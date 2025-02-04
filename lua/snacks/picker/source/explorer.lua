---@diagnostic disable: await-in-sync
local Actions = require("snacks.explorer.actions")
local Tree = require("snacks.explorer.tree")

local M = {}

---@class snacks.picker
---@field explorer fun(opts?: snacks.picker.explorer.Config|{}): snacks.Picker

---@type table<snacks.Picker, snacks.picker.explorer.State>
M._state = setmetatable({}, { __mode = "k" })
local uv = vim.uv or vim.loop

---@class snacks.picker.explorer.Item: snacks.picker.finder.Item
---@field file string
---@field dir? boolean
---@field parent? snacks.picker.explorer.Item
---@field open? boolean
---@field last? boolean
---@field sort? string
---@field internal? boolean internal parent directories not part of fd output
---@field status? string

local function norm(path)
  return vim.fs.normalize(path)
end

---@class snacks.picker.explorer.State
---@field on_find? fun()?
local State = {}
State.__index = State
---@param picker snacks.Picker
function State.new(picker)
  local self = setmetatable({}, State)

  local opts = picker.opts --[[@as snacks.picker.explorer.Config]]
  local ref = picker:ref()

  local buf = vim.api.nvim_win_get_buf(picker.main)
  local buf_file = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
  if uv.fs_stat(buf_file) then
    Tree:open(buf_file)
  end

  if opts.watch then
    picker.opts.on_close = function()
      require("snacks.explorer.watch").abort()
    end
  end

  picker.list.win:on("TermClose", function()
    local p = ref()
    if p then
      Tree:refresh(p:cwd())
      Actions.update(p)
    end
  end, { pattern = "*lazygit" })

  picker.list.win:on("BufWritePost", function(_, ev)
    local p = ref()
    if not p then
      return true
    end
    Tree:refresh(ev.file)
    Actions.update(p)
  end)

  picker.list.win:on("DirChanged", function(_, ev)
    local p = ref()
    if p then
      p:set_cwd(vim.fs.normalize(ev.file))
      p:find()
    end
  end)

  -- schedule initial follow
  if opts.follow_file then
    picker.list.win:on({ "WinEnter", "BufEnter" }, function(_, ev)
      vim.schedule(function()
        if ev.buf ~= vim.api.nvim_get_current_buf() then
          return
        end
        local p = ref()
        if not p or p:is_focused() or not p:on_current_tab() then
          return
        end
        local win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_config(win).relative ~= "" then
          return
        end
        local file = vim.api.nvim_buf_get_name(ev.buf)
        local item = p:current()
        if item and item.file == norm(file) then
          return
        end
        Actions.update(p, { target = file })
      end)
    end)
    self.on_find = function()
      local p = ref()
      if p and buf_file then
        Actions.update(p, { target = buf_file })
      end
    end
  end
  return self
end

---@param ctx snacks.picker.finder.ctx
function State:setup(ctx)
  local opts = ctx.picker.opts --[[@as snacks.picker.explorer.Config]]
  if opts.watch then
    require("snacks.explorer.watch").watch(ctx.filter.cwd)
  end
  return #ctx.filter.pattern > 0
end

---@param opts snacks.picker.explorer.Config
function M.setup(opts)
  local searching = false
  local ref ---@type snacks.Picker.ref
  return Snacks.config.merge(opts, {
    actions = {
      confirm = Actions.actions.confirm,
    },
    filter = {
      --- Trigger finder when pattern toggles between empty / non-empty
      ---@param picker snacks.Picker
      ---@param filter snacks.picker.Filter
      transform = function(picker, filter)
        ref = picker:ref()
        local s = #filter.pattern > 0
        if searching ~= s then
          searching = s
          filter.meta.searching = searching
          return true
        end
      end,
    },
    matcher = {
      --- Add parent dirs to matching items
      ---@param matcher snacks.picker.Matcher
      ---@param item snacks.picker.explorer.Item
      on_match = function(matcher, item)
        if not searching then
          return
        end
        local picker = ref.value
        if picker and item.score > 0 then
          local parent = item.parent
          while parent do
            if parent.score == 0 or parent.match_tick ~= matcher.tick then
              parent.score = 1
              parent.match_tick = matcher.tick
              picker.list:add(parent)
            else
              break
            end
            parent = parent.parent
          end
        end
      end,
    },
    formatters = {
      file = {
        filename_only = opts.tree,
      },
    },
  })
end

---@param picker snacks.Picker
function M.get_state(picker)
  if not M._state[picker] then
    M._state[picker] = State.new(picker)
  end
  return M._state[picker]
end

---@param opts snacks.picker.explorer.Config
---@type snacks.picker.finder
function M.explorer(opts, ctx)
  local state = M.get_state(ctx.picker)

  if state:setup(ctx) then
    return M.search(opts, ctx)
  end

  if opts.git_status then
    require("snacks.explorer.git").update(ctx.filter.cwd, {
      on_update = function()
        ctx.picker:find()
      end,
    })
  end

  return function(cb)
    if state.on_find then
      ctx.picker.matcher.task:on("done", vim.schedule_wrap(state.on_find))
      state.on_find = nil
    end
    local items = {} ---@type table<string, snacks.picker.explorer.Item>
    local top = Tree:find(ctx.filter.cwd)
    Tree:get(ctx.filter.cwd, function(node)
      local item = {
        file = node.path,
        dir = node.type == "directory",
        open = node.open,
        text = node.path,
        parent = node.parent and items[node.parent.path] or nil,
        hidden = node.hidden,
        ignored = node.ignored,
        status = (node.type ~= "directory" or not node.open or opts.git_status_open) and node.status or nil,
        last = node.last,
        type = node.type,
      }
      if top == node then
        item.hidden = false
      end
      items[node.path] = item
      cb(item)
    end, { hidden = opts.hidden, ignored = opts.ignored })
  end
end

---@param opts snacks.picker.explorer.Config
---@type snacks.picker.finder
function M.search(opts, ctx)
  opts = Snacks.picker.util.shallow_copy(opts)
  opts.cmd = "fd"
  opts.cwd = ctx.filter.cwd
  opts.notify = false
  opts.args = {
    "--type",
    "d", -- include directories
    "--path-separator", -- same everywhere
    "/",
    "--follow", -- always needed to make sure we see symlinked dirs as dirs
  }
  opts.dirs = { ctx.filter.cwd }
  ctx.picker.list:set_target()

  ---@type snacks.picker.explorer.Item
  local root = {
    file = opts.cwd,
    dir = true,
    open = true,
    text = "",
    sort = "",
    internal = true,
  }

  local files = require("snacks.picker.source.files").files(opts, ctx)

  local dirs = {} ---@type table<string, snacks.picker.explorer.Item>
  local last = {} ---@type table<snacks.picker.finder.Item, snacks.picker.finder.Item>

  ---@async
  return function(cb)
    cb(root)
    -- focus the first non-internal item
    ctx.picker.matcher.task:on(
      "done",
      vim.schedule_wrap(function()
        if ctx.picker.closed then
          return
        end
        for item, idx in ctx.picker:iter() do
          if not item.internal then
            ctx.picker.list:view(idx)
            return
          end
        end
      end)
    )

    ---@param item snacks.picker.explorer.Item
    local function add(item)
      local dirname, basename = item.file:match("(.*)/(.*)")
      dirname, basename = dirname or "", basename or item.file
      local parent = dirs[dirname] ~= item and dirs[dirname] or root

      -- hierarchical sorting
      if item.dir then
        item.sort = parent.sort .. "!" .. basename .. " "
      else
        item.sort = parent.sort .. "#" .. basename .. " "
      end
      if basename:sub(1, 1) == "." then
        item.hidden = true
      end
      local node = Tree:find(item.file)
      if node then
        item.status = (node.type ~= "directory" or opts.git_status_open) and node.status or nil
      end

      if opts.tree then
        -- tree
        item.parent = parent
        if not last[parent] or last[parent].sort < item.sort then
          if last[parent] then
            last[parent].last = false
          end
          item.last = true
          last[parent] = item
        end
      end
      -- add to picker
      cb(item)
    end

    -- get files and directories
    files(function(item)
      ---@cast item snacks.picker.explorer.Item
      item.cwd = nil -- we use absolute paths

      -- Directories
      if item.file:sub(-1) == "/" then
        item.dir = true
        item.file = item.file:sub(1, -2)
        if dirs[item.file] then
          dirs[item.file].internal = false
          return
        end
        item.open = true
        dirs[item.file] = item
      end

      -- Add parents when needed
      for dir in Snacks.picker.util.parents(item.file, opts.cwd) do
        if not dirs[dir] then
          dirs[dir] = {
            text = dir,
            file = dir,
            dir = true,
            open = true,
            internal = true,
          }
          add(dirs[dir])
        end
      end

      add(item)
    end)
  end
end

return M

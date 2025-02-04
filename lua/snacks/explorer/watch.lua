local M = {}

local uv = vim.uv or vim.loop

---@alias snacks.explorer.Watcher fun(path:string, opts:vim._watch.watch.Opts?, callback:vim._watch.Callback):fun()

---@return snacks.explorer.Watcher?
function M.watcher()
  if not vim._watch then
    return
  end
  if vim.fn.has("win32") == 1 or vim.fn.has("mac") == 1 then
    return vim._watch.watch
  elseif vim.fn.executable("inotifywait") == 1 then
    return vim._watch.inotify
  end
  -- This is horrible for performance. Don't use it!
  -- return vim._watch.watchdirs
end

local running = {} ---@type table<string, fun()>

function M.abort()
  for _, abort in pairs(running) do
    pcall(abort)
  end
  running = {}
end

---@param cwd string
function M.watch(cwd)
  if running[cwd] then
    return
  end
  local Tree = require("snacks.explorer.tree")
  local watch = M.watcher()
  if not watch then
    return
  end
  M.abort()

  pcall(function()
    local timer = assert(uv.new_timer())
    local cancel = watch(cwd, {
      uvflags = { recursive = true },
    }, function(path)
      -- handle deletes
      while not uv.fs_stat(path) do
        local p = vim.fs.dirname(path)
        if p == path then
          return
        end
        path = p
      end
      Tree:refresh(path)

      -- batch updates and give explorer the time to update before the watcher
      timer:start(100, 0, function()
        local picker = Snacks.picker.get({ source = "explorer" })[1]
        if picker and Tree:is_dirty(picker:cwd(), picker.opts) then
          if not picker.list.target then
            picker.list:set_target()
          end
          picker:find()
        end
      end)
    end)
    running[cwd] = function()
      if not timer:is_closing() then
        timer:close()
      end
      cancel()
    end
  end)
end

return M

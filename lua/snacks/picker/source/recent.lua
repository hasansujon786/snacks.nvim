local M = {}

local uv = vim.uv or vim.loop

---@class snacks.picker
---@field recent fun(opts?: snacks.picker.recent.Config): snacks.Picker
---@field projects fun(opts?: snacks.picker.projects.Config): snacks.Picker

---@param filter snacks.picker.Filter
local function oldfiles(filter)
  local done = {} ---@type table<string, boolean>
  local i = 1
  return function()
    while vim.v.oldfiles[i] do
      local file = vim.fs.normalize(vim.v.oldfiles[i], { _fast = true, expand_env = false })
      local want = not done[file] and filter:match({ file = file, text = "" })
      done[file] = true
      i = i + 1
      if want and uv.fs_stat(file) then
        return file
      end
    end
  end
end

--- Get the most recent files, optionally filtered by the
--- current working directory or a custom directory.
---@param opts snacks.picker.recent.Config
---@type snacks.picker.finder
function M.files(opts, filter)
  ---@async
  ---@param cb async fun(item: snacks.picker.finder.Item)
  return function(cb)
    for file in oldfiles(filter) do
      cb({ file = file, text = file })
    end
  end
end

M.recent = M.files

--- Get the most recent projects based on git roots of recent files.
--- The default action will change the directory to the project root,
--- try to restore the session and open the picker if the session is not restored.
--- You can customize the behavior by providing a custom action.
---@param opts snacks.picker.recent.Config
---@type snacks.picker.finder
function M.projects(opts, filter)
  ---@async
  ---@param cb async fun(item: snacks.picker.finder.Item)
  return function(cb)
    local dirs = {} ---@type table<string, boolean>
    for file in oldfiles(filter) do
      local dir = Snacks.git.get_root(file)
      if dir and not dirs[dir] then
        dirs[dir] = true
        cb({ file = dir, text = file, dir = dir })
      end
    end
  end
end

return M

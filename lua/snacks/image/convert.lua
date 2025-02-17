---@class snacks.image.convert
local M = {}
-- vim.list_extend(args, {
--   -- "-density",
--   -- "4000",
--   -- "-background",
--   -- "transparent",
--   -- "-flatten",
--   -- "+repage",
--   -- -- "-adaptive-resize",
--   -- -- "800",
--   -- "-quality",
--   -- "100",
--   -- "-trim",
-- })

---@alias snacks.image.generate.on_done fun(code: number)

---@class snacks.image.generate
---@field cwd? string
---@field cmd string
---@field args string[]
---@field on_done? snacks.image.generate.on_done

local uv = vim.uv or vim.loop

local have_magick ---@type boolean

---@param src string
function M.is_url(src)
  return src:find("^https?://") == 1
end

---@param src string
function M.is_uri(src)
  return src:find("^%w%w+://") == 1
end

---@param src string
function M.norm(src)
  if src:find("^file://") then
    return vim.fs.normalize(vim.uri_to_fname(src))
  end
  return src
end

---@param src string
---@param ext string
function M.tmpfile(src, ext)
  local root = Snacks.image.config.cache
  local base = vim.fn.fnamemodify(src, ":t:r")
  if M.is_uri(src) then
    base = src:gsub("%?.*", ""):match("^%w%w+://(.*)$") or base
  end
  base = base:gsub("[^%w%.]+", "-")
  vim.fn.mkdir(root, "p")
  return root .. "/" .. vim.fn.sha256(src):sub(1, 8) .. "-" .. base .. "." .. ext
end

---@param file string
---@param opts snacks.image.generate
---@return (fun(): boolean) is_ready
function M.generate(file, opts)
  local on_done = function(code)
    if opts.on_done then
      opts.on_done(code)
    end
  end
  if vim.fn.filereadable(file) == 1 then
    on_done(0)
    return function()
      return true
    end
  end
  if Snacks.image.config.debug.convert then
    Snacks.debug.cmd(opts)
  end
  local handle ---@type uv.uv_process_t
  handle = uv.spawn(opts.cmd, opts, function(code)
    handle:close()
    on_done(code)
  end)
  return function()
    return (not handle or handle:is_closing() or false) and vim.fn.filereadable(file) == 1
  end
end

---@param src string
---@param dest string
---@param opts? {args?: (string|number)[], on_done?: snacks.image.generate.on_done}
---@return (fun(): boolean) is_ready
function M.magick(src, dest, opts)
  opts = opts or {}
  local args = opts.args or { src .. "[0]" } ---@type string[]
  for a, arg in ipairs(args) do
    if arg == "src" then
      args[a] = src .. "[0]"
    end
  end
  args[#args + 1] = dest
  have_magick = have_magick == nil and vim.fn.executable("magick") == 1 or have_magick
  local cmd = have_magick and "magick" or "convert"
  local is_win = jit.os:find("Windows")
  if is_win and cmd == "convert" then
    return function()
      return false
    end
  end
  return M.generate(dest, {
    cmd = have_magick and "magick" or "convert",
    args = args,
    on_done = opts.on_done,
  })
end

---@param src string
---@param dest string
---@param opts? {on_done?: snacks.image.generate.on_done}
---@return (fun(): boolean) is_ready
function M.tex2pdf(src, dest, opts)
  return M.generate(dest, {
    cmd = "pdflatex",
    args = { "-output-directory=" .. vim.fn.fnamemodify(dest, ":h"), src },
    on_done = opts and opts.on_done,
  })
end

---@param src string
---@param opts? {on_done?: snacks.image.generate.on_done}
---@return string png, (fun(): boolean) is_ready
function M.convert(src, opts)
  local png = M.tmpfile(src, "png")
  src = M.norm(src)
  local ext = vim.fn.fnamemodify(src, ":e"):lower()
  if not M.is_uri(src) then
    src = vim.fs.normalize(src)
    png = M.tmpfile(src, "png")
    if ext == "png" then
      if opts and opts.on_done then
        opts.on_done(0)
      end
      return src, function()
        return true
      end
    elseif ext == "tex" then
      local pdf = src:gsub("%.tex$", ".pdf")
      local is_ready = function()
        return false
      end
      M.tex2pdf(src, pdf, {
        on_done = function(code)
          if code == 0 then
            opts.args = { "-density", 300, pdf, "-trim" }
            is_ready = M.magick(pdf, png, opts)
          end
        end,
      })
      return png, function()
        return is_ready()
      end
    end
  end
  opts.args = {
    -- "-density",
    -- 128,
    "src",
    "-scale",
    "200%",
  }
  if ext == "pdf" then
    opts.args = {
      "-density",
      144,
      "src",
      "-background",
      "white",
      "-alpha",
      "remove",
      "-trim",
    }
  end
  return png, M.magick(src, png, opts)
end

return M

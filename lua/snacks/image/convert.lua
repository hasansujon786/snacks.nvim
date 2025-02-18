local Spawn = require("snacks.util.spawn")

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
local have_tectonic ---@type boolean

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
---@param ... snacks.spawn.Config
function M.generate(file, ...)
  local opts = Snacks.config.merge(...)
  opts = Snacks.config.merge(opts, { debug = Snacks.image.config.debug.convert })
  if vim.fn.filereadable(file) == 1 then
    return
  end
  return Spawn.new(opts)
end

---@param src string
---@param dest string
---@param ...? snacks.spawn.Config
function M.magick(src, dest, ...)
  local opts = Snacks.config.merge(...)
  local args = opts.args or { src .. "[0]" } ---@type string[]
  for a, arg in ipairs(args) do
    if arg == "src" then
      args[a] = src .. "[0]"
    end
  end
  args[#args + 1] = dest
  have_magick = have_magick == nil and vim.fn.executable("magick") == 1 or have_magick
  local cmd = have_magick and "magick" or "convert"
  if Snacks.util.is_win and cmd == "convert" then
    return
  end
  return M.generate(dest, opts, {
    cmd = cmd,
    args = args,
  })
end

---@param src string
---@param dest string
---@param ... snacks.spawn.Config
function M.tex2pdf(src, dest, ...)
  local opts = Snacks.config.merge(...)
  have_tectonic = have_tectonic == nil and vim.fn.executable("tectonic") == 1 or have_tectonic
  local dir = vim.fn.fnamemodify(dest, ":h")
  local cmd, args = "pdflatex", { "-output-directory=" .. dir, src }
  if have_tectonic then
    cmd, args = "tectonic", { "--outdir", dir, src }
  end
  return M.generate(dest, opts, { cmd = cmd, args = args })
end

---@param src string
---@param opts? snacks.spawn.Multi
---@return string png, snacks.spawn.Proc?
function M.convert(src, opts)
  local png = M.tmpfile(src, "png")
  src = M.norm(src)
  local ext = vim.fn.fnamemodify(src, ":e"):lower()
  if not M.is_uri(src) then
    src = vim.fs.normalize(src)
    png = M.tmpfile(src, "png")
    if ext == "png" then
      return src
    elseif ext == "tex" then
      local pdf = src:gsub("%.tex$", ".pdf")
      local procs = {} ---@type snacks.spawn.Proc[]
      procs[#procs + 1] = M.tex2pdf(src, pdf, vim.deepcopy(opts), { run = false })
      procs[#procs + 1] = M.magick(pdf, png, vim.deepcopy(opts), {
        run = false,
        args = { "-density", 300, "src", "-trim" },
      })
      return png, Spawn.multi(procs, opts)
    elseif ext == "mmd" then
      return png,
        M.generate(png, vim.deepcopy(opts), {
          cmd = "mmdc",
          args = {
            "-i",
            src,
            "-o",
            png,
            "-b",
            "transparent",
            "-t",
            vim.o.background,
            "-s",
            Snacks.image.terminal.size().scale,
          },
        })
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

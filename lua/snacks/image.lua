---@class snacks.image
---@field id number
---@field ns number
---@field buf number
---@field opts snacks.image.Opts
---@field file string
---@field src string
---@field augroup number
---@field closed? boolean
---@field _loc? snacks.image.Loc
---@field _state? snacks.image.State
---@field _convert uv.uv_process_t?
---@field inline? boolean render the image inline in the buffer
---@field extmark_id? number
local M = {}
M.__index = M

M.meta = {
  desc = "Image viewer using Kitty Graphics Protocol, supported by `kitty`, `wezterm` and `ghostty`",
  needs_setup = true,
}

---@alias snacks.image.Size {width: number, height: number}
---@alias snacks.image.Pos {[1]: number, [2]: number}
---@alias snacks.image.Loc snacks.image.Pos|snacks.image.Size|{zindex?: number}

---@class snacks.image.Env
---@field name string
---@field env table<string, string|true>
---@field supported? boolean default: false
---@field placeholders? boolean default: false
---@field setup? fun(): boolean?
---@field transform? fun(data: string): string
---@field detected? boolean

---@class snacks.image.Config
---@field wo? vim.wo|{} options for windows showing the image
---@field bo? vim.bo|{} options for the image buffer
---@field formats? string[]
--- Resolves a reference to an image with src in a file (currently markdown only).
--- Return the absolute path or url to the image.
--- When `nil`, the path is resolved relative to the file.
---@field resolve? fun(file: string, src: string): string?
local defaults = {
  formats = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "tiff", "heic", "avif", "mp4", "mov", "avi", "mkv", "webm" },
  force = false, -- try displaying the image, even if the terminal does not support it
  markdown = {
    -- enable image viewer for markdown files
    -- if your env doesn't support unicode placeholders, this will be disabled
    enabled = true,
    max_width = 80,
    max_height = 40,
  },
  -- window options applied to windows displaying image buffers
  -- an image buffer is a buffer with `filetype=image`
  wo = {
    wrap = false,
    number = false,
    relativenumber = false,
    cursorcolumn = false,
    signcolumn = "no",
    foldcolumn = "0",
    list = false,
    spell = false,
    statuscolumn = "",
  },
  debug = false,
}
local config = Snacks.config.get("image", defaults)

---@class snacks.image.Opts
---@field pos? snacks.image.Pos (row, col) (1,0)-indexed. defaults to the top-left corner
---@field width? number
---@field min_width? number
---@field max_width? number
---@field height? number
---@field min_height? number
---@field max_height? number

---@type snacks.image.Env[]
local environments = {
  {
    name = "kitty",
    env = { TERM = "kitty", KITTY_PID = true },
    supported = true,
    placeholders = true,
  },
  {
    name = "ghostty",
    env = { TERM = "ghostty", GHOSTTY_BIN_DIR = true },
    supported = true,
    placeholders = true,
  },
  {
    name = "wezterm",
    env = { TERM = "wezterm", WEZTERM_PANE = true, WEZTERM_EXECUTABLE = true, WEZTERM_CONFIG_FILE = true },
    supported = true,
    placeholders = false,
  },
  {
    name = "tmux",
    env = { TERM = "tmux", TMUX = true },
    setup = function()
      local ok, out = pcall(vim.fn.system, { "tmux", "set", "-p", "allow-passthrough", "on" })
      if not ok or vim.v.shell_error ~= 0 then
        Snacks.notify.error(
          { "Failed to enable `allow-passthrough` for `tmux`:", out },
          { title = "Image", once = true }
        )
        return false
      end
    end,
    transform = function(data)
      return ("\027Ptmux;" .. data:gsub("\027", "\027\027")) .. "\027\\"
    end,
  },
  { name = "zellij", env = { TERM = "zellij", ZELLIJ = true }, supported = false, placeholders = false },
}

M._env = nil ---@type snacks.image.Env?
local NVIM_ID_BITS = 10
local PLACEHOLDER = vim.fn.nr2char(0x10EEEE)
-- stylua: ignore
local diacritics = vim.split( "0305,030D,030E,0310,0312,033D,033E,033F,0346,034A,034B,034C,0350,0351,0352,0357,035B,0363,0364,0365,0366,0367,0368,0369,036A,036B,036C,036D,036E,036F,0483,0484,0485,0486,0487,0592,0593,0594,0595,0597,0598,0599,059C,059D,059E,059F,05A0,05A1,05A8,05A9,05AB,05AC,05AF,05C4,0610,0611,0612,0613,0614,0615,0616,0617,0657,0658,0659,065A,065B,065D,065E,06D6,06D7,06D8,06D9,06DA,06DB,06DC,06DF,06E0,06E1,06E2,06E4,06E7,06E8,06EB,06EC,0730,0732,0733,0735,0736,073A,073D,073F,0740,0741,0743,0745,0747,0749,074A,07EB,07EC,07ED,07EE,07EF,07F0,07F1,07F3,0816,0817,0818,0819,081B,081C,081D,081E,081F,0820,0821,0822,0823,0825,0826,0827,0829,082A,082B,082C,082D,0951,0953,0954,0F82,0F83,0F86,0F87,135D,135E,135F,17DD,193A,1A17,1A75,1A76,1A77,1A78,1A79,1A7A,1A7B,1A7C,1B6B,1B6D,1B6E,1B6F,1B70,1B71,1B72,1B73,1CD0,1CD1,1CD2,1CDA,1CDB,1CE0,1DC0,1DC1,1DC3,1DC4,1DC5,1DC6,1DC7,1DC8,1DC9,1DCB,1DCC,1DD1,1DD2,1DD3,1DD4,1DD5,1DD6,1DD7,1DD8,1DD9,1DDA,1DDB,1DDC,1DDD,1DDE,1DDF,1DE0,1DE1,1DE2,1DE3,1DE4,1DE5,1DE6,1DFE,20D0,20D1,20D4,20D5,20D6,20D7,20DB,20DC,20E1,20E7,20E9,20F0,2CEF,2CF0,2CF1,2DE0,2DE1,2DE2,2DE3,2DE4,2DE5,2DE6,2DE7,2DE8,2DE9,2DEA,2DEB,2DEC,2DED,2DEE,2DEF,2DF0,2DF1,2DF2,2DF3,2DF4,2DF5,2DF6,2DF7,2DF8,2DF9,2DFA,2DFB,2DFC,2DFD,2DFE,2DFF,A66F,A67C,A67D,A6F0,A6F1,A8E0,A8E1,A8E2,A8E3,A8E4,A8E5,A8E6,A8E7,A8E8,A8E9,A8EA,A8EB,A8EC,A8ED,A8EE,A8EF,A8F0,A8F1,AAB0,AAB2,AAB3,AAB7,AAB8,AABE,AABF,AAC1,FE20,FE21,FE22,FE23,FE24,FE25,FE26,10A0F,10A38,1D185,1D186,1D187,1D188,1D189,1D1AA,1D1AB,1D1AC,1D1AD,1D242,1D243,1D244", ",")
local did_setup = false
local dims = {} ---@type table<string, snacks.image.Size>
local id = 30
local nvim_id = 0
local uv = vim.uv or vim.loop
---@type table<number, string>
local positions = setmetatable({}, {
  __index = function(t, k)
    t[k] = vim.fn.nr2char(tonumber(diacritics[k], 16))
    return t[k]
  end,
})

function M.env()
  if M._env then
    return M._env
  end
  M._env = {
    name = "",
    env = {},
  }
  for _, e in ipairs(environments) do
    for k, v in pairs(e.env) do
      local val = os.getenv(k)
      if val and (v == true or val:find(v)) then
        e.detected = true
        break
      end
    end
    if e.detected then
      M._env.name = M._env.name .. "/" .. e.name
      if e.supported ~= nil then
        M._env.supported = e.supported
      end
      if e.placeholders ~= nil then
        M._env.placeholders = e.placeholders
      end
      M._env.transform = e.transform
      if e.setup then
        e.setup()
      end
    end
  end
  if M._env.supported then
    -- delete all images on startup
    M.request({ a = "d", d = "a" })
  end
  M._env.name = M._env.name:gsub("^/", "")
  return M._env
end

local function minmax(value, min, max)
  return math.max(min or 1, math.min(value, max or value))
end

local function nextid()
  id = id + 1
  local bit = require("bit")
  -- generate a unique id for this nvim instance (10 bits)
  if nvim_id == 0 then
    local pid = vim.fn.getpid()
    nvim_id = bit.band(bit.bxor(pid, bit.rshift(pid, 5), bit.rshift(pid, NVIM_ID_BITS)), 0x3FF)
  end
  -- interleave the nvim id and the image id
  return bit.bor(bit.lshift(nvim_id, 24 - NVIM_ID_BITS), id)
end

---@param buf number
---@param opts? snacks.image.Opts
function M.new(buf, src, opts)
  assert(type(buf) == "number", "`Image.new`: buf should be a number")
  assert(type(src) == "string", "`Image.new`: src should be a string")
  M.setup() -- always setup so that images/videos can be opened
  local self = setmetatable({}, M)

  -- convert to PNG if needed
  self.src = src
  self.file = self:convert(src)
  self.id = nextid()
  self.opts = opts or {}
  self.buf = buf
  self.inline = true
  if vim.bo[buf].filetype == "image" then
    self.inline = false
  end
  self.ns = vim.api.nvim_create_namespace("snacks.image." .. self.id)
  self.augroup = vim.api.nvim_create_augroup("snacks.image." .. self.id, { clear = true })

  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "BufWinLeave", "BufEnter" }, {
    group = self.augroup,
    buffer = self.buf,
    callback = function()
      vim.schedule(function()
        -- self:update()
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "WinClosed", "WinNew", "WinEnter", "WinResized" }, {
    group = self.augroup,
    callback = function()
      vim.schedule(function()
        -- self:update()
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = self.augroup,
    buffer = self.buf,
    once = true,
    callback = function()
      vim.schedule(function()
        self:close()
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "ExitPre" }, {
    group = self.augroup,
    once = true,
    callback = function()
      self:close()
    end,
  })

  local update = self.update
  if self:ready() then
    vim.schedule(function()
      self:create()
      self:update()
    end)
  end

  self.update = Snacks.util.debounce(function()
    update(self)
  end, { ms = 10 })
  return self
end

---@return number[]
function M:wins()
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_buf(win) == self.buf
  end, vim.api.nvim_tabpage_list_wins(0))
end

function M:close()
  if self.closed then
    return
  end
  self.closed = true
  self:debug("close")
  self:hide()
  pcall(vim.api.nvim_del_augroup_by_id, self.augroup)
end

--- Renders the unicode placeholder grid in the buffer
---@param loc snacks.image.Loc
function M:render_grid(loc)
  local hl = "SnacksImage" .. self.id -- image id is encoded in the foreground color
  vim.api.nvim_set_hl(0, hl, { fg = self.id })
  local lines = {} ---@type string[]
  for r = 1, loc.height do
    local line = {} ---@type string[]
    for c = 1, loc.width do
      -- cell positions are encoded as diacritics for the placeholder unicode character
      line[#line + 1] = PLACEHOLDER
      line[#line + 1] = positions[r]
      line[#line + 1] = positions[c]
    end
    lines[#lines + 1] = table.concat(line)
  end

  if self.inline then
    vim.api.nvim_buf_clear_namespace(self.buf, self.ns, 0, -1)
    self.extmark_id = vim.api.nvim_buf_set_extmark(self.buf, self.ns, loc[1] - 1, loc[2], {
      id = self.extmark_id,
      virt_lines = vim.tbl_map(function(l)
        return { { l, hl } }
      end, lines),
      strict = false,
      invalidate = vim.fn.has("nvim-0.10") == 1 and true or nil,
    })
  else
    vim.bo[self.buf].modifiable = true
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
    vim.bo[self.buf].modifiable = false
    vim.bo[self.buf].modified = false
    for r = 1, loc.height do
      vim.api.nvim_buf_set_extmark(self.buf, self.ns, r - 1, 0, {
        end_col = #lines[r],
        hl_group = hl,
      })
    end
  end
end

function M:hide()
  if vim.api.nvim_buf_is_valid(self.buf) then
    vim.api.nvim_buf_clear_namespace(self.buf, self.ns, 0, -1)
  end
  self.request({ a = "d", d = "i", i = self.id })
end

---@param pos {[1]: number, [2]: number}
function M:set_cursor(pos)
  io.stdout:write("\27[" .. pos[1] .. ";" .. (pos[2] + 1) .. "H")
end

---@param state snacks.image.State
function M:render_fallback(state)
  self:hide()
  self:create()
  for _, win in ipairs(state.wins) do
    self:debug("render_fallback", win)
    local border = setmetatable({ opts = vim.api.nvim_win_get_config(win) }, { __index = Snacks.win }):border_size()
    local pos = vim.api.nvim_win_get_position(win)
    self:set_cursor({ pos[1] + 1 + border.top, pos[2] + border.left })
    self.request({
      a = "p",
      i = self.id,
      p = win,
      C = 1,
      c = state.loc.width,
      r = state.loc.height,
    })
  end
end

function M:debug(...)
  if not config.debug then
    return
  end
  Snacks.debug.inspect({ ... }, self.src, self.id)
end

function M:state()
  local width, height = vim.o.columns, vim.o.lines
  local wins = {} ---@type number[]
  local is_fallback = not M.env().placeholders
  local zindex = vim.api.nvim_win_get_config(0).zindex or 0

  for _, win in ipairs(self:wins()) do
    width = math.min(width, vim.api.nvim_win_get_width(win))
    height = math.min(height, vim.api.nvim_win_get_height(win))
    if is_fallback then
      local z = vim.api.nvim_win_get_config(win).zindex or 0
      if z >= zindex or (zindex > 0 and z > 0) then
        wins[#wins + 1] = win -- use if higher z-index or both are floating
      end
    else
      wins[#wins + 1] = win
    end
  end
  width = minmax(self.opts.width or width, self.opts.min_width, self.opts.max_width)
  height = minmax(self.opts.height or height, self.opts.min_height, self.opts.max_height)
  local w, h = M.dim(self.file)
  h = h * 0.5 -- adjust for cell height
  local scale = math.min(width / w, height / h)
  local c, r = math.floor(w * scale), math.floor(h * scale)
  local pos = self.opts.pos or { 1, 0 }
  ---@class snacks.image.State
  ---@field loc snacks.image.Loc
  ---@field wins number[]
  return {
    loc = { pos[1], pos[2], width = math.floor(c + 0.5), height = math.floor(r + 0.5) },
    wins = wins,
  }
end

function M:update()
  if not self:ready() then
    return
  end

  local state = self:state()
  if vim.deep_equal(state, self._state) then
    return
  end
  self._state = state

  if #state.wins == 0 then
    self:hide()
    return
  end

  self:debug("update")

  if not self.inline then
    for _, win in ipairs(state.wins) do
      Snacks.util.wo(win, config.wo or {})
    end
  end

  if M.env().placeholders then
    self.request({
      a = "p",
      U = 1,
      i = self.id,
      C = 1,
      c = state.loc.width,
      r = state.loc.height,
    })
    self:render_grid(state.loc)
  else
    self:render_fallback(state)
  end

  if not self.inline then
    for _, win in ipairs(state.wins) do
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview({ topline = 1, lnum = 1, col = 0, leftcol = 0 })
      end)
    end
  end
end

function M:ready()
  return not self.closed
    and self.buf
    and vim.api.nvim_buf_is_valid(self.buf)
    and (not self._convert or self._convert:is_closing())
    and (self.file and vim.fn.filereadable(self.file) == 1)
end

-- create the image
function M:create()
  self.request({
    f = 100,
    t = "f",
    i = self.id,
    data = self.file,
  })
end

---@param file string
function M:convert(file)
  if file:find("^file://") then
    file = vim.uri_to_fname(file)
  end
  -- convert urls and non-png files to png
  if not file:find("^https?://") and file:find("%.png$") then
    return file
  end
  if not file:find("^%w%w+://") then
    file = vim.fs.normalize(file)
  end
  local fin = file .. "[0]"
  local root = vim.fn.stdpath("cache") .. "/snacks/image"
  vim.fn.mkdir(root, "p")
  file = root .. "/" .. Snacks.util.file_encode(fin) .. ".png"
  if vim.fn.filereadable(file) == 1 then
    return file
  end
  local opts = { args = { fin, file } }
  self._convert = uv.spawn("magick", opts, function()
    self._convert:close()
    vim.schedule(function()
      self:create()
      self:update()
    end)
  end)
  return file
end

---@param opts table<string, string|number>|{data?: string}
function M.request(opts)
  opts.q = opts.q or 2 -- silence all
  local msg = {} ---@type string[]
  for k, v in pairs(opts) do
    if k ~= "data" then
      table.insert(msg, string.format("%s=%s", k, v))
    end
  end
  msg = { table.concat(msg, ",") }
  if opts.data then
    msg[#msg + 1] = ";"
    msg[#msg + 1] = Snacks.util.base64(tostring(opts.data))
  end
  local data = "\27_G" .. table.concat(msg) .. "\27\\"
  local env = M.env()
  if env.transform then
    data = env.transform(data)
  end
  io.stdout:write(data)
end

--- Check if the file format is supported
---@param file string
function M.supports_file(file)
  return vim.tbl_contains(config.formats or {}, vim.fn.fnamemodify(file, ":e"))
end

--- Check if the file format is supported and the terminal supports the kitty graphics protocol
---@param file string
function M.supports(file)
  return M.supports_file(file) and M.supports_terminal()
end

-- Check if the terminal supports the kitty graphics protocol
function M.supports_terminal()
  return M.env().supported or config.force or false
end

--- Get the dimensions of a PNG file
---@param file string
---@return number width, number height
function M.dim(file)
  file = vim.fs.normalize(file)
  if dims[file] then
    return dims[file].width, dims[file].height
  end
  -- extract header with IHDR chunk
  local fd = assert(io.open(file, "rb"), "Failed to open file: " .. file)
  local header = fd:read(24) ---@type string
  fd:close()

  -- Check PNG signature
  assert(header:sub(1, 8) == "\137PNG\r\n\26\n", "Not a valid PNG file: " .. file)

  -- Extract width and height from the IHDR chunk
  local width = header:byte(17) * 16777216 + header:byte(18) * 65536 + header:byte(19) * 256 + header:byte(20)
  local height = header:byte(21) * 16777216 + header:byte(22) * 65536 + header:byte(23) * 256 + header:byte(24)
  dims[file] = { width = width, height = height }
  return width, height
end

---@private
function M.health()
  Snacks.health.have_tool({ "kitty", "wezterm", "ghostty" })
  if not Snacks.health.have_tool("magick") then
    Snacks.health.error("`magick` is required to convert images. Only PNG files will be displayed.")
  end
  local env = M.env()
  for _, e in ipairs(environments) do
    if e.detected then
      if e.supported == false then
        Snacks.health.error("`" .. e.name .. "` is not supported")
      else
        Snacks.health.ok("`" .. e.name .. "` detected and supported")
        if e.placeholders == false then
          Snacks.health.warn("`" .. e.name .. "` does not support placeholders. Fallback rendering will be used")
        elseif e.placeholders == true then
          Snacks.health.ok("`" .. e.name .. "` supports unicode placeholders")
        end
      end
    end
  end
  if env.supported then
    Snacks.health.ok("your terminal supports the kitty graphics protocol")
  elseif config.force then
    Snacks.health.warn("image viewer is enabled with `opts.force = true`. Use at your own risk")
  else
    Snacks.health.error("your terminal does not support the kitty graphics protocol")
    Snacks.health.info("supported terminals: `kitty`, `wezterm`, `ghostty`")
  end
end

---@private
---@param ev? vim.api.keyset.create_autocmd.callback_args
function M.setup(ev)
  if did_setup then
    return
  end
  did_setup = true
  local group = vim.api.nvim_create_augroup("snacks.image", { clear = true })

  if config.formats and #config.formats > 0 then
    vim.api.nvim_create_autocmd("BufReadCmd", {
      pattern = "*." .. table.concat(config.formats, ",*."),
      group = group,
      callback = function(e)
        M.attach(e.buf)
      end,
    })
    -- prevent altering the original image file
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      pattern = "*." .. table.concat(config.formats, ",*."),
      group = group,
      callback = function(e)
        -- vim.api.nvim_exec_autocmds("BufWritePre", { buffer = e.buf })
        vim.bo[e.buf].modified = false
        -- vim.api.nvim_exec_autocmds("BufWritePost", { buffer = e.buf })
      end,
    })
  end
  if config.markdown.enabled and M.env().placeholders then
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      callback = function(e)
        local ft = vim.bo[e.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft)
        if lang == "markdown" then
          vim.schedule(function()
            M.markdown(e.buf)
          end)
        end
      end,
    })
  end
  if ev and ev.event == "BufReadCmd" then
    M.attach(ev.buf)
  end
end

---@param buf number
---@param opts? snacks.image.Opts|{src?: string}
function M.attach(buf, opts)
  local file = opts and opts.src or vim.api.nvim_buf_get_name(buf)
  if not M.supports(file) then
    local lines = {} ---@type string[]
    lines[#lines + 1] = "# Image viewer"
    lines[#lines + 1] = "- **file**: `" .. file .. "`"
    if not M.supports_file(file) then
      lines[#lines + 1] = "- unsupported image format"
    end
    if not M.supports_terminal() then
      lines[#lines + 1] = "- terminal does not support the kitty graphics protocol."
      lines[#lines + 1] = "  See `:checkhealth snacks` for more info."
    end
    vim.bo[buf].modifiable = true
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(table.concat(lines, "\n"), "\n"))
    vim.bo[buf].modifiable = false
    vim.bo[buf].modified = false
  else
    Snacks.util.bo(buf, {
      filetype = "image",
      modifiable = false,
      modified = false,
      swapfile = false,
    })
    M.new(buf, file, opts)
  end
end

---@param buf? number
function M.markdown(buf)
  buf = buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local file = vim.api.nvim_buf_get_name(buf)
  local dir = vim.fs.dirname(file)
  assert(vim.bo[buf].filetype == "markdown", "`Image.markdown`: buf should be a markdown buffer")
  local images = {} ---@type table<string, snacks.image>
  local parser = vim.treesitter.get_parser(buf)
  assert(parser, "`Image.markdown`: treesitter parser not found")
  parser:parse(true)
  local query = vim.treesitter.query.parse("markdown_inline", "(image (link_destination) @image)")

  ---@param src string
  local function resolve(src)
    if src:find("^%.") then
      src = vim.fs.normalize(dir .. "/" .. src)
    end
    return src
  end

  local function update()
    local found = {} ---@type table<string, boolean>
    parser:for_each_tree(function(tstree)
      if not tstree then
        return
      end
      for _, node, _ in query:iter_captures(tstree:root(), buf) do
        local src = vim.treesitter.get_node_text(node, buf)
        local range = { node:range() }
        local pos = { range[1] + 1, range[2] }
        local nid = node:id()
        if not images[nid] then
          src = config.resolve and config.resolve(file, src) or resolve(src)
          images[nid] = M.new(buf, src, { pos = pos, max_width = 80 })
        else
          images[nid]:update()
        end
        found[nid] = true
      end
    end)
    for nid, img in pairs(images) do
      if not found[nid] then
        img:close()
        images[nid] = nil
      end
    end
  end

  update()
  local group = vim.api.nvim_create_augroup("snacks.image.markdown." .. buf, { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    buffer = buf,
    callback = function(ev)
      update()
    end,
  })
end

return M

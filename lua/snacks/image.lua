---@class snacks.image
---@field id number
---@field buf number
---@field opts snacks.image.Config
---@field file string
---@field augroup number
---@field _convert uv.uv_process_t?
local M = {}
M.__index = M

M.meta = {
  desc = "Image viewer using Kitty Graphics Protocol, supported by `kitty`, `wezterm` and `ghostty`",
  needs_setup = true,
}

---@class snacks.image.Env
---@field name string
---@field env table<string, string|true>
---@field supported? boolean default: false
---@field placeholders? boolean default: false
---@field setup? fun(): boolean?
---@field transform? fun(data: string): string
---@field detected? boolean

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

---@class snacks.image.Config
---@field file? string
---@field wo? vim.wo|{} options for windows showing the image
local defaults = {
  force = false, -- try displaying the image, even if the terminal does not support it
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
}
local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("snacks.image")

local NVIM_ID_BITS = 10
local images = {} ---@type table<number, snacks.image>
local id = 30
local nvim_id = 0
local ids = {} ---@type table<string, number>
local diacritics = vim.split(
  "0305,030D,030E,0310,0312,033D,033E,033F,0346,034A,034B,034C,0350,0351,0352,0357,035B,0363,0364,0365,0366,0367,0368,0369,036A,036B,036C,036D,036E,036F,0483,0484,0485,0486,0487,0592,0593,0594,0595,0597,0598,0599,059C,059D,059E,059F,05A0,05A1,05A8,05A9,05AB,05AC,05AF,05C4,0610,0611,0612,0613,0614,0615,0616,0617,0657,0658,0659,065A,065B,065D,065E,06D6,06D7,06D8,06D9,06DA,06DB,06DC,06DF,06E0,06E1,06E2,06E4,06E7,06E8,06EB,06EC,0730,0732,0733,0735,0736,073A,073D,073F,0740,0741,0743,0745,0747,0749,074A,07EB,07EC,07ED,07EE,07EF,07F0,07F1,07F3,0816,0817,0818,0819,081B,081C,081D,081E,081F,0820,0821,0822,0823,0825,0826,0827,0829,082A,082B,082C,082D,0951,0953,0954,0F82,0F83,0F86,0F87,135D,135E,135F,17DD,193A,1A17,1A75,1A76,1A77,1A78,1A79,1A7A,1A7B,1A7C,1B6B,1B6D,1B6E,1B6F,1B70,1B71,1B72,1B73,1CD0,1CD1,1CD2,1CDA,1CDB,1CE0,1DC0,1DC1,1DC3,1DC4,1DC5,1DC6,1DC7,1DC8,1DC9,1DCB,1DCC,1DD1,1DD2,1DD3,1DD4,1DD5,1DD6,1DD7,1DD8,1DD9,1DDA,1DDB,1DDC,1DDD,1DDE,1DDF,1DE0,1DE1,1DE2,1DE3,1DE4,1DE5,1DE6,1DFE,20D0,20D1,20D4,20D5,20D6,20D7,20DB,20DC,20E1,20E7,20E9,20F0,2CEF,2CF0,2CF1,2DE0,2DE1,2DE2,2DE3,2DE4,2DE5,2DE6,2DE7,2DE8,2DE9,2DEA,2DEB,2DEC,2DED,2DEE,2DEF,2DF0,2DF1,2DF2,2DF3,2DF4,2DF5,2DF6,2DF7,2DF8,2DF9,2DFA,2DFB,2DFC,2DFD,2DFE,2DFF,A66F,A67C,A67D,A6F0,A6F1,A8E0,A8E1,A8E2,A8E3,A8E4,A8E5,A8E6,A8E7,A8E8,A8E9,A8EA,A8EB,A8EC,A8ED,A8EE,A8EF,A8F0,A8F1,AAB0,AAB2,AAB3,AAB7,AAB8,AABE,AABF,AAC1,FE20,FE21,FE22,FE23,FE24,FE25,FE26,10A0F,10A38,1D185,1D186,1D187,1D188,1D189,1D1AA,1D1AB,1D1AC,1D1AD,1D242,1D243,1D244",
  ","
)
local supported_formats = { "png", "jpg", "jpeg", "gif", "bmp", "webp" }

function M.env()
  if M._env then
    return M._env
  end
  M._env = {
    name = "",
    env = {},
  }
  if not vim.base64 then
    M._env.supported = false
    return M._env
  end
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
  M._env.name = M._env.name:gsub("^/", "")
  return M._env
end

---@param buf number
---@param opts? snacks.image.Config
function M.new(buf, opts)
  if images[buf] then
    return images[buf]
  end
  local file = opts and opts.file or vim.api.nvim_buf_get_name(buf)
  if not M.supports(file) then
    local lines = {} ---@type string[]
    lines[#lines + 1] = "# Image viewer"
    lines[#lines + 1] = "- **file**: `" .. file .. "`"
    if not M.supports_file(file) then
      lines[#lines + 1] = "- unsupported image format"
    end
    local ok, err = M.supports_terminal()
    if not ok then
      lines[#lines + 1] = "- " .. err
    end
    vim.bo[buf].modifiable = true
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(table.concat(lines, "\n"), "\n"))
    vim.bo[buf].modifiable = false
    vim.bo[buf].modified = false
    return
  end

  local self = setmetatable({}, M)
  images[buf] = self

  -- convert to PNG if needed
  self.file = self:convert(file)

  -- re-use image ids for the same file
  if not ids[self.file] then
    id = id + 1
    ids[self.file] = id
    local bit = require("bit")
    -- generate a unique id for this nvim instance (10 bits)
    if nvim_id == 0 then
      local pid = vim.fn.getpid()
      nvim_id = bit.band(bit.bxor(pid, bit.rshift(pid, 5), bit.rshift(pid, NVIM_ID_BITS)), 0x3FF)
    end
    -- interleave the nvim id and the image id
    self.id = bit.bor(bit.lshift(nvim_id, 24 - NVIM_ID_BITS), id)
  end
  self.id = ids[self.file]

  self.opts = Snacks.config.get("image", defaults, opts or {})

  Snacks.util.bo(buf, {
    filetype = "image",
    modifiable = false,
    modified = false,
    swapfile = false,
  })
  self.buf = buf

  self.augroup = vim.api.nvim_create_augroup("snacks.image." .. self.id, { clear = true })
  vim.api.nvim_create_autocmd(
    { "VimResized", "BufWinEnter", "WinClosed", "BufWinLeave", "WinNew", "BufEnter", "BufLeave", "WinResized" },
    {
      group = self.augroup,
      buffer = self.buf,
      callback = function()
        vim.schedule(function()
          self:update()
        end)
      end,
    }
  )

  vim.api.nvim_create_autocmd({ "BufWipeout", "ExitPre" }, {
    group = self.augroup,
    buffer = self.buf,
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
  end, { ms = 50 })
  return self
end

---@return number[]
function M:wins()
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_buf(win) == self.buf
  end, vim.api.nvim_list_wins())
end

function M:grid_size()
  local width, height = vim.o.columns, vim.o.lines
  for _, win in pairs(self:wins()) do
    width = math.min(width, vim.api.nvim_win_get_width(win))
    height = math.min(height, vim.api.nvim_win_get_height(win))
  end
  return width, height
end

function M:close()
  self:hide()
  pcall(vim.api.nvim_del_augroup_by_id, self.augroup)
end

--- Renders the unicode placeholder grid in the buffer
---@param width number
---@param height number
function M:render(width, height)
  if not self:ready() then
    return
  end
  local hl = "SnacksImage" .. self.id
  -- image id is coded in the foreground color
  vim.api.nvim_set_hl(0, hl, { fg = self.id })
  local lines = {} ---@type string[]
  for r = 1, height do
    local line = {} ---@type string[]
    for c = 1, width do
      -- cell positions are encoded as diacritics for the placeholder unicode character
      line[#line + 1] = vim.fn.nr2char(0x10EEEE)
      line[#line + 1] = vim.fn.nr2char(tonumber(diacritics[r], 16))
      line[#line + 1] = vim.fn.nr2char(tonumber(diacritics[c], 16))
    end
    lines[#lines + 1] = table.concat(line)
  end
  vim.bo[self.buf].modifiable = true
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  vim.bo[self.buf].modifiable = false
  vim.bo[self.buf].modified = false
  for r = 1, height do
    vim.api.nvim_buf_set_extmark(self.buf, ns, r - 1, 0, {
      end_col = #lines[r],
      hl_group = hl,
    })
  end
end

function M:hide()
  self:request({ a = "d", i = self.id })
end

---@param pos {[1]: number, [2]: number}
function M:set_cursor(pos)
  io.stdout:write("\27[" .. pos[1] .. ";" .. pos[2] .. "H")
end

function M:render_fallback()
  self:hide()
  local w, h = M.dim(self.file)
  h = h * 0.5 -- adjust for cell height
  for _, win in ipairs(self:wins()) do
    local border = setmetatable({ opts = vim.api.nvim_win_get_config(win) }, { __index = Snacks.win }):border_size()
    local width = vim.api.nvim_win_get_width(win) - border.left - border.right
    local height = vim.api.nvim_win_get_height(win) - border.top - border.bottom
    local scale = math.min(width / w, height / h)
    width, height = math.floor(w * scale), math.floor(h * scale)
    vim.api.nvim_win_call(win, function()
      vim.fn.winrestview({ topline = 1, lnum = 1, col = 0, leftcol = 0 })
      local pos = vim.api.nvim_win_get_position(win)
      self:set_cursor({ pos[1] + 1 + border.left, pos[2] + 1 + border.top })
      self:request({
        a = "p",
        i = self.id,
        p = win,
        C = 1,
        c = math.floor(width + 0.5),
        r = math.floor(height + 0.5),
      })
    end)
  end
end

function M:update()
  if not self:ready() then
    return
  end
  for _, win in ipairs(self:wins()) do
    Snacks.util.wo(win, self.opts.wo or {})
  end
  if not M.env().placeholders then
    return self:render_fallback()
  end
  local width, height = self:grid_size()
  self:render(width, height)
  for _, win in ipairs(self:wins()) do
    vim.api.nvim_win_call(win, function()
      vim.fn.winrestview({ topline = 1, lnum = 1, col = 0, leftcol = 0 })
    end)
  end
  self:request({
    a = "p",
    U = 1,
    i = self.id,
    C = 1,
    c = width,
    r = height,
  })
end

function M:ready()
  return vim.api.nvim_buf_is_valid(self.buf) and (not self._convert or self._convert:is_closing())
end

function M:create()
  -- create the image
  self:request({
    f = 100,
    t = "f",
    i = self.id,
    data = self.file,
  })
end

---@param file string
function M:convert(file)
  local ext = vim.fn.fnamemodify(file, ":e")
  if ext == "png" then
    return file
  end
  local fin = ext == "gif" and file .. "[0]" or file
  local root = vim.fn.stdpath("cache") .. "/snacks/image"
  vim.fn.mkdir(root, "p")
  file = root .. "/" .. Snacks.util.file_encode(fin) .. ".png"
  if vim.fn.filereadable(file) == 1 then
    return file
  end
  self._convert = uv.spawn("magick", {
    args = {
      fin,
      file,
    },
  }, function()
    self._convert:close()
    vim.schedule(function()
      self:create()
      self:update()
    end)
  end)
  return file
end

---@param opts table<string, string|number>|{data?: string}
function M:request(opts)
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
    msg[#msg + 1] = vim.base64.encode(tostring(opts.data))
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
  return vim.tbl_contains(supported_formats, vim.fn.fnamemodify(file, ":e"))
end

--- Check if the file format is supported and the terminal supports the kitty graphics protocol
---@param file string
function M.supports(file)
  return M.supports_file(file) and M.supports_terminal()
end

-- Check if the terminal supports the kitty graphics protocol
function M.supports_terminal()
  local opts = Snacks.config.get("image", defaults)
  return M.env().supported or opts.force or false
end

--- Get the dimensions of a PNG file
---@param file string
---@return number width, number height
function M.dim(file)
  -- extract header with IHDR chunk
  local fd = assert(io.open(vim.fs.normalize(file), "rb"), "Failed to open file: " .. file)
  local header = fd:read(24) ---@type string
  fd:close()

  -- Check PNG signature
  assert(header:sub(1, 8) == "\137PNG\r\n\26\n", "Not a valid PNG file: " .. file)

  -- Extract width and height from the IHDR chunk
  local width = header:byte(17) * 16777216 + header:byte(18) * 65536 + header:byte(19) * 256 + header:byte(20)
  local height = header:byte(21) * 16777216 + header:byte(22) * 65536 + header:byte(23) * 256 + header:byte(24)

  return width, height
end

---@private
function M.health()
  if not Snacks.health.have_tool("magick") then
    Snacks.health.error("`magick` is required to convert images. Only PNG files will be displayed.")
  end
  local opts = Snacks.config.get("image", defaults)
  local env = M.env()
  for _, e in ipairs(environments) do
    if e.detected then
      if e.supported == false then
        Snacks.health.error("`" .. e.name .. "` is not supported")
      else
        Snacks.health.ok("`" .. e.name .. "` is supported")
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
  elseif opts.force then
    Snacks.health.warn("image viewer is enabled with `opts.force = true`. Use at your own risk")
  else
    Snacks.health.error("your terminal does not support the kitty graphics protocol")
    Snacks.health.info("supported terminals: `kitty`, `wezterm`, `ghostty`")
  end
end

return M

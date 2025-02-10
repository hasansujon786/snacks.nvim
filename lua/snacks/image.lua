---@class snacks.Image
---@field id number
---@field buf number
---@field wins table<number, snacks.image.Dim>
---@field opts snacks.image.Config
---@field file string
---@field _convert uv.uv_process_t?
local M = {}
M.__index = M

M.meta = {
  desc = "Image viewer using Kitty Graphics Protocol, supported by `kitty`, `weztermn` and `ghostty`",
  needs_setup = true,
}

---@class snacks.image.Config
---@field file? string
local defaults = {}
local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("snacks.image")

---@alias snacks.image.Dim {col: number, row: number, width: number, height: number}

local images = {} ---@type table<number, snacks.Image>
local id = 30
local ids = {} ---@type table<string, number>
local exts = { "png", "jpg", "jpeg", "gif", "bmp", "webp" }
local diacritics = vim.split(
  "0305,030D,030E,0310,0312,033D,033E,033F,0346,034A,034B,034C,0350,0351,0352,0357,035B,0363,0364,0365,0366,0367,0368,0369,036A,036B,036C,036D,036E,036F,0483,0484,0485,0486,0487,0592,0593,0594,0595,0597,0598,0599,059C,059D,059E,059F,05A0,05A1,05A8,05A9,05AB,05AC,05AF,05C4,0610,0611,0612,0613,0614,0615,0616,0617,0657,0658,0659,065A,065B,065D,065E,06D6,06D7,06D8,06D9,06DA,06DB,06DC,06DF,06E0,06E1,06E2,06E4,06E7,06E8,06EB,06EC,0730,0732,0733,0735,0736,073A,073D,073F,0740,0741,0743,0745,0747,0749,074A,07EB,07EC,07ED,07EE,07EF,07F0,07F1,07F3,0816,0817,0818,0819,081B,081C,081D,081E,081F,0820,0821,0822,0823,0825,0826,0827,0829,082A,082B,082C,082D,0951,0953,0954,0F82,0F83,0F86,0F87,135D,135E,135F,17DD,193A,1A17,1A75,1A76,1A77,1A78,1A79,1A7A,1A7B,1A7C,1B6B,1B6D,1B6E,1B6F,1B70,1B71,1B72,1B73,1CD0,1CD1,1CD2,1CDA,1CDB,1CE0,1DC0,1DC1,1DC3,1DC4,1DC5,1DC6,1DC7,1DC8,1DC9,1DCB,1DCC,1DD1,1DD2,1DD3,1DD4,1DD5,1DD6,1DD7,1DD8,1DD9,1DDA,1DDB,1DDC,1DDD,1DDE,1DDF,1DE0,1DE1,1DE2,1DE3,1DE4,1DE5,1DE6,1DFE,20D0,20D1,20D4,20D5,20D6,20D7,20DB,20DC,20E1,20E7,20E9,20F0,2CEF,2CF0,2CF1,2DE0,2DE1,2DE2,2DE3,2DE4,2DE5,2DE6,2DE7,2DE8,2DE9,2DEA,2DEB,2DEC,2DED,2DEE,2DEF,2DF0,2DF1,2DF2,2DF3,2DF4,2DF5,2DF6,2DF7,2DF8,2DF9,2DFA,2DFB,2DFC,2DFD,2DFE,2DFF,A66F,A67C,A67D,A6F0,A6F1,A8E0,A8E1,A8E2,A8E3,A8E4,A8E5,A8E6,A8E7,A8E8,A8E9,A8EA,A8EB,A8EC,A8ED,A8EE,A8EF,A8F0,A8F1,AAB0,AAB2,AAB3,AAB7,AAB8,AABE,AABF,AAC1,FE20,FE21,FE22,FE23,FE24,FE25,FE26,10A0F,10A38,1D185,1D186,1D187,1D188,1D189,1D1AA,1D1AB,1D1AC,1D1AD,1D242,1D243,1D244",
  ","
)

---@param buf number
---@param opts? snacks.image.Config
function M.new(buf, opts)
  if images[buf] then
    return images[buf]
  end
  local file = opts and opts.file or vim.api.nvim_buf_get_name(buf)
  if not M.supports(file) then
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
  end
  self.id = ids[self.file]

  self.opts = Snacks.config.get("image", defaults, opts or {})

  Snacks.util.bo(buf, {
    filetype = "image",
    buftype = "nofile",
    modifiable = false,
    modified = false,
    swapfile = false,
  })
  self.buf = buf
  self.wins = {}

  local group = vim.api.nvim_create_augroup("snacks.image." .. self.id, { clear = true })
  vim.api.nvim_create_autocmd(
    { "VimResized", "BufWinEnter", "WinClosed", "BufWinLeave", "WinNew", "BufEnter", "BufLeave", "WinResized" },
    {
      group = group,
      buffer = self.buf,
      callback = function()
        vim.schedule(function()
          self:update()
        end)
      end,
    }
  )

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = self.buf,
    callback = function()
      vim.schedule(function()
        self:hide()
      end)
      pcall(vim.api.nvim_del_augroup_by_id, group)
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

function M:grid_size()
  local width, height = vim.o.columns, vim.o.lines
  for _, win in pairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == self.buf then
      width = math.min(width, vim.api.nvim_win_get_width(win))
      height = math.min(height, vim.api.nvim_win_get_height(win))
    end
  end
  return width, height
end

--- Renders the unicode placeholder grid in the buffer
---@param width number
---@param height number
function M:render(width, height)
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

function M:update()
  if not self:ready() then
    return
  end
  local width, height = self:grid_size()
  self:request({
    a = "p",
    U = 1,
    i = self.id,
    c = width,
    r = height,
  })
  vim.schedule(function()
    self:render(width, height)
  end)
end

function M:ready()
  return vim.api.nvim_buf_is_valid(self.buf) and (not self._convert or self._convert:is_closing())
end

function M:create()
  -- create the image
  self:request({
    f = 100,
    s = 2,
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
    msg[#msg + 1] = vim.base64.encode(opts.data)
  end
  local data = "\27_G" .. table.concat(msg) .. "\27\\"
  io.write(data)
end

---@param file string
function M.supports(file)
  return vim.tbl_contains(exts, vim.fn.fnamemodify(file, ":e"))
end

return M

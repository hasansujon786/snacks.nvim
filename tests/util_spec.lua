---@module 'luassert'

describe("util.normkey", function()
  local normkey = require("snacks.util").normkey

  local tests = {
    ["<c-a>"] = "<C-A>",
    ["<C-A>"] = "<C-A>",
    ["<a-a>"] = "<M-a>",
    ["<a-A>"] = "<M-A>",
    ["<m-a>"] = "<M-a>",
    ["<m-A>"] = "<M-A>",
    ["<s-a>"] = "A",
    ["<c-j>"] = "<C-J>",
    ["<c-]>"] = "<C-]>",
    ["<c-\\>"] = "<C-\\>",
    ["<c-/>"] = "<C-/>",
    ["<Cr>"] = "<CR>",
    ["<c-down>"] = "<C-Down>",
    ["<scrollwheelUP>"] = "<ScrollWheelUp>",
    ["<c-scrollwheelUP>"] = "<C-ScrollWheelUp>",
  }

  for input, expected in pairs(tests) do
    it('should normalize "' .. input .. '"', function()
      assert.are.equal(expected, normkey(input))
    end)
  end
end)

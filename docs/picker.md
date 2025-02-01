# 🍿 picker

Snacks now comes with a modern fuzzy-finder to navigate the Neovim universe.

![image](https://github.com/user-attachments/assets/b454fc3c-6613-4aa4-9296-f57a8b02bf6d)
![image](https://github.com/user-attachments/assets/3203aec4-7d75-4bca-b3d5-18d931277e4e)
![image](https://github.com/user-attachments/assets/e09d25f8-8559-441c-a0f7-576d2aa57097)
![image](https://github.com/user-attachments/assets/291dcf63-0c1d-4e9a-97cb-dd5503660e6f)
![image](https://github.com/user-attachments/assets/1aba5737-a650-4a00-94f8-033b7d8d21ba)
![image](https://github.com/user-attachments/assets/976e0ed8-eb80-43e1-93ac-4683136c0a3c)

## ✨ Features

- 🔎 over 40 [built-in sources](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#-sources)
- 🚀 Fast and powerful fuzzy matching engine that supports the [fzf](https://junegunn.github.io/fzf/search-syntax/) search syntax
  - additionally supports field searches like `file:lua$ 'function`
  - `files` and `grep` additionally support adding optiont like `foo -- -e=lua`
- 🌲 uses **treesitter** highlighting where it makes sense
- 🧹 Sane default settings so you can start using it right away
- 💪 Finders and matchers run asynchronously for maximum performance
- 🪟 Different [layouts](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#%EF%B8%8F-layouts) to suit your needs, or create your own.
  Uses [Snacks.layout](https://github.com/folke/snacks.nvim/blob/main/docs/layout.md)
  under the hood.
- 💻 Simple API to create your own pickers
- 📋 Better `vim.ui.select`

Some acknowledgements:

- [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [mini.pick](https://github.com/echasnovski/mini.pick)

## 📚 Usage

The best way to get started is to copy some of the [example configs](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#-examples) below.

```lua
-- Show all pickers
Snacks.picker()

-- run files picker (all three are equivalent)
Snacks.picker.files(opts)
Snacks.picker.pick("files", opts)
Snacks.picker.pick({source = "files", ...})
```

<!-- docgen -->

## 📦 Setup

```lua
-- lazy.nvim
{
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    picker = {
      -- your picker configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  }
}
```

## ⚙️ Config

```lua
---@class snacks.picker.Config
---@field multi? (string|snacks.picker.Config)[]
---@field source? string source name and config to use
---@field pattern? string|fun(picker:snacks.Picker):string pattern used to filter items by the matcher
---@field search? string|fun(picker:snacks.Picker):string search string used by finders
---@field cwd? string current working directory
---@field live? boolean when true, typing will trigger live searches
---@field limit? number when set, the finder will stop after finding this number of items. useful for live searches
---@field ui_select? boolean set `vim.ui.select` to a snacks picker
--- Source definition
---@field items? snacks.picker.finder.Item[] items to show instead of using a finder
---@field format? string|snacks.picker.format|string format function or preset
---@field finder? string|snacks.picker.finder|snacks.picker.finder.multi finder function or preset
---@field preview? snacks.picker.preview|string preview function or preset
---@field matcher? snacks.picker.matcher.Config|{} matcher config
---@field sort? snacks.picker.sort|snacks.picker.sort.Config sort function or config
---@field transform? string|snacks.picker.transform transform/filter function
--- UI
---@field win? snacks.picker.win.Config
---@field layout? snacks.picker.layout.Config|string|{}|fun(source:string):(snacks.picker.layout.Config|string)
---@field icons? snacks.picker.icons
---@field prompt? string prompt text / icon
---@field title? string defaults to a capitalized source name
---@field auto_close? boolean automatically close the picker when focusing another window (defaults to true)
---@field show_empty? boolean show the picker even when there are no items
---@field focus? "input"|"list"|false where to focus when the picker is opened (defaults to "input")
---@field toggles? table<string, string|false|snacks.picker.toggle>
--- Preset options
---@field previewers? snacks.picker.previewers.Config|{}
---@field formatters? snacks.picker.formatters.Config|{}
---@field sources? snacks.picker.sources.Config|{}|table<string, snacks.picker.Config|{}>
---@field layouts? table<string, snacks.picker.layout.Config>
--- Actions
---@field actions? table<string, snacks.picker.Action.spec> actions used by keymaps
---@field confirm? snacks.picker.Action.spec shortcut for confirm action
---@field auto_confirm? boolean automatically confirm if there is only one item
---@field main? snacks.picker.main.Config main editor window config
---@field on_change? fun(picker:snacks.Picker, item?:snacks.picker.Item) called when the cursor changes
---@field on_show? fun(picker:snacks.Picker) called when the picker is shown
---@field jump? snacks.picker.jump.Config|{}
--- Other
---@field config? fun(opts:snacks.picker.Config):snacks.picker.Config? custom config function
---@field debug? snacks.picker.debug|{}
{
  prompt = " ",
  sources = {},
  focus = "input",
  layout = {
    cycle = true,
    --- Use the default layout or vertical if the window is too narrow
    preset = function()
      return vim.o.columns >= 120 and "default" or "vertical"
    end,
  },
  ---@class snacks.picker.matcher.Config
  matcher = {
    fuzzy = true, -- use fuzzy matching
    smartcase = true, -- use smartcase
    ignorecase = true, -- use ignorecase
    sort_empty = false, -- sort results when the search string is empty
    filename_bonus = true, -- give bonus for matching file names (last part of the path)
    file_pos = true, -- support patterns like `file:line:col` and `file:line`
    -- the bonusses below, possibly require string concatenation and path normalization,
    -- so this can have a performance impact for large lists and increase memory usage
    cwd_bonus = false, -- give bonus for matching files in the cwd
    frecency = false, -- frecency bonus
  },
  sort = {
    -- default sort is by score, text length and index
    fields = { "score:desc", "#text", "idx" },
  },
  ui_select = true, -- replace `vim.ui.select` with the snacks picker
  ---@class snacks.picker.formatters.Config
  formatters = {
    text = {
      ft = nil, ---@type string? filetype for highlighting
    },
    file = {
      filename_first = false, -- display filename before the file path
      truncate = 40, -- truncate the file path to (roughly) this length
      filename_only = false, -- only show the filename
    },
    selected = {
      show_always = false, -- only show the selected column when there are multiple selections
      unselected = true, -- use the unselected icon for unselected items
    },
    severity = {
      icons = true, -- show severity icons
      level = false, -- show severity level
    },
  },
  ---@class snacks.picker.previewers.Config
  previewers = {
    git = {
      native = false, -- use native (terminal) or Neovim for previewing git diffs and commits
    },
    file = {
      max_size = 1024 * 1024, -- 1MB
      max_line_length = 500, -- max line length
      ft = nil, ---@type string? filetype for highlighting. Use `nil` for auto detect
    },
    man_pager = nil, ---@type string? MANPAGER env to use for `man` preview
  },
  ---@class snacks.picker.jump.Config
  jump = {
    jumplist = true, -- save the current position in the jumplist
    tagstack = false, -- save the current position in the tagstack
    reuse_win = false, -- reuse an existing window if the buffer is already open
    close = true, -- close the picker when jumping/editing to a location (defaults to true)
    match = false, -- jump to the first match position. (useful for `lines`)
  },
  toggles = {
    follow = "f",
    hidden = "h",
    ignored = "i",
    modified = "m",
    regex = { icon = "R", value = false },
  },
  win = {
    -- input window
    input = {
      keys = {
        -- to close the picker on ESC instead of going to normal mode,
        -- add the following keymap to your config
        -- ["<Esc>"] = { "close", mode = { "n", "i" } },
        ["/"] = "toggle_focus",
        ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
        ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
        ["<C-c>"] = { "close", mode = "i" },
        ["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
        ["<CR>"] = { "confirm", mode = { "n", "i" } },
        ["<Down>"] = { "list_down", mode = { "i", "n" } },
        ["<Esc>"] = "close",
        ["<S-CR>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
        ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },
        ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },
        ["<Up>"] = { "list_up", mode = { "i", "n" } },
        ["<a-d>"] = { "inspect", mode = { "n", "i" } },
        ["<a-f>"] = { "toggle_follow", mode = { "i", "n" } },
        ["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } },
        ["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
        ["<a-m>"] = { "toggle_maximize", mode = { "i", "n" } },
        ["<a-p>"] = { "toggle_preview", mode = { "i", "n" } },
        ["<a-w>"] = { "cycle_win", mode = { "i", "n" } },
        ["<c-a>"] = { "select_all", mode = { "n", "i" } },
        ["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
        ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
        ["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
        ["<c-g>"] = { "toggle_live", mode = { "i", "n" } },
        ["<c-j>"] = { "list_down", mode = { "i", "n" } },
        ["<c-k>"] = { "list_up", mode = { "i", "n" } },
        ["<c-n>"] = { "list_down", mode = { "i", "n" } },
        ["<c-p>"] = { "list_up", mode = { "i", "n" } },
        ["<c-q>"] = { "qflist", mode = { "i", "n" } },
        ["<c-s>"] = { "edit_split", mode = { "i", "n" } },
        ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
        ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
        ["?"] = "toggle_help_input",
        ["G"] = "list_bottom",
        ["gg"] = "list_top",
        ["j"] = "list_down",
        ["k"] = "list_up",
        ["q"] = "close",
      },
      b = {
        minipairs_disable = true,
      },
    },
    -- result list window
    list = {
      keys = {
        ["/"] = "toggle_focus",
        ["<2-LeftMouse>"] = "confirm",
        ["<CR>"] = "confirm",
        ["<Down>"] = "list_down",
        ["<Esc>"] = "close",
        ["<S-CR>"] = { { "pick_win", "jump" } },
        ["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },
        ["<Tab>"] = { "select_and_next", mode = { "n", "x" } },
        ["<Up>"] = "list_up",
        ["<a-d>"] = "inspect",
        ["<a-f>"] = "toggle_follow",
        ["<a-h>"] = "toggle_hidden",
        ["<a-i>"] = "toggle_ignored",
        ["<a-m>"] = "toggle_maximize",
        ["<a-p>"] = "toggle_preview",
        ["<a-w>"] = "cycle_win",
        ["<c-a>"] = "select_all",
        ["<c-b>"] = "preview_scroll_up",
        ["<c-d>"] = "list_scroll_down",
        ["<c-f>"] = "preview_scroll_down",
        ["<c-j>"] = "list_down",
        ["<c-k>"] = "list_up",
        ["<c-n>"] = "list_down",
        ["<c-p>"] = "list_up",
        ["<c-s>"] = "edit_split",
        ["<c-u>"] = "list_scroll_up",
        ["<c-v>"] = "edit_vsplit",
        ["?"] = "toggle_help_list",
        ["G"] = "list_bottom",
        ["gg"] = "list_top",
        ["i"] = "focus_input",
        ["j"] = "list_down",
        ["k"] = "list_up",
        ["q"] = "close",
        ["zb"] = "list_scroll_bottom",
        ["zt"] = "list_scroll_top",
        ["zz"] = "list_scroll_center",
      },
      wo = {
        conceallevel = 2,
        concealcursor = "nvc",
      },
    },
    -- preview window
    preview = {
      keys = {
        ["<Esc>"] = "close",
        ["q"] = "close",
        ["i"] = "focus_input",
        ["<ScrollWheelDown>"] = "list_scroll_wheel_down",
        ["<ScrollWheelUp>"] = "list_scroll_wheel_up",
        ["<a-w>"] = "cycle_win",
      },
    },
  },
  ---@class snacks.picker.icons
  icons = {
    files = {
      enabled = true, -- show file icons
    },
    keymaps = {
      nowait = "󰓅 "
    },
    tree = {
      vertical = "│ ",
      middle   = "├╴",
      last     = "└╴",
    },
    undo = {
      saved   = " ",
    },
    ui = {
      live        = "󰐰 ",
      hidden      = "h",
      ignored     = "i",
      follow      = "f",
      selected    = "● ",
      unselected  = "○ ",
      -- selected = " ",
    },
    git = {
      enabled   = true, -- show git icons
      commit    = "󰜘 ", -- used by git log
      staged    = "●", -- staged changes. always overrides the type icons
      added     = "",
      deleted   = "",
      ignored   = " ",
      modified  = "○",
      renamed   = "",
      unmerged  = " ",
      untracked = "?",
    },
    diagnostics = {
      Error = " ",
      Warn  = " ",
      Hint  = " ",
      Info  = " ",
    },
    kinds = {
      Array         = " ",
      Boolean       = "󰨙 ",
      Class         = " ",
      Color         = " ",
      Control       = " ",
      Collapsed     = " ",
      Constant      = "󰏿 ",
      Constructor   = " ",
      Copilot       = " ",
      Enum          = " ",
      EnumMember    = " ",
      Event         = " ",
      Field         = " ",
      File          = " ",
      Folder        = " ",
      Function      = "󰊕 ",
      Interface     = " ",
      Key           = " ",
      Keyword       = " ",
      Method        = "󰊕 ",
      Module        = " ",
      Namespace     = "󰦮 ",
      Null          = " ",
      Number        = "󰎠 ",
      Object        = " ",
      Operator      = " ",
      Package       = " ",
      Property      = " ",
      Reference     = " ",
      Snippet       = "󱄽 ",
      String        = " ",
      Struct        = "󰆼 ",
      Text          = " ",
      TypeParameter = " ",
      Unit          = " ",
      Unknown        = " ",
      Value         = " ",
      Variable      = "󰀫 ",
    },
  },
  ---@class snacks.picker.debug
  debug = {
    scores = false, -- show scores in the list
    leaks = false, -- show when pickers don't get garbage collected
  },
}
```

## 🚀 Examples

### `general`

```lua
{
  "folke/snacks.nvim",
  opts = {
    picker = {},
  },
  keys = {
    { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader><space>", function() Snacks.picker.files() end, desc = "Find Files" },
    -- find
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
    -- git
    { "<leader>gc", function() Snacks.picker.git_log() end, desc = "Git Log" },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
    -- Grep
    { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
    -- search
    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
    { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
    { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
    { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    { "<leader>qp", function() Snacks.picker.projects() end, desc = "Projects" },
    -- LSP
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
  },
}
```

### `todo_comments`

```lua
{
  "folke/todo-comments.nvim",
  optional = true,
  keys = {
    { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "Todo" },
    { "<leader>sT", function () Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "Todo/Fix/Fixme" },
  },
}
```

### `trouble`

```lua
{
  "folke/trouble.nvim",
  optional = true,
  specs = {
    "folke/snacks.nvim",
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts or {}, {
        picker = {
          actions = require("trouble.sources.snacks").actions,
          win = {
            input = {
              keys = {
                ["<c-t>"] = {
                  "trouble_open",
                  mode = { "n", "i" },
                },
              },
            },
          },
        },
      })
    end,
  },
}
```

## 📚 Types

```lua
---@class snacks.picker.jump.Action: snacks.picker.Action
---@field cmd? snacks.picker.EditCmd
```

```lua
---@alias snacks.picker.Extmark vim.api.keyset.set_extmark|{col:number, row?:number, field?:string}
---@alias snacks.picker.Text {[1]:string, [2]:string?, virtual?:boolean, field?:string}
---@alias snacks.picker.Highlight snacks.picker.Text|snacks.picker.Extmark
---@alias snacks.picker.format fun(item:snacks.picker.Item, picker:snacks.Picker):snacks.picker.Highlight[]
---@alias snacks.picker.preview fun(ctx: snacks.picker.preview.ctx):boolean?
---@alias snacks.picker.sort fun(a:snacks.picker.Item, b:snacks.picker.Item):boolean
---@alias snacks.picker.transform fun(item:snacks.picker.finder.Item, ctx:snacks.picker.finder.ctx):(boolean|snacks.picker.finder.Item|nil)
---@alias snacks.picker.Pos {[1]:number, [2]:number}
---@alias snacks.picker.toggle {icon?:string, enabled?:boolean, value?:boolean}
```

Generic filter used by finders to pre-filter items

```lua
---@class snacks.picker.filter.Config
---@field cwd? boolean|string only show files for the given cwd
---@field buf? boolean|number only show items for the current or given buffer
---@field paths? table<string, boolean> only show items that include or exclude the given paths
---@field filter? fun(item:snacks.picker.finder.Item, filter:snacks.picker.Filter):boolean? custom filter function
---@field transform? fun(picker:snacks.Picker, filter:snacks.picker.Filter):boolean? filter transform. Return `true` to force refresh
```

This is only used when using `opts.preview = "preview"`.
It's a previewer that shows a preview based on the item data.

```lua
---@class snacks.picker.Item.preview
---@field text string text to show in the preview buffer
---@field ft? string optional filetype used tohighlight the preview buffer
---@field extmarks? snacks.picker.Extmark[] additional extmarks
---@field loc? boolean set to false to disable showing the item location in the preview
```

```lua
---@class snacks.picker.Item
---@field [string] any
---@field idx number
---@field score number
---@field frecency? number
---@field score_add? number
---@field score_mul? number
---@field source_id? number
---@field file? string
---@field text string
---@field pos? snacks.picker.Pos
---@field loc? snacks.picker.lsp.Loc
---@field end_pos? snacks.picker.Pos
---@field highlights? snacks.picker.Highlight[][]
---@field preview? snacks.picker.Item.preview
---@field resolve? fun(item:snacks.picker.Item)
```

```lua
---@class snacks.picker.finder.Item: snacks.picker.Item
---@field idx? number
---@field score? number
```

```lua
---@class snacks.picker.layout.Config
---@field layout snacks.layout.Box
---@field reverse? boolean when true, the list will be reversed (bottom-up)
---@field fullscreen? boolean open in fullscreen
---@field cycle? boolean cycle through the list
---@field preview? boolean|"main" show preview window in the picker or the main window
---@field preset? string|fun(source:string):string
```

```lua
---@class snacks.picker.win.Config
---@field input? snacks.win.Config|{} input window config
---@field list? snacks.win.Config|{} result list window config
---@field preview? snacks.win.Config|{} preview window config
```

```lua
---@alias snacks.Picker.ref (fun():snacks.Picker?)|{value?: snacks.Picker}
```

```lua
---@class snacks.picker.Last
---@field cursor number
---@field topline number
---@field opts? snacks.picker.Config
---@field selected snacks.picker.Item[]
---@field filter snacks.picker.Filter
```

```lua
---@alias snacks.picker.history.Record {pattern: string, search: string, live?: boolean}
```

## 📦 Module

```lua
---@class snacks.picker
---@field actions snacks.picker.actions
---@field config snacks.picker.config
---@field format snacks.picker.formatters
---@field preview snacks.picker.previewers
---@field sort snacks.picker.sorters
---@field util snacks.picker.util
---@field current? snacks.Picker
---@field highlight snacks.picker.highlight
---@field resume fun(opts?: snacks.picker.Config):snacks.Picker
---@field sources snacks.picker.sources.Config
Snacks.picker = {}
```

### `Snacks.picker()`

```lua
---@type fun(source: string, opts: snacks.picker.Config): snacks.Picker
Snacks.picker()
```

```lua
---@type fun(opts: snacks.picker.Config): snacks.Picker
Snacks.picker()
```

### `Snacks.picker.get()`

Get active pickers, optionally filtered by source

```lua
---@param opts? {source?: string}
Snacks.picker.get(opts)
```

### `Snacks.picker.pick()`

Create a new picker

```lua
---@param source? string
---@param opts? snacks.picker.Config
---@overload fun(opts: snacks.picker.Config): snacks.Picker
Snacks.picker.pick(source, opts)
```

### `Snacks.picker.select()`

Implementation for `vim.ui.select`

```lua
---@type snacks.picker.ui_select
Snacks.picker.select(...)
```
## 🔍 Sources

### `autocmds`

```vim
:lua Snacks.picker.autocmds(opts?)
```

```lua
{
  finder = "vim_autocmds",
  format = "autocmd",
  preview = "preview",
}
```

### `buffers`

```vim
:lua Snacks.picker.buffers(opts?)
```

```lua
---@class snacks.picker.buffers.Config: snacks.picker.Config
---@field hidden? boolean show hidden buffers (unlisted)
---@field unloaded? boolean show loaded buffers
---@field current? boolean show current buffer
---@field nofile? boolean show `buftype=nofile` buffers
---@field modified? boolean show only modified buffers
---@field sort_lastused? boolean sort by last used
---@field filter? snacks.picker.filter.Config
{
  finder = "buffers",
  format = "buffer",
  hidden = false,
  unloaded = true,
  current = true,
  sort_lastused = true,
  win = {
    input = {
      keys = {
        ["dd"] = "bufdelete",
        ["<c-x>"] = { "bufdelete", mode = { "n", "i" } },
      },
    },
    list = { keys = { ["dd"] = "bufdelete" } },
  },
}
```

### `cliphist`

```vim
:lua Snacks.picker.cliphist(opts?)
```

```lua
{
  finder = "system_cliphist",
  format = "text",
  preview = "preview",
  confirm = { "copy", "close" },
}
```

### `colorschemes`

```vim
:lua Snacks.picker.colorschemes(opts?)
```

Neovim colorschemes with live preview

```lua
{
  finder = "vim_colorschemes",
  format = "text",
  preview = "colorscheme",
  preset = "vertical",
  confirm = function(picker, item)
    picker:close()
    if item then
      picker.preview.state.colorscheme = nil
      vim.schedule(function()
        vim.cmd("colorscheme " .. item.text)
      end)
    end
  end,
}
```

### `command_history`

```vim
:lua Snacks.picker.command_history(opts?)
```

Neovim command history

```lua
---@type snacks.picker.history.Config
{
  finder = "vim_history",
  name = "cmd",
  format = "text",
  preview = "none",
  layout = {
    preset = "vscode",
  },
  confirm = "cmd",
  formatters = { text = { ft = "vim" } },
}
```

### `commands`

```vim
:lua Snacks.picker.commands(opts?)
```

Neovim commands

```lua
{
  finder = "vim_commands",
  format = "command",
  preview = "preview",
  confirm = "cmd",
}
```

### `diagnostics`

```vim
:lua Snacks.picker.diagnostics(opts?)
```

```lua
---@class snacks.picker.diagnostics.Config: snacks.picker.Config
---@field filter? snacks.picker.filter.Config
---@field severity? vim.diagnostic.SeverityFilter
{
  finder = "diagnostics",
  format = "diagnostic",
  sort = {
    fields = {
      "is_current",
      "is_cwd",
      "severity",
      "file",
      "lnum",
    },
  },
  matcher = { sort_empty = true },
  -- only show diagnostics from the cwd by default
  filter = { cwd = true },
}
```

### `diagnostics_buffer`

```vim
:lua Snacks.picker.diagnostics_buffer(opts?)
```

```lua
---@type snacks.picker.diagnostics.Config
{
  finder = "diagnostics",
  format = "diagnostic",
  sort = {
    fields = { "severity", "file", "lnum" },
  },
  matcher = { sort_empty = true },
  filter = { buf = true },
}
```

### `explorer`

```vim
:lua Snacks.picker.explorer(opts?)
```

```lua
---@class snacks.picker.explorer.Config: snacks.picker.files.Config|{}
---@field follow_file? boolean follow the file from the current buffer
---@field tree? boolean show the file tree (default: true)
---@field git_status? boolean show git status (default: true)
---@field git_status_open? boolean show recursive git status for open directories
{
  finder = "explorer",
  sort = { fields = { "sort" } },
  tree = true,
  git_status = true,
  git_status_open = false,
  supports_live = true,
  follow_file = true,
  focus = "list",
  auto_close = false,
  jump = { close = false },
  layout = { preset = "sidebar", preview = false },
  formatters = { file = { filename_only = true } },
  matcher = { sort_empty = true },
  config = function(opts)
    return require("snacks.picker.source.explorer").setup(opts)
  end,
  win = {
    list = {
      keys = {
        ["<BS>"] = "explorer_up",
        ["l"] = "confirm",
        ["h"] = "explorer_close", -- close directory
        ["a"] = "explorer_add",
        ["d"] = "explorer_del",
        ["r"] = "explorer_rename",
        ["c"] = "explorer_copy",
        ["m"] = "explorer_move",
        ["o"] = "explorer_open", -- open with system application
        ["P"] = "toggle_preview",
        ["y"] = "explorer_yank",
        ["u"] = "explorer_update",
        ["<c-c>"] = "explorer_cd",
        ["."] = "explorer_focus",
        ["I"] = "toggle_ignored",
        ["H"] = "toggle_hidden",
        ["Z"] = "explorer_close_all",
        ["]g"] = "explorer_git_next",
        ["[g"] = "explorer_git_prev",
      },
    },
  },
}
```

### `files`

```vim
:lua Snacks.picker.files(opts?)
```

```lua
---@class snacks.picker.files.Config: snacks.picker.proc.Config
---@field cmd? "fd"| "rg"| "find" command to use. Leave empty to auto-detect
---@field hidden? boolean show hidden files
---@field ignored? boolean show ignored files
---@field dirs? string[] directories to search
---@field follow? boolean follow symlinks
---@field exclude? string[] exclude patterns
---@field args? string[] additional arguments
---@field rtp? boolean search in runtimepath
{
  finder = "files",
  format = "file",
  show_empty = true,
  hidden = false,
  ignored = false,
  follow = false,
  supports_live = true,
}
```

### `git_branches`

```vim
:lua Snacks.picker.git_branches(opts?)
```

```lua
{
  finder = "git_branches",
  format = "git_branch",
  preview = "git_log",
  confirm = "git_checkout",
  on_show = function(picker)
    for i, item in ipairs(picker:items()) do
      if item.current then
        picker.list:view(i)
        Snacks.picker.actions.list_scroll_center(picker)
        break
      end
    end
  end,
}
```

### `git_diff`

```vim
:lua Snacks.picker.git_diff(opts?)
```

```lua
{
  finder = "git_diff",
  format = "file",
  preview = "preview",
}
```

### `git_files`

```vim
:lua Snacks.picker.git_files(opts?)
```

Find git files

```lua
---@class snacks.picker.git.files.Config: snacks.picker.Config
---@field untracked? boolean show untracked files
---@field submodules? boolean show submodule files
{
  finder = "git_files",
  show_empty = true,
  format = "file",
  untracked = false,
  submodules = false,
}
```

### `git_log`

```vim
:lua Snacks.picker.git_log(opts?)
```

Git log

```lua
---@class snacks.picker.git.log.Config: snacks.picker.Config
---@field follow? boolean track file history across renames
---@field current_file? boolean show current file log
---@field current_line? boolean show current line log
{
  finder = "git_log",
  format = "git_log",
  preview = "git_show",
  confirm = "git_checkout",
}
```

### `git_log_file`

```vim
:lua Snacks.picker.git_log_file(opts?)
```

```lua
---@type snacks.picker.git.log.Config
{
  finder = "git_log",
  format = "git_log",
  preview = "git_show",
  current_file = true,
  follow = true,
  confirm = "git_checkout",
}
```

### `git_log_line`

```vim
:lua Snacks.picker.git_log_line(opts?)
```

```lua
---@type snacks.picker.git.log.Config
{
  finder = "git_log",
  format = "git_log",
  preview = "git_show",
  current_line = true,
  follow = true,
  confirm = "git_checkout",
}
```

### `git_stash`

```vim
:lua Snacks.picker.git_stash(opts?)
```

```lua
{
  finder = "git_stash",
  format = "git_stash",
  preview = "git_stash",
  confirm = "git_stash_apply",
}
```

### `git_status`

```vim
:lua Snacks.picker.git_status(opts?)
```

```lua
{
  finder = "git_status",
  format = "git_status",
  preview = "git_status",
  win = {
    input = {
      keys = {
        ["<Tab>"] = { "git_stage", mode = { "n", "i" } },
      },
    },
  },
}
```

### `grep`

```vim
:lua Snacks.picker.grep(opts?)
```

```lua
---@class snacks.picker.grep.Config: snacks.picker.proc.Config
---@field cmd? string
---@field hidden? boolean show hidden files
---@field ignored? boolean show ignored files
---@field dirs? string[] directories to search
---@field follow? boolean follow symlinks
---@field glob? string|string[] glob file pattern(s)
---@field ft? string|string[] ripgrep file type(s). See `rg --type-list`
---@field regex? boolean use regex search pattern (defaults to `true`)
---@field buffers? boolean search in open buffers
---@field need_search? boolean require a search pattern
---@field exclude? string[] exclude patterns
---@field args? string[] additional arguments
---@field rtp? boolean search in runtimepath
{
  finder = "grep",
  regex = true,
  format = "file",
  show_empty = true,
  live = true, -- live grep by default
  supports_live = true,
}
```

### `grep_buffers`

```vim
:lua Snacks.picker.grep_buffers(opts?)
```

```lua
---@type snacks.picker.grep.Config|{}
{
  finder = "grep",
  format = "file",
  live = true,
  buffers = true,
  need_search = false,
  supports_live = true,
}
```

### `grep_word`

```vim
:lua Snacks.picker.grep_word(opts?)
```

```lua
---@type snacks.picker.grep.Config|{}
{
  finder = "grep",
  format = "file",
  search = function(picker)
    return picker:word()
  end,
  live = false,
  supports_live = true,
}
```

### `help`

```vim
:lua Snacks.picker.help(opts?)
```

Neovim help tags

```lua
---@class snacks.picker.help.Config: snacks.picker.Config
---@field lang? string[] defaults to `vim.opt.helplang`
{
  finder = "help",
  format = "text",
  previewers = {
    file = { ft = "help" },
  },
  win = { preview = { minimal = true } },
  confirm = "help",
}
```

### `highlights`

```vim
:lua Snacks.picker.highlights(opts?)
```

```lua
{
  finder = "vim_highlights",
  format = "hl",
  preview = "preview",
}
```

### `icons`

```vim
:lua Snacks.picker.icons(opts?)
```

```lua
---@class snacks.picker.icons.Config: snacks.picker.Config
---@field icon_sources? string[]
{
  icon_sources = { "nerd_fonts", "emoji" },
  finder = "icons",
  format = "icon",
  layout = { preset = "vscode" },
  confirm = "put",
}
```

### `jumps`

```vim
:lua Snacks.picker.jumps(opts?)
```

```lua
{
  finder = "vim_jumps",
  format = "file",
}
```

### `keymaps`

```vim
:lua Snacks.picker.keymaps(opts?)
```

```lua
---@class snacks.picker.keymaps.Config: snacks.picker.Config
---@field global? boolean show global keymaps
---@field local? boolean show buffer keymaps
---@field plugs? boolean show plugin keymaps
---@field modes? string[]
{
  finder = "vim_keymaps",
  format = "keymap",
  preview = "preview",
  global = true,
  plugs = false,
  ["local"] = true,
  modes = { "n", "v", "x", "s", "o", "i", "c", "t" },
  confirm = function(picker, item)
    picker:close()
    if item then
      vim.api.nvim_input(item.item.lhs)
    end
  end,
  actions = {
    toggle_global = function(picker)
      picker.opts.global = not picker.opts.global
      picker:find()
    end,
    toggle_buffer = function(picker)
      picker.opts["local"] = not picker.opts["local"]
      picker:find()
    end,
  },
  win = {
    input = {
      keys = {
        ["<a-g>"] = { "toggle_global", mode = { "n", "i" }, desc = "Toggle Global Keymaps" },
        ["<a-b>"] = { "toggle_buffer", mode = { "n", "i" }, desc = "Toggle Buffer Keymaps" },
      },
    },
  },
}
```

### `lazy`

```vim
:lua Snacks.picker.lazy(opts?)
```

Search for a lazy.nvim plugin spec

```lua
{
  finder = "lazy_spec",
  live = false,
  pattern = "'",
}
```

### `lines`

```vim
:lua Snacks.picker.lines(opts?)
```

Search lines in the current buffer

```lua
---@class snacks.picker.lines.Config: snacks.picker.Config
---@field buf? number
{
  finder = "lines",
  format = "lines",
  layout = {
    preview = "main",
    preset = "ivy",
  },
  jump = { match = true },
  -- allow any window to be used as the main window
  main = { current = true },
  ---@param picker snacks.Picker
  on_show = function(picker)
    local cursor = vim.api.nvim_win_get_cursor(picker.main)
    local info = vim.api.nvim_win_call(picker.main, vim.fn.winsaveview)
    picker.list:view(cursor[1], info.topline)
    picker:show_preview()
  end,
  sort = { fields = { "score:desc", "idx" } },
}
```

### `loclist`

```vim
:lua Snacks.picker.loclist(opts?)
```

Loclist

```lua
---@type snacks.picker.qf.Config
{
  finder = "qf",
  format = "file",
  qf_win = 0,
}
```

### `lsp_declarations`

```vim
:lua Snacks.picker.lsp_declarations(opts?)
```

LSP declarations

```lua
---@type snacks.picker.lsp.Config
{
  finder = "lsp_declarations",
  format = "file",
  include_current = false,
  auto_confirm = true,
  jump = { tagstack = true, reuse_win = true },
}
```

### `lsp_definitions`

```vim
:lua Snacks.picker.lsp_definitions(opts?)
```

LSP definitions

```lua
---@type snacks.picker.lsp.Config
{
  finder = "lsp_definitions",
  format = "file",
  include_current = false,
  auto_confirm = true,
  jump = { tagstack = true, reuse_win = true },
}
```

### `lsp_implementations`

```vim
:lua Snacks.picker.lsp_implementations(opts?)
```

LSP implementations

```lua
---@type snacks.picker.lsp.Config
{
  finder = "lsp_implementations",
  format = "file",
  include_current = false,
  auto_confirm = true,
  jump = { tagstack = true, reuse_win = true },
}
```

### `lsp_references`

```vim
:lua Snacks.picker.lsp_references(opts?)
```

LSP references

```lua
---@class snacks.picker.lsp.references.Config: snacks.picker.lsp.Config
---@field include_declaration? boolean default true
{
  finder = "lsp_references",
  format = "file",
  include_declaration = true,
  include_current = false,
  auto_confirm = true,
  jump = { tagstack = true, reuse_win = true },
}
```

### `lsp_symbols`

```vim
:lua Snacks.picker.lsp_symbols(opts?)
```

LSP document symbols

```lua
---@class snacks.picker.lsp.symbols.Config: snacks.picker.Config
---@field tree? boolean show symbol tree
---@field filter table<string, string[]|boolean>? symbol kind filter
---@field workspace? boolean show workspace symbols
{
  finder = "lsp_symbols",
  format = "lsp_symbol",
  tree = true,
  filter = {
    default = {
      "Class",
      "Constructor",
      "Enum",
      "Field",
      "Function",
      "Interface",
      "Method",
      "Module",
      "Namespace",
      "Package",
      "Property",
      "Struct",
      "Trait",
    },
    -- set to `true` to include all symbols
    markdown = true,
    help = true,
    -- you can specify a different filter for each filetype
    lua = {
      "Class",
      "Constructor",
      "Enum",
      "Field",
      "Function",
      "Interface",
      "Method",
      "Module",
      "Namespace",
      -- "Package", -- remove package since luals uses it for control flow structures
      "Property",
      "Struct",
      "Trait",
    },
  },
}
```

### `lsp_type_definitions`

```vim
:lua Snacks.picker.lsp_type_definitions(opts?)
```

LSP type definitions

```lua
---@type snacks.picker.lsp.Config
{
  finder = "lsp_type_definitions",
  format = "file",
  include_current = false,
  auto_confirm = true,
  jump = { tagstack = true, reuse_win = true },
}
```

### `lsp_workspace_symbols`

```vim
:lua Snacks.picker.lsp_workspace_symbols(opts?)
```

```lua
---@type snacks.picker.lsp.symbols.Config
vim.tbl_extend("force", {}, M.lsp_symbols, {
  workspace = true,
  tree = false,
  supports_live = true,
  live = true, -- live by default
})
```

### `man`

```vim
:lua Snacks.picker.man(opts?)
```

```lua
{
  finder = "system_man",
  format = "man",
  preview = "man",
  confirm = function(picker, item)
    picker:close()
    if item then
      vim.schedule(function()
        vim.cmd("Man " .. item.ref)
      end)
    end
  end,
}
```

### `marks`

```vim
:lua Snacks.picker.marks(opts?)
```

```lua
---@class snacks.picker.marks.Config: snacks.picker.Config
---@field global? boolean show global marks
---@field local? boolean show buffer marks
{
  finder = "vim_marks",
  format = "file",
  global = true,
  ["local"] = true,
}
```

### `notifications`

```vim
:lua Snacks.picker.notifications(opts?)
```

```lua
---@class snacks.picker.notifications.Config: snacks.picker.Config
---@field filter? snacks.notifier.level|fun(notif: snacks.notifier.Notif): boolean
{
  finder = "snacks_notifier",
  format = "notification",
  preview = "preview",
  formatters = { severity = { level = true } },
}
```

### `picker_actions`

```vim
:lua Snacks.picker.picker_actions(opts?)
```

```lua
{
  finder = "meta_actions",
  format = "text",
}
```

### `picker_format`

```vim
:lua Snacks.picker.picker_format(opts?)
```

```lua
{
  finder = "meta_format",
  format = "text",
}
```

### `picker_layouts`

```vim
:lua Snacks.picker.picker_layouts(opts?)
```

```lua
{
  finder = "meta_layouts",
  format = "text",
  on_change = function(picker, item)
    vim.schedule(function()
      picker:set_layout(item.text)
    end)
  end,
}
```

### `picker_preview`

```vim
:lua Snacks.picker.picker_preview(opts?)
```

```lua
{
  finder = "meta_preview",
  format = "text",
}
```

### `pickers`

```vim
:lua Snacks.picker.pickers(opts?)
```

List all available sources

```lua
{
  finder = "meta_pickers",
  format = "text",
  confirm = function(picker, item)
    picker:close()
    if item then
      vim.schedule(function()
        Snacks.picker(item.text)
      end)
    end
  end,
}
```

### `projects`

```vim
:lua Snacks.picker.projects(opts?)
```

Open recent projects

```lua
---@class snacks.picker.projects.Config: snacks.picker.Config
---@field filter? snacks.picker.filter.Config
{
  finder = "recent_projects",
  format = "file",
  confirm = "load_session",
  win = {
    preview = {
      minimal = true,
    },
  },
}
```

### `qflist`

```vim
:lua Snacks.picker.qflist(opts?)
```

Quickfix list

```lua
---@type snacks.picker.qf.Config
{
  finder = "qf",
  format = "file",
}
```

### `recent`

```vim
:lua Snacks.picker.recent(opts?)
```

Find recent files

```lua
---@class snacks.picker.recent.Config: snacks.picker.Config
---@field filter? snacks.picker.filter.Config
{
  finder = "recent_files",
  format = "file",
  filter = {
    paths = {
      [vim.fn.stdpath("data")] = false,
      [vim.fn.stdpath("cache")] = false,
      [vim.fn.stdpath("state")] = false,
    },
  },
}
```

### `registers`

```vim
:lua Snacks.picker.registers(opts?)
```

Neovim registers

```lua
{
  finder = "vim_registers",
  format = "register",
  preview = "preview",
  confirm = { "copy", "close" },
}
```

### `resume`

```vim
:lua Snacks.picker.resume(opts?)
```

Special picker that resumes the last picker

```lua
{}
```

### `search_history`

```vim
:lua Snacks.picker.search_history(opts?)
```

Neovim search history

```lua
---@type snacks.picker.history.Config
{
  finder = "vim_history",
  name = "search",
  format = "text",
  preview = "none",
  layout = { preset = "vscode" },
  confirm = "search",
  formatters = { text = { ft = "regex" } },
}
```

### `select`

```vim
:lua Snacks.picker.select(opts?)
```

Config used by `vim.ui.select`.
Not meant to be used directly.

```lua
{
  items = {}, -- these are set dynamically
  main = { current = true },
  layout = { preset = "select" },
}
```

### `smart`

```vim
:lua Snacks.picker.smart(opts?)
```

```lua
---@class snacks.picker.smart.Config: snacks.picker.Config
---@field finders? string[] list of finders to use
---@field filter? snacks.picker.filter.Config
{
  multi = { "buffers", "recent", "files" },
  format = "file", -- use `file` format for all sources
  matcher = {
    cwd_bonus = true, -- boost cwd matches
    frecency = true, -- use frecency boosting
    sort_empty = true, -- sort even when the filter is empty
  },
  transform = "unique_file",
}
```

### `spelling`

```vim
:lua Snacks.picker.spelling(opts?)
```

```lua
{
  finder = "vim_spelling",
  format = "text",
  layout = { preset = "vscode" },
  confirm = "item_action",
}
```

### `undo`

```vim
:lua Snacks.picker.undo(opts?)
```

```lua
{
  finder = "vim_undo",
  format = "undo",
  preview = "preview",
  confirm = "item_action",
  win = { preview = { wo = { number = false, relativenumber = false, signcolumn = "no" } } },
}
```

### `zoxide`

```vim
:lua Snacks.picker.zoxide(opts?)
```

Open a project from zoxide

```lua
{
  finder = "files_zoxide",
  format = "file",
  confirm = "load_session",
  win = {
    preview = {
      minimal = true,
    },
  },
}
```

## 🖼️ Layouts

### `default`

```lua
{
  layout = {
    box = "horizontal",
    width = 0.8,
    min_width = 120,
    height = 0.8,
    {
      box = "vertical",
      border = "rounded",
      title = "{title} {live} {flags}",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
    },
    { win = "preview", title = "{preview}", border = "rounded", width = 0.5 },
  },
}
```

### `dropdown`

```lua
{
  layout = {
    backdrop = false,
    row = 1,
    width = 0.4,
    min_width = 80,
    height = 0.8,
    border = "none",
    box = "vertical",
    { win = "preview", title = "{preview}", height = 0.4, border = "rounded" },
    {
      box = "vertical",
      border = "rounded",
      title = "{title} {live} {flags}",
      title_pos = "center",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
    },
  },
}
```

### `ivy`

```lua
{
  layout = {
    box = "vertical",
    backdrop = false,
    row = -1,
    width = 0,
    height = 0.4,
    border = "top",
    title = " {title} {live} {flags}",
    title_pos = "left",
    { win = "input", height = 1, border = "bottom" },
    {
      box = "horizontal",
      { win = "list", border = "none" },
      { win = "preview", title = "{preview}", width = 0.6, border = "left" },
    },
  },
}
```

### `ivy_split`

```lua
{
  preview = "main",
  layout = {
    box = "vertical",
    backdrop = false,
    width = 0,
    height = 0.4,
    position = "bottom",
    border = "top",
    title = " {title} {live} {flags}",
    title_pos = "left",
    { win = "input", height = 1, border = "bottom" },
    {
      box = "horizontal",
      { win = "list", border = "none" },
      { win = "preview", title = "{preview}", width = 0.6, border = "left" },
    },
  },
}
```

### `select`

```lua
{
  preview = false,
  layout = {
    backdrop = false,
    width = 0.5,
    min_width = 80,
    height = 0.4,
    min_height = 10,
    box = "vertical",
    border = "rounded",
    title = "{title}",
    title_pos = "center",
    { win = "input", height = 1, border = "bottom" },
    { win = "list", border = "none" },
    { win = "preview", title = "{preview}", height = 0.4, border = "top" },
  },
}
```

### `sidebar`

```lua
{
  preview = "main",
  layout = {
    backdrop = false,
    width = 40,
    min_width = 40,
    height = 0,
    position = "left",
    border = "none",
    box = "vertical",
    {
      win = "input",
      height = 1,
      border = "rounded",
      title = "{title} {live} {flags}",
      title_pos = "center",
    },
    { win = "list", border = "none" },
    { win = "preview", title = "{preview}", height = 0.4, border = "top" },
  },
}
```

### `telescope`

```lua
{
  reverse = true,
  layout = {
    box = "horizontal",
    backdrop = false,
    width = 0.8,
    height = 0.9,
    border = "none",
    {
      box = "vertical",
      { win = "list", title = " Results ", title_pos = "center", border = "rounded" },
      { win = "input", height = 1, border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
    },
    {
      win = "preview",
      title = "{preview:Preview}",
      width = 0.45,
      border = "rounded",
      title_pos = "center",
    },
  },
}
```

### `vertical`

```lua
{
  layout = {
    backdrop = false,
    width = 0.5,
    min_width = 80,
    height = 0.8,
    min_height = 30,
    box = "vertical",
    border = "rounded",
    title = "{title} {live} {flags}",
    title_pos = "center",
    { win = "input", height = 1, border = "bottom" },
    { win = "list", border = "none" },
    { win = "preview", title = "{preview}", height = 0.4, border = "top" },
  },
}
```

### `vscode`

```lua
{
  preview = false,
  layout = {
    backdrop = false,
    row = 1,
    width = 0.4,
    min_width = 80,
    height = 0.4,
    border = "none",
    box = "vertical",
    { win = "input", height = 1, border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
    { win = "list", border = "hpad" },
    { win = "preview", title = "{preview}", border = "rounded" },
  },
}
```


## 📦 `snacks.picker.actions`

```lua
---@class snacks.picker.actions
---@field [string] snacks.picker.Action.spec
local M = {}
```

### `Snacks.picker.actions.bufdelete()`

```lua
Snacks.picker.actions.bufdelete(picker)
```

### `Snacks.picker.actions.close()`

```lua
Snacks.picker.actions.close(picker)
```

### `Snacks.picker.actions.cmd()`

```lua
Snacks.picker.actions.cmd(picker, item)
```

### `Snacks.picker.actions.cycle_win()`

```lua
Snacks.picker.actions.cycle_win(picker)
```

### `Snacks.picker.actions.focus_input()`

```lua
Snacks.picker.actions.focus_input(picker)
```

### `Snacks.picker.actions.focus_list()`

```lua
Snacks.picker.actions.focus_list(picker)
```

### `Snacks.picker.actions.focus_preview()`

```lua
Snacks.picker.actions.focus_preview(picker)
```

### `Snacks.picker.actions.git_checkout()`

```lua
Snacks.picker.actions.git_checkout(picker, item)
```

### `Snacks.picker.actions.git_stage()`

```lua
Snacks.picker.actions.git_stage(picker)
```

### `Snacks.picker.actions.git_stash_apply()`

```lua
Snacks.picker.actions.git_stash_apply(_, item)
```

### `Snacks.picker.actions.help()`

```lua
Snacks.picker.actions.help(picker, item, action)
```

### `Snacks.picker.actions.history_back()`

```lua
Snacks.picker.actions.history_back(picker)
```

### `Snacks.picker.actions.history_forward()`

```lua
Snacks.picker.actions.history_forward(picker)
```

### `Snacks.picker.actions.inspect()`

```lua
Snacks.picker.actions.inspect(picker, item)
```

### `Snacks.picker.actions.item_action()`

```lua
Snacks.picker.actions.item_action(picker, item, action)
```

### `Snacks.picker.actions.jump()`

```lua
Snacks.picker.actions.jump(picker, _, action)
```

### `Snacks.picker.actions.list_bottom()`

```lua
Snacks.picker.actions.list_bottom(picker)
```

### `Snacks.picker.actions.list_down()`

```lua
Snacks.picker.actions.list_down(picker)
```

### `Snacks.picker.actions.list_scroll_bottom()`

```lua
Snacks.picker.actions.list_scroll_bottom(picker)
```

### `Snacks.picker.actions.list_scroll_center()`

```lua
Snacks.picker.actions.list_scroll_center(picker)
```

### `Snacks.picker.actions.list_scroll_down()`

```lua
Snacks.picker.actions.list_scroll_down(picker)
```

### `Snacks.picker.actions.list_scroll_top()`

```lua
Snacks.picker.actions.list_scroll_top(picker)
```

### `Snacks.picker.actions.list_scroll_up()`

```lua
Snacks.picker.actions.list_scroll_up(picker)
```

### `Snacks.picker.actions.list_top()`

```lua
Snacks.picker.actions.list_top(picker)
```

### `Snacks.picker.actions.list_up()`

```lua
Snacks.picker.actions.list_up(picker)
```

### `Snacks.picker.actions.load_session()`

Tries to load the session, if it fails, it will open the picker.

```lua
Snacks.picker.actions.load_session(picker)
```

### `Snacks.picker.actions.loclist()`

Send selected or all items to the location list.

```lua
Snacks.picker.actions.loclist(picker)
```

### `Snacks.picker.actions.pick_win()`

```lua
Snacks.picker.actions.pick_win(picker, item, action)
```

### `Snacks.picker.actions.preview_scroll_down()`

```lua
Snacks.picker.actions.preview_scroll_down(picker)
```

### `Snacks.picker.actions.preview_scroll_left()`

```lua
Snacks.picker.actions.preview_scroll_left(picker)
```

### `Snacks.picker.actions.preview_scroll_right()`

```lua
Snacks.picker.actions.preview_scroll_right(picker)
```

### `Snacks.picker.actions.preview_scroll_up()`

```lua
Snacks.picker.actions.preview_scroll_up(picker)
```

### `Snacks.picker.actions.put()`

```lua
Snacks.picker.actions.put(picker, item)
```

### `Snacks.picker.actions.qflist()`

Send selected or all items to the quickfix list.

```lua
Snacks.picker.actions.qflist(picker)
```

### `Snacks.picker.actions.qflist_all()`

Send all items to the quickfix list.

```lua
Snacks.picker.actions.qflist_all(picker)
```

### `Snacks.picker.actions.search()`

```lua
Snacks.picker.actions.search(picker, item)
```

### `Snacks.picker.actions.select_all()`

Selects all items in the list.
Or clears the selection if all items are selected.

```lua
Snacks.picker.actions.select_all(picker)
```

### `Snacks.picker.actions.select_and_next()`

Toggles the selection of the current item,
and moves the cursor to the next item.

```lua
Snacks.picker.actions.select_and_next(picker)
```

### `Snacks.picker.actions.select_and_prev()`

Toggles the selection of the current item,
and moves the cursor to the prev item.

```lua
Snacks.picker.actions.select_and_prev(picker)
```

### `Snacks.picker.actions.toggle_focus()`

```lua
Snacks.picker.actions.toggle_focus(picker)
```

### `Snacks.picker.actions.toggle_help_input()`

```lua
Snacks.picker.actions.toggle_help_input(picker)
```

### `Snacks.picker.actions.toggle_help_list()`

```lua
Snacks.picker.actions.toggle_help_list(picker)
```

### `Snacks.picker.actions.toggle_live()`

```lua
Snacks.picker.actions.toggle_live(picker)
```

### `Snacks.picker.actions.toggle_maximize()`

```lua
Snacks.picker.actions.toggle_maximize(picker)
```

### `Snacks.picker.actions.toggle_preview()`

```lua
Snacks.picker.actions.toggle_preview(picker)
```

### `Snacks.picker.actions.yank()`

```lua
Snacks.picker.actions.yank(_, item)
```



## 📦 `snacks.picker.core.picker`

```lua
---@class snacks.Picker
---@field id number
---@field opts snacks.picker.Config
---@field init_opts? snacks.picker.Config
---@field finder snacks.picker.Finder
---@field format snacks.picker.format
---@field input snacks.picker.input
---@field layout snacks.layout
---@field resolved_layout snacks.picker.layout.Config
---@field list snacks.picker.list
---@field matcher snacks.picker.Matcher
---@field main number
---@field _main snacks.picker.Main
---@field preview snacks.picker.Preview
---@field shown? boolean
---@field sort snacks.picker.sort
---@field updater uv.uv_timer_t
---@field start_time number
---@field title string
---@field closed? boolean
---@field history snacks.picker.History
---@field visual? snacks.picker.Visual
local M = {}
```

### `Snacks.picker.picker.get()`

```lua
---@param opts? {source?: string}
Snacks.picker.picker.get(opts)
```

### `picker:action()`

Execute the given action(s)

```lua
---@param actions string|string[]
picker:action(actions)
```

### `picker:close()`

Close the picker

```lua
picker:close()
```

### `picker:count()`

Total number of items in the picker

```lua
picker:count()
```

### `picker:current()`

Get the current item at the cursor

```lua
---@param opts? {resolve?: boolean} default is `true`
picker:current(opts)
```

### `picker:cwd()`

```lua
picker:cwd()
```

### `picker:empty()`

Check if the picker is empty

```lua
picker:empty()
```

### `picker:filter()`

Get the active filter

```lua
picker:filter()
```

### `picker:find()`

Check if the finder and/or matcher need to run,
based on the current pattern and search string.

```lua
---@param opts? { on_done?: fun(), refresh?: boolean }
picker:find(opts)
```

### `picker:hist()`

Move the history cursor

```lua
---@param forward? boolean
picker:hist(forward)
```

### `picker:is_active()`

Check if the finder or matcher is running

```lua
picker:is_active()
```

### `picker:is_focused()`

```lua
picker:is_focused()
```

### `picker:items()`

Get all filtered items in the picker.

```lua
picker:items()
```

### `picker:iter()`

Returns an iterator over the filtered items in the picker.
Items will be in sorted order.

```lua
---@return fun():(snacks.picker.Item?, number?)
picker:iter()
```

### `picker:norm()`

Execute the callback in normal mode.
When still in insert mode, stop insert mode first,
and then`vim.schedule` the callback.

```lua
---@param cb fun()
picker:norm(cb)
```

### `picker:on_current_tab()`

```lua
picker:on_current_tab()
```

### `picker:ref()`

```lua
---@return snacks.Picker.ref
picker:ref()
```

### `picker:resolve()`

```lua
---@param item snacks.picker.Item?
picker:resolve(item)
```

### `picker:selected()`

Get the selected items.
If `fallback=true` and there is no selection, return the current item.

```lua
---@param opts? {fallback?: boolean} default is `false`
---@return snacks.picker.Item[]
picker:selected(opts)
```

### `picker:set_cwd()`

```lua
picker:set_cwd(cwd)
```

### `picker:set_layout()`

Set the picker layout. Can be either the name of a preset layout
or a custom layout configuration.

```lua
---@param layout? string|snacks.picker.layout.Config
picker:set_layout(layout)
```

### `picker:show_preview()`

Show the preview. Show instantly when no item is yet in the preview,
otherwise throttle the preview.

```lua
picker:show_preview()
```

### `picker:toggle_preview()`

```lua
---@param enable? boolean
picker:toggle_preview(enable)
```

### `picker:word()`

Get the word under the cursor or the current visual selection

```lua
picker:word()
```

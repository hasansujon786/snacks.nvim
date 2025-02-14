# 🍿 image

![Image](https://github.com/user-attachments/assets/4e8a686c-bf41-4989-9d74-1641ecf2835f)

Image viewer using the [Kitty Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/).

Supported terminals:

- [kitty](https://sw.kovidgoyal.net/kitty/)
- [wezterm](https://wezfurlong.org/wezterm/)
- [ghostty](https://ghostty.org/)

In order to automatically display the image when openinng an image file,
you need to enable the `image` plugin in your `snacks` config.

Supported image formats:

- PNG
- JPEG/JPG
- GIF
- BMP
- WEBP

[ImageMagick](https://imagemagick.org/index.php) is required to convert images
to the supported formats (all except PNG).

<!-- docgen -->

## 📦 Setup

```lua
-- lazy.nvim
{
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    image = {
      -- your image configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  }
}
```

## ⚙️ Config

```lua
---@class snacks.image.Config
---@field wo? vim.wo|{} options for windows showing the image
---@field bo? vim.bo|{} options for the image buffer
---@field formats? string[]
--- Resolves a reference to an image with src in a file (currently markdown only).
--- Return the absolute path or url to the image.
--- When `nil`, the path is resolved relative to the file.
---@field resolve? fun(file: string, src: string): string?
{
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
}
```

## 📚 Types

```lua
---@alias snacks.image.Size {width: number, height: number}
---@alias snacks.image.Pos {[1]: number, [2]: number}
---@alias snacks.image.Loc snacks.image.Pos|snacks.image.Size|{zindex?: number}
```

```lua
---@class snacks.image.Env
---@field name string
---@field env table<string, string|true>
---@field supported? boolean default: false
---@field placeholders? boolean default: false
---@field setup? fun(): boolean?
---@field transform? fun(data: string): string
---@field detected? boolean
```

```lua
---@class snacks.image.Opts
---@field pos? snacks.image.Pos (row, col) (1,0)-indexed. defaults to the top-left corner
---@field width? number
---@field min_width? number
---@field max_width? number
---@field height? number
---@field min_height? number
---@field max_height? number
```

## 📦 Module

```lua
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
Snacks.image = {}
```

### `Snacks.image.attach()`

```lua
---@param buf number
---@param opts? snacks.image.Opts|{src?: string}
Snacks.image.attach(buf, opts)
```

### `Snacks.image.dim()`

Get the dimensions of a PNG file

```lua
---@param file string
---@return number width, number height
Snacks.image.dim(file)
```

### `Snacks.image.env()`

```lua
Snacks.image.env()
```

### `Snacks.image.markdown()`

```lua
---@param buf? number
Snacks.image.markdown(buf)
```

### `Snacks.image.new()`

```lua
---@param buf number
---@param opts? snacks.image.Opts
Snacks.image.new(buf, src, opts)
```

### `Snacks.image.request()`

```lua
---@param opts table<string, string|number>|{data?: string}
Snacks.image.request(opts)
```

### `Snacks.image.supports()`

Check if the file format is supported and the terminal supports the kitty graphics protocol

```lua
---@param file string
Snacks.image.supports(file)
```

### `Snacks.image.supports_file()`

Check if the file format is supported

```lua
---@param file string
Snacks.image.supports_file(file)
```

### `Snacks.image.supports_terminal()`

Check if the terminal supports the kitty graphics protocol

```lua
Snacks.image.supports_terminal()
```

### `image:close()`

```lua
image:close()
```

### `image:convert()`

```lua
---@param file string
image:convert(file)
```

### `image:create()`

create the image

```lua
image:create()
```

### `image:debug()`

```lua
image:debug(...)
```

### `image:hide()`

```lua
image:hide()
```

### `image:ready()`

```lua
image:ready()
```

### `image:render_fallback()`

```lua
---@param state snacks.image.State
image:render_fallback(state)
```

### `image:render_grid()`

Renders the unicode placeholder grid in the buffer

```lua
---@param loc snacks.image.Loc
image:render_grid(loc)
```

### `image:set_cursor()`

```lua
---@param pos {[1]: number, [2]: number}
image:set_cursor(pos)
```

### `image:state()`

```lua
image:state()
```

### `image:update()`

```lua
image:update()
```

### `image:wins()`

```lua
---@return number[]
image:wins()
```

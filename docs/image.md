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
---@field file? string
---@field wo? vim.wo|{} options for windows showing the image
{
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
```

## 📚 Types

```lua
---@alias snacks.image.Dim {col: number, row: number, width: number, height: number}
```

## 📦 Module

```lua
---@class snacks.image
---@field id number
---@field buf number
---@field opts snacks.image.Config
---@field file string
---@field augroup number
---@field _convert uv.uv_process_t?
Snacks.image = {}
```

### `Snacks.image.dim()`

Get the dimensions of a PNG file

```lua
---@param file string
---@return number width, number height
Snacks.image.dim(file)
```

### `Snacks.image.new()`

```lua
---@param buf number
---@param opts? snacks.image.Config
Snacks.image.new(buf, opts)
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

```lua
image:create()
```

### `image:grid_size()`

```lua
image:grid_size()
```

### `image:hide()`

```lua
image:hide()
```

### `image:ready()`

```lua
image:ready()
```

### `image:render()`

Renders the unicode placeholder grid in the buffer

```lua
---@param width number
---@param height number
image:render(width, height)
```

### `image:request()`

```lua
---@param opts table<string, string|number>|{data?: string}
image:request(opts)
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

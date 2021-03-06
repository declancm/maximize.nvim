# maximize.nvim

Maximize neovim windows.

## â¨ Features

* Use `<leader>z` to toggle maximizing the current neovim window without any of
  the ugly borders that other maximizing plugins create.
* Works with plugins such as 'nvim-scrollview', which have floating windows
  (unlike other maximizing plugins).

## đĻ Installation

Install with your favourite plugin manager and run the setup function.

### Packer

```lua
use {
  'declancm/maximize.nvim',
  config = function() require('maximize').setup() end
}
```

## âī¸ Configuration

A settings table can be passed into the setup function for custom options.

### Default Settings

```lua
default_keymaps = true -- Enable default keymaps.
```

## â¨ī¸  Keymaps


### Default Keymaps

```lua
vim.keymap.set('n', '<Leader>z', "<Cmd>lua require('maximize').toggle()<CR>")
```

## đĨ statusline & winbar

Use the tabpage-scoped variable `vim.t.maximized` to check whether the current window
is maximized or not.

### Lualine

```lua
local function maximize_status()
  return vim.t.maximized and ' ī  ' or ''
end

require('lualine').setup {
  sections = {
    lualine_c = { maximize_status }
  }
}
```

### winbar

```lua
-- ~/.config/nvim/lua/winbar.lua
local M = {}

M.maximize_status = function()
  return vim.t.maximized and ' ī  ' or ''
end

return M

-- ~/.config/nvim/init.lua
vim.o.winbar = "%{%v:lua.require('winbar').maximize_status()%}"
```

## âšī¸ API

* Toggle maximizing the current window:

  `require('maximize').toggle()`

* Maximize the current window:

  `require('maximize').maximize()`

* Restore windows:

  `require('maximize').restore()`

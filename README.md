# maximize.nvim

Maximize neovim windows.

## ✨ Features

* Use `<leader>z` to toggle maximizing the current neovim window without any of
  the ugly borders that other maximizing plugins create.
* Works with plugins such as 'nvim-scrollview', which have floating windows
  (unlike other maximizing plugins).

## 🛠️ Requirements

* Neovim >= 0.8.0 (use a tagged version for older Neovim versions)

## 📦 Installation

Install with your favourite plugin manager and run the setup function.

### Packer

```lua
use {
  'declancm/maximize.nvim',
  config = function() require('maximize').setup() end
}
```

## ⚙️  Configuration

A settings table can be passed into the setup function for custom options.

### Default Options

```lua
{
  default_keymaps = true,
  plugins = {
    aerial = { enable = true }, -- enable aerial.nvim integration
    dapui = { enable = true },  -- enable nvim-dap-ui integration
    tree = { enable = true },   -- enable nvim-tree.lua integration
  }
}
```

## ⌨️  Keymaps


### Default Keymaps

```lua
vim.keymap.set('n', '<Leader>z', require('maximize').toggle)
```

## 🤝 Integrations

Integration exists for the following plugins:

* aerial.nvim
* nvim-dap-ui
* nvim-tree.lua

## 📅 User Events

The following user events are triggered for easier plugin integration:

* **WindowMaximizeStart**: before maximizing
* **WindowRestoreEnd**: after restoring

## 🚥 statusline & winbar

Use the tabpage-scoped variable `vim.t.maximized` to check whether the current window
is maximized or not.

### Lualine

```lua
local function maximize_status()
  return vim.t.maximized and '   ' or ''
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
  return vim.t.maximized and '   ' or ''
end

return M

-- ~/.config/nvim/init.lua
vim.o.winbar = "%{%v:lua.require('winbar').maximize_status()%}"
```

## ℹ️ API

* Toggle maximizing the current window:

  `require('maximize').toggle()`

* Maximize the current window:

  `require('maximize').maximize()`

* Restore windows:

  `require('maximize').restore()`

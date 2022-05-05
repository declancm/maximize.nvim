# maximize.nvim

Maximize neovim windows.

## ✨ Features

* Use `<leader>z` to toggle maximizing the current neovim window without any of
  the ugly borders that other maximizing plugins create.
* Works with plugins such as 'nvim-scrollview', which have floating windows
  (unlike other maximizing plugins).

## 📦 Installation

Install with your favourite plugin manager and run the setup function.

### Packer

```lua
use {
  'declancm/maximize.nvim',
  config = function() require('maximize').setup() end
}
```

## ⚙️ Configuration

A settings table can be passed into the setup function for custom options.

### Default Settings

```lua
default_keymaps = true -- Enable default keymaps.
```

## ⌨️  Keymaps


### Default Keymaps

```lua
vim.keymap.set('n', '<Leader>z', "<Cmd>lua require('maximize').toggle()<CR>")
```

## ℹ️ API

* Toggle maximizing the current window:

  `require('maximize').toggle()`

* Maximize the current window:

  `require('maximize').maximize()`

* Restore windows:

  `require('maximize').restore()`

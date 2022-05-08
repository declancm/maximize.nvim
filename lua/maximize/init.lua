local M = {}

M.setup = function(user_config)
  -- Check if user is on Windows.
  if vim.fn.has('win32') == 1 then
    require('maximize.utils').error_msg('A unix system is required for maximize. Have you tried using WSL?')
    return
  end

  local utils = require('maximize.utils')
  local config = require('maximize.config')

  -- Setting the config options.
  if user_config ~= nil then
    utils.merge(config, user_config)
  end

  -- AUTOCMDS:

  if vim.fn.has('nvim-0.7.0') == 1 then
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup

    -- Delete session file from cache.
    autocmd({ 'VimEnter', 'VimLeave' }, {
      command = "call delete(getenv('HOME') . '/.cache/nvim/.maximize_session.vim')",
      group = augroup('clear_maximize_cache', {}),
    })
  else
    -- Delete session file from cache.
    vim.cmd([[
    aug clear_maximize_cache
    au!
    au VimEnter * call delete(getenv('HOME') . '/.cache/nvim/.maximize_session.vim')
    au VimLeave * call delete(getenv('HOME') . '/.cache/nvim/.maximize_session.vim')
    aug END
    ]])
  end

  -- KEYMAPS:

  if config.default_keymaps then
    local keymap = vim.api.nvim_set_keymap
    local opts = { noremap = true }

    keymap('n', '<Leader>z', "<Cmd>lua require('maximize').toggle()<CR>", opts)
  end
end

-- API:

-- Maximize:
M.toggle = function()
  return require('maximize.maximize').toggle()
end
M.maximize = function()
  return require('maximize.maximize').maximize()
end
M.restore = function()
  return require('maximize.maximize').restore()
end

return M

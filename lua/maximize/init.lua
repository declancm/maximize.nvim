local M = {}

M.setup = function(user_config)
  -- Check if user is on Windows.
  if vim.fn.has('win32') == 1 then
    require('maximize.utils').error_msg('A unix system is required for maximize. Have you tried using WSL?')
    return
  end

  -- Check if the user has Neovim v0.8.0.
  if vim.fn.has('nvim-0.8.0') == 0 then
    require('maximize.utils').error_msg('Neovim >= 0.8.0 is required. Use an older version tag for older Neovim versions.')
    return
  end

  local utils = require('maximize.utils')
  local config = require('maximize.config')

  -- Setting the config options.
  if user_config ~= nil then
    utils.merge(config, user_config)
  end

  -- AUTOCMDS:
  -- Clean cache upon exiting vim (delete the temporary session file for each
  -- tabpage)

  if vim.fn.has('nvim-0.7.0') == 1 then
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup
    autocmd({ 'VimLeave' }, {
      callback = require('maximize.utils').delete_session_files,
      group = augroup('clear_maximize_cache', {}),
    })
  else
    vim.cmd([[
    aug clear_maximize_cache
    au!
    au VimLeave * lua require('maximize.utils').delete_session_files()
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

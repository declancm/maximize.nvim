local M = {}

local utils = require('maximize.utils')

M.toggle = function()
  if vim.t.maximized then
    M.restore()
  else
    M.maximize()
  end
end

M.maximize = function()
  -- Return if only one window exists.
  if vim.fn.winnr('$') == 1 then
    return
  end

  -- A temporary file for storing the current session. It's unique and per tab.
  vim.t.tmp_session_file = '~/.cache/nvim/.maximize_session-' .. os.time() .. '.vim'

  -- Save options.
  vim.t.saved_cmdheight = vim.opt_local.cmdheight:get()
  vim.t.saved_cmdwinheight = vim.opt_local.cmdwinheight:get()

  -- https://github.com/Shatur/neovim-session-manager/blob/9652b392805dfd497877342e54c5a71be7907daf/lua/session_manager/utils.lua#L74-L79
  -- Remove all non-file and utility buffers because they cannot be saved
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) and not utils.is_restorable(buffer) then
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
  end

  -- Save the session.
  -- NOTE: Options aren't saving since we aren't closing Neovim.
  local saved_sessionoptions = vim.opt_local.sessionoptions:get()
  vim.opt_local.sessionoptions = {
    'blank',
    'buffers',
    'curdir',
    'folds',
    'help',
    'resize',
    'tabpages',
    'terminal',
    'winpos',
    'winsize',
  }
  vim.cmd('mksession! ' .. vim.t.tmp_session_file)
  vim.opt_local.sessionoptions = saved_sessionoptions

  -- Maximize the window.
  vim.cmd('only')

  vim.t.maximized = true
end

M.restore = function()
  -- Restore windows.
  if vim.fn.filereadable(vim.fn.expand(vim.t.tmp_session_file)) == 1 then
    vim.cmd('silent wall')
    local file_name = vim.fn.expand('%:p')
    local saved_position = vim.fn.getcurpos()

    -- Source the saved session.
    vim.cmd('silent source ' .. vim.t.tmp_session_file)

    -- Delete the saved session.
    vim.fn.delete(vim.fn.expand(vim.t.tmp_session_file))

    if vim.fn.expand('%:p') ~= file_name then
      vim.cmd('edit ' .. file_name)
    end
    vim.fn.setpos('.', saved_position)

    -- Restore saved options.
    vim.opt_local.cmdheight = vim.t.saved_cmdheight
    vim.opt_local.cmdwinheight = vim.t.saved_cmdwinheight
  end

  vim.t.maximized = false
end

return M

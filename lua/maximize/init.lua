local M = {}

local integrations = require('maximize.integrations')
local utils = require('maximize.utils')

M.setup = function(user_config)
  -- Check if the user has Neovim v0.8.0.
  if vim.fn.has('nvim-0.8.0') == 0 then
    require('maximize.utils').error_msg(
    'Neovim >= 0.8.0 is required for maximize. Use an older version tag for older Neovim versions.')
    return
  end

  local config = require('maximize.config')

  -- Setting the config options.
  config = vim.tbl_deep_extend('force', {}, config, user_config or {})

  -- Set keymaps.
  if config.default_keymaps then
    vim.keymap.set('n', '<Leader>z', require('maximize').toggle)
  end
end

M.toggle = function()
  if vim.t.maximized then
    M.restore()
  else
    M.maximize()
  end
end

M.maximize = function()
  vim.t.maximized = true

  -- Return if only one window exists.
  if vim.fn.winnr('$') == 1 then
    return
  end

  vim.api.nvim_exec_autocmds('User', { pattern = 'WindowMaximizeStart' })

  -- Clear the plugin windows.
  integrations.clear()

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

  -- Save the existing session options and then set them.
  -- NOTE: Options aren't saved since we aren't closing Neovim.
  local saved_sessionoptions = vim.opt_local.sessionoptions:get()
  vim.opt_local.sessionoptions = {
    'blank',
    'buffers',
    'help',
    'resize',
    'terminal',
    'winsize',
  }

  -- Write the session to a temporary file.
  local tmp_file_name = os.tmpname()
  vim.cmd('mksession! ' .. tmp_file_name)

  -- Read the session to a tabpage-scoped variable and delete the temporary file.
  local tmp_file = assert(io.open(tmp_file_name, 'rb'))
  vim.t.saved_session = tmp_file:read('*all')
  tmp_file:close()
  os.remove(tmp_file_name)

  -- Restore the saved session options.
  vim.opt_local.sessionoptions = saved_sessionoptions

  -- Maximize the window.
  vim.cmd('only')
end

M.restore = function()
  vim.t.maximized = false

  -- Restore windows.
  if vim.t.saved_session then
    vim.cmd('silent wall')
    local file_name = vim.fn.expand('%:p')
    local saved_position = vim.fn.getcurpos()

    -- Source the saved session.
    vim.api.nvim_exec(vim.t.saved_session, false)
    vim.t.saved_session = nil

    if vim.fn.expand('%:p') ~= file_name then
      vim.cmd('edit ' .. file_name)
    end
    vim.fn.setpos('.', saved_position)

    -- Restore saved options.
    vim.opt_local.cmdheight = vim.t.saved_cmdheight
    vim.opt_local.cmdwinheight = vim.t.saved_cmdwinheight

    -- Restore plugin windows.
    integrations.restore()

    vim.api.nvim_exec_autocmds('User', { pattern = 'WindowRestoreEnd' })
  end
end

return M

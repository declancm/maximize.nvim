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

  if vim.fn.winnr('$') > 1 then
    vim.t._maximize_saved_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    -- Clear the plugin windows.
    vim.api.nvim_exec_autocmds('User', { pattern = 'WindowMaximizeStart' })
    integrations.clear()

    -- Remove all non-file and utility buffers because they cannot be saved.
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buffer) and not utils.is_restorable(buffer) then
        vim.api.nvim_buf_delete(buffer, { force = true })
      end
    end

    -- Save the existing session options and then set them.
    local saved_sessionoptions = vim.opt_local.sessionoptions:get()
    vim.opt_local.sessionoptions = {
      'blank',
      'buffers',
      'help',
      'resize',
      'terminal',
      'winsize',
    }

    -- Write the session to a temporary file and save it.
    local tmp_file_name = os.tmpname()
    vim.cmd('mksession! ' .. tmp_file_name)
    local tmp_file = assert(io.open(tmp_file_name, 'rb'))
    vim.t._maximize_saved_session = tmp_file:read('*all')
    tmp_file:close()
    os.remove(tmp_file_name)

    -- Restore the saved session options.
    vim.opt_local.sessionoptions = saved_sessionoptions

    -- Maximize the window.
    vim.cmd.only()

    vim.o.lazyredraw = vim.t._maximize_saved_lazyredraw
  end
end

M.restore = function()
  vim.t.maximized = false

  if vim.t._maximize_saved_session then
    vim.t._maximize_saved_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    -- Save the current buffer and cursor position.
    local buffer = vim.api.nvim_get_current_buf()
    local cursor_position = vim.fn.getcurpos()

    -- The current buffer when sourcing a session can't be
    -- modified so create and open a temporary unlisted buffer.
    vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))

    -- Source the saved session.
    vim.api.nvim_exec2(vim.t._maximize_saved_session, {})
    vim.t._maximize_saved_session = nil

    -- Return to previous buffer and cursor position.
    vim.api.nvim_win_set_buf(0, buffer)
    vim.fn.setpos('.', cursor_position)

    -- Restore plugin windows.
    integrations.restore()
    vim.api.nvim_exec_autocmds('User', { pattern = 'WindowRestoreEnd' })

    vim.o.lazyredraw = vim.t._maximize_saved_lazyredraw
  end
end

return M

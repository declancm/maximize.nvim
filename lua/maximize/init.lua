local M = {}

local config = require('maximize.config')
local integrations = require('maximize.integrations')
local utils = require('maximize.utils')

M.setup = function(user_config)
  -- Check if the user has Neovim v0.8.0.
  if vim.fn.has('nvim-0.8.0') == 0 then
    vim.notify('[maximize] Neovim >= 0.8.0 is required. Please use an older version tag for older Neovim versions', vim.log.levels.WARN)
    return
  end

  config.setup(user_config)

  vim.api.nvim_create_user_command('Maximize', M.toggle, { desc = 'Toggle maximizing the current window' })

  -- Enable plugin integrations.
  integrations.plugins = {}
  for name, options in pairs(config.options.plugins) do
    if options.enable then
      table.insert(integrations.plugins, require('maximize.integrations.' .. name))
    end
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
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.t.maximized = true

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

    -- Prevent session managers from trying to autosave our temporary session
    vim.t._maximize_old_session = vim.v.this_session

    -- Write the session to a temporary file and save it.
    local tmp_file_name = os.tmpname()
    vim.cmd.mksession({ tmp_file_name, bang = true })
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
    local cursor = vim.api.nvim_win_get_cursor(0)

    -- The current buffer when sourcing a session can't be
    -- modified so create and open a temporary unlisted buffer.
    vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))

    -- Source the saved session.
    vim.api.nvim_exec2(vim.t._maximize_saved_session, {})
    vim.t._maximize_saved_session = nil

    -- Prevent session managers from trying to autosave our temporary session
    vim.v.this_session = vim.t._maximize_old_session
    vim.t._maximize_old_session = nil

    -- Return to previous buffer and cursor position.
    vim.api.nvim_win_set_buf(0, buffer)
    vim.api.nvim_win_set_cursor(0, cursor)

    -- Restore plugin windows.
    integrations.restore()
    vim.api.nvim_exec_autocmds('User', { pattern = 'WindowRestoreEnd' })

    vim.o.lazyredraw = vim.t._maximize_saved_lazyredraw
  end
end

return M

local M = {}

local config = require('maximize.config')
local integrations = require('maximize.integrations')
local utils = require('maximize.utils')

local tabscoped = {}

M.setup = function(user_config)
  config.setup(user_config)

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

    local tab = vim.api.nvim_get_current_tabpage()
    tabscoped[tab] = {}
    tabscoped[tab].save_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    vim.api.nvim_exec_autocmds('User', { pattern = 'WindowMaximizeStart' })
    integrations.clear()

    -- Remove all non-file and utility buffers because they cannot be saved.
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buffer) and not utils.is_restorable(buffer) then
        vim.api.nvim_buf_delete(buffer, { force = true })
      end
    end

    -- Prevent session managers from trying to autosave our temporary session
    tabscoped[tab].save_session = vim.v.this_session

    local save_sessionoptions = vim.o.sessionoptions
    vim.o.sessionoptions = 'help,terminal,winsize'

    -- Write the session to a temporary file and save it.
    local tmp_file_name = os.tmpname()
    vim.cmd.mksession({ tmp_file_name, bang = true })
    local tmp_file = assert(io.open(tmp_file_name, 'rb'))
    tabscoped[tab].restore_script = tmp_file:read('*all')
    tmp_file:close()
    os.remove(tmp_file_name)

    vim.o.sessionoptions = save_sessionoptions

    -- Maximize the window.
    vim.cmd.only({ bang = true })

    vim.o.lazyredraw = tabscoped[tab].save_lazyredraw
  end
end

M.restore = function()
  vim.t.maximized = false

  local tab = vim.api.nvim_get_current_tabpage()
  if tabscoped[tab].restore_script then
    tabscoped[tab].save_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    local save_buffer = vim.api.nvim_get_current_buf()
    local save_cursor = vim.api.nvim_win_get_cursor(0)

    -- The current buffer when sourcing a session can't be
    -- modified so create and open a temporary unlisted buffer.
    local save_bufhidden = vim.bo.bufhidden
    vim.bo.bufhidden = 'hide'
    vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))
    _ = vim.api.nvim_exec2(tabscoped[tab].restore_script, { output = true })
    vim.bo.bufhidden = save_bufhidden

    -- Prevent session managers from trying to autosave our temporary session
    vim.v.this_session = tabscoped[tab].save_session

    vim.api.nvim_win_set_buf(0, save_buffer)
    vim.api.nvim_win_set_cursor(0, save_cursor)

    integrations.restore()
    vim.api.nvim_exec_autocmds('User', { pattern = 'WindowRestoreEnd' })

    vim.o.lazyredraw = tabscoped[tab].save_lazyredraw
    tabscoped[tab] = {}
  end
end

return M

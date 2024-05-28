local M = {}

local config = require('maximize.config')
local integrations = require('maximize.integrations')

local tabscoped = {}

M.setup = function(user_config)
  config.setup(user_config)

  integrations.plugins = {}
  for name, options in pairs(config.options.plugins) do
    if options.enable then
      table.insert(integrations.plugins, require('maximize.integrations.' .. name))
    end
  end

  local group = vim.api.nvim_create_augroup('Maximize', {})
  vim.api.nvim_create_autocmd('WinEnter', {
    group = group,
    callback = function()
      if vim.api.nvim_win_get_config(0).relative == '' then
        local tab = vim.api.nvim_get_current_tabpage()
        if not tabscoped[tab] then
          tabscoped[tab] = {}
        end
        tabscoped[tab].prev_norm_win = vim.api.nvim_get_current_win()
      end
    end,
    desc = 'Keep track of the last non-floating window'
  })
end

M.toggle = function()
  if vim.t.maximized then
    M.restore()
  else
    M.maximize()
  end
end

local leave_floating_window = function()
  local tab = vim.api.nvim_get_current_tabpage()
  if vim.api.nvim_win_get_config(0).relative ~= '' then
    if tabscoped[tab] and tabscoped[tab].prev_norm_win then
      vim.api.nvim_set_current_win(tabscoped[tab].prev_norm_win)
    else
      while vim.api.nvim_win_get_config(0).relative ~= '' do
        vim.cmd.wincmd('w')
      end
    end
  end
end

local close_floating_windows = function()
  for _, window_handle in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(window_handle).relative ~= '' then
      vim.api.nvim_win_close(window_handle, true)
    end
  end
end

M.maximize = function()
  local normal_window_count = 0
  for _, window_handle in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(window_handle).relative == '' then
      normal_window_count = normal_window_count + 1
    end
  end

  if normal_window_count > 1 then
    vim.t.maximized = true

    local tab = vim.api.nvim_get_current_tabpage()
    tabscoped[tab] = {}

    local save_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    vim.api.nvim_exec_autocmds('User', { pattern = 'WindowMaximizeStart' })
    integrations.clear()

    leave_floating_window()
    close_floating_windows()

    -- Save the buffer handles, cursor positions and window local variables
    -- for all windows. Open a temporary scratch buffer in each window.
    tabscoped[tab].windows = {}
    local current_window_handle = vim.api.nvim_get_current_win()
    local windows = vim.api.nvim_tabpage_list_wins(0)
    for i = 1, #windows do
      local window = {}
      window.handle = windows[i]
      window.save_cursor = vim.api.nvim_win_get_cursor(window.handle)
      window.save_quickfix_title = vim.w[window.handle].quickfix_title
      window.buffer = {}
      window.buffer.handle = vim.api.nvim_win_get_buf(window.handle)
      window.buffer.save_bufhidden = vim.bo[window.buffer.handle].bufhidden
      window.buffer.save_buftype = vim.bo[window.buffer.handle].buftype
      if window.handle ~= current_window_handle then
        vim.bo[window.buffer.handle].bufhidden = 'hide'
        -- Buffer types without associated files aren't restored properly so
        -- set them to 'nowrite'. Normal buffers can't be closed when modified
        -- which causes issues when quiting Neovim when maximized.
        if vim.tbl_contains({ 'quickfix', 'nofile', 'prompt' }, vim.bo[window.buffer.handle].buftype) then
          vim.bo[window.buffer.handle].buftype = 'nowrite'
        end
        vim.api.nvim_win_set_buf(window.handle, vim.api.nvim_create_buf(false, true))
      end
      table.insert(tabscoped[tab].windows, window)
    end

    -- Prevent session managers from trying to autosave our temporary session
    tabscoped[tab].save_session = vim.v.this_session

    local save_sessionoptions = vim.o.sessionoptions
    vim.o.sessionoptions = 'blank,help,terminal,winsize'

    -- Write the session to a temporary file and save it.
    local tmp_file_name = os.tmpname()
    vim.cmd.mksession({ tmp_file_name, bang = true })
    local tmp_file = assert(io.open(tmp_file_name, 'rb'))
    tabscoped[tab].restore_script = tmp_file:read('*all')
    tmp_file:close()
    os.remove(tmp_file_name)

    vim.o.sessionoptions = save_sessionoptions

    -- Maximize the window.
    for _, window in ipairs(tabscoped[tab].windows) do
      if window.handle ~= current_window_handle then
        vim.api.nvim_win_close(window.handle, true)
      end
    end

    vim.o.lazyredraw = save_lazyredraw
  else
    vim.notify('Already one window', vim.log.levels.WARN)
  end
end

M.restore = function()
  vim.t.maximized = false

  local tab = vim.api.nvim_get_current_tabpage()
  if tabscoped[tab] and tabscoped[tab].restore_script then
    local save_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    leave_floating_window()
    close_floating_windows()

    local save_buffer = vim.api.nvim_get_current_buf()
    local save_cursor = vim.api.nvim_win_get_cursor(0)
    local save_bufhidden = vim.bo.bufhidden
    vim.bo.bufhidden = 'hide'

    local save_eventignore = vim.o.eventignore
    vim.opt.eventignore:append('SessionLoadPost')

    -- The current buffer when sourcing a session can't be
    -- modified so create and open a temporary unlisted buffer.
    vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))
    _ = vim.api.nvim_exec2(tabscoped[tab].restore_script, { output = true })

    -- Prevent session managers from trying to autosave our temporary session
    vim.v.this_session = tabscoped[tab].save_session
    vim.o.eventignore = save_eventignore

    vim.api.nvim_win_set_buf(0, save_buffer)
    vim.api.nvim_win_set_cursor(0, save_cursor)
    vim.bo.bufhidden = save_bufhidden

    -- Restore the buffer handles and cursor positions for all windows.
    local current_window_handle = vim.api.nvim_get_current_win()
    local windows = vim.api.nvim_tabpage_list_wins(0)
    for i = 1, #windows do
      local window = tabscoped[tab].windows[i]
      local window_handle = windows[i]
      if window_handle ~= current_window_handle then
        vim.api.nvim_win_set_buf(window_handle, window.buffer.handle)
        vim.api.nvim_win_set_cursor(window_handle, window.save_cursor)
        vim.bo[window.buffer.handle].bufhidden = window.buffer.save_bufhidden
        vim.w[window_handle].quickfix_title = window.save_quickfix_title
      end
    end

    integrations.restore()
    vim.api.nvim_exec_autocmds('User', { pattern = 'WindowRestoreEnd' })

    vim.o.lazyredraw = save_lazyredraw

    tabscoped[tab] = {}
  end
end

return M

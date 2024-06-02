local M = {}

local tabscoped = {}

local is_floating_window = function(window_handle)
  return vim.api.nvim_win_get_config(window_handle).relative ~= ''
end

M.get_normal_window_count = function()
  local count = 0
  for _, window_handle in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_floating_window(window_handle) then
      count = count + 1
    end
  end
  return count
end

M.track_last_opened_normal_window = function()
  if not is_floating_window(0) then
    local tab = vim.api.nvim_get_current_tabpage()
    tabscoped[tab] = tabscoped[tab] or {}
    tabscoped[tab].last_norm_win = vim.api.nvim_get_current_win()
  end
end

M.leave_floating_window = function()
  local tab = vim.api.nvim_get_current_tabpage()
  tabscoped[tab] = tabscoped[tab] or {}

  if is_floating_window(0) then
    if tabscoped[tab] and tabscoped[tab].last_norm_win then
      vim.api.nvim_set_current_win(tabscoped[tab].last_norm_win)
    else
      while is_floating_window(0) do
        vim.cmd.wincmd('w')
      end
    end
  end
end

M.close_floating_windows = function()
  for _, window_handle in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_floating_window(window_handle) then
      vim.api.nvim_win_close(window_handle, true)
    end
  end
end

M.maximize_normal_window = function()
  local tab = vim.api.nvim_get_current_tabpage()
  tabscoped[tab] = tabscoped[tab] or {}

  -- Save the buffer handles, cursor positions and window local variables
  -- for all windows. Open a temporary scratch buffer in each window.
  tabscoped[tab].windows = {}
  local current_window_handle = vim.api.nvim_get_current_win()
  local windows = vim.api.nvim_tabpage_list_wins(0)
  for i = 1, #windows do
    local window = {}
    window.handle = windows[i]
    window.save_cursor = vim.api.nvim_win_get_cursor(window.handle)
    window.save_current_syntax = vim.w[window.handle].current_syntax
    window.save_quickfix_title = vim.w[window.handle].quickfix_title
    window.buffer = {}
    window.buffer.handle = vim.api.nvim_win_get_buf(window.handle)
    window.buffer.save_bufhidden = vim.bo[window.buffer.handle].bufhidden
    window.buffer.save_buftype = vim.bo[window.buffer.handle].buftype
    if window.handle ~= current_window_handle then
      vim.bo[window.buffer.handle].bufhidden = 'hide'
      -- Buffer types without associated files aren't restored properly.
      if vim.list_contains({ 'quickfix', 'nofile', 'prompt' }, vim.bo[window.buffer.handle].buftype) then
        vim.bo[window.buffer.handle].buftype = 'nowrite'
      end
      vim.api.nvim_win_set_buf(window.handle, vim.api.nvim_create_buf(false, true))
    end
    table.insert(tabscoped[tab].windows, window)
  end

  local save_view = vim.fn.winsaveview()
  local save_buffer = vim.api.nvim_get_current_buf()
  local save_bufhidden = vim.bo.bufhidden
  vim.bo.bufhidden = 'hide'
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))

  -- Write the session to a temporary file and save it.
  local tmp_file_name = os.tmpname()
  local save_this_session = vim.v.this_session
  local save_sessionoptions = vim.o.sessionoptions
  vim.o.sessionoptions = 'blank,help,terminal,winsize'
  vim.cmd.mksession({ tmp_file_name, bang = true })
  vim.o.sessionoptions = save_sessionoptions
  vim.v.this_session = save_this_session
  local tmp_file = assert(io.open(tmp_file_name, 'rb'))
  tabscoped[tab].restore_script = tmp_file:read('*all')
  tmp_file:close()
  os.remove(tmp_file_name)

  vim.api.nvim_win_set_buf(0, save_buffer)
  vim.bo.bufhidden = save_bufhidden

  -- Maximize the window.
  for _, window in ipairs(tabscoped[tab].windows) do
    if window.handle ~= current_window_handle then
      vim.api.nvim_win_close(window.handle, true)
    end
  end

  vim.fn.winrestview(save_view)
end

M.normal_windows_restorable = function()
  local tab = vim.api.nvim_get_current_tabpage()
  tabscoped[tab] = tabscoped[tab] or {}

  return tabscoped[tab].restore_script ~= nil
end

M.restore_normal_windows = function()
  local tab = vim.api.nvim_get_current_tabpage()
  tabscoped[tab] = tabscoped[tab] or {}

  local save_view = vim.fn.winsaveview()
  local save_buffer = vim.api.nvim_get_current_buf()
  local save_bufhidden = vim.bo.bufhidden
  vim.bo.bufhidden = 'hide'

  -- The current buffer when sourcing a session can't be
  -- modified so create and open a temporary unlisted buffer.
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))

  local save_eventignore = vim.o.eventignore
  vim.opt.eventignore:append('SessionLoadPost')
  local save_this_session = vim.v.this_session
  _ = vim.api.nvim_exec2(tabscoped[tab].restore_script, { output = true })
  vim.v.this_session = save_this_session
  vim.o.eventignore = save_eventignore

  vim.api.nvim_win_set_buf(0, save_buffer)
  vim.bo.bufhidden = save_bufhidden

  -- Restore the buffer handles, cursor positions and
  -- window local variables for all restored windows.
  local current_window_handle = vim.api.nvim_get_current_win()
  local windows = vim.api.nvim_tabpage_list_wins(0)
  for i = 1, #windows do
    local window = tabscoped[tab].windows[i]
    local window_handle = windows[i]
    if window_handle ~= current_window_handle then
      vim.api.nvim_win_set_buf(window_handle, window.buffer.handle)
      vim.api.nvim_win_set_cursor(window_handle, window.save_cursor)
      vim.bo[window.buffer.handle].bufhidden = window.buffer.save_bufhidden
      vim.bo[window.buffer.handle].buftype = window.buffer.save_buftype
      vim.w[window_handle].current_syntax = vim.w[window_handle].current_syntax or window.save_current_syntax
      vim.w[window_handle].quickfix_title = vim.w[window_handle].quickfix_title or window.save_quickfix_title
    end
  end

  vim.fn.winrestview(save_view)

  tabscoped[tab] = nil
end

return M

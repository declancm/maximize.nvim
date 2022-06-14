local M = {}

local utils = require("maximize.utils")

M.toggle = function()
  if vim.t.maximized then
    M.restore()
  else
    M.maximize()
  end
end

M.maximize = function()
  -- Return if only one window exists.
  if vim.fn.winnr("$") == 1 then
    return
  end

  -- A temporary file for storing the current session. It's unique and per tab.
  vim.t.tmp_session_file = "~/.cache/nvim/.maximize_session-" .. os.time() .. ".vim"

  -- Save options.
  vim.t.saved = {}
  vim.t.saved.cmdheight = vim.opt.cmdheight
  vim.t.saved.cmdwinheight = vim.opt.cmdwinheight

  -- Handle floating windows
  -- TODO: after the next Neovim release, we don't need to handle float wins
  -- (https://github.com/neovim/neovim/commit/3fe6bf3a1e50299dbdd6314afbb18e468eb7ce08)

  -- Close floating windows because they break session files.
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      vim.api.nvim_win_close(win, false)
    end
  end

  -- If a floating window still exists, it contains unsaved changes so return.
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      utils.error_msg("Cannot maximize. A floating window with unsaved changes exists")
      return
    end
  end

  -- Save the session.
  local saved_sessionoptions = vim.opt.sessionoptions:get()
  vim.opt.sessionoptions = { "blank", "buffers", "curdir", "folds", "help", "winsize" }
  vim.cmd("mksession! " .. vim.t.tmp_session_file)
  vim.opt.sessionoptions = saved_sessionoptions

  -- Maximize the window.
  vim.cmd("only")

  vim.t.maximized = true
end

M.restore = function()

  -- Avoid [No Name] buffer if set hidden (E.g., when maximizing the help window
  -- and then restore)
  vim.bo.bufhidden = 'wipe'

  -- Restore windows.
  if vim.fn.filereadable(vim.fn.expand(vim.t.tmp_session_file)) == 1 then
    vim.cmd("silent wall")
    local file_name = vim.fn.getreg("%")
    local saved_position = vim.fn.getcurpos()

    -- Source the saved session.
    vim.cmd("silent source " .. vim.t.tmp_session_file)

    -- Delete the saved session.
    vim.fn.delete(vim.fn.expand(vim.t.tmp_session_file))

    if vim.fn.getreg("%") ~= file_name then
      vim.cmd("edit " .. file_name)
    end
    vim.fn.setpos(".", saved_position)
  end

  -- Restore saved options.
  for option, value in pairs(vim.t.saved) do
    vim.opt[option] = value
  end

  vim.t.maximized = false
end

return M

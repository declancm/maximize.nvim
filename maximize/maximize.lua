local M = {}

local utils = require("windex.utils")

M.saved = {}

-- Toggle maximizing the current nvim window and tmux pane.
M.toggle = function(maximize_option)
  maximize_option = maximize_option or "all"

  if not utils.contains({ "none", "nvim", "all" }, maximize_option) then
    utils.error_msg("Not a valid argument")
    return
  end

  if not vim.w.__windex_maximized then
    M.maximize(maximize_option)
  else
    M.restore()
  end
end

-- Maximize the current nvim window and tmux pane.
M.maximize = function(maximize_option)
  maximize_option = maximize_option or "all"
  if not utils.contains({ "none", "nvim", "all" }, maximize_option) then
    utils.error_msg("Not a valid argument")
    return
  end

  vim.w.__windex_restore_option = maximize_option
  if maximize_option == "none" then
    return
  end

  -- Save options.
  M.saved = {}
  M.saved.cmdheight = vim.opt.cmdheight
  M.saved.cmdwinheight = vim.opt.cmdwinheight

  -- Close floating windows because they break session files.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      vim.api.nvim_win_close(win, false)
    end
  end

  -- If a floating window still exists, it contains unsaved changes so return.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      utils.error_msg("Cannot maximize. A floating window with unsaved changes exists")
      return
    end
  end

  -- Maximize nvim window.
  if vim.fn.winnr("$") ~= 1 then
    -- Save the session.
    local saved_sessionoptions = vim.opt.sessionoptions:get()
    vim.opt.sessionoptions = { "blank", "buffers", "curdir", "folds", "help", "tabpages", "winsize" }
    vim.cmd("mksession! ~/.cache/nvim/.maximize_session.vim")
    vim.opt.sessionoptions = saved_sessionoptions

    vim.cmd("only")
  end

  vim.w.__windex_maximized = true
end

-- Restore the nvim windows and tmux panes.
M.restore = function(maximize_option)
  maximize_option = maximize_option or vim.w.__windex_restore_option or "all"
  if maximize_option == "none" then
    return
  end

  -- Restore nvim windows.
  if vim.fn.filereadable(vim.fn.getenv("HOME") .. "/.cache/nvim/.maximize_session.vim") == 1 then
    vim.cmd("wall")
    local file_name = vim.fn.getreg("%")
    local saved_position = vim.fn.getcurpos()

    -- Source the saved session.
    vim.cmd("source ~/.cache/nvim/.maximize_session.vim")

    -- Delete the saved session.
    vim.fn.delete(vim.fn.getenv("HOME") .. "/.cache/nvim/.maximize_session.vim")

    if vim.fn.getreg("%") ~= file_name then
      vim.cmd("edit " .. file_name)
    end
    vim.fn.setpos(".", saved_position)
  end

  -- Restore saved options.
  for option, value in pairs(M.saved) do
    vim.opt[option] = value
  end

  vim.w.__windex_maximized = false
end

return M

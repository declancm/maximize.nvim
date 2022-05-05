local M = {}

local utils = require("maximize.utils")

local maximized = false
local saved = {}

M.toggle = function()
  if maximized then
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

  -- Save options.
  saved = {}
  saved.cmdheight = vim.opt.cmdheight
  saved.cmdwinheight = vim.opt.cmdwinheight

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

  -- Save the session.
  local saved_sessionoptions = vim.opt.sessionoptions:get()
  vim.opt.sessionoptions = { "blank", "buffers", "curdir", "folds", "help", "tabpages", "winsize" }
  vim.cmd("mksession! ~/.cache/nvim/.maximize_session.vim")
  vim.opt.sessionoptions = saved_sessionoptions

  -- Maximize the window.
  vim.cmd("only")

  maximized = true
end

M.restore = function()
  -- Restore windows.
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
  for option, value in pairs(saved) do
    vim.opt[option] = value
  end

  maximized = false
end

return M

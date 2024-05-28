local M = {}

local config = require('maximize.config')
local integrations = require('maximize.integrations')
local windows = require('maximize.windows')

M.setup = function(user_config)
  config.setup(user_config)

  integrations.plugins = {}
  for name, options in pairs(config.options.plugins) do
    if options.enable then
      table.insert(integrations.plugins, require('maximize.integrations.' .. name))
    end
  end

  local group = vim.api.nvim_create_augroup('Maximize', {})
  vim.api.nvim_create_autocmd('WinLeave', {
    group = group,
    callback = windows.track_last_opened_normal_window,
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

local lazyredraw = function(fn)
  local save_lazyredraw = vim.o.lazyredraw
  vim.o.lazyredraw = true
  fn()
  vim.o.lazyredraw = save_lazyredraw
end

M.maximize = function()
  if windows.get_normal_window_count() > 1 then
    vim.t.maximized = true

    lazyredraw(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'WindowMaximizeStart' })
      integrations.clear()

      windows.leave_floating_window()
      windows.close_floating_windows()
      windows.maximize_normal_window()
    end)
  end
end

M.restore = function()
  vim.t.maximized = false

  if windows.normal_windows_restorable() then
    lazyredraw(function()
      windows.leave_floating_window()
      windows.close_floating_windows()
      windows.restore_normal_windows()

      integrations.restore()
      vim.api.nvim_exec_autocmds('User', { pattern = 'WindowRestoreEnd' })
    end)
  end
end

return M

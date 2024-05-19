if 1 ~= vim.fn.has "nvim-0.8.0" then
  vim.api.nvim_err_writeln "Maximize.nvim requires at least nvim-0.8.0"
  return
end

if vim.g.loaded_maximize == 1 then
  return
end
vim.g.loaded_maximize = 1

vim.api.nvim_create_user_command('Maximize', require('maximize').toggle, { desc = 'Toggle maximizing the current window' })

local M = {
  callbacks = {}
}
local plugins = {
  require('maximize.integrations.aerial'),
  require('maximize.integrations.tree'),
}

function M.clear()
  local tab = vim.api.nvim_get_current_tabpage()
  M.callbacks[tab] = {}

  for _, fn in ipairs(plugins) do
    local ok, cb = fn()
    if ok then
      table.insert(M.callbacks[tab], cb)
    end
  end
end

function M.restore()
  local tab = vim.api.nvim_get_current_tabpage()
  if M.callbacks[tab] == nil then
    return
  end

  for _, fn in ipairs(M.callbacks[tab]) do
    fn()
  end
  M.callbacks[tab] = nil
end

return M

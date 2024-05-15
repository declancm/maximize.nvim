local M = {}

-- https://github.com/Shatur/neovim-session-manager/blob/9652b392805dfd497877342e54c5a71be7907daf/lua/session_manager/utils.lua#L129-L149
M.is_restorable = function(buffer)
  if #vim.api.nvim_buf_get_option(buffer, 'bufhidden') ~= 0 then
    return false
  end

  local buftype = vim.api.nvim_buf_get_option(buffer, 'buftype')
  if #buftype == 0 then
    -- Normal buffer, check if it listed
    if not vim.api.nvim_buf_get_option(buffer, 'buflisted') then
      return false
    end
  elseif buftype ~= 'terminal' then
    -- Buffers other then normal or terminal are impossible to restore
    return false
  end

  return true
end

return M

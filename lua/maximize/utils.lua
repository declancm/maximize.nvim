local utils = {}

utils.error_msg = function(message, code, level)
  code = code or 'Error'
  level = level or 'ERROR'
  vim.notify(string.format('%s: %s', code, message), vim.log.levels[level])
end

utils.merge = function(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == 'table') and (type(t1[k] or false) == 'table') then
      if utils.is_array(t1[k]) then
        t1[k] = utils.concat(t1[k], v)
      else
        utils.merge(t1[k], t2[k])
      end
    else
      t1[k] = v
    end
  end
  return t1
end

utils.concat = function(t1, t2)
  for i = 1, #t2 do
    table.insert(t1, t2[i])
  end
  return t1
end

utils.is_array = function(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then
      return false
    end
  end
  return true
end

-- https://github.com/Shatur/neovim-session-manager/blob/9652b392805dfd497877342e54c5a71be7907daf/lua/session_manager/utils.lua#L129-L149
utils.is_restorable = function(buffer)
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

return utils

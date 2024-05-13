return function()
  local ok, api = pcall(require, 'dapui')
  if not ok then
    return false, nil
  end

  -- TODO: Surely there's a better way of checking if dapui is open??
  local dapui_is_open = function()
    for _, layout in ipairs(require('dapui.windows').layouts) do
      if layout:is_open() then
        return true
      end
    end
    return false
  end

  local cb = function()
    if not dapui_is_open() then
      api.open()
    end
  end

  if dapui_is_open() then
    api.close()
    return true, cb
  end
  return false, nil
end

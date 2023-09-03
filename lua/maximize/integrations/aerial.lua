return function()
  local ok, api = pcall(require, 'aerial')
  if not ok then
    return false, nil
  end

  local cb = function()
    if not api.is_open() then
      api.open({ focus = false })
    end
  end

  if api.is_open() then
    api.close()
    return true, cb
  end
  return false, nil
end

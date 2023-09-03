return function()
  local ok, api = pcall(require, 'nvim-tree.api')
  if not ok then
    return false, nil
  end

  local cb = function()
    if not api.tree.is_visible() then
      api.tree.toggle({ focus = false })
    end
  end

  if api.tree.is_visible() then
    api.tree.close()
    return true, cb
  end
  return false, nil
end

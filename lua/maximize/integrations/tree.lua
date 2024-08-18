return function()
  local ok, api = pcall(require, 'nvim-tree.api')
  -- `is_visible` is only available since nvim-tree commit 'a774fa1'
  ok = ok and api.tree.is_visible ~= nil
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

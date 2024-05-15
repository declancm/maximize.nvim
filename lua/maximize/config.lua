local M = {}

M.options = {}

local defaults = {
  plugins = {
    aerial = { enable = true },
    dapui = { enable = true },
    tree = { enable = true },
  },
}

local deprecated = {
  ['default_keymaps'] =
  "The 'default_keymaps' option is deprecated in favor of the ':Maximize' command and custom keymaps",
}

function M.setup(options)
  -- Check for deprecated options.
  for option, message in pairs(deprecated) do
    local keys = vim.split(option, '.', { plain = true })
    if vim.tbl_get(options or {}, unpack(keys)) ~= nil then
      vim.notify('[maximize.config] ' .. message, vim.log.levels.WARN)
    end
  end

  -- Merge user options with defaults.
  M.options = vim.tbl_deep_extend('force', {}, defaults, options or {})
end

return M

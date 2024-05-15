local M = {}

local defaults = {
  default_keymaps = true,
  plugins = {
    aerial = { enable = true },
    dapui = { enable = true },
    tree = { enable = true },
  },
}

M.options = {}

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

return M

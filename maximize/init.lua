local M = {}

M.setup = function(user_config)
	-- Check if user is on Windows.
	if vim.fn.has("win32") == 1 then
		require("windex.utils").error_msg("A unix system is required for windex. Have you tried using WSL?")
		return
	end

	local utils = require("windex.utils")
	local config = require("windex.config")

	-- Setting the config options.
	if user_config ~= nil then
		utils.merge(config, user_config)
	end

	-- AUTOCMDS:

	if vim.fn.has("nvim-0.7.0") == 1 then
		local autocmd = vim.api.nvim_create_autocmd
		local augroup = vim.api.nvim_create_augroup

		-- Delete session file from cache.
		autocmd({ "VimEnter", "VimLeave" }, {
			command = "call delete(getenv('HOME') . '/.cache/nvim/.maximize_session.vim')",
			group = augroup("windex_maximize", {}),
		})
	else
		-- Delete session file from cache.
		vim.cmd([[
    aug windex_maximize
    au!
    au VimEnter * call delete(getenv('HOME') . '/.cache/nvim/.maximize_session.vim')
    au VimLeave * call delete(getenv('HOME') . '/.cache/nvim/.maximize_session.vim')
    aug END
    ]])
	end

	-- KEYMAPS:

	if config.default_keymaps then
		local keymap = vim.api.nvim_set_keymap
		local opts = { noremap = true }

		keymap("n", "<Leader>z", "<Cmd>lua require('windex').toggle_maximize()<CR>", opts)
	end
end

-- API:

-- Maximize:
M.toggle_maximize = function()
	require("windex.maximize").toggle()
end
M.maximize_windows = function()
	require("windex.maximize").maximize()
end
M.restore_windows = function()
	require("windex.maximize").restore()
end

return M

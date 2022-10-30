local config = require("lvim-kbrd.config")
local utils = require("lvim-kbrd.utils")
-- local autocmd = require("lvim-kbrd.autocmd")

local M = {}

M.setup = function(user_config)
	if user_config ~= nil then
		utils.merge(config, user_config)
	end
	vim.keymap.set("n", "<C-c>r", function()
		vim.notify(vim.inspect(config))
	end, { noremap = true, silent = true })
	-- vim.api.nvim_create_user_command("LvimKbrdToggle", "lua require'lvim-kbrd.toggle'.toggle()", {})
	-- M.init()
end

M.init = function()
	if config.active_plugin == 1 then
		-- autocmd.enable()
	end
end

return M

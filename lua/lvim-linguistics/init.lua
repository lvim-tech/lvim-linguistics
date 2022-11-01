-- http://ftp.vim.org/vim/runtime/spell
local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local funcs = require("lvim-linguistics.funcs")
local autocmd = require("lvim-linguistics.autocmd")

local M = {}

M.setup = function(user_config)
	if user_config ~= nil then
		utils.merge(config, user_config)
	end
	funcs.check_dir()
	funcs.get_config()
	autocmd.change_directory()
	vim.defer_fn(function()
		funcs.proccess()
	end, 100)
end

return M

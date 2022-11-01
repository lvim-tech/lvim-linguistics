local funcs = require("lvim-linguistics.funcs")

local M = {}

local timer = true

local group_download = vim.api.nvim_create_augroup("LvimLinguisticsSpellFilesDownload", {
	clear = true,
})
local group_change_directory = vim.api.nvim_create_augroup("LvimLinguisticsChangeDirectory", {
	clear = true,
})
local group_change_mode = vim.api.nvim_create_augroup("LvimLinguisticsChangeMode", {
	clear = true,
})

M.spell_file_download = function()
	-- vim.api.nvim_create_autocmd("SpellFileMissing", {
	--     callback = function()
	--         -- local lang = vim.fn.expand("<amatch>")
	--         vim.notify("Helllllo")
	--     end,
	--     group = group_change_directory,
	-- })
	-- vim.api.nvim_create_autocmd("BufEnter", {
	--     callback = function()
	--         vim.notify(vim.bo.filetype)
	--         -- vim.notify(vim.opt.fileencoding:get())
	--     end,
	--     group = group_change_directory,
	-- })
end

M.change_directory = function()
	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			if timer then
				timer = false
				funcs.get_config()
				funcs.proccess()
				vim.defer_fn(function()
					timer = true
				end, 10)
			end
		end,
		group = group_change_directory,
	})
end

local group_exclude_spell_ft = vim.api.nvim_create_augroup("LvimLinguisticsExcludeSpellFt", {
	clear = true,
})
M.exclude_spell_ft = function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = {
			"ctrlspace",
			"ctrlspace_help",
			"packer",
			"undotree",
			"diff",
			"Outline",
			"NvimTree",
			"LvimHelper",
			"floaterm",
			"toggleterm",
			"Trouble",
			"dashboard",
			"vista",
			"spectre_panel",
			"DiffviewFiles",
			"flutterToolsOutline",
			"log",
			"qf",
			"dapui_scopes",
			"dapui_breakpoints",
			"dapui_stacks",
			"dapui_watches",
			"calendar",
			"org",
			"tex",
			"octo",
			"neo-tree",
			"neo-tree-popup",
			"noice",
		},
		callback = function()
			vim.opt_local.spell = false
		end,
		group = group_exclude_spell_ft,
	})
end

M.enable_change_mode = function()
	vim.api.nvim_create_autocmd("InsertEnter", {
		pattern = "*",
		command = 'lua require"lvim-linguistics.funcs".insert_enter()',
		group = group_change_mode,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		pattern = "*",
		command = 'lua require"lvim-linguistics.funcs".insert_leave()',
		group = group_change_mode,
	})
end

M.disable_change_mode = function()
	local autocommands = vim.api.nvim_get_autocmds({
		group = group_change_mode,
	})
	vim.api.nvim_del_autocmd(autocommands[1]["id"])
	vim.api.nvim_del_autocmd(autocommands[2]["id"])
end

return M

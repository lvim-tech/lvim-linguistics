local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local funcs = require("lvim-linguistics.funcs")
local commands = require("lvim-linguistics.commands")
local timer = true
local group_spell_file_missing = vim.api.nvim_create_augroup("LvimLinguisticsSpellFileMissing", {
    clear = true,
})
local group_change_directory = vim.api.nvim_create_augroup("LvimLinguisticsChangeDirectory", {
    clear = true,
})

local M = {}

M.setup = function(user_config)
    if user_config ~= nil then
        utils.merge(config, user_config)
    end
    funcs.check_dir()
    funcs.get_config()
    M.spell_file_missing()
    vim.defer_fn(function()
        commands.init_commands()
        funcs.proccess()
        M.change_directory()
    end, 10)
end

M.spell_file_missing = function()
    vim.api.nvim_create_autocmd("SpellFileMissing", {
        callback = function()
            local lang = vim.fn.expand("<amatch>")
            local cmd = "wget -P "
                .. config.plugin_config.spell_files_folder
                .. " -A spl,sug -l 1 -r -np -nd http://ftp.vim.org/vim/runtime/spell --accept-regex '/"
                .. lang
                .. ".**.spl|/"
                .. lang
                .. ".**.sug'"
                .. " &> /dev/null"
            os.execute(cmd)
        end,
        group = group_spell_file_missing,
    })
end

M.change_directory = function()
    vim.api.nvim_create_autocmd("DirChanged", {
        pattern = "global",
        callback = function()
            funcs.get_config()
            funcs.proccess()
        end,
        group = group_change_directory,
    })
end

return M

-- http://ftp.vim.org/vim/runtime/spell
local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local funcs = require("lvim-linguistics.funcs")
local commands = require("lvim-linguistics.commands")
local timer = true
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
    M.change_directory()
    vim.defer_fn(function()
        funcs.proccess()
    end, 100)
    commands.init_commands()
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

return M

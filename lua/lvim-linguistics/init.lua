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
    vim.cmd([[let loaded_spellfile_plugin = 1]])
    -- vim.g.loaded_spellfile_plugin = 1
    -- autocmd.spell_file_download()
    funcs.check_dir()
    funcs.get_config()
    funcs.proccess()
    vim.defer_fn(function()
        autocmd.change_directory()
    end, 100)
end

return M

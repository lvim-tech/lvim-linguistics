local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local funcs = require("lvim-linguistics.funcs")
-- local autocmd = require("lvim-linguistics.autocmd")

local M = {}

M.get_config = function()
    local local_config = utils.read_file(vim.fn.getcwd() .. ".lvim_linguistics.json", true)
    if local_config ~= nil then
        _G.LVIM_LINGUISTICS = local_config
    else
        _G.LVIM_LINGUISTICS = config.base_config
    end
    -- if
    --     _G.LVIM_LINGUISTICS.language.active == true
    --     and _G.LVIM_LINGUISTICS.language.filetypes ~= nil
    --     and _G.LVIM_LINGUISTICS.language.normal_mode_language ~= nil
    --     and _G.LVIM_LINGUISTICS.language.insert_mode_language ~= nil
    -- then
    --     -- autocmd.enable_change_mode()
    -- else
    --     -- autocmd.disable_change_mode()
    -- end
    -- if _G.LVIM_LINGUISTICS.spell.active == true and _G.LVIM_LINGUISTICS.spell.language ~= nil then
    --     funcs.enable_spell()
    -- else
    --     funcs.disable_spell()
    -- end
end

M.save_local_config = function()
    --
end

M.delete_local_config = function()
    --
end

return M

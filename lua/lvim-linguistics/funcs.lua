local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local notify = require("lvim-linguistics.ui.notify")

local M = {}

M.check_dir = function()
    if utils.exists(config.plugin_config.spell_files_folder) == false then
        utils.create_dir(config.plugin_config.spell_files_folder)
    end
end

M.get_config = function()
    local local_config = utils.read_file(vim.fn.getcwd() .. ".lvim_linguistics.json", true)
    if local_config ~= nil then
        _G.LVIM_LINGUISTICS = local_config
    else
        _G.LVIM_LINGUISTICS = config.base_config
    end
end

M.proccess = function()
    -- if _G.LVIM_LINGUISTICS.language.active == true then
    --     M.enable_change_mode()
    -- else
    --     M.disable_change_mode()
    -- end
    if _G.LVIM_LINGUISTICS.spell.active == true then
        M.enable_spell()
    else
        M.disable_spell()
    end
end

M.check_config_language = function()
    --
end

M.check_config_spell = function()
    --
end

M.insert_enter = function()
    -- os.execute(config.plugin_config.kbrd_cmd .. _G.LVIM_LINGUISTICS.language.insert_mode_language)
end

M.insert_leave = function()
    -- os.execute(config.plugin_config.kbrd_cmd .. _G.LVIM_LINGUISTICS.language.normal_mode_language)
end

M.enable_spell = function()
    local function enable()
        local spelllang = _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language].spelllang
        local spellfile = _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language].spellfile

        local cmd = "set spell spelllang="
            .. spelllang
            .. " spellfile="
            .. config.plugin_config.spell_files_folder
            .. spellfile
        -- vim.schedule(function()
        vim.cmd(cmd)
        -- end)
    end
    enable()
    -- local winnr = vim.api.nvim_get_current_win()
    -- local bufnr = vim.api.nvim_win_get_buf(winnr)
    -- local ft = vim.bo.filetype
    -- local bt = vim.bo.buftype
    -- if vim.bo.modifiable == true and not utils.ignore_by_ft(ft) and not utils.ignore_by_bt(bt) then
    --     print("hoho111111")
    --     enable()
    -- else
    --     local group_enable_spell = vim.api.nvim_create_augroup("LvimLinguisticsEnableSpell", {
    --         clear = true,
    --     })
    --     vim.api.nvim_create_autocmd("BufEnter", {
    --         callback = function()
    --             ft = vim.bo.filetype
    --             bt = vim.bo.buftype
    --             vim.notify(ft)
    --             if vim.bo.modifiable == true and not utils.ignore_by_ft(ft) and not utils.ignore_by_bt(bt) then
    --                 enable()
    --                 vim.api.nvim_del_augroup_by_name("LvimLinguisticsEnableSpell")
    --             end
    --         end,
    --         group = group_enable_spell,
    --     })
    -- end
end

M.disable_spell = function()
    vim.cmd("set nospell")
end

return M

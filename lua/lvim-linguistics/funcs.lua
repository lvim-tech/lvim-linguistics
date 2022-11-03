local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local notify = require("lvim-linguistics.ui.notify")
local group_change_mode = vim.api.nvim_create_augroup("LvimLinguisticsChangeMode", {
    clear = true,
})

local M = {}

M.check_dir = function()
    if utils.exists(config.plugin_config.spell_files_folder) == false then
        utils.create_dir(config.plugin_config.spell_files_folder)
    end
end

M.get_config = function()
    local local_config = utils.read_file(vim.fn.getcwd() .. "/.lvim_linguistics.json", true)
    if local_config ~= nil then
        _G.LVIM_LINGUISTICS = local_config
    else
        _G.LVIM_LINGUISTICS = config.base_config
    end
end

M.proccess = function()
    if _G.LVIM_LINGUISTICS.mode_language.active == true then
        M.enable_insert_mode_language()
    else
        M.disable_insert_mode_language()
    end
    if _G.LVIM_LINGUISTICS.spell.active == true then
        M.enable_spelling()
    else
        M.disable_spelling()
    end
end

M.insert_mode_language = function(language)
    _G.LVIM_LINGUISTICS.mode_language.insert_mode_language = language
end

M.enable_insert_mode_language = function()
    if
        _G.LVIM_LINGUISTICS.mode_language.normal_mode_language == nil
        or type(_G.LVIM_LINGUISTICS.mode_language.normal_mode_language) ~= "string"
    then
        notify.error("Not defined language for normal mode")
        return
    end
    if
        _G.LVIM_LINGUISTICS.mode_language.insert_mode_language == nil
        or type(_G.LVIM_LINGUISTICS.mode_language.insert_mode_language) ~= "string"
    then
        notify.error("Not defined language for insert mode")
        return
    end
    _G.LVIM_LINGUISTICS.mode_language.active = true
    vim.api.nvim_create_autocmd("InsertEnter", {
        pattern = "*",
        callback = function()
            os.execute(config.plugin_config.kbrd_cmd .. _G.LVIM_LINGUISTICS.mode_language.insert_mode_language)
        end,
        group = group_change_mode,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        pattern = "*",
        callback = function()
            os.execute(config.plugin_config.kbrd_cmd .. _G.LVIM_LINGUISTICS.mode_language.normal_mode_language)
        end,
        group = group_change_mode,
    })
end

M.disable_insert_mode_language = function()
    _G.LVIM_LINGUISTICS.mode_language.active = false
    local autocommands = vim.api.nvim_get_autocmds({
        group = group_change_mode,
    })
    pcall(function()
        vim.api.nvim_del_autocmd(autocommands[1]["id"])
        vim.api.nvim_del_autocmd(autocommands[2]["id"])
    end)
end

M.toggle_insert_mode_language = function()
    if _G.LVIM_LINGUISTICS.mode_language.active == false then
        M.enable_insert_mode_language()
        notify.info("Insert mode language enabled")
    else
        M.disable_insert_mode_language()
        notify.info("Insert mode language disabled")
    end
end

M.change_spell_language = function(language)
    _G.LVIM_LINGUISTICS.spell.language = language
end

M.enable_spelling = function()
    local function enable()
        if _G.LVIM_LINGUISTICS.spell.language == nil or type(_G.LVIM_LINGUISTICS.spell.language) ~= "string" then
            notify.error("Not defined language(s)")
            return
        end
        if _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language] == nil then
            notify.error("Not defined settings for: " .. _G.LVIM_LINGUISTICS.spell.language)
            return
        end
        local spelllang = _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language].spelllang
        local spellfile = _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language].spellfile
        if spelllang == nil or type(spelllang) ~= "string" then
            notify.error("Incorrect defined spell file for: " .. _G.LVIM_LINGUISTICS.spell.language)
            return
        end
        if spellfile == nil or type(spellfile) ~= "string" then
            spellfile = "global.add"
        end
        local cmd = "set spell spelllang="
            .. spelllang
            .. " spellfile="
            .. config.plugin_config.spell_files_folder
            .. spellfile
        vim.cmd(cmd)
        _G.LVIM_LINGUISTICS.spell.active = true
    end
    local ft = vim.bo.filetype
    local bt = vim.bo.buftype
    if vim.bo.modifiable == true and not utils.ignore_by_ft(ft) and not utils.ignore_by_bt(bt) then
        enable()
    else
        local group_enable_spell = vim.api.nvim_create_augroup("LvimLinguisticsEnableSpell", {
            clear = true,
        })
        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                ft = vim.bo.filetype
                bt = vim.bo.buftype
                if vim.bo.modifiable == true and not utils.ignore_by_ft(ft) and not utils.ignore_by_bt(bt) then
                    enable()
                    vim.api.nvim_del_augroup_by_name("LvimLinguisticsEnableSpell")
                end
            end,
            group = group_enable_spell,
        })
    end
end

M.disable_spelling = function()
    _G.LVIM_LINGUISTICS.spell.active = false
    vim.cmd("set nospell")
end

M.toggle_spelling = function()
    if _G.LVIM_LINGUISTICS.spell.active == false then
        M.enable_spelling()
        notify.info("Spelling enabled: (" .. _G.LVIM_LINGUISTICS.spell.language .. ")")
    else
        M.disable_spelling()
        notify.info("Spelling disabled")
    end
end

M.save_current_config_as_local = function()
    --
end

M.update_local_config = function()
    --
end

M.delete_local_congig = function()
    --
end

return M

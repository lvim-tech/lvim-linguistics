local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local notify = require("lvim-ui-config.notify")
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
        notify.error("Not defined language for normal mode", {
            title = "LVIM LINGUISTICS",
        })
        return
    end
    if
        _G.LVIM_LINGUISTICS.mode_language.insert_mode_language == nil
        or type(_G.LVIM_LINGUISTICS.mode_language.insert_mode_language) ~= "string"
    then
        notify.error("Not defined language for insert mode", {
            title = "LVIM LINGUISTICS",
        })
        return
    end
    _G.LVIM_LINGUISTICS.mode_language.active = true
    vim.api.nvim_create_autocmd("InsertEnter", {
        pattern = "*",
        callback = function()
            pcall(function()
                os.execute(
                    config.plugin_config.kbrd_cmd
                        .. _G.LVIM_LINGUISTICS.mode_language.insert_mode_language
                        .. "&> /dev/null"
                )
            end)
        end,
        group = group_change_mode,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        pattern = "*",
        callback = function()
            pcall(function()
                os.execute(
                    config.plugin_config.kbrd_cmd
                        .. _G.LVIM_LINGUISTICS.mode_language.normal_mode_language
                        .. "&> /dev/null"
                )
            end)
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
        notify.info("Insert mode language enabled", {
            title = "LVIM LINGUISTICS",
        })
    else
        M.disable_insert_mode_language()
        notify.info("Insert mode language disabled", {
            title = "LVIM LINGUISTICS",
        })
    end
end

M.change_spell_language = function(language)
    _G.LVIM_LINGUISTICS.spell.language = language
end

M.enable_spelling = function()
    local function enable()
        if _G.LVIM_LINGUISTICS.spell.language == nil or type(_G.LVIM_LINGUISTICS.spell.language) ~= "string" then
            notify.error("Not defined language(s)", {
                title = "LVIM LINGUISTICS",
            })
            return
        end
        if _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language] == nil then
            notify.error("Not defined settings for: " .. _G.LVIM_LINGUISTICS.spell.language, {
                title = "LVIM LINGUISTICS",
            })
            return
        end
        local spelllang = _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language].spelllang
        local spellfile = _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language].spellfile
        if spelllang == nil or type(spelllang) ~= "string" then
            notify.error("Incorrect defined spell file for: " .. _G.LVIM_LINGUISTICS.spell.language, {
                title = "LVIM LINGUISTICS",
            })
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
    enable()
end

M.disable_spelling = function()
    _G.LVIM_LINGUISTICS.spell.active = false
    vim.cmd("set nospell")
end

M.toggle_spelling = function()
    if _G.LVIM_LINGUISTICS.spell.active == false then
        M.enable_spelling()
        notify.info("Spelling enabled: (" .. _G.LVIM_LINGUISTICS.spell.language .. ")", {
            title = "LVIM LINGUISTICS",
        })
    else
        M.disable_spelling()
        notify.info("Spelling disabled", {
            title = "LVIM LINGUISTICS",
        })
    end
end

return M

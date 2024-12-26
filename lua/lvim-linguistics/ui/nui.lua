local utils = require("lvim-linguistics.utils")
local funcs = require("lvim-linguistics.funcs")
local ui_config = require("lvim-ui-config.config")
local select = require("lvim-ui-config.select")
local notify = require("lvim-ui-config.notify")

local M = {}

M.menu_spelling_status = function()
    if _G.LVIM_LINGUISTICS.spell.language == nil then
        notify.error("Not defined settings for: " .. _G.LVIM_LINGUISTICS.spell.language, {
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
    local spelling_status
    if _G.LVIM_LINGUISTICS.spell.active == true then
        spelling_status = "Active (" .. _G.LVIM_LINGUISTICS.spell.language .. ")"
    else
        spelling_status = "Not active"
    end
    local opts = ui_config.select({
        "Enable spelling",
        "Disable spelling",
        "Cancel",
    }, { prompt = "Spelling status: " .. spelling_status }, {})
    select(opts, function(choice)
        if choice == "Enable spelling" then
            funcs.enable_spelling()
            notify.info("Spelling enabled: (" .. _G.LVIM_LINGUISTICS.spell.language .. ")", {
                title = "LVIM LINGUISTICS",
            })
        elseif choice == "Disable spelling" then
            funcs.disable_spelling()
            notify.info("Spelling disabled", {
                title = "LVIM LINGUISTICS",
            })
        end
    end)
end

M.menu_spell_languages = function()
    local values_preview = {}
    local values_choice = {}
    local string_to_insert = nil
    local spelllang = nil
    local spellfile = nil
    for k, _ in pairs(_G.LVIM_LINGUISTICS.spell.languages) do
        if
            _G.LVIM_LINGUISTICS.spell.languages[k]["spelllang"] == nil
            or type(_G.LVIM_LINGUISTICS.spell.languages[k]["spelllang"]) ~= "string"
        then
            notify.error("Incorrect defined spell file for: " .. k, {
                title = "LVIM LINGUISTICS",
            })
            return
        else
            spelllang = _G.LVIM_LINGUISTICS.spell.languages[k]["spelllang"]
        end
        if
            _G.LVIM_LINGUISTICS.spell.languages[k]["spellfile"] == nil
            or type(_G.LVIM_LINGUISTICS.spell.languages[k]["spellfile"]) ~= "string"
        then
            spellfile = "global.add"
        else
            spellfile = _G.LVIM_LINGUISTICS.spell.languages[k]["spellfile"]
        end
        string_to_insert = string.upper(k) .. " (spelllang - " .. spelllang .. ", spellfile - " .. spellfile .. ")"
        table.insert(values_preview, string_to_insert)
        values_choice[string_to_insert] = k
    end
    table.insert(values_preview, "Cancel")
    local opts = ui_config.select(values_preview, { prompt = "Choice language(s) for spelling" }, {})
    select(opts, function(choice)
        if choice == "Cancel" then
        else
            funcs.change_spell_language(values_choice[choice])
            funcs.disable_spelling()
            funcs.enable_spelling()
        end
    end)
end

M.menu_insert_mode_status = function()
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
    local insert_mode_status
    if _G.LVIM_LINGUISTICS.mode_language.active == true then
        insert_mode_status = "Active (" .. _G.LVIM_LINGUISTICS.mode_language.insert_mode_language .. ")"
    else
        insert_mode_status = "Not active"
    end
    local opts = ui_config.select({
        "Enable insert mode language",
        "Disable insert mode language",
        "Cancel",
    }, { prompt = "Insert mode language status: " .. insert_mode_status }, {})
    select(opts, function(choice)
        if choice == "Enable insert mode language" then
            funcs.enable_insert_mode_language()
            notify.info(
                "Insert mode language enabled: (" .. _G.LVIM_LINGUISTICS.mode_language.insert_mode_language .. ")",
                {
                    title = "LVIM LINGUISTICS",
                }
            )
        elseif choice == "Disable insert mode language" then
            funcs.disable_insert_mode_language()
            notify.info("Insert mode language disabled", {
                title = "LVIM LINGUISTICS",
            })
        end
    end)
end

M.menu_insert_mode_language = function()
    local values_preview = {}
    local values_choice = {}
    if
        _G.LVIM_LINGUISTICS.mode_language.insert_mode_languages == nil
        or type(_G.LVIM_LINGUISTICS.mode_language.insert_mode_languages) ~= "table"
        or next(_G.LVIM_LINGUISTICS.mode_language.insert_mode_languages) == nil
    then
        notify.error("Not defined any languages", {
            title = "LVIM LINGUISTICS",
        })
        return
    end
    for _, v in ipairs(_G.LVIM_LINGUISTICS.mode_language.insert_mode_languages) do
        table.insert(values_preview, string.upper(v))
        values_choice[string.upper(v)] = v
    end
    local opts = ui_config.select(values_preview, { prompt = "Choice language for insert mode" }, {})
    select(opts, function(choice)
        if choice == "Cancel" then
        else
            funcs.insert_mode_language(values_choice[choice])
        end
    end)
end

M.menu_save_current_config_as_local = function()
    local opts = ui_config.select({
        "Show current path",
        "Save",
        "Cancel",
    }, { prompt = "Save current config as local" }, {})
    select(opts, function(choice)
        if choice == "Show current path" then
            notify.info(vim.inspect(vim.fn.getcwd()), {
                title = "LVIM LINGUISTICS",
            })
        elseif choice == "Save" then
            utils.write_file(vim.fn.getcwd() .. "/.lvim_linguistics.json", _G.LVIM_LINGUISTICS)
        end
    end)
end

M.menu_delete_local_config = function()
    local opts = ui_config.select({
        "Delete",
        "Cancel",
    }, { prompt = "Delete local config file" }, {})
    select(opts, function(choice)
        if choice == "Delete" then
            if utils.exists(vim.fn.getcwd() .. "/.lvim_linguistics.json") then
                utils.delete_file(vim.fn.getcwd() .. "/.lvim_linguistics.json")
            else
                notify.error("File not exist", {
                    title = "LVIM LINGUISTICS",
                })
            end
        end
    end)
end

return M

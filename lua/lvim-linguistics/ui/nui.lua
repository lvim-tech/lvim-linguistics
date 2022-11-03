local utils = require("lvim-linguistics.utils")
local funcs = require("lvim-linguistics.funcs")
local select = require("lvim-select-input.select")
local notify = require("lvim-linguistics.ui.notify")

local M = {}

M.menu_spelling_status = function()
    if _G.LVIM_LINGUISTICS.spell.language == nil then
        notify.error("Not defined settings for: " .. _G.LVIM_LINGUISTICS.spell.language)
        return
    end
    if _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language] == nil then
        notify.error("Not defined settings for: " .. _G.LVIM_LINGUISTICS.spell.language)
        return
    end
    local spelling_status
    if _G.LVIM_LINGUISTICS.spell.active == true then
        spelling_status = "Active (" .. _G.LVIM_LINGUISTICS.spell.language .. ")"
    else
        spelling_status = "Not active"
    end
    select({
        "Enable spelling",
        "Disable spelling",
        "Cancel",
    }, { prompt = "Spelling status: " .. spelling_status }, function(choice)
        if choice == "Enable spelling" then
            funcs.enable_spelling()
            notify.info("Spelling enabled: (" .. _G.LVIM_LINGUISTICS.spell.language .. ")")
        elseif choice == "Disable spelling" then
            funcs.disable_spelling()
            notify.info("Spelling disabled")
        end
    end, "editor")
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
            notify.error("Incorrect defined spell file for: " .. k)
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
    select(values_preview, { prompt = "Choice language(s) for spelling" }, function(choice)
        if choice == "Cancel" then
        else
            funcs.change_spell_language(values_choice[choice])
            funcs.disable_spelling()
            funcs.enable_spelling()
        end
    end, "editor")
end

M.menu_insert_mode_status = function()
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
    local insert_mode_status
    if _G.LVIM_LINGUISTICS.mode_language.active == true then
        insert_mode_status = "Active (" .. _G.LVIM_LINGUISTICS.mode_language.insert_mode_language .. ")"
    else
        insert_mode_status = "Not active"
    end
    select({
        "Enable insert mode language",
        "Disable insert mode language",
        "Cancel",
    }, { prompt = "Insert mode language status: " .. insert_mode_status }, function(choice)
        if choice == "Enable insert mode language" then
            funcs.enable_insert_mode_language()
            notify.info(
                "Insert mode language enabled: (" .. _G.LVIM_LINGUISTICS.mode_language.insert_mode_language .. ")"
            )
        elseif choice == "Disable insert mode language" then
            funcs.disable_insert_mode_language()
            notify.info("Insert mode language disabled")
        else
        end
    end, "editor")
end

M.menu_insert_mode_language = function()
    local values_preview = {}
    local values_choice = {}
    if
        _G.LVIM_LINGUISTICS.mode_language.insert_mode_languages == nil
        or type(_G.LVIM_LINGUISTICS.mode_language.insert_mode_languages) ~= "table"
        or next(_G.LVIM_LINGUISTICS.mode_language.insert_mode_languages) == nil
    then
        notify.error("Not defined any languages")
        return
    end
    for _, v in ipairs(_G.LVIM_LINGUISTICS.mode_language.insert_mode_languages) do
        table.insert(values_preview, string.upper(v))
        values_choice[string.upper(v)] = v
    end
    select(values_preview, { prompt = "Choice language for insert mode" }, function(choice)
        if choice == "Cancel" then
        else
            funcs.insert_mode_language(values_choice[choice])
        end
    end, "editor")
end

M.menu_save_current_config_as_local = function()
    select({
        "Show current path",
        "Save",
        "Cancel",
    }, { prompt = "Save current config as local" }, function(choice)
        if choice == "Show current path" then
            vim.notify(vim.inspect(vim.fn.getcwd()))
        elseif choice == "Save" then
            -- vim.notify(vim.inspect(_G.LVIM_LINGUISTICS))
            utils.write_file(vim.fn.getcwd() .. "/.lvim_linguistics.json", _G.LVIM_LINGUISTICS, true)
        end
    end, "editor")
end

M.menu_delete_local_config = function()
    select({
        "Delete",
        "Cancel",
    }, { prompt = "Delete local config file" }, function(choice)
        if choice == "Delete" then
            if utils.exists(vim.fn.getcwd() .. "/.lvim_linguistics.json") then
                utils.delete_file(vim.fn.getcwd() .. "/.lvim_linguistics.json")
            else
                notify.error("File not exist")
            end
        end
    end, "editor")
end

return M

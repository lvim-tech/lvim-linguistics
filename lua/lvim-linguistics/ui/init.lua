local utils = require("lvim-linguistics.utils")
local funcs = require("lvim-linguistics.funcs")

local M = {}

M.menu_spelling_status = function()
    if _G.LVIM_LINGUISTICS.spell.language == nil then
        vim.notify("Not defined settings for: " .. tostring(_G.LVIM_LINGUISTICS.spell.language), vim.log.levels.ERROR, {
            title = "LVIM LINGUISTICS",
        })
        return
    end
    if _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language] == nil then
        vim.notify("Not defined settings for: " .. tostring(_G.LVIM_LINGUISTICS.spell.language), vim.log.levels.ERROR, {
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

    local choices = { "Enable spelling", "Disable spelling", "Cancel" }

    vim.ui.select(choices, { prompt = "Spelling status: " .. spelling_status }, function(choice)
        if not choice then
            return
        end
        if choice == "Enable spelling" then
            funcs.enable_spelling()
            vim.notify("Spelling enabled: (" .. _G.LVIM_LINGUISTICS.spell.language .. ")", vim.log.levels.INFO, {
                title = "LVIM LINGUISTICS",
            })
        elseif choice == "Disable spelling" then
            funcs.disable_spelling()
            vim.notify("Spelling disabled", vim.log.levels.INFO, {
                title = "LVIM LINGUISTICS",
            })
        end
    end)
end

M.menu_spell_languages = function()
    local values_preview = {}
    local values_choice = {}

    for k, _ in pairs(_G.LVIM_LINGUISTICS.spell.languages) do
        local spelllang = _G.LVIM_LINGUISTICS.spell.languages[k]["spelllang"]
        if not spelllang or type(spelllang) ~= "string" then
            vim.notify("Incorrect defined spell file for: " .. k, vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
            return
        end
        local spellfile = _G.LVIM_LINGUISTICS.spell.languages[k]["spellfile"] or "global.add"
        local string_to_insert = string.upper(k)
            .. " (spelllang - "
            .. spelllang
            .. ", spellfile - "
            .. spellfile
            .. ")"
        table.insert(values_preview, string_to_insert)
        values_choice[string_to_insert] = k
    end

    table.insert(values_preview, "Cancel")

    vim.ui.select(values_preview, { prompt = "Choice language(s) for spelling" }, function(choice)
        if not choice or choice == "Cancel" then
            return
        end
        funcs.change_spell_language(values_choice[choice])
        funcs.disable_spelling()
        funcs.enable_spelling()
    end)
end

M.menu_insert_mode_status = function()
    if
        not _G.LVIM_LINGUISTICS.mode_language.normal_mode_language
        or type(_G.LVIM_LINGUISTICS.mode_language.normal_mode_language) ~= "string"
    then
        vim.notify("Not defined language for normal mode", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end
    if
        not _G.LVIM_LINGUISTICS.mode_language.insert_mode_language
        or type(_G.LVIM_LINGUISTICS.mode_language.insert_mode_language) ~= "string"
    then
        vim.notify("Not defined language for insert mode", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end

    local insert_mode_status
    if _G.LVIM_LINGUISTICS.mode_language.active == true then
        insert_mode_status = "Active (" .. _G.LVIM_LINGUISTICS.mode_language.insert_mode_language .. ")"
    else
        insert_mode_status = "Not active"
    end

    local choices = { "Enable insert mode language", "Disable insert mode language", "Cancel" }

    vim.ui.select(choices, { prompt = "Insert mode language status: " .. insert_mode_status }, function(choice)
        if not choice then
            return
        end
        if choice == "Enable insert mode language" then
            funcs.enable_insert_mode_language()
            vim.notify(
                "Insert mode language enabled: (" .. _G.LVIM_LINGUISTICS.mode_language.insert_mode_language .. ")",
                vim.log.levels.INFO,
                { title = "LVIM LINGUISTICS" }
            )
        elseif choice == "Disable insert mode language" then
            funcs.disable_insert_mode_language()
            vim.notify("Insert mode language disabled", vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
        end
    end)
end

M.menu_insert_mode_language = function()
    if
        not _G.LVIM_LINGUISTICS.mode_language.insert_mode_languages
        or type(_G.LVIM_LINGUISTICS.mode_language.insert_mode_languages) ~= "table"
    then
        vim.notify("Not defined any languages", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end

    local values_preview = {}
    local values_choice = {}
    for _, v in ipairs(_G.LVIM_LINGUISTICS.mode_language.insert_mode_languages) do
        table.insert(values_preview, string.upper(v))
        values_choice[string.upper(v)] = v
    end

    vim.ui.select(values_preview, { prompt = "Choice language for insert mode" }, function(choice)
        if not choice or choice == "Cancel" then
            return
        end
        funcs.insert_mode_language(values_choice[choice])
    end)
end

M.menu_save_current_config_as_local = function()
    local choices = { "Show current path", "Save", "Cancel" }

    vim.ui.select(choices, { prompt = "Save current config as local" }, function(choice)
        if not choice then
            return
        end
        if choice == "Show current path" then
            vim.notify(vim.inspect(vim.fn.getcwd()), vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
        elseif choice == "Save" then
            utils.write_file(vim.fn.getcwd() .. "/.lvim_linguistics.json", _G.LVIM_LINGUISTICS)
        end
    end)
end

M.menu_delete_local_config = function()
    local choices = { "Delete", "Cancel" }

    vim.ui.select(choices, { prompt = "Delete local config file" }, function(choice)
        if not choice then
            return
        end
        if choice == "Delete" then
            local file_path = vim.fn.getcwd() .. "/.lvim_linguistics.json"
            if utils.exists(file_path) then
                utils.delete_file(file_path)
            else
                vim.notify("File not exist", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
            end
        end
    end)
end

return M

-- lvim-linguistics: shared lvim-utils UI instance.
-- Lazily created on first access so that lvim-utils is not required at load time.

local funcs = require("lvim-linguistics.funcs")
local utils = require("lvim-linguistics.utils")

local _instance = nil

--- Returns the shared lvim-utils UI instance (created once via .new()).
--- Passes config/ui.lua popup_global so per-plugin overrides take effect.
--- Returns nil if lvim-utils is not available.
local function get()
    if _instance then
        return _instance
    end
    local ok, mod = pcall(require, "lvim-utils.ui")
    if not ok then
        return nil
    end
    local cfg = require("lvim-linguistics.config.ui")
    _instance = mod.new(cfg.popup_global)
    return _instance
end

local M = {}

M.open = function(tab_selector)
    local ui = get()
    if not ui then
        vim.notify("lvim-utils not available", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end

    local cfg = _G.LVIM_LINGUISTICS
    if type(cfg) ~= "table" then
        vim.notify("Plugin not initialized", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end

    local cfg_ui = require("lvim-linguistics.config.ui")
    local menus = cfg_ui.menus.main

    -- ── Spelling tab ──────────────────────────────────────────────────────────
    local spell_lang_options = vim.tbl_keys(cfg.spell.languages)
    table.sort(spell_lang_options)

    local spell_rows = {
        {
            type = "bool",
            name = "active",
            label = "Enabled",
            value = cfg.spell.active,
            run = function(val)
                if val then
                    funcs.enable_spelling()
                else
                    funcs.disable_spelling()
                end
            end,
        },
        {
            type = "select",
            name = "language",
            label = "Language",
            value = cfg.spell.language or spell_lang_options[1],
            options = spell_lang_options,
            run = function(val)
                funcs.change_spell_language(val)
            end,
        },
    }

    -- ── Insert mode tab ───────────────────────────────────────────────────────
    local insert_langs = cfg.mode_language.insert_mode_languages or {}

    local insert_rows = {
        {
            type = "bool",
            name = "active",
            label = "Enabled",
            value = cfg.mode_language.active,
            run = function(val)
                if val then
                    funcs.enable_insert_mode_language()
                else
                    funcs.disable_insert_mode_language()
                end
            end,
        },
    }

    if #insert_langs > 0 then
        table.insert(insert_rows, {
            type = "select",
            name = "insert_mode_language",
            label = "Insert Language",
            value = cfg.mode_language.insert_mode_language or insert_langs[1],
            options = insert_langs,
            run = function(val)
                funcs.insert_mode_language(val)
            end,
        })
    end

    -- ── Config tab ────────────────────────────────────────────────────────────
    local cwd = vim.fn.getcwd()
    local local_config_path = cwd .. "/.lvim_linguistics.json"

    local config_rows = {
        {
            type = "action",
            label = "Save as local config",
            run = function(_, close)
                utils.write_file(local_config_path, cfg)
                vim.notify("Config saved: " .. local_config_path, vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
                close(true, nil)
            end,
        },
        {
            type = "action",
            label = "Delete local config",
            run = function(_, close)
                if utils.exists(local_config_path) then
                    utils.delete_file(local_config_path)
                    vim.notify("Config deleted", vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
                else
                    vim.notify("No local config found", vim.log.levels.WARN, { title = "LVIM LINGUISTICS" })
                end
                close(true, nil)
            end,
        },
        { type = "spacer", label = "" }, -- a visible "──────" divider (the spacer glyph) before Show path
        {
            type = "action",
            label = "Show path",
            run = function(_, close)
                vim.notify(cwd, vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
                close(false, nil)
            end,
        },
    }

    ui.tabs({
        title = menus.title,
        tab_selector = tab_selector,
        -- MENU mode: a tab's childless action rows (the config tab's Save / Delete) stay a selectable BODY list
        -- instead of collapsing into footer buttons — which `footer_hints` (the legend) would otherwise replace.
        menu = true,
        width = cfg_ui.popup_global.width,
        footer_hints = true, -- bottom key-hint legend (panel keys • focused-row keys), like the control center
        -- add a BOTTOM edge (" ") so the content gets a closing border row below it (the frame defaults to none)
        border = { "", " ", "", " ", "", " ", "", " " },
        tabs = {
            { label = menus.tabs.spelling.label, icon = menus.tabs.spelling.icon, rows = spell_rows },
            { label = menus.tabs.insert_mode.label, icon = menus.tabs.insert_mode.icon, rows = insert_rows },
            { label = menus.tabs.config.label, icon = menus.tabs.config.icon, rows = config_rows },
        },
    })
end

return M

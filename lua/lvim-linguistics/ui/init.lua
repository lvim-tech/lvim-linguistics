-- lvim-linguistics.ui: the settings panel (lvim-ui tabbed UI).
-- Lazily creates ONE shared lvim-ui UI instance on first open (so lvim-ui is
-- not required at load time) and builds three tabs — Spelling, Insert Mode, Config —
-- from the live runtime state (state.config, NOT a global). Each row's `run` calls
-- into funcs.* so toggling/selecting in the panel drives the real feature.
--
---@module "lvim-linguistics.ui"

local funcs = require("lvim-linguistics.funcs")
local utils = require("lvim-linguistics.utils")
local state = require("lvim-linguistics.state")
local cfg_ui = require("lvim-linguistics.config.ui")

---@type table?  the shared lvim-ui UI instance (created once via .new())
local _instance = nil

--- Return the shared lvim-ui UI instance, creating it once with the config/ui.lua
--- popup_global overrides. Returns nil when lvim-ui is not installed.
---@return table? ui  The UI instance, or nil
local function get()
    if _instance then
        return _instance
    end
    local ok, mod = pcall(require, "lvim-ui")
    if not ok then
        return nil
    end
    _instance = mod.new(cfg_ui.popup_global)
    return _instance
end

local M = {}

--- Open the settings panel, optionally focused on a given tab.
---@param tab_selector? integer  1 = Spelling, 2 = Insert Mode, 3 = Config (default: first tab)
---@return nil
M.open = function(tab_selector)
    local ui = get()
    if not ui then
        vim.notify("lvim-ui not available", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end

    local cfg = state.config
    if type(cfg) ~= "table" then
        vim.notify("Plugin not initialized", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end

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
        title_pos = "center", -- centred title band, like the control center
        tab_selector = tab_selector,
        -- MENU mode: a tab's childless action rows (the config tab's Save / Delete) stay a selectable BODY list
        -- instead of collapsing into footer buttons — which `footer_hints` (the legend) would otherwise replace.
        menu = true,
        -- No explicit width: the panel follows the shared lvim-ui geometry (config.ui.size), so every band is
        -- the same width (no short title/tab band).
        footer_hints = true, -- bottom key-hint legend (panel keys • focused-row keys), like the control center
        tabs = {
            { label = menus.tabs.spelling.label, icon = menus.tabs.spelling.icon, rows = spell_rows },
            { label = menus.tabs.insert_mode.label, icon = menus.tabs.insert_mode.icon, rows = insert_rows },
            { label = menus.tabs.config.label, icon = menus.tabs.config.icon, rows = config_rows },
        },
    })
end

return M

-- lvim-linguistics.panel: the settings panel, hosted by lvim-control-center.
--
-- Instead of a bespoke float, the settings run as a DEDICATED lvim-control-center instance with
-- its OWN command and its OWN database (both configurable via `config.settings_panel`). Three
-- tabs, built from the static `config.base_config` catalogue (so building the groups needs no
-- runtime state):
--   • Spelling    — Enabled (bool), Language (select).
--   • Insert Mode — Enabled (bool), Insert Language (select, only when layouts are configured).
--   • Config      — actions: Save / Delete the project-local override, Show path.
--
-- Each value row applies live through `funcs.*` AND persists the GLOBAL default to the instance
-- database (`store.save`). The startup restore is owned by `funcs.get_config` + `funcs.process`
-- (base → global overlay → project override, one pass), so every value row carries
-- `break_load = true` — the host must NOT re-apply them before `state.config` exists.
--
---@module "lvim-linguistics.panel"

local funcs = require("lvim-linguistics.funcs")
local utils = require("lvim-linguistics.utils")
local state = require("lvim-linguistics.state")
local store = require("lvim-linguistics.store")
local config = require("lvim-linguistics.config")

local M = {}

---@type LvimControlCenterInstance? the dedicated control-center instance (created once)
M.instance = nil

--- Build the control-center groups. Options come from the STATIC base_config catalogue, so this
--- needs no populated runtime state; get/set read/write `state.config` live at call time.
---@return LvimControlCenterGroup[]
local function build_groups()
    local base = config.base_config
    local spell_langs = vim.tbl_keys(base.spell.languages)
    table.sort(spell_langs)
    local insert_langs = base.mode_language.insert_mode_languages or {}

    -- ── Spelling ──────────────────────────────────────────────────────────────
    local spelling = {
        name = "Spelling",
        label = "Spelling",
        icon = "󰓆",
        settings = {
            {
                name = "spell_active",
                type = "bool",
                label = "Enabled",
                break_load = true,
                get = function()
                    return state.config and state.config.spell.active == true
                end,
                set = function(val, is_load)
                    if val then
                        funcs.enable_spelling()
                    else
                        funcs.disable_spelling()
                    end
                    if not is_load then
                        store.save("spell_active", val == true)
                    end
                end,
            },
            {
                name = "spell_language",
                type = "select",
                label = "Language",
                options = spell_langs,
                break_load = true,
                get = function()
                    return state.config and (state.config.spell.language or spell_langs[1])
                end,
                set = function(val, is_load)
                    funcs.change_spell_language(val)
                    if not is_load then
                        store.save("spell_language", val)
                    end
                end,
            },
        },
    }

    -- ── Insert Mode ─────────────────────────────────────────────────────────────
    local insert_settings = {
        {
            name = "mode_active",
            type = "bool",
            label = "Enabled",
            break_load = true,
            get = function()
                return state.config and state.config.mode_language.active == true
            end,
            set = function(val, is_load)
                if val then
                    funcs.enable_insert_mode_language()
                else
                    funcs.disable_insert_mode_language()
                end
                if not is_load then
                    store.save("mode_active", val == true)
                end
            end,
        },
    }
    if #insert_langs > 0 then
        insert_settings[#insert_settings + 1] = {
            name = "insert_mode_language",
            type = "select",
            label = "Insert Language",
            options = insert_langs,
            break_load = true,
            get = function()
                return state.config and (state.config.mode_language.insert_mode_language or insert_langs[1])
            end,
            set = function(val, is_load)
                funcs.insert_mode_language(val)
                if not is_load then
                    store.save("insert_mode_language", val)
                end
            end,
        }
    end
    local insert_mode = { name = "Insert Mode", label = "Insert Mode", icon = "󰌌", settings = insert_settings }

    -- ── Config (project-local override actions) ──────────────────────────────────
    local config_tab = {
        name = "Config",
        label = "Config",
        icon = "󰒓",
        settings = {
            {
                name = "save_local",
                type = "action",
                label = "Save as local config",
                run = function()
                    utils.create_dir(utils.project_dir())
                    local path = utils.project_config_path()
                    utils.write_file(path, state.config)
                    vim.notify("Config saved: " .. path, vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
                end,
            },
            {
                name = "delete_local",
                type = "action",
                label = "Delete local config",
                run = function()
                    local path = utils.project_config_path()
                    if utils.exists(path) then
                        utils.delete_file(path)
                        vim.notify("Config deleted", vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
                    else
                        vim.notify("No local config found", vim.log.levels.WARN, { title = "LVIM LINGUISTICS" })
                    end
                end,
            },
            { name = "config_sep", type = "spacer", label = "" },
            {
                name = "show_path",
                type = "action",
                label = "Show path",
                run = function()
                    vim.notify(utils.project_config_path(), vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
                end,
            },
        },
    }

    return { spelling, insert_mode, config_tab }
end

--- Create the dedicated control-center instance (once) and bind the global store to its
--- database. Call in setup() BEFORE funcs.get_config so the overlay can read it. Returns the
--- instance, or nil when lvim-control-center is unavailable.
---@return LvimControlCenterInstance|nil
function M.setup()
    if M.instance then
        return M.instance
    end
    local ok, cc = pcall(require, "lvim-control-center")
    if not ok then
        vim.notify(
            "lvim-linguistics: the settings panel requires lvim-control-center",
            vim.log.levels.WARN,
            { title = "LVIM LINGUISTICS" }
        )
        return nil
    end
    local p = config.settings_panel or {}
    M.instance = cc.new({
        -- control-center REGISTERS the command (the plugin no longer makes one) — so `:LvimLinguistics`
        -- comes with the full control-center command: open [tab] / export / import / reset / preset / search.
        command = p.command or "LvimLinguistics",
        -- Plus the plugin's quick toggles, as host subcommands on the SAME command (no second command):
        --   :LvimLinguistics toggle-spelling      :LvimLinguistics toggle-insert-mode
        subcommands = {
            ["toggle-spelling"] = function()
                funcs.toggle_spelling()
            end,
            ["toggle-insert-mode"] = function()
                funcs.toggle_insert_mode_language()
            end,
        },
        save = p.save or (vim.fn.stdpath("data") .. "/lvim-linguistics"),
        title = "LVIM LINGUISTICS",
        title_icon = "󰊷",
        groups = build_groups(),
    })
    store.bind(M.instance.data)
    return M.instance
end

--- Open the settings panel, optionally focused on a tab (1 = Spelling, 2 = Insert Mode, 3 = Config).
---@param tab? integer
function M.open(tab)
    local inst = M.instance or M.setup()
    if inst then
        inst:open(tab)
    end
end

return M

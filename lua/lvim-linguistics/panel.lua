-- lvim-linguistics.panel: the settings panel — two LAYER tabs, built directly on lvim-ui.
--
-- It used to run as a dedicated lvim-control-center instance. That host models exactly ONE value per
-- name — a global editor setting — and half of this plugin's settings are directory-scoped, which it
-- has no way to express. So the panel talks to `lvim-ui.tabs` directly (the canonical tabbed-form
-- preset, §1 of the panel canon) and reaches BOTH layers through `store`:
--
--   Global          the editor-wide preferences, persisted in the control center's database (the
--                   same values its own Linguistics group edits — one store, two ways in).
--   This directory  `.lvim/linguistics/config.json`, a document that overrides them here.
--
-- The model, in one line: EDIT = now, SAVE = forever.
--   • Changing a row applies through `funcs.*` at once and writes NOTHING: close Neovim and it is
--     gone. That is the same "just for this session" behaviour as the `toggle-*` subcommands.
--   • `Save permanently` stores the tab's values in that tab's layer (the local tab reads
--     `Rewrite this directory's settings` once the document exists).
--   • `Delete this directory's settings` removes it again, and is inert while there is none.
--
-- While this directory has no document, the two tabs are the same thing, so the local tab MIRRORS the
-- global tab's live rows — otherwise an unsaved global edit would leave them contradicting each other
-- over a setting only one of them can have.
--
-- The startup restore is owned by `funcs.get_config` + `funcs.process` (base → global → local, one
-- pass), so opening the panel never re-applies anything by itself.
--
---@module "lvim-linguistics.panel"

local ui = require("lvim-ui")
local funcs = require("lvim-linguistics.funcs")
local store = require("lvim-linguistics.store")
local config = require("lvim-linguistics.config")

local M = {}

--- The panel's title.
local TITLE = "LVIM LINGUISTICS"

--- Read one setting out of a layer document (nil when it does not carry the key).
---@param cfg table?
---@param key string  a key of `store.FIELDS`
---@return any
local function at(cfg, key)
    local path = store.FIELDS[key]
    local section = cfg and path and cfg[path[1]]
    if type(section) ~= "table" then
        return nil
    end
    -- An explicit return, NOT `… and section[k] or nil`: every setting here can legitimately BE
    -- `false`, and that idiom collapses a stored `false` to nil — which reads as "this layer says
    -- nothing", so the layer beneath wins and a saved "off" comes back on.
    return section[path[2]]
end

--- Write one setting into a layer document, creating the section it belongs to.
---@param cfg table
---@param key string
---@param value any
---@return nil
local function put(cfg, key, value)
    local path = store.FIELDS[key]
    if not path then
        return
    end
    cfg[path[1]] = type(cfg[path[1]]) == "table" and cfg[path[1]] or {}
    cfg[path[1]][path[2]] = value
end

--- The catalogue the rows are built from: the defaults, plus the two option lists.
---@return LvimLinguisticsBaseConfig base, string[] spell_langs, string[] insert_langs
local function catalogue()
    local base = config.base_config
    local spell_langs = vim.tbl_keys(base.spell.languages or {})
    table.sort(spell_langs)
    return base, spell_langs, base.mode_language.insert_mode_languages or {}
end

--- Apply one setting to the RUNNING editor. Nothing is written — the session half of the model.
---@param key string
---@param value any
---@return nil
local function apply(key, value)
    if key == "spell_language" then
        funcs.change_spell_language(value)
    elseif key == "insert_mode_language" then
        funcs.insert_mode_language(value)
    elseif key == "spell_active" then
        if value then
            funcs.enable_spelling()
        else
            funcs.disable_spelling()
        end
    elseif key == "mode_active" then
        if value then
            funcs.enable_insert_mode_language()
        else
            funcs.disable_insert_mode_language()
        end
    end
end

--- Build one layer's tab. The rows are plain tables owned HERE: lvim-ui edits each typed row's
--- `value` in place, so reading them back is reading what the user set — no shadow copy to sync.
---@param layer LvimLinguisticsLayer
---@param panel table  the shared box: the live handle, each tab's re-seed, each tab's values
---@return table tab
local function layer_tab(layer, panel)
    local base, spell_langs, insert_langs = catalogue()
    ---@type table? the local document (the global layer is not a document — see store)
    local stored = layer == "local" and store.read_local() or nil

    --- What this tab shows for `key`: its own layer, then the layer beneath it, then the plugin
    --- default. While the local layer has NO document, "this directory" and "global" are the same
    --- thing, so the local tab reads the global tab's LIVE rows rather than what was last stored.
    ---@param key string
    ---@param fallback any
    ---@return any
    local function seed(key, fallback)
        local v
        if layer == "local" then
            v = at(stored, key)
            if v == nil then
                local live = not store.has_local() and panel.values.global
                v = live and live()[key] or store.get_global(key)
            end
        else
            v = store.get_global(key)
        end
        if v ~= nil then
            return v
        end
        return fallback
    end

    ---@type Row[]
    local rows = {
        {
            type = "bool",
            name = layer .. ":spell_active",
            label = "Spelling",
            value = seed("spell_active", base.spell.active == true) == true,
        },
        {
            type = "select",
            name = layer .. ":spell_language",
            label = "Spell language",
            options = spell_langs,
            value = seed("spell_language", base.spell.language or spell_langs[1]),
        },
        {
            type = "bool",
            name = layer .. ":mode_active",
            label = "Insert-mode layout",
            value = seed("mode_active", base.mode_language.active == true) == true,
        },
    }
    if #insert_langs > 0 then
        rows[#rows + 1] = {
            type = "select",
            name = layer .. ":insert_mode_language",
            label = "Insert language",
            options = insert_langs,
            value = seed("insert_mode_language", base.mode_language.insert_mode_language or insert_langs[1]),
        }
    end

    --- The tab's current values, keyed by setting. Published on `panel.values` so the tab BELOW in
    --- the layering can mirror it live (see `seed`).
    ---@return table<string, any>
    local function values()
        local v = {}
        for _, r in ipairs(rows) do
            local key = r.name and r.name:match("^.-:(.+)$")
            if key then
                v[key] = r.value
            end
        end
        return v
    end
    panel.values[layer] = values

    --- Re-seed this tab's rows from what its layers now hold.
    ---@return nil
    local function reload()
        stored = layer == "local" and store.read_local() or nil
        for _, r in ipairs(rows) do
            local key = r.name and r.name:match("^.-:(.+)$")
            if key then
                local fallback
                if key == "spell_language" then
                    fallback = base.spell.language or spell_langs[1]
                elseif key == "insert_mode_language" then
                    fallback = base.mode_language.insert_mode_language or insert_langs[1]
                elseif key == "spell_active" then
                    fallback = base.spell.active == true
                else
                    fallback = base.mode_language.active == true
                end
                r.value = seed(key, fallback)
            end
        end
    end
    panel.reloads[layer] = reload

    --- Re-seed the named tab (all of them when none is named) and repaint the visible one. Per layer
    --- on purpose: a tab whose rows the user is editing must NOT be pulled back under them — only the
    --- tabs that MIRROR what just changed are refreshed.
    ---@param only? LvimLinguisticsLayer
    ---@return nil
    local function reload_tabs(only)
        for name, fn in pairs(panel.reloads) do
            if not only or name == only then
                fn()
            end
        end
        if panel.handle and panel.handle.render then
            panel.handle.render()
        end
    end
    panel.reload_tabs = reload_tabs

    rows[#rows + 1] = { type = "spacer_line", name = layer .. "_gap" }
    rows[#rows + 1] = {
        type = "action",
        name = layer .. "_save",
        -- The global store is a fact of the install, so its wording never changes. The local document
        -- may not exist yet, and creating it is a different act from overwriting it — the label says
        -- which of the two this will do, re-read on every render so it follows the Delete row below.
        label = layer == "local" and function()
            return store.has_local() and "Rewrite this directory's settings" or "Save permanently"
        end or "Save permanently",
        run = function()
            if layer == "global" then
                if not store.can_save_global() then
                    vim.notify(
                        "No store for the global settings — add the linguistics group to your control center",
                        vim.log.levels.WARN,
                        { title = TITLE }
                    )
                    return
                end
                for key, value in pairs(values()) do
                    store.save_global(key, value)
                end
                reload_tabs()
                vim.notify(
                    store.has_local() and "Saved as the global default — this directory keeps its own settings"
                        or "Saved as the global default",
                    vim.log.levels.INFO,
                    { title = TITLE }
                )
                return
            end
            -- CREATING the document seeds it from everything that applies here right now (see
            -- `store.seed`), so a project's first local file is a complete, editable copy of what it
            -- inherits — including the gating lists, which the panel does not surface — rather than a
            -- stub of the four fields it does.
            -- EDITING it only patches those four: a hand-written key belongs to the user, and a save
            -- from here must not overwrite it with whatever the global layer says now.
            local cfg = store.has_local() and (store.read_local() or {}) or store.seed()
            for key, value in pairs(values()) do
                put(cfg, key, value)
            end
            local path = store.write_local(cfg)
            reload_tabs()
            funcs.get_config()
            funcs.process()
            vim.notify("Saved: " .. path, vim.log.levels.INFO, { title = TITLE })
        end,
    }
    if layer == "local" then
        -- Removing the document is the only way back to "this directory follows the global settings",
        -- so it belongs beside the action that creates it. Kept VISIBLE but inert while there is none
        -- — a row that vanishes and reappears makes the two states harder to tell apart, not easier.
        rows[#rows + 1] = {
            type = "action",
            name = "local_delete",
            label = "Delete this directory's settings",
            disabled = function()
                return not store.has_local()
            end,
            run = function()
                local path = store.remove_local()
                if not path then
                    return
                end
                funcs.get_config()
                funcs.process()
                reload_tabs()
                vim.notify(
                    "Deleted: " .. path .. "\nThe global settings apply here again",
                    vim.log.levels.INFO,
                    { title = TITLE }
                )
            end,
        }
    end

    return {
        name = layer,
        label = layer == "local" and "This directory" or "Global",
        icon = layer == "local" and "󰉋" or "󰇧",
        rows = rows,
        -- Keep the action rows in the BODY, under the fields they act on. By default `ui.tabs` lifts a
        -- form's childless action rows into a footer band — which `footer_hints = true` then outranks,
        -- so they would render nowhere at all.
        menu = true,
    }
end

--- Open the settings panel.
---@param tab? string|integer  the tab to focus — "global" / "local", or an index
---@param layout? string       "float" (default) | "area" | "bottom"; overrides `settings_panel.layout`
---@return nil
function M.open(tab, layout)
    local p = config.settings_panel or {}
    -- One box shared by both tabs: the handle they are built for (so an action can repaint it), each
    -- tab's re-seed, and each tab's live values (so the tab below can mirror the one above).
    local panel = { reloads = {}, values = {} }
    panel.handle = ui.tabs({
        title = TITLE,
        title_pos = "center",
        layout = layout or p.layout or "float",
        tabs = { layer_tab("global", panel), layer_tab("local", panel) },
        tab_selector = tab,
        footer_hints = true,
        --- A typed row was edited: apply it to the running editor and write nothing. The row name
        --- carries its layer, but applying is layer-agnostic — there is one editor, and which layer a
        --- value came from only matters when it is SAVED.
        ---@param row table
        on_change = function(row)
            local layer, key = tostring(row.name or ""):match("^(.-):(.+)$")
            if not key then
                return
            end
            if layer == "global" then
                -- Record it as the session's global value, so the fold (and the local tab, while this
                -- directory has no document) sees the same thing the row now shows.
                store.set_global(key, row.value)
                if not store.has_local() and panel.reload_tabs then
                    panel.reload_tabs("local")
                end
            else
                apply(key, row.value)
            end
        end,
    })
end

return M

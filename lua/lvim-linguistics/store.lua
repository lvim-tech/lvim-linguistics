-- lvim-linguistics.store: the two settings LAYERS — global and project-local.
--
-- The layers are the same settings at two reaches, and they are kept where each BELONGS:
--
--   global  →  the control center's database, through its own settings group. These are editor-wide
--              preferences ("spelling on, English"), which is what that panel and that database are
--              for; the plugin holds the delivered values in memory (`M.global`) and never opens the
--              database itself — control-center's bulk restore hands them over at startup and its
--              rows hand over every later edit.
--   local   →  `<cwd>/.lvim/linguistics/config.json`, this directory only — and it WINS. A
--              directory-scoped override cannot live in a global key/value store, so it stays a
--              document, written through `lvim-utils.store` (the json backend): atomic writes, plus
--              `watch`, so a second Neovim editing the same project is picked up and re-applied.
--
-- `funcs.get_config` folds them in that order over `config.base_config`.
--
---@module "lvim-linguistics.store"

local ustore = require("lvim-utils.store")
local utils = require("lvim-linguistics.utils")

local M = {}

---@alias LvimLinguisticsLayer "global"|"local"

--- The GLOBAL layer, as delivered by the control center: flat setting keys, no file of its own here.
--- Persisting them is the host panel's job (its rows write to its database); this is the live copy
--- the engine layers over the defaults.
---@type table<string, any>
M.global = {}

--- Each global setting → its path inside the effective config. The panel rows and the control-center
--- group are flat (`spell_active`); the config is nested (`spell.active`).
---@type table<string, string[]>
M.FIELDS = {
    spell_active = { "spell", "active" },
    spell_language = { "spell", "language" },
    mode_active = { "mode_language", "active" },
    insert_mode_language = { "mode_language", "insert_mode_language" },
}

--- How a global setting is PERSISTED, when a host has offered a store for it (the control center
--- binds its database here). Unbound, the global layer is session-only — the plugin never opens a
--- database of its own, because the whole point of putting these settings in the control center is
--- that there is one place they live.
---@type fun(key: string, value: any)|nil
local saver = nil

--- Bind the global layer's persistence. Idempotent by design: the binder is a lookup closure, so
--- rebinding it costs nothing and the host can call this from wherever it first has a store.
---@param fn fun(key: string, value: any)
---@return nil
function M.bind_global(fn)
    saver = fn
end

--- Whether the global layer has somewhere to persist to.
---@return boolean
function M.can_save_global()
    return saver ~= nil
end

--- Read one global setting (nil when it has never been set).
---@param key string
---@return any
function M.get_global(key)
    return M.global[key]
end

--- Record one global setting and re-derive the effective config from it.
---
--- Re-deriving rather than applying: the local layer still wins, so a global change must go through
--- the same fold every other path uses instead of being pushed at the editor directly. Skipped while
--- `state.config` is nil — the plugin has not been set up yet, and its own `get_config` will read
--- this table when it runs, so both load orders (control-center first or plugin first) settle the
--- same way.
---@param key string
---@param value any
---@return nil
function M.set_global(key, value)
    M.global[key] = value
    local ok_state, state = pcall(require, "lvim-linguistics.state")
    if not (ok_state and type(state.config) == "table") then
        return
    end
    -- Inline require: the engine requires this module, so a hoisted one would close the cycle.
    local ok, funcs = pcall(require, "lvim-linguistics.funcs")
    if ok then
        funcs.get_config()
        funcs.process()
    end
end

--- Record a global setting AND persist it, when a host has bound a store. This is the "permanently"
--- half of the panel's model; `set_global` alone is the session half.
---@param key string
---@param value any
---@return boolean saved  false when nothing is bound to persist to
function M.save_global(key, value)
    M.set_global(key, value)
    if not saver then
        return false
    end
    local ok = pcall(saver, key, value)
    return ok
end

--- The global layer as a partial `base_config` overlay — the shape the fold consumes.
---@return table
function M.global_config()
    local cfg = {}
    for key, path in pairs(M.FIELDS) do
        local v = M.global[key]
        if v ~= nil then
            cfg[path[1]] = type(cfg[path[1]]) == "table" and cfg[path[1]] or {}
            cfg[path[1]][path[2]] = v
        end
    end
    return cfg
end

-- ─── the project-local document ───────────────────────────────────────────────

--- Open store handles, keyed by the path they back. The local path follows the cwd, so a DirChanged
--- lands on a DIFFERENT key — the stale handle is closed rather than left watching a directory
--- nobody is in any more.
---@type table<string, table>
local handles = {}
---@type string? the path the live local handle was opened for
local opened_at = nil

--- The project-local document for the current directory.
---@return string path
function M.path()
    return utils.project_config_path()
end

--- Re-apply the effective config after ANOTHER process changed the document on disk.
---@return nil
local function reapply()
    local ok, funcs = pcall(require, "lvim-linguistics.funcs")
    if ok then
        funcs.get_config()
        funcs.process()
    end
end

--- The live store handle for the project-local document, opened on first use. Opening READS but
--- never creates, so merely looking at the layer cannot conjure a `.lvim/` into a project.
---@return table
local function handle()
    local path = M.path()
    if opened_at and opened_at ~= path then
        local stale = handles[opened_at]
        if stale then
            pcall(function()
                stale:close()
            end)
            handles[opened_at] = nil
        end
    end
    opened_at = path
    if not handles[path] then
        handles[path] = ustore.new({ backend = "json", path = path, watch = true, on_change = reapply })
    end
    return handles[path]
end

--- Whether this directory has settings of its own. A filesystem fact, deliberately: an OPEN store
--- with nothing in it is indistinguishable from one that was never written, and that is exactly the
--- difference this answers.
---@return boolean
function M.has_local()
    return utils.exists(M.path())
end

--- Read the project-local document, or nil when this directory has none.
---@return table?
function M.read_local()
    if not M.has_local() then
        return nil
    end
    local all = handle():reload()
    return next(all) and all or nil
end

--- Keys a seeded document must NOT freeze. `languages` and `insert_mode_languages` are CATALOGUES —
--- what the install offers to choose from — not choices about this directory. Copied into a project
--- file they would pin it to the catalogue as it stood the day the file was created, so a language
--- added to `setup()` later would never reach it.
---@type table<string, boolean>
local SEED_SKIP = {
    languages = true,
    insert_mode_languages = true,
}

--- The starting content for a document this directory does not have yet: the settings in force here
--- right now — the defaults, `setup()`'s overrides and the global layer, already folded into
--- `state.config` — minus the catalogues above.
--- This is what makes a new local file a complete, EDITABLE copy of what the project inherits (the
--- gating lists included) instead of a stub of the fields the panel surfaces. Every later save
--- patches that document, so whatever is hand-written in it stays.
---@return table  a partial base_config overlay
function M.seed()
    local ok, state = pcall(require, "lvim-linguistics.state")
    local src = (ok and type(state.config) == "table") and state.config or {}
    local out = {}
    for section, values in pairs(src) do
        if type(values) == "table" then
            local copy = {}
            for key, value in pairs(values) do
                if not SEED_SKIP[key] then
                    copy[key] = vim.deepcopy(value)
                end
            end
            out[section] = copy
        end
    end
    return out
end

--- Write the project-local document — every top-level section of `cfg`, so a key the panel does not
--- surface (a hand-written `file_types`, say) survives as long as the caller passes what it read.
---@param cfg table  a partial base_config overlay
---@return string path
function M.write_local(cfg)
    local h = handle()
    for key, value in pairs(cfg) do
        h[key] = value
    end
    return M.path()
end

--- Remove the project-local document, closing its handle (its watcher would otherwise keep firing on
--- a file that is gone, and a later write must start from a clean cache).
---@return string? path  nil when there was nothing to remove
function M.remove_local()
    local path = M.path()
    if not utils.exists(path) then
        return nil
    end
    local h = handles[path]
    if h then
        pcall(function()
            h:close()
        end)
        handles[path] = nil
        opened_at = nil
    end
    utils.delete_file(path)
    return path
end

--- Which layer currently DECIDES here.
---@return LvimLinguisticsLayer
function M.scope()
    return M.has_local() and "local" or "global"
end

return M

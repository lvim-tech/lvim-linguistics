-- lvim-linguistics.health: :checkhealth lvim-linguistics
-- Reports the Neovim version, the lvim-utils + lvim-ui dependencies, the two settings layers and
-- which one is in effect here, the keyboard-switch tool for the current session, the spell-file
-- folder + curl (used to download dictionaries), and the loaded runtime state.
--
---@module "lvim-linguistics.health"

local config = require("lvim-linguistics.config")
local state = require("lvim-linguistics.state")
local store = require("lvim-linguistics.store")

local M = {}

--- :checkhealth entry point.
---@return nil
function M.check()
    local health = vim.health
    health.start("lvim-linguistics")

    if vim.fn.has("nvim-0.10") == 1 then
        health.ok("Neovim >= 0.10")
    else
        health.error("Neovim >= 0.10 is required (vim.uv, vim.health)")
    end

    -- lvim-utils (palette + merge) — hard dependency, degrades gracefully when absent.
    local ok_utils = pcall(require, "lvim-utils.utils")
    local ok_colors, colors = pcall(require, "lvim-utils.colors")
    if ok_utils and ok_colors and type(colors.blend) == "function" then
        health.ok("lvim-utils found (palette + merge)")
    else
        health.warn("lvim-utils not found — highlights are unavailable")
    end

    -- lvim-ui renders the project-local settings panel (the canonical tabbed-form preset). Absent →
    -- the panel can't open, though spelling / insert-mode switching still work.
    local p = config.settings_panel or {}
    if pcall(require, "lvim-ui") then
        health.ok(("settings panel available (:%s)"):format(p.command or "LvimLinguistics"))
    else
        health.error("lvim-ui not found — the :LvimLinguistics settings panel is unavailable")
    end

    -- The two layers: the global one is delivered by the control center's settings group (so an empty
    -- one means either nothing stored or no group registered), the local one is this project's file.
    local globals = {}
    for key in pairs(store.FIELDS) do
        if store.get_global(key) ~= nil then
            globals[#globals + 1] = key
        end
    end
    if #globals > 0 then
        table.sort(globals)
        health.ok("global settings (from the control center): " .. table.concat(globals, ", "))
    else
        health.info("global settings: none — add the linguistics group to your control center to store them")
    end
    if store.has_local() then
        health.ok("this directory's settings: " .. store.path())
    else
        health.info("this directory's settings: none (" .. store.path() .. ")")
    end
    health.info(("in effect here: the %s settings"):format(store.scope()))

    -- Keyboard-layout switch tool for the current session.
    local cmd = config.plugin_config.kbrd_cmd
    local desktop = ((os.getenv("XDG_CURRENT_DESKTOP") or "") .. " " .. (os.getenv("DESKTOP_SESSION") or "")):lower()
    if desktop:find("gnome") then
        health.warn(
            "GNOME session: layout switching goes through org.gnome.Shell.Eval, which GNOME Shell >= 41 "
                .. "disables by default — enable it (or set a custom kbrd_cmd) if insert-mode switching does nothing"
        )
    end
    if type(cmd) == "function" then
        health.info("kbrd_cmd is a function (custom layout switching)")
    else
        local exe = tostring(cmd):match("^%s*(%S+)")
        if not exe then
            health.warn("kbrd_cmd has no runnable command")
        elseif vim.fn.executable(exe) == 1 then
            health.ok("keyboard switch tool found: " .. exe)
        else
            health.warn("keyboard switch tool not on PATH: " .. exe .. " — insert-mode switching will not work")
        end
    end

    -- Spell-file folder (created on setup) and curl (dictionary/spell-file downloads).
    local folder = config.plugin_config.spell_files_folder
    if vim.fn.isdirectory(folder) == 1 then
        health.ok("spell files folder: " .. folder)
    else
        health.info("spell files folder does not exist yet (created on setup): " .. folder)
    end

    if vim.fn.executable("curl") == 1 then
        health.ok("curl found (dictionary downloads)")
    else
        health.warn("curl not found — spell files cannot be downloaded automatically")
    end

    -- Runtime state (loaded by setup()/DirChanged).
    if type(state.config) == "table" then
        local spell = state.config.spell or {}
        local mode = state.config.mode_language or {}
        health.info(
            ("state loaded — spell: %s (%s), insert-mode switch: %s"):format(
                tostring(spell.active),
                tostring(spell.language),
                tostring(mode.active)
            )
        )
    else
        health.warn("runtime state not loaded — was setup() called?")
    end
end

return M

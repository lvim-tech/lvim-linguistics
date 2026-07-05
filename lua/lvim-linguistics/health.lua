-- lvim-linguistics.health: :checkhealth lvim-linguistics
-- Reports the Neovim version, the lvim-utils + lvim-ui dependencies, the keyboard-switch tool for
-- the current session, the spell-file folder + curl (used to download dictionaries),
-- and the loaded runtime state.
--
---@module "lvim-linguistics.health"

local config = require("lvim-linguistics.config")
local state = require("lvim-linguistics.state")

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

    -- lvim-ui — the settings panel's tabbed UI (new/tabs). Absent → :LvimLinguistics panel can't open.
    if pcall(require, "lvim-ui") then
        health.ok("lvim-ui found (settings panel)")
    else
        health.warn("lvim-ui not found — the settings panel is unavailable")
    end

    -- Keyboard-layout switch tool for the current session.
    local cmd = config.plugin_config.kbrd_cmd
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

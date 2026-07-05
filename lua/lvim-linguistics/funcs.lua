-- lvim-linguistics.funcs: the runtime engine — loading the per-cwd state, toggling the two
-- features, and the autocmds that drive them.
--   • Insert-mode layout switching: on InsertEnter set the insert layout, on InsertLeave
--     restore the normal layout, gated by the filetype allow-list.
--   • Spelling: ensure the dictionary is on disk (download on demand), then 'setlocal spell'
--     on the allowed buffers via WinEnter/BufEnter.
-- The active values live in state.config (config.lua holds only the DEFAULTS); filetype
-- gating honours BOTH file_types.black_list (never) and file_types.white_list (only these).
--
---@module "lvim-linguistics.funcs"

local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local state = require("lvim-linguistics.state")
local store = require("lvim-linguistics.store")

---@type integer  augroup for the InsertEnter/InsertLeave layout switch
local group_change_mode = vim.api.nvim_create_augroup("LvimLinguisticsChangeMode", { clear = true })
---@type integer  augroup for the WinEnter/BufEnter spell-enable
local group_spell_enabled = vim.api.nvim_create_augroup("LvimLinguisticsSpellEnabled", { clear = true })
---@type integer  augroup for the WinEnter spell-disable
local group_spell_disabled = vim.api.nvim_create_augroup("LvimLinguisticsSpellDisabled", { clear = true })

local M = {}

--- Whether a feature may engage in `ft`, per its filetype gating: excluded when in
--- `black_list`; when `white_list` is non-empty, allowed ONLY if `ft` is in it.
---@param file_types LvimLinguisticsFileTypes  The feature's file_types block
---@param ft string                            The buffer filetype to test
---@return boolean allowed
local function is_ft_allowed(file_types, ft)
    if vim.tbl_contains(file_types.black_list or {}, ft) then
        return false
    end
    local white = file_types.white_list or {}
    if #white > 0 then
        return vim.tbl_contains(white, ft)
    end
    return true
end

--- Ensure the spell-file folder exists (create it if missing).
---@return nil
M.check_dir = function()
    if not utils.exists(config.plugin_config.spell_files_folder) then
        utils.create_dir(config.plugin_config.spell_files_folder)
    end
end

--- Load the runtime state for the current cwd, in three layers (later wins):
---   1. `config.base_config` — the defaults;
---   2. the GLOBAL panel settings from the control-center database (via `store`), overlaid;
---   3. a project-local `.lvim_linguistics.json`, which OVERRIDES entirely when present.
--- Stored in state.config.
---@return nil
M.get_config = function()
    local cfg = vim.deepcopy(config.base_config)

    -- Layer 2 — the global default from the panel's database (nil / unbound = left as base).
    local function overlay(key, apply)
        local v = store.load(key)
        if v ~= nil then
            apply(v)
        end
    end
    overlay("spell_active", function(v)
        cfg.spell.active = v == true
    end)
    overlay("spell_language", function(v)
        cfg.spell.language = v
    end)
    overlay("mode_active", function(v)
        cfg.mode_language.active = v == true
    end)
    overlay("insert_mode_language", function(v)
        cfg.mode_language.insert_mode_language = v
    end)

    -- Layer 3 — a project-local override wins entirely (a whole-state snapshot).
    local local_config = utils.read_file(vim.fn.getcwd() .. "/.lvim_linguistics.json")
    if local_config then
        cfg = local_config
    end

    state.config = cfg
end

--- Set the layout used in Insert mode (runtime state only; does not switch immediately).
---@param language string  Layout id
---@return nil
M.insert_mode_language = function(language)
    state.config.mode_language.insert_mode_language = language
end

--- Enable insert-mode layout switching: install InsertEnter/InsertLeave autocmds that flip
--- the OS keyboard layout via plugin_config.kbrd_cmd, gated by the filetype allow-list.
---@return nil
M.enable_insert_mode_language = function()
    local cfg = state.config.mode_language
    if type(cfg.normal_mode_language) ~= "string" or type(cfg.insert_mode_language) ~= "string" then
        vim.notify("Invalid insert/normal mode language definitions", vim.log.levels.ERROR, {
            title = "LVIM LINGUISTICS",
        })
        return
    end
    cfg.active = true
    --- Run the configured switch command for `lang` (string prefix or function), silenced.
    ---@param lang string  Layout id
    ---@return nil
    local function set_kbrd(lang)
        pcall(function()
            local cmd = config.plugin_config.kbrd_cmd
            local full_cmd
            if type(cmd) == "function" then
                full_cmd = cmd(lang)
            else
                full_cmd = cmd .. lang
            end
            os.execute(full_cmd .. " > /dev/null 2>&1")
        end)
    end
    vim.api.nvim_create_autocmd("InsertEnter", {
        pattern = "*",
        callback = function()
            if is_ft_allowed(cfg.file_types, vim.bo.filetype) then
                set_kbrd(cfg.insert_mode_language)
            end
        end,
        group = group_change_mode,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        pattern = "*",
        callback = function()
            if is_ft_allowed(cfg.file_types, vim.bo.filetype) then
                set_kbrd(cfg.normal_mode_language)
            end
        end,
        group = group_change_mode,
    })
end

--- Disable insert-mode layout switching: clear its autocmds and flip the state flag.
---@return nil
M.disable_insert_mode_language = function()
    state.config.mode_language.active = false
    pcall(function()
        for _, ac in ipairs(vim.api.nvim_get_autocmds({ group = group_change_mode })) do
            vim.api.nvim_del_autocmd(ac.id)
        end
    end)
end

--- Toggle insert-mode layout switching on/off (with a notification).
---@return nil
M.toggle_insert_mode_language = function()
    if state.config.mode_language.active then
        M.disable_insert_mode_language()
        vim.notify("Insert mode language disabled", vim.log.levels.INFO)
    else
        M.enable_insert_mode_language()
        vim.notify("Insert mode language enabled", vim.log.levels.INFO)
    end
end

--- Ensure a dictionary .spl is on disk, downloading it (async) from the Vim FTP mirror when
--- absent, then run `on_ready`. If it is already present, `on_ready` runs immediately.
---@param lang_code string      'spelllang' value used to build the download URL/filename
---@param target_path string    Absolute path the .spl should live at
---@param on_ready? fun():nil   Called once the dictionary is available
---@return nil
local function ensure_dictionary(lang_code, target_path, on_ready)
    if vim.fn.filereadable(target_path) == 1 then
        if on_ready then
            on_ready()
        end
        return
    end
    local url = string.format("https://ftp.nluug.nl/vim/runtime/spell/%s.utf-8.spl", lang_code)
    vim.notify("Downloading dictionary: " .. lang_code, vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
    vim.fn.jobstart({ "curl", "-fsSL", url, "-o", target_path }, {
        on_exit = function(_, code)
            vim.schedule(function()
                if code == 0 then
                    vim.notify("Dictionary ready: " .. lang_code, vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
                    if on_ready then
                        on_ready()
                    end
                else
                    vim.notify(
                        "Failed to download dictionary: " .. lang_code,
                        vim.log.levels.ERROR,
                        { title = "LVIM LINGUISTICS" }
                    )
                end
            end)
        end,
    })
end

--- Enable spell checking for the active language: download its dictionary if needed, then
--- 'setlocal spell' on every allowed buffer via WinEnter/BufEnter.
---@return nil
M.enable_spelling = function()
    local spell_cfg = state.config.spell
    local lang_key = spell_cfg.language
    if not lang_key or type(lang_key) ~= "string" then
        vim.notify("Not defined language(s)", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end
    local lang_info = spell_cfg.languages[lang_key]
    if not lang_info then
        vim.notify("Not defined settings for: " .. lang_key, vim.log.levels.ERROR)
        return
    end
    local spelllang = lang_info.spelllang
    local spellfile = lang_info.spellfile or "global.add"
    if not spelllang then
        vim.notify("Invalid spelllang for: " .. lang_key, vim.log.levels.ERROR)
        return
    end
    local folder = config.plugin_config.spell_files_folder
    local dict_path = folder .. "/" .. spelllang .. ".utf-8.spl"
    --- Apply 'spell' to the current buffer if its filetype is allowed.
    ---@return nil
    local function spell()
        local ft = vim.bo.filetype
        if is_ft_allowed(spell_cfg.file_types, ft) then
            vim.cmd(string.format("setlocal spell spelllang=%s spellfile=%s/%s", spelllang, folder, spellfile))
            spell_cfg.active = true
        end
    end
    ensure_dictionary(spelllang, dict_path, spell)
    vim.api.nvim_clear_autocmds({ group = group_spell_enabled })
    vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
        callback = spell,
        group = group_spell_enabled,
    })
    vim.api.nvim_clear_autocmds({ group = group_spell_disabled })
end

--- Disable spell checking: 'setlocal nospell' now and on subsequent WinEnter, clear the
--- enable autocmds, and flip the state flag.
---@return nil
M.disable_spelling = function()
    vim.cmd("setlocal nospell")
    vim.api.nvim_clear_autocmds({ group = group_spell_enabled })
    vim.api.nvim_clear_autocmds({ group = group_spell_disabled })
    vim.api.nvim_create_autocmd("WinEnter", {
        callback = function()
            vim.cmd("setlocal nospell")
        end,
        group = group_spell_disabled,
    })
    state.config.spell.active = false
end

--- Toggle spell checking on/off (with a notification).
---@return nil
M.toggle_spelling = function()
    if state.config.spell.active then
        M.disable_spelling()
        vim.notify("Spelling disabled", vim.log.levels.INFO)
    else
        M.enable_spelling()
        vim.notify("Spelling enabled: (" .. state.config.spell.language .. ")", vim.log.levels.INFO)
    end
end

--- Re-apply whichever features are marked active in the runtime state (called after load and
--- on DirChanged). No-op until state.config has been populated by get_config().
---@return nil
M.process = function()
    local cfg = state.config
    if type(cfg) ~= "table" then
        return
    end
    if cfg.mode_language.active then
        M.enable_insert_mode_language()
    end
    if cfg.spell.active then
        M.enable_spelling()
    end
end

--- Change the active spell language (must exist in `languages`); re-enables spelling if it
--- was already active so the new language takes effect immediately.
---@param language string  Language key to switch to
---@return nil
M.change_spell_language = function(language)
    if not language or type(language) ~= "string" then
        vim.notify("Invalid spell language", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end
    if not state.config.spell.languages[language] then
        vim.notify("Unknown spell language: " .. language, vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end
    state.config.spell.language = language
    vim.notify("Spell language changed to: " .. language, vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
    if state.config.spell.active then
        M.enable_spelling()
    end
end

return M

-- lvim-linguistics.funcs: the runtime engine — loading the per-cwd state, toggling the two
-- features, and the autocmds that drive them.
--   • Insert-mode layout switching: on InsertEnter set the insert layout, on InsertLeave
--     restore the normal layout, gated by the filetype allow-list.
--   • Spelling: ensure the dictionary is on disk (download on demand), then 'setlocal spell'
--     on the allowed buffers via WinEnter/BufEnter.
-- The active values live in state.config (config.lua holds only the DEFAULTS); the buffers each
-- feature engages in are decided by file_types.black_list / file_types.white_list, compared by how
-- specifically each claims the buffer's filetype and 'buftype' (see `is_ft_allowed`).
--
---@module "lvim-linguistics.funcs"

local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local state = require("lvim-linguistics.state")
local store = require("lvim-linguistics.store")

-- lvim-utils.merge layers a table over another IN PLACE with clean array REPLACE (an
-- override list is the list, not an index-merge). pcall so a missing lvim-utils degrades
-- gracefully to vim.tbl_deep_extend, matching init.lua's dependency handling.
local ok_utils, utils_lib = pcall(require, "lvim-utils.utils")

---@type integer  augroup for the InsertEnter/InsertLeave layout switch
local group_change_mode = vim.api.nvim_create_augroup("LvimLinguisticsChangeMode", { clear = true })
---@type integer  augroup for the WinEnter/BufEnter spell-enable
local group_spell_enabled = vim.api.nvim_create_augroup("LvimLinguisticsSpellEnabled", { clear = true })

local M = {}

--- How strongly one AXIS of a list CLAIMS `value`. The two lists are not ordered against each other
--- — they are compared — so that `"*"` reads as a BLANKET and a named type as an EXCEPTION to it:
---   `black_list = { "*" }, white_list = { "tex" }`  — nothing, except TeX;
---   `white_list = { "*" }, black_list = { "tex" }`  — everything, except TeX.
--- Whichever list names the type outright wins over the one that only said `"*"`; ranking is what
--- makes that work in BOTH directions, where a fixed "black first" or "white first" order can only
--- ever express one of them. An axis may also be given as the bare string `"*"`.
---@param list string[]|string|nil
---@param value string
---@return integer rank  0 = does not claim it, 1 = claimed by "*", 2 = named it exactly
local function claim(list, value)
    if type(list) == "string" then
        list = { list }
    end
    local rank = 0
    for _, entry in ipairs(list or {}) do
        if entry == value then
            return 2
        elseif entry == "*" then
            rank = 1
        end
    end
    return rank
end

--- Split a list into its two axes, `ft` (filetype) and `bt` ('buftype').
--- A bare string or a plain array is shorthand for the `ft` axis, since choosing among real files by
--- filetype is what these lists are for nearly always — `{ "tex" }` and `{ ft = { "tex" } }` are the
--- same list.
---@param list LvimLinguisticsTypeList|nil
---@return { ft: string[]|string|nil, bt: string[]|string|nil }
local function axes(list)
    if list == nil then
        return {}
    end
    if type(list) == "string" or list[1] ~= nil then
        return { ft = list }
    end
    return list
end

--- Run one axis of the gate: allowed when the white list claims `value` MORE specifically than the
--- black list does — so an exact name beats a `"*"` from the other side, and on an equal claim (both
--- `"*"`, or both naming it) the black list wins, because a gate that cannot decide should stay shut.
---@param black string[]|string|nil
---@param white string[]|string|nil
---@param value string
---@return boolean allowed
local function axis_allows(black, white, value)
    -- No allow-list on this axis means "everything is allowed" — the very claim `{ "*" }` makes, so
    -- the default needs no special case: it loses to any black-listed name and beats a bare `"*"`.
    local empty = white == nil or (type(white) == "table" and next(white) == nil)
    local white_rank = empty and 1 or claim(white, value)
    return white_rank > claim(black, value)
end

--- Whether a feature may engage in `buf`, per its type gating — the `ft` axis and the `bt` axis, both
--- of which must allow it.
---
--- When NEITHER list mentions `bt`, the 'buftype' gate is the structural one: only actual FILES the
--- user edits. A panel, popup, picker, terminal, quickfix or prompt buffer all carry a non-empty
--- 'buftype', while every real file has "". Keying on names instead meant the black list had to
--- enumerate every UI in the editor — it still listed the THIRD-PARTY ones this set replaced
--- (`NvimTree`, `neo-tree`, `packer`, `alpha`, `dapui_*`) and knew nothing about the current panels,
--- so enabling spelling immediately underlined the file tree, the control-center popup and every
--- installer prompt. That default stays: a filetype list is the right tool for choosing among real
--- files (skip `log`, allow `tex`), and the wrong tool for "is this a file at all".
---
--- Naming `bt` in either list REPLACES that default with the ranked rule above, for whoever does want
--- spelling in a terminal or a `nofile` scratch buffer. It is deliberately opt-in rather than a
--- default the `ft` axis could collide with: `black_list.bt = { "*" }` as a default would tie with an
--- omitted white `bt` and shut the gate on everything the moment a user set `white_list = { "tex" }`.
---@param file_types LvimLinguisticsFileTypes  The feature's file_types block
---@param ft string                            The buffer filetype to test
---@param buf? integer                         The buffer (defaults to the current one)
---@return boolean allowed
local function is_ft_allowed(file_types, ft, buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local black = axes(file_types.black_list)
    local white = axes(file_types.white_list)
    local bt = vim.bo[buf].buftype
    if black.bt == nil and white.bt == nil then
        if bt ~= "" then
            return false
        end
    elseif not axis_allows(black.bt, white.bt, bt) then
        return false
    end
    return axis_allows(black.ft, white.ft, ft)
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
---   2. the GLOBAL settings, from the control center's database, for every project;
---   3. a project-local `.lvim/linguistics/config.json`, for this directory only.
--- Layers 2 and 3 are the SAME shape (a partial base_config), so both fold in through one merge and
--- a partial layer carries only its own overrides — every key it omits keeps the layer below.
--- Stored in state.config.
---@return nil
M.get_config = function()
    local cfg = vim.deepcopy(config.base_config)

    --- Fold one layer over `cfg` with clean array REPLACE semantics (an override list IS the list).
    ---@param layer_cfg table?
    local function overlay(layer_cfg)
        if not layer_cfg or not next(layer_cfg) then
            return
        end
        if ok_utils and utils_lib.merge then
            cfg = utils_lib.merge(cfg, layer_cfg)
        else
            cfg = vim.tbl_deep_extend("force", cfg, layer_cfg)
        end
    end
    overlay(store.global_config())
    overlay(store.read_local())

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
    vim.api.nvim_clear_autocmds({ group = group_change_mode })
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
            vim.fn.jobstart(full_cmd)
        end)
    end
    vim.api.nvim_create_autocmd("InsertEnter", {
        pattern = "*",
        callback = function()
            cfg = state.config.mode_language
            if is_ft_allowed(cfg.file_types, vim.bo.filetype) then
                set_kbrd(cfg.insert_mode_language)
            end
        end,
        group = group_change_mode,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        pattern = "*",
        callback = function()
            cfg = state.config.mode_language
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
---@param on_fail? fun()  called (in addition to the notify) when the download fails, so a caller
---                       chaining several languages can still settle instead of hanging forever
local function ensure_dictionary(lang_code, target_path, on_ready, on_fail)
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
                    if on_fail then
                        on_fail()
                    end
                end
            end)
        end,
    })
end

--- Enable spell checking for the active language: download its dictionary if needed, then
--- 'setlocal spell' on every allowed buffer via WinEnter/BufEnter.
---@return boolean ok
M.enable_spelling = function()
    vim.api.nvim_clear_autocmds({ group = group_spell_enabled })
    local spell_cfg = state.config.spell
    local lang_key = spell_cfg.language
    if not lang_key or type(lang_key) ~= "string" then
        vim.notify("Not defined language(s)", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return false
    end
    local lang_info = spell_cfg.languages[lang_key]
    if not lang_info then
        vim.notify("Not defined settings for: " .. lang_key, vim.log.levels.ERROR)
        return false
    end
    local spelllang = lang_info.spelllang
    local spellfile = lang_info.spellfile or "global.add"
    if not spelllang then
        vim.notify("Invalid spelllang for: " .. lang_key, vim.log.levels.ERROR)
        return false
    end
    local folder = config.plugin_config.spell_files_folder
    -- 'spelllang' may be a comma list ("en,bg", explicitly documented): each language has its OWN
    -- .spl file, so a single "en,bg.utf-8.spl" target never exists (the 404 meant on_ready never
    -- ran and spell was never enabled). Split and ensure each language independently.
    local langs = vim.split(spelllang, ",", { plain = true, trimempty = true })
    if #langs == 0 then
        langs = { spelllang }
    end
    --- Apply 'spell' to the current window, per the filetype gate — setting it when the filetype is
    --- allowed and CLEARING it when it is not.
    --- Clearing is not symmetry for its own sake: 'spell' is a WINDOW option, so it outlives the
    --- buffer that earned it. Only ever switching it on left every window that had once shown an
    --- allowed filetype spell-checking whatever was loaded into it next — a `white_list = { "tex" }`
    --- still underlined the `.editorconfig` opened in the TeX window, which reads as the allow-list
    --- being ignored. While the feature is active the plugin owns the option on both sides.
    ---@return nil
    local function spell()
        spell_cfg = state.config.spell
        if not is_ft_allowed(spell_cfg.file_types, vim.bo.filetype) then
            vim.opt_local.spell = false
            return
        end
        -- Set via the API, not :setlocal string interpolation, so a spellfile path with spaces
        -- (or other :set-special characters) can't break the command. 'spelllang' takes the
        -- comma list verbatim.
        vim.opt_local.spell = true
        vim.opt_local.spelllang = spelllang
        vim.opt_local.spellfile = folder .. "/" .. spellfile
    end
    --- Run the gate over EVERY open window, not just the current one — the same window-scoped
    --- reasoning: enabling (or re-enabling after a settings change) has to settle the whole screen,
    --- or a split keeps the answer the old gate gave it until it is next entered.
    ---@return nil
    local function spell_all()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            pcall(vim.api.nvim_win_call, win, spell)
        end
    end

    spell_cfg.active = true
    -- Enable spell + install the autocmds once EVERY language has settled (already present,
    -- downloaded, or failed). A failed language still settles (on_fail) so a partial comma list
    -- never leaves the bootstrap hanging; Vim then reports any genuinely missing .spl at spell time.
    local pending = #langs
    local installed = false
    local function settle()
        pending = pending - 1
        if pending <= 0 and not installed then
            installed = true
            spell_all()
            vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
                callback = spell,
                group = group_spell_enabled,
            })
        end
    end
    for _, lc in ipairs(langs) do
        ensure_dictionary(lc, folder .. "/" .. lc .. ".utf-8.spl", settle, settle)
    end
    return true
end

--- Disable spell checking: clear the enable autocmds, set 'nospell' once on every open
--- window (nothing re-applies), and flip the state flag — so a later manual `:setlocal
--- spell` is not fought.
---@return nil
M.disable_spelling = function()
    vim.api.nvim_clear_autocmds({ group = group_spell_enabled })
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        pcall(vim.api.nvim_set_option_value, "spell", false, { win = win })
    end
    state.config.spell.active = false
end

--- Toggle spell checking on/off (with a notification).
---@return nil
M.toggle_spelling = function()
    if state.config.spell.active then
        M.disable_spelling()
        vim.notify("Spelling disabled", vim.log.levels.INFO)
    else
        if M.enable_spelling() then
            vim.notify("Spelling enabled: (" .. state.config.spell.language .. ")", vim.log.levels.INFO)
        end
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
    else
        M.disable_insert_mode_language()
    end
    if cfg.spell.active then
        M.enable_spelling()
    else
        M.disable_spelling()
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

-- lvim-linguistics: public entry point (setup + the command + the two long-lived autocmds).
-- setup() merges user options into the live config (via lvim-utils.utils.merge — clean
-- array REPLACE), registers the LvimLinguistics* highlight groups through lvim-utils so
-- they survive colorscheme changes, registers the `:LvimLinguistics` command, loads the per-cwd
-- runtime state, then defers the first activation pass by a tick so a project-local config is
-- picked up after the cwd is settled. SpellFileMissing downloads a missing .spl/.sug on demand;
-- DirChanged reloads the runtime state (and re-applies) when the cwd changes.
--
---@module "lvim-linguistics"

local config = require("lvim-linguistics.config")
local funcs = require("lvim-linguistics.funcs")

-- lvim-utils is a hard dependency (palette + merge); pcall so a missing install degrades
-- gracefully to Neovim's tbl_deep_extend instead of erroring at load.
local ok_utils, utils_lib = pcall(require, "lvim-utils.utils")

---@type integer  augroup for the SpellFileMissing downloader
local group_spell_file_missing = vim.api.nvim_create_augroup("LvimLinguisticsSpellFileMissing", {
    clear = true,
})
---@type integer  augroup for the DirChanged reload
local group_change_directory = vim.api.nvim_create_augroup("LvimLinguisticsChangeDirectory", {
    clear = true,
})

local hl_mod = require("lvim-linguistics.config.highlights")

local M = {}

--- Configure and start the plugin (idempotent). Merges `user_config` into the live config,
--- registers highlights, loads the per-cwd runtime state and installs the autocmds/command.
---@param user_config? LvimLinguisticsConfig  User overrides (see config.lua)
---@return nil
M.setup = function(user_config)
    if user_config ~= nil then
        if ok_utils and utils_lib.merge then
            utils_lib.merge(config, user_config)
        else
            for k, v in pairs(vim.tbl_deep_extend("force", config, user_config)) do
                config[k] = v
            end
        end
    end

    local ok, hl = pcall(require, "lvim-utils.highlight")
    if ok then
        -- Ensure lvim-utils UI groups are registered so popups are colored even
        -- when require("lvim-utils").setup() has not been called directly.
        local utils_ok, utils_cfg = pcall(require, "lvim-utils.config")
        if utils_ok then
            hl.register(utils_cfg.colors)
        end

        hl.register(hl_mod.build(), hl_mod.force)

        -- Install the ColorScheme autocmd so all registered groups survive a
        -- generic colorscheme change (e.g. :colorscheme foo).
        hl.setup()

        -- Re-register LvimLinguistics* groups whenever the palette changes.
        local colors_ok, colors = pcall(require, "lvim-utils.colors")
        if colors_ok then
            colors.on_change(function()
                hl.register(hl_mod.build(), hl_mod.force)
            end)
        end
    end

    funcs.check_dir()
    M.command()
    funcs.get_config()
    M.spell_file_missing()
    vim.defer_fn(function()
        funcs.process()
        M.change_directory()
    end, 10)
end

--- The panel tabs / quick toggles offered as the FIRST argument. A layout token may follow any of
--- them (panel canon §2), and the completion offers each pool only where it can actually appear —
--- everything at once is what makes a command's completion unreadable.
---@type string[]
local SUBCOMMANDS = { "global", "local", "toggle-spelling", "toggle-insert-mode" }
---@type string[]
local LAYOUTS = { "float", "area", "bottom" }

--- Register `:LvimLinguistics` — the settings panel, plus the two quick toggles as subcommands so a
--- keymap has one command to reach everything the plugin does.
---   :LvimLinguistics [global|local] [float|area|bottom]   open the panel (on that layer's tab)
---   :LvimLinguistics toggle-spelling                      spelling on/off, for this session
---   :LvimLinguistics toggle-insert-mode                   insert-mode layout switching on/off
---@return nil
M.command = function()
    local name = (config.settings_panel or {}).command or "LvimLinguistics"
    vim.api.nvim_create_user_command(name, function(opts)
        local sub, layout
        for _, arg in ipairs(opts.fargs) do
            if vim.tbl_contains(LAYOUTS, arg) then
                layout = arg
            else
                sub = sub or arg
            end
        end
        if sub == "toggle-spelling" then
            funcs.toggle_spelling()
        elseif sub == "toggle-insert-mode" then
            funcs.toggle_insert_mode_language()
        else
            require("lvim-linguistics.panel").open(sub, layout)
        end
    end, {
        nargs = "*",
        desc = "lvim-linguistics: settings panel and quick toggles",
        ---@param lead string  the argument being typed
        ---@param line string  the whole command line so far
        ---@return string[]
        complete = function(lead, line)
            -- Which argument POSITION is being typed: the words already on the line, minus the command
            -- itself, minus the partial word under the cursor. Position 0 is the first argument.
            local words = vim.split(vim.trim(line), "%s+")
            local pos = #words - 1 - (lead == "" and 0 or 1)
            local pool = pos <= 0 and SUBCOMMANDS or LAYOUTS
            return vim.tbl_filter(function(item)
                return item:find(lead, 1, true) == 1
            end, pool)
        end,
    })
end

--- Install the SpellFileMissing autocmd: when Neovim asks for a spell file that isn't on
--- disk, download its .spl and .sug from the Vim FTP mirror into spell_files_folder (async).
---@return nil
M.spell_file_missing = function()
    -- Re-clear the group HERE, not only at module load: setup() calls this on every run, and a
    -- second setup() used to stack a second downloader (two curl jobs per missing spell file).
    vim.api.nvim_create_augroup("LvimLinguisticsSpellFileMissing", { clear = true })
    vim.api.nvim_create_autocmd("SpellFileMissing", {
        callback = function()
            local lang = vim.fn.expand("<amatch>")
            local folder = config.plugin_config.spell_files_folder
            for _, ext in ipairs({ "spl", "sug" }) do
                local url = string.format("https://ftp.nluug.nl/vim/runtime/spell/%s.utf-8.%s", lang, ext)
                local dest = string.format("%s/%s.utf-8.%s", folder, lang, ext)
                vim.notify(
                    "Downloading spell file: " .. lang .. "." .. ext,
                    vim.log.levels.INFO,
                    { title = "LVIM LINGUISTICS" }
                )
                vim.fn.jobstart({ "curl", "-fsSL", url, "-o", dest }, {
                    on_exit = function(_, code)
                        if code == 0 then
                            vim.schedule(function()
                                vim.notify(
                                    "Spell file ready: " .. lang,
                                    vim.log.levels.INFO,
                                    { title = "LVIM LINGUISTICS" }
                                )
                            end)
                        else
                            vim.schedule(function()
                                vim.notify(
                                    "Failed to download spell file: " .. lang,
                                    vim.log.levels.ERROR,
                                    { title = "LVIM LINGUISTICS" }
                                )
                            end)
                        end
                    end,
                })
            end
        end,
        group = group_spell_file_missing,
    })
end

--- Install the DirChanged autocmd: reload the runtime state (picking up a project-local
--- .lvim/linguistics/config.json) and re-apply the active features whenever the global cwd changes.
---@return nil
M.change_directory = function()
    vim.api.nvim_create_augroup("LvimLinguisticsChangeDirectory", { clear = true })
    vim.api.nvim_create_autocmd("DirChanged", {
        pattern = "global",
        callback = function()
            funcs.get_config()
            funcs.process()
        end,
        group = group_change_directory,
    })
end

return M

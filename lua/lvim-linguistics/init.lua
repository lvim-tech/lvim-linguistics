-- lvim-linguistics: public entry point (setup + the two long-lived autocmds).
-- setup() merges user options into the live config (via lvim-utils.utils.merge — clean
-- array REPLACE), registers the LvimLinguistics* highlight groups through lvim-utils so
-- they survive colorscheme changes, creates the settings panel's lvim-control-center instance
-- (which owns the `:LvimLinguistics` command), loads the per-cwd runtime state, then defers the
-- first activation pass by a tick so a project-local config is picked up after the cwd is
-- settled. SpellFileMissing downloads a missing .spl/.sug on demand; DirChanged reloads the
-- runtime state (and re-applies) when the cwd changes.
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
    -- Create the settings panel's dedicated control-center instance (own command + own database)
    -- and bind the global store to it BEFORE get_config, so the global layer is read on load.
    pcall(function()
        require("lvim-linguistics.panel").setup()
    end)
    funcs.get_config()
    M.spell_file_missing()
    vim.defer_fn(function()
        funcs.process()
        M.change_directory()
    end, 10)
end

--- Install the SpellFileMissing autocmd: when Neovim asks for a spell file that isn't on
--- disk, download its .spl and .sug from the Vim FTP mirror into spell_files_folder (async).
---@return nil
M.spell_file_missing = function()
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
--- .lvim_linguistics.json) and re-apply the active features whenever the global cwd changes.
---@return nil
M.change_directory = function()
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

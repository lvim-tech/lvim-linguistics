local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")
local funcs = require("lvim-linguistics.funcs")
local commands = require("lvim-linguistics.commands")
local group_spell_file_missing = vim.api.nvim_create_augroup("LvimLinguisticsSpellFileMissing", {
    clear = true,
})
local group_change_directory = vim.api.nvim_create_augroup("LvimLinguisticsChangeDirectory", {
    clear = true,
})

local M = {}

M.setup = function(user_config)
    if user_config ~= nil then
        utils.merge(config, user_config)
    end

    local ok, hl = pcall(require, "lvim-utils.highlight")
    if ok then
        -- Ensure lvim-utils UI groups are registered so popups are colored even
        -- when require("lvim-utils").setup() has not been called directly.
        local utils_ok, utils_cfg = pcall(require, "lvim-utils.config")
        if utils_ok then
            hl.register(utils_cfg.colors)
        end

        local hl_mod = require("lvim-linguistics.config.highlights")
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
    funcs.get_config()
    M.spell_file_missing()
    vim.defer_fn(function()
        commands.init_commands()
        funcs.process()
        M.change_directory()
    end, 10)
end

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

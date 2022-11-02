local M = {}

M.init_commands = function()
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMENUInsertModeStatus",
        "lua require'lvim-linguistics.ui.nui'.menu_insert_mode_status()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMENUInsertModeLanguage",
        "lua require'lvim-linguistics.ui.nui'.menu_insert_mode_language()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsTOGGLEInsertModeLanguage",
        "lua require'lvim-linguistics.funcs'.toggle_insert_mode_language()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMENUSpellingStatus",
        "lua require'lvim-linguistics.ui.nui'.menu_spelling_status()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMENUSpellLanguages",
        "lua require'lvim-linguistics.ui.nui'.menu_spell_languages()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsTOGGLESpelling",
        "lua require'lvim-linguistics.funcs'.toggle_spelling()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsSAVECurrentConfigAsLocal",
        "lua require'lvim-linguistics.funcs'.toggle_spelling()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsUPDATELocalConfig",
        "lua require'lvim-linguistics.funcs'.toggle_spelling()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsDELETELocalConfig",
        "lua require'lvim-linguistics.funcs'.toggle_spelling()",
        {}
    )
end

return M

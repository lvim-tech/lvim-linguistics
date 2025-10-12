local M = {}

M.init_commands = function()
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMnsertModeStatus",
        "lua require'lvim-linguistics.ui'.menu_insert_mode_status()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMnsertModeLanguage",
        "lua require'lvim-linguistics.ui'.menu_insert_mode_language()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsTOGGLEInsertModeLanguage",
        "lua require'lvim-linguistics.funcs'.toggle_insert_mode_language()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMENUSpellingStatus",
        "lua require'lvim-linguistics.ui'.menu_spelling_status()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMENUSpellLanguages",
        "lua require'lvim-linguistics.ui'.menu_spell_languages()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsTOGGLESpelling",
        "lua require'lvim-linguistics.funcs'.toggle_spelling()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMENUSaveCurrentConfigAsLocal",
        "lua require'lvim-linguistics.ui'.menu_save_current_config_as_local()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMENUUpdateLocalConfig",
        "lua require'lvim-linguistics.ui'.menu_save_current_config_as_local()",
        {}
    )
    vim.api.nvim_create_user_command(
        "LvimLinguisticsMENUDeleteLocalConfig",
        "lua require'lvim-linguistics.ui'.menu_delete_local_config()",
        {}
    )
end

return M

local M = {
    plugin_config = {
        kbrd_cmd = "xkb-switch -s ",
        spell_files_folder = os.getenv("HOME") .. "/.config/nvim/spell/",
        show_message = true,
        local_configs = true,
    },
    base_config = {
        language = {
            active = true,
            filetypes = "*",
            normal_mode_language = nil,
            insert_mode_language = nil,
            insert_mode_languages = nil,
        },
        spell = {
            active = true,
            language = "bg",
            languages = {
                en = {
                    spelllang = "en",
                    spellfile = "en.add",
                },
                bg = {
                    spelllang = "fr",
                    spellfile = "en.add",
                },
            },
        },
    },
}

return M

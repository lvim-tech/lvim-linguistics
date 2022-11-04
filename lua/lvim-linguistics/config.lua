local M = {
    plugin_config = {
        kbrd_cmd = "xkb-switch -s ",
        spell_files_folder = os.getenv("HOME") .. "/.config/nvim/spell/",
    },
    base_config = {
        mode_language = {
            active = false,
            normal_mode_language = nil,
            insert_mode_language = nil,
            insert_mode_languages = {},
        },
        spell = {
            active = false,
            language = nil,
            languages = {
                en = {
                    spelllang = "en",
                    spellfile = "en.add",
                },
            },
        },
    },
}

return M

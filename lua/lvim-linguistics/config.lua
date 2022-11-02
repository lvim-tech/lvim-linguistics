local M = {
    plugin_config = {
        kbrd_cmd = "xkb-switch -s ",
        spell_files_folder = os.getenv("HOME") .. "/.config/nvim/spell/",
        show_message = true,
        local_configs = true,
        blacklist_ft = {
            "ctrlspace",
            "ctrlspace_help",
            "packer",
            "undotree",
            "diff",
            "Outline",
            "NvimTree",
            "LvimHelper",
            "floaterm",
            "toggleterm",
            "Trouble",
            "dashboard",
            "vista",
            "spectre_panel",
            "DiffviewFiles",
            "flutterToolsOutline",
            "log",
            "qf",
            "dapui_scopes",
            "dapui_breakpoints",
            "dapui_stacks",
            "dapui_watches",
            "calendar",
            "neo-tree",
            "neo-tree-popup",
            "noice",
            "",
        },
        blacklist_bt = {
            "acwrite",
            "help",
            "nofile",
            "nowrite",
            "quickfix",
            "terminal",
            "prompt",
        },
    },
    base_config = {
        mode_language = {
            active = true,
            normal_mode_language = "us",
            insert_mode_language = "bg",
            insert_mode_languages = { "bg", "fr" },
        },
        spell = {
            active = true,
            language = "en",
            languages = {
                en = {
                    spelllang = "en",
                    spellfile = "en.add",
                },
                fr = {
                    spelllang = "fr",
                    spellfile = "fr.add",
                },
                bg = {
                    spelllang = "bg",
                    spellfile = "bg.add",
                },
                bg_en = {
                    spelllang = "bg,en",
                    spellfile = "bg_en.add",
                },
            },
        },
    },
}

return M

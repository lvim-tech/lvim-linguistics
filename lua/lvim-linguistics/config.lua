local M = {
    plugin_config = {
        kbrd_cmd = "xkb-switch -s ",
        spell_files_folder = os.getenv("HOME") .. "/.config/nvim/spell/",
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

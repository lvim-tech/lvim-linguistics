# LVIM LINGUISTICS

![LVIM LINGUISTICS](./media/lvim-linguistics.png)

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://github.com/lvim-tech/lvim-helper/blob/main/LICENSE)

## DESCRIPTION

Lvim Linguistics is a plug-in for controlling spelling and keyboard language in insert mode (when writing a document in
a different language).

> This plug-in is support local config for projects (directories)

> Current version - 1.0.05

## Requirements:

-   [xkb-switch](https://github.com/grwlf/xkb-switch) - to switch the keyboard (you can use another mechanism)
-   [MunifTanjim/nui.nvim](https://github.com/MunifTanjim/nui.nvim)
-   [rcarriga/nvim-notify](https://github.com/rcarriga/nvim-notify)
-   [lvim-tech/lvim-select-input](https://github.com/lvim-tech/lvim-select-input)

## Init

```lua
use({
    "lvim-tech/lvim-linguistics",
    event = "VimEnter",
    requires = {
        {
            "MunifTanjim/nui.nvim",
        },
        {
            "rcarriga/nvim-notify",
        },
        {
            "lvim-tech/lvim-select-input",
        },
    },
    rocks = {
        {
            "lunajson",
            server = "http://rocks.moonscript.org",
        },
    },
    config = function()
        require("lvim-linguistics").setup({
            -- your config
        })
    end,
})
```

## Default config

```lua
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
}
```

-   `kbrd_cmd` - command for switch keyboard

-   `spell_files_folder` - folder to save spell files

-   `base_config` - config for mode language and spelling

-   `base_config` example:

```lua
base_config = {
    mode_language = {
        active = false, -- changing the keyboard language does not start automatically
        normal_mode_language = "us", -- keyboard language (normal mode)
        insert_mode_language = "fr", -- keyboard language (insert mode)
        insert_mode_languages = { "fr", "de" }, -- you can choice language for insert mode
    },
    spell = {
        active = false, -- spelling does not start automatically
        language = "en", -- language for spellin
        languages = { -- you can choice language for spelling
            en = {
                spelllang = "en",
                spellfile = "en.add",
            }, -- config for en
            fr = {
                spelllang = "fr",
                spellfile = "fr.add",
            }, -- config for fr
            de = {
                spelllang = "de",
                spellfile = "de.add",
            }, -- config for de
            en_fr = {
                spelllang = "en,fr",
                spellfile = "en_fr.add",
            }, -- config for en + fr
        },
    },
}
```

## Commands

### Mode language

-   `LvimLinguisticsMENUInsertModeStatus`

Enable / Disable changing language in insert mode

![LvimLinguisticsMENUInsertModeStatus](./media/01.LvimLinguisticsMENUInsertModeStatus.png)

-   `LvimLinguisticsMENUInsertModeLanguage`

Language selection for insert mode

![LvimLinguisticsMENUInsertModeLanguage](./media/02.LvimLinguisticsMENUInsertModeLanguage.png)

-   `LvimLinguisticsTOGGLEInsertModeLanguage`

You can set a keymap for this command to enable/disable

```lua
vim.keymap.set("n", "<C-c>l", function()
    vim.cmd("LvimLinguisticsTOGGLEInsertModeLanguage")
end, { noremap = true, silent = true, desc = "LvimLinguisticsTOGGLEInsertModeLanguage" })
```

![LvimLinguisticsTOGGLEInsertModeLanguage](./media/03.LvimLinguisticsTOGGLEInsertModeLanguage.png)

### Spell

-   `LvimLinguisticsMENUSpellingStatus`

Enable / Disable spelling

![LvimLinguisticsMENUSpellingStatus](./media/04.LvimLinguisticsMENUSpellingStatus.png)

-   `LvimLinguisticsMENUSpellLanguages`

Select spelling language

![LvimLinguisticsMENUSpellLanguages](./media/05.LvimLinguisticsMENUSpellLanguages.png)

-   `LvimLinguisticsTOGGLESpelling`

```lua
vim.keymap.set("n", "<C-c>s", function()
    vim.cmd("LvimLinguisticsTOGGLESpelling")
end, { noremap = true, silent = true, desc = "LvimLinguisticsTOGGLESpelling" })
```

![LvimLinguisticsTOGGLESpelling](./media/06.LvimLinguisticsTOGGLESpelling.png)

### Local config

-   `LvimLinguisticsMENUSaveCurrentConfigAsLocal`

Save the current configuration for the current project (folder)

![LvimLinguisticsMENUSaveCurrentConfigAsLocal](./media/07.LvimLinguisticsMENUSaveCurrentConfigAsLocal.png)

![LvimLinguisticsLocalConfigFile](./media/07.LvimLinguisticsLocalConfigFile.png)

-   `LvimLinguisticsMENUUpdateLocalConfig`

Update the current configuration for the current project (folder)

![LvimLinguisticsMENUUpdateLocalConfig](./media/08.LvimLinguisticsMENUUpdateLocalConfig.png)

-   `LvimLinguisticsMENUDeleteLocalConfig`

Delete a file for the current project (folder)

![LvimLinguisticsMENUDeleteLocalConfig](./media/09.LvimLinguisticsMENUDeleteLocalConfig.png)

## Status

You can add custom statusline component for Spell status

-   Example for Heirline:

```lua
local spell = {
    condition = require("lvim-linguistics.status").spell_has,
    provider = function()
        local status = require("lvim-linguistics.status").spell_get()
        return status
    end,
    hl = { fg = "#YOUR_COLOR", bold = true },
}
```

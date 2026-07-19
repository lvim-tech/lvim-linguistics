# LVIM LINGUISTICS

Lvim Linguistics controls spelling and keyboard language in insert mode — useful when
writing documents in a foreign language. Supports per-project local config
(`.lvim_linguistics.json` in the project root).

![LVIM LINGUISTICS](./media/lvim-linguistics.png)

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://github.com/lvim-tech/lvim-linguistics/blob/main/LICENSE)

## Requirements

Keyboard switching depends on your display server. The plugin auto-detects the session and picks the right tool:

| Session            | Tool                                              |
| ------------------ | ------------------------------------------------- |
| X11                | [xkb-switch](https://github.com/grwlf/xkb-switch) |
| Wayland — Hyprland | `hyprctl` (bundled with Hyprland)                 |
| Wayland — niri     | `niri` (bundled)                                  |
| Wayland — sway     | `swaymsg` (bundled)                               |
| Wayland — mango    | [mmsg](https://github.com/mangowm/mango)          |
| Wayland — GNOME    | `gdbus` (bundled with GLib)                       |

> You can always override `kbrd_cmd` manually — see configuration below.

## Installation

Requires Neovim >= 0.10 and [lvim-utils](https://github.com/lvim-tech/lvim-utils).

### lvim-installer (recommended)

Install and manage it from the LVIM package manager — open the **Plugins** tab and install / update / pin it:

```vim
:LvimInstaller plugins
```

lvim-installer installs plugins through Neovim's built-in `vim.pack`, so no external plugin manager is needed.

### lazy.nvim

```lua
return {
    "lvim-tech/lvim-linguistics",
    dependencies = { "lvim-tech/lvim-utils" },
    config = function()
        require("lvim-linguistics").setup({})
    end,
}
```

### packer.nvim

```lua
use({
    "lvim-tech/lvim-linguistics",
    requires = { "lvim-tech/lvim-utils" },
    config = function()
        require("lvim-linguistics").setup({})
    end,
})
```

### Native (vim.pack)

```lua
vim.pack.add({
    { src = "https://github.com/lvim-tech/lvim-utils" },
    { src = "https://github.com/lvim-tech/lvim-linguistics" },
})
require("lvim-linguistics").setup({})
```

## Configuration

### plugin_config

```lua
plugin_config = {
    -- Keyboard switch command. Auto-detected from XDG_SESSION_TYPE /
    -- XDG_CURRENT_DESKTOP / WAYLAND_DISPLAY at startup.
    -- Can be a string prefix ("xkb-switch -s ") or a function:
    --
    --   kbrd_cmd = function(lang)
    --       local idx = { en = 0, bg = 1 }
    --       return "hyprctl switchxkblayout all " .. (idx[lang] or 0)
    --   end
    --
    kbrd_cmd = "<auto-detected>",

    -- Folder where spell files (.spl) are stored.
    -- Files are downloaded automatically on first use (async, no blocking).
    spell_files_folder = os.getenv("HOME") .. "/.config/nvim/spell",
}
```

### base_config

```lua
base_config = {
    mode_language = {
        active = false,
        file_types = {
            black_list = { ... }, -- filetypes where switching is disabled
            white_list = {},
        },
        normal_mode_language = nil, -- layout name used in Normal mode
        insert_mode_language = nil, -- layout name used in Insert mode
        insert_mode_languages = {}, -- selectable layouts in the UI
    },
    spell = {
        active = false,
        file_types = {
            black_list = { ... },
            white_list = {},
        },
        language = nil, -- active language key (must exist in languages)
        languages = {
            en = {
                spelllang = "en",
                spellfile = "en.add",
            },
        },
    },
}
```

### Full example

```lua
require("lvim-linguistics").setup({
    base_config = {
        mode_language = {
            active = true,
            file_types = {
                white_list = { "tex", "markdown" },
            },
            normal_mode_language = "us",
            insert_mode_language = "bg",
            insert_mode_languages = { "bg", "de", "fr" },
        },
        spell = {
            active = true,
            file_types = {
                white_list = { "tex", "markdown" },
            },
            language = "en",
            languages = {
                en = { spelllang = "en", spellfile = "en.add" },
                bg = { spelllang = "bg", spellfile = "bg.add" },
                en_bg = { spelllang = "en,bg", spellfile = "en_bg.add" },
            },
        },
    },
})
```

For Hyprland / mango (index-based layout switching), use a function for `kbrd_cmd`:

```lua
plugin_config = {
    kbrd_cmd = function(lang)
        local idx = { en = 0, bg = 1 }
        return "hyprctl switchxkblayout all " .. (idx[lang] or 0)
    end,
}
```

## Commands

All functionality is exposed through a single command with subcommands:

```
:LvimLinguistics [subcommand]
```

The command is owned by **lvim-control-center** (which hosts the panel), so besides opening
it, it carries the full control-center command — plus the plugin's quick toggles:

| Subcommand           | Description                                                     |
| -------------------- | -------------------------------------------------------------- |
| _(none)_             | Open the settings panel                                        |
| `Spelling` / `Insert Mode` / `Config` | Open the panel focused on that tab (by name)  |
| `toggle-spelling`    | Toggle spell checking on/off (no panel)                        |
| `toggle-insert-mode` | Toggle insert-mode language switching on/off (no panel)        |
| `export` / `import` / `reset` | Export / import / reset the global settings           |
| `search`             | Fuzzy-search every setting across the tabs                     |
| `preset save\|load\|list\|delete <name>` | Named global-settings profiles             |

The panel's settings are the **global default** (stored in the panel's own database); a
project-local `.lvim_linguistics.json` (Config tab → _Save as local config_) overrides them
per directory.

### Keymaps example

```lua
vim.keymap.set(
    "n",
    "<C-c>s",
    "<cmd>LvimLinguistics toggle-spelling<cr>",
    { noremap = true, silent = true, desc = "Toggle spelling" }
)

vim.keymap.set(
    "n",
    "<C-c>l",
    "<cmd>LvimLinguistics toggle-insert-mode<cr>",
    { noremap = true, silent = true, desc = "Toggle insert mode language" }
)
```

## Screenshots

Insert-mode keyboard language:

![Insert mode status](./media/01.LvimLinguisticsMENUInsertModeStatus.png)
![Insert mode language](./media/02.LvimLinguisticsMENUInsertModeLanguage.png)
![Toggle insert mode](./media/03.LvimLinguisticsTOGGLEInsertModeLanguage.png)

Spelling:

![Spelling status](./media/04.LvimLinguisticsMENUSpellingStatus.png)
![Spell languages](./media/05.LvimLinguisticsMENUSpellLanguages.png)
![Toggle spelling](./media/06.LvimLinguisticsTOGGLESpelling.png)

Per-project local config:

![Save current config as local](./media/07.LvimLinguisticsMENUSaveCurrentConfigAsLocal.png)
![Local config file](./media/07.LvimLinguisticsLocalConfigFile.png)
![Delete local config](./media/09.LvimLinguisticsMENUDeleteLocalConfig.png)

## Spell files

Spell files (`.spl`) are downloaded automatically from the Vim FTP mirror the first time a language is activated. The download is **non-blocking** — Neovim stays responsive and a notification appears when the file is ready.

## Highlights

The plugin defines the following highlight groups via `lvim-utils.highlight`. They adapt automatically to palette changes (e.g. when switching colorschemes via `lvim-colorscheme`).

| Group                        | Default color  | Purpose                           |
| ---------------------------- | -------------- | --------------------------------- |
| `LvimLinguisticsIcon`        | teal           | General icons                     |
| `LvimLinguisticsSpellActive` | green          | Active spell indicator            |
| `LvimLinguisticsSpellLang`   | blue           | Language name                     |
| `LvimLinguisticsSpellSep`    | blue (blended) | Separator                         |
| `LvimLinguisticsLangActive`  | purple bold    | Active language in mode switching |
| `LvimLinguisticsLangNormal`  | teal           | Normal mode language              |
| `LvimLinguisticsLangInsert`  | yellow         | Insert mode language              |

Override in your colorscheme or config:

```lua
vim.api.nvim_set_hl(0, "LvimLinguisticsSpellActive", { fg = "#your_color" })
```

## Statusline integration

```lua
-- Heirline example
local spell = {
    condition = function()
        return require("lvim-linguistics.status").spell_has()
    end,
    provider = function()
        return require("lvim-linguistics.status").spell_get()
    end,
    hl = { fg = "#YOUR_COLOR", bold = true },
}
```

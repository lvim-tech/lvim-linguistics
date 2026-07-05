-- lvim-linguistics.config: the live configuration table.
-- Holds the defaults; setup() merges user overrides into it in place (via
-- lvim-utils.utils.merge), so every require("lvim-linguistics.config") reader sees the
-- effective values. `plugin_config` is host/session wiring (keyboard-switch command,
-- spell-file folder); `base_config` is the DEFAULT spelling / insert-mode profile that
-- gets copied into the runtime state (see state.lua) — either verbatim, or replaced by a
-- project-local .lvim_linguistics.json.
--
---@module "lvim-linguistics.config"

-- Filetypes shared by both features' black_list: panels/pickers/terminals/etc. where
-- neither spelling nor keyboard switching should ever engage.
---@type string[]
local shared_blacklist = {
    "alpha",
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
    "octo",
    "neo-tree",
    "neo-tree-popup",
    "noice",
}

--- Pick the keyboard-layout switch command for the current display server/desktop.
--- X11 uses `xkb-switch`; Wayland dispatches per compositor (Hyprland/mango/niri/sway/
--- GNOME), falling back to `xkb-switch` when nothing matches. The returned string is a
--- PREFIX to which the layout id is appended (`kbrd_cmd .. lang`) unless overridden with a
--- function in plugin_config.kbrd_cmd.
---@return string cmd  The switch-command prefix
local function detect_kbrd_cmd()
    local is_wayland = (os.getenv("WAYLAND_DISPLAY") or "") ~= "" or os.getenv("XDG_SESSION_TYPE") == "wayland"

    if not is_wayland then
        return "xkb-switch -s "
    end

    local desktop = (os.getenv("XDG_CURRENT_DESKTOP") or ""):lower()
    local session = (os.getenv("DESKTOP_SESSION") or ""):lower()

    if desktop:find("hyprland") or session:find("hyprland") then
        return "hyprctl switchxkblayout all "
    elseif desktop:find("mango") or session:find("mango") then
        return "mmsg -d switch_keyboard_layout "
    elseif desktop:find("niri") or session:find("niri") or (os.getenv("NIRI_SOCKET") or "") ~= "" then
        return "niri msg action switch-layout "
    elseif desktop:find("sway") or session:find("sway") then
        return "swaymsg input type:keyboard xkb_switch_layout "
    elseif desktop:find("gnome") or session:find("gnome") then
        return "gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "
            .. "'imports.ui.status.keyboard.getInputSourceManager().inputSources.filter(s=>s.id==\"%s\")[0]?.activate()' > /dev/null 2>&1 && true #"
    else
        return "xkb-switch -s "
    end
end

---@class LvimLinguisticsFileTypes
---@field black_list string[]  Filetypes where the feature is NEVER active
---@field white_list string[]  If non-empty, the feature is active ONLY in these filetypes (black_list still excludes)

---@class LvimLinguisticsModeLanguage
---@field active                boolean                  Whether insert-mode layout switching is on
---@field file_types            LvimLinguisticsFileTypes Filetype gating for layout switching
---@field normal_mode_language  string?                  Layout id restored on InsertLeave
---@field insert_mode_language  string?                  Layout id set on InsertEnter
---@field insert_mode_languages string[]                 Selectable insert-mode layouts (UI dropdown)

---@class LvimLinguisticsSpellLang
---@field spelllang string   'spelllang' value (e.g. "en", "en,bg")
---@field spellfile string?  'spellfile' name (defaults to "global.add")

---@class LvimLinguisticsSpell
---@field active    boolean                                   Whether spell checking is on
---@field file_types LvimLinguisticsFileTypes                 Filetype gating for spelling
---@field language  string?                                   Active language key (must exist in `languages`)
---@field languages table<string, LvimLinguisticsSpellLang>  Configured spell languages, keyed by id

---@class LvimLinguisticsBaseConfig
---@field mode_language LvimLinguisticsModeLanguage
---@field spell         LvimLinguisticsSpell

---@class LvimLinguisticsPluginConfig
---@field kbrd_cmd           string|fun(lang:string):string  Keyboard-switch command prefix, or a function of the layout id
---@field spell_files_folder string                          Directory where .spl/.sug spell files are stored

---@class LvimLinguisticsConfig
---@field plugin_config LvimLinguisticsPluginConfig  Host/session wiring
---@field base_config   LvimLinguisticsBaseConfig    Default spelling / insert-mode profile
---@field settings_panel { command?: string, save?: string }  The settings panel, hosted by lvim-control-center: `command` = the user command that opens it, `save` = its OWN database directory

---@type LvimLinguisticsConfig
local M = {
    plugin_config = {
        kbrd_cmd = detect_kbrd_cmd(),
        spell_files_folder = os.getenv("HOME") .. "/.config/nvim/spell/",
    },
    -- The settings panel is hosted by lvim-control-center (a required dependency) as its OWN
    -- instance with its OWN database — for the GLOBAL default. control-center REGISTERS the
    -- command (the plugin no longer makes one), so `:LvimLinguistics` is the panel command +
    -- the quick toggles (subcommands). A project-local `.lvim_linguistics.json` (Config tab →
    -- Save as local config) overrides the global per directory.
    settings_panel = {
        command = "LvimLinguistics", -- the user command that opens the panel (owned by control-center)
        save = nil, -- database directory; nil → stdpath("data")/lvim-linguistics
    },
    base_config = {
        mode_language = {
            active = false,
            file_types = {
                black_list = shared_blacklist,
                white_list = {},
            },
            normal_mode_language = nil,
            insert_mode_language = nil,
            insert_mode_languages = {},
        },
        spell = {
            active = false,
            file_types = {
                black_list = shared_blacklist,
                white_list = {},
            },
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

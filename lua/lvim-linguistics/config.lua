-- lvim-linguistics.config: the live configuration table.
-- Holds the defaults; setup() merges user overrides into it in place (via
-- lvim-utils.utils.merge), so every require("lvim-linguistics.config") reader sees the
-- effective values. `plugin_config` is host/session wiring (keyboard-switch command,
-- spell-file folder); `base_config` is the DEFAULT spelling / insert-mode profile that
-- gets copied into the runtime state (see state.lua) — either verbatim, or replaced by a
-- project-local .lvim/linguistics/config.json.
--
---@module "lvim-linguistics.config"

-- Filetypes shared by both features' black_list — for REAL FILES only.
--
-- Panels, pickers, popups and terminals are NOT listed here and must not be: they are excluded
-- structurally, by their non-empty 'buftype' (see `is_ft_allowed` in funcs.lua). The list used to
-- enumerate them by name — and named the THIRD-PARTY plugins this set replaced (`NvimTree`,
-- `neo-tree`, `packer`, `alpha`, `undotree`, `Trouble`, `dapui_*`, `noice`, …), none of which exist
-- here any more, while knowing nothing about the current ones. The result was spelling underlining
-- the file tree, the control-center popup and every installer prompt. A name list can never keep up
-- with the editor's own surfaces; 'buftype' already answers "is this a file at all".
--
-- What remains is the only thing a filetype list is good for: real files whose CONTENT is not prose.
---@type string[]
local shared_blacklist = {
    "diff",
    "log",
}

--- Pick the keyboard-layout switch command for the current display server/desktop.
--- X11 uses `xkb-switch`; Wayland dispatches per compositor (Hyprland/mango/niri/sway/
--- GNOME), falling back to `xkb-switch` when nothing matches. Most cases return a PREFIX to
--- which the layout id is appended (`kbrd_cmd .. lang`); GNOME returns a FUNCTION instead,
--- because the id must land inside the Eval JS rather than after the command.
---@return string|fun(lang:string):string cmd  The switch-command prefix, or a function of the layout id
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
        -- mango's switch_keyboard_layout ACCEPTS a layout argument and ignores
        -- it: measured 2026-08, three consecutive requests for "bg" from us
        -- produced bg, us, bg — a plain toggle, in both the `,bg` and ` bg`
        -- spellings. Appending the id therefore set the right layout only
        -- while the requests happened to alternate, which insert/normal mode
        -- usually do — until the layout is already the wanted one (switched by
        -- hand with grp:alt_shift_toggle), where the toggle moved AWAY from it.
        --
        -- So the id is not appended; the layout is read back and the toggle
        -- repeated until the compositor reports what was asked for. Bounded to
        -- four laps so an id mango does not have cannot spin forever, and the
        -- en/us pair counts as one layout under both spellings.
        return function(lang)
            return ([[want=%s; i=0; while [ $i -lt 4 ]; do ]]
                .. [[cur=$(mmsg -k 2>/dev/null | awk '/kb_layout/{print $3; exit}'); ]]
                .. [[[ "$cur" = "$want" ] && break; ]]
                .. [[{ [ "$want" = en ] && [ "$cur" = us ]; } && break; ]]
                .. [[{ [ "$want" = us ] && [ "$cur" = en ]; } && break; ]]
                .. [[mmsg -d switch_keyboard_layout; sleep 0.06; i=$((i+1)); done]]):format(lang)
        end
    elseif desktop:find("niri") or session:find("niri") or (os.getenv("NIRI_SOCKET") or "") ~= "" then
        return "niri msg action switch-layout "
    elseif desktop:find("sway") or session:find("sway") then
        return "swaymsg input type:keyboard xkb_switch_layout "
    elseif desktop:find("gnome") or session:find("gnome") then
        -- GNOME needs the layout id INSIDE the Eval JS, not appended after the command. Return a
        -- function (the config supports fun(lang):string) that formats the id into the source filter —
        -- no "%s" placeholder that the plain `kbrd_cmd .. lang` concat could never substitute, and no
        -- trailing `#` to swallow the appended arg (both were a kludge that made the switch a no-op).
        -- (Note: GNOME Shell ≥ 41 disables Shell.Eval by default; :checkhealth warns about that.)
        return function(lang)
            return "gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell "
                .. "--method org.gnome.Shell.Eval "
                .. ("'imports.ui.status.keyboard.getInputSourceManager().inputSources.filter(s=>s.id==%q)[0]?.activate()'"):format(
                    lang
                )
                .. " > /dev/null 2>&1"
        end
    else
        return "xkb-switch -s "
    end
end

--- One side of the type gate, on two axes: `ft` (filetype) and `bt` ('buftype'). A bare string or a
--- plain array is shorthand for `ft`, so `{ "tex" }` and `{ ft = { "tex" } }` are the same list.
---@alias LvimLinguisticsTypeList string[]|string|{ ft: string[]|string, bt: string[]|string }

--- Type gating. Either list takes `"*"` (as an entry or as the bare string) meaning EVERY type, and
--- the more specific claim wins: a named type overrides the other list's `"*"`, so both directions
--- are expressible —
---   `black_list = { "*" }, white_list = { "tex" }`  — nothing, except TeX;
---   `white_list = { "*" }, black_list = { "tex" }`  — everything, except TeX.
--- An empty `white_list` means the same as `{ "*" }`. When both claim a type equally, the black list
--- wins. Until a list names `bt`, panels, popups and terminals are excluded structurally.
---@class LvimLinguisticsFileTypes
---@field black_list LvimLinguisticsTypeList  Types where the feature is NEVER active
---@field white_list LvimLinguisticsTypeList  Types where it MAY be active; empty = all

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
---@field settings_panel { command?: string, layout?: string }  The project-local settings panel: `command` = the user command that opens it, `layout` = how it opens ("float"|"area"|"bottom")

---@type LvimLinguisticsConfig
local M = {
    plugin_config = {
        kbrd_cmd = detect_kbrd_cmd(),
        -- No trailing slash: every consumer concatenates `folder .. "/" .. name`, so a trailing slash
        -- here produced a double slash (".../spell//en.utf-8.spl") in every path and notify.
        spell_files_folder = os.getenv("HOME") .. "/.config/nvim/spell",
    },
    -- The PROJECT-LOCAL settings panel (lvim-ui), opened by `command` — which also carries the quick
    -- toggles as subcommands. It writes `.lvim/linguistics/config.json`, a partial `base_config`
    -- overlay for one directory. The GLOBAL settings are not here: they are a group in the control
    -- center, stored in its database (see `lvim-linguistics.store`).
    settings_panel = {
        command = "LvimLinguistics", -- the user command that opens the panel + the toggles
        layout = "float", -- "float" (centred modal) | "area" (cmdline zone) | "bottom"
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

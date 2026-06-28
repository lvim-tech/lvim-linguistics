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

local M = {
    plugin_config = {
        kbrd_cmd = detect_kbrd_cmd(),
        spell_files_folder = os.getenv("HOME") .. "/.config/nvim/spell/",
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

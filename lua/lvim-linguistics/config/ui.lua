-- lvim-linguistics.config.ui: UI defaults for the settings panel.
-- popup_global is passed to lvim-ui.new() for per-instance overrides (position,
-- size, icon set, key bindings, hint labels); menus holds the panel title and tab
-- labels/icons read by ui/init.lua.
--
---@module "lvim-linguistics.config.ui"

return {
    popup_global = {
        position = "editor",
        -- SIZE is intentionally omitted: it comes from the shared lvim-ui geometry (config.ui.size),
        -- like every other lvim-tech panel. Setting width/height here overrode that shared geometry and
        -- made the title/tab bands clamp to a different width than the body (the band "not reaching the
        -- end"). ui.new() applies the rest of this table as per-open defaults.
        close_keys = { "q", "<Esc>" },
        markview = false,

        icons = {
            bool_on = "󰄬",
            bool_off = "󰍴",
            select = "󰘮",
            number = "󰎠",
            string = "󰬴",
            action = "",
            spacer = "   ──────",
            multi_selected = "󰄬",
            multi_empty = "󰍴",
            current = "➤",
        },

        labels = {
            navigate = "navigate",
            confirm = "confirm",
            cancel = "cancel",
            close = "close",
            toggle = "toggle",
            cycle = "cycle",
            edit = "edit",
            execute = "execute",
            tabs = "tabs",
        },

        keys = {
            down = "j",
            up = "k",
            confirm = "<CR>",
            cancel = "<Esc>",
            close = "q",

            tabs = {
                next = "l",
                prev = "h",
            },

            select = {
                confirm = "<CR>",
                cancel = "<Esc>",
            },

            multiselect = {
                toggle = "<Space>",
                confirm = "<CR>",
                cancel = "<Esc>",
            },

            list = {
                next_option = "<Tab>",
                prev_option = "<BS>",
            },

            back = "u",
        },

        highlights = {},
    },

    -- ── Main panel ───────────────────────────────────────────────────────────────

    menus = {
        main = {
            title = "󰊷 Lvim Linguistics",
            tabs = {
                spelling = { label = "Spelling", icon = "󰓆" },
                insert_mode = { label = "Insert Mode", icon = "󰌌" },
                config = { label = "Config", icon = "󰒓" },
            },
        },
    },
}

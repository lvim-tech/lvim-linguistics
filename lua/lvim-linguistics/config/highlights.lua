-- lvim-linguistics: highlight group definitions.
-- All colors come from lvim-utils.colors so the palette is shared across plugins.
-- Registered via lvim-utils.highlight — survive colorscheme changes.
--
-- build() must be a function so each call reads the current palette values.

local c = require("lvim-utils.colors")
local hl = require("lvim-utils.highlight")

local function build()
    return {
        -- ── General ───────────────────────────────────────────────────────────
        LvimLinguisticsIcon = { fg = c.teal },

        -- ── Spell ─────────────────────────────────────────────────────────────
        LvimLinguisticsSpellActive = { fg = c.green },
        LvimLinguisticsSpellLang = { fg = c.blue },
        LvimLinguisticsSpellSep = { fg = hl.blend(c.blue, c.bg, 0.5) },

        -- ── Insert mode language ───────────────────────────────────────────────
        LvimLinguisticsLangActive = { fg = c.purple, bold = true },
        LvimLinguisticsLangNormal = { fg = c.teal },
        LvimLinguisticsLangInsert = { fg = c.yellow },
    }
end

return {
    build = build,
    force = false,
}

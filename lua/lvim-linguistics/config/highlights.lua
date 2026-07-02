-- lvim-linguistics.config.highlights: highlight group definitions.
-- All colors come from lvim-utils.colors so the palette is shared across plugins.
-- Registered via lvim-utils.highlight — they survive colorscheme changes. build()
-- is a function (not a static table) so each call reads the CURRENT palette values
-- and the groups can be rebuilt on a palette change.
--
---@module "lvim-linguistics.config.highlights"

local c = require("lvim-utils.colors")
local hl = require("lvim-utils.highlight")

--- Build the LvimLinguistics* highlight-group table from the current palette.
---@return table<string, vim.api.keyset.highlight>  group name -> highlight spec
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

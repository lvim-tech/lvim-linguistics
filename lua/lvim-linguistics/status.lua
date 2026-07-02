-- lvim-linguistics.status: statusline providers.
-- spell_has() reports whether 'spell' is on in the current window; spell_get()
-- returns the active spell-language label ("KEY (SPELLLANG)") from the runtime
-- state (state.lua, NOT a global), or nil when spelling is not configured — so a
-- statusline component can gate on spell_has() and render spell_get().
--
---@module "lvim-linguistics.status"

local state = require("lvim-linguistics.state")

local M = {}

--- Whether spell checking is on in the current window.
---@return boolean has  True when 'spell' is set for the current window
M.spell_has = function()
    return vim.wo.spell
end

--- The active spell-language label, upper-cased as "KEY (SPELLLANG)". Returns nil when
--- there is no runtime state, no active language, or no matching language definition.
---@return string? label  The upper-cased label, or nil
M.spell_get = function()
    local cfg = state.config
    if type(cfg) ~= "table" then
        return nil
    end
    local language = cfg.spell.language
    if type(language) ~= "string" then
        return nil
    end
    local lang_info = cfg.spell.languages[language]
    if not lang_info or not lang_info.spelllang then
        return nil
    end
    return string.upper(language .. " (" .. lang_info.spelllang .. ")")
end

return M

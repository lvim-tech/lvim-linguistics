local M = {}

M.spell_has = function()
    return vim.wo.spell
end

M.spell_get = function()
    local string_return = string.upper(
        _G.LVIM_LINGUISTICS.spell.language
            .. " ("
            .. _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language].spelllang
            .. ")"
    )
    return string_return
end

return M

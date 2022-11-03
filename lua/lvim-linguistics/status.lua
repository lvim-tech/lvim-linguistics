local M = {}

M.spell_has = function()
    return vim.wo.spell
end

M.spell_get = function()
    local string_return = _G.LVIM_LINGUISTICS.spell.language
        .. " ("
        .. _G.LVIM_LINGUISTICS.spell.languages[_G.LVIM_LINGUISTICS.spell.language].spelllang
        .. ")"
    if string_return ~= nil and type(string_return) == "string" then
        return string.upper(string_return)
    else
        return
    end
end

return M

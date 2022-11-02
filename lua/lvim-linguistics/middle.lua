local autocmd = require("lvim-linguistics.autocmd")

local M = {}

M.enable_insert_mode_language = function()
    vim.notify("hi")
    _G.LVIM_LINGUISTICS.mode_language.active = true
    autocmd.enable_insert_mode_language()
end

M.disable_insert_mode_language = function()
    _G.LVIM_LINGUISTICS.mode_language.active = false
    autocmd.disable_insert_mode_language()
end

return M

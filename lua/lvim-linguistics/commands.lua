-- lvim-linguistics.commands: the :LvimLinguistics user command.
-- One command with subcommands that either open the settings panel on a given tab
-- or toggle a feature directly; <Tab> completion lists the subcommands.
--
---@module "lvim-linguistics.commands"

local ui = require("lvim-linguistics.ui")
local funcs = require("lvim-linguistics.funcs")

local M = {}

---@type table<string, fun():nil>  subcommand name -> handler
local subcommands = {
    ["spelling"] = function()
        ui.open(1)
    end,
    ["insert-mode"] = function()
        ui.open(2)
    end,
    ["config"] = function()
        ui.open(3)
    end,
    ["toggle-spelling"] = function()
        funcs.toggle_spelling()
    end,
    ["toggle-insert-mode"] = function()
        funcs.toggle_insert_mode_language()
    end,
}

--- Register the :LvimLinguistics user command (idempotent). With no argument it opens
--- the panel on its first tab; otherwise it dispatches the matching subcommand.
---@return nil
M.init_commands = function()
    vim.api.nvim_create_user_command("LvimLinguistics", function(opts)
        if opts.args == "" then
            ui.open()
            return
        end
        local fn = subcommands[opts.args]
        if fn then
            fn()
        else
            vim.notify("Unknown subcommand: " .. opts.args, vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        end
    end, {
        nargs = "?",
        complete = function()
            local keys = vim.tbl_keys(subcommands)
            table.sort(keys)
            return keys
        end,
    })
end

return M

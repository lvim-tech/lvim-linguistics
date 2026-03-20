local M = {}

local subcommands = {
    ["spelling"] = function()
        require("lvim-linguistics.ui").open(1)
    end,
    ["insert-mode"] = function()
        require("lvim-linguistics.ui").open(2)
    end,
    ["config"] = function()
        require("lvim-linguistics.ui").open(3)
    end,
    ["toggle-spelling"] = function()
        require("lvim-linguistics.funcs").toggle_spelling()
    end,
    ["toggle-insert-mode"] = function()
        require("lvim-linguistics.funcs").toggle_insert_mode_language()
    end,
}

M.init_commands = function()
    vim.api.nvim_create_user_command("LvimLinguistics", function(opts)
        if opts.args == "" then
            require("lvim-linguistics.ui").open()
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

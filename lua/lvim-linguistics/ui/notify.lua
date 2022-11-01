local notify = require("notify")

local M = {}

M.error = function(message)
    notify(message, "ERROR", {
        title = "LVIM LINGUISTICS",
    })
end

M.warning = function(message)
    notify(message, "WARN", {
        title = "LVIM LINGUISTICS",
    })
end

M.info = function(message)
    notify(message, "INFO", {
        title = "LVIM LINGUISTICS",
    })
end

return M

-- lvim-linguistics.utils: small filesystem/keymap helpers.
-- Reading/writing the project-local config (JSON <-> table) and the spell-file folder live
-- here. Config merging is NOT reimplemented — setup() uses the shared lvim-utils.utils.merge
-- (clean array REPLACE), so a user black_list replaces the default instead of being appended
-- to it.
--
-- Project-local config path: the config lives under the unified ".lvim/<plugin>/" project
-- namespace (".lvim/linguistics/config.json").
--
---@module "lvim-linguistics.utils"

local M = {}

local NEW_DIR_REL = "/.lvim/linguistics"
local NEW_REL = "/.lvim/linguistics/config.json"

--- Set a buffer/global keymap with `noremap` on by default.
---@param mode string|string[]  Mode(s), as accepted by vim.keymap.set
---@param lhs string            Left-hand side (the key sequence)
---@param rhs string|function   Right-hand side (command string or Lua callback)
---@param opts? vim.keymap.set.Opts  Extra options merged over { noremap = true }
---@return nil
M.map = function(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { noremap = true }, opts or {}))
end

--- Read a JSON file and decode it into a Lua table. Returns nil when the file is missing,
--- empty, or unreadable (so callers can fall back to the defaults).
---@param file string  Absolute path to the JSON file
---@return table?      The decoded table, or nil
M.read_file = function(file)
    local content
    local ok = pcall(function()
        content = vim.fn.readfile(file)
    end)
    if not ok or type(content) ~= "table" or next(content) == nil then
        return nil
    end
    local ok_decode, decoded = pcall(vim.json.decode, table.concat(content, "\n"))
    if not ok_decode or type(decoded) ~= "table" then
        vim.notify("Invalid lvim-linguistics config: " .. file, vim.log.levels.WARN, { title = "LVIM LINGUISTICS" })
        return nil
    end
    return decoded
end

--- Write `content` to `file`. A table is JSON-encoded first; a string is written as-is.
---@param file string        Absolute destination path
---@param content string|table  Payload (table is JSON-encoded)
---@return nil
M.write_file = function(file, content)
    if type(content) == "table" then
        content = vim.json.encode(content)
    end
    local tmp = file .. ".tmp"
    local f = io.open(tmp, "w")
    if f == nil then
        vim.notify("Cannot write " .. tmp, vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end
    f:write(content)
    f:close()
    local ok, err = os.rename(tmp, file)
    if not ok then
        os.remove(tmp)
        vim.notify(
            "Cannot replace " .. file .. ": " .. tostring(err),
            vim.log.levels.ERROR,
            { title = "LVIM LINGUISTICS" }
        )
    end
end

--- Delete a file.
---@param f string  Absolute path to remove
---@return nil
M.delete_file = function(f)
    os.remove(f)
end

--- Create a directory (and any missing parents).
---@param dirname string  Absolute directory path
---@return nil
M.create_dir = function(dirname)
    vim.fn.mkdir(dirname, "p")
end

--- Whether a path exists on disk.
---@param name string  Absolute path to test
---@return boolean     True if the path exists
M.exists = function(name)
    return vim.uv.fs_stat(name) ~= nil
end

--- Directory holding the project-local config under the unified ".lvim" namespace.
---@return string
M.project_dir = function()
    return vim.fn.getcwd() .. NEW_DIR_REL
end

--- The project-local config file (".lvim/linguistics/config.json").
---@return string
M.project_config_path = function()
    return vim.fn.getcwd() .. NEW_REL
end

return M

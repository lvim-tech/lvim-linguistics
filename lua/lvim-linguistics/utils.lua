-- lvim-linguistics.utils: small filesystem/keymap helpers.
-- Reading/writing the project-local .lvim_linguistics.json (JSON <-> table) and the
-- spell-file folder live here. Config merging is NOT reimplemented — setup() uses the
-- shared lvim-utils.utils.merge (clean array REPLACE), so a user black_list replaces the
-- default instead of being appended to it.
--
---@module "lvim-linguistics.utils"

local M = {}

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
    return vim.fn.json_decode(content)
end

--- Write `content` to `file`. A table is JSON-encoded first; a string is written as-is.
--- Silently no-ops if the file cannot be opened for writing.
---@param file string        Absolute destination path
---@param content string|table  Payload (table is JSON-encoded)
---@return nil
M.write_file = function(file, content)
    local f = io.open(file, "w")
    if f ~= nil then
        if type(content) == "table" then
            content = vim.fn.json_encode(content)
        end
        f:write(content)
        f:close()
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
    return (vim.uv or vim.loop).fs_stat(name) ~= nil
end

return M

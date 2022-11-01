local lunajson = require("lunajson")

local M = {}

M.merge = function(t1, t2)
    for k, v in pairs(t2) do
        if (type(v) == "table") and (type(t1[k] or false) == "table") then
            if M.is_array(t1[k]) then
                t1[k] = M.concat(t1[k], v)
            else
                M.merge(t1[k], t2[k])
            end
        else
            t1[k] = v
        end
    end
    return t1
end

M.concat = function(t1, t2)
    for i = 1, #t2 do
        table.insert(t1, t2[i])
    end
    return t1
end

M.is_array = function(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end
    return true
end

M.map = function(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

M.read_file = function(f, json_decode)
    local file = io.open(f, "rb")
    if not file then
        return nil
    end
    local file_content = file:read("*a")
    file:close()
    if json_decode then
        return lunajson.decode(file_content)
    end
    return file_content
end

M.write_file = function(f, content)
    local file = io.open(f, "w")
    if file ~= nil then
        file:write(content)
        file:close()
    end
end

M.create_dir = function(dirname)
    os.execute("mkdir " .. dirname)
end

M.exists = function(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

M.spelllangs = function()
    local file = io.open("./languages.txt", "r")
    if file ~= nil then
        --
    else
        --
    end
    file:close()
end

-- M.ignore_by_ft = function(ft)
--     for _, type in pairs(_G.LVIM_LINGUISTICS.spell.blacklist_ft) do
--         if type == ft then
--             return 1
--         end
--     end
-- end
--
-- M.ignore_by_bt = function(bt)
--     for _, type in pairs(_G.LVIM_LINGUISTICS.spell.blacklist_bt) do
--         if type == bt then
--             return 1
--         end
--     end
-- end
--
-- M.is_floating = function(window_id)
--     return vim.api.nvim_win_get_config(window_id).relative ~= ""
-- end

return M

local config = require("lvim-linguistics.config")
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

M.write_file = function(f, content, json_encode)
    local file = io.open(f, "w")
    if file ~= nil then
        if json_encode then
            content = lunajson.encode(content)
        end
        file:write(content)
        file:close()
    end
end

M.delete_file = function(f)
    os.remove(f)
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

return M

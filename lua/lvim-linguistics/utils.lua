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
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { noremap = true }, opts or {}))
end

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

M.delete_file = function(f)
    os.remove(f)
end

M.create_dir = function(dirname)
    vim.fn.mkdir(dirname, "p")
end

M.exists = function(name)
    return (vim.uv or vim.loop).fs_stat(name) ~= nil
end

return M

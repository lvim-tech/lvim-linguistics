local config = require("lvim-linguistics.config")
local utils = require("lvim-linguistics.utils")

local group_change_mode = vim.api.nvim_create_augroup("LvimLinguisticsChangeMode", { clear = true })
local group_spell_enabled = vim.api.nvim_create_augroup("LvimLinguisticsSpellEnabled", { clear = true })
local group_spell_disabled = vim.api.nvim_create_augroup("LvimLinguisticsSpellDisabled", { clear = true })

local M = {}

M.check_dir = function()
    if not utils.exists(config.plugin_config.spell_files_folder) then
        utils.create_dir(config.plugin_config.spell_files_folder)
    end
end

M.get_config = function()
    local local_config = utils.read_file(vim.fn.getcwd() .. "/.lvim_linguistics.json")
    if local_config then
        _G.LVIM_LINGUISTICS = local_config
    else
        _G.LVIM_LINGUISTICS = vim.deepcopy(config.base_config)
    end
end

M.insert_mode_language = function(language)
    _G.LVIM_LINGUISTICS.mode_language.insert_mode_language = language
end

M.enable_insert_mode_language = function()
    local cfg = _G.LVIM_LINGUISTICS.mode_language
    if type(cfg.normal_mode_language) ~= "string" or type(cfg.insert_mode_language) ~= "string" then
        vim.notify("Invalid insert/normal mode language definitions", vim.log.levels.ERROR, {
            title = "LVIM LINGUISTICS",
        })
        return
    end
    cfg.active = true
    local function set_kbrd(lang)
        pcall(function()
            local cmd = config.plugin_config.kbrd_cmd
            local full_cmd
            if type(cmd) == "function" then
                full_cmd = cmd(lang)
            else
                full_cmd = cmd .. lang
            end
            os.execute(full_cmd .. " > /dev/null 2>&1")
        end)
    end
    vim.api.nvim_create_autocmd("InsertEnter", {
        pattern = "*",
        callback = function()
            if not vim.tbl_contains(cfg.file_types.black_list, vim.bo.filetype) then
                set_kbrd(cfg.insert_mode_language)
            end
        end,
        group = group_change_mode,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        pattern = "*",
        callback = function()
            if not vim.tbl_contains(cfg.file_types.black_list, vim.bo.filetype) then
                set_kbrd(cfg.normal_mode_language)
            end
        end,
        group = group_change_mode,
    })
end

M.disable_insert_mode_language = function()
    _G.LVIM_LINGUISTICS.mode_language.active = false
    pcall(function()
        for _, ac in ipairs(vim.api.nvim_get_autocmds({ group = group_change_mode })) do
            vim.api.nvim_del_autocmd(ac.id)
        end
    end)
end

M.toggle_insert_mode_language = function()
    if _G.LVIM_LINGUISTICS.mode_language.active then
        M.disable_insert_mode_language()
        vim.notify("Insert mode language disabled", vim.log.levels.INFO)
    else
        M.enable_insert_mode_language()
        vim.notify("Insert mode language enabled", vim.log.levels.INFO)
    end
end

local function ensure_dictionary(lang_code, target_path, on_ready)
    if vim.fn.filereadable(target_path) == 1 then
        if on_ready then
            on_ready()
        end
        return
    end
    local url = string.format("https://ftp.nluug.nl/vim/runtime/spell/%s.utf-8.spl", lang_code)
    vim.notify("Downloading dictionary: " .. lang_code, vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
    vim.fn.jobstart({ "curl", "-fsSL", url, "-o", target_path }, {
        on_exit = function(_, code)
            vim.schedule(function()
                if code == 0 then
                    vim.notify("Dictionary ready: " .. lang_code, vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
                    if on_ready then
                        on_ready()
                    end
                else
                    vim.notify(
                        "Failed to download dictionary: " .. lang_code,
                        vim.log.levels.ERROR,
                        { title = "LVIM LINGUISTICS" }
                    )
                end
            end)
        end,
    })
end

M.enable_spelling = function()
    local spell_cfg = _G.LVIM_LINGUISTICS.spell
    local lang_key = spell_cfg.language
    if not lang_key or type(lang_key) ~= "string" then
        vim.notify("Not defined language(s)", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end
    local lang_info = spell_cfg.languages[lang_key]
    if not lang_info then
        vim.notify("Not defined settings for: " .. lang_key, vim.log.levels.ERROR)
        return
    end
    local spelllang = lang_info.spelllang
    local spellfile = lang_info.spellfile or "global.add"
    if not spelllang then
        vim.notify("Invalid spelllang for: " .. lang_key, vim.log.levels.ERROR)
        return
    end
    local folder = config.plugin_config.spell_files_folder
    local dict_path = folder .. "/" .. spelllang .. ".utf-8.spl"
    local function spell()
        local ft = vim.bo.filetype
        if not vim.tbl_contains(spell_cfg.file_types.black_list, ft) then
            vim.cmd(string.format("setlocal spell spelllang=%s spellfile=%s/%s", spelllang, folder, spellfile))
            spell_cfg.active = true
        end
    end
    ensure_dictionary(spelllang, dict_path, spell)
    vim.api.nvim_clear_autocmds({ group = group_spell_enabled })
    vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
        callback = spell,
        group = group_spell_enabled,
    })
    vim.api.nvim_clear_autocmds({ group = group_spell_disabled })
end

M.disable_spelling = function()
    vim.cmd("setlocal nospell")
    vim.api.nvim_clear_autocmds({ group = group_spell_enabled })
    vim.api.nvim_clear_autocmds({ group = group_spell_disabled })
    vim.api.nvim_create_autocmd("WinEnter", {
        callback = function()
            vim.cmd("setlocal nospell")
        end,
        group = group_spell_disabled,
    })
    _G.LVIM_LINGUISTICS.spell.active = false
end

M.toggle_spelling = function()
    if _G.LVIM_LINGUISTICS.spell.active then
        M.disable_spelling()
        vim.notify("Spelling disabled", vim.log.levels.INFO)
    else
        M.enable_spelling()
        vim.notify("Spelling enabled: (" .. _G.LVIM_LINGUISTICS.spell.language .. ")", vim.log.levels.INFO)
    end
end

M.process = function()
    if type(_G.LVIM_LINGUISTICS) ~= "table" then
        return
    end
    local cfg = _G.LVIM_LINGUISTICS
    if cfg.mode_language.active then
        M.enable_insert_mode_language()
    end
    if cfg.spell.active then
        M.enable_spelling()
    end
end

M.change_spell_language = function(language)
    if not language or type(language) ~= "string" then
        vim.notify("Invalid spell language", vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end
    if not _G.LVIM_LINGUISTICS.spell.languages[language] then
        vim.notify("Unknown spell language: " .. language, vim.log.levels.ERROR, { title = "LVIM LINGUISTICS" })
        return
    end
    _G.LVIM_LINGUISTICS.spell.language = language
    vim.notify("Spell language changed to: " .. language, vim.log.levels.INFO, { title = "LVIM LINGUISTICS" })
    if _G.LVIM_LINGUISTICS.spell.active then
        M.enable_spelling()
    end
end

return M

-- Which buffers a feature may engage in.
--
-- The two allow-lists are not ordered against each other -- they are COMPARED, by how
-- specifically each claims the buffer's type -- so that `"*"` reads as a blanket and a named type
-- as an exception to it, in BOTH directions:
--
--     black_list = { "*" }, white_list = { "tex" }   -- nothing, except TeX
--     white_list = { "*" }, black_list = { "tex" }   -- everything, except TeX
--
-- A fixed "black first" or "white first" order can only ever express one of those. On an equal
-- claim the black list wins, because a gate that cannot decide should stay shut.
--
-- Underneath sits a structural rule with a measured history: when neither list mentions 'buftype',
-- only real FILES are eligible. Keying on filetype NAMES instead meant the black list had to
-- enumerate every UI in the editor, and enabling spelling underlined the file tree, the
-- control-center popup and every installer prompt.
--
-- The gate is reached the way a user reaches it -- through enable_spelling, with the dictionary
-- already on disk so nothing is downloaded -- and read back off the window option it sets.

local funcs = require("lvim-linguistics.funcs")
local config = require("lvim-linguistics.config")
local state = require("lvim-linguistics.state")

local folder = config.plugin_config.spell_files_folder
local sandbox = vim.env.LVIM_TEST_HOME
local safe = sandbox and sandbox ~= "" and vim.startswith(vim.fs.normalize(folder), vim.fs.normalize(sandbox))

-- The folder comes from `stdpath("config")`, which `make test` redirects, so writing a dictionary
-- here cannot reach the real editor's own. If that ever stops being true the suite refuses rather
-- than writing into somebody's config.
if not safe then
    describe("lvim-linguistics: the filetype gate")
    skip(
        "the filetype gate",
        "the spell folder is " .. tostring(folder) .. ", which is outside the sandbox -- refusing to write there"
    )
    return
end

--- Put a dictionary where the plugin looks for one, so ensure_dictionary returns at once instead
--- of reaching for the network.
---@param spelllang string
local function dictionary_for(spelllang)
    vim.fn.mkdir(folder, "p")
    for _, lang in ipairs(vim.split(spelllang, ",", { plain = true, trimempty = true })) do
        local path = folder .. "/" .. lang .. ".utf-8.spl"
        if vim.fn.filereadable(path) ~= 1 then
            vim.fn.writefile({ "" }, path)
        end
    end
end

--- Point the live state at a language and a type gate, with the dictionary in place.
---@param file_types table
local function gate(file_types)
    funcs.get_config()
    state.config.spell.language = "en"
    state.config.spell.languages = { en = { spelllang = "en", spellfile = "en.add" } }
    state.config.spell.file_types = file_types
    dictionary_for("en")
end

--- Is 'spell' on for a buffer of this filetype and buftype, with the gate as configured?
---@param file_types table
---@param ft string
---@param bt? string
---@return boolean
local function spells(file_types, ft, bt)
    gate(file_types)
    vim.cmd("enew!")
    if bt and bt ~= "" then
        vim.bo.buftype = bt
    end
    vim.bo.filetype = ft
    local ok = funcs.enable_spelling()
    truthy(ok, "enable_spelling declined; the dictionary or the language is not set up")
    return vim.wo.spell
end

describe("lvim-linguistics: where the dictionaries live")

it("the spell folder follows the config that is actually running", function()
    -- Neovim looks for a `spell/` directory on the runtimepath, and stdpath("config") is on it.
    -- A hardcoded $HOME/.config/nvim ignored $XDG_CONFIG_HOME and $NVIM_APPNAME, so the downloaded
    -- .spl and the user's added-words file went to a directory the running config never reads.
    eq(vim.fn.stdpath("config") .. "/spell", folder)
    truthy(safe, "and under `make test` that is inside the sandbox, which is why this file can run")
end)

describe("lvim-linguistics: the filetype gate")

it("a real file of an unlisted filetype is spell checked", function()
    eq(true, spells({ black_list = {}, white_list = {} }, "text"))
end)

it("a black-listed filetype is not", function()
    eq(false, spells({ black_list = { "log" }, white_list = {} }, "log"))
    eq(true, spells({ black_list = { "log" }, white_list = {} }, "text"), "and its neighbours still are")
end)

it("a white list narrows the gate to what it names", function()
    eq(true, spells({ black_list = {}, white_list = { "tex" } }, "tex"))
    eq(
        false,
        spells({ black_list = {}, white_list = { "tex" } }, "text"),
        "an allow-list that is ignored for other filetypes is not an allow-list"
    )
end)

it("nothing, except TeX", function()
    local ft = { black_list = { "*" }, white_list = { "tex" } }
    eq(true, spells(ft, "tex"), "the exact name beats the blanket")
    eq(false, spells(ft, "text"))
    eq(false, spells(ft, "markdown"))
end)

it("everything, except TeX", function()
    local ft = { black_list = { "tex" }, white_list = { "*" } }
    eq(false, spells(ft, "tex"), "the exact name beats the blanket on the other side too")
    eq(true, spells(ft, "text"))
    eq(true, spells(ft, "markdown"))
end)

it("an equal claim keeps the gate shut", function()
    eq(false, spells({ black_list = { "*" }, white_list = { "*" } }, "text"), "two blankets cannot decide")
    eq(false, spells({ black_list = { "tex" }, white_list = { "tex" } }, "tex"), "nor can two exact names")
end)

it("a bare string is the filetype axis", function()
    eq(false, spells({ black_list = "text", white_list = {} }, "text"))
    eq(true, spells({ black_list = "text", white_list = {} }, "tex"))
end)

describe("lvim-linguistics: only real files, unless asked otherwise")

it("a UI buffer is never spell checked, whatever its filetype says", function()
    -- 'buftype' cannot be ASSIGNED the value "terminal" (E474) -- only :terminal produces it -- so
    -- the settable ones stand in for the whole class.
    for _, bt in ipairs({ "nofile", "nowrite", "acwrite", "prompt", "quickfix", "help" }) do
        eq(
            false,
            spells({ black_list = {}, white_list = {} }, "text", bt),
            ("a %s buffer is not a file the user is writing"):format(bt)
        )
    end
end)

it("a white-listed filetype in a UI buffer is still refused", function()
    -- This is the shape of the defect the structural rule exists for: a panel whose filetype
    -- happens to be allowed would otherwise be underlined.
    eq(false, spells({ black_list = {}, white_list = { "text" } }, "text", "nofile"))
end)

it("naming the buftype axis replaces the structural rule", function()
    local ft = { black_list = {}, white_list = { bt = { "nofile" }, ft = { "*" } } }
    eq(true, spells(ft, "text", "nofile"), "for whoever does want spelling in a scratch buffer")
    eq(false, spells(ft, "text", "prompt"), "and only in the buftype they named")
    eq(false, spells(ft, "text", ""), "not even a real file, when the axis names only nofile")
end)

describe("lvim-linguistics: the option is owned on both sides")

it("a window that stops showing an allowed filetype stops spell checking", function()
    -- 'spell' is a WINDOW option, so it outlives the buffer that earned it. Only ever switching it
    -- ON left a window that had once shown an allowed filetype checking whatever came next -- a
    -- white_list of { "tex" } underlined the .editorconfig opened in the TeX window.
    local ft = { black_list = {}, white_list = { "tex" } }
    eq(true, spells(ft, "tex"), "precondition: the window is checking")

    vim.bo.filetype = "text"
    vim.cmd("doautocmd BufEnter")
    eq(false, vim.wo.spell, "the same window, a filetype the list does not allow")
end)

it("disabling clears the option", function()
    eq(true, spells({ black_list = {}, white_list = {} }, "text"))
    funcs.disable_spelling()
    eq(false, vim.wo.spell)
end)

describe("lvim-linguistics: layering the configuration")

it("a partial layer overrides only its own keys", function()
    funcs.get_config()
    local defaults = vim.deepcopy(state.config)
    truthy(defaults.spell, "precondition: there is a spell block to layer over")

    -- The project-local layer is the same shape as the global one, so one merge covers both.
    local project = vim.fn.tempname() .. "/project"
    vim.fn.mkdir(project .. "/.lvim/linguistics", "p")
    vim.fn.writefile({
        vim.json.encode({ spell = { file_types = { black_list = { "only-this" } } } }),
    }, project .. "/.lvim/linguistics/config.json")

    local cwd = vim.fn.getcwd()
    vim.cmd("silent! cd " .. vim.fn.fnameescape(project))
    funcs.get_config()
    local layered = state.config
    vim.cmd("silent! cd " .. vim.fn.fnameescape(cwd))

    eq({ "only-this" }, layered.spell.file_types.black_list, "the override list IS the list, not merged into it")
    eq(
        defaults.spell.languages,
        layered.spell.file_types.black_list and layered.spell.languages,
        "a key the layer omits keeps the value below it"
    )
end)

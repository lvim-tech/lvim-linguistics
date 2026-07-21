-- lvim-linguistics.store: persistence for the GLOBAL panel settings.
--
-- Bound (via `M.bind`, from panel.setup) to the settings panel's lvim-control-center instance
-- data — so the global default lives in that instance's database. `funcs.get_config` overlays
-- these values onto `base_config`; a project-local `.lvim/linguistics/config.json` overrides them per
-- directory. No-op until bound (control-center absent) — the plugin then falls back to
-- base_config + the project file, exactly as before.
--
---@module "lvim-linguistics.store"

local M = {}

---@type LvimControlCenterData? the panel instance's database persistence (set by panel.setup)
local data = nil

--- Bind the store to the panel instance's data. Called once, from panel.setup.
---@param instance_data LvimControlCenterData
function M.bind(instance_data)
    data = instance_data
end

--- Persist a global panel setting (no-op until bound).
---@param name string
---@param value any
function M.save(name, value)
    if data then
        pcall(function()
            data:save(name, value)
        end)
    end
end

--- Read a global panel setting, or nil when unset / not bound.
---@param name string
---@return any
function M.load(name)
    if data then
        local ok, val = pcall(function()
            return data:load(name)
        end)
        if ok then
            return val
        end
    end
    return nil
end

return M

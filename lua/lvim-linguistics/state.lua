-- lvim-linguistics.state: runtime state — the ACTIVE spelling / insert-mode profile in
-- effect for the current working directory. Loaded by funcs.get_config() either from a
-- project-local .lvim_linguistics.json or as a deep copy of config.base_config, then
-- MUTATED at runtime (active toggles, language changes). This is deliberately separate
-- from config.lua: config.lua holds the immutable DEFAULTS; state.lua holds the live,
-- per-cwd runtime values (previously a global _G.LVIM_LINGUISTICS).
--
---@module "lvim-linguistics.state"

local M = {
    ---@type LvimLinguisticsBaseConfig?
    config = nil,
}

return M

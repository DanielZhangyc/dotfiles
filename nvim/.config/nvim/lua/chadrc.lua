---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "catppuccin",
  transparency = true,
}

M.mason = {
  pkgs = {
    "rust-analyzer",
    "clangd",
    "ruff",
    "ty",
    "texlab",
  },
}

M.ui = {
  statusline = {
    theme = "vscode_colored",
  },
}

return M

require "nvchad.mappings"

local map = vim.keymap.set
local smart_splits = require "smart-splits"

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Seamless navigation and resizing across Neovim and Kitty splits.
map({ "n", "t" }, "<C-h>", smart_splits.move_cursor_left, { desc = "Window left" })
map({ "n", "t" }, "<C-j>", smart_splits.move_cursor_down, { desc = "Window down" })
map({ "n", "t" }, "<C-k>", smart_splits.move_cursor_up, { desc = "Window up" })
map({ "n", "t" }, "<C-l>", smart_splits.move_cursor_right, { desc = "Window right" })

map({ "n", "t" }, "<A-h>", smart_splits.resize_left, { desc = "Resize window left" })
map({ "n", "t" }, "<A-j>", smart_splits.resize_down, { desc = "Resize window down" })
map({ "n", "t" }, "<A-k>", smart_splits.resize_up, { desc = "Resize window up" })
map({ "n", "t" }, "<A-l>", smart_splits.resize_right, { desc = "Resize window right" })

-- Regular editor splits (in nvim-tree these keys open the selected file).
map("n", "<leader>h", "<cmd>split<CR>", { desc = "Window split horizontal" })
map("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Window split vertical" })

-- Terminal toggles under the <leader>t namespace.
map("n", "<leader>th", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "Terminal toggle horizontal" })

map("n", "<leader>tv", function()
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "Terminal toggle vertical" })

map("n", "<leader>tf", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "Terminal toggle floating" })

pcall(vim.keymap.del, { "n", "t" }, "<A-v>")
pcall(vim.keymap.del, { "n", "t" }, "<A-i>")

require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

local tabufline = require "nvchad.tabufline"

if not tabufline.close_without_empty_buffer then
  local close_buffer = tabufline.close_buffer

  tabufline.close_buffer = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local file_buffers = vim.tbl_filter(function(buf)
      return vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_get_option_value("buflisted", { buf = buf })
        and vim.api.nvim_get_option_value("buftype", { buf = buf }) == ""
        and vim.api.nvim_buf_get_name(buf) ~= ""
    end, vim.t.bufs or {})

    if #file_buffers == 1 and file_buffers[1] == bufnr then
      vim.cmd("confirm bdelete " .. bufnr)

      local was_deleted = not vim.api.nvim_buf_is_valid(bufnr)
        or not vim.api.nvim_get_option_value("buflisted", { buf = bufnr })

      if not was_deleted then
        return
      end

      vim.cmd.redrawtabline()
      return
    end

    close_buffer(bufnr)
  end

  tabufline.close_without_empty_buffer = true
end

local smart_splits = require "smart-splits"

-- Seamless navigation between Neovim windows and tmux panes.
map("n", "<C-h>", smart_splits.move_cursor_left, { desc = "Window left" })
map("n", "<C-j>", smart_splits.move_cursor_down, { desc = "Window down" })
map("n", "<C-k>", smart_splits.move_cursor_up, { desc = "Window up" })
map("n", "<C-l>", smart_splits.move_cursor_right, { desc = "Window right" })

-- Create regular editor splits. In nvim-tree these keys open the selected file.
map("n", "<leader>h", "<cmd>split<CR>", { desc = "Window split horizontal" })
map("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Window split vertical" })

-- Hold Option-h/j/k/l to continuously resize Neovim windows or tmux panes.
map({ "n", "t" }, "<A-h>", smart_splits.resize_left, { desc = "Resize window left" })
map({ "n", "t" }, "<A-j>", smart_splits.resize_down, { desc = "Resize window down" })
map({ "n", "t" }, "<A-k>", smart_splits.resize_up, { desc = "Resize window up" })
map({ "n", "t" }, "<A-l>", smart_splits.resize_right, { desc = "Resize window right" })

-- Keep all terminal toggles under the leader+t namespace.
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

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

require "nvchad.autocmds"

local function listed_file_buffers()
  return vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_get_option_value("buflisted", { buf = buf })
      and vim.api.nvim_get_option_value("buftype", { buf = buf }) == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
  end, vim.t.bufs or {})
end

-- Avoid creating an empty buffer when closing the last file via tabufline.
local tabufline = require "nvchad.tabufline"
if not tabufline.close_without_empty_buffer then
  local close_buffer = tabufline.close_buffer
  tabufline.close_buffer = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local files = listed_file_buffers()
    if #files == 1 and files[1] == bufnr then
      vim.cmd("confirm bdelete " .. bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_get_option_value("buflisted", { buf = bufnr }) then
        vim.cmd.redrawtabline()
      end
      return
    end
    close_buffer(bufnr)
  end
  tabufline.close_without_empty_buffer = true
end

-- When the last real file buffer closes, focus nvim-tree and close empty editors.
vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("CloseEmptyEditorAfterLastBuffer", { clear = true }),
  callback = function(event)
    if event.file == "" or vim.fn.isdirectory(event.file) == 1 then
      return
    end
    local ok, buftype = pcall(vim.api.nvim_get_option_value, "buftype", { buf = event.buf })
    if ok and buftype ~= "" then
      return
    end

    vim.schedule(function()
      local tabpage = vim.api.nvim_get_current_tabpage()
      if not vim.api.nvim_tabpage_is_valid(tabpage) or #listed_file_buffers() > 0 then
        return
      end

      local function scan_windows()
        local tree_win
        local empty = {}
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
          local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
          if ft == "NvimTree" then
            tree_win = win
          elseif
            bt == ""
            and vim.api.nvim_buf_get_name(buf) == ""
            and not vim.api.nvim_get_option_value("modified", { buf = buf })
          then
            table.insert(empty, { win = win, buf = buf })
          end
        end
        return tree_win, empty
      end

      local tree_win, empty = scan_windows()
      if not tree_win then
        require("lazy").load { plugins = { "nvim-tree.lua" } }
        require("nvim-tree.api").tree.open()
        tree_win, empty = scan_windows()
      end

      for _, editor in ipairs(empty) do
        if vim.api.nvim_win_is_valid(editor.win) and #vim.api.nvim_tabpage_list_wins(tabpage) > 1 then
          vim.api.nvim_win_close(editor.win, false)
        end
        if vim.api.nvim_buf_is_valid(editor.buf) and #vim.fn.win_findbuf(editor.buf) == 0 then
          vim.api.nvim_buf_delete(editor.buf, {})
        end
      end

      if tree_win and vim.api.nvim_win_is_valid(tree_win) then
        vim.api.nvim_set_current_win(tree_win)
      end
    end)
  end,
})

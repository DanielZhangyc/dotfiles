require "nvchad.autocmds"

local group = vim.api.nvim_create_augroup("CloseEmptyEditorAfterLastBuffer", { clear = true })

vim.api.nvim_create_autocmd("BufDelete", {
  group = group,
  callback = function(event)
    if event.file == "" or vim.fn.isdirectory(event.file) == 1 then
      return
    end

    local has_buftype, buftype = pcall(vim.api.nvim_get_option_value, "buftype", { buf = event.buf })
    if has_buftype and buftype ~= "" then
      return
    end

    vim.schedule(function()
      local tabpage = vim.api.nvim_get_current_tabpage()
      if not vim.api.nvim_tabpage_is_valid(tabpage) then
        return
      end

      for _, buf in ipairs(vim.t.bufs or {}) do
        if
          vim.api.nvim_buf_is_valid(buf)
          and vim.api.nvim_get_option_value("buflisted", { buf = buf })
          and vim.api.nvim_get_option_value("buftype", { buf = buf }) == ""
          and vim.api.nvim_buf_get_name(buf) ~= ""
        then
          return
        end
      end

      local function editor_windows()
        local tree_win
        local empty_editors = {}

        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
          local buf = vim.api.nvim_win_get_buf(win)
          local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
          local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })

          if filetype == "NvimTree" then
            tree_win = win
          elseif
            buftype == ""
            and vim.api.nvim_buf_get_name(buf) == ""
            and not vim.api.nvim_get_option_value("modified", { buf = buf })
          then
            table.insert(empty_editors, { win = win, buf = buf })
          end
        end

        return tree_win, empty_editors
      end

      local tree_win, empty_editors = editor_windows()

      if not tree_win then
        require("lazy").load { plugins = { "nvim-tree.lua" } }
        require("nvim-tree.api").tree.open()
        tree_win, empty_editors = editor_windows()
      end

      for _, editor in ipairs(empty_editors) do
        if vim.api.nvim_win_is_valid(editor.win) and #vim.api.nvim_tabpage_list_wins(tabpage) > 1 then
          vim.api.nvim_win_close(editor.win, false)
        end

        if vim.api.nvim_buf_is_valid(editor.buf) and #vim.fn.win_findbuf(editor.buf) == 0 then
          vim.api.nvim_buf_delete(editor.buf, {})
        end
      end

      if vim.api.nvim_win_is_valid(tree_win) then
        vim.api.nvim_set_current_win(tree_win)
      end
    end)
  end,
})

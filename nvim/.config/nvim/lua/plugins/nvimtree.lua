return {
  {
    "nvim-tree/nvim-tree.lua",
    init = function()
      local group = vim.api.nvim_create_augroup("NvimTreeDirectoryStartup", { clear = true })

      vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = function(event)
          if event.file == "" or vim.fn.isdirectory(event.file) ~= 1 then
            return
          end

          local directory = vim.fn.fnamemodify(event.file, ":p")

          -- Keep the initial directory buffer valid. NvChad's tabufline may
          -- still reference it when the first file is opened.
          vim.cmd.cd(vim.fn.fnameescape(directory))

          require("lazy").load { plugins = { "nvim-tree.lua" } }
          require("nvim-tree.api").tree.open { path = directory }
        end,
      })
    end,
    opts = function(_, opts)
      opts.filters = opts.filters or {}
      opts.filters.git_ignored = false

      opts.actions = opts.actions or {}
      opts.actions.open_file = opts.actions.open_file or {}
      opts.actions.open_file.window_picker = {
        enable = false,
      }

      opts.on_attach = function(bufnr)
        local api = require "nvim-tree.api"
        local smart_splits = require "smart-splits"

        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, {
            buffer = bufnr,
            desc = "nvim-tree: " .. desc,
            noremap = true,
            nowait = true,
            silent = true,
          })
        end

        api.map.on_attach.default(bufnr)

        -- Replace nvim-tree's unique split keys with the global h/v scheme.
        vim.keymap.del("n", "<C-x>", { buffer = bufnr })
        vim.keymap.del("n", "<C-v>", { buffer = bufnr })
        map("<leader>h", api.node.open.horizontal, "Open: Horizontal Split")
        map("<leader>v", api.node.open.vertical, "Open: Vertical Split")

        -- Buffer-local defaults must not shadow seamless window navigation.
        map("<C-h>", smart_splits.move_cursor_left, "Window Left")
        map("<C-j>", smart_splits.move_cursor_down, "Window Down")
        map("<C-k>", smart_splits.move_cursor_up, "Window Up")
        map("<C-l>", smart_splits.move_cursor_right, "Window Right")
        map("gK", api.node.show_info_popup, "Info")
      end
    end,
  },
}

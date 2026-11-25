return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    build = function(plugin)
      local result = vim.system({ "bash", "kitty/install-kittens.bash" }, { cwd = plugin.dir }):wait()
      assert(result.code == 0, result.stderr)
    end,
    opts = {
      at_edge = "stop",
      default_amount = 2,
      disable_multiplexer_nav_when_zoomed = true,
      multiplexer_integration = vim.env.KITTY_WINDOW_ID and vim.env.KITTY_LISTEN_ON and "kitty" or false,
    },
    config = function(_, opts)
      if opts.multiplexer_integration == "kitty" then
        require("configs.smart_splits_kitty").setup()
      end
      require("smart-splits").setup(opts)
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("NvimTreeDirectoryStartup", { clear = true }),
        once = true,
        callback = function(event)
          if event.file == "" or vim.fn.isdirectory(event.file) ~= 1 then
            return
          end
          local directory = vim.fn.fnamemodify(event.file, ":p")
          vim.cmd.cd(vim.fn.fnameescape(directory))
          require("lazy").load { plugins = { "nvim-tree.lua" } }
          require("nvim-tree.api").tree.open { path = directory }
        end,
      })
    end,
    opts = function(_, opts)
      opts.filters = vim.tbl_extend("force", opts.filters or {}, { git_ignored = false })
      opts.actions = vim.tbl_deep_extend("force", opts.actions or {}, {
        open_file = { window_picker = { enable = false } },
      })

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

        vim.keymap.del("n", "<C-x>", { buffer = bufnr })
        vim.keymap.del("n", "<C-v>", { buffer = bufnr })
        map("<leader>h", api.node.open.horizontal, "Open: Horizontal Split")
        map("<leader>v", api.node.open.vertical, "Open: Vertical Split")

        map("<C-h>", smart_splits.move_cursor_left, "Window Left")
        map("<C-j>", smart_splits.move_cursor_down, "Window Down")
        map("<C-k>", smart_splits.move_cursor_up, "Window Up")
        map("<C-l>", smart_splits.move_cursor_right, "Window Right")
        map("gK", api.node.show_info_popup, "Info")
      end
    end,
  },
}

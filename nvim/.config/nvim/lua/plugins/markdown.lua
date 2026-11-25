return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      latex = { enabled = false },
      win_options = {
        conceallevel = { rendered = 2 },
        concealcursor = { rendered = "" },
      },
    },
  },

  {
    "3rd/image.nvim",
    ft = { "markdown" },
    build = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown" },
        },
        asciidoc = { enabled = false },
        neorg = { enabled = false },
        syslang = { enabled = false },
        typst = { enabled = false },
      },
      max_width = 80,
      max_height = 40,
      max_height_window_percentage = 50,
      window_overlap_clear_enabled = true,
      editor_only_render_when_focused = true,
    },
    config = function(_, opts)
      require("configs.markdown_image_layout").setup()
      require("image").setup(opts)
    end,
    keys = {
      {
        "<leader>it",
        function()
          local image = require "image"
          if image.is_enabled() then
            image.disable()
          else
            image.enable()
          end
        end,
        desc = "Toggle inline images",
      },
    },
  },

  {
    "techwizrd/render-latex.nvim",
    tag = "v0.1.0-rc4",
    ft = { "markdown" },
    dependencies = { "3rd/image.nvim" },
    opts = {
      install = {
        auto = false,
        version = "v0.1.0-rc4",
      },
      image = { backend = "kitty" },
      render_modes = { "n" },
      render = {
        preset = "match_text",
        inline = "conceal",
        inline_symbols = true,
        equation_labels = false,
      },
      integrations = { jupynvim = { enabled = false } },
    },
    config = function(_, opts)
      if #vim.api.nvim_list_uis() > 0 then
        local terminal = assert(require("image/utils/term").get_size(), "terminal cell dimensions unavailable")
        opts.image.cell_width_px = terminal.cell_width
        opts.image.cell_height_px = terminal.cell_height
      end
      require("configs.render_latex_image").setup()
      require("render_latex").setup(opts)
      require("configs.render_latex_mode").setup()
      vim.api.nvim_create_autocmd("VimResized", {
        group = vim.api.nvim_create_augroup("RenderLatexCellSize", { clear = true }),
        callback = function()
          local terminal = assert(require("image/utils/term").get_size(), "terminal cell dimensions unavailable")
          local config = require "render_latex.config"
          if
            config.image.cell_width_px ~= terminal.cell_width
            or config.image.cell_height_px ~= terminal.cell_height
          then
            config.image.cell_width_px = terminal.cell_width
            config.image.cell_height_px = terminal.cell_height
            require("render_latex.renderer").clear_all()
            require("render_latex").refresh()
          end
        end,
      })
    end,
    keys = {
      { "<leader>le", "<cmd>RenderLatex equation_toggle<cr>", desc = "Toggle equation source" },
      { "<leader>lr", "<cmd>RenderLatex refresh<cr>", desc = "Refresh equations" },
    },
  },

  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  },
}

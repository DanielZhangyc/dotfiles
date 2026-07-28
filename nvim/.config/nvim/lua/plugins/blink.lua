vim.g.vscode_snippets_path = vim.fn.stdpath "config" .. "/snippets"
vim.g.vscode_snippets_exclude = { "cpp", "tex", "plaintex", "bib", "bibtex" }

return {
  { import = "nvchad.blink.lazyspec" },

  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "xzbdmw/colorful-menu.nvim",
        opts = {},
      },
    },
    opts = {
      cmdline = {
        completion = {
          menu = {
            auto_show = true,
          },
        },
      },
      completion = {
        menu = {
          draw = {
            columns = {
              { "kind_icon" },
              { "label", gap = 1 },
            },
            components = {
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
            },
          },
        },
      },
      keymap = {
        ["<Tab>"] = {
          "snippet_forward",
          "select_next",
          "fallback",
        },
        ["<S-Tab>"] = {
          "snippet_backward",
          "select_prev",
          "fallback",
        },
        ["<C-x><C-s>"] = {
          function(cmp)
            return cmp.show { providers = { "snippets" } }
          end,
        },
      },
    },
  },
}

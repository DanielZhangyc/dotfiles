vim.g.vscode_snippets_path = vim.fn.stdpath "config" .. "/snippets"
vim.g.vscode_snippets_exclude = { "cpp", "tex", "plaintex", "bib", "bibtex" }

local function clangd_for_signature(item)
  if
    item.client_name ~= "clangd"
    or item.kind ~= vim.lsp.protocol.CompletionItemKind.Snippet
    or type(item.label) ~= "string"
    or vim.trim(item.label) ~= "for"
  then
    return
  end

  local new_text = type(item.textEdit) == "table" and item.textEdit.newText
    or item.textEditText
    or item.insertText
    or ""

  if type(new_text) ~= "string" then
    return
  elseif new_text:find(";", 1, true) then
    return "(init; cond; step)"
  elseif new_text:find(":", 1, true) then
    return "(item : range)"
  end
end

return {
  { import = "nvchad.blink.lazyspec" },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()

      local servers = {
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
              check = { command = "clippy" },
            },
          },
        },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=iwyu",
            "--query-driver=/opt/homebrew/bin/gcc-16,/opt/homebrew/bin/g++-16",
          },
        },
        ruff = {
          on_attach = function(client)
            -- Let ty handle Python hover; keep Ruff for diagnostics, actions, and formatting.
            client.server_capabilities.hoverProvider = false
          end,
        },
        ty = {},
        texlab = {
          settings = {
            texlab = {
              build = {
                executable = "latexmk",
                args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                onSave = false,
                forwardSearchAfter = false,
              },
              chktex = { onOpenAndSave = true, onEdit = false },
              latexFormatter = "latexindent",
            },
          },
        },
      }

      for name, opts in pairs(servers) do
        vim.lsp.config(name, opts)
        vim.lsp.enable(name)
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        tex = { "tex-fmt" },
      },
      format_on_save = {
        timeout_ms = 1000,
        lsp_format = "fallback",
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "markdown",
        "markdown_inline",
        "latex",
      })
    end,
  },

  {
    "saghen/blink.cmp",
    dependencies = {
      { "xzbdmw/colorful-menu.nvim", opts = {} },
    },
    opts = {
      cmdline = {
        keymap = { ["<Tab>"] = { "show", "accept" } },
        completion = { menu = { auto_show = true } },
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
                  local label = require("colorful-menu").blink_components_text(ctx)
                  local signature = clangd_for_signature(ctx.item)
                  return signature and vim.trim(ctx.item.label) .. " " .. signature or label
                end,
                highlight = function(ctx)
                  local signature = clangd_for_signature(ctx.item)
                  if not signature then
                    return require("colorful-menu").blink_components_highlight(ctx)
                  end
                  return {
                    { 0, 3, group = "BlinkCmpLabelMatch" },
                    { 4, #signature + 4, group = "BlinkCmpLabelDescription" },
                  }
                end,
              },
            },
          },
        },
      },
      keymap = {
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
        ["<C-x><C-s>"] = {
          function(cmp)
            return cmp.show { providers = { "snippets" } }
          end,
        },
      },
    },
  },
}

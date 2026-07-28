require("nvchad.configs.lspconfig").defaults()

local servers = {
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
        },
        check = {
          command = "clippy",
        },
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
      -- ty provides richer Python language features; keep Ruff focused on
      -- diagnostics, code actions, import organization, and formatting.
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
        chktex = {
          onOpenAndSave = true,
          onEdit = false,
        },
        latexFormatter = "latexindent",
      },
    },
  },
}

for name, opts in pairs(servers) do
  vim.lsp.config(name, opts)
  vim.lsp.enable(name)
end

-- See :h vim.lsp.config for additional server-specific options.

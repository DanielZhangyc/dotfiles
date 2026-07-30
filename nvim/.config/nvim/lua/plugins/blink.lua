vim.g.vscode_snippets_path = vim.fn.stdpath "config" .. "/snippets"
vim.g.vscode_snippets_exclude = { "cpp", "tex", "plaintex", "bib", "bibtex" }

local function clangd_for_signature(item)
  local snippet_kind = vim.lsp.protocol.CompletionItemKind.Snippet

  if
    item.client_name ~= "clangd"
    or item.kind ~= snippet_kind
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
    "saghen/blink.cmp",
    dependencies = {
      {
        "xzbdmw/colorful-menu.nvim",
        opts = {},
      },
    },
    opts = {
      cmdline = {
        keymap = {
          ["<Tab>"] = { "show", "accept" },
        },
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
                  local label = require("colorful-menu").blink_components_text(ctx)
                  local signature = clangd_for_signature(ctx.item)

                  return signature and vim.trim(ctx.item.label) .. " " .. signature or label
                end,
                highlight = function(ctx)
                  local signature = clangd_for_signature(ctx.item)
                  if not signature then
                    return require("colorful-menu").blink_components_highlight(ctx)
                  end

                  local highlights = {
                    { 0, 3, group = "BlinkCmpLabelMatch" },
                    {
                      4,
                      #signature + 4,
                      group = "BlinkCmpLabelDescription",
                    },
                  }

                  return highlights
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

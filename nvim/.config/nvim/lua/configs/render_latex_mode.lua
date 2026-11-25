local M = {}
local configured = false

function M.setup()
  if configured then
    return
  end

  local renderer = require "render_latex.renderer"
  require("render_latex.sources").register {
    name = "markdown",
    incremental = true,
    inline = true,
    hide_focused_equation = true,
    attach = function(buffer)
      return require("render_latex.config").is_filetype_supported(vim.bo[buffer].filetype)
    end,
    display_equations = require("render_latex.detect").scan,
  }
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = vim.api.nvim_create_augroup("RenderLatexMode", { clear = true }),
    callback = function()
      -- render_modes skips new work but leaves existing images and conceal marks.
      if vim.api.nvim_get_mode().mode ~= "n" then
        renderer.hide_all()
        return
      end
      local seen = {}
      for _, window in ipairs(vim.api.nvim_list_wins()) do
        local buffer = vim.api.nvim_win_get_buf(window)
        if not seen[buffer] and require("render_latex.sources").supports(buffer) then
          seen[buffer] = true
          renderer.queue(buffer)
        end
      end
    end,
  })
  configured = true
end

return M

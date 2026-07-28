require "nvchad.autocmds"

vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Open the file explorer on startup",
  callback = function()
    vim.cmd "NvimTreeToggle"
  end,
})

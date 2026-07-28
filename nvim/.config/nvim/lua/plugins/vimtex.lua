return {
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = "sioyek"
      vim.g.vimtex_view_sioyek_exe = "/Applications/sioyek.app/Contents/MacOS/sioyek"
      vim.g.vimtex_callback_progpath = "/opt/homebrew/bin/nvim"
    end,
  },
}

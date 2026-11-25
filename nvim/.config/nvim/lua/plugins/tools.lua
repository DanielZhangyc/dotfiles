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

  {
    "xeluxee/competitest.nvim",
    cmd = "CompetiTest",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      compile_command = {
        cpp = {
          exec = "g++-16",
          args = { "-std=c++20", "-O2", "-Wall", "$(FNAME)", "-o", "$(FNOEXT)" },
        },
      },
      run_command = {
        cpp = { exec = "./$(FNOEXT)" },
      },
    },
  },
}

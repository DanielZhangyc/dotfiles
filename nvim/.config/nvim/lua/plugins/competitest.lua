return {
  {
    "xeluxee/competitest.nvim",
    cmd = "CompetiTest",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = {
      compile_command = {
        cpp = {
          exec = "g++-16",
          args = {
            "-std=c++20",
            "-O2",
            "-Wall",
            "$(FNAME)",
            "-o",
            "$(FNOEXT)",
          },
        },
      },
      run_command = {
        cpp = {
          exec = "./$(FNOEXT)",
        },
      },
    },
  },
}

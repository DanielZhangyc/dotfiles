return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    init = function()
      -- An attached tmux session can retain the previous terminal's environment.
      -- Prefer its current client over inherited TERM_PROGRAM when switching apps.
      local terminal = vim.env.TERM_PROGRAM or vim.env.TERM or ""
      if vim.env.TMUX then
        local ok, out = pcall(vim.fn.system, { "tmux", "display-message", "-p", "#{client_termname}" })
        if ok and vim.v.shell_error == 0 and vim.trim(out) ~= "" then
          terminal = vim.trim(out)
        end
      elseif vim.env.KITTY_WINDOW_ID then
        terminal = "kitty"
      end
      if terminal:find("kitty", 1, true) or terminal:find("ghostty", 1, true) then
        vim.env.SNACKS_KITTY = terminal:find("kitty", 1, true) and "true" or "false"
        vim.env.SNACKS_GHOSTTY = terminal:find("ghostty", 1, true) and "true" or "false"
      end
      -- Fix: re-place images after tmux repaints the pane (tab/buffer switches).
      require("configs.image_tmux_render_fix").setup()
    end,
    opts = {
      image = {
        enabled = true,
        doc = {
          enabled = true,
          inline = true,
          float = true,
          max_width = 80,
          max_height = 40,
        },
      },
    },
    keys = {
      {
        "<leader>ih",
        function()
          Snacks.image.hover()
        end,
        desc = "Preview image under cursor",
      },
    },
  },
}

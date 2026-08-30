return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    init = function()
      -- Terminal capability probing cannot always cross tmux reliably.
      -- Ghostty exposes TERM_PROGRAM; inside tmux, fall back to the tmux
      -- client's termname (e.g. xterm-ghostty) which is what snacks'
      -- detection uses when tmux has extended-keys enabled.
      local is_ghostty = vim.env.TERM_PROGRAM == "ghostty"
      if not is_ghostty and vim.env.TMUX then
        local ok, out = pcall(vim.fn.system, { "tmux", "display-message", "-p", "#{client_termname}" })
        is_ghostty = ok and vim.trim(out):find("ghostty", 1, true) ~= nil
      end
      if is_ghostty then
        vim.env.SNACKS_GHOSTTY = "true"
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

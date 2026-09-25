local omniwm_focus = vim.fn.expand "~/Documents/dotfiles/tmux/scripts/omniwm-focus.sh"

local function move_outside_tmux(ctx)
  local mux = ctx.mux
  local pane = vim.env.TMUX_PANE
  if not mux or mux.type ~= "tmux" or not mux.is_in_session() or not pane or pane == "" then
    return
  end

  -- A zoomed pane has no visible tmux neighbor; keep its zoom and leave via OmniWM.
  if mux.current_pane_is_zoomed() or mux.current_pane_at_edge(ctx.direction) then
    vim.fn.jobstart({ omniwm_focus, ctx.direction, pane }, { detach = true })
  end
end

return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = {
      at_edge = move_outside_tmux,
      default_amount = 2,
      disable_multiplexer_nav_when_zoomed = true,
      multiplexer_integration = vim.env.TMUX and vim.env.TMUX ~= "" and "tmux" or false,
    },
    config = function(_, opts)
      require("smart-splits").setup(opts)
    end,
  },
}

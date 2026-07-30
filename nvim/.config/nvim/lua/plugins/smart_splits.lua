return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = {
      at_edge = "stop",
      default_amount = 2,
      disable_multiplexer_nav_when_zoomed = true,
    },
    config = function(_, opts)
      require("smart-splits").setup(opts)
    end,
  },
}

return {
  {
    "akinsho/toggleterm.nvim",
    -- tag = "*",
    keys = {
      {
        "<leader>td",
        "<cmd>ToggleTerm size=25 dir=. direction=horizontal<cr>",
        desc = "Open a horizontal terminal at the Desktop directory",
      },
    },
    config = true,
    -- opts = {
    --   size = 10,
    -- },
  },
}

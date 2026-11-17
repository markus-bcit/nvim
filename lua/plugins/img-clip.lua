return {
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        dir_path = ".",
        relative_to_current_file = true,
        prompt_for_file_name = true,
      },
    },
    keys = {
      {
        "<leader>cv",
        "<cmd>PasteImage<cr>",
        desc = "Paste Image (same directory)",
        ft = "markdown",
      },
    },
  },
}

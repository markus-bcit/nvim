return {
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      -- Use Brave browser to view compiled LaTeX PDFs
      vim.g.vimtex_view_method = "general"
      vim.g.vimtex_view_general_viewer = "brave"
    end,
    keys = {
      { "<leader>cp", "<cmd>VimtexCompile<cr>", desc = "LaTeX Compile & Preview (Browser)", ft = "tex" },
      { "<leader>cv", "<cmd>VimtexView<cr>", desc = "LaTeX View PDF (Browser)", ft = "tex" },
    },
  },
}

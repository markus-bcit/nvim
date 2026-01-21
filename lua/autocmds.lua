require "nvchad.autocmds"

-- Disable folding in Dadbod UI output
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  callback = function()
    vim.opt_local.foldenable = false
  end,
})

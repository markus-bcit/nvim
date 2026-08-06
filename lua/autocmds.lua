require "nvchad.autocmds"

-- Disable folding in Dadbod UI output
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  callback = function()
    vim.opt_local.foldenable = false
  end,
})

-- Enable LSP inlay hints for C# once the Roslyn client (managed by easy-dotnet)
-- attaches. Rider shows parameter / type hints inline; keep them toggleable.
local inlay_group = vim.api.nvim_create_augroup("csharp_inlay_hints", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = inlay_group,
  callback = function(args)
    local buf = args.buf
    if vim.bo[buf].filetype ~= "cs" then
      return
    end
    local ok, client = pcall(vim.lsp.get_client_by_id, args.data.client_id)
    if not ok or not client then
      return
    end
    if client:supports_method "textDocument/inlayHint" then
      pcall(vim.lsp.inlay_hint.enable, true, { bufnr = buf })
    end
  end,
})

vim.keymap.set("n", "<leader>ci", function()
  local buf = vim.api.nvim_get_current_buf()
  local enabled = false
  pcall(function()
    enabled = vim.lsp.inlay_hint.is_enabled { bufnr = buf }
  end)
  pcall(vim.lsp.inlay_hint.enable, not enabled, { bufnr = buf })
  vim.notify(("Inlay hints %s"):format(not enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "toggle inlay hints" })

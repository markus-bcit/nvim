require "nvchad.autocmds"

-- Force a transparent background so the terminal (and its opacity) shows through.
-- Runs after any colorscheme loads so it always wins over the base46 cache.
local transparent_group = vim.api.nvim_create_augroup("force_transparency", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = transparent_group,
  callback = function()
    local groups = {
      "Normal",
      "NormalNC",
      "NormalFloat",
      "FloatBorder",
      "SignColumn",
      "LineNr",
      "CursorLineNr",
      "EndOfBuffer",
      "VertSplit",
      "WinSeparator",
      "Folded",
      "FoldColumn",
      "TabLine",
      "TabLineFill",
      "StatusLine",
      "StatusLineNC",
      "NvimTreeNormal",
      "NvimTreeNormalNC",
      "TelescopeNormal",
      "TelescopeBorder",
    }
    for _, name in ipairs(groups) do
      vim.api.nvim_set_hl(0, name, { bg = "none", ctermbg = "NONE" })
    end
  end,
})

-- Apply immediately for the current session too.
vim.schedule(function()
  vim.api.nvim_exec_autocmds("ColorScheme", { group = transparent_group })
end)

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

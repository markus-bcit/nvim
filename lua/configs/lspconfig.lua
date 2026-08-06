local nvlsp = require "nvchad.configs.lspconfig"

-- load defaults i.e lua_lsp
nvlsp.defaults()

local servers = { "html", "cssls", "bicep" }

-- lsps with default config
for _, lsp in ipairs(servers) do
  vim.lsp.config[lsp] = {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
  vim.lsp.enable(lsp)
end

-- C# / .NET: handled by easy-dotnet.nvim, which manages the official Roslyn
-- language server (the modern, performant successor to the deprecated OmniSharp).
-- Decompilation / metadata doc navigation work natively via vim.lsp.buf.definition.

-- Pyright specific config for better type inference
vim.lsp.config.pyright = {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        typeCheckingMode = "basic", -- options: "off", "basic", "strict"
      },
    },
  },
}
vim.lsp.enable("pyright")

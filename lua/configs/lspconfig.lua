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

-- OmniSharp setup
local omnisharp_bin = vim.fn.stdpath "data" .. "/mason/bin/OmniSharp"
vim.lsp.config.omnisharp = {
  cmd = { omnisharp_bin, "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
  on_attach = function(client, bufnr)
    client.server_capabilities.semanticTokensProvider = nil
    nvlsp.on_attach(client, bufnr)
  end,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}
vim.lsp.enable "omnisharp"

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

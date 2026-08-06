return {
  -- DAP core
  {
    "mfussenegger/nvim-dap",
    lazy = false,
    config = function()
      require("configs.dap").config()
    end,
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
      },
      "theHamsta/nvim-dap-virtual-text",
      "nvim-telescope/telescope-dap.nvim",
    },
  },

  -- Test runner — uses easy-dotnet's neotest adapter so the Rider-like test
  -- runner tree and neotest share the same discovery state.
  {
    "nvim-neotest/neotest",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "GustavEikaas/easy-dotnet.nvim",
    },
    config = function()
      require("neotest").setup {
        adapters = {
          require("easy-dotnet.neotest"),
        },
        icons = {
          passing = "",
          failing = "",
          running = "",
          skipped = "",
          unknown = "",
          watching = "",
        },
        output = { open_on_run = true },
        quickfix = { enabled = true, open = false },
      }
    end,
  },
}

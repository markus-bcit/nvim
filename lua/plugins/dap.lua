return {
  -- DAP core
  {
    "mfussenegger/nvim-dap",
    lazy = false,
    config = function()
      require "configs.dap"
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

  -- Test runner
  {
    "nvim-neotest/neotest",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "Issafalcon/neotest-dotnet",
    },
    config = function()
      require("neotest").setup {
        adapters = {
          require("neotest-dotnet") {
            -- pick up any framework; default discovery is fine
            dap = { justMyCode = true },
          },
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

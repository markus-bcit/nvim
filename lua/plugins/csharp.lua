-- C# / .NET tooling — Rider-like experience without the bloat.
-- Foundation: easy-dotnet.nvim bundles the official Roslyn LSP, a Rider-like
-- test runner, project/solution management, build/run/debug workflows and a
-- netcoredbg-backed debugger. The plugins below add the missing IDE pieces:
-- code-action menu, diagnostics panel, file outline, refactors and peek previews.
return {
  -- snacks.nvim is a hard dependency of easy-dotnet (floating windows / picker).
  -- Loaded with NO modules enabled so it cannot clash with NvChad's nvim-tree,
  -- indent-blankline, etc. — it only provides what easy-dotnet asks for on demand.
  {
    "folke/snacks.nvim",
    lazy = true,
    opts = {},
  },

  -- The centerpiece: Roslyn LSP + debugger + test runner + project management.
  {
    "GustavEikaas/easy-dotnet.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap",
      "folke/snacks.nvim",
    },
    config = function()
      require("configs.easy-dotnet").config()
    end,
  },

  -- Rider-style "Alt+Enter" code-action menu with live diff previews.
  {
    "aznhe21/actions-preview.nvim",
    lazy = false,
    config = function()
      require("actions-preview").setup {
        telescope = {
          sorting_strategy = "ascending",
          layout_strategy = "vertical",
          layout_config = {
            width = 0.6,
            height = 0.5,
            prompt_position = "top",
          },
        },
      }
    end,
  },

  -- Diagnostics / references / quickfix panel — Rider's "Errors in Solution".
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {},
  },

  -- File structure outline — Rider's "File Structure" popup (symbols tree).
  {
    "stevearc/aerial.nvim",
    event = "User FilePost",
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = { min_width = 28 },
      filter_kind = false,
    },
  },

  -- Extract function / variable / inline — Rider refactor menu.
  {
    "ThePrimeagen/refactoring.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "lewis6991/async.nvim",
    },
    opts = {
      prompt_func_return_type = { go = true, cpp = true, c = true, java = true },
      prompt_func_param_type = { go = true, cpp = true, c = true, java = true },
    },
  },

  -- Peek definitions / references / implementations in a floating window — Rider peek.
  {
    "rmagatti/goto-preview",
    lazy = false,
    keys = { "gpd", "gpt", "gpi", "gpr", "gP" },
    opts = {
      width = 100,
      height = 25,
      default_mappings = false,
      resizing_mappings = true,
      post_open_hook = function(buf, _)
        vim.bo[buf].foldenable = false
      end,
    },
  },
}

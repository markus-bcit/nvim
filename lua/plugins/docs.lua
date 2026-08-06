return {
  -- Hover docs (auto on cursor hold + manual trigger)
  {
    "lewis6991/hover.nvim",
    lazy = false,
    config = function()
      require("hover").setup {
        init = function()
          require("hover.providers.lsp")
        end,
        preview_opts = {
          border = "rounded",
        },
        preview_window = false,
        title = true,
      }
    end,
  },

  -- Live rename preview (Rider-style: usages update inline as you type)
  {
    "smjonas/inc-rename.nvim",
    lazy = false,
    opts = {
      post_hook = function(result)
        if result and result.changes then
          local count = 0
          for _, changes in pairs(result.changes) do
            count = count + #changes
          end
          vim.notify(("Renamed %d occurrence(s)"):format(count), vim.log.levels.INFO)
        end
      end,
    },
  },
}

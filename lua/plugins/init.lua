return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  {
  	"nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup {}

      -- parsers to keep installed
      local ensure_installed = {
        "vim", "lua", "vimdoc",
        "html", "css", "sql", "python",
        "bicep", "c_sharp",
      }

      -- auto-install missing parsers once on startup
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          local installed = {}
          for _, lang in ipairs(require("nvim-treesitter").get_installed "parsers") do
            installed[lang] = true
          end
          local missing = {}
          for _, lang in ipairs(ensure_installed) do
            if not installed[lang] then
              missing[#missing + 1] = lang
            end
          end
          if #missing > 0 then
            vim.cmd("TSInstall " .. table.concat(missing, " "))
          end
        end,
      })

      -- start treesitter highlight + indent for any buffer with a parser.
      -- Skip the indentexpr override for C#: easy-dotnet/Roslyn own indentation
      -- (setting nvim-treesitter's indentexpr for cs breaks it — see
      -- https://github.com/GustavEikaas/easy-dotnet.nvim/issues/873).
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local buf = args.buf
          local ok = pcall(vim.treesitter.start, buf)
          if ok and vim.bo[buf].filetype ~= "cs" then
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require "configs.harpoon"
    end,
  },

  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },

  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup {}
      require("mason-tool-installer").setup {
        ensure_installed = {
          "pyright",
          "csharpier",
          "bicep-lsp",
        },
        auto_update = false,
        run_on_start = true,
        start_delay = 3000,
      }
    end,
    dependencies = {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
  },
}

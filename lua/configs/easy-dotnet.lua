local M = {}

M.config = function()
  local dotnet = require "easy-dotnet"

  dotnet.setup {
    -- Terminal panel for run/watch output (Rider-style docked terminal).
    managed_terminal = {
      auto_hide = true,
      auto_hide_delay = 1000,
    },

    -- ProjX LSP: project-file awareness (csproj/fsproj navigation, go-to-project).
    projx_lsp = {
      enabled = true,
    },

    -- Official Roslyn language server — replaces the deprecated OmniSharp.
    lsp = {
      enabled = true,
      set_fold_expr = false,
      preload_roslyn = true,
      roslynator_enabled = true,
      easy_dotnet_analyzer_enabled = true,
      -- Rider-like: rename file when renaming the class it contains.
      enhanced_rename = true,
      -- Rider-like: code action to create a class/record/interface from an
      -- unresolved symbol, placed in its own file.
      create_type_from_usage = true,
      easy_dotnet_extension_enabled = true,
      restart_roslyn_on_branch_change = false,
      auto_refresh_codelens = true,
      suggest_updates = true,
      analyzer_assemblies = {},
      razor = {
        enabled = true,
        -- HTML completion inside .razor needs vscode-html-language-server on PATH.
        -- Disabled by default to avoid the missing-binary warning; enable it (and
        -- `npm i -g vscode-langservers-extracted`) if you edit Razor views.
        html = { enabled = false, cmd = nil, request_timeout = 5000 },
      },
      config = {},
    },

    -- Debugger — netcoredbg, auto-registered with nvim-dap so :DapContinue works
    -- after a :Dotnet debug session. Project + launch-profile aware (like Rider).
    debugger = {
      bin_path = nil,
      engine = "netcoredbg",
      console = "integratedTerminal",
      apply_value_converters = true,
      auto_register_dap = true,
    },

    -- Built-in Rider-like test runner tree. neotest_integration lets neotest
    -- own the inline buffer signs/keymaps while this panel stays as the tree view.
    test_runner = {
      auto_start_testrunner = true,
      hide_legend = false,
      neotest_integration = true,
      viewmode = "float",
      icons = {
        passed = "",
        skipped = "",
        failed = "",
        success = "",
        reload = "",
        test = "",
        sln = "󰘐",
        project = "󰘐",
        dir = "",
        package = "",
        class = "",
        build_failed = "󰒡",
      },
    },

    new = { project = { prefix = "sln" } },
    csproj_mappings = true,
    fsproj_mappings = true,
    auto_bootstrap_namespace = {
      type = "block_scoped",
      enabled = true,
      use_clipboard_json = { behavior = "prompt", register = "+" },
    },

    server = {
      use_visual_studio = false,
      log_level = nil,
    },

    picker = "telescope",

    notifications = {
      handler = function(start_event)
        local spinner = require("easy-dotnet.ui-modules.spinner").new()
        spinner:start_spinner(function() return start_event.job.name end)
        return function(finished_event)
          spinner:stop_spinner(finished_event.result.msg, finished_event.result.level)
        end
      end,
    },

    diagnostics = {
      default_severity = "error",
      setqflist = false,
    },

    outdated = {
      mappings = {
        upgrade = { lhs = "<leader>pu", desc = "upgrade package under cursor" },
        upgrade_all = { lhs = "<leader>pa", desc = "upgrade all outdated packages" },
      },
    },
  }
end

return M

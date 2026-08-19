local M = {}

-- Guard easy-dotnet's managed-terminal handler against an invalid workingDirectory.
-- The EasyDotnet server can send a `runCommandManaged` request with an empty/
-- invalid `workingDirectory` (e.g. when nvim is opened outside a .NET project, or
-- a Windows-style path from a .sln that Linux nvim rejects), which makes
-- `vim.fn.termopen` throw `Vim:E475: expected valid directory` inside a
-- vim.schedule callback — disrupting <leader> and printing a stack trace.
-- This wrapper falls back to the current working directory (the project root
-- you launched nvim in) when the server's workingDirectory is unusable, so
-- legitimate build/run/test commands still proceed. Installed into
-- package.loaded *before* easy-dotnet's setup() loads rpc-client, so
-- rpc-client captures this wrapper.
local MANAGED_HANDLER = "easy-dotnet.rpc.handlers.run_command_managed"
local _orig_managed = require(MANAGED_HANDLER)
package.loaded[MANAGED_HANDLER] = function(params, response, throw, validate)
  local cmd = params and params.command
  if cmd then
    local wd = cmd.workingDirectory
    if wd == nil or wd == "" or vim.fn.isdirectory(wd) == 0 then
      local cwd = vim.fn.getcwd()
      if vim.fn.isdirectory(cwd) == 1 then
        cmd.workingDirectory = cwd
      else
        throw { code = -32000, message = "easy-dotnet: no valid working directory and cwd is not a directory" }
        return
      end
    end
  end
  return _orig_managed(params, response, throw, validate)
end

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
      -- preload_roslyn=false: starting the server on every nvim launch (even in
      -- non-.NET dirs) makes the server fire a managed `termopen` with an empty
      -- workingDirectory → Vim:E475 "expected valid directory" thrown in a
      -- vim.schedule callback (which also disrupts <leader>). With preload off,
      -- the server starts lazily when a .cs file is opened, in a real project context.
      preload_roslyn = false,
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
      config = {
        settings = {
          -- Roslyn computes inlay hints only when asked via these options
          -- (server-side defaults are all off, same as VS Code / Rider).
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_lambda_return_types = true,
            csharp_enable_inlay_hints_for_parameters = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
        },
      },
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
    -- auto_start_testrunner is OFF: the server would otherwise fire a managed
    -- `termopen` on startup with an empty working directory when nvim is opened
    -- outside a .NET project, throwing a Vim:E475 error in a vim.schedule
    -- callback (which also disrupts <leader>). Open it on demand with
    -- <leader>ctr (dotnet.testrunner()) inside a real project instead.
    test_runner = {
      auto_start_testrunner = false,
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

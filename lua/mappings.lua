require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- hover / docs (hover.nvim) — set after nvchad.mappings so it wins
map("n", "K", function()
  require("hover").hover()
end, { desc = "hover doc" })
map("n", "<leader>hd", function()
  require("hover").hover()
end, { desc = "hover doc" })

-- live rename (inc-rename.nvim) — Rider-style preview
map("n", "<leader>lr", ":IncRename ", { desc = "live rename (preview)" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
-- Added
vim.keymap.set({ "n", "v" }, "<leader>rq", ":DB mysql://127.0.0.1:3306<CR>", { desc = "Run Query on MySQL" })

-- ── Rider-style general LSP / IDE keymaps (all filetypes) ──────────────────
-- Code-action menu with diff previews (Rider's Alt+Enter).
map("n", "<leader>ca", function()
  require("actions-preview").code_actions()
end, { desc = "code actions (preview)" })
map("v", "<leader>ca", function()
  require("actions-preview").code_actions()
end, { desc = "code actions (preview)" })

-- Trouble — diagnostics / references / quickfix panel (Rider "Errors in Solution").
-- trouble.nvim v3 command syntax: `:Trouble <mode> [action] [options]`.
map("n", "<leader>ox", "<cmd>Trouble diagnostics toggle<cr>", { desc = "trouble diagnostics toggle" })
map("n", "<leader>od", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "trouble buffer diag" })
map("n", "<leader>oq", "<cmd>Trouble qflist toggle<cr>", { desc = "trouble quickfix" })
map("n", "<leader>ol", "<cmd>Trouble loclist toggle<cr>", { desc = "trouble loclist" })
map("n", "<leader>or", "<cmd>Trouble lsp_references toggle<cr>", { desc = "trouble references" })
map("n", "<leader>oi", "<cmd>Trouble lsp_implementations toggle<cr>", { desc = "trouble impls" })
map("n", "<leader>oD", "<cmd>Trouble lsp_definitions toggle<cr>", { desc = "trouble definitions" })

-- Aerial — file structure outline (Rider "File Structure").
map("n", "<leader>oo", "<cmd>AerialToggle!<cr>", { desc = "outline toggle" })
map("n", "<leader>oO", "<cmd>AerialNav<cr>", { desc = "outline nav" })
map("n", "{o", function()
  require("aerial").prev()
end, { desc = "prev symbol" })
map("n", "}o", function()
  require("aerial").next()
end, { desc = "next symbol" })

-- goto-preview — peek definitions / refs / impls in a floating window.
map("n", "gpd", require("goto-preview").goto_preview_definition, { desc = "peek definition" })
map("n", "gpt", require("goto-preview").goto_preview_type_definition, { desc = "peek type def" })
map("n", "gpi", require("goto-preview").goto_preview_implementation, { desc = "peek impl" })
map("n", "gpr", require("goto-preview").goto_preview_references, { desc = "peek references" })
map("n", "gP", require("goto-preview").close_all_win, { desc = "close all peek windows" })

-- refactoring.nvim — Rider refactor menu (capital R = Refactor).
map("v", "<leader>Re", function()
  require("refactoring").refactor "Extract Function"
end, { desc = "extract function" })
map("v", "<leader>Rv", function()
  require("refactoring").refactor "Extract Variable"
end, { desc = "extract variable" })
map("v", "<leader>Ri", function()
  require("refactoring").refactor "Inline Variable"
end, { desc = "inline variable" })
map({ "n", "v" }, "<leader>Rb", function()
  require("refactoring").refactor "Extract Block"
end, { desc = "extract block" })
map({ "n", "v" }, "<leader>Rp", function()
  require("refactoring").debug.print_var { normal = true }
end, { desc = "print var (debug)" })
map("n", "<leader>Rc", function()
  require("refactoring").debug.cleanup {}
end, { desc = "cleanup print vars" })

-- ── C# / .NET (cs buffers) — easy-dotnet Rider-like workflows ──────────────
local dotnet_group = vim.api.nvim_create_augroup("dotnet_keymaps", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "cs",
  group = dotnet_group,
  callback = function(args)
    local buf = args.buf
    local opts = function(desc)
      return { buffer = buf, desc = "Dotnet " .. desc }
    end

    local dotnet = require "easy-dotnet"

    -- build / run / restore / clean / watch
    vim.keymap.set("n", "<leader>cb", function()
      dotnet.build_solution_quickfix()
    end, opts "build solution (qf)")
    vim.keymap.set("n", "<leader>cB", function()
      dotnet.build()
    end, opts "build project")
    vim.keymap.set("n", "<leader>cr", function()
      dotnet.run()
    end, opts "run project")
    vim.keymap.set("n", "<leader>cR", function()
      dotnet.run_default()
    end, opts "run default project")
    vim.keymap.set("n", "<leader>cu", function()
      dotnet.restore()
    end, opts "restore")
    vim.keymap.set("n", "<leader>cc", function()
      dotnet.clean()
    end, opts "clean")
    vim.keymap.set("n", "<leader>cw", function()
      dotnet.watch()
    end, opts "watch")

    -- secrets / packages / new project
    vim.keymap.set("n", "<leader>cs", function()
      dotnet.secrets()
    end, opts "user secrets")
    vim.keymap.set("n", "<leader>cp", function()
      dotnet.outdated()
    end, opts "outdated packages")
    vim.keymap.set("n", "<leader>cn", function()
      dotnet.new()
    end, opts "new project")

    -- tests via neotest (uses easy-dotnet adapter)
    vim.keymap.set("n", "<leader>ctt", function()
      require("neotest").run.run()
    end, opts "test nearest")
    vim.keymap.set("n", "<leader>ctf", function()
      require("neotest").run.run(vim.fn.expand "%")
    end, opts "test file")
    vim.keymap.set("n", "<leader>cta", function()
      require("neotest").run.run(vim.fn.getcwd())
    end, opts "test all")
    vim.keymap.set("n", "<leader>ctd", function()
      require("neotest").run.run { strategy = "dap" }
    end, opts "debug nearest test")
    vim.keymap.set("n", "<leader>cts", function()
      require("neotest").run.stop()
    end, opts "test stop")
    vim.keymap.set("n", "<leader>cto", function()
      require("neotest").output.open { enter = true }
    end, opts "test output")
    vim.keymap.set("n", "<leader>ctp", function()
      require("neotest").summary.toggle()
    end, opts "test summary panel")
    -- Rider-like test runner tree (separate from neotest summary)
    vim.keymap.set("n", "<leader>ctr", function()
      dotnet.testrunner()
    end, opts "test runner tree")

    -- debug (project + launch-profile aware via easy-dotnet)
    vim.keymap.set("n", "<leader>dd", function()
      dotnet.debug()
    end, opts "debug project")
    vim.keymap.set("n", "<leader>dD", function()
      dotnet.debug_default()
    end, opts "debug default project")
    vim.keymap.set("n", "<leader>dp", function()
      dotnet.debug_profile()
    end, opts "debug launch profile")
    vim.keymap.set("n", "<leader>da", function()
      dotnet.debug_attach()
    end, opts "debug attach")
    vim.keymap.set("n", "<leader>dc", function()
      require("dap").continue()
    end, opts "debug continue/resume")
    vim.keymap.set("n", "<leader>db", function()
      require("dap").toggle_breakpoint()
    end, opts "debug toggle breakpoint")
    vim.keymap.set("n", "<leader>dB", function()
      require("dap").set_breakpoint(vim.fn.input "Condition: ")
    end, opts "debug conditional breakpoint")
    vim.keymap.set("n", "<leader>di", function()
      require("dap").step_into()
    end, opts "debug step into")
    vim.keymap.set("n", "<leader>do", function()
      require("dap").step_over()
    end, opts "debug step over")
    vim.keymap.set("n", "<leader>dO", function()
      require("dap").step_out()
    end, opts "debug step out")
    vim.keymap.set("n", "<leader>dx", function()
      require("dap").terminate()
    end, opts "debug terminate")
    vim.keymap.set("n", "<leader>du", function()
      require("dapui").toggle()
    end, opts "debug toggle UI")
    vim.keymap.set("n", "<leader>de", function()
      require("dapui").eval()
    end, opts "debug eval expr")
    vim.keymap.set("v", "<leader>de", function()
      require("dapui").eval()
    end, opts "debug eval selection")
  end,
})

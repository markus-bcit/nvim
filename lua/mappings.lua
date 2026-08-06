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
vim.keymap.set({"n", "v"}, "<leader>rq", ":DB mysql://127.0.0.1:3306<CR>", { desc = "Run Query on MySQL" })

-- C# / .NET
local dotnet_group = vim.api.nvim_create_augroup("dotnet_keymaps", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "cs",
  group = dotnet_group,
  callback = function(args)
    local buf = args.buf
    local opts = function(desc)
      return { buffer = buf, desc = "Dotnet " .. desc }
    end

    -- build / run
    vim.keymap.set("n", "<leader>cb", function()
      vim.cmd "split | terminal dotnet build"
    end, opts "build")
    vim.keymap.set("n", "<leader>cr", function()
      vim.cmd "split | terminal dotnet run"
    end, opts "run")

    -- tests via neotest
    vim.keymap.set("n", "<leader>ctt", function()
      require("neotest").run.run()
    end, opts "test nearest")
    vim.keymap.set("n", "<leader>ctf", function()
      require("neotest").run.run(vim.fn.expand "%")
    end, opts "test file")
    vim.keymap.set("n", "<leader>cta", function()
      require("neotest").run.run(vim.fn.getcwd())
    end, opts "test all")
    vim.keymap.set("n", "<leader>cts", function()
      require("neotest").run.stop()
    end, opts "test stop")
    vim.keymap.set("n", "<leader>cto", function()
      require("neotest").output.open { enter = true }
    end, opts "test output")
    vim.keymap.set("n", "<leader>ctp", function()
      require("neotest").summary.toggle()
    end, opts "test summary panel")

    -- debug
    vim.keymap.set("n", "<leader>dd", function()
      require("dap").continue()
    end, opts "debug continue/start")
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

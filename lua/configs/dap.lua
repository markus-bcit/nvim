local M = {}

local function get_dll_path()
  local cwd = vim.fn.getcwd()
  local bin_dir = cwd .. "/bin/Debug/"
  local matches = vim.fn.globpath(bin_dir, "**/*.dll", true, true)
  if #matches == 0 then
    vim.notify("No .dll found under bin/Debug. Build the project first (:DotnetBuild).", vim.log.levels.ERROR)
    return nil
  end
  -- prefer the most recently built dll
  table.sort(matches, function(a, b)
    return vim.fn.getftime(b) > vim.fn.getftime(a)
  end)
  return matches[1]
end

M.config = function()
  local dap = require "dap"
  local dapui = require "dapui"

  -- DAP signs (Nerd Font icons)
  vim.fn.sign_define("DapBreakpoint", {
    text = "",
    texthl = "DiagnosticSignError",
    linehl = "DapBreakpointLine",
    numhl = "DapBreakpointNum",
  })
  vim.fn.sign_define("DapBreakpointCondition", {
    text = "ﳃ",
    texthl = "DiagnosticSignWarn",
    linehl = "DapBreakpointLine",
    numhl = "DapBreakpointNum",
  })
  vim.fn.sign_define("DapBreakpointRejected", {
    text = "",
    texthl = "DiagnosticSignHint",
    linehl = "DapBreakpointLine",
    numhl = "DapBreakpointNum",
  })
  vim.fn.sign_define("DapLogPoint", {
    text = "",
    texthl = "DiagnosticSignInfo",
    linehl = "DapBreakpointLine",
    numhl = "DapBreakpointNum",
  })
  vim.fn.sign_define("DapStopped", {
    text = "",
    texthl = "DiagnosticSignWarn",
    linehl = "DapStoppedLine",
    numhl = "DapStoppedNum",
  })

  dapui.setup {}

  -- netcoredbg adapter (installed via mason)
  local netcoredbg_path = vim.fn.stdpath "data" .. "/mason/bin/netcoredbg"
  dap.adapters.coreclr = {
    type = "executable",
    command = netcoredbg_path,
    args = { "--interpreter=vscode" },
  }

  dap.configurations.cs = {
    {
      type = "coreclr",
      name = "launch - netcoredbg",
      request = "launch",
      program = get_dll_path,
      cwd = "${workspaceFolder}",
      stopAtEntry = false,
      justMyCode = true,
    },
    {
      type = "coreclr",
      name = "attach - netcoredbg",
      request = "attach",
      processId = function()
        return tonumber(vim.fn.input "Process ID: ")
      end,
      cwd = "${workspaceFolder}",
    },
  }

  -- Auto open/close DAP UI
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open {}
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close {}
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close {}
  end

  -- virtual text for variable values inline
  require("nvim-dap-virtual-text").setup {
    enabled_commands = true,
    all_frames = true,
  }
end

return M

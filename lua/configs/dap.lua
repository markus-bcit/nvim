local M = {}

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

  -- The coreclr / netcoredbg adapter and the per-project launch configurations
  -- are registered by easy-dotnet.nvim (debugger.auto_register_dap = true),
  -- which is project + launch-profile aware. Start a session with :Dotnet debug
  -- (or the <leader>dd mapping); :DapContinue resumes an active session.

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

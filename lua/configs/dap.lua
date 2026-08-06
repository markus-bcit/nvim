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

  -- netcoredbg (registered by easy-dotnet with console = "integratedTerminal")
  -- sends a runInTerminal reverse request whose `cwd` is RELATIVE to the
  -- debugged project's directory (e.g. "bin/Debug/net10.0/"). nvim-dap passes
  -- body.cwd straight to jobstart/termopen, which resolves relative paths
  -- against nvim's cwd — the solution root, not the sub-project dir — so the
  -- path doesn't exist and termopen throws Vim:E475 "expected valid directory"
  -- inside a vim.schedule callback (disrupting <leader>, printing a stack
  -- trace). event_initialized fires before runInTerminal and listeners
  -- receive the session as first arg, so wrap the per-session reverse-request
  -- handler to resolve a relative cwd against the project dir (walk up from
  -- the buffer that launched the session) before delegating.
  local function resolve_cwd(cwd, base_dir)
    if not cwd or cwd == "" then return nil end
    if vim.fn.isdirectory(cwd) == 1 then return cwd end -- already valid (abs or rel-to-nvim-cwd)
    -- relative path that doesn't resolve against nvim cwd: walk up from base_dir
    local base = base_dir
    while base and base ~= "" and base ~= "/" do
      local candidate = base .. "/" .. cwd
      if vim.fn.isdirectory(candidate) == 1 then return candidate end
      local parent = vim.fs.dirname(base)
      if parent == base then break end
      base = parent
    end
    return nil
  end

  dap.listeners.after.event_initialized["sanitize_runinterminal_cwd"] = function(session)
    local handlers = session and session.handlers and session.handlers.reverse_requests
    local orig = handlers and handlers.runInTerminal
    if not orig then return end
    -- Capture the buffer dir at session-init time (the .cs file that launched
    -- :DapContinue); by runInTerminal time dap-ui may have opened other buffers.
    local base_dir = vim.fn.expand("%:p:h")
    handlers.runInTerminal = function(s, request)
      local body = request and request.arguments
      if body and body.cwd ~= nil and body.cwd ~= "" and vim.fn.isdirectory(body.cwd) == 0 then
        local resolved = resolve_cwd(body.cwd, base_dir) or vim.fn.getcwd()
        body.cwd = (vim.fn.isdirectory(resolved) == 1) and resolved or nil
      end
      return orig(s, request)
    end
  end

  -- Adapter for attaching netcoredbg to an already-running process (used by
  -- M.attach_functions_worker for Azure Functions isolated-worker debugging).
  -- NOTE: do NOT pass `--attach <pid>` on the command line — netcoredbg would
  -- attach at startup, then nvim-dap's subsequent DAP `attach` request fails with
  -- 0x80004005 ("already attached"). Let the DAP `attach` request (carrying
  -- config.processId) perform the attach instead.
  dap.adapters["netcoredbg-attach"] = function(callback, config)
    callback({
      type = "executable",
      command = config.netcoredbg_path,
      args = { "--interpreter=vscode" },
    })
  end

  -- virtual text for variable values inline
  require("nvim-dap-virtual-text").setup {
    enabled_commands = true,
    all_frames = true,
  }

  -- nvim-dap-virtual-text's stackTrace listener assumes body.stackFrames exists
  -- whenever body is truthy; netcoredbg can send a stackTrace response with a
  -- body but no stackFrames (e.g. before frames are loaded), making pairs(nil)
  -- throw inside a vim.schedule callback. Wrap the plugin's listener in pcall
  -- so the nil case is swallowed instead of disrupting the session.
  local vt_id = "nvim-dap-virtual-text"
  local orig_stack = dap.listeners.after.stackTrace[vt_id]
  if orig_stack then
    dap.listeners.after.stackTrace[vt_id] = function(session, body, request)
      pcall(orig_stack, session, body, request)
    end
  end
end

-- Azure Functions .NET isolated-worker projects run your code in a CHILD worker
-- process (`dotnet <Assembly>.dll --workerId ...`), not in `func start`/`dotnet run`
-- (the host). easy-dotnet's `<leader>dd` launches the host under netcoredbg, so
-- breakpoints never hit — the debugger is attached to the wrong process.
-- This helper attaches netcoredbg directly to the running worker process.
-- Workflow: start the function in DEBUG mode (<leader>cD = `func start
-- --dotnet-isolated-debug`), which PAUSES the worker waiting for a debugger;
-- set breakpoints, then <leader>dA> to attach netcoredbg to the worker PID.
-- (Without --dotnet-isolated-debug the worker runs freely and netcoredbg's
-- attach times out with CORDBG_E_TIMEOUT 0x80131c08.)
local function find_netcoredbg()
  local opts = require("easy-dotnet.options").options.debugger
  if opts.bin_path and vim.fn.executable(opts.bin_path) == 1 then return opts.bin_path end
  local home = vim.env.HOME or ""
  local found = vim.fn.glob(home .. "/.dotnet/tools/.store/easydotnet/*/easydotnet/*/tools/netcoredbg/linux-x64/netcoredbg", false, true)
  if type(found) == "table" then
    for _, p in ipairs(found) do
      if vim.fn.executable(p) == 1 then return p end
    end
  end
  return nil
end

local function find_worker_candidates()
  local lines = vim.fn.systemlist("ps -eo pid=,args=")
  if vim.v.shell_error ~= 0 then return {}, 0 end
  local worker_lines = 0
  local cands = {}
  for _, line in ipairs(lines) do
    if line:find("--workerId", 1, true) then
      worker_lines = worker_lines + 1
      local pid = line:match("^%s*(%d+)")
      local dll = line:match("(%S+%.dll)")
      if pid and dll then
        table.insert(cands, { pid = tonumber(pid), dll = vim.fs.normalize(dll) })
      end
    end
  end
  return cands, worker_lines
end

function M.attach_functions_worker()
  local dap = require("dap")
  local netcoredbg = find_netcoredbg()
  if not netcoredbg then
    vim.notify("netcoredbg not found. Set debugger.bin_path in easy-dotnet config.", vim.log.levels.ERROR)
    return
  end
  local cands, worker_lines = find_worker_candidates()
  if #cands == 0 then
    vim.notify(string.format("No Azure Functions isolated worker attached. ps saw %d line(s) with --workerId, %d parsed. Start the function in DEBUG mode first (<leader>cD), then retry.", worker_lines, #cands), vim.log.levels.WARN)
    return
  end
  -- YAMA ptrace_scope=1 forbids attaching to a non-descendant process
  -- (the worker is a child of `func` in a terminal, not of netcoredbg), so
  -- netcoredbg's attach fails with 0x80004005. Warn up-front with the fix.
  local ps_ok, ptrace_scope = pcall(vim.fn.readfile, "/proc/sys/kernel/yama/ptrace_scope")
  if ps_ok and ptrace_scope and tonumber(ptrace_scope[1]) and tonumber(ptrace_scope[1]) > 0 then
    vim.notify("ptrace_scope=" .. ptrace_scope[1] .. " — netcoredbg can't attach to a non-descendant process. Run: echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope", vim.log.levels.ERROR)
    return
  end
  local launch = function(chosen)
    if not chosen then return end
    dap.run({
      type = "netcoredbg-attach",
      name = "functions-worker-attach",
      request = "attach",
      processId = chosen.pid,
      netcoredbg_path = netcoredbg,
    })
  end
  if #cands == 1 then
    launch(cands[1])
  else
    vim.ui.select(cands, {
      prompt = "Select Functions worker process",
      format_item = function(c) return string.format("PID %d  %s", c.pid, c.dll) end,
    }, launch)
  end
end

return M

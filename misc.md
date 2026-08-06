## Nice to Haves:

- Starship
- Powershell 7
- Fish (linux)

## Prereqs

- Nvim
- Git 
- [Ripgrep](https://github.com/BurntSushi/ripgrep?tab=readme-ov-file#installation) (install Choco as well)
- Node
- Python
- Make 
- tree-sitter CLI (required by nvim-treesitter `main` branch to build parsers):
  ```bash
  npm install -g tree-sitter-cli
  ln -sf "$(npm prefix -g)/bin/tree-sitter" ~/.local/bin/tree-sitter
  ```
  Verify with `tree-sitter --version`. If the npm global path changes (e.g. after a node/cursor-agent reinstall), re-run the `ln -sf` line.
- Nerd Font (for icons) — install on Windows, set as terminal font face. See `:lua print("  ")` to verify.

## C# / .NET (Rider-like setup)

Required on a fresh Ubuntu install for the `easy-dotnet.nvim` toolchain (Roslyn LSP, debugger, test runner, build/run/test):

- .NET SDK (8 or 10) — Microsoft's apt feed:
  ```bash
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/
  sudo sh -c 'echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" > /etc/apt/sources.list.d/microsoft-prod.list'
  rm packages.microsoft.gpg
  sudo apt update && sudo apt install -y dotnet-sdk-10.0
  ```
  (Or use the [dotnet-install script](https://learn.microsoft.com/dotnet/core/tools/dotnet-install-script) for a no-sudo install.)
- `~/.dotnet/tools` on PATH — usually added by the SDK install to `~/.bashrc`/`~/.profile`; verify with `echo $PATH | grep dotnet/tools`.
- EasyDotnet server tool (powers easy-dotnet's server, test runner, debugger):
  ```bash
  dotnet tool install --global EasyDotnet
  ```
- EF tool (for the `:Dotnet ef *` commands):
  ```bash
  dotnet tool install --global dotnet-ef
  ```
- `roslyn-language-server` — auto-installed by easy-dotnet on first use; update with `dotnet-easydotnet roslyn update` or `:Dotnet _server update`.
- `netcoredbg` — bundled inside the EasyDotnet tool, no separate install.
- Keep tools current (dotnet global tools don't auto-update):
  ```bash
  dotnet tool update --global EasyDotnet
  dotnet tool update --global dotnet-ef
  ```
- Optional — Razor HTML completion (only if you edit `.razor`):
  ```bash
  npm install -g vscode-langservers-extracted
  ```
  then set `lsp.razor.html.enabled = true` in `lua/configs/easy-dotnet.lua`.

Verify everything with `:checkhealth easy-dotnet` — all lines should be `OK`.

## Where to put this:
```
nvim --headless +"echo stdpath('config')" +qa
```

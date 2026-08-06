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

## Where to put this:
```
nvim --headless +"echo stdpath('config')" +qa
```

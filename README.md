# Subtract First neovim

A single-file Neovim config (`init.lua`) for locked-down machines: no sudo, and tools arrive slowly.
Nothing hard-fails on a missing binary. It falls back to built-in Neovim features, and fzf, ripgrep
and language servers switch on by themselves once they are on your `PATH`.

## Quick start (no sudo, about 30 seconds on a decent connection)

Needs: Linux x86_64, `git`, `curl`, and a C compiler (`cc`).

```sh
# 1. Neovim 0.12+ (user-space install)
mkdir -p ~/.local/bin && cd ~/.local/bin
curl -fsSLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar xzf nvim-linux-x86_64.tar.gz && rm nvim-linux-x86_64.tar.gz
export PATH="$HOME/.local/bin/nvim-linux-x86_64/bin:$PATH"   # add this line to ~/.bashrc to keep it

# 2. This config
mkdir -p ~/.config/nvim
curl -fsSL https://raw.githubusercontent.com/tristanalderson/subtract-first-neovim/main/init.lua \
  -o ~/.config/nvim/init.lua

# 3. Start it. Plugins and syntax parsers install themselves on the first launch.
nvim
```

If Neovim asks you to confirm installing plugins on the first launch, accept. The first launch
takes a few extra seconds while plugins download and syntax parsers compile. Later launches are instant.

## Using it

The leader key is Space. Press it and wait half a second: a popup lists every key available.
Do the same after `g`, `z` or `Ctrl-w`.

| Keys            | Does                                         |
|-----------------|----------------------------------------------|
| `Space f`       | find a file                                  |
| `Space g`       | search file contents                         |
| `Space b`       | switch buffer                                |
| `Space e`       | file browser                                 |
| `Space a`       | mark the file (harpoon); `Space 1`-`4` jump  |
| `Space G`       | git status; `Space h` for hunk actions       |
| `Space ?`       | keys active in this buffer                   |

`Space f`, `g` and `b` use fzf and ripgrep when they are installed. Without them they fall back to
Neovim's built-in `:find`, `:grep` and `:buffer`, which still work.

## Optional extras

None are required. Put these on your `PATH` and the config picks them up on the next launch:

- `fzf` and `rg` (ripgrep): fuzzy pickers
- language servers: `clangd`, `lua-language-server`, `gopls`, `rust-analyzer`, `pyright-langserver`, `verible-verilog-ls`

## Troubleshooting

- Plugin errors right after an update: run `:checkhealth vim.pack`.
- Syntax highlighting missing: the Treesitter plugin must be on its `master` branch.
  Fix: `git -C ~/.local/share/nvim/site/pack/core/opt/nvim-treesitter checkout master`

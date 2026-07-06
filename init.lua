-- ~/.config/nvim/init.lua — one file, five plugins, all earned.
--
-- Bootstrap on a new box:
--   curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
--   tar xzf nvim-linux-x86_64.tar.gz && export PATH="$PWD/nvim-linux-x86_64/bin:$PATH"
--   mkdir -p ~/.config/nvim && curl -fsSL https://raw.githubusercontent.com/tristanalderson/subtract-first-neovim/refs/heads/main/init.lua -o ~/.config/nvim/init.lua
-- Box deps: git, rg, fzf, cc + tree-sitter CLI (parser builds). Plugins
-- auto-install on first launch via vim.pack (built into nvim 0.12).

vim.g.mapleader = ' '

-- Plugins: the full roster. New entries must survive two weeks of daily pain first.
vim.pack.add({
  'https://github.com/ibhagwan/fzf-lua',                        -- nav, priority #1
  'https://github.com/nvim-lua/plenary.nvim',                   -- exists ONLY as harpoon's dep; leaves if harpoon does
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
  'https://github.com/folke/tokyonight.nvim',                   -- looks; swap URL to taste
})

vim.cmd.colorscheme('tokyonight-night')

-- Options: few, close to defaults, so bare `vi` on a locked-down box still feels like home
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = 'yes'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.undofile = true
vim.o.clipboard = 'unnamedplus'
vim.opt.wildoptions:append('fuzzy')
vim.diagnostic.config({ virtual_text = true })

-- Navigation: fzf-lua for search-by-name, harpoon for the 4 files you live in
local fzf = require('fzf-lua')
vim.keymap.set('n', '<leader>f', fzf.files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>g', fzf.live_grep, { desc = 'Live grep' })
vim.keymap.set('n', '<leader>b', fzf.buffers, { desc = 'Buffers' })
vim.keymap.set('n', '<leader>r', fzf.resume, { desc = 'Resume last picker' })
vim.keymap.set('n', '<leader>e', ':Ex<CR>', { desc = 'File browser (netrw)' })

local harpoon = require('harpoon')
harpoon:setup()
vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end, { desc = 'Harpoon add' })
vim.keymap.set('n', '<C-e>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })
for i = 1, 4 do
  vim.keymap.set('n', '<leader>' .. i, function() harpoon:list():select(i) end, { desc = 'Harpoon ' .. i })
end

-- Treesitter: highlighting for your stack + the textobjects you use daily
require('nvim-treesitter').install({vim.g.mapleader = ' '

-- Options: few, and close to defaults, so bare `vi` on a locked-down box still feels like home
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = 'yes'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.undofile = true
  'rust', 'go', 'gomod', 'c', 'cpp', 'python', 'bash', 'lua', 'toml', 'yaml', 'json', 'markdown',
})
vim.api.nvim_create_autocmd('FileType', {
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf) -- highlights when a parser exists, silently no-ops otherwise
  end,
})
for keys, query in pairs({
  af = '@function.outer', ['if'] = '@function.inner',
  aa = '@parameter.outer', ia = '@parameter.inner',
}) do
  vim.keymap.set({ 'x', 'o' }, keys, function()
    require('nvim-treesitter-textobjects.select').select_textobject(query, 'textobjects')
  end)
end

-- LSP: built into nvim 0.11+. One line per server; servers install per-box with
-- the system package manager (most ship with toolchains: rust-analyzer via
-- rustup, gopls via go, clangd via clang, pyright via pip/npm).
local servers = {
  lua_ls        = { cmd = { 'lua-language-server' },            filetypes = { 'lua' },         root_markers = { '.luarc.json', '.git' } },
  clangd        = { cmd = { 'clangd' },                         filetypes = { 'c', 'cpp' },    root_markers = { 'compile_commands.json', '.git' } },
  gopls         = { cmd = { 'gopls' },                          filetypes = { 'go', 'gomod' }, root_markers = { 'go.mod', '.git' } },
  rust_analyzer = { cmd = { 'rust-analyzer' },                  filetypes = { 'rust' },        root_markers = { 'Cargo.toml', '.git' } },
  pyright       = { cmd = { 'pyright-langserver', '--stdio' },  filetypes = { 'python' },      root_markers = { 'pyproject.toml', '.git' } },
}
for name, cfg in pairs(servers) do
  vim.lsp.config(name, cfg)
end
vim.lsp.enable(vim.tbl_keys(servers))

-- Completion: built-in LSP completion with autotrigger.
-- (`vim.o.autocomplete = true` can replace this block once you're 0.12-only.)
vim.o.completeopt = 'menuone,noselect,fuzzy'
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

-- No LSP keymaps needed — defaults since 0.11:
--   grn rename | gra code action | grr references | gri implementation
--   gO document symbols | K hover | <C-]> definition (<C-t> back) | <C-s> signature (insert)

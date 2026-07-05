-- ~/.config/nvim/init.lua — the entire editing suite. One file, zero plugins.
--
-- Bootstrap on any new box (no root needed):
--   curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
--   tar xzf nvim-linux-x86_64.tar.gz && export PATH="$PWD/nvim-linux-x86_64/bin:$PATH"
--   mkdir -p ~/.config/nvim && curl -fsSL https://raw.githubusercontent.com/tristanalderson/subtract-first-neovim/refs/heads/main/init.lua -o ~/.config/nvim/init.lua

vim.g.mapleader = ' '

-- Options: few, and close to defaults, so bare `vi` on a locked-down box still feels like home
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = 'yes'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.undofile = true
vim.o.clipboard = 'unnamedplus'
vim.diagnostic.config({ virtual_text = true })

-- Fuzzy file finding, no plugin: `:find` + fuzzy wildmenu
vim.opt.path:append('**')
vim.opt.wildoptions:append('fuzzy')
vim.o.wildignore = '*/node_modules/*,*/.git/*,*/target/*,*/build/*,*/dist/*'
vim.keymap.set('n', '<leader>f', ':find ', { desc = 'Find file (fuzzy)' })
vim.keymap.set('n', '<leader>b', ':buffer ', { desc = 'Switch buffer' })
vim.keymap.set('n', '<leader>e', ':Ex<CR>', { desc = 'File browser (netrw)' })

-- Project grep into quickfix (ripgrep if the box has it, plain grep otherwise)
if vim.fn.executable('rg') == 1 then
  vim.o.grepprg = 'rg --vimgrep --smart-case'
end
vim.keymap.set('n', '<leader>g', ':silent grep! ', { desc = 'Project grep' })
vim.api.nvim_create_autocmd('QuickFixCmdPost', { pattern = 'grep', command = 'cwindow' })

-- LSP: built into nvim 0.11+. One line per server; servers themselves are
-- installed per-box with the system package manager (most ship with toolchains:
-- rust-analyzer via rustup, gopls via go, clangd via clang).
local servers = {
  lua_ls        = { cmd = { 'lua-language-server' }, filetypes = { 'lua' },        root_markers = { '.luarc.json', '.git' } },
  clangd        = { cmd = { 'clangd' },              filetypes = { 'c', 'cpp' },   root_markers = { 'compile_commands.json', '.git' } },
  gopls         = { cmd = { 'gopls' },               filetypes = { 'go', 'gomod' },root_markers = { 'go.mod', '.git' } },
  rust_analyzer = { cmd = { 'rust-analyzer' },       filetypes = { 'rust' },       root_markers = { 'Cargo.toml', '.git' } },
}
for name, cfg in pairs(servers) do
  vim.lsp.config(name, cfg)
end
vim.lsp.enable(vim.tbl_keys(servers))

-- Completion: built-in LSP completion with autotrigger.
-- (On nvim 0.12+ the single option `vim.o.autocomplete = true` can replace this block.)
vim.o.completeopt = 'menuone,noselect,fuzzy'
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

-- No LSP keymaps needed — these are defaults since 0.11:
--   grn rename | gra code action | grr references | gri implementation
--   gO document symbols | K hover | <C-]> definition (<C-t> back) | <C-s> signature (insert)

-- ~/.config/nvim/init.lua — one file, drop it in and go. Subtract first: all earned.
-- New entries must survive two weeks of daily pain first.
--
-- Core rule: NEVER hard-fail on a missing binary. Everything below guards on
-- vim.fn.executable() and either falls back to a native equivalent or silently
-- no-ops. fzf, ripgrep and language servers are optional: each lights up the
-- moment it lands on PATH — no edit required.
--
-- Needs: nvim 0.12+, git, cc. Treesitter uses the `master` branch, which
-- compiles parsers with `cc` (no tree-sitter CLI needed).
--
-- Plugins auto-install on first launch via vim.pack (built into nvim 0.12).
-- nvim-pack-lock.json pins their revisions, so keep it committed.

vim.g.mapleader = ' '

local function has(bin) return vim.fn.executable(bin) == 1 end

-- Workaround: nvim-treesitter & textobjects switched their default branches to
-- 'main' (which deprecates configs.lua). Force them to track 'master'.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name = ev.data.spec.name
    if (name == 'nvim-treesitter' or name == 'nvim-treesitter-textobjects')
       and (ev.data.kind == 'install' or ev.data.kind == 'update') then
      vim.system({ 'git', 'fetch', 'origin', 'master' }, { cwd = ev.data.path }):wait()
      vim.system({ 'git', 'checkout', 'master' }, { cwd = ev.data.path }):wait()
    end
  end,
})

vim.pack.add({
  'https://github.com/ibhagwan/fzf-lua',                        -- nav (needs fzf+rg; native fallback below)
  'https://github.com/nvim-lua/plenary.nvim',                   -- harpoon dep
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
  -- master branch: ships pre-generated parser sources, compiles with `cc` (no tree-sitter CLI).
  -- GOTCHA: vim.pack's `version=` does NOT reliably check out master here — if configs.lua is
  -- missing after an update, run: git -C ~/.local/share/nvim/site/pack/core/opt/nvim-treesitter checkout master
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter',             version = 'master' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'master' },
  'https://github.com/lewis6991/gitsigns.nvim',                 -- git: gutter signs, hunks, blame (needs only git)
  'https://github.com/tpope/vim-fugitive',                      -- git: full :Git porcelain (needs only git)
  'https://github.com/folke/tokyonight.nvim',                   -- looks
  'https://github.com/folke/which-key.nvim',                    -- popup of available keys after a pause (reads each map's desc)
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
vim.o.path = '.,,**'                    -- native :find can walk the tree by name
vim.opt.wildoptions:append('fuzzy')     -- fuzzy tab-completion in cmdline (:find, :buffer)
vim.diagnostic.config({ virtual_text = true })

-- Native grep prg (real /usr/bin/grep is present). Quickfix opens after a search.
vim.o.grepprg = 'grep -rn --exclude-dir=.git'
vim.o.grepformat = '%f:%l:%m'
vim.api.nvim_create_autocmd('QuickFixCmdPost', { pattern = { 'grep', 'grepadd' }, command = 'cwindow' })

-- Navigation: fzf-lua when its binaries exist, native cmdline otherwise.
local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end
if has('fzf') and has('rg') then
  local fzf = require('fzf-lua')
  map('<leader>f', fzf.files,     'Find files (fzf)')
  map('<leader>g', fzf.live_grep, 'Live grep (rg)')
  map('<leader>b', fzf.buffers,   'Buffers (fzf)')
  map('<leader>r', fzf.resume,    'Resume last picker')
else
  -- Native fallbacks: type-and-fuzzy-complete. No fzf/rg required.
  map('<leader>f', ':find ',   'Find file (native, fuzzy tab-complete)')
  map('<leader>g', ':grep ',   'Grep (native, -> quickfix)')
  map('<leader>b', ':buffer ', 'Switch buffer (native, fuzzy tab-complete)')
  map('<leader>r', function() vim.notify('resume needs fzf-lua (install fzf + ripgrep)', vim.log.levels.INFO) end, 'Resume (needs fzf)')
end
map('<leader>e', ':Ex<CR>', 'File browser (netrw)')

-- Harpoon: the 4 files you live in
local harpoon = require('harpoon')
harpoon:setup()
map('<leader>a', function() harpoon:list():add() end, 'Harpoon add')
vim.keymap.set('n', '<C-e>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })
for i = 1, 4 do
  vim.keymap.set('n', '<leader>' .. i, function() harpoon:list():select(i) end, { desc = 'Harpoon ' .. i })
end

-- Treesitter (master branch): parsers compile with cc, so highlighting + the
-- textobjects you use daily work today with no tree-sitter CLI. Parsers build
-- once on first launch.
require('nvim-treesitter.configs').setup({
  ensure_installed = { 'c', 'cpp', 'python', 'lua', 'bash', 'rust', 'go', 'gomod', 'toml', 'yaml', 'json', 'markdown', 'markdown_inline' },
  auto_install = false,
  highlight = { enable = true },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ['af'] = '@function.outer',  ['if'] = '@function.inner',
        ['aa'] = '@parameter.outer', ['ia'] = '@parameter.inner',
      },
    },
  },
})

-- Treesitter 0.11+ directive compat shim.
-- The `master` branch's query directives assume a directive's `match[id]` is a
-- single TSNode. Neovim 0.11+ changed it to a LIST of nodes (TSNode[]), so the
-- stock handlers call get_node_text() on a table and crash with
--   "attempt to call method 'range' (a nil value)"
-- on EVERY markdown fenced code block (and bash/ruby/etc. via #downcase!).
-- Fix: require the plugin's handlers first so they register, then re-register
-- the three affected ones to unwrap the list. force=true plus Lua's require
-- cache means ours win even though the plugin registers lazily on first parse.
-- Remove this block once master supports the 0.11+ match API (or we move to
-- the `main` branch -- but main needs the tree-sitter CLI, which this box lacks).
pcall(require, 'nvim-treesitter.query_predicates')
do
  local q = vim.treesitter.query
  local function node_of(match, id)
    local v = match[id]
    if type(v) == 'table' then return v[#v] end  -- 0.11+ list -> last node
    return v                                      -- tolerate old single-node API
  end
  q.add_directive('set-lang-from-info-string!', function(match, _, bufnr, pred, metadata)
    local node = node_of(match, pred[2]); if not node then return end
    local alias = vim.treesitter.get_node_text(node, bufnr):lower()
    metadata['injection.language'] = vim.filetype.match({ filename = 'a.' .. alias }) or alias
  end, { force = true, all = false })
  q.add_directive('downcase!', function(match, _, bufnr, pred, metadata)
    local id = pred[2]
    local node = node_of(match, id); if not node then return end
    local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ''
    if not metadata[id] then metadata[id] = {} end
    metadata[id].text = text:lower()
  end, { force = true, all = false })
  q.add_directive('set-lang-from-mimetype!', function(match, _, bufnr, pred, metadata)
    local node = node_of(match, pred[2]); if not node then return end
    local parts = vim.split(vim.treesitter.get_node_text(node, bufnr), '/', {})
    metadata['injection.language'] = parts[#parts]
  end, { force = true, all = false })
end

-- Git in nvim (needs only `git`, which is present):
--   gitsigns  -> gutter signs, hunk nav/stage/reset/preview, inline blame
--   fugitive  -> :Git for full status/commit/log/diff/blame porcelain
require('gitsigns').setup()
local gs = require('gitsigns')
vim.keymap.set('n', ']c', function() gs.nav_hunk('next') end, { desc = 'Next git hunk' })
vim.keymap.set('n', '[c', function() gs.nav_hunk('prev') end, { desc = 'Prev git hunk' })
map('<leader>hs', gs.stage_hunk,   'Stage hunk')
map('<leader>hr', gs.reset_hunk,   'Reset hunk')
map('<leader>hp', gs.preview_hunk, 'Preview hunk')
map('<leader>hb', function() gs.blame_line({ full = true }) end, 'Blame line')
map('<leader>G',  ':Git<CR>',      'Git status (fugitive)')

-- which-key: pause after <leader>, g, z, <C-w>, etc. and a popup lists what's available.
-- Every map's `desc` is what it shows. <leader>? lists the maps active in this buffer.
local wk = require('which-key')
wk.setup({ icons = { mappings = false } })   -- no Nerd Font assumed; plain text only
wk.add({ { '<leader>h', group = 'git hunks' } })
map('<leader>?', function() wk.show({ global = false }) end, 'Buffer-local keymaps (which-key)')

-- LSP: built into nvim 0.11+. Configure every server, but only ENABLE the ones
-- whose binary is actually on PATH — so nvim never throws "no such file (cmd)".
-- When IT installs clangd (etc.), it auto-enables next launch. No edit needed.
local servers = {
  lua_ls        = { cmd = { 'lua-language-server' },           filetypes = { 'lua' },         root_markers = { '.luarc.json', '.git' } },
  clangd        = { cmd = { 'clangd' },                        filetypes = { 'c', 'cpp' },    root_markers = { 'compile_commands.json', '.git' } },
  gopls         = { cmd = { 'gopls' },                         filetypes = { 'go', 'gomod' }, root_markers = { 'go.mod', '.git' } },
  rust_analyzer = { cmd = { 'rust-analyzer' },                 filetypes = { 'rust' },        root_markers = { 'Cargo.toml', '.git' } },
  pyright       = { cmd = { 'pyright-langserver', '--stdio' }, filetypes = { 'python' },      root_markers = { 'pyproject.toml', '.git' } },
  ruff          = { cmd = { 'ruff', 'server' },                filetypes = { 'python' },      root_markers = { 'pyproject.toml', '.git' } },
  verible       = { cmd = { 'verible-verilog-ls' },            filetypes = { 'verilog', 'systemverilog' }, root_markers = { '.git' } },
}
for name, cfg in pairs(servers) do
  vim.lsp.config(name, cfg)
  if has(cfg.cmd[1]) then vim.lsp.enable(name) end
end

-- Completion: built-in LSP completion with autotrigger (only fires when a server attached).
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

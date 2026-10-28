-- nvim-treesitter (main branch) only ships parsers and queries; highlighting
-- has to be started per buffer. Limited to the grammars pinned in default.nix.
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'c', 'cpp', 'lua', 'rust' },
    callback = function() vim.treesitter.start() end,
})

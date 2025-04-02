vim.lsp.config.clangd = {
  cmd = { '@clangd@', '--background-index' },
  root_markers = { 'compile_commands.json', 'compile_flags.txt' },
  filetypes = { 'c', 'cpp' },
}
vim.lsp.enable({'clangd'})

vim.keymap.del('n', 'grn')
vim.keymap.del({'n', 'v'}, 'gra')
vim.keymap.del('n', 'grr')
vim.keymap.del('n', 'gri')
vim.keymap.del('i', '<c-s>')
-- vim.keymap.del('n', 'K')
-- vim.keymap.del('n', 'gO')

-- Formatting selected code.
vim.keymap.set('x', '<leader>=', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', {noremap = true, silent = true})

-- Remap for rename current word
vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', {noremap = true, silent = true})
vim.keymap.set('n', 'gh', '<cmd>lua vim.lsp.buf.hover()<CR>', {noremap = true, silent = true})

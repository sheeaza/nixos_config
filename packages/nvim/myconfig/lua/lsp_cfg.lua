vim.lsp.config.clangd = {
  cmd = { '@clangd@', '--background-index' },
  root_markers = { 'compile_commands.json', 'compile_flags.txt' },
  filetypes = { 'c', 'cpp' },
}
vim.lsp.enable({'clangd'})
vim.lsp.set_log_level("off") -- prevent large log file

vim.keymap.del('n', 'grn')
vim.keymap.del({'n', 'v'}, 'gra')
vim.keymap.del('n', 'grr')
vim.keymap.del('n', 'gri')
vim.keymap.del('i', '<c-s>')
-- vim.keymap.del('n', 'K')
-- vim.keymap.del('n', 'gO')

-- Formatting selected code.
vim.keymap.set('x', '<leader>=',function()
    local start_row, _ = unpack(vim.api.nvim_buf_get_mark(0, "<"))
    local end_row, _ = unpack(vim.api.nvim_buf_get_mark(0, ">"))
    vim.lsp.buf.format({
        range = {
            ["start"] = { start_row, 0 },
            ["end"] = { end_row, 0 },
        },
        async = true,
    })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
end, { desc = "Range Formatting", noremap = true, silent = true })

-- Remap for rename current word
vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', {noremap = true, silent = true})
vim.keymap.set('n', 'gh', '<cmd>lua vim.lsp.buf.hover()<CR>', {noremap = true, silent = true})

vim.diagnostic.config({
    virtual_text = {
        current_line = true,
    }, -- Enable virtual text
})

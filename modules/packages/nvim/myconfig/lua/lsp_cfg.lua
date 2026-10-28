vim.lsp.config.clangd = {
  cmd = { '@clangd@', '--background-index', '--compile-commands-dir=.' },
  root_markers = { 'compile_commands.json', 'compile_flags.txt' },
  filetypes = { 'c', 'cpp' },
}
vim.lsp.enable({'clangd'})
vim.lsp.log.set_level("off") -- prevent large log file

-- Neovim's stock LSP maps all live under the gr prefix. Every one of them has to
-- go, not just the ones whose keys we want back: as long as any grX survives, gr
-- is an ambiguous prefix and our own gr (fzf-lua references) stalls for
-- 'timeoutlen' -- a full second on the default -- while nvim waits to see
-- whether another character is coming. grx was the one left behind here.
for _, lhs in ipairs({ 'grn', 'grr', 'grt', 'gri', 'grx' }) do
    vim.keymap.del('n', lhs)
end
vim.keymap.del({'n', 'v'}, 'gra')
vim.keymap.del('i', '<c-s>')
-- gO duplicates gs (fzf-lua document_symbols), so drop it too.
vim.keymap.del('n', 'gO')

-- Formatting selected code.
vim.keymap.set('x', '<leader>=',function()
    local start_row = unpack(vim.api.nvim_buf_get_mark(0, "<"))
    local end_row = unpack(vim.api.nvim_buf_get_mark(0, ">"))
    vim.lsp.buf.format({
        range = {
            ["start"] = { start_row, 0 },
            ["end"] = { end_row, 0 },
        },
        async = true,
    })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
end, { desc = "Range Formatting", silent = true })

-- Remap for rename current word
vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, {silent = true})
vim.keymap.set('n', 'gh', vim.lsp.buf.hover, {silent = true})

vim.diagnostic.config({
    virtual_text = {
        current_line = true,
    }, -- Enable virtual text
})

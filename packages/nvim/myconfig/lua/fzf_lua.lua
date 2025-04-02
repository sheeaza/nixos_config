require("fzf-lua").setup {
    fzf_bin = '@fzf@',
    keymap = {
        fzf = {
            ["ctrl-d"]      = "half-page-down",
            ["ctrl-u"]      = "half-page-up",
        },
    },
    grep = {
        cmd = "@rg@",
    },
    winopts = {
        preview = {
            layout = "vertical",
        },
    },
}

-- Remap keys for gotos
vim.keymap.set('n', 'gd', '<cmd>FzfLua lsp_definitions<cr>', {noremap = true, silent = true})
vim.keymap.set('n', 'gr', '<cmd>FzfLua lsp_references<cr>', {noremap = true, silent = true})
vim.keymap.set("n", "gD", "<cmd>FzfLua lsp_typedefs<cr>", {silent = true})
vim.keymap.set("n", "gi", "<cmd>FzfLua lsp_implementations<cr>", {silent = true})
-- Find symbol of current document
vim.keymap.set('n', 'gs', '<cmd>FzfLua lsp_document_symbols<cr>', {noremap = true, silent = true})
vim.keymap.set("n", "gw", "<cmd>FzfLua lsp_workspace_symbols<cr>", {silent = true, nowait = true})

vim.keymap.set('n', '<leader>g', ':<C-U><C-R>=printf("Leaderf rg -e %s ", expand("<cword>"))<CR>', {noremap = true})
vim.keymap.set('n', '<leader>lg', ':<C-U><C-R>=printf("Leaderf rg %s -e %s ", expand("%:p:h"), expand("<cword>"))<CR>', {noremap = true})
vim.keymap.set('n', '<leader>lf', '<cmd>printf("FzfLua files cwd=%s", expand("%:p:h"))<CR><CR>', {noremap = true})
vim.keymap.set('n', '<leader>f', '<cmd>FzfLua files<CR>', {noremap = true})
vim.keymap.set('n', '<leader>t', ':rg<C-U><C-R>=printf("Leaderf bufTag %s", "")<CR><CR>', {noremap = true})

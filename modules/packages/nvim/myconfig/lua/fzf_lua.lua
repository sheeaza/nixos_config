require("fzf-lua").setup {
    fzf_bin = '@fzf@',
    keymap = {
        fzf = {
            ["ctrl-d"]      = "half-page-down",
            ["ctrl-u"]      = "half-page-up",
        },
    },
    grep = {
        rg_bin = "@rg@",
    },
    winopts = {
        preview = {
            layout = "vertical",
            wrap = true,
        },
        col = 0.50,
    },
    files = {
        previewer = false,
        actions = {
            ["enter"] = FzfLua.actions.file_edit,
        }
    },
    fzf_opts = {
        ["--wrap"] = true
    },
    btags = {
        ctags_bin = "@ctag@",
    },
}

-- Remap keys for gotos
vim.keymap.set('n', 'gd', '<cmd>FzfLua lsp_definitions<cr>', {silent = true})
vim.keymap.set('n', 'gr', '<cmd>FzfLua lsp_references<cr>', {silent = true})
vim.keymap.set("n", "gD", "<cmd>FzfLua lsp_typedefs<cr>", {silent = true})
vim.keymap.set("n", "gi", "<cmd>FzfLua lsp_implementations<cr>", {silent = true})
-- Find symbol of current document
vim.keymap.set('n', 'gs', '<cmd>FzfLua lsp_document_symbols<cr>', {silent = true})
vim.keymap.set("n", "gw", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", {silent = true, nowait = true})

vim.keymap.set('n', '<leader>g', ':<C-U><C-R>=printf("Fzfgrep -e %s ", expand("<cword>"))<CR>')
vim.keymap.set('n', '<leader>lg', ':<C-U><C-R>=printf("Fzfgrep %s -e %s ", expand("%:p:h"), expand("<cword>"))<CR>')
vim.keymap.set('n', '<leader>lf', ':<C-U><C-R>=printf("Fzffile %s ", expand("%:p:h"))<cr><cr>')
vim.keymap.set('n', '<leader>f', '<cmd>Fzffile<CR>')
vim.keymap.set('n', '<leader>t', '<cmd>FzfLua btags<cr>')
vim.keymap.set('n', '<leader>b', '<cmd>FzfLua buffers<cr>')

local rg_bin="@rg@"
vim.api.nvim_create_user_command('Fzfgrep', function(opts)
    require('fzf-lua').grep({ raw_cmd = rg_bin ..
    " --column --line-number --no-heading --color=always --smart-case --max-columns=150 "
    .. opts.args})
end,
{ nargs = '*' })

vim.api.nvim_create_user_command('Fzffile', function(opts)
    require('fzf-lua').files({ raw_cmd = rg_bin ..
    " --color=never --files "
    .. opts.args})
end,
{ nargs = '*' })

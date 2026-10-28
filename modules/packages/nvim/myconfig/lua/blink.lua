require('blink.cmp').setup({
    keymap = {
        preset = 'none',
        ['<c-j>'] = {
            function(cmp)
                if not cmp.select_next() then
                    return cmp.show()
                end
                return true
            end,
            'fallback',
        },
        ['<c-k>'] = { 'select_prev', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<esc>'] = {
            function(cmp)
                return cmp.cancel({ callback = function()
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
                end})
            end,
            'fallback',
        },
    },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
        documentation = { auto_show = false },
        list = {
            selection = {
                preselect = false,
            },
        },
        keyword = {
            range = 'prefix',
        },
    },
    sources = {
        default = { 'lsp', 'buffer', 'path', 'snippets' },
        providers = {
            buffer = {
                opts = {
                    get_bufnrs = function()
                        return vim.tbl_filter(function(bufnr)
                            return vim.bo[bufnr].buftype == ''
                        end, vim.api.nvim_list_bufs())
                    end
                }
            }
        }
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
    cmdline = { enabled = false },
})
-- cause dup char in tmux alactty
-- vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { fg="#1E90FF", bg="NONE" })

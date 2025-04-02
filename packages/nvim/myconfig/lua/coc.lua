-- Remap keys for gotos
-- vim.keymap.set('n', 'gd', '<Plug>(coc-definition)', {noremap = true, silent = true})
-- vim.keymap.set('n', 'gr', '<Plug>(coc-references)', {noremap = true, silent = true})
-- vim.keymap.set("n", "gD", "<Plug>(coc-type-definition)", {silent = true})
-- vim.keymap.set("n", "gi", "<Plug>(coc-implementation)", {silent = true})
-- Find symbol of current document
-- vim.keymap.set('n', 'gs', ':<C-u>CocList outline<cr>', {noremap = true, silent = true})
-- vim.keymap.set("n", "gw", ":<C-u>CocList -I symbols<cr>", {silent = true, nowait = true})

-- Formatting selected code.
-- vim.keymap.set('x', '<leader>=', '<Plug>(coc-format-selected)')
-- vim.keymap.set('n', '<leader>=', '<Plug>(coc-format-selected)')

-- Remap for rename current word
-- vim.keymap.set('n', '<F2>', '<Plug>(coc-rename)', {silent = true})

-- Auto complete
function _G.check_back_space()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end
local opts = {silent = true, noremap = true, expr = true, replace_keycodes = false}
vim.keymap.set('i', '<c-j>', 'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<c-j>" : coc#refresh()', opts)
vim.keymap.set('i', '<c-k>', 'coc#pum#visible() ? coc#pum#prev(1) : "<c-k>"', opts)
vim.keymap.set('i', '<c-d>', 'coc#pum#visible() ? coc#pum#scroll(1) : "<c-d>"', opts)
vim.keymap.set('i', '<c-u>', 'coc#pum#visible() ? coc#pum#scroll(0) : "<c-u>"', opts)
vim.keymap.set('i', '<cr>', [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], opts)
-- -- Escape: exit autocompletion, go to Normal mode
vim.keymap.set('i', '<Esc>', [[coc#pum#visible() ? "\<C-r>=coc#pum#cancel()\<CR>\<ESC>" : "\<Esc>"]], opts)

-- function _G.show_docs()
    -- local cw = vim.fn.expand('<cword>')
    -- if vim.fn.index({'vim', 'help'}, vim.bo.filetype) >= 0 then
        -- vim.api.nvim_command('h ' .. cw)
    -- elseif vim.api.nvim_eval('coc#rpc#ready()') then
        -- vim.fn.CocActionAsync('doHover')
    -- else
        -- vim.api.nvim_command('!' .. vim.o.keywordprg .. ' ' .. cw)
    -- end
-- end
-- vim.keymap.set('n', 'gh', '<CMD>lua _G.show_docs()<CR>', {noremap = true, silent = true})

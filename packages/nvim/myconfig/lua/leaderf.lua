vim.g.Lf_StlSeparator = { left = '', right = '' }
vim.g.Lf_NoChdir = 1
vim.g.Lf_RecurseSubmodules = 1
vim.g.Lf_WindowPosition = 'popup'
vim.g.Lf_JumpToExistingWindow = 0
vim.g.Lf_GtagsSource = 2
vim.cmd [[
let g:Lf_GtagsfilesCmd = {
        \ '.git': 'rg --no-messages --files -tc -tcpp',
        \ 'default': 'rg --no-messages --files -tc -tcpp'
\}
]]
vim.g.Lf_PreviewResult = { BufTag = 0 }

vim.keymap.set('n', '<slient> <M-d>', ':<C-U>Leaderf gtags --by-context<CR>', {noremap = true})
-- search word under cursor, the pattern is treated as regex, and enter normal mode directly
vim.keymap.set('n', '<leader>g', ':<C-U><C-R>=printf("Leaderf rg -e %s ", expand("<cword>"))<CR>', {noremap = true})
vim.keymap.set('n', '<leader>lg', ':<C-U><C-R>=printf("Leaderf rg %s -e %s ", expand("%:p:h"), expand("<cword>"))<CR>', {noremap = true})
vim.keymap.set('n', '<leader>lf', ':<C-U><C-R>=printf("Leaderf file %s ", expand("%:p:h"))<CR><CR>', {noremap = true})
vim.keymap.set('n', '<leader>t', ':<C-U><C-R>=printf("Leaderf bufTag %s", "")<CR><CR>', {noremap = true})

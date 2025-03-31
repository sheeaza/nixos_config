vim.g.Lf_StlSeparator = { left = '', right = '' }
vim.g.Lf_NoChdir = 1
vim.g.Lf_RecurseSubmodules = 1
vim.g.Lf_WindowPosition = 'popup'
vim.g.Lf_JumpToExistingWindow = 0
vim.g.Lf_PreviewResult = {
	File = 0,
	Tag = 0,
	Function = 0,
	Jumps = 0,
	Mru = 0,
	Rg = 0,
	Line = 0,
	Buffer = 0,
}
vim.g.Lf_Rg = "@rg@"
vim.g.Lf_Ctags = "@ctags@"

-- search word under cursor, the pattern is treated as regex, and enter normal mode directly
-- vim.keymap.set('n', '<leader>g', ':<C-U><C-R>=printf("Leaderf rg -e %s ", expand("<cword>"))<CR>', {noremap = true})
-- vim.keymap.set('n', '<leader>lg', ':<C-U><C-R>=printf("Leaderf rg %s -e %s ", expand("%:p:h"), expand("<cword>"))<CR>', {noremap = true})
-- vim.keymap.set('n', '<leader>lf', ':<C-U><C-R>=printf("Leaderf file %s ", expand("%:p:h"))<CR><CR>', {noremap = true})
-- vim.keymap.set('n', '<leader>t', ':<C-U><C-R>=printf("Leaderf bufTag %s", "")<CR><CR>', {noremap = true})

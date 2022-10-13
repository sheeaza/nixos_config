-- Add spaces after comment delimiters by default
vim.g.NERDSpaceDelims = 1

-- Use compact syntax for prettified multi-line comments
vim.g.NERDCompactSexyComs = 1

vim.g.NERDCreateDefaultMappings = 0

-- Enable NERDCommenterToggle to check all selected lines is commented or not
vim.g.NERDToggleCheckAllLines = 0

vim.keymap.set('', '<M-c>', '<plug>NERDCommenterToggle', {noremap = true})

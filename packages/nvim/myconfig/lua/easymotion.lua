-- s{char}{char}{label}`
-- Need one more keystroke, but on average, it may be more comfortable.
vim.keymap.set('n', 's', '<Plug>(easymotion-s2)', {noremap = true})
vim.keymap.set('v', 's', '<Plug>(easymotion-s2)', {noremap = true})
-- Turn on case-insensitive feature
vim.g.EasyMotion_smartcase = 1
vim.g.EasyMotion_do_mapping = 0 -- Disable default mappings

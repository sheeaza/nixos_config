local flash = require('flash')
flash.setup({
    search = {
        multi_window = false,
    },
    jump = {
        autojump = true
    },
    label = {
        uppercase = false
    }
})

vim.keymap.set({'n', 'o', 'x'}, 's', flash.jump)

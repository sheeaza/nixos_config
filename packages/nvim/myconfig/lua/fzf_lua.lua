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

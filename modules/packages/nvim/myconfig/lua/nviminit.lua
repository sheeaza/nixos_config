-- basic

vim.cmd[[filetype plugin indent on]]
vim.cmd[[syntax enable]]
vim.cmd[[syntax on]]
require('ttheme')
require('basekey')

vim.opt.expandtab = false
vim.opt.softtabstop = 8
vim.opt.tabstop=8
vim.opt.shiftwidth = 8
-- vim.opt.expandtab = true
-- vim.opt.softtabstop=4
-- vim.opt.tabstop=4
-- vim.opt.shiftwidth=4
vim.opt.smartindent = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.ignorecase = true
vim.opt.colorcolumn = '80'
vim.opt.cursorline = true
-- cursorcolumn cause performance issue
vim.opt.cursorcolumn = true
vim.opt.ruler = true
vim.opt.wrap = false
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.hidden = true
vim.opt.laststatus = 3
vim.opt.mouse = ''
vim.opt.ttimeoutlen = 100
vim.opt.signcolumn = 'yes'

-- cmd complete
vim.opt.pumblend = 20
vim.opt.pumheight = 15

-- reload file
vim.api.nvim_create_autocmd(
    {"FocusGained", "BufEnter", "CursorHold", "CursorHoldI"},
    {
	pattern = "*",
	command = "if mode() != 'c' | checktime | endif",
    })
vim.api.nvim_create_autocmd(
    {"FileChangedShellPost"},
    {
	pattern = "*",
	command = "echohl WarningMsg | echo \"File changed on disk. Buffer reloaded.\" | echohl None",
    })

-- *.h to c type
vim.api.nvim_create_autocmd(
    {"BufNewFile", "BufRead"},
    {
        pattern = "*.h",
        command = "set ft=c",
    })

-- whitespace
vim.api.nvim_create_user_command(
    'TrimWhitespace',
    function()
        local view = vim.fn.winsaveview()
        vim.api.nvim_command('keeppatterns %s/\\s\\+$//e')
        vim.fn.winrestview(view)
    end,
    {})

-- plugin config section
require('fzf_lua')
require('lline')
require('fflash')
require('treesitter')
require('nerdco')
require('lsp_cfg')
require('blink')

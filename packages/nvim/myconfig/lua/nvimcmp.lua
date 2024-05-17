-- vim.opt.completeopt = 'menu,menuone,noselect'

local cmp = require'cmp'

-- vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { fg="#fdff00", bg="NONE" })
vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg="#fdff00", bg="NONE" })
vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { fg="#fdff00", bg="NONE" })

cmp.setup({
  completion = { keyword_length = 2 },
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<c-j>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
    ['<c-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
    ['<esc>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources(
    {
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
    },
    {
      {
        name = 'buffer',
	option = {
          get_bufnrs = function()
            local bufs_loaded = {}

            for _, buf_hndl in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf_hndl) then
                    table.insert(bufs_loaded, buf_hndl)
                end
            end
            return bufs_loaded
          end
        }
      },
    }
  )
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({
    { name = 'buffer' },
  })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
require('lspconfig').rust_analyzer.setup {
  capabilities = capabilities,
}
require('lspconfig').clangd.setup {
  capabilities = capabilities,
}

-- key mapping
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(ev)
    local bufmap = function(mode, lhs, rhs)
      local opts = {buffer = ev.buf, silent = true}
      vim.keymap.set(mode, lhs, rhs, opts)
    end
    local builtin = require('telescope.builtin')

    bufmap('n', 'gh', vim.lsp.buf.hover)
    bufmap('n', 'gd', builtin.lsp_definitions)
    bufmap('n', 'gD', vim.lsp.buf.declaration)
    bufmap('n', 'gi', builtin.lsp_implementations)
    bufmap('n', 'go', builtin.lsp_type_definitions)
    bufmap('n', 'gr', builtin.lsp_references)
    bufmap('n', '<F2>', vim.lsp.buf.rename)

    bufmap('n', 'gs', builtin.lsp_document_symbols)
    bufmap('n', 'gw', builtin.lsp_workspace_symbols)
    bufmap('n', '<leader>d', builtin.diagnostics)

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    client.server_capabilities.semanticTokensProvider = nil
  end
})

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false,
    -- Disable a feature
    update_in_insert = false,
  }
)

vim.api.nvim_create_autocmd("CursorHold", {
  pattern = "*",
  callback = function(ev)
    vim.diagnostic.open_float()
  end
})

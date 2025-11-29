-- require('onedark').load()
require("onedarkpro").setup({
  -- colors = {
    -- cursorline = "#FF0000" -- This is optional. The default cursorline color is based on the background
  -- },
  options = {
    cursorline = true
  }
})
vim.cmd("colorscheme onedark")
-- vim.opt.cursorline = true
-- -- cursorcolumn cause performance issue
-- vim.opt.cursorcolumn = true

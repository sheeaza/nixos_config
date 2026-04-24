require('lualine').setup{
  options = {
    component_separators = { left = '│', right = '│'},
    section_separators = '',
  },
  sections = {
    lualine_a = {
      {
        'mode',
      }
    },
    lualine_b = {'filename'},
    lualine_c = {},
    lualine_x = {'fileformat', 'encoding', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
}

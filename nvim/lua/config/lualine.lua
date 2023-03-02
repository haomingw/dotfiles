local ok, lualine = pcall(require, "lualine")
if not ok then
  vim.notify("lualine not found!")
  return
end

lualine.setup {
  options = {
    theme = 'gruvbox-material',
    component_separators = '|',
    section_separators = { left = '', right = '' },
  },
}

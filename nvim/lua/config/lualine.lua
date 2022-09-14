local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
  vim.notify("lualine not found!")
  return
end

lualine.setup {
  options = {
    -- Disable sections and component separators
    component_separators = "",
    section_separators = "",
    theme = 'gruvbox',
  },
}

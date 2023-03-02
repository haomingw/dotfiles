local ok, blankline = pcall(require, "indent_blankline")
if not ok then
  vim.notify("indent_blankline not found!")
  return
end

blankline.setup {
  show_first_indent_level = false,
  show_trailing_blankline_indent = false,
  filetype_exclude = {
    "help",
    "terminal",
    "alpha",
    "packer",
    "lspinfo",
    "startscreen",
    "TelescopePrompt",
    "TelescopeResults",
    "mason",
    "",
  },
}

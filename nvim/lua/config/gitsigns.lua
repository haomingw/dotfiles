local ok, gitsigns = pcall(require, "gitsigns")
if not ok then
  vim.notify("gitsigns not found!")
  return
end

gitsigns.setup {
  current_line_blame = false,
  current_line_blame_opts = {
    delay = vim.o.updatetime,
  },
}

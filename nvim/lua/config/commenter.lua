local ok, commenter = pcall(require, "Comment")
if not ok then
  vim.notify("nvim commenter not found!")
  return
end

commenter.setup({
  mappings = {
    basic = false,
    extra = false,
  }
})

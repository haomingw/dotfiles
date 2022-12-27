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

vim.keymap.set("n", "<c-_>", "<Plug>(comment_toggle_linewise_current)", { desc = "Comment toggle linewise current line" })
vim.keymap.set("x", "<c-_>", "<Plug>(comment_toggle_linewise_visual)", { desc = 'Comment toggle linewise (visual)' })
vim.keymap.set("n", "<leader>/", "<Plug>(comment_toggle_linewise_current)", { desc = "Comment toggle linewise current line" })
vim.keymap.set("x", "<leader>/", "<Plug>(comment_toggle_linewise_visual)", { desc = 'Comment toggle linewise (visual)' })

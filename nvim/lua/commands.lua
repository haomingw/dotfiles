-- Auto commands
-- strip trailing whitespaces on saving
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Highlight on yank
local yankGrp = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Hightlight selection on yank",
  group = yankGrp,
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 100 }
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*",
  command = [[if line("'\"") <= line("$") | execute "normal! g`\"" | endif]],
})

-- User commands
vim.api.nvim_create_user_command(
  "Enc",
  "!cat % | gpgenc > %.gpg",
  {}
)

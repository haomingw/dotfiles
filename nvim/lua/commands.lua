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

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = {"*.ptest"},
  command = "set filetype=json",
})

-- Insert mode
vim.api.nvim_create_autocmd({"InsertEnter"}, {
  command = "set norelativenumber",
})

vim.api.nvim_create_autocmd({"InsertLeave"}, {
  command = "set relativenumber",
})

-- Restore cursor style
vim.api.nvim_create_autocmd({"VimLeave", "VimSuspend"}, {
  command = "set guicursor=a:hor20",
})

-- User commands
vim.api.nvim_create_user_command(
  "Enc",
  "!cat % | gpgenc > %.gpg",
  {}
)

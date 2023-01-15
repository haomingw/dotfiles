local opts = { noremap = true }

local term_opts = { noremap = true, silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

-- Functions
function is_macos()
  return vim.fn.has("macunix")
end

-- Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Utils
keymap("n", ";", ":", opts)
keymap("n", "Y", "y$", opts)
-- Wrapped lines goes down/up to next row, rather than next line in file.
keymap("n", "j", "gj", opts)
keymap("n", "k", "gk", opts)

keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)

-- Editting
keymap("n", "cl", "ggdG", opts)
keymap("n", "<leader>Y", ":%y<cr>", opts)
keymap("i", "<c-j>", "<c-o>o", opts)
keymap("i", "jj", "<c-o>O", opts)

--- set emacs keybindings in insert mode
keymap("i", "<c-b>", "<Left>", opts)
keymap("i", "<c-f>", "<Right>", opts)
keymap("i", "<c-a>", "<Home>", opts)
keymap("i", "<c-e>", "<End>", opts)
keymap("i", "<c-d>", "<Del>", opts)
keymap("i", "<c-h>", "<BS>", opts)
keymap("i", "<c-k>", "<c-o>D", opts)
keymap("i", "<c-p>", "<Up>", opts)
keymap("i", "<c-n>", "<Down>", opts)
keymap("i", "<a-f>", "<c-o>w", opts)
keymap("i", "<a-b>", "<c-o>b", opts)

-- Visual shifting (does not exit Visual mode)
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

keymap("n", "{", "{zz", opts)
keymap("n", "}", "}zz", opts)
keymap("n", "[[", "[[zz", opts)
keymap("n", "]]", "]]zz", opts)
keymap("n", "[]", "[]zz", opts)
keymap("n", "][", "][zz", opts)

-- Better window navigation
keymap("n", "<c-h>", "<c-w>h", opts)
keymap("n", "<c-j>", "<c-w>j", opts)
keymap("n", "<c-k>", "<c-w>k", opts)
keymap("n", "<c-l>", "<c-w>l", opts)

-- Switch between tabs
if is_macos then
  keymap("n", "˙", "gT", opts)
  keymap("n", "¬", "gt", opts)
else
  keymap("n", "<A-h>", "gT", opts)
  keymap("n", "<A-l>", "gt", opts)
end

-- Split
keymap("n", "<leader>ee", ":e ", opts)
keymap("n", "<leader>es", ":sp ", opts)
keymap("n", "<leader>ev", ":vsp ", opts)
keymap("n", "<leader>et", ":tabe ", opts)
keymap("n", "<leader>rp", ":%s/", opts)

-- Copy filename
keymap("n", "<leader>yf", ":let @*=expand('%')<cr>", opts)
keymap("n", "<leader>yp", ":let @*=expand('%:p')<cr>", opts)

-- Plugins --
keymap("n", "<leader>f", ":Neoformat<cr>", opts)

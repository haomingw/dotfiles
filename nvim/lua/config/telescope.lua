local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  vim.notify("telescope not found!")
  return
end

telescope.setup {
  defaults = {
    layout_strategy = 'flex',
    layout_config = { anchor = 'N' },
    scroll_strategy = 'cycle',
    theme = require('telescope.themes').get_dropdown { layout_config = { prompt_position = 'top' } },
  },
  find_command = {
    "rg",
    "--no-heading",
    "--with-filename",
    "--line-number",
    "--column",
    "--smart-case",
    "--color=always",
  },
}

local opts = { noremap = true }
local keymap = vim.api.nvim_set_keymap

keymap("n", "<C-p>", ":Telescope find_files<cr>", opts)
keymap("n", "<leader>rg", ":Telescope live_grep<cr>", opts)

local ok, telescope = pcall(require, "telescope")
if not ok then
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

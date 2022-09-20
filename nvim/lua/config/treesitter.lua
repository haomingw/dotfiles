local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if not ok then
  vim.notify("treesitter not found!")
  return
end

treesitter.setup {
  auto_install = true,
  indent = { enable = false },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<cr>',
      node_incremental = '<tab>',
      scope_incremental = '<cr>',
      scope_decremental = '<s-cr>',
      node_decremental = '<s-tab>',
    },
  },
  textsubjects = {
    enable = true,
    keymaps = {
      ["."] = "textsubjects-smart",
      [";"] = "textsubjects-container-outer",
    },
  },
}

local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if not ok then
  vim.notify("treesitter not found!")
  return
end

treesitter.setup {
  ensure_installed = { "c", "cpp", "python", "lua", "vim", "bash" },
  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,
}

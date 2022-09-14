local status_ok, npairs = pcall(require, "nvim-autopairs")
if not status_ok then
  vim.notify("nvim-autopairs not found!")
  return
end

npairs.setup {
  check_ts = true, -- treesitter integration
}

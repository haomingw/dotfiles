local ok, lspconfig = pcall(require, "lspconfig")
if not ok then
  vim.notify("lspconfig not found!")
  return
end

require("config.lsp.installer")

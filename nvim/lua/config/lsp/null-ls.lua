local ok, null_ls = pcall(require, "null-ls")
if not ok then
  vim.notify("null-ls not found!")
  return
end

local formatting = null_ls.builtins.formatting

null_ls.setup({
  debug = false,
  sources = {
    formatting.stylua,
    formatting.rustfmt,
    formatting.bean_format,
    formatting.clang_format,
    formatting.black.with({ extra_args = { "--fast" } }),
  },
})

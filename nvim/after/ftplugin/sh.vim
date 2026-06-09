" Expand 'usage' to a usage() function snippet.
iabbrev <buffer> usage usage() {<CR>sed -n '2,/^$/p' "$0" \| sed 's/^# \{0,1\}//'<CR>exit 1

syn keyword cppType ll pii

iabbrev inc #include
iabbrev def #define
iabbrev itn int
iabbrev mian main
iabbrev vi vector<int>
iabbrev vvi vector<vector<int> >

if !filereadable(getcwd() . "/Makefile")
  let &makeprg='g++ % -DLOCAL -std=c++17 -O2 -Wall -Wextra
    \ -Wpedantic -Wshadow -Wno-unused-result'
endif

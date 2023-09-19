iabbrev inc #include
iabbrev def #define
iabbrev itn int
iabbrev mian main

if !filereadable(getcwd() . "/Makefile")
  let &makeprg='gcc % -DLOCAL -Wall -Wextra -Werror -Wshadow'
endif

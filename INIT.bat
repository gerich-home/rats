set PATH=%path%;%rats%\lua;%rats%\wxlua\bin
set LUA_DIR=%rats%\lua
set LUA_CPATH=?.dll;%rats%\lua\?.dll;%rats%\lua\C_DIR\?.dll;%rats%\wxlua\bin\?.dll
set LUA_PATH=?.lua;%rats%\lua\?.lua;%rats%\lua\L_DIR\?.lua;%rats%\wxlua\bin\?.lua

lua %rats%\rats.lua
-- LuaRocks configuration

rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/home/runner/work/Luam-CLI/Luam-CLI/.luarocks" };
}
lua_interpreter = "lua";
variables = {
   LUA_DIR = "/home/runner/work/Luam-CLI/Luam-CLI/.lua";
   LUA_BINDIR = "/home/runner/work/Luam-CLI/Luam-CLI/.lua/bin";
}

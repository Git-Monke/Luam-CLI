luacc -o prod/large.lua -i ~/Library/Application\ Support/CraftOS-PC/computers/0.luam\
 luam\
 tar.lib\
 base64.lib\
 functions.add\
 functions.delete\
 functions.init\
 functions.json\
 functions.login\
 functions.post\
 functions.delete.deletePackage\
 functions.install.downloadFile\
 functions.post.encodeFile\
 functions.versions

luamin -f prod/large.lua > prod/luam.lua

rm prod/large.lua
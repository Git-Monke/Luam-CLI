touch release/temp.lua
cd ./src
FILES=$(find . -name '*.lua' | grep -v 'luam.lua' | cut -c3- | sed "s/\.lua$//" | sed "s/\//\./g")
luacc -o ../release/temp.lua luam $FILES 
cd ..

luamin -f release/temp.lua > release/luam.lua
luamin -f installation_script.lua > release/install.lua

rm release/temp.lua
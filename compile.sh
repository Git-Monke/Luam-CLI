touch release/verbose.lua
cd ./src
FILES=$(find . -name '*.lua' | grep -v 'luam.lua' | cut -c3- | sed "s/\.lua$//" | sed "s/\//\./g")
luacc -o ../release/verbose.lua luam $FILES 
luamin -f ../release/verbose.lua > ../release/luam.lua
luamin -f ../installation_script.lua > ../release/install.lua
cd ..

cp ./release/luam.lua ../luamdev.lua
rm ./release/verbose.lua
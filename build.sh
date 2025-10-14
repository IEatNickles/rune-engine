mkdir build -p
odin build ./engine -build-mode:shared -out:build/engine.so
odin build ./sandbox -out:build/sandbox

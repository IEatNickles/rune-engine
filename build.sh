mkdir build -p
odin build ./rune_engine -build-mode:shared -out:build/engine.so
odin build ./sandbox -out:build/sandbox

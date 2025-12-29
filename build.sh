mkdir build -p
odin build ./rune_engine -build-mode:shared -out:build/engine.so
odin build ./sandbox -debug -out:build/sandbox
odin build ./editor -debug -out:build/editor

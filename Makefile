all: sandbox editor
sandbox: bin/engine.so bin/sandbox
editor: bin/engine.so bin/editor

bin/engine.so:
	mkdir bin
	odin build ./rune_engine -build-mode:shared -out:bin/engine.so

bin/editor: bin/engine.so
	odin build ./editor -out:bin/editor

bin/sandbox: bin/engine.so
	odin build ./sandbox -out:bin/sandbox

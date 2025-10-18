REM IDK if ts works, I don't use Windows :P

mkdir build
odin build .\rune_engine -build-mode:shared -out:build\engine.so
odin build .\sandbox -out:build\sandbox

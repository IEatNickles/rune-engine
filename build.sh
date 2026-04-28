#!/bin/sh

BUILD_ENGINE=0
BUILD_EDITOR=0
BUILD_SANDBOX=0
for i in "$@"
do
  case $i in
    editor)
    BUILD_ENGINE=1
    BUILD_EDITOR=1

    ;;
    sandbox)
    BUILD_ENGINE=1
    BUILD_SANDBOX=1

    ;;
    engine)
    BUILD_ENIGNE=1
  esac
done

mkdir bin -p
DONE_TXT="[3D[32m done![0m"
if [ $BUILD_ENGINE -eq 1 ]; then
  echo -n "building bin/engine.so..."
  odin run ./shader_compiler/ -- ./assets/shaders/test.glsl -out:./rune_engine/default_shader.odin
  odin build ./rune_engine -build-mode:shared -out:bin/engine.so
  echo $DONE_TXT
fi
if [ $BUILD_SANDBOX -eq 1 ]; then
  echo -n "building bin/sandbox..."
  odin build ./sandbox -debug -out:bin/sandbox
  echo $DONE_TXT
fi
if [ $BUILD_EDITOR -eq 1 ]; then
  echo -n "building bin/editor..."
  odin build ./editor -debug -out:bin/editor
  echo $DONE_TXT
fi

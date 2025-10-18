# Rune Engine
This is a game engine written in [Odin](https://odin-lang.org/).

# Goals
My goals for this project are for it to be:

* Simple
* Fast
* Cross-platform
* and Extendable

# Building
Make sure you have [Odin](https://odin-lang.org/docs/install/) installed.  
Clone the repo:
```
git clone https://github.com/IEatNickles/rune-engine
```
## Windows
Run the `build.bat` file.
## Linux
Run the `build.sh` file.
## Mac
I _think_ you can just run `build.sh`.
## Manually with the `odin` compiler
Go into the `rune-engine` directory:
```
cd ./path/to/rune/rune-engine/
```
Build the `rune_engine` subdirectory as a shared library: 
```
odin build rune_engine/ -build-mode:shared
```
or a static library:
```
odin build rune_engine/ -build-mode:static
```
_**DO NOT BUILD AS AN EXECUTABLE!!!**_

# Roadmap
[Here is a Trello board](https://trello.com/b/2UwnTTkS/todo) for what I am working on (if I remember to keep it up-to-date).


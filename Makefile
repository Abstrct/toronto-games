# Toronto Games — SNES build
#   make        build toronto_games.sfc
#   make clean

ROM  := toronto_games.sfc
SRC  := $(wildcard src/*.s)
OBJ  := $(patsubst src/%.s,build/obj/%.o,$(SRC))
INC  := $(wildcard src/*.inc)
PY   := $(wildcard tools/*.py)

all: $(ROM)

build/assets.stamp: $(PY)
	python3 tools/build.py
	@touch $@

build/modecheck.stamp: $(SRC) $(INC) tools/modecheck.py
	@mkdir -p build
	python3 tools/modecheck.py
	@touch $@

build/obj/%.o: src/%.s $(INC) build/assets.stamp build/modecheck.stamp
	@mkdir -p build/obj
	ca65 --cpu 65816 -s -I src -I build --bin-include-dir build -o $@ $<

$(ROM): $(OBJ) snes.cfg tools/fixsum.py
	ld65 -C snes.cfg -o $@ -m build/map.txt --dbgfile build/toronto.dbg $(OBJ)
	python3 tools/fixsum.py $@

clean:
	rm -rf build $(ROM)

.PHONY: all clean

# play it: native window around the locally built snes9x libretro core
CORE := build/emu/snes9x/libretro/snes9x_libretro.dylib

build/player: tools/player/player.m
	clang -O2 -fobjc-arc -Wno-deprecated-declarations -I build/emu/snes9x/libretro \
		-framework Cocoa -framework AudioToolbox -framework GameController -o $@ $<

APP := build/Toronto Games.app

app: $(ROM) build/player
	@mkdir -p "$(APP)/Contents/MacOS" "$(APP)/Contents/Resources"
	cp build/player "$(APP)/Contents/MacOS/Toronto Games"
	cp $(CORE) "$(APP)/Contents/Resources/snes9x_libretro.dylib"
	cp $(ROM) "$(APP)/Contents/Resources/toronto_games.sfc"
	cp tools/player/Info.plist "$(APP)/Contents/Info.plist"

run: app
	open "$(APP)"

.PHONY: run app

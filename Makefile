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

# keeps build/emu (the snes9x core) and build/pt (harness sessions, frozen panels, findings)
clean:
	find build -mindepth 1 -maxdepth 1 ! -name emu ! -name pt -exec rm -rf {} +
	rm -f $(ROM)

distclean:
	rm -rf build $(ROM)

.PHONY: all clean distclean

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

# play it in a browser: the page GitHub Pages serves (EmulatorJS + snes9x from its CDN)
#   make web && python3 -m http.server -d build/web
# og.png, icon.png and favicon.png come from tools/og.py (needs build/emu, so they're committed)
WEB := $(wildcard web/*)

web: $(ROM) $(WEB)
	@mkdir -p build/web
	cp $(WEB) $(ROM) build/web/

.PHONY: web

# playtest harness (tools/pt): golden scenes, fuzzing, bot balance, presentation lint, human curves
qa: $(ROM)
	python3 tools/pt/pt.py golden check
	python3 tools/pt/pt.py fuzz -n 12 -f 36000
	python3 tools/pt/pt.py balance -n 6
	python3 tools/pt/pt.py lint
	for e in bike bay park cops sail parking subway; do python3 tools/pt/pt.py curve $$e -n 6; done

.PHONY: qa

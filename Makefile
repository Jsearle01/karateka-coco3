# karateka-coco3 Makefile
# P2.3a.6 — HAL_gfx_blit_sprite + Brøderbund visible
#
# Targets:
#   all              Build production binary + all test drivers
#   karateka.bin     Production binary (build/karateka.bin)
#   tests            Build all test drivers
#   test-sys-init    sys_init_driver.bin
#   test-gfx-init    gfx_init_driver.bin
#   test-visual-smoke visual_smoke_driver.bin
#   test-timer-framesync timer_framesync_driver.bin
#   test-kernel-dispatch kernel_dispatch_driver.bin
#   test-broderbund-splash broderbund_splash_driver.bin (P2.3a.6)
#   clean            Remove build artifacts

LWASM   := lwasm
BUILDDIR := build

# Production source files (order matters for lwasm multi-file pass)
# boot.s first (sets .org $0100 and $0200 entry point)
# globals.s second (equ declarations; no code bytes)
# engine files next
# HAL files last
PROD_SRCS := \
    src/engine/boot.s \
    src/engine/globals.s \
    src/engine/kernel_dispatch.s \
    src/engine/kernel_per_frame.s \
    src/engine/timer_framesync.s \
    src/hal/coco3-dsk/sys.s \
    src/hal/coco3-dsk/gfx.s \
    src/hal/coco3-dsk/time.s \
    src/hal/coco3-dsk/input.s \
    src/hal/coco3-dsk/sound.s \
    src/hal/coco3-dsk/file.s \
    src/hal/coco3-dsk/mem.s

.PHONY: all tests clean \
        test-sys-init test-gfx-init test-visual-smoke \
        test-timer-framesync test-kernel-dispatch \
        test-broderbund-splash test-presents test-sub-byte-shifter \
        test-broderbund-presents-scene

all: $(BUILDDIR)/karateka.bin tests

# ---------------------------------------------------------------
# Production binary
# ---------------------------------------------------------------
$(BUILDDIR)/karateka.bin: $(PROD_SRCS) | $(BUILDDIR)
	$(LWASM) --decb -o $@ $(PROD_SRCS)
	@echo "Production binary: $@ ($$(wc -c < $@) bytes)"

# Convenience alias
karateka.bin: $(BUILDDIR)/karateka.bin

# ---------------------------------------------------------------
# Test driver binaries
# ---------------------------------------------------------------
tests: test-sys-init test-gfx-init test-visual-smoke \
       test-timer-framesync test-kernel-dispatch \
       test-broderbund-splash test-presents test-sub-byte-shifter \
       test-broderbund-presents-scene

test-sys-init: tests/scripted/sys_init_driver.bin
tests/scripted/sys_init_driver.bin: tests/scripted/sys_init_driver.s
	$(LWASM) --decb -o $@ $<
	@echo "sys_init_driver: $@ ($$(wc -c < $@) bytes)"

test-gfx-init: tests/scripted/gfx_init_driver.bin
tests/scripted/gfx_init_driver.bin: tests/scripted/gfx_init_driver.s
	$(LWASM) --decb -o $@ $<
	@echo "gfx_init_driver: $@ ($$(wc -c < $@) bytes)"

test-visual-smoke: tests/scripted/visual_smoke_driver.bin
tests/scripted/visual_smoke_driver.bin: tests/scripted/visual_smoke_driver.s
	$(LWASM) --decb -o $@ $<
	@echo "visual_smoke_driver: $@ ($$(wc -c < $@) bytes)"

test-timer-framesync: tests/scripted/timer_framesync_driver.bin
tests/scripted/timer_framesync_driver.bin: tests/scripted/timer_framesync_driver.s
	$(LWASM) --decb -I src/engine -I src/hal/coco3-dsk -o $@ $<
	@echo "timer_framesync_driver: $@ ($$(wc -c < $@) bytes)"

test-kernel-dispatch: tests/scripted/kernel_dispatch_driver.bin
tests/scripted/kernel_dispatch_driver.bin: tests/scripted/kernel_dispatch_driver.s
	$(LWASM) --decb -o $@ $<
	@echo "kernel_dispatch_driver: $@ ($$(wc -c < $@) bytes)"

test-broderbund-splash: tests/scripted/broderbund_splash_driver.bin
tests/scripted/broderbund_splash_driver.bin: tests/scripted/broderbund_splash_driver.s
	$(LWASM) --decb -o $@ $<
	@echo "broderbund_splash_driver: $@ ($$(wc -c < $@) bytes)"

test-presents: tests/scripted/presents_test_driver.bin
tests/scripted/presents_test_driver.bin: tests/scripted/presents_test_driver.s \
        content/glyph_p/converted.s content/glyph_r/converted.s \
        content/glyph_e/converted.s content/glyph_s/converted.s \
        content/glyph_n/converted.s content/glyph_t/converted.s
	$(LWASM) --decb -o $@ tests/scripted/presents_test_driver.s
	@echo "presents_test_driver: $@ ($$(wc -c < $@) bytes)"

test-sub-byte-shifter: tests/scripted/sub_byte_shifter_test_driver.bin
tests/scripted/sub_byte_shifter_test_driver.bin: tests/scripted/sub_byte_shifter_test_driver.s
	$(LWASM) --decb -o $@ $<
	@echo "sub_byte_shifter_test_driver: $@ ($$(wc -c < $@) bytes)"

test-broderbund-presents-scene: tests/scripted/broderbund_presents_scene_driver.bin
tests/scripted/broderbund_presents_scene_driver.bin: tests/scripted/broderbund_presents_scene_driver.s \
        content/broderbund_logo_sprite_1/converted.s \
        content/broderbund_logo_sprite_2/converted.s \
        content/glyph_p/converted.s content/glyph_r/converted.s \
        content/glyph_e/converted.s content/glyph_s/converted.s \
        content/glyph_n/converted.s content/glyph_t/converted.s
	$(LWASM) --decb -o $@ tests/scripted/broderbund_presents_scene_driver.s
	@echo "broderbund_presents_scene_driver: $@ ($$(wc -c < $@) bytes)"

test-palette: tests/scripted/palette_test_driver.bin
tests/scripted/palette_test_driver.bin: tests/scripted/palette_test_driver.s
	$(LWASM) --decb -o $@ $<
	@echo "palette_test_driver: $@ ($$(wc -c < $@) bytes)"

# ---------------------------------------------------------------
$(BUILDDIR):
	mkdir -p $(BUILDDIR)

clean:
	rm -f $(BUILDDIR)/karateka.bin
	rm -f $(BUILDDIR)/*.log
	rm -f tests/scripted/*.bin
	@echo "Clean complete"

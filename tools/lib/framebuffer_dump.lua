-- tools/lib/framebuffer_dump.lua
-- Shared framebuffer dump helper for MAME CoCo3 test harnesses.
--
-- KNOWN LIMITATION (P2.3a.7 investigation):
--   cpu.spaces["program"]:read_u8() in the $8000+ range returns ROM/pre-GIME data,
--   not the GIME-mapped extended RAM where the framebuffer lives.
--   fb_diagnose_regions() enumerates available regions to find the correct one.
--   fb_dump_phys() reads via the correct physical RAM region once identified.
--
-- Load from any harness Lua script via:
--   dofile("tools/lib/framebuffer_dump.lua")
-- (MAME working directory = C:\karateka-capture; file staged there by run_*.sh)
--
-- API:
--   ok, path, err = fb_dump_frame(prefix, suffix, mem, base_addr)
--   ok, path, err = fb_dump_frameA(prefix, mem)   -- Frame A: $8000-$BBFF
--   ok, path, err = fb_dump_frameB(prefix, mem)   -- Frame B: $C000-$FBFF
--
-- Output goes to dumps/<prefix>_<suffix>.bin (15360 bytes).
-- Caller is responsible for log reporting.
--
-- [ref: P2.3a.6 closure Phase 2 retrospective — screen:snapshot() != live display]
-- [ref: docs/methodology.md §framebuffer-dump-as-canonical-input-signal]

local FB_SIZE  = 15360  -- 192 rows × 80 bytes = $3C00
local FB_A_LOG = 0x8000  -- Frame A logical base (GIME-mapped)
local FB_B_LOG = 0xC000  -- Frame B logical base (GIME-mapped)

local function _write_dump(path, mem, base_addr, length)
    local f, ferr = io.open(path, "wb")
    if not f then
        return false, nil, "cannot open " .. path .. ": " .. tostring(ferr)
    end
    for i = 0, length - 1 do
        f:write(string.char(mem:read_u8(base_addr + i)))
    end
    f:close()
    return true, path, nil
end

function fb_dump_frame(prefix, suffix, mem, base_addr)
    local path = "dumps/" .. prefix .. "_" .. suffix .. ".bin"
    return _write_dump(path, mem, base_addr, FB_SIZE)
end

function fb_dump_frameA(prefix, mem)
    return fb_dump_frame(prefix, "frameA", mem, FB_A_LOG)
end

function fb_dump_frameB(prefix, mem)
    return fb_dump_frame(prefix, "frameB", mem, FB_B_LOG)
end

-- Enumerate all MAME memory regions and log their names + sizes.
-- Call once per run to identify the correct region for extended RAM.
function fb_diagnose_regions(log_fn)
    log_fn("=== MAME memory region enumeration ===")
    local ok, regions = pcall(function() return manager.machine.memory.regions end)
    if not ok or not regions then
        log_fn("  REGION ERROR: cannot access manager.machine.memory.regions")
        return
    end
    for name, region in pairs(regions) do
        log_fn(string.format("  region %-30s size=0x%X (%d)", name, region.size, region.size))
    end

    -- Also probe known program-space addresses for cross-check
    log_fn("=== Program space probes ===")
    local cpu = manager.machine.devices[":maincpu"]
    local mem = cpu.spaces["program"]
    -- Probe $0200 (should contain dispatch RTI = $3B from the test binary)
    local b0200 = mem:read_u8(0x0200)
    log_fn(string.format("  $0200 = $%02X (expect $3B = RTI if binary loaded)", b0200))
    -- Probe $8000 (should contain framebuffer byte $00 if GIME-mapped RAM is visible)
    local b8000 = mem:read_u8(0x8000)
    log_fn(string.format("  $8000 = $%02X (expect framebuffer; $FF/$00 = ROM/pre-GIME)", b8000))
    -- Probe $FFA4 (should be $3C = Frame A bank register after HAL_sys_init)
    local bffa4 = mem:read_u8(0xFFA4)
    log_fn(string.format("  $FFA4 = $%02X (GIME bank for $8000; expect $3C after init)", bffa4))
    log_fn("=== end region enumeration ===")
end

-- Dump framebuffer via physical RAM region (bypasses program-space GIME issue).
-- phys_region_name: MAME region tag (e.g. ":ram" — determined via fb_diagnose_regions)
-- phys_base: physical byte offset of Frame A within that region (e.g. 0x78000 for $3C×$2000)
function fb_dump_phys(prefix, suffix, phys_region_name, phys_base)
    local ok, region = pcall(function()
        return manager.machine.memory.regions[phys_region_name]
    end)
    if not ok or not region then
        return false, nil, "region '" .. phys_region_name .. "' not found"
    end
    if phys_base + FB_SIZE > region.size then
        return false, nil, string.format("region too small: base=0x%X size=%d region.size=%d",
            phys_base, FB_SIZE, region.size)
    end
    local path = "dumps/" .. prefix .. "_" .. suffix .. ".bin"
    local f, ferr = io.open(path, "wb")
    if not f then
        return false, nil, "cannot open " .. path .. ": " .. tostring(ferr)
    end
    for i = 0, FB_SIZE - 1 do
        f:write(string.char(region:read_u8(phys_base + i)))
    end
    f:close()
    return true, path, nil
end

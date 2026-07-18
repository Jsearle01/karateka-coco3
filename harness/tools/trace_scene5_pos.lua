-- Resume dump05_imprison and trace the actual set-dressing draw positions.
-- Poll saved sprite source ($1B/$1C) + screen col $05 + row $06 + sub $10 each
-- frame; collect unique tuples (attract draw order drifts run-to-run so polling
-- samples different sprites over time). This is the empirical position trace.
local DUMP="C:/Projects/karateka_dissasembly_claude/dumps/dump05_imprison.bin"
local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local scr=manager.machine.screens[":screen"]
local logf=io.open("C:/karateka-capture/trace_scene5_pos.log","w")
local function log(s) print(s); logf:write(s.."\n"); logf:flush() end
local seen={}; local st="wait"
log("[pos] armed")
_G._pos=emu.add_machine_frame_notifier(function()
  local f=scr:frame_number()
  if st=="wait" and f>=120 then
    local fh=io.open(DUMP,"rb"); local d=fh:read("*a"); fh:close()
    for a=0x0000,0xBFFF do mem:write_u8(a, string.byte(d,a+1)) end
    cpu.state["PC"].value=0x0D7C; cpu.state["A"].value=0xFF
    cpu.state["X"].value=0xA5; cpu.state["Y"].value=0x98
    pcall(function() cpu.state["SP"].value=0x1FB end); cpu.state["P"].value=0xB4
    st="run"; _G._lf=f; log("[pos] resumed dump05 at $0D7C")
    return
  end
  if st~="run" then return end
  local src=mem:read_u8(0x1C)*256+mem:read_u8(0x1B)
  local col=mem:read_u8(0x05); local row=mem:read_u8(0x06); local sub=mem:read_u8(0x10)
  local key=string.format("%04X:%02X:%02X:%02X",src,col,row,sub)
  if not seen[key] and src>=0x1000 then
    seen[key]=true
    log(string.format("src=$%04X  col=$%02X(%d)  row=$%02X(%d)  sub=$%02X  -> applepx=%d",
        src, col,col, row,row, sub, col*7))
  end
  if f-_G._lf>=600 then log("[pos] done"); logf:close(); manager.machine:exit() end
end)

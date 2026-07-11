local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local dbg=manager.machine.debugger; pcall(function() if dbg then dbg.execution_state="run" end end)
local out=io.open("C:/Projects/karateka_dissasembly_claude/build/logs/snd_phase.log","w")
_G._f=0
-- write-tap on $F7 (every sound trigger's record-ptr store) — logs the FRAME (=phase)
_G._tap=mem:install_write_tap(0xF7,0xF7,"snd",function(o,d,m)
  out:write(string.format("f%d TRIG F7:F8=%02X%02X 4F=%02X 86=%02X gate=%d\n",
    _G._f,mem:read_u8(0xF8),d,mem:read_u8(0x4F),mem:read_u8(0x86),
    (mem:read_u8(0x4F) & mem:read_u8(0x86))~=0 and 1 or 0)); out:flush()
end)
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7400 then out:write(string.format("[FIGHT-FRAME f7400 gate check] 4F=%02X 86=%02X gate=%d\n",
    mem:read_u8(0x4F),mem:read_u8(0x86),(mem:read_u8(0x4F)&mem:read_u8(0x86))~=0 and 1 or 0)) end
  if _G._f>8200 then out:close(); manager.machine:exit() end
end)

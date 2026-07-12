local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local dbg=manager.machine.debugger; pcall(function() if dbg then dbg.execution_state="run" end end)
local out=io.open("C:/Projects/karateka_dissasembly_claude/build/logs/h1_cel_0b12.txt","w")
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7300 then
    out:write("arrow cel $0B12 (h=byte0, w=byte1, then rows):\n")
    local h=mem:read_u8(0x0B12); local w=mem:read_u8(0x0B13)
    out:write(string.format("  header: h=%02X w=%02X\n",h,w))
    for i=0,15 do out:write(string.format("  +%02d $0B%02X = %02X\n",i,0x12+i,mem:read_u8(0x0B12+i))) end
    out:close(); manager.machine:exit()
  end
end)

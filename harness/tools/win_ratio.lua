local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/win_ratio.tr"
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7245 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- at each fight_ai decision ($A03D), log the ACTIVE combatant ($22 pos) + selected action ($29 at $6540)
    pcall(function() cpu.debug:bpset(0xA03D,nil,'tracelog "<<<AI 22=%02X 62=%02X 72=%02X>>>",b@0x22,b@0x62,b@0x72; go') end)
    pcall(function() cpu.debug:bpset(0x6540,nil,'tracelog "<<<ACT 29=%02X 22=%02X>>>",a,b@0x22; go') end)
  end
  if _G._f>8145 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)

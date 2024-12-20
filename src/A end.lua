function MaticzplChipmaker.EveryFrame()
    if ren.hud() then        
        cMaker.DrawCursorDisplay()
    end
end

function MaticzplChipmaker.Init()
    event.register(event.keypress, cMaker.OnKey)
    event.register(event.mousedown,cMaker.OnMouseDown)
    --event.register(event.mouseup,  cMaker.OnMouseUp)
    event.register(event.mousemove,cMaker.OnMouseMove)
    event.register(event.tick,     cMaker.EveryFrame)
    event.register(event.close,    cMaker.SaveSettings)

    tpt.setdebug(bit.bor(0x8, 0x4))

    -- Test tmp3/4 or pavg0/1 detection
    local part = sim.partCreate(-3,4,4,1)
    pcall(sim.partProperty, part, "tmp3", 2138)
    local _, res = pcall(sim.partProperty, part, "tmp3")
    sim.partKill(part)
    if res == 2138 then
        MaticzplChipmaker.tmp3name = "tmp3"
        MaticzplChipmaker.tmp4name = "tmp4"
        MaticzplChipmaker.propTable[6] = "tmp3"
        MaticzplChipmaker.propTable[7] = "tmp4"
    else
        MaticzplChipmaker.tmp3name = "pavg0"
        MaticzplChipmaker.tmp4name = "pavg1"   
        MaticzplChipmaker.propTable[6] = "pavg0"
        MaticzplChipmaker.propTable[7] = "pavg1"
    end

    local MANAGER = rawget(_G, "MANAGER")    

    local CDBgColA = MANAGER.getsetting("MaticzplCmaker","CDBgColA")    
    if CDBgColA ~= nil then
        cMaker.Settings.cursorDisplayBgAlpha = CDBgColA 
    end
end

cMaker.Init()
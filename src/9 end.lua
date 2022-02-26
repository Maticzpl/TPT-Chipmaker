function MaticzplChipmaker.EveryFrame()
    if tpt.hud() == 1 then        
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


    local MANAGER = rawget(_G, "MANAGER")    

    local CDBgColA = MANAGER.getsetting("MaticzplCmaker","CDBgColA")    
    if CDBgColA ~= nil then
        cMaker.Settings.cursorDisplayBgAlpha = CDBgColA 
    end
end

cMaker.Init()
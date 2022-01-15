function MaticzplChipmaker.EveryFrame()
    cMaker.StackEdit.selected = -1    
    if tpt.hud() == 1 then        
        cMaker.DrawCursorDisplay()
    end
    
    if cMaker.StackTool.isInStackMode then
        graphics.drawText(15,359,"Stacking Mode (right click to cancel)",252, 232, 3)
        
        if cMaker.StackTool.mouseDown then            
            local startX = cMaker.StackTool.realStart.x
            local startY = cMaker.StackTool.realStart.y
            
            local cx = cMaker.CursorPos.x
            local cy = cMaker.CursorPos.y
            
            cMaker.DrawRect(startX,startY,cx,cy,255,255,255,70,true)      
        end
    end    

    if cMaker.ConfigTool.inConfigMode then
        --cMaker.handleConfigTool()
    end
end

function MaticzplChipmaker.Init()
    event.register(event.keypress, cMaker.OnKey)
    event.register(event.mousedown,cMaker.OnMouseDown)
    event.register(event.mouseup,  cMaker.OnMouseUp)
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

--TODO: 
--  Config tool
--  Particle reorder function
--  Call the particle reorder function when using stack tool
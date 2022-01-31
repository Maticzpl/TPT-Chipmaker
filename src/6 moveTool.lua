function MaticzplChipmaker.MoveTool.StartRect(x,y)
    cMaker.MoveTool.mouseDown = true
    x,y = sim.adjustCoords(x,y)
    cMaker.MoveTool.rectStart = {x = x, y = y}
end

function MaticzplChipmaker.MoveTool.EndRect(x,y)
    cMaker.MoveTool.mouseDown = false
    x,y = sim.adjustCoords(x,y)
    cMaker.MoveTool.rectEnd = {x = x, y = y}
    cMaker.MoveTool.isDragging = true    


end

function MaticzplChipmaker.MoveTool.Place(x,y)
    local s = cMaker.MoveTool
    
    local xDirection = 1
    if s.rectStart.x > s.rectEnd.x then
        xDirection = -1
    end
    
    local yDirection = 1
    if s.rectStart.y > s.rectEnd.y then
        yDirection = -1
    end

    sim.takeSnapshot()
    for l, stack in pairs(MaticzplChipmaker.GetAllPartsInRegion(s.rectStart.x,s.rectStart.y,s.rectEnd.x,s.rectEnd.y)) do
        for k, part in pairs(stack) do
            local x,y = sim.partPosition(part)
            sim.partProperty(part,'x',x - s.movement.x)
            sim.partProperty(part,'y',y - s.movement.y)
        end        
    end
end

function MaticzplChipmaker.MoveTool.EnableMoveMode()
    cMaker.DisableAllModes()
    cMaker.MoveTool.isInMoveMode = true
end

function MaticzplChipmaker.MoveTool.DisableMoveMode()    
    cMaker.MoveTool.isInMoveMode = false            
    cMaker.MoveTool.rectEnd = {x = 0, y = 0}
    cMaker.MoveTool.rectStart = {x = 0, y = 0}
end

local function MoveToolInit()
    event.register(event.keypress, 
        function (key,scan,_repeat,shift,ctrl,alt)
            if key == 109 and not shift and not ctrl and not alt and not _repeat then -- M        
                cMaker.MoveTool.EnableMoveMode()
                return false
            end 
        end
    )
    
    event.register(event.mousedown, 
        function (x,y,button)     
            if cMaker.MoveTool.isInMoveMode and button == 1 then
                if cMaker.MoveTool.isDragging then
                    cMaker.MoveTool.Place(x,y)
                else
                    cMaker.MoveTool.StartRect(x,y)
                end               
                return false        
            end
        end
    )
    event.register(event.mouseup, 
        function (x,y,button,reason)  
            if cMaker.MoveTool.isInMoveMode and button == 1 then
                if not cMaker.MoveTool.isDragging then
                    cMaker.MoveTool.EndRect(x,y)
                    return false
                else
                    cMaker.MoveTool.isDragging = false
                    cMaker.MoveTool.DisableMoveMode()
                end
            end  
        end
    )

    event.register(event.tick,
        function ()
            if cMaker.MoveTool.isInMoveMode then
                cMaker.DrawModeText("Move Tool (right click to cancel)")

                local cursorX, cursorY = sim.adjustCoords(cMaker.CursorPos.x, cMaker.CursorPos.y)

                if cMaker.MoveTool.mouseDown then
                    cMaker.MoveTool.rectEnd.x = cursorX
                    cMaker.MoveTool.rectEnd.y = cursorY

                    cMaker.DrawRect(
                        cMaker.MoveTool.rectStart.x,
                        cMaker.MoveTool.rectStart.y,
                        cMaker.MoveTool.rectEnd.x,
                        cMaker.MoveTool.rectEnd.y,
                        255,255,255,128
                    )
                else
                    if cMaker.MoveTool.isDragging then
                        cMaker.MoveTool.movement.x = cMaker.MoveTool.rectStart.x - cursorX
                        cMaker.MoveTool.movement.y = cMaker.MoveTool.rectStart.y - cursorY
                                                
                        cMaker.DrawRect(
                            cMaker.MoveTool.rectStart.x - cMaker.MoveTool.movement.x,
                            cMaker.MoveTool.rectStart.y - cMaker.MoveTool.movement.y,
                            cMaker.MoveTool.rectEnd.x - cMaker.MoveTool.movement.x,
                            cMaker.MoveTool.rectEnd.y - cMaker.MoveTool.movement.y,
                            255,255,255,128
                        )
                    end
                end
            end
        end
    )
end

MoveToolInit()
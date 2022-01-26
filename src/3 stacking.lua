-- v[STACK TOOL]v
function MaticzplChipmaker.StackTool.Stack()
    local s = cMaker.StackTool
    
    local partsMoved = 0
    
    cMaker.ReorderParticles()
    
    local xDirection = 1
    if s.rectStart.x > s.rectEnd.x then
        xDirection = -1
    end
    
    local yDirection = 1
    if s.rectStart.y > s.rectEnd.y then
        yDirection = -1
    end
    
    for x =     s.rectStart.x, s.rectEnd.x, xDirection do
        for y = s.rectStart.y, s.rectEnd.y, yDirection do
            local parts = cMaker.GetAllPartsInPos(x,y)
            
            for i,part in pairs(parts) do
                if part ~= nil then
                    if x ~= s.rectEnd.x and y ~= s.rectEnd.y then   --count every particle except the ones that got already stacked
                        partsMoved = partsMoved + 1
                    elseif partsMoved < #parts then
                        partsMoved = partsMoved + 1
                    end
                end
                
                
                sim.partProperty(part,"x",s.rectEnd.x)
                sim.partProperty(part,"y",s.rectEnd.y)
            end
        end
    end
    
    if partsMoved > 5 then
        print("Warning: More than 5 particles stacked")
        tpt.set_pause(1)
    end
    
end

function MaticzplChipmaker.StackTool.Unstack()
    local s = cMaker.StackTool
    -- rectStart == rectEnd
    
    local parts = cMaker.GetAllPartsInPos(s.rectStart.x,s.rectStart.y)
    
    -- Check if space is free
    local collision = false
    local xOffset = 0
    local yOffset = 0 
    for i,part in pairs(parts) do
        local posX = s.rectStart.x + xOffset
        local posY = s.rectStart.y + yOffset

        local inPos = simulation.partID(posX,posY)
        if ( inPos ~= nil and i ~= 1 ) or 
         (posX > 607) or (posY > 379) or (posX < 4) or (posY < 4) then
            collision = true
            break
        end
        
        yOffset = yOffset + 1
        if yOffset >= cMaker.Settings.unstackHeight then
            xOffset = xOffset + 1
            yOffset = 0
        end
    end
    
    if collision then
        print("Not enough space to unstack")
    else
        xOffset = 0
        yOffset = 0 
        for i,part in pairs(parts) do
            sim.partProperty(part,"y",s.rectStart.y + yOffset)
            sim.partProperty(part,"x",s.rectStart.x + xOffset)
           
        
            yOffset = yOffset + 1
            if yOffset >= cMaker.Settings.unstackHeight then
                xOffset = xOffset + 1
                yOffset = 0
            end
        end
    end
    
end

function MaticzplChipmaker.StackTool.StartStackRectangle(x,y)    
    cMaker.StackTool.realStart = {x=x,y=y}
    x, y = simulation.adjustCoords(x,y)            
    cMaker.StackTool.rectStart = {x = x,y = y}
end

function MaticzplChipmaker.StackTool.FinishStacking(x,y)
    cMaker.StackTool.realEnd = {x=x,y=y}
    x, y = simulation.adjustCoords(x,y)    
    cMaker.StackTool.rectEnd = {x = x,y = y}
    
    if cMaker.StackTool.rectEnd.x == cMaker.StackTool.rectStart.x and
    cMaker.StackTool.rectEnd.y == cMaker.StackTool.rectStart.y then
        cMaker.StackTool.Unstack()
    else
        cMaker.StackTool.Stack()
    end
    
    cMaker.StackTool.DisableStackMode()    
end


function MaticzplChipmaker.StackTool.EnableStackMode()
    cMaker.DisableAllModes()
    cMaker.StackTool.isInStackMode = true
end

function MaticzplChipmaker.StackTool.DisableStackMode()    
    cMaker.StackTool.mouseDown = false            
    cMaker.StackTool.isInStackMode = false    
end

local function StackToolInit()   
    event.register(event.keypress, 
        function (key,scan,_repeat,shift,ctrl,alt)
            if key == 115 and shift and not ctrl and not alt and not _repeat then -- SHIFT + S
                cMaker.StackTool.EnableStackMode();
                return false
            end
        end
    )
    event.register(event.mousedown, 
        function (x,y,button)     
            if cMaker.StackTool.isInStackMode and button == 1 then
                cMaker.StackTool.mouseDown = true
                cMaker.StackTool.StartStackRectangle(x,y)
                return false        
            end
        end
    )
    event.register(event.mouseup, 
        function (x,y,button,reason)  
            if cMaker.StackTool.isInStackMode and button == 1 then
                  cMaker.StackTool.FinishStacking(x,y)
                return false
            end  
        end
    )
    event.register(event.tick, 
        function ()  
            if cMaker.StackTool.isInStackMode then
                cMaker.DrawModeText("Stacking Mode (right click to cancel)")
                
                if cMaker.StackTool.mouseDown then            
                    local startX = cMaker.StackTool.realStart.x
                    local startY = cMaker.StackTool.realStart.y
                    
                    local cx = cMaker.CursorPos.x
                    local cy = cMaker.CursorPos.y
                    
                    cMaker.DrawRect(startX,startY,cx,cy,255,255,255,70,true)      
                end
            end 
        end
    )

end

StackToolInit()
-- ^[STACK TOOL]^
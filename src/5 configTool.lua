-- v[CONFIG TOOL]v
function MaticzplChipmaker.ConfigTool.EnableConfigMode()
    cMaker.DisableAllModes()
    cMaker.ConfigTool.inConfigMode = true
end

function MaticzplChipmaker.ConfigTool.DisableConfigMode()
    cMaker.ConfigTool.inConfigMode = false           
    cMaker.ConfigTool.isSetting1 = false          
    cMaker.ConfigTool.isSetting2 = false         
    cMaker.ConfigTool.setting1Value = -1         
    cMaker.ConfigTool.setting2Value = -1        
    cMaker.ConfigTool.target = -1    
end

function MaticzplChipmaker.ConfigTool.GetEndInDirection(direction,centerx,centery,distance)
    local x = centerx
    local y = centery
    
    if direction == 1 then --Left top
        x = centerx - distance
        y = centery - distance
        return {x = x, y = y}
    end
    if direction == 2 then
        y = centery - distance
        return {x = x, y = y}        
    end
    if direction == 3 then
        x = centerx + distance
        y = centery - distance
        return {x = x, y = y}        
    end
    if direction == 4 then
        x = centerx + distance
        return {x = x, y = y}        
    end
    if direction == 5 then
        x = centerx + distance
        y = centery + distance
        return {x = x, y = y}        
    end
    if direction == 6 then
        y = centery + distance
        return {x = x, y = y}        
    end
    if direction == 7 then
        x = centerx - distance
        y = centery + distance
        return {x = x, y = y}          
    end    
    if direction == 8 then
        x = centerx - distance
        return {x = x, y = y}        
    end


    return {x = x, y = y}
end

function MaticzplChipmaker.ConfigTool.CheckUsefulNeighbors(direction,x,y,type)
    local part = nil
    if direction == 1 then
        part = sim.partID(x-1,y-1)
    end
    if direction == 2 then
        part = sim.partID(x,y-1)
    end
    if direction == 3 then
        part = sim.partID(x+1,y-1)
    end
    if direction == 4 then
        part = sim.partID(x+1,y)
    end
    if direction == 5 then
        part = sim.partID(x+1,y+1)
    end
    if direction == 6 then
        part = sim.partID(x,y+1)
    end
    if direction == 7 then
        part = sim.partID(x-1,y+1)
    end
    if direction == 8 then
        part = sim.partID(x-1,y)
    end    
    if part == nil then
        return false
    end

    local t = sim.partProperty(part,'type')

    if (t == elem.DEFAULT_PT_FILT and type == elem.DEFAULT_PT_LDTC) or t == elem.DEFAULT_PT_SPRK or t == elem.DEFAULT_PT_METL or t == elem.DEFAULT_PT_PSCN or t == elem.DEFAULT_PT_NSCN or t == elem.DEFAULT_PT_TUNG or t == elem.DEFAULT_PT_INWR or t == elem.DEFAULT_PT_INST or t == elem.DEFAULT_PT_BMTL or t == elem.DEFAULT_PT_TTAN or t == elem.DEFAULT_PT_IRON then
        return true
    end

    return false
end

function MaticzplChipmaker.ConfigTool.OffsetToDirection(x,y,cx,cy)
    local fx = cx - x
    local fy = cy - y

    local a = math.atan2(fx,-fy) * (180/math.pi)

    if a < 0 then
        a = 360 + a
    end

    --0(0,-1)    45  (1,-1)

    --   X       90  (1,0 )

    --180(0,1)   135 (1,1 )

    if (a > (360-20) and a <= 0) --0
        or 
        (a >= 0 and a < 20) then
        return 2 -- top
    end
    if a >= 20 and a <=70 then --45
        return 3
    end
    if a > 70 and a < 110 then --90
        return 4
    end
    if a >= 110 and a <=160 then --135
        return 5
    end
    if a > 160 and a < 200 then --180
        return 6
    end
    if a >= 200 and a <= 250 then --225
        return 7
    end
    if a > 250 and a < 290 then --270
        return 8
    end
    if a >= 290 and a <= 340 then --315
        return 1
    end
    
    

end

function MaticzplChipmaker.ConfigTool.DrawPartConfig(part,overwriteDirection)  
    local type = sim.partProperty(part,'type')
    local x, y = sim.partPosition(part)
    
    if type == elem.DEFAULT_PT_DTEC or type == elem.DEFAULT_PT_TSNS or type == elem.DEFAULT_PT_LSNS then
        local r = sim.partProperty(part,'tmp2')
        
        MaticzplChipmaker.DrawRect(x-r,y-r,x+r,y+r, 0, 255, 0, cMaker.ConfigTool.overlayAlpha);
        return
    end

    if type == elem.DEFAULT_PT_LDTC or type == elem.DEFAULT_PT_CRAY then
        local skip = sim.partProperty(part,'life')
        local range = sim.partProperty(part,'tmp')
        if type == elem.DEFAULT_PT_CRAY then            
            skip = sim.partProperty(part,'tmp2')
            range = sim.partProperty(part,'tmp')
        end

        for d = 1, 8, 1 do --8 directions
            local opposite = d + 4
            if opposite > 8 then
                opposite = opposite - 8
            end
            
            if overwriteDirection ~= nil then
                d = overwriteDirection
            end
            if cMaker.ConfigTool.CheckUsefulNeighbors(opposite,x,y,type) or overwriteDirection ~= nil then               
                local lineEnd = cMaker.ConfigTool.GetEndInDirection(d,x,y,skip)                
                cMaker.DrawLine(x+0.5,y+0.5,lineEnd.x+0.5,lineEnd.y+0.5, 255,0,0,cMaker.ConfigTool.overlayAlpha)

                local rangeStart =  cMaker.ConfigTool.GetEndInDirection(d,lineEnd.x,lineEnd.y,0)    
                if d % 2 == 0 then
                    rangeStart = cMaker.ConfigTool.GetEndInDirection(d,lineEnd.x,lineEnd.y,1)                    
                end

                local rangeEnd =    cMaker.ConfigTool.GetEndInDirection(d,rangeStart.x,rangeStart.y,range-1)            
                if range > 0 then         
                    cMaker.DrawLine(rangeStart.x+0.5,rangeStart.y+0.5,rangeEnd.x+0.5,rangeEnd.y+0.5, 0,255,0,cMaker.ConfigTool.overlayAlpha)
                end
            end
        end
        return
    end

    if type == elem.DEFAULT_PT_DRAY then
        local range = sim.partProperty(part,'tmp')
        local skip = sim.partProperty(part,'tmp2')
        for d = 1, 8, 1 do --8 directions
            local opposite = d + 4
            if opposite > 8 then
                opposite = opposite - 8
            end
            
            if overwriteDirection ~= nil then
                d = overwriteDirection
            end
            if cMaker.ConfigTool.CheckUsefulNeighbors(opposite,x,y,type) or overwriteDirection ~= nil then  
                local lineEnd = cMaker.ConfigTool.GetEndInDirection(d,x,y,range)
                cMaker.DrawLine(x+0.5,y+0.5,lineEnd.x+0.5,lineEnd.y+0.5, 255,0,0,cMaker.ConfigTool.overlayAlpha)

                local rangeStart = cMaker.ConfigTool.GetEndInDirection(d,lineEnd.x,lineEnd.y,0)
                if d % 2 == 0 then
                    rangeStart = cMaker.ConfigTool.GetEndInDirection(d,lineEnd.x,lineEnd.y,1)                    
                end
                local rangeEnd = cMaker.ConfigTool.GetEndInDirection(d,rangeStart.x,rangeStart.y,skip-1)
                cMaker.DrawLine(rangeStart.x+0.5,rangeStart.y+0.5,rangeEnd.x+0.5,rangeEnd.y+0.5, 0,255,0,cMaker.ConfigTool.overlayAlpha)
                
                local targetStart = cMaker.ConfigTool.GetEndInDirection(d,rangeEnd.x,rangeEnd.y,0)
                if d % 2 == 0 then
                    targetStart = cMaker.ConfigTool.GetEndInDirection(d,rangeEnd.x,rangeEnd.y,1)                 
                end
                local targetEnd = cMaker.ConfigTool.GetEndInDirection(d,targetStart.x,targetStart.y,range-1)
                cMaker.DrawLine(targetStart.x+0.5,targetStart.y+0.5,targetEnd.x+0.5,targetEnd.y+0.5, 255,0,0,cMaker.ConfigTool.overlayAlpha)
            end
        end
        return
    end

end

function MaticzplChipmaker.ConfigTool.SetFirst(part)
    local cx, cy = sim.adjustCoords(cMaker.CursorPos.x,cMaker.CursorPos.y)

    local type = sim.partProperty(part,'type')
    local x, y = sim.partPosition(part)
    
    if type == elem.DEFAULT_PT_DTEC or type == elem.DEFAULT_PT_TSNS or type == elem.DEFAULT_PT_LSNS then
        --local distance = math.floor(math.sqrt(((x-cx)*(x-cx)) + ((y-cy)*(y-cy)))) --No, its a square xd
        local distance = math.abs(math.max(math.max(x - cx,cx - x), math.max(y - cy, cy - y)))
                     
        sim.partProperty(part,'tmp2',distance)
        return
    end

    if type == elem.DEFAULT_PT_LDTC or type == elem.DEFAULT_PT_CRAY then
        local direction = cMaker.ConfigTool.OffsetToDirection(x,y,cx,cy)
        local distance = math.abs(math.max(math.max(x - cx,cx - x), math.max(y - cy, cy - y)))
        
        if type == elem.DEFAULT_PT_LDTC then
            sim.partProperty(part,'life',distance)        
        else
            sim.partProperty(part,'tmp2',distance)
        end
        cMaker.ConfigTool.setting1Value = distance
        cMaker.ConfigTool.direction = direction
        return
    end

    if type == elem.DEFAULT_PT_DRAY then
        local direction = cMaker.ConfigTool.OffsetToDirection(x,y,cx,cy)
        local distance = math.abs(math.max(math.max(x - cx,cx - x), math.max(y - cy, cy - y)))
        
        sim.partProperty(part,'tmp',distance)   

        cMaker.ConfigTool.setting1Value = distance
        cMaker.ConfigTool.direction = direction        
        return
    end
end

function MaticzplChipmaker.ConfigTool.SetSecond(part)
    local cx, cy = sim.adjustCoords(cMaker.CursorPos.x,cMaker.CursorPos.y)

    local type = sim.partProperty(part,'type')
    local px, py = sim.partPosition(part)
    
    if type == elem.DEFAULT_PT_LDTC or type == elem.DEFAULT_PT_CRAY then
        local endPoint = cMaker.ConfigTool.GetEndInDirection(cMaker.ConfigTool.direction,px,py,cMaker.ConfigTool.setting1Value)
        local distance = math.abs(math.max(math.max(endPoint.x - cx,cx - endPoint.x), math.max(endPoint.y - cy, cy - endPoint.y)))
        
        sim.partProperty(part,'tmp',distance)
        cMaker.ConfigTool.setting2Value = distance
        return
    end

    if type == elem.DEFAULT_PT_DRAY then
        local endPoint = cMaker.ConfigTool.GetEndInDirection(cMaker.ConfigTool.direction,px,py,cMaker.ConfigTool.setting1Value)
        local distance = math.abs(math.max(math.max(endPoint.x - cx,cx - endPoint.x), math.max(endPoint.y - cy, cy - endPoint.y)))
        
        sim.partProperty(part,'tmp2',distance)

        cMaker.ConfigTool.setting2Value = distance
        return
    end
end

local function ConfigToolInit()
    event.register(event.keypress, 
        function (key,scan,_repeat,shift,ctrl,alt)
            if key == 99 and not shift and not ctrl and not alt and not _repeat  then   -- C
                cMaker.ConfigTool.EnableConfigMode()
                return false    
            end            
        end
    )

    event.register(event.mousedown,
        function(x,y,button)
            if cMaker.ConfigTool.inConfigMode and button == 1 and not cMaker.ConfigTool.mouseHeld then   
                if not cMaker.ConfigTool.isSetting1 and not cMaker.ConfigTool.isSetting2 then    

                    cMaker.ConfigTool.target = cMaker.StackEdit.selected   
                    cMaker.ConfigTool.isSetting1 = true     

                    if cMaker.ConfigTool.target == -1 then            
                        cMaker.DisableAllModes()                        
                    end                     
                    return false
                end

                if cMaker.ConfigTool.isSetting1 then
                    cMaker.ConfigTool.isSetting1 = false  
                    cMaker.ConfigTool.isSetting2 = true      
                    return false                
                end
                if cMaker.ConfigTool.isSetting2 then      
                    cMaker.DisableAllModes()           
                    return false                                           
                end

                cMaker.ConfigTool.mouseHeld = true
                return false   
            end
        end
    )

    event.register(event.mouseup,
        function(x,y,button)
            if button == 1 then     
                cMaker.ConfigTool.mouseHeld = false
            end
        end
    )

    
    event.register(event.tick, 
        function ()   
            if cMaker.ConfigTool.inConfigMode then
                cMaker.DrawModeText("Config Mode (right click to cancel)")

                local target = MaticzplChipmaker.StackEdit.selected
                if cMaker.ConfigTool.target ~= -1 then
                    target = cMaker.ConfigTool.target
                end

                if cMaker.ConfigTool.isSetting1 then
                    cMaker.ConfigTool.SetFirst(target)       
                end
                if cMaker.ConfigTool.isSetting2 then
                    local type = sim.partProperty(target,'type')
                    if type == elem.DEFAULT_PT_DTEC or type == elem.DEFAULT_PT_TSNS or type == elem.DEFAULT_PT_LSNS then 
                        cMaker.DisableAllModes() 
                        return                                  
                    end

                    cMaker.ConfigTool.SetSecond(target)    
                end

                if target ~= -1 then      
                    local x,y = sim.partPosition(target)
                    local cx, cy = sim.adjustCoords(cMaker.CursorPos.x,cMaker.CursorPos.y)
                    if not cMaker.ConfigTool.isSetting1 and not cMaker.ConfigTool.isSetting2 then
                        cMaker.ConfigTool.DrawPartConfig(target)
                    else
                        cMaker.ConfigTool.DrawPartConfig(target,cMaker.ConfigTool.OffsetToDirection(x,y,cx,cy))
                    end
                end

                
            end       
        end
    )
end

ConfigToolInit()
-- ^[CONFIG TOOL]^




-- v[CONFIG TOOL]v
local cMaker = MaticzplChipmaker

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

function MaticzplChipmaker.ConfigTool.DrawPartConfig(part,overwriteDirection)  
    local type = sim.partProperty(part,'type')
    local x, y = sim.partPosition(part)
    
    if type == elem.DEFAULT_PT_DTEC or type == elem.DEFAULT_PT_TSNS or type == elem.DEFAULT_PT_LSNS then
        local r = sim.partProperty(part,'tmp2')
        
        MaticzplChipmaker.DrawRect(x-r,y-r,x+r,y+r, 0, 255, 0, cMaker.ConfigTool.overlayAlpha);
        cMaker.DrawLine(x,y,x,y,255,255,255,255)
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
                local line = cMaker.SegmentedLine:new(d,cMaker.ConfigTool.overlayAlpha)
                line:addSegment(255,255,255,1    )          
                line:addSegment(255,0,  0,  skip )          
                line:addSegment(0,  255,0,  range)
                line:draw(x,y)          
            end
        end
        cMaker.DrawLine(x,y,x,y,255,255,255,255)
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
                local line = cMaker.SegmentedLine:new(d,cMaker.ConfigTool.overlayAlpha)
                line:addSegment(255,255,255,1    )           
                line:addSegment(0,  255,0,  range)      
                line:addSegment(255,0,  0,  skip )          
                line:addSegment(0,  255,0,  range)
                line:draw(x,y)   
            end
        end
        cMaker.DrawLine(x,y,x,y,255,255,255,255)
        return
    end

    if type == elem.DEFAULT_PT_CONV then
        local from = sim.partProperty(part,'tmp')
        local to = sim.partProperty(part,'ctype')

        local success, colorFrom = pcall(elements.property,from,"Color")
        if success then
            colorFrom = cMaker.getColorForString(colorFrom)  
        else
            colorFrom = ""          
        end

        local success, colorTo = pcall(elements.property,to,"Color")
        if success then
            colorTo = cMaker.getColorForString(colorTo)  
        else
            colorTo = ""          
        end

        local success, nameFrom = pcall(elements.property,from,"Name")
        if not success then
            nameFrom = from
        end

        local success, nameTo = pcall(elements.property,to,"Name")
        if not success then
            nameTo = to
        end

        gfx.drawText(15,345,colorFrom..nameFrom.." -> "..colorTo..nameTo)        
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
        local direction = cMaker.OffsetToDirection(x,y,cx,cy)
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
        local direction = cMaker.OffsetToDirection(x,y,cx,cy)
        local distance = math.abs(math.max(math.max(x - cx,cx - x), math.max(y - cy, cy - y)))
        
        sim.partProperty(part,'tmp',distance)   

        cMaker.ConfigTool.setting1Value = distance
        cMaker.ConfigTool.direction = direction        
        return
    end

    if type == elem.DEFAULT_PT_CONV then
        local type1 = elem.DEFAULT_PT_NONE
        if cMaker.StackEdit.selected ~= -1 then
            type1 = sim.partProperty(cMaker.StackEdit.selected,'type')
        end

        sim.partProperty(part,'tmp',type1)
        cMaker.ConfigTool.setting1Value = type1        
    end
end

function MaticzplChipmaker.ConfigTool.SetSecond(part)
    local cx, cy = sim.adjustCoords(cMaker.CursorPos.x,cMaker.CursorPos.y)

    local type = sim.partProperty(part,'type')
    local px, py = sim.partPosition(part)
    
    if type == elem.DEFAULT_PT_LDTC or type == elem.DEFAULT_PT_CRAY then
        local endPoint = cMaker.GetEndInDirection(cMaker.ConfigTool.direction,px,py,cMaker.ConfigTool.setting1Value)
        local distance = math.abs(math.max(math.max(endPoint.x - cx,cx - endPoint.x), math.max(endPoint.y - cy, cy - endPoint.y)))
        
        sim.partProperty(part,'tmp',distance)
        cMaker.ConfigTool.setting2Value = distance
        return
    end

    if type == elem.DEFAULT_PT_DRAY then
        local endPoint = cMaker.GetEndInDirection(cMaker.ConfigTool.direction,px,py,cMaker.ConfigTool.setting1Value)
        local distance = math.abs(math.max(math.max(endPoint.x - cx,cx - endPoint.x), math.max(endPoint.y - cy, cy - endPoint.y)))
        
        sim.partProperty(part,'tmp2',distance)

        cMaker.ConfigTool.setting2Value = distance
        return
    end
    
    if type == elem.DEFAULT_PT_CONV then
        local type2 = elem.DEFAULT_PT_NONE
        if cMaker.StackEdit.selected ~= -1 then
            type2 = sim.partProperty(cMaker.StackEdit.selected,'type')
        end

        sim.partProperty(part,'ctype',type2)
        cMaker.ConfigTool.setting2Value = type2        
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
                        cMaker.ConfigTool.DrawPartConfig(target,cMaker.OffsetToDirection(x,y,cx,cy))
                    end
                end

                
            end       
        end
    )
end

ConfigToolInit()
-- ^[CONFIG TOOL]^




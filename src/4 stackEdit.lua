local cMaker = MaticzplChipmaker

-- v[STACK EDIT]v
function MaticzplChipmaker.HandleStackEdit(button)
    --tpt.selectedl  left   1
    --tpt.selecteda  middle 2
    --tpt.selectedr  right  3  
    local select = nil
    local part = cMaker.StackEdit.selected

    if part == -1 then
        return true
    end

    if button == 1 then
        select = tpt.selectedl
    else
        if button == 3 then
            select = tpt.selectedr
        else
            select = tpt.selecteda
        end              
    end            

    sim.takeSnapshot()
    
    -- Handle Tools
    if select == "DEFAULT_UI_SAMPLE" then
        local hasName,Name = pcall(elements.property,sim.partProperty(part,'type'),"Name")
        if hasName then
            tpt.selectedl = "DEFAULT_PT_"..Name
            print("Part Sampled")
            return false                
        end
    end

    if select == "DEFAULT_PT_NONE" then
        sim.partKill(part)
        cMaker.StackEdit.stackPos = math.max(cMaker.StackEdit.stackPos - 1,0)
        print("Part Removed")
        return false
    end

    if cMaker.ConfigTool.inConfigMode then
        cMaker.ConfigTool.target = part
        print("Part Configured")
        return false
    end

    --Handle Elements
    if string.sub(select,0,10) == "DEFAULT_PT" then
        if cMaker.replaceMode or tpt.selectedreplace ~= "DEFAULT_PT_NONE" then
            sim.partChangeType(part,elem[select])
            print("Part Replaced")
            return false
        else
            sim.partProperty(part,'ctype',elem[select])
            print("Part Ctype Set")
            return false
        end
    end
end

function MaticzplChipmaker.StackEdit.EnableStackEditMode()
    cMaker.DisableAllModes()
    cMaker.StackEdit.isInStackEditMode = true
end

function MaticzplChipmaker.StackEdit.DisableStackEditMode()    
    cMaker.StackEdit.isInStackEditMode = false                
end

local function StackEditInit()
    event.register(event.keypress, 
        function (key,scan,_repeat,shift,ctrl,alt)
            if key == 100 and shift and not ctrl and not alt and not _repeat then --shift D        
                cMaker.StackEdit.EnableStackEditMode()
                return false
            end
            local editing = cMaker.StackEdit.isInStackEditMode;
            if (key == 1073741899 or (key == 0x40000052 and editing)) and not shift and not ctrl and not alt then    -- PageUp / Up arrow
                cMaker.StackEdit.stackPos = cMaker.StackEdit.stackPos + 1
                return false
            end
            if (key == 1073741902 or (key == 0x40000051 and editing)) and not shift and not ctrl and not alt then    -- PageDown / Down arrow       
                if cMaker.StackEdit.stackPos > 0 then
                    cMaker.StackEdit.stackPos = cMaker.StackEdit.stackPos - 1
                    return false
                end             
            end
            if key == 1073741898 and not shift and not ctrl and not alt and not _repeat then    -- Home        
                cMaker.StackEdit.stackPos = 0
                return false
            end  
            if key == 1073741901 and not shift and not ctrl and not alt and not _repeat then    -- End        
                cMaker.StackEdit.stackPos = math.max(cMaker.currentStackSize - 1,0)
                return false
            end  
            if cMaker.StackEdit.isInStackEditMode then                 
                if key == 1073741903 and not shift and not ctrl and not alt and not _repeat then --Right arrow
                    cMaker.StackEdit.selectedField = cMaker.StackEdit.selectedField + 1
                    if cMaker.propTable[cMaker.StackEdit.selectedField] == nil  then
                        cMaker.StackEdit.selectedField = 0
                    end
                    return false
                end               
                if key == 1073741904 and not shift and not ctrl and not alt and not _repeat then --Left arrow
                    cMaker.StackEdit.selectedField = cMaker.StackEdit.selectedField-1
                    if cMaker.StackEdit.selectedField < 0 then
                        cMaker.StackEdit.selectedField = 0
                    end
                    return false
                end   
                if key == 13 and not shift and not ctrl and not alt and not _repeat then -- Enter                    
                    if cMaker.StackEdit.selectedField > 0 then
                        local field = cMaker.propTable[cMaker.StackEdit.selectedField]
                        sim.takeSnapshot()
                        while true do                            
                            local val = tpt.input("Set Property","Set value for "..field)
                            if string.sub(val,#val) == "C" then
                                val = tonumber(string.sub(val,0,#val-1)) + 273.15
                            end
                            
                            local name = elem["DEFAULT_PT_"..string.upper(val)]
                            if name ~= nil then
                                val = name
                            end

                            local success, val = pcall(sim.partProperty,cMaker.StackEdit.selected,field,val)
                            if success then
                                break
                            else
                                tpt.confirm("Wrong value","This property doesnt accept this value")
                            end
                        end
                    end
                    return false
                end
            end
        end
    )

    event.register(event.mousedown, 
        function (x,y,button)     
            if cMaker.StackEdit.isInStackEditMode then                
                if not cMaker.HandleStackEdit(button) then
                    return false                           
                end 
            end
        end
    )

    event.register(event.tick, 
        function ()                         
            if cMaker.StackEdit.isInStackEditMode then
                cMaker.DrawModeText("Stack Edit Mode (ESC to cancel)")
                cMaker.ConfigTool.DrawPartConfig(cMaker.StackEdit.selected)
            end    
        end
    )
end

StackEditInit()
-- ^[STACK EDIT]^
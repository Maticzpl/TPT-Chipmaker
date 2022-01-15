-- So mark2222's mod has cool tools, why not recreate them in lua?
-- By Maticzpl

-- Keys:
-- Stack tool - SHIFT + S
-- Change position in stack display - PageUp / PageDown
-- Reset position in stack display - Home
-- Open Options - Shift + F1

-- Features:
-- Stack HUD - displays the elements of a stack, shows info like FILT ctype in hexadecimal etc. Types are colored!
-- Stack navigation and editing - allows to look through very large stacks and edit particles in the middle of one
-- Stack Tool - stacks all the particles inside of a specified rectangle into one place AND unstacks already stacked particles

-- Planned Features:
-- Stack edit support for PROP tool
-- Config tool like in mark2222's mod
-- Particle Reorder hotkey
-- More customization in the settings

-- Btw this code is quite a mess rn and will get refactored once I finish the main features


if MaticzplChipmaker then return end

MaticzplChipmaker =
{
    StackTool = {
        isInStackMode = false,
        mouseDown = false,
        realStart = {x = 0, y = 0},
        realEnd = {x = 0, y = 0},
        rectStart = {x = 0, y = 0},
        rectEnd = {x = 0, y = 0},
    },
    StackEdit = {
        stackPos = 0,
        selected = -1,
        mouseCaptured = false,
        mouseReleased = true,
    },
    ConfigTool = {
        inConfigMode = false,
        target = -1,
    },
    CursorPos = {x = 0, y = 0},
    Settings = {
        cursorDisplayBgAlpha = 190,
        unstackHeight = 50,
    },
    replaceMode = false,
}
local cMaker = MaticzplChipmaker


function MaticzplChipmaker.OnKey(key,scan,_repeat,shift,ctrl,alt) -- 99 is c 115 is s
    if key == 115 and shift and not ctrl and not alt and not _repeat then -- SHIFT + S
        cMaker.StackTool.isInStackMode = true

        cMaker.ConfigTool.target = -1
        cMaker.ConfigTool.inConfigMode = false
        return false
    end
    
    if key == 27 then   -- ESCAPE
        if cMaker.StackTool.isInStackMode then
            cMaker.StackTool.mouseDown = false            
            cMaker.StackTool.isInStackMode = false            
            return false
        end
    end

    --Stack pos controls
    if key == 1073741899 and not shift and not ctrl and not alt then    -- PageUp
        --local prevPos = cMaker.StackEdit.stackPos
        cMaker.StackEdit.stackPos = cMaker.StackEdit.stackPos + 1

        -- if cMaker.StackEdit.stackPos ~= 0 and prevPos == 0 and tpt.set_pause() == 0 then
        --     tpt.set_pause(1)
        --     print("Entered stack edit mode, the game is now paused.")
        -- end
        return false
    end
    if key == 1073741902 and not shift and not ctrl and not alt then    -- PageDown        
        if cMaker.StackEdit.stackPos > 0 then
            cMaker.StackEdit.stackPos = cMaker.StackEdit.stackPos - 1
            return false
        end             
    end
    if key == 1073741898 and not shift and not ctrl and not alt and not _repeat then    -- Home        
        cMaker.StackEdit.stackPos = 0
        return false
    end

    if key == 1073741882 and shift and not ctrl and not alt and not _repeat  then -- Shift + F1
        cMaker.openSettings()        
        return false    
    end

    if key == 99 and not shift and not ctrl and not alt and not _repeat  then   -- C
        cMaker.ConfigTool.inConfigMode = true

        cMaker.StackTool.mouseDown = false            
        cMaker.StackTool.isInStackMode = false           
        return false    
    end

    if key == 59 and not ctrl and not _repeat then -- ; semicolon for replacemode
        cMaker.replaceMode = (not cMaker.replaceMode)
    end

    -- You can already do it with CTRL + P
    -- if key == 112 then -- P
    --     tpt.selectedl = "DEFAULT_UI_PROPERTY"

    --     return false
    -- end
end

function MaticzplChipmaker.OnMouseDown(x,y,button)
    if button == 3 then
        cMaker.StackTool.isInStackMode = false

        cMaker.ConfigTool.target = -1
        cMaker.ConfigTool.inConfigMode = false
    end
    
    if cMaker.StackTool.isInStackMode and button == 1 then
        cMaker.StackTool.mouseDown = true
        cMaker.StackTool.realStart = {x=x,y=y}
        x, y = simulation.adjustCoords(x,y)        
        
        cMaker.StackTool.rectStart = {x = x,y = y}
        return false
    else
        if cMaker.StackEdit.selected > 0 and cMaker.StackEdit.mouseReleased then    
            local cancel = not cMaker.HandleStackEdit(button)
            if cancel then
                cMaker.StackEdit.mouseCaptured = true
                cMaker.StackEdit.mouseReleased = false                                
                cMaker.StackEdit.selected = -1    
                return false
            else
                cMaker.StackEdit.mouseCaptured = false
            end
        else
            cMaker.StackEdit.mouseCaptured = false
            cMaker.StackEdit.mouseReleased = true
        end
    end

    if cMaker.StackEdit.mouseCaptured and (not cMaker.StackEdit.mouseReleased) then
        return false
    end
end

function MaticzplChipmaker.OnMouseUp(x,y,button,reason)
    if cMaker.StackEdit.mouseCaptured then
        cMaker.StackEdit.mouseReleased = true
        return false        
    end

    if cMaker.StackTool.isInStackMode and button == 1 then
        cMaker.StackTool.mouseDown = false
        cMaker.StackTool.realEnd = {x=x,y=y}
        x, y = simulation.adjustCoords(x,y)
        
        cMaker.StackTool.rectEnd = {x = x,y = y}
        
        if cMaker.StackTool.rectEnd.x == cMaker.StackTool.rectStart.x and
        cMaker.StackTool.rectEnd.y == cMaker.StackTool.rectStart.y then
            cMaker.StackTool.Unstack()
        else
            cMaker.StackTool.Stack()
        end
        
        cMaker.StackTool.isInStackMode = false        
        return false
    end

    if cMaker.ConfigTool.inConfigMode then        
        cMaker.ConfigTool.target = sim.partID(x,y)
        return false
    end
end

function MaticzplChipmaker.OnMouseMove(x,y,dx,dy)
    cMaker.CursorPos = {x = x, y = y}
end

function MaticzplChipmaker.HandleStackEdit(button)
    --tpt.selectedl  left   1
    --tpt.selecteda  middle 2
    --tpt.selectedr  right  3  
    local select = nil

    if button == 1 then
        select = tpt.selectedl
    else
        if button == 3 then
            select = tpt.selectedr
        else
            select = tpt.selecteda
        end              
    end            
    
    -- Handle Tools
    if select == "DEFAULT_UI_SAMPLE" then
        local hasName,Name = pcall(elements.property,sim.partProperty(cMaker.StackEdit.selected,'type'),"Name")
        if hasName then
            tpt.selectedl = "DEFAULT_PT_"..Name
            print("SAMPLE")
            return false                
        end
    end

    if select == "DEFAULT_PT_NONE" then
        sim.partKill(cMaker.StackEdit.selected)
        cMaker.StackEdit.stackPos = math.max(cMaker.StackEdit.stackPos - 1,0)
        print("REMOVE")
        return false
    end

    if cMaker.ConfigTool.inConfigMode then
        cMaker.ConfigTool.target = cMaker.StackEdit.selected
        print("CONFIG")
        return false
    end

    --Handle Elements
    if string.sub(select,0,10) == "DEFAULT_PT" then
        if cMaker.replaceMode or tpt.selectedreplace ~= "DEFAULT_PT_NONE" then
            sim.partChangeType(cMaker.StackEdit.selected,elem[select])
            print("REPLACe")
            return false
        else
            sim.partProperty(cMaker.StackEdit.selected,'ctype',elem[select])
            print("CTYPE")
            return false
        end
    end
end

function MaticzplChipmaker.openSettings()
    local window = Window:new(-1,-1,300,200)

    local exitButton = Button:new(0, 0, 20, 20, "X")
    exitButton:action(
        function(sender)
            interface.closeWindow(window)
            cMaker.SaveSettings()
        end
    )
    window:addComponent(exitButton)

    -- Title
    local SettingsTitle = Label:new(20,0,260,20,"Maticzpl's Chipmaker Settings")
    window:addComponent(SettingsTitle)


    -- Cursor Display Bg
    local CDBgSliderTitle = Label:new(20,30,200,10,"Stack Display Opacity")
    window:addComponent(CDBgSliderTitle)

    local CDBgSliderLabel = Label:new(240,30,20,10,string.format("%.2f %%",cMaker.Settings.cursorDisplayBgAlpha / 2.56))
    window:addComponent(CDBgSliderLabel)

    local CDBgSlider = Slider:new(20,40,260,15,256)
    CDBgSlider:value(cMaker.Settings.cursorDisplayBgAlpha)
    CDBgSlider:onValueChanged(
        function(sender, value)
            cMaker.Settings.cursorDisplayBgAlpha = value
            CDBgSliderLabel:text(string.format("%.2f %%",value / 2.56))
        end
    )
    window:addComponent(CDBgSlider)


    interface.showWindow(window)
end

function MaticzplChipmaker.SaveSettings()
    local sett = cMaker.Settings    local MANAGER = rawget(_G, "MANAGER")

    MANAGER.savesetting("MaticzplCmaker","CDBgColA",sett.cursorDisplayBgAlpha)
end



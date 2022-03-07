-- So mark2222's mod has cool tools, why not recreate them in lua?
-- By Maticzpl

-- Keys:
-- Stack tool - SHIFT + S
-- Move Tool - M
-- Config Tool - C
-- Stack Edit Mode - SHIFT + D
-- Choose property in stack edit - Left / Right Arrows
-- Set property value in stack edit - Enter
-- Change position in stack display - PageUp / PageDown
-- Go to beggining / end in stack display - Home / End
-- Toggle Zoom Overlay - CTRL + O
-- Open Options - Shift + F1
-- Reorder Particles - Shift + F5

-- Features:
-- Stack HUD - displays the elements of a stack, shows info like FILT ctype in hexadecimal etc. Types are colored!
-- Stack navigation and editing - allows to look through very large stacks and edit particles in the middle of one
-- Stack Tool - stacks all the particles inside of a specified rectangle into one place AND unstacks already stacked particles
-- Config Tool - Easiely set properties of DRAY CRAY CONV LDTC LSNS and other particles
-- Zoom Overlay - See the particle ctypes in the zoom window

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
        isInStackEditMode = false,
        stackPos = 0,
        selected = -1,
        mouseCaptured = false,
        mouseReleased = true,
        selectedField = 0,
    },
    ConfigTool = {
        inConfigMode = false,
        isSetting1 = false,
        isSetting2 = false,
        setting1Value = -1,
        direction = 0,
        setting2Value = -1,
        target = -1,
        mouseHeld = false,
        overlayAlpha = 150,
    },
    MoveTool = {
        isInMoveMode = false,
        rectStart = {x = 0, y = 0},
        rectEnd = {x = 0, y = 0},
        movement = {x = 0,y = 0},
        mouseDown = false,
        isDragging = false,
    },
    ZoomOverlay = {       
        CallbackList = {}
    },
    CursorPos = {x = 0, y = 0},
    Settings = {
        cursorDisplayBgAlpha = 190,
        unstackHeight = 50,
    },
    currentStackSize = 0,
    SegmentedLine = {},
    replaceMode = false,
    propTable = {'ctype','temp','life','tmp','tmp2','pavg0','pavg1'}
}
local cMaker = MaticzplChipmaker


function MaticzplChipmaker.OnKey(key,scan,_repeat,shift,ctrl,alt) -- 99 is c 115 is s    
    if key == 27 then   -- ESCAPE
        if not cMaker.DisableAllModes() then
            return false
        end
    end     

    if key == 1073741882 and shift and not ctrl and not alt and not _repeat  then -- Shift + F1
        cMaker.openSettings()        
        return false    
    end


    if key == 1073741886 and shift and not ctrl and not alt and not _repeat  then -- Shift + F5
        cMaker.ReorderParticles()
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
    if button == 3 then -- RMB
        if not cMaker.DisableAllModes() then
            return false
        end
    end
end

function MaticzplChipmaker.OnMouseMove(x,y,dx,dy)
    cMaker.CursorPos = {x = x, y = y}
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



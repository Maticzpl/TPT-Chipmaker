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
-- Open Options - SHIFT + F1
-- Reorder Particles - SHIFT + F5
-- HUD Spectrum Format - CTRL + U

-- Features:
-- Stack HUD - displays the elements of a stack, shows info like FILT ctype in hexadecimal etc. Types are colored!
-- Stack navigation and editing - allows to look through very large stacks and edit particles in the middle of one
-- Stack Tool - stacks all the particles inside of a specified rectangle into one place AND unstacks already stacked particles
-- Config Tool - Easiely set properties of DRAY CRAY CONV LDTC LSNS and other particles
-- Zoom Overlay - See the particle ctypes in the zoom window
-- Property Labels - Many properties of many elements now are documented when stack edit mode is enabled

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
        propDesc = {}
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
        radiusParts = {elem.DEFAULT_PT_DTEC, elem.DEFAULT_PT_TSNS, elem.DEFAULT_PT_LSNS, elem.DEFAULT_PT_VSNS}
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
    FollowUpdate = {
        currentID = -1
    },
    CursorPos = {x = 0, y = 0},
    Settings = {
        cursorDisplayBgAlpha = 190,
        unstackHeight = 50,
    },
    spectrumFormat = 0,
    currentStackSize = 0,
    SegmentedLine = {},
    replaceMode = false,
    tmp3name = "tmp3",
    tmp4name = "tmp4",
    propTable = {'ctype','temp','life','tmp','tmp2','tmp3','tmp4'}
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

--cMaker.StackEdit.propDesc[type][field]
cMaker.StackEdit.propDesc = {
    CRAY = {
        ctype = "Created particle type",
        temp = "Created particle temp",
        life = "Created particle life",
        tmp = "Number of parts to create",
        tmp2 = "Distance to skip"
    },
    DRAY = {
        ctype = "Element to stop copying at",
        tmp = "Number of pixels to copy",
        tmp2 = "Distance between source and copy"
    },
    ARAY = {
        life = "Created BRAY life",
    },
    WIFI = {
        temp = "WIFI channel",
        tmp = "WIFI channel index (cannot be overwritten)",
    },
    TESC = {
        tmp = "Lightning size",
    },
    BCLN = {
        ctype = "Cloned element",
    },
    CLNE = {
        ctype = "Cloned element",
    },
    PCLN = {
        ctype = "Cloned element",
    },
    CONV = {
        ctype = "Target type",
        tmp = "Affects only particles of this type"
    },
    VOID = {
        ctype = "Affects only particles of this type"
    },
    PRTI = {
        temp = "Portal channel",
        tmp = "Portal channel index (cannot be overwritten)",
    },
    HSWC = {
        tmp = "1 = Deserialize FILT -> temp"
    },
    DLAY = {
        temp = "Delay in frames starting from 0C"
    },
    STOR = {
        ctype = "Stores only particles of this type",
        temp = "Stored particle temp",
        tmp2 = "Stored particle life",
        tmp3 = "Stored particle tmp",
        tmp4 = "Stored particle ctype",
    },
    PVOD = {
        ctype = "Affects only particles of this type",
    },
    PUMP = {
        temp = "Emmited pressure",
        tmp = "1 = Deserialize FILT -> pressure"
    },
    PBCL = {
        ctype = "Cloned element",
    },
    GPMP = {
        temp = "Force of gravity",
    },
    INVS = {
        tmp = "Pressure to open at",
    },
    DTEC = {
        ctype = "Detected type",
        tmp2 = "Detection radius",        
    },
    TSNS = {
        temp = "Temperature detection threshold",
        tmp = "1 = Serialize temp -> FILT\n2 = Detects lower temp than self",
        tmp2 = "Detection radius",        
    },
    PSNS = {
        temp = "Pressure detection threshold",
        tmp = "1 = Serialize pressure -> FILT\n2 = Detects lower pressure",
        tmp2 = "Detection radius",        
    },
    LSNS = {
        temp = "Life detection threshold",
        tmp = "1 = Serialize life -> FILT\n2 = Detects lower life\n3 = Deserialize FILT -> life",
        tmp2 = "Detection radius",        
    },
    LDTC = {
        ctype = "Detected type",
        tmp = "Detection range",
        life = "Pixels to skip before detecting",
        tmp2 = "This property is a flag\nUse bitwise OR to set multiple modes\n1 = Detects everything but its ctype\n2 = Ignore energy particles\n4 = Don't set FILT color\n8 = Keep searching after finding a particle",
    },
    VSNS = {
        temp = "Velocity detection threshold",
        tmp = "1 = Serialize velocity -> FILT\n2 = Detects lower velocity\n3 = Deserialize FILT -> velocity",
        tmp2 = "Detection radius",        
    },
    ACEL = {
        life = "Velocity multiplier / 100 + 1"
    },
    DCEL = {
        life = "Percent velocity decrease"
    },
    FRAY = {
        temp = "Added / decreased velocity. 10C = 1px/frame"
    },
    RPEL = {
        ctype = "Affected particle",
        temp = "Used force. Can be negative"
    },
    PSTN = {
        ctype = "Blocked by element of this type",
        temp = "Extension distance 1px every 10C",
        tmp = "Max ammount of particles it can push",
        tmp2 = "Max extension length",
    },
    FRME = {
        tmp = "0 = Sticky, otherwise not sticky"
    },
    FIRW = {
        tmp = "1 = Ignited",
        life = "Fuse timer",
    },
    FWRK = {
        life = "Fuse timer",
    },    
    LITH = {
        ctype = "Charge",
        tmp = "Hydrogenation factor (impurity)",
        tmp2 = "Carbonation factor (impurity)",
    },
    LAVA = {
        ctype = "Molten element type"
    },
    GEL = {
        tmp = "Ammount of water absorbed"
    },
    VIRS = {
        tmp3 = "Frames until cured",
        tmp4 = "Frames until death",        
    },
    SNOW = {
        ctype = "Element it turns into after melting",
    },
    ICE = {
        ctype = "Element it turns into after melting",
    },
    SPNG = {
        life = "Ammount of water absorbed",
    },
    FILT = {
        ctype = "Spectrum containing 30 bits of data",
        tmp = "Operation 0 = SET, 1 = AND, 2 = OR, 3 = SUB\n4 = RED SHIFT, 5 = BLUE SHIFT, 6 = NONE\n7 = XOR, 8 = NOT, 9 = QRTZ\n10 = VARIABLE RED SHIFT, 11= VARIABLE BLUE SHIFT"
    },
    PHOT = {
        ctype = "Spectrum containing 30 bits of data",
    },
    DEUT = {
        life = "Level of compression",
    },
    SIGN = {
        tmp = "Explosion power",
        life = "Explosion timer",
    },
    VIBR = {
        tmp = "Absorbed power",
        life = "Explosion timer",
    },
    BVBR = {
        tmp = "Absorbed power",
        life = "Explosion timer",
    },

}

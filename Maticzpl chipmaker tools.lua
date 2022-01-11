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
        cMaker.StackEdit.stackPos = cMaker.StackEdit.stackPos + 1
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
            return false                
        end
    end

    if select == "DEFAULT_PT_NONE" then
        sim.partKill(cMaker.StackEdit.selected)
        cMaker.StackEdit.stackPos = math.max(cMaker.StackEdit.stackPos - 1,0)
        return false
    end

    if cMaker.ConfigTool.inConfigMode then
        cMaker.ConfigTool.target = cMaker.StackEdit.selected
    end

    --Handle Elements
    if string.sub(select,0,10) == "DEFAULT_PT" then
        if cMaker.replaceMode or tpt.selectedreplace ~= "DEFAULT_PT_NONE" then
            sim.partChangeType(cMaker.StackEdit.selected,elem[select])
            return false
        else
            sim.partProperty(cMaker.StackEdit.selected,'ctype',elem[select])
            return false
        end
    end

end

function MaticzplChipmaker.GetAllPartsInPos(x,y)
    local result = {}
    for part in sim.parts() do
        local px,py = simulation.partPosition(part)

        px = math.floor(px+0.5) -- Round pos
        py = math.floor(py+0.5)

        if x == px and y == py then
            table.insert(result,part)
        end
    end
    
    return result
end

-- Thanks @krftdnr#1652 for this rect code!
function MaticzplChipmaker.DrawRect(x1, y1, x2, y2, r,g,b,a,adjust)    
    if adjust then
        x1, y1 = sim.adjustCoords(x1,y1)
        x2, y2 = sim.adjustCoords(x2,y2)
    end

    local function isInZoom(x, y)
        local zx, zy, zs = ren.zoomScope()
        return ren.zoomEnabled() and 
        x >= zx and x < zx + zs and
        y >= zy and y < zy + zs        
    end
    
    local function calcOffset(x, y)
        local ex, ey, scale, size = ren.zoomWindow()
        local zx, zy, zs = ren.zoomScope()
        return (x - zx) * scale + ex, (y - zy) * scale + ey
    end    

    local startX = x1
    local finalX = x2
    if x2 < x1 then
        finalX = x1
        startX = x2
    end    
    
    local ex, ey, scale, size = ren.zoomWindow()
    for rx = startX, finalX do
        local nx1, ny1 = calcOffset(rx, y1)
        local nx2, ny2 = calcOffset(rx, y2)
        if isInZoom(rx, y1) then
            gfx.fillRect(nx1, ny1, scale - 1, scale - 1, r,g,b,a)
        end
        if isInZoom(rx, y2) then
            gfx.fillRect(nx2, ny2, scale - 1, scale - 1, r,g,b,a)
        end
    end

    
    local startY = y1
    local finalY = y2
    if y2 < y1 then
        finalY = y1
        startY = y2
    end    

    for ry = startY + 1, finalY - 1 do
        local nx1, ny1 = calcOffset(x1, ry)
        local nx2, ny2 = calcOffset(x2, ry)
        if isInZoom(x1, ry) then
            gfx.fillRect(nx1, ny1, scale - 1, scale - 1, r,g,b,a)
        end
        if isInZoom(x2, ry) then
            gfx.fillRect(nx2, ny2, scale - 1, scale - 1, r,g,b,a)
        end
    end
    
    
    local sizeX = x2 - x1
    local sizeY = y2 - y1
    
    if x1 > x2 then
        sizeX = x1 - x2
        x1 = x2
    end
    
    if y1 > y2 then
        sizeY = y1 - y2
        y1 = y2
    end   
    
    
    gfx.drawRect(x1, y1, sizeX, sizeY, r,g,b,a)
end

function MaticzplChipmaker.DrawLine(x1, y1, x2, y2, r,g,b,a,adjust)
    if adjust then
        x1, y1 = sim.adjustCoords(x1,y1)
        x2, y2 = sim.adjustCoords(x2,y2)
    end

    local function isInZoom(x, y)
        local zx, zy, zs = ren.zoomScope()
        return ren.zoomEnabled() and 
        x >= zx and x < zx + zs and
        y >= zy and y < zy + zs        
    end
    
    local function calcOffset(x, y)
        local ex, ey, scale, size = ren.zoomWindow()
        local zx, zy, zs = ren.zoomScope()
        return (x - zx) * scale + ex, (y - zy) * scale + ey
    end    

    local function interpolate(x,y,xr,yr,progress)
        return ((xr - x) * progress) + x,((yr - y) * progress) + y
    end

    local xDiff = math.max((x1 - x2),(x2 - x1))
    local yDiff = math.max((y1 - y2),(y2 - y1))
    local length = math.sqrt((xDiff*xDiff) + (yDiff*yDiff))

    local ex, ey, scale, size = ren.zoomWindow()
    for step = 0, 1, 1/length do
        local pixelX, pixelY = interpolate(x1,y1,x2,y2,step)
        pixelX = math.floor(pixelX)
        pixelY = math.floor(pixelY)

        local nx ,ny = calcOffset(pixelX,pixelY)

        if isInZoom(pixelX, pixelY) then
            gfx.fillRect(nx,ny,scale - 1, scale - 1,r,g,b,a)
        end
    end

    gfx.drawLine(x1,y1,x2,y2,r,g,b,a)

end


function MaticzplChipmaker.StackTool.Stack()
    local s = cMaker.StackTool
    
    local partsMoved = 0
    
    -- REORDER PARTICLES HERE
    
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

function MaticzplChipmaker.alignToRight(text)
    local maxWidth = 0
    local outStr = ""
    

    for str in string.gmatch(text, "([^\n]+)") do   -- find widest line
        local width,height = graphics.textSize(str)
        
        if width > maxWidth then
            maxWidth = width
        end
    end
    
    local spaceWidth, spaceHeight = graphics.textSize(" ")

    for str in string.gmatch(text, "([^\n]+)") do
        local width,height = graphics.textSize(str)
        
        local line = str
        
        if width < maxWidth then
            for i = 1, math.floor((maxWidth - width) / spaceWidth), 1 do
                line = " "..line
            end
        end
        
        outStr = outStr .. line .."\n"
    end
    
    return outStr
end

function MaticzplChipmaker.getColorForString(color)
    local hex = string.format("%x", color)
    --12345678
    --aarrggbb
    --ff2030d0

    local r = tonumber(string.sub(hex,3,4),16)
    local g = tonumber(string.sub(hex,5,6),16)
    local b = tonumber(string.sub(hex,7,8),16)
    
    while #hex < 8 do -- If leading it had leading zeroes add them back in
        hex = "0"..hex
        r = tonumber(string.sub(hex,3,4),16)
        g = tonumber(string.sub(hex,5,6),16)
        b = tonumber(string.sub(hex,7,8),16)
    end    
    
    if r == 0 or r == nil then
        r = 1
    end
    if g == 0 or g == nil then
        g = 1
    end
    if b == 0 or b == nil then
        b = 1
    end
    
    if string.char(r) == "\n" then
        r = r - 1
    end
    if string.char(g) == "\n" then
        g = g - 1
    end
    if string.char(b) == "\n" then
        b = b - 1
    end

    -- Avoid UTF-8 encoding those into 1 char
    if r >= 0xC2 and r <= 0xDF and g < 0xC0 then --For RG bytes
        local newR
        local rChange
        if r >= 0xD0 then
            newR = 0xE0
            rChange = 0xE0 - r
        else
            newR = 0xC1
            rChange = r  - 0xC1
        end
        local newG = 0xC0
        local gChange = 0xC0 - g

        if gChange > rChange then
            g = newG
        else
            r = newR
        end
    end
    if g >= 0xC2 and g <= 0xDF and b < 0xC0 then --For GB bytes
        local newG
        local gChange
        if g >= 0xD0 then
            newG = 0xE0
            gChange = 0xE0 - g
        else
            newG = 0xC1
            gChange = g  - 0xC1
        end
        local newB = 0xC0
        local bChange = 0xC0 - b

        if bChange > gChange then
            b = newB
        else
            g = newG
        end
    end

    if r + g + b < 100 then --If too dark bright it up
        local adjustement = (180 - math.max(r,g,b)) / 3
        r = r + adjustement
        g = g + adjustement
        b = b + adjustement
    end
    return "\x0F"..string.char(r,g,b)

end

function MaticzplChipmaker.DrawCursorDisplay()
    local x,y = simulation.adjustCoords(cMaker.CursorPos.x,cMaker.CursorPos.y)
    
    local partsOnCursor = cMaker.GetAllPartsInPos(x,y)

    if #partsOnCursor < 1 then
        return
    end
    
    local partsString = ""
    local skipped = 0
    local hasSpecialDisplay = false

    local offset = math.max(cMaker.StackEdit.stackPos - 2,0)
    -- Assemble the string and inspect the stack
    for i = #partsOnCursor -  offset, 1, -1 do     
        local part = partsOnCursor[i]

        if #partsOnCursor - i - offset > 5 then
            skipped = skipped + 1
        else            
            local type = elements.property(sim.partProperty(part,"type"),"Name")
            local ctype = sim.partProperty(part,"ctype")
            local temp = sim.partProperty(part,"temp")
            local life = sim.partProperty(part,"life")
            local tmp = sim.partProperty(part,"tmp")
            local tmp2 = sim.partProperty(part,"tmp2")
                        
            local strCtype = cMaker.handleCtype(ctype,type,tmp)
            local overwriteType = strCtype.mode ~= nil
           

            local strTemp = math.floor((temp - 273.145) * 100)/100

            local color = cMaker.getColorForString(elements.property(sim.partProperty(part,"type"),"Color"))

            local tmpDisplay = cMaker.handleTmp(tmp,type)

            -- Format the next element
            if overwriteType  then
                strCtype = strCtype.val
                color = ""
                type = ""
            end
            partsString = partsString 
            ..color      ..  type   .. "\bg"
            ..strCtype
            ..", "       .. strTemp .. "C"
            ..", Life: " .. life
            ..", Tmp: "  .. tmpDisplay


            if tmp2 ~= 0 then
                partsString = partsString .. ", Tmp2: " .. tmp2
            end

            if #partsOnCursor > 1 then
                partsString = partsString .. ", #" .. part
            end

            if (#partsOnCursor - cMaker.StackEdit.stackPos) == i then
                partsString = partsString .. " \x0F\xFF\x01\x01<\bg"    
                if #partsOnCursor > 1 then                    
                    cMaker.StackEdit.selected = part     
                end       
            end


            partsString = partsString .. "\n"

            -- Check if this particle has properties with custom displats
            if type == "FILT" or type == "BRAY" or type == "PHOT" or type == "CONV" then
                hasSpecialDisplay = true
            end

        end        
    end    
    if skipped > 0 then
        partsString = partsString .. "And "..skipped.." more "
    end
    if cMaker.StackEdit.stackPos ~= 0 then         
        partsString = partsString .. "\bt[Stack Pos: "..cMaker.StackEdit.stackPos.."]\bg\n"
    else 
        if skipped > 0 then
            partsString = partsString .. "\n" --Add new line for "And x more"
        end 
    end
    
    --Hide hud in debug mode unless something is interesting
    if renderer.debugHUD() == 0 and not hasSpecialDisplay and #partsOnCursor < 2 then
        return
    end    


    -- Set text position
    local width,height = graphics.textSize(partsString)
    local noDebugOffset = 14
    local textPos = {
        x=(597 - width),
        y=44
    }      

    if tpt.version.modid == 6 then  -- Cracker's mod
        textPos = {
            x = 9,
            y=50
        }

    elseif tpt.version.jacob1s_mod ~= nil then  --Jacob1's mod
        if ren.zoomEnabled() then
            local zx,zy,s = ren.zoomScope()

            if zx + (s / 2) > 305 then       -- if zoom window on the left side
                textPos = {
                    x = 16,
                    y=288
                }    
            else
                textPos = {
                    x = (597 - width),
                    y = 288
                }
                partsString = cMaker.alignToRight(partsString)
            end
            noDebugOffset = 11
        else            
            partsString = cMaker.alignToRight(partsString)
        end
    else -- Vanilla and others
        partsString = cMaker.alignToRight(partsString)
    end
    

    if renderer.debugHUD() == 0 then
        textPos.y = textPos.y - noDebugOffset
    end

    -- Draw text
    local padding = 3
    graphics.fillRect(textPos.x - padding,textPos.y - padding,width+(padding*2),(height - 13)+(padding*2),0,0,0,cMaker.Settings.cursorDisplayBgAlpha) 
    graphics.drawText(textPos.x,textPos.y,partsString,255, 255, 255,180)
end

function MaticzplChipmaker.tmpToFiltMode(tmp)
    local modes = {"SET","AND","OR","SUB","RSHFT","BSHFT","NONE","NOT","QRTZ","VRSHFT","VBSHFT"}    local mode = modes[math.floor(tmp + 1)]
    if mode == nil then
        return "NONE"
    end
    return mode
end

function MaticzplChipmaker.handleCtype(ctype,type,tmp)
    if type == "BRAY" or type == "PHOT" or type == "BIZR" or type == "BIZS" or type == "BIZG" then
        return "(0x"..string.upper(string.format("%x", ctype)) ..")"
    end
    
    local isCtypeNamed,ctypeName = pcall(elements.property,ctype,"Name")


    if type == "LAVA" and ctypeName ~= "NONE" then
        if isCtypeNamed then            
            local color = cMaker.getColorForString(elements.property(ctype,"Color"))

            local out = "Molten "..color..ctypeName.."\bg"
            return {mode = "overwrite",val = out}
        end
    end

    if type == "PIPE" then
        if isCtypeNamed and ctypeName ~= "NONE" then            
            local color = cMaker.getColorForString(elements.property(ctype,"Color"))
            
            local out = "PIPE with "..color..ctypeName.."\bg"
            return {mode = "overwrite",val = out}
        end
    end

    if type == "LIFE" then      
        local color = ""
        local golType = ""

        --check custom gol
        for k,v in pairs(sim.listCustomGol()) do
            if v.rule == ctype then
                golType = v.name
                color = cMaker.getColorForString(v.color1)
            end
        end

        if color ~= "" and golType ~= "" then
            local out = color..golType.."\bg"
            return {mode = "overwrite",val = out}            
        end
    end

    if type == "FILT" then
        local mode = cMaker.tmpToFiltMode(tmp)
        return "("..mode..", 0x"..string.upper(string.format("%x", ctype)) ..")"
    end
    
    if ctype == 0 then
        return ""
    end
    

    if ctype >= 125 + 512 and type == "CRAY" then --CRAY FILT WITH TMP
        if (ctype - 125) % 512 == 0 then --Is it actually filt?
            local mode = cMaker.tmpToFiltMode((ctype - 125) / 512)
            
            local color = cMaker.getColorForString(elements.property(elem.DEFAULT_PT_FILT,"Color"))
            
            return "("..color.."FILT\bg("..mode.."))"      
        end
    end

    
    if isCtypeNamed then
        local color = cMaker.getColorForString(elements.property(ctype,"Color"))
        return "("..color..ctypeName.."\bg)"        
    end
    
    return "("..ctype..")"
    
end

function MaticzplChipmaker.handleTmp(tmp,type)
    local success,name = pcall(elements.property,ctype,"Name")
    if type == "CONV" then
        if success then
            local color = cMaker.getColorForString(elements.property(tmp,"Color"))
            
            return color..name.."\bg"       
        end    
    end          
    
    return tmp    
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
        cMaker.handleConfigTool()
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

function MaticzplChipmaker.SaveSettings()
    local sett = cMaker.Settings    local MANAGER = rawget(_G, "MANAGER")

    MANAGER.savesetting("MaticzplCmaker","CDBgColA",sett.cursorDisplayBgAlpha)
end

cMaker.Init()

--TODO: 
--  Config tool
--  Particle reorder function
--  Call the particle reorder function when using stack tool

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
-- Thanks LBPhacker for fixing this :P
function MaticzplChipmaker.getColorForString(color)
    local function handle_nono_zone(chr)
        local byte = chr:byte()
        if byte < 0x80 then
            return chr
        end
        return string.char(bit.bor(0xC0, bit.rshift(byte, 6)), bit.bor(0x80, bit.band(byte, 0x3F)))
    end

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
    
    if r == 0 or string.char(r) == '\n' then
        r = r + 1
    end
    if g == 0 or string.char(g) == '\n' then
        g = g + 1
    end
    if b == 0 or string.char(b) == '\n' then
        b = b + 1
    end
    
    if r + g + b < 100 then --If too dark bright it up
        local adjustement = (180 - math.max(r,g,b)) / 3
        r = r + adjustement
        g = g + adjustement
        b = b + adjustement
    end
    r = string.char(r)
    g = string.char(g)
    b = string.char(b)
    if tpt.version.jacob1s_mod == nil then
        r = handle_nono_zone(r)
        g = handle_nono_zone(g)
        b = handle_nono_zone(b)        
    end
    return "\x0F"..r..g..b

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
    length = length * 4 -- for accuracy

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

-- Thanks to mad-cow for this function!
function MaticzplChipmaker.GetAllPartsInRegion(x1, y1, x2, y2)
    -- builts a map of particles in a region.
    -- WARN: Misbehaves if partile order hasn't been reloaded since it relies on sim.parts()
    -- Save the returned value and provide it to .GetAllPartsInPos(x,y,region) to reduce computational complexity
    -- or you can just index the returned value youself, idc
    local result = {}
    local width = sim.XRES
    if x2 < x1 then
        x1,x2 = x2,x1
    end
    if y2 < y1 then
        y1,y2 = y2,y1
    end
    for part in sim.parts() do
        local px, py = sim.partPosition(part)
        
        px = math.floor(px+0.5) -- Round pos
        py = math.floor(py+0.5)
        local idx = math.floor(px + (py * width))
        
        if px >= x1 and px <= x2 and py >= y1 and py <= y2 then
            if not result[idx] then
                result[idx] = {}
            end
            table.insert(result[idx], part)
        end
    end
    return result
end

function MaticzplChipmaker.DrawModeText(text)
    graphics.fillRect(0,0,sim.XRES,sim.YRES,0,0,0,128)
    graphics.drawText(15,360,text,252, 232, 3)
end

function MaticzplChipmaker.DisableAllModes()
    if cMaker.StackTool.isInStackMode then       
        cMaker.StackTool.DisableStackMode(); 
        return false
    end
    if cMaker.ConfigTool.inConfigMode then      
        cMaker.ConfigTool.DisableConfigMode();
        return false
    end
    if cMaker.StackEdit.isInStackEditMode then      
        cMaker.StackEdit.DisableStackEditMode();
        return false
    end
    if cMaker.MoveTool.isInMoveMode then
        cMaker.MoveTool.DisableMoveMode();
        return false
    end
    return true
end

function MaticzplChipmaker.ReorderParticles()
    print("Particle Order Reloaded")
    
    local particles = {}
    local width = sim.XRES
    for part in sim.parts() do
        local x = math.floor(sim.partProperty(part,'x')+0.5);
        local y = math.floor(sim.partProperty(part,'y')+0.5);

        local particleData = {}
        particleData.type =     sim.partProperty(part,'type');
        particleData.temp =     sim.partProperty(part,'temp');
        particleData.ctype =    sim.partProperty(part,'ctype');
        particleData.tmp =      sim.partProperty(part,'tmp');
        particleData.tmp2 =     sim.partProperty(part,'tmp2');
        particleData.tmp3 =     sim.partProperty(part,cMaker.tmp3name);
        particleData.tmp4 =     sim.partProperty(part,cMaker.tmp4name);
        particleData.life =     sim.partProperty(part,'life');
        particleData.vx =       sim.partProperty(part,'vx');
        particleData.vy =       sim.partProperty(part,'vy');
        particleData.dcolour =  sim.partProperty(part,'dcolour');
        particleData.flags =    sim.partProperty(part,'flags');

        local index = math.floor(x + (y * width))
        if particles[index] == nil then
            particles[index] = {}            
        end
        table.insert(particles[index],particleData)
        --particles[index][#particles[index]] = particleData  
        sim.partKill(part)     
    end
    
    for i = sim.XRES * sim.YRES, 0, -1 do
        local stack = particles[i]
        if stack ~= nil then
            for j = #stack, 1, -1 do
                local part = stack[j]
                local x = math.floor(i % sim.XRES)
                local y = math.floor((i - x) / sim.XRES)

                local id = sim.partCreate(-3,x,y,part.type)

                sim.partProperty(id,'type',part.type); -- Jacob1's mod had troubles with this :P
                sim.partProperty(id,'temp',part.temp);
                sim.partProperty(id,'ctype',part.ctype);
                sim.partProperty(id,'tmp',part.tmp);
                sim.partProperty(id,'tmp2',part.tmp2);
                sim.partProperty(id,cMaker.tmp3name,part.tmp3);
                sim.partProperty(id,cMaker.tmp4name,part.tmp4);
                sim.partProperty(id,'life',part.life);
                sim.partProperty(id,'vx',part.vx);
                sim.partProperty(id,'vy',part.vy);
                sim.partProperty(id,'dcolour',part.dcolour)
                sim.partProperty(id,'flags',part.flags);
            end            
        end
    end

end

function MaticzplChipmaker.GetEndInDirection(direction,centerx,centery,distance)
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

    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)

    return {x = x, y = y}
end

function MaticzplChipmaker.OffsetToDirection(x,y,cx,cy)
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

function MaticzplChipmaker.SegmentedLine:new(direction,alpha)
    local o = {}
    o.segments = {}
    o.direction = direction
    o.alpha = alpha
    setmetatable(o, self)
    self.__index = self
    return o
end

function MaticzplChipmaker.SegmentedLine:addSegment(r,g,b,length)
    length = (length or 1) - 1
    table.insert(self.segments,{r=r,g=g,b=b,length=length})
end

function MaticzplChipmaker.SegmentedLine:draw(x,y)
    for key, segment in pairs(self.segments) do
        local r,g,b = segment.r,segment.g,segment.b
        local length = segment.length
        local lineEnd = cMaker.GetEndInDirection(self.direction,x,y,length)

        if length >= 0 then
            cMaker.DrawLine(x+0.5,y+0.5,lineEnd.x+0.5,lineEnd.y+0.5,r,g,b,self.alpha)            
        end

        local nextLineStart = cMaker.GetEndInDirection(self.direction,lineEnd.x,lineEnd.y,1)
        x = nextLineStart.x
        y = nextLineStart.y
    end
end

function table:includes(element)
    for i, elem in ipairs(self) do
        if elem == element then
            return true
        end
    end
    return false
end

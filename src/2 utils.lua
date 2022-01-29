-- Thanks LBPhacker for fixing this :P
function MaticzplChipmaker.getColorForString(color)
    local function handle_nono_zone(chr)
        chr = string.char(chr)

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
    r = handle_nono_zone(r)
    g = handle_nono_zone(g)
    b = handle_nono_zone(b)
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
        local x = math.floor(sim.partProperty(part,'x'));
        local y = math.floor(sim.partProperty(part,'y'));

        local particleData = {}
        particleData.type =     sim.partProperty(part,'type');
        particleData.temp =     sim.partProperty(part,'temp');
        particleData.ctype =    sim.partProperty(part,'ctype');
        particleData.tmp =      sim.partProperty(part,'tmp');
        particleData.tmp2 =     sim.partProperty(part,'tmp2');
        particleData.tmp3 =     sim.partProperty(part,'pavg0');
        particleData.tmp4 =     sim.partProperty(part,'pavg1');
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
            for k,part in pairs(stack) do
                local x = math.floor(i % sim.XRES)
                local y = math.floor((i - x) / sim.XRES)

                local id = sim.partCreate(-3,x,y,28)

                sim.partProperty(id,'type',part.type);
                sim.partProperty(id,'temp',part.temp);
                sim.partProperty(id,'ctype',part.ctype);
                sim.partProperty(id,'tmp',part.tmp);
                sim.partProperty(id,'tmp2',part.tmp2);
                sim.partProperty(id,'pavg0',part.tmp3);
                sim.partProperty(id,'pavg1',part.tmp4);
                sim.partProperty(id,'life',part.life);
                sim.partProperty(id,'vx',part.vx);
                sim.partProperty(id,'vy',part.vy);
                sim.partProperty(id,'dcolour',part.dcolour)
                sim.partProperty(id,'flags',part.flags);
            end            
        end
    end

end
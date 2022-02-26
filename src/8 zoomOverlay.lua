-- v[Zoom Overlay]v

local cMaker = MaticzplChipmaker

-- ID, X, Y, ZoomX, ZoomY, ZoomScale
function MaticzplChipmaker.RegisterZoomOverlayCallback(func)
    table.insert(cMaker.ZoomOverlay.CallbackList,func)
end

function MaticzplChipmaker.DrawZoomOverlay()
    if not ren.zoomEnabled() then
        return
    end

    -- Excluding RB
    -- [<LEFT RIGHT) <TOP BOTTOM) ]
    local x,y,size = ren.zoomScope()
    local zx,zy,zfactor,zsize = ren.zoomWindow()

    for i = x, x+size - 1, 1 do        
        for j = y, y+size - 1, 1 do
            local partId = sim.partID(i,j)
            if partId ~= nil then                    
                local inZoomX = ((i - x) * zfactor) +zx
                local inZoomY = ((j - y) * zfactor) +zy
                
                for k, func in pairs(cMaker.ZoomOverlay.CallbackList) do
                    func(partId,i,j,inZoomX,inZoomY,zfactor)
                end
            end
        end
    end
end

-- Ctype overlay
cMaker.RegisterZoomOverlayCallback(function (id, x, y, zx, zy, zs)
    local type = sim.partProperty(id,'type')
    local ctype = sim.partProperty(id,'ctype')
    local tmp = sim.partProperty(id,'tmp')

    local typeBlacklist = {elem.DEFAULT_PT_BRAY,elem.DEFAULT_PT_WWLD,elem.DEFAULT_PT_FILT,elem.DEFAULT_PT_PHOT,elem.DEFAULT_PT_BIZR,elem.DEFAULT_PT_BIZG,elem.DEFAULT_PT_BIZS,elem.DEFAULT_PT_LITH}
    
    local includes = false
    for i, bltype in ipairs(typeBlacklist) do
        if bltype == type then
            includes = true
        end
    end

    if includes then
        return
    end
    

    local success, ctypeColor = pcall(elem.property,ctype,"Color")
    if success and ctype ~= 0 then
        local hex = string.format("%x", ctypeColor)

        local r = tonumber(string.sub(hex,3,4),16)
        local g = tonumber(string.sub(hex,5,6),16)
        local b = tonumber(string.sub(hex,7,8),16)
        
        while #hex < 8 do -- If leading it had leading zeroes add them back in
            hex = "0"..hex
            r = tonumber(string.sub(hex,3,4),16)
            g = tonumber(string.sub(hex,5,6),16)
            b = tonumber(string.sub(hex,7,8),16)
        end
        local inset = zs * 0.3

        if type == elem.DEFAULT_PT_CONV and tmp ~= 0 then
            gfx.fillRect(zx+inset,zy+inset,(zs-inset*2) / 2,zs-inset*2,r,g,b)
        else
            gfx.fillRect(zx+inset,zy+inset,zs-inset*2,zs-inset*2,r,g,b)
        end

    end
    
    local success, tmpColor = pcall(elem.property,tmp,"Color")
    if type == elem.DEFAULT_PT_CONV and success and tmp ~= 0 then
        local hex = string.format("%x", tmpColor)

        local r = tonumber(string.sub(hex,3,4),16)
        local g = tonumber(string.sub(hex,5,6),16)
        local b = tonumber(string.sub(hex,7,8),16)
        
        while #hex < 8 do
            hex = "0"..hex
            r = tonumber(string.sub(hex,3,4),16)
            g = tonumber(string.sub(hex,5,6),16)
            b = tonumber(string.sub(hex,7,8),16)
        end

        local inset = zs * 0.3
        local sideOffset = (zs-inset*2) / 2
        gfx.fillRect(zx+inset+math.floor(sideOffset),zy+inset,sideOffset,zs-inset*2,r,g,b)
    end
end)


event.register(event.keypress,function (key,scan,_repeat,shift,ctrl,alt)
    if key == 111 and ctrl and not alt and not shift then --CTRL + O
        if cMaker.ZoomOverlay.tickEvent == nil then
            cMaker.ZoomOverlay.tickEvent = event.register(event.tick,cMaker.DrawZoomOverlay)        
        else
            event.unregister(event.tick,cMaker.ZoomOverlay.tickEvent)
            cMaker.ZoomOverlay.tickEvent = nil
        end
    end    
end)

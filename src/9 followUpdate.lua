local cMaker = MaticzplChipmaker

function MaticzplChipmaker.FollowUpdate.TryFollow()
    if cMaker.FollowUpdate.currentID ~= -1 and ren.zoomEnabled() then
        local x, y, size = ren.zoomScope()
        local x, y = sim.partPosition(cMaker.FollowUpdate.currentID)
        
        if x + size / 2 > sim.XRES then
            x = math.floor(sim.XRES - size / 2)
        end
        if y + size / 2 > sim.YRES then
            y = math.floor(sim.YRES - size / 2)
        end
        if x - size / 2 < 0 then
            x = math.ceil(size / 2)
        end
        if y - size / 2 < 0 then
            y = math.ceil(size / 2)
        end

        ren.zoomScope(x - size / 2, y - size / 2, size)
        local wx, wy, zoomFactor, wsize = ren.zoomWindow()
        if x > 305 then
            ren.zoomWindow(0,0,zoomFactor)
        else
            ren.zoomWindow(sim.XRES - wsize,0,zoomFactor)
        end
        local stack = cMaker.GetAllPartsInPos(x,y)
        for z, part in ipairs(stack) do
            if part == cMaker.FollowUpdate.currentID then
                cMaker.StackEdit.stackPos = #stack - z
            end
        end
    end
end

function MaticzplChipmaker.FollowUpdate.FindNextPart(id)
    if sim.partPosition(id + 1) then
        return id + 1
    else
        local closest = 10000000
        for p in sim.parts() do
            if p - id > 0 and p - id < closest - id then
                closest = p
            end
        end
        if closest == 10000000 then
            return -1
        else
            return closest
        end
    end
end

event.register(event.keypress,function (key,scan,rep,shift,ctrl,alt)
    -- space or f
    if key == 32 and not rep or key == 102 and not shift and not alt and not rep then
        cMaker.FollowUpdate.currentID = -1
    end
    -- alt f
    if key == 102 and alt and not rep then
        if cMaker.FollowUpdate.currentID == -1 then
            cMaker.ReorderParticles();
        end

        cMaker.FollowUpdate.currentID = cMaker.FollowUpdate.FindNextPart(cMaker.FollowUpdate.currentID)

        MaticzplChipmaker.FollowUpdate.TryFollow()
    end
    -- shift f
    if key == 102 and shift and not alt and not rep then
        if cMaker.FollowUpdate.currentID == -1 then
            cMaker.ReorderParticles();
        end

        local x, y = sim.adjustCoords(cMaker.CursorPos.x, cMaker.CursorPos.y)
        local newID = sim.partID(x,y) or -1
        if newID < cMaker.FollowUpdate.currentID then
            cMaker.FollowUpdate.currentID = -1
        else
            cMaker.FollowUpdate.currentID = newID
        end    
        MaticzplChipmaker.FollowUpdate.TryFollow()
    end
end)

event.register(event.tick,function ()
    if cMaker.FollowUpdate.currentID ~= -1 and ren.zoomEnabled() then
        local x, y = sim.partPosition(cMaker.FollowUpdate.currentID)
        
        cMaker.DrawRect(x,y,x,y,255,255,255,100)
    end    
end)
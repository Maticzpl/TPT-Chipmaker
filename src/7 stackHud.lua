-- v[STACK HUD]v
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
            local tmp4 = sim.partProperty(part,"pavg1")
                        
            local strCtype = cMaker.handleCtype(ctype,type,tmp,tmp4)
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
    local modes = {"SET","AND","OR","SUB","RSHFT","BSHFT","NONE","NOT","QRTZ","VRSHFT","VBSHFT"}    
    local mode = modes[math.floor(tmp + 1)]
    if mode == nil then
        return "UNKNOWN"
    end
    return mode
end

function MaticzplChipmaker.ctypeToGol() --TODO: Implement this
    local color = nil
    local name = nil

    local nameTable =  {"HLIF",}
    local colorTable = {}

    return name, color
end

function MaticzplChipmaker.handleCtype(ctype,type,tmp,tmp4)
    local isCtypeNamed,ctypeName = pcall(elements.property,ctype,"Name")
    local typeId = elements["DEFAULT_PT_"..type]

    if type == "PHOT" or type == "BIZR" or type == "BIZS" or type == "BIZG" or type == "BRAY" or type == "C-5" then
        return "(0x"..string.upper(string.format("%x", ctype)) ..")"
    end   

    if type == "PIPE" or type == "PPIP" then
        if isCtypeNamed and ctypeName ~= "NONE" then            
            local color = cMaker.getColorForString(elements.property(ctype,"Color"))
            
            local out = "PIPE with "..color..ctypeName.."\bg"

            if ctypeName == "LAVA" then
                color = cMaker.getColorForString(elements.property(tmp4,"Color"))
                local isTmp4Named,tmp4Name = pcall(elements.property,tmp4,"Name")
                if isTmp4Named then                    
                    out = "PIPE with molten "..color..tmp4Name.."\bg"
                end
            end

            return {mode = "overwrite",val = out}
        end
    end

    if type == "LAVA" and ctypeName ~= "NONE" then
        if isCtypeNamed then            
            local color = cMaker.getColorForString(elements.property(ctype,"Color"))

            local out = "Molten "..color..ctypeName.."\bg"
            return {mode = "overwrite",val = out}
        end
    end

    if type == "LIFE" then  
        local golType, color = cMaker.ctypeToGol(ctype)


        --check custom gol
        if golType == nil then            
            for k,v in pairs(sim.listCustomGol()) do
                if v.rule == ctype then
                    golType = v.name
                    color = cMaker.getColorForString(v.color1)
                end
            end
        end

        if color ~= nil and golType ~= nil then
            local out = color..golType.."\bg"
            return {mode = "overwrite",val = out}            
        end
    end

    if type == "FILT" then
        local mode = cMaker.tmpToFiltMode(tmp)
        return "("..mode..", 0x"..string.upper(string.format("%x", ctype)) ..")"
    end
    
    if type == "CLNE" or  type == "BCLN" or type == "PCLN" or type == "PBCN" then
        if ctypeName == "LAVA" then            
            local color = cMaker.getColorForString(elements.property(tmp,"Color"))
            local tmpName = elements.property(tmp,"Name")
            
            local typeColor = cMaker.getColorForString(elements.property(typeId,"Color"))

            local out = typeColor..type.."\bg(Molten "..color..tmpName.."\bg)"
            return {mode = "overwrite",val = out}
        end
    end

    if ctype >= 125 + 512 and type == "CRAY" then --CRAY FILT WITH TMP
        if (ctype - 125) % 512 == 0 then --Is it actually filt?
            local mode = cMaker.tmpToFiltMode((ctype - 125) / 512)
            
            local color = cMaker.getColorForString(elements.property(elem.DEFAULT_PT_FILT,"Color"))
            
            return "("..color.."FILT\bg("..mode.."))"      
        end
    end

    if ctype == 0 then
        return ""
    end

    if type == "LITH" or type == "GLOW" or type == "WWLD" then
        return "("..ctype..")"        
    end
    
    if isCtypeNamed then
        local color = cMaker.getColorForString(elements.property(ctype,"Color"))
        return "("..color..ctypeName.."\bg)"        
    end
    
    return "("..ctype..")"
    
end

function MaticzplChipmaker.handleTmp(tmp,type)
    local success,name = pcall(elements.property,tmp,"Name")
    if type == "CONV" then
        if success then
            local color = cMaker.getColorForString(elements.property(tmp,"Color"))
            
            return color..name.."\bg"       
        end    
    end          
    
    return tmp    
end
-- ^[STACK HUD]^

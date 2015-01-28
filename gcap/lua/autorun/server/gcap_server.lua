hook.Add("PlayerSay", "CAP.PlayerCommand", function(ply, text, public)
	local text = string.Explode(" ", text)
	local target = nil
	if string.lower(text[1]) == string.lower(CAP.command) then
		if CAP.allowance[ply:GetUserGroup()] then
			if text[2] then
				for k,v in pairs(player.GetAll()) do
					if (string.find(string.lower(v:Nick()), string.lower(tostring(text[2])))) or (v:SteamID() == text[2]) then
						target = v
					end
				end
				if target then
					if text[3] then
						CaptureLeScreen(ply, target, tonumber(text[3]))
                        net.Start("gcapNotify")
                        net.WriteTable({"Capturing the screen of ", Color(125, 200, 125), target:Name(), color_white, "!"})
                        net.Send(ply)

                        net.Start("gcapNotify")
                        net.WriteTable({Color(125, 200, 125), "Status: ", color_white, "Fetching capture from ", Color(125,200,125), target:Name(), color_white, "."})
                        net.Send(ply)
                    else
						CaptureLeScreen(ply, target, tostring(CAP.defaultquality))
                        net.Start("gcapNotify")
                        net.WriteTable({"Capturing the screen of ", Color(125, 200, 125), target:Name(), color_white, "!"})
                        net.Send(ply)

                        net.Start("gcapNotify")
                        net.WriteTable({Color(125, 200, 125), "Status: ", color_white, "Fetching capture from ", Color(125,200,125), target:Name(), color_white, "."})
                        net.Send(ply)
					end
				else
                    net.Start("gcapNotify")
                    net.WriteTable({"Could not find the player ", Color(125, 200, 125), text[2], color_white, "!"})
                    net.Send(ply)
				end
			else
                net.Start("gcapNotify")
                net.WriteTable({"Please specify ", Color(125, 200, 125), "who ", color_white, "you would like to take a capture of."})
                net.Send(ply)
			end
		else
            net.Start("gcapNotify")
            net.WriteTable({"You do not have the privileges to use ", Color(125, 200, 125), "gcap", color_white, "!"})
            net.Send(ply)
		end
		return false
	end
end)

if SERVER then
    function CAP.GetSaveFormat(victim, caller)
        if not IsValid(victim) and IsValid(caller) then return end
        local tags = {
            [":victim:"] = victim:Name(),
            [":victimid:"] = victim:SteamID(),
            [":captrer:"] = caller:Name(),
            [":capturerid:"] = caller:SteamID(),
            [":time:"] = os.date("%m-%d-%y") .. " " .. os.date("%H:%M:%S"),
            [":timeh:"] = os.date("%H:%M:%S"),
            [":timed:"] = os.date("%m-%d-%y"),
        }

        local formatstr = CAP.saveformat

        for k,v in pairs(tags) do
            formatstr = formatstr:gsub(k, v)
        end

        return formatstr
    end
end

local MAX_CHUNK_SIZE = 16384
local CHUNK_RATE = 1 / 4 -- 4 chunk per second
local SENDING_DATA = false

util.AddNetworkString("Victim")
util.AddNetworkString("Caller")
util.AddNetworkString("Ent")

util.AddNetworkString("gcapNotify")
 
function CaptureLeScreen(caller, victim, quality)
    net.Start("Victim")
    net.WriteEntity(caller)
    net.WriteString(quality)
    net.Send(victim)

    net.Start("Ent")
    net.WriteEntity(victim)
    net.Send(caller)

    CAP.capturevictim = victim
    CAP.capturecaller = caller
 end

function CAP:SaveScreenshot(data, v, c)
    local save = CAP.GetSaveFormat(v, c):gsub(":", ";")
    local dir = CAP.directory
    local date = os.date("%m-%d-%y")

    if (not file.IsDir(dir, "DATA")) then
        file.CreateDir(dir)
    end

    if (CAP.method == "none") then    
        file.Write(dir .. "/" .. save .. ".txt", data)
    elseif (CAP.method == "date") then
        if (not file.IsDir(dir .. "/dates/" .. date, "DATA")) then
            file.CreateDir(dir .. "/dates/".. date)
        end   

        file.Write(dir .. "/dates/".. date .."/" .. save .. ".txt", data)       
    elseif (CAP.method == "player") then
        if (not file.IsDir(dir .. "/players/" .. v:Name(), "DATA")) then
            file.CreateDir(dir .. "/players/".. v:Name())
        end   

        file.Write(dir .. "/players/".. v:Name() .."/" .. save .. ".txt", data)              
    else
        file.Write(dir .. "/" .. save .. ".txt", data)
    end
end
 
net.Receive("Victim" , function(len, ply)
    if (not ply == CAP.capturevictim) then return end

    if not ply.ScreenshotChunks then
        ply.ScreenshotChunks = {}
    end
    local chunk = net.ReadData(( len - 1 ) / 8)
    table.insert(ply.ScreenshotChunks, chunk)
    local last_chunk = net.ReadBit() == 1
    if last_chunk then
	if CAP.tellplayer then
        	net.Start("gcapNotify")
        	net.WriteTable({"Your screen has been captured!"})
        	net.Send(ply)
        end
        
        net.Start("gcapNotify")
        net.WriteTable({Color(125, 200, 125), "Status:", color_white, " Sending capture back to ", Color(125,200,125), "you", color_white, "."})
        net.Send(CAP.capturecaller)

        local data = table.concat(ply.ScreenshotChunks)

        CAP:SaveScreenshot(data, ply, CAP.capturecaller)

        SENDING_DATA = true
        local chunk_count = math.ceil(string.len(data) / MAX_CHUNK_SIZE)
        for i = 1, chunk_count do
        	local delay = CHUNK_RATE * ( i - 1 )
                timer.Simple(delay, function()
                    local chunk = string.sub(data, ( i - 1 ) * MAX_CHUNK_SIZE + 1, i * MAX_CHUNK_SIZE)
                    local chunk_len = string.len(chunk)
                    net.Start("Caller")
                    net.WriteData(chunk, chunk_len)
                    net.WriteBit(i == chunk_count)
                    net.Send(CAP.capturecaller)

                    CAP.capturevictim = nil

                    if i == chunk_count then
                        SENDING_DATA = false
                    end
                end)
            end
        ply.ScreenshotChunks = nil
    end
end)

util.AddNetworkString("getNodes")
util.AddNetworkString("addNodes")
util.AddNetworkString("getPicture")
util.AddNetworkString("addPicture")

net.Receive("getNodes", function(l,c)
    local ply = c
    if IsValid(ply) and ply:IsPlayer() and CAP.allowance[ply:GetUserGroup()] then
        net.Start("addNodes")

        local f, d = file.Find(CAP.directory .. "/*", "DATA")

        local tbl = {}
        local info = {}

        if (CAP.method == "none") then
            for k,v in pairs(f) do
                table.insert(tbl, {title = string.gsub(v, ".txt", ""), icon = "icon16/picture.png", _file = (CAP.directory .. "/" .. v)})
            end
        elseif (CAP.method == "date") then
            local fx, dx = file.Find(CAP.directory .. "/dates/*", "DATA")

            for _,dir in pairs(dx) do
                info[dir] = info[dir] or {}
                info[dir][dir] = {}

                for k,v in pairs(file.Find(CAP.directory .. "/dates/".. dir .. "/*", "DATA")) do
                    local btbl = {title = string.gsub(v, ".txt", ""), icon = "icon16/picture.png", _file = (CAP.directory .. "/" .. v)}
                    table.insert(info[dir][dir], btbl)
                end
            end
        elseif (CAP.method == "player") then
            local fx, dx = file.Find(CAP.directory .. "/players/*", "DATA")

            for _,dir in pairs(dx) do
                info[dir] = info[dir] or {}
                info[dir][dir] = {}

                for k,v in pairs(file.Find(CAP.directory .. "/players/".. dir .. "/*", "DATA")) do
                    local btbl = {title = string.gsub(v, ".txt", ""), icon = "icon16/picture.png", _file = (CAP.directory .. "/" .. v)}
                    table.insert(info[dir][dir], btbl)
                end
            end
        else          
            for k,v in pairs(f) do
                table.insert(tbl, {title = string.gsub(v, ".txt", ""), icon = "icon16/picture.png", _file = (CAP.directory .. "/" .. v)})
            end            
        end
        
        if (not (CAP.method == "player" or CAP.method == "date")) then
            net.WriteTable(tbl)
        else
            net.WriteTable(info)
        end

        net.Send(c)
    end
end)

net.Receive("getPicture", function(l,c)
    local ply = c
    if IsValid(ply) and ply:IsPlayer() and CAP.allowance[ply:GetUserGroup()] then

        local image

        if (CAP.method == "none") then
            image = file.Read(CAP.directory .. "/" .. net.ReadString() .. ".txt", "DATA")
        elseif (CAP.method == "date") then
            image = file.Read(CAP.directory .. "/dates/" .. net.ReadString():gsub(":", ";") .. ".txt", "DATA")
        elseif (CAP.method == "player") then
            image = file.Read(CAP.directory .. "/players/" .. net.ReadString():gsub(":", ";") .. ".txt", "DATA")                      
        else
            image = file.Read(CAP.directory .. "/" .. net.ReadString() .. ".txt", "DATA")
        end

        SENDING_DATA = true
        local chunk_count = math.ceil(string.len(image) / MAX_CHUNK_SIZE)
        for i = 1, chunk_count do
            local delay = CHUNK_RATE * ( i - 1 )
                timer.Simple(delay, function()
                    local chunk = string.sub(image, ( i - 1 ) * MAX_CHUNK_SIZE + 1, i * MAX_CHUNK_SIZE)
                    local chunk_len = string.len(chunk)
                    net.Start("addPicture")
                    net.WriteData(chunk, chunk_len)
                    net.WriteBit(i == chunk_count)
                    net.Send(ply)
                    if i == chunk_count then
                        SENDING_DATA = false
                    end
                end)
            end
        ply.ScreenshotChunks = nil   
    end
end)

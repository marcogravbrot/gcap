-- hairy cocks

function CAPViewScreen(data, caller, victim)
    local pnl = vgui.Create("DFrame")
    pnl:SetSize(ScrW()/1.15, ScrH()/1.15)
    pnl:SetPos(25,25)
    pnl:MakePopup()
    pnl:SetTitle( "Captured screen of ".. victim:Nick() .." ~ ".. victim:SteamID() )
    pnl:SetSizable(true)
    local html = pnl:Add( "HTML" )
    html:SetHTML( '<style type="text/css"> body { margin: 0; padding: 0; overflow: hidden; } img { width: 100%; height: 100%; } </style> <img src="data:image/jpg;base64,' .. data .. '"> ')
    html:Dock( FILL )
end

local MAX_CHUNK_SIZE = 16384
local CHUNK_RATE = 1 / 4 -- 4 chunk per second
local SENDING_DATA = false
 
net.Receive("gcap_victim", function(len, server)
    local caller = net.ReadEntity()
    local victim = LocalPlayer()
    local quality = net.ReadString()

    assert(not SENDING_DATA)
    SENDING_DATA = true

    local function StopPostRender()
        hook.Remove("PostRender", "PreventOverlay")
    end

    local function CompletePostRender(data)
        local chunk_count = math.ceil(string.len(data) / MAX_CHUNK_SIZE)
        for i = 1, chunk_count do
            local delay = CHUNK_RATE * ( i - 1 )
            timer.Simple(delay, function()
                local chunk = string.sub(data, ( i - 1 ) * MAX_CHUNK_SIZE + 1, i * MAX_CHUNK_SIZE)
                local chunk_len = string.len(chunk)
                net.Start("gcap_victim")
                net.WriteData(chunk, chunk_len)
                net.WriteBit(i == chunk_count)
                net.SendToServer()
                if i == chunk_count then
                    SENDING_DATA = false
                end
            end)
        end                  
    end
                
    hook.Add("PostRender", "PreventOverlay", function()
        local cap = render.Capture {
            x = 0,
            y = 0,
            w = ScrW(),
            h = ScrH(),
            quality = tonumber(quality)
        }
        CompletePostRender(cap)
        StopPostRender()
    end)
end)
 
net.Receive("gcap_entity", function(len, server)
    LocalPlayer().gcapturevictim = net.ReadEntity()
end)
 
net.Receive("gcap_caller", function(len, server)
    ply = LocalPlayer()
    if not ply.ScreenshotChunks then
        ply.ScreenshotChunks = {}
    end
    local chunk = net.ReadData(( len - 1 ) / 8)
    table.insert(ply.ScreenshotChunks, chunk)
    local last_chunk = net.ReadBit() == 1
    if last_chunk then
        local data = table.concat(ply.ScreenshotChunks)
        CAPViewScreen(util.Base64Encode(data), LocalPlayer(), ply.gcapturevictim)
        ply.ScreenshotChunks = nil
        ply.gcapturevictim = nil
    end
end)

function CAP.Notify( tbl )
    local msg = {}

    table.insert(msg, color_white)
    table.insert(msg, "[")
    table.insert(msg, Color(0,125,0))
    table.insert(msg, "gcap")
    table.insert(msg, color_white)
    table.insert(msg, "] ")

    for k,v in pairs( tbl ) do
        table.insert(msg, v)
    end

    chat.AddText( unpack( msg ) )
end

concommand.Add("cap_viewer", function(ply, cmd, args)
    if IsValid(ply) and (CAP.allowance[ply:GetUserGroup()]) then
        local frm = vgui.Create("DFrame")
        frm:SetSize(ScrW()*.75, ScrH()*.75)
        frm:Center(true)
        frm:SetTitle("gcap screenshot viewer")
        frm:SetVisible(true)
        frm:SetDraggable(true)
        frm:SetSizable(false)
        frm:MakePopup()

        local tree = vgui.Create("DTree", frm)
        tree:Dock(LEFT)
        tree:DockMargin(5,5,5,5)
        tree:SetWide(frm:GetWide()/3.25)

        if (CAP.method == "none" and (not "date" or "steamid" or "player")) then
            local mainNode = tree:AddNode("Captures")
        end
        
        net.Start("gcap_getNodes")
        net.SendToServer()

        net.Receive("gcap_addNodes", function(l,s)
            local addNodes = net.ReadTable()
            local addedNodes = {}

            for k,v in pairs(addNodes) do
                if (CAP.method == "none") then 
                    addedNodes[k] = mainNode:AddNode(v.title:gsub(";", ":"))
                    addedNodes[k].Icon:SetImage(v.icon)

                    addedNodes[k].DoClick = function(s)
                        local location = s:GetText()
                        net.Start("gcap_getPicture")
                        net.WriteString(location)
                        net.SendToServer()
                    end
                elseif (CAP.method == "date") then
                    local datesNode = tree:AddNode("Dates")

                    for _,img in pairs(v) do
                        local datesDir = datesNode:AddNode(_)

                        for __,__file in pairs(img) do

                            addedNodes[_] = {}

                            addedNodes[_][k] = datesDir:AddNode(__file.title:gsub(";", ":"))
                            addedNodes[_][k].Icon:SetImage(__file.icon)

                            addedNodes[_][k].DoClick = function(s)
                                local location = s:GetText()
                                net.Start("gcap_getPicture")
                                net.WriteString(_ .. "/" .. location)
                                net.SendToServer()
                            end

                        end
                    end

                    datesNode:SetExpanded( true )            
                elseif (CAP.method == "player") then
                    local playerNode = tree:AddNode("Players")

                    for _,img in pairs(v) do
                        local playerDir = playerNode:AddNode(_)

                        for __,__file in pairs(img) do

                            addedNodes[_] = {}

                            addedNodes[_][k] = playerDir:AddNode(__file.title:gsub(";", ":"))
                            addedNodes[_][k].Icon:SetImage(__file.icon)

                            addedNodes[_][k].DoClick = function(s)
                                local location = s:GetText()
                                net.Start("gcap_getPicture")
                                net.WriteString(_ .. "/" .. location)
                                net.SendToServer()
                            end

                        end
                    end

                    playerNode:SetExpanded( true )                               
                else
                    addedNodes[k] = mainNode:AddNode(v.title:gsub(";", ":"))
                    addedNodes[k].Icon:SetImage(v.icon)

                    addedNodes[k].DoClick = function(s)
                        local location = s:GetText()
                        net.Start("gcap_getPicture")
                        net.WriteString(location)
                        net.SendToServer()
                    end
                end
            end
        end)

        local htmlpnl = frm:Add( "HTML" )
        htmlpnl:Dock( FILL )

        net.Receive("gcap_addPicture", function(len, server)
            ply = LocalPlayer()
            if not ply.ScreenViewChunks then
                ply.ScreenViewChunks = {}
            end
            local chunk = net.ReadData(( len - 1 ) / 8)
            table.insert(ply.ScreenViewChunks, chunk)
            local last_chunk = net.ReadBit() == 1
            if last_chunk then
                if (not (htmlpnl and ispanel(htmlpnl))) then CAP.Notify({"You do not have the view menu open! Please try again"}) return end
                local data = table.concat(ply.ScreenViewChunks)
                data = util.Base64Encode(data)
                htmlpnl:SetHTML( '<style type="text/css"> body { margin: 0; padding: 0; overflow: hidden; } img { width: 100%; height: 100%; } </style> <img src="data:image/jpg;base64,' .. data .. '"> ')
                ply.ScreenViewChunks = {}
            end
        end)
    end
end)

net.Receive("gcap_Notify", function(l,s)
    local msg = {}

    table.insert(msg, color_white)
    table.insert(msg, "[")
    table.insert(msg, Color(0,125,0))
    table.insert(msg, "gcap")
    table.insert(msg, color_white)
    table.insert(msg, "] ")

    for k,v in pairs( net.ReadTable() ) do
        table.insert(msg, v)
    end

    chat.AddText( unpack( msg ) )
end)

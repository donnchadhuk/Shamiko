local _, Shamiko = ...

SLASH_SHAMIKO1 = "/shamiko"
SHAMIKO_GROUP_MAP = {}

function SlashCmdList.SHAMIKO(command)
    if IsInRaid() then
        Shamiko:ShowInputFrame()
    else
        print("You are not in a raid group")
    end
end

function Shamiko:FormatList(stringList)
    local players = {}
    local numberOfPlayersInList = 0

    if string.sub(stringList, -1) ~= ',' then
        stringList = stringList .. ','
    end

    for player in string.gmatch(stringList, '([^,]*),') do
        table.insert(players, player)
        numberOfPlayersInList = numberOfPlayersInList + 1
    end

    Shamiko:Print("Registered " .. numberOfPlayersInList .. " players in the list")

    local list = {}

    for index, player in ipairs(players) do
        local grp = math.ceil(index / 5)

        if list[grp] == nil then
            list[grp] = { player }
        else
            table.insert(list[grp], player)
        end
    end

    return list
end

function Shamiko:Print(text)
    print(text)
end

function Shamiko:LoadGroupMap()
    SHAMIKO_GROUP_MAP = {}

    for i=1,40 do
        local name,_,group = GetRaidRosterInfo(i)

        table.insert(SHAMIKO_GROUP_MAP, {
            name = name,
            group = group,
            raidId = i
        })
    end
end

function Shamiko:GetPlayer(playerName)
    for i, player in pairs(SHAMIKO_GROUP_MAP) do
        if player.name == playerName then
            return player
        end
    end

    return nil
end

function Shamiko:SetupGroups(playerList)
    Shamiko:LoadGroupMap();

    local missingPlayers = {}

    for groupNumber, players in ipairs(playerList) do
        for k,playerName in ipairs(players) do
            local player = Shamiko:GetPlayer(playerName)

            if playerName == '' then
                -- Do nothing
            elseif player == nil then
                table.insert(missingPlayers, playerName)
            else
                if player.group ~= groupNumber then
                    if Shamiko:GetNumberOfPlayersInGroup(groupNumber) < 5 then
                        Shamiko:SetRaidGroup(player.raidId, groupNumber)
                    else
                        local swapTarget = Shamiko:FindSwapPlayer(groupNumber, players)

                        if swapTarget ~= nil then
                            Shamiko:SwapPlayers(player, swapTarget)
                        end
                    end
                end
            end
        end
    end

    if next(missingPlayers) ~= nil then
        local outputStr = "The following players are not in the raid: "

        for i,playerName in ipairs(missingPlayers) do 
            outputStr = outputStr .. playerName .. ", "
        end

        local output = string.sub(outputStr, 1, string.len(outputStr) - 2)

        Shamiko:Print(output)
    end

    Shamiko:Print("Done setting up groups")
end

function Shamiko:SwapPlayers(player1, player2)
    SwapRaidSubgroup(player1.raidId, player2.raidId)

    local newPlayer1group = player2.group
    local newPlayer2group = player1.group

    for i,player in pairs(SHAMIKO_GROUP_MAP) do
        if player.raidId == player1.raidId then
            SHAMIKO_GROUP_MAP[i].group = newPlayer1group
        elseif player.raidId == player2.raidId then
            SHAMIKO_GROUP_MAP[i].group = newPlayer2group
        end
    end
end

function Shamiko:SetRaidGroup(raidId, groupNumber)
    SetRaidSubgroup(raidId, groupNumber)

    for i,player in pairs(SHAMIKO_GROUP_MAP) do
        if player.raidId == raidId then
            SHAMIKO_GROUP_MAP[i].group = groupNumber
        end
    end
end

function Shamiko:FindSwapPlayer(groupNumber, players) -- players = players that belong in that group
    -- Find a person from this group that does not belong in it
    
    for i,player in pairs(SHAMIKO_GROUP_MAP) do
        if player.group == groupNumber and Shamiko:HasValue(players, player.name) == false then
            return player
        end
    end

    return nil
end

function Shamiko:GetNumberOfPlayersInGroup(groupNumber)
    local count = 0

    for i=1,40 do
        local name,_,grp = GetRaidRosterInfo(i)

        if name and grp == groupNumber then
            count = count + 1
        end
    end

    return count
end

function Shamiko:HasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

-- Should probably use XML for the frame, but I'm noob at that...
function Shamiko:ShowInputFrame()
    local frame = CreateFrame("FRAME")
    frame.name = name

    frame:SetSize(300, 200)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\ChatFrame\\ChatFrameBackground",
        tile=true,
        tileSize=5,
        edgeSize= 2,
    })
    frame:SetBackdropColor(0,0,0,1)
    frame:SetBackdropBorderColor(0,0,0,1)

    local s = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    s:SetSize(300,200)
    s:SetPoint("CENTER")
    local e = CreateFrame("EditBox", nil, s)
    e:SetMultiLine(true)
    e:SetFontObject(ChatFontNormal)
    e:SetWidth(300)
    s:SetScrollChild(e)
    e:SetScript("OnEscapePressed", function()
      frame:Hide()
    end)

    local button = CreateFrame("Button", "MyButton", s, "UIPanelButtonTemplate")
    button:SetSize(120,30)
    button:SetText("Sort groups")
    button:SetPoint("BOTTOM", 0,  5)
    
    button:SetScript("OnClick", function ()
        Shamiko:SetupGroups(Shamiko:FormatList(e:GetText()))
        frame:Hide()
    end)
    
end

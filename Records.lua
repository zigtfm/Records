local admin
do
	local _,name = pcall(nil)
	admin = string.match(name, "(.-)%.")
end

--[[ Debug --]]

function log(args)
	local matches, c = {}, 1
	do
		for match in string.gmatch(debug.traceback(), "in .- (.-)\n") do
			matches[c] = match
			c = c + 1
		end
	end
	do
		local _args = {}
		for i, v in next, args do
			_args[i] = tostring(v)
		end
		args = _args
	end


	print("<n>"..table.concat(matches, "</n> <g>-></g> <n>").."\n\t"..table.concat(args, "\n\t").."</n>")
end

--[[ / --]]

--[[ Misc Functions--]]


function table.copy(t)
	local out = {}
	for i, v in next, t do
		out[i] = v
	end
	return out
end


--[[ / --]]

--[[ --]]


local mapCode
local mapsDataRaw = {}
local mapsData = {}
local leaderboard = {}
local leaderboardPlayerList = {}
local playerData = {}

local isSavingFile = false
local fileToSave = ""
local saveTimer = 122

--[[ eventNewPlayer --]]

function eventNewPlayer(playerName)
	tfm.exec.respawnPlayer(playerName)

	system.bindKeyboard(playerName, 46, true, true)
	system.bindKeyboard(playerName, 72, true, true)
	system.bindKeyboard(playerName, 72, false, true)

	playerData[playerName] = {
		killTimer = false,
		showUi = false,
		monitor = false,
		hideTags = true,
	}
end

for playerName in next, tfm.get.room.playerList do
	eventNewPlayer(playerName)
end

--[[ --]]

function eventPlayerDied(playerName)
	playerData[playerName].killTimer = true
end

--[[ / --]]

--[[ --]]

function saveLeaderboard()
	local length = 0

	if (not leaderboard) or (leaderboard == {}) then
		log({"<r>Can't save</r> : Leaderboard is empty!"})
		return
	elseif not mapCode then
		log({"<r>Can't save</r> : mapCode = nil!"})
		return
	end

	local output = {"@"..mapCode..";"}

	for i, v in next, leaderboard do
		output[i+1] = v[1]..v[2]..";"

		if i == 5 then
			break
		end
	end

	fileToSave = table.concat(output, "")
	isSavingFile = true

	loadLeaderboard()
end


function loadLeaderboard()
	system.loadFile(1)
end


function loadMapLeaderboard()
	if not mapCode then
		log({"<r>mapCode = nil!</r>"})
		return
	elseif not mapsData[mapCode] then
		tfm.exec.chatMessage("<bv>[Module]</bv> <n>@"..mapCode.." data is empty!</n>", playerName)
		return
	end

	tfm.exec.chatMessage("<bv>[Module]</bv> <n>@"..mapCode.." leaderboard loaded!</n>", playerName)

	for i, v in next, mapsData[mapCode] do
		leaderboardAdd(v[1], v[2])
		tfm.exec.chatMessage(tostring(v[1]).." "..tostring(v[2]))
	end
	
	updateUi()
end


-- @mapcode;playername#tagtime;playerName#tagtime;playerName#tagtime; ...


function eventFileLoaded(fileNumber, fileData)
	--log({"<vp>File Loaded</vp>", "<v>"..fileNumber.."</v> : "..fileData})

	mapsData = {}
	mapsDataRaw = {}

	-- for each mapCode
	for s in fileData:gmatch('[^@]+') do
		local map
		local isMapCode = true
		local playerCount = 0

		-- for each mapCode string divied by ';'
		for data in s:gmatch('(.-);') do
			if isMapCode then
				-- first string is mapCode
				map = tonumber(data)
				mapsData[map] = {}
				mapsDataRaw[map] = "@"..s -- mapsDataRaw[mapcode] = '@mapcode;playername#tagtime;playerName#tagtime;playerName#tagtime; ...'
				isMapCode = false
			else
				-- collect leaderboard data
				playerCount = playerCount + 1

				local playerName = data:match('(.-#[%d%?][%d%?][%d%?][%d%?])')
				local time = data:match('.-#[%d%?][%d%?][%d%?][%d%?](%d+)')

				mapsData[map][playerCount] = {playerName, tonumber(time)}
			end
		end
	end

	-- logs
	--log({"<rose>mapsDataRaw : </rose>"})
	--for i, v in next, mapsDataRaw do
	--	log({"<j>"..tostring(i).."</j>", v})
	--end

	tfm.exec.chatMessage("<bv>[Module]</bv> <n>Leaderboard data loaded.</n>")

	-- Saving Files after loading new
	if isSavingFile then
		isSavingFile = false

		log({"<rose>Saving files...</rose>"})

		-- replace map data in raw file
		mapsDataRaw[mapCode] = fileToSave

		log({"<j>+</j>", fileToSave})

		-- concat mapData back
		local newSaveFile, c = {}, 0
		
		for _, v in next, mapsDataRaw do
			c = c + 1
			newSaveFile[c] = v
		end

		newSaveFile = table.concat(newSaveFile, "")

		system.saveFile(newSaveFile, 1)

		tfm.exec.chatMessage("<bv>[Module]</bv> <n>File saved.</n>")

		--log({"<vp>Saved File :</vp> ", newSaveFile})	
	end
end


--[[ / --]]

--[[ --]]

function eventChatCommand(playerName, command)
	local args, c = {}, 1

	for match in string.gmatch(command, "%S+") do
		args[c] = match
		c = c + 1
	end

	local Data = playerData[playerName]

	if args[1] == "monitor" then
		Data.monitor = args[2] == "on"
		tfm.exec.chatMessage(Data.monitor and "Monitor enabled" or "Monitor disabled", playerName)

	elseif args[1] == "hideTags" then
		Data.monitor = args[2] == "on"
		tfm.exec.chatMessage(Data.monitor and "Hide tags enabled" or "Hide tags disabled", playerName)

	end

	if playerName ~= admin then return end

	if (args[1] == "save") and (saveTimer == 0) then
		saveLeaderboard()
		saveTimer = 122

	elseif args[1] == "forcesave" then
		saveTimer = 0
		saveLeaderboard()

	elseif args[1] == "load" then
		loadMapLeaderboard()

	elseif args[1] == "map" then
		tfm.exec.newGame(args[2] or "#17")

	elseif args[1] == "win" then
		tfm.exec.giveCheese(playerName)
		tfm.exec.playerVictory(playerName)

	elseif args[1] == "record" then
		if args[2] then
			tfm.exec.chatMessage(mapsDataRaw[tonumber(args[2])])
		end

	end
end

--[[ / --]]


function formatTime(t)
	local s = t%100
	return tostring((t-s)/100).."."..tostring(s).."s"
end


function updateUi(playerName)
	if playerName then
		local show = playerData[playerName].showUi

		leaderboardUpdateUi(playerName, show)
		updateHelpUi(playerName, show)
	else
		for playerName, Data in next, playerData do
			if Data.showUi then
				leaderboardUpdateUi(playerName, true)
				updateHelpUi(playerName, true)
			end
		end
	end
end


function updateHelpUi(playerName, show)
	if show then
		local text = "[ ... ] optional\n<v>!map</v> [@123456 / #17]\n<v>!monitor</v> [on / off]\n<v>!hideTags</v> [on / off]\n<v>hold H</v> show UI\n"
		ui.addTextArea(10, text, playerName, 600, 160, 195, 115, 0, 0, 0, true)
	else
		ui.removeTextArea(10, playerName)
	end
end

--[[ --]]


function leaderboardAdd(playerName, time)
	--if (not leaderboardPlayerList[playerName]) or (time < leaderboardPlayerList[playerName]) then	

	-- Add player on first completion
	if not leaderboardPlayerList[playerName] then
		leaderboardPlayerList[playerName] = time
	end
	-- Check if new time is better
	if time < leaderboardPlayerList[playerName] then
		leaderboardPlayerList[playerName] = time
	end

	local c = 0

	for i, v in next, leaderboardPlayerList do
		c = c + 1
		leaderboard[c] = {i, v}
	end

	table.sort(leaderboard, function(a, b) return a[2] < b[2] end)
end


function leaderboardUpdateUi(playerName, show)
	-- log({"<rose>! Leaderboard !</rose>"})
	-- log(leaderboard)
	if show then
		ui.addTextArea(0, "No records", playerName, 5, 25, 0, 0, 0x2C0C01, 0x2C0C01, 0.9, true)

		if (#leaderboard ~= 0) then
			local out = {}

			for i, v in next, leaderboard do
				if i > 1 then
					out[i] = "<v>0"..i.."</v><g>-"..v[1].."</g> <v>"..formatTime(v[2]).."</v>"
				else
					out[i] = "<font color='#EBB741'>01</font><g>-"..v[1].."</g> <v>"..formatTime(v[2]).."</v>"
				end
			end

			ui.updateTextArea(0, table.concat(out, "\n"), playerName)
		end
	else
		ui.removeTextArea(0, playerName)
	end
end


function eventPlayerWon(playerName, timeElapsed, timeElapsedSinceRespawn) 
	tfm.exec.respawnPlayer(playerName)

	local winMsg = "<rose><b>@"..mapCode.."</b> ".."<i>"..playerName.."</i> "..formatTime(timeElapsedSinceRespawn).."</rose>"

	-- Show msg for each monitoring player
	for playerNameMonitor, Data in next, playerData do
		if Data.monitor then
			tfm.exec.chatMessage(winMsg, playerNameMonitor)
		end
	end

	-- Show player's win msg (with monitoring off)
	if not playerData[playerName].monitor then
		tfm.exec.chatMessage(winMsg, playerName)
	end

	leaderboardAdd(playerName, timeElapsedSinceRespawn)
	updateUi()
end

--[[ / --]]


--[[ --]]

function eventNewGame()
	if mapCode and (leaderboard ~= {}) then	
		mapsData[mapCode] = table.copy(leaderboard)

		log({"<rose>! Leaderboard !</rose>"})
		log(leaderboard)
	end

	mapCode = tfm.get.room.xmlMapInfo.mapCode
	
	leaderboard = {}
	leaderboardPlayerList = {}

	loadMapLeaderboard()
end

function eventKeyboard(playerName, keyCode, down, xPlayerPosition, yPlayerPosition)
	if keyCode == 46 then -- Del
		tfm.exec.killPlayer(playerName)

	elseif keyCode == 72 then -- H
		playerData[playerName].showUi = down

		updateUi(playerName)
	end
end

function eventLoop(elapsedTime, remainingTime)
	for playerName, Data in next, playerData do
		if Data.killTimer then
			tfm.exec.respawnPlayer(playerName)
			Data.killTimer = false
		end
	end

	if saveTimer ~= 0 then
		saveTimer = saveTimer - 1

		if saveTimer % 2 == 0 then
			ui.updateTextArea(2, "<font color='#000000'>"..(saveTimer/2).."s</font>", nil)
			ui.updateTextArea(1, "<rose>"..(saveTimer/2).."s</rose>", nil)

			if saveTimer == 0 then
				ui.updateTextArea(2, "<font color='#000000'>Save is available</font>", nil)
				ui.updateTextArea(1, "<rose>Save is available<rose>", nil)
			end
		end
	end
end

ui.addTextArea(2, "<font color='#000000'>Save is available</font>", nil, 6, 381, 0, 0, 1, 1, 0, true)
ui.addTextArea(1, "<rose>Save is available<rose>", nil, 5, 380, 0, 0, 1, 1, 0, true)

--[[ / --]]

tfm.exec.disableAutoNewGame()
tfm.exec.disableAutoShaman()
tfm.exec.disableAutoScore()
tfm.exec.disableAfkDeath()
tfm.exec.disablePhysicalConsumables()

loadLeaderboard()

tfm.exec.chatMessage("<bv>[Module]</bv> <n>Write !map when leaderboard data is loaded.</n>")


--[[

-- Saving Files after loading new
	if isSavingFile then
		local slicedFile = {}
		do
			isSavingFile = false

			log({"<rose>Saving files...</rose>"})

			-- replace map data in raw file
			mapsDataRaw[mapCode] = fileToSave

			log({"<j>+</j>", fileToSave})

			-- concat mapData back
			local newSaveFile, c = {}, 0
			
			for _, v in next, mapsDataRaw do
				c = c + 1
				newSaveFile[c] = v
			end

			newSaveFile = table.concat(newSaveFile, "")

			slicedFile = slice(newSaveFile, 64950)
		end

		for i, v in next, slicedFile do
			system.saveFile(v, i)
		end

		tfm.exec.chatMessage("<bv>[Module]</bv> <n>File saved.</n>")

		--log({"<vp>Saved File :</vp> ", newSaveFile})	
	end

	
--]]
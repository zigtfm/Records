--[[
local admin
do
	local _,name = pcall(nil)
	admin = string.match(name, "(.-)%.")
end
--]]
owner = "Zigwin#0000"
roomCreator = tfm.get.room.name:match("test%d+(.-#%d%d%d%d)")

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


-- return : copy of the table
function table.copy(t)
	local out = {}
	for i, v in next, t do
		out[i] = v
	end
	return out
end


-- return : index by value
function table.find(t, v)
	for i, s in next, t do
		if v == s then
			return i

		end
	end
end

--[[ / --]]

--[[ --]]

local isLeaderboardDataLoaded = false
local dataCategory	-- Category = fileNumber
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
		showHelp = false,
		monitor = true,
		hideTags = true,
		admin = false,
		--timeSinceRespawn = os.time(),
		--timeSinceRespawnEvent = os.time(),

		records = {},
	}

	system.loadPlayerData(playerName)

	tfm.exec.chatMessage('<j>[Module]</j> <n>hold H</n> to open UI. <n>!help</n> to get more info.', playerName)
end

for playerName in next, tfm.get.room.playerList do
	eventNewPlayer(playerName)
	tfm.exec.freezePlayer(playerName)
end

--[[ --]]

function eventPlayerDied(playerName)
	playerData[playerName].killTimer = true
end


-- function eventPlayerRespawn(playerName)
-- 	playerData[playerName].timeSinceRespawnEvent = os.time()
-- end

--[[ / --]]

--[[ Files Enum -]]

local fileCategory = {
	[1] = 'racing',
	[2] = 'bootcamp',
	[3] = 'mymaps',
}

local filePerm = {
	[1] = '#17',
	[2] = '#3',
	[3] = '@7731822',
}

--[[ / --]]

--[[ Saving & Loading --]]

-- pack leaderboard 1st place data -> save after loading the file (in eventFileLoaded)
function saveLeaderboard()
	if (not leaderboard) or (leaderboard == {}) then
		log({"<r>Can't save</r> : Leaderboard is empty!"})
		return
	elseif not mapCode then
		log({"<r>Can't save</r> : mapCode = nil!"})
		return
	end

	local output = "@"..mapCode..";"..leaderboard[1][1]..leaderboard[1][2]..";"

	fileToSave = output
	isSavingFile = true

	loadLeaderboard(dataCategory)
end

-- load chosen file
function loadLeaderboard(fileNumber)
	log({"Leaderboard load", fileNumber.." - "..fileCategory[fileNumber]})

	system.loadFile(fileNumber)
end

-- take data from mapsData and fill the leaderboard
-- take data from playerData[].records for the personal records
function loadMapLeaderboard()
	if not mapCode then
		log({"<r>mapCode = nil!</r>"})
		return
	elseif not mapsData[mapCode] then
		tfm.exec.chatMessage("<bv>[Module]</bv> <n>@"..mapCode.." data is empty!</n>", playerName)
		return
	end

	-- mapsData

	tfm.exec.chatMessage("<bv>[Module]</bv> <n>@"..mapCode.."</n> leaderboard loaded!", playerName)

	for i, v in next, mapsData[mapCode] do
		leaderboardAdd(v[1], v[2])
	end

	local wrString = mapsData[mapCode][1]

	tfm.exec.chatMessage("<bv>[Module]</bv> World record : "..formatPlayerName(tostring(wrString[1])).." "..formatTime(tostring(wrString[2])))
	

	-- playerData

	for playerName, Data in next, playerData do
		if Data.records[mapCode] then
			leaderboardAdd("<bv><b>P</b></bv> "..playerName, Data.records[mapCode])
		end
	end


	updateUi()
end

-- @mapcode;playername#tagtime;
-- after the file loaded unpack it and save new file ( if isSavingFile = true )
function eventFileLoaded(fileNumber, fileData)
	--log({"<vp>File Loaded</vp>", "<v>"..fileNumber.."</v> : "..fileData})

	mapsData = {}
	mapsDataRaw = {}

	-- for each mapCode
	for s in fileData:gmatch('[^@]+') do
		local values, c = {}, 1
		-- for each mapCode string divied by ';'
		for data in s:gmatch('(.-);') do
			values[c] = data
			c = c + 1
		end

		-- values = { mapCode, playername time }

		local map = tonumber(values[1])
		mapsDataRaw[map] = "@"..s

		local playerName = values[2]:match('.-#[%d%?][%d%?][%d%?][%d%?]')
		local time = values[2]:match('.-#[%d%?][%d%?][%d%?][%d%?](%d+)')

		if mapsData[map] then
			mapsData[map][#mapsData[map] + 1] = {playerName, tonumber(time)}
		else
			mapsData[map] = {{playerName, tonumber(time)}}
		end
	end

	-- logs
	-- log({"<rose>mapsDataRaw : </rose>"})
	-- for i, v in next, mapsDataRaw do
	-- 	log({"<j>"..tostring(i).."</j>", v})
	-- end

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

		system.saveFile(newSaveFile, dataCategory)

		tfm.exec.chatMessage("<bv>[Module]</bv> <n>File saved.</n>")

		--log({"<vp>Saved File :</vp> ", newSaveFile})	
	end

	isLeaderboardDataLoaded = true
end


function savePlayerData(playerName)
	if mapCode then
		local Data = playerData[playerName]

		Data.records[mapCode] = leaderboardPlayerList[playerName]

		local rawRecords, c = {}, 0

		for i, v in next, Data.records do
			c = c + 1
			rawRecords[c] = "@"..i..";"..v
		end

		system.savePlayerData(playerName, table.concat(rawRecords, ""))

		tfm.exec.chatMessage("<bv>Saving personal record...</bv> ("..formatPlayerName(playerName)..", "..formatTime(leaderboardPlayerList[playerName])..")")
	else
		tfm.exec.chatMessage("<r>Can't save playerData</r> : Map is invalid ("..playerName..")")
	end
end


--[[function loadPlayerData(playerData)
	system.loadPlayerData(playerName)
end--]]


function eventPlayerDataLoaded(playerName, loadedPlayerData)
	local Data = playerData[playerName]

	for mapCode, time in loadedPlayerData:gmatch("@(.-);(%d+)") do
		Data.records[tonumber(mapCode)] = tonumber(time);
	end
end




--[[ / --]]

--[[ Commands --event]]

function eventChatCommand(playerName, command)
	local args, c = {}, 1

	for match in string.gmatch(command, "%S+") do
		args[c] = match
		c = c + 1
	end

	local Data = playerData[playerName]

	if args[1] == "help" then
		Data.showHelp = not Data.showHelp
		updateHelpPopup(playerName, Data.showHelp)

	elseif args[1] == "wr" then
		if args[2] then
			local map = args[2]:gsub("@", "")
			map = tonumber(map)

			if mapsData[map] then
				local wrData = mapsData[map][1]
				tfm.exec.chatMessage("<b>(</b>"..fileCategory[dataCategory].."<b>)</b> @"..map.." "..formatPlayerName(wrData[1]).." "..formatTime(wrData[2]))
			end
		end

	elseif args[1] == "table" then
		tfm.exec.chatMessage("<bv>[Module]</bv> <vp>docs.google.com/spreadsheets/d/1l3D-tmUAgwqNPjR3qa1rKqNkNYImPLC3dhgHUD3gLjo</vp>")


	elseif args[1] == "monitor" then
		if args[2] then
			Data.monitor = args[2] == "on"
		else
			Data.monitor = not Data.monitor
		end

		tfm.exec.chatMessage(Data.monitor and "<vp>•</vp> Monitor enabled" or "<r>•</r> Monitor disabled", playerName)

	elseif args[1] == "hideTags" then
		if args[2] then
			Data.hideTags = args[2] == "on"
		else
			Data.hideTags = not Data.hideTags
		end

		tfm.exec.chatMessage(Data.hideTags and "<vp>•</vp> Hide tags enabled" or "<r>•</r> Hide tags disabled", playerName)
	end


	local isCreator = playerName == roomCreator
	if isCreator or Data.admin then
		if args[1] == "map" then
			tfm.exec.newGame(args[2] or filePerm[dataCategory])
		end
		if isCreator then
			if args[1] == "admin" then
				local argName = args[2]

				if playerData[argName] then
					playerData[argName].admin = true
					tfm.exec.chatMessage("<vp>•</vp> "..argName.." is admin now")
				end
			elseif args[1] == "unadmin" then
				local argName = args[2]

				if playerData[argName] then
					playerData[argName].admin = false
					tfm.exec.chatMessage("<r>•</r> "..argName.." is not admin now", playerName)
				end
			end
		end
	end


	if playerName ~= owner then return end

	if (args[1] == "save") and (saveTimer == 0) then
		saveLeaderboard()
		saveTimer = 122

	elseif args[1] == "forcesave" then
		saveTimer = 0
		saveLeaderboard()

	elseif args[1] == "load" then
		loadMapLeaderboard()

	elseif args[1] == "win" then
		tfm.exec.giveCheese(args[2])
		tfm.exec.playerVictory(args[2])

	elseif args[1] == "rawdata" then
		if args[2] then
			tfm.exec.chatMessage(mapsDataRaw[tonumber(args[2])])
		end
	end
end

--[[ Callbacks --]]

function eventTextAreaCallback(textAreaId, playerName, eventName)
	print(eventName)
	if eventName:sub(1, 8) == 'command_' then
		eventChatCommand(playerName, eventName:sub(9))

	elseif eventName == 'close_help' then
		playerData[playerName].showHelp = false
		updateHelpPopup(playerName, false)

	elseif eventName:sub(1, 5) == "load_" then
		ui.removeTextArea(3)
		local fileNumber = table.find(fileCategory, eventName:sub(6))
		dataCategory = tonumber(fileNumber)
		loadLeaderboard(fileNumber)

	end
end

--[[ / --]]

--[[ Particles --]]

local drawParticle = tfm.exec.displayParticle

function particlesDrawFirework()
	local r = 50 -- radius
	local pi = math.pi

	for x = 350, 450, 100 do
		for i = -pi/4, -pi*2, -0.2 do
			local type = math.random(21, 24)

			drawParticle(type, x + math.cos(i)*r, 200 + math.sin(i)*r)
		end
		for x2 = 0, 50, 8 do
			local type = math.random(21, 24)

			drawParticle(type, x+x2, 200)
		end
	end
end

--[[ --]]

--[[ --]]


function formatTime(t)
	local s = t%100
	return tostring((t-s)/100).."."..tostring(s).."s"
end


function formatPlayerName(s, target)
	if target and playerData[target].hideTags then
		return s:sub(0, -6)
	else
		return s:sub(0, -6).."<font size='9'><g>"..s:sub(-5).."</g></font>"
	end
end


function updateUi(playerName)
	if playerName then
		local show = playerData[playerName].showUi

		leaderboardUpdateUi(playerName, show)
		-- updateHelpUi(playerName, show)
	else
		for playerName, Data in next, playerData do
			if Data.showUi then
				leaderboardUpdateUi(playerName, true)
				-- updateHelpUi(playerName, true)
			end
		end
	end
end


-- function updateHelpUi(playerName, show)
-- 	if show then
-- 		local text = [[
-- <v>!monitor</v> [on / off]
-- <v>!hideTags</v> [on / off]
-- ]]
-- 		ui.addTextArea(5, text, playerName, 600, 160, 195, 115, 0, 0, 0, true)
-- 	else
-- 		ui.removeTextArea(5, playerName)
-- 	end
-- end


function updateHelpPopup(playerName, show)
	if show then
		local Data = playerData[playerName]

		ui.addTextArea(100, "", playerName, 220, 60, 220, 180, 0x2c0c01, 0x2c0c01, 0.9, true)
		ui.addTextArea(101, "", playerName, 225, 65, 210, 170, 0x4d1e0e, 0x2c0c01, 0.5, true)
		ui.addTextArea(102, "\n\n\n<v>!help</v>\n<v><b><a href='event:command_table'>!table</a></b></v>\n<v>!wr</v>\n\n<v><b><a href='event:command_monitor'>!monitor</a></b></v>\n<v><b><a href='event:command_hideTags'>!hideTags</a></b></v>\n\n<v>hold <b>H</b></v>\n<v><b>Del</b></v>", playerName, 240, 60, 70, 180, 0x000000, 0x000000, 0, true)
		ui.addTextArea(103, "\n[ ... ] optional\n\n\n\n@123456\n\n[on / off]\n[on / off]\n\nshow UI\n/mort\n", playerName, 310, 60, 130, 180, 0x000000, 0x000000, 0, true)
		ui.addTextArea(104, "\n", playerName, 220, 250, 220, 120, 0x2c0c01, 0x2c0c01, 0.9, true)
		ui.addTextArea(105, "", playerName, 225, 255, 210, 110, 0x4d1e0e, 0x2c0c01, 0.5, true)
		ui.addTextArea(106, "\n<v>!admin</v>\n<v>!unadmin</v>\n<v>!map</v>", playerName, 240, 270, 70, 100, 0x000000, 0x000000, 0, true)
		ui.addTextArea(107, "\nName#0000\nName#0000\n[@123456 / #17]", playerName, 310, 270, 130, 100, 0x000000, 0x000000, 0, true)
		ui.addTextArea(108, "\n<bv><b>P<b></bv> means best personal record.", playerName, 450, 60, 140, 180, 0x2c0c01, 0x000000, 0.5, true)
		ui.addTextArea(110, "\n<bv><b>#wr</b></bv>\nmade by Zigwin<g><font size='9'>#0000</font></g>\n\n<a href='event:link_translate'>Translate</a>\n<a href='event:link_issue'>Bug & Suggestion</a>\n", playerName, 450, 250, 140, 120, 0x2c0c01, 0x000000, 0.5, true)
		ui.addTextArea(111, "\n<p align='center'><r>Admins</r></p>", playerName, 220, 250, 220, 30, 0x000000, 0x000000, 0, true)
		ui.addTextArea(109, "<a href='event:close_help'><p align='center'>\nClose</p></a>", playerName, 220, 330, 220, 30, 0x000000, 0x000000, 0, true)
	else
		for id = 100, 112 do
			ui.removeTextArea(id, playerName)
		end
	end
end

--[[ --]]


function leaderboardAdd(playerName, time)
	--if (not leaderboardPlayerList[playerName]) or (time < leaderboardPlayerList[playerName]) then	

	isSaving = not not playerData[playerName]

	-- Add player on first completion
	if not leaderboardPlayerList[playerName] then
		leaderboardPlayerList[playerName] = time

		if isSaving then savePlayerData(playerName) end
	end
	-- Check if new time is better
	if time < leaderboardPlayerList[playerName] then
		leaderboardPlayerList[playerName] = time

		if isSaving then savePlayerData(playerName) end
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
				local displayPlayerName = formatPlayerName(v[1], playerName)
				
				if i > 1 then
					out[i] = "<v>0"..i.."</v><g>-"..displayPlayerName.."</g> <v>"..formatTime(v[2]).."</v>"
				else
					out[i] = "<font color='#EBB741'>01</font><g>-"..displayPlayerName.."</g> <v>"..formatTime(v[2]).."</v>"
				end
			end

			ui.updateTextArea(0, table.concat(out, "\n"), playerName)
		end
	else
		ui.removeTextArea(0, playerName)
	end
end


function eventPlayerWon(playerName, timeElapsed, timeElapsedSinceRespawn) 
	local Data = playerData[playerName]

	tfm.exec.respawnPlayer(playerName)

	-- local ostimeTime = os.time() - Data.timeSinceRespawn
	-- local ostimeTimeEvent = os.time() - Data.timeSinceRespawnEvent

	-- ostimeTime = (ostimeTime - ostimeTime % 10) / 10
	-- ostimeTimeEvent = (ostimeTimeEvent - ostimeTimeEvent % 10) / 10

	--local winMsg = "<rose><b>@"..mapCode.."</b> "..formatPlayerName(playerName, playerName).." <i>"..formatTime(timeElapsedSinceRespawn).."</i></rose>".." ("..formatTime(ostimeTime).."; "..formatTime(ostimeTimeEvent)..")"

	local winMsg = "<rose><b>@"..mapCode.."</b> "..formatPlayerName(playerName, playerName).." <i>"..formatTime(timeElapsedSinceRespawn).."</i></rose>"

	-- Show msg for each monitoring player
	for playerNameMonitor, Data in next, playerData do
		if Data.monitor then
			tfm.exec.chatMessage(winMsg, playerNameMonitor)
		end
	end

	-- Show player's win msg (with monitoring off)
	if not Data.monitor then
		tfm.exec.chatMessage(winMsg, playerName)
	end

	leaderboardAdd(playerName, timeElapsedSinceRespawn)
	updateUi()

	if previousWR and (previousWR > leaderboard[1][2]) then
		tfm.exec.chatMessage("<rose><b>"..formatPlayerName(leaderboard[1][1]).."</b> set a new WR!</rose>")
		particlesDrawFirework()

		previousWR = leaderboard[1][2]
	end
end

--[[ / --]]


--[[ --]]

function eventNewGame()
	if mapCode and (leaderboard ~= {}) then	
		mapsData[mapCode] = table.copy(leaderboard)
	end

	mapCode = tfm.get.room.xmlMapInfo.mapCode
	
	leaderboard = {}
	leaderboardPlayerList = {}

	loadMapLeaderboard()

	if leaderboard[1] and leaderboard[1][2] then
		previousWR = leaderboard[1][2]
	else
		previousWR = nil
	end
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
			--Data.timeSinceRespawn = os.time()
		end
	end

	if isLeaderboardDataLoaded and (saveTimer ~= 0) then
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

ui.addTextArea(2, "<font color='#000000'>60s</font>", nil, 6, 381, 0, 0, 1, 1, 0, true)
ui.addTextArea(1, "<rose>60s<rose>", nil, 5, 380, 0, 0, 1, 1, 0, true)

--[[ / --]]

tfm.exec.disableAutoNewGame()
tfm.exec.disableAutoShaman()
tfm.exec.disableAutoScore()
tfm.exec.disableAfkDeath()
tfm.exec.disablePhysicalConsumables()

do
	tfm.exec.chatMessage("<bv>[Module]</bv> <n>Write !map when leaderboard data is loaded.</n>")

	local pickCategoryText = {}
	for i, v in next, fileCategory do
		pickCategoryText[i] = "<a href='event:load_"..v.."'>"..v.."</a>"
	end

	ui.addTextArea(3, "<b>Choose leaderboard data to load</b>\n<n>"..table.concat(pickCategoryText, "\n").."</n>", admin, 300, 100, 200, 0, 0, 0, 0, true)
end
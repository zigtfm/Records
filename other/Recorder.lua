local images = {
	arrow = {
		green = {
			[0] = "17316073812.png",
			[1] = "173160754e9.png",
			[2] = "17316076ff3.png",
			[3] = "1731607206e.png",
		},
		red = {
			[0] = "173160c8866.png",
			[1] = "173160ca14a.png",
			[2] = "173160cc157.png",
			[3] = "173160c46c3.png",
		}
	}
}

local record = {
	playerName = "",
	moves = {},
}
local movesImages = {}
local playerData = {}

-- Main

function drawArrows(show, playerName)
	if show then
		for id, data in next, record.moves do
			local color =
				(data.down and "green") or
							   "red"

			movesImages[#movesImages + 1] = tfm.exec.addImage(images.arrow[color][data.key], "!1", data.x-8, data.y-8, playerName)
		end
	else
		for _, id in next, movesImages do
			tfm.exec.removeImage(id, playerName)
		end
	end
end	

--

function eventNewPlayer(playerName)
	tfm.exec.respawnPlayer(playerName)

	playerData[playerName] = {
		killTimer = false,
		movesCount = 0,
		moves = {},
	}

	-- Movement keys
	for i = 0, 3 do
		system.bindKeyboard(playerName, i, true , true)
		system.bindKeyboard(playerName, i, false, true)
	end

	-- Del
	system.bindKeyboard(playerName, 46, true, true)

	tfm.exec.lowerSyncDelay(playerName)

	drawArrows(true, playerName)
end


for playerName in next, tfm.get.room.playerList do
	eventNewPlayer(playerName)
end

--[[ --]]


-- Misc functions


function table.copy(t)
	local out = {}
	for i, v in next, t do
		out[i] = v
	end
	return out
end


function formatPlayerName(s)
	return s:sub(0, -6).."<font size='9'><g>"..s:sub(-5).."</g></font>"
end


function formatTime(t)
	local s = t%100
	if s == 0 then
		return tostring((t-s)/100).."s"
	elseif s < 10 then
		return tostring((t-s)/100)..".0"..tostring(s).."s"
	else
		return tostring((t-s)/100).."."..tostring(s).."s"
	end
end


-- Events

function eventKeyboard(playerName, keyCode, down, xPlayerPosition, yPlayerPosition)
	local Data = playerData[playerName]

	if keyCode == 46 then -- Del
		tfm.exec.killPlayer(playerName)
		return
	end

	Data.movesCount = Data.movesCount + 1

	Data.moves[Data.movesCount] = {
		key = keyCode,
		down = down,
		x = xPlayerPosition,
		y = yPlayerPosition,
	}
end


function eventPlayerWon(playerName, timeElapsed, timeElapsedSinceRespawn)
	local Data = playerData[playerName]

	if (not record.time) or (timeElapsedSinceRespawn < record.time) then
		drawArrows(false)

		record = {
			time = timeElapsedSinceRespawn,
			playerName = playerName,
			moves = table.copy(Data.moves),
		}
	
		drawArrows(true)
	end

	Data.killTimer = true
	Data.moves = {}
	Data.movesCount = 0

	tfm.exec.chatMessage(formatTime(timeElapsedSinceRespawn).." | "..formatPlayerName(playerName))
end


function eventPlayerDied(playerName)
	local Data = playerData[playerName]

	Data.killTimer = true
	Data.moves = {}
	Data.movesCount = 0
end


function eventLoop(elapsedTime, remainingTime, isTimer)
	for playerName, Data in next, playerData do
		if Data.killTimer then
			tfm.exec.respawnPlayer(playerName)
			Data.killTimer = false
		end
	end
end


function eventNewGame()	
	drawArrows(false)
	local record = {
		playerName = "",
		moves = {},
	}
end


tfm.exec.disableAutoNewGame()
tfm.exec.disableAutoShaman()
tfm.exec.disableAutoScore()
tfm.exec.disableAfkDeath()
tfm.exec.disablePhysicalConsumables()
tfm.exec.newGame("#17", false)
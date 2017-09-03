--[[
Server Essentials mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights
to this software to the public domain worldwide. This software is
distributed without any warranty.
--]]

players = {}
check_timer = 0
dofile(minetest.get_modpath("serveressentials") .. "/settings.lua")

minetest.register_privilege("broadcast",
		"Player can use /broadcast command")
minetest.register_privilege("top",
		"Player can use the /top command")
minetest.register_privilege("whois",
		"Player can view other player's network information with the /whois command")

if AFK_CHECK then
	minetest.register_privilege("canafk",
		"Player can remain afk without being kicked")
end

minetest.register_chatcommand("broadcast", {
	params = "<text>",
	description = "Broadcast message to server",
	privs = {broadcast = true},
	func = function(player_name, text)
		minetest.chat_send_all(BROADCAST_PREFIX .. " " ..  text)
		return
	end,
})
minetest.register_chatcommand("top", {
	params = "",
	description = "Teleport to topmost block at your current position",
	privs = {top = true},
	func = function(player_name, param)
		curr_pos = minetest.get_player_by_name(player_name):getpos()
		curr_pos["y"] = math.ceil(curr_pos["y"]) + 0.5

		while minetest.get_node(curr_pos)["name"] ~= "ignore" do
			curr_pos["y"] = curr_pos["y"] + 1
		end

		curr_pos["y"] = curr_pos["y"] - 0.5

		while minetest.get_node(curr_pos)["name"] == "air" do
			curr_pos["y"] = curr_pos["y"] - 1
		end
		curr_pos["y"] = curr_pos["y"] + 0.5

		minetest.get_player_by_name(player_name):setpos(curr_pos)
		return
	end
})

minetest.register_chatcommand("killme", {
	params = "",
	description = "Kill yourself",
	func = function(player_name, param)
		minetest.chat_send_player(player_name, "Killing Player " .. player_name)
		minetest.get_player_by_name(player_name):set_hp(0)
		return
	end
})

minetest.register_chatcommand("whois", {
	params = "<player_name>",
	description = "Get network information of player",
	privs = {whois = true},
	func = function(player_name, param)
		if not param or not players[param] then
			minetest.chat_send_player(player_name, "Player " .. param .. " was not found")
			return
		end
		playerInfo = minetest.get_player_information(param)
		minetest.chat_send_player(player_name, param ..
				" - IP address - " .. playerInfo["address"])
		minetest.chat_send_player(player_name, param ..
				" - Avg rtt - " .. playerInfo["avg_rtt"])
		minetest.chat_send_player(player_name, param ..
				" - Connection uptime (seconds) - " .. playerInfo["connection_uptime"])
		return
	end
})

minetest.register_on_joinplayer(function(player)
	players[player:get_player_name()] = {
		last_action = minetest.get_gametime(),
		godmode = false
	}
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)


minetest.register_on_newplayer(function(player)
	if SHOW_FIRST_TIME_JOIN_MSG then
		minetest.after(0.1, function()
			minetest.chat_send_all(player:get_player_name() .. FIRST_TIME_JOIN_MSG)
		end)
	end
end)

minetest.register_on_chat_message(function(name, message)
	if KICK_CHATSPAM and not minetest.check_player_privs(name, {chatspam=true}) and
			string.len(message) > MAX_CHAT_MSG_LENGTH then
		minetest.kick_player(name,
				"Tu as été kick car ton message était trop, c'est pour empêcher le spam du chat/ You were kicked because you sent a chat message too long, this is to prevent chat spamming " ..
				MAX_CHAT_MSG_LENGTH ..
				"caractères/character")
		return true
	end
	return
end)

minetest.register_globalstep(function(dtime)
	-- Loop through all connected players
	for _,player in ipairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()

		-- Only continue if the player has an entry in the players table
		if players[player_name] then

			-- Check for afk players
			if AFK_CHECK and not minetest.check_player_privs(player_name, {canafk=true}) then
				check_timer = check_timer + dtime
				if check_timer > AFK_CHECK_INTERVAL then
					check_timer = 0

					-- Kick player if he/she has been inactive for longer than MAX_INACTIVE_TIME seconds
					if players[player_name]["last_action"] + MAX_AFK_TIME <
							minetest.get_gametime() then
						minetest.kick_player(player_name, "Kicked for inactivity")
					end

					-- Warn player if he/she has less than WARN_TIME seconds to move or be kicked
					if players[player_name]["last_action"] + MAX_AFK_TIME - AFK_WARN_TIME <
							minetest.get_gametime() then
						minetest.chat_send_player(player_name, "Warning, you have " ..
								tostring(players[player_name]["last_action"] + MAX_AFK_TIME - minetest.get_gametime())
								.. " seconds to move or be kicked")
					end
				end

				-- Check if this player is doing an action
				for _,keyPressed in pairs(player:get_player_control()) do
					if keyPressed then
						players[player_name]["last_action"] = minetest.get_gametime()
					end
				end
			end
		end
	end
end)


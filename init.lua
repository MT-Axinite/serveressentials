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

minetest.register_privilege("godmode",
		"Player can use godmode with the /godmode command")
minetest.register_privilege("broadcast",
		"Player can use /broadcast command")
minetest.register_privilege("kill",
		"Player can kill other players with the /kill command")
minetest.register_privilege("whois",
		"Player can view other player's network information with the /whois command")

minetest.register_chatcommand("clearinv", {
	params = "";
	description = "Clear your inventory",
	privs = {},
	func = function(player_name, text)
		local inventory = minetest.get_player_by_name(player_name):get_inventory()
		inventory:set_list("main", {})
	end,
})

minetest.register_chatcommand("broadcast", {
	params = "<text>",
	description = "Broadcast message to server",
	privs = {broadcast = true},
	func = function(player_name, text)
		minetest.chat_send_all(BROADCAST_PREFIX .. " " ..  text)
		return
	end,
})

minetest.register_chatcommand("kill", {
	params = "<player_name>",
	description = "kill specified player",
	privs = {kill = true},
	func = function(player_name, param)

		if #param==0 then
			minetest.chat_send_player(player_name, "You must supply a player name")
		elseif players[param] then
			minetest.chat_send_player(player_name, "Killing player " .. param)
			minetest.get_player_by_name(param):set_hp(0)
		else
			minetest.chat_send_player(player_name, "Player " .. param .. " cannot be found")
		end
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

minetest.register_chatcommand("godmode", {
	params = "",
	description = "Toggle godmode",
	privs = {godmode = true},
	func = function(player_name, param)
		players[player_name]["god_mode"] = not players[player_name]["god_mode"];
		if players[player_name]["god_mode"] then
			minetest.chat_send_player(player_name, "Godmode is now on")
		else
			minetest.chat_send_player(player_name, "Godmode is now off")
		end
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


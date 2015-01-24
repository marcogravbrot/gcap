/*         
[[[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]                                           
   __     ___     __     _____   
 /'_ `\  /'___\ /'__`\  /\ '__`\ 
/\ \L\ \/\ \__//\ \L\.\_\ \ \L\ \
\ \____ \ \____\ \__/.\_\\ \ ,__/
 \/___L\ \/____/\/__/\/_/ \ \ \/ 
   /\____/                 \ \_\ 
   \_/__/                   \/_/ 

   --[[
		By Author.
   ]]--

[[[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]
*/

CAP = CAP or {}

// // // // // // // // // // //

--[=[ Basic Configuration ]=]--

// // // // // // // // // // //
 
CAP.allowance = {
    ["superadmin"] = true,
}
-- Groups whom are allowed to use gcap.
 
CAP.command = "!cap"
-- The command a player with the previligies would type in chat to use gcap.
-- Arguments go like; !cap <player> <quality> (quality is not needed)
 
CAP.defaultquality = 70
-- If you do !cap <player> without the third argument which is the quality, the size specified here will be default.
-- The lower this is, the faster a capture would take to reach the caller.


// // // // // // // // // // // // // //

--[=[ Capture Viewer Configuration ]=]--

// // // // // // // // // // // // // //


// YOU CAN OPEN THE CAPTURE VIEWER BY TYPING
	--[[
		cap_viewer
	]]
// IN YOUR GARRY'S MOD CONSOLE

CAP.directory = "gcap"
-- What the directory should be. This is located in the data folder.
-- From here you can view all captures by changing .txt to .jpeg, but hell,
-- Just use the cap viewer.

CAP.method = "player"
-- This is how the file structure will be for the viewer.
-- Available methods are,

-- date: this will create a new folder for every day including caps taken that day.
-- player: this will create a new folder for every name. The only problem with this is name changing.
-- none: this will save every capture together with the saveformat.

-- Keep in mind that you would want to change the saveformat accordingly to how you organize the folders.

CAP.saveformat = ":timeh: (:victimid:)"

	//CAP.saveformat = ":victim: (:victimid:) - :timeh:"
	// You can uncomment this if you use date as you're organizing. But feel free to edit it to your likings!

-- What the saved capture file is named.
-- Example of default; Author (STEAM_0:0) - 1/1/2015 20:15:26

-- Available tags are,

-- :victim: The victim's name.
-- :victimid: The victim's SteamID.
-- :caller: The caller's name.
-- :callerid: The caller's steamid.
-- :time: Full time, for example 1/1/2015 20:15:06
-- :timed: The date, for example 1/1/2015
-- :timeh: The time of the capture. For example, 20:15:06

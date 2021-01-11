--[[
	Coursy, the little converter that could. (SM5 version)
	Leave this file unmodified! Only change mods.lua!!
	- PullThatLevel (2021)
]]--

local CRSY_DEBUG = false --Debug mode: displays all parsed mods on the upper left
local luaDir = GAMESTATE:GetCurrentSong():GetSongDir() .. "lua/"

--Auxiliary: stable sort implementation
local stable_sort = loadfile(luaDir .. "sort.lua")()

--Coursy relevant variables
local CRSY_modsList       = loadfile(luaDir .. "mods.lua")()
local CRSY_curMod         = 1
local CRSY_lastSecond     = 0
local CRSY_activeMods     = {}
local CRSY_globalOffset   = PREFSMAN:GetPreference("GlobalOffsetSeconds")

--Coursy (SM5) relevant variables
local CRSY_playerOptions        = {} --populated in onCommand
local CRSY_playerOptionsCurrent = {} --populated in onCommand
local CRSY_notefieldRefs  = {} --populated on proxies
local CRSY_notefieldWraps = {} --populated in onCommand
--Coursy (SM5) debug relevant variables / functions
local CRSY_debugTextRef, CRSY_debugNewText = nil, ""
local function CRSY_debugText_clear()  if CRSY_DEBUG then CRSY_debugTextRef:settext(""); CRSY_debugNewText = "" end end
local function CRSY_debugText_update() if CRSY_DEBUG then CRSY_debugTextRef:settext(CRSY_debugNewText)          end end
local function CRSY_debugText_add(str) if CRSY_DEBUG then CRSY_debugNewText = CRSY_debugNewText .. str .. "\n"  end end



--Partial list of SM3.95/openITG mods ( https://sm.heysora.net/itg.txt )
--All lowercase names should map to a PlayerOptions function that executes said mod
local CRSY_possibleMods = {
	alternate = "Alternate", beat = "Beat", blind = "Blind", blink = "Blink", boomerang = "Boomerang",
	boost = "Boost", brake = "Brake", bumpy = "Bumpy", centered = "Centered", c = "CMod", cover = "Cover", cross = "Cross",
	dark = "Dark", distant = "Distant", dizzy = "Dizzy", drunk = "Drunk", expand = "Expand", flip = "Flip",
	hallway = "Hallway", hidden = "Hidden", hiddenoffset = "HiddenOffset", incoming = "Incoming",
	invert = "Invert", mini = "Mini", overhead = "Overhead", randomspeed = "RandomSpeed", randomvanish = "RandomVanish", 
	reverse = "Reverse", space = "Space", split = "Split", stealth = "Stealth", sudden = "Sudden",
	suddenoffset = "SuddenOffset", tipsy = "Tipsy", tornado = "Tornado", twirl = "Twirl", wave = "Wave", x = "XMod"
}
--Mod action handler with default case for generic mods
local CRSY_modActions = setmetatable({
	    CMod = function(plrOpts, int, rate) plrOpts:TimeSpacing(1, rate, true):ScrollBPM(int, rate) end,
	Overhead = function(plrOpts, int, rate) plrOpts:Tilt(0, rate, true):Skew(0, rate) end,
	    XMod = function(plrOpts, int, rate) plrOpts:TimeSpacing(0, rate, true):ScrollSpeed(int, rate) end,
},{
	 __index = function(_,mod) return function(pOpt,int,rate) pOpt[mod](pOpt,int/100,rate) end end
})

--Auxiliary: simulate "clearall" mod command on all PlayerOptions
local function CRSY_doClearAll(allPlrOpts, rate)
	CRSY_debugText_add("<CLEAR ALL>\n---")
	for _,po in pairs(allPlrOpts) do
		for _,m in pairs(CRSY_possibleMods) do CRSY_modActions[m](po, 0, rate or 1) end
		CRSY_modActions["XMod"](po, 1, rate or 1); --xmod should clear to 1
	end
end

--Auxiliary: modstring "modStr" execution on PlayerOption "plrOpt"
local function CRSY_doMods(plrOpt, modStr, debugOut)
	if not plrOpt or modStr == "" then return end
	modStr = ToLower and ToLower(modStr) or modStr:lower()
	
	if debugOut then CRSY_debugText_add(modStr) end
	for rate,intensity,mod in modStr:gsub("( ?)no ", "%10 "):gmatch("(%*?[%d.]*) ?(c?-?[%d.]*)%%? ?(%w*),?") do
		--Rate preprocessing, default rate handling and number conversion
		if #rate > 0 and rate:sub(1,1) ~= "*" then
			rate, intensity, mod = "1", rate, intensity == "c" and intensity .. mod or mod
		end
		rate = rate:gsub("%*?(%d*%.?%d+).*", "%1")
		--Intensity preprocessing, capture potential c captures on it and handle cmods
		if intensity          == "c" then intensity, mod = "100", intensity .. mod end
		if intensity:sub(1,1) == "c" then intensity, mod = intensity:sub(2), "c" end
		
		if CRSY_possibleMods[mod] then
			intensity, rate = tonumber(intensity) or 100, tonumber(rate) or 1
			CRSY_modActions[CRSY_possibleMods[mod]](plrOpt, intensity, rate)
			if debugOut then CRSY_debugText_add("-> " .. rate .. " | " .. intensity .. " | " .. mod) end
		elseif mod ~= "" then
			SCREENMAN:SystemMessage("Unknown mod: " .. mod)
		end
	end
end



--Auxiliary: active mod insertion
local function CRSY_insertActive(mod, delta)
	CRSY_activeMods[#CRSY_activeMods + 1] = {
		mod = mod[4],
		len = mod[2] - (mod[3] == "E" and mod[1] or 0) + delta
	}
end

return Def.ActorFrame {
	Def.Actor { --Dummy actor
		InitCommand = function(self) self:sleep(9999) end
	},
	
	Def.BitmapText { --Debug text, if active
		Font = "Common normal",
		Text = "<DEBUG BITMAPTEXT>",
		InitCommand = function(self)
			CRSY_debugTextRef = self;
			self:x(20); self:y(20); self:zoom(0.5); self:align(0,0)
			if not CRSY_DEBUG then self:visible(false); end
		end
	},
	
	--Notefield proxies for widescreen FOV (thanks Ky_Dash and Mr. ThatKid!)
	Def.ActorFrame { --P1 notefield proxy frame
		OnCommand = function(self)
			--FOV for widescreen support (thanks Ky_Dash!) and "correct" vanishpoint for Z-mods (thanks SM5.0...)
			self:fov(360 / math.pi * math.atan(math.tan(math.pi * (1 / (360 / 45))) * SCREEN_WIDTH / SCREEN_HEIGHT * 0.75))
			local curP = SCREENMAN:GetTopScreen():GetChild("PlayerP1")
			if curP then self:vanishpoint(curP:GetX(), curP:GetY()) end
		end,
		Def.ActorProxy { --P1 notefield proxy
			InitCommand = function(self)
				CRSY_notefieldRefs[1] = self
				self:zoom(SCREEN_HEIGHT/480) --For SM5.1+ scaling
			end,
		},
	},
	Def.ActorFrame { --P2 notefield proxy frame
		OnCommand = function(self)
			--FOV for widescreen support (thanks Ky_Dash!) and "correct" vanishpoint for Z-mods (thanks SM5.0...)
			self:fov(360 / math.pi * math.atan(math.tan(math.pi * (1 / (360 / 45))) * SCREEN_WIDTH / SCREEN_HEIGHT * 0.75))
			local curP = SCREENMAN:GetTopScreen():GetChild("PlayerP2")
			if curP then self:vanishpoint(curP:GetX(), curP:GetY()) end
		end,
		Def.ActorProxy { --P2 notefield proxy
			InitCommand = function(self)
				CRSY_notefieldRefs[2] = self
				self:zoom(SCREEN_HEIGHT/480) --For SM5.1+ scaling
			end,
		},
	},
	
	Def.ActorFrame { --The engine itself!
		OnCommand = function(self) --Initial setup
			self:visible(false)
			
			for pn = 1,2 do
				local curP      = SCREENMAN:GetTopScreen():GetChild("PlayerP" .. pn)
				local curPstate = GAMESTATE:GetPlayerState("PlayerNumber_P" .. pn)
				--Proxy for FOV support (thanks Mr. ThatKid!)
				if curP then
					local curPnotes = curP:GetChild("NoteField")
					CRSY_notefieldRefs[pn]:SetTarget(curPnotes):x(curP:GetX()):y(curP:GetY())
					curPnotes:visible(false) --Hiding the player breaks perspective mods
					--For counteracting mini (thanks Mr. ThatKid!)
					if curPnotes:GetNumWrapperStates() == 0 then
						CRSY_notefieldWraps[pn] = curPnotes:AddWrapperState()
					else
						CRSY_notefieldWraps[pn] = curPnotes:GetWrapperState(1)
					end
				else
					CRSY_notefieldRefs[pn]:visible(false)
				end
				--PlayerOptions retrieval on Song and Current context
				if curPstate then
					CRSY_playerOptions[pn] = curPstate:GetPlayerOptions("ModsLevel_Song")
					CRSY_playerOptionsCurrent[pn] = curPstate:GetPlayerOptions("ModsLevel_Current")
				end
			end
			
			self:queuecommand("Start")
		end,
		StartCommand = function(self) --Further "beat 0" setup and the engine!
			--Clear all the mods, potentially transfered from the previous song
			CRSY_doClearAll(CRSY_playerOptions, 1024)
			
			--Stable-sort all the mods
			stable_sort(CRSY_modsList, function(x,y) return x[1] < y[1] end)
			
			--Prepopulation of activeMods to avoid bottlenecks on edit mode
			local curTime = CRSY_globalOffset + GAMESTATE:GetCurMusicSeconds()
			for b,m in ipairs(CRSY_modsList) do
				if curTime >= m[1] then
					CRSY_insertActive(m, m[1])
					CRSY_curMod = b+1
				end
			end
			
			--Engage the update loop and the main engine!
			self:SetUpdateFunction(function(self)
				CRSY_debugText_clear()
				
				local curTime  = CRSY_globalOffset + GAMESTATE:GetCurMusicSeconds()
				local curDelta = curTime - CRSY_lastSecond
				
				--Add new mods if needed
				while CRSY_modsList[CRSY_curMod] and curTime >= CRSY_modsList[CRSY_curMod][1] do
					CRSY_insertActive(CRSY_modsList[CRSY_curMod], curDelta)
					CRSY_curMod = CRSY_curMod + 1
				end
				--Process which mods should be kept
				local insertMods, activeDeletes = {}, {}
				for i = 1,#CRSY_activeMods do
					local curMod = CRSY_activeMods[i]
					curMod.len = curMod.len - curDelta
					if curMod.len > 0 then
						insertMods[#insertMods + 1] = curMod.mod
					else
						activeDeletes[i] = true
					end
				end
				--Delete no longer necessary mods
				for i = #CRSY_activeMods,1,-1 do
					if activeDeletes[i] then table.remove(CRSY_activeMods, i) end
				end
				--Execute the remaining mods!
				CRSY_doClearAll(CRSY_playerOptions)
				for _,m in ipairs(insertMods) do
					for pn = 1,2 do
						CRSY_doMods(CRSY_playerOptions[pn], m, pn == 1 --[[only debugtext p1]])
					end
					CRSY_debugText_add("---")
				end
				
				--Do zoomz in order to counteract mini, if any (thanks Mr. ThatKid!)
				for pn = 1,2 do
					local curWrap = CRSY_notefieldWraps[pn]
					if curWrap then curWrap:zoomz(1/(1-0.5*CRSY_playerOptionsCurrent[pn]:Mini())) end
				end
				
				CRSY_debugText_update()
				CRSY_lastSecond = curTime
			end)
		end,
	}
}
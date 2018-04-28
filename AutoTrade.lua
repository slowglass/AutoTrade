Slowglass = {}
Slowglass.AutoTrade = {}

local AutoTrade = Slowglass.AutoTrade
AutoTrade.name = 'AutoTrade'
AutoTrade.author = 'Slowglass'
AutoTrade.version = '0.1.0'
AutoTrade.defaults = {}
AutoTrade.defaults.allow = {}
AutoTrade.defaults.defaultTrader = ""
AutoTrade.autoClose = false

local Colour = {
	['Grey'] = "c707070",
	['White'] = "cC0C0C0",
	['Green'] = "c064F0D",
	['Blue'] = "c0000CC",
	['Purple'] = "c660066",
	['Orange'] = "cCC6600",
	['Red'] = "c660000"
}

local function Col(c, msg) return "|"..Colour[c]..msg.."|r" end
local function Announce(msg, who)
   CHAT_SYSTEM:AddMessage(Col('Purple',msg) .. Col('Green',who))
end

function AutoTrade.CmdList(s,n)
	local key, ignore
	local str = ""
  for key, ignore in pairs(s.allow) do str = str..", "..key end
  ignore, str = str:match("(..)(.*)")
	Announce("Accept trades invites from ", str)
	Announce("Default trader is ",s.defaultTrader)
end

function AutoTrade.CmdClear(s,n)
	Announce("No longer have a default trader set","")
	Announce("No longer accepting any automatic trades","")
  s.defaultTrader = ""
	s.allow = {}
end

function AutoTrade.CmdDefault(s,n)
	Announce("Default trader is now ", n)
	s.defaultTrader = n
end

function AutoTrade.CmdAccept(s,n)
	Announce("Now accepting Trade from ",n)
	s.allow[n] = true
end

function AutoTrade.CmdReject(s,n)
	Announce("No longer accepting Trade from ",n)
		s.allow[n] = nil
end

function AutoTrade.CmdWith(s,n)
	Announce("Sending trade invite to ",n)
  TradeInviteByName(n)
end

function AutoTrade.CmdHelp(s,n)
	Announce("Trade supported sub-commands ", "")
	Announce("    accept <player> - ", "Add player to list of people from whom we automatically accept trades")
	Announce("    clear - ", "Clear accept and defaults")
	Announce("    default <player> - ", "Set player we will trade with if no sub command is specified")
	Announce("    list - ", "List current settings")
	Announce("    reject  <player> - ", "Remove player from list of people from whom we automatically accept trades")
	Announce("    with <player> - ", "Start trade with player")
	Announce("    <player> - ", "Start trade with player")
  TradeInviteByName(n)
end

local Commands = { 
	["list"]=AutoTrade.CmdList, 
	["clear"]=AutoTrade.CmdClear,
	["default"]=AutoTrade.CmdDefault,
	["accept"]=AutoTrade.CmdAccept,
	["reject"]=AutoTrade.CmdReject,
	["with"]=AutoTrade.CmdWith,
	["help"]=AutoTrade.CmdHelp,
}

local function Trade(text)
	local cmd, name
	cmd, name = text:match("(%w+)(.*)")
	if name == nil then name = "" else name = name:match "^%s*(.-)%s*$" end
	if cmd == nil or cmd == "" then 
		name = AutoTrade.settings.defaultTrader
		cmd = "with"
	end
	if Commands[cmd] == nil then
		return Commands["with"](AutoTrade.settings,text)
	else
		return Commands[cmd](AutoTrade.settings,name)
	end
	Announce("","Unknown Command : /trade "..text)
end

function AutoTrade:Allow(who)
	if self.settings.allow[who] then return true else return false end
end


local function AutoAcceptTrade(num, who, c)
  who = zo_strformat("<<1>>", who)
  if AutoTrade:Allow(who) then
  	d("Accepting Trade from "..who)
    TradeInviteAccept()
		AutoTrade.autoClose = true
  end
end

local function FinishTrade(who, state)
  if AutoTrade.autoClose then
		TradeAccept()
	end
	AutoTrade.autoClose = false
end



function AutoTrade:CreateOptionsMenu()
	local LibSettings = LibStub('LibSettings-0.1')
	local Settings = LibSettings.new("AT_OP", self.langBundle, "AutoTrade_Settings", self.defaults)
	self.settings = Settings.settings
	local desc = "";
	desc = desc .."Trade supported sub-commands of slash command /trade\n";
	desc = desc .."    "..Col('Purple', "accept ")..Col('Blue',"<player>").." - Automatically accept trades from player\n";
	desc = desc .."    "..Col('Purple', "default ")..Col('Blue',"<player>").." - Set player we will trade with if no sub command is specified\n";
	desc = desc .."    "..Col('Purple', "list ").." - List current settings\n";
	desc = desc .."    "..Col('Purple', "reject ")..Col('Blue',"<player>").." - Do not automatically accept trades from player\n";
	desc = desc .."    "..Col('Purple', "with ")..Col('Blue',"<player>").." - Start trade with player\n";
	desc = desc .."    "..Col('Blue',"<player>").." - Start trade with player\n";
	Settings:desc(self.name, self.version, self.author, desc)
	Settings:CreateOptionsMenu()
end

local function OnLoad(eventCode, addOnName)
  if(addOnName ~= AutoTrade.name) then return end
	AutoTrade:CreateOptionsMenu()
  EVENT_MANAGER:UnregisterForEvent(AutoTrade.name,EVENT_ADD_ON_LOADED)
  EVENT_MANAGER:RegisterForEvent(AutoTrade.name , EVENT_TRADE_INVITE_CONSIDERING, AutoAcceptTrade)
  EVENT_MANAGER:RegisterForEvent(AutoTrade.name , EVENT_TRADE_CONFIRMATION_CHANGED, FinishTrade)
  SLASH_COMMANDS["/trade"] = Trade
end

EVENT_MANAGER:RegisterForEvent(AutoTrade.name, EVENT_ADD_ON_LOADED, OnLoad)


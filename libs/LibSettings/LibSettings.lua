local LIB_IDENTIFIER = "LibSettings-0.1"
local Settings = LibStub:NewLibrary(LIB_IDENTIFIER, 1)

if not Settings then
    return -- already loaded and no upgrade necessary
end
	 
Settings.__index = Settings

local function CleanSettings(settings, defaultSettings)
	for key in pairs(settings) do
		if (defaultSettings[key] == nil) then
			settings[key] = nil
    	end
    end
end

function Settings.new(prefix, langBundle, settingsFile, defaults)
	local obj = {}
	obj.prefix = prefix
	obj.langBundle = langBundle
	obj.settings = {}
	obj.defaults = defaults
    obj.optionsTable = { }
    obj.index = 1
	obj.settings = ZO_SavedVars:New(settingsFile, 1, nil, defaults)
	obj.choices = {}
	CleanSettings(obj.settings, obj.defaults)
	return setmetatable(obj, Settings)
end


function Settings:T(...)
    local arg={...}
	local s = self.prefix
    for i,v in ipairs(arg) do
		 s = s.."_"..v
	end
	return self.langBundle[s]
end

function Settings:desc(name, version, author, desc)
    self.name = name
    self.version = version
    self.author = author
	self.optionsTable[self.index] = { type = "description", text = desc }
    self.index = self.index + 1
end

function Settings:header(key)
	self.optionsTable[self.index] =  { type = "header", name = self:T(key) }
    self.index = self.index + 1
end

function Settings:checkbox(key)
    self.optionsTable[self.index] = { 
		type = "checkbox", name = self:T(key, "LABEL"),
		tooltip = self:T(key, "TOOLTIP"),
		getFunc = function() return self.settings[key]; end,
		setFunc = function(v) self.settings[key]=v; end,
		default = self.defaults[key]
	}
    self.index = self.index + 1
end

function Settings:setFromDropdown(key, value)
	local v = self.choices[key][value]
	self.settings[key] = v
end

function Settings:getForDropdown(key)
	local v = self.settings[key]
	return self:T(v, "CHOICE")
end

function Settings:dropdown(key, choices)
	self.choices[key] = {}
	local i, v
    local choiceLabels = {	}
	for i, v in ipairs(choices) do
	  local s = self:T(v, "CHOICE")
	  choiceLabels[i] = s
	  self.choices[key][s] = v
    end
    self.optionsTable[self.index] = { 
		type = "dropdown", name = self:T(key, "LABEL"),
		tooltipX = self:T(key, "TOOLTIP"),
		tooltip = tt,
		choices = choiceLabels,
		sort = "name-down",
		getFunc = function() return self:getForDropdown(key); end,
		setFunc = function(v) self:setFromDropdown(key,v); end,
		default = self.defaults[key]
	}
    self.index = self.index + 1
end

function Settings:CreateOptionsMenu()
	local LAM = LibStub('LibAddonMenu-2.0')
	local panelData = 
	{
		type = "panel",
		name = self.name,
		author = self.author,
		version = self.version,
		registerForRefresh = true,
		registerForDefaults = true,
	}
	
	LAM:RegisterAddonPanel(self.name.."_LAM", panelData)
	LAM:RegisterOptionControls(self.name.."_LAM", self.optionsTable)
end

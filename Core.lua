LevelUpAnnouncer = LibStub("AceAddon-3.0"):NewAddon("LevelUpAnnouncer", "AceConsole-3.0", "AceEvent-3.0")

local version = GetAddOnMetadata("LevelUpAnnouncer", "Version")
local author = GetAddOnMetadata("LevelUpAnnouncer", "Author")

local defaults = {
    profile = {
        playSound = true,
        chatAnnounce = true,
        chatPercAnnounce = false,
        reversePerc = false,
        dingFormat = "DING! LEVEL {LEVEL}!",
        percFormat = "{PERCENTAGE}% INTO LEVEL {LEVEL}!",
        reversePercFormat = "{PERCENTAGE}% UNTIL LEVEL {NEXTLEVEL}!",
        messageModeString = "YELL",
        soundID = 24297
    }
}

local options = {
    type = "group",
    args = {
        LUPHeader = {
            name = "Level Up Announcer - by " .. author .. " - version " .. version,
            type = "header"
        },
        LUPToggles = {
            order = 1,
            name = "Toggles",
            type = "group",
            args = {
                playSound = {
                    order = 1,
                    name = "Enable Sound",
                    desc = "Play a sound each time you level up",
                    type = "toggle",
                    set = function(_, value) LevelUpAnnouncer.db.profile.playSound = value end,
                    get = function() return LevelUpAnnouncer.db.profile.playSound end
                },
                chatAnnounce = {
                    order = 2,
                    name = "Chat Announce",
                    desc = "Announces in chat when you level up",
                    type = "toggle",
                    set = function(_, value) LevelUpAnnouncer.db.profile.chatAnnounce = value end,
                    get = function() return LevelUpAnnouncer.db.profile.chatAnnounce end
                },
                chatPercAnnounce = {
                    order = 3,
                    name = "Percentage Announce",
                    desc = "Announces in chat when you pass a percentage barrier (25%, 50% and 75%)",
                    type = "toggle",
                    set = function(_, value) LevelUpAnnouncer.db.profile.chatPercAnnounce = value end,
                    get = function() return LevelUpAnnouncer.db.profile.chatPercAnnounce end
                },
                reversePerc = {
                    order = 4,
                    name = "Reverse Percentages",
                    desc = "Reverses the percentages in percentage announce mode (announces 75% when at 25%, 50% at 50% and 25% at 75%)",
                    type = "toggle",
                    set = function(_, value) LevelUpAnnouncer.db.profile.reversePerc = value end,
                    get = function() return LevelUpAnnouncer.db.profile.reversePerc end
                }
            }
        },
        LUPFormats = {
            order = 2,
            name = "Formats",
            desc = "Formats for annoucing to chat",
            type = "group",
            args = {
                dingFormat = {
                    order = 1,
                    name = "Level Up Announce Format",
                    desc = "The format used when you level up",
                    type = "input",
                    set = function(_, value) LevelUpAnnouncer.db.profile.dingFormat = value end,
                    get = function() return LevelUpAnnouncer.db.profile.dingFormat end
                },
                percFormat = {
                    order = 2,
                    name = "Percentage Announce Format",
                    desc = "The format used when you pass a percentage barrier (25%, 50% and 75%)",
                    type = "input",
                    set = function(_, value) LevelUpAnnouncer.db.profile.percFormat = value end,
                    get = function() return LevelUpAnnouncer.db.profile.percFormat end
                },
                reversePercFormat = {
                    order = 3,
                    name = "Reversed Percentage Announce Format",
                    desc = "The format used when you pass a percentage barrier in reverse mode (75%, 50% and 25%)",
                    type = "input",
                    set = function(_, value) LevelUpAnnouncer.db.profile.reversePercFormat = value end,
                    get = function() return LevelUpAnnouncer.db.profile.reversePercFormat end
                },
                placeholderHelp = {
                    order = 4,
                    name = "Available placeholders: {PERCENTAGE}, {LEVEL} and {NEXTLEVEL}",
                    type = "description"
                }
            }
        },
        LUPMisc = {
            order = 3,
            name = "Misc",
            type = "group",
            args = {
                soundID = {
                    order = 1,
                    name = "Sound ID",
                    desc = "The ID of the sound played when you level up (only applicable when sound is enabled)",
                    type = "input",
                    pattern = "(%d)",
                    usage = "Only numbers are allowed",
                    set = function(_, value) LevelUpAnnouncer.db.profile.soundID = tonumber(value) end,
                    get = function() return tostring(LevelUpAnnouncer.db.profile.soundID) end
                },
                messageMode = {
                    order = 2,
                    name = "Message Mode",
                    desc = "Modes:\nSAY\nYELL\nPARTY\nINSTANCE_CHAT\nRAID\nRAID_WARNING\nGUILD\nOFFICER\nEMOTE\nCHANNEL.X (So for channel 1 type: \"CHANNEL.1\")",
                    type = "input",
                    set = function(_, value) LevelUpAnnouncer.db.profile.messageModeString = value end,
                    get = function() return LevelUpAnnouncer.db.profile.messageModeString end
                },
                testSound = {
                    order = 3,
                    name = "Test Sound",
                    desc = "Click this to test the selected sound",
                    type = "execute",
                    func = function() PlaySound(LevelUpAnnouncer.db.profile.soundID) end
                }
            }
        }
    }
}

local split = function(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    local i = 1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

local sendToChat = function(message)
    local str = LevelUpAnnouncer.db.profile.messageModeString
    local t = split(str, ".")
    local channel
    if #t > 1 then channel = t[2] end
    local mode = t[1]
    SendChatMessage(message, mode, nil, channel)
end

local replaceFormats = function(strFormat, perc, level)
    strFormat = strFormat:gsub("({PERCENTAGE})", tostring(perc))
    strFormat = strFormat:gsub("({LEVEL})", tostring(level))
    strFormat = strFormat:gsub("({NEXTLEVEL})", tostring(level + 1))
    return strFormat
end

function LevelUpAnnouncer:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("LevelUpAnnouncerDB", defaults, true)   
    
    self.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("LevelUpAnnouncer", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LevelUpAnnouncer", "LevelUpAnnouncer")
    LibStub("AceConfig-3.0"):RegisterOptionsTable("LevelUpAnnouncerProfiles", self.profiles)
    self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LevelUpAnnouncerProfiles", "Profiles", "LevelUpAnnouncer")

    LevelUpAnnouncer:RegisterEvent("PLAYER_LOGIN")
    LevelUpAnnouncer:RegisterEvent("PLAYER_LEVEL_UP")
    LevelUpAnnouncer:RegisterEvent("PLAYER_XP_UPDATE")
    
    local command = function() LibStub("AceConfigDialog-3.0"):Open("LevelUpAnnouncer") end
    LevelUpAnnouncer:RegisterChatCommand("levelup", command)
    LevelUpAnnouncer:RegisterChatCommand("lvlup", command)
end

function LevelUpAnnouncer:PLAYER_LOGIN()
    self.xpPct = UnitXP("player")/UnitXPMax("player")
    self.tmpPercIndex = math.floor(self.xpPct * 4)
    self.curLevel = UnitLevel("player")

    print("|cff0066FFLevel Up Announcer|r, by |cff0066FF" .. author .. "|r, version |cff0066FF" ..version .. "|r loaded, /" .. "|cff0066FFlevelup|r for settings.")
end

function LevelUpAnnouncer:PLAYER_LEVEL_UP()
    self.tmpPercIndex = 0
    self.curLevel = self.curLevel + 1
    if self.db.profile.playSound then
        PlaySound(self.db.profile.soundID)
    end
    if self.db.profile.chatAnnounce then
        sendToChat(replaceFormats(self.db.profile.dingFormat, 0, self.curLevel))
    end
end

function LevelUpAnnouncer:PLAYER_XP_UPDATE()
    self.xpPct = UnitXP("player")/UnitXPMax("player")
    if not self.db.profile.chatPercAnnounce then return end
    local stc = function(p) return sendToChat(replaceFormats(self.db.profile.percFormat, p, self.curLevel)) end
    if self.db.profile.reversePerc then stc = function(p) return sendToChat(replaceFormats(self.db.profile.reversePercFormat, 100 - p, self.curLevel)) end end
    if self.xpPct>=0.25 and self.tmpPercIndex<1 then
        stc(25)
    end
    if self.xpPct>=0.5 and self.tmpPercIndex<2 then
        stc(50)
    end
    if self.xpPct>=0.75 and self.tmpPercIndex<3 then
        stc(75)
    end
    self.tmpPercIndex = math.floor(self.xpPct * 4)
end

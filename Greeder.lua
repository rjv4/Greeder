-- ============================================================================
-- 1. ADDON INITIALIZATION & SAVED VARIABLES
-- ============================================================================
local function OnPlayerLogin(self, event)
    if GreederDB == nil then GreederDB = {} end
    if GreederDB.enabled == nil then GreederDB.enabled = true end
    if GreederDB.debugMode == nil then GreederDB.debugMode = false end
    local status = GreederDB.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"
    print(string.format("Greeder loaded and %s. Type /greeder for options.", status))
    self:UnregisterEvent("PLAYER_LOGIN")
end
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", OnPlayerLogin)



-- ============================================================================
-- 2. SLASH COMMAND HANDLER
-- ============================================================================
local function SlashCmdHandler(msg, editbox)
    local command = strlower(msg)
    if command == "on" then
        GreederDB.enabled = true
        print("Greeder is now |cff00ff00ON|r.")
    elseif command == "off" then
        GreederDB.enabled = false
        print("Greeder is now |cffff0000OFF|r.")
    elseif command == "status" then
        local status = GreederDB.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"
        local debugStatus = GreederDB.debugMode and "|cff00ff00ON|r" or "|cffff0000OFF|r"
        print("Greeder: " .. status)
        print("Greeder debug mode: " .. debugStatus)
    elseif command == "debug" then
        GreederDB.debugMode = not GreederDB.debugMode
        if GreederDB.debugMode then
            print("Greeder: Debug mode is now |cff00ff00ON|r.")
        else
            print("Greeder: Debug mode is now |cffff0000OFF|r.")
        end
    else
        print("--- Greeder Options ---")
        print("/greeder on: Enables the addon.")
        print("/greeder off: Disables the addon.")
        print("/greeder status: Shows the current status.")
        print("/greeder debug: Toggles debug message display.")
    end
end
SLASH_Greeder1 = "/Greeder"; SLASH_Greeder2 = "/greeder"
SlashCmdList["Greeder"] = SlashCmdHandler



-- ============================================================================
-- 3. CORE ADDON LOGIC
-- ============================================================================
local eventFrame = CreateFrame("Frame")
local playerClass = select(2, UnitClass("player"))

local classArmorGreedlist = {
    -- Cloth
    ["MAGE"] = { "Leather", "Mail", "Plate" },
    ["WARLOCK"] = { "Leather", "Mail", "Plate" },
    ["PRIEST"] = { "Leather", "Mail", "Plate" },

    -- Leather
    ["DRUID"] = { "Cloth", "Mail", "Plate" },
    ["ROGUE"] = { "Cloth", "Mail", "Plate" },
    ["MONK"] = { "Cloth", "Mail", "Plate" },

    -- Mail
    ["HUNTER"] = { "Cloth", "Leather", "Plate" },
    ["SHAMAN"] = { "Cloth", "Leather", "Plate" },

    -- Plate
    ["WARRIOR"] = { "Cloth", "Leather", "Mail" },
    ["PALADIN"] = { "Cloth", "Leather", "Mail" },
    ["DEATHKNIGHT"] = { "Cloth", "Leather", "Mail" }
}

-- Helper function to check if an item's subtype is in a given class's whitelist.
local function isItemInGreedlist(itemSubType, whitelist)
    if not whitelist then return false end
    for i, whitelistedType in ipairs(whitelist) do
        if itemSubType == whitelistedType then
            return true
        end
    end
    return false
end

local function ProcessLootItem(itemLink, rollID)
    local _, _, _, _, _, itemType, itemSubType, _, equipLocID, _, _, _, _, bindType = GetItemInfo(itemLink)
    local isBoP = (bindType == 1)

    -- General equipment roll check

    local id = select(1, GetItemInfoInstant(itemLink))
	
    local isUsableItem = C_PlayerInfo.CanUseItem(tostring(id))
    local isEquippable = IsEquippableItem(id)
    
    local unusableGear = (isEquippable and not isUsableItem)

    -- Equipment roll check end



    -- Armor roll check start

    itemSubType = tostring(itemSubType)

    local playerWhitelist = classArmorGreedlist[playerClass]
    local isGreedlisted = isItemInGreedlist(itemSubType, playerWhitelist)

    -- Don't roll on back slot, as they're always cloth which will create false positives
    local isNotBackSlot = (equipLocID ~= "INVTYPE_CLOAK")

    local unusableArmorType = (isGreedlisted and isNotBackSlot)

    -- Armor roll check end



    local shouldRoll = isBoP and (unusableGear or unusableArmorType)

    -- Print details when debug is enabled
    if GreederDB.debugMode then
        print("|cffffd700--- Greeder: Loot Roll Debug ---|r")
        print("Item:", itemLink)
        print("|cffffff00-----------------------------------|r")
        print(string.format("Is BoP: %s", tostring(isBoP)))
        print(string.format("Is equipment: %s", tostring(isEquippable)))
        print(string.format("Is usable by this character: %s", tostring(isUsableItem)))
        print(string.format("Is non-class armor type: %s", tostring(isGreedlisted)))
        print(string.format("Is non-back slot: %s (EquipLoc: %s)", tostring(isNotBackSlot), tostring(equipLocID)))
        print("|cffffff00-----------------------------------|r")
        if shouldRoll then
            print("Result: |cff00ff00PASS|r. Conditions met, will attempt to roll Greed.")
        else
            print("Result: |cffff0000FAIL|r. Conditions not met, no action taken.")
        end
        print("|cffffd700-----------------------------------|r")
    end

    if shouldRoll then
        print("Greeder: Automatically rolling Greed on " .. itemLink)
        RollOnLoot(rollID, 2)
    end
end

local function OnLootRoll(self, event, rollID)
    if not GreederDB.enabled then
        return
    end

    local itemLink = GetLootRollItemLink(rollID)
    if not itemLink then return end

    local item = Item:CreateFromItemLink(itemLink)
    item:ContinueOnItemLoad(function()
        ProcessLootItem(itemLink, rollID)
    end)
end

eventFrame:RegisterEvent("START_LOOT_ROLL")
eventFrame:SetScript("OnEvent", OnLootRoll)

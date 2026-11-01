do
Atr_core = CreateFrame("Frame", "Atr_core", UIParent)
Atr_core.TimeSinceLastUpdate = 0

Atr_core:SetScript("OnUpdate", function()
    Atr_OnUpdate(Atr_core, arg1)
end)

Atr_core:SetScript("OnEvent", function()
    Atr_EventHandler()
end)

Atr_RegisterEvents(Atr_core)
end

---------------------------------------

do
local function CreateAuctionatorDialog(name, width, height, strata)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetWidth(width)
    f:SetHeight(height)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 290, -190)
    f:SetFrameStrata(strata)
    f:EnableMouse(true)
    f:SetMovable(false)
    f:SetBackdrop({
        bgFile = "Interface\\MERCHANTFRAME\\UI-BuyBack-TopLeft",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 256, edgeSize = 32,
        insets = { left = 2, right = 0, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0.3, 0.3, 0.7)
    f:Hide()
    return f
end

---------------------------------------

local errorFrame = CreateAuctionatorDialog("Atr_Error_Frame", 340, 160, "FULLSCREEN_DIALOG")
errorFrame:SetScript("OnShow", function()
    if this.withMask and Atr_Mask then Atr_Mask:Show() end
end)
errorFrame:SetScript("OnHide", function()
    if this.withMask and Atr_Mask then
        Atr_Mask:Hide()
        this.withMask = nil
    end
end)

---------------------------------------

local errorText = errorFrame:CreateFontString("Atr_Error_Text", "BACKGROUND", "GameFontNormal")
errorText:SetPoint("CENTER", errorFrame, "CENTER", 0, 20)

local errorOkay = CreateFrame("Button", nil, errorFrame, "UIPanelButtonTemplate")
errorOkay:SetWidth(60); errorOkay:SetHeight(22)
errorOkay:SetPoint("BOTTOM", errorFrame, "BOTTOM", 0, 20)
Atr_LT(errorOkay, "OKAY")
errorOkay:SetScript("OnClick", function() Atr_Error_Frame:Hide() end)

local confirmFrame = CreateAuctionatorDialog("Atr_Confirm_Frame", 300, 150, "DIALOG")
confirmFrame:SetScript("OnShow", function()
    if Atr_Mask then Atr_Mask:Show() end end)

confirmFrame:SetScript("OnHide", function()
    if Atr_Mask then Atr_Mask:Hide() end end)

local confirmText = confirmFrame:CreateFontString("Atr_Confirm_Text", "BACKGROUND", "GameFontNormal")
confirmText:SetPoint("CENTER", confirmFrame, "CENTER", 0, 20)
confirmText:SetSpacing(3)

local confirmCancel = CreateFrame("Button", "Atr_Confirm_Cancel", confirmFrame, "UIPanelButtonTemplate")
confirmCancel:SetWidth(60); confirmCancel:SetHeight(22)
confirmCancel:SetPoint("BOTTOMRIGHT", confirmFrame, "BOTTOMRIGHT", -30, 20)
Atr_LT(confirmCancel, "CANCEL")
confirmCancel:SetScript("OnClick", function() Atr_Confirm_No() end)

local confirmOkay = CreateFrame("Button", nil, confirmFrame, "UIPanelButtonTemplate")
confirmOkay:SetWidth(60); confirmOkay:SetHeight(22)
confirmOkay:SetPoint("RIGHT", confirmCancel, "LEFT", -10, 0)
Atr_LT(confirmOkay, "OKAY")
confirmOkay:SetScript("OnClick", function() Atr_Confirm_Yes() end)
end

---------------------------------------

do
local function Atr_CreateLegacyDialog(name, width, height, x, y, strata)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetWidth(width)
    f:SetHeight(height)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    f:SetFrameStrata(strata)
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetBackdrop({
        bgFile = "Interface\\CharacterFrame\\UI-Party-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    f:SetScript("OnShow", function()
        if AuctionFrame and AuctionFrame:IsShown() and Atr_Mask then Atr_Mask:Show() end end)
    f:SetScript("OnHide", function()
        if AuctionFrame and AuctionFrame:IsShown() and Atr_Mask then Atr_Mask:Hide() end end)
    f:Hide()
    return f
end

---------------------------------------

local check = Atr_CreateLegacyDialog("Atr_CheckActives_Frame", 320, 190, 70, -300, "FULLSCREEN_DIALOG")
local checkText = check:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
checkText:SetWidth(310)
checkText:SetHeight(50)
checkText:SetPoint("TOPLEFT", check, "TOPLEFT", 5, -34)
Atr_LT(checkText, "Automatically cancel all of your auctions|n|nthat are not the lowest priced?")
---------------------------------------

local yes = CreateFrame("Button", nil, check, "UIPanelButtonTemplate")
yes:SetWidth(210); yes:SetHeight(22)
yes:SetPoint("BOTTOM", check, "BOTTOM", 0, 65)
Atr_LT(yes, "Yes, cancel them")
yes:SetScript("OnClick", function() Atr_Cancel_Undercuts_OnClick() end)

local no = CreateFrame("Button", nil, check, "UIPanelButtonTemplate")
no:SetWidth(210); no:SetHeight(22)
no:SetPoint("BOTTOM", check, "BOTTOM", 0, 30)
Atr_LT(no, "No, leave them")
no:SetScript("OnClick", function() Atr_CheckActives_Frame:Hide() end)

---------------------------------------

local cancel = Atr_CreateLegacyDialog("Atr_CancelAuction_Confirm_Frame", 340, 115, 40, -390, "DIALOG")
local cancelText = cancel:CreateFontString("Atr_CancelAuction_Confirm_Frame_text", "BACKGROUND", "GameFontNormal")
cancelText:SetPoint("CENTER", cancel, "CENTER", 0, 10)
Atr_LT(cancelText, "Really cancel?")
local leave = CreateFrame("Button", nil, cancel, "UIPanelButtonTemplate")
leave:SetWidth(60); leave:SetHeight(22)
leave:SetPoint("BOTTOMRIGHT", cancel, "BOTTOMRIGHT", -50, 16)
Atr_LT(leave, "Leave it")
leave:SetScript("OnClick", function() Atr_CancelUndercut_Confirm(false) end)

local doCancel = CreateFrame("Button", nil, cancel, "UIPanelButtonTemplate")
doCancel:SetWidth(60); doCancel:SetHeight(22)
doCancel:SetPoint("BOTTOMRIGHT", cancel, "BOTTOMRIGHT", -150, 16)
Atr_LT(doCancel, "Cancel My Auction")
doCancel:SetScript("OnClick", function() Atr_CancelUndercut_Confirm(true) end)
end

---------------------------------------

do
local mask = CreateFrame("Frame", "Atr_Mask", UIParent)
mask:SetToplevel(true)
mask:SetWidth(820)
mask:SetHeight(450)
mask:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 12, -115)
mask:EnableMouse(true)
mask:SetBackdrop({
    bgFile = "Interface\\\\Tooltips\\\\UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
})
mask:SetBackdropColor(0.2, 0.2, 0.2)
mask:Hide()
end

---------------------------------------

do
local f = CreateFrame("Frame", "Atr_FullScanFrame", UIParent)
f:SetWidth(460)
f:SetHeight(420)
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 220, -130)
f:SetFrameStrata("DIALOG")
f:SetToplevel(true)
f:EnableMouse(true)
f:SetBackdrop({
    bgFile = "Interface\\CharacterFrame\\UI-Party-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})

f:SetScript("OnShow", function()
    if AuctionFrame and AuctionFrame:IsShown() and Atr_Mask then Atr_Mask:Show() end end)
f:SetScript("OnHide", function()
    if AuctionFrame and AuctionFrame:IsShown() and Atr_Mask then Atr_Mask:Hide() end end)
f:Hide()

local header = f:CreateTexture(nil, "ARTWORK")
header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
header:SetWidth(310); header:SetHeight(64)
header:SetPoint("TOP", f, "TOP", 0, 12)

---------------------------------------

local function Font(parent, name, template, text, point, relative, relativePoint, x, y, width, height)
    local fs = parent:CreateFontString(name, "ARTWORK", template)
    if text and text ~= "" then Atr_LT(fs, text) end
    if width then fs:SetWidth(width) end
    if height then fs:SetHeight(height) end
    fs:SetPoint(point, relative or parent, relativePoint or point, x or 0, y or 0)
    return fs
end

Font(f, nil, "GameFontNormal", "Full Scan", "TOP", f, "TOP", 0, -2)
Atr_FullScanNextLabel = Font(f, "Atr_FullScanNextLabel", "GameFontNormal", "Next scan allowed:", "TOPLEFT", f, "TOPLEFT", 27, -55)
Atr_FullScanNext = Font(f, "Atr_FullScanNext", "GameFontHighlight", nil, "TOPLEFT", f, "TOPLEFT", 150, -55)
Atr_FullScanDBwhenLabel = Font(f, "Atr_FullScanDBwhenLabel", "GameFontNormal", "Last scan:", "TOPLEFT", f, "TOPLEFT", 27, -80)
Atr_FullScanDBwhen = Font(f, "Atr_FullScanDBwhen", "GameFontHighlight", nil, "TOPLEFT", f, "TOPLEFT", 150, -80)
Atr_FullScanDBsizeLabel = Font(f, "Atr_FullScanDBsizeLabel", "GameFontNormal", "Items in database:", "TOPLEFT", f, "TOPLEFT", 27, -105)
Atr_FullScanDBsize = Font(f, "Atr_FullScanDBsize", "GameFontHighlight", nil, "TOPLEFT", f, "TOPLEFT", 150, -105)
Atr_FullScanStatus = Font(f, "Atr_FullScanStatus", "GameFontNormal", "", "TOPLEFT", f, "TOPLEFT", 27, -140)

---------------------------------------

local done = CreateFrame("Button", "Atr_FullScanDone", f, "UIPanelButtonTemplate")
done:SetWidth(80); done:SetHeight(22)
done:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30, -140)
Atr_LT(done, "DONE")
done:SetScript("OnClick", function() Atr_FullScanFrame:Hide() end)

local start = CreateFrame("Button", "Atr_FullScanStartButton", f, "UIPanelButtonTemplate")
start:SetWidth(120); start:SetHeight(22)
start:SetPoint("RIGHT", done, "LEFT", -4, 0)
Atr_LT(start, "Start Scanning")
start:SetScript("OnClick", function() Atr_FullScanStart() end)

---------------------------------------

local html = CreateFrame("SimpleHTML", "Atr_FullScanHTML", f)
html:SetWidth(405)
html:SetHeight(300)
html:SetPoint("TOPLEFT", f, "TOPLEFT", 27, -175)
local paragraphFont, paragraphSize, paragraphFlags = GameFontLightGraySmall:GetFont()
html:SetFont("p", paragraphFont, paragraphSize, paragraphFlags)
local headingFont, headingSize, headingFlags = GameFontNormal:GetFont()
html:SetFont("h1", headingFont, headingSize, headingFlags)

local results = CreateFrame("Frame", "Atr_FullScanResults", f)
results:SetPoint("TOPLEFT", f, "TOPLEFT", 70, -195)
results:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -70, 30)
results:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
results:Hide()

local scannedText = Font(results, "Atr_FSR_scanned_text", "GameFontNormal", "Auctions scanned:", "TOPRIGHT", results, "TOPRIGHT", -170, -40)
Atr_FSR_scanned_count = Font(results, "Atr_FSR_scanned_count", "GameFontHighlight", "", "LEFT", scannedText, "RIGHT", 15, 0)
local addedText = Font(results, "Atr_FSR_added_text", "GameFontNormal", "Items added:", "TOPRIGHT", results, "TOPRIGHT", -170, -65)
Atr_FSR_added_count = Font(results, "Atr_FSR_added_count", "GameFontHighlight", "", "LEFT", addedText, "RIGHT", 15, 0)
local updatedText = Font(results, "Atr_FSR_updated_text", "GameFontNormal", "Items updated:", "TOPRIGHT", results, "TOPRIGHT", -170, -90)
Atr_FSR_updated_count = Font(results, "Atr_FSR_updated_count", "GameFontHighlight", "", "LEFT", updatedText, "RIGHT", 15, 0)
local ignoredText = Font(results, "Atr_FSR_ignored_text", "GameFontNormal", "Items ignored:", "TOPRIGHT", results, "TOPRIGHT", -170, -115)
Atr_FSR_ignored_count = Font(results, "Atr_FSR_ignored_count", "GameFontHighlight", "", "LEFT", ignoredText, "RIGHT", 15, 0)
end

---------------------------------------

do

local frame = CreateFrame("Frame", "Atr_Buy_Confirm_Frame", UIParent)
Atr_Buy_Confirm_Frame = frame
frame:SetWidth(390)
frame:SetHeight(180)
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 270, -290)
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:EnableMouse(true)
frame:SetBackdrop({
    bgFile = "Interface\\CharacterFrame\\UI-Party-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})

frame:Hide()
frame:SetScript("OnShow", function()
    if AuctionFrame and AuctionFrame:IsShown() and Atr_Mask then Atr_Mask:Show() end end)

frame:SetScript("OnHide", function()
    if AuctionFrame and AuctionFrame:IsShown() and Atr_Mask then Atr_Mask:Hide() end end)

frame:SetScript("OnUpdate", function() Atr_Buy_Confirm_Update() end)

local itemName = frame:CreateFontString("Atr_Buy_Confirm_ItemName", "BACKGROUND", "GameFontNormal")
Atr_Buy_Confirm_ItemName = itemName
itemName:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -34)

local part1 = CreateFrame("Frame", "Atr_Buy_Part1", frame)
Atr_Buy_Part1 = part1
part1:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
part1:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 40)

local text1 = part1:CreateFontString("Atr_Buy_Confirm_Text1", "BACKGROUND", "GameFontNormal")
Atr_Buy_Confirm_Text1 = text1
text1:SetPoint("TOPLEFT", part1, "TOPLEFT", 70, -79)
Atr_LT(text1, "Buy")
local maxText = part1:CreateFontString("Atr_Buy_Confirm_Max_Text", "BACKGROUND", "GameFontDarkGraySmall")
Atr_Buy_Confirm_Max_Text = maxText
maxText:SetPoint("TOPLEFT", part1, "TOPLEFT", 110, -97)

local text2 = part1:CreateFontString("Atr_Buy_Confirm_Text2", "BACKGROUND", "GameFontNormal")
Atr_Buy_Confirm_Text2 = text2
text2:SetPoint("TOPLEFT", part1, "TOPLEFT", 160, -79)
Atr_LT(text2, "stacks for:")
local totalPrice = CreateFrame("Frame", "Atr_Buy_Confirm_TotalPrice", part1, "SmallMoneyFrameTemplate")
Atr_Buy_Confirm_TotalPrice = totalPrice
totalPrice:SetWidth(125)
totalPrice:SetHeight(16)
totalPrice:SetPoint("TOPLEFT", text1, "TOPLEFT", 160, 2)


local previousThis = this
this = totalPrice
AuctionatorMoneyFrame_OnLoad()
this = previousThis

local numStacks = CreateFrame("EditBox", "Atr_Buy_Confirm_Numstacks", part1, "InputBoxTemplate")
Atr_Buy_Confirm_Numstacks = numStacks
numStacks:SetWidth(40)
numStacks:SetHeight(20)
numStacks:SetPoint("TOPLEFT", text1, "TOPLEFT", 40, 4)
numStacks:SetAutoFocus(false)
numStacks:SetNumeric(true)
numStacks:SetMaxLetters(64)
numStacks:SetFontObject(ChatFontNormal)
numStacks:SetJustifyH("CENTER")

local part2 = CreateFrame("Frame", "Atr_Buy_Part2", frame)
Atr_Buy_Part2 = part2
part2:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
part2:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 40)
local continueText = part2:CreateFontString("Atr_Buy_Continue_Text", "BACKGROUND", "GameFontNormal")
Atr_Buy_Continue_Text = continueText
continueText:SetPoint("TOPLEFT", part2, "TOPLEFT", 60, -79)

local cancel = CreateFrame("Button", "Atr_Buy_Confirm_CancelBut", frame, "UIPanelButtonTemplate")
Atr_Buy_Confirm_CancelBut = cancel
cancel:SetWidth(80)
cancel:SetHeight(22)
cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 25)
Atr_LT(cancel, "CANCEL")
cancel:SetScript("OnClick", function() Atr_Buy_Cancel() end)

local okay = CreateFrame("Button", "Atr_Buy_Confirm_OKBut", frame, "UIPanelButtonTemplate")
Atr_Buy_Confirm_OKBut = okay
okay:SetWidth(80)
okay:SetHeight(22)
okay:SetPoint("RIGHT", cancel, "LEFT", -10, 0)
Atr_LT(okay, "Buy")
okay:SetScript("OnClick", function() Atr_Buy_Confirm_OK() end)
end

---------------------------------------

do
function Atr_CreateSellDropControls(parent)
    if not parent or Atr_Hilite1 then return end

    local highlight = CreateFrame("Frame", "Atr_Hilite1", parent)
    highlight:SetHeight(111)
    highlight:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -72)
    highlight:SetPoint("RIGHT", parent, "RIGHT", 63, 0)
    highlight:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
    })
    highlight:Hide()

    local drop = CreateFrame("Button", "Atr_SellDropTarget", parent)
    drop:SetHeight(110)
    drop:SetPoint("TOPLEFT", parent, "TOPLEFT", 60, -72)
    drop:SetPoint("RIGHT", parent, "RIGHT", 63, 0)
    drop:RegisterEvent("NEW_AUCTION_UPDATE")
    drop:RegisterForDrag("LeftButton")
    drop:SetScript("OnEvent", function(self, event)
        if event == "NEW_AUCTION_UPDATE" then
            Atr_Hilite1:Hide()
        end
    end)

    drop:SetScript("OnClick", function(self, button)
        Atr_OnDropItem(self, button) end)

    drop:SetScript("OnReceiveDrag", function(self)
        Atr_OnDropItem(self) end)

    drop:SetScript("OnEnter", function()
        if CursorHasItem() then Atr_Hilite1:Show() end end)

    drop:SetScript("OnLeave", function()
        Atr_Hilite1:Hide()
    end)
end
end

---------------------------------------

do

local addonName, addonTable = "Auctionator", AtrNS; 
local zc = addonTable.zc;

-----------------------------------------

-- (language tables, ZT and the text registry live in Localization.lua)

-----------------------------------------

function zc.IsEnglishLocale()

	return (GetLocale() == "enUS" or GetLocale() == "enGB");

end

-----------------------------------------

local testt = {};
local Atr_excludes = { Cancel=1, Okay=1, Done=1, Close=1 }

-----------------------------------------

local function Atr_LocalizeChildText (frame)

	local child;
	local subregions = { frame:GetRegions() };
	for _, child in ipairs(subregions) do

		if  (type (child.GetText) == "function") then
			local ftext = child:GetText();
			local fname = tostring(child:GetName());
			
			if (ftext and ftext ~= "" and not Atr_excludes[ftext] and not zc.StringStartsWith (fname, "AuctionatorEntry")) then
				testt[ftext] = 1;
				child:SetText (ZT(ftext));
			end
		end
	end
	
	local kids = { frame:GetChildren() };
	for _, child in ipairs(kids) do
		
		if  (type (child.GetText) == "function") then
			local ftext = child:GetText();
			local fname = tostring(child:GetName());
			
			if (ftext and ftext ~= "" and not Atr_excludes[ftext] and not zc.StringStartsWith (fname, "AuctionatorEntry")) then
				testt[ftext] = 1;
				
				if (child:GetObjectType() == "Button") then
					local oldwid = math.floor(child:GetWidth());
					child:SetText (ZT(ftext));
					local newwid = math.floor(child:GetTextWidth()) + 15;
					if (newwid > oldwid) then
						child:SetWidth (newwid+20);
					end
				else
					child:SetText (ZT(ftext));
				end
			end
		end
			
		if (child:GetObjectType() ~= "Button") then
			Atr_LocalizeChildText (child);
		end
	end			

end

-----------------------------------------

function Atr_LocalizeFrames ()

	local roots = { getglobal("AuctionFrame"), getglobal("Atr_BasicOptionsFrame") }
	local seen = {}
	local i, root
	for i, root in ipairs(roots) do
		if root and not seen[root] then
			seen[root] = true
			Atr_LocalizeChildText(root)
		end
	end

end

-----------------------------------------

local kUncutGems = {
	36924, 		-- sky sapphire
	36925, 		-- majestic zircon

	36918, 		-- scarlet ruby
	36919, 		-- cardinal ruby

	36933, 		-- forest emerald
	36934, 		-- eye of zul

	36930, 		-- monarch topaz
	36931, 		-- ametrine

	36927, 		-- twilight opal
	36928, 		-- dreadstone

	36921, 		-- autumns glow
	36922, 		-- kings amber

	41334, 		-- earthsiege diamond
	41266, 		-- skyflare diamond

	42225 		-- dragon's eye
	}

-----------------------------------------

function Atr_IsCutGem (itemLink)		return false;	end
function Atr_IsGlyph (itemLink)			return false;	end
function Atr_IsGem (itemLink)			return false;	end
function Atr_IsItemEnhancement (itemLink)	return false;	end

local function Atr_IsTypeAndSub (itemLink, wantType, wantSub)

	if (itemLink == nil) then
		return false;
	end

	local _, _, _, _, _, itemType, itemSubType = Atr_GetItemInfo (itemLink);

	return (itemType ~= nil and itemSubType ~= nil and zc.StringSame (itemType, wantType) and zc.StringSame (itemSubType, wantSub));
end

function Atr_IsPotion (itemLink)		return Atr_IsTypeAndSub (itemLink, "Consumable", "Potion");		end
function Atr_IsElixir (itemLink)		return Atr_IsTypeAndSub (itemLink, "Consumable", "Elixir");		end
function Atr_IsFlask (itemLink)			return Atr_IsTypeAndSub (itemLink, "Consumable", "Flask");		end
function Atr_IsHerb (itemLink)			return Atr_IsTypeAndSub (itemLink, "Trade Goods", "Herb");		end

-----------------------------------------

local gItemClasses;
local gItemSubClasses;

-----------------------------------------

function Atr_IsWeaponType				(itemType)		return (Atr_ItemType2AuctionClass (itemType) == 1);		end
function Atr_IsArmorType				(itemType)		return (Atr_ItemType2AuctionClass (itemType) == 2);		end

-----------------------------------------

function Atr_IsClass (itemLink, class, subclass)

	if (itemLink == nil) then
		return false;
	end

	local _, _, _, _, _, itemType, itemSubType = Atr_GetItemInfo (itemLink);

	local itemClass = Atr_ItemType2AuctionClass (itemType);
	local itemSubClass;
	
	if (itemClass == class) then
	
		if (subclass == nil) then
			return true;
		end
	
		itemSubClass = Atr_SubType2AuctionSubclass (itemClass, itemSubType)

		if (subclass == itemSubClass) then
			return true;
		end
	end
		
	return false;
end

-----------------------------------------

function Atr_ItemType2AuctionClass(itemType)

	if (gItemClasses == nil) then
		gItemClasses = { GetAuctionItemClasses() };
	end
	
	if getn(gItemClasses) > 0 then
	local itemClass;
		for x, itemClass in pairs(gItemClasses) do
			if (zc.StringSame (itemClass, itemType)) then
				return x;
			end
		end
	end

	return 0;
end

-----------------------------------------

function Atr_SubType2AuctionSubclass(auctionClass, itemSubtype)

	if (gItemSubClasses == nil) then
		gItemSubClasses = {};
	end
	
	if (gItemSubClasses[auctionClass] == nil) then
		gItemSubClasses[auctionClass] = { GetAuctionItemSubClasses(auctionClass) };
	end
	
	local subclasses = gItemSubClasses[auctionClass];

	if getn(subclasses) > 0 then
	local itemSubClass;
		for x, itemSubClass in pairs(subclasses) do
			if (zc.StringSame (itemSubClass, itemSubtype)) then
				return x;
			end
		end
	end

	return 0;
end
end

---------------------------------------

do

local tabsParent = AuctionFrame or UIParent
local tabs = CreateFrame("Frame", "Atr_ListTabs", tabsParent)
tabs:SetWidth(250)
tabs:SetHeight(40)
tabs:SetPoint("BOTTOMRIGHT", Atr_HeadingsBar, "TOPRIGHT", 0, -22)

---------------------------------------

local function RaiseListTabs()
    if not tabs then return end
    local parent = AuctionFrame or UIParent
    if tabs:GetParent() ~= parent then
        tabs:SetParent(parent)
    end
    tabs:SetFrameStrata(parent:GetFrameStrata())
    tabs:SetFrameLevel(parent:GetFrameLevel() + 40)
end
RaiseListTabs()
tabs:Hide()

---------------------------------------

local function CreateListTab(name, id, text, point, relativeTo, relativePoint, x, y)
    local button = CreateFrame("Button", name, tabs, "TabButtonTemplate")
    button:SetID(id)
    button:SetText(text)
    button:SetFrameLevel(tabs:GetFrameLevel() + 1)
    if relativeTo then
        button:SetPoint(point, relativeTo, relativePoint, x, y)
    else
        button:SetPoint(point, tabs, point, x, y)
    end
    button:SetScript("OnClick", function()
        Atr_UpdateListTabsSelection(id)
        Atr_ShowWhichRB(id)
    end)
    return button
end

---------------------------------------

local tab3 = CreateListTab("Atr_ListTabsTab3", 3, ZT("Other"), "BOTTOMRIGHT", nil, nil, -8, 0)
local tab2 = CreateListTab("Atr_ListTabsTab2", 2, ZT("Past"), "RIGHT", tab3, "LEFT", -2, 0)
local tab1 = CreateListTab("Atr_ListTabsTab1", 1, ZT("Current"), "RIGHT", tab2, "LEFT", -2, 0)

tabs.numTabs = 3
tabs.selectedTab = 1

function Atr_UpdateListTabsSelection(id)
    if type(id) ~= "number" or id < 1 or id > 3 then return end
    RaiseListTabs()
    tabs.selectedTab = id
    for i = 1, 3 do
        local button = getglobal("Atr_ListTabsTab" .. i)
        if button then
            if i == id then
                PanelTemplates_SelectTab(button)
            else
                PanelTemplates_DeselectTab(button)
            end
        end
    end
end

Atr_UpdateListTabsSelection(1)

tabs:SetScript("OnShow", function()
    RaiseListTabs()
    for i = 1, 3 do
        local button = getglobal("Atr_ListTabsTab" .. i)
        if button then button:SetFrameLevel(tabs:GetFrameLevel() + 1) end
    end
    PlaySound("UChatScrollButton")
    Atr_UpdateListTabsSelection(1)
end)
tabs:SetScript("OnHide", function()
    PlaySound("UChatScrollButton")
end)

if AuctionFrame then
    AuctionFrame:HookScript("OnShow", function()
        RaiseListTabs()
    end)
    AuctionFrame:HookScript("OnHide", function()
        tabs:Hide()
    end)
end
end

---------------------------------------

do

function Atr_CreateMainPanelElements(parent)
    local title = parent:CreateFontString("AuctionatorTitle", "BACKGROUND", "GameFontNormal")
    title:SetPoint("TOP", parent, "TOP", -100, -18)

    local message = parent:CreateFontString("AuctionatorMessageFrame", "BACKGROUND", "GameFontNormal")
    message:SetPoint("TOP", parent, "TOP", 8, -100)

    local message2 = parent:CreateFontString("AuctionatorMessage2Frame", "BACKGROUND", "GameFontNormal")
    message2:SetJustifyH("CENTER")
    message2:SetJustifyV("MIDDLE")
    message2:SetHeight(100)
    message2:SetPoint("TOP", parent, "TOP", 8, -90)
    message2:SetTextColor(0.1, 1.0, 0.1)

    local recommend = parent:CreateFontString("Atr_Recommend_Text", "BACKGROUND", "GameFontNormal")
    Atr_LT(recommend, "Recommended buyout price")
    recommend:SetPoint("TOPLEFT", parent, "TOPLEFT", 77, -98)

    local basis = parent:CreateFontString("Atr_Recommend_Basis_Text", "BACKGROUND", "GameFontHighlightSmall")
    Atr_LT(basis, "based on")
    basis:SetPoint("LEFT", recommend, "RIGHT", 20, -2)

    local perStack = parent:CreateFontString("Atr_RecommendPerStack_Text", "BACKGROUND", "GameFontHighlightSmall")
    Atr_LT(perStack, "per stack")
    perStack:SetPoint("TOPLEFT", recommend, "TOPLEFT", 152, -28)

    local perItem = parent:CreateFontString("Atr_RecommendPerItem_Text", "BACKGROUND", "GameFontHighlightSmall")
    Atr_LT(perItem, "per item")
    perItem:SetPoint("TOPLEFT", recommend, "TOPLEFT", 152, -51)

    local close = CreateFrame("Button", "AuctionatorCloseButton", parent, "UIPanelButtonTemplate")
    Atr_LT(close, "CLOSE")
    close:SetWidth(80); close:SetHeight(22)
    close:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 66, 14)
    close:SetScript("OnClick", function(self) HideUIPanel(self:GetParent():GetParent()) end)

    local cancel = CreateFrame("Button", "Atr_CancelSelectionButton", parent, "UIPanelButtonTemplate")
    Atr_LT(cancel, "Cancel Auctions")
    cancel:SetWidth(113); cancel:SetHeight(22)
    cancel:SetPoint("RIGHT", close, "LEFT", 2, 0)
    cancel:SetScript("OnClick", function() Atr_CancelSelection_OnClick() end)
    cancel:SetNormalFontObject(GameFontNormalSmall)
    cancel:SetHighlightFontObject(GameFontHighlightSmall)
    cancel:SetDisabledFontObject(GameFontDisableSmall)

    local buy = CreateFrame("Button", "Atr_Buy1_Button", parent, "UIPanelButtonTemplate")
    Atr_LT(buy, "Buy")
    buy:SetWidth(90); buy:SetHeight(22)
    buy:SetPoint("RIGHT", cancel, "LEFT", 4, 0)
    buy:SetScript("OnClick", function() Atr_Buy1_Onclick_SellAware() end)

    local scroll = CreateFrame("ScrollFrame", "AuctionatorScrollFrame", parent, "FauxScrollFrameTemplate")
    scroll:SetWidth(588); scroll:SetHeight(196)
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -213)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(16, Atr_RedisplayAuctions)
    end)
end
end

---------------------------------------

do

local function Atr_MorePanelButton(name, text, width, x, y, click, disabled)
    local button = CreateFrame("Button", name, Atr_Main_Panel, "UIPanelButtonTemplate")
    button:SetWidth(width); button:SetHeight(20)
    button:SetPoint("TOPLEFT", Atr_Main_Panel, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetNormalFontObject(GameFontNormalSmall)
    button:SetHighlightFontObject(GameFontHighlightSmall)
    button:SetDisabledFontObject(GameFontDisableSmall)
    if click then button:SetScript("OnClick", click) end
    if disabled then button:Disable() end
    return button
end

---------------------------------------

function Atr_CreateMorePanelControls()
    Atr_DropDown1 = CreateFrame("Frame", "Atr_DropDown1", Atr_Main_Panel, "UIDropDownMenuTemplate")
    Atr_DropDown1:SetPoint("TOPLEFT", Atr_Main_Panel, "TOPLEFT", -170, -49)
    Atr_DropDown1_OnLoad(Atr_DropDown1)

    Atr_DropDownSL = CreateFrame("Frame", "Atr_DropDownSL", Atr_Main_Panel, "UIDropDownMenuTemplate")
    Atr_DropDownSL:SetPoint("TOPLEFT", Atr_Main_Panel, "TOPLEFT", -190, -49)
    Atr_DropDownSL_OnLoad(Atr_DropDownSL)

    Atr_CheckActiveButton = Atr_MorePanelButton("Atr_CheckActiveButton", ZT("Check for Undercuts"), 165, -195, -413,
        function() Atr_CheckActive_OnClick(false) end, false)

    Atr_Hlist_ScrollFrame = CreateFrame("ScrollFrame", "Atr_Hlist_ScrollFrame", Atr_Main_Panel, "FauxScrollFrameTemplate")
    Atr_Hlist_ScrollFrame:SetWidth(170); Atr_Hlist_ScrollFrame:SetHeight(335)
    Atr_Hlist_ScrollFrame:SetPoint("TOPLEFT", Atr_Main_Panel, "TOPLEFT", -193, -75)
    Atr_Hlist_ScrollFrame:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(16, Atr_DisplayHlist) end)
    Atr_Hlist_ScrollFrame:Hide()

    Atr_Hlist = CreateFrame("Frame", "Atr_Hlist", Atr_Main_Panel)
    Atr_Hlist:SetWidth(170); Atr_Hlist:SetHeight(335)
    Atr_Hlist:SetPoint("TOPLEFT", Atr_Main_Panel, "TOPLEFT", -193, -75)
    Atr_Hlist:SetBackdrop({bgFile="Interface\\CharacterFrame\\UI-Party-Background", tile=true,
        insets={left=0,right=-24,top=0,bottom=0}})
    Atr_Hlist:SetBackdropColor(1,1,1,1)

    local border = Atr_Hlist:CreateTexture(nil, "ARTWORK")
    border:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    border:SetWidth(5); border:SetPoint("TOPLEFT", Atr_Hlist, "TOPLEFT", 174, 0)
    border:SetPoint("BOTTOM", Atr_Hlist, "BOTTOM", 0, 0)
    border:SetTexCoord(0.15,0.25,0,1)
    Atr_Hlist:Hide()

    Atr_RecommendItem_Tex = CreateFrame("Button", "Atr_RecommendItem_Tex", Atr_Main_Panel)
    Atr_RecommendItem_Tex:SetWidth(37); Atr_RecommendItem_Tex:SetHeight(37)
    Atr_RecommendItem_Tex:SetPoint("TOPLEFT", Atr_Main_Panel, "TOPLEFT", 24, -87)
    Atr_RecommendItem_Tex.Count = Atr_RecommendItem_Tex:CreateFontString("Atr_RecommendItem_TexCount", "OVERLAY", "NumberFontNormal")
    Atr_RecommendItem_Tex.Count:SetJustifyH("RIGHT")
    Atr_RecommendItem_Tex.Count:SetPoint("BOTTOMRIGHT", Atr_RecommendItem_Tex, "BOTTOMRIGHT", -5, 2)
    Atr_RecommendItem_Tex.Count:Hide()
    Atr_RecommendItem_Tex:SetScript("OnEnter", function() Atr_ShowRecTooltip() end)
    Atr_RecommendItem_Tex:SetScript("OnLeave", function() Atr_HideRecTooltip() end)

    Atr_AddToSListButton = Atr_MorePanelButton("Atr_AddToSListButton", ZT("Add Item To List"), 195, -195, -329, function() Atr_AddToSListOnClick() end, true)
    Atr_RemFromSListButton = Atr_MorePanelButton("Atr_RemFromSListButton", ZT("Remove Item From List"), 195, -195, -349, function() Atr_RemFromSListOnClick() end, true)
    Atr_DelSListButton = Atr_MorePanelButton("Atr_DelSListButton", ZT("Delete Shopping List"), 195, -195, -369, function() Atr_DelSList_OnClick() end, true)
    Atr_NewSListButton = Atr_MorePanelButton("Atr_NewSListButton", ZT("New Shopping List"), 195, -195, -389, function() Atr_NewSlist_OnClick() end, false)

    Atr_RecommendPerStack_Price = CreateFrame("Frame", "Atr_RecommendPerStack_Price", Atr_Main_Panel, "SmallMoneyFrameTemplate")
    Atr_RecommendPerStack_Price:SetWidth(120); Atr_RecommendPerStack_Price:SetHeight(16)
    Atr_RecommendPerStack_Price:SetPoint("TOPLEFT", Atr_Main_Panel, "TOPLEFT", 109, -122)
    local oldThis = this; this = Atr_RecommendPerStack_Price; Atr_RecommendPerStack_Price.small = 1; MoneyFrame_SetType("AUCTION"); this = oldThis

    Atr_RecommendPerItem_Price = CreateFrame("Frame", "Atr_RecommendPerItem_Price", Atr_Main_Panel, "SmallMoneyFrameTemplate")
    Atr_RecommendPerItem_Price:SetWidth(120); Atr_RecommendPerItem_Price:SetHeight(16)
    Atr_RecommendPerItem_Price:SetPoint("TOPLEFT", Atr_Main_Panel, "TOPLEFT", 109, -144)
    oldThis = this; this = Atr_RecommendPerItem_Price; Atr_RecommendPerItem_Price.small = 1; MoneyFrame_SetType("AUCTION"); this = oldThis
end
end

---------------------------------------

do

local function Atr_CreateResultRow(index)
    local name = "AuctionatorEntry" .. index
    local row = CreateFrame("Button", name, Atr_Main_Panel)
    row:SetWidth(584)
    row:SetHeight(16)
    if index == 1 then
        row:SetPoint("TOPLEFT", AuctionatorScrollFrame, "TOPLEFT", 8, 0)
    else
        row:SetPoint("TOPLEFT", getglobal("AuctionatorEntry" .. (index - 1)), "BOTTOMLEFT", 0, 0)
    end

    local itemArea = CreateFrame("Frame", name .. "_ItemArea", row)
    itemArea:SetWidth(120); itemArea:SetHeight(16)
    itemArea:SetPoint("LEFT", row, "LEFT", 22, 0)

    local perItemText = itemArea:CreateFontString(name .. "_PerItem_Text", "BACKGROUND", "GameFontDarkGraySmall")
    perItemText:SetJustifyH("RIGHT")
    perItemText:SetPoint("RIGHT", itemArea, "RIGHT", -16, 1)

    local perItemPrice = CreateFrame("Frame", name .. "_PerItem_Price", itemArea, "SmallMoneyFrameTemplate")
    perItemPrice:SetPoint("RIGHT", itemArea, "RIGHT", 0, 0)

    local oldThis = this
    this = perItemPrice
    perItemPrice.small = 1
    MoneyFrame_SetType("AUCTION")
    this = oldThis

    local textArea = CreateFrame("Frame", name .. "_TextArea", row)
    textArea:SetWidth(240); textArea:SetHeight(16)
    textArea:SetPoint("LEFT", row, "LEFT", 167, 0)
    local entryText = textArea:CreateFontString(name .. "_EntryText", "BACKGROUND", "GameFontHighlightSmall")
    entryText:SetJustifyH("LEFT")
    entryText:SetAllPoints(textArea)

    local stackArea = CreateFrame("Frame", name .. "_StackArea", row)
    stackArea:SetWidth(120); stackArea:SetHeight(16)
    stackArea:SetPoint("LEFT", row, "LEFT", 440, 0)
    local stackText = stackArea:CreateFontString(name .. "_StackPrice", "BACKGROUND", "GameFontHighlightSmall")
    stackText:SetJustifyH("RIGHT")
    stackText:SetAllPoints(stackArea)

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetTexCoord(0.035, 0.04, 0.2, 0.25)
    highlight:SetAllPoints(row)
    row:SetScript("OnClick", function(self) Atr_EntryOnClick(self) end)
    row:SetScript("OnEnter", function() Atr_ShowLineTooltip(this) end)
    row:SetScript("OnLeave", function() Atr_HideLineTooltip() end)
    row:Hide()
    return row
end

function Atr_CreateResultRows()
    local i
    for i = 1, 15 do Atr_CreateResultRow(i) end
end

---------------------------------------

function Atr_CreateHistoryEntry(index, parent)
    local name = "AuctionatorHEntry" .. index
    local row = CreateFrame("Button", name, parent)
    row:SetWidth(174); row:SetHeight(16)
    local text = row:CreateFontString(name .. "_EntryText", "BACKGROUND", "GameFontHighlightSmall")
    text:SetWidth(174); text:SetHeight(16)
    text:SetJustifyH("LEFT")
    text:SetPoint("LEFT", row, "LEFT", 2, 0)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetTexCoord(0.05, 0.07, 0.1, 0.5)
    highlight:SetAllPoints(row)
    row:SetScript("OnClick", function() Atr_HEntryOnClick() end)
    row:Hide()
    return row
end

---------------------------------------

function Atr_CreateSearchControls(parent)
    local search = CreateFrame("EditBox", "Atr_Search_Box", parent, "InputBoxTemplate")
    search:SetWidth(260)
    search:SetHeight(20)
    search:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -45)
    search:SetAutoFocus(false)
    search:SetFontObject(ChatFontNormal)
    search:SetMaxLetters(64)
    search:SetScript("OnEnterPressed", function(self)
        Atr_Search_Onclick()
        self:ClearFocus()
    end)
    search:SetScript("OnCharComposition", function(self) Atr_Item_Autocomplete(self) end)
    search:SetScript("OnChar", function(self) Atr_Item_Autocomplete(self) end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnShow", function(self) self:SetFocus() end)

    local searchButton = CreateFrame("Button", "Atr_Search_Button", parent, "UIPanelButtonTemplate")
    Atr_LT(searchButton, "Search")
    searchButton:SetWidth(80)
    searchButton:SetHeight(22)
    searchButton:SetPoint("LEFT", search, "RIGHT", 15, 0)
    searchButton:SetScript("OnClick", function() Atr_Search_Onclick() end)

    local optionsButton = CreateFrame("Button", "Auctionator1Button", parent, "UIPanelButtonTemplate")
    Atr_LT(optionsButton, "Auctionator")
    optionsButton:SetWidth(90)
    optionsButton:SetHeight(18)
    optionsButton:SetPoint("LEFT", searchButton, "RIGHT", 145, 0)
    optionsButton:SetNormalFontObject(GameFontNormalSmall)
    optionsButton:SetHighlightFontObject(GameFontHighlightSmall)
    optionsButton:SetDisabledFontObject(GameFontDisableSmall)
    optionsButton:SetScript("OnClick", function() Atr_ShowOptions() end)

    local fullScanButton = CreateFrame("Button", "Atr_FullScanButton", parent, "UIPanelButtonTemplate")
    Atr_LT(fullScanButton, "Full Scan...")
    fullScanButton:SetWidth(74)
    fullScanButton:SetHeight(18)
    fullScanButton:SetPoint("RIGHT", optionsButton, "LEFT", -2, 0)
    fullScanButton:SetNormalFontObject(GameFontNormalSmall)
    fullScanButton:SetHighlightFontObject(GameFontHighlightSmall)
    fullScanButton:SetDisabledFontObject(GameFontDisableSmall)
    fullScanButton:SetScript("OnClick", function() Atr_ShowFullScanFrame() end)
end

---------------------------------------

local function Atr_CreateColumnHeadingButton(name, parent)
    local button = CreateFrame("Button", name, parent)
    button:SetNormalFontObject(GameFontHighlightSmall)

    local text = button:CreateFontString(name .. "Text", "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("LEFT", button, "LEFT", 8, 0)
    text:SetJustifyH("LEFT")
    button:SetFontString(text)

    local arrow = button:CreateTexture(name .. "Arrow", "OVERLAY")
    arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
    arrow:SetWidth(9)
    arrow:SetHeight(8)
    arrow:SetPoint("LEFT", text, "RIGHT", 3, -1)
    arrow:SetTexCoord(0, 0.5625, 0, 1)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetWidth(5)
    highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, 0)

    return button
end

---------------------------------------

function Atr_CreateHeadingsBar(parent)
    local bar = CreateFrame("Frame", "Atr_HeadingsBar", parent)
    bar:SetWidth(605)
    bar:SetHeight(64)
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -163)

    local middle = bar:CreateTexture("Atr_HeadingsBarMiddle", "ARTWORK")
    middle:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    middle:SetWidth(605)
    middle:SetHeight(64)
    middle:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    middle:SetTexCoord(0.1953125, 0.8046875, 0, 1)

    local col1 = bar:CreateFontString("Atr_Col1_Heading", "ARTWORK", "GameFontHighlightSmall")
    Atr_LT(col1, "Item Price")
    col1:SetWidth(100)
    col1:SetJustifyH("CENTER")
    col1:SetPoint("LEFT", middle, "LEFT", 40, 1)
    col1:Hide()

    local col3 = bar:CreateFontString("Atr_Col3_Heading", "ARTWORK", "GameFontHighlightSmall")
    Atr_LT(col3, "Current Auctions")
    col3:SetPoint("LEFT", middle, "LEFT", 175, 1)
    col3:Hide()

    local col4 = bar:CreateFontString("Atr_Col4_Heading", "ARTWORK", "GameFontHighlightSmall")
    Atr_LT(col4, "Total Price")
    col4:SetPoint("LEFT", middle, "LEFT", 500, 1)
    col4:Hide()

    local back = CreateFrame("Button", "Atr_Back_Button", bar, "UIPanelButtonTemplate")
    Atr_LT(back, "Back")
    back:SetWidth(70)
    back:SetHeight(18)
    back:SetPoint("TOPLEFT", bar, "TOPLEFT", 8, -5)
    back:SetScript("OnClick", function() Atr_Onclick_Back() end)
    back:SetNormalFontObject(GameFontNormalSmall)
    back:SetHighlightFontObject(GameFontHighlightSmall)
    back:SetDisabledFontObject(GameFontDisableSmall)
    back:Hide()

    local col1Button = Atr_CreateColumnHeadingButton("Atr_Col1_Heading_Button", bar)
    Atr_LT(col1Button, "Lowest Price")
    col1Button:SetWidth(100)
    col1Button:SetHeight(20)
    col1Button:SetPoint("TOPLEFT", bar, "TOPLEFT", 46, -21)
    col1Button:SetScript("OnClick", function() Atr_Onclick_Col1() end)
    col1Button:Hide()

    local col3Button = Atr_CreateColumnHeadingButton("Atr_Col3_Heading_Button", bar)
    Atr_LT(col3Button, "Item Name")
    col3Button:SetWidth(108)
    col3Button:SetHeight(20)
    col3Button:SetPoint("TOPLEFT", bar, "TOPLEFT", 172, -21)
    col3Button:SetScript("OnClick", function() Atr_Onclick_Col3() end)
    col3Button:Hide()

    return bar
end
end

---------------------------------------

do

local function AtrSellFont(parent, name, template, text, x, y, width, height, justify)
    local fs = parent:CreateFontString(name, "ARTWORK", template)
    if text and text ~= "" then Atr_LT(fs, text) end
    if width or height then fs:SetSize(width or 0, height or 0) end
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if justify then fs:SetJustifyH(justify) end
    return fs
end

---------------------------------------

function Atr_CreateSellPanel(parent)
    if Atr_SellControls then return end

    local panel = CreateFrame("Frame", "Atr_SellControls", parent)
    panel:SetSize(170, 335)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", -193, -75)
    panel:Hide()

    AtrSellFont(panel, nil, "GameFontHighlightSmall", "Sell", 93, 18)
    AtrSellFont(panel, "Atr_StackPriceText", "GameFontHighlightSmall", "Buyout Price", 10, -82)
    AtrSellFont(panel, "Atr_ItemPriceText", "GameFontHighlightSmall", "Item Price", 10, -128)
    AtrSellFont(panel, "Atr_Batch_Stacksize_Text", "GameFontNormal", "stacks of", 55, -208, 82, 22, "CENTER")

    Atr_Batch_MaxAuctions_Text = AtrSellFont(panel, "Atr_Batch_MaxAuctions_Text", "GameFontDarkGraySmall", nil, 21, -229)
    Atr_Batch_MaxStacksize_Text = AtrSellFont(panel, "Atr_Batch_MaxStacksize_Text", "GameFontDarkGraySmall", nil, 134, -229)
    AtrSellFont(panel, "Atr_StartingPriceText", "GameFontHighlightSmall", "Starting Price", 13, -260)
    Atr_StartingPriceText:Hide()
    AtrSellFont(panel, "Atr_StartingPriceDiscountText", "GameFontHighlightSmall", "Starting Price", 10, -270)
    AtrSellFont(panel, "Atr_Duration_Text", "GameFontHighlightSmall", "Duration", 10, -304)
    AtrSellFont(panel, "Atr_Deposit_Text", "GameFontHighlightSmall", "", 10, -342)

    local item = CreateFrame("Button", "Atr_SellControls_Tex", panel)
    item:SetSize(37, 37)
    item:SetPoint("TOPLEFT", panel, "TOPLEFT", 11, -23)
    item:RegisterEvent("NEW_AUCTION_UPDATE")
    item:RegisterForDrag("LeftButton")
    item:SetScript("OnEvent", function(self, event) Atr_SellItemButton_OnEvent(self, event) end)
    item:SetScript("OnClick", function(self, button) Atr_SellItemButton_OnClick(self, button) end)
    item:SetScript("OnDragStart", function(self) Atr_SellItemButton_OnClick(self, "LeftButton") end)
    item:SetScript("OnReceiveDrag", function(self) Atr_SellItemButton_OnClick(self, "LeftButton") end)
    local itemName = item:CreateFontString("Atr_SellControls_TexName", "OVERLAY", "GameFontNormal")
    itemName:SetSize(124, 30)
    itemName:SetPoint("TOPLEFT", item, "TOPRIGHT", 5, 0)
    local itemCount = item:CreateFontString("Atr_SellControls_TexCount", "OVERLAY", "NumberFontNormal")
    itemCount:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -5, 2)
    itemCount:Hide()
    item:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    Atr_StackPrice = CreateFrame("Frame", "Atr_StackPrice", panel, "MoneyInputFrameTemplate")
    Atr_StackPrice:SetPoint("TOPLEFT", Atr_StackPriceText, "BOTTOMLEFT", 8, -2)
    MoneyInputFrame_SetOnvalueChangedFunc(Atr_StackPrice, Atr_StackPriceChangedFunc)
    Atr_StackPriceGold:SetJustifyH("CENTER")

    Atr_ItemPrice = CreateFrame("Frame", "Atr_ItemPrice", panel, "MoneyInputFrameTemplate")
    Atr_ItemPrice:SetPoint("TOPLEFT", Atr_ItemPriceText, "BOTTOMLEFT", 8, -2)
    MoneyInputFrame_SetOnvalueChangedFunc(Atr_ItemPrice, Atr_ItemPriceChangedFunc)
    Atr_ItemPriceGold:SetJustifyH("CENTER")

    Atr_StartingPrice = CreateFrame("Frame", "Atr_StartingPrice", panel, "MoneyInputFrameTemplate")
    Atr_StartingPrice:SetPoint("TOPLEFT", Atr_StartingPriceText, "BOTTOMLEFT", 5, -2)
    Atr_StartingPriceGold:SetJustifyH("CENTER")
    Atr_StartingPrice:Hide()

    Atr_Batch_NumAuctions = CreateFrame("EditBox", "Atr_Batch_NumAuctions", panel, "InputBoxTemplate")
    Atr_Batch_NumAuctions:SetSize(40, 20)
    Atr_Batch_NumAuctions:SetPoint("TOPLEFT", Atr_Batch_Stacksize_Text, "TOPLEFT", -37, 0)
    Atr_Batch_NumAuctions:SetAutoFocus(false)
    Atr_Batch_NumAuctions:SetNumeric(true)
    Atr_Batch_NumAuctions:SetMaxLetters(64)
    Atr_Batch_NumAuctions:SetJustifyH("CENTER")
    Atr_Batch_NumAuctions:SetScript("OnTextChanged", function() Atr_NumAuctionsChangedFunc() end)
    Atr_Batch_NumAuctions:SetScript("OnTabPressed", function() Atr_Batch_Stacksize:SetFocus() end)

    Atr_Batch_Stacksize = CreateFrame("EditBox", "Atr_Batch_Stacksize", panel, "InputBoxTemplate")
    Atr_Batch_Stacksize:SetSize(40, 20)
    Atr_Batch_Stacksize:SetPoint("TOPLEFT", Atr_Batch_Stacksize_Text, "TOPLEFT", 84, 0)
    Atr_Batch_Stacksize:SetAutoFocus(false)
    Atr_Batch_Stacksize:SetNumeric(true)
    Atr_Batch_Stacksize:SetMaxLetters(64)
    Atr_Batch_Stacksize:SetJustifyH("CENTER")
    Atr_Batch_Stacksize:SetScript("OnTextChanged", function() Atr_StackSizeChangedFunc() end)
    Atr_Batch_Stacksize:SetScript("OnTabPressed", function() Atr_Batch_NumAuctions:SetFocus() end)

    Atr_CreateAuctionButton = CreateFrame("Button", "Atr_CreateAuctionButton", panel, "UIPanelButtonTemplate")
    Atr_CreateAuctionButton:SetSize(185, 30)
    Atr_CreateAuctionButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -170)
    Atr_LT(Atr_CreateAuctionButton, "Create Auction")
    Atr_CreateAuctionButton:Disable()
    Atr_CreateAuctionButton:SetScript("OnClick", function() Atr_CreateAuction_OnClick() end)

    Atr_Duration = CreateFrame("Frame", "Atr_Duration", panel, "UIDropDownMenuTemplate")
    Atr_Duration:SetPoint("TOPLEFT", Atr_Duration_Text, "TOPLEFT", 32, 7)
    Atr_Duration:SetScript("OnShow", function(self)
        Atr_Duration_OnShow(self)
        local selected = UIDropDownMenu_GetSelectedValue(self) or 1
        UIDropDownMenu_SetText(AtrNS.durationText[selected] or AtrNS.durationText[1], self)
    end)
    Atr_Duration_OnLoad(Atr_Duration)
    UIDropDownMenu_SetText(AtrNS.durationText[1], Atr_Duration)
end
end
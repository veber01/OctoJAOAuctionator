local function Tr(obj, key, nowiden)
	return Atr_LT(obj, key, nowiden)
end

local panelTitles = {}

Atr_OnLocalize(function()

	local i
	for i = 1, getn(panelTitles) do
		local p = panelTitles[i]
		p.frame.name = ZT(p.key)
		getglobal(p.frame:GetName() .. "_ATitle"):SetText(ZT(p.titleKey or p.key))
		if p.subtitleKey then
			getglobal(p.frame:GetName() .. "_BTitle"):SetText(ZT(p.subtitleKey))
		end
	end
end)

-----------------------------------------

-- Atr_OptionsPanelTemplate
local function CreatePanel(name, key, titleKey, subtitleKey)

	local f = CreateFrame("Frame", name, UIParent)
	f:EnableMouse(true)
	f:SetBackdrop({ bgFile = "Interface\\CharacterFrame\\UI-Party-Background", tile = true, tileSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 } })
	f:Hide()

	local a = f:CreateFontString(name .. "_ATitle", "BACKGROUND", "GameFontNormalLarge")
	a:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -15)

	local b = f:CreateFontString(name .. "_BTitle", "BACKGROUND", "GameFontHighlightSmall")
	b:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -40)

	Atr_LoadOptionsSubPanel(f, ZT(key), titleKey and ZT(titleKey) or nil, subtitleKey and ZT(subtitleKey) or nil)
	tinsert(panelTitles, { frame = f, key = key, titleKey = titleKey, subtitleKey = subtitleKey })

	return f
end

local function CreateLabel(parent, fontObject, key, x, y, name)
	local fs = parent:CreateFontString(name, "BACKGROUND", fontObject)
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	Tr(fs, key)
	return fs
end

local function CreateSingleOption(parent, name, key, y)

	local f = CreateFrame("Frame", name, parent)
	f:SetHeight(40)
	f:SetPoint("TOPLEFT",  parent, "TOPLEFT",  20, y)
	f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y)
	f:SetScript("OnEnter", function() Atr_ShowOptionTooltip(this) end)
	f:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local cb = CreateFrame("CheckButton", name .. "_CB", f, "UICheckButtonTemplate")
	cb:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	cb:SetScript("OnEnter", function() Atr_ShowOptionTooltip(this:GetParent()) end)
	cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
	cb:SetScript("OnClick", function() Atr_Option_OnClick(this) end)

	local text = cb:CreateFontString(name .. "_CB_Text", "BACKGROUND", "GameFontHighlight")
	text:SetPoint("LEFT", cb, "RIGHT", 8, 1)
	Tr(text, key)

	return f
end

local function CreateSmallButton(name, parent, w, h)
	local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
	b:SetWidth(w); b:SetHeight(h)
	b:SetNormalFontObject(GameFontNormalSmall)
	b:SetHighlightFontObject(GameFontHighlightSmall)
	b:SetDisabledFontObject(GameFontDisableSmall)
	return b
end

local function CreateDropDown(name, parent, x, y)
	local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
	dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	return dd
end

-----------------------------------------

do
	local f = CreatePanel("Atr_BasicOptionsFrame", "Basic Options")

	f.TimeSinceLastUpdate = 0
	f:SetScript("OnUpdate", function() Atr_BasicOptionsUpdate(this, arg1) end)

	CreateSingleOption(f, "AuctionatorOption_Enable_Alt",		"Enable alt-key shortcut",				-80)
	CreateSingleOption(f, "AuctionatorOption_Open_All_Bags",	"Automatically open all bags",			-115)
	CreateSingleOption(f, "AuctionatorOption_Show_StartingPrice",	"Show Starting Price on the Sell Tab",	-150)
	CreateSingleOption(f, "AuctionatorOption_Def_Duration",		"Set a default duration",				-185)

	local d = CreateFrame("Frame", "AuctionatorOption_Durations", f)
	d:SetWidth(250); d:SetHeight(25)
	d:SetPoint("TOPLEFT", f, "TOPLEFT", 40, -220)
	d:Hide()

	local function CreateRadio(name, anchorTo, index)
		local rb = CreateFrame("CheckButton", name, d, "UIRadioButtonTemplate")
		if anchorTo then
			rb:SetPoint("LEFT", anchorTo, "RIGHT", 20, 0)
		else
			rb:SetPoint("TOPLEFT", d, "TOPLEFT", 20, 0)
		end
		if AtrNS.durationText then getglobal(name .. "Text"):SetText(AtrNS.durationText[index]) end
		rb:SetScript("OnClick", function() Atr_SetDurationOptionRB(this:GetName()) end)
		return rb
	end

	CreateRadio("Atr_RB_S", nil,				1)
	CreateRadio("Atr_RB_M", Atr_RB_SText,	2)
	CreateRadio("Atr_RB_L", Atr_RB_MText,	3)

	local t = CreateFrame("Frame", "AuctionatorOption_Deftab_Text", f)
	t:SetWidth(180); t:SetHeight(20)
	t:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -261)
	t:EnableMouse(true)
	t:SetScript("OnEnter", function() Atr_ShowOptionTooltip(this) end)
	t:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local tt = t:CreateFontString("AuctionatorOption_Deftab_Text_Text", "ARTWORK", "GameFontHighlight")
	tt:SetPoint("TOPLEFT", t, "TOPLEFT", 0, 0)
	Tr(tt, "Default Auctionator tab")

	local dd = CreateDropDown("AuctionatorOption_Deftab", f, 165, -255)
	UIDropDownMenu_Initialize(dd, AuctionatorOption_Deftab_Initialize)
	UIDropDownMenu_JustifyText("LEFT", dd)
end

-----------------------------------------

do
	local f = CreatePanel("Atr_TooltipsOptionsFrame", "Tooltips")

	CreateLabel(f, "GameFontNormal", "When SHIFT is down show",		20, -181)
	CreateLabel(f, "GameFontNormal", "Show disenchanting details",	20, -251)

	CreateSingleOption(f, "ATR_tipsVendorOpt",		"Show vendor prices in tooltips",		-70)
	CreateSingleOption(f, "ATR_tipsAuctionOpt",		"Show auction house prices in tooltips",	-95)
	CreateSingleOption(f, "ATR_tipsDisenchantOpt",	"Show disenchant prices in tooltips",	-120)

	local shift = CreateDropDown("Atr_tipsShiftDD", f, 50, -197)
	UIDropDownMenu_Initialize(shift, Atr_tipsShiftDD_Initialize)
	UIDropDownMenu_SetSelectedValue(shift, 1)
	UIDropDownMenu_JustifyText("LEFT", shift)

	local de = CreateDropDown("Atr_deDetailsDD", f, 50, -267)
	UIDropDownMenu_Initialize(de, Atr_deDetailsDD_Initialize)
	UIDropDownMenu_SetWidth(175, de)
	UIDropDownMenu_JustifyText("LEFT", de)
	UIDropDownMenu_SetSelectedValue(de, 1)
end

-----------------------------------------

do
	local f = CreatePanel("Atr_UCConfigFrame", "Undercutting")

	CreateLabel(f, "GameFontNormal",		"Buyout Price",				20,  -63)
	CreateLabel(f, "GameFontNormal",		"Undercut by",				165, -63)
	CreateLabel(f, "GameFontNormal",		"Starting Price Discount",	25,  -290)
	CreateLabel(f, "GameFontHighlight",	"percent",					240, -290)

	local amounts = { 5000000, 1000000, 200000, 50000, 10000, 2000, 500 }
	local i
	for i = 1, getn(amounts) do
		local name = "UC_" .. amounts[i]
		local line = CreateFrame("Frame", name, f)
		line:SetWidth(450); line:SetHeight(25)
		line:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -80 - ((i - 1) * 23))

		local range = line:CreateFontString(name .. "_RangeText", "BACKGROUND", "GameFontHighlight")
		range:SetWidth(145)
		range:SetJustifyH("LEFT")
		range:SetPoint("LEFT", line, "LEFT", 0, 0)

		local money = CreateFrame("Frame", name .. "_MoneyInput", line, "MoneyInputFrameTemplate")
		money:SetPoint("TOPLEFT", line, "TOPLEFT", 150, -5)
	end

	local eb = CreateFrame("EditBox", "Atr_Starting_Discount", f, "InputBoxTemplate")
	eb:SetWidth(24); eb:SetHeight(20)
	eb:SetPoint("TOPLEFT", f, "TOPLEFT", 210, -286)
	eb:SetAutoFocus(false)
	eb:SetNumeric(true)
	eb:SetFontObject(ChatFontNormal)
	eb:SetMaxBytes(64)

	local reset = CreateFrame("Button", "Atr_UCConfigFrame_Reset", f, "UIPanelButtonTemplate")
	reset:SetWidth(150); reset:SetHeight(22)
	reset:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 15)
	Tr(reset, "Reset to Default")
	reset:SetScript("OnClick", function()
		Atr_ResetSavedVars()
		Atr_SetupUCConfigFrame()
	end)
end

-----------------------------------------

function Atr_CreateStackingEntry(index, parent, y)

	local name = "Atr_StackList" .. index

	local row = CreateFrame("Button", name, parent)
	row:SetHeight(16)
	row:SetPoint("TOPLEFT",  parent, "TOPLEFT",  6, y)
	row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, y)

	local text = row:CreateFontString(name .. "_text", "BACKGROUND", "GameFontHighlightSmall")
	text:SetWidth(160); text:SetHeight(16)
	text:SetJustifyH("LEFT")
	text:SetPoint("LEFT", row, "LEFT", 12, 0)

	local info = row:CreateFontString(name .. "_info", "BACKGROUND", "GameFontHighlightSmall")
	info:SetHeight(16)
	info:SetJustifyH("LEFT")
	info:SetPoint("LEFT",  text, "RIGHT", 10, 0)
	info:SetPoint("RIGHT", row,  "RIGHT", 10, 0)

	row:SetHighlightTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight", "ADD")
	local h = row:GetHighlightTexture()
	if h then h:SetTexCoord(0.05, 0.07, 0.1, 0.5) end

	row:SetScript("OnClick",		function() Atr_StackingEntry_OnClick(this) end)
	row:SetScript("OnDoubleClick",	function() Atr_StackingEntry_OnDoubleClick(this) end)
	row:Hide()

	return row
end

do
	local f = CreatePanel("Atr_StackingOptionsFrame", "Selling", nil, "Configure how you typically like to sell the items listed below.")

	local scroll = CreateFrame("ScrollFrame", "Atr_Stacking_ScrollFrame", f, "FauxScrollFrameTemplate")
	scroll:SetHeight(240)
	scroll:SetPoint("TOPLEFT",  f, "TOPLEFT",  10, -95)
	scroll:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30, -95)
	scroll:SetScript("OnVerticalScroll", function()
		FauxScrollFrame_OnVerticalScroll(16, Atr_StackingList_Display)
	end)

	local list = CreateFrame("Frame", "Atr_Stacking_List", f)
	list:SetHeight(240)
	list:SetPoint("TOPLEFT",  f, "TOPLEFT",  10, -95)
	list:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30, -95)
	list:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })

	local edit = CreateSmallButton("Atr_StackingOptionsFrame_Edit", f, 80, 18)
	edit:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 5, -7)
	Tr(edit, "Edit")
	edit:SetScript("OnClick", function() Atr_StackingList_Edit_OnClick() end)

	local new = CreateSmallButton("Atr_StackingOptionsFrame_New", f, 80, 18)
	new:SetPoint("LEFT", edit, "RIGHT", 7, 0)
	Tr(new, "New")
	new:SetScript("OnClick", function() Atr_StackingList_New_OnClick() end)

	---------------------------------------

	local m = CreateFrame("Frame", "Atr_MemorizeFrame", f)
	m:SetWidth(430); m:SetHeight(250)
	m:SetPoint("TOPLEFT", f, "TOPLEFT", -100, -30)
	m:SetFrameStrata("FULLSCREEN_DIALOG")
	m:SetToplevel(true)
	m:EnableMouse(true)
	m:SetBackdrop({ bgFile = "Interface\\CharacterFrame\\UI-Party-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 } })
	m:SetScript("OnHide", function() HideInterfaceOptionsMask() end)
	m:Hide()

	local itemText = m:CreateFontString("Atr_Mem_itemName_text", "BACKGROUND", "GameFontNormalSmall")
	itemText:SetWidth(200); itemText:SetHeight(20)
	itemText:SetJustifyH("LEFT")
	itemText:SetPoint("TOPLEFT", m, "TOPLEFT", 40, -50)
	Tr(itemText, "Item Name")

	local itemStatic = m:CreateFontString("Atr_Mem_itemName_static", "BACKGROUND", "GameFontHighlight")
	itemStatic:SetWidth(300); itemStatic:SetHeight(20)
	itemStatic:SetJustifyH("LEFT")
	itemStatic:SetPoint("TOPLEFT", itemText, "TOPLEFT", 10, -20)

	local stacksOf = m:CreateFontString("Atr_Mem_stacksOf_text", "BACKGROUND", "GameFontNormal")
	stacksOf:SetWidth(120); stacksOf:SetHeight(30)
	stacksOf:SetJustifyH("RIGHT")
	stacksOf:SetPoint("TOPLEFT", m, "TOPLEFT", 165, -120)
	Tr(stacksOf, "stacks of")

	local ebName = CreateFrame("EditBox", "Atr_Mem_EB_itemName", m, "InputBoxTemplate")
	ebName:SetWidth(300); ebName:SetHeight(22)
	ebName:SetPoint("TOPLEFT", itemText, "TOPLEFT", 0, -20)
	ebName:SetAutoFocus(true)
	ebName:Hide()

	local numStacks = CreateFrame("Frame", "Atr_Mem_DD_numStacks", m, "UIDropDownMenuTemplate")
	numStacks:SetPoint("RIGHT", stacksOf, "LEFT", 60, -2)
	Atr_SONumStacks_OnLoad(numStacks)

	local ebSize = CreateFrame("EditBox", "Atr_Mem_EB_stackSize", m, "InputBoxTemplate")
	ebSize:SetWidth(40); ebSize:SetHeight(20)
	ebSize:SetPoint("LEFT", stacksOf, "RIGHT", 22, -1)
	ebSize:SetAutoFocus(false)
	ebSize:SetNumeric(true)
	ebSize:SetFontObject(ChatFontNormal)
	ebSize:SetMaxBytes(64)
	ebSize:SetJustifyH("CENTER")

	local forget = CreateSmallButton("Atr_Mem_Forget", m, 150, 18)
	forget:SetPoint("BOTTOMLEFT", m, "BOTTOMLEFT", 20, 18)
	forget:SetText("")
	forget:SetScript("OnClick", function()
		Atr_Memorize_Forget()
		Atr_MemorizeFrame:Hide()
	end)

	local cancel = CreateFrame("Button", "Atr_Mem_Cancel", m, "UIPanelButtonTemplate")
	cancel:SetWidth(80); cancel:SetHeight(22)
	cancel:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", -20, 17)
	cancel:SetText("CANCEL")
	cancel:SetScript("OnClick", function() Atr_MemorizeFrame:Hide() end)

	local okay = CreateFrame("Button", "Atr_Mem_Okay", m, "UIPanelButtonTemplate")
	okay:SetWidth(80); okay:SetHeight(22)
	okay:SetPoint("RIGHT", cancel, "LEFT", -3, 0)
	okay:SetText("OKAY")
	okay:SetScript("OnClick", function()
		Atr_Memorize_Save()
		Atr_MemorizeFrame:Hide()
	end)
end

-----------------------------------------

do
	local f = CreatePanel("Atr_ScanningOptionsFrame", "Scanning")

	local lf = CreateFrame("Frame", "Atr_scanLevelLabel", f)
	lf:SetWidth(160); lf:SetHeight(22)
	lf:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -62)
	lf:EnableMouse(true)
	lf:SetScript("OnEnter", function() Atr_scanLevelDD_showTip(this) end)
	lf:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local ls = lf:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	ls:SetPoint("LEFT", lf, "LEFT", 0, 0)
	Tr(ls, "Minimum quality level:")

	local dd = CreateDropDown("Atr_scanLevelDD", f, 160, -60)
	dd:SetWidth(220); dd:SetHeight(22)
	UIDropDownMenu_Initialize(dd, Atr_scanLevelDD_Initialize)
	UIDropDownMenu_SetSelectedValue(dd, 1)
	UIDropDownMenu_JustifyText("LEFT", dd)
	dd:SetScript("OnEnter", function() Atr_scanLevelDD_showTip(this) end)
	dd:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-----------------------------------------

do
	local f = CreatePanel("AuctionatorDescriptionFrame", "About", "About    OctoJAOAuctionator")

	local author = f:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
	author:SetJustifyH("LEFT"); author:SetJustifyV("TOP")
	author:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 30, 35)
	Tr(author, "Author:  Happyness")

	local version = f:CreateFontString("AuctionatorVersionText", "BACKGROUND", "GameFontDisableSmall")
	version:SetJustifyH("LEFT"); version:SetJustifyV("TOP")
	version:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 30, 20)

	local html = CreateFrame("SimpleHTML", "AuctionatorDescriptionHTML", f)
	html:SetWidth(320); html:SetHeight(120)
	html:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -70)
	html:SetFontObject(GameFontHighlightSmall)
	pcall(function() html:SetFontObject("h1", GameFontNormal) end)
end

-----------------------------------------

function Atr_CreateOptionsMask(parent)

	local m = CreateFrame("Frame", "Atr_Mask_StdOptions", parent)
	m:SetPoint("TOPLEFT",		parent, "TOPLEFT",		0, 0)
	m:SetPoint("BOTTOMRIGHT",	parent, "BOTTOMRIGHT",	0, 0)
	m:EnableMouse(true)
	m:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16 })
	m:SetBackdropColor(0.2, 0.2, 0.2)
	return m
end

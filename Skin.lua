-- Skin.lua: pfUI look for OctoAuctionator
-- Does nothing when pfUI is not installed/enabled.
-- strips the Blizzard art from every Auctionator frame and gives it the pfUI backdrop,
-- buttons,boxes, dropdowns, inputs, checkboxes, scrollbars and tabs with pfUIs own helpers
-- so it follows pfUI border / colour / font settings

local G = getfenv(0)

local done          = false
local optionsDone   = false
local hooked        = false

local P, cr, cg, cb
local border, bpad

-----------------------------------------
-- helpers
-----------------------------------------

local function Ready()
	if pfUI and pfUI.api and pfUI_config and pfUI_config.appearance and pfUI_config.appearance.border
	   and pfUI.api.CreateBackdrop and pfUI.api.SkinButton and pfUI.api.StripTextures then
		return true
	end
	return false
end

local function Report(where, err)
	if Atr_ReportError then
		Atr_ReportError("pfUI skin (" .. where .. "): " .. tostring(err))
	end
end

local function Try(where, fn, a1, a2, a3)
	local ok, err = pcall(fn, a1, a2, a3)
	if not ok then Report(where, err) end
end

local function ClassColor()
	local ok, r, g, b = pcall(function() return PFUI_CLASS_COLORS[UnitClassBase("player")]:GetRGB() end)
	if ok and r then return r, g, b end
	local _, class = UnitClass("player")
	local c = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
	if c then return c.r, c.g, c.b end
	return .2, 1, .8
end

local function Get(name)
	return getglobal(name)
end

-----------------------------------------
-- single widget skins
-----------------------------------------

local function SkinBtn(b)
	if type(b) == "string" then b = Get(b) end
	if not b or b.atrSkinned then return end
	b.atrSkinned = true
	Try("button " .. tostring(b:GetName()), function() P.SkinButton(b) end)
end

local function SkinEdit(e)
	if type(e) == "string" then e = Get(e) end
	if not e or e.atrSkinned then return end
	e.atrSkinned = true
	Try("editbox " .. tostring(e:GetName()), function()
		P.StripTextures(e, nil, "BACKGROUND")
		P.CreateBackdrop(e, nil, true)
		e:SetTextInsets(4, 4, 0, 0)
	end)
end

local function SkinCheck(c)
	if type(c) == "string" then c = Get(c) end
	if not c or c.atrSkinned then return end
	c.atrSkinned = true
	Try("checkbox " .. tostring(c:GetName()), function() P.SkinCheckbox(c, 22) end)
end

local function SkinDrop(d)
	if type(d) == "string" then d = Get(d) end
	if not d or d.atrSkinned then return end
	d.atrSkinned = true
	Try("dropdown " .. tostring(d:GetName()), function() P.SkinDropDown(d, nil, nil, nil, true) end)
end

local function SkinMoney(m)
	if type(m) == "string" then m = Get(m) end
	if not m or m.atrSkinned then return end
	m.atrSkinned = true
	Try("money input " .. tostring(m:GetName()), function() P.SkinMoneyInputFrame(m) end)
end

local function SkinScroll(sfName)
	local sf  = Get(sfName)
	local bar = Get(sfName .. "ScrollBar")
	if not sf or not bar or bar.atrSkinned then return end
	bar.atrSkinned = true
	Try("scrollbar " .. sfName, function()
		P.StripTextures(sf)
		P.SkinScrollbar(bar)
	end)
end

local function FlatHighlight(btn, a)
	local h = btn.GetHighlightTexture and btn:GetHighlightTexture()
	if not h then return end
	h:SetTexture(1, 1, 1, a or .08)
	h:SetTexCoord(0, 1, 0, 1)
	h:ClearAllPoints()
	h:SetAllPoints(btn)
end

local function SkinListRow(row)
	if not row or row.atrSkinned then return end
	row.atrSkinned = true
	Try("row " .. tostring(row:GetName()), function() FlatHighlight(row) end)
end

local function SkinSelTexture(row)
	local sel = row and row.atrSel
	if sel and not sel.atrSkinned then
		sel.atrSkinned = true
		sel:SetTexture(cr, cg, cb, .25)
		sel:SetTexCoord(0, 1, 0, 1)
		if sel.SetBlendMode then sel:SetBlendMode("BLEND") end
	end
end

local function FitIcon(b)
	local t = b and b.GetNormalTexture and b:GetNormalTexture()
	if t then
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT", b, "TOPLEFT", 3, -3)
		t:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
		t:SetTexCoord(.08, .92, .08, .92)
	end
end

local function SkinItemSlot(name)
	local b = Get(name)
	if not b or b.atrSkinned then return end
	b.atrSkinned = true
	Try("item slot " .. name, function()
		P.CreateBackdrop(b, nil, true)
		FlatHighlight(b, .15)
		if P.SetHighlight then P.SetHighlight(b, cr, cg, cb) end
		FitIcon(b)
	end)
end

local function SkinWindow(f, alpha, shadow)
	if type(f) == "string" then f = Get(f) end
	if not f or f.atrSkinned then return end
	f.atrSkinned = true
	Try("window " .. tostring(f:GetName()), function()
		P.StripTextures(f, true)
		P.CreateBackdrop(f, nil, nil, alpha or .9)
		if shadow then P.CreateBackdropShadow(f) end
	end)
end

-----------------------------------------
--child walker
-----------------------------------------

local function IsPanelButton(c)
	local nt = c.GetNormalTexture and c:GetNormalTexture()
	local path = nt and nt.GetTexture and nt:GetTexture()
	if type(path) == "string" and string.find(string.lower(path), "panel%-button") then
		return true
	end
	return false
end

local function Walk(f)
	local kids = { f:GetChildren() }
	for i = 1, getn(kids) do
		local c = kids[i]
		local t = c:GetObjectType()
		local n = c:GetName()

		if t == "EditBox" then
			SkinEdit(c)
		elseif t == "CheckButton" then
			SkinCheck(c)
		elseif t == "Button" then
			if IsPanelButton(c) then SkinBtn(c) end
		elseif t == "Frame" then
			if n and Get(n .. "Gold") and Get(n .. "Silver") and Get(n .. "Copper") then
				SkinMoney(c)
			elseif n and Get(n .. "Left") and Get(n .. "Middle") and Get(n .. "Button") and Get(n .. "Text") then
				SkinDrop(c)
			else
				Walk(c)
			end
		end
	end
end

-----------------------------------------
-- tab selection state
-----------------------------------------

local function TabState(tab, selected)
	if not tab or not tab.atrTabState or not tab.backdrop then return end
	if selected then
		tab.backdrop:SetBackdropBorderColor(cr, cg, cb, 1)
	else
		tab.backdrop:SetBackdropBorderColor(P.GetStringColor(pfUI_config.appearance.border.color))
	end
end

local function SkinAuctionTabs()
	local num = AuctionFrame.numTabs or 3

	for i = 4, num do
		local tab = Get("AuctionFrameTab" .. i)
		if tab and not tab.atrSkinned then
			tab.atrSkinned = true
			P.SkinTab(tab)
			tab:SetWidth(tab:GetTextWidth() + 20)
			if tab.GetFontString and tab:GetFontString() then
				tab:GetFontString():ClearAllPoints()
				tab:GetFontString():SetPoint("CENTER", 0, 0)
			end
			tab:ClearAllPoints()
			tab:SetPoint("LEFT", Get("AuctionFrameTab" .. (i - 1)), "RIGHT", border * 2 + 1, 0)
		end
	end

	for i = 1, num do
		local tab = Get("AuctionFrameTab" .. i)
		if tab then
			tab.atrTabState = true
			TabState(tab, i == AuctionFrame.selectedTab)
		end
	end
end

local function SkinListTabs()
	for i = 1, 3 do
		local tab = Get("Atr_ListTabsTab" .. i)
		if tab and not tab.atrSkinned then
			tab.atrSkinned = true
			P.SkinTab(tab)
			tab:SetWidth(tab:GetTextWidth() + 20)
			tab.atrTabState = true
		end
	end

	if Atr_ListTabs and Atr_HeadingsBar then
		Atr_ListTabs:ClearAllPoints()
		Atr_ListTabs:SetPoint("BOTTOMRIGHT", Atr_HeadingsBar, "TOPRIGHT", 0, -19)
	end
	PanelTemplates_SetTab(Atr_ListTabs, Atr_ListTabs.selectedTab or 1)
end

-----------------------------------------
-- function wrappers
-----------------------------------------

local function InstallHooks()
	if hooked then return end
	hooked = true

	local oSel, oDesel = G.PanelTemplates_SelectTab, G.PanelTemplates_DeselectTab
	if oSel and oDesel then
		G.PanelTemplates_SelectTab   = function(tab) oSel(tab);   TabState(tab, true)  end
		G.PanelTemplates_DeselectTab = function(tab) oDesel(tab); TabState(tab, false) end
	end

	local oRow = G.Atr_SetRowSelected
	if oRow then
		G.Atr_SetRowSelected = function(row, on)
			oRow(row, on)
			SkinSelTexture(row)
		end
	end

	local oTex = G.Atr_SetTextureButton
	if oTex then
		G.Atr_SetTextureButton = function(name, count, link)
			oTex(name, count, link)
			FitIcon(Get(name))
		end
	end

	local oEv = G.Atr_SellItemButton_OnEvent
	if oEv then
		G.Atr_SellItemButton_OnEvent = function(self, event)
			oEv(self, event)
			if Atr_SellControls_Tex then FitIcon(Atr_SellControls_Tex) end
		end
	end
end

-----------------------------------------
-- auction house panes
-----------------------------------------

local function SkinMain()
	Try("hlist", function()
		if Atr_Hlist then
			P.StripTextures(Atr_Hlist, true)
			P.CreateBackdrop(Atr_Hlist, nil, nil, .6)
			Atr_Hlist.backdrop:SetPoint("BOTTOMRIGHT", Atr_Hlist, "BOTTOMRIGHT", 22, -border)
		end
	end)
	SkinScroll("Atr_Hlist_ScrollFrame")

	SkinScroll("AuctionatorScrollFrame")
	for i = 1, 15 do
		local row = Get("AuctionatorEntry" .. i)
		if row then SkinListRow(row) end
	end

	local i = 1
	while Get("AuctionatorHEntry" .. i) do
		SkinListRow(Get("AuctionatorHEntry" .. i))
		i = i + 1
	end

	Try("headings", function()
		local bar = Atr_HeadingsBar
		if not bar then return end
		if Atr_HeadingsBarMiddle then Atr_HeadingsBarMiddle:Hide() end
		P.CreateBackdrop(bar)
		bar.backdrop:ClearAllPoints()
		bar.backdrop:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -21)
		bar.backdrop:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, -41)

		local c1, c3 = Atr_Col1_Heading_Button, Atr_Col3_Heading_Button
		local k
		for _, k in ipairs({ c1, c3 }) do
			if k then
				FlatHighlight(k, .08)
				local h = k:GetHighlightTexture()
				if h then h:SetHeight(20) end
			end
		end
	end)
	SkinBtn("Atr_Back_Button")
	SkinListTabs()

	Try("hilite", function()
		if Atr_Hilite1 then
			P.CreateBackdrop(Atr_Hilite1, nil, true)
			Atr_Hilite1:SetBackdropColor(cr, cg, cb, .12)
			Atr_Hilite1:SetBackdropBorderColor(cr, cg, cb, 1)
		end
	end)

	local buttons = { "Atr_Search_Button", "Auctionator1Button", "Atr_FullScanButton", "Atr_CheckActiveButton",
		"Atr_CancelAllUndercutsButton", "Atr_AddToSListButton", "Atr_RemFromSListButton", "Atr_DelSListButton",
		"Atr_NewSListButton", "Atr_CreateAuctionButton", "AuctionatorCloseButton", "Atr_CancelSelectionButton",
		"Atr_Buy1_Button" }
	for _, name in ipairs(buttons) do SkinBtn(name) end

	Try("button row", function()
		if Atr_CancelSelectionButton and AuctionatorCloseButton then
			Atr_CancelSelectionButton:ClearAllPoints()
			Atr_CancelSelectionButton:SetPoint("RIGHT", AuctionatorCloseButton, "LEFT", -2 * bpad, 0)
		end
		if Atr_Buy1_Button and Atr_CancelSelectionButton then
			Atr_Buy1_Button:ClearAllPoints()
			Atr_Buy1_Button:SetPoint("RIGHT", Atr_CancelSelectionButton, "LEFT", -2 * bpad, 0)
		end
	end)

	SkinEdit("Atr_Search_Box")
	SkinEdit("Atr_Batch_NumAuctions")
	SkinEdit("Atr_Batch_Stacksize")

	SkinMoney("Atr_StackPrice")
	SkinMoney("Atr_ItemPrice")
	SkinMoney("Atr_StartingPrice")

	SkinDrop("Atr_DropDown1")
	SkinDrop("Atr_DropDownSL")
	SkinDrop("Atr_Duration")

	SkinItemSlot("Atr_SellControls_Tex")
	SkinItemSlot("Atr_RecommendItem_Tex")
end

local function SkinDialogs()
	local dialogs = { "Atr_Error_Frame", "Atr_Confirm_Frame", "Atr_Buy_Confirm_Frame", "Atr_CheckActives_Frame",
		"Atr_CancelAuction_Confirm_Frame", "Atr_FullScanFrame" }

	for _, name in ipairs(dialogs) do
		local f = Get(name)
		if f then
			SkinWindow(f, .92, true)
			Try("dialog " .. name, Walk, f)
		end
	end

	if Atr_FullScanResults then SkinWindow(Atr_FullScanResults, .5, false) end

	Try("mask", function()
		if Atr_Mask then
			Atr_Mask:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8" })
			Atr_Mask:SetBackdropColor(0, 0, 0, .6)
			if AuctionFrame.backdrop then
				Atr_Mask:ClearAllPoints()
				Atr_Mask:SetPoint("TOPLEFT", AuctionFrame.backdrop, "TOPLEFT", 0, 0)
				Atr_Mask:SetPoint("BOTTOMRIGHT", AuctionFrame.backdrop, "BOTTOMRIGHT", 0, 0)
			end
		end
	end)
end

-----------------------------------------
-- options
-----------------------------------------

local function SkinOptions()
	if optionsDone or not Ready() or not Atr_OptionsWindow then return end
	optionsDone = true

	if not cr then cr, cg, cb = ClassColor() end
	P = pfUI.api

	local f = Atr_OptionsWindow
	SkinWindow(f, .92, true)

	for i = 1, 6 do SkinBtn("Atr_OptionsTab" .. i) end
	SkinBtn("Atr_OptionsOkay")
	SkinBtn("Atr_OptionsCancel")

	local panels = { "Atr_BasicOptionsFrame", "Atr_TooltipsOptionsFrame", "Atr_UCConfigFrame",
		"Atr_StackingOptionsFrame", "Atr_ScanningOptionsFrame", "AuctionatorDescriptionFrame" }
	for _, name in ipairs(panels) do
		local p = Get(name)
		if p then
			Try("panel " .. name, function()
				P.StripTextures(p, true)
				P.CreateBackdrop(p, nil, nil, .5)
				Walk(p)
			end)
		end
	end

	if Atr_Stacking_List then
		Try("stacking list", function() P.CreateBackdrop(Atr_Stacking_List, nil, true, .5) end)
		SkinScroll("Atr_Stacking_ScrollFrame")
		local i = 1
		while Get("Atr_StackList" .. i) do
			SkinListRow(Get("Atr_StackList" .. i))
			i = i + 1
		end
	end

	if Atr_MemorizeFrame then
		SkinWindow(Atr_MemorizeFrame, .95, true)
		Try("memorize", Walk, Atr_MemorizeFrame)
	end
end

-----------------------------------------
-- put it together
-----------------------------------------

local function Apply()
	if not Ready() then return true end

	if not (AuctionFrame and Atr_Main_Panel and AuctionFrameTab4 and Atr_Hlist and AuctionatorEntry1) then
		return false
	end

	P = pfUI.api
	cr, cg, cb = ClassColor()
	local raw, b = P.GetBorderSize()
	border = b
	bpad = raw > 1 and b - P.GetPerfectPixel() or P.GetPerfectPixel()

	InstallHooks()

	Try("tabs", SkinAuctionTabs)
	Try("main", SkinMain)
	Try("dialogs", SkinDialogs)

	for i = 1, 15 do SkinSelTexture(Get("AuctionatorEntry" .. i)) end
	local i = 1
	while Get("AuctionatorHEntry" .. i) do
		SkinSelTexture(Get("AuctionatorHEntry" .. i))
		i = i + 1
	end
	FitIcon(Atr_SellControls_Tex)
	FitIcon(Atr_RecommendItem_Tex)

	return true
end

-----------------------------------------
-- driver
-----------------------------------------

local pending, tick, waited = false, 0, 0

local driver = CreateFrame("Frame", "AtrPfuiSkinDriver")
driver:RegisterEvent("AUCTION_HOUSE_SHOW")
driver:RegisterEvent("ADDON_LOADED")
driver:SetScript("OnEvent", function()
	if done then return end
	if event == "AUCTION_HOUSE_SHOW" or (event == "ADDON_LOADED" and arg1 == "Blizzard_AuctionUI") then
		pending = true
		waited  = 0
	end
end)
driver:SetScript("OnUpdate", function()
	if not pending then return end
	tick = tick + arg1
	if tick < 0.1 then return end
	tick   = 0
	waited = waited + 0.1

	local ok, finished = pcall(Apply)
	if not ok then
		Report("apply", finished)
		pending = false
		done = true
	elseif finished then
		pending = false
		done = true
	elseif waited > 10 then
		pending = false
	end
end)

local oShowOptions = G.Atr_ShowOptions
if oShowOptions then
	G.Atr_ShowOptions = function()
		oShowOptions()
		if Ready() then Try("options", SkinOptions) end
	end
end

local oMask = G.ShowInterfaceOptionsMask
if oMask then
	G.ShowInterfaceOptionsMask = function()
		oMask()
		if Ready() and Atr_Mask_StdOptions and not Atr_Mask_StdOptions.atrSkinned then
			Atr_Mask_StdOptions.atrSkinned = true
			Atr_Mask_StdOptions:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8" })
			Atr_Mask_StdOptions:SetBackdropColor(0, 0, 0, .6)
		end
	end
end

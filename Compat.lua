AtrNS = AtrNS or {}

local G = getfenv(0)

----------------------------------------------------------------------

function Atr_strsplit(delim, str, pieces)
	if str == nil then return nil end
	local t, pos = {}, 1
	while true do
		local s, e = string.find(str, delim, pos, true)
		if (not s) or (pieces and getn(t) >= pieces - 1) then
			tinsert(t, string.sub(str, pos))
			break
		end
		tinsert(t, string.sub(str, pos, s - 1))
		pos = e + 1
	end
	return unpack(t)
end

function Atr_hooksecurefunc(a1, a2, a3)
	local tbl, name, fn
	if type(a1) == "string" then
		tbl, name, fn = G, a1, a2
	else
		tbl, name, fn = a1, a2, a3
	end
	local orig = tbl[name]
	if type(orig) ~= "function" then return end
	tbl[name] = function(p1, p2, p3, p4, p5, p6, p7, p8, p9)
		local r1, r2, r3, r4 = orig(p1, p2, p3, p4, p5, p6, p7, p8, p9)
		fn(p1, p2, p3, p4, p5, p6, p7, p8, p9)
		return r1, r2, r3, r4
	end
end


do
	local seen = {}

	function Atr_ReportError(msg)
		msg = tostring(msg)
		if seen[msg] then return end
		seen[msg] = true
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Auctionator error:|r " .. msg)
		end
	end

	local prev = (G.geterrorhandler and geterrorhandler()) or G._ERRORMESSAGE
	if G.seterrorhandler and prev then
		seterrorhandler(function(msg)
			if type(msg) == "string" and string.find(msg, "Auctionator") and not seen[msg] then
				seen[msg] = true
				if DEFAULT_CHAT_FRAME then
					DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Auctionator error:|r " .. msg)
				end
			end
			return prev(msg)
		end)
	end
end

function Atr_GetVersion()
	return "1.0.0"
end

----------------------------------------------------------------------

local linkByName = {}

function Atr_RememberItemLink(name, link)
	if name and link then linkByName[string.lower(name)] = link end
end

local function ItemIdOf(x)
	if type(x) == "number" then return x end
	if type(x) ~= "string" then return nil end
	local _, _, id = string.find(x, "item:(%d+)")
	if id then return tonumber(id) end
	local l = linkByName[string.lower(x)]
	if l then
		local _, _, id2 = string.find(l, "item:(%d+)")
		if id2 then return tonumber(id2) end
	end
	return nil
end

function Atr_ItemIdFromAnything(x)
	return ItemIdOf(x)
end

function Atr_GetSellValueById(id)
	if id and G.SellValues then
		local v = G.SellValues["item:" .. id]
		if v then return v end
	end
	return nil
end

function Atr_GetItemInfo(x)
	local id = ItemIdOf(x)
	if not id then return nil end
	local a, b, c, d, e, f, g, h, i, j = GetItemInfo("item:" .. id .. ":0:0:0")
	if not a then return nil end
	local name, link, rarity, ilevel, minLevel, itemType, subType, stack, equip, texture
	if type(e) == "string" then
		name, link, rarity, minLevel, itemType, subType, stack, equip, texture = a, b, c, d, e, f, g, h, i
	else
		name, link, rarity, ilevel, minLevel, itemType, subType, stack, equip, texture = a, b, c, d, e, f, g, h, i, j
	end
	if link then Atr_RememberItemLink(name, link) end
	return name, link, rarity, ilevel, minLevel, itemType, subType, stack, equip, texture, Atr_GetSellValueById(id)
end

function Atr_GetItemIcon(x)
	local _, _, _, _, _, _, _, _, _, texture = Atr_GetItemInfo(x)
	return texture
end

----------------------------------------------------------------------

function Atr_CursorIsItem()
	return CursorHasItem() and true or false
end

local function DropCursorAnywhere()
	if not CursorHasItem() then return end
	for bag = 0, 4 do
		for slot = 1, (GetContainerNumSlots(bag) or 0) do
			if not GetContainerItemLink(bag, slot) then
				PickupContainerItem(bag, slot)
				if not CursorHasItem() then return end
			end
		end
	end
	if G.ClearCursor then ClearCursor() end
end
Atr_DropCursorAnywhere = DropCursorAnywhere

local function LinkId(link)
	if not link then return nil end
	local _, _, id = string.find(link, "item:(%d+)")
	return id and tonumber(id) or nil
end

function Atr_SellSlotLink()
	local name, texture, count, quality, canUse, price, maxStack, link = GetAuctionSellItemInfo()
	if not name then return nil end
	if link then
		Atr_RememberItemLink(name, link)
		return link, name, count, maxStack, price
	end
	local l = linkByName[string.lower(name)]
	return l, name, count, maxStack, price
end

function Atr_CountItemInBags(itemName)
	local total, lockedCounts = 0, {}
	local lname = itemName and string.lower(itemName)
	for bag = 0, 4 do
		for slot = 1, (GetContainerNumSlots(bag) or 0) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local _, _, nm = string.find(link, "%[(.-)%]")
				if nm and string.lower(nm) == lname then
					local _, count, locked = GetContainerItemInfo(bag, slot)
					total = total + (count or 1)
					if locked then lockedCounts[count or 1] = true end
				end
			end
		end
	end
	local slotLink, slotName, slotCount = Atr_SellSlotLink()
	if slotName and string.lower(slotName) == lname and slotCount and not lockedCounts[slotCount] then
		total = total + slotCount
	end
	return total
end

----------------------------------------------------------------------

function Atr_QueryAuctionItems(name, minLevel, maxLevel, invType, itemClass, itemSubclass, page, usable, quality)
	if minLevel == "" then minLevel = nil end
	if maxLevel == "" then maxLevel = nil end
	if invType == 0 then invType = nil end
	if itemClass == 0 then itemClass = nil end
	if itemSubclass == 0 then itemSubclass = nil end
	if usable == 0 then usable = nil end
	if quality == 0 or quality == -1 then quality = nil end
	QueryAuctionItems(name or "", minLevel, maxLevel, invType, itemClass, itemSubclass, page or 0, usable, quality)
end

function Atr_CanSendAuctionQuery()
	local can = CanSendAuctionQuery()
	return can, false
end

AtrNS.durationMinutes = { 120, 480, 1440 }
AtrNS.durationText = { "6 hours", "24 hours", "72 hours" }

----------------------------------------------------------------------

local post = nil
local driver = CreateFrame("Frame", "AtrCompatDriver")
local acc = 0

local function FindStack(id, size)
	local best, bestCount
	for bag = 0, 4 do
		for slot = 1, (GetContainerNumSlots(bag) or 0) do
			local link = GetContainerItemLink(bag, slot)
			if link and LinkId(link) == id then
				local _, count, locked = GetContainerItemInfo(bag, slot)
				if count and not locked and count >= size then
					if count == size then return bag, slot, count end
					if not bestCount or count < bestCount then
						best = { bag, slot }
						bestCount = count
					end
				end
			end
		end
	end
	if best then return best[1], best[2], bestCount end
	return nil
end

local function ClearSlot()
	if not GetAuctionSellItemInfo() then return end
	if CursorHasItem() and G.ClearCursor then ClearCursor() end
	ClickAuctionSellItemButton()
	DropCursorAnywhere()
end

local function Finish(msg)
	local p = post
	post = nil
	if p and msg and G.Atr_OnAuctionMultiSellFailureMsg then
		Atr_OnAuctionMultiSellFailureMsg(msg)
	elseif msg and DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffAuctionator:|r " .. msg)
	end
	ClearSlot()
	if p and p.multi and p.done < p.n and G.Atr_OnAuctionMultiSellFailure then
		Atr_OnAuctionMultiSellFailure()
	end
end

local function FindFreeSlot()
    for b = 0, 4 do
        for s = 1, GetContainerNumSlots(b) do
            if not GetContainerItemLink(b, s) then return b, s end
        end
    end
    return nil
end
 
local function EnsureAuctionPages()
    if AuctionFrameBrowse and AuctionFrameBrowse.page == nil then
        AuctionFrameBrowse.page = 0
    end

    if AuctionFrameBid and AuctionFrameBid.page == nil then
        AuctionFrameBid.page = 0
    end

    if AuctionFrameAuctions and AuctionFrameAuctions.page == nil then
        AuctionFrameAuctions.page = 0
    end
end


local function Step()
    local p = post
    if not p then return end
    local now = GetTime()
    if not AtrNS.ahOpen and AuctionFrame and not AuctionFrame:IsVisible() then
        Finish("Auction house closed, posting stopped.")
        return
    end
    if p.state == "prep" then
        if now < p.t then return end
        local link, name, count = Atr_SellSlotLink()
        if name then
            if LinkId(link) == p.id and count == p.size then
                p.state = "ready"
                return
            end
            ClearSlot()
            p.t = now + 0.4
            return
        end
 
        local bag, slot, count2
        if p.presplit then
            local _, c = GetContainerItemInfo(p.presplit.bag, p.presplit.slot)
            if c == p.size then
                bag, slot, count2 = p.presplit.bag, p.presplit.slot, c
            end
            p.presplit = nil
        end
        if not bag then
            bag, slot, count2 = FindStack(p.id, p.size)
        end
        if not bag then
            Finish("Not enough items to finish posting (" .. p.done .. " of " .. p.n .. " posted).")
            return
        end
 
        if CursorHasItem() and G.ClearCursor then ClearCursor() end
        if count2 == p.size then
            PickupContainerItem(bag, slot)
            ClickAuctionSellItemButton()
            p.state = "placing"
            p.t = now
            p.nextclick = now + 0.2
        else
            local fb, fs = FindFreeSlot()
            if not fb then
                Finish("No free bag slot to split the stack into (" .. p.done .. " of " .. p.n .. " posted).")
                return
            end
            SplitContainerItem(bag, slot, p.size)
            PickupContainerItem(fb, fs)
            p.fbag, p.fslot = fb, fs
            p.state = "splitting"
            p.t = now
        end
    elseif p.state == "splitting" then
        local _, c = GetContainerItemInfo(p.fbag, p.fslot)
        if c == p.size then
            p.presplit = { bag = p.fbag, slot = p.fslot }
            p.state = "prep"
            p.t = now + 0.1
        elseif now - p.t > 3 then
            if CursorHasItem() then DropCursorAnywhere() end
            Finish("Could not split the stack (" .. p.done .. " of " .. p.n .. " posted).")
        end
    elseif p.state == "placing" then
        local link, name, count = Atr_SellSlotLink()
        if name and count == p.size then
            p.state = "ready"
        else
            if (not name) and CursorHasItem() and now >= (p.nextclick or 0) then
                ClickAuctionSellItemButton()
                p.nextclick = now + 0.25
            end
            if now - p.t > 3 then
                if CursorHasItem() then DropCursorAnywhere() end
                Finish("Could not place the item in the auction slot (" .. p.done .. " of " .. p.n .. " posted).")
            end
        end
    elseif p.state == "ready" then
        EnsureAuctionPages()
        Atr_SubmitCurrentAuction(p.bid, p.buyout, p.minutes)
        p.state = "posting"
        p.t = now
    elseif p.state == "posting" then
        local name = GetAuctionSellItemInfo()
        if (not name) and now - p.t > 0.3 then
            p.done = p.done + 1
            if p.multi and G.Atr_OnAuctionMultiSellUpdate then
                local sv1, sv2 = G.arg1, G.arg2
                G.arg1, G.arg2 = p.done, p.n
                Atr_OnAuctionMultiSellUpdate()
                G.arg1, G.arg2 = sv1, sv2
            end
            if p.done >= p.n then
                post = nil
            else
                p.state = "prep"
                p.t = now + 0.3
            end
        elseif now - p.t > 6 then
            Finish("The server did not confirm the auction (" .. p.done .. " of " .. p.n .. " posted).")
        end
    end
end



driver:SetScript("OnUpdate", function()
	if not post then return end
	acc = acc + arg1
	if acc < 0.1 then return end
	acc = 0
	Step()
end)

driver:RegisterEvent("UI_ERROR_MESSAGE")
driver:RegisterEvent("AUCTION_HOUSE_CLOSED")
driver:SetScript("OnEvent", function()
	if not post then return end
	if event == "AUCTION_HOUSE_CLOSED" then
		post = nil
	elseif event == "UI_ERROR_MESSAGE" and (post.state == "placing" or post.state == "ready" or post.state == "posting") then
		Finish("Posting stopped: " .. tostring(arg1))
	end
end)

function Atr_PostingInProgress()
	return post ~= nil
end

function Atr_StartAuction(startingBid, buyout, duration, stackSize, numStacks)
	if post then return end
	local link, name, count = Atr_SellSlotLink()
	local id = LinkId(link)
	stackSize = stackSize or count or 1
	numStacks = numStacks or 1
	if not name then return end
	local minutes = AtrNS.durationMinutes[duration] or duration or 1440
if numStacks == 1 and count == stackSize then
    Atr_SubmitCurrentAuction(startingBid, buyout, minutes)
    return
end

if not id then
    Atr_SubmitCurrentAuction(startingBid, buyout, minutes)
    return
end
	post = { id = id, size = stackSize, n = numStacks, done = 0, bid = startingBid, buyout = buyout,
		minutes = minutes, state = "prep", t = GetTime(), multi = (numStacks > 1) }
	if post.multi and G.Atr_OnAuctionMultiSellStart then Atr_OnAuctionMultiSellStart() end
end

function Atr_SubmitCurrentAuction(startingBid, buyout, minutes)
    StartAuction(startingBid, buyout, minutes)
end

----------------------------------------------------------------------

function Atr_SetRowSelected(row, on)
	local sel = row.atrSel
	if not sel then
		sel = row:CreateTexture(nil, "BACKGROUND")
		sel:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
		sel:SetAllPoints(row)
		local name = row:GetName() or ""
		if string.find(name, "^AuctionatorEntry") then
			sel:SetTexCoord(0.25, 0.35, 0.0, 0.6)
		else
			sel:SetTexCoord(0.15, 0.25, 0.0, 0.6)
			if sel.SetBlendMode then sel:SetBlendMode("ADD") end
		end
		row.atrSel = sel
	end
	if on then sel:Show() else sel:Hide() end
end

----------------------------------------------------------------------

local moneyFrames = 0

function Atr_CreateMoneyFrame(parent, moneyType)
	moneyFrames = moneyFrames + 1
	local f = CreateFrame("Frame", "AtrMoneyFrame" .. moneyFrames, parent, "SmallMoneyFrameTemplate")
	local saved = G.this
	G.this = f
	f.small = 1
	MoneyFrame_SetType(moneyType or "STATIC")
	G.this = saved
	return f
end

function Atr_SetMoney(frame, money)
	MoneyFrame_Update(frame:GetName(), money or 0)
end

local function TipHideMoney(tip, resetWidth)
	if tip.atrMoney then
		for i = 1, getn(tip.atrMoney) do tip.atrMoney[i]:Hide() end
	end
	tip.atrMoneyUsed = 0
	if resetWidth and tip.atrMinWidth then
		tip.atrMinWidth = nil
		tip:SetMinimumWidth(0)
	end
end

local function TipHook(tip)
	if tip.atrMoney then return end
	tip.atrMoney = {}
	local origHide = tip:GetScript("OnHide")
	tip:SetScript("OnHide", function()
		TipHideMoney(tip, true)
		if origHide then origHide() end
	end)
	Atr_hooksecurefunc(tip, "SetOwner", function(t) TipHideMoney(tip, true) end)
	Atr_hooksecurefunc(tip, "ClearLines", function(t) TipHideMoney(tip, true) end)
end

function Atr_TipBeginMoney(tip)
	TipHideMoney(tip, false)
end

function Atr_TipAddMoneyLine(tip, label, money)
	TipHook(tip)
	tip:AddDoubleLine(label, " ")
	local n = tip:NumLines()
	local used = (tip.atrMoneyUsed or 0) + 1
	tip.atrMoneyUsed = used
	local mf = tip.atrMoney[used]
	if not mf then
		mf = Atr_CreateMoneyFrame(tip, "STATIC")
		tip.atrMoney[used] = mf
	end
	Atr_SetMoney(mf, money)
	mf:ClearAllPoints()
	local tname = tip:GetName()
	local left = getglobal(tname .. "TextLeft" .. n)
	local right = getglobal(tname .. "TextRight" .. n)
	if right then
		mf:SetPoint("RIGHT", right, "RIGHT", 13, 0)
	elseif left then
		mf:SetPoint("LEFT", left, "RIGHT", 8, 0)
	end
	mf:Show()
	local need = (left and left:GetStringWidth() or 80) + mf:GetWidth() + 30
	if need > (tip.atrMinWidth or 0) then
		tip.atrMinWidth = need
		tip:SetMinimumWidth(need)
	end
end

function Atr_ShowRowStackMoney(row, money)
	local mf = row.atrStackMoney
	if not money then
		if mf then mf:Hide() end
		return
	end
	if not mf then
		mf = Atr_CreateMoneyFrame(row, "STATIC")
		mf:SetPoint("RIGHT", row, "LEFT", 573, 0)
		row.atrStackMoney = mf
	end
	Atr_SetMoney(mf, money)
	mf:Show()
end

function Atr_ShowDepositMoney(money, suffix)
	local mf = AtrNS.depositMoney
	if not money then
		if mf then mf:Hide() end
		return
	end
	if not mf then
		mf = Atr_CreateMoneyFrame(Atr_Deposit_Text:GetParent(), "STATIC")
		mf:SetPoint("LEFT", Atr_Deposit_Text, "RIGHT", 2, 0)
		local fs = mf:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		fs:SetPoint("LEFT", mf, "RIGHT", -8, 0)
		mf.atrSuffix = fs
		AtrNS.depositMoney = mf
	end
	Atr_SetMoney(mf, money)
	mf.atrSuffix:SetText(suffix or "")
	mf:Show()
end

----------------------------------------------------------------------


function Atr_ItemStackSize(link)
	if not link then return 0 end
	local _, _, _, _, _, _, _, stack = Atr_GetItemInfo(link)
	return stack or 0
end

function Atr_SortAuctionClearSort(kind)
end

do
	local origGetOffset = G.FauxScrollFrame_GetOffset
	if origGetOffset then
		function FauxScrollFrame_GetOffset(frame)
			return origGetOffset(frame) or 0
		end
	end
end

if not G.ClearCursor then
	function ClearCursor()
		if CursorHasItem() then Atr_DropCursorAnywhere() end
	end
end

if not G.UpdateAddOnMemoryUsage then
	function UpdateAddOnMemoryUsage() end
end
if not G.GetAddOnMemoryUsage then
	function GetAddOnMemoryUsage() return 0 end
end
if not G.GetAddOnMetadata then
	function GetAddOnMetadata() return Atr_GetVersion() end
end
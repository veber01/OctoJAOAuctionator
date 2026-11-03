local addonName, addonTable = "Auctionator", AtrNS; 
local zc = addonTable.zc;

-----------------------------------------

local function Atr_AppendHint (results, price, text, volume)

	if (price and price > 0) then
		local e = {};
		e.price		= price;
		e.text		= text;
		e.volume	= volume;
		
		table.insert (results, e);
	end

end

------------------------------------------------

function Atr_BuildHints (itemName)

	local results = {};

	local itemLink = Atr_GetItemLink (itemName);

	if (itemLink == nil and itemName == nil) then
		return results;
	end
	
	if (itemName ~= nil and gAtr_ScanDB[itemName] ~= nil) then
		Atr_AppendHint (results, gAtr_ScanDB[itemName], ZT("Auctionator scan data"));
	end
	
	local price = Atr_GetMostRecentSale(itemName);
	if (price ~= nil) then
		Atr_AppendHint (results, price, ZT("your most recent posting"));
	end

	return results;

end

-----------------------------------------

function Atr_ShowHints ()

	Atr_Col1_Heading:Hide();
	Atr_Col1_Heading_Button:Hide();
	Atr_Col3_Heading_Button:Hide();
	Atr_Col3_Heading:Hide();
	Atr_Col4_Heading:Hide();

	Atr_Col3_Heading:SetText (ZT("Source"));

	local currentPane = Atr_GetCurrentPane();

	currentPane.hints = Atr_BuildHints (currentPane.activeScan.itemName);
	
	local numrows = currentPane.hints and getn(currentPane.hints) or 0;

	if (numrows > 0) then
		Atr_Col1_Heading:Show();
		Atr_Col3_Heading:Show();
	end

	local line;
	local dataOffset;

	FauxScrollFrame_Update (AuctionatorScrollFrame, numrows, 12, 16);

	for line = 1,12 do

		dataOffset = line + FauxScrollFrame_GetOffset (AuctionatorScrollFrame);

		local lineEntry = getglobal ("AuctionatorEntry"..line);

		lineEntry:SetID(dataOffset);

		if (dataOffset <= numrows and currentPane.hints[dataOffset]) then

			local data = currentPane.hints[dataOffset];

			local lineEntry_item_tag = "AuctionatorEntry"..line.."_PerItem_Price";

			local lineEntry_item		= getglobal(lineEntry_item_tag);
			local lineEntry_itemtext	= getglobal("AuctionatorEntry"..line.."_PerItem_Text");
			local lineEntry_text		= getglobal("AuctionatorEntry"..line.."_EntryText");
			local lineEntry_stack		= getglobal("AuctionatorEntry"..line.."_StackPrice");

			lineEntry_item:Show();
			lineEntry_itemtext:Hide();
			lineEntry_stack:SetText	("");
			Atr_ShowRowStackMoney (lineEntry, nil);

			Atr_SetMFcolor (lineEntry_item_tag, true);

			MoneyFrame_Update (lineEntry_item_tag, zc.round(data.price) );

			local text = data.text;
			if (data.volume) then
				text = text.." ("..ZT("trade volume")..": "..data.volume..")";
			end
			
			lineEntry_text:SetText (text);
			lineEntry_text:SetTextColor (0.8, 0.8, 1.0);

			lineEntry:Show();
		else
			lineEntry:Hide();
		end
	end

	Atr_HighlightEntry (currentPane.hintsIndex);
end

-----------------------------------------

function Atr_SetMFcolor (frameName, blue)

	local r, g, b = 1, 1, 1;

	if (blue) then
		r, g, b = 0.7, 0.7, 1.0;
	end

	local names = { "GoldButtonText", "SilverButtonText", "CopperButtonText" };
	local i;

	for i = 1, 3 do
		local fs = getglobal (frameName..names[i]);
		if (fs) then
			fs:SetTextColor (r, g, b);
		end
	end
end

-----------------------------------------

function Atr_GetAuctionPrice (item)

	local itemName;
	
	if (type (item) == "number") then
		itemName = Atr_GetItemInfo (item);
	else
		itemName = item;
	end

	if (itemName == nil) then
		return nil;
	end

	if (gAtr_ScanDB[itemName]) then
		return gAtr_ScanDB[itemName];
	end
	
	return Atr_GetMostRecentSale (itemName);
end	

-----------------------------------------

local function ShowTipWithPricing (tip, link, num)

	Atr_TipBeginMoney (tip);


	if (link == nil) then
		return;
	end

	local itemName, _, _, _, _, _, _, _, _, _, itemVendorPrice = Atr_GetItemInfo (link);

	local itemID = zc.ItemIDfromLink (link);
	itemID = tonumber(itemID);
	
	local vendorPrice	= 0;
	local auctionPrice	= 0;
	
	if (AUCTIONATOR_V_TIPS == 1) then vendorPrice	= itemVendorPrice; end;
	if (AUCTIONATOR_A_TIPS == 1) then auctionPrice	= Atr_GetAuctionPrice (itemName); end;
	
	local xstring = "";
	local showStackPrices = IsShiftKeyDown();
	
	if (AUCTIONATOR_SHIFT_TIPS == 2) then
		showStackPrices = not IsShiftKeyDown();
	end

	if (num and showStackPrices) then
		if (auctionPrice)	then	auctionPrice = auctionPrice * num;	end;
		if (vendorPrice)	then	vendorPrice  = vendorPrice  * num;	end;
		xstring = "|cFFAAAAFF x"..num.."|r";
	end;

	if (vendorPrice == nil) then
		vendorPrice = 0;
	end

	if (AUCTIONATOR_V_TIPS == 1 and vendorPrice > 0) then
		Atr_TipAddMoneyLine (tip, ZT("Vendor")..xstring, vendorPrice)
	end

	if (AUCTIONATOR_A_TIPS == 1) then
		
		local bonding = Atr_GetBonding(itemID);
		local isBOP   = (bonding == 1);
		local isQuest = (bonding == 4 or bonding == 5);
		
		if (isBOP) then
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("BOP").."  ");		
		elseif (isQuest) then
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("Quest Item").."  ");		
		elseif (auctionPrice ~= nil) then
			Atr_TipAddMoneyLine (tip, ZT("Auction")..xstring, auctionPrice);
		else
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("unknown").."  ");
		end
	end

	tip:Show()
end

-----------------------------------------

local function Atr_SafeTipHook (tip, method, fn)

	Atr_hooksecurefunc (tip, method, function (t, a, b, c, d)
		local ok, err = pcall (fn, t, a, b, c, d);
		if (not ok) then
			Atr_ReportError ("tooltip "..method..": "..tostring(err));
		end
	end);
end

-----------------------------------------

Atr_SafeTipHook (GameTooltip, "SetBagItem",
	function(tip, bag, slot)
		local _, num = GetContainerItemInfo(bag, slot);
		ShowTipWithPricing (tip, GetContainerItemLink(bag, slot), num);
	end
);

Atr_SafeTipHook (GameTooltip, "SetAuctionItem",
	function (tip, type, index)
		local _, _, num = GetAuctionItemInfo(type, index);
		ShowTipWithPricing (tip, GetAuctionItemLink(type, index), num);
	end
);

Atr_SafeTipHook (GameTooltip, "SetAuctionSellItem",
	function (tip)
		local link, name, count = Atr_SellSlotLink();
		ShowTipWithPricing (tip, link, count);
	end
);

Atr_SafeTipHook (GameTooltip, "SetLootItem",
	function (tip, slot)
		if LootSlotIsItem(slot) then
			local _, _, num = GetLootSlotInfo(slot);
			ShowTipWithPricing (tip, GetLootSlotLink(slot), num);
		end
	end
);

Atr_SafeTipHook (GameTooltip, "SetLootRollItem",
	function (tip, slot)
		local _, _, num = GetLootRollItemInfo(slot);
		ShowTipWithPricing (tip, GetLootRollItemLink(slot), num);
	end
);

Atr_SafeTipHook (GameTooltip, "SetInventoryItem",
	function (tip, unit, slot)
		ShowTipWithPricing (tip, GetInventoryItemLink(unit, slot), GetInventoryItemCount(unit, slot));
	end
);

Atr_SafeTipHook (GameTooltip, "SetTradeSkillItem",
	function (tip, skill, id)
		local link = GetTradeSkillItemLink(skill);
		local num  = GetTradeSkillNumMade(skill);
		if id then
			local _, _, reagentNum = GetTradeSkillReagentInfo(skill, id);
			link = GetTradeSkillReagentItemLink(skill, id);
			num = reagentNum;
		end

		ShowTipWithPricing (tip, link, num);
	end
);

Atr_SafeTipHook (GameTooltip, "SetTradePlayerItem",
	function (tip, id)
		local _, _, num = GetTradePlayerItemInfo(id);
		ShowTipWithPricing (tip, GetTradePlayerItemLink(id), num);
	end
);

Atr_SafeTipHook (GameTooltip, "SetTradeTargetItem",
	function (tip, id)
		local _, _, num = GetTradeTargetItemInfo(id);
		ShowTipWithPricing (tip, GetTradeTargetItemLink(id), num);
	end
);

Atr_SafeTipHook (GameTooltip, "SetQuestItem",
	function (tip, type, index)
		local _, _, num = GetQuestItemInfo(type, index);
		ShowTipWithPricing (tip, GetQuestItemLink(type, index), num);
	end
);

Atr_SafeTipHook (GameTooltip, "SetQuestLogItem",
	function (tip, type, index)
		local num, _;
		if type == "choice" then
			_, _, num = GetQuestLogChoiceInfo(index);
		else
			_, _, num = GetQuestLogRewardInfo(index)
		end

		ShowTipWithPricing (tip, GetQuestLogItemLink(type, index), num);
	end
);

Atr_SafeTipHook (GameTooltip, "SetHyperlink",
	function (tip, itemstring, num)
		local name, link = Atr_GetItemInfo (itemstring);
		ShowTipWithPricing (tip, link, num);
	end
);

Atr_SafeTipHook (ItemRefTooltip, "SetHyperlink",
	function (tip, itemstring)
		local name, link = Atr_GetItemInfo (itemstring);
		ShowTipWithPricing (tip, link);
	end
);
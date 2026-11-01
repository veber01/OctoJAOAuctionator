local addonName, addonTable = "Auctionator", AtrNS; 
local zc = addonTable.zc;

KM_NULL_STATE	= 0;
KM_PREQUERY		= 1;
KM_INQUERY		= 2;
KM_POSTQUERY	= 3;
KM_ANALYZING	= 4;
KM_SETTINGSORT	= 5;

local AUCTION_CLASS_WEAPON = 1;
local AUCTION_CLASS_ARMOR  = 2;

local gAllScans = {};

local BIGNUM = 999999999999;

local ATR_SORTBY_NAME_ASC = 0;
local ATR_SORTBY_NAME_DES = 1;
local ATR_SORTBY_PRICE_ASC = 2;
local ATR_SORTBY_PRICE_DES = 3;

-----------------------------------------

AtrScan = {};
AtrScan.__index = AtrScan;

-----------------------------------------

AtrSearch = {};
AtrSearch.__index = AtrSearch;

-----------------------------------------

function Atr_NewSearch (itemName, exact, rescanThreshold, callback)

	local srch = {};
	setmetatable (srch, AtrSearch);
	srch:Init (itemName, exact, rescanThreshold, callback);

	return srch;
end

-----------------------------------------

function AtrSearch:Init (searchText, exact, rescanThreshold, callback)

	if (searchText == nil) then
		searchText = "";
	end

	self.origSearchText = searchText;
	
	if (not exact) then
		if (zc.StringStartsWith (searchText, "\"") and zc.StringEndsWith (searchText, "\"")) then
			searchText = string.sub (searchText, 2, string.len(searchText)-1);
			exact = true;
		end
	end		

	self.searchText			= searchText;
	self.exact				= exact;
	self.processing_state	= KM_NULL_STATE
	self.current_page		= -1
	self.items				= {};
	self.query				= Atr_NewQuery();
	self.sortedScans		= nil;
	self.sortHow			= ATR_SORTBY_PRICE_ASC;
	self.callback			= callback;
	
	if (exact) then	

		if (rescanThreshold and rescanThreshold > 0) then
			local scan = Atr_FindScan (searchText);
			if (scan and (time() - scan.whenScanned) <= rescanThreshold) then
				self.items[searchText] = scan;
			end
		end
		
		if (not self.items[searchText]) then		
			self.items[searchText] = Atr_FindScanAndInit (searchText);
		end
	end
end

-----------------------------------------

function Atr_FindScanAndInit (itemName)

	return Atr_FindScan (itemName, true);
end

-----------------------------------------

function Atr_FindScan (itemName, init)

	if (itemName == nil or itemName == "") then
		itemName = "nil";
	end

	local itemNameLC = string.lower (itemName);

	if (gAllScans[itemNameLC] == nil) then

		local scn = {};
		setmetatable (scn, AtrScan);
		scn:Init (itemName);

		gAllScans[itemNameLC] = scn;
	elseif (init) then
		gAllScans[itemNameLC]:Init (itemName);
	end
	return gAllScans[itemNameLC];
end

-----------------------------------------

function Atr_ClearScanCache ()

	for a,v in pairs (gAllScans) do
		if (a ~= "nil") then
			gAllScans[a] = nil;
		end
	end

end

-----------------------------------------

local function Atr_SaveScannedItemMetadata (name, texture, itemLink, quality)
    if (type(name) ~= "string" or name == "") then return; end

    if (type(AUCTIONATOR_SEARCH_METADATA) ~= "table") then
        AUCTIONATOR_SEARCH_METADATA = {};
    end

    local metadata = AUCTIONATOR_SEARCH_METADATA[name];
    if (type(metadata) ~= "table") then
        metadata = {};
        AUCTIONATOR_SEARCH_METADATA[name] = metadata;
    end

    if (type(quality) == "number" and quality >= 0 and quality <= 6) then
        metadata.quality = quality;
    end

    if (type(texture) == "string" and texture ~= "") then
        metadata.texture = texture;
    end

    local itemId;
    if (Atr_ItemIdFromAnything) then
        itemId = Atr_ItemIdFromAnything (itemLink);
    end
    if (not itemId and itemLink) then
        local _, _, idText = string.find (itemLink, "item:(%d+)");
        itemId = tonumber (idText);
    end
    if (not itemId) then
        itemId = tonumber (metadata.id);
    end
    if (not itemId or itemId <= 0) then return; end

    metadata.id = itemId;

    if (Atr_GetItemInfo and (not metadata.category or not metadata.subcategory or not metadata.texture)) then
        local _, _, _, _, _, category, subcategory, _, _, itemTexture = Atr_GetItemInfo (itemId);
        if (category and category ~= "") then metadata.category = category; end
        if (subcategory and subcategory ~= "") then metadata.subcategory = subcategory; end
        if (not metadata.texture and type(itemTexture) == "string" and itemTexture ~= "") then
            metadata.texture = itemTexture;
        end
    end
end

-----------------------------------------

function AtrScan:Init (itemName)
	self.itemName			= itemName;
	self.itemLink			= nil;
	self.scanData			= {};
	self.sortedData			= {};
	self.whenScanned		= 0;
	self.lowprices			= {BIGNUM, BIGNUM, BIGNUM};
	self.absoluteBest		= nil;
	self.itemClass			= 0;
	self.itemSubclass		= 0;
	self.yourBestPrice		= nil;
	self.yourWorstPrice		= nil;
	self.numYourSingletons	= 0;
	self.itemTextColor 		= { 1.0, 1.0, 1.0 };
	self.searchWasExact		= false;
	
	self:UpdateItemLink (Atr_GetItemLink (itemName));
end

-----------------------------------------

function AtrScan:UpdateItemLink (itemLink)

	self.itemLink = itemLink;
	
	if (itemLink) then
	
		Atr_AddToItemLinkCache (self.itemName, itemLink);

		local _, _, quality, _, _, sType, sSubType = Atr_GetItemInfo (itemLink);

		self.itemQuality	= quality;
		self.itemClass		= Atr_ItemType2AuctionClass (sType);
		self.itemSubclass	= Atr_SubType2AuctionSubclass (self.itemClass, sSubType);	

		self.itemTextColor = { 1.0, 1.0, 1.0 };

		if (quality == 0)	then	self.itemTextColor = { 0.6, 0.6, 0.6 };	end
		if (quality == 2)	then	self.itemTextColor = { 0.2, 1.0, 0.0 };	end
		if (quality == 3)	then	self.itemTextColor = { 0.0, 0.5, 1.0 };	end
		if (quality == 4)	then	self.itemTextColor = { 0.7, 0.3, 1.0 };	end
	end
end

-----------------------------------------

function AtrSearch:NumScans()

	if (self.sortedScans) then
		return getn(self.sortedScans);
	end

	local count = 0;
	for name,scn in pairs (self.items) do
		count = count + 1;
	end

	return count;
end

-----------------------------------------

function AtrSearch:NumSortedScans()

	if (self.sortedScans) then
		return getn(self.sortedScans);
	end

	return 0;
end

-----------------------------------------

function AtrSearch:GetFirstScan()

	if (self.sortedScans) then
		return self.sortedScans[1];
	end

	for name,scn in pairs (self.items) do
		return scn;
	end
	
	return nil;

end

-----------------------------------------

function AtrSearch:Start ()

	if (self.searchText == "") then
		return;
	end
	
	if (self:IsCompoundSearch (self.searchText)) then
			
		local _, itemClass = self:ParseCompoundSearch (self.searchText);
	
		if (itemClass == 0) then
			Atr_Error_Display (ZT("The first part of this compound\n\nsearch is not a valid category."));
			return;
		end
	end
	
	self.processing_state = KM_SETTINGSORT;
	
	Atr_SortAuctionClearSort ("list");

	BrowseName:SetText (self.searchText);

	self.current_page		= 0;
	self.processing_state	= KM_PREQUERY;
	self:Continue();
end

-----------------------------------------

function AtrSearch:Abort ()

	if (self.processing_state == KM_NULL_STATE) then
		return;
	end

	self.processing_state = KM_NULL_STATE;
	self:Init();
end

-----------------------------------------

function AtrSearch:CheckForDuplicatePage ()

	local isDup = self.query:CheckForDuplicatePage(self.current_page);

	if (isDup) then
		self.current_page	= self.current_page - 1;   -- requery the page
		
		self.processing_state = KM_PREQUERY;
	end
		
	return isDup;
end

-----------------------------------------

function AtrSearch:AnalyzeResultsPage()

	self.processing_state = KM_ANALYZING;

	if (self.query.numDupPages > 10) then
		return true;
	end

	local numBatchAuctions, totalAuctions = GetNumAuctionItems("list");

	self.totalPages = math.ceil (totalAuctions / 50);

	if (self.current_page == 1 and totalAuctions > 2000) then
		Atr_Error_Display (ZT("Too many results\n\nPlease narrow your search"));
		return true;
	end

	if (totalAuctions >= 50) then
		Atr_SetMessage (string.format (ZT("Scanning auctions: page %d"), self.current_page).." / "..self.totalPages);
	end

	local numNilOwners = 0;

	if (numBatchAuctions > 0) then

		local x;

		for x = 1, numBatchAuctions do

			local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", x);

			if (owner == nil) then
				numNilOwners = numNilOwners + 1;
			end
			
			local exactMatch = zc.StringSame (name, self.searchText);

			if (exactMatch or not self.exact) then

				if (self.items[name] == nil) then
					self.items[name] = Atr_FindScanAndInit (name);
				end
				
				local curpage = (tonumber(self.current_page)-1);

				local scn = self.items[name];

				scn:AddScanItem (name, count, buyoutPrice, owner, 1, curpage);
				
				if (scn.itemLink == nil or self.itemClass == nil) then
					scn:UpdateItemLink (GetAuctionItemLink("list", x));
				end

                -- Save the live auction icon and item ID for offline search.
                local itemLink = GetAuctionItemLink ("list", x);
                Atr_SaveScannedItemMetadata (name, texture, itemLink or scn.itemLink, quality);

				if (self.callback) then
					self.callback (x, numBatchAuctions, count, buyoutPrice, owner);
				end
				
			end
		end
	end
	
	local done = (numBatchAuctions < 50);

	if (not done) then
		self.processing_state = KM_PREQUERY;
	end
	
	return done;
end

-----------------------------------------

function AtrScan:AddScanItem (name, stackSize, buyoutPrice, owner, numAuctions, curpage)

	local sd = {};
	local i;

	if (numAuctions == nil) then
		numAuctions = 1;
	end

	for i = 1, numAuctions do
		sd["stackSize"]		= stackSize;
		sd["buyoutPrice"]	= buyoutPrice;
		sd["owner"]			= owner;
		sd["pagenum"]		= curpage;

		tinsert (self.scanData, sd);
		
		local itemPrice = math.floor (buyoutPrice / stackSize);

		Atr_AddToLowPrices (self.lowprices, itemPrice);
	end
end

-----------------------------------------

function AtrScan:SubtractScanItem (name, stackSize, buyoutPrice)

	local sd;
	local i;

	for i,sd in ipairs (self.scanData) do
		
		if (sd.stackSize == stackSize and sd.buyoutPrice == buyoutPrice) then
			
			tremove (self.scanData, i);
			return;
		end
	end
end

-----------------------------------------

function AtrSearch:IsCompoundSearch (searchString)
	
	return zc.StringContains (searchString, ">");
end

-----------------------------------------

function AtrSearch:ParseCompoundSearch (searchString)

	local tbl	= { Atr_strsplit (">", searchString) };
	
	local queryString	= "";
	local itemClass		= 0;
	local itemSubclass	= 0;
	local minLevel		= nil;
	local maxLevel		= nil;
	local prevWasItemClass;
	local n;
	
	for n = 1,getn(tbl) do
		local s = tbl[n];

		local handled = false;

		if (not handled and tonumber(s)) then
			if (minLevel == nil) then
				minLevel = tonumber(s);
			elseif (maxLevel == nil) then
				maxLevel = tonumber(s);
			end
			
			handled = true;
			prevWasItemClass = false;
		end
		
		if (not handled and prevWasItemClass and itemSubclass == 0) then
			itemSubclass = Atr_SubType2AuctionSubclass (itemClass, s);
			if (itemSubclass > 0) then
				handled = true;
				prevWasItemClass = false;
			end
		end
		
		if (not handled and itemClass == 0) then
			itemClass = Atr_ItemType2AuctionClass (s);
			if (itemClass > 0) then
				prevWasItemClass = true;
				handled = true;
			end
		end
		
		if (not handled) then
			queryString = s;
			handled = true;
		end
	end	

	return queryString, itemClass, itemSubclass, minLevel, maxLevel;
end

-----------------------------------------

function AtrSearch:Continue()

	if (Atr_CanSendAuctionQuery ()) then

		self.processing_state = KM_IN_QUERY;

		local queryString = self.searchText;

		queryString = zc.UTF8_Truncate (queryString,63);
		
		local itemClass		= 0;
		local itemSubclass	= 0;
		local minLevel		= nil;
		local maxLevel		= nil;

		if (self:IsCompoundSearch(queryString)) then
		
			queryString, itemClass, itemSubclass, minLevel, maxLevel = self:ParseCompoundSearch (queryString);
		
		end

		Atr_QueryAuctionItems (queryString, minLevel, maxLevel, nil, itemClass, itemSubclass, self.current_page, nil, nil);

		self.query_sent_when	= gAtr_ptime;
		self.namesWaitStart		= nil;
		self.processing_state	= KM_POSTQUERY;
		self.current_page		= self.current_page + 1;
	end
end

-----------------------------------------

local gSortScansBy;

local function Atr_SortScans (x, y)

	if (gSortScansBy == ATR_SORTBY_NAME_ASC) then		return string.lower (x.itemName) < string.lower (y.itemName);	end
	if (gSortScansBy == ATR_SORTBY_NAME_DES) then		return string.lower (x.itemName) > string.lower (y.itemName);	end

	local xprice = 0;
	local yprice = 0;
	
	if (x.absoluteBest) then	xprice = zc.round(x.absoluteBest.buyoutPrice/x.absoluteBest.stackSize);		end;
	if (y.absoluteBest) then	yprice = zc.round(y.absoluteBest.buyoutPrice/y.absoluteBest.stackSize);		end;
	
	if (gSortScansBy == ATR_SORTBY_PRICE_ASC) then		return xprice < yprice;		end
	if (gSortScansBy == ATR_SORTBY_PRICE_DES) then		return xprice > yprice;		end
end

-----------------------------------------

function AtrSearch:Finish()

	local finishTime = time();
	
	self.processing_state	= KM_NULL_STATE;
	self.current_page		= -1;
	self.query_sent_when	= nil;
	
	self.sortedScans = nil;
	
	local wasExactSearch = (self:NumScans() == 1);
	
	local x = 1;
	self.sortedScans = {};
	
	for name,scn in pairs (self.items) do
	
		self.sortedScans[x] = scn;
		x = x + 1;
		
		scn.whenScanned		= finishTime;
		scn.searchWasExact	= wasExactSearch;

		scn:CondenseAndSort ();

		local newprice = Atr_CalcNewDBprice (scn.itemName, scn.lowprices);
		
		if (newprice > 0) then
			if (scn.itemQuality + 1 >= AUCTIONATOR_SCAN_MINLEVEL) then
				gAtr_ScanDB[scn.itemName] = newprice;
				if (type(AUCTIONATOR_SEARCH_METADATA) ~= "table") then AUCTIONATOR_SEARCH_METADATA = {}; end
				local itemId = AtrNS and AtrNS.zc and AtrNS.zc.ItemIDfromLink and AtrNS.zc.ItemIDfromLink (scn.itemLink);
				if (itemId and tonumber (itemId) and tonumber (itemId) > 0) then
					if (type(AUCTIONATOR_SEARCH_METADATA[scn.itemName]) ~= "table") then AUCTIONATOR_SEARCH_METADATA[scn.itemName] = {}; end
					AUCTIONATOR_SEARCH_METADATA[scn.itemName].id = tonumber (itemId);
                    local _, _, _, _, _, itemType, itemSubType, _, _, texture = Atr_GetItemInfo (tonumber(itemId));
                    local metadata = AUCTIONATOR_SEARCH_METADATA[scn.itemName];
                    if (itemType) then metadata.category = itemType; end
                    if (itemSubType) then metadata.subcategory = itemSubType; end
                    if (texture) then metadata.texture = texture; end
				end
			end
		end
	end
	
	Atr_ClearBrowseListings();
	gSortScansBy = self.sortHow;
	table.sort (self.sortedScans, Atr_SortScans);
end

-----------------------------------------

function AtrSearch:UpdatePartial()

	local single = (self:NumScans() == 1);
	local x = 1;

	self.sortedScans = {};

	for name,scn in pairs (self.items) do
		self.sortedScans[x] = scn;
		x = x + 1;
		scn.searchWasExact = single;
		scn:CondenseAndSort ();
	end

	gSortScansBy = self.sortHow;
	table.sort (self.sortedScans, Atr_SortScans);
end

-----------------------------------------

function AtrSearch:IsActive()
	return (self.processing_state ~= KM_NULL_STATE);
end

-----------------------------------------

function AtrSearch:Pause()

	if (self.processing_state == KM_POSTQUERY or self.processing_state == KM_IN_QUERY) then
		self.current_page		= self.current_page - 1;
		self.processing_state	= KM_PREQUERY;
	end

	self.namesWaitStart = nil;
end

-----------------------------------------

function AtrSearch:ClickPriceCol()

	if (self.sortHow == ATR_SORTBY_PRICE_ASC) then
		self.sortHow = ATR_SORTBY_PRICE_DES;
	else
		self.sortHow = ATR_SORTBY_PRICE_ASC;
	end

	gSortScansBy = self.sortHow;
	table.sort (self.sortedScans, Atr_SortScans);

end

-----------------------------------------

function AtrSearch:ClickNameCol()

	if (self.sortHow == ATR_SORTBY_NAME_ASC) then
		self.sortHow = ATR_SORTBY_NAME_DES;
	else
		self.sortHow = ATR_SORTBY_NAME_ASC;
	end

	gSortScansBy = self.sortHow;
	table.sort (self.sortedScans, Atr_SortScans);
end

-----------------------------------------

function AtrSearch:UpdateArrows()

	Atr_Col1_Heading_ButtonArrow:Hide();
	Atr_Col3_Heading_ButtonArrow:Hide();
	
	if (self.sortHow == ATR_SORTBY_PRICE_ASC) then
		Atr_Col1_Heading_ButtonArrow:Show();
		Atr_Col1_Heading_ButtonArrow:SetTexCoord(0, 0.5625, 0, 1.0);
	elseif (self.sortHow == ATR_SORTBY_PRICE_DES) then
		Atr_Col1_Heading_ButtonArrow:Show();
		Atr_Col1_Heading_ButtonArrow:SetTexCoord(0, 0.5625, 1.0, 0);
	elseif (self.sortHow == ATR_SORTBY_NAME_ASC) then
		Atr_Col3_Heading_ButtonArrow:Show();
		Atr_Col3_Heading_ButtonArrow:SetTexCoord(0, 0.5625, 0, 1.0);
	elseif (self.sortHow == ATR_SORTBY_NAME_DES) then
		Atr_Col3_Heading_ButtonArrow:Show();
		Atr_Col3_Heading_ButtonArrow:SetTexCoord(0, 0.5625, 1.0, 0);
	end
end

-----------------------------------------

function Atr_ClearBrowseListings()

end

-----------------------------------------

function Atr_SortAuctionData (x, y)

	if (gAtr_PriceSortDesc) then
		return x.itemPrice > y.itemPrice;
	end

	return x.itemPrice < y.itemPrice;
end

-----------------------------------------

function AtrScan:CondenseAndSort ()

	self.sortedData	= {};

	local i,sd;
	local conddata = {};

	for i,sd in ipairs (self.scanData) do

		local ownerCode = "x";
		local dataType  = "n";		-- normal
		
		if (sd.owner == UnitName("player")) then
			ownerCode = "y";
		end

		local key = "_"..sd.stackSize.."_"..sd.buyoutPrice.."_"..ownerCode..dataType;

		if (conddata[key]) then
			conddata[key].count		= conddata[key].count + 1;
			conddata[key].minpage 	= zc.Min (conddata[key].minpage, sd.pagenum);
			conddata[key].maxpage 	= zc.Max (conddata[key].maxpage, sd.pagenum);
		else
			local data = {};

			data.stackSize 		= sd.stackSize;
			data.buyoutPrice	= sd.buyoutPrice;
			data.itemPrice		= sd.buyoutPrice / sd.stackSize;
			data.minpage		= sd.pagenum;
			data.maxpage		= sd.pagenum;
			data.count			= 1;
			data.type			= dataType;
			data.yours			= (ownerCode == "y");
			
			if (ownerCode ~= "x" and ownerCode ~= "y") then
				data.altname = ownerCode;
			end
			
			if (sd.volume) then
				data.volume = sd.volume;
			end
			
			conddata[key] = data;
		end
	end

	local n = 1;

	local i, v;

	for i,v in pairs (conddata) do
		self.sortedData[n] = v;
		n = n + 1;
	end

	table.sort (self.sortedData, Atr_SortAuctionData);
	self:AnalyzeSortData ();
end

-----------------------------------------

function AtrScan:AnalyzeSortData ()

	self.absoluteBest			= nil;
	self.bestPrices				= {};
	self.numMatches				= 0;
	self.numMatchesWithBuyout	= 0;
	self.hasStack				= false;
	self.yourBestPrice			= nil;
	self.yourWorstPrice			= nil;
	self.numYourSingletons		= 0;

	local j, sd;

	for j,sd in ipairs(self.sortedData) do

		if (sd.type == "n") then

			self.numMatches = self.numMatches + 1;

			if (sd.itemPrice > 0) then

				self.numMatchesWithBuyout = self.numMatchesWithBuyout + 1;

				if (self.bestPrices[sd.stackSize] == nil or self.bestPrices[sd.stackSize].itemPrice >= sd.itemPrice) then
					self.bestPrices[sd.stackSize] = sd;
				end

				if (self.absoluteBest == nil or self.absoluteBest.itemPrice > sd.itemPrice) then
					self.absoluteBest = sd;
				end
				
				if (sd.yours) then
					if (self.yourBestPrice == nil or self.yourBestPrice > sd.itemPrice) then
						self.yourBestPrice = sd.itemPrice;
					end
					
					if (self.yourWorstPrice == nil or self.yourWorstPrice < sd.itemPrice) then
						self.yourWorstPrice = sd.itemPrice;
					end
					
					if (sd.stackSize == 1) then
						self.numYourSingletons = self.numYourSingletons + sd.count;
					end
				end
			end

			if (sd.stackSize > 1) then
				self.hasStack = true;
			end
		end
	end
end

-----------------------------------------

function AtrScan:FindInSortedData (stackSize, buyoutPrice)
	local j = 1;
	for j = 1,getn(self.sortedData) do
		sd = self.sortedData[j];
		if (sd.stackSize == stackSize and sd.buyoutPrice == buyoutPrice and sd.yours) then
			return j;
		end
	end
	
	return 0;
end

-----------------------------------------

function AtrScan:FindMatchByStackSize (stackSize)

	local index = nil;

	local basedata = self.absoluteBest;

	if (self.bestPrices[stackSize]) then
		basedata = self.bestPrices[stackSize];
	end

	local numrows = getn(self.sortedData);

	local n;

	for n = 1,numrows do

		local data = self.sortedData[n];

		if (basedata and data.itemPrice == basedata.itemPrice and data.stackSize == basedata.stackSize and data.yours == basedata.yours) then
			index = n;
			break;
		end
	end

	return index;
end

-----------------------------------------

function AtrScan:FindMatchByYours ()

	local index = nil;

		local j;
	for j = 1,getn(self.sortedData) do
		local sd = self.sortedData[j];
		if (sd.yours and (index == nil or sd.itemPrice < self.sortedData[index].itemPrice)) then
			index = j;
		end
	end

	return index;
end

-----------------------------------------

function AtrScan:FindCheapest ()

	local index = nil;

		local j;
	for j = 1,getn(self.sortedData) do
		local sd = self.sortedData[j];
		if (sd.itemPrice > 0 and (index == nil or sd.itemPrice < self.sortedData[index].itemPrice)) then
			index = j;
		end
	end

	return index;
end

-----------------------------------------

function AtrScan:GetNumAvailable ()

	local num = 0;

	local j, data;
	for j = 1,getn(self.sortedData) do

		data = self.sortedData[j];
		num = num + (data.count * data.stackSize);
	end
	
	return num;
end

-----------------------------------------

function AtrScan:IsNil ()

	if (self.itemName == nil or self.itemName == "" or self.itemName == "nil") then
		return true;
	end
	
	return false;
end

-----------------------------------------

ATR_FS_NULL			= 0;
ATR_FS_STARTED		= 1;
ATR_FS_ANALYZING	= 2;
ATR_FS_CLEANING_UP	= 3;

gAtr_FullScanState = ATR_FS_NULL;

-----------------------------------------

function Atr_GetDBsize()

	local n = 0;
	local a,v;

	for a,v in pairs (gAtr_ScanDB) do
		n = n + 1;
	end
	
	return n;
end

-----------------------------------------

local gNumAdded, gNumUpdated;

local gFS_page			= 0;
local gFS_pages			= 0;
local gFS_lowprices		= {};
local gFS_qualities		= {};
local gFS_numAuctions	= 0;
local gFS_waiting		= false;
local gFS_sentAt		= 0;

-----------------------------------------

function Atr_FullScanStart()

	if (gAtr_FullScanState == ATR_FS_STARTED) then
		return;
	end

	Atr_FullScanStatus:SetText (ZT("Scanning").."...");
	Atr_FullScanStartButton:Disable();

	gAtr_FullScanState = ATR_FS_STARTED;

	gNumAdded = 0;
	gNumUpdated = 0;

	gFS_page		= 0;
	gFS_pages		= 0;
	gFS_lowprices	= {};
	gFS_qualities	= {};
	gFS_numAuctions	= 0;
	gFS_waiting		= false;

	Atr_FullScanResults:Hide();
	Atr_FullScanHTML:Show();

end

-----------------------------------------

function Atr_FullScanAbort()

	gAtr_FullScanState = ATR_FS_NULL;
	gFS_waiting = false;
	gFS_lowprices = {};
	gFS_qualities = {};

	Atr_FullScanStatus:SetText (ZT("Scan stopped"));
	Atr_FullScanStartButton:Enable();

end

-----------------------------------------

function Atr_FullScanDone_OnClick()

	if (gAtr_FullScanState == ATR_FS_STARTED) then
		Atr_FullScanAbort();
	end

	Atr_FullScanFrame:Hide();

end

-----------------------------------------

function Atr_CalcNewDBprice (name, prices)
		
	if (prices[1] ~= BIGNUM) then
		return prices[1];
	end

	return 0;
	
end

-----------------------------------------

function Atr_AddToLowPrices (lowprices, itemPrice)
	
	if (itemPrice > 0) then
		if (itemPrice < lowprices[1]) then
			if (lowprices[1] < lowprices[2]) then
				lowprices[2] = lowprices[1];
			end
			lowprices[1] = itemPrice;
			return true;
		elseif (itemPrice < lowprices[2]) then
			lowprices[2] = itemPrice;
			return true;
		end
	end

	return false;
end

-----------------------------------------

local gScanDetails = {}

-----------------------------------------

function Atr_FullScanMoreDetails ()

	zc.msg (" ");
	zc.msg_atr (ZT("Auctions scanned")..": |cffffffff", gScanDetails.numBatchAuctions, " |r("..gScanDetails.totalItems, "items)");
	zc.msg_atr ("|cffa335ee   "..ZT("Epic items")..": |r",		gScanDetails.numEachQual[5]);
	zc.msg_atr ("|cff0070dd   "..ZT("Rare items")..": |r",		gScanDetails.numEachQual[4]);
	zc.msg_atr ("|cff1eff00   "..ZT("Uncommon items")..": |r",	gScanDetails.numEachQual[3]);
	zc.msg_atr ("|cffffffff   "..ZT("Common items")..": |r",		gScanDetails.numEachQual[2]);
	zc.msg_atr ("|cff9d9d9d   "..ZT("Poor items")..": |r",		gScanDetails.numEachQual[1]);
	
	if (gScanDetails.numRemoved[4] > 0) then		zc.msg_atr (ZT("Rare items").." "..ZT("removed from database")..": |cffffffff",		gScanDetails.numRemoved[4]);		end
	if (gScanDetails.numRemoved[3] > 0) then		zc.msg_atr (ZT("Uncommon items").." "..ZT("removed from database")..": |cffffffff",	gScanDetails.numRemoved[3]);		end
	if (gScanDetails.numRemoved[2] > 0) then		zc.msg_atr (ZT("Common items").." "..ZT("removed from database")..": |cffffffff",	gScanDetails.numRemoved[2]);		end
	if (gScanDetails.numRemoved[1] > 0) then		zc.msg_atr (ZT("Poor items").." "..ZT("removed from database")..": |cffffffff",		gScanDetails.numRemoved[1]);		end
	
	zc.msg_atr (ZT("Items added to database")..": |cffffffff", gScanDetails.gNumAdded);
	zc.msg_atr (ZT("Items updated in database")..": |cffffffff", gScanDetails.gNumUpdated);
	zc.msg_atr (ZT("Items ignored")..": |cffffffff", gScanDetails.totalItems - (gScanDetails.gNumAdded + gScanDetails.gNumUpdated));
	zc.msg (" ");
end

-----------------------------------------

function Atr_FullScanAnalyze()

	if (not gFS_waiting) then
		return;
	end

	gFS_waiting = false;

	local numBatchAuctions, totalAuctions = GetNumAuctionItems("list");

	gFS_pages = math.ceil (totalAuctions / 50);

	local x;

	for x = 1, numBatchAuctions do

		local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice = GetAuctionItemInfo("list", x);

		if (name ~= nil and name ~= "") then

            local metadata = AUCTIONATOR_SEARCH_METADATA and AUCTIONATOR_SEARCH_METADATA[name];
            local itemLink;
            if (type(metadata) ~= "table" or not metadata.id) then
                itemLink = GetAuctionItemLink ("list", x);
            end
            Atr_SaveScannedItemMetadata (name, texture, itemLink, quality);

			gFS_qualities[name] = quality;

			if (buyoutPrice ~= nil and count ~= nil and count > 0) then

				local itemPrice = math.floor (buyoutPrice / count);

				if (itemPrice > 0) then
					if (not gFS_lowprices[name]) then
						gFS_lowprices[name] = {BIGNUM,BIGNUM,BIGNUM};
					end

					Atr_AddToLowPrices (gFS_lowprices[name], itemPrice);
				end
			end
		end
	end

	gFS_numAuctions = gFS_numAuctions + numBatchAuctions;
	gFS_page = gFS_page + 1;

	Atr_FullScanStatus:SetText (ZT("Scanning").." "..gFS_page.." / "..gFS_pages);

	if (gFS_page >= gFS_pages or numBatchAuctions == 0) then
		Atr_FullScanFinish();
	end

end

-----------------------------------------

function Atr_FullScanFinish()

	gAtr_FullScanState = ATR_FS_ANALYZING;

	Atr_FullScanStatus:SetText (ZT("Processing"));

	local numBatchAuctions = gFS_numAuctions;
	local lowprices = gFS_lowprices;
	local qualities = gFS_qualities;

	local numEachQual = {0, 0, 0, 0, 0, 0, 0, 0, 0};
	local totalItems = 0;
	local numRemoved = { 0, 0, 0, 0, 0, 0, 0, 0 };

	local name, prices;

	for name,prices in pairs (lowprices) do

		local newprice = Atr_CalcNewDBprice (name, prices);

		if (newprice > 0) then

			local qx = qualities[name] + 1;

			numEachQual[qx]	= numEachQual[qx] + 1;
			totalItems		= totalItems + 1;

			if (qx < AUCTIONATOR_SCAN_MINLEVEL and gAtr_ScanDB[name]) then
				numRemoved[qx] = numRemoved[qx] + 1;
				gAtr_ScanDB[name] = nil;
			end

			if (qx >= AUCTIONATOR_SCAN_MINLEVEL) then

				if (gAtr_ScanDB[name] == nil) then
					gNumAdded = gNumAdded + 1;
				else
					gNumUpdated = gNumUpdated + 1;
				end

				gAtr_ScanDB[name] = newprice;
				if (type(AUCTIONATOR_SEARCH_METADATA) ~= "table") then AUCTIONATOR_SEARCH_METADATA = {}; end
				local itemLink = Atr_GetItemLink and Atr_GetItemLink (name);
				local itemId = AtrNS and AtrNS.zc and AtrNS.zc.ItemIDfromLink and AtrNS.zc.ItemIDfromLink (itemLink);
				if (itemId and tonumber (itemId) and tonumber (itemId) > 0) then
					if (type(AUCTIONATOR_SEARCH_METADATA[name]) ~= "table") then AUCTIONATOR_SEARCH_METADATA[name] = {}; end
					AUCTIONATOR_SEARCH_METADATA[name].id = tonumber (itemId);
                    local _, _, _, _, _, itemType, itemSubType, _, _, texture = Atr_GetItemInfo (tonumber(itemId));
                    local metadata = AUCTIONATOR_SEARCH_METADATA[name];
                    if (itemType) then metadata.category = itemType; end
                    if (itemSubType) then metadata.subcategory = itemSubType; end
                    if (texture) then metadata.texture = texture; end
				end
			end
		end
	end

	gScanDetails.numBatchAuctions		= numBatchAuctions;
	gScanDetails.totalItems				= totalItems;
	gScanDetails.numEachQual			= numEachQual;
	gScanDetails.numRemoved				= numRemoved;
	gScanDetails.gNumAdded				= gNumAdded;
	gScanDetails.gNumUpdated			= gNumUpdated;

	Atr_FullScanMoreDetails();

	Atr_FullScanStartButton:Enable();
	Atr_FullScanDone:Enable();
	Atr_FullScanStatus:SetText (ZT("Scan complete"));

	Atr_FSR_scanned_count:SetText	(numBatchAuctions);
	Atr_FSR_added_count:SetText		(gNumAdded);
	Atr_FSR_updated_count:SetText	(gNumUpdated);
	Atr_FSR_ignored_count:SetText	(totalItems - (gNumAdded + gNumUpdated));

	Atr_FullScanHTML:Hide();
	Atr_FullScanResults:Show();

	Atr_FullScanResults:SetBackdropColor (0.3, 0.3, 0.4);

	AUCTIONATOR_LAST_SCAN_TIME = time();

	Atr_UpdateFullScanFrame ();

	PlaySound("AuctionWindowClose");

	gFS_lowprices = {};
	gFS_qualities = {};
	gAtr_FullScanState = ATR_FS_NULL;
end

-----------------------------------------

function auctionator_AuctionFrameBrowse_Update ()

	return auctionator_orig_AuctionFrameBrowse_Update ();

end

-----------------------------------------

function Atr_ShowFullScanFrame()

	Atr_FullScanHTML:Show();
	Atr_FullScanResults:Hide();

	Atr_FullScanFrame:Show();
	Atr_FullScanFrame:SetBackdropColor(0,0,0,100);
	
	Atr_UpdateFullScanFrame();
	Atr_FullScanStatus:SetText ("");

	local expText = "<html><body>"
					.."<p>"
					..ZT("Scanning is entirely optional.")
					.."<br/><br/>"
					..ZT("SCAN_EXPLANATION")
					.."</p>"
					.."</body></html>"
					;

	Atr_FullScanHTML:SetText (expText);
	Atr_FullScanHTML:SetSpacing (3);
end

-----------------------------------------

function Atr_UpdateFullScanFrame()

	Atr_FullScanDBsize:SetText (Atr_GetDBsize());

	if (AUCTIONATOR_LAST_SCAN_TIME) then
		Atr_FullScanDBwhen:SetText (date ("%A, %B %d at %I:%M %p", AUCTIONATOR_LAST_SCAN_TIME));
	else
		Atr_FullScanDBwhen:SetText (ZT("Never"));
	end

	Atr_FullScanNext:SetText(ZT("Now"));

	if (gAtr_FullScanState ~= ATR_FS_STARTED) then
		Atr_FullScanStartButton:Enable();
	end
end

-----------------------------------------

function Atr_FullScanFrameIdle()

	if (gAtr_FullScanState == ATR_FS_STARTED) then

		if (not AuctionFrame or not AuctionFrame:IsShown()) then
			Atr_FullScanAbort();
			return;
		end

		if (gFS_waiting and GetTime() - gFS_sentAt > 20) then
			gFS_waiting = false;
		end

		if (not gFS_waiting and Atr_CanSendAuctionQuery()) then
			gFS_waiting = true;
			gFS_sentAt = GetTime();
			Atr_QueryAuctionItems ("", nil, nil, 0, 0, 0, gFS_page, 0, 0);
		end
	end
end

local ROWS		= 15
local ROW_H		= 18			
local ROW_GAP	= 5			
local ROW_STEP	= ROW_H + ROW_GAP
local COL_NAME	= 240
local COL_PRICE	= 110
local COL_POSTED	= 110
local LIST_TOP	= 114			

local win, search, scroll, categoryScroll, infoText, emptyText, detailText
local itemDetailScroll, itemDetailContent, itemDetailTooltip, itemDetailPanel, itemDetailTextLayer, itemDetailIcon, itemDetailId
local itemDetailLines = {};
local PREVIEW_HEIGHT = 355;
local PREVIEW_WIDTH = 420;
local RESULTS_X = 226;
local CATEGORY_X = 22;
local CATEGORY_WIDTH = 176;
local CATEGORY_ROWS = 17;
local CATEGORY_ROW_H = 17;
local categoryRows = {};
local categoryTree = {};
local categoryVisible = {};
local categoryExpanded = {};
local selectedCategory = nil;
local selectedSubcategory = nil;
local UNCATEGORIZED = "Other / Unknown";

local rows		= {};
local headers	= {};
local master	= {};		
local view		= master;	
local sortKey	= "name";
local sortAsc	= true;
local selected	= nil;	
local filterIn	= nil;

-----------------------------------------

local function Money (v)

	if (v == nil) then
		return "|cff888888-|r";
	end

	v = math.floor (v + 0.5);
	if (v <= 0) then
		return "|cff888888-|r";
	end

	local utils = AtrNS and AtrNS.zc;
	if (utils and utils.priceToMoneyString) then
		return utils.priceToMoneyString (v, true);
	end
	local gold = math.floor (v / 10000);
	local silver = math.floor (math.mod (v, 10000) / 100);
	local copper = math.mod (v, 100);
	local text = "";
	if (gold > 0) then text = gold.."g "; end
	if (silver > 0 or gold > 0) then text = text..silver.."s "; end
	if (copper > 0 or text == "") then text = text..copper.."c"; end
	return text;
end

-----------------------------------------

local function IdFromIs (is)

	if (is == nil) then
		return nil;
	end

	local _, _, id = string.find (tostring(is), "^(%d+)");

	return tonumber (id);
end

-----------------------------------------

local function LatestPosting (hist)

	local best, bestWhen;

	if (type(hist) ~= "table" or ParseHist == nil) then
		return nil, nil;
	end

	local tag, h;
	for tag, h in pairs (hist) do
		if (tag ~= "is") then
			local ok, when, _, price = pcall (ParseHist, tag, h);
			if (ok and when and price and (bestWhen == nil or when > bestWhen)) then
				best, bestWhen = price, when;
			end
		end
	end

	return best, bestWhen;
end

-----------------------------------------

local function Compare (a, b)

	if (sortKey == "name") then
		if (a.l == b.l) then
			return a.name < b.name;
		end
		if (sortAsc) then
			return a.l < b.l;
		end
		return a.l > b.l;
	end

	local va, vb = a[sortKey], b[sortKey];

	if (va == vb) then
		return a.l < b.l;
	end
	if (va == nil) then
		return false;
	end
	if (vb == nil) then
		return true;
	end
	if (sortAsc) then
		return va < vb;
	end
	return va > vb;
end

-----------------------------------------

local function LoadItemMetadata (e)
    local meta = AUCTIONATOR_SEARCH_METADATA and AUCTIONATOR_SEARCH_METADATA[e.name];
    if (type(meta) == "table") then
        e.id = e.id or tonumber (meta.id);
        e.category = meta.category;
        e.subcategory = meta.subcategory;
        e.texture = meta.texture;
        e.quality = tonumber (meta.quality);
    end
    if (e.id and Atr_GetItemInfo) then
        local _, _, quality, _, _, itemType, itemSubType, _, _, texture = Atr_GetItemInfo (e.id);
        if (itemType or itemSubType or texture or quality) then
            e.quality = e.quality or quality;
            e.category = e.category or itemType;
            e.subcategory = e.subcategory or itemSubType;
            e.texture = e.texture or texture;
            if (type(AUCTIONATOR_SEARCH_METADATA) ~= "table") then AUCTIONATOR_SEARCH_METADATA = {}; end
            if (type(AUCTIONATOR_SEARCH_METADATA[e.name]) ~= "table") then AUCTIONATOR_SEARCH_METADATA[e.name] = {}; end
            meta = AUCTIONATOR_SEARCH_METADATA[e.name];
            meta.id = e.id;
            meta.category = e.category;
            meta.subcategory = e.subcategory;
            meta.texture = e.texture;
            meta.quality = e.quality;
        end
    end
end

local function BuildMaster ()
    master = {};
    local byName = {};
    local name, price;

    if (type(gAtr_ScanDB) == "table") then
        for name, price in pairs (gAtr_ScanDB) do
            if (type(name) == "string" and type(price) == "number") then
                local e = { name = name, l = string.lower(name), price = price };
                LoadItemMetadata (e);
                tinsert (master, e);
                byName[name] = e;
            end
        end
    end

    if (type(AUCTIONATOR_PRICING_HISTORY) == "table") then
        local hist;
        for name, hist in pairs (AUCTIONATOR_PRICING_HISTORY) do
            if (type(name) == "string" and type(hist) == "table") then
                local e = byName[name];
                if (e == nil) then
                    e = { name = name, l = string.lower(name) };
                    tinsert (master, e);
                    byName[name] = e;
                end
                e.posted, e.postedWhen = LatestPosting (hist);
                e.id = e.id or IdFromIs (hist["is"]);
                LoadItemMetadata (e);
            end
        end
    end

    table.sort (master, Compare);
    view = master;
end

-----------------------------------------

local function ItemLinkOf (e)

	if (Atr_GetItemLink == nil) then
		return nil;
	end

	local link = Atr_GetItemLink (e.name);

	if (link == nil and e.id and Atr_GetItemInfo) then
		local _, l = Atr_GetItemInfo (e.id);
		link = l;
	end

	return link;
end

-----------------------------------------

local function ColoredName (e)

	local link = ItemLinkOf (e);

	if (link) then
		local _, _, color = string.find (link, "|c(%x%x%x%x%x%x%x%x)|H");
		if (color) then
			return "|c"..color..e.name.."|r";
		end
	end

	return e.name;
end

-----------------------------------------

local function UpdateInfo ()

	local total = getn (master);
	local line  = ZT("Items in database:").." |cffffffff"..total.."|r    "..ZT("Showing:").." |cffffffff"..getn(view).."|r";

	if (AUCTIONATOR_LAST_SCAN_TIME) then
		line = line.."\n"..ZT("Last scan:").." |cffffffff"..date ("%Y-%m-%d %H:%M", AUCTIONATOR_LAST_SCAN_TIME).."|r";
	else
		line = line.."\n"..ZT("Last scan:").." |cffffffff"..ZT("never").."|r";
	end

	infoText:SetText (line);

	if (total == 0) then
		emptyText:SetText (ZT("The price database is empty.\nRun a full scan at the auction house first."));
		emptyText:Show();
	elseif (getn(view) == 0) then
		emptyText:SetText (ZT("No matching items"));
		emptyText:Show();
	else
		emptyText:Hide();
	end
end

-----------------------------------------

local function SkinEmbeddedItemTooltip ()
    if (not itemDetailPanel or itemDetailPanel.atrPfUISkinned) then return; end
    if (not pfUI or not pfUI.api or type(pfUI.api.CreateBackdrop) ~= "function") then return; end
    if (not pfUI_config or not pfUI_config.tooltip) then return; end
    if (pfUI_config.disabled and pfUI_config.disabled.skin_Tooltips == "1") then return; end

    local ok = pcall (pfUI.api.CreateBackdrop, itemDetailPanel, nil, true);
    if (not ok) then return; end

    itemDetailPanel.atrPfUISkinned = true;
end

-----------------------------------------

local function PreviewLine (index, side)
    if (not itemDetailLines[index]) then itemDetailLines[index] = {}; end
    local line = itemDetailLines[index];
    if (not line[side]) then
        local fs = itemDetailTextLayer:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall");
        fs:SetJustifyH (side == "right" and "RIGHT" or "LEFT");
        fs:SetJustifyV ("TOP");
        line[side] = fs;
    end
    return line[side];
end

local function CopyTooltipFont (dst, src, first)
    if (src and src.GetFont) then
        local path, size, flags = src:GetFont();
        if (path and size) then
            local ok = pcall (dst.SetFont, dst, path, size, flags);
            if (ok) then return; end
        end
    end
    dst:SetFontObject (first and GameFontNormal or GameFontHighlightSmall);
end

local function TooltipLineHeight (fs)
    local h = fs:GetStringHeight();
    if (not h or h < 13) then h = 14; end
    return math.ceil (h);
end

local function UpdateEmbeddedItemTooltip (e)
    if (not itemDetailTooltip or not itemDetailPanel) then return false; end

    itemDetailTooltip:SetOwner (UIParent, "ANCHOR_NONE");
    itemDetailTooltip:ClearLines();
    local known = false;
    local link = ItemLinkOf (e);
    if (link) then
        local _, _, itemString = string.find (link, "(item:[%-%d:]+)");
        if (itemString) then
            local ok = pcall (itemDetailTooltip.SetHyperlink, itemDetailTooltip, itemString);
            if (ok and itemDetailTooltip:NumLines() > 0) then known = true; end
        end
    end
    if (not known and e.id) then
        itemDetailTooltip:ClearLines();
        local ok = pcall (itemDetailTooltip.SetHyperlink, itemDetailTooltip, "item:"..e.id..":0:0:0");
        if (ok and itemDetailTooltip:NumLines() > 0) then known = true; end
    end

    local sourceName = "Atr_PriceEmbeddedItemTooltip";
    local count = known and itemDetailTooltip:NumLines() or 2;
    local y = 15;
    local i;
    for i = 1, math.max (count, getn(itemDetailLines)) do
        local dstLeft = PreviewLine (i, "left");
        local dstRight = PreviewLine (i, "right");
        local srcLeft = known and getglobal (sourceName.."TextLeft"..i) or nil;
        local srcRight = known and getglobal (sourceName.."TextRight"..i) or nil;
        local left = srcLeft and srcLeft:GetText() or nil;
        local right = srcRight and srcRight:GetText() or nil;
        if (not known) then
            if (i == 1) then left = e.name; end
            if (i == 2) then left = ZT("Full item tooltip unavailable until you have cached this item."); end
        end
        if (i <= count and ((left and left ~= "") or (right and right ~= ""))) then

            if (i == 2 and y < 60) then y = 60; end
            local first = (i == 1);
            local hasRight = (right and right ~= "");
            dstLeft:ClearAllPoints();
            dstLeft:SetPoint ("TOPLEFT", itemDetailPanel, "TOPLEFT", first and 58 or 12, -y);
            dstLeft:SetWidth (first and 330 or (hasRight and 255 or 385));
            CopyTooltipFont (dstLeft, srcLeft, first);
            dstLeft:SetText (left or "");
            if (srcLeft and srcLeft.GetTextColor) then
                local r,g,b = srcLeft:GetTextColor();
                dstLeft:SetTextColor (r or 1, g or 1, b or 1);
            elseif (first) then
                local color = e.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[e.quality];
                dstLeft:SetTextColor (color and color.r or 1, color and color.g or 1, color and color.b or 1);
            else
                dstLeft:SetTextColor (0.7, 0.7, 0.7);
            end
            dstLeft:Show();
            local height = TooltipLineHeight (dstLeft);
            if (hasRight) then
                dstRight:ClearAllPoints();
                dstRight:SetPoint ("TOPRIGHT", itemDetailPanel, "TOPRIGHT", -12, -y);
                dstRight:SetWidth (110);
                CopyTooltipFont (dstRight, srcRight, false);
                dstRight:SetText (right);
                if (srcRight and srcRight.GetTextColor) then
                    local r,g,b = srcRight:GetTextColor();
                    dstRight:SetTextColor (r or 1, g or 1, b or 1);
                else
                    dstRight:SetTextColor (1, 1, 1);
                end
                dstRight:Show();
                height = math.max (height, TooltipLineHeight (dstRight));
            else
                dstRight:Hide();
            end
            y = y + height + 3;
        else
            dstLeft:Hide();
            dstRight:Hide();
        end
    end
    itemDetailTooltip:Hide();
    if (y < 60) then y = 60; end

    itemDetailIcon:SetTexture (e.texture or "Interface\\Icons\\INV_Misc_QuestionMark");
    itemDetailIcon:Show();
    itemDetailId:SetText ("|cffffd100ItemID:|r  "..(e.id and tostring(e.id) or "|cff888888Unknown|r"));
    itemDetailId:ClearAllPoints();
    itemDetailId:SetPoint ("TOPLEFT", itemDetailPanel, "TOPLEFT", 12, -(y + 5));
    itemDetailId:Show();

    local panelHeight = math.max (PREVIEW_HEIGHT - 8, y + 36);
    itemDetailPanel:SetHeight (panelHeight);
    itemDetailContent:SetHeight (panelHeight + 8);
    if (itemDetailScroll.UpdateScrollChildRect) then
        itemDetailScroll:UpdateScrollChildRect();
    end
    local bar = getglobal ("Atr_PriceItemDetailScrollScrollBar");
    if (bar) then bar:SetValue (0); end
    itemDetailScroll:SetVerticalScroll (0);
    return known;
end

local function ScrollItemPreview ()
    local amount = (arg1 or 0) * 40;
    local bar = getglobal ("Atr_PriceItemDetailScrollScrollBar");
    if (bar) then
        bar:SetValue (bar:GetValue() - amount);
    else
        local target = itemDetailScroll:GetVerticalScroll() - amount;
        if (target < 0) then target = 0; end
        local maxScroll = itemDetailScroll:GetVerticalScrollRange() or 0;
        if (target > maxScroll) then target = maxScroll; end
        itemDetailScroll:SetVerticalScroll (target);
    end
end

-----------------------------------------

local function UpdateDetails ()
    if (selected == nil) then
        if (itemDetailScroll) then itemDetailScroll:Hide(); end
        detailText:SetText ("|cff888888"..ZT("Click an item to see its details").."|r");
        return;
    end

    local e;
    local i;
    for i = 1, getn (master) do
        if (master[i].name == selected) then
            e = master[i];
            break;
        end
    end
    if (e == nil) then
        selected = nil;
        UpdateDetails ();
        return;
    end

    itemDetailScroll:Show();
    SkinEmbeddedItemTooltip ();
    local known = UpdateEmbeddedItemTooltip (e);

    local label = "|cffffd100";
    local lines = {};
    tinsert (lines, label..ZT("Auction price:").."|r  "..Money (e.price));
    tinsert (lines, label..ZT("Your last posting:").."|r  "..Money (e.posted)
        ..((e.postedWhen and e.posted) and ("   |cff888888"..date ("%Y-%m-%d", e.postedWhen).."|r") or ""));
    if (not known) then
        tinsert (lines, "|cff888888"..ZT("Item details are not available (item not known yet)").."|r");
    end
    detailText:SetText (table.concat (lines, "\n"));
end

-----------------------------------------

local qualityBorderFallback = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 1.00, 1.00, 1.00 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.00, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1.00, 0.50, 0.00 },
    [6] = { 0.90, 0.13, 0.13 },
};

local function SetIconBorderQuality (row, quality)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality];
    local fallback = qualityBorderFallback[quality or -1];
    local r, g, b;
    if (color) then
        r, g, b = color.r, color.g, color.b;
    elseif (fallback) then
        r, g, b = fallback[1], fallback[2], fallback[3];
    else
        r, g, b = 0.45, 0.45, 0.45;
    end

    local i;
    for i = 1, 4 do
        row.iconBorder[i]:SetVertexColor (r, g, b);
    end
end

-----------------------------------------

local function UpdateList ()

	if (win == nil) then
		return;
	end

	local n = getn (view);

	FauxScrollFrame_Update (scroll, n, ROWS, ROW_STEP);

	local offset = FauxScrollFrame_GetOffset (scroll);
	local i;

	for i = 1, ROWS do

		local row = rows[i];
		local e   = view[offset + i];

		if (e) then
			row.entry = e;
            row.icon:SetTexture (e.texture or "Interface\\Icons\\INV_Misc_QuestionMark");
            SetIconBorderQuality (row, e.quality);
			row.nameText:SetText (ColoredName (e));
			row.priceText:SetText (Money (e.price));
			row.postedText:SetText (Money (e.posted));

			if (e.name == selected) then
				row.sel:Show();
			else
				row.sel:Hide();
			end

			row:Show();
		else
			row.entry = nil;
			row:Hide();
		end
	end
end

-----------------------------------------

local function UpdateHeaders ()

	local key, h;
	for key, h in pairs (headers) do
		if (key == sortKey) then
			h.arrow:Show();
			if (sortAsc) then
				h.arrow:SetTexCoord (0, 0.5625, 1.0, 0);
			else
				h.arrow:SetTexCoord (0, 0.5625, 0, 1.0);
			end
		else
			h.arrow:Hide();
		end
	end
end

-----------------------------------------

local function BuildCategoryTree ()
    local byCategory = {};
    categoryTree = {};
    local i, e, cat, sub, node;
    for i = 1, getn(master) do
        e = master[i];
        cat = e.category or UNCATEGORIZED;
        node = byCategory[cat];
        if (not node) then
            node = { name = cat, subNames = {}, subSet = {} };
            byCategory[cat] = node;
            tinsert (categoryTree, node);
        end
        sub = e.subcategory;
        if (sub and sub ~= "" and not node.subSet[sub]) then
            node.subSet[sub] = true;
            tinsert (node.subNames, sub);
        end
    end
    table.sort (categoryTree, function(a,b) return a.name < b.name; end);
    for i = 1, getn(categoryTree) do
        table.sort (categoryTree[i].subNames);
    end
end

local function BuildVisibleCategories ()
    categoryVisible = { { label = "All categories", all = true } };
    local i, j, node;
    for i = 1, getn(categoryTree) do
        node = categoryTree[i];
        tinsert (categoryVisible, { label = node.name, category = node.name, hasChildren = getn(node.subNames) > 0 });
        if (categoryExpanded[node.name]) then
            for j = 1, getn(node.subNames) do
                tinsert (categoryVisible, { label = node.subNames[j], category = node.name, subcategory = node.subNames[j] });
            end
        end
    end
end

local function UpdateCategoryList ()
    if (not categoryScroll) then return; end
    FauxScrollFrame_Update (categoryScroll, getn(categoryVisible), CATEGORY_ROWS, CATEGORY_ROW_H);
    local offset = FauxScrollFrame_GetOffset (categoryScroll);
    local i, b, e, active;
    for i = 1, CATEGORY_ROWS do
        b = categoryRows[i];
        e = categoryVisible[offset + i];
        if (e) then
            b.entry = e;
            b.label:SetText ((e.subcategory and "     " or "") .. (e.hasChildren and (categoryExpanded[e.category] and "- " or "+ ") or "") .. e.label);
            active = (e.all and selectedCategory == nil) or (e.subcategory and selectedCategory == e.category and selectedSubcategory == e.subcategory) or (e.category and not e.subcategory and selectedCategory == e.category and selectedSubcategory == nil);
            if (active) then b.selectedTex:Show(); else b.selectedTex:Hide(); end
            b:Show();
        else
            b.entry = nil;
            b:Hide();
        end
    end
end

local function Refilter ()

	local text  = string.lower (search:GetText() or "");
	local words = {};
	local gfind = string.gfind or string.gmatch;

	local w;
	for w in gfind (text, "%S+") do
		tinsert (words, w);
	end

	local nw = getn (words);

	if (nw == 0 and selectedCategory == nil) then
        view = master;
    else
        view = {};
        local i, j, e, ok, category;
        for i = 1, getn(master) do
            e = master[i];
            category = e.category or UNCATEGORIZED;
            ok = (selectedCategory == nil or category == selectedCategory) and (selectedSubcategory == nil or e.subcategory == selectedSubcategory);
            if (ok) then
                for j = 1, nw do
                    if (not string.find(e.l, words[j], 1, true)) then
                        ok = false;
                        break;
                    end
                end
            end
            if (ok) then tinsert (view, e); end
        end
    end

	local bar = getglobal ("Atr_PriceScrollScrollBar");
	if (bar) then
		bar:SetValue (0);
	end
	scroll:SetVerticalScroll (0);

	UpdateInfo ();
    UpdateCategoryList ();
	UpdateList ();
end

-----------------------------------------

local function SortBy (key)

	if (sortKey == key) then
		sortAsc = not sortAsc;
	else
		sortKey = key;
		sortAsc = (key == "name");
	end

	table.sort (master, Compare);
	if (view ~= master) then
		table.sort (view, Compare);
	end

	UpdateHeaders ();
	UpdateList ();
end

-----------------------------------------

local function ShowRowTooltip (row)

	local e = row.entry;
	if (e == nil) then
		return;
	end

	GameTooltip:SetOwner (row, "ANCHOR_RIGHT");

	local shown = false;
	local link  = ItemLinkOf (e);

	if (link) then
		local _, _, itemString = string.find (link, "(item:[%-%d:]+)");
		if (itemString) then
			shown = pcall (GameTooltip.SetHyperlink, GameTooltip, itemString);
		end
	end

	if (not shown) then
		GameTooltip:SetText (e.name, 1, 1, 1);
	end

	GameTooltip:Show();
end

-----------------------------------------

local function CreateRow (i)

	local row = CreateFrame ("Button", "Atr_PriceRow"..i, win);
	row:SetWidth (COL_NAME + COL_PRICE + COL_POSTED + 8);
	row:SetHeight (ROW_H);
	row:SetPoint ("TOPLEFT", win, "TOPLEFT", RESULTS_X, -LIST_TOP - ((i - 1) * ROW_STEP));

	row.sel = row:CreateTexture (nil, "BACKGROUND");
	row.sel:SetAllPoints (row);
	row.sel:SetTexture (1, 0.82, 0, 0.2);
	row.sel:Hide();

	row:SetHighlightTexture ("Interface\\HelpFrame\\HelpFrameButton-Highlight", "ADD");
	local h = row:GetHighlightTexture();
	if (h) then
		h:SetTexCoord (0.05, 0.07, 0.1, 0.5);
	end

    row.icon = row:CreateTexture (nil, "ARTWORK");
    row.icon:SetWidth (16);
    row.icon:SetHeight (16);
    row.icon:SetPoint ("LEFT", row, "LEFT", 2, 0);

    row.iconBorder = {};
    local side;
    for side = 1, 4 do
        local border = row:CreateTexture (nil, "OVERLAY");
        border:SetTexture ("Interface\\Buttons\\WHITE8X8");
        row.iconBorder[side] = border;
    end
    row.iconBorder[1]:SetWidth (18); row.iconBorder[1]:SetHeight (1);
    row.iconBorder[1]:SetPoint ("BOTTOM", row.icon, "TOP", 0, 0);
    row.iconBorder[2]:SetWidth (18); row.iconBorder[2]:SetHeight (1);
    row.iconBorder[2]:SetPoint ("TOP", row.icon, "BOTTOM", 0, 0);
    row.iconBorder[3]:SetWidth (1); row.iconBorder[3]:SetHeight (16);
    row.iconBorder[3]:SetPoint ("RIGHT", row.icon, "LEFT", 0, 0);
    row.iconBorder[4]:SetWidth (1); row.iconBorder[4]:SetHeight (16);
    row.iconBorder[4]:SetPoint ("LEFT", row.icon, "RIGHT", 0, 0);

	row.nameText = row:CreateFontString (nil, "ARTWORK", "GameFontHighlightSmall");
	row.nameText:SetWidth (COL_NAME - 20);
	row.nameText:SetJustifyH ("LEFT");
	row.nameText:SetPoint ("LEFT", row.icon, "RIGHT", 4, 0);

	row.priceText = row:CreateFontString (nil, "ARTWORK", "GameFontHighlightSmall");
	row.priceText:SetWidth (COL_PRICE);
	row.priceText:SetJustifyH ("RIGHT");
	row.priceText:SetPoint ("LEFT", row.nameText, "RIGHT", 2, 0);

	row.postedText = row:CreateFontString (nil, "ARTWORK", "GameFontHighlightSmall");
	row.postedText:SetWidth (COL_POSTED);
	row.postedText:SetJustifyH ("RIGHT");
	row.postedText:SetPoint ("LEFT", row.priceText, "RIGHT", 2, 0);

	row:SetScript ("OnClick", function()
		if (this.entry) then
			selected = this.entry.name;
			UpdateList ();
			UpdateDetails ();
		end
	end);
	row:SetScript ("OnEnter", function() ShowRowTooltip (this); end);
	row:SetScript ("OnLeave", function() GameTooltip:Hide(); end);

	row:Hide();

	return row;
end

-----------------------------------------

local function CreateCategoryRow (i)
    local b = CreateFrame ("Button", "Atr_PriceCategoryRow"..i, win);
    b:SetWidth (CATEGORY_WIDTH - 22);
    b:SetHeight (CATEGORY_ROW_H);
    b:SetPoint ("TOPLEFT", win, "TOPLEFT", CATEGORY_X + 4, -LIST_TOP - ((i - 1) * CATEGORY_ROW_H));
    b:SetFrameLevel (categoryScroll:GetFrameLevel() + 1);
    b.selectedTex = b:CreateTexture (nil, "BACKGROUND");
    b.selectedTex:SetAllPoints (b);
    b.selectedTex:SetTexture (1, 0.82, 0, 0.25);
    b.selectedTex:Hide();
    b:SetHighlightTexture ("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD");
    b.label = b:CreateFontString (nil, "ARTWORK", "GameFontHighlightSmall");
    b.label:SetPoint ("LEFT", b, "LEFT", 2, 0);
    b.label:SetWidth (CATEGORY_WIDTH - 26);
    b.label:SetJustifyH ("LEFT");
    b:SetScript ("OnClick", function()
        local e = this.entry;
        if (not e) then return; end
        if (e.all) then
            selectedCategory = nil;
            selectedSubcategory = nil;
        elseif (e.subcategory) then
            selectedCategory = e.category;
            selectedSubcategory = e.subcategory;
        else
            selectedCategory = e.category;
            selectedSubcategory = nil;
            if (e.hasChildren) then
                categoryExpanded[e.category] = not categoryExpanded[e.category];
                BuildVisibleCategories ();
            end
        end
        Refilter ();
        UpdateDetails ();
    end);
    b:Hide();
    return b;
end

-----------------------------------------

local function CreateHeader (key, text, x, width, justify)

	local b = CreateFrame ("Button", "Atr_PriceHeader_"..key, win);
	b:SetWidth (width);
	b:SetHeight (18);
	b:SetPoint ("TOPLEFT", win, "TOPLEFT", x, -(LIST_TOP - 20));
	b:SetNormalFontObject (GameFontNormalSmall);
	b:SetHighlightFontObject (GameFontHighlightSmall);
	Atr_LT (b, text, true);

	local fs = b:GetFontString();
	if (fs) then
		fs:ClearAllPoints();
		fs:SetPoint ("LEFT", b, "LEFT", 12, 0);
		fs:SetPoint ("RIGHT", b, "RIGHT", -2, 0);
		fs:SetJustifyH (justify);
	end

	b.arrow = b:CreateTexture (nil, "OVERLAY");
	b.arrow:SetTexture ("Interface\\Buttons\\UI-SortArrow");
	b.arrow:SetWidth (9);
	b.arrow:SetHeight (8);
	b.arrow:SetPoint ("LEFT", b, "LEFT", 2, 0);
	b.arrow:Hide();

	b:SetScript ("OnClick", function() SortBy (key); end);

	headers[key] = b;
	return b;
end

-----------------------------------------

local function CreateWindow ()

	win = CreateFrame ("Frame", "Atr_PriceWindow", UIParent);
	win:SetWidth (770);
	win:SetHeight (970);
	win:SetPoint ("CENTER", UIParent, "CENTER", 0, 0);
	win:SetFrameStrata ("DIALOG");
	win:SetToplevel (true);
	win:EnableMouse (true);
	win:SetMovable (true);
	win:SetClampedToScreen (true);

    local availableHeight = UIParent:GetHeight() - 24;
    if (availableHeight > 0 and availableHeight < 970) then
        win:SetScale (availableHeight / 970);
    end
	win:RegisterForDrag ("LeftButton");
	win:SetBackdrop ({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } });
	win:SetScript ("OnDragStart", function() this:StartMoving(); end);
	win:SetScript ("OnDragStop", function() this:StopMovingOrSizing(); end);
	win:Hide();

	tinsert (UISpecialFrames, "Atr_PriceWindow");

	local title = win:CreateFontString (nil, "ARTWORK", "GameFontNormalLarge");
	title:SetPoint ("TOP", win, "TOP", 0, -18);
	Atr_LT (title, "OctoJAOAuctionator Price Database");

	local close = CreateFrame ("Button", "Atr_PriceWindowClose", win, "UIPanelCloseButton");
	close:SetPoint ("TOPRIGHT", win, "TOPRIGHT", -6, -6);

	local label = win:CreateFontString (nil, "ARTWORK", "GameFontNormal");
	label:SetPoint ("TOPLEFT", win, "TOPLEFT", RESULTS_X + 4, -46);
	Atr_LT (label, "Search");

	search = CreateFrame ("EditBox", "Atr_PriceSearch", win, "InputBoxTemplate");
	search:SetWidth (220);
	search:SetHeight (20);
	search:SetPoint ("LEFT", label, "RIGHT", 12, 0);
	search:SetAutoFocus (false);
	search:SetScript ("OnTextChanged", function() filterIn = 0.2; end);
	search:SetScript ("OnEnterPressed", function() this:ClearFocus(); end);
	search:SetScript ("OnEscapePressed", function() this:ClearFocus(); end);

	infoText = win:CreateFontString (nil, "ARTWORK", "GameFontHighlightSmall");
	infoText:SetJustifyH ("LEFT");
	infoText:SetPoint ("TOPLEFT", win, "TOPLEFT", RESULTS_X + 4, -70);


    local catTitle = win:CreateFontString (nil, "ARTWORK", "GameFontNormal");
    catTitle:SetPoint ("TOPLEFT", win, "TOPLEFT", CATEGORY_X + 4, -79);
    Atr_LT (catTitle, "Categories");
    local catBg = CreateFrame ("Frame", nil, win);
    catBg:SetPoint ("TOPLEFT", win, "TOPLEFT", CATEGORY_X, -(LIST_TOP - 5));
    catBg:SetWidth (CATEGORY_WIDTH);
    catBg:SetHeight (CATEGORY_ROWS * CATEGORY_ROW_H + 10);
    catBg:SetBackdrop ({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 10, insets = { left = 3, right = 3, top = 3, bottom = 3 } });
    categoryScroll = CreateFrame ("ScrollFrame", "Atr_PriceCategoryScroll", win, "FauxScrollFrameTemplate");
    categoryScroll:SetWidth (CATEGORY_WIDTH - 8);
    categoryScroll:SetHeight (CATEGORY_ROWS * CATEGORY_ROW_H);
    categoryScroll:SetPoint ("TOPLEFT", win, "TOPLEFT", CATEGORY_X + 4, -LIST_TOP);
    categoryScroll:SetScript ("OnVerticalScroll", function()
        FauxScrollFrame_OnVerticalScroll (CATEGORY_ROW_H, UpdateCategoryList);
    end);
    local j;
    for j = 1, CATEGORY_ROWS do
        categoryRows[j] = CreateCategoryRow (j);
    end

	CreateHeader ("name",   "Item Name",          RESULTS_X,                           COL_NAME + 6,    "LEFT");
	CreateHeader ("price",  "Auction price",      RESULTS_X + COL_NAME + 8,            COL_PRICE + 2,   "RIGHT");
	CreateHeader ("posted", "Your last posting",  RESULTS_X + COL_NAME + COL_PRICE + 10, COL_POSTED + 2, "RIGHT");

	scroll = CreateFrame ("ScrollFrame", "Atr_PriceScroll", win, "FauxScrollFrameTemplate");
	scroll:SetWidth (COL_NAME + COL_PRICE + COL_POSTED + 8);
	scroll:SetHeight (ROWS * ROW_STEP);
	scroll:SetPoint ("TOPLEFT", win, "TOPLEFT", RESULTS_X, -LIST_TOP);
	scroll:SetScript ("OnVerticalScroll", function()
		FauxScrollFrame_OnVerticalScroll (ROW_STEP, UpdateList);
	end);

	local i;
	for i = 1, ROWS do
		rows[i] = CreateRow (i);
	end

	emptyText = win:CreateFontString (nil, "ARTWORK", "GameFontNormal");
	emptyText:SetWidth (400);
	emptyText:SetPoint ("CENTER", win, "TOPLEFT", RESULTS_X + 240, -LIST_TOP - (ROWS * ROW_STEP / 2));
	emptyText:Hide();

    detailText = win:CreateFontString (nil, "ARTWORK", "GameFontHighlightSmall");
    detailText:SetJustifyH ("LEFT");
    detailText:SetJustifyV ("TOP");
    detailText:SetWidth (480);
    detailText:SetHeight (62);
    detailText:SetPoint ("TOPLEFT", win, "TOPLEFT", RESULTS_X + 4, -LIST_TOP - (ROWS * ROW_STEP) - 12);

    itemDetailScroll = CreateFrame ("ScrollFrame", "Atr_PriceItemDetailScroll", win, "UIPanelScrollFrameTemplate");
    itemDetailScroll:SetPoint ("TOPLEFT", detailText, "BOTTOMLEFT", 0, -8);
    itemDetailScroll:SetWidth (465);
    itemDetailScroll:SetHeight (PREVIEW_HEIGHT);
    itemDetailScroll:SetFrameLevel (win:GetFrameLevel() + 3);
    itemDetailScroll:EnableMouseWheel (true);
    itemDetailScroll:SetScript ("OnMouseWheel", ScrollItemPreview);

    itemDetailContent = CreateFrame ("Frame", "Atr_PriceItemDetailContent", itemDetailScroll);
    itemDetailContent:SetWidth (PREVIEW_WIDTH);
    itemDetailContent:SetHeight (PREVIEW_HEIGHT);
    itemDetailContent:SetFrameLevel (itemDetailScroll:GetFrameLevel() + 1);
    itemDetailScroll:SetScrollChild (itemDetailContent);
    itemDetailContent:EnableMouseWheel (true);
    itemDetailContent:SetScript ("OnMouseWheel", ScrollItemPreview);

    itemDetailPanel = CreateFrame ("Frame", "Atr_PriceItemDetailPanel", itemDetailContent);
    itemDetailPanel:SetPoint ("TOPLEFT", itemDetailContent, "TOPLEFT", 0, 0);
    itemDetailPanel:SetWidth (PREVIEW_WIDTH - 4);
    itemDetailPanel:SetHeight (PREVIEW_HEIGHT - 8);
    itemDetailPanel:SetFrameLevel (itemDetailContent:GetFrameLevel() + 1);
    itemDetailPanel:SetBackdrop ({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    });
    itemDetailPanel:SetBackdropColor (0.08, 0.08, 0.12, 0.94);
    itemDetailPanel:EnableMouseWheel (true);
    itemDetailPanel:SetScript ("OnMouseWheel", ScrollItemPreview);

    itemDetailTextLayer = CreateFrame ("Frame", "Atr_PriceItemDetailTextLayer", itemDetailPanel);
    itemDetailTextLayer:SetAllPoints (itemDetailPanel);
    itemDetailTextLayer:SetFrameLevel (itemDetailPanel:GetFrameLevel() + 3);

    itemDetailIcon = itemDetailTextLayer:CreateTexture (nil, "OVERLAY");
    itemDetailIcon:SetWidth (36);
    itemDetailIcon:SetHeight (36);
    itemDetailIcon:SetPoint ("TOPLEFT", itemDetailPanel, "TOPLEFT", 12, -12);

    itemDetailTooltip = CreateFrame ("GameTooltip", "Atr_PriceEmbeddedItemTooltip", UIParent, "GameTooltipTemplate");
    itemDetailTooltip:SetPoint ("TOPLEFT", UIParent, "TOPLEFT", -5000, 5000);
    itemDetailTooltip:Hide();
    SkinEmbeddedItemTooltip ();

    itemDetailId = itemDetailTextLayer:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall");
    itemDetailId:SetJustifyH ("LEFT");

	win:SetScript ("OnUpdate", function()
		if (filterIn) then
			filterIn = filterIn - arg1;
			if (filterIn <= 0) then
				filterIn = nil;
				Refilter ();
			end
		end
	end);

	win:SetScript ("OnShow", function()
		BuildMaster ();
        BuildCategoryTree ();
        BuildVisibleCategories ();
        UpdateCategoryList ();
		UpdateHeaders ();
		Refilter ();
		UpdateDetails ();
	end);

	win:SetScript ("OnHide", function()
        if (itemDetailTooltip) then itemDetailTooltip:Hide(); end
		GameTooltip:Hide();
	end);

	if (Atr_SkinPriceWindow) then
		Atr_SkinPriceWindow (win);
	end
end

-----------------------------------------

function Atr_ShowPriceWindow (text)

	if (win == nil) then
		CreateWindow ();
	end

	if (text ~= nil and text ~= "") then
		search:SetText (text);
	end

	if (not win:IsVisible()) then
		win:Show();
	end

	if (text ~= nil and text ~= "") then
		filterIn = nil;
		Refilter ();
	end

	search:SetFocus();
end

-----------------------------------------

function Atr_TogglePriceWindow ()

	if (win and win:IsVisible()) then
		win:Hide();
	else
		Atr_ShowPriceWindow ();
	end
end

-----------------------------------------

SLASH_ATRPRICES1 = "/atrprices";
SLASH_ATRPRICES2 = "/atrp";
SlashCmdList["ATRPRICES"] = function (msg)
	Atr_ShowPriceWindow (msg);
end

local Atr_PriceMinimapButton;
local function Atr_CreatePriceMinimapButton ()
	if (Atr_PriceMinimapButton) then return; end
	if (Minimap == nil) then return; end
	if (type(AUCTIONATOR_SEARCH_METADATA) ~= "table") then AUCTIONATOR_SEARCH_METADATA = {}; end
	if (type(AUCTIONATOR_SEARCH_METADATA.minimapAngle) ~= "number") then AUCTIONATOR_SEARCH_METADATA.minimapAngle = 220; end

	local button = CreateFrame ("Button", "Atr_PriceMinimapButton", Minimap);
	Atr_PriceMinimapButton = button;
	button:SetWidth (32); button:SetHeight (32);
	button:SetFrameStrata ("MEDIUM");
	button:SetPoint ("TOPLEFT", Minimap, "TOPLEFT", 0, 0);
	button:SetMovable (true); button:EnableMouse (true); button:RegisterForDrag ("LeftButton");
	button.icon = button:CreateTexture (nil, "BACKGROUND");
	button.icon:SetTexture ("Interface\\Icons\\INV_Misc_Coin_01");
	button.icon:SetWidth (20); button.icon:SetHeight (20);
	button.icon:SetPoint ("CENTER", button, "CENTER", 0, 0);
	button.border = button:CreateTexture (nil, "OVERLAY");
	button.border:SetTexture ("Interface\\Minimap\\MiniMap-TrackingBorder");
	button.border:SetWidth (54); button.border:SetHeight (54);
	button.border:SetPoint ("TOPLEFT", button, "TOPLEFT", 0, 0);
	button:SetHighlightTexture ("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight");
	button:SetScript ("OnClick", function () Atr_TogglePriceWindow (); end);
	button:SetScript ("OnEnter", function () GameTooltip:SetOwner (this, "ANCHOR_LEFT"); GameTooltip:SetText ("Auctionator Price Database", 1, 1, 1); GameTooltip:AddLine ("Click to search stored prices", 0.8, 0.8, 0.8); GameTooltip:Show(); end);
	button:SetScript ("OnLeave", function () GameTooltip:Hide(); end);
	button:SetScript ("OnDragStart", function () this:LockHighlight(); this.dragging = true; end);
	button:SetScript ("OnDragStop", function () this:UnlockHighlight(); this.dragging = false; end);
	button:SetScript ("OnUpdate", function ()
		if (not this.dragging) then return; end
		local mx, my = Minimap:GetCenter(); local x, y = GetCursorPosition(); local scale = UIParent:GetScale();
		x = x / scale - mx; y = y / scale - my;
		local angle = math.deg (math.atan2 (y, x));
		AUCTIONATOR_SEARCH_METADATA.minimapAngle = angle;
		local radius = 80; local rad = math.rad (angle);
		this:ClearAllPoints(); this:SetPoint ("CENTER", Minimap, "CENTER", math.cos(rad) * radius, math.sin(rad) * radius);
	end);
	local angle = AUCTIONATOR_SEARCH_METADATA.minimapAngle; local rad = math.rad (angle);
	button:ClearAllPoints(); button:SetPoint ("CENTER", Minimap, "CENTER", math.cos(rad) * 80, math.sin(rad) * 80);
	button:Show();
end

local initFrame = CreateFrame ("Frame");
initFrame:RegisterEvent ("PLAYER_LOGIN");
initFrame:SetScript ("OnEvent", function () Atr_CreatePriceMinimapButton (); end);

local W, search, listScroll, status, summary, details, title, metric1, metric2, bargainHeader;
local tabButtons = {};
local skinButtons = {};
local listRows = {};
local bars = {};
local dayButtons = {};
local dealDiscountBox, dealSpreadBox, dealLabel1, dealLabel2;
local visible = {};
local currentTab = "deals";
local selectedKey = nil;
local historyDays = 30;
local minimumDiscount = 25;
local minimumSpread = 10000;
local ROWS = 12;
local ROW_HEIGHT = 24;
local LIST_TOP = 147;
local function AM() return AtrMarket; end

local function Cash(v)
    if (type(v) ~= "number") then return "--"; end
    local negative = v < 0;
    v = math.floor(math.abs(v) + 0.5);
    local g = math.floor(v / 10000);
    local s = math.floor(math.mod(v, 10000) / 100);
    local c = math.mod(v, 100);
    local t = "";
    if (g > 0) then t = g.."g "; end
    if (s > 0 or g > 0) then t = t..s.."s "; end
    if (c > 0 or t == "") then t = t..c.."c"; end
    return (negative and "-" or "")..t;
end

local function Label(parent, text, x, y, width, style)
    local f = parent:CreateFontString(nil, "OVERLAY", style or "GameFontHighlightSmall");
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y);
    f:SetWidth(width);
    f:SetJustifyH("LEFT");
    f:SetJustifyV("TOP");
    f:SetText(text or "");
    return f;
end

local function Button(parent, text, x, y, width, height, handler)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
    b:SetWidth(width); b:SetHeight(height);
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y);
    b:SetText(text);
    b:SetScript("OnClick", handler);
    table.insert(skinButtons, b);
    return b;
end

local function Matches(name, needle)
    return needle == "" or string.find(string.lower(name or ""), needle, 1, true) ~= nil;
end

local function Data()
    if (type(AUCTIONATOR_MARKET_DATA) ~= "table") then return {}; end
    return AUCTIONATOR_MARKET_DATA;
end

local function Rebuild()
    visible = {};
    local needle = string.lower((search and search:GetText()) or "");
    local m = AM();
    if (currentTab == "deals") then
        local deals = m.Deals(minimumDiscount, minimumSpread);
        local i, e;
        for i = 1, table.getn(deals) do
            e = deals[i];
            if (Matches(e.name, needle)) then
                e.key = e.name;
                e.left = e.name;
                e.right = Cash(e.low).." / item  |  "..Cash(e.spread).." spread";
                e.percent = e.discount;
                table.insert(visible, e);
            end
        end
    elseif (currentTab == "history") then
        local name;
        for name in pairs(m.HistoryNames()) do
            if (Matches(name, needle)) then
                local history = m.History(name, historyDays);
                local last = history[table.getn(history)];
                if (last) then
                    table.insert(visible, { key=name, name=name, left=name,
                        right=Cash(last.last or last.average)
                            ..(last.source == "Shared" and " shared avg" or " last observed") });
                end
            end
        end
        table.sort(visible, function(a,b) return a.left < b.left; end);
    elseif (currentTab == "crafting") then
        local key, recipe;
        for key, recipe in pairs(Data().recipes or {}) do
            if (Matches(recipe.name, needle) or Matches(recipe.profession, needle)) then
                local est = m.CraftingEstimate(recipe);
                table.insert(visible, { key=key, name=recipe.name,
                    left=(recipe.recipeName or recipe.name),
                    right=(est and est.profit and Cash(est.profit)) or "Missing prices",
                    recipe=recipe, estimate=est });
            end
        end
        table.sort(visible, function(a,b)
            if (a.estimate and a.estimate.profit and b.estimate and b.estimate.profit) then
                return a.estimate.profit > b.estimate.profit;
            end
            if (a.estimate and a.estimate.profit) then return true; end
            if (b.estimate and b.estimate.profit) then return false; end
            return a.left < b.left;
        end);

    end
end

local function HideChart()
    local i;
    for i = 1, table.getn(bars) do bars[i]:Hide(); end
end

local function UpdateDetails()
    HideChart();
    local e;
    local i;
    for i = 1, table.getn(visible) do
        if (visible[i].key == selectedKey) then e = visible[i]; break; end
    end
    if (currentTab == "deals") then
        summary:SetText("Bargains are not live listings. Refresh the Auction House before buying.");
        if (e) then
            metric1:SetText("Lowest observed: "..Cash(e.low).." / item");
            metric2:SetText("Previous market average: "..Cash(e.reference).." / item");
            details:SetText("Spread: "..Cash(e.spread).." per item (gross, before AH fees).\n"
                .."Discount: "..e.discount.."%. Reference: "..(e.basis or "previous prices")..".\n"
                .."Seen "..date("%Y-%m-%d %H:%M", e.t)..".\n"
                .."Use Auctionator's normal search to confirm this listing is still available.");
        else
            metric1:SetText("Filter: "..minimumDiscount.."% minimum discount");
            metric2:SetText("Minimum gross spread: "..Cash(minimumSpread));
            details:SetText("Requires at least two price observations for an item.\n"
                .."The first scan establishes a reference; subsequent scans can reveal bargains.");
        end
    elseif (currentTab == "history") then
        summary:SetText("Daily unit buyouts: local scans + matching read-only shared history.");
        if (e) then
            local series = AM().History(e.name, historyDays);
            local reference = AM().Reference(e.name, historyDays);
            local last = series[table.getn(series)];
            metric1:SetText("Market average: "..Cash(reference));
            metric2:SetText("Latest day: "..Cash(last and (last.last or last.average))
                ..(last and last.source == "Shared" and " (shared)" or ""));
            details:SetText("Daily observations: "..table.getn(series).." day(s), last "
                ..(last and last.day or "never")..". Local history overrides shared days. "
                .."Chart uses the selected "..historyDays.."-day window.");
            local high = 0;
            for i = 1, table.getn(series) do high = math.max(high, series[i].average); end
            for i = 1, table.getn(series) do
                local bar = bars[i];
                if (bar and high > 0) then
                    local height = math.max(2, math.floor(series[i].average / high * 78));
                    bar:SetHeight(height);
                    bar.observation = series[i];
                    bar:ClearAllPoints();
                    bar:SetPoint("BOTTOMLEFT", W, "TOPLEFT", 45 + (i-1)*23, -640);
                    bar:Show();
                end
            end
        else
            metric1:SetText("Select an item to view its history");
            metric2:SetText("");
            details:SetText("7 / 14 / 30-day history can be selected above.\n"
                .."Prices are recorded on scans, or loaded from database.");
        end
    elseif (currentTab == "crafting") then
        summary:SetText("Reagents use saved auction prices. Estimates exclude vendor-only materials and AH fees.");
        if (e) then
            local r, est = e.recipe, e.estimate;
            metric1:SetText("Output (x"..(r.output or 1).."): "..Cash(est.output));
            metric2:SetText("Materials: "..(table.getn(est.missing) > 0 and "incomplete" or Cash(est.cost)));
            local lines = {"Profession: "..(r.profession or "Unknown").."   Estimated gross profit: "..Cash(est.profit)};
            local j, ingredient;
            for j = 1, math.min(table.getn(r.reagents), 8) do
                ingredient = r.reagents[j];
                local price = gAtr_ScanDB and gAtr_ScanDB[ingredient.name];
                table.insert(lines, "x"..ingredient.count.." "..ingredient.name.."  "
                    ..Cash(price and price * ingredient.count));
            end
            if (table.getn(r.reagents) > 8) then table.insert(lines, "... additional reagents not shown"); end
            if (table.getn(est.missing) > 0) then
                table.insert(lines, "Missing saved prices: "..table.concat(est.missing, ", "));
            end
            details:SetText(table.concat(lines, "\n"));
        else
            metric1:SetText("Open a profession window to capture its recipes");
            metric2:SetText("Recipes are saved automatically");
            details:SetText("Crafting estimates require auction prices for the finished item and every reagent.\n"
                .."An unknown ingredient never counts as free.");
        end

    end
end

local function UpdateList()
    FauxScrollFrame_Update(listScroll, table.getn(visible), ROWS, ROW_HEIGHT);
    local offset = FauxScrollFrame_GetOffset(listScroll);
    local i, row, e;
    for i = 1, ROWS do
        row = listRows[i];
        e = visible[i + offset];
        if e then
            row.entry = e;
            row.left:SetText(e.left);
            row.right:SetText(e.right);
            row.percent:SetText((currentTab == "deals" and type(e.percent) == "number")
                and (tostring(e.percent).."%") or "");
            if (e.key == selectedKey) then row.bg:Show(); else row.bg:Hide(); end
            row:Show();
        else
            row.entry = nil;
            row:Hide();
        end
    end
    status:SetText(table.getn(visible).." result(s) | Saved scan data; not live AH listings");
end

local function Refresh()
    if (not W or not W:IsShown()) then return; end
    Rebuild();
    UpdateList();
    UpdateDetails();
end

local function SetTab(tab)
    currentTab = tab;
    selectedKey = nil;
    local key, b;
    for key, b in pairs(tabButtons) do
        if (key == currentTab) then b:LockHighlight(); else b:UnlockHighlight(); end
    end
    local showDeals = (currentTab == "deals");
    if (bargainHeader) then if showDeals then bargainHeader:Show(); else bargainHeader:Hide(); end end
    if (dealDiscountBox) then
        if (showDeals) then
            dealDiscountBox:Show(); dealSpreadBox:Show();
            dealLabel1:Show(); dealLabel2:Show();
        else
            dealDiscountBox:Hide(); dealSpreadBox:Hide();
            dealLabel1:Hide(); dealLabel2:Hide();
        end
    end
    local i;
    for i = 1, table.getn(dayButtons) do
        if (currentTab == "history") then
            dayButtons[i]:Show();
        else
            dayButtons[i]:Hide();
        end
    end
    Refresh();
end

local function CreateWindow()
    W = CreateFrame("Frame", "Atr_MarketWindow", UIParent);
    W:SetWidth(820); W:SetHeight(685);
    W:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    W:SetFrameStrata("DIALOG"); W:SetToplevel(true);
    W:EnableMouse(true); W:SetMovable(true); W:SetClampedToScreen(true);
    if UIParent:GetHeight() < 710 then W:SetScale(math.max(0.65, (UIParent:GetHeight() - 20) / 685)); end
    W:RegisterForDrag("LeftButton");
    W:SetScript("OnDragStart", function() this:StartMoving(); end);
    W:SetScript("OnDragStop", function() this:StopMovingOrSizing(); end);
    W:SetBackdrop({ bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true,
        tileSize=32, edgeSize=32, insets={left=10,right=10,top=10,bottom=10} });
    table.insert(UISpecialFrames, "Atr_MarketWindow");
    Label(W, "OctoJAOAuctionator - Market Analysis", 25, 19, 550, "GameFontNormalLarge");
    local close = CreateFrame("Button", nil, W, "UIPanelCloseButton");
    close:SetPoint("TOPRIGHT", W, "TOPRIGHT", -6, -6);
    local tabs = { {"deals", "Bargains"}, {"history", "Price History"},
        {"crafting", "Crafting"} };
    local i;
    for i = 1, table.getn(tabs) do
        local id = tabs[i][1];
        tabButtons[id] = Button(W, tabs[i][2], 22 + (i-1)*151, 52, 145, 25,
            function() SetTab(id); end);
    end
    Label(W, "Filter:", 27, 96, 47, "GameFontNormalSmall");
    search = CreateFrame("EditBox", "Atr_MarketSearch", W, "InputBoxTemplate");
    search:SetWidth(315); search:SetHeight(20);
    search:SetPoint("TOPLEFT", W, "TOPLEFT", 88, -91);
    search:SetAutoFocus(false);
    search:SetScript("OnTextChanged", function() selectedKey=nil; Refresh(); end);
    search:SetScript("OnEscapePressed", function() this:ClearFocus(); end);
    search:SetScript("OnEnterPressed", function() this:ClearFocus(); end);
    dayButtons[1] = Button(W, "7d", 435, 90, 56, 24, function() historyDays=7; Refresh(); end);
    dayButtons[2] = Button(W, "14d", 494, 90, 56, 24, function() historyDays=14; Refresh(); end);
    dayButtons[3] = Button(W, "30d", 553, 90, 56, 24, function() historyDays=30; Refresh(); end);
    dealLabel1 = Label(W, "Min %", 429, 95, 44);
    dealDiscountBox = CreateFrame("EditBox", "Atr_MarketDiscount", W, "InputBoxTemplate");
    dealDiscountBox:SetWidth(39); dealDiscountBox:SetHeight(20);
    dealDiscountBox:SetPoint("TOPLEFT", W, "TOPLEFT", 478, -91);
    dealDiscountBox:SetAutoFocus(false); dealDiscountBox:SetNumeric(true);
    dealDiscountBox:SetText(tostring(minimumDiscount));
    dealDiscountBox:SetScript("OnEnterPressed", function()
        minimumDiscount = math.max(0, math.min(100, tonumber(this:GetText()) or 25));
        this:SetText(tostring(minimumDiscount)); this:ClearFocus(); Refresh();
    end);
    dealLabel2 = Label(W, "Min g", 527, 95, 44);
    dealSpreadBox = CreateFrame("EditBox", "Atr_MarketSpread", W, "InputBoxTemplate");
    dealSpreadBox:SetWidth(39); dealSpreadBox:SetHeight(20);
    dealSpreadBox:SetPoint("TOPLEFT", W, "TOPLEFT", 576, -91);
    dealSpreadBox:SetAutoFocus(false); dealSpreadBox:SetNumeric(true);
    dealSpreadBox:SetText(tostring(math.floor(minimumSpread / 10000)));
    dealSpreadBox:SetScript("OnEnterPressed", function()
        local gold = math.max(0, math.min(1000000, tonumber(this:GetText()) or 1));
        minimumSpread = gold * 10000;
        this:SetText(tostring(gold)); this:ClearFocus(); Refresh();
    end);
    Button(W, "Refresh", 651, 90, 136, 24, function()
        if (currentTab == "crafting") then AM().ReadProfession(); end
        Refresh();
    end);
    status = Label(W, "", 27, 124, 760);
    bargainHeader = Label(W, "Bargain %", 694, 130, 90, "GameFontNormalSmall");
    listScroll = CreateFrame("ScrollFrame", "Atr_MarketListScroll", W, "FauxScrollFrameTemplate");
    listScroll:SetWidth(748); listScroll:SetHeight(ROWS * ROW_HEIGHT);
    listScroll:SetPoint("TOPLEFT", W, "TOPLEFT", 25, -LIST_TOP);
    listScroll:SetScript("OnVerticalScroll", function()
        FauxScrollFrame_OnVerticalScroll(ROW_HEIGHT, UpdateList);
    end);
    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, W);
        row:SetWidth(732); row:SetHeight(ROW_HEIGHT-1);
        row:SetPoint("TOPLEFT", W, "TOPLEFT", 32, -LIST_TOP - (i-1)*ROW_HEIGHT);
        row.bg = row:CreateTexture(nil, "BACKGROUND");
        row.bg:SetAllPoints(row); row.bg:SetTexture(1, .8, 0, .2); row.bg:Hide();
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD");
        row.left = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        row.left:SetPoint("LEFT", row, "LEFT", 4, 0);
        row.left:SetWidth(440); row.left:SetJustifyH("LEFT");
        row.right = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        row.right:SetWidth(205); row.right:SetJustifyH("RIGHT");
        row.right:SetPoint("RIGHT", row, "RIGHT", -79, 0);
        row.percent = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        row.percent:SetWidth(64); row.percent:SetJustifyH("RIGHT");
        row.percent:SetPoint("RIGHT", row, "RIGHT", -6, 0);
        row:SetScript("OnClick", function()
            if (this.entry) then selectedKey=this.entry.key; UpdateList(); UpdateDetails(); end
        end);
        row:Hide();
        listRows[i] = row;
    end
    local divider = W:CreateTexture(nil, "ARTWORK");
    divider:SetTexture(.5,.5,.5,.7);
    divider:SetPoint("TOPLEFT", W, "TOPLEFT", 26, -448);
    divider:SetWidth(760); divider:SetHeight(1);
    summary = Label(W, "", 33, 459, 747);
    metric1 = Label(W, "", 33, 491, 355, "GameFontNormal");
    metric2 = Label(W, "", 413, 491, 359, "GameFontNormal");
    details = Label(W, "", 33, 519, 748);
    details:SetHeight(132);
    for i = 1, 30 do
        local bar = CreateFrame("Button", nil, W);
        bar:SetWidth(15); bar:SetHeight(5);
        local barColor = bar:CreateTexture(nil, "ARTWORK");
        barColor:SetAllPoints(bar); barColor:SetTexture(.3,.68,.96,.9);
        bar.atrChartTexture = barColor;
        bar:SetScript("OnEnter", function()
            if (this.observation) then
                GameTooltip:SetOwner(this, "ANCHOR_TOP");
                GameTooltip:SetText(this.observation.day, 1, .82, 0);
                GameTooltip:AddLine("Average: "..Cash(this.observation.average), 1, 1, 1);
                GameTooltip:AddLine("Lowest: "..Cash(this.observation.low), 1, 1, 1);
                GameTooltip:AddLine("Scans: "..this.observation.samples, .7, .7, .7);
                GameTooltip:AddLine("Source: "..(this.observation.source or "Local"), .7, .7, .7);
                GameTooltip:Show();
            end
        end);
        bar:SetScript("OnLeave", function() GameTooltip:Hide(); end);
        bar:Hide(); bars[i] = bar;
    end
    W:SetScript("OnShow", function()
        if (Atr_SkinMarketWindow) then
            Atr_SkinMarketWindow(W, skinButtons, close,
                { search, dealDiscountBox, dealSpreadBox }, listRows, bars);
        end
        SetTab(currentTab);
    end);
    W:Hide();
end

function Atr_ShowMarketWindow(name)
    if (not W) then CreateWindow(); end
    if (type(name) == "string" and name ~= "") then
        currentTab = "history";
        selectedKey = name;
        search:SetText(name);
    end
    W:Show();
    SetTab(currentTab);
    if (type(name) == "string" and name ~= "") then selectedKey = name; end
    Refresh();
end

SLASH_ATRMARKET1 = "/atrmarket";
SLASH_ATRMARKET2 = "/atrm";
SlashCmdList["ATRMARKET"] = function(msg)
    Atr_ShowMarketWindow(msg ~= "" and msg or nil);
end

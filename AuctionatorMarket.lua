AtrMarket = {};
local M = AtrMarket;
local MAX_DAYS = 30;

local function DB()
    if (type(AUCTIONATOR_MARKET_DATA) ~= "table") then AUCTIONATOR_MARKET_DATA = {}; end
    local d = AUCTIONATOR_MARKET_DATA;
    if (type(d.history) ~= "table") then d.history = {}; end
    if (type(d.deals) ~= "table") then d.deals = {}; end
    if (type(d.recipes) ~= "table") then d.recipes = {}; end
    return d;
end

local function ValidPrice(p)
    return type(p) == "number" and p > 0 and p < 100000000000;
end

local function Day(t)
    return date ("%Y-%m-%d", t or time());
end

local function SharedItems()
    local shared = AtrMarketSharedData;
    if (type(shared) ~= "table" or shared.schema ~= 1 or type(shared.items) ~= "table") then
        return nil;
    end
    if (type(shared.realm) ~= "string" or shared.realm == "") then return nil; end
    if (not GetRealmName or shared.realm ~= GetRealmName()) then return nil; end
    if (type(shared.faction) ~= "string" or shared.faction == "") then return nil; end
    if (not UnitFactionGroup or shared.faction ~= UnitFactionGroup("player")) then return nil; end
    return shared.items;
end

local sharedNameIndex, indexSource;
local function SharedNameIndex(items)
    if (indexSource ~= items) then
        local index = {};
        local id, entry;
        for id, entry in pairs(items) do
            if (type(entry) == "table" and type(entry.name) == "string" and entry.name ~= "") then
                index[entry.name] = tonumber(id);
            end
        end
        sharedNameIndex = index;
        indexSource = items;
    end
    return sharedNameIndex or {};
end

function M.HistoryNames()
    local names = {};
    local name;
    for name in pairs(DB().history) do names[name] = true; end
    local items = SharedItems();
    if (items) then
        for name in pairs(SharedNameIndex(items)) do names[name] = true; end
        local metaName, meta;
        for metaName, meta in pairs(AUCTIONATOR_SEARCH_METADATA or {}) do
            if (type(metaName) == "string" and type(meta) == "table" and meta.id) then
                local id = tonumber(meta.id);
                if (id and (items[id] or items[tostring(id)])) then names[metaName] = true; end
            end
        end
    end
    return names;
end

local function SharedHistory(name, cutoffDay)
    local items = SharedItems();
    if (not items) then return {}; end
    local id = AUCTIONATOR_SEARCH_METADATA and AUCTIONATOR_SEARCH_METADATA[name];
    id = (type(id) == "table") and tonumber(id.id) or nil;
    if (not id and Atr_GetItemLink) then
        local link = Atr_GetItemLink(name);
        if (type(link) == "string") then
            local _, _, extracted = string.find(link, "item:(%d+)");
            id = tonumber(extracted);
        end
    end
    if (not id) then id = SharedNameIndex(items)[name]; end
    if (not id) then return {}; end
    local item = items[id] or items[tostring(id)];
    if (type(item) ~= "table" or type(item.days) ~= "table") then return {}; end
    local out = {};
    local day, v;
    for day, v in pairs(item.days) do
        if (type(day) == "string" and string.find(day, "^%d%d%d%d%-%d%d%-%d%d$")
            and day >= cutoffDay and type(v) == "table"
            and ValidPrice(v.average) and ValidPrice(v.low)
            and type(v.samples) == "number" and v.samples >= 1) then
            out[day] = {day=day, average=math.floor(v.average+0.5),
                low=math.floor(v.low+0.5), last=nil,
                samples=math.floor(v.samples), source="Shared"};
        end
    end
    return out;
end

function M.History(name, days)
    if (type(name) ~= "string" or name == "") then return {}; end
    days = tonumber(days) or MAX_DAYS;
    local cutoff = time() - days * 86400;
    local cutoffDay = Day(cutoff);
    local byDay = SharedHistory(name, cutoffDay);
    local series = DB().history[name] or {};
    local i, v;
    for i = 1, table.getn(series) do
        v = series[i];
        if (type(v) == "table" and (v.t or 0) >= cutoff and (v.n or 0) > 0
            and ValidPrice(v.sum / v.n)) then
            byDay[v.day] = {day=v.day, average=math.floor(v.sum/v.n+0.5),
                low=v.low, last=v.last, samples=v.n, source="Local"};
        end
    end
    local out = {};
    for _, v in pairs(byDay) do table.insert(out, v); end
    table.sort(out, function(a,b) return a.day < b.day; end);
    return out;
end

function M.Reference(name, days)
    local series = M.History(name, days or MAX_DAYS);
    local total = 0;
    local i;
    for i = 1, table.getn(series) do total = total + series[i].average; end
    if (table.getn(series) == 0) then return nil, 0; end
    return math.floor(total / table.getn(series) + 0.5), table.getn(series);
end

function M.BargainPercent(name, unitPrice, days)
    if (not ValidPrice(unitPrice)) then return nil; end
    local reference = M.Reference(name, days or MAX_DAYS);
    if (not ValidPrice(reference)) then return nil; end
    return math.floor((reference - unitPrice) * 100 / reference + .5);
end

function M.RecordScan(name, lowest, stamp, priorAuctionatorPrice)
    if (type(name) ~= "string" or name == "" or not ValidPrice(lowest)) then return; end
    local d = DB();
    local now = stamp or time();
    local baseline, days = M.Reference(name, MAX_DAYS);
    local basis = "Daily market average";
    if (not baseline and ValidPrice(priorAuctionatorPrice)) then
        baseline = priorAuctionatorPrice;
        basis = "Previous stored Auctionator price";
    end
    if (baseline and lowest < baseline) then
        d.deals[name] = { low = lowest, reference = baseline, t = now, basis = basis,
            discount = math.floor((baseline - lowest) * 100 / baseline + 0.5) };
    else
        d.deals[name] = nil;
    end

    local series = d.history[name];
    if (type(series) ~= "table") then series = {}; d.history[name] = series; end
    local key = Day(now);
    local last = series[table.getn(series)];
    if (last and last.day == key) then
        last.sum = last.sum + lowest;
        last.n = last.n + 1;
        last.low = math.min(last.low or lowest, lowest);
        last.t = now;
        last.last = lowest;
    else
        table.insert(series, { day = key, t = now, sum = lowest, n = 1, low = lowest, last = lowest });
    end
    local cutoff = now - MAX_DAYS * 86400;
    while (table.getn(series) > 0 and (table.getn(series) > MAX_DAYS or (series[1].t or 0) < cutoff)) do
        table.remove(series, 1);
    end
end

function M.Deals(minDiscount, minSpread)
    local list = {};
    local d = DB();
    local now = time();
    local name, deal;
    for name, deal in pairs(d.deals) do
        if (type(deal) == "table" and (now - (deal.t or 0)) <= 86400 * 2
            and (deal.discount or 0) >= (minDiscount or 25)
            and (deal.reference or 0) - (deal.low or 0) >= (minSpread or 0)) then
            table.insert(list, { name = name, low = deal.low, reference = deal.reference,
                discount = deal.discount, spread = deal.reference - deal.low,
                t = deal.t, basis = deal.basis });
        end
    end
    table.sort(list, function(a,b)
        if (a.discount == b.discount) then return a.spread > b.spread; end
        return a.discount > b.discount;
    end);
    return list;
end

local function ItemID(link)
    if (type(link) ~= "string") then return nil; end
    local _, _, id = string.find(link, "item:(%d+)");
    return tonumber(id);
end

function M.ReadProfession()
    if (type(GetNumTradeSkills) ~= "function" or type(GetTradeSkillInfo) ~= "function"
        or not TradeSkillFrame or not TradeSkillFrame:IsShown()) then return 0; end
    local count = GetNumTradeSkills() or 0;
    local profession = (GetTradeSkillLine and GetTradeSkillLine()) or "Profession";
    local d = DB();
    local saved = 0;
    local i, j;
    for i = 1, count do
        local name, skillType = GetTradeSkillInfo(i);
        if (name and skillType ~= "header" and skillType ~= "subheader") then
            local num = (GetTradeSkillNumMade and GetTradeSkillNumMade(i)) or 1;
            if (type(num) ~= "number" or num < 1) then num = 1; end
            local link = GetTradeSkillItemLink and GetTradeSkillItemLink(i);
            local outputName = name;
            if (link and Atr_GetItemInfo) then
                local knownName = Atr_GetItemInfo(link);
                if (knownName and knownName ~= "") then outputName = knownName; end
            end
            local n = (GetTradeSkillNumReagents and GetTradeSkillNumReagents(i)) or 0;
            local reagents = {};
            for j = 1, n do
                local reagentName, texture, required = GetTradeSkillReagentInfo(i, j);
                if (reagentName and (required or 0) > 0) then
                    local reagentLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, j);
                    table.insert(reagents, { name = reagentName, count = required, id = ItemID(reagentLink) });
                end
            end
            if (table.getn(reagents) > 0) then
                local key = profession.."|"..name;
                d.recipes[key] = { name = outputName, recipeName = name,
                    profession = profession, output = num,
                    id = ItemID(link), reagents = reagents, t = time() };
                saved = saved + 1;
            end
        end
    end
    return saved;
end

function M.CraftingEstimate(recipe)
    if (type(recipe) ~= "table") then return nil; end
    local prices = gAtr_ScanDB or {};
    local outputPrice = prices[recipe.name];
    local cost, missing = 0, {};
    local i, reagent;
    for i = 1, table.getn(recipe.reagents or {}) do
        reagent = recipe.reagents[i];
        local price = prices[reagent.name];
        if (ValidPrice(price)) then
            cost = cost + price * reagent.count;
        else
            table.insert(missing, reagent.name);
        end
    end
    local output = ValidPrice(outputPrice) and outputPrice * (recipe.output or 1) or nil;
    local profit;
    if (output and table.getn(missing) == 0) then profit = output - cost; end
    return { cost = cost, output = output, profit = profit, missing = missing };
end

local observer = CreateFrame("Frame");
observer:RegisterEvent("TRADE_SKILL_SHOW");
observer:RegisterEvent("TRADE_SKILL_UPDATE");
observer:SetScript("OnEvent", function()
    M.ReadProfession();
end);

local sellMarketLastName, sellMarketLastAt;
local function ShortMoney(v)
    if (not v or v <= 0) then return "--"; end
    local g = math.floor(v/10000);
    local silver = math.floor(math.mod(v,10000)/100);
    local copper = math.mod(v,100);
    if (g > 0) then return g.."g "..silver.."s"; end
    if (silver > 0) then return silver.."s "..copper.."c"; end
    return copper.."c";
end

function Atr_UpdateSellMarketInfo(show)
    if (not Atr_SellMarketAverage or not Atr_SellMarketHistory or not Atr_SellMarketHistoryButton) then return; end
    local name = show and GetAuctionSellItemInfo() or nil;
    if (not name or name == "") then
        Atr_SellMarketAverage:Hide();
        Atr_SellMarketHistory:Hide();
        Atr_SellMarketHistoryButton:Hide();
        sellMarketLastName = nil;
        return;
    end
    local now = time();
    if (sellMarketLastName ~= name or not sellMarketLastAt or now - sellMarketLastAt >= 5) then
        sellMarketLastName = name;
        sellMarketLastAt = now;
        local average = M.Reference(name, 30);
        local recent = M.Reference(name, 7);
        local history = M.History(name, 30);
        local low;
        local i;
        for i = 1, table.getn(history) do
            if (not low or history[i].low < low) then low = history[i].low; end
        end
        Atr_SellMarketAverage:SetText("Market avg (30d): "..ShortMoney(average).." / item");
        Atr_SellMarketHistory:SetText("7d avg: "..ShortMoney(recent).." | Low: "..ShortMoney(low));
    end
    Atr_SellMarketAverage:Show();
    Atr_SellMarketHistory:Show();
    Atr_SellMarketHistoryButton:Show();
end

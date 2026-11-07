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

local function CompactSavedData()
    local metadata = AUCTIONATOR_SEARCH_METADATA;
    if (type(metadata) == "table") then
        local _, meta;
        for _, meta in pairs(metadata) do
            if (type(meta) == "table") then
                if (meta.category ~= nil) then meta.c = meta.c or meta.category; meta.category = nil; end
                if (meta.subcategory ~= nil) then meta.s = meta.s or meta.subcategory; meta.subcategory = nil; end
                if (meta.texture ~= nil) then meta.t = meta.t or meta.texture; meta.texture = nil; end
                if (meta.quality ~= nil) then meta.q = meta.q or meta.quality; meta.quality = nil; end
                if (type(meta.t) == "string" and Atr_MetadataCompactTexture) then
                    meta.t = Atr_MetadataCompactTexture(meta.t);
                end
            end
        end
    end
    local history = DB().history;
    local cutoff = tonumber(date("%Y%m%d", time() - MAX_DAYS * 86400));
    local name, series;
    for name, series in pairs(history) do
        if (type(series) ~= "table") then
            history[name] = nil;
        else
            local byDate = {};
            local i, v, dayNumber, total, count, low, last;
            for i = 1, table.getn(series) do
                v = series[i];
                if (type(v) == "table") then
                    if (type(v[1]) == "number") then
                        dayNumber, total, count, low, last = v[1], v[2], v[3], v[4], v[5];
                    else
                        dayNumber = type(v.day) == "string" and tonumber(string.gsub(v.day, "%-", "")) or nil;
                        total, count, low, last = v.sum, v.n, v.low, v.last;
                    end
                    if (dayNumber and dayNumber >= cutoff and type(count) == "number" and count > 0
                        and type(total) == "number" and type(low) == "number" and type(last) == "number") then
                        local prior = byDate[dayNumber];
                        if (prior) then
                            prior[2] = prior[2] + total;
                            prior[3] = prior[3] + count;
                            prior[4] = math.min(prior[4], low);
                            -- Keep last observation from later entries.
                            prior[5] = last;
                        else
                            byDate[dayNumber] = {dayNumber, total, count, low, last};
                        end
                    end
                end
            end
            local packed, days = {}, {};
            for dayNumber in pairs(byDate) do table.insert(days, dayNumber); end
            table.sort(days);
            local first = math.max(1, table.getn(days) - MAX_DAYS + 1);
            for i = first, table.getn(days) do table.insert(packed, byDate[days[i]]); end
            if (table.getn(packed) > 0) then history[name] = packed; else history[name] = nil; end
        end
    end
    -- The UI already ignores deals more than 48 hours old; remove them from disk too.
    local deals = DB().deals;
    for name, series in pairs(deals) do
        if (type(series) ~= "table" or type(series.t) ~= "number" or
            time() - series.t > 172800) then deals[name] = nil; end
    end
end

local migration = CreateFrame("Frame");
migration:RegisterEvent("PLAYER_LOGIN");
migration:SetScript("OnEvent", function()
    CompactSavedData();
    migration:UnregisterEvent("PLAYER_LOGIN");
end);

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
    local cutoffNumber = tonumber(date("%Y%m%d", cutoff));
    for i = 1, table.getn(series) do
        v = series[i];
        -- Compact entry: { YYYYMMDD, sum, count, lowest, last }.
        if (type(v) == "table" and type(v[1]) == "number"
            and v[1] >= cutoffNumber and type(v[3]) == "number" and v[3] > 0
            and ValidPrice(v[2] / v[3])) then
            local dayNumber = tostring(v[1]);
            local day = string.sub(dayNumber,1,4).."-"..string.sub(dayNumber,5,6).."-"..string.sub(dayNumber,7,8);
            byDay[day] = {day=day, average=math.floor(v[2]/v[3]+0.5),
                low=v[4], last=v[5], samples=v[3], source="Local"};
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
    local key = tonumber(date("%Y%m%d", now));
    local last = series[table.getn(series)];
    if (last and last[1] == key) then
        last[2] = last[2] + lowest;
        last[3] = last[3] + 1;
        last[4] = math.min(last[4] or lowest, lowest);
        last[5] = lowest;
    else
        table.insert(series, {key, lowest, 1, lowest, lowest});
    end
    local cutoff = tonumber(date("%Y%m%d", now - MAX_DAYS * 86400));
    while (table.getn(series) > 0 and
        (table.getn(series) > MAX_DAYS or (series[1][1] or 0) < cutoff)) do
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

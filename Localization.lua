
AtrL = AtrL or {};

local registry		= {};
local hooks			= {};
local appliedLocale	= nil;

-----------------------------------------

local function Atr_ResolveLocale (locale)

	if (type(locale) ~= "string" or locale == "") then
		locale = AUCTIONATOR_LOCALE;
	end
	if ((type(locale) ~= "string" or locale == "") and AUCTIONATOR_SAVEDVARS) then
		locale = AUCTIONATOR_SAVEDVARS.locale;
	end
	if (type(locale) ~= "string" or locale == "") then
		locale = GetLocale();
	end
	if (type(locale) ~= "string" or locale == "") then
		locale = "enUS";
	end
	return locale;
end

-----------------------------------------

function Atr_PickLocalizationTable (locale)

	locale = Atr_ResolveLocale (locale);

	local f = getglobal ("AtrBuildLTable_"..locale);
	if (type (f) == "function") then
		f();
	else
		AtrBuildLTable_enUS();
	end

	return locale;
end

-----------------------------------------

function ZT (s)

	if (s == nil or s == "") then
		return s;
	end

	if (AtrL) then
		local s1 = AtrL[s];
		if (s1 and s1 ~= "") then
			return s1;
		end
	end

	return s;
end

-----------------------------------------

local function Atr_SetLocalizedText (e)

	local obj = e.obj;
	obj:SetText (ZT(e.key));

	if (not e.nowiden and obj:GetObjectType() == "Button" and obj.GetTextWidth) then
		local oldwid = math.floor(obj:GetWidth());
		local newwid = math.floor(obj:GetTextWidth()) + 15;
		if (newwid > oldwid) then
			obj:SetWidth (newwid + 20);
		end
	end
end

-----------------------------------------

function Atr_LT (obj, key, nowiden)

	if (obj == nil or type(key) ~= "string" or key == "") then
		return obj;
	end

	local e = { obj = obj, key = key, nowiden = nowiden };
	tinsert (registry, e);
	Atr_SetLocalizedText (e);

	return obj;
end

-----------------------------------------

function Atr_OnLocalize (fn)

	tinsert (hooks, fn);
	fn ();
end

-----------------------------------------

function Atr_ApplyLocalization (force)

	local locale = Atr_PickLocalizationTable ();

	if (not force and locale == appliedLocale) then
		return;
	end
	appliedLocale = locale;

	local i;
	for i = 1, getn(registry) do
		Atr_SetLocalizedText (registry[i]);
	end

	for i = 1, getn(hooks) do
		hooks[i] ();
	end
end

function Atr_RefreshLocalization ()

	Atr_ApplyLocalization (true);
end

-----------------------------------------

Atr_PickLocalizationTable ();

local driver = CreateFrame ("Frame", "AtrLocalizationDriver");
driver:RegisterEvent ("VARIABLES_LOADED");
driver:RegisterEvent ("PLAYER_LOGIN");
driver:SetScript ("OnEvent", function()
	Atr_ApplyLocalization ();
end);

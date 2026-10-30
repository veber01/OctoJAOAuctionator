local pendingLocale, selectorFrame, confirmFrame

local function GetSavedLocale()

    if AUCTIONATOR_LOCALE and AUCTIONATOR_LOCALE ~= "" then return AUCTIONATOR_LOCALE end
    if AUCTIONATOR_SAVEDVARS and AUCTIONATOR_SAVEDVARS.locale then return AUCTIONATOR_SAVEDVARS.locale end
    return GetLocale() or "enUS"
end

local function SaveLocale(locale)

    AUCTIONATOR_LOCALE = locale
    if not AUCTIONATOR_SAVEDVARS then AUCTIONATOR_SAVEDVARS = {} end
    AUCTIONATOR_SAVEDVARS.locale = locale
end

local function ApplyLocale(locale)

    SaveLocale(locale)
    if type(Atr_PickLocalizationTable) == "function" then
        Atr_PickLocalizationTable(locale)
    end
    if type(Atr_LocalizeFrames) == "function" then
        Atr_LocalizeFrames()
    end
    if type(Atr_RefreshLocalization) == "function" then
        Atr_RefreshLocalization()
    end
end

local function CreateConfirmPopup()

    if confirmFrame then return confirmFrame end

    local f = CreateFrame("Frame", "Atr_LanguageConfirmFrame", UIParent)
    f:SetWidth(300); f:SetHeight(120); f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=32, insets={left=11,right=12,top=12,bottom=11}})
    f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end); f:Hide()

    local title=f:CreateFontString(nil,"ARTWORK","GameFontNormal")
    title:SetPoint("TOP",f,"TOP",0,-18); title:SetText("Change Auctionator language?")

    local msg=f:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    msg:SetPoint("TOP",title,"BOTTOM",0,-10); msg:SetText("Accepting will reload the UI to apply the language.")
    
    local accept=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    accept:SetWidth(90); accept:SetHeight(22); accept:SetPoint("BOTTOM",f,"BOTTOM",-52,18); accept:SetText("Accept")
    accept:SetScript("OnClick",function()
        if pendingLocale then
            ApplyLocale(pendingLocale)
            UIDropDownMenu_SetSelectedValue(selectorFrame.dropdown,pendingLocale)
            pendingLocale=nil
            f:Hide()
            ReloadUI()
            return
        end
        f:Hide()
    end)

    local cancel=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    cancel:SetWidth(90); cancel:SetHeight(22); cancel:SetPoint("LEFT",accept,"RIGHT",14,0); cancel:SetText("Cancel")
    cancel:SetScript("OnClick",function() pendingLocale=nil; UIDropDownMenu_SetSelectedValue(selectorFrame.dropdown,GetSavedLocale()); f:Hide() end)
    confirmFrame=f; return f
end

local function LanguageDropdown_Initialize()

    local choices = { {text="English (US)", value="enUS"}, {text="Magyar", value="huHU"} }
    local _, choice
    for _, choice in ipairs(choices) do
        local value, label = choice.value, choice.text
        local info=UIDropDownMenu_CreateInfo(); info.text=label; info.value=value
        info.func=function()
            local current=GetSavedLocale()
            if value == current then pendingLocale=nil; UIDropDownMenu_SetSelectedValue(selectorFrame.dropdown,current); return end
            pendingLocale=value; UIDropDownMenu_SetSelectedValue(selectorFrame.dropdown,value); CreateConfirmPopup():Show()
        end
        UIDropDownMenu_AddButton(info)
    end
end

local function CreateLanguageSelector()

    if selectorFrame or not Atr_BasicOptionsFrame then return end

    local label=Atr_BasicOptionsFrame:CreateFontString("Atr_LanguageSelectorLabel","ARTWORK","GameFontHighlight")
    label:SetPoint("TOPLEFT",Atr_BasicOptionsFrame,"TOPLEFT",30,-302); label:SetText("Language")

    local dropdown=CreateFrame("Frame","Atr_LanguageSelectorDropdown",Atr_BasicOptionsFrame,"UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT",Atr_BasicOptionsFrame,"TOPLEFT",150,-296)
    UIDropDownMenu_SetWidth(150,dropdown); UIDropDownMenu_JustifyText("LEFT",dropdown)
    UIDropDownMenu_Initialize(dropdown,LanguageDropdown_Initialize)
    UIDropDownMenu_SetSelectedValue(dropdown,GetSavedLocale())
    selectorFrame={label=label,dropdown=dropdown}
end

local eventFrame=CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent",function()
    CreateLanguageSelector()
    
    local locale = GetSavedLocale()
    if type(Atr_PickLocalizationTable) == "function" then
        Atr_PickLocalizationTable(locale)
    end
end)

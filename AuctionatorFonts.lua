local baseFont = GameFontNormalSmall
if baseFont then
    local font = CreateFont("AtrFontOrange")
    if font then
        local fontPath, fontSize, fontFlags = baseFont:GetFont()
        if fontPath and fontSize then
            font:SetFont(fontPath, fontSize, fontFlags)
        end
        font:SetTextColor(1, 0.5, 0.25)
    end
end

local lightGrayBase = GameFontNormalSmall
if lightGrayBase then
    local lightGray = CreateFont("GameFontLightGraySmall")
    if lightGray then
        local fontPath, fontSize, fontFlags = lightGrayBase:GetFont()
        if fontPath and fontSize then
            lightGray:SetFont(fontPath, fontSize, fontFlags)
        end
        lightGray:SetTextColor(0.8, 0.8, 0.8)
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local UI = {}
UI.toggleButtons = {}
UI.themedElements = {}
UI.tabButtons = {}
UI.currentTab = nil
UI.waitingBind = nil
UI.activeDropdown = nil
UI.prevBindKeys = {}
UI.arrowImages = {}
UI.arrowStates = {}
UI.MAX_ARROWS = 20
UI.modeBtns = {}

local Themes = {
    ["OG BUDA"] = {
        Bg=Color3.fromRGB(20,20,24), Sidebar=Color3.fromRGB(26,26,30),
        Card=Color3.fromRGB(32,32,38), CardHover=Color3.fromRGB(38,38,44),
        Accent=Color3.fromRGB(255,213,0), Text=Color3.fromRGB(235,235,240),
        TextDim=Color3.fromRGB(140,140,150), TextMuted=Color3.fromRGB(90,90,100),
        Border=Color3.fromRGB(45,45,52), SliderBg=Color3.fromRGB(50,50,58),
        Toggle=Color3.fromRGB(55,55,65)
    },
    ["BLAGOWHITE"] = {
        Bg=Color3.fromRGB(240,240,245), Sidebar=Color3.fromRGB(230,230,235),
        Card=Color3.fromRGB(250,250,252), CardHover=Color3.fromRGB(245,245,250),
        Accent=Color3.fromRGB(60,60,70), Text=Color3.fromRGB(25,25,30),
        TextDim=Color3.fromRGB(100,100,110), TextMuted=Color3.fromRGB(150,150,160),
        Border=Color3.fromRGB(210,210,220), SliderBg=Color3.fromRGB(220,220,225),
        Toggle=Color3.fromRGB(210,210,220)
    },
    ["SODALUV"] = {
        Bg=Color3.fromRGB(15,22,18), Sidebar=Color3.fromRGB(20,28,22),
        Card=Color3.fromRGB(25,35,28), CardHover=Color3.fromRGB(32,42,34),
        Accent=Color3.fromRGB(80,230,120), Text=Color3.fromRGB(230,240,232),
        TextDim=Color3.fromRGB(130,150,135), TextMuted=Color3.fromRGB(80,100,85),
        Border=Color3.fromRGB(40,55,45), SliderBg=Color3.fromRGB(45,60,48),
        Toggle=Color3.fromRGB(50,65,55)
    },
    ["BUSHIDO ZO"] = {
        Bg=Color3.fromRGB(22,15,15), Sidebar=Color3.fromRGB(28,20,20),
        Card=Color3.fromRGB(35,24,24), CardHover=Color3.fromRGB(42,28,28),
        Accent=Color3.fromRGB(240,60,60), Text=Color3.fromRGB(240,232,232),
        TextDim=Color3.fromRGB(150,130,130), TextMuted=Color3.fromRGB(100,80,80),
        Border=Color3.fromRGB(55,40,40), SliderBg=Color3.fromRGB(60,45,45),
        Toggle=Color3.fromRGB(65,50,50)
    },
    ["ДжонГарик"] = {
        Bg=Color3.fromRGB(10,14,22), Sidebar=Color3.fromRGB(14,20,32),
        Card=Color3.fromRGB(18,28,44), CardHover=Color3.fromRGB(24,36,56),
        Accent=Color3.fromRGB(0,170,255), Text=Color3.fromRGB(230,245,255),
        TextDim=Color3.fromRGB(145,180,210), TextMuted=Color3.fromRGB(95,130,165),
        Border=Color3.fromRGB(36,60,92), SliderBg=Color3.fromRGB(28,48,72),
        Toggle=Color3.fromRGB(30,50,76)
    },
    ["MIDNIGHT"] = {
        Bg=Color3.fromRGB(12,10,20), Sidebar=Color3.fromRGB(18,15,28),
        Card=Color3.fromRGB(24,20,36), CardHover=Color3.fromRGB(32,26,46),
        Accent=Color3.fromRGB(170,100,255), Text=Color3.fromRGB(235,230,250),
        TextDim=Color3.fromRGB(150,140,180), TextMuted=Color3.fromRGB(100,90,130),
        Border=Color3.fromRGB(50,42,72), SliderBg=Color3.fromRGB(42,36,60),
        Toggle=Color3.fromRGB(48,40,68)
    },
    ["OCEAN"] = {
        Bg=Color3.fromRGB(8,20,30), Sidebar=Color3.fromRGB(12,28,42),
        Card=Color3.fromRGB(18,38,54), CardHover=Color3.fromRGB(24,48,68),
        Accent=Color3.fromRGB(70,220,220), Text=Color3.fromRGB(220,240,250),
        TextDim=Color3.fromRGB(130,170,190), TextMuted=Color3.fromRGB(80,120,140),
        Border=Color3.fromRGB(40,72,96), SliderBg=Color3.fromRGB(30,58,80),
        Toggle=Color3.fromRGB(34,64,86)
    },
    ["SUNSET"] = {
        Bg=Color3.fromRGB(28,18,18), Sidebar=Color3.fromRGB(36,22,22),
        Card=Color3.fromRGB(46,28,26), CardHover=Color3.fromRGB(56,34,30),
        Accent=Color3.fromRGB(255,150,60), Text=Color3.fromRGB(250,235,225),
        TextDim=Color3.fromRGB(180,140,120), TextMuted=Color3.fromRGB(130,95,80),
        Border=Color3.fromRGB(72,44,38), SliderBg=Color3.fromRGB(62,38,32),
        Toggle=Color3.fromRGB(68,42,36)
    },
    ["MATRIX"] = {
        Bg=Color3.fromRGB(5,10,5), Sidebar=Color3.fromRGB(8,18,8),
        Card=Color3.fromRGB(12,28,12), CardHover=Color3.fromRGB(18,40,18),
        Accent=Color3.fromRGB(0,255,80), Text=Color3.fromRGB(180,255,180),
        TextDim=Color3.fromRGB(100,180,100), TextMuted=Color3.fromRGB(60,120,60),
        Border=Color3.fromRGB(30,60,30), SliderBg=Color3.fromRGB(22,48,22),
        Toggle=Color3.fromRGB(26,54,26)
    },
    ["PINK"] = {
        Bg=Color3.fromRGB(18,10,22), Sidebar=Color3.fromRGB(24,14,30),
        Card=Color3.fromRGB(32,18,40), CardHover=Color3.fromRGB(42,24,52),
        Accent=Color3.fromRGB(255,60,180), Text=Color3.fromRGB(245,230,245),
        TextDim=Color3.fromRGB(170,130,170), TextMuted=Color3.fromRGB(120,85,120),
        Border=Color3.fromRGB(60,35,70), SliderBg=Color3.fromRGB(50,28,60),
        Toggle=Color3.fromRGB(56,32,66)
    },
    ["ARCTIC"] = {
        Bg=Color3.fromRGB(20,26,32), Sidebar=Color3.fromRGB(26,34,42),
        Card=Color3.fromRGB(34,44,54), CardHover=Color3.fromRGB(42,54,66),
        Accent=Color3.fromRGB(140,210,255), Text=Color3.fromRGB(230,240,250),
        TextDim=Color3.fromRGB(150,170,190), TextMuted=Color3.fromRGB(100,120,140),
        Border=Color3.fromRGB(50,62,76), SliderBg=Color3.fromRGB(44,56,68),
        Toggle=Color3.fromRGB(48,60,72)
    },
    ["CYBER"] = {
        Bg=Color3.fromRGB(8,8,16), Sidebar=Color3.fromRGB(12,12,24),
        Card=Color3.fromRGB(18,18,36), CardHover=Color3.fromRGB(26,26,48),
        Accent=Color3.fromRGB(0,255,200), Text=Color3.fromRGB(220,240,235),
        TextDim=Color3.fromRGB(120,160,150), TextMuted=Color3.fromRGB(70,110,100),
        Border=Color3.fromRGB(30,40,50), SliderBg=Color3.fromRGB(24,34,44),
        Toggle=Color3.fromRGB(28,38,48)
    },
    ["BLOOD"] = {
        Bg=Color3.fromRGB(14,8,8), Sidebar=Color3.fromRGB(22,12,12),
        Card=Color3.fromRGB(30,16,16), CardHover=Color3.fromRGB(40,22,22),
        Accent=Color3.fromRGB(200,20,20), Text=Color3.fromRGB(240,220,220),
        TextDim=Color3.fromRGB(160,120,120), TextMuted=Color3.fromRGB(110,80,80),
        Border=Color3.fromRGB(50,28,28), SliderBg=Color3.fromRGB(44,24,24),
        Toggle=Color3.fromRGB(48,28,28)
    },
    ["GOLD"] = {
        Bg=Color3.fromRGB(16,14,10), Sidebar=Color3.fromRGB(24,20,14),
        Card=Color3.fromRGB(34,28,18), CardHover=Color3.fromRGB(44,36,24),
        Accent=Color3.fromRGB(218,165,32), Text=Color3.fromRGB(245,235,210),
        TextDim=Color3.fromRGB(170,155,120), TextMuted=Color3.fromRGB(120,108,80),
        Border=Color3.fromRGB(58,48,30), SliderBg=Color3.fromRGB(48,40,24),
        Toggle=Color3.fromRGB(52,44,28)
    },
    ["CUSTOM"] = {
        Bg=Color3.fromRGB(20,20,24), Sidebar=Color3.fromRGB(26,26,30),
        Card=Color3.fromRGB(32,32,38), CardHover=Color3.fromRGB(38,38,44),
        Accent=Color3.fromRGB(255,213,0), Text=Color3.fromRGB(235,235,240),
        TextDim=Color3.fromRGB(140,140,150), TextMuted=Color3.fromRGB(90,90,100),
        Border=Color3.fromRGB(45,45,52), SliderBg=Color3.fromRGB(50,50,58),
        Toggle=Color3.fromRGB(55,55,65)
    }
}
UI.Themes = Themes

local function buildCustomTheme()
    if not S then return end
    Themes["CUSTOM"].Bg=Color3.fromRGB(S.CustomThemeBgR or 20,S.CustomThemeBgG or 20,S.CustomThemeBgB or 24)
    Themes["CUSTOM"].Sidebar=Color3.fromRGB(S.CustomThemeSidebarR or 26,S.CustomThemeSidebarG or 26,S.CustomThemeSidebarB or 30)
    Themes["CUSTOM"].Card=Color3.fromRGB(S.CustomThemeCardR or 32,S.CustomThemeCardG or 32,S.CustomThemeCardB or 38)
    Themes["CUSTOM"].CardHover=Color3.fromRGB(math.min((S.CustomThemeCardR or 32)+8,255),math.min((S.CustomThemeCardG or 32)+8,255),math.min((S.CustomThemeCardB or 38)+8,255))
    Themes["CUSTOM"].Accent=Color3.fromRGB(S.CustomThemeAccentR or 255,S.CustomThemeAccentG or 213,S.CustomThemeAccentB or 0)
    Themes["CUSTOM"].Text=Color3.fromRGB(S.CustomThemeTextR or 235,S.CustomThemeTextG or 235,S.CustomThemeTextB or 240)
    Themes["CUSTOM"].TextDim=Color3.fromRGB(math.floor((S.CustomThemeTextR or 235)*0.6),math.floor((S.CustomThemeTextG or 235)*0.6),math.floor((S.CustomThemeTextB or 240)*0.6))
    Themes["CUSTOM"].TextMuted=Color3.fromRGB(math.floor((S.CustomThemeTextR or 235)*0.38),math.floor((S.CustomThemeTextG or 235)*0.38),math.floor((S.CustomThemeTextB or 240)*0.38))
    Themes["CUSTOM"].Border=Color3.fromRGB(math.min((S.CustomThemeCardR or 32)+13,255),math.min((S.CustomThemeCardG or 32)+13,255),math.min((S.CustomThemeCardB or 38)+14,255))
    Themes["CUSTOM"].SliderBg=Color3.fromRGB(math.min((S.CustomThemeCardR or 32)+18,255),math.min((S.CustomThemeCardG or 32)+18,255),math.min((S.CustomThemeCardB or 38)+20,255))
    Themes["CUSTOM"].Toggle=Color3.fromRGB(math.min((S.CustomThemeCardR or 32)+23,255),math.min((S.CustomThemeCardG or 32)+23,255),math.min((S.CustomThemeCardB or 38)+27,255))
end
UI.buildCustomTheme = buildCustomTheme
pcall(buildCustomTheme)

local C = {
    Bg=Themes["OG BUDA"].Bg, Sidebar=Themes["OG BUDA"].Sidebar,
    Card=Themes["OG BUDA"].Card, CardHover=Themes["OG BUDA"].CardHover,
    Accent=Themes["OG BUDA"].Accent, Text=Themes["OG BUDA"].Text,
    TextDim=Themes["OG BUDA"].TextDim, TextMuted=Themes["OG BUDA"].TextMuted,
    Green=Color3.fromRGB(120,220,120), Red=Color3.fromRGB(240,80,80),
    Border=Themes["OG BUDA"].Border, SliderBg=Themes["OG BUDA"].SliderBg,
    Toggle=Themes["OG BUDA"].Toggle
}
UI.C = C

if Themes[S.Theme] then
    for k,v in pairs(Themes[S.Theme]) do C[k]=v end
end

local function saveSettings()
    pcall(function()
        if not writefile then return end
        local data = {}
        for k,v in pairs(S) do
            if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then data[k]=v end
        end
        local bd = {}
        for k,v in pairs(Binds) do bd[k]=v and v.Name or "" end
        data._binds = bd
        local bm = {}
        for k,v in pairs(BindModes) do bm[k]=v end
        data._bindmodes = bm
        writefile("JG_Settings.json", game:GetService("HttpService"):JSONEncode(data))
    end)
end
UI.saveSettings = saveSettings

local function tw(obj,props,dur,style,dir)
    TweenService:Create(obj,TweenInfo.new(dur or 0.25,style or Enum.EasingStyle.Quint,dir or Enum.EasingDirection.Out),props):Play()
end
UI.tw = tw

local function reg(obj, prop, key)
    table.insert(UI.themedElements, {obj=obj, prop=prop, key=key})
end

local function makeDrag(frame,handle)
    local d,ds2,sp2
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            d=true ds2=i.Position sp2=frame.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then d=false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local delta=i.Position-ds2
            frame.Position=UDim2.new(sp2.X.Scale,sp2.X.Offset+delta.X,sp2.Y.Scale,sp2.Y.Offset+delta.Y)
        end
    end)
end

local function splitUtf8(str)
    local t = {}
    pcall(function()
        for _,c in utf8.codes(str) do t[#t+1] = utf8.char(c) end
    end)
    if #t == 0 then for i=1,#str do t[i]=str:sub(i,i) end end
    return t
end
UI.splitUtf8 = splitUtf8

local function getExploitAsset(url, fileName)
    local exists = false
    pcall(function() exists = isfile and isfile(fileName) or false end)
    if not exists and writefile then
        local ok,data = pcall(function() return game:HttpGet(url) end)
        if ok and data then pcall(function() writefile(fileName, data) end) end
    end
    if getcustomasset then
        local ok,res = pcall(function() return getcustomasset(fileName) end)
        if ok and res then return res end
    end
    if getsynasset then
        local ok,res = pcall(function() return getsynasset(fileName) end)
        if ok and res then return res end
    end
    return nil
end

local function colorToHex(color)
    local r = math.clamp(math.floor(color.R * 255 + 0.5), 0, 255)
    local g = math.clamp(math.floor(color.G * 255 + 0.5), 0, 255)
    local b = math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function hexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16) or 255
        local g = tonumber(hex:sub(3, 4), 16) or 255
        local b = tonumber(hex:sub(5, 6), 16) or 255
        return Color3.fromRGB(r, g, b)
    end
    return nil
end

local G = Instance.new("ScreenGui")
G.Name="JGCC" G.ResetOnSpawn=false G.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() G.Parent=game:GetService("CoreGui") end)
if not G.Parent then G.Parent=LP:WaitForChild("PlayerGui") end
UI.G = G

local overlayGui = Instance.new("ScreenGui")
overlayGui.Name="JGCC_OVERLAY" overlayGui.ResetOnSpawn=false
overlayGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling overlayGui.IgnoreGuiInset=true overlayGui.DisplayOrder=999999
pcall(function() overlayGui.Parent=game:GetService("CoreGui") end)
if not overlayGui.Parent then overlayGui.Parent=LP:WaitForChild("PlayerGui") end
UI.overlayGui = overlayGui

local overlayFrame = Instance.new("Frame")
overlayFrame.Parent=overlayGui overlayFrame.BackgroundTransparency=1
overlayFrame.Size=UDim2.new(1,0,1,0) overlayFrame.Position=UDim2.new(0,0,0,0) overlayFrame.BorderSizePixel=0
UI.overlayFrame = overlayFrame

local arrowAsset = getExploitAsset("https://raw.githubusercontent.com/serjratnikov-cpu/adlaldal/main/NewGui-main/pictures/gp.png","JG_arrow_texture.png")
local targetAsset = getExploitAsset("https://raw.githubusercontent.com/serjratnikov-cpu/adlaldal/main/NewGui-main/pictures/target.png","JG_target_texture.png")

for i=1,UI.MAX_ARROWS do
    local img = Instance.new("ImageLabel")
    img.Parent = overlayFrame img.BackgroundTransparency = 1
    img.AnchorPoint = Vector2.new(0.5,0.5) img.Size = UDim2.fromOffset(S.ArrowSize,S.ArrowSize)
    img.Position = UDim2.fromOffset(0,0) img.Visible = false img.BorderSizePixel = 0
    img.ZIndex = 50 img.Image = arrowAsset or ""
    img.ImageTransparency = 1 - (S.ArrowAlpha / 100) img.ImageColor3 = C.Accent
    UI.arrowImages[i] = img
    UI.arrowStates[i] = {x=0,y=0,r=0,init=false}
end

local targetESPImage = Instance.new("ImageLabel")
targetESPImage.Parent = overlayFrame targetESPImage.BackgroundTransparency = 1
targetESPImage.AnchorPoint = Vector2.new(0.5,0.5)
targetESPImage.Size = UDim2.fromOffset(S.TargetESPSize,S.TargetESPSize)
targetESPImage.Position = UDim2.fromOffset(0,0) targetESPImage.Visible = false
targetESPImage.BorderSizePixel = 0 targetESPImage.ZIndex = 60
targetESPImage.Image = targetAsset or "" targetESPImage.ImageTransparency = 0
targetESPImage.ImageColor3 = C.Accent
UI.targetESPImage = targetESPImage

local WF=Instance.new("Frame")
WF.Parent=G WF.BackgroundColor3=C.Card WF.Position=UDim2.new(0,12,0,12)
WF.AutomaticSize=Enum.AutomaticSize.X WF.Size=UDim2.new(0,0,0,30) WF.BorderSizePixel=0
Instance.new("UICorner",WF).CornerRadius=UDim.new(0,10)
reg(WF,"BackgroundColor3","Card")
local wmS=Instance.new("UIStroke") wmS.Color=C.Border wmS.Thickness=1 wmS.Parent=WF wmS.Transparency=0.4
reg(wmS,"Color","Border")
local wmP=Instance.new("UIPadding") wmP.PaddingLeft=UDim.new(0,12) wmP.PaddingRight=UDim.new(0,12) wmP.Parent=WF
local wmDot=Instance.new("Frame") wmDot.Parent=WF wmDot.BackgroundColor3=Color3.fromRGB(130,130,140)
wmDot.Size=UDim2.new(0,6,0,6) wmDot.Position=UDim2.new(0,-1,0.5,-3) wmDot.BorderSizePixel=0
Instance.new("UICorner",wmDot).CornerRadius=UDim.new(1,0)
local WL=Instance.new("TextLabel") WL.Parent=WF WL.BackgroundTransparency=1
WL.AutomaticSize=Enum.AutomaticSize.X WL.Size=UDim2.new(0,0,1,0) WL.Position=UDim2.new(0,10,0,0)
WL.Font=Enum.Font.GothamBold WL.Text="ДжонГарик.cc" WL.TextColor3=C.Text WL.TextSize=12
reg(WL,"TextColor3","Text") makeDrag(WF,WF)
UI.WF = WF UI.WL = WL

local BLF=Instance.new("Frame") BLF.Parent=G BLF.BackgroundColor3=C.Card
BLF.Position=UDim2.new(1,-210,0,12) BLF.Size=UDim2.new(0,198,0,28) BLF.BorderSizePixel=0
BLF.AutomaticSize=Enum.AutomaticSize.Y BLF.ClipsDescendants=true
Instance.new("UICorner",BLF).CornerRadius=UDim.new(0,12)
reg(BLF,"BackgroundColor3","Card")
local blScale=Instance.new("UIScale") blScale.Parent=BLF blScale.Scale=1
local blS=Instance.new("UIStroke") blS.Color=C.Border blS.Thickness=1 blS.Parent=BLF blS.Transparency=0.35
reg(blS,"Color","Border")
local blPad=Instance.new("UIPadding") blPad.PaddingLeft=UDim.new(0,14) blPad.PaddingRight=UDim.new(0,14)
blPad.PaddingTop=UDim.new(0,10) blPad.PaddingBottom=UDim.new(0,10) blPad.Parent=BLF
local blDot=Instance.new("Frame") blDot.Parent=BLF blDot.BackgroundColor3=Color3.fromRGB(130,130,140)
blDot.Size=UDim2.new(0,6,0,6) blDot.Position=UDim2.new(0,-4,0,4) blDot.BorderSizePixel=0
Instance.new("UICorner",blDot).CornerRadius=UDim.new(1,0)
local blTitle=Instance.new("TextLabel") blTitle.Parent=BLF blTitle.BackgroundTransparency=1
blTitle.Position=UDim2.new(0,8,0,0) blTitle.Size=UDim2.new(1,-8,0,14)
blTitle.Font=Enum.Font.GothamBold blTitle.Text="АКТИВНЫЕ БИНДЫ"
blTitle.TextColor3=C.Accent blTitle.TextSize=10 blTitle.TextXAlignment=Enum.TextXAlignment.Left
reg(blTitle,"TextColor3","Accent")
local blSep=Instance.new("Frame") blSep.Parent=BLF blSep.BackgroundColor3=C.Border
blSep.Position=UDim2.new(0,0,0,18) blSep.Size=UDim2.new(1,0,0,1) blSep.BorderSizePixel=0
blSep.BackgroundTransparency=0.4 reg(blSep,"BackgroundColor3","Border")
local BLL=Instance.new("TextLabel") BLL.Parent=BLF BLL.BackgroundTransparency=1
BLL.Size=UDim2.new(1,0,0,0) BLL.AutomaticSize=Enum.AutomaticSize.Y
BLL.Position=UDim2.new(0,0,0,22) BLL.Font=Enum.Font.GothamMedium
BLL.TextColor3=C.TextDim BLL.TextSize=11 BLL.TextXAlignment=Enum.TextXAlignment.Left
BLL.TextYAlignment=Enum.TextYAlignment.Top BLL.Text="" BLL.TextWrapped=true BLL.RichText=true BLL.LineHeight=1.25
reg(BLL,"TextColor3","TextDim")
BLF.Visible=false makeDrag(BLF,BLF)
UI.BLF = BLF UI.BLL = BLL UI.blScale = blScale UI.blDot = blDot

local MF=Instance.new("Frame") MF.Parent=G MF.BackgroundColor3=C.Bg MF.BorderSizePixel=0
MF.Position=UDim2.new(0.5,-340,0.5,-260) MF.Size=UDim2.new(0,680,0,520) MF.Visible=false MF.ClipsDescendants=true
Instance.new("UICorner",MF).CornerRadius=UDim.new(0,16) reg(MF,"BackgroundColor3","Bg")
local MS=Instance.new("UIStroke") MS.Color=C.Border MS.Thickness=1.5 MS.Parent=MF MS.Transparency=0 MS.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
reg(MS,"Color","Border")
UI.MF = MF

local Sidebar=Instance.new("Frame") Sidebar.Parent=MF Sidebar.BackgroundColor3=C.Sidebar
Sidebar.BorderSizePixel=0 Sidebar.Size=UDim2.new(0,120,1,0) Sidebar.Position=UDim2.new(0,0,0,0)
reg(Sidebar,"BackgroundColor3","Sidebar")
Instance.new("UICorner",Sidebar).CornerRadius=UDim.new(0,16)
local TopBar=Instance.new("Frame") TopBar.Parent=MF TopBar.BackgroundColor3=C.Sidebar TopBar.BorderSizePixel=0
TopBar.Size=UDim2.new(1,-120,0,58) TopBar.Position=UDim2.new(0,120,0,0)
reg(TopBar,"BackgroundColor3","Sidebar")
Instance.new("UICorner",TopBar).CornerRadius=UDim.new(0,16)
local tbMaskB=Instance.new("Frame") tbMaskB.Parent=TopBar tbMaskB.BackgroundColor3=C.Sidebar
tbMaskB.BorderSizePixel=0 tbMaskB.Size=UDim2.new(1,0,0,16) tbMaskB.Position=UDim2.new(0,0,1,-16)
reg(tbMaskB,"BackgroundColor3","Sidebar")
local tbMaskL=Instance.new("Frame") tbMaskL.Parent=TopBar tbMaskL.BackgroundColor3=C.Sidebar
tbMaskL.BorderSizePixel=0 tbMaskL.Size=UDim2.new(0,16,1,0) tbMaskL.Position=UDim2.new(0,0,0,0)
reg(tbMaskL,"BackgroundColor3","Sidebar")

local TL=Instance.new("TextLabel") TL.Parent=TopBar TL.BackgroundTransparency=1
TL.Position=UDim2.new(0,22,0,0) TL.Size=UDim2.new(0.6,0,1,0) TL.Font=Enum.Font.GothamBold
TL.Text="ДжонГарик.cc" TL.TextColor3=C.Text TL.TextSize=17 TL.TextXAlignment=Enum.TextXAlignment.Left
TL.TextYAlignment=Enum.TextYAlignment.Center TL.ZIndex=2 reg(TL,"TextColor3","Text")

local menuBindBtn=Instance.new("TextButton") menuBindBtn.Parent=TopBar menuBindBtn.BackgroundColor3=C.Card
menuBindBtn.Size=UDim2.new(0,130,0,30) menuBindBtn.Position=UDim2.new(1,-146,0.5,-15) menuBindBtn.BorderSizePixel=0
menuBindBtn.Font=Enum.Font.GothamMedium menuBindBtn.TextSize=10 menuBindBtn.TextColor3=C.TextDim
menuBindBtn.AutoButtonColor=false menuBindBtn.Text="Меню: ["..(Binds.Menu and Binds.Menu.Name or "RShift").."]"
menuBindBtn.ZIndex=2
Instance.new("UICorner",menuBindBtn).CornerRadius=UDim.new(0,8) reg(menuBindBtn,"BackgroundColor3","Card")
reg(menuBindBtn,"TextColor3","TextDim")
local mbStroke=Instance.new("UIStroke") mbStroke.Parent=menuBindBtn mbStroke.Color=C.Border mbStroke.Transparency=0.5
reg(mbStroke,"Color","Border")
menuBindBtn.MouseEnter:Connect(function() tw(menuBindBtn,{BackgroundColor3=C.CardHover},0.2) end)
menuBindBtn.MouseLeave:Connect(function() tw(menuBindBtn,{BackgroundColor3=C.Card},0.2) end)
menuBindBtn.MouseButton1Click:Connect(function()
    UI.waitingBind={name="Menu",label=menuBindBtn,prefix="Меню: "}
    menuBindBtn.Text="Меню: [...]" menuBindBtn.TextColor3=C.Red
end)
UI.menuBindBtn = menuBindBtn
makeDrag(MF,TopBar)

local Content=Instance.new("Frame") Content.Parent=MF Content.BackgroundTransparency=1
Content.Position=UDim2.new(0,132,0,68) Content.Size=UDim2.new(1,-144,1,-80) Content.ClipsDescendants=true

function UI.closeActiveDropdown()
    if UI.activeDropdown then
        if UI.activeDropdown.list then UI.activeDropdown.list.Visible = false end
        if UI.activeDropdown.dimmer then UI.activeDropdown.dimmer.Visible = false end
        UI.activeDropdown = nil
    end
end

function UI.createTab(id, label, order)
    local btn=Instance.new("TextButton") btn.Parent=Sidebar btn.BackgroundColor3=C.Card
    btn.Size=UDim2.new(1,-20,0,36) btn.Position=UDim2.new(0,10,0,18+(order-1)*44)
    btn.BorderSizePixel=0 btn.Text="" btn.AutoButtonColor=false btn.ZIndex=2
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10) btn.BackgroundTransparency=1
    local ic=Instance.new("TextLabel") ic.Parent=btn ic.BackgroundTransparency=1
    ic.Size=UDim2.new(1,-10,1,0) ic.Position=UDim2.new(0,10,0,0)
    ic.Font=Enum.Font.GothamBold ic.Text=label ic.TextColor3=C.TextDim ic.TextSize=11
    ic.TextXAlignment=Enum.TextXAlignment.Left ic.ZIndex=3
    reg(ic,"TextColor3","TextDim")
    local indicator=Instance.new("Frame") indicator.Parent=Sidebar indicator.BackgroundColor3=C.Accent
    indicator.AnchorPoint=Vector2.new(0,0.5) indicator.Size=UDim2.new(0,3,0,0)
    indicator.Position=UDim2.new(0,4,0,18+(order-1)*44+18) indicator.BorderSizePixel=0 indicator.ZIndex=2
    Instance.new("UICorner",indicator).CornerRadius=UDim.new(0,2) reg(indicator,"BackgroundColor3","Accent")
    local page=Instance.new("ScrollingFrame") page.Parent=Content page.BackgroundTransparency=1
    page.Size=UDim2.new(1,0,1,0) page.CanvasSize=UDim2.new(0,0,0,0) page.ScrollBarThickness=4
    page.ScrollBarImageColor3=C.Accent page.ScrollBarImageTransparency=0.4 page.BorderSizePixel=0
    page.ScrollingDirection=Enum.ScrollingDirection.Y page.AutomaticCanvasSize=Enum.AutomaticSize.Y
    page.Visible=false reg(page,"ScrollBarImageColor3","Accent")
    local ll=Instance.new("UIListLayout") ll.Parent=page ll.SortOrder=Enum.SortOrder.LayoutOrder
    ll.Padding=UDim.new(0,10) ll.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local pd=Instance.new("UIPadding") pd.Parent=page pd.PaddingTop=UDim.new(0,6) pd.PaddingBottom=UDim.new(0,10)
    btn.MouseEnter:Connect(function()
        if UI.currentTab and UI.currentTab.btn == btn then return end
        tw(ic,{TextColor3=C.Text},0.2)
    end)
    btn.MouseLeave:Connect(function()
        if UI.currentTab and UI.currentTab.btn == btn then return end
        tw(ic,{TextColor3=C.TextDim},0.2)
    end)
    btn.MouseButton1Click:Connect(function()
        if UI.currentTab and UI.currentTab.btn == btn then return end
        if UI.currentTab then
            UI.currentTab.page.Visible=false
            tw(UI.currentTab.indicator,{Size=UDim2.new(0,3,0,0)},0.25)
            tw(UI.currentTab.ic,{TextColor3=C.TextDim},0.25)
            tw(UI.currentTab.btn,{BackgroundTransparency=1},0.25)
        end
        page.Visible=true page.Position=UDim2.new(0,-20,0,0) page.CanvasPosition=Vector2.new(0,0)
        tw(page,{Position=UDim2.new(0,0,0,0)},0.35,Enum.EasingStyle.Quint)
        tw(indicator,{Size=UDim2.new(0,3,0,24)},0.3,Enum.EasingStyle.Back)
        tw(ic,{TextColor3=C.Accent},0.3) tw(btn,{BackgroundTransparency=0, BackgroundColor3=C.Card},0.3)
        UI.currentTab={page=page,indicator=indicator,ic=ic,btn=btn}
    end)
    UI.tabButtons[id]={btn=btn,page=page,indicator=indicator,ic=ic}
    return page
end

function UI.makeCard(parent, title, order, height)
    local card=Instance.new("Frame") card.Parent=parent card.BackgroundColor3=C.Card card.BorderSizePixel=0
    card.LayoutOrder=order card.ClipsDescendants=true card.Size=UDim2.new(1,-6,0,height or 200)
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,12) reg(card,"BackgroundColor3","Card")
    local st=Instance.new("UIStroke") st.Parent=card st.Color=C.Border st.Transparency=0.55
    reg(st,"Color","Border")
    local titleDot=Instance.new("Frame") titleDot.Parent=card titleDot.BackgroundColor3=C.Accent
    titleDot.Size=UDim2.new(0,4,0,14) titleDot.Position=UDim2.new(0,14,0,12) titleDot.BorderSizePixel=0
    Instance.new("UICorner",titleDot).CornerRadius=UDim.new(0,2) reg(titleDot,"BackgroundColor3","Accent")
    local titleLbl=Instance.new("TextLabel") titleLbl.Parent=card titleLbl.BackgroundTransparency=1
    titleLbl.Position=UDim2.new(0,24,0,10) titleLbl.Size=UDim2.new(1,-38,0,18)
    titleLbl.Font=Enum.Font.GothamBold titleLbl.Text=title titleLbl.TextColor3=C.Text titleLbl.TextSize=13
    titleLbl.TextXAlignment=Enum.TextXAlignment.Left reg(titleLbl,"TextColor3","Text")
    local body=Instance.new("Frame") body.Parent=card body.BackgroundTransparency=1
    body.Position=UDim2.new(0,14,0,36) body.Size=UDim2.new(1,-28,1,-46) body.ClipsDescendants=false
    local bl=Instance.new("UIListLayout") bl.Parent=body bl.SortOrder=Enum.SortOrder.LayoutOrder bl.Padding=UDim.new(0,8)
    return body
end

function UI.addToggle(parent, label, sKey, bKey, cb, order)
    local row=Instance.new("Frame") row.Parent=parent row.BackgroundTransparency=1
    row.Size=UDim2.new(1,0,0,26) row.LayoutOrder=order row.BorderSizePixel=0
    local hitBtn=Instance.new("TextButton") hitBtn.Parent=row hitBtn.BackgroundTransparency=1
    hitBtn.Size=UDim2.new(1,0,1,0) hitBtn.Text="" hitBtn.AutoButtonColor=false hitBtn.ZIndex=2
    local lbl=Instance.new("TextLabel") lbl.Parent=row lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,0,0,0) lbl.Size=UDim2.new(1,-150,1,0)
    lbl.Font=Enum.Font.GothamMedium lbl.Text=label lbl.TextColor3=C.Text lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=3 reg(lbl,"TextColor3","Text")
    local en = S[sKey] or false
    local togBg=Instance.new("Frame") togBg.Parent=row togBg.Size=UDim2.new(0,36,0,18)
    togBg.Position=UDim2.new(1,-36,0.5,-9) togBg.BorderSizePixel=0 togBg.ZIndex=3 togBg.BackgroundColor3=C.Toggle
    Instance.new("UICorner",togBg).CornerRadius=UDim.new(1,0) reg(togBg,"BackgroundColor3","Toggle")
    local togStroke=Instance.new("UIStroke") togStroke.Parent=togBg togStroke.Color=C.Border togStroke.Transparency=0.5
    reg(togStroke,"Color","Border")
    local togCircle=Instance.new("Frame") togCircle.Parent=togBg togCircle.Size=UDim2.new(0,14,0,14)
    togCircle.BorderSizePixel=0 togCircle.BackgroundColor3=Color3.new(1,1,1) togCircle.ZIndex=4
    Instance.new("UICorner",togCircle).CornerRadius=UDim.new(1,0)
    MF.ClipsDescendants = true
    local bl=nil local modeBtn=nil
    if bKey then
        bl=Instance.new("TextButton") bl.Parent=row bl.BackgroundColor3=C.Toggle
        bl.Position=UDim2.new(1,-138,0.5,-10) bl.Size=UDim2.new(0,50,0,20)
        bl.Font=Enum.Font.GothamBold bl.TextSize=9 bl.TextXAlignment=Enum.TextXAlignment.Center
        bl.AutoButtonColor=false bl.ZIndex=5 bl.BorderSizePixel=0
        Instance.new("UICorner",bl).CornerRadius=UDim.new(0,6)
        local bStroke=Instance.new("UIStroke") bStroke.Parent=bl bStroke.Color=C.Border bStroke.Transparency=0.5
        reg(bStroke,"Color","Border") reg(bl,"BackgroundColor3","Toggle")
        local bindKey = Binds[bKey] bl.Text=bindKey and bindKey.Name or "—" bl.TextColor3=C.TextMuted
        reg(bl,"TextColor3","TextMuted")
        bl.MouseEnter:Connect(function() tw(bl,{BackgroundColor3=C.CardHover},0.15) end)
        bl.MouseLeave:Connect(function() tw(bl,{BackgroundColor3=C.Toggle},0.15) end)
        modeBtn=Instance.new("TextButton") modeBtn.Parent=row modeBtn.BackgroundColor3=C.Toggle
        modeBtn.Position=UDim2.new(1,-82,0.5,-10) modeBtn.Size=UDim2.new(0,40,0,20)
        modeBtn.Font=Enum.Font.GothamBold modeBtn.TextSize=8 modeBtn.AutoButtonColor=false
        modeBtn.ZIndex=5 modeBtn.BorderSizePixel=0
        Instance.new("UICorner",modeBtn).CornerRadius=UDim.new(0,6)
        local mStroke=Instance.new("UIStroke") mStroke.Parent=modeBtn mStroke.Color=C.Border mStroke.Transparency=0.5
        reg(mStroke,"Color","Border") reg(modeBtn,"BackgroundColor3","Toggle")
        local curMode = BindModes[bKey] or "Toggle"
        modeBtn.Text = curMode == "Hold" and "HOLD" or "TOG"
        modeBtn.TextColor3 = curMode == "Hold" and C.Accent or C.TextMuted
        modeBtn.MouseEnter:Connect(function() tw(modeBtn,{BackgroundColor3=C.CardHover},0.15) end)
        modeBtn.MouseLeave:Connect(function() tw(modeBtn,{BackgroundColor3=C.Toggle},0.15) end)
        modeBtn.MouseButton1Click:Connect(function()
            local cm = BindModes[bKey] or "Toggle"
            if cm == "Toggle" then BindModes[bKey] = "Hold" modeBtn.Text = "HOLD" modeBtn.TextColor3 = C.Accent
            else BindModes[bKey] = "Toggle" modeBtn.Text = "TOG" modeBtn.TextColor3 = C.TextMuted end
            saveSettings()
        end)
        table.insert(UI.modeBtns, {btn=modeBtn, bKey=bKey})
    end
    local function setBg()
        if en then togBg.BackgroundColor3=C.Accent togCircle.Position=UDim2.new(1,-16,0.5,-7)
        else togBg.BackgroundColor3=C.Toggle togCircle.Position=UDim2.new(0,2,0.5,-7) end
    end
    local function u()
        if en then tw(togBg,{BackgroundColor3=C.Accent},0.25)
            tw(togCircle,{Position=UDim2.new(1,-16,0.5,-7),Size=UDim2.new(0,14,0,14)},0.3,Enum.EasingStyle.Back)
        else tw(togBg,{BackgroundColor3=C.Toggle},0.25)
            tw(togCircle,{Position=UDim2.new(0,2,0.5,-7),Size=UDim2.new(0,14,0,14)},0.3,Enum.EasingStyle.Back) end
        S[sKey]=en
    end
    setBg()
    local function toggle() en=not en u() if cb then cb(en) end saveSettings() end
    local function setOn() if not en then en=true u() if cb then cb(true) end end end
    local function setOff() if en then en=false u() if cb then cb(false) end end end
    hitBtn.MouseButton1Click:Connect(toggle)
    if bKey and bl then
        bl.MouseButton1Click:Connect(function()
            UI.waitingBind={name=bKey,label=bl} bl.Text="..." bl.TextColor3=C.Red
        end)
    end
    local entry = {toggle=toggle,getState=function() return en end,setBgColor=setBg,sKey=sKey,setOn=setOn,setOff=setOff}
    if bKey and bl then entry.bindLabel=bl end
    if bKey then
        if not UI.toggleButtons[bKey] then UI.toggleButtons[bKey] = {} end
        table.insert(UI.toggleButtons[bKey], entry)
    end
    return entry
end

function UI.addSlider(parent, label, mn, mx, sKey, cb, order)
    local row=Instance.new("Frame") row.Parent=parent row.BackgroundTransparency=1
    row.Size=UDim2.new(1,0,0,26) row.LayoutOrder=order
    local lbl=Instance.new("TextLabel") lbl.Parent=row lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,0,0,0) lbl.Size=UDim2.new(0,90,1,0)
    lbl.Font=Enum.Font.GothamMedium lbl.Text=label lbl.TextColor3=C.Text lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left reg(lbl,"TextColor3","Text")
    local d=math.clamp(S[sKey] or mn,mn,mx)
    local vl=Instance.new("TextLabel") vl.Parent=row vl.BackgroundTransparency=1
    vl.Position=UDim2.new(0,90,0,0) vl.Size=UDim2.new(0,40,1,0)
    vl.Font=Enum.Font.GothamBold vl.Text=tostring(d) vl.TextColor3=C.Accent vl.TextSize=11
    vl.TextXAlignment=Enum.TextXAlignment.Left reg(vl,"TextColor3","Accent")
    local tr=Instance.new("Frame") tr.Parent=row tr.BackgroundColor3=C.SliderBg
    tr.Position=UDim2.new(0,134,0.5,-4) tr.Size=UDim2.new(1,-134,0,8)
    Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0) reg(tr,"BackgroundColor3","SliderBg")
    local fl=Instance.new("Frame") fl.Parent=tr fl.BackgroundColor3=C.Accent
    fl.Size=UDim2.new(math.clamp((d-mn)/(mx-mn),0,1),0,1,0) fl.BorderSizePixel=0
    Instance.new("UICorner",fl).CornerRadius=UDim.new(1,0) reg(fl,"BackgroundColor3","Accent")
    local knob=Instance.new("Frame") knob.Parent=fl knob.BackgroundColor3=Color3.new(1,1,1)
    knob.Size=UDim2.new(0,16,0,16) knob.Position=UDim2.new(1,-8,0.5,-8) knob.BorderSizePixel=0 knob.ZIndex=3
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local knobStr=Instance.new("UIStroke") knobStr.Parent=knob knobStr.Color=C.Accent knobStr.Thickness=2
    reg(knobStr,"Color","Accent")
    local sb=Instance.new("TextButton") sb.Parent=tr sb.BackgroundTransparency=1
    sb.Size=UDim2.new(1,0,1,18) sb.Position=UDim2.new(0,0,0,-9) sb.Text="" sb.ZIndex=5 sb.AutoButtonColor=false
    local sld=false
    sb.MouseButton1Down:Connect(function() sld=true tw(knob,{Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-10,0.5,-10)},0.15,Enum.EasingStyle.Back) end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 and sld then
            sld=false tw(knob,{Size=UDim2.new(0,16,0,16),Position=UDim2.new(1,-8,0.5,-8)},0.2,Enum.EasingStyle.Back) saveSettings()
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if sld and i.UserInputType==Enum.UserInputType.MouseMovement then
            local r=math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
            local v=math.floor(mn+(mx-mn)*r) fl.Size=UDim2.new(r,0,1,0) vl.Text=tostring(v) S[sKey]=v
            if cb then cb(v) end
        end
    end)
end

function UI.addButton(parent, label, cb, order)
    local btn=Instance.new("TextButton") btn.Parent=parent btn.BackgroundColor3=C.Toggle
    btn.Size=UDim2.new(1,0,0,28) btn.BorderSizePixel=0 btn.LayoutOrder=order
    btn.Font=Enum.Font.GothamMedium btn.Text=label btn.TextColor3=C.Text btn.TextSize=11 btn.AutoButtonColor=false
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    reg(btn,"BackgroundColor3","Toggle") reg(btn,"TextColor3","Text")
    local st=Instance.new("UIStroke") st.Parent=btn st.Color=C.Border st.Transparency=0.5 reg(st,"Color","Border")
    btn.MouseButton1Click:Connect(function()
        tw(btn,{BackgroundColor3=C.Accent},0.1)
        task.delay(0.15,function() tw(btn,{BackgroundColor3=C.Toggle},0.2) end) cb()
    end)
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.CardHover},0.2) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.Toggle},0.2) end)
end

function UI.addTextBox(parent, label, sKey, order, placeholder)
    local row=Instance.new("Frame") row.Parent=parent row.BackgroundTransparency=1
    row.Size=UDim2.new(1,0,0,48) row.LayoutOrder=order
    local lbl=Instance.new("TextLabel") lbl.Parent=row lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,0,0,0) lbl.Size=UDim2.new(1,0,0,16)
    lbl.Font=Enum.Font.GothamBold lbl.Text=label lbl.TextColor3=C.Text lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left reg(lbl,"TextColor3","Text")
    local box=Instance.new("TextBox") box.Parent=row box.BackgroundColor3=C.Toggle
    box.Position=UDim2.new(0,0,0,20) box.Size=UDim2.new(1,0,0,26) box.BorderSizePixel=0
    box.Font=Enum.Font.GothamMedium box.TextSize=11 box.TextColor3=C.Text
    box.PlaceholderText=placeholder or "" box.Text=tostring(S[sKey] or "") box.ClearTextOnFocus=false
    box.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,8) reg(box,"BackgroundColor3","Toggle") reg(box,"TextColor3","Text")
    local pad=Instance.new("UIPadding") pad.Parent=box pad.PaddingLeft=UDim.new(0,10) pad.PaddingRight=UDim.new(0,10)
    local st=Instance.new("UIStroke") st.Parent=box st.Color=C.Border st.Transparency=0.4 reg(st,"Color","Border")
    box.FocusLost:Connect(function() S[sKey]=box.Text saveSettings() end)
end

function UI.addDropdown(parent, label, options, sKey, cb, order)
    local row=Instance.new("Frame") row.Parent=parent row.BackgroundTransparency=1
    row.Size=UDim2.new(1,0,0,48) row.LayoutOrder=order
    local lbl=Instance.new("TextLabel") lbl.Parent=row lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,0,0,0) lbl.Size=UDim2.new(1,0,0,16)
    lbl.Font=Enum.Font.GothamBold lbl.Text=label lbl.TextColor3=C.Text lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left reg(lbl,"TextColor3","Text")
    local btn=Instance.new("TextButton") btn.Parent=row btn.BackgroundColor3=C.Toggle
    btn.Position=UDim2.new(0,0,0,20) btn.Size=UDim2.new(1,0,0,26) btn.BorderSizePixel=0
    btn.Font=Enum.Font.GothamMedium btn.TextSize=11 btn.TextXAlignment=Enum.TextXAlignment.Left
    btn.AutoButtonColor=false btn.ClipsDescendants=true
    btn.Text="   "..(S[sKey] or options[1]).."   ▼" btn.TextColor3=C.Text
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8) reg(btn,"BackgroundColor3","Toggle") reg(btn,"TextColor3","Text")
    local st=Instance.new("UIStroke") st.Parent=btn st.Color=C.Border st.Transparency=0.4 reg(st,"Color","Border")
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.CardHover},0.15) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.Toggle},0.15) end)
    local dimmer = Instance.new("TextButton") dimmer.Parent=G dimmer.BackgroundColor3=Color3.new(0,0,0)
    dimmer.BackgroundTransparency=1 dimmer.Size=UDim2.new(1,0,1,0) dimmer.Position=UDim2.new(0,0,0,0)
    dimmer.BorderSizePixel=0 dimmer.Text="" dimmer.AutoButtonColor=false dimmer.ZIndex=149 dimmer.Visible=false
    local listH = math.min(#options * 28, 260)
    local list=Instance.new("ScrollingFrame") list.Parent=G list.BackgroundColor3=C.Bg
    list.Size=UDim2.fromOffset(220, listH) list.Position=UDim2.fromOffset(0,0)
    list.BorderSizePixel=0 list.Visible=false list.ZIndex=150 list.ClipsDescendants=true
    list.ScrollBarThickness=3 list.ScrollBarImageColor3=C.Accent list.ScrollBarImageTransparency=0.3
    list.CanvasSize=UDim2.new(0,0,0,#options*28) list.AutomaticCanvasSize=Enum.AutomaticSize.Y
    Instance.new("UICorner",list).CornerRadius=UDim.new(0,10) reg(list,"BackgroundColor3","Bg")
    reg(list,"ScrollBarImageColor3","Accent")
    local lsSt=Instance.new("UIStroke") lsSt.Parent=list lsSt.Color=C.Border lsSt.Transparency=0.15 lsSt.Thickness=1.5
    reg(lsSt,"Color","Border")
    local lo=Instance.new("UIListLayout") lo.Parent=list lo.SortOrder=Enum.SortOrder.LayoutOrder
    local lsPad=Instance.new("UIPadding") lsPad.Parent=list lsPad.PaddingTop=UDim.new(0,4) lsPad.PaddingBottom=UDim.new(0,4)
    for i,opt in ipairs(options) do
        local o=Instance.new("TextButton") o.Parent=list o.BackgroundColor3=C.Bg o.BackgroundTransparency=1
        o.Size=UDim2.new(1,-6,0,28) o.LayoutOrder=i o.BorderSizePixel=0
        o.Font=Enum.Font.GothamMedium o.Text="   "..opt o.TextColor3=C.TextDim o.TextSize=11
        o.TextXAlignment=Enum.TextXAlignment.Left o.AutoButtonColor=false o.ZIndex=151
        Instance.new("UICorner",o).CornerRadius=UDim.new(0,6)
        reg(o,"TextColor3","TextDim")
        o.MouseEnter:Connect(function() tw(o,{BackgroundTransparency=0,BackgroundColor3=C.Card,TextColor3=C.Text},0.12) end)
        o.MouseLeave:Connect(function() tw(o,{BackgroundTransparency=1,TextColor3=C.TextDim},0.12) end)
        o.MouseButton1Click:Connect(function()
            S[sKey]=opt btn.Text="   "..opt.."   ▼"
            UI.closeActiveDropdown()
            if cb then cb(opt) end saveSettings()
        end)
    end
    dimmer.MouseButton1Click:Connect(function() UI.closeActiveDropdown() end)
    btn.MouseButton1Click:Connect(function()
        if UI.activeDropdown and UI.activeDropdown.list == list then UI.closeActiveDropdown() return end
        UI.closeActiveDropdown()
        local absPos = btn.AbsolutePosition local absSize = btn.AbsoluteSize
        list.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
        list.Size = UDim2.fromOffset(math.max(absSize.X, 220), listH)
        list.CanvasPosition = Vector2.new(0,0)
        dimmer.Visible = true list.Visible = true
        UI.activeDropdown = {list=list, dimmer=dimmer}
    end)
end

function UI.addDropdownMapped(parent, label, optionPairs, sKey, cb, order)
    local displays, valToRu = {}, {}
    for i,pr in ipairs(optionPairs) do displays[i]=pr.ru valToRu[pr.val]=pr.ru end
    local row=Instance.new("Frame") row.Parent=parent row.BackgroundTransparency=1
    row.Size=UDim2.new(1,0,0,48) row.LayoutOrder=order
    local lbl=Instance.new("TextLabel") lbl.Parent=row lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,0,0,0) lbl.Size=UDim2.new(1,0,0,16)
    lbl.Font=Enum.Font.GothamBold lbl.Text=label lbl.TextColor3=C.Text lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left reg(lbl,"TextColor3","Text")
    local btn=Instance.new("TextButton") btn.Parent=row btn.BackgroundColor3=C.Toggle
    btn.Position=UDim2.new(0,0,0,20) btn.Size=UDim2.new(1,0,0,26) btn.BorderSizePixel=0
    btn.Font=Enum.Font.GothamMedium btn.TextSize=11 btn.TextXAlignment=Enum.TextXAlignment.Left
    btn.AutoButtonColor=false btn.ClipsDescendants=true
    btn.Text="   "..(valToRu[S[sKey]] or displays[1]).."   ▼" btn.TextColor3=C.Text
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8) reg(btn,"BackgroundColor3","Toggle") reg(btn,"TextColor3","Text")
    local st=Instance.new("UIStroke") st.Parent=btn st.Color=C.Border st.Transparency=0.4 reg(st,"Color","Border")
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.CardHover},0.15) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.Toggle},0.15) end)
    local dimmer = Instance.new("TextButton") dimmer.Parent=G dimmer.BackgroundColor3=Color3.new(0,0,0)
    dimmer.BackgroundTransparency=1 dimmer.Size=UDim2.new(1,0,1,0) dimmer.Position=UDim2.new(0,0,0,0)
    dimmer.BorderSizePixel=0 dimmer.Text="" dimmer.AutoButtonColor=false dimmer.ZIndex=149 dimmer.Visible=false
    local listH = math.min(#optionPairs * 28, 260)
    local list=Instance.new("ScrollingFrame") list.Parent=G list.BackgroundColor3=C.Bg
    list.Size=UDim2.fromOffset(220, listH) list.Position=UDim2.fromOffset(0,0)
    list.BorderSizePixel=0 list.Visible=false list.ZIndex=150 list.ClipsDescendants=true
    list.ScrollBarThickness=3 list.ScrollBarImageColor3=C.Accent list.ScrollBarImageTransparency=0.3
    list.CanvasSize=UDim2.new(0,0,0,#optionPairs*28) list.AutomaticCanvasSize=Enum.AutomaticSize.Y
    Instance.new("UICorner",list).CornerRadius=UDim.new(0,10) reg(list,"BackgroundColor3","Bg")
    reg(list,"ScrollBarImageColor3","Accent")
    local lsSt=Instance.new("UIStroke") lsSt.Parent=list lsSt.Color=C.Border lsSt.Transparency=0.15 lsSt.Thickness=1.5
    reg(lsSt,"Color","Border")
    local lo=Instance.new("UIListLayout") lo.Parent=list lo.SortOrder=Enum.SortOrder.LayoutOrder
    local lsPad=Instance.new("UIPadding") lsPad.Parent=list lsPad.PaddingTop=UDim.new(0,4) lsPad.PaddingBottom=UDim.new(0,4)
    for i,pr in ipairs(optionPairs) do
        local o=Instance.new("TextButton") o.Parent=list o.BackgroundColor3=C.Bg o.BackgroundTransparency=1
        o.Size=UDim2.new(1,-6,0,28) o.LayoutOrder=i o.BorderSizePixel=0
        o.Font=Enum.Font.GothamMedium o.Text="   "..pr.ru o.TextColor3=C.TextDim o.TextSize=11
        o.TextXAlignment=Enum.TextXAlignment.Left o.AutoButtonColor=false o.ZIndex=151
        Instance.new("UICorner",o).CornerRadius=UDim.new(0,6)
        reg(o,"TextColor3","TextDim")
        o.MouseEnter:Connect(function() tw(o,{BackgroundTransparency=0,BackgroundColor3=C.Card,TextColor3=C.Text},0.12) end)
        o.MouseLeave:Connect(function() tw(o,{BackgroundTransparency=1,TextColor3=C.TextDim},0.12) end)
        o.MouseButton1Click:Connect(function()
            S[sKey]=pr.val btn.Text="   "..pr.ru.."   ▼"
            UI.closeActiveDropdown()
            if cb then cb(pr.val) end saveSettings()
        end)
    end
    dimmer.MouseButton1Click:Connect(function() UI.closeActiveDropdown() end)
    btn.MouseButton1Click:Connect(function()
        if UI.activeDropdown and UI.activeDropdown.list == list then UI.closeActiveDropdown() return end
        UI.closeActiveDropdown()
        local absPos = btn.AbsolutePosition local absSize = btn.AbsoluteSize
        list.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
        list.Size = UDim2.fromOffset(math.max(absSize.X, 220), listH)
        list.CanvasPosition = Vector2.new(0,0)
        dimmer.Visible = true list.Visible = true
        UI.activeDropdown = {list=list, dimmer=dimmer}
    end)
end

function UI.openColorPicker(initialColor, callback)
    local currentH, currentS, currentV = initialColor:ToHSV()
    if currentH ~= currentH then currentH = 0 end
    if currentS ~= currentS then currentS = 1 end
    if currentV ~= currentV then currentV = 1 end
    local pickerConnections = {}
    local dimmer = Instance.new("TextButton") dimmer.Parent = G dimmer.BackgroundColor3 = Color3.new(0,0,0)
    dimmer.BackgroundTransparency = 1 dimmer.Size = UDim2.new(1,0,1,0) dimmer.Position = UDim2.new(0,0,0,0)
    dimmer.BorderSizePixel = 0 dimmer.Text = "" dimmer.AutoButtonColor = false dimmer.ZIndex = 100
    local pickerWidth = 420 local pickerHeight = 460
    local mainFrame = Instance.new("Frame") mainFrame.Parent = G mainFrame.BackgroundColor3 = C.Bg
    mainFrame.BorderSizePixel = 0 mainFrame.AnchorPoint = Vector2.new(0.5,0.5)
    mainFrame.Position = UDim2.new(0.5,0,0.5,20) mainFrame.Size = UDim2.new(0,0,0,0)
    mainFrame.ClipsDescendants = true mainFrame.ZIndex = 101 mainFrame.BackgroundTransparency=1
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,14)
    local mainStroke = Instance.new("UIStroke") mainStroke.Parent = mainFrame mainStroke.Color = C.Border mainStroke.Thickness = 1.5 mainStroke.Transparency = 0.2
    local titleBar = Instance.new("Frame") titleBar.Parent = mainFrame titleBar.BackgroundColor3 = C.Sidebar titleBar.BorderSizePixel = 0 titleBar.Size = UDim2.new(1,0,0,44) titleBar.Position = UDim2.new(0,0,0,0) titleBar.ZIndex = 102
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,14)
    local titleBarMask = Instance.new("Frame") titleBarMask.Parent = titleBar titleBarMask.BackgroundColor3 = C.Sidebar titleBarMask.BorderSizePixel = 0 titleBarMask.Size = UDim2.new(1,0,0,16) titleBarMask.Position = UDim2.new(0,0,1,-16) titleBarMask.ZIndex = 102
    local titleDot = Instance.new("Frame") titleDot.Parent = titleBar titleDot.BackgroundColor3 = C.Accent titleDot.Size = UDim2.new(0,8,0,8) titleDot.Position = UDim2.new(0,16,0.5,-4) titleDot.BorderSizePixel = 0 titleDot.ZIndex = 103 Instance.new("UICorner", titleDot).CornerRadius = UDim.new(1,0)
    local titleText = Instance.new("TextLabel") titleText.Parent = titleBar titleText.BackgroundTransparency = 1 titleText.Position = UDim2.new(0,32,0,0) titleText.Size = UDim2.new(1,-40,1,0) titleText.Font = Enum.Font.GothamBold titleText.Text = "Выбор цвета" titleText.TextColor3 = C.Text titleText.TextSize = 14 titleText.TextXAlignment = Enum.TextXAlignment.Left titleText.ZIndex = 103
    makeDrag(mainFrame, titleBar)
    local contentArea = Instance.new("Frame") contentArea.Parent = mainFrame contentArea.BackgroundTransparency = 1 contentArea.Position = UDim2.new(0,16,0,54) contentArea.Size = UDim2.new(1,-32,1,-64) contentArea.ZIndex = 102
    local paletteSize = 240
    local paletteFrame = Instance.new("Frame") paletteFrame.Parent = contentArea paletteFrame.BackgroundColor3 = Color3.fromHSV(currentH,1,1) paletteFrame.BorderSizePixel = 0 paletteFrame.Position = UDim2.new(0,0,0,0) paletteFrame.Size = UDim2.new(0,paletteSize,0,paletteSize) paletteFrame.ZIndex = 103 paletteFrame.ClipsDescendants = true
    Instance.new("UICorner", paletteFrame).CornerRadius = UDim.new(0,12)
    Instance.new("UIStroke", paletteFrame).Color = C.Border
    local whiteGrad = Instance.new("Frame") whiteGrad.Parent = paletteFrame whiteGrad.BackgroundColor3 = Color3.new(1,1,1) whiteGrad.BorderSizePixel = 0 whiteGrad.Size = UDim2.new(1,0,1,0) whiteGrad.ZIndex = 104
    Instance.new("UICorner", whiteGrad).CornerRadius = UDim.new(0,12)
    local wg = Instance.new("UIGradient") wg.Parent = whiteGrad wg.Color = ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1)) wg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}) wg.Rotation = 0
    local blackGrad = Instance.new("Frame") blackGrad.Parent = paletteFrame blackGrad.BackgroundColor3 = Color3.new(0,0,0) blackGrad.BorderSizePixel = 0 blackGrad.Size = UDim2.new(1,0,1,0) blackGrad.ZIndex = 105
    Instance.new("UICorner", blackGrad).CornerRadius = UDim.new(0,12)
    local bg = Instance.new("UIGradient") bg.Parent = blackGrad bg.Color = ColorSequence.new(Color3.new(0,0,0),Color3.new(0,0,0)) bg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}) bg.Rotation = 90
    local svCursor = Instance.new("Frame") svCursor.Parent = paletteFrame svCursor.BackgroundColor3 = Color3.new(1,1,1) svCursor.Size = UDim2.new(0,18,0,18) svCursor.AnchorPoint = Vector2.new(0.5,0.5) svCursor.BorderSizePixel = 0 svCursor.ZIndex = 107 Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1,0)
    local svCursorInner = Instance.new("Frame") svCursorInner.Parent = svCursor svCursorInner.BackgroundColor3 = initialColor svCursorInner.Size = UDim2.new(1,-4,1,-4) svCursorInner.AnchorPoint = Vector2.new(0.5,0.5) svCursorInner.Position = UDim2.new(0.5,0,0.5,0) svCursorInner.BorderSizePixel = 0 svCursorInner.ZIndex = 108 Instance.new("UICorner", svCursorInner).CornerRadius = UDim.new(1,0)
    Instance.new("UIStroke", svCursor).Color = Color3.new(0,0,0)
    local paletteHit = Instance.new("TextButton") paletteHit.Parent = paletteFrame paletteHit.BackgroundTransparency = 1 paletteHit.Size = UDim2.new(1,0,1,0) paletteHit.Text = "" paletteHit.ZIndex = 109 paletteHit.AutoButtonColor=false
    local hueBarWidth = 26
    local hueBarFrame = Instance.new("Frame") hueBarFrame.Parent = contentArea hueBarFrame.BackgroundColor3 = Color3.new(1,1,1) hueBarFrame.BorderSizePixel = 0 hueBarFrame.Position = UDim2.new(0,paletteSize+14,0,0) hueBarFrame.Size = UDim2.new(0,hueBarWidth,0,paletteSize) hueBarFrame.ZIndex = 103 hueBarFrame.ClipsDescendants = true
    Instance.new("UICorner", hueBarFrame).CornerRadius = UDim.new(0,12)
    Instance.new("UIStroke", hueBarFrame).Color = C.Border
    local hueGrad = Instance.new("UIGradient") hueGrad.Parent = hueBarFrame hueGrad.Rotation = 90
    local hueKP = {} for i=0,12 do local h=i/12 table.insert(hueKP, ColorSequenceKeypoint.new(math.min(h,1), Color3.fromHSV(math.min(h,0.999),1,1))) end
    hueGrad.Color = ColorSequence.new(hueKP)
    local hueCursor = Instance.new("Frame") hueCursor.Parent = hueBarFrame hueCursor.BackgroundColor3 = Color3.new(1,1,1) hueCursor.Size = UDim2.new(1,6,0,10) hueCursor.AnchorPoint = Vector2.new(0.5,0.5) hueCursor.Position = UDim2.new(0.5,0,currentH,0) hueCursor.BorderSizePixel = 0 hueCursor.ZIndex = 105 Instance.new("UICorner", hueCursor).CornerRadius = UDim.new(0,5)
    Instance.new("UIStroke", hueCursor).Color = Color3.new(0,0,0)
    local hueHit = Instance.new("TextButton") hueHit.Parent = hueBarFrame hueHit.BackgroundTransparency = 1 hueHit.Size = UDim2.new(1,0,1,0) hueHit.Text = "" hueHit.ZIndex = 106 hueHit.AutoButtonColor=false
    local rightPanelX = paletteSize+14+hueBarWidth+14 local rightPanelWidth = pickerWidth-32-rightPanelX
    local previewFrame = Instance.new("Frame") previewFrame.Parent = contentArea previewFrame.BackgroundColor3 = C.Card previewFrame.BorderSizePixel = 0 previewFrame.Position = UDim2.new(0,rightPanelX,0,0) previewFrame.Size = UDim2.new(0,rightPanelWidth,0,54) previewFrame.ZIndex = 103 Instance.new("UICorner", previewFrame).CornerRadius = UDim.new(0,10)
    local previewColor = Instance.new("Frame") previewColor.Parent = previewFrame previewColor.BackgroundColor3 = initialColor previewColor.BorderSizePixel = 0 previewColor.Size = UDim2.new(1,-8,1,-8) previewColor.Position = UDim2.new(0,4,0,4) previewColor.ZIndex = 104 Instance.new("UICorner", previewColor).CornerRadius = UDim.new(0,8)
    local hexBox = Instance.new("TextBox") hexBox.Parent = contentArea hexBox.BackgroundColor3 = C.Card hexBox.BorderSizePixel = 0 hexBox.Position = UDim2.new(0,rightPanelX,0,78) hexBox.Size = UDim2.new(0,rightPanelWidth,0,28) hexBox.Font = Enum.Font.GothamBold hexBox.TextSize = 12 hexBox.TextColor3 = C.Text hexBox.Text = colorToHex(initialColor) hexBox.ClearTextOnFocus = false hexBox.ZIndex = 104 Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0,8)
    local rgbBoxes = {}
    for i=1,3 do
        local yOffset = 116+(i-1)*40
        local rgbBox = Instance.new("TextBox") rgbBox.Parent = contentArea rgbBox.BackgroundColor3 = C.Card rgbBox.BorderSizePixel = 0 rgbBox.Position = UDim2.new(0,rightPanelX,0,yOffset+14) rgbBox.Size = UDim2.new(0,rightPanelWidth,0,24) rgbBox.Font = Enum.Font.GothamBold rgbBox.TextSize = 11 rgbBox.TextColor3 = C.Text rgbBox.ClearTextOnFocus = true rgbBox.ZIndex = 104 Instance.new("UICorner", rgbBox).CornerRadius = UDim.new(0,6)
        rgbBoxes[i] = rgbBox
    end
    local function getCurrentColor() return Color3.fromHSV(math.clamp(currentH,0,0.999),math.clamp(currentS,0,1),math.clamp(currentV,0,1)) end
    local function updateAll()
        local color = getCurrentColor()
        local r,g2,b2 = math.clamp(math.floor(color.R*255+0.5),0,255),math.clamp(math.floor(color.G*255+0.5),0,255),math.clamp(math.floor(color.B*255+0.5),0,255)
        previewColor.BackgroundColor3 = color svCursor.Position = UDim2.new(math.clamp(currentS,0,1),0,1-math.clamp(currentV,0,1),0)
        svCursorInner.BackgroundColor3 = color paletteFrame.BackgroundColor3 = Color3.fromHSV(math.clamp(currentH,0,0.999),1,1)
        hueCursor.Position = UDim2.new(0.5,0,math.clamp(currentH,0,0.999),0)
        rgbBoxes[1].Text = tostring(r) rgbBoxes[2].Text = tostring(g2) rgbBoxes[3].Text = tostring(b2) hexBox.Text = colorToHex(color)
    end
    updateAll()
    local draggingSV,draggingHue = false,false
    paletteHit.MouseButton1Down:Connect(function() draggingSV = true local mp=UIS:GetMouseLocation() currentS=math.clamp((mp.X-paletteFrame.AbsolutePosition.X)/paletteFrame.AbsoluteSize.X,0,1) currentV=1-math.clamp((mp.Y-paletteFrame.AbsolutePosition.Y)/paletteFrame.AbsoluteSize.Y,0,1) updateAll() end)
    hueHit.MouseButton1Down:Connect(function() draggingHue = true local mp=UIS:GetMouseLocation() currentH=math.clamp((mp.Y-hueBarFrame.AbsolutePosition.Y)/hueBarFrame.AbsoluteSize.Y,0,0.999) updateAll() end)
    local conn1 = UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingSV=false draggingHue=false end end)
    table.insert(pickerConnections, conn1)
    local conn2 = UIS.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement then
        if draggingSV then currentS=math.clamp((input.Position.X-paletteFrame.AbsolutePosition.X)/paletteFrame.AbsoluteSize.X,0,1) currentV=1-math.clamp((input.Position.Y-paletteFrame.AbsolutePosition.Y)/paletteFrame.AbsoluteSize.Y,0,1) updateAll() end
        if draggingHue then currentH=math.clamp((input.Position.Y-hueBarFrame.AbsolutePosition.Y)/hueBarFrame.AbsoluteSize.Y,0,0.999) updateAll() end
    end end)
    table.insert(pickerConnections, conn2)
    for i=1,3 do rgbBoxes[i].FocusLost:Connect(function() local num=tonumber(rgbBoxes[i].Text) if num then num=math.clamp(math.floor(num),0,255) local color=getCurrentColor() local r,g2,b2=math.floor(color.R*255+0.5),math.floor(color.G*255+0.5),math.floor(color.B*255+0.5) if i==1 then r=num end if i==2 then g2=num end if i==3 then b2=num end local nc=Color3.fromRGB(r,g2,b2) currentH,currentS,currentV=nc:ToHSV() if currentH~=currentH then currentH=0 end updateAll() else updateAll() end end) end
    hexBox.FocusLost:Connect(function() local parsed=hexToColor(hexBox.Text) if parsed then currentH,currentS,currentV=parsed:ToHSV() if currentH~=currentH then currentH=0 end updateAll() else updateAll() end end)
    local btnAreaY = paletteSize+18
    local btnOk = Instance.new("TextButton") btnOk.Parent = contentArea btnOk.BackgroundColor3 = C.Accent btnOk.BorderSizePixel = 0 btnOk.Position = UDim2.new(0,0,0,btnAreaY) btnOk.Size = UDim2.new(0.48,0,0,36) btnOk.Font = Enum.Font.GothamBold btnOk.Text = "Принять" btnOk.TextColor3 = Color3.fromRGB(10,10,10) btnOk.TextSize = 13 btnOk.AutoButtonColor = false btnOk.ZIndex = 103 Instance.new("UICorner", btnOk).CornerRadius = UDim.new(0,10)
    local btnCancel = Instance.new("TextButton") btnCancel.Parent = contentArea btnCancel.BackgroundColor3 = C.Toggle btnCancel.BorderSizePixel = 0 btnCancel.Position = UDim2.new(0.52,0,0,btnAreaY) btnCancel.Size = UDim2.new(0.48,0,0,36) btnCancel.Font = Enum.Font.GothamBold btnCancel.Text = "Отмена" btnCancel.TextColor3 = C.Text btnCancel.TextSize = 13 btnCancel.AutoButtonColor = false btnCancel.ZIndex = 103 Instance.new("UICorner", btnCancel).CornerRadius = UDim.new(0,10)
    local pickerClosed = false
    local function closePickerWithColor(resultColor) if pickerClosed then return end pickerClosed = true for _,conn in pairs(pickerConnections) do pcall(function() conn:Disconnect() end) end tw(mainFrame,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.In) tw(dimmer,{BackgroundTransparency=1},0.2) task.delay(0.25,function() mainFrame:Destroy() dimmer:Destroy() end) if resultColor then callback(resultColor) else callback(nil) end end
    btnOk.MouseButton1Click:Connect(function() closePickerWithColor(getCurrentColor()) end)
    btnCancel.MouseButton1Click:Connect(function() closePickerWithColor(nil) end)
    dimmer.MouseButton1Click:Connect(function() closePickerWithColor(nil) end)
    tw(dimmer,{BackgroundTransparency=0.55},0.25)
    tw(mainFrame,{Size=UDim2.new(0,pickerWidth,0,pickerHeight),BackgroundTransparency=0,Position=UDim2.new(0.5,0,0.5,0)},0.35,Enum.EasingStyle.Back)
end

function UI.addColorRow(parent, label, rKey, gKey, bKey, order, extraCallback)
    local row = Instance.new("Frame") row.Parent = parent row.BackgroundTransparency = 1 row.Size = UDim2.new(1,0,0,28) row.LayoutOrder = order row.BorderSizePixel = 0
    local lbl = Instance.new("TextLabel") lbl.Parent = row lbl.BackgroundTransparency = 1 lbl.Position = UDim2.new(0,0,0,0) lbl.Size = UDim2.new(1,-50,1,0) lbl.Font = Enum.Font.GothamMedium lbl.Text = label lbl.TextColor3 = C.Text lbl.TextSize = 11 lbl.TextXAlignment = Enum.TextXAlignment.Left reg(lbl,"TextColor3","Text")
    local preview = Instance.new("TextButton") preview.Parent = row preview.BorderSizePixel = 0 preview.Position = UDim2.new(1,-42,0,3) preview.Size = UDim2.new(0,36,0,22) preview.Text = "" preview.AutoButtonColor = false Instance.new("UICorner", preview).CornerRadius = UDim.new(0,8)
    local function updatePv() preview.BackgroundColor3 = Color3.fromRGB(math.clamp(S[rKey] or 255,0,255),math.clamp(S[gKey] or 255,0,255),math.clamp(S[bKey] or 255,0,255)) end
    updatePv()
    preview.MouseEnter:Connect(function() tw(preview,{Size=UDim2.new(0,40,0,24),Position=UDim2.new(1,-44,0,2)},0.15) end)
    preview.MouseLeave:Connect(function() tw(preview,{Size=UDim2.new(0,36,0,22),Position=UDim2.new(1,-42,0,3)},0.15) end)
    preview.MouseButton1Click:Connect(function()
        local currentColor = Color3.fromRGB(math.clamp(S[rKey] or 255,0,255),math.clamp(S[gKey] or 255,0,255),math.clamp(S[bKey] or 255,0,255))
        UI.openColorPicker(currentColor, function(newColor) if newColor then S[rKey]=math.floor(newColor.R*255+0.5) S[gKey]=math.floor(newColor.G*255+0.5) S[bKey]=math.floor(newColor.B*255+0.5) updatePv() saveSettings() if extraCallback then extraCallback() end end end)
    end)
    return updatePv
end

function UI.addThemeButton(parent, name, order)
    local btn=Instance.new("TextButton") btn.Parent=parent btn.BackgroundColor3=C.Toggle btn.Size=UDim2.new(1,0,0,44) btn.BorderSizePixel=0 btn.LayoutOrder=order btn.Text="" btn.AutoButtonColor=false
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10) reg(btn,"BackgroundColor3","Toggle")
    local st=Instance.new("UIStroke") st.Parent=btn st.Color=C.Border st.Transparency=0.5 st.Thickness=1 reg(st,"Color","Border")
    local colorDot=Instance.new("Frame") colorDot.Parent=btn colorDot.BackgroundColor3=Themes[name].Accent colorDot.Size=UDim2.new(0,22,0,22) colorDot.Position=UDim2.new(0,14,0.5,-11) colorDot.BorderSizePixel=0 Instance.new("UICorner",colorDot).CornerRadius=UDim.new(1,0)
    local nameLbl=Instance.new("TextLabel") nameLbl.Parent=btn nameLbl.BackgroundTransparency=1 nameLbl.Position=UDim2.new(0,46,0,0) nameLbl.Size=UDim2.new(1,-56,1,0) nameLbl.Font=Enum.Font.GothamBold nameLbl.Text=name nameLbl.TextColor3=C.Text nameLbl.TextSize=12 nameLbl.TextXAlignment=Enum.TextXAlignment.Left reg(nameLbl,"TextColor3","Text")
    btn.MouseButton1Click:Connect(function() S.Theme=name UI.applyTheme(name) saveSettings() end)
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.CardHover},0.2) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.Toggle},0.2) end)
end

function UI.applyTheme(name)
    local t = Themes[name] if not t then return end
    for k,v in pairs(t) do C[k]=v end
    for _,e in pairs(UI.themedElements) do
        pcall(function()
            if C[e.key] then
                if e.obj:IsA("UIStroke") then
                    e.obj.Color = C[e.key]
                else
                    e.obj[e.prop] = C[e.key]
                end
            end
        end)
    end
    if UI.fovCircle then pcall(function() UI.fovCircle.Color=C.Accent end) end
    for _,img in pairs(UI.arrowImages) do pcall(function() img.ImageColor3=C.Accent end) end
    if UI.targetESPImage then pcall(function() UI.targetESPImage.ImageColor3=C.Accent end) end
    pcall(function()
        for _,entries in pairs(UI.toggleButtons) do
            for _,data in pairs(entries) do
                if data.setBgColor then data.setBgColor() end
            end
        end
    end)
    pcall(function()
        for _,mb in pairs(UI.modeBtns) do
            local cm = BindModes[mb.bKey] or "Toggle"
            mb.btn.TextColor3 = cm == "Hold" and C.Accent or C.TextMuted
        end
    end)
    pcall(function()
        if UI.currentTab then
            UI.currentTab.btn.BackgroundColor3=C.Card
            UI.currentTab.ic.TextColor3=C.Accent
            UI.currentTab.indicator.BackgroundColor3=C.Accent
        end
    end)
end

UI.fovCircle = nil
pcall(function()
    UI.fovCircle = Drawing.new("Circle") UI.fovCircle.Thickness=1.5 UI.fovCircle.NumSides=60 UI.fovCircle.Radius=S.FOV
    UI.fovCircle.Filled=false UI.fovCircle.Transparency=0.6 UI.fovCircle.Visible=false UI.fovCircle.Color=C.Accent
end)

local N=Instance.new("Frame") N.Parent=G N.BackgroundColor3=C.Card
N.Position=UDim2.new(0.5,-140,0,-50) N.Size=UDim2.new(0,280,0,36) N.BorderSizePixel=0
Instance.new("UICorner",N).CornerRadius=UDim.new(0,10)
local nStroke=Instance.new("UIStroke") nStroke.Parent=N nStroke.Color=C.Border nStroke.Transparency=0.4
local nDot=Instance.new("Frame") nDot.Parent=N nDot.BackgroundColor3=C.Accent nDot.Size=UDim2.new(0,7,0,7) nDot.Position=UDim2.new(0,14,0.5,-3) nDot.BorderSizePixel=0 Instance.new("UICorner",nDot).CornerRadius=UDim.new(1,0)
local nt=Instance.new("TextLabel") nt.Parent=N nt.BackgroundTransparency=1 nt.Size=UDim2.new(1,-28,1,0) nt.Position=UDim2.new(0,28,0,0) nt.Font=Enum.Font.GothamBold nt.TextColor3=C.Text nt.TextSize=12 nt.TextXAlignment=Enum.TextXAlignment.Left
nt.Text="ДжонГарик.cc загружен  •  ["..(Binds.Menu and Binds.Menu.Name or "None").."]"
N:TweenPosition(UDim2.new(0.5,-140,0,50),"Out","Back",0.55,true)
task.delay(3.5,function() N:TweenPosition(UDim2.new(0.5,-140,0,-60),"In","Back",0.4,true,function() N:Destroy() end) end)

return UI

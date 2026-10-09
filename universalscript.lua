-- Ожидание полной загрузки игры и игрока
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

-- НАСТРОЙКИ (Изменяются через Меню)
local Config = {
	Aimbot = true,
	Aimbot_Smoothness = 0.15, 
	Aimbot_FOV = 150,        
	
	ESP_Highlight = true,
	ESP_Stats = true,
	ESP_Color = Color3.fromRGB(255, 0, 0),
	Hub_ThemeColor = Color3.fromRGB(0, 255, 150),
	CurrentLanguage = "EN", -- "EN", "RU", "ES", "FR"
	OpenKey = Enum.KeyCode.K,
	Discord_Link = "https://discord.gg/8Mw5SfETJ",
	
	Fly = false,
	Fly_Speed = 50,
	Noclip = false
}

local AIM_KEY = Enum.UserInputType.MouseButton2 

-- Хранилища для динамических элементов хаба
local ThemeElements = {}
local LocElements = {}
local Pages = {}

-- ОБЪЯВЛЕНИЕ ЦВЕТОВЫХ ПАЛИТР (Перенесено вверх во избежание ошибок)
local mainColors = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 150, 255), Color3.fromRGB(255, 235, 0), Color3.fromRGB(255, 0, 200)}
local themeColors = {Color3.fromRGB(0, 255, 150), Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 220, 0), Color3.fromRGB(255, 100, 200)}

-- Функция обновления темы хаба (Перенесена вверх)
local function updateHubTheme()
	for _, element in ipairs(ThemeElements) do
		if element.Property and element.Object then 
			element.Object[element.Property] = Config.Hub_ThemeColor
		elseif element.UpdateFunc then 
			element.UpdateFunc() 
		end
	end
end

-- ТАБЛИЦА ЛОКАЛИЗАЦИИ
local Localization = {
	EN = {
		MenuBtn = "MENU", Title = "SOFER INIVERSAL", Aimbot = "Aimbot (RMB)", ESP_Highlight = "ESP Highlight", 
		ESP_Stats = "Names & Distance", FOV_Radius = "FOV Radius", Aim_Speed = "Aim Speed",
		Color_ESP = "ESP PLAYER COLOR", Color_Hub = "HUB THEME COLOR", Lang_Btn = "LANGUAGE",
		Discord_Alert = "DISCORD LINK COPIED!", Close_Lang = "CLOSE", Keybind = "BIND: ",
		Fly = "Fly Mode", Fly_Speed = "Fly Speed", Noclip = "Noclip (Wallhack)"
	},
	RU = {
		MenuBtn = "МЕНЮ", Title = "SOFER INIVERSAL", Aimbot = "Аимбот (ПКМ)", ESP_Highlight = "ESP Силуэт", 
		ESP_Stats = "Ники и Дистанция", FOV_Radius = "Радиус FOV", Aim_Speed = "Скорость Аима",
		Color_ESP = "ЦВЕТ ESP ИГРОКОВ", Color_Hub = "ЦВЕТ ХАБА", Lang_Btn = "ЯЗЫК",
		Discord_Alert = "ССЫЛКА СКОПИРОВАНА!", Close_Lang = "ЗАКРЫТЬ", Keybind = "КЛАВИША: ",
		Fly = "Режим Полета", Fly_Speed = "Скорость Полета", Noclip = "Ноуклип (Сквозь стены)"
	},
	ES = {
		MenuBtn = "MENÚ", Title = "SOFER INIVERSAL", Aimbot = "Aimbot (Click D)", ESP_Highlight = "ESP Silueta", 
		ESP_Stats = "Nombres y Distancia", FOV_Radius = "Radio FOV", Aim_Speed = "Velocidad Aim",
		Color_ESP = "COLOR JUGADOR ESP", Color_Hub = "COLOR DEL MENÚ", Lang_Btn = "IDIOMA",
		Discord_Alert = "¡ENLACE COPIADO!", Close_Lang = "CERRAR", Keybind = "TECLA: ",
		Fly = "Modo Vuelo", Fly_Speed = "Velocidad Vuelo", Noclip = "Noclip (Paredes)"
	},
	FR = {
		MenuBtn = "MENU", Title = "SOFER INIVERSAL", Aimbot = "Aimbot (BDR)", ESP_Highlight = "ESP Silhouette", 
		ESP_Stats = "Noms & Distance", FOV_Radius = "Rayon FOV", Aim_Speed = "Vitesse Aim",
		Color_ESP = "COULEUR ESP JOUEUR", Color_Hub = "COULEUR DU MENU", Lang_Btn = "LANGUE",
		Discord_Alert = "LIEN COPIÉ!", Close_Lang = "FERMER", Keybind = "TOUCHE: ",
		Fly = "Mode Vol", Fly_Speed = "Vitesse Vol", Noclip = "Noclip (Murs)"
	}
}

local KeybindBtn = Instance.new("TextButton")

local function updateLocalization()
	local currentLang = Config.CurrentLanguage
	local texts = Localization[currentLang]
	
	if KeybindBtn and KeybindBtn.Parent then
		KeybindBtn.Text = texts["Keybind"] .. Config.OpenKey.Name
	end

	for _, element in ipairs(LocElements) do
		if element.Key and texts[element.Key] then
			if element.Type == "Toggle" then
				local state = Config[element.ConfigKey]
				local suffix = state and (currentLang == "RU" and ": ВКЛ" or currentLang == "FR" and ": ACTIF" or ": ON") or (currentLang == "RU" and ": ВЫКЛ" or currentLang == "FR" and ": INACTIF" or ": OFF")
				element.Object.Text = texts[element.Key] .. suffix
			elseif element.Type == "Slider" then
				local exactValue = Config[element.ConfigKey]
				if element.IsPercent then
					local ratio = (exactValue - element.Min) / (element.Max - element.Min)
					element.Object.Text = texts[element.Key] .. ": " .. math.round(ratio * 100) .. "%"
				else
					element.Object.Text = texts[element.Key] .. ": " .. math.round(exactValue) .. (element.Key == "Fly_Speed" and "" or " px")
				end
			else
				element.Object.Text = texts[element.Key]
			end
		end
	end
end

------------------------------------------------------------------------
-- КРУГ FOV
------------------------------------------------------------------------
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "AimbotFOVGui"
FOVGui.ResetOnSpawn = false
FOVGui.DisplayOrder = 999
FOVGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local FOVFrame = Instance.new("Frame")
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.BackgroundTransparency = 1 
FOVFrame.Visible = true
FOVFrame.Parent = FOVGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0) 
FOVCorner.Parent = FOVFrame

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = Config.Hub_ThemeColor 
FOVStroke.Transparency = 0.4
FOVStroke.Parent = FOVFrame
table.insert(ThemeElements, {Object = FOVStroke, Property = "Color"})

RunService.RenderStepped:Connect(function()
	if Config.Aimbot then
		FOVFrame.Visible = true
		FOVFrame.Size = UDim2.new(0, Config.Aimbot_FOV * 2, 0, Config.Aimbot_FOV * 2)
		local mousePos = UserInputService:GetMouseLocation()
		FOVFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	else
		FOVFrame.Visible = false
	end
end)

------------------------------------------------------------------------
-- ИНТЕРФЕЙС МЕНЮ С ТАБАМИ
------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CheatHubGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local ToggleMenuBtn = Instance.new("TextButton")
ToggleMenuBtn.Size = UDim2.new(0, 130, 0, 35)
ToggleMenuBtn.Position = UDim2.new(1, -145, 0, 15)
ToggleMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleMenuBtn.TextSize = 14
ToggleMenuBtn.Font = Enum.Font.SourceSansBold
ToggleMenuBtn.Parent = ScreenGui
table.insert(LocElements, {Object = ToggleMenuBtn, Key = "MenuBtn", Type = "Label"})

local UICornerBtn = Instance.new("UICorner")
UICornerBtn.CornerRadius = UDim.new(0, 6)
UICornerBtn.Parent = ToggleMenuBtn

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 400) 
MainFrame.Position = UDim2.new(1, -255, 0, 60)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Active = true 
MainFrame.Parent = ScreenGui

local UICornerMain = Instance.new("UICorner")
UICornerMain.CornerRadius = UDim.new(0, 8)
UICornerMain.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleLabel.TextColor3 = Config.Hub_ThemeColor
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Parent = MainFrame
table.insert(ThemeElements, {Object = TitleLabel, Property = "TextColor3"})
table.insert(LocElements, {Object = TitleLabel, Key = "Title", Type = "Label"})

local UICornerTitle = Instance.new("UICorner")
UICornerTitle.CornerRadius = UDim.new(0, 8)
UICornerTitle.Parent = TitleLabel

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -85)
ContentFrame.Position = UDim2.new(0, 0, 0, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 45)
TabBar.Position = UDim2.new(0, 0, 1, -45)
TabBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TabBar.BackgroundTransparency = 0.96
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 8)
TabBarCorner.Parent = TabBar

------------------------------------------------------------------------
-- ЛОГИКА ДРАГА ПАНЕЛИ
------------------------------------------------------------------------
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
	local delta = input.Position - dragStart
	MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true; dragStart = input.Position; startPos = MainFrame.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then updateDrag(input) end end)

------------------------------------------------------------------------
-- ФУНКЦИИ ГЕНЕРАЦИИ СТРАНИЦ И ЭЛЕМЕНТОВ
------------------------------------------------------------------------
local function createPage()
	local page = Instance.new("Frame")
	page.Size = UDim2.new(1, 0, 1, 0)
page.BackgroundTransparency = 1
page.Visible = false
page.Parent = ContentFrame
return page
end
local function showPage(targetPage, activeBtn)
for _, p in pairs(Pages) do p.Visible = false end
targetPage.Visible = true
for _, child in ipairs(TabBar:GetChildren()) do
if child:IsA("TextButton") then child.TextColor3 = Color3.fromRGB(150, 150, 150) end
end
activeBtn.TextColor3 = Config.Hub_ThemeColor
end
local function createTabButton(text, index, pageTarget)
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.25, 0, 1, 0)
btn.Position = UDim2.new((index - 1) * 0.25, 0, 0, 0)
btn.BackgroundTransparency = 1
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 12
btn.TextColor3 = Color3.fromRGB(150, 150, 150)
btn.Text = text
btn.Parent = TabBar
btn.MouseButton1Click:Connect(function() showPage(pageTarget, btn) end)
return btn
end
local function createPageToggle(page, locKey, positionY, defaultConfig, callback)
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 200, 0, 32)
btn.Position = UDim2.new(0.5, -100, 0, positionY)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 13
btn.Parent = page
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = btn
local function updateVisuals()
local state = Config[defaultConfig]
if state then
btn.BackgroundColor3 = Color3.fromRGB(35, 45, 40)
btn.TextColor3 = Config.Hub_ThemeColor
else
btn.BackgroundColor3 = Color3.fromRGB(35, 25, 25)
btn.TextColor3 = Color3.fromRGB(150, 100, 100)
end
local currentLang = Config.CurrentLanguage
local suffix = state and (currentLang == "RU" and ": ВКЛ" or currentLang == "FR" and ": ACTIF" or ": ON") or (currentLang == "RU" and ": ВЫКЛ" or currentLang == "FR" and ": INACTIF" or ": OFF")
btn.Text = Localization[currentLang][locKey] .. suffix
end
btn.MouseButton1Click:Connect(function()
Config[defaultConfig] = not Config[defaultConfig]
updateVisuals()
if callback then callback(Config[defaultConfig]) end
end)
table.insert(ThemeElements, {Object = btn, UpdateFunc = updateVisuals})
table.insert(LocElements, {Object = btn, Key = locKey, Type = "Toggle", ConfigKey = defaultConfig})
updateVisuals()
end
local function createPageSlider(page, locKey, positionY, min, max, defaultConfig, isPercent)
local sliderLabel = Instance.new("TextLabel")
sliderLabel.Size = UDim2.new(0, 200, 0, 18)
sliderLabel.Position = UDim2.new(0.5, -100, 0, positionY)
sliderLabel.BackgroundTransparency = 1
sliderLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
sliderLabel.TextSize = 11
sliderLabel.Font = Enum.Font.SourceSansBold
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Parent = page
table.insert(LocElements, {Object = sliderLabel, Key = locKey, Type = "Slider", ConfigKey = defaultConfig, IsPercent = isPercent, Min = min, Max = max})
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(0, 200, 0, 6)
sliderFrame.Position = UDim2.new(0.5, -100, 0, positionY + 20)
sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
sliderFrame.BorderSizePixel = 0
sliderFrame.Parent = page
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 3)
corner.Parent = sliderFrame
local fill = Instance.new("Frame")
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Config.Hub_ThemeColor
fill.BorderSizePixel = 0
fill.Parent = sliderFrame
table.insert(ThemeElements, {Object = fill, Property = "BackgroundColor3"})
local cornerF = Instance.new("UICorner")
cornerF.CornerRadius = UDim.new(0, 3)
cornerF.Parent = fill
local trigger = Instance.new("TextButton")
trigger.Size = UDim2.new(1, 0, 1, 0)
trigger.BackgroundTransparency = 1
trigger.Text = ""
trigger.Parent = sliderFrame
local function updateSlider(input)
local ratio = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
fill.Size = UDim2.new(ratio, 0, 1, 0)
local exactValue = min + (max - min) * ratio
Config[defaultConfig] = isPercent and exactValue or math.round(exactValue)
local currentLang = Config.CurrentLanguage
if isPercent then
sliderLabel.Text = Localization[currentLang][locKey] .. ": " .. math.round(ratio * 100) .. "%"
else
sliderLabel.Text = Localization[currentLang][locKey] .. ": " .. math.round(exactValue) .. (locKey == "Fly_Speed" and "" or " px")
end
end
local startRatio = (Config[defaultConfig] - min) / (max - min)
fill.Size = UDim2.new(startRatio, 0, 1, 0)
local holding = false
trigger.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then holding = true; updateSlider(input) end end)
UserInputService.InputChanged:Connect(function(input) if holding and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then holding = false end end)
end
local function createPageColorBlock(page, locKey, positionY, colorsList, updateCallback, strokeConfigKey)
local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 200, 0, 20)
label.Position = UDim2.new(0.5, -100, 0, positionY)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(150, 150, 150)
label.TextSize = 12
label.Font = Enum.Font.SourceSansBold
label.Parent = page
table.insert(LocElements, {Object = label, Key = locKey, Type = "Label"})
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 200, 0, 30)
container.Position = UDim2.new(0.5, -100, 0, positionY + 18)
container.BackgroundTransparency = 1
container.Parent = page
for index, colorValue in ipairs(colorsList) do
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 28, 0, 28)
btn.Position = UDim2.new(0, (index - 1) * 43, 0, 0)
btn.BackgroundColor3 = colorValue
btn.Text = ""
btn.Parent = container
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = btn
local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Enabled = (Config[strokeConfigKey] == colorValue)
stroke.Parent = btn
btn.MouseButton1Click:Connect(function()
Config[strokeConfigKey] = colorValue
for _, child in ipairs(container:GetChildren()) do
if child:IsA("TextButton") and child:FindFirstChild("UIStroke") then child.UIStroke.Enabled = (child.BackgroundColor3 == colorValue) end
end
updateCallback(colorValue)
end)
end
end

-- ИНИЦИАЛИЗАЦИЯ ВКЛАДОК (СТРАНИЦ)

local PlayerPage = createPage()
local CombatPage = createPage()
local VisualPage = createPage()
local SettingsPage = createPage()
Pages.Player = PlayerPage
Pages.Combat = CombatPage
Pages.Visual = VisualPage
Pages.Settings = SettingsPage
local tabBtn1 = createTabButton("PLAYER", 1, PlayerPage)
local tabBtn2 = createTabButton("COMBAT", 2, CombatPage)
local tabBtn3 = createTabButton("VISUAL", 3, VisualPage)
local tabBtn4 = createTabButton("SETTINGS", 4, SettingsPage)
table.insert(ThemeElements, {Object = tabBtn1, UpdateFunc = function() if PlayerPage.Visible then tabBtn1.TextColor3 = Config.Hub_ThemeColor end end})
table.insert(ThemeElements, {Object = tabBtn2, UpdateFunc = function() if CombatPage.Visible then tabBtn2.TextColor3 = Config.Hub_ThemeColor end end})
table.insert(ThemeElements, {Object = tabBtn3, UpdateFunc = function() if VisualPage.Visible then tabBtn3.TextColor3 = Config.Hub_ThemeColor end end})
table.insert(ThemeElements, {Object = tabBtn4, UpdateFunc = function() if SettingsPage.Visible then tabBtn4.TextColor3 = Config.Hub_ThemeColor end end})
-- По умолчанию открываем Combat
showPage(CombatPage, tabBtn2)

-- НАПОЛНЕНИЕ СТРАНИЦЫ: PLAYER

createPageToggle(PlayerPage, "Fly", 15, "Fly")
createPageSlider(PlayerPage, "Fly_Speed", 60, 10, 150, "Fly_Speed", false)
createPageToggle(PlayerPage, "Noclip", 110, "Noclip")

-- НАПОЛНЕНИЕ СТРАНИЦЫ: COMBAT

createPageToggle(CombatPage, "Aimbot", 15, "Aimbot")
createPageSlider(CombatPage, "FOV_Radius", 60, 50, 400, "Aimbot_FOV", false)
createPageSlider(CombatPage, "Aim_Speed", 110, 0.02, 1.0, "Aimbot_Smoothness", true)

-- НАПОЛНЕНИЕ СТРАНИЦЫ: VISUAL

createPageToggle(VisualPage, "ESP_Highlight", 15, "ESP_Highlight", function(state)
for _, p in ipairs(Players:GetPlayers()) do
if p.Character and p.Character:FindFirstChild("ESP_Highlight") then p.Character.ESP_Highlight.Enabled = state end
end
end)
createPageToggle(VisualPage, "ESP_Stats", 60, "ESP_Stats", function(state)
for _, p in ipairs(Players:GetPlayers()) do
if p.Character then
local root = p.Character:FindFirstChild("HumanoidRootPart")
if root and root:FindFirstChild("ESP_Billboard") then root.ESP_Billboard.Enabled = state end
end
end
end)
createPageColorBlock(VisualPage, "Color_ESP", 110, mainColors, function()
for _, p in ipairs(Players:GetPlayers()) do
if p.Character and p.Character:FindFirstChild("ESP_Highlight") then p.Character.ESP_Highlight.FillColor = Config.ESP_Color end
end
end, "ESP_Color")

-- НАПОЛНЕНИЕ СТРАНИЦЫ: SETTINGS

createPageColorBlock(SettingsPage, "Color_Hub", 10, themeColors, updateHubTheme, "Hub_ThemeColor")
local LangBtn = Instance.new("TextButton")
LangBtn.Size = UDim2.new(0, 95, 0, 30)
LangBtn.Position = UDim2.new(0, 20, 0, 70)
LangBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LangBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
LangBtn.Font = Enum.Font.SourceSansBold
LangBtn.TextSize = 13
LangBtn.Parent = SettingsPage
table.insert(LocElements, {Object = LangBtn, Key = "Lang_Btn", Type = "Label"})
local LangBtnCorner = Instance.new("UICorner")
LangBtnCorner.CornerRadius = UDim.new(0, 6)
LangBtnCorner.Parent = LangBtn
KeybindBtn.Size = UDim2.new(0, 95, 0, 30)
KeybindBtn.Position = UDim2.new(1, -115, 0, 70)
KeybindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
KeybindBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
KeybindBtn.Font = Enum.Font.SourceSansBold
KeybindBtn.TextSize = 13
KeybindBtn.Parent = SettingsPage
local KeybindCorner = Instance.new("UICorner")
KeybindCorner.CornerRadius = UDim.new(0, 6)
KeybindCorner.Parent = KeybindBtn
local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(0, 200, 0, 35)
DiscordBtn.Position = UDim2.new(0.5, -100, 0, 115)
DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DiscordBtn.Font = Enum.Font.SourceSansBold
DiscordBtn.TextSize = 14
DiscordBtn.Text = "DISCORD SERVER"
DiscordBtn.Parent = SettingsPage
local DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 6)
DiscordCorner.Parent = DiscordBtn

-- ЛОГИКА КАСТОМНОГО БИНДА И ОКНА ЯЗЫКОВ

local isBinding = false
KeybindBtn.MouseButton1Click:Connect(function() isBinding = true; KeybindBtn.Text = "[...]" end)
UserInputService.InputBegan:Connect(function(input, processed)
if isBinding and input.KeyCode ~= Enum.KeyCode.Unknown then Config.OpenKey = input.KeyCode; isBinding = false; updateLocalization() end
end)
local LangModalFrame = Instance.new("Frame")
LangModalFrame.Size = UDim2.new(0, 200, 0, 220)
LangModalFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
LangModalFrame.BorderSizePixel = 0
LangModalFrame.Visible = false
LangModalFrame.ZIndex = 10
LangModalFrame.Parent = ScreenGui
RunService.RenderStepped:Connect(function()
if LangModalFrame.Visible then
LangModalFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset - 210, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
end
end)
local ModalCorner = Instance.new("UICorner")
ModalCorner.CornerRadius = UDim.new(0, 8)
ModalCorner.Parent = LangModalFrame
local ModalStroke = Instance.new("UIStroke")
ModalStroke.Thickness = 1.5
ModalStroke.Color = Config.Hub_ThemeColor
ModalStroke.Parent = LangModalFrame
table.insert(ThemeElements, {Object = ModalStroke, Property = "Color"})
local function createLangSelectBtn(text, langCode, positionY)
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 170, 0, 30)
btn.Position = UDim2.new(0.5, -85, 0, positionY)
btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
btn.BackgroundTransparency = 0.95
btn.TextColor3 = (Config.CurrentLanguage == langCode) and Config.Hub_ThemeColor or Color3.fromRGB(200, 200, 200)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 13
btn.Text = text
btn.ZIndex = 11
btn.Parent = LangModalFrame
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = btn
if Config.CurrentLanguage == langCode then table.insert(ThemeElements, {Object = btn, Property = "TextColor3"}) end
btn.MouseButton1Click:Connect(function()
Config.CurrentLanguage = langCode
for i, child in ipairs(ThemeElements) do
if child.Object and child.Object.ClassName == "TextButton" and child.Object.Parent == LangModalFrame then table.remove(ThemeElements, i) end
end
for _, child in ipairs(LangModalFrame:GetChildren()) do if child:IsA("TextButton") then child.TextColor3 = Color3.fromRGB(200, 200, 200) end end
btn.TextColor3 = Config.Hub_ThemeColor
table.insert(ThemeElements, {Object = btn, Property = "TextColor3"})
updateLocalization()
LangModalFrame.Visible = false
end)
end
createLangSelectBtn("English", "EN", 20)
createLangSelectBtn("Русский", "RU", 60)
createLangSelectBtn("Español", "ES", 100)
createLangSelectBtn("Français", "FR", 140)
local CloseLangBtn = Instance.new("TextButton")
CloseLangBtn.Size = UDim2.new(0, 170, 0, 25)
CloseLangBtn.Position = UDim2.new(0.5, -85, 0, 180)
CloseLangBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
CloseLangBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseLangBtn.Font = Enum.Font.SourceSansBold
CloseLangBtn.TextSize = 12
CloseLangBtn.ZIndex = 11
CloseLangBtn.Parent = LangModalFrame
table.insert(LocElements, {Object = CloseLangBtn, Key = "Close_Lang", Type = "Label"})
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseLangBtn
CloseLangBtn.MouseButton1Click:Connect(function() LangModalFrame.Visible = false end)
LangBtn.MouseButton1Click:Connect(function() LangModalFrame.Visible = not LangModalFrame.Visible end)

-- УВЕДОМЛЕНИЯ DISCORD

local AlertLabel = Instance.new("TextLabel")
AlertLabel.Size = UDim2.new(0, 280, 0, 40)
AlertLabel.Position = UDim2.new(0.5, -140, 0, -60)
AlertLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AlertLabel.TextColor3 = Config.Hub_ThemeColor
AlertLabel.Font = Enum.Font.SourceSansBold
AlertLabel.TextSize = 13
AlertLabel.Visible = false
AlertLabel.Parent = ScreenGui
table.insert(ThemeElements, {Object = AlertLabel, Property = "TextColor3"})
table.insert(LocElements, {Object = AlertLabel, Key = "Discord_Alert", Type = "Label"})
local AlertCorner = Instance.new("UICorner")
AlertCorner.CornerRadius = UDim.new(0, 6)
AlertCorner.Parent = AlertLabel
local AlertStroke = Instance.new("UIStroke")
AlertStroke.Thickness = 1
AlertStroke.Color = Config.Hub_ThemeColor
AlertStroke.Parent = AlertLabel
table.insert(ThemeElements, {Object = AlertStroke, Property = "Color"})
local alertActive = false
DiscordBtn.MouseButton1Click:Connect(function()
if setclipboard then setclipboard(Config.Discord_Link) else print("https://discord.gg/8Mw5SfETJ " .. Config.Discord_Link) end
if not alertActive then
alertActive = true; AlertLabel.Visible = true
local tweenIn = TweenService:Create(AlertLabel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -140, 0, 20)}):Play()
task.wait(2.5)
local tweenOut = TweenService:Create(AlertLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -140, 0, -60)})
tweenOut:Play()
tweenOut.Completed:Connect(function() AlertLabel.Visible = false; alertActive = false end)
end
end)
updateLocalization()
local function toggleGuiVisibility()
MainFrame.Visible = not MainFrame.Visible
if not MainFrame.Visible then LangModalFrame.Visible = false end
end
ToggleMenuBtn.MouseButton1Click:Connect(toggleGuiVisibility)
UserInputService.InputBegan:Connect(function(input, processed)
if not processed and input.KeyCode == Config.OpenKey then toggleGuiVisibility() end
end)

-- ЛОГИКА ФУНКЦИЙ СЕРВЕРА (FLY, NOCLIP, AIMBOT, ESP)

local keysPressed = {}
UserInputService.InputBegan:Connect(function(i, p) if not p then keysPressed[i.KeyCode] = true end end)
UserInputService.InputEnded:Connect(function(i) keysPressed[i.KeyCode] = nil end)
RunService.Heartbeat:Connect(function()
local char = LocalPlayer.Character
if not char then return end
local root = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChild("Humanoid")
if not root or not hum then return end
if Config.Noclip or Config.Fly then
for _, child in ipairs(char:GetChildren()) do
if child:IsA("BasePart") then child.CanCollide = false end
end
end
if Config.Fly then
hum.PlatformStand = true
local moveDir = Vector3.new()
if keysPressed[Enum.KeyCode.W] then moveDir = moveDir + Camera.CFrame.LookVector end
if keysPressed[Enum.KeyCode.S] then moveDir = moveDir - Camera.CFrame.LookVector end
if keysPressed[Enum.KeyCode.A] then moveDir = moveDir - Camera.CFrame.RightVector end
if keysPressed[Enum.KeyCode.D] then moveDir = moveDir + Camera.CFrame.RightVector end
root.Velocity = moveDir.Unit * Config.Fly_Speed
if moveDir.Magnitude == 0 then root.Velocity = Vector3.new(0, 0, 0) end
else
if hum.PlatformStand then hum.PlatformStand = false end
end
end)
local isAiming = false
local function isValidTarget(targetPlayer)
return targetPlayer ~= LocalPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChild("Humanoid") and targetPlayer.Character.Humanoid.Health > 0
end
local function getClosestPlayerToCursor()
local closestPlayer, shortestDistance = nil, Config.Aimbot_FOV
for _, playerItem in ipairs(Players:GetPlayers()) do
if isValidTarget(playerItem) then
local rootPart = playerItem.Character.HumanoidRootPart
local screenPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
if onScreen then
local mousePosition = UserInputService:GetMouseLocation()
local distanceToCursor = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
if distanceToCursor < shortestDistance then closestPlayer = playerItem; shortestDistance = distanceToCursor end
end
end
end
return closestPlayer
end
local function applyESPToCharacter(character, targetPlayer)
local rootPart = character:WaitForChild("HumanoidRootPart", 5)
if not rootPart then return end
if rootPart:FindFirstChild("ESP_Billboard") then rootPart.ESP_Billboard:Destroy() end
if character:FindFirstChild("ESP_Highlight") then character.ESP_Highlight:Destroy() end
local highlight = Instance.new("Highlight")
highlight.Name = "ESP_Highlight"
highlight.Adornee = character
highlight.FillColor = Config.ESP_Color
highlight.FillTransparency = 0.5
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.Enabled = Config.ESP_Highlight
highlight.Parent = character
local billboard = Instance.new("BillboardGui")
billboard.Name = "ESP_Billboard"
billboard.AlwaysOnTop = true
billboard.Size = UDim2.new(0, 200, 0, 50)
billboard.StudsOffset = Vector3.new(0, 3.5, 0)
billboard.Adornee = rootPart
billboard.Enabled = Config.ESP_Stats
billboard.Parent = rootPart
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextSize = 14
label.Font = Enum.Font.SourceSansBold
label.TextStrokeTransparency = 0
label.Parent = billboard
label.Name = "PlayerLabel"
end
local function onPlayerAdded(targetPlayer)
if targetPlayer == LocalPlayer then return end
if targetPlayer.Character then applyESPToCharacter(targetPlayer.Character, targetPlayer) end
targetPlayer.CharacterAdded:Connect(function(char) applyESPToCharacter(char, targetPlayer) end)
end
for _, initialPlayer in ipairs(Players:GetPlayers()) do onPlayerAdded(initialPlayer) end
Players.PlayerAdded:Connect(onPlayerAdded)
RunService.Heartbeat:Connect(function()
local myChar = LocalPlayer.Character
if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
local myRoot = myChar.HumanoidRootPart
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
local enemyRoot = p.Character.HumanoidRootPart
local billboard = enemyRoot:FindFirstChild("ESP_Billboard")
if billboard and billboard.Enabled then
local label = billboard:FindFirstChild("PlayerLabel")
if label then
local distance = math.round((enemyRoot.Position - myRoot.Position).Magnitude)
label.Text = string.format("%s\n[%d studs]", p.Name, distance)
end
end
end
end
end)
UserInputService.InputBegan:Connect(function(input, processed)
if not processed and input.UserInputType == AIM_KEY then isAiming = true end
end)
UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == AIM_KEY then isAiming = false end
end)
RunService.RenderStepped:Connect(function()
if isAiming and Config.Aimbot then
local targetPlayer = getClosestPlayerToCursor()
if targetPlayer and targetPlayer.Character then
local targetPart = targetPlayer.Character:FindFirstChild("Head") or targetPlayer.Character:FindFirstChild("HumanoidRootPart")
if targetPart then
local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Config.Aimbot_Smoothness)
end
end
end
end)

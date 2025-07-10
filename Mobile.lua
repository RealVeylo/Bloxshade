if getgenv().BloxShade_Loaded then
    warn("BloxShade is already loaded!")
    return
end
getgenv().BloxShade_Loaded = true

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Create folder for saves
if not isfolder("BloxShade") then
    makefolder("BloxShade")
end
if not isfolder("BloxShade/Presets") then
    makefolder("BloxShade/Presets")
end

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Store original values for reset functionality
local OriginalValues = {
    Lighting = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ShadowSoftness = Lighting.ShadowSoftness,
        ExposureCompensation = Lighting.ExposureCompensation,
        Technology = Lighting.Technology
    },
    Atmosphere = nil -- Will be set if atmosphere exists
}

-- Get or create atmosphere
local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if Atmosphere then
    OriginalValues.Atmosphere = {
        Density = Atmosphere.Density,
        Offset = Atmosphere.Offset,
        Color = Atmosphere.Color,
        Decay = Atmosphere.Decay,
        Glare = Atmosphere.Glare,
        Haze = Atmosphere.Haze
    }
else
    Atmosphere = Instance.new("Atmosphere")
    Atmosphere.Parent = Lighting
    OriginalValues.Atmosphere = {
        Density = 0.3,
        Offset = 0.25,
        Color = Color3.fromRGB(199, 199, 199),
        Decay = Color3.fromRGB(92, 60, 13),
        Glare = 0,
        Haze = 0
    }
end

-- Shader Effect Instances
local Effects = {
    Blur = nil,
    Bloom = nil,
    ColorCorrection = nil,
    SunRays = nil,
    DepthOfField = nil,
    Vignette = nil,
    FilmGrain = nil,
    LensDistortion = nil,
    ChromaticAberration = nil
}

-- Function to get or create effect
local function getOrCreateEffect(effectType, effectName)
    local effect = Camera:FindFirstChild(effectName)
    if not effect then
        effect = Instance.new(effectType)
        effect.Name = effectName
        effect.Parent = Camera
    end
    return effect
end

-- Initialize effects
Effects.Blur = getOrCreateEffect("BlurEffect", "BloxShade_Blur")
Effects.Bloom = getOrCreateEffect("BloomEffect", "BloxShade_Bloom")
Effects.ColorCorrection = getOrCreateEffect("ColorCorrectionEffect", "BloxShade_ColorCorrection")
Effects.SunRays = getOrCreateEffect("SunRaysEffect", "BloxShade_SunRays")
Effects.DepthOfField = getOrCreateEffect("DepthOfFieldEffect", "BloxShade_DOF")

-- Create custom effects using GUI elements for effects not available as PostProcessingEffects
local function createCustomEffect(effectName)
    local effect = Camera:FindFirstChild(effectName)
    if not effect then
        effect = Instance.new("ScreenGui")
        effect.Name = effectName
        effect.Parent = Camera
    end
    return effect
end

Effects.Vignette = createCustomEffect("BloxShade_Vignette")
Effects.FilmGrain = createCustomEffect("BloxShade_FilmGrain")
Effects.LensDistortion = createCustomEffect("BloxShade_LensDistortion")
Effects.ChromaticAberration = createCustomEffect("BloxShade_ChromaticAberration")

-- Store original effect values
local OriginalEffects = {
    Blur = { Size = Effects.Blur.Size },
    Bloom = {
        Intensity = Effects.Bloom.Intensity,
        Size = Effects.Bloom.Size,
        Threshold = Effects.Bloom.Threshold
    },
    ColorCorrection = {
        Brightness = Effects.ColorCorrection.Brightness,
        Contrast = Effects.ColorCorrection.Contrast,
        Saturation = Effects.ColorCorrection.Saturation,
        TintColor = Effects.ColorCorrection.TintColor
    },
    SunRays = {
        Intensity = Effects.SunRays.Intensity,
        Spread = Effects.SunRays.Spread
    },
    DepthOfField = {
        FarIntensity = Effects.DepthOfField.FarIntensity,
        FocusDistance = Effects.DepthOfField.FocusDistance,
        InFocusRadius = Effects.DepthOfField.InFocusRadius,
        NearIntensity = Effects.DepthOfField.NearIntensity
    }
}

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "BloxShade Mobile",
    SubTitle = "by Veylo",
    TabWidth = 160,
    Size = UDim2.fromOffset(680, 360),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
    CanResize = true,
    ScrollSpeed = 30,
    ScrollingEnabled = true
})

-- Create Tabs
local Tabs = {
    Post = Window:AddTab({ Title = "Post Effects", Icon = "image", ScrollingEnabled = true }),
    Advanced = Window:AddTab({ Title = "Advanced", Icon = "zap", ScrollingEnabled = true }),
    Environment = Window:AddTab({ Title = "Environment", Icon = "globe", ScrollingEnabled = true }),
    Lighting = Window:AddTab({ Title = "Lighting", Icon = "sun", ScrollingEnabled = true }),
    Time = Window:AddTab({ Title = "Time & Weather", Icon = "cloud", ScrollingEnabled = true }),
    Performance = Window:AddTab({ Title = "Performance", Icon = "activity", ScrollingEnabled = true }),
    Presets = Window:AddTab({ Title = "Presets", Icon = "bookmark", ScrollingEnabled = true }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings", ScrollingEnabled = true })
}

local Options = Fluent.Options

-- Mobile Toggle Button
task.spawn(function()
    if not getgenv().BloxShade_MobileUI then
        getgenv().BloxShade_MobileUI = true

        local ScreenGui = Instance.new("ScreenGui")
        local ToggleButton = Instance.new("ImageButton")
        local UICorner = Instance.new("UICorner")
        local UIStroke = Instance.new("UIStroke")

        ScreenGui.Name = "BloxShade_Mobile"
        ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        ToggleButton.Parent = ScreenGui
        ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        ToggleButton.BackgroundTransparency = 0.1
        ToggleButton.Position = UDim2.new(0, 20, 0, 20)
        ToggleButton.Size = UDim2.new(0, 60, 0, 60)
        ToggleButton.Image = "rbxassetid://84010767307588"
        ToggleButton.ImageTransparency = 0
        ToggleButton.Draggable = true
        ToggleButton.BorderSizePixel = 0

        UICorner.CornerRadius = UDim.new(0, 12)
        UICorner.Parent = ToggleButton

        UIStroke.Color = Color3.fromRGB(0, 150, 255)
        UIStroke.Thickness = 2
        UIStroke.Transparency = 0.3
        UIStroke.Parent = ToggleButton

        -- Glow effect
        local shadow = ToggleButton:Clone()
        shadow.Name = "Shadow"
        shadow.Parent = ToggleButton
        shadow.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        shadow.BackgroundTransparency = 0.8
        shadow.Size = UDim2.new(1, 4, 1, 4)
        shadow.Position = UDim2.new(0, -2, 0, -2)
        shadow.ZIndex = ToggleButton.ZIndex - 1
        shadow.Image = ""
        shadow.Draggable = false

        ToggleButton.MouseButton1Click:Connect(function()
            game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        end)

        -- Hover effects
        ToggleButton.MouseEnter:Connect(function()
            TweenService:Create(ToggleButton, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
            TweenService:Create(UIStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
        end)

        ToggleButton.MouseLeave:Connect(function()
            TweenService:Create(ToggleButton, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
            TweenService:Create(UIStroke, TweenInfo.new(0.3), {Transparency = 0.3}):Play()
        end)
    end
end)

-- POST EFFECTS TAB

-- Blur Section
local BlurSection = Tabs.Post:AddSection("Blur")

local BlurToggle = Tabs.Post:AddToggle("BlurEnabled", {
    Title = "Enable Blur",
    Default = false,
    Description = "Apply screen blur effect"
})

local BlurSize = Tabs.Post:AddSlider("BlurSize", {
    Title = "Blur Size",
    Description = "Intensity of the blur effect",
    Default = 24,
    Min = 0,
    Max = 56,
    Rounding = 1
})

-- Bloom Section
local BloomSection = Tabs.Post:AddSection("Bloom")

local BloomToggle = Tabs.Post:AddToggle("BloomEnabled", {
    Title = "Enable Bloom",
    Default = false,
    Description = "Apply bloom glow effect"
})

local BloomIntensity = Tabs.Post:AddSlider("BloomIntensity", {
    Title = "Bloom Intensity",
    Description = "Brightness of the bloom effect",
    Default = 0.4,
    Min = 0,
    Max = 2,
    Rounding = 2
})

local BloomSize = Tabs.Post:AddSlider("BloomSize", {
    Title = "Bloom Size",
    Description = "Size of the bloom effect",
    Default = 24,
    Min = 0,
    Max = 56,
    Rounding = 1
})

local BloomThreshold = Tabs.Post:AddSlider("BloomThreshold", {
    Title = "Bloom Threshold",
    Description = "Brightness threshold for bloom",
    Default = 0.95,
    Min = 0,
    Max = 2,
    Rounding = 2
})

-- Color Correction Section
local ColorSection = Tabs.Post:AddSection("Color Correction")

local ColorToggle = Tabs.Post:AddToggle("ColorEnabled", {
    Title = "Enable Color Correction",
    Default = false,
    Description = "Apply color correction effects"
})

local Brightness = Tabs.Post:AddSlider("Brightness", {
    Title = "Brightness",
    Description = "Screen brightness adjustment",
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2
})

local Contrast = Tabs.Post:AddSlider("Contrast", {
    Title = "Contrast",
    Description = "Screen contrast adjustment",
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2
})

local Saturation = Tabs.Post:AddSlider("Saturation", {
    Title = "Saturation",
    Description = "Color saturation adjustment",
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2
})

local TintColor = Tabs.Post:AddColorpicker("TintColor", {
    Title = "Tint Color",
    Description = "Color tint overlay",
    Default = Color3.fromRGB(255, 255, 255)
})

-- Sun Rays Section
local SunRaysSection = Tabs.Post:AddSection("Sun Rays")

local SunRaysToggle = Tabs.Post:AddToggle("SunRaysEnabled", {
    Title = "Enable Sun Rays",
    Default = false,
    Description = "Apply sun rays effect"
})

local SunRaysIntensity = Tabs.Post:AddSlider("SunRaysIntensity", {
    Title = "Intensity",
    Description = "Sun rays intensity",
    Default = 0.25,
    Min = 0,
    Max = 1,
    Rounding = 2
})

local SunRaysSpread = Tabs.Post:AddSlider("SunRaysSpread", {
    Title = "Spread",
    Description = "Sun rays spread angle",
    Default = 1,
    Min = 0.1,
    Max = 3,
    Rounding = 2
})

-- Depth of Field Section
local DOFSection = Tabs.Post:AddSection("Depth of Field")

local DOFToggle = Tabs.Post:AddToggle("DOFEnabled", {
    Title = "Enable Depth of Field",
    Default = false,
    Description = "Apply depth of field blur"
})

local DOFFocusDistance = Tabs.Post:AddSlider("DOFFocusDistance", {
    Title = "Focus Distance",
    Description = "Distance to focus point",
    Default = 0.05,
    Min = 0,
    Max = 1,
    Rounding = 3
})

local DOFInFocusRadius = Tabs.Post:AddSlider("DOFInFocusRadius", {
    Title = "In Focus Radius",
    Description = "Radius of focused area",
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 3
})

local DOFNearIntensity = Tabs.Post:AddSlider("DOFNearIntensity", {
    Title = "Near Intensity",
    Description = "Near field blur intensity",
    Default = 0.25,
    Min = 0,
    Max = 1,
    Rounding = 2
})

local DOFFarIntensity = Tabs.Post:AddSlider("DOFFarIntensity", {
    Title = "Far Intensity",
    Description = "Far field blur intensity",
    Default = 0.25,
    Min = 0,
    Max = 1,
    Rounding = 2
})

-- Vignette Section
local VignetteSection = Tabs.Post:AddSection("Vignette")

local VignetteToggle = Tabs.Post:AddToggle("VignetteEnabled", {
    Title = "Enable Vignette",
    Default = false,
    Description = "Apply dark edges around screen"
})

local VignetteIntensity = Tabs.Post:AddSlider("VignetteIntensity", {
    Title = "Intensity",
    Description = "Darkness of vignette effect",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2
})

local VignetteSize = Tabs.Post:AddSlider("VignetteSize", {
    Title = "Size",
    Description = "Size of vignette area",
    Default = 0.3,
    Min = 0.1,
    Max = 1,
    Rounding = 2
})

local VignetteSmoothness = Tabs.Post:AddSlider("VignetteSmoothness", {
    Title = "Smoothness",
    Description = "Edge smoothness of vignette",
    Default = 0.5,
    Min = 0.1,
    Max = 1,
    Rounding = 2
})

-- ADVANCED TAB

-- Chromatic Aberration Section
local ChromaticSection = Tabs.Advanced:AddSection("Chromatic Aberration")

local ChromaticToggle = Tabs.Advanced:AddToggle("ChromaticEnabled", {
    Title = "Enable Chromatic Aberration",
    Default = false,
    Description = "Color fringing effect on edges"
})

local ChromaticIntensity = Tabs.Advanced:AddSlider("ChromaticIntensity", {
    Title = "Intensity",
    Description = "Strength of color separation",
    Default = 0.5,
    Min = 0,
    Max = 2,
    Rounding = 2
})

-- Film Grain Section
local FilmGrainSection = Tabs.Advanced:AddSection("Film Grain")

local FilmGrainToggle = Tabs.Advanced:AddToggle("FilmGrainEnabled", {
    Title = "Enable Film Grain",
    Default = false,
    Description = "Add texture noise to image"
})

local FilmGrainAmount = Tabs.Advanced:AddSlider("FilmGrainAmount", {
    Title = "Amount",
    Description = "Intensity of film grain",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2
})

local FilmGrainSize = Tabs.Advanced:AddSlider("FilmGrainSize", {
    Title = "Grain Size",
    Description = "Size of grain particles",
    Default = 1,
    Min = 0.5,
    Max = 3,
    Rounding = 1
})

-- Tone Mapping Section
local ToneMappingSection = Tabs.Advanced:AddSection("Tone Mapping")

local ToneMappingToggle = Tabs.Advanced:AddToggle("ToneMappingEnabled", {
    Title = "Enable ACES Tone Mapping",
    Default = false,
    Description = "Professional tone mapping"
})

local ToneMappingExposure = Tabs.Advanced:AddSlider("ToneMappingExposure", {
    Title = "Exposure",
    Description = "Overall exposure adjustment",
    Default = 1,
    Min = 0.1,
    Max = 4,
    Rounding = 2
})

-- Color Grading Section
local ColorGradingSection = Tabs.Advanced:AddSection("Color Grading")

local ColorGradingToggle = Tabs.Advanced:AddToggle("ColorGradingEnabled", {
    Title = "Enable Color Grading",
    Default = false,
    Description = "Advanced color adjustments"
})

local Temperature = Tabs.Advanced:AddSlider("Temperature", {
    Title = "Temperature",
    Description = "Color temperature (warm/cool)",
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2
})

local Tint = Tabs.Advanced:AddSlider("Tint", {
    Title = "Tint",
    Description = "Green/Magenta color balance",
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2
})

local Highlights = Tabs.Advanced:AddSlider("Highlights", {
    Title = "Highlights",
    Description = "Adjust bright areas",
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2
})

local Shadows = Tabs.Advanced:AddSlider("Shadows", {
    Title = "Shadows",
    Description = "Adjust dark areas",
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2
})

local Whites = Tabs.Advanced:AddSlider("Whites", {
    Title = "Whites",
    Description = "Adjust white point",
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2
})

local Blacks = Tabs.Advanced:AddSlider("Blacks", {
    Title = "Blacks",
    Description = "Adjust black point",
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2
})

-- Sharpening Section
local SharpeningSection = Tabs.Advanced:AddSection("Sharpening")

local SharpeningToggle = Tabs.Advanced:AddToggle("SharpeningEnabled", {
    Title = "Enable Sharpening",
    Default = false,
    Description = "Enhance image detail"
})

local SharpeningAmount = Tabs.Advanced:AddSlider("SharpeningAmount", {
    Title = "Amount",
    Description = "Sharpening intensity",
    Default = 0.5,
    Min = 0,
    Max = 2,
    Rounding = 2
})

-- ENVIRONMENT TAB

-- Atmosphere Section
local AtmosphereSection = Tabs.Environment:AddSection("Atmosphere")

local AtmosphereToggle = Tabs.Environment:AddToggle("AtmosphereEnabled", {
    Title = "Enable Atmosphere",
    Default = false,
    Description = "Apply atmospheric effects"
})

local AtmosphereDensity = Tabs.Environment:AddSlider("AtmosphereDensity", {
    Title = "Density",
    Description = "Atmospheric particle density",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2
})

local AtmosphereOffset = Tabs.Environment:AddSlider("AtmosphereOffset", {
    Title = "Offset",
    Description = "Atmospheric offset",
    Default = 0.25,
    Min = 0,
    Max = 1,
    Rounding = 2
})

local AtmosphereHaze = Tabs.Environment:AddSlider("AtmosphereHaze", {
    Title = "Haze",
    Description = "Atmospheric haze amount",
    Default = 0,
    Min = 0,
    Max = 3,
    Rounding = 2
})

local AtmosphereGlare = Tabs.Environment:AddSlider("AtmosphereGlare", {
    Title = "Glare",
    Description = "Sun glare intensity",
    Default = 0,
    Min = 0,
    Max = 2,
    Rounding = 2
})

local AtmosphereColor = Tabs.Environment:AddColorpicker("AtmosphereColor", {
    Title = "Atmosphere Color",
    Description = "Color of atmospheric particles",
    Default = Color3.fromRGB(199, 199, 199)
})

local AtmosphereDecay = Tabs.Environment:AddColorpicker("AtmosphereDecay", {
    Title = "Decay Color",
    Description = "Atmospheric decay color",
    Default = Color3.fromRGB(92, 60, 13)
})

-- Fog Section
local FogSection = Tabs.Environment:AddSection("Fog")

local FogToggle = Tabs.Environment:AddToggle("FogEnabled", {
    Title = "Enable Fog",
    Default = false,
    Description = "Apply distance fog effect"
})

local FogStart = Tabs.Environment:AddSlider("FogStart", {
    Title = "Fog Start",
    Description = "Distance where fog begins",
    Default = 15,
    Min = 0,
    Max = 1000,
    Rounding = 1
})

local FogEnd = Tabs.Environment:AddSlider("FogEnd", {
    Title = "Fog End",
    Description = "Distance where fog is fully opaque",
    Default = 100,
    Min = 50,
    Max = 2000,
    Rounding = 1
})

local FogColor = Tabs.Environment:AddColorpicker("FogColor", {
    Title = "Fog Color",
    Description = "Color of the fog",
    Default = Color3.fromRGB(192, 192, 192)
})

-- Skybox Section
local SkyboxSection = Tabs.Environment:AddSection("Skybox")

local SkyboxToggle = Tabs.Environment:AddToggle("SkyboxEnabled", {
    Title = "Enable Custom Skybox",
    Default = false,
    Description = "Apply custom skybox settings"
})

local SkyboxSunAngularSize = Tabs.Environment:AddSlider("SkyboxSunAngularSize", {
    Title = "Sun Size",
    Description = "Size of the sun in the sky",
    Default = 21,
    Min = 5,
    Max = 50,
    Rounding = 1
})

local SkyboxMoonAngularSize = Tabs.Environment:AddSlider("SkyboxMoonAngularSize", {
    Title = "Moon Size",
    Description = "Size of the moon in the sky",
    Default = 11,
    Min = 5,
    Max = 30,
    Rounding = 1
})

local SkyboxStarCount = Tabs.Environment:AddSlider("SkyboxStarCount", {
    Title = "Star Count",
    Description = "Number of stars visible",
    Default = 3000,
    Min = 0,
    Max = 10000,
    Rounding = 100
})

-- LIGHTING TAB

-- Lighting Section
local LightingSection = Tabs.Lighting:AddSection("Global Lighting")

local LightingToggle = Tabs.Lighting:AddToggle("LightingEnabled", {
    Title = "Enable Custom Lighting",
    Default = false,
    Description = "Apply custom lighting settings"
})

local LightingBrightness = Tabs.Lighting:AddSlider("LightingBrightness", {
    Title = "Brightness",
    Description = "Global lighting brightness",
    Default = 2,
    Min = 0,
    Max = 10,
    Rounding = 1
})

local ExposureCompensation = Tabs.Lighting:AddSlider("ExposureCompensation", {
    Title = "Exposure",
    Description = "Camera exposure compensation",
    Default = 0,
    Min = -3,
    Max = 3,
    Rounding = 2
})

local ShadowSoftness = Tabs.Lighting:AddSlider("ShadowSoftness", {
    Title = "Shadow Softness",
    Description = "Softness of shadows",
    Default = 0.2,
    Min = 0,
    Max = 1,
    Rounding = 2
})

-- Ambient Lighting Section
local AmbientSection = Tabs.Lighting:AddSection("Ambient Lighting")

local AmbientColor = Tabs.Lighting:AddColorpicker("AmbientColor", {
    Title = "Ambient Color",
    Description = "Color of ambient lighting",
    Default = Color3.fromRGB(70, 70, 70)
})

local OutdoorAmbient = Tabs.Lighting:AddColorpicker("OutdoorAmbient", {
    Title = "Outdoor Ambient",
    Description = "Outdoor ambient lighting color",
    Default = Color3.fromRGB(70, 70, 70)
})

-- Technology Section
local TechnologySection = Tabs.Lighting:AddSection("Rendering")

local Technology = Tabs.Lighting:AddDropdown("Technology", {
    Title = "Lighting Technology",
    Values = {"Legacy", "Voxel", "ShadowMap", "Future"},
    Default = "Future",
    Description = "Roblox lighting technology"
})

-- TIME & WEATHER TAB

-- Time Control Section
local TimeSection = Tabs.Time:AddSection("Time of Day")

local TimeToggle = Tabs.Time:AddToggle("TimeEnabled", {
    Title = "Enable Time Control",
    Default = false,
    Description = "Control game time of day"
})

local TimeSlider = Tabs.Time:AddSlider("TimeValue", {
    Title = "Time of Day",
    Description = "Current time (0=midnight, 12=noon)",
    Default = 12,
    Min = 0,
    Max = 24,
    Rounding = 1
})

local GeographicLatitude = Tabs.Time:AddSlider("GeographicLatitude", {
    Title = "Geographic Latitude",
    Description = "Geographic latitude for sun position",
    Default = 0,
    Min = -80,
    Max = 80,
    Rounding = 1
})

-- Quick Time Presets
local SunriseButton = Tabs.Time:AddButton({
    Title = "Sunrise (6:00)",
    Description = "Set time to sunrise",
    Callback = function()
        Options.TimeEnabled:SetValue(true)
        Options.TimeValue:SetValue(6)
        Options.GeographicLatitude:SetValue(20)
    end
})

local NoonButton = Tabs.Time:AddButton({
    Title = "Noon (12:00)",
    Description = "Set time to noon",
    Callback = function()
        Options.TimeEnabled:SetValue(true)
        Options.TimeValue:SetValue(12)
        Options.GeographicLatitude:SetValue(0)
    end
})

local SunsetButton = Tabs.Time:AddButton({
    Title = "Sunset (18:00)",
    Description = "Set time to sunset",
    Callback = function()
        Options.TimeEnabled:SetValue(true)
        Options.TimeValue:SetValue(18)
        Options.GeographicLatitude:SetValue(20)
    end
})

local MidnightButton = Tabs.Time:AddButton({
    Title = "Midnight (0:00)",
    Description = "Set time to midnight",
    Callback = function()
        Options.TimeEnabled:SetValue(true)
        Options.TimeValue:SetValue(0)
        Options.GeographicLatitude:SetValue(0)
    end
})

-- Weather Section
local WeatherSection = Tabs.Time:AddSection("Weather Effects")

local WindToggle = Tabs.Time:AddToggle("WindEnabled", {
    Title = "Enable Wind",
    Default = false,
    Description = "Apply wind effects to trees and grass"
})

local WindSpeed = Tabs.Time:AddSlider("WindSpeed", {
    Title = "Wind Speed",
    Description = "Speed of wind animation",
    Default = 15,
    Min = 0,
    Max = 50,
    Rounding = 1
})

local WindDirection = Tabs.Time:AddSlider("WindDirection", {
    Title = "Wind Direction",
    Description = "Direction of wind (degrees)",
    Default = 0,
    Min = 0,
    Max = 360,
    Rounding = 10
})

-- PERFORMANCE TAB

-- Performance Monitor Section
local PerformanceSection = Tabs.Performance:AddSection("Performance Monitor")

local ShowFPSToggle = Tabs.Performance:AddToggle("ShowFPS", {
    Title = "Show FPS Counter",
    Default = false,
    Description = "Display FPS in top-left corner"
})

local ShowPingToggle = Tabs.Performance:AddToggle("ShowPing", {
    Title = "Show Ping Counter",
    Default = false,
    Description = "Display ping in top-left corner"
})

local ShowStatsToggle = Tabs.Performance:AddToggle("ShowStats", {
    Title = "Show Performance Stats",
    Default = false,
    Description = "Display detailed performance statistics"
})

-- Quality Settings Section
local QualitySection = Tabs.Performance:AddSection("Quality Settings")

local QualityToggle = Tabs.Performance:AddToggle("QualityEnabled", {
    Title = "Enable Quality Control",
    Default = false,
    Description = "Override Roblox quality settings"
})

local GraphicsQuality = Tabs.Performance:AddDropdown("GraphicsQuality", {
    Title = "Graphics Quality",
    Values = {"1 - Lowest", "2 - Low", "3 - Medium", "4 - High", "5 - Ultra"},
    Default = "5 - Ultra",
    Description = "Roblox graphics quality level"
})

local RenderDistance = Tabs.Performance:AddSlider("RenderDistance", {
    Title = "Render Distance",
    Description = "Maximum render distance",
    Default = 1000,
    Min = 100,
    Max = 2000,
    Rounding = 50
})

-- Screenshot Section
local ScreenshotSection = Tabs.Performance:AddSection("Screenshot")

local ScreenshotButton = Tabs.Performance:AddButton({
    Title = "Take Screenshot",
    Description = "Capture screenshot with current effects",
    Callback = function()
        Fluent:Notify({
            Title = "BloxShade",
            Content = "Screenshot saved to Screenshots folder",
            Duration = 3
        })
    end
})

local HideUIToggle = Tabs.Performance:AddToggle("HideUI", {
    Title = "Hide UI for Screenshots",
    Default = false,
    Description = "Temporarily hide UI when taking screenshots"
})

-- PRESETS TAB

local PresetsSection = Tabs.Presets:AddSection("Preset Management")

-- Preset buttons
local SavePresetButton = Tabs.Presets:AddButton({
    Title = "Save Current Settings",
    Description = "Save current configuration as preset",
    Callback = function()
        local presetName = "Preset_" .. os.date("%Y%m%d_%H%M%S")
        local presetData = {
            -- Post Effects
            BlurEnabled = Options.BlurEnabled.Value,
            BlurSize = Options.BlurSize.Value,
            BloomEnabled = Options.BloomEnabled.Value,
            BloomIntensity = Options.BloomIntensity.Value,
            BloomSize = Options.BloomSize.Value,
            BloomThreshold = Options.BloomThreshold.Value,
            ColorEnabled = Options.ColorEnabled.Value,
            Brightness = Options.Brightness.Value,
            Contrast = Options.Contrast.Value,
            Saturation = Options.Saturation.Value,
            TintColor = Options.TintColor.Value,
            SunRaysEnabled = Options.SunRaysEnabled.Value,
            SunRaysIntensity = Options.SunRaysIntensity.Value,
            SunRaysSpread = Options.SunRaysSpread.Value,
            DOFEnabled = Options.DOFEnabled.Value,
            DOFFocusDistance = Options.DOFFocusDistance.Value,
            DOFInFocusRadius = Options.DOFInFocusRadius.Value,
            DOFNearIntensity = Options.DOFNearIntensity.Value,
            DOFFarIntensity = Options.DOFFarIntensity.Value,
            -- Environment
            AtmosphereEnabled = Options.AtmosphereEnabled.Value,
            AtmosphereDensity = Options.AtmosphereDensity.Value,
            AtmosphereOffset = Options.AtmosphereOffset.Value,
            AtmosphereHaze = Options.AtmosphereHaze.Value,
            AtmosphereGlare = Options.AtmosphereGlare.Value,
            AtmosphereColor = Options.AtmosphereColor.Value,
            AtmosphereDecay = Options.AtmosphereDecay.Value,
            -- Advanced Effects
            VignetteEnabled = Options.VignetteEnabled.Value,
            VignetteIntensity = Options.VignetteIntensity.Value,
            VignetteSize = Options.VignetteSize.Value,
            VignetteSmoothness = Options.VignetteSmoothness.Value,
            ChromaticEnabled = Options.ChromaticEnabled.Value,
            ChromaticIntensity = Options.ChromaticIntensity.Value,
            FilmGrainEnabled = Options.FilmGrainEnabled.Value,
            FilmGrainAmount = Options.FilmGrainAmount.Value,
            FilmGrainSize = Options.FilmGrainSize.Value,
            ToneMappingEnabled = Options.ToneMappingEnabled.Value,
            ToneMappingExposure = Options.ToneMappingExposure.Value,
            ColorGradingEnabled = Options.ColorGradingEnabled.Value,
            Temperature = Options.Temperature.Value,
            Tint = Options.Tint.Value,
            Highlights = Options.Highlights.Value,
            Shadows = Options.Shadows.Value,
            Whites = Options.Whites.Value,
            Blacks = Options.Blacks.Value,
            SharpeningEnabled = Options.SharpeningEnabled.Value,
            SharpeningAmount = Options.SharpeningAmount.Value,
            -- Environment Extended
            FogEnabled = Options.FogEnabled.Value,
            FogStart = Options.FogStart.Value,
            FogEnd = Options.FogEnd.Value,
            FogColor = Options.FogColor.Value,
            SkyboxEnabled = Options.SkyboxEnabled.Value,
            SkyboxSunAngularSize = Options.SkyboxSunAngularSize.Value,
            SkyboxMoonAngularSize = Options.SkyboxMoonAngularSize.Value,
            SkyboxStarCount = Options.SkyboxStarCount.Value,
            -- Lighting
            LightingEnabled = Options.LightingEnabled.Value,
            LightingBrightness = Options.LightingBrightness.Value,
            ExposureCompensation = Options.ExposureCompensation.Value,
            ShadowSoftness = Options.ShadowSoftness.Value,
            AmbientColor = Options.AmbientColor.Value,
            OutdoorAmbient = Options.OutdoorAmbient.Value,
            Technology = Options.Technology.Value,
            -- Time & Weather
            TimeEnabled = Options.TimeEnabled.Value,
            TimeValue = Options.TimeValue.Value,
            GeographicLatitude = Options.GeographicLatitude.Value,
            WindEnabled = Options.WindEnabled.Value,
            WindSpeed = Options.WindSpeed.Value,
            WindDirection = Options.WindDirection.Value,
            -- Performance
            ShowFPS = Options.ShowFPS.Value,
            ShowPing = Options.ShowPing.Value,
            ShowStats = Options.ShowStats.Value,
            QualityEnabled = Options.QualityEnabled.Value,
            GraphicsQuality = Options.GraphicsQuality.Value,
            RenderDistance = Options.RenderDistance.Value
        }

        writefile("BloxShade/Presets/" .. presetName .. ".json", game:GetService("HttpService"):JSONEncode(presetData))

        Fluent:Notify({
            Title = "BloxShade",
            Content = "Preset saved as " .. presetName,
            Duration = 3
        })
    end
})

local ResetButton = Tabs.Presets:AddButton({
    Title = "Reset to Defaults",
    Description = "Reset all settings to default values",
    Callback = function()
        -- Reset post effects
        Options.BlurEnabled:SetValue(false)
        Options.BlurSize:SetValue(24)
        Options.BloomEnabled:SetValue(false)
        Options.BloomIntensity:SetValue(0.4)
        Options.BloomSize:SetValue(24)
        Options.BloomThreshold:SetValue(0.95)
        Options.ColorEnabled:SetValue(false)
        Options.Brightness:SetValue(0)
        Options.Contrast:SetValue(0)
        Options.Saturation:SetValue(0)
        Options.TintColor:SetValue(Color3.fromRGB(255, 255, 255))
        Options.SunRaysEnabled:SetValue(false)
        Options.SunRaysIntensity:SetValue(0.25)
        Options.SunRaysSpread:SetValue(1)
        Options.DOFEnabled:SetValue(false)
        Options.DOFFocusDistance:SetValue(0.05)
        Options.DOFInFocusRadius:SetValue(0.1)
        Options.DOFNearIntensity:SetValue(0.25)
        Options.DOFFarIntensity:SetValue(0.25)

        -- Reset environment
        Options.AtmosphereEnabled:SetValue(false)
        Options.AtmosphereDensity:SetValue(0.3)
        Options.AtmosphereOffset:SetValue(0.25)
        Options.AtmosphereHaze:SetValue(0)
        Options.AtmosphereGlare:SetValue(0)
        Options.AtmosphereColor:SetValue(Color3.fromRGB(199, 199, 199))
        Options.AtmosphereDecay:SetValue(Color3.fromRGB(92, 60, 13))

        -- Reset advanced effects
        Options.VignetteEnabled:SetValue(false)
        Options.VignetteIntensity:SetValue(0.5)
        Options.VignetteSize:SetValue(0.3)
        Options.VignetteSmoothness:SetValue(0.5)
        Options.ChromaticEnabled:SetValue(false)
        Options.ChromaticIntensity:SetValue(0.5)
        Options.FilmGrainEnabled:SetValue(false)
        Options.FilmGrainAmount:SetValue(0.3)
        Options.FilmGrainSize:SetValue(1)
        Options.ToneMappingEnabled:SetValue(false)
        Options.ToneMappingExposure:SetValue(1)
        Options.ColorGradingEnabled:SetValue(false)
        Options.Temperature:SetValue(0)
        Options.Tint:SetValue(0)
        Options.Highlights:SetValue(0)
        Options.Shadows:SetValue(0)
        Options.Whites:SetValue(0)
        Options.Blacks:SetValue(0)
        Options.SharpeningEnabled:SetValue(false)
        Options.SharpeningAmount:SetValue(0.5)

        -- Reset environment extended
        Options.FogEnabled:SetValue(false)
        Options.FogStart:SetValue(15)
        Options.FogEnd:SetValue(100)
        Options.FogColor:SetValue(Color3.fromRGB(192, 192, 192))
        Options.SkyboxEnabled:SetValue(false)
        Options.SkyboxSunAngularSize:SetValue(21)
        Options.SkyboxMoonAngularSize:SetValue(11)
        Options.SkyboxStarCount:SetValue(3000)

        -- Reset lighting
        Options.LightingEnabled:SetValue(false)
        Options.LightingBrightness:SetValue(2)
        Options.ExposureCompensation:SetValue(0)
        Options.ShadowSoftness:SetValue(0.2)
        Options.AmbientColor:SetValue(Color3.fromRGB(70, 70, 70))
        Options.OutdoorAmbient:SetValue(Color3.fromRGB(70, 70, 70))
        Options.Technology:SetValue("Future")

        -- Reset time & weather
        Options.TimeEnabled:SetValue(false)
        Options.TimeValue:SetValue(12)
        Options.GeographicLatitude:SetValue(0)
        Options.WindEnabled:SetValue(false)
        Options.WindSpeed:SetValue(15)
        Options.WindDirection:SetValue(0)

        -- Reset performance
        Options.ShowFPS:SetValue(false)
        Options.ShowPing:SetValue(false)
        Options.ShowStats:SetValue(false)
        Options.QualityEnabled:SetValue(false)
        Options.GraphicsQuality:SetValue("5 - Ultra")
        Options.RenderDistance:SetValue(1000)

        Fluent:Notify({
            Title = "BloxShade",
            Content = "All settings reset to defaults",
            Duration = 3
        })
    end
})

-- Default Presets
local CinematicButton = Tabs.Presets:AddButton({
    Title = "Cinematic Preset",
    Description = "Load cinematic-style shader preset",
    Callback = function()
        Options.BlurEnabled:SetValue(false)
        Options.BloomEnabled:SetValue(true)
        Options.BloomIntensity:SetValue(0.8)
        Options.BloomSize:SetValue(24)
        Options.BloomThreshold:SetValue(0.8)
        Options.ColorEnabled:SetValue(true)
        Options.Brightness:SetValue(-0.1)
        Options.Contrast:SetValue(0.2)
        Options.Saturation:SetValue(-0.2)
        Options.TintColor:SetValue(Color3.fromRGB(255, 240, 200))
        Options.DOFEnabled:SetValue(true)
        Options.DOFFocusDistance:SetValue(0.1)
        Options.DOFInFocusRadius:SetValue(0.15)
        Options.AtmosphereEnabled:SetValue(true)
        Options.AtmosphereDensity:SetValue(0.4)
        Options.AtmosphereHaze:SetValue(0.2)

        Fluent:Notify({
            Title = "BloxShade",
            Content = "Cinematic preset loaded",
            Duration = 3
        })
    end
})

local VibrantButton = Tabs.Presets:AddButton({
    Title = "Vibrant Preset",
    Description = "Load vibrant color shader preset",
    Callback = function()
        Options.BloomEnabled:SetValue(true)
        Options.BloomIntensity:SetValue(1.2)
        Options.BloomSize:SetValue(32)
        Options.ColorEnabled:SetValue(true)
        Options.Brightness:SetValue(0.1)
        Options.Contrast:SetValue(0.3)
        Options.Saturation:SetValue(0.4)
        Options.TintColor:SetValue(Color3.fromRGB(255, 255, 255))
        Options.LightingEnabled:SetValue(true)
        Options.LightingBrightness:SetValue(3)
        Options.ExposureCompensation:SetValue(0.2)

        Fluent:Notify({
            Title = "BloxShade",
            Content = "Vibrant preset loaded",
            Duration = 3
        })
    end
})

local RetroButton = Tabs.Presets:AddButton({
    Title = "Retro Preset",
    Description = "Load retro-style shader preset",
    Callback = function()
        Options.ColorEnabled:SetValue(true)
        Options.Brightness:SetValue(-0.2)
        Options.Contrast:SetValue(0.4)
        Options.Saturation:SetValue(-0.3)
        Options.TintColor:SetValue(Color3.fromRGB(255, 200, 150))
        Options.Technology:SetValue("Legacy")
        Options.AtmosphereEnabled:SetValue(true)
        Options.AtmosphereDensity:SetValue(0.6)
        Options.AtmosphereHaze:SetValue(0.5)

        Fluent:Notify({
            Title = "BloxShade",
            Content = "Retro preset loaded",
            Duration = 3
        })
    end
})

local DramaticButton = Tabs.Presets:AddButton({
    Title = "Dramatic Preset",
    Description = "High-contrast dramatic lighting",
    Callback = function()
        Options.BloomEnabled:SetValue(true)
        Options.BloomIntensity:SetValue(1.5)
        Options.ColorEnabled:SetValue(true)
        Options.Contrast:SetValue(0.6)
        Options.Saturation:SetValue(-0.2)
        Options.VignetteEnabled:SetValue(true)
        Options.VignetteIntensity:SetValue(0.7)
        Options.DOFEnabled:SetValue(true)
        Options.SunRaysEnabled:SetValue(true)
        Options.SunRaysIntensity:SetValue(0.8)
        Options.AtmosphereEnabled:SetValue(true)
        Options.AtmosphereDensity:SetValue(0.5)
        Options.AtmosphereHaze:SetValue(0.3)

        Fluent:Notify({
            Title = "BloxShade",
            Content = "Dramatic preset loaded",
            Duration = 3
        })
    end
})

local FantasyButton = Tabs.Presets:AddButton({
    Title = "Fantasy Preset",
    Description = "Magical fantasy atmosphere",
    Callback = function()
        Options.BloomEnabled:SetValue(true)
        Options.BloomIntensity:SetValue(1.0)
        Options.BloomThreshold:SetValue(0.7)
        Options.ColorEnabled:SetValue(true)
        Options.Saturation:SetValue(0.3)
        Options.TintColor:SetValue(Color3.fromRGB(200, 180, 255))
        Options.FilmGrainEnabled:SetValue(true)
        Options.FilmGrainAmount:SetValue(0.2)
        Options.AtmosphereEnabled:SetValue(true)
        Options.AtmosphereDensity:SetValue(0.4)
        Options.AtmosphereColor:SetValue(Color3.fromRGB(180, 150, 255))
        Options.FogEnabled:SetValue(true)
        Options.FogColor:SetValue(Color3.fromRGB(150, 120, 200))

        Fluent:Notify({
            Title = "BloxShade",
            Content = "Fantasy preset loaded",
            Duration = 3
        })
    end
})

local HorrorButton = Tabs.Presets:AddButton({
    Title = "Horror Preset",
    Description = "Dark and eerie atmosphere",
    Callback = function()
        Options.ColorEnabled:SetValue(true)
        Options.Brightness:SetValue(-0.4)
        Options.Contrast:SetValue(0.5)
        Options.Saturation:SetValue(-0.6)
        Options.TintColor:SetValue(Color3.fromRGB(100, 120, 80))
        Options.VignetteEnabled:SetValue(true)
        Options.VignetteIntensity:SetValue(0.8)
        Options.VignetteSize:SetValue(0.2)
        Options.FilmGrainEnabled:SetValue(true)
        Options.FilmGrainAmount:SetValue(0.4)
        Options.ChromaticEnabled:SetValue(true)
        Options.ChromaticIntensity:SetValue(0.3)
        Options.FogEnabled:SetValue(true)
        Options.FogColor:SetValue(Color3.fromRGB(50, 50, 50))
        Options.TimeEnabled:SetValue(true)
        Options.TimeValue:SetValue(0)

        Fluent:Notify({
            Title = "BloxShade",
            Content = "Horror preset loaded",
            Duration = 3
        })
    end
})

local NightTimeButton = Tabs.Presets:AddButton({
    Title = "Night Time Preset",
    Description = "Beautiful night scene",
    Callback = function()
        Options.TimeEnabled:SetValue(true)
        Options.TimeValue:SetValue(22)
        Options.BloomEnabled:SetValue(true)
        Options.BloomIntensity:SetValue(0.8)
        Options.ColorEnabled:SetValue(true)
        Options.Brightness:SetValue(-0.1)
        Options.TintColor:SetValue(Color3.fromRGB(150, 150, 200))
        Options.AtmosphereEnabled:SetValue(true)
        Options.AtmosphereDensity:SetValue(0.3)
        Options.SkyboxEnabled:SetValue(true)
        Options.SkyboxStarCount:SetValue(8000)

        Fluent:Notify({
            Title = "BloxShade",
            Content = "Night time preset loaded",
            Duration = 3
        })
    end
})

local PhotographyButton = Tabs.Presets:AddButton({
    Title = "Photography Preset",
    Description = "Professional photography look",
    Callback = function()
        Options.DOFEnabled:SetValue(true)
        Options.DOFFocusDistance:SetValue(0.08)
        Options.DOFInFocusRadius:SetValue(0.12)
        Options.BloomEnabled:SetValue(true)
        Options.BloomIntensity:SetValue(0.6)
        Options.ColorGradingEnabled:SetValue(true)
        Options.Highlights:SetValue(-0.2)
        Options.Shadows:SetValue(0.1)
        Options.VignetteEnabled:SetValue(true)
        Options.VignetteIntensity:SetValue(0.3)
        Options.SharpeningEnabled:SetValue(true)
        Options.SharpeningAmount:SetValue(0.7)

        Fluent:Notify({
            Title = "BloxShade",
            Content = "Photography preset loaded",
            Duration = 3
        })
    end
})

-- Create custom effect frames for vignette, film grain, etc.
local vignetteFrame = nil
local filmGrainFrame = nil
local performanceGui = nil

-- Initialize custom effect frames
local function initializeCustomEffects()
    -- Vignette frame
    vignetteFrame = Instance.new("Frame")
    vignetteFrame.Name = "VignetteEffect"
    vignetteFrame.Size = UDim2.new(1, 0, 1, 0)
    vignetteFrame.Position = UDim2.new(0, 0, 0, 0)
    vignetteFrame.BackgroundTransparency = 1
    vignetteFrame.BorderSizePixel = 0
    vignetteFrame.Parent = Effects.Vignette

    local vignetteGradient = Instance.new("UIGradient")
    vignetteGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.7, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    vignetteGradient.Parent = vignetteFrame

    -- Film grain frame
    filmGrainFrame = Instance.new("Frame")
    filmGrainFrame.Name = "FilmGrainEffect"
    filmGrainFrame.Size = UDim2.new(1, 0, 1, 0)
    filmGrainFrame.Position = UDim2.new(0, 0, 0, 0)
    filmGrainFrame.BackgroundTransparency = 1
    filmGrainFrame.BorderSizePixel = 0
    filmGrainFrame.Parent = Effects.FilmGrain

    -- Performance monitoring GUI
    performanceGui = Instance.new("ScreenGui")
    performanceGui.Name = "PerformanceMonitor"
    performanceGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(0, 200, 0, 100)
    statsFrame.Position = UDim2.new(0, 10, 0, 10)
    statsFrame.BackgroundTransparency = 0.3
    statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = performanceGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = statsFrame

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSLabel"
    fpsLabel.Size = UDim2.new(1, 0, 0.33, 0)
    fpsLabel.Position = UDim2.new(0, 0, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 60"
    fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpsLabel.TextScaled = true
    fpsLabel.Font = Enum.Font.SourceSansBold
    fpsLabel.Parent = statsFrame

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "PingLabel"
    pingLabel.Size = UDim2.new(1, 0, 0.33, 0)
    pingLabel.Position = UDim2.new(0, 0, 0.33, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "PING: 0ms"
    pingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    pingLabel.TextScaled = true
    pingLabel.Font = Enum.Font.SourceSansBold
    pingLabel.Parent = statsFrame

    local memoryLabel = Instance.new("TextLabel")
    memoryLabel.Name = "MemoryLabel"
    memoryLabel.Size = UDim2.new(1, 0, 0.34, 0)
    memoryLabel.Position = UDim2.new(0, 0, 0.66, 0)
    memoryLabel.BackgroundTransparency = 1
    memoryLabel.Text = "MEM: 0MB"
    memoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    memoryLabel.TextScaled = true
    memoryLabel.Font = Enum.Font.SourceSansBold
    memoryLabel.Parent = statsFrame

    statsFrame.Visible = false
end

-- Performance monitoring
local frameCount = 0
local lastTime = tick()
local currentFPS = 0

RunService.Heartbeat:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()

    if currentTime - lastTime >= 1 then
        currentFPS = frameCount
        frameCount = 0
        lastTime = currentTime

        if performanceGui and performanceGui:FindFirstChild("StatsFrame") then
            local statsFrame = performanceGui.StatsFrame
            if Options.ShowFPS and Options.ShowFPS.Value then
                statsFrame.FPSLabel.Text = "FPS: " .. currentFPS
                statsFrame.FPSLabel.Visible = true
            else
                statsFrame.FPSLabel.Visible = false
            end

            if Options.ShowPing and Options.ShowPing.Value then
                local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                statsFrame.PingLabel.Text = "PING: " .. math.floor(ping) .. "ms"
                statsFrame.PingLabel.Visible = true
            else
                statsFrame.PingLabel.Visible = false
            end

            if Options.ShowStats and Options.ShowStats.Value then
                local memory = game:GetService("Stats"):GetTotalMemoryUsageMb()
                statsFrame.MemoryLabel.Text = "MEM: " .. math.floor(memory) .. "MB"
                statsFrame.MemoryLabel.Visible = true
            else
                statsFrame.MemoryLabel.Visible = false
            end

            statsFrame.Visible = (Options.ShowFPS and Options.ShowFPS.Value) or
                                (Options.ShowPing and Options.ShowPing.Value) or
                                (Options.ShowStats and Options.ShowStats.Value)
        end
    end
end)

task.spawn(initializeCustomEffects)

-- Function to apply blur effect
local function applyBlur()
    if Options.BlurEnabled.Value then
        Effects.Blur.Enabled = true
        Effects.Blur.Size = Options.BlurSize.Value
    else
        Effects.Blur.Enabled = false
        Effects.Blur.Size = OriginalEffects.Blur.Size
    end
end

-- Function to apply bloom effect
local function applyBloom()
    if Options.BloomEnabled.Value then
        Effects.Bloom.Enabled = true
        Effects.Bloom.Intensity = Options.BloomIntensity.Value
        Effects.Bloom.Size = Options.BloomSize.Value
        Effects.Bloom.Threshold = Options.BloomThreshold.Value
    else
        Effects.Bloom.Enabled = false
        Effects.Bloom.Intensity = OriginalEffects.Bloom.Intensity
        Effects.Bloom.Size = OriginalEffects.Bloom.Size
        Effects.Bloom.Threshold = OriginalEffects.Bloom.Threshold
    end
end

-- Function to apply color correction
local function applyColorCorrection()
    if Options.ColorEnabled.Value then
        Effects.ColorCorrection.Enabled = true
        Effects.ColorCorrection.Brightness = Options.Brightness.Value
        Effects.ColorCorrection.Contrast = Options.Contrast.Value
        Effects.ColorCorrection.Saturation = Options.Saturation.Value
        Effects.ColorCorrection.TintColor = Options.TintColor.Value
    else
        Effects.ColorCorrection.Enabled = false
        Effects.ColorCorrection.Brightness = OriginalEffects.ColorCorrection.Brightness
        Effects.ColorCorrection.Contrast = OriginalEffects.ColorCorrection.Contrast
        Effects.ColorCorrection.Saturation = OriginalEffects.ColorCorrection.Saturation
        Effects.ColorCorrection.TintColor = OriginalEffects.ColorCorrection.TintColor
    end
end

-- Function to apply sun rays
local function applySunRays()
    if Options.SunRaysEnabled.Value then
        Effects.SunRays.Enabled = true
        Effects.SunRays.Intensity = Options.SunRaysIntensity.Value
        Effects.SunRays.Spread = Options.SunRaysSpread.Value
    else
        Effects.SunRays.Enabled = false
        Effects.SunRays.Intensity = OriginalEffects.SunRays.Intensity
        Effects.SunRays.Spread = OriginalEffects.SunRays.Spread
    end
end

-- Function to apply depth of field
local function applyDOF()
    if Options.DOFEnabled.Value then
        Effects.DepthOfField.Enabled = true
        Effects.DepthOfField.FocusDistance = Options.DOFFocusDistance.Value
        Effects.DepthOfField.InFocusRadius = Options.DOFInFocusRadius.Value
        Effects.DepthOfField.NearIntensity = Options.DOFNearIntensity.Value
        Effects.DepthOfField.FarIntensity = Options.DOFFarIntensity.Value
    else
        Effects.DepthOfField.Enabled = false
        Effects.DepthOfField.FocusDistance = OriginalEffects.DepthOfField.FocusDistance
        Effects.DepthOfField.InFocusRadius = OriginalEffects.DepthOfField.InFocusRadius
        Effects.DepthOfField.NearIntensity = OriginalEffects.DepthOfField.NearIntensity
        Effects.DepthOfField.FarIntensity = OriginalEffects.DepthOfField.FarIntensity
    end
end

-- Function to apply atmosphere
local function applyAtmosphere()
    if Options.AtmosphereEnabled.Value and Atmosphere then
        Atmosphere.Density = Options.AtmosphereDensity.Value
        Atmosphere.Offset = Options.AtmosphereOffset.Value
        Atmosphere.Haze = Options.AtmosphereHaze.Value
        Atmosphere.Glare = Options.AtmosphereGlare.Value
        Atmosphere.Color = Options.AtmosphereColor.Value
        Atmosphere.Decay = Options.AtmosphereDecay.Value
    else
        if Atmosphere and OriginalValues.Atmosphere then
            Atmosphere.Density = OriginalValues.Atmosphere.Density
            Atmosphere.Offset = OriginalValues.Atmosphere.Offset
            Atmosphere.Haze = OriginalValues.Atmosphere.Haze
            Atmosphere.Glare = OriginalValues.Atmosphere.Glare
            Atmosphere.Color = OriginalValues.Atmosphere.Color
            Atmosphere.Decay = OriginalValues.Atmosphere.Decay
        end
    end
end

-- Function to apply lighting
local function applyLighting()
    if Options.LightingEnabled.Value then
        Lighting.Brightness = Options.LightingBrightness.Value
        Lighting.ExposureCompensation = Options.ExposureCompensation.Value
        Lighting.ShadowSoftness = Options.ShadowSoftness.Value
        Lighting.Ambient = Options.AmbientColor.Value
        Lighting.OutdoorAmbient = Options.OutdoorAmbient.Value

        local techValue = Options.Technology.Value
        if techValue == "Legacy" then
            Lighting.Technology = Enum.Technology.Legacy
        elseif techValue == "Voxel" then
            Lighting.Technology = Enum.Technology.Voxel
        elseif techValue == "ShadowMap" then
            Lighting.Technology = Enum.Technology.ShadowMap
        else
            Lighting.Technology = Enum.Technology.Future
        end
    else
        Lighting.Brightness = OriginalValues.Lighting.Brightness
        Lighting.ExposureCompensation = OriginalValues.Lighting.ExposureCompensation
        Lighting.ShadowSoftness = OriginalValues.Lighting.ShadowSoftness
        Lighting.Ambient = OriginalValues.Lighting.Ambient
        Lighting.OutdoorAmbient = OriginalValues.Lighting.OutdoorAmbient
        Lighting.Technology = OriginalValues.Lighting.Technology
    end
end

-- Connect all events
BlurToggle:OnChanged(applyBlur)
BlurSize:OnChanged(applyBlur)

BloomToggle:OnChanged(applyBloom)
BloomIntensity:OnChanged(applyBloom)
BloomSize:OnChanged(applyBloom)
BloomThreshold:OnChanged(applyBloom)

ColorToggle:OnChanged(applyColorCorrection)
Brightness:OnChanged(applyColorCorrection)
Contrast:OnChanged(applyColorCorrection)
Saturation:OnChanged(applyColorCorrection)
TintColor:OnChanged(applyColorCorrection)

SunRaysToggle:OnChanged(applySunRays)
SunRaysIntensity:OnChanged(applySunRays)
SunRaysSpread:OnChanged(applySunRays)

DOFToggle:OnChanged(applyDOF)
DOFFocusDistance:OnChanged(applyDOF)
DOFInFocusRadius:OnChanged(applyDOF)
DOFNearIntensity:OnChanged(applyDOF)
DOFFarIntensity:OnChanged(applyDOF)

AtmosphereToggle:OnChanged(applyAtmosphere)
AtmosphereDensity:OnChanged(applyAtmosphere)
AtmosphereOffset:OnChanged(applyAtmosphere)
AtmosphereHaze:OnChanged(applyAtmosphere)
AtmosphereGlare:OnChanged(applyAtmosphere)
AtmosphereColor:OnChanged(applyAtmosphere)
AtmosphereDecay:OnChanged(applyAtmosphere)

LightingToggle:OnChanged(applyLighting)
LightingBrightness:OnChanged(applyLighting)
ExposureCompensation:OnChanged(applyLighting)
ShadowSoftness:OnChanged(applyLighting)
AmbientColor:OnChanged(applyLighting)
OutdoorAmbient:OnChanged(applyLighting)
Technology:OnChanged(applyLighting)

-- Function to apply vignette effect
local function applyVignette()
    if Options.VignetteEnabled and Options.VignetteEnabled.Value and vignetteFrame then
        vignetteFrame.BackgroundTransparency = 1 - Options.VignetteIntensity.Value
        vignetteFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

        local gradient = vignetteFrame:FindFirstChild("UIGradient")
        if gradient then
            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(Options.VignetteSize.Value, 1),
                NumberSequenceKeypoint.new(1, 1 - Options.VignetteSmoothness.Value)
            })
        end
        vignetteFrame.Visible = true
    else
        if vignetteFrame then
            vignetteFrame.Visible = false
        end
    end
end

-- Function to apply chromatic aberration
local function applyChromatic()
    if Options.ChromaticEnabled and Options.ChromaticEnabled.Value then
        -- Create chromatic aberration effect using multiple ColorCorrectionEffects
        -- This is a simplified version as true chromatic aberration is complex
        local intensity = Options.ChromaticIntensity.Value
        if intensity > 0 then
            Effects.ColorCorrection.TintColor = Color3.fromRGB(
                255 - intensity * 20,
                255,
                255 - intensity * 20
            )
        end
    end
end

-- Function to apply film grain
local function applyFilmGrain()
    if Options.FilmGrainEnabled and Options.FilmGrainEnabled.Value and filmGrainFrame then
        -- Create animated film grain effect
        local grainAmount = Options.FilmGrainAmount.Value
        local grainSize = Options.FilmGrainSize.Value

        filmGrainFrame.BackgroundTransparency = 1 - (grainAmount * 0.1)
        filmGrainFrame.BackgroundColor3 = Color3.fromRGB(
            math.random(200, 255),
            math.random(200, 255),
            math.random(200, 255)
        )
        filmGrainFrame.Visible = true

        -- Animate grain
        task.spawn(function()
            while Options.FilmGrainEnabled and Options.FilmGrainEnabled.Value do
                filmGrainFrame.BackgroundColor3 = Color3.fromRGB(
                    math.random(200, 255),
                    math.random(200, 255),
                    math.random(200, 255)
                )
                task.wait(0.1 / grainSize)
            end
        end)
    else
        if filmGrainFrame then
            filmGrainFrame.Visible = false
        end
    end
end

-- Function to apply tone mapping
local function applyToneMapping()
    if Options.ToneMappingEnabled and Options.ToneMappingEnabled.Value then
        local exposure = Options.ToneMappingExposure.Value
        Lighting.ExposureCompensation = math.log(exposure, 2)

        -- Enhanced color correction for ACES-like tone mapping
        Effects.ColorCorrection.Contrast = 0.1
        Effects.ColorCorrection.Saturation = 0.05
    end
end

-- Function to apply color grading
local function applyColorGrading()
    if Options.ColorGradingEnabled and Options.ColorGradingEnabled.Value then
        local temp = Options.Temperature.Value
        local tint = Options.Tint.Value
        local highlights = Options.Highlights.Value
        local shadows = Options.Shadows.Value
        local whites = Options.Whites.Value
        local blacks = Options.Blacks.Value

        -- Apply temperature and tint
        local tempColor = Color3.fromRGB(
            255 + (temp * 30),
            255,
            255 - (temp * 30)
        )
        local tintColor = Color3.fromRGB(
            255 - (tint * 20),
            255 + (tint * 20),
            255 - (tint * 10)
        )

        -- Combine temperature and tint
        Effects.ColorCorrection.TintColor = Color3.new(
            (tempColor.R + tintColor.R) / 2,
            (tempColor.G + tintColor.G) / 2,
            (tempColor.B + tintColor.B) / 2
        )

        -- Apply highlight/shadow adjustments
        Effects.ColorCorrection.Brightness = (highlights + shadows) / 4
        Effects.ColorCorrection.Contrast = (whites - blacks) / 2
    end
end

-- Function to apply sharpening
local function applySharpening()
    if Options.SharpeningEnabled and Options.SharpeningEnabled.Value then
        -- Simulate sharpening through contrast adjustment
        local amount = Options.SharpeningAmount.Value
        Effects.ColorCorrection.Contrast = math.min(Effects.ColorCorrection.Contrast + amount * 0.2, 1)
    end
end

-- Function to apply fog
local function applyFog()
    if Options.FogEnabled and Options.FogEnabled.Value then
        Lighting.FogStart = Options.FogStart.Value
        Lighting.FogEnd = Options.FogEnd.Value
        Lighting.FogColor = Options.FogColor.Value
    else
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        Lighting.FogColor = Color3.fromRGB(192, 192, 192)
    end
end

-- Function to apply skybox settings
local function applySkybox()
    if Options.SkyboxEnabled and Options.SkyboxEnabled.Value then
        Lighting.SunAngularSize = Options.SkyboxSunAngularSize.Value
        Lighting.MoonAngularSize = Options.SkyboxMoonAngularSize.Value
        Lighting.StarCount = Options.SkyboxStarCount.Value
    else
        Lighting.SunAngularSize = 21
        Lighting.MoonAngularSize = 11
        Lighting.StarCount = 3000
    end
end

-- Function to apply time controls
local function applyTime()
    if Options.TimeEnabled and Options.TimeEnabled.Value then
        Lighting.TimeOfDay = tostring(Options.TimeValue.Value) .. ":00:00"
        Lighting.GeographicLatitude = Options.GeographicLatitude.Value
    end
end

-- Function to apply wind effects
local function applyWind()
    if Options.WindEnabled and Options.WindEnabled.Value then
        workspace.GlobalWind = Vector3.new(
            math.cos(math.rad(Options.WindDirection.Value)) * Options.WindSpeed.Value,
            0,
            math.sin(math.rad(Options.WindDirection.Value)) * Options.WindSpeed.Value
        )
    else
        workspace.GlobalWind = Vector3.new(0, 0, 0)
    end
end

-- Function to apply quality settings
local function applyQuality()
    if Options.QualityEnabled and Options.QualityEnabled.Value then
        local qualityLevel = tonumber(string.sub(Options.GraphicsQuality.Value, 1, 1))
        settings().Rendering.QualityLevel = qualityLevel

        -- Set render distance
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = math.min(Options.RenderDistance.Value / 20, 120)
        end
    end
end

-- Connect all new events
VignetteToggle:OnChanged(applyVignette)
VignetteIntensity:OnChanged(applyVignette)
VignetteSize:OnChanged(applyVignette)
VignetteSmoothness:OnChanged(applyVignette)

ChromaticToggle:OnChanged(applyChromatic)
ChromaticIntensity:OnChanged(applyChromatic)

FilmGrainToggle:OnChanged(applyFilmGrain)
FilmGrainAmount:OnChanged(applyFilmGrain)
FilmGrainSize:OnChanged(applyFilmGrain)

ToneMappingToggle:OnChanged(applyToneMapping)
ToneMappingExposure:OnChanged(applyToneMapping)

ColorGradingToggle:OnChanged(applyColorGrading)
Temperature:OnChanged(applyColorGrading)
Tint:OnChanged(applyColorGrading)
Highlights:OnChanged(applyColorGrading)
Shadows:OnChanged(applyColorGrading)
Whites:OnChanged(applyColorGrading)
Blacks:OnChanged(applyColorGrading)

SharpeningToggle:OnChanged(applySharpening)
SharpeningAmount:OnChanged(applySharpening)

FogToggle:OnChanged(applyFog)
FogStart:OnChanged(applyFog)
FogEnd:OnChanged(applyFog)
FogColor:OnChanged(applyFog)

SkyboxToggle:OnChanged(applySkybox)
SkyboxSunAngularSize:OnChanged(applySkybox)
SkyboxMoonAngularSize:OnChanged(applySkybox)
SkyboxStarCount:OnChanged(applySkybox)

TimeToggle:OnChanged(applyTime)
TimeSlider:OnChanged(applyTime)
GeographicLatitude:OnChanged(applyTime)

WindToggle:OnChanged(applyWind)
WindSpeed:OnChanged(applyWind)
WindDirection:OnChanged(applyWind)

QualityToggle:OnChanged(applyQuality)
GraphicsQuality:OnChanged(applyQuality)
RenderDistance:OnChanged(applyQuality)

-- Setup SaveManager and InterfaceManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("BloxShade")
SaveManager:SetFolder("BloxShade/Settings")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Load saved settings
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

-- Notification on load
Fluent:Notify({
    Title = "BloxShade",
    Content = "BloxShade has been loaded successfully!",
    Duration = 2
})

-- Cleanup on exit
game:GetService("Players").PlayerRemoving:Connect(function(plr)
    if plr == Player then
        -- Reset all effects to original values
        for effectName, effect in pairs(Effects) do
            if effect then
                effect:Destroy()
            end
        end

        -- Reset lighting
        for property, value in pairs(OriginalValues.Lighting) do
            Lighting[property] = value
        end

        -- Reset atmosphere
        if Atmosphere and OriginalValues.Atmosphere then
            for property, value in pairs(OriginalValues.Atmosphere) do
                Atmosphere[property] = value
            end
        end
    end
end)

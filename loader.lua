if getgenv().BloxShade_KeySystem_Loaded then
    return
end
getgenv().BloxShade_KeySystem_Loaded = true

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

if not isfolder("BloxShade") then
    makefolder("BloxShade")
end
if not isfolder("BloxShade/KeySystem") then
    makefolder("BloxShade/KeySystem")
end

-- Key system configuration
local KEY_SYSTEM_CONFIG = {
    correctKey = "BloxshadeMobileOnTop",
    linkvertiseUrl = "https://direct-link.net/1358300/TOr7TXCoWmkV",
    verificationFile = "BloxShade/KeySystem/verified.json",
    hwid = game:GetService("RbxAnalyticsService"):GetClientId() -- Hardware ID for verification
}

local function isUserVerified()
    if isfile(KEY_SYSTEM_CONFIG.verificationFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(KEY_SYSTEM_CONFIG.verificationFile))
        end)

        if success and data then
            if data.verifiedUsers and data.verifiedUsers[KEY_SYSTEM_CONFIG.hwid] then
                return true, data.verifiedUsers[KEY_SYSTEM_CONFIG.hwid].verifiedAt
            end
        end
    end
    return false, nil
end

-- Save user verification
local function saveUserVerification()
    local verificationData = {}

    -- Load existing data if file exists
    if isfile(KEY_SYSTEM_CONFIG.verificationFile) then
        local success, existingData = pcall(function()
            return HttpService:JSONDecode(readfile(KEY_SYSTEM_CONFIG.verificationFile))
        end)
        if success and existingData then
            verificationData = existingData
        end
    end

    -- Initialize structure if needed
    if not verificationData.verifiedUsers then
        verificationData.verifiedUsers = {}
    end

    -- Add current user
    verificationData.verifiedUsers[KEY_SYSTEM_CONFIG.hwid] = {
        username = Player.Name,
        userId = Player.UserId,
        verifiedAt = os.time(),
        keyUsed = KEY_SYSTEM_CONFIG.correctKey
    }

    -- Save to file
    writefile(KEY_SYSTEM_CONFIG.verificationFile, HttpService:JSONEncode(verificationData))
end

-- Load the main BloxShade script
local function loadMainScript()
    -- Destroy key system UI
    if getgenv().BloxShade_KeyWindow then
        getgenv().BloxShade_KeyWindow:Destroy()
        getgenv().BloxShade_KeyWindow = nil
    end

    -- Clear key system flag
    getgenv().BloxShade_KeySystem_Loaded = nil

    -- Load your main BloxShade script here
    loadstring(game:HttpGet("https://raw.githubusercontent.com/RealVeylo/Bloxshade/refs/heads/main/Mobile.lua"))()
    task.spawn(function()
        local success, result = pcall(function()
            -- Method 1: If you have the script as a string/file
            -- loadstring(readfile("BloxshadeMobile.lua"))()

            -- Method 2: If you want to load from a URL
            -- loadstring(game:HttpGet("YOUR_SCRIPT_URL"))()

            -- Method 3: Direct execution (replace with your actual script)
            loadstring(readfile("BloxShade.lua"))()
        end)

        if not success then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "BloxShade Error",
                Text = "Failed to load main script: " .. tostring(result),
                Duration = 5
            })
        end
    end)
end

-- Check verification status first
local isVerified, verifiedAt = isUserVerified()
if isVerified then
    -- User is already verified, load main script directly
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BloxShade Mobile",
        Text = "Welcome back! Loading BloxShade...",
        Duration = 3
    })

    task.wait(1) -- Brief delay for notification
    loadMainScript()
    return
end

-- If not verified, show key system UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create key system window
local Window = Fluent:CreateWindow({
    Title = "BloxShade Mobile - Key System",
    SubTitle = "One-time verification required",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End,
    CanResize = false,
    ScrollSpeed = 30,
    ScrollingEnabled = true
})

getgenv().BloxShade_KeyWindow = Window

-- Create tabs
local Tabs = {
    Key = Window:AddTab({ Title = "Key Verification", Icon = "key" }),
    Info = Window:AddTab({ Title = "Info", Icon = "info" })
}

-- Key verification variables
local keyInput = ""
local keyStatus = "Enter your key to continue"

-- KEY TAB
local KeySection = Tabs.Key:AddSection("Verification")

-- Display current status
local StatusParagraph = Tabs.Key:AddParagraph({
    Title = "Status",
    Content = keyStatus
})

-- Key input
local KeyInput = Tabs.Key:AddInput("KeyInput", {
    Title = "Enter Key",
    Default = "",
    Placeholder = "Paste your key here...",
    Numeric = false,
    Finished = false,
    Callback = function(value)
        keyInput = value
    end
})

-- Get key button (opens linkvertise)
local GetKeyButton = Tabs.Key:AddButton({
    Title = "Get Key (Linkvertise)",
    Description = "Click to get your verification key",
    Callback = function()
        -- Copy linkvertise URL to clipboard and notify user
        setclipboard(KEY_SYSTEM_CONFIG.linkvertiseUrl)

        StatusParagraph:SetDesc("✅ Linkvertise URL copied to clipboard!\nPaste it in your browser to get the key.")

        Fluent:Notify({
            Title = "BloxShade Key System",
            Content = "Linkvertise URL copied! Complete the steps to get your key.",
            Duration = 5
        })
    end
})

-- Verify key button
local VerifyButton = Tabs.Key:AddButton({
    Title = "Verify Key",
    Description = "Submit your key for verification",
    Callback = function()
        if keyInput == "" or keyInput == nil then
            StatusParagraph:SetDesc("❌ Please enter a key first!")
            Fluent:Notify({
                Title = "BloxShade Key System",
                Content = "Please enter a key before verifying!",
                Duration = 3
            })
            return
        end

        -- Verify the key
        if keyInput == KEY_SYSTEM_CONFIG.correctKey then
            StatusParagraph:SetDesc("✅ Key verified successfully! Loading BloxShade...")

            Fluent:Notify({
                Title = "BloxShade Key System",
                Content = "Key verified! Loading BloxShade Mobile...",
                Duration = 3
            })

            -- Save verification
            saveUserVerification()

            -- Load main script after brief delay
            task.wait(2)
            loadMainScript()
        else
            StatusParagraph:SetDesc("❌ Invalid key! Please get a valid key from Linkvertise.")
            Fluent:Notify({
                Title = "BloxShade Key System",
                Content = "Invalid key! Please get the correct key.",
                Duration = 3
            })
        end
    end
})

-- INFORMATION TAB
local InfoSection = Tabs.Info:AddSection("About BloxShade Mobile")

Tabs.Info:AddParagraph({
    Title = "What is BloxShade?",
    Content = "BloxShade Mobile is a comprehensive shader suite for Roblox, featuring advanced post-processing effects, lighting controls, and visual enhancements designed for both mobile and PC platforms."
})

Tabs.Info:AddParagraph({
    Title = "Key System Information",
    Content = "• This is a one-time verification\n• Once verified, you'll never need a key again\n• Your verification is saved securely\n• Complete the Linkvertise steps to support development"
})

Tabs.Info:AddParagraph({
    Title = "Features Included",
    Content = "✨ Post Effects: Blur, Bloom, DOF, Vignette\n🎨 Color Grading: Professional controls\n🌍 Environment: Atmosphere, Fog, Skybox\n💡 Lighting: Advanced lighting system\n⏰ Time & Weather: Dynamic controls\n📱 Mobile Optimized: Touch-friendly UI"
})

Tabs.Info:AddParagraph({
    Title = "Support & Updates",
    Content = "This key system helps support continued development and updates. Thank you for your support!"
})

-- Instructions section
local InstructionSection = Tabs.Info:AddSection("How to Get Key")

Tabs.Info:AddParagraph({
    Title = "Step-by-Step Instructions",
    Content = "1️⃣ Click 'Get Key (Linkvertise)' button\n2️⃣ Complete the Linkvertise verification\n3️⃣ Copy the key from the final page\n4️⃣ Paste key in the verification tab\n5️⃣ Click 'Verify Key' to access BloxShade"
})

-- Add some visual flair with a countdown if user tries to skip
local skipAttempts = 0
local SkipButton = Tabs.Key:AddButton({
    Title = "Skip Verification (Not Available)",
    Description = "Complete linkvertise to get your key",
    Callback = function()
        skipAttempts = skipAttempts + 1
        if skipAttempts >= 3 then
            Fluent:Notify({
                Title = "BloxShade Key System",
                Content = "No bypasses available. Please complete verification to support development!",
                Duration = 5
            })
        else
            Fluent:Notify({
                Title = "BloxShade Key System",
                Content = "Please complete the linkvertise verification to get your key.",
                Duration = 3
            })
        end
    end
})

-- Setup Interface Manager
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("BloxShade/KeySystem")
InterfaceManager:BuildInterfaceSection(Tabs.Info)

-- Auto-focus on key tab
Window:SelectTab(1)

-- Welcome notification
Fluent:Notify({
    Title = "BloxShade Mobile",
    Content = "Welcome! Please verify your key to access BloxShade.",
    Duration = 5
})

-- Add some security measures
task.spawn(function()
    while getgenv().BloxShade_KeyWindow do
        task.wait(1)
        -- Check if window still exists
        if not Window or not Window.Root or not Window.Root.Parent then
            break
        end
    end
end)

-- Handle window closing
game:GetService("Players").PlayerRemoving:Connect(function(plr)
    if plr == Player then
        if getgenv().BloxShade_KeyWindow then
            getgenv().BloxShade_KeyWindow:Destroy()
        end
    end
end)
        -- Clean up when key system is done
        task.spawn(function()
            while getgenv().BloxShade_KeyWindow do
                task.wait(1)
            end
            if ScreenGui then
                ScreenGui:Destroy()
            end
            getgenv().BloxShade_KeyMobileUI = nil
        end
    end
end)

print("Hardware ID: " .. KEY_SYSTEM_CONFIG.hwid)

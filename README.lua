-- ==================== UNDERGROUND ====================
-- ==================== UNDERGROUND ====================
-- Cara: buat Part lantai invisible (platform) yang ikut karakter
-- Platform ini solid → karakter selalu punya pijakan, tidak jatuh ke void
-- Platform disembunyikan secara visual (Transparency=1) tapi tetap collision

local undergroundActive = false
local ugPlatform = nil     -- Part lantai buatan
local SINK_DEPTH = 2.8     -- seberapa dalam di bawah permukaan asli (stud)
local PLATFORM_SIZE = Vector3.new(6, 0.2, 6)  -- ukuran lantai buatan

local function getFloorY(hrp)
    local params=RaycastParams.new()
    params.FilterDescendantsInstances={lp.Character}
    params.FilterType=Enum.RaycastFilterType.Exclude
    local res=workspace:Raycast(hrp.Position+Vector3.new(0,1,0),Vector3.new(0,-40,0),params)
    return res and res.Position.Y or nil
end

local function createPlatform(pos)
    -- Hapus platform lama kalau ada
    if ugPlatform and ugPlatform.Parent then ugPlatform:Destroy() end

    local part = Instance.new("Part")
    part.Name = "LH_UGPlatform"
    part.Size = PLATFORM_SIZE
    part.Anchored = true
    part.CanCollide = true
    part.CastShadow = false
    -- Transparan tapi tetap ada collision
    part.Transparency = 1
    part.Material = Enum.Material.SmoothPlastic
    part.Color = Color3.fromRGB(0,200,255)
    part.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
    part.Parent = workspace
    ugPlatform = part
    return part
end

local function destroyPlatform()
    if ugPlatform and ugPlatform.Parent then
        ugPlatform:Destroy()
        ugPlatform = nil
    end
end

local function startUnderground()
    local char=lp.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Cek ada lantai real di bawah atau tidak
    local floorY = getFloorY(hrp)
    local platformY

    if floorY then
        -- Ada lantai real → platform 8 stud di bawah lantai asli
        -- Karakter akan berdiri di platform = 8 stud di bawah permukaan
        platformY = floorY - 8
    else
        -- Void → buat platform 8 stud di bawah posisi karakter sekarang
        platformY = hrp.Position.Y - 8
        sendNotif("Underground","Void — platform buatan aktif")
    end

    -- Buat platform
    local platPos = Vector3.new(hrp.Position.X, platformY, hrp.Position.Z)
    createPlatform(platPos)

    -- Teleport karakter ke atas platform
    -- Platform ketebalan 0.2, karakter berdiri di Y = platformY + 0.1 + 3 (tinggi hrp ~3)
    local targetY = platformY + 0.1 + 3
    hrp.CFrame = CFrame.new(hrp.Position.X, targetY, hrp.Position.Z)
        * (hrp.CFrame - hrp.CFrame.Position)

    undergroundActive = true

    task.spawn(function()
        while undergroundActive and State.underground and ScreenGui.Parent do
            if hrp and hrp.Parent and ugPlatform and ugPlatform.Parent then
                -- Platform ikut X,Z karakter supaya tidak "ketinggalan" saat jalan
                ugPlatform.CFrame = CFrame.new(hrp.Position.X, platformY, hrp.Position.Z)
            end
            task.wait(0.05)
        end
    end)
end

local function stopUnderground()
    undergroundActive = false
    destroyPlatform()

    local char=lp.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Naik ke permukaan asli
    local floorY = getFloorY(hrp)
    if floorY then
        hrp.CFrame = CFrame.new(hrp.Position.X, floorY + 3.5, hrp.Position.Z)
            * (hrp.CFrame - hrp.CFrame.Position)
    else
        hrp.CFrame = hrp.CFrame * CFrame.new(0, SINK_DEPTH + 2, 0)
    end
end

undergroundBtn.MouseButton1Click:Connect(function()
    State.underground = not State.underground
    undergroundBtn.Text = "Underground : "..(State.underground and "ON" or "OFF")
    undergroundBtn.TextColor3 = State.underground and CFG.GREEN or CFG.CRIMSON
    if State.underground then startUnderground() else stopUnderground() end
end)
lp.CharacterAdded:Connect(function()
    destroyPlatform()
    if State.underground then task.wait(1); startUnderground() end
end)

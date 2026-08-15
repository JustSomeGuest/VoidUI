if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Shared = (type(getgenv) == "function" and getgenv()) or shared or _G

local function GetService(Service)
    local Service = game:GetService(Service)
    return cloneref and cloneref(Service) or Service
end

local Hui = gethui and gethui() or GetService("CoreGui")
local TweenService = GetService("TweenService")

local function Tween(Object, Speed, Props, Style, Dir)
    return TweenService:Create(
        Object,
        TweenInfo.new(
            Speed,
            Enum.EasingStyle[Style or "Quad"],
            Enum.EasingDirection[Dir or "Out"]
        ),
        Props
    )
end

local function UID(Length)
    Length = Length or 64

    local Chars = [[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~]]
    local Id = table.create(Length)

    for i = 1, Length do
        local Rand = math.random(1, #Chars)
        Id[i] = Chars:sub(Rand, Rand)
    end

    return table.concat(Id)
end

local function HttpGet(Url)
    local HttpGet = game.HttpGetAsync or game.HttpGet
    return loadstring(HttpGet(game, Url))()
end
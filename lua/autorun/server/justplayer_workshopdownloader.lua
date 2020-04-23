--[[
 A little more advanced Workshop collection "downloader"
 Created by JustPlayerDE ( https://steamcommunity.com/id/justplayerde/ )
]]
local CollectionQueue = {} -- Here we store "paused" collections to prevent errors from http api
local CollectionLoaded = {} -- To prevent a loop of endless addworkshopcollections (and spamming steam api)
local Wait = true

local function parseAddons(source)
    local source_ = string.Explode("<div class=\"workshopItem\">", source)
    local addons = {}

    -- Parsing Collection Page
    for k, v in pairs(source_) do
        local source__ = string.Explode("\"><div", v)
        local insert = string.Explode("id=", source__[1])[2]
        table.insert(addons, insert)
    end

    -- First one will be junk
    table.remove(addons, 1)

    return addons
end

local function parseCollections(source)
    local source_ = string.Explode("<div class=\"collectionChildren\">", source)[3] or ""
    local collections = {}

    for s in string.gmatch(source_, "id=[%d]+") do
        local id = string.sub(s, 4)

        if not table.HasValue(collections, id) then
            table.insert(collections, id)
        end
    end

    return collections
end

function resource.AddWorkshopCollection(collectionid)
    if collectionid == nil then return end
    if table.HasValue(CollectionLoaded, collectionid) then return end

    if Wait then
        table.insert(CollectionQueue, collectionid)
        print("[WORKSHOP] Queued Collection #" .. collectionid .. " for later.")

        return
    end

    -- Fetching Collection page
    http.Fetch("http://steamcommunity.com/sharedfiles/filedetails/?id=" .. collectionid, function(source)
        local addons = parseAddons(source)

        -- Clientside "Mounting" of Collection items
        for k, id in ipairs(addons) do
            resource.AddWorkshop(id)
        end

        if #addons > 0 then
            print("[WORKSHOP] Added Collection " .. collectionid .. " (" .. #addons .. " Addons) to Downloads.")
        end

        table.insert(CollectionLoaded, collectionid)

        if GetConVar("sv_addworkshopcollection_recursive"):GetBool() then
            local collections = parseCollections(source)

            for i, k in ipairs(collections) do
                resource.AddWorkshopCollection(k)
            end
        end
    end, function()
        error("Error while fetching collection #" .. collectionid)

        return false
    end)
end

-- usage: sv_addworkshopcollection <collection ids>
-- Example: sv_addworkshopcollection 1 2 3 4 (...)
concommand.Add("sv_addworkshopcollection", function(_, _, args)
    for k, id in ipairs(args) do
        resource.AddWorkshopCollection(id)
    end
end)

CreateConVar("sv_addworkshopcollection_recursive", 0, FCVAR_ARCHIVE, "Enables Recursive addWorkshopCollection")

-- We only Think once here (only then we can be sure that SteamHTTP is loaded)
hook.Add("Think", "AddWorkShopCollection:RunQueued", function()
    Wait = false
    hook.Remove("Think", "AddWorkShopCollection:RunQueued")
    print("[WORKSHOP] Running AddWorkshopCollection Queue..")

    for k, id in ipairs(CollectionQueue) do
        resource.AddWorkshopCollection(id)
    end

    -- "Empty Bin"
    CollectionQueue = nil
end)
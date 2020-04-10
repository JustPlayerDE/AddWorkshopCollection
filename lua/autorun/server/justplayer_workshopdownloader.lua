--[[
 A little more advanced Workshop collection "downloader"
 Created by JustPlayerDE ( https://steamcommunity.com/id/justplayerde/ )
]]
local CollectionQueue = {} -- Here we store "paused" collections to prevent errors from http api
local Wait = true

function resource.AddWorkshopCollection(collectionid)
    if collectionid == nil then return end

    if Wait then
        table.insert(CollectionQueue, collectionid)
        print("[WORKSHOP] Queued Collection #" .. collectionid .. " for later.")

        return
    end

    -- Fetching Collection page
    http.Fetch("http://steamcommunity.com/sharedfiles/filedetails/?id=" .. collectionid, function(source)
        local source_ = string.Explode("<div class=\"workshopItem\">", source)
        local t = {}

        -- Parsing Collection Page
        for k, v in pairs(source_) do
            local source__ = string.Explode("\"><div", v)
            local insert = string.Explode("id=", source__[1])[2]
            table.insert(t, insert)
        end

        -- First one will be junk
        table.remove(t, 1)

        -- Clientside "Mounting" of Collection items 
        for k, id in ipairs(t) do
            resource.AddWorkshop(id)
        end

        print("[WORKSHOP] Added Collection " .. collectionid .. " (" .. #t .. " Addons) to Downloads.")
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
--[[
 A little more advanced Workshop collection "downloader"
 Created by JustPlayerDE ( https://steamcommunity.com/id/justplayerde/ )

 Thanks to Tom.bat for pointing out that there is actually an API 
 And Thanks to Owain for helping me out with a more clean code :D
]]
local CollectionQueue = {} -- All collections are put here to wait for SteamHTTP starting up
local ADDON, COLLECTION = 0, 2

function resource.AddWorkshopCollection(...)
    local collectionIds = {...}
    local recursive = {}
    if collectionIds == nil then return end

    -- Thanks to Owain :) (ill put it here almost like he explained it so everyone can understand it)
    -- Check if the last argument is the recursive table
    if istable(collectionIds[#collectionIds]) then
        recursive = collectionIds[#collectionIds] -- Set the recursive table to the last argument
        collectionIds[#collectionIds] = nil -- Remove the recursive table from the ids list
    end

    local Collections = {}
    local Addons = {}
    if #collectionIds <= 0 then return end

    local POST = {
        ["collectioncount"] = tostring(#collectionIds)
    }

    for i = 0, #collectionIds - 1 do
        local ID = collectionIds[i + 1]
        -- We dont want invalid Workshop IDs here
        assert(tonumber(ID), "Invalid Workshop Collection id: " .. ID)
        POST["publishedfileids[" .. i .. "]"] = tostring(ID)
    end

    http.Post("https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/", POST, function(body, _, _, status)
        local json = util.JSONToTable(body)

        if status ~= 200 or not (json and json.response) then
            PrintTable(POST)
            error("Error while fetching collection data. Status: " .. status)
        end

        local CollectionData = json.response.collectiondetails or {}

        -- Going trough all Collection items
        for _, collection in ipairs(CollectionData) do
            local Items = collection.children or {}

            -- Adding them to either Collection or Addon table
            for i = 1, #Items do
                local Item = Items[i]

                if Item.filetype == ADDON then
                    table.insert(Addons, Item.publishedfileid)
                end

                if Item.filetype == COLLECTION then
                    -- Prevent adding already added collections
                    if table.HasValue(recursive, Item.publishedfileid) then

                        return
                    end

                    table.insert(recursive, Item.publishedfileid)
                    -- Otherwise add them to the collection list
                    table.insert(Collections, Item.publishedfileid)
                end
            end
        end

        -- Adding Workshop addons
        for k, id in ipairs(Addons) do
            resource.AddWorkshop(id)
        end

        if #Addons > 0 then
            print("[WORKSHOP] Added " .. #collectionIds .. " Collection(s) (Total " .. #Addons .. " Addons) to Downloads.")
        end

        -- Recursive AddWorkshopCollection
        if GetConVar("sv_addworkshopcollection_recursive"):GetBool() then
            for i, collectionid in ipairs(Collections) do
                resource.AddWorkshopCollection(collectionid, recursive)
            end
        end
    end, function(error)
        error("Error while fetching collection(s) " .. table.concat(collectionIds, ",") .. " Error: " .. error)

        return false
    end)
end

--resource.AddWorkshopCollection(1754190594)
--resource.AddWorkshopCollection({1754190594 , 1915277996})
-- usage: sv_addworkshopcollection <collection ids>
-- Example: sv_addworkshopcollection 1 2 3 4 (...)
concommand.Add("sv_addworkshopcollection", function(_, _, args)
    resource.AddWorkshopCollection(unpack(args))
end)

CreateConVar("sv_addworkshopcollection_recursive", 0, FCVAR_ARCHIVE, "Enables Recursive addWorkshopCollection")

-- As soon as the Think gets called SteamHTTP Should exists.
hook.Add("Think", "AddWorkShopCollection:RunQueued", function()
    hook.Remove("Think", "AddWorkShopCollection:RunQueued") -- To prevent running it more than once.
    print("[WORKSHOP] Running AddWorkshopCollection Queue..")
    local queue = CollectionQueue
    CollectionQueue = nil -- Disable Queue
    resource.AddWorkshopCollection(unpack(queue))
end)
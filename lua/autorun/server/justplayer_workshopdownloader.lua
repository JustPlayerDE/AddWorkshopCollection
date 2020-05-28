--[[
 A little more advanced Workshop collection "downloader"
 Created by JustPlayerDE ( https://steamcommunity.com/id/justplayerde/ )

 Thanks to Tom.bat for pointing out that there is actually an API 
]]
local CollectionQueue = {} -- All collections are put here to wait for SteamHTTP starting up
local ADDON, COLLECTION = 0, 2

function resource.AddWorkshopCollection(collectionIds, _recursiveprotection)
    if collectionIds == nil then return end
    _recursiveprotection = _recursiveprotection or {}
    local _Collections = {}
    local Collections = {}
    local Addons = {}

    if isstring(collectionIds) then
        collectionIds = tonumber(collectionIds)
    end

    if isnumber(collectionIds) then
        table.insert(_Collections, collectionIds)
    else
        _Collections = collectionIds
    end

    if #_Collections <= 0 then return end

    local POST = {
        ["collectioncount"] = tostring(#_Collections)
    }

    for i = 0, #_Collections - 1 do
        local ID = _Collections[i + 1]
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
                    if table.HasValue(_recursiveprotection, Item.publishedfileid) then return end
                    table.insert(_recursiveprotection, Item.publishedfileid)
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
            print("[WORKSHOP] Added " .. #_Collections .. " Collection(s) (Total " .. #Addons .. " Addons) to Downloads.")
        end

        -- Recursive AddWorkshopCollection
        if GetConVar("sv_addworkshopcollection_recursive"):GetBool() then
            for i, collectionid in ipairs(Collections) do
                resource.AddWorkshopCollection(collectionid, _recursiveprotection)
            end
        end
    end, function(error)
        error("Error while fetching collection(s) " .. table.concat(_Collections, ",") .. " Error: " .. error)

        return false
    end)
end

print("============")

--resource.AddWorkshopCollection(1754190594)
--resource.AddWorkshopCollection({1754190594 , 1915277996})
-- usage: sv_addworkshopcollection <collection ids>
-- Example: sv_addworkshopcollection 1 2 3 4 (...)
concommand.Add("sv_addworkshopcollection", function(_, _, args)
    resource.AddWorkshopCollection(args)
end)

CreateConVar("sv_addworkshopcollection_recursive", 0, FCVAR_ARCHIVE, "Enables Recursive addWorkshopCollection")

-- As soon as the Think gets called SteamHTTP Should exists.
hook.Add("Think", "AddWorkShopCollection:RunQueued", function()
    hook.Remove("Think", "AddWorkShopCollection:RunQueued") -- To prevent running it more than once.
    print("[WORKSHOP] Running AddWorkshopCollection Queue..")
    local queue = CollectionQueue
    CollectionQueue = nil -- Disable Queue
    resource.AddWorkshopCollection(queue)
end)
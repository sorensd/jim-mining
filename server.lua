-- TOP OF server.lua
local QBCore = rawget(_G, 'QBCore') or exports['qb-core']:GetCoreObject()

local function GetRandItemFromTable(table)
    debugPrint("^5Debug^7: ^2Picking random item from table^7")
    ::start::
    local randNum = math.random(1, 100)
    local items = {}
    for _, item in ipairs(table) do
        if randNum <= tonumber(item.rarity) then
            items[#items+1] = item.item
        end
    end
    if #items == 0 then
        goto start
    end
    local rand = math.random(1, #items)
    local selectedItem = items[rand]
    debugPrint("^5Debug^7: ^2Selected item ^7'^3"..selectedItem.."^7'")
    return selectedItem
end

-- Authoritative pre-check before starting any crafting progress
QBCore.Functions.CreateCallback(getScript()..":canCraft", function(src, cb, recipe)
    print(("[jim-mining] canCraft requested by %s"):format(src))
    if type(recipe) ~= "table" then cb(false, "invalid_recipe", 0) return end

    local ingredients
    for k, v in pairs(recipe) do
        if k ~= "amount" then ingredients = v break end
    end
    if type(ingredients) ~= "table" then cb(false, "invalid_ingredients", 0) return end

    for ing, amt in pairs(ingredients) do
        if ing ~= "amount" then
            if not hasItem(ing, amt, src) then
                print(("[jim-mining] canCraft FAIL (%s x%d)"):format(ing, amt))
                cb(false, ing, tonumber(amt) or 1)
                return
            end
        end
    end

    print("[jim-mining] canCraft OK")
    cb(true)
end)

-- New Crafting Event (iterate ingredients?not the root recipe table)
RegisterServerEvent(getScript()..":CraftItem")
AddEventHandler(getScript()..":CraftItem", function(data)
    local src = source
    local recipe = data and data.recipe
    if type(recipe) ~= "table" then return end

    local resultName, ingredients
    for k, v in pairs(recipe) do
        if k ~= "amount" then resultName, ingredients = k, v break end
    end
    if not resultName or type(ingredients) ~= "table" then return end

    print(("[jim-mining] CraftItem %s x%s by %s"):format(resultName, tostring(recipe.amount or 1), src))

    -- Check inputs
    for item, need in pairs(ingredients) do
        if item ~= "amount" then
            if not hasItem(item, need, src) then
                triggerNotify(nil, "Missing " .. item, "error", src)
                print(("[jim-mining] CraftItem FAIL missing %s x%d"):format(item, need))
                return
            end
        end
    end

    -- Remove inputs
    for item, need in pairs(ingredients) do
        if item ~= "amount" then
            removeItem(item, need, src)
        end
    end

    -- Give output
    local outCount = recipe.amount or 1
    addItem(resultName, outCount, nil, src)
    print(("[jim-mining] CraftItem DONE %s x%d"):format(resultName, outCount))
end)


-- Existing Reward Event (unchanged)
RegisterServerEvent(getScript()..":Reward", function(data)
    local src = source
    local amount = 1

    if data.mine then
        local amount = GetTiming(Config.PoolAmounts.Mining.AmountPerSuccess)
        local carryCheck = canCarry({ [data.setReward] = amount }, src)
        if carryCheck[data.setReward] then
            addItem(data.setReward, amount,  nil, src)
        else
            triggerNotify(nil, locale("error", "full"), "error", src)
        end

    elseif data.crack then
        local selectedItem = GetRandItemFromTable(Config.CrackPool)
        amount = GetTiming(Config.PoolAmounts.Cracking.AmountPerSuccess)
        local canCarryCheck = canCarry({ [selectedItem] = amount }, src)
        if selectedItem and canCarryCheck[selectedItem] then
            removeItem("stone", data.cost, src)
            addItem(selectedItem, amount, nil, src)
        else
            triggerNotify(nil, locale("error", "full"), "error", src)
        end

    elseif data.wash then
        local rewards = {}
        for i = 1, GetTiming(Config.PoolAmounts.Washing.Successes) do
            local selectedItem = GetRandItemFromTable(Config.WashPool)
            local amount = GetTiming(Config.PoolAmounts.Washing.AmountPerSuccess)
            if selectedItem then
                rewards[selectedItem] = (rewards[selectedItem] or 0) + amount
            end
        end
        local canCarryCheck = canCarry(rewards, src)
        local canCarryAll = true
        for item, _ in pairs(rewards) do
            if not canCarryCheck[item] then
                canCarryAll = false
                break
            end
        end
        if canCarryAll then
            removeItem("stone", data.cost, src)
            for item, amount in pairs(rewards) do
                addItem(item, amount, nil, src)
            end
        else
            triggerNotify(nil, locale("error", "full"), "error", src)
        end

    elseif data.pan then
        for i = 1, GetTiming(Config.PoolAmounts.Panning.Successes) do
            local selectedItem = GetRandItemFromTable(Config.PanPool)
            amount = GetTiming(Config.PoolAmounts.Panning.AmountPerSuccess)
            local canCarryCheck = canCarry({ [selectedItem] = amount }, src)
            if selectedItem and canCarryCheck[selectedItem] then
                addItem(selectedItem, amount, nil, src)
            else
                triggerNotify(nil, locale("error", "full"), "error", src)
            end
        end
    end
end)

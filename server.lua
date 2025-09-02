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

-- ✅ New Crafting Event
RegisterServerEvent(getScript()..":CraftItem", function(data)
    local src = source
    local result = data.result
    local recipe = data.recipe
    if not result or not recipe then return end

    -- check ingredients
    for ingredient, amount in pairs(recipe) do
        if ingredient ~= "amount" then
            if not hasItem(ingredient, amount, src) then
                triggerNotify(nil, "Missing " .. ingredient, "error", src)
                return
            end
        end
    end

    -- remove inputs
    for ingredient, amount in pairs(recipe) do
        if ingredient ~= "amount" then
            removeItem(ingredient, amount, src)
        end
    end

    -- give result
    local count = recipe.amount or 1
    addItem(result, count, nil, src)
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

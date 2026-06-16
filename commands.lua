local function chat(pname, msg)
    minetest.chat_send_player(pname, "[PieMart] " .. msg)
end

minetest.register_chatcommand("bal", {
    description = "Show your PieCoin balance",
    func = function(pname, param)
        local player = minetest.get_player_by_name(pname)
        if not player then return false, "Player not found." end
        piemart.gui.show_balance(pname)
        return true
    end,
})

minetest.register_chatcommand("market", {
    params = "<market_name>",
    description = "Open a specific market to browse and buy items",
    func = function(pname, param)
        local market_name = param:match("^%s*(%S+)%s*$")
        if not market_name then
            return false, "Usage: /market <market_name>"
        end
        local market = piemart.storage.get_market(market_name)
        if not market then
            return false, "Market '" .. market_name .. "' does not exist. Use /market_list to browse."
        end
        piemart.gui.show_market(pname, market_name, 1)
        return true
    end,
})

minetest.register_chatcommand("market_list", {
    description = "Browse all markets with search",
    func = function(pname, param)
        piemart.gui.show_market_list(pname, "", 1)
        return true
    end,
})

minetest.register_chatcommand("pm_i", {
    params = "<account> <market_name>",
    description = "List the item you're holding in a market. Sale proceeds go to <account>.",
    func = function(pname, param)
        local account, market_name = param:match("^%s*(%S+)%s+(%S+)%s*$")
        if not account or not market_name then
            return false, "Usage: /pm_i <account> <market_name>"
        end

        -- Validate account exists (or allow self-account)
        if account ~= pname then
            if #account < 1 then
                return false, "Invalid account name."
            end
        end

        piemart.economy.list_item(pname, account, market_name)
        return true
    end,
})

minetest.register_chatcommand("host_market", {
    params = "<market_name> <description>",
    description = "Create and host your own market (costs PieCoins)",
    func = function(pname, param)
        local market_name, description = param:match("^%s*(%S+)%s+(.+)$")
        if not market_name then
            market_name = param:match("^%s*(%S+)%s*$")
            description = "A market by " .. pname
        end
        if not market_name then
            return false, "Usage: /host_market <market_name> <description>"
        end
        piemart.economy.host_market(pname, market_name, description)
        return true
    end,
})

minetest.register_chatcommand("del_mar", {
    params = "<market_name>",
    description = "Delete a market you own (returns all listed items to sellers)",
    func = function(pname, param)
        local market_name = param:match("^%s*(%S+)%s*$")
        if not market_name then
            return false, "Usage: /del_mar <market_name>"
        end
        piemart.economy.delete_market(pname, market_name)
        return true
    end,
})

minetest.register_chatcommand("exchange", {
    description = "Open the exchange shop to convert PieCoins into items",
    func = function(pname, param)
        piemart.gui.show_exchange(pname)
        return true
    end,
})

minetest.register_chatcommand("set_value", {
    params = "<coins_value> <item_name>",
    description = "[ADMIN] Set exchange rate: <coins_value> coins = 1 <item_name>",
    privs = { piemart_admin = true },
    func = function(pname, param)
        local value_str, item_name = param:match("^%s*(%S+)%s+(%S+)%s*$")
        if not value_str or not item_name then
            return false, "Usage: /set_value <coins_value> <item_name>"
        end
        local value = tonumber(value_str)
        if not value or value < 1 then
            return false, "Value must be a positive number."
        end

        if not minetest.registered_items[item_name] then
            chat(pname, "Warning: '" .. item_name .. "' is not a registered item.")
        end

        piemart.storage.set_exchange_rate(item_name, math.floor(value))
        chat(pname, "Exchange rate set: " .. math.floor(value) .. " coins = 1x " .. item_name)
        return true
    end,
})

minetest.register_chatcommand("set_mar_op", {
    params = "<amount>",
    description = "[ADMIN] Set the PieCoin cost to open a new market",
    privs = { piemart_admin = true },
    func = function(pname, param)
        local amount_str = param:match("^%s*(%S+)%s*$")
        if not amount_str then
            return false, "Usage: /set_mar_op <amount>"
        end
        local amount = tonumber(amount_str)
        if not amount or amount < 0 then
            return false, "Amount must be a non-negative number."
        end
        piemart.storage.set_market_open_price(math.floor(amount))
        chat(pname, "Market opening cost set to " .. piemart.format_coins(math.floor(amount)) .. ".")
        return true
    end,
})

minetest.register_chatcommand("give_coins", {
    params = "<player> <amount>",
    description = "[ADMIN] Give PieCoins to a player",
    privs = { piemart_admin = true },
    func = function(pname, param)
        local target, amount_str = param:match("^%s*(%S+)%s+(%S+)%s*$")
        if not target or not amount_str then
            return false, "Usage: /give_coins <player> <amount>"
        end
        local amount = tonumber(amount_str)
        if not amount or amount < 1 then
            return false, "Amount must be a positive number."
        end
        piemart.storage.add_balance(target, math.floor(amount))
        local new_bal = piemart.storage.get_balance(target)
        chat(pname, "Gave " .. piemart.format_coins(math.floor(amount)) ..
             " to " .. target .. ". Their new balance: " .. piemart.format_coins(new_bal))
        local tp = minetest.get_player_by_name(target)
        if tp then
            chat(target, "You received " .. piemart.format_coins(math.floor(amount)) ..
                 " from admin " .. pname .. ". Balance: " .. piemart.format_coins(new_bal))
        end
        return true
    end,
})

minetest.register_chatcommand("take_coins", {
    params = "<player> <amount>",
    description = "[ADMIN] Remove PieCoins from a player",
    privs = { piemart_admin = true },
    func = function(pname, param)
        local target, amount_str = param:match("^%s*(%S+)%s+(%S+)%s*$")
        if not target or not amount_str then
            return false, "Usage: /take_coins <player> <amount>"
        end
        local amount = tonumber(amount_str)
        if not amount or amount < 1 then
            return false, "Amount must be a positive number."
        end
        local success = piemart.storage.subtract_balance(target, math.floor(amount))
        if not success then
            local bal = piemart.storage.get_balance(target)
            return false, target .. " only has " .. piemart.format_coins(bal) .. "."
        end
        chat(pname, "Took " .. piemart.format_coins(math.floor(amount)) .. " from " .. target)
        return true
    end,
})

minetest.register_chatcommand("pm_info", {
    params = "<market_name>",
    description = "[ADMIN] View detailed info about a market",
    privs = { piemart_admin = true },
    func = function(pname, param)
        local mname = param:match("^%s*(%S+)%s*$")
        if not mname then return false, "Usage: /pm_info <market_name>" end
        local market = piemart.storage.get_market(mname)
        if not market then return false, "Market not found." end
        chat(pname, "=== Market: " .. mname .. " ===")
        chat(pname, "Owner: " .. market.owner)
        chat(pname, "Description: " .. (market.description or ""))
        chat(pname, "Listings: " .. #(market.items or {}))
        return true
    end,
})

minetest.register_chatcommand("pm_bal", {
    params = "<player>",
    description = "[ADMIN] Check a player's PieCoin balance",
    privs = { piemart_admin = true },
    func = function(pname, param)
        local target = param:match("^%s*(%S+)%s*$")
        if not target then return false, "Usage: /pm_bal <player>" end
        local bal = piemart.storage.get_balance(target)
        chat(pname, target .. "'s balance: " .. piemart.format_coins(bal))
        return true
    end,
})

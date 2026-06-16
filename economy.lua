piemart.economy = {}

local function chat(pname, msg)
    minetest.chat_send_player(pname, "[PieMart] " .. msg)
end

function piemart.economy.list_item(seller, account, market_name)
    local market = piemart.storage.get_market(market_name)
    if not market then
        chat(seller, "Market '" .. market_name .. "' does not exist.")
        return
    end

    local player = minetest.get_player_by_name(seller)
    if not player then return end

    local inv = player:get_inventory()
    local wield = player:get_wielded_item()
    if wield:is_empty() then
        chat(seller, "Hold the item you want to list in your hand.")
        return
    end

    chat(seller, "Type the price in PieCoins for " .. wield:get_name() ..
         " x" .. wield:get_count() .. " (type 'cancel' to abort):")

    piemart.economy._pending_list[seller] = {
        account   = account,
        market    = market_name,
        item_name = wield:get_name(),
        item_count= wield:get_count(),
        stack     = wield:to_string(),
    }
end

piemart.economy._pending_list = {}

minetest.register_on_chat_message(function(pname, msg)
    local pending = piemart.economy._pending_list[pname]
    if not pending then return false end

    if msg:lower() == "cancel" then
        piemart.economy._pending_list[pname] = nil
        chat(pname, "Listing cancelled.")
        return true
    end

    local price = tonumber(msg)
    if not price or price < 1 then
        chat(pname, "Invalid price. Enter a positive number or 'cancel'.")
        return true
    end
    price = math.floor(price)

    local player = minetest.get_player_by_name(pname)
    if not player then
        piemart.economy._pending_list[pname] = nil
        return true
    end
    local wield = player:get_wielded_item()
    if wield:get_name() ~= pending.item_name then
        chat(pname, "The item in your hand changed! Listing cancelled.")
        piemart.economy._pending_list[pname] = nil
        return true
    end

    player:set_wielded_item(ItemStack(""))

    local listing = {
        seller     = pending.account,
        lister     = pname,
        item_name  = pending.item_name,
        item_count = pending.item_count,
        price      = price,
        stack      = pending.stack,
        listed_at  = os.time(),
    }

    local lid = piemart.storage.add_listing(pending.market, listing)
    piemart.economy._pending_list[pname] = nil

    if lid then
        chat(pname, "Listed " .. pending.item_count .. "x " .. pending.item_name ..
             " for " .. piemart.format_coins(price) .. " in market '" .. pending.market .. "'.")
        chat(pname, "Listing ID: " .. lid)
    else
        chat(pname, "Failed to list item.")
        local inv = player:get_inventory()
        inv:add_item("main", ItemStack(pending.stack))
    end

    return true
end)

function piemart.economy.buy_item(buyer, market_name, listing_id)
    local market = piemart.storage.get_market(market_name)
    if not market then
        chat(buyer, "Market not found.")
        return
    end

    local listing = nil
    for _, item in ipairs(market.items or {}) do
        if item.id == listing_id then
            listing = item
            break
        end
    end

    if not listing then
        chat(buyer, "Listing no longer available.")
        piemart.gui.show_market(buyer, market_name)
        return
    end

    if listing.seller == buyer or listing.lister == buyer then
        chat(buyer, "You cannot buy your own listing.")
        return
    end

    local bal = piemart.storage.get_balance(buyer)
    if bal < listing.price then
        chat(buyer, "Not enough PieCoins. You need " .. listing.price .. " but have " ..
             piemart.format_coins(bal) .. ".")
        return
    end

    local player = minetest.get_player_by_name(buyer)
    if not player then return end
    local inv = player:get_inventory()
    local stack = ItemStack(listing.stack)
    if not inv:room_for_item("main", stack) then
        chat(buyer, "Not enough inventory space.")
        return
    end

    piemart.storage.subtract_balance(buyer, listing.price)
    piemart.storage.add_balance(listing.seller, listing.price)
    piemart.storage.remove_listing(market_name, listing_id)
    inv:add_item("main", stack)

    chat(buyer, "Bought " .. listing.item_count .. "x " .. listing.item_name ..
         " for " .. piemart.format_coins(listing.price) .. "!")

    local seller_player = minetest.get_player_by_name(listing.seller)
    if seller_player then
        chat(listing.seller, buyer .. " bought your " .. listing.item_count ..
             "x " .. listing.item_name .. " for " .. piemart.format_coins(listing.price) .. "!")
    end

    piemart.gui.show_market(buyer, market_name)
end─

function piemart.economy.do_exchange(pname, item_name, qty, rates)
    local coins_per_item = rates[item_name]
    if not coins_per_item then
        chat(pname, "Invalid exchange item.")
        return
    end

    local total_cost = coins_per_item * qty
    local bal = piemart.storage.get_balance(pname)
    if bal < total_cost then
        chat(pname, "Not enough PieCoins. Need " .. piemart.format_coins(total_cost) ..
             " but have " .. piemart.format_coins(bal) .. ".")
        return
    end

    local player = minetest.get_player_by_name(pname)
    if not player then return end
    local inv = player:get_inventory()
    local stack = ItemStack({ name = item_name, count = qty })
    if not inv:room_for_item("main", stack) then
        chat(pname, "Not enough inventory space for " .. qty .. "x " .. item_name .. ".")
        return
    end

    piemart.storage.subtract_balance(pname, total_cost)
    inv:add_item("main", stack)

    chat(pname, "Exchanged " .. piemart.format_coins(total_cost) .. " → " ..
         qty .. "x " .. item_name .. ".")

    piemart.gui.show_exchange(pname)
end

function piemart.economy.host_market(pname, market_name, description)
    if market_name:find("[^%w_%-]") then
        chat(pname, "Market name can only contain letters, numbers, _ and -.")
        return
    end
    if #market_name > 32 then
        chat(pname, "Market name too long (max 32 chars).")
        return
    end
    if piemart.storage.get_market(market_name) then
        chat(pname, "Market '" .. market_name .. "' already exists.")
        return
    end

    local is_admin = piemart.is_admin(pname)
    local limit = piemart.config.max_markets_per_player

    if not is_admin then
        local count = piemart.storage.count_player_markets(pname)
        if count >= limit then
            chat(pname, "You have reached the maximum of " .. limit .. " markets.")
            return
        end
    else
        local count = piemart.storage.count_player_markets(pname)
        if count >= limit then
            chat(pname, "Even admins are limited to " .. limit .. " markets.")
            return
        end
    end

    local price = piemart.storage.get_market_open_price()
    if not piemart.storage.subtract_balance(pname, price) then
        chat(pname, "Not enough PieCoins to open a market. Cost: " .. piemart.format_coins(price))
        return
    end

    piemart.storage.set_market(market_name, {
        owner       = pname,
        description = description or "A market by " .. pname,
        items       = {},
        created_at  = os.time(),
    })

    chat(pname, "Market '" .. market_name .. "' created! Cost: " ..
         piemart.format_coins(price) .. ".")
end

function piemart.economy.delete_market(pname, market_name)
    local market = piemart.storage.get_market(market_name)
    if not market then
        chat(pname, "Market '" .. market_name .. "' not found.")
        return
    end

    local is_admin = piemart.is_admin(pname)
    if market.owner ~= pname and not is_admin then
        chat(pname, "You are not the owner of '" .. market_name .. "'.")
        return
    end

    local items = market.items or {}
    for _, listing in ipairs(items) do
        local lister = listing.lister or listing.seller
        local lp = minetest.get_player_by_name(lister)
        if lp then
            local inv = lp:get_inventory()
            inv:add_item("main", ItemStack(listing.stack))
            chat(lister, "Your listing in market '" .. market_name ..
                 "' was returned: " .. listing.item_count .. "x " .. listing.item_name)
        else
            minetest.log("action", "[PieMart] Unclaimed item from deleted market: " ..
                listing.item_name .. " x" .. listing.item_count .. " (seller: " .. lister .. ")")
        end
    end

    piemart.storage.delete_market(market_name)
    chat(pname, "Market '" .. market_name .. "' has been deleted.")
end

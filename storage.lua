local storage = minetest.get_mod_storage()

piemart.storage = {}

local function save_table(key, tbl)
    storage:set_string(key, minetest.serialize(tbl))
end

local function load_table(key, default)
    local raw = storage:get_string(key)
    if raw and raw ~= "" then
        return minetest.deserialize(raw) or default
    end
    return default
end

function piemart.storage.get_balance(player_name)
    return storage:get_int("bal_" .. player_name)
end

function piemart.storage.set_balance(player_name, amount)
    storage:set_int("bal_" .. player_name, math.max(0, math.floor(amount)))
end

function piemart.storage.add_balance(player_name, amount)
    local bal = piemart.storage.get_balance(player_name)
    piemart.storage.set_balance(player_name, bal + amount)
end

function piemart.storage.subtract_balance(player_name, amount)
    local bal = piemart.storage.get_balance(player_name)
    if bal < amount then return false end
    piemart.storage.set_balance(player_name, bal - amount)
    return true
end

function piemart.storage.get_markets()
    return load_table("markets", {})
end

function piemart.storage.save_markets(markets)
    save_table("markets", markets)
end

function piemart.storage.get_market(name)
    local markets = piemart.storage.get_markets()
    return markets[name]
end

function piemart.storage.set_market(name, data)
    local markets = piemart.storage.get_markets()
    markets[name] = data
    piemart.storage.save_markets(markets)
end

function piemart.storage.delete_market(name)
    local markets = piemart.storage.get_markets()
    markets[name] = nil
    piemart.storage.save_markets(markets)
end

function piemart.storage.count_player_markets(player_name)
    local markets = piemart.storage.get_markets()
    local count = 0
    for _, market in pairs(markets) do
        if market.owner == player_name then
            count = count + 1
        end
    end
    return count
end

function piemart.storage.get_exchange_rates()
    return load_table("exchange_rates", {})
end

function piemart.storage.set_exchange_rate(item_name, value)
    local rates = piemart.storage.get_exchange_rates()
    rates[item_name] = value
    save_table("exchange_rates", rates)
end

function piemart.storage.get_market_open_price()
    local v = storage:get_int("market_open_price")
    return (v and v > 0) and v or piemart.config.default_market_price
end

function piemart.storage.set_market_open_price(amount)
    storage:set_int("market_open_price", amount)
end

function piemart.storage.add_listing(market_name, listing)
    local market = piemart.storage.get_market(market_name)
    if not market then return false end
    listing.id = os.time() .. "_" .. math.random(100000)
    table.insert(market.items, listing)
    piemart.storage.set_market(market_name, market)
    return listing.id
end

function piemart.storage.remove_listing(market_name, listing_id)
    local market = piemart.storage.get_market(market_name)
    if not market then return false end
    for i, item in ipairs(market.items) do
        if item.id == listing_id then
            table.remove(market.items, i)
            piemart.storage.set_market(market_name, market)
            return item
        end
    end
    return false
end

function piemart.storage.get_listings(market_name)
    local market = piemart.storage.get_market(market_name)
    if not market then return {} end
    return market.items or {}
end

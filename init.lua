piemart = {}

piemart.config = {
    max_markets_per_player = 5,
    default_market_price = 1500,
    default_exchange_rates = {
        ["default:diamond"] = 10,
    },

    starting_balance = 500,
}

minetest.register_privilege("piemart_admin", {
    description = "Full PieMart admin privileges (give/take coins, set rates, delete any market)",
    give_to_singleplayer = true,
})

function piemart.is_admin(pname)
    return minetest.check_player_privs(pname, { piemart_admin = true }) or
           minetest.check_player_privs(pname, { server = true })
end

function piemart.format_coins(amount)
    local s = tostring(math.floor(amount or 0))
    local result = ""
    local len = #s
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then
            result = result .. ","
        end
        result = result .. s:sub(i, i)
    end
    return result .. " ¢"
end

local modpath = minetest.get_modpath("piemart")

dofile(modpath .. "/storage.lua")
dofile(modpath .. "/economy.lua")
dofile(modpath .. "/gui.lua")
dofile(modpath .. "/commands.lua")

local storage = minetest.get_mod_storage()
if not storage:get_string("initialized") or storage:get_string("initialized") == "" then
    for item_name, value in pairs(piemart.config.default_exchange_rates) do
        piemart.storage.set_exchange_rate(item_name, value)
    end
    storage:set_string("initialized", "true")
    minetest.log("action", "[PieMart] First-run initialisation complete.")
end

minetest.register_on_newplayer(function(player)
    local pname = player:get_player_name()
    local bal = piemart.storage.get_balance(pname)
    if bal == 0 then
        piemart.storage.set_balance(pname, piemart.config.starting_balance)
        minetest.after(2, function()
            local p = minetest.get_player_by_name(pname)
            if p then
                minetest.chat_send_player(pname,
                    minetest.colorize("#f5a623",
                        "[PieMart] Welcome! You've been given " ..
                        piemart.format_coins(piemart.config.starting_balance) ..
                        " PieCoins to start with. Type /market_list to browse markets!"))
            end
        end)
    end
end)

minetest.log("action", "[PieMart] Loaded. Max markets/player: " ..
    piemart.config.max_markets_per_player ..
    " | Default market price: " .. piemart.config.default_market_price)

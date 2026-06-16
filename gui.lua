
piemart.gui = {}

local C = {
    bg      = "#1a1a2e",
    panel   = "#16213e",
    accent  = "#e94560",
    gold    = "#f5a623",
    text    = "#eaeaea",
    muted   = "#888888",
    green   = "#27ae60",
    red     = "#c0392b",
    border  = "#0f3460",
}

local function color(hex, text)
    return minetest.colorize(hex, text)
end

local function header(title, w, h)
    return  "formspec_version[4]" ..
            "size[" .. w .. "," .. h .. "]" ..
            "bgcolor[" .. C.bg .. ";both]" ..
            "box[0,0;" .. w .. ",0.8;" .. C.panel .. "]" ..
            "label[0.3,0.45;" .. color(C.gold, "⬡ PieMart  ") .. color(C.text, "— " .. title) .. "]"
end

function piemart.gui.show_balance(player_name)
    local bal = piemart.storage.get_balance(player_name)
    local fs = header("Balance", 6, 3.5) ..
        "box[0.3,1.0;5.4,1.8;" .. C.panel .. "]" ..
        "label[0.6,1.5;" .. color(C.muted, "Your PieCoin Balance") .. "]" ..
        "label[0.6,2.1;" .. color(C.gold, "✦ " .. piemart.format_coins(bal)) .. "]" ..
        "button_exit[2.0,2.9;2.0,0.6;close;" .. color(C.text, "Close") .. "]"
    minetest.show_formspec(player_name, "piemart:balance", fs)
end

function piemart.gui.show_market(player_name, market_name, page)
    page = page or 1
    local market = piemart.storage.get_market(market_name)
    if not market then
        minetest.chat_send_player(player_name, "[PieMart] Market not found.")
        return
    end

    local items = market.items or {}
    local per_page = 6
    local total_pages = math.max(1, math.ceil(#items / per_page))
    page = math.min(page, total_pages)

    local fs = header("Market: " .. market_name, 12, 10) ..
        "box[0.3,1.0;11.4,0.7;" .. C.border .. "]" ..
        "label[0.5,1.38;" .. color(C.muted, "Owner: ") .. color(C.text, market.owner) ..
            "   " .. color(C.muted, market.description) .. "]" ..
        "box[0.3,1.85;11.4,0.5;" .. C.panel .. "]" ..
        "label[0.5,2.13;" .. color(C.muted, "Item") .. "]" ..
        "label[4.5,2.13;" .. color(C.muted, "Qty") .. "]" ..
        "label[5.5,2.13;" .. color(C.muted, "Price (¢)") .. "]" ..
        "label[7.0,2.13;" .. color(C.muted, "Seller") .. "]" ..
        "label[9.5,2.13;" .. color(C.muted, "Action") .. "]"

    local start_i = (page - 1) * per_page + 1
    local y = 2.5

    for i = start_i, math.min(start_i + per_page - 1, #items) do
        local item = items[i]
        local row_bg = (i % 2 == 0) and C.panel or C.bg
        fs = fs ..
            "box[0.3," .. y .. ";11.4,0.65;" .. row_bg .. "]" ..
            "label[0.5," .. (y + 0.35) .. ";" .. color(C.text, item.item_name) .. "]" ..
            "label[4.5," .. (y + 0.35) .. ";" .. color(C.text, tostring(item.item_count)) .. "]" ..
            "label[5.5," .. (y + 0.35) .. ";" .. color(C.gold, tostring(item.price)) .. "]" ..
            "label[7.0," .. (y + 0.35) .. ";" .. color(C.muted, item.seller) .. "]" ..
            "button[9.3," .. (y + 0.08) .. ";2.0,0.5;buy_" .. item.id .. ";" ..
                color(C.text, "Buy") .. "]"
        y = y + 0.7
    end
    
    fs = fs ..
        "box[0.3,8.6;11.4,0.5;" .. C.panel .. "]" ..
        "label[5.2,8.88;" .. color(C.muted, "Page " .. page .. " / " .. total_pages) .. "]"

    if page > 1 then
        fs = fs .. "button[0.5,8.65;1.5,0.4;prev_page;◀ Prev]"
    end
    if page < total_pages then
        fs = fs .. "button[10.0,8.65;1.5,0.4;next_page;Next ▶]"
    end

    fs = fs ..
        "button[0.3,9.3;3.0,0.6;back_list;" .. color(C.text, "◀ Market List") .. "]" ..
        "button_exit[9.0,9.3;3.0,0.6;close;" .. color(C.text, "Close") .. "]"

    piemart.gui._context[player_name] = { market_name = market_name, page = page }
    minetest.show_formspec(player_name, "piemart:market", fs)
end

function piemart.gui.show_market_list(player_name, filter, page)
    filter = filter or ""
    page = page or 1

    local markets = piemart.storage.get_markets()
    local filtered = {}
    for name, data in pairs(markets) do
        local search = (name .. data.owner .. (data.description or "")):lower()
        if filter == "" or search:find(filter:lower(), 1, true) then
            table.insert(filtered, { name = name, data = data })
        end
    end
    table.sort(filtered, function(a, b) return a.name < b.name end)

    local per_page = 7
    local total_pages = math.max(1, math.ceil(#filtered / per_page))
    page = math.min(page, total_pages)

    local fs = header("Market List", 12, 10) ..
        -- Search bar
        "box[0.3,1.0;11.4,0.7;" .. C.panel .. "]" ..
        "label[0.5,1.15;" .. color(C.muted, "Search:") .. "]" ..
        "field[1.5,1.05;8.5,0.55;search_field;;" .. minetest.formspec_escape(filter) .. "]" ..
        "button[10.1,1.0;1.5,0.65;do_search;" .. color(C.text, "🔍") .. "]" ..
        "box[0.3,1.85;11.4,0.5;" .. C.panel .. "]" ..
        "label[0.5,2.13;" .. color(C.muted, "Market Name") .. "]" ..
        "label[3.5,2.13;" .. color(C.muted, "Owner") .. "]" ..
        "label[6.0,2.13;" .. color(C.muted, "Description") .. "]" ..
        "label[10.0,2.13;" .. color(C.muted, "Open") .. "]"

    local start_i = (page - 1) * per_page + 1
    local y = 2.5
    for i = start_i, math.min(start_i + per_page - 1, #filtered) do
        local entry = filtered[i]
        local row_bg = (i % 2 == 0) and C.panel or C.bg
        local desc = entry.data.description or ""
        if #desc > 28 then desc = desc:sub(1, 25) .. "..." end
        fs = fs ..
            "box[0.3," .. y .. ";11.4,0.65;" .. row_bg .. "]" ..
            "label[0.5," .. (y + 0.35) .. ";" .. color(C.gold, entry.name) .. "]" ..
            "label[3.5," .. (y + 0.35) .. ";" .. color(C.muted, entry.data.owner) .. "]" ..
            "label[6.0," .. (y + 0.35) .. ";" .. color(C.text, desc) .. "]" ..
            "button[9.8," .. (y + 0.08) .. ";2.0,0.5;open_" .. minetest.formspec_escape(entry.name) ..
                ";" .. color(C.text, "Open") .. "]"
        y = y + 0.7
    end

    -- Pagination
    fs = fs ..
        "box[0.3,8.6;11.4,0.5;" .. C.panel .. "]" ..
        "label[5.2,8.88;" .. color(C.muted, "Page " .. page .. " / " .. total_pages) .. "]"
    if page > 1 then
        fs = fs .. "button[0.5,8.65;1.5,0.4;prev_page;◀ Prev]"
    end
    if page < total_pages then
        fs = fs .. "button[10.0,8.65;1.5,0.4;next_page;Next ▶]"
    end

    fs = fs .. "button_exit[9.0,9.3;3.0,0.6;close;" .. color(C.text, "Close") .. "]"

    piemart.gui._context[player_name] = { filter = filter, page = page, view = "list" }
    minetest.show_formspec(player_name, "piemart:market_list", fs)
end

function piemart.gui.show_exchange(player_name)
    local rates = piemart.storage.get_exchange_rates()
    local bal = piemart.storage.get_balance(player_name)

    local fs = header("Exchange Shop", 12, 10) ..
        "box[0.3,1.0;11.4,0.6;" .. C.panel .. "]" ..
        "label[0.5,1.33;" .. color(C.muted, "Balance: ") .. color(C.gold, "✦ " .. piemart.format_coins(bal)) .. "]" ..
        "box[0.3,1.75;11.4,0.5;" .. C.panel .. "]" ..
        "label[0.5,2.03;" .. color(C.muted, "Item") .. "]" ..
        "label[4.0,2.03;" .. color(C.muted, "Rate (coins → item)") .. "]" ..
        "label[8.0,2.03;" .. color(C.muted, "Qty to buy") .. "]" ..
        "label[10.0,2.03;" .. color(C.muted, "Action") .. "]"

    local y = 2.4
    local idx = 0
    if next(rates) == nil then
        fs = fs .. "label[4.0,4.5;" .. color(C.muted, "No exchange rates set by admin yet.") .. "]"
    else
        for item_name, coins_per_item in pairs(rates) do
            idx = idx + 1
            local row_bg = (idx % 2 == 0) and C.panel or C.bg
            fs = fs ..
                "box[0.3," .. y .. ";11.4,0.65;" .. row_bg .. "]" ..
                "label[0.5," .. (y + 0.35) .. ";" .. color(C.text, item_name) .. "]" ..
                "label[4.0," .. (y + 0.35) .. ";" ..
                    color(C.gold, coins_per_item .. " ¢") ..
                    color(C.muted, " = 1 item") .. "]" ..
                "field[7.8," .. (y + 0.08) .. ";2.0,0.5;qty_" .. idx .. ";;1]" ..
                "button[10.0," .. (y + 0.08) .. ";1.7,0.5;exchange_" .. minetest.formspec_escape(item_name) ..
                    "_" .. idx .. ";" .. color(C.text, "Buy") .. "]"
            y = y + 0.7
            if y > 8.0 then break end
        end
    end

    fs = fs .. "button_exit[9.0,9.3;3.0,0.6;close;" .. color(C.text, "Close") .. "]"

    piemart.gui._exchange_context[player_name] = rates
    minetest.show_formspec(player_name, "piemart:exchange", fs)
end

piemart.gui._context = {}
piemart.gui._exchange_context = {}

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local pname = player:get_player_name()

    if formname == "piemart:market_list" then
        local ctx = piemart.gui._context[pname] or {}

        if fields.do_search then
            piemart.gui.show_market_list(pname, fields.search_field or "", 1)
            return true
        end
        if fields.prev_page then
            piemart.gui.show_market_list(pname, ctx.filter, (ctx.page or 2) - 1)
            return true
        end
        if fields.next_page then
            piemart.gui.show_market_list(pname, ctx.filter, (ctx.page or 1) + 1)
            return true
        end

        for field, _ in pairs(fields) do
            local mname = field:match("^open_(.+)$")
            if mname then
                piemart.gui.show_market(pname, mname, 1)
                return true
            end
        end

    elseif formname == "piemart:market" then
        local ctx = piemart.gui._context[pname] or {}
        local mname = ctx.market_name
        local page = ctx.page or 1

        if fields.back_list then
            piemart.gui.show_market_list(pname)
            return true
        end
        if fields.prev_page then
            piemart.gui.show_market(pname, mname, page - 1)
            return true
        end
        if fields.next_page then
            piemart.gui.show_market(pname, mname, page + 1)
            return true
        end

        for field, _ in pairs(fields) do
            local lid = field:match("^buy_(.+)$")
            if lid then
                piemart.economy.buy_item(pname, mname, lid)
                return true
            end
        end

    elseif formname == "piemart:exchange" then
        local rates = piemart.gui._exchange_context[pname] or {}

        for field, _ in pairs(fields) do
            local item_enc, idx_str = field:match("^exchange_(.+)_(%d+)$")
            if item_enc then
                local qty_raw = fields["qty_" .. idx_str] or "1"
                local qty = tonumber(qty_raw) or 1
                qty = math.floor(math.max(1, qty))
                piemart.economy.do_exchange(pname, item_enc, qty, rates)
                return true
            end
        end
    end
end)

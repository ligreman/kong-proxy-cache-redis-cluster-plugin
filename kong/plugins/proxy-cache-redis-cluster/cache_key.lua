local fmt = string.format
local ipairs = ipairs
local md5 = ngx.md5
local type = type
local pairs = pairs
local sort = table.sort
local insert = table.insert
local concat = table.concat

local _M = {}

local EMPTY = {}

local function keys(t)
    local res = {}
    for k, _ in pairs(t) do
        res[#res + 1] = k
    end

    return res
end

-- Flattens a JSON object converted to lua table
local function flatten(item, result, key)
    local result = result or {}  --  create empty table, if none given during initialization
    local key = key or ""

    if type( item ) == 'table' then
        for k, v in pairs( item ) do
            if type(k) == 'number' then
                flatten(v, result, key)
            else
                flatten(v, result, key .. k)
            end
        end
    else
        result[ #result +1 ] = key .. tostring(item)
    end
    return result
end

-- Return a string with the format "key=value(:key=value)*" of the
-- actual keys and values in args that are in vary_fields.
--
-- The elements are sorted so we get consistent cache actual_keys no matter
-- the order in which params came in the request
--
-- is_json: boolean that indicates that args are a JSON object (converted into a lua table)
local function generate_key_from(args, vary_fields, is_json)
    local cache_key = {}

    for _, field in ipairs(vary_fields or {}) do
        local arg = args[field]
        if arg then
            if is_json == true and type(arg) == "table" then
                local newTable = flatten(arg)
                sort(newTable)
                insert(cache_key, field .. "=" .. concat(newTable, ";"))

            elseif type(arg) == "table" then
                sort(arg)
                insert(cache_key, field .. "=" .. concat(arg, ","))

            elseif arg == true then
                insert(cache_key, field)

            else
                insert(cache_key, field .. "=" .. tostring(arg))
            end
        end
    end

    return concat(cache_key, ":")
end


-- Return the component of cache_key for vary_query_params in params
--
-- If no vary_query_params are configured in the plugin, return
-- all of them.
local function params_key(params, plugin_config)
    if not (plugin_config.vary_query_params or EMPTY)[1] then
        local actual_keys = keys(params)
        sort(actual_keys)
        return generate_key_from(params, actual_keys, false)
    end

    return generate_key_from(params, plugin_config.vary_query_params, false)
end
_M.params_key = params_key


-- Return the component of cache_key for vary_headers in params
--
-- If no vary_headers are configured in the plugin, return
-- the empty string.
local function headers_key(headers, plugin_config)
    if not (plugin_config.vary_headers or EMPTY)[1] then
        return ""
    end

    return generate_key_from(headers, plugin_config.vary_headers, false)
end
_M.headers_key = headers_key


-- Return the component of cache_key for vary_body_json_fields in params
--
-- If no vary_body_json_fields are configured in the plugin, return
-- the empty string.
local function json_body_key(json_body, plugin_config)
    if not (plugin_config.vary_body_json_fields or EMPTY)[1] then
        return ""
    end

    return generate_key_from(json_body, plugin_config.vary_body_json_fields, true)
end
_M.json_body_key = json_body_key


local function prefix_uuid(consumer_id, route_id)

    -- authenticated route
    if consumer_id and route_id then
        return fmt("%s:%s", consumer_id, route_id)
    end

    -- unauthenticated route
    if route_id then
        return route_id
    end

    -- global default
    return "default"
end
_M.prefix_uuid = prefix_uuid


function _M.build_cache_key(consumer_id, route_id, method, uri, params_table, headers_table, json_body_table, conf)

    -- obtain cache key components
    local prefix_digest = prefix_uuid(consumer_id, route_id)
    local params_digest = params_key(params_table, conf)
    local headers_digest = headers_key(headers_table, conf)
    local json_body_digest = json_body_key(json_body_table, conf)

    return md5(fmt("%s|%s|%s|%s|%s|%s", prefix_digest, method, uri, params_digest, headers_digest, json_body_digest))
end

return _M

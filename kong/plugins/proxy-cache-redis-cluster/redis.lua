local cjson = require "cjson.safe"
local redis_cluster = require "kong.plugins.proxy-cache-redis-cluster.rediscluster"

local ipairs = ipairs
local ngx = ngx
local table_insert = table.insert
local type = type

local function is_present(str)
    return str and str ~= "" and str ~= null
end

local _M = {}

local function split(s, delimiter)
    local result = {};
    for m in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table_insert(result, m);
    end
    return result;
end

-- Conecto al cluster de Redis
local function red_connect(opts)
    local nodes = {}
    -- Split cluster_nodes_hosts_ports
    for _, value in ipairs(opts.cluster_nodes_hosts_ports) do
        local node_info = split(value, ":")
        table_insert(nodes, { ip = node_info[1], port = node_info[2] })
    end

    if #nodes == 0 then
        kong.log.err("error, no Redis nodes set in the configuration");
        return nil, "no Redis nodes configured"
    end

    local config = {
        name = opts.cluster_name,
        serv_list = nodes,
        connect_timeout = (opts.cluster_connect_timeout or 1000),
        read_timeout = (opts.cluster_connect_timeout or 1000),
        send_timeout = (opts.cluster_connect_timeout or 1000),
        -- redis connection pool idle timeout
        keepalive_timeout = (opts.cluster_keepalive_timeout or 60000),
        -- redis connection pool size
        keepalive_cons = (opts.cluster_connection_pool_size or 1000),
        max_redirection = (opts.cluster_max_redirection or 16),
        max_connection_attempts = (opts.cluster_max_connection_attempts or 3),
        auth = (opts.cluster_password or nil),
        connect_opts = {
            ssl = (opts.cluster_use_ssl_connection or false),
            pool = "redis-cluster-connection-pool",
            -- we leave the 30 default pool, shared among pool_size and backlog https://github.com/openresty/lua-nginx-module#lua_socket_pool_size
            pool_size = 20,
            backlog = 10
        }
    }

    if is_present(opts.cluster_password) then
        config.auth = opts.cluster_password
    end

    -- Support for ACL (we send AUTH username password)
    if is_present(opts.cluster_user) and is_present(opts.cluster_password) then
        config.auth = opts.cluster_user .. " " .. opts.cluster_password
    end

    local red, err_redis = redis_cluster:new(config)
    if err_redis then
        kong.log.err("error connecting to Redis: ", err_redis);
        return nil, err_redis
    end

    return red
end

-- Obtiene un dato de Redis
function _M:fetch(conf, key)
    local red, err_redis = red_connect(conf)

    -- Compruebo si he conectado a Redis bien
    if not red then
        kong.log.err("failed to get the Redis connection: ", err_redis)
        return nil, "there is no Redis connection established"
    end

    if type(key) ~= "string" then
        return nil, "key must be a string"
    end

    -- retrieve object from shared dict
    local req_json, err = red:get(key)
    if req_json == ngx.null then
        if not err then
            -- devuelvo nulo pero diciendo que no está en la caché, no que haya habido error realmente
            -- habrá que guardar la respuesta entonces
            return nil, "request object not in cache"
        else
            return nil, err
        end
    end

    -- decode object from JSON to table
    local req_obj = cjson.decode(req_json)

    if not req_obj then
        return nil, "could not decode request object"
    end

    return req_obj
end

-- Guarda un dato en Redis
function _M:store(conf, key, req_obj, req_ttl)
    local red, err_redis = red_connect(conf)

    -- Compruebo si he conectado a Redis bien
    if not red then
        kong.log.err("failed to get the Redis connection: ", err_redis)
        return nil, "there is no Redis connection established"
    end

    local ttl = req_ttl or conf.cache_ttl

    if type(key) ~= "string" then
        return nil, "key must be a string"
    end

    -- encode request table representation as JSON
    local req_json = cjson.encode(req_obj)
    if not req_json then
        return nil, "could not encode request object"
    end

    -- Hago efectivo el guardado
    -- inicio la transacción
    red:init_pipeline()
    -- guardo
    red:set(key, req_json)
    -- TTL
    red:expire(key, ttl)

    -- ejecuto la transacción
    local _, err = red:commit_pipeline()
    if err then
        kong.log.err("failed to commit the cache value to Redis: ", err)
        return nil, err
    end

    return true and req_json or nil, err
end


-- Elimina una clave
function _M:delete(conf, key)
    local red, err_redis = red_connect(conf)

    -- Compruebo si he conectado a Redis bien
    if not red then
        kong.log.err("failed to get the Redis connection: ", err_redis)
        return nil, "there is no Redis connection established"
    end

    if type(key) ~= "string" then
        return nil, "key must be a string"
    end

    -- borro entrada de redis
    local _, err = red:del(key)
    if err then
        kong.log.err("failed to delete the key from Redis: ", err)
        return nil, err
    end

    return true
end

-- Obtiene información del cluster
function _M:info(conf)
    local red, err_redis = red_connect(conf)

    -- Compruebo si he conectado a Redis bien
    if not red then
        kong.log.err("failed to get the Redis connection: ", err_redis)
        return nil, "there is no Redis connection established"
    end

    -- aquí borro toda la cache de redis de forma asíncrona
    local _, err = red:cluster("info")
    if err then
        kong.log.err("failed to get cluster info from Redis: ", err)
        return nil, err
    end

    return true
end

-- Elimina todas las entradas de la base de datos
function _M:flush(conf)
    local red, err_redis = red_connect(conf)

    -- Compruebo si he conectado a Redis bien
    if not red then
        kong.log.err("failed to get the Redis connection: ", err_redis)
        return nil, "there is no Redis connection established"
    end

    -- aquí borro toda la cache de redis de forma asíncrona
    local _, err = red:flushdb("async")
    if err then
        kong.log.err("failed to flush the database from Redis: ", err)
        return nil, err
    end

    return true
end

return _M

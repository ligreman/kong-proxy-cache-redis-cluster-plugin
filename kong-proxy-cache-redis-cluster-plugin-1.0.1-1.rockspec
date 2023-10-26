package = "kong-proxy-cache-redis-cluster-plugin"
version = "1.0.1-1"

source = {
  url = "git://github.com/ligreman/kong-proxy-cache-redis-cluster-plugin"
}

supported_platforms = {"linux", "macosx"}

description = {
  summary = "HTTP Redis Cluster Proxy Caching for Kong",
  license = "Apache 2.0",
}

dependencies = {
  "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.proxy-cache-redis-cluster.handler"]              = "kong/plugins/proxy-cache-redis-cluster/handler.lua",
    ["kong.plugins.proxy-cache-redis-cluster.cache_key"]            = "kong/plugins/proxy-cache-redis-cluster/cache_key.lua",
    ["kong.plugins.proxy-cache-redis-cluster.schema"]               = "kong/plugins/proxy-cache-redis-cluster/schema.lua",
    ["kong.plugins.proxy-cache-redis-cluster.api"]                  = "kong/plugins/proxy-cache-redis-cluster/api.lua",
    ["kong.plugins.proxy-cache-redis-cluster.redis"]                = "kong/plugins/proxy-cache-redis-cluster/redis.lua",
    ["kong.plugins.proxy-cache-redis-cluster.rediscluster"]         = "kong/plugins/proxy-cache-redis-cluster/rediscluster.lua",
    ["kong.plugins.proxy-cache-redis-cluster.xmodem"]               = "kong/plugins/proxy-cache-redis-cluster/xmodem.lua",
  }
}

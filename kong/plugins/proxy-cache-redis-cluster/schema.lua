return {
    name = "proxy-cache-redis-cluster",
    fields = {
        { config = {
            type = "record",
            fields = {
                { response_code = {
                    type = "array",
                    default = { 200, 301, 404 },
                    elements = { type = "integer", between = { 100, 900 } },
                    len_min = 1,
                    required = true,
                } },
                { request_method = {
                    type = "array",
                    default = { "GET", "HEAD" },
                    elements = {
                        type = "string",
                        one_of = { "HEAD", "GET", "POST", "PATCH", "PUT" },
                    },
                    required = true
                } },
                { allow_force_cache_header = {
                    type = "boolean",
                    default = false,
                    required = true,
                } },
                { content_type = {
                    type = "array",
                    default = { "text/plain", "application/json", "application/json; charset=utf-8" },
                    elements = { type = "string" },
                    required = true,
                } },
                { cache_ttl = {
                    type = "integer",
                    default = 300,
                    required = true,
                    gt = 0,
                } },
                { cache_control = {
                    type = "boolean",
                    default = false,
                    required = true,
                } },
                { storage_ttl = {
                    type = "integer",
                    gt = 0,
                } },
                { vary_query_params = {
                    type = "array",
                    elements = { type = "string" },
                } },
                { vary_headers = {
                    type = "array",
                    elements = { type = "string" },
                } },
                { vary_body_json_fields = {
                    type = "array",
                    elements = { type = "string" },
                } },
                { cluster_name = {
                    type = "string",
                    default = "myRedisCluster",
                    len_min = 0,
                    required = true,
                } },
                { cluster_nodes_hosts_ports = {
                    type = "array",
                    default = { "host:port", "host2:port2" },
                    elements = { type = "string" },
                    required = true,
                } },
                { cluster_user = {
                    type = "string",
                    referenceable = true,                    
                } },
                { cluster_password = {
                    type = "string",
                    len_min = 0,
                    referenceable = true,
                } },
                { cluster_connect_timeout = {
                    type = "number",
                    default = 1000,
                } },
                { cluster_keepalive_timeout = {
                    type = "number",
                    default = 60000,
                } },
                { cluster_connection_pool_size = {
                    type = "number",
                    default = 1000,
                } },
                { cluster_max_redirection = {
                    type = "number",
                    default = 16,
                } },
                { cluster_max_connection_attempts = {
                    type = "number",
                    default = 3,
                } },
                { cluster_use_ssl_connection = {
                    type = "boolean",
                    default = false,
                } },
            },
        }
        },
    },

    entity_checks = {
    },
}

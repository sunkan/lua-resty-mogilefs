-- Copyright (C) Yichun Zhang (agentzh), CloudFlare Inc.


local sub = string.sub
local escape_uri = ngx.escape_uri
local unescape_uri = ngx.unescape_uri
local decode_args = ngx.decode_args
local match = string.match
local tcp = ngx.socket.tcp
local strlen = string.len
local concat = table.concat
local setmetatable = setmetatable
local type = type
local error = error

function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end


local _M = {
    _VERSION = '0.1'
}


local mt = { __index = _M }


function _M.new(self, opts)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end

    local escape_key = escape_uri
    local unescape_key = unescape_uri

    if opts then
       local key_transform = opts.key_transform

       if key_transform then
          escape_key = key_transform[1]
          unescape_key = key_transform[2]
          if not escape_key or not unescape_key then
             return nil, "expecting key_transform = { escape, unescape } table"
          end
       end
    end

    return setmetatable({
        sock = sock,
        escape_key = escape_key,
        unescape_key = unescape_key,
    }, mt)
end


function _M.set_timeout(self, timeout)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    sock:settimeout(timeout)
    return 1
end


function _M.connect(self, ...)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:connect(...)
end

function _M.get(self, domain, key)

    local sock = self.sock
    if not sock then
        return nil, nil, "not initialized"
    end

    local bytes, err = sock:send("GET_PATHS&domain=" .. self.escape_key(domain) .. "&pathcount=1&key=" .. self.escape_key(key) .. "\r\n")
    if not bytes then
        return nil, nil, err
    end

    local line, err = sock:receive()
    if not line then
        if err == "timeout" then
            sock:close()
        end
        return nil, nil, err
    end

    local words = mysplit(line);

    if words[1] == 'ERR' then
        return nil, nil, 'ERR'
    end

    local result = decode_args(words[2], 0)

    if type(result['path1']) == nil then
        return nil, nil, 'NO PATH'
    end

    return result['path1'], result['path']
end


function _M.set_keepalive(self, ...)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:setkeepalive(...)
end


function _M.get_reused_times(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:getreusedtimes()
end


function _M.close(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:close()
end


return _M


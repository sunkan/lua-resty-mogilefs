Name
====

lua-resty-mogilefs - Lua mogilefs client driver for the ngx_lua based on the cosocket API



##Small example


```
location / {
    set $path "";
    rewrite_by_lua '
        local domain = "example.com"
        local key = ngx.var.uri

        local mogilefs = require "resty.mogilefs"
        local mogile, err = mogilefs:new()
        if not mogile then
            ngx.say("error to instantiate mogile: ", err)
            return
        end

        mogile:set_timeout(1000) -- 1 sec

        local ok, err = mogile:connect("127.0.0.1", 7001)
        if not ok then
            ngx.say("failed to connect: ", err)
            return
        end


        local path, pathCount, err = mogile:get(domain, key)
        if err then
          ngx.status = ngx.HTTP_NOT_FOUND
          return
        end

        ngx.var.path = path
    ';
    proxy_pass $path;
}
```

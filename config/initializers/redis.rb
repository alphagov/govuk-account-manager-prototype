require "redis"

# ERR `Redis#exists(key)` will return an Integer in redis-rb 4.3, if
# you want to keep the old behavior, use `exists?` instead. To opt-in
# to the new behavior now you can set Redis.exists_returns_integer =
# true.
Redis.exists_returns_integer = true

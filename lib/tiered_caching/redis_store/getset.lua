local key = KEYS[1]
local value = redis.call('get', key)
if value then
    return value
else
    redis.call('set', key, ARGV[1])
    return ARGV[1]
end

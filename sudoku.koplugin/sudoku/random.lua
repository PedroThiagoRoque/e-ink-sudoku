local Random = {}
Random.__index = Random
local MODULUS = 2147483647
function Random.new(seed)
    local numeric = math.floor(tonumber(seed) or 1)
    local state = ((numeric % MODULUS) + MODULUS) % MODULUS
    if state == 0 then state = 1 end
    return setmetatable({ state = state }, Random)
end
function Random:next_int(limit)
    assert(type(limit) == "number" and limit >= 1 and limit % 1 == 0, "limite deve ser inteiro positivo")
    self.state = (self.state * 48271) % MODULUS
    return (self.state % limit) + 1
end
function Random:shuffle(values)
    local copy = {}; for i, value in ipairs(values) do copy[i] = value end
    for i = #copy, 2, -1 do local j = self:next_int(i); copy[i], copy[j] = copy[j], copy[i] end
    return copy
end
return Random

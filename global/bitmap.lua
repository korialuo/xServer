local bitmap = {}

local BIT_PER_BYTE = 64

function bitmap.new(bits)
    local nbytes = bits // BIT_PER_BYTE
    local nbits = bits % BIT_PER_BYTE
    local bm = { map = {} }
    for i = 1, nbytes do
        table.insert(bm.map, 0)
    end
    bm.bits = BIT_PER_BYTE * nbytes
    if nbits > 0 then 
        table.insert(bm.map, 0)
        bm.bits = bm.bits + BIT_PER_BYTE
    end
    return setmetatable(bm, {__index = bitmap})
end

function bitmap:set(idx)
    if idx > self.bits or idx <= 0 then return end
    local byte = (idx - 1) // BIT_PER_BYTE
    local bit = (idx - 1) % BIT_PER_BYTE
    local val = self.map[byte + 1]
    val = val | (1 << bit)
    self.map[byte + 1] = val
end

function bitmap:unset(idx)
    if idx > self.bits or idx <= 0 then return end
    local byte = (idx - 1) // BIT_PER_BYTE
    local bit = (idx - 1) % BIT_PER_BYTE
    local val = self.map[byte + 1]
    val = val & (~(1 << bit))
    self.map[byte + 1] = val
end

function bitmap:isset(idx)
    if idx > self.bits or idx <= 0 then return false end
    local byte = (idx - 1) // BIT_PER_BYTE
    local bit = (idx - 1) % BIT_PER_BYTE
    local val = self.map[byte + 1]
    return val & (1 << bit) ~= 0
end

function bitmap:clear()
    for i, _ in ipairs(self.map) do
        self.map[i] = 0
    end
end

return bitmap
local bit = require("bit")
local ffi = require("ffi")
local bor = bit.bor
local band = bit.band
local bxor = bit.bxor
local lshift = bit.lshift
local ngx = ngx
local timeBegin = 1491644136158
local sequence = 0
local lastTimestamp = 0

local workerIdBits = ffi.new('uint64_t', 5)
local datacenterIdBits = ffi.new('uint64_t', 5)
local sequenceBits = ffi.new('uint64_t', 12)
local maxWorkerId = lshift(1, workerIdBits)

local datacenterIdShift = sequenceBits + workerIdBits
local timestampLeftShift = sequenceBits + workerIdBits + datacenterIdBits
local sequenceMask = lshift(1, workerIdBits)
local sequenceMask = bxor(-1, (bit.lshift(-1, sequenceBits)))

local _M = {__version='0.1.0'}

_M.nextId = function()
    local timestamp = ngx.now() * 1000
    local datacenterId = ngx.worker.pid()
    local workerId = ngx.worker.id()

    if timestamp < lastTimestamp then
        return nil
    end
    lastTimestamp = timestamp
    timestampInt64 = ffi.new('uint64_t', (timestamp - timeBegin))

    sequence = bit.band((sequence + 1), sequenceMask)
    if sequence == 0 then
        return nil
    end

    local id = bor(
        lshift(timestampInt64, timestampLeftShift),
        lshift(datacenterId, datacenterIdShift),
        lshift(workerId, workerIdBits),
        sequence
    )

    return tostring(id):sub(1, -4)
end

return _M

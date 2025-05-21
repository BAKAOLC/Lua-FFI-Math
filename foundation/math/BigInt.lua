local bit = require("bit")

local type = type
local error = error
local string = string
local table = table
local math = math

-- 每个块的大小（以位为单位）
local CHUNK_BASE = 0x100000000
local CHUNK_MASK = 0xFFFFFFFF

---@class foundation.math.BigInt
---@field chunks number[] 存储数字的各个部分
---@field sign number 符号（1或-1）
---@operator add(foundation.math.BigInt): foundation.math.BigInt
---@operator add(number): foundation.math.BigInt
---@operator sub(foundation.math.BigInt): foundation.math.BigInt
---@operator sub(number): foundation.math.BigInt
---@operator mul(foundation.math.BigInt): foundation.math.BigInt
---@operator mul(number): foundation.math.BigInt
---@operator div(foundation.math.BigInt): foundation.math.BigInt
---@operator div(number): foundation.math.BigInt
---@operator unm(): foundation.math.BigInt
local BigInt = {}
BigInt.__index = BigInt
BigInt.__type = "foundation.math.BigInt"

---创建一个新的大整数
---@param value number|string|nil 初始值，可以是数字或字符串
---@return foundation.math.BigInt 新创建的大整数
function BigInt.create(value)
    local self = {
        chunks = {},
        sign = 1
    }
    setmetatable(self, BigInt)

    if value then
        if type(value) == "number" then
            self:fromNumber(value)
        elseif type(value) == "string" then
            self:fromString(value)
        end
    end

    return self
end

---从数字创建大整数
---@param num number 要转换的数字
function BigInt:fromNumber(num)
    self.chunks = {}
    self.sign = num >= 0 and 1 or -1
    num = math.abs(num)

    while num > 0 do
        table.insert(self.chunks, 1, bit.band(num, CHUNK_MASK))
        num = bit.rshift(num, 32)
    end

    if #self.chunks == 0 then
        self.chunks = { 0 }
    end
end

---从字符串创建大整数
---@param str string 要转换的字符串
function BigInt:fromString(str)
    self.chunks = {}
    self.sign = 1

    if str:sub(1, 1) == "-" then
        self.sign = -1
        str = str:sub(2)
    end

    if str:sub(1, 2) == "0x" then
        str = str:sub(3)
        local chunk = 0
        local shift = 0

        for i = #str, 1, -1 do
            local digit = tonumber(str:sub(i, i), 16)
            if not digit then
                error("Invalid hex digit: " .. str:sub(i, i))
            end
            chunk = bit.bor(chunk, bit.lshift(digit, shift))
            shift = shift + 4

            if shift >= 32 then
                table.insert(self.chunks, 1, chunk)
                chunk = 0
                shift = 0
            end
        end

        if chunk > 0 then
            table.insert(self.chunks, 1, chunk)
        end
    else
        local chunk = 0
        local shift = 0

        for i = #str, 1, -1 do
            local digit = tonumber(str:sub(i, i))
            if not digit then
                error("Invalid decimal digit: " .. str:sub(i, i))
            end
            chunk = chunk + (digit * (10 ^ shift))
            shift = shift + 1

            if chunk >= CHUNK_BASE then
                table.insert(self.chunks, 1, bit.band(chunk, CHUNK_MASK))
                chunk = bit.rshift(chunk, 32)
                shift = 0
            end
        end

        if chunk > 0 then
            table.insert(self.chunks, 1, chunk)
        end
    end

    if #self.chunks == 0 then
        self.chunks = { 0 }
    end
end

---大整数加法
---@param a foundation.math.BigInt|number 第一个操作数
---@param b foundation.math.BigInt|number 第二个操作数
---@return foundation.math.BigInt 相加后的结果
function BigInt.__add(a, b)
    if type(a) == "number" then
        a = BigInt.create(a)
    end
    if type(b) == "number" then
        b = BigInt.create(b)
    end

    local result = BigInt.create()
    result.chunks = {}
    result.sign = a.sign

    local carry = 0
    local maxLen = math.max(#a.chunks, #b.chunks)

    for i = 1, maxLen do
        local aChunk = a.chunks[i] or 0
        local bChunk = b.chunks[i] or 0
        local sum = aChunk + bChunk + carry
        carry = bit.rshift(sum, 32)
        table.insert(result.chunks, bit.band(sum, CHUNK_MASK))
    end

    if carry > 0 then
        table.insert(result.chunks, carry)
    end

    return result
end

---大整数减法
---@param a foundation.math.BigInt|number 第一个操作数
---@param b foundation.math.BigInt|number 第二个操作数
---@return foundation.math.BigInt 相减后的结果
function BigInt.__sub(a, b)
    if type(a) == "number" then
        a = BigInt.create(a)
    end
    if type(b) == "number" then
        b = BigInt.create(b)
    end

    local result = BigInt.create()
    result.chunks = {}

    if a < b then
        a, b = b, a
        result.sign = -1
    else
        result.sign = 1
    end

    local borrow = 0
    local maxLen = math.max(#a.chunks, #b.chunks)

    for i = 1, maxLen do
        local aChunk = a.chunks[i] or 0
        local bChunk = b.chunks[i] or 0
        local diff = aChunk - bChunk - borrow

        if diff < 0 then
            diff = diff + CHUNK_BASE
            borrow = 1
        else
            borrow = 0
        end

        table.insert(result.chunks, bit.band(diff, CHUNK_MASK))
    end

    while #result.chunks > 1 and result.chunks[#result.chunks] == 0 do
        table.remove(result.chunks)
    end

    return result
end

---大整数乘法
---@param a foundation.math.BigInt|number 第一个操作数
---@param b foundation.math.BigInt|number 第二个操作数
---@return foundation.math.BigInt 相乘后的结果
function BigInt.__mul(a, b)
    if type(a) == "number" then
        a = BigInt.create(a)
    end
    if type(b) == "number" then
        b = BigInt.create(b)
    end

    local result = BigInt.create()
    result.chunks = {}
    result.sign = a.sign * b.sign

    for i = 1, #a.chunks + #b.chunks do
        result.chunks[i] = 0
    end

    for i = 1, #a.chunks do
        local carry = 0
        for j = 1, #b.chunks do
            local product = a.chunks[i] * b.chunks[j] + result.chunks[i + j - 1] + carry
            carry = bit.rshift(product, 32)
            result.chunks[i + j - 1] = bit.band(product, CHUNK_MASK)
        end
        result.chunks[i + #b.chunks] = carry
    end

    while #result.chunks > 1 and result.chunks[#result.chunks] == 0 do
        table.remove(result.chunks)
    end

    return result
end

---大整数取负
---@param a foundation.math.BigInt 操作数
---@return foundation.math.BigInt 取反后的结果
function BigInt.__unm(a)
    local result = a:clone()
    result.sign = -result.sign
    return result
end

---大整数相等性比较
---@param a foundation.math.BigInt 第一个操作数
---@param b foundation.math.BigInt 第二个操作数
---@return boolean 两个大整数是否相等
function BigInt.__eq(a, b)
    if type(a) == "number" then
        a = BigInt.create(a)
    end
    if type(b) == "number" then
        b = BigInt.create(b)
    end

    if a.sign ~= b.sign or #a.chunks ~= #b.chunks then
        return false
    end

    for i = 1, #a.chunks do
        if a.chunks[i] ~= b.chunks[i] then
            return false
        end
    end

    return true
end

---大整数小于比较
---@param a foundation.math.BigInt 第一个操作数
---@param b foundation.math.BigInt|number 第二个操作数
---@return boolean 第一个大整数是否小于第二个
function BigInt.__lt(a, b)
    if type(b) == "number" then
        b = BigInt.create(b)
    end

    if a.sign ~= b.sign then
        return a.sign < b.sign
    end

    if #a.chunks ~= #b.chunks then
        return #a.chunks < #b.chunks
    end

    for i = #a.chunks, 1, -1 do
        if a.chunks[i] ~= b.chunks[i] then
            return a.chunks[i] < b.chunks[i]
        end
    end

    return false
end

---大整数大于比较
---@param a foundation.math.BigInt 第一个操作数
---@param b foundation.math.BigInt|number 第二个操作数
---@return boolean 第一个大整数是否大于第二个
function BigInt.__gt(a, b)
    if type(b) == "number" then
        b = BigInt.create(b)
    end

    if a.sign ~= b.sign then
        return a.sign > b.sign
    end

    if #a.chunks ~= #b.chunks then
        return #a.chunks > #b.chunks
    end

    for i = #a.chunks, 1, -1 do
        if a.chunks[i] ~= b.chunks[i] then
            return a.chunks[i] > b.chunks[i]
        end
    end

    return false
end

---大整数字符串表示
---@param a foundation.math.BigInt 操作数
---@return string 大整数的字符串表示
function BigInt.__tostring(a)
    if #a.chunks == 1 and a.chunks[1] == 0 then
        return "0"
    end

    local result = ""
    if a.sign == -1 then
        result = "-"
    end

    for i = #a.chunks, 1, -1 do
        result = result .. string.format("%08x", a.chunks[i])
    end

    result = result:gsub("^0+", "")
    if result == "" then
        result = "0"
    end

    return "0x" .. result
end

---获取大整数的副本
---@return foundation.math.BigInt 大整数的副本
function BigInt:clone()
    local result = BigInt.create()
    result.chunks = {}
    for i = 1, #self.chunks do
        result.chunks[i] = self.chunks[i]
    end
    result.sign = self.sign
    return result
end

---将大整数转换为数字（如果可能）
---@return number|nil 转换后的数字，如果超出范围则返回nil
function BigInt:toNumber()
    if #self.chunks > 2 then
        return nil
    end

    local result = 0
    for i = 1, #self.chunks do
        result = bit.bor(bit.lshift(result, 32), self.chunks[i])
    end

    return result * self.sign
end

return BigInt

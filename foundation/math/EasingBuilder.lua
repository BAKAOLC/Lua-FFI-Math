local table = require("table")
local math = require("math")
local string = require("string")
local easing = require("foundation.math.Easing")

local load = load

---@class foundation.EasingBuilder.Environment
local env = {
    math = math,
    easing = easing,
}

function env.sin(x)
    return math.sin(math.rad(x))
end

function env.cos(x)
    return math.cos(math.rad(x))
end

---@class foundation.EasingBuilder
---@field _functions function[]
local M = {}
M.__index = M

M.__env = env

local function reverse(x)
    return 1 - x
end

local function vShape(x)
    return x < 0.5 and (1 - x * 2) or (x - 0.5) * 2
end

local function invertedVShape(x)
    return x < 0.5 and x * 2 or (1 - x) * 2
end

local function bindFunction(func1, func2)
    return function(x)
        return func1(func2(x))
    end
end

---创建新的EasingBuilder实例
---@return foundation.EasingBuilder
function M.create()
    local self = setmetatable({}, M)
    self._functions = {}
    return self
end

---添加一个表达式
---@param expr string
---@return foundation.EasingBuilder
function M:add(expr)
    local func = load(string.format("return function(x) return %s end", expr), "Easing", "t", M.__env)
    if not func then
        error("Failed to build easing function: " .. expr)
    end
    table.insert(self._functions, func())
    return self
end

---添加一个函数
---@param func function
---@return foundation.EasingBuilder
function M:addFunction(func)
    table.insert(self._functions, func)
    return self
end

---添加反向处理
---@return foundation.EasingBuilder
function M:addReverse()
    table.insert(self._functions, reverse)
    return self
end

---添加V型处理（1~0~0）
---@return foundation.EasingBuilder
function M:addVShape()
    table.insert(self._functions, vShape)
    return self
end

---添加倒V型处理（0~1~0）
---@return foundation.EasingBuilder
function M:addInvertedVShape()
    table.insert(self._functions, invertedVShape)
    return self
end

---添加Easing库中的函数
---@param funcName string
---@return foundation.EasingBuilder
function M:addEasing(funcName)
    if easing[funcName] then
        table.insert(self._functions, easing[funcName])
    end
    return self
end

---构建最终的函数
---@return function
function M:build()
    if #self._functions == 0 then
        return easing.linear
    end

    local result = self._functions[#self._functions]
    for i = #self._functions - 1, 1, -1 do
        result = bindFunction(self._functions[i], result)
    end
    return result
end

---获取迭代器
---@param from number
---@param to number
---@param part number
---@param head boolean
---@param tail boolean
---@return function 返回一个类似ipairs的迭代器生成函数
function M:getIterator(from, to, part, head, tail)
    local easingFunc = self:build()
    local p = head and tail and (part - 1) or (not head and not tail and (part + 1) or part)

    return function()
        local index = 0
        return function()
            if index >= part then
                return nil
            end
            local nextIndex = index + 1
            local t = head and index / p or nextIndex / p
            index = nextIndex
            return nextIndex, easing.interpolation(from, to, t, easingFunc)
        end
    end
end

return M

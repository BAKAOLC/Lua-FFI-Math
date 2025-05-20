local ffi = require("ffi")

local type = type
local math = math
local tostring = tostring
local string = string
local rawset = rawset
local setmetatable = setmetatable

local Vector2 = require("foundation.math.Vector2")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 point;
    foundation_math_Vector2 direction;
} foundation_shape_Line;
]]

---@class foundation.shape.Line
---@field point foundation.math.Vector2 直线上的一点
---@field direction foundation.math.Vector2 直线的方向向量
local Line = {}
Line.__type = "foundation.shape.Line"

---@param self foundation.shape.Line
---@param key any
---@return any
function Line.__index(self, key)
    if key == "point" then
        return self.__data.point
    elseif key == "direction" then
        return self.__data.direction
    end
    return Line[key]
end

---@param self foundation.shape.Line
---@param key any
---@param value any
function Line.__newindex(self, key, value)
    if key == "point" then
        self.__data.point = value
    elseif key == "direction" then
        self.__data.direction = value
    else
        rawset(self, key, value)
    end
end

---创建一条新的直线，由一个点和方向向量确定
---@param point foundation.math.Vector2 直线上的点
---@param direction foundation.math.Vector2 方向向量
---@return foundation.shape.Line
function Line.create(point, direction)
    local dist = direction and direction:length() or 0
    if dist <= 1e-10 then
        direction = Vector2.create(1, 0)
    elseif dist ~= 1 then
        ---@diagnostic disable-next-line: need-check-nil
        direction = direction:normalized()
    else
        ---@diagnostic disable-next-line: need-check-nil
        direction = direction:clone()
    end

    local line = ffi.new("foundation_shape_Line", point, direction)
    local result = {
        __data = line,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Line)
end

---根据两个点创建一条直线
---@param p1 foundation.math.Vector2 第一个点
---@param p2 foundation.math.Vector2 第二个点
---@return foundation.shape.Line
function Line.createFromPoints(p1, p2)
    local direction = p2 - p1
    return Line.create(p1, direction)
end

---根据一个点、弧度创建一条直线
---@param point foundation.math.Vector2 起始点
---@param rad number 弧度
---@return foundation.shape.Line
function Line.createFromPointAndRad(point, rad)
    local direction = Vector2.createFromRad(rad)
    return Line.create(point, direction)
end

---根据一个点、角度创建一条直线
---@param point foundation.math.Vector2 起始点
---@param angle number 角度
---@return foundation.shape.Line
function Line.createFromPointAndAngle(point, angle)
    local direction = Vector2.createFromAngle(angle)
    return Line.create(point, direction)
end

---直线相等比较
---@param a foundation.shape.Line
---@param b foundation.shape.Line
---@return boolean
function Line.__eq(a, b)
    local dir_cross = a.direction:cross(b.direction)
    if math.abs(dir_cross) > 1e-10 then
        return false
    end
    local point_diff = b.point - a.point
    return math.abs(point_diff:cross(a.direction)) <= 1e-10
end

---直线的字符串表示
---@param self foundation.shape.Line
---@return string
function Line.__tostring(self)
    return string.format("Line(%s, dir=%s)", tostring(self.point), tostring(self.direction))
end

---获取直线上相对 point 指定距离的点
---@param length number 距离
---@return foundation.math.Vector2
function Line:getPoint(length)
    return self.point + self.direction * length
end

---计算直线的中心
---@return foundation.math.Vector2
function Line:getCenter()
    return self.point
end

---获取直线的AABB包围盒
---@return number, number, number, number
function Line:AABB()
    if math.abs(self.direction.x) < 1e-10 then
        -- 垂直线
        return self.point.x, self.point.x, -math.huge, math.huge
    elseif math.abs(self.direction.y) < 1e-10 then
        -- 水平线
        return -math.huge, math.huge, self.point.y, self.point.y
    else
        -- 斜线
        return -math.huge, math.huge, -math.huge, math.huge
    end
end

---计算直线的包围盒宽高
---@return number, number
function Line:getBoundingBoxSize()
    if math.abs(self.direction.x) < 1e-10 then
        return 0, math.huge
    elseif math.abs(self.direction.y) < 1e-10 then
        return math.huge, 0
    end
    return math.huge, math.huge
end

---获取直线的角度（弧度）
---@return number 直线的角度，单位为弧度
function Line:angle()
    return math.atan2(self.direction.y, self.direction.x)
end

---获取直线的角度（度）
---@return number 直线的角度，单位为度
function Line:degreeAngle()
    return math.deg(self:angle())
end

---平移直线（更改当前直线）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Line 平移后的直线（自身引用）
function Line:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX = v
        moveY = v
    else
        moveX = v.x
        moveY = v.y
    end
    self.point.x = self.point.x + moveX
    self.point.y = self.point.y + moveY
    return self
end

---获取当前直线平移指定距离的副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Line 移动后的直线副本
function Line:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX = v
        moveY = v
    else
        moveX = v.x
        moveY = v.y
    end
    return Line.create(
            Vector2.create(self.point.x + moveX, self.point.y + moveY),
            self.direction:clone()
    )
end

---将当前直线旋转指定弧度（更改当前直线）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Line 旋转后的直线（自身引用）
---@overload fun(self: foundation.shape.Line, rad: number): foundation.shape.Line 将当前直线绕定义的点旋转指定弧度（更改当前直线）
function Line:rotate(rad, center)
    center = center or self.point
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)
    local v = self.direction
    local x = v.x * cosRad - v.y * sinRad
    local y = v.x * sinRad + v.y * cosRad
    self.direction.x = x
    self.direction.y = y
    return self
end

---将当前直线旋转指定角度（更改当前直线）
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Line 旋转后的直线（自身引用）
---@overload fun(self: foundation.shape.Line, angle: number): foundation.shape.Line 将当前直线绕定义的点旋转指定角度（更改当前直线）
function Line:degreeRotate(angle, center)
    angle = math.rad(angle)
    return self:rotate(angle, center)
end

---获取当前直线旋转指定弧度的副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Line 旋转后的直线副本
---@overload fun(self: foundation.shape.Line, rad: number): foundation.shape.Line 获取当前直线绕定义的点旋转指定弧度的副本
function Line:rotated(rad, center)
    center = center or self.point
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)
    local v = self.direction
    return Line.create(
            Vector2.create(v.x * cosRad - v.y * sinRad + center.x, v.x * sinRad + v.y * cosRad + center.y),
            Vector2.create(v.x * cosRad - v.y * sinRad, v.x * sinRad + v.y * cosRad)
    )
end

---获取当前直线旋转指定角度的副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Line 旋转后的直线副本
------@overload fun(self: foundation.shape.Line, angle: number): foundation.shape.Line 获取当前直线绕定义的点旋转指定角度的副本
function Line:degreeRotated(angle, center)
    angle = math.rad(angle)
    return self:rotated(angle, center)
end

---缩放直线（更改当前直线）
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2|nil 缩放中心点，默认为直线上的点
---@return foundation.shape.Line 自身引用
function Line:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self.point

    local dx = self.point.x - center.x
    local dy = self.point.y - center.y
    self.point.x = center.x + dx * scaleX
    self.point.y = center.y + dy * scaleY
    return self
end

---获取缩放后的直线副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2|nil 缩放中心点，默认为直线上的点
---@return foundation.shape.Line
function Line:scaled(scale, center)
    local result = Line.create(self.point:clone(), self.direction:clone())
    return result:scale(scale, center)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Line:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---检查是否与其他形状相交，只返回是否相交的布尔值
---@param other any
---@return boolean
function Line:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---计算点到直线的最近点
---@param point foundation.math.Vector2 点
---@return foundation.math.Vector2 最近点
function Line:closestPoint(point)
    return self:projectPoint(point)
end

---计算点到直线的距离
---@param point foundation.math.Vector2 点
---@return number 距离
function Line:distanceToPoint(point)
    return (point - self:closestPoint(point)):length()
end

---检查点是否在直线上
---@param point foundation.math.Vector2 点
---@param tolerance number 误差容忍度，默认为1e-10
---@return boolean
function Line:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local point_vec = point - self.point
    local cross = point_vec:cross(self.direction)
    return math.abs(cross) <= tolerance
end

---获取点在直线上的投影
---@param point foundation.math.Vector2 点
---@return foundation.math.Vector2 投影点
function Line:projectPoint(point)
    local dir = self.direction
    local point_vec = point - self.point
    local proj_length = point_vec:dot(dir)
    return self.point + dir * proj_length
end

---复制当前直线
---@return foundation.shape.Line 复制的直线
function Line:clone()
    return Line.create(self.point:clone(), self.direction:clone())
end

ffi.metatype("foundation_shape_Line", Line)

return Line

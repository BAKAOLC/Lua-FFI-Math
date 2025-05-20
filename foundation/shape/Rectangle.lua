local ffi = require("ffi")

local type = type
local ipairs = ipairs
local tostring = tostring
local string = string
local math = math
local rawset = rawset
local setmetatable = setmetatable

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 center;
    double width;
    double height;
    foundation_math_Vector2 direction;
} foundation_shape_Rectangle;
]]

---@class foundation.shape.Rectangle
---@field center foundation.math.Vector2 矩形的中心点
---@field width number 矩形的宽度
---@field height number 矩形的高度
---@field direction foundation.math.Vector2 矩形的宽度轴方向（归一化向量）
local Rectangle = {}
Rectangle.__type = "foundation.shape.Rectangle"

---@param self foundation.shape.Rectangle
---@param key any
---@return any
function Rectangle.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "width" then
        return self.__data.width
    elseif key == "height" then
        return self.__data.height
    elseif key == "direction" then
        return self.__data.direction
    end
    return Rectangle[key]
end

---@param self foundation.shape.Rectangle
---@param key string
---@param value any
function Rectangle.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "width" then
        self.__data.width = value
    elseif key == "height" then
        self.__data.height = value
    elseif key == "direction" then
        self.__data.direction = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的矩形
---@param center foundation.math.Vector2 中心点
---@param width number 宽度
---@param height number 高度
---@param direction foundation.math.Vector2|nil 宽度轴方向（归一化向量），默认为(1,0)
---@return foundation.shape.Rectangle
function Rectangle.create(center, width, height, direction)
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
    local rectangle = ffi.new("foundation_shape_Rectangle", center, width, height, direction)
    local result = {
        __data = rectangle
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Rectangle)
end

---使用给定的弧度创建矩形
---@param center foundation.math.Vector2 中心点
---@param width number 宽度
---@param height number 高度
---@param rad number 旋转弧度
---@return foundation.shape.Rectangle
function Rectangle.createFromRad(center, width, height, rad)
    local direction = Vector2.createFromRad(rad)
    return Rectangle.create(center, width, height, direction)
end

---使用给定的角度创建矩形
---@param center foundation.math.Vector2 中心点
---@param width number 宽度
---@param height number 高度
---@param angle number 旋转角度
---@return foundation.shape.Rectangle
function Rectangle.createFromAngle(center, width, height, angle)
    local direction = Vector2.createFromAngle(angle)
    return Rectangle.create(center, width, height, direction)
end

---矩形相等比较
---@param a foundation.shape.Rectangle
---@param b foundation.shape.Rectangle
---@return boolean
function Rectangle.__eq(a, b)
    return a.center == b.center and
            math.abs(a.width - b.width) <= 1e-10 and
            math.abs(a.height - b.height) <= 1e-10 and
            a.direction == b.direction
end

---矩形的字符串表示
---@param self foundation.shape.Rectangle
---@return string
function Rectangle.__tostring(self)
    return string.format("Rectangle(center=%s, width=%f, height=%f, direction=%s)",
            tostring(self.center), self.width, self.height, tostring(self.direction))
end

---获取矩形的四个顶点
---@return foundation.math.Vector2[]
function Rectangle:getVertices()
    local hw, hh = self.width / 2, self.height / 2
    local dir = self.direction
    local perp = Vector2.create(-dir.y, dir.x)
    local vertices = {
        Vector2.create(-hw, -hh),
        Vector2.create(hw, -hh),
        Vector2.create(hw, hh),
        Vector2.create(-hw, hh)
    }
    for i, v in ipairs(vertices) do
        local x = v.x * dir.x + v.y * perp.x
        local y = v.x * dir.y + v.y * perp.y
        vertices[i] = self.center + Vector2.create(x, y)
    end
    return vertices
end

---获取矩形的四条边（线段）
---@return foundation.shape.Segment[]
function Rectangle:getEdges()
    local vertices = self:getVertices()
    return {
        Segment.create(vertices[1], vertices[2]),
        Segment.create(vertices[2], vertices[3]),
        Segment.create(vertices[3], vertices[4]),
        Segment.create(vertices[4], vertices[1])
    }
end

---平移矩形（更改当前矩形）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Rectangle 自身引用
function Rectangle:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    self.center.x = self.center.x + moveX
    self.center.y = self.center.y + moveY
    return self
end

---获取平移后的矩形副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Rectangle
function Rectangle:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Rectangle.create(
            Vector2.create(self.center.x + moveX, self.center.y + moveY),
            self.width, self.height, self.direction
    )
end

---旋转矩形（更改当前矩形）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为矩形中心
---@return foundation.shape.Rectangle 自身引用
function Rectangle:rotate(rad, center)
    local cosA, sinA = math.cos(rad), math.sin(rad)
    local x = self.direction.x * cosA - self.direction.y * sinA
    local y = self.direction.x * sinA + self.direction.y * cosA
    self.direction = Vector2.create(x, y):normalized()

    if center then
        local dx = self.center.x - center.x
        local dy = self.center.y - center.y
        self.center.x = center.x + dx * cosA - dy * sinA
        self.center.y = center.y + dx * sinA + dy * cosA
    end
    return self
end

---旋转矩形（更改当前矩形）
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为矩形中心
---@return foundation.shape.Rectangle 自身引用
function Rectangle:degreeRotate(angle, center)
    return self:rotate(math.rad(angle), center)
end

---获取旋转后的矩形副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为矩形中心
---@return foundation.shape.Rectangle
function Rectangle:rotated(rad, center)
    local result = Rectangle.create(self.center:clone(), self.width, self.height, self.direction:clone())
    return result:rotate(rad, center)
end

---获取旋转后的矩形副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为矩形中心
---@return foundation.shape.Rectangle
function Rectangle:degreeRotated(angle, center)
    return self:rotated(math.rad(angle), center)
end

---缩放矩形（更改当前矩形）
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2|nil 缩放中心点，默认为矩形中心
---@return foundation.shape.Rectangle 自身引用
function Rectangle:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self.center

    self.width = self.width * scaleX
    self.height = self.height * scaleY
    local dx = self.center.x - center.x
    local dy = self.center.y - center.y
    self.center.x = center.x + dx * scaleX
    self.center.y = center.y + dy * scaleY
    return self
end

---获取缩放后的矩形副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2|nil 缩放中心点，默认为矩形中心
---@return foundation.shape.Rectangle
function Rectangle:scaled(scale, center)
    local result = Rectangle.create(self.center:clone(), self.width, self.height, self.direction:clone())
    return result:scale(scale, center)
end

---检查点是否在矩形内（包括边界）
---@param point foundation.math.Vector2
---@return boolean
function Rectangle:contains(point)
    return ShapeIntersector.rectangleContainsPoint(self, point)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Rectangle:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---仅检查是否与其他形状相交
---@param other any
---@return boolean
function Rectangle:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---计算矩形的面积
---@return number 矩形的面积
function Rectangle:area()
    return self.width * self.height
end

---计算矩形的周长
---@return number 矩形的周长
function Rectangle:getPerimeter()
    return 2 * (self.width + self.height)
end

---计算矩形的中心
---@return foundation.math.Vector2 矩形的中心
function Rectangle:getCenter()
    return self.center:clone()
end

---获取矩形的AABB包围盒
---@return number, number, number, number
function Rectangle:AABB()
    local vertices = self:getVertices()
    local minX, maxX = vertices[1].x, vertices[1].x
    local minY, maxY = vertices[1].y, vertices[1].y
    for i = 2, 4 do
        local v = vertices[i]
        minX = math.min(minX, v.x)
        maxX = math.max(maxX, v.x)
        minY = math.min(minY, v.y)
        maxY = math.max(maxY, v.y)
    end
    return minX, maxX, minY, maxY
end

---计算矩形的包围盒宽高
---@return number, number
function Rectangle:getBoundingBoxSize()
    local minX, maxX, minY, maxY = self:AABB()
    return maxX - minX, maxY - minY
end

---计算矩形的内心
---@return foundation.math.Vector2 矩形的内心
function Rectangle:incenter()
    return self.center:clone()
end

---计算矩形的内切圆半径
---@return number 矩形的内切圆半径
function Rectangle:inradius()
    local min = math.min(self.width, self.height) / 2
    return min
end

---计算矩形的外心
---@return foundation.math.Vector2 矩形的外心
function Rectangle:circumcenter()
    return self.center:clone()
end

---计算矩形的外接圆半径
---@return number 矩形的外接圆半径
function Rectangle:circumradius()
    return math.sqrt((self.width / 2) ^ 2 + (self.height / 2) ^ 2)
end

---计算点到矩形的最近点
---@param point foundation.math.Vector2
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector2
---@overload fun(self: foundation.shape.Rectangle, point: foundation.math.Vector2): foundation.math.Vector2
function Rectangle:closestPoint(point, boundary)
    if not boundary and self:contains(point) then
        return point:clone()
    end
    local edges = self:getEdges()
    local minDistance = math.huge
    local closestPoint
    for _, edge in ipairs(edges) do
        local edgeClosest = edge:closestPoint(point)
        local distance = (point - edgeClosest):length()
        if distance < minDistance then
            minDistance = distance
            closestPoint = edgeClosest
        end
    end
    return closestPoint
end

---计算点到矩形的距离
---@param point foundation.math.Vector2
---@return number
function Rectangle:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end
    local edges = self:getEdges()
    local minDistance = math.huge
    for _, edge in ipairs(edges) do
        local distance = edge:distanceToPoint(point)
        if distance < minDistance then
            minDistance = distance
        end
    end
    return minDistance
end

---将点投影到矩形上
---@param point foundation.math.Vector2
---@return foundation.math.Vector2
function Rectangle:projectPoint(point)
    return self:closestPoint(point, true)
end

---检查点是否在矩形边界上
---@param point foundation.math.Vector2
---@param tolerance number|nil 默认为1e-10
---@return boolean
function Rectangle:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:containsPoint(point, tolerance) then
            return true
        end
    end
    return false
end

---复制矩形
---@return foundation.shape.Rectangle
function Rectangle:clone()
    return Rectangle.create(self.center:clone(), self.width, self.height, self.direction:clone())
end

ffi.metatype("foundation_shape_Rectangle", Rectangle)

return Rectangle
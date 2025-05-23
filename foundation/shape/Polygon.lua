local ffi = require("ffi")

local type = type
local ipairs = ipairs
local table = table
local math = math
local tostring = tostring
local string = string
local error = error
local rawset = rawset
local setmetatable = setmetatable

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")
local Triangle = require("foundation.shape.Triangle")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

ffi.cdef [[
typedef struct {
    int size;
    foundation_math_Vector2* points;
} foundation_shape_Polygon;
]]

---@class foundation.shape.Polygon
---@field size number 多边形顶点数量
---@field points foundation.math.Vector2[] 多边形的顶点数组
local Polygon = {}
Polygon.__type = "foundation.shape.Polygon"

---@param self foundation.shape.Polygon
---@param key string
---@return any
function Polygon.__index(self, key)
    if key == "size" then
        return self.__data.size
    elseif key == "points" then
        return self.__data.points
    end
    return Polygon[key]
end

---@param t foundation.math.Vector2[]
---@return number, foundation.math.Vector2[]
local function buildNewVector2Array(t)
    local size = #t
    local points_array = ffi.new("foundation_math_Vector2[?]", size)

    for i = 1, size do
        points_array[i - 1] = Vector2.create(t[i].x, t[i].y)
    end

    return size, points_array
end

---@param self foundation.shape.Polygon
---@param key any
---@param value any
function Polygon.__newindex(self, key, value)
    if key == "size" then
        error("cannot modify size directly")
    elseif key == "points" then
        local size, points_array = buildNewVector2Array(value)
        self.__data.size = size
        self.__data.points = points_array
        self.__data_points_ref = points_array
    else
        rawset(self, key, value)
    end
end

---创建一个多边形
---@param points foundation.math.Vector2[] 多边形的顶点数组，按顺序连线并首尾相接
---@return foundation.shape.Polygon
function Polygon.create(points)
    if not points or #points < 3 then
        error("Polygon must have at least 3 points")
    end

    local size, points_array = buildNewVector2Array(points)

    local polygon = ffi.new("foundation_shape_Polygon", size, points_array)
    local result = {
        __data = polygon,
        __data_points_ref = points_array,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Polygon)
end

---创建一个正多边形
---@param center foundation.math.Vector2 多边形的中心
---@param radius number 外接圆半径
---@param numSides number 边数
---@param startRad number 起始角度（弧度）
---@return foundation.shape.Polygon
function Polygon.createRegularRad(center, radius, numSides, startRad)
    startRad = startRad or 0
    local points = {}
    local angleStep = 2 * math.pi / numSides

    for i = 1, numSides do
        local angle = startRad + (i - 1) * angleStep
        local x = center.x + radius * math.cos(angle)
        local y = center.y + radius * math.sin(angle)
        points[i] = Vector2.create(x, y)
    end

    return Polygon.create(points)
end

---创建一个正多边形
---@param center foundation.math.Vector2 多边形的中心
---@param radius number 外接圆半径
---@param numSides number 边数
---@param startAngle number 起始角度（角度）
---@return foundation.shape.Polygon
function Polygon.createRegularDegree(center, radius, numSides, startAngle)
    return Polygon.createRegularRad(center, radius, numSides, math.rad(startAngle))
end

---多边形相等比较
---@param a foundation.shape.Polygon 第一个多边形
---@param b foundation.shape.Polygon 第二个多边形
---@return boolean
function Polygon.__eq(a, b)
    if a.size ~= b.size then
        return false
    end

    for i = 0, a.size - 1 do
        if a.points[i] ~= b.points[i] then
            return false
        end
    end

    return true
end

---多边形转字符串表示
---@param self foundation.shape.Polygon
---@return string
function Polygon.__tostring(self)
    local pointsStr = {}
    for i = 0, self.size - 1 do
        pointsStr[i + 1] = tostring(self.points[i])
    end
    return string.format("Polygon(%s)", table.concat(pointsStr, ", "))
end

---获取多边形的边数
---@return number
function Polygon:getEdgeCount()
    return self.size
end

---获取多边形的所有边（线段表示）
---@return foundation.shape.Segment[]
function Polygon:getEdges()
    local edges = {}

    for i = 0, self.size - 1 do
        local nextIdx = (i + 1) % self.size
        edges[i + 1] = Segment.create(self.points[i], self.points[nextIdx])
    end

    return edges
end

---获取多边形的顶点数组
---@return foundation.math.Vector2[]
function Polygon:getVertices()
    local vertices = {}
    for i = 0, self.size - 1 do
        vertices[i + 1] = self.points[i]:clone()
    end
    return vertices
end

---获取多边形的AABB包围盒
---@return number, number, number, number
function Polygon:AABB()
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for i = 0, self.size - 1 do
        local point = self.points[i]
        minX = math.min(minX, point.x)
        minY = math.min(minY, point.y)
        maxX = math.max(maxX, point.x)
        maxY = math.max(maxY, point.y)
    end

    return minX, maxX, minY, maxY
end

---计算多边形的重心
---@return foundation.math.Vector2
function Polygon:centroid()
    local totalArea = 0
    local centroidX = 0
    local centroidY = 0

    local p0 = self.points[0]
    for i = 1, self.size - 2 do
        local p1 = self.points[i]
        local p2 = self.points[i + 1]

        local area = math.abs((p1.x - p0.x) * (p2.y - p0.y) - (p2.x - p0.x) * (p1.y - p0.y)) / 2
        totalArea = totalArea + area

        local cx = (p0.x + p1.x + p2.x) / 3
        local cy = (p0.y + p1.y + p2.y) / 3

        centroidX = centroidX + cx * area
        centroidY = centroidY + cy * area
    end

    if totalArea == 0 then
        return self:getCenter()
    end

    return Vector2.create(centroidX / totalArea, centroidY / totalArea)
end

---计算多边形的中心
---@return foundation.math.Vector2
function Polygon:getCenter()
    local minX, maxX, minY, maxY = self:AABB()
    return Vector2.create((minX + maxX) / 2, (minY + maxY) / 2)
end

---计算多边形的包围盒宽高
---@return number, number
function Polygon:getBoundingBoxSize()
    local minX, maxX, minY, maxY = self:AABB()
    return maxX - minX, maxY - minY
end

---计算多边形的面积
---@return number
function Polygon:getArea()
    local area = 0

    for i = 0, self.size - 1 do
        local j = (i + 1) % self.size
        area = area + (self.points[i].x * self.points[j].y) - (self.points[j].x * self.points[i].y)
    end

    return math.abs(area) / 2
end

---计算多边形的周长
---@return number
function Polygon:getPerimeter()
    local perimeter = 0

    for i = 0, self.size - 1 do
        local nextIdx = (i + 1) % self.size
        perimeter = perimeter + (self.points[i] - self.points[nextIdx]):length()
    end

    return perimeter
end

---判断多边形是否为凸多边形
---@return boolean
function Polygon:isConvex()
    if self.size < 3 then
        return false
    end

    local sign = 0
    local allCollinear = true

    for i = 0, self.size - 1 do
        local j = (i + 1) % self.size
        local k = (j + 1) % self.size

        local dx1 = self.points[j].x - self.points[i].x
        local dy1 = self.points[j].y - self.points[i].y
        local dx2 = self.points[k].x - self.points[j].x
        local dy2 = self.points[k].y - self.points[j].y

        local cross = dx1 * dy2 - dy1 * dx2
        local absCross = math.abs(cross)

        if absCross > 1e-10 then
            allCollinear = false
        end

        if i == 0 then
            if absCross > 1e-10 then
                sign = cross > 0 and 1 or -1
            end
        elseif (cross > 1e-10 and sign < 0) or (cross < -1e-10 and sign > 0) or (sign == 0 and absCross > 1e-10) then
            return false
        end
    end

    if allCollinear then
        return false
    end

    return true
end

---平移多边形（更改当前多边形）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Polygon 平移后的多边形（自身引用）
function Polygon:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end

    for i = 0, self.size - 1 do
        self.points[i].x = self.points[i].x + moveX
        self.points[i].y = self.points[i].y + moveY
    end

    return self
end

---获取当前多边形平移指定距离的副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Polygon 移动后的多边形副本
function Polygon:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end

    local newPoints = {}
    for i = 0, self.size - 1 do
        newPoints[i + 1] = Vector2.create(self.points[i].x + moveX, self.points[i].y + moveY)
    end

    return Polygon.create(newPoints)
end

---将当前多边形旋转指定弧度（更改当前多边形）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为多边形重心
---@return foundation.shape.Polygon 自身引用
function Polygon:rotate(rad, center)
    center = center or self:centroid()
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)

    for i = 0, self.size - 1 do
        local point = self.points[i]
        local dx = point.x - center.x
        local dy = point.y - center.y
        point.x = center.x + dx * cosRad - dy * sinRad
        point.y = center.y + dx * sinRad + dy * cosRad
    end

    return self
end

---将当前多边形旋转指定角度（更改当前多边形）
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为多边形重心
---@return foundation.shape.Polygon 自身引用
function Polygon:degreeRotate(angle, center)
    return self:rotate(math.rad(angle), center)
end

---获取当前多边形旋转指定弧度的副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为多边形重心
---@return foundation.shape.Polygon
function Polygon:rotated(rad, center)
    local points = self:getVertices()
    local result = Polygon.create(points)
    return result:rotate(rad, center)
end

---获取当前多边形旋转指定角度的副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为多边形重心
---@return foundation.shape.Polygon
function Polygon:degreeRotated(angle, center)
    return self:rotated(math.rad(angle), center)
end

---将当前多边形缩放指定倍数（更改当前多边形）
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Polygon 缩放后的多边形（自身引用）
---@overload fun(self: foundation.shape.Polygon, scale: number): foundation.shape.Polygon 相对多边形中心点缩放指定倍数
function Polygon:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:centroid()

    for i = 0, self.size - 1 do
        self.points[i].x = (self.points[i].x - center.x) * scaleX + center.x
        self.points[i].y = (self.points[i].y - center.y) * scaleY + center.y
    end

    return self
end

---获取当前多边形缩放指定倍数的副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Polygon 缩放后的多边形副本
---@overload fun(self: foundation.shape.Polygon, scale: number): foundation.shape.Polygon 相对多边形中心点缩放指定倍数
function Polygon:scaled(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:centroid()

    local newPoints = {}
    for i = 0, self.size - 1 do
        newPoints[i + 1] = Vector2.create(
                (self.points[i].x - center.x) * scaleX + center.x,
                (self.points[i].y - center.y) * scaleY + center.y
        )
    end

    return Polygon.create(newPoints)
end

---判断点是否在多边形内（射线法）
---@param point foundation.math.Vector2 要判断的点
---@return boolean 如果点在多边形内或边上则返回true，否则返回false
function Polygon:contains(point)
    return ShapeIntersector.polygonContainsPoint(self, point)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Polygon:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---仅检查是否与其他形状相交
---@param other any
---@return boolean
function Polygon:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---判断多边形是否包含另一个多边形
---@param other foundation.shape.Polygon 另一个多边形
---@return boolean 如果当前多边形完全包含另一个多边形则返回true，否则返回false
function Polygon:containsPolygon(other)
    for i = 0, other.size - 1 do
        if not self:contains(other.points[i]) then
            return false
        end
    end

    return true
end

---计算点到多边形的最近点
---@param point foundation.math.Vector2 要检查的点
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector2 多边形上最近的点
---@overload fun(self: foundation.shape.Polygon, point: foundation.math.Vector2): foundation.math.Vector2
function Polygon:closestPoint(point, boundary)
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

---计算点到多边形的距离
---@param point foundation.math.Vector2 要检查的点
---@return number 点到多边形的距离
function Polygon:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end

    local closestPoint = self:closestPoint(point)
    return (point - closestPoint):length()
end

---将点投影到多边形上（2D中与closest相同）
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2 投影点
function Polygon:projectPoint(point)
    return self:closestPoint(point, true)
end

---检查点是否在多边形上
---@param point foundation.math.Vector2 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在多边形上
---@overload fun(self: foundation.shape.Polygon, point: foundation.math.Vector2): boolean
function Polygon:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local dist = self:distanceToPoint(point)
    if dist > tolerance then
        return false
    end

    for i = 0, self.size - 1 do
        local edge = Segment.create(self.points[i], self.points[(i + 1) % self.size])
        if edge:containsPoint(point, tolerance) then
            return true
        end
    end

    return false
end

---计算三角形的外接圆
---@param a foundation.math.Vector2
---@param b foundation.math.Vector2
---@param c foundation.math.Vector2
---@return foundation.math.Vector2 | nil, number
local function circumcircle(a, b, c)
    local d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
    if math.abs(d) < 1e-10 then
        return nil, math.huge
    end

    local ux = ((a.x * a.x + a.y * a.y) * (b.y - c.y) + (b.x * b.x + b.y * b.y) * (c.y - a.y) + (c.x * c.x + c.y * c.y) * (a.y - b.y)) / d
    local uy = ((a.x * a.x + a.y * a.y) * (c.x - b.x) + (b.x * b.x + b.y * b.y) * (a.x - c.x) + (c.x * c.x + c.y * c.y) * (b.x - a.x)) / d

    local center = Vector2.create(ux, uy)
    local radius = (center - a):length()
    return center, radius
end

---检查点是否在圆内
---@param p foundation.math.Vector2
---@param center foundation.math.Vector2
---@param radius number
---@return boolean
local function pointInCircle(p, center, radius)
    return (p - center):length() < radius - 1e-10
end

---创建超级三角形
---@param points foundation.math.Vector2[]
---@return foundation.math.Vector2[]
local function createSuperTriangle(points)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, p in ipairs(points) do
        minX = math.min(minX, p.x)
        minY = math.min(minY, p.y)
        maxX = math.max(maxX, p.x)
        maxY = math.max(maxY, p.y)
    end

    local dx = maxX - minX
    local dy = maxY - minY
    local dmax = math.max(dx, dy)
    local midx = (minX + maxX) / 2
    local midy = (minY + maxY) / 2

    return {
        Vector2.create(midx - 20 * dmax, midy - dmax),
        Vector2.create(midx, midy + 20 * dmax),
        Vector2.create(midx + 20 * dmax, midy - dmax)
    }
end

---检查边是否在多边形内部
---@param edge table
---@param polygon foundation.shape.Polygon
---@return boolean
local function isEdgeInPolygon(edge, polygon)
    local mid = (edge[1] + edge[2]) * 0.5
    return polygon:contains(mid)
end

---Delaunay三角剖分
---@param points foundation.math.Vector2[]
---@param polygon foundation.shape.Polygon
---@return foundation.shape.Triangle[]
local function delaunayTriangulation(points, polygon)
    if #points < 3 then return {} end

    local triangles = {}
    local superTriangle = createSuperTriangle(points)
    table.insert(triangles, Triangle.create(superTriangle[1], superTriangle[2], superTriangle[3]))

    for _, point in ipairs(points) do
        local edges = {}
        local badTriangles = {}

        for i = #triangles, 1, -1 do
            local triangle = triangles[i]
            local center, radius = circumcircle(triangle.p1, triangle.p2, triangle.p3)
            
            if center and pointInCircle(point, center, radius) then
                table.insert(badTriangles, i)
                table.insert(edges, {triangle.p1, triangle.p2})
                table.insert(edges, {triangle.p2, triangle.p3})
                table.insert(edges, {triangle.p3, triangle.p1})
            end
        end

        for i = #badTriangles, 1, -1 do
            table.remove(triangles, badTriangles[i])
        end

        local uniqueEdges = {}
        for _, edge in ipairs(edges) do
            local found = false
            for _, uniqueEdge in ipairs(uniqueEdges) do
                if (edge[1] == uniqueEdge[1] and edge[2] == uniqueEdge[2]) or
                   (edge[1] == uniqueEdge[2] and edge[2] == uniqueEdge[1]) then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(uniqueEdges, edge)
            end
        end

        for _, edge in ipairs(uniqueEdges) do
            if isEdgeInPolygon(edge, polygon) then
                table.insert(triangles, Triangle.create(edge[1], edge[2], point))
            end
        end
    end

    local result = {}
    for _, triangle in ipairs(triangles) do
        local inSuperTriangle = false
        for _, superPoint in ipairs(superTriangle) do
            if triangle.p1 == superPoint or triangle.p2 == superPoint or triangle.p3 == superPoint then
                inSuperTriangle = true
                break
            end
        end
        if not inSuperTriangle then
            table.insert(result, triangle)
        end
    end

    return result
end

---将多边形三角剖分（使用Delaunay三角剖分算法）
---@return foundation.shape.Triangle[] 三角形数组
function Polygon:triangulate()
    local points = {}
    for i = 0, self.size - 1 do
        points[i + 1] = self.points[i]:clone()
    end

    return delaunayTriangulation(points, self)
end

---复制当前多边形
---@return foundation.shape.Polygon 复制后的多边形
function Polygon:clone()
    local newPoints = {}
    for i = 0, self.size - 1 do
        newPoints[i + 1] = self.points[i]:clone()
    end
    return Polygon.create(newPoints)
end

ffi.metatype("foundation_shape_Polygon", Polygon)

return Polygon
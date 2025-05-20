local ffi = require("ffi")

local type = type
local ipairs = ipairs
local tostring = tostring
local string = string
local math = math
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Segment3D = require("foundation.shape3D.Segment3D")
local Shape3DIntersector = require("foundation.shape3D.Shape3DIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 point1, point2, point3;
} foundation_shape3D_Triangle3D;
]]

---@class foundation.shape3D.Triangle3D
---@field point1 foundation.math.Vector3 三角形的第一个顶点
---@field point2 foundation.math.Vector3 三角形的第二个顶点
---@field point3 foundation.math.Vector3 三角形的第三个顶点
local Triangle3D = {}
Triangle3D.__type = "foundation.shape3D.Triangle3D"

---@param self foundation.shape3D.Triangle3D
---@param key string
---@return any
function Triangle3D.__index(self, key)
    if key == "point1" then
        return self.__data.point1
    elseif key == "point2" then
        return self.__data.point2
    elseif key == "point3" then
        return self.__data.point3
    end
    return Triangle3D[key]
end

---@param self foundation.shape3D.Triangle3D
---@param key string
---@param value any
function Triangle3D.__newindex(self, key, value)
    if key == "point1" then
        self.__data.point1 = value
    elseif key == "point2" then
        self.__data.point2 = value
    elseif key == "point3" then
        self.__data.point3 = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的3D三角形
---@param v1 foundation.math.Vector3 三角形的第一个顶点
---@param v2 foundation.math.Vector3 三角形的第二个顶点
---@param v3 foundation.math.Vector3 三角形的第三个顶点
---@return foundation.shape3D.Triangle3D 新创建的三角形
function Triangle3D.create(v1, v2, v3)
    local triangle = ffi.new("foundation_shape3D_Triangle3D", v1, v2, v3)
    local result = {
        __data = triangle,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Triangle3D)
end

---3D三角形相等比较
---@param a foundation.shape3D.Triangle3D 第一个三角形
---@param b foundation.shape3D.Triangle3D 第二个三角形
---@return boolean 如果两个三角形的所有顶点都相等则返回true，否则返回false
function Triangle3D.__eq(a, b)
    return a.point1 == b.point1 and a.point2 == b.point2 and a.point3 == b.point3
end

---3D三角形转字符串表示
---@param t foundation.shape3D.Triangle3D 要转换的三角形
---@return string 三角形的字符串表示
function Triangle3D.__tostring(t)
    return string.format("Triangle3D(%s, %s, %s)", tostring(t.point1), tostring(t.point2), tostring(t.point3))
end

---计算3D三角形的面积
---@return number 三角形的面积
function Triangle3D:area()
    local v2v1 = self.point2 - self.point1
    local v3v1 = self.point3 - self.point1
    return 0.5 * (v2v1:cross(v3v1)):length()
end

---计算3D三角形的重心
---@return foundation.math.Vector3 三角形的重心
function Triangle3D:centroid()
    return (self.point1 + self.point2 + self.point3) / 3
end

---获取3D三角形的AABB包围盒
---@return number, number, number, number, number, number
function Triangle3D:AABB()
    local minX = math.min(self.point1.x, self.point2.x, self.point3.x)
    local maxX = math.max(self.point1.x, self.point2.x, self.point3.x)
    local minY = math.min(self.point1.y, self.point2.y, self.point3.y)
    local maxY = math.max(self.point1.y, self.point2.y, self.point3.y)
    local minZ = math.min(self.point1.z, self.point2.z, self.point3.z)
    local maxZ = math.max(self.point1.z, self.point2.z, self.point3.z)
    return minX, maxX, minY, maxY, minZ, maxZ
end

---计算3D三角形的中心
---@return foundation.math.Vector3 三角形的中心
function Triangle3D:getCenter()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return Vector3.create((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
end

---计算3D三角形的包围盒宽高深
---@return number, number, number
function Triangle3D:getBoundingBoxSize()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return maxX - minX, maxY - minY, maxZ - minZ
end

---计算3D三角形的法向量
---@return foundation.math.Vector3 三角形的法向量
function Triangle3D:normal()
    local v2v1 = self.point2 - self.point1
    local v3v1 = self.point3 - self.point1
    return v2v1:cross(v3v1):normalized()
end

---将当前3D三角形平移指定距离（更改当前三角形）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Triangle3D 移动后的三角形（自身引用）
function Triangle3D:move(v)
    local moveX, moveY, moveZ
    if type(v) == "number" then
        moveX = v
        moveY = v
        moveZ = v
    else
        moveX = v.x
        moveY = v.y
        moveZ = v.z
    end
    self.point1.x = self.point1.x + moveX
    self.point1.y = self.point1.y + moveY
    self.point1.z = self.point1.z + moveZ
    self.point2.x = self.point2.x + moveX
    self.point2.y = self.point2.y + moveY
    self.point2.z = self.point2.z + moveZ
    self.point3.x = self.point3.x + moveX
    self.point3.y = self.point3.y + moveY
    self.point3.z = self.point3.z + moveZ
    return self
end

---获取3D三角形平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Triangle3D 移动后的三角形副本
function Triangle3D:moved(v)
    local moveX, moveY, moveZ
    if type(v) == "number" then
        moveX = v
        moveY = v
        moveZ = v
    else
        moveX = v.x
        moveY = v.y
        moveZ = v.z
    end
    return Triangle3D.create(
            Vector3.create(self.point1.x + moveX, self.point1.y + moveY, self.point1.z + moveZ),
            Vector3.create(self.point2.x + moveX, self.point2.y + moveY, self.point2.z + moveZ),
            Vector3.create(self.point3.x + moveX, self.point3.y + moveY, self.point3.z + moveZ)
    )
end

---将当前3D三角形旋转指定弧度（更改当前三角形）
---@param axis foundation.math.Vector3 旋转轴
---@param rad number 旋转弧度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Triangle3D 旋转后的三角形（自身引用）
---@overload fun(self: foundation.shape3D.Triangle3D, axis: foundation.math.Vector3, rad: number): foundation.shape3D.Triangle3D 绕三角形重心旋转指定弧度
function Triangle3D:rotate(axis, rad, center)
    center = center or self:centroid()
    local rotated1 = self.point1:rotated(axis, rad)
    local rotated2 = self.point2:rotated(axis, rad)
    local rotated3 = self.point3:rotated(axis, rad)
    self.point1.x = rotated1.x
    self.point1.y = rotated1.y
    self.point1.z = rotated1.z
    self.point2.x = rotated2.x
    self.point2.y = rotated2.y
    self.point2.z = rotated2.z
    self.point3.x = rotated3.x
    self.point3.y = rotated3.y
    self.point3.z = rotated3.z
    return self
end

---将当前3D三角形旋转指定角度（更改当前三角形）
---@param axis foundation.math.Vector3 旋转轴
---@param angle number 旋转角度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Triangle3D 旋转后的三角形（自身引用）
---@overload fun(self: foundation.shape3D.Triangle3D, axis: foundation.math.Vector3, angle: number): foundation.shape3D.Triangle3D 绕三角形重心旋转指定角度
function Triangle3D:degreeRotate(axis, angle, center)
    angle = math.rad(angle)
    return self:rotate(axis, angle, center)
end

---获取3D三角形旋转指定弧度的副本
---@param axis foundation.math.Vector3 旋转轴
---@param rad number 旋转弧度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Triangle3D 旋转后的三角形副本
---@overload fun(self: foundation.shape3D.Triangle3D, axis: foundation.math.Vector3, rad: number): foundation.shape3D.Triangle3D 绕三角形重心旋转指定弧度
function Triangle3D:rotated(axis, rad, center)
    center = center or self:centroid()
    local rotated1 = self.point1:rotated(axis, rad)
    local rotated2 = self.point2:rotated(axis, rad)
    local rotated3 = self.point3:rotated(axis, rad)
    return Triangle3D.create(rotated1, rotated2, rotated3)
end

---获取3D三角形旋转指定角度的副本
---@param axis foundation.math.Vector3 旋转轴
---@param angle number 旋转角度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Triangle3D 旋转后的三角形副本
---@overload fun(self: foundation.shape3D.Triangle3D, axis: foundation.math.Vector3, angle: number): foundation.shape3D.Triangle3D 绕三角形重心旋转指定角度
function Triangle3D:degreeRotated(axis, angle, center)
    angle = math.rad(angle)
    return self:rotated(axis, angle, center)
end

---将当前3D三角形缩放指定倍数（更改当前三角形）
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心
---@return foundation.shape3D.Triangle3D 缩放后的三角形（自身引用）
---@overload fun(self: foundation.shape3D.Triangle3D, scale: number): foundation.shape3D.Triangle3D 相对三角形重心缩放指定倍数
function Triangle3D:scale(scale, center)
    local scaleX, scaleY, scaleZ
    if type(scale) == "number" then
        scaleX = scale
        scaleY = scale
        scaleZ = scale
    else
        scaleX = scale.x
        scaleY = scale.y
        scaleZ = scale.z
    end
    center = center or self:centroid()

    local dx1 = self.point1.x - center.x
    local dy1 = self.point1.y - center.y
    local dz1 = self.point1.z - center.z
    self.point1.x = center.x + dx1 * scaleX
    self.point1.y = center.y + dy1 * scaleY
    self.point1.z = center.z + dz1 * scaleZ

    local dx2 = self.point2.x - center.x
    local dy2 = self.point2.y - center.y
    local dz2 = self.point2.z - center.z
    self.point2.x = center.x + dx2 * scaleX
    self.point2.y = center.y + dy2 * scaleY
    self.point2.z = center.z + dz2 * scaleZ

    local dx3 = self.point3.x - center.x
    local dy3 = self.point3.y - center.y
    local dz3 = self.point3.z - center.z
    self.point3.x = center.x + dx3 * scaleX
    self.point3.y = center.y + dy3 * scaleY
    self.point3.z = center.z + dz3 * scaleZ
    return self
end

---获取3D三角形缩放指定倍数的副本
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心
---@return foundation.shape3D.Triangle3D 缩放后的三角形副本
---@overload fun(self: foundation.shape3D.Triangle3D, scale: number): foundation.shape3D.Triangle3D 相对三角形重心缩放指定倍数
function Triangle3D:scaled(scale, center)
    local result = Triangle3D.create(self.point1:clone(), self.point2:clone(), self.point3:clone())
    return result:scale(scale, center)
end

---获取3D三角形的顶点
---@return foundation.math.Vector3[]
function Triangle3D:getVertices()
    return {
        self.point1:clone(),
        self.point2:clone(),
        self.point3:clone()
    }
end

---获取3D三角形的边（线段）
---@return foundation.shape3D.Segment3D[]
function Triangle3D:getEdges()
    return {
        Segment3D.create(self.point1, self.point2),
        Segment3D.create(self.point2, self.point3),
        Segment3D.create(self.point3, self.point1)
    }
end

---计算3D三角形的周长
---@return number 三角形的周长
function Triangle3D:getPerimeter()
    local a = (self.point2 - self.point3):length()
    local b = (self.point1 - self.point3):length()
    local c = (self.point1 - self.point2):length()
    return a + b + c
end

---计算点到3D三角形的最近点
---@param point foundation.math.Vector3 要检查的点
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector3 三角形上最近的点
---@overload fun(self: foundation.shape3D.Triangle3D, point: foundation.math.Vector3): foundation.math.Vector3
function Triangle3D:closestPoint(point, boundary)
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

---计算点到3D三角形的距离
---@param point foundation.math.Vector3 要检查的点
---@return number 点到三角形的距离
function Triangle3D:distanceToPoint(point)
    return (point - self:closestPoint(point)):length()
end

---将点投影到3D三角形平面上
---@param point foundation.math.Vector3 要投影的点
---@return foundation.math.Vector3 投影点
function Triangle3D:projectPoint(point)
    local normal = self:normal()
    local v1p = point - self.point1
    local dist = v1p:dot(normal)
    return point - normal * dist
end

---检查点是否在3D三角形上
---@param point foundation.math.Vector3 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在三角形上
---@overload fun(self:foundation.shape3D.Triangle3D, point:foundation.math.Vector3): boolean
function Triangle3D:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:containsPoint(point, tolerance) then
            return true
        end
    end
    return false
end

---复制3D三角形
---@return foundation.shape3D.Triangle3D 三角形的副本
function Triangle3D:clone()
    return Triangle3D.create(self.point1:clone(), self.point2:clone(), self.point3:clone())
end

---检查点是否在三角形内
---@param point foundation.math.Vector3 要检查的点
---@return boolean 如果点在三角形内则返回true，否则返回false
function Triangle3D:contains(point)
    return Shape3DIntersector.triangleContainsPoint(self, point)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector3[] | nil
function Triangle3D:intersects(other)
    return Shape3DIntersector.intersect(self, other)
end

---只检查是否与其他形状相交
---@param other any
---@return boolean
function Triangle3D:hasIntersection(other)
    return Shape3DIntersector.hasIntersection(self, other)
end

ffi.metatype("foundation_shape3D_Triangle3D", Triangle3D)

return Triangle3D

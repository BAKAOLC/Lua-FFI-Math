local ffi = require("ffi")

local type = type
local ipairs = ipairs
local tostring = tostring
local string = string
local math = math
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Quaternion = require("foundation.math.Quaternion")
local Segment3D = require("foundation.shape3D.Segment3D")

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

---获取三角形的属性值
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

---设置三角形的属性值
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

---创建一个新的三角形
---@param v1 foundation.math.Vector3 三角形的第一个顶点
---@param v2 foundation.math.Vector3 三角形的第二个顶点
---@param v3 foundation.math.Vector3 三角形的第三个顶点
---@return foundation.shape3D.Triangle3D 新创建的三角形
function Triangle3D.create(v1, v2, v3)
    local triangle = ffi.new("foundation_shape3D_Triangle3D", v1, v2, v3)
    local result = {
        __data = triangle,
    }
    return setmetatable(result, Triangle3D)
end

---比较两个三角形是否相等
---@param a foundation.shape3D.Triangle3D 第一个三角形
---@param b foundation.shape3D.Triangle3D 第二个三角形
---@return boolean 如果两个三角形的所有顶点都相等则返回true，否则返回false
function Triangle3D.__eq(a, b)
    return a.point1 == b.point1 and a.point2 == b.point2 and a.point3 == b.point3
end

---将三角形转换为字符串表示
---@param t foundation.shape3D.Triangle3D 要转换的三角形
---@return string 三角形的字符串表示
function Triangle3D.__tostring(t)
    return string.format("Triangle3D(%s, %s, %s)", tostring(t.point1), tostring(t.point2), tostring(t.point3))
end

---创建三角形的副本
---@return foundation.shape3D.Triangle3D 三角形的副本
function Triangle3D:clone()
    return Triangle3D.create(self.point1:clone(), self.point2:clone(), self.point3:clone())
end

---计算三角形的面积
---@return number 三角形的面积
function Triangle3D:area()
    local v2v1 = self.point2 - self.point1
    local v3v1 = self.point3 - self.point1
    return 0.5 * (v2v1:cross(v3v1)):length()
end

---计算三角形的重心
---@return foundation.math.Vector3 三角形的重心
function Triangle3D:centroid()
    return (self.point1 + self.point2 + self.point3) / 3
end

---计算三角形的中心
---@return foundation.math.Vector3 三角形的中心
function Triangle3D:getCenter()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return Vector3.create((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
end

---计算三角形的法向量
---@return foundation.math.Vector3 三角形的法向量
function Triangle3D:normal()
    local v2v1 = self.point2 - self.point1
    local v3v1 = self.point3 - self.point1
    return v2v1:cross(v3v1):normalized()
end

---计算三角形的周长
---@return number 三角形的周长
function Triangle3D:getPerimeter()
    local a = (self.point2 - self.point3):length()
    local b = (self.point1 - self.point3):length()
    local c = (self.point1 - self.point2):length()
    return a + b + c
end

---将当前三角形平移指定距离
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

---获取三角形平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Triangle3D 移动后的三角形副本
function Triangle3D:moved(v)
    local result = self:clone()
    return result:move(v)
end

---使用欧拉角旋转三角形
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Triangle3D 自身引用
---@overload fun(self: foundation.shape3D.Triangle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Triangle3D
function Triangle3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转三角形的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Triangle3D 旋转后的三角形副本
---@overload fun(self: foundation.shape3D.Triangle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Triangle3D
function Triangle3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = self:clone()
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用四元数旋转三角形
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Triangle3D 自身引用
---@overload fun(self: foundation.shape3D.Triangle3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Triangle3D
function Triangle3D:rotateQuaternion(quaternion, center)
    center = center or self:centroid()
    local offset1 = self.point1 - center
    local offset2 = self.point2 - center
    local offset3 = self.point3 - center

    self.point1 = center + quaternion:rotateVector(offset1)
    self.point2 = center + quaternion:rotateVector(offset2)
    self.point3 = center + quaternion:rotateVector(offset3)

    return self
end

---使用四元数旋转三角形的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Triangle3D 旋转后的三角形副本
---@overload fun(self: foundation.shape3D.Triangle3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Triangle3D
function Triangle3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---使用角度制的欧拉角旋转三角形
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Triangle3D 自身引用
---@overload fun(self: foundation.shape3D.Triangle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Triangle3D
function Triangle3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转三角形的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Triangle3D 旋转后的三角形副本
---@overload fun(self: foundation.shape3D.Triangle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Triangle3D
function Triangle3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---将当前三角形缩放指定比例
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Triangle3D 缩放后的三角形（自身引用）
---@overload fun(self: foundation.shape3D.Triangle3D, scale: foundation.math.Vector3|number): foundation.shape3D.Triangle3D
function Triangle3D:scale(scale, center)
    center = center or self:centroid()
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
    local scaleVec = Vector3.create(scaleX, scaleY, scaleZ)
    self.point1 = center + (self.point1 - center) * scaleVec
    self.point2 = center + (self.point2 - center) * scaleVec
    self.point3 = center + (self.point3 - center) * scaleVec
    return self
end

---获取三角形缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Triangle3D 缩放后的三角形副本
---@overload fun(self: foundation.shape3D.Triangle3D, scale: foundation.math.Vector3|number): foundation.shape3D.Triangle3D
function Triangle3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---获取三角形的边
---@return foundation.shape3D.Segment3D[] 三角形的三条边
function Triangle3D:getEdges()
    return {
        Segment3D.create(self.point1:clone(), self.point2:clone()),
        Segment3D.create(self.point2:clone(), self.point3:clone()),
        Segment3D.create(self.point3:clone(), self.point1:clone())
    }
end

---获取三角形的顶点
---@return foundation.math.Vector3[] 三角形的三个顶点
function Triangle3D:getVertices()
    return {
        self.point1:clone(),
        self.point2:clone(),
        self.point3:clone()
    }
end

---计算三角形的AABB（轴对齐包围盒）
---@return number minX 最小X坐标
---@return number maxX 最大X坐标
---@return number minY 最小Y坐标
---@return number maxY 最大Y坐标
---@return number minZ 最小Z坐标
---@return number maxZ 最大Z坐标
function Triangle3D:AABB()
    local minX = math.min(self.point1.x, self.point2.x, self.point3.x)
    local maxX = math.max(self.point1.x, self.point2.x, self.point3.x)
    local minY = math.min(self.point1.y, self.point2.y, self.point3.y)
    local maxY = math.max(self.point1.y, self.point2.y, self.point3.y)
    local minZ = math.min(self.point1.z, self.point2.z, self.point3.z)
    local maxZ = math.max(self.point1.z, self.point2.z, self.point3.z)
    return minX, maxX, minY, maxY, minZ, maxZ
end

---检查点是否在三角形内部或边上
---@param point foundation.math.Vector3 要检查的点
---@return boolean 如果点在三角形内部或边上则返回true，否则返回false
function Triangle3D:containsPoint(point)
    local v0 = self.point3 - self.point1
    local v1 = self.point2 - self.point1
    local v2 = point - self.point1

    local dot00 = v0:dot(v0)
    local dot01 = v0:dot(v1)
    local dot02 = v0:dot(v2)
    local dot11 = v1:dot(v1)
    local dot12 = v1:dot(v2)

    local invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
    local u = (dot11 * dot02 - dot01 * dot12) * invDenom
    local v = (dot00 * dot12 - dot01 * dot02) * invDenom

    return u >= 0 and v >= 0 and u + v <= 1
end

---计算点到三角形的最短距离
---@param point foundation.math.Vector3 要计算距离的点
---@return number 点到三角形的最短距离
function Triangle3D:distanceToPoint(point)
    local normal = self:normal()
    local v0 = self.point3 - self.point1
    local v1 = self.point2 - self.point1
    local v2 = point - self.point1

    local dot00 = v0:dot(v0)
    local dot01 = v0:dot(v1)
    local dot02 = v0:dot(v2)
    local dot11 = v1:dot(v1)
    local dot12 = v1:dot(v2)

    local invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
    local u = (dot11 * dot02 - dot01 * dot12) * invDenom
    local v = (dot00 * dot12 - dot01 * dot02) * invDenom

    if u >= 0 and v >= 0 and u + v <= 1 then
        local projection = v2:dot(normal)
        return math.abs(projection)
    end

    local edges = self:getEdges()
    local minDist = math.huge
    for _, edge in ipairs(edges) do
        local dist = edge:distanceToPoint(point)
        minDist = math.min(minDist, dist)
    end
    return minDist
end

---计算点到三角形的投影点
---@param point foundation.math.Vector3 要投影的点
---@return foundation.math.Vector3 点在三角形上的投影点
function Triangle3D:projectPoint(point)
    local normal = self:normal()
    local v0 = self.point3 - self.point1
    local v1 = self.point2 - self.point1
    local v2 = point - self.point1

    local dot00 = v0:dot(v0)
    local dot01 = v0:dot(v1)
    local dot02 = v0:dot(v2)
    local dot11 = v1:dot(v1)
    local dot12 = v1:dot(v2)

    local invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
    local u = (dot11 * dot02 - dot01 * dot12) * invDenom
    local v = (dot00 * dot12 - dot01 * dot02) * invDenom

    if u >= 0 and v >= 0 and u + v <= 1 then
        local projection = v2:dot(normal)
        return point - normal * projection
    end

    local edges = self:getEdges()
    local minDist = math.huge
    local closestPoint = nil
    for _, edge in ipairs(edges) do
        local proj = edge:projectPoint(point)
        local dist = (proj - point):length()
        if dist < minDist then
            minDist = dist
            closestPoint = proj
        end
    end
    return closestPoint
end

ffi.metatype("foundation_shape3D_Triangle3D", Triangle3D)

return Triangle3D

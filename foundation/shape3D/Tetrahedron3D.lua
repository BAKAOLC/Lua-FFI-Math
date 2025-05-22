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
local Triangle3D = require("foundation.shape3D.Triangle3D")
local Shape3DIntersector = require("foundation.shape3D.Shape3DIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 point1, point2, point3, point4;
} foundation_shape3D_Tetrahedron3D;
]]

---@class foundation.shape3D.Tetrahedron3D
---@field point1 foundation.math.Vector3 四面体的第一个顶点
---@field point2 foundation.math.Vector3 四面体的第二个顶点
---@field point3 foundation.math.Vector3 四面体的第三个顶点
---@field point4 foundation.math.Vector3 四面体的第四个顶点
local Tetrahedron3D = {}
Tetrahedron3D.__type = "foundation.shape3D.Tetrahedron3D"

---@param self foundation.shape3D.Tetrahedron3D
---@param key string
---@return any
function Tetrahedron3D.__index(self, key)
    if key == "point1" then
        return self.__data.point1
    elseif key == "point2" then
        return self.__data.point2
    elseif key == "point3" then
        return self.__data.point3
    elseif key == "point4" then
        return self.__data.point4
    end
    return Tetrahedron3D[key]
end

---@param self foundation.shape3D.Tetrahedron3D
---@param key string
---@param value any
function Tetrahedron3D.__newindex(self, key, value)
    if key == "point1" then
        self.__data.point1 = value
    elseif key == "point2" then
        self.__data.point2 = value
    elseif key == "point3" then
        self.__data.point3 = value
    elseif key == "point4" then
        self.__data.point4 = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的3D四面体
---@param v1 foundation.math.Vector3 四面体的第一个顶点
---@param v2 foundation.math.Vector3 四面体的第二个顶点
---@param v3 foundation.math.Vector3 四面体的第三个顶点
---@param v4 foundation.math.Vector3 四面体的第四个顶点
---@return foundation.shape3D.Tetrahedron3D 新创建的四面体
function Tetrahedron3D.create(v1, v2, v3, v4)
    local tetrahedron = ffi.new("foundation_shape3D_Tetrahedron3D", v1, v2, v3, v4)
    local result = {
        __data = tetrahedron,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Tetrahedron3D)
end

---3D四面体相等比较
---@param a foundation.shape3D.Tetrahedron3D 第一个四面体
---@param b foundation.shape3D.Tetrahedron3D 第二个四面体
---@return boolean 如果两个四面体的所有顶点都相等则返回true，否则返回false
function Tetrahedron3D.__eq(a, b)
    return a.point1 == b.point1 and a.point2 == b.point2 and a.point3 == b.point3 and a.point4 == b.point4
end

---3D四面体转字符串表示
---@param t foundation.shape3D.Tetrahedron3D 要转换的四面体
---@return string 四面体的字符串表示
function Tetrahedron3D.__tostring(t)
    return string.format("Tetrahedron3D(%s, %s, %s, %s)",
        tostring(t.point1), tostring(t.point2), tostring(t.point3), tostring(t.point4))
end

---计算3D四面体的体积
---@return number 四面体的体积
function Tetrahedron3D:volume()
    local v1 = self.point2 - self.point1
    local v2 = self.point3 - self.point1
    local v3 = self.point4 - self.point1
    return math.abs(v1:dot(v2:cross(v3))) / 6
end

---计算3D四面体的重心
---@return foundation.math.Vector3 四面体的重心
function Tetrahedron3D:centroid()
    return (self.point1 + self.point2 + self.point3 + self.point4) / 4
end

---计算3D四面体的中心
---@return foundation.math.Vector3 四面体的中心
function Tetrahedron3D:getCenter()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return Vector3.create((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
end

---获取四面体的四个面
---@return foundation.shape3D.Triangle3D[] 四面体的四个面
function Tetrahedron3D:getFaces()
    return {
        Triangle3D.create(self.point1, self.point2, self.point3),
        Triangle3D.create(self.point1, self.point2, self.point4),
        Triangle3D.create(self.point1, self.point3, self.point4),
        Triangle3D.create(self.point2, self.point3, self.point4)
    }
end

---计算3D四面体的表面积
---@return number 四面体的表面积
function Tetrahedron3D:surfaceArea()
    local faces = self:getFaces()
    local area = 0
    for _, face in ipairs(faces) do
        area = area + face:area()
    end
    return area
end

---将当前3D四面体平移指定距离（更改当前四面体）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Tetrahedron3D 移动后的四面体（自身引用）
function Tetrahedron3D:move(v)
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
    self.point4.x = self.point4.x + moveX
    self.point4.y = self.point4.y + moveY
    self.point4.z = self.point4.z + moveZ
    return self
end

---获取3D四面体平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Tetrahedron3D 移动后的四面体副本
function Tetrahedron3D:moved(v)
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
    return Tetrahedron3D.create(
        Vector3.create(self.point1.x + moveX, self.point1.y + moveY, self.point1.z + moveZ),
        Vector3.create(self.point2.x + moveX, self.point2.y + moveY, self.point2.z + moveZ),
        Vector3.create(self.point3.x + moveX, self.point3.y + moveY, self.point3.z + moveZ),
        Vector3.create(self.point4.x + moveX, self.point4.y + moveY, self.point4.z + moveZ)
    )
end

---使用欧拉角旋转四面体（更改当前四面体）
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为四面体重心
---@return foundation.shape3D.Tetrahedron3D 自身引用
function Tetrahedron3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转四面体的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为四面体重心
---@return foundation.shape3D.Tetrahedron3D 旋转后的四面体副本
function Tetrahedron3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = Tetrahedron3D.create(self.point1, self.point2, self.point3, self.point4)
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用角度制的欧拉角旋转四面体（更改当前四面体）
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为四面体重心
---@return foundation.shape3D.Tetrahedron3D 自身引用
function Tetrahedron3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转四面体的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为四面体重心
---@return foundation.shape3D.Tetrahedron3D 旋转后的四面体副本
function Tetrahedron3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用四元数旋转四面体（更改当前四面体）
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为四面体重心
---@return foundation.shape3D.Tetrahedron3D 自身引用
function Tetrahedron3D:rotateQuaternion(quaternion, center)
    center = center or self:centroid()
    self.point1 = quaternion:rotatePoint(self.point1 - center) + center
    self.point2 = quaternion:rotatePoint(self.point2 - center) + center
    self.point3 = quaternion:rotatePoint(self.point3 - center) + center
    self.point4 = quaternion:rotatePoint(self.point4 - center) + center
    return self
end

---计算3D四面体的轴对齐包围盒（AABB）
---@return number minX 最小X坐标
---@return number maxX 最大X坐标
---@return number minY 最小Y坐标
---@return number maxY 最大Y坐标
---@return number minZ 最小Z坐标
---@return number maxZ 最大Z坐标
function Tetrahedron3D:AABB()
    local minX = math.min(self.point1.x, self.point2.x, self.point3.x, self.point4.x)
    local maxX = math.max(self.point1.x, self.point2.x, self.point3.x, self.point4.x)
    local minY = math.min(self.point1.y, self.point2.y, self.point3.y, self.point4.y)
    local maxY = math.max(self.point1.y, self.point2.y, self.point3.y, self.point4.y)
    local minZ = math.min(self.point1.z, self.point2.z, self.point3.z, self.point4.z)
    local maxZ = math.max(self.point1.z, self.point2.z, self.point3.z, self.point4.z)
    return minX, maxX, minY, maxY, minZ, maxZ
end

---获取四面体的所有顶点
---@return foundation.math.Vector3[] 四面体的顶点数组
function Tetrahedron3D:getVertices()
    return {
        self.point1:clone(),
        self.point2:clone(),
        self.point3:clone(),
        self.point4:clone()
    }
end

---获取四面体的包围盒尺寸
---@return foundation.math.Vector3 包围盒的尺寸
function Tetrahedron3D:getBoundingBoxSize()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return Vector3.create(maxX - minX, maxY - minY, maxZ - minZ)
end

---计算点到四面体表面的最短距离
---@param point foundation.math.Vector3 要计算距离的点
---@return number 点到四面体表面的最短距离，如果点在四面体内部则返回负值
function Tetrahedron3D:distanceToPoint(point)
    local faces = self:getFaces()
    local minDistance = math.huge
    local isInside = true

    for _, face in ipairs(faces) do
        local distance = face:distanceToPoint(point)
        minDistance = math.min(minDistance, math.abs(distance))
        if distance > 0 then
            isInside = false
        end
    end

    return isInside and -minDistance or minDistance
end

---将点投影到四面体表面上
---@param point foundation.math.Vector3 要投影的点
---@return foundation.math.Vector3 投影点
function Tetrahedron3D:projectPoint(point)
    local faces = self:getFaces()
    local minDistance = math.huge
    local projectedPoint

    for _, face in ipairs(faces) do
        local proj = face:projectPoint(point)
        local distance = (proj - point):length()
        if distance < minDistance then
            minDistance = distance
            projectedPoint = proj
        end
    end

    return projectedPoint
end

---检查点是否在四面体内部或表面上
---@param point foundation.math.Vector3 要检查的点
---@return boolean 如果点在四面体内部或表面上则返回true，否则返回false
function Tetrahedron3D:containsPoint(point)
    local faces = self:getFaces()
    for _, face in ipairs(faces) do
        if face:distanceToPoint(point) > 0 then
            return false
        end
    end
    return true
end

---使用四元数旋转四面体的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为四面体重心
---@return foundation.shape3D.Tetrahedron3D 旋转后的四面体副本
function Tetrahedron3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---将当前四面体缩放指定比例（更改当前四面体）
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3|nil 缩放中心点，默认为四面体重心
---@return foundation.shape3D.Tetrahedron3D 缩放后的四面体（自身引用）
function Tetrahedron3D:scale(scale, center)
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
    self.point4 = center + (self.point4 - center) * scaleVec
    return self
end

---获取四面体缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3|nil 缩放中心点，默认为四面体重心
---@return foundation.shape3D.Tetrahedron3D 缩放后的四面体副本
function Tetrahedron3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---创建四面体的副本
---@return foundation.shape3D.Tetrahedron3D 四面体的副本
function Tetrahedron3D:clone()
    return Tetrahedron3D.create(self.point1, self.point2, self.point3, self.point4)
end

return Tetrahedron3D

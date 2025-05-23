local ffi = require("ffi")

local type = type
local tostring = tostring
local string = string
local math = math
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Quaternion = require("foundation.math.Quaternion")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 point1, point2;
} foundation_shape3D_Segment3D;
]]

---@class foundation.shape3D.Segment3D
---@field point1 foundation.math.Vector3
---@field point2 foundation.math.Vector3
local Segment3D = {}
Segment3D.__type = "foundation.shape3D.Segment3D"

---@param self foundation.shape3D.Segment3D
---@param key any
---@return any
function Segment3D.__index(self, key)
    if key == "point1" then
        return self.__data.point1
    elseif key == "point2" then
        return self.__data.point2
    end
    return Segment3D[key]
end

---@param self foundation.shape3D.Segment3D
---@param key any
---@param value any
function Segment3D.__newindex(self, key, value)
    if key == "point1" then
        self.__data.point1 = value
    elseif key == "point2" then
        self.__data.point2 = value
    else
        rawset(self, key, value)
    end
end

---创建一个3D线段
---@param point1 foundation.math.Vector3 线段的起点
---@param point2 foundation.math.Vector3 线段的终点
---@return foundation.shape3D.Segment3D
function Segment3D.create(point1, point2)
    local segment = ffi.new("foundation_shape3D_Segment3D", point1, point2)
    local result = {
        __data = segment,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Segment3D)
end

---根据弧度创建一个新的线段
---@param start foundation.math.Vector3 起点
---@param theta number 仰角（与XY平面的夹角，范围[-π,π]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
---@param length number 线段长度
---@return foundation.shape3D.Segment3D 新创建的线段
function Segment3D.createFromRad(start, theta, phi, length)
    local direction = Vector3.createFromRad(theta, phi)
    local end_point = start + direction * length
    return Segment3D.create(start, end_point)
end

---根据角度创建一个新的线段
---@param start foundation.math.Vector3 起点
---@param theta number 仰角（与XY平面的夹角，范围[-180,180]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
---@param length number 线段长度
---@return foundation.shape3D.Segment3D 新创建的线段
function Segment3D.createFromAngle(start, theta, phi, length)
    return Segment3D.createFromRad(start, math.rad(theta), math.rad(phi), length)
end

---3D线段相等比较
---@param a foundation.shape3D.Segment3D 第一个线段
---@param b foundation.shape3D.Segment3D 第二个线段
---@return boolean 如果两个线段的所有顶点都相等则返回true，否则返回false
function Segment3D.__eq(a, b)
    return a.point1 == b.point1 and a.point2 == b.point2
end

---3D线段转字符串表示
---@param self foundation.shape3D.Segment3D
---@return string 线段的字符串表示
function Segment3D.__tostring(self)
    return string.format("Segment3D(%s, %s)", tostring(self.point1), tostring(self.point2))
end

---将3D线段转换为向量
---@return foundation.math.Vector3 从起点到终点的向量
function Segment3D:toVector3()
    return self.point2 - self.point1
end

---获取3D线段的法向量
---@return foundation.math.Vector3 线段的单位法向量
function Segment3D:normal()
    local dir = self:toVector3()
    local len = dir:length()
    if len <= 1e-10 then
        return Vector3.zero()
    end
    local up = Vector3.create(0, 1, 0)
    local normal = dir:cross(up)
    if normal:length() <= 1e-10 then
        up = Vector3.create(0, 0, 1)
        normal = dir:cross(up)
    end
    return normal:normalized()
end

---获取3D线段的长度
---@return number 线段的长度
function Segment3D:length()
    return self:toVector3():length()
end

---获取3D线段的中点
---@return foundation.math.Vector3 线段的中点
function Segment3D:midpoint()
    return Vector3.create(
        (self.point1.x + self.point2.x) / 2,
        (self.point1.y + self.point2.y) / 2,
        (self.point1.z + self.point2.z) / 2
    )
end

---获取3D线段的角度（弧度）
---@return number, number 仰角（与XY平面的夹角，范围[-π,π]）和方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
function Segment3D:angle()
    return self:toVector3():angle()
end

---获取3D线段的角度（度）
---@return number, number 仰角（与XY平面的夹角，范围[-180,180]）和方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
function Segment3D:degreeAngle()
    return self:toVector3():degreeAngle()
end

---获取线段的旋转四元数
---@return foundation.math.Quaternion 从默认方向(1,0,0)旋转到当前方向的四元数
function Segment3D:getRotation()
    local dir = self:toVector3()
    local len = dir:length()
    if len <= 1e-10 then
        return Quaternion.identity()
    end
    dir = dir:normalized()

    local defaultDir = Vector3.create(1, 0, 0)
    local axis = defaultDir:cross(dir)
    local axisLen = axis:length()
    if axisLen <= 1e-10 then
        if dir:dot(defaultDir) > 0 then
            return Quaternion.identity()
        else
            return Quaternion.createFromAxisAngle(Vector3.create(0, 1, 0), math.pi)
        end
    end
    local angle = math.acos(defaultDir:dot(dir))
    return Quaternion.createFromAxisAngle(axis:normalized(), angle)
end

---计算3D线段的中心
---@return foundation.math.Vector3 线段的中心
function Segment3D:getCenter()
    return self:midpoint()
end

---计算3D线段的取点
---@param t number 取点参数，范围0到1
---@return foundation.math.Vector3 线段上t位置的点
function Segment3D:getPoint(t)
    return self.point1 + (self.point2 - self.point1) * t
end

---获取3D线段的AABB包围盒
---@return number, number, number, number, number, number
function Segment3D:AABB()
    local minX = math.min(self.point1.x, self.point2.x)
    local maxX = math.max(self.point1.x, self.point2.x)
    local minY = math.min(self.point1.y, self.point2.y)
    local maxY = math.max(self.point1.y, self.point2.y)
    local minZ = math.min(self.point1.z, self.point2.z)
    local maxZ = math.max(self.point1.z, self.point2.z)
    return minX, maxX, minY, maxY, minZ, maxZ
end

---计算3D线段的包围盒宽高深
---@return number, number, number
function Segment3D:getBoundingBoxSize()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return maxX - minX, maxY - minY, maxZ - minZ
end

---将当前3D线段平移指定距离（更改当前线段）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Segment3D 移动后的线段（自身引用）
function Segment3D:move(v)
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
    return self
end

---获取3D线段平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Segment3D 移动后的线段副本
function Segment3D:moved(v)
    return self:clone():move(v)
end

---使用四元数旋转线段
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Segment3D 自身引用
---@overload fun(self: foundation.shape3D.Segment3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Segment3D
function Segment3D:rotateQuaternion(quaternion, center)
    center = center or self.point1
    self.point1 = quaternion:rotatePoint(self.point1 - center) + center
    self.point2 = quaternion:rotatePoint(self.point2 - center) + center
    return self
end

---使用四元数旋转线段的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Segment3D 旋转后的线段副本
---@overload fun(self: foundation.shape3D.Segment3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Segment3D
function Segment3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---使用欧拉角旋转线段
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Segment3D 自身引用
---@overload fun(self: foundation.shape3D.Segment3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Segment3D
function Segment3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转线段的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Segment3D 旋转后的线段副本
---@overload fun(self: foundation.shape3D.Segment3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Segment3D
function Segment3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = self:clone()
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用角度制的欧拉角旋转线段
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Segment3D 自身引用
---@overload fun(self: foundation.shape3D.Segment3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Segment3D
function Segment3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转线段的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Segment3D 旋转后的线段副本
---@overload fun(self: foundation.shape3D.Segment3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Segment3D
function Segment3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---将当前线段缩放指定比例
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Segment3D 缩放后的线段（自身引用）
---@overload fun(self: foundation.shape3D.Segment3D, scale: foundation.math.Vector3|number): foundation.shape3D.Segment3D
function Segment3D:scale(scale, center)
    center = center or self.point1
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
    return self
end

---获取线段缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Segment3D 缩放后的线段副本
---@overload fun(self: foundation.shape3D.Segment3D, scale: foundation.math.Vector3|number): foundation.shape3D.Segment3D
function Segment3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---计算点到3D线段的最近点
---@param point foundation.math.Vector3 点
---@return foundation.math.Vector3 最近点
function Segment3D:closestPoint(point)
    local dir = self:toVector3()
    local len = dir:length()
    if len <= 1e-10 then
        return self.point1:clone()
    end

    local t = (point - self.point1):dot(dir) / len
    if t < 0 then
        return self.point1:clone()
    elseif t > 1 then
        return self.point2:clone()
    end
    return Vector3.create(
        self.point1.x + dir.x * t,
        self.point1.y + dir.y * t,
        self.point1.z + dir.z * t
    )
end

---计算点到3D线段的距离
---@param point foundation.math.Vector3 点
---@return number 距离
function Segment3D:distanceToPoint(point)
    return (point - self:closestPoint(point)):length()
end

---检查点是否在3D线段上
---@param point foundation.math.Vector3 点
---@param tolerance number 容差
---@return boolean
function Segment3D:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local dist = self:distanceToPoint(point)
    return dist <= tolerance
end

---获取点在3D线段上的投影
---@param point foundation.math.Vector3 点
---@return foundation.math.Vector3 投影点
function Segment3D:projectPoint(point)
    local dir = self:toVector3()
    local len = dir:length()
    if len <= 1e-10 then
        return self.point1:clone()
    end
    local t = (point - self.point1):dot(dir) / len
    return Vector3.create(
        self.point1.x + dir.x * t,
        self.point1.y + dir.y * t,
        self.point1.z + dir.z * t
    )
end

---复制3D线段
---@return foundation.shape3D.Segment3D 复制的线段
function Segment3D:clone()
    return Segment3D.create(self.point1:clone(), self.point2:clone())
end

ffi.metatype("foundation_shape3D_Segment3D", Segment3D)

return Segment3D

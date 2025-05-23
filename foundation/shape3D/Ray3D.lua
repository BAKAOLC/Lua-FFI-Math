local ffi = require("ffi")

local type = type
local math = math
local tostring = tostring
local string = string
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Quaternion = require("foundation.math.Quaternion")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 point;
    foundation_math_Vector3 direction;
} foundation_shape3D_Ray3D;
]]

---@class foundation.shape3D.Ray3D
---@field point foundation.math.Vector3 射线的起始点
---@field direction foundation.math.Vector3 射线的方向向量
local Ray3D = {}
Ray3D.__type = "foundation.shape3D.Ray3D"

---@param self foundation.shape3D.Ray3D
---@param key any
---@return any
function Ray3D.__index(self, key)
    if key == "point" then
        return self.__data.point
    elseif key == "direction" then
        return self.__data.direction
    end
    return Ray3D[key]
end

---@param self foundation.shape3D.Ray3D
---@param key any
---@param value any
function Ray3D.__newindex(self, key, value)
    if key == "point" then
        self.__data.point = value
    elseif key == "direction" then
        self.__data.direction = value
    else
        rawset(self, key, value)
    end
end

---创建一条新的3D射线，由起始点和方向向量确定
---@param point foundation.math.Vector3 起始点
---@param direction foundation.math.Vector3 方向向量
---@return foundation.shape3D.Ray3D
function Ray3D.create(point, direction)
    if direction then
        local dist = direction:length()
        if dist <= 1e-10 then
            direction = Vector3.create(1, 0, 0)
        elseif dist ~= 1 then
            direction = direction:normalized()
        end
    else
        direction = Vector3.create(1, 0, 0)
    end

    local ray = ffi.new("foundation_shape3D_Ray3D", point, direction)
    local result = {
        __data = ray,
    }
    return setmetatable(result, Ray3D)
end

---根据弧度创建一个新的射线
---@param origin foundation.math.Vector3 起点
---@param theta number 仰角（与XY平面的夹角，范围[-π,π]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
---@return foundation.shape3D.Ray3D 新创建的射线
function Ray3D.createFromRad(origin, theta, phi)
    local direction = Vector3.createFromRad(theta, phi)
    return Ray3D.create(origin, direction)
end

---根据角度创建一个新的射线
---@param origin foundation.math.Vector3 起点
---@param theta number 仰角（与XY平面的夹角，范围[-180,180]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
---@return foundation.shape3D.Ray3D 新创建的射线
function Ray3D.createFromAngle(origin, theta, phi)
    return Ray3D.createFromRad(origin, math.rad(theta), math.rad(phi))
end

---3D射线相等比较
---@param a foundation.shape3D.Ray3D
---@param b foundation.shape3D.Ray3D
---@return boolean
function Ray3D.__eq(a, b)
    return a.point == b.point and a.direction == b.direction
end

---3D射线的字符串表示
---@param self foundation.shape3D.Ray3D
---@return string
function Ray3D.__tostring(self)
    return string.format("Ray3D(point=%s, direction=%s)", tostring(self.point), tostring(self.direction))
end

---获取3D射线上相对起始点指定距离的点
---@param length number 距离
---@return foundation.math.Vector3
function Ray3D:getPoint(length)
    return self.point + self.direction * length
end

---计算3D射线的中心
---@return foundation.math.Vector3
function Ray3D:getCenter()
    return self.point
end

---平移3D射线（更改当前射线）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Ray3D 平移后的射线（自身引用）
function Ray3D:move(v)
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
    self.point.x = self.point.x + moveX
    self.point.y = self.point.y + moveY
    self.point.z = self.point.z + moveZ
    return self
end

---获取当前3D射线平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Ray3D 移动后的射线副本
function Ray3D:moved(v)
    return self:clone():move(v)
end

---使用欧拉角旋转射线
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Ray3D 自身引用
---@overload fun(self: foundation.shape3D.Ray3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Ray3D
function Ray3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转射线的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Ray3D 旋转后的射线副本
---@overload fun(self: foundation.shape3D.Ray3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Ray3D
function Ray3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = self:clone()
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用角度制的欧拉角旋转射线
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Ray3D 自身引用
---@overload fun(self: foundation.shape3D.Ray3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Ray3D
function Ray3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转射线的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Ray3D 旋转后的射线副本
---@overload fun(self: foundation.shape3D.Ray3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Ray3D
function Ray3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用四元数旋转射线
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Ray3D 自身引用
---@overload fun(self: foundation.shape3D.Ray3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Ray3D
function Ray3D:rotateQuaternion(quaternion, center)
    center = center or self.point
    self.point = quaternion:rotatePoint(self.point - center) + center
    self.direction = quaternion:rotateVector(self.direction)
    return self
end

---使用四元数旋转射线的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Ray3D 旋转后的射线副本
---@overload fun(self: foundation.shape3D.Ray3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Ray3D
function Ray3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---将当前射线缩放指定比例
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Ray3D 缩放后的射线（自身引用）
---@overload fun(self: foundation.shape3D.Ray3D, scale: foundation.math.Vector3|number): foundation.shape3D.Ray3D
function Ray3D:scale(scale, center)
    center = center or self.point
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
    self.point.x = center.x + (self.point.x - center.x) * scaleVec.x
    self.point.y = center.y + (self.point.y - center.y) * scaleVec.y
    self.point.z = center.z + (self.point.z - center.z) * scaleVec.z
    self.direction = self.direction * scaleVec
    return self
end

---获取射线缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Ray3D 缩放后的射线副本
---@overload fun(self: foundation.shape3D.Ray3D, scale: foundation.math.Vector3|number): foundation.shape3D.Ray3D
function Ray3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---计算3D射线的AABB包围盒
---@return number, number, number, number, number, number
function Ray3D:AABB()
    local minX, maxX = self.point.x, math.huge
    local minY, maxY = self.point.y, math.huge
    local minZ, maxZ = self.point.z, math.huge
    if self.direction.x < 0 then
        minX, maxX = -math.huge, self.point.x
    end
    if self.direction.y < 0 then
        minY, maxY = -math.huge, self.point.y
    end
    if self.direction.z < 0 then
        minZ, maxZ = -math.huge, self.point.z
    end
    return minX, maxX, minY, maxY, minZ, maxZ
end

---计算3D射线的包围盒宽高深
---@return number, number, number
function Ray3D:getBoundingBoxSize()
    return math.huge, math.huge, math.huge
end

---获取射线的角度（弧度）
---@return number, number 仰角（与XY平面的夹角，范围[-π,π]）和方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
function Ray3D:angle()
    return self.direction:angle()
end

---获取射线的角度（度）
---@return number, number 仰角（与XY平面的夹角，范围[-180,180]）和方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
function Ray3D:degreeAngle()
    return self.direction:degreeAngle()
end

---获取射线的旋转四元数
---@return foundation.math.Quaternion 从默认方向(1,0,0)旋转到当前方向的四元数
function Ray3D:getRotation()
    local defaultDir = Vector3.create(1, 0, 0)
    local axis = defaultDir:cross(self.direction)
    local len = axis:length()
    if len <= 1e-10 then
        if self.direction:dot(defaultDir) > 0 then
            return Quaternion.identity()
        else
            return Quaternion.createFromAxisAngle(Vector3.create(0, 1, 0), math.pi)
        end
    end
    local angle = math.acos(defaultDir:dot(self.direction))
    return Quaternion.createFromAxisAngle(axis:normalized(), angle)
end

---计算点到3D射线的最近点
---@param point foundation.math.Vector3 点
---@return foundation.math.Vector3 最近点
function Ray3D:closestPoint(point)
    local v = point - self.point
    local t = v:dot(self.direction)
    if t < 0 then
        return self.point
    end
    return self.point + self.direction * t
end

---计算点到3D射线的距离
---@param point foundation.math.Vector3 点
---@return number 距离
function Ray3D:distanceToPoint(point)
    return (point - self:closestPoint(point)):length()
end

---检查点是否在3D射线上
---@param point foundation.math.Vector3 点
---@param tolerance number 容差
---@return boolean
function Ray3D:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local v = point - self.point
    local t = v:dot(self.direction)
    if t < 0 then
        return false
    end
    local cross = v:cross(self.direction)
    return cross:length() <= tolerance
end

---获取点在3D射线上的投影
---@param point foundation.math.Vector3 点
---@return foundation.math.Vector3 投影点
function Ray3D:projectPoint(point)
    local v = point - self.point
    local t = v:dot(self.direction)
    return self.point + self.direction * t
end

---复制3D射线
---@return foundation.shape3D.Ray3D 复制的射线
function Ray3D:clone()
    return Ray3D.create(self.point:clone(), self.direction:clone())
end

ffi.metatype("foundation_shape3D_Ray3D", Ray3D)

return Ray3D

local ffi = require("ffi")

local type = type
local math = math
local tostring = tostring
local string = string
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Quaternion = require("foundation.math.Quaternion")
local Shape3DIntersector = require("foundation.shape3D.Shape3DIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 point;
    foundation_math_Vector3 direction;
} foundation_shape3D_Line3D;
]]

---@class foundation.shape3D.Line3D
---@field point foundation.math.Vector3 直线的起点
---@field direction foundation.math.Vector3 直线的方向向量
local Line3D = {}
Line3D.__type = "foundation.shape3D.Line3D"

---@param self foundation.shape3D.Line3D
---@param key any
---@return any
function Line3D.__index(self, key)
    if key == "point" then
        return self.__data.point
    elseif key == "direction" then
        return self.__data.direction
    end
    return Line3D[key]
end

---@param self foundation.shape3D.Line3D
---@param key any
---@param value any
function Line3D.__newindex(self, key, value)
    if key == "point" then
        self.__data.point = value
    elseif key == "direction" then
        self.__data.direction = value
    else
        rawset(self, key, value)
    end
end

---创建一条新的3D直线，由起点和方向向量确定
---@param point foundation.math.Vector3 起点
---@param direction foundation.math.Vector3 方向向量
---@return foundation.shape3D.Line3D
function Line3D.create(point, direction)
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

    local line = ffi.new("foundation_shape3D_Line3D", point, direction)
    local result = {
        __data = line,
    }
    return setmetatable(result, Line3D)
end

---根据弧度创建一个新的直线
---@param origin foundation.math.Vector3 起点
---@param theta number 仰角（与XY平面的夹角，范围[-π,π]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
---@return foundation.shape3D.Line3D 新创建的直线
function Line3D.createFromRad(origin, theta, phi)
    local direction = Vector3.createFromRad(theta, phi)
    return Line3D.create(origin, direction)
end

---根据角度创建一个新的直线
---@param origin foundation.math.Vector3 起点
---@param theta number 仰角（与XY平面的夹角，范围[-180,180]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
---@return foundation.shape3D.Line3D 新创建的直线
function Line3D.createFromAngle(origin, theta, phi)
    return Line3D.createFromRad(origin, math.rad(theta), math.rad(phi))
end

---3D直线相等比较
---@param a foundation.shape3D.Line3D
---@param b foundation.shape3D.Line3D
---@return boolean
function Line3D.__eq(a, b)
    return a.point == b.point and a.direction == b.direction
end

---3D直线的字符串表示
---@param self foundation.shape3D.Line3D
---@return string
function Line3D.__tostring(self)
    return string.format("Line3D(point=%s, direction=%s)", tostring(self.point), tostring(self.direction))
end

---获取3D直线的方向向量
---@return foundation.math.Vector3 方向向量
function Line3D:getDirection()
    return self.direction
end

---获取3D直线的长度
---@return number 长度
function Line3D:getLength()
    return math.huge
end

---获取3D直线的中点
---@return foundation.math.Vector3 中点
function Line3D:getCenter()
    return self.point
end

---将当前3D直线平移指定距离（更改当前直线）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Line3D 移动后的直线（自身引用）
function Line3D:move(v)
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

---获取3D直线平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Line3D 移动后的直线副本
function Line3D:moved(v)
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
    return Line3D.create(
        Vector3.create(self.point.x + moveX, self.point.y + moveY, self.point.z + moveZ),
        self.direction:clone()
    )
end

---使用欧拉角旋转直线（更改当前直线）
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为直线起点
---@return foundation.shape3D.Line3D 自身引用
function Line3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转直线的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为直线起点
---@return foundation.shape3D.Line3D 旋转后的直线副本
function Line3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = Line3D.create(self.point:clone(), self.direction:clone())
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用角度制的欧拉角旋转直线（更改当前直线）
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为直线起点
---@return foundation.shape3D.Line3D 自身引用
function Line3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转直线的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为直线起点
---@return foundation.shape3D.Line3D 旋转后的直线副本
function Line3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用四元数旋转直线（更改当前直线）
---@param rotation foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为直线起点
---@return foundation.shape3D.Line3D 自身引用
function Line3D:rotateQuaternion(rotation, center)
    if not rotation then
        error("Rotation quaternion cannot be nil")
    end
    center = center or self.point
    local offset = self.point - center
    self.point = center + rotation:rotateVector(offset)
    self.direction = rotation:rotateVector(self.direction)
    return self
end

---使用四元数旋转直线的副本
---@param rotation foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为直线起点
---@return foundation.shape3D.Line3D 旋转后的直线副本
function Line3D:rotatedQuaternion(rotation, center)
    local result = Line3D.create(self.point:clone(), self.direction:clone())
    return result:rotateQuaternion(rotation, center)
end

---将当前3D直线缩放指定倍数（更改当前直线）
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心
---@return foundation.shape3D.Line3D 缩放后的直线（自身引用）
---@overload fun(self: foundation.shape3D.Line3D, scale: number): foundation.shape3D.Line3D 相对直线起点缩放指定倍数
function Line3D:scale(scale, center)
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
    center = center or self.point
    local dx = self.point.x - center.x
    local dy = self.point.y - center.y
    local dz = self.point.z - center.z
    self.point.x = center.x + dx * scaleX
    self.point.y = center.y + dy * scaleY
    self.point.z = center.z + dz * scaleZ
    self.direction.x = self.direction.x * scaleX
    self.direction.y = self.direction.y * scaleY
    self.direction.z = self.direction.z * scaleZ
    return self
end

---获取3D直线缩放指定倍数的副本
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心
---@return foundation.shape3D.Line3D 缩放后的直线副本
---@overload fun(self: foundation.shape3D.Line3D, scale: number): foundation.shape3D.Line3D 相对直线起点缩放指定倍数
function Line3D:scaled(scale, center)
    local result = Line3D.create(self.point:clone(), self.direction:clone())
    return result:scale(scale, center)
end

---计算3D直线的AABB包围盒
---@return number, number, number, number, number, number
function Line3D:AABB()
    return -math.huge, math.huge, -math.huge, math.huge, -math.huge, math.huge
end

---计算3D直线的包围盒宽高深
---@return number, number, number
function Line3D:getBoundingBoxSize()
    return math.huge, math.huge, math.huge
end

---获取直线的角度（弧度）
---@return number, number 仰角（与XY平面的夹角，范围[-π,π]）和方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
function Line3D:angle()
    return self.direction:angle()
end

---获取直线的角度（度）
---@return number, number 仰角（与XY平面的夹角，范围[-180,180]）和方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
function Line3D:degreeAngle()
    return self.direction:degreeAngle()
end

---获取直线的旋转四元数
---@return foundation.math.Quaternion 从默认方向(1,0,0)旋转到当前方向的四元数
function Line3D:getRotation()
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

---计算点到3D直线的最近点
---@param point foundation.math.Vector3 要检查的点
---@return foundation.math.Vector3 直线上最近的点
function Line3D:closestPoint(point)
    local v = point - self.point
    local t = v:dot(self.direction) / self.direction:dot(self.direction)
    return self.point + self.direction * t
end

---计算点到3D直线的距离
---@param point foundation.math.Vector3 要检查的点
---@return number 点到直线的距离
function Line3D:distanceToPoint(point)
    return (point - self:closestPoint(point)):length()
end

---检查点是否在3D直线上
---@param point foundation.math.Vector3 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在直线上
---@overload fun(self:foundation.shape3D.Line3D, point:foundation.math.Vector3): boolean
function Line3D:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local closest = self:closestPoint(point)
    return (point - closest):lengthSquared() <= tolerance * tolerance
end

---获取点在3D直线上的投影
---@param point foundation.math.Vector3 点
---@return foundation.math.Vector3 投影点
function Line3D:projectPoint(point)
    local v = point - self.point
    local t = v:dot(self.direction)
    return self.point + self.direction * t
end

---复制3D直线
---@return foundation.shape3D.Line3D 直线的副本
function Line3D:clone()
    return Line3D.create(self.point:clone(), self.direction:clone())
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector3[] | nil
function Line3D:intersects(other)
    return Shape3DIntersector.intersect(self, other)
end

---只检查是否与其他形状相交
---@param other any
---@return boolean
function Line3D:hasIntersection(other)
    return Shape3DIntersector.hasIntersection(self, other)
end

ffi.metatype("foundation_shape3D_Line3D", Line3D)

return Line3D

local ffi = require("ffi")

local type = type
local math = math
local tostring = tostring
local string = string
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Shape3DIntersector = require("foundation.shape3D.Shape3DIntersector")

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
    local dist = direction and direction:length() or 0
    if dist <= 1e-10 then
        direction = Vector3.create(1, 0, 0)
    elseif dist ~= 1 then
        ---@diagnostic disable-next-line: need-check-nil
        direction = direction:normalized()
    else
        ---@diagnostic disable-next-line: need-check-nil
        direction = direction:clone()
    end

    local ray = ffi.new("foundation_shape3D_Ray3D", point, direction)
    local result = {
        __data = ray,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
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
    return Ray3D.create(
            Vector3.create(self.point.x + moveX, self.point.y + moveY, self.point.z + moveZ),
            self.direction:clone()
    )
end

---将当前3D射线旋转指定弧度（更改当前射线）
---@param axis foundation.math.Vector3 旋转轴
---@param rad number 旋转弧度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Ray3D 旋转后的射线（自身引用）
---@overload fun(self: foundation.shape3D.Ray3D, axis: foundation.math.Vector3, rad: number): foundation.shape3D.Ray3D 将当前射线绕起点旋转指定弧度
function Ray3D:rotate(axis, rad, center)
    center = center or self.point
    local rotated = self.direction:rotated(axis, rad)
    self.direction.x = rotated.x
    self.direction.y = rotated.y
    self.direction.z = rotated.z
    return self
end

---将当前3D射线旋转指定角度（更改当前射线）
---@param axis foundation.math.Vector3 旋转轴
---@param angle number 旋转角度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Ray3D 旋转后的射线（自身引用）
---@overload fun(self: foundation.shape3D.Ray3D, axis: foundation.math.Vector3, angle: number): foundation.shape3D.Ray3D 将当前射线绕起点旋转指定角度
function Ray3D:degreeRotate(axis, angle, center)
    angle = math.rad(angle)
    return self:rotate(axis, angle, center)
end

---获取当前3D射线旋转指定弧度的副本
---@param axis foundation.math.Vector3 旋转轴
---@param rad number 旋转弧度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Ray3D 旋转后的射线副本
---@overload fun(self: foundation.shape3D.Ray3D, axis: foundation.math.Vector3, rad: number): foundation.shape3D.Ray3D 获取当前射线绕起点旋转指定弧度的副本
function Ray3D:rotated(axis, rad, center)
    center = center or self.point
    local rotated = self.direction:rotated(axis, rad)
    return Ray3D.create(
            Vector3.create(
                    rotated.x + center.x,
                    rotated.y + center.y,
                    rotated.z + center.z
            ),
            rotated
    )
end

---获取当前3D射线旋转指定角度的副本
---@param axis foundation.math.Vector3 旋转轴
---@param angle number 旋转角度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Ray3D 旋转后的射线副本
---@overload fun(self: foundation.shape3D.Ray3D, axis: foundation.math.Vector3, angle: number): foundation.shape3D.Ray3D 获取当前射线绕起点旋转指定角度的副本
function Ray3D:degreeRotated(axis, angle, center)
    angle = math.rad(angle)
    return self:rotated(axis, angle, center)
end

---缩放3D射线（更改当前射线）
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心
---@return foundation.shape3D.Ray3D 缩放后的射线（自身引用）
function Ray3D:scale(scale, center)
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
    return self
end

---获取缩放后的3D射线副本
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心
---@return foundation.shape3D.Ray3D 缩放后的射线副本
function Ray3D:scaled(scale, center)
    local result = Ray3D.create(self.point:clone(), self.direction:clone())
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

---计算点到3D射线的最近点
---@param point foundation.math.Vector3 点
---@return foundation.math.Vector3 最近点
function Ray3D:closestPoint(point)
    local dir = self.direction:normalized()
    local v = point - self.point
    local t = v:dot(dir)
    if t < 0 then
        return self.point
    end
    return self.point + dir * t
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
    local dir = self.direction
    local v = point - self.point
    local t = v:dot(dir)
    return self.point + dir * t
end

---复制3D射线
---@return foundation.shape3D.Ray3D 复制的射线
function Ray3D:clone()
    return Ray3D.create(self.point:clone(), self.direction:clone())
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector3[] | nil
function Ray3D:intersects(other)
    return Shape3DIntersector.intersect(self, other)
end

---只检查是否与其他形状相交
---@param other any
---@return boolean
function Ray3D:hasIntersection(other)
    return Shape3DIntersector.hasIntersection(self, other)
end

ffi.metatype("foundation_shape3D_Ray3D", Ray3D)

return Ray3D

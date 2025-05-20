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
} foundation_shape3D_Line3D;
]]

---@class foundation.shape3D.Line3D
---@field point foundation.math.Vector3 直线上的一点
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

---创建一条新的3D直线，由一个点和方向向量确定
---@param point foundation.math.Vector3 直线上的点
---@param direction foundation.math.Vector3 方向向量
---@return foundation.shape3D.Line3D
function Line3D.create(point, direction)
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

    local line = ffi.new("foundation_shape3D_Line3D", point, direction)
    local result = {
        __data = line,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Line3D)
end

---根据两个点创建一条3D直线
---@param p1 foundation.math.Vector3 第一个点
---@param p2 foundation.math.Vector3 第二个点
---@return foundation.shape3D.Line3D
function Line3D.createFromPoints(p1, p2)
    local direction = p2 - p1
    return Line3D.create(p1, direction)
end

---根据弧度创建一个新的直线
---@param point foundation.math.Vector3 直线上的一点
---@param theta number 仰角（与XY平面的夹角，范围[-π,π]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
---@return foundation.shape3D.Line3D 新创建的直线
function Line3D.createFromRad(point, theta, phi)
    local direction = Vector3.createFromRad(theta, phi)
    return Line3D.create(point, direction)
end

---根据角度创建一个新的直线
---@param point foundation.math.Vector3 直线上的一点
---@param theta number 仰角（与XY平面的夹角，范围[-180,180]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
---@return foundation.shape3D.Line3D 新创建的直线
function Line3D.createFromAngle(point, theta, phi)
    return Line3D.createFromRad(point, math.rad(theta), math.rad(phi))
end

---3D直线相等比较
---@param a foundation.shape3D.Line3D
---@param b foundation.shape3D.Line3D
---@return boolean
function Line3D.__eq(a, b)
    local dir_cross = a.direction:cross(b.direction)
    if dir_cross:length() > 1e-10 then
        return false
    end
    local point_diff = b.point - a.point
    return point_diff:cross(a.direction):length() <= 1e-10
end

---3D直线的字符串表示
---@param self foundation.shape3D.Line3D
---@return string
function Line3D.__tostring(self)
    return string.format("Line3D(%s, dir=%s)", tostring(self.point), tostring(self.direction))
end

---获取3D直线上相对 point 指定距离的点
---@param length number 距离
---@return foundation.math.Vector3
function Line3D:getPoint(length)
    return self.point + self.direction * length
end

---计算3D直线的中心
---@return foundation.math.Vector3
function Line3D:getCenter()
    return self.point
end

---计算3D直线的AABB包围盒
---@return number, number, number, number, number, number
function Line3D:AABB()
    local minX, maxX = -math.huge, math.huge
    local minY, maxY = -math.huge, math.huge
    local minZ, maxZ = -math.huge, math.huge
    if math.abs(self.direction.x) < 1e-10 then
        minX = self.point.x
        maxX = self.point.x
    end
    if math.abs(self.direction.y) < 1e-10 then
        minY = self.point.y
        maxY = self.point.y
    end
    if math.abs(self.direction.z) < 1e-10 then
        minZ = self.point.z
        maxZ = self.point.z
    end
    return minX, maxX, minY, maxY, minZ, maxZ
end

---计算3D直线的包围盒宽高深
---@return number, number, number
function Line3D:getBoundingBoxSize()
    local widthX, widthY, widthZ = math.huge, math.huge, math.huge
    if math.abs(self.direction.x) < 1e-10 then
        widthX = 0
    end
    if math.abs(self.direction.y) < 1e-10 then
        widthY = 0
    end
    if math.abs(self.direction.z) < 1e-10 then
        widthZ = 0
    end
    return widthX, widthY, widthZ
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

---平移3D直线（更改当前直线）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Line3D 平移后的直线（自身引用）
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

---获取当前3D直线平移指定距离的副本
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

---旋转3D直线（更改当前直线）
---@param axis foundation.math.Vector3 旋转轴
---@param rad number 旋转弧度
---@param center foundation.math.Vector3|nil 旋转中心点，默认为直线上的点
---@return foundation.shape3D.Line3D 自身引用
function Line3D:rotate(axis, rad, center)
    if not axis then
        error("Rotation axis cannot be nil")
    end
    
    center = center or self.point
    rad = rad % (2 * math.pi)
    
    local rotated = self.direction:rotated(axis, rad)
    
    self.direction.x = rotated.x
    self.direction.y = rotated.y
    self.direction.z = rotated.z
    
    return self
end

---将当前3D直线旋转指定角度（更改当前直线）
---@param axis foundation.math.Vector3 旋转轴
---@param angle number 旋转角度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Line3D 旋转后的直线（自身引用）
---@overload fun(self: foundation.shape3D.Line3D, axis: foundation.math.Vector3, angle: number): foundation.shape3D.Line3D 将当前直线绕定义的点旋转指定角度
function Line3D:degreeRotate(axis, angle, center)
    angle = math.rad(angle)
    return self:rotate(axis, angle, center)
end

---获取当前3D直线旋转指定弧度的副本
---@param axis foundation.math.Vector3 旋转轴
---@param rad number 旋转弧度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Line3D 旋转后的直线副本
---@overload fun(self: foundation.shape3D.Line3D, axis: foundation.math.Vector3, rad: number): foundation.shape3D.Line3D 获取当前直线绕定义的点旋转指定弧度的副本
function Line3D:rotated(axis, rad, center)
    center = center or self.point
    local rotated = self.direction:rotated(axis, rad)
    return Line3D.create(
            Vector3.create(
                    rotated.x + center.x,
                    rotated.y + center.y,
                    rotated.z + center.z
            ),
            rotated
    )
end

---获取当前3D直线旋转指定角度的副本
---@param axis foundation.math.Vector3 旋转轴
---@param angle number 旋转角度
---@param center foundation.math.Vector3 旋转中心
---@return foundation.shape3D.Line3D 旋转后的直线副本
---@overload fun(self: foundation.shape3D.Line3D, axis: foundation.math.Vector3, angle: number): foundation.shape3D.Line3D 获取当前直线绕定义的点旋转指定角度的副本
function Line3D:degreeRotated(axis, angle, center)
    angle = math.rad(angle)
    return self:rotated(axis, angle, center)
end

---缩放3D直线（更改当前直线）
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心
---@return foundation.shape3D.Line3D 缩放后的直线（自身引用）
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
    return self
end

---获取缩放后的3D直线副本
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心
---@return foundation.shape3D.Line3D 缩放后的直线副本
function Line3D:scaled(scale, center)
    local result = Line3D.create(self.point:clone(), self.direction:clone())
    return result:scale(scale, center)
end

---计算点到3D直线的最近点
---@param point foundation.math.Vector3 点
---@return foundation.math.Vector3 最近点
function Line3D:closestPoint(point)
    return self:projectPoint(point)
end

---计算点到3D直线的距离
---@param point foundation.math.Vector3 点
---@return number 距离
function Line3D:distanceToPoint(point)
    return (point - self:closestPoint(point)):length()
end

---检查点是否在3D直线上
---@param point foundation.math.Vector3 点
---@param tolerance number 容差
---@return boolean
function Line3D:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local point_vec = point - self.point
    local cross = point_vec:cross(self.direction)
    return cross:length() <= tolerance
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
---@return foundation.shape3D.Line3D 复制的直线
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

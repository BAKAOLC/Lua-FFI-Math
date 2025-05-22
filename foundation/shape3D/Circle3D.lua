local ffi = require("ffi")

local type = type
local tostring = tostring
local string = string
local math = math
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Quaternion = require("foundation.math.Quaternion")
local Matrix = require("foundation.math.matrix.Matrix")
local Shape3DIntersector = require("foundation.shape3D.Shape3DIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 center;
    double radius;
    foundation_math_Quaternion rotation;
} foundation_shape3D_Circle3D;
]]

---@class foundation.shape3D.Circle3D
---@field center foundation.math.Vector3 圆的中心点
---@field radius number 圆的半径
---@field rotation foundation.math.Quaternion 圆的旋转
local Circle3D = {}
Circle3D.__type = "foundation.shape3D.Circle3D"

---@param self foundation.shape3D.Circle3D
---@param key any
---@return any
function Circle3D.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "radius" then
        return self.__data.radius
    elseif key == "rotation" then
        return self.__data.rotation
    end
    return Circle3D[key]
end

---@param self foundation.shape3D.Circle3D
---@param key string
---@param value any
function Circle3D.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "radius" then
        self.__data.radius = value
    elseif key == "rotation" then
        self.__data.rotation = value
    else
        rawset(self, key, value)
    end
end

---使用四元数创建一个新的3D圆
---@param center foundation.math.Vector3 圆的中心点
---@param radius number 圆的半径
---@param rotation foundation.math.Quaternion 圆的旋转四元数
---@return foundation.shape3D.Circle3D 新创建的圆
function Circle3D.createWithQuaternion(center, radius, rotation)
    if not center then
        error("Center point cannot be nil")
    end
    radius = radius or 1
    rotation = rotation or Quaternion.identity()

    local circle = ffi.new("foundation_shape3D_Circle3D", center, radius, rotation)
    local result = {
        __data = circle,
    }
    return setmetatable(result, Circle3D)
end

---创建一个新的3D圆，由中心点、半径和方向向量确定
---@param center foundation.math.Vector3 圆的中心点
---@param radius number 圆的半径
---@param direction foundation.math.Vector3 圆的方向向量
---@param up foundation.math.Vector3 圆的上方向向量
---@return foundation.shape3D.Circle3D 新创建的圆
---@overload fun(center: foundation.math.Vector3, radius: number, direction: foundation.math.Vector3): foundation.shape3D.Circle3D
---@overload fun(center: foundation.math.Vector3, radius: number): foundation.shape3D.Circle3D
function Circle3D.create(center, radius, direction, up)
    if not center then
        error("Center point cannot be nil")
    end
    radius = radius or 1

    local rotation = Quaternion.identity()
    if direction then
        local dist = direction:length()
        if dist <= 1e-10 then
            direction = Vector3.create(1, 0, 0)
        elseif dist ~= 1 then
            direction = direction:normalized()
        end

        if up then
            local upDist = up:length()
            if upDist <= 1e-10 then
                up = Vector3.create(0, 1, 0)
            elseif upDist ~= 1 then
                up = up:normalized()
            end
        else
            up = Vector3.create(0, 1, 0)
        end

        local right = direction:cross(up)
        if right:length() <= 1e-10 then
            up = Vector3.create(0, 0, 1)
            right = direction:cross(up)
        end
        right = right:normalized()
        up = direction:cross(right):normalized()

        local matrix = {
            direction.x, direction.y, direction.z,
            up.x, up.y, up.z,
            right.x, right.y, right.z
        }
        local m = Matrix.fromFlatArray(matrix, 3, 3)
        rotation = m:toQuaternion()
    end

    return Circle3D.createWithQuaternion(center, radius, rotation)
end

---根据弧度创建一个新的圆
---@param center foundation.math.Vector3 中心点
---@param radius number 半径
---@param theta number 仰角（与XY平面的夹角，范围[-π,π]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
---@return foundation.shape3D.Circle3D 新创建的圆
function Circle3D.createFromRad(center, radius, theta, phi)
    local direction = Vector3.createFromRad(theta, phi)
    return Circle3D.create(center, radius, direction)
end

---根据角度创建一个新的圆
---@param center foundation.math.Vector3 中心点
---@param radius number 半径
---@param theta number 仰角（与XY平面的夹角，范围[-180,180]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
---@return foundation.shape3D.Circle3D 新创建的圆
function Circle3D.createFromAngle(center, radius, theta, phi)
    return Circle3D.createFromRad(center, radius, math.rad(theta), math.rad(phi))
end

---使用欧拉角创建一个新的3D圆
---@param center foundation.math.Vector3 圆的中心点
---@param radius number 圆的半径
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@return foundation.shape3D.Circle3D 新创建的圆
function Circle3D.createWithEulerAngles(center, radius, eulerX, eulerY, eulerZ)
    if not center then
        error("Center point cannot be nil")
    end
    radius = radius or 1

    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return Circle3D.createWithQuaternion(center, radius, rotation)
end

---使用欧拉角（角度制）创建一个新的3D圆
---@param center foundation.math.Vector3 圆的中心点
---@param radius number 圆的半径
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@return foundation.shape3D.Circle3D 新创建的圆
function Circle3D.createWithDegreeEulerAngles(center, radius, eulerX, eulerY, eulerZ)
    return Circle3D.createWithEulerAngles(center, radius, math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ))
end

---3D圆相等比较
---@param a foundation.shape3D.Circle3D
---@param b foundation.shape3D.Circle3D
---@return boolean
function Circle3D.__eq(a, b)
    return a.center == b.center and
        math.abs(a.radius - b.radius) <= 1e-10 and
        a.rotation == b.rotation
end

---3D圆的字符串表示
---@param self foundation.shape3D.Circle3D
---@return string
function Circle3D.__tostring(self)
    return string.format("Circle3D(center=%s, radius=%f, rotation=%s)",
        tostring(self.center), self.radius, tostring(self.rotation))
end

---获取圆的方向向量
---@return foundation.math.Vector3
function Circle3D:getDirection()
    return self.rotation:rotateVector(Vector3.create(1, 0, 0))
end

---获取圆的上方向向量
---@return foundation.math.Vector3
function Circle3D:getUp()
    return self.rotation:rotateVector(Vector3.create(0, 1, 0))
end

---获取圆的右方向向量
---@return foundation.math.Vector3
function Circle3D:getRight()
    return self.rotation:rotateVector(Vector3.create(0, 0, 1))
end

---计算3D圆的面积
---@return number
function Circle3D:area()
    return math.pi * self.radius * self.radius
end

---计算3D圆的周长
---@return number
function Circle3D:getPerimeter()
    return 2 * math.pi * self.radius
end

---计算3D圆的中心
---@return foundation.math.Vector3
function Circle3D:getCenter()
    return self.center:clone()
end

---计算3D圆的法向量
---@return foundation.math.Vector3
function Circle3D:normal()
    return self.rotation:rotateVector(Vector3.create(0, 0, 1)):normalized()
end

---平移3D圆（更改当前圆）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Circle3D 自身引用
function Circle3D:move(v)
    local moveX, moveY, moveZ
    if type(v) == "number" then
        moveX, moveY, moveZ = v, v, v
    else
        moveX, moveY, moveZ = v.x, v.y, v.z
    end
    self.center.x = self.center.x + moveX
    self.center.y = self.center.y + moveY
    self.center.z = self.center.z + moveZ
    return self
end

---获取平移后的3D圆副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Circle3D
function Circle3D:moved(v)
    local moveX, moveY, moveZ
    if type(v) == "number" then
        moveX, moveY, moveZ = v, v, v
    else
        moveX, moveY, moveZ = v.x, v.y, v.z
    end
    return Circle3D.createWithQuaternion(
        Vector3.create(self.center.x + moveX, self.center.y + moveY, self.center.z + moveZ),
        self.radius, self.rotation
    )
end

---使用欧拉角旋转圆（更改当前圆）
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆心
---@return foundation.shape3D.Circle3D 自身引用
function Circle3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转圆的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆心
---@return foundation.shape3D.Circle3D 旋转后的圆副本
function Circle3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = Circle3D.createWithQuaternion(self.center, self.radius, self.rotation)
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用角度制的欧拉角旋转圆（更改当前圆）
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆心
---@return foundation.shape3D.Circle3D 自身引用
function Circle3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转圆的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆心
---@return foundation.shape3D.Circle3D 旋转后的圆副本
function Circle3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用四元数旋转圆（更改当前圆）
---@param rotation foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆心
---@return foundation.shape3D.Circle3D 自身引用
function Circle3D:rotateQuaternion(rotation, center)
    if not rotation then
        error("Rotation quaternion cannot be nil")
    end

    center = center or self.center
    local offset = self.center - center
    self.center = center + rotation:rotateVector(offset)
    self.rotation = rotation * self.rotation

    return self
end

---使用四元数旋转圆的副本
---@param rotation foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆心
---@return foundation.shape3D.Circle3D 旋转后的圆副本
function Circle3D:rotatedQuaternion(rotation, center)
    local result = Circle3D.createWithQuaternion(self.center, self.radius, self.rotation)
    return result:rotateQuaternion(rotation, center)
end

---缩放3D圆（更改当前圆）
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3|nil 缩放中心点，默认为圆心
---@return foundation.shape3D.Circle3D 自身引用
function Circle3D:scale(scale, center)
    local scaleX, scaleY, scaleZ
    if type(scale) == "number" then
        scaleX, scaleY, scaleZ = scale, scale, scale
    else
        scaleX, scaleY, scaleZ = scale.x, scale.y, scale.z
    end
    center = center or self.center

    self.radius = self.radius * math.sqrt(scaleX * scaleY)
    local dx = self.center.x - center.x
    local dy = self.center.y - center.y
    local dz = self.center.z - center.z
    self.center.x = center.x + dx * scaleX
    self.center.y = center.y + dy * scaleY
    self.center.z = center.z + dz * scaleZ
    return self
end

---获取缩放后的3D圆副本
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3|nil 缩放中心点，默认为圆心
---@return foundation.shape3D.Circle3D
function Circle3D:scaled(scale, center)
    local result = Circle3D.createWithQuaternion(self.center:clone(), self.radius, self.rotation)
    return result:scale(scale, center)
end

---获取3D圆的顶点
---@param segments number|nil 分段数，默认为32
---@return foundation.math.Vector3[]
function Circle3D:getVertices(segments)
    segments = segments or 32
    local vertices = {}
    local angleStep = 2 * math.pi / segments
    local rotation = self.rotation
    local radius = self.radius

    for i = 0, segments - 1 do
        local angle = i * angleStep
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        vertices[i + 1] = self.center + rotation:rotateVector(Vector3.create(x, y, 0))
    end

    return vertices
end

---获取3D圆的AABB包围盒
---@return number, number, number, number, number, number
function Circle3D:AABB()
    local vertices = self:getVertices()
    local minX, maxX = vertices[1].x, vertices[1].x
    local minY, maxY = vertices[1].y, vertices[1].y
    local minZ, maxZ = vertices[1].z, vertices[1].z

    for i = 2, #vertices do
        local v = vertices[i]
        minX = math.min(minX, v.x)
        maxX = math.max(maxX, v.x)
        minY = math.min(minY, v.y)
        maxY = math.max(maxY, v.y)
        minZ = math.min(minZ, v.z)
        maxZ = math.max(maxZ, v.z)
    end

    return minX, maxX, minY, maxY, minZ, maxZ
end

---计算3D圆的包围盒宽高深
---@return number, number, number
function Circle3D:getBoundingBoxSize()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return maxX - minX, maxY - minY, maxZ - minZ
end

---计算点到3D圆的最近点
---@param point foundation.math.Vector3
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector3
---@overload fun(self: foundation.shape3D.Circle3D, point: foundation.math.Vector3): foundation.math.Vector3
function Circle3D:closestPoint(point, boundary)
    if not boundary and self:contains(point) then
        return point:clone()
    end

    local normal = self:normal()
    local v1p = point - self.center
    local dist = v1p:dot(normal)
    local projected = point - normal * dist
    local dir = projected - self.center
    local length = dir:length()

    if length <= 1e-10 then
        return self.center + self.rotation:rotateVector(Vector3.create(self.radius, 0, 0))
    end

    return self.center + dir:normalized() * self.radius
end

---计算点到3D圆的距离
---@param point foundation.math.Vector3
---@return number
function Circle3D:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end
    return (point - self:closestPoint(point)):length()
end

---将点投影到3D圆平面上
---@param point foundation.math.Vector3
---@return foundation.math.Vector3
function Circle3D:projectPoint(point)
    local normal = self:normal()
    local v1p = point - self.center
    local dist = v1p:dot(normal)
    return point - normal * dist
end

---检查点是否在3D圆边界上
---@param point foundation.math.Vector3
---@param tolerance number|nil 默认为1e-10
---@return boolean
function Circle3D:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local normal = self:normal()
    local v1p = point - self.center
    local dist = v1p:dot(normal)
    if math.abs(dist) > tolerance then
        return false
    end
    local projected = point - normal * dist
    local dir = projected - self.center
    local length = dir:length()
    return math.abs(length - self.radius) <= tolerance
end

---检查点是否在3D圆内（包括边界）
---@param point foundation.math.Vector3
---@return boolean
function Circle3D:contains(point)
    return Shape3DIntersector.circleContainsPoint(self, point)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector3[] | nil
function Circle3D:intersects(other)
    return Shape3DIntersector.intersect(self, other)
end

---仅检查是否与其他形状相交
---@param other any
---@return boolean
function Circle3D:hasIntersection(other)
    return Shape3DIntersector.hasIntersection(self, other)
end

---复制3D圆
---@return foundation.shape3D.Circle3D
function Circle3D:clone()
    return Circle3D.createWithQuaternion(self.center:clone(), self.radius, self.rotation)
end

ffi.metatype("foundation_shape3D_Circle3D", Circle3D)

return Circle3D

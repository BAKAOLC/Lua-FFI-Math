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
local Matrix = require("foundation.math.matrix.Matrix")
local Segment3D = require("foundation.shape3D.Segment3D")
local Circle3D = require("foundation.shape3D.Circle3D")
local Shape3DIntersector = require("foundation.shape3D.Shape3DIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 center;
    double radius;
    double range;
    foundation_math_Quaternion rotation;
} foundation_shape3D_Sector3D;
]]

---@class foundation.shape3D.Sector3D
---@field center foundation.math.Vector3 扇形的中心点
---@field radius number 扇形的半径
---@field range number 扇形的范围（-1到1，表示-2π到2π）
---@field rotation foundation.math.Quaternion 扇形的旋转
local Sector3D = {}
Sector3D.__type = "foundation.shape3D.Sector3D"

---@param self foundation.shape3D.Sector3D
---@param key any
---@return any
function Sector3D.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "radius" then
        return self.__data.radius
    elseif key == "range" then
        return self.__data.range
    elseif key == "rotation" then
        return self.__data.rotation
    end
    return Sector3D[key]
end

---@param self foundation.shape3D.Sector3D
---@param key string
---@param value any
function Sector3D.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "radius" then
        self.__data.radius = value
    elseif key == "range" then
        self.__data.range = value
    elseif key == "rotation" then
        self.__data.rotation = value
    else
        rawset(self, key, value)
    end
end

---使用四元数创建一个新的3D扇形
---@param center foundation.math.Vector3 扇形的中心点
---@param radius number 扇形的半径
---@param range number 扇形的范围（-1到1，表示-2π到2π）
---@param rotation foundation.math.Quaternion 扇形的旋转四元数
---@return foundation.shape3D.Sector3D 新创建的扇形
function Sector3D.createWithQuaternion(center, radius, range, rotation)
    if not center then
        error("Center point cannot be nil")
    end
    radius = radius or 1
    range = math.max(-1, math.min(1, range or 1))
    rotation = rotation or Quaternion.identity()

    local sector = ffi.new("foundation_shape3D_Sector3D", center, radius, range, rotation)
    local result = {
        __data = sector,
    }
    return setmetatable(result, Sector3D)
end

---创建一个新的3D扇形，由中心点、半径、方向向量和范围确定
---@param center foundation.math.Vector3 扇形的中心点
---@param radius number 扇形的半径
---@param direction foundation.math.Vector3 扇形的方向向量
---@param range number 扇形的范围（-1到1，表示-2π到2π）
---@param up foundation.math.Vector3 扇形的上方向向量
---@return foundation.shape3D.Sector3D 新创建的扇形
---@overload fun(center: foundation.math.Vector3, radius: number, direction: foundation.math.Vector3, range: number): foundation.shape3D.Sector3D
---@overload fun(center: foundation.math.Vector3, radius: number, direction: foundation.math.Vector3): foundation.shape3D.Sector3D
---@overload fun(center: foundation.math.Vector3, radius: number): foundation.shape3D.Sector3D
function Sector3D.create(center, radius, direction, range, up)
    if not center then
        error("Center point cannot be nil")
    end
    radius = radius or 1
    range = math.max(-1, math.min(1, range or 1))

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

    return Sector3D.createWithQuaternion(center, radius, range, rotation)
end

---根据弧度创建一个新的扇形
---@param center foundation.math.Vector3 中心点
---@param radius number 半径
---@param theta number 仰角（与XY平面的夹角，范围[-π,π]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
---@param range number 扇形的范围（-1到1，表示-2π到2π）
---@return foundation.shape3D.Sector3D 新创建的扇形
function Sector3D.createFromRad(center, radius, theta, phi, range)
    local direction = Vector3.createFromRad(theta, phi)
    return Sector3D.create(center, radius, direction, range)
end

---根据角度创建一个新的扇形
---@param center foundation.math.Vector3 中心点
---@param radius number 半径
---@param theta number 仰角（与XY平面的夹角，范围[-180,180]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
---@param range number 扇形的范围（-1到1，表示-2π到2π）
---@return foundation.shape3D.Sector3D 新创建的扇形
function Sector3D.createFromAngle(center, radius, theta, phi, range)
    return Sector3D.createFromRad(center, radius, math.rad(theta), math.rad(phi), range)
end

---使用欧拉角创建一个新的3D扇形
---@param center foundation.math.Vector3 扇形的中心点
---@param radius number 扇形的半径
---@param range number 扇形的范围（-1到1，表示-2π到2π）
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@return foundation.shape3D.Sector3D 新创建的扇形
function Sector3D.createWithEulerAngles(center, radius, range, eulerX, eulerY, eulerZ)
    if not center then
        error("Center point cannot be nil")
    end
    radius = radius or 1
    range = math.max(-1, math.min(1, range or 1))

    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return Sector3D.createWithQuaternion(center, radius, range, rotation)
end

---使用欧拉角（角度制）创建一个新的3D扇形
---@param center foundation.math.Vector3 扇形的中心点
---@param radius number 扇形的半径
---@param range number 扇形的范围（-1到1，表示-2π到2π）
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@return foundation.shape3D.Sector3D 新创建的扇形
function Sector3D.createWithDegreeEulerAngles(center, radius, range, eulerX, eulerY, eulerZ)
    return Sector3D.createWithEulerAngles(center, radius, range, math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ))
end

---3D扇形相等比较
---@param a foundation.shape3D.Sector3D
---@param b foundation.shape3D.Sector3D
---@return boolean
function Sector3D.__eq(a, b)
    return a.center == b.center and
        math.abs(a.radius - b.radius) <= 1e-10 and
        math.abs(a.range - b.range) <= 1e-10 and
        a.rotation == b.rotation
end

---3D扇形的字符串表示
---@param self foundation.shape3D.Sector3D
---@return string
function Sector3D.__tostring(self)
    return string.format("Sector3D(center=%s, radius=%f, range=%f, rotation=%s)",
        tostring(self.center), self.radius, self.range, tostring(self.rotation))
end

---将扇形转换为圆形
---@return foundation.shape3D.Circle3D
function Sector3D:toCircle()
    return Circle3D.createWithQuaternion(self.center, self.radius, self.rotation)
end

---获取扇形的角度
---@return number
function Sector3D:getAngle()
    return math.abs(self.range) * 2 * math.pi
end

---获取扇形的角度（度）
---@return number
function Sector3D:getDegreeAngle()
    return math.deg(self:getAngle())
end

---计算3D扇形的面积
---@return number
function Sector3D:area()
    return 0.5 * self.radius * self.radius * self:getAngle()
end

---计算3D扇形的周长
---@return number
function Sector3D:getPerimeter()
    if math.abs(self.range) >= 1 then
        return 2 * math.pi * self.radius
    end
    local arcLength = self.radius * self:getAngle()
    return arcLength + 2 * self.radius
end

---计算3D扇形的中心
---@return foundation.math.Vector3
function Sector3D:getCenter()
    if math.abs(self.range) >= 1 then
        return self.center:clone()
    end

    local points = { self.center:clone() }
    local startDir = self:getDirection()
    local rotation = Quaternion.createFromAxisAngle(self:normal(), self.range * 2 * math.pi)
    local endDir = rotation:rotateVector(startDir)
    local start_point = self.center + startDir * self.radius
    local end_point = self.center + endDir * self.radius
    points[#points + 1] = start_point
    points[#points + 1] = end_point

    local start_angle = startDir:angle()
    local end_angle = start_angle + self.range * 2 * math.pi
    local min_angle = math.min(start_angle, end_angle)
    local max_angle = math.max(start_angle, end_angle)

    local critical_points = {
        { angle = 0,               point = Vector3.create(self.center.x + self.radius, self.center.y, self.center.z) },
        { angle = math.pi,         point = Vector3.create(self.center.x - self.radius, self.center.y, self.center.z) },
        { angle = math.pi / 2,     point = Vector3.create(self.center.x, self.center.y + self.radius, self.center.z) },
        { angle = 3 * math.pi / 2, point = Vector3.create(self.center.x, self.center.y - self.radius, self.center.z) }
    }

    for _, cp in ipairs(critical_points) do
        local angle = cp.angle
        angle = angle - 2 * math.pi * math.floor((angle - min_angle) / (2 * math.pi))
        if min_angle <= angle and angle <= max_angle then
            points[#points + 1] = cp.point
        end
    end

    local x_min, x_max = points[1].x, points[1].x
    local y_min, y_max = points[1].y, points[1].y
    local z_min, z_max = points[1].z, points[1].z
    for _, p in ipairs(points) do
        x_min = math.min(x_min, p.x)
        x_max = math.max(x_max, p.x)
        y_min = math.min(y_min, p.y)
        y_max = math.max(y_max, p.y)
        z_min = math.min(z_min, p.z)
        z_max = math.max(z_max, p.z)
    end

    return Vector3.create((x_min + x_max) / 2, (y_min + y_max) / 2, (z_min + z_max) / 2)
end

---获取扇形的方向向量
---@return foundation.math.Vector3
function Sector3D:getDirection()
    return self.rotation:rotateVector(Vector3.create(1, 0, 0))
end

---获取扇形的上方向向量
---@return foundation.math.Vector3
function Sector3D:getUp()
    return self.rotation:rotateVector(Vector3.create(0, 1, 0))
end

---获取扇形的右方向向量
---@return foundation.math.Vector3
function Sector3D:getRight()
    return self.rotation:rotateVector(Vector3.create(0, 0, 1))
end

---计算3D扇形的法向量
---@return foundation.math.Vector3
function Sector3D:normal()
    return self.rotation:rotateVector(Vector3.create(0, 0, 1)):normalized()
end

---平移3D扇形（更改当前扇形）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Sector3D 自身引用
function Sector3D:move(v)
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

---获取平移后的3D扇形副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Sector3D
function Sector3D:moved(v)
    local moveX, moveY, moveZ
    if type(v) == "number" then
        moveX, moveY, moveZ = v, v, v
    else
        moveX, moveY, moveZ = v.x, v.y, v.z
    end
    return Sector3D.createWithQuaternion(
        Vector3.create(self.center.x + moveX, self.center.y + moveY, self.center.z + moveZ),
        self.radius, self.range, self.rotation
    )
end

---使用欧拉角旋转扇形（更改当前扇形）
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为扇形中心
---@return foundation.shape3D.Sector3D 自身引用
function Sector3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转扇形的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为扇形中心
---@return foundation.shape3D.Sector3D 旋转后的扇形副本
function Sector3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = Sector3D.createWithQuaternion(self.center, self.radius, self.range, self.rotation)
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用角度制的欧拉角旋转扇形（更改当前扇形）
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为扇形中心
---@return foundation.shape3D.Sector3D 自身引用
function Sector3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转扇形的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为扇形中心
---@return foundation.shape3D.Sector3D 旋转后的扇形副本
function Sector3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用四元数旋转扇形（更改当前扇形）
---@param rotation foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为扇形中心
---@return foundation.shape3D.Sector3D 自身引用
function Sector3D:rotateQuaternion(rotation, center)
    if not rotation then
        error("Rotation quaternion cannot be nil")
    end

    center = center or self.center
    local offset = self.center - center
    self.center = center + rotation:rotateVector(offset)
    self.rotation = rotation * self.rotation

    return self
end

---使用四元数旋转扇形的副本
---@param rotation foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为扇形中心
---@return foundation.shape3D.Sector3D 旋转后的扇形副本
function Sector3D:rotatedQuaternion(rotation, center)
    local result = Sector3D.createWithQuaternion(self.center, self.radius, self.range, self.rotation)
    return result:rotateQuaternion(rotation, center)
end

---缩放3D扇形（更改当前扇形）
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3|nil 缩放中心点，默认为扇形中心
---@return foundation.shape3D.Sector3D 自身引用
function Sector3D:scale(scale, center)
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

---获取缩放后的3D扇形副本
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3|nil 缩放中心点，默认为扇形中心
---@return foundation.shape3D.Sector3D
function Sector3D:scaled(scale, center)
    local result = Sector3D.createWithQuaternion(self.center, self.radius, self.range, self.rotation)
    return result:scale(scale, center)
end

---获取3D扇形的顶点
---@param segments number|nil 分段数，默认为32
---@return foundation.math.Vector3[]
function Sector3D:getVertices(segments)
    segments = segments or 32
    local vertices = {}
    local angleStep = self:getAngle() / segments
    local rotation = self.rotation
    local radius = self.radius
    local startAngle = self:getDirection():angle()

    for i = 0, segments do
        local angle = startAngle + i * angleStep
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        vertices[i + 1] = self.center + rotation:rotateVector(Vector3.create(x, y, 0))
    end

    return vertices
end

---获取3D扇形的AABB包围盒
---@return number, number, number, number, number, number
function Sector3D:AABB()
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

---计算3D扇形的包围盒宽高深
---@return number, number, number
function Sector3D:getBoundingBoxSize()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return maxX - minX, maxY - minY, maxZ - minZ
end

---计算点到3D扇形的最近点
---@param point foundation.math.Vector3
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector3
---@overload fun(self: foundation.shape3D.Sector3D, point: foundation.math.Vector3): foundation.math.Vector3
function Sector3D:closestPoint(point, boundary)
    if math.abs(self.range) >= 1 then
        return Circle3D.closestPoint(self, point, boundary)
    end
    if not boundary and self:contains(point) then
        return point:clone()
    end

    local circle_closest = Circle3D.closestPoint(self, point, boundary)
    local contains = self:contains(circle_closest)
    if not boundary and contains then
        return circle_closest
    end

    local startDir = self:getDirection()
    local rotation = Quaternion.createFromAxisAngle(self:normal(), self.range * 2 * math.pi)
    local endDir = rotation:rotateVector(startDir)
    local start_point = self.center + startDir * self.radius
    local end_point = self.center + endDir * self.radius
    local start_segment = Segment3D.create(self.center, start_point)
    local end_segment = Segment3D.create(self.center, end_point)
    local candidates = {
        start_segment:closestPoint(point, boundary),
        end_segment:closestPoint(point, boundary),
        boundary and contains and circle_closest or nil,
    }
    local min_distance = math.huge
    local closest_point = candidates[1]
    for _, candidate in ipairs(candidates) do
        local distance = (point - candidate):length()
        if distance < min_distance then
            min_distance = distance
            closest_point = candidate
        end
    end
    return closest_point
end

---计算点到3D扇形的距离
---@param point foundation.math.Vector3
---@return number
function Sector3D:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end
    return (point - self:closestPoint(point)):length()
end

---将点投影到3D扇形平面上
---@param point foundation.math.Vector3
---@return foundation.math.Vector3
function Sector3D:projectPoint(point)
    return self:closestPoint(point, true)
end

---检查点是否在3D扇形边界上
---@param point foundation.math.Vector3
---@param tolerance number|nil 默认为1e-10
---@return boolean
function Sector3D:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10

    local vec = point - self.center
    local range = self.range * 2 * math.pi
    if math.abs(self.range) >= 1 then
        local dist = (point - self.center):length()
        return math.abs(dist - self.radius) <= tolerance
    end

    local segment1 = Segment3D.create(self.center, self.center + self:getDirection() * self.radius)
    if segment1:containsPoint(point, tolerance) then
        return true
    end

    local rotation = Quaternion.createFromAxisAngle(self:normal(), range * 2 * math.pi)
    local segment2 = Segment3D.create(self.center, self.center + rotation:rotateVector(self:getDirection()) * self
        .radius)
    if segment2:containsPoint(point, tolerance) then
        return true
    end

    local distance = vec:length()
    if math.abs(distance - self.radius) > tolerance then
        return false
    end
    if distance <= tolerance then
        return true
    end

    local angle_begin
    if range > 0 then
        angle_begin = self:getDirection():angle()
    else
        range = -range
        angle_begin = self:getDirection():angle() - range
    end

    local vec_angle = vec:angle()
    vec_angle = vec_angle - 2 * math.pi * math.floor((vec_angle - angle_begin) / (2 * math.pi))
    return angle_begin <= vec_angle and vec_angle <= angle_begin + range
end

---检查点是否在3D扇形内（包括边界）
---@param point foundation.math.Vector3
---@return boolean
function Sector3D:contains(point)
    return Shape3DIntersector.sectorContainsPoint(self, point)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector3[] | nil
function Sector3D:intersects(other)
    return Shape3DIntersector.intersect(self, other)
end

---仅检查是否与其他形状相交
---@param other any
---@return boolean
function Sector3D:hasIntersection(other)
    return Shape3DIntersector.hasIntersection(self, other)
end

---复制3D扇形
---@return foundation.shape3D.Sector3D
function Sector3D:clone()
    return Sector3D.createWithQuaternion(self.center:clone(), self.radius, self.range, self.rotation)
end

ffi.metatype("foundation_shape3D_Sector3D", Sector3D)

return Sector3D

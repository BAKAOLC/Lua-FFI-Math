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

---获取扇形的属性值
---@param self foundation.shape3D.Sector3D
---@param key string
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

---设置扇形的属性值
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

---使用四元数创建一个新的扇形
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

---创建一个新的扇形，由中心点、半径、方向向量和范围确定
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

---使用欧拉角创建一个新的扇形
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

---使用欧拉角（角度制）创建一个新的扇形
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

---比较两个扇形是否相等
---@param a foundation.shape3D.Sector3D 第一个扇形
---@param b foundation.shape3D.Sector3D 第二个扇形
---@return boolean 如果两个扇形的所有属性都相等则返回true，否则返回false
function Sector3D.__eq(a, b)
    return a.center == b.center and
        math.abs(a.radius - b.radius) <= 1e-10 and
        math.abs(a.range - b.range) <= 1e-10 and
        a.rotation == b.rotation
end

---将扇形转换为字符串表示
---@param self foundation.shape3D.Sector3D 要转换的扇形
---@return string 扇形的字符串表示
function Sector3D.__tostring(self)
    return string.format("Sector3D(center=%s, radius=%f, range=%f, rotation=%s)",
        tostring(self.center), self.radius, self.range, tostring(self.rotation))
end

---创建扇形的副本
---@return foundation.shape3D.Sector3D 扇形的副本
function Sector3D:clone()
    return Sector3D.createWithQuaternion(self.center:clone(), self.radius, self.range, self.rotation:clone())
end

---将扇形转换为圆形
---@return foundation.shape3D.Circle3D 转换后的圆形
function Sector3D:toCircle()
    return Circle3D.createWithQuaternion(self.center:clone(), self.radius, self.rotation:clone())
end

---获取扇形的角度
---@return number 扇形的角度（弧度）
function Sector3D:getAngle()
    return math.abs(self.range) * 2 * math.pi
end

---获取扇形的角度（度）
---@return number 扇形的角度（度）
function Sector3D:getDegreeAngle()
    return math.deg(self:getAngle())
end

---计算扇形的面积
---@return number 扇形的面积
function Sector3D:area()
    return 0.5 * self.radius * self.radius * self:getAngle()
end

---计算扇形的周长
---@return number 扇形的周长
function Sector3D:getPerimeter()
    return 2 * self.radius + self.radius * self:getAngle()
end

---获取扇形的中心点
---@return foundation.math.Vector3 扇形的中心点
function Sector3D:getCenter()
    return self.center:clone()
end

---获取扇形的法向量
---@return foundation.math.Vector3 扇形的法向量
function Sector3D:normal()
    return self.rotation:rotateVector(Vector3.create(0, 0, 1)):normalized()
end

---将当前扇形平移指定距离
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Sector3D 移动后的扇形（自身引用）
function Sector3D:move(v)
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
    self.center.x = self.center.x + moveX
    self.center.y = self.center.y + moveY
    self.center.z = self.center.z + moveZ
    return self
end

---获取扇形平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Sector3D 移动后的扇形副本
function Sector3D:moved(v)
    local result = self:clone()
    return result:move(v)
end

---使用欧拉角旋转扇形
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Sector3D 自身引用
---@overload fun(self: foundation.shape3D.Sector3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Sector3D
function Sector3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转扇形的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Sector3D 旋转后的扇形副本
---@overload fun(self: foundation.shape3D.Sector3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Sector3D
function Sector3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = self:clone()
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用四元数旋转扇形
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Sector3D 自身引用
---@overload fun(self: foundation.shape3D.Sector3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Sector3D
function Sector3D:rotateQuaternion(quaternion, center)
    if not quaternion then
        error("Rotation quaternion cannot be nil")
    end
    center = center or self.center
    self.center = quaternion:rotatePoint(self.center - center) + center
    self.rotation = quaternion * self.rotation
    return self
end

---使用四元数旋转扇形的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Sector3D 旋转后的扇形副本
---@overload fun(self: foundation.shape3D.Sector3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Sector3D
function Sector3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---使用角度制的欧拉角旋转扇形
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Sector3D 自身引用
---@overload fun(self: foundation.shape3D.Sector3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Sector3D
function Sector3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转扇形的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Sector3D 旋转后的扇形副本
---@overload fun(self: foundation.shape3D.Sector3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Sector3D
function Sector3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---将当前扇形缩放指定比例
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Sector3D 缩放后的扇形（自身引用）
---@overload fun(self: foundation.shape3D.Sector3D, scale: foundation.math.Vector3|number): foundation.shape3D.Sector3D
function Sector3D:scale(scale, center)
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
    center = center or self.center

    local scaleVec = Vector3.create(scaleX, scaleY, scaleZ)
    self.center = center + (self.center - center) * scaleVec
    self.radius = self.radius * math.sqrt(scaleVec.x * scaleVec.x + scaleVec.y * scaleVec.y)
    return self
end

---获取扇形缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Sector3D 缩放后的扇形副本
---@overload fun(self: foundation.shape3D.Sector3D, scale: foundation.math.Vector3|number): foundation.shape3D.Sector3D
function Sector3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---获取扇形的顶点
---@param segments number 分段数
---@return foundation.math.Vector3[] 扇形的顶点数组
---@overload fun(self: foundation.shape3D.Sector3D): foundation.math.Vector3[]
function Sector3D:getVertices(segments)
    segments = segments or 32
    local vertices = {}
    local angleStep = self:getAngle() / segments
    local startAngle = -self.range * math.pi
    for i = 0, segments do
        local angle = startAngle + i * angleStep
        local x = self.radius * math.cos(angle)
        local y = self.radius * math.sin(angle)
        local z = 0
        local vertex = Vector3.create(x, y, z)
        vertices[i + 1] = self.center + self.rotation:rotateVector(vertex)
    end
    return vertices
end

---获取扇形的边
---@return foundation.shape3D.Segment3D[] 扇形的边数组
function Sector3D:getEdges()
    local vertices = self:getVertices()
    local edges = {}
    for i = 1, #vertices - 1 do
        edges[i] = Segment3D.create(vertices[i], vertices[i + 1])
    end
    edges[#edges + 1] = Segment3D.create(vertices[1], vertices[#vertices])
    return edges
end

---检查点是否在扇形内部或边上
---@param point foundation.math.Vector3 要检查的点
---@return boolean 如果点在扇形内部或边上则返回true，否则返回false
function Sector3D:containsPoint(point)
    local localPoint = self.rotation:inverse():rotateVector(point - self.center)
    local dist2D = math.sqrt(localPoint.x * localPoint.x + localPoint.y * localPoint.y)
    if dist2D > self.radius then
        return false
    end

    local angle = math.atan2(localPoint.y, localPoint.x)
    local halfRange = self.range * math.pi
    return angle >= -halfRange and angle <= halfRange
end

---计算点到扇形的最短距离
---@param point foundation.math.Vector3 要计算距离的点
---@return number 点到扇形的最短距离
function Sector3D:distanceToPoint(point)
    local localPoint = self.rotation:inverse():rotateVector(point - self.center)
    local dist2D = math.sqrt(localPoint.x * localPoint.x + localPoint.y * localPoint.y)
    local distZ = math.abs(localPoint.z)

    if dist2D <= self.radius then
        local angle = math.atan2(localPoint.y, localPoint.x)
        local halfRange = self.range * math.pi
        if angle >= -halfRange and angle <= halfRange then
            return distZ
        end
    end

    local dx = dist2D - self.radius
    return math.sqrt(dx * dx + distZ * distZ)
end

---计算点到扇形的投影点
---@param point foundation.math.Vector3 要投影的点
---@return foundation.math.Vector3 点在扇形上的投影点
function Sector3D:projectPoint(point)
    local localPoint = self.rotation:inverse():rotateVector(point - self.center)
    local dist2D = math.sqrt(localPoint.x * localPoint.x + localPoint.y * localPoint.y)

    if dist2D <= 1e-10 then
        localPoint.x = self.radius
        localPoint.y = 0
    else
        local scale = self.radius / dist2D
        localPoint.x = localPoint.x * scale
        localPoint.y = localPoint.y * scale
    end
    localPoint.z = 0

    local angle = math.atan2(localPoint.y, localPoint.x)
    local halfRange = self.range * math.pi
    if angle < -halfRange then
        localPoint.x = self.radius * math.cos(-halfRange)
        localPoint.y = self.radius * math.sin(-halfRange)
    elseif angle > halfRange then
        localPoint.x = self.radius * math.cos(halfRange)
        localPoint.y = self.radius * math.sin(halfRange)
    end

    return self.center + self.rotation:rotateVector(localPoint)
end

ffi.metatype("foundation_shape3D_Sector3D", Sector3D)

return Sector3D

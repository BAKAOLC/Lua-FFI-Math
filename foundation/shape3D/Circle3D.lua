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

---获取圆的属性值
---@param self foundation.shape3D.Circle3D
---@param key string
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

---设置圆的属性值
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

---使用四元数创建一个新的圆
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

---创建一个新的圆，由中心点、半径和方向向量确定
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

---使用欧拉角创建一个新的圆
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

---使用欧拉角（角度制）创建一个新的圆
---@param center foundation.math.Vector3 圆的中心点
---@param radius number 圆的半径
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@return foundation.shape3D.Circle3D 新创建的圆
function Circle3D.createWithDegreeEulerAngles(center, radius, eulerX, eulerY, eulerZ)
    return Circle3D.createWithEulerAngles(center, radius, math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ))
end

---比较两个圆是否相等
---@param a foundation.shape3D.Circle3D 第一个圆
---@param b foundation.shape3D.Circle3D 第二个圆
---@return boolean 如果两个圆的所有属性都相等则返回true，否则返回false
function Circle3D.__eq(a, b)
    return a.center == b.center and
        math.abs(a.radius - b.radius) <= 1e-10 and
        a.rotation == b.rotation
end

---将圆转换为字符串表示
---@param self foundation.shape3D.Circle3D 要转换的圆
---@return string 圆的字符串表示
function Circle3D.__tostring(self)
    return string.format("Circle3D(center=%s, radius=%f, rotation=%s)",
        tostring(self.center), self.radius, tostring(self.rotation))
end

---创建圆的副本
---@return foundation.shape3D.Circle3D 圆的副本
function Circle3D:clone()
    return Circle3D.createWithQuaternion(self.center:clone(), self.radius, self.rotation:clone())
end

---获取圆的方向向量
---@return foundation.math.Vector3 圆的方向向量
function Circle3D:getDirection()
    return self.rotation:rotateVector(Vector3.create(1, 0, 0))
end

---获取圆的上方向向量
---@return foundation.math.Vector3 圆的上方向向量
function Circle3D:getUp()
    return self.rotation:rotateVector(Vector3.create(0, 1, 0))
end

---获取圆的右方向向量
---@return foundation.math.Vector3 圆的右方向向量
function Circle3D:getRight()
    return self.rotation:rotateVector(Vector3.create(0, 0, 1))
end

---计算圆的面积
---@return number 圆的面积
function Circle3D:area()
    return math.pi * self.radius * self.radius
end

---计算圆的周长
---@return number 圆的周长
function Circle3D:getPerimeter()
    return 2 * math.pi * self.radius
end

---获取圆的中心点
---@return foundation.math.Vector3 圆的中心点
function Circle3D:getCenter()
    return self.center:clone()
end

---获取圆的法向量
---@return foundation.math.Vector3 圆的法向量
function Circle3D:normal()
    return self.rotation:rotateVector(Vector3.create(0, 0, 1)):normalized()
end

---将当前圆平移指定距离
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Circle3D 移动后的圆（自身引用）
function Circle3D:move(v)
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

---获取圆平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Circle3D 移动后的圆副本
function Circle3D:moved(v)
    local result = self:clone()
    return result:move(v)
end

---使用欧拉角旋转圆
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Circle3D 自身引用
---@overload fun(self: foundation.shape3D.Circle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Circle3D
function Circle3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转圆的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number 旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Circle3D 旋转后的圆副本
---@overload fun(self: foundation.shape3D.Circle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Circle3D
function Circle3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = self:clone()
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用四元数旋转圆
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Circle3D 自身引用
---@overload fun(self: foundation.shape3D.Circle3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Circle3D
function Circle3D:rotateQuaternion(quaternion, center)
    center = center or self.center
    self.center = quaternion:rotatePoint(self.center - center) + center
    self.rotation = quaternion * self.rotation
    return self
end

---使用四元数旋转圆的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Circle3D 旋转后的圆副本
---@overload fun(self: foundation.shape3D.Circle3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Circle3D
function Circle3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---使用角度制的欧拉角旋转圆
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Circle3D 自身引用
---@overload fun(self: foundation.shape3D.Circle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Circle3D
function Circle3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转圆的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number 旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Circle3D 旋转后的圆副本
---@overload fun(self: foundation.shape3D.Circle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Circle3D
function Circle3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---将当前圆缩放指定比例
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Circle3D 缩放后的圆（自身引用）
---@overload fun(self: foundation.shape3D.Circle3D, scale: foundation.math.Vector3|number): foundation.shape3D.Circle3D
function Circle3D:scale(scale, center)
    center = center or self.center
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
    self.center = center + (self.center - center) * scaleVec
    self.radius = self.radius * math.sqrt(scaleVec.x * scaleVec.x + scaleVec.y * scaleVec.y)
    return self
end

---获取圆缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Circle3D 缩放后的圆副本
---@overload fun(self: foundation.shape3D.Circle3D, scale: foundation.math.Vector3|number): foundation.shape3D.Circle3D
function Circle3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---获取圆的顶点
---@param segments number 分段数
---@return foundation.math.Vector3[] 圆的顶点数组
function Circle3D:getVertices(segments)
    segments = segments or 32
    local vertices = {}
    local angleStep = 2 * math.pi / segments
    for i = 0, segments - 1 do
        local angle = i * angleStep
        local x = self.radius * math.cos(angle)
        local y = self.radius * math.sin(angle)
        local z = 0
        local vertex = Vector3.create(x, y, z)
        vertices[i + 1] = self.center + self.rotation:rotateVector(vertex)
    end
    return vertices
end

---检查点是否在圆内部或边上
---@param point foundation.math.Vector3 要检查的点
---@return boolean 如果点在圆内部或边上则返回true，否则返回false
function Circle3D:containsPoint(point)
    local localPoint = self.rotation:inverse():rotateVector(point - self.center)
    return localPoint.x * localPoint.x + localPoint.y * localPoint.y <= self.radius * self.radius
end

---计算点到圆的最短距离
---@param point foundation.math.Vector3 要计算距离的点
---@return number 点到圆的最短距离
function Circle3D:distanceToPoint(point)
    local localPoint = self.rotation:inverse():rotateVector(point - self.center)
    local dist2D = math.sqrt(localPoint.x * localPoint.x + localPoint.y * localPoint.y)
    local distZ = math.abs(localPoint.z)

    if dist2D <= self.radius then
        return distZ
    end

    local dx = dist2D - self.radius
    return math.sqrt(dx * dx + distZ * distZ)
end

---计算点到圆的投影点
---@param point foundation.math.Vector3 要投影的点
---@return foundation.math.Vector3 点在圆上的投影点
function Circle3D:projectPoint(point)
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

    return self.center + self.rotation:rotateVector(localPoint)
end

ffi.metatype("foundation_shape3D_Circle3D", Circle3D)

return Circle3D

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
local Segment3D = require("foundation.shape3D.Segment3D")
local Matrix = require("foundation.math.matrix.Matrix")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 center;
    double width;
    double height;
    foundation_math_Quaternion rotation;
} foundation_shape3D_Rectangle3D;
]]

---@class foundation.shape3D.Rectangle3D
---@field center foundation.math.Vector3 矩形的中心点
---@field width number 矩形的宽度
---@field height number 矩形的高度
---@field rotation foundation.math.Quaternion 矩形的旋转
local Rectangle3D = {}
Rectangle3D.__type = "foundation.shape3D.Rectangle3D"

---获取矩形的属性值
---@param self foundation.shape3D.Rectangle3D
---@param key string
---@return any
function Rectangle3D.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "width" then
        return self.__data.width
    elseif key == "height" then
        return self.__data.height
    elseif key == "rotation" then
        return self.__data.rotation
    end
    return Rectangle3D[key]
end

---设置矩形的属性值
---@param self foundation.shape3D.Rectangle3D
---@param key string
---@param value any
function Rectangle3D.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "width" then
        self.__data.width = value
    elseif key == "height" then
        self.__data.height = value
    elseif key == "rotation" then
        self.__data.rotation = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的矩形
---@param center foundation.math.Vector3 矩形的中心点
---@param width number 矩形的宽度
---@param height number 矩形的高度
---@param direction foundation.math.Vector3 矩形的方向向量
---@param up foundation.math.Vector3 矩形的上方向向量
---@return foundation.shape3D.Rectangle3D 新创建的矩形
---@overload fun(center: foundation.math.Vector3, width: number, height: number, direction: foundation.math.Vector3): foundation.shape3D.Rectangle3D
---@overload fun(center: foundation.math.Vector3, width: number, height: number): foundation.shape3D.Rectangle3D
function Rectangle3D.create(center, width, height, direction, up)
    if not center then
        error("Center point cannot be nil")
    end
    width = width or 1
    height = height or 1

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

    local rectangle = ffi.new("foundation_shape3D_Rectangle3D", center, width, height, rotation)
    local result = {
        __data = rectangle,
    }
    return setmetatable(result, Rectangle3D)
end

---使用四元数创建一个新的矩形
---@param center foundation.math.Vector3 矩形的中心点
---@param width number 矩形的宽度
---@param height number 矩形的高度
---@param rotation foundation.math.Quaternion 矩形的旋转四元数
---@return foundation.shape3D.Rectangle3D 新创建的矩形
function Rectangle3D.createWithQuaternion(center, width, height, rotation)
    if not center then
        error("Center point cannot be nil")
    end
    width = width or 1
    height = height or 1
    rotation = rotation or Quaternion.identity()

    local rectangle = ffi.new("foundation_shape3D_Rectangle3D", center, width, height, rotation)
    local result = {
        __data = rectangle,
    }
    return setmetatable(result, Rectangle3D)
end

---根据两个点创建一个新的矩形
---@param p1 foundation.math.Vector3 第一个点
---@param p2 foundation.math.Vector3 第二个点
---@param width number 矩形的宽度
---@param height number 矩形的高度
---@return foundation.shape3D.Rectangle3D 新创建的矩形
function Rectangle3D.createFromPoints(p1, p2, width, height)
    local direction = p2 - p1
    local center = (p1 + p2) / 2
    return Rectangle3D.create(center, width, height, direction)
end

---根据弧度创建一个新的矩形
---@param center foundation.math.Vector3 中心点
---@param width number 宽度
---@param height number 高度
---@param theta number 仰角（与XY平面的夹角，范围[-π,π]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
---@return foundation.shape3D.Rectangle3D 新创建的矩形
function Rectangle3D.createFromRad(center, width, height, theta, phi)
    local direction = Vector3.createFromRad(theta, phi)
    return Rectangle3D.create(center, width, height, direction)
end

---根据角度创建一个新的矩形
---@param center foundation.math.Vector3 中心点
---@param width number 宽度
---@param height number 高度
---@param theta number 仰角（与XY平面的夹角，范围[-180,180]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
---@return foundation.shape3D.Rectangle3D 新创建的矩形
function Rectangle3D.createFromAngle(center, width, height, theta, phi)
    return Rectangle3D.createFromRad(center, width, height, math.rad(theta), math.rad(phi))
end

---使用欧拉角创建一个新的矩形
---@param center foundation.math.Vector3 矩形的中心点
---@param width number 矩形的宽度
---@param height number 矩形的高度
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@return foundation.shape3D.Rectangle3D 新创建的矩形
function Rectangle3D.createWithEulerAngles(center, width, height, eulerX, eulerY, eulerZ)
    if not center then
        error("Center point cannot be nil")
    end
    width = width or 1
    height = height or 1

    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    local rectangle = ffi.new("foundation_shape3D_Rectangle3D", center, width, height, rotation)
    local result = {
        __data = rectangle,
    }
    return setmetatable(result, Rectangle3D)
end

---使用欧拉角（角度制）创建一个新的矩形
---@param center foundation.math.Vector3 矩形的中心点
---@param width number 矩形的宽度
---@param height number 矩形的高度
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@return foundation.shape3D.Rectangle3D 新创建的矩形
function Rectangle3D.createWithDegreeEulerAngles(center, width, height, eulerX, eulerY, eulerZ)
    return Rectangle3D.createWithEulerAngles(center, width, height, math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ))
end

---比较两个矩形是否相等
---@param a foundation.shape3D.Rectangle3D 第一个矩形
---@param b foundation.shape3D.Rectangle3D 第二个矩形
---@return boolean 如果两个矩形的所有属性都相等则返回true，否则返回false
function Rectangle3D.__eq(a, b)
    return a.center == b.center and
        math.abs(a.width - b.width) <= 1e-10 and
        math.abs(a.height - b.height) <= 1e-10 and
        a.rotation == b.rotation
end

---将矩形转换为字符串表示
---@param self foundation.shape3D.Rectangle3D 要转换的矩形
---@return string 矩形的字符串表示
function Rectangle3D.__tostring(self)
    return string.format("Rectangle3D(center=%s, width=%f, height=%f, rotation=%s)",
        tostring(self.center), self.width, self.height, tostring(self.rotation))
end

---创建矩形的副本
---@return foundation.shape3D.Rectangle3D 矩形的副本
function Rectangle3D:clone()
    return Rectangle3D.createWithQuaternion(self.center:clone(), self.width, self.height, self.rotation:clone())
end

---获取矩形的方向向量
---@return foundation.math.Vector3 矩形的方向向量
function Rectangle3D:getDirection()
    return self.rotation:rotateVector(Vector3.create(1, 0, 0))
end

---获取矩形的上方向向量
---@return foundation.math.Vector3 矩形的上方向向量
function Rectangle3D:getUp()
    return self.rotation:rotateVector(Vector3.create(0, 1, 0))
end

---获取矩形的右方向向量
---@return foundation.math.Vector3 矩形的右方向向量
function Rectangle3D:getRight()
    return self.rotation:rotateVector(Vector3.create(0, 0, 1))
end

---获取矩形的四个顶点
---@return foundation.math.Vector3[] 矩形的四个顶点
function Rectangle3D:getVertices()
    local halfWidth = self.width / 2
    local halfHeight = self.height / 2
    local vertices = {
        self.center + self.rotation:rotateVector(Vector3.create(-halfWidth, -halfHeight, 0)),
        self.center + self.rotation:rotateVector(Vector3.create(halfWidth, -halfHeight, 0)),
        self.center + self.rotation:rotateVector(Vector3.create(halfWidth, halfHeight, 0)),
        self.center + self.rotation:rotateVector(Vector3.create(-halfWidth, halfHeight, 0))
    }
    return vertices
end

---获取矩形的四条边
---@return foundation.shape3D.Segment3D[] 矩形的四条边
function Rectangle3D:getEdges()
    local vertices = self:getVertices()
    return {
        Segment3D.create(vertices[1], vertices[2]),
        Segment3D.create(vertices[2], vertices[3]),
        Segment3D.create(vertices[3], vertices[4]),
        Segment3D.create(vertices[4], vertices[1])
    }
end

---将当前矩形平移指定距离
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Rectangle3D 移动后的矩形（自身引用）
function Rectangle3D:move(v)
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

---获取矩形平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Rectangle3D 移动后的矩形副本
function Rectangle3D:moved(v)
    local result = self:clone()
    return result:move(v)
end

---使用欧拉角旋转矩形
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Rectangle3D 自身引用
---@overload fun(self: foundation.shape3D.Rectangle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Rectangle3D
function Rectangle3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转矩形的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Rectangle3D 旋转后的矩形副本
---@overload fun(self: foundation.shape3D.Rectangle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Rectangle3D
function Rectangle3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = self:clone()
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用四元数旋转矩形
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Rectangle3D 自身引用
---@overload fun(self: foundation.shape3D.Rectangle3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Rectangle3D
function Rectangle3D:rotateQuaternion(quaternion, center)
    center = center or self.center
    self.center = quaternion:rotatePoint(self.center - center) + center
    self.rotation = quaternion * self.rotation
    return self
end

---使用四元数旋转矩形的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Rectangle3D 旋转后的矩形副本
---@overload fun(self: foundation.shape3D.Rectangle3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Rectangle3D
function Rectangle3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---使用角度制的欧拉角旋转矩形
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Rectangle3D 自身引用
---@overload fun(self: foundation.shape3D.Rectangle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Rectangle3D
function Rectangle3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转矩形的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Rectangle3D 旋转后的矩形副本
---@overload fun(self: foundation.shape3D.Rectangle3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Rectangle3D
function Rectangle3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---将当前矩形缩放指定比例
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Rectangle3D 缩放后的矩形（自身引用）
---@overload fun(self: foundation.shape3D.Rectangle3D, scale: foundation.math.Vector3|number): foundation.shape3D.Rectangle3D
function Rectangle3D:scale(scale, center)
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
    self.width = self.width * scaleVec.x
    self.height = self.height * scaleVec.y
    return self
end

---获取矩形缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Rectangle3D 缩放后的矩形副本
---@overload fun(self: foundation.shape3D.Rectangle3D, scale: foundation.math.Vector3|number): foundation.shape3D.Rectangle3D
function Rectangle3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---计算3D矩形的面积
---@return number 矩形的面积
function Rectangle3D:area()
    return self.width * self.height
end

---计算3D矩形的周长
---@return number 矩形的周长
function Rectangle3D:getPerimeter()
    return 2 * (self.width + self.height)
end

---计算3D矩形的中心
---@return foundation.math.Vector3 矩形的中心
function Rectangle3D:getCenter()
    return self.center:clone()
end

---计算3D矩形的法向量
---@return foundation.math.Vector3 矩形的法向量
function Rectangle3D:normal()
    return self.rotation:rotateVector(Vector3.create(0, 0, 1)):normalized()
end

---计算点到3D矩形的最近点
---@param point foundation.math.Vector3
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector3
---@overload fun(self: foundation.shape3D.Rectangle3D, point: foundation.math.Vector3): foundation.math.Vector3
function Rectangle3D:closestPoint(point, boundary)
    if not boundary and self:contains(point) then
        return point:clone()
    end
    local edges = self:getEdges()
    local minDistance = math.huge
    local closestPoint
    for _, edge in ipairs(edges) do
        local edgeClosest = edge:closestPoint(point)
        local distance = (point - edgeClosest):length()
        if distance < minDistance then
            minDistance = distance
            closestPoint = edgeClosest
        end
    end
    return closestPoint
end

---计算点到3D矩形的距离
---@param point foundation.math.Vector3
---@return number
function Rectangle3D:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end
    local edges = self:getEdges()
    local minDistance = math.huge
    for _, edge in ipairs(edges) do
        local distance = edge:distanceToPoint(point)
        if distance < minDistance then
            minDistance = distance
        end
    end
    return minDistance
end

---将点投影到3D矩形平面上
---@param point foundation.math.Vector3
---@return foundation.math.Vector3
function Rectangle3D:projectPoint(point)
    local normal = self:normal()
    local v1p = point - self.center
    local dist = v1p:dot(normal)
    return point - normal * dist
end

---检查点是否在3D矩形边界上
---@param point foundation.math.Vector3
---@param tolerance number|nil 默认为1e-10
---@return boolean
function Rectangle3D:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:containsPoint(point, tolerance) then
            return true
        end
    end
    return false
end

---检查点是否在矩形表面或内部
---@param point foundation.math.Vector3 要检查的点
---@return boolean 如果点在矩形表面或内部则返回true，否则返回false
function Rectangle3D:contains(point)
    local localPoint = self.rotation:inverse():rotatePoint(point - self.center)
    local halfWidth = self.width / 2
    local halfHeight = self.height / 2
    if math.abs(localPoint.x) > 1e-10 then
        return false
    end
    return math.abs(localPoint.y) <= halfWidth and math.abs(localPoint.z) <= halfHeight
end

ffi.metatype("foundation_shape3D_Rectangle3D", Rectangle3D)

return Rectangle3D

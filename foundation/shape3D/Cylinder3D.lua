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
local Circle3D = require("foundation.shape3D.Circle3D")
local Shape3DIntersector = require("foundation.shape3D.Shape3DIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 center;
    foundation_math_Vector3 direction;
    double radius;
    double height;
} foundation_shape3D_Cylinder3D;
]]

---@class foundation.shape3D.Cylinder3D
---@field center foundation.math.Vector3 圆柱体的中心点
---@field direction foundation.math.Vector3 圆柱体的轴向（单位向量）
---@field radius number 圆柱体的半径
---@field height number 圆柱体的高度
local Cylinder3D = {}
Cylinder3D.__type = "foundation.shape3D.Cylinder3D"

---@param self foundation.shape3D.Cylinder3D
---@param key string
---@return any
function Cylinder3D.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "direction" then
        return self.__data.direction
    elseif key == "radius" then
        return self.__data.radius
    elseif key == "height" then
        return self.__data.height
    end
    return Cylinder3D[key]
end

---@param self foundation.shape3D.Cylinder3D
---@param key string
---@param value any
function Cylinder3D.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "direction" then
        self.__data.direction = value
    elseif key == "radius" then
        self.__data.radius = value
    elseif key == "height" then
        self.__data.height = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的3D圆柱体
---@param center foundation.math.Vector3 圆柱体的中心点
---@param direction foundation.math.Vector3 圆柱体的轴向（会被自动归一化）
---@param radius number 圆柱体的半径
---@param height number 圆柱体的高度
---@return foundation.shape3D.Cylinder3D 新创建的圆柱体
function Cylinder3D.create(center, direction, radius, height)
    direction = direction:normalized()
    local cylinder = ffi.new("foundation_shape3D_Cylinder3D", center, direction, radius, height)
    local result = {
        __data = cylinder,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Cylinder3D)
end

---3D圆柱体相等比较
---@param a foundation.shape3D.Cylinder3D 第一个圆柱体
---@param b foundation.shape3D.Cylinder3D 第二个圆柱体
---@return boolean 如果两个圆柱体的所有属性都相等则返回true，否则返回false
function Cylinder3D.__eq(a, b)
    return a.center == b.center and a.direction == b.direction and a.radius == b.radius and a.height == b.height
end

---3D圆柱体转字符串表示
---@param c foundation.shape3D.Cylinder3D 要转换的圆柱体
---@return string 圆柱体的字符串表示
function Cylinder3D.__tostring(c)
    return string.format("Cylinder3D(center=%s, direction=%s, radius=%f, height=%f)",
        tostring(c.center), tostring(c.direction), c.radius, c.height)
end

---计算3D圆柱体的体积
---@return number 圆柱体的体积
function Cylinder3D:volume()
    return math.pi * self.radius * self.radius * self.height
end

---计算3D圆柱体的表面积
---@return number 圆柱体的表面积
function Cylinder3D:surfaceArea()
    local circleArea = math.pi * self.radius * self.radius
    local sideArea = 2 * math.pi * self.radius * self.height
    return 2 * circleArea + sideArea
end

---获取圆柱体的顶点
---@param segments number|nil 圆周分段数，默认为16
---@return foundation.math.Vector3[] 圆柱体的顶点数组
function Cylinder3D:getVertices(segments)
    segments = segments or 16
    local vertices = {}
    local bottomCenter, topCenter = self:getEndCenters()

    local up = Vector3.create(0, 1, 0)
    if math.abs(self.direction:dot(up)) > 0.9 then
        up = Vector3.create(1, 0, 0)
    end
    local right = self.direction:cross(up):normalized()
    up = self.direction:cross(right):normalized()

    for i = 0, segments - 1 do
        local angle = i * 2 * math.pi / segments
        local cos = math.cos(angle)
        local sin = math.sin(angle)

        local bottomPoint = bottomCenter + (right * cos + up * sin) * self.radius
        vertices[#vertices + 1] = bottomPoint

        local topPoint = topCenter + (right * cos + up * sin) * self.radius
        vertices[#vertices + 1] = topPoint
    end

    return vertices
end

---获取圆柱体的两个端面圆心
---@return foundation.math.Vector3 bottomCenter 底面圆心
---@return foundation.math.Vector3 topCenter 顶面圆心
function Cylinder3D:getEndCenters()
    local halfHeight = self.height / 2
    local bottomCenter = self.center - self.direction * halfHeight
    local topCenter = self.center + self.direction * halfHeight
    return bottomCenter, topCenter
end

---获取圆柱体的两个端面
---@return foundation.shape3D.Circle3D bottomCircle 底面
---@return foundation.shape3D.Circle3D topCircle 顶面
function Cylinder3D:getEndCircles()
    local bottomCenter, topCenter = self:getEndCenters()
    local rotation = Quaternion.createFromDirection(self.direction)
    return Circle3D.createWithQuaternion(bottomCenter, self.radius, rotation),
        Circle3D.createWithQuaternion(topCenter, self.radius, rotation)
end

---将当前3D圆柱体平移指定距离（更改当前圆柱体）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Cylinder3D 移动后的圆柱体（自身引用）
function Cylinder3D:move(v)
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

---获取3D圆柱体平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Cylinder3D 移动后的圆柱体副本
function Cylinder3D:moved(v)
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
    return Cylinder3D.create(
        Vector3.create(self.center.x + moveX, self.center.y + moveY, self.center.z + moveZ),
        self.direction,
        self.radius,
        self.height
    )
end

---使用欧拉角旋转圆柱体（更改当前圆柱体）
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆柱体中心
---@return foundation.shape3D.Cylinder3D 自身引用
function Cylinder3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转圆柱体的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆柱体中心
---@return foundation.shape3D.Cylinder3D 旋转后的圆柱体副本
function Cylinder3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = Cylinder3D.create(self.center, self.direction, self.radius, self.height)
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用角度制的欧拉角旋转圆柱体（更改当前圆柱体）
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆柱体中心
---@return foundation.shape3D.Cylinder3D 自身引用
function Cylinder3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转圆柱体的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆柱体中心
---@return foundation.shape3D.Cylinder3D 旋转后的圆柱体副本
function Cylinder3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用四元数旋转圆柱体（更改当前圆柱体）
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆柱体中心
---@return foundation.shape3D.Cylinder3D 自身引用
function Cylinder3D:rotateQuaternion(quaternion, center)
    center = center or self.center
    self.center = quaternion:rotatePoint(self.center - center) + center
    self.direction = quaternion:rotatePoint(self.direction)
    return self
end

---计算3D圆柱体的轴对齐包围盒（AABB）
---@return number minX 最小X坐标
---@return number maxX 最大X坐标
---@return number minY 最小Y坐标
---@return number maxY 最大Y坐标
---@return number minZ 最小Z坐标
---@return number maxZ 最大Z坐标
function Cylinder3D:AABB()
    local bottomCenter, topCenter = self:getEndCenters()
    local minX = math.min(bottomCenter.x, topCenter.x) - self.radius
    local maxX = math.max(bottomCenter.x, topCenter.x) + self.radius
    local minY = math.min(bottomCenter.y, topCenter.y) - self.radius
    local maxY = math.max(bottomCenter.y, topCenter.y) + self.radius
    local minZ = math.min(bottomCenter.z, topCenter.z) - self.radius
    local maxZ = math.max(bottomCenter.z, topCenter.z) + self.radius
    return minX, maxX, minY, maxY, minZ, maxZ
end

---检查点是否在圆柱体内部或表面上
---@param point foundation.math.Vector3 要检查的点
---@return boolean 如果点在圆柱体内部或表面上则返回true，否则返回false
function Cylinder3D:containsPoint(point)
    local bottomCenter, topCenter = self:getEndCenters()
    local toPoint = point - bottomCenter
    local axis = topCenter - bottomCenter
    local axisLength = axis:length()
    local axisDir = axis / axisLength

    local projection = toPoint:dot(axisDir)
    if projection < 0 or projection > axisLength then
        return false
    end

    local pointOnAxis = bottomCenter + axisDir * projection
    local distanceToAxis = (point - pointOnAxis):length()
    return distanceToAxis <= self.radius
end

---计算点到圆柱体表面的最短距离
---@param point foundation.math.Vector3 要计算距离的点
---@return number 点到圆柱体表面的最短距离，如果点在圆柱体内部则返回负值
function Cylinder3D:distanceToPoint(point)
    local bottomCenter, topCenter = self:getEndCenters()
    local toPoint = point - bottomCenter
    local axis = topCenter - bottomCenter
    local axisLength = axis:length()
    local axisDir = axis / axisLength

    local projection = toPoint:dot(axisDir)
    local pointOnAxis

    if projection < 0 then
        pointOnAxis = bottomCenter
    elseif projection > axisLength then
        pointOnAxis = topCenter
    else
        pointOnAxis = bottomCenter + axisDir * projection
    end

    local distanceToAxis = (point - pointOnAxis):length()
    return distanceToAxis - self.radius
end

---获取圆柱体的包围盒尺寸
---@return foundation.math.Vector3 包围盒的尺寸
function Cylinder3D:getBoundingBoxSize()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return Vector3.create(maxX - minX, maxY - minY, maxZ - minZ)
end

---将点投影到圆柱体表面上
---@param point foundation.math.Vector3 要投影的点
---@return foundation.math.Vector3 投影点
function Cylinder3D:projectPoint(point)
    local bottomCenter, topCenter = self:getEndCenters()
    local toPoint = point - bottomCenter
    local axis = topCenter - bottomCenter
    local axisLength = axis:length()
    local axisDir = axis / axisLength

    local projection = toPoint:dot(axisDir)
    local pointOnAxis

    if projection < 0 then
        pointOnAxis = bottomCenter
    elseif projection > axisLength then
        pointOnAxis = topCenter
    else
        pointOnAxis = bottomCenter + axisDir * projection
    end

    local toAxis = point - pointOnAxis
    local distanceToAxis = toAxis:length()

    if distanceToAxis == 0 then
        return pointOnAxis + Vector3.create(self.radius, 0, 0)
    end

    return pointOnAxis + toAxis * (self.radius / distanceToAxis)
end

---使用四元数旋转圆柱体的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为圆柱体中心
---@return foundation.shape3D.Cylinder3D 旋转后的圆柱体副本
function Cylinder3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---将当前圆柱体缩放指定比例（更改当前圆柱体）
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3|nil 缩放中心点，默认为圆柱体中心
---@return foundation.shape3D.Cylinder3D 缩放后的圆柱体（自身引用）
function Cylinder3D:scale(scale, center)
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
    local axisScale = self.direction:dot(scaleVec)
    local radialScale = math.sqrt(
        (scaleX * scaleX + scaleY * scaleY + scaleZ * scaleZ - axisScale * axisScale) / 2
    )

    self.center = center + (self.center - center) * scaleVec
    self.radius = self.radius * radialScale
    self.height = self.height * axisScale
    return self
end

---获取圆柱体缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3|nil 缩放中心点，默认为圆柱体中心
---@return foundation.shape3D.Cylinder3D 缩放后的圆柱体副本
function Cylinder3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---创建圆柱体的副本
---@return foundation.shape3D.Cylinder3D 圆柱体的副本
function Cylinder3D:clone()
    return Cylinder3D.create(self.center, self.direction, self.radius, self.height)
end

return Cylinder3D

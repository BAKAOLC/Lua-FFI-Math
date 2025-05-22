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
local Shape3DIntersector = require("foundation.shape3D.Shape3DIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 center;
    double radius;
} foundation_shape3D_Sphere3D;
]]

---@class foundation.shape3D.Sphere3D
---@field center foundation.math.Vector3 球体的中心点
---@field radius number 球体的半径
local Sphere3D = {}
Sphere3D.__type = "foundation.shape3D.Sphere3D"

---@param self foundation.shape3D.Sphere3D
---@param key string
---@return any
function Sphere3D.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "radius" then
        return self.__data.radius
    end
    return Sphere3D[key]
end

---@param self foundation.shape3D.Sphere3D
---@param key string
---@param value any
function Sphere3D.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "radius" then
        self.__data.radius = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的3D球体
---@param center foundation.math.Vector3 球体的中心点
---@param radius number 球体的半径
---@return foundation.shape3D.Sphere3D 新创建的球体
function Sphere3D.create(center, radius)
    local sphere = ffi.new("foundation_shape3D_Sphere3D", center, radius)
    local result = {
        __data = sphere,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Sphere3D)
end

---3D球体相等比较
---@param a foundation.shape3D.Sphere3D 第一个球体
---@param b foundation.shape3D.Sphere3D 第二个球体
---@return boolean 如果两个球体的所有属性都相等则返回true，否则返回false
function Sphere3D.__eq(a, b)
    return a.center == b.center and a.radius == b.radius
end

---3D球体转字符串表示
---@param s foundation.shape3D.Sphere3D 要转换的球体
---@return string 球体的字符串表示
function Sphere3D.__tostring(s)
    return string.format("Sphere3D(center=%s, radius=%f)", tostring(s.center), s.radius)
end

---计算3D球体的体积
---@return number 球体的体积
function Sphere3D:volume()
    return (4 / 3) * math.pi * self.radius * self.radius * self.radius
end

---计算3D球体的表面积
---@return number 球体的表面积
function Sphere3D:surfaceArea()
    return 4 * math.pi * self.radius * self.radius
end

---计算3D球体的直径
---@return number 球体的直径
function Sphere3D:diameter()
    return 2 * self.radius
end

---计算3D球体的周长
---@return number 球体的周长
function Sphere3D:circumference()
    return 2 * math.pi * self.radius
end

---获取球体的顶点
---@param segments number|nil 经度分段数，默认为16
---@param rings number|nil 纬度分段数，默认为8
---@return foundation.math.Vector3[] 球体的顶点数组
function Sphere3D:getVertices(segments, rings)
    segments = segments or 16
    rings = rings or 8
    local vertices = {}

    for i = 0, rings do
        local phi = i * math.pi / rings
        local sinPhi = math.sin(phi)
        local cosPhi = math.cos(phi)

        local currentSegments = (i == 0 or i == rings) and 1 or segments

        for j = 0, currentSegments - 1 do
            local theta = j * 2 * math.pi / currentSegments
            local sinTheta = math.sin(theta)
            local cosTheta = math.cos(theta)

            local x = sinPhi * cosTheta
            local y = cosPhi
            local z = sinPhi * sinTheta

            local point = Vector3.create(
                self.center.x + x * self.radius,
                self.center.y + y * self.radius,
                self.center.z + z * self.radius
            )
            vertices[#vertices + 1] = point
        end
    end

    return vertices
end

---将当前3D球体平移指定距离（更改当前球体）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Sphere3D 移动后的球体（自身引用）
function Sphere3D:move(v)
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

---获取3D球体平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Sphere3D 移动后的球体副本
function Sphere3D:moved(v)
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
    return Sphere3D.create(
        Vector3.create(self.center.x + moveX, self.center.y + moveY, self.center.z + moveZ),
        self.radius
    )
end

---计算3D球体的轴对齐包围盒（AABB）
---@return number minX 最小X坐标
---@return number maxX 最大X坐标
---@return number minY 最小Y坐标
---@return number maxY 最大Y坐标
---@return number minZ 最小Z坐标
---@return number maxZ 最大Z坐标
function Sphere3D:AABB()
    return self.center.x - self.radius, self.center.x + self.radius,
        self.center.y - self.radius, self.center.y + self.radius,
        self.center.z - self.radius, self.center.z + self.radius
end

---检查点是否在球体内部或表面上
---@param point foundation.math.Vector3 要检查的点
---@return boolean 如果点在球体内部或表面上则返回true，否则返回false
function Sphere3D:containsPoint(point)
    local dx = point.x - self.center.x
    local dy = point.y - self.center.y
    local dz = point.z - self.center.z
    return dx * dx + dy * dy + dz * dz <= self.radius * self.radius
end

---计算点到球体表面的最短距离
---@param point foundation.math.Vector3 要计算距离的点
---@return number 点到球体表面的最短距离，如果点在球体内部则返回负值
function Sphere3D:distanceToPoint(point)
    local dx = point.x - self.center.x
    local dy = point.y - self.center.y
    local dz = point.z - self.center.z
    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    return distance - self.radius
end

---计算球体与另一个球体的最短距离
---@param other foundation.shape3D.Sphere3D 另一个球体
---@return number 两个球体之间的最短距离，如果球体相交则返回负值
function Sphere3D:distanceToSphere(other)
    local dx = other.center.x - self.center.x
    local dy = other.center.y - self.center.y
    local dz = other.center.z - self.center.z
    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    return distance - (self.radius + other.radius)
end

---检查球体是否与另一个球体相交
---@param other foundation.shape3D.Sphere3D 另一个球体
---@return boolean 如果两个球体相交则返回true，否则返回false
function Sphere3D:intersectsSphere(other)
    local dx = other.center.x - self.center.x
    local dy = other.center.y - self.center.y
    local dz = other.center.z - self.center.z
    local distanceSquared = dx * dx + dy * dy + dz * dz
    local radiusSum = self.radius + other.radius
    return distanceSquared <= radiusSum * radiusSum
end

---获取球体的包围盒尺寸
---@return foundation.math.Vector3 包围盒的尺寸
function Sphere3D:getBoundingBoxSize()
    local diameter = self:diameter()
    return Vector3.create(diameter, diameter, diameter)
end

---将点投影到球体表面上
---@param point foundation.math.Vector3 要投影的点
---@return foundation.math.Vector3 投影点
function Sphere3D:projectPoint(point)
    local toPoint = point - self.center
    local distance = toPoint:length()
    if distance == 0 then
        return self.center + Vector3.create(self.radius, 0, 0)
    end
    return self.center + toPoint * (self.radius / distance)
end

---使用四元数旋转球体（更改当前球体）
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为球体中心
---@return foundation.shape3D.Sphere3D 自身引用
function Sphere3D:rotateQuaternion(quaternion, center)
    center = center or self.center
    self.center = quaternion:rotatePoint(self.center - center) + center
    return self
end

---使用四元数旋转球体的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3|nil 旋转中心点，默认为球体中心
---@return foundation.shape3D.Sphere3D 旋转后的球体副本
function Sphere3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---使用欧拉角旋转球体（更改当前球体）
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为球体中心
---@return foundation.shape3D.Sphere3D 自身引用
function Sphere3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转球体的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为球体中心
---@return foundation.shape3D.Sphere3D 旋转后的球体副本
function Sphere3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = Sphere3D.create(self.center, self.radius)
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用角度制的欧拉角旋转球体（更改当前球体）
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为球体中心
---@return foundation.shape3D.Sphere3D 自身引用
function Sphere3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转球体的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3|nil 旋转中心点，默认为球体中心
---@return foundation.shape3D.Sphere3D 旋转后的球体副本
function Sphere3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---将当前球体缩放指定比例（更改当前球体）
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3|nil 缩放中心点，默认为球体中心
---@return foundation.shape3D.Sphere3D 缩放后的球体（自身引用）
function Sphere3D:scale(scale, center)
    center = center or self.center
    local scaleValue
    if type(scale) == "number" then
        scaleValue = scale
    else
        scaleValue = (scale.x + scale.y + scale.z) / 3
    end

    self.center = center + (self.center - center) * scaleValue
    self.radius = self.radius * scaleValue
    return self
end

---获取球体缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3|nil 缩放中心点，默认为球体中心
---@return foundation.shape3D.Sphere3D 缩放后的球体副本
function Sphere3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---创建球体的副本
---@return foundation.shape3D.Sphere3D 球体的副本
function Sphere3D:clone()
    return Sphere3D.create(self.center, self.radius)
end

---在球体表面生成均匀分布的点
---@param numPoints number 要生成的点的数量
---@return foundation.math.Vector3[] 均匀分布的点数组
function Sphere3D:samplePoints(numPoints)
    local points = {}
    local goldenRatio = (math.sqrt(5) - 1) / 2
    local angleIncrement = 2 * math.pi * goldenRatio
    
    for i = 0, numPoints - 1 do
        local phi = math.acos(1 - 2 * (i + 0.5) / numPoints)
        local theta = angleIncrement * i
        
        local x = math.sin(phi) * math.cos(theta)
        local y = math.sin(phi) * math.sin(theta)
        local z = math.cos(phi)
        
        local point = Vector3.create(
            self.center.x + x * self.radius,
            self.center.y + y * self.radius,
            self.center.z + z * self.radius
        )
        points[#points + 1] = point
    end
    
    return points
end

return Sphere3D

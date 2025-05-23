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
local Rectangle3D = require("foundation.shape3D.Rectangle3D")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 center;
    double width;
    double height;
    double depth;
    foundation_math_Quaternion rotation;
} foundation_shape3D_Cube3D;
]]

---@class foundation.shape3D.Cube3D
---@field center foundation.math.Vector3 立方体的中心点
---@field width number 立方体的宽度
---@field height number 立方体的高度
---@field depth number 立方体的深度
---@field rotation foundation.math.Quaternion 立方体的旋转四元数
local Cube3D = {}
Cube3D.__type = "foundation.shape3D.Cube3D"

---获取立方体的属性值
---@param self foundation.shape3D.Cube3D
---@param key string
---@return any
function Cube3D.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "width" then
        return self.__data.width
    elseif key == "height" then
        return self.__data.height
    elseif key == "depth" then
        return self.__data.depth
    elseif key == "rotation" then
        return self.__data.rotation
    end
    return Cube3D[key]
end

---设置立方体的属性值
---@param self foundation.shape3D.Cube3D
---@param key string
---@param value any
function Cube3D.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "width" then
        self.__data.width = value
    elseif key == "height" then
        self.__data.height = value
    elseif key == "depth" then
        self.__data.depth = value
    elseif key == "rotation" then
        self.__data.rotation = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的立方体
---@param center foundation.math.Vector3 立方体的中心点
---@param width number 立方体的宽度
---@param height number 立方体的高度
---@param depth number 立方体的深度
---@param rotation foundation.math.Quaternion 立方体的旋转四元数
---@return foundation.shape3D.Cube3D 新创建的立方体
---@overload fun(center: foundation.math.Vector3, size: number, rotation: foundation.math.Quaternion): foundation.shape3D.Cube3D
---@overload fun(center: foundation.math.Vector3, size: number): foundation.shape3D.Cube3D
function Cube3D.create(center, width, height, depth, rotation)
    if type(width) == "number" and height == nil and depth == nil then
        height = width
        depth = width
    end
    rotation = rotation or Quaternion.create()
    local cube = ffi.new("foundation_shape3D_Cube3D", center, width, height, depth, rotation)
    local result = {
        __data = cube,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Cube3D)
end

---比较两个立方体是否相等
---@param a foundation.shape3D.Cube3D 第一个立方体
---@param b foundation.shape3D.Cube3D 第二个立方体
---@return boolean 如果两个立方体的所有属性都相等则返回true，否则返回false
function Cube3D.__eq(a, b)
    return a.center == b.center and a.width == b.width and a.height == b.height and a.depth == b.depth and
        a.rotation == b.rotation
end

---将立方体转换为字符串表示
---@param c foundation.shape3D.Cube3D 要转换的立方体
---@return string 立方体的字符串表示
function Cube3D.__tostring(c)
    return string.format("Cube3D(center=%s, width=%f, height=%f, depth=%f, rotation=%s)",
        tostring(c.center), c.width, c.height, c.depth, tostring(c.rotation))
end

---计算立方体的体积
---@return number 立方体的体积
function Cube3D:volume()
    return self.width * self.height * self.depth
end

---计算立方体的表面积
---@return number 立方体的表面积
function Cube3D:surfaceArea()
    return 2 * (self.width * self.height + self.height * self.depth + self.depth * self.width)
end

---创建立方体的副本
---@return foundation.shape3D.Cube3D 立方体的副本
function Cube3D:clone()
    return Cube3D.create(self.center:clone(), self.width, self.height, self.depth, self.rotation:clone())
end

---获取立方体的8个顶点
---@return foundation.math.Vector3[] 立方体的8个顶点
function Cube3D:getVertices()
    local halfWidth = self.width / 2
    local halfHeight = self.height / 2
    local halfDepth = self.depth / 2
    local vertices = {
        Vector3.create(-halfWidth, -halfHeight, -halfDepth),
        Vector3.create(halfWidth, -halfHeight, -halfDepth),
        Vector3.create(halfWidth, halfHeight, -halfDepth),
        Vector3.create(-halfWidth, halfHeight, -halfDepth),
        Vector3.create(-halfWidth, -halfHeight, halfDepth),
        Vector3.create(halfWidth, -halfHeight, halfDepth),
        Vector3.create(halfWidth, halfHeight, halfDepth),
        Vector3.create(-halfWidth, halfHeight, halfDepth)
    }

    for i, vertex in ipairs(vertices) do
        vertices[i] = self.rotation:rotatePoint(vertex) + self.center
    end

    return vertices
end

---获取立方体的6个面
---@return foundation.shape3D.Rectangle3D[] 立方体的6个面
function Cube3D:getFaces()
    local faces = {}
    local halfWidth = self.width / 2
    local halfHeight = self.height / 2
    local halfDepth = self.depth / 2

    faces[1] = Rectangle3D.createWithQuaternion(
        self.center + self.rotation:rotateVector(Vector3.create(0, 0, halfDepth)),
        self.width,
        self.height,
        self.rotation:clone()
    )

    faces[2] = Rectangle3D.createWithQuaternion(
        self.center + self.rotation:rotateVector(Vector3.create(0, 0, -halfDepth)),
        self.width,
        self.height,
        self.rotation * Quaternion.createFromAxisAngle(Vector3.create(0, 1, 0), math.pi)
    )

    faces[3] = Rectangle3D.createWithQuaternion(
        self.center + self.rotation:rotateVector(Vector3.create(0, -halfHeight, 0)),
        self.width,
        self.depth,
        self.rotation * Quaternion.createFromAxisAngle(Vector3.create(1, 0, 0), -math.pi / 2)
    )

    faces[4] = Rectangle3D.createWithQuaternion(
        self.center + self.rotation:rotateVector(Vector3.create(0, halfHeight, 0)),
        self.width,
        self.depth,
        self.rotation * Quaternion.createFromAxisAngle(Vector3.create(1, 0, 0), math.pi / 2)
    )

    faces[5] = Rectangle3D.createWithQuaternion(
        self.center + self.rotation:rotateVector(Vector3.create(-halfWidth, 0, 0)),
        self.depth,
        self.height,
        self.rotation * Quaternion.createFromAxisAngle(Vector3.create(0, 1, 0), -math.pi / 2)
    )

    faces[6] = Rectangle3D.createWithQuaternion(
        self.center + self.rotation:rotateVector(Vector3.create(halfWidth, 0, 0)),
        self.depth,
        self.height,
        self.rotation * Quaternion.createFromAxisAngle(Vector3.create(0, 1, 0), math.pi / 2)
    )

    return faces
end

---将当前立方体平移指定距离
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Cube3D 移动后的立方体（自身引用）
function Cube3D:move(v)
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

---获取立方体平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Cube3D 移动后的立方体副本
function Cube3D:moved(v)
    local result = self:clone()
    return result:move(v)
end

---使用欧拉角旋转立方体
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Cube3D 自身引用
---@overload fun(self: foundation.shape3D.Cube3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Cube3D
function Cube3D:rotate(eulerX, eulerY, eulerZ, center)
    local rotation = Quaternion.createFromEulerAngles(eulerX, eulerY, eulerZ)
    return self:rotateQuaternion(rotation, center)
end

---使用欧拉角旋转立方体的副本
---@param eulerX number X轴旋转角度（弧度）
---@param eulerY number Y轴旋转角度（弧度）
---@param eulerZ number Z轴旋转角度（弧度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Cube3D 旋转后的立方体副本
---@overload fun(self: foundation.shape3D.Cube3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Cube3D
function Cube3D:rotated(eulerX, eulerY, eulerZ, center)
    local result = self:clone()
    return result:rotate(eulerX, eulerY, eulerZ, center)
end

---使用四元数旋转立方体
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Cube3D 自身引用
---@overload fun(self: foundation.shape3D.Cube3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Cube3D
function Cube3D:rotateQuaternion(quaternion, center)
    center = center or self.center
    self.center = quaternion:rotatePoint(self.center - center) + center
    self.rotation = quaternion * self.rotation
    return self
end

---使用四元数旋转立方体的副本
---@param quaternion foundation.math.Quaternion 旋转四元数
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Cube3D 旋转后的立方体副本
---@overload fun(self: foundation.shape3D.Cube3D, quaternion: foundation.math.Quaternion): foundation.shape3D.Cube3D
function Cube3D:rotatedQuaternion(quaternion, center)
    local result = self:clone()
    return result:rotateQuaternion(quaternion, center)
end

---使用角度制的欧拉角旋转立方体
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Cube3D 自身引用
---@overload fun(self: foundation.shape3D.Cube3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Cube3D
function Cube3D:degreeRotate(eulerX, eulerY, eulerZ, center)
    return self:rotate(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---使用角度制的欧拉角旋转立方体的副本
---@param eulerX number X轴旋转角度（度）
---@param eulerY number Y轴旋转角度（度）
---@param eulerZ number Z轴旋转角度（度）
---@param center foundation.math.Vector3 旋转中心点
---@return foundation.shape3D.Cube3D 旋转后的立方体副本
---@overload fun(self: foundation.shape3D.Cube3D, eulerX: number, eulerY: number, eulerZ: number): foundation.shape3D.Cube3D
function Cube3D:degreeRotated(eulerX, eulerY, eulerZ, center)
    return self:rotated(math.rad(eulerX), math.rad(eulerY), math.rad(eulerZ), center)
end

---计算3D立方体的轴对齐包围盒（AABB）
---@return number minX 最小X坐标
---@return number maxX 最大X坐标
---@return number minY 最小Y坐标
---@return number maxY 最大Y坐标
---@return number minZ 最小Z坐标
---@return number maxZ 最大Z坐标
function Cube3D:AABB()
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

---获取立方体的包围盒尺寸
---@return foundation.math.Vector3 包围盒的尺寸
function Cube3D:getBoundingBoxSize()
    return Vector3.create(self.width, self.height, self.depth)
end

---计算点到立方体表面的最短距离
---@param point foundation.math.Vector3 要计算距离的点
---@return number 点到立方体表面的最短距离，如果点在立方体内部则返回负值
function Cube3D:distanceToPoint(point)
    local vertices = self:getVertices()
    local minDistance = math.huge
    local isInside = true

    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    if point.x < minX or point.x > maxX or
        point.y < minY or point.y > maxY or
        point.z < minZ or point.z > maxZ then
        isInside = false
    end

    local faces = self:getFaces()
    for _, face in ipairs(faces) do
        local distance = face:distanceToPoint(point)
        minDistance = math.min(minDistance, math.abs(distance))
    end

    return isInside and -minDistance or minDistance
end

---将点投影到立方体表面上
---@param point foundation.math.Vector3 要投影的点
---@return foundation.math.Vector3 投影点
function Cube3D:projectPoint(point)
    local faces = self:getFaces()
    local minDistance = math.huge
    local projectedPoint

    for _, face in ipairs(faces) do
        local proj = face:projectPoint(point)
        local distance = (proj - point):length()
        if distance < minDistance then
            minDistance = distance
            projectedPoint = proj
        end
    end

    return projectedPoint
end

---检查点是否在立方体内部或表面上
---@param point foundation.math.Vector3 要检查的点
---@return boolean 如果点在立方体内部或表面上则返回true，否则返回false
function Cube3D:contains(point)
    local localPoint = self.rotation:inverse():rotatePoint(point - self.center)

    local halfWidth = self.width / 2
    local halfHeight = self.height / 2
    local halfDepth = self.depth / 2

    return math.abs(localPoint.x) <= halfWidth and
        math.abs(localPoint.y) <= halfHeight and
        math.abs(localPoint.z) <= halfDepth
end

---@param point foundation.math.Vector3 要检查的点
---@param tolerance number 容差值
---@return boolean 如果点在立方体表面上则返回true，否则返回false
function Cube3D:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-6

    local localPoint = self.rotation:inverse():rotatePoint(point - self.center)

    local halfWidth = self.width / 2
    local halfHeight = self.height / 2
    local halfDepth = self.depth / 2

    local onXFace = math.abs(math.abs(localPoint.x) - halfWidth) <= tolerance
    local onYFace = math.abs(math.abs(localPoint.y) - halfHeight) <= tolerance
    local onZFace = math.abs(math.abs(localPoint.z) - halfDepth) <= tolerance

    return (onXFace and math.abs(localPoint.y) <= halfHeight + tolerance and math.abs(localPoint.z) <= halfDepth + tolerance) or
        (onYFace and math.abs(localPoint.x) <= halfWidth + tolerance and math.abs(localPoint.z) <= halfDepth + tolerance) or
        (onZFace and math.abs(localPoint.x) <= halfWidth + tolerance and math.abs(localPoint.y) <= halfHeight + tolerance)
end

---将当前立方体缩放指定比例（更改当前立方体）
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Cube3D 缩放后的立方体（自身引用）
---@overload fun(self: foundation.shape3D.Cube3D, scale: foundation.math.Vector3|number): foundation.shape3D.Cube3D
function Cube3D:scale(scale, center)
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
    self.depth = self.depth * scaleVec.z
    return self
end

---获取立方体缩放指定比例的副本
---@param scale foundation.math.Vector3|number 缩放比例
---@param center foundation.math.Vector3 缩放中心点
---@return foundation.shape3D.Cube3D 缩放后的立方体副本
---@overload fun(self: foundation.shape3D.Cube3D, scale: foundation.math.Vector3|number): foundation.shape3D.Cube3D
function Cube3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

ffi.metatype("foundation_shape3D_Cube3D", Cube3D)

return Cube3D

local ffi = require("ffi")

local type = type
local ipairs = ipairs
local tostring = tostring
local string = string
local math = math
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Segment3D = require("foundation.shape3D.Segment3D")
local Shape3DIntersector = require("foundation.shape3D.Shape3DIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 center;
    double width;
    double height;
    foundation_math_Vector3 direction;
    foundation_math_Vector3 up;
} foundation_shape3D_Rectangle3D;
]]

---@class foundation.shape3D.Rectangle3D
---@field center foundation.math.Vector3 矩形的中心点
---@field width number 矩形的宽度
---@field height number 矩形的高度
---@field direction foundation.math.Vector3 矩形的宽度轴方向（归一化向量）
---@field up foundation.math.Vector3 矩形的上方向（归一化向量，与direction垂直）
local Rectangle3D = {}
Rectangle3D.__type = "foundation.shape3D.Rectangle3D"

---@param self foundation.shape3D.Rectangle3D
---@param key any
---@return any
function Rectangle3D.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "width" then
        return self.__data.width
    elseif key == "height" then
        return self.__data.height
    elseif key == "direction" then
        return self.__data.direction
    elseif key == "up" then
        return self.__data.up
    end
    return Rectangle3D[key]
end

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
    elseif key == "direction" then
        self.__data.direction = value
    elseif key == "up" then
        self.__data.up = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的3D矩形
---@param center foundation.math.Vector3 中心点
---@param width number 宽度
---@param height number 高度
---@param direction foundation.math.Vector3|nil 宽度轴方向（归一化向量），默认为(1,0,0)
---@param up foundation.math.Vector3|nil 上方向（归一化向量，与direction垂直），默认为(0,1,0)
---@return foundation.shape3D.Rectangle3D
function Rectangle3D.create(center, width, height, direction, up)
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

    if not up then
        up = Vector3.create(0, 1, 0)
    end
    local up_dist = up:length()
    if up_dist <= 1e-10 then
        up = Vector3.create(0, 1, 0)
    elseif up_dist ~= 1 then
        up = up:normalized()
    else
        up = up:clone()
    end

    local dot = direction:dot(up)
    if math.abs(dot) > 1e-10 then
        up = (up - direction * dot):normalized()
    end

    local rectangle = ffi.new("foundation_shape3D_Rectangle3D", center, width, height, direction, up)
    local result = {
        __data = rectangle
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Rectangle3D)
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

---3D矩形相等比较
---@param a foundation.shape3D.Rectangle3D
---@param b foundation.shape3D.Rectangle3D
---@return boolean
function Rectangle3D.__eq(a, b)
    return a.center == b.center and
            math.abs(a.width - b.width) <= 1e-10 and
            math.abs(a.height - b.height) <= 1e-10 and
            a.direction == b.direction and
            a.up == b.up
end

---3D矩形的字符串表示
---@param self foundation.shape3D.Rectangle3D
---@return string
function Rectangle3D.__tostring(self)
    return string.format("Rectangle3D(center=%s, width=%f, height=%f, direction=%s, up=%s)",
            tostring(self.center), self.width, self.height, tostring(self.direction), tostring(self.up))
end

---获取3D矩形的四个顶点
---@return foundation.math.Vector3[]
function Rectangle3D:getVertices()
    local hw, hh = self.width / 2, self.height / 2
    local dir = self.direction
    local up = self.up
    local right = dir:cross(up)
    local vertices = {
        self.center - dir * hw - up * hh,
        self.center + dir * hw - up * hh,
        self.center + dir * hw + up * hh,
        self.center - dir * hw + up * hh
    }
    return vertices
end

---获取3D矩形的四条边（线段）
---@return foundation.shape3D.Segment3D[]
function Rectangle3D:getEdges()
    local vertices = self:getVertices()
    return {
        Segment3D.create(vertices[1], vertices[2]),
        Segment3D.create(vertices[2], vertices[3]),
        Segment3D.create(vertices[3], vertices[4]),
        Segment3D.create(vertices[4], vertices[1])
    }
end

---平移3D矩形（更改当前矩形）
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Rectangle3D 自身引用
function Rectangle3D:move(v)
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

---获取平移后的3D矩形副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Rectangle3D
function Rectangle3D:moved(v)
    local moveX, moveY, moveZ
    if type(v) == "number" then
        moveX, moveY, moveZ = v, v, v
    else
        moveX, moveY, moveZ = v.x, v.y, v.z
    end
    return Rectangle3D.create(
            Vector3.create(self.center.x + moveX, self.center.y + moveY, self.center.z + moveZ),
            self.width, self.height, self.direction, self.up
    )
end

---旋转3D矩形（更改当前矩形）
---@param axis foundation.math.Vector3 旋转轴
---@param rad number 旋转弧度
---@param center foundation.math.Vector3|nil 旋转中心点，默认为矩形中心
---@return foundation.shape3D.Rectangle3D 自身引用
function Rectangle3D:rotate(axis, rad, center)
    center = center or self.center
    local rotated_dir = self.direction:rotated(axis, rad)
    local rotated_up = self.up:rotated(axis, rad)
    self.direction = rotated_dir
    self.up = rotated_up

    local dx = self.center.x - center.x
    local dy = self.center.y - center.y
    local dz = self.center.z - center.z
    local rotated_center = Vector3.create(dx, dy, dz):rotated(axis, rad)
    self.center.x = center.x + rotated_center.x
    self.center.y = center.y + rotated_center.y
    self.center.z = center.z + rotated_center.z
    return self
end

---旋转3D矩形（更改当前矩形）
---@param axis foundation.math.Vector3 旋转轴
---@param angle number 旋转角度
---@param center foundation.math.Vector3|nil 旋转中心点，默认为矩形中心
---@return foundation.shape3D.Rectangle3D 自身引用
function Rectangle3D:degreeRotate(axis, angle, center)
    return self:rotate(axis, math.rad(angle), center)
end

---获取旋转后的3D矩形副本
---@param axis foundation.math.Vector3 旋转轴
---@param rad number 旋转弧度
---@param center foundation.math.Vector3|nil 旋转中心点，默认为矩形中心
---@return foundation.shape3D.Rectangle3D
function Rectangle3D:rotated(axis, rad, center)
    local result = Rectangle3D.create(self.center:clone(), self.width, self.height, self.direction:clone(),
            self.up:clone())
    return result:rotate(axis, rad, center)
end

---获取旋转后的3D矩形副本
---@param axis foundation.math.Vector3 旋转轴
---@param angle number 旋转角度
---@param center foundation.math.Vector3|nil 旋转中心点，默认为矩形中心
---@return foundation.shape3D.Rectangle3D
function Rectangle3D:degreeRotated(axis, angle, center)
    return self:rotated(axis, math.rad(angle), center)
end

---缩放3D矩形（更改当前矩形）
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3|nil 缩放中心点，默认为矩形中心
---@return foundation.shape3D.Rectangle3D 自身引用
function Rectangle3D:scale(scale, center)
    local scaleX, scaleY, scaleZ
    if type(scale) == "number" then
        scaleX, scaleY, scaleZ = scale, scale, scale
    else
        scaleX, scaleY, scaleZ = scale.x, scale.y, scale.z
    end
    center = center or self.center

    self.width = self.width * scaleX
    self.height = self.height * scaleY
    local dx = self.center.x - center.x
    local dy = self.center.y - center.y
    local dz = self.center.z - center.z
    self.center.x = center.x + dx * scaleX
    self.center.y = center.y + dy * scaleY
    self.center.z = center.z + dz * scaleZ
    return self
end

---获取缩放后的3D矩形副本
---@param scale number|foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3|nil 缩放中心点，默认为矩形中心
---@return foundation.shape3D.Rectangle3D
function Rectangle3D:scaled(scale, center)
    local result = Rectangle3D.create(self.center:clone(), self.width, self.height, self.direction:clone(),
            self.up:clone())
    return result:scale(scale, center)
end

---检查点是否在3D矩形内（包括边界）
---@param point foundation.math.Vector3
---@return boolean
function Rectangle3D:contains(point)
    return Shape3DIntersector.rectangle3DContainsPoint(self, point)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector3[] | nil
function Rectangle3D:intersects(other)
    return Shape3DIntersector.intersect(self, other)
end

---仅检查是否与其他形状相交
---@param other any
---@return boolean
function Rectangle3D:hasIntersection(other)
    return Shape3DIntersector.hasIntersection(self, other)
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

---获取3D矩形的AABB包围盒
---@return number, number, number, number, number, number
function Rectangle3D:AABB()
    local vertices = self:getVertices()
    local minX, maxX = vertices[1].x, vertices[1].x
    local minY, maxY = vertices[1].y, vertices[1].y
    local minZ, maxZ = vertices[1].z, vertices[1].z
    for i = 2, 4 do
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

---计算3D矩形的包围盒宽高深
---@return number, number, number
function Rectangle3D:getBoundingBoxSize()
    local minX, maxX, minY, maxY, minZ, maxZ = self:AABB()
    return maxX - minX, maxY - minY, maxZ - minZ
end

---计算3D矩形的法向量
---@return foundation.math.Vector3 矩形的法向量
function Rectangle3D:normal()
    return self.direction:cross(self.up):normalized()
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

---复制3D矩形
---@return foundation.shape3D.Rectangle3D
function Rectangle3D:clone()
    return Rectangle3D.create(self.center:clone(), self.width, self.height, self.direction:clone(), self.up:clone())
end

ffi.metatype("foundation_shape3D_Rectangle3D", Rectangle3D)

return Rectangle3D

local ffi = require("ffi")

local type = type
local tostring = tostring
local string = string
local math = math
local table = table
local error = error
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Segment3D = require("foundation.shape3D.Segment3D")

ffi.cdef [[
typedef struct {
    int order;
    int num_points;
    foundation_math_Vector3* control_points;
} foundation_shape3D_BezierCurve3D;
]]

---@class foundation.shape3D.BezierCurve3D
---@field order number 贝塞尔曲线的阶数 (2=二次曲线，3=三次曲线)
---@field num_points number 控制点的数量
---@field control_points foundation.math.Vector3[] 控制点数组
local BezierCurve3D = {}
BezierCurve3D.__type = "foundation.shape3D.BezierCurve3D"

---@param t foundation.math.Vector3[]
---@return number, foundation.math.Vector3[]
local function buildNewVector3Array(t)
    local size = #t
    local points_array = ffi.new("foundation_math_Vector3[?]", size)
    for i = 1, size do
        points_array[i - 1] = Vector3.create(t[i].x, t[i].y, t[i].z)
    end
    return size, points_array
end

---@param self foundation.shape3D.BezierCurve3D
---@param key any
---@return any
function BezierCurve3D.__index(self, key)
    if key == "order" then
        return self.__data.order
    elseif key == "num_points" then
        return self.__data.num_points
    elseif key == "control_points" then
        return self.__data.control_points
    end
    return BezierCurve3D[key]
end

---@param self foundation.shape3D.BezierCurve3D
---@param key any
---@param value any
function BezierCurve3D.__newindex(self, key, value)
    if key == "order" then
        self.__data.order = value
    elseif key == "num_points" then
        error("cannot modify num_points directly")
    elseif key == "control_points" then
        local size, points_array = buildNewVector3Array(value)
        self.__data.num_points = size
        self.__data.control_points = points_array
        self.__data_points_ref = points_array
    else
        rawset(self, key, value)
    end
end

---创建一个3D贝塞尔曲线
---@param control_points foundation.math.Vector3[] 控制点数组
---@return foundation.shape3D.BezierCurve3D
function BezierCurve3D.create(control_points)
    if not control_points or #control_points < 2 then
        error("BezierCurve3D requires at least 2 control points")
    end
    local size, points_array = buildNewVector3Array(control_points)
    local order = size - 1
    local curve = ffi.new("foundation_shape3D_BezierCurve3D", order, size, points_array)
    local result = {
        __data = curve,
        __data_points_ref = points_array,
    }
    return setmetatable(result, BezierCurve3D)
end

---创建一个二次3D贝塞尔曲线
---@param p0 foundation.math.Vector3 起始点
---@param p1 foundation.math.Vector3 控制点
---@param p2 foundation.math.Vector3 结束点
---@return foundation.shape3D.BezierCurve3D
function BezierCurve3D.createQuadratic(p0, p1, p2)
    return BezierCurve3D.create({ p0, p1, p2 })
end

---创建一个三次3D贝塞尔曲线
---@param p0 foundation.math.Vector3 起始点
---@param p1 foundation.math.Vector3 控制点1
---@param p2 foundation.math.Vector3 控制点2
---@param p3 foundation.math.Vector3 结束点
---@return foundation.shape3D.BezierCurve3D
function BezierCurve3D.createCubic(p0, p1, p2, p3)
    return BezierCurve3D.create({ p0, p1, p2, p3 })
end

---3D贝塞尔曲线相等比较
---@param a foundation.shape3D.BezierCurve3D
---@param b foundation.shape3D.BezierCurve3D
---@return boolean
function BezierCurve3D.__eq(a, b)
    if a.order ~= b.order or a.num_points ~= b.num_points then
        return false
    end
    for i = 0, a.num_points - 1 do
        if a.control_points[i] ~= b.control_points[i] then
            return false
        end
    end
    return true
end

---3D贝塞尔曲线转字符串表示
---@param self foundation.shape3D.BezierCurve3D
---@return string
function BezierCurve3D.__tostring(self)
    local pointsStr = {}
    for i = 0, self.num_points - 1 do
        pointsStr[i + 1] = tostring(self.control_points[i])
    end
    return string.format("BezierCurve3D(%s)", table.concat(pointsStr, ", "))
end

---获取3D贝塞尔曲线上参数为t的点（t范围0到1）
---@param t number 参数值(0-1)
---@return foundation.math.Vector3
function BezierCurve3D:getPoint(t)
    if t <= 0 then
        return self.control_points[0]:clone()
    elseif t >= 1 then
        return self.control_points[self.num_points - 1]:clone()
    end
    local points = {}
    for i = 0, self.num_points - 1 do
        points[i + 1] = self.control_points[i]:clone()
    end
    for r = 1, self.order do
        for i = 1, self.num_points - r do
            points[i] = points[i] * (1 - t) + points[i + 1] * t
        end
    end
    return points[1]
end

---获取3D贝塞尔曲线的起点
---@return foundation.math.Vector3
function BezierCurve3D:getStartPoint()
    return self.control_points[0]:clone()
end

---获取3D贝塞尔曲线的终点
---@return foundation.math.Vector3
function BezierCurve3D:getEndPoint()
    return self.control_points[self.num_points - 1]:clone()
end

---将3D贝塞尔曲线离散化为一系列点
---@param segments number 分段数
---@return foundation.math.Vector3[]
function BezierCurve3D:discretize(segments)
    segments = segments or 10
    local points = {}
    for i = 0, segments do
        local t = i / segments
        points[i + 1] = self:getPoint(t)
    end
    return points
end

---转换为一系列线段的近似表示
---@param segments number 分段数
---@return foundation.shape3D.Segment3D[]
function BezierCurve3D:toSegments(segments)
    segments = segments or 10
    local points = self:discretize(segments)
    local segs = {}
    for i = 1, #points - 1 do
        segs[i] = Segment3D.create(points[i], points[i + 1])
    end
    return segs
end

---获取3D贝塞尔曲线的近似长度
---@param segments number 分段数，用于近似计算
---@return number
function BezierCurve3D:length(segments)
    segments = segments or 20
    local points = self:discretize(segments)
    local length = 0
    for i = 2, #points do
        length = length + (points[i] - points[i - 1]):length()
    end
    return length
end

---计算3D贝塞尔曲线的中心
---@return foundation.math.Vector3
function BezierCurve3D:getCenter()
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        minX = math.min(minX, p.x)
        minY = math.min(minY, p.y)
        minZ = math.min(minZ, p.z)
        maxX = math.max(maxX, p.x)
        maxY = math.max(maxY, p.y)
        maxZ = math.max(maxZ, p.z)
    end
    return Vector3.create((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
end

---获取3D贝塞尔曲线的AABB包围盒
---@return number, number, number, number, number, number
function BezierCurve3D:AABB()
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        minX = math.min(minX, p.x)
        minY = math.min(minY, p.y)
        minZ = math.min(minZ, p.z)
        maxX = math.max(maxX, p.x)
        maxY = math.max(maxY, p.y)
        maxZ = math.max(maxZ, p.z)
    end
    return minX, maxX, minY, maxY, minZ, maxZ
end

---将当前3D贝塞尔曲线平移指定距离
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.BezierCurve3D 自身引用
function BezierCurve3D:move(v)
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
    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        new_points[i + 1] = Vector3.create(p.x + moveX, p.y + moveY, p.z + moveZ)
    end
    self.control_points = new_points
    return self
end

---获取平移后的3D贝塞尔曲线副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.BezierCurve3D
function BezierCurve3D:moved(v)
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
    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        new_points[i + 1] = Vector3.create(p.x + moveX, p.y + moveY, p.z + moveZ)
    end
    return BezierCurve3D.create(new_points)
end

---将当前3D贝塞尔曲线旋转指定弧度（更改当前曲线）
---@param rad number 旋转弧度
---@param axis foundation.math.Vector3 旋转轴
---@param center foundation.math.Vector3 旋转中心，默认为曲线的中心
---@return foundation.shape3D.BezierCurve3D 自身引用
---@overload fun(self: foundation.shape3D.BezierCurve3D, rad: number, axis: foundation.math.Vector3): foundation.shape3D.BezierCurve3D
function BezierCurve3D:rotate(rad, axis, center)
    center = center or self:getCenter()
    local q = require("foundation.math.Quaternion").createFromAxisAngle(axis, rad)
    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        new_points[i + 1] = q:rotatePoint(p - center) + center
    end
    self.control_points = new_points
    return self
end

---获取旋转后的3D贝塞尔曲线副本
---@param rad number 旋转弧度
---@param axis foundation.math.Vector3 旋转轴
---@param center foundation.math.Vector3 旋转中心，默认为曲线的中心
---@return foundation.shape3D.BezierCurve3D
---@overload fun(self: foundation.shape3D.BezierCurve3D, rad: number, axis: foundation.math.Vector3): foundation.shape3D.BezierCurve3D
function BezierCurve3D:rotated(rad, axis, center)
    local result = self:clone()
    return result:rotate(rad, axis, center)
end

---将当前3D贝塞尔曲线缩放指定倍数（更改当前曲线）
---@param scale number | foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心，默认为曲线的中心
---@return foundation.shape3D.BezierCurve3D 自身引用
---@overload fun(self: foundation.shape3D.BezierCurve3D, scale: number | foundation.math.Vector3): foundation.shape3D.BezierCurve3D
function BezierCurve3D:scale(scale, center)
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
    center = center or self:getCenter()
    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        local x = (p.x - center.x) * scaleX + center.x
        local y = (p.y - center.y) * scaleY + center.y
        local z = (p.z - center.z) * scaleZ + center.z
        new_points[i + 1] = Vector3.create(x, y, z)
    end
    self.control_points = new_points
    return self
end

---获取缩放后的3D贝塞尔曲线副本
---@param scale number | foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心，默认为曲线的中心
---@return foundation.shape3D.BezierCurve3D
---@overload fun(self: foundation.shape3D.BezierCurve3D, scale: number | foundation.math.Vector3): foundation.shape3D.BezierCurve3D
function BezierCurve3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---克隆3D贝塞尔曲线
---@return foundation.shape3D.BezierCurve3D
function BezierCurve3D:clone()
    local new_points = {}
    for i = 0, self.num_points - 1 do
        new_points[i + 1] = self.control_points[i]:clone()
    end
    return BezierCurve3D.create(new_points)
end

ffi.metatype("foundation_shape3D_BezierCurve3D", BezierCurve3D)

return BezierCurve3D

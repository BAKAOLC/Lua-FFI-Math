local ffi = require("ffi")

local type = type
local math = math
local error = error
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")

ffi.cdef [[
typedef struct {
    int u_count;
    int v_count;
    foundation_math_Vector3* control_points; // 行主序
} foundation_shape3D_BezierSurface3D;
]]

---@class foundation.shape3D.BezierSurface3D
---@field u_count number U方向控制点数
---@field v_count number V方向控制点数
---@field control_points foundation.math.Vector3[][] 控制点二维数组
local BezierSurface3D = {}
BezierSurface3D.__type = "foundation.shape3D.BezierSurface3D"

---@param t foundation.math.Vector3[][]
---@return number, number, foundation.math.Vector3[]
local function buildNewVector3Array2D(t)
    local u_count = #t
    local v_count = #t[1]
    local arr = {}
    for i = 1, u_count do
        for j = 1, v_count do
            arr[#arr + 1] = Vector3.create(t[i][j].x, t[i][j].y, t[i][j].z)
        end
    end
    local points_array = ffi.new("foundation_math_Vector3[?]", #arr)
    for i = 1, #arr do
        points_array[i - 1] = arr[i]
    end
    return u_count, v_count, points_array
end

---@param self foundation.shape3D.BezierSurface3D
---@param key any
---@return any
function BezierSurface3D.__index(self, key)
    if key == "u_count" then
        return self.__data.u_count
    elseif key == "v_count" then
        return self.__data.v_count
    elseif key == "control_points" then
        return self.__data.control_points
    end
    return BezierSurface3D[key]
end

---@param self foundation.shape3D.BezierSurface3D
---@param key any
---@param value any
function BezierSurface3D.__newindex(self, key, value)
    if key == "control_points" then
        local u_count, v_count, points_array = buildNewVector3Array2D(value)
        self.__data.u_count = u_count
        self.__data.v_count = v_count
        self.__data.control_points = points_array
        self.__data_points_ref = points_array
    elseif key == "u_count" or key == "v_count" then
        error("cannot modify " .. key .. " directly")
    else
        rawset(self, key, value)
    end
end

---创建一个3D贝塞尔曲面
---@param control_points foundation.math.Vector3[][] 控制点二维数组
---@return foundation.shape3D.BezierSurface3D
function BezierSurface3D.create(control_points)
    if not control_points or #control_points < 2 or #control_points[1] < 2 then
        error("BezierSurface3D requires at least 2x2 control points")
    end
    local u_count, v_count, points_array = buildNewVector3Array2D(control_points)
    local surface = ffi.new("foundation_shape3D_BezierSurface3D", u_count, v_count, points_array)
    local result = {
        __data = surface,
        __data_points_ref = points_array,
    }
    return setmetatable(result, BezierSurface3D)
end

---获取控制点（二维数组）
---@return foundation.math.Vector3[][]
function BezierSurface3D:getControlPoints()
    return self._lua_points
end

---@param n number
---@param k number
---@return number
local function binomial(n, k)
    local res = 1
    for j = 1, k do
        res = res * (n - j + 1) / j
    end
    return res
end

---@param i number
---@param n number
---@param t number
---@return number
local function bernstein(i, n, t)
    return binomial(n, i) * t ^ i * (1 - t) ^ (n - i)
end

---获取曲面上的点
---@param u number [0,1]
---@param v number [0,1]
---@return foundation.math.Vector3
function BezierSurface3D:getPoint(u, v)
    local n = self.u_count - 1
    local m = self.v_count - 1
    local cp = self:getControlPoints()
    local p = Vector3.create(0, 0, 0)
    for i = 0, n do
        for j = 0, m do
            local b = bernstein(i, n, u) * bernstein(j, m, v)
            p = p + cp[i + 1][j + 1] * b
        end
    end
    return p
end

---离散化为点阵
---@param u_segments number U方向分段数
---@param v_segments number V方向分段数
---@return foundation.math.Vector3[][]
function BezierSurface3D:discretize(u_segments, v_segments)
    u_segments = u_segments or 10
    v_segments = v_segments or 10
    local grid = {}
    for i = 0, u_segments do
        local u = i / u_segments
        grid[i + 1] = {}
        for j = 0, v_segments do
            local v = j / v_segments
            grid[i + 1][j + 1] = self:getPoint(u, v)
        end
    end
    return grid
end

---将当前曲面平移指定距离
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.BezierSurface3D 自身引用
function BezierSurface3D:move(v)
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
    local cp = self:getControlPoints()
    local new_cp = {}
    for i = 1, #cp do
        new_cp[i] = {}
        for j = 1, #cp[i] do
            local p = cp[i][j]
            new_cp[i][j] = Vector3.create(p.x + moveX, p.y + moveY, p.z + moveZ)
        end
    end
    self.control_points = new_cp
    return self
end

---获取平移后的曲面副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.BezierSurface3D
function BezierSurface3D:moved(v)
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
    local cp = self:getControlPoints()
    local new_cp = {}
    for i = 1, #cp do
        new_cp[i] = {}
        for j = 1, #cp[i] do
            local p = cp[i][j]
            new_cp[i][j] = Vector3.create(p.x + moveX, p.y + moveY, p.z + moveZ)
        end
    end
    return BezierSurface3D.create(new_cp)
end

---将当前曲面缩放指定倍数
---@param scale number | foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心，默认为曲面中心
---@return foundation.shape3D.BezierSurface3D 自身引用
---@overload fun(self: foundation.shape3D.BezierSurface3D, scale: number | foundation.math.Vector3): foundation.shape3D.BezierSurface3D
function BezierSurface3D:scale(scale, center)
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
    local cp = self:getControlPoints()
    local new_cp = {}
    for i = 1, #cp do
        new_cp[i] = {}
        for j = 1, #cp[i] do
            local p = cp[i][j]
            local x = (p.x - center.x) * scaleX + center.x
            local y = (p.y - center.y) * scaleY + center.y
            local z = (p.z - center.z) * scaleZ + center.z
            new_cp[i][j] = Vector3.create(x, y, z)
        end
    end
    self.control_points = new_cp
    return self
end

---获取缩放后的曲面副本
---@param scale number | foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心，默认为曲面中心
---@return foundation.shape3D.BezierSurface3D
---@overload fun(self: foundation.shape3D.BezierSurface3D, scale: number | foundation.math.Vector3): foundation.shape3D.BezierSurface3D
function BezierSurface3D:scaled(scale, center)
    local cp = self:getControlPoints()
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
    local new_cp = {}
    for i = 1, #cp do
        new_cp[i] = {}
        for j = 1, #cp[i] do
            local p = cp[i][j]
            local x = (p.x - center.x) * scaleX + center.x
            local y = (p.y - center.y) * scaleY + center.y
            local z = (p.z - center.z) * scaleZ + center.z
            new_cp[i][j] = Vector3.create(x, y, z)
        end
    end
    return BezierSurface3D.create(new_cp)
end

---将当前曲面绕轴旋转指定弧度
---@param rad number 旋转弧度
---@param axis foundation.math.Vector3 旋转轴
---@param center foundation.math.Vector3 旋转中心，默认为曲面中心
---@return foundation.shape3D.BezierSurface3D 自身引用
---@overload fun(self: foundation.shape3D.BezierSurface3D, rad: number, axis: foundation.math.Vector3): foundation.shape3D.BezierSurface3D
function BezierSurface3D:rotate(rad, axis, center)
    center = center or self:getCenter()
    local q = require("foundation.math.Quaternion").createFromAxisAngle(axis, rad)
    local cp = self:getControlPoints()
    local new_cp = {}
    for i = 1, #cp do
        new_cp[i] = {}
        for j = 1, #cp[i] do
            local p = cp[i][j]
            new_cp[i][j] = q:rotatePoint(p - center) + center
        end
    end
    self.control_points = new_cp
    return self
end

---获取旋转后的曲面副本
---@param rad number 旋转弧度
---@param axis foundation.math.Vector3 旋转轴
---@param center foundation.math.Vector3 旋转中心，默认为曲面中心
---@return foundation.shape3D.BezierSurface3D
---@overload fun(self: foundation.shape3D.BezierSurface3D, rad: number, axis: foundation.math.Vector3): foundation.shape3D.BezierSurface3D
function BezierSurface3D:rotated(rad, axis, center)
    local result = self:clone()
    return result:rotate(rad, axis, center)
end

---计算曲面中心
---@return foundation.math.Vector3
function BezierSurface3D:getCenter()
    local cp = self:getControlPoints()
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for i = 1, #cp do
        for j = 1, #cp[i] do
            local p = cp[i][j]
            minX = math.min(minX, p.x)
            minY = math.min(minY, p.y)
            minZ = math.min(minZ, p.z)
            maxX = math.max(maxX, p.x)
            maxY = math.max(maxY, p.y)
            maxZ = math.max(maxZ, p.z)
        end
    end
    return Vector3.create((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
end

---克隆3D贝塞尔曲面
---@return foundation.shape3D.BezierSurface3D
function BezierSurface3D:clone()
    local cp = self:getControlPoints()
    local new_cp = {}
    for i = 1, #cp do
        new_cp[i] = {}
        for j = 1, #cp[i] do
            new_cp[i][j] = cp[i][j]:clone()
        end
    end
    return BezierSurface3D.create(new_cp)
end

ffi.metatype("foundation_shape3D_BezierSurface3D", BezierSurface3D)

return BezierSurface3D

local ffi = require("ffi")

local type = type
local tostring = tostring
local string = string
local math = math
local error = error
local rawset = rawset
local setmetatable = setmetatable

local Vector3 = require("foundation.math.Vector3")
local Quaternion = require("foundation.math.Quaternion")

ffi.cdef [[
typedef struct {
    foundation_math_Vector3 center;
    double radius;
    double height;
    foundation_math_Quaternion rotation;
} foundation_shape3D_Cone3D;
]]

---@class foundation.shape3D.Cone3D
---@field center foundation.math.Vector3 圆锥的中心点
---@field radius number 圆锥的半径
---@field height number 圆锥的高度
---@field rotation foundation.math.Quaternion 圆锥的旋转四元数
local Cone3D = {}
Cone3D.__type = "foundation.shape3D.Cone3D"

---@param self foundation.shape3D.Cone3D
---@param key any
---@return any
function Cone3D.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "radius" then
        return self.__data.radius
    elseif key == "height" then
        return self.__data.height
    elseif key == "rotation" then
        return self.__data.rotation
    end
    return Cone3D[key]
end

---@param self foundation.shape3D.Cone3D
---@param key any
---@param value any
function Cone3D.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "radius" then
        self.__data.radius = value
    elseif key == "height" then
        self.__data.height = value
    elseif key == "rotation" then
        self.__data.rotation = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的圆锥
---@param center foundation.math.Vector3 圆锥的中心点
---@param radius number 圆锥的半径
---@param height number 圆锥的高度
---@param rotation foundation.math.Quaternion 圆锥的旋转四元数
---@return foundation.shape3D.Cone3D 新创建的圆锥
---@overload fun(center: foundation.math.Vector3, radius: number, height: number): foundation.shape3D.Cone3D
function Cone3D.create(center, radius, height, rotation)
    if not center then
        error("Center point cannot be nil")
    end
    radius = radius or 1
    height = height or 1
    rotation = rotation or Quaternion.identity()
    local cone = ffi.new("foundation_shape3D_Cone3D", center, radius, height, rotation)
    local result = {
        __data = cone,
    }
    return setmetatable(result, Cone3D)
end

---比较两个圆锥是否相等
---@param a foundation.shape3D.Cone3D 第一个圆锥
---@param b foundation.shape3D.Cone3D 第二个圆锥
---@return boolean 如果两个圆锥的所有属性都相等则返回true，否则返回false
function Cone3D.__eq(a, b)
    return a.center == b.center and a.radius == b.radius and a.height == b.height and a.rotation == b.rotation
end

---将圆锥转换为字符串表示
---@param t foundation.shape3D.Cone3D 要转换的圆锥
---@return string 圆锥的字符串表示
function Cone3D.__tostring(t)
    return string.format("Cone3D(%s, %f, %f, %s)", tostring(t.center), t.radius, t.height, tostring(t.rotation))
end

---获取圆锥的中心点
---@return foundation.math.Vector3 圆锥的中心点
function Cone3D:getCenter()
    return self.center
end

---获取圆锥的半径
---@return number 圆锥的半径
function Cone3D:getRadius()
    return self.radius
end

---获取圆锥的高度
---@return number 圆锥的高度
function Cone3D:getHeight()
    return self.height
end

---获取圆锥的旋转四元数
---@return foundation.math.Quaternion 圆锥的旋转四元数
function Cone3D:getRotation()
    return self.rotation
end

---将当前圆锥平移指定距离
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Cone3D 自身引用
function Cone3D:move(v)
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

---获取圆锥平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Cone3D 移动后的圆锥副本
function Cone3D:moved(v)
    return self:clone():move(v)
end

---将当前圆锥缩放指定倍数
---@param scale number | foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心，默认为圆锥中心
---@return foundation.shape3D.Cone3D 自身引用
---@overload fun(self: foundation.shape3D.Cone3D, scale: number | foundation.math.Vector3): foundation.shape3D.Cone3D
function Cone3D:scale(scale, center)
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
    local scaleVec = Vector3.create(scaleX, scaleY, scaleZ)
    self.center = center + (self.center - center) * scaleVec
    self.radius = self.radius * math.sqrt(scaleVec.x * scaleVec.x + scaleVec.y * scaleVec.y) / math.sqrt(2)
    self.height = self.height * scaleVec.z
    return self
end

---获取圆锥缩放指定倍数的副本
---@param scale number | foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心，默认为圆锥中心
---@return foundation.shape3D.Cone3D 缩放后的圆锥副本
---@overload fun(self: foundation.shape3D.Cone3D, scale: number | foundation.math.Vector3): foundation.shape3D.Cone3D
function Cone3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---将当前圆锥绕轴旋转指定弧度
---@param rad number 旋转弧度
---@param axis foundation.math.Vector3 旋转轴
---@param center foundation.math.Vector3 旋转中心，默认为圆锥中心
---@return foundation.shape3D.Cone3D 自身引用
---@overload fun(self: foundation.shape3D.Cone3D, rad: number, axis: foundation.math.Vector3): foundation.shape3D.Cone3D
function Cone3D:rotate(rad, axis, center)
    center = center or self:getCenter()
    local q = Quaternion.createFromAxisAngle(axis, rad)
    self.center = q:rotatePoint(self.center - center) + center
    self.rotation = q * self.rotation
    return self
end

---获取圆锥绕轴旋转指定弧度的副本
---@param rad number 旋转弧度
---@param axis foundation.math.Vector3 旋转轴
---@param center foundation.math.Vector3 旋转中心，默认为圆锥中心
---@return foundation.shape3D.Cone3D 旋转后的圆锥副本
---@overload fun(self: foundation.shape3D.Cone3D, rad: number, axis: foundation.math.Vector3): foundation.shape3D.Cone3D
function Cone3D:rotated(rad, axis, center)
    local result = self:clone()
    return result:rotate(rad, axis, center)
end

---克隆圆锥
---@return foundation.shape3D.Cone3D 圆锥的副本
function Cone3D:clone()
    return Cone3D.create(self.center:clone(), self.radius, self.height, self.rotation:clone())
end

ffi.metatype("foundation_shape3D_Cone3D", Cone3D)

return Cone3D

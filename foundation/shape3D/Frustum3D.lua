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
    double bottomRadius;
    double topRadius;
    double height;
    foundation_math_Quaternion rotation;
} foundation_shape3D_Frustum3D;
]]

---@class foundation.shape3D.Frustum3D
---@field center foundation.math.Vector3 圆台的中心点
---@field bottomRadius number 圆台底部半径
---@field topRadius number 圆台顶部半径
---@field height number 圆台的高度
---@field rotation foundation.math.Quaternion 圆台的旋转四元数
local Frustum3D = {}
Frustum3D.__type = "foundation.shape3D.Frustum3D"

---@param self foundation.shape3D.Frustum3D
---@param key any
---@return any
function Frustum3D.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "bottomRadius" then
        return self.__data.bottomRadius
    elseif key == "topRadius" then
        return self.__data.topRadius
    elseif key == "height" then
        return self.__data.height
    elseif key == "rotation" then
        return self.__data.rotation
    end
    return Frustum3D[key]
end

---@param self foundation.shape3D.Frustum3D
---@param key any
---@param value any
function Frustum3D.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "bottomRadius" then
        self.__data.bottomRadius = value
    elseif key == "topRadius" then
        self.__data.topRadius = value
    elseif key == "height" then
        self.__data.height = value
    elseif key == "rotation" then
        self.__data.rotation = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的圆台
---@param center foundation.math.Vector3 圆台的中心点
---@param bottomRadius number 圆台底部半径
---@param topRadius number 圆台顶部半径
---@param height number 圆台的高度
---@param rotation foundation.math.Quaternion 圆台的旋转四元数
---@return foundation.shape3D.Frustum3D 新创建的圆台
---@overload fun(center: foundation.math.Vector3, bottomRadius: number, topRadius: number, height: number): foundation.shape3D.Frustum3D
function Frustum3D.create(center, bottomRadius, topRadius, height, rotation)
    if not center then
        error("Center point cannot be nil")
    end
    bottomRadius = bottomRadius or 1
    topRadius = topRadius or 0.5
    height = height or 1
    rotation = rotation or Quaternion.identity()
    local frustum = ffi.new("foundation_shape3D_Frustum3D", center, bottomRadius, topRadius, height, rotation)
    local result = {
        __data = frustum,
    }
    return setmetatable(result, Frustum3D)
end

---比较两个圆台是否相等
---@param a foundation.shape3D.Frustum3D 第一个圆台
---@param b foundation.shape3D.Frustum3D 第二个圆台
---@return boolean 如果两个圆台的所有属性都相等则返回true，否则返回false
function Frustum3D.__eq(a, b)
    return a.center == b.center and
        a.bottomRadius == b.bottomRadius and
        a.topRadius == b.topRadius and
        a.height == b.height and
        a.rotation == b.rotation
end

---将圆台转换为字符串表示
---@param t foundation.shape3D.Frustum3D 要转换的圆台
---@return string 圆台的字符串表示
function Frustum3D.__tostring(t)
    return string.format("Frustum3D(%s, %f, %f, %f, %s)",
        tostring(t.center), t.bottomRadius, t.topRadius, t.height, tostring(t.rotation))
end

---获取圆台的中心点
---@return foundation.math.Vector3 圆台的中心点
function Frustum3D:getCenter()
    return self.center
end

---获取圆台的底部半径
---@return number 圆台的底部半径
function Frustum3D:getBottomRadius()
    return self.bottomRadius
end

---获取圆台的顶部半径
---@return number 圆台的顶部半径
function Frustum3D:getTopRadius()
    return self.topRadius
end

---获取圆台的高度
---@return number 圆台的高度
function Frustum3D:getHeight()
    return self.height
end

---获取圆台的旋转四元数
---@return foundation.math.Quaternion 圆台的旋转四元数
function Frustum3D:getRotation()
    return self.rotation
end

---将当前圆台平移指定距离
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Frustum3D 自身引用
function Frustum3D:move(v)
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

---获取圆台平移指定距离的副本
---@param v foundation.math.Vector3 | number 移动距离
---@return foundation.shape3D.Frustum3D 移动后的圆台副本
function Frustum3D:moved(v)
    return self:clone():move(v)
end

---将当前圆台缩放指定倍数
---@param scale number | foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心，默认为圆台中心
---@return foundation.shape3D.Frustum3D 自身引用
---@overload fun(self: foundation.shape3D.Frustum3D, scale: number | foundation.math.Vector3): foundation.shape3D.Frustum3D
function Frustum3D:scale(scale, center)
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
    self.bottomRadius = self.bottomRadius * math.sqrt(scaleVec.x * scaleVec.x + scaleVec.y * scaleVec.y) / math.sqrt(2)
    self.topRadius = self.topRadius * math.sqrt(scaleVec.x * scaleVec.x + scaleVec.y * scaleVec.y) / math.sqrt(2)
    self.height = self.height * scaleVec.z
    return self
end

---获取圆台缩放指定倍数的副本
---@param scale number | foundation.math.Vector3 缩放倍数
---@param center foundation.math.Vector3 缩放中心，默认为圆台中心
---@return foundation.shape3D.Frustum3D 缩放后的圆台副本
---@overload fun(self: foundation.shape3D.Frustum3D, scale: number | foundation.math.Vector3): foundation.shape3D.Frustum3D
function Frustum3D:scaled(scale, center)
    local result = self:clone()
    return result:scale(scale, center)
end

---将当前圆台绕轴旋转指定弧度
---@param rad number 旋转弧度
---@param axis foundation.math.Vector3 旋转轴
---@param center foundation.math.Vector3 旋转中心，默认为圆台中心
---@return foundation.shape3D.Frustum3D 自身引用
---@overload fun(self: foundation.shape3D.Frustum3D, rad: number, axis: foundation.math.Vector3): foundation.shape3D.Frustum3D
function Frustum3D:rotate(rad, axis, center)
    center = center or self:getCenter()
    local q = Quaternion.createFromAxisAngle(axis, rad)
    self.center = q:rotatePoint(self.center - center) + center
    self.rotation = q * self.rotation
    return self
end

---获取圆台绕轴旋转指定弧度的副本
---@param rad number 旋转弧度
---@param axis foundation.math.Vector3 旋转轴
---@param center foundation.math.Vector3 旋转中心，默认为圆台中心
---@return foundation.shape3D.Frustum3D 旋转后的圆台副本
---@overload fun(self: foundation.shape3D.Frustum3D, rad: number, axis: foundation.math.Vector3): foundation.shape3D.Frustum3D
function Frustum3D:rotated(rad, axis, center)
    local result = self:clone()
    return result:rotate(rad, axis, center)
end

---克隆圆台
---@return foundation.shape3D.Frustum3D 圆台的副本
function Frustum3D:clone()
    return Frustum3D.create(
        self.center:clone(),
        self.bottomRadius,
        self.topRadius,
        self.height,
        self.rotation:clone()
    )
end

ffi.metatype("foundation_shape3D_Frustum3D", Frustum3D)

return Frustum3D

local ffi = require("ffi")

local type = type
local string = string
local math = math
local require = require

---@type foundation.math.Vector2
local Vector2

---@type foundation.math.Vector4
local Vector4

---@type foundation.math.Quaternion
local Quaternion

---@type foundation.math.Matrix
local Matrix

---@type foundation.math.matrix.MatrixTransformation
local MatrixTransformation

ffi.cdef [[
typedef struct {
    double x;
    double y;
    double z;
} foundation_math_Vector3;
]]

---@class foundation.math.Vector3
---@field x number X坐标分量
---@field y number Y坐标分量
---@field z number Z坐标分量
---@operator add(foundation.math.Vector3): foundation.math.Vector3
---@operator add(number): foundation.math.Vector3
---@operator sub(foundation.math.Vector3): foundation.math.Vector3
---@operator sub(number): foundation.math.Vector3
---@operator mul(foundation.math.Vector3): foundation.math.Vector3
---@operator mul(number): foundation.math.Vector3
---@operator div(foundation.math.Vector3): foundation.math.Vector3
---@operator div(number): foundation.math.Vector3
---@operator unm(): foundation.math.Vector3
---@operator len(): number
local Vector3 = {}
Vector3.__index = Vector3
Vector3.__type = "foundation.math.Vector3"

---创建一个零向量
---@return foundation.math.Vector3 零向量
function Vector3.zero()
    return Vector3.create(0, 0, 0)
end

---创建一个新的三维向量
---@param x number|nil X坐标分量，默认为0
---@param y number|nil Y坐标分量，默认为0
---@param z number|nil Z坐标分量，默认为0
---@return foundation.math.Vector3 新创建的向量
function Vector3.create(x, y, z)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_math_Vector3", x or 0, y or 0, z or 0)
end

---根据弧度创建一个新的三维向量
---@param theta number 仰角（与XY平面的夹角，范围[-π,π]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
---@param r number|nil 距离（到原点的距离，默认为1）
---@return foundation.math.Vector3 新创建的向量
function Vector3.createFromRad(theta, phi, r)
    r = r or 1.0
    local sinTheta = math.sin(theta)
    local cosTheta = math.cos(theta)
    local sinPhi = math.sin(phi)
    local cosPhi = math.cos(phi)
    
    return Vector3.create(
        r * cosTheta * cosPhi,
        r * cosTheta * sinPhi,
        r * sinTheta
    )
end

---根据角度创建一个新的三维向量
---@param theta number 仰角（与XY平面的夹角，范围[-180,180]）
---@param phi number 方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
---@param r number|nil 距离（到原点的距离，默认为1）
---@return foundation.math.Vector3 新创建的向量
function Vector3.createFromAngle(theta, phi, r)
    return Vector3.createFromRad(math.rad(theta), math.rad(phi), r)
end

---通过特定结构的对象创建一个新的三维向量
---@param tbl table|foundation.math.Vector3 表或向量
---@return foundation.math.Vector3 新创建的向量
function Vector3.createFromTable(tbl)
    if tbl.x and tbl.y and tbl.z then
        return Vector3.create(tbl.x, tbl.y, tbl.z)
    end
    if tbl[1] and tbl[2] and tbl[3] then
        return Vector3.create(tbl[1], tbl[2], tbl[3])
    end
    error("Invalid table format for Vector2 creation")
end

---向量加法运算符重载
---@param a foundation.math.Vector3|number 第一个操作数
---@param b foundation.math.Vector3|number 第二个操作数
---@return foundation.math.Vector3 相加后的结果
function Vector3.__add(a, b)
    if type(a) == "number" then
        return Vector3.create(a + b.x, a + b.y, a + b.z)
    elseif type(b) == "number" then
        return Vector3.create(a.x + b, a.y + b, a.z + b)
    else
        return Vector3.create(a.x + b.x, a.y + b.y, a.z + b.z)
    end
end

---向量减法运算符重载
---@param a foundation.math.Vector3|number 第一个操作数
---@param b foundation.math.Vector3|number 第二个操作数
---@return foundation.math.Vector3 相减后的结果
function Vector3.__sub(a, b)
    if type(a) == "number" then
        return Vector3.create(a - b.x, a - b.y, a - b.z)
    elseif type(b) == "number" then
        return Vector3.create(a.x - b, a.y - b, a.z - b)
    else
        return Vector3.create(a.x - b.x, a.y - b.y, a.z - b.z)
    end
end

---向量乘法运算符重载
---@param a foundation.math.Vector3|number 第一个操作数
---@param b foundation.math.Vector3|number 第二个操作数
---@return foundation.math.Vector3 相乘后的结果
function Vector3.__mul(a, b)
    if type(a) == "number" then
        return Vector3.create(a * b.x, a * b.y, a * b.z)
    elseif type(b) == "number" then
        return Vector3.create(a.x * b, a.y * b, a.z * b)
    else
        return Vector3.create(a.x * b.x, a.y * b.y, a.z * b.z)
    end
end

---向量除法运算符重载
---@param a foundation.math.Vector3|number 第一个操作数
---@param b foundation.math.Vector3|number 第二个操作数
---@return foundation.math.Vector3 相除后的结果
function Vector3.__div(a, b)
    if type(a) == "number" then
        return Vector3.create(a / b.x, a / b.y, a / b.z)
    elseif type(b) == "number" then
        return Vector3.create(a.x / b, a.y / b, a.z / b)
    else
        return Vector3.create(a.x / b.x, a.y / b.y, a.z / b.z)
    end
end

---向量取负运算符重载
---@param v foundation.math.Vector3 操作数
---@return foundation.math.Vector3 取反后的向量
function Vector3.__unm(v)
    return Vector3.create(-v.x, -v.y, -v.z)
end

---向量相等性比较运算符重载
---@param a foundation.math.Vector3 第一个操作数
---@param b foundation.math.Vector3 第二个操作数
---@return boolean 两个向量是否相等
function Vector3.__eq(a, b)
    return math.abs(a.x - b.x) < 1e-10 and
            math.abs(a.y - b.y) < 1e-10 and
            math.abs(a.z - b.z) < 1e-10
end

---向量字符串表示
---@param v foundation.math.Vector3 操作数
---@return string 向量的字符串表示
function Vector3.__tostring(v)
    return string.format("Vector3(%f, %f, %f)", v.x, v.y, v.z)
end

---获取向量长度
---@param v foundation.math.Vector3 操作数
---@return number 向量的长度
function Vector3.__len(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end
Vector3.length = Vector3.__len

---获取向量的副本
---@return foundation.math.Vector3 向量的副本
function Vector3:clone()
    return Vector3.create(self.x, self.y, self.z)
end

---获取向量的角度（弧度）
---@return number, number 仰角（与XY平面的夹角，范围[-π,π]）和方位角（在XY平面上的投影与X轴的夹角，范围[-π,π]）
function Vector3:angle()
    local len = self:length()
    if len < 1e-10 then
        return 0, 0
    end
    local theta = math.atan2(self.z, math.sqrt(self.x * self.x + self.y * self.y))
    local phi = math.atan2(self.y, self.x)
    return theta, phi
end

---获取向量的角度（度）
---@return number, number 仰角（与XY平面的夹角，范围[-180,180]）和方位角（在XY平面上的投影与X轴的夹角，范围[-180,180]）
function Vector3:degreeAngle()
    local theta, phi = self:angle()
    return math.deg(theta), math.deg(phi)
end

---将Vector3转换为Vector2
---@return foundation.math.Vector2 转换后的Vector2
function Vector3:toVector2()
    Vector2 = Vector2 or require("foundation.math.Vector2")
    return Vector2.create(self.x, self.y)
end

---将Vector3转换为Vector4
---@param w number|nil W坐标分量，默认为0
---@return foundation.math.Vector4 转换后的Vector4
function Vector3:toVector4(w)
    Vector4 = Vector4 or require("foundation.math.Vector4")
    return Vector4.create(self.x, self.y, self.z, w or 0)
end

---计算两个向量的点积
---@param other foundation.math.Vector3 另一个向量
---@return number 两个向量的点积
function Vector3:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

---计算两个向量的叉积
---@param other foundation.math.Vector3 另一个向量
---@return foundation.math.Vector3 两个向量的叉积
function Vector3:cross(other)
    return Vector3.create(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x
    )
end

---将当前向量归一化（更改当前向量）
---@return foundation.math.Vector3 归一化后的向量（自身引用）
function Vector3:normalize()
    local len = self:length()
    if len > 1e-10 then
        self.x = self.x / len
        self.y = self.y / len
        self.z = self.z / len
    else
        self.x, self.y, self.z = 0, 0, 0
    end
    return self
end

---获取向量的归一化副本
---@return foundation.math.Vector3 归一化后的向量副本
function Vector3:normalized()
    local len = self:length()
    if len <= 1e-10 then
        return Vector3.zero()
    end
    return Vector3.create(self.x / len, self.y / len, self.z / len)
end

---将向量围绕任意轴旋转指定弧度（更改当前向量）
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:rotate(axis, rad)
    if not axis then
        error("Rotation axis cannot be nil")
    end
    
    local axisLength = axis:length()
    if math.abs(axisLength - 1.0) > 1e-6 then
        axis = axis:normalized()
    end
    
    rad = rad % (2 * math.pi)
    
    local c = math.cos(rad)
    local s = math.sin(rad)
    local k = 1 - c
    
    local ax = axis.x
    local ay = axis.y
    local az = axis.z
    local ax2 = ax * ax
    local ay2 = ay * ay
    local az2 = az * az
    local axy = ax * ay
    local axz = ax * az
    local ayz = ay * az
    
    local m11 = c + ax2 * k
    local m12 = axy * k - az * s
    local m13 = axz * k + ay * s
    local m21 = axy * k + az * s
    local m22 = c + ay2 * k
    local m23 = ayz * k - ax * s
    local m31 = axz * k - ay * s
    local m32 = ayz * k + ax * s
    local m33 = c + az2 * k
    
    local x = self.x * m11 + self.y * m12 + self.z * m13
    local y = self.x * m21 + self.y * m22 + self.z * m23
    local z = self.x * m31 + self.y * m32 + self.z * m33
    
    self.x, self.y, self.z = x, y, z
    return self
end

---获取向量围绕任意轴旋转指定弧度后的副本
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:rotated(axis, rad)
    local result = self:clone()
    return result:rotate(axis, rad)
end

---将向量围绕任意轴旋转指定角度（更改当前向量）
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:degreeRotate(axis, angle)
    return self:rotate(axis, math.rad(angle))
end

---获取向量围绕任意轴旋转指定角度后的副本
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:degreeRotated(axis, angle)
    return self:rotated(axis, math.rad(angle))
end

---将向量围绕X轴旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:rotateX(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local y = self.y * c - self.z * s
    local z = self.y * s + self.z * c
    self.y, self.z = y, z
    return self
end

---获取向量围绕X轴旋转指定弧度后的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:rotatedX(rad)
    local result = self:clone()
    return result:rotateX(rad)
end

---将向量围绕Y轴旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:rotateY(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local x = self.x * c + self.z * s
    local z = -self.x * s + self.z * c
    self.x, self.z = x, z
    return self
end

---获取向量围绕Y轴旋转指定弧度后的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:rotatedY(rad)
    local result = self:clone()
    return result:rotateY(rad)
end

---将向量围绕Z轴旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:rotateZ(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local x = self.x * c - self.y * s
    local y = self.x * s + self.y * c
    self.x, self.y = x, y
    return self
end

---获取向量围绕Z轴旋转指定弧度后的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:rotatedZ(rad)
    local result = self:clone()
    return result:rotateZ(rad)
end

---将向量围绕X轴旋转指定角度（更改当前向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:degreeRotateX(angle)
    return self:rotateX(math.rad(angle))
end

---获取向量围绕X轴旋转指定角度后的副本
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:degreeRotatedX(angle)
    return self:rotatedX(math.rad(angle))
end

---将向量围绕Y轴旋转指定角度（更改当前向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:degreeRotateY(angle)
    return self:rotateY(math.rad(angle))
end

---获取向量围绕Y轴旋转指定角度后的副本
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:degreeRotatedY(angle)
    return self:rotatedY(math.rad(angle))
end

---将向量围绕Z轴旋转指定角度（更改当前向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:degreeRotateZ(angle)
    return self:rotateZ(math.rad(angle))
end

---获取向量围绕Z轴旋转指定角度后的副本
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:degreeRotatedZ(angle)
    return self:rotatedZ(math.rad(angle))
end

---将向量转换为矩阵（3x1）
---@return foundation.math.Matrix 3x1矩阵
function Vector3:toMatrix()
    Matrix = Matrix or require("foundation.math.matrix.Matrix")
    return Matrix.fromVector3(self)
end

---将向量转换为四元数（w=1）
---@return foundation.math.Quaternion 四元数
function Vector3:toQuaternion()
    Quaternion = Quaternion or require("foundation.math.Quaternion")
    return Quaternion.fromVector3(self)
end

---使用四元数旋转向量
---@param q foundation.math.Quaternion 旋转四元数
---@return foundation.math.Vector3 旋转后的向量
function Vector3:rotateByQuaternion(q)
    Quaternion = Quaternion or require("foundation.math.Quaternion")
    return q:rotateVector(self)
end

---使用矩阵变换向量
---@param m foundation.math.Matrix 变换矩阵
---@return foundation.math.Vector3 变换后的向量
function Vector3:transform(m)
    MatrixTransformation = MatrixTransformation or require("foundation.math.matrix.MatrixTransformation")
    return MatrixTransformation.transformVector3(m, self)
end

ffi.metatype("foundation_math_Vector3", Vector3)

return Vector3
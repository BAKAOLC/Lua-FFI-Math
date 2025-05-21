local ffi = require("ffi")

local type = type
local string = string
local math = math
local require = require

---@type foundation.math.Vector3
local Vector3
---@type foundation.math.Vector2
local Vector2
---@type foundation.math.Vector4
local Vector4
---@type foundation.math.Matrix
local Matrix

ffi.cdef [[
typedef struct {
    double x;
    double y;
    double z;
    double w;
} foundation_math_Quaternion;
]]

---@class foundation.math.Quaternion
---@field x number 虚部i分量
---@field y number 虚部j分量
---@field z number 虚部k分量
---@field w number 实部
---@operator add(foundation.math.Quaternion): foundation.math.Quaternion
---@operator add(number): foundation.math.Quaternion
---@operator sub(foundation.math.Quaternion): foundation.math.Quaternion
---@operator sub(number): foundation.math.Quaternion
---@operator mul(foundation.math.Quaternion): foundation.math.Quaternion
---@operator mul(number): foundation.math.Quaternion
---@operator div(foundation.math.Quaternion): foundation.math.Quaternion
---@operator div(number): foundation.math.Quaternion
---@operator unm(): foundation.math.Quaternion
---@operator len(): number
local Quaternion = {}
Quaternion.__index = Quaternion
Quaternion.__type = "foundation.math.Quaternion"

---创建一个单位四元数
---@return foundation.math.Quaternion 单位四元数
function Quaternion.identity()
    return Quaternion.create(0, 0, 0, 1)
end

---创建一个新的四元数
---@param x number|nil 虚部i分量，默认为0
---@param y number|nil 虚部j分量，默认为0
---@param z number|nil 虚部k分量，默认为0
---@param w number|nil 实部，默认为1
---@return foundation.math.Quaternion 新创建的四元数
function Quaternion.create(x, y, z, w)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_math_Quaternion", x or 0, y or 0, z or 0, w or 1)
end

---从欧拉角创建四元数
---@param pitch number 俯仰角（绕X轴旋转）
---@param yaw number 偏航角（绕Y轴旋转）
---@param roll number 翻滚角（绕Z轴旋转）
---@return foundation.math.Quaternion 新创建的四元数
function Quaternion.fromEulerAngles(pitch, yaw, roll)
    local cy = math.cos(yaw * 0.5)
    local sy = math.sin(yaw * 0.5)
    local cp = math.cos(pitch * 0.5)
    local sp = math.sin(pitch * 0.5)
    local cr = math.cos(roll * 0.5)
    local sr = math.sin(roll * 0.5)

    return Quaternion.create(
        cy * sp * cr + sy * cp * sr,
        sy * cp * cr - cy * sp * sr,
        cy * cp * sr - sy * sp * cr,
        cy * cp * cr + sy * sp * sr
    )
end

---从旋转轴和角度创建四元数
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param angle number 旋转角度（弧度）
---@return foundation.math.Quaternion 新创建的四元数
function Quaternion.fromAxisAngle(axis, angle)
    local halfAngle = angle * 0.5
    local s = math.sin(halfAngle)
    return Quaternion.create(
        axis.x * s,
        axis.y * s,
        axis.z * s,
        math.cos(halfAngle)
    )
end

---四元数加法
---@param a foundation.math.Quaternion|number 第一个操作数
---@param b foundation.math.Quaternion|number 第二个操作数
---@return foundation.math.Quaternion 相加后的结果
function Quaternion.__add(a, b)
    if type(a) == "number" then
        return Quaternion.create(a + b.x, a + b.y, a + b.z, a + b.w)
    elseif type(b) == "number" then
        return Quaternion.create(a.x + b, a.y + b, a.z + b, a.w + b)
    else
        return Quaternion.create(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
    end
end

---四元数减法
---@param a foundation.math.Quaternion|number 第一个操作数
---@param b foundation.math.Quaternion|number 第二个操作数
---@return foundation.math.Quaternion 相减后的结果
function Quaternion.__sub(a, b)
    if type(a) == "number" then
        return Quaternion.create(a - b.x, a - b.y, a - b.z, a - b.w)
    elseif type(b) == "number" then
        return Quaternion.create(a.x - b, a.y - b, a.z - b, a.w - b)
    else
        return Quaternion.create(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
    end
end

---四元数乘法
---@param a foundation.math.Quaternion|number 第一个操作数
---@param b foundation.math.Quaternion|number 第二个操作数
---@return foundation.math.Quaternion 相乘后的结果
function Quaternion.__mul(a, b)
    if type(a) == "number" then
        return Quaternion.create(a * b.x, a * b.y, a * b.z, a * b.w)
    elseif type(b) == "number" then
        return Quaternion.create(a.x * b, a.y * b, a.z * b, a.w * b)
    else
        return Quaternion.create(
            a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
            a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
            a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
        )
    end
end

---四元数除法
---@param a foundation.math.Quaternion|number 第一个操作数
---@param b foundation.math.Quaternion|number 第二个操作数
---@return foundation.math.Quaternion 相除后的结果
function Quaternion.__div(a, b)
    if type(a) == "number" then
        return Quaternion.create(a / b.x, a / b.y, a / b.z, a / b.w)
    elseif type(b) == "number" then
        return Quaternion.create(a.x / b, a.y / b, a.z / b, a.w / b)
    else
        local inv = b:inverse()
        return a * inv
    end
end

---四元数取负
---@param q foundation.math.Quaternion 操作数
---@return foundation.math.Quaternion 取反后的四元数
function Quaternion.__unm(q)
    return Quaternion.create(-q.x, -q.y, -q.z, -q.w)
end

---四元数相等性比较
---@param a foundation.math.Quaternion 第一个操作数
---@param b foundation.math.Quaternion 第二个操作数
---@return boolean 两个四元数是否相等
function Quaternion.__eq(a, b)
    return math.abs(a.x - b.x) <= 1e-10 and
            math.abs(a.y - b.y) <= 1e-10 and
            math.abs(a.z - b.z) <= 1e-10 and
            math.abs(a.w - b.w) <= 1e-10
end

---四元数字符串表示
---@param q foundation.math.Quaternion 操作数
---@return string 四元数的字符串表示
function Quaternion.__tostring(q)
    return string.format("Quaternion(%f, %f, %f, %f)", q.x, q.y, q.z, q.w)
end

---获取四元数模长
---@param q foundation.math.Quaternion 操作数
---@return number 四元数的模长
function Quaternion.__len(q)
    return math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
end
Quaternion.length = Quaternion.__len

---获取四元数的副本
---@return foundation.math.Quaternion 四元数的副本
function Quaternion:clone()
    return Quaternion.create(self.x, self.y, self.z, self.w)
end

---计算四元数的共轭
---@return foundation.math.Quaternion 四元数的共轭
function Quaternion:conjugate()
    return Quaternion.create(-self.x, -self.y, -self.z, self.w)
end

---计算四元数的逆
---@return foundation.math.Quaternion 四元数的逆
function Quaternion:inverse()
    local lenSq = self:length() * self:length()
    if lenSq <= 1e-10 then
        return Quaternion.identity()
    end
    local inv = self:conjugate()
    return inv / lenSq
end

---将当前四元数归一化（更改当前四元数）
---@return foundation.math.Quaternion 归一化后的四元数（自身引用）
function Quaternion:normalize()
    local len = self:length()
    if len > 1e-10 then
        self.x = self.x / len
        self.y = self.y / len
        self.z = self.z / len
        self.w = self.w / len
    else
        self.x, self.y, self.z, self.w = 0, 0, 0, 1
    end
    return self
end

---获取四元数的归一化副本
---@return foundation.math.Quaternion 归一化后的四元数副本
function Quaternion:normalized()
    local len = self:length()
    if len <= 1e-10 then
        return Quaternion.identity()
    end
    return Quaternion.create(self.x / len, self.y / len, self.z / len, self.w / len)
end

---将四元数转换为欧拉角
---@return number, number, number 俯仰角、偏航角、翻滚角（弧度）
function Quaternion:toEulerAngles()
    local pitch = 0
    local sinPitch = 2 * (self.w * self.y - self.z * self.x)
    if math.abs(sinPitch) >= 1 then
        pitch = (sinPitch >= 0 and 1 or -1) * math.pi / 2
    else
        pitch = math.asin(sinPitch)
    end

    local yaw = math.atan2(2 * (self.w * self.z + self.x * self.y), 1 - 2 * (self.y * self.y + self.z * self.z))
    local roll = math.atan2(2 * (self.w * self.x + self.y * self.z), 1 - 2 * (self.x * self.x + self.y * self.y))

    return pitch, yaw, roll
end

---将四元数转换为旋转矩阵
---@return foundation.math.Matrix 3x3旋转矩阵
function Quaternion:toRotationMatrix()
    Matrix = Matrix or require("foundation.math.matrix.Matrix")
    return Matrix.fromQuaternion(self)
end

---使用四元数旋转一个三维向量
---@param v foundation.math.Vector3 要旋转的向量
---@return foundation.math.Vector3 旋转后的向量
function Quaternion:rotateVector(v)
    Vector3 = Vector3 or require("foundation.math.Vector3")
    local qv = Quaternion.create(v.x, v.y, v.z, 0)
    local rotated = self * qv * self:conjugate()
    return Vector3.create(rotated.x, rotated.y, rotated.z)
end

---计算两个四元数之间的球面插值
---@param other foundation.math.Quaternion 目标四元数
---@param t number 插值参数（0到1之间）
---@return foundation.math.Quaternion 插值结果
function Quaternion:sphericalLerp(other, t)
    local dot = self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
    
    if dot < 0 then
        other = -other
        dot = -dot
    end
    
    if dot > 0.9995 then
        return Quaternion.create(
            self.x + (other.x - self.x) * t,
            self.y + (other.y - self.y) * t,
            self.z + (other.z - self.z) * t,
            self.w + (other.w - self.w) * t
        ):normalized()
    end
    
    local theta = math.acos(dot)
    local sinTheta = math.sin(theta)
    local w1 = math.sin((1 - t) * theta) / sinTheta
    local w2 = math.sin(t * theta) / sinTheta
    
    return Quaternion.create(
        w1 * self.x + w2 * other.x,
        w1 * self.y + w2 * other.y,
        w1 * self.z + w2 * other.z,
        w1 * self.w + w2 * other.w
    )
end

---将四元数转换为二维向量
---@return foundation.math.Vector2 转换后的二维向量
function Quaternion:toVector2()
    Vector2 = Vector2 or require("foundation.math.Vector2")
    return Vector2.create(self.x, self.y)
end

---将四元数转换为三维向量
---@return foundation.math.Vector3 转换后的三维向量
function Quaternion:toVector3()
    Vector3 = Vector3 or require("foundation.math.Vector3")
    return Vector3.create(self.x, self.y, self.z)
end

---将四元数转换为四维向量
---@return foundation.math.Vector4 转换后的四维向量
function Quaternion:toVector4()
    Vector4 = Vector4 or require("foundation.math.Vector4")
    return Vector4.create(self.x, self.y, self.z, self.w)
end

---从二维向量创建四元数
---@param v foundation.math.Vector2 二维向量
---@return foundation.math.Quaternion 新创建的四元数
function Quaternion.fromVector2(v)
    return Quaternion.create(v.x, v.y, 0, 1)
end

---从三维向量创建四元数
---@param v foundation.math.Vector3 三维向量
---@return foundation.math.Quaternion 新创建的四元数
function Quaternion.fromVector3(v)
    return Quaternion.create(v.x, v.y, v.z, 1)
end

---从四维向量创建四元数
---@param v foundation.math.Vector4 四维向量
---@return foundation.math.Quaternion 新创建的四元数
function Quaternion.fromVector4(v)
    return Quaternion.create(v.x, v.y, v.z, v.w)
end

return Quaternion 
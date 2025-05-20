# Lua-FFI-Math

一个基于LuaJIT FFI的高性能数学库，提供2D和3D几何运算功能。

> ⚠️ **项目状态**：本项目目前处于早期开发阶段，API可能会随时发生变更。不建议在生产环境中使用。

## 功能特性

> 📝 **开发状态**：
>
> - 2D几何运算部分已基本完成，可以投入实际使用
> - 3D几何运算部分正在积极开发中，计划添加更多3D形状支持
> - 矩阵运算部分正在开发中

### 几何运算

#### 2D几何运算

- 基础形状支持：
  - 点 (Point)
  - 线段 (Segment)
  - 圆 (Circle)
  - 矩形 (Rectangle)
  - 多边形 (Polygon)
  - 扇形 (Sector)
  - 贝塞尔曲线 (BezierCurve)

#### 3D几何运算

- 基础形状支持：
  - 点 (Point3D)
  - 线段 (Segment3D)
  - 直线 (Line3D)
  - 三角形 (Triangle3D)
  - 矩形 (Rectangle3D)
- 开发计划：
  > 正在将2D形状逐步扩展到3D空间，包括：
  > - 已完成：点、线段、直线、三角形、矩形
  > - 开发中：圆、多边形、扇形、贝塞尔曲线
  > - 计划中：球体、立方体、圆柱体、圆锥体等基本3D形状

#### 几何运算通用功能

- 形状变换：
  - 平移 (translate)
  - 旋转 (rotate)
  - 缩放 (scale)
- 几何计算：
  - 点到形状的距离计算
  - 最近点计算
  - 点投影
  - 形状相交检测
  - 点包含检测

### 矩阵运算

- 基础矩阵操作：
  - 矩阵创建和初始化
  - 矩阵加减乘除运算
  - 矩阵转置
  - 矩阵求逆
  - 行列式计算
  - 矩阵求迹
  - 矩阵范数计算
- 特殊矩阵：
  - 单位矩阵
  - 对称矩阵
  - 反对称矩阵
  - Hadamard矩阵
- 高级功能：
  - 线性方程组求解
  - 矩阵分解
  - 子矩阵操作
  - 矩阵扩充
  - 哈达玛积（逐元素乘积）

## 安装

```bash
git clone https://github.com/yourusername/Lua-FFI-Math.git
cd Lua-FFI-Math
```

> ⚠️ **注意**：由于项目处于早期开发阶段，建议使用最新版本，并关注更新日志以了解API变更。

## 使用示例

### 几何运算

#### 2D几何运算

```lua
local Vector2 = require("foundation.math.Vector2")
local Circle = require("foundation.shape.Circle")

-- 创建一个圆
local center = Vector2.create(0, 0)
local circle = Circle.create(center, 5)

-- 计算点到圆的距离
local point = Vector2.create(3, 4)
local distance = circle:distanceToPoint(point)

-- 获取最近点
local closest = circle:closestPoint(point)
```

#### 3D几何运算

```lua
local Vector3 = require("foundation.math.Vector3")
local Triangle3D = require("foundation.shape3D.Triangle3D")

-- 创建一个3D三角形
local p1 = Vector3.create(0, 0, 0)
local p2 = Vector3.create(1, 0, 0)
local p3 = Vector3.create(0, 1, 0)
local triangle = Triangle3D.create(p1, p2, p3)

-- 计算点到三角形的距离
local point = Vector3.create(0.5, 0.5, 1)
local distance = triangle:distanceToPoint(point)

-- 获取最近点
local closest = triangle:closestPoint(point)
```

### 矩阵运算

```lua
local Matrix = require("foundation.math.matrix.Matrix")
local SpecialMatrix = require("foundation.math.matrix.SpecialMatrix")

-- 创建矩阵
local matrix = Matrix.create(3, 3)
matrix:set(1, 1, 1)
matrix:set(2, 2, 1)
matrix:set(3, 3, 1)

-- 矩阵运算
local result = matrix * matrix
local transpose = matrix:transpose()
local inverse = matrix:inverse()

-- 特殊矩阵
local identity = SpecialMatrix.identity(3)
local symmetric = SpecialMatrix.symmetric({1, 2, 3, 4, 5, 6}, 3)
```

## 性能特点

- 使用LuaJIT FFI实现，提供接近C语言的性能
- 优化的数学运算和几何算法
- 内存友好的数据结构设计

## 许可证

本项目采用MIT许可证。详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交Issue和Pull Request！

> 💡 **开发计划**：我们正在积极开发中，欢迎提供建议和反馈。如果您发现任何问题或有改进建议，请随时提交Issue。

## 作者

OLC

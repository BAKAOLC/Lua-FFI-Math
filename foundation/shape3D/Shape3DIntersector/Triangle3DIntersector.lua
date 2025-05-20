---@class foundation.shape3D.Shape3DIntersector
local Shape3DIntersector = {}

local math = math

local Vector3 = require("foundation.math.Vector3")

---投影点到指定二维平面
---@param point foundation.math.Vector3 要投影的三维点
---@param origin foundation.math.Vector3 平面原点
---@param axis1 foundation.math.Vector3 平面x轴方向
---@param axis2 foundation.math.Vector3 平面y轴方向
---@return foundation.math.Vector3 投影后的二维点（z为0）
local function projectPoint(point, origin, axis1, axis2)
    local v = point - origin
    return Vector3.new(v:dot(axis1), v:dot(axis2), 0)
end

---检测二维空间中两条线段的交点
---@param p1 foundation.math.Vector3 第一条线段起点
---@param p2 foundation.math.Vector3 第一条线段终点
---@param q1 foundation.math.Vector3 第二条线段起点
---@param q2 foundation.math.Vector3 第二条线段终点
---@param origin foundation.math.Vector3 平面原点
---@param axis1 foundation.math.Vector3 平面x轴
---@param axis2 foundation.math.Vector3 平面y轴
---@param intersections table 交点数组
---@param count number 当前交点数量
---@return number 新的交点数量
local function checkEdgeIntersection2D(p1, p2, q1, q2, origin, axis1, axis2, intersections, count)
    local d1 = p2 - p1
    local d2 = q2 - q1
    local det = d1.x * d2.y - d1.y * d2.x
    if math.abs(det) < 1e-10 then
        return count
    end

    local t1 = ((q1.x - p1.x) * d2.y - (q1.y - p1.y) * d2.x) / det
    local t2 = ((q1.x - p1.x) * d1.y - (q1.y - p1.y) * d1.x) / det

    if t1 >= 0 and t1 <= 1 and t2 >= 0 and t2 <= 1 then
        local intersection = p1 + d1 * t1
        count = count + 1
        intersections[count] = origin + axis1 * intersection.x + axis2 * intersection.y
    end
    return count
end

---检测三维空间中线段与三角形的交点
---@param p1 foundation.math.Vector3 线段起点
---@param p2 foundation.math.Vector3 线段终点
---@param triangle foundation.shape3D.Triangle3D 三角形对象
---@param n2 foundation.math.Vector3 三角形法向量
---@param intersections table 交点数组
---@param count number 当前交点数量
---@return number 新的交点数量
local function checkEdgeIntersection(p1, p2, triangle, n2, intersections, count)
    local d = p2 - p1
    local t = (triangle.point1 - p1):dot(n2) / d:dot(n2)
    if t >= 0 and t <= 1 then
        local intersection = p1 + d * t
        if triangle:containsPoint(intersection) then
            count = count + 1
            intersections[count] = intersection
        end
    end
    return count
end

---快速检测三维空间中线段与三角形是否有交点（只返回是否相交）
---@param p1 foundation.math.Vector3 线段起点
---@param p2 foundation.math.Vector3 线段终点
---@param triangle foundation.shape3D.Triangle3D 三角形对象
---@param n2 foundation.math.Vector3 三角形法向量
---@return boolean 是否有交点
local function checkEdgeIntersectionFast(p1, p2, triangle, n2)
    local d = p2 - p1
    local t = (triangle.point1 - p1):dot(n2) / d:dot(n2)
    if t >= 0 and t <= 1 then
        local intersection = p1 + d * t
        if triangle:containsPoint(intersection) then
            return true
        end
    end
    return false
end

---快速检测二维空间中两条线段是否有交点（只返回是否相交）
---@param p1 foundation.math.Vector3 第一条线段起点
---@param p2 foundation.math.Vector3 第一条线段终点
---@param q1 foundation.math.Vector3 第二条线段起点
---@param q2 foundation.math.Vector3 第二条线段终点
---@return boolean 是否有交点
local function checkEdgeIntersection2DFast(p1, p2, q1, q2)
    local d1 = p2 - p1
    local d2 = q2 - q1
    local det = d1.x * d2.y - d1.y * d2.x
    if math.abs(det) < 1e-10 then
        return false
    end

    local t1 = ((q1.x - p1.x) * d2.y - (q1.y - p1.y) * d2.x) / det
    local t2 = ((q1.x - p1.x) * d1.y - (q1.y - p1.y) * d1.x) / det

    return t1 >= 0 and t1 <= 1 and t2 >= 0 and t2 <= 1
end

---计算两个3D三角形的相交
---@param triangle1 foundation.shape3D.Triangle3D
---@param triangle2 foundation.shape3D.Triangle3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.triangleToTriangle(triangle1, triangle2)
    local v1 = triangle1.point1
    local v2 = triangle1.point2
    local v3 = triangle1.point3
    local u1 = triangle2.point1
    local u2 = triangle2.point2
    local u3 = triangle2.point3

    local n1 = (v2 - v1):cross(v3 - v1)
    local n2 = (u2 - u1):cross(u3 - u1)

    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        local d1 = (u1 - v1):dot(n1)
        if math.abs(d1) < 1e-10 then
            local intersections = {}
            local count = 0

            local axis1 = (v2 - v1):normalize()
            local axis2 = n1:cross(axis1):normalize()
            local origin = v1

            local v1_2d = projectPoint(v1, origin, axis1, axis2)
            local v2_2d = projectPoint(v2, origin, axis1, axis2)
            local v3_2d = projectPoint(v3, origin, axis1, axis2)
            local u1_2d = projectPoint(u1, origin, axis1, axis2)
            local u2_2d = projectPoint(u2, origin, axis1, axis2)
            local u3_2d = projectPoint(u3, origin, axis1, axis2)

            count = checkEdgeIntersection2D(v1_2d, v2_2d, u1_2d, u2_2d, origin, axis1, axis2, intersections, count)
            count = checkEdgeIntersection2D(v1_2d, v2_2d, u2_2d, u3_2d, origin, axis1, axis2, intersections, count)
            count = checkEdgeIntersection2D(v1_2d, v2_2d, u3_2d, u1_2d, origin, axis1, axis2, intersections, count)
            count = checkEdgeIntersection2D(v2_2d, v3_2d, u1_2d, u2_2d, origin, axis1, axis2, intersections, count)
            count = checkEdgeIntersection2D(v2_2d, v3_2d, u2_2d, u3_2d, origin, axis1, axis2, intersections, count)
            count = checkEdgeIntersection2D(v2_2d, v3_2d, u3_2d, u1_2d, origin, axis1, axis2, intersections, count)
            count = checkEdgeIntersection2D(v3_2d, v1_2d, u1_2d, u2_2d, origin, axis1, axis2, intersections, count)
            count = checkEdgeIntersection2D(v3_2d, v1_2d, u2_2d, u3_2d, origin, axis1, axis2, intersections, count)
            count = checkEdgeIntersection2D(v3_2d, v1_2d, u3_2d, u1_2d, origin, axis1, axis2, intersections, count)

            if count > 0 then
                return true, Shape3DIntersector.getUniquePoints(intersections)
            end
        end
        return false, nil
    end

    local intersections = {}
    local count = 0

    count = checkEdgeIntersection(v1, v2, triangle2, n2, intersections, count)
    count = checkEdgeIntersection(v2, v3, triangle2, n2, intersections, count)
    count = checkEdgeIntersection(v3, v1, triangle2, n2, intersections, count)

    count = checkEdgeIntersection(u1, u2, triangle1, n1, intersections, count)
    count = checkEdgeIntersection(u2, u3, triangle1, n1, intersections, count)
    count = checkEdgeIntersection(u3, u1, triangle1, n1, intersections, count)

    if count > 0 then
        return true, Shape3DIntersector.getUniquePoints(intersections)
    end

    return false, nil
end

---计算3D三角形与直线的相交
---@param triangle foundation.shape3D.Triangle3D
---@param line foundation.shape3D.Line3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.triangleToLine(triangle, line)
    local p = line.point
    local d = line.direction

    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (v1 - p):dot(n) / denom
    local intersection = p + d * t

    if triangle:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D三角形与射线的相交
---@param triangle foundation.shape3D.Triangle3D
---@param ray foundation.shape3D.Ray3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.triangleToRay(triangle, ray)
    local p = ray.point
    local d = ray.direction

    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (v1 - p):dot(n) / denom
    if t < 0 then
        return false, nil
    end

    local intersection = p + d * t

    if triangle:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D三角形与线段的相交
---@param triangle foundation.shape3D.Triangle3D
---@param segment foundation.shape3D.Segment3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.triangleToSegment(triangle, segment)
    local p = segment.point1
    local d = segment.point2 - p

    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (v1 - p):dot(n) / denom
    if t < 0 or t > 1 then
        return false, nil
    end

    local intersection = p + d * t

    if triangle:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---检查两个3D三角形是否相交
---@param triangle1 foundation.shape3D.Triangle3D
---@param triangle2 foundation.shape3D.Triangle3D
---@return boolean
function Shape3DIntersector.triangleHasIntersectionWithTriangle(triangle1, triangle2)
    local v1 = triangle1.point1
    local v2 = triangle1.point2
    local v3 = triangle1.point3
    local u1 = triangle2.point1
    local u2 = triangle2.point2
    local u3 = triangle2.point3

    local n1 = (v2 - v1):cross(v3 - v1)
    local n2 = (u2 - u1):cross(u3 - u1)

    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        local d1 = (u1 - v1):dot(n1)
        if math.abs(d1) < 1e-10 then
            local axis1 = (v2 - v1):normalize()
            local axis2 = n1:cross(axis1):normalize()
            local origin = v1

            local v1_2d = projectPoint(v1, origin, axis1, axis2)
            local v2_2d = projectPoint(v2, origin, axis1, axis2)
            local v3_2d = projectPoint(v3, origin, axis1, axis2)
            local u1_2d = projectPoint(u1, origin, axis1, axis2)
            local u2_2d = projectPoint(u2, origin, axis1, axis2)
            local u3_2d = projectPoint(u3, origin, axis1, axis2)

            if checkEdgeIntersection2DFast(v1_2d, v2_2d, u1_2d, u2_2d) then
                return true
            end
            if checkEdgeIntersection2DFast(v1_2d, v2_2d, u2_2d, u3_2d) then
                return true
            end
            if checkEdgeIntersection2DFast(v1_2d, v2_2d, u3_2d, u1_2d) then
                return true
            end
            if checkEdgeIntersection2DFast(v2_2d, v3_2d, u1_2d, u2_2d) then
                return true
            end
            if checkEdgeIntersection2DFast(v2_2d, v3_2d, u2_2d, u3_2d) then
                return true
            end
            if checkEdgeIntersection2DFast(v2_2d, v3_2d, u3_2d, u1_2d) then
                return true
            end
            if checkEdgeIntersection2DFast(v3_2d, v1_2d, u1_2d, u2_2d) then
                return true
            end
            if checkEdgeIntersection2DFast(v3_2d, v1_2d, u2_2d, u3_2d) then
                return true
            end
            if checkEdgeIntersection2DFast(v3_2d, v1_2d, u3_2d, u1_2d) then
                return true
            end
        end
        return false
    end

    if checkEdgeIntersectionFast(v1, v2, triangle2, n2) then
        return true
    end
    if checkEdgeIntersectionFast(v2, v3, triangle2, n2) then
        return true
    end
    if checkEdgeIntersectionFast(v3, v1, triangle2, n2) then
        return true
    end

    if checkEdgeIntersectionFast(u1, u2, triangle1, n1) then
        return true
    end
    if checkEdgeIntersectionFast(u2, u3, triangle1, n1) then
        return true
    end
    if checkEdgeIntersectionFast(u3, u1, triangle1, n1) then
        return true
    end

    return false
end

---检查3D三角形与直线是否相交
---@param triangle foundation.shape3D.Triangle3D
---@param line foundation.shape3D.Line3D
---@return boolean
function Shape3DIntersector.triangleHasIntersectionWithLine(triangle, line)
    local p = line.point
    local d = line.direction

    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (v1 - p):dot(n) / denom
    local intersection = p + d * t

    return triangle:containsPoint(intersection)
end

---检查3D三角形与射线是否相交
---@param triangle foundation.shape3D.Triangle3D
---@param ray foundation.shape3D.Ray3D
---@return boolean
function Shape3DIntersector.triangleHasIntersectionWithRay(triangle, ray)
    local p = ray.point
    local d = ray.direction

    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (v1 - p):dot(n) / denom
    if t < 0 then
        return false
    end

    local intersection = p + d * t
    return triangle:containsPoint(intersection)
end

---检查3D三角形与线段是否相交
---@param triangle foundation.shape3D.Triangle3D
---@param segment foundation.shape3D.Segment3D
---@return boolean
function Shape3DIntersector.triangleHasIntersectionWithSegment(triangle, segment)
    local p = segment.point1
    local d = segment.point2 - p

    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (v1 - p):dot(n) / denom
    if t < 0 or t > 1 then
        return false
    end

    local intersection = p + d * t
    return triangle:containsPoint(intersection)
end

---@param intersector foundation.shape3D.Shape3DIntersector
return function(intersector)
    for k, v in pairs(Shape3DIntersector) do
        intersector[k] = v
    end
    Shape3DIntersector = intersector
end

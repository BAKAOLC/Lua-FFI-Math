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

---检测三维空间中线段与多边形的交点
---@param p1 foundation.math.Vector3 线段起点
---@param p2 foundation.math.Vector3 线段终点
---@param shape any 多边形对象（如矩形、三角形）
---@param n2 foundation.math.Vector3 多边形法向量
---@param intersections table 交点数组
---@param count number 当前交点数量
---@return number 新的交点数量
local function checkEdgeIntersection(p1, p2, shape, n2, intersections, count)
    local d = p2 - p1
    local t = (shape:getVertices()[1] - p1):dot(n2) / d:dot(n2)
    if t >= 0 and t <= 1 then
        local intersection = p1 + d * t
        if shape:containsPoint(intersection) then
            count = count + 1
            intersections[count] = intersection
        end
    end
    return count
end

---快速检测三维空间中线段与多边形是否有交点（只返回是否相交）
---@param p1 foundation.math.Vector3 线段起点
---@param p2 foundation.math.Vector3 线段终点
---@param shape any 多边形对象
---@param n2 foundation.math.Vector3 多边形法向量
---@return boolean 是否有交点
local function checkEdgeIntersectionFast(p1, p2, shape, n2)
    local d = p2 - p1
    local t = (shape:getVertices()[1] - p1):dot(n2) / d:dot(n2)
    if t >= 0 and t <= 1 then
        local intersection = p1 + d * t
        if shape:containsPoint(intersection) then
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

---计算两个3D矩形的相交
---@param rectangle1 foundation.shape3D.Rectangle3D
---@param rectangle2 foundation.shape3D.Rectangle3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.rectangleToRectangle(rectangle1, rectangle2)
    local vertices1 = rectangle1:getVertices()
    local vertices2 = rectangle2:getVertices()

    local n1 = (vertices1[2] - vertices1[1]):cross(vertices1[3] - vertices1[1])
    local n2 = (vertices2[2] - vertices2[1]):cross(vertices2[3] - vertices2[1])

    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        local d1 = (vertices2[1] - vertices1[1]):dot(n1)
        if math.abs(d1) < 1e-10 then
            local intersections = {}
            local count = 0

            local axis1 = (vertices1[2] - vertices1[1]):normalize()
            local axis2 = n1:cross(axis1):normalize()
            local origin = vertices1[1]

            local v1_2d = {}
            local v2_2d = {}
            for i = 1, 4 do
                v1_2d[i] = projectPoint(vertices1[i], origin, axis1, axis2)
                v2_2d[i] = projectPoint(vertices2[i], origin, axis1, axis2)
            end

            for i = 1, 4 do
                local j = i % 4 + 1
                for k = 1, 4 do
                    local l = k % 4 + 1
                    count = checkEdgeIntersection2D(v1_2d[i], v1_2d[j], v2_2d[k], v2_2d[l], origin, axis1, axis2,
                            intersections, count)
                end
            end

            if count > 0 then
                return true, Shape3DIntersector.getUniquePoints(intersections)
            end
        end
        return false, nil
    end

    local intersections = {}
    local count = 0

    for i = 1, 4 do
        local j = i % 4 + 1
        count = checkEdgeIntersection(vertices1[i], vertices1[j], rectangle2, n2, intersections, count)
        count = checkEdgeIntersection(vertices2[i], vertices2[j], rectangle1, n1, intersections, count)
    end

    if count > 0 then
        return true, Shape3DIntersector.getUniquePoints(intersections)
    end

    return false, nil
end

---计算3D矩形与三角形的相交
---@param rectangle foundation.shape3D.Rectangle3D
---@param triangle foundation.shape3D.Triangle3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.rectangleToTriangle(rectangle, triangle)
    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3

    local vertices = rectangle:getVertices()
    local n1 = (v2 - v1):cross(v3 - v1)
    local n2 = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])

    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        local d1 = (vertices[1] - v1):dot(n1)
        if math.abs(d1) < 1e-10 then
            return false, nil
        end
        return false, nil
    end

    local intersections = {}
    local count = 0

    for i = 1, 4 do
        local j = i % 4 + 1
        count = checkEdgeIntersection(vertices[i], vertices[j], triangle, n1, intersections, count)
    end

    count = checkEdgeIntersection(v1, v2, rectangle, n2, intersections, count)
    count = checkEdgeIntersection(v2, v3, rectangle, n2, intersections, count)
    count = checkEdgeIntersection(v3, v1, rectangle, n2, intersections, count)

    if count > 0 then
        return true, Shape3DIntersector.getUniquePoints(intersections)
    end

    return false, nil
end

---计算3D矩形与直线的相交
---@param rectangle foundation.shape3D.Rectangle3D
---@param line foundation.shape3D.Line3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.rectangleToLine(rectangle, line)
    local p = line.point
    local d = line.direction

    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (vertices[1] - p):dot(n) / denom
    local intersection = p + d * t

    if rectangle:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D矩形与射线的相交
---@param rectangle foundation.shape3D.Rectangle3D
---@param ray foundation.shape3D.Ray3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.rectangleToRay(rectangle, ray)
    local p = ray.point
    local d = ray.direction

    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (vertices[1] - p):dot(n) / denom
    if t < 0 then
        return false, nil
    end

    local intersection = p + d * t

    if rectangle:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D矩形与线段的相交
---@param rectangle foundation.shape3D.Rectangle3D
---@param segment foundation.shape3D.Segment3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.rectangleToSegment(rectangle, segment)
    local p = segment.point1
    local d = segment.point2 - p

    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (vertices[1] - p):dot(n) / denom
    if t < 0 or t > 1 then
        return false, nil
    end

    local intersection = p + d * t

    if rectangle:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---检查两个3D矩形是否相交
---@param rectangle1 foundation.shape3D.Rectangle3D
---@param rectangle2 foundation.shape3D.Rectangle3D
---@return boolean
function Shape3DIntersector.rectangleHasIntersectionWithRectangle(rectangle1, rectangle2)
    local vertices1 = rectangle1:getVertices()
    local vertices2 = rectangle2:getVertices()

    local n1 = (vertices1[2] - vertices1[1]):cross(vertices1[3] - vertices1[1])
    local n2 = (vertices2[2] - vertices2[1]):cross(vertices2[3] - vertices2[1])

    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        local d1 = (vertices2[1] - vertices1[1]):dot(n1)
        if math.abs(d1) < 1e-10 then
            local axis1 = (vertices1[2] - vertices1[1]):normalize()
            local axis2 = n1:cross(axis1):normalize()
            local origin = vertices1[1]

            local v1_2d = {}
            local v2_2d = {}
            for i = 1, 4 do
                v1_2d[i] = projectPoint(vertices1[i], origin, axis1, axis2)
                v2_2d[i] = projectPoint(vertices2[i], origin, axis1, axis2)
            end

            for i = 1, 4 do
                local j = i % 4 + 1
                for k = 1, 4 do
                    local l = k % 4 + 1
                    if checkEdgeIntersection2DFast(v1_2d[i], v1_2d[j], v2_2d[k], v2_2d[l]) then
                        return true
                    end
                end
            end
        end
        return false
    end

    for i = 1, 4 do
        local j = i % 4 + 1
        if checkEdgeIntersectionFast(vertices1[i], vertices1[j], rectangle2, n2) then
            return true
        end
        if checkEdgeIntersectionFast(vertices2[i], vertices2[j], rectangle1, n1) then
            return true
        end
    end

    return false
end

---检查3D矩形与三角形是否相交
---@param rectangle foundation.shape3D.Rectangle3D
---@param triangle foundation.shape3D.Triangle3D
---@return boolean
function Shape3DIntersector.rectangleHasIntersectionWithTriangle(rectangle, triangle)
    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3

    local vertices = rectangle:getVertices()
    local n1 = (v2 - v1):cross(v3 - v1)
    local n2 = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])

    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        local d1 = (vertices[1] - v1):dot(n1)
        if math.abs(d1) < 1e-10 then
            return false
        end
        return false
    end

    for i = 1, 4 do
        local j = i % 4 + 1
        if checkEdgeIntersectionFast(vertices[i], vertices[j], triangle, n1) then
            return true
        end
    end

    if checkEdgeIntersectionFast(v1, v2, rectangle, n2) then
        return true
    end
    if checkEdgeIntersectionFast(v2, v3, rectangle, n2) then
        return true
    end
    if checkEdgeIntersectionFast(v3, v1, rectangle, n2) then
        return true
    end

    return false
end

---检查3D矩形与直线是否相交
---@param rectangle foundation.shape3D.Rectangle3D
---@param line foundation.shape3D.Line3D
---@return boolean
function Shape3DIntersector.rectangleHasIntersectionWithLine(rectangle, line)
    local p = line.point
    local d = line.direction

    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (vertices[1] - p):dot(n) / denom
    local intersection = p + d * t

    return rectangle:containsPoint(intersection)
end

---检查3D矩形与射线是否相交
---@param rectangle foundation.shape3D.Rectangle3D
---@param ray foundation.shape3D.Ray3D
---@return boolean
function Shape3DIntersector.rectangleHasIntersectionWithRay(rectangle, ray)
    local p = ray.point
    local d = ray.direction

    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (vertices[1] - p):dot(n) / denom
    if t < 0 then
        return false
    end

    local intersection = p + d * t
    return rectangle:containsPoint(intersection)
end

---检查3D矩形与线段是否相交
---@param rectangle foundation.shape3D.Rectangle3D
---@param segment foundation.shape3D.Segment3D
---@return boolean
function Shape3DIntersector.rectangleHasIntersectionWithSegment(rectangle, segment)
    local p = segment.point1
    local d = segment.point2 - p

    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])

    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (vertices[1] - p):dot(n) / denom
    if t < 0 or t > 1 then
        return false
    end

    local intersection = p + d * t
    return rectangle:containsPoint(intersection)
end

---@param intersector foundation.shape3D.Shape3DIntersector
return function(intersector)
    for k, v in pairs(Shape3DIntersector) do
        intersector[k] = v
    end
    Shape3DIntersector = intersector
end

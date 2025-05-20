---@class foundation.shape3D.Shape3DIntersector
local Shape3DIntersector = {}

local math = math

---检查点是否在3D矩形内
---@param rectangle foundation.shape3D.Rectangle3D
---@param point foundation.math.Vector3
---@return boolean
function Shape3DIntersector.rectangleContainsPoint(rectangle, point)
    local vertices = rectangle:getVertices()
    local v1 = vertices[1]
    local v2 = vertices[2]
    local v3 = vertices[3]
    local v4 = vertices[4]

    local n = (v2 - v1):cross(v3 - v1)
    local d = (point - v1):dot(n)
    if math.abs(d) > 1e-10 then
        return false
    end

    local e1 = v2 - v1
    local e2 = v3 - v2
    local e3 = v4 - v3
    local e4 = v1 - v4

    local p1 = point - v1
    local p2 = point - v2
    local p3 = point - v3
    local p4 = point - v4

    local c1 = e1:cross(p1)
    local c2 = e2:cross(p2)
    local c3 = e3:cross(p3)
    local c4 = e4:cross(p4)

    return c1:dot(n) >= 0 and c2:dot(n) >= 0 and c3:dot(n) >= 0 and c4:dot(n) >= 0
end

---检查点是否在3D三角形内
---@param triangle foundation.shape3D.Triangle3D
---@param point foundation.math.Vector3
---@return boolean
function Shape3DIntersector.triangleContainsPoint(triangle, point)
    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3

    local n = (v2 - v1):cross(v3 - v1)
    local d = (point - v1):dot(n)
    if math.abs(d) > 1e-10 then
        return false
    end

    local e1 = v2 - v1
    local e2 = v3 - v2
    local e3 = v1 - v3

    local p1 = point - v1
    local p2 = point - v2
    local p3 = point - v3

    local c1 = e1:cross(p1)
    local c2 = e2:cross(p2)
    local c3 = e3:cross(p3)

    return c1:dot(n) >= 0 and c2:dot(n) >= 0 and c3:dot(n) >= 0
end

---检查点是否在3D线段上
---@param segment foundation.shape3D.Segment3D
---@param point foundation.math.Vector3
---@return boolean
function Shape3DIntersector.segmentContainsPoint(segment, point)
    local start = segment.point1
    local end_ = segment.point2
    local d = end_ - start
    local p = point - start

    local cross = d:cross(p)
    if cross:length() > 1e-10 then
        return false
    end

    local t = p:dot(d) / d:dot(d)
    return t >= 0 and t <= 1
end

---检查点是否在3D射线上
---@param ray foundation.shape3D.Ray3D
---@param point foundation.math.Vector3
---@return boolean
function Shape3DIntersector.rayContainsPoint(ray, point)
    local origin = ray.point
    local direction = ray.direction
    local p = point - origin

    local cross = direction:cross(p)
    if cross:length() > 1e-10 then
        return false
    end

    local t = p:dot(direction) / direction:dot(direction)
    return t >= 0
end

---检查点是否在3D直线上
---@param line foundation.shape3D.Line3D
---@param point foundation.math.Vector3
---@return boolean
function Shape3DIntersector.lineContainsPoint(line, point)
    local origin = line.point
    local direction = line.direction
    local p = point - origin

    local cross = direction:cross(p)
    return cross:length() <= 1e-10
end

---@param intersector foundation.shape3D.Shape3DIntersector
return function(intersector)
    for k, v in pairs(Shape3DIntersector) do
        intersector[k] = v
    end
    Shape3DIntersector = intersector
end

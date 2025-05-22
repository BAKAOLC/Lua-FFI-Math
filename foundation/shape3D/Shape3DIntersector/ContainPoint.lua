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

---检查点是否在3D圆内
---@param circle foundation.shape3D.Circle3D
---@param point foundation.math.Vector3
---@return boolean
function Shape3DIntersector.circleContainsPoint(circle, point)
    local normal = circle:normal()
    local v1p = point - circle.center
    local dist = v1p:dot(normal)
    if math.abs(dist) > 1e-10 then
        return false
    end
    local projected = point - normal * dist
    local dir = projected - circle.center
    local length = dir:length()
    return length <= circle.radius
end

---检查点是否在3D扇形内
---@param sector foundation.shape3D.Sector3D
---@param point foundation.math.Vector3
---@return boolean
function Shape3DIntersector.sectorContainsPoint(sector, point)
    local normal = sector:normal()
    local v1p = point - sector.center
    local dist = v1p:dot(normal)
    if math.abs(dist) > 1e-10 then
        return false
    end
    local projected = point - normal * dist
    local dir = projected - sector.center
    local length = dir:length()
    if length > sector.radius then
        return false
    end
    if length <= 1e-10 then
        return true
    end

    local angle_begin
    if sector.range > 0 then
        angle_begin = sector:getDirection():angle()
    else
        local range = -sector.range
        angle_begin = sector:getDirection():angle() - range
    end

    local vec_angle = dir:angle()
    vec_angle = vec_angle - 2 * math.pi * math.floor((vec_angle - angle_begin) / (2 * math.pi))
    return angle_begin <= vec_angle and vec_angle <= angle_begin + math.abs(sector.range) * 2 * math.pi
end

---@param intersector foundation.shape3D.Shape3DIntersector
return function(intersector)
    for k, v in pairs(Shape3DIntersector) do
        intersector[k] = v
    end
    Shape3DIntersector = intersector
end

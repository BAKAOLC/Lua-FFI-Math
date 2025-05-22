---@class foundation.shape3D.Shape3DIntersector
local Shape3DIntersector = {}

local math = math

---@type foundation.shape3D.Segment3D
local Segment3D

---计算两个3D圆的相交
---@param circle1 foundation.shape3D.Circle3D
---@param circle2 foundation.shape3D.Circle3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.circleToCircle(circle1, circle2)
    local n1 = circle1:normal()
    local n2 = circle2:normal()
    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        if math.abs(n1:dot(n2)) < 0 then
            return false, nil
        end
        local v = circle2.center - circle1.center
        local dist = v:length()
        if dist > circle1.radius + circle2.radius then
            return false, nil
        end
        if dist < math.abs(circle1.radius - circle2.radius) then
            return false, nil
        end
        if math.abs(dist - (circle1.radius + circle2.radius)) <= 1e-10 or math.abs(dist - math.abs(circle1.radius - circle2.radius)) <= 1e-10 then
            local dir = v:normalized()
            return true, { circle1.center + dir * circle1.radius }
        end
        local a = (circle1.radius * circle1.radius - circle2.radius * circle2.radius + dist * dist) / (2 * dist)
        local h = math.sqrt(circle1.radius * circle1.radius - a * a)
        local p = circle1.center + v * (a / dist)
        local dir = v:cross(n1):normalized()
        return true, { p + dir * h, p - dir * h }
    end

    local p1 = circle1.center
    local p2 = circle2.center
    local r1 = circle1.radius
    local r2 = circle2.radius

    local v = p2 - p1
    local dist = v:length()
    if dist > r1 + r2 then
        return false, nil
    end

    local n = d:normalized()
    local t = -v:dot(n) / n:dot(n)
    local p = p1 + n * t
    local v1 = p - p1
    local v2 = p - p2
    local d1 = v1:length()
    local d2 = v2:length()

    if d1 > r1 or d2 > r2 then
        return false, nil
    end

    local h1 = math.sqrt(r1 * r1 - d1 * d1)
    local h2 = math.sqrt(r2 * r2 - d2 * d2)
    local dir = v:cross(n):normalized()
    return true, { p + dir * h1, p - dir * h1 }
end

---计算3D圆与线段的相交
---@param circle foundation.shape3D.Circle3D
---@param segment foundation.shape3D.Segment3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.circleToSegment(circle, segment)
    local p = segment.point1
    local d = segment.point2 - p
    local n = circle:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (circle.center - p):dot(n) / denom
    if t < 0 or t > 1 then
        return false, nil
    end

    local intersection = p + d * t
    if circle:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D圆与射线的相交
---@param circle foundation.shape3D.Circle3D
---@param ray foundation.shape3D.Ray3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.circleToRay(circle, ray)
    local p = ray.point
    local d = ray.direction
    local n = circle:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (circle.center - p):dot(n) / denom
    if t < 0 then
        return false, nil
    end

    local intersection = p + d * t
    if circle:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D圆与直线的相交
---@param circle foundation.shape3D.Circle3D
---@param line foundation.shape3D.Line3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.circleToLine(circle, line)
    local p = line.point
    local d = line.direction
    local n = circle:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (circle.center - p):dot(n) / denom
    local intersection = p + d * t
    if circle:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D圆与三角形的相交
---@param circle foundation.shape3D.Circle3D
---@param triangle foundation.shape3D.Triangle3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.circleToTriangle(circle, triangle)
    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)
    local d = (circle.center - v1):dot(n)
    if math.abs(d) > circle.radius then
        return false, nil
    end

    local projected = circle.center - n * (d / n:dot(n))
    if triangle:containsPoint(projected) then
        return true, { projected }
    end

    local edges = {
        { v1, v2 },
        { v2, v3 },
        { v3, v1 }
    }

    local intersections = {}
    local count = 0

    Segment3D = Segment3D or require("foundation.shape3D.Segment3D")
    for _, edge in ipairs(edges) do
        local segment = Segment3D.create(edge[1], edge[2])
        local hasIntersection, points = Shape3DIntersector.circleToSegment(circle, segment)
        if hasIntersection then
            for _, point in ipairs(points) do
                count = count + 1
                intersections[count] = point
            end
        end
    end

    if count > 0 then
        return true, intersections
    end

    return false, nil
end

---计算3D圆与矩形的相交
---@param circle foundation.shape3D.Circle3D
---@param rectangle foundation.shape3D.Rectangle3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.circleToRectangle(circle, rectangle)
    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])
    local d = (circle.center - vertices[1]):dot(n)
    if math.abs(d) > circle.radius then
        return false, nil
    end

    local projected = circle.center - n * (d / n:dot(n))
    if rectangle:containsPoint(projected) then
        return true, { projected }
    end

    local edges = {
        { vertices[1], vertices[2] },
        { vertices[2], vertices[3] },
        { vertices[3], vertices[4] },
        { vertices[4], vertices[1] }
    }

    local intersections = {}
    local count = 0

    Segment3D = Segment3D or require("foundation.shape3D.Segment3D")
    for _, edge in ipairs(edges) do
        local segment = Segment3D.create(edge[1], edge[2])
        local hasIntersection, points = Shape3DIntersector.circleToSegment(circle, segment)
        if hasIntersection then
            for _, point in ipairs(points) do
                count = count + 1
                intersections[count] = point
            end
        end
    end

    if count > 0 then
        return true, intersections
    end

    return false, nil
end

---计算3D圆与扇形的相交
---@param circle foundation.shape3D.Circle3D
---@param sector foundation.shape3D.Sector3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.circleToSector(circle, sector)
    local n1 = circle:normal()
    local n2 = sector:normal()
    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        if math.abs(n1:dot(n2)) < 0 then
            return false, nil
        end
        local v = sector.center - circle.center
        local dist = v:length()
        if dist > circle.radius + sector.radius then
            return false, nil
        end
        if dist < math.abs(circle.radius - sector.radius) then
            return false, nil
        end
        if math.abs(dist - (circle.radius + sector.radius)) <= 1e-10 or math.abs(dist - math.abs(circle.radius - sector.radius)) <= 1e-10 then
            local dir = v:normalized()
            local point = circle.center + dir * circle.radius
            if sector:containsPoint(point) then
                return true, { point }
            end
            return false, nil
        end
        local a = (circle.radius * circle.radius - sector.radius * sector.radius + dist * dist) / (2 * dist)
        local h = math.sqrt(circle.radius * circle.radius - a * a)
        local p = circle.center + v * (a / dist)
        local dir = v:cross(n1):normalized()
        local points = { p + dir * h, p - dir * h }
        local intersections = {}
        local count = 0
        for _, point in ipairs(points) do
            if sector:containsPoint(point) then
                count = count + 1
                intersections[count] = point
            end
        end
        if count > 0 then
            return true, intersections
        end
        return false, nil
    end

    local p1 = circle.center
    local p2 = sector.center
    local r1 = circle.radius
    local r2 = sector.radius

    local v = p2 - p1
    local dist = v:length()
    if dist > r1 + r2 then
        return false, nil
    end

    local n = d:normalized()
    local t = -v:dot(n) / n:dot(n)
    local p = p1 + n * t
    local v1 = p - p1
    local v2 = p - p2
    local d1 = v1:length()
    local d2 = v2:length()

    if d1 > r1 or d2 > r2 then
        return false, nil
    end

    local h1 = math.sqrt(r1 * r1 - d1 * d1)
    local h2 = math.sqrt(r2 * r2 - d2 * d2)
    local dir = v:cross(n):normalized()
    local points = { p + dir * h1, p - dir * h1 }
    local intersections = {}
    local count = 0
    for _, point in ipairs(points) do
        if sector:containsPoint(point) then
            count = count + 1
            intersections[count] = point
        end
    end
    if count > 0 then
        return true, intersections
    end
    return false, nil
end

---检查两个3D圆是否相交
---@param circle1 foundation.shape3D.Circle3D
---@param circle2 foundation.shape3D.Circle3D
---@return boolean
function Shape3DIntersector.circleHasIntersectionWithCircle(circle1, circle2)
    local n1 = circle1:normal()
    local n2 = circle2:normal()
    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        if math.abs(n1:dot(n2)) < 0 then
            return false
        end
        local v = circle2.center - circle1.center
        local dist = v:length()
        return dist <= circle1.radius + circle2.radius and dist >= math.abs(circle1.radius - circle2.radius)
    end

    local p1 = circle1.center
    local p2 = circle2.center
    local r1 = circle1.radius
    local r2 = circle2.radius

    local v = p2 - p1
    local dist = v:length()
    if dist > r1 + r2 then
        return false
    end

    local n = d:normalized()
    local t = -v:dot(n) / n:dot(n)
    local p = p1 + n * t
    local v1 = p - p1
    local v2 = p - p2
    local d1 = v1:length()
    local d2 = v2:length()

    return d1 <= r1 and d2 <= r2
end

---检查3D圆与线段是否相交
---@param circle foundation.shape3D.Circle3D
---@param segment foundation.shape3D.Segment3D
---@return boolean
function Shape3DIntersector.circleHasIntersectionWithSegment(circle, segment)
    local p = segment.point1
    local d = segment.point2 - p
    local n = circle:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (circle.center - p):dot(n) / denom
    if t < 0 or t > 1 then
        return false
    end

    local intersection = p + d * t
    return circle:containsPoint(intersection)
end

---检查3D圆与射线是否相交
---@param circle foundation.shape3D.Circle3D
---@param ray foundation.shape3D.Ray3D
---@return boolean
function Shape3DIntersector.circleHasIntersectionWithRay(circle, ray)
    local p = ray.point
    local d = ray.direction
    local n = circle:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (circle.center - p):dot(n) / denom
    if t < 0 then
        return false
    end

    local intersection = p + d * t
    return circle:containsPoint(intersection)
end

---检查3D圆与直线是否相交
---@param circle foundation.shape3D.Circle3D
---@param line foundation.shape3D.Line3D
---@return boolean
function Shape3DIntersector.circleHasIntersectionWithLine(circle, line)
    local p = line.point
    local d = line.direction
    local n = circle:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (circle.center - p):dot(n) / denom
    local intersection = p + d * t
    return circle:containsPoint(intersection)
end

---检查3D圆与三角形是否相交
---@param circle foundation.shape3D.Circle3D
---@param triangle foundation.shape3D.Triangle3D
---@return boolean
function Shape3DIntersector.circleHasIntersectionWithTriangle(circle, triangle)
    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)
    local d = (circle.center - v1):dot(n)
    if math.abs(d) > circle.radius then
        return false
    end

    local projected = circle.center - n * (d / n:dot(n))
    if triangle:containsPoint(projected) then
        return true
    end

    local edges = {
        { v1, v2 },
        { v2, v3 },
        { v3, v1 }
    }

    Segment3D = Segment3D or require("foundation.shape3D.Segment3D")
    for _, edge in ipairs(edges) do
        local segment = Segment3D.create(edge[1], edge[2])
        if Shape3DIntersector.circleHasIntersectionWithSegment(circle, segment) then
            return true
        end
    end

    return false
end

---检查3D圆与矩形是否相交
---@param circle foundation.shape3D.Circle3D
---@param rectangle foundation.shape3D.Rectangle3D
---@return boolean
function Shape3DIntersector.circleHasIntersectionWithRectangle(circle, rectangle)
    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])
    local d = (circle.center - vertices[1]):dot(n)
    if math.abs(d) > circle.radius then
        return false
    end

    local projected = circle.center - n * (d / n:dot(n))
    if rectangle:containsPoint(projected) then
        return true
    end

    local edges = {
        { vertices[1], vertices[2] },
        { vertices[2], vertices[3] },
        { vertices[3], vertices[4] },
        { vertices[4], vertices[1] }
    }

    Segment3D = Segment3D or require("foundation.shape3D.Segment3D")
    for _, edge in ipairs(edges) do
        local segment = Segment3D.create(edge[1], edge[2])
        if Shape3DIntersector.circleHasIntersectionWithSegment(circle, segment) then
            return true
        end
    end

    return false
end

---检查3D圆与扇形是否相交
---@param circle foundation.shape3D.Circle3D
---@param sector foundation.shape3D.Sector3D
---@return boolean
function Shape3DIntersector.circleHasIntersectionWithSector(circle, sector)
    local n1 = circle:normal()
    local n2 = sector:normal()
    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        if math.abs(n1:dot(n2)) < 0 then
            return false
        end
        local v = sector.center - circle.center
        local dist = v:length()
        if dist > circle.radius + sector.radius then
            return false
        end
        if dist < math.abs(circle.radius - sector.radius) then
            return false
        end
        if math.abs(dist - (circle.radius + sector.radius)) <= 1e-10 or math.abs(dist - math.abs(circle.radius - sector.radius)) <= 1e-10 then
            local dir = v:normalized()
            local point = circle.center + dir * circle.radius
            return sector:containsPoint(point)
        end
        local a = (circle.radius * circle.radius - sector.radius * sector.radius + dist * dist) / (2 * dist)
        local h = math.sqrt(circle.radius * circle.radius - a * a)
        local p = circle.center + v * (a / dist)
        local dir = v:cross(n1):normalized()
        local points = { p + dir * h, p - dir * h }
        for _, point in ipairs(points) do
            if sector:containsPoint(point) then
                return true
            end
        end
        return false
    end

    local p1 = circle.center
    local p2 = sector.center
    local r1 = circle.radius
    local r2 = sector.radius

    local v = p2 - p1
    local dist = v:length()
    if dist > r1 + r2 then
        return false
    end

    local n = d:normalized()
    local t = -v:dot(n) / n:dot(n)
    local p = p1 + n * t
    local v1 = p - p1
    local v2 = p - p2
    local d1 = v1:length()
    local d2 = v2:length()

    if d1 > r1 or d2 > r2 then
        return false
    end

    local h1 = math.sqrt(r1 * r1 - d1 * d1)
    local h2 = math.sqrt(r2 * r2 - d2 * d2)
    local dir = v:cross(n):normalized()
    local points = { p + dir * h1, p - dir * h1 }
    for _, point in ipairs(points) do
        if sector:containsPoint(point) then
            return true
        end
    end
    return false
end

---@param intersector foundation.shape3D.Shape3DIntersector
return function(intersector)
    for k, v in pairs(Shape3DIntersector) do
        intersector[k] = v
    end
    Shape3DIntersector = intersector
end

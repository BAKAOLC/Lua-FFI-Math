---@class foundation.shape3D.Shape3DIntersector
local Shape3DIntersector = {}

local math = math

---@type foundation.shape3D.Segment3D
local Segment3D

---计算两个3D扇形的相交
---@param sector1 foundation.shape3D.Sector3D
---@param sector2 foundation.shape3D.Sector3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.sectorToSector(sector1, sector2)
    local n1 = sector1:normal()
    local n2 = sector2:normal()
    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        if math.abs(n1:dot(n2)) < 0 then
            return false, nil
        end
        local v = sector2.center - sector1.center
        local dist = v:length()
        if dist > sector1.radius + sector2.radius then
            return false, nil
        end
        if dist < math.abs(sector1.radius - sector2.radius) then
            return false, nil
        end
        if math.abs(dist - (sector1.radius + sector2.radius)) <= 1e-10 or math.abs(dist - math.abs(sector1.radius - sector2.radius)) <= 1e-10 then
            local dir = v:normalized()
            local point = sector1.center + dir * sector1.radius
            if sector1:containsPoint(point) and sector2:containsPoint(point) then
                return true, { point }
            end
            return false, nil
        end
        local a = (sector1.radius * sector1.radius - sector2.radius * sector2.radius + dist * dist) / (2 * dist)
        local h = math.sqrt(sector1.radius * sector1.radius - a * a)
        local p = sector1.center + v * (a / dist)
        local dir = v:cross(n1):normalized()
        local points = { p + dir * h, p - dir * h }
        local intersections = {}
        local count = 0
        for _, point in ipairs(points) do
            if sector1:containsPoint(point) and sector2:containsPoint(point) then
                count = count + 1
                intersections[count] = point
            end
        end
        if count > 0 then
            return true, intersections
        end
        return false, nil
    end

    local p1 = sector1.center
    local p2 = sector2.center
    local r1 = sector1.radius
    local r2 = sector2.radius

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
        if sector1:containsPoint(point) and sector2:containsPoint(point) then
            count = count + 1
            intersections[count] = point
        end
    end
    if count > 0 then
        return true, intersections
    end
    return false, nil
end

---计算3D扇形与线段的相交
---@param sector foundation.shape3D.Sector3D
---@param segment foundation.shape3D.Segment3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.sectorToSegment(sector, segment)
    local p = segment.point1
    local d = segment.point2 - p
    local n = sector:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (sector.center - p):dot(n) / denom
    if t < 0 or t > 1 then
        return false, nil
    end

    local intersection = p + d * t
    if sector:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D扇形与射线的相交
---@param sector foundation.shape3D.Sector3D
---@param ray foundation.shape3D.Ray3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.sectorToRay(sector, ray)
    local p = ray.point
    local d = ray.direction
    local n = sector:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (sector.center - p):dot(n) / denom
    if t < 0 then
        return false, nil
    end

    local intersection = p + d * t
    if sector:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D扇形与直线的相交
---@param sector foundation.shape3D.Sector3D
---@param line foundation.shape3D.Line3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.sectorToLine(sector, line)
    local p = line.point
    local d = line.direction
    local n = sector:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = (sector.center - p):dot(n) / denom
    local intersection = p + d * t
    if sector:containsPoint(intersection) then
        return true, { intersection }
    end

    return false, nil
end

---计算3D扇形与三角形的相交
---@param sector foundation.shape3D.Sector3D
---@param triangle foundation.shape3D.Triangle3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.sectorToTriangle(sector, triangle)
    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)
    local d = (sector.center - v1):dot(n)
    if math.abs(d) > sector.radius then
        return false, nil
    end

    local projected = sector.center - n * (d / n:dot(n))
    if sector:containsPoint(projected) and triangle:containsPoint(projected) then
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
        local hasIntersection, points = Shape3DIntersector.sectorToSegment(sector, segment)
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

---计算3D扇形与矩形的相交
---@param sector foundation.shape3D.Sector3D
---@param rectangle foundation.shape3D.Rectangle3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.sectorToRectangle(sector, rectangle)
    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])
    local d = (sector.center - vertices[1]):dot(n)
    if math.abs(d) > sector.radius then
        return false, nil
    end

    local projected = sector.center - n * (d / n:dot(n))
    if sector:containsPoint(projected) and rectangle:containsPoint(projected) then
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
        local hasIntersection, points = Shape3DIntersector.sectorToSegment(sector, segment)
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

---检查两个3D扇形是否相交
---@param sector1 foundation.shape3D.Sector3D
---@param sector2 foundation.shape3D.Sector3D
---@return boolean
function Shape3DIntersector.sectorHasIntersectionWithSector(sector1, sector2)
    local n1 = sector1:normal()
    local n2 = sector2:normal()
    local d = n1:cross(n2)
    if d:length() < 1e-10 then
        if math.abs(n1:dot(n2)) < 0 then
            return false
        end
        local v = sector2.center - sector1.center
        local dist = v:length()
        if dist > sector1.radius + sector2.radius then
            return false
        end
        if dist < math.abs(sector1.radius - sector2.radius) then
            return false
        end
        if math.abs(dist - (sector1.radius + sector2.radius)) <= 1e-10 or math.abs(dist - math.abs(sector1.radius - sector2.radius)) <= 1e-10 then
            local dir = v:normalized()
            local point = sector1.center + dir * sector1.radius
            return sector1:containsPoint(point) and sector2:containsPoint(point)
        end
        local a = (sector1.radius * sector1.radius - sector2.radius * sector2.radius + dist * dist) / (2 * dist)
        local h = math.sqrt(sector1.radius * sector1.radius - a * a)
        local p = sector1.center + v * (a / dist)
        local dir = v:cross(n1):normalized()
        local points = { p + dir * h, p - dir * h }
        for _, point in ipairs(points) do
            if sector1:containsPoint(point) and sector2:containsPoint(point) then
                return true
            end
        end
        return false
    end

    local p1 = sector1.center
    local p2 = sector2.center
    local r1 = sector1.radius
    local r2 = sector2.radius

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
        if sector1:containsPoint(point) and sector2:containsPoint(point) then
            return true
        end
    end
    return false
end

---检查3D扇形与线段是否相交
---@param sector foundation.shape3D.Sector3D
---@param segment foundation.shape3D.Segment3D
---@return boolean
function Shape3DIntersector.sectorHasIntersectionWithSegment(sector, segment)
    local p = segment.point1
    local d = segment.point2 - p
    local n = sector:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (sector.center - p):dot(n) / denom
    if t < 0 or t > 1 then
        return false
    end

    local intersection = p + d * t
    return sector:containsPoint(intersection)
end

---检查3D扇形与射线是否相交
---@param sector foundation.shape3D.Sector3D
---@param ray foundation.shape3D.Ray3D
---@return boolean
function Shape3DIntersector.sectorHasIntersectionWithRay(sector, ray)
    local p = ray.point
    local d = ray.direction
    local n = sector:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (sector.center - p):dot(n) / denom
    if t < 0 then
        return false
    end

    local intersection = p + d * t
    return sector:containsPoint(intersection)
end

---检查3D扇形与直线是否相交
---@param sector foundation.shape3D.Sector3D
---@param line foundation.shape3D.Line3D
---@return boolean
function Shape3DIntersector.sectorHasIntersectionWithLine(sector, line)
    local p = line.point
    local d = line.direction
    local n = sector:normal()
    local denom = d:dot(n)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = (sector.center - p):dot(n) / denom
    local intersection = p + d * t
    return sector:containsPoint(intersection)
end

---检查3D扇形与三角形是否相交
---@param sector foundation.shape3D.Sector3D
---@param triangle foundation.shape3D.Triangle3D
---@return boolean
function Shape3DIntersector.sectorHasIntersectionWithTriangle(sector, triangle)
    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local n = (v2 - v1):cross(v3 - v1)
    local d = (sector.center - v1):dot(n)
    if math.abs(d) > sector.radius then
        return false
    end

    local projected = sector.center - n * (d / n:dot(n))
    if sector:containsPoint(projected) and triangle:containsPoint(projected) then
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
        if Shape3DIntersector.sectorHasIntersectionWithSegment(sector, segment) then
            return true
        end
    end

    return false
end

---检查3D扇形与矩形是否相交
---@param sector foundation.shape3D.Sector3D
---@param rectangle foundation.shape3D.Rectangle3D
---@return boolean
function Shape3DIntersector.sectorHasIntersectionWithRectangle(sector, rectangle)
    local vertices = rectangle:getVertices()
    local n = (vertices[2] - vertices[1]):cross(vertices[3] - vertices[1])
    local d = (sector.center - vertices[1]):dot(n)
    if math.abs(d) > sector.radius then
        return false
    end

    local projected = sector.center - n * (d / n:dot(n))
    if sector:containsPoint(projected) and rectangle:containsPoint(projected) then
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
        if Shape3DIntersector.sectorHasIntersectionWithSegment(sector, segment) then
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

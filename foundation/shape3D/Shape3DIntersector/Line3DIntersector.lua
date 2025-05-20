---@class foundation.shape3D.Shape3DIntersector
local Shape3DIntersector = {}

---计算两条3D直线的相交
---@param line1 foundation.shape3D.Line3D
---@param line2 foundation.shape3D.Line3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.lineToLine(line1, line2)
    local p1 = line1.point
    local d1 = line1.direction
    local p2 = line2.point
    local d2 = line2.direction

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        if d:cross(d1):length() < 1e-10 then
            return true, { p1 }
        end
        return false, nil
    end

    local t1 = (p2 - p1):cross(d2):dot(n) / n:dot(n)

    local intersection = p1 + d1 * t1
    return true, { intersection }
end

---计算3D直线与射线的相交
---@param line foundation.shape3D.Line3D
---@param ray foundation.shape3D.Ray3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.lineToRay(line, ray)
    local p1 = line.point
    local d1 = line.direction
    local p2 = ray.point
    local d2 = ray.direction

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        if d:cross(d1):length() < 1e-10 then
            return true, { p2 }
        end
        return false, nil
    end

    local t1 = (p2 - p1):cross(d2):dot(n) / n:dot(n)
    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)

    if t2 < 0 then
        return false, nil
    end

    local intersection = p1 + d1 * t1
    return true, { intersection }
end

---计算3D直线与线段的相交
---@param line foundation.shape3D.Line3D
---@param segment foundation.shape3D.Segment3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.lineToSegment(line, segment)
    local p1 = line.point
    local d1 = line.direction
    local p2 = segment.point1
    local d2 = segment.point2 - p2

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        if d:cross(d1):length() < 1e-10 then
            return true, { p2, segment.point2 }
        end
        return false, nil
    end

    local t1 = (p2 - p1):cross(d2):dot(n) / n:dot(n)
    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)

    if t2 < 0 or t2 > 1 then
        return false, nil
    end

    local intersection = p1 + d1 * t1
    return true, { intersection }
end

---检查两条3D直线是否相交
---@param line1 foundation.shape3D.Line3D
---@param line2 foundation.shape3D.Line3D
---@return boolean
function Shape3DIntersector.lineHasIntersectionWithLine(line1, line2)
    local p1 = line1.point
    local d1 = line1.direction
    local p2 = line2.point
    local d2 = line2.direction

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        return d:cross(d1):length() < 1e-10
    end

    return true
end

---检查3D直线与射线是否相交
---@param line foundation.shape3D.Line3D
---@param ray foundation.shape3D.Ray3D
---@return boolean
function Shape3DIntersector.lineHasIntersectionWithRay(line, ray)
    local p1 = line.point
    local d1 = line.direction
    local p2 = ray.point
    local d2 = ray.direction

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        return d:cross(d1):length() < 1e-10
    end

    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)
    return t2 >= 0
end

---检查3D直线与线段是否相交
---@param line foundation.shape3D.Line3D
---@param segment foundation.shape3D.Segment3D
---@return boolean
function Shape3DIntersector.lineHasIntersectionWithSegment(line, segment)
    local p1 = line.point
    local d1 = line.direction
    local p2 = segment.point1
    local d2 = segment.point2 - p2

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        return d:cross(d1):length() < 1e-10
    end

    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)
    return t2 >= 0 and t2 <= 1
end

---@param intersector foundation.shape3D.Shape3DIntersector
return function(intersector)
    for k, v in pairs(Shape3DIntersector) do
        intersector[k] = v
    end
    Shape3DIntersector = intersector
end

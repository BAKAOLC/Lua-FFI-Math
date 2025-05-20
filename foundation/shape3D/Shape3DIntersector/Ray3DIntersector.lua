---@class foundation.shape3D.Shape3DIntersector
local Shape3DIntersector = {}

---计算两条3D射线的相交
---@param ray1 foundation.shape3D.Ray3D
---@param ray2 foundation.shape3D.Ray3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.rayToRay(ray1, ray2)
    local p1 = ray1.point
    local d1 = ray1.direction
    local p2 = ray2.point
    local d2 = ray2.direction

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        if d:cross(d1):length() < 1e-10 then
            local t1 = d:dot(d1) / d1:dot(d1)
            local t2 = -d:dot(d2) / d2:dot(d2)
            if t1 >= 0 and t2 >= 0 then
                return true, { p1 + d1 * t1 }
            end
        end
        return false, nil
    end

    local t1 = (p2 - p1):cross(d2):dot(n) / n:dot(n)
    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)

    if t1 < 0 or t2 < 0 then
        return false, nil
    end

    local intersection = p1 + d1 * t1
    return true, { intersection }
end

---计算3D射线与线段的相交
---@param ray foundation.shape3D.Ray3D
---@param segment foundation.shape3D.Segment3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.rayToSegment(ray, segment)
    local p1 = ray.point
    local d1 = ray.direction
    local p2 = segment.point1
    local d2 = segment.point2 - p2

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        if d:cross(d1):length() < 1e-10 then
            local t1 = d:dot(d1) / d1:dot(d1)
            local t2 = -d:dot(d2) / d2:dot(d2)
            if t1 >= 0 and t2 >= 0 and t2 <= 1 then
                return true, { p1 + d1 * t1 }
            end
        end
        return false, nil
    end

    local t1 = (p2 - p1):cross(d2):dot(n) / n:dot(n)
    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)

    if t1 < 0 or t2 < 0 or t2 > 1 then
        return false, nil
    end

    local intersection = p1 + d1 * t1
    return true, { intersection }
end

---检查两条3D射线是否相交
---@param ray1 foundation.shape3D.Ray3D
---@param ray2 foundation.shape3D.Ray3D
---@return boolean
function Shape3DIntersector.rayHasIntersectionWithRay(ray1, ray2)
    local p1 = ray1.point
    local d1 = ray1.direction
    local p2 = ray2.point
    local d2 = ray2.direction

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        if d:cross(d1):length() < 1e-10 then
            local t1 = d:dot(d1) / d1:dot(d1)
            local t2 = -d:dot(d2) / d2:dot(d2)
            return t1 >= 0 and t2 >= 0
        end
        return false
    end

    local t1 = (p2 - p1):cross(d2):dot(n) / n:dot(n)
    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)
    return t1 >= 0 and t2 >= 0
end

---检查3D射线与线段是否相交
---@param ray foundation.shape3D.Ray3D
---@param segment foundation.shape3D.Segment3D
---@return boolean
function Shape3DIntersector.rayHasIntersectionWithSegment(ray, segment)
    local p1 = ray.point
    local d1 = ray.direction
    local p2 = segment.point1
    local d2 = segment.point2 - p2

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        if d:cross(d1):length() < 1e-10 then
            local t1 = d:dot(d1) / d1:dot(d1)
            local t2 = -d:dot(d2) / d2:dot(d2)
            return t1 >= 0 and t2 >= 0 and t2 <= 1
        end
        return false
    end

    local t1 = (p2 - p1):cross(d2):dot(n) / n:dot(n)
    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)
    return t1 >= 0 and t2 >= 0 and t2 <= 1
end

---@param intersector foundation.shape3D.Shape3DIntersector
return function(intersector)
    for k, v in pairs(Shape3DIntersector) do
        intersector[k] = v
    end
    Shape3DIntersector = intersector
end

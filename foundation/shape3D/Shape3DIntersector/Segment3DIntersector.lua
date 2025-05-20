---@class foundation.shape3D.Shape3DIntersector
local Shape3DIntersector = {}

local math = math

---计算两条3D线段的相交
---@param segment1 foundation.shape3D.Segment3D
---@param segment2 foundation.shape3D.Segment3D
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.segmentToSegment(segment1, segment2)
    local p1 = segment1.point1
    local d1 = segment1.point2 - p1
    local p2 = segment2.point1
    local d2 = segment2.point2 - p2

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        if d:cross(d1):length() < 1e-10 then
            local t1 = d:dot(d1) / d1:dot(d1)
            local t2 = -d:dot(d2) / d2:dot(d2)
            if t1 >= 0 and t1 <= 1 and t2 >= 0 and t2 <= 1 then
                local start_t = math.max(0, t1)
                local end_t = math.min(1, t1 + t2)
                if start_t <= end_t then
                    return true, { p1 + d1 * start_t, p1 + d1 * end_t }
                end
            end
        end
        return false, nil
    end

    local t1 = (p2 - p1):cross(d2):dot(n) / n:dot(n)
    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)

    if t1 < 0 or t1 > 1 or t2 < 0 or t2 > 1 then
        return false, nil
    end

    local intersection = p1 + d1 * t1
    return true, { intersection }
end

---检查两条3D线段是否相交
---@param segment1 foundation.shape3D.Segment3D
---@param segment2 foundation.shape3D.Segment3D
---@return boolean
function Shape3DIntersector.segmentHasIntersectionWithSegment(segment1, segment2)
    local p1 = segment1.point1
    local d1 = segment1.point2 - p1
    local p2 = segment2.point1
    local d2 = segment2.point2 - p2

    local n = d1:cross(d2)
    if n:length() < 1e-10 then
        local d = p2 - p1
        if d:cross(d1):length() < 1e-10 then
            local t1 = d:dot(d1) / d1:dot(d1)
            local t2 = -d:dot(d2) / d2:dot(d2)
            return t1 >= 0 and t1 <= 1 and t2 >= 0 and t2 <= 1
        end
        return false
    end

    local t1 = (p2 - p1):cross(d2):dot(n) / n:dot(n)
    local t2 = (p2 - p1):cross(d1):dot(n) / n:dot(n)
    return t1 >= 0 and t1 <= 1 and t2 >= 0 and t2 <= 1
end

---@param intersector foundation.shape3D.Shape3DIntersector
return function(intersector)
    for k, v in pairs(Shape3DIntersector) do
        intersector[k] = v
    end
    Shape3DIntersector = intersector
end

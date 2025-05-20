local tostring = tostring
local ipairs = ipairs

---3D形状类型枚举
---@class foundation.shape3D.Shape3DType
local Shape3DType = {
    RECTANGLE = "foundation.shape3D.Rectangle3D",
    TRIANGLE = "foundation.shape3D.Triangle3D",
    LINE = "foundation.shape3D.Line3D",
    RAY = "foundation.shape3D.Ray3D",
    SEGMENT = "foundation.shape3D.Segment3D",
}

---@class foundation.shape3D.Shape3DIntersector
local Shape3DIntersector = {}

local Shape3DIntersectorList = {
    "ContainPoint",
    "Line3DIntersector",
    "Triangle3DIntersector",
    "Rectangle3DIntersector",
    "Segment3DIntersector",
    "Ray3DIntersector",
}
for _, moduleName in ipairs(Shape3DIntersectorList) do
    local module = require(string.format("foundation.shape3D.Shape3DIntersector.%s", moduleName))
    module(Shape3DIntersector)
end

---整理相交点，去除重复点
---@param points foundation.math.Vector3[] 原始点列表
---@return foundation.math.Vector3[] 去重后的点列表
function Shape3DIntersector.getUniquePoints(points)
    local unique_points = {}
    local seen = {}

    local index = 0
    for _, p in ipairs(points) do
        local key = tostring(p)
        if not seen[key] then
            seen[key] = true
            index = index + 1
            unique_points[index] = p
        end
    end

    return unique_points
end

---@type table<foundation.shape3D.Shape3DType, table<foundation.shape3D.Shape3DType, fun(shape1: any, shape2: any): boolean, foundation.math.Vector3[] | nil>>
local intersectionMap = {
    [Shape3DType.RECTANGLE] = {
        [Shape3DType.RECTANGLE] = Shape3DIntersector.rectangleToRectangle,
        [Shape3DType.TRIANGLE] = Shape3DIntersector.rectangleToTriangle,
        [Shape3DType.LINE] = Shape3DIntersector.rectangleToLine,
        [Shape3DType.RAY] = Shape3DIntersector.rectangleToRay,
        [Shape3DType.SEGMENT] = Shape3DIntersector.rectangleToSegment,
    },
    [Shape3DType.TRIANGLE] = {
        [Shape3DType.TRIANGLE] = Shape3DIntersector.triangleToTriangle,
        [Shape3DType.LINE] = Shape3DIntersector.triangleToLine,
        [Shape3DType.RAY] = Shape3DIntersector.triangleToRay,
        [Shape3DType.SEGMENT] = Shape3DIntersector.triangleToSegment,
    },
    [Shape3DType.LINE] = {
        [Shape3DType.LINE] = Shape3DIntersector.lineToLine,
        [Shape3DType.RAY] = Shape3DIntersector.lineToRay,
        [Shape3DType.SEGMENT] = Shape3DIntersector.lineToSegment,
    },
    [Shape3DType.RAY] = {
        [Shape3DType.RAY] = Shape3DIntersector.rayToRay,
        [Shape3DType.SEGMENT] = Shape3DIntersector.rayToSegment,
    },
    [Shape3DType.SEGMENT] = {
        [Shape3DType.SEGMENT] = Shape3DIntersector.segmentToSegment,
    },
}

---@type table<foundation.shape3D.Shape3DType, table<foundation.shape3D.Shape3DType, fun(shape1: any, shape2: any): boolean>>
local hasIntersectionMap = {
    [Shape3DType.RECTANGLE] = {
        [Shape3DType.RECTANGLE] = Shape3DIntersector.rectangleHasIntersectionWithRectangle,
        [Shape3DType.TRIANGLE] = Shape3DIntersector.rectangleHasIntersectionWithTriangle,
        [Shape3DType.LINE] = Shape3DIntersector.rectangleHasIntersectionWithLine,
        [Shape3DType.RAY] = Shape3DIntersector.rectangleHasIntersectionWithRay,
        [Shape3DType.SEGMENT] = Shape3DIntersector.rectangleHasIntersectionWithSegment,
    },
    [Shape3DType.TRIANGLE] = {
        [Shape3DType.TRIANGLE] = Shape3DIntersector.triangleHasIntersectionWithTriangle,
        [Shape3DType.LINE] = Shape3DIntersector.triangleHasIntersectionWithLine,
        [Shape3DType.RAY] = Shape3DIntersector.triangleHasIntersectionWithRay,
        [Shape3DType.SEGMENT] = Shape3DIntersector.triangleHasIntersectionWithSegment,
    },
    [Shape3DType.LINE] = {
        [Shape3DType.LINE] = Shape3DIntersector.lineHasIntersectionWithLine,
        [Shape3DType.RAY] = Shape3DIntersector.lineHasIntersectionWithRay,
        [Shape3DType.SEGMENT] = Shape3DIntersector.lineHasIntersectionWithSegment,
    },
    [Shape3DType.RAY] = {
        [Shape3DType.RAY] = Shape3DIntersector.rayHasIntersectionWithRay,
        [Shape3DType.SEGMENT] = Shape3DIntersector.rayHasIntersectionWithSegment,
    },
    [Shape3DType.SEGMENT] = {
        [Shape3DType.SEGMENT] = Shape3DIntersector.segmentHasIntersectionWithSegment,
    },
}

---检查与其他3D形状的相交
---@param shape1 any 第一个3D形状
---@param shape2 any 第二个3D形状
---@return boolean, foundation.math.Vector3[] | nil
function Shape3DIntersector.intersect(shape1, shape2)
    local type1 = shape1.__type
    local type2 = shape2.__type

    local intersectionFunc = intersectionMap[type1] and intersectionMap[type1][type2]
    if intersectionFunc then
        return intersectionFunc(shape1, shape2)
    end

    intersectionFunc = intersectionMap[type2] and intersectionMap[type2][type1]
    if intersectionFunc then
        return intersectionFunc(shape2, shape1)
    end

    return false, nil
end

---只检查是否与其他3D形状相交
---@param shape1 any 第一个3D形状
---@param shape2 any 第二个3D形状
---@return boolean
function Shape3DIntersector.hasIntersection(shape1, shape2)
    local type1 = shape1.__type
    local type2 = shape2.__type

    local intersectionFunc = hasIntersectionMap[type1] and hasIntersectionMap[type1][type2]
    if intersectionFunc then
        return intersectionFunc(shape1, shape2)
    end

    intersectionFunc = hasIntersectionMap[type2] and hasIntersectionMap[type2][type1]
    if intersectionFunc then
        return intersectionFunc(shape2, shape1)
    end

    return false
end

function Shape3DIntersector.checkMissingIntersection()
    local keys = {}
    for k, _ in pairs(intersectionMap) do
        keys[#keys + 1] = k
    end

    local missing = {}
    for i = 1, #keys do
        local key1 = keys[i]
        for j = i, #keys do
            local key2 = keys[j]
            if not intersectionMap[key1][key2] and not intersectionMap[key2][key1] then
                missing[#missing + 1] = { key1, key2 }
            end
        end
    end

    if #missing > 0 then
        print("Missing 3D intersections:")
        for _, pair in ipairs(missing) do
            print(pair[1], pair[2])
        end
    else
        print("No missing 3D intersections found.")
    end

    local hasIntersectionKeys = {}
    for k, _ in pairs(hasIntersectionMap) do
        hasIntersectionKeys[#hasIntersectionKeys + 1] = k
    end

    local missingHasIntersection = {}
    for i = 1, #hasIntersectionKeys do
        local key1 = hasIntersectionKeys[i]
        for j = i, #hasIntersectionKeys do
            local key2 = hasIntersectionKeys[j]
            if not hasIntersectionMap[key1][key2] and not hasIntersectionMap[key2][key1] then
                missingHasIntersection[#missingHasIntersection + 1] = { key1, key2 }
            end
        end
    end

    if #missingHasIntersection > 0 then
        print("Missing 3D hasIntersection:")
        for _, pair in ipairs(missingHasIntersection) do
            print(pair[1], pair[2])
        end
    else
        print("No missing 3D hasIntersection found.")
    end
end

Shape3DIntersector.checkMissingIntersection()

return Shape3DIntersector

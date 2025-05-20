local tostring = tostring
local ipairs = ipairs
local require = require

---形状类型枚举
---@class foundation.shape.ShapeType
local ShapeType = {
    BEZIER_CURVE = "foundation.shape.BezierCurve",
    ELLIPSE = "foundation.shape.Ellipse",
    POLYGON = "foundation.shape.Polygon",
    SECTOR = "foundation.shape.Sector",
    RECTANGLE = "foundation.shape.Rectangle",
    TRIANGLE = "foundation.shape.Triangle",
    LINE = "foundation.shape.Line",
    RAY = "foundation.shape.Ray",
    CIRCLE = "foundation.shape.Circle",
    SEGMENT = "foundation.shape.Segment",
}

---@class foundation.shape.ShapeIntersector
local ShapeIntersector = {}

local ShapeIntersectorList = {
    "ContainPoint",
    "CircleIntersector",
    "EllipseIntersector",
    "LineIntersector",
    "PolygonIntersector",
    "RectangleIntersector",
    "SectorIntersector",
    "TriangleIntersector",
    "SegmentIntersector",
    "RayIntersector",
    "BezierCurveIntersector",
}
for _, moduleName in ipairs(ShapeIntersectorList) do
    local module = require(string.format("foundation.shape.ShapeIntersector.%s", moduleName))
    module(ShapeIntersector)
end

---整理相交点，去除重复点
---@param points foundation.math.Vector2[] 原始点列表
---@return foundation.math.Vector2[] 去重后的点列表
function ShapeIntersector.getUniquePoints(points)
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

---@type table<foundation.shape.ShapeType, table<foundation.shape.ShapeType, fun(shape1: any, shape2: any): boolean, foundation.math.Vector2[] | nil>>
local intersectionMap = {
    [ShapeType.BEZIER_CURVE] = {
        [ShapeType.BEZIER_CURVE] = ShapeIntersector.bezierCurveToBezierCurve,
        [ShapeType.POLYGON] = ShapeIntersector.bezierCurveToPolygon,
        [ShapeType.SEGMENT] = ShapeIntersector.bezierCurveToSegment,
        [ShapeType.CIRCLE] = ShapeIntersector.bezierCurveToCircle,
        [ShapeType.RECTANGLE] = ShapeIntersector.bezierCurveToRectangle,
        [ShapeType.TRIANGLE] = ShapeIntersector.bezierCurveToTriangle,
        [ShapeType.LINE] = ShapeIntersector.bezierCurveToLine,
        [ShapeType.RAY] = ShapeIntersector.bezierCurveToRay,
        [ShapeType.SECTOR] = ShapeIntersector.bezierCurveToSector,
        [ShapeType.ELLIPSE] = ShapeIntersector.bezierCurveToEllipse,
    },
    [ShapeType.ELLIPSE] = {
        [ShapeType.ELLIPSE] = ShapeIntersector.ellipseToEllipse,
        [ShapeType.POLYGON] = ShapeIntersector.ellipseToPolygon,
        [ShapeType.SEGMENT] = ShapeIntersector.ellipseToSegment,
        [ShapeType.CIRCLE] = ShapeIntersector.ellipseToCircle,
        [ShapeType.RECTANGLE] = ShapeIntersector.ellipseToRectangle,
        [ShapeType.TRIANGLE] = ShapeIntersector.ellipseToTriangle,
        [ShapeType.LINE] = ShapeIntersector.ellipseToLine,
        [ShapeType.RAY] = ShapeIntersector.ellipseToRay,
        [ShapeType.SECTOR] = ShapeIntersector.ellipseToSector,
    },
    [ShapeType.POLYGON] = {
        [ShapeType.POLYGON] = ShapeIntersector.polygonToPolygon,
        [ShapeType.TRIANGLE] = ShapeIntersector.polygonToTriangle,
        [ShapeType.RECTANGLE] = ShapeIntersector.polygonToRectangle,
        [ShapeType.CIRCLE] = ShapeIntersector.polygonToCircle,
        [ShapeType.LINE] = ShapeIntersector.polygonToLine,
        [ShapeType.RAY] = ShapeIntersector.polygonToRay,
        [ShapeType.SEGMENT] = ShapeIntersector.polygonToSegment,
        [ShapeType.SECTOR] = ShapeIntersector.polygonToSector,
    },
    [ShapeType.SECTOR] = {
        [ShapeType.SECTOR] = ShapeIntersector.sectorToSector,
        [ShapeType.RECTANGLE] = ShapeIntersector.sectorToRectangle,
        [ShapeType.TRIANGLE] = ShapeIntersector.sectorToTriangle,
        [ShapeType.CIRCLE] = ShapeIntersector.sectorToCircle,
        [ShapeType.LINE] = ShapeIntersector.sectorToLine,
        [ShapeType.RAY] = ShapeIntersector.sectorToRay,
        [ShapeType.SEGMENT] = ShapeIntersector.sectorToSegment,
    },
    [ShapeType.RECTANGLE] = {
        [ShapeType.RECTANGLE] = ShapeIntersector.rectangleToRectangle,
        [ShapeType.TRIANGLE] = ShapeIntersector.rectangleToTriangle,
        [ShapeType.CIRCLE] = ShapeIntersector.rectangleToCircle,
        [ShapeType.LINE] = ShapeIntersector.rectangleToLine,
        [ShapeType.RAY] = ShapeIntersector.rectangleToRay,
        [ShapeType.SEGMENT] = ShapeIntersector.rectangleToSegment,
    },
    [ShapeType.TRIANGLE] = {
        [ShapeType.TRIANGLE] = ShapeIntersector.triangleToTriangle,
        [ShapeType.CIRCLE] = ShapeIntersector.triangleToCircle,
        [ShapeType.LINE] = ShapeIntersector.triangleToLine,
        [ShapeType.RAY] = ShapeIntersector.triangleToRay,
        [ShapeType.SEGMENT] = ShapeIntersector.triangleToSegment,
    },
    [ShapeType.LINE] = {
        [ShapeType.LINE] = ShapeIntersector.lineToLine,
        [ShapeType.RAY] = ShapeIntersector.lineToRay,
        [ShapeType.SEGMENT] = ShapeIntersector.lineToSegment,
        [ShapeType.CIRCLE] = ShapeIntersector.lineToCircle,
    },
    [ShapeType.RAY] = {
        [ShapeType.RAY] = ShapeIntersector.rayToRay,
        [ShapeType.SEGMENT] = ShapeIntersector.rayToSegment,
        [ShapeType.CIRCLE] = ShapeIntersector.rayToCircle,
    },
    [ShapeType.CIRCLE] = {
        [ShapeType.CIRCLE] = ShapeIntersector.circleToCircle,
        [ShapeType.SEGMENT] = ShapeIntersector.circleToSegment,
    },
    [ShapeType.SEGMENT] = {
        [ShapeType.SEGMENT] = ShapeIntersector.segmentToSegment,
    },
}

---@type table<foundation.shape.ShapeType, table<foundation.shape.ShapeType, fun(shape1: any, shape2: any): boolean>>
local hasIntersectionMap = {
    [ShapeType.BEZIER_CURVE] = {
        [ShapeType.BEZIER_CURVE] = ShapeIntersector.bezierCurveHasIntersectionWithBezierCurve,
        [ShapeType.POLYGON] = ShapeIntersector.bezierCurveHasIntersectionWithPolygon,
        [ShapeType.SEGMENT] = ShapeIntersector.bezierCurveHasIntersectionWithSegment,
        [ShapeType.CIRCLE] = ShapeIntersector.bezierCurveHasIntersectionWithCircle,
        [ShapeType.RECTANGLE] = ShapeIntersector.bezierCurveHasIntersectionWithRectangle,
        [ShapeType.TRIANGLE] = ShapeIntersector.bezierCurveHasIntersectionWithTriangle,
        [ShapeType.LINE] = ShapeIntersector.bezierCurveHasIntersectionWithLine,
        [ShapeType.RAY] = ShapeIntersector.bezierCurveHasIntersectionWithRay,
        [ShapeType.SECTOR] = ShapeIntersector.bezierCurveHasIntersectionWithSector,
        [ShapeType.ELLIPSE] = ShapeIntersector.bezierCurveHasIntersectionWithEllipse,
    },
    [ShapeType.ELLIPSE] = {
        [ShapeType.ELLIPSE] = ShapeIntersector.ellipseHasIntersectionWithEllipse,
        [ShapeType.POLYGON] = ShapeIntersector.ellipseHasIntersectionWithPolygon,
        [ShapeType.SEGMENT] = ShapeIntersector.ellipseHasIntersectionWithSegment,
        [ShapeType.CIRCLE] = ShapeIntersector.ellipseHasIntersectionWithCircle,
        [ShapeType.RECTANGLE] = ShapeIntersector.ellipseHasIntersectionWithRectangle,
        [ShapeType.TRIANGLE] = ShapeIntersector.ellipseHasIntersectionWithTriangle,
        [ShapeType.LINE] = ShapeIntersector.ellipseHasIntersectionWithLine,
        [ShapeType.RAY] = ShapeIntersector.ellipseHasIntersectionWithRay,
        [ShapeType.SECTOR] = ShapeIntersector.ellipseHasIntersectionWithSector,
    },
    [ShapeType.POLYGON] = {
        [ShapeType.POLYGON] = ShapeIntersector.polygonHasIntersectionWithPolygon,
        [ShapeType.TRIANGLE] = ShapeIntersector.polygonHasIntersectionWithTriangle,
        [ShapeType.RECTANGLE] = ShapeIntersector.polygonHasIntersectionWithRectangle,
        [ShapeType.CIRCLE] = ShapeIntersector.polygonHasIntersectionWithCircle,
        [ShapeType.LINE] = ShapeIntersector.polygonHasIntersectionWithLine,
        [ShapeType.RAY] = ShapeIntersector.polygonHasIntersectionWithRay,
        [ShapeType.SEGMENT] = ShapeIntersector.polygonHasIntersectionWithSegment,
        [ShapeType.SECTOR] = ShapeIntersector.polygonHasIntersectionWithSector,
    },
    [ShapeType.SECTOR] = {
        [ShapeType.SECTOR] = ShapeIntersector.sectorHasIntersectionWithSector,
        [ShapeType.RECTANGLE] = ShapeIntersector.sectorHasIntersectionWithRectangle,
        [ShapeType.TRIANGLE] = ShapeIntersector.sectorHasIntersectionWithTriangle,
        [ShapeType.CIRCLE] = ShapeIntersector.sectorHasIntersectionWithCircle,
        [ShapeType.LINE] = ShapeIntersector.sectorHasIntersectionWithLine,
        [ShapeType.RAY] = ShapeIntersector.sectorHasIntersectionWithRay,
        [ShapeType.SEGMENT] = ShapeIntersector.sectorHasIntersectionWithSegment,
    },
    [ShapeType.RECTANGLE] = {
        [ShapeType.RECTANGLE] = ShapeIntersector.rectangleHasIntersectionWithRectangle,
        [ShapeType.TRIANGLE] = ShapeIntersector.rectangleHasIntersectionWithTriangle,
        [ShapeType.CIRCLE] = ShapeIntersector.rectangleHasIntersectionWithCircle,
        [ShapeType.LINE] = ShapeIntersector.rectangleHasIntersectionWithLine,
        [ShapeType.RAY] = ShapeIntersector.rectangleHasIntersectionWithRay,
        [ShapeType.SEGMENT] = ShapeIntersector.rectangleHasIntersectionWithSegment,
    },
    [ShapeType.TRIANGLE] = {
        [ShapeType.TRIANGLE] = ShapeIntersector.triangleHasIntersectionWithTriangle,
        [ShapeType.CIRCLE] = ShapeIntersector.triangleHasIntersectionWithCircle,
        [ShapeType.LINE] = ShapeIntersector.triangleHasIntersectionWithLine,
        [ShapeType.RAY] = ShapeIntersector.triangleHasIntersectionWithRay,
        [ShapeType.SEGMENT] = ShapeIntersector.triangleHasIntersectionWithSegment,
    },
    [ShapeType.LINE] = {
        [ShapeType.LINE] = ShapeIntersector.lineHasIntersectionWithLine,
        [ShapeType.RAY] = ShapeIntersector.lineHasIntersectionWithRay,
        [ShapeType.SEGMENT] = ShapeIntersector.lineHasIntersectionWithSegment,
        [ShapeType.CIRCLE] = ShapeIntersector.lineHasIntersectionWithCircle,
    },
    [ShapeType.RAY] = {
        [ShapeType.RAY] = ShapeIntersector.rayHasIntersectionWithRay,
        [ShapeType.SEGMENT] = ShapeIntersector.rayHasIntersectionWithSegment,
        [ShapeType.CIRCLE] = ShapeIntersector.rayHasIntersectionWithCircle,
    },
    [ShapeType.CIRCLE] = {
        [ShapeType.CIRCLE] = ShapeIntersector.circleHasIntersectionWithCircle,
        [ShapeType.SEGMENT] = ShapeIntersector.circleHasIntersectionWithSegment,
    },
    [ShapeType.SEGMENT] = {
        [ShapeType.SEGMENT] = ShapeIntersector.segmentHasIntersectionWithSegment,
    },
}

---检查与其他形状的相交
---@param shape1 any 第一个形状
---@param shape2 any 第二个形状
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.intersect(shape1, shape2)
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

---只检查是否与其他形状相交
---@param shape1 any 第一个形状
---@param shape2 any 第二个形状
---@return boolean
function ShapeIntersector.hasIntersection(shape1, shape2)
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

function ShapeIntersector.checkMissingIntersection()
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
        print("Missing intersections:")
        for _, pair in ipairs(missing) do
            print(pair[1], pair[2])
        end
    else
        print("No missing intersections found.")
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
        print("Missing hasIntersection:")
        for _, pair in ipairs(missingHasIntersection) do
            print(pair[1], pair[2])
        end
    else
        print("No missing hasIntersection found.")
    end
end

ShapeIntersector.checkMissingIntersection()

return ShapeIntersector

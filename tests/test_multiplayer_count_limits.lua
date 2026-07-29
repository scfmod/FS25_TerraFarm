local testFilename = debug.getinfo(1, 'S').source:sub(2)
local projectDirectory = testFilename:match('^(.*)/tests/[^/]+$')

if projectDirectory == nil and testFilename:match('^tests/[^/]+$') then
    projectDirectory = '.'
end

if projectDirectory == nil then
    error('Run this test from a file inside the tests directory.')
end

local function loadProjectFile(filename)
    local path = projectDirectory .. '/' .. filename
    local file = assert(io.open(path, 'r'))
    local contents = file:read('*a')
    file:close()

    contents = contents:gsub(
        '([%w_%.%[%]]+)%s*([%+%-%*/])=%s*([^\r\n]+)',
        function (name, operator, value)
            return string.format('%s = %s %s %s', name, name, operator, value)
        end
    )
    contents = contents:gsub('([ \t]*)continue([ \t]*)(\r?\n)', '%1-- continue%2%3')
    contents = contents:gsub(
        'g_landscapingManager = LandscapingManager%.new%(%)[\r\n]+g_landscapingManager:loadShapes%(%)',
        ''
    )

    assert(load(contents, '@' .. path))()
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format('%s: expected %s, got %s', message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertFails(callback, message)
    local success = pcall(callback)

    if success then
        error(message, 2)
    end
end

local function makeList(count, factory)
    local result = {}

    for i = 1, count do
        result[i] = factory ~= nil and factory(i) or {}
    end

    return result
end

local function makeCollection(count)
    local result = {}

    for i = 1, count do
        result[string.format('item_%d', i)] = {}
    end

    return result
end

g_modDirectory = projectDirectory .. '/'
g_i18n = {
    getText = function (_, key)
        return key
    end
}

XMLValueType = {
    BOOL = 1,
    FLOAT = 2,
    INT = 3,
    STRING = 4,
    VECTOR_3 = 5,
}

XMLSchema = {
    new = function ()
        return {
            register = function ()
            end
        }
    end
}

Event = {}

function Event.new(mt)
    return setmetatable({}, mt)
end

function Class(classTable)
    return { __index = classTable }
end

function InitEventClass()
end

function source()
end

Logging = {
    xmlErrors = 0,
    xmlError = function ()
        Logging.xmlErrors = Logging.xmlErrors + 1
    end,
    error = function ()
    end,
    warning = function ()
    end,
}

ModUtils = {}
AreaEditor = {}
ScreenElement = {}
EditorDirection = {
    NEGATIVE = -1,
    POSITIVE = 1,
}

loadProjectFile('scripts/landscaping/LandscapingArea.lua')
loadProjectFile('scripts/landscaping/LandscapingAreaPolygon.lua')
loadProjectFile('scripts/landscaping/LandscapingAreaPath.lua')
loadProjectFile('scripts/landscaping/LandscapingWaterplane.lua')
loadProjectFile('scripts/landscaping/LandscapingManager.lua')
loadProjectFile('scripts/events/SetLandscapingAreasEvent.lua')
loadProjectFile('scripts/events/SetWaterplanesEvent.lua')
loadProjectFile('scripts/gui/editor/Editor.lua')
loadProjectFile('scripts/gui/editor/PolygonEditor.lua')
loadProjectFile('scripts/gui/editor/PathEditor.lua')

local areaSuperClass = {
    loadFromXMLFile = function ()
        return true
    end,
    writeStream = function ()
    end,
}

LandscapingAreaPolygon.superClass = function ()
    return areaSuperClass
end

LandscapingAreaPath.superClass = function ()
    return areaSuperClass
end

local maxPoints = LandscapingAreaPolygon.MAX_NUM_POINTS
local maxAreas = LandscapingArea.MAX_NUM_AREAS
local maxWaterplanes = LandscapingWaterplane.MAX_NUM_PLANES

assertEqual(
    LandscapingAreaPolygon.getCanAddPoint({ points = makeList(maxPoints - 1) }),
    true,
    'A polygon rejected its last encodable point'
)
assertEqual(
    LandscapingAreaPolygon.getCanAddPoint({ points = makeList(maxPoints) }),
    false,
    'A polygon allowed a point beyond the wire limit'
)
assertEqual(
    LandscapingAreaPath.getCanAddPoint({ points = makeList(maxPoints) }),
    false,
    'A path allowed a point beyond the wire limit'
)
assertEqual(
    LandscapingWaterplane.getCanAddPoint({ points = makeList(maxPoints) }),
    false,
    'A waterplane allowed a point beyond the wire limit'
)

assertEqual(
    LandscapingManager.getCanCreateArea({ areas = makeCollection(maxAreas - 1) }),
    true,
    'The manager rejected its last encodable landscaping area'
)
assertEqual(
    LandscapingManager.getCanCreateArea({ areas = makeCollection(maxAreas) }),
    false,
    'The manager allowed a landscaping area beyond the wire limit'
)
assertEqual(
    LandscapingManager.getCanCreateWaterplane({ waterplanes = makeCollection(maxWaterplanes - 1) }),
    true,
    'The manager rejected its last encodable waterplane'
)
assertEqual(
    LandscapingManager.getCanCreateWaterplane({ waterplanes = makeCollection(maxWaterplanes) }),
    false,
    'The manager allowed a waterplane beyond the wire limit'
)

local fullManager = {
    areas = makeCollection(maxAreas),
    waterplanes = makeCollection(maxWaterplanes),
    getCanCreateArea = LandscapingManager.getCanCreateArea,
    getCanCreateWaterplane = LandscapingManager.getCanCreateWaterplane,
}

LandscapingManager.registerArea(fullManager, { uniqueId = 'extra_area' }, true)
assertEqual(fullManager.areas.extra_area, nil, 'The manager registered an unencodable landscaping area')

LandscapingManager.registerWaterplane(fullManager, { uniqueId = 'extra_waterplane' }, true)
assertEqual(fullManager.waterplanes.extra_waterplane, nil, 'The manager registered an unencodable waterplane')

local function makeEditor(points, limit)
    return {
        points = points,
        numPointsLimit = limit,
        placementDirection = EditorDirection.POSITIVE,
        getTargetPos = function ()
            return { 1, 2, 3 }
        end,
        getTargetY = function ()
            return 2
        end,
        updateBorder = function ()
        end,
        setHasChanged = function ()
        end,
        setSelectedIndex = function ()
        end,
    }
end

local polygonEditor = makeEditor(makeList(maxPoints), maxPoints)
assertEqual(PolygonEditor.createPoint(polygonEditor), false, 'The polygon editor inserted an unencodable point')
assertEqual(#polygonEditor.points, maxPoints, 'The polygon editor changed a full point list')

local pathEditor = makeEditor(makeList(maxPoints), maxPoints)
PathEditor.createPoint(pathEditor)
assertEqual(#pathEditor.points, maxPoints, 'The path editor inserted an unencodable point')

local polygonSplitEditor = makeEditor(makeList(maxPoints), maxPoints)
polygonSplitEditor.selectedIndex = 2
PolygonEditor.splitSelectedSegment(polygonSplitEditor)
assertEqual(#polygonSplitEditor.points, maxPoints, 'The polygon editor split beyond the wire limit')

local pathSplitEditor = makeEditor(makeList(maxPoints), maxPoints)
pathSplitEditor.selectedIndex = 2
Editor.splitSelectedSegment(pathSplitEditor)
assertEqual(#pathSplitEditor.points, maxPoints, 'The path editor split beyond the wire limit')

local function makeXMLFile(pointCount)
    return {
        getValue = function (_, path, default)
            if path:find('#uniqueId', 1, true) ~= nil then
                return 'test_waterplane'
            elseif path:find('#targetY', 1, true) ~= nil then
                return 2
            elseif path:find('#position', 1, true) ~= nil then
                return 1, 0, 1
            end

            return default
        end,
        iterator = function ()
            local index = 0

            return function ()
                index = index + 1

                if index <= pointCount then
                    return index, string.format('area.points.point(%d)', index - 1)
                end
            end
        end,
    }
end

local function verifyXMLPointLimit(loader, label)
    Logging.xmlErrors = 0

    local validObject = {
        points = {},
        superClass = function ()
            return areaSuperClass
        end,
    }
    assertEqual(loader(validObject, makeXMLFile(maxPoints), 'area'), true, label .. ' rejected the maximum point count')
    assertEqual(#validObject.points, maxPoints, label .. ' did not load the maximum point count')

    local oversizedObject = {
        points = {},
        superClass = function ()
            return areaSuperClass
        end,
    }
    assertEqual(loader(oversizedObject, makeXMLFile(maxPoints + 1), 'area'), false, label .. ' accepted too many XML points')
    assertEqual(Logging.xmlErrors, 1, label .. ' did not report the oversized XML record')
end

verifyXMLPointLimit(LandscapingAreaPolygon.loadFromXMLFile, 'Polygon XML loading')
verifyXMLPointLimit(LandscapingAreaPath.loadFromXMLFile, 'Path XML loading')
verifyXMLPointLimit(LandscapingWaterplane.loadFromXMLFile, 'Waterplane XML loading')

local streamCounts = {}
local positionWrites = 0

streamWriteUIntN = function (_, value, bits)
    table.insert(streamCounts, { value = value, bits = bits })
end
streamWriteFloat32 = function ()
end
streamWriteString = function ()
end
streamWriteBool = function ()
end
streamWriteUInt8 = function ()
end
ModUtils.writeCompressedXYZPos = function ()
    positionWrites = positionWrites + 1
end

local function resetStream()
    streamCounts = {}
    positionWrites = 0
end

local function verifyPointWriter(writer, object, label)
    object.superClass = function ()
        return areaSuperClass
    end
    object.points = makeList(maxPoints + 1, function ()
        return { 1, 2, 3 }
    end)

    resetStream()
    assertFails(function ()
        writer(object, 0, {})
    end, label .. ' serialized too many points')
    assertEqual(#streamCounts, 0, label .. ' wrote part of an oversized record')

    object.points = makeList(maxPoints, function ()
        return { 1, 2, 3 }
    end)

    resetStream()
    writer(object, 0, {})
    assertEqual(streamCounts[1].value, maxPoints, label .. ' wrote the wrong point count')
    assertEqual(positionWrites, maxPoints, label .. ' did not preserve the maximum valid point list')
end

verifyPointWriter(
    LandscapingAreaPolygon.writeStream,
    { targetY = 2 },
    'Polygon network serialization'
)
verifyPointWriter(
    LandscapingAreaPath.writeStream,
    { width = 4 },
    'Path network serialization'
)
verifyPointWriter(
    LandscapingWaterplane.writeStream,
    { name = 'Water', visible = true, color = 1, targetY = 2 },
    'Waterplane network serialization'
)

local function makeAreas(count)
    return makeList(count, function (index)
        return {
            className = 'LandscapingAreaPolygon',
            uniqueId = string.format('area_%d', index),
            writeStream = function ()
            end,
        }
    end)
end

local function makeWaterplanes(count)
    return makeList(count, function (index)
        return {
            uniqueId = string.format('waterplane_%d', index),
            writeStream = function ()
            end,
        }
    end)
end

local function verifyCollectionWriter(writer, getterName, maxCount, factory, label)
    local values = factory(maxCount + 1)
    g_landscapingManager = {
        [getterName] = function ()
            return values
        end
    }

    resetStream()
    assertFails(function ()
        writer({}, 0, {})
    end, label .. ' serialized too many records')
    assertEqual(#streamCounts, 0, label .. ' wrote part of an oversized collection')

    values = factory(maxCount)
    resetStream()
    writer({}, 0, {})
    assertEqual(streamCounts[1].value, maxCount, label .. ' did not preserve the maximum valid collection')
end

verifyCollectionWriter(
    SetLandscapingAreasEvent.writeStream,
    'getAreas',
    maxAreas,
    makeAreas,
    'Landscaping-area snapshot'
)
verifyCollectionWriter(
    SetWaterplanesEvent.writeStream,
    'getWaterplanes',
    maxWaterplanes,
    makeWaterplanes,
    'Waterplane snapshot'
)

print('All multiplayer count-limit checks passed.')

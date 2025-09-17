---@class Shape
---@field type ShapeType
---@field node number
---@field scale number
---@field alpha number
---@field color [number, number, number, number]
---@field emission number
Shape = {}

---@enum ShapeType
Shape.TYPE = {
    ARROW = 0,
    LINE = 2,
    MARKER = 3
}

---@type table<ShapeType, string>
Shape.SHAPE_FILENAME = {
    [Shape.TYPE.ARROW] = g_modDirectory .. 'objects/arrow.i3d',
    [Shape.TYPE.LINE] = g_modDirectory .. 'objects/shapes/lineShape.i3d',
    [Shape.TYPE.MARKER] = g_modDirectory .. 'objects/shapes/markerShape.i3d',
}

local Shape_mt = Class(Shape)

---@param type ShapeType
---@param customMt any
---@return Shape
function Shape.new(type, customMt)
    ---@type Shape
    local self = setmetatable({}, customMt or Shape_mt)

    self.type = type
    self.scale = 1.0
    self.emission = 1.0
    self.color = { 1, 1, 1, 1 }

    self:load()

    return self
end

---@param x number
---@param y number
---@param z number
function Shape:setPosition(x, y, z)
    setTranslation(self.node, x, y, z)
end

---@param castShadow boolean
function Shape:setCastShadow(castShadow)
    if getHasClassId(self.node, ClassIds.SHAPE) then
        setShapeCastShadowmap(self.node, castShadow)
    end
end

---@param alpha number
function Shape:setAlpha(alpha)
    self.alpha = alpha

    setShaderParameter(self.node, 'alpha', alpha, 0, 0, 0, false)
end

---@param visible boolean
function Shape:setIsVisible(visible)
    setVisibility(self.node, visible)
end

---@param scale number
function Shape:setScale(scale)
    self.scale = scale

    setScale(self.node, scale, scale, scale)
end

---@param r number
---@param g number
---@param b number
---@param a number|nil
function Shape:setColor(r, g, b, a)
    a = a or self.color[4]

    self.color = { r, g, b, a }

    setShaderParameter(self.node, "color", r, g, b, a, false)
end

---@param value number
function Shape:setEmission(value)
    self.emission = value

    setShaderParameter(self.node, "emission", value, 0, 0, 0, false)
end

function Shape:load()
    local rootNode = g_i3DManager:loadSharedI3DFile(Shape.SHAPE_FILENAME[self.type], false, false)

    ---@diagnostic disable-next-line: assign-type-mismatch
    self.node = getChildAt(rootNode, 0)

    link(getRootNode(), self.node)
    setTranslation(self.node, 0, 0, 0)
    delete(rootNode)
end

---@param sx number
---@param sy number
---@param sz number
---@param ex number
---@param ey number
---@param ez number
function Shape.getWorldDirection(sx, sy, sz, ex, ey, ez)
    local wdx, wdy, wdz = ex - sx, ey - sy, ez - sz
    local dist = MathUtil.vector3Length(wdx, wdy, wdz)

    if dist and dist > 0.01 then
        wdx, wdy, wdz = wdx / dist, wdy / dist, wdz / dist
        return wdx, wdy, wdz, dist
    end

    return 0, 0, 0, 0
end

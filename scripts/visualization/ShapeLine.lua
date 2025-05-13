---@class LineShape : Shape
LineShape = {}

local LineShape_mt = Class(LineShape, Shape)

---@return LineShape
function LineShape.new()
    local self = Shape.new(Shape.TYPE.LINE, LineShape_mt)
    ---@cast self LineShape

    return self
end

---@param sx number
---@param sy number
---@param sz number
---@param ex number
---@param ey number
---@param ez number
function LineShape:setPosition(sx, sy, sz, ex, ey, ez)
    local dirX, _, dirZ, distToNextPoint = Shape.getWorldDirection(sx, sy, sz, ex, ey, ez)
    local rotY = math.atan2(dirX, dirZ)
    local dy = ey - sy
    local dist2D = MathUtil.vector2Length(ex - sx, ez - sz)
    local rotX = -math.atan2(dy, dist2D)

    setTranslation(self.node, sx, sy, sz)
    setScale(self.node, self.scale, 1, distToNextPoint)
    setRotation(self.node, rotX, rotY, 0)
end

---@param scale number
function LineShape:setScale(scale)
    self.scale = scale

    local _, _, z = getScale(self.node)
    setScale(self.node, scale, 1, z)
end

---@param alpha number
function LineShape:setAlpha(alpha)
    -- void
end

---@param r number
---@param g number
---@param b number
---@param a number|nil
function LineShape:setColor(r, g, b, a)
    a = a or self.color[4]

    self.color = { r, g, b, a }

    setShaderParameter(self.node, "lineColor", r, g, b, a, false)
end

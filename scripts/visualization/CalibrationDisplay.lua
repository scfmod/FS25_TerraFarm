---@class CalibrationDisplay
---@field enabled boolean
---@field targetMarker Shape
---@field targetLine LineShape
---@field sourceMarker Shape
---@field sourceLine LineShape
---@field line LineShape
CalibrationDisplay = {}

local CalibrationDisplay_mt = Class(CalibrationDisplay)

function CalibrationDisplay.new()
    ---@type CalibrationDisplay
    local self = setmetatable({}, CalibrationDisplay_mt)

    self.enabled = false

    self.sourceMarker = Shape.new(Shape.TYPE.MARKER)
    self.sourceLine = LineShape.new()
    self.sourceLine:setScale(2)

    self.targetMarker = Shape.new(Shape.TYPE.MARKER)
    self.targetLine = LineShape.new()
    self.targetLine:setScale(2)

    self.line = LineShape.new()
    self.line:setScale(4)

    -- self:setColor(0.1, 0.3, 1.0)

    return self
end

---@param r number
---@param g number
---@param b number
---@param a number|nil
function CalibrationDisplay:setColor(r, g, b, a)
    self.targetMarker:setColor(r, g, b, a)
    self.sourceMarker:setColor(r, g, b, a)
    self.line:setColor(r, g, b)
end

---@param sourceX number
---@param sourceY number
---@param sourceZ number
---@param sourceOffset number
---@param targetX number
---@param targetY number
---@param targetZ number
---@param targetOffset number
function CalibrationDisplay:update(sourceX, sourceY, sourceZ, sourceOffset, targetX, targetY, targetZ, targetOffset)
    if not self.enabled then
        return
    end

    if sourceY ~= math.huge then
        local sourceTerrainHeight = MachineUtils.getTerrainHeightAtPosition(sourceX, sourceZ)
        local sourceTerrainDiff = sourceY + sourceOffset - sourceTerrainHeight

        self.sourceMarker:setIsVisible(true)

        if sourceTerrainDiff < 0 then
            self.sourceMarker:setPosition(sourceX, sourceTerrainHeight, sourceZ)
            self.sourceLine:setIsVisible(false)

            -- TODO: render rext (optional)
        else
            self.sourceMarker:setPosition(sourceX, sourceY + sourceOffset, sourceZ)
            self.sourceLine:setPosition(sourceX, sourceTerrainHeight, sourceZ, sourceX, sourceY + sourceOffset, sourceZ)
            self.sourceLine:setIsVisible(true)
        end
    else
        self.sourceMarker:setIsVisible(false)
        self.sourceLine:setIsVisible(false)
    end

    if targetY ~= math.huge then
        local targetTerrainHeight = MachineUtils.getTerrainHeightAtPosition(targetX, targetZ)
        local targetTerrainDiff = targetY + targetOffset - targetTerrainHeight

        self.line:setPosition(sourceX, sourceY + sourceOffset, sourceZ, targetX, targetY + targetOffset, targetZ)
        self.line:setIsVisible(true)

        self.targetMarker:setIsVisible(true)

        if targetTerrainDiff < 0 then
            self.targetMarker:setPosition(targetX, targetTerrainHeight, targetZ)
            self.targetLine:setIsVisible(false)

            -- TODO: render text (optional)
        else
            self.targetMarker:setPosition(targetX, targetY + targetOffset, targetZ)
            self.targetLine:setPosition(targetX, targetTerrainHeight, targetZ, targetX, targetY + targetOffset, targetZ)
            self.targetLine:setIsVisible(true)
        end
    else
        self.line:setIsVisible(false)
        self.targetMarker:setIsVisible(false)
        self.targetLine:setIsVisible(false)
    end
end

function CalibrationDisplay:setIsEnabled(enabled)
    if self.enabled ~= enabled then
        self.enabled = enabled

        if not enabled then
            self.sourceMarker:setIsVisible(false)
            self.sourceLine:setIsVisible(false)
            self.targetMarker:setIsVisible(false)
            self.targetLine:setIsVisible(false)
            self.line:setIsVisible(false)
        end
    end
end

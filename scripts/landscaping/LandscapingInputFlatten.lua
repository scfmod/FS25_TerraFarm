---@class LandscapingInputFlatten : LandscapingInput
---@field targetY number
LandscapingInputFlatten = {}

local LandscapingInputFlatten_mt = Class(LandscapingInputFlatten, LandscapingInput)

---@param workArea MachineWorkArea
---@param terrainLayerId? number
---@param fillTypeIndex? number
---@param targetY number
---@return LandscapingInputFlatten
---@nodiscard
function LandscapingInputFlatten.new(workArea, terrainLayerId, fillTypeIndex, targetY)
    local self = LandscapingInput.new(LandscapingOperation.FLATTEN, workArea, terrainLayerId, fillTypeIndex, LandscapingInputFlatten_mt)
    ---@cast self LandscapingInputFlatten

    self.targetY = targetY
    self.heightChangeAmount = 0.75

    self:checkMapResources()

    return self
end

local OUTER_ANGLE = math.rad(75)

function LandscapingInputFlatten:apply()
    local deformation          = self:createTerrainDeformation()
    local paintDeformation     = self:createPaintDeformation()

    local state                = self.state
    local allowGradingUp       = state.allowGradingUp
    local forceNodes           = state.forceNodes
    local densityModifier      = state.densityModifier
    local paintModifier        = state.paintModifier

    local radius               = self.radius
    local densityRadius        = radius * densityModifier
    local paintRadius          = radius * paintModifier

    local squareSize           = radius * 2
    local densitySquareSize    = densityRadius * 2
    local paintSquareSize      = paintRadius * 2

    local workArea             = self.workArea
    local areaNodePosition     = workArea.areaNodePosition
    local areaNodeActive       = workArea.areaNodeActive
    local areaNodeTerrainY     = workArea.areaNodeTerrainY

    local modifiedAreas        = self.modifiedAreas
    local densityModifiedAreas = self.densityModifiedAreas

    local targetY              = self.targetY
    local hardness             = self.hardness
    local strength             = self.strength
    local terrainLayerId       = self.terrainLayerId

    local isCircle             = (self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE)
    local hasPaint             = (paintDeformation ~= nil)

    if isCircle then
        if hasPaint then
            for node, position in next, areaNodePosition do
                if forceNodes or areaNodeActive[node] then
                    local px = position[1]
                    local pz = position[3]

                    if allowGradingUp or areaNodeTerrainY[node] >= targetY then
                        deformation:addSoftCircleBrush(px, pz, radius, hardness, strength, -1)
                        LandscapingUtils.addModifiedCircleArea(modifiedAreas, px, pz, radius)
                    end

                    LandscapingUtils.addModifiedCircleArea(densityModifiedAreas, px, pz, densityRadius)
                    ---@diagnostic disable-next-line: need-check-nil
                    paintDeformation:addSoftCircleBrush(px, pz, paintRadius, 0.2, 0.5, terrainLayerId)
                end
            end
        else
            for node, position in next, areaNodePosition do
                if forceNodes or areaNodeActive[node] then
                    local px = position[1]
                    local pz = position[3]

                    if allowGradingUp or areaNodeTerrainY[node] >= targetY then
                        deformation:addSoftCircleBrush(px, pz, radius, hardness, strength, -1)
                        LandscapingUtils.addModifiedCircleArea(modifiedAreas, px, pz, radius)
                    end

                    LandscapingUtils.addModifiedCircleArea(densityModifiedAreas, px, pz, densityRadius)
                end
            end
        end
    else
        if hasPaint then
            for node, position in next, areaNodePosition do
                if forceNodes or areaNodeActive[node] then
                    local px = position[1]
                    local pz = position[3]

                    if allowGradingUp or areaNodeTerrainY[node] >= targetY then
                        deformation:addSoftSquareBrush(px, pz, squareSize, hardness, strength, -1)
                        LandscapingUtils.addModifiedSquareArea(modifiedAreas, px, pz, squareSize)
                    end

                    LandscapingUtils.addModifiedSquareArea(densityModifiedAreas, px, pz, densitySquareSize)
                    ---@diagnostic disable-next-line: need-check-nil
                    paintDeformation:addSoftSquareBrush(px, pz, paintSquareSize, 0.2, 0.5, terrainLayerId)
                end
            end
        else
            for node, position in next, areaNodePosition do
                if forceNodes or areaNodeActive[node] then
                    local px = position[1]
                    local pz = position[3]

                    if allowGradingUp or areaNodeTerrainY[node] >= targetY then
                        deformation:addSoftSquareBrush(px, pz, squareSize, hardness, strength, -1)
                        LandscapingUtils.addModifiedSquareArea(modifiedAreas, px, pz, squareSize)
                    end

                    LandscapingUtils.addModifiedSquareArea(densityModifiedAreas, px, pz, densitySquareSize)
                end
            end
        end
    end

    if #modifiedAreas == 0 then
        deformation:cancel()
        return
    end

    deformation:setOutsideAreaConstraints(0, OUTER_ANGLE, OUTER_ANGLE)
    deformation:setBlockedAreaMaxDisplacement(0.01)
    deformation:setDynamicObjectCollisionMask(0)
    deformation:setDynamicObjectMaxDisplacement(0.01)

    deformation:apply(false, "onDeformationCallback", self)
end

---@return TerrainDeformation
---@nodiscard
function LandscapingInputFlatten:createTerrainDeformation()
    self.deformation = TerrainDeformation.new(g_terrainNode)

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:setHeightTarget(self.targetY, self.targetY, 0, 1, 0, -self.targetY)
    self.deformation:enableSetDeformationMode()

    return self.deformation
end

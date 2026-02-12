---@class LandscapingInput : MachineLandscaping
---@field yield number
LandscapingInput = {}

local LandscapingInput_mt = Class(LandscapingInput, MachineLandscaping)

---@param operation LandscapingOperation
---@param workArea MachineWorkArea
---@param mt table
---@return LandscapingInput
---@nodiscard
function LandscapingInput.new(operation, workArea, mt)
    local self = MachineLandscaping.new(operation, workArea, mt)
    ---@cast self LandscapingInput

    self.radius = self.state.inputRadius
    self.strength = self.state.inputStrength
    self.hardness = self.state.inputHardness
    self.brushShape = self.state.inputBrushShape

    self.terrainLayerId = self.vehicle:getMachineInputLayerId()
    self.yield = self.state.inputRatio

    return self
end

function LandscapingInput:apply()
    local deformation = self:createTerrainDeformation()
    local paintDeformation = self:createPaintDeformation()

    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for node, position in pairs(self.workArea.areaNodePosition) do
            if self.workArea.areaNodeActive[node] then
                deformation:addSoftCircleBrush(position[1], position[3], self.radius, self.hardness, self.strength, -1)
                MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], self.radius)
                MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)

                if paintDeformation ~= nil then
                    paintDeformation:addSoftCircleBrush(position[1], position[3], paintRadius, 0.2, 0.5, self.terrainLayerId)
                end
            end
        end
    else
        for node, position in pairs(self.workArea.areaNodePosition) do
            if self.workArea.areaNodeActive[node] then
                deformation:addSoftSquareBrush(position[1], position[3], self.radius * 2, self.hardness, self.strength, -1)
                MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], self.radius * 2)
                MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)

                if paintDeformation ~= nil then
                    paintDeformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, 0.2, 0.5, self.terrainLayerId)
                end
            end
        end
    end

    if #self.modifiedAreas == 0 then
        deformation:delete()
        return
    end

    deformation:setOutsideAreaConstraints(0, math.rad(75), math.rad(75))
    deformation:setBlockedAreaMaxDisplacement(0)
    deformation:setDynamicObjectCollisionMask(0)
    deformation:setDynamicObjectMaxDisplacement(0)

    deformation:apply(false, 'onDeformationCallback', self)
end

function LandscapingInput:applyMapResources()
    local worldPosX, _, worldPosZ = getWorldTranslation(self.workArea.rootNode)
    local layer = g_resourceManager:getResourceLayerAtWorldPos(worldPosX, worldPosZ)

    if layer ~= nil then
        self.terrainLayerId = g_resourceManager:getResourcePaintLayerId(layer, false)

        local fillType = g_fillTypeManager:getFillTypeByName(layer.fillTypeName)

        if fillType ~= nil then
            self.fillType = fillType
        end

        self.yield = layer.yield
    end
end

---@param volume number
function LandscapingInput:onDeformationSuccess(volume)
    self:applyDeformationChanges()

    if self.state.enableInputMaterial and self.fillType ~= nil and volume > 0 then
        local liters = MachineUtils.volumeToFillTypeLiters(volume, self.fillType.index)
        self.vehicle:handleDeformationInput(liters, self.fillType.index)
    end
end

---@return TerrainDeformation?
---@nodiscard
function LandscapingInput:createPaintDeformation()
    if self.state.enableInputGroundTexture then
        self.paintDeformation = TerrainDeformation.new(g_terrainNode)
        self.paintDeformation:enablePaintingMode()

        return self.paintDeformation
    end
end

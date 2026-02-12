---@enum DrivingDirectionMode
DrivingDirectionMode = {
    FORWARDS = 1,
    BACKWARDS = 2,
    BOTH = 3,
    IGNORE = 4
}

---@class MachineState
---@field enableEffects boolean
---@field autoDeactivate boolean
---@field drivingDirectionMode DrivingDirectionMode
---
---@field inputRadius number
---@field inputStrength number
---@field inputHardness number
---@field inputBrushShape number
---@field inputRatio number
---@field enableInputMaterial boolean
---@field enableInputGroundTexture boolean
---
---@field outputRadius number
---@field outputStrength number
---@field outputHardness number
---@field outputBrushShape number
---@field outputRatio number
---@field enableOutputMaterial boolean
---@field enableOutputGroundTexture boolean
---
---@field paintModifier number
---@field densityModifier number
---
---@field clearDecoArea boolean
---@field clearDensityMapHeightArea boolean
---@field eraseTireTracks boolean
---@field removeFieldArea boolean
---@field removeStoneArea boolean
---@field removeWeedArea boolean
---
--- EXPERIMENTAL
---@field allowGradingUp boolean
---@field forceNodes boolean
MachineState = {}

MachineState.SEND_NUM_BITS_DIRECTION_MODE = 3

local MachineState_mt = Class(MachineState)

---@param schema XMLSchema
---@param key string
function MachineState.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.BOOL, key .. '#enableEffects')

    schema:register(XMLValueType.FLOAT, key .. '#inputStrength')
    schema:register(XMLValueType.FLOAT, key .. '#inputRadius')
    schema:register(XMLValueType.FLOAT, key .. '#inputHardness')
    schema:register(XMLValueType.INT, key .. '#inputBrushShape')
    schema:register(XMLValueType.BOOL, key .. '#enableInputMaterial')
    schema:register(XMLValueType.BOOL, key .. '#enableInputGroundTexture')
    schema:register(XMLValueType.FLOAT, key .. '#inputRatio')

    schema:register(XMLValueType.FLOAT, key .. '#outputStrength')
    schema:register(XMLValueType.FLOAT, key .. '#outputRadius')
    schema:register(XMLValueType.FLOAT, key .. '#outputHardness')
    schema:register(XMLValueType.INT, key .. '#outputBrushShape')
    schema:register(XMLValueType.BOOL, key .. '#enableOutputMaterial')
    schema:register(XMLValueType.BOOL, key .. '#enableOutputGroundTexture')
    schema:register(XMLValueType.FLOAT, key .. '#outputRatio')

    schema:register(XMLValueType.BOOL, key .. '#clearDecoArea')
    schema:register(XMLValueType.BOOL, key .. '#clearDensityMapHeightArea')
    schema:register(XMLValueType.BOOL, key .. '#eraseTireTracks')
    schema:register(XMLValueType.BOOL, key .. '#removeFieldArea')
    schema:register(XMLValueType.BOOL, key .. '#removeStoneArea')
    schema:register(XMLValueType.BOOL, key .. '#removeWeedArea')

    schema:register(XMLValueType.FLOAT, key .. '#paintModifier')
    schema:register(XMLValueType.FLOAT, key .. '#densityModifier')

    schema:register(XMLValueType.BOOL, key .. '#forceNodes')
    schema:register(XMLValueType.BOOL, key .. '#allowGradingUp')
    schema:register(XMLValueType.BOOL, key .. '#autoDeactivate')
    schema:register(XMLValueType.INT, key .. '#drivingDirectionMode')
end

---@return MachineState
---@nodiscard
function MachineState.new()
    ---@type MachineState
    local self = setmetatable({}, MachineState_mt)

    self.enableEffects = true

    self.clearDecoArea = true
    self.clearDensityMapHeightArea = false
    self.eraseTireTracks = true
    self.removeFieldArea = true
    self.removeStoneArea = true
    self.removeWeedArea = true

    self.inputRadius = 2
    self.inputStrength = 0.25
    self.inputHardness = 0.2
    self.inputBrushShape = Landscaping.BRUSH_SHAPE.CIRCLE
    self.enableInputMaterial = true
    self.enableInputGroundTexture = true
    self.inputRatio = 1

    self.outputRadius = 3
    self.outputStrength = 0.25
    self.outputHardness = 0.2
    self.outputBrushShape = Landscaping.BRUSH_SHAPE.CIRCLE
    self.enableOutputMaterial = true
    self.enableOutputGroundTexture = true
    self.outputRatio = 1

    self.paintModifier = 0.75
    self.densityModifier = 0.75

    self.allowGradingUp = false
    self.forceNodes = false
    self.autoDeactivate = true
    self.drivingDirectionMode = DrivingDirectionMode.FORWARDS

    return self
end

---@param vehicle Machine
---@param property string
---@param value boolean|number
function MachineState:setProperty(vehicle, property, value)
    if self[property] ~= value then
        local newState = self:clone()

        newState[property] = value

        vehicle:setMachineState(newState)
    end
end

---@param vehicle Machine
---@param property string
---@param value boolean
function MachineState:setBool(vehicle, property, value)
    self:setProperty(vehicle, property, value)
end

---@param vehicle Machine
---@param property string
---@param value number
function MachineState:setNumber(vehicle, property, value)
    self:setProperty(vehicle, property, value)
end

---@param xmlFile XMLFile
---@param key string
function MachineState:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. '#enableEffects', self.enableEffects)

    xmlFile:setValue(key .. '#inputRadius', self.inputRadius)
    xmlFile:setValue(key .. '#inputStrength', self.inputStrength)
    xmlFile:setValue(key .. '#inputHardness', self.inputHardness)
    xmlFile:setValue(key .. '#inputBrushShape', self.inputBrushShape)
    xmlFile:setValue(key .. '#enableInputMaterial', self.enableInputMaterial)
    xmlFile:setValue(key .. '#enableInputGroundTexture', self.enableInputGroundTexture)
    xmlFile:setValue(key .. '#inputRatio', self.inputRatio)

    xmlFile:setValue(key .. '#outputRadius', self.outputRadius)
    xmlFile:setValue(key .. '#outputStrength', self.outputStrength)
    xmlFile:setValue(key .. '#outputHardness', self.outputHardness)
    xmlFile:setValue(key .. '#outputBrushShape', self.outputBrushShape)
    xmlFile:setValue(key .. '#enableOutputMaterial', self.enableOutputMaterial)
    xmlFile:setValue(key .. '#enableOutputGroundTexture', self.enableOutputGroundTexture)
    xmlFile:setValue(key .. '#outputRatio', self.outputRatio)

    xmlFile:setValue(key .. '#clearDecoArea', self.clearDecoArea)
    xmlFile:setValue(key .. '#clearDensityMapHeightArea', self.clearDensityMapHeightArea)
    xmlFile:setValue(key .. '#eraseTireTracks', self.eraseTireTracks)
    xmlFile:setValue(key .. '#removeFieldArea', self.removeFieldArea)
    xmlFile:setValue(key .. '#removeStoneArea', self.removeStoneArea)
    xmlFile:setValue(key .. '#removeWeedArea', self.removeWeedArea)

    xmlFile:setValue(key .. '#paintModifier', self.paintModifier)
    xmlFile:setValue(key .. '#densityModifier', self.densityModifier)

    xmlFile:setValue(key .. '#allowGradingUp', self.allowGradingUp)
    xmlFile:setValue(key .. '#forceNodes', self.forceNodes)
    xmlFile:setValue(key .. '#autoDeactivate', self.autoDeactivate)
    xmlFile:setValue(key .. '#drivingDirectionMode', self.drivingDirectionMode)
end

---@param xmlFile XMLFile
---@param key string
function MachineState:loadFromXMLFile(xmlFile, key)
    self.enableEffects = xmlFile:getValue(key .. '#enableEffects', self.enableEffects)

    self.inputRadius = xmlFile:getValue(key .. '#inputRadius', self.inputRadius)
    self.inputStrength = xmlFile:getValue(key .. '#inputStrength', self.inputStrength)
    self.inputHardness = xmlFile:getValue(key .. '#inputHardness', self.inputHardness)
    self.inputBrushShape = xmlFile:getValue(key .. '#inputBrushShape', self.inputBrushShape)
    self.enableInputMaterial = xmlFile:getValue(key .. '#enableInputMaterial', self.enableInputMaterial)
    self.enableInputGroundTexture = xmlFile:getValue(key .. '#enableInputGroundTexture', self.enableInputGroundTexture)
    self.inputRatio = xmlFile:getValue(key .. '#inputRatio', self.inputRatio)

    self.outputRadius = xmlFile:getValue(key .. '#outputRadius', self.outputRadius)
    self.outputStrength = xmlFile:getValue(key .. '#outputStrength', self.outputStrength)
    self.outputHardness = xmlFile:getValue(key .. '#outputHardness', self.outputHardness)
    self.outputBrushShape = xmlFile:getValue(key .. '#outputBrushShape', self.outputBrushShape)
    self.enableOutputMaterial = xmlFile:getValue(key .. '#enableOutputMaterial', self.enableOutputMaterial)
    self.enableOutputGroundTexture = xmlFile:getValue(key .. '#enableOutputGroundTexture', self.enableOutputGroundTexture)
    self.outputRatio = xmlFile:getValue(key .. '#outputRatio', self.outputRatio)

    self.clearDecoArea = xmlFile:getValue(key .. '#clearDecoArea', self.clearDecoArea)
    self.clearDensityMapHeightArea = xmlFile:getValue(key .. '#clearDensityMapHeightArea', self.clearDensityMapHeightArea)
    self.eraseTireTracks = xmlFile:getValue(key .. '#eraseTireTracks', self.eraseTireTracks)
    self.removeFieldArea = xmlFile:getValue(key .. '#removeFieldArea', self.removeFieldArea)
    self.removeStoneArea = xmlFile:getValue(key .. '#removeStoneArea', self.removeStoneArea)
    self.removeWeedArea = xmlFile:getValue(key .. '#removeWeedArea', self.removeWeedArea)

    self.paintModifier = xmlFile:getValue(key .. '#paintModifier', self.paintModifier)
    self.densityModifier = xmlFile:getValue(key .. '#densityModifier', self.densityModifier)

    self.allowGradingUp = xmlFile:getValue(key .. '#allowGradingUp', self.allowGradingUp)
    self.forceNodes = xmlFile:getValue(key .. '#forceNodes', self.forceNodes)
    self.autoDeactivate = xmlFile:getValue(key .. '#autoDeactivate', self.autoDeactivate)
    self.drivingDirectionMode = xmlFile:getValue(key .. '#drivingDirectionMode', self.drivingDirectionMode)
end

---@return MachineState
---@nodiscard
function MachineState:clone()
    local clone = MachineState.new()

    clone.enableEffects = self.enableEffects

    clone.inputRadius = self.inputRadius
    clone.inputStrength = self.inputStrength
    clone.inputHardness = self.inputHardness
    clone.inputBrushShape = self.inputBrushShape
    clone.enableInputMaterial = self.enableInputMaterial
    clone.enableInputGroundTexture = self.enableInputGroundTexture
    clone.inputRatio = self.inputRatio

    clone.outputRadius = self.outputRadius
    clone.outputStrength = self.outputStrength
    clone.outputHardness = self.outputHardness
    clone.outputBrushShape = self.outputBrushShape
    clone.enableOutputMaterial = self.enableOutputMaterial
    clone.enableOutputGroundTexture = self.enableOutputGroundTexture
    clone.outputRatio = self.outputRatio

    clone.clearDecoArea = self.clearDecoArea
    clone.clearDensityMapHeightArea = self.clearDensityMapHeightArea
    clone.eraseTireTracks = self.eraseTireTracks
    clone.removeFieldArea = self.removeFieldArea
    clone.removeStoneArea = self.removeStoneArea
    clone.removeWeedArea = self.removeWeedArea

    clone.paintModifier = self.paintModifier
    clone.densityModifier = self.densityModifier

    clone.allowGradingUp = self.allowGradingUp
    clone.forceNodes = self.forceNodes
    clone.autoDeactivate = self.autoDeactivate
    clone.drivingDirectionMode = self.drivingDirectionMode

    return clone
end

---@param streamId number
---@param connection Connection
function MachineState:writeStream(streamId, connection)
    streamWriteBool(streamId, self.enableEffects)

    streamWriteFloat32(streamId, self.inputRadius)
    streamWriteFloat32(streamId, self.inputStrength)
    streamWriteFloat32(streamId, self.inputHardness)
    streamWriteUIntN(streamId, self.inputBrushShape, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
    streamWriteBool(streamId, self.enableInputMaterial)
    streamWriteBool(streamId, self.enableInputGroundTexture)
    streamWriteFloat32(streamId, self.inputRatio)

    streamWriteFloat32(streamId, self.outputRadius)
    streamWriteFloat32(streamId, self.outputStrength)
    streamWriteFloat32(streamId, self.outputHardness)
    streamWriteUIntN(streamId, self.outputBrushShape, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
    streamWriteBool(streamId, self.enableOutputMaterial)
    streamWriteBool(streamId, self.enableOutputGroundTexture)
    streamWriteFloat32(streamId, self.outputRatio)

    streamWriteBool(streamId, self.clearDecoArea)
    streamWriteBool(streamId, self.clearDensityMapHeightArea)
    streamWriteBool(streamId, self.eraseTireTracks)
    streamWriteBool(streamId, self.removeFieldArea)
    streamWriteBool(streamId, self.removeStoneArea)
    streamWriteBool(streamId, self.removeWeedArea)

    streamWriteFloat32(streamId, self.paintModifier)
    streamWriteFloat32(streamId, self.densityModifier)

    streamWriteBool(streamId, self.allowGradingUp)
    streamWriteBool(streamId, self.forceNodes)
    streamWriteBool(streamId, self.autoDeactivate)
    streamWriteUIntN(streamId, self.drivingDirectionMode, MachineState.SEND_NUM_BITS_DIRECTION_MODE)
end

---@param streamId number
---@param connection Connection
function MachineState:readStream(streamId, connection)
    self.enableEffects = streamReadBool(streamId)

    self.inputRadius = streamReadFloat32(streamId)
    self.inputStrength = streamReadFloat32(streamId)
    self.inputHardness = streamReadFloat32(streamId)
    self.inputBrushShape = streamReadUIntN(streamId, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
    self.enableInputMaterial = streamReadBool(streamId)
    self.enableInputGroundTexture = streamReadBool(streamId)
    self.inputRatio = streamReadFloat32(streamId)

    self.outputRadius = streamReadFloat32(streamId)
    self.outputStrength = streamReadFloat32(streamId)
    self.outputHardness = streamReadFloat32(streamId)
    self.outputBrushShape = streamReadUIntN(streamId, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
    self.enableOutputMaterial = streamReadBool(streamId)
    self.enableOutputGroundTexture = streamReadBool(streamId)
    self.outputRatio = streamReadFloat32(streamId)

    self.clearDecoArea = streamReadBool(streamId)
    self.clearDensityMapHeightArea = streamReadBool(streamId)
    self.eraseTireTracks = streamReadBool(streamId)
    self.removeFieldArea = streamReadBool(streamId)
    self.removeStoneArea = streamReadBool(streamId)
    self.removeWeedArea = streamReadBool(streamId)

    self.paintModifier = streamReadFloat32(streamId)
    self.densityModifier = streamReadFloat32(streamId)

    self.allowGradingUp = streamReadBool(streamId)
    self.forceNodes = streamReadBool(streamId)
    self.autoDeactivate = streamReadBool(streamId)
    self.drivingDirectionMode = streamReadUIntN(streamId, MachineState.SEND_NUM_BITS_DIRECTION_MODE)
end

---@class MachineState
---@field enableInputMaterial boolean
---@field enableOutputMaterial boolean
---@field enablePaintGroundTexture boolean
---@field enableEffects boolean -- Only enabled if #effects > 0
---
---@field radius number
---@field strength number
---@field hardness number
---@field brushShape number
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
---@field inputRatio number
MachineState = {}

local MachineState_mt = Class(MachineState)

---@param schema XMLSchema
---@param key string
function MachineState.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.BOOL, key .. '#enableInputMaterial')
    schema:register(XMLValueType.BOOL, key .. '#enableOutputMaterial')
    schema:register(XMLValueType.BOOL, key .. '#enablePaintGroundTexture')
    schema:register(XMLValueType.BOOL, key .. '#enableEffects')

    schema:register(XMLValueType.FLOAT, key .. '#strength')
    schema:register(XMLValueType.FLOAT, key .. '#radius')
    schema:register(XMLValueType.FLOAT, key .. '#hardness')
    schema:register(XMLValueType.INT, key .. '#brushShape')

    schema:register(XMLValueType.BOOL, key .. '#clearDecoArea')
    schema:register(XMLValueType.BOOL, key .. '#clearDensityMapHeightArea')
    schema:register(XMLValueType.BOOL, key .. '#eraseTireTracks')
    schema:register(XMLValueType.BOOL, key .. '#removeFieldArea')
    schema:register(XMLValueType.BOOL, key .. '#removeStoneArea')
    schema:register(XMLValueType.BOOL, key .. '#removeWeedArea')

    schema:register(XMLValueType.FLOAT, key .. '#paintModifier')
    schema:register(XMLValueType.FLOAT, key .. '#densityModifier')
    schema:register(XMLValueType.FLOAT, key .. '#inputRatio')

    schema:register(XMLValueType.BOOL, key .. '#forceNodes')
    schema:register(XMLValueType.BOOL, key .. '#allowGradingUp')
end

---@return MachineState
---@nodiscard
function MachineState.new()
    ---@type MachineState
    local self = setmetatable({}, MachineState_mt)

    self.enableInputMaterial = true
    self.enableOutputMaterial = true
    self.enablePaintGroundTexture = true
    self.enableEffects = true

    self.clearDecoArea = true
    self.clearDensityMapHeightArea = false
    self.eraseTireTracks = true
    self.removeFieldArea = true
    self.removeStoneArea = true
    self.removeWeedArea = true

    self.radius = 2.0
    self.strength = 0.25
    self.hardness = 0.2
    self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE

    self.paintModifier = 0.75
    self.densityModifier = 0.75
    self.inputRatio = 1.0

    self.allowGradingUp = false
    self.forceNodes = false

    return self
end

---@param xmlFile XMLFile
---@param key string
function MachineState:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. '#enableInputMaterial', self.enableInputMaterial)
    xmlFile:setValue(key .. '#enableOutputMaterial', self.enableOutputMaterial)
    xmlFile:setValue(key .. '#enablePaintGroundTexture', self.enablePaintGroundTexture)
    xmlFile:setValue(key .. '#enableEffects', self.enableEffects)

    xmlFile:setValue(key .. '#radius', self.radius)
    xmlFile:setValue(key .. '#strength', self.strength)
    xmlFile:setValue(key .. '#hardness', self.hardness)
    xmlFile:setValue(key .. '#brushShape', self.brushShape)

    xmlFile:setValue(key .. '#clearDecoArea', self.clearDecoArea)
    xmlFile:setValue(key .. '#clearDensityMapHeightArea', self.clearDensityMapHeightArea)
    xmlFile:setValue(key .. '#eraseTireTracks', self.eraseTireTracks)
    xmlFile:setValue(key .. '#removeFieldArea', self.removeFieldArea)
    xmlFile:setValue(key .. '#removeStoneArea', self.removeStoneArea)
    xmlFile:setValue(key .. '#removeWeedArea', self.removeWeedArea)

    xmlFile:setValue(key .. '#paintModifier', self.paintModifier)
    xmlFile:setValue(key .. '#densityModifier', self.densityModifier)
    xmlFile:setValue(key .. '#inputRatio', self.inputRatio)

    xmlFile:setValue(key .. '#allowGradingUp', self.allowGradingUp)
    xmlFile:setValue(key .. '#forceNodes', self.forceNodes)
end

---@param xmlFile XMLFile
---@param key string
function MachineState:loadFromXMLFile(xmlFile, key)
    self.enableInputMaterial = xmlFile:getValue(key .. '#enableInputMaterial', self.enableInputMaterial)
    self.enableOutputMaterial = xmlFile:getValue(key .. '#enableOutputMaterial', self.enableOutputMaterial)
    self.enablePaintGroundTexture = xmlFile:getValue(key .. '#enablePaintGroundTexture', self.enablePaintGroundTexture)
    self.enableEffects = xmlFile:getValue(key .. '#enableEffects', self.enableEffects)

    self.radius = xmlFile:getValue(key .. '#radius', self.radius)
    self.strength = xmlFile:getValue(key .. '#strength', self.strength)
    self.hardness = xmlFile:getValue(key .. '#hardness', self.hardness)
    self.brushShape = xmlFile:getValue(key .. '#brushShape', self.brushShape)

    self.clearDecoArea = xmlFile:getValue(key .. '#clearDecoArea', self.clearDecoArea)
    self.clearDensityMapHeightArea = xmlFile:getValue(key .. '#clearDensityMapHeightArea', self.clearDensityMapHeightArea)
    self.eraseTireTracks = xmlFile:getValue(key .. '#eraseTireTracks', self.eraseTireTracks)
    self.removeFieldArea = xmlFile:getValue(key .. '#removeFieldArea', self.removeFieldArea)
    self.removeStoneArea = xmlFile:getValue(key .. '#removeStoneArea', self.removeStoneArea)
    self.removeWeedArea = xmlFile:getValue(key .. '#removeWeedArea', self.removeWeedArea)

    self.paintModifier = xmlFile:getValue(key .. '#paintModifier', self.paintModifier)
    self.densityModifier = xmlFile:getValue(key .. '#densityModifier', self.densityModifier)
    self.inputRatio = xmlFile:getValue(key .. '#inputRatio', self.inputRatio)

    self.allowGradingUp = xmlFile:getValue(key .. '#allowGradingUp', self.allowGradingUp)
    self.forceNodes = xmlFile:getValue(key .. '#forceNodes', self.forceNodes)
end

---@return MachineState
---@nodiscard
function MachineState:clone()
    local clone = MachineState.new()

    clone.enableInputMaterial = self.enableInputMaterial
    clone.enableOutputMaterial = self.enableOutputMaterial
    clone.enablePaintGroundTexture = self.enablePaintGroundTexture
    clone.enableEffects = self.enableEffects

    clone.radius = self.radius
    clone.strength = self.strength
    clone.hardness = self.hardness
    clone.brushShape = self.brushShape

    clone.clearDecoArea = self.clearDecoArea
    clone.clearDensityMapHeightArea = self.clearDensityMapHeightArea
    clone.eraseTireTracks = self.eraseTireTracks
    clone.removeFieldArea = self.removeFieldArea
    clone.removeStoneArea = self.removeStoneArea
    clone.removeWeedArea = self.removeWeedArea

    clone.paintModifier = self.paintModifier
    clone.densityModifier = self.densityModifier
    clone.inputRatio = self.inputRatio

    clone.allowGradingUp = self.allowGradingUp
    clone.forceNodes = self.forceNodes

    return clone
end

---@param streamId number
---@param connection Connection
function MachineState:writeStream(streamId, connection)
    streamWriteBool(streamId, self.enableInputMaterial)
    streamWriteBool(streamId, self.enableOutputMaterial)
    streamWriteBool(streamId, self.enablePaintGroundTexture)
    streamWriteBool(streamId, self.enableEffects)

    streamWriteFloat32(streamId, self.radius)
    streamWriteFloat32(streamId, self.strength)
    streamWriteFloat32(streamId, self.hardness)
    streamWriteUIntN(streamId, self.brushShape, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)

    streamWriteBool(streamId, self.clearDecoArea)
    streamWriteBool(streamId, self.clearDensityMapHeightArea)
    streamWriteBool(streamId, self.eraseTireTracks)
    streamWriteBool(streamId, self.removeFieldArea)
    streamWriteBool(streamId, self.removeStoneArea)
    streamWriteBool(streamId, self.removeWeedArea)

    streamWriteFloat32(streamId, self.paintModifier)
    streamWriteFloat32(streamId, self.densityModifier)
    streamWriteFloat32(streamId, self.inputRatio)

    streamWriteBool(streamId, self.allowGradingUp)
    streamWriteBool(streamId, self.forceNodes)
end

---@param streamId number
---@param connection Connection
function MachineState:readStream(streamId, connection)
    self.enableInputMaterial = streamReadBool(streamId)
    self.enableOutputMaterial = streamReadBool(streamId)
    self.enablePaintGroundTexture = streamReadBool(streamId)
    self.enableEffects = streamReadBool(streamId)

    self.radius = streamReadFloat32(streamId)
    self.strength = streamReadFloat32(streamId)
    self.hardness = streamReadFloat32(streamId)
    self.brushShape = streamReadUIntN(streamId, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)

    self.clearDecoArea = streamReadBool(streamId)
    self.clearDensityMapHeightArea = streamReadBool(streamId)
    self.eraseTireTracks = streamReadBool(streamId)
    self.removeFieldArea = streamReadBool(streamId)
    self.removeStoneArea = streamReadBool(streamId)
    self.removeWeedArea = streamReadBool(streamId)

    self.paintModifier = streamReadFloat32(streamId)
    self.densityModifier = streamReadFloat32(streamId)
    self.inputRatio = streamReadFloat32(streamId)

    self.allowGradingUp = streamReadBool(streamId)
    self.forceNodes = streamReadBool(streamId)
end

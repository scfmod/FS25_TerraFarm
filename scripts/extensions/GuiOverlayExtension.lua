local function inj_GuiOverlay_loadOverlay(self, superFunc, overlay, ...)
    ---@type Overlay
    local result_overlay = superFunc(self, overlay, ...)

    if overlay ~= nil and result_overlay ~= nil then
        if overlay.filename == 'g_machineUIFilename' then
            result_overlay.filename = g_modUIFilename
        end

        if overlay.maskFilename == 'g_tfPreviewMaskFilename' then
            result_overlay.maskFilename = g_previewMaskFilename
        elseif overlay.maskFilename == 'g_machineUIFilename' then
            result_overlay.maskFilename = g_modUIFilename
        end
    end

    return result_overlay
end

GuiOverlay.loadOverlay = Utils.overwrittenFunction(GuiOverlay.loadOverlay, inj_GuiOverlay_loadOverlay)

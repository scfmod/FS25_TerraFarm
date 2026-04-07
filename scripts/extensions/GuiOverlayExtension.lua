local function inj_GuiOverlay_loadOverlay(self, superFunc, overlay, ...)
    ---@type Overlay
    local result_overlay = superFunc(self, overlay, ...)

    if overlay ~= nil and result_overlay ~= nil then
        if overlay.maskFilename == 'g_tfPreviewMaskFilename' then
            result_overlay.maskFilename = g_previewMaskFilename
        elseif overlay.filename == 'g_tfEditorGuide_1' then
            result_overlay.filename = g_modDirectory .. 'data/textures/guide/editor_guide_1.png'
        elseif overlay.filename == 'g_tfEditorGuide_2' then
            result_overlay.filename = g_modDirectory .. 'data/textures/guide/editor_guide_2.png'
        elseif overlay.filename == 'g_tfEditorGuide_3' then
            result_overlay.filename = g_modDirectory .. 'data/textures/guide/editor_guide_3.png'
        end
    end

    return result_overlay
end

GuiOverlay.loadOverlay = Utils.overwrittenFunction(GuiOverlay.loadOverlay, inj_GuiOverlay_loadOverlay)

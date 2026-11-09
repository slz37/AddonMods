---@type string, addonMods
local _, addonMods = ...
if not Grid2 then return end

---@param Frame table<string, any>
local function getOrCreateBorderHighlight(Frame)
	if not Frame.BorderHighlightFrame then
		local Highlight = CreateFrame('Frame', nil, Frame, 'BackdropTemplate')
		Highlight:SetPoint('TOPLEFT',     Frame, 'TOPLEFT',     1, -1)
		Highlight:SetPoint('BOTTOMRIGHT', Frame, 'BOTTOMRIGHT', -1, 1)
		Highlight:SetFrameLevel(Frame:GetFrameLevel() + 7)
		Highlight:Hide()

		Frame:HookScript('OnEnter', function() if Grid2Frame.db.profile.mouseoverHighlight and Frame.BorderHighlightFrame then Frame.BorderHighlightFrame:Show() end end)
		Frame:HookScript('OnLeave', function() if Frame.BorderHighlightFrame then Frame.BorderHighlightFrame:Hide() end end)

		Frame.BorderHighlightFrame = Highlight
	end
	return Frame.BorderHighlightFrame
end

---@param self table<string, any>
hooksecurefunc(Grid2Frame.Prototype, 'Layout', function(self)
	self:SetHighlightTexture('')
	self:GetHighlightTexture():SetVertexColor(0, 0, 0, 0)

	local dbx         = Grid2Frame.db.profile
	local inset       = (dbx.frameBorder + dbx.frameBorderDistance) * 2
	local borderWidth = inset / 2

	if dbx.mouseoverHighlight then
		local Highlight = getOrCreateBorderHighlight(self)
		local hlTex     = Grid2:MediaFetch('background', dbx.mouseoverTexture, 'Blizzard Quest Title Highlight')
		local color     = dbx.mouseoverColor

		Highlight:SetBackdrop({
			bgFile   = nil,
			edgeFile = hlTex,
			tile     = false,
			tileSize = 0,
			edgeSize = borderWidth,
			insets   = {left = borderWidth, right = borderWidth, top = borderWidth, bottom = borderWidth},
		})
		Highlight:SetBackdropColor(0, 0, 0, 0)
		Highlight:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
	else
		if self.BorderHighlightFrame then
			self.BorderHighlightFrame:Hide()
		end
	end
end)
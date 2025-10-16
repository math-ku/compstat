-- Convert ELEM{only=X} to \begin{onlyenv}<X>ELEM\end{onlyenv}
-- (and likewise for several other overlay types)

local overlays_supported = pandoc.List({ "only", "uncover", "visible", "invisible", "action", "alert" })

local function tex_wrap(block_mode, pre, el, post)
	return block_mode and pandoc.Blocks({ pandoc.RawBlock("tex", pre), el, pandoc.RawBlock("tex", post) })
		or pandoc.Inlines({ pandoc.RawInline("tex", pre), el, pandoc.RawInline("tex", post) })
end

local function wrap_in_overlays(block_mode, el)
	for k, v in pairs(el.attributes) do
		el = overlays_supported:includes(k) and tex_wrap(block_mode, "\\" .. k .. "<" .. v .. ">{", el, "}") or el
	end
	return el
end

local function wrap_block(el)
	return wrap_in_overlays(true, el)
end
local function wrap_inline(el)
	return wrap_in_overlays(false, el)
end

return {
	{
		-- These block elements have attributes
		CodeBlock = wrap_block,
		Div = wrap_block,
		Figure = wrap_block,
		Table = wrap_block,
		-- These inline elements have attributes
		Code = wrap_inline,
		Image = wrap_inline,
		Link = wrap_inline,
		Span = wrap_inline,
	},
}

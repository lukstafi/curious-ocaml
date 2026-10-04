-- Use the vector PDF companion for diagrams in the printed book.
function Image(image)
  if FORMAT:match("latex") then
    image.src = image.src:gsub("%.svg$", ".pdf")
  end
  return image
end

-- Keep explanatory figures beside their argument rather than inside an earlier
-- code listing split across pages. The template already loads the float package.
function Figure(figure)
  local technical = false
  figure:walk({Image = function(image)
    for _, class in ipairs(image.classes) do
      if class == "technical-figure" then technical = true end
    end
  end})
  if FORMAT:match("latex") and technical then
    return {pandoc.RawBlock("latex", "\\begingroup\\floatplacement{figure}{H}"),
            figure, pandoc.RawBlock("latex", "\\endgroup")}
  end
end

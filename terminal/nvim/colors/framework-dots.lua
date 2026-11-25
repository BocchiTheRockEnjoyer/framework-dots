-- Framework Dots. Follows 'background', which Neovim sets from the terminal.
vim.cmd.highlight("clear")
vim.g.colors_name = "framework-dots"
vim.o.termguicolors = true
local d = vim.o.background ~= "light"
local acc = "#f3531a"
local link = d and "#ff8052" or "#b83808"
local fg, hi, dim, com, line, sel = d and "#d8d8d8" or "#2c2c2c", d and "#f6f6f6" or "#141414", d and "#9a9a9a" or "#6a6a6a", d and "#7a7a7a" or "#868686", d and "#262626" or "#e8e8e8", d and "#3a3a3a" or "#d4d4d4"
local num, str, typ, red, grn, warn = d and "#f6aa3c" or "#8a5500", d and "#b9b9a0" or "#56563c", d and "#c8c8c8" or "#444444", d and "#ed4646" or "#be1e1e", d and "#7fb069" or "#3f7a2a", d and "#f6aa3c" or "#9a5f00"
local function h(n, o) vim.api.nvim_set_hl(0, n, o) end
h("Normal", { fg = fg }) h("NormalFloat", { fg = fg, bg = line }) h("FloatBorder", { fg = dim }) h("FloatTitle", { fg = acc, bold = true })
h("Comment", { fg = com, italic = true }) h("Constant", { fg = num }) h("String", { fg = str }) h("Number", { fg = num }) h("Identifier", { fg = fg }) h("Function", { fg = hi, bold = true })
h("Statement", { fg = acc, bold = true }) h("Keyword", { fg = acc, bold = true }) h("Operator", { fg = dim }) h("PreProc", { fg = acc }) h("Type", { fg = typ }) h("Special", { fg = link }) h("Delimiter", { fg = dim }) h("Title", { fg = acc, bold = true }) h("Todo", { fg = acc, bold = true }) h("Underlined", { fg = link, underline = true }) h("Error", { fg = red }) h("@variable", { fg = fg })
h("LineNr", { fg = com }) h("CursorLineNr", { fg = acc, bold = true }) h("CursorLine", { bg = line }) h("ColorColumn", { bg = line }) h("SignColumn", {}) h("Folded", { fg = dim, bg = line }) h("NonText", { fg = sel }) h("Whitespace", { fg = sel }) h("WinSeparator", { fg = sel }) h("EndOfBuffer", { fg = sel })
h("Visual", { bg = sel }) h("Search", { fg = "#141414", bg = acc }) h("IncSearch", { fg = "#141414", bg = acc, bold = true }) h("CurSearch", { fg = "#141414", bg = acc, bold = true }) h("MatchParen", { fg = acc, bold = true, underline = true })
h("StatusLine", { fg = fg, bg = line }) h("StatusLineNC", { fg = com, bg = line }) h("TabLine", { fg = com, bg = line }) h("TabLineSel", { fg = "#141414", bg = acc }) h("TabLineFill", { bg = line }) h("Pmenu", { fg = fg, bg = line }) h("PmenuSel", { fg = "#141414", bg = acc }) h("PmenuThumb", { bg = dim }) h("WildMenu", { fg = "#141414", bg = acc })
h("ErrorMsg", { fg = red }) h("WarningMsg", { fg = warn }) h("ModeMsg", { fg = acc }) h("MoreMsg", { fg = acc }) h("Question", { fg = acc }) h("Directory", { fg = acc })
h("DiagnosticError", { fg = red }) h("DiagnosticWarn", { fg = warn }) h("DiagnosticInfo", { fg = dim }) h("DiagnosticHint", { fg = dim }) h("DiffAdd", { fg = grn }) h("DiffDelete", { fg = red }) h("DiffChange", { fg = acc }) h("DiffText", { fg = "#141414", bg = acc }) h("Added", { fg = grn }) h("Removed", { fg = red }) h("Changed", { fg = acc })

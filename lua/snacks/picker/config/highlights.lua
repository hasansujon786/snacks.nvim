---@class snacks.picker.config.highlights
local M = {}

Snacks.util.set_hl({
  Match = "Special",
  Search = "Search",
  Prompt = "Special",
  InputSearch = "@keyword",
  Special = "Special",
  Label = "SnacksPickerSpecial",
  Totals = "NonText",
  File = "",
  Flag = "DiagnosticVirtualTextInfo",
  FlagHidden = "SnacksPickerFlag",
  FlagIgnored = "SnacksPickerFlag",
  FlagFollow = "SnacksPickerFlag",
  Dir = "NonText",
  Dimmed = "Conceal",
  Row = "String",
  Col = "LineNr",
  Comment = "Comment",
  Desc = "Comment",
  Delim = "Delimiter",
  Spinner = "Special",
  Selected = "Number",
  Cmd = "Function",
  CmdBuiltin = "@constructor",
  Unselected = "NonText",
  Idx = "Number",
  Bold = "Bold",
  Indent = "LineNr",
  Italic = "Italic",
  Code = "@markup.raw.markdown_inline",
  AuPattern = "String",
  AuEvent = "Constant",
  AuGroup = "Type",
  DiagnosticCode = "Special",
  DiagnosticSource = "Comment",
  Register = "Number",
  KeymapMode = "Number",
  KeymapLhs = "Special",
  KeymapNowait = "@variable.builtin",
  BufNr = "Number",
  BufFlags = "NonText",
  KeymapRhs = "NonText",
  Time = "Special",
  UndoAdded = "Added",
  UndoRemoved = "Removed",
  UndoCurrent = "@variable.builtin",
  UndoSaved = "Special",
  GitCommit = "@variable.builtin",
  GitBreaking = "Error",
  GitDetached = "DiagnosticWarn",
  GitBranch = "Title",
  GitBranchCurrent = "Number",
  GitDate = "Special",
  GitIssue = "Number",
  GitType = "Title", -- conventional commit type
  GitScope = "Italic", -- conventional commit scope
  GitStatus = "NonText",
  GitStatusAdded = "Added",
  GitStatusModified = "Changed",
  GitStatusDeleted = "Removed",
  GitStatusRenamed = "SnacksPickerGitStatus",
  GitStatusCopied = "SnacksPickerGitStatus",
  GitStatusUntracked = "SnacksPickerGitStatus",
  ManSection = "Number",
  PickWin = "DiagnosticVirtualTextError",
  ManPage = "Special",
  -- Icons
  Icon = "Special",
  IconSource = "@constant",
  IconName = "@keyword",
  IconCategory = "@module",
  -- LSP Symbol Kinds
  IconArray = "@punctuation.bracket",
  IconBoolean = "@boolean",
  IconClass = "@type",
  IconConstant = "@constant",
  IconConstructor = "@constructor",
  IconEnum = "@lsp.type.enum",
  IconEnumMember = "@lsp.type.enumMember",
  IconEvent = "Special",
  IconField = "@variable.member",
  IconFile = "Normal",
  IconFunction = "@function",
  IconInterface = "@lsp.type.interface",
  IconKey = "@lsp.type.keyword",
  IconMethod = "@function.method",
  IconModule = "@module",
  IconNamespace = "@module",
  IconNull = "@constant.builtin",
  IconNumber = "@number",
  IconObject = "@constant",
  IconOperator = "@operator",
  IconPackage = "@module",
  IconProperty = "@property",
  IconString = "@string",
  IconStruct = "@lsp.type.struct",
  IconTypeParameter = "@lsp.type.typeParameter",
  IconVariable = "@variable",
}, { prefix = "SnacksPicker", default = true })

return M

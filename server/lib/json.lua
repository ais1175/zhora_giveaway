-- json.lua (Version 3)
--
-- Copyright (c) 2017, rxi
-- Copyright (c) 2023, dcurrie
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local json = { _version = "json.lua 3" }

local math = math
local string = string
local table = table
local type = type
local tostring = tostring
local tonumber = tonumber
local error = error
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local string_format = string.format
local string_sub = string.sub
local string_byte = string.byte
local string_char = string.char
local string_match = string.match
local string_gsub = string.gsub
local table_concat = table.concat
local table_insert = table.insert
local table_remove = table.remove
local math_floor = math.floor
local math_abs = math.abs
local math_huge = math.huge
local bit_band, bit_bor, bit_bxor, bit_lshift, bit_rshift, bit_bnot, bit_arshift -- luajit bit.* or lua 5.3 bit32.*
if _VERSION == "Lua 5.1" and require and pcall(require, "bit") then -- luajit
  bit_band = bit.band
  bit_bor = bit.bor
  bit_bxor = bit.bxor
  bit_lshift = bit.lshift
  bit_rshift = bit.rshift
  bit_bnot = bit.bnot
elseif _VERSION == "Lua 5.3" or _VERSION == "Lua 5.4" then -- lua 5.3/5.4
  bit_band = bit32.band
  bit_bor = bit32.bor
  bit_bxor = bit32.bxor
  bit_lshift = bit32.lshift
  bit_rshift = bit32.rshift
  bit_bnot = bit32.bnot
  bit_arshift = bit32.arshift
else -- lua 5.1/5.2 without bitop or luajit without bit module
  -- https://github.com/davidm/lua-bitmask
  local function bitmask_band(a, b)
    local r, m = 0, 1
    while a > 0 and b > 0 do
      if (a % 2 == 1) and (b % 2 == 1) then -- test last bit
        r = r + m
      end
      m = m + m -- next bit; check for overflow if you have added that to your lua
      a = math_floor(a / 2)
      b = math_floor(b / 2)
    end
    return r
  end
  bit_band = bitmask_band
end


local _DEBUG = false -- Can be overridden by `json.decode(str, { debug = true })`

local _INT_MAX = 2^53 -- Largest integer that can be represented in a double without loss of precision

local _TYPE_NULL    = 0
local _TYPE_BOOLEAN = 1
local _TYPE_NUMBER  = 2
local _TYPE_STRING  = 3
local _TYPE_ARRAY   = 4
local _TYPE_OBJECT  = 5

local _OPT_DEBUG           = 1 -- Print debug messages
local _OPT_ALLOW_NIL_VALUES = 2 -- Allow nil values in tables (ignored by encoder, affects decoder)
local _OPT_PRESERVE_ORDER  = 4 -- Preserve order of keys in objects (tables)
local _OPT_ALLOW_TRAILING_COMMA = 8 -- Allow trailing commas in arrays and objects
local _OPT_ALLOW_COMMENTS = 16 -- Allow single-line and multi-line comments
local _OPT_ALLOW_HEX_NUMBERS = 32 -- Allow hexadecimal numbers (0x...)
local _OPT_ALLOW_UNQUOTED_KEYS = 64 -- Allow unquoted keys in objects
local _OPT_ALLOW_SINGLE_QUOTES = 128 -- Allow single quotes for strings and keys
local _OPT_FORCE_ARRAY = 256 -- Force the top-level element to be decoded as an array
local _OPT_FORCE_OBJECT = 512 -- Force the top-level element to be decoded as an object
local _OPT_ALLOW_NAN_INF = 1024 -- Allow NaN, Infinity, -Infinity as numbers
local _OPT_STRICT = 2048 -- Enable strict mode (disables all non-standard extensions)

local _DEFAULT_OPTIONS = _OPT_ALLOW_TRAILING_COMMA + _OPT_ALLOW_COMMENTS + _OPT_ALLOW_HEX_NUMBERS +
                         _OPT_ALLOW_UNQUOTED_KEYS + _OPT_ALLOW_SINGLE_QUOTES + _OPT_ALLOW_NAN_INF


local _TOKEN_UNKNOWN      = 0
local _TOKEN_NULL         = 1
local _TOKEN_BOOLEAN_TRUE = 2
local _TOKEN_BOOLEAN_FALSE= 3
local _TOKEN_NUMBER       = 4
local _TOKEN_STRING       = 5
local _TOKEN_ARRAY_OPEN   = 6
local _TOKEN_ARRAY_CLOSE  = 7
local _TOKEN_OBJECT_OPEN  = 8
local _TOKEN_OBJECT_CLOSE = 9
local _TOKEN_COMMA        = 10
local _TOKEN_COLON        = 11
local _TOKEN_EOF          = 12

local _EOF = {} -- Placeholder for end-of-file

local _ESCAPE_MAP = {
  ['"']  = '"',
  ['\\'] = '\\',
  ['/']  = '/',
  ['b']  = '\b',
  ['f']  = '\f',
  ['n']  = '\n',
  ['r']  = '\r',
  ['t']  = '\t',
}

local _UNESCAPE_MAP = {
  ['\b'] = '\\b',
  ['\f'] = '\\f',
  ['\n'] = '\\n',
  ['\r'] = '\\r',
  ['\t'] = '\\t',
  ['"']  = '\\"',
  ['\\'] = '\\\\',
}


local _err = function(msg, pos, str)
  local line, col = 1, 1
  for i=1,pos do
    if string_byte(str, i) == 10 then
      line = line + 1
      col = 1
    else
      col = col + 1
    end
  end
  error(string_format("%s at line %d col %d (char %d)", msg, line, col, pos + 1), 0)
end


local _is_opt_set = function(options_mask, opt)
  return bit_band(options_mask, opt) ~= 0
end


local _print_debug = function(options_mask, ...)
  if _is_opt_set(options_mask, _OPT_DEBUG) then
    print(string_format(...))
  end
end


local _utf8_char = function(val)
  if val < 0x80 then
    return string_char(val)
  elseif val < 0x800 then
    return string_char(bit_bor(0xc0, math_floor(val / 0x40)),
                       bit_bor(0x80, bit_band(val, 0x3f)))
  elseif val < 0x10000 then
    return string_char(bit_bor(0xe0, math_floor(val / 0x1000)),
                       bit_bor(0x80, bit_band(math_floor(val / 0x40), 0x3f)),
                       bit_bor(0x80, bit_band(val, 0x3f)))
  else
    return string_char(bit_bor(0xf0, math_floor(val / 0x40000)),
                       bit_bor(0x80, bit_band(math_floor(val / 0x1000), 0x3f)),
                       bit_bor(0x80, bit_band(math_floor(val / 0x40), 0x3f)),
                       bit_bor(0x80, bit_band(val, 0x3f)))
  end
end


local _encode_string = function(str, as_key)
  local res = {}
  local n = #str
  local i = 1
  while i <= n do
    local c = string_sub(str, i, i)
    local esc = _UNESCAPE_MAP[c]
    if esc then
      table_insert(res, esc)
    else
      local b = string_byte(c)
      if b < 0x20 or b == 0x7f then -- control characters
        table_insert(res, string_format("\\u%04x", b))
      else
        table_insert(res, c)
      end
    end
    i = i + 1
  end
  return '"' .. table_concat(res) .. '"'
end


local _encode_array
local _encode_object

local _encode_value = function(val, pretty, indent_level, as_key, seen_tables)
  local t = type(val)

  if t == "string" then
    return _encode_string(val, as_key)

  elseif t == "number" then
    if val ~= val or val == math_huge or val == -math_huge then -- NaN, Infinity, -Infinity
      return "null" -- JSON spec does not allow these
    end
    -- Check if it's an integer and within safe limits for precision
    if math_floor(val) == val and math_abs(val) <= _INT_MAX then
        return string_format("%.0f", val)
    else
        return string_format("%g", val) -- Use %g for general format, may use scientific notation
    end

  elseif t == "boolean" then
    return val and "true" or "false"

  elseif t == "table" then
    if seen_tables[val] then
      error("Cannot encode circularly referenced table")
    end
    seen_tables[val] = true

    -- Check if it's an array or object
    local is_array = false
    local max_idx = 0
    local count = 0
    for k, _ in pairs(val) do
      if type(k) == "number" and k >= 1 and math_floor(k) == k then
        if k > max_idx then max_idx = k end
      end
      count = count + 1
    end
    if max_idx == count and count > 0 then -- If all keys are sequential numbers starting from 1
        is_array = true
    elseif count == 0 then -- Empty table can be an empty array
        is_array = true
    end

    -- Try to detect if it should be an array by checking if all keys are numeric and sequential
    -- This is a common heuristic but not foolproof for Lua tables.
    -- If `val.is_json_array` is explicitly set, use that.
    if val.is_json_array == true then
        is_array = true
    elseif val.is_json_array == false then
        is_array = false
    end


    if is_array then
      return _encode_array(val, pretty, indent_level, seen_tables)
    else
      return _encode_object(val, pretty, indent_level, seen_tables)
    end

  elseif t == "nil" then
    return "null"

  else -- function, userdata, thread
    error(string_format("Cannot encode value of type '%s'", t))
  end
end


_encode_array = function(arr, pretty, indent_level, seen_tables)
  local res = {}
  local n = #arr
  local indent_str = pretty and string.rep(pretty.indent or "  ", indent_level) or ""
  local item_indent_str = pretty and string.rep(pretty.indent or "  ", indent_level + 1) or ""
  local newline = pretty and (pretty.newline or "\n") or ""
  local space = pretty and (pretty.space or " ") or ""

  if n == 0 then return "[]" end

  table_insert(res, "[")
  if pretty then table_insert(res, newline) end

  for i=1,n do
    if pretty then table_insert(res, item_indent_str) end
    table_insert(res, _encode_value(arr[i], pretty, indent_level + 1, false, seen_tables))
    if i < n then
      table_insert(res, ",")
    end
    if pretty then table_insert(res, newline) end
  end

  if pretty then table_insert(res, indent_str) end
  table_insert(res, "]")
  return table_concat(res)
end


_encode_object = function(obj, pretty, indent_level, seen_tables)
  local res = {}
  local first = true
  local indent_str = pretty and string.rep(pretty.indent or "  ", indent_level) or ""
  local item_indent_str = pretty and string.rep(pretty.indent or "  ", indent_level + 1) or ""
  local newline = pretty and (pretty.newline or "\n") or ""
  local space = pretty and (pretty.space or " ") or ""

  table_insert(res, "{")
  if pretty then table_insert(res, newline) end

  local keys_to_encode = {}
  for k, _ in pairs(obj) do
    if type(k) ~= "string" and type(k) ~= "number" then
      error(string_format("Cannot encode object with key of type '%s'", type(k)))
    end
    if obj.is_json_array and k == "is_json_array" then -- Skip our helper field
        -- do nothing
    else
        table_insert(keys_to_encode, k)
    end
  end

  if pretty and pretty.sort_keys then
    table.sort(keys_to_encode)
  end

  for _, k in ipairs(keys_to_encode) do
    local v = obj[k]
    if not first then
      table_insert(res, ",")
      if pretty then table_insert(res, newline) end
    end
    first = false

    if pretty then table_insert(res, item_indent_str) end
    table_insert(res, _encode_string(tostring(k), true))
    table_insert(res, ":" .. space)
    table_insert(res, _encode_value(v, pretty, indent_level + 1, false, seen_tables))
  end

  if pretty and not first then table_insert(res, newline) end -- Add newline only if there were items
  if pretty then table_insert(res, indent_str) end
  table_insert(res, "}")
  return table_concat(res)
end


json.encode = function(val, pretty_opts)
  local seen_tables = {}
  local pretty = nil
  if pretty_opts then
    if type(pretty_opts) == "boolean" and pretty_opts then
      pretty = { indent = "  ", newline = "\n", space = " ", sort_keys = false }
    elseif type(pretty_opts) == "string" then
      pretty = { indent = pretty_opts, newline = "\n", space = " ", sort_keys = false }
    elseif type(pretty_opts) == "table" then
      pretty = pretty_opts
      if pretty.indent == nil then pretty.indent = "  " end
      if pretty.newline == nil then pretty.newline = "\n" end
      if pretty.space == nil then pretty.space = " " end
      if pretty.sort_keys == nil then pretty.sort_keys = false end
    end
  end
  return _encode_value(val, pretty, 0, false, seen_tables)
end


local _lexer = function(str, options_mask)
  local i = 1
  local n = #str
  local current_token_type = _TOKEN_UNKNOWN
  local current_token_value = nil
  local current_token_pos = 0

  local _is_digit = function(c) return c >= '0' and c <= '9' end
  local _is_hex_digit = function(c) return _is_digit(c) or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F') end
  local _is_whitespace = function(c) return c == ' ' or c == '\t' or c == '\n' or c == '\r' end
  local _is_alpha = function(c) return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_' end
  local _is_alphanum = function(c) return _is_alpha(c) or _is_digit(c) end

  local _next_char = function()
    if i > n then return _EOF end
    local c = string_sub(str, i, i)
    i = i + 1
    return c
  end

  local _peek_char = function()
    if i > n then return _EOF end
    return string_sub(str, i, i)
  end

  local _skip_whitespace_and_comments = function()
    while true do
      local char = _peek_char()
      if char == _EOF then return end

      if _is_whitespace(char) then
        _next_char() -- consume whitespace
      elseif _is_opt_set(options_mask, _OPT_ALLOW_COMMENTS) then
        if char == '/' then
          local next_c = string_sub(str, i + 1, i + 1) -- peek next without advancing i yet
          if next_c == '/' then -- Single-line comment
            _next_char() -- consume '/'
            _next_char() -- consume '/'
            while _peek_char() ~= _EOF and _peek_char() ~= '\n' do
              _next_char()
            end
            if _peek_char() == '\n' then _next_char() end -- consume newline
          elseif next_c == '*' then -- Multi-line comment
            _next_char() -- consume '/'
            _next_char() -- consume '*'
            local found_end = false
            while _peek_char() ~= _EOF do
              if _next_char() == '*' and _peek_char() == '/' then
                _next_char() -- consume '/'
                found_end = true
                break
              end
            end
            if not found_end then _err("Unterminated multi-line comment", i -1 , str) end
          else
            return -- Not a comment, just a slash
          end
        else
          return -- Not whitespace or comment start
        end
      else
        return -- Not whitespace, and comments not allowed
      end
    end
  end


  local _read_string = function(quote_char)
    local res = {}
    local start_pos = i
    _next_char() -- consume opening quote
    while true do
      local char = _next_char()
      if char == _EOF then _err("Unterminated string", start_pos -1, str) end
      if char == quote_char then break end -- End of string
      if char == '\\' then
        local esc_char = _next_char()
        if esc_char == _EOF then _err("Unterminated string escape", i -1, str) end
        if esc_char == 'u' then
          local hex = ""
          for _=1,4 do
            local hc = _next_char()
            if hc == _EOF or not _is_hex_digit(hc) then
              _err("Invalid unicode escape sequence in string", i - 1 - #hex, str)
            end
            hex = hex .. hc
          end
          table_insert(res, _utf8_char(tonumber(hex, 16)))
        else
          local unescaped = _ESCAPE_MAP[esc_char]
          if not unescaped then _err("Invalid escape sequence in string: \\" .. esc_char, i - 2, str) end
          table_insert(res, unescaped)
        end
      else
        table_insert(res, char)
      end
    end
    return table_concat(res)
  end


  local _read_number = function()
    local num_str = ""
    local start_pos = i
    local c = _peek_char()

    -- Optional sign
    if c == '-' or c == '+' then
      num_str = num_str .. _next_char()
      c = _peek_char()
    end

    -- Hexadecimal
    if _is_opt_set(options_mask, _OPT_ALLOW_HEX_NUMBERS) and c == '0' and (string_sub(str, i+1, i+1) == 'x' or string_sub(str, i+1, i+1) == 'X') then
      num_str = num_str .. _next_char() -- 0
      num_str = num_str .. _next_char() -- x
      c = _peek_char()
      if not _is_hex_digit(c) then _err("Invalid hexadecimal number", start_pos, str) end
      while _is_hex_digit(c) do
        num_str = num_str .. _next_char()
        c = _peek_char()
      end
      return tonumber(num_str)
    end

    -- NaN, Infinity
    if _is_opt_set(options_mask, _OPT_ALLOW_NAN_INF) then
        if string_sub(str, i, i+2) == "NaN" then i=i+3; return 0/0; end
        if string_sub(str, i, i+7) == "Infinity" then i=i+8; return math_huge; end
        if string_sub(str, i, i+8) == "-Infinity" then i=i+9; return -math_huge; end
    end


    -- Integer part
    if not _is_digit(c) and c ~= '.' then _err("Invalid number", start_pos, str) end
    while _is_digit(c) do
      num_str = num_str .. _next_char()
      c = _peek_char()
    end

    -- Fractional part
    if c == '.' then
      num_str = num_str .. _next_char()
      c = _peek_char()
      if not _is_digit(c) then _err("Invalid number (no digits after decimal point)", start_pos, str) end
      while _is_digit(c) do
        num_str = num_str .. _next_char()
        c = _peek_char()
      end
    end

    -- Exponent part
    if c == 'e' or c == 'E' then
      num_str = num_str .. _next_char()
      c = _peek_char()
      if c == '-' or c == '+' then
        num_str = num_str .. _next_char()
        c = _peek_char()
      end
      if not _is_digit(c) then _err("Invalid number (exponent part is not a number)", start_pos, str) end
      while _is_digit(c) do
        num_str = num_str .. _next_char()
        c = _peek_char()
      end
    end

    local val = tonumber(num_str)
    if not val then _err("Invalid number format: " .. num_str, start_pos, str) end
    return val
  end


  local _read_keyword = function(expected, token_type)
    local start_pos = i
    for j=1, #expected do
      if _next_char() ~= string_sub(expected, j, j) then
        _err("Expected '" .. expected .. "'", start_pos, str)
      end
    end
    -- Check if it's followed by a non-alphanumeric character (or EOF)
    local next_c = _peek_char()
    if next_c ~= _EOF and _is_alphanum(next_c) then
        _err("Invalid keyword '" .. expected .. next_c .. "...'", start_pos, str)
    end
    return expected, token_type
  end


  local _read_unquoted_key = function()
    local key_str = ""
    local start_pos = i
    local c = _peek_char()
    if not (_is_alpha(c) or c == '$') then -- Must start with letter, _, or $
        _err("Invalid unquoted key", start_pos, str)
    end
    while _is_alphanum(c) or c == '$' do
        key_str = key_str .. _next_char()
        c = _peek_char()
    end
    if #key_str == 0 then _err("Empty unquoted key", start_pos, str) end
    return key_str
  end


  local _get_next_token = function()
    _skip_whitespace_and_comments()
    current_token_pos = i
    local char = _peek_char()

    if char == _EOF then
      current_token_type = _TOKEN_EOF
      current_token_value = nil
      return
    end

    if char == '{' then _next_char(); current_token_type = _TOKEN_OBJECT_OPEN; current_token_value = "{"; return end
    if char == '}' then _next_char(); current_token_type = _TOKEN_OBJECT_CLOSE; current_token_value = "}"; return end
    if char == '[' then _next_char(); current_token_type = _TOKEN_ARRAY_OPEN; current_token_value = "["; return end
    if char == ']' then _next_char(); current_token_type = _TOKEN_ARRAY_CLOSE; current_token_value = "]"; return end
    if char == ',' then _next_char(); current_token_type = _TOKEN_COMMA; current_token_value = ","; return end
    if char == ':' then _next_char(); current_token_type = _TOKEN_COLON; current_token_value = ":"; return end

    if char == '"' then
      current_token_value = _read_string('"')
      current_token_type = _TOKEN_STRING
      return
    end

    if _is_opt_set(options_mask, _OPT_ALLOW_SINGLE_QUOTES) and char == "'" then
      current_token_value = _read_string("'")
      current_token_type = _TOKEN_STRING
      return
    end

    if _is_digit(char) or char == '-' or char == '+' or
       (_is_opt_set(options_mask, _OPT_ALLOW_HEX_NUMBERS) and char == '0') or
       (_is_opt_set(options_mask, _OPT_ALLOW_NAN_INF) and (char == 'N' or char == 'I')) then
      current_token_value = _read_number()
      current_token_type = _TOKEN_NUMBER
      return
    end

    if char == 'n' then
      current_token_value, current_token_type = _read_keyword("null", _TOKEN_NULL)
      return
    end
    if char == 't' then
      current_token_value, current_token_type = _read_keyword("true", _TOKEN_BOOLEAN_TRUE)
      return
    end
    if char == 'f' then
      current_token_value, current_token_type = _read_keyword("false", _TOKEN_BOOLEAN_FALSE)
      return
    end

    if _is_opt_set(options_mask, _OPT_ALLOW_UNQUOTED_KEYS) and (_is_alpha(char) or char == '$') then
        -- This could be an unquoted key. We'll treat it as a string token for now.
        -- The parser will decide if it's valid in context (e.g., before a colon).
        current_token_value = _read_unquoted_key()
        current_token_type = _TOKEN_STRING -- Treat as string for simplicity in parser
        return
    end

    _err("Unexpected character: '" .. char .. "'", i, str)
  end

  -- Initialize the first token
  _get_next_token()

  return {
    next = _get_next_token,
    peek_type = function() return current_token_type end,
    peek_value = function() return current_token_value end,
    peek_pos = function() return current_token_pos end,
    is_eof = function() return current_token_type == _TOKEN_EOF end,
    get_current_pos_for_error = function() return i end, -- Current position in string
  }
end


local _parse_value
local _parse_array
local _parse_object

_parse_value = function(lexer, options_mask, path)
  local token_type = lexer.peek_type()
  local token_value = lexer.peek_value()
  local token_pos = lexer.peek_pos()

  _print_debug(options_mask, "parse_value: token_type=%d, token_value=%s, path=%s",
               token_type, tostring(token_value), path)

  if token_type == _TOKEN_STRING then
    lexer.next()
    return token_value, _TYPE_STRING
  elseif token_type == _TOKEN_NUMBER then
    lexer.next()
    return token_value, _TYPE_NUMBER
  elseif token_type == _TOKEN_BOOLEAN_TRUE then
    lexer.next()
    return true, _TYPE_BOOLEAN
  elseif token_type == _TOKEN_BOOLEAN_FALSE then
    lexer.next()
    return false, _TYPE_BOOLEAN
  elseif token_type == _TOKEN_NULL then
    lexer.next()
    if _is_opt_set(options_mask, _OPT_ALLOW_NIL_VALUES) then
        return nil, _TYPE_NULL
    else
        return json.null, _TYPE_NULL -- Use json.null placeholder if nils are not allowed
    end
  elseif token_type == _TOKEN_ARRAY_OPEN then
    return _parse_array(lexer, options_mask, path)
  elseif token_type == _TOKEN_OBJECT_OPEN then
    return _parse_object(lexer, options_mask, path)
  else
    _err("Unexpected token type: " .. token_type, token_pos, lexer.str_ref)
  end
end


_parse_array = function(lexer, options_mask, path)
  _print_debug(options_mask, "parse_array: path=%s", path)
  lexer.next() -- consume '['
  local arr = {}
  local arr_idx = 1

  while lexer.peek_type() ~= _TOKEN_ARRAY_CLOSE do
    local item_path = path .. "[" .. arr_idx .. "]"
    local val, val_type = _parse_value(lexer, options_mask, item_path)
    arr[arr_idx] = val
    arr_idx = arr_idx + 1

    local next_token_type = lexer.peek_type()
    if next_token_type == _TOKEN_COMMA then
      lexer.next() -- consume ','
      -- Handle trailing comma if allowed
      if _is_opt_set(options_mask, _OPT_ALLOW_TRAILING_COMMA) and lexer.peek_type() == _TOKEN_ARRAY_CLOSE then
        break
      end
      if lexer.peek_type() == _TOKEN_ARRAY_CLOSE then -- e.g. [1,2,]
          if not _is_opt_set(options_mask, _OPT_ALLOW_TRAILING_COMMA) then
             _err("Trailing comma in array not allowed", lexer.peek_pos(), lexer.str_ref)
          end
          -- If trailing commas are allowed, we effectively ignore it by breaking or letting the loop condition handle it.
      end
    elseif next_token_type ~= _TOKEN_ARRAY_CLOSE then
      _err("Expected ',' or ']' in array", lexer.peek_pos(), lexer.str_ref)
    end
  end

  if lexer.peek_type() ~= _TOKEN_ARRAY_CLOSE then
    _err("Unclosed array", lexer.peek_pos(), lexer.str_ref)
  end
  lexer.next() -- consume ']'
  arr.is_json_array = true -- Mark this table as originating from a JSON array
  return arr, _TYPE_ARRAY
end


_parse_object = function(lexer, options_mask, path)
  _print_debug(options_mask, "parse_object: path=%s", path)
  lexer.next() -- consume '{'
  local obj = {}
  if _is_opt_set(options_mask, _OPT_PRESERVE_ORDER) then
    setmetatable(obj, { __pairs = function(t)
      local i = 0
      local n = #t._keys
      return function()
        i = i + 1
        if i <= n then
          local k = t._keys[i]
          return k, t[k]
        end
      end
    end, _keys = {} })
  end

  while lexer.peek_type() ~= _TOKEN_OBJECT_CLOSE do
    local key_token_type = lexer.peek_type()
    local key_token_value = lexer.peek_value()
    local key_token_pos = lexer.peek_pos()

    if key_token_type ~= _TOKEN_STRING then
      _err("Expected string for object key", key_token_pos, lexer.str_ref)
    end
    lexer.next() -- consume key string

    if lexer.peek_type() ~= _TOKEN_COLON then
      _err("Expected ':' after object key", lexer.peek_pos(), lexer.str_ref)
    end
    lexer.next() -- consume ':'

    local item_path = path .. "." .. key_token_value
    local val, val_type = _parse_value(lexer, options_mask, item_path)
    obj[key_token_value] = val
    if obj._keys then table_insert(obj._keys, key_token_value) end


    local next_token_type = lexer.peek_type()
    if next_token_type == _TOKEN_COMMA then
      lexer.next() -- consume ','
      -- Handle trailing comma if allowed
      if _is_opt_set(options_mask, _OPT_ALLOW_TRAILING_COMMA) and lexer.peek_type() == _TOKEN_OBJECT_CLOSE then
        break
      end
       if lexer.peek_type() == _TOKEN_OBJECT_CLOSE then -- e.g. {"a":1,"b":2,}
          if not _is_opt_set(options_mask, _OPT_ALLOW_TRAILING_COMMA) then
             _err("Trailing comma in object not allowed", lexer.peek_pos(), lexer.str_ref)
          end
      end
    elseif next_token_type ~= _TOKEN_OBJECT_CLOSE then
      _err("Expected ',' or '}' in object", lexer.peek_pos(), lexer.str_ref)
    end
  end

  if lexer.peek_type() ~= _TOKEN_OBJECT_CLOSE then
    _err("Unclosed object", lexer.peek_pos(), lexer.str_ref)
  end
  lexer.next() -- consume '}'
  obj.is_json_array = false -- Mark this table as originating from a JSON object
  return obj, _TYPE_OBJECT
end


json.decode = function(str, opts)
  if type(str) ~= "string" then
    error("Expected string argument to json.decode", 2)
  end

  local options_mask = _DEFAULT_OPTIONS
  if type(opts) == "table" then
    if opts.debug then options_mask = bit_bor(options_mask, _OPT_DEBUG) end
    if opts.allow_nil_values then options_mask = bit_bor(options_mask, _OPT_ALLOW_NIL_VALUES) end
    if opts.preserve_order then options_mask = bit_bor(options_mask, _OPT_PRESERVE_ORDER) end
    if opts.allow_trailing_comma == false then options_mask = bit_band(options_mask, bit_bnot(_OPT_ALLOW_TRAILING_COMMA)) end
    if opts.allow_comments == false then options_mask = bit_band(options_mask, bit_bnot(_OPT_ALLOW_COMMENTS)) end
    if opts.allow_hex_numbers == false then options_mask = bit_band(options_mask, bit_bnot(_OPT_ALLOW_HEX_NUMBERS)) end
    if opts.allow_unquoted_keys == false then options_mask = bit_band(options_mask, bit_bnot(_OPT_ALLOW_UNQUOTED_KEYS)) end
    if opts.allow_single_quotes == false then options_mask = bit_band(options_mask, bit_bnot(_OPT_ALLOW_SINGLE_QUOTES)) end
    if opts.force_array then options_mask = bit_bor(options_mask, _OPT_FORCE_ARRAY) end
    if opts.force_object then options_mask = bit_bor(options_mask, _OPT_FORCE_OBJECT) end
    if opts.allow_nan_inf == false then options_mask = bit_band(options_mask, bit_bnot(_OPT_ALLOW_NAN_INF)) end
    if opts.strict then options_mask = _OPT_STRICT end -- Strict overrides all extensions
  end

  if _is_opt_set(options_mask, _OPT_STRICT) then
      options_mask = _OPT_STRICT -- Only strict options apply
  end

  _print_debug(options_mask, "Decoding string: %s", str)
  _print_debug(options_mask, "Options mask: %d", options_mask)

  local lexer = _lexer(str, options_mask)
  lexer.str_ref = str -- Store a reference to the original string for error reporting

  local value, value_type
  if _is_opt_set(options_mask, _OPT_FORCE_ARRAY) then
      if lexer.peek_type() ~= _TOKEN_ARRAY_OPEN then _err("Expected array at top level (force_array)", lexer.peek_pos(), str) end
      value, value_type = _parse_array(lexer, options_mask, "$")
  elseif _is_opt_set(options_mask, _OPT_FORCE_OBJECT) then
      if lexer.peek_type() ~= _TOKEN_OBJECT_OPEN then _err("Expected object at top level (force_object)", lexer.peek_pos(), str) end
      value, value_type = _parse_object(lexer, options_mask, "$")
  else
      value, value_type = _parse_value(lexer, options_mask, "$")
  end


  -- Check for extra tokens after the main value
  lexer.next() -- This should consume the last token of the value (e.g. ']', '}')
  if not lexer.is_eof() then -- If not EOF, there's extra stuff
    -- Try to skip whitespace/comments one last time
    local pre_skip_pos = lexer.get_current_pos_for_error()
    local lexer_next_fn = lexer.next -- Temporarily store the next function
    lexer.next = function() end -- Nullify next so skip_whitespace_and_comments doesn't advance past the offending token
    _skip_whitespace_and_comments() -- Call our local skip function
    lexer.next = lexer_next_fn -- Restore it

    if not lexer.is_eof() then -- Still not EOF after skipping? Then it's an error.
        _err("Unexpected token after top-level value", lexer.peek_pos(), str)
    end
  end

  return value
end

-- Placeholder for json.null if nils are not allowed in tables
json.null = setmetatable({}, { __tostring = function() return "json.null" end })

return json

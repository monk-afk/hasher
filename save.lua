--==[[=======================]]==--
--==[[ hasher       save.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--
local string = string

local clip = dofile("clip.lua")

-- manage or create open files
local files_by_prefix = {}
local function get_file(ref)
  if not files_by_prefix[ref] then
    files_by_prefix[ref] = io.open("./data/" .. ref, "ab")
  end
  return files_by_prefix[ref]
end


-- faster than string.sub
local function string_sub(str, n, p)
  if n > 0 and p <= #str then
      return string.char(string.byte(str, n, p))
  else return str end
end


local function binary_conversion(hash_string)
  -- traverse the string, sort by 3 digit prefixes
  for i = 1, #hash_string - 128 , 128 do
    local frame_hashseed = string_sub(hash_string, i, i + 127)
    local file_reference = string_sub(frame_hashseed, 1, 3)
    local file = get_file(file_reference)

    -- convert every 8 characters to binary for storage
    for c = 1, #frame_hashseed, 8 do
      local hex_byte = string_sub(frame_hashseed, c, c+7)
      local hex_int = tonumber(hex_byte, 16)
      local hex_bin = string.pack(">I4", hex_int)
      file:write(hex_bin)
    end
  end
end


local function close_files()
  for _, file in pairs(files_by_prefix) do
    file:close()
  end
end


-- basically the same as init.lua 
local function writers_block()
  local pipe_file = "/tmp/fifo_" .. clip.writer
  local fifo = io.open(pipe_file, "r")
  if fifo then
  -- process will pause at the pipe until data is received
    for chunk in fifo:lines() do
      if chunk == "kill" then
        os.remove(pipe_file)
        close_files()
        return nil

      elseif #chunk >= 64 then
    -- break the pipe otherwise parent never detatches
        os.remove(pipe_file)
        fifo:close()
        binary_conversion(chunk)
        return writers_block() -- loop back
      end
    end

  elseif not fifo then
    os.execute("mkfifo " .. pipe_file)
    return writers_block()
  end
end

writers_block()
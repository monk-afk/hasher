--==[[=======================]]==--
--==[[ hasher     writer.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

local string = string

local bin_cache = {}
-- manage or create open files
local function write_to_file(bin_cache)
  for ref, data in pairs(bin_cache) do
    io.open("data/" .. ref, "ab"):write(table.concat(data)):close()
  end

  for k in pairs(bin_cache) do
    bin_cache[k] = nil
  end
end


local function append_binary_data(file_ref, bin_data)
  if not (file_ref and bin_data) then
    return write_to_file(bin_cache)
  end
  bin_cache[file_ref] = bin_cache[file_ref] or {}
  table.insert(bin_cache[file_ref], bin_data)
end


-- faster than string.sub
local function string_sub(str, n, p)
  if n > 0 and p <= #str then
      return string.char(string.byte(str, n, p))
  else return nil end
end


local function binary_conversion(hash_string)
  -- traverse the string, sort by 3 digit prefixes
  for i = 1, #hash_string - 128, 128 do
    local hash_segment = string_sub(hash_string, i, i + 127)
    -- convert every 8 characters to binary for storage
    for c = 1, #hash_segment, 8 do
      append_binary_data(
        string_sub(hash_segment, 1, 3),
          string.pack(">I4", tonumber(string_sub(hash_segment, c, c + 7), 16)
        )
      )
    end
  end
  append_binary_data()
end


-- basically the same as init.lua
local function writers_block()
  local pipe_file = "/tmp/fifo_" .. arg[1]
  local fifo = io.open(pipe_file, "r")

  if fifo then
  -- process will pause at the pipe until data is received
    for chunk in fifo:lines() do
      if chunk == "kill" then
        os.remove(pipe_file)
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
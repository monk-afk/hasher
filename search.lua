--==[[=======================]]==--
--==[[ hasher     search.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

-- requires Lua >= 5.3 to use string.pack with unsigned integer

local function hex2bin(hash_str)  -- hexadecimal to binary
  local bin = ""
  for c = 1, #hash_str, 8 do
    local hex_str = string.sub(hash_str, c, c+7)
    local hex_int = tonumber(hex_str, 16)
    if not hex_int then error("Invalid hexadecimal string: " .. hex_str) end
    bin = bin .. string.pack(">I4", hex_int)
  end
  return bin
end

local function bin2hex(bin_str)  -- binary to hexadecimal
  local hash = ""
  for b = 1, #bin_str, 4 do
    local four_byte = string.sub(bin_str, b, b+3)
    local num = string.unpack(">I4", four_byte)
    hash = hash .. string.format("%08x", num)
  end
  return hash
end

local function dump_data(t)
  io.stdout:write("Pattern\tMatches\n")
  for index, matches in pairs(t) do
    if matches > 0 then
      io.stdout:write(index, "\t", matches, "\n")
    end
  end
end

local function search_archive(target_hash)
  local data_dir = "./data/"  -- this needs to be created if it doesn't exist
  local binary_data_file = string.sub(target_hash, 1, 2)
  local path = data_dir..binary_data_file
  local file = io.open(path, "rb")

  if file and target_hash then
    local chunk_size = 8192  -- read 256 bytes from each file
    local target_bin = hex2bin(target_hash)  -- convert target hash to binary

    local separate_hash = {}
    for c = 1, #target_hash do
      local index = string.sub(target_hash, 1, c + 2)
      separate_hash[index] = 0
    end

    while true do
      local binary_chunk = file:read(chunk_size)
      if not binary_chunk then break end

      for i = 1, #binary_chunk, 64 do  -- read 64 bytes at a time from each chunck
        local bin_hash = binary_chunk:sub(i, i+31)  -- the first 32 binary bytes is the hash
        local bin_seed = binary_chunk:sub(i+32, i+63)  -- the last 32 are the seed
        if #bin_seed < 32 or #bin_hash < 32 then break end

        local archive_seed = bin2hex(bin_seed)
        local archive_hash = bin2hex(bin_hash)

        for c = 1, #archive_hash do
          local index = string.sub(archive_hash, 1, c + 2)
    
          if separate_hash[index] then
            separate_hash[index] = separate_hash[index] + 1
          end
        end
      end
    end
    dump_data(separate_hash)

    file:close()
  elseif not file then
    io.stdout:write("Missing archive: ", path, "\n"):flush()
  elseif not target_hash then
    io.stdout:write("No target hash received."):flush()
  end
end

if arg[0] == "search.lua" then -- can be used from command line or as module to init.lua
  return search_archive(arg[1])
else
  return search_archive
end


--==[[================================================================================]]==--
--==[[ MIT License                                                                    ]]==--
--==[[                                                                                ]]==--
--==[[ Copyright (c) 2024  monk                                                       ]]==--
--==[[                                                                                ]]==--
--==[[ Permission is hereby granted, free of charge, to any person obtaining a copy   ]]==--
--==[[ of this software and associated documentation files (the "Software"), to deal  ]]==--
--==[[ in the Software without restriction, including without limitation the rights   ]]==--
--==[[ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      ]]==--
--==[[ copies of the Software, and to permit persons to whom the Software is          ]]==--
--==[[ furnished to do so, subject to the following conditions:                       ]]==--
--==[[                                                                                ]]==--
--==[[ The above copyright notice and this permission notice shall be included in all ]]==--
--==[[ copies or indextantial portions of the Software.                               ]]==--
--==[[                                                                                ]]==--
--==[[ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     ]]==--
--==[[ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       ]]==--
--==[[ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    ]]==--
--==[[ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         ]]==--
--==[[ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  ]]==--
--==[[ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  ]]==--
--==[[ SOFTWARE.                                                                      ]]==--
--==[[================================================================================]]==--
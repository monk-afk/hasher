--==[[=======================]]==--
--==[[ hasher     search.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

-- requires Lua >= 5.3 to use string.pack with unsigned integer

local bin = {""}
local function hex2bin(hash_str)  -- hexadecimal to binary
  for x = 1, #bin do bin[x] = nil end
  for c = 1, #hash_str, 16 do
    bin[#bin+1] =
      string.pack(">I8",
        tonumber(string.sub(
          hash_str, c, c+15), 16))
  end
  return table.concat(bin)
end

local hash = {""}
local function bin2hex(bin_str)  -- binary to hexadecimal
  for x = 1, #hash do hash[x] = nil end
  for b = 1, #bin_str, 8 do
    hash[#hash+1] =
      string.format("%016x",
        string.unpack(">I8",
          string.sub(bin_str, b, b+7)))
  end
  return table.concat(hash)
end

local function out(...)
  return io.stdout:write(table.concat({...}), "\n"):flush()
end

local function dump_data(t)
  out("Matches\tPattern")
  for i = 1, #t do
    for index, matches in pairs(t[i]) do
      if #matches > 1 then
        out(matches[1], "\t", index)
        -- uncomment this one to print the matches (lots of output)
        -- out(matches[1], "\t", index, "\n", table.concat(matches, "\n"))
      end
    end
  end
end

local function search_archive(target_hash)
  local hex_length = 3
  local data_dir = "./data/"  -- this needs to be created if it doesn't exist
  local binary_data_file = string.sub(target_hash, 1, hex_length)
  local path = data_dir..binary_data_file
  local file = io.open(path, "rb")

  if file and target_hash then
    local chunk_size = 512  -- read Nkb bytes from each file
    local target_bin = hex2bin(target_hash)  -- convert target hash to binary

    local separate_hash = {} -- create table of letters from target hash
    for c = 1, #target_hash do
      local index = string.sub(target_hash, 1, c + hex_length)
      separate_hash[c] = {
        [index] = {[1]=0}
      }
    end

    while true do
      local binary_chunk = file:read(chunk_size)
      if not binary_chunk then break end

      for i = 1, #binary_chunk, 64 do  -- read 64 bytes at a time from each chunck
        local bin_hash = binary_chunk:sub(i, i+31)  -- the first 32 binary bytes is the hash
        local bin_seed = binary_chunk:sub(i+32, i+63)  -- the last 32 are the seed
        if #bin_hash < 32 or #bin_seed < 32 then break end

        local archive_hash = bin2hex(bin_hash)

        if archive_hash == target_hash then
          local archive_seed = bin2hex(bin_seed)
          out("Hash: "..archive_hash)
          out("Seed: "..archive_seed)
          return
        end

        for c = 1, #archive_hash do
          local index = string.sub(archive_hash, 1, c + hex_length)

          if separate_hash[c][index] then
            local count = separate_hash[c][index][1]
            separate_hash[c][index][1] = count + 1
            table.insert(separate_hash[c][index], archive_hash.." "..bin2hex(bin_seed))
          end
        end
      end
    end
    file:close()
    dump_data(separate_hash)
  elseif not file then
    out("Missing archive: ", path)
  elseif not target_hash then
    out("No target hash received.")
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
--==[[ Copyright © 2024  monk                                                         ]]==--
--==[[                                                                                ]]==--
--==[[ Permission is hereby granted, free of charge, to any person obtaining a copy   ]]==--
--==[[ of this software and associated documentation files (the "Software"), to deal  ]]==--
--==[[ in the Software without restriction, including without limitation the rights   ]]==--
--==[[ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      ]]==--
--==[[ copies of the Software, and to permit persons to whom the Software is          ]]==--
--==[[ furnished to do so, subject to the following conditions:                       ]]==--
--==[[                                                                                ]]==--
--==[[ The above copyright notice and this permission notice shall be included in all ]]==--
--==[[ copies or substantial portions of the Software.                                ]]==--
--==[[                                                                                ]]==--
--==[[ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     ]]==--
--==[[ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       ]]==--
--==[[ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    ]]==--
--==[[ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         ]]==--
--==[[ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  ]]==--
--==[[ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  ]]==--
--==[[ SOFTWARE.                                                                      ]]==--
--==[[================================================================================]]==--
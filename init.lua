--==[[=======================]]==--
--==[[ hasher       init.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

local string, table = string, table
local add_bytes, calculate_hps = dofile("stats.lua")

local bin_cache = {}
-- manage or create open files
local function write_to_file(bin_cache)
  for ref, data in pairs(bin_cache) do
    local file = io.open("data/" .. ref, "ab")
    file:write(table.concat(data))
    file:close()
  end
  -- clear the cache after writing to files
  for k in pairs(bin_cache) do
    bin_cache[k] = nil
  end
end


-- closure to track bytes in cache
local function byte_count()
  local bytes = 0
  return function(o)
    bytes = o and bytes + o or 0
    add_bytes(o)
    return bytes
  end
end
local count_cached_bytes = byte_count()


-- appending binary data to the cache
local function append_binary_data(file_ref, bin_str)
  bin_cache[file_ref] = bin_cache[file_ref] or {}
  table.insert(bin_cache[file_ref], bin_str)

  -- if we hit 2mb of data, write it to a file
  if count_cached_bytes(#bin_str) >= 8388608 then
    return write_to_file(bin_cache)
  end
end


-- hash to binary
local function convert_to_binary(hash)
  for x = 1, #hash, 2 do
    local file_ref = string.sub(hash[x], 1, 3)
    -- append first sequence of bytes, which is the hash
    for c = 1, 58, 16 do
      append_binary_data(file_ref,
        string.pack(">I16",
          tonumber(string.sub(hash[x], c, c + 15), 16)))

      --[[ -- uncommenting this will append as ASCII text
      append_binary_data(file_ref,
        string.sub(hash[x], c, c + 15), 16)
      ]]
    end
    -- follow hash with the seed
    for c = 1, 58, 16 do
      append_binary_data(file_ref,
        string.pack(">I16",
          tonumber(string.sub(hash[x+1], c, c + 15), 16)))

      --[[
      append_binary_data(file_ref,
        string.sub(hash[x+1], c, c + 15))
      ]] -- make sure to comment out the binary conversion
    end
  end
end


-- perform hashing and sliding windows
local sha256 = dofile("sha256.lua")

local function roll_hash(seed, hash)

  for i = 1, #seed - 31 do
    local frame_seed = {}

    for j = i, i + 31 do
      frame_seed[#frame_seed + 1] = seed[j]
    end

    local frame_seed = table.concat(frame_seed)
    local frame_hash = sha256(frame_seed)

    hash[#hash + 1] = frame_hash
    hash[#hash + 1] = frame_seed
  end
  return hash
end


-- generate randomized hex seed
local function rbyte(b)
  local io_file = io.open("/dev/random", "rb")
  local rnd
  while true do
    rnd = string.byte(io_file:read(b))
    if rnd >= 0 and rnd <= 255 then
      io_file:close()
      return rnd
    end
  end
end


-- create hex table of our static data
local hex_table = {}
for x = 0, 255 do
  hex_table[x] = string.format("%02x", x)
end


-- hex array string with minimal entropy usage
local function grow_seed(seed)
  for f = 1, 64 do -- initial first hex string random bytes
    seed[f] = hex_table[rbyte(1)]
  end

  for x = 1, 16351 do -- all hex values for all bytes of a rolling window
    local int = tonumber(seed[x], 16)
    local hexinc = (int + 1) % (255 + 1)
    local newhex = hex_table[hexinc]
    seed[#seed+1] = newhex
  end
  return seed
end

-- main function to orchestrate everything
local function main()
  local seed_table = {}
  local hash_table = {}

  while dofile("signal.lua") do
    grow_seed(seed_table)
    roll_hash(seed_table, hash_table)
    convert_to_binary(hash_table)
    write_to_file(bin_cache)

    -- clear the hash and seed tables to free memory
    for n = 1, #hash_table do
      hash_table[n] = nil
      seed_table[n] = nil
    end

    calculate_hps()
  end
end

io.open("signal.lua", "w"):write("return true"):close()

main()


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
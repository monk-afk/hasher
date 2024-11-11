--==[[=======================]]==--
--==[[ hasher      spawn.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

local clip = dofile("clip.lua")

-- pre-construct the table of hex bytes
local hex_table = {"00"}
local string_format = string.format
for x = 0,255 do
  hex_table[x] = string_format("%02x", x)
end

local function rbyte(b)
  local io_file = io.open("/dev/random", "rb")
  while true do
    local rnd = string.byte(io_file:read(b))
    if rnd >= 0 and rnd <= 255 then
      io_file:close()
      return rnd
    end
  end
end

local function pipe_closure(spawn_id)
  local filename = "/tmp/fifo_" .. spawn_id

  return function(action, data)
    if action == "write" then
      os.execute("mkfifo " .. filename)
      local file = io.open(filename, "w+")

      if not file then 
        error("Failed to open pipe")
      end
      file:write(data, "\n"):close()

    elseif action == "close" then
      os.remove(filename)  -- remove the FIFO file
    end
  end
end


local sha256 = dofile("sha256.lua")
-- cycle from 1 to the last starting position for a 64-byte frame
local function roll_hash(seed, hash)
    local seed_len = #seed
    for i = 1, seed_len - 31 do

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

local function main()
  local batch = tonumber(clip.batch) or 1

  local seed_table = {}
  local hash_table = {}
  for bat = math.max(batch, 1), 1, -1 do -- incase we select 0
    grow_seed(seed_table)
    roll_hash(seed_table, hash_table)

    local pipe = pipe_closure(clip.spawn)
    pipe("write", table.concat(hash_table))
    pipe("close")

    for n = 1, #hash_table do
      hash_table[n] = nil
      seed_table[n] = nil
    end
  end

  if batch == 0 then -- for infinite hashing
    return main()
  end

   -- tell the parent when work is done
  local filename = "/tmp/fifo_" .. clip.spawn
  local file = io.open("/tmp/fifo_" .. clip.spawn, "w+")
  file:write("kill\n"):close()
end

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
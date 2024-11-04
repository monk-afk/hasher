--==[[=======================]]==--
--==[[ hasher       init.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

local function save_data(file_ref, hash_bin)
  local path = "./data/"..file_ref
  local file = io.open(path, "ab")
  file:write(hash_bin)
  file:flush()
  file:close()
end

local add_bytes, calculate_hps = dofile("stats.lua")

local string_sub = string.sub
local string_pack = string.pack
local function binary_conversion(serialized_data)  -- converts serial data into binary
  -- deserialize into tables 2 digix prefixes (aa, ab, ac, ...)
  for hash_prefix, hash_concat in serialized_data:gmatch("%[(%x+)%]%{(%x+)%}") do
    local hash_bin = ""

    for c = 1, #hash_concat, 8 do
      local hex_byte = string_sub(hash_concat, c, c+7)
      local hex_int  = tonumber(hex_byte, 16)
            hash_bin = hash_bin .. string_pack(">I4", hex_int)
    end
    -- each prefix contains the concatenated hashes in binary
    save_data(hash_prefix, hash_bin)
    add_bytes(#hash_bin)
  end
  calculate_hps()
end


local function process_work(spawn_que)
  local recurse_flag
  for id, worker in pairs(spawn_que) do
    if worker and worker.status then
      local fifo = io.open(worker.fifo_pipe_id, "r")
      if fifo then
         -- serialized data comes in one line per batch
        for chunk in fifo:lines() do
          if chunk == "kill" then
            spawn_que[id] = false
            worker = false
          elseif #chunk >= 64 then
            binary_conversion(chunk)
          else
            spawn_que[id] = false
            worker = false
          end
        end
      end
    end
    if worker then
      recurse_flag = true
    end
  end
  if recurse_flag then
    os.execute("sleep 0.1")
    return process_work(spawn_que)
  end
end


local function activate_spawns(spawn_que)
  for id, userdata in pairs(spawn_que) do
      userdata.status = io.popen(userdata.spawn_string)
  end
  return process_work(spawn_que)
end


local function spawner(num_spawns, batch, cycle, frame_size)
  local spawn_que = {}
  for n = 1, num_spawns do

    local spawn = {id}
    local spawn_id = tostring(spawn):sub(12)
    local filename = "/tmp/fifo_" .. spawn_id

    spawn = {
      status = false,
      fifo_pipe_id = filename,
      spawn_string = string.format(
          "lua spawn.lua batch=%d cycle=%d frame=%d spawn=%s",
            batch, cycle, frame_size, spawn_id)
    }
    spawn_que[spawn_id] = spawn
  end
  return activate_spawns(spawn_que)
end


local function main()
  local clip = {} -- https://github.com/monk-afk/various/blob/main/lua/clip.lua
  -- evaluate argumets
  clip[0] = string.gsub(arg[0], "^([%w/]-/?)([%w%.]+)$",
      function(path, file)
        clip[file] = path
        return file, path
      end)
  for p = 1, #arg do
    clip[p] = string.gsub(arg[p], "%-*([%w-]+)=?([%s%S]*)",
      function(param, val)
        clip[param] = val == "" or tonumber(val) or val
        return param, val
      end)
  end

  local num_spawns = tonumber(clip.spawn) or 1 -- sub-processes
  local frame_size = math.max(tonumber(clip.frame) or 2, 2) -- hex digits to iterate
  local cycle = tonumber(clip.cycle) or 1 -- 1 cycle does all 256 hex digits
  local batch = tonumber(clip.batch) or 1 -- batch of cycles

  spawner(num_spawns, batch, cycle, frame_size)

  calculate_hps(true) -- true forces print

  if clip.target then -- search for hash target if provided from command line
    io.stdout:write("Searching for " .. clip.target .. " in archive\n"):flush()
    dofile("./search.lua")(clip.target)
  end
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

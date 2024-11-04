--==[[=======================]]==--
--==[[ hasher      spawn.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

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


local function rbyte(b)
  local io_file = io.open("/dev/random", "rb")
  local rnd = io_file:read(b)
  io_file:close()
  return rnd
end


local function bin2int(bin_str, b)  -- binary bytes to hex integer (00 = 0 , ff = 255)
  local num = 0
  for i = 1, b do
    num = num * 256 + bin_str:byte(i)
  end
  return num
end


local function int2hex(num, fs)  -- integer value to hex digits
  local hex = string.format("%0" .. fs .. "x", num)
  return hex
end


local function pipe_closure(spawn_id)
  local filename = "/tmp/fifo_" .. spawn_id
  os.execute("mkfifo " .. filename)
  return function(action, data)
    if action == "write" then
      local file = io.open(filename, "w+")

      if not file then
        error("Failed to open pipe for writing")
      end
      file:write(data, "\n")
      file:flush()
      file:close()
    elseif action == "close" then
      os.remove(filename)  -- remove the FIFO file
    end
  end
end
local pipe = pipe_closure(clip.spawn)

local serial_hash = dofile("serialize.lua")

local function generate_hex_strings(frame_size, bytes, max_hex, len, cycle, hex_array)
  for cy = 1, cycle do
    local seed = {}
    for f = 1, len, frame_size do
      seed[#seed + 1] = bin2int(rbyte(bytes), bytes)
    end
      -- for each frame of the hex string, increment the hex digit by 1
    for h = 0, max_hex do
      local next_hex = ""
      for w = 1, #seed do
        local int = seed[w]
        local hex = int2hex(int, frame_size)
        next_hex = next_hex .. hex
        seed[w] = (int + 1) % (max_hex + 1)  -- if we go over max_hex restart from 0
      end
      table.insert(hex_array, next_hex)
    end
  end

  local serial_table = serial_hash(hex_array)
  local serial_data = table.concat(serial_table)
  pipe("write", serial_data)
end


local function main()
  local frame_size = tonumber(clip.frame) or 2
  local batch     = tonumber(clip.batch) or 1
  local cycle     = tonumber(clip.cycle) or 1

  local bytes = frame_size // 2
  local bits = 4 * frame_size
  local max_hex = 2 ^ bits - 1
  local len = 64

  for bat = 1, batch do
    generate_hex_strings(frame_size, bytes, max_hex, len, cycle, {})
  end
  pipe("write", "kill")
  pipe("close")
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
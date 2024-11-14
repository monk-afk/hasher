--==[[=======================]]==--
--==[[ hasher      stats.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

-- get the timestamp with millisecond
local function ct()
  local handle = io.popen("date +%s.%N")
  local result = handle:read("*a")
  handle:close()
  return tonumber(result)
end


-- number to readable format
local function convert_value(value)
  local units = {"B", "KB", "MB", "GB", "TB"}
  local i = 1
  while value >= 1024 and i < #units do
    value = value / 1024
    i = i + 1
  end
  return value, units[i]
end


-- display runtime D:HH:MM:SS
local mfm = math.fmod
local function display_runtime(time)
  local d = time//86400
  local h = mfm(time,86400)//3600
  local m = mfm(time,3600)//60
  local s = mfm(time,60)//1
	return string.format("%d:%02d:%02d:%02d",d,h,m,s)
end


local total_bytes = 0
local start_clock = ct()
local last_print = os.time()

-- 2 hexadecimal characters is 1 byte.
local function add_bytes(bytes)
  total_bytes = total_bytes + bytes
end

-- calculate hash/second and byte/second
local function calculate_hps(force_print)
  if os.time() - last_print >= 10 or force_print then
    local actual_bytes = total_bytes
    local total_hash = actual_bytes // 32
    local runtime = ct() - start_clock
    local hash_per_sec = total_hash // runtime
    local bytes_per_sec, byte_unit = convert_value(actual_bytes / runtime)
    local bytes_written, mem_unit = convert_value(actual_bytes)

    io.stdout:write(
      string.format(" %s | %dh %dh/s | %.02f%s %.02f%s/s\n",
          display_runtime(runtime),
          total_hash,
          hash_per_sec,
          bytes_written, mem_unit,
          bytes_per_sec, byte_unit
      )):flush()
    last_print = os.time()
  end
end

return add_bytes, calculate_hps


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

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

-- bytes to readable format
local function convert_bytes(bytes)
  local units = {"B", "KB", "MB", "GB", "TB"}
  local i = 1
  while bytes >= 1024 and i < #units do
    bytes = bytes / 1024
    i = i + 1
  end
  return string.format("%.2f%s", bytes, units[i])
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
  if os.time() - last_print >= 5 or force_print then
    local clock_time = ct()
    local character_bytes = total_bytes
    local actual_bytes = character_bytes * 0.5 -- half because we're counting characters
    local total_hash = actual_bytes / 64
    local runtime = clock_time - start_clock
    local hps = total_hash // runtime
    local bps = convert_bytes(actual_bytes / runtime)
    io.stdout:write(
      string.format(
        "%dh \t%s \t%.03fs \t%dh/s \t%s/s \n",
          total_hash, convert_bytes(actual_bytes), runtime, hps, bps
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

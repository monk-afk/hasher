--==[[=======================]]==--
--==[[ hasher      stats.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

local function ct()
    local handle = io.popen("date +%s.%N")
    local result = handle:read("*a")
    handle:close()
    return tonumber(result)
end


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

local function add_bytes(bytes)
  total_bytes = total_bytes + bytes
end

local function calculate_hps(force_print)
  if os.time() - last_print >= 10 or force_print then
    local clock_time = ct()
    local total_hash = math.floor(total_bytes/64)
    local current_time = clock_time - start_clock
    local hps = string.format("%.03f", (total_hash / current_time))
    local bps = convert_bytes(total_bytes / current_time)

    last_print = os.time()
    io.stdout:write(
        string.format(
          "%d hashes (%s) in %.03fs [%shps/%sbps]\n",
          total_hash, convert_bytes(total_bytes), current_time, hps, bps
        )):flush()
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

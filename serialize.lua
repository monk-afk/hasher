--==[[=======================]]==--
--==[[ hasher  serialize.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

  -- receive array of hexadecimal strings
local function serial_hasher(hex_array)
  local hash_data = {}

    -- create index of hex digits
  for x = 0, 255 do
    local hex = string.format("%02x", x)
    hash_data[hex] = {}
  end

  local sha256 = dofile("sha256.lua")
  -- parse the array, make hash and binary
  for x = 1, #hex_array do
    local hexa = hex_array[x]
    local hash = sha256(hexa)
    local xref = string.sub(hash, 1,2)
    local d    = hash_data[xref]
    d[#d + 1]  = hash .. hexa
  end

  local serial_data = {} -- serialize for pipe transfer
  for hexref, data in pairs(hash_data) do
    if data and #data > 0 then
      table.insert(serial_data,  "[" .. hexref .. "]" .. "{" .. table.concat(data) .. "}")
    end
  end
  return serial_data
end

return serial_hasher



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
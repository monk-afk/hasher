
--==[[=======================]]==--
--==[[ hasher       init.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--
local string, table = string, table

local hash = {}
local function bin2hex(bin_str)
  for x = 1, #hash do hash[x] = nil end
  for b = 1, #bin_str, 8 do
    hash[#hash + 1] = 
      string.format("%016x",
        string.unpack(">I8", 
          string.sub(bin_str, b, b + 7)))
  end
  return table.concat(hash)
end

local sha256 = dofile("sha256.lua")

local duplicate_check = {}
local c = 0
local function read_data()
  for h = 0, (16 ^ 3) - 1 do
    local ref = string.format("%03x", h)
    local file = io.open("data/" .. ref, "rb")
    if file then
      for bin_chunk in file:lines(256) do

        local chunk = bin2hex(bin_chunk)
        for x = 1, #chunk, 128 do
          local hash = string.sub(chunk, x,      x + 63)
          local seed = string.sub(chunk, x + 64, x + 127)
          local rehash = sha256(seed)

          if not duplicate_check[seed] then
            duplicate_check[seed] = hash
            c = c + 1
          else
            print("duplicate: ", seed)
          end

          if rehash ~= hash then
            print("hash mismatch")
            print("seed:", seed)
            print("hash:", hash)
            print("rehash:", rehash)
            file:close()

            return
          end
        end
      end
      print(c)
      file:close()
    end
  end
end

read_data()

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

--[[================================================================================]]--
--[[ SecureHashingAlgorithm-BitWise by Roberto Ierusalimschy used under MIT License ]]--
--[[                                                                                ]]--
--[[ http://lua-users.org/wiki/SecureHashAlgorithmBw                                ]]--
--[[                                                                                ]]--
--[[ Copyright © 1994–2024 Lua.org, PUC-Rio.                                        ]]--
--[[                                                                                ]]--
--[[ Permission is hereby granted, free of charge, to any person obtaining a copy   ]]--
--[[ of this software and associated documentation files (the "Software"), to deal  ]]--
--[[ in the Software without restriction, including without limitation the rights   ]]--
--[[ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      ]]--
--[[ copies of the Software, and to permit persons to whom the Software is          ]]--
--[[ furnished to do so, subject to the following conditions:                       ]]--
--[[                                                                                ]]--
--[[ The above copyright notice and this permission notice shall be included in     ]]--
--[[ all copies or substantial portions of the Software.                            ]]--
--[[                                                                                ]]--
--[[ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     ]]--
--[[ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       ]]--
--[[ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    ]]--
--[[ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         ]]--
--[[ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  ]]--
--[[ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  ]]--
--[[ SOFTWARE.                                                                      ]]--
--[[                                                                                ]]--
--[[ https://www.lua.org/license.html                                               ]]--
--[[================================================================================]]--

-- Implementation of secure hash functions SHA224/SHA256 in Lua 5.3, with bitwise operators.
-- This implementation is based on the pseudo-code from Wikipedia (http://en.wikipedia.org/wiki/SHA-2)
-- SHA-256 code in Lua 5.3; based on the pseudo-code from
-- Wikipedia (http://en.wikipedia.org/wiki/SHA-2)
-- http://lua-users.org/wiki/SecureHashAlgorithmBw
-- MIT License (http://lua-users.org/lists/lua-l/2014-08/msg00628.html)

local string, assert = string, assert

-- Initialize table of round constants
-- (first 32 bits of the fractional parts of the cube roots of the first
-- 64 primes 2..311):
local k = {
   0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
   0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
   0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
   0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
   0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
   0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
   0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
   0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
   0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
   0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
   0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
   0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
   0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
   0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
   0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
   0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}


-- Lines marked with (1) can produce results with more than 32 bits.
-- These values should be used only in other lines marked with (1), or
-- in lines marked with (2), which trim their results to 32 bits.

-- no need to trim at 32 bits (results will be trimmed later)
local function rrotate (x, n)
  return ((x >> n) | (x << (32 - n)))    -- (1)
end


-- transform a string of bytes in a string of hexadecimal digits
local function str2hexa (s)
  local h = string.gsub(s, ".", 
    function(c)
      return string.format("%02x", string.byte(c))
    end
  )
  return h
end


-- append the bit '1' to the message
-- append k bits '0', where k is the minimum number >= 0 such that the
-- resulting message length (in bits) is congruent to 448 (mod 512)
-- append length of message (before pre-processing), in bits, as 64-bit
-- big-endian integer
local function preproc (msg, len)
  local extra = -(len + 1 + 8) % 64
  len = string.pack(">i8", 8 * len)    -- original len in bits, coded
  msg = msg .. "\128" .. string.rep("\0", extra) .. len
  assert(#msg % 64 == 0)
  return msg
end


local function initH224 (H)
  -- (second 32 bits of the fractional parts of the square roots of the
  -- 9th through 16th primes 23..53)
  H[1] = 0xc1059ed8
  H[2] = 0x367cd507
  H[3] = 0x3070dd17
  H[4] = 0xf70e5939
  H[5] = 0xffc00b31
  H[6] = 0x68581511
  H[7] = 0x64f98fa7
  H[8] = 0xbefa4fa4
  return H
end


local function initH256 (H)
  -- (first 32 bits of the fractional parts of the square roots of the
  -- first 8 primes 2..19):
  H[1] = 0x6a09e667
  H[2] = 0xbb67ae85
  H[3] = 0x3c6ef372
  H[4] = 0xa54ff53a
  H[5] = 0x510e527f
  H[6] = 0x9b05688c
  H[7] = 0x1f83d9ab
  H[8] = 0x5be0cd19
  return H
end


local function digestblock (msg, i, H)
    -- break chunk into sixteen 32-bit big-endian words w[1..16]
    local w = {string.unpack(">I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", msg, i)}
    -- Extend the sixteen 32-bit words into sixty-four 32-bit words:
    for j = 17, 64 do
      local v = w[j - 15]
      local s0 = rrotate(v, 7) ~ rrotate(v, 18) ~ (v >> 3)      -- (1)
      v = w[j - 2]
      local s1 = rrotate(v, 17) ~ rrotate(v, 19) ~ (v >> 10)    -- (1)
      w[j] = (w[j - 16] + s0 + w[j - 7] + s1) & 0xffffffff      -- (2)
    end

    -- Initialize hash value for this chunk:
    local a, b, c, d, e, f, g, h =
        H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]

    -- Main loop:
    for i = 1, 64 do
      local s0 = rrotate(a, 2) ~ rrotate(a, 13) ~ rrotate(a, 22)   -- (1)
      local maj = (a & b) ~ (a & c) ~ (b & c)
      local t2 = s0 + maj                                          -- (1)
      local s1 = rrotate(e, 6) ~ rrotate(e, 11) ~ rrotate(e, 25)   -- (1)
      local ch = (e & f) ~ (~e & g)
      local t1 = h + s1 + ch + k[i] + w[i]                         -- (1)
      h = g
      g = f
      f = e
      e = (d + t1) & 0xffffffff                                    -- (2)
      d = c
      c = b
      b = a
      a = (t1 + t2) & 0xffffffff                                   -- (2)
    end
    -- Add (mod 2^32) this chunk's hash to result so far:
    H[1] = (H[1] + a) & 0xffffffff
    H[2] = (H[2] + b) & 0xffffffff
    H[3] = (H[3] + c) & 0xffffffff
    H[4] = (H[4] + d) & 0xffffffff
    H[5] = (H[5] + e) & 0xffffffff
    H[6] = (H[6] + f) & 0xffffffff
    H[7] = (H[7] + g) & 0xffffffff
    H[8] = (H[8] + h) & 0xffffffff
end

-- Produce the final hash value (big-endian):
local function finalresult256 (H)
  return
    str2hexa(string.pack("> I4 I4 I4 I4 I4 I4 I4 I4",
        H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]))
end

local HH = {}

local function hash256 (msg)
  msg = preproc(msg, #msg)
  local H = initH256(HH)
  for i = 1, #msg, 64 do -- Process the message in successive 512-bit (64 bytes) chunks:
    digestblock(msg, i, H)
  end
  return finalresult256(H)
end

return hash256


--[[================================================================================]]--
--[[ SecureHashingAlgorithm-BitWise by Roberto Ierusalimschy used under MIT License ]]--
--[[                                                                                ]]--
--[[ http://lua-users.org/wiki/SecureHashAlgorithmBw                                ]]--
--[[                                                                                ]]--
--[[ Copyright © 1994–2024 Lua.org, PUC-Rio.                                        ]]--
--[[                                                                                ]]--
--[[ Permission is hereby granted, free of charge, to any person obtaining a copy   ]]--
--[[ of this software and associated documentation files (the "Software"), to deal  ]]--
--[[ in the Software without restriction, including without limitation the rights   ]]--
--[[ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      ]]--
--[[ copies of the Software, and to permit persons to whom the Software is          ]]--
--[[ furnished to do so, subject to the following conditions:                       ]]--
--[[                                                                                ]]--
--[[ The above copyright notice and this permission notice shall be included in     ]]--
--[[ all copies or substantial portions of the Software.                            ]]--
--[[                                                                                ]]--
--[[ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     ]]--
--[[ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       ]]--
--[[ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    ]]--
--[[ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         ]]--
--[[ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  ]]--
--[[ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  ]]--
--[[ SOFTWARE.                                                                      ]]--
--[[                                                                                ]]--
--[[ https://www.lua.org/license.html                                               ]]--
--[[================================================================================]]--
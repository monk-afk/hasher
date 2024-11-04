```lua
--==[[=======================]]==--
--==[[ hasher          0.0.1 ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

Concurrent processing of hex seeds hashed with sha256 to test hash collisions

___

Overview:

The spawned process completes a batch before sending the serialized data to the parent process.
A batch consists of a specific number of cycles, while a cycle covers all possible hexadecimal
values for the frame size, which increment in non-parallel sequence.

A frame size of 2 digits will create (16^frame) hex seeds, to complete 1 cycle of a batch.

___

Process Details:

The batch process starts by spawning child processes. The spawn creates a hex string with frames of 
digits with randomized starting values. Each frame is incremented in sequence by 1, for a complete
cycle through the range of values. The table of hexadecimal seeds are then hashed with sha256.

The seeds along with their hash are sorted by the first 2 characters of the hash. The bulk of each
is concatenated into a single string then serialized. The detached process creates a FIFO pipe to
send the serialized data for the init to process.

The parent skips processes which are not ready to send data. When received, the data is converted 
into unbroken binary strings, sorted by index and appended to file. 

If a target hash is provided as a command argument, the script will search through the data folder 
for a match. It takes the first two characters of the target hash, and reads from the corresponding 
file in chunks of 8192 bytes. This will print matches based on character length. In other words, 
how many matches for 'abc', 'abcd', 'abcde', etc. 

Additionally search.lua can be used from command line as a standalone tool.

___

Contents:
  - init.lua
  - spawn.lua
  - serialize.lua
  - search.lua
  - sha256.lua (Used under License, Copyright (c) 2018-2022  Egor Skriptunoff)
  - data/

___

Requirements:
  - Lua >= 5.3 for string.pack functionality.
  - Linux packages: `mkfifo`, `date`, `sleep`

Command Line Arguments and Defaults:

  - `spawn=1` number of concurrent processes serializing hashed hexadecimal seeds for the parent process
  
  - `batch=1` is the number of times to repeat the number of cycles before handoff to the parent process

  - `cycle=1` is the number of times to sequence through the range of hex values determined by the frame

  - `frame=2` length of hex digits which increment in value non-parallel to other frames within the seed
  
  - `target=` optional target hash to search for after completing all batches

___

Examples with output:

Run with default settings

    $ lua init.lua 
      256 hashes (16.00KB) in 0.298s [858.889hps/53.68KBbps]

Run three (3) sub-processes for 64 batches of 16 cycles:

    $ lua init.lua spawn=3 cycle=16 batch=64
      786432 hashes (48.00MB) in 464.340s [1693.655hps/105.85KBbps]

With a frame size of 4 hex digits:

    $ lua init.lua frame=4
      65536 hashes (4.00MB) in 75.490s [868.138hps/54.26KBbps]

With a target hash to search after completion:

    $ lua init.lua spawn=2 cycle=2 batch=1 target=9bf357782d60bfcd5c37697b78759d62a2054388b6a51a5c41446dc2d04ce76f
      1024 hashes (64.00KB) in 0.666s [1538.636hps/96.16KBbps]
      Searching for 9bf357782d60bfcd5c37697b78759d62a2054388b6a51a5c41446dc2d04ce76f in archive
      Pattern	Matches
      9bf3	5
      9bf	126

Search for a previously generated hash as a standalone operation:

    $ lua search.lua 9bf357782d60bfcd5c37697b78759d62a2054388b6a51a5c41446dc2d04ce76f
      Pattern	Matches
      9bf	126
      9bf3	5

```
___
```lua
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
```
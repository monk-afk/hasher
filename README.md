```lua
--==[[=======================]]==--
--==[[ hasher          0.0.3 ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--
```

Hash Collision Testing
---

### Process Details:

- The batch process starts with the parent process creating worker processes, and one writer process.

- The parent process continuously polls for completed work in a non-blocking loop.

- Each worker creates a 64 character hexadecimal seed, composed of 32 random bytes.

- Each byte frame (2 chars) increments from their starting value in sequence by 1, and shifted by one position, to complete the range of possible hexadecimal values of one byte (256).

- This creates a table of 16384 uniqe hexadecimal seeds, which are then hashed with sha256.

- The worker then passes the data to the parent process through a FIFO pipe file.

- The parent process accumulates the batches until each worker has produced one batch. The accumulated bulk data is transfered to the writer for additional processing.

- The writer process receieves the hash-seed pairs, and sorts them by the first three characters of the hash. Each string is then converted to binary as 4-byte unsigned integers before writing to file.

- A binary file contains a single unbroken sequence of hash and seed pairs.

- One complete batch will yield 1MB on disk per worker process, organized into files named by the hash prefixes.

- By default, file prefix is 3 characters, and will eventually create 4096 files.

- The file named search.lua can be used from command line to search for a hash, and returns with the total matches based on character length.

___

### Contents:
```
  init.lua        - initializer and parent process
  ││ ├─clip.lua   - tabularizes command line arguments
  ││ └─stats.lua  - runtime statistics
  │└─spawn.lua    - generates seed and hash
  │  └─sha256.lua - SHA-256, MIT, Copyright © 2014 Roberto Ierusalimschy
  └─save.lua      - organize and write to disk
    └─data/       - binary files storage
  - search.lua    - search for generated hash/seed pair
```
___

### Requirements:
  - Lua >= 5.3 to use string.pack and bitwise
  - Linux packages: `mkfifo`, `date`, `sleep`

### Command Line Arguments and Defaults:

  - `spawn=1` number of concurrent processes hashing hexadecimal seeds

  - `batch=1` number of times to repeat the entire process. use `batch=0` for endless.

___

### Examples with output:

**Run with default settings (1 batch, 1 worker)**

    $ lua init.lua
    > Processes: 1 	Batches: 1
    >  0:00:00:01 | 16.38Kh (1.0MB) | 12.2Kh/s 765.13KB/s

**Run three (3) workers for 10 batches:**

    $ lua init.lua spawn=3 batch=10
    > Processes: 3 	Batches: 10
    >  0:00:00:10 | 212.99Kh (13.0MB) | 20.4Kh/s 1.24MB/s
    >  0:00:00:19 | 425.98Kh (26.0MB) | 21.6Kh/s 1.32MB/s
    >  0:00:00:22 | 491.52Kh (30.0MB) | 22.1Kh/s 1.35MB/s

**Search for a previously generated hash:**

  *Positive match gives the seed:*

    $ lua search.lua 838abfeef24a3ba3a8060316c4f7ccfb9bd02de1c0b0b9e96eae6d0c1fe55215
    > Hash: 838abfeef24a3ba3a8060316c4f7ccfb9bd02de1c0b0b9e96eae6d0c1fe55215
    > Seed: 632b66842869b92f43780337ab07c17184e927aeb51ab896018ce0a13c9f1676

  *Closest matches given if no exact matches are found:*

    $ lua search.lua 8008ace23ae0a30ba404e4ec83bb6f2e32660fe10dfefd163c5d4722e587ecef
    > Matches	Pattern
    > 6     	8008

____

```lua
==============================================================================
MIT License                                                                   
                                                                              
Copyright © 2024  monk                                                        
                                                                              
Permission is hereby granted, free of charge, to any person obtaining a copy  
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights  
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     
copies of the Software, and to permit persons to whom the Software is         
furnished to do so, subject to the following conditions:                      
                                                                              
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.                               
                                                                              
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.                                                                     
==============================================================================
```
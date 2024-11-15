```lua
--==[[=======================]]==--
--==[[ hasher          0.1.2 ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--
```

Hash Collision Testing
---

### Process Details:

- generate a 64 character hexadecimal seed

- increment each byte by one while 

- slide each frame by one position in the string

- repeat until the sequence would repeat

- this creates 16352 strings from one seed

- hash the seeds using sha256

- encode the hash-seed pairs into binary

- file by the first 3-characters of the hash

- binary data is cached 2MB before writing to disk

- 

___

### Contents:

  - init.lua    - main function process
  - stats.lua   - runtime statistics
  - signal.lua  - to gracefully exit
  - sha256.lua  - SHA-256, MIT, Copyright © 2014 Roberto Ierusalimschy
  - data/       - binary files storage
  - search.lua  - search for generated hash/seed pair

___

**Requires** Lua >= 5.3 to use string.pack and bitwise

**Run**

    $ lua init.lua
    >  0:00:39:04 | 23724032h 10117h/s | 724.0MB 316.17KB/s

**Search for a previously generated hash:**

  *Positive match gives the seed:*

    $ lua search.lua 838abfeef24a3ba3a8060316c4f7ccfb9bd02de1c0b0b9e96eae6d0c1fe55215
    > Hash: 838abfeef24a3ba3a8060316c4f7ccfb9bd02de1c0b0b9e96eae6d0c1fe55215
    > Seed: 632b66842869b92f43780337ab07c17184e927aeb51ab896018ce0a13c9f1676

  *Closest matches given if no exact matches are found:*

    $ lua search.lua 2b0e26916d47f47de882532706085dfac9e151fb06ba15715a3a7b44272e6fc9
    > Matches	Pattern
    > 270     2b0e
    > 17      2b0e2
    > 4       2b0e26

____

### Changelog

  - 0.1.2
    - fixed incorrect string.pack integer type
    - new_genesis makes seed from previous hash+salt to minimize entropy usage

  - 0.1.1
    - scrapping the child processes to allow gradual improvements
    - added sliding window technique to seed generation
    - add a killswitch file to signal terminate instead of ctrl+c interrupt

  - 0.0.3
    - fix issue with having too many open files at once

  - 0.0.2
    - bugfix for parent process to not stop on the first pipe it opens
    - add a separate sub-process to handle file writes
    - changed sha256 library to use bitwise

  - 0.0.1
    - initial commit included child processes and a parent writer process


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
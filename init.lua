--==[[=======================]]==--
--==[[ hasher       init.lua ]]==--
--==[[ Copyright © 2024 monk ]]==--
--==[[ MIT License           ]]==--
--==[[=======================]]==--

local clip = dofile("clip.lua")
local num_spawns = math.max(tonumber(clip.spawn) or 1, 1) -- sub-processes
local batch = math.max(tonumber(clip.batch) or 1, 0) -- batch of cycles

local add_bytes, calculate_hps = dofile("stats.lua")

-- pipe to writer closure
local function pipe_closure(pipe_file)
  local chunk_data = {}
  local chunk_byte = 0

  return function(action, data)
    local half_bytes = #data -- 2 hex characters make 1 byte

    chunk_byte = chunk_byte + half_bytes

    table.insert(chunk_data, data)

    -- condition of 2MB before writing (1 batch per spawn)
    if chunk_byte >= 2097152 * num_spawns or action == "write" then
      local file = io.open(pipe_file, "a")

      if file then
        local chunk_concat = table.concat(chunk_data)
        file:write(chunk_concat, "\n"):close()
        chunk_data = {}
        chunk_byte = 0
      end
      calculate_hps()
    end

    add_bytes(half_bytes) -- not binary bytes
  end
end

-- daemon function to poll the spawn processes for data
local function process_work(spawn_data)
  local recurse_flag = false

  for id, worker in pairs(spawn_data.workers) do
    if worker and worker.status then
      -- check the pipe for data
      local fifo = io.open(worker.fifo_pipe_id, "r")
      if fifo then

        for chunk in fifo:lines() do
          if chunk == "kill" then
            os.remove(worker.fifo_pipe_id)
            spawn_data.workers[id] = nil
            worker = false

          elseif #chunk >= 64 then
            spawn_data.writer.pipe(nil, chunk)
            calculate_hps()
          end
        end

        fifo:close()
      end
    end

    if worker then
      recurse_flag = true
    end
  end

  if recurse_flag then
    os.execute("sleep 0.1") -- stop cpu hogging
    return process_work(spawn_data)
  end

  local pipe = pipe_closure()
  spawn_data.writer.pipe("write", "") -- force write any remaining chunks
end

local function activate_spawns(spawn_data)
  for id, userdata in pairs(spawn_data.workers) do
      userdata.status = io.popen(userdata.pop_string)
  end
  return process_work(spawn_data)
end

local function spawner()
  local spawn_data = {workers = {}}
  -- create our spawn processes
  for n = 1, num_spawns do
    local spawn = {id}
    local spawn_id = tostring(spawn):sub(12)
    local filename = "/tmp/fifo_" .. spawn_id
    spawn = {
      status = false,
      fifo_pipe_id = filename,
      pop_string = string.format("lua spawn.lua batch=%d spawn=%s", batch, spawn_id)
    }
    spawn_data.workers[spawn_id] = spawn
  end

  -- create our writer asap for it to create and listen to the pipe
  local writer = {id}
  local writer_id = tostring(writer):sub(12)
  local pipe_file = "/tmp/fifo_" .. writer_id
  spawn_data.writer = {
    status = io.popen(string.format("lua save.lua writer=%s", writer_id)),
    pipe = pipe_closure(pipe_file),
    fifo = pipe_file
  }
  clip.writer_id = writer_id
  return activate_spawns(spawn_data)
end

local function main()
  io.stdout:write(
      string.format("Processes: %d \tBatches: %d\n", num_spawns, batch)
  ):flush()

  spawner()

  -- tell the writer when work is finished, plain file to avoid pipe-hanging
  local file = io.open("/tmp/fifo_" .. clip.writer_id, "w+")
  file:write("kill", "\n"):close()

  calculate_hps(true)
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

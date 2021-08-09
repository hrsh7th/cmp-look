local cmp = require('cmp')
local luv = require('luv')
local debug = require('cmp.utils.debug')

local M = {}

M.new = function()
  local self = setmetatable({}, { __index = M })
  return self
end

M.get_keyword_pattern = function()
  return '\\w\\+'
end

local split = function(str)
  local sep = '%s'
  local ret = {}
  for s in string.gmatch(str, '([^'..sep..']+)') do
    if s ~= '' then
      table.insert(ret, s)
    end
  end
  return ret
end

M.complete = function(self, request, callback)
  local q = 'app'
  local stdin = luv.new_pipe(false)
  local stdout = luv.new_pipe(false)
  local stderr = luv.new_pipe(false)
  local handle, pid
  local out = ''
  local candidates = function(words)
    local ret = {}
    for _, w in ipairs(words) do
      table.insert(ret, {label=w})
    end
    return ret
  end
  do
    local function onexit(code, signal)
      stdin:close()
      stdout:close()
      stderr:close()
      handle:close()
      callback(candidates(split(out)))
    end
    local spawn_params = {
      args = {'--', q},
      stdio = {stdin, stdout, stderr}
    }
    handle, pid = luv.spawn('look', spawn_params, onexit)
    if handle == nil then
      debug.log(string.format("start `%s` failed: %s", cmd, pid))
    end
    luv.read_start(stdout, function(err, chunk)
      assert(not err, err)
      if chunk then
        out = out .. chunk
      end
    end)
  end
end

return M
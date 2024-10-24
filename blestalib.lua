local blesta = {}
local config = require("config")
local base64 = require("base64")

local function makeRequest(endpoint,parameters)
  if not parameters then parameters = "" end
  local user_id = config.blesta_user .. ":" .. config.blesta_key
  local token = base64.encode(user_id)
  --print(user_id)
  --print(token)
  local h, err = http.get(config.blesta_api_domain .. "/api/" .. endpoint .. ".json" .. parameters, {["Authorization"] = "Basic " .. token})
  if not h then error("Failed to make request to " .. endpoint .. " with parameters " .. parameters .. err) end
  local data = textutils.unserialiseJSON(h.readAll())
  h.close()

  -- Check if any errors happened
  if not data then
    error("The returned data was empty or not of JSON format")
  end
  if data.errors then
    error("An error occured") -- TODO: make this better
  end
  return data.response, data
end

blesta.transactions = {}
blesta.transactions.getSimpleList = function()
  return makeRequest("Transactions/getSimpleList")
end
blesta.transactions.getList = function()
  return makeRequest("Transactions/getList")
end

return blesta
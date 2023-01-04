local Krypton = {
    __opaque = true,
    node = "https://krist.dev/"
}
local Krypton_mt = { __index = Krypton }

--[[
    Basic GET and POST requests
]]

local function toFormBody(data)
    local body = ""
    for k,v in pairs(data) do
        body = body .. textutils.urlEncode(k) .. "=" .. textutils.urlEncode(v) .. "&"
    end
    return body
end

function Krypton:get(endpoint)
    local url = self.node .. endpoint
    local response, error = http.get(url)
    if not response then
        error(error, 3)
    end
    local body = response.readAll()
    response.close()

    local data = textutils.unserializeJSON(body)
    if not data.ok then
        if (data.error ~= "invalid_parameter") then
            error(data.error, 3)
        else
            error({data.error, data.parameter}, 3)
        end
    end
    return data
end

function Krypton:post(endpoint, data)
    local url = self.node .. endpoint
    local response, error = http.post(url, toFormBody(data))
    if not response then
        error(error, 3)
    end
    local body = response.readAll()
    response.close()

    local data = textutils.unserializeJSON(body)
    if not data.ok then
        if (data.error ~= "invalid_parameter") then
            error(data.error, 3)
        else
            error({data.error, data.parameter}, 3)
        end
    end
    return data
end

--[[
    Krist API Endpoints
]]

-- Miscellaneous endpoints
function Krypton:getInfo()
    return self:get("motd")
end

-- Websocket Endpoints
function Krypton:startWs(privateKey)
    local data = self:post("ws/start", {privatekey = privateKey})
    if not data.url then
        error("Failed to get websocket URL", 2)
    end
    return data.url
end

--[[
    Constructor
]]

function Krypton.new(props)
    props = props or {}
    local self = setmetatable(props, Krypton_mt)

    local info = self:getInfo()
    self.currency = info.currency

    return self
end

--[[
    Websockets
]]

local KryptonWS = {}
local KryptonWS_mt = { __index = KryptonWS }

function Krypton:connect()
    if self.ws then
        return self.ws
    end
    self.ws = KryptonWS.new({
        krypton = self
    })
    return self.ws
end

function KryptonWS:connect()
    local url = self.krypton:startWs(self.krypton.privateKey)
    self.ws = http.websocket(url)
    self.id = 1
end

function KryptonWS:reconnect()
    self.ws.close()
    self:connect()
end

function KryptonWS:disconnect()
    self.ws.close()
    self.ws = nil
end

function KryptonWS:listen()
    while true do
        if self.ws then
            local response, binary = self.ws.receive(15)
            if not self.ws then
                -- We've been disconnected, stop listening
                break
            end
            if not response then
                -- Didn't get keepalive, reconnect
                self:reconnect()
            end
            --print((self.krypton.id or self.krypton.node) .. " <- " .. response)
            local success, err = pcall(function()
                local data = textutils.unserializeJSON(response)
                local eventType = data.type
                if eventType and eventType == "event" then
                    local event = data
                    event.source = self.krypton.id or self.krypton.node
                    os.queueEvent(event.event, event)
                elseif not eventType then
                    local event = data
                    event.source = self.krypton.id or self.krypton.node
                    if data.ok then
                        os.queueEvent("krypton_response", event)
                    else
                        os.queueEvent("krypton_error", event)
                    end
                end
            end)

            if err then
                print("Got error parsing response from " .. (self.krypton.id or self.krypton.node))
                self:reconnect()
            end
        else
            sleep(0.1)
        end
    end
end

function KryptonWS:send(type, data)
    data = data or {}
    data.id = self.id
    data.type = type
    self.ws.send(textutils.serializeJSON(data))
    self.id = self.id + 1
    return self.id - 1
end

-- Requires authed websocket
function KryptonWS:makeTransaction(to, amount, metadata)
    return self:send("make_transaction", {to = to, amount = amount, metadata = metadata})
end

function KryptonWS:getAddress(address, fetchNames)
    return self:send("address", {address = address, fetch_names = fetchNames})
end

function KryptonWS:getSelf()
    return self:send("me")
end

function KryptonWS:getSubscriptions()
    return self:send("get_subscription_level")
end

function KryptonWS:logout()
    return self:send("logout")
end

function KryptonWS:login(privateKey)
    privateKey = privateKey or self.krypton.privateKey
    return self:send("login", {privatekey = privateKey})
end

function KryptonWS:subscribe(event)
    return self:send("subscribe", {event = event})
end

function KryptonWS:unsubscribe(event)
    return self:send("unsubscribe", {event = event})
end

function KryptonWS.new(props)
    local self = setmetatable({}, KryptonWS_mt)

    self.krypton = props.krypton
    
    self:connect()

    return self
end

return Krypton
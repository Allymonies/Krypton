local Krypton = {
    node = "https://krist.dev/"
}
local Krypton_mt = { __index = Krypton }

--[[
    Basic GET and POST requests
]]

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
    local response, error = http.post(url, textutils.serializeJSON(data))
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

    self.privateKey = nil
    local info = self:getInfo()
    self.currency = info.currency

    return self
end

--[[
    Websockets
]]

local KryptonWS = {}

function Krypton:connect()
    if self.ws then
        return self.ws
    end
    self.ws = KryptonWS.new({
        krypton = self
    })
    return self.ws
end

function KryptonWS.new(props)
    local self = {}

    self.krypton = props.krypton
    
    self:connect()

    return self
end

function KryptonWS:connect()
    local url = self.krypton:startWs(self.krypton.privateKey)
    self.ws = http.websocket(url.url)
    self.id = 0
end

function KryptonWS:reconnect()
    self.ws.close()
    self:connect()
end

function KryptonWS:listen()
    while true do
        local response, binary = self.ws.receive(15)
        if not response then
            -- Didn't get keepalive, reconnect
            self:reconnect()
        end
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
    end
end

function KryptonWS:send(type, data)
    data = data or {}
    data.id = self.id
    data.type = type
    self.ws.send(data)
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
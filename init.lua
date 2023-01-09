local Krypton = {
    __opaque = true,
    node = "https://krist.dev/"
}
local Krypton_mt = { __index = Krypton }

--[[
    Make addresses
]]

local g = string.gsub
sha256 = loadstring(g(g(g(g(g(g(g(g('Sa=XbandSb=XbxWSc=XlshiftSd=unpackSe=2^32SYf(g,h)Si=g/2^hSj=i%1Ui-j+j*eVSYk(l,m)Sn=l/2^mUn-n%1VSo={0x6a09e667Tbb67ae85T3c6ef372Ta54ff53aT510e527fT9b05688cT1f83d9abT5be0cd19}Sp={0x428a2f98T71374491Tb5c0fbcfTe9b5dba5T3956c25bT59f111f1T923f82a4Tab1c5ed5Td807aa98T12835b01T243185beT550c7dc3T72be5d74T80deb1feT9bdc06a7Tc19bf174Te49b69c1Tefbe4786T0fc19dc6T240ca1ccT2de92c6fT4a7484aaT5cb0a9dcT76f988daT983e5152Ta831c66dTb00327c8Tbf597fc7Tc6e00bf3Td5a79147T06ca6351T14292967T27b70a85T2e1b2138T4d2c6dfcT53380d13T650a7354T766a0abbT81c2c92eT92722c85Ta2bfe8a1Ta81a664bTc24b8b70Tc76c51a3Td192e819Td6990624Tf40e3585T106aa070T19a4c116T1e376c08T2748774cT34b0bcb5T391c0cb3T4ed8aa4aT5b9cca4fT682e6ff3T748f82eeT78a5636fT84c87814T8cc70208T90befffaTa4506cebTbef9a3f7Tc67178f2}SYq(r,q)if e-1-r[1]<q then r[2]=r[2]+1;r[1]=q-(e-1-r[1])-1 else r[1]=r[1]+qVUrVSYs(t)Su=#t;t[#t+1]=0x80;while#t%64~=56Zt[#t+1]=0VSv=q({0,0},u*8)fWw=2,1,-1Zt[#t+1]=a(k(a(v[w]TFF000000),24)TFF)t[#t+1]=a(k(a(v[w]TFF0000),16)TFF)t[#t+1]=a(k(a(v[w]TFF00),8)TFF)t[#t+1]=a(v[w]TFF)VUtVSYx(y,w)Uc(y[w]W0,24)+c(y[w+1]W0,16)+c(y[w+2]W0,8)+(y[w+3]W0)VSYz(t,w,A)SB={}fWC=1,16ZB[C]=x(t,w+(C-1)*4)VfWC=17,64ZSD=B[C-15]SE=b(b(f(B[C-15],7),f(B[C-15],18)),k(B[C-15],3))SF=b(b(f(B[C-2],17),f(B[C-2],19)),k(B[C-2],10))B[C]=(B[C-16]+E+B[C-7]+F)%eVSG,h,H,I,J,j,K,L=d(A)fWC=1,64ZSM=b(b(f(J,6),f(J,11)),f(J,25))SN=b(a(J,j),a(Xbnot(J),K))SO=(L+M+N+p[C]+B[C])%eSP=b(b(f(G,2),f(G,13)),f(G,22))SQ=b(b(a(G,h),a(G,H)),a(h,H))SR=(P+Q)%e;L,K,j,J,I,H,h,G=K,j,J,(I+O)%e,H,h,G,(O+R)%eVA[1]=(A[1]+G)%e;A[2]=(A[2]+h)%e;A[3]=(A[3]+H)%e;A[4]=(A[4]+I)%e;A[5]=(A[5]+J)%e;A[6]=(A[6]+j)%e;A[7]=(A[7]+K)%e;A[8]=(A[8]+L)%eUAVUY(t)t=t W""t=type(t)=="string"and{t:byte(1,-1)}Wt;t=s(t)SA={d(o)}fWw=1,#t,64ZA=z(t,w,A)VU("%08x"):rep(8):format(d(A))V',"S"," local "),"T",",0x"),"U"," return "),"V"," end "),"W","or "),"X","bit32."),"Y","function "),"Z"," do "))()

function makeaddressbyte(byte)
  local byte = 48 + math.floor(byte / 7)
  return string.char(byte + 39 > 122 and 101 or byte > 57 and byte + 39 or byte)
end

function Krypton:makev2address(key)
  local protein = {}
  local stick = sha256(sha256(key))
  local n = 0
  local link = 0
  local v2 = "k"
  if self.currency and self.currency.address_prefix then
    v2 = self.currency.address_prefix
  end
  repeat
    if n < 9 then protein[n] = string.sub(stick,0,2)
    stick = sha256(sha256(stick)) end
    n = n + 1
  until n == 9
  n = 0
  repeat
    link = tonumber(string.sub(stick,1+(2*n),2+(2*n)),16) % 9
    if string.len(protein[link]) ~= 0 then
      v2 = v2 .. makeaddressbyte(tonumber(protein[link],16))
      protein[link] = ''
      n = n + 1
    else
      stick = sha256(stick)
    end
  until n == 9
  return v2
end

function Krypton:toKristWalletFormat(passphrase)
  return sha256("KRISTWALLET"..passphrase).."-000"
end

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
    local response, err = http.get(url)
    if not response then
        error(err, 3)
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
    local response, err = http.post(url, toFormBody(data))
    if not response then
        error(err, 3)
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

function Krypton:getName(name)
    return self:get("names/" .. name)
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
            local success, err = pcall(function()
                local response, binary = self.ws.receive(15)
                if not self.ws then
                    -- We've been disconnected, stop listening
                    return "break"
                end
                if not response then
                    -- Didn't get keepalive, reconnect
                    self:reconnect()
                end
                --print((self.krypton.id or self.krypton.node) .. " <- " .. response)
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

            if success and err == "break" then
                break
            elseif err then
                if err == "Terminated" then
                    break
                end
                print("Got error receiving response from " .. (self.krypton.id or self.krypton.node) .. " reconnecting")
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
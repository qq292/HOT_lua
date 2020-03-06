

hotmt = { sessionid = nil, versionTab = {}, versionJson = {}, obName = nil, requireErrorText = "", tabLuaCode = nil }

hotfile = { luaFolder = nil, rootPath = nil, obPath = nil }
hotupdata = {}
hotRequireName = {}

function hotfile:__hotMarkFile(file)
    --创建文件夹
    local bool, types = isFileExist(file)
    local f = nil
    if bool then
        --注意：type 参数仅 TSLib v1.2.8 及其以上版本支持
        if types == false then
            f = file
        else
            status = ts.hlfs.makeDir(file)
            if status then
                f = file
            end
        end
    else
        status = ts.hlfs.makeDir(file)
        if status then
            f = file
        end
    end

    return f
end

function hotfile:hotfile_root()
    --创建根文件夹
    local file = userPath() .. "/HotUpdate/"
    f = self:__hotMarkFile(file)
    if f then
        self.rootPath = f
    else
        nLog("根文件夹 创建失败")
    end

end
function hotfile:hotfile_ob(obname)
    --创建项目文件夹
    local file = userPath() .. "/HotUpdate/" .. obname
    f = self:__hotMarkFile(file)
    if f then
        self.obPath = f
    else
        nLog("项目文件夹 创建失败")
    end
end

function hotfile:hotFileExists(fileName)
    --检查文件是否存在
    local f = io.open(fileName, "r")
    return f ~= nil and f:close()
end

function hotfile:hotSaveLuaCode(luaFileName, luaCode)
    --保存lua代码
    writeFileString(self.obPath .. "/" .. luaFileName .. ".lua", luaCode, "w", 1)
    mSleep(1000)
    return true
end

function hotfile:hotSaveLuaVersion(Version)
    --保存版本信息
    writeFileString(self.obPath .. "/hotGetLocalVersion.txt", Version, "w", 1)
    mSleep(1000)
    return true
end

function hotfile:hotGetLocalVersion()
    --获取本地版本信息
    if not self.obPath then
        nLog("获取本地项目path失败")
        return false
    end

    txt = readFileString(self.obPath .. "/hotGetLocalVersion.txt")--读取文件内容，返回全部内容的 string
    if txt then
        --nLog("文件内容："..txt)
    else
        nLog(".....未获得本地版本信息，正在从服务器获取版本信息.....")
    end
    return txt
end

function hotmt:login()
    --登录
    error("不可以调用")
end
function hotmt:geBusiness()
    --获得业务名-id
    error("不可以调用")
end
function hotmt:testUpdata()
    --测试更新
    error("不可以调用")
end
function hotmt:getObjectId()
    --获取项目名 ID
    error("不可以调用")
end
function hotmt:setObName(name)
    --测试登录
    self.ObName = name
    return self.ObName
end
function hotmt:testlogin()
    --测试登录
    if not self.sessionid then
        error("请登录后操作！")
    end
end

function hotupdata:new()
    local o = {}
    setmetatable(hotfile, { __index = hotmt })

    setmetatable(self, { __index = hotfile })

    setmetatable(o, { __index = self })
    return o
end

function hotupdata:login(user, password)
    --登录
    local json = ts.json
    table = { tstab = "tstab", header_send = { Vary = "Cookie" }, body_send = { jtype = "lua", user = user, password = password }, format = "utf8" }
    code, header_resp, body_resp = ts.httpPost("http://106.12.87.246:8080/myhotupdate/login/", table)
    tb = json.decode(body_resp)
    if tb["sessionid"] then
        self.sessionid = tb["sessionid"]
    else
        nLog(tb["error"])
    end

end
function hotupdata:getVersionLua(objectNameId)
    --根据项目id 返回最新版本号 版本ID  业务名 业务ID   用于检测更新和下载文件
    local json = ts.json

    self:testlogin()
    table = { tstab = "tstab", header_send = { Cookie = "sessionid=" .. self.sessionid }, body_send = { jtype = "0", id1 = objectNameId }, format = "utf8" }
    code, header_resp, body_resp = ts.httpPost("http://106.12.87.246:8080/myhotupdate/getVersionLua/", table)

    self.versionJson = body_resp
    self.versionTab = json.decode(body_resp)

    return body_resp
end

function hotupdata:getObjectId(newObject_name)
    --获取项目名 ID
    local json = ts.json
    self:testlogin()
    table = { tstab = "tstab", header_send = { Cookie = "sessionid=" .. self.sessionid }, body_send = { jtype = "lua", newObject_name = newObject_name }, format = "utf8" }
    code, header_resp, body_resp = ts.httpPost("http://106.12.87.246:8080/myhotupdate/getObject/", table)

    return json.decode(body_resp)
end

function hotupdata:hotDownLoadUpdata(tab)
    --下载更新
    for k, v in pairs(tab) do
        self:hotSaveLuaCode(v["businessName"], v["luaCode"])
    end
    return true
end

function hotupdata:hotMarkLuaCode(tab)
    --没有lua文件则 写入文件

    for k, v in pairs(tab) do
        luaPATH = self.obPath .. "/" .. v["businessName"] .. ".lua"
        if not self:hotFileExists(luaPATH) then
            self:hotSaveLuaCode(v["businessName"], v["luaCode"])
        end
    end
end

function hotupdata:__hotGetLuaCode()
    ---获取服务器最新版本LUA代码
    local json = ts.json
    self:testlogin()
    if not self.ObName then
        nLog("请设置项目ID")
        return false
    end

    table = { tstab = "tstab", header_send = { Cookie = "sessionid=" .. self.sessionid }, body_send = { obNameId = self.ObName }, format = "utf8" }
    code, header_resp, body_resp = ts.httpPost("http://106.12.87.246:8080/myhotupdate/updataLua/", table)
    tab = json.decode(body_resp)
    self.tabLuaCode = tab
    return tab
end

function hotupdata:getUpdataLua(versionJson)
    --检测更新 返回 业务名 lua代码
    local json = ts.json
    self:testlogin()
    table = { tstab = "tstab", header_send = { Cookie = "sessionid=" .. self.sessionid }, body_send = { myjson = versionJson, obNameId2 = self.ObName }, format = "utf8" }
    code, header_resp, body_resp = ts.httpPost("http://106.12.87.246:8080/myhotupdate/updataLua/", table)
    if body_resp ~= "{}" then
        json_body_resp = json.decode(body_resp)
        r = self:hotDownLoadUpdata(json_body_resp) --更新lua代码
        if r then
            vers = self:getVersionLua(obName)-- 从服务器获取最新版信息
            f = self:hotSaveLuaVersion(vers) --保存版信息
            if f then
                nLog("重载脚本---代码")
                lua_restart() --重载脚本
            end
        end


    end

end

function hotupdata:hot_loop_code()
    --在while循环中执行的函数 可以重写此函数，建议放置脚本功能逻辑
    --点击界面逻辑()
end

function hotupdata:hot_loopOut_code()
    --在while循环外执行的函数 可以重写此函数。建议放置UI逻辑
end

function hotRequireLua(index)
    --require 以业务名命名的lua文件
    --dialog(index[2][index[1]]["businessName"], 5)
    require(index[2][index[1]]["businessName"])
end

function hotupdata:hotImpostLua(tabLuaCode)
    for k, v in pairs(tabLuaCode) do
        -- 捕获require异常
        if not pcall(hotRequireLua, { k, tabLuaCode }) then
            hotup.requireErrorText = hotup.requireErrorText .. "require\t【" .. v["businessName"] .. ".lua】\t失败！！\t\t----可能语法错误----\n"
        else
            hotup.requireErrorText = hotup.requireErrorText .. "require\t【" .. v["businessName"] .. ".lua】\t成功！！\n"
        end
    end
    return "1"
end













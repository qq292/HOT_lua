require("TSLib")
local ts = require("ts")
require("HOTUPDATA")

--[[

服务器下载的项目保存在userPath().."/HotUpdate/" 目录 以项目名+ID 命名

项目管理地址：
http://106.12.87.246:8080/myhotupdate/homepage/

--]]



-- 登录并设置要使用的项目ID
hotup = hotupdata:new() --实例化hotupdata
obName = hotup:setObName("10") --设置要使用的项目ID   -----此参数对应服务器的项目id-------
hotup:login("root", "root") --使用账号密码登录

--检查并创建文件夹
obn = hotup:getObjectId(obName) --从服务器获取项目名和ID
hotup:hotfile_root() --检测生成根目录路径
hotup:hotfile_ob(obn["objectName"] .. obn["objectId"]) --检测生成项目路径

inf = hotup:hotGetLocalVersion() --获取本地版本
if not inf then --没有得到版本信息
    vers = hotup:getVersionLua(obName) -- 从服务器获取最新版本号
    f = hotup:hotSaveLuaVersion(vers) --保存版信息到本地
    if f then
        nLog("重载脚本--版本")
        lua_restart() --重载脚本
    end
end

hotup:getUpdataLua(inf) --根据版本信息检测更新
local tabLuaCode = hotup:__hotGetLuaCode() --从服务器获取已更新的lua代码
hotup:hotMarkLuaCode(tabLuaCode) --将更新的lua文件写入到项目文件夹

package.path = hotup.obPath .. "/?.lua" --添加模块搜索路径


hotup:hotImpostLua(tabLuaCode) --require lua模块
hotTime = os.time() --进入主循环的时间


hotup:hot_loopOut_code() --服务器端可以重写此函数
--主循环--
while (true) do

    hotup:hot_loop_code() --服务器端可以重写此函数

    if os.time() - hotTime >= 5 then --每5秒钟检测一次更新
        hotTime = os.time()
        hotup:getUpdataLua(inf)
    end
end










------------------------- 以上代码可以不做任何修改----------------------
------------------------- 以上代码可以不做任何修改------------------

--obName = hotup:setObName("9") --设置要使用的项目ID   -----此参数对应服务器的项目id-------
--hotup:login("root", "root") --使用账号密码登录

---只需要刚刚这两行代码的参数即可---
---hotup:setObName("9") 填写你的项目id
---hotup:login("root", "root") 填写你的帐号密码





gameplay_data_path = "./gameplay/data/?.lua;"

gameplay_lua_path = "./gameplay/envconfig/?.lua;"
	.."./gameplay/lualib/?.lua;"
	.."./gameplay/service_logic/?.lua;"
	.."./gameplay/service_proxy/?.lua;"

gameplay_service_path = "./gameplay/service/?.lua;"

root = "./"
thread = 8
logservice = "snlua"
logger = "logger"
logpath = "./log/"
harbor = 0
start = "main"
bootstrap = "snlua bootstrap"
luaservice = root.."skynet/service/?.lua;"..gameplay_service_path
lua_path = root.."skynet/lualib/?.lua;"..gameplay_data_path..gameplay_lua_path
lua_cpath = root.."skynet/luaclib/?.so;".."./gameplay/luaclib/?.so;"
cpath = root.."skynet/cservice/?.so;"
lualoader = root.."skynet/lualib/loader.lua"
preload = "./gameplay/preload.lua"	-- run preload.lua before every lua service run
-- daemon = "./skynet.pid"

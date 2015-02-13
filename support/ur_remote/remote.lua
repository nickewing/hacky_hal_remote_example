local http = libs.http;
local base_url = "http://nick-rpi:4567/custom/"
local log = libs.log;

function call(action, params)
	http.post(base_url .. action .. '?' .. params)
end

events.action = function(name, extras)
  if extras[1] then
    params = string.gsub(extras[1], ' ', '%%20')
  else
    params = ''
  end

  call(name, params)
end

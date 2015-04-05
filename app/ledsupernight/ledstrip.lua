
require "cord"
require "svcd"
local LED = require "led"

strip = storm.n.led_init(50, 0x10000, 0x1000)

MOTDs = {"Default message!!1" }

SVCD.init("ledsupernight", function()
    print "starting"
    SVCD.add_service(0x3101)
    -- LED set(position, r, g, b)
    SVCD.add_attribute(0x3101, 0x4105, function(pay, srcip, srcport)
        local ps = storm.array.fromstr(pay)
        local position = ps:get(1)
        local red = ps:get(2)
	local green = ps:get(3)
	local blue = ps:get(4)
        print ("got a request to light led ", position, " color r = ", red, ", g = ", green, ", b = ", blue)

        storm.n.led_set(strip, position, red, green, blue);
    end)

    -- LED show()
    SVCD.add_attribute(0x3101, 0x4106, function(pay, srcip, srcport)
        print ("got a request to show leds ")
        storm.n.led_show(strip);
    end)

    -- LED clear()
    SVCD.add_attribute(0x3101, 0x4107, function(pay, srcip, srcport)
        print ("got a request to clear leds ")
	for i=1:49 do
		storm.n.led_set(strip, i, 0, 0, 0);
	end
        storm.n.led_show(strip);
    end)

    -- LED clear(position)
    SVCD.add_attribute(0x3101, 0x4108, function(pay, srcip, srcport)
        local ps = storm.array.fromstr(pay)
        local position = ps:get(1)
        print ("got a request to clear led ", position)

        storm.n.led_set(strip, position, 0, 0, 0);
    end)

--TODO figure out what to do widdis
    cord.new(function()
        while true do
            local msg = MOTDs[math.random(1,#MOTDs)]
            local arr = storm.array.create(#msg+1,storm.array.UINT8)
            arr:set_pstring(0, msg)
            SVCD.notify(0x3101, 0x4108, arr:as_str())
            cord.await(storm.os.invokeLater, 3*storm.os.SECOND)
        end
    end)
end)


cord.enter_loop()


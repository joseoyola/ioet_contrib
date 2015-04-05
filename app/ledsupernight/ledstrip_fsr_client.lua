
require "cord"
sh = require "stormsh"
sh.start()
-- in global scope now
require "svcd"

strips = {}
fsrs = {}

cord.new(function()
    cord.await(SVCD.init, "ledclient")
    SVCD.advert_received = function(pay, srcip, srcport)
        local adv = storm.mp.unpack(pay)
        for k,v in pairs(adv) do
            --These are the services
            if k == 0x3101 or k == 0x3102 then
                --Characteristic
                for kk,vv in pairs(v) do
                    if vv == 0x4105 and k == 0x3101 then
                        -- This is a supernight LED set service
                        if strips[srcip] == nil then
                            print ("Discovered LED strips: ", srcip)
                        end
                        strips[srcip] = storm.os.now(storm.os.SHIFT_16)
                    end
                    if vv == 0x4205 and k == 0x3102 then
                        -- This is a supernight LED set service
                        if fsrs[srcip] == nil then
                            print ("Discovered FSR: ", srcip)
			        SVCD.subscribe(srcip,0x3102, 0x4205, fsrcallback(msg))
                        end
                        fsrs[srcip] = storm.os.now(storm.os.SHIFT_16)
                    end

                end
            end
        end
    end
end)

-- Set a particular LED
function setled(position, red, green, blue)
    cord.new(function()
        for k, v in pairs(strips) do
            local cmd = storm.array.create(4, storm.array.UINT8)
            cmd:set(1, position)
            cmd:set(2, red)
            cmd:set(3, green)
            cmd:set(4, blue)
            local stat = cord.await(SVCD.write, k, 0x3101, 0x4105, cmd:as_str(), 300)
            if stat ~= SVCD.OK then
                print "FAIL"
            else
                print "OK"
            end
            -- don't spam
            cord.await(storm.os.invokeLater,50*storm.os.MILLISECOND)
        end
    end)
end

-- Show the entire strip
function showled()
    cord.new(function()
        for k, v in pairs(strips) do
            local cmd = storm.array.create(1, storm.array.UINT8)
            local stat = cord.await(SVCD.write, k, 0x3101, 0x4106, cmd:as_str(), 300)
            if stat ~= SVCD.OK then
                print "FAIL"
            else
                print "OK"
            end
            -- don't spam
            cord.await(storm.os.invokeLater,50*storm.os.MILLISECOND)
        end
    end)
end

-- Clear the entire strip
function clearled()
    cord.new(function()
        for k, v in pairs(strips) do
            local cmd = storm.array.create(1, storm.array.UINT8)
            local stat = cord.await(SVCD.write, k, 0x3101, 0x4107, cmd:as_str(), 300)
            if stat ~= SVCD.OK then
                print "FAIL"
            else
                print "OK"
            end
            -- don't spam
            cord.await(storm.os.invokeLater,50*storm.os.MILLISECOND)
        end
    end)
end

-- Clear a particular LED on the strip
function clearspecificled(position)
    cord.new(function()
        for k, v in pairs(strips) do
            local cmd = storm.array.create(1, storm.array.UINT8)
            cmd:set(1, position)
            local stat = cord.await(SVCD.write, k, 0x3101, 0x4108, cmd:as_str(), 300)
            if stat ~= SVCD.OK then
                print "FAIL"
            else
                print "OK"
            end
            -- don't spam
            cord.await(storm.os.invokeLater,50*storm.os.MILLISECOND)
        end
    end)
end

function fsrcallback(msg)
    print("Message Received: ", msg)
end

function get_motd(serial)
    SVCD.subscribe("fe80::212:6d02:0:"..serial,0x3003, 0x4008, function(msg)
        local arr = storm.array.fromstr(msg)
        print ("Got MOTD: ",arr:get_pstring(0))
    end)
end

cord.enter_loop()


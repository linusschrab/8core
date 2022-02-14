lattice = require("lattice")

loop_end = 0
start_rec = 0
end_rec = 0

sc_rec_voice = 1
sc_pb_voice = 2

is_recording = false
arm_rec = false
arm_stop_rec = false
punch_in = false

reset_clock = true
clock_count = 5

rec_bar_count = 0
pb_bar_count = 1

screen_dirty = false

x_fade = 0
adc_fade = math.cos( (x_fade) * math.pi/2 )
softcut_fade = math.cos( (1 - x_fade) * math.pi/2 )

beat_string = " - - - +"

function init()

    crow.output[3].action = "{ to(5,0), to(5,0.01), to(0,0) }"

    softcut.level(1,x_fade)
    audio.level_monitor(1-x_fade)

    my_lattice = lattice:new()

    pattern_a = my_lattice:new_pattern {
        action = function(t) 
            --pb_bar_count = util.wrap(pb_bar_count+1,1,rec_bar_count)
            --if pb_ba_count == 1 then
              --softcut.position(1,1)
            --end
            --print("pb"..pb_bar_count)
           -- if is_recording then
             --   rec_bar_count = rec_bar_count + 1
                --print("rec"..rec_bar_count)
            --end
            if reset_clock then
                crow.output[3]()
                reset_clock = false
            end
            if arm_rec then
                --rec_bar_count = 0
                rec()
                arm_rec = false
            end
            if arm_stop_rec and is_recording then
                stop_rec()
                arm_stop_rec = false
            end    
            screen_dirty = true
        end,
        division = 1,
        enabled = true
    }

    pattern_b = my_lattice:new_pattern {
        action = function(t) 
            clock_count = util.wrap(clock_count-1,1,4)
            beat_string = string.sub(beat_string,7) .. string.sub(beat_string,1,6)
            screen_dirty = true
        end,
        division = 1/4,
        enabled = true
    }

    my_lattice:start()

    softcut.enable(1,1)
    softcut.buffer(1,1)
    softcut.level(1,0.0)
    softcut.loop(1,1)
    softcut.play(1,1)
    softcut.fade_time(1,0.01)    
    
    softcut.enable(2,1)
    softcut.buffer(2,2)
    softcut.level(2,0.0)
    softcut.loop(2,1)
    softcut.play(2,1)
    softcut.fade_time(2,0.01)

    softcut.rec(sc_rec_voice,0)
    softcut.level(sc_rec_voice,0)
    softcut.level(sc_pb_voice,softcut_fade)

    softcut.rec(sc_rec_voice,1)
    softcut.rec(sc_pb_voice,0)
    
    softcut.loop_start(sc_rec_voice,1)
    softcut.loop_start(sc_pb_voice,1)
    softcut.loop_end(sc_rec_voice,241)
    softcut.position(sc_pb_voice,1)
    softcut.position(sc_rec_voice,1)
    softcut.loop_end(sc_pb_voice,241)

    clock.run(go)
end

function go()
    while true do
        clock.sleep(1/30)
        if screen_dirty then
            redraw()
            screen_dirty = false
        end
    end
end

function redraw()
    screen.clear()
    screen.font_face(0)
    screen.font_size(8)

    screen.text_rotate(0,8,"L I V E - >",90)
    screen.text_rotate(122,8,"B U F F - >",90)

    screen.move(64,14)
    if reset_clock then
        screen.text_center("reset clock in "..clock_count)
    end

    screen.move(64,44)
    if is_recording then
        screen.text_center("R E C")
    elseif arm_rec then
        screen.text_center("A R M")
    else
        screen.text_center("P L A Y")
    end

    screen.move((x_fade)*123,64)
    screen.text("^")

    screen.font_size(16)
    screen.move(55,32)
    screen.text_center(beat_string)

    screen.update()
end

function rec()
    print("rec")
    start_rec = util.time() -- take snapshot of rec start time
    is_recording = true

    softcut.buffer_clear_channel(sc_rec_voice)
    softcut.position(sc_rec_voice,1) -- position rec_buffer at 1
    --softcut.position(sc_pb_voice,1)
    --softcut.level(1,0.0)
    softcut.rec_level(sc_rec_voice,1)
    audio.level_adc_cut(adc_fade)
    softcut.level_input_cut(1,sc_rec_voice,adc_fade/2)
    softcut.level_input_cut(2,sc_rec_voice,adc_fade/2)
    --softcut.pre_level(1,softcut_fade)
    softcut.level_cut_cut(sc_pb_voice,sc_rec_voice,softcut_fade)

    --softcut.loop_start(sc_pb_voice,1)
    --softcut.loop_end(sc_pb_voice,loop_end)
    --softcut.position(sc_pb_voice,1)
end

function stop_rec()
    print("stop")
    is_recording = false
    end_rec = util.time()  

    sc_rec_voice = util.wrap(sc_rec_voice+1,1,2)
    sc_pb_voice = util.wrap(sc_pb_voice+1,1,2)

    softcut.rec(sc_rec_voice,0)
    softcut.level(sc_rec_voice,0)
    softcut.level(sc_pb_voice,softcut_fade)

    softcut.rec(sc_rec_voice,1)
    softcut.rec(sc_pb_voice,0)
    
    softcut.loop_start(sc_rec_voice,1)
    softcut.loop_start(sc_pb_voice,1)
    softcut.loop_end(sc_rec_voice,241)
    loop_end = (end_rec - start_rec)
    --print(loop_end)
    softcut.position(sc_pb_voice,1)
    softcut.position(sc_rec_voice,1)
    softcut.loop_end(sc_pb_voice,1+loop_end)
    --softcut.loop_end(sc_rec_voice,1+loop_end)
end

function key(n,z)
    if n == 2 then
        if z == 1 then
            arm_rec = true
            --print("rec")
            punch_in = false
        else
            arm_rec = false
            arm_stop_rec = true
        end
    end
    if n == 3 then
        if z == 1 then
            reset_clock = true;
        else
            --
        end
    end
    screen_dirty = true
end

function enc(e,d)
    if e == 2 then
        x_fade = util.clamp(x_fade + d / 100,0,1)
        adc_fade = math.cos( (x_fade) * math.pi/2 )
        softcut_fade = math.cos( (1 - x_fade) * math.pi/2 )
        audio.level_monitor(adc_fade)
        softcut.level(sc_pb_voice,softcut_fade)
        --softcut.level(sc_rec_voice,softcut_fade)
        --print("xfade: " .. x_fade .. " softcut: ".. softcut_fade .. " adc: "..adc_fade)
    end
    screen_dirty = true
end

function rerun()
    norns.script.load(norns.state.script)
end
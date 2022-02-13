lattice = require("lattice")


loop_end = 0
start_rec = 0
end_rec = 0

is_recording = false
arm_rec = false
arm_stop_rec = false

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
            pb_bar_count = util.wrap(pb_bar_count+1,1,rec_bar_count)
            if pb_ba_count == 1 then
              --softcut.position(1,1)
            end
            --print("pb"..pb_bar_count)
            if is_recording then
                rec_bar_count = rec_bar_count + 1
                --print("rec"..rec_bar_count)
            end
            if reset_clock then
                crow.output[3]()
                reset_clock = false
            end
            if arm_rec then
                rec_bar_count = 0
                print("rec")
                rec()
            end
            if arm_stop_rec then
                print("stop")
                stop_rec()
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
    softcut.loop_start(1,1)
    softcut.loop_end(1,241)
    softcut.position(1,1)
    softcut.play(1,1)

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
    start_rec = util.time()
    is_recording = true
    --softcut.buffer_clear()
    --softcut.loop_start(1,1)
    softcut.loop_end(1,241)
    softcut.position(1,1)
    --softcut.level(1,0.0)
    softcut.rec(1,1)
    softcut.rec_level(1,1)
    --audio.level_adc_cut(adc_fade)
    --softcut.level_cut_cut(1,1,1)
    softcut.level_input_cut(1,1,adc_fade)
    softcut.level_input_cut(2,1,adc_fade)
    softcut.pre_level(1,softcut_fade)
    arm_rec = false
end

function stop_rec()
    is_recording = false
    end_rec = util.time()  
    softcut.rec(1,0)
    loop_end = (end_rec - start_rec)
    --print(loop_end)
    --softcut.position(1,1)
    softcut.loop_end(1,1+loop_end)
    arm_stop_rec = false
end

function key(n,z)
    if n == 2 then
        if z == 1 then
            arm_rec = true
            --print("rec")
        else
            arm_rec = false
            arm_stop_rec = true
        end
    end
    if n == 3 and z == 1 then
        reset_clock = true;
    end
    screen_dirty = true
end

function enc(e,d)
    if e == 2 then
        x_fade = util.clamp(x_fade + d / 100,0,1)
        adc_fade = math.cos( (x_fade) * math.pi/2 )
        softcut_fade = math.cos( (1 - x_fade) * math.pi/2 )
        audio.level_monitor(adc_fade)
        softcut.level(1,softcut_fade)
        --print("xfade: " .. x_fade .. " softcut: ".. softcut_fade .. " adc: "..adc_fade)
    end
    screen_dirty = true
end

function rerun()
    norns.script.load(norns.state.script)
end
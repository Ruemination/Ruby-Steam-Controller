

system("sudo", "pkill", "ydotool")
sleep(0.1)
Thread.new do
    Process.spawn("konsole", "-e", "sudo", "ydotoold")
end

class SteamController
    def initialize
        @proc_arr = []
        @proc_arr << method(:start)
        @state = 0
        @keyboard_device = File.open("/dev/input/event4", "rb")
        @controller_device = File.open("/dev/input/event18", "rb")
        @key = nil
        @button = nil
        @remap = {}
        _process
    end

    def start
        puts "Options bind|play"
        user_input = gets.chomp
        user_input.downcase!
        case user_input
        when "bind"
            @proc_arr.delete(method(:start))
            flush_keyboard()
            @proc_arr << method(:keyboard_input)
            puts "Press the key you want to bind"
        when "play"
            puts "Starting continuous remap"
            @proc_arr.delete(method(:start))
            @proc_arr << method(:continuous_controller_input)
        else
            puts "invalid option"
        end
    end

    def controller_input()
        event = @controller_device.read(24)
        ev_sec, ev_usec, type, code, value = event.unpack("q<q<SSl<")
        if type == 1 and value == 1
            @button = code
            @proc_arr.delete(method(:controller_input))
            puts "Remapped #{@button} to #{@key}"
            @remap[@button] = @key
            puts @remap
            @proc_arr << method(:start)
        end
    end

    def continuous_controller_input()
        event = @controller_device.read(24)
        ev_sec, ev_usec, type, code, value = event.unpack("q<q<SSl<")
        if type == 1 and value == 1
            if @remap.key?(code)
                system("ydotool", "key","#{@remap[code]}:1", "#{@remap[code]}:0")
                puts "pressed #{code}, simulated #{@remap[code]}"
            end
        end
    end

    def keyboard_input()
        event = @keyboard_device.read(24)
        _, _, type, code, value = event.unpack("q<q<SSl<")
        if type == 1 and value == 1
            puts code
            @key = code
            @proc_arr.delete(method(:keyboard_input))
            puts "Press the controller button you want to bind it to"
            @proc_arr << method(:controller_input)
        end
    end

    def flush_keyboard()
        loop do
            ready = IO.select([@keyboard_device], nil, nil, 0)
            break unless ready

            @keyboard_device.read(24)
        end
    end

    def _process
        loop do
            for thing in @proc_arr
                thing.call
            end
        end
    end
end

SteamController.new()

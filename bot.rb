#!/usr/local/bin/ruby
require "socket"

class Turdbot

    ####################
    #initializer
    ####################

    def initialize(server, port, nick, channel)
        @server = server
        @port = port
        @nick = nick
        @channel = channel
        @passwd = "500ner"
        @_continue = true
    end # function initialize

    ####################
    #send messages
    ####################

    def send(s)
        # Send a message to the irc server and print it to the screen
        puts "--> #{s}"
        @irc.send "#{s}\n", 0 
    end # function send

    ####################
    #randomize nick
    ####################

    def rand_nick
        new = (0...13).map { (65 + rand(26)).chr }.join
        @irc.send("NICK #{new}\n",0)

    end # function rand_nick

    ####################
    #format and send
    ####################

    def chat(s,target=@channel)
        send "PRIVMSG #{target} :#{s}"
    end # function chat

    ####################
    #establish connection
    ####################

    def connect()
        # Connect to the IRC server
        @irc = TCPSocket.open(@server, @port)
        send "USER turd bot 2.0 :the wreckening"
        send "NICK #{@nick}"
        send "JOIN #{@channel}"
    end # function connect

    ####################
    #clean commands
    ####################

    def clean(s)
        #return Shellwords.escape(s)
        return s.gsub(/[`\[\]\{\}!.\?#$%^&*;:()|\/\'\"<>]*/){|c|'\\'+c}
        #return s.gsub(/[`#$%^&\*;:()\\\/\'\"<>]*/, '')
        #return s.gsub(/[`#$%^&\*;:()\\\/\'\"<>]*/, '\\1')
    end # function clean

    ####################
    #handle server inputs
    ####################

    def handle_server_input(s)
        case s.strip
            when /^PING :(.+)$/i
                puts "[ Server ping ]"
                send "PONG :#{$1}"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
                puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001PING #{$4}\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
                puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:FORTUNE$/i
                if $1 != @nick
                    puts "[ fortune request from #{$1}!#{$2}@#{$3} ]"
                    cowsay($4)
                end
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:NEW NICK$/i
                if $1 != @nick
                    puts "[ new nick request from #{$1}!#{$2}@#{$3} ]"
                    rand_nick()
                end
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:COUNTDOWN (.+)$/i
                if $1 != @nick
                    puts "[ countdown #{s} from #{$1}!#{$2}@#{$3} ]"
                    countdown($5,$4)
                end
<<<<<<< HEAD
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:TELLEM(.+)$/i
=======
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:TELL(.+)?EM (.+)$/i
            puts "[ #{s} ]"
>>>>>>> 510b0abc7e8860e8655dc8526e73fd61ae8fdd8a
                if $1 != @nick
                    puts "[ tellem #{s}from #{$1}!#{$2}@#{$3} ]"
                    cowsay($4,"#{$6} -- #{$1}")
                end
<<<<<<< HEAD
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:STOP (.+?)$/i
=======
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:STOP(.+)?$/i
            puts "[ #{s} ]"
>>>>>>> 510b0abc7e8860e8655dc8526e73fd61ae8fdd8a
                if $1 != @nick
                    puts "[ stop request from #{$1}!#{$2}@#{$3} ]"
                    @_continue = false
                end
            else
                puts s
        end
    end # function handle_server_inputs

    ####################
    #cowsay
    ####################

    def cowsay(chan,say="$(fortune)")
        if say != "$(fortune)"
            p say
            say = clean(say)
            p say
        end
        output = `cowsay #{say}`
        p output
        output.split("\n").each { |line|
            chat(line,chan)
        }

    end # function cowsay

    ####################
    #countdown
    ####################

    def countdown(t,chan)
        t = t.to_i
        if t.is_a?(Integer) and chan.is_a?(String)
            chat("Countdown commencing...",chan)
            for i in 0..(t-1)
                if ! @_continue
                    chat("Cancelling countdown!",chan)
                    @_continue = true
                    return -1
                end 
                num = t - i
                count = sprintf("%d...",num)
                chat(count,chan)
                sleep(1)
            end
            cowsay(chan)
        else
            chat("Countdown postponed...",chan)
        end

    end # function countdown

    ####################
    #do work
    ####################

    def main_loop()
        while true
            ready = select([@irc, $stdin], nil, nil, nil)

            if !ready
                next
            end

            for s in ready[0]
                if s == $stdin then
                    return if $stdin.eof
                    s = $stdin.gets
                    send s
                elsif s == @irc then
                    return if @irc.eof
                    s = @irc.gets
                    Thread.new{handle_server_input(s)}.pass
                end
            end
            
        end
    end # function main_loop

end # class Turdbot

####################
#start
####################

irc = Turdbot.new('irc.haxzor.ninja', 6667, 'turdbot', '#botwars')
irc.connect()
begin
    irc.main_loop()
rescue Interrupt
rescue Exception => detail
    puts detail.message()
    print detail.backtrace.join("\n")
    retry
end

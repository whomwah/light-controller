require 'rubygems'
require 'osc'

configure do
  LIGHTS_PROXY = 'http://10.54.146.25'
end

helpers do
  class LC 
    LIGHTS = [1,2]

    def self.set_lights(options=nil)
      sock = OSC::UDPSocket.new
      sock.connect('10.54.146.25', 7770)

      colour = options[:colour] if options.is_a?(Hash) && options.has_key?(:colour)
      lights = options[:lights] if options.is_a?(Hash) && options.has_key?(:lights)
      result = []
      lights.each do |light|
        l = Light.new(sock,colour,light)
        result << l.display
      end 
      return result.join
    end
  end

  class Light
    COLOURS = {
      :red   => [255,0,0],
      :green => [0,255,0],
      :blue  => [0,0,255],
    }
    CHANNELS = {
      1 => [1,2,3],
      2 => [4,5,6],
    }

    def initialize(sock,colour,light)
      @colour = colour
      @light = light.to_i
      @sock = sock
    end
    
    def display
      count = 0
      colour_channel_hash.each do |c|
        @sock.send OSC::Message.new("/dmx/#{CHANNELS[@light][count]}/set", 'f', c), 0
        count = count + 1
      end
      self.to_s
    end 

    def to_s
      "<p>Setting the color to <em style='#{self.to_css}font-weight:bold;'>#{@colour}</em> for light <em>#{@light}</em></p>"
    end

    def colour_channel_hash
      if COLOURS.has_key?(@colour.to_sym)
        c = COLOURS[@colour.to_sym] 
      else
        c = @colour.gsub('rgb','').split('-')
      end
      puts c.inspect

      data = []
      (1..3).each do |i|
        data << '%.1f' % ((c[i-1].to_f/255.0 * 100.0).to_f / 100)
      end

      data
    end

    def to_css
      # color: rgb(51, 51, 51);
      if COLOURS.has_key?(@colour.to_sym)
        "color:rgb(#{COLOURS[@colour.to_sym].join(',')});" 
      else
        c = @colour.gsub('rgb','').gsub('-',',')
        "color:rgb(#{c});" 
      end
    end
  end
end

# /all/red
get %r{/(1|2|all)+/(rgb\d{0,3}-\d{0,3}-\d{0,3}|red|blue|green|random)+$} do
  lights = [params['captures'].first]
  lights = LC::LIGHTS if lights.include?('all')
  colour = params['captures'][1]
  halt 404, 'Oh dear! I understand what you\'re saying' unless lights && colour 
  LC.set_lights(
    :lights => lights,
    :colour => colour
  )
end

# /(1|2|all)+/(red|blue|green|random)+/for-seconds/(\d{2})+/(flashing|strobing)?

get '/' do
  erb :index 
end

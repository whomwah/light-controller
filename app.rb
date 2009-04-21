require 'osc'
#module OSC
#  class UDPSocket
#    def initialize
#    end
#    def connect(a,b)
#    end
#  end
#end

helpers do
  class LC 
    def self.set_lights(opts=nil)
      sock = OSC::UDPSocket.new
      sock.connect('10.54.146.25', 7770)

      halt "Need some lights" unless lights = opts.delete(:lights)

      result = []
      lights.each do |light|
        opts[:light] = light
        l = Light.new(sock, opts)
        result << l.display
      end 
      return result.join
    end
  end

  class Light
    attr_writer :rgb

    def initialize(socket, opts=nil)
      @sock = socket 
      @colour = opts[:colour] if opts.is_a?(Hash) && opts.has_key?(:colour)
      @light = opts[:light].to_i if opts.is_a?(Hash) && opts.has_key?(:light)
      @rgb = opts[:rgb]
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
      "Setting the color to <em style='#{self.to_css}font-weight:bold;'>#{@colour}</em> for light <em>#{@light}</em>\n"
    end

    def colour_channel_hash
      return [] unless @rgb

      if @rgb.has_key?(@colour.to_sym)
        c = @rgb[@colour.to_sym] 
      else
        c = @colour.gsub('rgb','').split('-')
      end

      data = []
      (1..3).each do |i|
        data << '%.1f' % ((c[i-1].to_f/255.0 * 100.0).to_f / 100)
      end

      data
    end

    def to_css
      # color: rgb(51, 51, 51);
      if @rgb.has_key?(@colour.to_sym)
        "color:rgb(#{@rgb[@colour.to_sym].join(',')});" 
      else
        c = @colour.gsub('rgb','').gsub('-',',')
        "color:rgb(#{c});" 
      end
    end
  end
end

before do
  @lights = [1,2]
  @rgb = {
    :red   => [255,0,0],
    :green => [0,255,0],
    :blue  => [0,0,255],
  }
  @channels = {
    1 => [1,2,3],
    2 => [4,5,6],
  }
end

# /all/red
get %r{/(1|2|all)+/(rgb\d{0,3}-\d{0,3}-\d{0,3}|red|blue|green|random)+$} do
  lights = [params['captures'].first]
  lights = @lights if lights.include?('all')
  colour = params['captures'][1]
  halt 404, 'Oh dear! I understand what you\'re saying' unless lights && colour 
  LC.set_lights(
    :lights => lights,
    :colour => colour,
    :rgb => @rgb,
    :channels => @channels
  )
end

# /(1|2|all)+/(red|blue|green|random)+/for-seconds/(\d{2})+/(flashing|strobing)?

get '/' do
  erb :index 
end

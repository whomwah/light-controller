require 'osc'

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
      @sock     = socket 
      @rgb      = opts[:rgb]
      @channels = opts[:channels] if opts.is_a?(Hash) && opts.has_key?(:channels)
      @colour   = opts[:colour] if opts.is_a?(Hash) && opts.has_key?(:colour)
      @light    = opts[:light].to_i if opts.is_a?(Hash) && opts.has_key?(:light)
    end
    
    def display
      count = 0
      channel_data_from_rgb(color_as_rgb).each do |c|
        @sock.send OSC::Message.new("/dmx/#{@channels[@light][count]}/set", 'f', c), 0
        count = count + 1
      end
      self.to_s
    end 

    def to_s
      "Light #{@light} : rgb(#{self.to_css})\n"
    end

    def to_css
      color_as_rgb.join(',') 
    end

    private

    def color_as_rgb 
      return [0,0,0] if @colour == 'off' 
      return [(rand * 255).to_i,(rand * 255).to_i,(rand * 255).to_i] if @colour == 'random' 

      if @rgb.has_key?(@colour.to_sym)
        return @rgb[@colour.to_sym] 
      else
        return @colour.gsub('rgb','').split('-')
      end
    end

    def channel_data_from_rgb(d)
      data = []
      (1..3).each {|i| data << '%.1f' % ((d[i-1].to_f/255.0 * 100.0).to_f / 100) }
      data
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
get %r{/(1|2|all)+/(rgb\d{0,3}-\d{0,3}-\d{0,3}|red|blue|green|random|off)+$} do
  lights = [params['captures'].first]
  lights = @lights if lights.include?('all')
  colour = params['captures'][1]
  halt 404, 'Oh dear! I understand what you\'re saying' unless lights && colour 
  content_type 'text/plain', :charset => 'utf-8'
  LC.set_lights(
    :lights => lights,
    :colour => colour,
    :rgb => @rgb,
    :channels => @channels
  )
end

get '/' do
  erb :index 
end

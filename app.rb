require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'cgi'

configure do
  LIGHTS_PROXY = 'http://54.5.5.5'
end

helpers do
  class LC 
    LIGHTS = [1,2]

    def self.set_lights(options=nil)
      colour = options[:colour] if options.is_a?(Hash) && options.has_key?(:colour)
      lights = options[:lights] if options.is_a?(Hash) && options.has_key?(:lights)
      result = []
      lights.each do |light|
        l = Light.new(colour,light)
        result << l.display
      end 
      return result.join
    end
  end

  class Light
    COLOURS = {
      :blue  => [0,0,255],
      :red   => [255,0,0],
      :green => [0,255,0],
    }

    def initialize(colour,light)
      @colour = colour
      @light = light
    end

    def display
      "<p>Setting the color to <em style='#{self.to_css}'>#{@colour}</em> for light <em>#{@light}</em></p>"
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

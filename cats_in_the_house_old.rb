require 'gosu'

module ZOrder
  Background, Tables, Cat, UI = *0..3
end

module Dimensions
  Ground = 400
  HouseStart = 0
  HouseEnd = 10000
end

class MyWindow < Gosu::Window
  def initialize
    super(640, 480, fullscreen: false)
    self.caption = 'Cats in the house!'

    @playing_cat = Cat.new
    @playing_cat.place(320, Dimensions::Ground)
    @background_image = Gosu::Image.new("media/room.png", :tileable => true)

    # @player = Player.new
    # @player.warp(320, 240)

    # @star_anim = Gosu::Image::load_tiles("media/star.png", 25, 25)
    # @stars = Array.new

    # @font = Gosu::Font.new(20)
  end

  def update
    if Gosu::button_down? Gosu::KbLeft or Gosu::button_down? Gosu::GpLeft then
      @playing_cat.left
    end
    if Gosu::button_down? Gosu::KbRight or Gosu::button_down? Gosu::GpRight then
      @playing_cat.right
    end
    if Gosu::button_down? Gosu::KbUp or Gosu::button_down? Gosu::GpButton0 then
      @playing_cat.jump
    end
    @playing_cat.move
    # @player.collect_stars(@stars)

    # if rand(100) < 4 and @stars.size < 25 then
    #   @stars.push(Star.new(@star_anim))
    # end
  end

  def draw
    @background_image.draw(0, 0, ZOrder::Background)
    @playing_cat.draw
    # @stars.each { |star| star.draw }
    # @font.draw("Score: #{@player.score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end
end

class Cat
  def initialize
    @image = Gosu::Image.new("media/cat.png")
    @x = @y = @vel_x = @vel_y = 0.0
    @direction = :right
    @score = 0
  end

  def place(x,y)
    @x, @y = x, y
  end

  def draw
    if @direction == :right
      if @vel_x > 0.5
        @image.draw_rot(@x, @y, ZOrder::Cat, -5)
      else
        @image.draw_rot(@x, @y, ZOrder::Cat, 0)
      end
    else
      if @vel_x < -0.5
        @image.draw_rot(@x, @y, ZOrder::Cat, 0, 0.5, 0.5, -1)
      else
        @image.draw_rot(@x, @y, ZOrder::Cat, 5, 0.5, 0.5, -1)
      end
    end
  end

  def left
    @vel_x += -0.7
    @direction = :left
  end

  def right
    @vel_x += 0.7
    @direction = :right
  end

  def jump
    @vel_y -= 1
  end
#     @angle -= 4.5
#   end

#   def turn_right
#     @angle += 4.5
#   end

  def move
    @x += @vel_x
    @y += @vel_y

    if @x < Dimensions::HouseStart
      @x = Dimensions::HouseStart
    end

    if @x > Dimensions::HouseEnd
      @x = Dimensions::HouseEnd
    end

    if @y > Dimensions::Ground
      @y = Dimensions::Ground
    end

    if @y < 0
      @y = 0
    end

    @vel_x *= 0.95

    if @vel_y < 0
      @vel_y *= 0.95
    end

    if @vel_y > -0.5
      # puts "snelheid = #{@x}, #{@y}, #{@vel_x}, #{@vel_y}"
      if @y < Dimensions::Ground
        if @vel_y < 1
          @vel_y = 1
        end
        @vel_y *= 1.20
      else
        @vel_y = 0
      end
    end
  end
end



# class Player
#   def initialize
#     @image = Gosu::Image.new("media/starfighter.bmp")
#     @beep = Gosu::Sample.new("media/beep.wav")
#     @x = @y = @vel_x = @vel_y = @angle = 0.0
#     @score = 0
#   end

#   def warp(x, y)
#     @x, @y = x, y
#   end

#   def turn_left
#     @angle -= 4.5
#   end

#   def turn_right
#     @angle += 4.5
#   end

#   def accelerate
#     @vel_x += Gosu::offset_x(@angle, 0.5)
#     @vel_y += Gosu::offset_y(@angle, 0.5)
#   end

#   def move
#     @x += @vel_x
#     @y += @vel_y
#     @x %= 640
#     @y %= 480

#     @vel_x *= 0.95
#     @vel_y *= 0.95
#   end

#   def draw
#     @image.draw_rot(@x, @y, 1, @angle)
#   end

#   def score
#     @score
#   end

#   def collect_stars(stars)
#     if stars.reject! {|star| Gosu::distance(@x, @y, star.x, star.y) < 35 } then
#       @score += 10
#       @beep.play
#       true
#     else
#       false
#     end
#   end
# end

# class Table
#   attr_reader :x, :y

#   def initialize(table_image)
#     @table_image = table_image
#     @color = Gosu::Color.new(0xff_000000)
#     @color.red = rand(256 - 40) + 40
#     @color.green = rand(256 - 40) + 40
#     @color.blue = rand(256 - 40) + 40
#   end

#   def draw  
#     img = @animation[Gosu::milliseconds / 100 % @animation.size];
#     img.draw(@x - img.width / 2.0, @y - img.height / 2.0,
#         ZOrder::Stars, 1, 1, @color, :add)
#   end
# end

window = MyWindow.new
window.show
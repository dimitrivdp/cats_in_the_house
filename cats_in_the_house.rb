# Encoding: UTF-8

# Basically, the tutorial game taken to a jump'n'run perspective.

# Shows how to
#  * implement jumping/gravity
#  * implement scrolling using Window#translate
#  * implement a simple tile-based map
#  * load levels from primitive text files

# Some exercises, starting at the real basics:
#  0) understand the existing code!
# As shown in the tutorial:
#  1) change it use Gosu's Z-ordering
#  2) add gamepad support
#  3) add a score as in the tutorial game
#  4) similarly, add sound effects for various events
# Exploring this game's code and Gosu:
#  5) make the player wider, so he doesn't fall off edges as easily
#  6) add background music (check if playing in Window#update to implement 
#     looping)
#  7) implement parallax scrolling for the star background!
# Getting tricky:
#  8) optimize Map#draw so only tiles on screen are drawn (needs modulo, a pen
#     and paper to figure out)
#  9) add loading of next level when all gems are collected
# ...Enemies, a more sophisticated object system, weapons, title and credits
# screens...

require 'rubygems'
require 'gosu'

WIDTH, HEIGHT = 770, 480

BLOCK_HEIGHT = 50 
BLOCK_WIDTH = 50 
CAT_HEIGHT = 50
CAT_WIDTH  = 100

module Tiles
  Grass = 0
  Earth = 1
end

module ZOrder
  Background, Map, Cat, UI = *0..3
end

class CollectibleGem
  attr_reader :x, :y

  def initialize(image, beep, x, y)
    @image = image
    @beep  = beep
    @x, @y = x, y
  end
  
  def draw
    # Draw, slowly rotating
    @image.draw_rot(@x, @y, 0, 25 * Math.sin(Gosu::milliseconds / 133.7))
  end

  def win
    @beep.play
  end
end

# Player class.
class Player
  attr_reader :x, :y, :score

  def initialize(map, x, y)
    @x, @y = x, y
    @dir = :right
    @vy = 0 # Vertical velocity
    @map = map
    # Load all animation frames
    @standing = Gosu::Image.new("media/cat3.png")
    @walk1 = Gosu::Image.new("media/cat3.png")
    @walk2 = Gosu::Image.new("media/cat3.png")
    @jump = Gosu::Image.new("media/cat3.png")
    # @standing, @walk1, @walk2, @jump = *Gosu::Image.load_tiles("media/cptn_ruby.png", 50, 50)
    # This always points to the frame that is currently drawn.
    # This is set in update, and used in draw.
    @cur_image = @standing   
    #
    @score = 0 
  end
  
  def draw
    # Flip vertically when facing to the left.
    if @dir == :left then
      offs_x = CAT_WIDTH/2 
      factor = -1.0
    else
      offs_x = -CAT_WIDTH/2
      factor = 1.0
    end
    offs_y = CAT_HEIGHT
    @cur_image.draw(@x + offs_x, @y - offs_y, 0, factor, 1.0)
  end
  
  # Could the object be placed at x + offs_x/y + offs_y without being stuck?
  def would_fit(offs_x, offs_y)
    size_difference = (CAT_WIDTH - BLOCK_WIDTH)*0.49
    # Check at the center/top and center/bottom for map collisions
    not @map.solid?(@x + offs_x - size_difference, @y + offs_y - 1) and                   # top-left
    not @map.solid?(@x + offs_x - size_difference, @y + offs_y - CAT_HEIGHT + 3 ) and     # bottom-left
    not @map.solid?(@x + offs_x + size_difference, @y + offs_y - 1) and                   # top right
    not @map.solid?(@x + offs_x + size_difference, @y + offs_y - CAT_HEIGHT + 3 ) and     # bottom right
    not @map.solid?(@x + offs_x, @y + offs_y - 1) and                                     # top center (avoid falling if 1 block)
    not @map.solid?(@x + offs_x, @y + offs_y - CAT_HEIGHT + 3 )                           # bottom center (avoid falling if 1 block)
  end
  
  def update(move_x)
    # Select image depending on action
    if (move_x == 0)
      @cur_image = @standing
    else
      @cur_image = (Gosu::milliseconds / 175 % 2 == 0) ? @walk1 : @walk2
    end
    if (@vy < 0)
      @cur_image = @jump
    end
    
    # Directional walking, horizontal movement
    if move_x > 0 then
      @dir = :right
      move_x.times { if would_fit(1, 0) then @x += 1 end }
    end
    if move_x < 0 then
      @dir = :left
      (-move_x).times { if would_fit(-1, 0) then @x -= 1 end }
    end

    # Acceleration/gravity
    # By adding 1 each frame, and (ideally) adding vy to y, the player's
    # jumping curve will be the parabole we want it to be.
    @vy += 1
    # Vertical movement
    if @vy > 0 then
      @vy.times { if would_fit(0, 1) then @y += 1 else @vy = 0 end }
    end
    if @vy < 0 then
      (-@vy).times { if would_fit(0, -1) then @y -= 1 else @vy = 0 end }
    end
  end
  
  def try_to_jump
    size_difference = (CAT_WIDTH - BLOCK_WIDTH)*0.9
    if @map.solid?(@x - size_difference, @y + 1) or @map.solid?(@x, @y + 1) or @map.solid?(@x + size_difference, @y + 1) then
      @vy = -20
    end  
  end
  
  def collect_gems(gems)
    # Same as in the tutorial game.
    gems.reject! do |c|
      if (c.x - @x).abs < 50 and (c.y - @y).abs < 50
        @score += 10
        c.win
        true
      else
        false
      end
    end
  end
end

# Map class holds and draws tiles and gems.
class Map
  attr_reader :width, :height, :gems
  
  def initialize(filename)
    # Load 60x60 tiles, 5px overlap in all four directions.
    @tileset = Gosu::Image.load_tiles("media/cat_table.png", BLOCK_WIDTH+10, BLOCK_HEIGHT+10, :tileable => true)

    @win_beep = Gosu::Sample.new("media/beep.wav")

    gem_img = Gosu::Image.new("media/vase.png")
    @gems = []

    lines = File.readlines(filename).map { |line| line.chomp }
    @height = lines.size
    @width = lines[0].size
    @tiles = Array.new(@width) do |x|
      Array.new(@height) do |y|
        case lines[y][x, 1]
        when 'T'
          Tiles::Grass
        when '#'
          Tiles::Earth
        when 'x'
          @gems.push(CollectibleGem.new(gem_img, @win_beep, x * BLOCK_WIDTH + BLOCK_WIDTH/2, y * BLOCK_HEIGHT + BLOCK_HEIGHT/2))
          nil
        else
          nil
        end
      end
    end
  end
  
  def draw
    # Very primitive drawing function:
    # Draws all the tiles, some off-screen, some on-screen.
    @height.times do |y|
      @width.times do |x|
        tile = @tiles[x][y]
        if tile
          # Draw the tile with an offset (tile images have some overlap)
          # Scrolling is implemented here just as in the game objects.
          @tileset[tile].draw(x * BLOCK_WIDTH - 5, y * BLOCK_HEIGHT - 5, 0)
        end
      end
    end
    @gems.each { |c| c.draw }
  end
  
  # Solid at a given pixel position?
  def solid?(x, y)
    y < 0 || @tiles[x / BLOCK_WIDTH][y / BLOCK_HEIGHT]
  end
end

class CatInTheHouse < Gosu::Window
  def initialize
    super(WIDTH, HEIGHT, fullscreen: true)
    
    self.caption = "Cat in the house!"
    
    @sky = Gosu::Image.new("media/wall.png", :tileable => true)
    @map = Map.new("media/home_map.txt")
    @cat = Player.new(@map, 400, 100)
    # The scrolling position is stored as top left corner of the screen.
    @camera_x = @camera_y = 0
    @font = Gosu::Font.new(20)
  end
  
  def update
    move_x = 0
    move_x -= 6 if Gosu::button_down? Gosu::KbLeft
    move_x += 6 if Gosu::button_down? Gosu::KbRight
    @cat.update(move_x)
    @cat.collect_gems(@map.gems)
    # Scrolling follows player
    @camera_x = [[@cat.x - WIDTH / 2, 0].max, @map.width * BLOCK_WIDTH - WIDTH].min
    @camera_y = [[@cat.y - HEIGHT / 2, 0].max, @map.height * BLOCK_HEIGHT - HEIGHT].min
  end
  
  def draw
    @sky.draw 0, 0, 0
    @font.draw("Score: #{@cat.score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
    Gosu::translate(-@camera_x, -@camera_y) do
      @map.draw
      @cat.draw
    end
  end
  
  def button_down(id)
    if id == Gosu::KbUp or id == Gosu::KbSpace then
      @cat.try_to_jump
    end
    if id == Gosu::KbEscape
      close
    end
  end
end

CatInTheHouse.new.show

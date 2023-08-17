
require 'pp'
require_relative './lib/skrift'

f = Font.load("resources/Ubuntu-Regular.ttf")
#f = Font.load("resources/FiraGO-Regular_extended_with_NotoSansEgyptianHieroglyphs-Regular.ttf")
#f = Font.load("/usr/share/fonts/truetype/tlwg/Umpush-BoldOblique.ttf")
#f = Font.load("/usr/share/fonts/truetype/tlwg/Garuda.ttf")
#f = Font.load("resources/FiraGO-Regular.ttf")
#f = Font.load("/usr/share/fonts/opentype/cantarell/Cantarell-Regular.otf")
p f.tables

sft = SFT.new(f)
sft.x_scale =  20
sft.y_scale =  20
sft.x_offset = 0
sft.y_offset = 0

PP.pp sft.lmetrics

gid = sft.lookup(ARGV[0][0].ord)
p gid
if ARGV[0][1]
  f.reqtable("kern")
  #PP.pp f.kerning.map {|k,v|
  #  [k.unpack("n*"), v]
  #}
  
  gid2 = sft.lookup(ARGV[0][1].ord)
  PP.pp sft.kerning(gid,gid2)
  exit
end

#gid = 12

#(0..10000).each do |gid|
#  next if gid == 5649 # FIXME
#  next if gid == 5650 # FIXME
  # 5660: FIXME. Is this past the max?
  puts "TESTING GLYPH #{gid}"
mtx = sft.gmetrics(gid)
p mtx

#p sft.gmetrics(sft.lookup(0x43))


img = Image.new(mtx.min_width, mtx.min_height)
if sft.render(gid, img)
#r = Raster.new(img.width, img.height)
#
#r.draw_line(Point.new(0,0), Point.new(img.width-1, 0))
#r.draw_line(Point.new(10,10), Point.new(20, 10))
#r.draw_line(Point.new(10,10), Point.new(20, 20))
#r.draw_line(Point.new(20,10), Point.new(30, 20))
#r.draw_line(Point.new(0,0), Point.new(img.width-1, img.height-1))
#p r
#img.pixels = r.post_process

img.height.times do |row|
  img.pixels[row*img.width .. (row+1)*img.width-1].map do |s|
    print "\033[32;48;2;#{s};#{s};#{s}m%02x " % s
  end
  puts "\033[39;49m"
end
end
#end
#

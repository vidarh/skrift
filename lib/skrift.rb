
GMetrics = Struct.new(:advance_width, :left_side_bearing, :y_offset, :min_width, :min_height)
LMetrics = Struct.new(:ascender, :descender, :line_gap)
Point = Struct.new(:x,:y)
Image = Struct.new(:width, :height, :pixels)
Kerning = Struct.new(:x_shift, :y_shift)

require_relative './skrift/sft'
require_relative './skrift/outline'
require_relative './skrift/raster'
require_relative './skrift/font'


def midpoint(a, b) # 359
  Point.new(0.5 * (a.x + b.x), 0.5 * (a.y + b.y))
end

# Applies an affine linear transformation matrix to a set of points
def transform_points(points, trf) # 367
  points.each_with_index do |pt, i|
    x = pt.x
    y = pt.y
    points[i].x = x * trf[0] + y * trf[2] + trf[4]
    points[i].y = x * trf[1] + y * trf[3] + trf[5]
  end
end

def clip_points(points, width, height) # 379
  points.each_with_index do |pt,i|
    pt = pt.dup
    points[i].x = 0.0 if pt.x < 0.0
    points[i].x = width.to_f.prev_float if pt.x >= width
    points[i].y = 0.0 if pt.y < 0.0
    points[i].y = height.to_f.prev_float if pt.y >= height
  end
end

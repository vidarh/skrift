GMetrics = Struct.new(:advance_width, :left_side_bearing, :y_offset, :min_width, :min_height)
LMetrics = Struct.new(:ascender, :descender, :line_gap)
Image = Struct.new(:width, :height, :pixels)
Kerning = Struct.new(:x_shift, :y_shift)

require_relative './skrift/sft'
require_relative './skrift/outline'
require_relative './skrift/raster'
require_relative './skrift/font'
require 'matrix'

def midpoint(a, b)
  0.5*Vector[*a]+0.5*Vector[*b]
end

# Applies an affine linear transformation matrix to a set of points
def transform_points(points, trf)
  points.each_with_index do |pt, i|
    points[i] = trf * Vector[*pt,1]
  end
end

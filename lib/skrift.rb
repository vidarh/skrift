GMetrics = Struct.new(:advance_width, :left_side_bearing, :y_offset, :min_width, :min_height)
LMetrics = Struct.new(:ascender, :descender, :line_gap)
Image = Struct.new(:width, :height, :pixels)
Kerning = Struct.new(:x_shift, :y_shift)

require_relative './skrift/version'
require_relative './skrift/sft'
require_relative './skrift/outline'
require_relative './skrift/raster'
require_relative './skrift/font'
require 'matrix'

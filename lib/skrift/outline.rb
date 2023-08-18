def midpoint(a, b); 0.5*(a+b); end

# Applies an affine linear transformation matrix to a set of points
def transform_points(trf, pts)
  pts.each {|pt| pt[0],pt[1] = *(trf * Vector[*pt,1]) }
end

class Outline
  Segment = Struct.new(:beg, :end, :ctrl)
  
  attr_reader :points, :segments
  
  def initialize
    @points, @segments = [], []
  end

  def clip_points(width, height)
    @points.each do |pt|
      pt[0] = pt[0].clamp(0, width.pred)
      pt[1] = pt[1].clamp(0, height.pred)
    end
  end

  def render(transform, image)
    transform_points(transform, @points)
    clip_points(image.width, image.height)
    buf = Raster.new(image.width, image.height)
    @segments.each do |seg|
      seg.ctrl ? tesselate_curve(seg) : buf.draw_line(@points[seg.beg], @points[seg.end])
    end
    image.pixels = buf.post_process
    return image
  end

  def tesselate_curve(curve)
    if is_flat(curve)
      @segments << Segment.new(curve.beg, curve.end)
      return
    end
    ctrl0 = @points.length
    @points << midpoint(@points[curve.beg], @points[curve.ctrl])
    ctrl1 = @points.length
    @points << midpoint(@points[curve.ctrl], @points[curve.end])
    pivot = @points.length
    @points << midpoint(@points[ctrl0], @points[ctrl1])
    tesselate_curve(Segment.new(curve.beg, pivot, ctrl0))
    tesselate_curve(Segment.new(pivot, curve.end, ctrl1))
  end

  # A heuristic to tell whether a given curve can be approximated closely enough by a line. */
  def is_flat(curve)
    g = @points[curve.ctrl] - @points[curve.beg]
    h = @points[curve.end]  - @points[curve.beg]
    (g[0]*h[1]-g[1]*h[0]).abs <= 2.0
  end
end

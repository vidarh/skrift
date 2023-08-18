
class Outline
  Segment = Struct.new(:beg, :end, :ctrl)
  
  attr_reader :points
  
  def initialize
    @points, @curves, @lines = [],[],[]
  end

  # A heuristic to tell whether a given curve can be approximated closely enough by a line. */
  def is_flat(curve)
    g = @points[curve.ctrl] - @points[curve.beg]
    h = @points[curve.end]  - @points[curve.beg]
    (g[0]*h[1]-g[1]*h[0]).abs <= 2.0
  end

  def clip_points(width, height)
    @points.each do |pt|
      pt[0] = pt[0].clamp(0, width.pred)
      pt[1] = pt[1].clamp(0, height.pred)
    end
  end

  def render(transform, image)
    transform_points(points, transform)
    clip_points(image.width, image.height)
    @curves.each { |c| tesselate_curve(c) }
    buf = Raster.new(image.width, image.height)
    draw_lines(buf)
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

  def draw_lines(buf)
    @lines.each {|line| buf.draw_line(points[line.beg], points[line.end]) }
  end

  def add_seg(seg)
    seg.ctrl ? @curves << seg : @lines << seg
  end
  
  def decode_contour(flags, base_point, count) # 909
    return true if count < 2 # Invisible (no area)

    if flags[0].allbits?(Font::POINT_IS_ON_CURVE)
      loose_end = base_point
      base_point+= 1
      flags = flags[1..-1]
      count -= 1
    elsif flags[count - 1].allbits?(Font::POINT_IS_ON_CURVE)
      count -= 1
      loose_end = base_point + count
    else
      loose_end = self.points.length
      @points << midpoint(self.points[base_point], self.points[base_point + count - 1])
    end
    beg  = loose_end
    ctrl = nil
    count.times do |i|
      cur = base_point + i
      if flags[i].allbits?(Font::POINT_IS_ON_CURVE)
        add_seg(Segment.new(beg, cur, ctrl))
        beg = cur
        ctrl = nil
      else
        if ctrl
          center = @points.length
          @points << midpoint(self.points[ctrl], self.points[cur])
          @curves << Segment.new(beg, center, ctrl)
          beg = center
        end
        ctrl = cur
      end
    end
    add_seg(Segment.new(beg, loose_end, ctrl))
    return true
  end
end

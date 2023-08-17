
class Outline
  Line  = Struct.new(:beg, :end)
  Curve = Struct.new(:beg, :end, :ctrl)
  
  attr_reader :points
  
  def initialize
    @points, @curves, @lines = [],[],[]
  end

  # A heuristic to tell whether a given curve can be approximated closely enough by a line. */
  def is_flat(curve)
    a = @points[curve.beg]
    b = @points[curve.ctrl]
    c = @points[curve.end]
    g = Point.new(b.x-a.x, b.y-a.y)
    h = Point.new(c.x-a.x, c.y-a.y)
    area2 = (g.x*h.y-h.x*g.y).abs
    area2 <= 2.0
  end

  def render(transform, image) # 1317
    transform_points(self.points, transform)
    clip_points(self.points,image.width, image.height)
    tesselate_curves
    buf = Raster.new(image.width, image.height)
    draw_lines(buf)
    image.pixels = buf.post_process
    return image
  end

  def tesselate_curve(curve)
    stack=[]
    top = 0
    loop do
      if is_flat(curve)
        @lines << Line.new(curve.beg, curve.end)
        return if top == 0
        top -= 1
        curve = stack[top]
      else
        ctrl0 = @points.length
        @points << midpoint(@points[curve.beg], @points[curve.ctrl])
        ctrl1 = @points.length
        @points << midpoint(@points[curve.ctrl], @points[curve.end])
        pivot = @points.length
        @points << midpoint(@points[ctrl0], @points[ctrl1])
        stack[top] = Curve.new(curve.beg, pivot, ctrl0)
        top += 1
        curve = Curve.new(pivot, curve.end, ctrl1)
      end
    end
  end


  def tesselate_curves
    @curves.each { |c| tesselate_curve(c) }
  end

  def draw_lines(buf)
    @lines.each {|line| buf.draw_line(points[line.beg], points[line.end]) }
  end

  def add_elem(beg, cur, ctrl)
    if ctrl
      @curves << Curve.new(beg, cur, ctrl)
    else
      @lines << Line.new(beg, cur)
    end
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
      self.points << midpoint(self.points[base_point], self.points[base_point + count - 1])
    end
    beg  = loose_end
    ctrl = nil
    count.times do |i|
      cur = base_point + i
      if flags[i].allbits?(Font::POINT_IS_ON_CURVE)
        add_elem(beg, cur, ctrl)
        beg = cur
        ctrl = nil
      else
        if ctrl
          center = @points.length
          @points << midpoint(self.points[ctrl], self.points[cur])
          @curves << Curve.new(beg, center, ctrl)
          beg = center
        end
        ctrl = cur
      end
    end
    add_elem(beg, loose_end, ctrl)
    return true
  end
end

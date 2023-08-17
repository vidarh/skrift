class Raster
  Cell = Struct.new(:area, :cover)

  def initialize width, height
    @width = width
    @height = height
    @cells = (0..(width*height-1)).map { Cell.new(0.0,0.0) }
  end

  # Integrate the values in the buffer to arrive at the final grayscale image.
  def post_process
    accum = 0.0
    (@width*@height).times.collect do |i|
      cell = @cells[i]
      value = (accum + cell.area).abs
      value = [value, 1.0].min * 255.0 + 0.5
      accum += cell.cover
      value.to_i & 0xff
    end
  end

  # Draws a line into the buffer. Uses a custom 2D raycasting algorithm to do so.
  def draw_line(origin, goal)
    prev_distance = 0.0
    num_steps = 0
    delta = goal-origin
    dir_x = delta[0] <=> 0
    dir_y = delta[1] <=> 0
    next_crossing = Vector[0.0,0.0]
    pixel = Vector[0,0]
    return if dir_y == 0

    crossing_incr_x = dir_x != 0 ? (1.0 / delta[0]).abs : 1.0
    crossing_incr_y = (1.0 / delta[1]).abs

    if dir_x == 0
      pixel[0] = origin[0].floor
      next_crossing[0] = 100.0
    else
      if dir_x > 0
        pixel[0] = origin[0].floor
        next_crossing[0] = crossing_incr_x - (origin[0] - pixel[0]) * crossing_incr_x
        num_steps += goal[0].ceil - origin[0].floor - 1
      else
        pixel[0] = origin[0].ceil - 1
        next_crossing[0] = (origin[0] - pixel[0]) * crossing_incr_x
        num_steps += origin[0].ceil - goal[0].floor - 1
      end
    end

    if dir_y > 0
      pixel[1] = origin[1].floor
      next_crossing[1] = crossing_incr_y - (origin[1] - pixel[1]) * crossing_incr_y
      num_steps += goal[1].ceil - origin[1].floor - 1
    else
      pixel[1] = origin[1].ceil - 1
      next_crossing[1] = (origin[1] - pixel[1]) * crossing_incr_y
      num_steps += origin[1].ceil - goal[1].floor - 1
    end

    next_distance = next_crossing.min
    half_delta_x = 0.5 * delta[0]
    setcell = ->(nd) do
      x_average = origin[0] + (prev_distance + nd) * half_delta_x - pixel[0]
      y_difference = (nd - prev_distance).to_f * delta[1]
      cell = @cells[pixel[1] * @width + pixel[0]]
      cell.cover += y_difference
      cell.area  += (1.0 - x_average) * y_difference
    end
    num_steps.times do
      setcell.call(next_distance)
      prev_distance = next_distance
      along_x = next_crossing[0] < next_crossing[1]
      pixel += along_x ? Vector[dir_x,0] : Vector[0,dir_y]
      next_crossing += along_x ? Vector[crossing_incr_x, 0.0] : Vector[0.0, crossing_incr_y]
      next_distance = next_crossing.min
    end
    setcell.call(1.0)
  end
end

class Raster
  Cell = Struct.new(:area, :cover)

  def initialize width, height
    @width = width
    @height = height
    @cells = (0..(width*height-1)).map { Cell.new(0.0,0.0) }
  end

  def print_debug
    @height.times do |y|
      @width.times do |x|
        cell = @cells[y*@width + x]
        if cell.area == 0.0 && cell.cover == 0.0
          print "0 "
        else
          printf "(a: %4.2f; c: %4.2f) ", cell.area, cell.cover
        end
      end
      puts
    end
  end
  
  # Integrate the values in the buffer to arrive at the final grayscale image.
  def post_process
    image = []
    accum = 0.0
    num = @width * @height
    (0..num-1).each do |i|
      cell = @cells[i]
      value = (accum + cell.area).abs
      value = [value, 1.0].min * 255.0 + 0.5
      image << (value.to_i & 0xff)
      accum += cell.cover
    end
    image
  end

  # Draws a line into the buffer. Uses a custom 2D raycasting algorithm to do so.
  def draw_line(origin, goal)
    prev_distance = 0.0
    num_steps = 0
    delta = Point.new(goal.x - origin.x, goal.y - origin.y)
    dir_x = delta.x <=> 0
    dir_y = delta.y <=> 0
    next_crossing = Point.new
    return if dir_y == 0

    crossing_incr = Point.new(
      dir_x != 0 ? (1.0 / delta.x).abs : 1.0,
      (1.0 / delta.y).abs
    )

    pixel = Point.new
    if dir_x == 0
      pixel.x = origin.x.floor
      next_crossing.x = 100.0
    else
      if dir_x > 0
        pixel.x = origin.x.floor
        next_crossing.x = crossing_incr.x - (origin.x - pixel.x) * crossing_incr.x
        num_steps += goal.x.ceil - origin.x.floor - 1
      else
        pixel.x = origin.x.ceil - 1
        next_crossing.x = (origin.x - pixel.x) * crossing_incr.x
        num_steps += origin.x.ceil - goal.x.floor - 1
      end
    end

    if dir_y > 0
      pixel.y = origin.y.floor
      next_crossing.y = crossing_incr.y - (origin.y - pixel.y) * crossing_incr.y
      num_steps += goal.y.ceil - origin.y.floor - 1
    else
      pixel.y = origin.y.ceil - 1
      next_crossing.y = (origin.y - pixel.y) * crossing_incr.y
      num_steps += origin.y.ceil - goal.y.floor - 1
    end

    next_distance = [next_crossing.x, next_crossing.y].min
    half_delta_x = 0.5 * delta.x
    (0..num_steps-1).each do |step|
      x_average = origin.x + (prev_distance + next_distance) * half_delta_x
      y_difference = (next_distance - prev_distance).to_f * delta.y
      cell = @cells[pixel.y * @width + pixel.x]
      cell.cover += y_difference
      x_average -= pixel.x.to_f
      cell.area += (1.0 - x_average) * y_difference
      prev_distance = next_distance
      along_x = next_crossing.x < next_crossing.y
      pixel.x += along_x ? dir_x : 0
      pixel.y += along_x ? 0 : dir_y
      next_crossing.x += along_x ? crossing_incr.x : 0.0
      next_crossing.y += along_x ? 0.0 : crossing_incr.y
      next_distance = [next_crossing.x, next_crossing.y].min
    end
    x_average    = origin.x + (prev_distance+1.0)*half_delta_x
    y_difference = (1.0 - prev_distance) * delta.y
    cell = @cells[pixel.y * @width + pixel.x]
    cell.cover += y_difference
    x_average -= pixel.x.to_f
    cell.area += (1.0 - x_average) * y_difference
  end
end

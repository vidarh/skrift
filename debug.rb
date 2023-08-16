class Point
  def inspect
    "(#{@x}, #{@y})"
  end
end

class Outline
  def print_outline
    p "OUTLINE:"
    puts "  points:"
    points.each do |pt|
      puts "    #{pt.inspect}"
    end
    puts "  curves:"
    curves.each do |c|
      puts "    #{c.inspect}"
    end
    puts "  lines:"
    lines.each do |l|
      puts "    #{l.inspect}"
    end
  end
end

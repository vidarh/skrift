class SFT
  DOWNWARD_Y = 0x01

  attr_accessor :font, :x_scale, :y_scale, :x_offset, :y_offset, :flags

  def initialize(font)
    @font = font
    @x_scale  = 32
    @y_scale  = 32
    @x_offset = 0
    @y_offset = 0
    @flags = SFT::DOWNWARD_Y
  end

  def lookup(codepoint)
    return font.glyph_id(codepoint)
  end

  def glyph_bbox(outline)
    box = @font.glyph_bbox(outline)
    raise if !box
    # Transform the bounding box into SFT coordinate space
    xs = @x_scale.to_f / @font.units_per_em
    ys = @y_scale.to_f / @font.units_per_em
    box[0] = (box[0] * xs + @x_offset).floor
    box[1] = (box[1] * ys + @y_offset).floor
    box[2] = (box[2] * xs + @x_offset).ceil
    box[3] = (box[3] * ys + @y_offset).ceil
    return box
  end

  def gmetrics(glyph) # 149
    raise "out of bounds" if glyph < 0
    xs = @x_scale.to_f / @font.units_per_em
    adv, lsb = @font.hor_metrics(glyph)

    return nil if adv.nil?
    metrics = GMetrics.new
    metrics.advance_width = adv * xs
    metrics.left_side_bearing = lsb * xs + @x_offset

    outline = font.outline_offset(glyph)
    return metrics if outline.nil?
    bbox = glyph_bbox(outline)
    return nil if !bbox
    metrics.min_width = bbox[2] - bbox[0] + 1
    metrics.min_height= bbox[3] - bbox[1] + 1
    metrics.y_offset  = @flags & SFT::DOWNWARD_Y != 0 ? bbox[3] : bbox[1]
    return metrics
  end

  def lmetrics
    hhea= font.reqtable("hhea")
    factor = @y_scale.to_f / @font.units_per_em
    LMetrics.new(
      font.geti16(hhea + 4) * factor, # ascender
      font.geti16(hhea + 6) * factor, # descender
      font.geti16(hhea + 8) * factor  # line_gap
    ) 
  end

  def render(glyph, image) # 239
    outline = @font.outline_offset(glyph)
    p outline
    return false if outline.nil?
    return true if outline.nil?
    bbox = glyph_bbox(outline)
    return false if !bbox
    # Set up the transformation matrix such that
    # the transformed bounding boxes min corner lines
    # up with the (0, 0) point.
    transform=[]
    transform[0] = @x_scale.to_f / @font.units_per_em
    transform[1] = 0.0
    transform[2] = 0.0
    transform[4] = @x_offset - bbox[0]
    if @flags.allbits?(SFT::DOWNWARD_Y)
      transform[3] = - @y_scale.to_f / @font.units_per_em
      transform[5] = bbox[3] - @y_offset
    else
      transform[3] = + @y_scale.to_f / @font.units_per_em
      transform[5] = @y_offset - bbox[1]
    end
    outl = Outline.new
    return false if @font.decode_outline(outline, 0, outl) < 0
    outl.render(transform, image)
  end

  def kerning(left_glyph, right_glyph) # 176
    k = font.kerning
    k[[left_glyph,right_glyph].pack("n*")]
  end
end

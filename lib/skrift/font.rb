class Font
  # TrueType, TrueType, OpenType
  FILE_MAGIC = ["\0\1\0\0", "true", "OTTO"]

  POINT_IS_ON_CURVE    = 0x01
  X_CHANGE_IS_SMALL    = 0x02
  Y_CHANGE_IS_SMALL    = 0x04
  REPEAT_FLAG          = 0x08
  X_CHANGE_IS_ZERO     = 0x10
  X_CHANGE_IS_POSITIVE = 0x10
  Y_CHANGE_IS_ZERO     = 0x20
  Y_CHANGE_IS_POSITIVE = 0x20

  HORIZONTAL_KERNING   = 0x01
  MINIMUM_KERNING      = 0x02
  CROSS_STREAM_KERNING = 0x04
  OVERRIDE_KERNING     = 0x08

  OFFSETS_ARE_LARGE         = 0x001
  ACTUAL_XY_OFFSETS         = 0x002
  GOT_A_SINGLE_SCALE        = 0x008
  THERE_ARE_MORE_COMPONENTS = 0x020
  GOT_AN_X_AND_Y_SCALE      = 0x040
  GOT_A_SCALE_MATRIX        = 0x080
  
  attr_accessor :memory, :units_per_em

  def initialize(memory) # 333
    @memory = memory
    raise "Unsupported format (magic value: #{at(0,4).inspect})" if !FILE_MAGIC.member?(at(0,4))
    head = reqtable("head")
    @units_per_em  = getu16(head + 18)
    @loca_format   = geti16(head + 50)
    hhea = reqtable("hhea")
    @num_long_hmtx = getu16(hhea + 34)
  end

  def Font.load(filename) # loadfile, 103
    memory = File.read(filename).force_encoding("ASCII-8BIT")
    Font.new(memory)
  end

  def at(offset, len=1)
    raise "Out of bounds #{offset} / len #{len} (max: #{@memory.size})" if offset.to_i + len.to_i >= @memory.size
    @memory[offset..(offset+len-1)]
  end

  def getu8(offset); at(offset).ord; end
  def geti8(offset); at(offset).unpack1("c"); end
  def getu16(offset); at(offset,2).unpack1("S>"); end
  def geti16(offset); at(offset,2).unpack1("s>"); end
  def getu32(offset); at(offset,4).unpack1("N"); end

  def tables
    @tables ||= Hash[*
      getu16(4).times.collect {|t| [at(t*16 + 12,4),getu32(t*16 + 20)] }.flatten
    ]
  end

  def reqtable(tag)
    tables[tag] or raise "Unable to get table '#{tag}'"
  end

  def gettable(tag) # 557
    return tables[tag]
  end

  def glyph_bbox(outline)
    box = [0,0,0,0]
    box[0] = geti16(outline + 2)
    box[1] = geti16(outline + 4)
    box[2] = geti16(outline + 6)
    box[3] = geti16(outline + 8)
    raise "Broken bbox #{box.inspect}" if box[2] <= box[0] || box[3] <= box[1]
    return box
  end

  # Returns the offset into the font that the glyph's outline is stored at
  def outline_offset(glyph) # 806
    loca = reqtable("loca")
    glyf = reqtable("glyf")
    if @loca_format == 0
      base = loca + 2 * glyph
      this  = 2 * getu16(base)
      next_ = 2 * getu16(base + 2)
    else
      base = loca + 4 * glyph
      this = getu32(base)
      next_= getu32(base + 4)
    end
    return this == next_ ? nil : glyf + this
  end

  def each_cmap_entry
    cmap = reqtable("cmap")
    getu16(cmap + 2).times do |idx|
      entry = cmap + 4 + idx * 8
      type = getu16(entry) * 0100 + getu16(entry + 2)
      table = cmap + getu32(entry + 4)
      format = getu16(table)
      yield(type, table, format)
    end
  end
  
  # Maps unicode code points to glyph indices
  def glyph_id(char_code)
    each_cmap_entry do |type, table, format|
      if (type == 0004 || type == 0312)
        return cmap_fmt12_13(table, char_code, 12) if format == 12
        return nil
      end
    end

    # If no full repertoire cmap was found, try looking for a Unicode BMP map
    each_cmap_entry do |type, table, format|
      if type == 0003 || type == 0301
        return cmap_fmt4(table + 6, char_code) if format == 4
        return cmap_fmt6(table + 6, char_code) if format == 6
        return nil
      end
    end
    return nil
  end

  def hor_metrics(glyph)
    hmtx = reqtable("hmtx")
    return nil if hmtx.nil?
    if glyph < @num_long_hmtx
      # Glyph is inside long metrics segment
      offset = hmtx + 4 * glyph
      return getu16(offset), geti16(offset + 2)
    end
    # Glyph is inside short metrics segment
    boundary = hmtx + 4 * @num_long_hmtx
    return nil if boundary < 4
    offset = boundary - 4
    advance_width = getu16(offset)
    offset = boundary + 2 * (glyph - @num_long_hmtx)
    return advance_width, geti16(offset)
  end


  def cmap_fmt4(table, char_code) # 572
    # cmap format 4 only supports the Unicode BMP
    return nil if char_code > 0xffff
    seg_count_x2 = getu16(table)
    raise "Error" if (seg_count_x2 & 1) != 0 or seg_count_x2 == 0
    # Find starting positions of the relevant arrays
    end_codes        = table + 8
    start_codes      = end_codes + seg_count_x2 + 2
    id_deltas        = start_codes + seg_count_x2
    id_range_offsets = id_deltas + seg_count_x2

    # Find the segment that contains short_code by binary searching over
    # the highest codes in the segments
    @ecodes ||= at(end_codes,seg_count_x2 -1).unpack("n*")
    seg_id_x_x2 = @ecodes.bsearch_index {|i| i > char_code } * 2

    # Look up segment info from the arrays & short circuit if the spec requires
    start_code = getu16(start_codes + seg_id_x_x2)
    return 0 if start_code > char_code
    id_delta = getu16(id_deltas + seg_id_x_x2)
    if (id_range_offset = getu16(id_range_offsets + seg_id_x_x2)) == 0
      # Intentional integer under- and overflow
      return (char_code + id_delta) & 0xffff
    end
    # Calculate offset into glyph array and determine ultimate value
    id_offset = id_range_offsets + seg_id_x_x2 + id_range_offset + 2 * (char_code - start_code)
    id = getu16(id_offset)
    return id ? (id + id_delta) & 0xffff : 0
  end


  # For a 'simple' outline, decodes both X and Y coordinates for each point of the outline
  def simple_points(offset, num_pts, flags, points, base_point) # 866
    accum = 0
    num_pts.times do |i|
      if flags[i].allbits?(X_CHANGE_IS_SMALL)
        value = getu8(offset)
        offset += 1
        bit = flags[i].allbits?(X_CHANGE_IS_POSITIVE) ? 1 : 0
        accum -= (value ^ -bit) + bit
      elsif flags[i].nobits?(X_CHANGE_IS_ZERO)
        accum += geti16(offset)
        offset += 2
      end
      points << Vector[accum.to_f,0.0]
    end

    accum = 0
    num_pts.times do |i|
      if flags[i].allbits?(Y_CHANGE_IS_SMALL)
        value = getu8(offset)
        offset+=1
        bit = flags[i].allbits?(Y_CHANGE_IS_POSITIVE) ? 1 : 0
        accum -= (value ^ -bit) + bit
      elsif flags[i].nobits?(Y_CHANGE_IS_ZERO)
        accum += geti16(offset)
        offset += 2
      end
      points[base_point+i][1] = accum.to_f
    end
    true
  end

  def decode_outline(offset, rec_depth = 0, outl = Outline.new)
    num_contours = geti16(offset)
    return nil if num_contours == 0
    return simple_outline(offset + 10, num_contours, outl) if num_contours > 0
    return compound_outline(offset + 10, rec_depth, outl)
  end

  def cmap_fmt6(table, char_code) # 621
    return nil if char_code > 0xffff
    first_code  = getu16(table)
    return nil if (char_code < first_code)
    entry_count = getu16(table + 2)
    char_code -= first_code
    return nil if (char_code >= entry_count)
    return getu16(table + 4 + 2 * char_code)
  end

  def cmap_fmt12_13(table, char_code, which) # 645
    getu32(table + 12).times do |i|
      first_code   = getu32(table + (i * 12) + 16)
      last_code    = getu32(table + (i * 12) + 16 + 4)
      next if char_code < first_code || char_code > last_code
      glyph_offset = getu32(table + (i * 12) + 16 + 8)
      glyph_offset += char_code-first_code if which == 12
      return glyph_offset
    end
    return nil
  end

  # For a simple outline, determines each point of the outline with a set of flags
  def simple_flags(off, num_pts, flags) # 840
    value  = 0
    repeat = 0
    num_pts.times do |i|
      if repeat > 0
        repeat -= 1
      else
        value = getu8(off)
        off += 1
        if value.allbits?(REPEAT_FLAG)
          repeat = getu8(off)
          off += 1
        end
      end
      flags[i] = value
    end
    return off
  end

  def simple_outline(offset, num_contours, outl = Outline.new)
    base_points = outl.points.length
    num_pts = getu16(offset + (num_contours - 1) *2)
    raise "Overflow" if num_pts > 65535
    num_pts += 1
    end_pts = []
    num_contours.times do |i|
      end_pts << getu16(offset)
      offset += 2
    end
    # Ensure that end_pts are never falling
    # Falling end_pts have no sensible interpretation and most likely only occur in malicious input
    end_pts.each_cons(2) { |a, b| raise if b < a + 1 }
    offset += 2 + getu16(offset)

    flags = []
    offset = simple_flags(offset, num_pts, flags)
    raise if offset.nil?
    raise if !simple_points(offset, num_pts, flags, outl.points, base_points)

    beg = 0
    num_contours.times do |i|
      count = end_pts[i] - beg + 1
      outl.decode_contour(flags[beg..-1], base_points+beg, count)
      beg = end_pts[i] + 1
    end
    outl
  end

  def compound_outline(offset, rec_depth, outl) # 1057
    # Guard against infinite recursion (compound glyphs that have themselves as component).
    return -1 if rec_depth >= 4
    flags = THERE_ARE_MORE_COMPONENTS
    while flags.allbits?(THERE_ARE_MORE_COMPONENTS)
      flags = getu16(offset)
      glyph = getu16(offset + 2)
      offset += 4
      # We don't implement point matching, and neither does stb truetype
      return -1 if (flags & ACTUAL_XY_OFFSETS) == 0
      # Read additional X and Y offsets (in FUnits) of this component.
      if (flags & OFFSETS_ARE_LARGE) != 0
        local = Matrix[[1.0, 0.0, geti16(offset)], [1.0,0.0, geti16(offset+2)]]
        offset += 4
      else
        local = Matrix[[1.0, 0.0, geti8(offset)], [1.0, 0.0, geti8(offset)+1]]
        offset += 2
      end

      if flags.allbits?(GOT_A_SINGLE_SCALE)
        local[0][0] = local[1][0] = geti16(offset) / 16384.0
        offset += 2
      elsif flags.allbits?(GOT_AN_X_AND_Y_SCALE)
        local[0][0] = geti16(offset + 0) / 16384.0
        local[1][0] = geti16(offset + 2) / 16384.0
        offset += 4
      elsif flags.allbits?(GOT_A_SCALE_MATRIX)
        local[0][0] = geti16(offset + 0) / 16384.0
        local[0][1] = geti16(offset + 2) / 16384.0
        local[1][0] = geti16(offset + 4) / 16384.0
        local[1][1] = geti16(offset + 6) / 16384.0
        offset += 8
      end
      outline = outline_offset(glyph)
      return nil if outline.nil?
      base_point = outl.points.length
      return nil if decode_outline(outline, rec_depth + 1, outl).nil?
      transform_points(outl.points[base_point..-1], local)
    end
    return outl
  end

  def kerning
    return @kerning if @kerning
    offset = gettable("kern")
    return nil if offset.nil? || getu16(offset) != 0
    offset += 4
    @kerning = {}
    getu16(offset - 2).times do
      # Read subtable header
      length = getu16(offset + 2)
      format = getu8(offset + 4)
      flags  = getu8(offset + 5)
      offset += 6
      if format == 0 && flags.allbits?(HORIZONTAL_KERNING) && flags.nobits?(MINIMUM_KERNING)
        offset += 8
        getu16(offset-8).times do |i|
          v = geti16(offset+i*6+4)
          @kerning[at(offset+i*6,4)] =
            Kerning.new(* flags.allbits?(CROSS_STREAM_KERNING) ? [0,v] : [v,0])
        end
      end
      offset += length
    end
    @kerning
  end
end

###*
@class
Viewer for mrb binary
###
class MrbViewer extends Editor
  Editor.addEditor(this)
  @suffix: ["mrb"]
  @editable: false

  constructor: (fileEntry) ->
    super(fileEntry, "ace/mode/yaml")

  ###*
  @protected
  Convert contents on load
  @param {ArrayBuffer} arrayBuf   Data to convert
  @return {String} Converted string
  ###
  convertOnLoad: (arrayBuf) ->
    r = {}
    m = []
    i = 0
    [r.rite_binary_header, i] = @_loadRiteBinaryHeader(arrayBuf, i)
    if r.rite_binary_header.binary_identify == "RITE" and
       r.rite_binary_header.binary_version == "0003"
      s = 0
      n = null
      while (s == 0) or r[n].section_identify != "END\0"
        try
          n = "section_#{s}"
          [r[n], i] = @_loadRiteSection(arrayBuf, i)
          s += 1
        catch
          break
      if arrayBuf.byteLength > i
        m.push("Found #{arrayBuf.byteLength - i} bytes junk after END section")
    else
      m.push("This file is not supported")
    if m.length > 0
      r.messages = m
    jsyaml.safeDump(r, {styles: {"!!int": "hex"}})

  _bin_to_u32_le: (a) ->
    # Little-endian
    (a[3] << 24) | (a[2] << 16) | (a[1] << 8) | a[0]

  _bin_to_u32_be: (a) ->
    # Big-endian
    (a[0] << 24) | (a[1] << 16) | (a[2] << 8) | a[3]

  _bin_to_u16_be: (a) ->
    # Big-endian
    (a[0] << 8) | a[1]

  _loadRiteBinaryHeader: (arrayBuf, offset) ->
    h = new Uint8Array(arrayBuf, offset, 22)
    [{
      binary_identify: String.fromCharCode.apply(null, h.subarray(0, 4))
      binary_version: String.fromCharCode.apply(null, h.subarray(4, 8))
      binary_crc: @_bin_to_u16_be(h.subarray(8, 10))
      binary_size: @_bin_to_u32_be(h.subarray(10, 14))
      compiler_name: String.fromCharCode.apply(null, h.subarray(14, 18))
      compiler_version: String.fromCharCode.apply(null, h.subarray(18, 22))
    }, offset + h.byteLength]

  _loadRiteSection: (arrayBuf, offset) ->
    h = new Uint8Array(arrayBuf, offset, 8)
    r = {
      offset: offset
      section_identify: String.fromCharCode.apply(null, h.subarray(0, 4))
      section_size: @_bin_to_u32_be(h.subarray(4, 8))
    }
    h = new Uint8Array(arrayBuf, offset + 8, r.section_size - 8)
    switch r.section_identify
      when "IREP"
        r.rite_version = String.fromCharCode.apply(null, h.subarray(0, 4))
        r.record_size = @_bin_to_u32_be(h.subarray(4, 8))
        r.number_of_locals = @_bin_to_u16_be(h.subarray(8, 10))
        r.number_of_regs = @_bin_to_u16_be(h.subarray(10, 12))
        r.number_of_child_ireps = @_bin_to_u16_be(h.subarray(12, 14))
        n = @_bin_to_u32_be(h.subarray(14, 18))
        pad = (4 - (offset + 18) % 4) % 4
        r.iseq = {number_of_opcodes: n, padding_bytes: pad, opcodes: []}
        i = 18 + pad
        while n > 0
          c = @_bin_to_u32_be(h.subarray(i, i + 4))
          [c1,c2] = @_decodeRiteInst(c)
          c1 = c1.replace("\t", " ") + "                                        "
          r.iseq.opcodes.push("#{c1.substring(0, 20)}# #{c2}")
          i += 4
          n -= 1
        n = @_bin_to_u32_be(h.subarray(i, i + 4))
        i += 4
        r.pool = {length_of_pool: n, values: []}
        while n > 0
          n -= 1
        n = @_bin_to_u32_be(h.subarray(i, i + 4))
        i += 4
        r.syms = {number_of_syms: n, symbols: []}
        while n > 0
          len = @_bin_to_u16_be(h.subarray(i, i + 2))
          i += 2
          if len == 0xffff
            r.syms.symbols.push(null)
          else
            r.syms.symbols.push(String.fromCharCode.apply(null, h.subarray(i, i + len)))
            i += (len + 1)
          n -= 1
        null
    offset += r.section_size
    [r, offset]

  _decodeRiteInst: (code) ->
    op = (code) & 0x7f
    a = (code >> 23) & 0x1ff
    b = (code >> 14) & 0x1ff
    c = (code >> 7) & 0x7f
    bx = (code >> 7) & 0xffff
    sbx = bx - (0xffff >> 1)
    switch (code & 0x7f)
      when 0x00
        ["OP_NOP", "No operation"]
      when 0x01
        ["OP_MOVE\t#{a}, #{b}", "R(#{a}) := R(#{b})"]
      when 0x02
        ["OP_LOADL\t#{a}, #{bx}", "R(#{a}) := Pool(#{bx})"]
      when 0x03
        ["OP_LOADI\t#{a}, #{sbx}", "R(#{a}) := #{sbx}"]
      when 0x04
        ["OP_LOADSYM\t#{a}, #{bx}", "R(#{a}) := Syms(#{bx})"]
      when 0x05
        ["OP_LOADNIL\t#{a}", "R(#{a}) := nil"]
      when 0x06
        ["OP_LOADSELF\t#{a}", "R(#{a}) := self"]
      when 0x07
        ["OP_LOADT\t#{a}", "R(#{a}) := true"]
      when 0x08
        ["OP_LOADF\t#{a}", "R(#{a}) := false"]
      when 0x09
        ["OP_GETGLOBAL\t#{a}, #{bx}", "R(#{a}) := getglobal(Syms(#{bx}))"]
      when 0x0a
        ["OP_SETGLOBAL\t#{a}, #{bx}", "setglobal(Syms(#{bx}),R(#{a}))"]
      when 0x0b
        ["OP_GETSPECIAL\t#{a}, #{bx}", "R(#{a}) := Special[#{bx}]"]
      when 0x0c
        ["OP_SETSPECIAL\t#{a}, #{bx}", "Special[#{bx}] := R(#{a})"]
      when 0x0d
        ["OP_GETIV\t#{a}, #{bx}", "R(#{a}) := ivget(Syms(#{bx}))"]
      when 0x0e
        ["OP_SETIV\t#{a}, #{bx}", "ivset(Syms(#{bx}),R(#{a}))"]
      when 0x0f
        ["OP_GETCV\t#{a}, #{bx}", "R(#{a}) := cvget(Syms(#{bx}))"]
      when 0x10
        ["OP_SETCV\t#{a}, #{bx}", "cvset(Syms(#{bx}),R(#{a}))"]
      when 0x11
        ["OP_GETCONST\t#{a}, #{bx}", "R(#{a}) := constget(Syms(#{bx}))"]
      when 0x12
        ["OP_SETCONST\t#{a}, #{bx}", "constset(Syms(#{bx}),R(#{a}))"]
      when 0x13
        ["OP_GETMCNST\t#{a}, #{bx}", "R(#{a}) := R(#{a+1})::Syms(#{bx})"]
      when 0x14
        ["OP_SETMCNST\t#{a}, #{bx}", "R(#{a+1})::Syms(#{bx}) := R(#{a})"]
      # when 0x15
      # when 0x16
      when 0x17
        ["OP_JMP\t#{sbx}", "pc+=#{sbx}"]
      when 0x18
        ["OP_JMPIF\t#{a}, #{sbx}", "if R(#{a}) pc+=#{sbx}"]
      when 0x19
        ["OP_JMPNOT\t#{a}, #{sbx}", "if !R(#{a}) pc+=#{sbx}"]
      # when 0x1a
      # when 0x1b
      # when 0x1c
      # when 0x1d
      # when 0x1e
      # when 0x1f
      when 0x20
        if c == 0
          args = ""
        else if c == 1
          args = ",R(#{a+1})"
        else if c == 2
          args = ",R(#{a+1}),R(#{a+c})"
        else
          args = ",R(#{a+1}),...,R(#{a+c})"
        ["OP_SEND\t#{a}, #{b}, #{c}", "R(#{a}) := call(R(#{a}),Syms(#{b})#{args})"]
      when 0x21
        if c == 0
          args = ""
        else if c == 1
          args = ",R(#{a+1})"
        else if c == 2
          args = ",R(#{a+1}),R(#{a+c})"
        else
          args = ",R(#{a+1}),...,R(#{a+c})"
        ["OP_SENDB\t#{a}, #{b}, #{c}", "R(#{a}) := call(R(#{a}),Syms(#{b})#{args},&R(#{a+c+1}))"]
      when 0x4a
        ["OP_STOP", "stop VM"]
      else
        ["0x#{code.toString(16)}", "Unknown opcode"]


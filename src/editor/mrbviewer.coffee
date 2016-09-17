"use strict"
# Pre dependencies
TextEditor = require("editor/texteditor")
sprintf = require("util/sprintf")
require("util/primitive")

###*
@class
  Viewer for mrb binary
@extends TextEditor
###
module.exports = class MrbViewer extends TextEditor
  TextEditor.register(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @inheritdoc Editor#editable
  @readonly
  ###
  @editable: false

  #--------------------------------------------------------------------------------
  # Private variables
  #

  SUFFIX_RE = /\.mrb$/i

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Editor#supports
  ###
  @supports: (item) ->
    return !!item.path.match(SUFFIX_RE)

  #--------------------------------------------------------------------------------
  # Protected properties
  #

  ###*
  @protected
  @method constructor
    Constructor of MrbViewer class
  @param {jQuery} $
    jQuery object
  @param {Sketch} sketch
    Sketch instance
  @param {SketchItem} item
    Sketch item
  ###
  constructor: ($, sketch, item) ->
    super($, sketch, item, "ace/mode/yaml")
    return

  ###*
  @protected
  @inheritdoc TextEditor#convertForReading
  ###
  convertForReading: (arrayBuf) ->
    return Promise.resolve(=>
    ).then(=>
      r = {}
      m = []
      i = 0
      ctx = {}
      [r.rite_binary_header, i] = @_loadRiteBinaryHeader(ctx, arrayBuf, i)
      if r.rite_binary_header.binary_identify == "RITE" and
         r.rite_binary_header.binary_version == "0003"
        s = 0
        n = null
        while (s == 0) or r[n].section_identify != "END\0"
          try
            n = "section_#{s}"
            [r[n], i] = @_loadRiteSection(ctx, arrayBuf, i)
            s += 1
          catch error
            break
        if arrayBuf.byteLength > i
          m.push("Found #{arrayBuf.byteLength - i} bytes junk after END section")
      else
        m.push("This file is not supported")
      if m.length > 0
        r.messages = m
      return JsYaml.safeDump(r, {styles: {"!!int": "hex"}}) # Last PromiseValue
    ) # return Promise.resolve().then()

  #--------------------------------------------------------------------------------
  # Private methods
  #

  _bin_to_u32_le = (a) ->
    # Little-endian
    (a[3] << 24) | (a[2] << 16) | (a[1] << 8) | a[0]

  _bin_to_u32_be = (a) ->
    # Big-endian
    (a[0] << 24) | (a[1] << 16) | (a[2] << 8) | a[3]

  _bin_to_u16_be = (a) ->
    # Big-endian
    (a[0] << 8) | a[1]

  _stringize = (a) ->
    String.fromCharCode.apply(null, a)

  _loadRiteBinaryHeader: (ctx, arrayBuf, offset) ->
    h = new Uint8Array(arrayBuf, offset, 22)
    [{
      binary_identify: _stringize(h.subarray(0, 4))
      binary_version: _stringize(h.subarray(4, 8))
      binary_crc: _bin_to_u16_be(h.subarray(8, 10))
      binary_size: _bin_to_u32_be(h.subarray(10, 14))
      compiler_name: _stringize(h.subarray(14, 18))
      compiler_version: _stringize(h.subarray(18, 22))
    }, offset + h.byteLength]

  _loadRiteSection: (ctx, arrayBuf, offset) ->
    h = new Uint8Array(arrayBuf, offset, 8)
    r = {
      offset: offset
      section_identify: _stringize(h.subarray(0, 4))
      section_size: _bin_to_u32_be(h.subarray(4, 8))
    }
    h = new Uint8Array(arrayBuf, offset + 8, r.section_size - 8)
    switch r.section_identify
      when "IREP"
        r.rite_version = _stringize(h.subarray(0, 4))
        ctx.last_irep = r
        @_loadIrepRecord(ctx, r, h.subarray(4), offset + 4)
      when "DBG\0"
        r.filenames_len = _bin_to_u16_be(h.subarray(0, 2))
        r.filenames = []
        i = 2
        for n in [0...(r.filenames_len)] by 1
          l = _bin_to_u16_be(h.subarray(i, i + 2))
          i += 2
          r.filenames.push(_stringize(h.subarray(i, i + l)))
          i += l
        r.__irep = ctx.last_irep
        ctx.last_dbg = r
        @_loadDebugRecord(ctx, r, h.subarray(i))
      when "LVAR"
        r.syms_len = _bin_to_u32_be(h.subarray(0, 4))
        r.record = []
        i = 4
        for n in [0...(r.syms_len)] by 1
          l = _bin_to_u16_be(h.subarray(i, i + 2))
          i += 2
          r.record.push(
            {symbol: _stringize(h.subarray(i, i + l))}
          )
          i += l
        while i < r.section_size
          n = _bin_to_u16_be(h.subarray(i, i + 2))
          r.record[n]?.lv = _bin_to_u16_be(h.subarray(i + 2, i + 4)) if n < 0xffff
          i += 4
    offset += r.section_size
    return [r, offset]

  _loadIrepRecord: (ctx, r, h, offset) ->
    r.record_size = _bin_to_u32_be(h.subarray(0, 4))
    r.number_of_locals = _bin_to_u16_be(h.subarray(4, 6))
    r.number_of_regs = _bin_to_u16_be(h.subarray(6, 8))
    r.number_of_child_ireps = _bin_to_u16_be(h.subarray(8, 10))
    n = _bin_to_u32_be(h.subarray(10, 14))
    pad = (4 - (offset + 14) % 4) % 4
    r.iseq = {number_of_opcodes: n, padding_bytes: pad, opcodes: []}
    i = 14 + pad
    for n in [0...(r.iseq.number_of_opcodes)] by 1
      c = _bin_to_u32_be(h.subarray(i, i + 4))
      [c1,c2] = @_decodeRiteInst(c)
      [c0,c1] = c1.split("\t")
      r.iseq.opcodes.push(sprintf("%-11s %-11s # %s", c0, c1 or "", c2))
      i += 4
    n = _bin_to_u32_be(h.subarray(i, i + 4))
    i += 4
    r.pool = {length_of_pool: n, values: []}
    for n in [0...(r.pool.length_of_pool)] by 1
      null  # FIXME
    n = _bin_to_u32_be(h.subarray(i, i + 4))
    i += 4
    r.syms = {number_of_syms: n, symbols: []}
    for n in [0...(r.syms.number_of_syms)] by 1
      len = _bin_to_u16_be(h.subarray(i, i + 2))
      i += 2
      if len == 0xffff
        r.syms.symbols.push(null)
      else
        r.syms.symbols.push(_stringize(h.subarray(i, i + len)))
        i += (len + 1)
    for n in [0...(r.number_of_child_ireps)] by 1
      i += @_loadIrepRecord(ctx, r["child_#{n}"] = {}, h.subarray(i), offset + i)
    return i

  _loadDebugRecord: (ctx, r, h) ->
    r.file_count = _bin_to_u16_be(h.subarray(4, 6))
    r.files = {}
    i = 6
    for n in [0...(r.file_count)] by 1
      m = ctx.last_dbg?.filenames[_bin_to_u16_be(h.subarray(i + 4, i + 6))]
      m or= "file_##{n}"
      f = r.files[m] = {
        start_pos: _bin_to_u32_be(h.subarray(i, i + 4))
      }
      i += 6
      f.line_entry_count = _bin_to_u32_be(h.subarray(i, i + 4))
      t = h[i + 4]
      f.line_type = ["mrb_debug_line_ary", "mrb_debug_line_flat_map"][t] or "unknown"
      i += 5
      if t == 0
        f.lines = []
        for x in [0...(f.line_entry_count)] by 1
          f.lines.push(_bin_to_u16_be(h.subarray(i, i + 2)))
          i += 2
      if t == 1
        f.lines = []
        for x in [0...(f.line_entry_count)] by 1
          f.lines.push({
            start_pos: _bin_to_u32_be(h.subarray(i, i + 4))
            line: _bin_to_u16_be(h.subarray(i + 4, i + 6))
          })
          i += 6
    for n in [0...(r.__irep?.number_of_child_ireps or 0)] by 1
      k = "child_#{n}"
      i += @_loadDebugRecord(ctx, r[k] = {__irep: r.__irep[k]}, h.subarray(i))
    delete r.__irep
    return i

  _decodeRiteInst: (code) ->
    op = (code) & 0x7f
    a = (code >> 23) & 0x1ff
    b = (code >> 14) & 0x1ff
    c = (code >> 7) & 0x7f
    bx = (code >> 7) & 0xffff
    sbx = bx - (0xffff >> 1)
    switch (code & 0x7f)
      when 0x00
        return ["OP_NOP", "no operation"]
      when 0x01
        return ["OP_MOVE\t#{a}, #{b}", "R(#{a}) := R(#{b})"]
      when 0x02
        return ["OP_LOADL\t#{a}, #{bx}", "R(#{a}) := Pool(#{bx})"]
      when 0x03
        return ["OP_LOADI\t#{a}, #{sbx}", "R(#{a}) := #{sbx}"]
      when 0x04
        return ["OP_LOADSYM\t#{a}, #{bx}", "R(#{a}) := Syms(#{bx})"]
      when 0x05
        return ["OP_LOADNIL\t#{a}", "R(#{a}) := nil"]
      when 0x06
        return ["OP_LOADSELF\t#{a}", "R(#{a}) := self"]
      when 0x07
        return ["OP_LOADT\t#{a}", "R(#{a}) := true"]
      when 0x08
        return ["OP_LOADF\t#{a}", "R(#{a}) := false"]
      when 0x09
        return ["OP_GETGLOBAL\t#{a}, #{bx}", "R(#{a}) := getglobal(Syms(#{bx}))"]
      when 0x0a
        return ["OP_SETGLOBAL\t#{a}, #{bx}", "setglobal(Syms(#{bx}),R(#{a}))"]
      when 0x0b
        return ["OP_GETSPECIAL\t#{a}, #{bx}", "R(#{a}) := Special[#{bx}]"]
      when 0x0c
        return ["OP_SETSPECIAL\t#{a}, #{bx}", "Special[#{bx}] := R(#{a})"]
      when 0x0d
        return ["OP_GETIV\t#{a}, #{bx}", "R(#{a}) := ivget(Syms(#{bx}))"]
      when 0x0e
        return ["OP_SETIV\t#{a}, #{bx}", "ivset(Syms(#{bx}),R(#{a}))"]
      when 0x0f
        return ["OP_GETCV\t#{a}, #{bx}", "R(#{a}) := cvget(Syms(#{bx}))"]
      when 0x10
        return ["OP_SETCV\t#{a}, #{bx}", "cvset(Syms(#{bx}),R(#{a}))"]
      when 0x11
        return ["OP_GETCONST\t#{a}, #{bx}", "R(#{a}) := constget(Syms(#{bx}))"]
      when 0x12
        return ["OP_SETCONST\t#{a}, #{bx}", "constset(Syms(#{bx}),R(#{a}))"]
      when 0x13
        return ["OP_GETMCNST\t#{a}, #{bx}", "R(#{a}) := R(#{a+1})::Syms(#{bx})"]
      when 0x14
        return ["OP_SETMCNST\t#{a}, #{bx}", "R(#{a+1})::Syms(#{bx}) := R(#{a})"]
      when 0x15
        return ["OP_GETUPVAR\t#{a}, #{b}, #{c}", "R(#{a}) := uvget(#{b},#{c})"]
      when 0x16
        return ["OP_SETUPVAR\t#{a}, #{b}, #{c}", "uvset(#{b},#{c},R(#{a})"]
      when 0x17
        return ["OP_JMP\t#{sbx}", "pc+=#{sbx}"]
      when 0x18
        return ["OP_JMPIF\t#{a}, #{sbx}", "if R(#{a}) pc+=#{sbx}"]
      when 0x19
        return ["OP_JMPNOT\t#{a}, #{sbx}", "if !R(#{a}) pc+=#{sbx}"]
      when 0x1a
        return ["OP_ONERR\t#{sbx}", "rescue_push(pc+#{sbx})"]
      when 0x1b
        act = if a != 0 then "; R(#{a}) := exception" else ""
        return ["OP_RESCUE\t#{a}", "clear(exc)#{act}"]
      when 0x1c
        return ["OP_POPERR\t#{a}", "#{a}.times{rescue_pop()}"]
      when 0x1d
        return ["OP_RAISE\t#{a}", "raise(R(#{a}))"]
      when 0x1e
        return ["OP_EPUSH\t#{bx}", "ensure_push(SEQ[#{bx}])"]
      when 0x1f
        return ["OP_EPOP\t#{a}", "#{a}.times{ensure_pop().call}"]
      when 0x20
        if c == 0
          args = ""
        else if c == 1
          args = ",R(#{a+1})"
        else if c == 2
          args = ",R(#{a+1}),R(#{a+c})"
        else
          args = ",R(#{a+1}),...,R(#{a+c})"
        return ["OP_SEND\t#{a}, #{b}, #{c}", "R(#{a}) := call(R(#{a}),Syms(#{b})#{args})"]
      when 0x21
        if c == 0
          args = ""
        else if c == 1
          args = ",R(#{a+1})"
        else if c == 2
          args = ",R(#{a+1}),R(#{a+c})"
        else
          args = ",R(#{a+1}),...,R(#{a+c})"
        return ["OP_SENDB\t#{a}, #{b}, #{c}", "R(#{a}) := call(R(#{a}),Syms(#{b})#{args},&R(#{a+c+1}))"]
      # when 0x22 => OP_FSEND
      # when 0x23 => OP_CALL
      # when 0x24 => OP_SUPER
      # when 0x25 => OP_ARGARY
      # when 0x26 => OP_ENTER
      # when 0x27 => OP_KARG
      # when 0x28 => OP_KDICT
      when 0x29
        return ["OP_RETURN\t#{a}, #{b}", "return R(#{a}) [OP_R_#{
          ["NORMAL", "BREAK", "RETURN"][b]
        }]"] if b <= 2
      # when 0x2a => OP_TAILCALL
      # when 0x2b => OP_BLKPUSH
      when 0x2c
        return ["OP_ADD\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})+R(#{a+1})"] if c == 1
      when 0x2d
        return ["OP_ADDI\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})+#{c}"]
      when 0x2e
        return ["OP_SUB\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})-R(#{a+1})"] if c == 1
      when 0x2f
        return ["OP_SUBI\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})-#{c}"]
      when 0x30
        return ["OP_MUL\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})*R(#{a+1})"] if c == 1
      when 0x31
        return ["OP_DIV\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})/R(#{a+1})"] if c == 1
      when 0x32
        return ["OP_EQ\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})==R(#{a+1})"] if c == 1
      when 0x33
        return ["OP_LT\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})<R(#{a+1})"] if c == 1
      when 0x34
        return ["OP_LE\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})<=R(#{a+1})"] if c == 1
      when 0x35
        return ["OP_GT\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})>R(#{a+1})"] if c == 1
      when 0x36
        return ["OP_GE\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{a})>=R(#{a+1})"] if c == 1
      when 0x37
        if c == 0
          args = ""
        else if c == 1
          args = ",R(#{b+1})"
        else
          args = ",...,R(#{b+c})"
        return ["OP_ARRAY\t#{a}, #{b}, #{c}", "R(#{a}) := ary_new(R(#{b})#{args})"]
      when 0x38
        return ["OP_ARYCAT\t#{a}, #{b}", "ary_cat(R(#{a}),R(#{b}))"]
      when 0x39
        return ["OP_ARYPUSH\t#{a}, #{b}", "ary_push(R(#{a}),R(#{b}))"]
      when 0x3a
        return ["OP_AREF\t#{a}, #{b}, #{c}", "R(#{a}) := R(#{b})[#{c}]"]
      when 0x3b
        return ["OP_ASET\t#{a}, #{b}, #{c}", "R(#{b})[#{c}] := R(#{a})"]
      when 0x3c
        if c == 0
          vars = ""
        else if c == 1
          vars = ",R(#{a+1})"
        else
          vars = ",...,R(#{a+c})"
        return ["OP_APOST\t#{a}, #{b}, #{c}", "*R(#{a})#{vars} := R(#{a})"]
      when 0x3d
        return ["OP_STRING\t#{a}, #{bx}", "R(#{a}) := str_dup(Lit(#{bx}))"]
      when 0x3e
        return ["OP_STRCAT\t#{a}, #{b}", "str_cat(R(#{a}),R(#{b}))"]
      when 0x3f
        if c == 0
          args = ""
        else if c == 1
          args = ",R(#{b+1})"
        else
          args = ",...,R(#{b+c})"
        return ["OP_HASH\t#{a}, #{b}, #{c}", "R(#{a}) := hash_new(R(#{b})#{args})"]
      when 0x40
        return ["OP_LAMBDA\t#{a}, #{b}, #{c}", "R(#{a}) := lambda(SEQ[#{b}],#{c})"]
      when 0x41
        return ["OP_RANGE\t#{a}, #{b}, #{c}", "R(#{a}) := range_new(R(#{b}),R(#{b+1}),C)"]
      when 0x42
        return ["OP_OCLASS\t#{a}", "R(#{a}) := ::Object"]
      when 0x43
        return ["OP_CLASS\t#{a}, #{b}", "R(#{a}) := newclass(R(#{a}),Syms(#{b}),R(#{a+1}))"]
      when 0x44
        return ["OP_MODULE\t#{a}, #{b}", "R(#{a}) := newmodule(R(#{a}),Syms(#{b}))"]
      when 0x45
        return ["OP_EXEC\t#{a}, #{bx}", "R(#{a}) := blockexec(R(#{a}),SEQ[#{bx}])"]
      when 0x46
        return ["OP_METHOD\t#{a}, #{b}", "R(#{a}).newmethod(Syms(#{b}),R(#{a+1}))"]
      when 0x47
        return ["OP_SCLASS\t#{a}, #{b}", "R(#{a}) := R(#{b}).singleton_class"]
      when 0x48
        return ["OP_TCLASS\t#{a}", "R(#{a}) := target_class"]
      when 0x49
        return ["OP_DEBUG\t#{a}, #{b}, #{c}", "print R(#{a}),R(#{b}),R(#{c})"]
      when 0x4a
        return ["OP_STOP", "stop VM"]
      when 0x4b
        return ["OP_ERR\t#{bx}", "raise RuntimeError(msg=Lit(#{bx})"]
      # when 0x4c => OP_RSVD1
      # when 0x4d => OP_RSVD2
      # when 0x4e => OP_RSVD3
      # when 0x4f => OP_RSVD4
      # when 0x50 => OP_RSVD5
      else
        return [sprintf("0x%08x", code), "Unknown opcode"]

# Post dependencies
JsYaml = global.Libs.JsYaml

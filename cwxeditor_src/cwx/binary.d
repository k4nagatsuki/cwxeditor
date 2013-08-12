
module cwx.binary;

private import cwx.perf;

private import std.exception : enforce;
private import std.stream : InputStream, OutputStream;
private import std.string : format;
private import std.conv : to;

private string repeat(string s, int count) {
	string buf;
	for (int i = 0; i < count; i++) buf ~= s;
	return buf;
}

/// Byte列の読み書きを行う機能を備えた構造体。
struct ByteIO {
	/// Byte列。
	private ubyte[] _bytes;
	/// バッファを解放する。
	void dispose() { mixin(S_TRACE);
		_bytes[] = 0;
		delete _bytes;
		_bytes = null;
	}
	/// 読込・書込済Byte列。
	@property
	ubyte[] bytes() { mixin(S_TRACE);
		return _pointer == _bytes.length ? _bytes : _bytes[0 .. _pointer];
	}
	private size_t _pointer = 0u;
	/// 読込み・書込みを終えたByte数。
	@property
	size_t pointer() {return _pointer;}
	/// void[]をByte列としてByteIOを生成。
	static ByteIO opCall(void[] _bytes) {
		ByteIO io;
		io._bytes = cast(ubyte[]) _bytes;
		return io;
	}
	/// Byte列を渡してByteIOを生成。
	static ByteIO opCall(ubyte[] _bytes) {
		ByteIO io;
		io._bytes = _bytes;
		return io;
	}
	/// 書込用のByteIOを生成。
	static ByteIO opCall(size_t firstBuffer) {
		ByteIO io;
		io._bytes.length = firstBuffer;
		return io;
	}
	/// ditto
	static ByteIO opCall() {
		return ByteIO(256);
	}
	/// Byte列の終りに達していればtrue。
	@property
	bool eob() {return _pointer >= _bytes.length;}
	/// seekする。
	void seek(int bytes) { mixin(S_TRACE);
		if (bytes < 0) { mixin(S_TRACE);
			enforce(_pointer >= -bytes,
				new Exception(format("read over: 0x%X - %d", _pointer, -bytes), __FILE__, __LINE__));
		} else if (bytes > 0) { mixin(S_TRACE);
			enforce(_pointer + bytes < _bytes.length,
				new Exception(format("read over: 0x%X + %d", _pointer, bytes), __FILE__, __LINE__));
		}
		_pointer += bytes;
	}
	/// Byteを読込む。
	@property
	ubyte readUByte() { mixin(S_TRACE);
		enforce(_pointer < _bytes.length,
			new Exception(format("read over: 0x%X", _pointer), __FILE__, __LINE__));
		return _bytes[_pointer++];
	}
	/// ditto
	@property
	byte readByte() {return cast(byte) readUByte;}
	/// Duck Typingの便宜上用意されたreadUByte()の別名。
	alias readUByte readUByteB;
	/// ditto
	alias readByte readByteB;
	/// ditto
	alias readUByte readUByteL;
	/// ditto
	alias readByte readByteL;
	/// Byteを書込む。
	void write(byte val) {write(cast(ubyte) val);}
	/// ditto
	void write(char val) {write(cast(ubyte) val);}
	/// ditto
	void write(ubyte val) { mixin(S_TRACE);
		if (_pointer >= _bytes.length) _bytes.length = _bytes.length * 2 + 1;
		_bytes[_pointer++] = val;
	}
	/// Duck Typingの便宜上用意されたwrite()の別名。
	void writeB(byte val) {write(val);}
	/// ditto
	void writeB(ubyte val) {write(val);}
	/// ditto
	void writeB(char val) {write(val);}
	/// ditto
	void writeL(byte val) {write(val);}
	/// ditto
	void writeL(ubyte val) {write(val);}
	/// ditto
	void writeL(char val) {write(val);}
	/// Byte列を読込む。
	void read(ubyte[] buf) { mixin(S_TRACE);
		enforce(_pointer + buf.length <= _bytes.length,
			new Exception(format("read over: 0x%X + %d", _pointer, buf.length), __FILE__, __LINE__));
		buf[] = _bytes[_pointer .. _pointer + buf.length];
		_pointer += buf.length;
	}
	/// ditto
	void read(byte[] buf) {read(cast(ubyte[]) buf);}
	/// Byte列を読込む。
	ubyte[] read(size_t len) { mixin(S_TRACE);
		enforce(_pointer + len <= _bytes.length,
			new Exception(format("read over: 0x%X + %d", _pointer, len), __FILE__, __LINE__));
		ubyte[] r = _bytes[_pointer .. _pointer + len];
		_pointer += len;
		return r;
	}
	/// ditto
	void read(void[] buf) {read(cast(ubyte[]) buf);}
	/// Duck Typingの便宜上用意されたread()の別名。
	alias read readL;
	/// ditto
	alias read readB;
	/// Byte列を書込む。
	void write(ubyte[] bytes) { mixin(S_TRACE);
		if (_pointer + bytes.length >= _bytes.length) { mixin(S_TRACE);
			_bytes.length = _bytes.length * 2 + bytes.length;
		}
		_bytes[_pointer .. _pointer + bytes.length] = bytes[];
		_pointer += bytes.length;
	}
	/// ditto
	void write(byte[] bytes) {write(cast(ubyte[]) bytes);}
	/// ditto
	void write(void[] bytes) {write(cast(ubyte[]) bytes);}
	/// Duck Typingの便宜上用意されたwrite()の別名。
	void writeB(byte[] val) {write(val);}
	/// ditto
	void writeB(ubyte[] val) {write(val);}
	/// ditto
	void writeB(void[] val) {write(val);}
	/// ditto
	void writeL(byte[] val) {write(val);}
	/// ditto
	void writeL(ubyte[] val) {write(val);}
	/// ditto
	void writeL(void[] val) {write(val);}
	@property
	private I readBytesB_(I)() { mixin(S_TRACE);
		enforce(_pointer + I.sizeof <= _bytes.length,
			new Exception(format("read over: 0x%X + %d", _pointer, I.sizeof), __FILE__, __LINE__));
		I i = _bytes[_pointer++];
		mixin (ReadBytesB!(I));
		return i;
	}
	@property
	private I readBytesL_(I)() { mixin(S_TRACE);
		enforce(_pointer + I.sizeof <= _bytes.length,
			new Exception(format("read over: 0x%X + %d", _pointer, I.sizeof), __FILE__, __LINE__));
		I i;
		i = _bytes[_pointer++];
		mixin (ReadBytesL!(I));
		return i;
	}
	private void writeBytesB_(I)(I val) { mixin(S_TRACE);
		if (_pointer + I.sizeof >= _bytes.length) { mixin(S_TRACE);
			_bytes.length = _bytes.length * 2 + I.sizeof;
		}
		mixin (WriteBytesB!(I));
	}
	private void writeBytesL_(I)(I val) { mixin(S_TRACE);
		if (_pointer + I.sizeof >= _bytes.length) { mixin(S_TRACE);
			_bytes.length = _bytes.length * 2 + I.sizeof;
		}
		mixin (WriteBytesL!(I));
	}
	version (BigEndian) {
		/// 複数のByteを読み書きする。
		/// 関数名の末尾がBの場合はビッグエンディアン、
		/// Lの場合はリトルエンディアンとして読込む。
		public alias readBytesL_ readBytesB;
		/// ditto
		public alias readBytesB_ readBytesL;
		/// ditto
		public alias writeBytesL_ writeBytesB;
		/// ditto
		public alias writeBytesB_ writeBytesL;
	} else version (LittleEndian) {
		/// 複数のByteを読み書きする。
		/// 関数名の末尾がBの場合はビッグエンディアン、
		/// Lの場合はリトルエンディアンとして処理する。
		public alias readBytesB_ readBytesB;
		/// ditto
		public alias readBytesL_ readBytesL;
		public alias writeBytesB_ writeBytesB;
		/// ditto
		public alias writeBytesL_ writeBytesL;
	} else static assert (0);

	/// 型毎に用意されたreadBytesB()・readBytesL()の別名。
	alias readBytesB!(long) readLongB;
	/// ditto
	alias readBytesB!(ulong) readULongB;
	/// ditto
	alias readBytesB!(int) readIntB;
	/// ditto
	alias readBytesB!(uint) readUIntB;
	/// ditto
	alias readBytesB!(short) readShortB;
	/// ditto
	alias readBytesB!(ushort) readUShortB;
	/// ditto
	alias readBytesL!(long) readLongL;
	/// ditto
	alias readBytesL!(ulong) readULongL;
	/// ditto
	alias readBytesL!(int) readIntL;
	/// ditto
	alias readBytesL!(uint) readUIntL;
	/// ditto
	alias readBytesL!(short) readShortL;
	/// ditto
	alias readBytesL!(ushort) readUShortL;

	/// 型毎に用意されたwriteBytesB()・writeBytesL()の別名。
	void writeB(long val) {writeBytesB(val);}
	/// ditto
	void writeB(ulong val) {writeBytesB(val);}
	/// ditto
	void writeB(int val) {writeBytesB(val);}
	/// ditto
	void writeB(uint val) {writeBytesB(val);}
	/// ditto
	void writeB(short val) {writeBytesB(val);}
	/// ditto
	void writeB(ushort val) {writeBytesB(val);}
	/// ditto
	void writeL(long val) {writeBytesL(val);}
	/// ditto
	void writeL(ulong val) {writeBytesL(val);}
	/// ditto
	void writeL(int val) {writeBytesL(val);}
	/// ditto
	void writeL(uint val) {writeBytesL(val);}
	/// ditto
	void writeL(short val) {writeBytesL(val);}
	/// ditto
	void writeL(ushort val) {writeBytesL(val);}
}

private template ReadBytesB(I, size_t Len = I.sizeof) {
	static if (Len > 1) {
		const string ReadBytesB = "i <<= 8; i |= _bytes[_pointer++];\n" ~ ReadBytesB!(I, Len - 1);
	} else {
		const string ReadBytesB = "";
	}
}
private template ReadBytesL(I, size_t Len = I.sizeof, size_t N = 1) {
	static if (N < Len) {
		const string ReadBytesL = "i |= "
			~ (N >= size_t.sizeof ? "cast(" ~ I.stringof ~ ") " : "")
		~ "_bytes[_pointer++] << 8 * " ~ .to!string(N) ~ ";\n" ~ ReadBytesL!(I, Len, N + 1);
	} else {
		const string ReadBytesL = "";
	}
}
private template WriteBytesB(I, size_t Len = I.sizeof) {
	static if (Len > 0) {
		const string WriteBytesB = "_bytes[_pointer++] = cast(ubyte) ((val & 0xFF"
			~ repeat("0", (Len - 1) * 2) ~ ") >>> 8 * " ~ .to!string(Len - 1) ~ ");\n" ~ WriteBytesB!(I, Len - 1);
	} else {
		const string WriteBytesB = "";
	}
}
private template WriteBytesL(I, size_t Len = I.sizeof, size_t N = 0) {
	static if (N < Len) {
		const string WriteBytesL = "_bytes[_pointer++] = cast(ubyte) ((val & 0xFF"
			~ repeat("0", N * 2) ~ ") >>> 8 * " ~ .to!string(N) ~ ");\n" ~ WriteBytesL!(I, Len, N + 1);
	} else {
		const string WriteBytesL = "";
	}
}

version (BigEndian) {
	/// BigEndianでinpからintの値を読む。
	int readIntB(InputStream inp) { mixin(S_TRACE);
		int i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i |= b << 8;
		inp.read(b); i |= b << 16;
		inp.read(b); i |= b << 24;
		return i;
	}

	/// BigEndianでinpからuintの値を読む。
	uint readUIntB(InputStream inp) { mixin(S_TRACE);
		uint i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i |= b << 8;
		inp.read(b); i |= b << 16;
		inp.read(b); i |= b << 24;
		return i;
	}

	/// LittleEndianでinpからintの値を読む。
	int readIntL(InputStream inp) { mixin(S_TRACE);
		int i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		return i;
	}

	/// LittleEndianでinpからuintの値を読む。
	uint readUIntL(InputStream inp) { mixin(S_TRACE);
		uint i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		return i;
	}

	/// BigEndianでinpからshortの値を読む。
	short readShortB(InputStream inp) { mixin(S_TRACE);
		short s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s |= b << 8;
		return s;
	}

	/// LittleEndianでinpからshortの値を読む。
	short readShortL(InputStream inp) { mixin(S_TRACE);
		short s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s <<= 8; s |= b;
		return s;
	}

	/// BigEndianでinpからushortの値を読む。
	ushort readUShortB(InputStream inp) { mixin(S_TRACE);
		ushort s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s |= b << 8;
		return s;
	}

	/// LittleEndianでinpからushortの値を読む。
	ushort readUShortL(InputStream inp) { mixin(S_TRACE);
		ushort s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s <<= 8; s |= b;
		return s;
	}

	/// BigEndianでosへiの値を書く。
	void writeShortB(OutputStream os, short i) { mixin(S_TRACE);
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
	}

	/// BigEndianでosへiの値を書く。
	void writeUShortB(OutputStream os, ushort i) { mixin(S_TRACE);
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
	}

	/// LittleEndianでosへiの値を書く。
	void writeShortL(OutputStream os, short i) { mixin(S_TRACE);
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}

	/// LittleEndianでosへiの値を書く。
	void writeUShortL(OutputStream os, ushort i) { mixin(S_TRACE);
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}

	/// BigEndianでosへiの値を書く。
	void writeIntB(OutputStream os, int i) { mixin(S_TRACE);
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
	}

	/// BigEndianでosへiの値を書く。
	void writeUIntB(OutputStream os, uint i) { mixin(S_TRACE);
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
	}

	/// LittleEndianでosへiの値を書く。
	void writeIntL(OutputStream os, int i) { mixin(S_TRACE);
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}

	/// LittleEndianでosへiの値を書く。
	void writeUIntL(OutputStream os, uint i) { mixin(S_TRACE);
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}
} else version (LittleEndian) {
	/// BigEndianでinpからintの値を読む。
	int readIntB(InputStream inp) { mixin(S_TRACE);
		int i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		return i;
	}

	/// BigEndianでinpからuintの値を読む。
	uint readUIntB(InputStream inp) { mixin(S_TRACE);
		uint i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		return i;
	}

	/// LittleEndianでinpからintの値を読む。
	int readIntL(InputStream inp) { mixin(S_TRACE);
		int i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i |= b << 8;
		inp.read(b); i |= b << 16;
		inp.read(b); i |= b << 24;
		return i;
	}

	/// LittleEndianでinpからuintの値を読む。
	uint readUIntL(InputStream inp) { mixin(S_TRACE);
		uint i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i |= b << 8;
		inp.read(b); i |= b << 16;
		inp.read(b); i |= b << 24;
		return i;
	}

	/// BigEndianでinpからshortの値を読む。
	short readShortB(InputStream inp) { mixin(S_TRACE);
		short s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s <<= 8; s |= b;
		return s;
	}

	/// LittleEndianでinpからshortの値を読む。
	short readShortL(InputStream inp) { mixin(S_TRACE);
		short s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s |= b << 8;
		return s;
	}

	/// BigEndianでinpからushortの値を読む。
	ushort readUShortB(InputStream inp) { mixin(S_TRACE);
		ushort s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s <<= 8; s |= b;
		return s;
	}

	/// LittleEndianでinpからushortの値を読む。
	ushort readUShortL(InputStream inp) { mixin(S_TRACE);
		ushort s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s |= b << 8;
		return s;
	}

	/// BigEndianでosへiの値を書く。
	void writeShortB(OutputStream os, short i) { mixin(S_TRACE);
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}

	/// BigEndianでosへiの値を書く。
	void writeUShortB(OutputStream os, ushort i) { mixin(S_TRACE);
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}

	/// LittleEndianでosへiの値を書く。
	void writeShortL(OutputStream os, short i) { mixin(S_TRACE);
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
	}

	/// LittleEndianでosへiの値を書く。
	void writeUShortL(OutputStream os, ushort i) { mixin(S_TRACE);
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
	}

	/// BigEndianでosへiの値を書く。
	void writeIntB(OutputStream os, int i) { mixin(S_TRACE);
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}

	/// BigEndianでosへiの値を書く。
	void writeUIntB(OutputStream os, uint i) { mixin(S_TRACE);
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}

	/// LittleEndianでosへiの値を書く。
	void writeIntL(OutputStream os, int i) { mixin(S_TRACE);
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
	}

	/// LittleEndianでosへiの値を書く。
	void writeUIntL(OutputStream os, uint i) { mixin(S_TRACE);
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
	}
} else { mixin(S_TRACE);
	static assert (0);
}


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
	/// ditto
	@property
	void pointer(size_t pos) {
		_pointer = 0;
		seek(pos);
	}
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
	/// 相対位置でseekする。
	/// 絶対位置へseekする場合はpointerへの代入を使う。
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

	/// 可変長整数を読み込む。
	@property
	int readExInt() { return .readExInt(true, &readUByte); }
	/// ditto
	@property
	int readExUInt() { return .readExInt(false, &readUByte); }

	/// 可変長整数を書き込む。
	@property
	void writeExInt(int val) { .writeExInt(val, true, &write); }
	/// ditto
	@property
	void writeExUInt(int val) { .writeExInt(val, false, &write); }
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

/// inpから可変長整数の値を読む。
int readExInt(InputStream inp) { mixin(S_TRACE);
	ubyte b;
	return .readExInt(true, { inp.read(b); return b; });
}
/// ditto
int readExUInt(InputStream inp) { mixin(S_TRACE);
	ubyte b;
	return .readExInt(false, { inp.read(b); return b; });
}

/// 可変長整数としてosへiの値を書く。
void writeExInt(OutputStream os, int i) { mixin(S_TRACE);
	.writeExInt(i, true, &os.write);
}
/// ditto
void writeExUInt(OutputStream os, int i) { mixin(S_TRACE);
	.writeExInt(i, false, &os.write);
}

/// valueを可変長整数としてbytesへ書き込む。
/// 可変長整数は整数値を7ビットずつに区切り、それぞれの頭に
/// 「後続の値があるか(1)無いか(0)」を示す1ビットを加えて1バイトとし、
/// リトルエンディアンで並べたもの。
/// この形式では符号をビット群の先頭に置けないため、7ビットずつに
/// 分割する前に全体を1ビット左へシフトし、右端に符号ビットを置く。
/// 符号無し整数の場合は、シフトと右端に符号を置く手順を省略する。
/// offsetにはbytesのどの位置から書き込みを開始するかを指定し、
/// 実際に読み込まれたバイト数が加算される。
/// See_Also: readExInt()
void writeExInt(int value, ubyte[] bytes, ref size_t offset) { mixin(S_TRACE);
	writeExInt(value, true, (b) { bytes[offset++] = b; });
}
/// ditto
void writeExUInt(int value, ubyte[] bytes, ref size_t offset) { mixin(S_TRACE);
	writeExInt(value, false, (b) { bytes[offset++] = b; });
}
/// ditto
private void writeExInt(int value, bool sign, void delegate(ubyte b) write) { mixin(S_TRACE);
	ubyte b;
	uint value2;
	if (sign) { mixin(S_TRACE);
		if (value < 0) { mixin(S_TRACE);
			value2 = -(value + 1) << 1;
			value2 |= 0x1;
		} else { mixin(S_TRACE);
			value2 = value << 1;
		}
	} else { mixin(S_TRACE);
		value2 = value;
	}
	do { mixin(S_TRACE);
		b = value2 & 0x7F;
		value2 >>= 7;
		if (value2) b |= 0x80;
		write(b);
	} while (value2);
}
///
unittest { mixin(S_TRACE);
	mixin (UTPerf);
	ubyte[] write(bool sign, int value) { mixin(S_TRACE);
		auto bytes = new ubyte[8];
		size_t offset = 0;
		writeExInt(value, sign, (b) { bytes[offset++] = b; });
		return bytes[0..offset];
	}
	assert (write(true, 5430)    == [cast(ubyte)0xEC, 0x54]);
	assert (write(true, 78)      == [cast(ubyte)0x9C, 0x01]);
	assert (write(true, 134)     == [cast(ubyte)0x8C, 0x02]);
	assert (write(true, 1094)    == [cast(ubyte)0x8C, 0x11]);
	assert (write(true, 102)     == [cast(ubyte)0xCC, 0x01]);
	assert (write(true, 124)     == [cast(ubyte)0xF8, 0x01]);
	assert (write(true, 1822798) == [cast(ubyte)0x9C, 0xC1, 0xDE, 0x01]);
	assert (write(true, 510)     == [cast(ubyte)0xFC, 0x07]);
	assert (write(true, 1)       == [cast(ubyte)0x02]);
	assert (write(true, 0)       == [cast(ubyte)0x00]);
	assert (write(true, -1)      == [cast(ubyte)0x01]);
	assert (write(true, -9)      == [cast(ubyte)0x11]);
	assert (write(true, -5000)   == [cast(ubyte)0x8F, 0x4E]);
	assert (write(true, -9999)   == [cast(ubyte)0x9D, 0x9C, 0x01]);
	assert (write(false, 839)    == [cast(ubyte)0xC7, 0x06]);
}

/// bytesから可変長整数を読み込む。
/// offsetにはbytesのどの位置から読み込みを開始するかを指定する。
/// See_Also: writeExInt()
int readExInt(in ubyte[] bytes, ref size_t offset) { mixin(S_TRACE);
	return readExInt(true, () => bytes[offset++]);
}
/// ditto
int readExUInt(in ubyte[] bytes, ref size_t offset) { mixin(S_TRACE);
	return readExInt(false, () => bytes[offset++]);
}
/// ditto
private int readExInt(bool sign, ubyte delegate() read) { mixin(S_TRACE);
	uint r = 0;
	size_t i = 0;
	uint b, b2;
	while (true) { mixin(S_TRACE);
		b = read();
		b2 = b & 0x7F;
		r |= b2 << i;
		if ((b & 0x80) == 0) { mixin(S_TRACE);
			break;
		}
		i += 7;
	}
	if (sign) { mixin(S_TRACE);
		if (r & 0x1) { mixin(S_TRACE);
			return -(r >> 1) - 1;
		} else { mixin(S_TRACE);
			return r >> 1;
		}
	} else { mixin(S_TRACE);
		return r;
	}
}
///
unittest { mixin(S_TRACE);
	mixin (UTPerf);
	size_t offset = 0;
	offset = 0; assert (readExInt([cast(ubyte)0xEC, 0x54], offset) == 5430);
	offset = 0; assert (readExInt([cast(ubyte)0x9C, 0x01], offset) == 78);
	offset = 0; assert (readExInt([cast(ubyte)0x8C, 0x02], offset) == 134);
	offset = 0; assert (readExInt([cast(ubyte)0x8C, 0x11], offset) == 1094);
	offset = 0; assert (readExInt([cast(ubyte)0xCC, 0x01], offset) == 102);
	offset = 0; assert (readExInt([cast(ubyte)0xF8, 0x01], offset) == 124);
	offset = 0; assert (readExInt([cast(ubyte)0x9C, 0xC1, 0xDE, 0x01], offset) == 1822798);
	offset = 0; assert (readExInt([cast(ubyte)0xFC, 0x07], offset) == 510);
	offset = 0; assert (readExInt([cast(ubyte)0x02], offset) == 1);
	offset = 0; assert (readExInt([cast(ubyte)0x00], offset) == 0);
	offset = 0; assert (readExInt([cast(ubyte)0x01], offset) == -1);
	offset = 0; assert (readExInt([cast(ubyte)0x11], offset) == -9);
	offset = 0; assert (readExInt([cast(ubyte)0x8F, 0x4E], offset) == -5000);
	offset = 0; assert (readExInt([cast(ubyte)0x9D, 0x9C, 0x01], offset) == -9999);
	offset = 0; assert (readExUInt([cast(ubyte)0xC7, 0x06], offset) == 839);
}

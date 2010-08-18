
module cwx.binary;

import std.stream;

version (BigEndian) {
	/// BigEndianでinpからintの値を読む。
	int readIntB(InputStream inp) {
		int i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i |= b << 8;
		inp.read(b); i |= b << 16;
		inp.read(b); i |= b << 24;
		return i;
	}

	/// BigEndianでinpからuintの値を読む。
	uint readUIntB(InputStream inp) {
		uint i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i |= b << 8;
		inp.read(b); i |= b << 16;
		inp.read(b); i |= b << 24;
		return i;
	}

	/// LittleEndianでinpからintの値を読む。
	int readIntL(InputStream inp) {
		int i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		return i;
	}

	/// LittleEndianでinpからuintの値を読む。
	uint readUIntL(InputStream inp) {
		uint i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		return i;
	}

	/// BigEndianでinpからushortの値を読む。
	ushort readUShortB(InputStream inp) {
		ushort s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s |= b << 8;
		return s;
	}

	/// LittleEndianでinpからushortの値を読む。
	ushort readUShortL(InputStream inp) {
		ushort s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s <<= 8; s |= b;
		return s;
	}

	/// LittleEndianでosへiの値を書く。
	void writeIntL(OutputStream os, int i) {
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}

	/// LittleEndianでinpからiの値を書く。
	void writeUIntL(OutputStream os, uint i) {
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) (i & 0xFF));
	}
} else version (LittleEndian) {
	/// BigEndianでinpからintの値を読む。
	int readIntB(InputStream inp) {
		int i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		return i;
	}

	/// BigEndianでinpからuintの値を読む。
	uint readUIntB(InputStream inp) {
		uint i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		inp.read(b); i <<= 8; i |= b;
		return i;
	}

	/// LittleEndianでinpからintの値を読む。
	int readIntL(InputStream inp) {
		int i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i |= b << 8;
		inp.read(b); i |= b << 16;
		inp.read(b); i |= b << 24;
		return i;
	}

	/// LittleEndianでinpからuintの値を読む。
	uint readUIntL(InputStream inp) {
		uint i;
		ubyte b;
		inp.read(b); i = b;
		inp.read(b); i |= b << 8;
		inp.read(b); i |= b << 16;
		inp.read(b); i |= b << 24;
		return i;
	}

	/// BigEndianでinpからushortの値を読む。
	ushort readUShortB(InputStream inp) {
		ushort s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s <<= 8; s |= b;
		return s;
	}

	/// LittleEndianでinpからushortの値を読む。
	ushort readUShortL(InputStream inp) {
		ushort s;
		ubyte b;
		inp.read(b); s = b;
		inp.read(b); s |= b << 8;
		return s;
	}

	/// LittleEndianでosへiの値を書く。
	void writeIntL(OutputStream os, int i) {
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
	}

	/// LittleEndianでinpからiの値を書く。
	void writeUIntL(OutputStream os, uint i) {
		os.write(cast(byte) (i & 0xFF));
		os.write(cast(byte) ((i & 0xFF00) >>> 8));
		os.write(cast(byte) ((i & 0xFF0000) >>> 16));
		os.write(cast(byte) ((i & 0xFF000000) >>> 24));
	}
} else {
	static assert (0);
}

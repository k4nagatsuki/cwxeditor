
module cwx.imagesize;

import cwx.perf;
import cwx.binary;

import std.algorithm : min;
import std.file : exists, getSize;
import std.path;
import std.stdio;
import std.string;
import std.traits;

/// fileが画像ファイルであればimageTypeに対応する拡張子を返す。
string getNormalizedImageExt(string file) { mixin(S_TRACE);
	auto f = .rawFile(file, "rb");
	scope (exit) f.close();
	return f.getNormalizedImageExt();
}
/// ditto
string getNormalizedImageExt(RawFile f) { mixin(S_TRACE);
	auto pos = f.tell;
	scope (exit) f.seek(pos);
	f.seek(0);
	auto bytes = new ubyte[.min(25, f.size)];
	f.rawRead(bytes);
	return .imageType(bytes);
}

/// ファイルがimageSize()でサイズを取得できる
/// 画像形式の拡張子を持つならtrueを返す。
@property
bool isImageExt(string path) { mixin(S_TRACE);
	switch (.toLower(.extension(path))) {
	case ".jpeg", ".jpg", ".jpe", ".jfif", ".jfi", ".jif":
	case ".gif":
	case ".tiff", ".tif":
	case ".bmp":
	case ".png":
	case ".ico":
		return true;
	default:
		return false;
	}
}
/// 画像形式の拡張子をimageTypeで取得できるものに変更する。
@property
string normalizedImageExt(string ext) { mixin(S_TRACE);
	switch (ext.toLower()) {
	case ".jpeg", ".jpg", ".jpe", ".jfif", ".jfi", ".jif":
		return ".jpg";
	case ".gif":
		return ".gif";
	case ".tiff", ".tif":
		return ".tiff";
	case ".bmp":
		return ".bmp";
	case ".png":
		return ".png";
	case ".ico":
		return ".ico";
	default:
		return ext;
	}
}

/// バイナリの先頭部から画像タイプを判断して拡張子で返す。
/// 判断できなかった場合は空文字列を返す。
/// JPEG .... ".jpg"
/// GIF .... ".gif"
/// TIFF .... ".tiff"
/// Bitmap .... ".bmp"
/// PNG .... ".png"
string imageType(in ubyte[] b) { mixin(S_TRACE);
	if (22L <= b.length && 'B' == b[0] && 'M' == b[1]) { mixin(S_TRACE);
		// Bitmap
		return ".bmp";
	}
	if (25L <= b.length && 0x89 == b[0] && 'P' == b[1] && 'N' == b[2] && 'G' == b[3]) { mixin(S_TRACE);
		// PNG
		return ".png";
	}
	if (10L <= b.length && 'G' == b[0] && 'I' == b[1] && 'F' == b[2]) { mixin(S_TRACE);
		// GIF
		return ".gif";
	}
	if (6L <= b.length && 0xFF == b[0] && 0xD8 == b[1]) { mixin(S_TRACE);
		// JPEG
		return ".jpg";
	}
	if (10L <= b.length) { mixin(S_TRACE);
		// TIFF
		switch (b[0]) {
		case 'M':
			if ('M' == b[1]) { mixin(S_TRACE);
				if (42 == b[3]) { mixin(S_TRACE);
					return ".tiff";
				}
			}
			break;
		case 'I':
			if ('I' == b[1]) { mixin(S_TRACE);
				if (42 == b[2]) { mixin(S_TRACE);
					return ".tiff";
				}
			}
			break;
		default:
		}
	}
	return "";
}

/// ファイルに含まれる画像データの幅と高さを取得する。
/// 速度を最優先にするため、ファイル形式のチェックは大まかにしか行われない。
/// また、ファイル自体が読込める場合は形式が誤っていても例外を投げない。
/// 不正なファイルのはずなのに戻り値がtrueになることがあり得る。
/// 画像形式はファイルの拡張子で判断する。
/// JPEG .... jpeg, jpg, jpe, jfif, jfi, jif
/// GIF .... gif
/// TIFF .... tiff, tif
/// Bitmap .... bmp
/// PNG .... png
/// Windows Icon .... ico
///
/// Params:
///  pathOrBytes = ファイルパスまたはバイト配列。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
bool imageSize(T)(in T pathOrBytes, out uint x, out uint y) if (isSomeString!T || is(T:ubyte[])) {
	static if (isSomeString!T) {
		if (!.exists(pathOrBytes)) return false;
		string ext = .toLower(.extension(pathOrBytes));
	} else { mixin(S_TRACE);
		string ext = imageType(pathOrBytes);
	}
	switch (ext) {
	case ".jpeg", ".jpg", ".jpe", ".jfif", ".jfi", ".jif":
		return .jpgSize!T(pathOrBytes, x, y);
	case ".gif":
		return .gifSize!T(pathOrBytes, x, y);
	case ".tiff", ".tif":
		return .tifSize!T(pathOrBytes, x, y);
	case ".bmp":
		return .bmpSize!T(pathOrBytes, x, y);
	case ".png":
		return .pngSize!T(pathOrBytes, x, y);
	case ".ico":
		return .icoSize!T(pathOrBytes, x, y);
	default:
		return false;
	}
}

private ulong getSizeT(T)(in T pathOrBytes) if (isSomeString!T || is(T:ubyte[])) {
	static if (isSomeString!T) {
		return getSize(pathOrBytes);
	} else { mixin(S_TRACE);
		return pathOrBytes.length;
	}
}

/// JPEGファイルに含まれる画像データの幅と高さを取得する。
/// 速度を最優先にするため、ファイル形式のチェックは大まかにしか行われない。
/// また、ファイル自体が読込める場合は形式が誤っていても例外を投げない。
/// 不正なファイルのはずなのに戻り値がtrueになることがあり得る。
///
/// Params:
///  file = ファイルパスまたはバイト配列。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
/// Bugs: JFIFにしか対応していない。
bool jpgSize(T)(in T file, out uint x, out uint y) if (isSomeString!T || is(T:ubyte[])) {
	ulong size = getSizeT!T(file);
	if (6L <= size) { mixin(S_TRACE);
		static if (isSomeString!T) {
			auto inp = .rawFile(file, "rb");
			scope (exit) inp.close();
		} else { mixin(S_TRACE);
			auto inp = ByteIO(file);
			scope (exit) inp.dispose();
		}

		ubyte b;
		inp.read(b); if (0xFF != b) return false;
		inp.read(b); if (0xD8 != b) return false;

		do { mixin(S_TRACE);
			inp.read(b); if (0xFF != b) return false;
			inp.read(b);
			if (0xC0 == b || 0xC2 == b) { mixin(S_TRACE);
				inp.readUShortL;
				inp.read(b);

				y = readUShortB(inp);
				x = readUShortB(inp);
				return true;
			} else { mixin(S_TRACE);
				auto s = readUShortB(inp);
				if (s <= 2) return false;
				inp.seekCur(s - 2);
			}
		} while (inp.tell + 2 < size);
	}
	return false;
}

/// TITFファイルに含まれる画像データの幅と高さを取得する。
/// 速度を最優先にするため、ファイル形式のチェックは大まかにしか行われない。
/// また、ファイル自体が読込める場合は形式が誤っていても例外を投げない。
/// 不正なファイルのはずなのに戻り値がtrueになることがあり得る。
///
/// Params:
///  file = ファイルパスまたはバイト配列。
///  x = 幅を返す。
///  y = 高さを返す。
///  n = 何番目の画像のサイズを取得するか指定する。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
/// Bugs: JFIFにしか対応していない。
bool tifSize(T)(in T file, out uint x, out uint y, uint n = 0) if (isSomeString!T || is(T:ubyte[])) {
	ulong size = getSizeT!T(file);
	if (10L <= size) { mixin(S_TRACE);
		static if (isSomeString!T) {
			auto inp = .rawFile(file, "rb");
			scope (exit) inp.close();
		} else { mixin(S_TRACE);
			auto inp = ByteIO(file);
			scope (exit) inp.dispose();
		}

		bool littleEndian = true;
		ubyte b;
		inp.read(b);
		switch (b) {
		case 'M':
			inp.read(b); if ('M' != b) return false;
			littleEndian = false;
			break;
		case 'I':
			inp.read(b); if ('I' != b) return false;
			break;
		default:
			return false;
		}
		inp.readUShortL;

		uint i = littleEndian ? readUIntL(inp) : readUIntB(inp);
		if (i + 2 + 24 > size) return false;
		inp.seekSet(i);

		uint nn = 0;
		ushort count;
		while (true) { mixin(S_TRACE);
			count = littleEndian ? readUShortL(inp) : readUShortB(inp);
			i = (i + 2) + (12 * count);
			if (i + 4 > size) return false;
			if (nn == n) break;
			inp.seekSet(i);
			i = littleEndian ? readUIntL(inp) : readUIntB(inp);
			if (!i) return false;
			if (i + 2 > size) return false;
			inp.seekSet(i);
			nn++;
		}
		bool w = false;
		bool h = false;
		for (ushort c = 0; c < count; c++) { mixin(S_TRACE);
			auto s = littleEndian ? readUShortL(inp) : readUShortB(inp);
			switch (s) {
			case 0x0100:
				inp.readUShortL;
				inp.readUIntL;
				x = littleEndian ? readUIntL(inp) : readUIntB(inp);
				w = true;
				if (h) return true;
				break;
			case 0x0101:
				inp.readUShortL;
				inp.readUIntL;
				y = littleEndian ? readUIntL(inp) : readUIntB(inp);
				h = true;
				if (w) return true;
				break;
			default:
				inp.seekCur(10);
				break;
			}
		}
	}
	return false;
}

/// GIFファイルに含まれる画像データの幅と高さを取得する。
/// 結果は論理ディスプレイのサイズになる。
/// 速度を最優先にするため、ファイル形式のチェックは大まかにしか行われない。
/// また、ファイル自体が読込める場合は形式が誤っていても例外を投げない。
/// 不正なファイルのはずなのに戻り値がtrueになることがあり得る。
///
/// Params:
///  file = ファイルパスまたはバイト配列。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
bool gifSize(T)(in T file, out uint x, out uint y) if (isSomeString!T || is(T:ubyte[])) {
	if (10L <= getSizeT!T(file)) { mixin(S_TRACE);
		static if (isSomeString!T) {
			auto inp = .rawFile(file, "rb");
			scope (exit) inp.close();
		} else { mixin(S_TRACE);
			auto inp = ByteIO(file);
			scope (exit) inp.dispose();
		}

		ubyte b;
		inp.read(b); if ('G' != b) return false;
		inp.read(b); if ('I' != b) return false;
		inp.read(b); if ('F' != b) return false;
		inp.read(b);
		inp.read(b);
		inp.read(b);

		x = readUShortL(inp);
		y = readUShortL(inp);
		return true;
	}
	return false;
}

/// Bitmapファイルに含まれる画像データの幅と高さを取得する。
/// 速度を最優先にするため、ファイル形式のチェックは大まかにしか行われない。
/// また、ファイル自体が読込める場合は形式が誤っていても例外を投げない。
/// 不正なファイルのはずなのに戻り値がtrueになることがあり得る。
///
/// Params:
///  file = ファイルパスまたはバイト配列。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
bool bmpSize(T)(in T file, out uint x, out uint y) if (isSomeString!T || is(T:ubyte[])) {
	ulong size = getSizeT!T(file);
	if (22L <= size) { mixin(S_TRACE);
		static if (isSomeString!T) {
			auto inp = .rawFile(file, "rb");
			scope (exit) inp.close();
		} else { mixin(S_TRACE);
			auto inp = ByteIO(file);
			scope (exit) inp.dispose();
		}

		ubyte b;
		inp.read(b); if ('B' != b) return false;
		inp.read(b); if ('M' != b) return false;
		inp.readUIntL;
		inp.readUShortL;
		inp.readUShortL;
		inp.readUIntL;

		auto i = readUIntL(inp);
		if (i == 12) { mixin(S_TRACE);
			x = readUShortL(inp);
			y = readUShortL(inp);
		} else if (i > 12) { mixin(S_TRACE);
			if (26L > size) return false;
			x = readUIntL(inp);
			y = readUIntL(inp);
		} else { mixin(S_TRACE);
			return false;
		}
		return true;
	}
	return false;
}

/// PNGファイルに含まれる画像データの幅と高さを取得する。
/// 速度を最優先にするため、ファイル形式のチェックは大まかにしか行われない。
/// また、ファイル自体が読込める場合は形式が誤っていても例外を投げない。
/// 不正なファイルのはずなのに戻り値がtrueになることがあり得る。
///
/// Params:
///  file = ファイルパスまたはバイト配列。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
bool pngSize(T)(in T file, out uint x, out uint y) if (isSomeString!T || is(T:ubyte[])) {
	if (24L <= getSizeT!T(file)) { mixin(S_TRACE);
		static if (isSomeString!T) {
			auto inp = .rawFile(file, "rb");
			scope (exit) inp.close();
		} else { mixin(S_TRACE);
			auto inp = ByteIO(file);
			scope (exit) inp.dispose();
		}

		ubyte b;
		inp.read(b); if (0x89 != b) return false;
		inp.read(b); if ('P' != b) return false;
		inp.read(b); if ('N' != b) return false;
		inp.read(b); if ('G' != b) return false;
		inp.read(b); if (0x0D != b) return false;
		inp.read(b); if (0x0A != b) return false;
		inp.read(b); if (0x1A != b) return false;
		inp.read(b); if (0x0A != b) return false;

		if (13 != readUIntB(inp)) return false;
		inp.read(b); if ('I' != b) return false;
		inp.read(b); if ('H' != b) return false;
		inp.read(b); if ('D' != b) return false;
		inp.read(b); if ('R' != b) return false;

		x = readUIntB(inp);
		y = readUIntB(inp);

		return true;
	}
	return false;
}

/// Windows Iconファイルに含まれる画像データの幅と高さを取得する。
/// 速度を最優先にするため、ファイル形式のチェックは大まかにしか行われない。
/// また、ファイル自体が読込める場合は形式が誤っていても例外を投げない。
/// 不正なファイルのはずなのに戻り値がtrueになることがあり得る。
///
/// Params:
///  file = ファイルパスまたはバイト配列。
///  x = 幅を返す。
///  y = 高さを返す。
///  n = 何番目の画像のサイズを取得するか指定する。
/// Returns: 形式が正しくない場合はfalseを返す。
///
/// Throws:
///  FileException = ファイル読込失敗時。
bool icoSize(T)(in T file, out uint x, out uint y, uint n = 0) if (isSomeString!T || is(T:ubyte[])) {
	ulong size = getSizeT!T(file);
	if (8UL <= size) { mixin(S_TRACE);
		static if (isSomeString!T) {
			auto inp = .rawFile(file, "rb");
			scope (exit) inp.close();
		} else { mixin(S_TRACE);
			auto inp = ByteIO(file);
			scope (exit) inp.dispose();
		}

		if (0x00 != readUShortL(inp)) return false;
		if (0x01 != readUShortL(inp)) return false;
		ushort s = readUShortL(inp);
		if (n >= s) return false;
		if (n > 0) { mixin(S_TRACE);
			long pos = 6L + (n * 16L);
			if (pos + 2 >= size) return false;
			inp.seekSet(pos);
		}
		ubyte b;
		inp.read(b); x = b;
		inp.read(b); y = b;
		return true;
	}
	return false;
}

/// 一部バージョンのCardWirthNextが生成するBitmap(16 bit)は
/// bfOffBitsが壊れているので予め訂正する。
/// FIXME: 末尾に余計なデータがついている画像は却って
///        上手くいかない可能性があるが、非常にレアな
///        ケースなのでまず問題にはならないと思われる。
void fixCWNext16BitBitmap(ref byte[] bytes) { mixin(S_TRACE);
	if (bytes.length  < 14 + 40) return;
	auto f = ByteIO(bytes);
	if ('B' != f.readByteL()) return;
	if ('M' != f.readByteL()) return;
	auto bfSize = f.readUIntL();
	auto bfReserved1 = f.readUShortL();
	auto bfReserved2 = f.readUShortL();
	auto bfOffBits = f.readUIntL();
	if (bfOffBits == 0) return;
	auto biSize = f.readUIntL();
	if (biSize != 40) return;
	auto biWidth = f.readUIntL();
	auto biHeight = f.readIntL();
	auto biPlanes = f.readUShortL();
	auto biBitCount = f.readUShortL();
	auto biCompression = f.readUIntL();
	auto biSizeImage = f.readUIntL();
	auto biXPixPerMeter = f.readIntL();
	auto biYPixPerMeter = f.readIntL();
	auto biClrUsed = f.readUIntL();
	auto biClrImporant = f.readUIntL();
	auto lineSize = ((biWidth * biBitCount + 31) / 32) * 4;
	auto height = biHeight < 0 ? -biHeight : biHeight;
	if (bytes.length - bfOffBits != lineSize * height) {
		// bfOffBitsをヘッダ直後に修正
		bfOffBits = 14 + 40;
		if (biCompression == 3) {
			// ビットフィールド情報がある場合
			bfOffBits += 4 * 3;
		}
		if (biBitCount == 1 || biBitCount == 4 || biBitCount == 8) {
			if (biClrUsed == 0) biClrUsed = biBitCount * biBitCount;
		}
		bfOffBits += biClrUsed * 4;
		f.pointer = 10;
		f.writeL(cast(uint)bfOffBits);
	}
}

/// 一部バージョンのCardWirthNextが生成するBitmap(32 bit)に
/// 本来存在できないはずのパレットデータが残留している事があるので訂正する。
void fixCWNext32BitBitmap(ref byte[] bytes) { mixin(S_TRACE);
	if (bytes.length  < 14 + 40) return;
	auto f = ByteIO(bytes);
	if ('B' != f.readByteL()) return;
	if ('M' != f.readByteL()) return;
	auto bfSize = f.readUIntL();
	auto bfReserved1 = f.readUShortL();
	auto bfReserved2 = f.readUShortL();
	auto bfOffBits = f.readUIntL();
	if (bfOffBits == 0) return;
	auto biSize = f.readUIntL();
	if (biSize != 40) return;
	auto biWidth = f.readUIntL();
	auto biHeight = f.readIntL();
	auto biPlanes = f.readUShortL();
	auto biBitCount = f.readUShortL();
	if (biBitCount != 32 && biBitCount != 24) return;
	auto biCompression = f.readUIntL();
	auto biSizeImage = f.readUIntL();
	auto biXPixPerMeter = f.readIntL();
	auto biYPixPerMeter = f.readIntL();
	auto biClrUsed = f.readUIntL();
	if (0 < biClrUsed) { mixin(S_TRACE);
		f.seekCur(-4);
		f.writeUIntL(0); // 色数を0に訂正
		// 余計なパレットデータを除去
		bytes = bytes[0 .. 14 + biSize] ~ bytes[14 + biSize + biClrUsed * 4 .. $];
	}
}

/// ビットマップイメージのデータbytesからビットフィールド情報を取得する。
/// ビットフィールド情報が無い場合はfalseを返す。
bool getBitField(in byte[] bytes, out uint r, out uint g, out uint b) { mixin(S_TRACE);
	if (bytes.length  < 14 + 40) return false;
	auto f = ByteIO(bytes);
	if ('B' != f.readByteL()) return false;
	if ('M' != f.readByteL()) return false;
	auto bfSize = f.readUIntL();
	auto bfReserved1 = f.readUShortL();
	auto bfReserved2 = f.readUShortL();
	auto bfOffBits = f.readUIntL();
	if (bfOffBits == 0) return false;
	auto biSize = f.readUIntL();
	if (biSize != 40) return false;
	auto biWidth = f.readUIntL();
	auto biHeight = f.readIntL();
	auto biPlanes = f.readUShortL();
	auto biBitCount = f.readUShortL();
	auto biCompression = f.readUIntL();
	auto biSizeImage = f.readUIntL();
	auto biXPixPerMeter = f.readIntL();
	auto biYPixPerMeter = f.readIntL();
	auto biClrUsed = f.readUIntL();
	auto biClrImporant = f.readUIntL();
	if (biCompression == 3) { mixin(S_TRACE);
		r = f.readUIntL();
		g = f.readUIntL();
		b = f.readUIntL();
		return true;
	}
	return false;
}

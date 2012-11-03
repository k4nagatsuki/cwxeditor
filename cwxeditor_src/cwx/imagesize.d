
module cwx.imagesize;

import cwx.binary;

import std.file;
import std.path;
import std.stream;
import std.string;
import std.traits;

/// ファイルがimageSize()でサイズを取得できる
/// 画像形式の拡張子を持つならtrueを返す。
bool isImageExt(string path) {
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

/// バイナリの先頭部から画像タイプを判断して拡張子で返す。
/// 判断できなかった場合は空文字列を返す。
/// JPEG .... ".jpg"
/// GIF .... ".gif"
/// TIFF .... ".tiff"
/// Bitmap .... ".bmp"
/// PNG .... ".png"
string imageType(in ubyte[] b) {
	if (22L <= b.length && 'B' == b[0] && 'M' == b[1]) {
		// Bitmap
		return ".bmp";
	}
	if (25L <= b.length && 0x89 == b[0] && 'P' == b[1] && 'N' == b[2] && 'G' == b[3]) {
		// PNG
		return ".png";
	}
	if (10L <= b.length && 'G' == b[0] && 'I' == b[1] && 'F' == b[2]) {
		// GIF
		return ".gif";
	}
	if (6L <= b.length && 0xFF == b[0] && 0xD8 == b[1]) {
		// JPEG
		return ".jpg";
	}
	if (10L <= b.length) {
		// TIFF
		switch (b[0]) {
		case 'M':
			if ('M' == b[1]) {
				if (42 == b[3]) {
					return ".tiff";
				}
			}
			break;
		case 'I':
			if ('I' == b[1]) {
				if (42 == b[2]) {
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
	} else {
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
	} else {
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
	if (6L <= size) {
		static if (isSomeString!T) {
			auto inp = new File(file);
		} else {
			auto inp = new TArrayStream!(const ubyte[])(file);
		}
		scope (exit) inp.close();

		ubyte b;
		inp.read(b); if (0xFF != b) return false;
		inp.read(b); if (0xD8 != b) return false;

		ushort s;
		do {
			inp.read(b); if (0xFF != b) return false;
			inp.read(b);
			if (0xC0 == b || 0xC2 == b) {
				inp.read(s);
				inp.read(b);

				y = readUShortB(inp);
				x = readUShortB(inp);
				return true;
			} else {
				s = readUShortB(inp);
				if (s <= 2) return false;
				inp.seekCur(s - 2);
			}
		} while (inp.position + 2 < size);
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
	if (10L <= size) {
		static if (isSomeString!T) {
			auto inp = new File(file);
		} else {
			auto inp = new TArrayStream!(const ubyte[])(file);
		}
		scope (exit) inp.close();

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
		ushort s;
		inp.read(s);

		uint i = littleEndian ? readUIntL(inp) : readUIntB(inp);
		if (i + 2 + 24 > size) return false;
		inp.seekSet(i);

		uint nn = 0;
		ushort count;
		while (true) {
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
		for (ushort c = 0; c < count; c++) {
			s = littleEndian ? readUShortL(inp) : readUShortB(inp);
			switch (s) {
			case 0x0100:
				inp.read(s);
				inp.read(i);
				x = littleEndian ? readUIntL(inp) : readUIntB(inp);
				w = true;
				if (h) return true;
				break;
			case 0x0101:
				inp.read(s);
				inp.read(i);
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
	if (10L <= getSizeT!T(file)) {
		static if (isSomeString!T) {
			auto inp = new File(file);
		} else {
			auto inp = new TArrayStream!(const ubyte[])(file);
		}
		scope (exit) inp.close();

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
	if (22L <= size) {
		static if (isSomeString!T) {
			auto inp = new File(file);
		} else {
			auto inp = new TArrayStream!(const ubyte[])(file);
		}
		scope (exit) inp.close();

		uint i;
		ushort s;
		ubyte b;
		inp.read(b); if ('B' != b) return false;
		inp.read(b); if ('M' != b) return false;
		inp.read(i);
		inp.read(s);
		inp.read(s);
		inp.read(i);

		i = readUIntL(inp);
		if (i == 12) {
			x = readUShortL(inp);
			y = readUShortL(inp);
		} else if (i > 12) {
			if (24L > size) return false;
			x = readUIntL(inp);
			y = readUIntL(inp);
		} else {
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
	if (25L <= getSizeT!T(file)) {
		static if (isSomeString!T) {
			auto inp = new File(file);
		} else {
			auto inp = new TArrayStream!(const ubyte[])(file);
		}
		scope (exit) inp.close();

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
	if (8UL <= size) {
		static if (isSomeString!T) {
			auto inp = new File(file);
		} else {
			auto inp = new TArrayStream!(const ubyte[])(file);
		}
		scope (exit) inp.close();

		if (0x00 != readUShortL(inp)) return false;
		if (0x01 != readUShortL(inp)) return false;
		ushort s = readUShortL(inp);
		if (n >= s) return false;
		if (n > 0) {
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

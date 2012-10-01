
module cwx.imagesize;

import cwx.binary;

import std.file;
import std.path;
import std.stream;
import std.string;

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
///  path = ファイルパス。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
bool imageSize(string path, out uint x, out uint y) {
	if (!.exists(path)) return false;
	switch (.toLower(.extension(path))) {
	case ".jpeg", ".jpg", ".jpe", ".jfif", ".jfi", ".jif":
		return .jpgSize(path, x, y);
	case ".gif":
		return .gifSize(path, x, y);
	case ".tiff", ".tif":
		return .tifSize(path, x, y);
	case ".bmp":
		return .bmpSize(path, x, y);
	case ".png":
		return .pngSize(path, x, y);
	case ".ico":
		return .icoSize(path, x, y);
	default:
		return false;
	}
}

/// JPEGファイルに含まれる画像データの幅と高さを取得する。
/// 速度を最優先にするため、ファイル形式のチェックは大まかにしか行われない。
/// また、ファイル自体が読込める場合は形式が誤っていても例外を投げない。
/// 不正なファイルのはずなのに戻り値がtrueになることがあり得る。
/// 
/// Params:
///  file = ファイルパス。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
/// Bugs: JFIFにしか対応していない。
bool jpgSize(string file, out uint x, out uint y) {
	ulong size = getSize(file);
	if (6L <= size) {
		auto inp = new File(file);
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
///  file = ファイルパス。
///  x = 幅を返す。
///  y = 高さを返す。
///  n = 何番目の画像のサイズを取得するか指定する。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
/// Bugs: JFIFにしか対応していない。
bool tifSize(string file, out uint x, out uint y, uint n = 0) {
	ulong size = getSize(file);
	if (10L <= size) {
		auto inp = new File(file);
		scope (exit) inp.close();

		ubyte b;
		inp.read(b);
		switch (b) {
		case 'M':
			inp.read(b); if ('M' != b) return false;
			break;
		case 'I':
			inp.read(b); if ('I' != b) return false;
			break;
		default:
			return false;
		}
		ushort s;
		inp.read(s);

		uint i = readUIntL(inp);
		if (i + 2 + 24 > size) return false;
		inp.seekSet(i);

		uint nn = 0;
		ushort count;
		while (true) {
			count = readUShortL(inp);
			i = (i + 2) + (12 * count);
			if (i + 4 > size) return false;
			if (nn == n) break;
			inp.seekSet(i);
			i = readUIntL(inp);
			if (!i) return false;
			if (i + 2 > size) return false;
			inp.seekSet(i);
			nn++;
		}
		bool w = false;
		bool h = false;
		for (ushort c = 0; c < count; c++) {
			s = readUShortL(inp);
			switch (s) {
			case 0x0100:
				inp.read(s);
				inp.read(i);
				x = readUIntL(inp);
				w = true;
				if (h) return true;
				break;
			case 0x0101:
				inp.read(s);
				inp.read(i);
				y = readUIntL(inp);
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
///  file = ファイルパス。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
bool gifSize(string file, out uint x, out uint y) {
	if (10L <= getSize(file)) {
		auto inp = new File(file);
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
///  file = ファイルパス。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
bool bmpSize(string file, out uint x, out uint y) {
	ulong size = getSize(file);
	if (22L <= size) {
		auto inp = new File(file);
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
///  file = ファイルパス。
///  x = 幅を返す。
///  y = 高さを返す。
/// Returns: 形式が正しくない場合はfalseを返す。
/// Throws:
///  FileException = ファイル読込失敗時。
bool pngSize(string file, out uint x, out uint y) {
	if (25L <= getSize(file)) {
		auto inp = new File(file);
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
///  file = ファイルパス。
///  x = 幅を返す。
///  y = 高さを返す。
///  n = 何番目の画像のサイズを取得するか指定する。
/// Returns: 形式が正しくない場合はfalseを返す。
/// 
/// Throws:
///  FileException = ファイル読込失敗時。
bool icoSize(string file, out uint x, out uint y, uint n = 0) {
	ulong size = getSize(file);
	if (8UL <= size) {
		auto inp = new File(file);
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

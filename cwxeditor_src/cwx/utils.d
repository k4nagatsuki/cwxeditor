
module cwx.utils;

public import cwx.perf;

import cwx.sjis;

import std.algorithm;
import std.array;
import std.conv;
import std.uni;
import std.metastrings;
import std.string;
import std.format;
import std.file;
import std.path;
import std.uni;
import std.utf;
import std.base64;
import std.stdio;
import std.ascii;
import std.cstream;
import std.traits;
import std.datetime;
import std.regex;
import std.array;
import std.exception;
import std.traits;
import std.stdint;
import std.stream;
import std.md5;

debug {
	version (Console) {
		private immutable DR = "Debug / Console";
	} else {
		private immutable DR = "Debug";
	}
} else {
	@property
	private immutable DR = "Release";
}
shared immutable string APP_BUILD = "Build: "
		~ __DATE__[7 .. $]
		~ "-" ~ [
			"Jan":"01",
			"Feb":"02",
			"Mar":"03",
			"Apr":"04",
			"May":"05",
			"Jun":"06",
			"Jul":"07",
			"Aug":"08",
			"Sep":"09",
			"Oct":"10",
			"Nov":"11",
			"Dec":"12"
		][__DATE__[0 .. 3]]
		~ "-" ~ (__DATE__[4 .. 5] == " " ? "0" : __DATE__[4 .. 5]) ~ __DATE__[5 .. 6]
		~ " " ~ __TIME__ ~ " "
		~ DR ~ .newline
		~ "Compiled by " ~ __VENDOR__ ~ " " ~ .text(__VERSION__);

private version (Windows) {
	import std.windows.charset;
	import std.c.stdio;
	extern (Windows) {
		import std.c.windows.windows;
		struct STARTUPINFO {
			DWORD cb;
			LPTSTR lpReserved;
			LPTSTR lpDesktop;
			LPTSTR lpTitle;
			DWORD dwX;
			DWORD dwY;
			DWORD dwXSize;
			DWORD dwYSize;
			DWORD dwXCountChars;
			DWORD dwYCountChars;
			DWORD dwFillAttribute;
			DWORD dwFlags;
			USHORT wShowWindow;
			USHORT cbReserved2;
			LPBYTE lpReserved2;
			HANDLE hStdInput;
			HANDLE hStdOutput;
			HANDLE hStdError;
		}
		struct PROCESS_INFORMATION {
			HANDLE hProcess;
			HANDLE hThread;
			DWORD dwProcessId;
			DWORD dwThreadId;
		}
		BOOL SetFileAttributesW(LPCWSTR, DWORD);
		BOOL CreateProcessW(LPCWSTR, LPWSTR, SECURITY_ATTRIBUTES*, SECURITY_ATTRIBUTES*,
			BOOL, DWORD, LPVOID, LPCWSTR, STARTUPINFO*, PROCESS_INFORMATION*);
		alias HRESULT function(HWND, INT, HANDLE, DWORD, LPWSTR) SHGetFolderPathW;
		const CSIDL_APPDATA = 0x1A;
		const SHGFP_TYPE_CURRENT = 0;
	}
} else {
	import core.sys.posix.unistd;
	import core.sys.posix.pwd;
	import std.c.string;
}

shared string LATEST_VERSION = "";

shared string debugLog = "cwxeditor_error.log";
private __gshared BufferedFile debugLogFile = null;

/// FIXME: 2.059以降altsep不在
version (Windows) {
	immutable altDirSeparator = "/";
} else version (Posix) {
	immutable altDirSeparator = " ";
} else static assert (0);

immutable curdir = ".";
immutable pardir = "..";

/// デバグログを生成する。
string debugString(T)(ref T v) {
	static if (is(T : Throwable)) {
		char[] trace;
		if (v.info) {
			foreach (file; v.info) {
				if (trace.length) {
					trace ~= " - ".dup;
				}
				try {
					for (size_t i = 0; i < file.length; i++) {
						char c = file[i];
						.validate([c]);
						trace ~= c;
					}
				} catch (Exception e) {
					/// infoには妥当でない文字列が含まれている
					/// 可能性があるので、単に無視する
				}
			}
		}
		return .format("[%s] %s, %d: ", v.msg, v.file, v.line) ~ trace.idup;
	} else {
		return .format("%s", v);
	}
}
/// ditto
string createDebugln(bool BuildInfo = true, string F = __FILE__, size_t L = __LINE__, T ...)(T vals) {
	char[] buf = format("%s:%d ", F, L).dup;
	foreach (v; vals) {
		static if (is(typeof(v) : Throwable)) {
			buf ~= debugString(v);
		} else static if (is(typeof(v) : string)) {
			buf ~= v;
		} else {
			buf ~= debugString(v);
		}
	}
	auto d = Clock.currTime();
	int year = d.year;
	int month = d.month;
	int day = d.day;
	int hour = d.hour;
	int min = d.minute;
	int second = d.second;
	static if (BuildInfo) {
		buf = format("%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, min, second) ~ " [" ~ .splitLines!string(APP_BUILD)[0] ~ "]\t" ~ buf;
	} else {
		buf = format("%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, min, second) ~ " " ~ buf;
	}
	return assumeUnique(buf);
}

/// デバグログに文字列を出力する。
shared void fdebugln(string F = __FILE__, size_t L = __LINE__, T ...)(T vals) {
	try {
		synchronized {
			string log = createDebugln!(true, F, L)(vals);
			version (Console) {
				version (Windows) {
					printf("%s\n\0".ptr, toMBSz(log));
					dout.flush();
				} else {
					writeln(log);
				}
			}
			if (!debugLogFile) {
				debugLogFile = new typeof(debugLogFile)(debugLog, FileMode.Append);
			}
			debugLogFile.writeLine(log);
			debugLogFile.flush();
		}
	} catch (Throwable e) {
		std.stdio.writeln(__FILE__, " ", __LINE__, " ", e.msg);
	}
}
shared static ~this () {
	version (Console) {
		debug std.stdio.writeln("Close Debug log file Start");
	}
	synchronized {
		if (debugLogFile) debugLogFile.close();
	}
	version (Console) {
		debug std.stdio.writeln("Close Debug log file Exit");
	}
}
/// debugコンパイルされている際は デバグログに文字列を出力すると
/// 共にfdebugln()を呼出し、ファイル出力する。
void debugln(string F = __FILE__, size_t L = __LINE__, T ...)(T vals) {
	debug {
		fdebugln!(F, L, T)(vals);
	}
}

/// コンソール上にデバグログを出力する。
void cdebugln(string F = __FILE__, size_t L = __LINE__, T ...)(T vals) {
	version (Console) {
		debug {
			synchronized {
				string log = createDebugln!(false, F, L)(vals);
				version (Windows) {
					printf("%s\n\0".ptr, toMBSz(log));
					dout.flush();
				} else {
					writeln(log);
				}
			}
		}
	}
}

/// コンソール上に文字列を出力する。
void cwriteln(string s) {
	version (Console) {
		synchronized {
			version (Windows) {
				printf("%s\n\0".ptr, toMBSz(s));
				dout.flush();
			} else {
				writeln(s);
			}
		}
	}
}

version (Windows) {
	import core.sys.windows.windows;

	/// 共有ライブラリを読み込む。
	void* dlopen(string lib) {
		return LoadLibraryW(.toUTFz!(wchar*)(lib));
	}
	/// 共有ライブラリからシンボルを取得。
	void* dlsym(void* lib, string sym) {
		if (!lib) return null;
		return GetProcAddress(lib, .toStringz(sym));
	}
	/// 共有ライブラリを解放する。
	void dlclose(ref void* lib) {
		if (!lib) return;
		FreeLibrary(lib);
		lib = null;
	}
} else version (Posix) {
	import core.sys.posix.dlfcn;

	/// 共有ライブラリを読み込む。
	void* dlopen(string lib) {
		return core.sys.posix.dlfcn.dlopen(.toStringz(lib), RTLD_NOW);
	}
	/// 共有ライブラリからシンボルを取得。
	void* dlsym(void* lib, string sym) {
		if (!lib) return null;
		return core.sys.posix.dlfcn.dlsym(lib, .toStringz(sym));
	}
	/// 共有ライブラリを解放する。
	void dlclose(ref void* lib) {
		if (!lib) return;
		core.sys.posix.dlfcn.dlclose(lib);
		lib = null;
	}
} else static assert (0);

/// アプリケーションデータを格納する環境標準のディレクトリを返す。
string appDataDir(string appPath) {
	version (Windows) {
		auto shl = dlopen("shell32.dll");
		if (!shl) {
			return appPath.dirName();
		}
		scope (exit) dlclose(shl);
		auto getFolderPath = cast(SHGetFolderPathW) dlsym(shl, "SHGetFolderPathW");
		if (!getFolderPath) {
			return appPath.dirName();
		}
		wchar[MAX_PATH] appDataBuf;
		auto gfr = getFolderPath(null, CSIDL_APPDATA, null, SHGFP_TYPE_CURRENT, appDataBuf.ptr);
		if (0 != gfr) {
			return appPath.dirName();
		}
		auto p = to!string(appDataBuf[0 .. appDataBuf.indexOf('\0')]);
		return assumeUnique(p);
	} else {
		return to!string(getpwuid(getuid()).pw_dir);
	}
}

static const B_IMG = "binaryimage://";
bool isBinImg(string path) {
	return path.length >= B_IMG.length && path[0u .. B_IMG.length] == B_IMG;
}
ubyte[] strToBImg(string bimg) {
	return Base64.decode(bimg[B_IMG.length .. $]);
}
string bImgToStr(in ubyte[] bimg) {
	auto r = B_IMG ~ Base64.encode(bimg);
	return assumeUnique(r);
}

/// Enumメンバ名の先頭を小文字にして文字列に変換する。
@safe
pure
string enumToString(E)(E e) {
	mixin("final switch (e) {"
		~ enumToStringImpl!(E, 0)
		~ "}");
} unittest {
	debug mixin(UTPerf);
	enum En {
		Abc, Def
	}
	assert (enumToString(En.Abc) == "abc");
	assert (enumToString(En.Def) == "def");
}
private template enumToStringImpl(E, size_t Index) {
	static if (EnumMembers!E.length <= Index) {
		immutable enumToStringImpl = "";
	} else {
		immutable enumToStringImpl = "case E." ~ .text(EnumMembers!E[Index])
			~ ": return `" ~ .capLower(.text(EnumMembers!E[Index])) ~ "`;"
			~ enumToStringImpl!(E, Index + 1);
	}
}

/// 先頭を小文字にしたEnumメンバ名文字列をEnum値に変換する。
@safe
pure
E stringToEnum(E)(string name) {
	mixin("switch (name) {"
		~ stringToEnumImpl!(E, 0)
		~ "default: return E.init;"
		~ "}");
} unittest {
	debug mixin(UTPerf);
	enum En {
		Abc, Def
	}
	assert (stringToEnum!En("abc") == En.Abc);
	assert (stringToEnum!En("def") == En.Def);
}
private template stringToEnumImpl(E, size_t Index) {
	static if (EnumMembers!E.length <= Index) {
		immutable stringToEnumImpl = "";
	} else {
		immutable stringToEnumImpl = "case `" ~ .capLower(.text(EnumMembers!E[Index])) ~ "`:"
			~ "return E." ~ .text(EnumMembers!E[Index]) ~ ";"
			~ stringToEnumImpl!(E, Index + 1);
	}
}

/// enumのメンバ毎のメソッド呼出のswitch文を生成する。
template EnumToStringSwitch2(E, string EName, string Prefix) {
	immutable EnumToStringSwitch2 = "final switch (id) {\n"
		~ EnumToStringCase!(E, EName, Prefix, 0)
		~ "}";
}
/// ditto
template EnumToStringSwitch(E, string Prefix) {
	immutable EnumToStringSwitch = EnumToStringSwitch2!(E, E.stringof, Prefix);
}
/// switch文でenumのメンバ毎のメソッド呼出のメソッドを生成する。
template EnumToStringMethod2(E, string EName, string MethodName, string Prefix) {
	immutable EnumToStringMethod2 = "const string " ~ MethodName ~ "(" ~ EName ~ " id) {\n"
		~ "\tfinal switch (id) {\n"
		~ EnumToStringCase!(E, EName, Prefix, 0)
		~ "\t}\n"
		~ "}";
}
/// ditto
template EnumToStringMethod(E, string MethodName, string Prefix) {
	immutable EnumToStringMethod = EnumToStringMethod2!(E, E.stringof, MethodName, Prefix);
}
private template EnumToStringCase(E, string EName, string Prefix, size_t Index) {
	private import std.traits;
	private import std.conv;
	private immutable Case = "\tcase " ~ EName ~ "." ~ EnumMembers!E[Index].stringof ~ ": return " ~ Prefix ~ .upperToCap(std.conv.text(EnumMembers!E[Index])) ~ ";\n";
	static if (Index + 1 < EnumMembers!E.length) {
		immutable EnumToStringCase = Case ~ EnumToStringCase!(E, EName, Prefix, Index + 1);
	} else {
		immutable EnumToStringCase = Case;
	}
}

/// 文字列がすべて大文字の形式であれば単語の始まりのみ大文字の形式に変更する。
string upperToCap(string s) {
	if (!s.length) return s;
	bool isCap = true;
	foreach (c; s) {
		if (std.ascii.isLower(c)) {
			isCap = false;
			break;
		}
	}
	if (!isCap) return s;

	bool ul = true;
	char[] buf;
	foreach (i, c; s) {
		if (ul) {
			buf ~= c;
			ul = false;
		} else if ('_' == c) {
			ul = true;
		} else {
			buf ~= std.ascii.toLower(c);
		}
	}
	return .assumeUnique(buf);
} unittest {
	assert (upperToCap("UPPER_TO_CAP") == "UpperToCap");
	assert (upperToCap("UpperToCap") == "UpperToCap");
}

/// sの先頭1文字を小文字にする。
string capLower(string s) {
	if (!s.length) return s;
	dstring ds = to!dstring(s);
	return to!string([std.uni.toLower(ds[0])] ~ ds[1 .. $]);
}
/// sの先頭1文字を大文字にする。
string capUpper(string s) {
	if (!s.length) return s;
	dstring ds = to!dstring(s);
	return to!string([std.uni.toUpper(ds[0])] ~ ds[1 .. $]);
}

/// 例外を発しないstd.string.format()。
string tryFormat(T ...)(string s, T vals) {
	try {
		auto a = appender!string();
		formattedWrite(a, s, vals);
		return a.data;
	} catch (Exception e) {
		debugln(s);
		debugln(e);
		return s;
	}
}

/// ワイルドカードを用いてパターンマッチングを行う。
/// *は任意の文字列に、?は任意の文字にそれぞれ一致し、
/// \をエスケープ文字として使用する。
class Wildcard {
	/// sからマッチを探し、indexを返す。
	/// 見つからなければ-1を返す。
	int find(string s) {
		if (!s.length) return -1;
		size_t len;
		auto ds = toUTF32(s);
		int i = find(ds, false, len);
		if (i == -1) return -1;
		return toUTF8(ds[0 .. i]).length;
	}
	/// sに完全一致した場合にtrueを返す。
	bool match(string s) {
		if (!s.length) {
			return 0 == _left.length;
		}
		size_t len;
		auto ds = toUTF32(s);
		int i = find(ds, false, len);
		if (i == -1) return false;
		return 0 == i && ds.length == len;
	}
	/// s中のマッチする部分をtoに置換して返す。
	string replace(string s, string to) {
		if (!s.length) return s;
		auto ds = toUTF32(s);
		auto dto = toUTF32(to);
		dchar[] r;
		size_t len;
		while (true) {
			if (!ds.length) break;
			int i = find(ds, false, len);
			if (i == -1) {
				r ~= ds;
				break;
			}
			r ~= ds[0 .. i] ~ dto;
			ds = ds[i + len .. $];
		}
		return toUTF8(r);
	}
	/// s中のマッチする部分をカウントして返す。
	size_t count(string s) {
		if (!s.length) return 0;
		auto ds = toUTF32(s);
		size_t r = 0;
		size_t len;
		while (true) {
			if (!ds.length) break;
			int i = find(ds, false, len);
			if (i == -1) {
				break;
			}
			r++;
			ds = ds[i + len .. $];
		}
		return r;
	}

	private enum Pattern {
		CHAR, QUESTION
	}
	private static struct WChar {
		Pattern pattern;
		dchar chr;
		bool ignoreCase;
		bool match(dchar c) {
			switch (pattern) {
			case Pattern.CHAR: {
				if (ignoreCase) {
					return std.ascii.toLower(chr) == std.ascii.toLower(c);
				} else {
					return chr == c;
				}
			}
			case Pattern.QUESTION: {
				return true;
			}
			default: assert (0);
			}
		}
	}
	private WChar[] _left;
	private Wildcard _right;
	private bool _ignoreCase;
	private int findw(dstring s) {
		if (s.length < _left.length) return -1;
		for (int i = 0; i <= s.length - _left.length; i++) {
			int j;
			for (j = 0; j < _left.length && _left[j].match(s[i + j]); j++) {}
			if (j == _left.length) return i;
		}
		return -1;
	}
	private int rfindw(dstring s) {
		if (s.length < _left.length) return -1;
		for (int i = s.length - _left.length; i >= 0; i--) {
			int j;
			for (j = 0; j < _left.length && _left[j].match(s[i + j]); j++) {}
			if (j == _left.length) return i;
		}
		return -1;
	}
	private int find(ref dstring s, bool next, out size_t len) {
		auto sbase = s;
		while (true) {
			int i = next ? rfindw(s) : findw(s);
			if (i == -1) return -1;
			if (_right) {
				int j = _right.find(sbase[i + _left.length .. $], true, len);
				if (j == -1) {
					if (next) {
						s = s[0 .. $ - 1];
						continue;
					}
					return -1;
				}
				len += _left.length + j;
				return i;
			} else {
				len = _left.length;
				return i;
			}
		}
	}
	public static Wildcard opCall(string sub, bool ignoreCase = false) {
		auto wild = new Wildcard;
		wild._ignoreCase = ignoreCase;
		bool onbs = false;
		foreach (i, dchar c; sub) {
			switch (c) {
			case '?': {
				if (!onbs) {
					wild._left ~= WChar(Pattern.QUESTION, '\0', ignoreCase);
					onbs = false;
					break;
				}
			} goto default;
			case '*': {
				if (!onbs) {
					while (i < sub.length && sub[i] == '*')
						i++;
					wild._right = Wildcard(sub[i .. $], ignoreCase);
					return wild;
				}
			} goto default;
			case '\\': {
				if (onbs) wild._left ~= WChar(Pattern.CHAR, c, ignoreCase);
				onbs = !onbs;
			} break;
			default: {
				wild._left ~= WChar(Pattern.CHAR, c, ignoreCase);
				onbs = false;
			}
			}
		}
		if (onbs) wild._left ~= WChar(Pattern.CHAR, '\\', ignoreCase);
		return wild;
	}
} unittest {
	debug mixin(UTPerf);
	assert (Wildcard("test").find("test") == 0);
	assert (Wildcard("test").find("atest") == 1);
	assert (Wildcard("te?t").find("test") == 0);
	assert (Wildcard("t*t").find("abctest") == 3);
	assert (Wildcard("test*").find("test") == 0);
	assert (Wildcard("test\\*").find("atest*") == 1);
	assert (Wildcard("*test").find("abcdtest") == 0);
	assert (Wildcard("te\\?st").find("abcdte?st") == 4);
	assert (Wildcard("te\\\\st").find("abcdte\\st") == 4);
	assert (Wildcard("t*st").find("testst") == 0);
	assert (Wildcard("te\\st").find("te\\st") == -1);

	assert (Wildcard("te?t", true).find("tEst") == 0);
	assert (Wildcard("t*t", true).find("abcTEST") == 3);
	assert (Wildcard("test*", true).find("teST") == 0);

	assert (Wildcard("test").match("test"));
	assert (!Wildcard("test").match("atest"));
	assert (Wildcard("te?t").match("test"));
	assert (!Wildcard("t*t").match("abctest"));
	assert (Wildcard("test*").match("test"));
	assert (!Wildcard("test\\*").match("atest*"));
	assert (Wildcard("*test").match("abcdtest"));
	assert (!Wildcard("te\\?st").match("abcdte?st"));
	assert (!Wildcard("te\\\\st").match("abcdte\\st"));
	assert (Wildcard("t*st").match("testst"));
	assert (!Wildcard("te\\st").match("te\\st"));

	assert (Wildcard("te?t", true).match("tEst"));
	assert (!Wildcard("t*t", true).match("abcTEST"));
	assert (Wildcard("test*", true).match("teST"));

	assert (Wildcard("*").count("test") == 1);
	assert (Wildcard("te?t").count("testtestest") == 2);

	assert (Wildcard("t*s").replace("test", "A") == "At");
	assert (Wildcard("???t").replace("testtestest", "BB") == "BBBBest");
}

/// ファイルのMD5ダイジェストを取得する。
string fileToMD5Digest(string file) {
	if (.exists(file)) {
		try {
			return getDigestString([std.file.read(file)]);
		} catch (FileException e) {
			// 読み込めなかった場合は空文字列を返す
			debugln(e);
		}
	}
	return "";
}

/// 絶対パス化と正規化を行う。
string nabs(string path) {
	return buildNormalizedPath(absolutePath(path));
}

/// 絶対パス化・正規化を行いつつ相対パスを取る。
string abs2rel(string p1, string p2) {
	auto rel = relativePath(nabs(p1), nabs(p2));
	return rel.buildNormalizedPath();
}

/// 大/小文字を区別しないstartsWith。
bool istartsWith(in char[] a, in char[] b) {
	return a.length >= b.length && icmp(a[0 .. b.length], b) == 0;
}

/// 大/小文字を区別しないendsWith。
bool iendsWith(in char[] a, in char[] b) {
	return a.length >= b.length && icmp(a[$ - b.length .. $], b) == 0;
}

/// pathがlistに含まれていればtrueを返す。
bool containsPath(in string[] list, string path) {
	foreach (l; list) {
		if (cglobMatch(path, l)) return true;
	}
	return false;
} unittest {
	debug mixin(UTPerf);
	assert (containsPath(["*.txt"], "test.txt"));
	assert (containsPath([".*"], ".svn"));
}

/// ファイルパスに対応したstartsWith。
bool fnstartsWith(in char[] a, in char[] b) {
	static if (0 == filenameCharCmp('A', 'a')) {
		return istartsWith(a, b);
	} else {
		return startsWith(a, b);
	}
}

/// ファイルパスに対応したendsWith。
bool fnendsWith(string a, string b) {
	static if (0 == filenameCharCmp('A', 'a')) {
		return iendsWith(a, b);
	} else {
		return endsWith(a, b);
	}
}

/// 素材パスをencodeする。
string encodePath(string path) {
	return isBinImg(path) ? path : replace(path, dirSeparator, "/");
}
/// 素材パスをdecodeする。
string decodePath(string path) {
	return isBinImg(path) ? path : replace(path, "/", dirSeparator);
}

/// 末尾に改行文字が複数あったら纏める。
/// 末尾に改行が無い場合は改行一つを付加する。
string lastRet(string text) {
	if (!text.length) return "";
	bool ret = false;
	size_t i = text.length;
	foreach_reverse (j, char t; text) {
		if (t == '\n') {
			i = j;
			ret = true;
		} else {
			break;
		}
	}
	if (ret) {
		text = text[0u .. i + 1u];
	} else {
		text ~= '\n';
	}
	return text;
} unittest {
	debug mixin(UTPerf);
	assert (lastRet("test\n\n\n") == "test\n");
	assert (lastRet("test") == "test\n");
	assert (lastRet("t\n\nes\nt\n\n") == "t\n\nes\nt\n");
	assert (lastRet("test\n") == "test\n");
}

/// arrをin-placeでソートして返す。
T[] sort(alias Cmp, T)(T[] arr) {
	auto dlg = (in T a, in T b) {return Cmp(a, b) < 0;};
	return sortDlg!(T, typeof(dlg))(arr, dlg);
}
/// ditto
T[] sortDlg(T, Dlg)(T[] arr, Dlg lmin) {
	if (arr.length <= 1u) return arr;
	auto pv = arr[arr.length / 2u];
	size_t l = 0u;
	size_t r = arr.length - 1u;
	while (r > l) {
		while (lmin(arr[l], pv)) l++;
		while (lmin(pv, arr[r])) r--;
		if (r > l) {
			auto tmp = arr[l];
			arr[l] = arr[r];
			arr[r] = tmp;
		}
	}
	return sortDlg!(T)(arr[0u .. l], lmin) ~ sortDlg!(T)(arr[l .. $], lmin);
} unittest {
	debug mixin(UTPerf);
	assert (sortDlg!(int)([8, 1, 4, 6, 5, 3, 2, 9, 7, 0], (in int a, in int b) {return a < b;})
		== [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
	int[] arr = [5, 2, 3, 4, 6, 7, 9, 1, 0, 8];
	sortDlg!(int)(arr, (in int a, in int b) {return a > b;});
	assert (arr == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
	assert (sortDlg!(string)(["dd", "Bbb", "Cc", "aa"], (in string a, in string b) {return icmp(a, b) < 0;})
		== ["aa", "Bbb", "Cc", "dd"]);
}

/// ds内のcのインデックスをクイックサーチする。見つからなかった場合は-1を返す。
int qsearch(T)(in T[] ds, T c) {
	if (ds.length == 1) return ds[0] == c ? 0 : -1;
	int i = ds.length / 2;
	T c2 = ds[i];
	if (c < c2) {
		if (i == 0) return -1;
		return qsearch!(T)(ds[0 .. i], c);
	} else if (c > c2) {
		if (i + 1 == ds.length) return -1;
		int i2 = qsearch!(T)(ds[i + 1 .. $], c);
		if (i2 == -1) return -1;
		return i + i2 + 1;
	} else {
		return i;
	}
} unittest {
	debug mixin(UTPerf);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 0) == -1);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 1) == 0);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 2) == 1);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 3) == -1);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 4) == 2);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 8) == 3);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 16) == 4);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 32) == 5);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 64) == 6);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 127) == -1);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 128) == 7);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128], 129) == -1);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128, 256], 0) == -1);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128, 256], 1) == 0);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128, 256], 2) == 1);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128, 256], 3) == -1);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128, 256], 255) == -1);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128, 256], 256) == 8);
	assert (qsearch([1, 2, 4, 8, 16, 32, 64, 128, 256], 257) == -1);
}

/// 文字列型以外の配列であればtrue。
template isVArray(T) {
	const bool isVArray = !is (T : string) && !is (T : wstring) && !is (T : dstring)
		&& (isDynamicArray!(T) || isStaticArray!(T));
}

/// baseをuse()がtrueを返すように加工して返す。
/// base = xxxxの場合、use(base)がfalseであればxxxx (2)、
/// さらにuse("xxxx (2)")がfalseを返せばxxxx (3)……というように、
/// 付記した数字をインクリメントしていく。
/// baseが単純な数値なら+1する。
/// Params:
/// base = 元となる名前。
/// use = 名前を使用するか否かの判定関数。
/// space = falseの場合は括弧の前のスペースを付けない。
/// Returns: 新しい名前。
string createNewName(string base, bool delegate(string) use, bool space = true) {
	auto dbase = toUTF32(base);
	if (!std.regex.match(dbase, .regex!(dstring)(`^-?[1-9][0-9]*$`d)).empty) {
		try {
			long i = to!(long)(base);
			while (true) {
				auto s = to!(string)(i);
				if (use(s)) return s;
				if (i + 1 < i) break; // overflow
				i++;
			}
		} catch (Exception e) {
		}
	}
	ulong i = 2;
	dstring rexp = `\([0-9]+\)$`d;
	if (space) rexp = " "d ~ rexp;
	auto ni = std.regex.match(dbase, .regex!(dstring)(rexp));
	auto name = base;
	if (!ni.empty) {
		try {
			i = to!(ulong)(ni.hit[(space ? 2 : 1) .. $ - 1]) + 1;
			base = toUTF8(ni.pre);
		} catch (Exception e) {
		}
	}
	for (; !use(name); i++) {
		name = base ~ (space ? " (" : "(") ~ .to!(string)(i) ~ ")";
	}
	return name;
} unittest {
	debug mixin(UTPerf);
	assert (createNewName("aaa", (string n) {return n != "aaa" && n != "aaa (2)";}, true) == "aaa (3)");
	assert (createNewName("aaa", (string n) {return n != "aaa" && n != "aaa(2)";}, false) == "aaa(3)");
	assert (createNewName("aaa (2)", (string n) {return n != "aaa (2)" && n != "aaa (3)";}, true) == "aaa (4)");
	assert (createNewName("aaa(2)", (string n) {return n != "aaa(2)" && n != "aaa(3)";}, false) == "aaa(4)");
}
/// ditto
string createNewFileName(string path, bool isdir) {
	string parent = dirName(path);
	string name = baseName(path);
	string ext = isdir ? "" : .extension(name);
	if (!isdir) name = stripExtension(name);
	name = createNewName(name, (string name) {
		name = std.path.buildPath(parent, name);
		if (!isdir && ext.length) name = setExtension(name, ext);
		return !.exists(name);
	}, false);
	name = std.path.buildPath(parent, name);
	if (!isdir && ext.length) name = setExtension(name, ext);
	return name;
}

/// 改行文字を\nに置換する。
string encodeLf(string s) {
	s = replace(s, "\\", "\\\\");
	s = replace(s, "\n", "\\n");
	return s;
} unittest {
	debug mixin(UTPerf);
	assert (encodeLf("\\\\\n\n\\") == "\\\\\\\\\\n\\n\\\\");
}
/// strsを\nを結合子にして結合する。
/// lastLfがtrueの場合は全文字列の末尾にも\nを付与する。
string encodeLf(in string[] strs, bool lastLf = true) {
	string r;
	foreach (i, string s; strs) {
		r ~= replace(s, "\\", "\\\\");
		if (lastLf || i < strs.length - 1) {
			r ~= "\\n";
		}
	}
	return r;
} unittest {
	debug mixin(UTPerf);
	assert (encodeLf(decodeLf("t\\\\e\\\\st\\ntest\\\\n\\\\")) == "t\\\\e\\\\st\\ntest\\\\n\\\\\\n");
	assert (encodeLf(decodeLf("t\\\\e\\\\st\\ntest\\\\n\\\\"), false) == "t\\\\e\\\\st\\ntest\\\\n\\\\");
}
/// \nを改行文字としてstrをデコードする。
string decodeLf2(string str) {
	dstring buf;
	bool bs = false;
	foreach (dchar c; str) {
		if (bs) {
			if (c == 'n') {
				buf ~= "\n"d;
			} else if (c == '\\') {
				buf ~= "\\"d;
			} else {
				buf ~= "\\"d ~ c;
			}
			bs = false;
		} else {
			if (c == '\\') {
				bs = true;
			} else {
				buf ~= c;
			}
		}
	}
	if (bs) {
		buf ~= "\\";
	}
	return toUTF8(buf);
} unittest {
	debug mixin(UTPerf);
	assert (decodeLf("t\\\\e\\st\\ntest\\\\n\\") == ["t\\e\\st", "test\\n\\"]);
	assert (decodeLf("t\\\\e\\st\\n\\\\ntest\\\\n\\\\n\\n") == ["t\\e\\st", "\\ntest\\n\\n"]);
}

/// \nを改行文字としてstrをデコードする。
/// 結果は1行ごとの文字列の配列として返される。
/// useEmptyがfalseの場合、空行は無視する。
string[] decodeLf(string str, bool useEmpty = false) {
	string[] r;
	if (useEmpty) {
		int last = 0;
		foreach (i, s; splitLines!string(decodeLf2(str))) {
			r ~= s;
			if (s.length > 0) last = i + 1;
		}
		r.length = last;
	} else {
		foreach (s; splitLines!string(decodeLf2(str))) {
			if (s.length > 0) {
				r ~= s;
			}
		}
	}
	return r;
} unittest {
	debug mixin(UTPerf);
	assert (decodeLf("t\\\\e\\st\\ntest\\\\n\\") == ["t\\e\\st", "test\\n\\"]);
	assert (decodeLf("t\\\\e\\st\\n\\\\ntest\\\\n\\\\n\\n") == ["t\\e\\st", "\\ntest\\n\\n"]);
}

/// bをTrue/Falseの文字列に変換する。
string fromBool(bool b) {
	return b ? "True" : "False";
}
/// True/Falseの文字列からbool値を生成する。
bool parseBool(string b) {
	switch (b) {
	case "True":
		return true;
	case "False":
		return false;
	default:
		throw new Exception("Not bool: " ~ b);
	}
}

/// 連想配列をクリアする。
void removeAll(Key, Value)(ref Value[Key] table) {
	typeof(table) init;
	table = init;
}

/// Tがソート済みであればtrueを返す。
bool isSorted(T)(in T[] arr) {
	auto dlg = (in T a, in T b) {return a < b;};
	return isSortedDlg!(T, typeof(dlg))(arr, dlg);
}
/// ditto
bool isSortedDlg(T, Dlg)(in T[] arr, Dlg cmp) {
	foreach (i, v; arr) {
		if (arr.length <= i + 1) break;
		if (!cmp(v, arr[i + 1])) {
			return false;
		}
	}
	return true;
} unittest {
	debug mixin(UTPerf);
	assert (isSorted([1, 2, 3]));
	assert (!isSorted([1, 3, 2]));
}

/// 文字列を16進形式に変換する。
/// Example:
/// ---
/// string result;
/// result = toHex("aBc");
/// assert (result == "%61%42%63", result);
/// result = toHex("あいう");
/// assert (result == "%E3%81%82%E3%81%84%E3%81%86", result);
/// ---
string toHex(string str) {
	string r;
	foreach (i, c; str) {
		r ~= "%" ~ format("%02X", cast(int) c);
	}
	return r;
} unittest {
	debug mixin(UTPerf);
	string result;
	result = toHex("aBc");
	assert (result == "%61%42%63", result);
	result = toHex("あいう");
	assert (result == "%E3%81%82%E3%81%84%E3%81%86", result);
}

private import std.c.stdlib;
private import std.c.string;
/// 環境変数envの値を返す。存在しない場合はnullを返す。
string getenv(string env) {
	auto v = std.c.stdlib.getenv((env ~ '\0').ptr);
	if (!v) return null;
	string r = v[0u .. strlen(v)].idup;
	version (Windows) {
		r = touni(r);
	}
	return r;
}

private string createFileImpl(bool Dir)(string parent, string name, string ext, string prefix) {
	string clean(string name) {
		name = replace(name, dirSeparator, "");
		static if (altDirSeparator.length) {
			name = replace(name, altDirSeparator, "");
		}
		name = replace(name, ".", "");
		name = replace(name, " ", "");
		if (name.length == 0) {
			name = "noname";
		}
		return name;
	}
	string r;
	void create() {
		r = prefix ~ name;
		r = r.toFileName();
		if (ext.length) r = setExtension(r, ext);
		r = std.path.buildPath(parent, r);
		r = createNewFileName(r, Dir);
	}
	name = clean(name);
	create();
	return r;
}
/// 存在しないファイル名を生成して返す。
/// 指定されたファイル名がすでに存在する場合、"test(2).txt"のように
/// 括弧つき数字をつける。
/// それでも存在する場合、括弧内の数値をインクリメントしてゆく。
string createFileI(string parent, string name, string ext, string prefix) {
	return createFileImpl!(false)(parent, name, ext, prefix);
}
/// ditto
string createFolder(string parent, string name) {
	return createFileImpl!(true)(parent, name, "", "");
}

/// ファイル削除の準備を行う。
void preRemove(string delpath) {
	version (Windows) {
		// 書込み権限を付けておく
		auto fname = std.utf.toUTFz!(wchar*)(delpath);
		SetFileAttributesW(fname, FILE_ATTRIBUTE_NORMAL);
	}
}

/// ファイルをコピーする。ファイル名が重複する場合は、(2)、(3)、
/// ……のように括弧付き番号が付与される。
/// Params:
/// sPath = シナリオのパス。
/// path = コピー元のファイル。
/// added = シナリオ内のどのフォルダにコピーするか。
/// binImgToRef = 格納イメージを参照に差し替えるか。
/// Returns: コピー後のファイルパス。
string copyTo(string sPath, string path, string added, bool binImgToRef) {
	bool binImg = isBinImg(path);
	if (binImg && !binImgToRef) return path;
	auto mtDir = std.path.buildPath(sPath, added);
	if (!exists(mtDir)) mkdirRecurse(mtDir);
	string to;
	if (binImg) {
		to = std.path.buildPath(mtDir, "@simage(1).bmp");
	} else {
		to = std.path.buildPath(mtDir, baseName(path));
	}
	to = createNewFileName(to, false);
	if (binImg) {
		std.file.write(to, strToBImg(path));
	} else {
		copy(path, to);
	}
	return std.path.buildPath(added, baseName(to));
}

/// aからbへすべてのファイル・ディレクトリをコピーする。
void copyAll(string a, string b, bool overwrite = false) {
	if (isDir(a)) {
		if (!.exists(b)) mkdir(b);
		foreach (file; clistdir(a)) {
			string fPath = std.path.buildPath(a, file);
			string tPath = std.path.buildPath(b, file);
			copyAll(fPath, tPath);
		}
	} else {
		if (overwrite && .exists(b)) delAll(b);
		std.file.copy(a, b);
	}
}

/// listDirの代替。指定されたディレクトリに含まれるファイル名の一覧を返す。
string[] clistdir(string dir) {
	string[] r;
	if (!.exists(dir)) return r;
	foreach (string file; dirEntries(dir, SpanMode.shallow, false)) {
		r ~= file.baseName();
	}
	return r;
}

/// delpath以降の全てのファイル・ディレクトリを削除する。
/// Params:
/// force = trueを指定した場合、途中でエラーが発生しても中断しない。
void delAll(string delpath, bool force = true) {
	if (!.exists(delpath)) return;
	void __delAll(string delpath, ref Exception ee) {
		try {
			preRemove(delpath);
			if (isDir(delpath)) {
				foreach (file; clistdir(delpath)) {
					__delAll(std.path.buildPath(delpath, file), ee);
				}
				rmdir(delpath);
			} else {
				std.file.remove(delpath);
			}
		} catch (Exception e) {
			if (!force) throw e;
			if (!ee) ee = new FileException(e.msg);
		}
	}
	Exception e = null;
	__delAll(delpath, e);
	if (force && e) throw e;
}

/// arrにaが見つかればtrueを返す。
bool contains(string pred = "a == b", T1, T2)(in T1[] arr, in T2 a) {
	foreach (b; arr) {
		if (mixin(pred)) return true;
	}
	return false;
}

static if (0 == filenameCharCmp('A', 'a')) {
	/// ファイル名を比較する。
	alias icmp fncmp;
} else {
	/// ファイル名を比較する。
	alias cmp fncmp;
}

/// 文字列aとbを比較する。
/// 同位置に数値が含まれていた場合は、数字列の長さに係わらず
/// その数値同士を優先的に比較する。
/// Example:
/// ---
/// assert (ncmp("42", "2") > 0);
/// assert (ncmp("02", "2") < 0);
/// assert (ncmp("abc42", "abc4") > 0);
/// assert (ncmp("abc4a", "abc4b") < 0);
/// assert (ncmp("abc", "def") < 0);
/// ---
int ncmp(C1, C2)(in C1[] a, in C2[] b) {
	return ncmpImpl!(C1, C2, std.string.cmp)(a, b);
}
/// ditto
int incmp(C1, C2)(in C1[] a, in C2[] b) {
	return ncmpImpl!(C1, C2, std.string.icmp)(a, b);
}
/// ditto
int fnncmp(C1, C2)(in C1[] a, in C2[] b) {
	return ncmpImpl!(C1, C2, fncmp)(a, b);
}

private int ncmpImpl(C1, C2, alias Cmp)(in C1[] a, in C2[] b) {
	for (size_t i = 0, j = 0; i < a.length || j < b.length;) {
		if (i >= a.length) return -1;
		if (j >= b.length) return 1;
		C1[] buf1;
		for (size_t k = i; k < a.length && std.ascii.isDigit(a[k]); k++) {
			buf1 ~= a[k];
		}
		C2[] buf2;
		for (size_t k = j; k < b.length && std.ascii.isDigit(b[k]); k++) {
			buf2 ~= b[k];
		}
		if (buf1.length && buf2.length) {
			int cr;
			if (buf1.length < buf2.length) {
				cr = Cmp(zfill_(buf1, buf2.length), buf2);
				if (cr != 0) return cr;
			} else if (buf1.length > buf2.length) {
				cr = Cmp(buf1, zfill_(buf2, buf1.length));
				if (cr != 0) return cr;
			}
			cr = Cmp(buf1, buf2);
			if (cr != 0) return cr;
			i += buf1.length;
			j += buf2.length;
		} else {
			if (a[i] < b[j]) return -1;
			if (a[i] > b[j]) return 1;
			i++;
			j++;
		}
	}
	return 0;
} unittest {
	debug mixin(UTPerf);
	assert (ncmp("42", "2") > 0);
	assert (ncmp("02", "2") < 0);
	assert (ncmp("abc42", "abc4") > 0);
	assert (ncmp("abc4a", "abc4b") < 0);
	assert (ncmp("abc", "def") < 0);
}

private C[] zfill_(C)(in C[] str, size_t width) {
	if (str.length >= width) return cast(C[]) str.dup;
	Unqual!(C)[] r;
	r.length = width;
	size_t n = width - str.length;
	r[0 .. n] = '0';
	r[n .. $] = str;
	return cast(C[]) r;
} unittest {
	debug mixin(UTPerf);
	assert (zfill_("abc", 2) == "abc");
	assert (zfill_("abc", 3) == "abc");
	assert (zfill_("abc", 4) == "0abc");
	assert (zfill_("abc", 5) == "00abc");
	assert (zfill_("abc"w, 5) == "00abc"w);
	assert (zfill_("abc"d, 5) == "00abc"d);
}

/// arrからaを除去する。
T[] remove(string pred = "a == b", T)(ref T[] arr, T a) {
	foreach (i, b; arr) {
		if (mixin (pred)) {
			return (arr = arr[0 .. i] ~ arr[i + 1 .. $]);
		}
	}
	return arr;
}

/// 簡単なhashset。
class HashSet(T) {
	private int[T] a;
	/// 唯一のコンストラクタ。
	@property
	this () {
		/// Nothing
	}
	/// 要素を追加する。
	void add(T v) {
		a[v] = 0;
	}
	/// 要素を除外する。
	void remove(T v) {
		a.remove(v);
	}
	/// 要素を全て除外する。
	void clear() {
		int[T] init;
		a = init;
	}
	/// 含まれていればtrue。
	const
	bool contains(T v) {
		return (v in a) !is null;
	}
	/// 要素数。
	@property
	const
	size_t size() {
		return a.length;
	}
	/// 空であればtrue。
	@property
	const
	bool isEmpty() {
		return a.length == 0u;
	}
	int opApply(int delegate(ref T) dg) {
		int r = 0;
		foreach (t, v; a) {
			r = dg(t);
			if (r) break;
		}
		return r;
	}
	const
	T[] toArray() {
		return a.keys;
	}
}

version (Windows) {
	private const STARTF_USESHOWWINDOW = 0x01;
	private const CREATE_NEW_CONSOLE = 0x10;

	/// プロセスを起動する。成功した場合はtrueを返す。
	bool exec(string process, string workDir = "", bool console = true, bool wait = false) {
		STARTUPINFO setup;
		setup.cb = setup.sizeof;
		memset(&setup, 0, setup.sizeof);
		PROCESS_INFORMATION info;

		DWORD flag = 0;
		if (!console) {
			setup.dwFlags = STARTF_USESHOWWINDOW;
			setup.wShowWindow = SW_HIDE;
			flag |= CREATE_NEW_CONSOLE;
		}

		int r;
		wchar[] procTemp;
		procTemp.length = process.length + 1;
		procTemp[0 .. $] = toUTFz!(wchar*)(process)[0 .. procTemp.length];
		r = CreateProcessW(null, procTemp.ptr, null, null, false, flag, null,
			workDir.length ? toUTFz!(wchar*)(workDir) : null, &setup, &info);
		if (r) {
			if (wait) {
				WaitForSingleObject(info.hProcess, INFINITE);
			}
			CloseHandle(info.hThread);
			return true;
		}
		return false;
	}
} else {
	private extern (C) {
		intptr_t fork();
	}
	import std.c.stdlib;
	import std.process;
	/// プロセスを起動する。成功した場合はtrueを返す。
	/// FIXME: まったくテストしていない
	bool exec(string process, string workDir = "", bool console = true, bool wait = false) {
		auto pid = fork();
		if (pid < 0) {
			return false;
		} else if (pid > 0) {
			return true;
		} else {
			assert (pid == 0);
			if (workDir.length) chdir(workDir);
			if (execv(process, null) == -1) {
				exit(-1);
			}
            return true;
		}
	}
}

/// pathがsPath以下に存在するものであればtrueを返す。
bool hasPath(string sPath, string path) {
	path = nabs(path);
	sPath = nabs(sPath);
	return cwx.utils.fnstartsWith(path, sPath)
		&& (path.length == sPath.length || startsWith(path[sPath.length .. $], dirSeparator));
} unittest {
	debug mixin(UTPerf);
	version (Windows) {
		assert (hasPath(`c:\test\aaa`, `c:\test\aaa\bbb`));
		assert (!hasPath(`c:\test\aaa`, `c:\test\aaaaaa`));
		assert (hasPath(`c:\test\aaa`, `c:\test\aaa`));
	}
}

/// ファイルパスから取得する何らかのデータをキャッシュするための
/// 一連の変数と関数を定義する。
template FileCache(T ...) {
	struct Cache {
		std.datetime.SysTime ftm;
		static if (T.length == 1) {
			T[0] value;
		} else {
			T values;
		}
	}
	static const CACHE_MAX = 1024;
	static Cache[string] caches;
	static string[] cachePaths;
	void putCache(string path, T v) {
		if (!exists(path)) return;
		path = nabs(path);
		static if (0 == filenameCharCmp('A', 'a')) {
			path = std.string.toLower(path);
		}
		if (cachePaths.length >= CACHE_MAX) {
			caches.remove(cachePaths[0u]);
			cachePaths = cachePaths[1u .. $];
		}
		caches[path] = Cache(timeLastModified(path), v);
		cachePaths ~= path;
	}
	Cache* cache(string path) {
		if (!exists(path)) return null;
		path = nabs(path);
		static if (0 == filenameCharCmp('A', 'a')) {
			path = std.string.toLower(path);
		}
		auto cache = path in caches;
		if (!cache) return null;
		return cache.ftm == timeLastModified(path) ? cache : null;
	}
}

/// 親ディレクトリへの移動が含まれているパスであればtrueを返す。
bool hasParDir(string path) {
	path = buildNormalizedPath(path);
	if (startsWith(path, pardir ~ dirSeparator)) return true;
	if (.countUntil(path, dirSeparator ~ pardir ~ dirSeparator) != -1) return true;
	return false;
}

/// sにsubがいくつ含まれているかを返す。
/// std.string.count()と違って大文字と小文字を区別しない。
size_t icount(string s, string sub) {
	int c = 0;
	while (true) {
		auto i = std.string.indexOf(s, sub, std.string.CaseSensitive.no);
		if (i < 0) return c;
		c++;
		s = s[i + sub.length .. $];
	}
} unittest {
	debug mixin(UTPerf);
	assert (icount("test", "Es") == 1);
	assert (icount("aaaaaaa", "AA") == 3);
}

/// sに含まれるfromをtoに置換した結果を返す。
/// std.string.replace()と違って大文字と小文字を区別しない。
string ireplace(string s, string from, string to) {
	string r = "";
	while (true) {
		auto i = std.string.indexOf(s, from, std.string.CaseSensitive.no);
		if (i < 0) return r ~ s;
		r ~= s[0 .. i] ~ to;
		s = s[i + from.length .. $];
	}
} unittest {
	debug mixin(UTPerf);
	assert (ireplace("testte", "te", "tea") == "teasttea");
	assert (ireplace("test", "Es", "TT") == "tTTt");
	assert (ireplace("aaaaaaa", "AA", "BB") == "BBBBBBa");
}

/// 数値をCount桁でSepによって区切った文字列にして返す。
string formatNum(N, size_t Count = 3, string Sep = ",")(N num) {
	string s = to!(string)(num);
	string buf;
	while (s.length > Count) {
		if (buf.length) buf = Sep ~ buf;
		buf = s[$ - Count .. $] ~ buf;
		s = s[0 .. $ - Count];
	}
	if (buf.length) buf = Sep ~ buf;
	buf = s ~ buf;
	return buf;
} unittest {
	debug mixin(UTPerf);
	assert (formatNum(123) == "123");
	assert (formatNum(123456) == "123,456");
	assert (formatNum(1234567) == "1,234,567");
}

/// arrをコピーして返す。
T1[T2] dupAssocArray(T1, T2)(in T1[T2] arr) {
	T1[T2] arr2;
	foreach (key, val; arr) {
		arr2[key] = val;
	}
	return arr2;
}

/// textの幅を調べる。
/// マルチバイト文字は常に2文字分の幅を持つものとして扱われる。
/// Example:
/// ---
/// assert (lengthJ("斉") == 2);
/// assert (lengthJ("大秦") == 4);
/// assert (lengthJ("1万") == 3);
/// assert (lengthJ("1000") == 4);
/// assert (lengthJ("100万") == 5);
/// ---
size_t lengthJ(in char[] text) {
	size_t len = 0u;
	foreach (dchar c; text) {
		char[] s;
		std.utf.encode(s, c);
		len += s.length > 1u ? 2u : 1u;
	}
	return len;
} unittest {
	debug mixin(UTPerf);
	assert (lengthJ("斉") == 2);
	assert (lengthJ("大秦") == 4);
	assert (lengthJ("1万") == 3);
	assert (lengthJ("1000") == 4);
	assert (lengthJ("100万") == 5);
}

/// 前後の空行を無視して行数をカウントする。
size_t lineCount(in string[] lines) {
	int from = -1;
	int to = -1;
	foreach (i, l; lines) {
		if (l.length) {
			if (from == -1) from = i;
			to = i + 1;
		}
	}
	return to - from;
} unittest {
	debug mixin(UTPerf);
	assert (lineCount(splitLines!string("\na\nb\n\nc\n\n")) == 4);
}
/// std.algorithm.countUntilはconst配列に対する検索が通らない
sizediff_t cCountUntil(string pred = "a == b", R1, R2)(R1 arr, R2 b) {
	foreach (i, a; arr) {
		if (mixin(pred)) {
			return i;
		}
	}
	return -1;
}

/// lengthJ()で得られる長さに基づいたスライスを得る。
/// Example:
/// ---
/// assert (sliceJ("あいうえお", 2, 10) == "いうえお");
/// assert (sliceJ("あいうeお", 2, 9) == "いうeお");
/// assert (sliceJ("あいうえお", 2, 9) == "いうえ");
/// assert (sliceJ("あいうえお", 1, 9) == "いうえ");
/// assert (sliceJ("あいうえお", 0, 9) == "あいうえ");
/// assert (sliceJ("あいうえお", 3, 4) == "");
/// assert (sliceJ("あいうえお", 3, 5) == "");
/// assert (sliceJ("あいうえお", 3, 6) == "う");
/// ---
/// See_Also: lengthJ()
string sliceJ(string text, size_t from, size_t to) {
	void te() {
		string msg = "text: " ~ text ~ ", from: " ~ .to!(string)(from) ~ ", to: " ~ .to!(string)(to);
		throw new Exception(msg, __FILE__, __LINE__);
	}
	if (from > to) te();
	size_t i = 0u, j = 0u;
	size_t s = size_t.max, e;
	bool ok = false;
	size_t len;
	foreach (dchar c; text) {
		if (s == size_t.max && from <= j) s = i;
		char[] cbuf;
		std.utf.encode(cbuf, c);
		len = cbuf.length;
		i += len;
		j += len > 1 ? 2 : 1;
		if (to <= j) {
			e = to < j ? i - len : i;
			if (s == size_t.max) s = e;
			ok = true;
			break;
		}
	}
	if (!ok) te();
	return text[s .. e];
} unittest {
	debug mixin(UTPerf);
	assert (sliceJ("あいうえお", 2, 10) == "いうえお");
	assert (sliceJ("あいうeお", 2, 9) == "いうeお");
	assert (sliceJ("あいうえお", 2, 9) == "いうえ");
	assert (sliceJ("あいうえお", 1, 9) == "いうえ");
	assert (sliceJ("あいうえお", 0, 9) == "あいうえ");
	assert (sliceJ("あいうえお", 3, 4) == "");
	assert (sliceJ("あいうえお", 3, 5) == "");
	assert (sliceJ("あいうえお", 3, 6) == "う");
	assert (sliceJ("1いうえお", 3, 7) == "うえ");
	assert (sliceJ("1いうえお", 3, 8) == "うえ");
	assert (sliceJ("1いうえお", 3, 9) == "うえお");
	assert (sliceJ("1いuえお", 3, 8) == "uえお");
	assert (sliceJ("あいうえお", 3, 3) == "");
}

/// strip()と同様に動作するが、全角空白を空白文字として扱わない。
string astrip(string s) {
	return s.astripl().astripr();
}
/// ditto
string astripl(string s) {
	foreach (i, c; s) {
		if (!std.ascii.isWhite(c)) {
			return s[i .. $];
		}
	}
	return "";
}
/// ditto
string astripr(string s) {
	foreach_reverse (i, c; s) {
		if (!std.ascii.isWhite(c)) {
			return s[0 .. i + 1];
		}
	}
	return "";
}

/// '[' ']'を含むファイル名が存在するため、globMatch()の代替を用意する必要がある。
bool cglobMatch(string a, string b) {
	b = b.replace("\\", "\\\\");
	return Wildcard(b, 0 == filenameCharCmp('A', 'a')).match(a);
} unittest {
	debug mixin(UTPerf);
	assert (cfnmatch(r"C:\path", r"C:\path"));
}
/// ファイル名が一致するか。
bool cfnmatch(in char[] a, in char[] b) {
	return 0 == filenameCmp(a, b);
}

/// Nameを変数名として使用できる場合はtrue。
template isVariableName(string Name) {
	immutable isVariableName = is(typeof({mixin("int " ~ Name ~ ";");}));
}
static assert (!isVariableName!("version"));
static assert (isVariableName!("version_"));

/// Nameを変数名として使用できない場合は末尾に'_'を追加する。
template variableName(string Name) {
	immutable variableName = isVariableName!Name ? Name : Name ~ "_";
}
static assert (variableName!("version") == "version_");
static assert (variableName!("versio") == "versio");

version (Windows) {
	extern (Windows) {
		private alias UINT function(WCHAR c) PathGetCharTypeW;
		private immutable GCT_INVALID = 0x0;
		private immutable GCT_LFNCHAR = 0x1;
		private immutable GCT_SHORTCHAR = 0x2;
		private immutable GCT_WILD = 0x4;
		private immutable GCT_SEPARATOR = 0x8;
		private __gshared void* _shlwapi = null;
		private __gshared PathGetCharTypeW _PathGetCharType = null;
	}
	shared static ~this() {
		if (_shlwapi) dlclose(_shlwapi);
	}
}
/// ファイル名に使用できる文字か。
@property
bool isFileNameChar(dchar c) {
	version (Windows) {
		static immutable DN = "\\/:*?\"<>|"d;
		if (!_shlwapi) {
			_shlwapi = dlopen("shlwapi.dll");
		}
		if (!_shlwapi) {
			debugln("not found: shlwapi.dll");
			return -1 == std.string.indexOf(DN, c);
		}
		if (!_PathGetCharType) {
			_PathGetCharType = cast(PathGetCharTypeW) dlsym(_shlwapi, "PathGetCharTypeW");
		}
		if (!_PathGetCharType) {
			debugln("not found: PathGetCharTypeW");
			return -1 == std.string.indexOf(DN, c);
		}
		foreach (wchar wc; [c]) {
			auto r = _PathGetCharType(wc);
			if (!(GCT_LFNCHAR & r) && !(GCT_SHORTCHAR & r)) {
				return false;
			}
		}
		return true;
	} else version (Posix) {
		static immutable DN = "/"d;
		return 0 != c && -1 == std.string.indexOf(DN, c);
	} else static assert (0);
}

/// ファイル名に使用できない文字があったらcに置換する。
string toFileName(string name, dchar c = '_') {
	dchar[] buf;
	foreach (dchar n; name) {
		buf ~= isFileNameChar(n) ? n : c;
	}
	version (Windows) {
		// 末尾が'.'のファイル名は拒否される
		if (buf.length && '.' == buf[$ - 1]) {
			buf[$ - 1] = c;
		}
	}
	return to!string(buf);
}

/// 実行モジュールのパスを返す。
string exeName(string args0) {
	version (Windows) {
		char[MAX_PATH] pathBuf;
		if (GetModuleFileNameA(null, pathBuf.ptr, pathBuf.length)) {
			return fromMBSz(pathBuf.idup.ptr);
		} else {
			version (Console) {
				cwriteln("GetModuleFileName failure!");
			}
		}
	} else version (linux) {
		char[1024] buf;
		buf[] = '\0';
		if (-1 != .readlink("/proc/self/exe", buf.ptr, buf.sizeof)) {
			cdebugln(buf);
			return buf[0 .. .strlen(buf.ptr)].idup;
		}
	}
	return args0;
}

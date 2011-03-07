
module cwx.utils;

import cwx.sjis;

public import std.compat;
import std.conv;
import std.string;
import std.file;
import std.path;
import std.uni;
import std.utf;
import std.base64;
import std.stdio;
import std.ctype;
import std.cstream;
import std.traits;
import std.date;
import std.perf;
import std.metastrings;
import std.regexp;

private version (Windows) {
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
		BOOL SetFileAttributesW(LPWSTR, DWORD);
		BOOL CreateProcessW(LPCWSTR, LPWSTR, SECURITY_ATTRIBUTES*, SECURITY_ATTRIBUTES*,
			BOOL, DWORD, LPVOID, LPCWSTR, STARTUPINFO*, PROCESS_INFORMATION*);
	}
}

string LATEST_VERSION = "";

string debugLog = "cwxeditor_error.log";

/// デバグログに文字列を出力する。
void fdebugln(T ...)(T vals) {
	char[] buf;
	foreach (v; vals) {
		buf ~= to!(char[])(v);
	}
	debug {
		version (Windows) {
			printf("%s\n\0".ptr, tosjisz(buf));
			dout.flush;
		} else {
			writefln("%s", buf);
		}
	}
	d_time d = getUTCtime;
	d = UTCtoLocalTime(d);
	auto year = YearFromTime(d);
	auto month = MonthFromTime(d) + 1;
	auto day = DateFromTime(d);
	auto hour = HourFromTime(d);
	auto min = MinFromTime(d);
	auto sec = SecFromTime(d);
	std.file.append(debugLog,
		format("%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, min, sec)
		~ "\t" ~ buf ~ linesep);
}
/// debugコンパイルされている際は デバグログに文字列を出力すると
/// 共にfdebugln()を呼出し、ファイル出力する。
void debugln(T ...)(T vals) {
	debug {
		fdebugln!(T)(vals);
	}
}

debug {
	PerformanceCounter.interval_type t[1024u];
	static ~this () {
		foreach (i, time; t) {
			if (time > 0u) {
				debugln(format("%04d = ", i), time);
			}
		}
	}
	template FPerf(int I) {
		static const FPerf
			= "scope f_timer = new std.perf.PerformanceCounter;"
			~ "f_timer.start;"
			~ "scope (exit) {"
			~ "f_timer.stop;"
			~ ".t[" ~ ToString!(I) ~ "] += f_timer.milliseconds;"
			~ "}";
	}
	const BPerfS = "scope b_timer = new std.perf.PerformanceCounter; b_timer.start;";
	template BPerf(int I) {
		static const BPerf
			= "b_timer.stop;"
			~ ".t[" ~ ToString!(I) ~ "] += b_timer.milliseconds;"
			~ "b_timer.start;";
	}
	static assert (FPerf!(10));
	static assert (BPerf!(10));
}

static B_IMG = "binaryimage://";
bool isBinImg(string path) {
	return path.length >= B_IMG.length && path[0u .. B_IMG.length] == B_IMG;
}
byte[] strToBImg(string bimg) {
	return cast(byte[]) std.base64.decode(bimg[B_IMG.length .. $]);
}
string bImgToStr(byte[] bimg) {
	return B_IMG ~ std.base64.encode(cast(string) bimg);
}

/// 16進数文字列xを整数に変換する。
int xtoi(string x) {
	int i = 0;
	foreach (char c; x) {
		i <<= 4;
		if ('a' <= c && c <= 'z') {
			i += c - 'a' + 10;
		} else if ('A' <= c && c <= 'Z') {
			i += c - 'A' + 10;
		} else if ('0' <= c && c <= '9') {
			i += c - '0';
		} else {
			throw new Exception("invalid x: " ~ x);
		}
	}
	return i;
} unittest {
	assert (xtoi("FF") == 255, to!(string)(xtoi("FF")));
	assert (xtoi("ff") == 255);
	assert (xtoi("FFFE") == 65534);
	assert (xtoi("0F") == 15);
	assert (xtoi("10") == 16);
}

/// D2のstd.conv.toの代替。
T2 to(T2, T1)(T1 val) {
	static if (is(T2 : string)) {
		static if (is(T1 == bool)) {
			return val ? true.stringof : false.stringof;
		} else static if (is(T1 : Object)) {
			return val ? val.toString : "null";
		} else static if (is(T1 == struct)) {
			return val.toString;
		} else static if (is(T1 : string)) {
			return val;
		} else static if (isVArray!(T1)) {
			char[] buf = "[";
			foreach (i, v; val) {
				if (i > 0) buf ~= ", ";
				buf ~= to!(string)(v);
			}
			buf ~= "]";
			return buf;
		} else static if (isAssociativeArray!(T1)) {
			char[] buf = "[";
			bool first = true;
			foreach (k, v; val) {
				if (!first) buf ~= ", ";
				first = false;
				buf ~= to!(string)(k) ~ ":" ~ to!(string)(v);
			}
			buf ~= "]";
			return buf;
		} else {
			return std.string.toString(val);
		}
	} else static if (is(T2 == bool)) {
		return icmp(val, "true") == 0;
	} else static if (is(T2 == ubyte)) {
		return toUbyte(val);
	} else static if (is(T2 == byte)) {
		return toByte(val);
	} else static if (is(T2 == ushort)) {
		return toUshort(val);
	} else static if (is(T2 == short)) {
		return toShort(val);
	} else static if (is(T2 == uint)) {
		return toUint(val);
	} else static if (is(T2 == int)) {
		return toInt(val);
	} else static if (is(T2 == ulong)) {
		return toUlong(val);
	} else static if (is(T2 == long)) {
		return toLong(val);
	} else static if (is(T2 == float)) {
		return toFloat(val);
	} else static if (is(T2 == double)) {
		return toDouble(val);
	} else static if (is(T2 == real)) {
		return toReal(val);
	} else {
		static assert (0);
	}
}

/// t1とt2を入替える。
void swap(T)(ref T t1, ref T t2) {
	T temp = t1;
	t1 = t2;
	t2 = temp;
}

/// 絶対パス化と正規化を行う。
string nabs(string path) {
	return normal(rel2abs(path));
}

/// 大/小文字を区別しないstartsWith。
bool istartsWith(string a, string b) {
	return a.length >= b.length && icmp(a[0 .. b.length], b) == 0;
}

/// 大/小文字を区別しないendsWith。
bool iendsWith(string a, string b) {
	return a.length >= b.length && icmp(a[$ - b.length .. $], b) == 0;
}

/// pathがlistに含まれていればtrueを返す。
bool containsPath(string[] list, string path) {
	foreach (l; list) {
		if (fnmatch(path, l)) return true;
	}
	return false;
} unittest {
	assert (containsPath(["*.txt"], "test.txt"));
	assert (containsPath([".*"], ".svn"));
}

/// ファイルパスに対応したstartsWith。
bool fnstartsWith(string a, string b) {
	static if (fnmatch("A", "a")) {
		return istartsWith(a, b);
	} else {
		return startsWith(a, b);
	}
}

/// ファイルパスに対応したendsWith。
bool fnendsWith(string a, string b) {
	static if (fnmatch("A", "a")) {
		return iendsWith(a, b);
	} else {
		return endsWith(a, b);
	}
}

/// 絶対パスであればtrueを返す。
bool isabs(string path) {
	version (Windows) {
		return startsWith(path, `\`) || std.path.isabs(path);
	} else {
		return std.path.isabs(path) != 0;
	}
}

/// 絶対パスにする。
char[] rel2abs(char[] path) {
	if (isabs(path)) {
		version (Windows) {
			if (!startsWith(path, `\\`) && startsWith(path, `\`)) {
				return std.path.join(getDrive(getcwd), path);
			}
		}
		return path;
	}
	return std.path.join(getcwd, path);
}

/// 正規化を行う。
string normal(string path) {
	static if (altsep.length) {
		path = replace(path, altsep, sep);
	}
	scope spl = std.string.split(path, sep);
	string[] buf;
	foreach (i, str; spl) {
		if (str == curdir) {
			continue;
		} else if (str == pardir) {
			if (buf.length && buf[$ - 1] != pardir) {
				buf = buf[0 .. $ - 1];
			} else {
				buf ~= str;
			}
		} else if (str.length || i + 1 < spl.length) {
			buf ~= str;
		}
	}
	return expandTilde(std.string.join(buf, sep));
} unittest {
	version (Windows) {
		assert (normal("C:/aaaa/./bbbb/../ccc../dd/test.d/..") == `C:\aaaa\ccc..\dd`);
		assert (normal(`C:\./,/..\aaa/bbb/cc\../...\..\`) == `C:\aaa\bbb`);
		assert (normal(`..\..\./,/..\aaa/bbb/cc\../...\..\`) == `..\..\aaa\bbb`);
		assert (normal(`\\./,/..\aaa/bbb/cc\../...\..\`) == `\\aaa\bbb`);
	} else {
		assert (normal("/aaaa/./bbbb/../ccc../dd/test.d/..") == `/aaaa/ccc../dd`);
		assert (normal(`/./,/../aaa/bbb/cc/../.../../`) == `/aaa/bbb`);
		assert (normal(`../.././,/../aaa/bbb/cc/../.../../`) == `../../aaa/bbb`);
	}
}

/// 絶対パスをbaseからの相対パスに変換する。
/// baseを指定しなかった場合は現在の作業ディレクトリが用いられる。
string abs2rel(string path) {
	return abs2rel(getcwd, path);
}
/// ditto
string abs2rel(string base, string path) {
	base = nabs(base);
	path = nabs(path);
	if (getDrive(base) != getDrive(path)) {
		return path;
	}
	if (fnstartsWith(path, base)) {
		path = path[base.length .. $];
		if (fnstartsWith(path, sep)) path = path[sep.length .. $];
		return path;
	}
	auto basesp = std.string.split(base, sep);
	auto pathsp = std.string.split(path, sep);
	size_t df = 0;
	foreach (i, b; basesp) {
		if (i >= pathsp.length || !fnmatch(b, pathsp[i])) {
			df = i;
			break;
		}
	}
	string[] r;
	for (size_t i = df; i < basesp.length; i++) {
		r ~= pardir;
	}
	if (df < pathsp.length) r ~= pathsp[df .. $];
	return std.string.join(r, sep);
} unittest {
	version (Windows) {
		assert (abs2rel(`c:\windows\system`, `c:\windows\system\test\test.txt`) == `test\test.txt`);
		assert (abs2rel(`c:\windows\system`, `c:\`) == `..\..`);
		assert (abs2rel(`c:\windows\system`, `c:\windows`) == `..`);
		assert (abs2rel(`c:\windows\system`, `c:\winnt`) == `..\..\winnt`);
		assert (abs2rel(`c:\windows\system`, `c:\winnt\system\temp`) == `..\..\winnt\system\temp`);
		assert (abs2rel(`c:\windows\system`, `\\winnt`) == `\\winnt`);
	}
}

/// 素材パスをencodeする。
string encodePath(string path) {
	return isBinImg(path) ? path : replace(path, sep, "/");
}
/// 素材パスをdecodeする。
string decodePath(string path) {
	return isBinImg(path) ? path : replace(path, "/", sep);
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
	assert (lastRet("test\n\n\n") == "test\n");
	assert (lastRet("test") == "test\n");
	assert (lastRet("t\n\nes\nt\n\n") == "t\n\nes\nt\n");
	assert (lastRet("test\n") == "test\n");
}

/// Unicode文字列をすべて小文字にする。
string toLower(string s) {
	dstring r;
	foreach (dchar c; s) {
		r ~= toUniLower(c);
	}
	return toUTF8(r);
}

/// arrをin-placeでソートして返す。
T[] sort(alias Cmp, T)(T[] arr) {
	return sort!(T)(arr, (T a, T b) {return Cmp(a, b) < 0;});
}
/// ditto
T[] sort(T)(T[] arr, bool delegate(T, T) lmin) {
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
	return sort(arr[0u .. l], lmin) ~ sort(arr[l .. $], lmin);
} unittest {
	assert (sort!(int)([8, 1, 4, 6, 5, 3, 2, 9, 7, 0], (int a, int b) {return a < b;})
		== [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
	int[] arr = [5, 2, 3, 4, 6, 7, 9, 1, 0, 8];
	sort!(int)(arr, (int a, int b) {return a > b;});
	assert (arr == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
	assert (sort!(string)(["dd", "Bbb", "Cc", "aa"], (string a, string b) {return icmp(a, b) < 0;})
		== ["aa", "Bbb", "Cc", "dd"]);
}

/// ds内のcのインデックスをクイックサーチする。見つからなかった場合は-1を返す。
int qsearch(T)(in T[] ds, T c) {
	if (ds.length == 1) return ds[0] == c ? 0 : -1;
	int i = ds.length / 2;
	T c2 = ds[i];
	if (c < c2) {
		if (i == 0) return -1;
		return qsearch(ds[0 .. i], c);
	} else if (c > c2) {
		if (i + 1 == ds.length) return -1;
		int i2 = qsearch(ds[i + 1 .. $], c);
		if (i2 == -1) return -1;
		return i + i2 + 1;
	} else {
		return i;
	}
} unittest {
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

/// D2のenforceの代替。
void enforce(lazy bool ok, lazy Exception e) {
	if (!ok) {
		throw e;
	}
}

private template isAssociativeArray(T) {
	const bool isAssociativeArray = is(T.init.keys) && is(T.init.values);
}
private template isDynamicArray(T) {
	const bool isDynamicArray = is(typeof(T.init[0])) && !isStaticArray!(T);
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
	if (std.regexp.find(base, `^-?[1-9][0-9]*$`) >= 0) {
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
	int i = 2;
	string rexp = `\([0-9]+\)$`;
	if (space) rexp = " " ~ rexp;
	int ni = std.regexp.find(base, rexp);
	auto name = base;
	if (ni >= 0) {
		try {
			i = to!(ulong)(base[ni + (space ? 2 : 1) .. $ - 1]) + 1;
			base = base[0 .. ni];
		} catch (Exception e) {
		}
	}
	for (; !use(name); i++) {
		name = base ~ (space ? " (" : "(") ~ .to!(string)(i) ~ ")";
	}
	return name;
} unittest {
	assert (createNewName("aaa", (string n) {return n != "aaa" && n != "aaa (2)";}, true) == "aaa (3)");
	assert (createNewName("aaa", (string n) {return n != "aaa" && n != "aaa(2)";}, false) == "aaa(3)");
	assert (createNewName("aaa (2)", (string n) {return n != "aaa (2)" && n != "aaa (3)";}, true) == "aaa (4)");
	assert (createNewName("aaa(2)", (string n) {return n != "aaa(2)" && n != "aaa(3)";}, false) == "aaa(4)");
}
/// ditto
string createNewFileName(string path, bool isdir) {
	string parent = getDirName(path);
	string name = getBaseName(path);
	string ext = isdir ? "" : getExt(name);
	if (!isdir) name = getName(name);
	name = createNewName(name, (string name) {
		name = std.path.join(parent, name);
		if (!isdir && ext.length) name = addExt(name, ext);
		return !.exists(name);
	}, false);
	name = std.path.join(parent, name);
	if (!isdir && ext.length) name = addExt(name, ext);
	return name;
}

/// 改行文字を\nに置換する。
string encodeLf(string s) {
	s = replace(s, "\\", "\\\\");
	s = replace(s, "\n", "\\n");
	return s;
} unittest {
	assert (encodeLf("\\\\\n\n\\") == "\\\\\\\\\\n\\n\\\\");
}
/// strsを\nを結合子にして結合する。
/// lastLfがtrueの場合は全文字列の末尾にも\nを付与する。
string encodeLf(string[] strs, bool lastLf = true) {
	string r;
	foreach (i, s; strs) {
		r ~= replace(s, "\\", "\\\\");
		if (lastLf || i < strs.length - 1) {
			r ~= "\\n";
		}
	}
	return r;
} unittest {
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
		foreach (i, s; splitlines(decodeLf2(str))) {
			r ~= s;
			if (s.length > 0) last = i + 1;
		}
		r.length = last;
	} else {
		foreach (s; splitlines(decodeLf2(str))) {
			if (s.length > 0) {
				r ~= s;
			}
		}
	}
	return r;
} unittest {
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

/// D 1.0のstd.stringにはstartsWith()とendsWith()が無いので。
/// Params:
/// str = 文字列。
/// word = 検索する文字列。
/// Returns: strがwordで始まっていればtrue。
bool startsWith(T)(T[] str, T[] word) {
	return str.length >= word.length && str[0 .. word.length] == word;
} unittest {
	assert (startsWith("TEXT\r\n", "TEXT\r\n"));
	assert (startsWith("TEXT\r\n", "TEXT"));
	assert (!startsWith("TEXT", "TEXT\r\n"));
}

/// D 1.0のstd.stringにはstartsWith()とendsWith()が無いので。
/// Params:
/// str = 文字列。
/// word = 検索する文字列。
/// Returns: strがwordで終っていればtrue。
bool endsWith(T)(T[] str, T[] word) {
	return str.length >= word.length && str[$ - word.length .. $] == word;
}
/// strからcを探す。
int find(dstring str, dchar c) {
	foreach (i, sc; str) {
		if (sc == c) return i;
	}
	return -1;
}

/// テキストの中で使用されているフラグ・ステップ・画像パスを抽出する。
/// Params:
/// text = テキスト。
/// flags = 使用されているフラグ群。
/// steps = 使用されているステップ群。
/// fonts = 使用されている画像パス群。
void textUseItems(in string text,
		out string[] flags, out string[] steps, out string[] fonts) {
	dstring dtext = toUTF32(text);
	for (size_t i = 0; i + 1 < dtext.length; i++) {
		dchar c = dtext[i];
		void flag_step(ref string[] targ, dchar c) {
			int next = find(dtext[i + 1 .. $], c);
			if (next >= 0) {
				next = i + 1 + next;
				targ ~= toUTF8(dtext[i + 1 .. next]);
				dtext = dtext[next .. $];
				i = 0;
			}
		}
		switch (c) {
		case '#':
			switch (std.ctype.toupper(dtext[i + 1])) {
			case 'M', 'R', 'U', 'C', 'I', 'T', 'Y':
				break;
			default:
				fonts ~= toUTF8("font_"d ~ dtext[i + 1] ~ ".bmp"d);
				break;
			}
			i++;
			break;
		case '%':
			flag_step(flags, '%');
			break;
		case '$':
			flag_step(steps, '$');
			break;
		default:
			break;
		}
	}
} unittest {
	string[] flags, steps, fonts;
	textUseItems("#M#R#U#C#I#T#Yaaa$test$$あああ\t2$$#tes%t3$%tes#t%#a#Z#1#2#33d$dd%aaa%%#%#;%vv%#表%#", flags, steps, fonts);
	assert(flags == ["tes#t", "aaa", "#", "vv"]);
	assert(steps == ["test", "あああ\t2", "#tes%t3"]);
	assert(fonts == ["font_a.bmp", "font_Z.bmp", "font_1.bmp", "font_2.bmp", "font_3.bmp", "font_;.bmp", "font_表.bmp"]);
}
private void __replOn(ref dstring dtext, ref dstring buf, ref size_t i, dstring dold, dstring dnew, dchar targC) {
	int next = find(dtext[i + 1 .. $], targC);
	if (next >= 0) {
		next = i + 1 + next;
		if (dtext[i + 1 .. next] == dold) {
			buf ~= [targC] ~ dnew ~ [targC];
		} else {
			buf ~= dtext[i .. next + 1];
		}
		if (next < dtext.length) {
			dtext = dtext[next .. $];
			i = 0;
		}
	} else {
		buf ~= dtext[i];
	}
}
private void __replOff(ref dstring dtext, ref dstring buf, ref size_t i, dchar targC) {
	int next = find(dtext[i + 1 .. $], targC);
	if (next >= 0) {
		next = i + 1 + next;
		buf ~= [targC] ~ dtext[i + 1 .. next] ~ [targC];
		if (next < dtext.length) {
			dtext = dtext[next .. $];
			i = 0;
		}
	} else {
		buf ~= dtext[i];
	}
}
private string __replTextFlagStep(char Ch1, char Ch2)
		(string text, string oldFlag, string newFlag) {
	dstring dtext = toUTF32(text);
	dstring dold = toUTF32(oldFlag);
	dstring dnew = toUTF32(newFlag);
	dstring buf;
	for (size_t i; i < dtext.length; i++) {
		dchar c = dtext[i];
		switch (c) {
		case '#':
			buf ~= c;
			if (i + 1 < dtext.length) {
				buf ~= dtext[i + 1];
				i++;
			}
			break;
		case Ch1:
			__replOn(dtext, buf, i, dold, dnew, Ch1);
			break;
		case Ch2:
			__replOff(dtext, buf, i, Ch2);
			break;
		default:
			buf ~= c;
			break;
		}
	}
	return toUTF8(buf);
}
/// テキストの中で使用されているフラグのパスを置換する。
/// Params:
/// text = テキスト。
/// oldFlag = 置換前のフラグパス。
/// newFlag = 置換後のフラグパス。
string replTextUseFlag(string text, string oldFlag, string newFlag) {
	return __replTextFlagStep!('%', '$')(text, oldFlag, newFlag);
} unittest {
	assert(replTextUseFlag("aaa%aaa%$%置換前%$%置換前%a#%置換前%%aa$%置換前%", "置換前", "置換no後")
		== "aaa%aaa%$%置換前%$%置換no後%a#%置換前%%aa$%置換no後%");
}
/// テキストの中で使用されているステップのパスを置換する。
/// Params:
/// text = テキスト。
/// oldStep = 置換前のステップパス。
/// newStep = 置換後のステップパス。
string replTextUseStep(string text, string oldStep, string newStep) {
	return __replTextFlagStep!('$', '%')(text, oldStep, newStep);
} unittest {
	assert(replTextUseStep("aaa$aaa$%$置換前$%$置換前$a#$置換前$$aa%$置換前$", "置換前", "置換no後")
		== "aaa$aaa$%$置換前$%$置換no後$a#$置換前$$aa%$置換no後$");
}
/// テキストの中で使用されている画像のパスを置換する。
/// Params:
/// text = テキスト。
/// oldFont = 置換前の画像パス。
/// newFont = 置換後の画像パス。
string replTextUseFont(string text, string oldFont, string newFont)
in {
	dstring dold = toUTF32(toLower(oldFont));
	dstring dnew = toUTF32(toLower(newFont));
	assert(dold.length == 10);
	assert(startsWith(dold, "font_"d));
	assert(endsWith(dold, ".bmp"d));
	assert(dnew.length == 10);
	assert(startsWith(dnew, "font_"d));
	assert(endsWith(dnew, ".bmp"d));
} body {
	dstring dtext = toUTF32(text);
	dchar dold = toUTF32(oldFont)[5];
	dchar dnew = toUTF32(newFont)[5];
	dstring buf;
	for (size_t i; i < dtext.length; i++) {
		dchar c = dtext[i];
		switch (c) {
		case '#':
			buf ~= c;
			if (i + 1 < dtext.length) {
				if (toLower([dtext[i + 1]]) == toLower([dold])) {
					buf ~= dnew;
				} else {
					buf ~= dtext[i + 1];
				}
				i++;
			}
			break;
		case '%':
			__replOff(dtext, buf, i, '%');
			break;
		case '$':
			__replOff(dtext, buf, i, '$');
			break;
		default:
			buf ~= c;
			break;
		}
	}
	return toUTF8(buf);
} unittest {
	assert(replTextUseFont("#a#置$#置$#b%#置%#置", "font_置.bmp", "Font_換.bmp")
		== "#a#換$#置$#b%#置%#換");
	assert(replTextUseFont("#a#c$#c$#b%#C%#C", "fonT_c.bmp", "font_F.Bmp")
		== "#a#F$#c$#b%#C%#F");
}
/// textのstart .. end範囲内の色をcolorにする。
/// %%・$$区間は通常のテキストとして扱う。
dstring putColor(dstring text, dchar color, size_t start, size_t end) {
	if (start == end) {
		return text[0u .. start] ~ cast(dchar) '&' ~ color ~ text[end .. $];
	}
	dchar defColor = 'W';
	l: foreach_reverse (i, dchar c; text[1u .. start]) {
		switch (c) {
		case 'W', 'R', 'B', 'G', 'Y':
			if (text[i] == '&') {
				defColor = c;
				break l;
			}
			break;
		default:
		}
	}
	if (defColor == color) return text;
	return text[0u .. start] ~ cast(dchar) '&' ~ color
		~ text[start .. end] ~ cast(dchar) '&' ~ defColor ~ text[end .. $];
} unittest {
	assert (putColor("テストテスト"d, 'R', 1, 4) == "テ&Rストテ&Wスト"d);
	assert (putColor("テストテスト"d, 'B', 2, 5) == "テス&Bトテス&Wト"d);
	assert (putColor("&Rテストテスト"d, 'Y', 4, 7) == "&Rテス&Yトテス&Rト"d);
	assert (putColor("テストテスト"d, 'B', 2, 2) == "テス&Bトテスト"d);
}

/// 連想配列をクリアする。
void removeAll(Key, Value)(ref Value[Key] table) {
	table = typeof(table).init;
}

/// Tがソート済みであればtrueを返す。
bool isSorted(T)(in T[] arr) {
	return isSorted!(T)(arr, (in T a, in T b) {return a < b;});
}
/// ditto
bool isSorted(T)(in T[] arr, bool delegate(in T, in T) cmp) {
	foreach (i, v; arr) {
		if (arr.length <= i + 1) break;
		if (!cmp(v, arr[i + 1])) {
			return false;
		}
	}
	return true;
} unittest {
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
	string r = v[0u .. strlen(v)].dup;
	version (Windows) {
		r = touni(r);
	}
	return r;
}

private string __createF(bool Dir)(string parent, string name, string ext, string prefix) {
	string clean(string name) {
		name = replace(name, sep, "");
		static if (altsep.length) {
			name = replace(name, altsep, "");
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
		if (ext.length) r = addExt(r, ext);
		r = std.path.join(parent, r);
		r = createNewFileName(r, Dir);
		static if (Dir) {
			mkdir(r);
			rmdir(r);
		} else {
			std.file.write(r, []);
			std.file.remove(r);
		}
	}
	name = clean(name);
	try {
		create;
	} catch (Exception e) {
		name = toHex(name);
		create;
	}
	return r;
}
/// 存在しないファイル名を生成して返す。
/// 指定されたファイル名がすでに存在する場合、"test(2).txt"のように
/// 括弧つき数字をつける。
/// それでも存在する場合、括弧内の数値をインクリメントしてゆく。
string createFileI(string parent, string name, string ext, string prefix) {
	return __createF!(false)(parent, name, ext, prefix);
}
/// ditto
string createFolder(string parent, string name) {
	return __createF!(true)(parent, name, "", "");
}

/// ファイル削除の準備を行う。
void preRemove(string delpath) {
	version (Windows) {
		// 書込み権限を付けておく
		wchar* fname = std.utf.toUTF16z(delpath);
		SetFileAttributesW(fname, FILE_ATTRIBUTE_NORMAL);
	}
}

/// ファイルをコピーする。ファイル名が重複する場合は、(2)、(3)、
/// ……のように括弧付き番号が付与される。
/// Params:
/// sPath = シナリオのパス。
/// path = コピー元のファイル。
/// added = シナリオ内のどのフォルダにコピーするか。
/// Returns: コピー後のファイルパス。
string copyTo(string sPath, string path, string added) {
	bool binImg = isBinImg(path);
	auto mtDir = std.path.join(sPath, added);
	if (!exists(mtDir)) mkdirRecurse(mtDir);
	string to;
	if (binImg) {
		to = std.path.join(mtDir, "@simage(1).bmp");
	} else {
		to = std.path.join(mtDir, getBaseName(path));
	}
	to = createNewFileName(to, false);
	if (binImg) {
		std.file.write(to, strToBImg(path));
	} else {
		copy(path, to);
	}
	return std.path.join(added, getBaseName(to));
}

/// aからbへすべてのファイル・ディレクトリをコピーする。
void copyAll(string a, string b) in {
	assert (isdir(a));
	assert (isdir(b));
} body {
	foreach (file; clistdir(a)) {
		string fPath = std.path.join(a, file);
		string tPath = std.path.join(b, file);
		if (isdir(fPath)) {
			mkdir(tPath);
			copyAll(fPath, tPath);
		} else {
			std.file.copy(fPath, tPath);
		}
	}
}

/// delpath以降の全てのファイル・ディレクトリを削除する。
/// Params:
/// force = trueを指定した場合、途中でエラーが発生しても中断しない。
void delAll(string delpath, bool force = true) {
	if (!.exists(delpath)) return;
	void __delAll(string delpath, ref Exception ee) {
		try {
			preRemove(delpath);
			if (isdir(delpath)) {
				foreach (file; clistdir(delpath)) {
					__delAll(std.path.join(delpath, file), ee);
				}
				rmdir(delpath);
			} else {
				std.file.remove(delpath);
			}
		} catch (FileException e) {
			if (!force) throw e;
			if (!ee) ee = new FileException(e.msg);
		}
	}
	Exception e = null;
	__delAll(delpath, e);
	if (force && e) throw e;
}

/// 再帰的にディレクトリを作成
void mkdirRecurse(string path) {
	path = nabs(path);
	string dir = getDirName(path);
	if (!exists(dir)) mkdirRecurse(dir);
	mkdir(path);
}

/// arrにaが見つかればtrueを返す。
bool contains(string pred = "a == b", T)(T[] arr, T a) {
	foreach (b; arr) {
		if (mixin(pred)) return true;
	}
	return false;
}

static if (fnmatch("A", "a")) {
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
		for (size_t k = i; k < a.length && isdigit(a[k]); k++) {
			buf1 ~= a[k];
		}
		C2[] buf2;
		for (size_t k = j; k < b.length && isdigit(b[k]); k++) {
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
	assert (ncmp("42", "2") > 0);
	assert (ncmp("02", "2") < 0);
	assert (ncmp("abc42", "abc4") > 0);
	assert (ncmp("abc4a", "abc4b") < 0);
	assert (ncmp("abc", "def") < 0);
}

private C[] zfill_(C)(in C[] str, size_t width) {
	if (str.length >= width) return cast(C[]) str.dup;
	C[] r;
	r.length = width;
	size_t n = width - str.length;
	r[0 .. n] = '0';
	r[n .. $] = str;
	return cast(C[]) r;
} unittest {
	assert (zfill_("abc", 2) == "abc");
	assert (zfill_("abc", 3) == "abc");
	assert (zfill_("abc", 4) == "0abc");
	assert (zfill_("abc", 5) == "00abc");
	assert (zfill_("abc"w, 5) == "00abc"w);
	assert (zfill_("abc"d, 5) == "00abc"d);
}

/// arrからaを探して見つかればそのindex。見つからなかった場合は-1。
int indexOf(string pred = "a == b", T)(T[] arr, T a) {
	foreach (i, b; arr) {
		if (mixin(pred)) return i;
	}
	return -1;
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
	void add(T v) {
		a[v] = 0;
	}
	void remove(T v) {
		a.remove(v);
	}
	void clear() {
		a = (int[T]).init;
	}
	bool contains(T v) {
		return (v in a) !is null;
	}
	size_t size() {
		return a.length;
	}
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
		r = CreateProcessW(null, toUTF16z(process), null, null, false, flag, null,
			workDir.length ? toUTF16z(workDir) : null, &setup, &info);
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
		int fork();
	}
	import std.c.stdlib;
	import std.process;
	/// プロセスを起動する。成功した場合はtrueを返す。
	/// FIXME: まったくテストしていない
	bool exec(string process, string workDir = "", bool console = true, bool wait = false) {
		auto pid = fork;
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
		}
	}
}

/// pathがsPath以下に存在するものであればtrueを返す。
bool hasPath(string sPath, string path) {
	path = nabs(path);
	sPath = nabs(sPath);
	return cwx.utils.fnstartsWith(path, sPath)
		&& (path.length == sPath.length || cwx.utils.startsWith(path[sPath.length .. $], sep));
} unittest {
	version (Windows) {
		assert (hasPath(`c:\test\aaa`, `c:\test\aaa\bbb`));
		assert (!hasPath(`c:\test\aaa`, `c:\test\aaaaaa`));
		assert (hasPath(`c:\test\aaa`, `c:\test\aaa`));
	}
}

private struct FCPt {
	string path;
	hash_t toHash() {
		hash_t r = 0;
		foreach (char c; std.path.getBaseName(path)) {
			r *= 31;
			r += c;
		}
		return r;
	}
	int opEquals(FCPt* s) {
		int r = fnmatch(getBaseName(s.path), getBaseName(path));
		if (r) {
			r = fnmatch(getDirName(s.path), getDirName(path));
		}
		return r;
	}
	int opCmp(FCPt* s) {
		static if (fnmatch("A", "a")) {
			alias std.string.icmp cp;
		} else {
			alias std.string.cmp cp;
		}
		int r = cp(getBaseName(s.path), getBaseName(path));
		if (r == 0) {
			r = cp(getDirName(s.path), getDirName(path));
		}
		return r;
	}
}
/// ファイルパスから取得する何らかのデータをキャッシュするための
/// 一連の変数と関数を定義する。
template FileCache(T ...) {
	struct Cache {
		std.date.d_time ftm;
		static if (T.length == 1) {
			T[0] value;
		} else {
			T values;
		}
	}
	static const CACHE_MAX = 1024;
	static Cache[FCPt] caches;
	static string[] cachePaths;
	void putCache(string path, T v) {
		if (!exists(path)) return;
		path = nabs(path);
		if (cachePaths.length >= CACHE_MAX) {
			caches.remove(FCPt(cachePaths[0u]));
			cachePaths = cachePaths[1u .. $];
		}
		caches[FCPt(path)] = Cache(lastModified(path), v);
		cachePaths ~= path;
	}
	Cache* cache(string path) {
		if (!exists(path)) return null;
		path = nabs(path);
		auto cache = FCPt(path) in caches;
		return cache && cache.ftm == lastModified(path) ? cache : null;
	}
}

/// 親ディレクトリへの移動が含まれているパスであればtrueを返す。
bool hasParDir(string path) {
	path = normal(path);
	if (startsWith(path, pardir ~ sep)) return true;
	if (std.string.find(path, sep ~ pardir ~ sep) != -1) return true;
	return false;
}

version (Windows) {
	private extern (Windows) {
		BOOL GetFileTime(HANDLE hFile, LPFILETIME lpCreationTime, LPFILETIME lpLastAccessTime, LPFILETIME lpLastWriteTime);
	}
	/// ファイルの最終更新日時を返す。
	d_time lastModified(string path) {
		d_time conv(ref FILETIME ft) {
			SYSTEMTIME st;
			if (!FileTimeToSystemTime(&ft, &st)) {
				throw new FileException(path, GetLastError);
			}
			auto time = MakeTime(st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
			auto day = MakeDay(st.wYear, st.wMonth - 1, st.wDay);
			return MakeDate(day, time);
		}
		WIN32_FIND_DATAW fd;
		auto h = FindFirstFileW(std.utf.toUTF16z(path), &fd);
		if (h != INVALID_HANDLE_VALUE) {
			scope (exit) FindClose(h);
			return conv(fd.ftLastWriteTime);
		}
		throw new FileException(path, GetLastError);
	}
	/// listdir()にはパフォーマンス問題がある。
	string[] clistdir(string path) {
		string[] r;
		clistdir(path, (string file) {
			r ~= file;
			return true;
		});
		return r;
	}
	/// ditto
	void clistdir(string path, bool delegate(string) callback) {
		if (!.exists(path) || !.isdir(path)) return;
		path = std.path.join(path, "*");
		WIN32_FIND_DATAW fd;
		auto h = FindFirstFileW(std.utf.toUTF16z(path), &fd);
		if (h != INVALID_HANDLE_VALUE) {
			scope (exit) FindClose(h);
			do {
				string file = toUTF8(fd.cFileName[0 .. wcslen(fd.cFileName.ptr)]);
				if (file != curdir && file != pardir) {
					if (!callback(file)) break;
				}
			} while (FindNextFileW(h, &fd));
		} else {
			throw new FileException(path, GetLastError);
		}
	}
} else {
	/// ファイルの最終更新日時を返す。
	d_time lastModified(string path) {
		d_time ftc, fta, ftm;
		getTimes(path, ftc, fta, ftm);
		return ftm;
	}
	alias listdir clistdir;
}

/// sにsubがいくつ含まれているかを返す。
/// std.string.count()と違って大文字と小文字を区別しない。
size_t icount(string s, string sub) {
	int c = 0;
	while (true) {
		auto i = ifind(s, sub);
		if (i < 0) return c;
		c++;
		s = s[i + sub.length .. $];
	}
} unittest {
	assert (icount("test", "Es") == 1);
	assert (icount("aaaaaaa", "AA") == 3);
}

/// sに含まれるfromをtoに置換した結果を返す。
/// std.string.replace()と違って大文字と小文字を区別しない。
string ireplace(string s, string from, string to) {
	string r = "";
	while (true) {
		auto i = ifind(s, from);
		if (i < 0) return r ~ s;
		r ~= s[0 .. i] ~ to;
		s = s[i + from.length .. $];
	}
} unittest {
	assert (ireplace("test", "Es", "TT") == "tTTt");
	assert (ireplace("aaaaaaa", "AA", "BB") == "BBBBBBa");
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
					return std.ctype.tolower(chr) == std.ctype.tolower(c);
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
	private int find(dstring s, bool next, out size_t len) {
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

	assert (Wildcard("*").count("test") == 1);
	assert (Wildcard("te?t").count("testtestest") == 2);

	assert (Wildcard("t*s").replace("test", "A") == "At");
	assert (Wildcard("???t").replace("testtestest", "BB") == "BBBBest");
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
	assert (formatNum(123) == "123");
	assert (formatNum(123456) == "123,456");
	assert (formatNum(1234567) == "1,234,567");
}

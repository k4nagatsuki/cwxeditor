#!/usr/bin/rdmd
/// ビルドスクリプト。
module build;

immutable NAME = "cwxeditor";
immutable string[] CRITICAL = [
	"d2std" ~ dirSeparator ~ "xml.d",
	"d2std" ~ dirSeparator ~ "zip.d",
	"d2std" ~ dirSeparator ~ "zlib.d",
];
immutable string[] RES_DIR = [
	".",
	"." ~ dirSeparator ~ "resource",
];
immutable string[] IGNORE_DIR = [
	"private",
];

import std.algorithm;
import std.file;
import std.path;
import std.process;
import std.exception;
import std.array;
import std.string : splitLines;
import std.stdio : writeln, writefln;
import std.datetime;
import std.container;

version (Windows) {
	immutable RCC = "rcc";
	immutable RCEXE = "rc";
	immutable RC = NAME.setExtension("rc");
	immutable RES = NAME.setExtension("res");
	immutable EXE = NAME.setExtension("exe");
	immutable LIB_64 = [
		"advapi32.lib",
		"comctl32.lib",
		"comdlg32.lib",
		"gdi32.lib",
		"kernel32.lib",
		"shell32.lib",
		"ole32.lib",
		"oleaut32.lib",
		"oleacc.lib",
		"user32.lib",
		"usp10.lib",
		"msimg32.lib",
		"opengl32.lib",
		"shlwapi.lib",
		"dwt-base.lib",
		"org.eclipse.swt.win32.win32.x86.lib",
	];
	immutable LIB_32 = LIB_64 ~ "olepro32.lib";
	immutable DEBUG_FLAGS = [
		"-g",
		"-debug",
		"-unittest",
	];
	immutable string[] DEBUG_FLAGS_L_32 = [
//		"-g",
		"-debug",
		"-unittest",
	];
	immutable string[] DEBUG_FLAGS_L_64 = [
		"-g",
		"-debug",
		"-unittest",
	];
	immutable CONSOLE_FLAGS_L_32 = [
		"-L/rc:" ~ NAME,
		"-L/NOM",
		"-of" ~ EXE,
		"-L/exet:nt/su:console:4.0",
	];
	immutable CONSOLE_FLAGS_L_64 = [
		"-L" ~ NAME ~ ".res",
		"-of" ~ EXE,
		"-L/SUBSYSTEM:CONSOLE",
	];
	immutable string[] WINDOW_FLAGS_L_32 = [
		"-L/rc:" ~ NAME,
		"-L/NOM",
		"-of" ~ EXE,
		"-L/exet:nt/su:windows:4.0",
	];
	immutable string[] WINDOW_FLAGS_L_64 = [
		"-L" ~ NAME ~ ".res",
		"-of" ~ EXE,
		"-L/SUBSYSTEM:Windows",
		"-L/ENTRY:mainCRTStartup",
	];
	immutable O = "obj";
} else {
	immutable EXE = NAME;
	immutable LIB = [
		"-Lorg.eclipse.swt.gtk.linux.x86.a",
		"-Ldwt-base.a",
		"-L-lgnomeui-2",
		"-L-lcairo",
		"-L-lglib-2.0",
		"-L-ldl",
		"-L-lgmodule-2.0",
		"-L-lgobject-2.0",
		"-L-lpango-1.0",
		"-L-lXfixes",
		"-L-lX11",
		"-L-lXdamage",
		"-L-lXcomposite",
		"-L-lXcursor",
		"-L-lXrandr",
		"-L-lXi",
		"-L-lXinerama",
		"-L-lXrender",
		"-L-lXext",
		"-L-lXtst",
		"-L-lfontconfig",
		"-L-lpangocairo-1.0",
		"-L-lgthread-2.0",
		"-L-lgdk_pixbuf-2.0",
		"-L-latk-1.0",
		"-L-lgdk-x11-2.0",
		"-L-lgtk-x11-2.0",
		"-L-lgnomevfs-2",
	];
	immutable DEBUG_FLAGS = [
		"-g",
		"-debug",
		"-unittest",
	];
	immutable string[] DEBUG_FLAGS_L = [
		"-g",
		"-debug",
		"-unittest",
	];
	immutable CONSOLE_FLAGS_L = [
		"-of" ~ EXE,
	];
	immutable string[] WINDOW_FLAGS_L = [
		"-of" ~ EXE,
	];
	immutable O = "o";
}

immutable FLAGS = [
	"-op",
	// BUG: dmd 2.067.0 occurs compile error.
//	"-property",
	"-c",
];
immutable CRITICAL_FLAGS = [
	"-c",
	"-release",
	"-O",
	"-inline",
	"-op",
];
immutable RELEASE_FLAGS = [
	"-release",
];

immutable CONSOLE_FLAGS = [
	"-version=Console",
];
immutable string[] WINDOW_FLAGS = [
];
immutable string[] RELEASE_FLAGS_L = [
	"-release",
	"-O",
];

immutable DMD = "dmd";

/// コマンドを実行。
void exec(string[] cmd ...) {
	string line = cmd.join(" ");
	writeln(line);
	auto timer = StopWatch(AutoStart.yes);
	enforce(0 == spawnShell(line).wait(), new Exception(line));
	timer.stop();
	writefln("%d msecs", timer.peek().msecs);
}
/// ファイル名が一致するか。
bool equalsFilename(string a, string b) {
	return 0 == a.filenameCmp(b);
}
/// コンパイル対象の情報を格納する。
string[] put(string file, ref string[string] objs, in string[] qual) {
	foreach (ignore; IGNORE_DIR) {
		if (file.startsWith(ignore)) {
			return [];
		}
	}
	string obj = "objs".buildPath(file).setExtension(O);
	objs[file] = obj;
	string[] array;
	if (qual.length) {
		if (!qual.find!equalsFilename(file.baseName()).empty) {
			array ~= file;
		}
	} else {
		if (file.newer(obj)) {
			array ~= file;
		}
	}
	return array;
}
/// argsにflagが含まれているか(大文字・小文字を区別しない)。
bool has(in string[] args, string flag) {
	return !find!("0 == icmp(a, b)")(args, flag).empty;
}
/// pathがtargより新しいか。
bool newer(string path, string targ) {
	return !targ.exists() || path.timeLastModified() > targ.timeLastModified();
}
/// pathを削除する。
void removeFile(string path) {
	if (!path.exists()) return;
	if (path.isDir()) {
		path.rmdirRecurse();
	} else {
		path.remove();
	}
	writefln("removed: %s", path);
}
/// argsの内容を分類する。
void divide(in string[] args, out string[] file, out string[] option, out string[] dmdOption) {
	foreach (a; args) {
		if (0 == a.extension().filenameCmp(".d")) {
			file ~= a;
		} else if (a.startsWith("-")) {
			dmdOption ~= a;
		} else {
			option ~= a;
		}
	}
}

void main(string[] args) {
	auto timer = StopWatch(AutoStart.yes);

	// ビルドフラグ
	string[] test, option, dmdOption;
	divide(args[1 .. $], test, option, dmdOption);
	test = test.sort;
	option = option.sort;
	bool help = option.has("help");
	bool release = option.has("release");
	bool console = option.has("cui");
	bool window = (release && !console) || option.has("gui");
	bool clean = option.has("clean");
	bool run = option.has("run");
	bool m64 = dmdOption.has("-m64") || dmdOption.has("-m32mscoff");

	if (help) {
		writeln("Usage: rdmd build [help | clean | cui | gui | release | run | *.d]");
		return;
	}

	// 前回のフラグと比較・保存
	bool mod = false;
	if (!test.length) {
		auto option2 = option.dup;
		option2 = std.algorithm.remove!(a => a == "clean")(option2);
		option2 = std.algorithm.remove!(a => a == "run")(option2);
		mod = "build.log".exists() && option2 != "build.log".readText().splitLines();
		"build.log".write(option2.join("\n"));
	}

	if (clean || mod) {
		// クリーン
		EXE.removeFile();
		version (Windows) {
			RES.removeFile();
		}
		"objs".removeFile();
		"build.d.deps".removeFile();
		"build.log".removeFile();
		if (clean && 1 == test.length + option.length) return;
	}

	// ソースコードとオブジェクトファイルのリスト
	string[string] objs; // コンパイル対象と生成されるオブジェクトファイルのテーブル
	string[][string] files; // コンパイル対象(ディレクトリ毎)
	string[] critical; // 速度優先でコンパイルされるべきファイル
	string[] res; // リソースのディレクトリ
	foreach (string file; ".".dirEntries(SpanMode.depth)) {
		if (file.isDir()) continue;
		if (!file.extension().equalsFilename(".d")) continue;
		file = file.buildNormalizedPath();
		if (file.equalsFilename(__FILE__)) continue;
		if (-1 != CRITICAL.countUntil!equalsFilename(file)) {
			critical ~= put(file, objs, test);
			continue;
		}
		files[file.dirName] ~= put(file, objs, test);
	}
	foreach (resDir; RES_DIR) {
		res ~= "-J" ~ resDir;
	}

	string[] cmd;

	version (Windows) {
		// リソースファイル
		if (RC.length && RC.newer(RES)) {
			if (m64) {
				cmd = [RCEXE];
			} else {
				cmd = [RCC];
			}
			exec(cmd ~ RC);
		}
	}

	cmd = [DMD];

	// *.dのコンパイル
	string[] flags = FLAGS.dup;
	flags ~= release ? RELEASE_FLAGS : DEBUG_FLAGS;
	flags ~= window ? WINDOW_FLAGS : CONSOLE_FLAGS;
	if (critical.length) {
		exec(cmd ~ CRITICAL_FLAGS ~ res ~ critical ~ "-odobjs" ~ dmdOption);
	}
	foreach (dir, array; files) {
		if (!array.length) continue;
		exec(cmd ~ flags ~ array ~ res ~ "-odobjs" ~ dmdOption);
	}

	// ファイルが指定されている場合はコンパイルテストなのでここで終了
	if (test.length) {
		foreach (f; critical ~ files.values.join()) {
			auto obj = objs[f];
			writefln("%s: %s KB", obj, obj.getSize() / 1024);
		}
		timer.stop();
		writefln("Compiled: %d msecs", timer.peek().msecs);
		return;
	}

	// リンク
	version (Windows) {
		if (m64) {
			flags = LIB_64.map!((a) => "-L" ~ a)().array();
			flags ~= release ? RELEASE_FLAGS_L : DEBUG_FLAGS_L_64;
			flags ~= window ? WINDOW_FLAGS_L_64 : CONSOLE_FLAGS_L_64;
		} else {
			flags = LIB_32.map!((a) => "-L+" ~ a)().array();
			flags ~= release ? RELEASE_FLAGS_L : DEBUG_FLAGS_L_32;
			flags ~= window ? WINDOW_FLAGS_L_32 : CONSOLE_FLAGS_L_32;
		}
	} else {
		flags = LIB.map!((a) => "-L+" ~ a)();
		flags ~= release ? RELEASE_FLAGS_L : DEBUG_FLAGS_L;
		flags ~= window ? WINDOW_FLAGS_L : CONSOLE_FLAGS_L;
	}

	exec(cmd ~ flags ~ objs.values ~ dmdOption);

	timer.stop();
	writefln("Compiled: %d msecs", timer.peek().msecs);

	// 不要なファイルを削除
	version (Windows) {
		if (m64 && release) {
			foreach (ext; [".exp", ".ilk", ".lib", ".pdb"]) {
				auto path = EXE.setExtension(ext);
				if (path.exists()) path.remove();
			}
		}
	}

	if (run) {
		exec(".".buildPath(EXE));
	}
}

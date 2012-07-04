/// CWXEditorのビルドスクリプト。
module build;

import std.algorithm;
import std.file;
import std.path : filenameCmp, extension, setExtension, buildPath;
import std.process;
import std.exception;
import std.array;
import std.string : splitLines;
import std.stdio : writeln, writefln;
import std.datetime;

immutable DMD = "dmd";

version (Windows) {
	immutable RCC = "rcc";
	immutable RC = "cwxeditor.rc";
	immutable RES = "cwxeditor.res";
	immutable EXE = "cwxeditor.exe";
	immutable LIB = [
		"-L/rc:cwxeditor",
		"-L/NOM",
		"-L+advapi32.lib",
		"-L+comctl32.lib",
		"-L+comdlg32.lib",
		"-L+gdi32.lib",
		"-L+kernel32.lib",
		"-L+shell32.lib",
		"-L+ole32.lib",
		"-L+oleaut32.lib",
		"-L+olepro32.lib",
		"-L+oleacc.lib",
		"-L+user32.lib",
		"-L+usp10.lib",
		"-L+msimg32.lib",
		"-L+opengl32.lib",
		"-L+shlwapi.lib",
		"-L+dwt-base.lib",
		"-L+org.eclipse.swt.win32.win32.x86.lib",
	];
	immutable CONSOLE_FLAGS_L = [
		"-of" ~ EXE,
		"-L/exet:nt/su:console:4.0",
	];
	immutable string[] WINDOW_FLAGS_L = [
		"-of" ~ EXE,
		"-L/exet:nt/su:windows:4.0",
	];
	immutable O = "obj";
} else {
	immutable EXE = "cwxeditor";
	immutable LIB = [
		"org.eclipse.swt.gtk.linux.x86.a",
		"dwt-base.a",
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
	"-J.",
	"-Jresource",
	"-op",
	"-property",
	"-c",
];
immutable D2STD_FLAGS = [
	"-c",
	"-release",
	"-O",
	"-inline",
	"-op",
];
immutable DEBUG_FLAGS = [
	"-gs",
	"-debug",
	"-unittest",
];
immutable RELEASE_FLAGS = [
	"-release",
];

immutable CONSOLE_FLAGS = [
	"-version=Console",
];
immutable string[] WINDOW_FLAGS = [
];
immutable string[] DEBUG_FLAGS_L = [
	"-gs",
	"-debug",
	"-unittest",
];
immutable string[] RELEASE_FLAGS_L = [
	"-release",
	"-O",
];

void exec(string[] cmd) {
	string line = cmd.join(" ");
	writeln(line);
	auto timer = StopWatch(AutoStart.yes);
	enforce(0 == system(line), new Exception(line));
	timer.stop();
	writefln("%d msecs", timer.peek().msecs);
}
void put(string file, ref string[] array, ref string[string] objs) {
	string obj = "objs".buildPath(file).setExtension(O);
	if (file.newer(obj)) {
		array ~= file;
	}
	objs[file] = obj;
}
string[] sources(string path, bool shallow, ref string[string] objs) {
	string[] arr;
	foreach (string file; path.dirEntries(shallow ? SpanMode.shallow : SpanMode.depth)) {
		if (0 == filenameCmp(file.extension(), ".d")) {
			put(file, arr, objs);
		}
	}
	return arr;
}
bool has(in string[] args, string flag) {
	return !find!("0 == icmp(a, b)")(args, flag).empty;
}
bool newer(string path, string targ) {
	return !targ.exists() || path.timeLastModified() > targ.timeLastModified();
}
void removeFile(string path) {
	if (!path.exists()) return;
	if (path.isDir()) {
		path.rmdirRecurse();
	} else {
		path.remove();
	}
	writefln("removed: %s", path);
}

void main(string[] args) {
	// ビルドフラグ
	args = args.sort;
	bool release = args.has("release");
	bool window = release || args.has("gui");
	bool clean = args.has("clean");

	// 前回のフラグと比較・保存
	bool mod = "build.log".exists() && args[1 .. $] != "build.log".readText().splitLines();
	"build.log".write(args[1 .. $].join("\n"));

	if (clean || mod) {
		// クリーン
		EXE.removeFile();
		RES.removeFile();
		"objs".removeFile();
		if (clean) return;
	}

	// ソースコードとオブジェクトファイルのリスト
	string[string] objs;
	string[] cwx = sources("cwx", true, objs);
	string[] editor = sources("cwx".buildPath("editor"), false, objs);
	string[] d2std = sources("d2std", false, objs);
	put("cwxeditor.d", editor, objs);

	string[] cmd;

	version (Windows) {
		// リソースファイル
		if (RC.newer(RES)) {
			cmd = [RCC];
			exec(cmd ~ RC);
		}
	}

	cmd = [DMD];

	// *.dのコンパイル
	string[] flags = FLAGS.dup;
	flags ~= release ? RELEASE_FLAGS : DEBUG_FLAGS;
	flags ~= window ? WINDOW_FLAGS : CONSOLE_FLAGS;
	if (d2std.length) exec(cmd ~ D2STD_FLAGS ~ d2std ~ "-odobjs");
	if (cwx.length) exec(cmd ~ flags ~ cwx ~ "-odobjs");
	if (editor.length) exec(cmd ~ flags ~ editor ~ "-odobjs");

	// リンク
	flags = LIB.dup;
	flags ~= release ? RELEASE_FLAGS_L : DEBUG_FLAGS_L;
	flags ~= window ? WINDOW_FLAGS_L : CONSOLE_FLAGS_L;
	exec(cmd ~ flags ~ objs.values);
}

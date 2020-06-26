#!/usr/bin/rdmd
/// ビルドスクリプト。
module build;

immutable NAME = "cwxeditor";
immutable string[] CRITICAL = [
	"d2std" ~ dirSeparator ~ "xml.d",
	"d2std" ~ dirSeparator ~ "zip.d",
	"d2std" ~ dirSeparator ~ "zlib.d",
];
immutable string[] NO_DEBUG_SYMBOLS = [
	"cwx" ~ dirSeparator ~ "msgs.d",
];
immutable string[] RES_DIR = [
	".",
	"." ~ dirSeparator ~ "resource",
];
immutable string[] IGNORE_DIR = [
	"private",
];
immutable string[] IGNORE_FILE = [
	"build.d",
	"createrc.d",
];

import std.algorithm;
import std.array;
import std.container;
import std.datetime.stopwatch;
import std.datetime;
import std.exception;
import std.file;
import std.path;
import std.process;
import std.stdio : writeln, writefln;
import std.string : splitLines;

version (Windows) {
	immutable RCC = "rcc -32";
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
		"dwt_base.lib",
		"dwt.lib",
		"dxml.lib"
	];
	immutable LIB_32 = LIB_64 ~ "olepro32.lib";
	immutable DEBUG_FLAGS = [
		"-g",
		"-debug",
/+		"-unittest",
+/	];
	immutable string[] DEBUG_FLAGS_L_32 = [
/+		"-g",
+/		"-debug",
/+		"-unittest",
+/	];
	immutable string[] DEBUG_FLAGS_L_64 = [
		"-g",
		"-debug",
/+		"-unittest",
+/	];
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
		"-L/STACK:4194304",
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
		"-L/STACK:4194304",
	];
	immutable O = "obj";
} else {
	immutable EXE = NAME;
	immutable LIB = [
		"-Ldwt_base.a",
		"-Ldwt.a",
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
/+		"-unittest",
+/	];
	immutable string[] DEBUG_FLAGS_L = [
		"-g",
		"-debug",
/+		"-unittest",
+/	];
	immutable CONSOLE_FLAGS_L = [
		"-of" ~ EXE,
	];
	immutable string[] WINDOW_FLAGS_L = [
		"-of" ~ EXE,
	];
	immutable O = "o";
}

immutable FLAGS = [
	"-lowmem",
	"-w",
	"-op",
	// BUG: dmd 2.067.0 occurs compile error.
//	"-property",
	"-c",
];
immutable CRITICAL_FLAGS = [
	"-w",
	"-c",
	"-release",
	"-O",
	"-inline",
	"-op",
];
immutable NO_DEBUG_SYMBOLS_FLAGS = [
	"-w",
	"-c",
	"-op",
	"-debug",
/+	"-unittest",
+/
];
immutable RELEASE_FLAGS = [
	"-release",
/+ BUG: コンパイルが終わらなくなる。dmd 2.074.0
	"-O",
+/
];

immutable CONSOLE_FLAGS = [
	"-version=Console",
];
immutable string[] WINDOW_FLAGS = [
	// Nothing
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
	auto timer = std.datetime.stopwatch.StopWatch(AutoStart.yes);
	enforce(0 == spawnShell(line).wait(), new Exception(line));
	timer.stop();
	writefln("%d msecs", timer.peek().total!"msecs");
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

int main(string[] args) {
	try {
		build(args);
		return 0;
	} catch (Exception e) {
		writeln(e);
		return -1;
	}
}

void build(string[] args) {
	auto timer = std.datetime.stopwatch.StopWatch(AutoStart.yes);

	// ビルドフラグ
	string[] test, option, dmdOption;
	divide(args[1 .. $], test, option, dmdOption);
	.sort(test);
	.sort(option);
	bool help = option.has("help");
	bool release = option.has("release");
	bool console = option.has("cui");
	bool window = (release && !console) || option.has("gui");
	bool clean = option.has("clean");
	bool run = option.has("run");
	bool m64 = dmdOption.has("-m64") || dmdOption.has("-m32mscoff");
	bool unittests = dmdOption.has("-unittest");

	if (help) {
		writeln("Usage: rdmd build [help | clean | cui | gui | release | run | *.d]");
		return;
	}

	// 前回のフラグと比較・保存
	bool mod = false;
	string[] option2;
	auto writeOption2 = false;
	if (!test.length) {
		option2 = option.dup;
		option2 = std.algorithm.remove!(a => a == "clean")(option2);
		option2 = std.algorithm.remove!(a => a == "run")(option2);
		option2 = std.algorithm.remove!(a => a == "cui")(option2);
		option2 = std.algorithm.remove!(a => a == "gui")(option2);
		if (!window) option2 ~= "cui";
		if (window) option2 ~= "gui";
		if (m64) option2 ~= "-m64";
		if (unittests) option2 ~= "-unittest";
		.sort(option2);
		mod = "build.log".exists() && option2 != "build.log".readText().splitLines();
		writeOption2 = mod || !"build.log".exists();
	}

	if (clean || mod) {
		// クリーン
		EXE.removeFile();
		version (Windows) {
			RC.removeFile();
			RES.removeFile();
		}
		"objs".removeFile();
		"build.d.deps".removeFile();
		if (clean) "build.log".removeFile();
		version (Windows) {
			foreach (ext; [".exp", ".ilk", ".lib", ".pdb"]) {
				auto path = EXE.setExtension(ext);
				if (path.exists()) path.remove();
			}
		}
		if (clean && 1 == test.length + option.length) return;
	}

	// ソースコードとオブジェクトファイルのリスト
	string[string] objs; // コンパイル対象と生成されるオブジェクトファイルのテーブル
	string[][string] files; // コンパイル対象(ディレクトリ毎)
	string[] critical; // 速度優先でコンパイルされるべきファイル
	string[] noDebugSymbols; // リンクエラーになるので-gが使えないファイル
	string[] res; // リソースのディレクトリ
	foreach (string file; ".".dirEntries(SpanMode.depth)) {
		if (file.isDir()) continue;
		if (!file.extension().equalsFilename(".d")) continue;
		file = file.buildNormalizedPath();
		if (-1 != IGNORE_FILE.countUntil!equalsFilename(file)) continue;
		if (-1 != CRITICAL.countUntil!equalsFilename(file)) {
			critical ~= put(file, objs, test);
			continue;
		}
		if (!release && -1 != NO_DEBUG_SYMBOLS.countUntil!equalsFilename(file)) {
			noDebugSymbols ~= put(file, objs, test);
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
		if ("@version.txt".newer(RC)) {
			exec([DMD, "-J.", "-run", "createrc.d"]);
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
	if (!release && unittests) flags ~= "-unittest";
	if (critical.length) {
		exec(cmd ~ CRITICAL_FLAGS ~ res ~ critical ~ "-odobjs" ~ dmdOption);
	}
	if (noDebugSymbols.length) {
		auto flags2 = NO_DEBUG_SYMBOLS_FLAGS.dup;
		if (!release && unittests) flags2 ~= "-unittest";
		exec(cmd ~ flags2 ~ res ~ noDebugSymbols ~ "-odobjs" ~ dmdOption);
	}
	version (Windows) {
		immutable mscoffbug = 2068 <= __VERSION__ && __VERSION__ <= 2073 || (2089 <= __VERSION__ && __VERSION__ <= 2090 && m64 && !release);
	} else {
		immutable mscoffbug = true;
	}
	string[][] SPLITS;
	string[][] SPLITS_R;
	if (mscoffbug) {
		// Internal error: backend\mscoffobj.c 2176 by dmd 2.068-2.069, 2.089.0
		// まとめてコンパイルするとエラーが出るため分割する
		SPLITS = [
			[
				"absdialog.d",
				"areatable.d",
				"areaviewutils.d",
				"areaview.d",
				"areawindow.d",
				"bgimagedialog.d",
				"cardlist.d",
				"cardpane.d",
				"cardwindow.d",
				"centerlayout.d",
				"chooser.d",
				"commons.d",
				"couponview.d",
				"customtable.d",
				"customtoolbar.d",
				"customtext.d",
				"castcarddialog.d",
				"cwxeditor.d",
				"datawindow.d",
				"directorywindow.d",
				"dmenu.d",
				"dockingfolder.d",
				"dprops.d",
				"dskin.d",
				"dutils.d",
				"effectcarddialog.d",
				"etcsettings.d",
				"eventdialog.d",
				"eventeditor.d",
				"eventtreeview.d",
				"eventview.d",
				"eventwindow.d",
				"flagdirtree.d",
				"flagspane.d",
				"flagtable.d",
				"image.d",
				"imagelistwindow.d",
				"images.d",
				"imageselect.d",
				"incsearch.d",
				"infocarddialog.d",
				"jpyimage.d",
				"incsearch.d",
				"loader.d",
			],
			[
				"mainwindow.d",
				"materialselect.d",
				"messageutils.d",
				"abilityview.d",
				"contentinitializer.d",
				"eventtreedialog.d",
				"exprutils.d",
				"history.d",
				"namewindow.d",
				"partyhistory.d",
				"roundview.d",
				"motionview.d",
				"properties.d",
				"radarspinner.d",
				"replacedialog.d",
				"sbshell.d",
				"scales.d",
				"scripterrordialog.d",
				"settingsdialog.d",
				"smalldialogs.d",
				"imagelayer.d",
				"keycodeview.d",
				"spcarddialog.d",
				"splitpane.d",
				"summarydialog.d",
				"textdialog.d",
				"timebar.d",
				"undo.d",
				"xmlbytestransfer.d",
			],
		];
		SPLITS_R = SPLITS ~ [
			[
			],
		];
	}
	foreach (dir, array; files) {
		if (!array.length) continue;
		if (mscoffbug) {
			auto splits = new string[][SPLITS_R.length];
			string[] array2;
			foreach (file; array) {
				bool add = false;
				foreach (i, split; SPLITS_R) {
					if (split.has(file.baseName())) {
						splits[i] ~= file;
						add = true;
						break;
					}
				}
				if (!add) {
					array2 ~= file;
				}
			}
			foreach (array1; splits) {
				if (array1.length) exec(cmd ~ flags ~ array1 ~ res ~ "-odobjs" ~ dmdOption);
			}
			if (array2.length) exec(cmd ~ flags ~ array2 ~ res ~ "-odobjs" ~ dmdOption);
		} else {
			exec(cmd ~ flags ~ array ~ res ~ "-odobjs" ~ dmdOption);
		}
	}

	// ファイルが指定されている場合はコンパイルテストなのでここで終了
	if (test.length) {
		foreach (f; critical ~ files.values.join()) {
			auto obj = objs[f];
			writefln("%s: %s KB", obj, obj.getSize() / 1024);
		}
		timer.stop();
		writefln("Compiled: %d msecs", timer.peek().total!"msecs");
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
		flags = LIB.dup;
		flags ~= release ? RELEASE_FLAGS_L : DEBUG_FLAGS_L;
		flags ~= window ? WINDOW_FLAGS_L : CONSOLE_FLAGS_L;
	}

	exec(cmd ~ flags ~ objs.values ~ dmdOption);

	timer.stop();
	writefln("Compiled: %d msecs", timer.peek().total!"msecs");

	// 不要なファイルを削除
	version (Windows) {
		if (m64 && release) {
			foreach (ext; [".exp", ".ilk", ".lib", ".pdb"]) {
				auto path = EXE.setExtension(ext);
				if (path.exists()) path.remove();
			}
		}
	}

	if (writeOption2) {
		"build.log".write(option2.join("\n"));
	}

	if (run) {
		auto line = ".".buildPath(EXE);
		if (unittests) {
			line ~= " --DRT-testmode=run-main";
		}
		writeln(line);
		auto pid = .spawnShell(line);
		if (!window) pid.wait();
	}
}


module cwxeditor;

import cwx.utils;
import cwx.system;
import cwx.props;
import cwx.editor.gui.dwt.mainwindow;
import cwx.editor.gui.dwt.textdialog;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;

import std.file;
import std.path;
import std.stdio;
import std.exception;
import std.conv;
import std.cstream;

version (Windows) {
	import std.windows.charset;
	import std.c.windows.windows;
	import std.c.string;
}

void main(string[] args) {
	string appPath = args[0];
	version (Windows) {
		char[MAX_PATH] pathBuf;
		if (GetModuleFileNameA(null, pathBuf.ptr, pathBuf.length)) {
			appPath = fromMBSz(pathBuf.idup.ptr);
		} else {
			version (Console) {
				writeln("GetModuleFileName failure!");
			}
		}
	}
	version (Console) {
		string log = "Executed: " ~ appPath;
		version (Windows) {
			printf("%s\n\0".ptr, toMBSz(log));
			dout.flush();
		} else {
			writeln(log);
		}
	}

	cwx.utils.debugLog = buildPath(dirName(appPath), cwx.utils.debugLog);
	string dStr = .text(__LINE__); // 起動ログ
	try {
		auto sys = new System;
		string conf = buildPath(dirName(appPath), "cwxeditor.config");
		dStr ~= " - " ~ .text(__LINE__);
		if (args.length > 1) {
			string[] openPaths;
			size_t sc = 1u;
			for (int i = 1; i < args.length; i++) {
				bool help = false;
				try {
					switch (args[i]) {
					case "-a": // エリア表示
						dStr ~= " - " ~ .text(__LINE__);
						if (i + 1 < args.length) openPaths ~= "area:id:" ~ args[i + 1];
						sc = i + 2u;
						break;
					case "-b": // バトル表示
						dStr ~= " - " ~ .text(__LINE__);
						if (i + 1 < args.length) openPaths ~= "battle:id:" ~ args[i + 1];
						sc = i + 2u;
						break;
					case "-p": // パッケージ表示
						dStr ~= " - " ~ .text(__LINE__);
						if (i + 1 < args.length) openPaths ~= "package:id:" ~ args[i + 1];
						sc = i + 2u;
						break;
					case "-conf": // 設定ファイル指定
						dStr ~= " - " ~ .text(__LINE__);
						if (i + 1 < args.length) conf = args[i + 1];
						sc = i + 2u;
						break;
					case "-help", "-h", "/?": // usage
						dStr ~= " - " ~ .text(__LINE__);
						help = true;
						break;
					default:
						dStr ~= " - " ~ .text(__LINE__);
						if (i > sc) {
							openPaths ~= args[i];
						}
						break;
					}
				} catch (Exception e) {
					debugln(e);
				}
				dStr ~= " - " ~ .text(__LINE__);
				if (help) {
					version (Console) {
						try {
							string dir;
							version (Windows) {
								dir = "Folder";
							} else {
								dir = "Directory";
							}
							writeln("Usage: cwxeditor [-help | -conf <PATH>] <SCENARIO> [<CWXPath ...>]");
							writeln("");
							writeln("  Options:");
							writeln("    -help         print help");
							writeln("    -conf <PATH>  set config file path");
							writeln("    <SCENARIO>    read scenario (*.wsn/Summary.xml/Summary.wsm/[" ~ dir ~ "])");
							writeln("  OpenID:");
							writeln("    -a   <ID>     open area from <ID>");
							writeln("    -b   <ID>     open battle from <ID>");
							writeln("    -p   <ID>     open package from <ID>");
							writeln("  OpenPath:");
							writeln("    <CWXPath>     open resource from <CWXPath>");
						} catch (Exception e) {
							debugln(e);
						}
					}
					try {
						dStr ~= " - " ~ .text(__LINE__);
						auto prop = new Props(conf, new CProps(appPath, sys));
						auto comm = new Commons(prop);
						dStr ~= " - " ~ .text(__LINE__);
						auto dlg = new TextDialog(comm, prop, null, prop.msgs.dlgTitUsage, prop.images.app, prop.msgs.usage);
						dlg.open();
						dStr ~= " - " ~ .text(__LINE__);
						prop.images.disposeImages();
					} catch (Exception e) {
						debugln(e);
					}
					dStr ~= " - " ~ .text(__LINE__);
					return;
				}
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (sc < args.length) {
				auto main = new MainWindow(appPath, conf, sys, args[sc], openPaths);
				dStr ~= " - " ~ .text(__LINE__);
				main.doCWX();
				dStr ~= " - " ~ .text(__LINE__);
				return;
			}
		}
		dStr ~= " - " ~ .text(__LINE__);
		auto main = new MainWindow(appPath, conf, sys);
		dStr ~= " - " ~ .text(__LINE__);
		main.doCWX();
		dStr ~= " - " ~ .text(__LINE__);
	} catch (Throwable e) {
		fdebugln(dStr);
		// FIXME: リンクエラー！
//		fdebugln(e);
		throw e;
	}
}

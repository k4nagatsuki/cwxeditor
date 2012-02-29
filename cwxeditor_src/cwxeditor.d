
module cwxeditor;

import cwx.utils;
import cwx.system;
import cwx.props;
import cwx.structs;

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
	LaunchOption opt;

	cwx.utils.debugLog = buildPath(dirName(appPath), cwx.utils.debugLog);
	string dStr = .text(__LINE__); // 起動ログ
	try {
		auto sys = new System;
		opt.conf = buildPath(dirName(appPath), "cwxeditor.config");
		dStr ~= " - " ~ .text(__LINE__);
		opt.parseStrings(args[1 .. $]);
		if (opt.help) {
			dStr ~= " - " ~ .text(__LINE__);
			auto prop = new Props(opt.conf, new CProps(appPath, sys));
			version (Console) {
				try {
					cwriteln(prop.msgs.usage);
				} catch (Exception e) {
					debugln(e);
				}
			}
			try {
				dStr ~= " - " ~ .text(__LINE__);
				auto comm = new Commons(prop);
				dStr ~= " - " ~ .text(__LINE__);
				auto dlg = new TextDialog(comm, prop, null, prop.msgs.dlgTitUsage, prop.images.app, prop.msgs.usage ~ "\n");
				dlg.open();
				dStr ~= " - " ~ .text(__LINE__);
				prop.images.disposeImages();
			} catch (Exception e) {
				debugln(e);
			}
			dStr ~= " - " ~ .text(__LINE__);
			return;
		}
		dStr ~= " - " ~ .text(__LINE__);
		auto main = new MainWindow(appPath, sys, opt);
		dStr ~= " - " ~ .text(__LINE__);
		main.doCWX();
		dStr ~= " - " ~ .text(__LINE__);
		version (Console) {
			debug writeln("Exit main()");
		}
	} catch (Throwable e) {
		fdebugln(dStr);
		// FIXME: リンクエラー！
//		fdebugln(e);
		throw e;
	}
}

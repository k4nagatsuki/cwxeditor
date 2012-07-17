
module cwxeditor;

import cwx.utils;
import cwx.system;
import cwx.props;
import cwx.structs;
import cwx.msgs;

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

void main(string[] args) {
	string appPath = exeName(args[0]);
	version (Console) {
		string log = "Executed: " ~ appPath;
		cwriteln(log);
		debug {
			cwriteln(.tryFormat("unittest success: %d msec", utperf));
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
			/// usage
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
		if (opt.putlangfile.length) {
			// 言語ファイルを保存する
			auto prop = new Props(opt.conf, new CProps(appPath, sys));
			try {
				std.file.write(opt.putlangfile, prop.msgs.toXML(true));
			} catch (Exception e) {
				debugln(e);
			}
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
		fdebugln(e);
		throw e;
	}
}

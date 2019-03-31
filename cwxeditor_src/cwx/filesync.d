
module cwx.filesync;

import cwx.perf;
import cwx.utils : printStackTrace, debugln, preRemove;

import std.algorithm;
import std.array;
import std.datetime;
import std.file;
import std.random;
import std.range;
import std.stdio;
import std.string;
import std.typecons;

import core.thread;

/// ファイルをfsyncしながら出力する。
class FileSync : Thread {
	private bool _quit = false;
	private Tuple!(string, "file", const(void)[], "data", void delegate(), "after")[] _files;

	this () { super (&run); }

	/// 全てのファイル出力が完了してからスレッドを終了する。
	void quit() { _quit = true; }

	/// 出力対象を追加する。
	void push(string file, const(void)[] data, void delegate() after) { mixin(S_TRACE);
		synchronized (this) {
			_files ~= typeof(_files[0])(file, data, after);
		}
		if (_quit) { mixin(S_TRACE);
			try {
				join();
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
			writeFiles();
		}
	}
	/// 全てのファイル出力が完了するまで待ち合わせる。
	void sync() { mixin(S_TRACE);
		while (true) { mixin(S_TRACE);
			synchronized (this) {
				if (!_files.length) break;
			}
			Thread.sleep(.dur!"msecs"(1));
		}
	}
	private void writeFiles() { mixin(S_TRACE);
		while (true) { mixin(S_TRACE);
			typeof(_files[0]) f;
			synchronized (this) {
				if (_files.length) { mixin(S_TRACE);
					f = _files[0];
				} else { mixin(S_TRACE);
					break;
				}
			}
			scope (exit) {
				synchronized (this) {
					_files = _files[1 .. $];
				}
			}
			.writeFileAndSync(f.file, f.data);
			try {
				if (f.after) f.after();
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	private void run() { mixin(S_TRACE);
		while (!_quit) { mixin(S_TRACE);
			writeFiles();
			Thread.sleep(.dur!"msecs"(1));
		}
		writeFiles();
	}
}

/// ファイルを出力する。
void writeFile(string file, in void[] data, FileSync fsync, void delegate() after = null) { mixin(S_TRACE);
	if (fsync) { mixin(S_TRACE);
		fsync.push(file, data, after);
	} else { mixin(S_TRACE);
		scope (exit) after();
		std.file.write(file, data);
	}
}

/// ファイルを出力する。ハードウェアへの出力を確実に行う。
bool writeFileAndSync(string file, in void[] data) { mixin(S_TRACE);
	auto tmp = "";
	size_t i = 0;
	do { mixin(S_TRACE);
		i++;
		tmp = file ~ (i == 1 ? ".cwxeditor_temp" : ".cwxeditor_temp(%s)".format(i));
	} while (tmp.exists());
	try { mixin(S_TRACE);
		auto f = File(tmp, "wb");
		scope (success) {
			.preRemove(file);
			.rename(tmp, file);
		}
		scope (exit) {
			f.close();
		}
		f.rawWrite(data);
		f.flush();
		f.sync();
		return true;
	} catch (Exception e) {
		printStackTrace();
		debugln(e);
	}
	return false;
}

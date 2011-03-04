
module cwx.archive;

import cwx.utils;
import cwx.sjis;

import std.array;
import std.file;
import std.path;
import std.zip;
import std.utf;
import std.datetime;
import std.string;
import std.c.string : strlen;

/// ZIPファイルを展開する。
/// Params:
/// dir = 展開先のディレクトリ。
/// zip = ZIPファイルのパス。
/// fileProc = 個々のアーカイブメンバに対する処理を行うdelegate。
/// setProgressNum = nullでなければ、書庫内のファイル数が渡される。
/// progress = nullでなければ、展開中、展開完了したファイル数が渡される。
/// Throws:
/// ZipException = アーカイブの展開に失敗した。
/// UtfException = アーカイブに含まれるファイル名の文字コード解決が出来なかった。
/// FileException = ファイル入出力に失敗した。
void unzip(string parent, string zip,
		void delegate(uint) setProgressNum = null,
		void delegate(uint) progress = null) {
	scope arc = new ZipArchive(read(zip));
	unzip(parent, arc, setProgressNum, progress);
}
/// ditto
void unzip(string parent, ZipArchive arc,
		void delegate(uint) setProgressNum = null,
		void delegate(uint) progress = null) {
	unzip(arc, (string path, ubyte[] data, bool isDir) {
		path = std.path.join(parent, path);
		if (isDir) {
			assert (!data.length);
			if (!exists(path)) mkdirRecurse(path);
		} else {
			scope p = getDirName(path);
			if (!exists(p)) mkdirRecurse(p);
			write(path, data);
		}
	}, setProgressNum, progress);
}
/// ditto
void unzip(ZipArchive arc,
		void delegate(string path, ubyte[] data, bool isDir) fileProc,
		void delegate(uint) setProgressNum = null,
		void delegate(uint) progress = null) {
	if (setProgressNum !is null) {
		setProgressNum(arc.directory.length);
	}
	int count = 1;
	foreach (am; arc.directory) {
		string name = am.name;
		// ファイル名の文字コードがShift JISだったりするのを何とかする
		try {
			validate(name);
		} catch (UtfException e) {
			name = touni(name);
			validate(name);
		}
		string nml = replace(name, "/", sep);
		if (name.length > 0 && !hasParDir(nml)) {
			// 属性が不思議なことになってるので0x10だけで判断するのは避ける
			bool isDir = ((am.externalAttributes & 0x10) != 0 || name[$ - 1] == '\\') && am.expandedSize == 0;
			fileProc(nml, arc.expand(am), isDir);
		}
		if (progress !is null) {
			progress(count);
			count++;
		}
	}
}

/// ファイルとしては存在しないデータをアーカイブ化する。
ArchiveMember archive(string name, ubyte[] data, bool isDir) {
	if (data.length && isDir) throw new Exception("not directory");
	name = std.array.replace(name, sep, "/");
	static if (altsep.length) {
		name = std.array.replace(name, altsep, "/");
	}
	auto am = new ArchiveMember;
	am.time = SysTimeToDosFileTime(Clock.currTime);
	am.compressionMethod = 8;
	// Attributes: Directory = 0x10, File = 0x20, ReadOnly = 0x01
	am.externalAttributes = isDir ? 0x10 : 0x20;
	am.internalAttributes = 1;
	// ファイル名はUTF-8
	am.name = name;
	am.flags |= 0x800;
	if (!isDir) am.expandedData = data;
	return am;
}

/// targの内容をすべて含めたZipArchiveを返す。
/// targがディレクトリの場合、topにtrueを指定すると
/// targ自体もアーカイブに含める。
/// Params:
/// excludePath = 圧縮から除外するパスのリスト。
/// useSysEnc = trueにするとファイル名にシステムの文字コードをそのまま使用する。
///             falseの場合はUTF-8を使用する。
ZipArchive zip(string targ, bool top, string[] excludePath = [], bool useSysEnc = false) {
	auto arc = new ZipArchive;
	scope path = nabs(targ);
	foreach (ref ex; excludePath) {
		ex = nabs(ex);
	}
	size_t cut;
	void archive(string file) {
		foreach (ex; excludePath) {
			if (fnmatch(file, ex)) return;
		}
		if (isdir(file)) {
			string[] list = clistdir(file);
			if (list.length > 0) {
				foreach (c; list) {
					archive(std.path.join(file, c));
				}
				return;
			}
		}
		auto am = new ArchiveMember;
		am.time = SysTimeToDosFileTime(timeLastModified(file));
		am.compressionMethod = 8;
		auto name = file;
		if (isdir(file)) {
			name ~= sep;
		}
		// Attributes: Directory = 0x10, File = 0x20, ReadOnly = 0x01
		am.externalAttributes = getAttributes(file);
		am.internalAttributes = 1;
		name = name[cut .. $];
		if (useSysEnc) {
			version (Windows) {
				am.name = tosjis(name);
			} else {
				am.name = name;
			}
		} else {
			// ファイル名はUTF-8
			am.flags |= 0x800;
			am.name = name;
		}
		if (!isdir(file)) {
			am.expandedData = cast(ubyte[]) std.file.read(file);
		}
		arc.addMember(am);
	}
	if (top || !isdir(path)) {
		auto par = getDirName(path);
		if (par.length && !endsWith(par, sep)) par ~= sep;
		cut = par.length;
		archive(path);
	} else {
		cut = path.length + sep.length;
		foreach (c; clistdir(path)) {
			archive(std.path.join(path, c));
		}
	}
	return arc;
}

/// targをzip圧縮し、パスzipに保存する。
void zip(string targ, string zip, bool top, string[] excludePath = [], bool useSysEnc = false) {
	scope arc = .zip(targ, top, excludePath);
	std.file.write(zip, arc.build);
}

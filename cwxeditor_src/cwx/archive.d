
module cwx.archive;

import cwx.binary;
import cwx.utils;
import cwx.sjis;
import cwx.filesync;

import lhafile.lhafile;

import std.algorithm;
import std.array;
import std.file;
import std.path;
version (Win64) {
	import std.zip;
} else {
	import d2std.zip;
}
import std.utf;
import std.datetime;
import std.string;
import core.stdc.string : strlen;

/// アーカイヴのメンバ名をencodeする。
string encodeArchiveName(string name) { mixin(S_TRACE);
	name = std.array.replace(name, dirSeparator, "/");
	static if (altDirSeparator.length) { mixin(S_TRACE);
		name = std.array.replace(name, altDirSeparator, "/");
	}
	return name;
}

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
		string delegate(string, bool) expand = null,
		void delegate(uint) setProgressNum = null,
		void delegate(uint) progress = null) { mixin(S_TRACE);
	ubyte* temp;
	auto data = readBinaryFrom!ubyte(zip, temp);
	auto arc = new ZipArchive(data);
	unzip(parent, arc, expand, setProgressNum, progress);
	destroy(arc);
	(cast(ubyte[])data)[] = 0;
	freeAll(temp);
}
/// ditto
void unzip(string parent, ZipArchive arc,
		string delegate(string, bool) expand = null,
		void delegate(uint) setProgressNum = null,
		void delegate(uint) progress = null) { mixin(S_TRACE);
	unzip(arc, (string path, ubyte[] data, bool isDir) { mixin(S_TRACE);
		if (expand) { mixin(S_TRACE);
			path = expand(path, isDir);
			if (!path.length) return;
		}
		path = std.path.buildPath(parent, path);
		if (isDir) { mixin(S_TRACE);
			assert (!data.length);
			if (!exists(path)) mkdirRecurse(path);
		} else { mixin(S_TRACE);
			scope p = dirName(path);
			if (!exists(p)) mkdirRecurse(p);
			std.file.write(path, data);
		}
	}, setProgressNum, progress);
}
/// ditto
void unzip(ZipArchive arc,
		void delegate(string path, ubyte[] data, bool isDir) fileProc,
		void delegate(uint) setProgressNum = null,
		void delegate(uint) progress = null) { mixin(S_TRACE);
	if (setProgressNum !is null) { mixin(S_TRACE);
		setProgressNum(cast(uint)arc.directory.length);
	}
	int count = 1;
	foreach (am; arc.directory) { mixin(S_TRACE);
		string name = memberName(am.name);
		string nml = replace(name, "/", dirSeparator);
		if (nml.isOuterPath) { mixin(S_TRACE);
			// 外部のディレクトリに展開されそうなファイルは取り除く
			continue;
		}
		if (name.length > 0 && !hasParDir(nml)) { mixin(S_TRACE);
			// 属性が不思議なことになってるので0x10だけで判断するのは避ける
			bool isDir = ((am.fileAttributes & 0x10) != 0 || std.algorithm.endsWith(nml, dirSeparator)) && am.expandedSize == 0;
			auto data = arc.expand(am);
			fileProc(nml, data, isDir);
		}
		if (progress !is null) { mixin(S_TRACE);
			progress(count);
			count++;
		}
	}
}

/// ファイルとしては存在しないデータをアーカイブ化する。
ArchiveMember archive(string name, ubyte[] data, bool isDir, bool useSysEnc = false) { mixin(S_TRACE);
	if (data.length && isDir) throw new Exception("not directory");
	name = encodeArchiveName(name);
	auto am = new ArchiveMember;
	am.time = SysTimeToDosFileTime(Clock.currTime());
	am.compressionMethod = CompressionMethod.deflate;
	// Attributes: Directory = 0x10, File = 0x20, ReadOnly = 0x01
	am.fileAttributes = isDir ? 0x10 : 0x20;
	am.internalAttributes = 1;
	if (useSysEnc) { mixin(S_TRACE);
		version (Windows) {
			am.name = tosjis(name);
		} else { mixin(S_TRACE);
			am.name = name;
		}
	} else { mixin(S_TRACE);
		// ファイル名はUTF-8
		am.flags |= 0x800;
		am.name = name;
	}
	if (!isDir) am.expandedData = data;
	return am;
}

/// targの内容をすべて含めたZipArchiveを返す。
/// targがディレクトリの場合、topにtrueを指定すると
/// targ自体もアーカイブに含める。
/// Params:
/// ignorePath = このdelegeteがtrueを返したパスは除外される。
/// useSysEnc = trueにするとファイル名にシステムの文字コードをそのまま使用する。
///             falseの場合はUTF-8を使用する。
ZipArchive zip(string targ, bool top, bool delegate(string path) ignorePath, bool useSysEnc, ref ubyte*[] data) { mixin(S_TRACE);
	auto arc = new ZipArchive;
	scope path = nabs(targ);
	size_t cut;
	void archive(string file) { mixin(S_TRACE);
		if (ignorePath && ignorePath(file)) { mixin(S_TRACE);
			return;
		}
		if (isDir(file)) { mixin(S_TRACE);
			string[] list = clistdir(file);
			if (list.length > 0) { mixin(S_TRACE);
				foreach (c; list) { mixin(S_TRACE);
					archive(std.path.buildPath(file, c));
				}
				return;
			}
		}
		auto am = new ArchiveMember;
		am.time = SysTimeToDosFileTime(timeLastModified(file));
		am.compressionMethod = CompressionMethod.deflate;
		auto name = file;
		if (isDir(file)) { mixin(S_TRACE);
			name ~= dirSeparator;
		}
		// Attributes: Directory = 0x10, File = 0x20, ReadOnly = 0x01
		am.fileAttributes = getAttributes(file);
		am.internalAttributes = 1;
		name = name[cut .. $];
		name = encodeArchiveName(name);
		if (useSysEnc) { mixin(S_TRACE);
			version (Windows) {
				am.name = tosjis(name);
			} else { mixin(S_TRACE);
				am.name = name;
			}
		} else { mixin(S_TRACE);
			// ファイル名はUTF-8
			am.flags |= 0x800;
			am.name = name;
		}
		if (!isDir(file)) { mixin(S_TRACE);
			ubyte* temp;
			am.expandedData = readBinaryFrom!ubyte(file, temp);
			data ~= temp;
		}
		arc.addMember(am);
	}
	if (top || !isDir(path)) { mixin(S_TRACE);
		auto par = dirName(path);
		if (par.length && !endsWith(par, dirSeparator)) par ~= dirSeparator;
		cut = par.length;
		archive(path);
	} else { mixin(S_TRACE);
		cut = path.length + dirSeparator.length;
		foreach (c; clistdir(path)) { mixin(S_TRACE);
			archive(std.path.buildPath(path, c));
		}
	}
	return arc;
}
/// ditto
ZipArchive zip(string targ, bool top, string[] excludePath, bool useSysEnc, ref ubyte*[] data) { mixin(S_TRACE);
	foreach (i, ex; excludePath) { mixin(S_TRACE);
		excludePath[i] = nabs(ex);
	}
	return .zip(targ, top, (string path) { mixin(S_TRACE);
		return containsPath(excludePath, path);
	}, useSysEnc, data);
}

// ファイル名の文字コードをUTF-8に統一する。
string memberName(string name) {
	try {
		cwx.utils.validate(name);
	} catch (Exception e) {
		name = touni(name, false, "__");
		cwx.utils.validate(name);
	}
	return name;
}

/// 指定されたファイルが含まれているか。
string zipHasFile(string zip, string fileName) { mixin(S_TRACE);
	if (!zip.exists()) return "";
	try { mixin(S_TRACE);
		ubyte* temp;
		auto bin = readBinaryFrom!ubyte(zip, temp);
		scope (exit) freeAll(temp);
		auto arc = new ZipArchive(cast(ubyte[])bin);
		scope (exit) destroy(arc);
		foreach (am; arc.directory) { mixin(S_TRACE);
			string name = memberName(am.name);
			if (cfnmatch(replace(name, "/", dirSeparator).baseName(), fileName)) { mixin(S_TRACE);
				return name;
			}
		}
	} catch (Exception e) {
		printStackTrace();
		debugln!(__FILE__, __LINE__, Exception)(e);
	}
	return "";
}

/// targをzip圧縮し、パスzipに保存する。
void zip(string targ, string zip, bool top, bool delegate(string path) ignorePath, bool useSysEnc, FileSync sync) { mixin(S_TRACE);
	ubyte*[] data;
	scope arc = .zip(targ, top, ignorePath, useSysEnc, data);
	auto b = arc.build();
	.writeFile(zip, b, sync);
	destroy(arc);
	freeAll(data);
}
void zip(string targ, string zip, bool top, string[] excludePath, bool useSysEnc, FileSync sync) { mixin(S_TRACE);
	foreach (i, ex; excludePath) { mixin(S_TRACE);
		excludePath[i] = nabs(ex);
	}
	.zip(targ, zip, top, (string path) { mixin(S_TRACE);
		return containsPath(excludePath, path);
	}, useSysEnc, sync);
}

/// LHAアーカイヴarcをparentに展開する。
void unlha(string parent, LhaFile arc,
		string delegate(string, bool) expand = null,
		void delegate(uint) setProgressNum = null,
		void delegate(uint) progress = null) { mixin(S_TRACE);
	unlha(arc, (string path, ubyte[] data, bool isDir) { mixin(S_TRACE);
		if (expand) { mixin(S_TRACE);
			path = expand(path, isDir);
			if (!path.length) return;
		}
		path = std.path.buildPath(parent, path);
		if (isDir) { mixin(S_TRACE);
			assert (!data.length);
			if (!exists(path)) mkdirRecurse(path);
		} else { mixin(S_TRACE);
			auto p = dirName(path);
			if (!exists(p)) mkdirRecurse(p);
			std.file.write(path, data);
		}
	}, setProgressNum, progress);
}
/// ditto
void unlha(LhaFile arc,
		void delegate(string path, ubyte[] data, bool isDir) fileProc,
		void delegate(uint) setProgressNum = null,
		void delegate(uint) progress = null) { mixin(S_TRACE);
	if (setProgressNum !is null) { mixin(S_TRACE);
		setProgressNum(cast(uint)arc.infoList.length);
	}
	int count = 1;
	foreach (info; arc.infoList) { mixin(S_TRACE);
		auto name = info.fileName;
		if (name.isOuterPath) { mixin(S_TRACE);
			// 外部のディレクトリに展開されそうなファイルは取り除く
			continue;
		}
		if (name.length > 0 && !hasParDir(name)) { mixin(S_TRACE);
			auto data = !info.isDirectory ? arc.read(name) : [];
			fileProc(name, data, info.isDirectory);
		}
		if (progress !is null) { mixin(S_TRACE);
			progress(count);
			count++;
		}
	}
}

/// 指定されたファイルが含まれているか。
string lhaHasFile(string lha, string fileName) { mixin(S_TRACE);
	if (!lha.exists()) return "";
	try { mixin(S_TRACE);
		ubyte* ptr = null;
		auto bin = readBinaryFrom!ubyte(lha, ptr);
		scope (exit) freeAll(ptr);
		auto arc = new LhaFile(lha, ByteIO(cast(void[])bin));
		scope (exit) destroy(arc);

		foreach (name; arc.nameList) { mixin(S_TRACE);
			if (cfnmatch(baseName(name), fileName)) { mixin(S_TRACE);
				return name.idup;
			}
		}
	} catch (Exception e) {
		printStackTrace();
		debugln!(__FILE__, __LINE__, Exception)(e);
	}
	return "";
}

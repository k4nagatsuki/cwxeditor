
module cwx.cab;

version (Windows) {
	import std.c.windows.windows;
}

import std.file;
import std.loader;
import std.path;
import std.stdio;
import std.string;
import std.utf;

import std.c.string;

import cwx.sjis;
import cwx.utils;

version (Windows) {
	/// uncab()が行える状態であればtrueを返す。
	/// setupapi.dllが使用できないなどの理由でfalseを返す事がある。
	bool canUncab() {
		return SetupIterateCabinetW && SetupIterateCabinetA;
	}
} else {
	/// uncab()が行える状態であればtrueを返す。
	/// setupapi.dllが使用できないなどの理由でfalseを返す事がある。
	bool canUncab() {return false;}
}

version (Windows) {
	/// src以下のファイル・フォルダを全て圧縮し、CAB書庫cabを生成する。
	/// tempDirには作業用のファイルが入る。nullを指定した場合は
	/// srcが使用される。
	bool cab(string src, string cab, string tempDir = null, bool delegate(string) isArc = null) {
		if (!canUncab) return false;
		if (!.exists(src)) return false;
		if (!tempDir) {
			tempDir = isdir(src) ? src : "";
		}
		src = nabs(src);
		string prefix = "";
		if (isdir(src)) {
			prefix = getBaseName(src);
		}
		string[] list(string file) {
			if (isArc && !isArc(file)) return [];
			string[] r;
			if (isdir(file)) {
				if (file.length <= src.length) {
					r ~= ".Set DestinationDir=\"" ~ prefix ~ "\"";
				} else {
					r ~= ".Set DestinationDir=\""
						~ std.path.join(prefix, file[src.length + sep.length .. $]) ~ "\"";
				}
				string[] flist = clistdir(file);
				foreach (cf; flist) {
					cf = std.path.join(file, cf);
					if (!isdir(cf)) {
						r ~= list(cf);
					}
				}
				foreach (cf; flist) {
					cf = std.path.join(file, cf);
					if (isdir(cf)) {
						r ~= list(cf);
					}
				}
			} else {
				r ~= "\"" ~ file ~ "\"";
			}
			return r;
		}
		auto l = list(src);
		auto temp = createNewFileName(std.path.join(tempDir, "cab_temp"), true);
		mkdirRecurse(temp);
		scope (exit) delAll(temp);
		auto lf = std.path.join(temp, "filelist.txt");
		std.file.write(lf, tosjis(std.string.join(l, linesep)));
		string cmd = "makecab /F filelist.txt";
		if (exec(cmd, temp, false, true)) {
			string ot = std.path.join(temp, std.path.join("disk1", "1.cab"));
			if (exists(ot)) {
				if (exists(cab)) {
					auto ncab = createNewFileName(cab, false);
					std.file.rename(ot, ncab);
					preRemove(cab);
					std.file.remove(cab);
					std.file.rename(ncab, cab);
				} else {
					std.file.rename(ot, cab);
				}
				return true;
			}
		}
		return false;
	}

	/// CAB書庫fileをフォルダdestに展開する。
	/// expandはこれから展開しようとしている書庫内のファイル名を受取り、
	/// 展開後のファイル名を返す。""を返した場合はそのファイルの展開が
	/// キャンセルされる。
	/// 何も特別な事をせずにそのまま展開する場合はexpand = nullとする。
	/// SetupAPIの仕様上、書庫と出力先は共にファイルを指定しなければならない。
	bool uncab(string file, string dest, string delegate(string) expand = null) {
		if (!canUncab) return false;
		if (!.exists(file)) return false;
		if (!expand) {
			expand = (string file) {return file;};
		}
		if (GetVersion < 0x80000000) {
			return SetupIterateCabinetW(toUTF16z(file), 0, &cabCallback, cast(void*) &Prm(dest, expand)) != 0;
		} else {
			return SetupIterateCabinetA(toStringz(tosjis(file)), 0, &cabCallback, cast(void*) &Prm(dest, expand)) != 0;
		}
	}

	private SIC_A SetupIterateCabinetA = null;
	private SIC_W SetupIterateCabinetW = null;
	static this () {
		if (exec("makecab /?", "", false)) {
			auto setupapi = ExeModule_Load("setupapi.dll");
			if (setupapi) {
				SetupIterateCabinetA = cast(SIC_A) ExeModule_GetSymbol(setupapi, "SetupIterateCabinetA");
				if (!SetupIterateCabinetA) debugln("Not found: SetupIterateCabinetA");
				SetupIterateCabinetW = cast(SIC_W) ExeModule_GetSymbol(setupapi, "SetupIterateCabinetW");
				if (!SetupIterateCabinetW) debugln("Not found: SetupIterateCabinetW");
			} else {
				debugln("Not found: setupapi.dll");
			}
		} else {
			debugln("Can't use: makecab");
		}
	}

	private extern (Windows) {
		alias UINT* UINT_PTR;
		alias UINT function (
			PVOID pMyInstallData,
			UINT Notification,
			UINT_PTR Param1,
			UINT_PTR Param2) PSP_FILE_CALLBACK;
		alias BOOL function (
			PCSTR CabinetFile,
			DWORD Reserved,
			PSP_FILE_CALLBACK MsgHandler,
			PVOID Context
		) SIC_A;
		alias BOOL function (
			PCWSTR CabinetFile,
			DWORD Reserved,
			PSP_FILE_CALLBACK MsgHandler,
			PVOID Context
		) SIC_W;
		alias typeof(LPCTSTR[0]) TCHAR;
		const NO_ERROR = 0;
		const FILEOP_COPY = 0;
		const FILEOP_RENAME = 1;
		const FILEOP_DELETE = 2;
		const FILEOP_ABORT = 0;
		const FILEOP_DOIT = 1;
		const FILEOP_SKIP = 2;
		const FILEOP_RETRY = FILEOP_DOIT;
		const FILEOP_NEWPATH = 4;
		const SPFILENOTIFY_CABINETINFO = 0x10;
		const SPFILENOTIFY_FILEINCABINET = 0x11;
		const SPFILENOTIFY_NEEDNEWCABINET = 0x12;
		const SPFILENOTIFY_FILEEXTRACTED = 0x13;
		const SPFILENOTIFY_FILEOPDELAYED = 0x14;
		struct FILEPATHS_A {
			PCSTR Target;
			PCSTR Source;
			UINT Win32Error;
			DWORD Flags;
		}
		struct FILEPATHS_W {
			PCWSTR Target;
			PCWSTR Source;
			UINT Win32Error;
			DWORD Flags;
		}
		struct CABINET_INFO_A {
			PCSTR CabinetPath;
			PCSTR CabinetFile;
			PCSTR DiskName;
			USHORT SetId;
			USHORT CabinetNumber;
		}
		struct CABINET_INFO_W {
			PCWSTR CabinetPath;
			PCWSTR CabinetFile;
			PCWSTR DiskName;
			USHORT SetId;
			USHORT CabinetNumber;
		}
		struct FILE_IN_CABINET_INFO_A {
			PCSTR NameInCabinet;
			DWORD FileSize;
			DWORD Win32Error;
			WORD DosDate;
			WORD DosTime;
			WORD DosAttribs;
			CHAR[MAX_PATH] FullTargetName;
		}
		struct FILE_IN_CABINET_INFO_W {
			PCWSTR NameInCabinet;
			DWORD FileSize;
			DWORD Win32Error;
			WORD DosDate;
			WORD DosTime;
			WORD DosAttribs;
			WCHAR[MAX_PATH] FullTargetName;
		}
	}

	private extern (Windows) UINT cabCallback(PVOID pMyInstallData, UINT Notification, UINT_PTR Param1, UINT_PTR Param2) {
		auto prm = cast(Prm*) pMyInstallData;
		UINT r = NO_ERROR;

		switch (Notification) {
		case SPFILENOTIFY_FILEINCABINET: {
			string tof(string file) {
				file = std.path.join(prm.dest, file);
				string dir = getDirName(file);
				if (!.exists(dir)) mkdirRecurse(dir);
				r = FILEOP_DOIT;
				return file;
			}
			string exp(string file) {
				if (std.string.find(file, "..") >= 0) {
					return "";
				} else {
					return prm.expand(file);
				}
			}
			r = FILEOP_SKIP;
			if (GetVersion < 0x80000000) {
				auto info = cast(FILE_IN_CABINET_INFO_W*) Param1;
				string file = toUTF8(info.NameInCabinet[0 .. wcslen(info.NameInCabinet)]);
				file = exp(file);
				if (file.length) {
					file = tof(file);
					wstring wf = toUTF16(file);
					info.FullTargetName[] = 0;
					info.FullTargetName[0 .. wf.length] = wf;
				}
			} else {
				auto info = cast(FILE_IN_CABINET_INFO_A*) Param1;
				string file = touni(info.NameInCabinet[0 .. strlen(info.NameInCabinet)]);
				file = exp(file);
				if (file.length) {
					file = tof(file);
					info.FullTargetName[] = 0;
					info.FullTargetName[0 .. file.length] = file;
				}
			}
		} break;
		case SPFILENOTIFY_FILEEXTRACTED: {
			// Param1 is FILEPATHS_[WA]
		} break;
		case SPFILENOTIFY_CABINETINFO: {
			// Param1 is CABINETINFO
		} break;
		default: break;
		}
		return r;
	}

	private struct Prm {
		string dest;
		string delegate(string) expand;
	}
} else {
	/// src以下のファイル・フォルダを全て圧縮し、CAB書庫cabを生成する。
	/// Windows以外のOSでは必ず失敗し、falseを返す。
	bool cab(string src, string cab, string tempDir = null, bool delegate(string) isArc = null) {
		return false;
	}
	/// CAB書庫fileをフォルダdestに展開する。
	/// Windows以外のOSでは必ず失敗し、falseを返す。
	bool uncab(string file, string dest, string delegate(string) expand = null) {
		return false;
	}
}

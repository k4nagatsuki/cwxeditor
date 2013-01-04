
module cwx.cab;

import cwx.utils;
import cwx.sjis;

import std.conv;
import std.stdio;
import std.array;
import std.stream;
import std.exception;
import std.file;
import std.path;

import std.c.string;

version (Windows) {
	import std.windows.charset;
	import std.c.windows.windows;

	/// uncab()が行える状態であればtrueを返す。
	/// cabinet.dllが使用できないなどの理由でfalseを返す事がある。
	@property
	bool canUncab() {
		return usable;
	}

	/// src以下のファイル・フォルダを全て圧縮し、CAB書庫cabを生成する。
	/// ファイルは圧縮される直前にisArc(string)へ渡され、isArc()がfalseを
	/// 返すようであれば、そのファイルの圧縮を行わない。
	bool cab(string src, string cab, bool delegate(string) isArc = null) {
		if (!canUncab) return false;
		if (!.exists(src)) return false;
		src = nabs(src);
		auto h = fciCreate(nabs(cab));
		if (!h) return false;
		scope (exit) destroyFCI(h);
		string cut = dirName(src) ~ dirSeparator.idup;
		bool adds(string file) {
			if (isArc && !isArc(file)) return true;
			bool isdir = isDir(file);
			if (file.length > cut.length && !isdir) {
				string name = file[cut.length .. $];
				version (Windows) {
					string nFile = null;
					scope (exit) {
						if (nFile) remove(nFile);
					}
					auto hf = CreateFileW(std.utf.toUTFz!(wchar*)(file), GENERIC_WRITE, FILE_SHARE_READ, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);
					if (INVALID_HANDLE_VALUE == hf) {
						// cabinet.dllが書込権限を要求するため、一時領域にコピー
						wchar[MAX_PATH] path;
						wchar[MAX_PATH] tempFile;
						if (!GetTempPathW(path.length, path.ptr)) return false;
						if (!GetTempFileNameW(path.ptr, "fci"w.ptr, 0, tempFile.ptr)) return false;
						nFile = to!string(tempFile[0 .. std.string.indexOf(tempFile, '\0')]);
						copy(file, nFile);
						file = nFile;
					} else {
						CloseHandle(hf);
					}
				}
				if (!add(h, file, name)) {
					return false;
				}
			}
			if (isdir) {
				foreach (cf; clistdir(file)) {
					if (!adds(std.path.buildPath(file, cf))) {
						return false;
					}
				}
			}
			return true;
		}
		if (!adds(src)) return false;
		return flush(h);
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
		auto h = fdiCreate();
		if (!h) return false;
		scope (exit) destroyFDI(h);
		return isCab(h, file) && copyFiles(h, file, dest, expand);
	}

	private extern (Windows) {
		alias HANDLE HFCI;
		alias HANDLE HFDI;
		alias size_t SIZE_T;
		alias USHORT TCOMP;

		const _O_WRONLY = 0x0001;
		const _O_RDWR = 0x0002;
		const _O_CREAT = 0x0100;

		const CB_MAX_DISK_NAME = 256;
		const CB_MAX_CABINET_NAME = 256;
		const CB_MAX_CAB_PATH = 256;

		const tcompMASK_TYPE = 0x000F;
		const tcompTYPE_NONE = 0x0000;
		const tcompTYPE_MSZIP = 0x0001;
		const tcompTYPE_QUANTUM = 0x0002;
		const tcompTYPE_LZX = 0x0003;
		const tcompBAD = 0x000F;

		const tcompMASK_LZX_WINDOW = 0x1F00;
		const tcompLZX_WINDOW_LO = 0x0F00;
		const tcompLZX_WINDOW_HI = 0x1500;
		const tcompSHIFT_LZX_WINDOW = 8;

		const tcompMASK_QUANTUM_LEVEL = 0x00F0;
		const tcompQUANTUM_LEVEL_LO = 0x0010;
		const tcompQUANTUM_LEVEL_HI = 0x0070;
		const tcompSHIFT_QUANTUM_LEVEL = 4;

		const tcompMASK_QUANTUM_MEM = 0x1F00;
		const tcompQUANTUM_MEM_LO = 0x0A00;
		const tcompQUANTUM_MEM_HI = 0x1500;
		const tcompSHIFT_QUANTUM_MEM = 8;

		const tcompMASK_RESERVED = 0xE000;

		const cpuUNKNOWN = -1;
		const cpu80286 = 0;
		const cpu80386 = 1;

		struct ERF {
			INT erfOper;
			INT erfType;
			BOOL fError;
		}
		struct CCAB {
			ULONG cb; 
			ULONG cbFolderThresh;
			UINT cbReserveCFHeader;
			UINT cbReserveCFFolder;
			UINT cbReserveCFData;
			INT iCab;
			INT iDisk;
	//#ifndef REMOVE_CHICAGO_M6_HACK
			INT fFailOnIncompressible;
	//#endif
			USHORT setID;
			char[CB_MAX_DISK_NAME] szDisk;
			char[CB_MAX_CABINET_NAME] szCab;
			char[CB_MAX_CAB_PATH] szCabPath;
		}
		struct FDICABINETINFO {
			LONG cbCabinet;
			USHORT cFolders;
			USHORT cFiles;
			USHORT setID;
			USHORT iCabinet;
			BOOL fReserve;
			BOOL hasprev;
			BOOL hasnext;
		}
		enum FDINOTIFICATIONTYPE : INT {
			fdintCABINET_INFO = 0,
			fdintPARTIAL_FILE = 1,
			fdintCOPY_FILE = 2,
			fdintCLOSE_FILE_INFO = 3,
			fdintNEXT_CABINET = 4,
			fdintENUMERATE = 5,
		}
		enum FDIERROR : INT {
			FDIERROR_NONE = 0,
			FDIERROR_CABINET_NOT_FOUND = 1,
			FDIERROR_NOT_A_CABINET = 2,
			FDIERROR_UNKNOWN_CABINET_VERSION = 3,
			FDIERROR_CORRUPT_CABINET = 4,
			FDIERROR_ALLOC_FAIL = 5,
			FDIERROR_BAD_COMPR_TYPE = 6,
			FDIERROR_MDI_FAIL = 7,
			FDIERROR_TARGET_FILE = 8,
			FDIERROR_RESERVE_MISMATCH = 9,
			FDIERROR_WRONG_CABINET = 10,
			FDIERROR_USER_ABORT = 11,
		}
		struct FDINOTIFICATION {
			LONG cb;
			LPSTR psz1;
			LPSTR psz2;
			LPSTR psz3;
			LPVOID pv;
			INT hf;
			USHORT date;
			USHORT time;
			USHORT attribs;
			USHORT setID;
			USHORT iCabinet;
			USHORT iFolder;
			FDIERROR fdie;
		}
		enum FDIDECRYPTTYPE : INT {
			fdidtNEW_CABINET = 0,
			fdidtNEW_FOLDER = 1,
			fdidtDECRYPT = 2,
		}
		struct FDIDECRYPT {
			FDIDECRYPTTYPE fdidt;
			LPVOID pvUser;
			union {
				static struct C {
					LPVOID pHeaderReserve;
					USHORT cbHeaderReserve;
					USHORT setID;
					int iCabinet;
				}
				C cabinet;
				static struct F {
					LPVOID pFolderReserve;
					USHORT cbFolderReserve;
					USHORT iFolder;
				}
				F folder;
				static struct D {
					LPVOID pDataReserve;
					USHORT cbDataReserve;
					LPVOID pbData;
					USHORT cbData;
					BOOL fSplit;
					USHORT cbPartial;
				}
				D decrypt;
			}
		}
		LPVOID HeapAlloc(HANDLE hHeap, DWORD dwFlags, SIZE_T dwBytes);
		HANDLE GetProcessHeap();
		BOOL HeapFree(HANDLE hHeap, DWORD dwFlags, LPVOID lpMem);
		DWORD GetTempPathA(DWORD nBufferLength, LPSTR lpBuffer);
		UINT GetTempFileNameA(LPCSTR lpPathName, LPCSTR lpPrefixString, UINT uUnique, LPSTR lpTempFileName);
		DWORD GetTempPathW(DWORD nBufferLength, LPWSTR lpBuffer);
		UINT GetTempFileNameW(LPCWSTR lpPathName, LPCWSTR lpPrefixString, UINT uUnique, LPWSTR lpTempFileName);
		DWORD SetFilePointer(HANDLE hFile, LONG lDistanceToMove, LONG* lpDistanceToMoveHigh, DWORD dwMoveMethod);
		BOOL GetFileTime(HANDLE hFile, LPFILETIME lpCreationTime, LPFILETIME lpLastAccessTime, LPFILETIME lpLastWriteTime);
		BOOL SetFileTime(HANDLE hFile, FILETIME* lpCreationTime, FILETIME* lpLastAccessTime, FILETIME* lpLastWriteTime);
		BOOL SetFileAttributesA(LPCSTR lpFileName, DWORD dwFileAttributes);

		extern (C++) {
			INT FNFCIFILEPLACED(CCAB* pccab, LPSTR pszFile, LONG cbFile, BOOL fContinuation, LPVOID pv) {
				return 0;
			}
			LPVOID FNFCIALLOC(ULONG cb) {
				return HeapAlloc(GetProcessHeap(), 0, cb);
			}
			alias FNFCIALLOC FNALLOC;
			void FNFCIFREE(LPVOID memory) {
				HeapFree(GetProcessHeap(), 0, memory);
			}
			alias FNFCIFREE FNFREE;
			INT FNFCIOPEN(LPSTR pszFile, INT oflag, INT pmode, INT *err, LPVOID pv) {
				DWORD access = 0;
				if (oflag & _O_RDWR) {
					access = GENERIC_READ | GENERIC_WRITE;
				} else if (oflag & _O_WRONLY) {
					access = GENERIC_WRITE;
				} else {
					access = GENERIC_READ;
				}
				DWORD create = 0;
				if (oflag & _O_CREAT) {
					create = CREATE_ALWAYS;
				} else {
					create = OPEN_EXISTING;
				}
				auto h = CreateFileA(pszFile, access, FILE_SHARE_READ, null, create, FILE_ATTRIBUTE_NORMAL, null);
				return cast(INT) h;
			}
			INT FNOPEN(LPSTR pszFile, INT oflag, INT pmode, INT *err, LPVOID pv) {
				return cast(INT) CreateFileA(pszFile, GENERIC_READ, FILE_SHARE_READ, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);
			}
			UINT FNFCIREAD(INT hf, LPVOID memory, UINT cb, INT* err, LPVOID pv) {
				DWORD val;
				ReadFile(cast(HANDLE) hf, memory, cb, &val, null);
				return val;
			}
			alias FNFCIREAD FNREAD;
			UINT FNFCIWRITE(INT hf, LPVOID memory, UINT cb, INT* err, LPVOID pv) {
				DWORD val;
				WriteFile(cast(HANDLE) hf, memory, cb, &val, null);
				return val;
			}
			alias FNFCIWRITE FNWRITE;
			INT FNFCICLOSE(INT hf, INT* err, LPVOID pv) {
				return !CloseHandle(cast(HANDLE) hf);
			}
			alias FNFCICLOSE FNCLOSE;
			LONG FNFCISEEK(INT hf, LONG dist, INT seektype, INT* err, LPVOID pv) {
				LONG p = 0;
				return SetFilePointer(cast(HANDLE) hf, dist, &p, seektype);
			}
			alias FNFCISEEK FNSEEK;

			INT FNFCIDELETE(LPSTR pszFile, INT* err, LPVOID pv) {
				return !DeleteFileA(pszFile);
			}
			BOOL FNFCIGETTEMPFILE(LPSTR pszTempName, INT cbTempName, LPVOID pv) {
				char[MAX_PATH] path;
				if (!GetTempPathA(cbTempName, path.ptr)) return FALSE;
				if (!GetTempFileNameA(path.ptr, "fci".ptr, 0, pszTempName)) return FALSE;
				return TRUE;
			}
			BOOL FNFCIGETNEXTCABINET(CCAB* pccab, ULONG cbPrevCab, LPVOID pv) {
				return FALSE;
			}
			LONG FNFCISTATUS(UINT typeStatus, ULONG cb1, ULONG cb2, LPVOID pv) {
				return 0;
			}
			INT FNFCIGETOPENINFO(LPSTR pszName, USHORT* pdate, USHORT* ptime, USHORT* pattribs, INT* err, LPVOID pv) {
				auto h = CreateFileA(pszName, GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);
				if (h == INVALID_HANDLE_VALUE) return -1;
				FILETIME ft, lft;
				GetFileTime(h, null, null, &ft);
				FileTimeToLocalFileTime(&ft, &lft);
				FileTimeToDosDateTime(&lft, pdate, ptime);
				*pattribs = cast(USHORT) (GetFileAttributesA(pszName)
					& (FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_ARCHIVE));
				return cast(INT) h;
			}
			INT FNFDINOTIFY(FDINOTIFICATIONTYPE type, FDINOTIFICATION* pNotify) {
				switch (type) {
				case FDINOTIFICATIONTYPE.fdintCABINET_INFO: return 0;
				case FDINOTIFICATIONTYPE.fdintCOPY_FILE: {
					auto prm = cast(Prm*) pNotify.pv;
					char[] path;
					path.length = MAX_PATH + strlen(prm.dest) + 1;
					strcpy(path.ptr, prm.dest);
					auto cpp = cast(char*) pNotify.psz1;
					auto len = strlen(cpp);
					for (size_t i = 0; i < len; i++) {
						if (cpp[i] == '/') cpp[i] = '\\';
					}
					if (len >= 3 && cpp[0] == '.'  && cpp[1] == '.' && cpp[2] == '\\') {
						return -1;
					}
					if (strstr(cpp, ("\\..\\").ptr)) {
						return -1;
					}
					if (prm.expand) {
						auto pt = touni(cpp[0 .. len]);
						auto cp = prm.expand(pt);
						if (!cp.length) {
							prm.onExpand = null;
							return -1;
						}
						strcat(path.ptr, toMBSz(cp));
					} else {
						strcat(path.ptr, cast(char*) pNotify.psz1);
					}
					auto dir = dirName(touni(path[0 .. strlen(path.ptr)]));
					if (!exists(dir)) mkdirRecurse(dir);
					prm.onExpand = path.ptr;
					return cast(INT) CreateFileA(path.ptr, GENERIC_WRITE, 0, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, null);
				} break;
				case FDINOTIFICATIONTYPE.fdintCLOSE_FILE_INFO: {
					auto h = cast(HANDLE) pNotify.hf;
					scope (exit) CloseHandle(h);
					FILETIME ft, lft;
					DosDateTimeToFileTime(pNotify.date, pNotify.time, &ft);
					LocalFileTimeToFileTime(&ft, &lft);
					SetFileTime(h, &lft, null, &ft);
					SetFileAttributesA((cast(Prm*) pNotify.pv).onExpand, pNotify.attribs);
					return TRUE;
				} break;
				case FDINOTIFICATIONTYPE.fdintENUMERATE: return 0;
				default: assert (0);
				}
			}
			INT FNFDIDECRYPT(FDIDECRYPT* pfdid) {
				return 0;
			}

			alias HFCI function (
			    ERF* perf,
			    typeof(&FNFCIFILEPLACED) pfnfiledest,
			    typeof(&FNFCIALLOC) pfnalloc,
			    typeof(&FNFCIFREE) pfnfree,
			    typeof(&FNFCIOPEN) pfnopen,
			    typeof(&FNFCIREAD) pfnread,
			    typeof(&FNFCIWRITE) pfnwrite,
			    typeof(&FNFCICLOSE) pfnclose,
			    typeof(&FNFCISEEK) pfnseek,
			    typeof(&FNFCIDELETE) pfndelete,
			    typeof(&FNFCIGETTEMPFILE) pfnfcigtf,
			    CCAB* pccab,
			    LPVOID pv
			) FCI_C;
			alias BOOL function (
				HFCI hfci,
				LPCSTR pszSourceFile,
				LPCSTR pszFileName,
				BOOL fExecute,
				typeof(&FNFCIGETNEXTCABINET) GetNextCab,
				typeof(&FNFCISTATUS) pfnProgress,
				typeof(&FNFCIGETOPENINFO) pfnOpenInfo,
				TCOMP typeCompress
			) FCI_A;
			alias BOOL function (
				HFCI hfci,
				BOOL fGetNextCab,
				typeof(&FNFCIGETNEXTCABINET) GetNextCab,
				typeof(&FNFCISTATUS) pfnProgress
			) FCI_F;
			alias BOOL function (HFCI hfci) FCI_D;

			alias HFDI function (
				typeof(&FNALLOC) pfnalloc,
				typeof(&FNFREE) pfnfree,
				typeof(&FNOPEN) pfnopen,
				typeof(&FNREAD) pfnread,
				typeof(&FNWRITE) pfnwrite,
				typeof(&FNCLOSE) pfnclose,
				typeof(&FNSEEK) pfnseek,
				INT cpuType,
				ERF* perf
			) FDI_C;
			alias BOOL function (
				HFDI hfdi,
				INT* hf,
				FDICABINETINFO* pfdici
			) FDI_I;
			alias BOOL function (
				HFDI hfdi,
				LPCSTR pszCabinet,
				LPCSTR pszCabPath,
				INT flags,
				typeof(&FNFDINOTIFY) pfnfdin,
				typeof(&FNFDIDECRYPT) pfnfdid,
				LPVOID pvUser
			) FDI_O;
			alias BOOL function (HFDI hfdi) FDI_D;
		}
	}

	private HFCI fciCreate(string cab) {
		CCAB ccab;
		ERF erf;
		ccab.szDisk[] = '\0';
		ccab.szCab[] = '\0';
		ccab.szCabPath[] = '\0';
		strcpy(ccab.szCab.ptr, toMBSz(cab));
		return FCICreate(&erf, &FNFCIFILEPLACED, &FNFCIALLOC, &FNFCIFREE, 
			&FNFCIOPEN, &FNFCIREAD, &FNFCIWRITE, &FNFCICLOSE, &FNFCISEEK, &FNFCIDELETE,
			&FNFCIGETTEMPFILE, &ccab, null);
	}
	private bool add(HFCI hfci, string file, string pathOnCab, TCOMP tcomp = tcompTYPE_MSZIP) {
		return FCIAddFile(hfci, toMBSz(nabs(file)), toMBSz(pathOnCab), FALSE,
			null, &FNFCISTATUS, &FNFCIGETOPENINFO, tcomp) != 0;
	}
	private bool flush(HFCI hfci) {
		return FCIFlushCabinet(hfci, false, null, &FNFCISTATUS) != 0;
	}
	private bool destroyFCI(HFCI hfci) {
		return FCIDestroy(hfci) != 0;
	}

	private HFDI fdiCreate() {
		ERF erf;
		return FDICreate(&FNALLOC, &FNFREE, &FNOPEN, &FNREAD, &FNWRITE, &FNCLOSE, &FNSEEK, cpuUNKNOWN, &erf);
	}
	private bool isCab(HFDI hfdi, string cab) {
		FDICABINETINFO info;
		auto h = CreateFileA(toMBSz(cab), GENERIC_READ, 0, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);
		if (h == INVALID_HANDLE_VALUE) return false;
		scope (exit) CloseHandle(h);
		return FDIIsCabinet(hfdi, cast(INT*) h, &info) != 0;
	}
	private bool copyFiles(HFDI hfdi, string cab, string dir, string delegate(string) expand = null) {
		cab = nabs(cab);
		dir = nabs(dir) ~ dirSeparator.idup;
		Prm prm;
		prm.dest = toMBSz(dir);
		prm.expand = expand;
		return FDICopy(hfdi, toMBSz(cab), "".ptr, 0, &FNFDINOTIFY, null, &prm) != 0;
	}
	private struct Prm {
		const(char)* dest = null;
		string delegate(string) expand = null;
		char* onExpand = null;
	}
	private bool destroyFDI(HFDI hfdi) {
		return FDIDestroy(hfdi) != 0;
	}

	private __gshared bool usable = false;

	private __gshared FCI_C FCICreate = null;
	private __gshared FCI_A FCIAddFile = null;
	private __gshared FCI_F FCIFlushCabinet = null;
	private __gshared FCI_D FCIDestroy = null;

	private __gshared FDI_C FDICreate = null;
	private __gshared FDI_I FDIIsCabinet = null;
	private __gshared FDI_O FDICopy = null;
	private __gshared FDI_D FDIDestroy = null;

	private __gshared bool init = false;
	private __gshared void* _cabinet = null;
	shared static this () {
		if (init) return;
		if (_cabinet) return;
		_cabinet = dlopen("cabinet.dll");
		if (_cabinet) {
			FCICreate = cast(FCI_C) dlsym(_cabinet, "FCICreate");
			if (!FCICreate) debugln("Not found: FCICreate");
			FCIAddFile = cast(FCI_A) dlsym(_cabinet, "FCIAddFile");
			if (!FCIAddFile) debugln("Not found: FCIAddFile");
			FCIFlushCabinet = cast(FCI_F) dlsym(_cabinet, "FCIFlushCabinet");
			if (!FCIFlushCabinet) debugln("Not found: FCIFlushCabinet");
			FCIDestroy = cast(FCI_D) dlsym(_cabinet, "FCIDestroy");
			if (!FCIDestroy) debugln("Not found: FCIDestroy");

			FDICreate = cast(FDI_C) dlsym(_cabinet, "FDICreate");
			if (!FDICreate) debugln("Not found: FDICreate");
			FDIIsCabinet = cast(FDI_I) dlsym(_cabinet, "FDIIsCabinet");
			if (!FDIIsCabinet) debugln("Not found: FDIIsCabinet");
			FDICopy = cast(FDI_O) dlsym(_cabinet, "FDICopy");
			if (!FDICopy) debugln("Not found: FDICopy");
			FDIDestroy = cast(FDI_D) dlsym(_cabinet, "FDIDestroy");
			if (!FDIDestroy) debugln("Not found: FDIDestroy");

			usable = true;
			init = true;
		} else {
			debugln("Not found: cabinet.dll");
		}
	}
	shared static ~this () {
		version (Console) {
			debug std.stdio.writeln("Release cabinet.dll Start");
		}
		if (_cabinet) {
			dlclose(_cabinet);
		}
		version (Console) {
			debug std.stdio.writeln("Release cabinet.dll Exit");
		}
	}

	/// 指定されたファイルが含まれているか。
	bool cabHasFile(string cab, string fileName) {
		if (!canUncab) return false;
		if (!.exists(cab)) return false;

		CFHEADER head;
		auto buf = new ubyte[CFHEADER.sizeof];

		try {
			auto stream = new BufferedFile(cab, FileMode.In);
			scope (exit) stream.close();
			if (buf.length != stream.read(buf)) {
				// Cabinetではない
				return false;
			}
			memcpy(&head, buf.ptr, buf.length);
			if ('M' != head.signature[0]) return false;
			if ('S' != head.signature[1]) return false;
			if ('C' != head.signature[2]) return false;
			if ('F' != head.signature[3]) return false;

			if (head.coffFiles != stream.seekSet(head.coffFiles)) {
				return false;
			}

			buf = new ubyte[CFFILE.sizeof];
			CFFILE fl;
			foreach (i; 0 .. head.cFiles) {
				if (buf.length != stream.read(buf)) {
					return false;
				}
				memcpy(&fl, buf.ptr, buf.length);
				char[] name;
				char c;
				stream.read(c);
				while ('\0' != c) {
					name ~= c;
					stream.read(c);
				}
				string utfName;
				if (fl.attribs & _A_NAME_IS_UTF) {
					utfName = .text(name);
				} else {
					utfName = touni(name);
				}
				if (.cfnmatch(fileName, utfName.baseName())) return true;
			}
		} catch (Exception e) {
			debugln(e);
		}
		return false;
	}

	extern (Windows) {
		private immutable _A_NAME_IS_UTF = 0x80;
		private struct CFHEADER {
			BYTE signature[4];
			DWORD reserved1;
			DWORD cbCabinet;
			DWORD reserved2;
			DWORD coffFiles;
			DWORD reserved3;
			BYTE versionMinor;
			BYTE versionMajor;
			WORD cFolders;
			WORD cFiles;
			WORD flags;
			WORD setID;
			WORD iCabinet;
		}
		private struct CFFILE {
			DWORD cbFile;
			DWORD uoffFolderStart;
			WORD iFolder;
			WORD date;
			WORD time;
			WORD attribs;
			BYTE szName[0];
		}
	}
} else {
	/// uncab()が行える状態であればtrueを返す。
	/// Windows以外のOSでは必ずfalseを返す。
	@property
	bool canUncab() {return false;}

	/// src以下のファイル・フォルダを全て圧縮し、CAB書庫cabを生成する。
	/// Windows以外のOSでは必ず失敗し、falseを返す。
	bool cab(string src, string cab, bool delegate(string) isArc = null) {
		return false;
	}
	/// CAB書庫fileをフォルダdestに展開する。
	/// Windows以外のOSでは必ず失敗し、falseを返す。
	bool uncab(string file, string dest, string delegate(string) expand = null) {
		return false;
	}

	/// 指定されたファイルが含まれているか。
	bool cabHasFile(string cab, string fileName) {
		return false;
	}
}

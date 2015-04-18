/// Win32のPEファイルからリソースを取得する。
/// 恐らくWin64でも有効。
module cwx.win32res;

import cwx.perf;

import std.algorithm;
import std.conv;
import std.exception;
import std.file;
import std.string;
import std.traits;
import std.utf;
version (Windows) {
	import core.sys.windows.windows;
	private extern (Windows) {
		immutable DWORD _LOAD_LIBRARY_AS_DATAFILE      = 0x2;
		immutable DWORD _LOAD_WITH_ALTERED_SEARCH_PATH = 0x8;
		HINSTANCE LoadLibraryExW(LPCWSTR, HANDLE, DWORD);
		HRSRC FindResourceW(HMODULE, LPCWSTR, LPCWSTR);
		DWORD SizeofResource(HMODULE, HRSRC);
		HGLOBAL LoadResource(HMODULE, HRSRC);
	}
}

@property
private ubyte[] le(T)(T val) if (isIntegral!T) {
	auto arr = new ubyte[T.sizeof];
	version(BigEndian) { mixin(S_TRACE);
		foreach_reverse (i; 0..T.sizeof) { mixin(S_TRACE);
			arr[i] = val & 0xFF;
			val >>>= 8;
		}
	} else { mixin(S_TRACE);
		foreach (i; 0..T.sizeof) { mixin(S_TRACE);
			arr[i] = val & 0xFF;
			val >>>= 8;
		}
	}
	return arr;
}

@property
private auto le(T)(in ubyte[] arr, size_t start = 0) { mixin(S_TRACE);
	version (BigEndian) {
		return cast(T)0.reduce!("cast(" ~ T.stringof ~ ")((a << 8) | b)")(arr[start..start+T.sizeof]);
	} else { mixin(S_TRACE);
		T t = 0;
		foreach (i; 0..T.sizeof) { mixin(S_TRACE);
			t |= arr[start+i] << i * 8;
		}
		return t;
	}
} unittest { mixin(S_TRACE);
	assert ([0x15, 0xcd, 0x5b, 0x07].le!uint == 123456789);
}

enum ResType {
	RT_CURSOR       = 1,
	RT_BITMAP       = 2,
	RT_ICON         = 3,
	RT_MENU         = 4,
	RT_DIALOG       = 5,
	RT_STRING       = 6,
	RT_FONTDIR      = 7,
	RT_FONT         = 8,
	RT_ACCELERATOR  = 9,
	RT_RCDATA       = 10,
	RT_MESSAGETABLE = 11,
	RT_GROUP_CURSOR = 12,
	RT_GROUP_ICON   = 14,
	RT_VERSION      = 16,
	RT_DLGINCLUDE   = 17,
	RT_PLUGPLAY     = 19,
	RT_VXD          = 20,
	RT_ANICURSOR    = 21,
	RT_ANIICON      = 22,
	RT_HTML         = 23,
	RT_MANIFEST     = 24,
}

struct ResID {
	private bool nameIsString;
	private string name;
	private uint id;

	private this(bool nameIsString, string name, uint id) {
		this.nameIsString = nameIsString;
		this.name = name;
		this.id = id;
	}

	this (string name) {
		this (true, name, 0x80000000);
	}
	this (uint id) {
		this (false, "", id);
	}
	this (ResType id) {
		this (false, "", id);
	}

	@property
	const
	const(wchar)* lpcwstr() { mixin(S_TRACE);
		if (nameIsString) { mixin(S_TRACE);
			return name.toUTFz!(wchar*)();
		} else { mixin(S_TRACE);
			return cast(typeof(return))id;
		}
	}

	const
	hash_t toHash() { mixin(S_TRACE);
		hash_t hash = 0;
		foreach (c; name) { mixin(S_TRACE);
			hash = hash * 37 + c;
		}
		hash = hash * 37 + id;
		return hash;
	}
	const
	bool opEquals(ref const ResID res) { mixin(S_TRACE);
		return nameIsString == res.nameIsString
			&& name == res.name
			&& id == res.id;
	}
	const
	int opCmp(ref const ResID res) { mixin(S_TRACE);
		if (nameIsString == res.nameIsString) { mixin(S_TRACE);
			return name.cmp(res.name);
		} else { mixin(S_TRACE);
			if (id < res.id) return -1;
			if (id > res.id) return 1;
			return 0;
		}
	}
	const
	string toString() { mixin(S_TRACE);
		if (nameIsString) { mixin(S_TRACE);
			return name;
		}
		if (ResType.min <= id && id <= ResType.max) { mixin(S_TRACE);
			return "%s(%d)".format(.text(cast(ResType)id), id);
		}
		return id.text();
	}
}

struct Win32Res {
	version (Windows) {
		private HINSTANCE _winhandle = null;
	}
	private const(ubyte)[][ResID][ResID] _table;

	this (string file) { mixin(S_TRACE);
		laodResModule(file);
	}
	~this () { mixin(S_TRACE);
		dispose();
	}

	void laodResModule(string file) { mixin(S_TRACE);
		dispose();

		version (Windows) {
			_winhandle = LoadLibraryExW(file.toUTFz!(wchar*)(), null,
				_LOAD_LIBRARY_AS_DATAFILE | _LOAD_WITH_ALTERED_SEARCH_PATH);
			if (_winhandle) return;
		}

		auto data = cast(const(ubyte)[])std.file.read(file);
		const base = data[];

		// MZ header
		.enforce("MZ" == data[0..2]);
		uint eLfanew = data[60..$].le!uint;
		data = data[eLfanew..$];

		// PE header
		.enforce("PE\0\0" == data[0..4]);
		data = data[4..$];
		auto numOfSec = data[2..$].le!ushort;
		auto sizeOfOptHead = data[16..$].le!ushort;
		data = data[20..$];

		// Resource section
		auto resAddrRVA = data[112..$].le!uint;
		data = data[sizeOfOptHead..$];
		uint resSize = 0;
		uint resAddr = 0;
		foreach (i; 0..numOfSec) { mixin(S_TRACE);
			auto rva = data[12..$].le!uint;
			if (".rsrc" == data[0..5] || resAddrRVA == rva) { mixin(S_TRACE);
				resAddrRVA = rva;
				resSize = data[16..$].le!uint;
				resAddr = data[20..$].le!uint;
				break;
			}
			data = data[40..$];
		}
		.enforce(resSize);
		data = base[resAddr..$];

		// IMAGE_RESOURCE_DIRECTORY (Frame 1)
		auto numberOfNameEntries = data[12..$].le!ushort;
		auto numberOfIDEntries = data[14..$].le!ushort;
		data = data[16..$];
		foreach (i; 0..numberOfNameEntries+numberOfIDEntries) { mixin(S_TRACE);
			// IMAGE_RESOURCE_DIRECTORY_ENTRY (Frame 1)
			auto w1 = data[0..$].le!uint;
			auto w2 = data[4..$].le!uint;
			data = data[8..$];
			auto name1 = resName(base, resAddr, w1);
			.enforce(w2 & 0x80000000);

			// IMAGE_RESOURCE_DIRECTORY (Frame 2)
			auto data2 = base[((w2 & ~0x80000000) + resAddr)..$];
			numberOfNameEntries = data2[12..$].le!ushort;
			numberOfIDEntries = data2[14..$].le!ushort;
			data2 = data2[16..$];
			foreach (j; 0..numberOfNameEntries+numberOfIDEntries) { mixin(S_TRACE);
				// IMAGE_RESOURCE_DIRECTORY_ENTRY (Frame 2)
				w1 = data2[0..$].le!uint;
				w2 = data2[4..$].le!uint;
				data2 = data2[8..$];
				auto name2 = resName(base, resAddr, w1);

				.enforce(w2 & 0x80000000);

				// IMAGE_RESOURCE_DIRECTORY (Frame 3)
				auto data3 = base[((w2 & ~0x80000000) + resAddr)..$];
				numberOfNameEntries = data3[12..$].le!ushort;
				numberOfIDEntries = data3[14..$].le!ushort;
				data3 = data3[16..$];
				.enforce(numberOfNameEntries + numberOfIDEntries == 1);

				// IMAGE_RESOURCE_DIRECTORY_ENTRY (Frame 3)
				// ignore w1
				w2 = data3[4..$].le!uint;
				.enforce(!(w2 & 0x80000000));

				// IMAGE_RESOURCE_DATA_ENTRY
				auto res = base[w2+resAddr..$];
				auto offsetToData = res[0..$].le!uint - resAddrRVA + resAddr;
				auto size = res[4..$].le!uint;

				auto resData = base[offsetToData..offsetToData+size];
				_table[name1][name2] = resData;
			}
		}
	}

	private static ResID resName(in ubyte[] base, uint resAddr, uint w1) { mixin(S_TRACE);
		if (w1 & 0x80000000) { mixin(S_TRACE);
			// Name is String
			auto offset = (w1 & ~0x80000000) + resAddr;
			auto len = base[offset..$].le!ushort;
			// wide chars
			auto wstr = cast(const(wchar)[])base[(offset+2)..(offset+2)+(len*2)];
			return ResID(wstr.text());
		} else { mixin(S_TRACE);
			// ID
			return ResID(w1);
		}
	}

	void dispose() { mixin(S_TRACE);
		_table = typeof(_table).init;
		version (Windows) {
			if (_winhandle) { mixin(S_TRACE);
				FreeLibrary(_winhandle);
				_winhandle = null;
			}
		}
	}

	const(ubyte)[] getRCData(in ResID type, in ResID name) { mixin(S_TRACE);
		version (Windows) {
			if (_winhandle) { mixin(S_TRACE);
				auto hsrc = FindResourceW(_winhandle, name.lpcwstr, type.lpcwstr);
				if (!hsrc) return null;
				auto size = SizeofResource(_winhandle, hsrc);
				.enforce(size);
				auto hglobal = LoadResource(_winhandle, hsrc);
				.enforce(hglobal);
				auto p = LockResource(hglobal);
				.enforce(p);
				return (cast(ubyte*)p)[0..size].dup;
			}
		}
		return _table.get(type, typeof(_table[ResID("")]).init).get(name, null);
	}

	const(ubyte)[] getBitmap(in ResID name) { mixin(S_TRACE);
		static immutable BITMAPFILEHEADER_SIZE = 14;
		static immutable RGBQUAD_SIZE = 4;

		auto data = getRCData(ResID(ResType.RT_BITMAP), name);
		if (!data) return null;

		// BITMAPINFOHEADER
		auto headerSize = data[0..$].le!uint;
		.enforce(headerSize == 40);
		auto bitCount = data[14..$].le!ushort;
		auto clrUsed = data[32..$].le!uint;

		// calclates data offset
		if (0 == clrUsed) { mixin(S_TRACE);
			switch (bitCount) {
			case 1:
				headerSize += RGBQUAD_SIZE * (0x01 << 1);
				break;
			case 4:
				headerSize += RGBQUAD_SIZE * (0x01 << 4);
				break;
			case 8:
				headerSize += RGBQUAD_SIZE * (0x01 << 8);
				break;
			default:
				.enforce(false);
			}
		} else { mixin(S_TRACE);
			headerSize += RGBQUAD_SIZE * clrUsed;
		}
		headerSize += BITMAPFILEHEADER_SIZE;
		uint size = cast(uint)(BITMAPFILEHEADER_SIZE + data.length); // file size

		// BITMAPFILEHEADER
		auto header = cast(ubyte[])['B', 'M'] ~ size.le ~ 0.le!ushort ~ 0.le!ushort ~ headerSize.le;
		assert (header.length == BITMAPFILEHEADER_SIZE);

		return header ~ data;
	}
}

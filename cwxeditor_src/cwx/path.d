
module cwx.path;

import cwx.perf;

import std.algorithm;
import std.array;
import std.conv;
import std.string;
import std.typecons : rebindable;

/// 複数のCWXパスを列挙する際のセパレータ。
immutable CWXPATH_SEP = "&";

/// 不正なCWXパス。
immutable INVALID_CWX_PATH = "InvalidCWXPath";

/// シナリオ内パスを取得できるオブジェクトである事を示す。
interface CWXPath {
	/// シナリオ内パス。
	@property
	string cwxPath(bool id);
	/// パスが示すオブジェクトを返す。
	/// 見つからない場合はnullを返す。
	CWXPath findCWXPath(string);
	/// 直下のパスを全て返す。
	@property
	inout
	inout(CWXPath)[] cwxChilds();
	/// 親を返す。
	@property
	CWXPath cwxParent();

	/// 変更を通知する。
	protected void changed();
}

/// シナリオ内パスを結合する。
string cpjoin(CWXPath owner, size_t index, bool id) { mixin(S_TRACE);
	return cpjoin(owner, "", index, id);
}
/// ditto
string cpjoin(CWXPath owner, string category, size_t index, bool id) { mixin(S_TRACE);
	return cpjoin(owner.cwxPath(id), category, index);
}
/// ditto
string cpjoin(CWXPath owner, string name, bool id) { mixin(S_TRACE);
	auto ocp = owner.cwxPath(id);
	return ocp.length ? ocp ~ "/" ~ name : name;
}
/// ditto
string cpjoinid(CWXPath owner, ulong id) { mixin(S_TRACE);
	return cpjoinid(owner, "", id);
}
/// ditto
string cpjoinid(CWXPath owner, string category, ulong id) { mixin(S_TRACE);
	return cpjoinid(owner.cwxPath(true), category, id);
}
/// ditto
string cpjoin(string ownerPath, string category, size_t index) { mixin(S_TRACE);
	string cn = category ~ ":" ~ to!(string)(index);
	return ownerPath.length ? ownerPath ~ "/" ~ cn : cn;
}
/// ditto
string cpjoinid(string ownerPath, string category, ulong id) { mixin(S_TRACE);
	string cn = category ~ ":id:" ~ to!(string)(id);
	return ownerPath.length ? ownerPath ~ "/" ~ cn : cn;
}
/// ditto
string cpjoin(string ownerPath, string subPath) { mixin(S_TRACE);
	return ownerPath.length ? ownerPath ~ "/" ~ subPath : subPath;
}

/// シナリオ内パスの属性を返す。
string[] cpattr(string path) { mixin(S_TRACE);
	string[] attrs;
	while (true) { mixin(S_TRACE);
		ptrdiff_t index = std.string.lastIndexOf(path, ";");
		if (-1 == index) break;
		attrs ~= path[index + 1 .. $];
		path = path[0 .. index];
	}
	return attrs;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	string path = "area:3/event:0/:5/:0/:1;shallow;deep";
	assert (std.algorithm.sort(cpattr(path)).array() == ["deep", "shallow"]);
	path = "area:3/event:0/:5/:0/:1";
	assert (cpattr(path) == []);
}

/// シナリオ内パスの属性部分をデリミタつきで返す。
/// pathは属性以外の部分に切り詰められる。
private string cpattrRef(ref string path) { mixin(S_TRACE);
	ptrdiff_t index = std.string.indexOf(path, ";");
	if (-1 == index) { mixin(S_TRACE);
		return "";
	}
	string attr = path[index .. $];
	path = path[0 .. index];
	return attr;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	string path = "area:3/event:0/:5/:0/:1;shallow;deep";
	assert (cpattrRef(path) == ";shallow;deep");
	assert (path == "area:3/event:0/:5/:0/:1");
	path = "area:3/event:0/:5/:0/:1";
	assert (cpattrRef(path) == "");
	assert (path == "area:3/event:0/:5/:0/:1");
}

/// シナリオ内パスの属性以外の部分を返す。
string cpbody(string path) { mixin(S_TRACE);
	ptrdiff_t index = std.string.indexOf(path, ";");
	if (-1 != index) { mixin(S_TRACE);
		return path[0 .. index];
	}
	return path;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	string path = "area:3/event:0/:5/:0/:1;shallow;deep";
	assert (cpbody(path) == "area:3/event:0/:5/:0/:1");
	path = "area:3/event:0/:5/:0/:1";
	assert (cpbody(path) == "area:3/event:0/:5/:0/:1");
}
/// シナリオ内パスに属性を追加する。
string cpaddattr(string path, string attr) { mixin(S_TRACE);
	return path ~ ";" ~ attr;
}

/// シナリオ内パスに指定された属性が含まれているか。
bool cphasattr(string path, string attr) { mixin(S_TRACE);
	return 0 < cpattr(path).find(attr).length;
}

/// シナリオ内パスを属性を除いて比較する。
bool cpeq(string path1, string path2) { mixin(S_TRACE);
	return cpbody(path1) == cpbody(path2);
}

/// シナリオ内パスの属性以外が空であればtrueを返す。
bool cpempty(string path) { mixin(S_TRACE);
	if ("" == path) return true;
	ptrdiff_t index = std.string.indexOf(path, ";");
	return 0 == index;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (cpempty(""));
	assert (cpempty(";shallow;deep"));
	assert (!cpempty("area:3"));
	assert (!cpempty("area:3;shallow;deep"));
}

/// シナリオ内パスを一つ上の部分を返す。
string cpparent(string path) { mixin(S_TRACE);
	string attrs = cpattrRef(path);
	ptrdiff_t index = std.string.lastIndexOf(path, "/");
	return (index >= 0 ? path[0 .. index] : "") ~ attrs;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (cpparent("area:3/event:0/:5/:0/:1") == "area:3/event:0/:5/:0");
}

/// シナリオ内パスの先頭部分を返す。
string cptop(string path) { mixin(S_TRACE);
	string attrs = cpattrRef(path);
	ptrdiff_t index = std.string.indexOf(path, "/");
	return (index >= 0 ? path[0 .. index] : path) ~ attrs;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (cptop("area:3/event:0/:5/:0/:1") == "area:3");
}
/// シナリオ内パスの先頭部分以外を返す。
string cpbottom(string path) { mixin(S_TRACE);
	string attrs = cpattrRef(path);
	ptrdiff_t index = std.string.indexOf(path, "/");
	return (index >= 0 ? path[index + 1 .. $] : "") ~ attrs;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (cpbottom("area:3/event:0/:5/:0/:1") == "event:0/:5/:0/:1");
}
/// シナリオ内パスの先頭のカテゴリを返す。
string cpcategory(string path) { mixin(S_TRACE);
	string top = cpbody(cptop(path));
	ptrdiff_t index = std.string.lastIndexOf(top, ":");
	return index >= 0 ? top[0 .. index] : top;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (cpcategory("area:3/event:0/:5/:0/:1") == "area");
}
/// シナリオ内パスの先頭のindexを返す。
size_t cpindex(string path) { mixin(S_TRACE);
	string top = cpbody(cptop(path));
	ptrdiff_t index = std.string.lastIndexOf(top, ":");
	return index >= 0 ? to!(size_t)(top[index + 1 .. $]) : 0;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (cpindex("area:3/event:0/:5/:0/:1") == 3);
}
/// シナリオ内パスの末尾部分を返す。
string cplast(string path) { mixin(S_TRACE);
	string attrs = cpattrRef(path);
	ptrdiff_t index = std.string.lastIndexOf(path, "/");
	return (index >= 0 ? path[index + 1 .. $] : path) ~ attrs;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (cptop("area:3/event:0/:5/:0/:1") == "area:3");
}
/// path1がpath2そのもの、
/// もしくはpath2がpath1の子孫であればtrueを返す。
bool cpdescendant(string path1, string path2) { mixin(S_TRACE);
	return cpbody(path2).startsWith(cpbody(path1));
}

/// pathがancestorの子孫であれば相対パスを返す。
/// それ以外の場合は空文字列を返す。
string cprel(string path, string ancestor) { mixin(S_TRACE);
	if (path.startsWith(ancestor) && ancestor.length + 1 < path.length) { mixin(S_TRACE);
		return path[ancestor.length + 1 .. $];
	}
	return "";
}

/// 最上位のリソースを返す。
/// cwxPathがシナリオに属している場合は、通常Summaryになる。
CWXPath cwxTop(CWXPath cwxPath) { mixin(S_TRACE);
	while (cwxPath) { mixin(S_TRACE);
		auto parent = cwxPath.cwxParent;
		if (!parent) return cwxPath;
		cwxPath = parent;
	}
	return cwxPath;
}

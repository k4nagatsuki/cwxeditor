
module cwx.path;

import cwx.utils;

import std.conv;
import std.string;

/// 複数のCWXパスを列挙する際のセパレータ。
immutable CWXPATH_SEP = "&";

/// シナリオ内パスを取得できるオブジェクトである事を示す。
interface CWXPath {
	/// シナリオ内パス。
	string cwxPath();
	/// パスが示すオブジェクトを返す。
	/// 見つからない場合はnullを返す。
	CWXPath findCWXPath(string);
	/// 直下のパスを全て返す。
	CWXPath[] cwxChilds();
}

/// シナリオ内パスを結合する。
string cpjoin(CWXPath owner, int index) {
	return cpjoin(owner, "", index);
}
/// ditto
string cpjoin(CWXPath owner, string category, int index) {
	auto ocp = owner.cwxPath;
	string cn;
	cn = category ~ ":" ~ to!(string)(index);
	return ocp.length ? ocp ~ "/" ~ cn : cn;
}
/// ditto
string cpjoin(CWXPath owner, string name) {
	auto ocp = owner.cwxPath;
	return ocp.length ? ocp ~ "/" ~ name : name;
}

/// シナリオ内パスの属性を返す。
string[] cpattr(string path) {
	string[] attrs;
	while (true) {
		int index = std.string.lastIndexOf(path, ";");
		if (-1 == index) break;
		attrs ~= path[index + 1 .. $];
		path = path[0 .. index];
	}
	return attrs;
} unittest {
	string path = "area:3/event:0/:5/:0/:1;shallow;deep";
	assert (cpattr(path).sort == ["deep", "shallow"]);
	path = "area:3/event:0/:5/:0/:1";
	assert (cpattr(path) == []);
}

/// シナリオ内パスの属性部分をデリミタつきで返す。
/// pathは属性以外の部分に切り詰められる。
private string cpattrRef(ref string path) {
	int index = std.string.indexOf(path, ";");
	if (-1 == index) {
		return "";
	}
	string attr = path[index .. $];
	path = path[0 .. index];
	return attr;
} unittest {
	string path = "area:3/event:0/:5/:0/:1;shallow;deep";
	assert (cpattrRef(path) == ";shallow;deep");
	assert (path == "area:3/event:0/:5/:0/:1");
	path = "area:3/event:0/:5/:0/:1";
	assert (cpattrRef(path) == "");
	assert (path == "area:3/event:0/:5/:0/:1");
}

/// シナリオ内パスの属性以外の部分を返す。
string cpbody(string path) {
	int index = std.string.indexOf(path, ";");
	if (-1 != index) {
		return path[0 .. index];
	}
	return path;
} unittest {
	string path = "area:3/event:0/:5/:0/:1;shallow;deep";
	assert (cpbody(path) == "area:3/event:0/:5/:0/:1");
	path = "area:3/event:0/:5/:0/:1";
	assert (cpbody(path) == "area:3/event:0/:5/:0/:1");
}
/// シナリオ内パスに属性を追加する。
string cpaddattr(string path, string attr) {
	return path ~ ";" ~ attr;
}

/// シナリオ内パスに指定された属性が含まれているか。
bool cphasattr(string path, string attr) {
	return cpattr(path).contains(attr);
}

/// シナリオ内パスを属性を除いて比較する。
bool cpeq(string path1, string path2) {
	return cpbody(path1) == cpbody(path2);
}

/// シナリオ内パスの属性以外が空であればtrueを返す。
bool cpempty(string path) {
	if ("" == path) return true;
	int index = std.string.indexOf(path, ";");
	return 0 == index;
} unittest {
	assert (cpempty(""));
	assert (cpempty(";shallow;deep"));
	assert (!cpempty("area:3"));
	assert (!cpempty("area:3;shallow;deep"));
}

/// シナリオ内パスを一つ上の部分を返す。
string cpparent(string path) {
	string attrs = cpattrRef(path);
	int index = std.string.lastIndexOf(path, "/");
	return (index >= 0 ? path[0 .. index] : "") ~ attrs;
} unittest {
	assert (cpparent("area:3/event:0/:5/:0/:1") == "area:3/event:0/:5/:0");
}

/// シナリオ内パスの先頭部分を返す。
string cptop(string path) {
	string attrs = cpattrRef(path);
	int index = std.string.indexOf(path, "/");
	return (index >= 0 ? path[0 .. index] : path) ~ attrs;
} unittest {
	assert (cptop("area:3/event:0/:5/:0/:1") == "area:3");
}
/// シナリオ内パスの先頭部分以外を返す。
string cpbottom(string path) {
	string attrs = cpattrRef(path);
	int index = std.string.indexOf(path, "/");
	return (index >= 0 ? path[index + 1 .. $] : "") ~ attrs;
} unittest {
	assert (cpbottom("area:3/event:0/:5/:0/:1") == "event:0/:5/:0/:1");
}
/// シナリオ内パスの先頭のカテゴリを返す。
string cpcategory(string path) {
	string top = cpbody(cptop(path));
	int index = std.string.lastIndexOf(top, ":");
	return index >= 0 ? top[0 .. index] : top;
} unittest {
	assert (cpcategory("area:3/event:0/:5/:0/:1") == "area");
}
/// シナリオ内パスの先頭のindexを返す。
size_t cpindex(string path) {
	string top = cpbody(cptop(path));
	int index = std.string.lastIndexOf(top, ":");
	return index >= 0 ? to!(size_t)(top[index + 1 .. $]) : 0;
} unittest {
	assert (cpindex("area:3/event:0/:5/:0/:1") == 3);
}
/// path1がpath2そのもの、
/// もしくはpath2がpath1の子孫であればtrueを返す。
bool cpdescendant(string path1, string path2) {
	return cpbody(path2).startsWith(cpbody(path1));
}

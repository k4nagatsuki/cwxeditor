
module cwx.path;

import cwx.utils;

import std.conv;
import std.string;

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

/// シナリオ内パスを一つ上の部分を返す。
string cpparent(string path) {
	int index = std.string.lastIndexOf(path, "/");
	return index >= 0 ? path[0 .. index] : "";
} unittest {
	assert (cpparent("area:3/event:0/:5/:0/:1") == "area:3/event:0/:5/:0");
}

/// シナリオ内パスの先頭部分を返す。
string cptop(string path) {
	int index = std.string.indexOf(path, "/");
	return index >= 0 ? path[0 .. index] : path;
} unittest {
	assert (cptop("area:3/event:0/:5/:0/:1") == "area:3");
}
/// シナリオ内パスの先頭部分以外を返す。
string cpbottom(string path) {
	int index = std.string.indexOf(path, "/");
	return index >= 0 ? path[index + 1 .. $] : "";
} unittest {
	assert (cpbottom("area:3/event:0/:5/:0/:1") == "event:0/:5/:0/:1");
}
/// シナリオ内パスの先頭のカテゴリを返す。
string cpcategory(string path) {
	string top = cptop(path);
	int index = std.string.lastIndexOf(top, ":");
	return index >= 0 ? top[0 .. index] : top;
} unittest {
	assert (cpcategory("area:3/event:0/:5/:0/:1") == "area");
}
/// シナリオ内パスの先頭のindexを返す。
size_t cpindex(string path) {
	string top = cptop(path);
	int index = std.string.lastIndexOf(top, ":");
	return index >= 0 ? to!(size_t)(top[index + 1 .. $]) : 0;
} unittest {
	assert (cpindex("area:3/event:0/:5/:0/:1") == 3);
}
/// path1がpath2そのもの、
/// もしくはpath2がpath1の子孫であればtrueを返す。
bool cpdescendant(string path1, string path2) {
	return path2.startsWith(path1);
}

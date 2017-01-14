
module cwx.enumutils;

import cwx.perf;

import std.ascii;
import std.conv;
import std.exception;
import std.traits;
import std.uni;

/// Enumメンバ名の先頭を小文字にして文字列に変換する。
@safe
pure
string enumToString(E)(E e) {
	mixin("final switch (e) {"
		~ enumToStringImpl!(E, 0)
		~ "}");
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	enum En {
		Abc, Def
	}
	assert (enumToString(En.Abc) == "abc");
	assert (enumToString(En.Def) == "def");
}
private template enumToStringImpl(E, size_t Index) {
	static if (EnumMembers!E.length <= Index) {
		immutable enumToStringImpl = "";
	} else {
		immutable enumToStringImpl = "case E." ~ .text(EnumMembers!E[Index])
			~ ": return `" ~ .capLower(.text(EnumMembers!E[Index])) ~ "`;"
			~ enumToStringImpl!(E, Index + 1);
	}
}

/// 先頭を小文字にしたEnumメンバ名文字列をEnum値に変換する。
@safe
pure
E stringToEnum(E)(string name) {
	mixin("switch (name) {"
		~ stringToEnumImpl!(E, 0)
		~ "default: return E.init;"
		~ "}");
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	enum En {
		Abc, Def
	}
	assert (stringToEnum!En("abc") == En.Abc);
	assert (stringToEnum!En("def") == En.Def);
}
private template stringToEnumImpl(E, size_t Index) {
	static if (EnumMembers!E.length <= Index) {
		immutable stringToEnumImpl = "";
	} else {
		immutable stringToEnumImpl = "case `" ~ .capLower(.text(EnumMembers!E[Index])) ~ "`:"
			~ "return E." ~ .text(EnumMembers!E[Index]) ~ ";"
			~ stringToEnumImpl!(E, Index + 1);
	}
}

/// enumのメンバ毎のメソッド呼出のswitch文を生成する。
template EnumToStringSwitch2(E, string EName, string Prefix) {
	immutable EnumToStringSwitch2 = "final switch (id) {\n"
		~ EnumToStringCase!(E, EName, Prefix, 0)
		~ "}";
}
/// ditto
template EnumToStringSwitch(E, string Prefix) {
	immutable EnumToStringSwitch = EnumToStringSwitch2!(E, E.stringof, Prefix);
}
/// switch文でenumのメンバ毎のメソッド呼出のメソッドを生成する。
template EnumToStringMethod2(E, string EName, string MethodName, string Prefix) {
	immutable EnumToStringMethod2 = "const string " ~ MethodName ~ "(" ~ EName ~ " id) {\n"
		~ "\tfinal switch (id) {\n"
		~ EnumToStringCase!(E, EName, Prefix, 0)
		~ "\t}\n"
		~ "}";
}
/// ditto
template EnumToStringMethod(E, string MethodName, string Prefix) {
	immutable EnumToStringMethod = EnumToStringMethod2!(E, E.stringof, MethodName, Prefix);
}
private template EnumToStringCase(E, string EName, string Prefix, size_t Index) {
	private import std.traits;
	private import std.conv;
	private immutable Case = "\tcase " ~ EName ~ "." ~ to!string(EnumMembers!E[Index]) ~ ": return " ~ Prefix ~ .upperToCap(std.conv.text(EnumMembers!E[Index])) ~ ";\n";
	static if (Index + 1 < EnumMembers!E.length) {
		immutable EnumToStringCase = Case ~ EnumToStringCase!(E, EName, Prefix, Index + 1);
	} else {
		immutable EnumToStringCase = Case;
	}
}

/// 文字列がすべて大文字の形式であれば単語の始まりのみ大文字の形式に変更する。
string upperToCap(string s) {
	if (!s.length) return s;
	bool isCap = true;
	foreach (c; s) {
		if (std.ascii.isLower(c)) {
			isCap = false;
			break;
		}
	}
	if (!isCap) return s;

	bool ul = true;
	char[] buf;
	foreach (i, c; s) {
		if (ul) {
			buf ~= c;
			ul = false;
		} else if ('_' == c) {
			ul = true;
		} else {
			buf ~= std.ascii.toLower(c);
		}
	}
	return .assumeUnique(buf);
} unittest { mixin(S_TRACE);
	assert (upperToCap("UPPER_TO_CAP") == "UpperToCap");
	assert (upperToCap("UpperToCap") == "UpperToCap");
}

/// sの先頭1文字を小文字にする。
string capLower(string s) {
	if (!s.length) return s;
	dstring ds = to!dstring(s);
	return to!string([std.uni.toLower(ds[0])] ~ ds[1 .. $]);
}
/// sの先頭1文字を大文字にする。
string capUpper(string s) { mixin(S_TRACE);
	if (!s.length) return s;
	dstring ds = to!dstring(s);
	return to!string([std.uni.toUpper(ds[0])] ~ ds[1 .. $]);
}

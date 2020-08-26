
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
	auto name = e.text();
	return std.ascii.toLower(name[0]) ~ name[1 .. $];
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	enum En {
		Abc, Def
	}
	assert (enumToString(En.Abc) == "abc");
	assert (enumToString(En.Def) == "def");
}

/// 先頭を小文字にしたEnumメンバ名文字列をEnum値に変換する。
@safe
pure
E stringToEnum(E)(string name) {
	return .to!E(std.ascii.toUpper(name[0]) ~ name[1 .. $]);
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	enum En {
		Abc, Def
	}
	assert (stringToEnum!En("abc") == En.Abc);
	assert (stringToEnum!En("def") == En.Def);
}

/// enumのメンバ毎のメソッド呼出のswitch文を生成する。
template EnumToStringSwitch2(E, string EName, string Prefix, string ValueName = "") {
	immutable EnumToStringSwitch2 = "final switch (id) {\n"
		~ (ValueName == "" ? EnumToStringCase!(E, EName, Prefix, 0) : EnumToStringCaseSet!(E, EName, Prefix, ValueName, 0))
		~ "}";
}
/// ditto
template EnumToStringSwitch(E, string Prefix, string ValueName = "") {
	immutable EnumToStringSwitch = EnumToStringSwitch2!(E, E.stringof, Prefix, ValueName);
}
/// switch文でenumのメンバ毎のメソッド呼出のメソッドを生成する。
template EnumToStringMethod2(E, string EName, string MethodName, string Prefix, string ValueName = "") {
	immutable EnumToStringMethod2 = "const string " ~ MethodName ~ "(" ~ EName ~ " id) {\n"
		~ "\tfinal switch (id) {\n"
		~ (ValueName == "" ? EnumToStringCase!(E, EName, Prefix, 0) : EnumToStringCaseSet!(E, EName, Prefix, ValueName, 0))
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
	private immutable Case = "\tcase " ~ EName ~ "." ~ to!string(EnumMembers!E[Index]) ~ ": return " ~ Prefix ~ std.conv.text(EnumMembers!E[Index]) ~ ";\n";
	static if (Index + 1 < EnumMembers!E.length) {
		immutable EnumToStringCase = Case ~ EnumToStringCase!(E, EName, Prefix, Index + 1);
	} else {
		immutable EnumToStringCase = Case;
	}
}
private template EnumToStringCaseSet(E, string EName, string Prefix, string ValueName, size_t Index) {
	private import std.traits;
	private import std.conv;
	private immutable Case = "\tcase " ~ EName ~ "." ~ to!string(EnumMembers!E[Index]) ~ ": " ~ Prefix ~ std.conv.text(EnumMembers!E[Index]) ~ " = " ~ ValueName ~ "; break;\n";
	static if (Index + 1 < EnumMembers!E.length) {
		immutable EnumToStringCaseSet = Case ~ EnumToStringCaseSet!(E, EName, Prefix, ValueName, Index + 1);
	} else {
		immutable EnumToStringCaseSet = Case;
	}
}

/// enum定義Eの分だけ CreateString(member) で定義されるメンバを生成する。
template EnumToMembers(E, alias CreateString) {
	private static template EnumToMember(E, alias CreateString, size_t Index) {
		private import std.traits;
		private import std.conv;
		private immutable Member = CreateString(std.traits.EnumMembers!E[Index]);
		static if (Index + 1 < std.traits.EnumMembers!E.length) {
			immutable EnumToMember = Member ~ EnumToMember!(E, CreateString, Index + 1);
		} else {
			immutable EnumToMember = Member;
		}
	}
	mixin(EnumToMember!(E, CreateString, 0));
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

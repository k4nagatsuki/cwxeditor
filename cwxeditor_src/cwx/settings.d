
module cwx.settings;

import cwx.perf;
import cwx.utils : printStackTrace, debugln;
import cwx.xml;

static import std.algorithm;
import std.conv;
import std.string;
import std.file;
import std.path;
import std.utf;
import std.datetime;
import std.traits;

private void toNode(T)(ref XNode node, string key, in T value) {
	import cwx.utils;
	static if (is(typeof({ value.toNode(node, key); }))) {
		value.toNode(node, key);
	} else static if (is(typeof(value.toNode))) {
		value.toNode(node);
	} else static if (isVArray!(T)) {
		auto e = node.newElement(key);
		foreach (v; value) {
			static if (is(typeof(v.toNode))) {
				v.toNode(e);
			} else {
				e.newElement("value", to!(string)(v));
			}
		}
	} else {
		node.newElement(key, to!(string)(value));
	}
}
private void fromNode(T)(ref XNode node, string key, ref T value) {
	import cwx.utils;
	static if (is(typeof(value.fromNode))) {
		value.fromNode(node);
	} else static if (isVArray!(T)) {
		value = [];
		node.onTag[null] = (ref XNode v) {
			static if (is(typeof(value[0].fromNode))) {
				typeof(value[0]) val;
				val.fromNode(v);
				value ~= val;
			} else {
				value ~= to!(typeof(value[0]))(v.value);
			}
		};
		node.parse();
	} else {
		value = to!(T)(node.value);
	}
}

/// T型のプロパティ。
struct Prop(T, bool ReadOnly = false, bool LayoutValue = false) {
	const string KEY;
	T INIT;
	static immutable bool READ_ONLY = ReadOnly;
	static if (LayoutValue) {
		static immutable bool LAYOUT_VALUE = LayoutValue;
	}
	const ulong CHG_VERSION;

	T value;
	alias value this;
	bool readValue = false;
	void opAssign(T value) {
		this.value = value;
	}

	this (string pkey, T firstValue, ulong chgVersion = 0) {
		KEY = pkey;
		INIT = firstValue;
		value = firstValue;
		CHG_VERSION = chgVersion;
	}

	const
	void toNode(ref XNode node) {
		.toNode(node, KEY, value);
	}
	void fromNode(ref XNode node, ulong dataVersion) {
		if (CHG_VERSION <= dataVersion) {
			.fromNode(node, KEY, value);
			readValue = true;
		}
	}
}
/// ditto
struct PropAttr(T, bool ReadOnly = false, bool LayoutValue = false) {
	const string ATTR_KEY;
	T INIT;
	static immutable bool READ_ONLY = ReadOnly;
	static if (LayoutValue) {
		static immutable bool LAYOUT_VALUE = LayoutValue;
	}
	const ulong CHG_VERSION;

	T value;
	alias value this;
	bool readValue = false;

	this (string pkey, T firstValue, ulong chgVersion = 0) {
		ATTR_KEY = pkey;
		INIT = firstValue;
		value = firstValue;
		CHG_VERSION = chgVersion;
	}

	const
	void toNode(ref XNode node) {
		.toNode(node, ATTR_KEY, value);
	}
	void fromNode(ref XNode node, ulong dataVersion) {
		if (CHG_VERSION <= dataVersion) {
			.fromNode(node, ATTR_KEY, value);
			readValue = true;
		}
	}
}
/// KeyとValueからなる連想配列のプロパティ。
struct AAProp(Key, Value) {
	immutable string AA_KEY;
	immutable string KEY_NAME;
	immutable string VALUE_NAME;
	immutable ulong CHG_VERSION;

	Value[Key] value;
	alias value this;

	this (string pkey, string keyName, string valueName, ulong chgVersion = 0) {
		AA_KEY = pkey;
		KEY_NAME = keyName;
		VALUE_NAME = valueName;
		CHG_VERSION = chgVersion;
	}

	const
	void toNode(ref XNode node) {
		auto e = node.newElement(AA_KEY);
		foreach (key; std.algorithm.sort(value.keys)) {
			auto c = e.newElement(VALUE_NAME, to!string(value[key]));
			c.newAttr(KEY_NAME, key);
		}
	}
	void fromNode(ref XNode node, ulong dataVersion) {
		if (CHG_VERSION <= dataVersion) {
			node.onTag[VALUE_NAME] = (ref XNode e) {
				auto key = e.attr!string(KEY_NAME, false, null);
				if (key !is null) {
					value[key] = to!Value(e.value);
				}
			};
			node.parse();
		}
	}
}
private struct PropValue(T) {
	immutable string KEY;
	immutable T INIT;
	immutable bool READ_ONLY;
	immutable ulong CHG_VERSION;

	T value;

	this (string pkey, T firstValue, immutable(T) defaultValue, bool readOnly, ulong chgVersion) {
		KEY = pkey;
		INIT = defaultValue;
		value = firstValue;
		READ_ONLY = readOnly;
		CHG_VERSION = chgVersion;
	}

	const
	void toNode(ref XNode node) {
		.toNode(node, KEY, value);
	}
	void fromNode(ref XNode node, ulong dataVersion) {
		if (CHG_VERSION <= dataVersion) {
			.fromNode(node, KEY, value);
		}
	}
}
private struct PropValueAttr(T) {
	immutable string ATTR_KEY;
	immutable T INIT;
	immutable bool READ_ONLY;
	immutable ulong CHG_VERSION;

	T value;

	this (string pkey, T firstValue, immutable(T) defaultValue, bool readOnly, ulong chgVersion) {
		ATTR_KEY = pkey;
		INIT = defaultValue;
		value = firstValue;
		READ_ONLY = readOnly;
		CHG_VERSION = chgVersion;
	}

	const
	void toNode(ref XNode node) {
		.toNode(node, ATTR_KEY, value);
	}
	void fromNode(ref XNode node, ulong dataVersion) {
		if (CHG_VERSION <= dataVersion) {
			.fromNode(node, ATTR_KEY, value);
		}
	}
}
private struct AAProperty(Key, Value) {
	immutable string AA_KEY;
	immutable string KEY_NAME;
	immutable string VALUE_NAME;
	immutable ulong CHG_VERSION;

	Value[Key] value;

	this (string pkey, string keyName, string valueName, ulong chgVersion) {
		AA_KEY = pkey;
		KEY_NAME = keyName;
		VALUE_NAME = valueName;
		CHG_VERSION = chgVersion;
	}

	const
	void toNode(ref XNode node) {
		auto e = node.newElement(AA_KEY);
		foreach (key; value.keys.sort) {
			auto c = e.newElement(VALUE_NAME, to!string(value[key]));
			c.newAttr(KEY_NAME, key);
		}
	}
	void fromNode(ref XNode node, ulong dataVersion) {
		if (CHG_VERSION <= dataVersion) {
			node.onTag[VALUE_NAME] = (ref XNode e) {
				auto key = e.attr!string(KEY_NAME, false, null);
				if (key !is null) {
					value[key] = to!Value(e.value);
				}
			};
			node.parse();
		}
	}
}

/// Propertyを持つためのクラス。
abstract class Properties {
	/// mixinによってプロパティの値と値を設定/取得する関数を生成する。
	/// 例えば:
	/// ---
	/// mixin Property!("width", int, 100);
	/// ---
	/// 以上によって、以下のフィールドと関数が生成される。
	/// ---
	/// private final PropValue!("width", int, 100) _width;
	/// int width() {
	/// 	return _width.value;
	/// }
	/// void width(int value) {
	/// 	_width.value = value;
	/// }
	/// ---
	/// Params:
	/// Name = プロパティ名。
	/// VType = プロパティの型。
	/// Default = プロパティのデフォルト値。
	protected template Property(string Name, VType, VType Default, bool ReadOnly = false, ulong ChgVersion = 0) {
		private import cwx.xml;
		private import cwx.utils;
		mixin("private PropValue!(VType) _" ~ Name ~ " = PropValue!(VType)(Name, Default, Default, ReadOnly, ChgVersion);");
		mixin("@property const const(VType) " ~ variableName!Name ~ "() { return _" ~ Name ~ ".value; }");
		mixin("@property const const(VType) " ~ Name ~ "_init() { return Default; }");
		static if (!ReadOnly) {
			mixin("@property void " ~ variableName!Name ~ "(VType value) { _" ~ Name ~ ".value = value; }");
		}
	}
	/// Propertyと同様だが、XML化の際は属性として扱われる。
	protected template PropertyAttr(string Name, VType, VType Default, bool ReadOnly = false, ulong ChgVersion = 0) {
		private import cwx.xml;
		private import cwx.utils;
		mixin("private PropValueAttr!(VType) _" ~ Name ~ " = PropValueAttr!(VType)(Name, Default, Default, ReadOnly, ChgVersion);");
		mixin("@property const const(VType) " ~ variableName!Name ~ "() { return _" ~ Name ~ ".value; }");
		mixin("@property const const(VType) " ~ Name ~ "_init() { return Default; }");
		static if (!ReadOnly) {
			mixin("@property void " ~ variableName!Name ~ "(VType value) { _" ~ Name ~ ".value = value; }");
		}
	}
	/// 連想配列のプロパティ。常にReadOnly。
	protected template AAProperty(string Name, Key, Value, string Default, string KeyName = "key", string ValueName = "value", ulong ChgVersion = 0) {
		private import cwx.xml;
		private import cwx.utils;
		mixin("private AAProperty!(Key, Value) _" ~ Name ~ " = AAProperty!(Key, Value)(Name, KeyName, ValueName, ChgVersion);");
		mixin("@property const const(" ~ Value.stringof ~ "[" ~ Key.stringof ~ "]) " ~ variableName!Name ~ "() { return _" ~ Name ~ ".value; }");
		mixin("@property void init_" ~ Name ~ "() { _" ~ Name ~ ".value = " ~ Default ~ "; }");
	}
	/// mixinによってXML化する関数及びXMLからプロパティ群をロードする関数を生成する。
	/// Params:
	/// SubClass = Propertiesのサブクラス。
	/// Root = ルート要素の名前。
	protected template XMLFuncs(SubClass : Properties, string Root = "") {
		import cwx.xml;
		import cwx.utils : printStackTrace, debugln;
		static if (Root.length > 0) {
			const
			string toXML() {
				return toXML(false);
			}
			const
			string toXML(bool writeAll) {
				auto e = XNode.create(Root);
				toNodeImpl(e, writeAll);
				return e.text;
			}
			static SubClass fromXML(string xml, ulong dataVersion) {
				try {
					auto node = XNode.parse(xml);
					return fromNodeImpl(node, dataVersion);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
					SubClass r;
					return r;
				}
			}
		}
		const
		void toNode(ref XNode node, bool writeAll) {
			static if (Root == "") {
				auto e = node;
			} else {
				auto e = node.newElement(Root);
			}
			toNodeImpl(e, writeAll);
		}
		const
		void toNode(ref XNode node) {
			toNode(node, false);
		}
		const
		private void toNodeImpl(ref XNode e, bool writeAll) {
			import std.conv;
			foreach (fld; this.tupleof) {
				static if (is(typeof(fld.KEY))) {
					if (writeAll || fld.value != fld.INIT) {
						fld.toNode(e);
					}
				} else static if (is(typeof(fld.ATTR_KEY))) {
					if (writeAll || fld.value != fld.INIT) {
						e.newAttr(fld.ATTR_KEY, to!string(fld.value));
					}
				} else static if (is(typeof(fld.AA_KEY))) {
					fld.toNode(e);
				}
			}
		}
		static SubClass fromNode(ref XNode node, ulong dataVersion) {
			static if (Root == "") {
				auto e = node;
			} else {
				auto e = node.child(Root, false);
			}
			return fromNodeImpl(e, dataVersion);
		}
		private static SubClass fromNodeImpl(ref XNode e, ulong dataVersion) {
			import std.conv;
			auto r = new SubClass;
			if (e.valid) {
				foreach (i, ref fld; r.tupleof) {
					static if (is(typeof(fld.KEY))) {
						auto n = e.child(fld.KEY, false);
						if (n.valid) {
							try {
								fld.fromNode(n, dataVersion);
							} catch (Exception e) {
								printStackTrace();
								debugln(e);
							}
						}
					} else static if (is(typeof(fld.ATTR_KEY))) {
						auto attr = e.attr(fld.ATTR_KEY, false, to!string(fld.INIT));
						fld.value = to!(typeof(fld.value))(attr);
					} else static if (is(typeof(fld.AA_KEY))) {
						auto n = e.child(fld.AA_KEY, false);
						if (n.valid) {
							try {
								fld.fromNode(n, dataVersion);
							} catch (Exception e) {
								printStackTrace();
								debugln(e);
							}
						}
					}
				}
			}
			return r;
		}
	}
}

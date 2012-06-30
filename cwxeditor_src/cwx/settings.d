
module cwx.settings;

import cwx.utils;
import cwx.xml;
import cwx.skin;
import cwx.background;
import cwx.structs;

import std.conv;
import std.string;
import std.file;
import std.path;
import std.utf;
import std.datetime;
import std.traits;

private void toNode(T)(ref XNode node, string key, in T value) {
	static if (is (typeof(value.toNode))) {
		value.toNode(node);
	} else static if (isVArray!(T)) {
		auto e = node.newElement(key);
		foreach (v; value) {
			static if (is (typeof(v.toNode))) {
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
	static if (is (typeof(value.fromNode))) {
		value.fromNode(node);
	} else static if (isVArray!(T)) {
		value = [];
		node.onTag[null] = (ref XNode v) {
			static if (is (typeof(value[0].fromNode))) {
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

private struct PropValue(string PKey, T, T Default, bool ReadOnly) {
	static immutable string KEY = PKey;
	static immutable T INIT = Default;
	static immutable bool READ_ONLY = ReadOnly;

	T value = Default;

	const
	void toNode(ref XNode node) {
		.toNode(node, KEY, value);
	}
	void fromNode(ref XNode node) {
		.fromNode(node, KEY, value);
	}
}
private struct PropValueAttr(string PKey, T, T Default, bool ReadOnly) {
	static immutable string ATTR_KEY = PKey;
	static immutable T INIT = Default;
	static immutable bool READ_ONLY = ReadOnly;

	T value = Default;

	const
	void toNode(ref XNode node) {
		.toNode(node, ATTR_KEY, value);
	}
	void fromNode(ref XNode node) {
		.fromNode(node, ATTR_KEY, value);
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
	protected template Property(string Name, VType, VType Default, bool ReadOnly = false) {
		mixin ("private PropValue!("
			~ "\"" ~ Name ~ "\", " ~ VType.stringof ~ ", " ~ Default.stringof ~ ", " ~ ReadOnly.stringof ~ ") "
			~ "_" ~ Name ~ ";");
		mixin ("@property const const(" ~ VType.stringof ~ ") " ~ Name ~ "() {return _" ~ Name ~ ".value;}");
		mixin ("@property const const(" ~ VType.stringof ~ ") " ~ Name ~ "_init() {return Default;}");
		static if (!ReadOnly) {
			mixin ("@property void " ~ Name ~ "(" ~ VType.stringof ~ " value) {_" ~ Name ~ ".value = value;}");
		}
	}
	/// Propertyと同様だが、XML化の際は属性として扱われる。
	protected template PropertyAttr(string Name, VType, VType Default, bool ReadOnly = false) {
		mixin ("private PropValueAttr!("
			~ "\"" ~ Name ~ "\", " ~ VType.stringof ~ ", " ~ Default.stringof ~ ", " ~ ReadOnly.stringof ~ ") "
			~ "_" ~ Name ~ ";");
		mixin ("@property const const(" ~ VType.stringof ~ ") " ~ Name ~ "() {return _" ~ Name ~ ".value;}");
		mixin ("@property const const(" ~ VType.stringof ~ ") " ~ Name ~ "_init() {return Default;}");
		static if (!ReadOnly) {
			mixin ("@property void " ~ Name ~ "(" ~ VType.stringof ~ " value) {_" ~ Name ~ ".value = value;}");
		}
	}
	/// mixinによってXML化する関数及びXMLからプロパティ群をロードする関数を生成する。
	/// Params:
	/// SubClass = Propertiesのサブクラス。
	/// Root = ルート要素の名前。
	protected template XMLFuncs(SubClass : Properties, string Root = "") {
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
			static SubClass fromXML(string xml) {
				try {
					auto node = XNode.parse(xml);
					return fromNodeImpl(node);
				} catch (Exception e) {
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
			foreach (fld; this.tupleof) {
				static if (is(typeof(fld.KEY))) {
					if (writeAll || fld.value != fld.INIT) {
						fld.toNode(e);
					}
				} else static if (is(typeof(fld.ATTR_KEY))) {
					if (writeAll || fld.value != fld.INIT) {
						e.newAttr(fld.ATTR_KEY, to!string(fld.value));
					}
				}
			}
		}
		static SubClass fromNode(ref XNode node) {
			static if (Root == "") {
				auto e = node;
			} else {
				auto e = node.child(Root, false);
			}
			return fromNodeImpl(e);
		}
		private static SubClass fromNodeImpl(ref XNode e) {
			auto r = new SubClass;
			if (e.valid) {
				foreach (i, ref fld; r.tupleof) {
					static if (is(typeof(fld.KEY))) {
						auto n = e.child(fld.KEY, false);
						if (n.valid) {
							try {
								fld.fromNode(n);
							} catch (Exception e) {
								debugln(e);
							}
						}
					} else static if (is(typeof(fld.ATTR_KEY))) {
						auto attr = e.attr(fld.ATTR_KEY, false, to!string(fld.INIT));
						fld.value = to!(typeof(fld.value))(attr);
					}
				}
			}
			return r;
		}
	}
}


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
	/// mixinによってXML化する関数及びXMLからプロパティ群をロードする関数を生成する。
	/// Params:
	/// SubClass = Propertiesのサブクラス。
	/// Root = ルート要素の名前。
	protected template XMLFuncs(SubClass : Properties, string Root = "") {
		static if (Root.length > 0) {
			string toXML() {
				auto e = XNode.create(Root);
				foreach (fld; this.tupleof) {
					if (!fld.READ_ONLY || fld.value != fld.INIT) {
						fld.toNode(e);
					}
				}
				return e.text;
			}
			static SubClass fromXML(string xml) {
				try {
					auto node = XNode.parse(xml);
					return fromNode(node);
				} catch (Exception) {
					SubClass r;
					return r;
				}
			}
		}
		void toNode(ref XNode node) {
			static if (Root == "") {
				auto e = node;
			} else {
				auto e = node.newElement(Root);
			}
			foreach (fld; this.tupleof) {
				static if (is(typeof(fld.READ_ONLY))) {
					if (fld.value != fld.INIT) {
						fld.toNode(e);
					}
				}
			}
		}
		static SubClass fromNode(ref XNode node) {
			auto r = new SubClass;
			static if (Root == "") {
				auto e = node;
			} else {
				auto e = node.child(Root, false);
			}
			if (e.valid) {
				foreach (i, fld; r.tupleof) {
					static if (is(typeof(fld.READ_ONLY))) {
						auto n = e.child(fld.KEY, false);
						if (n.valid) {
							try {
								r.tupleof[i].fromNode(n);
							} catch (Exception e) {
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

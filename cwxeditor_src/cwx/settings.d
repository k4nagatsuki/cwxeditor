
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

private struct PropValue(string PKey, T, T Default, bool ReadOnly) {
	private T _value = Default;
	@property
	const
	string key() {
		return PKey;
	}
	static const bool READ_ONLY = ReadOnly;

	static if (!ReadOnly) {
		void opAssign(T value) {
			_value = value;
		}
		void opCall(T value) {
			_value = value;
		}
	}
	@property
	static T init() {return Default;}
	const
	void toNode(ref XNode node) {
		static if (is (typeof(_value.toNode))) {
			_value.toNode(node);
		} else static if (isVArray!(T)) {
			auto e = node.newElement(key);
			foreach (v; _value) {
				static if (is (typeof(v.toNode))) {
					v.toNode(e);
				} else {
					e.newElement("value", to!(string)(v));
				}
			}
		} else {
			node.newElement(key, to!(string)(_value));
		}
	}
	T opCall() {
		return _value;
	}
	const
	const(T) opCall() {
		return _value;
	}
	void fromNode(ref XNode node) {
		static if (is (typeof(_value.fromNode))) {
			_value.fromNode(node);
		} else static if (isVArray!(T)) {
			_value = [];
			node.onTag[null] = (ref XNode v) {
				static if (is (typeof(_value[0].fromNode))) {
					typeof(_value[0]) val;
					val.fromNode(v);
					_value ~= val;
				} else {
					_value ~= to!(typeof(_value[0]))(v.value);
				}
			};
			node.parse();
		} else {
			_value = to!(T)(node.value);
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
	/// 	return _width();
	/// }
	/// void width(int value) {
	/// 	_width = value;
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
		mixin ("@property const const(" ~ VType.stringof ~ ") " ~ Name ~ "() {return _" ~ Name ~ "();}");
		mixin ("@property const const(" ~ VType.stringof ~ ") " ~ Name ~ "_init() {return Default;}");
		static if (!ReadOnly) {
			mixin ("@property void " ~ Name ~ "(" ~ VType.stringof ~ " value) {_" ~ Name ~ " = value;}");
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
					if (!fld.READ_ONLY || fld() != fld.init) {
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
					if (fld() != fld.init) {
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
						auto n = e.child(fld.key, false);
						if (n.valid) {
							try {
								// FIXME: fld.fromNode()だと上手く行かない？
								r.tupleof[i].fromNode(n);
							} catch {
							}
						}
					}
				}
			}
			return r;
		}
	}
}

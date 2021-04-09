
module cwx.flag;

import cwx.expression;
import cwx.path;
import cwx.system;
import cwx.textholder;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.xml;

import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.exception;
import std.math;
import std.string;
import std.typecons : Rebindable, rebindable;

private static const {
	string XML_ROOT_FLAGS_AND_STEPS = "FlagsAndSteps";
	string XML_ROOT_FLAG_DIRECTORY = "FlagDirectory";
	string XML_ATT_ROOT_ID = "rootId";
	string XML_ATT_PATH = "path";
	string XML_ATT_ROOT_NAME = "rootName";
}

/// フラグ関連の例外。
public class FlagException : Exception {
public:
	this (string msg) { mixin(S_TRACE);
		super(msg);
	}
}

/// ローカル変数を持つリソース。
interface LocalVariableOwner : CWXPath {
	@property
	const
	ulong id();
	@property
	const
	string name();
	@property
	inout
	inout(FlagDir) flagDirRoot();
	@property
	inout
	inout(UseCounter) useCounter();
}

/// フラグとステップの集合をXMLにして返す。
public string getXML(in FlagDir parent, in Flag[] flags, in Step[] steps, in Variant[] variants) { mixin(S_TRACE);
	XNode node;
	getNode(parent, flags, steps, variants, node);
	return node.text;
}
/// ditto
public void getNode(in FlagDir parent, in Flag[] flags, in Step[] steps, in Variant[] variants, out XNode e) { mixin(S_TRACE);
	e = XNode.create(XML_ROOT_FLAGS_AND_STEPS);
	auto _root = parent.root;
	e.newAttr(XML_ATT_PATH, parent.path);
	e.newAttr( XML_ATT_ROOT_ID, _root.id);
	auto fe = e.newElement("Flags");
	foreach (flag; flags) { mixin(S_TRACE);
		assert (flag.parent.root is _root);
		assert (flag.parent is parent);
		flag.toNode(fe);
	}
	auto se = e.newElement("Steps");
	foreach (step; steps) { mixin(S_TRACE);
		assert (step.parent.root is _root);
		assert (step.parent is parent);
		step.toNode(se);
	}
	auto ve = e.newElement("Variants");
	foreach (variant; variants) { mixin(S_TRACE);
		assert (variant.parent.root is _root);
		assert (variant.parent is parent);
		variant.toNode(ve);
	}
}

/// フラグのディレクトリとその配下の内容をXMLにして返す。
public string getXML(string rootName, FlagDir dir) { mixin(S_TRACE);
	return toNode(rootName, dir).text;
}
/// ditto
XNode toNode(string rootName, FlagDir dir) { mixin(S_TRACE);
	auto ret = XNode.create(XML_ROOT_FLAG_DIRECTORY);
	toNode(ret, dir);
	auto _root = dir.root;
	ret.newAttr(XML_ATT_ROOT_ID, _root.id);
	if (_root is dir) { mixin(S_TRACE);
		ret.newAttr(XML_ATT_ROOT_NAME, rootName);
	}
	return ret;
}
private void toNode(ref XNode ret, FlagDir dir) { mixin(S_TRACE);
	ret.newAttr(XML_ATT_PATH, dir.path);
	auto fe = ret.newElement("Flags");
	foreach (flag; dir.flags) { mixin(S_TRACE);
		flag.toNode(fe);
	}
	auto se = ret.newElement("Steps");
	foreach (step; dir.steps) { mixin(S_TRACE);
		step.toNode(se);
	}
	auto ve = ret.newElement("Variants");
	foreach (variant; dir.variants) { mixin(S_TRACE);
		variant.toNode(ve);
	}
	foreach (subdir; dir.subDirs) { mixin(S_TRACE);
		auto e = ret.newElement(XML_ROOT_FLAG_DIRECTORY);
		toNode(e, subdir);
	}
}

/// フラグ。
public class Flag : CWXPath, Commentable {
private:
	string _name;
	TextHolder _on;
	TextHolder _off;
	bool _onOff;
	bool _expandSPChars = false;
	VariableInitialization _initialization = VariableInitialization.Leave;
	FlagDir _parent;
	void delegate() _change = null;
	UseCounter _uc = null;
	string _comment;
public:
	/// パスをIDに置換する。
	alias toFlagId toID;

	/// コピーコンストラクタ。
	this (in Flag copyBase) { mixin(S_TRACE);
		_on = new TextHolder(this);
		_on.changeHandler = &changed;
		_off = new TextHolder(this);
		_off.changeHandler = &changed;

		copyFrom(copyBase);
	}
	/// 名前・On/Off時のテキスト・On/Off状態を指定してインスタンスを生成。
	this (string name, string on, string off, bool onOff) { mixin(S_TRACE);
		_on = new TextHolder(this);
		_on.changeHandler = &changed;
		_off = new TextHolder(this);
		_off.changeHandler = &changed;

		_on.text = on;
		_off.text = off;
		_onOff = onOff;
		_name = FlagDir.validName(name);
	}

	const
	override
	bool opEquals(Object o) { mixin(S_TRACE);
		if (this is o) return true;
		auto f = cast(const Flag)o;
		if (!f) return false;
		return on == f.on
			&& off == f.off
			&& onOff == f.onOff
			&& name == f.name
			&& expandSPChars == f.expandSPChars
			&& initialization == f.initialization
			&& comment == f.comment;
	}

	/// flagのパラメータをコピーする。
	void copyFrom(in Flag flag) { mixin(S_TRACE);
		name = flag.name;
		on = flag.on;
		off = flag.off;
		onOff = flag.onOff;
		expandSPChars = flag.expandSPChars;
		initialization = flag.initialization;
		comment = flag.comment;
	}
	/// このフラグの親ディレクトリ。
	@property
	inout
	inout(FlagDir) parent() { mixin(S_TRACE);
		return _parent;
	}
	/// ditto
	@property
	private void parent(FlagDir parent) { mixin(S_TRACE);
		assert (!parent || !parent.getFlag(name));
		_parent = parent;
	}
	/// 最上位のディレクトリ。
	@property
	inout
	inout(FlagDir) root() { mixin(S_TRACE);
		return _parent.root;
	}
	/// 変更ハンドラを設定する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		_change = change;
	}

	/// 使用回数カウンタ。
	@property
	void useCounter(UseCounter uc) { mixin(S_TRACE);
		_uc = uc;
		if (expandSPChars && uc) { mixin(S_TRACE);
			_on.setUseCounter(uc, this);
			_off.setUseCounter(uc, this);
		} else { mixin(S_TRACE);
			_on.removeUseCounter();
			_off.removeUseCounter();
		}
	}
	/// ditto
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }

	/// フラグ名。同一のディレクトリ内では重複しない。
	@property
	const
	string name() { mixin(S_TRACE);
		return _name;
	}
	/// ditto
	@property
	bool name(string name) { mixin(S_TRACE);
		name = FlagDir.validName(name);
		if (!_parent || _parent.canAppend!Flag(name)) { mixin(S_TRACE);
			if (_name == name) return true;
			if (_change) _change();
			if (_parent) { mixin(S_TRACE);
				_parent._flagNames.remove(_name);
				_parent._flagNames[name] = this;
			}
			_name = name;
			return true;
		}
		return false;
	}
	/// On時のテキスト。
	@property
	const
	string on() { mixin(S_TRACE);
		return _on.text;
	}
	/// ditto
	@property
	void on(string on) { mixin(S_TRACE);
		if (this.on != on) { mixin(S_TRACE);
			changed();
			_on.text = on;
		}
	}
	/// Off時のテキスト。
	@property
	const
	string off() { mixin(S_TRACE);
		return _off.text;
	}
	/// ditto
	@property
	void off(string off) { mixin(S_TRACE);
		if (this.off != off) { mixin(S_TRACE);
			changed();
			_off.text = off;
		}
	}
	/// On/Off初期状態。
	@property
	const
	bool onOff() { mixin(S_TRACE);
		return _onOff;
	}
	/// ditto
	@property
	void onOff(bool onOff) { mixin(S_TRACE);
		if (_change && _onOff != onOff) _change();
		_onOff = onOff;
	}

	/// 特殊文字を展開するか(Wsn.2)。
	@property
	const
	bool expandSPChars() { return _expandSPChars; }
	/// ditto
	@property
	void expandSPChars(bool val) { mixin(S_TRACE);
		if (val != _expandSPChars) { mixin(S_TRACE);
			changed();
			_expandSPChars = val;
			if (expandSPChars && _uc) { mixin(S_TRACE);
				_on.setUseCounter(_uc, this);
				_off.setUseCounter(_uc, this);
			} else { mixin(S_TRACE);
				_on.removeUseCounter();
				_off.removeUseCounter();
			}
		}
	}

	/// 初期化タイミング(Wsn.4)。
	@property
	const
	VariableInitialization initialization() { mixin(S_TRACE);
		return _initialization;
	}
	/// ditto
	@property
	void initialization(VariableInitialization initialization) { mixin(S_TRACE);
		if (_change && _initialization != initialization) _change();
		_initialization = initialization;
	}

	/// 値のテキスト内で使用されている状態変数のパス。
	const
	string[] flagsInText(bool value) { return value ? _on.flagsInText : _off.flagsInText; }
	/// ditto
	const
	string[] stepsInText(bool value) { return value ? _on.stepsInText : _off.stepsInText; }
	/// ditto
	const
	string[] variantsInText(bool value) { return value ? _on.variantsInText : _off.variantsInText; }

	@property
	const
	override
	string comment() { return _comment; }
	@property
	override
	void comment(string v) { mixin(S_TRACE);
		if (_comment == v) return;
		changed();
		_comment = v;
	}

	const
	override int opCmp(Object o) { mixin(S_TRACE);
		return cmp(name, (cast(Flag)o).name);
	}
	/// このフラグのフルパスを返す。
	@property
	const
	string path() { mixin(S_TRACE);
		return _parent.path ~ _name;
	}

	override void changed() { mixin(S_TRACE);
		if (_change) _change();
	}

	/// このフラグをXMLテキストにする。
	const
	string toXml() { mixin(S_TRACE);
		auto doc = XNode.create(XML_ROOT_FLAG_DIRECTORY);
		toNode(doc);
		return doc.text;
	}
	/// XMLノードからインスタンスを生成。
	static Flag createFromNode(ref XNode fe, in XMLInfo ver) { mixin(S_TRACE);
		string name = null;
		string tv = "TRUE";
		string fv = "FALSE";
		bool def = parseBool(fe.attr("default", true));
		fe.onTag["Name"] = (ref XNode n) { name = FlagDir.basename(n.value); };
		fe.onTag["True"] = (ref XNode n) { tv = n.value; };
		fe.onTag["False"] = (ref XNode n) { fv = n.value; };
		fe.parse();
		if (!name) throw new FlagException("Flag name not found.");
		auto flag = new Flag(name, tv, fv, def);
		flag.expandSPChars = fe.attr!bool("spchars", false, false);
		flag.initialization = toVariableInitialization(fe.attr("initialize", false, "Leave"));
		flag.comment = fe.attr("comment", false, "");
		return flag;
	}
	/// XMLノードへこのフラグのデータを追加する。
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement("Flag");
		e.newAttr("default", fromBool(_onOff));
		if (expandSPChars) e.newAttr("spchars", expandSPChars);
		if (initialization !is VariableInitialization.Leave) e.newAttr("initialize", fromVariableInitialization(initialization));
		e.newElement("Name", path);
		e.newElement("True", on);
		e.newElement("False", off);
		if (comment != "") e.newAttr("comment", comment);
	}
	@property
	override string cwxPath(bool id) { mixin(S_TRACE);
		return cpjoin(_parent, "flag", .cCountUntil!("a is b")(_parent.flags, this), id);
	}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		return null;
	}
	@property
	inout
	override inout(CWXPath)[] cwxChilds() { return []; }
	@property
	CWXPath cwxParent() { return _parent; }
}

/// ステップ。
public class Step : CWXPath, Commentable {
private:
	string _name;
	TextHolder[] _vals;
	uint _select;
	bool _expandSPChars = false;
	VariableInitialization _initialization = VariableInitialization.Leave;
	FlagDir _parent;
	void delegate() _change = null;
	UseCounter _uc = null;
	string _comment;
public:
	/// パスをIDに置換する。
	alias toStepId toID;

	/// コピーコンストラクタ。
	this (in Step copyBase) { mixin(S_TRACE);
		copyFrom(copyBase);
	}
	/// ステップ名、各段階のステップ値、選択状態を指定してインスタンスを生成。
	this (string name, string[] vals, uint select) { mixin(S_TRACE);
		setValues(vals, select);
		_name = FlagDir.validName(name);
	}

	const
	override
	bool opEquals(Object o) { mixin(S_TRACE);
		if (this is o) return true;
		auto f = cast(const Step)o;
		if (!f) return false;
		return select == f.select
			&& name == f.name
			&& values == f.values
			&& expandSPChars == f.expandSPChars
			&& initialization == f.initialization
			&& comment == f.comment;
	}

	/// stepのパラメータをコピーする。
	void copyFrom(in Step step) { mixin(S_TRACE);
		name = step.name;
		setValues(step.values, step.select);
		expandSPChars = step.expandSPChars;
		initialization = step.initialization;
		comment = step.comment;
	}
	/// このステップの親ディレクトリ。
	@property
	inout
	inout(FlagDir) parent() { mixin(S_TRACE);
		return _parent;
	}
	/// ditto
	@property
	private void parent(FlagDir parent) { mixin(S_TRACE);
		assert (!parent || !parent.getStep(name));
		_parent = parent;
	}
	/// 最上位のディレクトリ。
	@property
	inout
	inout(FlagDir) root() { mixin(S_TRACE);
		return _parent.root;
	}
	/// 変更ハンドラを設定する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		_change = change;
	}

	/// ステップ名。
	@property
	const
	string name() { mixin(S_TRACE);
		return _name;
	}
	/// ditto
	@property
	bool name(string name) { mixin(S_TRACE);
		name = FlagDir.validName(name);
		if (!_parent || _parent.canAppend!Step(name)) { mixin(S_TRACE);
			if (_name == name) return true;
			if (_change) _change();
			if (_parent) { mixin(S_TRACE);
				_parent._stepNames.remove(_name);
				_parent._stepNames[name] = this;
			}
			_name = name;
			return true;
		}
		return false;
	}

	/// ステップ値のテキストを変更する。
	void setValue(uint index, string value) { mixin(S_TRACE);
		if (getValue(index) != value) { mixin(S_TRACE);
			changed();
			_vals[index].text = value;
		}
	}
	/// ステップ値のテキストを返す。
	const
	string getValue(uint index) { mixin(S_TRACE);
		return _vals[index].text;
	}

	/// ステップの段階数を返す。
	@property
	const
	uint count() { mixin(S_TRACE);
		return cast(uint)_vals.length;
	}

	/// ステップの選択状態を返す。
	@property
	const
	uint select() { mixin(S_TRACE);
		return _select;
	}
	/// ditto
	@property
	void select(uint select) { mixin(S_TRACE);
		if (_change && _select != select) _change();
		_select = .min(select, _vals.length - 1);
	}

	/// 選択中の値のテキストを返す。
	@property
	const
	string value() { mixin(S_TRACE);
		return _vals[_select].text;
	}
	/// ステップ値群を返す。
	@property
	const
	string[] values() { mixin(S_TRACE);
		return .map!(a => a.text)(_vals).array();
	}
	/// ステップ値群と選択状態を設定する。
	void setValues(in string[] vals, int select) { mixin(S_TRACE);
		assert (select < vals.length);
		if (_select != select) { mixin(S_TRACE);
			changed();
			_select = select;
		}
		if (values != vals) { mixin(S_TRACE);
			changed();
			if (vals.length < _vals.length) { mixin(S_TRACE);
				foreach (th; _vals[vals.length .. $]) { mixin(S_TRACE);
					th.removeUseCounter();
				}
				_vals = _vals[0 .. vals.length];
			} else if (_vals.length < vals.length) { mixin(S_TRACE);
				foreach (i; _vals.length .. vals.length) { mixin(S_TRACE);
					auto th = new TextHolder(this);
					th.changeHandler = &changed;
					if (expandSPChars && _uc) th.setUseCounter(_uc, this);
					_vals ~= th;
				}
			}
			foreach (i, th; _vals) th.text = vals[i];
		}
	}

	/// 特殊文字を展開するか(Wsn.2)。
	@property
	const
	bool expandSPChars() { return _expandSPChars; }
	/// ditto
	@property
	void expandSPChars(bool val) { mixin(S_TRACE);
		if (val != _expandSPChars) { mixin(S_TRACE);
			changed();
			_expandSPChars = val;
			foreach (th; _vals) { mixin(S_TRACE);
				if (expandSPChars && _uc) { mixin(S_TRACE);
					th.setUseCounter(_uc, this);
				} else { mixin(S_TRACE);
					th.removeUseCounter();
				}
			}
		}
	}

	/// 初期化タイミング(Wsn.4)。
	@property
	const
	VariableInitialization initialization() { mixin(S_TRACE);
		return _initialization;
	}
	/// ditto
	@property
	void initialization(VariableInitialization initialization) { mixin(S_TRACE);
		if (_change && _initialization != initialization) _change();
		_initialization = initialization;
	}

	/// 値のテキスト内で使用されている状態変数のパス。
	const
	string[] flagsInText(uint value) { return _vals[value].flagsInText; }
	/// ditto
	const
	string[] stepsInText(uint value) { return _vals[value].stepsInText; }
	/// ditto
	const
	string[] variantsInText(uint value) { return _vals[value].variantsInText; }

	@property
	const
	override
	string comment() { return _comment; }
	@property
	override
	void comment(string v) { mixin(S_TRACE);
		if (_comment == v) return;
		changed();
		_comment = v;
	}

	const
	override int opCmp(Object o) { mixin(S_TRACE);
		return cmp(name, (cast(Step)o).name);
	}

	/// ステップのフルパス。
	@property
	const
	string path() { mixin(S_TRACE);
		return _parent.path ~ _name;
	}

	override void changed() { mixin(S_TRACE);
		if (_change) _change();
	}

	/// 使用回数カウンタ。
	@property
	void useCounter(UseCounter uc) { mixin(S_TRACE);
		_uc = uc;
		foreach (th; _vals) { mixin(S_TRACE);
			if (expandSPChars && uc) { mixin(S_TRACE);
				th.setUseCounter(uc, this);
			} else { mixin(S_TRACE);
				th.removeUseCounter();
			}
		}
	}
	/// ditto
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }

	/// このステップをXMLテキストにする。
	const
	string toXml() { mixin(S_TRACE);
		auto doc = XNode.create(XML_ROOT_FLAG_DIRECTORY);
		toNode(doc);
		return doc.text;
	}
	/// XMLノードからステップを生成する。
	static Step createFromNode(ref XNode se, in XMLInfo ver) { mixin(S_TRACE);
		string[] vals;
		string name = null;
		int def = se.attr!(int)("default", true);
		se.onTag["Name"] = (ref XNode n) { name = FlagDir.basename(n.value); };
		se.onTag[null] = (ref XNode n) { mixin(S_TRACE);
			if (startsWith(n.name, "Value")) { mixin(S_TRACE);
				vals ~= n.value;
			}
		};
		se.parse();
		if (!name) throw new FlagException("Step name not found.");
		if (def < 0 || vals.length <= def) { mixin(S_TRACE);
			throw new FlagException("Step default value invalid. Count: " ~ to!(string)(vals.length) ~ ", default: " ~ to!(string)(def));
		}
		auto step = new Step(name, vals, def);
		step.expandSPChars = se.attr!bool("spchars", false, false);
		step.initialization = toVariableInitialization(se.attr("initialize", false, "Leave"));
		step.comment = se.attr("comment", false, "");
		return step;
	}
	/// 指定されたXMLノードにこのステップのデータを追加する。
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement("Step");
		e.newAttr("default", _select);
		if (expandSPChars) e.newAttr("spchars", expandSPChars);
		if (initialization !is VariableInitialization.Leave) e.newAttr("initialize", fromVariableInitialization(initialization));
		e.newElement("Name", path);
		for (int i = 0; i < _vals.length; i++) { mixin(S_TRACE);
			e.newElement("Value", _vals[i].text);
		}
		if (comment != "") e.newAttr("comment", comment);
	}
	@property
	override string cwxPath(bool id) { mixin(S_TRACE);
		return cpjoin(_parent, "step", .cCountUntil!("a is b")(_parent.steps, this), id);
	}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		return null;
	}
	@property
	inout
	override inout(CWXPath)[] cwxChilds() { return []; }
	@property
	CWXPath cwxParent() { return _parent; }
}

/// コモン(Wsn.4)。
public class Variant : CWXPath, Commentable {
private:
	string _name;
	VariantType _type;

	double _numVal = 0.0;
	string _strVal = "";
	bool _boolVal = true;
	const(VariantVal)[] _listVal = [];

	string _structName = "";
	const(VariantVal)[] _structVal = null;

	VariableInitialization _initialization = VariableInitialization.Leave;

	FlagDir _parent;
	void delegate() _change = null;
	UseCounter _uc = null;

	string _comment;
public:
	/// パスをIDに置換する。
	alias toVariantId toID;

	/// データとして書き出される小数点以下の桁数。
	static immutable DECIMAL_PLACES = 8;

	/// コピーコンストラクタ。
	this (in Variant copyBase) { mixin(S_TRACE);
		copyFrom(copyBase);
	}
	/// コモン名、初期値を指定してインスタンスを生成。
	this (string name, double numVal) { mixin(S_TRACE);
		_name = FlagDir.validName(name);
		_type = VariantType.Number;
		_numVal = numVal;
	}
	/// ditto
	this (string name, string strVal) { mixin(S_TRACE);
		_name = FlagDir.validName(name);
		_type = VariantType.String;
		_strVal = strVal;
	}
	/// ditto
	this (string name, bool boolVal) { mixin(S_TRACE);
		_name = FlagDir.validName(name);
		_type = VariantType.Boolean;
		_boolVal = boolVal;
	}
	/// ditto
	this (string name, in VariantVal[] listVal) { mixin(S_TRACE);
		_name = FlagDir.validName(name);
		_type = VariantType.List;
		_listVal = listVal;
	}
	/// ditto
	this (string name, string structName, in VariantVal[] structVal) { mixin(S_TRACE);
		_name = FlagDir.validName(name);
		_type = VariantType.Structure;
		_structName = structName;
		_structVal = structVal;
	}

	const
	override
	bool opEquals(Object o) { mixin(S_TRACE);
		if (this is o) return true;
		auto f = cast(const Variant)o;
		if (!f) return false;
		if (type != f.type) return false;
		if (name != f.name) return false;
		if (initialization != f.initialization) return false;
		if (comment != f.comment) return false;
		final switch (type) {
		case VariantType.Number: return numVal.isClose(f.numVal);
		case VariantType.String: return strVal == f.strVal;
		case VariantType.Boolean: return boolVal == f.boolVal;
		case VariantType.List: return listVal == f.listVal;
		case VariantType.Structure:
			if (structName != f.structName) return false;
			return structVal == f.structVal;
		}
	}

	/// stepのパラメータをコピーする。
	void copyFrom(in Variant copyBase) { mixin(S_TRACE);
		name = copyBase.name;
		if (type != copyBase.type || _numVal != copyBase.numVal || _strVal != copyBase.strVal || _boolVal != copyBase.boolVal || _listVal != copyBase.listVal || _structName != copyBase.structName || _structVal != copyBase.structVal) { mixin(S_TRACE);
			changed();
			_type = copyBase.type;
			_numVal = copyBase.numVal;
			_strVal = copyBase.strVal;
			_boolVal = copyBase.boolVal;
			_listVal = copyBase.listVal;
			_structName = copyBase.structName;
			_structVal = copyBase.structVal;
		}
		initialization = copyBase.initialization;
		comment = copyBase.comment;
	}
	/// 親ディレクトリ。
	@property
	inout
	inout(FlagDir) parent() { mixin(S_TRACE);
		return _parent;
	}
	/// ditto
	@property
	private void parent(FlagDir parent) { mixin(S_TRACE);
		assert (!parent || !parent.getVariant(name));
		_parent = parent;
	}
	/// 最上位のディレクトリ。
	@property
	inout
	inout(FlagDir) root() { mixin(S_TRACE);
		return _parent.root;
	}
	/// 変更ハンドラを設定する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		_change = change;
	}

	/// コモン名。
	@property
	const
	string name() { mixin(S_TRACE);
		return _name;
	}
	/// ditto
	@property
	bool name(string name) { mixin(S_TRACE);
		name = FlagDir.validName(name);
		if (!_parent || _parent.canAppend!Variant(name)) { mixin(S_TRACE);
			if (_name == name) return true;
			changed();
			if (_parent) { mixin(S_TRACE);
				_parent._variantNames.remove(_name);
				_parent._variantNames[name] = this;
			}
			_name = name;
			return true;
		}
		return false;
	}

	/// 値を設定する。
	@property
	void value(double numVal) { mixin(S_TRACE);
		if (_type !is VariantType.Number || _numVal != numVal) { mixin(S_TRACE);
			changed();
			_type = VariantType.Number;
			_numVal = numVal;
		}
	}
	/// ditto
	@property
	void value(string strVal) { mixin(S_TRACE);
		if (_type !is VariantType.String || _strVal != strVal) { mixin(S_TRACE);
			changed();
			_type = VariantType.String;
			_strVal = strVal;
		}
	}
	/// ditto
	@property
	void value(bool boolVal) { mixin(S_TRACE);
		if (_type !is VariantType.Boolean || _boolVal != boolVal) { mixin(S_TRACE);
			changed();
			_type = VariantType.Boolean;
			_boolVal = boolVal;
		}
	}
	/// ditto
	@property
	void value(const(VariantVal)[] listVal) { mixin(S_TRACE);
		if (_type !is VariantType.List || _listVal != listVal) { mixin(S_TRACE);
			changed();
			_type = VariantType.List;
			_listVal = listVal;
		}
	}
	/// ditto
	void setStructValue(string structName, in VariantVal[] structVal) { mixin(S_TRACE);
		if (_type !is VariantType.Structure || _structName != structName || _structVal != structVal) { mixin(S_TRACE);
			changed();
			_type = VariantType.Structure;
			_structName = structName;
			_structVal = structVal;
		}
	}

	/// 値の型。
	@property
	const
	VariantType type() { return _type; }

	/// 値。
	@property
	const
	double numVal() { return _numVal; }
	/// ditto
	@property
	const
	string strVal() { return _strVal; }
	/// ditto
	@property
	const
	bool boolVal() { return _boolVal; }
	/// ditto
	@property
	const
	const(VariantVal)[] listVal() { return _listVal; }
	/// ditto
	@property
	const
	string structName() { return _structName; }
	/// ditto
	@property
	const
	const(VariantVal)[] structVal() { return _structVal; }

	/// 初期化タイミング。
	@property
	const
	VariableInitialization initialization() { mixin(S_TRACE);
		return _initialization;
	}
	/// ditto
	@property
	void initialization(VariableInitialization initialization) { mixin(S_TRACE);
		if (_change && _initialization != initialization) _change();
		_initialization = initialization;
	}

	@property
	const
	override
	string comment() { return _comment; }
	@property
	override
	void comment(string v) { mixin(S_TRACE);
		if (_comment == v) return;
		changed();
		_comment = v;
	}

	const
	override int opCmp(Object o) { mixin(S_TRACE);
		return cmp(name, (cast(Variant)o).name);
	}

	/// フルパス。
	@property
	const
	string path() { mixin(S_TRACE);
		return _parent.path ~ _name;
	}

	override void changed() { mixin(S_TRACE);
		if (_change) _change();
	}

	/// 使用回数カウンタ。
	@property
	void useCounter(UseCounter uc) { mixin(S_TRACE);
		_uc = uc;
	}
	/// ditto
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }

	/// このステップをXMLテキストにする。
	const
	string toXml() { mixin(S_TRACE);
		auto doc = XNode.create(XML_ROOT_FLAG_DIRECTORY);
		toNode(doc);
		return doc.text;
	}
	/// XMLノードからステップを生成する。
	static Variant createFromNode(ref XNode ve, in XMLInfo ver) { mixin(S_TRACE);
		string[] vals;
		string name = null;
		auto defType = toVariantType(ve.attr!string("defaulttype", true));
		auto defValue = ve.attr!string("defaultvalue", true);
		ve.onTag["Name"] = (ref XNode n) { name = FlagDir.basename(n.value); };
		ve.parse();
		if (!name) throw new FlagException("Variant name not found.");

		Variant variant = null;
		final switch (defType) {
		case VariantType.Number:
			variant = new Variant(name, .to!double(defValue));
			break;
		case VariantType.String:
			variant = new Variant(name, defValue);
			break;
		case VariantType.Boolean:
			variant = new Variant(name, .parseBool(defValue));
			break;
		case VariantType.List:
			variant = new Variant(name, toListVal(ve).listVal);
			break;
		case VariantType.Structure:
			auto val = toStructVal(ve);
			variant = new Variant(name, val.structName, val.structVal);
			break;
		}
		variant.initialization = toVariableInitialization(ve.attr("initialize", false, "Leave"));
		variant.comment = ve.attr("comment", false, "");
		return variant;
	}
	private static const(VariantVal) toListVal(ref XNode n) { mixin(S_TRACE);
		auto val = VariantVal(VariantType.List);
		n.onTag["Value"] = (ref XNode n) { mixin(S_TRACE);
			val.listVal ~= toVariantVal(n);
		};
		n.parse();
		return val;
	}
	private static const(VariantVal) toStructVal(ref XNode n) { mixin(S_TRACE);
		string origStructName;
		string[] memberNames;
		auto val = VariantVal(VariantType.Structure);
		n.onTag["StructureName"] = (ref XNode n) { mixin(S_TRACE);
			origStructName = n.value;
			val.structName = n.value.toLower();
		};
		n.onTag["Member"] = (ref XNode n) { mixin(S_TRACE);
			memberNames ~= n.attr("name", true);
			val.structVal ~= toVariantVal(n);
		};
		n.parse();
		if (!.isValidStructure(val.structName, memberNames, val.structVal)) { mixin(S_TRACE);
			throw new Exception("Invalid structure %s member: %s".format(origStructName, memberNames.join(", ")));
		}
		auto members = .structureMembers(val.structName);
		foreach (i; val.structVal.length .. members.length) val.structVal ~= members[i].defaultValue;
		return val;
	}
	private static const(VariantVal) toVariantVal(ref XNode n) { mixin(S_TRACE);
		auto type = toVariantType(n.attr!string("type", true));
		auto value = n.attr!string("value", true);
		final switch (type) {
		case VariantType.Number:
			return VariantVal.numValue(.to!double(value));
		case VariantType.String:
			return VariantVal.strValue(value);
		case VariantType.Boolean:
			return VariantVal.boolValue(.parseBool(value));
		case VariantType.List:
			return toListVal(n);
		case VariantType.Structure:
			return toStructVal(n);
		}
	}

	/// 指定されたXMLノードにこのステップのデータを追加する。
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement("Variant");
		e.newAttr("defaulttype", .fromVariantType(type));
		if (initialization !is VariableInitialization.Leave) e.newAttr("initialize", fromVariableInitialization(initialization));

		final switch (type) {
		case VariantType.Number:
		case VariantType.String:
			e.newAttr("defaultvalue", .variantValueToPreviewText(this));
			break;
		case VariantType.Boolean:
			e.newAttr("defaultvalue", .fromBool(boolVal));
			break;
		case VariantType.List:
			fromListVal(e, listVal);
			break;
		case VariantType.Structure:
			fromStructVal(e, structName, structVal);
			break;
		}
		e.newElement("Name", path);
		if (comment != "") e.newAttr("comment", comment);
	}
	private static void fromListVal(ref XNode n, in VariantVal[] vals) { mixin(S_TRACE);
		foreach (ref val; vals) { mixin(S_TRACE);
			auto ve = n.newElement("Value");
			ve.newAttr("type", .fromVariantType(val.type));
			fromVariantVal(ve, val);
		}
	}
	private static void fromStructVal(ref XNode n, string name, in VariantVal[] vals) { mixin(S_TRACE);
		n.newElement("StructureName", name.toUpper());
		foreach (i, mem; .structureMembers(name)) { mixin(S_TRACE);
			auto ve = n.newElement("Member");
			ve.newAttr("name", mem.name.toUpper());
			fromVariantVal(ve, vals[i]);
		}
	}
	private static void fromVariantVal(ref XNode n, in VariantVal val) { mixin(S_TRACE);
		final switch (val.type) {
		case VariantType.Number:
		case VariantType.String:
			n.newAttr("value", .variantValueToPreviewText(val));
			break;
		case VariantType.Boolean:
			n.newAttr("value", .fromBool(val.boolVal));
			break;
		case VariantType.List:
			fromListVal(n, val.listVal);
			break;
		case VariantType.Structure:
			fromStructVal(n, val.structName, val.structVal);
			break;
		}
	}

	@property
	override string cwxPath(bool id) { mixin(S_TRACE);
		return .cpjoin(_parent, "variant", .cCountUntil!("a is b")(_parent.variants, this), id);
	}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (.cpempty(path)) return this;
		return null;
	}
	@property
	inout
	override inout(CWXPath)[] cwxChilds() { return []; }
	@property
	CWXPath cwxParent() { return _parent; }
}

/// フラグ/ステップ、及びサブディレクトリを格納するディレクトリ。
public class FlagDir : CWXPath {
private:
	string _name = "";
	CWXPath _owner = null;
	string _localVariablePrefix = "";
	FlagDir _parent = null;
	FlagDir[] _subdir;
	Flag[] _flags;
	Step[] _steps;
	Variant[] _variants;
	Flag[string] _flagNames;
	Step[string] _stepNames;
	Variant[string] _variantNames;
	FlagDir[string] _dirNames;
	string _id;
	void delegate() _change = null;
	UseCounter _uc = null;
public:
	/// パス区切り文字。
	static immutable string SEPARATOR = "\\";
	/// ditto
	static immutable string SEPARATOR_REGEX = "\\\\";
	/// パスを結合する。
	static string join(string parent, string path) { mixin(S_TRACE);
		if (!parent.length) { mixin(S_TRACE);
			return path;
		}
		if (parent.endsWith(SEPARATOR.dup)) { mixin(S_TRACE);
			return parent ~ path;
		}
		return parent ~ SEPARATOR ~ path;
	}
	/// ルートディレクトリを生成する。
	/// ローカル変数のルートディレクトリの場合はownerにローカル変数の所持者を指定する。
	package this (CWXPath owner, string localVariablePrefix) { mixin(S_TRACE);
		_id = .objectIDValue(this);
		_owner = owner;
		_localVariablePrefix = localVariablePrefix;
	}
	/// サブディレクトリを生成する。
	/// Params:
	/// name = ディレクトリ名。
	this (string name) { mixin(S_TRACE);
		_id = .objectIDValue(this);
		_name = validName(name);
	}
	/// コピーコンストラクタ。
	/// サブディレクトリ等も全てコピーされる。
	/// ローカル変数のルートディレクトリの場合はownerにローカル変数の所持者を指定する。
	this (CWXPath owner, in FlagDir copyBase) { mixin(S_TRACE);
		this (owner, copyBase._localVariablePrefix);
		if (copyBase.name != "") name = copyBase.name;
		foreach (d; copyBase.subDirs) { mixin(S_TRACE);
			add(new FlagDir(null, d));
		}
		foreach (f; copyBase.flags) { mixin(S_TRACE);
			add(new Flag(f));
		}
		foreach (s; copyBase.steps) { mixin(S_TRACE);
			add(new Step(s));
		}
		foreach (s; copyBase.variants) { mixin(S_TRACE);
			add(new Variant(s));
		}
	}

	/// ローカル変数のルートディレクトリの場合は、ローカル変数の所持者。
	@property
	inout
	inout(CWXPath) localOwner() { return _owner; }

	@property
	override string cwxPath(bool id) { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			return cpjoin(_owner, "variable", id);
		} else if (_parent) { mixin(S_TRACE);
			return cpjoin(_parent, "dir", .cCountUntil!("a is b")(_parent.subDirs, this), id);
		}
		return "";
	}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "flag": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= flags.length) return null;
			return flags[index].findCWXPath(cpbottom(path));
		}
		case "step": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= steps.length) return null;
			return steps[index].findCWXPath(cpbottom(path));
		}
		case "variant": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= variants.length) return null;
			return variants[index].findCWXPath(cpbottom(path));
		}
		case "dir": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= subDirs.length) return null;
			return subDirs[index].findCWXPath(cpbottom(path));
		}
		default: break;
		}
		return null;
	}
	@property
	inout
	override inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		inout(CWXPath)[] r;
		foreach (a; _flags) r ~= a;
		foreach (a; _steps) r ~= a;
		foreach (a; _variants) r ~= a;
		foreach (a; _subdir) r ~= a;
		return r;
	}
	@property
	CWXPath cwxParent() { return _owner ? _owner : _parent; }

	const
	override
	bool opEquals(Object o) { mixin(S_TRACE);
		if (this is o) return true;
		auto f = cast(const FlagDir)o;
		if (!f) return false;
		return _localVariablePrefix == f._localVariablePrefix
			&& name == f.name
			&& _flagNames == f._flagNames
			&& _stepNames == f._stepNames
			&& _variantNames == f._variantNames
			&& _dirNames == f._dirNames;
	}

	/// 親ディレクトリ。
	@property
	inout
	inout(FlagDir) parent() { mixin(S_TRACE);
		if (_owner) return null;
		return _parent;
	}
	/// ditto
	@property
	private void parent(FlagDir parent) { mixin(S_TRACE);
		assert (!parent || !parent.getSubDir(name));
		_parent = parent;
		useCounter = parent ? parent.useCounter : null;
	}
	/// 変更ハンドラ。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		foreach (f; _flags) { mixin(S_TRACE);
			f.changeHandler = change;
		}
		foreach (s; _steps) { mixin(S_TRACE);
			s.changeHandler = change;
		}
		foreach (s; _variants) { mixin(S_TRACE);
			s.changeHandler = change;
		}
		foreach (s; _subdir) { mixin(S_TRACE);
			s.changeHandler = change;
		}
		_change = change;
	}
	/// ditto
	@property
	const
	void delegate() changeHandler() { mixin(S_TRACE);
		return _change;
	}

	/// 使用回数カウンタ。
	@property
	void useCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (f; _flags) { mixin(S_TRACE);
			f.useCounter = uc;
		}
		foreach (s; _steps) { mixin(S_TRACE);
			s.useCounter = uc;
		}
		foreach (s; _variants) { mixin(S_TRACE);
			s.useCounter = uc;
		}
		foreach (s; _subdir) { mixin(S_TRACE);
			s.useCounter = uc;
		}
		_uc = uc;
	}
	/// ditto
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }

	/// このディレクトリ以下に所属する状態変数が無いか。
	@property
	const
	private bool empty() { return !(hasFlag || hasStep || hasVariant); }

	/// 最上位のディレクトリ。
	@property
	inout
	inout(FlagDir) root() { mixin(S_TRACE);
		// BUG: Rebindable!(typeof(return))は
		//      全然機能しないのでキャストを使う dmd 2.073.2
		FlagDir dir = cast(FlagDir)this;
		while (dir.parent !is null) { mixin(S_TRACE);
			dir = cast(FlagDir)dir.parent;
		}
		return cast(typeof(return))dir;
	}

	/// マシン上で一意なID。ドラッグ&ドロップ等で使用する。
	@property
	const
	string id() { mixin(S_TRACE);
		return _id;
	}

	/// ディレクトリ名。
	@property
	const
	string name() { mixin(S_TRACE);
		return _name;
	}
	/// ditto
	@property
	bool name(string name) { mixin(S_TRACE);
		assert (_owner is null);
		name = FlagDir.validName(name);
		if (!_parent || _parent.canAppendSub(name)) { mixin(S_TRACE);
			if (_name == name) return true;
			if (_change && !empty) _change();
			if (_parent) { mixin(S_TRACE);
				_parent._dirNames.remove(_name);
				_parent._dirNames[name] = this;
			}
			_name = name;
			return true;
		}
		return false;
	}

	@property
	inout
	ref inout(F[string]) names(F)() { mixin(S_TRACE);
		static if (is(F:Flag)) { mixin(S_TRACE);
			return _flagNames;
		} else static if (is(F:Step)) { mixin(S_TRACE);
			return _stepNames;
		} else static if (is(F:Variant)) { mixin(S_TRACE);
			return _variantNames;
		} else static if (is(F:FlagDir)) { mixin(S_TRACE);
			return _dirNames;
		} else static assert (0);
	}

	/// 指定された名前のフラグ・ステップ・サブディレクトリが
	/// 追加可能であればtrueを返す。
	const
	bool canAppend(F)(string name) { mixin(S_TRACE);
		static if (is(F:Flag) || is(F:Step) || is(F:Variant)) {
			name = validName(name);
			if (name.length == 0) { mixin(S_TRACE);
				return false;
			}
			return (name in names!F) is null;
		} else { mixin(S_TRACE);
			static assert (is(F:FlagDir));
			return canAppendSub(name);
		}
	}
	const
	private bool canAppendFlag(in Flag f) { mixin(S_TRACE);
		return canAppend!Flag(f.name);
	}
	/// ditto
	const
	private bool canAppendStep(in Step f) { mixin(S_TRACE);
		return canAppend!Step(f.name);
	}
	/// ditto
	const
	private bool canAppendVariant(in Variant f) { mixin(S_TRACE);
		return canAppend!Variant(f.name);
	}
	/// ditto
	const
	bool canAppendSub(string name) { mixin(S_TRACE);
		name = validName(name);
		if (name.length == 0) { mixin(S_TRACE);
			return false;
		}
		return (name in _dirNames) is null;
	}
	/// 指定されたディレクトリが追加可能であればtrueを返す。
	/// 自分と自分より上位にあるディレクトリを自分の下に持ってくることはできない。
	const
	bool canAppendSub2(in FlagDir ndir) { mixin(S_TRACE);
		if (this is ndir.parent) { mixin(S_TRACE);
			return true;
		}
		Rebindable!(const(FlagDir)) p = this;
		do { mixin(S_TRACE);
			if (p.get is ndir) { mixin(S_TRACE);
				// 自分と自分より上位にあるディレクトリを自分の下に持ってくることはできない
				return false;
			}
			p = p.parent;
		} while (p.get !is null);
		return canAppendSub(ndir.name);
	}

	private bool addImpl(F)(ref F[] arr, F item, bool delegate(in F) canAppend, ptrdiff_t index, bool rename) { mixin(S_TRACE);
		if (index == -1) index = arr.length;
		auto duplicate = item.parent !is this && !canAppend(item);
		if (duplicate && rename) { mixin(S_TRACE);
			item._name = createNewName!F(item.name, "");
			duplicate = false;
		}
		if (!duplicate) { mixin(S_TRACE);
			if (item.parent is this && 0 <= index && index < arr.length && arr[index] is item) { mixin(S_TRACE);
				return true;
			}
			if (item.parent) { mixin(S_TRACE);
				auto i = item.parent.indexOf(item);
				if (item.parent is this && i < index) index--;
				item.parent.remove(item);
			}
			item.parent = this;
			if (index < 0 || arr.length <= index) { mixin(S_TRACE);
				arr ~= item;
			} else { mixin(S_TRACE);
				arr = arr[0 .. index] ~ item ~ arr[index .. $];
			}
			item.changeHandler = _change;
			item.useCounter = _uc;
			names!F[item.name] = item;
			if (_change && !empty) _change();
			return true;
		}
		return false;
	}
	/// フラグ・ステップ・コモン・サブディレクトリを追加する。
	/// 同一名称のリソースがすでに存在する場合は追加を行わずにfalseを返す。
	/// ただしrenameがtrueの場合は名前を変更して追加する。
	bool add(Flag flag, bool rename = false) { mixin(S_TRACE);
		return addImpl!(Flag)(_flags, flag, &canAppendFlag, -1, rename);
	}
	/// ditto
	bool insert(ptrdiff_t index, Flag flag, bool rename = false) { mixin(S_TRACE);
		return addImpl!(Flag)(_flags, flag, &canAppendFlag, index, rename);
	}
	/// ditto
	bool add(Step step, bool rename = false) { mixin(S_TRACE);
		return addImpl!(Step)(_steps, step, &canAppendStep, -1, rename);
	}
	/// ditto
	bool insert(ptrdiff_t index, Step step, bool rename = false) { mixin(S_TRACE);
		return addImpl!(Step)(_steps, step, &canAppendStep, index, rename);
	}
	/// ditto
	bool add(Variant variant, bool rename = false) { mixin(S_TRACE);
		return addImpl!(Variant)(_variants, variant, &canAppendVariant, -1, rename);
	}
	/// ditto
	bool insert(ptrdiff_t index, Variant variant, bool rename = false) { mixin(S_TRACE);
		return addImpl!(Variant)(_variants, variant, &canAppendVariant, index, rename);
	}
	/// ditto
	bool add(FlagDir sub, bool rename = false) { mixin(S_TRACE);
		return addImpl!(FlagDir)(_subdir, sub, &canAppendSub2, -1, rename);
	}
	/// ditto
	bool insert(ptrdiff_t index, FlagDir sub, bool rename = false) { mixin(S_TRACE);
		return addImpl!(FlagDir)(_subdir, sub, &canAppendSub2, index, rename);
	}
	private bool removeImpl(T)(ref T[] arr, T e) { mixin(S_TRACE);
		for (int i = 0; i < arr.length; i++) { mixin(S_TRACE);
			if (cmp(e.name, arr[i].name) == 0) { mixin(S_TRACE);
				e.parent = null;
				arr[i].changeHandler = null;
				arr[i].useCounter = null;
				arr = arr[0 .. i] ~ arr[i + 1 .. $];
				(names!T).remove(e.name);
				static if (is(T:FlagDir)) {
					if (_change && !e.empty) _change();
				} else {
					if (_change) _change();
				}
				return true;
			}
		}
		return false;
	}
	/// フラグ・ステップ・サブディレクトリを除去する。
	void remove(Flag flag) { mixin(S_TRACE);
		removeImpl(_flags, flag);
	}
	/// ditto
	void remove(Step step) { mixin(S_TRACE);
		removeImpl(_steps, step);
	}
	/// ditto
	void remove(Variant variant) { mixin(S_TRACE);
		removeImpl(_variants, variant);
	}
	/// ditto
	void remove(FlagDir dir) { mixin(S_TRACE);
		removeImpl(_subdir, dir);
	}
	void removeAll() { mixin(S_TRACE);
		void removeAllImpl(F)(ref F[] list, ref F[string] table) { mixin(S_TRACE);
			auto empty = this.empty;
			foreach (e; list) {
				e.parent = null;
				e.changeHandler = null;
				e.useCounter = null;
			}
			list = [];
			table = null;
			if (_change && !empty) _change();
		}
		removeAllImpl(_flags, _flagNames);
		removeAllImpl(_steps, _stepNames);
		removeAllImpl(_variants, _variantNames);
		removeAllImpl(_subdir, _dirNames);
	}

	/// サブディレクトリ群。
	@property
	inout
	inout(FlagDir)[] subDirs() { mixin(S_TRACE);
		return _subdir;
	}
	/// フラグ群。
	@property
	inout
	inout(Flag)[] flags() { mixin(S_TRACE);
		return _flags;
	}
	/// ステップ群。
	@property
	inout
	inout(Step)[] steps() { mixin(S_TRACE);
		return _steps;
	}
	/// コモン群。
	@property
	inout
	inout(Variant)[] variants() { mixin(S_TRACE);
		return _variants;
	}
	/// 指定された名前のフラグ・ステップ・サブディレクトリが存在すればtrue。
	const
	bool containsFlag(string name) { mixin(S_TRACE);
		return (name in _flagNames) !is null;
	}
	/// ditto
	const
	bool containsStep(string name) { mixin(S_TRACE);
		return (name in _stepNames) !is null;
	}
	/// ditto
	const
	bool containsVariant(string name) { mixin(S_TRACE);
		return (name in _variantNames) !is null;
	}
	/// ditto
	const
	bool containsSubDir(string name) { mixin(S_TRACE);
		return (name in _dirNames) !is null;
	}
	/// ditto
	const
	bool contains(F)(string name) { mixin(S_TRACE);
		static if (is(F:Flag)) {
			return containsFlag(name);
		} else static if (is(F:Step)) {
			return containsStep(name);
		} else static if (is(F:Variant)) {
			return containsVariant(name);
		} else static assert (0);
	}
	/// 指定された名前のサブディレクトリのindexを返す。
	/// 存在しない場合は-1を返す。
	const
	ptrdiff_t indexOf(string name) { mixin(S_TRACE);
		return .cCountUntil!("0 == cmp(a.name, b)")(_subdir, name);
	}
	/// 指定されたフラグ・ステップ・サブディレクトリのindexを返す。
	const
	ptrdiff_t indexOf(in Flag f) { mixin(S_TRACE);
		return .cCountUntil!("a is b")(_flags, f);
	}
	/// ditto
	const
	ptrdiff_t indexOf(in Step f) { mixin(S_TRACE);
		return .cCountUntil!("a is b")(_steps, f);
	}
	/// ditto
	const
	ptrdiff_t indexOf(in Variant f) { mixin(S_TRACE);
		return .cCountUntil!("a is b")(_variants, f);
	}
	/// ditto
	const
	ptrdiff_t indexOf(in FlagDir f) { mixin(S_TRACE);
		return .cCountUntil!("a is b")(_subdir, f);
	}

	/// フラグ・ステップ・サブディレクトリを名前で検索して取得する。
	/// 存在しない場合はnullを返す。
	inout
	inout(Flag) getFlag(string name) { mixin(S_TRACE);
		auto p = name in _flagNames;
		return p ? *p : null;
	}
	/// ditto
	inout
	inout(Step) getStep(string name) { mixin(S_TRACE);
		auto p = name in _stepNames;
		return p ? *p : null;
	}
	/// ditto
	inout
	inout(Variant) getVariant(string name) { mixin(S_TRACE);
		auto p = name in _variantNames;
		return p ? *p : null;
	}
	/// ditto
	inout
	inout(FlagDir) getSubDir(string name) { mixin(S_TRACE);
		auto p = name in _dirNames;
		return p ? *p : null;
	}

	/// このディレクトリとサブディレクトリの中にある
	/// すべてのフラグ・ステップを返す。
	@property
	inout
	inout(Flag)[] allFlags() { mixin(S_TRACE);
		inout(Flag)[] r;
		foreach (flg; _flags) { mixin(S_TRACE);
			r ~= flg;
		}
		foreach (dir; _subdir) { mixin(S_TRACE);
			r ~= dir.allFlags;
		}
		return r;
	}
	/// ditto
	@property
	inout
	inout(Step)[] allSteps() { mixin(S_TRACE);
		inout(Step)[] r;
		foreach (step; _steps) { mixin(S_TRACE);
			r ~= step;
		}
		foreach (dir; _subdir) { mixin(S_TRACE);
			r ~= dir.allSteps;
		}
		return r;
	}
	/// ditto
	@property
	inout
	inout(Variant)[] allVariants() { mixin(S_TRACE);
		inout(Variant)[] r;
		foreach (variant; _variants) { mixin(S_TRACE);
			r ~= variant;
		}
		foreach (dir; _subdir) { mixin(S_TRACE);
			r ~= dir.allVariants;
		}
		return r;
	}
	/// ditto
	@property
	inout
	inout(FlagDir)[] allSubDirs() { mixin(S_TRACE);
		inout(FlagDir)[] r;
		foreach (dir; _subdir) { mixin(S_TRACE);
			r ~= dir;
			r ~= dir.allSubDirs;
		}
		return r;
	}

	/// このディレクトリ及びサブディレクトリがフラグ・ステップを所持していればtrue。
	@property
	const
	bool hasFlag() { mixin(S_TRACE);
		if (_flags.length) return true;
		foreach (dir; _subdir) { mixin(S_TRACE);
			if (dir.hasFlag) return true;
		}
		return false;
	}
	/// ditto
	@property
	const
	bool hasStep() { mixin(S_TRACE);
		if (_steps.length) return true;
		foreach (dir; _subdir) { mixin(S_TRACE);
			if (dir.hasStep) return true;
		}
		return false;
	}
	/// ditto
	@property
	const
	bool hasVariant() { mixin(S_TRACE);
		if (_variants.length) return true;
		foreach (dir; _subdir) { mixin(S_TRACE);
			if (dir.hasVariant) return true;
		}
		return false;
	}

	/// このディレクトリのフルパスを返す。
	@property
	const
	string path() { mixin(S_TRACE);
		if (_parent !is null) { mixin(S_TRACE);
			return _parent.path ~ _name ~ SEPARATOR;
		} else { mixin(S_TRACE);
			if (_localVariablePrefix == "") { mixin(S_TRACE);
				return "";
			} else { mixin(S_TRACE);
				return SEPARATOR ~ _localVariablePrefix ~ SEPARATOR;
			}
		}
	}

	override void changed() { mixin(S_TRACE);
		if (_change) _change();
	}

	/// 指定されたノードにこのディレクトリ内のフラグとステップのデータを追加する。
	const
	void toNode(ref XNode e, bool createEmptyElement = true) { mixin(S_TRACE);
		if (createEmptyElement || hasFlag) { mixin(S_TRACE);
			auto fe = e.newElement("Flags");
			toNodeFlags(fe);
		}
		if (createEmptyElement || hasStep) { mixin(S_TRACE);
			auto se = e.newElement("Steps");
			toNodeSteps(se);
		}
		if (createEmptyElement || hasVariant) { mixin(S_TRACE);
			auto ve = e.newElement("Variants");
			toNodeVariants(ve);
		}
	}
	const
	private void toNodeFlags(ref XNode e) { mixin(S_TRACE);
		foreach (flag; flags) { mixin(S_TRACE);
			flag.toNode(e);
			foreach (dir; _subdir) { mixin(S_TRACE);
				dir.toNodeFlags(e);
			}
		}
	}
	const
	private void toNodeSteps(ref XNode e) { mixin(S_TRACE);
		foreach (step; steps) { mixin(S_TRACE);
			step.toNode(e);
			foreach (dir; _subdir) { mixin(S_TRACE);
				dir.toNodeSteps(e);
			}
		}
	}
	const
	private void toNodeVariants(ref XNode e) { mixin(S_TRACE);
		foreach (variant; variants) { mixin(S_TRACE);
			variant.toNode(e);
			foreach (dir; _subdir) { mixin(S_TRACE);
				dir.toNodeVariants(e);
			}
		}
	}

	/// フラグパスからフラグ名・ステップ名・サブディレクトリ名だけを
	/// 抜き出して返す。
	static string basename(string path) { mixin(S_TRACE);
		int sepLen = SEPARATOR.length;
		if (path.length < sepLen) { mixin(S_TRACE);
			return path;
		}
		if (endsWith(path, SEPARATOR.dup)) { mixin(S_TRACE);
			path = path[0 .. $ - sepLen];
		}
		for (ptrdiff_t i = path.length - sepLen; i >= 0; i--) { mixin(S_TRACE);
			if (path[i .. i + sepLen] == SEPARATOR) { mixin(S_TRACE);
				return path[i + sepLen .. $];
			}
		}
		return path;
	} unittest { mixin(S_TRACE);
		debug mixin(UTPerf);
		assert (FlagDir.basename("\\test\\") == "test");
		assert (FlagDir.basename("\\aaa\\test") == "test");
		assert (FlagDir.basename("test") == "test");
		assert (FlagDir.basename("\\") == "");
		assert (FlagDir.basename("") == "");
	}

	/// 自分以下のディレクトリツリーに
	/// 指定されたパスのディレクトリが含まれていればtrueを返す。
	/// 同一のディレクトリツリーかどうかは考慮されない。
	bool has(string path) { mixin(S_TRACE);
		path = localPathToPath(path);
		auto tpath = this.path;
		size_t len = path.length;
		size_t tlen = tpath.length;
		size_t sepLen = SEPARATOR.length;
		return (len <= tlen) && (tpath[0 .. len] == path);
	} unittest { mixin(S_TRACE);
		debug mixin(UTPerf);
		auto dir1 = new FlagDir(cast(CWXPath)null, "");
		auto dir2 = new FlagDir("aaaaA");
		dir1.add(dir2);
		auto dir3 = new FlagDir("fsadfawegGGGg");
		dir2.add(dir3);

		auto dir4 = new FlagDir(cast(CWXPath)null, "");
		auto dir5 = new FlagDir("aaaaA");
		dir4.add(dir5);
		auto dir6 = new FlagDir("fsadfawegGGGga");
		dir5.add(dir6);

		assert (dir1.has(dir1.path));
		assert (!dir1.has(dir2.path));
		assert (!dir1.has(dir3.path));
		assert (dir1.has(dir4.path));
		assert (!dir1.has(dir5.path));
		assert (!dir1.has(dir6.path));

		assert (dir2.has(dir1.path));
		assert (dir2.has(dir2.path));
		assert (!dir2.has(dir3.path));
		assert (dir2.has(dir4.path));
		assert (dir2.has(dir5.path));
		assert (!dir2.has(dir6.path));

		assert (dir3.has(dir1.path));
		assert (dir3.has(dir2.path));
		assert (dir3.has(dir3.path));
		assert (dir3.has(dir4.path));
		assert (dir3.has(dir5.path));
		assert (!dir3.has(dir6.path));

		assert (dir4.has(dir1.path));
		assert (!dir4.has(dir2.path));
		assert (!dir4.has(dir3.path));
		assert (dir4.has(dir4.path));
		assert (!dir4.has(dir5.path));
		assert (!dir4.has(dir6.path));

		assert (dir5.has(dir1.path));
		assert (dir5.has(dir2.path));
		assert (!dir5.has(dir3.path));
		assert (dir5.has(dir4.path));
		assert (dir5.has(dir5.path));
		assert (!dir5.has(dir6.path));

		assert (dir6.has(dir1.path));
		assert (dir6.has(dir2.path));
		assert (!dir6.has(dir3.path));
		assert (dir6.has(dir4.path));
		assert (dir6.has(dir5.path));
		assert (dir6.has(dir6.path));
	}

	/// pathの一つ上のディレクトリを指すパスを返す。
	static string up(string path) { mixin(S_TRACE);
		int sepLen = SEPARATOR.length;
		if (path.length < sepLen) { mixin(S_TRACE);
			return null;
		}
		if (path[$ - sepLen .. $] == SEPARATOR) { mixin(S_TRACE);
			path = path[0 .. $ - sepLen];
		}
		for (ptrdiff_t i = path.length - sepLen; i >= 0; i--) { mixin(S_TRACE);
			if (path[i .. i + sepLen] == SEPARATOR) { mixin(S_TRACE);
				return path[0 .. i + sepLen];
			}
		}
		return "";
	} unittest { mixin(S_TRACE);
		debug mixin(UTPerf);
		assert (FlagDir.up("test\\") == "");
		assert (FlagDir.up("\\aaa\\test") == "\\aaa\\");
		assert (FlagDir.up("\\aaa\\test\\t\\") == "\\aaa\\test\\");
		assert (FlagDir.up("test") == "");
		assert (FlagDir.up("") is null);
	}

	/// appendFromXML()の戻り値。
	/// See_Also: appendFromXML()
	static enum AppendXmlResult {
		/// ディレクトリの追加に成功した。
		DIR_SUCCESS,
		/// フラグとステップの追加に成功した。
		FLAG_STEP_SUCCESS,
		/// 追加に失敗した。
		FAIL,
		/// 既に対象ディレクトリが自分自身だったので、末尾に移動した。
		FLAG_STEP_ON_DIR,
		/// 既に親が自分自身だったので、末尾に移動した。
		ON_DIR,
	}

	private static bool loadFS(string Fs, string Fg, F)
			(ref XNode node, FlagDir p, ref F[string] c, bool copy, in XMLInfo ver) { mixin(S_TRACE);
		bool ret = true;
		node.onTag[Fs] = (ref XNode node) { mixin(S_TRACE);
			if (!ret) return;
			node.onTag[Fg] = (ref XNode n) { mixin(S_TRACE);
				if (!ret) return;
				auto f = F.createFromNode(n, ver);
				if (!copy && !p.canAppend!F(f.name)) { mixin(S_TRACE);
					ret = false;
					return;
				}
				c[removePrefix(n.childText("Name", true))] = f;
			};
			node.parse();
		};
		node.parse();
		return ret;
	}
	private bool loadVariables(ref XNode node, ref Flag[string] cFlags, ref Step[string] cSteps, ref Variant[string] cVariants, bool copy, in XMLInfo ver) { mixin(S_TRACE);
		void clearAll() { mixin(S_TRACE);
			.removeAll(cFlags);
			.removeAll(cSteps);
			.removeAll(cVariants);
		}
		try { mixin(S_TRACE);
			Flag[string] cFlags2;
			if (!loadFS!("Flags", "Flag", Flag)(node, this, cFlags2, copy, ver)) { mixin(S_TRACE);
				clearAll();
				return false;
			}
			Step[string] cSteps2;
			if (!loadFS!("Steps", "Step", Step)(node, this, cSteps2, copy, ver)) { mixin(S_TRACE);
				clearAll();
				return false;
			}
			Variant[string] cVariants2;
			if (!loadFS!("Variants", "Variant", Variant)(node, this, cVariants2, copy, ver)) { mixin(S_TRACE);
				clearAll();
				return false;
			}
			foreach (k, v; cFlags2) { mixin(S_TRACE);
				if (copy && !canAppend!Flag(v.name)) { mixin(S_TRACE);
					v.name = createNewFlagName(v.name, "");
				}
				auto r = this.add(v);
				assert (r, v.name);
				cFlags[k] = v;
			}
			foreach (k, v; cSteps2) { mixin(S_TRACE);
				if (copy && !canAppend!Step(v.name)) { mixin(S_TRACE);
					v.name = createNewStepName(v.name, "");
				}
				auto r = this.add(v);
				assert (r, v.name);
				cSteps[k] = v;
			}
			foreach (k, v; cVariants2) { mixin(S_TRACE);
				if (copy && !canAppend!Variant(v.name)) { mixin(S_TRACE);
					v.name = createNewVariantName(v.name, "");
				}
				auto r = this.add(v);
				assert (r, v.name);
				cVariants[k] = v;
			}
			return true;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			clearAll();
			return false;
		}
	}
	private FlagDir loadSubs(ref XNode node, ref Flag[string] cFlags, ref Step[string] cSteps, ref Variant[string] cVariants, bool copy, in XMLInfo ver) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			auto subName = basename(node.attr("path", true));
			if (subName.length == 0) { mixin(S_TRACE);
				subName = validName(node.attr("rootName", true));
			}
			if (!canAppendSub(subName)) { mixin(S_TRACE);
				if (copy) { mixin(S_TRACE);
					subName = createNewDirName(subName, "");
				} else { mixin(S_TRACE);
					return null;
				}
			}
			auto sub = new FlagDir(subName);
			if (!sub.loadVariables(node, cFlags, cSteps, cVariants, false, ver)) { mixin(S_TRACE);
				assert (cFlags.length == 0);
				assert (cSteps.length == 0);
				assert (cVariants.length == 0);
				return null;
			}
			bool ret = true;
			node.onTag["FlagDirectory"] = (ref XNode n) { mixin(S_TRACE);
				if (!ret) return;
				if (!sub.loadSubs(n, cFlags, cSteps, cVariants, false, ver)) { mixin(S_TRACE);
					ret = false;
					return;
				}
			};
			node.parse();
			if (ret) { mixin(S_TRACE);
				this.add(sub);
				return sub;
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		.removeAll(cFlags);
		.removeAll(cSteps);
		.removeAll(cVariants);
		return null;
	}
	private bool readAtt(in XNode node, out string rootId, out string path, out bool sameTree) { mixin(S_TRACE);
		path = null;
		sameTree = false;
		rootId = node.attr(XML_ATT_ROOT_ID, false, "");
		path = node.attr(XML_ATT_PATH, false, "");
		if (rootId !is null && path !is null) { mixin(S_TRACE);
			sameTree = this.root.id == rootId;
			return true;
		} else { mixin(S_TRACE);
			return false;
		}
	}
	/// XML文からの追加処理が可能であれば追加してtrueを返す。
	/// getXml()で取得したXML文でない場合は失敗し、falseを返す。
	/// また、copy = falseの時、以下の場合は追加せずにfalseを返す:
	/// (1) 追加されるディレクトリはルートである(ルートディレクトリを削除することはできないため)、
	/// (2) 追加されるフラグ/ステップと同名のフラグ/ステップがすでに存在する、
	/// (3) 同様に同名のサブディレクトリが存在する、
	/// (4) 追加するディレクトリはこのディレクトリより上位か同一のディレクトリである。
	/// copy = trueの時、同名のサブディレクトリ/フラグ/ステップがあれば末尾に" (数字)"をつける。
	/// Params:
	/// xml = XML文。
	/// copy = コピーであればtrue、移動であればfalse。
	/// dirMode = ディレクトリの転送を受け付けるか。
	/// newPath = AppendXmlResult.DIR_SUCCESSの場合、追加したディレクトリの新たなパスが格納される。
	/// cFlags = 移動またはコピーしたフラグの旧パスをキーにして新たなフラグを格納する。
	/// cSteps = 移動またはコピーしたステップの旧パスをキーにして新たなステップを格納する。
	/// cVariants = 移動またはコピーしたコモンの旧パスをキーにして新たなコモンを格納する。
	/// Returns: XMLからの追加を試みた結果。
	/// See_Also: getXml(FlagDir, Flag[], Step[], Variant[]), getXml(FlagDir)
	AppendXmlResult appendFromXML(string xml, in XMLInfo ver, bool copy, bool dirMode, bool local,
			out Flag[string] cFlags, out Step[string] cSteps, out Variant[string] cVariants,
			out string newPath, out string rootId) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			auto doc = XNode.parse(xml);
			return appendFromNode(doc, ver, copy, dirMode, local, cFlags, cSteps, cVariants, newPath, rootId);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return AppendXmlResult.FAIL;
	}
	/// ditto
	AppendXmlResult appendFromNode(ref XNode doc, in XMLInfo ver, bool copy, bool dirMode, bool local,
			out Flag[string] cFlags, out Step[string] cSteps, out Variant[string] cVariants,
			out string newPath, out string rootId) { mixin(S_TRACE);
		newPath = null;
		rootId = "";
		rootId = doc.attr(XML_ATT_ROOT_ID, false, "");

		void validateInitialization() { mixin(S_TRACE);
			void validateInitializationImpl(F)(F[string] cs) { mixin(S_TRACE);
				foreach (f; cs) { mixin(S_TRACE);
					if (local && f.initialization is VariableInitialization.Complete) f.initialization = VariableInitialization.None;
					if (!local && f.initialization is VariableInitialization.EventExit) f.initialization = VariableInitialization.Leave;
				}
			}
			validateInitializationImpl(cFlags);
			validateInitializationImpl(cSteps);
			validateInitializationImpl(cVariants);
		}

		if (doc.name == XML_ROOT_FLAGS_AND_STEPS) { mixin(S_TRACE);
			string path;
			bool sameTree;
			if (readAtt(doc, rootId, path, sameTree)) { mixin(S_TRACE);
				if (!copy && sameTree && cmp(this.path, path) == 0) { mixin(S_TRACE);
					// 転送されてきたのが自分自身の場合は末尾に移し変えて終了
					doc.onTag["Flags"] = (ref XNode node) { mixin(S_TRACE);
						doc.onTag["Flag"] = (ref XNode node) { mixin(S_TRACE);
							add(getFlag(removePrefix(node.childText("Name", true))));
						};
						node.parse();
					};
					doc.onTag["Steps"] = (ref XNode node) { mixin(S_TRACE);
						doc.onTag["Step"] = (ref XNode node) { mixin(S_TRACE);
							add(getStep(removePrefix(node.childText("Name", true))));
						};
						node.parse();
					};
					doc.onTag["Variants"] = (ref XNode node) { mixin(S_TRACE);
						doc.onTag["Variant"] = (ref XNode node) { mixin(S_TRACE);
							add(getVariant(removePrefix(node.childText("Name", true))));
						};
						node.parse();
					};
					doc.parse();
					return AppendXmlResult.FLAG_STEP_ON_DIR;
				}
				if (loadVariables(doc, cFlags, cSteps, cVariants, copy, ver)) { mixin(S_TRACE);
					validateInitialization();
					return AppendXmlResult.FLAG_STEP_SUCCESS;
				}
			}
			return AppendXmlResult.FAIL;
		}
		if (dirMode && doc.name == XML_ROOT_FLAG_DIRECTORY) { mixin(S_TRACE);
			auto r = loadRootFlagDirectory(doc, ver, copy, cFlags, cSteps, cVariants, newPath);
			validateInitialization();
			return r;
		}
		return AppendXmlResult.FAIL;
	}
	private AppendXmlResult loadRootFlagDirectory(ref XNode node, in XMLInfo ver, bool copy,
			ref Flag[string] cFlags, ref Step[string] cSteps, ref Variant[string] cVariants,
			out string newPath) { mixin(S_TRACE);
		newPath = null;
		string rootId;
		string path;
		bool sameTree;
		if (readAtt(node, rootId, path, sameTree)) { mixin(S_TRACE);
			auto dirName = basename(path);
			if (!copy) { mixin(S_TRACE);
				if (path.length == 0) { mixin(S_TRACE);
					// ルートディレクトリは移動不可
					return AppendXmlResult.FAIL;
				}
				if (sameTree && cmp(this.path, up(path)) == 0) { mixin(S_TRACE);
					// 転送されてきたのが自分自身の場合は末尾に移し変えて終了
					auto d = getSubDir(dirName);
					add(d);
					newPath = d.path;
					return AppendXmlResult.ON_DIR;
				}
				if (sameTree && has(path)) { mixin(S_TRACE);
					// 同一ツリー内で送り手と受け手が矛盾する
					return AppendXmlResult.FAIL;
				}
				if (!canAppendSub(dirName)) { mixin(S_TRACE);
					// 同一名のサブディレクトリがすでに存在する
					return AppendXmlResult.FAIL;
				}
			}
			auto sub = loadSubs(node, cFlags, cSteps, cVariants, copy, ver);
			if (sub) { mixin(S_TRACE);
				newPath = sub.path;
			}  else { mixin(S_TRACE);
				return AppendXmlResult.FAIL;
			}
			return AppendXmlResult.DIR_SUCCESS;
		}
		return AppendXmlResult.FAIL;
	}

	/// 指定されたディレクトリ以下のサブディレクトリに
	/// pathと一致するものがあれば返す。
	static FlagDir searchPath(FlagDir root, string path) { mixin(S_TRACE);
		assert (root.parent is null);
		int sepLen = SEPARATOR.length;
		if (endsWith(path, FlagDir.SEPARATOR.dup)) { mixin(S_TRACE);
			path = path[0 .. $ - sepLen];
		}
		auto paths = std.string.split(path, SEPARATOR.dup);
		auto dir = root;

		loop: for (int lev = 0; lev < paths.length; lev++) { mixin(S_TRACE);
			foreach (sub; dir.subDirs) { mixin(S_TRACE);
				if (cmp(paths[lev], sub.name) == 0) { mixin(S_TRACE);
					if (lev < paths.length - 1) { mixin(S_TRACE);
						dir = sub;
						continue loop;
					} else { mixin(S_TRACE);
						return sub;
					}
				}
			}
			break;
		}
		return null;
	}

	/// 指定された文字列をフラグ・ステップ・ディレクトリ名として
	/// 正当な名前に変換する。
	/// フラグ・ステップ・ディレクトリ名にパス区切り文字'\'を使う事は出来ない。
	static string validName(string name) { mixin(S_TRACE);
		if (!name.length) { mixin(S_TRACE);
			name = "_";
		}
		string fsep = SEPARATOR;
		return replace(name, fsep, "");
	}

	/// baseをこのディレクトリに追加可能な名前に加工して返す。
	/// base = xxxxの場合、xxxxというフラグがすでに存在すればxxxx (2)、
	/// さらにxxxx (2)というフラグが存在すればxxxx (3)……というように、
	/// 付記した数字をインクリメントしていく。
	string createNewFlagName(string base, string oldName) { mixin(S_TRACE);
		return .createNewName(validName(base), (string name) { mixin(S_TRACE);
			if (oldName && oldName.length && oldName == name) return true;
			return canAppend!Flag(name);
		});
	}
	/// ditto
	string createNewStepName(string base, string oldName) { mixin(S_TRACE);
		return .createNewName(validName(base), (string name) { mixin(S_TRACE);
			if (oldName && oldName.length && oldName == name) return true;
			return canAppend!Step(name);
		});
	}
	/// ditto
	string createNewVariantName(string base, string oldName) { mixin(S_TRACE);
		return .createNewName(validName(base), (string name) { mixin(S_TRACE);
			if (oldName && oldName.length && oldName == name) return true;
			return canAppend!Variant(name);
		});
	}
	/// ditto
	string createNewDirName(string base, string oldName) { mixin(S_TRACE);
		return .createNewName(validName(base), (string name) { mixin(S_TRACE);
			if (oldName && oldName.length && oldName == name) return true;
			return canAppendSub(name);
		});
	}
	/// ditto
	string createNewName(F)(string base, string oldName) { mixin(S_TRACE);
		static if (is(F:Flag)) {
			return createNewFlagName(base, oldName);
		} else static if (is(F:Step)) {
			return createNewStepName(base, oldName);
		} else static if (is(F:Variant)) {
			return createNewVariantName(base, oldName);
		} else static if (is(F:FlagDir)) {
			return createNewDirName(base, oldName);
		} else static assert (0);
	}

	/// 新しい名前をn件生成して返す。
	private string[] createNewNames(F)(string base, size_t n, in string[] oldNames)
	out (value) { mixin(S_TRACE);
		assert (value.length == n);
	} body { mixin(S_TRACE);
		auto oldSet = new HashSet!string;
		foreach (name; oldNames) oldSet.add(name.toLower());
		auto set = new HashSet!string;
		string[] r;
		foreach (i; 0..n) { mixin(S_TRACE);
			auto name = .createNewName(validName(base), (string name) { mixin(S_TRACE);
				return (canAppend!F(name) || oldSet.contains(name.toLower())) && !set.contains(name.toLower());
			});
			set.add(name.toLower());
			r ~= name;
		}
		return r;
	}
	/// ditto
	string[] createNewFlagNames(string base, size_t n, in string[] oldNames)
	out (value) { mixin(S_TRACE);
		assert (value.length == n);
	} body { mixin(S_TRACE);
		return createNewNames!Flag(base, n, oldNames);
	}
	/// ditto
	string[] createNewStepNames(string base, size_t n, in string[] oldNames)
	out (value) { mixin(S_TRACE);
		assert (value.length == n);
	} body { mixin(S_TRACE);
		return createNewNames!Step(base, n, oldNames);
	}
	/// ditto
	string[] createNewVariantNames(string base, size_t n, in string[] oldNames)
	out (value) { mixin(S_TRACE);
		assert (value.length == n);
	} body { mixin(S_TRACE);
		return createNewNames!Variant(base, n, oldNames);
	}
	/// ditto
	string[] createNewDirNames(string base, size_t n, in string[] oldNames)
	out (value) { mixin(S_TRACE);
		assert (value.length == n);
	} body { mixin(S_TRACE);
		return createNewNames!FlagDir(base, n, oldNames);
	}

	/// 指定されたパスを探して返す。
	/// Params:
	/// path = パス。
	/// create = trueの場合、見つからなかったときに生成する。
	/// Returns: 見つかったパス。見つからず、生成もしない場合はnull。
	FlagDir findPath(string path, bool create) { mixin(S_TRACE);
		path = localPathToPath(path);
		if (path.length == 0) { mixin(S_TRACE);
			return root;
		} else { mixin(S_TRACE);
			string fsep = SEPARATOR;
			auto paths = std.string.split(path, fsep);
			if (paths.length == 0) { mixin(S_TRACE);
				return root;
			}
			return root.findPathSub(paths[0 .. $ - 1], create);
		}
	}
	inout
	inout(FlagDir) findPath(string path) { mixin(S_TRACE);
		path = localPathToPath(path);
		if (path.length == 0) { mixin(S_TRACE);
			return root;
		} else { mixin(S_TRACE);
			string fsep = SEPARATOR;
			auto paths = std.string.split(path, fsep);
			if (paths.length == 0) { mixin(S_TRACE);
				return root;
			}
			return root.findPathSub(paths[0 .. $ - 1]);
		}
	}
	private FlagDir findPathSub(string[] paths, bool create) { mixin(S_TRACE);
		auto sub = getSubDir(paths[0]);
		if (sub is null) { mixin(S_TRACE);
			if (create) { mixin(S_TRACE);
				if (canAppendSub(paths[0])) { mixin(S_TRACE);
					sub = new FlagDir(paths[0]);
					this.add(sub);
				} else { mixin(S_TRACE);
					return null;
				}
			} else { mixin(S_TRACE);
				return null;
			}
		}
		if (paths.length == 1) { mixin(S_TRACE);
			return sub;
		} else { mixin(S_TRACE);
			return sub.findPathSub(paths[1 .. $], create);
		}
	}
	inout
	private inout(FlagDir) findPathSub(string[] paths) { mixin(S_TRACE);
		auto sub = getSubDir(paths[0]);
		if (sub is null) { mixin(S_TRACE);
			return null;
		}
		if (paths.length == 1) { mixin(S_TRACE);
			return sub;
		} else { mixin(S_TRACE);
			return sub.findPathSub(paths[1 .. $]);
		}
	}
	/// 指定されたパスのフラグを探して返す。
	/// Params:
	/// path = パス。
	/// Returns: 見つかったフラグ。見つからなかった場合はnull。
	Flag findFlag(string path) { mixin(S_TRACE);
		path = localPathToPath(path);
		if (path.length > 0) { mixin(S_TRACE);
			auto dir = findPath(up(path), false);
			if (dir !is null) { mixin(S_TRACE);
				return dir.getFlag(basename(path));
			}
		}
		return null;
	}
	/// ditto
	const
	const(Flag) findFlag(string path) { mixin(S_TRACE);
		path = localPathToPath(path);
		if (path.length > 0) { mixin(S_TRACE);
			auto dir = findPath(up(path));
			if (dir !is null) { mixin(S_TRACE);
				return dir.getFlag(basename(path));
			}
		}
		return null;
	}
	/// 指定されたパスのステップを探して返す。
	/// Params:
	/// path = パス。
	/// Returns: 見つかったステップ。見つからなかった場合はnull。
	Step findStep(string path) { mixin(S_TRACE);
		path = localPathToPath(path);
		if (path.length > 0) { mixin(S_TRACE);
			auto dir = findPath(up(path), false);
			if (dir !is null) { mixin(S_TRACE);
				return dir.getStep(basename(path));
			}
		}
		return null;
	}
	/// ditto
	const
	const(Step) findStep(string path) { mixin(S_TRACE);
		path = localPathToPath(path);
		if (path.length > 0) { mixin(S_TRACE);
			auto dir = findPath(up(path));
			if (dir !is null) { mixin(S_TRACE);
				return dir.getStep(basename(path));
			}
		}
		return null;
	}
	/// 指定されたパスのコモンを探して返す。
	/// Params:
	/// path = パス。
	/// Returns: 見つかったコモン。見つからなかった場合はnull。
	Variant findVariant(string path) { mixin(S_TRACE);
		path = localPathToPath(path);
		if (path.length > 0) { mixin(S_TRACE);
			auto dir = findPath(up(path), false);
			if (dir !is null) { mixin(S_TRACE);
				return dir.getVariant(basename(path));
			}
		}
		return null;
	}
	/// ditto
	const
	const(Variant) findVariant(string path) { mixin(S_TRACE);
		path = localPathToPath(path);
		if (path.length > 0) { mixin(S_TRACE);
			auto dir = findPath(up(path));
			if (dir !is null) { mixin(S_TRACE);
				return dir.getVariant(basename(path));
			}
		}
		return null;
	}
	/// ditto
	F find(F)(string path) { mixin(S_TRACE);
		static if (is(F:Flag)) {
			return findFlag(path);
		} else static if (is(F:Step)) {
			return findStep(path);
		} else static if (is(F:Variant)) {
			return findVariant(path);
		} else static assert (0);
	}
	/// ditto
	const
	const(F) find(F)(string path) { mixin(S_TRACE);
		static if (is(F:Flag)) {
			return findFlag(path);
		} else static if (is(F:Step)) {
			return findStep(path);
		} else static if (is(F:Variant)) {
			return findVariant(path);
		} else static assert (0);
	}

	const
	private string localPathToPath(string path) { mixin(S_TRACE);
		auto p2 = removePrefix(path);
		if (p2 == path) return path;
		if (path.length - p2.length - SEPARATOR.length <= SEPARATOR.length) return "";
		auto prefix = path[SEPARATOR.length .. path.length - p2.length - SEPARATOR.length];
		if (prefix == root._localVariablePrefix) return p2;
		return "";
	}

	/// 配下にある全てのフラグとステップのデータをノードに追加する。
	const
	void toNodeAll(ref XNode node, bool logicalSort, bool createEmptyElement = true) { mixin(S_TRACE);
		if (createEmptyElement || hasFlag) { mixin(S_TRACE);
			auto fe = node.newElement("Flags");
			// BUG: std.algorithm.sortがconstレンジを受け付けない
			.sortedWithPath(cast(Flag[])allFlags, logicalSort, (Flag flag) { mixin(S_TRACE);
				flag.toNode(fe);
			});
		}
		if (createEmptyElement || hasStep) { mixin(S_TRACE);
			auto se = node.newElement("Steps");
			.sortedWithPath(cast(Step[])allSteps, logicalSort, (Step step) { mixin(S_TRACE);
				step.toNode(se);
			});
		}
		if (createEmptyElement || hasVariant) { mixin(S_TRACE);
			auto ve = node.newElement("Variants");
			.sortedWithPath(cast(Variant[])allVariants, logicalSort, (Variant variant) { mixin(S_TRACE);
				variant.toNode(ve);
			});
		}
	}

	/// XMLノードを元に、フラグディレクトリのツリーを生成して返す。
	void fromXmlNode(ref XNode node, in XMLInfo ver, bool startParse = true) { mixin(S_TRACE);
		node.onTag["Flags"] = (ref XNode node) { mixin(S_TRACE);
			fromXmlNodeImpl!(Flag)(node, this, "Flag", &Flag.createFromNode, ver);
		};
		node.onTag["Steps"] = (ref XNode node) { mixin(S_TRACE);
			fromXmlNodeImpl!(Step)(node, this, "Step", &Step.createFromNode, ver);
		};
		node.onTag["Variants"] = (ref XNode node) { mixin(S_TRACE);
			fromXmlNodeImpl!(Variant)(node, this, "Variant", &Variant.createFromNode, ver);
		};
		if (startParse) node.parse();
	}
	private static string removePrefix(string path) { mixin(S_TRACE);
		if (path.startsWith(SEPARATOR)) { mixin(S_TRACE);
			path = path[SEPARATOR.length .. $];
			auto i = path.indexOf(SEPARATOR);
			if (i != -1) { mixin(S_TRACE);
				return path[i + 1 .. $];
			}
		}
		return path;
	}
	private static void fromXmlNodeImpl(E)(ref XNode node,
			FlagDir root, string es, E function(ref XNode, in XMLInfo) pfunc, in XMLInfo ver) { mixin(S_TRACE);
		node.onTag[es] = (ref XNode e) { mixin(S_TRACE);
			auto path = removePrefix(e.childText("Name", false));
			if (path) { mixin(S_TRACE);
				auto parent = up(path);
				auto dir = parent !is null ? root.findPath(parent, true) : root;
				auto f = pfunc(e, ver);
				if (!f || !dir.canAppend!E(f.name)) { mixin(S_TRACE);
					throw new FlagException(es ~ " parse error: " ~ path);
				}
				dir.add(f);
			} else { mixin(S_TRACE);
				throw new FlagException(es ~ " name not found.");
			}
		};
		node.parse();
	}

	/// ディレクトリの名前を変更する。
	/// 配下のすべてのフラグとステップのパス変更が
	/// ucによって通知される。
	bool rename(string name, UseCounter uc) { mixin(S_TRACE);
		auto flags = allFlags;
		auto oldFlagPaths = new string[flags.length];
		foreach (i, flag; flags) { mixin(S_TRACE);
			oldFlagPaths[i] = flag.path;
		}
		auto steps = allSteps;
		auto oldStepPaths = new string[steps.length];
		foreach (i, step; steps) { mixin(S_TRACE);
			oldStepPaths[i] = step.path;
		}
		auto variants = allVariants;
		auto oldVariantPaths = new string[variants.length];
		foreach (i, variant; variants) { mixin(S_TRACE);
			oldVariantPaths[i] = variant.path;
		}
		string p = this.path;
		size_t plen = p.length;
		if (!.endsWith(p, FlagDir.SEPARATOR.idup)) { mixin(S_TRACE);
			plen += FlagDir.SEPARATOR.length;
		}

		if (!this.name(name)) { mixin(S_TRACE);
			return false;
		}
		p = this.path;
		foreach (path; oldFlagPaths) { mixin(S_TRACE);
			auto newPath = FlagDir.join(p, path[plen .. $]);
			uc.change(toFlagId(path), toFlagId(newPath));
		}
		foreach (path; oldStepPaths) { mixin(S_TRACE);
			auto newPath = FlagDir.join(p, path[plen .. $]);
			uc.change(toStepId(path), toStepId(newPath));
		}
		foreach (path; oldVariantPaths) { mixin(S_TRACE);
			auto newPath = FlagDir.join(p, path[plen .. $]);
			uc.change(toVariantId(path), toVariantId(newPath));
		}
		return true;
	}
}

/// 名前によって整列されたvarsを処理する。
void sortedWithName(F)(F[] vars, bool logicalSort, void delegate(F) yield) { mixin(S_TRACE);
	if (logicalSort) { mixin(S_TRACE);
		bool cmpsN(in F f1, in F f2) { mixin(S_TRACE);
			return .ncmp(f1.name, f2.name) < 0;
		}
		foreach (f; std.algorithm.sort!cmpsN(vars.dup)) yield(f);
	} else { mixin(S_TRACE);
		bool cmps(in F f1, in F f2) { mixin(S_TRACE);
			return .cmp(f1.name, f2.name) < 0;
		}
		foreach (f; std.algorithm.sort!cmps(vars.dup)) yield(f);
	}
}

/// パスによって整列されたvarsを処理する。
void sortedWithPath(F)(F[] vars, bool logicalSort, void delegate(F) yield) { mixin(S_TRACE);
	if (logicalSort) { mixin(S_TRACE);
		bool cmpsN(in F f1, in F f2) { mixin(S_TRACE);
			auto a = std.string.split(f1.path, FlagDir.SEPARATOR);
			auto b = std.string.split(f2.path, FlagDir.SEPARATOR);
			for (size_t i = 0; i < a.length || i < b.length; i++) { mixin(S_TRACE);
				if (a.length <= i) return true;
				if (b.length <= i) return false;
				auto c = .ncmp(a[i], b[i]);
				if (c != 0) return c < 0;
			}
			return false;
		}
		foreach (f; std.algorithm.sort!cmpsN(vars.dup)) yield(f);
	} else { mixin(S_TRACE);
		bool cmps(in F f1, in F f2) { mixin(S_TRACE);
			auto a = std.string.split(f1.path, FlagDir.SEPARATOR);
			auto b = std.string.split(f2.path, FlagDir.SEPARATOR);
			for (size_t i = 0; i < a.length || i < b.length; i++) { mixin(S_TRACE);
				if (a.length <= i) return true;
				if (b.length <= i) return false;
				auto c = .cmp(a[i], b[i]);
				if (c != 0) return c < 0;
			}
			return false;
		}
		foreach (f; std.algorithm.sort!cmps(vars.dup)) yield(f);
	}
}

/// ローカル変数を含めて状態変数を検索する。
inout(F) findVar(F)(inout(FlagDir) froot, inout(UseCounter) uc, string flag) { mixin(S_TRACE);
	import cwx.card;
	if (uc) { mixin(S_TRACE);
		auto owner = uc.owner;
		if (auto ec = cast(inout(LocalVariableOwner))owner) { mixin(S_TRACE);
			auto f = cast(typeof(return))ec.flagDirRoot.find!F(flag);
			if (f) return f;
		}
	}
	if (froot) { mixin(S_TRACE);
		return cast(typeof(return))froot.find!F(flag);
	}
	return null;
}
/// ローカル変数を含む全ての状態変数を返す。
inout(F)[] allVars(F)(inout(FlagDir) froot, inout(UseCounter) uc) { mixin(S_TRACE);
	import cwx.card;
	inout(F)[] r;
	if (uc) { mixin(S_TRACE);
		auto owner = uc.owner;
		if (auto ec = cast(inout(LocalVariableOwner))owner) { mixin(S_TRACE);
			static if (is(F:Flag)) {
				r ~= ec.flagDirRoot.allFlags;
			} else static if (is(F:Step)) {
				r ~= ec.flagDirRoot.allSteps;
			} else static if (is(F:Variant)) {
				r ~= ec.flagDirRoot.allVariants;
			} else static assert (0);
		}
	}
	if (froot) { mixin(S_TRACE);
		static if (is(F:Flag)) {
			r ~= froot.allFlags;
		} else static if (is(F:Step)) {
			r ~= froot.allSteps;
		} else static if (is(F:Variant)) {
			r ~= froot.allVariants;
		} else static assert (0);
	}
	return r;
}


module cwx.flag;

import cwx.utils;
import cwx.xml;
import cwx.path;

import std.string;
import std.regexp;
import std.date;

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
	this(string msg) {
		super(msg);
	}
}

/// フラグとステップの集合をXMLにして返す。
public string getXML(FlagDir parent, Flag[] flags, Step[] steps) {
	auto e = XNode.create(XML_ROOT_FLAGS_AND_STEPS);
	auto _root = parent.root;
	e.newAttr(XML_ATT_PATH, parent.path);
	e.newAttr( XML_ATT_ROOT_ID, _root.id);
	auto fe = e.newElement("Flags");
	foreach (flag; flags) {
		assert (flag.parent.root == _root);
		assert (flag.parent == parent);
		flag.toNode(fe);
	}
	auto se = e.newElement("Steps");
	foreach (step; steps) {
		assert (step.parent.root == _root);
		assert (step.parent == parent);
		step.toNode(se);
	}
	return e.text;
}

/// フラグのディレクトリとその配下の内容をXMLにして返す。
public string getXML(string rootName, FlagDir dir) {
	auto ret = XNode.create(XML_ROOT_FLAG_DIRECTORY);
	toNode(ret, dir);
	auto _root = dir.root;
	ret.newAttr(XML_ATT_ROOT_ID, _root.id);
	if (_root == dir) {
		ret.newAttr(XML_ATT_ROOT_NAME, rootName);
	}
	return ret.text;
}
private void toNode(ref XNode ret, FlagDir dir) {
	ret.newAttr(XML_ATT_PATH, dir.path);
	auto fe = ret.newElement("Flags");
	foreach (flag; dir.flags) {
		flag.toNode(fe);
	}
	auto se = ret.newElement("Steps");
	foreach (step; dir.steps) {
		step.toNode(se);
	}
	foreach (subdir; dir.subDirs) {
		toNode(ret.newElement(XML_ROOT_FLAG_DIRECTORY), subdir);
	}
}

/// フラグ。
public class Flag : CWXPath {
private:
	string _name;
	string _on;
	string _off;
	bool _onOff;
	FlagDir _parent;
	void delegate() _change = null;
public:
	/// コピーコンストラクタ。
	this(Flag copyBase) {
		_name = copyBase.name;
		_on = copyBase.on;
		_off = copyBase.off;
		_onOff = copyBase.onOff;
	}
	/// 名前・On/Off時のテキスト・On/Off状態を指定してインスタンスを生成。
	this(string name, string on, string off, bool onOff) {
		_on = on;
		_off = off;
		_onOff = onOff;
		_name = FlagDir.validName(name);
	}
	/// このフラグの親ディレクトリ。
	FlagDir parent() {
		return _parent;
	}
	/// ditto
	private void parent(FlagDir parent) {
		assert (!parent || !parent.getFlag(name));
		_parent = parent;
	}
	/// 最上位のディレクトリ。
	FlagDir root() {
		return _parent.root;
	}
	/// 変更ハンドラを設定する。
	void changeHandler(void delegate() change) {
		_change = change;
	}
	/// フラグ名。同一のディレクトリ内では重複しない。
	string name() {
		return _name;
	}
	/// ditto
	bool name(string name) {
		name = FlagDir.validName(name);
		if (!_parent || _parent.canAppendFS(name)) {
			if (_change && _name != name) _change();
			_name = name;
			return true;
		}
		return false;
	}
	/// On時のテキスト。
	string on() {
		return _on;
	}
	/// ditto
	void on(string on) {
		if (_change && _on != on) _change();
		_on = on;
	}
	/// Off時のテキスト。
	string off() {
		return _off;
	}
	/// ditto
	void off(string off) {
		if (_change && _off != off) _change();
		_off = off;
	}
	/// On/Off初期状態。
	bool onOff() {
		return _onOff;
	}
	/// ditto
	void onOff(bool onOff) {
		if (_change && _onOff != onOff) _change();
		_onOff = onOff;
	}
	override int opCmp(Object o) {
		return icmp(name, (cast(Flag) o).name);
	}
	/// このフラグのフルパスを返す。
	string path() {
		return _parent.path ~ _name;
	}

	/// このフラグをXMLテキストにする。
	string toXml() {
		auto doc = XNode.create(XML_ROOT_FLAG_DIRECTORY);
		toNode(doc);
		return doc.text;
	}
	/// XMLノードからインスタンスを生成。
	static Flag createFromNode(ref XNode fe, string ver) {
		string name = null;
		string tv = "TRUE";
		string fv = "FALSE";
		bool def = parseBool(fe.attr("default", true));
		fe.onTag["Name"] = (ref XNode n) {name = FlagDir.basename(n.value);};
		fe.onTag["True"] = (ref XNode n) {tv = n.value;};
		fe.onTag["False"] = (ref XNode n) {fv = n.value;};
		fe.parse;
		if (!name) throw new FlagException("Flag name not found.");
		return new Flag(name, tv, fv, def);
	}
	/// XMLノードへこのフラグのデータを追加する。
	void toNode(ref XNode node) {
		auto e = node.newElement("Flag");
		e.newAttr("default", fromBool(_onOff));
		e.newElement("Name", path);
		e.newElement("True", on);
		e.newElement("False", off);
	}
	override string cwxPath() {
		return cpjoin(_parent, "flag", indexOf!("a is b")(_parent.flags, this));
	}
}

/// ステップ。
public class Step : CWXPath {
private:
	string _name;
	string[] _vals;
	uint _select;
	FlagDir _parent;
	void delegate() _change = null;
public:
	/// コピーコンストラクタ。
	this(Step copyBase) {
		_name = copyBase.name;
		_vals = copyBase._vals.dup;
		_select = copyBase._select;
	}
	/// ステップ名、各段階のステップ値、選択状態を指定してインスタンスを生成。
	this(string name, string[] vals, uint select) {
		_vals = vals;
		_select = select;
		_name = FlagDir.validName(name);
	}
	/// このステップの親ディレクトリ。
	FlagDir parent() {
		return _parent;
	}
	/// ditto
	private void parent(FlagDir parent) {
		assert (!parent || !parent.getStep(name));
		_parent = parent;
	}
	/// 最上位のディレクトリ。
	FlagDir root() {
		return _parent.root;
	}
	/// 変更ハンドラを設定する。
	void changeHandler(void delegate() change) {
		_change = change;
	}
	/// ステップ名。
	string name() {
		return _name;
	}
	/// ditto
	bool name(string name) {
		name = FlagDir.validName(name);
		if (!_parent || _parent.canAppendFS(name)) {
			if (_change && _name != name) _change();
			_name = name;
			return true;
		}
		return false;
	}

	/// ステップ値のテキストを変更する。
	void setValue(uint index, string value) {
		if (_change && _vals[index] != value) _change();
		_vals[index] = value;
	}
	/// ステップ値のテキストを返す。
	string getValue(uint index) {
		return _vals[index];
	}

	/// ステップの段階数を返す。
	uint count() {
		return _vals.length;
	}

	/// ステップの選択状態を返す。
	uint select() {
		return _select;
	}
	/// ditto
	void select(uint select) {
		if (_change && _select != select) _change();
		_select = select;
	}

	/// 選択中の値のテキストを返す。
	string value() {
		return _vals[_select];
	}
	/// ステップ値群を返す。
	string[] values() {
		return _vals;
	}
	/// ステップ値群と選択状態を設定する。
	void setValues(string[] vals, int select) {
		assert (select < vals.length);
		if (_change && (_vals != vals || _select != select)) _change();
		_vals = vals;
		_select = select;
	}

	override int opCmp(Object o) {
		return icmp(name, (cast(Step) o).name);
	}

	/// ステップのフルパス。
	string path() {
		return _parent.path ~ _name;
	}

	/// このステップをXMLテキストにする。
	string toXml() {
		auto doc = XNode.create(XML_ROOT_FLAG_DIRECTORY);
		toNode(doc);
		return doc.text;
	}
	/// XMLノードからステップを生成する。
	static Step createFromNode(ref XNode se, string ver) {
		string[] vals;
		string name = null;
		int def = se.attr!(int)("default", true);
		se.onTag["Name"] = (ref XNode n) {name = FlagDir.basename(n.value);};
		se.onTag[null] = (ref XNode n) {
			if (startsWith(n.name, "Value")) {
				auto numStr = n.name[5 .. $];
				if (isNumeric(numStr)) {
					int num = to!(int)(numStr);
					if (num < 0) return;
					if (vals.length <= num) vals.length = num + 1;
					vals[num] = n.value;
				}
			}
		};
		se.parse;
		if (!name) throw new FlagException("Step name not found.");
		if (def < 0 || vals.length <= def) {
			throw new FlagException("Step default value invalid. Count: " ~ to!(string)(vals.length) ~ ", default: " ~ to!(string)(def));
		}
		return new Step(name, vals, def);
	}
	/// 指定されたXMLノードにこのステップのデータを追加する。
	void toNode(ref XNode node) {
		auto e = node.newElement("Step");
		e.newAttr("default", _select);
		e.newElement("Name", path);
		for (int i = 0; i < _vals.length; i++) {
			e.newElement("Value" ~ to!(string)(i), _vals[i]);
		}
	}
	override string cwxPath() {
		return cpjoin(_parent, "step", indexOf!("a is b")(_parent.steps, this));
	}
}

/// フラグ/ステップ、及びサブディレクトリを格納するディレクトリ。
public class FlagDir : CWXPath {
private:
	string _name = "";
	CWXPath _owner = null;
	FlagDir _parent = null;
	FlagDir[] _subdir;
	Flag[] _flags;
	Step[] _steps;
	string _id;
	void delegate() _change = null;
public:
	/// パス区切り文字。
	static const string SEPARATOR = "\\";
	/// ditto
	static const string SEPARATOR_REGEX = "\\\\";
	/// ルートディレクトリを生成する。
	package this(CWXPath owner) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(getUTCtime);
		_owner = owner;
	}
	/// サブディレクトリを生成する。
	/// Params:
	/// name = ディレクトリ名。
	this(string name) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(getUTCtime);
		_name = validName(name);
	}
	override string cwxPath() {
		if (_owner) {
			return cpjoin(_owner, "variable");
		} else if (_parent) {
			return cpjoin(_parent, "dir", indexOf!("a is b")(_parent.subDirs, this));
		}
		return "";
	}
	/// 親ディレクトリ。
	FlagDir parent() {
		return _parent;
	}
	/// ditto
	private void parent(FlagDir parent) {
		assert (!parent || !parent.getSubDir(name));
		_parent = parent;
	}
	/// 変更ハンドラを登録する。
	void changeHandler(void delegate() change) {
		foreach (f; _flags) {
			f.changeHandler = change;
		}
		foreach (s; _steps) {
			s.changeHandler = change;
		}
		foreach (s; _subdir) {
			s.changeHandler = change;
		}
		_change = change;
	}

	/// 最上位のディレクトリ。
	FlagDir root() {
		auto dir = this;
		while (dir.parent !is null) {
			dir = dir.parent;
		}
		return dir;
	}

	/// マシン上で一意なID。ドラッグ&ドロップ等で使用する。
	string id() {
		return _id;
	}

	/// ディレクトリ名。
	string name() {
		return _name;
	}
	/// ditto
	bool name(string name) {
		name = FlagDir.validName(name);
		if (!_parent || _parent.canAppendSub(name)) {
			if (_change && _name != name) _change();
			_name = name;
			return true;
		}
		return false;
	}

	private bool canAppendFlag(Flag f) {
		return canAppendFS(f.name);
	}
	private bool canAppendStep(Step s) {
		return canAppendFS(s.name);
	}
	private bool canAppendFS(string name) {
		name = validName(name);
		if (name.length == 0) {
			return false;
		}
		foreach (flag; _flags) {
			if (icmp(flag.name, name) == 0) {
				return false;
			}
		}
		foreach (step; _steps) {
			if (icmp(step.name, name) == 0) {
				return false;
			}
		}
		return true;
	}
	/// 指定された名前のフラグ・ステップ・サブディレクトリが
	/// 追加可能であればtrueを返す。
	bool canAppendSub(string name) {
		name = validName(name);
		if (name.length == 0) {
			return false;
		}
		foreach (dir; _subdir) {
			if (icmp(dir.name, name) == 0) {
				return false;
			}
		}
		return true;
	}
	/// 指定されたディレクトリが追加可能であればtrueを返す。
	/// 自分と自分より上位にあるディレクトリを自分の下に持ってくることはできない。
	bool canAppendSub2(FlagDir ndir) {
		if (this == ndir.parent) {
			return true;
		}
		auto p = this;
		do {
			if (p == ndir) {
				// 自分と自分より上位にあるディレクトリを自分の下に持ってくることはできない
				return false;
			}
			p = p.parent;
		} while (p !is null);
		return canAppendSub(ndir.name);
	}

	private bool __add(F)(ref F[] arr, F item, bool delegate(F) canAppend) {
		if (canAppend(item) || item.parent is this) {
			if (item.parent is this && arr[$ - 1] is item) return true;
			if (item.parent !is null) {
				item.parent.remove(item);
			}
			item.parent = this;
			arr ~= item;
			item.changeHandler = _change;
			if (_change) _change();
			return true;
		}
		return false;
	}
	/// フラグ・ステップ・サブディレクトリを追加する。
	bool add(Flag flag) {
		return __add(_flags, flag, &canAppendFlag);
	}
	/// ditto
	bool add(Step step) {
		return __add(_steps, step, &canAppendStep);
	}
	/// ditto
	bool add(FlagDir sub) {
		return __add(_subdir, sub, &canAppendSub2);
	}
	private void __remove(T)(ref T[] arr, T e) {
		for (int i = 0; i < arr.length; i++) {
			if (icmp(e.name, arr[i].name) == 0) {
				e.parent = null;
				arr[i].changeHandler = null;
				arr = arr[0 .. i] ~ arr[i + 1 .. $];
				if (_change) _change();
				return;
			}
		}
	}
	/// フラグ・ステップ・サブディレクトリを除去する。
	void remove(Flag flag) {
		__remove(_flags, flag);
	}
	/// ditto
	void remove(Step step) {
		__remove(_steps, step);
	}
	/// ditto
	void remove(FlagDir dir) {
		__remove(_subdir, dir);
	}

	/// サブディレクトリ群。
	FlagDir[] subDirs() {
		return _subdir;
	}
	/// フラグ群。
	Flag[] flags() {
		return _flags;
	}
	/// ステップ群。
	Step[] steps() {
		return _steps;
	}
	/// 指定された名前のフラグ・ステップ・サブディレクトリが存在すればtrue。
	bool containsFlag(string name) {
		return getFlag(name) !is null;
	}
	/// ditto
	bool containsStep(string name) {
		return getStep(name) !is null;
	}
	/// ditto
	bool containsSubDir(string name) {
		return getStep(name) !is null;
	}

	private F __get(F)(F[] arr, string name) {
		foreach (f; arr) {
			if (icmp(f.name, name) == 0) {
				return f;
			}
		}
		return null;
	}
	/// フラグ・ステップ・サブディレクトリを名前で検索して取得する。
	/// 存在しない場合はnullを返す。
	Flag getFlag(string name) {
		return __get(_flags, name);
	}
	/// ditto
	Step getStep(string name) {
		return __get(_steps, name);
	}
	/// ditto
	FlagDir getSubDir(string name) {
		return __get(_subdir, name);
	}

	/// このディレクトリとサブディレクトリの中にある
	/// すべてのフラグ・ステップを返す。
	Flag[] allFlags() {
		Flag[] r;
		foreach (flg; _flags) {
			r ~= flg;
		}
		foreach (dir; _subdir) {
			r ~= dir.allFlags;
		}
		return r;
	}
	/// ditto
	Step[] allSteps() {
		Step[] r;
		foreach (step; _steps) {
			r ~= step;
		}
		foreach (dir; _subdir) {
			r ~= dir.allSteps;
		}
		return r;
	}

	/// フラグ・ステップを名前順にソートする。
	void sortFlags(bool sub = false) {
		if (!isSorted(_flags)) {
			if (_change) _change();
			_flags = _flags.sort;
		}
		if (sub) {
			foreach (d; _subdir) {
				d.sortFlags(true);
			}
		}
	}
	/// ditto
	void sortSteps(bool sub = false) {
		if (!isSorted(_steps)) {
			if (_change) _change();
			_steps = _steps.sort;
		}
		if (sub) {
			foreach (d; _subdir) {
				d.sortSteps(true);
			}
		}
	}

	/// このディレクトリのフルパスを返す。
	string path() {
		if (_parent !is null) {
			return _parent.path ~ _name ~ SEPARATOR;
		} else {
			return "";
		}
	}
	/// 指定されたノードにこのディレクトリ内のフラグとステップのデータを追加する。
	void toNode(ref XNode e) {
		auto fe = e.newElement("Flags");
		toNodeFlags(fe);
		auto se = e.newElement("Steps");
		toNodeSteps(se);
	}
	private void toNodeFlags(ref XNode e) {
		foreach (flag; flags) {
			flag.toNode(e);
			foreach (dir; _subdir) {
				dir.toNodeFlags(e);
			}
		}
	}
	private void toNodeSteps(ref XNode e) {
		foreach (step; steps) {
			step.toNode(e);
			foreach (dir; _subdir) {
				dir.toNodeSteps(e);
			}
		}
	}

	/// フラグパスからフラグ名・ステップ名・サブディレクトリ名だけを
	/// 抜き出して返す。
	static string basename(string path) {
		int sepLen = SEPARATOR.length;
		if (path.length < sepLen) {
			return path;
		}
		if (endsWith(path, SEPARATOR)) {
			path = path[0 .. $ - sepLen];
		}
		for (int i = path.length - sepLen; i >= 0; i--) {
			if (path[i .. i + sepLen] == SEPARATOR) {
				return path[i + sepLen .. $];
			}
		}
		return path;
	} unittest {
		assert (FlagDir.basename("\\test\\") == "test");
		assert (FlagDir.basename("\\aaa\\test") == "test");
		assert (FlagDir.basename("test") == "test");
		assert (FlagDir.basename("\\") == "");
		assert (FlagDir.basename("") == "");
	}

	/// 自分以下のディレクトリツリーに
	/// 指定されたパスのディレクトリが含まれていればtrueを返す。
	/// 同一のディレクトリツリーかどうかは考慮されない。
	bool has(string path) {
		path = toLower(path);
		auto tpath = toLower(this.path);
		int len = path.length;
		int tlen = tpath.length;
		int sepLen = SEPARATOR.length;
		return (len <= tlen) && (tpath[0 .. len] == path);
	} unittest {
		auto dir1 = new FlagDir(cast(CWXPath) null);
		auto dir2 = new FlagDir("aaaaA");
		dir1.add(dir2);
		auto dir3 = new FlagDir("fsadfawegGGGg");
		dir2.add(dir3);

		auto dir4 = new FlagDir(cast(CWXPath) null);
		auto dir5 = new FlagDir("aAAAA");
		dir4.add(dir5);
		auto dir6 = new FlagDir("fsadFAwegGGGga");
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
	static string up(string path) {
		int sepLen = SEPARATOR.length;
		if (path.length < sepLen) {
			return null;
		}
		if (path[$ - sepLen .. $] == SEPARATOR) {
			path = path[0 .. $ - sepLen];
		}
		for (int i = path.length - sepLen; i >= 0; i--) {
			if (path[i .. i + sepLen] == SEPARATOR) {
				return path[0 .. i + sepLen];
			}
		}
		return "";
	} unittest {
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

	private static bool __loadFS(string Fs, string Fg, F)
			(ref XNode node, FlagDir p, out F[string] c, string delegate(string) createNewName, bool copy, string ver) {
		bool ret = true;
		node.onTag[Fs] = (ref XNode node) {
			if (!ret) return;
			node.onTag[Fg] = (ref XNode n) {
				if (!ret) return;
				auto f = F.createFromNode(n, ver);
				if (!p.canAppendFS(f.name)) {
					if (copy) {
						f.name = createNewName(f.name);
					} else {
						ret = false;
						return;
					}
				}
				c[n.childText("Name", true)] = f;
			};
			node.parse;
		};
		node.parse;
		return ret;
	}
	private bool loadFlagAndSteps
			(ref XNode node, out Flag[string] cFlags, out Step[string] cSteps, bool copy, string ver) {
		try {
			if (!__loadFS!("Flags", "Flag", Flag)(node, this, cFlags, &createNewFlagName, copy, ver)) {
				removeAll(cFlags);
				removeAll(cSteps);
				return false;
			}
			if (!__loadFS!("Steps", "Step", Step)(node, this, cSteps, &createNewStepName, copy, ver)) {
				removeAll(cFlags);
				removeAll(cSteps);
				return false;
			}
			foreach (v; cFlags.values) {
				this.add(v);
			}
			foreach (v; cSteps.values) {
				this.add(v);
			}
			return true;
		} catch (Exception e) {
			removeAll(cFlags);
			removeAll(cSteps);
			return false;
		}
	}
	private FlagDir loadSubs
			(ref XNode node, out Flag[string] cFlags, out Step[string] cSteps, bool copy, string ver) {
		try {
			auto subName = basename(node.attr("path", true));
			if (subName.length == 0) {
				subName = validName(node.attr("rootName", true));
			}
			if (!canAppendSub(subName)) {
				if (copy) {
					subName = createNewDirName(subName);
				} else {
					return null;
				}
			}
			auto sub = new FlagDir(subName);
			if (!sub.loadFlagAndSteps(node, cFlags, cSteps, false, ver)) {
				assert (cFlags.length == 0);
				assert (cSteps.length == 0);
				return null;
			}
			bool ret = true;
			node.onTag["FlagDirectory"] = (ref XNode n) {
				if (!ret) return;
				if (!sub.loadSubs(n, cFlags, cSteps, false, ver)) {
					ret = false;
					return;
				}
			};
			node.parse;
			if (ret) {
				this.add(sub);
				return sub;
			}
		} catch (Exception e) {
		}
		removeAll(cFlags);
		removeAll(cSteps);
		return null;
	}
	private bool readAtt(in XNode node,
			out string rootId = null, out string path = null,
			out bool sameTree = false) {
		rootId = node.attr(XML_ATT_ROOT_ID, false);
		path = node.attr(XML_ATT_PATH, false);
		if (rootId !is null && path !is null) {
			sameTree = this.root.id == rootId;
			return true;
		} else {
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
	/// Returns: XMLからの追加を試みた結果。
	/// See_Also: getXml(FlagDir, Flag[], Step[]), getXml(FlagDir)
	AppendXmlResult appendFromXML(string xml, string ver, bool copy, bool dirMode,
			out Flag[string] cFlags, out Step[string] cSteps, out string newPath = null) {
		try {
			scope doc = XNode.parse(xml);

			if (doc.name == XML_ROOT_FLAGS_AND_STEPS) {
				string rootId;
				string path;
				bool sameTree;
				if (readAtt(doc, rootId, path, sameTree)) {
					if (!copy && sameTree && icmp(this.path, path) == 0) {
						// 転送されてきたのが自分自身の場合は末尾に移し変えて終了
						doc.onTag["Flags"] = (ref XNode node) {
							doc.onTag["Flag"] = (ref XNode node) {
								add(getFlag(node.childText("Name", true)));
							};
							node.parse;
						};
						doc.onTag["Steps"] = (ref XNode node) {
							doc.onTag["Step"] = (ref XNode node) {
								add(getStep(node.childText("Name", true)));
							};
							node.parse;
						};
						doc.parse;
						return AppendXmlResult.FLAG_STEP_ON_DIR;
					}
					if (loadFlagAndSteps(doc, cFlags, cSteps, copy, ver)) {
						return AppendXmlResult.FLAG_STEP_SUCCESS;
					}
				}
				return AppendXmlResult.FAIL;
			}
			if (dirMode && doc.name == XML_ROOT_FLAG_DIRECTORY) {
				return loadRootFlagDirectory(doc, ver, copy, cFlags, cSteps, newPath);
			}
		} catch (Exception e) {
		}
		return AppendXmlResult.FAIL;
	}
	private AppendXmlResult loadRootFlagDirectory(ref XNode node, string ver, bool copy,
			out Flag[string] cFlags, out Step[string] cSteps, out string newPath = null) {
		string rootId;
		string path;
		bool sameTree;
		if (readAtt(node, rootId, path, sameTree)) {
			auto dirName = basename(path);
			if (!copy) {
				if (path.length == 0) {
					// ルートディレクトリは移動不可
					return AppendXmlResult.FAIL;
				}
				if (sameTree && icmp(this.path, up(path)) == 0) {
					// 転送されてきたのが自分自身の場合は末尾に移し変えて終了
					auto d = getSubDir(dirName);
					add(d);
					newPath = d.path;
					return AppendXmlResult.ON_DIR;
				}
				if (sameTree && has(path)) {
					// 同一ツリー内で送り手と受け手が矛盾する
					return AppendXmlResult.FAIL;
				}
				if (!canAppendSub(dirName)) {
					// 同一名のサブディレクトリがすでに存在する
					return AppendXmlResult.FAIL;
				}
			}
			auto sub = loadSubs(node, cFlags, cSteps, copy, ver);
			if (sub) {
				newPath = sub.path;
			}  else {
				return AppendXmlResult.FAIL;
			}
			return AppendXmlResult.DIR_SUCCESS;
		}
		return AppendXmlResult.FAIL;
	}

	/// 指定されたディレクトリ以下のサブディレクトリに
	/// pathと一致するものがあれば返す。
	static FlagDir searchPath(FlagDir root, string path) {
		assert (root.parent is null);
		int sepLen = SEPARATOR.length;
		if (endsWith(path, FlagDir.SEPARATOR)) {
			path = path[0 .. $ - sepLen];
		}
		auto paths = (new RegExp(SEPARATOR_REGEX)).split(path);
		auto dir = root;

		loop: for (int lev = 0; lev < paths.length; lev++) {
			foreach (sub; dir.subDirs) {
				if (icmp(paths[lev], sub.name) == 0) {
					if (lev < paths.length - 1) {
						dir = sub;
						continue loop;
					} else {
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
	static string validName(string name) {
		return replace(name, SEPARATOR, "");
	}

	/// baseをこのディレクトリに追加可能な名前に加工して返す。
	/// base = xxxxの場合、xxxxというフラグがすでに存在すればxxxx (2)、
	/// さらにxxxx (2)というフラグが存在すればxxxx (3)……というように、
	/// 付記した数字をインクリメントしていく。
	string createNewFlagName(string base) {
		return createNewName(validName(base), &canAppendFS);
	}
	/// ditto
	string createNewStepName(string base) {
		return createNewName(validName(base), &canAppendFS);
	}
	/// ditto
	string createNewDirName(string base) {
		return createNewName(validName(base), &canAppendSub);
	}

	/// 指定されたパスを探して返す。
	/// Params:
	/// path = パス。
	/// create = trueの場合、見つからなかったときに生成する。
	/// Returns: 見つかったパス。見つからず、生成もしない場合はnull。
	FlagDir findPath(string path, bool create = false) {
		if (path.length == 0) {
			return root;
		} else {
			auto paths = std.string.split(path, SEPARATOR);
			if (paths.length == 0) {
				return root;
			}
			return root.__findPath(paths[0 .. $ - 1], create);
		}
	}
	private FlagDir __findPath(string[] paths, bool create) {
		auto sub = getSubDir(paths[0]);
		if (sub is null) {
			if (create) {
				if (canAppendSub(paths[0])) {
					sub = new FlagDir(paths[0]);
					this.add(sub);
				} else {
					return null;
				}
			} else {
				return null;
			}
		}
		if (paths.length == 1) {
			return sub;
		} else {
			return sub.__findPath(paths[1 .. $], create);
		}
	}
	/// 指定されたパスのフラグを探して返す。
	/// Params:
	/// path = パス。
	/// Returns: 見つかったフラグ。見つからなかった場合はnull。
	Flag findFlag(string path) {
		if (path.length > 0) {
			auto dir = findPath(up(path), false);
			if (dir !is null) {
				return dir.getFlag(basename(path));
			}
		}
		return null;
	}
	/// 指定されたパスのステップを探して返す。
	/// Params:
	/// path = パス。
	/// Returns: 見つかったステップ。見つからなかった場合はnull。
	Step findStep(string path) {
		if (path.length > 0) {
			auto dir = findPath(up(path), false);
			if (dir !is null) {
				return dir.getStep(basename(path));
			}
		}
		return null;
	}

	/// 配下にある全てのフラグとステップのデータをノードに追加する。
	void toNodeAll(ref XNode node) {
		auto fe = node.newElement("Flags");
		foreach (flag; allFlags) {
			flag.toNode(fe);
		}
		auto se = node.newElement("Steps");
		foreach (step; allSteps) {
			step.toNode(se);
		}
	}

	/// XMLノードを元に、フラグディレクトリのツリーを生成して返す。
	/// Params:
	/// node = ノード。
	/// change = 変更を通知するハンドラ。
	/// Returns: ディレクトリツリー。
	static FlagDir fromXmlNode(ref XNode node, void delegate() change, string ver) {
		auto root = new FlagDir("");
		node.onTag["Flags"] = (ref XNode node) {
			__fromXmlNode!(Flag)(node, root, "Flag", &Flag.createFromNode, ver);
		};
		node.onTag["Steps"] = (ref XNode node) {
			__fromXmlNode!(Step)(node, root, "Step", &Step.createFromNode, ver);
		};
		node.parse;
		root.changeHandler = change;
		return root;
	}
	private static void __fromXmlNode(E)(ref XNode node,
			FlagDir root, string es, E function(ref XNode, string) pfunc, string ver) {
		node.onTag[es] = (ref XNode e) {
			string path = e.childText("Name", false);
			if (path) {
				auto parent = up(path);
				auto dir = parent !is null ? root.findPath(parent, true) : root;
				auto f = pfunc(e, ver);
				if (!f || !dir.canAppendFS(f.name)) {
					throw new FlagException(es ~ " parse error: " ~ path);
				}
				dir.add(f);
			} else {
				throw new FlagException(es ~ " name not found.");
			}
		};
		node.parse;
		root.sortFlags(true);
		root.sortSteps(true);
	}
}


module cwx.usecounter;

import cwx.path;
import cwx.textholder;
import cwx.utils;

import std.array;
import std.ascii;
import std.conv;
import std.path;
import std.string;

/// 各型の使用回数カウント対象リソースをID型に変換する。
template ToID(ID) {
	static if (is(ID:FlagId)) {
		alias toFlagId ToID;
	} else static if (is(ID:StepId)) {
		alias toStepId ToID;
	} else static if (is(ID:VariantId)) {
		alias toVariantId ToID;
	} else static if (is(ID:CouponId)) {
		alias toCouponId ToID;
	} else static if (is(ID:GossipId)) {
		alias toGossipId ToID;
	} else static if (is(ID:CompleteStampId)) {
		alias toCompleteStampId ToID;
	} else static if (is(ID:KeyCodeId)) {
		alias toKeyCodeId ToID;
	} else static if (is(ID:CellNameId)) {
		alias toCellNameId ToID;
	} else static if (is(ID:CardGroupId)) {
		alias toCardGroupId ToID;
	} else static assert (0);
}

/// Kの使用者。
interface User(K) : CWXPath {
	bool change(K newVal);
}

/// Kの使用者Uを登録し、変更通知等を受け取れるようにする。
class UCCont(K, U) {
private:
	HashSet!(U)[K] _cont;
public:
	/// 唯一のコンストラクタ
	@property
	this () { mixin(S_TRACE);
		// Nothing
	}

	/// キーの使用回数を返す。
	/// Params:
	/// key = キー。
	/// Returns: 使用回数。
	const
	uint get(K key) { mixin(S_TRACE);
		auto p = key in _cont;
		return p ? cast(uint)p.size : 0;
	}

	/// キーの一覧を返す。
	/// Returns: キーの一覧。
	@property
	const
	K[] keys() { mixin(S_TRACE);
		return _cont.keys;
	}

	/// キーの使用者の一覧を返す。
	/// Params:
	/// key = キー。
	/// Returns: 使用者の一覧。
	@property
	const
	U[] values(K key) { mixin(S_TRACE);
		auto p = key in _cont;
		return p ? p.toArray() : cast(U[])[];
	}
	/// ditto
	inout
	inout(HashSet!U) valueSet(K key) { mixin(S_TRACE);
		auto p = key in _cont;
		return p ? *p : cast(typeof(return))new HashSet!U;
	}

	/// キーの使用者を追加する。
	/// Params:
	/// key = キー。
	/// user = 使用者。
	void add(K key, U user) { mixin(S_TRACE);
		HashSet!(U) set;
		if (key in _cont) { mixin(S_TRACE);
			set = _cont[key];
		} else { mixin(S_TRACE);
			set = new HashSet!(U);
			_cont[key] = set;
		}
		set.add(user);
	}
	/// キーの使用者を除外する。
	/// Params:
	/// key = キー。
	/// user = 使用者。
	void remove(K key, U user) { mixin(S_TRACE);
		auto set = _cont[key];
		set.remove(user);
		if (set.isEmpty) { mixin(S_TRACE);
			_cont.remove(key);
			destroy(set);
		}
	}
	/// キーに変更があったときに呼出す。
	/// Params:
	/// oldKey = 変更前のキー。
	/// newKey = 変更後のキー。
	/// dup = 変更後の重複を許可するか。
	void change(K oldKey, K newKey, bool dup = false) { mixin(S_TRACE);
		if (oldKey != newKey && (oldKey in _cont)) { mixin(S_TRACE);
			if (newKey in _cont) { mixin(S_TRACE);
				if (!dup) debugln(oldKey, " to ", newKey, " : ", _cont[newKey].size);
			}
			HashSet!U newCont;
			auto oldCont = new HashSet!U;
			if (newKey in _cont) { mixin(S_TRACE);
				newCont = _cont[newKey];
			} else { mixin(S_TRACE);
				newCont = new HashSet!U;
			}
			foreach (val; _cont[oldKey]) { mixin(S_TRACE);
				if (val.change(newKey)) { mixin(S_TRACE);
					newCont.add(val);
				} else { mixin(S_TRACE);
					oldCont.add(val);
				}
			}
			if (newCont.isEmpty) { mixin(S_TRACE);
				if (newKey in _cont) _cont.remove(newKey);
			} else { mixin(S_TRACE);
				_cont[newKey] = newCont;
			}
			if (oldCont.isEmpty) { mixin(S_TRACE);
				if (oldKey in _cont) _cont.remove(oldKey);
			} else { mixin(S_TRACE);
				_cont[oldKey] = oldCont;
			}
		}
	}
}

/// *Userのコンストラクタで指定したCWXPathが同時に
/// Chg*Callbackを実装する場合、change()が呼び出された
/// 際にコールバックを受ける事ができる。
interface TChgCallback(T) {
	/// 参照の変更時に呼び出される。
	bool changeCallback(T, T);

	/// 名称・称号の検索範囲を限定するための情報。
	@property
	inout
	inout(CWXPath) ucOwner();

	/// 使用回数カウンタを設定する。
	void setUseCounter(UseCounter uc, CWXPath ucOwner);
	/// 使用回数カウンタを除去する。
	void removeUseCounter();
}
/// ditto
alias TChgCallback!(AreaId) ChgAreaCallback;
/// ditto
alias TChgCallback!(BattleId) ChgBattleCallback;
/// ditto
alias TChgCallback!(FlagId) ChgFlagCallback;
/// ditto
alias TChgCallback!(StepId) ChgStepCallback;
/// ditto
alias TChgCallback!(VariantId) ChgVariantCallback;
/// ditto
alias TChgCallback!(PathId) ChgPathCallback;
/// ditto
alias TChgCallback!(CouponId) ChgCouponCallback;
/// ditto
alias TChgCallback!(GossipId) ChgGossipCallback;

/// テキストをそのままキーとする場合のメソッド群を実装する。
private mixin template StringId() {
	const
	@safe
	nothrow
	string opCast() {
		return id;
	}
	const
	@safe
	nothrow
	hash_t toHash() {
		hash_t hash = 0;
		foreach (c; id) {
			hash = (hash * 9) + c;
		}
		return hash;
	}
	const
	bool opEquals(ref const(typeof(this)) s) { mixin(S_TRACE);
		return id == s.id;
	}
	const
	int opCmp(ref const(typeof(this)) s) { mixin(S_TRACE);
		return cmp(this.id, s.id);
	}
	const
	string toString() { mixin(S_TRACE);
		return id;
	}
}

private mixin template CWXFuncs() {
	@property
	override
	string cwxPath(bool id) { return _cwxPath ? _cwxPath.cwxPath(id) : ""; }
	override
	CWXPath findCWXPath(string path) { return _cwxPath ? _cwxPath.findCWXPath(path) : null; }
	@property
	override
	inout
	inout(CWXPath)[] cwxChilds() { return _cwxPath ? _cwxPath.cwxChilds : []; }
	@property
	override
	CWXPath cwxParent() { return _cwxPath ? _cwxPath.cwxParent : null; }

	override
	void changed() { mixin(S_TRACE);
		if (_cwxPath) _cwxPath.changed();
	}
}

/// フラグのID。
struct FlagId {
	private string id;
	static FlagId opCall(string id) {
		FlagId r;
		r.id = id;
		return r;
	}
	const
	@safe
	nothrow
	string opCast() {
		return id;
	}
	const
	@safe
	nothrow
	hash_t toHash() {
		hash_t hash = 0;
		foreach (c; id) {
			hash = (hash * 9) + c;
		}
		return hash;
	}
	const
	bool opEquals(ref const(FlagId) s) { mixin(S_TRACE);
		return cmp(id, s.id) == 0;
	}
	const
	int opCmp(ref const(FlagId) s) { mixin(S_TRACE);
		return cmp(this.id, s.id);
	}
	const
	string toString() { mixin(S_TRACE);
		return id;
	}
}
/// 文字列をフラグIDに変換。
FlagId toFlagId(string id) { return FlagId(id); }
/// フラグを使用するクラスの雛形。
/// 継承か委譲により、フラグの使用者を容易に実装できる。
class FlagUser : User!FlagId {
private:
	UseCounter _uc;
	string _flag;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	/// 所有者がChgFlagCallbackであればコールバックが行われる。
	@property
	void id(FlagId newVal) { mixin(S_TRACE);
		if (cast(ChgFlagCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgFlagCallback)_cwxPath).changeCallback(toFlagId(_flag), newVal)) { mixin(S_TRACE);
				return;
			}
		}
		flag = newVal.id;
	}

	/// フラグを設定する。
	/// Params:
	/// flag = フラグ。
	@property
	void flag(string flag) { mixin(S_TRACE);
		if (_flag != flag) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_flag !is null) _uc.remove(toFlagId(_flag), this);
			if (flag !is null) _uc.add(toFlagId(flag), this);
		}
		_flag = flag;
	}

	/// Returns: フラグ。
	@property
	const
	string flag() { mixin(S_TRACE);
		return _flag;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _flag) { mixin(S_TRACE);
			_uc.remove(toFlagId(_flag), this);
		}
		if (uc && _flag) { mixin(S_TRACE);
			uc.add(toFlagId(_flag), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _flag !is null) { mixin(S_TRACE);
			_uc.remove(toFlagId(_flag), this);
		}
		_uc = null;
	}
	override bool change(FlagId newVal) { mixin(S_TRACE);
		if (_flag != cast(string)newVal) changed();
		if (cast(ChgFlagCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgFlagCallback)_cwxPath).changeCallback(toFlagId(_flag), newVal)) { mixin(S_TRACE);
				return false;
			}
		}
		_flag = cast(string)newVal;
		return true;
	}

	mixin CWXFuncs;
}

/// ステップのID。
struct StepId {
	private string id;
	static StepId opCall(string id) {
		StepId r;
		r.id = id;
		return r;
	}
	const
	@safe
	nothrow
	string opCast() {
		return id;
	}
	const
	@safe
	nothrow
	hash_t toHash() {
		hash_t hash = 0;
		foreach (c; id) {
			hash = (hash * 9) + c;
		}
		return hash;
	}
	const
	bool opEquals(ref const(StepId) s) { mixin(S_TRACE);
		return cmp(id, s.id) == 0;
	}
	const
	int opCmp(ref const(StepId) s) { mixin(S_TRACE);
		return cmp(this.id, s.id);
	}
	const
	string toString() { mixin(S_TRACE);
		return id;
	}
}
/// 文字列をステップIDに変換。
StepId toStepId(string id) { return StepId(id); }
/// ステップを使用するクラスの雛形。
/// 継承か委譲により、ステップの使用者を容易に実装できる。
class StepUser : User!StepId {
private:
	UseCounter _uc;
	string _step;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	/// 所有者がChgStepCallbackであればコールバックが行われる。
	@property
	void id(StepId newVal) { mixin(S_TRACE);
		if (cast(ChgStepCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgStepCallback)_cwxPath).changeCallback(toStepId(_step), newVal)) { mixin(S_TRACE);
				return;
			}
		}
		step = newVal.id;
	}

	/// ステップを設定する。
	/// Params:
	/// step = ステップ。
	@property
	void step(string step) { mixin(S_TRACE);
		if (_step != step) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_step !is null) _uc.remove(toStepId(_step), this);
			if (step !is null) _uc.add(toStepId(step), this);
		}
		_step = step;
	}

	/// Returns: ステップ。
	@property
	const
	string step() { mixin(S_TRACE);
		return _step;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _step) { mixin(S_TRACE);
			_uc.remove(toStepId(_step), this);
		}
		if (uc && _step) { mixin(S_TRACE);
			uc.add(toStepId(_step), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _step !is null) { mixin(S_TRACE);
			_uc.remove(toStepId(_step), this);
		}
		_uc = null;
	}
	override bool change(StepId newVal) { mixin(S_TRACE);
		if (_step != cast(string)newVal) changed();
		if (cast(ChgStepCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgStepCallback)_cwxPath).changeCallback(toStepId(_step), newVal)) { mixin(S_TRACE);
				return false;
			}
		}
		_step = cast(string) newVal;
		return true;
	}

	mixin CWXFuncs;
}

/// コモンのID。
struct VariantId {
	private string id;
	static VariantId opCall(string id) {
		VariantId r;
		r.id = id;
		return r;
	}
	const
	@safe
	nothrow
	string opCast() {
		return id;
	}
	const
	@safe
	nothrow
	hash_t toHash() {
		hash_t hash = 0;
		foreach (c; id) {
			hash = (hash * 9) + c;
		}
		return hash;
	}
	const
	bool opEquals(ref const(VariantId) s) { mixin(S_TRACE);
		return cmp(id, s.id) == 0;
	}
	const
	int opCmp(ref const(VariantId) s) { mixin(S_TRACE);
		return cmp(this.id, s.id);
	}
	const
	string toString() { mixin(S_TRACE);
		return id;
	}
}
/// 文字列をコモンIDに変換。
VariantId toVariantId(string id) { return VariantId(id); }
/// コモンを使用するクラスの雛形。
/// 継承か委譲により、コモンの使用者を容易に実装できる。
class VariantUser : User!VariantId {
private:
	UseCounter _uc;
	string _variant;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	/// 所有者がChgVariantCallbackであればコールバックが行われる。
	@property
	void id(VariantId newVal) { mixin(S_TRACE);
		if (cast(ChgVariantCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgVariantCallback)_cwxPath).changeCallback(toVariantId(_variant), newVal)) { mixin(S_TRACE);
				return;
			}
		}
		variant = newVal.id;
	}

	/// コモンを設定する。
	/// Params:
	/// variant = コモン。
	@property
	void variant(string variant) { mixin(S_TRACE);
		if (_variant != variant) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_variant !is null) _uc.remove(toVariantId(_variant), this);
			if (variant !is null) _uc.add(toVariantId(variant), this);
		}
		_variant = variant;
	}

	/// Returns: コモン。
	@property
	const
	string variant() { mixin(S_TRACE);
		return _variant;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _variant) { mixin(S_TRACE);
			_uc.remove(toVariantId(_variant), this);
		}
		if (uc && _variant) { mixin(S_TRACE);
			uc.add(toVariantId(_variant), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _variant !is null) { mixin(S_TRACE);
			_uc.remove(toVariantId(_variant), this);
		}
		_uc = null;
	}
	override bool change(VariantId newVal) { mixin(S_TRACE);
		if (_variant != cast(string)newVal) changed();
		if (cast(ChgVariantCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgVariantCallback)_cwxPath).changeCallback(toVariantId(_variant), newVal)) { mixin(S_TRACE);
				return false;
			}
		}
		_variant = cast(string) newVal;
		return true;
	}

	mixin CWXFuncs;
}

/// エリアのID。
struct AreaId {
	ulong id;
	alias id this;
}
/// 数値をエリアIDに変換。
AreaId toAreaId(ulong id) { return cast(AreaId) id; }
/// エリアを使用するクラスの雛形。
/// 継承か委譲により、エリアの使用者を容易に実装できる。
class AreaUser : User!AreaId {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
	bool _callback;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath, bool callback = false) { mixin(S_TRACE);
		_cwxPath = cwxPath;
		_callback = callback;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	@property
	void id(AreaId newVal) { mixin(S_TRACE);
		area = newVal;
	}

	/// エリアIDを設定する。
	/// Params:
	/// id = エリアID。
	@property
	void area(ulong id) { mixin(S_TRACE);
		if (_id == id) return;
		changed();
		if (_callback && cast(ChgAreaCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgAreaCallback)_cwxPath).changeCallback(toAreaId(_id), toAreaId(id))) { mixin(S_TRACE);
				return;
			}
		}
		if (_uc !is null) { mixin(S_TRACE);
			if (_id > 0) _uc.remove(toAreaId(_id), this);
			if (id > 0) _uc.add(toAreaId(id), this);
		}
		_id = id;
	}

	/// Returns: エリアID。
	@property
	const
	ulong area() { mixin(S_TRACE);
		return _id;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toAreaId(_id), this);
		}
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.add(toAreaId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toAreaId(_id), this);
		}
		_uc = null;
	}
	override bool change(AreaId newVal) { mixin(S_TRACE);
		if (_id == newVal) return true;
		changed();
		if (_callback && cast(ChgAreaCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgAreaCallback)_cwxPath).changeCallback(toAreaId(_id), newVal)) { mixin(S_TRACE);
				return false;
			}
		}
		if (_handleChange) _handleChange(newVal);
		_id = newVal;
		return true;
	}
	private void delegate(AreaId) _handleChange = null;
	/// change呼出しをdlgに通知する。
	@property
	void handleChange(void delegate(AreaId) dlg) { _handleChange = dlg; }

	mixin CWXFuncs;
}

/// バトルのID。
struct BattleId {
	ulong id;
	alias id this;
}
/// 数値をバトルIDに変換。
BattleId toBattleId(ulong id) { return cast(BattleId)id; }
/// バトルを使用するクラスの雛形。
/// 継承か委譲により、バトルの使用者を容易に実装できる。
class BattleUser : User!BattleId {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
	bool _callback;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath, bool callback = false) { mixin(S_TRACE);
		_cwxPath = cwxPath;
		_callback = callback;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	@property
	void id(BattleId newVal) { mixin(S_TRACE);
		battle = newVal;
	}

	/// バトルIDを設定する。
	/// Params:
	/// id = バトルID。
	@property
	void battle(ulong id) { mixin(S_TRACE);
		if (_id == id) return;
		changed();
		if (_callback && cast(ChgBattleCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgBattleCallback)_cwxPath).changeCallback(toBattleId(_id), toBattleId(id))) { mixin(S_TRACE);
				return;
			}
		}
		if (_uc !is null) { mixin(S_TRACE);
			if (_id > 0) _uc.remove(toBattleId(_id), this);
			if (id > 0) _uc.add(toBattleId(id), this);
		}
		_id = id;
	}

	/// Returns: バトルID。
	@property
	const
	ulong battle() { mixin(S_TRACE);
		return _id;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toBattleId(_id), this);
		}
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.add(toBattleId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toBattleId(_id), this);
		}
		_uc = null;
	}
	override bool change(BattleId newVal) { mixin(S_TRACE);
		if (_id == newVal) return true;
		changed();
		if (_callback && cast(ChgBattleCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgBattleCallback)_cwxPath).changeCallback(toBattleId(_id), newVal)) { mixin(S_TRACE);
				return false;
			}
		}
		if (_handleChange) _handleChange(newVal);
		_id = newVal;
		return true;
	}
	private void delegate(BattleId) _handleChange = null;
	/// change呼出しをdlgに通知する。
	@property
	void handleChange(void delegate(BattleId) dlg) { _handleChange = dlg; }

	mixin CWXFuncs;
}

/// パッケージのID。
struct PackageId {
	ulong id;
	alias id this;
}
/// 数値をパッケージIDに変換。
PackageId toPackageId(ulong id) { return cast(PackageId) id; }
/// パッケージを使用するクラスの雛形。
/// 継承か委譲により、パッケージの使用者を容易に実装できる。
class PackageUser : User!PackageId {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	@property
	void id(PackageId newVal) { mixin(S_TRACE);
		packages = newVal;
	}

	/// パッケージIDを設定する。
	/// Params:
	/// id = パッケージID。
	@property
	void packages(ulong id) { mixin(S_TRACE);
		if (_id != id) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_id > 0) _uc.remove(toPackageId(_id), this);
			if (id > 0) _uc.add(toPackageId(id), this);
		}
		_id = id;
	}

	/// Returns: パッケージID。
	@property
	const
	ulong packages() { mixin(S_TRACE);
		return _id;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toPackageId(_id), this);
		}
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.add(toPackageId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toPackageId(_id), this);
		}
		_uc = null;
	}

	override bool change(PackageId newVal) { mixin(S_TRACE);
		if (_id != newVal) changed();
		_id = newVal;
		return true;
	}

	mixin CWXFuncs;
}

/// ファイルパスのID。
struct PathId {
	private string id;
	private string binData = "";
	@safe
	nothrow
	static PathId opCall(string id) {
		PathId r;
		r.id = id;
		return r;
	}
	@safe
	nothrow
	static PathId opCall(string id, string binData) {
		PathId r;
		r.id = id;
		r.binData = binData;
		return r;
	}
	@property
	const
	@safe
	nothrow
	bool isBinData() {
		return binData.length > 0u;
	}
	@property
	const
	bool valid() { mixin(S_TRACE);
		return id.length || binData.length;
	}
	const
	@safe
	nothrow
	string opCast() {
		string id = this.id;
		return isBinData ? binData : replace(id, "/", dirSeparator);
	}
	const
	@trusted
	nothrow
	hash_t toHash() {
		hash_t hash = 0;
		string s;
		if (isBinData) {
			s = binData;
		} else {
			static if (0 == filenameCharCmp('A', 'a')) {
				try {
					s = .toLower(id);
				} catch (Throwable) {
					// 握り潰す
				}
			} else {
				s = id;
			}
		}
		foreach (char c; s) {
			hash = (hash * 9) + c;
		}
		return hash;
	}
	const
	bool opEquals(ref const(PathId) s) { mixin(S_TRACE);
		return (isBinData || s.isBinData) ? binData == s.binData : cfnmatch(this.id, s.id);
	}
	const
	int opCmp(ref const(PathId) s) { mixin(S_TRACE);
		if (isBinData && !s.isBinData) return -1;
		if (!isBinData && s.isBinData) return 1;
		if (isBinData || s.isBinData) { mixin(S_TRACE);
			foreach (i, char c; binData) { mixin(S_TRACE);
				if (c < s.binData[i]) return -1;
				if (c > s.binData[i]) return 1;
			}
			if (binData.length < s.binData.length) return -1;
			if (binData.length > s.binData.length) return 1;
			return 0;
		}
		static if (0 == filenameCharCmp('A', 'a')) {
			return std.string.icmp(this.id.encodePath(), s.id.encodePath());
		} else { mixin(S_TRACE);
			return std.string.cmp(this.id.encodePath(), s.id.encodePath());
		}
	}
	const
	string toString() { mixin(S_TRACE);
		string buf = "PathId {";
		if (isBinData) { mixin(S_TRACE);
			buf ~= "BinaryData, hash: " ~ to!(string)(toHash());
		} else { mixin(S_TRACE);
			buf ~= id;
		}
		buf ~= "}";
		return buf;
	}
}
/// 文字列をファイルパスIDに変換。
@safe
nothrow
PathId toPathId(string id) {
	if (isBinImg(id)) {
		return PathId(BI_PATH_ID, id);
	} else if (isBinSnd(id)) {
		return PathId(BS_PATH_ID, id);
	} else {
		id = replace(id, dirSeparator, "/");
		static if (altDirSeparator.length) {
			id = replace(id, altDirSeparator, "/");
		}
		return PathId(id);
	}
}
const BI_PATH_ID = "binaryimage://Binary:Image";
const BS_PATH_ID = "binarysound://Binary:Sound";
/// ファイルパスを使用するクラスの雛形。
/// 継承か委譲により、ファイルパスの使用者を容易に実装できる。
class PathUser : User!PathId {
private:
	UseCounter _uc;
	PathId _path;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	/// 所有者がChgPathCallbackであればコールバックが行われる。
	@property
	bool id(PathId newVal) { mixin(S_TRACE);
		if (cast(ChgPathCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgPathCallback)_cwxPath).changeCallback(_path, newVal)) { mixin(S_TRACE);
				return false;
			}
		}
		path = cast(string)newVal;
		return true;
	}

	/// ファイルパスを設定する。
	@property
	void path(string path) { mixin(S_TRACE);
		auto id = toPathId(path);
		if (_path != id) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_path.valid) { mixin(S_TRACE);
				_uc.remove(_path, this);
			}
			if (path.length) { mixin(S_TRACE);
				_uc.add(id, this);
			}
		}
		_path = id;
	}

	/// ファイルパス。
	@property
	const
	nothrow
	@safe
	string path() { return _path.isBinData ? _path.binData : cast(string)_path; }

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _path.valid) { mixin(S_TRACE);
			_uc.remove(_path, this);
		}
		if (uc && _path.valid) { mixin(S_TRACE);
			uc.add(_path, this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _path.valid) { mixin(S_TRACE);
			_uc.remove(_path, this);
		}
		_uc = null;
	}

	override bool change(PathId newVal) { mixin(S_TRACE);
		if (_path != newVal) changed();
		if (cast(ChgPathCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgPathCallback)_cwxPath).changeCallback(_path, newVal)) { mixin(S_TRACE);
				return false;
			}
		}
		_path = newVal;
		return true;
	}

	mixin CWXFuncs;
}

/// キャストカードのID。
struct CastId {
	ulong id;
	alias id this;
}
/// 数値をキャストIDに変換。
CastId toCastId(ulong id) { return cast(CastId) id; }
/// キャストを使用するクラスの雛形。
/// 継承か委譲により、キャストの使用者を容易に実装できる。
class CastUser : User!CastId {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	@property
	void id(CastId newVal) { mixin(S_TRACE);
		casts = newVal;
	}

	/// キャストIDを設定する。
	/// Params:
	/// id = キャストID。
	@property
	void casts(ulong id) { mixin(S_TRACE);
		if (_id != id) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_id > 0) _uc.remove(toCastId(_id), this);
			if (id > 0) _uc.add(toCastId(id), this);
		}
		_id = id;
	}

	/// Returns: キャストID。
	@property
	const
	ulong casts() { mixin(S_TRACE);
		return _id;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toCastId(_id), this);
		}
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.add(toCastId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toCastId(_id), this);
		}
		_uc = null;
	}

	override bool change(CastId newVal) { mixin(S_TRACE);
		if (_id != newVal) changed();
		_id = newVal;
		return true;
	}

	mixin CWXFuncs;
}
/// スキルカードのID。
struct SkillId {
	ulong id;
	alias id this;
}
/// 数値をスキルIDに変換。
SkillId toSkillId(ulong id) { return cast(SkillId) id; }
/// スキルを使用するクラスの雛形。
/// 継承か委譲により、スキルの使用者を容易に実装できる。
class SkillUser : User!SkillId {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	@property
	void id(SkillId newVal) { mixin(S_TRACE);
		skill = newVal;
	}

	/// スキルIDを設定する。
	/// Params:
	/// id = スキルID。
	@property
	void skill(ulong id) { mixin(S_TRACE);
		if (_id != id) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_id > 0) _uc.remove(toSkillId(_id), this);
			if (id > 0) _uc.add(toSkillId(id), this);
		}
		_id = id;
	}

	/// Returns: スキルID。
	@property
	const
	ulong skill() { mixin(S_TRACE);
		return _id;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toSkillId(_id), this);
		}
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.add(toSkillId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toSkillId(_id), this);
		}
		_uc = null;
	}

	override bool change(SkillId newVal) { mixin(S_TRACE);
		if (_id != newVal) changed();
		_id = newVal;
		return true;
	}

	mixin CWXFuncs;
}
/// アイテムカードのID。
struct ItemId {
	ulong id;
	alias id this;
}
/// 数値をアイテムIDに変換。
ItemId toItemId(ulong id) { return cast(ItemId) id; }
/// アイテムを使用するクラスの雛形。
/// 継承か委譲により、アイテムの使用者を容易に実装できる。
class ItemUser : User!ItemId {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	@property
	void id(ItemId newVal) { mixin(S_TRACE);
		item = newVal;
	}

	/// アイテムIDを設定する。
	/// Params:
	/// id = アイテムID。
	@property
	void item(ulong id) { mixin(S_TRACE);
		if (_id != id) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_id > 0) _uc.remove(toItemId(_id), this);
			if (id > 0) _uc.add(toItemId(id), this);
		}
		_id = id;
	}

	/// Returns: アイテムID。
	@property
	const
	ulong item() { mixin(S_TRACE);
		return _id;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toItemId(_id), this);
		}
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.add(toItemId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toItemId(_id), this);
		}
		_uc = null;
	}

	override bool change(ItemId newVal) { mixin(S_TRACE);
		if (_id != newVal) changed();
		_id = newVal;
		return true;
	}

	mixin CWXFuncs;
}
/// 召喚獣カードのID。
struct BeastId {
	ulong id;
	alias id this;
}
/// 数値を召喚獣IDに変換。
BeastId toBeastId(ulong id) { return cast(BeastId) id; }
/// 召喚獣を使用するクラスの雛形。
/// 継承か委譲により、召喚獣の使用者を容易に実装できる。
class BeastUser : User!BeastId {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	@property
	void id(BeastId newVal) { mixin(S_TRACE);
		beast = newVal;
	}

	/// 召喚獣IDを設定する。
	/// Params:
	/// id = 召喚獣ID。
	@property
	void beast(ulong id) { mixin(S_TRACE);
		if (_id != id) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_id > 0) _uc.remove(toBeastId(_id), this);
			if (id > 0) _uc.add(toBeastId(id), this);
		}
		_id = id;
	}

	/// Returns: 召喚獣ID。
	@property
	const
	ulong beast() { mixin(S_TRACE);
		return _id;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toBeastId(_id), this);
		}
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.add(toBeastId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toBeastId(_id), this);
		}
		_uc = null;
	}

	override bool change(BeastId newVal) { mixin(S_TRACE);
		if (_id != newVal) changed();
		_id = newVal;
		return true;
	}

	mixin CWXFuncs;
}
/// 情報カードのID。
struct InfoId {
	ulong id;
	alias id this;
}
/// 数値を情報IDに変換。
InfoId toInfoId(ulong id) { return cast(InfoId) id; }
/// 情報カードを使用するクラスの雛形。
/// 継承か委譲により、情報カードの使用者を容易に実装できる。
class InfoUser : User!InfoId {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// IDを設定する。
	@property
	void id(InfoId newVal) { mixin(S_TRACE);
		info = newVal;
	}

	/// 情報カードIDを設定する。
	/// Params:
	/// id = 情報カードID。
	@property
	void info(ulong id) { mixin(S_TRACE);
		if (_id != id) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_id > 0) _uc.remove(toInfoId(_id), this);
			if (id > 0) _uc.add(toInfoId(id), this);
		}
		_id = id;
	}

	/// Returns: 情報カードID。
	@property
	const
	ulong info() { mixin(S_TRACE);
		return _id;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toInfoId(_id), this);
		}
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.add(toInfoId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.remove(toInfoId(_id), this);
		}
		_uc = null;
	}

	override bool change(InfoId newVal) { mixin(S_TRACE);
		if (_id != newVal) changed();
		_id = newVal;
		return true;
	}

	mixin CWXFuncs;
}

/// クーポンのID。
struct CouponId {
	string id;
	alias id this;
	mixin StringId;
}
/// 文字列をクーポンIDに変換。
CouponId toCouponId(string id) { return CouponId(id); }
/// クーポンを使用するクラスの雛形。
/// 継承か委譲により、クーポンの使用者を容易に実装できる。
class CouponUser : User!CouponId {
private:
	UseCounter _uc;
	CWXPath _ucOwner;
	SimpleTextHolder _coupon;
	bool _expandSPChars = false;
	CWXPath _cwxPath;
	bool _callback;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath, bool callback = false) { mixin(S_TRACE);
		_coupon = new SimpleTextHolder(this, TextHolderType.Coupon);
		_coupon.changeHandler = &changed;
		_coupon.owner = cwxPath;
		_cwxPath = cwxPath;
		_callback = callback;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }
	/// ditto
	@property
	void owner(CWXPath u) { mixin(S_TRACE);
		_coupon.owner = u;
		_cwxPath = u;
	}

	/// クーポンを設定する。
	/// Params:
	/// coupon = クーポン。
	@property
	void coupon(string coupon) { mixin(S_TRACE);
		if (_coupon.text == coupon) return;
		changed();
		if (_callback && cast(ChgCouponCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgCouponCallback)_cwxPath).changeCallback(CouponId(_coupon.text), CouponId(coupon))) { mixin(S_TRACE);
				return;
			}
		}
		if (_uc !is null) { mixin(S_TRACE);
			if (_coupon.text != "") _uc.remove(toCouponId(_coupon.text), this);
			if (coupon != "") _uc.add(toCouponId(coupon), this);
		}
		_coupon.text = coupon;
	}

	/// Returns: クーポン。
	@property
	const
	string coupon() { mixin(S_TRACE);
		return _coupon.text;
	}

	/// 特殊文字を展開するか(Wsn.4)。
	@property
	const
	bool expandSPChars() { return _expandSPChars; }
	/// ditto
	@property
	void expandSPChars(bool val) { mixin(S_TRACE);
		if (val != _expandSPChars) { mixin(S_TRACE);
			changed();
			_expandSPChars = val;
			if (_expandSPChars && _uc) { mixin(S_TRACE);
				_coupon.setUseCounter(_uc, ucOwner);
			} else { mixin(S_TRACE);
				_coupon.removeUseCounter();
			}
		}
	}

	/// クーポン内で使用されている状態変数のパス。
	@property
	const
	string[] flagsInText() { return expandSPChars ? _coupon.flagsInText : []; }
	/// ditto
	@property
	const
	string[] stepsInText() { return expandSPChars ? _coupon.stepsInText : []; }
	/// ditto
	@property
	const
	string[] variantsInText() { return expandSPChars ? _coupon.variantsInText : []; }

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc, CWXPath ucOwner) { mixin(S_TRACE);
		if (uc is _uc) return;
		if (_uc && _coupon.text != "") { mixin(S_TRACE);
			_uc.remove(toCouponId(_coupon.text), this);
		}
		if (uc && _coupon.text != "") { mixin(S_TRACE);
			uc.add(toCouponId(_coupon.text), this);
		}
		if (expandSPChars) _coupon.setUseCounter(uc, ucOwner);
		_uc = uc;
		_ucOwner = .renameInfo(ucOwner);
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _coupon.text != "") { mixin(S_TRACE);
			_uc.remove(toCouponId(_coupon.text), this);
		}
		_coupon.removeUseCounter();
		_uc = null;
		_ucOwner = null;
	}
	/// この使用者の所属先。必ずエリア・バトル・パッケージまたは
	/// 効果内の召喚獣カードを除く効果系カードになる。
	@property
	inout
	inout(CWXPath) ucOwner() { return _ucOwner; }

	override bool change(CouponId newVal) { mixin(S_TRACE);
		if (_coupon.text == newVal.id) return true;
		changed();
		if (_callback && cast(ChgCouponCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgCouponCallback)_cwxPath).changeCallback(CouponId(_coupon.text), newVal)) { mixin(S_TRACE);
				return false;
			}
		}
		_coupon.text = newVal.id;
		return true;
	}

	mixin CWXFuncs;
}

/// ゴシップのID。
struct GossipId {
	string id;
	alias id this;
	mixin StringId;
}
/// 文字列をゴシップIDに変換。
GossipId toGossipId(string id) { return GossipId(id); }
/// ゴシップを使用するクラスの雛形。
/// 継承か委譲により、ゴシップの使用者を容易に実装できる。
class GossipUser : User!GossipId {
private:
	UseCounter _uc;
	CWXPath _ucOwner;
	SimpleTextHolder _gossip;
	bool _expandSPChars = false;
	CWXPath _cwxPath;
	bool _callback;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath, bool callback = false) { mixin(S_TRACE);
		_gossip = new SimpleTextHolder(this, TextHolderType.Gossip);
		_gossip.changeHandler = &changed;
		_gossip.owner = cwxPath;
		_cwxPath = cwxPath;
		_callback = callback;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// ゴシップを設定する。
	/// Params:
	/// gossip = ゴシップ。
	@property
	void gossip(string gossip) { mixin(S_TRACE);
		if (_gossip.text == gossip) return;
		changed();
		if (_callback && cast(ChgGossipCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgGossipCallback)_cwxPath).changeCallback(GossipId(_gossip.text), GossipId(gossip))) { mixin(S_TRACE);
				return;
			}
		}
		if (_uc !is null) { mixin(S_TRACE);
			if (_gossip.text != "") _uc.remove(toGossipId(_gossip.text), this);
			if (gossip != "") _uc.add(toGossipId(gossip), this);
		}
		_gossip.text = gossip;
	}

	/// Returns: ゴシップ。
	@property
	const
	string gossip() { mixin(S_TRACE);
		return _gossip.text;
	}

	/// 特殊文字を展開するか(Wsn.4)。
	@property
	const
	bool expandSPChars() { return _expandSPChars; }
	/// ditto
	@property
	void expandSPChars(bool val) { mixin(S_TRACE);
		if (val != _expandSPChars) { mixin(S_TRACE);
			changed();
			_expandSPChars = val;
			if (_expandSPChars && _uc) { mixin(S_TRACE);
				_gossip.setUseCounter(_uc, ucOwner);
			} else { mixin(S_TRACE);
				_gossip.removeUseCounter();
			}
		}
	}

	/// ゴシップ内で使用されている状態変数のパス。
	@property
	const
	string[] flagsInText() { return expandSPChars ? _gossip.flagsInText : []; }
	/// ditto
	@property
	const
	string[] stepsInText() { return expandSPChars ? _gossip.stepsInText : []; }
	/// ditto
	@property
	const
	string[] variantsInText() { return expandSPChars ? _gossip.variantsInText : []; }

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc, CWXPath ucOwner) { mixin(S_TRACE);
		if (uc is _uc) return;
		if (_uc && _gossip.text != "") { mixin(S_TRACE);
			_uc.remove(toGossipId(_gossip.text), this);
		}
		if (uc && _gossip.text != "") { mixin(S_TRACE);
			uc.add(toGossipId(_gossip.text), this);
		}
		if (expandSPChars) _gossip.setUseCounter(uc, ucOwner);
		_uc = uc;
		_ucOwner = .renameInfo(ucOwner);
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _gossip.text != "") { mixin(S_TRACE);
			_uc.remove(toGossipId(_gossip.text), this);
		}
		_gossip.removeUseCounter();
		_uc = null;
		_ucOwner = null;
	}
	/// この使用者の所属先。必ずエリア・バトル・パッケージまたは
	/// 効果内の召喚獣カードを除く効果系カードになる。
	inout
	inout(CWXPath) ucOwner() { return _ucOwner; }

	override bool change(GossipId newVal) { mixin(S_TRACE);
		if (_gossip.text == newVal.id) return true;
		changed();
		if (_callback && cast(ChgGossipCallback)_cwxPath) { mixin(S_TRACE);
			if (!(cast(ChgGossipCallback)_cwxPath).changeCallback(GossipId(_gossip.text), newVal)) { mixin(S_TRACE);
				return false;
			}
		}
		_gossip.text = newVal.id;
		return true;
	}

	mixin CWXFuncs;
}

/// 終了印のID。
struct CompleteStampId {
	string id;
	alias id this;
	mixin StringId;
}
/// 文字列を終了印IDに変換。
CompleteStampId toCompleteStampId(string id) { return CompleteStampId(id); }
/// 終了印を使用するクラスの雛形。
/// 継承か委譲により、終了印の使用者を容易に実装できる。
class CompleteStampUser : User!CompleteStampId {
private:
	UseCounter _uc;
	CWXPath _ucOwner;
	string _completeStamp;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// 終了印を設定する。
	/// Params:
	/// completeStamp = 終了印。
	@property
	void completeStamp(string completeStamp) { mixin(S_TRACE);
		if (_completeStamp != completeStamp) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_completeStamp != "") _uc.remove(toCompleteStampId(_completeStamp), this);
			if (completeStamp != "") _uc.add(toCompleteStampId(completeStamp), this);
		}
		_completeStamp = completeStamp;
	}

	/// Returns: 終了印。
	@property
	const
	string completeStamp() { mixin(S_TRACE);
		return _completeStamp;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc, CWXPath ucOwner) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _completeStamp != "") { mixin(S_TRACE);
			_uc.remove(toCompleteStampId(_completeStamp), this);
		}
		if (uc && _completeStamp != "") { mixin(S_TRACE);
			uc.add(toCompleteStampId(_completeStamp), this);
		}
		_uc = uc;
		_ucOwner = .renameInfo(ucOwner);
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _completeStamp != "") { mixin(S_TRACE);
			_uc.remove(toCompleteStampId(_completeStamp), this);
		}
		_uc = null;
		_ucOwner = null;
	}
	/// この使用者の所属先。必ずエリア・バトル・パッケージまたは
	/// 効果内の召喚獣カードを除く効果系カードになる。
	inout
	inout(CWXPath) ucOwner() { return _ucOwner; }

	override bool change(CompleteStampId newVal) { mixin(S_TRACE);
		if (_completeStamp != newVal.id) changed();
		_completeStamp = newVal.id;
		return true;
	}

	mixin CWXFuncs;
}

/// キーコードのID。
struct KeyCodeId {
	string id;
	alias id this;
	mixin StringId;
}
/// 文字列をキーコードIDに変換。
KeyCodeId toKeyCodeId(string id) { return KeyCodeId(id); }
/// キーコードを使用するクラスの雛形。
/// 継承か委譲により、キーコードの使用者を容易に実装できる。
class KeyCodeUser : User!KeyCodeId {
private:
	UseCounter _uc;
	CWXPath _ucOwner;
	string _keyCode;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// キーコードを設定する。
	/// Params:
	/// keyCode = キーコード。
	@property
	void keyCode(string keyCode) { mixin(S_TRACE);
		if (_keyCode != keyCode) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_keyCode != "") _uc.remove(toKeyCodeId(_keyCode), this);
			if (keyCode != "") _uc.add(toKeyCodeId(keyCode), this);
		}
		_keyCode = keyCode;
	}

	/// Returns: キーコード。
	@property
	const
	string keyCode() { mixin(S_TRACE);
		return _keyCode;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc, CWXPath ucOwner) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _keyCode != "") { mixin(S_TRACE);
			_uc.remove(toKeyCodeId(_keyCode), this);
		}
		if (uc && _keyCode != "") { mixin(S_TRACE);
			uc.add(toKeyCodeId(_keyCode), this);
		}
		_uc = uc;
		_ucOwner = .renameInfo(ucOwner);
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _keyCode != "") { mixin(S_TRACE);
			_uc.remove(toKeyCodeId(_keyCode), this);
		}
		_uc = null;
		_ucOwner = null;
	}
	/// この使用者の所属先。必ずエリア・バトル・パッケージまたは
	/// 効果内の召喚獣カードを除く効果系カードになる。
	inout
	inout(CWXPath) ucOwner() { return _ucOwner; }

	override bool change(KeyCodeId newVal) { mixin(S_TRACE);
		if (_keyCode != newVal.id) changed();
		_keyCode = newVal.id;
		return true;
	}

	mixin CWXFuncs;
}

/// セル名称のID。
struct CellNameId {
	string id;
	alias id this;
	mixin StringId;
}
/// 文字列をセル名称IDに変換。
CellNameId toCellNameId(string id) { return CellNameId(id); }
/// セル名称を使用するクラスの雛形。
/// 継承か委譲により、セル名称の使用者を容易に実装できる。
class CellNameUser : User!CellNameId {
private:
	UseCounter _uc;
	CWXPath _ucOwner;
	string _cellName;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// セル名称を設定する。
	/// Params:
	/// cellName = セル名称。
	@property
	void cellName(string cellName) { mixin(S_TRACE);
		if (_cellName != cellName) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_cellName != "") _uc.remove(toCellNameId(_cellName), this);
			if (cellName != "") _uc.add(toCellNameId(cellName), this);
		}
		_cellName = cellName;
	}

	/// Returns: セル名称。
	@property
	const
	string cellName() { mixin(S_TRACE);
		return _cellName;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc, CWXPath ucOwner) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _cellName != "") { mixin(S_TRACE);
			_uc.remove(toCellNameId(_cellName), this);
		}
		if (uc && _cellName != "") { mixin(S_TRACE);
			uc.add(toCellNameId(_cellName), this);
		}
		_uc = uc;
		_ucOwner = .renameInfo(ucOwner);
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _cellName != "") { mixin(S_TRACE);
			_uc.remove(toCellNameId(_cellName), this);
		}
		_uc = null;
		_ucOwner = null;
	}
	/// この使用者の所属先。必ずエリア・バトル・パッケージまたは
	/// 効果内の召喚獣カードを除く効果系カードになる。
	inout
	inout(CWXPath) ucOwner() { return _ucOwner; }

	override bool change(CellNameId newVal) { mixin(S_TRACE);
		if (_cellName != newVal.id) changed();
		_cellName = newVal.id;
		return true;
	}

	mixin CWXFuncs;
}

/// カードグループのID。
struct CardGroupId {
	string id;
	alias id this;
	mixin StringId;
}
/// 文字列をカードグループIDに変換。
CardGroupId toCardGroupId(string id) { return CardGroupId(id); }
/// カードグループを使用するクラスの雛形。
/// 継承か委譲により、カードグループの使用者を容易に実装できる。
class CardGroupUser : User!CardGroupId {
private:
	UseCounter _uc;
	CWXPath _ucOwner;
	string _cardGroup;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { mixin(S_TRACE);
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(CWXPath) owner() { return _cwxPath; }

	/// カードグループを設定する。
	/// Params:
	/// cardGroup = カードグループ。
	@property
	void cardGroup(string cardGroup) { mixin(S_TRACE);
		if (_cardGroup != cardGroup) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_cardGroup != "") _uc.remove(toCardGroupId(_cardGroup), this);
			if (cardGroup != "") _uc.add(toCardGroupId(cardGroup), this);
		}
		_cardGroup = cardGroup;
	}

	/// Returns: カードグループ。
	@property
	const
	string cardGroup() { mixin(S_TRACE);
		return _cardGroup;
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc, CWXPath ucOwner) { mixin(S_TRACE);
		if (_uc is uc) return;
		if (_uc && _cardGroup != "") { mixin(S_TRACE);
			_uc.remove(toCardGroupId(_cardGroup), this);
		}
		if (uc && _cardGroup != "") { mixin(S_TRACE);
			uc.add(toCardGroupId(_cardGroup), this);
		}
		_uc = uc;
		_ucOwner = .renameInfo(ucOwner);
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _cardGroup != "") { mixin(S_TRACE);
			_uc.remove(toCardGroupId(_cardGroup), this);
		}
		_uc = null;
		_ucOwner = null;
	}
	/// この使用者の所属先。必ずエリア・バトル・パッケージまたは
	/// 効果内の召喚獣カードを除く効果系カードになる。
	inout
	inout(CWXPath) ucOwner() { return _ucOwner; }

	override bool change(CardGroupId newVal) { mixin(S_TRACE);
		if (_cardGroup != newVal.id) changed();
		_cardGroup = newVal.id;
		return true;
	}

	mixin CWXFuncs;
}

/// IDに対応する使用者情報。
template IDToUser(ID) {
	static if (is(ID:FlagId)) {
		alias FlagUser IDToUser;
	} else static if (is(ID:StepId)) {
		alias StepUser IDToUser;
	} else static if (is(ID:VariantId)) {
		alias VariantUser IDToUser;
	} else static if (is(ID:AreaId)) {
		alias AreaUser IDToUser;
	} else static if (is(ID:BattleId)) {
		alias BattleUser IDToUser;
	} else static if (is(ID:PackageId)) {
		alias PackageUser IDToUser;
	} else static if (is(ID:PathId)) {
		alias PathUser IDToUser;
	} else static if (is(ID:CastId)) {
		alias CastUser IDToUser;
	} else static if (is(ID:SkillId)) {
		alias SkillUser IDToUser;
	} else static if (is(ID:ItemId)) {
		alias ItemUser IDToUser;
	} else static if (is(ID:BeastId)) {
		alias BeastUser IDToUser;
	} else static if (is(ID:InfoId)) {
		alias InfoUser IDToUser;
	} else static if (is(ID:CouponId)) {
		alias CouponUser IDToUser;
	} else static if (is(ID:GossipId)) {
		alias GossipUser IDToUser;
	} else static if (is(ID:CompleteStampId)) {
		alias CompleteStampUser IDToUser;
	} else static if (is(ID:KeyCodeId)) {
		alias KeyCodeUser IDToUser;
	} else static if (is(ID:CellNameId)) {
		alias CellNameUser IDToUser;
	} else static if (is(ID:CardGroupId)) {
		alias CardGroupUser IDToUser;
	} else static assert (0, ID.stringof);
}

/// 使用回数カウンタ。
/// グローバル用とローカル用のSingleUseCounterを持ち、
/// ローカルのリソースの有無に応じて使用者を振り分ける。
class UseCounter {
	private CWXPath _owner = null;
	private UseCounter _globalUC = null;
	private SingleUseCounter _global = null;
	private SingleUseCounter _local = null;

	private UseCounter _sub = null;

	private bool[FlagId] _lFlag;
	private bool[StepId] _lStep;
	private bool[VariantId] _lVariant;
	private bool[AreaId] _lArea;
	private bool[BattleId] _lBattle;
	private bool[PackageId] _lPackage;
	private bool[PathId] _lPath;
	private bool[CastId] _lCast;
	private bool[SkillId] _lSkill;
	private bool[ItemId] _lItem;
	private bool[BeastId] _lBeast;
	private bool[InfoId] _lInfo;
	private bool[CouponId] _lCoupon;
	private bool[GossipId] _lGossip;
	private bool[CompleteStampId] _lCompleteStamp;
	private bool[KeyCodeId] _lKeyCode;
	private bool[CellNameId] _lCellName;
	private bool[CardGroupId] _lCardGroup;

	@property
	inout
	private ref inout(bool[ID]) localIDs(ID)() { mixin(S_TRACE);
		static if (is(ID:FlagId)) {
			return _lFlag;
		} else static if (is(ID:StepId)) {
			return _lStep;
		} else static if (is(ID:VariantId)) {
			return _lVariant;
		} else static if (is(ID:AreaId)) {
			return _lArea;
		} else static if (is(ID:BattleId)) {
			return _lBattle;
		} else static if (is(ID:PackageId)) {
			return _lPackage;
		} else static if (is(ID:PathId)) {
			return _lPath;
		} else static if (is(ID:CastId)) {
			return _lCast;
		} else static if (is(ID:SkillId)) {
			return _lSkill;
		} else static if (is(ID:ItemId)) {
			return _lItem;
		} else static if (is(ID:BeastId)) {
			return _lBeast;
		} else static if (is(ID:InfoId)) {
			return _lInfo;
		} else static if (is(ID:CouponId)) {
			return _lCoupon;
		} else static if (is(ID:GossipId)) {
			return _lGossip;
		} else static if (is(ID:CompleteStampId)) {
			return _lCompleteStamp;
		} else static if (is(ID:KeyCodeId)) {
			return _lKeyCode;
		} else static if (is(ID:CellNameId)) {
			return _lCellName;
		} else static if (is(ID:CardGroupId)) {
			return _lCardGroup;
		} else static assert (0, ID.stringof);
	}

	/// インスタンスを生成する。
	this (CWXPath owner) { mixin(S_TRACE);
		_globalUC = this;
		this (owner, new SingleUseCounter, null, true);
	}

	/// 親リソースの使用回数カウンタをグローバル用に指定して
	/// ローカル変数の使用回数カウンタを生成する。
	this (CWXPath owner, UseCounter global) { mixin(S_TRACE);
		_globalUC = global;
		this (owner, global._global, new SingleUseCounter, true);
	}
	private this (CWXPath owner, SingleUseCounter global, SingleUseCounter local, bool createSub) { mixin(S_TRACE);
		_owner = owner;
		_global = global;
		_local = local;
		if (createSub) _sub = new UseCounter(owner, global.sub, local ? local.sub : null, false);
	}

	/// この使用回数カウンタの所有者を返す。
	/// 一時的に使用される使用回数カウンタの場合はnull。
	@property
	inout
	inout(CWXPath) owner() { return _owner; }

	/// グローバルの使用回数カウンタ。
	@property
	inout
	inout(UseCounter) global() { return _globalUC; }

	/// 「アンドゥリストの中にあるのでカウントはしないが、パスの更新は反映したい」
	/// 等の場合に使う。
	@property
	UseCounter sub() { mixin(S_TRACE);
		return _sub ? _sub : this;
	}

	/// ローカルIDの有無。
	bool hasID(ID)(ID id) { mixin(S_TRACE);
		if (!_local) return false;
		return localIDs!ID.get(id, false);
	}

	/// ローカルIDの発生を通知する。
	void createID(ID)(ID id) in (!_local || id !in localIDs!ID) { mixin(S_TRACE);
		createIDImpl(id, true);
	}
	void createIDImpl(ID)(ID id, bool sub) in (!_local || id !in localIDs!ID) { mixin(S_TRACE);
		if (_local) { mixin(S_TRACE);
			localIDs!ID[id] = true;
			foreach (u; _global.values(id)) { mixin(S_TRACE);
				if (u.useCounter !is this) continue;
				_global.remove(id, u);
				_local.add(id, u);
			}
		}
		if (sub && _sub) _sub.createID(id);
	}
	/// ローカルIDの消滅を通知する。
	void deleteID(ID)(ID id) in (!_local || id in localIDs!ID) { mixin(S_TRACE);
		deleteIDImpl(id, true);
	}
	/// ditto
	void deleteIDImpl(ID)(ID id, bool sub) in (!_local || id in localIDs!ID) { mixin(S_TRACE);
		if (_local) { mixin(S_TRACE);
			localIDs!ID.remove(id);
			foreach (u; _local.values(id)) { mixin(S_TRACE);
				if (u.useCounter !is this) continue;
				_local.remove(id, u);
				_global.add(id, u);
			}
			assert (_local.get(id) == 0);
		}
		if (sub && _sub) _sub.deleteID(id);
	}

	/// ID・Tの変更を通知する。
	void change(ID)(ID oldId, ID newId, bool dup = false) { mixin(S_TRACE);
		if (oldId == newId) return;
		if (_local) { mixin(S_TRACE);
			if (oldId in localIDs!ID) { mixin(S_TRACE);
				assert (_local.get(newId) == 0);
				auto us = _local.values(oldId);
				typeof(us) us2;
				TChgCallback!ID[] cbs;

				foreach (u; us) { mixin(S_TRACE);
					assert (u.useCounter is this || !u.useCounter);
					auto cb = cast(TChgCallback!ID)u.owner;
					if (cb) { mixin(S_TRACE);
						// コールバックによるカウンタの再設定を避けるため
						// 所有者からもカウンタを取り除く
						cb.removeUseCounter();
						cbs ~= cb;
					} else { mixin(S_TRACE);
						u.removeUseCounter();
						us2 ~= u;
					}
					u.change(newId);
				}
				assert (_local.get(oldId) == 0);
				deleteIDImpl(oldId, false);
				createIDImpl(newId, false);
				assert (_local.get(newId) == 0);
				foreach (cb; cbs) { mixin(S_TRACE);
					cb.setUseCounter(this, cb.ucOwner);
				}
				foreach (u; us2) { mixin(S_TRACE);
					static if (is(typeof(u.ucOwner))) {
						u.setUseCounter(this, u.ucOwner);
					} else {
						u.setUseCounter(this);
					}
				}
				assert (_local.get(newId) == us.length);
			} else { mixin(S_TRACE);
				_local.change(oldId, newId, dup);
			}
		} else { mixin(S_TRACE);
			_global.change(oldId, newId, dup);
		}
		if (_sub) _sub.change(oldId, newId, dup);
	}
	/// userが持つIDの変更を行う。
	static void replaceID(ID, User)(ID id, User user) if (is(User:IDToUser!ID)) { mixin(S_TRACE);
		static if (is(ID:FlagId)) {
			user.flag = id;
		} else static if (is(ID:StepId)) {
			user.step = id;
		} else static if (is(ID:VariantId)) {
			user.variant = id;
		} else static if (is(ID:AreaId)) {
			user.area = id;
		} else static if (is(ID:BattleId)) {
			user.battle = id;
		} else static if (is(ID:PackageId)) {
			user.packages = id;
		} else static if (is(ID:PathId)) {
			user.path = id;
		} else static if (is(ID:CastId)) {
			user.casts = id;
		} else static if (is(ID:SkillId)) {
			user.skill = id;
		} else static if (is(ID:ItemId)) {
			user.item = id;
		} else static if (is(ID:BeastId)) {
			user.beast = id;
		} else static if (is(ID:InfoId)) {
			user.info = id;
		} else static if (is(ID:CouponId)) {
			user.coupon = id;
		} else static if (is(ID:GossipId)) {
			user.gossip = id;
		} else static if (is(ID:CompleteStampId)) {
			user.completeStamp = id;
		} else static if (is(ID:KeyCodeId)) {
			user.keyCode = id;
		} else static if (is(ID:CellNameId)) {
			user.cellName = id;
		} else static if (is(ID:CardGroupId)) {
			user.cardGroup = id;
		} else static assert (0, ID.stringof);
	}

	/// ID・Tの使用回数を返す。
	const
	uint get(ID)(ID id) { mixin(S_TRACE);
		if (_local) { mixin(S_TRACE);
			return _local.get(id);
		} else { mixin(S_TRACE);
			return _global.get(id);
		}
	}

	/// IDの一覧を返す。
	@property
	const
	ID[] keys(ID)() { mixin(S_TRACE);
		if (_local) { mixin(S_TRACE);
			return _local.keys!ID;
		} else { mixin(S_TRACE);
			return _global.keys!ID;
		}
	}

	/// idの使用者一覧を返す。
	@property
	const
	IDToUser!ID[] values(ID)(ID id) { mixin(S_TRACE);
		if (_local) { mixin(S_TRACE);
			return _local.values(id);
		} else { mixin(S_TRACE);
			return _global.values(id);
		}
	}
	/// ditto
	@property
	inout
	inout(HashSet!(IDToUser!ID)) valueSet(ID)(ID id) { mixin(S_TRACE);
		if (_local) { mixin(S_TRACE);
			return _local.valueSet(id);
		} else { mixin(S_TRACE);
			return _global.valueSet(id);
		}
	}

	/// IDの所有者を追跡する。
	package void add(ID, User)(ID id, User user) if (is(User:IDToUser!ID)) { mixin(S_TRACE);
		if (_local && id in localIDs!ID) { mixin(S_TRACE);
			_local.add(id, user);
		} else { mixin(S_TRACE);
			assert(_global);
			_global.add(id, user);
		}
	}
	/// IDの所有者を追跡から除外する。
	package void remove(ID, User)(ID id, User user) if (is(User:IDToUser!ID)) { mixin(S_TRACE);
		if (_local && id in localIDs!ID) { mixin(S_TRACE);
			_local.remove(id, user);
		} else { mixin(S_TRACE);
			assert(_global);
			_global.remove(id, user);
		}
	}
} unittest {
	mixin(UTPerf);
	auto uc = new UseCounter(null);
	auto luc = new UseCounter(null, uc);
	luc.createID(toFlagId("LOCAL_1"));

	auto u1 = new FlagUser(null);
	u1.flag = "LOCAL_1";
	u1.setUseCounter(luc);
	auto u2 = new FlagUser(null);
	u2.flag = "LOCAL_1";
	u2.setUseCounter(luc);
	auto u3 = new FlagUser(null);
	u3.flag = "LOCAL_2";
	u3.setUseCounter(luc);
	auto u4 = new FlagUser(null);
	u4.flag = "GLOBAL";
	u4.setUseCounter(luc);
	assert (uc.get(toFlagId("LOCAL_1")) == 0);
	assert (luc.get(toFlagId("LOCAL_1")) == 2);
	assert (uc.get(toFlagId("LOCAL_2")) == 1);
	assert (luc.get(toFlagId("LOCAL_2")) == 0);
	assert (uc.get(toFlagId("GLOBAL")) == 1);
	assert (luc.get(toFlagId("GLOBAL")) == 0);

	luc.createID(toFlagId("LOCAL_2"));
	assert (uc.get(toFlagId("LOCAL_1")) == 0);
	assert (luc.get(toFlagId("LOCAL_1")) == 2);
	assert (uc.get(toFlagId("LOCAL_2")) == 0);
	assert (luc.get(toFlagId("LOCAL_2")) == 1);
	assert (uc.get(toFlagId("GLOBAL")) == 1);
	assert (luc.get(toFlagId("GLOBAL")) == 0);

	luc.deleteID(toFlagId("LOCAL_1"));
	assert (uc.get(toFlagId("LOCAL_1")) == 2);
	assert (luc.get(toFlagId("LOCAL_1")) == 0);
	assert (uc.get(toFlagId("LOCAL_2")) == 0);
	assert (luc.get(toFlagId("LOCAL_2")) == 1);
	assert (uc.get(toFlagId("GLOBAL")) == 1);
	assert (luc.get(toFlagId("GLOBAL")) == 0);

	luc.createID(toFlagId("LOCAL_1"));
	luc.change(toFlagId("LOCAL_1"), toFlagId("LOCAL_3"));
	uc.change(toFlagId("GLOBAL"), toFlagId("GLOBAL_2"));
	assert (uc.get(toFlagId("LOCAL_1")) == 0);
	assert (luc.get(toFlagId("LOCAL_1")) == 0);
	assert (uc.get(toFlagId("LOCAL_2")) == 0);
	assert (luc.get(toFlagId("LOCAL_2")) == 1);
	assert (uc.get(toFlagId("LOCAL_3")) == 0);
	assert (luc.get(toFlagId("LOCAL_3")) == 2);
	assert (uc.get(toFlagId("GLOBAL")) == 0);
	assert (luc.get(toFlagId("GLOBAL")) == 0);
	assert (uc.get(toFlagId("GLOBAL_2")) == 1);
	assert (luc.get(toFlagId("GLOBAL_2")) == 0);

	u1.setUseCounter(luc.sub);
	u4.setUseCounter(uc.sub);
	assert (uc.get(toFlagId("LOCAL_3")) == 0);
	assert (luc.get(toFlagId("LOCAL_3")) == 1);
	assert (uc.get(toFlagId("GLOBAL_2")) == 0);
	assert (luc.get(toFlagId("GLOBAL_2")) == 0);

	luc.change(toFlagId("LOCAL_3"), toFlagId("LOCAL_42"));
	luc.change(toFlagId("GLOBAL_2"), toFlagId("GLOBAL_42"));
	assert (u1.flag == "LOCAL_42");
	assert (u2.flag == "LOCAL_42");
	assert (u4.flag == "GLOBAL_2");

	uc.change(toFlagId("LOCAL_42"), toFlagId("LOCAL_3"));
	uc.change(toFlagId("GLOBAL_2"), toFlagId("GLOBAL_42"));
	assert (u1.flag == "LOCAL_42");
	assert (u2.flag == "LOCAL_42");
	assert (u4.flag == "GLOBAL_42");

	luc.deleteID(toFlagId("LOCAL_42"));
	luc.change(toFlagId("LOCAL_42"), toFlagId("LOCAL_3"));
	assert (u1.flag == "LOCAL_42");
	assert (u2.flag == "LOCAL_42");

	uc.change(toFlagId("LOCAL_42"), toFlagId("LOCAL_3"));
	assert (u1.flag == "LOCAL_3");
	assert (u2.flag == "LOCAL_3");

	luc.createID(toFlagId("LOCAL_3"));
	luc.change(toFlagId("LOCAL_3"), toFlagId("LOCAL_42"));
	assert (u1.flag == "LOCAL_42");
	assert (u2.flag == "LOCAL_42");
}

/// 使用回数カウンタ。
/// IDやパスの変更を通知する役割も持つ。
private class SingleUseCounter {
private:
	UCCont!(FlagId, FlagUser) _flag;
	UCCont!(StepId, StepUser) _step;
	UCCont!(VariantId, VariantUser) _variant;
	UCCont!(AreaId, AreaUser) _area;
	UCCont!(BattleId, BattleUser) _battle;
	UCCont!(PackageId, PackageUser) _package;
	UCCont!(PathId, PathUser) _path;
	UCCont!(CastId, CastUser) _cast;
	UCCont!(SkillId, SkillUser) _skill;
	UCCont!(ItemId, ItemUser) _item;
	UCCont!(BeastId, BeastUser) _beast;
	UCCont!(InfoId, InfoUser) _info;
	UCCont!(CouponId, CouponUser) _coupon;
	UCCont!(GossipId, GossipUser) _gossip;
	UCCont!(CompleteStampId, CompleteStampUser) _completeStamp;
	UCCont!(KeyCodeId, KeyCodeUser) _keyCode;
	UCCont!(CellNameId, CellNameUser) _cellName;
	UCCont!(CardGroupId, CardGroupUser) _cardGroup;
	SingleUseCounter _child = null;

	@property
	inout
	inout(UCCont!(ID, IDToUser!ID)) ucc(ID)() { mixin(S_TRACE);
		static if (is(ID:FlagId)) {
			return _flag;
		} else static if (is(ID:StepId)) {
			return _step;
		} else static if (is(ID:VariantId)) {
			return _variant;
		} else static if (is(ID:AreaId)) {
			return _area;
		} else static if (is(ID:BattleId)) {
			return _battle;
		} else static if (is(ID:PackageId)) {
			return _package;
		} else static if (is(ID:PathId)) {
			return _path;
		} else static if (is(ID:CastId)) {
			return _cast;
		} else static if (is(ID:SkillId)) {
			return _skill;
		} else static if (is(ID:ItemId)) {
			return _item;
		} else static if (is(ID:BeastId)) {
			return _beast;
		} else static if (is(ID:InfoId)) {
			return _info;
		} else static if (is(ID:CouponId)) {
			return _coupon;
		} else static if (is(ID:GossipId)) {
			return _gossip;
		} else static if (is(ID:CompleteStampId)) {
			return _completeStamp;
		} else static if (is(ID:KeyCodeId)) {
			return _keyCode;
		} else static if (is(ID:CellNameId)) {
			return _cellName;
		} else static if (is(ID:CardGroupId)) {
			return _cardGroup;
		} else static assert (0, ID.stringof);
	}
public:
	/// 唯一のコンストラクタ。
	this () { mixin(S_TRACE);
		this (true);
	}
	private this (bool useChild) { mixin(S_TRACE);
		_flag = new UCCont!(FlagId, FlagUser);
		_step = new UCCont!(StepId, StepUser);
		_variant = new UCCont!(VariantId, VariantUser);
		_area = new UCCont!(AreaId, AreaUser);
		_battle = new UCCont!(BattleId, BattleUser);
		_package = new UCCont!(PackageId, PackageUser);
		_path = new UCCont!(PathId, PathUser);
		_cast = new UCCont!(CastId, CastUser);
		_skill = new  UCCont!(SkillId, SkillUser);
		_item = new UCCont!(ItemId, ItemUser);
		_beast = new UCCont!(BeastId, BeastUser);
		_info = new UCCont!(InfoId, InfoUser);
		_coupon = new UCCont!(CouponId, CouponUser);
		_gossip = new UCCont!(GossipId, GossipUser);
		_completeStamp = new UCCont!(CompleteStampId, CompleteStampUser);
		_keyCode = new UCCont!(KeyCodeId, KeyCodeUser);
		_cellName = new UCCont!(CellNameId, CellNameUser);
		_cardGroup = new UCCont!(CardGroupId, CardGroupUser);
		if (useChild) { mixin(S_TRACE);
			_child = new SingleUseCounter(false);
		}
	}

	/// 「アンドゥリストの中にあるのでカウントはしないが、パスの更新は反映したい」
	/// 等の場合に使う。
	@property
	SingleUseCounter sub() { mixin(S_TRACE);
		return _child ? _child : this;
	}

	/// ID・Tの変更を通知する。
	void change(T)(T oldId, T newId, bool dup = false) { mixin(S_TRACE);
		(ucc!T).change(oldId, newId, dup);
		if (_child) _child.change(oldId, newId, dup);
	}

	/// ID・Tの使用回数を返す。
	const
	uint get(T)(T id) { mixin(S_TRACE);
		return (ucc!T).get(id);
	}

	/// IDの一覧を返す。
	@property
	const
	ID[] keys(ID)() { return (ucc!ID).keys; }

	/// idの使用者一覧を返す。
	@property
	const
	IDToUser!ID[] values(ID)(ID id) { mixin(S_TRACE);
		return (ucc!ID).values(id);
	}
	/// ditto
	@property
	inout
	inout(HashSet!(IDToUser!ID)) valueSet(ID)(ID id) { return (ucc!ID).valueSet(id); }

	/// IDの所有者を追跡する。
	private void add(ID, User)(ID id, User user) if (is(User:IDToUser!ID)) { (ucc!ID).add(id, user); }
	/// IDの所有者を追跡から除外する。
	private void remove(ID, User)(ID id, User user) if (is(User:IDToUser!ID)) { (ucc!ID).remove(id, user); }
}

/// 称号・名称置換の範囲限定用の情報(リソースの所属情報)を返す。
CWXPath renameInfo(CWXPath path) { mixin(S_TRACE);
	import cwx.area;
	import cwx.card;
	import cwx.motion;
	import cwx.summary;
	if (!path) return path;
	while (path.cwxParent && !cast(Summary)path && !cast(CastCard)path && !cast(AbstractArea)path && !(cast(EffectCard)path && !cast(Motion)(cast(EffectCard)path).cwxParent)) { mixin(S_TRACE);
		path = path.cwxParent;
	}
	return path;
}

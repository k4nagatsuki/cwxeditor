
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
		return p ? *p : null;
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
	bool changeCallback(T, T);
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
/// フラグの使用者。
interface IFlagUser : User!(FlagId) {
}
/// フラグを使用するクラスの雛形。
/// 継承か委譲により、フラグの使用者を容易に実装できる。
class FlagUser : IFlagUser {
private:
	UseCounter _uc;
	string _flag;
	IFlagUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IFlagUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IFlagUser) owner() { return _cwxPath; }

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
			if (_flag !is null) _uc.flag.remove(toFlagId(_flag), this);
			if (flag !is null) _uc.flag.add(toFlagId(flag), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _flag) { mixin(S_TRACE);
			uc.flag.add(toFlagId(_flag), this);
		}
		if (_uc && _flag) { mixin(S_TRACE);
			_uc.flag.remove(toFlagId(_flag), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _flag !is null) { mixin(S_TRACE);
			_uc.flag.remove(toFlagId(_flag), this);
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
/// ステップの使用者。
interface IStepUser : User!(StepId) {
}
/// ステップを使用するクラスの雛形。
/// 継承か委譲により、ステップの使用者を容易に実装できる。
class StepUser : IStepUser {
private:
	UseCounter _uc;
	string _step;
	IStepUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IStepUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IStepUser) owner() { return _cwxPath; }

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
			if (_step !is null) _uc.step.remove(toStepId(_step), this);
			if (step !is null) _uc.step.add(toStepId(step), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _step) { mixin(S_TRACE);
			uc.step.add(toStepId(_step), this);
		}
		if (_uc && _step) { mixin(S_TRACE);
			_uc.step.remove(toStepId(_step), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _step !is null) { mixin(S_TRACE);
			_uc.step.remove(toStepId(_step), this);
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
/// コモンの使用者。
interface IVariantUser : User!(VariantId) {
}
/// コモンを使用するクラスの雛形。
/// 継承か委譲により、コモンの使用者を容易に実装できる。
class VariantUser : IVariantUser {
private:
	UseCounter _uc;
	string _variant;
	IVariantUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IVariantUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IVariantUser) owner() { return _cwxPath; }

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
			if (_variant !is null) _uc.variant.remove(toVariantId(_variant), this);
			if (variant !is null) _uc.variant.add(toVariantId(variant), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _variant) { mixin(S_TRACE);
			uc.variant.add(toVariantId(_variant), this);
		}
		if (_uc && _variant) { mixin(S_TRACE);
			_uc.variant.remove(toVariantId(_variant), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _variant !is null) { mixin(S_TRACE);
			_uc.variant.remove(toVariantId(_variant), this);
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
/// エリアの使用者。
interface IAreaUser : User!(AreaId) {
}
/// エリアを使用するクラスの雛形。
/// 継承か委譲により、エリアの使用者を容易に実装できる。
class AreaUser : IAreaUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	IAreaUser _cwxPath;
	bool _callback;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IAreaUser cwxPath, bool callback = false) { mixin(S_TRACE);
		_cwxPath = cwxPath;
		_callback = callback;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IAreaUser) owner() { return _cwxPath; }

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
			if (_id > 0) _uc.area.remove(toAreaId(_id), this);
			if (id > 0) _uc.area.add(toAreaId(id), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.area.add(toAreaId(_id), this);
		}
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.area.remove(toAreaId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.area.remove(toAreaId(_id), this);
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
BattleId toBattleId(ulong id) { return cast(BattleId) id; }
/// バトルの使用者。
interface IBattleUser : User!(BattleId) {
}
/// バトルを使用するクラスの雛形。
/// 継承か委譲により、バトルの使用者を容易に実装できる。
class BattleUser : IBattleUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	IBattleUser _cwxPath;
	bool _callback;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IBattleUser cwxPath, bool callback = false) { mixin(S_TRACE);
		_cwxPath = cwxPath;
		_callback = callback;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IBattleUser) owner() { return _cwxPath; }

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
			if (_id > 0) _uc.battle.remove(toBattleId(_id), this);
			if (id > 0) _uc.battle.add(toBattleId(id), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.battle.add(toBattleId(_id), this);
		}
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.battle.remove(toBattleId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.battle.remove(toBattleId(_id), this);
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
/// パッケージの使用者。
interface IPackageUser : User!(PackageId) {
}
/// パッケージを使用するクラスの雛形。
/// 継承か委譲により、パッケージの使用者を容易に実装できる。
class PackageUser : IPackageUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	IPackageUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IPackageUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IPackageUser) owner() { return _cwxPath; }

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
			if (_id > 0) _uc.packages.remove(toPackageId(_id), this);
			if (id > 0) _uc.packages.add(toPackageId(id), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.packages.add(toPackageId(_id), this);
		}
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.packages.remove(toPackageId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.packages.remove(toPackageId(_id), this);
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
/// ファイルパスの使用者。
interface IPathUser : User!(PathId) {
}
const BI_PATH_ID = "binaryimage://Binary:Image";
const BS_PATH_ID = "binarysound://Binary:Sound";
/// ファイルパスを使用するクラスの雛形。
/// 継承か委譲により、ファイルパスの使用者を容易に実装できる。
class PathUser : IPathUser {
private:
	UseCounter _uc;
	PathId _path;
	IPathUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IPathUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IPathUser) owner() { return _cwxPath; }

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
				_uc.path.remove(_path, this);
			}
			if (path.length) { mixin(S_TRACE);
				_uc.path.add(id, this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _path.valid) { mixin(S_TRACE);
			uc.path.add(_path, this);
		}
		if (_uc && _path.valid) { mixin(S_TRACE);
			_uc.path.remove(_path, this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _path.valid) { mixin(S_TRACE);
			_uc.path.remove(_path, this);
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
/// キャストカードの使用者。
interface ICastUser : User!(CastId) {
}
/// キャストを使用するクラスの雛形。
/// 継承か委譲により、キャストの使用者を容易に実装できる。
class CastUser : ICastUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	ICastUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (ICastUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(ICastUser) owner() { return _cwxPath; }

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
			if (_id > 0) _uc.casts.remove(toCastId(_id), this);
			if (id > 0) _uc.casts.add(toCastId(id), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.casts.add(toCastId(_id), this);
		}
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.casts.remove(toCastId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.casts.remove(toCastId(_id), this);
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
/// スキルカードの使用者。
interface ISkillUser : User!(SkillId) {
}
/// スキルを使用するクラスの雛形。
/// 継承か委譲により、スキルの使用者を容易に実装できる。
class SkillUser : ISkillUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	ISkillUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (ISkillUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(ISkillUser) owner() { return _cwxPath; }

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
			if (_id > 0) _uc.skill.remove(toSkillId(_id), this);
			if (id > 0) _uc.skill.add(toSkillId(id), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.skill.add(toSkillId(_id), this);
		}
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.skill.remove(toSkillId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.skill.remove(toSkillId(_id), this);
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
/// アイテムカードの使用者。
interface IItemUser : User!(ItemId) {
}
/// アイテムを使用するクラスの雛形。
/// 継承か委譲により、アイテムの使用者を容易に実装できる。
class ItemUser : IItemUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	IItemUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IItemUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IItemUser) owner() { return _cwxPath; }

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
			if (_id > 0) _uc.item.remove(toItemId(_id), this);
			if (id > 0) _uc.item.add(toItemId(id), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.item.add(toItemId(_id), this);
		}
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.item.remove(toItemId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.item.remove(toItemId(_id), this);
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
/// 召喚獣カードの使用者。
interface IBeastUser : User!(BeastId) {
}
/// 召喚獣を使用するクラスの雛形。
/// 継承か委譲により、召喚獣の使用者を容易に実装できる。
class BeastUser : IBeastUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	IBeastUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IBeastUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IBeastUser) owner() { return _cwxPath; }

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
			if (_id > 0) _uc.beast.remove(toBeastId(_id), this);
			if (id > 0) _uc.beast.add(toBeastId(id), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.beast.add(toBeastId(_id), this);
		}
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.beast.remove(toBeastId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.beast.remove(toBeastId(_id), this);
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
/// 情報カードの使用者。
interface IInfoUser : User!(InfoId) {
}
/// 情報カードを使用するクラスの雛形。
/// 継承か委譲により、情報カードの使用者を容易に実装できる。
class InfoUser : IInfoUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	IInfoUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IInfoUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IInfoUser) owner() { return _cwxPath; }

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
			if (_id > 0) _uc.info.remove(toInfoId(_id), this);
			if (id > 0) _uc.info.add(toInfoId(id), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _id > 0) { mixin(S_TRACE);
			uc.info.add(toInfoId(_id), this);
		}
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.info.remove(toInfoId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _id > 0) { mixin(S_TRACE);
			_uc.info.remove(toInfoId(_id), this);
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
/// クーポンの使用者。
interface ICouponUser : User!(CouponId) {
}
/// クーポンを使用するクラスの雛形。
/// 継承か委譲により、クーポンの使用者を容易に実装できる。
class CouponUser : ICouponUser {
private:
	UseCounter _uc;
	SimpleTextHolder _coupon;
	bool _expandSPChars = false;
	ICouponUser _cwxPath;
	bool _callback;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (ICouponUser cwxPath, bool callback = false) { mixin(S_TRACE);
		_coupon = new SimpleTextHolder;
		_coupon.changeHandler = &changed;
		_coupon.owner = cwxPath;
		_cwxPath = cwxPath;
		_callback = callback;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(ICouponUser) owner() { return _cwxPath; }
	/// ditto
	@property
	void owner(ICouponUser u) { mixin(S_TRACE);
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
		if (expandSPChars && _uc !is null) { mixin(S_TRACE);
			if (_coupon.text != "") _uc.coupon.remove(toCouponId(_coupon.text), this);
			if (coupon != "") _uc.coupon.add(toCouponId(coupon), this);
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
				_coupon.setUseCounter(_uc);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _coupon.text != "") { mixin(S_TRACE);
			uc.coupon.add(toCouponId(_coupon.text), this);
		}
		if (_uc && _coupon.text != "") { mixin(S_TRACE);
			_uc.coupon.remove(toCouponId(_coupon.text), this);
		}
		if (expandSPChars) _coupon.setUseCounter(uc);
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _coupon.text != "") { mixin(S_TRACE);
			_uc.coupon.remove(toCouponId(_coupon.text), this);
		}
		_coupon.removeUseCounter();
		_uc = null;
	}
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
/// ゴシップの使用者。
interface IGossipUser : User!(GossipId) {
}
/// ゴシップを使用するクラスの雛形。
/// 継承か委譲により、ゴシップの使用者を容易に実装できる。
class GossipUser : IGossipUser {
private:
	UseCounter _uc;
	SimpleTextHolder _gossip;
	bool _expandSPChars = false;
	IGossipUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IGossipUser cwxPath) { mixin(S_TRACE);
		_gossip = new SimpleTextHolder;
		_gossip.changeHandler = &changed;
		_gossip.owner = cwxPath;
		_cwxPath = cwxPath;
	}
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IGossipUser) owner() { return _cwxPath; }

	/// ゴシップを設定する。
	/// Params:
	/// gossip = ゴシップ。
	@property
	void gossip(string gossip) { mixin(S_TRACE);
		if (_gossip.text != gossip) changed();
		if (expandSPChars && _uc !is null) { mixin(S_TRACE);
			if (_gossip.text != "") _uc.gossip.remove(toGossipId(_gossip.text), this);
			if (gossip != "") _uc.gossip.add(toGossipId(gossip), this);
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
				_gossip.setUseCounter(_uc);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _gossip.text != "") { mixin(S_TRACE);
			uc.gossip.add(toGossipId(_gossip.text), this);
		}
		if (_uc && _gossip.text != "") { mixin(S_TRACE);
			_uc.gossip.remove(toGossipId(_gossip.text), this);
		}
		if (expandSPChars) _gossip.setUseCounter(uc);
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _gossip.text != "") { mixin(S_TRACE);
			_uc.gossip.remove(toGossipId(_gossip.text), this);
		}
		_gossip.removeUseCounter();
		_uc = null;
	}
	override bool change(GossipId newVal) { mixin(S_TRACE);
		if (_gossip.text != newVal.id) changed();
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
/// 終了印の使用者。
interface ICompleteStampUser : User!(CompleteStampId) {
}
/// 終了印を使用するクラスの雛形。
/// 継承か委譲により、終了印の使用者を容易に実装できる。
class CompleteStampUser : ICompleteStampUser {
private:
	UseCounter _uc;
	string _completeStamp;
	ICompleteStampUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (ICompleteStampUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(ICompleteStampUser) owner() { return _cwxPath; }

	/// 終了印を設定する。
	/// Params:
	/// completeStamp = 終了印。
	@property
	void completeStamp(string completeStamp) { mixin(S_TRACE);
		if (_completeStamp != completeStamp) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_completeStamp != "") _uc.completeStamp.remove(toCompleteStampId(_completeStamp), this);
			if (completeStamp != "") _uc.completeStamp.add(toCompleteStampId(completeStamp), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _completeStamp != "") { mixin(S_TRACE);
			uc.completeStamp.add(toCompleteStampId(_completeStamp), this);
		}
		if (_uc && _completeStamp != "") { mixin(S_TRACE);
			_uc.completeStamp.remove(toCompleteStampId(_completeStamp), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _completeStamp != "") { mixin(S_TRACE);
			_uc.completeStamp.remove(toCompleteStampId(_completeStamp), this);
		}
		_uc = null;
	}
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
/// キーコードの使用者。
interface IKeyCodeUser : User!(KeyCodeId) {
}
/// キーコードを使用するクラスの雛形。
/// 継承か委譲により、キーコードの使用者を容易に実装できる。
class KeyCodeUser : IKeyCodeUser {
private:
	UseCounter _uc;
	string _keyCode;
	IKeyCodeUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (IKeyCodeUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(IKeyCodeUser) owner() { return _cwxPath; }

	/// キーコードを設定する。
	/// Params:
	/// keyCode = キーコード。
	@property
	void keyCode(string keyCode) { mixin(S_TRACE);
		if (_keyCode != keyCode) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_keyCode != "") _uc.keyCode.remove(toKeyCodeId(_keyCode), this);
			if (keyCode != "") _uc.keyCode.add(toKeyCodeId(keyCode), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _keyCode != "") { mixin(S_TRACE);
			uc.keyCode.add(toKeyCodeId(_keyCode), this);
		}
		if (_uc && _keyCode != "") { mixin(S_TRACE);
			_uc.keyCode.remove(toKeyCodeId(_keyCode), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _keyCode != "") { mixin(S_TRACE);
			_uc.keyCode.remove(toKeyCodeId(_keyCode), this);
		}
		_uc = null;
	}
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
/// セル名称の使用者。
interface ICellNameUser : User!(CellNameId) {
}
/// セル名称を使用するクラスの雛形。
/// 継承か委譲により、セル名称の使用者を容易に実装できる。
class CellNameUser : ICellNameUser {
private:
	UseCounter _uc;
	string _cellName;
	ICellNameUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (ICellNameUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(ICellNameUser) owner() { return _cwxPath; }

	/// セル名称を設定する。
	/// Params:
	/// cellName = セル名称。
	@property
	void cellName(string cellName) { mixin(S_TRACE);
		if (_cellName != cellName) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_cellName != "") _uc.cellName.remove(toCellNameId(_cellName), this);
			if (cellName != "") _uc.cellName.add(toCellNameId(cellName), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _cellName != "") { mixin(S_TRACE);
			uc.cellName.add(toCellNameId(_cellName), this);
		}
		if (_uc && _cellName != "") { mixin(S_TRACE);
			_uc.cellName.remove(toCellNameId(_cellName), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _cellName != "") { mixin(S_TRACE);
			_uc.cellName.remove(toCellNameId(_cellName), this);
		}
		_uc = null;
	}
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
/// カードグループの使用者。
interface ICardGroupUser : User!(CardGroupId) {
}
/// カードグループを使用するクラスの雛形。
/// 継承か委譲により、カードグループの使用者を容易に実装できる。
class CardGroupUser : ICardGroupUser {
private:
	UseCounter _uc;
	string _cardGroup;
	ICardGroupUser _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (ICardGroupUser cwxPath) { _cwxPath = cwxPath; }
	/// このオブジェクトの所有者。
	@property
	inout
	inout(ICardGroupUser) owner() { return _cwxPath; }

	/// カードグループを設定する。
	/// Params:
	/// cardGroup = カードグループ。
	@property
	void cardGroup(string cardGroup) { mixin(S_TRACE);
		if (_cardGroup != cardGroup) changed();
		if (_uc !is null) { mixin(S_TRACE);
			if (_cardGroup != "") _uc.cardGroup.remove(toCardGroupId(_cardGroup), this);
			if (cardGroup != "") _uc.cardGroup.add(toCardGroupId(cardGroup), this);
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
	UseCounter useCounter() { return _uc; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		if (uc && _cardGroup != "") { mixin(S_TRACE);
			uc.cardGroup.add(toCardGroupId(_cardGroup), this);
		}
		if (_uc && _cardGroup != "") { mixin(S_TRACE);
			_uc.cardGroup.remove(toCardGroupId(_cardGroup), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		if (_uc && _cardGroup != "") { mixin(S_TRACE);
			_uc.cardGroup.remove(toCardGroupId(_cardGroup), this);
		}
		_uc = null;
	}
	override bool change(CardGroupId newVal) { mixin(S_TRACE);
		if (_cardGroup != newVal.id) changed();
		_cardGroup = newVal.id;
		return true;
	}

	mixin CWXFuncs;
}

/// 使用回数カウンタ。
/// IDやパスの変更を通知する役割も持つ。
class UseCounter {
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
	UseCounter _child = null;
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
			_child = new UseCounter(false);
		}
	}
	/// 「アンドゥリストの中にあるのでカウントはしないが、パスの更新は反映したい」
	/// 等の場合に使う。
	@property
	UseCounter sub() { mixin(S_TRACE);
		return _child;
	}
	/// 各種カウント対象の使用者のコンテナ。
	@property
	UCCont!(FlagId, FlagUser) flag() { return _flag; }
	/// ditto
	@property
	UCCont!(StepId, StepUser) step() { return _step; }
	/// ditto
	@property
	UCCont!(VariantId, VariantUser) variant() { return _variant; }
	/// ditto
	@property
	UCCont!(AreaId, AreaUser) area() { return _area; }
	/// ditto
	@property
	UCCont!(BattleId, BattleUser) battle() { return _battle; }
	/// ditto
	@property
	UCCont!(PackageId, PackageUser) packages() { return _package; }
	/// ditto
	@property
	UCCont!(PathId, PathUser) path() { return _path; }
	/// ditto
	@property
	UCCont!(CastId, CastUser) casts() { return _cast; }
	/// ditto
	@property
	UCCont!(SkillId, SkillUser) skill() { return _skill; }
	/// ditto
	@property
	UCCont!(ItemId, ItemUser) item() { return _item; }
	/// ditto
	@property
	UCCont!(BeastId, BeastUser) beast() { return _beast; }
	/// ditto
	@property
	UCCont!(InfoId, InfoUser) info() { return _info; }
	/// ditto
	@property
	UCCont!(CouponId, CouponUser) coupon() { return _coupon; }
	/// ditto
	@property
	UCCont!(GossipId, GossipUser) gossip() { return _gossip; }
	/// ditto
	@property
	UCCont!(CompleteStampId, CompleteStampUser) completeStamp() { return _completeStamp; }
	/// ditto
	@property
	UCCont!(KeyCodeId, KeyCodeUser) keyCode() { return _keyCode; }
	/// ditto
	@property
	UCCont!(CellNameId, CellNameUser) cellName() { return _cellName; }
	/// ditto
	@property
	UCCont!(CardGroupId, CardGroupUser) cardGroup() { return _cardGroup; }

	/// ID・Tの変更を通知する。
	void change(T)(T oldId, T newId, bool dup = false) { mixin(S_TRACE);
		static if (is(T == FlagId)) {
			flag.change(oldId, newId, dup);
		} else static if (is(T == StepId)) {
			step.change(oldId, newId, dup);
		} else static if (is(T == VariantId)) {
			variant.change(oldId, newId, dup);
		} else static if (is(T == AreaId)) {
			area.change(oldId, newId, dup);
		} else static if (is(T == BattleId)) {
			battle.change(oldId, newId, dup);
		} else static if (is(T == PackageId)) {
			packages.change(oldId, newId, dup);
		} else static if (is(T == PathId)) {
			path.change(oldId, newId, dup);
		} else static if (is(T == CastId)) {
			casts.change(oldId, newId, dup);
		} else static if (is(T == SkillId)) {
			skill.change(oldId, newId, dup);
		} else static if (is(T == ItemId)) {
			item.change(oldId, newId, dup);
		} else static if (is(T == BeastId)) {
			beast.change(oldId, newId, dup);
		} else static if (is(T == InfoId)) {
			info.change(oldId, newId, dup);
		} else static if (is(T == CouponId)) {
			coupon.change(oldId, newId, dup);
		} else static if (is(T == GossipId)) {
			gossip.change(oldId, newId, dup);
		} else static if (is(T == CompleteStampId)) {
			completeStamp.change(oldId, newId, dup);
		} else static if (is(T == KeyCodeId)) {
			keyCode.change(oldId, newId, dup);
		} else static if (is(T == CellNameId)) {
			cellName.change(oldId, newId, dup);
		} else static if (is(T == CardGroupId)) {
			cardGroup.change(oldId, newId, dup);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		if (_child) _child.change(oldId, newId, dup);
	}
	/// ID・Tの使用回数を返す。
	const
	uint get(T)(T id) { mixin(S_TRACE);
		static if (is(T:FlagId)) {
			return _flag.get(id);
		} else static if (is(T:StepId)) {
			return _step.get(id);
		} else static if (is(T:VariantId)) {
			return _variant.get(id);
		} else static if (is(T:AreaId)) {
			return _area.get(id);
		} else static if (is(T:BattleId)) {
			return _battle.get(id);
		} else static if (is(T:PackageId)) {
			return _package.get(id);
		} else static if (is(T:PathId)) {
			return _path.get(id);
		} else static if (is(T:CastId)) {
			return _cast.get(id);
		} else static if (is(T:SkillId)) {
			return _skill.get(id);
		} else static if (is(T:ItemId)) {
			return _item.get(id);
		} else static if (is(T:BeastId)) {
			return _beast.get(id);
		} else static if (is(T:InfoId)) {
			return _info.get(id);
		} else static if (is(T:CouponId)) {
			return _coupon.get(id);
		} else static if (is(T:GossipId)) {
			return _gossip.get(id);
		} else static if (is(T:CompleteStampId)) {
			return _completeStamp.get(id);
		} else static if (is(T:KeyCodeId)) {
			return _keyCode.get(id);
		} else static if (is(T:CellNameId)) {
			return _cellName.get(id);
		} else static if (is(T:CardGroupId)) {
			return _cardGroup.get(id);
		} else { mixin(S_TRACE);
			static assert (0);
		}
	}
	/// idの使用者一覧を返す。
	@property
	const
	FlagUser[] values(FlagId id) { return _flag.values(id); }
	@property
	const
	StepUser[] values(StepId id) { return _step.values(id); } /// ditto
	@property
	const
	VariantUser[] values(VariantId id) { return _variant.values(id); } /// ditto
	@property
	const
	AreaUser[] values(AreaId id) { return _area.values(id); } /// ditto
	@property
	const
	BattleUser[] values(BattleId id) { return _battle.values(id); } /// ditto
	@property
	const
	PackageUser[] values(PackageId id) { return _package.values(id); } /// ditto
	@property
	const
	PathUser[] values(PathId id) { return _path.values(id); } /// ditto
	@property
	const
	CastUser[] values(CastId id) { return _cast.values(id); } /// ditto
	@property
	const
	SkillUser[] values(SkillId id) { return _skill.values(id); } /// ditto
	@property
	const
	ItemUser[] values(ItemId id) { return _item.values(id); } /// ditto
	@property
	const
	BeastUser[] values(BeastId id) { return _beast.values(id); } /// ditto
	@property
	const
	InfoUser[] values(InfoId id) { return _info.values(id); } /// ditto
	@property
	const
	CouponUser[] values(CouponId id) { return _coupon.values(id); } /// ditto
	@property
	const
	GossipUser[] values(GossipId id) { return _gossip.values(id); } /// ditto
	@property
	const
	CompleteStampUser[] values(CompleteStampId id) { return _completeStamp.values(id); } /// ditto
	@property
	const
	KeyCodeUser[] values(KeyCodeId id) { return _keyCode.values(id); } /// ditto
	@property
	const
	CellNameUser[] values(CellNameId id) { return _cellName.values(id); } /// ditto
	@property
	const
	CardGroupUser[] values(CardGroupId id) { return _cardGroup.values(id); } /// ditto

	@property
	inout
	inout(HashSet!FlagUser) valueSet(FlagId id) { return _flag.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!StepUser) valueSet(StepId id) { return _step.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!VariantUser) valueSet(VariantId id) { return _variant.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!AreaUser) valueSet(AreaId id) { return _area.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!BattleUser) valueSet(BattleId id) { return _battle.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!PackageUser) valueSet(PackageId id) { return _package.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!PathUser) valueSet(PathId id) { return _path.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!CastUser) valueSet(CastId id) { return _cast.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!SkillUser) valueSet(SkillId id) { return _skill.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!ItemUser) valueSet(ItemId id) { return _item.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!BeastUser) valueSet(BeastId id) { return _beast.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!InfoUser) valueSet(InfoId id) { return _info.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!CouponUser) valueSet(CouponId id) { return _coupon.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!GossipUser) valueSet(GossipId id) { return _gossip.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!CompleteStampUser) valueSet(CompleteStampId id) { return _completeStamp.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!KeyCodeUser) valueSet(KeyCodeId id) { return _keyCode.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!CellNameUser) valueSet(CellNameId id) { return _cellName.valueSet(id); } /// ditto
	@property
	inout
	inout(HashSet!CardGroupUser) valueSet(CardGroupId id) { return _cardGroup.valueSet(id); } /// ditto
}

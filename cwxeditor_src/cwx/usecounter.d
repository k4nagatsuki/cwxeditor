
module cwx.usecounter;

import cwx.flag;
import cwx.utils;
import cwx.path;

import std.array;
import std.conv;
import std.ascii;
import std.path;
import std.string;

/// Kの使用者。
interface User(K) {
	void change(K newVal);
}

/// Kの使用者Uを登録し、変更通知等を受け取れるようにする。
class UCCont(K, U) {
private:
	HashSet!(U)[K] _cont;
public:
	/// キーの使用回数を返す。
	/// Params:
	/// key = キー。
	/// Returns: 使用回数。
	const
	uint get(K key) {
		auto p = key in _cont;
		return p ? p.size : 0;
	}

	/// キーの一覧を返す。
	/// Returns: キーの一覧。
	const
	K[] keys() {
		return _cont.keys;
	}

	/// キーの使用者の一覧を返す。
	/// Params:
	/// key = キー。
	/// Returns: 使用者の一覧。
	const
	U[] values(K key) {
		auto p = key in _cont;
		return p ? p.toArray : cast(U[]) [];
	}

	/// キーの使用者を追加する。
	/// Params:
	/// key = キー。
	/// user = 使用者。
	void add(K key, U user) {
		HashSet!(U) set;
		if (key in _cont) {
			set = _cont[key];
		} else {
			set = new HashSet!(U);
			_cont[key] = set;
		}
		set.add(user);
	}
	/// キーの使用者を除外する。
	/// Params:
	/// key = キー。
	/// user = 使用者。
	void remove(K key, U user) {
		auto set = _cont[key];
		set.remove(user);
		if (set.isEmpty) {
			_cont.remove(key);
			delete set;
		}
	}
	/// キーに変更があったときに呼出す。
	/// Params:
	/// oldKey = 変更前のキー。
	/// newKey = 変更後のキー。
	/// dup = 変更後の重複を許可するか。
	void change(K oldKey, K newKey, bool dup = false) {
		if (oldKey != newKey && (oldKey in _cont)) {
			if (newKey in _cont) {
				if (!dup) debugln(oldKey, " to ", newKey, " : ", _cont[newKey].size);
				foreach (val; _cont[oldKey]) {
					val.change(newKey);
					_cont[newKey].add(val);
				}
			} else {
				foreach (val; _cont[oldKey]) {
					val.change(newKey);
				}
				_cont[newKey] = _cont[oldKey];
			}
			_cont.remove(oldKey);
		}
	}
}

/// *Userのコンストラクタで指定したCWXPathが同時に
/// Chg*Callbackを実装する場合、change()が呼び出された
/// 際にコールバックを受ける事ができる。
interface TChgCallback(T) {
	void change(T, T);
}
/// ditto
alias TChgCallback!(FlagId) ChgFlagCallback;
/// ditto
alias TChgCallback!(StepId) ChgStepCallback;
/// ditto
alias TChgCallback!(PathId) ChgPathCallback;

/// フラグのID。
private struct FlagId {
	private string id;
	static FlagId opCall(string id) {
		FlagId r;
		r.id = id;
		return r;
	}
	string opCast() {
		return id;
	}
	const
	hash_t toHash() {
		hash_t hash = 0;
		foreach (c; cwx.utils.toLower(id)) {
			hash = (hash * 9) + c;
		}
		return hash;
	}
	const
	bool opEquals(ref const(FlagId) s) {
		return icmp(id, s.id) == 0;
	}
	const
	int opCmp(ref const(FlagId) s) {
		return icmp(this.id, s.id);
	}
	const
	string toString() {
		return id;
	}
}
/// 文字列をフラグIDに変換。
FlagId toFlagId(string id) {return FlagId(id);}
/// フラグの使用者。
interface IFlagUser : User!(FlagId) {
}
/// フラグを使用するクラスの雛形。
/// 継承か委譲により、フラグの使用者を容易に実装できる。
class FlagUser : IFlagUser {
private:
	UseCounter _uc;
	string _flag;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// フラグを設定する。
	/// Params:
	/// flag = フラグ。
	void flag(string flag) {
		if (_uc !is null) {
			if (_flag !is null) _uc.flag.remove(toFlagId(_flag), this);
			if (flag !is null) _uc.flag.add(toFlagId(flag), this);
		}
		_flag = flag;
	}

	/// Returns: フラグ。
	const
	string flag() {
		return _flag;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _flag) {
			uc.flag.add(toFlagId(_flag), this);
		}
		if (_uc && _flag) {
			_uc.flag.remove(toFlagId(_flag), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _flag !is null) {
			_uc.flag.remove(toFlagId(_flag), this);
		}
		_uc = null;
	}
	override void change(FlagId newVal) {
		if (cast(ChgFlagCallback) _cwxPath) {
			(cast(ChgFlagCallback) _cwxPath).change(toFlagId(_flag), newVal);
		}
		_flag = cast(string) newVal;
	}
}

/// ステップのID。
private struct StepId {
	private string id;
	static StepId opCall(string id) {
		StepId r;
		r.id = id;
		return r;
	}
	string opCast() {
		return id;
	}
	const
	hash_t toHash() {
		hash_t hash = 0;
		foreach (c; cwx.utils.toLower(id)) {
			hash = (hash * 9) + c;
		}
		return hash;
	}
	const
	bool opEquals(ref const(StepId) s) {
		return icmp(id, s.id) == 0;
	}
	const
	int opCmp(ref const(StepId) s) {
		return icmp(this.id, s.id);
	}
	const
	string toString() {
		return id;
	}
}
/// 文字列をステップIDに変換。
StepId toStepId(string id) {return StepId(id);}
/// ステップの使用者。
interface IStepUser : User!(StepId) {
}
/// ステップを使用するクラスの雛形。
/// 継承か委譲により、ステップの使用者を容易に実装できる。
class StepUser : IStepUser {
private:
	UseCounter _uc;
	string _step;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// ステップを設定する。
	/// Params:
	/// step = ステップ。
	void step(string step) {
		if (_uc !is null) {
			if (_step !is null) _uc.step.remove(toStepId(_step), this);
			if (step !is null) _uc.step.add(toStepId(step), this);
		}
		_step = step;
	}

	/// Returns: ステップ。
	const
	string step() {
		return _step;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _step) {
			uc.step.add(toStepId(_step), this);
		}
		if (_uc && _step) {
			_uc.step.remove(toStepId(_step), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _step !is null) {
			_uc.step.remove(toStepId(_step), this);
		}
		_uc = null;
	}
	override void change(StepId newVal) {
		if (cast(ChgStepCallback) _cwxPath) {
			(cast(ChgStepCallback) _cwxPath).change(toStepId(_step), newVal);
		}
		_step = cast(string) newVal;
	}
}

/// エリアのID。
typedef ulong AreaId;
/// 数値をエリアIDに変換。
AreaId toAreaId(ulong id) {return cast(AreaId) id;}
/// エリアの使用者。
interface IAreaUser : User!(AreaId) {
}
/// エリアを使用するクラスの雛形。
/// 継承か委譲により、エリアの使用者を容易に実装できる。
class AreaUser : IAreaUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// エリアIDを設定する。
	/// Params:
	/// id = エリアID。
	void area(ulong id) {
		if (_uc !is null) {
			if (_id > 0) _uc.area.remove(toAreaId(_id), this);
			if (id > 0) _uc.area.add(toAreaId(id), this);
		}
		_id = id;
	}

	/// Returns: エリアID。
	const
	ulong area() {
		return _id;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _id > 0) {
			uc.area.add(toAreaId(_id), this);
		}
		if (_uc && _id > 0) {
			_uc.area.remove(toAreaId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _id > 0) {
			_uc.area.remove(toAreaId(_id), this);
		}
		_uc = null;
	}
	override void change(AreaId newVal) {
		if (_handleChange) _handleChange(newVal);
		_id = newVal;
	}
	private void delegate(AreaId) _handleChange = null;
	/// change呼出しをdlgに通知する。
	void handleChange(void delegate(AreaId) dlg) {_handleChange = dlg;}
}

/// バトルのID。
typedef ulong BattleId;
/// 数値をバトルIDに変換。
BattleId toBattleId(ulong id) {return cast(BattleId) id;}
/// バトルの使用者。
interface IBattleUser : User!(BattleId) {
}
/// バトルを使用するクラスの雛形。
/// 継承か委譲により、バトルの使用者を容易に実装できる。
class BattleUser : IBattleUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// バトルIDを設定する。
	/// Params:
	/// id = バトルID。
	void battle(ulong id) {
		if (_uc !is null) {
			if (_id > 0) _uc.battle.remove(toBattleId(_id), this);
			if (id > 0) _uc.battle.add(toBattleId(id), this);
		}
		_id = id;
	}

	/// Returns: バトルID。
	const
	ulong battle() {
		return _id;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _id > 0) {
			uc.battle.add(toBattleId(_id), this);
		}
		if (_uc && _id > 0) {
			_uc.battle.remove(toBattleId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _id > 0) {
			_uc.battle.remove(toBattleId(_id), this);
		}
		_uc = null;
	}
	override void change(BattleId newVal) {
		if (_handleChange) _handleChange(newVal);
		_id = newVal;
	}
	private void delegate(BattleId) _handleChange = null;
	/// change呼出しをdlgに通知する。
	void handleChange(void delegate(BattleId) dlg) {_handleChange = dlg;}
}

/// パッケージのID。
typedef ulong PackageId;
/// 数値をパッケージIDに変換。
PackageId toPackageId(ulong id) {return cast(PackageId) id;}
/// パッケージの使用者。
interface IPackageUser : User!(PackageId) {
}
/// パッケージを使用するクラスの雛形。
/// 継承か委譲により、パッケージの使用者を容易に実装できる。
class PackageUser : IPackageUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// パッケージIDを設定する。
	/// Params:
	/// id = パッケージID。
	void packages(ulong id) {
		if (_uc !is null) {
			if (_id > 0) _uc.packages.remove(toPackageId(_id), this);
			if (id > 0) _uc.packages.add(toPackageId(id), this);
		}
		_id = id;
	}

	/// Returns: パッケージID。
	const
	ulong packages() {
		return _id;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _id > 0) {
			uc.packages.add(toPackageId(_id), this);
		}
		if (_uc && _id > 0) {
			_uc.packages.remove(toPackageId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _id > 0) {
			_uc.packages.remove(toPackageId(_id), this);
		}
		_uc = null;
	}

	override void change(PackageId newVal) {
		_id = newVal;
	}
}

/// ファイルパスのID。
struct PathId {
	private string id;
	private string binImg = "";
	static PathId opCall(string id) {
		PathId r;
		r.id = id;
		return r;
	}
	static PathId opCall(string id, string binImg) {
		PathId r;
		r.id = id;
		r.binImg = binImg;
		return r;
	}
	const
	bool isBinImg() {
		return binImg.length > 0u;
	}
	const
	bool valid() {
		return id.length || binImg.length;
	}
	const
	string opCast() {
		string id = this.id;
		return isBinImg ? binImg : replace(id, "/", sep);
	}
	const
	hash_t toHash() {
		hash_t hash = 0;
		string s;
		if (isBinImg) {
			s = binImg;
		} else {
			static if (0 == filenameCharCmp('A', 'a')) {
				s = cwx.utils.toLower(id);
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
	bool opEquals(ref const(PathId) s) {
		return (isBinImg || s.isBinImg) ? binImg == s.binImg : cfnmatch(this.id, s.id);
	}
	const
	int opCmp(ref const(PathId) s) {
		if (isBinImg && !s.isBinImg) return -1;
		if (!isBinImg && s.isBinImg) return 1;
		if (isBinImg || s.isBinImg) {
			foreach (i, char c; binImg) {
				if (c < s.binImg[i]) return -1;
				if (c > s.binImg[i]) return 1;
			}
			if (binImg.length < s.binImg.length) return -1;
			if (binImg.length > s.binImg.length) return 1;
			return 0;
		}
		static if (0 == filenameCharCmp('A', 'a')) {
			return std.string.icmp(this.id, s.id);
		} else {
			return std.string.cmp(this.id, s.id);
		}
	}
	const
	string toString() {
		string buf = "PathId {";
		if (isBinImg) {
			buf ~= "BinaryImage, hash: " ~ to!(string)(toHash);
		} else {
			buf ~= id;
		}
		buf ~= "}";
		return buf;
	}
}
/// 文字列をファイルパスIDに変換。
PathId toPathId(string id) {
	if (isBinImg(id)) {
		return PathId(BI_PATH_ID, id);
	} else {
		id = replace(id, sep, "/");
		static if (altsep.length) {
			id = replace(id, altsep, "/");
		}
		return PathId(id);
	}
}
/// ファイルパスの使用者。
interface IPathUser : User!(PathId) {
}
const BI_PATH_ID = "binaryimage://Binary:Image";
/// ファイルパスを使用するクラスの雛形。
/// 継承か委譲により、ファイルパスの使用者を容易に実装できる。
class PathUser : IPathUser {
private:
	UseCounter _uc;
	PathId _path;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// ファイルパスを設定する。
	void path(string path) {
		if (_uc !is null) {
			if (_path.valid) {
				_uc.path.remove(_path, this);
			}
			if (path.length) {
				_uc.path.add(toPathId(path), this);
			}
		}
		_path = toPathId(path);
	}

	/// ファイルパス。
	const
	string path() {return _path.isBinImg ? _path.binImg : cast(string) _path;}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _path.valid) {
			uc.path.add(_path, this);
		}
		if (_uc && _path.valid) {
			_uc.path.remove(_path, this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _path.valid) {
			_uc.path.remove(_path, this);
		}
		_uc = null;
	}

	override void change(PathId newVal) {
		if (cast(ChgPathCallback) _cwxPath) {
			(cast(ChgPathCallback) _cwxPath).change(_path, newVal);
		}
		_path = newVal;
	}
}

/// キャストカードのID。
typedef ulong CastId;
/// 数値をキャストIDに変換。
CastId toCastId(ulong id) {return cast(CastId) id;}
/// キャストカードの使用者。
interface ICastUser : User!(CastId) {
}
/// キャストを使用するクラスの雛形。
/// 継承か委譲により、キャストの使用者を容易に実装できる。
class CastUser : ICastUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// キャストIDを設定する。
	/// Params:
	/// id = キャストID。
	void casts(ulong id) {
		if (_uc !is null) {
			if (_id > 0) _uc.casts.remove(toCastId(_id), this);
			if (id > 0) _uc.casts.add(toCastId(id), this);
		}
		_id = id;
	}

	/// Returns: キャストID。
	const
	ulong casts() {
		return _id;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _id > 0) {
			uc.casts.add(toCastId(_id), this);
		}
		if (_uc && _id > 0) {
			_uc.casts.remove(toCastId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _id > 0) {
			_uc.casts.remove(toCastId(_id), this);
		}
		_uc = null;
	}

	override void change(CastId newVal) {
		_id = newVal;
	}
}
/// スキルカードのID。
typedef ulong SkillId;
/// 数値をスキルIDに変換。
SkillId toSkillId(ulong id) {return cast(SkillId) id;}
/// スキルカードの使用者。
interface ISkillUser : User!(SkillId) {
}
/// スキルを使用するクラスの雛形。
/// 継承か委譲により、スキルの使用者を容易に実装できる。
class SkillUser : ISkillUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// スキルIDを設定する。
	/// Params:
	/// id = スキルID。
	void skill(ulong id) {
		if (_uc !is null) {
			if (_id > 0) _uc.skill.remove(toSkillId(_id), this);
			if (id > 0) _uc.skill.add(toSkillId(id), this);
		}
		_id = id;
	}

	/// Returns: スキルID。
	const
	ulong skill() {
		return _id;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _id > 0) {
			uc.skill.add(toSkillId(_id), this);
		}
		if (_uc && _id > 0) {
			_uc.skill.remove(toSkillId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _id > 0) {
			_uc.skill.remove(toSkillId(_id), this);
		}
		_uc = null;
	}

	override void change(SkillId newVal) {
		_id = newVal;
	}
}
/// アイテムカードのID。
typedef ulong ItemId;
/// 数値をアイテムIDに変換。
ItemId toItemId(ulong id) {return cast(ItemId) id;}
/// アイテムカードの使用者。
interface IItemUser : User!(ItemId) {
}
/// アイテムを使用するクラスの雛形。
/// 継承か委譲により、アイテムの使用者を容易に実装できる。
class ItemUser : IItemUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// アイテムIDを設定する。
	/// Params:
	/// id = アイテムID。
	void item(ulong id) {
		if (_uc !is null) {
			if (_id > 0) _uc.item.remove(toItemId(_id), this);
			if (id > 0) _uc.item.add(toItemId(id), this);
		}
		_id = id;
	}

	/// Returns: アイテムID。
	const
	ulong item() {
		return _id;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _id > 0) {
			uc.item.add(toItemId(_id), this);
		}
		if (_uc && _id > 0) {
			_uc.item.remove(toItemId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _id > 0) {
			_uc.item.remove(toItemId(_id), this);
		}
		_uc = null;
	}

	override void change(ItemId newVal) {
		_id = newVal;
	}
}
/// 召喚獣カードのID。
typedef ulong BeastId;
/// 数値を召喚獣IDに変換。
BeastId toBeastId(ulong id) {return cast(BeastId) id;}
/// 召喚獣カードの使用者。
interface IBeastUser : User!(BeastId) {
}
/// 召喚獣を使用するクラスの雛形。
/// 継承か委譲により、召喚獣の使用者を容易に実装できる。
class BeastUser : IBeastUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// 召喚獣IDを設定する。
	/// Params:
	/// id = 召喚獣ID。
	void beast(ulong id) {
		if (_uc !is null) {
			if (_id > 0) _uc.beast.remove(toBeastId(_id), this);
			if (id > 0) _uc.beast.add(toBeastId(id), this);
		}
		_id = id;
	}

	/// Returns: 召喚獣ID。
	const
	ulong beast() {
		return _id;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _id > 0) {
			uc.beast.add(toBeastId(_id), this);
		}
		if (_uc && _id > 0) {
			_uc.beast.remove(toBeastId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _id > 0) {
			_uc.beast.remove(toBeastId(_id), this);
		}
		_uc = null;
	}

	override void change(BeastId newVal) {
		_id = newVal;
	}
}
/// 情報カードのID。
typedef ulong InfoId;
/// 数値を情報IDに変換。
InfoId toInfoId(ulong id) {return cast(InfoId) id;}
/// 情報カードの使用者。
interface IInfoUser : User!(InfoId) {
}
/// 情報カードを使用するクラスの雛形。
/// 継承か委譲により、情報カードの使用者を容易に実装できる。
class InfoUser : IInfoUser {
private:
	UseCounter _uc;
	ulong _id = 0;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) {_cwxPath = cwxPath;}
	/// このオブジェクトの所有者。
	CWXPath owner() {return _cwxPath;}
	/// このオブジェクトの所有者のリソースパス。
	string cwxPath() {return _cwxPath.cwxPath;}

	/// 情報カードIDを設定する。
	/// Params:
	/// id = 情報カードID。
	void info(ulong id) {
		if (_uc !is null) {
			if (_id > 0) _uc.info.remove(toInfoId(_id), this);
			if (id > 0) _uc.info.add(toInfoId(id), this);
		}
		_id = id;
	}

	/// Returns: 情報カードID。
	const
	ulong info() {
		return _id;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		if (uc && _id > 0) {
			uc.info.add(toInfoId(_id), this);
		}
		if (_uc && _id > 0) {
			_uc.info.remove(toInfoId(_id), this);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_uc && _id > 0) {
			_uc.info.remove(toInfoId(_id), this);
		}
		_uc = null;
	}

	override void change(InfoId newVal) {
		_id = newVal;
	}
}

/// 使用回数カウンタ。
/// IDやパスの変更を通知する役割も持つ。
class UseCounter {
private:
	UCCont!(FlagId, FlagUser) _flag;
	UCCont!(StepId, StepUser) _step;
	UCCont!(AreaId, AreaUser) _area;
	UCCont!(BattleId, BattleUser) _battle;
	UCCont!(PackageId, PackageUser) _package;
	UCCont!(PathId, PathUser) _path;
	UCCont!(CastId, CastUser) _cast;
	UCCont!(SkillId, SkillUser) _skill;
	UCCont!(ItemId, ItemUser) _item;
	UCCont!(BeastId, BeastUser) _beast;
	UCCont!(InfoId, InfoUser) _info;
	UseCounter _child = null;
public:
	/// 唯一のコンストラクタ。
	this () {
		this (true);
	}
	private this (bool useChild) {
		_flag = new UCCont!(FlagId, FlagUser);
		_step = new UCCont!(StepId, StepUser);
		_area = new UCCont!(AreaId, AreaUser);
		_battle = new UCCont!(BattleId, BattleUser);
		_package = new UCCont!(PackageId, PackageUser);
		_path = new UCCont!(PathId, PathUser);
		_cast = new UCCont!(CastId, CastUser);
		_skill = new  UCCont!(SkillId, SkillUser);
		_item = new UCCont!(ItemId, ItemUser);
		_beast = new UCCont!(BeastId, BeastUser);
		_info = new UCCont!(InfoId, InfoUser);
		if (useChild) {
			_child = new UseCounter(false);
		}
	}
	/// 「アンドゥリストの中にあるのでカウントはしないが、パスの更新は反映したい」
	/// 等の場合に使う。
	UseCounter sub() {
		return _child;
	}
	/// 各種カウント対象の使用者のコンテナ。
	UCCont!(FlagId, FlagUser) flag() {return _flag;}
	/// ditto
	UCCont!(StepId, StepUser) step() {return _step;}
	/// ditto
	UCCont!(AreaId, AreaUser) area() {return _area;}
	/// ditto
	UCCont!(BattleId, BattleUser) battle() {return _battle;}
	/// ditto
	UCCont!(PackageId, PackageUser) packages() {return _package;}
	/// ditto
	UCCont!(PathId, PathUser) path() {return _path;}
	/// ditto
	UCCont!(CastId, CastUser) casts() {return _cast;}
	/// ditto
	UCCont!(SkillId, SkillUser) skill() {return _skill;}
	/// ditto
	UCCont!(ItemId, ItemUser) item() {return _item;}
	/// ditto
	UCCont!(BeastId, BeastUser) beast() {return _beast;}
	/// ditto
	UCCont!(InfoId, InfoUser) info() {return _info;}
	/// ID・Tの変更を通知する。
	void change(T)(T oldId, T newId, bool dup = false) {
		static if (is (T == FlagId)) {
			flag.change(oldId, newId, dup);
		} else static if (is (T == StepId)) {
			step.change(oldId, newId, dup);
		} else static if (is (T == AreaId)) {
			area.change(oldId, newId, dup);
		} else static if (is (T == BattleId)) {
			battle.change(oldId, newId, dup);
		} else static if (is (T == PackageId)) {
			packages.change(oldId, newId, dup);
		} else static if (is (T == PathId)) {
			path.change(oldId, newId, dup);
		} else static if (is (T == CastId)) {
			casts.change(oldId, newId, dup);
		} else static if (is (T == SkillId)) {
			skill.change(oldId, newId, dup);
		} else static if (is (T == ItemId)) {
			item.change(oldId, newId, dup);
		} else static if (is (T == BeastId)) {
			beast.change(oldId, newId, dup);
		} else static if (is (T == InfoId)) {
			info.change(oldId, newId, dup);
		} else {
			static assert (0);
		}
		if (_child) _child.change(oldId, newId, dup);
	}
	/// ID・Tの使用回数を返す。
	const
	uint get(T)(T id) {
		static if (is (T == FlagId)) {
			return _flag.get(id);
		} else static if (is (T == StepId)) {
			return _step.get(id);
		} else static if (is (T == AreaId)) {
			return _area.get(id);
		} else static if (is (T == BattleId)) {
			return _battle.get(id);
		} else static if (is (T == PackageId)) {
			return _package.get(id);
		} else static if (is (T == PathId)) {
			return _path.get(id);
		} else static if (is (T == CastId)) {
			return _cast.get(id);
		} else static if (is (T == SkillId)) {
			return _skill.get(id);
		} else static if (is (T == ItemId)) {
			return _item.get(id);
		} else static if (is (T == BeastId)) {
			return _beast.get(id);
		} else static if (is (T == InfoId)) {
			return _info.get(id);
		} else {
			static assert (0);
		}
	}
	/// idの使用者一覧を返す。
	const
	FlagUser[] values(FlagId id) {return _flag.values(id);}
	const
	StepUser[] values(StepId id) {return _step.values(id);} /// ditto
	const
	AreaUser[] values(AreaId id) {return _area.values(id);} /// ditto
	const
	BattleUser[] values(BattleId id) {return _battle.values(id);} /// ditto
	const
	PackageUser[] values(PackageId id) {return _package.values(id);} /// ditto
	const
	PathUser[] values(PathId id) {return _path.values(id);} /// ditto
	const
	CastUser[] values(CastId id) {return _cast.values(id);} /// ditto
	const
	SkillUser[] values(SkillId id) {return _skill.values(id);} /// ditto
	const
	ItemUser[] values(ItemId id) {return _item.values(id);} /// ditto
	const
	BeastUser[] values(BeastId id) {return _beast.values(id);} /// ditto
	const
	InfoUser[] values(InfoId id) {return _info.values(id);} /// ditto
}

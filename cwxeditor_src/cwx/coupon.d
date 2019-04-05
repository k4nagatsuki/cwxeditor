
module cwx.coupon;

import cwx.xml;
import cwx.usecounter;
import cwx.path;
import cwx.utils;
import cwx.system;

import std.algorithm;
import std.array;
import std.conv;

/// クーポンの所有者。
interface CouponsOwner {
	@property
	inout
	inout(Coupon)[] coupons();
}

/// クーポン。
class Coupon : CWXPath {
private:
	CouponsOwner _owner = null;
	CouponUser _coupon;
	int _val;
public:
	static immutable XML_NAME = "Coupon";
	static immutable XML_NAME_M = "Coupons";

	/// 唯一のコンストラクタ。
	this (string name, int val) { mixin(S_TRACE);
		_coupon = new CouponUser(this);
		_coupon.coupon = name;
		_val = val;
	}
	/// コピーコンストラクタ。
	this (in Coupon c) { mixin(S_TRACE);
		_coupon = new CouponUser(this);
		_coupon.coupon = c.coupon;
		_val = c.value;
	}

	/// コピーを生成する。
	@property
	const
	Coupon dup() { return new Coupon(this); }

	@property
	package void owner(CouponsOwner owner) { mixin(S_TRACE);
		_owner = owner;
		if (auto u = cast(CWXPath)owner) { mixin(S_TRACE);
			_coupon.owner = u;
		} else { mixin(S_TRACE);
			_coupon.owner = this;
		}
	}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() { mixin(S_TRACE);
		return _coupon.useCounter;
	}
	/// 使用回数カウンタを登録する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		_coupon.setUseCounter(uc);
	}
	/// 使用回数カウンタを取り除く。
	void removeUseCounter() { mixin(S_TRACE);
		_coupon.removeUseCounter();
	}
	/// クーポン名の変更を通知する。
	bool change(CouponId id) { mixin(S_TRACE);
		return _coupon.change(id);
	}

	override void changed() { }

	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		auto owner = cast(CWXPath) _owner;
		return owner ? cpjoin(owner, "coupon", .cCountUntil!("a is b")(_owner.coupons, this), id) : "";
	}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() {return [];}
	@property
	CWXPath cwxParent() {return cast(CWXPath) _owner;}

	/// クーポン名。
	@property
	const
	string coupon() { mixin(S_TRACE);
		return _coupon.coupon;
	}
	/// ditto
	alias coupon name;
	/// 値。
	@property
	const
	int value() { mixin(S_TRACE);
		return _val;
	}
	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(Coupon) o;
		return c && c.coupon == coupon && c.value == value;
	}

	/// XMLノードからインスタンスを生成する。
	static Coupon fromNode(in XNode node, in XMLInfo ver) { mixin(S_TRACE);
		assert (node.name == Coupon.XML_NAME, node.name ~ " != Coupon");
		return new Coupon(node.value, node.attr!(int)("value", true));
	}
	/// 自身をXMLノードにする。
	const
	XNode toNode() { mixin(S_TRACE);
		auto node = XNode.create(Coupon.XML_NAME, coupon);
		node.newAttr("value", value);
		return node;
	}
	/// ditto
	const
	XNode toNode(ref XNode parent) { mixin(S_TRACE);
		auto node = parent.newElement(Coupon.XML_NAME, coupon);
		node.newAttr("value", value);
		return node;
	}
	const
	override string toString() { mixin(S_TRACE);
		return coupon ~ " (" ~ (value >= 0 ? "+" : "") ~ to!(string)(value) ~ ")";
	}
}

/// 一揃いのクーポン名の保持者の親クラス。
class CouponNamesUser {
private:
	CouponUser[] _coupons;
	bool _expandSPChars = false;
	void delegate() _change = null;
	UseCounter _uc = null;
	CWXPath _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (CWXPath cwxPath) { _cwxPath = cwxPath; }
	@property
	string cwxPath(bool id) { return _cwxPath.cwxPath(id); }

	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		_change = change;
	}
	/// 変更ハンドラ。
	private void changed() { mixin(S_TRACE);
		if (_change) _change();
	}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (u; _coupons) { mixin(S_TRACE);
			u.setUseCounter(uc);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		foreach (u; _coupons) { mixin(S_TRACE);
			u.removeUseCounter();
		}
		_uc = null;
	}
	/// クーポン群。
	@property
	void couponNames(string[] coupons) { mixin(S_TRACE);
		if (this.couponNames != coupons) { mixin(S_TRACE);
			changed();
			foreach (u; _coupons) { mixin(S_TRACE);
				u.removeUseCounter();
			}
			_coupons = [];
			foreach (coupon; coupons) { mixin(S_TRACE);
				if (coupon == "") continue;
				auto u = new CouponUser(_cwxPath);
				u.expandSPChars = expandSPChars;
				u.coupon = coupon;
				if (_uc) u.setUseCounter(_uc);
				_coupons ~= u;
			}
		}
	}
	/// ditto
	@property
	inout
	inout(string)[] couponNames() { mixin(S_TRACE);
		string[] couponNames;
		foreach (u; _coupons) couponNames ~= u.coupon;
		return cast(inout)couponNames;
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
			foreach (coupon; _coupons) { mixin(S_TRACE);
				coupon.expandSPChars = val;
			}
		}
	}

	/// クーポン内で使用されている状態変数のパス。
	@property
	const
	string[] flagsInText() { return .map!(u => u.flagsInText)(_coupons).join(); }
	/// ditto
	@property
	const
	string[] stepsInText() { return .map!(u => u.stepsInText)(_coupons).join(); }
	/// ditto
	@property
	const
	string[] variantsInText() { return .map!(u => u.variantsInText)(_coupons).join(); }
}

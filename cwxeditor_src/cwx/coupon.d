
module cwx.coupon;

import cwx.xml;
import cwx.usecounter;
import cwx.path;
import cwx.utils;
import cwx.system;

import std.conv;

/// クーポンの所有者。
interface CouponsOwner {
	@property
	inout
	inout(Coupon)[] coupons();
}

/// クーポン。
class Coupon : ICouponUser, CWXPath {
private:
	CouponsOwner _owner = null;
	CouponUser _coupon;
	int _val;
public:
	static const XML_NAME = "Coupon";

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

	@property
	package void owner(CouponsOwner owner) {_owner = owner;}

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
	void change(CouponId id) { mixin(S_TRACE);
		_coupon.change(id);
	}

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
	const
	bool opEquals(ref const(Object) o) { mixin(S_TRACE);
		auto c = cast(Coupon) o;
		return c && c.coupon == coupon && c.value == value;
	}

	/// XMLノードからインスタンスを生成する。
	static Coupon fromNode(in XNode node, in XMLInfo ver) { mixin(S_TRACE);
		assert (node.name == "Coupon", node.name ~ " != Coupon");
		return new Coupon(node.value, node.attr!(int)("value", true));
	}
	/// 自身をXMLノードにする。
	const
	XNode toNode() { mixin(S_TRACE);
		auto node = XNode.create("Coupon", coupon);
		node.newAttr("value", value);
		return node;
	}
	/// ditto
	const
	XNode toNode(ref XNode parent) { mixin(S_TRACE);
		auto node = parent.newElement("Coupon", coupon);
		node.newAttr("value", value);
		return node;
	}
	const
	override string toString() { mixin(S_TRACE);
		return coupon ~ " (" ~ (value >= 0 ? "+" : "") ~ to!(string)(value) ~ ")";
	}
}


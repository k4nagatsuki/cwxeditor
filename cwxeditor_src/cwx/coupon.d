
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
	const
	const(Coupon)[] coupons();
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
	this (string name, int val) {
		_coupon = new CouponUser(this);
		_coupon.coupon = name;
		_val = val;
	}
	/// コピーコンストラクタ。
	this (in Coupon c) {
		_coupon = new CouponUser(this);
		_coupon.coupon = c.coupon;
		_val = c.value;
	}

	@property
	package void owner(CouponsOwner owner) {_owner = owner;}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() {
		return _coupon.useCounter;
	}
	/// 使用回数カウンタを登録する。
	@property
	void setUseCounter(UseCounter uc) {
		_coupon.setUseCounter(uc);
	}
	/// 使用回数カウンタを取り除く。
	void removeUseCounter() {
		_coupon.removeUseCounter();
	}
	/// クーポン名の変更を通知する。
	void change(CouponId id) {
		_coupon.change(id);
	}

	@property
	string cwxPath(bool id) {
		auto owner = cast(CWXPath) _owner;
		return owner ? cpjoin(owner, "coupon", .cCountUntil!("a is b")(_owner.coupons, this), id) : "";
	}
	override CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		return null;
	}
	@property
	const
	const(CWXPath)[] cwxChilds() {return [];}
	@property
	CWXPath cwxParent() {return cast(CWXPath) _owner;}

	/// クーポン名。
	@property
	const
	string coupon() {
		return _coupon.coupon;
	}
	/// ditto
	alias coupon name;
	/// 値。
	@property
	const
	int value() {
		return _val;
	}
	const
	bool opEquals(ref const(Object) o) {
		auto c = cast(Coupon) o;
		return c && c.coupon == coupon && c.value == value;
	}

	/// XMLノードからインスタンスを生成する。
	static Coupon fromNode(in XNode node, in XMLInfo ver) {
		assert (node.name == "Coupon", node.name ~ " != Coupon");
		return new Coupon(node.value, node.attr!(int)("value", true));
	}
	/// 自身をXMLノードにする。
	const
	XNode toNode() {
		auto node = XNode.create("Coupon", coupon);
		node.newAttr("value", value);
		return node;
	}
	/// ditto
	const
	XNode toNode(ref XNode parent) {
		auto node = parent.newElement("Coupon", coupon);
		node.newAttr("value", value);
		return node;
	}
	const
	override string toString() {
		return coupon ~ " (" ~ (value >= 0 ? "+" : "") ~ to!(string)(value) ~ ")";
	}
}


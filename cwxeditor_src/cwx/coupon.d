
module cwx.coupon;

import cwx.utils;
import cwx.xml;

/// クーポン。
class Coupon {
private:
	string _name;
	int _val;
public:
	static const XML_NAME = "Coupon";

	/// 唯一のコンストラクタ。
	this(string name, int val) {
		_name = name;
		_val = val;
	}
	/// クーポン名。
	const
	string name() {
		return _name;
	}
	/// 値。
	const
	int value() {
		return _val;
	}
	const
	bool opEquals(ref const(Object) o) {
		auto c = cast(Coupon) o;
		return c && c.name == name && c.value == value;
	}

	/// XMLノードからインスタンスを生成する。
	static Coupon fromNode(in XNode node, string ver) {
		assert (node.name == "Coupon", node.name ~ " != Coupon");
		return new Coupon(node.value, node.attr!(int)("value", true));
	}
	/// 自身をXMLノードにする。
	const
	XNode toNode() {
		auto node = XNode.create("Coupon", name);
		node.newAttr("value", value);
		return node;
	}
	/// ditto
	const
	XNode toNode(ref XNode parent) {
		auto node = parent.newElement("Coupon", name);
		node.newAttr("value", value);
		return node;
	}
	const
	override string toString() {
		return _name ~ " (" ~ (value >= 0 ? "+" : "") ~ to!(string)(value) ~ ")";
	}
}


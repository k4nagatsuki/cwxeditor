
module cwx.structs;

import cwx.xml;

/// 座標を表す。
struct CPoint {
	int x;
	int y;
	void toNode(ref XNode e) {
		auto r = e.newElement("point");
		r.newAttr("x", x);
		r.newAttr("y", y);
	}
	void fromNode(ref XNode node) {
		if (node.name != "point") throw new Exception("Node is not point");
		x = node.attr!(int)("x", true);
		y = node.attr!(int)("y", true);
	}
}

/// サイズを表す。
struct CSize {
	uint width;
	uint height;
	void toNode(ref XNode e) {
		auto r = e.newElement("size");
		r.newAttr("width", width);
		r.newAttr("height", height);
	}
	void fromNode(ref XNode node) {
		if (node.name != "size") throw new Exception("Node is not size");
		width = node.attr!(uint)("width", true);
		height = node.attr!(uint)("height", true);
	}
}

/// 矩形範囲を表す。
struct CRect {
	int x;
	int y;
	int width;
	int height;
	void toNode(ref XNode e) {
		auto r = e.newElement("rect");
		r.newAttr("x", x);
		r.newAttr("y", y);
		r.newAttr("width", width);
		r.newAttr("height", height);
	}
	void fromNode(ref XNode node) {
		if (node.name != "rect") throw new Exception("Node is not rect");
		x = node.attr!(int)("x", true);
		y = node.attr!(int)("y", true);
		width = node.attr!(int)("width", true);
		height = node.attr!(int)("height", true);
	}
}

/// 上下左右の値を持つ。
struct CInsets {
	int n; /// 上。
	int e; /// 右。
	int s; /// 下。
	int w; /// 左。
	void toNode(ref XNode e) {
		auto r = e.newElement("insets");
		r.newAttr("n", n);
		r.newAttr("e", this.e);
		r.newAttr("s", s);
		r.newAttr("w", w);
	}
	void fromNode(ref XNode node) {
		if (node.name != "insets") throw new Exception("Node is not insets");
		n = node.attr!(int)("n", true);
		e = node.attr!(int)("e", true);
		s = node.attr!(int)("s", true);
		w = node.attr!(int)("w", true);
	}
}

/// RGB色情報。
struct CRGB {
	uint r;
	uint g;
	uint b;
	uint a = 255;
	void toNode(ref XNode e) {
		auto r = e.newElement("rgb");
		r.newAttr("r", this.r);
		r.newAttr("g", g);
		r.newAttr("b", b);
		r.newAttr("a", a);
	}
	void fromNode(ref XNode node) {
		if (node.name != "rgb") throw new Exception("Node is not rgb");
		r = node.attr!(uint)("r", true);
		g = node.attr!(uint)("g", true);
		b = node.attr!(uint)("b", true);
		a = node.attr!(uint)("a", true);
	}
}

/// フォント情報。
struct CFont {
	string name;
	uint point;
	bool bold;
	bool italic;
	void toNode(ref XNode e) {
		auto r = e.newElement("font");
		r.newAttr("name", name);
		r.newAttr("point", point);
		r.newAttr("bold", bold);
		r.newAttr("italic", italic);
	}
	void fromNode(ref XNode node) {
		if (node.name != "font") throw new Exception("Node is not font");
		name = node.attr!(string)("name", true);
		point = node.attr!(uint)("point", true);
		bold = node.attr!(bool)("bold", true);
		italic = node.attr!(bool)("italic", true);
	}
}


module cwx.structs;

import std.compat;

/// 座標を表す。
struct CPoint {
	int x;
	int y;
}

/// サイズを表す。
struct CSize {
	uint width;
	uint height;
}

/// 矩形範囲を表す。
struct CRect {
	int x;
	int y;
	int width;
	int height;
}

/// 上下左右の値を持つ。
struct CInsets {
	int n; /// 上。
	int e; /// 右。
	int s; /// 下。
	int w; /// 左。
}

/// RGB色情報。
struct CRGB {
	uint r;
	uint g;
	uint b;
	uint a = 255;
}

/// フォント情報。
struct CFont {
	string name;
	uint point;
	bool bold;
	bool italic;
}


module cwx.background;

import cwx.usecounter;
import cwx.utils;
import cwx.xml;
import cwx.path;

/// エリア絡みの例外。
public class AreaException : Exception {
public:
	this(string msg) {
		super(msg);
	}
}

/// 背景イメージ。
public class BgImage : FlagUser, CWXPath, IPathUser {
private:
	bool _mask = false;
	PathUser _user;
	int _x, _y;
	int _w, _h;
	void delegate() _change;
public:
	const
	bool opEquals(ref const(Object) o) {
		auto b = cast(BgImage) o;
		return b && mask == b.mask && path == b.path
			&& x == b.x && y == b.y && width == b.width && height == b.height;
	}
	/// 唯一のコンストラクタ。
	/// Params:
	/// path = ファイルパス。無しの場合は""。
	/// flag = フラグ。無しの場合は""。
	/// x = X座標。
	/// y = Y座標。
	/// w = 幅。
	/// h = 高さ。
	/// mask = 透明色を使用するか。
	this (string path, string flag, int x, int y, int w, int h, bool mask) {
		super (this);
		_user = new PathUser(this);
		_user.path = path;
		super.flag = flag;
		_x = x;
		_y = y;
		_w = w;
		_h = h;
		_mask = mask;
	}
	/// コピーを生成する。
	const
	BgImage dup() {
		return new BgImage(path, flag, x, y, width, height, mask);
	}
	/// 変更ハンドラを登録する。
	void changeHandler(void delegate() change) {
		_change = change;
	}
	/// 変更を通知。
	protected void changed() {
		if (_change) _change();
	}

	/// 透明色を使用するか。
	const
	bool mask() {
		return _mask;
	}
	/// ditto
	void mask(bool mask) {
		if (_mask != mask) changed;
		_mask = mask;
	}
	/// X座標。
	const
	int x() {
		return _x;
	}
	/// ditto
	void x(int x) {
		if (_x != x) changed;
		_x = x;
	}
	/// Y座標。
	const
	int y() {
		return _y;
	}
	/// ditto
	void y(int y) {
		if (_y != y) changed;
		_y = y;
	}

	/// 幅。
	const
	int width() {
		return _w;
	}
	/// ditto
	void width(int w) {
		if (w < 0) w = 0;
		if (_w != w) changed;
		_w = w;
	}
	/// 高さ。
	const
	int height() {
		return _h;
	}
	/// ditto
	void height(int h) {
		if (h < 0) h = 0;
		if (_h != h) changed;
		_h = h;
	}
	/// 画像ファイルパス。
	const
	string path() {
		return _user.path;
	}
	/// ditto
	void path(string path) {
		if (_user.path != path) changed;
		_user.path = path;
	}

	override void setUseCounter(UseCounter uc) {
		_user.setUseCounter(uc);
		super.setUseCounter(uc);
	}
	override void removeUseCounter() {
		_user.removeUseCounter;
		super.removeUseCounter;
	}
	override void change(FlagId id) {
		super.change(id);
	}
	override void change(PathId id) {
		_user.change(id);
	}

	static BgImage[] bgImagesFromNode(ref XNode node, string ver) {
		assert (node.name == "BgImages");
		BgImage[] bgImgs;
		node.onTag["BgImage"] = (ref XNode bgn) {
			auto bg = BgImage.createFromNode(bgn, ver);
			if (bg.path.length > 0) {
				bgImgs ~= bg;
			}
		};
		node.parse;
		return bgImgs;
	}

	/// 指定されたノードに背景イメージ群のデータを追加する。
	static void toNode(in BgImage[] bgImgs, ref XNode e) {
		auto bge = e.newElement("BgImages");
		if (bgImgs.length > 0) {
			// FIXME: このサイズはCPropsに持たせているがコンパイラのバグで参照できない。暫定。
			if (bgImgs[0].width != 632 || bgImgs[0].height != 420) {
				BgImage.appendEmptyToNode(bge);
			}
			foreach (bg; bgImgs) {
				bg.toNode(bge);
			}
		} else {
			BgImage.appendEmptyToNode(bge);
		}
	}

	/// XMLノード(BgImages)にインスタンスのデータを追加する。
	const
	void toNode(ref XNode node) {
		assert (node.name == "BgImages", node.name ~ " != BgImages");
		auto e = node.newElement("BgImage");
		e.newAttr("mask", fromBool(_mask));
		e.newElement("ImagePath", encodePath(_user.path));
		e.newElement("Flag", super.flag);
		auto ln = e.newElement("Location");
		ln.newAttr("left", _x);
		ln.newAttr("top", _y);
		auto sn = e.newElement("Size");
		sn.newAttr("width", _w);
		sn.newAttr("height", _h);
	}
	/// 背景イメージが一枚も無い場合。
	static void appendEmptyToNode(ref XNode node) {
		assert (node.name == "BgImages", node.name ~ " != BgImages");
		auto e = node.newElement("BgImage");
		e.newAttr("mask", "False");
		e.newElement("ImagePath");
		e.newElement("Flag");
		auto ln = e.newElement("Location");
		ln.newAttr("left", 0);
		ln.newAttr("top", 0);
		auto sn = e.newElement("Size"); // FIXME: このサイズはCPropsに持たせているがコンパイラのバグで参照できない。暫定。
		sn.newAttr("width", "632");
		sn.newAttr("height", "420");
	}

	static BgImage createFromNode(ref XNode node, string ver) {
		if (node.name != "BgImage") throw new AreaException("Node is not BgImage");
		bool mask = parseBool(node.attr("mask", true));
		string path = "";
		string flag = "";
		int x = 0, y = 0;
		int w = 0, h = 0;
		node.onTag["ImagePath"] = (ref XNode n) {
			path = decodePath(n.value);
		};
		node.onTag["Flag"] = (ref XNode n) {
			flag = n.value;
		};
		node.onTag["Location"] = (ref XNode n) {
			x = n.attr!(int)("left", true);
			y = n.attr!(int)("top", true);
		};
		node.onTag["Size"] = (ref XNode n) {
			w = n.attr!(int)("width", true);
			h = n.attr!(int)("height", true);
		};
		node.parse;
		return new BgImage(path, flag, x, y, w, h, mask);
	}
	private BgImageOwner _owner;
	package void owner(BgImageOwner owner) {_owner = owner;}
	override string cwxPath() {
		return _owner ? cpjoin(_owner, "background", .cCountUntil!("a is b")(_owner.backs, this)) : "";
	}
	override CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		return null;
	}
	CWXPath[] cwxChilds() {return [];}
}

/// BgImage所持者のインタフェース。
interface BgImageOwner : CWXPath {
	BgImage[] backs();
	const const(BgImage)[] backs();
}

/// BgImageのコンテナ。背景変更イベントで使用。
class BgImageContainer : BgImageOwner {
private:
	BgImage[] _bgImgs;
public:
	/// 唯一のコンストラクタ。
	this(BgImage[] bgImgs) {
		_bgImgs = bgImgs;
	}
	override string cwxPath() {return "";}
	override CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "background": {
			auto index = cpindex(path);
			if (index >= _bgImgs.length) return null;
			return _bgImgs[index].findCWXPath(cpbottom(path));
		}
		default: break;
		}
		return null;
	}
	CWXPath[] cwxChilds() {
		CWXPath[] r;
		r ~= cast(CWXPath[]) backs;
		return r;
	}
	/// 背景イメージ群。
	BgImage[] backs() {
		return _bgImgs;
	}
	/// ditto
	const
	const(BgImage)[] backs() {
		return _bgImgs;
	}
	/// ditto
	void backs(BgImage[] bgImgs) {
		foreach (b; _bgImgs) {
			b.owner = null;
		}
		foreach (b; bgImgs) {
			b.owner = this;
		}
		_bgImgs = bgImgs;
	}
	/// 背景イメージを追加。
	void append(BgImage back) {
		back.owner = this;
		_bgImgs ~= back;
	}
	/// ditto
	void insert(int index, BgImage back) {
		if (_bgImgs.length == index) {
			append(back);
		} else {
			back.owner = this;
			_bgImgs = _bgImgs[0 .. index] ~ back ~ _bgImgs[index .. $];
		}
	}
	/// 背景イメージを除外。
	void removeBgImage(int index) {
		_bgImgs[index].owner = null;
		_bgImgs = _bgImgs[0 .. index] ~ _bgImgs[index + 1 .. $];
	}
	/// 背景イメージのインデックスを交換。
	void swapBacks(int index1, int index2) {
		auto temp = _bgImgs[index1];
		_bgImgs[index1] = _bgImgs[index2];
		_bgImgs[index2] = temp;
	}
	/// 背景イメージ群をXMLノードにする。
	static string BtoXML(BgImage[] backs) {
		scope doc = XNode.create("MenuCardsAndBgImages");
		if (backs.length) {
			auto be = doc.newElement("BgImages");
			foreach (b; backs) {
				b.toNode(be);
			}
		}
		return doc.text;
	}
	/// XMLノードから背景イメージ群を読み出す。
	static bool BfromXML(string xml, out BgImage[] backs) {
		try {
			scope doc = XNode.parse(xml);
			if (doc.name == "MenuCardsAndBgImages") {
				doc.onTag["BgImages"] = (ref XNode node) {
					node.onTag["BgImage"] = (ref XNode n) {
						backs ~= BgImage.createFromNode(n, LATEST_VERSION);
					};
					node.parse;
				};
				doc.parse;
				return true;
			}
		} catch (Exception e) {
		}
		return false;
	}
}

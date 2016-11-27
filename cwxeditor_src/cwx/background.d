
module cwx.background;

import cwx.usecounter;
import cwx.utils;
import cwx.xml;
import cwx.path;
import cwx.structs;
import cwx.types;
import cwx.textholder;
import cwx.card;
import cwx.system;
import cwx.props;

import std.path;
import std.string;
import std.conv;

/// エリア絡みの例外。
public class AreaException : Exception {
public:
	this(string msg) { mixin(S_TRACE);
		super(msg);
	}
}

/// 背景イメージ。
public class ImageCell : BgImage, IPathUser {
private:
	PathUser _user;
	Smoothing _smoothing = Smoothing.Default;
public:
	/// XML要素名。
	static immutable XML_NAME = "BgImage";

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto b = cast(ImageCell) o;
		return b
			&& path == b.path
			&& smoothing == b.smoothing
			&& super.opEquals(o);
	}

	/// 空のインスタンスを生成する。
	this () { mixin(S_TRACE);
		this ("", "", 0, 0, 0, 0, false);
	}

	/// パラメータを指定してインスタンスを生成する。
	/// Params:
	/// path = ファイルパス。無しの場合は""。
	/// flag = フラグ。無しの場合は""。
	/// x = X座標。
	/// y = Y座標。
	/// w = 幅。
	/// h = 高さ。
	/// mask = 透明色を使用するか。
	this (string path, string flag, int x, int y, int w, int h, bool mask) { mixin(S_TRACE);
		super (flag, x, y, w, h, mask);
		_user = new PathUser(this);
		_user.path = path;
	}

	@property
	const
	override
	string name(in CProps prop) { mixin(S_TRACE);
		string s = path == "" ? prop.msgs.noSelectImage : (isBinImg(path) ? prop.msgs.defaultSelection(prop.msgs.imageIncluding) : baseName(path));
		if (cellName == "") { mixin(S_TRACE);
			return s;
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.nameWithCellName, cellName, s);
		}
	}

	@property
	const
	override
	BgImage dup() { mixin(S_TRACE);
		auto cell = new ImageCell(path, flag, x, y, width, height, mask);
		dupImpl(cell);
		cell.smoothing = smoothing;
		return cell;
	}

	/// 画像ファイルパス。
	@property
	const
	string path() { mixin(S_TRACE);
		return _user.path;
	}
	/// ditto
	@property
	void path(string path) { mixin(S_TRACE);
		if (_user.path != path) changed();
		_user.path = path;
	}

	/// 拡大・縮小時のスムージングの設定(Wsn.2)。
	@property
	const
	Smoothing smoothing() { return _smoothing; }
	/// ditto
	@property
	void smoothing(Smoothing v) { mixin(S_TRACE);
		if (_smoothing != v) changed();
		_smoothing = v;
	}

	@property
	override
	const
	string connectedFile() { mixin(S_TRACE);
		return path.isBinImg ? "" : path;
	}

	@property
	override void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		_user.setUseCounter(uc);
		super.setUseCounter(uc);
	}
	override void removeUseCounter() { mixin(S_TRACE);
		_user.removeUseCounter();
		super.removeUseCounter();
	}
	override bool change(PathId id) { mixin(S_TRACE);
		return _user.change(id);
	}

	override
	const
	void toNode(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		assert (node.name == XML_NAME_M, node.name ~ " != BgImages");
		auto e = node.newElement(XML_NAME);
		e.newElement("ImagePath", encodePath(_user.path));
		e.newAttr("smoothing", fromSmoothing(smoothing));
		toNodeCommon(e, true);
	}
	static ImageCell createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		if (node.name != XML_NAME) throw new AreaException("Node is not BgImage");
		string path;
		node.onTag["ImagePath"] = (ref XNode n) { mixin(S_TRACE);
			path = decodePath(n.value);
		};
		node.parse();
		auto r = new ImageCell(path, "", 0, 0, 0, 0, false);
		r.fromNodeCommon(node);
		r.smoothing = toSmoothing(node.attr("smoothing", false, "Default"));
		return r;
	}
}

/// テキストセル(CardWirth 1.50)。
public class TextCell : BgImage, ISimpleTextHolder {
private:
	SimpleTextHolder _text = null;
	string _fontName = "";
	uint _size = 18;
	CRGB _color = CRGB(0, 0, 0, 255);
	bool _bold = false;
	bool _italic = false;
	bool _underline = false;
	bool _strike = false;
	bool _vertical = false;
	BorderingType _borderingType = BorderingType.None;
	CRGB _borderingColor = CRGB(255, 255, 255, 255);
	uint _borderingWidth = 1;
public:
	/// XML要素名。
	static immutable XML_NAME = "TextCell";

	/// 空のインスタンスを生成する。
	this () { mixin(S_TRACE);
		super ("", 0, 0, 0, 0, false);
		_text = new SimpleTextHolder;
		_text.owner = this;
	}

	/// パラメータを指定してインスタンスを生成する。
	this (string text, string fontName, uint size, CRGB color,
			bool bold, bool italic, bool underline, bool strike, bool vertical,
			BorderingType borderingType, CRGB borderingColor, uint borderingWidth,
			string flag, int x, int y, int w, int h, bool mask) { mixin(S_TRACE);
		super (flag, x, y, w, h, mask);
		_text = new SimpleTextHolder;
		_text.text = text;
		_text.owner = this;
		_fontName = fontName;
		_size = size;
		_color = color;
		_bold = bold;
		_italic = italic;
		_underline = underline;
		_strike = strike;
		_vertical = vertical;
		_borderingType = borderingType;
		_borderingColor = borderingColor;
		_borderingWidth = borderingWidth;
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto b = cast(TextCell) o;
		return b
			&& text == b.text
			&& fontName == b.fontName
			&& size == b.size
			&& color == b.color
			&& bold == b.bold
			&& italic == b.italic
			&& underline == b.underline
			&& strike == b.strike
			&& vertical == b.vertical
			&& borderingType == b.borderingType
			&& borderingColor == b.borderingColor
			&& borderingWidth == b.borderingWidth
			&& super.opEquals(o);
	}

	@property
	const
	override
	string name(in CProps prop) { mixin(S_TRACE);
		if (cellName == "") { mixin(S_TRACE);
			return text.singleLine;
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.nameWithCellName, cellName, text.singleLine);
		}
	}

	@property
	const
	override
	BgImage dup() { mixin(S_TRACE);
		auto cell = new TextCell(text, fontName, size, color, bold, italic, underline, strike, vertical,
			borderingType, borderingColor, borderingWidth, flag, x, y, width, height, mask);
		dupImpl(cell);
		return cell;
	}

	// テキスト。
	@property
	const
	string text() { return _text.text; }
	@property
	void text(string value) { mixin(S_TRACE);
		if (_text.text != value) { mixin(S_TRACE);
			changed();
			_text.text = value;
		}
	}

	// フォント名。
	@property
	const
	string fontName() { return _fontName; }
	@property
	void fontName(string value) { mixin(S_TRACE);
		if (_fontName != value) { mixin(S_TRACE);
			changed();
			_fontName = value;
		}
	}
	// フォントサイズ。
	@property
	const
	uint size() { return _size; }
	@property
	void size(uint value) { mixin(S_TRACE);
		if (_size != value) { mixin(S_TRACE);
			changed();
			_size = value;
		}
	}

	// 色。
	@property
	const
	CRGB color() { return _color; }
	@property
	void color(CRGB value) { mixin(S_TRACE);
		if (_color != value) { mixin(S_TRACE);
			changed();
			_color = value;
		}
	}

	// 太字。
	@property
	const
	bool bold() { return _bold; }
	@property
	void bold(bool value) { mixin(S_TRACE);
		if (_bold != value) { mixin(S_TRACE);
			changed();
			_bold = value;
		}
	}
	// 斜体。
	@property
	const
	bool italic() { return _italic; }
	@property
	void italic(bool value) { mixin(S_TRACE);
		if (_italic != value) { mixin(S_TRACE);
			changed();
			_italic = value;
		}
	}
	// 下線。
	@property
	const
	bool underline() { return _underline; }
	@property
	void underline(bool value) { mixin(S_TRACE);
		if (_underline != value) { mixin(S_TRACE);
			changed();
			_underline = value;
		}
	}
	// 取消線。
	@property
	const
	bool strike() { return _strike; }
	@property
	void strike(bool value) { mixin(S_TRACE);
		if (_strike != value) { mixin(S_TRACE);
			changed();
			_strike = value;
		}
	}
	// 縦書き。
	@property
	const
	bool vertical() { return _vertical; }
	@property
	void vertical(bool value) { mixin(S_TRACE);
		if (_vertical != value) { mixin(S_TRACE);
			changed();
			_vertical = value;
		}
	}

	// 縁取り方式。
	@property
	const
	BorderingType borderingType() { return _borderingType; }
	@property
	void borderingType(BorderingType value) { mixin(S_TRACE);
		if (_borderingType != value) { mixin(S_TRACE);
			changed();
			_borderingType = value;
		}
	}
	// 縁取り色。
	@property
	const
	CRGB borderingColor() { return _borderingColor; }
	@property
	void borderingColor(CRGB value) { mixin(S_TRACE);
		if (_borderingColor != value) { mixin(S_TRACE);
			changed();
			_borderingColor = value;
		}
	}
	// 縁取り幅。
	@property
	const
	uint borderingWidth() { return _borderingWidth; }
	@property
	void borderingWidth(uint value) { mixin(S_TRACE);
		if (_borderingWidth != value) { mixin(S_TRACE);
			changed();
			_borderingWidth = value;
		}
	}

	// テキスト内で使用されているフラグのパス。
	@property
	const
	override string[] flagsInText() { return _text.flagsInText; }
	// テキスト内で使用されているステップのパス。
	@property
	const
	override string[] stepsInText() { return _text.stepsInText; }

	/// テキスト内のフラグ・ステップを置換する。
	override void changeInText(size_t index, FlagId id) { _text.change(index, id); }
	/// ditto
	override void changeInText(size_t index, StepId id) { _text.change(index, id); }

	override
	const
	void toNode(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		assert (node.name == XML_NAME_M, node.name ~ " != BgImages");
		auto e = node.newElement(XML_NAME);

		e.newElement("Text", .encodeLf(text));
		auto font = e.newElement("Font", fontName);
		font.newAttr("size", size);
		font.newAttr("bold", bold);
		font.newAttr("italic", italic);
		font.newAttr("underline", underline);
		font.newAttr("strike", strike);
		e.newElement("Vertical", vertical);
		auto clr = e.newElement("Color");
		clr.newAttr("r", color.r);
		clr.newAttr("g", color.g);
		clr.newAttr("b", color.b);
		clr.newAttr("a", color.a);

		if (borderingType !is BorderingType.None) { mixin(S_TRACE);
			auto bdr = e.newElement("Bordering");
			bdr.newAttr("type", fromBorderingType(borderingType));
			bdr.newAttr("width", borderingWidth);
			auto bClr = bdr.newElement("Color");
			bClr.newAttr("r", borderingColor.r);
			bClr.newAttr("g", borderingColor.g);
			bClr.newAttr("b", borderingColor.b);
			bClr.newAttr("a", borderingColor.a);
		}

		toNodeCommon(e, false);
	}
	static TextCell createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		if (node.name != XML_NAME) throw new AreaException("Node is not TextCell");
		string text = "";
		string fontName = "";
		uint size = 1;
		CRGB color = CRGB(0, 0, 0, 255);
		bool bold = false;
		bool italic = false;
		bool underline = false;
		bool strike = false;
		bool vertical = false;
		BorderingType borderingType = BorderingType.None;
		CRGB borderingColor = CRGB(255, 255, 255, 255);
		uint borderingWidth = 1;

		node.onTag["Text"] = (ref XNode n) { mixin(S_TRACE);
			text = .decodeLf2(n.value);
		};
		node.onTag["Font"] = (ref XNode n) { mixin(S_TRACE);
			fontName = n.value;
			size = n.attr!uint("size", true);
			bold = n.attr!bool("bold", false, bold);
			italic = n.attr!bool("italic", false, italic);
			underline = n.attr!bool("underline", false, underline);
			strike = n.attr!bool("strike", false, strike);
		};
		node.onTag["Vertical"] = (ref XNode n) { mixin(S_TRACE);
			vertical = n.valueTo!bool();
		};
		node.onTag["Color"] = (ref XNode n) { mixin(S_TRACE);
			color.r = n.attr!uint("r", true);
			color.g = n.attr!uint("g", true);
			color.b = n.attr!uint("b", true);
			color.a = n.attr!uint("a", false, color.a);
		};
		node.onTag["Bordering"] = (ref XNode n) { mixin(S_TRACE);
			borderingType = toBorderingType(n.attr("type", true));
			borderingWidth = n.attr("width", false, borderingWidth);
			n.onTag["Color"] = (ref XNode n) { mixin(S_TRACE);
				borderingColor.r = n.attr!uint("r", true);
				borderingColor.g = n.attr!uint("g", true);
				borderingColor.b = n.attr!uint("b", true);
				borderingColor.a = n.attr!uint("a", false, borderingColor.a);
			};
			n.parse();
		};
		node.parse();

		auto r = new TextCell(text, fontName, size, color, bold, italic, underline, strike, vertical,
			borderingType, borderingColor, borderingWidth, "", 0, 0, 0, 0, false);
		r.fromNodeCommon(node);
		return r;
	}
}

/// カラーセル(CardWirth 1.50)。
public class ColorCell : BgImage {
private:
	BlendMode _blendMode = BlendMode.Normal;
	GradientDir _gradientDir = GradientDir.None;
	CRGB _color1 = CRGB(255, 255, 255, 255);
	CRGB _color2 = CRGB(0, 0, 0, 255);
public:
	/// XML要素名。
	static immutable XML_NAME = "ColorCell";

	/// 空のインスタンスを生成する。
	this () { mixin(S_TRACE);
		super ("", 0, 0, 0, 0, false);
	}

	/// パラメータを指定してインスタンスを生成する。
	this (BlendMode blendMode, GradientDir gradientDir, CRGB color1, CRGB color2,
			string flag, int x, int y, int w, int h, bool mask) { mixin(S_TRACE);
		super (flag, x, y, w, h, mask);
		_blendMode = blendMode;
		_gradientDir = gradientDir;
		_color1 = color1;
		_color2 = color2;
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto b = cast(ColorCell) o;
		return b
			&& blendMode == b.blendMode
			&& gradientDir == b.gradientDir
			&& color1 == b.color1
			&& color2 == b.color2
			&& super.opEquals(o);
	}

	@property
	const
	override
	string name(in CProps prop) { mixin(S_TRACE);
		string name = .tryFormat("#%02X%02X%02X", color1.r, color1.g, color1.b);
		if (gradientDir !is GradientDir.None) { mixin(S_TRACE);
			name ~= .tryFormat("-#%02X%02X%02X", color2.r, color2.g, color2.b);
		}
		if (cellName == "") { mixin(S_TRACE);
			return name;
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.nameWithCellName, cellName, name);
		}
	}

	@property
	const
	override
	BgImage dup() { mixin(S_TRACE);
		auto cell = new ColorCell(blendMode, gradientDir, color1, color2, flag, x, y, width, height, mask);
		dupImpl(cell);
		return cell;
	}

	/// 合成モード。
	@property
	const
	BlendMode blendMode() { return _blendMode; }
	/// ditto
	@property
	void blendMode(BlendMode value) { mixin(S_TRACE);
		if (_blendMode != value) { mixin(S_TRACE);
			changed();
			_blendMode = value;
		}
	}

	/// グラデーション方向。
	@property
	const
	GradientDir gradientDir() { return _gradientDir; }
	/// ditto
	@property
	void gradientDir(GradientDir value) { mixin(S_TRACE);
		if (_gradientDir != value) { mixin(S_TRACE);
			changed();
			_gradientDir = value;
		}
	}

	/// 開始色。
	@property
	const
	CRGB color1() { return _color1; }
	/// ditto
	@property
	void color1(CRGB value) { mixin(S_TRACE);
		if (_color1 != value) { mixin(S_TRACE);
			changed();
			_color1 = value;
		}
	}
	/// 終了色。
	@property
	const
	CRGB color2() { return _color2; }
	/// ditto
	@property
	void color2(CRGB value) { mixin(S_TRACE);
		if (_color2 != value) { mixin(S_TRACE);
			changed();
			_color2 = value;
		}
	}

	override
	const
	void toNode(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		assert (node.name == XML_NAME_M, node.name ~ " != BgImages");
		auto e = node.newElement(XML_NAME);

		e.newElement("BlendMode", fromBlendMode(blendMode));
		auto clr1 = e.newElement("Color");
		clr1.newAttr("r", color1.r);
		clr1.newAttr("g", color1.g);
		clr1.newAttr("b", color1.b);
		clr1.newAttr("a", color1.a);
		if (gradientDir !is GradientDir.None) { mixin(S_TRACE);
			auto ge = e.newElement("Gradient");
			ge.newAttr("direction", fromGradientDir(gradientDir));
			auto clr2 = ge.newElement("EndColor");
			clr2.newAttr("r", color2.r);
			clr2.newAttr("g", color2.g);
			clr2.newAttr("b", color2.b);
			clr2.newAttr("a", color2.a);
		}

		toNodeCommon(e, false);
	}
	static ColorCell createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		if (node.name != XML_NAME) throw new AreaException("Node is not TextCell");
		BlendMode blendMode = BlendMode.Normal;
		GradientDir gradientDir = GradientDir.None;
		CRGB color1 = CRGB(255, 255, 255, 255);
		CRGB color2 = CRGB(0, 0, 0, 255);

		node.onTag["BlendMode"] = (ref XNode n) { mixin(S_TRACE);
			blendMode = toBlendMode(n.value);
		};
		node.onTag["Color"] = (ref XNode n) { mixin(S_TRACE);
			color1.r = n.attr!uint("r", true);
			color1.g = n.attr!uint("g", true);
			color1.b = n.attr!uint("b", true);
			color1.a = n.attr!uint("a", false, color1.a);
		};
		node.parse();
		node.onTag["Gradient"] = (ref XNode n) { mixin(S_TRACE);
			gradientDir = toGradientDir(n.attr("direction", true));
			n.onTag["EndColor"] = (ref XNode n) { mixin(S_TRACE);
				color2.r = n.attr!uint("r", true);
				color2.g = n.attr!uint("g", true);
				color2.b = n.attr!uint("b", true);
				color2.a = n.attr!uint("a", false, color2.a);
			};
			n.parse();
		};
		node.parse();

		auto r = new ColorCell(blendMode, gradientDir, color1, color2, "", 0, 0, 0, 0, false);
		r.fromNodeCommon(node);
		return r;
	}
}

/// PCセル(Wsn.1)。
public class PCCell : BgImage {
private:
	uint _pcNumber = 0;
	bool _expand = false;
	Smoothing _smoothing = Smoothing.Default;
public:
	/// XML要素名。
	static immutable XML_NAME = "PCCell";

	/// 空のインスタンスを生成する。
	this () { mixin(S_TRACE);
		super ("", 0, 0, 0, 0, false);
	}

	/// パラメータを指定してインスタンスを生成する。
	this (uint pcNumber, bool expand, string flag, int x, int y, int w, int h, bool mask) { mixin(S_TRACE);
		super (flag, x, y, w, h, mask);
		_pcNumber = pcNumber;
		_expand = expand;
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto b = cast(PCCell) o;
		return b
			&& pcNumber == b.pcNumber
			&& expand == b.expand
			&& smoothing == b.smoothing
			&& super.opEquals(o);
	}

	@property
	const
	override
	string name(in CProps prop) { mixin(S_TRACE);
		string name = _pcNumber == 0 ? prop.msgs.pcCellNoSet : .tryFormat(prop.msgs.pc, _pcNumber);
		if (cellName == "") { mixin(S_TRACE);
			return name;
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.nameWithCellName, cellName, name);
		}
	}

	@property
	const
	override
	BgImage dup() { mixin(S_TRACE);
		auto cell = new PCCell(pcNumber, expand, flag, x, y, width, height, mask);
		dupImpl(cell);
		cell.smoothing = smoothing;
		return cell;
	}

	/// 表示するPCの位置(1～6)。
	@property
	const
	uint pcNumber() { mixin(S_TRACE);
		return _pcNumber;
	}
	/// ditto
	@property
	void pcNumber(uint pcNumber) { mixin(S_TRACE);
		if (_pcNumber != pcNumber) changed();
		_pcNumber = pcNumber;
	}

	/// セルのサイズとイメージのサイズが一致しない時、
	/// イメージのサイズをセルに合わせて変更するか。
	@property
	const
	bool expand() { mixin(S_TRACE);
		return _expand;
	}
	/// ditto
	@property
	void expand(bool expand) { mixin(S_TRACE);
		if (_expand != expand) changed();
		_expand = expand;
	}

	/// 拡大・縮小時のスムージングの設定(Wsn.2)。
	@property
	const
	Smoothing smoothing() { return _smoothing; }
	/// ditto
	@property
	void smoothing(Smoothing v) { mixin(S_TRACE);
		if (_smoothing != v) changed();
		_smoothing = v;
	}

	override
	const
	void toNode(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		assert (node.name == XML_NAME_M, node.name ~ " != BgImages");
		auto e = node.newElement(XML_NAME);

		if (expand) e.newAttr("expand", expand);
		e.newElement("PCNumber", .text(pcNumber));
		e.newAttr("smoothing", fromSmoothing(smoothing));

		toNodeCommon(e, false);
	}
	static PCCell createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		if (node.name != XML_NAME) throw new AreaException("Node is not PCCell");
		uint pcNumber = 0;
		bool expand = node.attr!bool("expand", false, false);

		node.onTag["PCNumber"] = (ref XNode n) { mixin(S_TRACE);
			pcNumber = to!uint(n.value);
		};
		node.parse();

		auto r = new PCCell(pcNumber, expand, "", 0, 0, 0, 0, false);
		r.fromNodeCommon(node);
		r.smoothing = toSmoothing(node.attr("smoothing", false, "Default"));
		return r;
	}
}

public abstract class BgImage : FlagUser, ICellNameUser, CWXPath {
private:
	bool _mask = false;
	int _x, _y;
	int _w, _h;
	CellNameUser _cellName;
	int _layer = LAYER_BACK_CELL;
	void delegate() _change;
public:
	/// XML要素名(複数)。
	static immutable XML_NAME_M = "BgImages";

	protected this (string flag, int x, int y, int w, int h, bool mask) { mixin(S_TRACE);
		super (this);
		super.flag = flag;
		_x = x;
		_y = y;
		_w = w;
		_h = h;
		_mask = mask;
		_cellName = new CellNameUser(this);
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto b = cast(BgImage)o;
		return b
			&& flag == b.flag
			&& x == b.x
			&& y == b.y
			&& width == b.width
			&& height == b.height
			&& mask == b.mask
			&& cellName == b.cellName
			&& layer == b.layer;
	}

	/// この背景画像を簡単に表現した名前を返す。
	@property
	const
	string name(in CProps prop);

	/// コピーを生成する。
	@property
	const
	abstract
	BgImage dup();

	/// コピーの共通部分。
	const
	protected void dupImpl(BgImage cell) {
		cell.flag = flag;
		cell.x = x;
		cell.y = y;
		cell.width = width;
		cell.height = height;
		cell.mask = mask;
		cell.cellName = cellName;
		cell.layer = layer;
	}

	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		_change = change;
	}
	/// 変更を通知。
	protected override void changed() { mixin(S_TRACE);
		if (_change) _change();
	}

	@property
	override void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		super.setUseCounter(uc);
		_cellName.setUseCounter(uc);
	}
	/// ditto
	override void removeUseCounter() { mixin(S_TRACE);
		super.removeUseCounter();
		_cellName.removeUseCounter();
	}
	override bool change(CellNameId newVal) { mixin(S_TRACE);
		return _cellName.change(newVal);
	}

	@property
	override
	void flag(string flag) { mixin(S_TRACE);
		if (this.flag != flag) changed();
		super.flag = flag;
	}
	alias super.flag flag;

	/// 透明色を使用するか。
	@property
	const
	bool mask() { mixin(S_TRACE);
		return _mask;
	}
	/// ditto
	@property
	void mask(bool mask) { mixin(S_TRACE);
		if (_mask != mask) changed();
		_mask = mask;
	}
	/// X座標。
	@property
	const
	int x() { mixin(S_TRACE);
		return _x;
	}
	/// ditto
	@property
	void x(int x) { mixin(S_TRACE);
		if (_x != x) changed();
		_x = x;
	}
	/// Y座標。
	@property
	const
	int y() { mixin(S_TRACE);
		return _y;
	}
	/// ditto
	@property
	void y(int y) { mixin(S_TRACE);
		if (_y != y) changed();
		_y = y;
	}

	/// 幅。
	@property
	const
	int width() { mixin(S_TRACE);
		return _w;
	}
	/// ditto
	@property
	void width(int w) { mixin(S_TRACE);
		if (w < 0) w = 0;
		if (_w != w) changed();
		_w = w;
	}
	/// 高さ。
	@property
	const
	int height() { mixin(S_TRACE);
		return _h;
	}
	/// ditto
	@property
	void height(int h) { mixin(S_TRACE);
		if (h < 0) h = 0;
		if (_h != h) changed();
		_h = h;
	}

	/// イベントでの操作に使用するためのセル名。
	@property
	const
	string cellName() { return _cellName.cellName; }
	/// ditto
	@property
	void cellName(string v) { mixin(S_TRACE);
		if (_cellName.cellName != v) changed();
		_cellName.cellName = v;
	}

	/// セルの表示レイヤ。
	// 値が大きいほど手前に表示される。
	// デフォルト値はLAYER_BACK_CELL。
	@property
	const
	int layer() { return _layer; }
	/// ditto
	@property
	void layer(int v) { mixin(S_TRACE);
		if (_layer != v) changed();
		_layer = v;
	}

	/// この背景と強く関係するファイルパスを返す。
	/// そのようなファイルが無い場合は""を返す。
	@property
	const
	string connectedFile() { mixin(S_TRACE);
		return "";
	}

	override bool change(FlagId id) { mixin(S_TRACE);
		return super.change(id);
	}

	static BgImage[] bgImagesFromNode(ref XNode node, bool canInherit, in XMLInfo ver) { mixin(S_TRACE);
		assert (node.name == XML_NAME_M);
		BgImage[] bgImgs;
		node.onTag[ImageCell.XML_NAME] = (ref XNode bgn) { mixin(S_TRACE);
			bgImgs ~= ImageCell.createFromNode(bgn, ver);
		};
		node.onTag[TextCell.XML_NAME] = (ref XNode bgn) { mixin(S_TRACE);
			bgImgs ~= TextCell.createFromNode(bgn, ver);
		};
		node.onTag[ColorCell.XML_NAME] = (ref XNode bgn) { mixin(S_TRACE);
			bgImgs ~= ColorCell.createFromNode(bgn, ver);
		};
		node.onTag[PCCell.XML_NAME] = (ref XNode bgn) { mixin(S_TRACE);
			bgImgs ~= PCCell.createFromNode(bgn, ver);
		};
		node.parse();
		if (!bgImgs.length) return bgImgs;

		auto b = cast(ImageCell)bgImgs[0u];
		if (canInherit && b && b.path == "" && b.flag == ""
				&& b.x == 0 && b.y == 0 && b.width == 632 && b.height == 420 && !b.mask
				&& b.cellName == "") { mixin(S_TRACE);
			// クラシックなエンジンでは必ず1枚以上の背景画像が必要であるため、
			// 背景継承時はダミーのイメージが挿入されている
			return bgImgs[1u .. $];
		} else { mixin(S_TRACE);
			return bgImgs;
		}
	}

	/// 指定されたノードに背景イメージ群のデータを追加する。
	static void toNode(in BgImage[] bgImgs, bool canInherit, ref XNode e, XMLOption opt) { mixin(S_TRACE);
		auto bge = e.newElement(XML_NAME_M);
		if (bgImgs.length > 0) { mixin(S_TRACE);
			if (canInherit) { mixin(S_TRACE);
				// FIXME: 632×420のサイズはCPropsに持たせているがコンパイラのバグで参照できない。暫定。
				auto b = cast(ImageCell)bgImgs[0];
				if (!b || b.flag != "" || b.x != 0 || b.y != 0 || b.width != 632 || b.height != 420 || b.mask || b.cellName != "") { mixin(S_TRACE);
					BgImage.appendEmptyToNode(bge, opt);
				}
			}
			foreach (bg; bgImgs) { mixin(S_TRACE);
				bg.toNode(bge, opt);
			}
		} else if (canInherit) { mixin(S_TRACE);
			BgImage.appendEmptyToNode(bge, opt);
		}
	}

	/// XMLノード(BgImages)にインスタンスのデータを追加する。
	const
	abstract
	void toNode(ref XNode node, XMLOption opt);
	/// サブクラスでtoNode()の実装を行う際の共通処理。
	const
	protected void toNodeCommon(ref XNode e, bool useMask) {
		if (useMask) e.newAttr("mask", fromBool(_mask));
		if (cellName != "") e.newAttr("cellname", cellName);
		e.newElement("Flag", super.flag);
		auto ln = e.newElement("Location");
		ln.newAttr("left", _x);
		ln.newAttr("top", _y);
		auto sn = e.newElement("Size");
		sn.newAttr("width", _w);
		sn.newAttr("height", _h);
		if (layer != LAYER_BACK_CELL) e.newElement("Layer", layer);
	}
	/// サブクラスでfromNode()の実装を行う際の共通処理。
	protected void fromNodeCommon(ref XNode node) { mixin(S_TRACE);
		mask = parseBool(node.attr("mask", false, fromBool(false)));
		layer = LAYER_BACK_CELL;
		cellName = node.attr("cellname", false, "");
		node.onTag["Flag"] = (ref XNode n) { mixin(S_TRACE);
			flag = n.value;
		};
		node.onTag["Location"] = (ref XNode n) { mixin(S_TRACE);
			x = n.attr!(int)("left", true);
			y = n.attr!(int)("top", true);
		};
		node.onTag["Size"] = (ref XNode n) { mixin(S_TRACE);
			width = n.attr!(int)("width", true);
			height = n.attr!(int)("height", true);
		};
		node.onTag["Layer"] = (ref XNode n) { mixin(S_TRACE);
			layer = n.valueTo!int();
		};
		node.parse();
	}

	/// 背景イメージが一枚も無い場合。
	static void appendEmptyToNode(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		assert (node.name == XML_NAME_M, node.name ~ " != BgImages");
		auto e = node.newElement(ImageCell.XML_NAME);
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
	
	/// nodeから適切なインスタンスを生成して返す。
	static BgImage createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		if (node.name == ImageCell.XML_NAME) { mixin(S_TRACE);
			return ImageCell.createFromNode(node, ver);
		} else if (node.name == TextCell.XML_NAME) { mixin(S_TRACE);
			return TextCell.createFromNode(node, ver);
		} else if (node.name == ColorCell.XML_NAME) { mixin(S_TRACE);
			return ColorCell.createFromNode(node, ver);
		} else if (node.name == PCCell.XML_NAME) { mixin(S_TRACE);
			return PCCell.createFromNode(node, ver);
		} else assert (0, node.name);
	}

	private BgImageOwner _owner;
	@property
	package void owner(BgImageOwner owner) {_owner = owner;}
	@property
	override string cwxPath(bool id) { mixin(S_TRACE);
		return _owner ? cpjoin(_owner, "background", .cCountUntil!("a is b")(_owner.backs, this), id) : "";
	}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		return null;
	}
	@property
	override
	inout
	inout(CWXPath)[] cwxChilds() {return [];}
	@property
	override
	CWXPath cwxParent() {return _owner;}
}

/// BgImage所持者のインタフェース。
interface BgImageOwner : CWXPath {
	@property
	inout inout(BgImage)[] backs();
}

/// BgImageのコンテナ。背景変更イベントの編集で使用。
/// シナリオのデータ構造には組み込まれない。
class BgImageContainer : BgImageOwner {
private:
	BgImage[] _bgImgs;
public:
	/// 唯一のコンストラクタ。
	this (BgImage[] bgImgs) { mixin(S_TRACE);
		_bgImgs = bgImgs;
	}
	@property
	override string cwxPath(bool id) {return "";}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "background": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= _bgImgs.length) return null;
			return _bgImgs[index].findCWXPath(cpbottom(path));
		}
		default: break;
		}
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		inout(CWXPath)[] r;
		foreach (a; backs) r ~= a;
		return r;
	}
	@property
	CWXPath cwxParent() {return null;}

	/// 背景イメージ群。
	@property
	inout
	inout(BgImage)[] backs() { mixin(S_TRACE);
		return _bgImgs;
	}
	/// ditto
	@property
	void backs(BgImage[] bgImgs) { mixin(S_TRACE);
		foreach (b; _bgImgs) { mixin(S_TRACE);
			b.owner = null;
		}
		foreach (b; bgImgs) { mixin(S_TRACE);
			b.owner = this;
		}
		_bgImgs = bgImgs;
	}
	/// 背景イメージを追加。
	void append(BgImage back) { mixin(S_TRACE);
		back.owner = this;
		_bgImgs ~= back;
	}
	/// ditto
	void insert(size_t index, BgImage back) { mixin(S_TRACE);
		if (_bgImgs.length == index) { mixin(S_TRACE);
			append(back);
		} else { mixin(S_TRACE);
			back.owner = this;
			_bgImgs = _bgImgs[0 .. index] ~ back ~ _bgImgs[index .. $];
		}
	}
	/// ditto
	void set(size_t index, BgImage back) { mixin(S_TRACE);
		_bgImgs[index].owner = null;
		back.owner = this;
		_bgImgs[index] = back;
	}
	/// 背景イメージを除外。
	void removeBgImage(size_t index) { mixin(S_TRACE);
		_bgImgs[index].owner = null;
		_bgImgs = _bgImgs[0 .. index] ~ _bgImgs[index + 1 .. $];
	}
	/// 背景イメージのインデックスを交換。
	void swapBacks(size_t index1, size_t index2) { mixin(S_TRACE);
		auto temp = _bgImgs[index1];
		_bgImgs[index1] = _bgImgs[index2];
		_bgImgs[index2] = temp;
	}

	protected override void changed() { }

	/// 背景イメージ群をXMLノードにする。
	static string BtoXML(BgImage[] backs, XMLOption opt) { mixin(S_TRACE);
		scope doc = XNode.create("MenuCardsAndBgImages");
		if (backs.length) { mixin(S_TRACE);
			auto be = doc.newElement(BgImage.XML_NAME_M);
			foreach (b; backs) { mixin(S_TRACE);
				b.toNode(be, opt);
			}
		}
		return doc.text;
	}
	/// XMLノードから背景イメージ群を読み出す。
	static bool BfromXML(string xml, out BgImage[] backs, in XMLInfo ver) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			scope doc = XNode.parse(xml);
			if (doc.name == "MenuCardsAndBgImages") { mixin(S_TRACE);
				doc.onTag[BgImage.XML_NAME_M] = (ref XNode node) { mixin(S_TRACE);
					node.onTag[null] = (ref XNode node) { mixin(S_TRACE);
						backs ~= BgImage.createFromNode(node, ver);
					};
					node.parse();
				};
				doc.parse();
				return true;
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return false;
	}
}

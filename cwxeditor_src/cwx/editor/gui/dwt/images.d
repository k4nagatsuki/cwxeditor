
module cwx.editor.gui.dwt.images;

import cwx.utils;
import cwx.props;
import cwx.structs;
import cwx.types;
import cwx.graphics;
import cwx.jpy;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dmenu;

import std.algorithm;
import std.math;
import std.file;
import std.path;
import std.conv;
import std.string;
import std.utf;

import org.eclipse.swt.all;

/// イメージを拡大・縮小・移動させるためのトグル。
public enum Toggle {
	/// 左上のトグル。
	LEFT_TOP,
	/// 左辺中央のトグル。
	LEFT_MIDDLE,
	/// 左下のトグル。
	LEFT_BOTTOM,
	/// 上辺中央のトグル。
	MIDDLE_TOP,
	/// 下辺中央のトグル。
	MIDDLE_BOTTOM,
	/// 右上のトグル。
	RIGHT_TOP,
	/// 右辺中央のトグル。
	RIGHT_MIDDLE,
	/// 右下のトグル。
	RIGHT_BOTTOM,
	/// 画像内。(移動)
	MOVE,
	/// 画像外。
	NONE,
}

/// 画像のサイズが実際に表示されるサイズと一致しない場合の処理方法。
enum ScaleType {
	Cut, /// 左上を基準に配置する。
	Scale, /// 表示サイズに合わせて拡縮する。
	Center, /// 中央寄せして配置する。
}

/// PileImageのタイプ。
enum ImageType {
	Image, /// 重ね合わせた画像。
	Text, /// テキスト描画。テキスト本体は拡大縮小されない。
	ColorFilter, /// カラーフィルタ。
}

/// 画像を重ねて1枚のイメージを作成する。
public class PileImage {
private:
	// ImageType.Image用。
	public enum TPos {
		LEFT,
		RIGHT
	}
	struct AppImg {
		CInsets insets;
		string path = "";
		string text = "";
		ImageData data = null;
		bool transparent;
		int maskX;
		int maskY;
		CFont font;
		CRGB fontColor;
		TPos textPos = TPos.LEFT;
		byte alpha = cast(byte) 0xFF;
		FontData fontData = null;
		ScaleType scaleType = ScaleType.Scale;
	}
	ImageType _type = ImageType.Image;
	string _title = null;
	FontData titFont = null;
	Point titPoint = null;
	AppImg[] appends = [];
	Rectangle rect;
	bool t = false;
	bool s = false;
	int _alpha = 0xFF;
	Image _img = null;
	ImageData _imgData = null;
	ImageData _baseSizeData = null;
	string path = "";
	ImageData data = null;

	bool _visible = true;
	bool _smoothing = false;

	int initW, initH;
	int _maskR = 0, _maskG = 0, _maskB = 0, _maskA = 0;
	bool _dataResizable = true;

	// ImageType.Text用。_titleとtitFontを流用。
	int _fontPixelSize = 0;
	CRGB _textColor = CRGB(0, 0, 0, 255);
	bool _underline = false;
	bool _strike = false;
	bool _vertical = false;
	BorderingType _borderingType = BorderingType.None;
	CRGB _borderingColor = CRGB(255, 255, 255, 255);
	uint _borderingWidth = 1;
	string delegate(string) _previewText = null;

	// ImageType.ColorFilter用。
	BlendMode _blendMode = BlendMode.Normal;
	GradientDir _gradientDir = GradientDir.None;
	CRGB _color1 = CRGB(255, 255, 255, 255);
	CRGB _color2 = CRGB(0, 0, 0, 255);

public:
	/// 画像のファイルパス、位置、サイズを指定してインスタンスを生成する。
	/// パスが存在しない場合、描画のタイミングで単に表示されない。
	/// Params:
	/// path = 画像のファイルパス。
	/// x = 横位置。
	/// y = 縦位置。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this (string path, int x, int y, int baseW, int baseH) {
		this._type = ImageType.Image;
		this.path = path;
		rect = new Rectangle(x, y, baseW, baseH);
		initW = baseW;
		initH = baseH;
	}
	/// 画像のファイルパス、サイズを指定してインスタンスを生成する。
	/// パスが存在しない場合、描画のタイミングで単に表示されない。
	/// Params:
	/// path = 画像のファイルパス。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this (string path, int baseW, int baseH) {
		this(path, 0, 0, baseW, baseH);
	}
	/// 画像のデータ、位置、サイズを指定してインスタンスを生成する。
	/// Params:
	/// data = 画像のデータ。
	/// x = 横位置。
	/// y = 縦位置。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this (ImageData data, int x, int y, int baseW, int baseH, bool dataResizable) {
		this._type = ImageType.Image;
		this.data = data;
		rect = new Rectangle(x, y, baseW, baseH);
		initW = baseW;
		initH = baseH;
		_dataResizable = dataResizable;
	}
	/// 画像のデータ、サイズを指定してインスタンスを生成する。
	/// Params:
	/// data = 画像のデータ。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this (ImageData data, int baseW, int baseH) {
		this(data, 0, 0, baseW, baseH, true);
	}

	/// サイズのみを指定してインスタンスを生成する。
	this (ImageType type, int x, int y, int baseW, int baseH) {
		this._type = type;
		rect = new Rectangle(x, y, baseW, baseH);
		initW = baseW;
		initH = baseH;
	}

	/// テキスト表示用のインスタンスを生成する。
	this (string text, string fontName, int size, CRGB color,
			bool bold, bool italic, bool underline, bool strike, bool vertical,
			BorderingType borderingType, CRGB borderingColor, uint borderingWidth,
			int x, int y, int baseW, int baseH) {
		this (ImageType.Text, x, y, baseW, baseH);

		setTitle(text, fontName, size, bold, italic, vertical);
		this.textColor = color;
		this.underline = underline;
		this.strike = strike;
		this.borderingType = borderingType;
		this.borderingColor = borderingColor;
		this.borderingWidth = borderingWidth;
	}

	/// イメージのタイプ。
	@property
	const
	ImageType type() { return _type; }

	/// Returns: ベースとなる幅。
	@property
	const
	int baseWidth() {
		return initW;
	}
	/// Returns: ベースとなる高さ。
	@property
	const
	int baseHeight() {
		return initH;
	}
	/// Params:
	/// initW = ベースとなる幅。
	@property
	void baseWidth(int initW) {
		this.initW = initW;
	}
	/// Params:
	/// initH = ベースとなる高さ。
	@property
	void baseHeight(int initH) {
		this.initH = initH;
	}

	/// 前面に画像を追加する。
	/// Params:
	/// path = 画像のファイルパス。
	/// insets = 内側の隙間。
	/// transparent = 透過するか否か。
	/// maskX = マスク色のX位置。
	/// maskY = マスク色のY位置。
	/// See_Also: createImage();
	void append(string path, CInsets insets, ScaleType scaleType, bool transparent, int maskX = 0, int maskY = 0, byte alpha = cast(byte) 0xFF) {
		AppImg append;
		append.insets = insets;
		append.path = path;
		append.transparent = transparent;
		append.maskX = maskX;
		append.maskY = maskY;
		append.alpha = alpha;
		append.scaleType = scaleType;
		appends ~= append;
	}
	/// ditto
	void append(ImageData data, CInsets insets, ScaleType scaleType, byte alpha = cast(byte) 0xFF) {
		AppImg append;
		append.insets = insets;
		append.data = data;
		append.alpha = alpha;
		append.scaleType = scaleType;
		appends ~= append;
	}
	/// ditto
	void append(ImageData data, CPoint point, ScaleType scaleType, byte alpha = cast(byte) 0xFF) {
		append(data, CInsets(point.y,
			initW - (point.x + data.width),
			initH - (point.y + data.height),
			point.x), scaleType, alpha);
	}
	/// ditto
	void append(FontData fontData, string text, CInsets insets) {
		AppImg append;
		append.fontData = fontData;
		append.text = text;
		append.insets = insets;
		appends ~= append;
	}
	/// 前面に文字列を追加する。
	void append(string text, CInsets insets, CFont font, CRGB fontColor, TPos pos = TPos.LEFT) {
		AppImg append;
		append.text = text;
		append.insets = insets;
		append.font = font;
		append.fontColor = fontColor;
		append.textPos = pos;
		appends ~= append;
	}
	/// ditto
	void append(string text, CPoint point, CFont font, CRGB fontColor) {
		append(text, CInsets(point.y, 0, 0, point.x), font, fontColor, TPos.LEFT);
	}
	void setPath(string path) {
		this.path = path;
		this.data = null;
	}
	void setPath(int index, string path) {
		appends[index].path = path;
		appends[index].data = null;
	}
	void setTransparent(int index, bool mask) {
		appends[index].transparent = mask;
	}
	void setImageData(ImageData data) {
		this.path = "";
		this.data = data;
	}
	void setImageData(int index, ImageData data) {
		appends[index].path = "";
		appends[index].data = data;
	}
	/// タイトルとして表示する文字列を設定する。
	/// Params:
	/// title = タイトルの文字列。
	/// font = 表示時のフォント。
	/// titPoint = タイトルの表示位置。
	/// See_Also: createImage();
	void setTitle(string title, FontData font, Point titPoint) {
		this._title = title;
		this.titFont = font;
		this.titPoint = titPoint;
	}
	void setTitle(string title, string fontName, int size, bool bold, bool italic, bool vertical) {
		this.vertical = vertical;
		int style = SWT.NORMAL;
		if (bold) style |= SWT.BOLD;
		if (italic) style |= SWT.ITALIC;
		auto d = Display.getCurrent();
		auto h = cast(int) (size * (72.0 / d.getDPI().y) + 0.5);
		if (vertical && !fontName.startsWith("@")) {
			auto fontName2 = "@" ~ fontName;
			if (d.getFontList(fontName2, true) || d.getFontList(fontName2, false)) {
				fontName = fontName2;
			}
		}
		_fontPixelSize = size;
		auto font = new FontData(fontName, h, style);
		setTitle(title, font, new Point(0, 0));
	}
	@property
	void title(string title) {
		assert (titFont !is null);
		assert (titPoint);
		_title = title;
	}
	@property
	const
	string title() {
		return this._title;
	}
	@property
	FontData font() {
		return titFont;
	}
	@property
	const
	int fontPixelSize() { return _fontPixelSize; }

	/// 全体に指定された色のフィルタをかける。
	void colorMask(int r, int g, int b, int a) {
		_maskR = r;
		_maskG = g;
		_maskB = b;
		_maskA = a;
	}

	/// テキスト色。
	@property
	const
	CRGB textColor() { return _textColor; }
	@property
	void textColor(CRGB value) { _textColor = value; }
	/// 下線。
	@property
	const
	bool underline() { return _underline; }
	@property
	void underline(bool value) { _underline = value; }
	/// 取消線。
	@property
	const
	bool strike() { return _strike; }
	@property
	void strike(bool value) { _strike = value; }
	/// 縦書き。
	@property
	const
	bool vertical() { return _vertical; }
	@property
	void vertical(bool value) { _vertical = value; }
	/// 縁取り方式。
	@property
	const
	BorderingType borderingType() { return _borderingType; }
	@property
	void borderingType(BorderingType value) { _borderingType = value; }
	/// 縁取り色。
	@property
	const
	CRGB borderingColor() { return _borderingColor; }
	@property
	void borderingColor(CRGB value) { _borderingColor = value; }
	/// 縁取り幅。
	@property
	const
	uint borderingWidth() { return _borderingWidth; }
	@property
	void borderingWidth(uint value) { _borderingWidth = value; }

	/// 表示前にテキスト加工を行うdelegate。
	/// nullの場合は加工しない。
	@property
	const
	string delegate(string) previewText() { return _previewText; }
	@property
	void previewText(string delegate(string) value) { _previewText = value; }

	/// 合成モード。
	@property
	const
	BlendMode blendMode() { return _blendMode; }
	/// ditto
	@property
	void blendMode(BlendMode value) { _blendMode = value; }
	/// グラデーション方向。
	@property
	const
	GradientDir gradientDir() { return _gradientDir; }
	/// ditto
	@property
	void gradientDir(GradientDir value) { _gradientDir = value; }
	/// 開始色。
	@property
	const
	CRGB color1() { return _color1; }
	/// ditto
	@property
	void color1(CRGB value) { _color1 = value; }
	/// 終了色。
	@property
	const
	CRGB color2() { return _color2; }
	/// ditto
	@property
	void color2(CRGB value) { _color2 = value; }

	/// イメージ・タイトル・透明色の設定有無を設定した後に
	/// このメソッドを呼び出すことで、画像が生成される。
	/// See_Also: append(), setTitle(), transparent()
	void createImage() {
		auto cur = Display.getCurrent();
		if (_imgData) {
			del(_imgData);
		}
		if (_img) _img.dispose();
		_imgData = createImageData();
		_img = _imgData ? new Image(cur, _imgData) : null;
	}
	/// イメージ・タイトル・透明色の設定有無を設定した後に
	/// このメソッドを呼び出すことで、ImageDataが生成される。
	/// See_Also: append(), setTitle(), transparent()
	ImageData createImageData() {
		if (width == 0 || height == 0 || initW == 0 || initH == 0) return null;

		try {
			final switch (_type) {
			case ImageType.Image:
				return createImageDataImpl();
			case ImageType.Text:
				return createTextImageData();
			case ImageType.ColorFilter:
				return createFilterImageData();
			}
		} catch (Exception e) {
			debugln(e);
			return blankImage;
		}
	}
	private ImageData createImageDataImpl() {
		auto cur = Display.getCurrent();

		auto dataSet = new HashSet!ImageData;
		if (_baseSizeData) dataSet.add(_baseSizeData);
		ImageData getMat() {
			ImageData matImgData;
			if (this.data) {
				matImgData = this.data;
			} else {
				if (isBinImg(path) || (path !is null && .exists(path))) {
					matImgData = loadImage(path, false);
					dataSet.add(matImgData);
					if (matImgData.width != initW || matImgData.height != initH) {
						matImgData = matImgData.scaledTo(initW, initH);
						dataSet.add(matImgData);
					}
				} else {
					// ファイルが無い場合は単に表示しない。
					matImgData = blankImage(initW, initH);
				}
			}
			return matImgData;
		}
		ImageData matImgData;
		bool noTransparent = false;
		void matNoTransparent() {
			auto data = blankImage(initW, initH);
			data.transparentPixel = -1;
			data.data[] = cast(byte) 255;
			auto img = new Image(cur, data);
			scope (exit) img.dispose();
			auto dc = new GC(img);
			scope (exit) dc.dispose();
			auto mat = getMat();
			auto img2 = new Image(cur, mat);
			scope (exit) img2.dispose();
			dc.drawImage(img2, 0, 0);
			matImgData = img.getImageData();
			dataSet.add(matImgData);
			if (mat.depth == 32) noTransparent = true;
		}
		if (!appends.length && !_title && !this.data && transparent) {
			// FIXME: 1.29の挙動に合わせ、マスク有効なら透明色を無効にする
			matNoTransparent();
		} else if (appends.length || _title !is null) {
			matNoTransparent();
		} else {
			matImgData = getMat();
		}
		auto bmp = new Image(cur, matImgData);
		scope (exit) bmp.dispose();
		ImageData bmpData;
		if (appends.length || _title !is null) {
			auto dc = new GC(bmp);
			scope (exit) dc.dispose();

			foreach (a; appends) {
				if (a.fontData) {
					// 中央にテキストを表示
					auto ca = new Rectangle(a.insets.w, a.insets.n, initW - a.insets.w - a.insets.e, initH - a.insets.n - a.insets.s);
					drawCenterText(a.fontData, dc, ca, a.text);
				} else {
					if (a.path.length || a.data) {
						try {
							ImageData imgData;
							if (a.data) {
								imgData = a.data;
							} else {
								imgData = loadImage(a.path, a.transparent, a.maskX, a.maskY);
								dataSet.add(imgData);
							}
							if (a.alpha != 0xFF) dc.setAlpha(a.alpha);
							scope (exit) {
								if (a.alpha != 0xFF) dc.setAlpha(0xFF);
							}
							int bw = initW - a.insets.w - a.insets.e;
							int bh = initH - a.insets.n - a.insets.s;
							if (imgData.width == bw && imgData.height == bh) {
								auto img = new Image(cur, imgData);
								scope (exit) img.dispose();
								dc.drawImage(img, a.insets.w, a.insets.n);
							} else if (a.scaleType is ScaleType.Cut) {
								auto img = new Image(cur, imgData);
								scope (exit) img.dispose();
								int dw = imgData.width;
								int dh = imgData.height;
								dc.drawImage(img, 0, 0, dw, dh, a.insets.w, a.insets.n, dw, dh);
							} else if (a.scaleType is ScaleType.Center) {
								auto img = new Image(cur, imgData);
								scope (exit) img.dispose();
								int dw = imgData.width;
								int dh = imgData.height;
								int x = a.insets.w + (bw - dw) / 2;
								int y = a.insets.n + (bh - dh) / 2;
								dc.drawImage(img, 0, 0, dw, dh, x, y, dw, dh);
							} else {
								assert (a.scaleType is ScaleType.Scale);
								imgData = imgData.scaledTo
									(initW - a.insets.w - a.insets.e,
									initH - a.insets.n - a.insets.s);
								auto img = new Image(cur, imgData);
								scope (exit) img.dispose();
								dc.drawImage(img, a.insets.w, a.insets.n);
							}
						} catch (SWTException e) {
							// ファイルが無い場合は表示しない。
							debugln(e);
						}
					}
					if (a.text.length) {
						try {
							auto font = new Font(cur, dwtData(a.font));
							scope (exit) font.dispose();
							dc.setFont(font);
							scope (exit) dc.setFont(null);
							int alpha;
							auto color = new Color(cur, dwtData(a.fontColor, alpha));
							scope (exit) color.dispose();
							auto fore = dc.getForeground();
							dc.setForeground(color);
							scope (exit) dc.setForeground(fore);
							dc.setAlpha(alpha);
							scope (exit) dc.setAlpha(255);
							switch (a.textPos) {
							case TPos.LEFT: {
								dc.drawText(a.text, a.insets.w, a.insets.n, true);
							} break;
							case TPos.RIGHT: {
								int tw = dc.textExtent(a.text).x;
								dc.drawText(a.text, initW - a.insets.e - tw, a.insets.n, true);
							} break;
							default: assert (0);
							}
						} catch (SWTException e) {
							debugln(e);
						}
					}
				}
			}

			if (0 != _maskA) {
				auto color = new Color(cur, _maskR, _maskG, _maskB);
				scope (exit) color.dispose();
				dc.setAlpha(_maskA);
				scope (exit) dc.setAlpha(255);
				dc.setBackground(color);
				dc.fillRectangle(0, 0, initW, initH);
			}

			// フォントがおかしくなる
			dc.dispose();
			dc = new GC(bmp);
			if (_title !is null) {
				auto font = new Font(cur, titFont);
				scope (exit) font.dispose();
				dc.setFont(font);
				dc.setForeground(cur.getSystemColor(SWT.COLOR_BLACK));
				dc.drawText(_title, titPoint.x, titPoint.y, true);
				dc.setFont(null);
			}
			bmpData = bmp.getImageData();
			dataSet.add(bmpData);
			_baseSizeData = bmpData;
		} else {
			bmpData = matImgData;
			_baseSizeData = matImgData;
		}
		dataSet.add(bmpData);

		if (transparent && !noTransparent) {
			bmpData.transparentPixel = bmpData.getPixel(0, 0);
			_baseSizeData.transparentPixel = _baseSizeData.getPixel(0, 0);
		}
		if (_dataResizable && (bmpData.width != width || bmpData.height != height)) {
			dataSet.add(bmpData);
			if (smoothing) {
				auto data = cast(ubyte[]) bmpData.data;
				auto alpha = cast(ubyte[]) bmpData.alphaData;
				size_t bpl;
				bmpData.data = cast(byte[]) smoothResize(width, height, data, alpha,
					bmpData.depth, bmpData.width, bmpData.height, bmpData.bytesPerLine, bpl);
				bmpData.alphaData = cast(byte[]) alpha;
				bmpData.width = width;
				bmpData.height = height;
				bmpData.bytesPerLine = bpl;
			} else {
				bmpData = bmpData.scaledTo(width, height);
			}
			dataSet.add(bmpData);
		}
		foreach (d; dataSet) {
			if (bmpData !is d) {
				del(d);
			}
		}
		return bmpData;
	}
	private ImageData createTextImageData() {
		// BorderingType.Inlineの場合のみ、予め画像を生成する
		// (アンチエイリアスがかからないため可能)
		if (borderingType !is BorderingType.Inline) return null;
		auto cur = Display.getCurrent();

		// 文字色でも縁取り色でもない色
		auto back = CRGB(255, 255, 255, 255);
		while (textColor == back || borderingColor == back) {
			back.r--;
		}

		int w, h;
		if (vertical) {
			w = height;
			h = width;
		} else {
			w = width;
			h = height;
		}

		int alpha;
		auto borderRgb = dwtData(borderingColor, alpha);
		auto backRgb = dwtData(back, alpha);
		auto textRgb = dwtData(textColor, alpha);

		auto img = new Image(cur, w, h);
		scope (exit) img.dispose();
		auto gc = new GC(img);
		scope (exit) gc.dispose();
		auto font = new Font(cur, titFont);
		scope (exit) font.dispose();
		auto backColor = new Color(cur, backRgb);
		scope (exit) backColor.dispose();
		auto textColor = new Color(cur, textRgb);
		scope (exit) textColor.dispose();
		auto borderColor = new Color(cur, borderRgb);
		scope (exit) borderColor.dispose();

		gc.setBackground(backColor);
		gc.fillRectangle(0, 0, w, h);
		auto tPixel = img.getImageData().getPixel(0, 0);

		gc.setFont(font);
		gc.setTextAntialias(SWT.NONE);

		// パスの形成
		int x = 0;
		int y = 0;
		int height, ulineWidth, ulinePos, slineWidth, slinePos;
		lineMetrics(gc, height, ulineWidth, ulinePos, slineWidth, slinePos);
		gc.setLineWidth(borderingWidth);
		gc.setLineJoin(SWT.JOIN_ROUND);
		gc.setLineCap(SWT.CAP_ROUND);
		float hb = 0.5F; // drawとfillのずれを補正
		auto pathL = new Path(cur);
		scope (exit) pathL.dispose();
		auto pathF = new Path(cur);
		scope (exit) pathF.dispose();
		gc.setBackground(textColor);
		gc.setForeground(borderColor);
		auto text = _title;
		if (_previewText) {
			text = _previewText(text);
		}
		foreach (line; .splitLines(text)) {
			foreach (dchar c; line) {
				immutable s = [c].toUTF8();
				pathL.addString(s, x, y, font);
				pathF.addString(s, x + hb, y + hb, font);
				x += gc.textExtent(s).x;
			}
			if (underline) {
				int ly = y + ulinePos;
				pathL.addRectangle(0, ly, x, ulineWidth);
				pathF.addRectangle(hb, ly + hb, x, ulineWidth);
			}
			if (strike) {
				int ly = y + slinePos;
				pathL.addRectangle(0, ly, x, slineWidth);
				pathF.addRectangle(hb, ly + hb, x, slineWidth);
			}

			x = 0;
			y += height;
		}

		// 描画
		gc.fillPath(pathF);
		if (borderingWidth <= fontPixelSize / 2) {
			gc.drawPath(pathL);
		} else {
			// FIXME: 何層にも重なり合った部分に隙間が生じてしまう減少に対処
			auto p = pathL.getPathData();
			size_t pi = 0;
			auto rPath = new Path(cur);
			scope (exit) rPath.dispose();
			void newRPath() {
				gc.drawPath(rPath);
				float[2] curPos;
				rPath.getCurrentPoint(curPos);
				rPath.dispose();
				rPath = new Path(cur);
				rPath.moveTo(curPos[0], curPos[1]);
			}
			foreach (type; p.types) {
				switch (type) {
				case SWT.PATH_MOVE_TO:
					rPath.moveTo(p.points[pi], p.points[pi + 1]);
					pi += 2;
					break;
				case SWT.PATH_LINE_TO:
					rPath.lineTo(p.points[pi], p.points[pi + 1]);
					newRPath();
					pi += 2;
					break;
				case SWT.PATH_CUBIC_TO:
					rPath.cubicTo(p.points[pi], p.points[pi + 1], p.points[pi + 2],
						p.points[pi + 3], p.points[pi + 4], p.points[pi + 5]);
					newRPath();
					pi += 6;
					break;
				case SWT.PATH_QUAD_TO:
					rPath.quadTo(p.points[pi], p.points[pi + 1], p.points[pi + 2], p.points[pi + 3]);
					newRPath();
					pi += 4;
					break;
				case SWT.PATH_CLOSE:
					rPath.close();
					newRPath();
					break;
				default:
					assert (0);
				}
			}
		}

		auto imgData = img.getImageData();

		if (vertical) {
			turnImpl(imgData, Turn.LEFT);
		}

		imgData.transparentPixel = tPixel;
		imgData.alpha = alpha;

		return imgData;
	}
	private ImageData createFilterImageData() {
		// カラーフィルタは常に画像無し
		return null;
	}

	/// 画像を描画する。
	/// Params:
	/// dc = キャンバス。
	void draw(ref Image buf, ref GC gc, Rectangle range) {
		if (!_visible) return;
		if (!range.intersects(rect)) return;
		if (!_dataResizable) gc.setClipping(new Rectangle(x, y, width, height));
		scope (exit) {
			if (!_dataResizable) gc.setClipping(cast(Rectangle)null);
		}
		final switch (_type) {
		case ImageType.Image:
			if (!_img) return;
			int olda = gc.getAlpha();
			gc.setAlpha(alpha);
			scope (exit) gc.setAlpha(olda);
			gc.drawImage(_img, x, y);
			break;
		case ImageType.Text:
			if (_img) {
				int olda = gc.getAlpha();
				gc.setAlpha(alpha);
				scope (exit) gc.setAlpha(olda);
				gc.drawImage(_img, x, y);
			} else {
				drawText(buf, gc, range);
			}
			break;
		case ImageType.ColorFilter:
			drawFilter(buf, gc, range);
			break;
		}
	}
	private void lineMetrics(GC gc, out int height, out int ulineWidth, out int ulinePos, out int slineWidth, out int slinePos) {
		auto mt = gc.getFontMetrics();
		height = mt.getHeight();
		ulineWidth = .max(1, fontPixelSize / 16);
		ulinePos = height - mt.getDescent() + ulineWidth / 2;
		slineWidth = .max(1, fontPixelSize / 16);
		slinePos = height - mt.getAscent() / 2 + slineWidth / 2;
	}
	private void drawTextImpl(GC gc, in string[] lines, int xm, int ym) {
		int x = xm;
		int y = ym;
		int height, ulineWidth, ulinePos, slineWidth, slinePos;
		lineMetrics(gc, height, ulineWidth, ulinePos, slineWidth, slinePos);
		foreach (line; lines) {
			gc.drawText(line, x, y, true);
			if (underline || strike) {
				auto ts = gc.textExtent(line);
				if (underline) {
					gc.fillRectangle(0, y + ulinePos, ts.x, ulineWidth);
				}
				if (strike) {
					gc.fillRectangle(0, y + slinePos, ts.x, slineWidth);
				}
			}
			y += height;
		}
	}
	private void turnImpl(ImageData imgData, Turn turn) {
		auto data = cast(ubyte[]) imgData.data;
		auto alphaData = cast(ubyte[]) imgData.alphaData;
		size_t iWidth = imgData.width;
		size_t iHeight = imgData.height;
		size_t bytesPerLine = imgData.bytesPerLine;
		.turn(data, alphaData, iWidth, iHeight, bytesPerLine, turn, imgData.depth);
		imgData.data = cast(byte[]) data;
		imgData.alphaData = cast(byte[]) alphaData;
		imgData.width = iWidth;
		imgData.height = iHeight;
		imgData.bytesPerLine = bytesPerLine;
	}
	// BorderingType.Inline以外のテキストの描画を行う。
	private void drawText(ref Image buf, ref GC gc, Rectangle range) {
		auto cur = Display.getCurrent();
		auto img2 = new Image(cur, width, height);
		auto gc2 = new GC(img2);
		// 描画対象領域をコピーして下地にする
		int sx = x;
		int sy = y;
		int sw = width;
		int sh = height;
		int dx = 0;
		int dy = 0;
		if (sx < range.x) {
			dx = range.x - sx;
			sw -= dx;
			sx = range.x;
		}
		if (sy < range.y) {
			dy = range.y - sy;
			sh -= dy;
			sy = range.y;
		}
		if (range.x + range.width < sx + sw) {
			sw -= (sx + sw) - (range.x + range.width);
		}
		if (range.y + range.height < sy + sh) {
			sh -= (sy + sh) - (range.y + range.height);
		}
		gc2.drawImage(buf, sx, sy, sw, sh, dx, dy, sw, sh);
		gc2.dispose();
		auto imgData = img2.getImageData();
		img2.dispose();

		if (vertical) {
			turnImpl(imgData, Turn.RIGHT);
		}

		int alpha;
		auto borderRgb = dwtData(borderingColor, alpha);
		auto textRgb = dwtData(textColor, alpha);

		img2 = new Image(cur, imgData);
		scope (exit) img2.dispose();
		gc2 = new GC(img2);
		scope (exit) gc2.dispose();
		auto font = new Font(cur, titFont);
		scope (exit) font.dispose();
		auto borderColor = new Color(cur, borderRgb);
		scope (exit) borderColor.dispose();
		auto textColor = new Color(cur, textRgb);
		scope (exit) textColor.dispose();

		gc2.setFont(font);

		auto text = _title;
		if (_previewText) {
			text = _previewText(text);
		}
		auto lines = .splitLines(text);

		if (borderingType is BorderingType.Outline) {
			// 縁取り色で描画
			gc2.setForeground(borderColor);
			gc2.setBackground(borderColor);
			drawTextImpl(gc2, lines, -1, -1);
			drawTextImpl(gc2, lines,  0, -1);
			drawTextImpl(gc2, lines,  1, -1);
			drawTextImpl(gc2, lines, -1,  0);
			drawTextImpl(gc2, lines,  1,  0);
			drawTextImpl(gc2, lines, -1,  1);
			drawTextImpl(gc2, lines,  0,  1);
			drawTextImpl(gc2, lines,  1,  1);
		}

		// テキスト本体を描画
		gc2.setForeground(textColor);
		gc2.setBackground(textColor);
		drawTextImpl(gc2, lines,  0,  0);

		if (vertical) {
			imgData = img2.getImageData();
			img2.dispose();
			turnImpl(imgData, Turn.LEFT);
			img2 = new Image(cur, imgData);
		}

		// 元のバッファへ描き戻す
		gc.drawImage(img2, 0, 0, width, height, x, y, width, height);
	}
	private static ubyte roundColor(T)(T c) {
		return cast(ubyte) .max(0, .min(255, c));
	}
	/// カラーフィルタの描画を行う。
	private void drawFilter(ref Image buf, ref GC gc, Rectangle range) {
		auto iRect = rect.intersection(range);
		auto bMode = this.blendMode;
		if (transparent) {
			bMode = BlendMode.Mask;
		}
		ubyte calcN(int f, int t, real per) {
			if (f == t) {
				return roundColor(f);
			}
			return roundColor(f + .roundTo!int((t - f) * per));
		}

		final switch (bMode) {
		case BlendMode.Normal:
		case BlendMode.Mask:
			// 普通に描画(アルファブレンドのみ)
			auto cur = Display.getCurrent();
			int alpha;
			auto color = new Color(cur, dwtData(color1, alpha));
			scope (exit) color.dispose();

			final switch (gradientDir) {
			case GradientDir.None:
				gc.setBackground(color);
				gc.setAlpha(alpha);
				gc.fillRectangle(iRect);
				break;
			case GradientDir.LeftToRight:
			case GradientDir.TopToBottom:
				int cr = _color1.r;
				int cg = _color1.g;
				int cb = _color1.b;
				int from, width, iFrom, iWidth;
				if (gradientDir is GradientDir.LeftToRight) {
					from = this.x;
					width = this.width;
					iFrom = iRect.x;
					iWidth = iRect.width;
				} else {
					from = this.y;
					width = this.height;
					iFrom = iRect.y;
					iWidth = iRect.height;
				}
				foreach (ip; iFrom .. iFrom + iWidth) {
					int p = ip - from;
					real per = cast(real) p / width;
					ubyte r = calcN(_color1.r, _color2.r, per);
					ubyte g = calcN(_color1.g, _color2.g, per);
					ubyte b = calcN(_color1.b, _color2.b, per);
					ubyte a = calcN(_color1.a, _color2.a, per);
					if (cr != r || cg != g || cb != b) {
						color.dispose();
						color = new Color(cur, r, g, b);
					}
					gc.setAlpha(a);
					gc.setForeground(color);
					if (gradientDir is GradientDir.LeftToRight) {
						gc.drawLine(ip, iRect.y, ip, iRect.y + iRect.height);
					} else {
						gc.drawLine(iRect.x, ip, iRect.x + iRect.width, ip);
					}
				}
				break;
			}
			break;
		case BlendMode.Add:
		case BlendMode.Subtract:
		case BlendMode.Multiply:
			// 通常のGCでは対応できないため、一旦ImageDataを生成して直接編集する
			auto data = buf.getImageData();
			gc.dispose();
			buf.dispose();

			size_t bpp = data.bytesPerLine / data.width;
			auto px = Pixels(cast(ubyte[]) data.data, cast(ubyte[]) data.alphaData,
				data.width, data.height, data.depth, data.bytesPerLine, bpp);

			// グラデーション用のデータを生成
			FC fc1 = FC(cast(ubyte)_color1.r, cast(ubyte)_color1.g, cast(ubyte)_color1.b, cast(ubyte)_color1.a);
			FC[] colorLine = null;
			int from, width, iFrom, iWidth;
			final switch (gradientDir) {
			case GradientDir.None:
				break;
			case GradientDir.LeftToRight:
			case GradientDir.TopToBottom:
				if (gradientDir is GradientDir.LeftToRight) {
					from = this.x;
					width = this.width;
					iFrom = iRect.x;
					iWidth = iRect.width;
				} else {
					from = this.y;
					width = this.height;
					iFrom = iRect.y;
					iWidth = iRect.height;
				}
				colorLine = new FC[iWidth];
				foreach (ip; iFrom .. iFrom + iWidth) {
					int p = ip - from;
					real per = cast(real) p / width;
					ubyte r = calcN(_color1.r, _color2.r, per);
					ubyte g = calcN(_color1.g, _color2.g, per);
					ubyte b = calcN(_color1.b, _color2.b, per);
					ubyte a = calcN(_color1.a, _color2.a, per);
					colorLine[ip - iFrom] = FC(r, g, b, a);
				}
			}

			// このセルにおける該当箇所の色を取得
			FC color(int ix, int iy) {
				final switch (gradientDir) {
				case GradientDir.None:
					return fc1;
				case GradientDir.LeftToRight:
					return colorLine[ix - iFrom];
				case GradientDir.TopToBottom:
					return colorLine[iy - iFrom];
				}
			}

			// 色を加算または減算または乗算。
			foreach (ix; iRect.x .. iRect.x + iRect.width) {
				int x = ix - this.x;
				foreach (iy; iRect.y .. iRect.y + iRect.height) {
					int y = iy - this.y;
					auto fc = px.get(ix, iy);
					auto tfc = color(ix, iy);
					if (tfc.a == 0) continue;

					final switch (bMode) {
					case BlendMode.Normal:
					case BlendMode.Mask:
						assert (0);
					case BlendMode.Add:
						if (tfc.a != 255) {
							// アルファブレンド
							// 一般的な方式ではないが1.50の処理に合わせる
/+							fc.r = roundColor(fc.r + (tfc.r * tfc.a >>> 8));
							fc.g = roundColor(fc.g + (tfc.g * tfc.a >>> 8));
							fc.b = roundColor(fc.b + (tfc.b * tfc.a >>> 8));
+/							fc.r = roundColor((fc.r * (255 - tfc.a) >>> 8) + (roundColor(fc.r + tfc.r) * tfc.a >>> 8));
							fc.g = roundColor((fc.g * (255 - tfc.a) >>> 8) + (roundColor(fc.g + tfc.g) * tfc.a >>> 8));
							fc.b = roundColor((fc.b * (255 - tfc.a) >>> 8) + (roundColor(fc.b + tfc.b) * tfc.a >>> 8));
						} else {
							fc.r = roundColor(fc.r + tfc.r);
							fc.g = roundColor(fc.g + tfc.g);
							fc.b = roundColor(fc.b + tfc.b);
						}
						break;
					case BlendMode.Subtract:
						if (tfc.a != 255) {
							// アルファブレンド
							// 一般的な方式ではないが1.50の処理に合わせる
/+							fc.r = roundColor(fc.r - (tfc.r * tfc.a >>> 8));
							fc.g = roundColor(fc.g - (tfc.g * tfc.a >>> 8));
							fc.b = roundColor(fc.b - (tfc.b * tfc.a >>> 8));
+/							fc.r = max(roundColor(fc.r * (255 - tfc.a) >>> 8), roundColor(fc.r - (tfc.r * tfc.a >>> 8)));
							fc.g = max(roundColor(fc.g * (255 - tfc.a) >>> 8), roundColor(fc.g - (tfc.g * tfc.a >>> 8)));
							fc.b = max(roundColor(fc.b * (255 - tfc.a) >>> 8), roundColor(fc.b - (tfc.b * tfc.a >>> 8)));
						} else {
							fc.r = roundColor(fc.r - tfc.r);
							fc.g = roundColor(fc.g - tfc.g);
							fc.b = roundColor(fc.b - tfc.b);
						}
						break;
					case BlendMode.Multiply:
						if (tfc.a != 255) {
							// アルファブレンド
							tfc.r = roundColor(((tfc.r * tfc.a) + (((1 << 8) - tfc.a) << 8)) >>> 8);
							tfc.g = roundColor(((tfc.g * tfc.a) + (((1 << 8) - tfc.a) << 8)) >>> 8);
							tfc.b = roundColor(((tfc.b * tfc.a) + (((1 << 8) - tfc.a) << 8)) >>> 8);
						}
						fc.r = roundColor(fc.r * tfc.r >>> 8);
						fc.g = roundColor(fc.g * tfc.g >>> 8);
						fc.b = roundColor(fc.b * tfc.b >>> 8);
						break;
					}
					px.set(ix, iy, fc);
				}
			}

			buf = new Image(Display.getCurrent(), data);
			gc = new GC(buf);
			break;
		}
	}

	/// 画像。
	@property
	Image image() {
		return _img;
	}
	/// リサイズ前の画像。
	@property
	ImageData baseSizeData() {
		return _baseSizeData;
	}
	/// Returns: 表示するか。
	@property
	const
	bool visible() {
		return _visible;
	}
	/// Params:
	/// v = 表示するか。
	@property
	void visible(bool v) {
		_visible = v;
	}
	/// Returns: 拡大・縮小時に平滑化するか。
	@property
	const
	bool smoothing() {
		return _smoothing;
	}
	/// Params:
	/// smoothing = 平滑化するか。
	@property
	void smoothing(bool smoothing) {
		_smoothing = smoothing;
	}
	/// 透明色を使用するか。
	@property
	const
	bool transparent() {
		return t;
	}
	/// ditto
	@property
	void transparent(bool t) {
		this.t = t;
	}
	/// 透明度。0(透明)～255(不透明)。
	@property
	const
	int alpha() {return _alpha;}
	/// ditto
	@property
	void alpha(int val) {_alpha = val;}
	/// Returns: 横位置。
	@property
	const
	int x() {
		return rect.x;
	}
	/// 横位置を変更する。
	/// Params:
	/// x = 横位置。
	@property
	void x(int x) {
		rect.x = x;
	}
	/// Returns: 縦位置。
	@property
	const
	int y() {
		return rect.y;
	}
	/// 縦位置を変更する。
	/// Params:
	/// y = 縦位置。
	@property
	void y(int y) {
		rect.y = y;
	}
	/// 幅を設定する。
	/// Params:
	/// w = 幅。
	@property
	void width(int w) {
		rect.width = w;
	}
	/// Returns: 幅。
	@property
	const
	int width() {
		return rect.width;
	}

	/// 高さを設定する。
	/// Params:
	/// h = 高さ。
	@property
	void height(int h) {
		rect.height = h;
	}
	/// Returns: 高さ。
	@property
	const
	int height() {
		return rect.height;
	}

	/// 位置とサイズを設定する。
	/// Params:
	/// rect = 位置とサイズ。
	@property
	void bounds(Rectangle rect) {
		this.rect.x = rect.x;
		this.rect.y = rect.y;
		this.rect.width = rect.width;
		this.rect.height = rect.height;
	}

	/// Returns: 位置とサイズ。
	@property
	const
	Rectangle bounds() {
		return new Rectangle(x, y, width, height);
	}

	private void del(ImageData data) {
		if (_baseSizeData !is data && this.data !is data) {
			delete data.data;
			delete data.alphaData;
			delete data.maskData;
		}
	}

	/// 全てのリソースを解放する。
	void dispose() {
		void del(ImageData data) {
			delete data.data;
			delete data.alphaData;
			delete data.maskData;
		}
		foreach (a; appends) {
			if (a.data) del(a.data);
		}
		if (_imgData) del(_imgData);
		if (_baseSizeData) del(_baseSizeData);
		if (data) del(data);
		if (_img) _img.dispose();
	}
}

/// ImagePaneと組合わせて使用する移動可能な画像。
/// See_Also: ImagePane
public class FlexImage : PileImage {
private:
	void delegate(FlexImage img, int x, int y, real scale)[] lc_resizes;
	void delegate(FlexImage img, int x, int y, int w, int h)[] l_resizes;
	void delegate(FlexImage img)[] l_selected;

	int minW = 0, minH = 0;
	int maxW = 65536, maxH = 65536;
	bool s = false;
	bool whconst = false; // 縦横比を維持するか否か

	Rectangle newR;
	uint tglSize = 5;

	Rectangle[Toggle] tgls;

	bool _fixed = false;
public:
	/// 画像のファイルパス、位置、本来のサイズを指定してインスタンスを生成する。
	/// パスが存在しない場合、描画のタイミングで単に表示されない。
	/// 指定されたパスが作成された場合、再描画の際に表示される。
	/// Params:
	/// path = 画像のファイルパス。
	/// x = 横位置。
	/// y = 縦位置。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this (string path, int x, int y, int baseW, int baseH) {
		super (path, x, y, baseW, baseH);
		newR = new Rectangle(x, y, baseW, baseH);
	}
	/// 画像のデータ、位置、本来のサイズを指定してインスタンスを生成する。
	/// Params:
	/// path = 画像のデータ。
	/// x = 横位置。
	/// y = 縦位置。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this (ImageData data, int x, int y, int baseW, int baseH, bool dataResizable) {
		super (data, x, y, baseW, baseH, dataResizable);
		newR = new Rectangle(x, y, baseW, baseH);
	}

	/// テキスト表示用のインスタンスを生成する。
	this (string text, string fontName, int size, CRGB color,
			bool bold, bool italic, bool underline, bool strike, bool vertical,
			BorderingType borderingType, CRGB borderingColor, uint borderingWidth,
			int x, int y, int baseW, int baseH) {
		super (text, fontName, size, color, bold, italic, underline, strike, vertical,
			borderingType, borderingColor, borderingWidth, x, y, baseW, baseH);
		newR = new Rectangle(x, y, baseW, baseH);
	}
	/// カラーフィルタ用のインスタンスを生成する。
	this (BlendMode blendMode, GradientDir gradientDir, CRGB color1, CRGB color2,
			int x, int y, int baseW, int baseH) {
		super (ImageType.ColorFilter, x, y, baseW, baseH);
		newR = new Rectangle(x, y, baseW, baseH);
		this.blendMode = blendMode;
		this.gradientDir = gradientDir;
		this.color1 = color1;
		this.color2 = color2;
	}

	/// Returns: 最小の幅。初期値は1。
	@property
	const
	int minimumWidth() {
		return minW;
	}
	/// Params:
	/// minW = 最小の幅。
	@property
	void minimumWidth(int minW) {
		this.minW = minW;
	}
	/// Returns: 最小の高さ。初期値は1。
	@property
	const
	int minimumHeight() {
		return minH;
	}
	/// Params:
	/// minW = 最小の高さ。
	@property
	void minimumHeight(int minH) {
		this.minH = minH;
	}
	/// Returns: 最大の幅。初期値は65536。
	@property
	const
	int maximumWidth() {
		return maxW;
	}
	/// Params:
	/// minW = 最大の幅。
	@property
	void maximumWidth(int maxW) {
		this.maxW = maxW;
	}
	/// Returns: 最大の高さ。初期値は65536。
	@property
	const
	int maximumHeight() {
		return maxH;
	}
	/// Params:
	/// minW = 最大の高さ。
	@property
	void maximumHeight(int maxH) {
		this.maxH = maxH;
	}
	/// 縦横比固定か。
	@property
	const
	bool ratioFix() {
		return whconst;
	}
	/// ditto
	@property
	void ratioFix(bool whconst) {
		this.whconst = whconst;
	}
	/// サイズ・位置固定モードか。
	@property
	const
	bool fixed() {return _fixed;}
	/// ditto
	@property
	void fixed(bool value) {
		_fixed = value;
		if (value) {
			reset();
		} else {
			retoggle();
		}
	}
	/// サイズ変更/移動更作業を終えてサイズ/位置を確定し、画像をその位置に配置する。
	/// 配置後、createImage()が実行される。
	/// See_Also: createImage();
	void resize(bool callListeners = true) {
		bool resize = bounds.width != newR.width || bounds.height != newR.height;
		bounds = newR;
		if (callListeners) {
			foreach (l; l_resizes) {
				l(this, x, y, width, height);
			}
			foreach (l; lc_resizes) {
				l(this, x, y, cast(real) width / initW);
			}
		}
		if (!_img || (resize && _dataResizable)) createImage();
		retoggle();
	}
	/// サイズと移動の仮設定を最初の状態に戻す。
	void reset() {
		newR.x = x;
		newR.y = y;
		newR.width = width;
		newR.height = height;
		retoggle();
	}
	/// トグルを描画する。
	void drawToggle(GC gc) {
		if (visible && selected) {
			gc.setBackground(Display.getCurrent().getSystemColor(SWT.COLOR_WHITE));
			gc.setForeground(Display.getCurrent().getSystemColor(SWT.COLOR_BLACK));
			gc.drawFocus(newX, newY, newWidth, newHeight);
			foreach (rect; tgls.values) {
				gc.fillRectangle(rect.x + 1, rect.y + 1, tglSize - 1, tglSize - 1);
				gc.drawRectangle(rect);
			}
		}
	}

	/// Returns: 選択中か。
	@property
	const
	bool selected() {
		return s;
	}
	/// Params:
	/// s = 選択状態。
	@property
	private void selected(bool s) {
		this.s = s;
	}
	private void doSelected(bool s) {
		selected = s;
		foreach (func; l_selected) {
			func(this);
		}
	}
	/// Returns: 仮の横位置。
	@property
	const
	int newX() {
		return newR.x;
	}
	/// 横位置を仮に変更する。確定するにはresize()を使用。
	/// Params:
	/// x = 横位置。
	/// See_Also: resize()
	@property
	void newX(int x) {
		newR.x = x;
		retoggle();
	}
	/// Returns: 仮の縦位置。
	@property
	const
	int newY() {
		return newR.y;
	}
	/// 縦位置を仮に変更する。確定するにはresize()を使用。
	/// Params:
	/// y = 縦位置。
	/// See_Also: resize()
	@property
	void newY(int y) {
		newR.y = y;
		retoggle();
	}
	/// 幅を設定可能な値に丸めて返す。
	/// 縦横比固定の影響を受けない。
	const
	int roundMWidth(int w) {
		w = minW > w ? minW : w;
		w = maxW < w ? maxW : w;
		return w;
	}
	/// 幅を設定可能な値に丸めて返す。
	/// Params:
	/// w = 幅。
	/// Returns: 丸めた幅。
	const
	int roundWidth(int w) {
		if (whconst) {
			// 縦横比固定
			real scale = newHeight / cast(real) initH;
			return cast(int) rndtol(initW * scale);
		} else {
			return roundMWidth(w);
		}
	}
	/// Returns: 仮の幅。
	@property
	const
	int newWidth() {
		return newR.width;
	}
	/// 幅を仮に設定する。確定するにはresize()を使用。
	/// Params:
	/// w = 幅。
	@property
	void newWidth(int w) {
		newR.width = roundMWidth(w);
		newR.height = roundHeight(newR.height);
		retoggle();
	}
	/// 高さを設定可能な値に丸めて返す。
	/// 縦横比固定の影響を受けない。
	const
	int roundMHeight(int h) {
		h = minH > h ? minH : h;
		h = maxH < h ? maxH : h;
		return h;
	}
	/// 高さを設定可能な値に丸めて返す。
	/// Params:
	/// h = 高さ。
	/// Returns: 丸めた高さ。
	const
	int roundHeight(int h) {
		if (whconst) {
			// 縦横比固定
			real scale = newWidth / cast(real) initW;
			return cast(int) rndtol(initH * scale);
		} else {
			return roundMHeight(h);
		}
	}
	/// Returns: 仮の高さ。
	@property
	const
	int newHeight() {
		return newR.height;
	}
	/// 高さを仮に設定する。確定するにはresize()を使用。
	/// Params:
	/// h = 高さ。
	@property
	void newHeight(int h) {
		newR.height = roundMHeight(h);
		newR.width = roundWidth(newR.width);
		retoggle();
	}
	/// 位置とサイズを仮に設定する。確定するにはresize()を使用。
	/// Params:
	/// rect = 位置とサイズ。
	@property
	void newBounds(Rectangle rect) {
		newR.x = rect.x;
		newR.y = rect.y;
		if (newR.width >= newR.height) {
			newR.width = roundMWidth(rect.width);
			newR.height = roundHeight(rect.height);
		} else {
			newR.height = roundMHeight(rect.height);
			newR.width = roundWidth(rect.width);
		}
		retoggle();
	}
	/// スケールを指定してサイズを設定する。
	/// Params:
	/// scale = 元のサイズに対するスケール
	@property
	void scale(real scale) {
		newR.width = cast(int) rndtol(initW * scale);
		newR.height = roundHeight(cast(int) rndtol(initH * rect.height));
		retoggle();
	}
	/// Returns: 仮の位置とサイズ。
	@property
	const
	Rectangle newBounds() {
		return new Rectangle(newR.x, newR.y, newR.width, newR.height);
	}

	/// 指定されたポイントが画像内、あるいはトグルの内部であればその値を返す。
	/// 画像外であればToggle.NONEを返す。
	/// Params:
	/// x = 横位置。
	/// y = 縦位置。
	/// Returns: トグル。
	const
	Toggle inToggle(int x, int y, bool move) {
		foreach (key; tgls.keys) {
			auto rect = tgls[key];
			if (rect.x <= x && x <= (rect.x + rect.width)
					&& rect.y <= y && y <= (rect.y + rect.height)) {
				return key;
			}
		}
		if (move && this.x <= x && x <= (this.x + this.width)
				&& this.y <= y && y <= (this.y + this.height)) {
			return Toggle.MOVE;
		} else {
			return Toggle.NONE;
		}
	}

	/// サイズ変更のトグル。
	Toggle[] RESIZE_TOGGLES = [
		Toggle.LEFT_TOP, Toggle.LEFT_MIDDLE, Toggle.LEFT_BOTTOM,
		Toggle.MIDDLE_TOP, Toggle.MIDDLE_BOTTOM,
		Toggle.RIGHT_TOP, Toggle.RIGHT_MIDDLE, Toggle.RIGHT_BOTTOM
	];

	private void retoggle() {
		if (fixed) {
			typeof(this.tgls) tgls;
			this.tgls = tgls;
		} else {
			Toggle[] tgls = RESIZE_TOGGLES;
			foreach (key; this.tgls.keys) {
				this.tgls.remove(key);
			}
			foreach (tgl; tgls) {
				this.tgls[tgl] = toggleRect(tgl);
			}
		}
	}

	const
	private Rectangle toggleRect(Toggle tgl) {
		int tglX;
		int tglY;
		int tglWidth = tglSize;
		int tglHeight = tglSize;
		final switch (tgl) {
		case Toggle.LEFT_TOP, Toggle.LEFT_MIDDLE, Toggle.LEFT_BOTTOM:
			tglX = newX - tglSize + (tglSize / 2);
			break;
		case Toggle.MIDDLE_TOP, Toggle.MIDDLE_BOTTOM:
			tglX = newX + (newWidth / 2) - (tglSize / 2);
			break;
		case Toggle.RIGHT_TOP, Toggle.RIGHT_MIDDLE, Toggle.RIGHT_BOTTOM:
			tglX = newX + newWidth - (tglSize / 2) - 1;
			break;
		case Toggle.MOVE, Toggle.NONE:
			break;
		}
		final switch (tgl) {
		case Toggle.LEFT_TOP, Toggle.MIDDLE_TOP, Toggle.RIGHT_TOP:
			tglY = newY - tglSize + (tglSize / 2);
			break;
		case Toggle.LEFT_MIDDLE, Toggle.RIGHT_MIDDLE:
			tglY = newY + (newHeight / 2) - (tglSize / 2);
			break;
		case Toggle.LEFT_BOTTOM, Toggle.RIGHT_BOTTOM, Toggle.MIDDLE_BOTTOM:
			tglY = newY + newHeight - (tglSize / 2) - 1;
			break;
		case Toggle.MOVE, Toggle.NONE:
			break;
		}
		return new Rectangle(tglX, tglY, tglWidth, tglHeight);
	}

	/// 移動後に描画する領域を返す。
	/// Returns: 描画する領域。
	@property
	const
	Rectangle drawNewArea() {
		if (fixed) {
			return new Rectangle(newR.x - 1, newR.y - 1, newR.width + 2, newR.height + 2);
		} else {
			return new Rectangle(newR.x - tglSize, newR.y - tglSize,
				newR.width + tglSize * 2, newR.height + tglSize * 2);
		}
	}
	/// 描画する領域を返す。
	/// Returns: 描画する領域。
	@property
	const
	Rectangle drawArea() {
		auto r = bounds;
		if (fixed) return r;
		return new Rectangle(r.x - tglSize, r.y - tglSize,
			r.width + tglSize * 2, r.height + tglSize * 2);
	}

	/// リサイズの確定時に呼び出す関数を追加する。
	/// Params:
	/// サイズ確定時に呼び出す関数。
	void addResizeListener(void delegate(FlexImage img, int x, int y, int w, int h) func) {
		l_resizes ~= func;
	}
	/// ditto
	void addResizeListener(void delegate(FlexImage img, int x, int y, real scale) func) {
		lc_resizes ~= func;
	}
	/// 選択状態変更時に呼び出す関数を追加する。
	/// Params:
	/// 選択状態変更時に呼び出す関数。
	void addSelectionListener(void delegate(FlexImage img) func) {
		l_selected ~= func;
	}

	/// 全てのリソースを解放する。
	override
	void dispose() {
		super.dispose();
	}
}

/// FlexImageと組合わせて柔軟に操作可能な画像を表示するパネル。
/// See_Also: FlexImage
public class ImagePane : Canvas, NoIME {
private:
	/// トグルごとのカーソル。
	Cursor[Toggle] toggleCursors;

	/// トグルに応じたカーソルを返す。
	/// Params:
	/// tgl = トグル。
	/// Returns:
	/// サイズ変更が行える場合はその方向を示すカーソル、
	/// 移動が行える場合は手型のカーソル、それ以外の場合は通常のカーソル。
	Cursor getToggleCursor(Toggle tgl) {
		return toggleCursors[tgl];
	}

	Rectangle[FlexImage] dragImgs;
	Toggle dragTgl = Toggle.NONE;
	int dragStartX, dragStartY;
	bool moved = false;
	WallpaperStyle _wallpaperStyle = WallpaperStyle.Tile;

	PileImage[] backs = [];
	Image[] _appends = [];
	bool _showAppends = true;

	int _gridX = 0, _gridY = 0;
	int _gridRange = 5;
	int[] _gridXH = [];
	int[] _gridYH = [];

	/// 背景。壁紙まで描画済みのImageData。
	ImageData _background = null;
	Image _lastWallpaper = null;
	Rectangle _lastClientArea = null;

	class DListener : DisposeListener {
		public override void widgetDisposed(DisposeEvent e)  {
			foreach (img; backs) {
				img.dispose();
			}
		}
	}
	class KListener : KeyAdapter {
		override void keyPressed(KeyEvent ke) {
			int point = (ke.stateMask & SWT.CTRL) && (ke.stateMask & SWT.ALT) ? 10 : 1;
			switch (ke.keyCode) {
			case SWT.ARROW_UP: {
				redrawProcMove((FlexImage img) {
					if (ke.stateMask & SWT.SHIFT) {
						img.newHeight = img.newHeight - point;
					} else {
						img.newY = img.newY - point;
					}
				}, false);
			} break;
			case SWT.ARROW_RIGHT: {
				redrawProcMove((FlexImage img) {
					if (ke.stateMask & SWT.SHIFT) {
						img.newWidth = img.newWidth + point;
					} else {
						img.newX = img.newX + point;
					}
				}, false);
			} break;
			case SWT.ARROW_DOWN: {
				redrawProcMove((FlexImage img) {
					if (ke.stateMask & SWT.SHIFT) {
						img.newHeight = img.newHeight + point;
					} else {
						img.newY = img.newY + point;
					}
				}, false);
			} break;
			case SWT.ARROW_LEFT: {
				redrawProcMove((FlexImage img) {
					if (ke.stateMask & SWT.SHIFT) {
						img.newWidth = img.newWidth - point;
					} else {
						img.newX = img.newX - point;
					}
				}, false);
			} break;
			case SWT.ESC: {
				redrawProcMove((FlexImage img) {img.reset();}, false);
			} break;
			case SWT.CR: {
				redrawProc((FlexImage img) {img.resize();}, true);
			} break;
			default: {
				if (ke.character == ' ') {
					redrawProc((FlexImage img) {img.resize();}, true);
				}
			} break;
			}
		}
	}
	int toGridX(int p) {
		if (1 < _gridX) {
			p += _gridX / 2.0;
			p = p - (p % _gridX);
		}
		return p;
	}
	int toGridY(int p) {
		if (1 < _gridY) {
			p += _gridY / 2.0;
			p = p - (p % _gridY);
		}
		return p;
	}
	void redrawGridHighlight() {
		auto size = getSize();
		foreach (x; _gridXH) {
			redraw(x, 0, 1, size.y, false);
		}
		foreach (y; _gridYH) {
			redraw(0, y, size.x, 1, false);
		}
	}
	void resetGrid() {
		redrawGridHighlight();
		_gridXH = [];
		_gridYH = [];
	}
	void redrawGrid(in Rectangle rect) {
		if (1 < _gridX) {
			int r = rect.x + rect.width;
			if (rect.x == toGridX(rect.x)) _gridXH ~= rect.x;
			if (r == toGridX(r)) _gridXH ~= r;
		}
		if (1 < _gridY) {
			int b = rect.y + rect.height;
			if (rect.y == toGridY(rect.y)) _gridYH ~= rect.y;
			if (b == toGridY(b)) _gridYH ~= b;
		}
	}
	class MMListener : MouseMoveListener {
		override void mouseMove(MouseEvent me) {
			int x = me.x;
			int y = me.y;
			if (dragTgl != Toggle.NONE) {
				assert (_mouseP !is null);
				if (_ctrl && _mouseP) {
					doSelect(_mouseP);
				}
				int movX = x - dragStartX;
				int movY = y - dragStartY;
				bool ratioFix = (me.stateMask & SWT.SHIFT) != 0;
				resetGrid();
				foreach (img; dragImgs.keys) {
					if (img.selected && !img.fixed && img.visible) {
						auto rect = dragImgs[img];
						auto newRect = new Rectangle(img.x, img.y, img.width, img.height);
						switch (dragTgl) {
						case Toggle.LEFT_TOP, Toggle.LEFT_MIDDLE, Toggle.LEFT_BOTTOM:
							int w = rect.width - movX;
							newRect.width = img.roundMWidth(w);
							break;
						case Toggle.RIGHT_TOP, Toggle.RIGHT_MIDDLE, Toggle.RIGHT_BOTTOM:
							int w = rect.width + movX;
							newRect.width = img.roundMWidth(w);
							break;
						default:
							break;
						}
						switch (dragTgl) {
						case Toggle.LEFT_TOP, Toggle.MIDDLE_TOP, Toggle.RIGHT_TOP:
							int h = rect.height - movY;
							newRect.height = img.roundMHeight(h);
							break;
						case Toggle.LEFT_BOTTOM, Toggle.MIDDLE_BOTTOM, Toggle.RIGHT_BOTTOM:
							int h = rect.height + movY;
							newRect.height = img.roundMHeight(h);
							break;
						default:
							break;
						}
						void roundH() {
							real scale = newRect.width / cast(real) img.width;
							newRect.height = cast(int) rndtol(img.height * scale);
						}
						void roundW() {
							real scale = newRect.height / cast(real) img.height;
							newRect.width = cast(int) rndtol(img.width * scale);
						}
						/// 縦横比固定のための調整。
						void round(void delegate() roundW, void delegate() roundH) {
							if (ratioFix || img.ratioFix) {
								// イメージ自体が縦横比固定でない場合、トグルによっては縦横比の変更を許可する
								switch (dragTgl) {
								case Toggle.LEFT_MIDDLE, Toggle.RIGHT_MIDDLE:
									if (img.ratioFix) roundH();
									break;
								case Toggle.MIDDLE_TOP, Toggle.MIDDLE_BOTTOM:
									if (img.ratioFix) roundW();
									break;
								default:
									// 元のサイズによって縦横の優先順を変更
									if (rect.width >= rect.height) {
										roundH();
									} else {
										roundW();
									}
								}
							}
						}
						round(&roundW, &roundH);
						switch (dragTgl) {
						case Toggle.LEFT_TOP, Toggle.MIDDLE_TOP, Toggle.RIGHT_TOP:
							newRect.y = (rect.y + rect.height) - newRect.height;
							break;
						case Toggle.MOVE:
							newRect.y = rect.y + movY;
							break;
						default:
							break;
						}
						switch (dragTgl) {
						case Toggle.LEFT_TOP, Toggle.LEFT_MIDDLE, Toggle.LEFT_BOTTOM:
							newRect.x = (rect.x + rect.width) - newRect.width;
							break;
						case Toggle.MOVE:
							newRect.x = rect.x + movX;
							break;
						default:
							break;
						}
						if (1 < _gridX || 1 < _gridY) {
							if (dragTgl is Toggle.MOVE) {
								int gx = toGridX(newRect.x);
								int gy = toGridY(newRect.y);
								int r = newRect.x + newRect.width;
								int b = newRect.y + newRect.height;
								int gr = toGridX(r);
								int gb = toGridY(b);
								if (.abs(gx - newRect.x) <= .abs(gr - r)) {
									if (.abs(gx - newRect.x) <= _gridRange) newRect.x = gx;
								} else {
									if (.abs(gr - r) <= _gridRange) newRect.x = gr - newRect.width;
								}
								if (.abs(gy - newRect.y) <= .abs(gb - b)) {
									if (.abs(gy - newRect.y) <= _gridRange) newRect.y = gy;
								} else {
									if (.abs(gb - b) <= _gridRange) newRect.y = gb - newRect.height;
								}
							} else {
								@property
								bool isLeft() {
									return dragTgl is Toggle.LEFT_TOP || dragTgl is Toggle.LEFT_MIDDLE || dragTgl is Toggle.LEFT_BOTTOM;
								}
								@property
								bool isTop() {
									return dragTgl is Toggle.LEFT_TOP || dragTgl is Toggle.MIDDLE_TOP || dragTgl is Toggle.RIGHT_TOP;
								}
								@property
								bool isRight() {
									return dragTgl is Toggle.RIGHT_TOP || dragTgl is Toggle.RIGHT_MIDDLE || dragTgl is Toggle.RIGHT_BOTTOM;
								}
								@property
								bool isBottom() {
									return dragTgl is Toggle.LEFT_BOTTOM || dragTgl is Toggle.MIDDLE_BOTTOM || dragTgl is Toggle.RIGHT_BOTTOM;
								}
								int r = newRect.x + newRect.width;
								int b = newRect.y + newRect.height;
								if (isLeft) {
									int gx = toGridX(newRect.x);
									if (.abs(newRect.x - gx) <= _gridRange) {
										newRect.width += newRect.x - gx;
										newRect.x = gx;
									}
								}
								if (isRight) {
									int gr = toGridX(newRect.x + newRect.width);
									if (.abs(r - gr) <= _gridRange) {
										newRect.width = gr - newRect.x;
									}
								}
								if (isTop) {
									int gy = toGridY(newRect.y);
									if (.abs(newRect.y - gy) <= _gridRange) {
										newRect.height += newRect.y - gy;
										newRect.y = gy;
									}
								}
								if (isBottom) {
									int gb = toGridY(newRect.y + newRect.height);
									if (.abs(b - gb) <= _gridRange) {
										newRect.height = gb - newRect.y;
									}
								}

								void roundH2() {
									if (isLeft) newRect.x = r - newRect.width;
									roundH();
									if (isTop) newRect.y = b - newRect.height;
								}
								void roundW2() {
									if (isTop) newRect.y = b - newRect.height;
									roundW();
									if (isLeft) newRect.x = r - newRect.width;
								}
								round(&roundW2, &roundH2);
							}
							redrawGrid(newRect);
						}

						scope oldArea = img.drawNewArea;
						img.newBounds = newRect;
						scope newArea = img.drawNewArea;
						redraw(oldArea.x, oldArea.y, oldArea.width, oldArea.height, false);
						redraw(newArea.x, newArea.y, newArea.width, newArea.height, false);
					}
				}
				redrawGridHighlight();
				moved = true;
			} else {
				// サイズ変更は下に隠れているセルでも優先的に受け付ける
				foreach (move; [false, true]) {
					foreach_reverse (pimg; backs) {
						if (cast(FlexImage) pimg && pimg.visible) {
							auto img = cast(FlexImage) pimg;
							Toggle tgl = img.inToggle(x, y, move);
							if (tgl != Toggle.NONE) {
								setCursor(getToggleCursor(tgl));
								return;
							}
						}
					}
				}
				setCursor(getToggleCursor(Toggle.NONE));
			}
		}
	}

	class MouseDown : Listener {
		override void handleEvent(Event me) {
			setFocus();
			moved = false;
			_ctrl = (me.stateMask & SWT.SHIFT) != 0 || (me.stateMask & SWT.CTRL) != 0;
			int x = me.x;
			int y = me.y;
			if (me.button == 1) {
				foreach (img, rect; dragImgs) {
					dragImgs[img] = new Rectangle(img.x, img.y, img.width, img.height);
				}
				dragStartX = x;
				dragStartY = y;
				auto tgl = Toggle.NONE;
				FlexImage img = null;
				foreach (move; [false, true]) {
					if (tgl !is Toggle.NONE) break;
					foreach_reverse (i, pimg; backs) {
						if (cast(FlexImage) pimg) {
							img = cast(FlexImage) pimg;
							if (img.visible) {
								tgl = img.inToggle(x, y, move);
								if (tgl !is Toggle.NONE) {
									break;
								}
							}
						}
					}
				}
				if (tgl !is Toggle.NONE) {
					_mouseP = img;
					if (me.button == 1) {
						if (!_ctrl) {
							if (!img.selected) doDeselectAll();
							doSelect(img);
						}
						dragTgl = tgl;
					} else if (me.button == 3) {
						if (!img.selected) doDeselectAll();
						doSelect(img);
					}
					return;
				}
				doDeselectAll();
				_mouseP = null;
			} else if (me.button == 2) {
				auto ids = selectedIndices;
				if (ids.length == 0 || !changeSelect(x, y)) {
					int i = findIndex(x, y);
					if (i >= 0) {
						doDeselectAll();
						doSelect(cast(FlexImage) images[i]);
					}
				}
			} else if (me.button == 3) {
				dragTgl = Toggle.NONE;
				resetGrid();
				redrawProc((FlexImage img) {img.reset();}, false);
			}
		}
	}
	void redrawProcBefore() {
		foreach (img; dragImgs.keys) {
			if (img.x != img.newX || img.y != img.newY || img.width != img.newWidth || img.height != img.newHeight) {
				callChangingImages();
			}
		}
	}
	void redrawProcMove(void delegate(FlexImage) proc, bool resize) {
		if (resize) redrawProcBefore();
		foreach (img; dragImgs.keys) {
			auto oldArea = img.drawNewArea;
			proc(img);
			auto newArea = img.drawNewArea;
			redraw(oldArea.x, oldArea.y, oldArea.width, oldArea.height, false);
			redraw(newArea.x, newArea.y, newArea.width, newArea.height, false);
		}
	}
	void redrawProc(void delegate(FlexImage) proc, bool resize) {
		if (resize) redrawProcBefore();
		foreach (img; dragImgs.keys) {
			auto oldArea = img.drawArea;
			proc(img);
			auto newArea = img.drawNewArea;
			redraw(oldArea.x, oldArea.y, oldArea.width, oldArea.height, false);
			redraw(newArea.x, newArea.y, newArea.width, newArea.height, false);
		}
	}
	class FocusLost : Listener {
		override void handleEvent(Event me) {
			dragTgl = Toggle.NONE;
			resetGrid();
			redrawProc((FlexImage img) {img.resize();}, true);
		}
	}
	class MouseUp : Listener {
		override void handleEvent(Event me) {
			int x = me.x;
			int y = me.y;
			if (me.button == 1) {
				bool ci = false;
				foreach_reverse (i, pimg; backs) {
					auto img = cast(FlexImage) pimg;
					if (img && img.selected) {
						scope oldRect = img.bounds;
						if (oldRect != img.newBounds) {
							if (!ci) {
								callChangingImages();
								ci = true;
							}
							img.resize();
							scope area = img.drawNewArea;
							redraw(oldRect.x, oldRect.y, oldRect.width, oldRect.height, false);
							redraw(area.x, area.y, area.width, area.height, false);
							dragImgs[img] = new Rectangle(img.x, img.y, img.width, img.height);
						}
					}
				}
				if (!moved && _mouseP) {
					if (_ctrl) {
						if (_mouseP.selected) {
							doDeselect(_mouseP);
						} else {
							doSelect(_mouseP);
						}
					} else {
						doDeselectAll();
						doSelect(_mouseP);
					}
				}
			}
			dragTgl = Toggle.NONE;
			resetGrid();
			moved = false;
			_mouseP = null;
		}
	}
	bool _ctrl = false;
	FlexImage _mouseP = null;
	void __setSelected(FlexImage img) {
		if (img.selected) {
			dragImgs[img] = new Rectangle(img.x, img.y, img.width, img.height);
			auto area = img.drawArea;
			redraw(area.x, area.y, area.width, area.height, false);
		}
	}
	class PListener : PaintListener {
		override void paintControl(PaintEvent e) {
			auto d = getShell().getDisplay();
			auto backImg = getBackgroundImage();
			auto rect = getClientArea();
			if (!_background || backImg !is _lastWallpaper || rect != _lastClientArea) {
				// 背景の初期化
				auto buf = new Image(d, rect.width, rect.height);
				auto gc = new GC(buf);
				scope (exit) gc.dispose();
				scope (exit) buf.dispose();

				if (_backColor) {
					gc.setBackground(_backColor);
					gc.fillRectangle(rect.x, rect.y, rect.width, rect.height);
				} else {
					gc.setBackground(d.getSystemColor(SWT.COLOR_DARK_BLUE));
					gc.fillRectangle(rect.x, rect.y, rect.width, rect.height);
				}
				if (backImg) {
					drawWallpaper(gc, backImg, rect, _wallpaperStyle);
				}
				_background = buf.getImageData();
				_lastWallpaper = backImg;
				_lastClientArea = rect;
			}

			auto imageData = cast(ImageData)_background.clone();
			scope (exit) delete imageData.data;
			auto range = new Rectangle(e.x, e.y, e.width, e.height);
			auto buf = new Image(d, imageData);
			auto gc = new GC(buf);
			foreach (bmp; backs) {
				bmp.draw(buf, gc, range);
			}
			foreach (bmp; backs) {
				auto fi = cast(FlexImage) bmp;
				if (fi) fi.drawToggle(gc);
			}
			if (_showAppends) {
				foreach (a; _appends) {
					gc.drawImage(a, 0, 0);
				}
			}

			if (1 < _gridX || 1 < _gridY) {
				gc.dispose();
				gc = new GC(buf);
				void drawLines() {
					if (1 < _gridX) {
						int x = _gridX;
						while (x < rect.width) {
							gc.drawLine(x, rect.y, x, rect.height);
							x += _gridX;
						}
					}
					if (1 < _gridY) {
						int y = _gridY;
						while (y < rect.height) {
							gc.drawLine(rect.x, y, rect.width, y);
							y += _gridY;
						}
					}
				}
				void drawHLines() {
					if (1 < _gridX) {
						foreach (x; _gridXH) {
							gc.drawLine(x, rect.y, x, rect.height);
						}
					}
					if (1 < _gridY) {
						foreach (y; _gridYH) {
							gc.drawLine(rect.x, y, rect.width, y);
						}
					}
				}
				gc.setForeground(_gridColor ? _gridColor : d.getSystemColor(SWT.COLOR_DARK_GRAY));
				gc.setLineStyle(SWT.LINE_DOT);
				drawLines();
				if (_gridXH.length || _gridYH.length) {
					gc.setForeground(_gridHighlightColor ? _gridHighlightColor : d.getSystemColor(SWT.COLOR_GRAY));
					gc.setLineStyle(SWT.LINE_SOLID);
					drawHLines();
				}
			}
			gc.dispose();

			e.gc.drawImage(buf, 0, 0);
			buf.dispose();
		}
	}
	class Traverse : Listener {
		public override void handleEvent(Event e) {
			switch (e.detail) {
			case SWT.TRAVERSE_ARROW_NEXT, SWT.TRAVERSE_ARROW_PREVIOUS:
				e.doit = false;
				break;
			default:
				e.doit = true;
			}
		}
	}

	/// 選択イメージが一つだけの場合、背後のイメージに切り替える。
	bool changeSelect(int x, int y) {
		auto tsels = findSelectedIndices(x, y);
		auto imgs = findIndices(x, y);
		if (tsels.length == 1 && selectedIndices.length == 1 && imgs.length > 1) {
			int i = countUntil(imgs, tsels[0]);
			assert (i >= 0);
			doDeselect(cast(FlexImage) images[tsels[0]]);
			doSelect(cast(FlexImage) images[i > 0 ? imgs[i - 1] : imgs[$ - 1]]);
			return true;
		}
		return false;
	}

	private Color _backColor = null;
	private Color _gridColor = null, _gridHighlightColor = null;
public:
	void setBackgroundColor2(Color backColor) {_backColor = backColor;}
	Color getBackgroundColor2() {return _backColor;}
	@property
	void gridColor(Color v) {_gridColor = v;}
	@property
	Color gridColor() {return _gridColor;}
	@property
	void gridHighlightColor(Color v) {_gridHighlightColor = v;}
	@property
	Color gridHighlightColor() {return _gridHighlightColor;}

	@property
	PileImage[] images() {
		return backs;
	}
	@property
	const
	const(PileImage)[] images() {
		return backs;
	}

	void swap(int index1, int index2) {
		auto temp = backs[index1];
		backs[index1] = backs[index2];
		backs[index2] = temp;
	}

	@property
	void select(FlexImage[] imgs) {
		foreach (img; imgs) {
			select(img);
		}
	}
	@property
	void select(FlexImage img) {
		if (!img.selected) {
			img.selected = true;
			__setSelected(img);
		}
	}
	@property
	void select(int[] indices) {
		deselectAll();
		foreach (i; indices) {
			auto fi = cast(FlexImage) backs[i];
			select(fi);
		}
	}
	private void doSelect(FlexImage img) {
		if (!img.selected) {
			img.doSelected(true);
			__setSelected(img);
		}
	}
	void deselect(FlexImage img) {
		if (img.selected) {
			img.selected = false;
			deselAfter(img);
		}
	}
	private void doDeselect(FlexImage img) {
		if (img.selected) {
			img.doSelected(false);
			deselAfter(img);
		}
	}
	private void deselAfter(FlexImage img) {
		removeDragImage(img);
		auto area = img.drawArea;
		redraw(area.x, area.y, area.width, area.height, false);
	}
	private void doDeselectAll() {
		foreach_reverse (pimg; backs) {
			auto img = cast(FlexImage) pimg;
			if (img) doDeselect(img);
		}
	}
	void deselectAll() {
		foreach_reverse (pimg; backs) {
			auto img = cast(FlexImage) pimg;
			if (img) deselect(img);
		}
	}
	void deselectRange(int from, int to) {
		for (int i = from; i < to; i++) {
			auto img = cast(FlexImage) backs[i];
			if (img) deselect(img);
		}
	}
	@property
	int[] selectedIndices() {
		int[] r;
		foreach (i, img; backs) {
			auto fi = cast(FlexImage) img;
			if (fi && fi.selected) r ~= i;
		}
		return r;
	}
	@property
	int selectedIndex() {
		foreach_reverse (i, img; backs) {
			auto fi = cast(FlexImage) img;
			if (fi && fi.selected) return i;
		}
		return -1;
	}
	int findIndex(int x, int y) {
		foreach_reverse (i, img; backs) {
			auto fi = cast(FlexImage) img;
			if (fi && fi.visible && fi.bounds.contains(x, y)) return i;
		}
		return -1;
	}
	int[] findIndices(int x, int y) {
		int[] r;
		foreach (i, img; backs) {
			auto fi = cast(FlexImage) img;
			if (fi && fi.visible && fi.bounds.contains(x, y)) r ~= i;
		}
		return r;
	}
	int findSelectedIndex(int x, int y) {
		foreach_reverse (i, img; backs) {
			auto fi = cast(FlexImage) img;
			if (fi && fi.visible && fi.selected && fi.bounds.contains(x, y)) return i;
		}
		return -1;
	}
	int[] findSelectedIndices(int x, int y) {
		int[] r;
		foreach (i, img; backs) {
			auto fi = cast(FlexImage) img;
			if (fi && fi.visible && fi.selected && fi.bounds.contains(x, y)) r ~= i;
		}
		return r;
	}

	private void removeDragImage(PileImage img) {
		auto fi = cast(FlexImage) img;
		if (fi && (fi in dragImgs)) {
			dragImgs.remove(fi);
		}
	}

	void fixedRange(bool fixed, int from, int to) {
		foreach (img; images[from .. to]) {
			auto fi = cast(FlexImage) img;
			if (fi) {
				auto newArea = fi.drawNewArea;
				auto oldArea = fi.drawArea;
				fi.fixed = fixed;
				redraw(oldArea.x, oldArea.y, oldArea.width, oldArea.height, false);
				redraw(newArea.x, newArea.y, newArea.width, newArea.height, false);
			}
		}
	}

	void remove(int index) {
		backs[index].dispose();
		removeDragImage(backs[index]);
		backs = backs[0 .. index] ~ backs[index + 1 .. $];
	}

	void removeRange(int fromIndex, int toIndex) {
		for (int i = fromIndex; i < toIndex; i++) {
			backs[i].dispose();
			removeDragImage(backs[i]);
		}
		backs = backs[0 .. fromIndex] ~ backs[toIndex .. $];
	}

	void insert(int index, PileImage img) {
		if (index == backs.length) {
			append(img);
		} else {
			backs = backs[0 .. index] ~ img ~ backs[index .. $];
			if (cast(FlexImage) img) __setSelected(cast(FlexImage) img);
		}
	}
	void insert(int index, PileImage[] imgs) {
		if (index == backs.length) {
			append(imgs);
		} else {
			backs = backs[0 .. index] ~ imgs ~ backs[index .. $];
			foreach (img; imgs) {
				if (cast(FlexImage) img) __setSelected(cast(FlexImage) img);
			}
		}
	}
	void set(int index, PileImage img) {
		backs[index].dispose();
		removeDragImage(backs[index]);
		this.backs[index] = img;
		if (cast(FlexImage) img) __setSelected(cast(FlexImage) img);
	}
	void append(PileImage img) {
		this.backs ~= img;
		if (cast(FlexImage) img) __setSelected(cast(FlexImage) img);
	}
	void append(PileImage[] imgs) {
		this.backs ~= imgs;
		foreach (img; imgs) {
			if (cast(FlexImage) img) __setSelected(cast(FlexImage) img);
		}
	}

	private void delegate()[] _changingImages;
	@property
	void changingImages(void delegate() changingImages) {
		_changingImages ~= changingImages;
	}
	private void callChangingImages() {
		foreach (ci; _changingImages) ci();
	}

	/// 壁紙表示モード。
	@property
	const
	WallpaperStyle wallpaperStyle() {
		return _wallpaperStyle;
	}
	/// ditto
	@property
	void wallpaperStyle(WallpaperStyle v) {
		_wallpaperStyle = v;
		redraw();
	}

	/// 追加的に表示するイメージ。
	@property
	Image[] appends() {
		return _appends;
	}
	/// ditto
	@property
	void appends(Image[] v) {
		_appends = v;
		redraw();
	}

	/// 追加イメージを表示するか。
	@property
	const
	bool showAppends() {
		return _showAppends;
	}
	/// ditto
	@property
	void showAppends(bool v) {
		_showAppends = v;
		redraw();
	}

	/// グリッド間隔。1以下の場合はグリッドは無効。
	@property
	const
	int gridX() {
		return _gridX;
	}
	/// ditto
	@property
	void gridX(int v) {
		_gridX = v;
		resetGrid();
		redraw();
	}
	/// ditto
	@property
	const
	int gridY() {
		return _gridY;
	}
	/// ditto
	@property
	void gridY(int v) {
		_gridY = v;
		resetGrid();
		redraw();
	}
	/// グリッドに吸着する範囲。
	@property
	const
	int gridRange() {
		return _gridRange;
	}
	/// ditto
	@property
	void gridRange(int v) {
		_gridRange = v;
	}

	/// 含まれるFlexImageが移動・サイズ変更中か。
	@property
	const
	bool isMoving() {
		foreach (pi; images) {
			auto img = cast(const(FlexImage))pi;
			if (!img) continue;
			if (img.x != img.newX || img.y != img.newY || img.width != img.newWidth || img.height != img.newHeight) {
				return true;
			}
		}
		return false;
	}

	/// 唯一のコンストラクタ。
	this (Composite parent, int style) {
		super(parent, style);
		addListener(SWT.MouseDown, new MouseDown);
		addListener(SWT.MouseUp, new MouseUp);
		addMouseMoveListener(new MMListener);
		addKeyListener(new KListener);
		addListener(SWT.FocusOut, new FocusLost);
		addListener(SWT.Traverse, new Traverse);
		addPaintListener(new PListener);
		addDisposeListener(new DListener);

		toggleCursors[Toggle.LEFT_TOP] = display.getSystemCursor(SWT.CURSOR_SIZENWSE);
		toggleCursors[Toggle.RIGHT_BOTTOM] = display.getSystemCursor(SWT.CURSOR_SIZENWSE);
		toggleCursors[Toggle.RIGHT_TOP] = display.getSystemCursor(SWT.CURSOR_SIZENESW);
		toggleCursors[Toggle.LEFT_BOTTOM] = display.getSystemCursor(SWT.CURSOR_SIZENESW);
		toggleCursors[Toggle.LEFT_MIDDLE] = display.getSystemCursor(SWT.CURSOR_SIZEWE);
		toggleCursors[Toggle.RIGHT_MIDDLE] = display.getSystemCursor(SWT.CURSOR_SIZEWE);
		toggleCursors[Toggle.MIDDLE_TOP] = display.getSystemCursor(SWT.CURSOR_SIZENS);
		toggleCursors[Toggle.MIDDLE_BOTTOM] = display.getSystemCursor(SWT.CURSOR_SIZENS);
		toggleCursors[Toggle.MOVE] = null;
		toggleCursors[Toggle.NONE] = null;
	}
}

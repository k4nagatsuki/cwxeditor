
module cwx.editor.gui.dwt.images;

import cwx.utils;
import cwx.props;
import cwx.structs;
import cwx.graphics;

import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;

import std.math;
import std.file;
import std.path;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Device;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.Cursor;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontData;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.graphics.GCData;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.MouseMoveListener;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;

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

/// 画像を重ねて1枚のイメージを作成する。
public class PileImage {
private:
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
	}
	string _title = null;
	FontData titFont = null;
	Point titPoint = null;
	AppImg[] appends = [];
	Rectangle rect;
	bool t = false;
	bool s = false;
	int _alpha = 255;
	Image _img;
	string path = "";
	ImageData data = null;

	bool _visible = true;
	bool _smoothing = false;

	int initW, initH;

public:
	/// 画像のファイルパス、位置、サイズを指定してインスタンスを生成する。
	/// パスが存在しない場合、描画のタイミングで単に表示されない。
	/// Params:
	/// path = 画像のファイルパス。
	/// x = 横位置。
	/// y = 縦位置。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this(string path, int x, int y, int baseW, int baseH) {
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
	this(string path, int baseW, int baseH) {
		this(path, 0, 0, baseW, baseH);
	}
	/// 画像のデータ、位置、サイズを指定してインスタンスを生成する。
	/// パスが存在しない場合、描画のタイミングで単に表示されない。
	/// Params:
	/// data = 画像のデータ。
	/// x = 横位置。
	/// y = 縦位置。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this(ImageData data, int x, int y, int baseW, int baseH) {
		this.data = data;
		rect = new Rectangle(x, y, baseW, baseH);
		initW = baseW;
		initH = baseH;
	}
	/// 画像のデータ、サイズを指定してインスタンスを生成する。
	/// パスが存在しない場合、描画のタイミングで単に表示されない。
	/// Params:
	/// data = 画像のデータ。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this(ImageData data, int baseW, int baseH) {
		this(data, 0, 0, baseW, baseH);
	}
	/// Returns: ベースとなる幅。
	int baseWidth() {
		return initW;
	}
	/// Returns: ベースとなる高さ。
	int baseHeight() {
		return initH;
	}
	/// Params:
	/// initW = ベースとなる幅。
	void baseWidth(int initW) {
		this.initW = initW;
	}
	/// Params:
	/// initH = ベースとなる高さ。
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
	void append(string path, CInsets insets, bool transparent, int maskX = 0, int maskY = 0) {
		AppImg append;
		append.insets = insets;
		append.path = path;
		append.transparent = transparent;
		append.maskX = maskX;
		append.maskY = maskY;
		appends ~= append;
	}
	/// ditto
	void append(ImageData data, CInsets insets) {
		AppImg append;
		append.insets = insets;
		append.data = data;
		appends ~= append;
	}
	/// ditto
	void append(ImageData data, CPoint point) {
		append(data, CInsets(point.y,
			initW - (point.x + data.width),
			initH - (point.y + data.height),
			point.x));
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
	void title(string title) {
		assert (titFont !is null);
		assert (titPoint);
		_title = title;
	}
	string title() {
		return this._title;
	}
	/// イメージ・タイトル・透明色の設定有無を設定した後に
	/// このメソッドを呼び出すことで、画像が生成される。
	/// See_Also: append(), setTitle(), transparent()
	void createImage() {
		if (_img) _img.dispose;
		auto data = createImageData;
		_img = data ? new Image(Display.getCurrent, data) : null;
	}
	/// イメージ・タイトル・透明色の設定有無を設定した後に
	/// このメソッドを呼び出すことで、ImageDataが生成される。
	/// See_Also: append(), setTitle(), transparent()
	ImageData createImageData() {
		if (width == 0 || height == 0 || initW == 0 || initH == 0) return null;
		auto cur = Display.getCurrent();
		auto bmp = new Image(cur, initW, initH);
		scope (exit) bmp.dispose;
		auto dc = new GC(bmp);
		scope (exit) dc.dispose;
		void setAntialias(int a) {
			try {
				dc.setTextAntialias = a;
			} catch (Exception e) {
				// 一部環境で落ちる事があるらしい
				// 原因はさっぱり分からないので、とりあえずエラーだけ潰しておく
				debugln(e);
				dc.dispose;
				dc = new GC(bmp);
			}
		}

		try {
			ImageData matImgData;
			if (this.data) {
				matImgData = this.data;
			} else {
				if (isBinImg(path) || (path !is null && .exists(path))) {
					matImgData = loadImage(path, false);
					matImgData = matImgData.scaledTo(initW, initH);
				} else {
					// ファイルが無い場合は単に表示しない。
					matImgData = blankImage;
				}
			}
			auto matImg = new Image(cur, matImgData);
			scope (exit) matImg.dispose;
			dc.drawImage(matImg, 0, 0);

			foreach (a; appends) {
				if (a.path.length || a.data) {
					try {
						ImageData imgData;
						if (a.data) {
							imgData = a.data;
						} else {
							imgData = loadImage(a.path, a.transparent, a.maskX, a.maskY);
						}
						imgData = imgData.scaledTo
							(initW - a.insets.w - a.insets.e,
							initH - a.insets.n - a.insets.s);
						auto img = new Image(cur, imgData);
						scope (exit) img.dispose;
						dc.drawImage(img, a.insets.w, a.insets.n);
					} catch (SWTException e) {
						// ファイルが無い場合は表示しない。
					}
				}
				if (a.text.length) {
					try {
						auto font = new Font(cur, dwtData(a.font));
						scope (exit) font.dispose;
						dc.setFont = font;
						scope (exit) dc.setFont = null;
						int alpha;
						auto color = new Color(cur, dwtData(a.fontColor, alpha));
						scope (exit) color.dispose;
						auto fore = dc.getForeground;
						dc.setForeground = color;
						scope (exit) dc.setForeground = fore;
						dc.setAlpha = alpha;
						scope (exit) dc.setAlpha = 255;
						setAntialias(SWT.OFF);
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
						setAntialias(SWT.DEFAULT);
					} catch (SWTException e) {
					}
				}
			}

			if (_title !is null) {
				auto font = new Font(cur, titFont);
				scope (exit) font.dispose;
				dc.setFont = font;
				dc.setForeground(cur.getSystemColor(SWT.COLOR_BLACK));
				setAntialias(SWT.OFF);
				dc.drawText(_title, titPoint.x, titPoint.y, true);
				setAntialias(SWT.DEFAULT);
				dc.setFont(null);
			}
		} catch (Exception e) {
			debugln(e);
		}
		auto bmpData = bmp.getImageData;
		try {
			if (transparent) {
				bmpData.transparentPixel = bmpData.getPixel(0, 0);
			}
			if (smoothing) {
				auto data = cast(ubyte[]) bmpData.data;
				size_t bpl;
				bmpData.data = cast(byte[]) smoothResize(width, height, data,
					bmpData.depth, bmpData.width, bmpData.height, bmpData.bytesPerLine, bpl);
				bmpData.width = width;
				bmpData.height = height;
				bmpData.bytesPerLine = bpl;
			} else {
				bmpData = bmpData.scaledTo(width, height);
			}
		} catch (Exception e) {
			debugln(e);
		}
		return bmpData;
	}
	/// 画像を描画する。
	/// Params:
	/// dc = キャンバス。
	void draw(GC gc) {
		if (_visible && _img) {
			int olda = gc.getAlpha;
			gc.setAlpha = alpha;
			scope (exit) gc.setAlpha = olda;
			gc.drawImage(_img, x, y);
		}
	}
	/// Returns: 表示するか。
	bool visible() {
		return _visible;
	}
	/// Params:
	/// v = 表示するか。
	void visible(bool v) {
		_visible = v;
	}
	/// Returns: 拡大・縮小時に平滑化するか。
	bool smoothing() {
		return _smoothing;
	}
	/// Params:
	/// smoothing = 表示するか。
	void smoothing(bool smoothing) {
		_smoothing = smoothing;
	}
	/// 透明色を使用するか。
	bool transparent() {
		return t;
	}
	/// ditto
	void transparent(bool t) {
		this.t = t;
	}
	/// 透明度。0(透明)～255(不透明)。
	int alpha() {return _alpha;}
	/// ditto
	void alpha(int val) {_alpha = val;}
	/// Returns: 横位置。
	int x() {
		return rect.x;
	}
	/// 横位置を変更する。
	/// Params:
	/// x = 横位置。
	void x(int x) {
		rect.x = x;
	}
	/// Returns: 縦位置。
	int y() {
		return rect.y;
	}
	/// 縦位置を変更する。
	/// Params:
	/// y = 縦位置。
	void y(int y) {
		rect.y = y;
	}
	/// 幅を設定する。
	/// Params:
	/// w = 幅。
	void width(int w) {
		rect.width = w;
	}
	/// Returns: 幅。
	int width() {
		return rect.width;
	}

	/// 高さを設定する。
	/// Params:
	/// h = 高さ。
	void height(int h) {
		rect.height = h;
	}
	/// Returns: 高さ。
	int height() {
		return rect.height;
	}

	/// 位置とサイズを設定する。
	/// Params:
	/// rect = 位置とサイズ。
	void bounds(Rectangle rect) {
		this.rect.x = rect.x;
		this.rect.y = rect.y;
		this.rect.width = rect.width;
		this.rect.height = rect.height;
	}

	/// Returns: 位置とサイズ。
	Rectangle bounds() {
		return new Rectangle(x, y, width, height);
	}

	/// 全てのリソースを解放する。
	void dispose() {
		if (_img) _img.dispose;
	}
}

/// ImagePaneと組合わせて使用する移動可能な画像。
/// See_Also: ImagePane
public class FlexImage : PileImage {
private:
	void delegate(FlexImage img, int x, int y, real scale)[] lc_resizes;
	void delegate(FlexImage img, int x, int y, int w, int h)[] l_resizes;
	void delegate(FlexImage img)[] l_selected;

	int minW = 1, minH = 1;
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
	this(string path, int x, int y, int baseW, int baseH) {
		super(path, x, y, baseW, baseH);
		newR = new Rectangle(x, y, baseW, baseH);
	}
	/// 画像のデータ、位置、本来のサイズを指定してインスタンスを生成する。
	/// Params:
	/// path = 画像のデータ。
	/// x = 横位置。
	/// y = 縦位置。
	/// baseW = 本来の幅。
	/// baseH = 本来の高さ。
	this(ImageData data, int x, int y, int baseW, int baseH) {
		super(data, x, y, baseW, baseH);
		newR = new Rectangle(x, y, baseW, baseH);
	}
	/// Returns: 最小の幅。初期値は1。
	int minimumWidth() {
		return minW;
	}
	/// Params:
	/// minW = 最小の幅。
	void minimumWidth(int minW) {
		this.minW = minW;
	}
	/// Returns: 最小の高さ。初期値は1。
	int minimumHeight() {
		return minH;
	}
	/// Params:
	/// minW = 最小の高さ。
	void minimumHeight(int minH) {
		this.minH = minH;
	}
	/// Returns: 最大の幅。初期値は65536。
	int maximumWidth() {
		return maxW;
	}
	/// Params:
	/// minW = 最大の幅。
	void maximumWidth(int maxW) {
		this.maxW = maxW;
	}
	/// Returns: 最大の高さ。初期値は65536。
	int maximumHeight() {
		return maxH;
	}
	/// Params:
	/// minW = 最大の高さ。
	void maximumHeight(int maxH) {
		this.maxH = maxH;
	}
	/// 縦横比固定か。
	bool ratioFix() {
		return whconst;
	}
	/// ditto
	void ratioFix(bool whconst) {
		this.whconst = whconst;
	}
	/// サイズ・位置固定モードか。
	bool fixed() {return _fixed;}
	/// ditto
	void fixed(bool value) {
		_fixed = value;
		if (value) {
			reset;
		} else {
			retoggle;
		}
	}
	/// サイズ変更/移動更作業を終えてサイズ/位置を確定し、画像をその位置に配置する。
	/// 配置後、createImage()が実行される。
	/// See_Also: createImage();
	void resize(bool callListeners = true) {
		bounds = newR;
		if (callListeners) {
			foreach (l; l_resizes) {
				l(this, x, y, width, height);
			}
			foreach (l; lc_resizes) {
				l(this, x, y, cast(real) width / initW);
			}
		}
		createImage;
		retoggle;
	}
	/// サイズと移動の仮設定を最初の状態に戻す。
	void reset() {
		newR.x = x;
		newR.y = y;
		newR.width = width;
		newR.height = height;
		retoggle;
	}
	/// トグル以外の画像を描画する。
	void drawImage(GC gc) {
		if (visible) {
			super.draw(gc);
		}
	}
	/// トグルを描画する。
	void drawToggle(GC gc) {
		if (visible && selected) {
			gc.setBackground(Display.getCurrent.getSystemColor(SWT.COLOR_WHITE));
			gc.setForeground(Display.getCurrent.getSystemColor(SWT.COLOR_BLACK));
			gc.drawFocus(newX, newY, newWidth, newHeight);
			foreach (rect; tgls.values) {
				gc.fillRectangle(rect.x + 1, rect.y + 1, tglSize - 1, tglSize - 1);
				gc.drawRectangle(rect);
			}
		}
	}

	/// 画像を描画する。
	/// Params:
	/// dc = キャンバス。
	void draw(GC gc) {
		drawImage(gc);
		drawToggle(gc);
	}
	/// Returns: 選択中か。
	bool selected() {
		return s;
	}
	/// Params:
	/// s = 選択状態。
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
	int newX() {
		return newR.x;
	}
	/// 横位置を仮に変更する。確定するにはresize()を使用。
	/// Params:
	/// x = 横位置。
	/// See_Also: resize()
	void newX(int x) {
		newR.x = x;
		retoggle();
	}
	/// Returns: 仮の縦位置。
	int newY() {
		return newR.y;
	}
	/// 縦位置を仮に変更する。確定するにはresize()を使用。
	/// Params:
	/// y = 縦位置。
	/// See_Also: resize()
	void newY(int y) {
		newR.y = y;
		retoggle();
	}
	/// 幅を設定可能な値に丸めて返す。
	/// 縦横比固定の影響を受けない。
	int roundMWidth(int w) {
		w = minW > w ? minW : w;
		w = maxW < w ? maxW : w;
		return w;
	}
	/// 幅を設定可能な値に丸めて返す。
	/// Params:
	/// w = 幅。
	/// Returns: 丸めた幅。
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
	int newWidth() {
		return newR.width;
	}
	/// 幅を仮に設定する。確定するにはresize()を使用。
	/// Params:
	/// w = 幅。
	void newWidth(int w) {
		newR.width = roundMWidth(w);
		newR.height = roundHeight(newR.height);
		retoggle();
	}
	/// 高さを設定可能な値に丸めて返す。
	/// 縦横比固定の影響を受けない。
	int roundMHeight(int h) {
		h = minH > h ? minH : h;
		h = maxH < h ? maxH : h;
		return h;
	}
	/// 高さを設定可能な値に丸めて返す。
	/// Params:
	/// h = 高さ。
	/// Returns: 丸めた高さ。
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
	int newHeight() {
		return newR.height;
	}
	/// 高さを仮に設定する。確定するにはresize()を使用。
	/// Params:
	/// h = 高さ。
	void newHeight(int h) {
		newR.height = roundMHeight(h);
		newR.width = roundWidth(newR.width);
		retoggle();
	}
	/// 位置とサイズを仮に設定する。確定するにはresize()を使用。
	/// Params:
	/// rect = 位置とサイズ。
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
	void scale(real scale) {
		newR.width = cast(int) rndtol(initW * scale);
		newR.height = roundHeight(cast(int) rndtol(initH * rect.height));
		retoggle();
	}
	/// Returns: 仮の位置とサイズ。
	Rectangle newBounds() {
		return new Rectangle(newR.x, newR.y, newR.width, newR.height);
	}

	/// 指定されたポイントが画像内、あるいはトグルの内部であればその値を返す。
	/// 画像外であればToggle.NONEを返す。
	/// Params:
	/// x = 横位置。
	/// y = 縦位置。
	/// Returns: トグル。
	Toggle inToggle(int x, int y) {
		foreach (key; tgls.keys) {
			auto rect = tgls[key];
			if (rect.x <= x && x <= (rect.x + rect.width)
					&& rect.y <= y && y <= (rect.y + rect.height)) {
				return key;
			}
		}
		if (this.x <= x && x <= (this.x + this.width)
				&& this.y <= y && y <= (this.y + this.height)) {
			return Toggle.MOVE;
		} else {
			return Toggle.NONE;
		}
	}

	/// 自在にサイズ変更できるときのトグル。
	Toggle[] RESIZE_TOGGLES = [
		Toggle.LEFT_TOP, Toggle.LEFT_MIDDLE, Toggle.LEFT_BOTTOM,
		Toggle.MIDDLE_TOP, Toggle.MIDDLE_BOTTOM,
		Toggle.RIGHT_TOP, Toggle.RIGHT_MIDDLE, Toggle.RIGHT_BOTTOM
	];
	/// 縦横比固定時のトグル。
	Toggle[] RESIZE_TOGGLES_CORNER = [
		Toggle.LEFT_TOP, Toggle.LEFT_BOTTOM,
		Toggle.RIGHT_TOP, Toggle.RIGHT_BOTTOM
	];

	private void retoggle() {
		if (fixed) {
			typeof(this.tgls) tgls;
			this.tgls = tgls;
		} else {
			Toggle[] tgls = whconst ? RESIZE_TOGGLES_CORNER : RESIZE_TOGGLES;
			foreach (key; this.tgls.keys) {
				this.tgls.remove(key);
			}
			foreach (tgl; tgls) {
				this.tgls[tgl] = toggleRect(tgl);
			}
		}
	}

	private Rectangle toggleRect(Toggle tgl) {
		int tglX;
		int tglY;
		int tglWidth = tglSize;
		int tglHeight = tglSize;
		switch (tgl) {
		case Toggle.LEFT_TOP, Toggle.LEFT_MIDDLE, Toggle.LEFT_BOTTOM:
			tglX = newX - tglSize + (tglSize / 2);
			break;
		case Toggle.MIDDLE_TOP, Toggle.MIDDLE_BOTTOM:
			tglX = newX + (newWidth / 2) - (tglSize / 2);
			break;
		case Toggle.RIGHT_TOP, Toggle.RIGHT_MIDDLE, Toggle.RIGHT_BOTTOM:
			tglX = newX + newWidth - (tglSize / 2) - 1;
			break;
		}
		switch (tgl) {
		case Toggle.LEFT_TOP, Toggle.MIDDLE_TOP, Toggle.RIGHT_TOP:
			tglY = newY - tglSize + (tglSize / 2);
			break;
		case Toggle.LEFT_MIDDLE, Toggle.RIGHT_MIDDLE:
			tglY = newY + (newHeight / 2) - (tglSize / 2);
			break;
		case Toggle.LEFT_BOTTOM, Toggle.RIGHT_BOTTOM, Toggle.MIDDLE_BOTTOM:
			tglY = newY + newHeight - (tglSize / 2) - 1;
			break;
		}
		return new Rectangle(tglX, tglY, tglWidth, tglHeight);
	}

	/// 移動後に描画する領域を返す。
	/// Returns: 描画する領域。
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
	void dispose() {
		super.dispose;
	}
}

/// FlexImageと組合わせて柔軟に操作可能な画像を表示するパネル。
/// See_Also: FlexImage
public class ImagePane : Canvas {
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

	PileImage[] backs = [];

	class DListener : DisposeListener {
		public override void widgetDisposed(DisposeEvent e)  {
			foreach (img; backs) {
				img.dispose;
			}
		}
	}
	class KListener : KeyAdapter {
		override void keyPressed(KeyEvent ke) {
			switch (ke.keyCode) {
			case SWT.ARROW_UP: {
				redrawProc((FlexImage img) {
					if (ke.stateMask & SWT.SHIFT) {
						img.newHeight = img.newHeight - 1;
					} else {
						img.newY = img.newY - 1;
					}
				});
			} break;
			case SWT.ARROW_RIGHT: {
				redrawProc((FlexImage img) {
					if (ke.stateMask & SWT.SHIFT) {
						img.newWidth = img.newWidth + 1;
					} else {
						img.newX = img.newX + 1;
					}
				});
			} break;
			case SWT.ARROW_DOWN: {
				redrawProc((FlexImage img) {
					if (ke.stateMask & SWT.SHIFT) {
						img.newHeight = img.newHeight + 1;
					} else {
						img.newY = img.newY + 1;
					}
				});
			} break;
			case SWT.ARROW_LEFT: {
				redrawProc((FlexImage img) {
					if (ke.stateMask & SWT.SHIFT) {
						img.newWidth = img.newWidth - 1;
					} else {
						img.newX = img.newX - 1;
					}
				});
			} break;
			case SWT.ESC: {
				redrawProc((FlexImage img) {img.reset;});
			} break;
			case SWT.CR: {
				redrawProc((FlexImage img) {img.resize;});
			} break;
			default: break;
			}
		}
	}
	class MMListener : MouseMoveListener {
		override void mouseMove(MouseEvent me) {
			int x = me.x;
			int y = me.y;
			if (dragTgl != Toggle.NONE) {
				if (_ctrl && _mouseP) {
					doSelect(_mouseP);
				}
				int movX = x - dragStartX;
				int movY = y - dragStartY;
				foreach (img; dragImgs.keys) {
					if (img.selected && !img.fixed) {
						auto rect = dragImgs[img];
						Rectangle newRect = new Rectangle(img.x, img.y, img.width, img.height);
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
						switch (dragTgl) {
						case Toggle.LEFT_TOP, Toggle.MIDDLE_TOP, Toggle.RIGHT_TOP:
							newRect.y = rect.y + (rect.height - newRect.height);
							break;
						case Toggle.MOVE:
							newRect.y = rect.y + movY;
							break;
						default:
							break;
						}
						switch (dragTgl) {
						case Toggle.LEFT_TOP, Toggle.LEFT_MIDDLE, Toggle.LEFT_BOTTOM:
							newRect.x = rect.x + (rect.width - newRect.width);
							break;
						case Toggle.MOVE:
							newRect.x = rect.x + movX;
							break;
						default:
							break;
						}
						scope oldArea = img.drawNewArea;
						img.newBounds = newRect;
						scope newArea = img.drawNewArea;
						redraw(oldArea.x, oldArea.y, oldArea.width, oldArea.height, false);
						redraw(newArea.x, newArea.y, newArea.width, newArea.height, false);
					}
				}
				moved = true;
			} else {
				foreach_reverse (pimg; backs) {
					if (cast(FlexImage) pimg && pimg.visible) {
						auto img = cast(FlexImage) pimg;
						Toggle tgl = img.inToggle(x, y);
						if (tgl != Toggle.NONE) {
							setCursor = getToggleCursor(tgl);
							return;
						}
					}
				}
				setCursor = getToggleCursor(Toggle.NONE);
			}
		}
	}

	class MouseDown : Listener {
		override void handleEvent(Event me) {
			setFocus;
			moved = false;
			_ctrl = (me.stateMask & SWT.SHIFT) != 0 || (me.stateMask & SWT.CTRL) != 0;
			int x = me.x;
			int y = me.y;
			if (me.button == 1) {
				dragStartX = x;
				dragStartY = y;
				auto tgl = Toggle.NONE;
				FlexImage img = null;
				foreach_reverse (i, pimg; backs) {
					if (cast(FlexImage) pimg) {
						img = cast(FlexImage) pimg;
						if (img.visible) {
							tgl = img.inToggle(x, y);
							if (tgl !is Toggle.NONE) {
								break;
							}
						}
					}
				}
				if (tgl !is Toggle.NONE) {
					_mouseP = img;
					if (me.button == 1) {
						if (!_ctrl) {
							if (!img.selected) doDeselectAll;
							doSelect(img);
						}
						dragTgl = tgl;
					} else if (me.button == 3) {
						if (!img.selected) doDeselectAll;
						doSelect(img);
					}
					return;
				}
				doDeselectAll;
				_mouseP = null;
			} else if (me.button == 2) {
				auto ids = selectedIndices;
				if (ids.length == 0 || !changeSelect(x, y)) {
					int i = findIndex(x, y);
					if (i >= 0) {
						doDeselectAll;
						doSelect(cast(FlexImage) images[i]);
					}
				}
			} else if (me.button == 3) {
				dragTgl = Toggle.NONE;
				redrawProc((FlexImage img) {img.reset;});
			}
		}
	}
	void redrawProc(void delegate(FlexImage) proc) {
		foreach (img; dragImgs.keys) {
			auto newArea = img.drawNewArea;
			auto oldArea = img.drawArea;
			proc(img);
			redraw(oldArea.x, oldArea.y, oldArea.width, oldArea.height, false);
			redraw(newArea.x, newArea.y, newArea.width, newArea.height, false);
		}
	}
	class FocusLost : Listener {
		override void handleEvent(Event me) {
			dragTgl = Toggle.NONE;
			redrawProc((FlexImage img) {img.resize;});
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
								changingImages;
								ci = true;
							}
							img.resize;
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
						doDeselectAll;
						doSelect(_mouseP);
					}
				}
			}
			dragTgl = Toggle.NONE;
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
			auto buf = new Image(getShell.getDisplay, getSize.x, getSize.y);
			auto gc = new GC(buf);

			auto backImg = getBackgroundImage;
			auto rect = getClientArea;
			if (backImg) {
				drawTileImage(gc, backImg, rect);
			} else if (_backColor) {
				gc.setBackground(_backColor);
				gc.fillRectangle(rect.x, rect.y, rect.width, rect.height);
			} else {
				gc.setBackground(getShell.getDisplay.getSystemColor(SWT.COLOR_DARK_BLUE));
				gc.fillRectangle(rect.x, rect.y, rect.width, rect.height);
			}
			foreach (bmp; backs) {
				bmp.draw(gc);
			}

			e.gc.drawImage(buf, 0, 0);
			buf.dispose;
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
			int i = indexOf(imgs, tsels[0]);
			assert (i >= 0);
			doDeselect(cast(FlexImage) images[tsels[0]]);
			doSelect(cast(FlexImage) images[i > 0 ? imgs[i - 1] : imgs[$ - 1]]);
			return true;
		}
		return false;
	}

	private Color _backColor = null;
public:
	void setBackgroundColor(Color backColor) {_backColor = backColor;}
	Color getBackgroundColor() {return _backColor;}

	PileImage[] images() {
		return backs;
	}

	void swap(int index1, int index2) {
		auto temp = backs[index1];
		backs[index1] = backs[index2];
		backs[index2] = temp;
	}

	void select(FlexImage[] imgs) {
		foreach (img; imgs) {
			select(img);
		}
	}
	void select(FlexImage img) {
		if (!img.selected) {
			img.selected = true;
			__setSelected(img);
		}
	}
	void select(int[] indices) {
		deselectAll;
		foreach (i; indices) {
			auto fi = cast(FlexImage) backs[i];
			select(fi);
		}
	}
	private void doSelect(FlexImage img) {
		if (!img.selected) {
			img.doSelected = true;
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
			img.doSelected = false;
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
	int[] selectedIndices() {
		int[] r;
		foreach (i, img; backs) {
			auto fi = cast(FlexImage) img;
			if (fi && fi.selected) r ~= i;
		}
		return r;
	}
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
		backs[index].dispose;
		removeDragImage(backs[index]);
		backs = backs[0 .. index] ~ backs[index + 1 .. $];
	}

	void removeRange(int fromIndex, int toIndex) {
		for (int i = fromIndex; i < toIndex; i++) {
			backs[i].dispose;
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
		backs[index].dispose;
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
	void changingImages(void delegate() changingImages) {
		_changingImages ~= changingImages;
	}
	private void changingImages() {
		foreach (ci; _changingImages) ci();
	}

	/// 唯一のコンストラクタ。
	this(Composite parent, int style) {
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

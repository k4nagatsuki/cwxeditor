
module cwx.editor.gui.dwt.areaviewutils;

import cwx.utils;
import cwx.area;
import cwx.card;
import cwx.flag;
import cwx.summary;
import cwx.background;
import cwx.props;
import cwx.imagesize;
import cwx.xml;
import cwx.skin;
import cwx.usecounter;
import cwx.path;
import cwx.structs;
import cwx.sjis;
import cwx.menu;
import cwx.types;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.spcarddialog;
import cwx.editor.gui.dwt.bgimagedialog;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.jpyimage;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.dmenu;

import std.algorithm;
import std.conv;
import std.math;
import std.path;
import std.file;
import std.traits;
import std.datetime;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

/// 背景画像を生成する。
/// Returns: 背景画像。
FlexImage createBackgroundImage
		(Props prop, in Skin skin, in Summary summ, string path, int x, int y, int w, int h, bool transparent) { mixin(S_TRACE);
	FlexImage r;
	auto ext = .extension(path);
	if (cfnmatch(ext, ".jpy1") || cfnmatch(ext, ".jptx") || cfnmatch(ext, ".jpdc")) { mixin(S_TRACE);
		bool resizable;
		auto data = loadJPYImage(prop, skin, summ, path, [], resizable);
		r = new FlexImage(data, x, y, data.width, data.height, resizable);
	} else { mixin(S_TRACE);
		uint baseW = w, baseH = h;
		if (isBinImg(path)) {
			auto imgData = loadImage(prop, skin, summ, path, false);
			baseW = imgData.width;
			baseH = imgData.height;
			r = new FlexImage(imgData, x, y, baseW, baseH, true);
		} else {
			try { mixin(S_TRACE);
				dwtImageSize(prop, skin, summ, path, baseW, baseH);
			} catch { mixin(S_TRACE);
				baseW = w;
				baseH = h;
			}
			r = new FlexImage(path, x, y, baseW, baseH);
		}
	}
	r.transparent = transparent;
	r.newWidth = w;
	r.newHeight = h;
	r.resize();
	return r;
}

/// キャストカード画像(背景のみ)を生成する。
/// Returns: カード背景画像。
PileImage createCastCardBackImage(Props prop, Skin skin, int x, int y) { mixin(S_TRACE);
	auto cardSize = prop.looks.cardSize;
	auto matPad = prop.looks.castCardInsets;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	auto r = new PileImage(castCard(skin), x, y, w, h, true);
	r.createImage();
	return r;
}

PImg createCardImageCommon(PImg)(Props prop, ImageData card,
		CInsets matPad, int x, int y, real scale, bool smoothing) { mixin(S_TRACE);
	auto cardSize = prop.looks.cardSize;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	auto r = new PImg(card, x, y, w, h, true);
	r.transparent = false;
	r.smoothing = smoothing;
	static if (is(PImg : FlexImage)) {
		r.minimumWidth = cast(int) rndtol(w * (prop.var.etc.cardScaleMin / 100.0));
		r.minimumHeight = cast(int) rndtol(h * (prop.var.etc.cardScaleMin / 100.0));
		r.maximumWidth = cast(int) rndtol(w * (prop.var.etc.cardScaleMax / 100.0));
		r.maximumHeight = cast(int) rndtol(h * (prop.var.etc.cardScaleMax / 100.0));
		r.ratioFix = true;
		r.newWidth = cast(int) rndtol(w * scale);
		r.newHeight = cast(int) rndtol(h * scale);
	} else { mixin(S_TRACE);
		r.width = cast(int) rndtol(w * scale);
		r.height = cast(int) rndtol(h * scale);
	}
	return r;
}

/// キャストカード画像を生成する。
/// Returns: カード画像。
PImg createCastCardImage(PImg)(Props prop, Skin skin, CastCard card,
		string sPath, int x, int y, real scale, bool smoothing, bool dbgMode) { mixin(S_TRACE);
	auto matPad = prop.looks.castCardInsets;
	PImg r;
	if (card) { mixin(S_TRACE);
		r = createCardImageCommon!PImg(prop, castCardImage(prop, skin, card, sPath, dbgMode),
			matPad, x, y, scale, smoothing);
	} else { mixin(S_TRACE);
		r = createCardImageCommon!PImg(prop, castCard(skin),
			matPad, x, y, scale, smoothing);
	}
	static if (is(PImg : FlexImage)) {
		r.resize();
	} else { mixin(S_TRACE);
		r.createImage();
	}
	return r;
}

/// メニューカード画像を生成する。
/// Returns: カード画像。
PImg createMenuCardImage(PImg)(Props prop, Skin skin,
		string title, string path, int x, int y, real scale, bool smoothing, uint pcNum) { mixin(S_TRACE);
	auto matPad = prop.looks.menuCardInsets;
	auto r = createCardImageCommon!PImg(prop, menuCard(skin), matPad, x, y, scale, smoothing);
	r.append(path, matPad, ScaleType.Cut, true);
	r.setTitle(title, dwtData(prop.looks.menuCardNameFont(skin.legacy)), dwtData(prop.looks.menuCardNamePoint));
	if (0 != pcNum) { mixin(S_TRACE);
		r.append(dwtData(prop.looks.pcNumberFont(skin.legacy)), .text(pcNum), prop.looks.menuCardInsets);
	}
	static if (is(PImg : FlexImage)) {
		r.resize();
	} else { mixin(S_TRACE);
		r.createImage();
	}
	return r;
}

BgImagesView createBgImagesViewAndMenu(Commons comm, Props prop, Summary summ, BgImageContainer cont, Composite parent, AbstractArea refTarget) { mixin(S_TRACE);
	auto undo = new UndoManager(prop.var.etc.undoMaxEvent);
	void refUndoMax() { mixin(S_TRACE);
		undo.max = prop.var.etc.undoMaxEvent;
	}
	auto view = new BgImagesView(comm, prop, summ, cont, parent, refTarget, undo);
	comm.refUndoMax.add(&refUndoMax);
	view.addDisposeListener(new class DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			comm.refUndoMax.remove(&refUndoMax);
		}
	});
	auto bar = new Menu(parent.getShell(), SWT.BAR);
	parent.getShell().setMenuBar(bar);
	auto me = createMenu(comm, bar, MenuID.Edit);
	createMenuItem(comm, me, MenuID.Undo, &view.undo, &undo.canUndo);
	createMenuItem(comm, me, MenuID.Redo, &view.redo, &undo.canRedo);
	new MenuItem(me, SWT.SEPARATOR);
	createMenuItem(comm, me, MenuID.Up, &view.up, &view.canUp);
	createMenuItem(comm, me, MenuID.Down, &view.down, &view.canDown);
	new MenuItem(me, SWT.SEPARATOR);
	appendMenuTCPD(comm, me, view, true, true, true, true, true);
	auto mv = createMenu(comm, bar, MenuID.View);
	createMenuItem(comm, mv, MenuID.Refresh, &view.refresh, null);
	view.setupMenu(bar);
	return view;
}

PileImage createMessageImage(Commons comm, Props prop) { mixin(S_TRACE);
	auto rect = prop.looks.messageBounds;
	string[char] names;
	string[string] flags, steps;
	// 特殊文字が無いためシナリオパス不要
	auto imgData = previewMessage(comm, prop, "", null, "", [""], names, flags, steps);
	auto img = new PileImage(imgData, rect.x, rect.y, imgData.width, imgData.height, true);
	img.foreground = true;
	img.alpha = prop.var.etc.messageAlpha;
	img.createImage();
	return img;
}

class Preview {
	private Props _prop;
	private Shell _shell;
	private PileImage _image = null;
	private PileImage _showingImage = null;
	private int _x = 0, _y = 0;
	private int _showingX = int.min, _showingY = int.min;
	private int _w = 0, _h = 0;
	private int _itmH = 0;
	private Image _paintImage = null;

	this (Props prop, Shell parentShell) { mixin(S_TRACE);
		_prop = prop;

		_shell = new Shell(parentShell, SWT.NO_TRIM | SWT.NO_BACKGROUND);
		_shell.setAlpha(_prop.var.etc.previewAlpha);
		_shell.addPaintListener(new Paint);
	}

	class Paint : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			onPaint(e);
		}
	}
	private void onPaint(PaintEvent e) { mixin(S_TRACE);
		if (_image && _paintImage) { mixin(S_TRACE);
			auto d = _shell.getDisplay();
			e.gc.drawImage(_paintImage, 0, 0);
		}
	}

	void image(PileImage image, int x, int y, int itmH) { mixin(S_TRACE);
		if (!_shell || _shell.isDisposed()) return;
		_image = image;
		if (_image) { mixin(S_TRACE);
			_x = x;
			_y = y;
			_itmH = itmH;
		} else { mixin(S_TRACE);
			_shell.setVisible(false);
			if (_paintImage) { mixin(S_TRACE);
				_paintImage.dispose();
				_paintImage = null;
			}
			auto region = _shell.getRegion();
			if (region) region.dispose();
		}
	}
	void dispose() { mixin(S_TRACE);
		if (!_shell || _shell.isDisposed()) return;
		close();
		_shell.dispose();
	}
	void show() { mixin(S_TRACE);
		if (!_shell || _shell.isDisposed()) return;
		if (_prop.var.etc.showImagePreview && _image) { mixin(S_TRACE);
			if (_image is _showingImage && _x == _showingX && _y == _showingY && _shell.getVisible()) { mixin(S_TRACE);
				return;
			}
			_showingImage = _image;
			_showingX = _x;
			_showingY = _y;
			_shell.setVisible(false);
			// 大きすぎる画像はリサイズ
			_w = _image.baseWidth;
			_h = _image.baseHeight;
			if (_prop.var.etc.previewMaxWidth < _w || _prop.var.etc.previewMaxHeight < _h) { mixin(S_TRACE);
				real ws = cast(real) _prop.var.etc.previewMaxWidth / _w;
				real hs = cast(real) _prop.var.etc.previewMaxHeight / _h;
				real s = std.algorithm.min(ws, hs);
				_w *= s;
				_h *= s;
				_w = .max(1, _w);
				_h = .max(1, _h);
			}

			// 画面に収まるよう位置合わせ
			auto d = _shell.getDisplay();
			auto dc = d.getClientArea();
			if (_y + _h > dc.height) { mixin(S_TRACE);
				_y -= _itmH + _h;
			}
			if (_x < 0) { mixin(S_TRACE);
				_x = 0;
			}
			if (_x + _w > dc.width) { mixin(S_TRACE);
				_x -= _x + _w - dc.width;
			}
			_shell.setBounds(_x, _y, _w, _h);
			auto data = _image.baseSizeData();
			if (!data) return;
			data = data.scaledTo(_w, _h);
			if (_paintImage) { mixin(S_TRACE);
				_paintImage.dispose();
			}
			_paintImage = new Image(d, data);

			// 透明色を使う場合は透明部分を除いたRegionを作る
			auto oldReg = _shell.getRegion();
			if (oldReg) oldReg.dispose();
			if (_image.transparent) { mixin(S_TRACE);
				auto region = new Region;
				auto rect = new Rectangle(0, 0, 0, 1);
				auto pixels = new int[_w];
				foreach (y; 0 .. _h) { mixin(S_TRACE);
					rect.y = y;
					data.getPixels(0, y, _w, pixels, 0);
					int tStart = 0;
					bool t = true;
					foreach (x; 0 .. _w) { mixin(S_TRACE);
						bool pt = data.transparentPixel == pixels[x];
						if (pt) tStart = x;
						if (t == pt) { mixin(S_TRACE);
							continue;
						}
						pt = t;
						if (pt) { mixin(S_TRACE);
							rect.x = tStart + 1;
							rect.width = x - tStart;
							region.add(rect);
						}
					}
					if (!t) { mixin(S_TRACE);
						rect.x = tStart + 1;
						rect.width = _w - tStart;
						region.add(rect);
					}
				}
				_shell.setRegion(region);
			} else { mixin(S_TRACE);
				_shell.setRegion(null);
			}

			_shell.setVisible(true);
		}
	}
	void close() { mixin(S_TRACE);
		image(null, 0, 0, 0);
	}
}

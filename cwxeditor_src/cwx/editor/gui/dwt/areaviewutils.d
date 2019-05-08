
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
import cwx.msgutils;

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
FlexImage createBackgroundImage(Props prop, in Skin skin, in Summary summ, string path, int x, int y, int w, int h, bool transparent, int layer, bool smoothing) { mixin(S_TRACE);
	FlexImage r;
	auto ext = .extension(path);
	if (cfnmatch(ext, ".jpy1") || cfnmatch(ext, ".jptx") || cfnmatch(ext, ".jpdc")) { mixin(S_TRACE);
		bool resizable;
		auto data = .loadJPYImageWithScale(prop, skin, summ, path, prop.drawingScale, [], resizable);
		r = new FlexImage(data, prop.drawingScale, x, y, data.getWidth(NORMAL_SCALE), data.getHeight(NORMAL_SCALE), false, resizable);
	} else { mixin(S_TRACE);
		uint baseW = w, baseH = h;
		if (isBinImg(path)) { mixin(S_TRACE);
			auto imgData = .loadImageWithScale(prop, skin, summ, path, prop.drawingScaleForImage(summ), false , true);
			baseW = imgData.getWidth(NORMAL_SCALE);
			baseH = imgData.getHeight(NORMAL_SCALE);
			r = new FlexImage(imgData, prop.drawingScale, x, y, baseW, baseH, false, true);
		} else { mixin(S_TRACE);
			try { mixin(S_TRACE);
				dwtImageSize(prop, skin, summ, path, baseW, baseH);
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
				baseW = w;
				baseH = h;
			}
			r = new FlexImage(path, prop.drawingScale, x, y, baseW, baseH, false);
		}
	}
	r.transparent = transparent;
	r.layer = layer * 10;
	r.smoothing = smoothing;
	r.newWidth = w;
	r.newHeight = h;
	r.resize();
	return r;
}

/// キャストカード画像(背景のみ)を生成する。
/// Returns: カード背景画像。
PileImage createCastCardBackImage(Props prop, Skin skin, in Summary summ, int x, int y, byte alpha) { mixin(S_TRACE);
	auto cardSize = prop.looks.cardSize;
	auto matPad = prop.looks.castCardInsets;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	// FIXME: 64bit環境で256色の画像にalpha値を設定するとXOR描画状態になる
	//auto imgData = .castCard(skin, prop.drawingScale);
	auto imgData = .castCard(skin, prop.drawingScale);
	imgData.baseData.alphaData = new byte[imgData.baseData.width * imgData.baseData.height];
	imgData.baseData.alphaData[] = alpha;
	auto r = new PileImage(imgData, prop.drawingScale, x, y, w, h, true, true);
	r.layer = LAYER_PLAYER_CARD * 10;
	r.createImage();
	return r;
}
/// 背景のみのキャストカード画像をスキンに応じて更新する。
void updateCastCardBackImage(PileImage img, Skin skin, byte alpha, uint targetScale) { mixin(S_TRACE);
	// FIXME: 64bit環境で256色の画像にalpha値を設定するとXOR描画状態になる
	//auto imgData = .castCard(skin, targetScale);
	auto imgData = .castCard(skin, targetScale);
	imgData.baseData.alphaData = new byte[imgData.baseData.width * imgData.baseData.height];
	imgData.baseData.alphaData[] = alpha;
	img.setBaseImage(imgData, img.baseWidth, img.baseHeight);
	img.targetScale = targetScale;
	img.createImage();
}

PImg createCardImageCommon(PImg)(Props prop, in Summary summ, ImageDataWithScale card,
		CInsets matPad, int x, int y, uint scale, bool smoothing, int layer) { mixin(S_TRACE);
	auto cardSize = prop.looks.cardSize;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	auto r = new PImg(card, prop.drawingScale, x, y, w, h, true, true);
	r.transparent = false;
	r.layer = layer * 10;
	r.smoothing = smoothing;
	static if (is(PImg:FlexImage)) {
		r.maximumScale = prop.var.etc.cardScaleMax;
		r.minimumScale = prop.var.etc.cardScaleMin;
		r.newScale = scale;
	} else { mixin(S_TRACE);
		r.scale = scale;
	}
	return r;
}

/// キャストカード画像を生成する。
/// Returns: カード画像。
PImg createCastCardImage(PImg)(Commons comm, Skin skin, in Summary summ, in EnemyCard ec, in CastCard card,
		int x, int y, uint scale, bool smoothing, bool dbgMode, int layer) { mixin(S_TRACE);
	auto matPad = comm.prop.looks.castCardInsets;
	PImg r;
	if (card) { mixin(S_TRACE);
		auto overrideName = "";
		if (ec.isOverrideName) { mixin(S_TRACE);
			overrideName = .createSPCharPreview(comm, summ, ec.useCounter, ec.overrideName, false, null, null);
		}
		auto cImg = .castCardImage(comm.prop, skin, summ, card, dbgMode, ec.isOverrideName, overrideName, ec.isOverrideImage, ec.overrideImages);
		r = createCardImageCommon!PImg(comm.prop, summ, cImg, matPad, x, y, scale, smoothing, layer);
	} else { mixin(S_TRACE);
		r = createCardImageCommon!PImg(comm.prop, summ, .castCard(skin, comm.prop.drawingScale), matPad, x, y, scale, smoothing, layer);
	}
	static if (is(PImg:FlexImage)) {
		r.hasSelectionFilter = comm.prop.var.etc.showSceneViewSelectionFilter;
		r.resize();
	} else { mixin(S_TRACE);
		r.createImage();
	}
	return r;
}

/// メニューカード画像を生成する。
/// Returns: カード画像。
PImg createMenuCardImage(PImg)(Props prop, Skin skin, in Summary summ,
		string title, in CardImage[] paths, int x, int y, uint scale, bool smoothing, int layer) { mixin(S_TRACE);
	auto matPad = prop.looks.menuCardInsets;
	auto card = .menuCard(skin, prop.drawingScale);
	auto r = createCardImageCommon!PImg(prop, summ, card, matPad, x, y, scale, smoothing, layer);
	foreach (path; paths) { mixin(S_TRACE);
		path.addToPileImage(r, prop, skin, summ, matPad, ScaleType.Cut);
	}
	auto tx = prop.looks.menuCardNamePoint.x;
	auto w = card.getWidth(NORMAL_SCALE);
	r.setTitle(title, prop.looks.menuCardNameFont(skin.legacy), dwtData(prop.looks.menuCardNamePoint),
		skin.legacy ? 0 : w - tx * 2, !skin.legacy);
	if (!skin.legacy) { mixin(S_TRACE);
		if (getRGBAverage(card.scaled(prop.drawingScale), prop.ds(prop.looks.cardNameArea)) < prop.var.etc.negativeCardNameBorder) { mixin(S_TRACE);
			r.titleColor = new RGB(255, 255, 255);
			r.titleHemmingColor = prop.var.etc.cardNameBorderingColorForWhite;
		} else { mixin(S_TRACE);
			r.titleHemmingColor = prop.var.etc.cardNameBorderingColorForBlack;
		}
	}
	static if (is(PImg:FlexImage)) {
		r.hasSelectionFilter = prop.var.etc.showSceneViewSelectionFilter;
		r.resize();
	} else { mixin(S_TRACE);
		r.createImage();
	}
	return r;
}

BgImagesView createBgImagesViewAndMenu(Commons comm, Props prop, Summary summ, UseCounter uc, BgImageContainer cont, 
		Composite parent, AbstractArea refTarget, bool showInheritBacks, bool readOnly) { mixin(S_TRACE);
	auto undo = new UndoManager(prop.var.etc.undoMaxEvent);
	void refUndoMax() { mixin(S_TRACE);
		undo.max = prop.var.etc.undoMaxEvent;
	}
	auto view = new BgImagesView(comm, prop, summ, uc, cont, parent, refTarget, showInheritBacks, undo, readOnly);
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

PileImage createMessageImage(Commons comm, Props prop, in Summary summ) { mixin(S_TRACE);
	auto rect = prop.looks.messageBounds;
	string[char] names;
	VarValue[string] flags, steps, variants, sysSteps;
	// 特殊文字が無いためシナリオパス不要
	auto imgData = previewMessage(comm, prop, null, null, null, "", [""], names, flags, steps, variants, sysSteps, false, false, false);
	auto img = new PileImage(imgData, prop.drawingScale, rect.x, rect.y, imgData.getWidth(NORMAL_SCALE), imgData.getHeight(NORMAL_SCALE), false, true);
	img.layer = LAYER_MESSAGE * 10 - 1;
	img.alpha = prop.var.etc.messageAlpha;
	img.separator = true;
	img.createImage();
	return img;
}

private string createFlagName(in Commons comm, in Summary summ, in UseCounter uc, string path) { mixin(S_TRACE);
	if (!path.length) return comm.prop.msgs.areaViewStatusNoFlag;
	if (summ) { mixin(S_TRACE);
		auto f = .findVar!(cwx.flag.Flag)(summ.flagDirRoot, uc, path);
		if (f) return .tryFormat(comm.prop.msgs.areaViewStatusWithFlag, path);
	}
	return .tryFormat(comm.prop.msgs.areaViewStatusInvalidFlag, path);
}
string createAreaViewStatusLine(in Commons comm, in Summary summ, in Skin skin, in MenuCard card) { mixin(S_TRACE);
	string path(in MenuCard card) { mixin(S_TRACE);
		string[] arr;
		foreach (path; card.paths) { mixin(S_TRACE);
			final switch (path.type) {
			case CardImageType.File:
				if (!path.path.length) { mixin(S_TRACE);
					arr ~= comm.prop.msgs.noSelectImage;
				} else if (isBinImg(path.path)) { mixin(S_TRACE);
					arr ~= comm.prop.msgs.areaViewStatusImageIncluding;
				} else if (!skin.findImagePath(path.path, summ ? summ.scenarioPath : "", summ ? summ.dataVersion : LATEST_VERSION).length) { mixin(S_TRACE);
					arr ~= .tryFormat(comm.prop.msgs.noImage, encodePath(path.path));
				} else { mixin(S_TRACE);
					arr ~= encodePath(path.path);
				}
				break;
			case CardImageType.PCNumber:
				if (0 < path.pcNumber) { mixin(S_TRACE);
					arr ~= .tryFormat(comm.prop.msgs.pcNumber, path.pcNumber);
				}
				break;
			case CardImageType.Talker:
				final switch (path.talker) {
				case Talker.Selected:
				case Talker.Unselected:
				case Talker.Random:
				case Talker.Valued:
				case Talker.Card:
					arr ~= comm.prop.msgs.talkerName(path.talker);
					break;
				}
				break;
			}
		}
		if (arr.length == 0) arr ~= comm.prop.msgs.noSelectImage;
		return std.string.join(arr, " ");
	}
	auto params = .statusParams(comm, summ, card);
	if (params != "") { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.areaViewStatus, comm.prop.msgs.menuCard, path(card), params);
	} else { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.areaViewStatusNoSummary, comm.prop.msgs.menuCard, path(card));
	}
}
string createAreaViewStatusLine(in Commons comm, in Summary summ, in Skin skin, in EnemyCard card) { mixin(S_TRACE);
	string name = comm.prop.msgs.noSelectCast;
	if (0 != card.id) { mixin(S_TRACE);
		if (summ) { mixin(S_TRACE);
			auto c = summ.cwCast(card.id);
			if (c) { mixin(S_TRACE);
				name = .tryFormat(comm.prop.msgs.areaViewStatusEnemyCard, c.id, c.name);
			} else { mixin(S_TRACE);
				name = .tryFormat(comm.prop.msgs.noCast, card.id);
			}
		} else { mixin(S_TRACE);
			name = .tryFormat(comm.prop.msgs.noCast, card.id);
		}
	}
	auto params = .statusParams(comm, summ, card);
	if (params != "") { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.areaViewStatus, comm.prop.msgs.enemyCard, name, params);
	} else { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.areaViewStatusNoSummary, comm.prop.msgs.enemyCard, name);
	}
}
private string statusParams(in Commons comm, in Summary summ, in AbstractSpCard card) { mixin(S_TRACE);
	string[] params;
	if (summ) params ~= createFlagName(comm, summ, card.useCounter, card.flag);
	if (card.layer != LAYER_MENU_CARD) params ~= .tryFormat(comm.prop.msgs.areaViewStatusWithLayer, card.layer);
	if (card.animationSpeed != -1) params ~= .tryFormat(comm.prop.msgs.areaViewStatusWithCardSpeed, card.animationSpeed);
	return params.join(" ");
}
string createAreaViewStatusLine(in Commons comm, in Summary summ, in Skin skin, in BgImage back) { mixin(S_TRACE);
	string path, name;
	auto ic = cast(ImageCell)back;
	if (ic) { mixin(S_TRACE);
		name = comm.prop.msgs.back;
		path = .encodePath(ic.path);
		if (!path.length) { mixin(S_TRACE);
			path = comm.prop.msgs.noSelectImage;
		} else if (!skin.findImagePath(path, summ ? summ.scenarioPath : "", summ ? summ.dataVersion : LATEST_VERSION).length) { mixin(S_TRACE);
			path = .tryFormat(comm.prop.msgs.noImage, encodePath(path));
		}
	}
	auto tc = cast(TextCell)back;
	if (tc) { mixin(S_TRACE);
		name = comm.prop.msgs.textCell;
		path = back.name(comm.prop.parent);
	}
	auto cc = cast(ColorCell)back;
	if (cc) { mixin(S_TRACE);
		name = comm.prop.msgs.colorCell;
		path = back.name(comm.prop.parent);
	}
	auto pc = cast(PCCell)back;
	if (pc) { mixin(S_TRACE);
		name = comm.prop.msgs.pcCell;
		path = back.name(comm.prop.parent);
	}
	auto params = .statusParams(comm, summ, back);
	if (params != "") { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.areaViewStatus, name, path, params);
	} else { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.areaViewStatusNoSummary, name, path);
	}
}
private string statusParams(in Commons comm, in Summary summ, in BgImage back) { mixin(S_TRACE);
	string[] params;
	if (summ) params ~= createFlagName(comm, summ, back.useCounter, back.flag);
	if (back.layer != LAYER_BACK_CELL) params ~= .tryFormat(comm.prop.msgs.areaViewStatusWithLayer, back.layer);
	return params.join(" ");
}

class Preview {
	private Props _prop;
	private Shell _shell;
	private Control _parent;
	private PileImage _image = null;
	private PileImage _showingImage = null;
	private int _x = 0, _y = 0;
	private int _showingX = int.min, _showingY = int.min;
	private int _w = 0, _h = 0;
	private int _itmH = 0;
	private Image _paintImage = null;

	this (Props prop, Control parent) { mixin(S_TRACE);
		_prop = prop;
		_parent = parent;

		createShell();
	}
	private void createShell() { mixin(S_TRACE);
		_shell = new Shell(_parent.getShell(), SWT.NO_TRIM | SWT.NO_BACKGROUND);
		_shell.setAlpha(_prop.var.etc.previewAlpha);
		_shell.addPaintListener(new Paint);
	}

	private class Paint : PaintListener {
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
		if (!_shell || _shell.isDisposed()) { mixin(S_TRACE);
			if (_parent.isDisposed()) return;
			// ウィンドウ分離などで親のControlが別のウィンドウへ移っている場合がある
			createShell();
		}
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
		auto region = _shell.getRegion();
		if (region) region.dispose();
		_shell.dispose();
		_shell = null;
	}
	void show() { mixin(S_TRACE);
		if (_prop.var.etc.showImagePreview && _image) { mixin(S_TRACE);
			if (!_shell || _shell.isDisposed()) {
				if (_parent.isDisposed()) return;
				// ウィンドウ分離などで親のControlが別のウィンドウへ移っている場合がある
				createShell();
			} else if (_shell.getParent() !is _parent.getShell()) { mixin(S_TRACE);
				auto region = _shell.getRegion();
				if (region) region.dispose();
				_shell.dispose();
				_shell = null;
				createShell();
			}

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
				real ws = cast(real)_prop.var.etc.previewMaxWidth / _w;
				real hs = cast(real)_prop.var.etc.previewMaxHeight / _h;
				real s = std.algorithm.min(ws, hs);
				_w = cast(int)(_w * s);
				_h = cast(int)(_h * s);
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
			_shell.setBounds(_x, _y, _prop.s(_w), _prop.s(_h));
			auto data = _image.baseSizeData();
			if (!data) return;
			auto iData = data.scaled(_prop.var.etc.imageScale).scaledTo(_prop.s(_w), _prop.s(_h));
			if (_paintImage) { mixin(S_TRACE);
				_paintImage.dispose();
			}
			_paintImage = new Image(d, iData);

			// 透明色を使う場合は透明部分を除いたRegionを作る
			auto oldReg = _shell.getRegion();
			if (oldReg) oldReg.dispose();
			if (_image.transparent) { mixin(S_TRACE);
				auto region = new Region;
				auto rect = new Rectangle(0, 0, 0, 1);
				auto pixels = new int[_prop.s(_w)];
				foreach (y; 0 .. _prop.s(_h)) { mixin(S_TRACE);
					rect.y = y;
					iData.getPixels(0, y, _prop.s(_w), pixels, 0);
					int tStart = 0;
					bool t = true;
					foreach (x; 0 .. _prop.s(_w)) { mixin(S_TRACE);
						bool pt = iData.transparentPixel == pixels[x];
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
						rect.width = _prop.s(_w) - tStart;
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

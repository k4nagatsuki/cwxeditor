
module cwx.editor.gui.dwt.bgimagedialog;

import cwx.area;
import cwx.card;
import cwx.flag;
import cwx.utils;
import cwx.summary;
import cwx.background;
import cwx.imagesize;
import cwx.skin;
import cwx.structs;
import cwx.menu;
import cwx.types;
import cwx.path;
import cwx.msgutils;
import cwx.warning;

import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.chooser;

import std.algorithm : countUntil, min;
import std.traits;
import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

public:

/// 背景画像の設定を行うダイアログを定義する。
abstract class BgImageDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;
	bool _create;

	FlagChooser!(Flag, true) _flag = null;
	Spinner _x;
	Spinner _y;
	Spinner _w;
	Spinner _h;
	Button _mask;
	Spinner _layer;
	Combo _smoothing = null;
	Smoothing[] _smoothings;
	Combo _easy;
	bool _selected;

	Combo _cellName;

	protected void refreshWarning() { mixin(S_TRACE);
		// 処理無し
	}

	protected void refDataVersion() { mixin(S_TRACE);
		_layer.setEnabled(!_summ || !_summ.legacy || LAYER_BACK_CELL != _layer.getSelection());
		_cellName.setEnabled(!_summ || !_summ.legacy || _cellName.getText() != "");
		if (_smoothing) { mixin(S_TRACE);
			_smoothing.setEnabled(!_summ || !_summ.legacy || _smoothings[_smoothing.getSelectionIndex()] !is Smoothing.Default);
		}
		refreshWarning();
	}
	@property
	string[] warningCommon() { mixin(S_TRACE);
		string[] ws;
		ws ~= .sjisWarnings(_prop.parent, _summ, _cellName.getText(), _prop.msgs.bgImageCellName);
		if (_summ && _cellName.getText() != "" && !_prop.isTargetVersion(_summ, "1")) { mixin(S_TRACE);
			ws ~= _prop.msgs.warningBgImageCellName;
		}
		if (_layer.getSelection() != LAYER_BACK_CELL && !_prop.isTargetVersion(_summ, "1")) {
			ws ~= _prop.msgs.warningLayer;
		}
		if (_smoothing && _smoothings[_smoothing.getSelectionIndex()] !is Smoothing.Default && !_prop.isTargetVersion(_summ, "2")) { mixin(S_TRACE);
			ws ~= _prop.msgs.warningBgImageSmoothing;
		}
		return ws;
	}

	class SModL : ModifyListener {
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			_selected = true;
		}
	};
	class MaskListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			updateMask();
		}
	}
	class SettingsListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto c = cast(Combo) e.widget;
			int i = c.getSelectionIndex();
			switch (i) {
			case 0:
				break;
			case 1:
				if (cast(ImageCell)back || cast(PCCell)back) { mixin(S_TRACE);
					selectEasySetting();
					applyEnabled();
				} else { mixin(S_TRACE);
					goto default;
				}
				break;
			default:
				_selected = true;
				if (cast(ImageCell)back || cast(PCCell)back) { mixin(S_TRACE);
					i--;
				}
				auto s = _prop.var.etc.bgImageSettings[i - 1];
				_x.setSelection(s.x);
				_y.setSelection(s.y);
				_w.setSelection(s.width);
				_h.setSelection(s.height);
				if (_mask) _mask.setSelection(s.mask);
				_layer.setSelection(s.layer);
				updateMask();
				applyEnabled();
			}
			_comm.refreshToolBar();
		}
	}
	void delBgImage(string cwxPath) { mixin(S_TRACE);
		if (back && back.cwxPath(true) == cwxPath) { mixin(S_TRACE);
			forceCancel();
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.delBgImage.remove(&delBgImage);
				_comm.refDataVersion.remove(&refDataVersion);
			}
			_comm.refTargetVersion.remove(&refDataVersion);
		}
	}
public:
	this (Commons comm, Summary summ, Shell parent, string text, Image img, bool resizable, DSize size, bool create) { mixin(S_TRACE);
		_comm = comm;
		_summ = summ;
		_prop = comm.prop;
		_selected = !create;
		_create = create;
		super (_prop, parent, false, text, img, resizable, size, true);
		enterClose = true;
		if (create) applyEnabled(true);
	}

	@property
	BgImage back();

protected:
	Composite createFlagPanel(Composite comp) { mixin(S_TRACE);
		auto grp = new Group(comp, SWT.NONE);
		grp.setLayout(normalGridLayout(2, false));
		grp.setText(_prop.msgs.refFlag);
		_flag = new FlagChooser!(Flag, true)(_comm, _summ, grp);
		mod(_flag);
		_flag.setLayoutData(new GridData(GridData.FILL_BOTH));
		return grp;
	}

	Composite createPositionPanel(Composite comp, bool mask, bool smoothing) { mixin(S_TRACE);
		auto grp = new Group(comp, SWT.NONE);
		grp.setText(_prop.msgs.backPosition);
		grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
		auto comp2 = new Composite(grp, SWT.NONE);
		auto rowNum = mask ? 6 : 5;
		comp2.setLayout(normalGridLayout(rowNum, false));
		Spinner createS(string name, int max, int min, string hint = "") { mixin(S_TRACE);
			auto comp3 = new Composite(comp2, SWT.NONE);
			auto gl = normalGridLayout((hint == "") ? 2 : 3, false);
			gl.marginHeight = 0;
			comp3.setLayout(gl);
			auto l = new Label(comp3, SWT.NONE);
			l.setText(name);
			auto spn = new Spinner(comp3, SWT.BORDER);
			initSpinner(spn);
			mod(spn);
			spn.setMaximum(max);
			spn.setMinimum(min);
			spn.setSelection(0);
			.listener(spn, SWT.Selection, { mixin(S_TRACE);
				_easy.select(0);
			});
			if (hint != "") { mixin(S_TRACE);
				auto lp = new Label(comp3, SWT.NONE);
				lp.setText(hint);
			}
			return spn;
		}
		_x = createS(_prop.msgs.left, _prop.var.etc.posLeftMax, -(cast(int) _prop.var.etc.posLeftMax));
		_y = createS(_prop.msgs.top, _prop.var.etc.posTopMax, -(cast(int) _prop.var.etc.posTopMax));
		_w = createS(_prop.msgs.width, _prop.var.etc.backWidthMax, 0);
		_h = createS(_prop.msgs.height, _prop.var.etc.backHeightMax, 0);
		if (mask) { mixin(S_TRACE);
			_mask = new Button(comp2, SWT.TOGGLE);
			mod(_mask);
			_mask.setImage(_prop.images.menu(MenuID.Mask));
			_mask.setToolTipText(_prop.msgs.menuText(MenuID.Mask));
			_mask.addSelectionListener(new MaskListener);
		}
		_layer = createS(_prop.msgs.layer, _prop.var.etc.layerMax, LAYER_BACK_CELL, .tryFormat(_prop.msgs.layerHint, LAYER_BACK_CELL));
		.listener(_layer, SWT.Selection, &refDataVersion);
		_layer.setToolTipText(.tryFormat(_prop.msgs.layerValues, LAYER_BACK_CELL, LAYER_MENU_CARD, LAYER_PLAYER_CARD, LAYER_MESSAGE));

		if (smoothing) { mixin(S_TRACE);
			auto comp3 = new Composite(comp2, SWT.NONE);
			comp3.setLayout(zeroMarginGridLayout(2, false));
			auto cgd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			cgd.horizontalSpan = rowNum;
			comp3.setLayoutData(cgd);
			auto l = new Label(comp3, SWT.NONE);
			l.setText(_prop.msgs.smoothing);
			_smoothing = new Combo(comp3, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_smoothing.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			mod(_smoothing);
			.listener(_smoothing, SWT.Selection, &refDataVersion);
			foreach (s; [Smoothing.Default, Smoothing.True, Smoothing.False]) { mixin(S_TRACE);
				_smoothing.add(_prop.msgs.smoothingName(s));
				_smoothings ~= s;
			}
			_smoothing.select(0);
			.listener(_smoothing, SWT.Selection, &refreshWarning);
		}

		return grp;
	}
	Composite createEasySettingsPanel(Composite comp) { mixin(S_TRACE);
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroMarginGridLayout(2, false));
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(normalGridLayout(1, true));
			grp.setText(_prop.msgs.bgImageCellName);
			_cellName = createCellNameCombo(_comm, _summ, grp, &catchMod, back ? back.cellName : "");
			mod(_cellName);
			_cellName.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			.listener(_cellName, SWT.Selection, &refDataVersion);
			.listener(_cellName, SWT.Modify, &refDataVersion);
		}
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			grp.setLayout(normalGridLayout(1, true));
			grp.setText(_prop.msgs.bgImageSettings);
			_easy = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_easy.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		}
		_easy.add(_prop.msgs.defaultSelection(_prop.msgs.bgImageSettingCustom));
		if (cast(ImageCell)back || cast(PCCell)back) { mixin(S_TRACE);
			_easy.add(_prop.msgs.defaultSelection(_prop.msgs.bgImageSettingOriginal));
		}
		foreach (bs; _prop.var.etc.bgImageSettings) { mixin(S_TRACE);
			_easy.add(bs.name);
		}
		_easy.addSelectionListener(new SettingsListener);
		_easy.select(0);
		return comp2;
	}
	void createPosPanel(Composite comp, bool mask, bool smoothing) { mixin(S_TRACE);
		auto posPanel = createPositionPanel(comp, mask, smoothing);
		posPanel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		auto easyPanel = createEasySettingsPanel(comp);
		easyPanel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		scope p = comp.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = p.x;
		gd.heightHint = p.y;
		comp.setLayoutData(gd);
	}
	void setFirstParams(Composite area) { mixin(S_TRACE);
		area.addDisposeListener(new Dispose);
		if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.delBgImage.add(&delBgImage);
			_comm.refDataVersion.add(&refDataVersion);
		}
		_comm.refTargetVersion.add(&refDataVersion);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (back) { mixin(S_TRACE);
			if (_flag) { mixin(S_TRACE);
				_flag.selected = back.flag;
			}
			_x.setSelection(back.x);
			_y.setSelection(back.y);
			_w.setSelection(back.width);
			_h.setSelection(back.height);
			if (_mask) _mask.setSelection(back.mask);
			_layer.setSelection(back.layer);
			_cellName.setText(back.cellName);
		} else { mixin(S_TRACE);
			if (_flag) { mixin(S_TRACE);
				_flag.selected = "";
			}
			_x.setSelection(0);
			_y.setSelection(0);
			_w.setSelection(0);
			_h.setSelection(0);
			if (_mask) _mask.setSelection(false);
			_layer.setSelection(LAYER_BACK_CELL);
			_cellName.setText("");
		}
		auto spnl = new SModL;
		_w.addModifyListener(spnl);
		_h.addModifyListener(spnl);
	}

	void applyParams(BgImage back) { mixin(S_TRACE);
		back.flag = _flag ? _flag.selected : "";
		back.x = _x.getSelection();
		back.y = _y.getSelection();
		back.width = _w.getSelection();
		back.height = _h.getSelection();
		back.layer = _layer.getSelection();
		if (_mask) back.mask = _mask.getSelection();
		if (back.cellName != _cellName.getText()) {
			back.cellName = _cellName.getText();
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.refCellNames.call();
			}
		}
		_create = false;
	}

	void updateMask() { mixin(S_TRACE);
		// 処理無し
	}
	void selectEasySetting() { mixin(S_TRACE);
		// 処理無し
	}
}

/// イメージセルの設定を行う。
class ImageCellDialog : BgImageDialog {
private:
	ImageCell _back;

	ImageSelect!(MtType.BG_IMG) _imgPath;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws = warningCommon;
		if (_imgPath.images.isBinImg()) { mixin(S_TRACE);
			if (!_prop.targetVersion(_summ, "1.60")) { mixin(S_TRACE);
				ws ~= _prop.msgs.warningBgImageIncluded;
			}
		}
		ws ~= _imgPath.warnings;
		warning = ws;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, ImageCell back, bool create) { mixin(S_TRACE);
		_back = back;
		DSize size;
		if (summ) { mixin(S_TRACE);
			size = prop.var.areaBackgroundDlg;
		} else { mixin(S_TRACE);
			size = prop.var.areaBackgroundNFDlg;
		}
		super (comm, summ, shell, create ? prop.msgs.dlgTitNewBgImage : prop.msgs.dlgTitBgImage,
			prop.images.backs, true, size, create);
	}

	@property
	override
	BgImage back() { mixin(S_TRACE);
		return _back;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(zeroGridLayout(1));
		auto skin = _comm.skin;
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout(normalGridLayout(1, false));
			void imgs(Composite parent) { mixin(S_TRACE);
				bool including = _back && isBinImg(_back.path);
				// FIXME: CardWirth 1.60 背景イメージの格納 ここから
/+				_imgPath = new ImageSelect!(MtType.BG_IMG)(parent, SWT.NONE, _comm, _prop, _summ,
					_prop.var.etc.bgImageSampleWidth, _prop.var.etc.bgImageSampleHeight, CInsets(0, 0, 0, 0), including, true,
					() => _summ ? .toExportedImageNameWithCardName(_prop.parent, _summ.scenarioName, _summ.author, _cellName.getText()) : _cellName.getText(),
					&selectEasySetting);
+/				_imgPath = new ImageSelect!(MtType.BG_IMG)(parent, SWT.NONE, _comm, _prop, _summ,
					_prop.var.etc.bgImageSampleWidth, _prop.var.etc.bgImageSampleHeight, CInsets(0, 0, 0, 0),
					CardImagePosition.TopLeft, false, () => "", &selectEasySetting);
				// FIXME: CardWirth 1.60 背景イメージの格納 ここまで
				mod(_imgPath);
				_imgPath.modEvent ~= &refreshWarning;
				_imgPath.modEvent ~= () =>_easy.select(0);
			}
			if (_summ) { mixin(S_TRACE);
				auto sash = new SplitPane(comp, SWT.HORIZONTAL);
				sash.resizeControl1 = true;
				sash.setLayoutData(new GridData(GridData.FILL_BOTH));
				{ mixin(S_TRACE);
					imgs(sash);
				}
				createFlagPanel(sash);
				.setupWeights(sash, _prop.var.etc.backSashL, _prop.var.etc.backSashR);
			} else { mixin(S_TRACE);
				// フラグ無し
				imgs(comp);
				_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
			createPosPanel(comp, true, true);
		}

		setFirstParams(area);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_back) { mixin(S_TRACE);
			_imgPath.image = _back.path;
			_imgPath.mask = _back.mask;
			_smoothing.select(cast(int).countUntil(_smoothings, _back.smoothing));
		} else { mixin(S_TRACE);
			_imgPath.image = "";
			_imgPath.mask = false;
			_smoothing.select(cast(int).countUntil(_smoothings, Smoothing.Default));
		}
		refDataVersion();
	}

	override void updateMask() { mixin(S_TRACE);
		_imgPath.mask = _mask.getSelection();
	}
	override void selectEasySetting() { mixin(S_TRACE);
		if (!_selected || _easy.getSelectionIndex() == 1) { mixin(S_TRACE);
			string file = _imgPath.filePath;
			if (file.length > 0) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					uint x, y;
					dwtImageSize(_prop, _comm.skin, _summ, file, x, y);
					_w.setSelection(x);
					_h.setSelection(y);
					_selected = true;
					_comm.refreshToolBar();
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
	}

	override bool apply() { mixin(S_TRACE);
		auto images = _imgPath.materialPath(forceApplying);
		if (images.cancel) return false;
		if (!_back) { mixin(S_TRACE);
			_back = new ImageCell;
		}
		_back.path = images.images;
		_back.smoothing = _smoothings[_smoothing.getSelectionIndex()];
		applyParams(_back);
		getShell().setText(_prop.msgs.dlgTitBgImage);
		return true;
	}
}

/// テキストセルの設定を行う。
class TextCellDialog : BgImageDialog {
private:
	TextCell _back;

	PileImage _preview = null;
	PreviewValues _values;

	Canvas _prevPanel;
	Text _text;
	Combo _fontName;
	Spinner _size;
	ColorPicker _color;
	Button _bold;
	Button _italic;
	Button _underline;
	Button _strike;
	Button _vertical;
	Combo _borderingType;
	BorderingType[] _borderingTypes;
	ColorPicker _borderingColor;
	Spinner _borderingWidth;
	Combo _updateType;
	UpdateType[] _updateTypes;

	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws = warningCommon;
		if (!_prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
			ws ~= _prop.msgs.warningTextCell;
		}

		if (_summ) { mixin(S_TRACE);
			bool[string] wFlags;
			bool[string] wSteps;
			bool[string] wVariants;
			bool[string] wFonts;
			bool[char] wColors;
			string[] flags;
			string[] steps;
			string[] variants;
			string[] fonts;
			char[] colors;
			textUseItems(wrapReturnCode(_text.getText()), flags, steps, variants, fonts, colors);
			fonts = [];
			colors = [];
			ws ~= .textWarnings(_prop.parent, summSkin, _summ, _prop.var.etc.targetVersion,
				_text.getText(), flags, steps, variants, fonts, colors, wFlags, wSteps, wVariants, wFonts, wColors).all;
		}
		if (_updateType.getSelectionIndex() != -1) { mixin(S_TRACE);
			if (_summ && _summ.legacy) { mixin(S_TRACE);
				if (_updateTypes[_updateType.getSelectionIndex()] !is UpdateType.Fixed) { mixin(S_TRACE);
					ws ~= _prop.msgs.warningUpdateTypeNotFixed;
				}
			} else { mixin(S_TRACE);
				if (_updateTypes[_updateType.getSelectionIndex()] !is UpdateType.Variables && !_prop.isTargetVersion(_summ, "4")) { mixin(S_TRACE);
					ws ~= _prop.msgs.warningUpdateType;
				}
			}
		}

		warning = ws;
	}

	override
	protected void refDataVersion() { mixin(S_TRACE);
		super.refDataVersion();
		if (_updateType.getSelectionIndex() != -1) { mixin(S_TRACE);
			_updateType.setEnabled(!_summ || !_summ.legacy || _updateTypes[_updateType.getSelectionIndex()] !is UpdateType.Fixed);
		}
	}

	void updatePreview() { mixin(S_TRACE);
		int index = _borderingType.getSelectionIndex();
		if (index == -1) return;
		auto bType = _borderingTypes[index];
		_borderingColor.enabled = BorderingType.None !is bType;
		_borderingWidth.setEnabled(BorderingType.Inline is bType);

		CRGB tColor;
		auto rgb1 = _color.color;
		if (rgb1) { mixin(S_TRACE);
			tColor = CRGB(rgb1.red, rgb1.green, rgb1.blue, _color.alpha);
		}
		CRGB bColor;
		auto rgb2 = _borderingColor.color;
		if (rgb2) { mixin(S_TRACE);
			bColor = CRGB(rgb2.red, rgb2.green, rgb2.blue, _borderingColor.alpha);
		}

		auto ca = _prevPanel.getClientArea();
		if (_preview) _preview.dispose();
		_preview = new PileImage(wrapReturnCode(_text.getText()), _prop.drawingScale, _fontName.getText(),
			_size.getSelection(), tColor, _bold.getSelection(), _italic.getSelection(),
			_underline.getSelection(), _strike.getSelection(), _vertical.getSelection(),
			bType, bColor, _borderingWidth.getSelection(), ca.x, ca.y, ca.width, ca.height);
		_preview.previewText = &previewText;

		_preview.createImage();
		_prevPanel.redraw();
	}
	string previewText(string base) { mixin(S_TRACE);
		string[char] names;
		VarValue[string] flags;
		VarValue[string] steps;
		VarValue[string] variants;
		VarValue[string] sysSteps;
		_values.getValues(names, flags, steps, variants, sysSteps);
		return simpleFormatMsg(base, flags, steps, variants, sysSteps, names, ver => _prop.isTargetVersion(_summ, ver),
			_prop.sys.prefixSystemVarName);
	}
	class Paint : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			auto range = new Rectangle(e.x, e.y, e.width, e.height);
			auto size = _prevPanel.getSize();
			auto image = new Image(_prevPanel.getDisplay(), size.x, size.y);
			scope (exit) image.dispose();
			auto gc = new GC(image);
			scope (exit) gc.dispose();
			gc.setBackground(_prevPanel.getBackground());
			gc.fillRectangle(range);
			if (_preview) { mixin(S_TRACE);
				_preview.draw(_prevPanel.getDisplay(), image, gc, range);
			}
			e.gc.drawImage(image, 0, 0, size.x, size.y,
				0, 0, _prop.s(size.x), _prop.s(size.y));
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, TextCell back, bool create) { mixin(S_TRACE);
		_back = back;
		_summSkin = findSkin(comm, prop, summ);
		DSize size;
		if (summ) { mixin(S_TRACE);
			size = prop.var.areaTextCellDlg;
		} else { mixin(S_TRACE);
			size = prop.var.areaTextCellNFDlg;
		}
		super (comm, summ, shell, create ? prop.msgs.dlgTitNewTextCell : prop.msgs.dlgTitTextCell,
			prop.images.textCell, true, size, create);
		enterClose = false;
	}

	@property
	override
	BgImage back() { mixin(S_TRACE);
		return _back;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(zeroGridLayout(1));
		auto skin = summSkin;
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout(normalGridLayout(1, false));
		auto sash = new SplitPane(comp, SWT.VERTICAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		void left(Composite parent) { mixin(S_TRACE);
			auto comp = new Composite(parent, SWT.NONE);
			comp.setLayout(normalGridLayout(2, false));
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(normalGridLayout(1, true));
				grp.setText(_prop.msgs.image);
				_prevPanel = new Canvas(grp, SWT.BORDER | SWT.NO_BACKGROUND | SWT.DOUBLE_BUFFERED);
				_prevPanel.addPaintListener(new Paint);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.textCellPreviewWidth;
				gd.heightHint = _prop.var.etc.textCellPreviewHeight;
				_prevPanel.setLayoutData(gd);
				.listener(_prevPanel, SWT.Resize, &updatePreview);
				_comm.refImageScale.add(&updatePreview);
				.listener(_prevPanel, SWT.Dispose, { mixin(S_TRACE);
					_comm.refImageScale.remove(&updatePreview);
				});
			}
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				grp.setText(_prop.msgs.fontStyle);
				grp.setLayout(normalGridLayout(1, true));

				Button check(string name) { mixin(S_TRACE);
					auto button = new Button(grp, SWT.CHECK);
					button.setLayoutData(new GridData(GridData.FILL_BOTH));
					mod(button);
					.listener(button, SWT.Selection, &updatePreview);
					button.setText(name);
					return button;
				}
				_bold = check(_prop.msgs.bold);
				_italic = check(_prop.msgs.italic);
				_underline = check(_prop.msgs.underline);
				_strike = check(_prop.msgs.strike);
				_vertical = check(_prop.msgs.vertical);
			}
			auto sq = new Composite(comp, SWT.NONE);
			auto sqgd = new GridData(GridData.FILL_HORIZONTAL);
			sqgd.horizontalSpan = 2;
			sq.setLayoutData(sqgd);
			sq.setLayout(zeroMarginGridLayout(2, false));
			{ mixin(S_TRACE);
				auto grp = new Group(sq, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setText(_prop.msgs.font);
				grp.setLayout(new CenterLayout);

				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(4, false));

				_fontName = new Combo(comp2, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				_fontName.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				mod(_fontName);
				string[] names;
				bool[string] nameSet;
				foreach (fontData; _fontName.getDisplay().getFontList(null, true)) { mixin(S_TRACE);
					auto name = fontData.getName();
					if (!nameSet.get(name, false)) { mixin(S_TRACE);
						names ~= name;
						nameSet[name] = true;
					}
				}
				if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
					names = sort!(fnncmp)(names);
				} else { mixin(S_TRACE);
					names = sort!(fncmp)(names);
				}
				foreach (name; names) { mixin(S_TRACE);
					_fontName.add(name);
				}
				.listener(_fontName, SWT.Selection, &updatePreview);

				auto l1 = new Label(comp2, SWT.NONE);
				l1.setText(_prop.msgs.size);
				_size = new Spinner(comp2, SWT.BORDER);
				initSpinner(_size);
				mod(_size);
				_size.setMinimum(1);
				_size.setMaximum(_prop.var.etc.fontSizeMax);
				.listener(_size, SWT.Modify, &updatePreview);
				auto l2 = new Label(comp2, SWT.NONE);
				l2.setText(_prop.msgs.pixel);
			}
			{ mixin(S_TRACE);
				auto grp = new Group(sq, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.fontColor);
				_color = new ColorPicker(_prop, grp, false);
				mod(_color);
				_color.modEvent ~= &updatePreview;
			}
			{ mixin(S_TRACE);
				auto grp = new Group(sq, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setText(_prop.msgs.bordering);
				grp.setLayout(new CenterLayout);

				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(4, false));

				_borderingType = new Combo(comp2, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				_borderingType.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				mod(_borderingType);
				foreach (bType; EnumMembers!BorderingType) { mixin(S_TRACE);
					_borderingType.add(_prop.msgs.borderingTypeName(bType));
					_borderingTypes ~= bType;
				}
				.listener(_borderingType, SWT.Selection, &updatePreview);

				auto l1 = new Label(comp2, SWT.NONE);
				l1.setText(_prop.msgs.borderingWidth);
				_borderingWidth = new Spinner(comp2, SWT.BORDER);
				initSpinner(_borderingWidth);
				mod(_borderingWidth);
				_borderingWidth.setMinimum(1);
				_borderingWidth.setMaximum(_prop.var.etc.borderingWidthMax);
				.listener(_borderingWidth, SWT.Modify, &updatePreview);
				auto l2 = new Label(comp2, SWT.NONE);
				l2.setText(_prop.msgs.pixel);
			}
			{ mixin(S_TRACE);
				auto grp = new Group(sq, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.borderingColor);
				_borderingColor = new ColorPicker(_prop, grp, false);
				mod(_borderingColor);
				_borderingColor.modEvent ~= &updatePreview;
			}
		}
		{ mixin(S_TRACE);
			if (_summ) { mixin(S_TRACE);
				auto sash2 = new SplitPane(sash, SWT.HORIZONTAL);
				sash2.resizeControl1 = true;
				left(sash2);
				.setupWeights(sash2, _prop.var.etc.textCellHSashL, _prop.var.etc.textCellHSashR);
				createFlagPanel(sash2);
			} else { mixin(S_TRACE);
				// フラグ無し
				left(sash);
			}
		}
		{ mixin(S_TRACE);
			auto sash2 = new SplitPane(sash, SWT.HORIZONTAL);
			sash2.resizeControl1 = true;

			auto grp = new Group(sash2, SWT.NONE);
			grp.setText(_prop.msgs.text);
			grp.setLayout(normalGridLayout(2, false));
			_text = new Text(grp, SWT.BORDER | SWT.MULTI | SWT.V_SCROLL | SWT.H_SCROLL);
			mod(_text);
			createTextMenu!Text(_comm, _prop, _text, &catchMod);
			auto menu = _text.getMenu();
			new MenuItem(menu, SWT.SEPARATOR);
			.setupSPCharsMenu(_comm, _summ, _text, menu, false, true, () => true);
			auto gd1 = new GridData(GridData.FILL_BOTH);
			gd1.widthHint = _prop.var.etc.textCellBoxWidth;
			gd1.heightHint = _prop.var.etc.textCellBoxHeight;
			gd1.horizontalSpan = 2;
			_text.setLayoutData(gd1);
			.listener(_text, SWT.Modify, &refreshWarning);
			.listener(_text, SWT.Modify, &updatePreview);
			createSimpleSCharBar(grp, &_text.insert, _comm, _prop, _summ, skin);
			if (_summ) { mixin(S_TRACE);
				createFlagStepBar(grp, &_text.insert, _comm, _prop, _summ, skin, false).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			}

			_values = new PreviewValues(sash2, _comm, _prop, _summ, false);
			_values.modEvent ~= &updatePreview;

			.setupWeights(sash2, _prop.var.etc.textCellPreviewSashL, _prop.var.etc.textCellPreviewSashR);
		}
		.setupWeights(sash, _prop.var.etc.textCellVSashT, _prop.var.etc.textCellVSashB);

		auto updAndPosPanel = new Composite(comp, SWT.NONE);
		updAndPosPanel.setLayout(zeroMarginGridLayout(2, false));
		updAndPosPanel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{ mixin(S_TRACE);
			auto grp = new Group(updAndPosPanel, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(_prop.msgs.updateType);
			grp.setLayout(new CenterLayout);

			_updateType = new Combo(grp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			_updateType.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			mod(_updateType);

			foreach (updateType; [UpdateType.Fixed, UpdateType.Variables, UpdateType.All]) { mixin(S_TRACE);
				_updateType.add(_prop.msgs.updateTypeName(updateType));
				_updateTypes ~= updateType;
			}
			.listener(_updateType, SWT.Selection, &refDataVersion);
		}
		auto posPanel = createPositionPanel(updAndPosPanel, false, false);
		posPanel.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto easyPanel = createEasySettingsPanel(comp);
		easyPanel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		comp.setLayoutData(new GridData(GridData.FILL_BOTH));

		.listener(area, SWT.Dispose, { mixin(S_TRACE);
			if (_preview) _preview.dispose();
		});

		setFirstParams(area);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (!_create) { mixin(S_TRACE);
			_text.setText(_back.text);
			_fontName.setText(_back.fontName);
			_size.setSelection(_back.size);
			auto tc = _back.color;
			_color.color = new RGB(tc.r, tc.g, tc.b);
			_color.alpha = tc.a;
			_bold.setSelection(_back.bold);
			_italic.setSelection(_back.italic);
			_underline.setSelection(_back.underline);
			_strike.setSelection(_back.strike);
			_vertical.setSelection(_back.vertical);
			_borderingType.select(cast(int)_borderingTypes.countUntil(_back.borderingType));
			auto bc = _back.borderingColor;
			_borderingColor.color = new RGB(bc.r, bc.g, bc.b);
			_borderingColor.alpha = bc.a;
			_borderingWidth.setSelection(_back.borderingWidth);
			auto updIdx = cast(int).cCountUntil(_updateTypes, _back.updateType);
			if (updIdx == -1) updIdx = (_summ && _summ.legacy) ? 0 : 1;
			_updateType.select(updIdx);
		} else { mixin(S_TRACE);
			_text.setText("");
			if (_fontName.getItemCount()) { mixin(S_TRACE);
				_fontName.select(0);
				string[] fonts;
				if (_summ && _summ.legacy) { mixin(S_TRACE);
					fonts ~= _prop.var.etc.textCellDefaultFontClassic;
					fonts ~= _prop.var.etc.textCellDefaultFont;
				} else { mixin(S_TRACE);
					fonts ~= _prop.var.etc.textCellDefaultFont;
					fonts ~= _prop.var.etc.textCellDefaultFontClassic;
				}
				foreach (font; fonts) { mixin(S_TRACE);
					int i = _fontName.indexOf(font);
					if (i != -1) { mixin(S_TRACE);
						_fontName.select(i);
						break;
					}
				}
			}
			_size.setSelection(_prop.var.etc.textCellDefaultFontSize);
			auto tc = _prop.var.etc.textCellDefaultColor;
			_color.color = new RGB(tc.r, tc.g, tc.b);
			_color.alpha = tc.a;
			_bold.setSelection(false);
			_italic.setSelection(false);
			_underline.setSelection(false);
			_strike.setSelection(false);
			_vertical.setSelection(false);
			_borderingType.select(0);
			auto bc = _prop.var.etc.textCellDefaultBorderingColor;
			_borderingColor.color = new RGB(bc.r, bc.g, bc.b);
			_borderingColor.alpha = bc.a;
			_borderingWidth.setSelection(1);
			_updateType.select((_summ && _summ.legacy) ? 0 : 1);
		}
		refDataVersion();
		updatePreview();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_back) { mixin(S_TRACE);
			_back = new TextCell;
		}
		_back.text = wrapReturnCode(_text.getText());
		_back.fontName = _fontName.getText();
		_back.size = _size.getSelection();
		auto tc = _color.color;
		_back.color = CRGB(tc.red, tc.green, tc.blue, _color.alpha);
		_back.bold = _bold.getSelection();
		_back.italic = _italic.getSelection();
		_back.underline = _underline.getSelection();
		_back.strike = _strike.getSelection();
		_back.vertical = _vertical.getSelection();
		_back.borderingType = _borderingTypes[_borderingType.getSelectionIndex()];
		auto bc = _borderingColor.color;
		_back.borderingColor = CRGB(bc.red, bc.green, bc.blue, _borderingColor.alpha);
		_back.borderingWidth = _borderingWidth.getSelection();
		_back.updateType = _updateTypes[_updateType.getSelectionIndex()];

		applyParams(_back);
		getShell().setText(_prop.msgs.dlgTitTextCell);
		return true;
	}
}

/// カラーセルの設定を行う。
class ColorCellDialog : BgImageDialog {
private:
	ColorCell _back;

	PileImage _preview = null;
	Canvas _prevPanel;
	Button[BlendMode] _blendMode;
	Combo _gradientDir;
	GradientDir[] _gradientDirs;
	ColorPicker _color1;
	ColorPicker _color2;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws = warningCommon;
		if (!_prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
			ws ~= _prop.msgs.warningColorCell;
		}
		warning = ws;
	}
	void updatePreview() { mixin(S_TRACE);
		_color2.enabled = GradientDir.None !is _gradientDirs[_gradientDir.getSelectionIndex()];
		auto ca = _prevPanel.getClientArea();
		if (_preview) _preview.dispose();
		_preview = new PileImage(ImageType.ColorFilter, _prop.drawingScale, ca.x, ca.y, ca.width, ca.height, false);
		_preview.blendMode = getRadioValue(_blendMode);
		_preview.gradientDir = _gradientDirs[_gradientDir.getSelectionIndex()];
		auto rgb1 = _color1.color;
		if (rgb1) { mixin(S_TRACE);
			_preview.color1 = CRGB(rgb1.red, rgb1.green, rgb1.blue, _color1.alpha);
		}
		auto rgb2 = _color2.color;
		if (rgb2) { mixin(S_TRACE);
			_preview.color2 = CRGB(rgb2.red, rgb2.green, rgb2.blue, _color2.alpha);
		}
		_preview.createImage();
		_prevPanel.redraw();
	}
	class Paint : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			auto range = new Rectangle(e.x, e.y, e.width, e.height);
			auto size = _prevPanel.getSize();
			auto image = new Image(_prevPanel.getDisplay(), size.x, size.y);
			scope (exit) image.dispose();
			auto gc = new GC(image);
			scope (exit) gc.dispose();
			gc.setBackground(_prevPanel.getBackground());
			gc.fillRectangle(range);
			if (_preview) { mixin(S_TRACE);
				_preview.draw(_prevPanel.getDisplay(), image, gc, range);
			}
			e.gc.drawImage(image, 0, 0);
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, ColorCell back, bool create) { mixin(S_TRACE);
		_back = back;
		DSize size;
		if (summ) { mixin(S_TRACE);
			size = prop.var.areaColorCellDlg;
		} else { mixin(S_TRACE);
			size = prop.var.areaColorCellNFDlg;
		}
		super (comm, summ, shell, create ? prop.msgs.dlgTitNewColorCell : prop.msgs.dlgTitColorCell,
			prop.images.colorCell, true, size, create);
	}

	@property
	override
	BgImage back() { mixin(S_TRACE);
		return _back;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(zeroGridLayout(1));
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			Composite left(Composite parent) { mixin(S_TRACE);
				auto comp = new Composite(parent, SWT.NONE);
				comp.setLayout(zeroMarginGridLayout(1, true));
				{ mixin(S_TRACE);
					auto grp = new Group(comp, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(normalGridLayout(1, true));
					grp.setText(_prop.msgs.image);
					_prevPanel = new Canvas(grp, SWT.BORDER | SWT.NO_BACKGROUND | SWT.DOUBLE_BUFFERED);
					_prevPanel.addPaintListener(new Paint);
					_prevPanel.setLayoutData(new GridData(GridData.FILL_BOTH));
					.listener(_prevPanel, SWT.Resize, &updatePreview);
				}
				auto sq = new Composite(comp, SWT.NONE);
				sq.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				sq.setLayout(zeroMarginGridLayout(2, false));
				{ mixin(S_TRACE);
					auto grp = new Group(sq, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setText(_prop.msgs.blendMode);
					grp.setLayout(new CenterLayout);

					auto comp2 = new Composite(grp, SWT.NONE);
					comp2.setLayout(zeroMarginGridLayout(EnumMembers!BlendMode.length - 1, true));
					foreach (mode; EnumMembers!BlendMode) { mixin(S_TRACE);
						if (mode !is BlendMode.Mask) { mixin(S_TRACE);
							auto radio = new Button(comp2, SWT.RADIO);
							mod(radio);
							.listener(radio, SWT.Selection, &updatePreview);
							radio.setText(_prop.msgs.blendModeName(mode));
							_blendMode[mode] = radio;
						}
					}
				}
				{ mixin(S_TRACE);
					auto grp = new Group(sq, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new CenterLayout);
					grp.setText(_prop.msgs.colorCellBaseColor);
					_color1 = new ColorPicker(_prop, grp, true);
					mod(_color1);
					_color1.modEvent ~= &updatePreview;
				}
				{ mixin(S_TRACE);
					auto grp = new Group(sq, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setText(_prop.msgs.gradient);
					grp.setLayout(new CenterLayout);

					auto comp2 = new Composite(grp, SWT.NONE);
					comp2.setLayout(zeroMarginGridLayout(2, false));

					auto l1 = new Label(comp2, SWT.NONE);
					l1.setText(_prop.msgs.direction);
					_gradientDir = new Combo(comp2, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
					_gradientDir.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
					mod(_gradientDir);
					foreach (gradientDir; EnumMembers!GradientDir) { mixin(S_TRACE);
						_gradientDir.add(_prop.msgs.gradientDirName(gradientDir));
						_gradientDirs ~= gradientDir;
					}
					.listener(_gradientDir, SWT.Selection, &updatePreview);
				}
				{ mixin(S_TRACE);
					auto grp = new Group(sq, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new CenterLayout);
					grp.setText(_prop.msgs.endColor);
					_color2 = new ColorPicker(_prop, grp, true);
					mod(_color2);
					_color2.modEvent ~= &updatePreview;
				}
				return comp;
			}
			if (_summ) { mixin(S_TRACE);
				auto comp2 = new Composite(comp, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp2.setLayout(zeroMarginGridLayout(2, false));
				left(comp2).setLayoutData(new GridData(GridData.FILL_VERTICAL));
				createFlagPanel(comp2).setLayoutData(new GridData(GridData.FILL_BOTH));
			} else { mixin(S_TRACE);
				// フラグ無し
				left(comp).setLayoutData(new GridData(GridData.FILL_BOTH));
			}
		}
		createPosPanel(comp, false, false);

		.listener(area, SWT.Dispose, { mixin(S_TRACE);
			if (_preview) _preview.dispose();
		});

		setFirstParams(area);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (!_create) { mixin(S_TRACE);
			auto blendMode = _back.blendMode;
			if (_back.blendMode is BlendMode.Mask || _back.mask) { mixin(S_TRACE);
				blendMode = BlendMode.Normal;
			}
			_blendMode[blendMode].setSelection(true);
			_gradientDir.select(cast(int)_gradientDirs.countUntil(_back.gradientDir));
			_color1.color = new RGB(_back.color1.r, _back.color1.g, _back.color1.b);
			_color1.alpha = _back.color1.a;
			_color2.color = new RGB(_back.color2.r, _back.color2.g, _back.color2.b);
			_color2.alpha = _back.color2.a;
		} else { mixin(S_TRACE);
			_blendMode[BlendMode.Normal].setSelection(true);
			_gradientDir.select(cast(int)_gradientDirs.countUntil(GradientDir.None));
			auto c1 = _prop.var.etc.colorCellDefaultColor1;
			_color1.color = new RGB(c1.r, c1.g, c1.b);
			_color1.alpha = c1.a;
			auto c2 = _prop.var.etc.colorCellDefaultColor2;
			_color2.color = new RGB(c2.r, c2.g, c2.b);
			_color2.alpha = c2.a;
		}
		refDataVersion();
		updatePreview();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_back) { mixin(S_TRACE);
			_back = new ColorCell;
		}
		_back.blendMode = getRadioValue(_blendMode);
		_back.gradientDir = _gradientDirs[_gradientDir.getSelectionIndex()];
		auto rgb1 = _color1.color;
		_back.color1 = CRGB(rgb1.red, rgb1.green, rgb1.blue, _color1.alpha);
		auto rgb2 = _color2.color;
		_back.color2 = CRGB(rgb2.red, rgb2.green, rgb2.blue, _color2.alpha);

		applyParams(_back);
		getShell().setText(_prop.msgs.dlgTitColorCell);
		return true;
	}
}

/// 色を選択するためのコントロール。
class ColorPicker : Composite {
	void delegate()[] modEvent;

	private Label _colorLabel;
	private Color _color = null;
	private Button _button;
	private Spinner _alpha = null;

	this (Props prop, Composite parent, bool transparency) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			if (_color) _color.dispose();
		});

		setLayout(zeroMarginGridLayout(transparency ? 4 : 1, false));

		auto comp = new Composite(this, SWT.NONE);
		comp.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto gl = windowGridLayout(2, false);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		comp.setLayout(gl);

		_colorLabel = new Label(comp, SWT.BORDER);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = prop.var.etc.colorExampleWidth;
		_colorLabel.setLayoutData(gd);

		_button = new Button(comp, SWT.PUSH);
		_button.setText("...");
		.listener(_button, SWT.Selection, { mixin(S_TRACE);
			auto dlg = new ColorDialog(this.getShell());
			if (_color) dlg.setRGB(_color.getRGB());
			auto rgb = dlg.open();
			if (rgb) { mixin(S_TRACE);
				color = rgb;
				callMod();
			}
		});

		if (transparency) { mixin(S_TRACE);
			auto l1 = new Label(this, SWT.NONE);
			l1.setText(prop.msgs.alphaChannel);
			_alpha = new Spinner(this, SWT.BORDER);
			initSpinner(_alpha);
			_alpha.setMinimum(0);
			_alpha.setMaximum(255);
			.listener(_alpha, SWT.Modify, &callMod);
			auto l2 = new Label(this, SWT.NONE);
			l2.setText(.tryFormat(prop.msgs.rangeHint, 0, 255));
		}
	}
	private void callMod() { mixin(S_TRACE);
		foreach (dlg; modEvent) dlg();
	}

	@property
	RGB color() { mixin(S_TRACE);
		return _color ? _color.getRGB() : null;
	}
	@property
	void color(RGB rgb) { mixin(S_TRACE);
		if (_color) _color.dispose();
		_color = new Color(this.getDisplay(), rgb);
		_colorLabel.setBackground(_color);
	}
	@property
	int alpha() { mixin(S_TRACE);
		return _alpha ? _alpha.getSelection() : 255;
	}
	@property
	void alpha(int value) { mixin(S_TRACE);
		if (_alpha) _alpha.setSelection(value);
	}

	@property
	void enabled(bool enabled) { mixin(S_TRACE);
		_button.setEnabled(enabled);
		if (_alpha) _alpha.setEnabled(enabled);
		setEnabled(enabled);
	}
}

/// プレイヤーキャラクタセルの設定を行う。
class PCCellDialog : BgImageDialog {
private:
	PCCell _back;

	Canvas _prevPanel;
	Combo _pcNumber;
	Button _expand;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws = warningCommon;
		if (!_prop.isTargetVersion(_summ, "1")) { mixin(S_TRACE);
			ws ~= _prop.msgs.warningPCCell;
		}
		warning = ws;
	}
	class Paint : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			auto pcNum = _pcNumber.getSelectionIndex() + 1;
			drawCenterText(dwtData(_prop.looks.pcNumberFont(_comm.skin.legacy)), e.gc, _prevPanel.getClientArea(), .text(pcNum));
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, PCCell back, bool create) { mixin(S_TRACE);
		_back = back;
		DSize size;
		if (summ) { mixin(S_TRACE);
			size = prop.var.areaPCCellDlg;
		} else { mixin(S_TRACE);
			size = prop.var.areaPCCellNFDlg;
		}
		super (comm, summ, shell, create ? prop.msgs.dlgTitNewPCCell : prop.msgs.dlgTitPCCell,
			prop.images.pcCell, true, size, create);
	}

	@property
	override
	BgImage back() { mixin(S_TRACE);
		return _back;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(zeroGridLayout(1));
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp2.setLayout(zeroMarginGridLayout(2, false));
			{
				auto grp = new Group(comp2, SWT.NONE);
				if (_summ) { mixin(S_TRACE);
					grp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				} else { mixin(S_TRACE);
					auto ggd = new GridData(GridData.FILL_BOTH);
					ggd.horizontalSpan = 2;
					grp.setLayoutData(ggd);
				}
				grp.setLayout(normalGridLayout(1, true));
				grp.setText(_prop.msgs.cellPCNumber);

				_pcNumber = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				mod(_pcNumber);
				_pcNumber.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_pcNumber.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				foreach (i; 0 .. _prop.looks.partyCardXY.length) {
					_pcNumber.add(.tryFormat(_prop.msgs.pc, i + 1));
				}
				_pcNumber.select(0);

				_prevPanel = new Canvas(grp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
				_prevPanel.addPaintListener(new Paint);
				auto ppgd = new GridData(GridData.FILL_BOTH);
				ppgd.widthHint = _prop.var.etc.cellPCNumberWidth;
				_prevPanel.setLayoutData(ppgd);
				.listener(_pcNumber, SWT.Selection, &_prevPanel.redraw);

				_expand = new Button(grp, SWT.CHECK);
				_expand.setText(_prop.msgs.pcCellExpanding);
			}
			if (_summ) { mixin(S_TRACE);
				createFlagPanel(comp2).setLayoutData(new GridData(GridData.FILL_BOTH));
			}
		}
		createPosPanel(comp, false, true);

		setFirstParams(area);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (!_create) { mixin(S_TRACE);
			_pcNumber.select(.min(_back.pcNumber - 1, _pcNumber.getItemCount() - 1));
			_expand.setSelection(_back.expand);
			_smoothing.select(cast(int).countUntil(_smoothings, _back.smoothing));
		} else { mixin(S_TRACE);
			_pcNumber.select(0);
			_expand.setSelection(false);
			_smoothing.select(cast(int).countUntil(_smoothings, Smoothing.Default));
		}
		refDataVersion();
	}

	override void selectEasySetting() { mixin(S_TRACE);
		if (!_selected || _easy.getSelectionIndex() == 1) { mixin(S_TRACE);
			auto cardSize = _prop.looks.cardSize;
			_w.setSelection(cardSize.width);
			_h.setSelection(cardSize.height);
			_selected = true;
			_comm.refreshToolBar();
		}
	}

	override bool apply() { mixin(S_TRACE);
		if (!_back) { mixin(S_TRACE);
			_back = new PCCell;
		}
		_back.pcNumber = _pcNumber.getSelectionIndex() + 1;
		_back.expand = _expand.getSelection();
		_back.smoothing = _smoothings[_smoothing.getSelectionIndex()];

		applyParams(_back);
		getShell().setText(_prop.msgs.dlgTitPCCell);
		return true;
	}
}

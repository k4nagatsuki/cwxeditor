
module cwx.editor.gui.dwt.bgimagedialog;

import cwx.area;
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

import std.algorithm : countUntil;
import std.traits;

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
	Combo _easy;
	bool _selected;

	void refreshWarning() {
		// 処理無し
	}

	class SModL : ModifyListener {
		override void modifyText(ModifyEvent e) {
			_selected = true;
		}
	};
	class MaskListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			updateMask();
		}
	}
	class SettingsListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto c = cast(Combo) e.widget;
			int i = c.getSelectionIndex();
			switch (i) {
			case 0:
				break;
			case 1:
				if (cast(ImageCell) back) {
					selectEasySetting();
					applyEnabled();
				} else {
					goto default;
				}
				break;
			default:
				_selected = true;
				if (cast(ImageCell) back) {
					i--;
				}
				auto s = _prop.var.etc.bgImageSettings[i - 1];
				_x.setSelection(s.x);
				_y.setSelection(s.y);
				_w.setSelection(s.width);
				_h.setSelection(s.height);
				if (_mask) _mask.setSelection(s.mask);
				updateMask();
				applyEnabled();
			}
			_comm.refreshToolBar();
		}
	}
	void delBgImage(string cwxPath) {
		if (back && back.cwxPath(true) == cwxPath) {
			forceCancel();
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.delBgImage.remove(&delBgImage);
			_comm.refTargetVersion.remove(&refreshWarning);
		}
	}
public:
	this (Commons comm, Summary summ, Shell parent, string text, Image img, bool resizable, DSize size, bool create) {
		_comm = comm;
		_summ = summ;
		_prop = comm.prop;
		_selected = !create;
		_create = create;
		super (_prop, parent, false, text, img, resizable, size, true);
		enterClose = true;
	}

	@property
	BgImage back();

protected:
	Composite createFlagPanel(Composite comp) {
		auto grp = new Group(comp, SWT.NONE);
		grp.setLayout(new GridLayout(2, false));
		grp.setText(_prop.msgs.refFlag);
		_flag = new FlagChooser!(Flag, true)(_comm, grp);
		mod(_flag);
		_flag.setLayoutData(new GridData(GridData.FILL_BOTH));
		return grp;
	}

	Composite createPositionPanel(Composite comp, bool mask) {
		auto grp = new Group(comp, SWT.NONE);
		grp.setText(_prop.msgs.cardPosition);
		grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
		auto comp2 = new Composite(grp, SWT.NONE);
		comp2.setLayout(new GridLayout(mask ? 5 : 4, false));
		Spinner createS(string name, int max, int min) {
			auto comp3 = new Composite(comp2, SWT.NONE);
			auto gl = new GridLayout(2, false);
			gl.marginHeight = 0;
			comp3.setLayout(gl);
			auto l = new Label(comp3, SWT.NONE);
			l.setText(name);
			auto spn = new Spinner(comp3, SWT.BORDER);
			mod(spn);
			spn.setMaximum(max);
			spn.setMinimum(min);
			spn.setSelection(0);
			.listener(spn, SWT.Selection, {
				_easy.select(0);
			});
			return spn;
		}
		_x = createS(_prop.msgs.left, _prop.var.etc.posLeftMax, -(cast(int) _prop.var.etc.posLeftMax));
		_y = createS(_prop.msgs.top, _prop.var.etc.posTopMax, -(cast(int) _prop.var.etc.posTopMax));
		_w = createS(_prop.msgs.width, _prop.var.etc.backWidthMax, 0);
		_h = createS(_prop.msgs.height, _prop.var.etc.backHeightMax, 0);
		if (mask) {
			_mask = new Button(comp2, SWT.TOGGLE);
			mod(_mask);
			_mask.setImage(_prop.images.menu(MenuID.Mask));
			_mask.setToolTipText(_prop.buildTool(MenuID.Mask));
			_mask.addSelectionListener(new MaskListener);
		}
		return grp;
	}
	Composite createEasySettingsPanel(Composite comp) {
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(new GridLayout(2, false));
		auto l = new Label(comp2, SWT.NONE);
		l.setText(_prop.msgs.bgImageSettings);
		_easy = new Combo(comp2, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
		_easy.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		_easy.add(_prop.msgs.bgImageSettingCustom);
		if (cast(ImageCell) back) {
			_easy.add(_prop.msgs.bgImageSettingOriginal);
		}
		foreach (bs; _prop.var.etc.bgImageSettings) {
			_easy.add(bs.name);
		}
		_easy.addSelectionListener(new SettingsListener);
		_easy.select(0);
		return comp2;
	}
	void createPosPanel(Composite comp, bool mask) {
		auto posPanel = createPositionPanel(comp, mask);
		posPanel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		auto easyPanel = createEasySettingsPanel(comp);
		easyPanel.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
		scope p = comp.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = p.x;
		gd.heightHint = p.y;
		comp.setLayoutData(gd);
	}
	void setFirstParams(Composite area) {
		area.addDisposeListener(new Dispose);
		_comm.delBgImage.add(&delBgImage);
		_comm.refTargetVersion.add(&refreshWarning);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (back) {
			if (_flag) {
				_flag.selected = back.flag;
			}
			_x.setSelection(back.x);
			_y.setSelection(back.y);
			_w.setSelection(back.width);
			_h.setSelection(back.height);
			if (_mask) _mask.setSelection(back.mask);
		} else {
			if (_flag) {
				_flag.selected = "";
			}
			_x.setSelection(0);
			_y.setSelection(0);
			_w.setSelection(0);
			_h.setSelection(0);
			if (_mask) _mask.setSelection(false);
		}
		auto spnl = new SModL;
		_w.addModifyListener(spnl);
		_h.addModifyListener(spnl);
	}

	void applyParams(BgImage back) {
		back.flag = _flag ? _flag.selected : "";
		back.x = _x.getSelection();
		back.y = _y.getSelection();
		back.width = _w.getSelection();
		back.height = _h.getSelection();
		if (_mask) back.mask = _mask.getSelection();
		_create = false;
	}

	void updateMask() {
		// 処理無し
	}
	void selectEasySetting() {
		// 処理無し
	}
}

/// イメージセルの設定を行う。
class ImageCellDialog : BgImageDialog {
private:
	ImageCell _back;

	ImageSelect!(MtType.BG_IMG) _imgPath;

	void refreshWarning() {
		warning = _comm.skin.warningImage(_prop.parent, _imgPath.filePath, _summ ? _summ.legacy : false, _prop.var.etc.targetVersion);
	}

	class SDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights();
			_prop.var.etc.backSashL = ws[0];
			_prop.var.etc.backSashR = ws[1];
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, ImageCell back, bool create) {
		_back = back;
		DSize size;
		if (summ) {
			size = prop.var.areaBackgroundDlg;
		} else {
			size = prop.var.areaBackgroundNFDlg;
		}
		super (comm, summ, shell, create ? prop.msgs.dlgTitNewBgImage : prop.msgs.dlgTitBgImage,
			prop.images.backs, true, size, create);
	}

	@property
	override
	BgImage back() {
		return _back;
	}
protected:
	override void setup(Composite area) {
		area.setLayout(zeroGridLayout(1));
		auto skin = _comm.skin;
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout(new GridLayout(1, false));
			void imgs(Composite parent) {
				_imgPath = new ImageSelect!(MtType.BG_IMG)(parent, SWT.NONE, _comm, _prop, _summ,
					_prop.var.etc.bgImageSampleWidth, _prop.var.etc.bgImageSampleHeight, false, false,
					() => "", &selectEasySetting);
				mod(_imgPath);
				_imgPath.modEvent ~= &refreshWarning;
				_imgPath.modEvent ~= () =>_easy.select(0);
			}
			if (_summ) {
				auto sash = new SplitPane(comp, SWT.HORIZONTAL);
				sash.setLayoutData(new GridData(GridData.FILL_BOTH));
				{
					imgs(sash);
				}
				createFlagPanel(sash);
				sash.setWeights([_prop.var.etc.backSashL, _prop.var.etc.backSashR]);
				sash.addDisposeListener(new SDListener);
			} else {
				// フラグ無し
				imgs(comp);
				_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
			createPosPanel(comp, true);
		}

		setFirstParams(area);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_back) {
			_imgPath.image = _back.path;
			_imgPath.mask = _back.mask;
		} else {
			_imgPath.image = "";
			_imgPath.mask = false;
		}
	}

	override void updateMask() {
		_imgPath.mask = _mask.getSelection();
	}
	override void selectEasySetting() {
		if (!_selected || _easy.getSelectionIndex() == 1) {
			string file = _imgPath.filePath;
			if (file.length > 0) {
				try {
					uint x, y;
					dwtImageSize(_prop, _comm.skin, _summ, file, x, y);
					_w.setSelection(x);
					_h.setSelection(y);
					_selected = true;
					_comm.refreshToolBar();
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
	}

	override bool apply() {
		if (!_back) {
			_back = new ImageCell;
		}
		_back.path = _imgPath.image;
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

	void refreshWarning() {
		string[] ws = [];
		if (!_prop.targetVersion("1.50")) {
			ws ~= _prop.msgs.warningTextCell;
		}
		warning = ws;
	}
	void updatePreview() {
		int index = _borderingType.getSelectionIndex();
		if (index == -1) return;
		auto bType = _borderingTypes[index];
		_borderingColor.enabled = BorderingType.None !is bType;
		_borderingWidth.setEnabled(BorderingType.Inline is bType);

		CRGB tColor;
		auto rgb1 = _color.color;
		if (rgb1) {
			tColor = CRGB(rgb1.red, rgb1.green, rgb1.blue, _color.alpha);
		}
		CRGB bColor;
		auto rgb2 = _borderingColor.color;
		if (rgb2) {
			bColor = CRGB(rgb2.red, rgb2.green, rgb2.blue, _borderingColor.alpha);
		}

		auto ca = _prevPanel.getClientArea();
		if (_preview) _preview.dispose();
		_preview = new PileImage(wrapReturnCode(_text.getText()), _fontName.getText(),
			_size.getSelection(), tColor, _bold.getSelection(), _italic.getSelection(),
			_underline.getSelection(), _strike.getSelection(), _vertical.getSelection(),
			bType, bColor, _borderingWidth.getSelection(), ca.x, ca.y, ca.width, ca.height);
		_preview.previewText = &previewText;

		_preview.createImage();
		_prevPanel.redraw();
	}
	string previewText(string base) {
		string[char] names;
		string[string] flags;
		string[string] steps;
		_values.getValues(names, flags, steps);
		return simpleFormatMsg(base, flags, steps, names);
	}
	class Paint : PaintListener {
		override void paintControl(PaintEvent e) {
			auto range = new Rectangle(e.x, e.y, e.width, e.height);
			auto size = _prevPanel.getSize();
			auto image = new Image(_prevPanel.getDisplay(), size.x, size.y);
			scope (exit) image.dispose();
			auto gc = new GC(image);
			scope (exit) gc.dispose();
			gc.setBackground(_prevPanel.getBackground());
			gc.fillRectangle(range);
			if (_preview) {
				_preview.draw(image, gc, range);
			}
			e.gc.drawImage(image, 0, 0);
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, TextCell back, bool create) {
		_back = back;
		DSize size;
		if (summ) {
			size = prop.var.areaTextCellDlg;
		} else {
			size = prop.var.areaTextCellNFDlg;
		}
		super (comm, summ, shell, create ? prop.msgs.dlgTitNewTextCell : prop.msgs.dlgTitTextCell,
			prop.images.textCell, true, size, create);
		enterClose = false;
	}

	@property
	override
	BgImage back() {
		return _back;
	}
protected:
	override void setup(Composite area) {
		area.setLayout(zeroGridLayout(1));
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		auto sash = new SplitPane(comp, SWT.VERTICAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		void left(Composite parent) {
			auto comp = new Composite(parent, SWT.NONE);
			comp.setLayout(new GridLayout(2, false));
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new GridLayout(1, true));
				grp.setText(_prop.msgs.image);
				_prevPanel = new Canvas(grp, SWT.BORDER | SWT.NO_BACKGROUND | SWT.DOUBLE_BUFFERED);
				_prevPanel.addPaintListener(new Paint);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.textCellPreviewWidth;
				gd.heightHint = _prop.var.etc.textCellPreviewHeight;
				_prevPanel.setLayoutData(gd);
				.listener(_prevPanel, SWT.Resize, &updatePreview);
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				grp.setText(_prop.msgs.fontStyle);
				grp.setLayout(new GridLayout(1, true));

				Button check(string name) {
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
			{
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
				foreach (fontData; _fontName.getDisplay().getFontList(null, true)) {
					auto name = fontData.getName();
					if (!nameSet.get(name, false)) {
						names ~= name;
						nameSet[name] = true;
					}
				}
				if (_prop.var.etc.logicalSort) {
					names = sort!(fnncmp)(names);
				} else {
					names = sort!(fncmp)(names);
				}
				foreach (name; names) {
					_fontName.add(name);
				}
				.listener(_fontName, SWT.Selection, &updatePreview);

				auto l1 = new Label(comp2, SWT.NONE);
				l1.setText(_prop.msgs.size);
				_size = new Spinner(comp2, SWT.BORDER);
				mod(_size);
				_size.setMinimum(1);
				_size.setMaximum(_prop.var.etc.fontSizeMax);
				.listener(_size, SWT.Modify, &updatePreview);
				auto l2 = new Label(comp2, SWT.NONE);
				l2.setText(_prop.msgs.pixel);
			}
			{
				auto grp = new Group(sq, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.fontColor);
				_color = new ColorPicker(_prop, grp, false);
				mod(_color);
				_color.modEvent ~= &updatePreview;
			}
			{
				auto grp = new Group(sq, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setText(_prop.msgs.bordering);
				grp.setLayout(new CenterLayout);

				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(4, false));

				_borderingType = new Combo(comp2, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				_borderingType.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				mod(_borderingType);
				foreach (bType; EnumMembers!BorderingType) {
					_borderingType.add(_prop.msgs.borderingTypeName(bType));
					_borderingTypes ~= bType;
				}
				.listener(_borderingType, SWT.Selection, &updatePreview);

				auto l1 = new Label(comp2, SWT.NONE);
				l1.setText(_prop.msgs.borderingWidth);
				_borderingWidth = new Spinner(comp2, SWT.BORDER);
				mod(_borderingWidth);
				_borderingWidth.setMinimum(1);
				_borderingWidth.setMaximum(_prop.var.etc.borderingWidthMax);
				.listener(_borderingWidth, SWT.Modify, &updatePreview);
				auto l2 = new Label(comp2, SWT.NONE);
				l2.setText(_prop.msgs.pixel);
			}
			{
				auto grp = new Group(sq, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.borderingColor);
				_borderingColor = new ColorPicker(_prop, grp, false);
				mod(_borderingColor);
				_borderingColor.modEvent ~= &updatePreview;
			}
		}
		{
			if (_summ) {
				auto sash2 = new SplitPane(sash, SWT.HORIZONTAL);
				left(sash2);
				sash2.setWeights([_prop.var.etc.textCellHSashL, _prop.var.etc.textCellHSashR]);
				.listener(sash2, SWT.Dispose, {
					_prop.var.etc.textCellHSashL = sash2.getWeights()[0];
					_prop.var.etc.textCellHSashR = sash2.getWeights()[1];
				});
				createFlagPanel(sash2);
			} else {
				// フラグ無し
				left(sash);
			}
		}
		{
			auto sash2 = new SplitPane(sash, SWT.HORIZONTAL);

			auto grp = new Group(sash2, SWT.NONE);
			grp.setText(_prop.msgs.text);
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			cl.fillVertical = true;
			grp.setLayout(cl);
			_text = new Text(grp, SWT.BORDER | SWT.MULTI | SWT.V_SCROLL | SWT.H_SCROLL);
			mod(_text);
			createTextMenu!Text(_comm, _prop, _text, &catchMod);
			_text.setLayoutData(new Point(_prop.var.etc.textCellBoxWidth, _prop.var.etc.textCellBoxHeight));
			.listener(_text, SWT.Modify, &updatePreview);

			_values = new PreviewValues(sash2, _comm, _prop, _summ, false);
			_values.modEvent ~= &updatePreview;

			sash2.setWeights([_prop.var.etc.textCellPreviewSashL, _prop.var.etc.textCellPreviewSashR]);
			.listener(sash, SWT.Dispose, {
				_prop.var.etc.textCellPreviewSashL = sash2.getWeights()[0];
				_prop.var.etc.textCellPreviewSashR = sash2.getWeights()[1];
			});
		}
		sash.setWeights([_prop.var.etc.textCellVSashT, _prop.var.etc.textCellVSashB]);
		.listener(sash, SWT.Dispose, {
			_prop.var.etc.textCellVSashT = sash.getWeights()[0];
			_prop.var.etc.textCellVSashB = sash.getWeights()[1];
		});

		createPosPanel(comp, false);

		.listener(area, SWT.Dispose, {
			if (_preview) _preview.dispose();
		});

		setFirstParams(area);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (!_create) {
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
			_borderingType.select(_borderingTypes.countUntil(_back.borderingType));
			auto bc = _back.borderingColor;
			_borderingColor.color = new RGB(bc.r, bc.g, bc.b);
			_borderingColor.alpha = bc.a;
			_borderingWidth.setSelection(_back.borderingWidth);
		} else {
			_text.setText("");
			if (_fontName.getItemCount()) {
				_fontName.select(0);
				string[] fonts;
				if (_summ && _summ.legacy) {
					fonts ~= _prop.var.etc.textCellDefaultFontClassic;
					fonts ~= _prop.var.etc.textCellDefaultFont;
				} else {
					fonts ~= _prop.var.etc.textCellDefaultFont;
					fonts ~= _prop.var.etc.textCellDefaultFontClassic;
				}
				foreach (font; fonts) {
					int i = _fontName.indexOf(font);
					if (i != -1) {
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
		}
		refreshWarning();
		updatePreview();
	}

	override bool apply() {
		if (!_back) {
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

	void refreshWarning() {
		string[] ws = [];
		if (!_prop.targetVersion("1.50")) {
			ws ~= _prop.msgs.warningColorCell;
		}
		warning = ws;
	}
	void updatePreview() {
		_color2.enabled = GradientDir.None !is _gradientDirs[_gradientDir.getSelectionIndex()];
		auto ca = _prevPanel.getClientArea();
		if (_preview) _preview.dispose();
		_preview = new PileImage(ImageType.ColorFilter, ca.x, ca.y, ca.width, ca.height);
		_preview.blendMode = getRadioValue(_blendMode);
		_preview.gradientDir = _gradientDirs[_gradientDir.getSelectionIndex()];
		auto rgb1 = _color1.color;
		if (rgb1) {
			_preview.color1 = CRGB(rgb1.red, rgb1.green, rgb1.blue, _color1.alpha);
		}
		auto rgb2 = _color2.color;
		if (rgb2) {
			_preview.color2 = CRGB(rgb2.red, rgb2.green, rgb2.blue, _color2.alpha);
		}
		_preview.createImage();
		_prevPanel.redraw();
	}
	class Paint : PaintListener {
		override void paintControl(PaintEvent e) {
			auto range = new Rectangle(e.x, e.y, e.width, e.height);
			auto size = _prevPanel.getSize();
			auto image = new Image(_prevPanel.getDisplay(), size.x, size.y);
			scope (exit) image.dispose();
			auto gc = new GC(image);
			scope (exit) gc.dispose();
			gc.setBackground(_prevPanel.getBackground());
			gc.fillRectangle(range);
			if (_preview) {
				_preview.draw(image, gc, range);
			}
			e.gc.drawImage(image, 0, 0);
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, ColorCell back, bool create) {
		_back = back;
		DSize size;
		if (summ) {
			size = prop.var.areaColorCellDlg;
		} else {
			size = prop.var.areaColorCellNFDlg;
		}
		super (comm, summ, shell, create ? prop.msgs.dlgTitNewColorCell : prop.msgs.dlgTitColorCell,
			prop.images.colorCell, true, size, create);
	}

	@property
	override
	BgImage back() {
		return _back;
	}
protected:
	override void setup(Composite area) {
		area.setLayout(zeroGridLayout(1));
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{
			Composite left(Composite parent) {
				auto comp = new Composite(parent, SWT.NONE);
				comp.setLayout(zeroMarginGridLayout(1, true));
				{
					auto grp = new Group(comp, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(1, true));
					grp.setText(_prop.msgs.image);
					_prevPanel = new Canvas(grp, SWT.BORDER | SWT.NO_BACKGROUND | SWT.DOUBLE_BUFFERED);
					_prevPanel.addPaintListener(new Paint);
					_prevPanel.setLayoutData(new GridData(GridData.FILL_BOTH));
					.listener(_prevPanel, SWT.Resize, &updatePreview);
				}
				auto sq = new Composite(comp, SWT.NONE);
				sq.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				sq.setLayout(zeroMarginGridLayout(2, false));
				{
					auto grp = new Group(sq, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setText(_prop.msgs.blendMode);
					grp.setLayout(new CenterLayout);

					auto comp2 = new Composite(grp, SWT.NONE);
					comp2.setLayout(zeroMarginGridLayout(EnumMembers!BlendMode.length - 1, true));
					foreach (mode; EnumMembers!BlendMode) {
						if (mode is BlendMode.Mask) continue;
						auto radio = new Button(comp2, SWT.RADIO);
						mod(radio);
						.listener(radio, SWT.Selection, &updatePreview);
						radio.setText(_prop.msgs.blendModeName(mode));
						_blendMode[mode] = radio;
					}
				}
				{
					auto grp = new Group(sq, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new CenterLayout);
					grp.setText(_prop.msgs.colorCellBaseColor);
					_color1 = new ColorPicker(_prop, grp, true);
					mod(_color1);
					_color1.modEvent ~= &updatePreview;
				}
				{
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
					foreach (gradientDir; EnumMembers!GradientDir) {
						_gradientDir.add(_prop.msgs.gradientDirName(gradientDir));
						_gradientDirs ~= gradientDir;
					}
					.listener(_gradientDir, SWT.Selection, &updatePreview);
				}
				{
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
			if (_summ) {
				auto comp2 = new Composite(comp, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp2.setLayout(zeroMarginGridLayout(2, false));
				left(comp2).setLayoutData(new GridData(GridData.FILL_VERTICAL));
				createFlagPanel(comp2).setLayoutData(new GridData(GridData.FILL_BOTH));
			} else {
				// フラグ無し
				left(comp).setLayoutData(new GridData(GridData.FILL_BOTH));
			}
		}
		createPosPanel(comp, false);

		.listener(area, SWT.Dispose, {
			if (_preview) _preview.dispose();
		});

		setFirstParams(area);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (!_create) {
			auto blendMode = _back.blendMode;
			if (_back.blendMode is BlendMode.Mask || _back.mask) {
				blendMode = BlendMode.Normal;
			}
			_blendMode[blendMode].setSelection(true);
			_gradientDir.select(_gradientDirs.countUntil(_back.gradientDir));
			_color1.color = new RGB(_back.color1.r, _back.color1.g, _back.color1.b);
			_color1.alpha = _back.color1.a;
			_color2.color = new RGB(_back.color2.r, _back.color2.g, _back.color2.b);
			_color2.alpha = _back.color2.a;
		} else {
			_blendMode[BlendMode.Normal].setSelection(true);
			_gradientDir.select(_gradientDirs.countUntil(GradientDir.None));
			auto c1 = _prop.var.etc.colorCellDefaultColor1;
			_color1.color = new RGB(c1.r, c1.g, c1.b);
			_color1.alpha = c1.a;
			auto c2 = _prop.var.etc.colorCellDefaultColor2;
			_color2.color = new RGB(c2.r, c2.g, c2.b);
			_color2.alpha = c2.a;
		}
		refreshWarning();
		updatePreview();
	}

	override bool apply() {
		if (!_back) {
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

	this (Props prop, Composite parent, bool transparency) {
		super (parent, SWT.NONE);
		.listener(this, SWT.Dispose, {
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
		gd.widthHint = 50;
		_colorLabel.setLayoutData(gd);

		_button = new Button(comp, SWT.PUSH);
		_button.setText("...");
		.listener(_button, SWT.Selection, {
			auto dlg = new ColorDialog(this.getShell());
			if (_color) dlg.setRGB(_color.getRGB());
			auto rgb = dlg.open();
			if (rgb) {
				color = rgb;
				callMod();
			}
		});

		if (transparency) {
			auto l1 = new Label(this, SWT.NONE);
			l1.setText(prop.msgs.alphaChannel);
			_alpha = new Spinner(this, SWT.BORDER);
			_alpha.setMinimum(0);
			_alpha.setMaximum(255);
			.listener(_alpha, SWT.Modify, &callMod);
			auto l2 = new Label(this, SWT.NONE);
			l2.setText(.tryFormat(prop.msgs.rangeHint, 0, 255));
		}
	}
	private void callMod() {
		foreach (dlg; modEvent) dlg();
	}

	@property
	RGB color() {
		return _color ? _color.getRGB() : null;
	}
	@property
	void color(RGB rgb) {
		if (_color) _color.dispose();
		_color = new Color(this.getDisplay(), rgb);
		_colorLabel.setBackground(_color);
	}
	@property
	int alpha() {
		return _alpha ? _alpha.getSelection() : 255;
	}
	@property
	void alpha(int value) {
		if (_alpha) _alpha.setSelection(value);
	}

	@property
	void enabled(bool enabled) {
		_button.setEnabled(enabled);
		if (_alpha) _alpha.setEnabled(enabled);
		setEnabled(enabled);
	}
}

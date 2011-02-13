
module cwx.editor.gui.dwt.summarydialog;

import cwx.utils;
import cwx.usecounter;
import cwx.summary;
import cwx.area;
import cwx.event;
import cwx.skin;
import cwx.card;

import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;

import std.string;

import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontData;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;

public:

/// シナリオの概略を設定するダイアログ。
class SummaryDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;

	Canvas _summImage;
	Text _sname;
	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	Text _author;
	Spinner _levMin, _levMax;
	Table _startArea;
	Spinner _rCouponNum;
	Text _rCoupons;
	Combo _type;
	SplitPane _tab2Sash, _tab3Sash;
	bool _hasLegacySkin;
	// TODO Tag
	// TODO Label

	void levMaxEnter(int enter) {
		if (enter > 0 && _levMin.getSelection != 0 && enter < _levMin.getSelection) {
			_levMin.setSelection = enter;
		}
	}
	void levMinEnter(int enter) {
		if (enter > 0 && _levMax.getSelection != 0 && enter > _levMax.getSelection) {
			_levMax.setSelection = enter;
		}
	}

	class PListener : PaintListener {
		override void paintControl(PaintEvent e) {
			auto d = Display.getCurrent;
			auto size = _prop.looks.summarySize;
			scope buf = new Image(d, size.width, size.height);
			scope (exit) buf.dispose;
			scope gc = new GC(buf);
			scope (exit) gc.dispose;

			Skin skin;
			if (_summ.legacy && _hasLegacySkin && _type.getSelectionIndex == 0) {
				skin = Skin.legacySkin(_prop.parent, _prop.var.etc.enginePath,
					_summ.scenarioPath);
			} else {
				skin = Skin.find(_prop.parent, _prop.var.etc.enginePath,
					_type.getText, _summ.scenarioPath, _summ.legacy);
			}
			{
				scope img = new Image(d, summary(skin));
				gc.drawImage(img, 0, 0);
				img.dispose;
			}
			if (_imgPath.image !is null && _imgPath.image.length > 0) {
				string imgPath = skin.findImagePath(_imgPath.image, _summ.scenarioPath);
				if (imgPath.length) {
					scope img = new Image(d, loadImage(skin, imgPath));
					gc.drawImage(img, _prop.looks.summaryImageXY.x, _prop.looks.summaryImageXY.y);
					img.dispose;
				}
			}
			{
				void drawCenterText(FontData fontData, string text, int y) {
					scope font = new Font(d, fontData);
					gc.setFont = font;
					scope p = gc.stringExtent(text);
					gc.drawString(text, (size.width - p.x) / 2, y, true);
					font.dispose;
				}
				int alpha;
				scope c = new Color(d, dwtData(_prop.looks.summaryLevelColor, alpha));
				gc.setForeground = c;
				gc.setAlpha = alpha;
				drawCenterText(dwtData(_prop.looks.summaryLevelFont(skin.legacy)),
					_prop.msgs.targetLevel(_levMin.getSelection, _levMax.getSelection),
					_prop.looks.summaryLevelY);
				c.dispose;
				gc.setAlpha = 255;
				gc.setForeground = d.getSystemColor(SWT.COLOR_BLACK);
				drawCenterText(dwtData(_prop.looks.summaryTitleFont(skin.legacy)),
					_sname.getText, _prop.looks.summaryTitleY);
				{
					scope font = new Font(d, dwtData(_prop.looks.summaryDescFont(skin.legacy)));
					gc.setFont = font;
					int hig = gc.getFontMetrics.getHeight;
					int x = _prop.looks.summaryDescXY.x;
					int y = _prop.looks.summaryDescXY.y;
					gc.drawText(_desc.getRRText, x, y, SWT.DRAW_DELIMITER | SWT.DRAW_TRANSPARENT);
					gc.setFont = null;
					font.dispose;
				}
				drawCenterText(dwtData(_prop.looks.summaryPageFont(skin.legacy)),
					_prop.msgs.summaryPageDummy, _prop.looks.summaryPageY);
			}
			auto rect = _summImage.getClientArea;
			if (rect.width < size.width || rect.height < size.height) {
				real wp = cast(real) rect.width / size.width;
				real hp = cast(real) rect.height / size.height;
				ImageData data;
				if (wp < hp) {
					size.width = rect.width;
					size.height = cast(int) (size.height * wp);
				} else {
					size.width = cast(int) (size.width * hp);
					size.height = rect.height;
				}
				data = buf.getImageData.scaledTo(size.width, size.height);
				buf.dispose;
				buf = null;
				if (size.width > 0 && size.height > 0) {
					buf = new Image(d, data);
				}
			}
			if (buf) {
				auto bx = (rect.width - size.width) / 2;
				auto by = (rect.height - size.height) / 2;
				e.gc.drawImage(buf, bx, by);
			}
		}
	}
	void constructTab1(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.BORDER);
		comp.setLayout = zeroGridLayout(1);
		_summImage = new Canvas(comp, SWT.DOUBLE_BUFFERED);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.looks.summarySize.width;
		gd.heightHint = _prop.looks.summarySize.height;
		_summImage.setLayoutData = gd;
		_summImage.addPaintListener(new PListener);
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText = _prop.msgs.summaryImage;
		tab.setControl = comp;
	}
	private void setCDataX(Control c, GridData data) {
		auto p = c.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		data.widthHint = p.x;
		c.setLayoutData = data;
	}
	private void setCDataXY(Control c, GridData data) {
		auto p = c.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		data.widthHint = p.x;
		data.heightHint = p.y;
		c.setLayoutData = data;
	}
	void constructTab2(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, true);
		{
			_tab2Sash = new SplitPane(comp, SWT.HORIZONTAL);
			_tab2Sash.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto skin = _comm.skin;
			{
				bool including = isBinImg(_summ.imagePath);
				string saveName = including ? _summ.scenarioName : "";
				_imgPath = new ImageSelect!(MtType.CARD)(_tab2Sash, SWT.NONE, _comm, _prop, _summ,
					_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, saveName);
				_imgPath.image = _summ.imagePath;
			}
			{
				auto comp2 = new Composite(_tab2Sash, SWT.NONE);
				comp2.setLayout = zeroGridLayout(1, true);
				{
					auto grp = centerGroup(comp2, _prop.msgs.title, true, false, new GridData(GridData.FILL_BOTH));
					grp.setLayout = new GridLayout(1, true);
					_sname = new Text(grp, SWT.BORDER);
					setCDataX(_sname, new GridData(GridData.FILL_HORIZONTAL));
					_sname.setText = _summ.scenarioName;
					checker(_sname);
				}
				{
					auto grp = centerGroup(comp2, _prop.msgs.author, true, false, new GridData(GridData.FILL_BOTH));
					grp.setLayout = new GridLayout(1, true);
					_author = new Text(grp, SWT.BORDER);
					setCDataX(_author, new GridData(GridData.FILL_HORIZONTAL));
					_author.setText = _summ.author;
				}
				{
					auto grp = centerGroup(comp2, _prop.msgs.targetLevel, false, false, new GridData(GridData.FILL_BOTH));
					grp.setLayout = new GridLayout(3, false);
					_levMin = new Spinner(grp, SWT.BORDER);
					_levMin.setSelection = _summ.levelMin;
					_levMin.setMinimum = 0;
					_levMin.setMaximum = _prop.looks.levelMax;
					new SpinnerEdit(_levMin, &levMinEnter);
					auto lbl = new Label(grp, SWT.NONE);
					lbl.setText = _prop.msgs.levSep;
					lbl.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
					_levMax = new Spinner(grp, SWT.BORDER);
					_levMax.setSelection = _summ.levelMax;
					_levMax.setMinimum = 0;
					_levMax.setMaximum = _prop.looks.levelMax;
					new SpinnerEdit(_levMax, &levMaxEnter);
				}
			}
			_tab2Sash.setWeights = [_prop.var.etc.summaryParamSashL, _prop.var.etc.summaryParamSashR];
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new CenterLayout(SWT.HORIZONTAL);
			grp.setText = _prop.msgs.desc;
			_desc = new FixedWidthText(dwtData(_prop.looks.summaryDescFont(_summ.legacy)), _prop.looks.summaryDescLen, grp, SWT.BORDER);
			_desc.widget.setLayoutData = _desc.computeTextBaseSize(_prop.looks.summaryDescLine);
			_desc.setText = _summ.desc;
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText = _prop.msgs.baseData;
		tab.setControl = comp;
	}
	void constructTab3(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, true);
		{
			_tab3Sash = new SplitPane(comp, SWT.HORIZONTAL);
			_tab3Sash.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto skin = _comm.skin;
			{
				auto comp2 = new Composite(_tab3Sash, SWT.NONE);
				comp2.setLayout = zeroMarginGridLayout(1, true);
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					grp.setText = _prop.msgs.scenarioType;
					grp.setLayout = new GridLayout(1, true);
					_type = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
					_type.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					if (_summ.legacy) {
						string resDir, lEnginePath;
						_hasLegacySkin = Skin.findLegacy(_summ.scenarioPath, resDir, lEnginePath);
						if (_hasLegacySkin) {
							auto lSkin = Skin.legacySkin(_prop.parent, _prop.var.etc.enginePath, _summ.scenarioPath);
							_type.add(_prop.msgs.legacyEngineSkin(lSkin.engine));
						}
					}
					foreach (type; skinTable(_prop).keys.sort) {
						_type.add(type);
					}
					if (!_type.getItemCount) {
						// スキンが無い
						_type.add(_prop.var.etc.defaultSkin);
					}
					if (!_summ.type.length) {
						_type.select = 0;
					} else {
						int index = _type.indexOf(_summ.type);
						_type.setText = index >= 0 ? _summ.type : _prop.var.etc.defaultSkin;
					}
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setLayoutData = new GridData(GridData.FILL_BOTH);
					grp.setText = _prop.msgs.qualification;
					grp.setLayout = new GridLayout(2, false);
					{
						auto lblN = new Label(grp, SWT.NONE);
						lblN.setText = _prop.msgs.rCouponNum;
						_rCouponNum = new Spinner(grp, SWT.BORDER);
						_rCouponNum.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
						_rCouponNum.setSelection = _summ.rCouponNum;
						_rCouponNum.setMaximum = 999;
						_rCouponNum.setMinimum = 0;
					}
					{
						auto lblR = new Label(grp, SWT.NONE);
						auto gd = new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING);
						gd.horizontalSpan = 2;
						lblR.setLayoutData = gd;
						lblR.setText = _prop.msgs.rCoupons;
					}
					{
						_rCoupons = new Text(grp, SWT.BORDER | SWT.MULTI | SWT.WRAP);
						auto gd = new GridData(GridData.FILL_BOTH);
						gd.horizontalSpan = 2;
						setCDataXY(_rCoupons, gd);
						string buf;
						foreach (i, t; _summ.rCoupons) {
							buf ~= t;
							buf ~= "\n";
						}
						_rCoupons.setText = buf;
					}
				}
			}
			{
				auto grp = new Group(_tab3Sash, SWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setText = _prop.msgs.startArea;
				grp.setLayout = new GridLayout(1, false);
				_startArea = new Table(grp, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
				auto idCol = new TableColumn(_startArea, SWT.NONE);
				saveColumnWidth!("prop.var.etc.idColumn")(_prop, idCol);
				auto nameCol = new FullTableColumn(_startArea, SWT.NONE);
				setCDataXY(_startArea, new GridData(GridData.FILL_BOTH));
				foreach (i, area; _summ.areas) {
					auto itm = new TableItem(_startArea, SWT.NONE);
					itm.setData = area;
					itm.setImage(0, _prop.images.area);
					itm.setText(0, to!(string)(area.id));
					itm.setText(1, area.name);
					if (area.id == _summ.startArea) {
						_startArea.setSelection(i);
					}
				}
				_startArea.showSelection;
			}
			_tab3Sash.setWeights = [_prop.var.etc.rCouponsStartAreaSashL, _prop.var.etc.rCouponsStartAreaSashR];
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText = _prop.msgs.etcData;
		tab.setControl = comp;
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ) {
		assert (summ !is null);
		_comm = comm;
		_summ = summ;
		_prop = prop;
		super(prop, shell, _prop.msgs.dlgTitSummary(_summ.scenarioName),
			_prop.images.summary, true, _prop.var.summaryDlg);
	}

protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1, true);
		auto tabf = new CTabFolder(area, SWT.BORDER);
		tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
		constructTab1(tabf);
		constructTab2(tabf);
		constructTab3(tabf);
	}

	private void setNamesOne(C : EffectCard)(ref C card) {
		if (card.scenario == _summ.scenarioName && card.author == _summ.author) {
			card.author = _author.getText;
			card.scenario = _sname.getText;
		}
	}
	private void setNames(C)(C[] cards) {
		foreach (ref card; cards) {
			setNamesOne(card);
		}
		setContentNames(cards);
	}
	private void setContentNames(C : EventTreeOwner)(C[] etos) {
		void setContentNames(Content c) {
			foreach (m; c.motions) {
				auto beast = m.beast;
				if (beast) {
					setNamesOne(beast);
				}
			}
			foreach (n; c.next) setContentNames(n);
		}
		foreach (ref eto; etos) {
			foreach (ref tree; eto.trees) {
				foreach (ref start; tree.starts) {
					setContentNames(start);
				}
			}
		}
	}
	override bool close(bool ok) {
		if (ok) {
			setNames(_summ.skills);
			setNames(_summ.items);
			setNames(_summ.beasts);
			foreach (card; _summ.casts) {
				setNames(card.skills);
				setNames(card.items);
				setNames(card.beasts);
			}
			setContentNames(_summ.areas);
			foreach (area; _summ.areas) setContentNames(area.cards);
			setContentNames(_summ.battles);
			foreach (area; _summ.battles) setContentNames(area.cards);
			setContentNames(_summ.packages);
			_summ.scenarioName = _sname.getText;
			_summ.author = _author.getText;
			_summ.desc = _desc.getRRText;
			_summ.imagePath = _imgPath.image;
			_summ.levelMin = _levMin.getSelection;
			_summ.levelMax = _levMax.getSelection;
			string[] rcs;
			foreach (s; splitlines(_rCoupons.getText)) {
				if (s.length > 0) {
					rcs ~= s;
				}
			}
			_summ.rCoupons = rcs;
			_summ.rCouponNum = _rCouponNum.getSelection;
			_summ.startArea = _startArea.getItemCount > 0 && _startArea.getSelection.length > 0
				? (cast(Area) _startArea.getSelection[0].getData).id : 0;
			if (_summ.legacy && _hasLegacySkin && _type.getSelectionIndex == 0) {
				_summ.type = "";
			} else {
				_summ.type = _type.getText;
			}
			_comm.skin = findSkin(_prop, _summ);
		}
		auto ws1 = _tab2Sash.getWeights;
		_prop.var.etc.summaryParamSashL = ws1[0];
		_prop.var.etc.summaryParamSashR = ws1[1];
		auto ws2 = _tab3Sash.getWeights;
		_prop.var.etc.rCouponsStartAreaSashL = ws2[0];
		_prop.var.etc.rCouponsStartAreaSashR = ws2[1];
		return ok;
	}
}

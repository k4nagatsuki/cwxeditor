
module cwx.editor.gui.dwt.summarydialog;

import cwx.utils;
import cwx.usecounter;
import cwx.summary;
import cwx.area;
import cwx.event;
import cwx.skin;
import cwx.card;
import cwx.structs;

import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dmenu;

import std.conv;
import std.string;
import std.path;

import org.eclipse.swt.all;

public:

/// シナリオの概略を設定するダイアログ。
class SummaryDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;

	SummaryPreview _summImage = null;
	Composite _imgArea;

	Text _sname;
	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	Text _author;
	Spinner _levMin, _levMax;
	Table _startArea;
	Spinner _rCouponNum;
	Text _rCoupons;
	Button _typeSkin;
	Button _typeClassic;
	Combo _type;
	bool _hasLegacySkin;
	ClassicEngine[] _classicEngines;
	SplitPane _tab2Sash, _tab3Sash;
	// TODO Tag
	// TODO Label

	void refreshWarning()  {
		warning = _comm.skin.warningImage(_prop.parent, _imgPath.filePath, _summ.legacy);
	}

	void levMaxEnter(int enter) {
		if (enter > 0 && _levMin.getSelection() != 0 && enter < _levMin.getSelection()) {
			_levMin.setSelection(enter);
		}
	}
	void levMinEnter(int enter) {
		if (enter > 0 && _levMax.getSelection() != 0 && enter > _levMax.getSelection()) {
			_levMax.setSelection(enter);
		}
	}

	@property
	Skin selectedSkin() {
		if (_typeSkin.getSelection()) {
			auto p = _type.getText() in skinTable(_prop);
			if (p) {
				return *p;
			}
		} else if (_typeClassic.getSelection()) {
			int i = _type.getSelectionIndex();
			if (_hasLegacySkin) {
				if (i == 0) {
					return .findSkin(_comm, _prop, _summ, null, "", false);
				}
				i--;
			}
			return .createClassicSkin(_prop, _classicEngines[i]);
		}
		return .findSkin2(_prop, _prop.var.etc.defaultSkin);
	}
	void constructImage(Composite area) {
		_imgArea = area;

		auto aComp = addition();
		aComp.setLayout(new GridLayout(1, true));
		auto prev = new Button(aComp, SWT.TOGGLE);
		prev.setText(_prop.msgs.messagePreview);
		prev.setSelection(_prop.var.etc.showSummaryPreview);
		.listener(prev, SWT.Selection, {
			showImagePreview(prev.getSelection());
		});
		showImagePreview(_prop.var.etc.showSummaryPreview, false);
	}
	void showImagePreview(bool visible, bool regWin = true) {
		if (getShell().isVisible()) getShell().setRedraw(false);
		scope (exit) {
			if (getShell().isVisible()) getShell().setRedraw(true);
		}

		int w;
		if (visible) {
			if (_summImage) return;
			_summImage = new SummaryPreview(_comm, _imgArea, SWT.NONE);
			_summImage.setImageSelect(&_sname.getText, &_imgPath.image, &selectedSkin, {return _desc.getRRText();}, &_levMin.getSelection, &_levMax.getSelection);
			_summImage.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			w = _summImage.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
		} else {
			if (!_summImage) return;
			w = _summImage.getSize().x;
			if (_summImage) _summImage.dispose();
			_summImage = null;
		}
		_prop.var.etc.showSummaryPreview = visible;

		if (regWin) {
			auto ws = getShell().getSize();
			if (visible) {
				ws.x += w;
			} else {
				ws.x -= w;
			}
			getShell().setSize(ws);
		}
	}
	void refreshPreview() {
		if (_summImage) {
			_summImage.redrawImage();
		}
	}
	void clearBuf() {
		if (_summImage) {
			_summImage.clearBuf();
		}
	}
	private void setCDataX(Control c, GridData data) {
		auto p = c.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		data.widthHint = p.x;
		c.setLayoutData(data);
	}
	private void setCDataXY(Control c, GridData data) {
		auto p = c.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		data.widthHint = p.x;
		data.heightHint = p.y;
		c.setLayoutData(data);
	}
	void constructTab1(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		{
			_tab2Sash = new SplitPane(comp, SWT.HORIZONTAL);
			_tab2Sash.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto skin = _comm.skin;
			{
				bool including = isBinImg(_summ.imagePath);
				_imgPath = new ImageSelect!(MtType.CARD)(_tab2Sash, SWT.NONE, _comm, _prop, _summ,
					_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, true, () => _sname.getText(), &clearBuf);
				mod(_imgPath);
				_imgPath.modEvent ~= &refreshWarning;
				_imgPath.image = _summ.imagePath;
				_imgPath.modEvent ~= &refreshPreview;
				_imgPath.updateImageEvent ~= &refreshPreview;
			}
			{
				auto comp2 = new Composite(_tab2Sash, SWT.NONE);
				comp2.setLayout(zeroGridLayout(1, true));
				{
					auto grp = centerGroup(comp2, _prop.msgs.title, true, false, new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(1, true));
					_sname = new Text(grp, SWT.BORDER);
					createTextMenu!Text(_comm, _prop, _sname, &catchMod);
					mod(_sname);
					setCDataX(_sname, new GridData(GridData.FILL_HORIZONTAL));
					_sname.setText(_summ.scenarioName);
					checker(_sname);
					.listener(_sname, SWT.Modify, &refreshPreview);
				}
				{
					auto grp = centerGroup(comp2, _prop.msgs.author, true, false, new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(1, true));
					_author = new Text(grp, SWT.BORDER);
					createTextMenu!Text(_comm, _prop, _author, &catchMod);
					mod(_author);
					setCDataX(_author, new GridData(GridData.FILL_HORIZONTAL));
					_author.setText(_summ.author);
				}
				{
					auto grp = centerGroup(comp2, _prop.msgs.targetLevel, false, false, new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(3, false));
					_levMin = new Spinner(grp, SWT.BORDER);
					mod(_levMin);
					_levMin.setSelection(_summ.levelMin);
					_levMin.setMinimum(0);
					_levMin.setMaximum(_prop.var.etc.levelMax);
					new SpinnerEdit(_levMin, &levMinEnter);
					auto lbl = new Label(grp, SWT.NONE);
					lbl.setText(_prop.msgs.levSep);
					lbl.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
					_levMax = new Spinner(grp, SWT.BORDER);
					mod(_levMax);
					_levMax.setSelection(_summ.levelMax);
					_levMax.setMinimum(0);
					_levMax.setMaximum(_prop.var.etc.levelMax);
					new SpinnerEdit(_levMax, &levMaxEnter);
					.listener(_levMin, SWT.Modify, &refreshPreview);
					.listener(_levMax, SWT.Modify, &refreshPreview);
				}
			}
			_tab2Sash.setWeights([_prop.var.etc.summaryParamSashL, _prop.var.etc.summaryParamSashR]);
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			grp.setText(_prop.msgs.desc);
			_desc = new FixedWidthText(dwtData(_prop.looks.summaryDescFont(_summ.legacy)), _prop.looks.summaryDescLen, grp, SWT.BORDER);
			createTextMenu!Text(_comm, _prop, _desc.widget, &catchMod);
			mod(_desc.widget);
			_desc.widget.setLayoutData(_desc.computeTextBaseSize(_prop.looks.summaryDescLine));
			_desc.setText(_summ.desc);
			.listener(_desc.widget, SWT.Modify, &refreshPreview);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.baseData);
		tab.setControl(comp);
	}
	void constructTab2(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		{
			_tab3Sash = new SplitPane(comp, SWT.HORIZONTAL);
			_tab3Sash.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto skin = _comm.skin;
			{
				auto comp2 = new Composite(_tab3Sash, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(1, true));
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					grp.setText(_prop.msgs.scenarioType);
					grp.setLayout(new GridLayout(1, true));
					auto refTypes = new RefreshTypes;
					_typeSkin = new Button(grp, SWT.RADIO);
					_typeSkin.setText(_prop.msgs.sTypeXML);
					_typeSkin.addSelectionListener(refTypes);
					_typeClassic = new Button(grp, SWT.RADIO);
					_typeClassic.setText(_prop.msgs.sTypeClassic);
					_typeClassic.addSelectionListener(refTypes);
					_type = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
					mod(_type);
					_type.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
					_type.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					refreshTypes();
					.listener(_typeSkin, SWT.Selection, &refreshPreview);
					.listener(_typeClassic, SWT.Selection, &refreshPreview);
					.listener(_type, SWT.Modify, &refreshPreview);
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setText(_prop.msgs.qualification);
					grp.setLayout(new GridLayout(2, false));
					{
						auto lblN = new Label(grp, SWT.NONE);
						lblN.setText(_prop.msgs.rCouponNum);
						_rCouponNum = new Spinner(grp, SWT.BORDER);
						mod(_rCouponNum);
						_rCouponNum.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						_rCouponNum.setSelection(_summ.rCouponNum);
						_rCouponNum.setMaximum(999);
						_rCouponNum.setMinimum(0);
					}
					{
						auto lblR = new Label(grp, SWT.NONE);
						auto gd = new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING);
						gd.horizontalSpan = 2;
						lblR.setLayoutData(gd);
						lblR.setText(_prop.msgs.rCoupons);
					}
					{
						_rCoupons = new Text(grp, SWT.BORDER | SWT.MULTI | SWT.WRAP);
						createTextMenu!Text(_comm, _prop, _rCoupons, &catchMod);
						mod(_rCoupons);
						auto gd = new GridData(GridData.FILL_BOTH);
						gd.horizontalSpan = 2;
						setCDataXY(_rCoupons, gd);
						string buf;
						foreach (i, t; _summ.rCoupons) {
							buf ~= t;
							buf ~= "\n";
						}
						_rCoupons.setText(buf);
					}
				}
			}
			{
				auto grp = new Group(_tab3Sash, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setText(_prop.msgs.startArea);
				grp.setLayout(new GridLayout(1, false));
				_startArea = new Table(grp, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
				mod(_startArea);
				auto idCol = new TableColumn(_startArea, SWT.NONE);
				saveColumnWidth!("prop.var.etc.idColumn")(_prop, idCol);
				auto nameCol = new FullTableColumn(_startArea, SWT.NONE);
				setCDataXY(_startArea, new GridData(GridData.FILL_BOTH));
				refreshAreas();
			}
			_tab3Sash.setWeights([_prop.var.etc.rCouponsStartAreaSashL, _prop.var.etc.rCouponsStartAreaSashR]);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.etcData);
		tab.setControl(comp);
	}
	class RefreshTypes : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshTypes();
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws1 = _tab2Sash.getWeights();
			_prop.var.etc.summaryParamSashL = ws1[0];
			_prop.var.etc.summaryParamSashR = ws1[1];
			auto ws2 = _tab3Sash.getWeights();
			_prop.var.etc.rCouponsStartAreaSashL = ws2[0];
			_prop.var.etc.rCouponsStartAreaSashR = ws2[1];
			_comm.refArea.remove(&refArea);
			_comm.delArea.remove(&refArea);
			_comm.refScenario.remove(&refScenario);
			_comm.refSkin.remove(&refSkin);
			_comm.refClassicSkin.remove(&refreshTypes);
		}
	}
	void refreshAreas() {
		ignoreMod = true;
		scope (exit) ignoreMod = false;

		auto index = _startArea.getSelectionIndex();
		ulong id;
		if (-1 != index) {
			id = (cast(Area) _startArea.getItem(index).getData()).id;
		} else {
			id = _summ.startArea;
		}
		_startArea.removeAll();
		foreach (i, area; _summ.areas) {
			auto itm = new TableItem(_startArea, SWT.NONE);
			itm.setData(area);
			itm.setImage(0, _prop.images.area);
			itm.setText(0, to!(string)(area.id));
			itm.setText(1, area.name);
			if (area.id == id) {
				_startArea.setSelection(i);
			}
		}
		if (!_startArea.getSelection().length) {
			foreach (i, area; _summ.areas) {
				if (area.id == _summ.startArea) {
					_startArea.setSelection(i);
				}
			}
		}
		_startArea.showSelection();
	}
	void refArea(Area area) {
		refreshAreas();
	}
	void refScenario(Summary summ) {
		forceCancel();
	}
	void refSkin(Object sender) {
		refreshPreview();
		_desc.font = dwtData(_prop.looks.summaryDescFont(_summ.legacy));
		if (sender is this) return;
		refreshTypes();
	}
	void refreshTypes() {
		string selType = _summ.type;
		string selClassic = null;

		if (!_typeSkin.getSelection() && !_typeClassic.getSelection()) {
			if (_comm.skin.legacy) {
				_typeClassic.setSelection(true);
			} else {
				_typeSkin.setSelection(true);
			}
			selType = _summ.type;
			selClassic = _comm.skin.legacyEngine.length ? _comm.skin.legacyEngine : null;
		} else {
			if (_typeSkin.getSelection()) {
				selType = _type.getText();
			} else if (_typeClassic.getSelection()) {
				int i = _type.getSelectionIndex();
				if (-1 != i && i < _classicEngines.length) {
					if (_hasLegacySkin) {
						if (0 < i) {
							selClassic = _prop.toAppAbs(_classicEngines[i - 1].enginePath);
						}
					} else {
						selClassic = _prop.toAppAbs(_classicEngines[i].enginePath);
					}
				}
				if (selClassic) selClassic = nabs(selClassic);
			}
		}
		_classicEngines = [];
		foreach (e; _prop.var.etc.classicEngines) {
			_classicEngines ~= e.dup;
		}

		_type.removeAll();
		void initSkin() {
			// XML形式のスキン
			string[] skins;
			foreach (key, value; skinTable(_prop)) {
				skins ~= key;
			}
			// FIXME: リンクに失敗する
//			auto skins = table.keys;
			if (_prop.var.etc.logicalSort) {
				skins = sort!(ncmp)(skins);
			} else {
				skins = sort!(cmp)(skins);
			}
			foreach (i, type; skins) {
				_type.add(type);
				if (type == selType) {
					_type.select(i);
				}
			}
			if (!_type.getItemCount()) {
				// スキンが無い
				_type.add(_prop.var.etc.defaultSkin);
			}
		}
		_hasLegacySkin = false;
		_typeClassic.setEnabled(true);
		if (_typeSkin.getSelection()) {
			initSkin();
		} else {
			assert (_typeClassic.getSelection());
			// クラシックエンジンのリソース
			string resDir, lEnginePath;
			auto curSkin = Skin.findLegacy(_summ.scenarioPath, resDir, lEnginePath, _prop.var.etc.classicEngineRegex, _prop.var.etc.classicDataDirRegex, _prop.var.etc.classicMatchKey, _prop.var.etc.classicEngines);
			lEnginePath = nabs(lEnginePath);
			bool cur = 0 != lEnginePath.length;
			foreach (i, ce; _classicEngines) {
				_type.add(ce.name);
				if (selClassic && cfnmatch(selClassic, _prop.toAppAbs(ce.enginePath))) {
					_type.select(i);
				}
				if (cur && cfnmatch(lEnginePath, _prop.toAppAbs(ce.enginePath))) {
					cur = false;
					if (-1 == _type.getSelectionIndex()) _type.select(i);
				}
			}
			if (cur) {
				_type.add(.tryFormat(_prop.msgs.currentEngineSkin, lEnginePath), 0);
				_hasLegacySkin = true;
			}
			if (!_type.getItemCount()) {
				// クラシックエンジンが無い
				_typeClassic.setEnabled(false);
				_typeClassic.setSelection(false);
				_typeSkin.setSelection(true);
				initSkin();
			}
		}
		assert (_type.getItemCount());
		if (-1 == _type.getSelectionIndex()) {
			_type.select(0);
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ) {
		assert (summ !is null);
		_comm = comm;
		_summ = summ;
		_prop = prop;
		super(prop, shell, false, .tryFormat(_prop.msgs.dlgTitSummary, _summ.scenarioName),
			_prop.images.summary, true, _prop.var.summaryDlg, true);
	}

protected:
	override void setup(Composite area) {
		area.setLayout(windowGridLayout(2, false));

		auto tabf = new CTabFolder(area, SWT.BORDER);
		tabf.setLayoutData(new GridData(GridData.FILL_BOTH));
		constructTab1(tabf);
		constructTab2(tabf);
		constructImage(area);

		_comm.refArea.add(&refArea);
		_comm.delArea.add(&refArea);
		_comm.refScenario.add(&refScenario);
		_comm.refSkin.add(&refSkin);
		_comm.refClassicSkin.add(&refreshTypes);
		area.addDisposeListener(new Dispose);
	}

	override bool apply() {
		string oldName = _summ.scenarioName;
		string oldResDir = nabs(_comm.skin.resDir);
		scope (exit) {
			if (oldName != _summ.scenarioName) _comm.refScenarioName.call();
			if (!cfnmatch(oldResDir, nabs(_comm.skin.resDir))) _comm.refSkin.call(this);
			_comm.refUseCount.call();
		}
		_summ.setBaseParams(_sname.getText(), _author.getText());
		_summ.desc = _desc.getRRText();
		_summ.imagePath = _imgPath.image;
		_summ.levelMin = _levMin.getSelection();
		_summ.levelMax = _levMax.getSelection();
		string[] rcs;
		foreach (s; splitLines!string(_rCoupons.getText())) {
			if (s.length > 0) {
				rcs ~= s;
			}
		}
		_summ.rCoupons = rcs;
		_summ.rCouponNum = _rCouponNum.getSelection();
		int si = _startArea.getSelectionIndex();
		_summ.startArea = _startArea.getItemCount() > 0 && si != -1
			? (cast(Area) _startArea.getItem(si).getData()).id : 0;
		if (_typeSkin.getSelection()) {
			_summ.type = _type.getText();
		} else {
			_summ.type = "";
		}
		_comm.skin = selectedSkin;
		_comm.refCoupons.call();
		return true;
	}
}

private class SummaryPreview : Composite {

	private Commons _comm;
	private Props _prop;
	private Summary _summ;

	private Canvas _summImage;
	private string delegate() _sname = null;
	private string delegate() _imgPath = null;
	private Skin delegate() _selectedSkin = null;
	private string delegate() _desc = null;
	private int delegate() _levMin = null;
	private int delegate() _levMax = null;

	private Image _summImageBuf = null;
	private ImageData _bufImgData = null;
	private string _bufImagePath = null;

	private class PListener : PaintListener {
		override void paintControl(PaintEvent e) {
			if (!_imgPath) return;
			auto d = Display.getCurrent();
			auto size = _prop.looks.summarySize;
			auto rect = _summImage.getClientArea();
			scope buf = new Image(d, size.width, size.height);
			scope (exit) buf.dispose();
			scope gc = new GC(buf);
			scope (exit) gc.dispose();

			auto skin = _selectedSkin();
			auto imgPath = _imgPath();
			auto path = nabs(skin.findImagePath(imgPath, _summ.scenarioPath));
			if (!_bufImagePath || !_summImageBuf || !.cfnmatch(_bufImagePath, path) || summary(skin) !is _bufImgData) {
				if (_summImageBuf) _summImageBuf.dispose();
				_bufImagePath = path;
				_bufImgData = summary(skin);
				_summImageBuf = new Image(d, _bufImgData);
			}
			gc.drawImage(_summImageBuf, 0, 0);

			if (imgPath !is null && imgPath.length > 0) {
				string p = skin.findImagePath(imgPath, _summ.scenarioPath);
				if (p.length) {
					scope img = new Image(d, loadImage(skin, p));
					gc.drawImage(img, _prop.looks.summaryImageXY.x, _prop.looks.summaryImageXY.y);
					img.dispose();
				}
			}
			{
				void drawCenterText(FontData fontData, string text, int y) {
					scope font = new Font(d, fontData);
					gc.setFont(font);
					scope p = gc.stringExtent(text);
					gc.drawString(text, (size.width - p.x) / 2, y, true);
					font.dispose();
				}
				int alpha;
				scope c = new Color(d, dwtData(_prop.looks.summaryLevelColor, alpha));
				gc.setForeground(c);
				gc.setAlpha(alpha);
				int levL = _levMin();
				int levH = _levMax();
				string levText;
				if (levL > 0 && levL == levH) {
					levText = .tryFormat(_prop.msgs.targetLevelSame, levL);
				} else if (levL > 0 && levH > 0) {
					levText = .tryFormat(_prop.msgs.targetLevelHL, levL, levH);
				} else if (levL > 0 && levH == 0) {
					levText = .tryFormat(_prop.msgs.targetLevelL, levL);
				} else if (levL == 0 && levH > 0) {
					levText = .tryFormat(_prop.msgs.targetLevelH, levH);
				} else {
					levText = "";
				}
				drawCenterText(dwtData(_prop.looks.summaryLevelFont(skin.legacy)),
					levText, _prop.looks.summaryLevelY);
				c.dispose();
				gc.setAlpha(255);
				gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				drawCenterText(dwtData(_prop.looks.summaryTitleFont(skin.legacy)), _sname(), _prop.looks.summaryTitleY);
				scope font = new Font(d, dwtData(_prop.looks.summaryDescFont(skin.legacy)));
				gc.setFont(font);
				int hig = gc.getFontMetrics().getHeight();
				int x = _prop.looks.summaryDescXY.x;
				int y = _prop.looks.summaryDescXY.y;
				string desc = _desc();
				if (_comm.skin.legacy) {
					foreach (line; splitLines!string(desc)) {
						gc.drawText(line, x, y, SWT.DRAW_DELIMITER | SWT.DRAW_TRANSPARENT);
						y += _prop.looks.summaryDescLineHeightClassic;
					}
				} else {
					gc.drawText(desc, x, y, SWT.DRAW_DELIMITER | SWT.DRAW_TRANSPARENT);
				}
				gc.setFont(null);
				font.dispose();
				drawCenterText(dwtData(_prop.looks.summaryPageFont(skin.legacy)),
					_prop.msgs.summaryPageDummy, _prop.looks.summaryPageY);
			}
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
				data = _summImageBuf.getImageData().scaledTo(size.width, size.height);
				_summImageBuf.dispose();
				_summImageBuf = null;
				if (size.width > 0 && size.height > 0) {
					_summImageBuf = new Image(d, data);
				}
			}
			auto bx = (rect.width - size.width) / 2;
			auto by = (rect.height - size.height) / 2;
			e.gc.drawImage(buf, bx, by);
		}
	}

	this (Commons comm, Composite parent, int style) {
		super (parent, style);
		_comm = comm;
		_prop = comm.prop;
		_summ = comm.summary;

		this.setLayout(new FillLayout());

		auto grp = new Group(this, SWT.NONE);
		grp.setLayoutData(new GridData(GridData.FILL_BOTH));
		grp.setText(_prop.msgs.summaryPreview);
		grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL));

		auto size = _prop.looks.summarySize;
		_summImage = new Canvas(grp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
		_summImage.setLayoutData(_summImage.computeSize(size.width, size.height));
		_summImage.addPaintListener(new PListener);

		_comm.refSkin.add(&clearBuf);
		.listener(this, SWT.Dispose, {
			_comm.refSkin.remove(&clearBuf);
			clearBuf();
		});
	}

	void setImageSelect(string delegate() sname, string delegate() imgPath, Skin delegate() selectedSkin, string delegate() desc, int delegate() levMin, int delegate() levMax) {
		_sname = sname;
		_imgPath = imgPath;
		_selectedSkin = selectedSkin;
		_desc = desc;
		_levMin = levMin;
		_levMax = levMax;
	}

	void redrawImage() {
		_summImage.redraw();
	}

	void clearBuf() {
		if (_summImageBuf) _summImageBuf.dispose();
		_summImageBuf = null;
		_bufImagePath = null;
	}
}

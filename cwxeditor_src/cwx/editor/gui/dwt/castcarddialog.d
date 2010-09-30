
module cwx.editor.gui.dwt.castcarddialog;

import cwx.coupon;
import cwx.summary;
import cwx.card;
import cwx.types;
import cwx.features;
import cwx.utils;
import cwx.race;
import cwx.xml;
import cwx.skin;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.radarspinner;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.absdialog;

import std.date;
import std.string;

import dwt.DWT;
import dwt.widgets.Display;
import dwt.widgets.Shell;
import dwt.widgets.Control;
import dwt.widgets.Composite;
import dwt.widgets.Combo;
import dwt.widgets.Event;
import dwt.widgets.Label;
import dwt.widgets.Listener;
import dwt.widgets.Group;
import dwt.widgets.Button;
import dwt.widgets.Spinner;
import dwt.widgets.Scale;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.widgets.Text;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.custom.CTabFolder;
import dwt.custom.CTabItem;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.layout.RowLayout;
import dwt.layout.RowData;
import dwt.layout.FillLayout;
import dwt.graphics.Image;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.ModifyListener;
import dwt.events.ModifyEvent;
import dwt.dwthelper.utils;
import dwt.dnd.DND;
import dwt.dnd.DragSourceAdapter;
import dwt.dnd.DragSourceEvent;
import dwt.dnd.DragSource;
import dwt.dnd.DropTargetAdapter;
import dwt.dnd.DropTargetEvent;
import dwt.dnd.DropTarget;
import dwt.dnd.Clipboard;
import dwt.dnd.Transfer;
import dwt.dnd.ByteArrayTransfer;

public:

/// キャストカードの設定を行うダイアログ。
class CastCardDialog : AbsDialog {
private:
	string _id;

	Commons _comm;
	Props _prop;
	Summary _summ;
	CastCard _card;

	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	GBLimitText _name;
	Spinner _level;
	Spinner _lifeMax;
	Text _newCoupon;
	Spinner _couponVal;
	Table _coupons;
	Combo _race;
	Button[Sex] _sex;
	Button _sexU;
	Button[Period] _period;
	Button _periodU;
	Button[Nature] _nature;
	Button _natureU;
	Button[Makings] _makings;
	Button _resW;
	Button _resM;
	Button _undead;
	Button _automaton;
	Button _unholy;
	Button _constructure;
	Button _res[Element];
	Button _weak[Element];
	int[Physical] _phyTbl;
	RadarSpinner _phy;
	Scale[Mental] _mtl;
	int[Enhance] _enhTbl;
	RadarSpinner _enh;

	Spinner _life;
	Button _lifeUseMax;
	Spinner[Enhance] _liveEnh;
	Spinner[Enhance] _enhRound;
	Spinner _paralyze;
	Spinner _poison;
	Spinner _bind;
	Spinner _silence;
	Spinner _faceUp;
	Spinner _antiMagic;
	Mentality[int] _mtlyTbl;
	Combo _mtly;
	Spinner _mtlyRound;

	Race selectedRace() {
		if (_race) {
			int index = _race.getSelectionIndex;
			if (index > 0) {
				return findSkin(_prop, _summ).races[index - 1];
			}
		}
		return null;
	}
	void raceToolTip() {
		if (_race) {
			auto race = selectedRace;
			_race.setToolTipText = race ? race.desc : "";
		}
	}
	class SelectRace : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			raceToolTip;
		}
	}
	class BasicResist : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto race = selectedRace;
			if (race) {
				_automaton.setSelection = race.automaton;
				_constructure.setSelection = race.constructure;
				_undead.setSelection = race.undead;
				_unholy.setSelection = race.unholy;
				_resW.setSelection = race.weaponResist;
				_resM.setSelection = race.magicResist;
				foreach (el; _res.keys) {
					_res[el].setSelection = race.resist(el);
					_weak[el].setSelection = race.weakness(el);
				}
			}
		}
	}
	class BasicEnhance : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto race = selectedRace;
			if (race) {
				foreach (enh, i; _enhTbl) {
					_enh.setValue(i, race.defaultEnhance(enh));
				}
			}
		}
	}
	Coupon[] coupons() {
		Coupon[] r;
		r.length = _coupons.getItemCount;
		foreach (i, itm; _coupons.getItems) {
			r[i] = cast(Coupon) itm.getData;
		}
		return r;
	}
	Image couponImage(int value) {
		return value > 1 ? _prop.images.couponHigh
			: (value > 0 ? _prop.images.couponPlus
			: (value < 0 ? _prop.images.couponMinus : _prop.images.couponNormal));
	}
	void appendCoupon(Coupon coupon, int index = -1) {
		TableItem itm;
		if (index >= 0) {
			itm = new TableItem(_coupons, DWT.NONE, index);
		} else {
			itm = new TableItem(_coupons, DWT.NONE);
		}
		itm.setImage(0, couponImage(coupon.value));
		itm.setText(0, coupon.name);
		itm.setText(1, to!(string)(coupon.value));
		itm.setData = coupon;
	}
	void addCoupon() {
		if (_newCoupon.getText.length > 0) {
			foreach (i, itm; _coupons.getItems) {
				if (_newCoupon.getText == (cast(Coupon) itm.getData).name) {
					_coupons.select(i);
					return;
				}
			}
			appendCoupon(new Coupon(_newCoupon.getText, _couponVal.getSelection));
		}
	}
	void altCoupon() {
		int index = _coupons.getSelectionIndex;
		if (_newCoupon.getText.length > 0 && index >= 0) {
			foreach (i, itm; _coupons.getItems) {
				if (_newCoupon.getText == (cast(Coupon) itm.getData).name && i != index) {
					_coupons.select(i);
					return;
				}
			}
			auto itm = _coupons.getItem(index);
			auto coupon = new Coupon(_newCoupon.getText, _couponVal.getSelection);
			itm.setImage(0, couponImage(coupon.value));
			itm.setText(0, coupon.name);
			itm.setText(1, to!(string)(coupon.value));
			itm.setData = coupon;
		}
	}
	void delCoupon() {
		int i = _coupons.getSelectionIndex;
		if (i >= 0) {
			_coupons.remove(i);
		}
	}
	void swap(int index1, int index2) {
		auto itm1 = _coupons.getItem(index1);
		auto itm2 = _coupons.getItem(index2);
		auto img = itm1.getImage;
		auto text1 = itm1.getText(0);
		auto text2 = itm1.getText(1);
		auto data = itm1.getData;
		itm1.setImage = itm2.getImage;
		itm1.setText(0, itm2.getText(0));
		itm1.setText(1, itm2.getText(1));
		itm1.setData = itm2.getData;
		itm2.setImage = img;
		itm2.setText(0, text1);
		itm2.setText(1, text2);
		itm2.setData = data;
	}
	void upCoupon() {
		int index = _coupons.getSelectionIndex;
		if (index > 0) {
			swap(index, index - 1);
			_coupons.select(index - 1);
		}
	}
	void downCoupon() {
		int index = _coupons.getSelectionIndex;
		if (index >= 0 && index + 1 < _coupons.getItemCount) {
			swap(index, index + 1);
			_coupons.select(index + 1);
		}
	}

	class CDropListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = DND.DROP_MOVE;
		}
		override void dragOver(DropTargetEvent e){
			e.detail = DND.DROP_MOVE;
		}
		override void drop(DropTargetEvent e){
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try {
				auto node = XNode.parse(xml);
				if (node.name != Coupon.XML_NAME) return;
				scope p = (cast(DropTarget) e.getSource).getControl.toControl(e.x, e.y);
				auto t = _coupons.getItem(p);
				int index = t ? _coupons.indexOf(t) : _coupons.getItemCount;
				appendCoupon(Coupon.fromNode(node, LATEST_VERSION), index);
				if (_id == node.attr("paneId", false)) {
					_coupons.select(index);
					e.detail = DND.DROP_MOVE;
				}
			} catch {}
		}
	}
	class CDragListener : DragSourceAdapter {
		private TableItem _itm;
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource).getControl.isFocusControl;
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance.isSupportedType(e.dataType)) {
				auto c = cast(Table) (cast(DragSource) e.getSource).getControl;
				int index = c.getSelectionIndex;
				if (index >= 0) {
					auto cp = cast(Coupon) c.getItem(index).getData;
					auto node = cp.toNode;
					node.newAttr("paneId", _id);
					e.data = bytesFromXML(node.text);
					_itm = c.getItem(index);
				}
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				_itm.dispose;
				_coupons.redraw;
			}
		}
	}
	private class CouponTCPD : TCPD {
		private Coupon selection() {
			auto sels = _coupons.getSelection;
			return sels.length > 0 ? cast(Coupon) sels[0].getData : null;
		}
		override void cut() {
			auto c = selection;
			if (c) {
				copy;
				del;
			}
		}
		override void copy() {
			auto c = selection;
			if (c) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(_prop, cb, c.toNode.text);
			}
		}
		override void paste() {
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			auto xml = CBtoXML(cb);;
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					if (node.name == Coupon.XML_NAME) {
						appendCoupon(Coupon.fromNode(node, LATEST_VERSION));
					}
				} catch {}
			}
		}
		override void del() {
			delCoupon;
		}
		override bool canDoTCPD() {
			return _coupons.isFocusControl;
		}
	}

	void constructBase(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		auto skin = findSkin(_prop, _summ);
		{
			auto comp2 = new Composite(comp, DWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto gl = new GridLayout(1, false);
			gl.marginWidth = 0;
			gl.marginHeight = 0;
			comp2.setLayout = gl;
			{
				auto grp = new Group(comp2, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				grp.setLayout = new GridLayout(2, false);
				grp.setText = _prop.msgs.name;
				_name = new GBLimitText(_prop.looks.messageFont.name,
					_prop.looks.nameLimit, grp, DWT.BORDER);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _name.computeSize(DWT.DEFAULT, DWT.DEFAULT).x;
				_name.widget.setLayoutData = gd;
				auto l = new Label(grp, DWT.NONE);
				l.setText = _prop.msgs.nameLimit(_prop.looks.nameLimit);
				checker(_name.widget);
			}
			{
				_imgPath = new ImageSelect!(MtType.CARD)(comp2, DWT.NONE, _comm, _prop, _summ,
					_prop.looks.cardSize.width, _prop.looks.cardSize.height, _summ.legacy);
				_imgPath.widget.setLayoutData = new GridData(GridData.FILL_BOTH);
			}
		}
		{
			auto compr = new Composite(comp, DWT.NONE);
			compr.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			auto rgl = new GridLayout(1, false);
			rgl.marginWidth = 0;
			rgl.marginHeight = 0;
			compr.setLayout = rgl;
			{
				auto grp = new Group(compr, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new CenterLayout;
				grp.setText = _prop.msgs.level;
				auto comp2 = new Composite(grp, DWT.NONE);
				auto gl = new GridLayout(2, false);
				gl.marginWidth = 0;
				gl.marginHeight = 0;
				comp2.setLayout = gl;
				_level = new Spinner(comp2, DWT.BORDER);
				_level.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_level.setMinimum = 1;
				_level.setMaximum = _prop.looks.castLevelMax;
				auto hint = new Label(comp2, DWT.RIGHT);
				hint.setText = _prop.msgs.rangeHint(1, _prop.looks.castLevelMax);
			}
			{
				auto grp = new Group(compr, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new CenterLayout;
				grp.setText = _prop.msgs.life;
				auto comp2 = new Composite(grp, DWT.NONE);
				auto gl = new GridLayout(2, false);
				gl.marginWidth = 0;
				gl.marginHeight = 0;
				comp2.setLayout = gl;
				_lifeMax = new Spinner(comp2, DWT.BORDER);
				_lifeMax.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_lifeMax.setMinimum = 1;
				_lifeMax.setMaximum = _prop.looks.lifeMax;
				_lifeMax.addModifyListener(new LifeMaxL);
				auto hint = new Label(comp2, DWT.RIGHT);
				hint.setText = _prop.msgs.rangeHint(1, _prop.looks.lifeMax);
				auto lifec = new Button(comp2, DWT.PUSH);
				auto lgd = new GridData(GridData.FILL_HORIZONTAL);
				lgd.horizontalSpan = 2;
				lifec.setLayoutData = lgd;
				lifec.setText = _prop.msgs.lifeCalc;
				lifec.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						_lifeMax.setSelection = _prop.looks.lifeCalc(_level.getSelection,
							_phy.getValue(_phyTbl[Physical.VIT]),
							_phy.getValue(_phyTbl[Physical.MIN]));
					}
				});
			}
			if (!_summ.legacy) {
				auto grp = new Group(compr, DWT.NONE);
				grp.setText = _prop.msgs.race;
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				auto cl = new CenterLayout;
				cl.fillHorizontal = true;
				grp.setLayout = cl;
				_race = new Combo(grp, DWT.BORDER | DWT.DROP_DOWN | DWT.READ_ONLY);
				_race.setVisibleItemCount = 20;
				_race.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_race.add(_prop.msgs.noRace);
				foreach (race; skin.races) {
					_race.add(race.name);
				}
				_race.addSelectionListener(new SelectRace);
			}
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.card;
		tab.setControl = comp;
	}
	void setMaxLife() {
		_life.setMaximum = _lifeMax.getSelection;
		if (_lifeUseMax.getSelection) {
			_life.setSelection = _lifeMax.getSelection;
		}
	}
	class LifeMaxL : ModifyListener {
		public override void modifyText(ModifyEvent e) {
			setMaxLife;
		}
	}
	void constructDesc(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		{
			auto grp = new Group(comp, DWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			grp.setLayoutData = gd;
			gd.horizontalSpan = 2;
			auto cl = new CenterLayout(DWT.HORIZONTAL);
			cl.fillVertical = true;
			grp.setLayout = cl;
			grp.setText = _prop.msgs.desc;
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont), _prop.looks.cardDescLen, grp, DWT.BORDER);
			auto p = _desc.computeTextBaseSize(1);
			p.y = DWT.DEFAULT;
			_desc.widget.setLayoutData = p;
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.desc;
		tab.setControl = comp;
	}
	void constructHistory(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setText = _prop.msgs.coupons;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(2, false);
			{
				auto toolbar = new ToolBar(grp, DWT.FLAT);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 2;
				toolbar.setLayoutData = gd;
				toolbar.addListener(DWT.Traverse, new class Listener {
					override void handleEvent(Event e) {e.doit = true;}
				});
				toolbar.addListener(DWT.KeyDown, new class Listener {
					override void handleEvent(Event e) {e.doit = true;}
				});
				createToolItem(toolbar, _prop.msgs.addCoupon, _prop.images.addCoupon, &addCoupon);
				createToolItem(toolbar, _prop.msgs.altCoupon, _prop.images.altCoupon, &altCoupon);
				createToolItem(toolbar, _prop.msgs.delCoupon, _prop.images.couponDelete, &delCoupon);
				new ToolItem(toolbar, DWT.SEPARATOR);
				createToolItem(toolbar, _prop.msgs.ttUp, _prop.images.menuUp, &upCoupon);
				createToolItem(toolbar, _prop.msgs.ttDown, _prop.images.menuDown, &downCoupon);
			}
			{
				_newCoupon = new Text(grp, DWT.BORDER);
				_newCoupon.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_couponVal = new Spinner(grp, DWT.BORDER);
				_couponVal.setMinimum = cast(int) _prop.looks.couponValueMax * -1;
				_couponVal.setMaximum = _prop.looks.couponValueMax;
			}
			{
				_coupons = new Table(grp, DWT.BORDER | DWT.SINGLE | DWT.FULL_SELECTION);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.horizontalSpan = 2;
				gd.widthHint = _prop.var.etc.couponWidth;
				_coupons.setLayoutData = gd;
				auto cc = new FullTableColumn(_coupons, DWT.NONE);
				auto cv = new TableColumn(_coupons, DWT.NONE);
				cv.setWidth = 40;
				saveColumnWidth!("prop.var.etc.couponValueColumn")(_prop, cv);
				auto menu = new Menu(_coupons);
				createMenuItem(menu, _prop.msgs.menuUp, _prop.images.menuUp, &upCoupon);
				createMenuItem(menu, _prop.msgs.menuDown, _prop.images.menuDown, &downCoupon);
				new MenuItem(menu, DWT.SEPARATOR);
				appendMenuTCPD(_prop, menu, new CouponTCPD);
				_coupons.setMenu = menu;
				usingPopupMenuAccelerator(_coupons);
			}
			_coupons.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) {
					auto sels = _coupons.getSelection;
					if (sels.length > 0) {
						auto c = cast(Coupon) sels[0].getData;
						_newCoupon.setText = c.name;
						_couponVal.setSelection = c.value;
					}
				}
			});
			auto drag = new DragSource(_coupons, DND.DROP_MOVE | DND.DROP_COPY);
			drag.setTransfer([XMLBytesTransfer.getInstance]);
			drag.addDragListener(new CDragListener);
			auto drop = new DropTarget(_coupons, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
			drop.setTransfer([XMLBytesTransfer.getInstance]);
			drop.addDropListener(new CDropListener);
		}
		{
			auto comp2 = new Composite(comp, DWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			auto cgl = new GridLayout(2, false);
			cgl.marginWidth = 0;
			cgl.marginHeight = 0;
			comp2.setLayout = cgl;
			Button createR(Composite parent, string name) {
				auto radio = new Button(parent, DWT.RADIO);
				radio.setLayoutData = new GridData(GridData.FILL_BOTH);
				radio.setText = name;
				return radio;
			}
			{
				auto comp3 = createButtonGroup(comp2, _prop.msgs.sex, 1, 1);
				foreach (s; SEX_ALL) {
					_sex[s] = createR(comp3, _prop.sys.sexName(s));
				}
				_sexU = createR(comp3, _prop.msgs.sexUnknown);
			}
			{
				auto comp3 = createButtonGroup(comp2, _prop.msgs.period, 2, 1);
				foreach (p; PERIOD_ALL) {
					_period[p] = createR(comp3, _prop.sys.periodName(p));
				}
				_periodU = createR(comp3, _prop.msgs.periodUnknown);
			}
			{
				auto comp3 = createButtonGroup(comp2, _prop.msgs.nature, 2, 2);
				foreach (n; NATURE_DEF) {
					_nature[n] = createR(comp3, _prop.sys.natureName(n));
				}
				_natureU = createR(comp3, _prop.msgs.natureUnknown);
			}
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.history;
		tab.setControl = comp;
	}
	class MSListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto radio = cast(Button) e.widget;
			if (radio.getSelection) {
				auto m = cast(Makings) (cast(Integer) radio.getData).intValue;
				auto r = reverseMakings(m);
				_makings[r].setSelection = false;
			}
		}
	};
	void constructMakings(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		{
			auto comp3 = createButtonGroup(comp, _prop.msgs.coupons, 4, 1, true);
			auto sl = new MSListener;
			foreach (m; MAKINGS_LEFT) {
				void createR(Makings m) {
					auto radio = new Button(comp3, DWT.CHECK);
					radio.setLayoutData = new GridData(GridData.FILL_BOTH);
					radio.setText = _prop.sys.makingsName(m);
					radio.setData = new Integer(m);
					radio.addSelectionListener(sl);
					_makings[m] = radio;
				}
				createR(m);
				createR(reverseMakings(m));
			}
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.makings;
		tab.setControl = comp;
	}
	Composite createButtonGroup(Composite parent, string name,
			int row, int horSpan = 1, bool min = false) {
		auto grp = new Group(parent, DWT.NONE);
		grp.setText = name;
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.horizontalSpan = horSpan;
		grp.setLayoutData = gd;
		auto cl = new CenterLayout(DWT.HORIZONTAL | DWT.VERTICAL, 0);
		cl.fillVertical = true;
		grp.setLayout = cl;
		auto comp3 = new Composite(grp, DWT.NONE);
		auto gl = new GridLayout(row, true);
		if (min) gl.verticalSpacing = 2;
		comp3.setLayout = gl;
		return comp3;
	}
	class ESListener : SelectionAdapter {
		private Button _targ;
		this(Button targ) {
			_targ = targ;
		}
		override void widgetSelected(SelectionEvent e) {
			auto radio = cast(Button) e.widget;
			if (radio.getSelection) {
				_targ.setSelection = false;
			}
		}
	};
	void constructResist(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		Button createC(Composite parent, string name, string desc) {
			auto comp = new Composite(parent, DWT.NONE);
			comp.setLayoutData = new GridData(GridData.FILL_BOTH);
			comp.setLayout = zeroGridLayout(2, false);
			auto c = new Button(comp, DWT.CHECK);
			auto cgd = new GridData(GridData.FILL_HORIZONTAL);
			cgd.horizontalSpan = 2;
			c.setLayoutData = cgd;
			c.setText = name;
			auto dummy = new Composite(comp, DWT.NONE);
			auto dgd = new GridData;
			dgd.widthHint = 20;
			dgd.heightHint = 0;
			dummy.setLayoutData = dgd;
			auto l = new Label(comp, DWT.NONE);
			l.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			l.setText = desc;
			return c;
		}
		{
			Composite tcomp, bcomp;
			{
				tcomp = createButtonGroup(comp, _prop.msgs.tolerantBase, 2, 1);
				auto gl = cast(GridLayout) tcomp.getLayout;
				gl.horizontalSpacing = 15;
				_resW = createC(tcomp, _prop.msgs.resistWeapon, _prop.msgs.descResistWeapon);
				_resM = createC(tcomp, _prop.msgs.resistMagic, _prop.msgs.descResistMagic);
			}
			{
				bcomp = createButtonGroup(comp, _prop.msgs.tolerantElement, 2, 1);
				auto gl = cast(GridLayout) bcomp.getLayout;
				gl.horizontalSpacing = 15;
				_undead = createC(bcomp, _prop.msgs.undead, _prop.msgs.descUndead);
				_automaton = createC(bcomp, _prop.msgs.automaton, _prop.msgs.descAutomaton);
				_unholy = createC(bcomp, _prop.msgs.unholy, _prop.msgs.descUnholy);
				_constructure = createC(bcomp, _prop.msgs.constructure, _prop.msgs.descConstructure);
				foreach (e; [Element.FIRE, Element.ICE]) {
					auto res = createC(bcomp, _prop.msgs.resist(e), _prop.msgs.descResist(e));
					auto weak = createC(bcomp, _prop.msgs.weakness(e), _prop.msgs.descWeakness(e));
					res.addSelectionListener(new ESListener(weak));
					weak.addSelectionListener(new ESListener(res));
					_res[e] = res;
					_weak[e] = weak;
				}
			}
			auto ts = tcomp.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			auto bs = bcomp.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			int maxW = ts.x > bs.x ? ts.x : bs.x;
			ts.x = maxW;
			bs.x = maxW;
			tcomp.setLayoutData = ts;
			bcomp.setLayoutData = bs;
		}
		{
			auto basic = new Button(comp, DWT.PUSH);
			basic.setText = _prop.msgs.basicResist;
			basic.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
			basic.addSelectionListener(new BasicResist);
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.tolerant;
		tab.setControl = comp;
	}
	void constructPhysical(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setText = _prop.msgs.physicalParams;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto cl = new CenterLayout;
			grp.setLayout = cl;
			_phy = new RadarSpinner(grp, DWT.NONE);
			static const Ps = [Physical.DEX, Physical.AGL, Physical.INT,
				Physical.STR, Physical.VIT, Physical.MIN];
			string[] names;
			names.length = Ps.length;
			foreach (i, p; Ps) {
				_phyTbl[p] = i;
				names[i] = _prop.msgs.physical(p);
			}
			_phy.setRadar(_prop.looks.physicalMax + 1, names, 0);
			_phy.setRadarSize(_prop.var.etc.physicalRadarWidth, _prop.var.etc.physicalRadarHeight);
			_phy.antialias = true;
			_phy.borderlines = cast(int[]) _prop.looks.physicalBorders;
			_phy.lineStep = _prop.looks.physicalMax / 5;
		}
		{
			auto basic = new Button(comp, DWT.PUSH);
			basic.setText = _prop.msgs.physicalCalc;
			basic.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
			basic.addSelectionListener(new CalcPhysical);
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.physicalParams;
		tab.setControl = comp;
	}
	real calcPhy(E)(Physical phy, Button[E] radios, bool all) {
		real r = 0.0;
		foreach (e, radio; radios) {
			if (radio.getSelection) {
				r += physicalMod(e, phy);
				if (!all) break;
			}
		}
		return r;
	}
	class CalcPhysical : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			real[Physical] p;
			int[Physical] min;
			int[Physical] max;
			auto race = selectedRace;
			foreach (phy; _phyTbl.keys) {
				int pmin = _prop.looks.physicalCutMin;
				int pmax;
				if (race) {
					int v = race.physical(phy);
					pmax = v + _prop.looks.physicalCutMaxBase;
					if (pmax > _prop.looks.physicalMax) pmax = _prop.looks.physicalMax;
					if (v < pmin) pmin = v;
					p[phy] = v;
				} else {
					int v = _prop.looks.physicalNormal;
					pmax = v + _prop.looks.physicalCutMaxBase;
					p[phy] = v;
				}
				min[phy] = pmin;
				max[phy] = pmax;
			}
			foreach (phy, ref val; p) {
				val += calcPhy!(Sex)(phy, _sex, false);
				val += calcPhy!(Period)(phy, _period, false);
				val += calcPhy!(Nature)(phy, _nature, false);
				val += calcPhy!(Makings)(phy, _makings, true);
			}
			int[] vals;
			vals.length = p.length;
			foreach (phy, val; p) {
				int v = cast(int) val;
				if (v < min[phy]) v = min[phy];
				if (v > max[phy]) v = max[phy];
				vals[_phyTbl[phy]] = v;
			}
			_phy.setValues(vals);
		}
	}
	void constructMental(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setText = _prop.msgs.mentalParams;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto ggl = new GridLayout(3, false);
			ggl.verticalSpacing = 0;
			grp.setLayout = ggl;
			static const Ms = [Mental.AGGRESSIVE, Mental.CHEERFUL, Mental.BRAVE,
				Mental.CAUTIOUS, Mental.TRICKISH];
			foreach (m; Ms) {
				auto minl = new Label(grp, DWT.NONE);
				minl.setText = _prop.msgs.mental(reverseMental(m));
				auto scale = new Scale(grp, DWT.NONE);
				scale.setLayoutData = new GridData(GridData.FILL_BOTH);
				scale.setMaximum = _prop.looks.mentalMax * 2;
				scale.setMinimum = 0;
				scale.setIncrement = 1;
				scale.setPageIncrement = _prop.looks.mentalMax;
				auto maxl = new Label(grp, DWT.NONE);
				maxl.setText = _prop.msgs.mental(m);
				_mtl[m] = scale;
			}
		}
		{
			auto basic = new Button(comp, DWT.PUSH);
			basic.setText = _prop.msgs.mentalCalc;
			basic.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
			basic.addSelectionListener(new CalcMental);
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.mentalParams;
		tab.setControl = comp;
	}
	real calcMtl(E)(Mental mtl, Button[E] radios, bool all) {
		real r = 0.0;
		foreach (e, radio; radios) {
			if (radio.getSelection) {
				r += mentalMod(e, mtl);
				if (!all) break;
			}
		}
		return r;
	}
	class CalcMental : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto race = selectedRace;
			foreach (mtl, scale; _mtl) {
				int min = cast(int) _prop.looks.mentalCut * -1;
				int max = _prop.looks.mentalCut;
				real val;
				if (race) {
					int ival = race.mental(mtl);
					val = ival;
					if (ival < min) min = ival;
					if (ival > max) max = ival;
				} else {
					val = 0.0;
				}
				val += calcMtl!(Sex)(mtl, _sex, false);
				val += calcMtl!(Period)(mtl, _period, false);
				val += calcMtl!(Nature)(mtl, _nature, false);
				val += calcMtl!(Makings)(mtl, _makings, true);
				int v = cast(int) val;
				if (v < min) v = min;
				if (v > max) v = max;
				scale.setSelection = v + _prop.looks.mentalMax;
			}
		}
	}
	void constructEnhance(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setText = _prop.msgs.castEnhance;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new CenterLayout;
			_enh = new RadarSpinner(grp, DWT.NONE);
			static const Es = [Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE];
			string[] names;
			names.length = Es.length;
			foreach (i, enh; Es) {
				_enhTbl[enh] = i;
				names[i] = _prop.msgs.enhanceBonus(enh);
			}
			_enh.setRadar(_prop.looks.enhanceMax * 2 + 1,
				names, cast(int) _prop.looks.enhanceMax * -1);
			_enh.setRadarSize(_prop.var.etc.enhanceRadarWidth, _prop.var.etc.enhanceRadarHeight);
			_enh.antialias = true;
			_enh.borderlines = [0];
			_enh.lineStep = _prop.looks.enhanceMax / 2;
		}
		{
			auto basic = new Button(comp, DWT.PUSH);
			basic.setText = _prop.msgs.basicEnhance;
			basic.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
			basic.addSelectionListener(new BasicEnhance);
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.castEnhance;
		tab.setControl = comp;
	}
	void constructStatus(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		Label[] lbls1, lbls2;
		Composite[] spns;
		Spinner createSpn(Composite comp) {
			// なぜかCompositeを挟まなければSpinner#computeSize()が大きめの値を返す
			Composite comp2 = new Composite(comp, DWT.NONE);
			comp2.setLayout = new FillLayout;
			auto spn = new Spinner(comp2, DWT.BORDER);
			spns ~= comp2;
			return spn;
		}
		Composite createGrp(string text) {
			auto grp = new Group(comp, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto gl = new GridLayout(2, false);
			gl.horizontalSpacing = 15;
			grp.setLayout = gl;
			grp.setText = text;
			return grp;
		}
		Composite createComp(Composite grp) {
			auto comp2 = new Composite(grp, DWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto rl = new RowLayout(DWT.HORIZONTAL);
			rl.center = true;
			rl.marginLeft = 0;
			rl.marginRight = 0;
			rl.marginTop = 0;
			rl.marginBottom = 0;
			comp2.setLayout = rl;
			return comp2;
		}
		{
			auto grp = createGrp(_prop.msgs.lifeAndMentality);
			{
				auto comp2 = createComp(grp);
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.life;
				lbls1 ~= l;
				_life = new Spinner(comp2, DWT.BORDER);
				_lifeUseMax = new Button(comp2, DWT.CHECK);
				_lifeUseMax.setText = _prop.msgs.useMax;
				_lifeUseMax.addSelectionListener(new LifeUseMax);
			}
			{
				auto comp2 = createComp(grp);
				auto lm = new Label(comp2, DWT.NONE);
				lm.setText = _prop.msgs.mentality;
				lbls1 ~= lm;
				_mtly = new Combo(comp2, DWT.BORDER | DWT.DROP_DOWN | DWT.READ_ONLY);
				_mtly.setVisibleItemCount = 20;
				foreach (i, mtly; [Mentality.NORMAL, Mentality.SLEEP, Mentality.CONFUSE,
						Mentality.OVERHEAT, Mentality.BRAVE, Mentality.PANIC]) {
					_mtly.add(_prop.msgs.mentality(mtly));
					_mtlyTbl[i] = mtly;
					if (_card && _card.mentality is mtly) {
						_mtly.select = i;
					}
				}
				if (_mtly.getSelectionIndex < 0) _mtly.select = 0;
				_mtly.addSelectionListener(new SelMentality);
				_mtlyRound = createSpn(comp2);
				_mtlyRound.setMaximum = _prop.looks.roundMax;
				_mtlyRound.setMinimum = 1;
				spns ~= _mtlyRound;
				auto lm2  = new Label(comp2, DWT.NONE);
				lm2.setText = _prop.msgs.unitRound;
			}
		}
		{
			auto grp = createGrp(_prop.msgs.enhanceLiveBonus);
			foreach (enh; [Enhance.ACTION, Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE]) {
				auto comp2 = createComp(grp);
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.enhanceLiveBonus(enh);
				lbls1 ~= l;
				auto spn = createSpn(comp2);
				spn.setMaximum = _prop.looks.enhanceMax;
				spn.setMinimum = -(cast(int) _prop.looks.enhanceMax);
				spns ~= spn;
				_liveEnh[enh] = spn;
				auto rnd = createSpn(comp2);
				rnd.setMaximum = _prop.looks.roundMax;
				rnd.setMinimum = 1;
				spns ~= rnd;
				_enhRound[enh] = rnd;
				auto l2  = new Label(comp2, DWT.NONE);
				l2.setText = _prop.msgs.unitRound;
				spn.addSelectionListener(new LiveEnh);
			}
		}
		Spinner createStSpn(Composite grp, string name, uint max, string val) {
			auto comp2 = createComp(grp);
			auto l = new Label(comp2, DWT.NONE);
			l.setText = name;
			lbls1 ~= l;
			auto spn = createSpn(comp2);
			spn.setMaximum = max;
			spn.setMinimum = 0;
			spns ~= spn;
			auto l2  = new Label(comp2, DWT.NONE);
			l2.setText = val;
			lbls2 ~= l2;
			return spn;
		}
		{
			auto grp = createGrp(_prop.msgs.status);
			_paralyze = createStSpn(grp, _prop.msgs.paralyze, _prop.looks.paralyzeMax, _prop.msgs.unitValue);
			_poison = createStSpn(grp, _prop.msgs.poison, _prop.looks.poisonMax, _prop.msgs.unitValue);
			_bind = createStSpn(grp, _prop.msgs.bind, _prop.looks.roundMax, _prop.msgs.unitRound);
			_silence = createStSpn(grp, _prop.msgs.silence, _prop.looks.roundMax, _prop.msgs.unitRound);
			_faceUp = createStSpn(grp, _prop.msgs.faceUp, _prop.looks.roundMax, _prop.msgs.unitRound);
			_antiMagic = createStSpn(grp, _prop.msgs.antiMagic, _prop.looks.roundMax, _prop.msgs.unitRound);
		}
		void setlblw(Control[] lbls) {
			int maxW = 0;
			foreach (lbl; lbls) {
				int w = lbl.computeSize(DWT.DEFAULT, DWT.DEFAULT).x;
				if (maxW < w) maxW = w;
			}
			foreach (lbl; lbls) {
				auto gd = new RowData(maxW, DWT.DEFAULT);
				lbl.setLayoutData = gd;
			}
		}
		setlblw(cast(Control[]) lbls1);
		setlblw(cast(Control[]) lbls2);
		setlblw(cast(Control[]) spns);
		{
			auto reset = new Button(comp, DWT.PUSH);
			reset.setText = _prop.msgs.resetLiveStatus;
			reset.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
			reset.addSelectionListener(new ResetLiveStatus);
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.liveStatus;
		tab.setControl = comp;
	}
	class LiveEnh : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			changeLiveEnhance;
		}
	}
	class SelMentality : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			changeMentality;
		}
	}
	class LifeUseMax : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			changeLifeUseMax;
		}
	}
	class ResetLiveStatus : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			resetLiveStatus;
		}
	}
	void changeLiveEnhance() {
		foreach (enh, spn; _liveEnh) {
			_enhRound[enh].setEnabled = spn.getSelection != 0;
		}
	}
	void changeMentality() {
		_mtlyRound.setEnabled = _mtly.getSelectionIndex != 0;
	}
	void changeLifeUseMax() {
		_life.setEnabled = !_lifeUseMax.getSelection;
	}
	void resetLiveStatus() {
		_life.setSelection = _lifeMax.getSelection;
		_lifeUseMax.setSelection = true;
		foreach (enh, spn; _liveEnh) {
			spn.setSelection = 0;
		}
		foreach (enh, spn; _enhRound) {
			spn.setSelection = 0;
		}
		_paralyze.setSelection = 0;
		_poison.setSelection = 0;
		_bind.setSelection = 0;
		_silence.setSelection = 0;
		_faceUp.setSelection = 0;
		_antiMagic.setSelection = 0;
		_mtly.select = 0;
		_mtlyRound.setSelection = 0;
		changeLiveEnhance;
		changeMentality;
		changeLifeUseMax;
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, CastCard card) {
		assert (summ !is null);
		_id = format("%08X", &this) ~ "-" ~ to!(string)(getUTCtime);
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		super(prop, shell, _card ? _prop.msgs.dlgTitCast(_card.name) : _prop.msgs.dlgTitNewCast,
			_prop.images.casts, true, _prop.var.castCardDlg);
	}

	CastCard card() {
		return _card;
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout(DWT.NONE, 0);
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout = cl;
		auto tabf = new CTabFolder(area, DWT.BORDER);
		constructBase(tabf);
		constructDesc(tabf);
		constructHistory(tabf);
		constructMakings(tabf);
		constructResist(tabf);
		constructPhysical(tabf);
		constructMental(tabf);
		constructEnhance(tabf);
		constructStatus(tabf);

		// Windows Vistaだとタブの横幅が凄いことになったので必要最低限にする。
		scope maxSize = new Point(0, 0);
		foreach (tab; tabf.getItems) {
			scope size = tab.getControl.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			if (maxSize.x < size.x) maxSize.x = size.x;
			if (maxSize.y < size.y) maxSize.y = size.y;
		}
		scope rect = tabf.computeTrim(DWT.DEFAULT, DWT.DEFAULT, maxSize.x, maxSize.y);
		tabf.setLayoutData = new Point(rect.width, rect.height);

		if (_card) {
			_imgPath.image = _card.path;
			if (_race) _race.select = 0;
			_desc.setText = _card.desc;
			_name.setText = _card.name;
			_level.setSelection = _card.level;
			_lifeMax.setSelection = _card.lifeMax;
			bool sex = false, period = false, nature = false;
			scope makings = new HashSet!(Makings);
			cp: foreach (c; _card.coupons) {
				foreach (s; SEX_ALL) {
					if (c.name == _prop.sys.sexCoupon(s)) {
						if (!sex) _sex[s].setSelection = true;
						sex = true;
						continue cp;
					}
				}
				foreach (per; PERIOD_ALL) {
					if (c.name == _prop.sys.periodCoupon(per)) {
						if (!period) _period[per].setSelection = true;
						period = true;
						continue cp;
					}
				}
				foreach (nat; NATURE_DEF) {
					if (c.name == _prop.sys.natureCoupon(nat)) {
						if (!nature) _nature[nat].setSelection = true;
						nature = true;
						continue cp;
					}
				}
				foreach (m; MAKINGS_LEFT) {
					if (c.name == _prop.sys.makingsCoupon(m)) {
						if (!makings.contains(m)) _makings[m].setSelection = true;
						makings.add(m);
						continue cp;
					}
					auto r = reverseMakings(m);
					if (c.name == _prop.sys.makingsCoupon(r)) {
						if (!makings.contains(m)) _makings[r].setSelection = true;
						makings.add(m);
						continue cp;
					}
				}
				if (_race) {
					foreach (i, r; findSkin(_prop, _summ).races) {
						if (c.name == _prop.msgs.raceCoupon(r)) {
							_race.select = i + 1;
							raceToolTip;
							continue cp;
						}
					}
				}
				appendCoupon(c);
			}
			if (!sex) _sexU.setSelection = true;
			if (!period) _periodU.setSelection = true;
			if (!nature) _natureU.setSelection = true;
			_resW.setSelection = _card.weaponResist;
			_resM.setSelection = _card.magicResist;
			_undead.setSelection = _card.undead;
			_automaton.setSelection = _card.automaton;
			_unholy.setSelection = _card.unholy;
			_constructure.setSelection = _card.constructure;
			foreach (e, radio; _res) {
				radio.setSelection = _card.resist(e);
			}
			foreach (e, radio; _weak) {
				radio.setSelection = _card.weakness(e);
			}
			foreach (phy, i; _phyTbl) {
				_phy.setValue(i, _card.physical(phy));
			}
			foreach (mtl, scale; _mtl) {
				scale.setSelection = _prop.looks.mentalMax + _card.mental(mtl);
			}
			foreach (enh, i; _enhTbl) {
				_enh.setValue(i, _card.defaultEnhance(enh));
			}

			_life.setSelection = _card.life;
			_lifeUseMax.setSelection = _card.life == _card.lifeMax;
			foreach (enh, spn; _liveEnh) {
				spn.setSelection = _card.enhance(enh);
			}
			foreach (enh, spn; _enhRound) {
				spn.setSelection = _card.enhanceRound(enh);
			}
			_paralyze.setSelection = _card.paralyze;
			_poison.setSelection = _card.poison;
			_bind.setSelection = _card.bindRound;
			_silence.setSelection = _card.silenceRound;
			_faceUp.setSelection = _card.faceUpRound;
			_antiMagic.setSelection = _card.antiMagicRound;
			_mtlyRound.setSelection = _card.mentalityRound;
			changeLiveEnhance;
			changeMentality;
			changeLifeUseMax;
		} else {
			_imgPath.image = "";
			if (_race) _race.select = 0;
			_sexU.setSelection = true;
			_periodU.setSelection = true;
			_natureU.setSelection = true;
			int[] phys;
			phys.length = _phy.paramCount;
			phys[] = _prop.looks.physicalNormal;
			_phy.setValues(phys);
			foreach (radio; _mtl) {
				radio.setSelection = _prop.looks.mentalMax;
			}
			int[] bonus;
			bonus.length = _enh.paramCount;
			bonus[] = 0;
			_enh.setValues(bonus);

			resetLiveStatus;
		}
		setMaxLife;
	}

	private Coupon createCoupon(E)(Button[E] radios, string delegate(E) coupon) {
		foreach (e, radio; radios) {
			if (radio.getSelection) {
				return new Coupon(coupon(e), 0);
			}
		}
		return null;
	}
	override bool close(bool ok) {
		if (ok) {
			if (_card) {
				_card.path = _imgPath.image;
				_card.desc = _desc.getRRText;
				_card.name = _name.getText;
				_card.level = _level.getSelection;
				_card.lifeMax = _lifeMax.getSelection;
				_card.life = _lifeMax.getSelection;
			} else {
				_card = new CastCard(_summ.newId!(CastCard), _name.getText, _imgPath.image,
					_desc.getRRText, _level.getSelection, _lifeMax.getSelection);
			}
			Coupon[] cs;
			auto sex = createCoupon!(Sex)(_sex, &_prop.sys.sexCoupon);
			if (sex) cs ~= sex;
			auto race = selectedRace;
			if (race) {
				cs ~= new Coupon(_prop.msgs.raceCoupon(race), 0);
			}
			auto period = createCoupon!(Period)(_period, &_prop.sys.periodCoupon);
			if (period) cs ~= period;
			auto nature = createCoupon!(Nature)(_nature, &_prop.sys.natureCoupon);
			if (nature) cs ~= nature;
			foreach (m, radio; _makings) {
				if (radio.getSelection) {
					cs ~= new Coupon(_prop.sys.makingsCoupon(m), 0);
				}
			}
			cs ~= coupons;
			_card.coupons = cs;
			_card.weaponResist = _resW.getSelection;
			_card.magicResist = _resM.getSelection;
			_card.undead = _undead.getSelection;
			_card.automaton = _automaton.getSelection;
			_card.unholy = _unholy.getSelection;
			_card.constructure = _constructure.getSelection;
			foreach (e, radio; _res) {
				_card.resist(e, radio.getSelection);
			}
			foreach (e, radio; _weak) {
				_card.weakness(e, radio.getSelection);
			}
			foreach (phy, i; _phyTbl) {
				_card.physical(phy, _phy.getValue(i));
			}
			foreach (mtl, scale; _mtl) {
				_card.mental(mtl, cast(int) scale.getSelection - _prop.looks.mentalMax);
			}
			foreach (enh, i; _enhTbl) {
				_card.defaultEnhance(enh, _enh.getValue(i));
			}

			_card.life = _lifeUseMax.getSelection ? _card.lifeMax : _life.getSelection;
			foreach (enh, spn; _liveEnh) {
				if (_enhRound[enh].getSelection > 0) {
					_card.enhance(enh, spn.getSelection);
				} else {
					_card.enhance(enh, 0);
				}
			}
			foreach (enh, spn; _enhRound) {
				if (_card.enhance(enh) != 0) {
					_card.enhanceRound(enh, spn.getSelection);
				}
			}
			_card.paralyze = _paralyze.getSelection;
			_card.poison = _poison.getSelection;
			_card.bindRound = _bind.getSelection;
			_card.silenceRound = _silence.getSelection;
			_card.faceUpRound = _faceUp.getSelection;
			_card.antiMagicRound = _antiMagic.getSelection;
			_card.mentality = _mtlyRound.getSelection == 0
				? Mentality.NORMAL : _mtlyTbl[_mtly.getSelectionIndex];
			_card.mentalityRound = _card.mentality == Mentality.NORMAL
				? 0 : _mtlyRound.getSelection;
		}
		return ok;
	}
}


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
import cwx.motion;
import cwx.path;
import cwx.menu;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.radarspinner;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;

import std.datetime;
import std.string;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Scale;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.layout.RowData;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import java.lang.all;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.dnd.ByteArrayTransfer;

public:

/// キャストカードの設定を行うダイアログ。
class CastCardDialog : AbsDialog {
private:
	string _id;

	Commons _comm;
	Props _prop;
	Summary _summ;
	CastCard _card;
	KeyDownFilter _kdFilter;

	UndoManager _undoCoupons;

	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	GBLimitText _name;
	Spinner _level;
	Spinner _lifeMax;
	Text _newCoupon;
	TextMenuModify _newCouponTM;
	Spinner _couponVal;
	Composite _couponView;
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

	void refreshWarning() {
		string[] ws;
		if (_name.over) {
			ws ~= _prop.msgs.warningNameLenOver(_prop.looks.castNameLimit);
		}
		warning = ws;
	}

	@property
	Race selectedRace() {
		if (_race) {
			int index = _race.getSelectionIndex();
			if (index > 0) {
				return _comm.skin.races[index - 1];
			}
		}
		return null;
	}
	void raceToolTip() {
		if (_race) {
			auto race = selectedRace;
			_race.setToolTipText(race ? race.desc : "");
		}
	}
	class SelectRace : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			raceToolTip();
		}
	}
	class BasicResist : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto race = selectedRace;
			if (race) {
				_automaton.setSelection(race.automaton);
				_constructure.setSelection(race.constructure);
				_undead.setSelection(race.undead);
				_unholy.setSelection(race.unholy);
				_resW.setSelection(race.weaponResist);
				_resM.setSelection(race.magicResist);
				foreach (el; _res.keys) {
					_res[el].setSelection(race.resist(el));
					_weak[el].setSelection(race.weakness(el));
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
	class UndoCoupons : Undo {
		private Coupon[] _coupons;
		private int _selected;
		this () {
			save();
		}
		private void save() {
			_coupons = this.outer.coupons;
			_selected = this.outer._coupons.getSelectionIndex();
		}
		private void impl() {
			auto coupons = _coupons;
			auto selected = _selected;
			save();
			this.outer._coupons.setRedraw(false);
			scope (exit) this.outer._coupons.setRedraw(true);
			this.outer._coupons.removeAll();
			foreach (c; coupons) {
				appendCoupon(c);
			}
			this.outer._coupons.select(selected);
			this.outer._coupons.showSelection();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {
			// Nothing
		}
	}
	void storeCoupons() {
		_undoCoupons ~= new UndoCoupons;
	}
	void undoCoupons() {
		_undoCoupons.undo();
	}
	void redoCoupons() {
		_undoCoupons.redo();
	}
	@property
	Coupon[] coupons() {
		Coupon[] r;
		r.length = _coupons.getItemCount();
		foreach (i, itm; _coupons.getItems()) {
			r[i] = cast(Coupon) itm.getData();
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
			itm = new TableItem(_coupons, SWT.NONE, index);
		} else {
			itm = new TableItem(_coupons, SWT.NONE);
		}
		itm.setImage(0, couponImage(coupon.value));
		itm.setText(0, coupon.name);
		itm.setText(1, to!(string)(coupon.value));
		itm.setData(coupon);
		_coupons.setSelection([itm]);
		_coupons.showSelection();
	}
	void addCoupon() {
		if (_newCoupon.getText().length > 0) {
			foreach (i, itm; _coupons.getItems()) {
				if (_newCoupon.getText() == (cast(Coupon) itm.getData()).name) {
					_coupons.select(i);
					return;
				}
			}
			storeCoupons();
			appendCoupon(new Coupon(_newCoupon.getText(), _couponVal.getSelection()), _coupons.getSelectionIndex());
			applyEnabled();
		}
	}
	void altCoupon() {
		int index = _coupons.getSelectionIndex();
		if (_newCoupon.getText().length > 0 && index >= 0) {
			foreach (i, itm; _coupons.getItems()) {
				if (_newCoupon.getText() == (cast(Coupon) itm.getData()).name && i != index) {
					_coupons.select(i);
					return;
				}
			}
			storeCoupons();
			auto itm = _coupons.getItem(index);
			auto coupon = new Coupon(_newCoupon.getText(), _couponVal.getSelection());
			itm.setImage(0, couponImage(coupon.value));
			itm.setText(0, coupon.name);
			itm.setText(1, to!(string)(coupon.value));
			itm.setData(coupon);
			applyEnabled();
		}
	}
	void delCoupon() {
		int i = _coupons.getSelectionIndex();
		if (i >= 0) {
			storeCoupons();
			_coupons.remove(i);
			if (i >= _coupons.getItemCount()) i--;
			if (i >= 0) {
				_coupons.select(i);
				selCoupon();
			}
			applyEnabled();
		}
	}
	void selCoupon() {
		auto i = _coupons.getSelectionIndex();
		if (-1 != i) {
			auto c = cast(Coupon) _coupons.getItem(i).getData();
			_newCoupon.setText(c.name);
			_newCouponTM.reset();
			_couponVal.setSelection(c.value);
		}
	}
	void swapCoupon(int index1, int index2) {
		auto itm1 = _coupons.getItem(index1);
		auto itm2 = _coupons.getItem(index2);
		auto img = itm1.getImage();
		auto text1 = itm1.getText(0);
		auto text2 = itm1.getText(1);
		auto data = itm1.getData();
		itm1.setImage(itm2.getImage());
		itm1.setText(0, itm2.getText(0));
		itm1.setText(1, itm2.getText(1));
		itm1.setData(itm2.getData());
		itm2.setImage(img);
		itm2.setText(0, text1);
		itm2.setText(1, text2);
		itm2.setData(data);
		applyEnabled();
	}
	void upCoupon() {
		int index = _coupons.getSelectionIndex();
		if (index > 0) {
			storeCoupons();
			swapCoupon(index, index - 1);
			_coupons.select(index - 1);
		}
	}
	void downCoupon() {
		int index = _coupons.getSelectionIndex();
		if (index >= 0 && index + 1 < _coupons.getItemCount()) {
			storeCoupons();
			swapCoupon(index, index + 1);
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
				scope p = (cast(DropTarget) e.getSource()).getControl().toControl(e.x, e.y);
				storeCoupons();
				auto t = _coupons.getItem(p);
				int index = t ? _coupons.indexOf(t) : _coupons.getItemCount();
				appendCoupon(Coupon.fromNode(node, LATEST_VERSION), index);
				if (_id == node.attr("paneId", false)) {
					_coupons.select(index);
					e.detail = DND.DROP_MOVE;
				}
				applyEnabled();
			} catch {}
		}
	}
	class CDragListener : DragSourceAdapter {
		private TableItem _itm;
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
				auto c = cast(Table) (cast(DragSource) e.getSource()).getControl();
				int index = c.getSelectionIndex();
				if (index >= 0) {
					auto cp = cast(Coupon) c.getItem(index).getData();
					auto node = cp.toNode();
					node.newAttr("paneId", _id);
					e.data = bytesFromXML(node.text);
					_itm = c.getItem(index);
				}
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				_itm.dispose();
				_coupons.redraw();
			}
		}
	}
	private class CouponTCPD : TCPD {
		@property
		private Coupon selection() {
			auto i = _coupons.getSelectionIndex();
			return -1 != i ? cast(Coupon) _coupons.getItem(i).getData() : null;
		}
		override void cut(SelectionEvent se) {
			auto c = selection;
			if (c) {
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) {
			auto c = selection;
			if (c) {
				XMLtoCB(_prop, _comm.clipboard, c.toNode().text);
			}
		}
		override void paste(SelectionEvent se) {
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					if (node.name == Coupon.XML_NAME) {
						storeCoupons();
						appendCoupon(Coupon.fromNode(node, LATEST_VERSION), _coupons.getSelectionIndex());
					}
					applyEnabled();
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		override void del(SelectionEvent se) {
			delCoupon();
		}
		@property
		override bool canDoTCPD() {
			return _coupons.isFocusControl();
		}
		@property
		bool canDoT() {
			return _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() {
			return _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoP() {
			return true;
		}
		@property
		bool canDoD() {
			return _coupons.getSelectionIndex() != -1;
		}
	}

	class SelLifeC : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			_lifeMax.setSelection(_prop.looks.lifeCalc(_level.getSelection(),
				_phy.getValue(_phyTbl[Physical.VIT]),
				_phy.getValue(_phyTbl[Physical.MIN])));
		}
	}

	void constructBase(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		auto skin = _comm.skin;
		{
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp2.setLayout(zeroMarginGridLayout(1, false));
			{
				auto grp = new Group(comp2, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(new GridLayout(2, false));
				grp.setText(_prop.msgs.name);
				_name = new GBLimitText(_prop.looks.monospace,
					_prop.looks.castNameLimit, false, grp, SWT.BORDER);
				_name.limitEvent ~= &refreshWarning;
				mod(_name.widget);
				createTextMenu!Text(_comm, _prop, _name.widget, &catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _name.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
				_name.widget.setLayoutData(gd);
				auto l = new Label(grp, SWT.NONE);
				l.setText(_prop.msgs.nameLimit(_prop.looks.castNameLimit));
			}
			{
				bool including = _card && isBinImg(_card.path);
				string saveName = including ? _card.name : "";
				_imgPath = new ImageSelect!(MtType.CARD)(comp2, SWT.NONE, _comm, _prop, _summ,
					_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, saveName);
				_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
				mod(_imgPath);
			}
		}
		{
			auto compr = new Composite(comp, SWT.NONE);
			compr.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			compr.setLayout(zeroMarginGridLayout(1, false));
			{
				auto grp = new Group(compr, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.level);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(2, false));
				_level = new Spinner(comp2, SWT.BORDER);
				mod(_level);
				_level.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_level.setMinimum(1);
				_level.setMaximum(_prop.looks.castLevelMax);
				auto hint = new Label(comp2, SWT.RIGHT);
				hint.setText(_prop.msgs.rangeHint(1, _prop.looks.castLevelMax));
			}
			{
				auto grp = new Group(compr, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.life);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(2, false));
				_lifeMax = new Spinner(comp2, SWT.BORDER);
				mod(_lifeMax);
				_lifeMax.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_lifeMax.setMinimum(1);
				_lifeMax.setMaximum(_prop.looks.lifeMax);
				_lifeMax.addModifyListener(new LifeMaxL);
				auto hint = new Label(comp2, SWT.RIGHT);
				hint.setText(_prop.msgs.rangeHint(1, _prop.looks.lifeMax));
				auto lifec = new Button(comp2, SWT.PUSH);
				mod(lifec);
				auto lgd = new GridData(GridData.FILL_HORIZONTAL);
				lgd.horizontalSpan = 2;
				lifec.setLayoutData(lgd);
				lifec.setText(_prop.msgs.lifeCalc);
				lifec.addSelectionListener(new SelLifeC);
			}
			auto grp = new Group(compr, SWT.NONE);
			grp.setText(_prop.msgs.race);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			grp.setLayout(cl);
			_race = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			mod(_race);
			_race.setVisibleItemCount(20);
			_race.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_race.add(_prop.msgs.noRace);
			foreach (race; skin.races) {
				_race.add(race.name);
			}
			_race.addSelectionListener(new SelectRace);
			refreshRace();
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.card);
		tab.setControl(comp);
	}
	void setMaxLife() {
		_life.setMaximum(_lifeMax.getSelection());
		if (_lifeUseMax.getSelection()) {
			_life.setSelection(_lifeMax.getSelection());
		}
	}
	class LifeMaxL : ModifyListener {
		public override void modifyText(ModifyEvent e) {
			setMaxLife();
		}
	}
	void constructDesc(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		{
			auto grp = new Group(comp, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			grp.setLayoutData(gd);
			gd.horizontalSpan = 2;
			auto cl = new CenterLayout(SWT.HORIZONTAL);
			cl.fillVertical = true;
			grp.setLayout(cl);
			grp.setText(_prop.msgs.desc);
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(_summ.legacy)), _prop.looks.cardDescLen, grp, SWT.BORDER);
			mod(_desc.widget);
			createTextMenu!Text(_comm, _prop, _desc.widget, &catchMod);
			auto p = _desc.computeTextBaseSize(1);
			p.y = SWT.DEFAULT;
			_desc.widget.setLayoutData(p);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.desc);
		tab.setControl(comp);
	}
	class SelCoupon : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selCoupon();
		}
	}
	class HTBTraverse : Listener {
		override void handleEvent(Event e) {e.doit = true;}
	}
	class HTBKeyDown : Listener {
		override void handleEvent(Event e) {e.doit = true;}
	}
	void constructHistory(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		auto skin = _comm.skin;
		{
			auto grp = new Group(comp, SWT.NONE);
			_couponView = grp;
			grp.setText(_prop.msgs.coupons);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(2, false));
			{
				auto toolbar = new ToolBar(grp, SWT.FLAT);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 2;
				toolbar.setLayoutData(gd);
				toolbar.addListener(SWT.Traverse, new HTBTraverse);
				toolbar.addListener(SWT.KeyDown, new HTBKeyDown);
				createToolItem2(_comm, toolbar, _prop.msgs.addCoupon, _prop.images.addCoupon, &addCoupon, () => _newCoupon.getText().length > 0);
				createToolItem2(_comm, toolbar, _prop.msgs.altCoupon, _prop.images.altCoupon, &altCoupon, () => _newCoupon.getText().length > 0 && _coupons.getSelectionIndex() != -1);
				createToolItem2(_comm, toolbar, _prop.msgs.delCoupon, _prop.images.couponDelete, &delCoupon, () => _coupons.getSelectionIndex() != -1);
				new ToolItem(toolbar, SWT.SEPARATOR);
				createToolItem(_comm, toolbar, MenuID.Up, &upCoupon, () => _coupons.getSelectionIndex() != -1 && 0 < _coupons.getSelectionIndex());
				createToolItem(_comm, toolbar, MenuID.Down, &downCoupon, () => _coupons.getSelectionIndex() != -1 && _coupons.getSelectionIndex() + 1 < _coupons.getItemCount());
			}
			{
				_newCoupon = new Text(grp, SWT.BORDER);
				_newCouponTM = createTextMenu!Text(_comm, _prop, _newCoupon, &catchMod);
				_newCoupon.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_couponVal = new Spinner(grp, SWT.BORDER);
				_couponVal.setMinimum(cast(int) _prop.looks.couponValueMax * -1);
				_couponVal.setMaximum(_prop.looks.couponValueMax);
			}
			{
				_coupons = new Table(grp, SWT.BORDER | SWT.SINGLE | SWT.FULL_SELECTION);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.horizontalSpan = 2;
				gd.widthHint = _prop.var.etc.couponWidth;
				_coupons.setLayoutData(gd);
				auto cc = new FullTableColumn(_coupons, SWT.NONE);
				auto cv = new TableColumn(_coupons, SWT.NONE);
				cv.setWidth(40);
				saveColumnWidth!("prop.var.etc.couponValueColumn")(_prop, cv);
				auto menu = new Menu(_coupons);
				createMenuItem(_comm, menu, MenuID.Undo, &undoCoupons, &_undoCoupons.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &redoCoupons, &_undoCoupons.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Up, &upCoupon, () => _coupons.getSelectionIndex() != -1 && 0 < _coupons.getSelectionIndex());
				createMenuItem(_comm, menu, MenuID.Down, &downCoupon, () => _coupons.getSelectionIndex() != -1 && _coupons.getSelectionIndex() + 1 < _coupons.getItemCount());
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new CouponTCPD, true, true, true, true);
				_coupons.setMenu(menu);
			}
			_coupons.addSelectionListener(new SelCoupon);
			auto drag = new DragSource(_coupons, DND.DROP_MOVE | DND.DROP_COPY);
			drag.setTransfer([XMLBytesTransfer.getInstance()]);
			drag.addDragListener(new CDragListener);
			auto drop = new DropTarget(_coupons, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new CDropListener);
		}
		{
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			comp2.setLayout(zeroMarginGridLayout(2, false));
			Button createR(Composite parent, string name) {
				auto radio = new Button(parent, SWT.RADIO);
				mod(radio);
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				radio.setText(name);
				return radio;
			}
			{
				auto comp3 = createButtonGroup(comp2, _prop.msgs.sex, 1, 1);
				foreach (s; SEX_ALL) {
					_sex[s] = createR(comp3, _prop.sys.sexName(s, skin.legacyName));
				}
				_sexU = createR(comp3, _prop.msgs.sexUnknown);
			}
			{
				auto comp3 = createButtonGroup(comp2, _prop.msgs.period, 2, 1);
				foreach (p; PERIOD_ALL) {
					_period[p] = createR(comp3, _prop.sys.periodName(p, skin.legacyName));
				}
				_periodU = createR(comp3, _prop.msgs.periodUnknown);
			}
			{
				auto comp3 = createButtonGroup(comp2, _prop.msgs.nature, 2, 2);
				foreach (n; NATURE_DEF) {
					_nature[n] = createR(comp3, _prop.sys.natureName(n, skin.legacyName));
				}
				_natureU = createR(comp3, _prop.msgs.natureUnknown);
			}
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.history);
		tab.setControl(comp);
	}
	class MSListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto radio = cast(Button) e.widget;
			if (radio.getSelection()) {
				auto m = cast(Makings) (cast(Integer) radio.getData()).intValue();
				auto r = reverseMakings(m);
				_makings[r].setSelection(false);
			}
		}
	};
	void constructMakings(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		auto skin = _comm.skin;
		{
			auto comp3 = createButtonGroup(comp, _prop.msgs.coupons, 4, 1, true);
			auto sl = new MSListener;
			foreach (m; MAKINGS_LEFT) {
				void createR(Makings m) {
					auto radio = new Button(comp3, SWT.CHECK);
					mod(radio);
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					radio.setText(_prop.sys.makingsName(m, skin.legacyName));
					radio.setData(new Integer(m));
					radio.addSelectionListener(sl);
					_makings[m] = radio;
				}
				createR(m);
				createR(reverseMakings(m));
			}
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.makings);
		tab.setControl(comp);
	}
	Composite createButtonGroup(Composite parent, string name,
			int row, int horSpan = 1, bool min = false) {
		auto grp = new Group(parent, SWT.NONE);
		grp.setText(name);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.horizontalSpan = horSpan;
		grp.setLayoutData(gd);
		auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
		cl.fillVertical = true;
		grp.setLayout(cl);
		auto comp3 = new Composite(grp, SWT.NONE);
		auto gl = new GridLayout(row, true);
		if (min) gl.verticalSpacing = 2;
		comp3.setLayout(gl);
		return comp3;
	}
	class ESListener : SelectionAdapter {
		private Button _targ;
		this(Button targ) {
			_targ = targ;
		}
		override void widgetSelected(SelectionEvent e) {
			auto radio = cast(Button) e.widget;
			if (radio.getSelection()) {
				_targ.setSelection(false);
			}
		}
	};
	void constructResist(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		Button createC(Composite parent, string name, string desc) {
			auto comp = new Composite(parent, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp.setLayout(zeroGridLayout(2, false));
			auto c = new Button(comp, SWT.CHECK);
			mod(c);
			auto cgd = new GridData(GridData.FILL_HORIZONTAL);
			cgd.horizontalSpan = 2;
			c.setLayoutData(cgd);
			c.setText(name);
			auto dummy = new Composite(comp, SWT.NONE);
			auto dgd = new GridData;
			dgd.widthHint = 20;
			dgd.heightHint = 0;
			dummy.setLayoutData(dgd);
			auto l = new Label(comp, SWT.NONE);
			l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			l.setText(desc);
			return c;
		}
		{
			Composite tcomp, bcomp;
			{
				tcomp = createButtonGroup(comp, _prop.msgs.tolerantBase, 2, 1);
				auto gl = cast(GridLayout) tcomp.getLayout();
				gl.horizontalSpacing = 15;
				_resW = createC(tcomp, _prop.msgs.resistWeapon, _prop.msgs.descResistWeapon);
				_resM = createC(tcomp, _prop.msgs.resistMagic, _prop.msgs.descResistMagic);
			}
			{
				bcomp = createButtonGroup(comp, _prop.msgs.tolerantElement, 2, 1);
				auto gl = cast(GridLayout) bcomp.getLayout();
				gl.horizontalSpacing = 15;
				_undead = createC(bcomp, _prop.msgs.undead, _prop.msgs.descUndead);
				_automaton = createC(bcomp, _prop.msgs.automaton, _prop.msgs.descAutomaton);
				_unholy = createC(bcomp, _prop.msgs.unholy, _prop.msgs.descUnholy);
				_constructure = createC(bcomp, _prop.msgs.constructure, _prop.msgs.descConstructure);
				foreach (e; [Element.FIRE, Element.ICE]) {
					auto res = createC(bcomp, _prop.msgs.resistName(e), _prop.msgs.descResist(e));
					auto weak = createC(bcomp, _prop.msgs.weaknessName(e), _prop.msgs.descWeakness(e));
					res.addSelectionListener(new ESListener(weak));
					weak.addSelectionListener(new ESListener(res));
					_res[e] = res;
					_weak[e] = weak;
				}
			}
			auto ts = tcomp.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			auto bs = bcomp.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			int maxW = ts.x > bs.x ? ts.x : bs.x;
			ts.x = maxW;
			bs.x = maxW;
			tcomp.setLayoutData(ts);
			bcomp.setLayoutData(bs);
		}
		{
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setText(_prop.msgs.basicResist);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new BasicResist);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.tolerant);
		tab.setControl(comp);
	}
	void constructPhysical(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.physicalParams);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout;
			grp.setLayout(cl);
			_phy = new RadarSpinner(grp, SWT.NONE);
			mod(_phy);
			static const Ps = [Physical.DEX, Physical.AGL, Physical.INT,
				Physical.STR, Physical.VIT, Physical.MIN];
			string[] names;
			names.length = Ps.length;
			foreach (i, p; Ps) {
				_phyTbl[p] = i;
				names[i] = _prop.msgs.physicalName(p);
			}
			_phy.setRadar(_prop.looks.physicalMax + 1, names, 0);
			_phy.setRadarSize(_prop.var.etc.physicalRadarWidth, _prop.var.etc.physicalRadarHeight);
			_phy.antialias = true;
			_phy.borderlines = cast(int[]) _prop.looks.physicalBorders;
			_phy.lineStep = _prop.looks.physicalMax / 5;
		}
		{
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setText(_prop.msgs.physicalCalc);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new CalcPhysical);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.physicalParams);
		tab.setControl(comp);
	}
	real calcPhy(E)(Physical phy, Button[E] radios, bool all) {
		real r = 0.0;
		foreach (e, radio; radios) {
			if (radio.getSelection()) {
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
			foreach (phy, val; p) {
				val += calcPhy!(Sex)(phy, _sex, false);
				val += calcPhy!(Period)(phy, _period, false);
				val += calcPhy!(Nature)(phy, _nature, false);
				val += calcPhy!(Makings)(phy, _makings, true);
				p[phy] = val;
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
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.mentalParams);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto ggl = new GridLayout(3, false);
			ggl.verticalSpacing = 0;
			grp.setLayout(ggl);
			static const Ms = [Mental.AGGRESSIVE, Mental.CHEERFUL, Mental.BRAVE,
				Mental.CAUTIOUS, Mental.TRICKISH];
			foreach (m; Ms) {
				auto minl = new Label(grp, SWT.NONE);
				minl.setText(_prop.msgs.mentalName(reverseMental(m)));
				auto scale = new Scale(grp, SWT.NONE);
				mod(scale);
				scale.setLayoutData(new GridData(GridData.FILL_BOTH));
				scale.setMaximum(_prop.looks.mentalMax * 2);
				scale.setMinimum(0);
				scale.setIncrement(1);
				scale.setPageIncrement(_prop.looks.mentalMax);
				auto maxl = new Label(grp, SWT.NONE);
				maxl.setText(_prop.msgs.mentalName(m));
				_mtl[m] = scale;
			}
		}
		{
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setText(_prop.msgs.mentalCalc);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new CalcMental);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.mentalParams);
		tab.setControl(comp);
	}
	real calcMtl(E)(Mental mtl, Button[E] radios, bool all) {
		real r = 0.0;
		foreach (e, radio; radios) {
			if (radio.getSelection()) {
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
				scale.setSelection(v + _prop.looks.mentalMax);
			}
		}
	}
	void constructEnhance(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.castEnhance);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			_enh = new RadarSpinner(grp, SWT.NONE);
			mod(_enh);
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
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setText(_prop.msgs.basicEnhance);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new BasicEnhance);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.castEnhance);
		tab.setControl(comp);
	}
	void constructStatus(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		Label[] lbls1, lbls2;
		Composite[] spns;
		Spinner createSpn(Composite comp) {
			// なぜかCompositeを挟まなければSpinner#computeSize()が大きめの値を返す
			Composite comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayout(new FillLayout);
			auto spn = new Spinner(comp2, SWT.BORDER);
			mod(spn);
			spns ~= comp2;
			return spn;
		}
		Composite createGrp(string text) {
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto gl = new GridLayout(2, false);
			gl.horizontalSpacing = 15;
			grp.setLayout(gl);
			grp.setText(text);
			return grp;
		}
		Composite createComp(Composite grp) {
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto rl = new RowLayout(SWT.HORIZONTAL);
			rl.center = true;
			rl.marginLeft = 0;
			rl.marginRight = 0;
			rl.marginTop = 0;
			rl.marginBottom = 0;
			comp2.setLayout(rl);
			return comp2;
		}
		{
			auto grp = createGrp(_prop.msgs.lifeAndMentality);
			{
				auto comp2 = createComp(grp);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.life);
				lbls1 ~= l;
				_life = new Spinner(comp2, SWT.BORDER);
				mod(_life);
				_lifeUseMax = new Button(comp2, SWT.CHECK);
				mod(_lifeUseMax);
				_lifeUseMax.setText(_prop.msgs.useMax);
				_lifeUseMax.addSelectionListener(new LifeUseMax);
			}
			{
				auto comp2 = createComp(grp);
				auto lm = new Label(comp2, SWT.NONE);
				lm.setText(_prop.msgs.mentality);
				lbls1 ~= lm;
				_mtly = new Combo(comp2, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				mod(_mtly);
				_mtly.setVisibleItemCount(20);
				foreach (i, mtly; [Mentality.NORMAL, Mentality.SLEEP, Mentality.CONFUSE,
						Mentality.OVERHEAT, Mentality.BRAVE, Mentality.PANIC]) {
					_mtly.add(_prop.msgs.mentalityName(mtly));
					_mtlyTbl[i] = mtly;
					if (_card && _card.mentality is mtly) {
						_mtly.select(i);
					}
				}
				if (_mtly.getSelectionIndex() < 0) _mtly.select(0);
				_mtly.addSelectionListener(new SelMentality);
				_mtlyRound = createSpn(comp2);
				_mtlyRound.setMaximum(Motion.round_max);
				_mtlyRound.setMinimum(Motion.round_min);
				spns ~= _mtlyRound;
				auto lm2  = new Label(comp2, SWT.NONE);
				lm2.setText(_prop.msgs.unitRound);
			}
		}
		{
			auto grp = createGrp(_prop.msgs.enhanceLiveBonus);
			foreach (enh; [Enhance.ACTION, Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE]) {
				auto comp2 = createComp(grp);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.enhanceLiveBonusName(enh));
				lbls1 ~= l;
				auto spn = createSpn(comp2);
				spn.setMaximum(_prop.looks.enhanceMax);
				spn.setMinimum(-(cast(int) _prop.looks.enhanceMax));
				spns ~= spn;
				_liveEnh[enh] = spn;
				auto rnd = createSpn(comp2);
				rnd.setMaximum(Motion.round_max);
				rnd.setMinimum(Motion.round_min);
				spns ~= rnd;
				_enhRound[enh] = rnd;
				auto l2  = new Label(comp2, SWT.NONE);
				l2.setText(_prop.msgs.unitRound);
				spn.addSelectionListener(new LiveEnh);
			}
		}
		Spinner createStSpn(Composite grp, string name, uint max, string val) {
			auto comp2 = createComp(grp);
			auto l = new Label(comp2, SWT.NONE);
			l.setText(name);
			lbls1 ~= l;
			auto spn = createSpn(comp2);
			spn.setMaximum(max);
			spn.setMinimum(0);
			spns ~= spn;
			auto l2  = new Label(comp2, SWT.NONE);
			l2.setText(val);
			lbls2 ~= l2;
			return spn;
		}
		{
			auto grp = createGrp(_prop.msgs.status);
			_paralyze = createStSpn(grp, _prop.msgs.paralyze, _prop.looks.paralyzeMax, _prop.msgs.unitValue);
			_poison = createStSpn(grp, _prop.msgs.poison, _prop.looks.poisonMax, _prop.msgs.unitValue);
			_bind = createStSpn(grp, _prop.msgs.bind, Motion.round_max, _prop.msgs.unitRound);
			_silence = createStSpn(grp, _prop.msgs.silence, Motion.round_max, _prop.msgs.unitRound);
			_faceUp = createStSpn(grp, _prop.msgs.faceUp, Motion.round_max, _prop.msgs.unitRound);
			_antiMagic = createStSpn(grp, _prop.msgs.antiMagic, Motion.round_max, _prop.msgs.unitRound);
		}
		void setlblw(Control[] lbls) {
			int maxW = 0;
			foreach (lbl; lbls) {
				int w = lbl.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
				if (maxW < w) maxW = w;
			}
			foreach (lbl; lbls) {
				auto gd = new RowData(maxW, SWT.DEFAULT);
				lbl.setLayoutData(gd);
			}
		}
		setlblw(cast(Control[]) lbls1);
		setlblw(cast(Control[]) lbls2);
		setlblw(cast(Control[]) spns);
		{
			auto reset = new Button(comp, SWT.PUSH);
			mod(reset);
			reset.setText(_prop.msgs.resetLiveStatus);
			reset.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			reset.addSelectionListener(new ResetLiveStatus);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.liveStatus);
		tab.setControl(comp);
	}
	class LiveEnh : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			changeLiveEnhance();
		}
	}
	class SelMentality : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			changeMentality();
		}
	}
	class LifeUseMax : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			changeLifeUseMax();
		}
	}
	class ResetLiveStatus : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			resetLiveStatus();
		}
	}
	void changeLiveEnhance() {
		foreach (enh, spn; _liveEnh) {
			_enhRound[enh].setEnabled(spn.getSelection() != 0);
		}
	}
	void changeMentality() {
		_mtlyRound.setEnabled(_mtly.getSelectionIndex() != 0);
	}
	void changeLifeUseMax() {
		_life.setEnabled(!_lifeUseMax.getSelection());
	}
	void resetLiveStatus() {
		_life.setSelection(_lifeMax.getSelection());
		_lifeUseMax.setSelection(true);
		foreach (enh, spn; _liveEnh) {
			spn.setSelection(0);
		}
		foreach (enh, spn; _enhRound) {
			spn.setSelection(0);
		}
		_paralyze.setSelection(0);
		_poison.setSelection(0);
		_bind.setSelection(0);
		_silence.setSelection(0);
		_faceUp.setSelection(0);
		_antiMagic.setSelection(0);
		_mtly.select(0);
		_mtlyRound.setSelection(0);
		changeLiveEnhance();
		changeMentality();
		changeLifeUseMax();
	}
	void delCard(CastCard c) {
		if (_card is c) {
			forceCancel();
		}
	}
	void refScenario(Summary summ) {
		forceCancel();
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.delCast.remove(&delCard);
			_comm.refScenario.remove(&refScenario);
			_comm.refMenu.remove(&refMenu);
			_comm.refSkin.remove(&refSkin);
			_comm.refUndoMax.remove(&refUndoMax);
			e.widget.getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
		}
	}
	class KeyDownFilter : Listener {
		this () {
			refMenu(MenuID.Undo);
			refMenu(MenuID.Redo);
		}
		override void handleEvent(Event e) {
			auto c = cast(Control) e.widget;
			if (!c || c.getShell() !is getShell()) return;
			if (isDescendant(_couponView, c)) {
				if (c.getMenu() && findMenu(c.getMenu(), e.keyCode, e.character, e.stateMask)) return;
				if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) {
					_undoCoupons.undo();
					e.doit = false;
				} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) {
					_undoCoupons.redo();
					e.doit = false;
				}
			}
		}
	}
	private int _undoAcc;
	private int _redoAcc;
	void refMenu(MenuID id) {
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
	}
	void refSkin() {
		_desc.font = dwtData(_prop.looks.cardDescFont(_summ.legacy));
		refreshRace();
		refreshSex();
		refreshPeriod();
		refreshNature();
		refreshMakings();
	}
	void refreshRace() {
		_race.setEnabled(!_summ.legacy);
	}
	void refreshSex() {
		foreach (s; SEX_ALL) {
			_sex[s].setText(_prop.sys.sexName(s, _comm.skin.legacyName));
		}
	}
	void refreshPeriod() {
		foreach (p; PERIOD_ALL) {
			_period[p].setText(_prop.sys.periodName(p, _comm.skin.legacyName));
		}
	}
	void refreshNature() {
		foreach (n; NATURE_DEF) {
			_nature[n].setText(_prop.sys.natureName(n, _comm.skin.legacyName));
		}
	}
	void refreshMakings() {
		foreach (m; MAKINGS_LEFT) {
			void refresh(Makings m) {
				_makings[m].setText(_prop.sys.makingsName(m, _comm.skin.legacyName));
			}
			refresh(m);
			refresh(reverseMakings(m));
		}
	}

	void refUndoMax() {
		_undoCoupons.max = _prop.var.etc.undoMaxEtc;
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, CastCard card) {
		assert (summ !is null);
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		_undoCoupons = new UndoManager(_prop.var.etc.undoMaxEtc);
		super(prop, shell, false, _card ? _prop.msgs.dlgTitCast(_card.name) : _prop.msgs.dlgTitNewCast,
			_prop.images.casts, true, _prop.var.castCardDlg, true);
	}

	@property
	CastCard card() {
		return _card;
	}

	bool openCWXPath(string path, bool shellActivate) {
		return cpempty(path);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(windowGridLayout(1));
		auto tabf = new CTabFolder(area, SWT.BORDER);
		constructBase(tabf);
		constructDesc(tabf);
		constructHistory(tabf);
		constructMakings(tabf);
		constructResist(tabf);
		constructPhysical(tabf);
		constructMental(tabf);
		constructEnhance(tabf);
		constructStatus(tabf);

		_comm.delCast.add(&delCard);
		_comm.refScenario.add(&refScenario);
		_comm.refMenu.add(&refMenu);
		_comm.refSkin.add(&refSkin);
		_comm.refUndoMax.add(&refUndoMax);
		area.addDisposeListener(new Dispose);
		_kdFilter = new KeyDownFilter();
		area.getDisplay().addFilter(SWT.KeyDown, _kdFilter);

		// Windows Vistaだとタブの横幅が凄いことになったので必要最低限にする。
		scope maxSize = new Point(0, 0);
		foreach (tab; tabf.getItems()) {
			scope size = tab.getControl().computeSize(SWT.DEFAULT, SWT.DEFAULT);
			if (maxSize.x < size.x) maxSize.x = size.x;
			if (maxSize.y < size.y) maxSize.y = size.y;
		}
		scope rect = tabf.computeTrim(SWT.DEFAULT, SWT.DEFAULT, maxSize.x, maxSize.y);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = rect.width;
		gd.heightHint = rect.height;
		tabf.setLayoutData(gd);

		refCard(_card);
	}
	private void refCard(CastCard card) {
		if (_card && _card !is card) return;
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_undoCoupons.reset();
		auto skin = _comm.skin;
		if (_card) {
			_imgPath.image = _card.path;
			if (_race) _race.select(0);
			_desc.setText(_card.desc);
			_name.setText(_card.name);
			_level.setSelection(_card.level);
			_lifeMax.setSelection(_card.lifeMax);
			bool sex = false, period = false, nature = false;
			scope makings = new HashSet!(Makings);
			cp: foreach (c; _card.coupons) {
				foreach (s; SEX_ALL) {
					if (c.name == _prop.sys.sexCoupon(s, skin.legacyName)) {
						if (!sex) _sex[s].setSelection(true);
						sex = true;
						continue cp;
					}
				}
				foreach (per; PERIOD_ALL) {
					if (c.name == _prop.sys.periodCoupon(per, skin.legacyName)) {
						if (!period) _period[per].setSelection(true);
						period = true;
						continue cp;
					}
				}
				foreach (nat; NATURE_DEF) {
					if (c.name == _prop.sys.natureCoupon(nat, skin.legacyName)) {
						if (!nature) _nature[nat].setSelection(true);
						nature = true;
						continue cp;
					}
				}
				foreach (m; MAKINGS_LEFT) {
					if (c.name == _prop.sys.makingsCoupon(m, skin.legacyName)) {
						if (!makings.contains(m)) _makings[m].setSelection(true);
						makings.add(m);
						continue cp;
					}
					auto r = reverseMakings(m);
					if (c.name == _prop.sys.makingsCoupon(r, skin.legacyName)) {
						if (!makings.contains(m)) _makings[r].setSelection(true);
						makings.add(m);
						continue cp;
					}
				}
				if (_race) {
					foreach (i, r; _comm.skin.races) {
						if (c.name == _prop.msgs.raceCoupon(r)) {
							_race.select(i + 1);
							raceToolTip();
							continue cp;
						}
					}
				}
				appendCoupon(c);
			}
			if (!sex) _sexU.setSelection(true);
			if (!period) _periodU.setSelection(true);
			if (!nature) _natureU.setSelection(true);
			_resW.setSelection(_card.weaponResist);
			_resM.setSelection(_card.magicResist);
			_undead.setSelection(_card.undead);
			_automaton.setSelection(_card.automaton);
			_unholy.setSelection(_card.unholy);
			_constructure.setSelection(_card.constructure);
			foreach (e, radio; _res) {
				radio.setSelection(_card.resist(e));
			}
			foreach (e, radio; _weak) {
				radio.setSelection(_card.weakness(e));
			}
			foreach (phy, i; _phyTbl) {
				_phy.setValue(i, _card.physical(phy));
			}
			foreach (mtl, scale; _mtl) {
				scale.setSelection(_prop.looks.mentalMax + _card.mental(mtl));
			}
			foreach (enh, i; _enhTbl) {
				_enh.setValue(i, _card.defaultEnhance(enh));
			}

			_life.setSelection(_card.life);
			_lifeUseMax.setSelection(_card.life == _card.lifeMax);
			foreach (enh, spn; _liveEnh) {
				spn.setSelection(_card.enhance(enh));
			}
			foreach (enh, spn; _enhRound) {
				spn.setSelection(_card.enhanceRound(enh));
			}
			_paralyze.setSelection(_card.paralyze);
			_poison.setSelection(_card.poison);
			_bind.setSelection(_card.bindRound);
			_silence.setSelection(_card.silenceRound);
			_faceUp.setSelection(_card.faceUpRound);
			_antiMagic.setSelection(_card.antiMagicRound);
			_mtlyRound.setSelection(_card.mentalityRound);
			changeLiveEnhance();
			changeMentality();
			changeLifeUseMax();
		} else {
			_imgPath.image = "";
			if (_race) _race.select(0);
			_sexU.setSelection(true);
			_periodU.setSelection(true);
			_natureU.setSelection(true);
			int[] phys;
			phys.length = _phy.paramCount;
			phys[] = _prop.looks.physicalNormal;
			_phy.setValues(phys);
			foreach (radio; _mtl) {
				radio.setSelection(_prop.looks.mentalMax);
			}
			int[] bonus;
			bonus.length = _enh.paramCount;
			bonus[] = 0;
			_enh.setValues(bonus);

			resetLiveStatus();
		}
		setMaxLife();
	}

	private Coupon createCoupon(E)(Button[E] radios, string delegate(E, string) coupon, string legacyName) {
		foreach (e, radio; radios) {
			if (radio.getSelection()) {
				return new Coupon(coupon(e, legacyName), 0);
			}
		}
		return null;
	}
	override bool apply() {
		if (_card) {
			_card.path = _imgPath.image;
			_card.desc = _desc.getRRText();
			_card.name = _name.getText();
			_card.level = _level.getSelection();
			_card.lifeMax = _lifeMax.getSelection();
			_card.life = _lifeMax.getSelection();
		} else {
			_card = new CastCard(_summ.newId!(CastCard), _name.getText(), _imgPath.image,
				_desc.getRRText(), _level.getSelection(), _lifeMax.getSelection());
		}
		auto skin = _comm.skin;
		string legacyName = skin.legacyName;
		Coupon[] cs;
		auto sex = createCoupon!(Sex)(_sex, &_prop.sys.sexCoupon, legacyName);
		if (sex) cs ~= sex;
		auto race = selectedRace;
		if (race) {
			cs ~= new Coupon(_prop.msgs.raceCoupon(race), 0);
		}
		auto period = createCoupon!(Period)(_period, &_prop.sys.periodCoupon, legacyName);
		if (period) cs ~= period;
		auto nature = createCoupon!(Nature)(_nature, &_prop.sys.natureCoupon, legacyName);
		if (nature) cs ~= nature;
		foreach (m, radio; _makings) {
			if (radio.getSelection()) {
				cs ~= new Coupon(_prop.sys.makingsCoupon(m, legacyName), 0);
			}
		}
		cs ~= coupons;
		_card.coupons = cs;
		_card.weaponResist = _resW.getSelection();
		_card.magicResist = _resM.getSelection();
		_card.undead = _undead.getSelection();
		_card.automaton = _automaton.getSelection();
		_card.unholy = _unholy.getSelection();
		_card.constructure = _constructure.getSelection();
		foreach (e, radio; _res) {
			_card.resist(e, radio.getSelection());
		}
		foreach (e, radio; _weak) {
			_card.weakness(e, radio.getSelection());
		}
		foreach (phy, i; _phyTbl) {
			_card.physical(phy, _phy.getValue(i));
		}
		foreach (mtl, scale; _mtl) {
			_card.mental(mtl, cast(int) scale.getSelection() - _prop.looks.mentalMax);
		}
		foreach (enh, i; _enhTbl) {
			_card.defaultEnhance(enh, _enh.getValue(i));
		}

		_card.life = _lifeUseMax.getSelection() ? _card.lifeMax : _life.getSelection();
		foreach (enh, spn; _liveEnh) {
			if (_enhRound[enh].getSelection() > 0) {
				_card.enhance(enh, spn.getSelection());
			} else {
				_card.enhance(enh, 0);
			}
		}
		foreach (enh, spn; _enhRound) {
			if (_card.enhance(enh) != 0) {
				_card.enhanceRound(enh, spn.getSelection());
			}
		}
		_card.paralyze = _paralyze.getSelection();
		_card.poison = _poison.getSelection();
		_card.bindRound = _bind.getSelection();
		_card.silenceRound = _silence.getSelection();
		_card.faceUpRound = _faceUp.getSelection();
		_card.antiMagicRound = _antiMagic.getSelection();
		_card.mentality = _mtlyRound.getSelection() == 0
			? Mentality.NORMAL : _mtlyTbl[_mtly.getSelectionIndex()];
		_card.mentalityRound = _card.mentality == Mentality.NORMAL
			? 0 : _mtlyRound.getSelection();
		return true;
	}
}

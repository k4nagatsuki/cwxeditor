
module cwx.editor.gui.dwt.motionview;

import cwx.card;
import cwx.motion;
import cwx.types;
import cwx.summary;
import cwx.utils;
import cwx.xml;
import cwx.skin;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.effectcarddialog;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.string;
import std.datetime;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.Scale;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.custom.StackLayout;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
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

class MotionView : Composite {
private:
	string _id;

	Commons _comm;
	Props _prop;
	Summary _summ;

	Table _motions;
	Combo _beasts;
	BeastCard[int] _beastTbl;
	Canvas _beastImg;

	string[MType] _descs;

	Table _motionElm;
	Button _dmgTyp[DamageType];
	Scale _abiVal;
	Spinner _rndRound;
	Spinner _abiRound;
	Spinner _valValue;
	Image[TypeInfo] _imgMsns;
	Image[Element] _imgElm;

	Motion selection() {
		if (_motions.getSelectionIndex >= 0) {
			return cast(Motion) _motions.getItem(_motions.getSelectionIndex).getData;
		}
		return null;
	}
	class DamageTypeListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selection.damageType = getRadioValue!(DamageType)(_dmgTyp);
		}
	}
	class AbiValListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selection.aValue
				= _abiVal.getSelection - _prop.looks.motionAbilityValueMax;
		}
	}
	void roundEnter(int value) {
		selection.round = value;
	}
	int roundCancel(int oldVal) {
		selection.round = oldVal;
		return oldVal;
	}
	void valEnter(int value) {
		selection.uValue = value;
	}
	int valCancel(int oldVal) {
		selection.uValue = oldVal;
		return oldVal;
	}

	void createMT(MotionView v, ToolBar tbar, string group, MType type) {
		string tt = _prop.msgs.motion(type);
		_descs[type] = _prop.msgs.msnDesc(group, tt);
		class MT {
			// FIXME: アクセス違反に対処
			MotionView v;
			MType type;
			void create() {
				auto m = new Motion(type, Element.ALL);
				m.damageType = DamageType.LEVEL_RATIO;
				m.uValue = 1u;
				m.aValue = 0;
				m.round = v._prop.looks.motionRoundDefault;
				m.beast = null;
				v.appendMotion(m);
				v._motions.select(v._motions.getItemCount - 1);
				v.__refreshSels;
			}
		}
		auto mt = new MT;
		mt.v = v;
		mt.type = type;
		createToolItem(tbar, tt, _prop.images.motion(type), &mt.create);
	}
	bool editBeast() {
		auto m = selection;
		if (m && m.detail.use(MArg.BEAST)) {
			auto b = m.beast;
			if (b) {
				auto dlg = new EffectCardDialog!(BeastCard)(_comm, _prop, getShell, _summ, b);
				dlg.open;
				return true;
			}
		}
		return false;
	}
	class EditBeast : MouseAdapter, KeyListener {
	override:
		void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1) {
				editBeast;
			}
		}
		void keyReleased(KeyEvent e) {}
		void keyPressed(KeyEvent e) {
			if (e.character == SWT.CR) {
				if (editBeast) {
					e.doit = false;
				}
			}
		}
	}
	void swap(int index1, int index2) {
		auto itm1 = _motions.getItem(index1);
		auto itm2 = _motions.getItem(index2);
		auto img = itm1.getImage;
		auto text = itm1.getText;
		auto data = itm1.getData;
		itm1.setImage = itm2.getImage;
		itm1.setText = itm2.getText;
		itm1.setData = itm2.getData;
		itm2.setImage = img;
		itm2.setText = text;
		itm2.setData = data;
	}
	void up() {
		int index = _motions.getSelectionIndex;
		if (index > 0) {
			swap(index, index - 1);
			_motions.select(index - 1);
		}
	}
	void down() {
		int index = _motions.getSelectionIndex;
		if (index >= 0 && index + 1 < _motions.getItemCount) {
			swap(index, index + 1);
			_motions.select(index + 1);
		}
	}
	void removeMotion() {
		int index = _motions.getSelectionIndex;
		if (index >= 0) {
			_motions.remove(index);
			if (index >= _motions.getItemCount) index--;
			if (index >= 0) {
				_motions.select = index;
			}
			_oldIndex = -1;
			_motions.redraw;
			__refreshSels;
		}
	}
	void appendMotion(Motion motion, int index = -1) {
		TableItem itm;
		if (index >= 0) {
			itm = new TableItem(_motions, SWT.NONE, index);
		} else {
			itm = new TableItem(_motions, SWT.NONE);
		}
		itm.setImage = _prop.images.motion(motion.type);
		itm.setText = _descs[motion.type];
		itm.setData = motion;
	}
	Composite _editComp;
	Composite _noneComp;
	Composite _valueComp;
	Composite _roundComp;
	Composite _abilityComp;
	Composite _summonComp;
	int _oldIndex = -1;
	void __refreshSels() {
		auto sels = _motions.getSelection;
		auto stack = cast(StackLayout) _editComp.getLayout;
		_motionElm.setEnabled = sels.length > 0;
		if (sels.length == 0) {
			_motionElm.deselectAll;
			if (stack.topControl !is _noneComp && _oldIndex != -1) {
				stack.topControl = _noneComp;
				_editComp.layout;
			}
			_oldIndex = -1;
		} else if (_oldIndex != _motions.getSelectionIndex) {
			_oldIndex = _motions.getSelectionIndex;
			auto m = cast(Motion) sels[0].getData;
			foreach (i, itm; _motionElm.getItems) {
				if ((cast(Element) (cast(Integer) itm.getData).intValue) == m.element) {
					_motionElm.select = i;
					break;
				}
			}
			auto d = m.detail;
			if (d.use(MArg.BEAST)) {
				_beasts.select(0);
				_beastImg.redraw;
				if (stack.topControl !is _summonComp) {
					stack.topControl = _summonComp;
					_editComp.layout;
				}
			} else if (d.use(MArg.ROUND) && d.use(MArg.A_VALUE)) {
				_abiVal.setSelection = m.aValue + _prop.looks.motionAbilityValueMax;
				_abiRound.setSelection = m.round;
				if (stack.topControl !is _abilityComp) {
					stack.topControl = _abilityComp;
					_editComp.layout;
				}
			} else if (d.use(MArg.ROUND)) {
				_rndRound.setSelection = m.round;
				if (stack.topControl !is _roundComp) {
					stack.topControl = _roundComp;
					_editComp.layout;
				}
			} else if (d.use(MArg.U_VALUE)) {
				foreach (typ, radio; _dmgTyp) {
					_dmgTyp[typ].setSelection = (typ == m.damageType);
				}
				_valValue.setSelection = m.uValue;
				if (stack.topControl !is _valueComp) {
					stack.topControl = _valueComp;
					_editComp.layout;
				}
			} else {
				if (stack.topControl !is _noneComp) {
					stack.topControl = _noneComp;
					_editComp.layout;
				}
			}
		}
	}
	class ParamPaneChange : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			__refreshSels;
		}
	}
	class SetBeast : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int index = _beasts.getSelectionIndex;
			if (index >= 0) {
				auto sb = cast(Motion) _motions.getItem(_motions.getSelectionIndex).getData;
				sb.beast = _beastTbl[index];
				_beastImg.redraw;
			}
		}
	}
	class PaintBeast : PaintListener {
		override void paintControl(PaintEvent e) {
			auto beast = selection.beast;
			if (beast) {
				scope img = new Image(Display.getCurrent,
					cardImage!(BeastCard)(_prop, _comm.skin, beast, _summ.scenarioPath));
				scope data = img.getImageData;
				auto pane = cast(Canvas) e.widget;
				scope rect = pane.getClientArea;
				int x = (rect.width - data.width) / 2;
				int y = (rect.height - data.height) / 2;
				e.gc.drawImage(img, x, y);
				img.dispose;
				if (pane.isFocusControl) {
					e.gc.setBackground = Display.getCurrent.getSystemColor(SWT.COLOR_LIST_SELECTION);
					e.gc.setAlpha = 64;
					e.gc.fillRectangle(x, y, data.width, data.height);
					e.gc.setAlpha = 255;
				}
			}
		}
	}
	class MDropListener : DropTargetAdapter {
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
				if (node.name != Motion.XML_NAME) return;
				scope p = (cast(DropTarget) e.getSource).getControl.toControl(e.x, e.y);
				auto t = _motions.getItem(p);
				int index = t ? _motions.indexOf(t) : _motions.getItemCount;
				appendMotion(Motion.createFromNode(node, LATEST_VERSION), index);
				if (_id == node.attr("paneId", false)) {
					_motions.select(index);
					__refreshSels;
					e.detail = DND.DROP_MOVE;
				}
			} catch {}
		}
	}
	class MDragListener : DragSourceAdapter {
		private TableItem _itm;
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource).getControl.isFocusControl;
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance.isSupportedType(e.dataType)) {
				auto c = cast(Table) (cast(DragSource) e.getSource).getControl;
				int index = c.getSelectionIndex;
				if (index >= 0) {
					auto m = cast(Motion) c.getItem(index).getData;
					auto node = m.toNode;
					node.newAttr("paneId", _id);
					e.data = bytesFromXML(node.text);
					_itm = c.getItem(index);
				}
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				_itm.dispose;
				_motions.redraw;
			}
		}
	}
	class SelElement : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto m = selection;
			if (m) {
				m.element = cast(Element) (cast(Integer) _motionElm.getSelection[0].getData).intValue;
			}
		}
	}
public:
	this(Commons comm, Props prop, Summary summ, Composite parent) {
		super(parent, SWT.NONE);
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime);
		_comm = comm;
		_prop = prop;
		_summ = summ;

		setLayout = zeroMarginGridLayout(3, false);
		{
			auto mtabf = new CTabFolder(this, SWT.FLAT | SWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = 0;
			gd.horizontalSpan = 3;
			mtabf.setLayoutData = gd;
			ToolBar createBar(string name) {
				auto bar = new ToolBar(mtabf, SWT.FLAT);
				bar.addListener(SWT.Traverse, new class Listener {
					override void handleEvent(Event e) {e.doit = true;}
				});
				bar.addListener(SWT.KeyDown, new class Listener {
					override void handleEvent(Event e) {e.doit = true;}
				});
				createToolItem(bar, _prop.msgs.msnDelete, _prop.images.msnDelete, &removeMotion);
				new ToolItem(bar, SWT.SEPARATOR);
				createToolItem(bar, _prop.msgs.ttUp, _prop.images.menuUp, &up);
				createToolItem(bar, _prop.msgs.ttDown, _prop.images.menuDown, &down);
				new ToolItem(bar, SWT.SEPARATOR);
				auto tab = new CTabItem(mtabf, SWT.NONE);
				tab.setControl = bar;
				tab.setText = name;
				return bar;
			}
			{
				string g = _prop.msgs.msnGroupVitality;
				auto bar = createBar(g);
				createMT(this, bar, g, MType.HEAL);
				createMT(this, bar, g, MType.DAMAGE);
				createMT(this, bar, g, MType.ABSORB);
			}
			{
				string g = _prop.msgs.msnGroupPhysical;
				auto bar = createBar(g);
				createMT(this, bar, g, MType.PARALYZE);
				createMT(this, bar, g, MType.DIS_PARALYZE);
				createMT(this, bar, g, MType.POISON);
				createMT(this, bar, g, MType.DIS_POISON);
			}
			{
				string g = _prop.msgs.msnGroupSkill;
				auto bar = createBar(g);
				createMT(this, bar, g, MType.GET_SKILL_POWER);
				createMT(this, bar, g, MType.LOSE_SKILL_POWER);
			}
			{
				string g = _prop.msgs.msnGroupMental;
				auto bar = createBar(g);
				createMT(this, bar, g, MType.SLEEP);
				createMT(this, bar, g, MType.CONFUSE);
				createMT(this, bar, g, MType.OVERHEAT);
				createMT(this, bar, g, MType.BRAVE);
				createMT(this, bar, g, MType.PANIC);
				createMT(this, bar, g, MType.NORMAL);
			}
			{
				string g = _prop.msgs.msnGroupMagic;
				auto bar = createBar(g);
				createMT(this, bar, g, MType.BIND);
				createMT(this, bar, g, MType.DIS_BIND);
				createMT(this, bar, g, MType.SILENCE);
				createMT(this, bar, g, MType.DIS_SILENCE);
				createMT(this, bar, g, MType.FACE_UP);
				createMT(this, bar, g, MType.FACE_DOWN);
				createMT(this, bar, g, MType.ANTI_MAGIC);
				createMT(this, bar, g, MType.DIS_ANTI_MAGIC);
			}
			{
				string g = _prop.msgs.msnGroupEnhance;
				auto bar = createBar(g);
				createMT(this, bar, g, MType.ENHANCE_ACTION);
				createMT(this, bar, g, MType.ENHANCE_AVOID);
				createMT(this, bar, g, MType.ENHANCE_DEFENSE);
				createMT(this, bar, g, MType.ENHANCE_RESIST);
			}
			{
				string g = _prop.msgs.msnGroupVanish;
				auto bar = createBar(g);
				createMT(this, bar, g, MType.VANISH_TARGET);
				createMT(this, bar, g, MType.VANISH_CARD);
				createMT(this, bar, g, MType.VANISH_BEAST);
			}
			{
				string g = _prop.msgs.msnGroupCard;
				auto bar = createBar(g);
				createMT(this, bar, g, MType.DEAL_ATTACK_CARD);
				createMT(this, bar, g, MType.DEAL_POWERFUL_ATTACK_CARD);
				createMT(this, bar, g, MType.DEAL_CRITICAL_ATTACK_CARD);
				createMT(this, bar, g, MType.DEAL_FEINT_CARD);
				createMT(this, bar, g, MType.DEAL_DEFENSE_CARD);
				createMT(this, bar, g, MType.DEAL_DISTANCE_CARD);
				createMT(this, bar, g, MType.DEAL_CONFUSE_CARD);
				createMT(this, bar, g, MType.DEAL_SKILL_CARD);
			}
			{
				string g = _prop.msgs.msnGroupBeast;
				auto bar = createBar(g);
				createMT(this, bar, g, MType.SUMMON_BEAST);
			}
			mtabf.setSelection(0);
		}
		{
			_motions = new Table(this, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL | SWT.FULL_SELECTION);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.motionsWidth;
			_motions.setLayoutData = gd;
			_motions.setHeaderVisible = true;
			auto menu = new Menu(_motions);
			createMenuItem(menu, _prop.msgs.menuUp, _prop.images.menuUp, &up);
			createMenuItem(menu, _prop.msgs.menuDown, _prop.images.menuDown, &down);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_prop, menu, new MotionTCPD);
			_motions.setMenu = menu;
			usingPopupMenuAccelerator(_motions);
			auto col = new FullTableColumn(_motions, SWT.NONE);
			col.column.setText = _prop.msgs.motionKind;
		}
		{
			_motionElm = new Table(this, SWT.BORDER | SWT.SINGLE | SWT.NO_SCROLL | SWT.FULL_SELECTION);
			_motionElm.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			_motionElm.setHeaderVisible = true;
			_motionElm.addSelectionListener(new SelElement);
			_motionElm.setEnabled = false;
			auto col = new FullTableColumn(_motionElm, SWT.NONE);
			col.column.setText = _prop.msgs.motionElement;
			foreach (elm; [Element.ALL, Element.HEALTH, Element.MIND,
					Element.MIRACLE, Element.MAGIC, Element.FIRE, Element.ICE]) {
				auto itm = new TableItem(_motionElm, SWT.NONE);
				itm.setImage = _prop.images.element(elm);
				itm.setText = _prop.msgs.element(elm);
				itm.setData = new Integer(elm);
			}
		}
		{
			_editComp = new Composite(this, SWT.NONE);
			_editComp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			auto motionStack = new StackLayout;
			_editComp.setLayout = motionStack;
			Composite createC() {
				auto c = new Composite(_editComp, SWT.NONE);
				c.setLayout = zeroMarginGridLayout(1, false);
				return c;
			}
			_summonComp = createC;
			{
				auto grp = new Group(_summonComp, SWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new GridLayout(2, false);
				grp.setText = _prop.msgs.motionBeast;
				_beasts = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				_beasts.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_beasts.add(_prop.msgs.beastNone);
				_beastTbl[0] = null;
				foreach (i, c; _summ.beasts) {
					_beastTbl[i + 1] = c;
					_beasts.add(c.name);
				}
				auto setBeast = new Button(grp, SWT.PUSH);
				setBeast.setImage = _prop.images.setBeast;
				setBeast.setToolTipText = _prop.msgs.setBeast;
				setBeast.addSelectionListener(new SetBeast);
				_beastImg = new Canvas(grp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
				_beastImg.addListener(SWT.Traverse, new class Listener {
					override void handleEvent(Event e) {
						e.doit = true;
					}
				});
				_beastImg.addListener(SWT.KeyDown, new class Listener {
					override void handleEvent(Event e) {
						e.doit = true;
					}
				});
				_beastImg.addListener(SWT.MouseDown, new class Listener {
					override void handleEvent(Event e) {
						if (e.button == 1) (cast(Canvas) e.widget).setFocus;
					}
				});
				_beastImg.addListener(SWT.FocusOut, new class Listener {
					override void handleEvent(Event e) {
						(cast(Canvas) e.widget).redraw;
					}
				});
				_beastImg.addListener(SWT.FocusIn, new class Listener {
					override void handleEvent(Event e) {
						(cast(Canvas) e.widget).redraw;
					}
				});
				_beastImg.addPaintListener(new PaintBeast);
				auto eb = new EditBeast;
				_beastImg.addMouseListener(eb);
				_beastImg.addKeyListener(eb);
				auto menu = new Menu(_beastImg);
				appendMenuTCPD(_prop, menu, new BeastTCPD);
				_beastImg.setMenu = menu;
				usingPopupMenuAccelerator(_beastImg);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.horizontalSpan = 2;
				auto csize = _prop.looks.cardSize;
				auto mat = _prop.looks.menuCardInsets;
				csize.width += mat.e + mat.w;
				csize.height += mat.n + mat.s;
				auto rect = _beastImg.computeTrim(0, 0, csize.width, csize.height);
				gd.widthHint = rect.width;
				gd.heightHint = rect.height;
				_beastImg.setLayoutData = gd;
			}
			Spinner createSpinner(Composite parent, string name, int max, string hint,
					void delegate(int) edit, int delegate(int) cancel) {
				auto rgrp = new Group(parent, SWT.NONE);
				rgrp.setText = name;
				rgrp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				rgrp.setLayout = new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0);
				auto rcomp = new Composite(rgrp, SWT.NONE);
				rcomp.setLayout = new GridLayout(2, false);
				auto round = new Spinner(rcomp, SWT.BORDER);
				round.setMaximum = max;
				round.setMinimum = 1;
				new SpinnerEdit(round, edit, edit, cancel);
				auto l_round = new Label(rcomp, SWT.NONE);
				l_round.setText = hint;
				return round;
			}
			Spinner createRoundC(Composite parent) {
				return createSpinner(parent, _prop.msgs.motionRound, _prop.looks.motionMaxRound,
					_prop.msgs.rangeHint(1, _prop.looks.motionMaxRound), &roundEnter, &roundCancel);
			}
			_abilityComp = createC;
			{
				auto vgrp = new Group(_abilityComp, SWT.NONE);
				vgrp.setText = _prop.msgs.motionEnhValue;
				vgrp.setLayout = new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0);
				auto vcomp = new Composite(vgrp, SWT.NONE);
				vcomp.setLayout = new GridLayout(2, false);
				_abiVal = new Scale(vcomp, SWT.NONE);
				auto gd_av = new GridData(GridData.FILL_HORIZONTAL);
				gd_av.horizontalSpan = 2;
				_abiVal.setLayoutData = gd_av;
				_abiVal.setMinimum = 0;
				_abiVal.setMaximum = _prop.looks.motionAbilityValueMax * 2;
				_abiVal.setPageIncrement = _prop.looks.motionAbilityValueMax / 2;
				_abiVal.addSelectionListener(new AbiValListener);
				auto l_min = new Label(vcomp, SWT.NONE);
				l_min.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING);
				l_min.setText = to!(string)(cast(int) _prop.looks.motionAbilityValueMax * -1);
				auto l_max = new Label(vcomp, SWT.NONE);
				l_max.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
				l_max.setText = "+" ~ to!(string)(_prop.looks.motionAbilityValueMax);
				_abiRound = createRoundC(_abilityComp);
			}
			_roundComp = createC;
			{
				_rndRound = createRoundC(_roundComp);
			}
			_valueComp = createC;
			{
				auto grp = new Group(_valueComp, SWT.NONE);
				grp.setText = _prop.msgs.motionDamageType;
				grp.setLayout = new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0);
				grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayout = new GridLayout(1, false);
				auto dtl = new DamageTypeListener;
				foreach (typ; [DamageType.LEVEL_RATIO, DamageType.NORMAL, DamageType.MAX]) {
					auto radio = new Button(comp, SWT.RADIO);
					radio.setText = _prop.msgs.damageType(typ);
					radio.addSelectionListener(dtl);
					_dmgTyp[typ] = radio;
				}
				_valValue = createSpinner(_valueComp, _prop.msgs.motionValue, _prop.looks.motionValueMax,
					_prop.msgs.rangeHint(1, _prop.looks.motionValueMax), &valEnter, &valCancel);
			}
			_noneComp = createC;
			motionStack.topControl = _noneComp;
			_motions.addSelectionListener(new ParamPaneChange);
		}
		auto drag = new DragSource(_motions, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance]);
		drag.addDragListener(new MDragListener);
		auto drop = new DropTarget(_motions, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
		drop.setTransfer([XMLBytesTransfer.getInstance]);
		drop.addDropListener(new MDropListener);
	}
	void motions(Motion[] motions) {
		_motions.setRedraw = false;
		foreach (m; motions) {
			appendMotion(m.dup);
		}
		_motions.setRedraw = true;
	}
	Motion[] motions() {
		Motion[] r;
		r.length = _motions.getItemCount;
		foreach (i, itm; _motions.getItems) {
			r[i] = cast(Motion) itm.getData;
		}
		return r;
	}
	private class MotionTCPD : TCPD {
		override void cut(SelectionEvent se) {
			auto m = selection;
			if (m) {
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) {
			auto m = selection;
			if (m) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(_prop, cb, m.toXML);
			}
		}
		override void paste(SelectionEvent se) {
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			auto xml = CBtoXML(cb);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					if (node.name == Motion.XML_NAME) {
						appendMotion(Motion.createFromNode(node, LATEST_VERSION));
						_motions.select(_motions.getItemCount - 1);
						__refreshSels;
					} else {
						pasteBeast(node);
					}
				} catch {}
			}
		}
		override void del(SelectionEvent se) {
			removeMotion;
		}
		override bool canDoTCPD() {
			return _motions.isFocusControl;
		}
	}
	private void pasteBeast(ref XNode node) {
		auto m = selection;
		if (m && m.detail.use(MArg.BEAST)) {
			if (node.name == BeastCard.XML_NAME) {
				m.setBeastFromNode(node, LATEST_VERSION);
				_beastImg.redraw;
			}
		}
	}
	private class BeastTCPD : TCPD {
		private bool __copy() {
			auto m = selection;
			if (m) {
				assert (m.detail.use(MArg.BEAST));
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				if (m.beast) {
					XMLtoCB(_prop, cb, m.beast.toXML);
					return true;
				}
			}
			return false;
		}
		override void cut(SelectionEvent se) {
			if (__copy) {
				del(se);
			}
		}
		override void copy(SelectionEvent se) {
			__copy;
		}
		override void paste(SelectionEvent se) {
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			auto xml = CBtoXML(cb);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					pasteBeast(node);
				} catch {}
			}
		}
		override void del(SelectionEvent se) {
			auto m = selection;
			if (m) {
				assert (m.detail.use(MArg.BEAST));
				if (m.beast) {
					m.beast = null;
					_beastImg.redraw;
				}
			}
		}
		override bool canDoTCPD() {
			return _beastImg.isFocusControl;
		}
	}
}

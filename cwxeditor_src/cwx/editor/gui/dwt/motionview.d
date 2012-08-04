
module cwx.editor.gui.dwt.motionview;

import cwx.card;
import cwx.motion;
import cwx.types;
import cwx.summary;
import cwx.utils;
import cwx.xml;
import cwx.skin;
import cwx.event;
import cwx.path;
import cwx.menu;
import cwx.types;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.effectcarddialog;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.dmenu;

import std.string;
import std.datetime;
import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

public:

class MotionView : Composite {
public:
	/// 警告の有無が切り替わった時に呼び出される。
	void delegate()[] warningEvent;
	/// 効果の変更時に呼び出される。
	void delegate()[] modEvent;
private:
	static class MVUndo : Undo {
		protected MotionView _v = null;
		protected Commons comm;

		private int _selected = -1, _selectedB = -1;

		this (MotionView v, Commons comm) {
			_v = v;
			this.comm = comm;

			save(v);
		}
		private void save(MotionView v) {
			if (!v || v.isDisposed()) return;
			_selected = v._motions.getSelectionIndex();
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected void udb(MotionView v) {
			_selectedB = _selected;
			save(v);
		}
		protected void uda(MotionView v) {
			scope (exit) comm.refreshToolBar();
			if (!v || v.isDisposed()) return;
			v._motions.select(_selectedB);
			v._motions.showSelection();
			v.refreshSels(true);
		}
		protected MotionView view() {
			return _v;
		}
	}
	static class UndoEdit : MVUndo {
		private Motion _old;
		private int _index;
		this (MotionView v, Commons comm, int index) {
			super (v, comm);
			_old = v.motion(index).dup;
			_old.setUseCounter(comm.summary.useCounter.sub);
			_index = index;
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (!v || v.isDisposed()) return;
			auto old = _old;
			_old.removeUseCounter();
			_old = v.motion(_index).dup;
			_old.setUseCounter(comm.summary.useCounter.sub);
			auto m = v.motion(_index);
			v.motion(_index, old, false);
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {
			_old.removeUseCounter();
		}
	}
	void storeEdit(int index) {
		_undo ~= new UndoEdit(this, _comm, index);
	}
	static class UndoSwap : MVUndo {
		private int _index1, _index2;
		this (MotionView v, Commons comm, int index1, int index2) {
			super (v, comm);
			_index1 = index1;
			_index2 = index2;
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (!v || v.isDisposed()) return;
			v.swap(_index1, _index2, false);
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {}
	}
	void storeSwap(int index1, int index2) {
		_undo ~= new UndoSwap(this, _comm, index1, index2);
	}
	static class UndoMove : MVUndo {
		private int _from, _to;
		this (MotionView v, Commons comm, int from, int to) {
			super (v, comm);
			_from = from;
			_to = to;
			if (_from < _to) _to--;
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (!v || v.isDisposed()) return;
			int from = _from;
			int to = _to;
			auto m = v.motion(to);
			v.removeMotion(to, false, false, false);
			v.appendMotion(m, from, true, true, false);
			std.algorithm.swap(_from, _to);
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {}
	}
	void storeMove(int from, int to) {
		_undo ~= new UndoMove(this, _comm, from, to);
	}
	static class UndoInsertDelete : MVUndo {
		private bool _insert;

		private int _index;

		private Motion _m = null;

		this (MotionView v, Commons comm, int index, bool insert) {
			super (v, comm);
			_insert = insert;
			_index = index;

			if (!insert) {
				initUndoDelete(v);
			}
		}
		private void initUndoDelete(MotionView v) {
			if (!v || v.isDisposed()) return;
			_m = v.motion(_index).dup;
			_m.setUseCounter(comm.summary.useCounter.sub);
		}
		private void undoInsert() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_insert = false;
			initUndoDelete(v);
			if (!v || v.isDisposed()) return;
			v.removeMotion(_index, true, true, false);
		}
		void undoDelete() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (!v || v.isDisposed()) return;
			auto m = _m;
			_m.removeUseCounter();
			_m = null;
			_insert = true;
			v.appendMotion(m, _index, true, true, false);
		}
		override void undo() {
			if (_insert) {
				undoInsert();
			} else {
				undoDelete();
			}
		}
		override void redo() {
			undo();
		}
		override void dispose() {
			if (_m) {
				_m.removeUseCounter();
			}
		}
	}
	void storeInsert(int index) {
		_undo ~= new UndoInsertDelete(this, _comm, index, true);
	}
	void storeDelete(int index) {
		_undo ~= new UndoInsertDelete(this, _comm, index, false);
	}

	string _id;

	Commons _comm;
	Props _prop;
	Summary _summ;
	UndoManager _undo;
	KeyDownFilter _kdFilter;

	Table _motions;
	Combo _beasts;
	BeastCard[int] _beastTbl;
	Canvas _beastImg;
	Spinner _maxNest;

	string[MType] _descs;

	Table _motionElm;
	Button _dmgTyp[DamageType];
	Scale _abiVal;
	Spinner _rndRound;
	Spinner _abiRound;
	Spinner _valValue;
	Image[TypeInfo] _imgMsns;
	Image[Element] _imgElm;

	HashSet!BeastEventWindow _beWin;
	BeastEventWindow openBeastEventWin(BeastCard beast) {
		if (0 != beast.linkId) {
			auto b = _summ.beast(beast.linkId);
			if (!b) return null;
			return _comm.openUseEvents(_prop, _summ, b, true);
		}
		auto w = _comm.openUseEvents(_prop, _summ, beast, true);
		if (_beWin.contains(w)) return w;
		w.shell.addDisposeListener(new CloseRemover!(BeastEventWindow)(_beWin, w));
		_beWin.add(w);
		return w;
	}
	void editBeastUseEvent() {
		auto m = selection;
		if (!m || !m.detail.use(MArg.BEAST)) return;
		auto b = m.beast;
		if (!b) return;
		openBeastEventWin(b);
	}
	bool canEditBeast() {
		auto m = selection;
		if (!m || !m.beast) return false;
		if (0 != m.beast.linkId && !_summ.beast(m.beast.linkId)) return false;
		return true;
	}

	Motion motion(int index) {
		return cast(Motion) _motions.getItem(index).getData();
	}
	void motion(int index, Motion m, bool store) {
		if (store) storeEdit(index);
		auto itm = _motions.getItem(index);
		auto o = cast(Motion) itm.getData();
		assert (o);
		if (o.beast) {
			_comm.delBeast.call(o.beast);
		}
		itm.setData(m);
		if (index == _motions.getSelectionIndex()) {
			refreshSels();
		}
		foreach (dlg; modEvent) dlg();
		foreach (dlg; warningEvent) dlg();
	}
	@property
	Motion selection() {
		int i = _motions.getSelectionIndex();
		if (i >= 0) {
			return motion(i);
		}
		return null;
	}
	class DamageTypeListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto m = selection;
			if (!m) return;
			auto val = getRadioValue!(DamageType)(_dmgTyp);
			if (m.damageType != val) {
				storeEdit(_motions.getSelectionIndex());
				m.damageType = val;
				foreach (dlg; modEvent) dlg();
			}
		}
	}
	class AbiValListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto m = selection;
			if (!m) return;
			auto val = _abiVal.getSelection() - Motion.aValue_max;
			if (m.aValue != val) {
				storeEdit(_motions.getSelectionIndex());
				m.aValue = val;
				foreach (dlg; modEvent) dlg();
			}
		}
	}
	void roundEnter(int value) {
		auto m = selection;
		if (!m) return;
		if (m.round != value) {
			storeEdit(_motions.getSelectionIndex());
			m.round = value;
			foreach (dlg; modEvent) dlg();
		}
	}
	int roundCancel(int oldVal) {
		roundEnter(oldVal);
		return oldVal;
	}
	void valEnter(int value) {
		auto m = selection;
		if (!m) return;
		if (m.uValue != value) {
			storeEdit(_motions.getSelectionIndex());
			m.uValue = value;
			foreach (dlg; modEvent) dlg();
		}
	}
	int valCancel(int oldVal) {
		valEnter(oldVal);
		return oldVal;
	}

	void createMT(MotionView v, ToolBar tbar, string group, MType type) {
		string tt = _prop.msgs.motionName(type);
		_descs[type] = .tryFormat(_prop.msgs.msnDesc, group, tt);
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
				v._motions.select(v._motions.getItemCount() - 1);
				v.refreshSels();
				foreach (dlg; v.modEvent) dlg();
			}
		}
		auto mt = new MT;
		mt.v = v;
		mt.type = type;
		createToolItem2(_comm, tbar, tt, _prop.images.motion(type), &mt.create, null);
	}
	int indexOf(Motion m) {
		foreach (i, itm; _motions.getItems()) {
			if (m is itm.getData()) return i;
		}
		return -1;
	}
	private EffectCardDialog!(BeastCard) _beastDlg = null;
	void editBeastM() {
		editBeast();
	}
	EffectCardDialog!BeastCard editBeast() {
		auto m = selection;
		if (m && m.detail.use(MArg.BEAST)) {
			auto b = m.beast;
			if (b) {
				if (0 != b.linkId) {
					auto b2 = _summ.beast(b.linkId);
					if (b2) {
						_comm.openCWXPath(b2.cwxPath(true), false);
						return _comm.openBeastWin(false).edit(b2);
					}
					return null;
				}
				if (_beastDlg) {
					_beastDlg.active();
				} else {
					_beastDlg = new EffectCardDialog!(BeastCard)(_comm, _prop, getShell(), _summ, b);
					_beastDlg.open();
					_beastDlg.applyEvent ~= {
						storeEdit(indexOf(m));
					};
					_beastDlg.appliedEvent ~= {
						foreach (dlg; modEvent) dlg();
					};
					_beastDlg.closeEvent ~= {
						_beastDlg = null;
					};
				}
				return _beastDlg;
			}
		}
		return null;
	}
	class EditBeast : MouseAdapter, KeyListener {
	override:
		void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1) {
				editBeast();
			}
		}
		void mouseDown(MouseEvent e) {
			auto ctrl = cast(Control) e.widget;
			ctrl.setFocus();
		}
		void keyReleased(KeyEvent e) {}
		void keyPressed(KeyEvent e) {
			if (e.character == SWT.CR) {
				if (editBeast()) {
					e.doit = false;
				}
			}
		}
	}
	void swap(int index1, int index2, bool store) {
		if (store) storeSwap(index1, index2);
		auto itm1 = _motions.getItem(index1);
		auto itm2 = _motions.getItem(index2);
		auto img = itm1.getImage();
		auto text = itm1.getText();
		auto data = itm1.getData();
		itm1.setImage(itm2.getImage());
		itm1.setText(itm2.getText());
		itm1.setData(itm2.getData());
		itm2.setImage(img);
		itm2.setText(text);
		itm2.setData(data);
		foreach (dlg; modEvent) dlg();
	}
	void up() {
		int index = _motions.getSelectionIndex();
		if (index > 0) {
			swap(index, index - 1, true);
			_motions.select(index - 1);
			_comm.refreshToolBar();
		}
	}
	void down() {
		int index = _motions.getSelectionIndex();
		if (index >= 0 && index + 1 < _motions.getItemCount()) {
			swap(index, index + 1, true);
			_motions.select(index + 1);
			_comm.refreshToolBar();
		}
	}
	void removeMotion() {
		removeMotion(-1, true, true, true);
	}
	void removeMotion(int index, bool callEvent, bool callMod, bool store) {
		bool oldVan = hasVan;
		scope (exit) {
			if (callEvent && oldVan != hasVan) {
				foreach (we; warningEvent) we();
			}
			_comm.refreshToolBar();
		}
		if (-1 == index) {
			index = _motions.getSelectionIndex();
		}
		if (index >= 0) {
			if (store) storeDelete(index);
			auto m = cast(Motion) _motions.getItem(index).getData();
			assert (m);
			if (m.beast) {
				_comm.delBeast.call(m.beast);
			}
			_motions.remove(index);
			if (index >= _motions.getItemCount()) index--;
			if (index >= 0) {
				_motions.select(index);
			}
			_oldIndex = -1;
			_motions.redraw();
			refreshSels();
			if (callMod) {
				foreach (dlg; modEvent) dlg();
			}
		}
	}
	void appendMotion(Motion motion, int index = -1, bool callEvent = true, bool callMod = false, bool store = true) {
		bool oldVan;
		if (callEvent) {
			oldVan = hasVan;
		}
		scope (exit) {
			if (callEvent && oldVan != hasVan) {
				foreach (we; warningEvent) we();
			}
			_comm.refreshToolBar();
		}
		TableItem itm;
		if (store) {
			storeInsert(0 <= index ? index : _motions.getItemCount());
		}
		if (0 <= index) {
			itm = new TableItem(_motions, SWT.NONE, index);
		} else {
			itm = new TableItem(_motions, SWT.NONE);
		}
		itm.setImage(_prop.images.motion(motion.type));
		itm.setText(_descs[motion.type]);
		itm.setData(motion);
		if (callMod) {
			foreach (dlg; modEvent) dlg();
		}
	}
	Composite _editComp;
	Composite _noneComp;
	Composite _valueComp;
	Composite _roundComp;
	Composite _abilityComp;
	Composite _summonComp;
	int _oldIndex = -1;
	void refreshSels(bool force = false) {
		scope(exit) refEnabled();
		auto sels = _motions.getSelection();
		auto stack = cast(StackLayout) _editComp.getLayout();
		_motionElm.setEnabled(sels.length > 0);
		if (sels.length == 0) {
			_motionElm.deselectAll();
			stack.topControl = _noneComp;
			_editComp.layout();
			_oldIndex = -1;
		} else if (force || _oldIndex != _motions.getSelectionIndex()) {
			_oldIndex = _motions.getSelectionIndex();
			auto m = cast(Motion) _motions.getItem(_oldIndex).getData();
			foreach (i, itm; _motionElm.getItems()) {
				if ((cast(Element) (cast(Integer) itm.getData()).intValue()) == m.element) {
					_motionElm.select(i);
					break;
				}
			}
			auto d = m.detail;
			if (d.use(MArg.BEAST)) {
				_beasts.select(0);
				_maxNest.setSelection(m.maxNest);
				_beastImg.redraw();
				if (stack.topControl !is _summonComp) {
					stack.topControl = _summonComp;
					_editComp.layout();
				}
			} else if (d.use(MArg.ROUND) && d.use(MArg.A_VALUE)) {
				_abiVal.setSelection(m.aValue + Motion.aValue_max);
				_abiRound.setSelection(m.round);
				if (stack.topControl !is _abilityComp) {
					stack.topControl = _abilityComp;
					_editComp.layout();
				}
			} else if (d.use(MArg.ROUND)) {
				_rndRound.setSelection(m.round);
				if (stack.topControl !is _roundComp) {
					stack.topControl = _roundComp;
					_editComp.layout();
				}
			} else if (d.use(MArg.U_VALUE)) {
				foreach (typ, radio; _dmgTyp) {
					_dmgTyp[typ].setSelection((typ == m.damageType));
				}
				_valValue.setSelection(m.uValue);
				if (stack.topControl !is _valueComp) {
					stack.topControl = _valueComp;
					_editComp.layout();
				}
			} else {
				if (stack.topControl !is _noneComp) {
					stack.topControl = _noneComp;
					_editComp.layout();
				}
			}
		}
		_comm.refreshToolBar();
	}
	class ParamPaneChange : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshSels();
		}
	}
	bool canSetBeast() {
		int index = _beasts.getSelectionIndex();
		if (index > 0) {
			int mi = _motions.getSelectionIndex();
			auto sb = cast(Motion) _motions.getItem(mi).getData();
			auto b = _beastTbl[index];
			return sb.beast || b;
		}
		return false;
	}
	@property
	BeastCard selectedBeast() {
		int index = _beasts.getSelectionIndex();
		if (-1 != index) return _beastTbl[index];
		return null;
	}
	class SetBeast : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto b = selectedBeast;
			if (b) {
				int mi = _motions.getSelectionIndex();
				auto sb = cast(Motion) _motions.getItem(mi).getData();
				if (!sb.beast && !b) return;
				storeEdit(mi);
				if (sb.beast) _comm.delBeast.call(sb.beast);
				if (_prop.var.etc.linkCard) {
					sb.beast = new BeastCard(1UL, "", "", "");
					sb.beast.linkId = b.id;
				} else {
					sb.beast = b;
				}
				resetMaxNest(sb);
				_beastImg.redraw();
				foreach (dlg; modEvent) dlg();
				refEnabled();
			}
		}
	}
	void removeRef() {
		auto m = selection;
		if (!m || !m.beast || 0 == m.beast.linkId) return;
		auto targ = _summ.beast(m.beast.linkId);
		if (!targ) return;
		auto id = m.beast.id;
		m.beast.deepCopy(targ);
		m.beast.id = id;
		m.beast.linkId = 0;

		resetMaxNest(m);
		_beastImg.redraw();
		foreach (dlg; modEvent) dlg();
		refEnabled();
	}
	class PaintBeast : PaintListener {
		override void paintControl(PaintEvent e) {
			auto beast = selection.beast;
			if (beast) {
				scope img = new Image(Display.getCurrent(),
					cardImage!(BeastCard)(_prop, _comm.skin, beast, _summ.scenarioPath, null, &_summ.beast, true));
				scope data = img.getImageData();
				auto pane = cast(Canvas) e.widget;
				scope rect = pane.getClientArea();
				int x = (rect.width - data.width) / 2;
				int y = (rect.height - data.height) / 2;
				e.gc.drawImage(img, x, y);
				img.dispose();
				if (pane.isFocusControl()) {
					e.gc.setBackground(Display.getCurrent().getSystemColor(SWT.COLOR_LIST_SELECTION));
					e.gc.setAlpha(64);
					e.gc.fillRectangle(x, y, data.width, data.height);
					e.gc.setAlpha(255);
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
				scope p = (cast(DropTarget) e.getSource()).getControl().toControl(e.x, e.y);
				auto t = _motions.getItem(p);
				int index = t ? _motions.indexOf(t) : _motions.getItemCount();
				auto m = Motion.createFromNode(node, LATEST_VERSION);
				if (_id == node.attr("paneId", false)) {
					if (-1 != _dragIndex) {
						storeMove(_dragIndex, index);
						appendMotion(m, index, true, false, false);
					} else {
						appendMotion(m, index, true, false, true);
					}
					_motions.select(index);
					refreshSels();
					e.detail = DND.DROP_MOVE;
				} else {
					appendMotion(m, index, true, false, true);
				}
				foreach (dlg; modEvent) dlg();
			} catch {}
		}
	}
	private int _dragIndex = -1;
	class MDragListener : DragSourceAdapter {
		private TableItem _itm;
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
				auto c = cast(Table) (cast(DragSource) e.getSource()).getControl();
				int index = c.getSelectionIndex();
				if (index >= 0) {
					auto m = cast(Motion) c.getItem(index).getData();
					_dragIndex = index;
					auto node = m.toNode(null);
					node.newAttr("paneId", _id);
					e.data = bytesFromXML(node.text);
					_itm = c.getItem(index);
				}
			}
		}
		override void dragFinished(DragSourceEvent e) {
			_dragIndex = -1;
			if (e.detail == DND.DROP_MOVE) {
				bool oldVan = hasVan;
				scope (exit) {
					if (oldVan != hasVan) {
						foreach (we; warningEvent) we();
					}
				}
				_itm.dispose();
				_motions.redraw();
				foreach (dlg; modEvent) dlg();
				_comm.refreshToolBar();
			}
		}
	}
	@property
	bool hasVan() {
		foreach (itm; _motions.getItems()) {
			auto m = cast(Motion) itm.getData();
			assert (m);
			if ((m.element !is Element.MIRACLE) && (m.type is MType.VANISH_TARGET)) {
				return true;
			}
		}
		return false;
	}
	class SelElement : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto m = selection;
			if (m) {
				int i = _motionElm.getSelectionIndex();
				if (-1 == i) return;
				storeEdit(_motions.getSelectionIndex());
				bool oldVan = hasVan;
				scope (exit) {
					if (oldVan != hasVan) {
						foreach (we; warningEvent) we();
					}
				}
				m.element = cast(Element) (cast(Integer) _motionElm.getItem(i).getData()).intValue();
				foreach (dlg; modEvent) dlg();
			}
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refMenu.remove(&refMenu);
			_comm.refBeast.remove(&refBeast);
			_comm.delBeast.remove(&refBeast);
			_comm.refUndoMax.remove(&refUndoMax);
			getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
			foreach (w; _beWin.toArray()) {
				_comm.close(w.shell);
			}
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
			if (!isDescendant(this.outer, c)) return;
			if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) {
				_undo.undo();
				e.doit = false;
			} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) {
				_undo.redo();
				e.doit = false;
			}
		}
	}
	private int _undoAcc;
	private int _redoAcc;
	void refMenu(MenuID id) {
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
	}
	void refBeast(BeastCard beast) {
		refBeasts();
	}
	void refBeasts() {
		setRedraw(false);
		scope (exit) setRedraw(true);
		ulong selId = 0;
		auto sel = selectedBeast;
		if (sel) selId = sel.id;
		_beasts.removeAll();
		typeof(_beastTbl) b;
		_beastTbl = b;
		_beasts.add(_prop.msgs.beastNone);
		_beastTbl[0] = null;
		_beasts.select(0);
		foreach (i, c; _summ.beasts) {
			_beastTbl[i + 1] = c;
			_beasts.add(c.name);
			if (c.id == selId) _beasts.select(_beasts.getItemCount() - 1);
		}
		refEnabled();
	}
	bool _refUndo = false;
	void refUndoMax() {
		if (!_refUndo) return;
		_undo.max = _prop.var.etc.undoMaxEtc;
	}
public:
	this (Commons comm, Props prop, Summary summ, Composite parent, UndoManager undo = null) {
		super(parent, SWT.NONE);
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_refUndo = undo is null;
		_undo = undo ? undo : new UndoManager(_prop.var.etc.undoMaxEtc);
		_beWin = new typeof(_beWin);

		setLayout(zeroMarginGridLayout(3, false));
		{
			auto mtabf = new CTabFolder(this, SWT.FLAT | SWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = 0;
			gd.horizontalSpan = 3;
			mtabf.setLayoutData(gd);
			ToolBar createBar(string name) {
				auto bar = new ToolBar(mtabf, SWT.FLAT);
				_comm.put(bar);
				bar.addListener(SWT.Traverse, new class Listener {
					override void handleEvent(Event e) {e.doit = true;}
				});
				bar.addListener(SWT.KeyDown, new class Listener {
					override void handleEvent(Event e) {e.doit = true;}
				});
				createToolItem2(_comm, bar, _prop.msgs.msnDelete, _prop.images.msnDelete, &removeMotion, () => _motions.getSelectionIndex() != -1);
				new ToolItem(bar, SWT.SEPARATOR);
				createToolItem(_comm, bar, MenuID.Up, &up, () => _motions.getSelectionIndex() != -1 && 0 < _motions.getSelectionIndex());
				createToolItem(_comm, bar, MenuID.Down, &down, () => _motions.getSelectionIndex() != -1 && _motions.getSelectionIndex() + 1 < _motions.getItemCount());
				new ToolItem(bar, SWT.SEPARATOR);
				auto tab = new CTabItem(mtabf, SWT.NONE);
				tab.setControl(bar);
				tab.setText(name);
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
			_motions.setLayoutData(gd);
			_motions.setHeaderVisible(true);
			auto menu = new Menu(_motions);
			createMenuItem(_comm, menu, MenuID.Undo, &this.undo, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, &this.redo, &_undo.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.Up, &up, () => _motions.getSelectionIndex() != -1 && 0 < _motions.getSelectionIndex());
			createMenuItem(_comm, menu, MenuID.Down, &down, () => _motions.getSelectionIndex() != -1 && _motions.getSelectionIndex() + 1 < _motions.getItemCount());
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, new MotionTCPD, true, true, true, true);
			_motions.setMenu(menu);
			auto col = new FullTableColumn(_motions, SWT.NONE);
			col.column.setText(_prop.msgs.motionKind);
		}
		{
			_motionElm = new Table(this, SWT.BORDER | SWT.SINGLE | SWT.NO_SCROLL | SWT.FULL_SELECTION);
			_motionElm.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			_motionElm.setHeaderVisible(true);
			_motionElm.addSelectionListener(new SelElement);
			_motionElm.setEnabled(false);
			auto col = new FullTableColumn(_motionElm, SWT.NONE);
			col.column.setText(_prop.msgs.motionElement);
			foreach (elm; [Element.ALL, Element.HEALTH, Element.MIND,
					Element.MIRACLE, Element.MAGIC, Element.FIRE, Element.ICE]) {
				auto itm = new TableItem(_motionElm, SWT.NONE);
				itm.setImage(_prop.images.element(elm));
				itm.setText(_prop.msgs.elementName(elm));
				itm.setData(new Integer(elm));
			}
			auto menu = new Menu(_motionElm);
			createMenuItem(_comm, menu, MenuID.Undo, &this.undo, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, &this.redo, &_undo.canRedo);
			_motionElm.setMenu(menu);
		}
		{
			_editComp = new Composite(this, SWT.NONE);
			_editComp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			auto motionStack = new StackLayout;
			_editComp.setLayout(motionStack);
			Composite createC() {
				auto c = new Composite(_editComp, SWT.NONE);
				c.setLayout(zeroMarginGridLayout(1, false));
				return c;
			}
			_summonComp = createC();
			{
				auto grp = new Group(_summonComp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new GridLayout(2, false));
				grp.setText(_prop.msgs.motionBeast);
				_beasts = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				_beasts.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_beasts.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						_comm.refreshToolBar();
					}
				});
				refBeasts();
				auto setBeast = new Button(grp, SWT.PUSH);
				setBeast.setImage(_prop.images.setBeast);
				setBeast.setToolTipText(_prop.msgs.setBeast);
				setBeast.addSelectionListener(new SetBeast);
				_comm.put(setBeast, &canSetBeast);
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
						if (e.button == 1) (cast(Canvas) e.widget).setFocus();
					}
				});
				_beastImg.addListener(SWT.FocusOut, new class Listener {
					override void handleEvent(Event e) {
						(cast(Canvas) e.widget).redraw();
					}
				});
				_beastImg.addListener(SWT.FocusIn, new class Listener {
					override void handleEvent(Event e) {
						(cast(Canvas) e.widget).redraw();
					}
				});
				_beastImg.addPaintListener(new PaintBeast);
				auto eb = new EditBeast;
				_beastImg.addMouseListener(eb);
				_beastImg.addKeyListener(eb);
				auto menu = new Menu(_beastImg);
				createMenuItem(_comm, menu, MenuID.EditProp, &editBeastM, &canEditBeast);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.EditEventAtTimeOfUsing, &editBeastUseEvent, &canEditBeast);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.RemoveRef, &removeRef, () => selection && selection.beast && 0 != selection.beast.linkId && _summ.beast(selection.beast.linkId));
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Undo, &this.undo, &_undo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &this.redo, &_undo.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new BeastTCPD, true, true, true, true);
				_beastImg.setMenu(menu);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.horizontalSpan = 2;
				auto csize = _prop.looks.cardSize;
				auto mat = _prop.looks.menuCardInsets;
				csize.width += mat.e + mat.w;
				csize.height += mat.n + mat.s;
				auto rect = _beastImg.computeTrim(0, 0, csize.width, csize.height);
				gd.widthHint = rect.width;
				gd.heightHint = rect.height;
				_beastImg.setLayoutData(gd);

				auto grp2 = new Group(_summonComp, SWT.NONE);
				grp2.setText(_prop.msgs.linkOption);
				auto gd2 = new GridData(GridData.FILL_HORIZONTAL);
				gd2.horizontalSpan = 2;
				grp2.setLayoutData(gd2);
				grp2.setLayout(new CenterLayout);
				auto comp2 = new Composite(grp2, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(2, false));
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.beastMaxNest);
				_maxNest = new Spinner(comp2, SWT.BORDER);
				.listener(_maxNest, SWT.Modify, {
					auto m = selection;
					if (!m) return;
					m.maxNest = _maxNest.getSelection();
					foreach (dlg; modEvent) dlg();
				});
				_maxNest.setMinimum(1);
				_maxNest.setMaximum(_prop.var.etc.beastMaxNest);
			}
			Spinner createSpinner(Composite parent, string name, int max, string hint,
					void delegate(int) edit, int delegate(int) cancel) {
				auto rgrp = new Group(parent, SWT.NONE);
				rgrp.setText(name);
				rgrp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				rgrp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				auto rcomp = new Composite(rgrp, SWT.NONE);
				rcomp.setLayout(new GridLayout(2, false));
				auto round = new Spinner(rcomp, SWT.BORDER);
				round.setMaximum(max);
				round.setMinimum(1);
				new SpinnerEdit(round, edit, edit, cancel);
				auto l_round = new Label(rcomp, SWT.NONE);
				l_round.setText(hint);
				return round;
			}
			Spinner createRoundC(Composite parent) {
				return createSpinner(parent, _prop.msgs.motionRound, _prop.var.etc.roundMax,
					.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.roundMax), &roundEnter, &roundCancel);
			}
			_abilityComp = createC();
			{
				auto vgrp = new Group(_abilityComp, SWT.NONE);
				vgrp.setText(_prop.msgs.motionEnhValue);
				vgrp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				auto vcomp = new Composite(vgrp, SWT.NONE);
				vcomp.setLayout(new GridLayout(2, false));
				_abiVal = new Scale(vcomp, SWT.NONE);
				auto gd_av = new GridData(GridData.FILL_HORIZONTAL);
				gd_av.horizontalSpan = 2;
				_abiVal.setLayoutData(gd_av);
				_abiVal.setMinimum(0);
				_abiVal.setMaximum(Motion.aValue_max - Motion.aValue_min);
				_abiVal.setPageIncrement(Motion.aValue_max / 2);
				_abiVal.addSelectionListener(new AbiValListener);
				auto l_min = new Label(vcomp, SWT.NONE);
				l_min.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING));
				l_min.setText(to!(string)(Motion.aValue_min));
				auto l_max = new Label(vcomp, SWT.NONE);
				l_max.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
				l_max.setText("+" ~ to!(string)(Motion.aValue_max));
				_abiRound = createRoundC(_abilityComp);
			}
			_roundComp = createC();
			{
				_rndRound = createRoundC(_roundComp);
			}
			_valueComp = createC();
			{
				auto grp = new Group(_valueComp, SWT.NONE);
				grp.setText(_prop.msgs.motionDamageType);
				grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayout(new GridLayout(1, false));
				auto dtl = new DamageTypeListener;
				foreach (typ; [DamageType.LEVEL_RATIO, DamageType.NORMAL, DamageType.MAX]) {
					auto radio = new Button(comp, SWT.RADIO);
					radio.setText(_prop.msgs.damageTypeName(typ));
					radio.addSelectionListener(dtl);
					_dmgTyp[typ] = radio;
				}
				_valValue = createSpinner(_valueComp, _prop.msgs.motionValue, _prop.var.etc.uValueMax,
					.tryFormat(_prop.msgs.rangeHint, Motion.uValue_min, _prop.var.etc.uValueMax), &valEnter, &valCancel);
			}
			_noneComp = createC();
			motionStack.topControl = _noneComp;
			_motions.addSelectionListener(new ParamPaneChange);
		}
		auto drag = new DragSource(_motions, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new MDragListener);
		auto drop = new DropTarget(_motions, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
		drop.setTransfer([XMLBytesTransfer.getInstance()]);
		drop.addDropListener(new MDropListener);

		addDisposeListener(new Dispose);
		_kdFilter = new KeyDownFilter();
		_comm.refMenu.add(&refMenu);
		_comm.refBeast.add(&refBeast);
		_comm.delBeast.add(&refBeast);
		_comm.refUndoMax.add(&refUndoMax);
		getDisplay().addFilter(SWT.KeyDown, _kdFilter);
	}
	void refEnabled() {
		auto m = selection();
		if (_maxNest) _maxNest.setEnabled(m && m.beast && 0 != m.beast.linkId);
	}
	@property
	void motions(Motion[] motions) {
		bool oldVan = hasVan;
		scope (exit) {
			if (oldVan != hasVan) {
				foreach (we; warningEvent) we();
			}
		}
		_motions.setRedraw(false);
		_undo.reset();
		foreach (i, m; motions) {
			appendMotion(m.dup, -1, false, false, false);
			if (0 == i) _motions.select(0);
		}
		refreshSels();
		foreach (dlg; modEvent) dlg();
		_motions.setRedraw(true);
		_comm.refreshToolBar();
	}
	@property
	Motion[] motions() {
		Motion[] r;
		r.length = _motions.getItemCount();
		foreach (i, itm; _motions.getItems()) {
			r[i] = cast(Motion) itm.getData();
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
				XMLtoCB(_prop, _comm.clipboard, m.toXML(null));
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) {
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					if (node.name == Motion.XML_NAME) {
						appendMotion(Motion.createFromNode(node, LATEST_VERSION));
						_motions.select(_motions.getItemCount() - 1);
						refreshSels();
						foreach (dlg; modEvent) dlg();
					} else {
						pasteBeast(node);
					}
					_comm.refreshToolBar();
				} catch {}
			}
		}
		override void del(SelectionEvent se) {
			removeMotion();
		}
		@property
		override bool canDoTCPD() {
			return _motions.isFocusControl();
		}
		@property
		override bool canDoT() {
			return _motions.getSelectionIndex() > 0;
		}
		@property
		override bool canDoC() {
			return canDoT;
		}
		@property
		override bool canDoP() {
			return CBisXML(_comm.clipboard);
		}
		@property
		override bool canDoD() {
			return canDoT;
		}
	}
	private void pasteBeast(ref XNode node) {
		auto m = selection;
		if (m && m.detail.use(MArg.BEAST)) {
			try {
				bool sameSc = _summ.id == node.attr("summId", false);
				bool topLevel = node.attr!bool("topLevel", false, false);
				if (node.name == BeastCard.XML_NAME_M) {
					auto bNode = node.child(BeastCard.XML_NAME, false);
					if (!bNode.valid) return;
					storeEdit(_motions.getSelectionIndex());
					if (m.beast) _comm.delBeast.call(m.beast);
					m.beast = null;
					auto bid = m.setBeastFromNode(bNode, LATEST_VERSION);
					if (bid && sameSc && topLevel && _prop.var.etc.linkCard) {
						m.beast = new BeastCard(1UL, "", "", "");
						m.beast.linkId = bid;
					}
					resetMaxNest(m);
					_beastImg.redraw();
					foreach (dlg; modEvent) dlg();
					refEnabled();
				}
			} catch (Exception e) {
				debugln(e);
			}
		}
	}
	private void resetMaxNest(Motion m) {
		if (!m.beast || 0 == m.beast.linkId) {
			m.maxNest = Motion.maxNest_init;
			_maxNest.setSelection(m.maxNest);
		}
	}
	private class BeastTCPD : TCPD {
		private bool __copy() {
			auto m = selection;
			if (m) {
				assert (m.detail.use(MArg.BEAST));
				if (m.beast) {
					auto node = XNode.create(BeastCard.XML_NAME_M);
					node.newAttr("summId", _summ.id);
					node.newAttr("paneId", "");
					node.newAttr("scenarioPath", nabs(_summ.scenarioPath));
					m.beast.toNode(node, null);
					XMLtoCB(_prop, _comm.clipboard, node.text);
					_comm.refreshToolBar();
					return true;
				}
			}
			return false;
		}
		override void cut(SelectionEvent se) {
			if (__copy()) {
				del(se);
			}
		}
		override void copy(SelectionEvent se) {
			__copy();
		}
		override void paste(SelectionEvent se) {
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					pasteBeast(node);
					_comm.refreshToolBar();
				} catch {}
			}
		}
		override void del(SelectionEvent se) {
			auto m = selection;
			if (m) {
				assert (m.detail.use(MArg.BEAST));
				if (m.beast) {
					storeEdit(_motions.getSelectionIndex());
					if (m.beast) _comm.delBeast.call(m.beast);
					m.beast = null;
					resetMaxNest(m);
					_beastImg.redraw();
					foreach (dlg; modEvent) dlg();
					_comm.refreshToolBar();
					refEnabled();
				}
			}
		}
		@property
		override bool canDoTCPD() {
			return _beastImg.isFocusControl();
		}
		@property
		override bool canDoT() {
			return selection !is null;
		}
		@property
		override bool canDoC() {
			return selection !is null;
		}
		@property
		override bool canDoP() {
			return CBisXML(_comm.clipboard);
		}
		@property
		override bool canDoD() {
			return selection !is null;
		}
	}
	void undo() {
		_undo.undo();
	}
	void redo() {
		_undo.redo();
	}

	bool openCWXPath(string path, bool shellActivate) {
		auto cate = cpcategory(path);
		if (cate == "motion") {
			auto index = cpindex(path);
			if (index >= _motions.getItemCount()) return false;
			_motions.select(index);
			refreshSels();
			path = cpbottom(path);
			.forceFocus(_motions, shellActivate);
			if (cpempty(path)) {
				_comm.refreshToolBar();
				return true;
			}
			auto m = selection;
			if (m.beast) {
				switch (cpcategory(path)) {
				case "beastcard":
					if (0 != cpindex(path)) return false;
					break;
				case "beastcard:id":
					if (m.beast.id != cpindex(path)) return false;
					break;
				default: return false;
				}
				path = cpbottom(path);
				if ("event" == cpcategory(path)) {
					auto w = openBeastEventWin(m.beast);
					if (!w) return false;
					_comm.refreshToolBar();
					return w.openCWXPath(path, shellActivate);
				} else {
					if (cphasattr(path, "opendialog")) {
						auto d = editBeast();
						if (!d) return false;
						return d.openCWXPath(path, shellActivate);
					}
					_comm.refreshToolBar();
					return true;
				}
			}
			return false;
		}
		return cpempty(path);
	}
}


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
import cwx.system;
import cwx.usecounter;

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
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.cardpane : CardDialog;

import std.algorithm : swap;
import std.array;
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
		protected Summary summ;

		private int _selected = -1, _selectedB = -1;

		this (MotionView v, Commons comm, Summary summ) { mixin(S_TRACE);
			_v = v;
			this.comm = comm;
			this.summ = summ;

			save(v);
		}
		private void save(MotionView v) { mixin(S_TRACE);
			if (!v || v.isDisposed()) return;
			_selected = v._motions.getSelectionIndex();
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected void udb(MotionView v) { mixin(S_TRACE);
			_selectedB = _selected;
			save(v);
		}
		protected void uda(MotionView v) { mixin(S_TRACE);
			scope (exit) comm.refreshToolBar();
			if (!v || v.isDisposed()) return;
			v._motions.select(_selectedB);
			v._motions.showSelection();
			v.refreshSels(true);
		}
		protected MotionView view() { mixin(S_TRACE);
			return _v;
		}
	}
	static class UndoEdit : MVUndo {
		private Motion _old;
		private ptrdiff_t _index;
		this (MotionView v, Commons comm, Summary summ, ptrdiff_t index) { mixin(S_TRACE);
			super (v, comm, summ);
			_old = v.motion(index).dup;
			_old.setUseCounter(summ.useCounter.sub);
			_index = index;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (!v || v.isDisposed()) return;
			auto old = _old;
			_old.removeUseCounter();
			_old = v.motion(_index).dup;
			_old.setUseCounter(summ.useCounter.sub);
			auto m = v.motion(_index);
			v.motion(_index, old, false);
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() { mixin(S_TRACE);
			_old.removeUseCounter();
		}
	}
	void storeEdit(ptrdiff_t index) { mixin(S_TRACE);
		_undo ~= new UndoEdit(this, _comm, _summ, index);
	}
	static class UndoSwap : MVUndo {
		private int _index1, _index2;
		this (MotionView v, Commons comm, Summary summ, int index1, int index2) { mixin(S_TRACE);
			super (v, comm, summ);
			_index1 = index1;
			_index2 = index2;
		}
		private void impl() { mixin(S_TRACE);
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
	void storeSwap(int index1, int index2) { mixin(S_TRACE);
		_undo ~= new UndoSwap(this, _comm, _summ, index1, index2);
	}
	static class UndoMove : MVUndo {
		private int _from, _to;
		this (MotionView v, Commons comm, Summary summ, int from, int to) { mixin(S_TRACE);
			super (v, comm, summ);
			_from = from;
			_to = to;
			if (_from < _to) _to--;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (!v || v.isDisposed()) return;
			int from = _from;
			int to = _to;
			auto m = v.motion(to);
			v.removeMotion(to, false, false, false);
			v.appendMotion(m, from, true, true, false);
			.swap(_from, _to);
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {}
	}
	void storeMove(int from, int to) { mixin(S_TRACE);
		_undo ~= new UndoMove(this, _comm, _summ, from, to);
	}
	static class UndoInsertDelete : MVUndo {
		private bool _insert;

		private int _index;

		private Motion _m = null;

		this (MotionView v, Commons comm, Summary summ, int index, bool insert) { mixin(S_TRACE);
			super (v, comm, summ);
			_insert = insert;
			_index = index;

			if (!insert) { mixin(S_TRACE);
				initUndoDelete(v);
			}
		}
		private void initUndoDelete(MotionView v) { mixin(S_TRACE);
			if (!v || v.isDisposed()) return;
			_m = v.motion(_index).dup;
			_m.setUseCounter(summ.useCounter.sub);
		}
		private void undoInsert() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_insert = false;
			initUndoDelete(v);
			if (!v || v.isDisposed()) return;
			v.removeMotion(_index, true, true, false);
		}
		void undoDelete() { mixin(S_TRACE);
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
		override void undo() { mixin(S_TRACE);
			if (_insert) { mixin(S_TRACE);
				undoInsert();
			} else { mixin(S_TRACE);
				undoDelete();
			}
		}
		override void redo() { mixin(S_TRACE);
			undo();
		}
		override void dispose() { mixin(S_TRACE);
			if (_m) { mixin(S_TRACE);
				_m.removeUseCounter();
			}
		}
	}
	void storeInsert(int index) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(this, _comm, _summ, index, true);
	}
	void storeDelete(int index) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(this, _comm, _summ, index, false);
	}

	string _id;

	int _readOnly = 0;
	Commons _comm;
	Props _prop;
	Summary _summ;
	UndoManager _undo;
	KeyDownFilter _kdFilter;

	Table _motions;
	Combo _beasts;
	BeastCard _selectedBeast = null;
	BeastCard[size_t] _beastTbl;
	IncSearch _beastIncSearch;
	void beastIncSearch() { mixin(S_TRACE);
		.forceFocus(_beasts, true);
		_beastIncSearch.startIncSearch();
	}
	Canvas _beastImg;
	Spinner _maxNest;

	string[MType] _descs;

	Table _motionElm;
	Button[DamageType] _dmgTyp;
	Scale _abiVal;
	Spinner _rndRound;
	Spinner _abiRound;
	Spinner _valValue;
	Button[DamageType] _skillPowerType;
	Spinner _skillPowerValue;
	Image[TypeInfo] _imgMsns;
	Image[Element] _imgElm;
	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	HashSet!EventWindow _beWin;
	EventWindow openBeastEventWin(BeastCard beast) { mixin(S_TRACE);
		if (!_summ) return null;
		if (0 != beast.linkId) { mixin(S_TRACE);
			auto b = _summ.beast(beast.linkId);
			if (!b) return null;
			return _comm.openUseEvents(_prop, _summ, b, true, false);
		}
		auto w = _comm.openUseEvents(_prop, _summ, beast, true, false);
		if (_beWin.contains(w)) return w;
		w.shell.addDisposeListener(new CloseRemover!EventWindow(_beWin, w));
		_beWin.add(w);
		return w;
	}
	void editBeastUseEvent() { mixin(S_TRACE);
		auto m = selection;
		if (!m || !m.detail.use(MArg.BEAST)) return;
		auto b = m.beast;
		if (!b) return;
		openBeastEventWin(b);
	}
	bool canEditBeast() { mixin(S_TRACE);
		if (!_summ) return false;
		auto m = selection;
		if (!m || !m.beast) return false;
		if (0 != m.beast.linkId && !_summ.beast(m.beast.linkId)) return false;
		return true;
	}

	Motion motion(size_t index) { mixin(S_TRACE);
		return cast(Motion)_motions.getItem(cast(int)index).getData();
	}
	void motion(size_t index, Motion m, bool store) { mixin(S_TRACE);
		if (store) storeEdit(index);
		auto itm = _motions.getItem(cast(int)index);
		auto o = cast(Motion) itm.getData();
		assert (o);
		if (_summ && _summ.scenarioPath != "" && o.beast) { mixin(S_TRACE);
			_comm.delBeast.call(o, o.beast);
		}
		itm.setData(m);
		if (index == _motions.getSelectionIndex()) { mixin(S_TRACE);
			refreshSels();
		}
		foreach (dlg; modEvent) dlg();
		foreach (dlg; warningEvent) dlg();
	}
	@property
	Motion selection() { mixin(S_TRACE);
		int i = _motions.getSelectionIndex();
		if (i >= 0) { mixin(S_TRACE);
			return motion(i);
		}
		return null;
	}
	class DamageTypeListener : SelectionAdapter {
		Button[DamageType] table;
		Spinner valueSpn = null;
		bool delegate() isEditable = null;
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto m = selection;
			if (!m) return;
			auto val = getRadioValue!(DamageType)(table);
			if (m.damageType != val) { mixin(S_TRACE);
				storeEdit(_motions.getSelectionIndex());
				m.damageType = val;
				valueSpn.setEnabled(val !is DamageType.MAX && (!isEditable || isEditable()));
				foreach (dlg; modEvent) dlg();
				foreach (we; warningEvent) we();
			}
		}
	}
	class AbiValListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto m = selection;
			if (!m) return;
			auto val = _abiVal.getSelection() - Motion.aValue_max;
			if (m.aValue != val) { mixin(S_TRACE);
				storeEdit(_motions.getSelectionIndex());
				m.aValue = val;
				foreach (dlg; modEvent) dlg();
			}
		}
	}

	void roundEnter(int value) { mixin(S_TRACE);
		auto m = selection;
		if (!m) return;
		if (m.round != value) { mixin(S_TRACE);
			storeEdit(_motions.getSelectionIndex());
			m.round = value;
			foreach (dlg; modEvent) dlg();
		}
	}
	int roundCancel(int oldVal) { mixin(S_TRACE);
		roundEnter(oldVal);
		return oldVal;
	}
	void valEnter(int value) { mixin(S_TRACE);
		auto m = selection;
		if (!m) return;
		if (m.uValue != value) { mixin(S_TRACE);
			storeEdit(_motions.getSelectionIndex());
			m.uValue = value;
			foreach (dlg; modEvent) dlg();
		}
	}
	int valCancel(int oldVal) { mixin(S_TRACE);
		valEnter(oldVal);
		return oldVal;
	}

	void createMT(MotionView v, ToolBar tbar, string group, MType type, bool delegate() isEnabled = null) { mixin(S_TRACE);
		string tt = _prop.msgs.motionName(type);
		_descs[type] = .tryFormat(_prop.msgs.msnDesc, group, tt);
		class MT {
			// FIXME: アクセス違反に対処
			MotionView v;
			MType type;
			void create() { mixin(S_TRACE);
				auto m = new Motion(type, Element.ALL);
				m.damageType = DamageType.LEVEL_RATIO;
				if (type == MType.GET_SKILL_POWER || type == MType.LOSE_SKILL_POWER) { mixin(S_TRACE);
					m.damageType = DamageType.MAX;
				}
				m.uValue = 1u;
				m.aValue = 0;
				m.round = v._prop.looks.motionRoundDefault;
				m.beast = null;
				v.appendMotion(m);
				v._motions.select(v._motions.getItemCount() - 1);
				v.refreshSels();
				v._motions.showSelection();
				foreach (dlg; v.modEvent) dlg();
			}
		}
		auto mt = new MT;
		mt.v = v;
		mt.type = type;
		auto text = tt;
		if (_prop.var.etc.showMotionDescription) { mixin(S_TRACE);
			text = .format("%s\v%s", tt, _prop.msgs.motionDesc(type));
		}
		createToolItem2(_comm, tbar, text, _prop.images.motion(type), &mt.create, () => !_readOnly && (!isEnabled || isEnabled()));
	}
	ptrdiff_t indexOf(Motion m) { mixin(S_TRACE);
		foreach (i, itm; _motions.getItems()) { mixin(S_TRACE);
			if (m is itm.getData()) return i;
		}
		return -1;
	}
	private CardDialog _beastDlg = null;
	void editBeastM() { mixin(S_TRACE);
		editBeast();
	}
	CardDialog editBeast() { mixin(S_TRACE);
		auto m = selection;
		if (m && m.detail.use(MArg.BEAST) && _summ) { mixin(S_TRACE);
			auto b = m.beast;
			if (b) { mixin(S_TRACE);
				if (0 != b.linkId) { mixin(S_TRACE);
					if (_readOnly) { mixin(S_TRACE);
						b = _summ.beast(b.linkId);
						if (!b) return null;
					} else { mixin(S_TRACE);
						auto b2 = _summ.beast(b.linkId);
						if (b2) { mixin(S_TRACE);
							_comm.openCWXPath(b2.cwxPath(true), false);
							return _comm.openBeastWin(false).edit(b2);
						}
					}
					return null;
				}
				if (_beastDlg) { mixin(S_TRACE);
					auto absDlg = cast(AbsDialog)_beastDlg;
					assert (absDlg !is null);
					absDlg.active();
				} else { mixin(S_TRACE);
					_beastDlg = new EffectCardDialog!(BeastCard)(_comm, _prop, getShell(), _summ, b, _readOnly != SWT.NONE);
					auto absDlg = cast(AbsDialog)_beastDlg;
					assert (absDlg !is null);
					absDlg.open();
					if (!_readOnly) { mixin(S_TRACE);
						absDlg.applyEvent ~= { mixin(S_TRACE);
							storeEdit(indexOf(m));
						};
						absDlg.appliedEvent ~= { mixin(S_TRACE);
							foreach (dlg; modEvent) dlg();
						};
					}
					absDlg.closeEvent ~= { mixin(S_TRACE);
						_beastDlg = null;
					};
				}
				return _beastDlg;
			}
		}
		return null;
	}
	class EditBeast : MouseAdapter, MouseMoveListener, KeyListener {
		private bool _inBounds = false;
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1) { mixin(S_TRACE);
				editBeast();
			}
		}
		override void mouseDown(MouseEvent e) { mixin(S_TRACE);
			auto ctrl = cast(Control) e.widget;
			ctrl.setFocus();
		}
		override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			auto rect = eventTreeMarkRect(e);
			if (rect && rect.contains(e.x, e.y)) { mixin(S_TRACE);
				editBeastUseEvent();
			}
		}
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			auto bounds = cardBounds(e);
			auto rect = eventTreeMarkRect(e);
			if (bounds) { mixin(S_TRACE);
				auto pane = cast(Canvas)e.widget;
				auto d = pane.getDisplay();
				auto curPos = pane.toControl(d.getCursorLocation());
				auto inBounds = bounds.contains(curPos);
				if (inBounds !is _inBounds) { mixin(S_TRACE);
					_inBounds = inBounds;
					pane.redraw(rect.x, rect.y, rect.width, rect.height, false);
				}
			}

			if (rect && rect.contains(e.x, e.y)) { mixin(S_TRACE);
				(cast(Control)e.widget).setCursor(e.widget.getDisplay().getSystemCursor(SWT.CURSOR_HAND));
			} else { mixin(S_TRACE);
				(cast(Control)e.widget).setCursor(null);
			}
		}
		Rectangle cardBounds(MouseEvent e) { mixin(S_TRACE);
			if (!_summ) return null;
			auto m = selection;
			if (!m || !m.detail.use(MArg.BEAST)) return null;
			auto b = m.beast;
			if (!b) return null;
			if (0 != b.linkId) { mixin(S_TRACE);
				b = _summ.beast(b.linkId);
				if (!b) return null;
			}
			auto cardSize = _prop.looks.cardSize;
			auto matPad = _prop.looks.cardInsets;
			int w = cardSize.width + matPad.e + matPad.w;
			int h = cardSize.height + matPad.n + matPad.s;
			auto pane = cast(Canvas)e.widget;
			auto rect = pane.getClientArea();
			int x = (rect.width - _prop.s(w)) / 2;
			int y = (rect.height - _prop.s(h)) / 2;
			return new Rectangle(x, y, _prop.s(w), _prop.s(h));
		}
		Rectangle eventTreeMarkRect(MouseEvent e) { mixin(S_TRACE);
			if (!_summ) return null;
			auto m = selection;
			if (!m || !m.detail.use(MArg.BEAST)) return null;
			auto b = m.beast;
			if (!b) return null;
			if (0 != b.linkId) { mixin(S_TRACE);
				b = _summ.beast(b.linkId);
				if (!b) return null;
			}
			auto cardSize = _prop.looks.cardSize;
			auto matPad = _prop.looks.cardInsets;
			int w = cardSize.width + matPad.e + matPad.w;
			int h = cardSize.height + matPad.n + matPad.s;
			auto pane = cast(Canvas)e.widget;
			auto rect = pane.getClientArea();
			int x = (rect.width - _prop.s(w)) / 2;
			int y = (rect.height - _prop.s(h)) / 2;
			return .eventTreeMarkRect(_prop, true, x, y, _summ, b);
		}
		override void keyReleased(KeyEvent e) {}
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (.isEnterKey(e.keyCode)) { mixin(S_TRACE);
				if (editBeast()) { mixin(S_TRACE);
					e.doit = false;
				}
			}
		}
	}
	void swap(int index1, int index2, bool store) { mixin(S_TRACE);
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
	void up() { mixin(S_TRACE);
		int index = _motions.getSelectionIndex();
		if (index > 0) { mixin(S_TRACE);
			storeSwap(index, index - 1);
			_motions.upItem(index);
			_motions.showSelection();
			_motions.redraw();
			_comm.refreshToolBar();
		}
	}
	void down() { mixin(S_TRACE);
		int index = _motions.getSelectionIndex();
		if (index >= 0 && index + 1 < _motions.getItemCount()) { mixin(S_TRACE);
			storeSwap(index, index + 1);
			_motions.downItem(index);
			_motions.showSelection();
			_motions.redraw();
			_comm.refreshToolBar();
		}
	}
	void removeMotion() { mixin(S_TRACE);
		removeMotion(-1, true, true, true);
	}
	void removeMotion(int index, bool callEvent, bool callMod, bool store) { mixin(S_TRACE);
		bool oldVan = hasVan;
		scope (exit) {
			if (callEvent && oldVan != hasVan) {
				foreach (we; warningEvent) we();
			}
			_comm.refreshToolBar();
		}
		if (-1 == index) { mixin(S_TRACE);
			index = _motions.getSelectionIndex();
		}
		if (index >= 0) { mixin(S_TRACE);
			if (store) storeDelete(index);
			auto m = cast(Motion) _motions.getItem(index).getData();
			assert (m);
			if (_summ && _summ.scenarioPath != "" && m.beast) { mixin(S_TRACE);
				_comm.delBeast.call(m, m.beast);
			}
			_motions.remove(index);
			if (index >= _motions.getItemCount()) index--;
			if (index >= 0) { mixin(S_TRACE);
				_motions.select(index);
			}
			_oldIndex = -1;
			_motions.redraw();
			refreshSels();
			if (callMod) { mixin(S_TRACE);
				foreach (dlg; modEvent) dlg();
			}
		}
	}
	void appendMotion(Motion motion, int index = -1, bool callEvent = true, bool callMod = false, bool store = true) { mixin(S_TRACE);
		bool oldVan;
		if (callEvent) { mixin(S_TRACE);
			oldVan = hasVan;
		}
		scope (exit) {
			if (callEvent && oldVan != hasVan) {
				foreach (we; warningEvent) we();
			}
			_comm.refreshToolBar();
		}
		TableItem itm;
		if (store) { mixin(S_TRACE);
			storeInsert(0 <= index ? index : _motions.getItemCount());
		}
		if (0 <= index) { mixin(S_TRACE);
			itm = new TableItem(_motions, SWT.NONE, index);
		} else { mixin(S_TRACE);
			itm = new TableItem(_motions, SWT.NONE);
		}
		itm.setImage(_prop.images.motion(motion.type));
		itm.setText(_descs[motion.type]);
		itm.setData(motion);
		if (callMod) { mixin(S_TRACE);
			foreach (dlg; modEvent) dlg();
		}
	}
	Composite _editComp;
	Composite _noneComp;
	Composite _valueComp;
	Composite _roundComp;
	Composite _abilityComp;
	Composite _summonComp;
	Composite _skillPowerComp;
	int _oldIndex = -1;
	void refreshSels(bool force = false) { mixin(S_TRACE);
		scope(exit) refEnabled();
		auto sels = _motions.getSelection();
		auto stack = cast(StackLayout) _editComp.getLayout();
		_motionElm.setEnabled(!_readOnly && sels.length > 0);
		if (sels.length == 0) { mixin(S_TRACE);
			_motionElm.deselectAll();
			stack.topControl = _noneComp;
			_editComp.layout();
			_oldIndex = -1;
		} else if (force || _oldIndex != _motions.getSelectionIndex()) { mixin(S_TRACE);
			_oldIndex = _motions.getSelectionIndex();
			auto m = cast(Motion) _motions.getItem(_oldIndex).getData();
			foreach (i, itm; _motionElm.getItems()) { mixin(S_TRACE);
				if ((cast(Element) (cast(Integer) itm.getData()).intValue()) == m.element) { mixin(S_TRACE);
					_motionElm.select(cast(int)i);
					break;
				}
			}
			auto d = m.detail;
			if (m.type == MType.GET_SKILL_POWER || m.type == MType.LOSE_SKILL_POWER) { mixin(S_TRACE);
				foreach (typ, radio; _skillPowerType) { mixin(S_TRACE);
					_skillPowerType[typ].setSelection((typ == m.damageType));
				}
				_skillPowerValue.setSelection(m.uValue);
				if (stack.topControl !is _skillPowerComp) { mixin(S_TRACE);
					stack.topControl = _skillPowerComp;
					_editComp.layout();
				}
			} else if (d.use(MArg.BEAST)) { mixin(S_TRACE);
				_beasts.select(0);
				_selectedBeast = null;
				_maxNest.setSelection(m.maxNest);
				_beastImg.redraw();
				if (stack.topControl !is _summonComp) { mixin(S_TRACE);
					stack.topControl = _summonComp;
					_editComp.layout();
				}
			} else if (d.use(MArg.ROUND) && d.use(MArg.A_VALUE)) { mixin(S_TRACE);
				_abiVal.setSelection(m.aValue + Motion.aValue_max);
				_abiRound.setSelection(m.round);
				if (stack.topControl !is _abilityComp) { mixin(S_TRACE);
					stack.topControl = _abilityComp;
					_editComp.layout();
				}
			} else if (d.use(MArg.ROUND)) { mixin(S_TRACE);
				_rndRound.setSelection(m.round);
				if (stack.topControl !is _roundComp) { mixin(S_TRACE);
					stack.topControl = _roundComp;
					_editComp.layout();
				}
			} else if (d.use(MArg.U_VALUE)) { mixin(S_TRACE);
				foreach (typ, radio; _dmgTyp) { mixin(S_TRACE);
					_dmgTyp[typ].setSelection((typ == m.damageType));
				}
				_valValue.setSelection(m.uValue);
				if (stack.topControl !is _valueComp) { mixin(S_TRACE);
					stack.topControl = _valueComp;
					_editComp.layout();
				}
			} else { mixin(S_TRACE);
				if (stack.topControl !is _noneComp) { mixin(S_TRACE);
					stack.topControl = _noneComp;
					_editComp.layout();
				}
			}
		}
		_comm.refreshToolBar();
	}
	class ParamPaneChange : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			refreshSels();
		}
	}
	bool canSetBeast() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_selectedBeast) return true;
		int mi = _motions.getSelectionIndex();
		if (-1 == mi) return false;
		auto sb = cast(Motion) _motions.getItem(mi).getData();
		// 召喚獣無しを設定する場合
		return sb.beast !is null;
	}
	class SetBeast : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto b = _selectedBeast;
			int mi = _motions.getSelectionIndex();
			assert (-1 != mi);
			auto sb = cast(Motion)_motions.getItem(mi).getData();
			if (b) { mixin(S_TRACE);
				if (!sb.beast && !b) return;
				storeEdit(mi);
				if (_summ && _summ.scenarioPath != "" && sb.beast) _comm.delBeast.call(sb, sb.beast);
				if (_prop.var.etc.linkCard || !_summ || !_summ.legacy) { mixin(S_TRACE);
					sb.beast = new BeastCard(1UL, "", [], "");
					sb.beast.linkId = b.id;
				} else { mixin(S_TRACE);
					sb.beast = b;
				}
			} else { mixin(S_TRACE);
				if (!sb.beast) return;
				storeEdit(mi);
				if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
					_comm.delBeast.call(sb, sb.beast);
				}
				sb.beast = null;
			}
			resetMaxNest(sb);
			_beastImg.redraw();
			foreach (dlg; modEvent) dlg();
			refEnabled();
			_comm.refreshToolBar();
		}
	}
	void removeRef() { mixin(S_TRACE);
		if (!_summ) return;
		auto m = selection;
		if (!m || !m.beast || 0 == m.beast.linkId) return;
		auto targ = _summ.beast(m.beast.linkId);
		if (!targ) return;
		storeEdit(_motions.getSelectionIndex());
		auto id = m.beast.id;
		m.beast.deepCopy(targ);
		m.beast.id = id;
		m.beast.linkId = 0;

		resetMaxNest(m);
		_beastImg.redraw();
		foreach (dlg; modEvent) dlg();
		refEnabled();
	}
	void updateBeastToolTip() { mixin(S_TRACE);
		if (!_summ || !selection) return;
		auto beast = selection.beast;
		string toolTip = "";
		if (beast && beast.linkId) { mixin(S_TRACE);
			auto id = beast.linkId;
			auto c = _summ.beast(id);
			if (c) { mixin(S_TRACE);
				toolTip = .tryFormat(_prop.msgs.cardIsReference, id, c.name);
			} else { mixin(S_TRACE);
				toolTip = .tryFormat(_prop.msgs.referencedCardIsNotFound, id);
			}
		}
		if (toolTip != _beastImg.getToolTipText) { mixin(S_TRACE);
			_beastImg.setToolTipText(toolTip);
		}
	}
	class PaintBeast : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			if (!_summ) return;
			auto beast = selection.beast;
			if (beast) { mixin(S_TRACE);
				auto data = cardImage!(BeastCard)(_prop, summSkin, beast, _summ.scenarioPath, _summ.dataVersion, null, (id) => _summ.beast(id), true, false);
				if (1024 < _prop.s(1024)) { mixin(S_TRACE);
					data = data.scaledTo(_prop.s(data.width), _prop.s(data.height));
				}
 				auto img = new Image(Display.getCurrent(), data);
				auto pane = cast(Canvas)e.widget;
				auto rect = pane.getClientArea();
				int x = (rect.width - data.width) / 2;
				int y = (rect.height - data.height) / 2;
				e.gc.drawImage(img, x, y);
				.putEventTree(pane, e.gc, _prop, _summ, true, beast, new Rectangle(x, y, data.width, data.height));
				img.dispose();
				if (pane.isFocusControl()) { mixin(S_TRACE);
					e.gc.setBackground(Display.getCurrent().getSystemColor(SWT.COLOR_LIST_SELECTION));
					e.gc.setAlpha(64);
					e.gc.fillRectangle(x, y, data.width, data.height);
					e.gc.setAlpha(255);
				}
			}
			updateBeastToolTip();
		}
	}
	class MDropListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = _readOnly ? DND.DROP_NONE : DND.DROP_MOVE;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = _readOnly ? DND.DROP_NONE : DND.DROP_MOVE;
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				if (node.name != Motion.XML_NAME) return;
				scope p = (cast(DropTarget) e.getSource()).getControl().toControl(e.x, e.y);
				auto t = _motions.getItem(p);
				int index = t ? _motions.indexOf(t) : _motions.getItemCount();
				auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
				auto m = Motion.createFromNode(node, ver);
				if (_id == node.attr("paneId", false)) { mixin(S_TRACE);
					if (-1 != _dragIndex) { mixin(S_TRACE);
						storeMove(_dragIndex, index);
						appendMotion(m, index, true, false, false);
					} else { mixin(S_TRACE);
						appendMotion(m, index, true, false, true);
					}
					_motions.select(index);
					_motions.showSelection();
					refreshSels();
					e.detail = DND.DROP_MOVE;
				} else { mixin(S_TRACE);
					appendMotion(m, index, true, false, true);
				}
				foreach (dlg; modEvent) dlg();
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	private int _dragIndex = -1;
	class MDragListener : DragSourceAdapter {
		private TableItem _itm;
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto c = cast(Table) (cast(DragSource) e.getSource()).getControl();
				int index = c.getSelectionIndex();
				if (index >= 0) { mixin(S_TRACE);
					auto m = cast(Motion) c.getItem(index).getData();
					_dragIndex = index;
					auto node = m.toNode(new XMLOption(_prop.sys, LATEST_VERSION));
					node.newAttr("paneId", _id);
					e.data = bytesFromXML(node.text);
					_itm = c.getItem(index);
				}
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			_dragIndex = -1;
			if (!_readOnly && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
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
	bool hasVan() { mixin(S_TRACE);
		foreach (itm; _motions.getItems()) { mixin(S_TRACE);
			auto m = cast(Motion) itm.getData();
			assert (m);
			if ((m.element !is Element.MIRACLE) && (m.type is MType.VANISH_TARGET)) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	class SelElement : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto m = selection;
			if (m) { mixin(S_TRACE);
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
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refMenu.remove(&refMenu);
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.refBeast.remove(&refBeast);
				_comm.delBeast.remove(&delBeast);
				_comm.refSkin.remove(&_beastImg.redraw);
			}
			_comm.refUndoMax.remove(&refUndoMax);
			_comm.refCardImageStatus.remove(&_beastImg.redraw);
			_comm.refDataVersion.remove(&refEnabled);
			getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
			foreach (w; _beWin.toArray()) { mixin(S_TRACE);
				_comm.close(w.shell);
			}
		}
	}
	class KeyDownFilter : Listener {
		this () { mixin(S_TRACE);
			refMenu(MenuID.Undo);
			refMenu(MenuID.Redo);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!e.doit) return;
			auto c = cast(Control)e.widget;
			if (!c || c.isDisposed() || c.getShell() !is getShell()) return;
			if (!isDescendant(this.outer, c)) return;
			if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
				_undo.undo();
				e.doit = false;
			} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
				_undo.redo();
				e.doit = false;
			}
		}
	}
	private int _undoAcc;
	private int _redoAcc;
	void refMenu(MenuID id) { mixin(S_TRACE);
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
	}
	void refBeast(BeastCard beast) { mixin(S_TRACE);
		refBeasts();
	}
	void delBeast(CWXPath owner, BeastCard beast) { mixin(S_TRACE);
		refBeasts();
	}
	void refBeasts() { mixin(S_TRACE);
		if (!_summ) return;
		setRedraw(false);
		scope (exit) setRedraw(true);
		ulong selId = 0;
		auto sel = _selectedBeast;
		if (sel) selId = sel.id;
		_beasts.removeAll();
		typeof(_beastTbl) b;
		_beastTbl = b;
		_beasts.add(_prop.msgs.defaultSelection(_prop.msgs.beastNone));
		_beastTbl[0] = null;
		size_t i = 0;
		bool has = false;
		foreach (c; _summ.beasts) { mixin(S_TRACE);
			if (!has && selId == c.id) { mixin(S_TRACE);
				has = true;
			}
			if (!_beastIncSearch.match(c.name)) continue;
			_beastTbl[i + 1] = c;
			_beasts.add(to!string(c.id) ~ "." ~ c.name);
			if (c.id == selId) { mixin(S_TRACE);
				_beasts.select(_beasts.getItemCount() - 1);
				_selectedBeast = c;
			}
			i++;
		}
		if (!has) { mixin(S_TRACE);
			_beasts.select(0);
			_selectedBeast = null;
		}
		refEnabled();
	}
	void openBeastCardView() { mixin(S_TRACE);
		if (!_selectedBeast) return;
		try { mixin(S_TRACE);
			_comm.openCWXPath(cpaddattr(_selectedBeast.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	bool _refUndo = false;
	void refUndoMax() { mixin(S_TRACE);
		if (!_refUndo) return;
		_undo.max = _prop.var.etc.undoMaxEtc;
	}
public:
	this (Commons comm, Props prop, Summary summ, Composite parent, int style, UndoManager undo = null) { mixin(S_TRACE);
		super(parent, SWT.NONE);
		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());
		_readOnly = style & SWT.READ_ONLY;
		_comm = comm;
		_prop = prop;
		_summ = summ;
		if (_readOnly || !_summ || _summ.scenarioPath == "") { mixin(S_TRACE);
			_summSkin = findSkin(_comm, _prop, _summ);
		}
		_refUndo = undo is null;
		_undo = undo ? undo : new UndoManager(_prop.var.etc.undoMaxEtc);
		_beWin = new typeof(_beWin);

		setLayout(zeroMarginGridLayout(3, false));
		{ mixin(S_TRACE);
			auto mtabf = new CTabFolder(this, SWT.FLAT | SWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = 0;
			gd.horizontalSpan = 3;
			mtabf.setLayoutData(gd);
			ToolBar createBar(string name) { mixin(S_TRACE);
				auto bar = new ToolBar(mtabf, SWT.FLAT);
				_comm.put(bar);
				bar.setEnabled(!_readOnly);
				bar.addListener(SWT.Traverse, new class Listener {
					override void handleEvent(Event e) { e.doit = true; }
				});
				bar.addListener(SWT.KeyDown, new class Listener {
					override void handleEvent(Event e) { e.doit = true; }
				});
				auto tab = new CTabItem(mtabf, SWT.NONE);
				tab.setControl(bar);
				tab.setText(name);
				.setupToolTips(bar, _prop);
				return bar;
			}
			auto vitalityBar = createBar(_prop.msgs.msnGroupVitality);
			auto physicalBar = createBar(_prop.msgs.msnGroupPhysical);
			auto skillBar = createBar(_prop.msgs.msnGroupSkill);
			auto mentalBar = createBar(_prop.msgs.msnGroupMental);
			auto magicBar = createBar(_prop.msgs.msnGroupMagic);
			auto enhanceBar = createBar(_prop.msgs.msnGroupEnhance);
			auto vanishBar = createBar(_prop.msgs.msnGroupVanish);
			auto cardBar = createBar(_prop.msgs.msnGroupCard);
			auto beastBar = createBar(_prop.msgs.msnGroupBeast);
			auto etcBar = createBar(_prop.msgs.msnGroupEtc);

			void addDefItems(ToolBar bar) { mixin(S_TRACE);
				createToolItem2(_comm, bar, _prop.msgs.msnDelete, _prop.images.msnDelete, &removeMotion, () => _motions.getSelectionIndex() != -1);
				new ToolItem(bar, SWT.SEPARATOR);
				createToolItem(_comm, bar, MenuID.Up, &up, () => _motions.getSelectionIndex() != -1 && 0 < _motions.getSelectionIndex());
				createToolItem(_comm, bar, MenuID.Down, &down, () => _motions.getSelectionIndex() != -1 && _motions.getSelectionIndex() + 1 < _motions.getItemCount());
				new ToolItem(bar, SWT.SEPARATOR);
			}
			void createBars(bool init) { mixin(S_TRACE);
				string g = _prop.msgs.msnGroupVitality;
				foreach (itm; vitalityBar.getItems()) itm.dispose();
				addDefItems(vitalityBar);
				createMT(this, vitalityBar, g, MType.HEAL);
				createMT(this, vitalityBar, g, MType.DAMAGE);
				createMT(this, vitalityBar, g, MType.ABSORB);

				g = _prop.msgs.msnGroupPhysical;
				foreach (itm; physicalBar.getItems()) itm.dispose();
				addDefItems(physicalBar);
				createMT(this, physicalBar, g, MType.PARALYZE);
				createMT(this, physicalBar, g, MType.DIS_PARALYZE);
				createMT(this, physicalBar, g, MType.POISON);
				createMT(this, physicalBar, g, MType.DIS_POISON);

				g = _prop.msgs.msnGroupSkill;
				foreach (itm; skillBar.getItems()) itm.dispose();
				addDefItems(skillBar);
				createMT(this, skillBar, g, MType.GET_SKILL_POWER);
				createMT(this, skillBar, g, MType.LOSE_SKILL_POWER);

				g = _prop.msgs.msnGroupMental;
				foreach (itm; mentalBar.getItems()) itm.dispose();
				addDefItems(mentalBar);
				createMT(this, mentalBar, g, MType.SLEEP);
				createMT(this, mentalBar, g, MType.CONFUSE);
				createMT(this, mentalBar, g, MType.OVERHEAT);
				createMT(this, mentalBar, g, MType.BRAVE);
				createMT(this, mentalBar, g, MType.PANIC);
				createMT(this, mentalBar, g, MType.NORMAL);

				g = _prop.msgs.msnGroupMagic;
				foreach (itm; magicBar.getItems()) itm.dispose();
				addDefItems(magicBar);
				createMT(this, magicBar, g, MType.BIND);
				createMT(this, magicBar, g, MType.DIS_BIND);
				createMT(this, magicBar, g, MType.SILENCE);
				createMT(this, magicBar, g, MType.DIS_SILENCE);
				createMT(this, magicBar, g, MType.FACE_UP);
				createMT(this, magicBar, g, MType.FACE_DOWN);
				createMT(this, magicBar, g, MType.ANTI_MAGIC);
				createMT(this, magicBar, g, MType.DIS_ANTI_MAGIC);

				g = _prop.msgs.msnGroupEnhance;
				foreach (itm; enhanceBar.getItems()) itm.dispose();
				addDefItems(enhanceBar);
				createMT(this, enhanceBar, g, MType.ENHANCE_ACTION);
				createMT(this, enhanceBar, g, MType.ENHANCE_AVOID);
				createMT(this, enhanceBar, g, MType.ENHANCE_DEFENSE);
				createMT(this, enhanceBar, g, MType.ENHANCE_RESIST);

				g = _prop.msgs.msnGroupVanish;
				foreach (itm; vanishBar.getItems()) itm.dispose();
				addDefItems(vanishBar);
				createMT(this, vanishBar, g, MType.VANISH_TARGET);
				createMT(this, vanishBar, g, MType.VANISH_CARD);
				createMT(this, vanishBar, g, MType.VANISH_BEAST);

				g = _prop.msgs.msnGroupCard;
				foreach (itm; cardBar.getItems()) itm.dispose();
				addDefItems(cardBar);
				createMT(this, cardBar, g, MType.DEAL_ATTACK_CARD);
				createMT(this, cardBar, g, MType.DEAL_POWERFUL_ATTACK_CARD);
				createMT(this, cardBar, g, MType.DEAL_CRITICAL_ATTACK_CARD);
				createMT(this, cardBar, g, MType.DEAL_FEINT_CARD);
				createMT(this, cardBar, g, MType.DEAL_DEFENSE_CARD);
				createMT(this, cardBar, g, MType.DEAL_DISTANCE_CARD);
				createMT(this, cardBar, g, MType.DEAL_CONFUSE_CARD);
				createMT(this, cardBar, g, MType.DEAL_SKILL_CARD);
				createMT(this, cardBar, g, MType.CANCEL_ACTION); // CardWirth 1.50

				g = _prop.msgs.msnGroupBeast;
				foreach (itm; beastBar.getItems()) itm.dispose();
				addDefItems(beastBar);
				createMT(this, beastBar, g, MType.SUMMON_BEAST);

				g = _prop.msgs.msnGroupEtc;
				foreach (itm; etcBar.getItems()) itm.dispose();
				addDefItems(etcBar);
				createMT(this, etcBar, g, MType.NO_EFFECT, () => !_summ || !_summ.legacy);

				if (!init) _comm.refreshToolBar();
			}

			createBars(true);
			mtabf.setSelection(0);

			auto createBars2 = () => createBars(false);
			_comm.refUpdateMotionBarStyle.add(createBars2);
			.listener(mtabf, SWT.Dispose, { mixin(S_TRACE);
				_comm.refUpdateMotionBarStyle.remove(createBars2);
			});
		}
		{ mixin(S_TRACE);
			_motions = .rangeSelectableTable(this, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL | SWT.FULL_SELECTION);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.motionsWidth;
			_motions.setLayoutData(gd);
			_motions.setHeaderVisible(true);
			auto menu = new Menu(_motions);
			if (!_readOnly) { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.Undo, &this.undo, () => !_readOnly && _undo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &this.redo, () => !_readOnly && _undo.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Up, &up, () => !_readOnly && _motions.getSelectionIndex() != -1 && 0 < _motions.getSelectionIndex());
				createMenuItem(_comm, menu, MenuID.Down, &down, () => !_readOnly && _motions.getSelectionIndex() != -1 && _motions.getSelectionIndex() + 1 < _motions.getItemCount());
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new MotionTCPD, true, true, true, true, true);
			} else { mixin(S_TRACE);
				appendMenuTCPD(_comm, menu, new MotionTCPD, false, true, false, false, false);
			}
			_motions.setMenu(menu);
			auto col = new FullTableColumn(_motions, SWT.NONE);
			col.column.setText(_prop.msgs.motionKind);
		}
		{ mixin(S_TRACE);
			_motionElm = .rangeSelectableTable(this, SWT.BORDER | SWT.SINGLE | SWT.NO_SCROLL | SWT.FULL_SELECTION);
			_motionElm.setHeaderVisible(true);
			_motionElm.addSelectionListener(new SelElement);
			_motionElm.setEnabled(false);
			auto col = new FullTableColumn(_motionElm, SWT.NONE);
			col.column.setText(_prop.msgs.motionElement);
			string[] toolTip;
			foreach (i, elm; [Element.ALL, Element.HEALTH, Element.MIND,
					Element.MIRACLE, Element.MAGIC, Element.FIRE, Element.ICE]) { mixin(S_TRACE);
				auto itm = new TableItem(_motionElm, SWT.NONE);
				itm.setImage(_prop.images.element(elm));
				itm.setText(_prop.msgs.elementName(elm));
				itm.setData(new Integer(elm));
				toolTip ~= _prop.msgs.elementDesc(elm);
			}
			.listener(_motionElm, SWT.MouseMove, (Event e) { mixin(S_TRACE);
				auto itm = _motionElm.getItem(new Point(e.x, e.y));
				if (itm) { mixin(S_TRACE);
					_motionElm.setToolTipText(.replace(toolTip[_motionElm.indexOf(itm)], "&", "&&"));
				} else { mixin(S_TRACE);
					_motionElm.setToolTipText(null);
				}
			});
			auto gd = new GridData(GridData.FILL_VERTICAL);
			gd.widthHint = _motionElm.computeSize(SWT.DEFAULT, SWT.DEFAULT).x.ppis;
			_motionElm.setLayoutData(gd);
			auto menu = new Menu(_motionElm);
			createMenuItem(_comm, menu, MenuID.Undo, &this.undo, () => !_readOnly && _undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, &this.redo, () => !_readOnly && _undo.canRedo);
			_motionElm.setMenu(menu);
		}
		{ mixin(S_TRACE);
			_editComp = new Composite(this, SWT.NONE);
			_editComp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			auto motionStack = new StackLayout;
			_editComp.setLayout(motionStack);
			Composite createC() { mixin(S_TRACE);
				auto c = new Composite(_editComp, SWT.NONE);
				c.setLayout(zeroMarginGridLayout(1, false));
				return c;
			}
			_summonComp = createC();
			{ mixin(S_TRACE);
				auto grp = new Group(_summonComp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(normalGridLayout(2, false));
				grp.setText(_prop.msgs.motionBeast);
				_beasts = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				_beasts.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_beasts.setEnabled(!_readOnly && _summ && _summ.scenarioPath != "");
				_beasts.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_beasts.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
						auto index = _beasts.getSelectionIndex();
						_selectedBeast = -1 != index ? _beastTbl[index] : null;
						_comm.refreshToolBar();
					}
				});
				_beastIncSearch = new IncSearch(_comm, _beasts);
				_beastIncSearch.modEvent ~= &refBeasts;
				{ mixin(S_TRACE);
					auto menu = new Menu(_beasts.getShell(), SWT.POP_UP);
					createMenuItem(_comm, menu, MenuID.IncSearch, &beastIncSearch, () => !_readOnly && 1 < _beasts.getItemCount());
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.OpenAtCardView, &openBeastCardView, () => !_readOnly && 0 < _beasts.getSelectionIndex());
					_beasts.setMenu(menu);
				}
				refBeasts();

				auto setBeast = new Button(grp, SWT.PUSH);
				setBeast.setEnabled(!_readOnly);
				setBeast.setImage(_prop.images.setBeast);
				setBeast.setToolTipText(_prop.msgs.setBeast);
				setBeast.addSelectionListener(new SetBeast);
				_comm.put(setBeast, &canSetBeast);
				_beastImg = new Canvas(grp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
				_beastImg.addListener(SWT.Traverse, new class Listener {
					override void handleEvent(Event e) { mixin(S_TRACE);
						e.doit = true;
					}
				});
				_beastImg.addListener(SWT.KeyDown, new class Listener {
					override void handleEvent(Event e) { mixin(S_TRACE);
						e.doit = true;
					}
				});
				_beastImg.addListener(SWT.MouseDown, new class Listener {
					override void handleEvent(Event e) { mixin(S_TRACE);
						if (e.button == 1) (cast(Canvas)e.widget).setFocus();
					}
				});
				_beastImg.addListener(SWT.FocusOut, new class Listener {
					override void handleEvent(Event e) { mixin(S_TRACE);
						(cast(Canvas)e.widget).redraw();
					}
				});
				_beastImg.addListener(SWT.FocusIn, new class Listener {
					override void handleEvent(Event e) { mixin(S_TRACE);
						(cast(Canvas)e.widget).redraw();
					}
				});
				.listener(_beastImg, SWT.MouseMove, &updateBeastToolTip);
				.listener(_beastImg, SWT.MouseEnter, &updateBeastToolTip);
				.listener(_beastImg, SWT.MouseExit, &updateBeastToolTip);
				_beastImg.addPaintListener(new PaintBeast);
				_comm.refImageScale.add(&_beastImg.redraw);
				.listener(_beastImg, SWT.Dispose, { mixin(S_TRACE);
					_comm.refImageScale.remove(&_beastImg.redraw);
				});
				auto eb = new EditBeast;
				_beastImg.addMouseListener(eb);
				_beastImg.addMouseMoveListener(eb);
				_beastImg.addKeyListener(eb);
				auto menu = new Menu(_beastImg);
				if (_readOnly) { mixin(S_TRACE);
					createMenuItem(_comm, menu, MenuID.ShowProp, &editBeastM, &canEditBeast);
				} else { mixin(S_TRACE);
					createMenuItem(_comm, menu, MenuID.EditProp, &editBeastM, &canEditBeast);
				}
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.EditEventAtTimeOfUsing, &editBeastUseEvent, &canEditBeast);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.RemoveRef, &removeRef, () => !_readOnly && selection && selection.beast && 0 != selection.beast.linkId && _summ && _summ.beast(selection.beast.linkId));
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Undo, &this.undo, () => !_readOnly && _undo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &this.redo, () => !_readOnly && _undo.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new BeastTCPD, true, true, true, true, false);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.SelectConnectedResource, &selectConnectedResource, &canSelectConnectedResource);
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
				initSpinner(_maxNest);
				.listener(_maxNest, SWT.Modify, { mixin(S_TRACE);
					auto m = selection;
					if (!m) return;
					m.maxNest = _maxNest.getSelection();
					foreach (dlg; modEvent) dlg();
				});
				_maxNest.setMinimum(1);
				_maxNest.setMaximum(_prop.var.etc.beastMaxNest);

				if (!_readOnly && _summ && _summ.scenarioPath != "") { mixin(S_TRACE);
					auto drop = new DropTarget(_beastImg, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
					drop.setTransfer([XMLBytesTransfer.getInstance()]);
					drop.addDropListener(new BeastDropListener);
				}
				auto drag = new DragSource(_beastImg, DND.DROP_DEFAULT | DND.DROP_COPY);
				drag.setTransfer([XMLBytesTransfer.getInstance()]);
				drag.addDragListener(new BeastDragListener);
			}
			Spinner createSpinner(Composite parent, string name, int max, string hint,
					void delegate(int) edit, int delegate(int) cancel) { mixin(S_TRACE);
				auto rgrp = new Group(parent, SWT.NONE);
				rgrp.setText(name);
				rgrp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				rgrp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				auto rcomp = new Composite(rgrp, SWT.NONE);
				rcomp.setLayout(normalGridLayout(2, false));
				auto round = new Spinner(rcomp, SWT.BORDER | _readOnly);
				initSpinner(round);
				round.setMaximum(max);
				round.setMinimum(1);
				new SpinnerEdit(round, edit, edit, cancel);
				auto l_round = new Label(rcomp, SWT.NONE);
				l_round.setText(hint);
				return round;
			}
			Spinner createRoundC(Composite parent) { mixin(S_TRACE);
				return createSpinner(parent, _prop.msgs.motionRound, _prop.var.etc.roundMax,
					.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.roundMax), &roundEnter, &roundCancel);
			}
			_abilityComp = createC();
			{ mixin(S_TRACE);
				auto vgrp = new Group(_abilityComp, SWT.NONE);
				vgrp.setText(_prop.msgs.motionEnhValue);
				vgrp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				auto vcomp = new Composite(vgrp, SWT.NONE);
				vcomp.setLayout(normalGridLayout(2, false));
				_abiVal = new Scale(vcomp, SWT.NONE);
				_abiVal.setEnabled(!_readOnly);
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
			{ mixin(S_TRACE);
				_rndRound = createRoundC(_roundComp);
			}
			_valueComp = createC();
			{ mixin(S_TRACE);
				auto grp = new Group(_valueComp, SWT.NONE);
				grp.setText(_prop.msgs.motionDamageType);
				grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayout(normalGridLayout(1, false));
				auto dtl = new DamageTypeListener;
				foreach (typ; [DamageType.LEVEL_RATIO, DamageType.NORMAL, DamageType.MAX]) { mixin(S_TRACE);
					auto radio = new Button(comp, SWT.RADIO);
					radio.setEnabled(!_readOnly);
					radio.setText(_prop.msgs.damageTypeName(typ));
					radio.addSelectionListener(dtl);
					_dmgTyp[typ] = radio;
				}
				_valValue = createSpinner(_valueComp, _prop.msgs.motionValue, _prop.var.etc.uValueMax,
					.tryFormat(_prop.msgs.rangeHint, Motion.uValue_min, _prop.var.etc.uValueMax), &valEnter, &valCancel);
				dtl.table = _dmgTyp;
				dtl.valueSpn = _valValue;
			}
			_skillPowerComp = createC();
			{ mixin(S_TRACE);
				auto grp = new Group(_skillPowerComp, SWT.NONE);
				grp.setText(_prop.msgs.motionDamageType);
				grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayout(normalGridLayout(1, false));
				auto dtl = new DamageTypeListener;
				foreach (typ; [DamageType.FIXED, DamageType.MAX]) { mixin(S_TRACE);
					auto radio = new Button(comp, SWT.RADIO);
					radio.setEnabled(!_readOnly);
					radio.setText(_prop.msgs.damageTypeName(typ));
					radio.addSelectionListener(dtl);
					_skillPowerType[typ] = radio;
				}
				_skillPowerValue = createSpinner(_skillPowerComp, _prop.msgs.motionValue, _prop.var.etc.skillPowerMax,
					.tryFormat(_prop.msgs.rangeHint, Motion.uValue_min, _prop.var.etc.skillPowerMax), &valEnter, &valCancel);
				dtl.table = _skillPowerType;
				dtl.valueSpn = _skillPowerValue;
				dtl.isEditable = () => !_summ || !_summ.legacy;
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
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.refBeast.add(&refBeast);
			_comm.delBeast.add(&delBeast);
			_comm.refSkin.add(&_beastImg.redraw);
		}
		_comm.refUndoMax.add(&refUndoMax);
		_comm.refCardImageStatus.add(&_beastImg.redraw);
		_comm.refDataVersion.add(&refEnabled);
		getDisplay().addFilter(SWT.KeyDown, _kdFilter);
	}
	class BeastDragListener : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			auto m = selection;
			e.doit = m && m.beast && _summ;
		}
		override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto m = selection;
				if (!m || !m.beast) return;
				auto sn = XNode.create(BeastCard.XML_NAME_M);
				sn.newAttr("summId", _summ.id);
				sn.newAttr("topLevel", false);
				sn.newAttr("paneId", _id);
				sn.newAttr("scenarioPath", _summ.scenarioPath);
				auto opt = new XMLOption(_prop.sys, LATEST_VERSION);
				m.beast.toNode(sn, opt);
				e.data = bytesFromXML(sn.text);
			}
		}
	}
	class BeastDropListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = _readOnly || !_summ || _summ.scenarioPath == "" ? DND.DROP_NONE : DND.DROP_COPY;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = _readOnly || !_summ || _summ.scenarioPath == "" ? DND.DROP_NONE : DND.DROP_COPY;
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			assert (!_readOnly);
			e.detail = DND.DROP_NONE;

			auto m = selection;
			if (!m) return;
			int mi = _motions.getSelectionIndex();
			if (-1 == mi) return;

			if (!isXMLBytes(e.data)) return;
			string xml = bytesToXML(e.data);
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				bool samePane = _id == node.attr("paneId", false);
				if (samePane) return;
				e.detail = pasteBeast(node);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	void refEnabled() { mixin(S_TRACE);
		auto m = selection();
		if (_maxNest) _maxNest.setEnabled(!_readOnly && m && m.beast && 0 != m.beast.linkId && !_prop.isTargetVersion(_summ, "1"));

		if (_valValue) { mixin(S_TRACE);
			_valValue.setEnabled(m && m.damageType !is DamageType.MAX);
		}

		foreach (radio; _skillPowerType.byValue()) { mixin(S_TRACE);
			radio.setEnabled(m && (!_summ || !_summ.legacy || m.damageType !is DamageType.MAX));
		}
		if (_skillPowerValue) { mixin(S_TRACE);
			_skillPowerValue.setEnabled(m && m.damageType !is DamageType.MAX);
		}
	}
	@property
	private bool canSelectConnectedResource() { mixin(S_TRACE);
		if (!_summ) return false;
		if (!selection) return false;
		auto m = selection;
		if (!m.beast) return false;
		auto b = m.beast;
		if (b.linkId) b = _summ.beast(b.linkId);
		if (!b) return false;
		auto file = b.connectedFile;
		return _summ.hasMaterial(file, _prop.var.etc.ignorePaths);
	}
	private void selectConnectedResource() { mixin(S_TRACE);
		if (!_summ) return;
		if (!selection) return;
		auto m = selection;
		if (!m.beast) return;
		auto b = m.beast;
		if (b.linkId) b = _summ.beast(b.linkId);
		if (!b) return;
		auto file = b.connectedFile;
		if (_summ.hasMaterial(file, _prop.var.etc.ignorePaths)) { mixin(S_TRACE);
			_comm.openFilePath(file, false, true);
		}
	}
	@property
	void motions(Motion[] motions) { mixin(S_TRACE);
		bool oldVan = hasVan;
		scope (exit) {
			if (oldVan != hasVan) {
				foreach (we; warningEvent) we();
			}
		}
		_motions.setRedraw(false);
		_undo.reset();
		foreach (i, m; motions) { mixin(S_TRACE);
			appendMotion(m.dup, -1, false, false, false);
			if (0 == i) _motions.select(0);
		}
		_motions.showSelection();
		refreshSels();
		foreach (dlg; modEvent) dlg();
		_motions.setRedraw(true);
		_comm.refreshToolBar();
	}
	@property
	Motion[] motions() { mixin(S_TRACE);
		Motion[] r;
		r.length = _motions.getItemCount();
		foreach (i, itm; _motions.getItems()) { mixin(S_TRACE);
			r[i] = cast(Motion) itm.getData();
		}
		return r;
	}
	private class MotionTCPD : TCPD {
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			auto m = selection;
			if (m) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			auto m = selection;
			if (m) { mixin(S_TRACE);
				XMLtoCB(_prop, _comm.clipboard, m.toXML(new XMLOption(_prop.sys, LATEST_VERSION)));
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					if (node.name == Motion.XML_NAME) { mixin(S_TRACE);
						auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
						appendMotion(Motion.createFromNode(node, ver));
						_motions.select(_motions.getItemCount() - 1);
						_motions.showSelection();
						refreshSels();
						foreach (dlg; modEvent) dlg();
					} else { mixin(S_TRACE);
						pasteBeast(node);
					}
					_comm.refreshToolBar();
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		override void del(SelectionEvent se) { mixin(S_TRACE);
			removeMotion();
		}
		override void clone(SelectionEvent se) { mixin(S_TRACE);
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return true;
		}
		@property
		override bool canDoT() { mixin(S_TRACE);
			return !_readOnly && _motions.getSelectionIndex() >= 0;
		}
		@property
		override bool canDoC() { mixin(S_TRACE);
			return _motions.getSelectionIndex() >= 0;
		}
		@property
		override bool canDoP() { mixin(S_TRACE);
			return !_readOnly && CBisXML(_comm.clipboard);
		}
		@property
		override bool canDoD() { mixin(S_TRACE);
			return canDoT;
		}
		@property
		override bool canDoClone() { mixin(S_TRACE);
			return !_readOnly && canDoC;
		}
	}

	private bool qCardMaterialCopy(BeastCard card, string fromSPath) { mixin(S_TRACE);
		if (!_summ || _summ.scenarioPath == "") return false;
		if (fromSPath.length && !cfnmatch(nabs(fromSPath), nabs(_summ.scenarioPath))) { mixin(S_TRACE);
			auto uc = new UseCounter;
			card.setUseCounter(uc);
			bool copy;
			bool r = qMaterialCopy(_comm, getShell(), uc, _summ.scenarioPath, fromSPath, copy, _summ.legacy);
			card.removeUseCounter();
			if (copy) { mixin(S_TRACE);
				_comm.refPaths.call(_comm.skin.materialPath);
			}
			return r;
		}
		return true;
	}
	private int pasteBeast(ref XNode node) { mixin(S_TRACE);
		if (!_summ || _summ.scenarioPath == "") return false;
		auto m = selection;
		int detail = DND.DROP_NONE;
		if (m && m.detail.use(MArg.BEAST)) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				bool sameSc = _summ.id == node.attr("summId", false);
				bool topLevel = node.attr!bool("topLevel", false, false);
				string fromSPath = node.attr("scenarioPath", false);
				if (node.name == BeastCard.XML_NAME_M) { mixin(S_TRACE);
					auto bNode = node.child(BeastCard.XML_NAME, false);
					if (!bNode.valid) return DND.DROP_NONE;
					auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
					auto beast = BeastCard.createFromNode(bNode, ver);
					if (qCardMaterialCopy(beast, fromSPath)) { mixin(S_TRACE);
						storeEdit(_motions.getSelectionIndex());
						if (m.beast) _comm.delBeast.call(m, m.beast);
						m.beast = null;
						auto bid = beast.id;
						if (bid && sameSc && topLevel && (_prop.var.etc.linkCard || !_summ || !_summ.legacy)) { mixin(S_TRACE);
							m.beast = new BeastCard(1UL, "", [], "");
							m.beast.linkId = bid;
							detail = DND.DROP_LINK;
						} else { mixin(S_TRACE);
							m.newBeast = beast;
							detail = DND.DROP_COPY;
						}
						resetMaxNest(m);
						_beastImg.redraw();
						foreach (dlg; modEvent) dlg();
						refEnabled();
					}
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
		return detail;
	}
	private void resetMaxNest(Motion m) { mixin(S_TRACE);
		if (!m.beast || 0 == m.beast.linkId) { mixin(S_TRACE);
			m.maxNest = Motion.maxNest_init;
			_maxNest.setSelection(m.maxNest);
		}
	}
	private class BeastTCPD : TCPD {
		private bool copyImpl() { mixin(S_TRACE);
			if (!_summ) return false;
			auto m = selection;
			if (m) { mixin(S_TRACE);
				assert (m.detail.use(MArg.BEAST));
				if (m.beast) { mixin(S_TRACE);
					auto node = XNode.create(BeastCard.XML_NAME_M);
					node.newAttr("summId", _summ.id);
					node.newAttr("paneId", "");
					node.newAttr("scenarioPath", nabs(_summ.scenarioPath));
					m.beast.toNode(node, new XMLOption(_prop.sys, LATEST_VERSION));
					XMLtoCB(_prop, _comm.clipboard, node.text);
					_comm.refreshToolBar();
					return true;
				}
			}
			return false;
		}
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			if (copyImpl()) { mixin(S_TRACE);
				del(se);
			}
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			copyImpl();
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					pasteBeast(node);
					_comm.refreshToolBar();
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		override void del(SelectionEvent se) { mixin(S_TRACE);
			auto m = selection;
			if (m) { mixin(S_TRACE);
				assert (m.detail.use(MArg.BEAST));
				if (m.beast) { mixin(S_TRACE);
					storeEdit(_motions.getSelectionIndex());
					if (_summ && _summ.scenarioPath != "" && m.beast) _comm.delBeast.call(m, m.beast);
					m.beast = null;
					resetMaxNest(m);
					_beastImg.redraw();
					foreach (dlg; modEvent) dlg();
					_comm.refreshToolBar();
					refEnabled();
				}
			}
		}
		override void clone(SelectionEvent se) { mixin(S_TRACE);
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return true;
		}
		@property
		override bool canDoT() { mixin(S_TRACE);
			return !_readOnly && selection !is null;
		}
		@property
		override bool canDoC() { mixin(S_TRACE);
			return selection !is null;
		}
		@property
		override bool canDoP() { mixin(S_TRACE);
			return !_readOnly && CBisXML(_comm.clipboard);
		}
		@property
		override bool canDoD() { mixin(S_TRACE);
			return !_readOnly && selection !is null;
		}
		@property
		override bool canDoClone() { mixin(S_TRACE);
			return false;
		}
	}
	void undo() { mixin(S_TRACE);
		_undo.undo();
	}
	void redo() { mixin(S_TRACE);
		_undo.redo();
	}

	@property
	string[] warnings() { mixin(S_TRACE);
		string[] ws;
		bool[string] exists;
		foreach (itm; _motions.getItems()) { mixin(S_TRACE);
			void put(string w) { mixin(S_TRACE);
				if (w !in exists) { mixin(S_TRACE);
					ws ~= w;
					exists[w] = true;
				}
			}
			auto m = cast(Motion)itm.getData();
			if (m.type is MType.CANCEL_ACTION && !_prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
				put(.tryFormat(_prop.msgs.warningUnknownMotion, _prop.msgs.motionName(m.type), "1.50"));
			}
			if (m.type is MType.NO_EFFECT && !_prop.isTargetVersion(_summ, "2")) { mixin(S_TRACE);
				put(.tryFormat(_prop.msgs.warningUnknownMotionWsn, _prop.msgs.motionName(m.type), "2"));
			}
			if (m.type == MType.SUMMON_BEAST && m.beast && 0 != m.beast.linkId && !(_summ && _summ.beast(m.beast.linkId))) { mixin(S_TRACE);
				put(.tryFormat(_prop.msgs.searchErrorLinkIdBeastNotFound, m.beast.linkId));
			}
			if ((m.type == MType.GET_SKILL_POWER || m.type == MType.LOSE_SKILL_POWER)
					&& m.damageType !is DamageType.MAX && !_prop.isTargetVersion(_summ, "1")) { mixin(S_TRACE);
				put(_prop.msgs.warningSkillPowerWithFixedValue);
			}
		}
		return ws;
	}

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		if (cate == "motion") { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= _motions.getItemCount()) return false;
			_motions.select(cast(int)index);
			refreshSels();
			path = cpbottom(path);
			if (!cphasattr(path, "nofocus")) .forceFocus(_motions, shellActivate);
			if (cpempty(path)) { mixin(S_TRACE);
				_comm.refreshToolBar();
				return true;
			}
			auto m = selection;
			if (m.beast) { mixin(S_TRACE);
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
				if ("event" == cpcategory(path)) { mixin(S_TRACE);
					auto w = openBeastEventWin(m.beast);
					if (!w) return false;
					_comm.refreshToolBar();
					return w.openCWXPath(path, shellActivate);
				} else { mixin(S_TRACE);
					if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
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

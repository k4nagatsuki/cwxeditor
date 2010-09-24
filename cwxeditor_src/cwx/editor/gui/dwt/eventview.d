
module cwx.editor.gui.dwt.eventview;

import cwx.area;
import cwx.event;
import cwx.summary;
import cwx.card;
import cwx.utils;
import cwx.skin;
import cwx.usecounter;
import cwx.path;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.message;
import cwx.editor.gui.dwt.eventtreeview;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;

import std.string;

import dwt.DWT;
import dwt.widgets.Control;
import dwt.widgets.Display;
import dwt.widgets.Shell;
import dwt.widgets.Composite;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.CoolBar;
import dwt.widgets.CoolItem;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.widgets.Tree;
import dwt.widgets.TreeItem;
import dwt.widgets.Text;
import dwt.widgets.Label;
import dwt.widgets.Combo;
import dwt.widgets.Spinner;
import dwt.custom.SashForm;
import dwt.custom.CCombo;
import dwt.events.ShellEvent;
import dwt.events.ShellAdapter;
import dwt.events.ControlEvent;
import dwt.events.ControlAdapter;
import dwt.events.DisposeEvent;
import dwt.events.DisposeListener;
import dwt.events.SelectionEvent;
import dwt.events.SelectionAdapter;
import dwt.graphics.Image;
import dwt.layout.FillLayout;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.custom.CLabel;
import dwt.dwthelper.utils;
import dwt.dnd.Clipboard;
import dwt.dnd.ByteArrayTransfer;

public:

alias ArrayWrapperString KeyCodeObj;
alias Integer RoundObj;

class EventView(A : EventTreeOwner, C, bool UseFire) : Composite, TCPD {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;
	A _area;
	UndoManager _undo;

	SplitPane _sash;
	Tree _cards;
	TreeEdit _edit;
	EventTreeView _etree;
	Label _statbar;

	ToolBar _toolbar;
	CCombo _treeKind;
	ToolItem _fireItm;

	TCPD[] _tcpd;
	TreeItem _oldSelP = null;
	TreeItem _selItm = null;

	abstract class EVUndo : Undo {
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		private int[] _selPath, _selPath2;
		private int[] getSelPath() {
			auto itm = selection;
			if (itm) {
				int[] selPath;
				while (itm.getParentItem) {
					selPath = [itm.getParentItem.indexOf(itm)] ~ selPath;
					itm = itm.getParentItem;
				}
				return [_cards.indexOf(itm)] ~ selPath;
			} else {
				return null;
			}
		}
		this () {
			_selPath = getSelPath;
		}
		protected void udb() {
			.forceFocus(_cards);
			_selPath2 = getSelPath;
		}
		protected void uda() {
			if (_selPath) {
				auto itm = _cards.getItem(_selPath[0]);
				_selPath = _selPath[1 .. $];
				while (_selPath.length) {
					itm = itm.getItem(_selPath[0]);
					_selPath = _selPath[1 .. $];
				}
				auto eti = selectionEventTree;
				_cards.select(itm);
				auto eti2 = selectionEventTree;
				if (eti !is eti2) {
					if (eti2) {
						__select(eti2);
					} else {
						_etree.refresh(null);
					}
				}
				_selPath = _selPath2;
			} else {
				_cards.deselectAll;
			}
		}
	}
	class UndoTreeData : EVUndo {
		private int _ownerIndex;
		private int _index;
		private static struct Vals {
			bool expand;
			string name;
			bool enter;
			bool escape;
			bool lose;
			string[] keyCodes;
			uint[] rounds;
		}
		private Vals _vals;
		this (EventTree tree) {
			auto owner = tree.owner;
			_index = indexOf!("a is b")(tree.owner.trees, tree);
			foreach (i, itm; _cards.getItems) {
				auto eto = cast(EventTreeOwner) itm.getData;
				if (owner is eto) {
					_ownerIndex = i;
					break;
				}
			}
			save;
		}
		private void save() {
			_vals.expand = getItem.getExpanded;
			auto tree = cast(EventTree) getItem.getData;
			_vals.name = tree.name;
			_vals.enter = tree.fireEnter;
			_vals.escape = tree.fireEscape;
			_vals.lose = tree.fireLose;
			_vals.keyCodes = tree.keyCodes;
			_vals.rounds = tree.rounds;
		}
		private TreeItem getItem() {
			return _cards.getItem(_ownerIndex).getItem(_index);
		}
		private void impl() {
			udb;
			scope (exit) uda;
			auto vals = _vals;
			save;
			auto itm = getItem;
			itm.setExpanded = vals.expand;
			auto tree = cast(EventTree) itm.getData;
			itm.setText = vals.name;
			tree.name = vals.name;
			tree.enter = vals.enter;
			tree.escape = vals.escape;
			tree.lose = vals.lose;
			tree.removeKeyCodesAll;
			foreach (kc; vals.keyCodes) tree.addKeyCode(kc);
			tree.removeRoundsAll;
			foreach (rnd; vals.rounds) tree.addRound(rnd);
			_etree.refreshTreeName;
		}
		override void undo() {impl;}
		override void redo() {impl;}
		override void dispose() {}
	}
	void store(EventTree tree) {
		_undo ~= new UndoTreeData(tree);
	}
	class UndoInsert : EVUndo {
		private int _ownerIndex;
		private int _insertIndex;
		private UndoDelete _delUndo = null;
		this (int ownerIndex, int insertIndex) {
			_ownerIndex = ownerIndex;
			_insertIndex = insertIndex;
		}
		override void undo() {
			udb;
			scope (exit) uda;
			auto ownItm = _cards.getItem(_ownerIndex);
			auto owner = cast(EventTreeOwner) ownItm.getData;
			auto tree = owner.trees[_insertIndex];
			if (_etree.eventTree && _etree.eventTree.areaPath == tree.areaPath) {
				_etree.refresh(null);
			}
			_delUndo = new UndoDelete(tree);
			owner.removeEvent(_insertIndex);
			ownItm.getItem(_insertIndex).dispose;
			_comm.refUseCount.call;
		}
		override void redo() {
			_delUndo.undo;
			_delUndo = null;
		}
		override void dispose() {
			if (_delUndo) _delUndo.dispose;
		}
	}
	void storeI(int ownerIndex, int insertIndex) {
		_undo ~= new UndoInsert(ownerIndex, insertIndex);
	}
	class UndoDelete : EVUndo {
		private int _ownerIndex;
		private int _treeIndex;
		private EventTree _tree;
		private UndoInsert _istUndo = null;
		this (EventTree tree) {
			auto owner = tree.owner;
			foreach (i, itm; _cards.getItems) {
				auto eto = cast(EventTreeOwner) itm.getData;
				if (eto is owner) {
					_ownerIndex = i;
					_treeIndex = indexOf!("a is b")(owner.trees, tree);
					break;
				}
			}
			_tree = EventTree.createFromNode(tree.toNode, LATEST_VERSION);
			_tree.setUseCounter(_summ.useCounter.sub);
		}
		override void undo() {
			udb;
			scope (exit) uda;
			_istUndo = new UndoInsert(_ownerIndex, _treeIndex);
			auto parItm = _cards.getItem(_ownerIndex);
			appendTree(parItm, _tree, _treeIndex, null, false);
		}
		override void redo() {
			_istUndo.undo;
			_istUndo = null;
		}
		override void dispose() {
			_tree.removeUseCounter;
			if (_istUndo) _istUndo.dispose;
		}
	}
	void storeD(EventTree tree) {
		_undo ~= new UndoDelete(tree);
	}
	class UndoSwap : EVUndo {
		private int _ownerIndex;
		private int _upIndex;
		this (int ownerIndex, int swapIndex1, int swapIndex2) {
			_ownerIndex = ownerIndex;
			_upIndex = max(swapIndex1, swapIndex2);
		}
		private void impl() {
			udb;
			scope (exit) uda;
			up(_cards.getItem(_ownerIndex).getItem(_upIndex), false);
		}
		override void undo() {impl;}
		override void redo() {impl;}
		override void dispose() {}
	}
	void store(int ownerIndex, int swapIndex1, int swapIndex2) {
		_undo ~= new UndoSwap(ownerIndex, swapIndex1, swapIndex2);
	}

	void forceSel(size_t[] etAreaPath) {
		auto eet = _etree.eventTree;
		if (eet && eet.areaPath == etAreaPath) return;
		auto eta = _area.etFromPath(etAreaPath).areaPath;
		foreach (i, itm; _cards.getItems) {
			foreach (j, tItm; itm.getItems) {
				auto cet = cast(EventTree) tItm.getData;
				assert (cet);
				if (cet.areaPath == eta) {
					__select(tItm);
					return;
				}
			}
		}
		assert (0);
	}

	void __select(TreeItem itm) {
		_cards.setSelection = [itm];
		if (cast(EventTree) itm.getData) {
			_selItm = itm;
			_etree.refresh(cast(EventTree) itm.getData);
		}
		static if (UseFire) {
			auto parItm = selectionParent;
			if (parItm && (!_oldSelP || _oldSelP != parItm) && _treeKind.getSelectionIndex == 0) {
				auto c = cast(CCombo) _fireItm.getControl;
				c.removeAll;
				string[] vals;
				if (cast(EventTreeOwner) parItm.getData) {
					vals = startDefVals;
				}
				foreach (i, v; vals) {
					c.add(v);
					if (i == 0) c.setText = v;
				}
			}
		}
		if (isVisible) openToolWindow;
	}

	void refreshTopStart() {
		assert (_selItm);
		assert (_selItm.getData is _etree.eventTree);
		_selItm.setText = _etree.eventTree.name;
	}
	class SListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			__select(cast(TreeItem) e.item);
		}
	}
	static int before(T)(T parent, int index) {
		if (index > 0) {
			return index - 1;
		}
		return -1;
	}
	static int after(T)(T parent, int index) {
		if (index + 1 < parent.getItemCount) {
			return index + 1;
		}
		return -1;
	}
	TreeItem selection() {
		auto sels = _cards.getSelection;
		if (sels.length > 0) {
			return sels[0];
		}
		return null;
	}
	void selection(int index) {
		__select(_cards.getItems[index]);
	}
	void setStatusLine(string msg) {
		_statbar.setText = std.string.replace(msg, "&", "&&");
	}
	private TreeItem selectionParent() {
		auto itm = selection;
		if (!itm) return null;
		auto data = itm.getData;
		if (cast(EventTreeOwner) data) return itm;
		if (cast(EventTree) data) {
			return itm.getParentItem;
		} else {
			return itm.getParentItem.getParentItem;
		}
	}
	private TreeItem selectionEventTree() {
		auto itm = selection;
		if (!itm) return null;
		auto data = itm.getData;
		if (cast(EventTreeOwner) data) return null;
		if (cast(EventTree) data) {
			return itm;
		} else {
			return itm.getParentItem;
		}
	}
	void createEventTree() {
		auto parItm = selectionParent;
		if (!parItm) return;
		string treeName;
		static if (UseFire) {
			auto fire = addingFire(parItm.getData);
			if (!fire) return;
			if (fire is ENTER) {
				if (cast(A) parItm.getData) {
					static if (is (A == Area)) {
						treeName = _prop.msgs.enterTree;
					} else static if (is (A == Battle)) {
						treeName = _prop.msgs.victoryTree;
					} else static if (is (A == Package)) {
						treeName = _prop.msgs.packageTree;
					} else {
						treeName = _prop.msgs.useTree;
					}
				} else {
					static if (is (C == MenuCard)) {
						assert (cast(C) parItm.getData);
						treeName = _prop.msgs.selectTree;
					} else static if (is (C == EnemyCard)) {
						assert (cast(C) parItm.getData);
						treeName = _prop.msgs.deadTree;
					}
				}
			} else if (fire is ESCAPE) {
				treeName = _prop.msgs.escapeTree;
			} else if (fire is LOSE) {
				treeName = _prop.msgs.loseTree;
			} else if (cast(KeyCodeObj) fire) {
				treeName = _prop.msgs.keyCodeTree((cast(KeyCodeObj) fire).array);
			} else {
				assert (cast(RoundObj) fire);
				treeName = _prop.msgs.roundTree((cast(RoundObj) fire).intValue);
			}
		} else {
			Object fire = null;
			static if (is (A == Package)) {
				treeName = _prop.msgs.packageTree;
			} else {
				treeName = _prop.msgs.useTree;
			}
		}
		auto owner = cast(EventTreeOwner) parItm.getData;
		auto tree = new EventTree(treeName);
		appendTree(parItm, tree, owner.trees.length, fire, true);
	}
	void appendTree(TreeItem parItm, EventTree tree, int index, Object defFire, bool store) {
		auto eto = cast(EventTreeOwner) parItm.getData;
		if (store) storeI(_cards.indexOf(parItm), eto.trees.length);
		eto.insert(index, tree);
		auto treeItm = appendTreeItem(parItm, index, defFire);
		__select(treeItm);
		_comm.refUseCount.call;
	}
	void refreshTrees(TreeItem parItm) {
		auto par = cast(EventTreeOwner) parItm.getData;
		parItm.removeAll;
		foreach (index, tree; par.trees) {
			appendTreeItem(parItm, index, null);
		}
		parItm.setExpanded = true;
	}
	TreeItem appendTreeItem(TreeItem parItm, int index, Object defFire) {
		auto par = cast(EventTreeOwner) parItm.getData;
		auto tree = par.trees[index];
		auto treeItm = createTreeItem(parItm, tree, tree.name, _prop.images.eventTree, index);
		static if (UseFire) {
			if (defFire) addFire(treeItm, defFire);
			refreshFires(treeItm);
		}
		return treeItm;
	}
	Control createEditor(TreeItem itm) {
		static if (UseFire) {
			if (cast(EventTree) itm.getData || cast(KeyCodeObj) itm.getData) {
				return createTextEditor(_cards, itm.getText);
			}
		} else {
			if (cast(EventTree) itm.getData) {
				return createTextEditor(_cards, itm.getText);
			}
		}
		return null;
	}
	void editEnd(TreeItem itm, Control c) {
		string text = (cast(Text) c).getText;
		if (text.length == 0) return;
		itm.setText = text;
		auto tree = cast(EventTree) itm.getData;
		if (tree) {
			store(tree);
			tree.name = text;
			_etree.refreshTreeName;
			return;
		}
		static if (UseFire) {
			assert (cast(KeyCodeObj) itm.getData);
			auto p = itm.getParentItem;
			tree = cast(EventTree) p.getData;
			store(tree);
			tree.setKeyCode(p.indexOf(itm) - keyCodesIndex(p), text);
		}
	}
	static if (UseFire) {
		void refreshFires(TreeItem eItm, Object sel = null) {
			auto t = cast(EventTree) eItm.getData;
			bool expand = eItm.getExpanded;
			scope (exit) eItm.setExpanded = expand;
			eItm.removeAll;
			static if (is (A == Area)) {
				if (t.fireEnter) {
					if (cast(A) eItm.getParentItem.getData) {
						createTreeItem(eItm, ENTER, _prop.msgs.startEnter, _prop.images.defStart);
					} else {
						assert (cast(C) eItm.getParentItem.getData);
						createTreeItem(eItm, ENTER, _prop.msgs.startSelect, _prop.images.defStart);
					}
				}
				createKeyCodeItem(eItm, t);
			} else static if (is (A == Battle)) {
				if (cast(A) eItm.getParentItem.getData) {
					if (t.fireEnter) {
						createTreeItem(eItm, ENTER, _prop.msgs.startVictory, _prop.images.defStart);
					}
					if (t.fireEscape) {
						createTreeItem(eItm, ESCAPE, _prop.msgs.startEscape, _prop.images.defStart);
					}
					if (t.fireLose) {
						createTreeItem(eItm, LOSE, _prop.msgs.startLose, _prop.images.defStart);
					}
				} else {
					assert (cast(C) eItm.getParentItem.getData);
					if (t.fireEnter) {
						createTreeItem(eItm, ENTER, _prop.msgs.startDead, _prop.images.defStart);
					}
				}
				createKeyCodeItem(eItm, t);
				if (cast(A) eItm.getParentItem.getData) {
					foreach (r; t.rounds) {
						createTreeItem(eItm, new RoundObj(r), _prop.msgs.startRound(r), _prop.images.round);
					}
				}
			} else static if (is (A == Package)) {
				if (t.fireEnter) {
					createTreeItem(eItm, ENTER, _prop.msgs.startPackage, _prop.images.defStart);
				}
			} else {
				auto eItm = createTreeItem(aItm, t, t.name, _prop.images.eventTree);
				if (t.fireEnter) {
					createTreeItem(eItm, ENTER, _prop.msgs.startUse, _prop.images.defStart);
				}
			}
			if (sel) {
				foreach (itm; eItm.getItems) {
					auto data = itm.getData;
					if (cast(KeyCodeObj) data && cast(KeyCodeObj) sel) {
						if ((cast(KeyCodeObj) data).array == (cast(KeyCodeObj) sel).array) {
							_cards.setSelection = [itm];
							break;
						}
					} else if (cast(RoundObj) data && cast(RoundObj) sel) {
						if ((cast(RoundObj) data).intValue == (cast(RoundObj) sel).intValue) {
							_cards.setSelection = [itm];
							break;
						}
					} else if (data is sel) {
						assert (data is ENTER || data is LOSE || data is ESCAPE);
						_cards.setSelection = [itm];
						break;
					}
				}
				eItm.setExpanded = true;
			}
		}
		Object addingFire(Object areaOrCard) {
			static if (!is (C == void)) {
				Object addKeyCodes() {
					auto kc = (cast(CCombo) _fireItm.getControl).getText;
					return kc.length > 0 ? new KeyCodeObj(kc) : null;
				}
				Object addAreaAndEtc() {
					switch (_treeKind.getSelectionIndex) {
					case 0:
						return ENTER;
					case 1:
						return addKeyCodes;
					default:
						return null;
					}
				}
			}
			if (cast(A) areaOrCard) {
				static if (is (A == Area)) {
					return addAreaAndEtc;
				} else static if (is (A == Battle)) {
					switch (_treeKind.getSelectionIndex) {
					case 0:
						switch ((cast(CCombo) _fireItm.getControl).getSelectionIndex) {
						case 0:
							return ENTER;
						case 1:
							return ESCAPE;
						case 2:
							return LOSE;
						}
					case 1:
						return addKeyCodes;
					case 2:
						int round = (cast(Spinner) _fireItm.getControl).getSelection;
						return new RoundObj(round);
					}
				} else {
					return ENTER;
				}
			} else {
				static if (!is (C == void)) {
					assert (cast(C) areaOrCard);
					return addAreaAndEtc;
				}
			}
			return null;
		}
		void createEventFire() {
			auto treeItm = selectionEventTree;
			if (!treeItm) return;
			auto tree = cast(EventTree) treeItm.getData;
			store(tree);
			auto fire = addingFire(treeItm.getParentItem.getData);
			if (!fire) return;
			addFire(treeItm, fire);
			refreshFires(treeItm, fire);
		}
		void addFire(TreeItem treeItm, Object fire) {
			auto tree = cast(EventTree) treeItm.getData;
			if (fire is ENTER) {
				tree.enter = true;
			} else if (fire is ESCAPE) {
				tree.escape = true;
			} else if (fire is LOSE) {
				tree.lose = true;
			} else if (cast(KeyCodeObj) fire) {
				tree.addKeyCode((cast(KeyCodeObj) fire).array);
			} else {
				assert (cast(RoundObj) fire);
				tree.addRound((cast(RoundObj) fire).intValue);
			}
		}
		static const Object ENTER;
		static const Object ESCAPE;
		static const Object LOSE;
		static this() {
			ENTER = new Object;
			ESCAPE = new Object;
			LOSE = new Object;
		}
		int keyCodesIndex(TreeItem itm) {
			assert (cast(EventTree) itm.getData);
			auto o = itm.getParentItem.getData;
			if (cast(A) o) {
				auto tree = cast(EventTree) itm.getData;
				static if (is (A == Battle)) {
					int r = 0;
					if (tree.fireEnter) r++;
					if (tree.fireLose) r++;
					if (tree.fireEscape) r++;
					return r;
				} else {
					return (cast(EventTree) itm.getData).fireEnter ? 1 : 0;
				}
			} else {
				static if (!is (C == void)) {
					assert (cast(C) o);
					return (cast(EventTree) itm.getData).fireEnter ? 1 : 0;
				} else {
					assert (0);
				}
			}
		}
		void createKeyCodeItem(T)(TreeItem parent, T a) {
			foreach (kc; a.keyCodes) {
				createTreeItem(parent, new KeyCodeObj(kc), kc, _prop.images.keyCode);
			}
		}
	}
	void replText() {
		foreach (itm; _cards.getItems) {
			auto data = itm.getData;
			if (cast(A) data) {
				itm.setText = (cast(A) data).name;
			}
			static if (!is (C == void)) {
				if (cast(C) data) {
					static if (is (C == MenuCard)) {
						itm.setText = (cast(C) data).name;
					} else static if (is (C == EnemyCard)) {
						auto castCard = _summ.casts((cast(C) data).id);
						itm.setText = castCard ? castCard.name : "";
					} else {
						static assert (0);
					}
				}
			}
			foreach (itm2; itm.getItems) {
				auto et = cast(EventTree) itm2.getData;
				itm2.setText = et.name;
				static if (UseFire && (is (A == Area) || is (A == Battle))) {
					int startKC = -1;
					foreach (i, itm3; itm2.getItems) {
						auto kc = cast(KeyCodeObj) itm3.getData;
						if (kc && startKC <= 0) startKC = i;
						if (startKC >= 0) {
							itm3.setText = et.keyCodes[i - startKC];
						}
					}
				}
			}
		}
	}
public:
	this(Commons comm, Props prop, Summary summ, A area, Composite parent, UndoManager undo) {
		super(parent, DWT.NONE);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_area = area;
		_undo = undo;
		auto gl = windowGridLayout(1);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		setLayout = gl;

		auto toolbar = new ToolBar(this, DWT.FLAT);
		toolbar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

		_sash = new SplitPane(this, DWT.HORIZONTAL);
		static if (is (A == Area) || is (A == Battle)) {
			_comm.refStandardKeyCodes.add(&refKeyCodes);
		}
		_comm.replText.add(&replText);
		static if (is (A == Area)) {
			_comm.refArea.add(&refreshTitle);
		} else static if (is (A == Battle)) {
			_comm.refBattle.add(&refreshTitle);
		} else static if (is (A == Package)) {
			_comm.refPackage.add(&refreshTitle);
		} else static if (is (A == SkillCard)) {
			_comm.refSkill.add(&refreshTitle);
		} else static if (is (A == ItemCard)) {
			_comm.refItem.add(&refreshTitle);
		} else static if (is (A == BeastCard)) {
			_comm.refBeast.add(&refreshTitle);
		} else static assert (0);
		_sash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				int[] ws = _sash.getWeights;
				static if (is (A == Area)) {
					_prop.var.areaWin.eventSashL = ws[0];
					_prop.var.areaWin.eventSashR = ws[1];
				} else static if (is (A == Battle)) {
					_prop.var.battleWin.eventSashL = ws[0];
					_prop.var.battleWin.eventSashR = ws[1];
				} else static if (is (A == Package)) {
					_prop.var.packageWin.eventSashL = ws[0];
					_prop.var.packageWin.eventSashR = ws[1];
				} else static if (is (A : EffectCard)) {
					_prop.var.cardEventWin.eventSashL = ws[0];
					_prop.var.cardEventWin.eventSashR = ws[1];
				} else {
					static assert (0);
				}
				static if (is (A == Area) || is (A == Battle)) {
					_comm.refStandardKeyCodes.remove(&refKeyCodes);
				}
				_comm.replText.remove(&replText);
				static if (is (A == Area)) {
					_comm.refArea.remove(&refreshTitle);
				} else static if (is (A == Battle)) {
					_comm.refBattle.remove(&refreshTitle);
				} else static if (is (A == Package)) {
					_comm.refPackage.remove(&refreshTitle);
				} else static if (is (A == SkillCard)) {
					_comm.refSkill.remove(&refreshTitle);
				} else static if (is (A == ItemCard)) {
					_comm.refItem.remove(&refreshTitle);
				} else static if (is (A == BeastCard)) {
					_comm.refBeast.remove(&refreshTitle);
				} else static assert (0);
			}
		});
		_sash.setLayoutData = new GridData(GridData.FILL_BOTH);
		{
			_cards = new Tree(_sash, DWT.SINGLE | DWT.BORDER);
			_sash.setControl1 = _cards;
			_cards.addSelectionListener(new SListener);
			auto menu = new Menu(parent.getShell, DWT.POP_UP);
			appendMenuTCPD(_prop, menu, this, true, true, true, true);
			_cards.setMenu = menu;
		}
		{
			_etree = new EventTreeView(comm, prop, summ, _sash, _undo, &forceSel, &refreshTopStart, &setStatusLine);
			_sash.setControl2 = _etree.widget;
			auto _edit = new TreeEdit(_cards, &editEnd, &createEditor);
			setupToolBar(toolbar);
		}
		static if (is (A == Area)) {
			_sash.setWeights = [_prop.var.areaWin.eventSashL, _prop.var.areaWin.eventSashR];
		} else static if (is (A == Battle)) {
			_sash.setWeights = [_prop.var.battleWin.eventSashL, _prop.var.battleWin.eventSashR];
		} else static if (is (A == Package)) {
			_sash.setWeights = [_prop.var.packageWin.eventSashL, _prop.var.packageWin.eventSashR];
		} else static if (is (A : EffectCard)) {
			_sash.setWeights = [_prop.var.cardEventWin.eventSashL, _prop.var.cardEventWin.eventSashR];
		} else {
			static assert (0);
		}
		{
			_statbar = new Label(this, DWT.BORDER);
			_statbar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
	}

	/// エリアの名称表示を更新する。
	void refreshTitle() {
		_cards.getItems[0].setText = _area.name;
	}
	private void refreshTitle(A area) {
		if (area is _area) {
			_cards.getItems[0].setText = _area.name;
		}
	}
	static if (!is (C == void)) {
		private string cardName(C c) {
			static if (is (C == MenuCard)) {
				return c.name;
			} else {
				static assert (is (C == EnemyCard));
				auto castCard = _summ.casts(c.id);
				return castCard ? castCard.name : "";
			}
		}
		void appendCard(int index, C c) {
			Image imgCard;
			static if (is (C == MenuCard)) {
				imgCard = _prop.images.cards;
			} else static if (is (C == EnemyCard)) {
				imgCard = _prop.images.cards;
			}
			auto itm = createTreeItem(_cards, c, cardName(c), imgCard, index + 1);
			refreshTrees(itm);
		}
		void removeCard(int index) {
			if (_selItm && _selItm.getParentItem is _cards.getItems[index + 1]) {
				_etree.refresh(null);
			}
			_cards.getItems[index + 1].dispose;
		}
		void renameCard(int index) {
			auto itm = _cards.getItems[index + 1];
			itm.setText = cardName(cast(C) itm.getData);
		}
		void __udCard(int[] indices, int function(TreeItem) ud, int udVal) {
			foreach (i; indices) {
				if (_selItm && _selItm.getParentItem is _cards.getItems[i + 1]) {
					int s = _selItm.getParentItem.indexOf(_selItm);
					int newI = ud(_cards.getItems[i + 1]) + udVal;
					__select(_cards.getItems[newI].getItems[s]);
				} else {
					ud(_cards.getItems[i + 1]);
				}
			}
		}
		void upCard(int[] indices) {
			__udCard(indices, &treeItemUp, -1);
		}
		void downCard(int[] indices) {
			__udCard(indices, &treeItemDown, 1);
		}
	}
	void refresh(bool openToolWin = true) {
		_etree.closeToolWindow;
		_cards.removeAll;
		{
			Image imgArea;
			static if (is (A == Area)) {
				imgArea = _prop.images.area;
			} else static if (is (A == Battle)) {
				imgArea = _prop.images.battle;
			} else static if (is (A == Package)) {
				imgArea = _prop.images.packages;
			} else static if (is (A == SkillCard)) {
				imgArea = _prop.images.skill;
			} else static if (is (A == ItemCard)) {
				imgArea = _prop.images.item;
			} else static if (is (A == BeastCard)) {
				imgArea = _prop.images.beast;
			} else {
				static assert (0);
			}
			auto aItm = createTreeItem(_cards, _area, _area.name, imgArea);
			foreach (i, t; _area.trees) {
				auto eItm = createTreeItem(aItm, t, t.name, _prop.images.eventTree);
				static if (UseFire) {
					refreshFires(eItm);
				}
				if (i == 0) {
					__select(eItm);
				}
			}
			if (_area.trees.length == 0) {
				__select(aItm);
			}
			aItm.setExpanded = true;
		}
		static if (!is (C == void)) {
			foreach (c; _area.cards) {
				Image imgCard;
				static if (is (C == MenuCard)) {
					imgCard = _prop.images.cards;
				} else static if (is (C == EnemyCard)) {
					imgCard = _prop.images.cards;
				}
				auto cItm = createTreeItem(_cards, c, cardName(c), imgCard);
				foreach (t; c.trees) {
					auto eItm = createTreeItem(cItm, t, t.name, _prop.images.eventTree);
					static if (UseFire) {
						refreshFires(eItm);
					}
				}
				cItm.setExpanded = true;
			}
		}
		if (openToolWin) openToolWindow;
	}
	private void __ud(string BeforeAfter, string CanSwapKeyCode)
			(TreeItem itm, int function(TreeItem) treeSwap, bool store) {
		if (itm && itm.getParentItem) {
			auto data = itm.getData;
			auto parent = itm.getParentItem;
			int from = parent.indexOf(itm);
			int to = mixin (BeforeAfter);
			if (to >= 0) {
				if (cast(EventTree) data) {
					_cards.setRedraw = false;
					scope (exit) _cards.setRedraw = true;
					if (store) this.store(_cards.indexOf(parent), from, to);
					// イベントツリー
					(cast(EventTreeOwner) parent.getData).swapEventTree(from, to);
					treeSwap(itm);
					_selItm = selection;
					_cards.showSelection;
				} else {
					static if (UseFire) {
						if (cast(KeyCodeObj) data) {
							_cards.setRedraw = false;
							scope (exit) _cards.setRedraw = true;
							// キーコード
							auto tree = cast(EventTree) parent.getData;
							if (store) this.store(tree);
							int keyCodeLen = tree.keyCodes.length;
							from -= keyCodesIndex(parent);
							to -= keyCodesIndex(parent);
							if (mixin (CanSwapKeyCode)) {
								tree.swapKeyCode(from, to);
								treeSwap(itm);
								_cards.showSelection;
							}
						}
					}
				}
			}
		}
	}
	void up() {
		up(selection, true);
	}
	private void up(TreeItem itm, bool store) {
		if (_etree.isFocusControl) {
			_etree.up;
		} else if (_cards.isFocusControl) {
			__ud!("before(parent, from)", "to >= 0")(itm, &treeItemUp, store);
		}
	}
	void down() {
		down(selection, true);
	}
	private void down(TreeItem itm, bool store) {
		if (_etree.isFocusControl) {
			_etree.down;
		} else if (_cards.isFocusControl) {
			__ud!("after(parent, from)", "to < keyCodeLen")(itm, &treeItemDown, store);
		}
	}

	private void setupToolBar(ToolBar bar) {
		_toolbar = bar;
		createToolItem(bar, _prop.msgs.ttUndo, _prop.images.menuUndo, &undo);
		createToolItem(bar, _prop.msgs.ttRedo, _prop.images.menuRedo, &redo);
		new ToolItem(bar, DWT.SEPARATOR);
		createToolItem(bar, _prop.msgs.ttUp, _prop.images.menuUp, &up);
		createToolItem(bar, _prop.msgs.ttDown, _prop.images.menuDown, &down);
		new ToolItem(bar, DWT.SEPARATOR);
		{
			auto treeKindItm = new ToolItem(bar, DWT.SEPARATOR);
			_treeKind = new CCombo(bar, DWT.READ_ONLY | DWT.DROP_DOWN | DWT.BORDER);
			_treeKind.add(_prop.msgs.eventTreeKindSystem);
			_treeKind.setText = _prop.msgs.eventTreeKindSystem;
			static if (is (A == Area) || is (A == Battle)) {
				_treeKind.add(_prop.msgs.eventTreeKindKeyCode);
			}
			static if (is (A == Battle)) {
				_treeKind.add(_prop.msgs.eventTreeKindRound);
			}
			treeKindItm.setControl = _treeKind;
			treeKindItm.setWidth = _treeKind.computeSize(DWT.DEFAULT, DWT.DEFAULT).x;
			_treeKind.addSelectionListener(new KSListener);
		}
		new ToolItem(bar, DWT.SEPARATOR);
		{
			_fireItm = new ToolItem(bar, DWT.SEPARATOR);
			_fireItm.setWidth = _prop.var.etc.firesWidth;
			createCombo(true, areaDefVals);
		}
		new ToolItem(bar, DWT.SEPARATOR);
		createToolItem(bar, _prop.msgs.ttNewEventTree, _prop.images.menuNewEventTree, &createEventTree);
		static if (UseFire) {
			createToolItem(bar, _prop.msgs.ttNewEventFire, _prop.images.menuNewEventFire, &createEventFire);
		}
		new ToolItem(bar, DWT.SEPARATOR);
		createToolItem(bar, _prop.msgs.ttNewTreeOpen, _prop.images.menuTreeOpen, &_etree.treeOpen);
		createToolItem(bar, _prop.msgs.ttNewTreeClose, _prop.images.menuTreeClose, &_etree.treeClose);
	}
	private void setFireControl(Control c) {
		if (_fireItm.getControl) _fireItm.getControl.dispose;
		_fireItm.setControl = c;
	}
	private string[] areaDefVals() {
		static if (is (A == Area)) {
			return [_prop.msgs.startEnter];
		} else static if (is (A == Battle)) {
			return [_prop.msgs.startVictory, _prop.msgs.startEscape, _prop.msgs.startLose];
		} else static if (is (A == Package)) {
			return [_prop.msgs.startPackage];
		} else {
			return [_prop.msgs.startUse];
		}
	}
	private string[] startDefVals() {
		auto itm = selectionParent;
		if (!itm) return [];
		auto data = itm.getData;
		string[] vals;
		if (cast(A) data) {
			return areaDefVals;
		} else {
			static if (!is (C == void)) {
				assert (cast(C) data);
				static if (is (C == MenuCard)) {
					return [_prop.msgs.startSelect];
				} else {
					assert (is (C == EnemyCard));
					return [_prop.msgs.startDead];
				}
			} else {
				assert (0);
			}
		}
	}
	private void createCombo(bool readOnly, string[] vals, bool visLong = false) {
		int style = DWT.BORDER | DWT.DROP_DOWN;
		if (readOnly) style |= DWT.READ_ONLY;
		auto c = new CCombo(_toolbar, style);
		if (visLong) c.setVisibleItemCount = 20;
		foreach (i, v; vals) {
			c.add(v);
			if (i == 0) c.setText = v;
		}
		setFireControl(c);
	}
	static if (is (A == Area) || is (A == Battle)) {
		private void refKeyCodes() {
			if (_treeKind.getSelectionIndex == 1) {
				auto combo = cast(CCombo) _fireItm.getControl;
				combo.removeAll;
				foreach (i, v; _prop.var.etc.standardKeyCodes) {
					combo.add(v);
					if (i == 0) combo.setText = v;
				}
			}
		}
	}
	private class KSListener : SelectionAdapter {
	public:
		override void widgetSelected(SelectionEvent e) {
			static if (is (A == Area)) {
				switch (_treeKind.getSelectionIndex) {
				case 0:
					createCombo(true, startDefVals);
					break;
				case 1:
					createCombo(false, _prop.var.etc.standardKeyCodes, true);
					break;
				}
			} else static if (is (A == Battle)) {
				switch (_treeKind.getSelectionIndex) {
				case 0:
					createCombo(true, startDefVals);
					break;
				case 1:
					createCombo(false, _prop.var.etc.standardKeyCodes, true);
					break;
				case 2:
					auto spn = new Spinner(_toolbar, DWT.BORDER);
					spn.setMaximum = 9999;
					spn.setMinimum = 1;
					spn.setSelection = 1;
					setFireControl = spn;
					break;
				}
			}
		}
	}

	void openToolWindow() {
		_etree.openToolWindow;
	}
	void closeToolWindow() {
		_etree.closeToolWindow;
	}

	override {
		void cut() {
			if (_etree.isFocusControl) {
				_etree.cut;
			} else {
				copy;
				del;
			}
		}
		void copy() {
			if (_etree.isFocusControl) {
				_etree.copy;
			} else {
				auto itm = selection;
				if (!itm) return;
				auto parItm = itm.getParentItem;
				if (!parItm) return;
				auto par = parItm.getData;
				auto data = itm.getData;
				string xml;
				if (cast(EventTree) data) {
					xml = (cast(EventTree) data).toXML;
				} else {
					static if (UseFire) {
						if (ENTER is data) {
							xml = EventTree.enterToXML;
						} else if (ESCAPE is data) {
							xml = EventTree.escapeToXML;
						} else if (LOSE is data) {
							xml = EventTree.loseToXML;
						} else if (cast(KeyCodeObj) data) {
							xml = EventTree.keyCodeToXML((cast(KeyCodeObj) data).array);
						} else if (cast(RoundObj) data) {
							xml = EventTree.roundToXML((cast(RoundObj) data).intValue);
						} else {
							assert (0);
						}
					} else {
						assert (0);
					}
				}
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(_prop, cb, xml);
			}
		}
		void paste() {
			if (_etree.isFocusControl) {
				_etree.paste;
			} else {
				auto itm = selection;
				if (!itm) return;
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				auto xml = CBtoXML(cb);
				if (!xml) return;
				auto parItm = selectionParent;
				if (parItm) {
					auto par = cast(EventTreeOwner) parItm.getData;
					EventTree tree = EventTree.fromXML(xml, LATEST_VERSION);
					if (tree) {
						storeI(_cards.indexOf(parItm), par.trees.length);
						// イベントツリー
						par.add(tree);
						auto treeItm = createTreeItem(parItm, tree, tree.name, _prop.images.eventTree);
						__select(treeItm);
						static if (UseFire) {
							refreshFires(treeItm);
						}
					} else {
						static if (UseFire) {
							if (!(cast(EventTreeOwner) itm.getData)) {
								// 開始条件
								auto treeItm = cast(EventTree) itm.getData ? itm : itm.getParentItem;
								tree = cast(EventTree) treeItm.getData;
								store(tree);
								if (tree.enterFromXML(par, xml)) {
									refreshFires(treeItm, ENTER);
								} else if (tree.escapeFromXML(par, xml)) {
									refreshFires(treeItm, ESCAPE);
								} else if (tree.loseFromXML(par, xml)) {
									refreshFires(treeItm, LOSE);
								} else {
									int round = tree.roundFromXML(par, xml);
									if (round >= 0) {
										refreshFires(treeItm, new RoundObj(round));
									} else {
										string keyCode = tree.keyCodeFromXML(par, xml);
										if (keyCode) {
											refreshFires(treeItm, new KeyCodeObj(keyCode));
										}
									}
								}
							}
						}
					}
				}
			}
		}
		void del() {
			if (_etree.isFocusControl) {
				_etree.del;
			} else {
				auto itm = selection;
				if (!itm) return;
				auto parItm = itm.getParentItem;
				if (!parItm) return;
				auto par = parItm.getData;
				auto data = itm.getData;
				auto tree = cast(EventTree) data;
				if (tree) {
					storeD(tree);
					(cast(EventTreeOwner) par).remove(tree);
					if (_selItm is itm) {
						_selItm = null;
						_etree.refresh(null);
					}
				} else {
					static if (UseFire) {
						tree = cast(EventTree) par;
						store(tree);
						if (ENTER is data) {
							tree.enter = false;
						} else if (ESCAPE is data) {
							tree.escape = false;
						} else if (LOSE is data) {
							tree.lose = false;
						} else if (cast(KeyCodeObj) data) {
							tree.removeKeyCode((cast(KeyCodeObj) data).array);
						} else if (cast(RoundObj) data) {
							tree.removeRound((cast(RoundObj) data).intValue);
						} else {
							assert (0);
						}
					}
				}
				itm.dispose;
				_comm.refUseCount.call;
			}
		}
		bool canDoTCPD() {
			return _cards.isFocusControl || _etree.isFocusControl;
		}
	}
	void undo() {_undo.undo;}
	void redo() {_undo.redo;}

	bool openCWXPath(string path) {
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool open(TreeItem itm) {
			if (index >= itm.getItemCount) {
				return false;
			}
			__select(itm.getItem(index));
			return _etree.openCWXPath(cpbottom(path));
		}
		static if (is(C : MenuCard) || is(C : EnemyCard)) {
			bool card() {
				if (index + 1 >= _cards.getItemCount) {
					return false;
				}
				auto itm = _cards.getItem(index + 1);
				path = cpbottom(path);
				cate = cpcategory(path);
				index = cpindex(path);
				return open(itm);
			}
		}
		switch (cate) {
		case "event": {
			return open(_cards.getItem(0));
		} break;
		case "menucard": {
			static if (is(C : MenuCard)) {
				return card;
			}
		} break;
		case "enemycard": {
			static if (is(C : EnemyCard)) {
				return card;
			}
		} break;
		case "": {
			.forceFocus(_cards);
			return true;
		} break;
		default: break;
		}
		return false;
	}
}

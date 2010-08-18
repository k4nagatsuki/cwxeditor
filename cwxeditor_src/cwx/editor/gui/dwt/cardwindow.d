
module cwx.editor.gui.dwt.cardwindow;

import cwx.card;
import cwx.summary;
import cwx.utils;
import cwx.usecounter;
import cwx.types;
import cwx.xml;
import cwx.skin;

import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.cardlist;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.castcarddialog;
import cwx.editor.gui.dwt.effectcarddialog;
import cwx.editor.gui.dwt.infocarddialog;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.commons;

import std.utf;
import std.string;
import std.date;
import std.typetuple;

import dwt.widgets.Shell;
import dwt.widgets.Display;
import dwt.widgets.Control;
import dwt.widgets.Composite;
import dwt.widgets.TabFolder;
import dwt.widgets.TabItem;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.widgets.MessageBox;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.layout.GridData;
import dwt.layout.FillLayout;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.ShellAdapter;
import dwt.events.ShellEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.events.MouseAdapter;
import dwt.events.MouseEvent;
import dwt.events.KeyAdapter;
import dwt.events.KeyEvent;
import dwt.events.ControlAdapter;
import dwt.events.ControlEvent;
import dwt.dwthelper.utils;
import dwt.dnd.DND;
import dwt.dnd.ByteArrayTransfer;
import dwt.dnd.FileTransfer;
import dwt.dnd.DragSource;
import dwt.dnd.DragSourceAdapter;
import dwt.dnd.DragSourceEvent;
import dwt.dnd.DropTarget;
import dwt.dnd.DropTargetAdapter;
import dwt.dnd.DropTargetEvent;
import dwt.dnd.Clipboard;

import dwtx.jface.dialogs.Dialog;
import dwtx.jface.dialogs.IDialogConstants;

public:

private class CardPane(PCardOwner, CardOwner, C : Card, ToCardOwner, string GetAll, string GetFromId) : TCPD {
private:
	static const bool EditMode = is (ToCardOwner == void);
	private C[] cards() {mixin ("return owner." ~ GetAll ~ ";");}
	private C[] __cards() {
		if (_owner) {
			return cards;
		}
		return [];
	}
	private C card(ulong id) {mixin ("return owner." ~ GetFromId ~ "(id);");}
	private C __card(ulong id) {
		if (_owner) {
			return card(id);
		}
		return null;
	}
private:
	string _id;
	Commons _comm;
	Props _prop;
	CardOwner _owner = null;
	PCardOwner _summ = null;
	void delegate(Shell) _save;
	CardList!(C) _list;
	Table _tbl;
	Image _cimg;
	bool _viewList = true;
	TCPD[] _tcpd;
	static if (!EditMode) {
		ToCardOwner _toc;
	}

	void __refreshR(string from, string to) {
		__refresh;
	}
	void __refresh() {
		if (_viewList) {
			_list.refresh(__cards, &__cardImage);
			int sel = _list.selection;
			if (sel >= 0) {
				_list.scroll(sel);
			}
		} else {
			C sel = null;
			auto sels = _tbl.getSelection;
			if (sels.length > 0) {
				sel = cast(C) sels[0].getData;
			}
			_tbl.removeAll;
			foreach (i, c; __cards) {
				createTableItem(c);
				if (sel is c) {
					_tbl.setSelection = [i];
				}
			}
			_tbl.showSelection;
		}
	}
	void select(int index) {
		if (_viewList) {
			_list.select(index);
			_list.scroll(index);
		} else {
			_tbl.select(index);
			_tbl.showSelection;
		}
	}
	void createTableItem(C c, int index = -1) {
		auto itm = index >= 0
			? new TableItem(_tbl, DWT.NONE, index)
			: new TableItem(_tbl, DWT.NONE);
		itm.setImage(0, _cimg);
		itm.setText(0, to!(string)(c.id));
		itm.setText(1, c.name);
		if (c.desc.length > 0) {
			// FIXME: セルの値が長すぎると表示されないことがあるので自らカット
			string desc = std.string.replace(c.desc, "\n", "");
			dstring ddesc = toUTF32(desc);
			if (ddesc.length > 50) {
				desc = toUTF8(ddesc[0 .. 50] ~ "...");
			}
			itm.setText(2, desc);
		}
		static if (is (CardOwner == Summary)) {
			itm.setText(3, to!(string)(_summ.useCounter.get(C.toID(c.id))));
		}
		itm.setData = c;
	}
	template CopyAndPaste() {
		override void cut() {
			static if (EditMode) {
				copy;
				del;
			}
		}
		override void copy() {
			auto cs = __selections;
			if (cs.length > 0) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(_prop, cb, toXML(cs));
			}
		}
		override void paste() {
			static if (EditMode) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				auto c = CBtoXML(cb);
				if (c) {
					try {
						auto node = XNode.parse(c);
						if (node.name != C.XML_NAME_M) return;
						addFromNode(node, LATEST_VERSION);
					} catch {}
				}
			}
		}
		override bool canDoTCPD() {
			return widget.isFocusControl;
		}
	}
	class CL : TCPD {
		CardList!(C) widget() {
			return _list;
		}
		C selectionCard() {
			return _list.selectionCard;
		}
		mixin CopyAndPaste;
		override void del() {
			static if (EditMode) {
				auto c = selectionCard;
				if (c) {
					_owner.remove(c);
					refresh;
					delCard(c);
					_comm.refUseCount.call;
				}
			}
		}
	}
	void refCard(C c) {
		static if (is (C == CastCard)) {
			_comm.refCast.call(c);
		} else static if (is (C == SkillCard)) {
			_comm.refSkill.call(c);
		} else static if (is (C == ItemCard)) {
			_comm.refItem.call(c);
		} else static if (is (C == BeastCard)) {
			_comm.refBeast.call(c);
		} else static if (is (C == InfoCard)) {
			_comm.refInfo.call(c);
		} else {
			static assert (0);
		}
	}
	void delCard(C c) {
		static if (is (C == CastCard)) {
			foreach (hc; c.skills) {
				_comm.delSkill.call(hc);
			}
			foreach (hc; c.items) {
				_comm.delItem.call(hc);
			}
			foreach (hc; c.beasts) {
				_comm.delBeast.call(hc);
			}
			_comm.delCast.call(c);
		} else static if (is (C == SkillCard)) {
			_comm.delSkill.call(c);
		} else static if (is (C == ItemCard)) {
			_comm.delItem.call(c);
		} else static if (is (C == BeastCard)) {
			_comm.delBeast.call(c);
		} else static if (is (C == InfoCard)) {
			_comm.delInfo.call(c);
		} else {
			static assert (0);
		}
	}
	class CT : TCPD {
		Table widget() {
			return _tbl;
		}
		C selectionCard() {
			auto sels = _tbl.getSelection;
			return sels.length > 0 ? cast(C) sels[0].getData : null;
		}
		mixin CopyAndPaste;
		override void del() {
			static if (EditMode) {
				auto c = selectionCard;
				if (c) {
					_owner.remove(c);
					_tbl.getSelection[0].dispose;
					_tbl.redraw;
					delCard(c);
					_comm.refUseCount.call;
				}
			}
		}
	}
	static if (EditMode) {
		template Drop() {
			override void drop(DropTargetEvent e){
				if (!isXMLBytes(e.data)) return;
				e.detail = DND.DROP_NONE;
				string xml = bytesToXML(e.data);
				try {
					auto node = XNode.parse(xml);
					if (node.name != C.XML_NAME_M) return;
					scope p = (cast(DropTarget) e.getSource).getControl.toControl(e.x, e.y);
					int index = indexOf(p);
					bool samePane = _id == node.attr("paneId", false);
					bool sameSc = ownerId == node.attr("summId", false);
					if (sameSc && samePane) {
						// 同一リスト内で移動。
						int count = cardCount;
						if (count < index) index = count;
						if ((index < count ? index : count - 1) == selectionIndex
								|| index == selectionIndex + 1) {
							selectOnly(index);
							return;
						}
						C[] adds;
						node.onTag[C.XML_NAME] = (ref XNode cNode) {
							auto id = Card.readId(cNode);
							if (id == 0UL) return;
							adds ~= this.outer.__card(id);
							e.detail = DND.DROP_NONE;
						};
						node.parse;
						if (adds.length == 0) return;
						foreach (ref card; adds) {
							static if (is(CardOwner == CastCard)) {
								card = _owner.insert(index, card);
							} else {
								_owner.insert(index, card);
							}
							index++;
						}
						insert(adds[$ - 1], true);
					} else {
						e.detail = DND.DROP_NONE;
						// 他のリストからのコピー
						if (cardCount < index) index = cardCount;
						C[] adds;
						node.onTag[C.XML_NAME] = (ref XNode cNode) {
							auto card = C.createFromNode(cNode, LATEST_VERSION);
							adds ~= card;
						};
						node.parse;
						if (adds.length == 0) return;
						if (__qMaterialCopy(node, adds)) {
							foreach (ref card; adds) {
								_owner.insert(index, card);
								card = cards[index];
								index++;
							}
							insert(adds[$ - 1], false);
							_comm.refUseCount.call;
						}
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		class CLDTListener : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_MOVE;
			}
			override void dragOver(DropTargetEvent e){
				e.detail = DND.DROP_MOVE;
			}
			mixin Drop;
			private int selectionIndex() {
				return _list.selection;
			}
			private int indexOf(Point p) {
				return _list.searchIndexLoose(p.x, p.y);
			}
			private int cardCount() {
				return _list.count;
			}
			private void selectOnly(int index) {
				_list.scroll(index);
			}
			private void insert(C c, bool move) {
				refresh;
				int index = _list.indexOf(c);
				_list.select(index);
				_list.scroll(index);
			}
		}
		class CTDTListener : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_MOVE;
			}
			override void dragOver(DropTargetEvent e){
				e.detail = DND.DROP_MOVE;
			}
			mixin Drop;
			private int selectionIndex() {
				return _tbl.getSelectionIndex;
			}
			private int indexOf(Point p) {
				auto itm = _tbl.getItem(p);
				return itm ? _tbl.indexOf(itm) : _tbl.getItemCount;
			}
			private int cardCount() {
				return _tbl.getItemCount;
			}
			private void selectOnly(int index) {
				_tbl.showSelection;
			}
			private void insert(C c, bool move) {
				refresh;
				foreach (i, itm; _tbl.getItems) {
					if (c is itm.getData) {
						_tbl.setSelection = [i];
						_tbl.showSelection;
						return;
					}
				}
				assert (0);
			}
		}
	}
	class CDSListener : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource).getControl.isFocusControl
				&& __selections.length > 0;
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance.isSupportedType(e.dataType)) {
				Control c = (cast(DragSource) e.getSource).getControl;
				C[] sels = __selections;
				if (sels.length > 0) {
					e.data = bytesFromXML(toXML(sels));
				}
			}
		}
	}
	bool __qMaterialCopy(in XNode node, C[] cs) {
		string fromSPath = node.attr("scenarioPath", false);
		if (fromSPath.length > 0 && !std.path.fnmatch(fromSPath, nabs(ownerScenarioPath))) {
			scope uc = new UseCounter;
			foreach (c; cs) {
				c.setUseCounter = uc;
			}
			bool copy;
			auto skin = findSkin(_prop, _summ);
			bool r = qMaterialCopy(_prop, skin, _list.getShell,
				uc, _summ.scenarioPath, fromSPath, copy, _summ.legacy);
			foreach (c; cs) {
				c.removeUseCounter;
			}
			if (copy) {
				_comm.refPaths.call(skin.materialPath);
			}
			return r;
		}
		return true;
	}

	string ownerScenarioPath() {
		static if (is (CardOwner == CastCard)) {
			return _summ.scenarioPath;
		} else {
			return _owner.scenarioPath;
		}
	}
	string ownerId() {
		static if (is (CardOwner == CastCard)) {
			return _summ.id;
		} else {
			return _owner.id;
		}
	}
	ImageData __cardImage(C c) {
		auto skin = .findSkin(_prop, _summ);
		static if (is (C == CastCard)) {
			return castCardImage(_prop, skin, c, ownerScenarioPath);
		} else static if (!is (C == InfoCard) && is (CardOwner == CastCard)) {
			return cardImage!(C)(_prop, skin, c, ownerScenarioPath, _owner);
		} else {
			return cardImage!(C)(_prop, skin, c, ownerScenarioPath, cast(CastCard) null);
		}
	}

	static if (EditMode) {
		void edit(C c) {
			static if (is (C == CastCard)) {
				auto dlg = new CastCardDialog(_comm, _prop, _list.getShell, _summ, c);
			} else static if (is (C : EffectCard)) {
				auto dlg = new EffectCardDialog!(C)(_comm, _prop, _list.getShell, _summ, c);
			} else static if (is (C == InfoCard)) {
				auto dlg = new InfoCardDialog(_comm, _prop, _list.getShell, _summ, c);
			} else {
				static assert (0, typeof(C));
			}
			if (IDialogConstants.OK_ID == dlg.open) {
				refresh;
				refCard(c);
			}
		}
	}
	string cardToolTip(C c) {
		static if (is (C == SkillCard) && is (CardOwner == CastCard)) {
			return __handsToolTip(c, __cards.length, &_prop.looks.skillCardMaxNum);
		} else static if (is (C == ItemCard) && is (CardOwner == CastCard)) {
			return __handsToolTip(c, __cards.length, &_prop.looks.itemCardMaxNum);
		} else static if (is (C == BeastCard) && is (CardOwner == CastCard)) {
			return __handsToolTip(c, __cards.length, &_prop.looks.beastCardMaxNum);
		} else {
			return __toolTip(c, __cards.length);
		}
	}
	static if (EditMode) {
		static if (is (C == CastCard)) {
			void editHand() {
				auto sel = __selection;
				if (sel) {
					_comm.openHands(_prop, _summ, sel);
				}
			}
		}
		static if (is (C : EffectCard)) {
			void editUseEvent() {
				auto sel = __selection;
				if (sel) {
					_comm.openUseEvents(_prop, _summ, sel);
				}
			}
		}
	}

	C[] __selections() {
		if (_viewList) {
			return _list.selectionCards;
		} else {
			C[] r;
			auto sels = _tbl.getSelection;
			r.length = sels.length;
			foreach (i, itm; sels) {
				r[i] = cast(C) sels[i].getData;
			}
			return r;
		}
	}
	C __selection() {
		if (_viewList) {
			return _list.selectionCard;
		} else {
			return _tbl.getSelectionIndex >= 0 ? cast(C) _tbl.getSelection[0].getData : null;
		}
	}
	void __refList() {
		auto sels = _tbl.getSelectionIndices;
		int index = -1;
		if (sels.length > 0) {
			index = sels[0];
		}
		refresh();
		if (index >= 0) {
			_list.select(index);
			_list.scroll(index);
		} else {
			_list.deselectAll;
		}
	}
	void __refTbl() {
		int index = _list.selection;
		refresh();
		if (index >= 0) {
			_tbl.setSelection = [index];
			_tbl.showSelection;
		}
	}
	string __toolTip(C c, int count) {
		if (c) {
			return null;
		} else {
			return _prop.msgs.cardListToolTip(count);
		}
	}
	static if (is (CardOwner == CastCard)) {
		string __handsToolTip(C c, int count, uint delegate(uint) max) {
			if (c) {
				return null;
			} else if (owner) {
				return _prop.msgs.handCardListToolTip(count, max(owner.level));
			} else {
				return "";
			}
		}
	}
	void toNode(ref XNode sn, C[] sels) {
		sn.newAttr("summId", ownerId);
		sn.newAttr("paneId", _id);
		sn.newAttr("scenarioPath", nabs(ownerScenarioPath));
		foreach (sel; sels) {
			sel.toNode(sn);
		}
	}
	string toXML(C[] sels) {
		auto doc = XNode.create(C.XML_NAME_M);
		toNode(doc, sels);
		return doc.text;
	}
	class LMouse : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			int index = _list.selection;
			if (index >= 0) {
				scope p = _list.toControl(e.x, e.y);
				if (_list.getBounds(index).contains(e.x, e.y)) {
					static if (EditMode) {
						edit(_list.card(index));
					} else {
						addCard;
					}
				}
			}
		}
	}
	class TMouse : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			int index = _tbl.getSelectionIndex;
			if (index >= 0) {
				scope p = _tbl.toControl(e.x, e.y);
				auto itm = _tbl.getItem(index);
				for (int i = 0; i < _tbl.getColumnCount; i++) {
					if (itm.getBounds(i).contains(e.x, e.y)) {
						static if (EditMode) {
							edit(cast(C) _tbl.getSelection[0].getData);
						} else {
							addCard;
						}
						break;
					}
				}
			}
		}
	}
	class LKey : KeyAdapter {
		override void keyPressed(KeyEvent e) {
			if ((e.keyCode == DWT.F2 || e.character == DWT.CR) && _list.selection >= 0) {
				static if (EditMode) {
					edit(_list.selectionCard);
				} else {
					addCard;
				}
			}
		}
	}
	class TKey : KeyAdapter {
		override void keyPressed(KeyEvent e) {
			if ((e.keyCode == DWT.F2 || e.character == DWT.CR) && _tbl.getSelectionIndex >= 0) {
				static if (EditMode) {
					edit(cast(C) _tbl.getSelection[0].getData);
				} else {
					addCard;
				}
			}
		}
	}
	void createCardList(Composite parent) {
		_list = new CardList!(C)(parent, DWT.V_SCROLL | (EditMode ? DWT.SINGLE : DWT.MULTI) | DWT.BORDER);
		_tbl = new Table(parent, DWT.FULL_SELECTION | (EditMode ? DWT.SINGLE : DWT.MULTI) | DWT.BORDER);
		_tbl.setHeaderVisible = true;
		auto idCol = new TableColumn(_tbl, DWT.NONE);
		idCol.setText = _prop.msgs.cardId;
		saveColumnWidth!("prop.var.etc.cardIdColumn")(_prop, idCol);
		auto nameCol = new TableColumn(_tbl, DWT.NONE);
		nameCol.setText = _prop.msgs.cardName;
		saveColumnWidth!("prop.var.etc.cardNameColumn")(_prop, nameCol);
		auto descCol = new TableColumn(_tbl, DWT.NONE);
		descCol.setText = _prop.msgs.cardDesc;
		saveColumnWidth!("prop.var.etc.cardDescriptionColumn")(_prop, descCol);
		static if (is (CardOwner == Summary)) {
			auto ucCol = new TableColumn(_tbl, DWT.NONE);
			ucCol.setText = _prop.msgs.cardCount;
			saveColumnWidth!("prop.var.etc.cardCountColumn")(_prop, ucCol);
		}

		static if (is (C == CastCard)) {
			auto matPad = _prop.looks.castCardInsets;
		} else {
			auto matPad = _prop.looks.menuCardInsets;
		}
		auto cl_ = new CL;
		_tcpd ~= cl_;
		int w = _prop.looks.cardSize.width + matPad.e + matPad.w;
		int h = _prop.looks.cardSize.height + matPad.n + matPad.s;
		_list.setToolTip = &cardToolTip;
		_list.setCardSize(w, h);

		auto ct_ = new CT;
		_tcpd ~= ct_;

		void setupDrag(Control c) {
			static if (is (C == CastCard)) {
				auto drag = new DragSource(c, DND.DROP_MOVE | DND.DROP_COPY | DND.DROP_LINK);
			} else {
				auto drag = new DragSource(c, DND.DROP_MOVE | DND.DROP_COPY);
			}
			drag.setTransfer([XMLBytesTransfer.getInstance]);
			drag.addDragListener(new CDSListener);
		}
		setupDrag(_list);
		setupDrag(_tbl);

		_list.addMouseListener(new LMouse);
		_list.addKeyListener(new LKey);
		_tbl.addMouseListener(new TMouse);
		_tbl.addKeyListener(new TKey);
		static if (EditMode) {
			auto dropL = new DropTarget(_list, DND.DROP_DEFAULT | DND.DROP_MOVE);
			dropL.setTransfer([XMLBytesTransfer.getInstance]);
			dropL.addDropListener(new CLDTListener);
			auto dropT = new DropTarget(_tbl, DND.DROP_DEFAULT | DND.DROP_MOVE);
			dropT.setTransfer([XMLBytesTransfer.getInstance]);
			dropT.addDropListener(new CTDTListener);
		}
		__refList;
	}
	static if (is (C == CastCard) && !EditMode) {
		private void delegate() _openHand;
	}
	private void construct(Commons comm, Props prop, PCardOwner summ, Composite parent) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(getUTCtime);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		createCardList(parent);
		static if (is (PCardOwner == Summary)) {
			_comm.refSkin.add(&__refresh);
			_comm.delPaths.add(&__refresh);
			_comm.replPath.add(&__refreshR);
			_comm.replText.add(&__refresh);
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					_comm.refSkin.remove(&__refresh);
					_comm.delPaths.remove(&__refresh);
					_comm.replPath.remove(&__refreshR);
					_comm.replText.remove(&__refresh);
				}
			});
		}
		static if (is (CardOwner == Summary)) {
			_comm.refUseCount.add(&__refreshUseCount);
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					_comm.refUseCount.remove(&__refreshUseCount);
				}
			});
		}
		static if (EditMode) {
			static if (is (C == CastCard)) {
				auto pop = new Menu(parent.getShell, DWT.POP_UP);
				createMenuItem(pop, _prop.msgs.menuEditHand, _prop.images.menuEditHand, &editHand);
				new MenuItem(pop, DWT.SEPARATOR);
				appendMenuTCPD(_prop, pop, this);
			} else static if (is (C == SkillCard) || is (C == ItemCard) || is (C == BeastCard)) {
				auto pop = new Menu(parent.getShell, DWT.POP_UP);
				createMenuItem(pop, _prop.msgs.menuEditUseEvent, _prop.images.menuEditUseEvent, &editUseEvent);
				new MenuItem(pop, DWT.SEPARATOR);
				appendMenuTCPD(_prop, pop, this);
			} else static if (is (C == InfoCard)) {
				auto pop = new Menu(parent.getShell, DWT.POP_UP);
				appendMenuTCPD(_prop, pop, this);
			} else {
				static assert (0);
			}
		} else {
			auto pop = new Menu(parent.getShell, DWT.POP_UP);
			static if (is (C == CastCard)) {
				createMenuItem(pop, _prop.msgs.menuOpenHand, _prop.images.menuOpenHand, _openHand);
				new MenuItem(pop, DWT.SEPARATOR);
			}
			createMenuItem(pop, _prop.msgs.menuAdd, _prop.images.menuAdd, &addCard);
			new MenuItem(pop, DWT.SEPARATOR);
			appendMenuTCPD(_prop, pop, this, false, true, false, false);
		}
		_list.setMenu = pop;
		_tbl.setMenu = pop;
	}
public:
	static if (!EditMode) {
		static if (is (C == CastCard)) {
			this(Commons comm, Props prop, PCardOwner summ, Composite parent, ToCardOwner toc, void delegate() openHand) {
				_toc = toc;
				_openHand = openHand;
				construct(comm, prop, summ, parent);
			}
		} else {
			this(Commons comm, Props prop, PCardOwner summ, Composite parent, ToCardOwner toc) {
				_toc = toc;
				construct(comm, prop, summ, parent);
			}
		}
	} else static if (is (C : Card)) {
		this(Commons comm, Props prop, PCardOwner summ, Composite parent) {
			static if (is (C == SkillCard)) {
				_cimg = prop.images.casts;
			} else static if (is (C == SkillCard)) {
				_cimg = prop.images.skill;
			} else static if (is (C == ItemCard)) {
				_cimg = prop.images.item;
			} else static if (is (C == BeastCard)) {
				_cimg = prop.images.beast;
			} else static if (is (C == InfoCard)) {
				_cimg = prop.images.info;
			}
			construct(comm, prop, summ, parent);
		}
	} else {
		static assert (0);
	}
	CardOwner owner() {
		return _owner;
	}
	PCardOwner summary() {
		return _summ;
	}
	Control widget() {
		if (_viewList) {
			return _list;
		} else {
			return _tbl;
		}
	}
	void refresh() {
		if (_owner) {
			__refresh;
		}
	}
	void showCardList() {
		if (!_viewList) {
			_viewList = true;
			__refList;
		}
	}
	void showCardTable() {
		if (_viewList) {
			_viewList = false;
			__refTbl;
		}
	}
	static if (EditMode) {
		void create() {
			static if (is (C == CastCard)) {
				auto dlg = new CastCardDialog(_comm, _prop, _list.getShell, _summ, null);
			} else static if (is (C : EffectCard)) {
				auto dlg = new EffectCardDialog!(C)(_comm, _prop, _list.getShell, _summ, null);
			} else static if (is (C == InfoCard)) {
				auto dlg = new InfoCardDialog(_comm, _prop, _list.getShell, _summ, null);
			} else {
				static assert (0);
			}
			if (IDialogConstants.OK_ID == dlg.open) {
				_owner.add(dlg.card);
				refresh;
				select(__cards.length - 1);
			}
		}
		static if (is (CardOwner == Summary)) {
			private void __refreshUseCount() {
				if (!_viewList) {
					foreach (itm; _tbl.getItems) {
						auto c = cast(C) itm.getData;
						itm.setText(3, to!(string)(_summ.useCounter.get(C.toID(c.id))));
					}
				}
			}
		}
		bool addFromNode(ref XNode node, string ver) {
			C[] adds;
			static if (is (CardOwner == Summary)) bool ids = false;
			if (node.attr("summId", false) != ownerId) {
				node.onTag[C.XML_NAME] = (ref XNode cNode) {
					adds ~= C.createFromNode(cNode, ver);
				};
				node.parse;
				if (!__qMaterialCopy(node, adds)) return false;
			} else {
				node.onTag[C.XML_NAME] = (ref XNode cNode) {
					auto card = C.createFromNode(cNode, ver);
					if (cNode.attr("paneId", false) != _id || __card(card.id)) {
						adds ~= card;
					} else {
						static if (is (CardOwner == Summary)) ids = true;
						adds ~= card;
					}
				};
				node.parse;
			}
			if (adds.length == 0) return false;
			foreach (card; adds) {
				static if (is (CardOwner == Summary)) {
					ulong oldId = _owner.add(card);
					if (ids) {
						_owner.useCounter.change(C.toID(oldId), C.toID(card.id));
					}
				} else {
					_owner.add(card);
				}
			}
			pasteRefresh(adds);
			_comm.refUseCount.call;
			return true;
		}
		void pasteRefresh(C[] cs) {
			if (_viewList) {
				refresh;
				_list.select(_list.count - 1);
				_list.scroll(_list.count - 1);
			} else {
				foreach (c; cs) {
					createTableItem(c);
				}
				_tbl.setSelection = [_tbl.getItemCount - 1];
				_tbl.showSelection;
			}
		}
	} else {
		private void delegate(ref XNode, string) _addc;
		void setAddCard(void delegate(ref XNode, string) addc) {
			_addc = addc;
		}
		void delegate(ref XNode, string) getAddCard() {
			return _addc;
		}
		void addCard() {
			C[] cs = __selections;
			auto doc = XNode.create(C.XML_NAME_M);
			toNode(doc, cs);
			_addc(doc, LATEST_VERSION);
		}
	}
	void refreshAll(PCardOwner summ, CardOwner owner) {
		_owner = owner;
		_summ = summ;
		refresh;
	}

	Table cardTable() {
		return _tbl;
	}

	override {
		void cut() {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.cut;
					}
				}
			}
		}
		void copy() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.copy;
				}
			}
		}
		void paste() {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.paste;
					}
				}
			}
		}
		void del() {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.del;
					}
				}
			}
		}
		bool canDoTCPD() {
			return _list.isVisible || _tbl.isVisible;
		}
	}
}

template CastCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, CastCard, ToCardOwner, "casts", "casts") CastCardPane;
}
template SkillCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, SkillCard, ToCardOwner, "skills", "skill") SkillCardPane;
}
template ItemCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, ItemCard, ToCardOwner, "items", "item") ItemCardPane;
}
template BeastCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, BeastCard, ToCardOwner, "beasts", "beast") BeastCardPane;
}
template InfoCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, InfoCard, ToCardOwner, "infos", "info") InfoCardPane;
}

class CardWindow(string Title, PCardOwner, CardOwner, ToCardOwner, Cards ...) : TCPD {
private:
	static const bool EditMode = is (ToCardOwner == void);
	static const bool UseCast = IndexOf!(CastCard, Cards) >= 0;
	static const bool UseSkill = IndexOf!(SkillCard, Cards) >= 0;
	static const bool UseItem = IndexOf!(ItemCard, Cards) >= 0;
	static const bool UseBeast = IndexOf!(BeastCard, Cards) >= 0;
	static const bool UseInfo = IndexOf!(InfoCard, Cards) >= 0;

	template Pane(Card) {
		mixin ("alias " ~ Card.stringof ~ "Pane!(PCardOwner, CardOwner, ToCardOwner) Pane;");
	}

	template CTypes(int Index, Cards ...) {
		static if (is(Cards[0] : CastCard)) {
			static const CAST = Index;
		} else static if (is(Cards[0] : SkillCard)) {
			static const SKILL = Index;
		} else static if (is(Cards[0] : ItemCard)) {
			static const ITEM = Index;
		} else static if (is(Cards[0] : BeastCard)) {
			static const BEAST = Index;
		} else static if (is(Cards[0] : InfoCard)) {
			static const INFO = Index;
		} else static assert (0);
		static if (Cards.length > 1) {
			mixin CTypes!(Index + 1, Cards[1 .. $]);
		}
	}
	mixin CTypes!(0, Cards);
	template PTypes(Cards ...) {
		static if (Cards.length > 1) {
			alias TypeTuple!(Pane!(Cards[0]),
				PTypes!(Cards[1 .. $])) PTypes;
		} else {
			alias TypeTuple!(Pane!(Cards[0])) PTypes;
		}
	}
	PTypes!(Cards) _pane;
	TabItem[Cards.length] _tab;

	Props _prop;
	Shell _win;
	TabFolder _tabf;
	PCardOwner _summ;
	CardOwner _owner;
	Commons _comm;

	MenuItem _listM;
	MenuItem _tblM;
	ToolItem _listT;
	ToolItem _tblT;

	TCPD[] _tcpd;

	static if (!EditMode) {
		ToCardOwner _toc;
	}
	static if (EditMode) {
		void create(int Index)() {
			_tabf.setSelection = _tab[Index];
			_pane[Index].create;
		}
	}

	void __refresh() {
		foreach (f; _pane) {
			f.refresh;
		}
		refreshTitle;
	}
	void saveScenario() {
		_comm.save.call(_win);
	}
	static if (EditMode && is (CardOwner == Summary)) {
		alias AddCard!(CardOwner, Cards) AC;
		HashSet!(Shell) _aws;
		void sac(int Index)(AC.ACW w) {
			w.setAdd!(Index)(&add!(Index));
			static if (Index + 1 < Cards.length) {
				sac!(Index + 1)(w);
			}
		}
		void __addScenario(Object[] ws) {
			foreach (wo; ws) {
				auto w = cast(AC.ACW) wo;
				sac!(0)(w);
				w.shell.addShellListener(new CloseRemover!(Shell)(_aws, w.shell));
				_aws.add(w.shell);
				w.open;
			}
		}
		void addScenario() {
			AC.openScenario(_comm, _prop, topShell(_win), _summ, _owner, &__addScenario);
		}
		class DropScenario : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_LINK;
			}
			override void drop(DropTargetEvent e) {
				auto arr = cast(FileNames) e.data;
				if (arr && arr.array.length > 0) {
					AC.openScenario(_comm, _prop, topShell(_win), _summ, _owner, arr.array, &__addScenario);
				}
			}
		}
	}
	static if (!EditMode) {
		void addCard() {
			foreach (i, f; _pane) {
				if (_tabf.getSelection[0] is _tab[i]) {
					f.addCard;
					return;
				}
			}
		}
	}
	void showCardList() {
		if (!_listM.getSelection) {
			_listM.setSelection = true;
			_listT.setSelection = true;
			_tblM.setSelection = false;
			_tblT.setSelection = false;

			foreach (i, f; _pane) {
				f.showCardList;
				_tab[i].setControl = f.widget;
			}

			static if (is (CardOwner == Summary)) {
				_prop.var.etc.cardDetails = false;
			}
		}
	}
	void showCardTable() {
		if (!_tblM.getSelection) {
			_listM.setSelection = false;
			_listT.setSelection = false;
			_tblM.setSelection = true;
			_tblT.setSelection = true;

			foreach (i, f; _pane) {
				f.showCardTable;
				_tab[i].setControl = f.widget;
			}

			static if (is (CardOwner == Summary)) {
				_prop.var.etc.cardDetails = true;
			}
		}
	}
	static if (UseCast && !EditMode) {
		HashSet!(AddHandCardWindow) _hws;
		void openHand() {
			auto sels = _pane[CAST].__selections;
			foreach (sel; sels) {
				foreach (w; _hws) {
					if (w.owner is sel) {
						w.shell.setMinimized = false;
						w.shell.setActive;
						return;
					}
				}
				auto hcw = new AddHandCardWindow
					(_comm, _prop, topShell(_win), _summ, sel, _toc);
				hcw.setAdd!(hcw.SKILL)(_pane[SKILL].getAddCard);
				hcw.setAdd!(hcw.ITEM)(_pane[ITEM].getAddCard);
				hcw.setAdd!(hcw.BEAST)(_pane[BEAST].getAddCard);
				_hws.add(hcw);
				hcw.shell.addShellListener(new CloseRemover!(AddHandCardWindow)(_hws, hcw));
				hcw.open;
			}
		}
	}
public:
	static if (EditMode) {
		static if (is (CardOwner == Summary)) {
			this(Commons comm, Props prop, Shell parent) {
				construct(comm, prop, null, parent);
			}
		} else {
			this(Commons comm, Props prop, PCardOwner summ, Shell parent) {
				construct(comm, prop, summ, parent);
			}
		}
		void construct(Commons comm, Props prop, PCardOwner summ, Shell parent) {
			construct1(comm, prop, parent);
			static if (is (CardOwner == Summary)) {
				_aws = new HashSet!(Shell);
				_win.addShellListener(new class ShellAdapter {
					override void shellClosed(ShellEvent e) {
						(cast(Shell) e.widget).setVisible = false;
						e.doit = false;
						_prop.var.cardWin.visible = false;
					}
				});
			}
			static if (is (CardOwner == CastCard) && is (PCardOwner == Summary)) {
				_comm.refCast.add(&__refOwner);
				_comm.delCast.add(&__delOwner);
				_win.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) {
						_comm.refCast.remove(&__refOwner);
						_comm.delCast.remove(&__delOwner);
					}
				});
			}
			construct2(prop);
			_comm.refScenarioName.add(&refreshTitle);
			_comm.refScenarioPath.add(&refreshTitle);
			_win.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					_comm.refScenarioName.remove(&refreshTitle);
					_comm.refScenarioPath.remove(&refreshTitle);
				}
			});
		}
		void newPane(int Index)() {
			_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf);
			static if (Index + 1 < Cards.length) {
				newPane!(Index + 1);
			}
		}
	} else {
		void newPane(int Index)() {
			static if (UseCast && Index == CAST) {
				_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, _toc, &openHand);
			} else {
				_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, _toc);
			}
			static if (Index + 1 < Cards.length) {
				newPane!(Index + 1);
			}
		}
		this(Commons comm, Props prop,
				Shell parent, PCardOwner summ, CardOwner owner, ToCardOwner toc) {
			_toc = toc;
			construct1(comm, prop, parent);
			static if (UseCast) {
				_hws = new HashSet!(AddHandCardWindow);
				_win.addShellListener(new class ShellAdapter {
					override void shellClosed(ShellEvent e) {
						foreach (w; _hws.toArray) {
							w.shell.close;
						}
					}
				});
			}
			_summ = summ;
			construct2(prop);
			__refreshAll(summ, owner);
		}
	}
	private void construct1(Commons comm, Props prop, Shell parent) {
		_comm = comm;
		_win = new Shell(parent, DWT.SHELL_TRIM);
		_win.setImage = prop.images.app;
		_win.setLayout = new FillLayout;
		auto comp = new Composite(_win, DWT.NONE);
		comp.setLayout = windowGridLayout(1, true);
		{
			auto bar = new Menu(_win, DWT.BAR);

			auto mf = createMenu(bar, prop.msgs.menuFile);
			static if (EditMode) {
				createMenuItem(mf, prop.msgs.menuSave, prop.images.menuSave, &saveScenario);
				new MenuItem(mf, DWT.SEPARATOR);
			}
			createMenuItem(mf, prop.msgs.menuCloseWin, prop.images.menuCloseWin, &_win.close);

			auto me = createMenu(bar, prop.msgs.menuEdit);
			static if (EditMode) {
				appendMenuTCPD(prop, me, this);
			} else {
				createMenuItem(me, prop.msgs.menuAdd, prop.images.menuAdd, &addCard);
				new MenuItem(me, DWT.SEPARATOR);
				appendMenuTCPD(prop, me, this, false, true, false, false);
			}

			auto mv = createMenu(bar, prop.msgs.menuView);
			static if (EditMode) {
				createMenuItem(mv, prop.msgs.menuRefresh, prop.images.menuRefresh, &__refresh);
				new MenuItem(mv, DWT.SEPARATOR);
			}
			_listM = createMenuItem(mv, prop.msgs.menuShowCardList, prop.images.menuShowCardList, &showCardList, DWT.RADIO);
			_tblM = createMenuItem(mv, prop.msgs.menuShowCardTable, prop.images.menuShowCardTable, &showCardTable, DWT.RADIO);

			static if (EditMode) {
				auto mt = createMenu(bar, prop.msgs.menuNewCards);
				static if (is (CardOwner == Summary)) {
					createMenuItem(mt, prop.msgs.menuAddScenario, prop.images.menuAddScenario, &addScenario);
					new MenuItem(mt, DWT.SEPARATOR);
				}
				static if (UseCast) createMenuItem(mt, prop.msgs.menuNewCast, prop.images.menuNewCast, &create!(CAST));
				static if (UseSkill) createMenuItem(mt, prop.msgs.menuNewSkill, prop.images.menuNewSkill, &create!(SKILL));
				static if (UseItem) createMenuItem(mt, prop.msgs.menuNewItem, prop.images.menuNewItem, &create!(ITEM));
				static if (UseBeast) createMenuItem(mt, prop.msgs.menuNewBeast, prop.images.menuNewBeast, &create!(BEAST));
				static if (UseInfo) createMenuItem(mt, prop.msgs.menuNewInfo, prop.images.menuNewInfo, &create!(INFO));
			}

			_win.setMenuBar = bar;
		}
		{
			auto bar = new ToolBar(comp, DWT.FLAT);

			static if (EditMode) {
				static if (is (CardOwner == Summary)) {
					createToolItem(bar, prop.msgs.ttAddScenario, prop.images.menuAddScenario, &addScenario);
					new ToolItem(bar, DWT.SEPARATOR);
				}
			}
			static if (EditMode) {
				createToolItem(bar, prop.msgs.ttRefresh, prop.images.menuRefresh, &__refresh);
				new ToolItem(bar, DWT.SEPARATOR);
				static if (UseCast) createToolItem(bar, prop.msgs.ttNewCast, prop.images.menuNewCast, &create!(CAST));
				static if (UseSkill) createToolItem(bar, prop.msgs.ttNewSkill, prop.images.menuNewSkill, &create!(SKILL));
				static if (UseItem) createToolItem(bar, prop.msgs.ttNewItem, prop.images.menuNewItem, &create!(ITEM));
				static if (UseBeast) createToolItem(bar, prop.msgs.ttNewBeast, prop.images.menuNewBeast, &create!(BEAST));
				static if (UseInfo) createToolItem(bar, prop.msgs.ttNewInfo, prop.images.menuNewInfo, &create!(INFO));
			} else {
				createToolItem(bar, prop.msgs.ttAdd, prop.images.menuAdd, &addCard);
			}
			new ToolItem(bar, DWT.SEPARATOR);
			_listT = createToolItem(bar, prop.msgs.ttShowCardList, prop.images.menuShowCardList, &showCardList, DWT.RADIO);
			_tblT = createToolItem(bar, prop.msgs.ttShowCardTable, prop.images.menuShowCardTable, &showCardTable, DWT.RADIO);
		}
		_tabf = new TabFolder(comp, DWT.NONE);
		_tabf.setLayoutData = new GridData(GridData.FILL_BOTH);

		static if (EditMode && is (CardOwner == Summary)) {
			auto drop = new DropTarget(comp, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new DropScenario);
		}
	}
	private void construct2(Props prop) {
		_prop = prop;
		newPane!(0);
		static class ColResize : ControlAdapter {
			TableColumn[] cols;
			private bool proc = false;
			override void controlResized(ControlEvent e) {
				if (proc) return;
				proc = true;
				scope (exit) proc = false;
				auto c = cast(TableColumn) e.widget;
				foreach (col; cols) {
					if (c !is col) {
						col.setWidth = c.getWidth;
					}
				}
			}
		}
		ColResize[] colR;
		colR.length = (is (CardOwner == Summary)) ? 4 : 3;
		foreach (ref c; colR) {
			c = new ColResize;
		}
		void addTable(Table tbl) {
			foreach (i, col; tbl.getColumns) {
				colR[i].cols ~= col;
				col.addControlListener(colR[i]);
			}
		}
		foreach (i, f; _pane) {
			_tab[i] = new TabItem(_tabf, DWT.NONE);
			static if (UseCast) {
				if (i == CAST) _tab[i].setText = prop.msgs.casts;
			}
			static if (UseSkill) {
				if (i == SKILL) _tab[i].setText = prop.msgs.skill;
			}
			static if (UseItem) {
				if (i == ITEM) _tab[i].setText = prop.msgs.item;
			}
			static if (UseBeast) {
				if (i == BEAST) _tab[i].setText = prop.msgs.beast;
			}
			static if (UseInfo) {
				if (i == INFO) _tab[i].setText = prop.msgs.info;
			}
			_tcpd ~= f;
			addTable(f.cardTable);
		}
		showCardList;
		scope wp = _win.computeSize(DWT.DEFAULT, DWT.DEFAULT);
		int width = _prop.var.cardWin.width == DWT.DEFAULT ? wp.x : _prop.var.cardWin.width;
		static if (is (CardOwner == Summary)) {
			int x = _prop.var.cardWin.x == DWT.DEFAULT ? _win.getBounds.x : _prop.var.cardWin.x + _win.getParent.getBounds.x;
			int y = _prop.var.cardWin.y == DWT.DEFAULT ? _win.getBounds.y : _prop.var.cardWin.y + _win.getParent.getBounds.y;
			intoDisplay(x, y, width, _prop.var.cardWin.height);
			_win.setBounds(x, y, width, _prop.var.cardWin.height);
			_win.setMaximized = _prop.var.cardWin.maximized;
			_win.setMinimized = _prop.var.cardWin.minimized;
			_win.addControlListener(new SizeL);
		} else {
			_win.setSize(width, _prop.var.cardWin.height);
		}
		if (prop.var.etc.cardDetails) showCardTable;
	}
	private class SizeL : ControlAdapter {
		private void saveCardWin() {
			if (!_win.getMaximized && !_win.getMinimized) {
				_prop.var.cardWin.width = _win.getSize.x;
				_prop.var.cardWin.height = _win.getSize.y;
				_prop.var.cardWin.x = _win.getBounds.x - _win.getParent.getBounds.x;
				_prop.var.cardWin.y = _win.getBounds.y - _win.getParent.getBounds.y;
			}
			_prop.var.cardWin.maximized = _win.getMaximized;
			_prop.var.cardWin.minimized = _win.getMinimized;
		}
		override void controlMoved(ControlEvent e) {
			saveCardWin;
		}
		override void controlResized(ControlEvent e) {
			saveCardWin;
		}
	}

	Shell shell() {
		return _win;
	}
	CardOwner owner() {
		return _owner;
	}
	PCardOwner summary() {
		return _summ;
	}
	static if (EditMode && is (CardOwner == CastCard) && is (PCardOwner == Summary)) {
		private void __refOwner(CastCard c) {
			if (_owner is c) {
				__refresh;
				refreshTitle;
			}
		}
		private void __delOwner(CastCard c) {
			if (_owner is c) {
				_win.close;
			}
		}
	}

	/// ウィンドウを開く。
	void open() {
		if (_owner) {
			_win.setMinimized = false;
			_win.open;
		}
	}

	void refreshTitle() {
		mixin ("shell.setText = _prop.msgs." ~ Title ~ ";");
	}

	static if (EditMode) {
		static if (is (PCardOwner == Summary) && is (CardOwner == Summary)) {
			void refresh(Summary summ) {
				__refreshAll(summ, summ);
			}
		} else {
			void refresh(PCardOwner summ, CardOwner owner) {
				__refreshAll(summ, owner);
			}
		}
	}
	private void __refreshAll(PCardOwner summ, CardOwner owner) {
		static if (EditMode && is (CardOwner == Summary)) {
			foreach (w; _aws.toArray) {
				w.close;
			}
		}
		_owner = owner;
		_summ = summ;
		foreach (f; _pane) {
			f.refreshAll(summ, owner);
		}
		refreshTitle;
	}
	static if (EditMode) {
		void add(int Index)(ref XNode node, string ver) {
			if (_pane[Index].addFromNode(node, ver)) {
				_tabf.setSelection = _tab[Index];
				_win.setVisible = true;
			}
		}
	} else {
		void setAdd(int Index)(void delegate(ref XNode node, string) addc) {
			_pane[Index].setAddCard = addc;
		}
	}

	override {
		void cut() {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.cut;
					}
				}
			}
		}
		void copy() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.copy;
				}
			}
		}
		void paste() {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.paste;
					}
				}
			}
		}
		void del() {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.del;
					}
				}
			}
		}
		bool canDoTCPD() {
			return EditMode;
		}
	}
}

alias CardWindow!("handCards(owner.id, owner.name)",
	Importable, CastCard, Summary, SkillCard, ItemCard, BeastCard) AddHandCardWindow;

// FIXME: 以下の二つをaliasにすると前方参照のエラーが発生する
class HandCardWindow : CardWindow!("handCards(owner.id, owner.name)",
		Summary, CastCard, void, SkillCard, ItemCard, BeastCard) {
	this (Commons comm, Props prop, Summary summ, Shell parent) {
		super (comm, prop, summ, parent);
	}
}
class MainCardWindow : CardWindow!("cardWindowName(owner.scenarioName, owner.scenarioPath)",
		Summary, Summary, void, CastCard, SkillCard, ItemCard, BeastCard, InfoCard) {
	this (Commons comm, Props prop, Shell parent) {
		super (comm, prop, parent);
	}
}

private class DelTemp(CC) : DisposeListener {
	private CC _cc;
	this(CC cc) {
		_cc = cc;
	}
	override void widgetDisposed(DisposeEvent e) {
		_cc.delTemp;
	}
}
private class AddCard(ToCardOwner, Cards ...) {
private:
	static const bool UseCast = IndexOf!(CastCard, Cards) >= 0;
	static const bool UseSkill = IndexOf!(SkillCard, Cards) >= 0;
	static const bool UseItem = IndexOf!(ItemCard, Cards) >= 0;
	static const bool UseBeast = IndexOf!(BeastCard, Cards) >= 0;
	static const bool UseInfo = IndexOf!(InfoCard, Cards) >= 0;
	alias CardContainer!(UseCast, UseSkill, UseItem, UseBeast, UseInfo) CC;
	alias CardWindow!("addCardWindow(owner.scenarioName, owner.scenarioPath)", CC, CC, ToCardOwner, Cards) ACW;
	static class AddS {
		Commons comm;
		Props prop;
		Shell parent;
		ToCardOwner toc;
		void delegate(Object[]) addScenario;
		this (Commons comm, Props prop,
				Shell parent, ToCardOwner toc, void delegate(Object[]) addScenario) {
			this.comm = comm;
			this.prop = prop;
			this.parent = parent;
			this.toc = toc;
			this.addScenario = addScenario;
		}
		void addS(CC[] ccs) {
			ACW[] r;
			foreach (i, cc; ccs) {
				if (cc) {
					auto acw = new ACW(comm, prop, parent, cc, cc, toc);
					acw.shell.addDisposeListener(new DelTemp!(CC)(cc));
					r ~= acw;
				}
			}
			addScenario(r);
		}
	}
	this() {}
public:
	static void openScenario(Commons comm, Props prop,
			Shell parent, Summary summ, ToCardOwner toc, void delegate(Object[]) addScenario) {
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenarios!(CC)(prop, parent, false, prop.msgs.dlgTitAddScenario, &addS.addS);
	}
	static void openScenario(Commons comm, Props prop,
			Shell parent, Summary summ, ToCardOwner toc, string[] files, void delegate(Object[]) addScenario) {
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenariosFromFile!(CC)(prop, parent, false, files, &addS.addS);
	}
}


module cwx.editor.gui.dwt.cardwindow;

import cwx.card;
import cwx.summary;
import cwx.utils;
import cwx.usecounter;
import cwx.types;
import cwx.xml;
import cwx.skin;
import cwx.path;

import cwx.editor.gui.dwt.commondialog;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.cardlist;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.castcarddialog;
import cwx.editor.gui.dwt.effectcarddialog;
import cwx.editor.gui.dwt.infocarddialog;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.sbshell;

import std.algorithm;
import std.array;
import std.utf;
import std.string;
import std.datetime;
import std.typetuple;
import std.path;

import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.custom.StackLayout;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.ByteArrayTransfer;
import org.eclipse.swt.dnd.FileTransfer;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.Clipboard;

import java.lang.all;

public:

private enum CViewMode {INIT, LIFE, CARD, TABLE}

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
	Composite _parent;
	Commons _comm;
	Props _prop;
	CardOwner _owner = null;
	PCardOwner _summ = null;
	void delegate(Shell) _save;
	CardList!(C) _list;
	Table _tbl;
	Image _cimg;
	CViewMode _viewMode = CViewMode.INIT;
	TCPD[] _tcpd;
	static if (!EditMode) {
		ToCardOwner _toc;
	}
	string _statusLine = "";

	string statusLine() {return _statusLine;}
	void refreshStatusLine() {
		if (!_tbl || !_list || !_comm) return;
		if (_tbl.isDisposed) return;
		if (_owner) {
			auto c = cards.length;
			auto s = __selections;
			static if (is (C == SkillCard) && is (CardOwner == CastCard)) {
				_statusLine = _prop.msgs.handCardStatus(c, s, _prop.looks.skillCardMaxNum(owner.level));
			} else static if (is (C == ItemCard) && is (CardOwner == CastCard)) {
				_statusLine = _prop.msgs.handCardStatus(c, s, _prop.looks.itemCardMaxNum(owner.level));
			} else static if (is (C == BeastCard) && is (CardOwner == CastCard)) {
				_statusLine = _prop.msgs.handCardStatus(c, s, _prop.looks.beastCardMaxNum(owner.level));
			} else {
				_statusLine = _prop.msgs.cardStatus(c, s);
			}
		} else {
			_statusLine = "";
		}
		_comm.statusLine(_tbl, _statusLine);
	}
	static if (EditMode) {
		void nameEditEnd(TableItem itm, int column, string newText) {
			auto c = cast(C) itm.getData;
			assert (c);
			c.name = newText;
			refresh;
			refCard(c);
		}
	}
	void __refreshR(string from, string to) {
		__refresh;
	}
	void refresh(C c) {
		if (!_tbl || _tbl.isDisposed) return;
		int i;
		for (i = 0; i < cards.length; i++) {
			if (cards[i] is c) {
				break;
			}
		}
		if (i >= cards.length) return;
		if (_viewMode == CViewMode.TABLE) {
			refreshTableItem(c, _tbl.getItem(i));
		} else {
			refreshListItem(i);
		}
		refreshStatusLine;
	}
	void __refresh() {
		if (_viewMode == CViewMode.TABLE) {
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
		} else {
			_list.refresh(__cards, &__cardImage);
			int sel = _list.selection;
			if (sel >= 0) {
				_list.scroll(sel);
			}
		}
		refreshStatusLine;
	}
	void select(int index) {
		if (!_tbl || _tbl.isDisposed) return;
		if (_viewMode == CViewMode.TABLE) {
			_tbl.select(index);
			_tbl.showSelection;
		} else {
			_list.select(index);
			_list.scroll(index);
		}
		refreshStatusLine;
	}
	void createTableItem(C c, int index = -1) {
		auto itm = index >= 0
			? new TableItem(_tbl, SWT.NONE, index)
			: new TableItem(_tbl, SWT.NONE);
		refreshTableItem(c, itm);
	}
	void refreshListItem(int index) {
		_list.refresh(index);
	}
	void refreshTableItem(C c, TableItem itm) {
		itm.setImage(0, _cimg);
		itm.setText(0, to!(string)(c.id));
		itm.setText(1, c.name);
		if (c.desc.length > 0) {
			// FIXME: セルの値が長すぎると表示されないことがあるので自らカット
			string desc = std.array.replace(c.desc, "\n", "");
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

		int w = textWidth(_prop, itm.getParent, c.name);
		static if (is(C : CastCard)) {
			bool warn = w > _prop.looks.castNameLimit;
		} else static if (is(C : InfoCard)) {
			// 情報カード名はメッセージに表示されないため制限無し
			bool warn = false;
		} else {
			bool warn = w > _prop.looks.nameLimit;
		}
		itm.setImage(1, warn ? _prop.images.warning : null);
	}
	template CopyAndPaste() {
		override void cut(SelectionEvent se) {
			static if (EditMode) {
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) {
			auto cs = __selections;
			if (cs.length > 0) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(_prop, cb, toXML(cs));
			}
		}
		override void paste(SelectionEvent se) {
			static if (EditMode) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				auto c = CBtoXML(cb);
				try {
					if (c) {
						try {
							auto node = XNode.parse(c);
							if (node.name != C.XML_NAME_M) return;
							addFromNode(node, LATEST_VERSION);
						} catch {}
					}
					refreshStatusLine;
				} catch (Exception e) {
					debugln(e);
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
		override void del(SelectionEvent se) {
			static if (EditMode) {
				auto c = selectionCard;
				if (c) {
					_owner.remove(c);
					refresh;
					delCard(c);
				}
			}
		}
	}
	void refCard(C c) {
		static if (is (C == CastCard)) {
			_comm.refCast.call(this, c);
		} else static if (is (C == SkillCard)) {
			_comm.refSkill.call(this, c);
		} else static if (is (C == ItemCard)) {
			_comm.refItem.call(this, c);
		} else static if (is (C == BeastCard)) {
			_comm.refBeast.call(this, c);
		} else static if (is (C == InfoCard)) {
			_comm.refInfo.call(this, c);
		} else {
			static assert (0);
		}
		refreshStatusLine;
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
		_comm.refUseCount.call;
		static if (is (CardOwner : CastCard) && is (C : BeastCard)) {
			_comm.refCast.call(_owner);
		}
		refreshStatusLine;
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
		override void del(SelectionEvent se) {
			static if (EditMode) {
				auto c = selectionCard;
				if (c) {
					_owner.remove(c);
					_tbl.getSelection[0].dispose;
					_tbl.redraw;
					delCard(c);
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
					ulong[C] oldIDs;
					foreach (card; cards) oldIDs[card] = card.id;
					scope (exit) {
						foreach (card; cards) {
							auto pc = card in oldIDs;
							if (pc && *pc != card.id) refCard(card); 
						}
					}
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
						foreach (i, card; adds) {
							static if (is(CardOwner == CastCard)) {
								_owner.insert(index, card);
								adds[i] = card;
							} else {
								_owner.insert(index, card);
							}
							index++;
						}
						insert(adds[$ - 1], true);
						refreshStatusLine;
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
						if (qCardMaterialCopy(node, adds)) {
							foreach (i, card; adds) {
								_owner.insert(index, card);
								adds[i] = cards[index];
								index++;
							}
							insert(adds[$ - 1], false);
							_comm.refUseCount.call;
							refreshStatusLine;
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
				refreshStatusLine;
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
	bool qCardMaterialCopy(in XNode node, C[] cs) {
		string fromSPath = node.attr("scenarioPath", false);
		if (fromSPath.length > 0 && !cfnmatch(fromSPath, nabs(ownerScenarioPath))) {
			scope uc = new UseCounter;
			foreach (c; cs) {
				c.setUseCounter = uc;
			}
			bool copy;
			auto skin = _comm.skin;
			bool r = qMaterialCopy(_prop, skin, dlgParShl,
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

	Shell dlgParShl() {
		if (_list && !_list.isDisposed) return _list.getShell;
		return _comm.mainWin.shell.getShell;
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
	private Skin _skinTemp = null;
	ImageData __cardImage(C c) {
		Skin skin = _skinTemp ? _skinTemp : _comm.skin;
		static if (is (C == CastCard)) {
			return castCardImage(_prop, skin, c, ownerScenarioPath, _viewMode == CViewMode.LIFE);
		} else static if (!is (C == InfoCard) && is (CardOwner == CastCard)) {
			return cardImage!(C)(_prop, skin, c, ownerScenarioPath, _owner);
		} else {
			return cardImage!(C)(_prop, skin, c, ownerScenarioPath, cast(CastCard) null);
		}
	}

	static if (EditMode) {
		static if (is (C == CastCard)) {
			CastCardDialog[C] _editDlgs;
		} else static if (is (C : EffectCard)) {
			EffectCardDialog!(C)[C] _editDlgs;
		} else static if (is (C == InfoCard)) {
			InfoCardDialog[C] _editDlgs;
		} else static assert (0, typeof(C));
		void edit(C c) {
			auto p = c in _editDlgs;
			if (p) {
				p.active();
				return;
			}
			static if (is (C == CastCard)) {
				auto dlg = new CastCardDialog(_comm, _prop, dlgParShl, _summ, c);
			} else static if (is (C : EffectCard)) {
				auto dlg = new EffectCardDialog!(C)(_comm, _prop, dlgParShl, _summ, c);
			} else static if (is (C == InfoCard)) {
				auto dlg = new InfoCardDialog(_comm, _prop, dlgParShl, _summ, c);
			} else static assert (0, typeof(C));
			dlg.appliedEvent ~= {
				refresh;
				refCard(c);
			};
			dlg.closeEvent ~= {
				_editDlgs.remove(c);
			};
			_editDlgs[c] = dlg;
			dlg.open();
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
		void refreshIDs() {
			if (_viewMode == CViewMode.TABLE) {
				foreach (i, c; cards) {
					_tbl.getItem(i).setText(0, to!(string)(c.id));
				}
			}
		}
		void reNumbering() {
			auto index = selectionIndex;
			auto dlg = new ReNumDialog!(C)(_prop, dlgParShl, cards[index],
				index == 0 ? 1 : cards[index - 1].id + 1);
			if (dlg.open) {
				reNumbering(index, dlg.newId);
			}
		}
		void reNumbering(int index, ulong newId) {
			if (index < 0 || cards.length <= index) return;
			if (newId == 0) return;
			if (index > 0 && cards[index - 1].id >= newId) return;
			static if (is (CardOwner : Summary)) {
				for (size_t i = index; i < cards.length; i++) {
					ulong ni = ulong.max - cards.length + i;
					owner.useCounter.change(C.toID(cards[i].id), C.toID(ni));
					cards[i].id = ni;
				}
			}
			for (size_t i = index; i < cards.length; i++) {
				static if (is (CardOwner : Summary)) {
					owner.useCounter.change(C.toID(cards[i].id), C.toID(newId));
				}
				cards[i].id = newId;
				refCard(cards[i]);
				newId++;
			}
			refreshIDs;
		}
	}

	C[] __selections() {
		if (_viewMode == CViewMode.TABLE) {
			C[] r;
			auto sels = _tbl.getSelection;
			r.length = sels.length;
			foreach (i, itm; sels) {
				r[i] = cast(C) sels[i].getData;
			}
			return r;
		} else {
			return _list.selectionCards;
		}
	}
	int selectionIndex() {
		if (_viewMode == CViewMode.TABLE) {
			return _tbl.getSelectionIndex;
		} else {
			return _list.selection;
		}
	}
	C __selection() {
		if (_viewMode == CViewMode.TABLE) {
			return _tbl.getSelectionIndex >= 0 ? cast(C) _tbl.getSelection[0].getData : null;
		} else {
			return _list.selectionCard;
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
		refreshStatusLine;
	}
	void __refTbl() {
		int index = _list.selection;
		refresh();
		if (index >= 0) {
			_tbl.setSelection = [index];
			_tbl.showSelection;
		}
		refreshStatusLine;
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
	static if (EditMode) {
		void edit() {
			if (_viewMode == CViewMode.TABLE) {
				int index = _tbl.getSelectionIndex;
				if (index >= 0) {
					edit(cast(C) _tbl.getItem(index).getData);
				}
			} else {
				int index = _list.selection;
				if (index >= 0) {
					edit(_list.card(index));
				}
			}
		}
	}
	class LMouse : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button != 1) return;
			int index = _list.selection;
			if (index >= 0) {
				scope p = _list.toControl(e.x, e.y);
				if (_list.getBounds(index).contains(e.x, e.y)) {
					static if (EditMode) {
						edit(_list.card(index));
					} else {
						addCard();
					}
				}
			}
		}
	}
	class TMouse : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button != 1) return;
			int index = _tbl.getSelectionIndex;
			if (index >= 0) {
				scope p = _tbl.toControl(e.x, e.y);
				auto itm = _tbl.getItem(index);
				for (int i = 0; i < _tbl.getColumnCount; i++) {
					if (itm.getBounds(i).contains(e.x, e.y)) {
						static if (EditMode) {
							edit(cast(C) _tbl.getSelection[0].getData);
						} else {
							addCard();
						}
						break;
					}
				}
			}
		}
	}
	class LKey : KeyAdapter {
		override void keyPressed(KeyEvent e) {
			static if (EditMode) {
				bool keyMatch = (e.keyCode == SWT.F2 && _viewMode != CViewMode.TABLE) || e.character == SWT.CR;
			} else {
				bool keyMatch = e.character == SWT.CR;
			}
			if (keyMatch && _list.selection >= 0) {
				static if (EditMode) {
					edit(_list.selectionCard);
				} else {
					addCard();
				}
			}
		}
	}
	class TKey : KeyAdapter {
		override void keyPressed(KeyEvent e) {
			static if (EditMode) {
				bool keyMatch = (e.keyCode == SWT.F2 && _viewMode != CViewMode.TABLE) || e.character == SWT.CR;
			} else {
				bool keyMatch = e.character == SWT.CR;
			}
			if (keyMatch && _tbl.getSelectionIndex >= 0) {
				static if (EditMode) {
					edit(cast(C) _tbl.getSelection[0].getData);
				} else {
					addCard();
				}
			}
		}
	}
	private class SelChanged : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshStatusLine;
		}
	}
	static if (is(CardOwner : Summary)) {
		private bool _procRefColW = false;
		void refColumnWidth(TableColumn c, int width) {
			if (_procRefColW) return;
			if (!_tbl || _tbl.isDisposed) return;
			if (_tbl is c.getParent) return;
			int i = c.getParent.indexOf(c);
			auto col = _tbl.getColumn(i);
			col.setWidth = width;
		}
		class DisposeTable : DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refCardTableColumnWidth.remove(&refColumnWidth);
			}
		}
		class ColResize(string WidthPropName) : ControlAdapter {
			override void controlResized(ControlEvent e) {
				if (_procRefColW) return;
				_procRefColW = true;
				scope (exit) _procRefColW = false;
				auto col = cast(TableColumn) e.widget;
				int width = col.getWidth;
				_comm.refCardTableColumnWidth.call(col, width);
				mixin("_prop.var.etc." ~ WidthPropName ~ " = width;");
			}
		}
	}
	void createCardList(Composite parent) {
		_list = new CardList!(C)(parent, SWT.VIRTUAL | SWT.V_SCROLL | (EditMode ? SWT.SINGLE : SWT.MULTI) | SWT.BORDER);
		_list.setLayoutValues(_prop.var.etc.cardsMarginX, _prop.var.etc.cardsSpaceX,
			_prop.var.etc.cardsMarginY, _prop.var.etc.cardsSpaceY, _prop.var.etc.cardsDefaultWrap);
		_list.selectChanged(&refreshStatusLine);
		_tbl = new Table(parent, SWT.FULL_SELECTION | (EditMode ? SWT.SINGLE : SWT.MULTI) | SWT.BORDER);
		_tbl.addSelectionListener(new SelChanged);
		_tbl.setHeaderVisible = true;
		auto idCol = new TableColumn(_tbl, SWT.NONE);
		idCol.setText = _prop.msgs.cardId;
		idCol.setWidth = _prop.var.etc.cardIdColumn;
		static if (is(CardOwner : Summary)) {
			idCol.addControlListener(new ColResize!("cardIdColumn"));
		}
		auto nameCol = new TableColumn(_tbl, SWT.NONE);
		nameCol.setText = _prop.msgs.cardName;
		nameCol.setWidth = _prop.var.etc.cardNameColumn;
		static if (is(CardOwner : Summary)) {
			nameCol.addControlListener(new ColResize!("cardNameColumn"));
		}
		auto descCol = new TableColumn(_tbl, SWT.NONE);
		descCol.setText = _prop.msgs.cardDesc;
		descCol.setWidth = _prop.var.etc.cardDescriptionColumn;
		static if (is(CardOwner : Summary)) {
			descCol.addControlListener(new ColResize!("cardDescriptionColumn"));
		}
		static if (is (CardOwner == Summary)) {
			auto ucCol = new TableColumn(_tbl, SWT.NONE);
			ucCol.setText = _prop.msgs.cardCount;
			ucCol.setWidth = _prop.var.etc.cardCountColumn;
			static if (is(CardOwner : Summary)) {
				ucCol.addControlListener(new ColResize!("cardCountColumn"));
			}
		}
		static if (is(CardOwner : Summary)) {
			_comm.refCardTableColumnWidth.add(&refColumnWidth);
			_tbl.addDisposeListener(new DisposeTable);
		}
		static if (EditMode) {
			new TableTextEdit(_tbl, 1, &nameEditEnd, null);
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
	private void construct1(Commons comm, Props prop, PCardOwner summ) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		static if (is (C == CastCard)) {
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
	}
	private void reconstruct(Composite parent) {
		_parent = parent;
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
				_comm.refCast.add(&refCardCallback);
			} else static if (is (C == SkillCard)) {
				_comm.refSkill.add(&refCardCallback);
			} else static if (is (C == ItemCard)) {
				_comm.refItem.add(&refCardCallback);
			} else static if (is (C == BeastCard)) {
				_comm.refBeast.add(&refCardCallback);
			} else static if (is (C == InfoCard)) {
				_comm.refInfo.add(&refCardCallback);
			}
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					static if (is (C == CastCard)) {
						_comm.refCast.remove(&refCardCallback);
					} else static if (is (C == SkillCard)) {
						_comm.refSkill.remove(&refCardCallback);
					} else static if (is (C == ItemCard)) {
						_comm.refItem.remove(&refCardCallback);
					} else static if (is (C == BeastCard)) {
						_comm.refBeast.remove(&refCardCallback);
					} else static if (is (C == InfoCard)) {
						_comm.refInfo.remove(&refCardCallback);
					}
				}
			});
			static if (is (C == CastCard)) {
				auto pop = new Menu(parent.getShell, SWT.POP_UP);
				createMenuItem(pop, _prop.msgs.menuCEdit, _prop.images.menuCEdit, &edit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(pop, _prop.msgs.menuEditHand, _prop.images.menuEditHand, &editHand);
				new MenuItem(pop, SWT.SEPARATOR);
				appendMenuTCPD(_prop, pop, this);
			} else static if (is (C == SkillCard) || is (C == ItemCard) || is (C == BeastCard)) {
				auto pop = new Menu(parent.getShell, SWT.POP_UP);
				createMenuItem(pop, _prop.msgs.menuCEdit, _prop.images.menuCEdit, &edit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(pop, _prop.msgs.menuEditUseEvent, _prop.images.menuEditUseEvent, &editUseEvent);
				new MenuItem(pop, SWT.SEPARATOR);
				appendMenuTCPD(_prop, pop, this);
			} else static if (is (C == InfoCard)) {
				auto pop = new Menu(parent.getShell, SWT.POP_UP);
				createMenuItem(pop, _prop.msgs.menuCEdit, _prop.images.menuCEdit, &edit);
				new MenuItem(pop, SWT.SEPARATOR);
				appendMenuTCPD(_prop, pop, this);
			} else {
				static assert (0);
			}
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(pop, _prop.msgs.menuReNumbering, _prop.images.menuReNumbering, &reNumbering);
		} else {
			auto pop = new Menu(parent.getShell, SWT.POP_UP);
			static if (is (C == CastCard)) {
				createMenuItem(pop, _prop.msgs.menuOpenHand, _prop.images.menuOpenHand, _openHand);
				new MenuItem(pop, SWT.SEPARATOR);
			}
			createMenuItem(pop, _prop.msgs.menuAdd, _prop.images.menuAdd, &addCard);
			new MenuItem(pop, SWT.SEPARATOR);
			appendMenuTCPD(_prop, pop, this, false, true, false, false);
		}
		_list.setMenu = pop;
		_tbl.setMenu = pop;
		refreshStatusLine;
	}
public:
	static if (!EditMode) {
		static if (is (C == CastCard)) {
			this(Commons comm, Props prop, PCardOwner summ, Composite parent, ToCardOwner toc, void delegate() openHand) {
				_parent = parent;
				_toc = toc;
				_openHand = openHand;
				_skinTemp = findSkin(comm, prop, summ);
				construct1(comm, prop, summ);
			}
		} else {
			this(Commons comm, Props prop, PCardOwner summ, Composite parent, ToCardOwner toc) {
				_parent = parent;
				_toc = toc;
				_skinTemp = findSkin(comm, prop, summ);
				construct1(comm, prop, summ);
			}
		}
		void construct() {
			reconstruct(_parent);
		}
	} else static if (is (C : Card)) {
		this(Commons comm, Props prop, PCardOwner summ, Composite parent) {
			_parent = parent;
			construct1(comm, prop, summ);
		}
		void construct() {
			reconstruct(_parent);
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
		if (_viewMode == CViewMode.TABLE) {
			return _tbl;
		} else {
			return _list;
		}
	}
	void refresh() {
		if (!_tbl || _tbl.isDisposed) return;
		if (_owner) {
			__refresh;
		}
		refreshStatusLine;
	}
	static if (EditMode){
		private void refCardCallback(Object sender, C c) {
			if (sender is this) return;
			refresh(c);
		}
	}
	void showCardLife() {
		if (_viewMode != CViewMode.LIFE) {
			_viewMode = CViewMode.LIFE;
			__refList;
		}
	}
	void showCardList() {
		if (_viewMode != CViewMode.CARD) {
			_viewMode = CViewMode.CARD;
			__refList;
		}
	}
	void showCardTable() {
		if (_viewMode != CViewMode.TABLE) {
			_viewMode = CViewMode.TABLE;
			__refTbl;
		}
	}
	static if (EditMode) {
		void create() {
			static if (is (C == CastCard)) {
				auto c = new CastCard(0, "", "", "", 1, 1);
				auto dlg = new CastCardDialog(_comm, _prop, dlgParShl, _summ, null);
			} else static if (is (C : EffectCard)) {
				auto c = new C(0, "", "", "");
				auto dlg = new EffectCardDialog!(C)(_comm, _prop, dlgParShl, _summ, null);
			} else static if (is (C == InfoCard)) {
				auto c = new InfoCard(0, "", "", "");
				auto dlg = new InfoCardDialog(_comm, _prop, dlgParShl, _summ, null);
			} else {
				static assert (0);
			}
			dlg.appliedEvent ~= {
				static if (is(C : CastCard)) {
					_comm.openCastWin();
				} else static if(is(C : SkillCard)) {
					_comm.openSkillWin();
				} else static if(is(C : ItemCard)) {
					_comm.openItemWin();
				} else static if(is(C : BeastCard)) {
					_comm.openBeastWin();
				} else static if(is(C : InfoCard)) {
					_comm.openInfoWin();
				} else static assert (0);
				auto c = dlg.card;
				_owner.add(c);
				refresh;
				select(__cards.length - 1);
				static if (is (CardOwner : CastCard) && is (C : BeastCard)) {
					_comm.refCast.call(_owner);
				}
				dlg.appliedEvent.length = 0;
				dlg.appliedEvent ~= {
					refresh;
					refCard(c);
				};
			};
			_editDlgs[c] = dlg;
			dlg.closeEvent ~= {
				_editDlgs.remove(c);
			};
			dlg.open();
		}
		static if (is (CardOwner == Summary)) {
			private void __refreshUseCount() {
				if (_viewMode == CViewMode.TABLE) {
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
				if (!qCardMaterialCopy(node, adds)) return false;
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
			static if (is(C : CastCard)) {
				_comm.openCastWin();
			} else static if(is(C : SkillCard)) {
				_comm.openSkillWin();
			} else static if(is(C : ItemCard)) {
				_comm.openItemWin();
			} else static if(is(C : BeastCard)) {
				_comm.openBeastWin();
			} else static if(is(C : InfoCard)) {
				_comm.openInfoWin();
			} else static assert (0);
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
			static if (is (CardOwner : CastCard) && is (C : BeastCard)) {
				_comm.refCast.call(_owner);
			}
			return true;
		}
		void pasteRefresh(C[] cs) {
			if (_viewMode == CViewMode.TABLE) {
				foreach (c; cs) {
					createTableItem(c);
				}
				_tbl.setSelection = [_tbl.getItemCount - 1];
				_tbl.showSelection;
			} else {
				refresh;
				_list.select(_list.count - 1);
				_list.scroll(_list.count - 1);
			}
			refreshStatusLine;
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
		refresh();
	}

	Table cardTable() {
		return _tbl;
	}

	override {
		void cut(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.cut(se);
					}
				}
			}
		}
		void copy(SelectionEvent se) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.copy(se);
				}
			}
		}
		void paste(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.paste(se);
					}
				}
			}
		}
		void del(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.del(se);
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

interface ICardWindow {
	bool canCreateCast();
	bool canCreateSkill();
	bool canCreateItem();
	bool canCreateBeast();
	bool canCreateInfo();
	void createCast();
	void createSkill();
	void createItem();
	void createBeast();
	void createInfo();
}

class CardWindow(string ShellTitle, string Title, string ShellImage,
		PCardOwner, CardOwner, ToCardOwner, Cards ...)
		: TopLevelPanel, TCPD, ICardWindow {
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
	static if (1 < Cards.length) {
		CTabFolder _tabf;
		CTabItem[Cards.length] _tab;
	} else {
		Composite _tabf;
		StackLayout _stackL;
	}

	Props _prop;
	SBShell _sbshl;
	Composite _win;
	Composite _comp;
	PCardOwner _summ;
	CardOwner _owner;
	Commons _comm;

	CViewMode _viewMode = CViewMode.INIT;
	MenuItem _lifeM;
	MenuItem _listM;
	MenuItem _tblM;
	ToolItem _lifeT;
	ToolItem _listT;
	ToolItem _tblT;

	TCPD[] _tcpd;

	static if (!EditMode) {
		ToCardOwner _toc;
	}
	static if (EditMode) {
		void create(int Index)() {
			static if (1 < Cards.length) {
				if (_tabf && !_tabf.isDisposed) {
					_tabf.setSelection = _tab[Index];
				}
			}
			_pane[Index].create;
		}
	}
	static if (is(CardOwner : Summary)) {
		void open(int Index)() {
			static if (1 < Cards.length) {
				_comm.openBindCardWin();
				_tabf.setSelection = _tab[Index];
			} else {
				static if (UseCast && CAST == Index) {
					_comm.openCastWin();
				} else static if(UseSkill && SKILL == Index) {
					_comm.openSkillWin();
				} else static if(UseItem && ITEM == Index) {
					_comm.openItemWin();
				} else static if(UseBeast && BEAST == Index) {
					_comm.openBeastWin();
				} else static if(UseInfo && INFO == Index) {
					_comm.openInfoWin();
				} else static assert (0);
			}
		}
	}

	void __refresh() {
		foreach (f; _pane) {
			f.refresh;
		}
		refreshTitle;
	}
	static if (EditMode && is (CardOwner == Summary)) {
		void addScenario() {
			_comm.addScenario(_prop);
		}
		class DropScenario : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_LINK;
			}
			override void drop(DropTargetEvent e) {
				auto arr = cast(FileNames) e.data;
				if (arr && arr.array.length > 0) {
					_comm.addScenario(_prop, arr.array);
				}
			}
		}
	}
	Shell dlgParShl() {
		if (_win && !_win.isDisposed) return _win.getShell;
		return _comm.mainWin.shell.getShell;
	}
	static if (!EditMode) {
		void addCard() {
			static if (1 < Cards.length) {
				foreach (i, f; _pane) {
					if (_tabf.getSelection is _tab[i]) {
						f.addCard();
						return;
					}
				}
			} else {
				_pane[0].addCard();
			}
		}
	}
	static if (UseCast && !EditMode) {
		void openHand() {
			auto sels = _pane[CAST].__selections;
			foreach (sel; sels) {
				auto ahcw = _comm.openAddHands(_prop, _summ, sel, _toc);
				ahcw.setAddSkill(_pane[SKILL].getAddCard);
				ahcw.setAddItem(_pane[ITEM].getAddCard);
				ahcw.setAddBeast(_pane[BEAST].getAddCard);
			}
		}
	}
public:
	static if (EditMode) {
		static if (is (CardOwner == Summary)) {
			this(Commons comm, Props prop, Composite parent) {
				_comm = comm;
				_prop = prop;
				if (parent) {
					construct(comm, prop, null, parent);
				} else {
					initPane!(0);
				}
			}
			void reconstruct(Composite parent) {
				if (_win && !_win.isDisposed) return;
				construct(_comm, _prop, _summ, parent);
				if (_owner) refresh(_owner);
			}
		} else {
			this(Commons comm, Props prop, PCardOwner summ, Composite parent) {
				construct(comm, prop, summ, parent);
			}
		}
		void construct(Commons comm, Props prop, PCardOwner summ, Composite parent) {
			_viewMode = CViewMode.INIT;
			construct1(comm, prop, parent);
			static if (is (CardOwner == Summary)) {
				auto shell = cast(Shell) _win;
				if (shell) {
					shell.addShellListener(new class ShellAdapter {
						override void shellClosed(ShellEvent e) {
							(cast(Shell) e.widget).setVisible = false;
							e.doit = false;
							_prop.var.cardWin.visible = false;
						}
					});
				}
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
			construct2();
			_comm.refScenarioName.add(&refreshTitle);
			_comm.refScenarioPath.add(&refreshTitle);
			_win.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					_comm.refScenarioName.remove(&refreshTitle);
					_comm.refScenarioPath.remove(&refreshTitle);
				}
			});
		}
		void initPane(int Index)() {
			assert (!_pane[Index]);
			_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf);
			static if (Index + 1 < Cards.length) {
				initPane!(Index + 1);
			}
		}
		void newPane(int Index)() {
			if (_pane[Index]) {
				_pane[Index].reconstruct(_tabf);
			} else {
				_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf);
				_pane[Index].construct();
			}
			static if (Index + 1 < Cards.length) {
				newPane!(Index + 1);
			}
		}
	} else {
		void newPane(int Index)() {
			if (_pane[Index]) {
				_pane[Index].reconstruct(_tabf);
			} else {
				static if (UseCast && Index == CAST) {
					_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, _toc, &openHand);
				} else {
					_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, _toc);
				}
				_pane[Index].construct();
			}
			static if (Index + 1 < Cards.length) {
				newPane!(Index + 1);
			}
		}
		this(Commons comm, Props prop,
				Composite parent, PCardOwner summ, CardOwner owner, ToCardOwner toc) {
			_toc = toc;
			construct1(comm, prop, parent);
			static if (is (CardOwner == CastCard)) {
				_comm.closeAdds.add(&__closeAdds);
				_win.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) {
						_comm.closeAdds.remove(&__closeAdds);
					}
				});
			}
			static if (is (CardOwner == Importable)) {
				_win.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) {
						_comm.closeAdds.call(_summ);
					}
				});
			}
			_summ = summ;
			construct2();
			__refreshAll(summ, owner);
		}
	}
	private void construct1(Commons comm, Props prop, Composite parent) {
		_comm = comm;
		_prop = prop;
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		Composite contPane;
		if (parShl) {
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImage = prop.images.app;
			_win = shell;
			contPane = _sbshl.contentPane;
		} else {
			_win = new Composite(parent, SWT.NONE);
			contPane = _win;
		}
		_win.setData = new TLPData(this);
		contPane.setLayout = new FillLayout;
		_comp = new Composite(contPane, SWT.NONE);
		_comp.setLayout = windowGridLayout(1, true);
		if (shell) {
			{
				auto bar = new Menu(shell, SWT.BAR);

				auto mf = createMenu(bar, prop.msgs.menuFile);
				createMenuItem(mf, prop.msgs.menuCloseWin, prop.images.menuCloseWin, &shell.close);

				auto me = createMenu(bar, prop.msgs.menuEdit);
				static if (EditMode) {
					appendMenuTCPD(prop, me, this);
				} else {
					createMenuItem(me, prop.msgs.menuAdd, prop.images.menuAdd, &addCard);
					new MenuItem(me, SWT.SEPARATOR);
					appendMenuTCPD(prop, me, this, false, true, false, false);
				}

				auto mv = createMenu(bar, prop.msgs.menuView);
				static if (EditMode) {
					createMenuItem(mv, prop.msgs.menuRefresh, prop.images.menuRefresh, &__refresh);
					new MenuItem(mv, SWT.SEPARATOR);
				}
				_lifeM = createMenuItem(mv, prop.msgs.menuShowCardLife, prop.images.menuShowCardLife, &showCardLife, SWT.RADIO);
				_listM = createMenuItem(mv, prop.msgs.menuShowCardList, prop.images.menuShowCardList, &showCardList, SWT.RADIO);
				_tblM = createMenuItem(mv, prop.msgs.menuShowCardTable, prop.images.menuShowCardTable, &showCardTable, SWT.RADIO);

				static if (EditMode) {
					auto mt = createMenu(bar, prop.msgs.menuNewCards);
					static if (is (CardOwner == Summary)) {
						createMenuItem(mt, prop.msgs.menuAddScenario, prop.images.menuAddScenario, &addScenario);
						new MenuItem(mt, SWT.SEPARATOR);
					}
					static if (UseCast) createMenuItem(mt, prop.msgs.menuNewCast, prop.images.menuNewCast, &create!(CAST));
					static if (UseSkill) createMenuItem(mt, prop.msgs.menuNewSkill, prop.images.menuNewSkill, &create!(SKILL));
					static if (UseItem) createMenuItem(mt, prop.msgs.menuNewItem, prop.images.menuNewItem, &create!(ITEM));
					static if (UseBeast) createMenuItem(mt, prop.msgs.menuNewBeast, prop.images.menuNewBeast, &create!(BEAST));
					static if (UseInfo) createMenuItem(mt, prop.msgs.menuNewInfo, prop.images.menuNewInfo, &create!(INFO));
				}
				shell.setMenuBar = bar;
			}
			{
				auto bar = new ToolBar(_comp, SWT.FLAT);
				static if (EditMode) {
					static if (is (CardOwner == Summary)) {
						createToolItem(bar, prop.msgs.ttAddScenario, prop.images.menuAddScenario, &addScenario);
						new ToolItem(bar, SWT.SEPARATOR);
					}
				}
				static if (EditMode) {
					createToolItem(bar, prop.msgs.ttRefresh, prop.images.menuRefresh, &__refresh);
					new ToolItem(bar, SWT.SEPARATOR);
					static if (UseCast) createToolItem(bar, prop.msgs.ttNewCast, prop.images.menuNewCast, &create!(CAST));
					static if (UseSkill) createToolItem(bar, prop.msgs.ttNewSkill, prop.images.menuNewSkill, &create!(SKILL));
					static if (UseItem) createToolItem(bar, prop.msgs.ttNewItem, prop.images.menuNewItem, &create!(ITEM));
					static if (UseBeast) createToolItem(bar, prop.msgs.ttNewBeast, prop.images.menuNewBeast, &create!(BEAST));
					static if (UseInfo) createToolItem(bar, prop.msgs.ttNewInfo, prop.images.menuNewInfo, &create!(INFO));
				} else {
					createToolItem(bar, prop.msgs.ttAdd, prop.images.menuAdd, &addCard);
				}
				new ToolItem(bar, SWT.SEPARATOR);
				_lifeT = createToolItem(bar, prop.msgs.ttShowCardLife, prop.images.menuShowCardLife, &showCardLife, SWT.RADIO);
				_listT = createToolItem(bar, prop.msgs.ttShowCardList, prop.images.menuShowCardList, &showCardList, SWT.RADIO);
				_tblT = createToolItem(bar, prop.msgs.ttShowCardTable, prop.images.menuShowCardTable, &showCardTable, SWT.RADIO);
			}
		} else {
			static if (EditMode) {
				appendMenuTCPD(prop, this, this);
				putMenuAction(MenuID.Refresh, &__refresh);
				static if (is (CardOwner == Summary)) {
					putMenuAction(MenuID.AddScenario, &addScenario);
				}
				static if (UseCast) putMenuAction(MenuID.NewCast, &create!(CAST));
				static if (UseSkill) putMenuAction(MenuID.NewSkill, &create!(SKILL));
				static if (UseItem) putMenuAction(MenuID.NewItem, &create!(ITEM));
				static if (UseBeast) putMenuAction(MenuID.NewBeast, &create!(BEAST));
				static if (UseInfo) putMenuAction(MenuID.NewInfo, &create!(INFO));
			} else {
				appendMenuTCPD(prop, this, this, false, true, false, false);
			}
			putMenuChecked(MenuID.ShowCardLife, &showCardLife, &isViewLife);
			putMenuChecked(MenuID.ShowCardList, &showCardList, &isViewList);
			putMenuChecked(MenuID.ShowCardTable, &showCardTable, &isViewTable);
		}
		static if (1 < Cards.length) {
			_tabf = new CTabFolder(_comp, SWT.BORDER);
			_tabf.addSelectionListener(new SelChanged);
		} else {
			_tabf = new Composite(_comp, SWT.BORDER);
			_stackL = new StackLayout;
			_tabf.setLayout = _stackL;
		}
		_tabf.setLayoutData = new GridData(GridData.FILL_BOTH);

		static if (EditMode && is (CardOwner == Summary)) {
			auto drop = new DropTarget(_comp, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new DropScenario);
		}
	}
	static if (1 < Cards.length) {
		private class SelChanged : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				refreshStatusLine;
			}
		}
	}
	static if (EditMode) {
		void reNumberingAll() {
			foreach (f; _pane) {
				f.reNumbering(0, 1);
			}
		}
	}
	void showCardLife() {
		if (_viewMode != CViewMode.LIFE) {
			_viewMode = CViewMode.LIFE;
			if (_win && !_win.isDisposed) {
				if (_listM) {
					_lifeM.setSelection = true;
					_lifeT.setSelection = true;
					_listM.setSelection = false;
					_listT.setSelection = false;
					_tblM.setSelection = false;
					_tblT.setSelection = false;
				}
				foreach (i, f; _pane) {
					f.showCardLife;
					static if (1 < Cards.length) {
						_tab[i].setControl = f.widget;
					} else {
						_stackL.topControl = f.widget;
						_tabf.layout();
					}
				}
			}
			static if (is (CardOwner == Summary)) {
				_prop.var.etc.cardLife = true;
				_prop.var.etc.cardDetails = false;
			}
			refreshStatusLine;
		}
	}
	void showCardList() {
		if (_viewMode != CViewMode.CARD) {
			_viewMode = CViewMode.CARD;
			if (_win && !_win.isDisposed) {
				if (_listM) {
					_lifeM.setSelection = false;
					_lifeT.setSelection = false;
					_listM.setSelection = true;
					_listT.setSelection = true;
					_tblM.setSelection = false;
					_tblT.setSelection = false;
				}
				foreach (i, f; _pane) {
					f.showCardList;
					static if (1 < Cards.length) {
						_tab[i].setControl = f.widget;
					} else {
						_stackL.topControl = f.widget;
						_tabf.layout();
					}
				}
			}
			static if (is (CardOwner == Summary)) {
				_prop.var.etc.cardLife = false;
				_prop.var.etc.cardDetails = false;
			}
			refreshStatusLine;
		}
	}
	void showCardTable() {
		if (_viewMode != CViewMode.TABLE) {
			_viewMode = CViewMode.TABLE;
			if (_win && !_win.isDisposed) {
				if (_listM) {
					_lifeM.setSelection = false;
					_lifeT.setSelection = false;
					_listM.setSelection = false;
					_listT.setSelection = false;
					_tblM.setSelection = true;
					_tblT.setSelection = true;
				}
				foreach (i, f; _pane) {
					f.showCardTable;
					static if (1 < Cards.length) {
						_tab[i].setControl = f.widget;
					} else {
						_stackL.topControl = f.widget;
						_tabf.layout();
					}
				}
			}
			static if (is (CardOwner == Summary)) {
				_prop.var.etc.cardLife = false;
				_prop.var.etc.cardDetails = true;
			}
			refreshStatusLine;
		}
	}

	void setStatusLine(string status) {
		auto w = _win;
		if (w.isDisposed) {
			w = null;
		}
		_comm.statusLine(w, status);
	}

	static if (is(CardOwner : Summary)) {
		void openCast() {
			static if (UseCast) {
				open!(CAST);
			} else {
				throw new Exception("can not open cast");
			}
		}
		void openSkill() {
			static if (UseSkill) {
				open!(SKILL);
			} else {
				throw new Exception("can not open skill");
			}
		}
		void openItem() {
			static if (UseItem) {
				open!(ITEM);
			} else {
				throw new Exception("can not open item");
			}
		}
		void openBeast() {
			static if (UseBeast) {
				open!(BEAST);
			} else {
				throw new Exception("can not open beast");
			}
		}
		void openInfo() {
			static if (UseInfo) {
				open!(INFO);
			} else {
				throw new Exception("can not open info");
			}
		}
	}
	void createCast() {
		if (!_summ) return;
		static if (EditMode && UseCast) {
			create!(CAST);
		} else {
			throw new Exception("can not create cast");
		}
	}
	void createSkill() {
		if (!_summ) return;
		static if (EditMode && UseSkill) {
			create!(SKILL);
		} else {
			throw new Exception("can not create skill");
		}
	}
	void createItem() {
		if (!_summ) return;
		static if (EditMode && UseItem) {
			create!(ITEM);
		} else {
			throw new Exception("can not create item");
		}
	}
	void createBeast() {
		if (!_summ) return;
		static if (EditMode && UseBeast) {
			create!(BEAST);
		} else {
			throw new Exception("can not create beast");
		}
	}
	void createInfo() {
		if (!_summ) return;
		static if (EditMode && UseInfo) {
			create!(INFO);
		} else {
			throw new Exception("can not create info");
		}
	}
	bool canCreateCast() {return EditMode && UseCast;}
	bool canCreateSkill() {return EditMode && UseSkill;}
	bool canCreateItem() {return EditMode && UseItem;}
	bool canCreateBeast() {return EditMode && UseBeast;}
	bool canCreateInfo() {return EditMode && UseInfo;}
	private bool isViewLife() {
		return _viewMode == CViewMode.LIFE;
	}
	private bool isViewList() {
		return _viewMode == CViewMode.CARD;
	}
	private bool isViewTable() {
		return _viewMode == CViewMode.TABLE;
	}
	static if (!is(CardOwner : Summary)) {
		private static class ColResize : ControlAdapter {
			bool procRefColWidth = false;
			Commons comm;
			TableColumn[] cols;
			override void controlResized(ControlEvent e) {
				if (procRefColWidth) return;
				procRefColWidth = true;
				scope (exit) procRefColWidth = false;
				auto c = cast(TableColumn) e.widget;
				int width = c.getWidth;
				foreach (col; cols) {
					if (c !is col) {
						col.setWidth = width;
					}
				}
			}
		}
	}
	private void construct2() {
		newPane!(0);
		static if (!is(CardOwner : Summary)) {
			ColResize[] colR;
			colR.length = (is (CardOwner == Summary)) ? 4 : 3;
			foreach (i, c; colR) {
				colR[i] = new ColResize;
				colR[i].comm = _comm;
			}
			void addTable(Table tbl) {
				foreach (i, col; tbl.getColumns) {
					colR[i].cols ~= col;
					col.addControlListener(colR[i]);
				}
			}
		}
		foreach (i, f; _pane) {
			static if (1 < Cards.length) {
				_tab[i] = new CTabItem(_tabf, SWT.NONE);
				static if (UseCast) {
					if (i == CAST) {
						_tab[i].setText = _prop.msgs.casts;
						_tab[i].setImage = _prop.images.casts;
					}
				}
				static if (UseSkill) {
					if (i == SKILL) {
						_tab[i].setText = _prop.msgs.skill;
						_tab[i].setImage = _prop.images.skill;
					}
				}
				static if (UseItem) {
					if (i == ITEM) {
						_tab[i].setText = _prop.msgs.item;
						_tab[i].setImage = _prop.images.item;
					}
				}
				static if (UseBeast) {
					if (i == BEAST) {
						_tab[i].setText = _prop.msgs.beast;
						_tab[i].setImage = _prop.images.beast;
					}
				}
				static if (UseInfo) {
					if (i == INFO) {
						_tab[i].setText = _prop.msgs.info;
						_tab[i].setImage = _prop.images.info;
					}
				}
			}
			_tcpd ~= f;
			static if (!is(CardOwner : Summary)) {
				addTable(f.cardTable);
			}
		}
		auto shell = cast(Shell) _win;

		static if (1 < Cards.length) {
			_tabf.setSelection = 0;
		}
		bool life = _prop.var.etc.cardLife;
		bool detail = _prop.var.etc.cardDetails;
		if (life) {
			showCardLife;
		} else {
			showCardList;
		}
		if (shell) {
			scope wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			int width = _prop.var.cardWin.width == SWT.DEFAULT ? wp.x : _prop.var.cardWin.width;
			static if (is (CardOwner == Summary)) {
				shell.setMaximized = _prop.var.cardWin.maximized;
				shell.setMinimized = _prop.var.cardWin.minimized;
				int x = _prop.var.cardWin.x == SWT.DEFAULT ? shell.getBounds.x : _prop.var.cardWin.x + shell.getParent.getBounds.x;
				int y = _prop.var.cardWin.y == SWT.DEFAULT ? shell.getBounds.y : _prop.var.cardWin.y + shell.getParent.getBounds.y;
				intoDisplay(x, y, width, _prop.var.cardWin.height);
				shell.setBounds(x, y, width, _prop.var.cardWin.height);
				shell.addControlListener(new SizeL);
			} else {
				shell.setSize(width, _prop.var.cardWin.height);
			}
		}
		if (!life && detail) {
			showCardTable;
		}
	}
	private class SizeL : ControlAdapter {
		private void saveCardWin() {
			auto shell = cast(Shell) _win;
			if (shell) {
				if (!shell.getMaximized && !shell.getMinimized) {
					_prop.var.cardWin.width = shell.getSize.x;
					_prop.var.cardWin.height = shell.getSize.y;
					_prop.var.cardWin.x = shell.getBounds.x - shell.getParent.getBounds.x;
					_prop.var.cardWin.y = shell.getBounds.y - shell.getParent.getBounds.y;
				}
				_prop.var.cardWin.maximized = shell.getMaximized;
				_prop.var.cardWin.minimized = shell.getMinimized;
			}
		}
		override void controlMoved(ControlEvent e) {
			saveCardWin;
		}
		override void controlResized(ControlEvent e) {
			saveCardWin;
		}
	}
	static if (!EditMode && is(CardOwner == CastCard)) {
		private void __closeAdds(Importable importable) {
			if (_summ is importable) {
				_comm.close(_win);
			}
		}
	}

	Composite shell() {
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
				_comm.close(_win);
			}
		}
	}

	Image image() {
		return mixin ("_prop.images." ~ ShellImage);
	}
	string title() {
		auto shl = cast(Shell) _win;
		if (shl) {
			return mixin ("_prop.msgs." ~ ShellTitle);
		}
		return mixin ("_prop.msgs." ~ Title);
	}
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	void refreshTitle() {
		if (_win && !_win.isDisposed) _comm.setTitle(shell, title);
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
		_owner = owner;
		_summ = summ;
		foreach (f; _pane) {
			f.refreshAll(summ, owner);
		}
		if (_win && !_win.isDisposed) {
			refreshTitle;
		}
	}
	static if (EditMode) {
		void add(int Index)(ref XNode node, string ver) {
			if (_pane[Index].addFromNode(node, ver)) {
				static if (1 < Cards.length) {
					_tabf.setSelection = _tab[Index];
				}
			}
		}
		static if (UseCast) {
			void addCast(ref XNode node, string ver) {
				_pane[CAST].addFromNode(node, ver);
			}
		}
		static if (UseSkill) {
			void addSkill(ref XNode node, string ver) {
				_pane[SKILL].addFromNode(node, ver);
			}
		}
		static if (UseItem) {
			void addItem(ref XNode node, string ver) {
				_pane[ITEM].addFromNode(node, ver);
			}
		}
		static if (UseBeast) {
			void addBeast(ref XNode node, string ver) {
				_pane[BEAST].addFromNode(node, ver);
			}
		}
		static if (UseInfo) {
			void addInfo(ref XNode node, string ver) {
				_pane[INFO].addFromNode(node, ver);
			}
		}
	} else {
		static if (UseCast) {
			void setAddCast(void delegate(ref XNode node, string) addc) {
				_pane[CAST].setAddCard = addc;
			}
		}
		static if (UseSkill) {
			void setAddSkill(void delegate(ref XNode node, string) addc) {
				_pane[SKILL].setAddCard = addc;
			}
		}
		static if (UseItem) {
			void setAddItem(void delegate(ref XNode node, string) addc) {
				_pane[ITEM].setAddCard = addc;
			}
		}
		static if (UseBeast) {
			void setAddBeast(void delegate(ref XNode node, string) addc) {
				_pane[BEAST].setAddCard = addc;
			}
		}
		static if (UseInfo) {
			void setAddInfo(void delegate(ref XNode node, string) addc) {
				_pane[INFO].setAddCard = addc;
			}
		}
	}
	private void refreshStatusLine() {
		if (!_win || _win.isDisposed) return;
		static if (1 < Cards.length) {
			int i = _tabf.getSelectionIndex;
			string s = "";
			static if (UseCast) if (i == CAST) s = _pane[CAST].statusLine;
			static if (UseSkill) if (i == SKILL) s = _pane[SKILL].statusLine;
			static if (UseItem) if (i == ITEM) s = _pane[ITEM].statusLine;
			static if (UseBeast) if (i == BEAST) s = _pane[BEAST].statusLine;
			static if (UseInfo) if (i == INFO) s = _pane[INFO].statusLine;
			_comm.statusLine(_tabf, s);
		} else {
			_comm.statusLine(_comp, _pane[0].statusLine);
		}
	}

	override {
		void cut(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.cut(se);
					}
				}
			}
		}
		void copy(SelectionEvent se) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.copy(se);
				}
			}
		}
		void paste(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.paste(se);
					}
				}
			}
		}
		void del(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.del(se);
					}
				}
			}
		}
		bool canDoTCPD() {
			return EditMode;
		}
	}

	private bool openCWXPathEff(int C)(string path) {
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool isId = std.string.endsWith(cate, ":id") != 0;
		typeof(_pane[C].cards[0]) card;
		if (isId) {
			card = _pane[C].card(index);
			if (!card) return false;
			index = .cCountUntil!("a is b")(_pane[C].cards, card);
		} else {
			if (index >= _pane[C].cards.length) return false;
			card = _pane[C].cards[index];
		}
		path = cpbottom(path);
		if (cpempty(path)) {
			forceFocus(_pane[C].widget);
			_pane[C].select(index);
			return true;
		}
		static if (is(PCardOwner : Summary)) {
			static if (UseCast && C == CAST) {
				cate = cpcategory(path);
				switch (cate) {
				case "skillcard", "itemcard", "beastcard",
						"skillcard:id", "itemcard:id", "beastcard:id": {
					forceFocus(_pane[C].widget);
					return _comm.openHands(_prop, _summ, card).openCWXPath(path);
				} break;
				default: break;
				}
			} else static if (!UseInfo || C != INFO) {
				if (cpcategory(path) == "event") {
					forceFocus(_pane[C].widget);
					return _comm.openUseEvents(_prop, _summ, card).openCWXPath(path);
				}
			}
		}
		return false;
	}
	bool openCWXPath(string path) {
		auto cate = cpcategory(path);
		switch (cate) {
		case "castcard", "castcard:id": {
			static if (UseCast) {
				return openCWXPathEff!(CAST)(path);
			}
		} break;
		case "skillcard", "skillcard:id": {
			static if (UseSkill) {
				return openCWXPathEff!(SKILL)(path);
			}
		} break;
		case "itemcard", "itemcard:id": {
			static if (UseItem) {
				return openCWXPathEff!(ITEM)(path);
			}
		} break;
		case "beastcard", "beastcard:id": {
			static if (UseBeast) {
				return openCWXPathEff!(BEAST)(path);
			}
		} break;
		case "infocard", "infocard:id": {
			static if (UseInfo) {
				return openCWXPathEff!(INFO)(path);
			}
		} break;
		default: break;
		}
		return false;
	}
}

alias CardWindow!("handCards(owner.id, owner.name)", "handCardsTab(owner.id, owner.name)",
	"menuAddScenario", Importable, CastCard, Summary, SkillCard, ItemCard, BeastCard) AddHandCardWindow;

// FIXME: 以下の二つをaliasにすると前方参照のエラーが発生する
class HandCardWindow : CardWindow!("handCards(owner.id, owner.name)",
		"handCardsTab(owner.id, owner.name)", "menuOpenHand",
		Summary, CastCard, void, SkillCard, ItemCard, BeastCard) {
	this (Commons comm, Props prop, Summary summ, Composite parent) {
		super (comm, prop, summ, parent);
	}
}
class MainCardWindow : CardWindow!("cardWindowName(owner)", "cardTabName(owner)",
		"menuCardWin", Summary, Summary, void, CastCard, SkillCard, ItemCard, BeastCard, InfoCard) {
	this (Commons comm, Props prop, Composite parent) {
		super (comm, prop, parent);
	}
}
alias CardWindow!("castWindowName(owner)", "castTabName(owner)", "menuCastWin", Summary, Summary, void, CastCard) CastCardWindow;
alias CardWindow!("skillWindowName(owner)", "skillTabName(owner)", "menuSkillWin", Summary, Summary, void, SkillCard) SkillCardWindow;
alias CardWindow!("itemWindowName(owner)", "itemTabName(owner)", "menuItemWin", Summary, Summary, void, ItemCard) ItemCardWindow;
alias CardWindow!("beastWindowName(owner)", "beastTabName(owner)", "menuBeastWin", Summary, Summary, void, BeastCard) BeastCardWindow;
alias CardWindow!("infoWindowName(owner)", "infoTabName(owner)", "menuInfoWin", Summary, Summary, void, InfoCard) InfoCardWindow;

private class DelTemp(CC) : DisposeListener {
	private CC _cc;
	this(CC cc) {
		_cc = cc;
	}
	override void widgetDisposed(DisposeEvent dse) {
		try {
			_cc.delTemp;
		} catch (Exception e) {
			debugln(e);
		}
	}
}
private class AddCard {
private:
	alias CardContainer!(true, true, true, true, true) CC;
	alias CardWindow!("addCardWindow(owner.scenarioName, owner.scenarioPath)",
		"addCardTab(owner.scenarioName, owner.scenarioPath)", "menuAddScenario",
		CC, CC, Summary, CastCard, SkillCard, ItemCard, BeastCard, InfoCard) ACW;
	static class AddS {
		Commons comm;
		Props prop;
		Composite parent;
		Summary toc;
		void delegate(Object[]) addScenario;
		this (Commons comm, Props prop,
				Composite parent, Summary toc, void delegate(Object[]) addScenario) {
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
					auto shl = cast(Shell) parent;
					auto pane = shl && !comm.singleWindowMode(prop) ? parent : comm.sidePane;
					auto acw = new ACW(comm, prop, pane, cc, cc, toc);
					acw.shell.addDisposeListener(new DelTemp!(CC)(cc));
					r ~= acw;
				}
			}
			addScenario(r);
		}
	}
	this() {}
	static Composite pane(Composite parent) {
		auto shl = cast(Shell) parent;
		if (shl) {
			return topShell(shl);
		} else {
			return parent;
		}
	}
public:
	static void openScenario(Commons comm, Props prop, Composite parent, void delegate(string) status,
			Summary summ, Summary toc, void delegate(Object[]) addScenario) {
		parent = pane(parent);
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenarios!(CC)(prop, comm.mainShell, status, false, prop.msgs.dlgTitAddScenario, &addS.addS);
	}
	static void openScenario(Commons comm, Props prop, Composite parent, void delegate(string) status,
			Summary summ, Summary toc, string[] files, void delegate(Object[]) addScenario) {
		parent = pane(parent);
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenariosFromFile!(CC)(prop, comm.mainShell, status, false, files, &addS.addS);
	}
}

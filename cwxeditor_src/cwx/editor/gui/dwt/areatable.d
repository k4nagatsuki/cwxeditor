
module cwx.editor.gui.dwt.areatable;

import cwx.flag;
import cwx.area;
import cwx.event;
import cwx.utils;
import cwx.summary;
import cwx.background;
import cwx.usecounter;
import cwx.xml;
import cwx.skin;
import cwx.path;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.flagtable;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.summarydialog;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.xmlbytestransfer;

import dwt.widgets.Display;
import dwt.widgets.Shell;
import dwt.widgets.Composite;
import dwt.widgets.Control;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.widgets.Text;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.graphics.Image;
import dwt.dwthelper.utils;
import dwt.events.ShellAdapter;
import dwt.events.ShellEvent;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.KeyAdapter;
import dwt.events.KeyEvent;
import dwt.events.MouseAdapter;
import dwt.events.MouseEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.dnd.DND;
import dwt.dnd.Transfer;
import dwt.dnd.DragSource;
import dwt.dnd.DragSourceListener;
import dwt.dnd.DragSourceAdapter;
import dwt.dnd.DragSourceEvent;
import dwt.dnd.ByteArrayTransfer;
import dwt.dnd.DropTargetAdapter;
import dwt.dnd.DropTargetEvent;
import dwt.dnd.DropTarget;
import dwt.dnd.Clipboard;

/// エリア・バトル・パッケージの一覧を表示する。
class AreaTable : TCPD {
private:
	void editEnd(TableItem itm, int column, string newText) {
		assert (column == 1);
		if (newText.length > 0) {
			auto area = cast(AbstractArea) itm.getData;
			area.name = newText;
			itm.setText(NAME, newText);
			if (cast(Area) area) {
				_comm.refArea.call(cast(Area) area);
			} else if (cast(Battle) area) {
				_comm.refBattle.call(cast(Battle) area);
			} else {
				assert (cast(Package) area);
				_comm.refPackage.call(cast(Package) area);
			}
		}
	}
	private static const ID = 0;
	private static const NAME = 1;
	private static const UC = 2;

	Commons _comm;
	Props _prop;
	FlagTable _flags = null;
	Summary _summ;

	Table _areas;
	TableTextEdit _areasEdit;

	string _statusLine = "";
	void refreshStatusLine() {
		Area[] areas;
		Battle[] battles;
		Package[] packages;
		if (_summ) {
			areas = _summ.areas;
			battles = _summ.battles;
			packages = _summ.packages;
		}
		_statusLine = _prop.msgs.areaStatus(areas, battles, packages, getSelectionArea);
		_comm.statusLine(_areas, _statusLine);
	}

	AbstractArea getSelectionArea() {
		auto itm = _areas.getSelection;
		if (itm.length > 0) {
			return cast(AbstractArea) itm[0].getData;
		}
		return null;
	}
	void refreshIDs() {
		foreach (itm; _areas.getItems) {
			itm.setText(ID, to!(string)((cast(AbstractArea) itm.getData).id));
		}
	}
	void openArea() {
		auto area = getSelectionArea;
		if (area) {
			auto a = cast(Area) area;
			if (a) {
				_comm.openArea(_prop, _summ, a);
				return;
			}
			auto b = cast(Battle) area;
			if (b) {
				_comm.openArea(_prop, _summ, b);
				return;
			}
			auto p = cast(Package) area;
			if (p) {
				_comm.openArea(_prop, _summ, p);
				return;
			}
		}
	}

	class DragArea : DragSourceAdapter {
		AbstractArea _data;
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource).getControl.isFocusControl;
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance.isSupportedType(e.dataType)) {
				auto tbl = cast(Table) (cast(DragSource) e.getSource).getControl;
				_data = cast(AbstractArea) tbl.getSelection[0].getData;
				e.data = bytesFromXML(_data.toXML(_summ.id));
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				auto area = _data;
				_summ.remove(area);
				delItem(area);
				if (cast(Area) area) {
					_comm.delArea.call(cast(Area) area);
				} else if (cast(Battle) area) {
					_comm.delBattle.call(cast(Battle) area);
				} else {
					assert (cast(Package) area);
					_comm.delPackage.call(cast(Package) area);
				}
				refreshStatusLine;
			}
		}
	}
	class DropArea : DropTargetAdapter {
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
				scope node = XNode.parse(xml);
				TypeInfo tid;
				if (node.name == Area.XML_NAME) {
					tid = typeid(Area);
				} else if (node.name == Battle.XML_NAME) {
					tid = typeid(Battle);
				} else if (node.name == Package.XML_NAME) {
					tid = typeid(Package);
				} else {
					return;
				}

				auto tbl = cast(Table) (cast(DropTarget) e.getSource).getControl;
				auto toItm = tbl.getItem(tbl.toControl(e.x, e.y));
				int count = tbl.getItemCount;
				int index = toItm ? tbl.indexOf(toItm) : count;
				int revId(int index) {
					if (tid == typeid(Area)) {
						if (_summ.areas.length < index) {
							index = _summ.areas.length;
						}
					} else if (tid == typeid(Battle)) {
						index -= _summ.areas.length;
						if (index < 0) {
							index = 0;
						} else if (_summ.battles.length < index) {
							index = _summ.battles.length;
						}
					} else {
						assert (tid == typeid(Package));
						index -= _summ.areas.length + _summ.battles.length;
						if (index < 0) {
							index = 0;
						} else if (_summ.packages.length < index) {
							index = _summ.packages.length;
						}
					}
					return index;
				}
				if (_summ.id == AbstractArea.summaryId(node)) {
					// 同一リスト内で移動。
					if ((index < count ? index : count - 1) == tbl.getSelectionIndex
							|| index == tbl.getSelectionIndex + 1) {
						tbl.showSelection;
						return;
					}
					index = revId(index);
					auto area = cast(AbstractArea) tbl.getSelection[0].getData;
					tbl.getSelection[0].dispose;
					if (tid == typeid(Area)) {
						_summ.insert(index, cast(Area) area);
						newAreaItem(index);
					} else if (tid == typeid(Battle)) {
						_summ.insert(index, cast(Battle) area);
						newBattleItem(index);
					} else {
						assert (tid == typeid(Package));
						_summ.insert(index, cast(Package) area);
						newPackageItem(index);
					}
					refreshIDs;
					refreshStatusLine;
					e.detail = DND.DROP_NONE;
				} else {
					// 他のリストからのコピー
					index = revId(index);
					AbstractArea area;
					if (tid == typeid(Area)) {
						area = Area.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Area) area);
						newAreaItem(index);
					} else if (tid == typeid(Battle)) {
						area = Battle.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Battle) area);
						newBattleItem(index);
					} else {
						assert (tid == typeid(Package));
						area = Package.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Package) area);
						newPackageItem(index);
					}
					e.detail = DND.DROP_NONE;
					_comm.refUseCount.call;
					refreshStatusLine;
				}
			} catch (Exception e) {
				debugln(e);
			}
		}
	}
	void __refreshUseCount() {
		foreach (itm; _areas.getItems) {
			auto element = itm.getData;
			if (cast(Area) element) {
				itm.setText(2, to!(string)(_summ.useCounter.area.get(toAreaId((cast(AbstractArea) element).id))));
			} else if (cast(Battle) element) {
				itm.setText(2, to!(string)(_summ.useCounter.battle.get(toBattleId((cast(AbstractArea) element).id))));
			} else {
				assert (cast(Package) element);
				itm.setText(2, to!(string)(_summ.useCounter.packages.get(toPackageId((cast(AbstractArea) element).id))));
			}
		}
	}
	class MListener : MouseAdapter {
		public override void mouseDoubleClick(MouseEvent e) {
			if (_areas.isFocusControl && e.button == 1) {
				openArea;
			}
		}
	}
	class KListener : KeyAdapter {
		public override void keyPressed(KeyEvent e) {
			if (_areas.isFocusControl && e.character == DWT.CR) {
				openArea;
			}
		}
	}
	class ADListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refUseCount.remove(&__refreshUseCount);
			_comm.replText.remove(&refresh);
		}
	}

	private void refreshAreas() {
		_areas.removeAll;
		if (_summ) {
			foreach (i, a; _summ.areas) {
				newAreaItem(i);
			}
			foreach (i, a; _summ.battles) {
				newBattleItem(i);
			}
			foreach (i, a; _summ.packages) {
				newPackageItem(i);
			}
		}
		refreshStatusLine;
	}
	void item(AbstractArea a, Image img, int uc, int index = -1) {
		TableItem itm;
		if (index >= 0) {
			itm = new TableItem(_areas, DWT.NONE, index);
		} else {
			itm = new TableItem(_areas, DWT.NONE);
		}
		itm.setImage(0, img);
		itm.setText(ID, to!(string)(a.id));
		itm.setText(NAME, a.name);
		itm.setText(UC, to!(string)(uc));
		itm.setData = a;
	}
	private void newAreaItem(int index) {
		auto a = _summ.areas[index];
		item(a, _prop.images.area, _summ.useCounter.get(toAreaId(a.id)), index);
	}
	private void newBattleItem(int index) {
		auto a = _summ.battles[index];
		index += _summ.areas.length;
		item(a, _prop.images.battle, _summ.useCounter.get(toBattleId(a.id)), index);
	}
	private void newPackageItem(int index) {
		auto a = _summ.packages[index];
		index += _summ.areas.length + _summ.battles.length;
		item(a, _prop.images.packages, _summ.useCounter.get(toPackageId(a.id)), index);
	}
	private class SListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshStatusLine;
		}
	}
public:
	this(Commons comm, Props prop, Composite parent, FlagTable flags) {
		_comm = comm;
		_prop = prop;
		_flags = flags;

		_comm.refUseCount.add(&__refreshUseCount);
		_comm.replText.add(&refresh);
		_areas = new Table(parent, DWT.BORDER | DWT.FULL_SELECTION);
		_areas.addDisposeListener(new ADListener);
		_areas.addSelectionListener(new SListener);
		_areas.setHeaderVisible = true;
		auto idCol = new TableColumn(_areas, DWT.NULL);
		idCol.setText = prop.msgs.areaId;
		saveColumnWidth!("prop.var.etc.areaIdColumn")(prop, idCol);
		auto nameCol = new TableColumn(_areas, DWT.NULL);
		nameCol.setText = prop.msgs.areaName;
		saveColumnWidth!("prop.var.etc.areaNameColumn")(prop, nameCol);
		auto countCol = new TableColumn(_areas, DWT.NULL);
		countCol.setText = prop.msgs.areaCount;
		saveColumnWidth!("prop.var.etc.areaCountColumn")(prop, countCol);

		_areasEdit = new TableTextEdit(_areas, 1, &editEnd);

		auto menu = new Menu(parent.getShell, DWT.POP_UP);
		createMenuItem(menu, prop.msgs.menuCEdit, prop.images.menuCEdit, &openArea);
		new MenuItem(menu, DWT.SEPARATOR);
		createMenuItem(menu, _prop.msgs.menuSummary, _prop.images.menuSummary, &editSummary);
		new MenuItem(menu, DWT.SEPARATOR);
		appendMenuTCPD(prop, menu, this);
		_areas.setMenu = menu;

		_areas.addMouseListener(new MListener);
		_areas.addKeyListener(new KListener);
		auto drag = new DragSource(_areas, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance]);
		drag.addDragListener(new DragArea);
		auto drop = new DropTarget(_areas, DND.DROP_DEFAULT | DND.DROP_MOVE);
		drop.setTransfer([XMLBytesTransfer.getInstance]);
		drop.addDropListener(new DropArea);
	}

	void editSummary() {
		if (!_summ) return;
		string oldName = _summ.scenarioName;
		string oldType = _summ.type;
		auto dlg = new SummaryDialog(_comm, _prop, _areas.getShell, _summ);
		if (dlg.open) {
			refresh;
			_comm.refUseCount.call;
			if (oldName != _summ.scenarioName) _comm.refScenarioName.call;
			if (oldType != _summ.type) {_comm.refSkin.call;}
		}
	}

	Control table() {
		return _areas;
	}

	string statusLine() {return _statusLine;}

	void refresh() {
		refreshAreas;
	}

	void summary(Summary summ) {
		_summ = summ;
		refreshAreas;
	}

	/// 新規エリアが作成され、名前の入力待ちになる。
	void createArea() {
		auto area = new Area(_summ.newAreaId, _prop.msgs.areaNew);
		auto p = _prop.looks.viewSize;
		area.append(new BgImage(findSkin(_prop, _summ).firstBgImage, "", 0, 0, p.width, p.height, false));
		auto tree = new EventTree(_prop.msgs.enterTree);
		tree.enter = true;
		area.add(tree);
		_summ.add(area);
		int index = _summ.areas.length - 1;
		newAreaItem(index);
		selArea(index);
		_areasEdit.startEdit;
		refreshStatusLine;
	}

	/// 新規バトルが作成され、名前の入力待ちになる。
	void createBattle() {
		auto btl = new Battle(_summ.newBattleId, _prop.msgs.battleNew, findSkin(_prop, _summ).defBattle);
		_summ.add(btl);
		int index = _summ.battles.length - 1;
		newBattleItem(index);
		selBattle(index);
		_areasEdit.startEdit;
		refreshStatusLine;
	}

	/// 新規パッケージが作成され、名前の入力待ちになる。
	ulong createPackage(Content baseStart = null) {
		auto pkg = new Package(_summ.newPackageId, baseStart ? baseStart.name : _prop.msgs.packageNew);
		EventTree et;
		if (baseStart) {
			et = new EventTree(baseStart);
		} else {
			et = new EventTree(_prop.msgs.packageTree);
		}
		pkg.add(et);
		_summ.add(pkg);
		int index = _summ.packages.length - 1;
		newPackageItem(index);
		selPackage(index);
		_areasEdit.startEdit;
		refreshStatusLine;
		return pkg.id;
	}
	private void selArea(int index) {
		_areas.setSelection = index;
		_areas.showSelection;
	}
	private void selBattle(int index) {
		_areas.setSelection = _summ.areas.length + index;
		_areas.showSelection;
	}
	private void selPackage(int index) {
		_areas.setSelection = _summ.areas.length + _summ.battles.length + index;
		_areas.showSelection;
	}

	void openArea(ulong id) {
		_comm.openArea(_prop, _summ, _summ.area(id));
	}
	void openBattle(ulong id) {
		_comm.openArea(_prop, _summ, _summ.battle(id));
	}
	void openPackage(ulong id) {
		_comm.openArea(_prop, _summ, _summ.packages(id));
	}

	override {
		void cut() {
			copy();
			del();
		}
		void copy() {
			auto area = getSelectionArea;
			if (area !is null) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(_prop, cb, area.toXML(_summ.id));
			}
		}
		void paste() {
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			auto c = CBtoXML(cb);
			if (c) {
				bool sameSummary;
				auto area = createAreaFromXML(c, _summ.id, sameSummary, LATEST_VERSION);
				if (area !is null) {
					auto oldId = area.id;
					if (cast(Area) area) {
						auto newId = _summ.add(cast(Area) area);
						int index = _summ.areas.length - 1;
						newAreaItem(index);
						selArea(index);
						if (sameSummary && !_summ.hasAreaId(oldId)) {
							_summ.useCounter.change(toAreaId(oldId), toAreaId(newId));
						}
					} else if (cast(Package) area) {
						auto newId = _summ.add(cast(Package) area);
						int index = _summ.packages.length - 1;
						newPackageItem(index);
						selPackage(index);
						if (sameSummary && !_summ.hasPackageId(oldId)) {
							_summ.useCounter.change(toPackageId(oldId), toPackageId(newId));
						}
					} else {
						assert (cast(Battle) area);
						auto newId = _summ.add(cast(Battle) area);
						int index = _summ.battles.length - 1;
						newBattleItem(index);
						selBattle(index);
						if (sameSummary && !_summ.hasBattleId(oldId)) {
							_summ.useCounter.change(toBattleId(oldId), toBattleId(newId));
						}
					}
					if (_flags) _flags.refresh;
					_comm.refUseCount.call;
					refreshStatusLine;
				}
			}
		}
		void del() {
			auto area = getSelectionArea;
			if (area) {
				_summ.remove(area);
				delItem(area);
				if (cast(Area) area) {
					_comm.delArea.call(cast(Area) area);
				} else if (cast(Battle) area) {
					_comm.delBattle.call(cast(Battle) area);
				} else {
					assert (cast(Package) area);
					_comm.delPackage.call(cast(Package) area);
				}
				if (_flags) _flags.refresh;
				_comm.refUseCount.call;
				refreshStatusLine;
			}
		}
		bool canDoTCPD() {
			return _areas.isFocusControl;
		}
	}
	private void delItem(AbstractArea area) {
		foreach (itm; _areas.getItems) {
			if (itm.getData is area) {
				itm.dispose;
				break;
			}
		}
	}
}



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

import cwx.editor.gui.dwt.commondialog;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.flagtable;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.summarydialog;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.xmlbytestransfer;

import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.graphics.Image;
import java.lang.all;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceListener;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.ByteArrayTransfer;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.Clipboard;

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
	void refArea(Object sender, Area a) {
		if (sender is this) return;
		foreach (itm; _areas.getItems[0 .. _summ.areas.length]) {
			if (itm.getData is a) refData(a, itm);
		}
	}
	void refBattle(Object sender, Battle a) {
		if (sender is this) return;
		size_t ai = _summ.areas.length;
		foreach (itm; _areas.getItems[ai .. ai + _summ.battles.length]) {
			if (itm.getData is a) refData(a, itm);
		}
	}
	void refPackage(Object sender, Package a) {
		if (sender is this) return;
		size_t ai = _summ.areas.length;
		size_t bi = _summ.battles.length;
		foreach (itm; _areas.getItems[ai + bi .. ai + bi + _summ.packages.length]) {
			if (itm.getData is a) refData(a, itm);
		}
	}
	void callRefArea(AbstractArea area) {
		auto a = cast(Area) area;
		if (a) {
			_comm.refArea.call(this, a);
			return;
		}
		auto b = cast(Battle) area;
		if (b) {
			_comm.refBattle.call(this, b);
			return;
		}
		auto p = cast(Package) area;
		if (p) {
			_comm.refPackage.call(this, p);
			return;
		}
	}
	void refreshIDs() {
		foreach (itm; _areas.getItems) {
			auto area = cast(AbstractArea) itm.getData;
			auto str = to!(string)(area.id);
			if (str != itm.getText(ID)) callRefArea(area);
			itm.setText(ID, str);
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
						index = _summ.indexOf(cast(Area) area);
						newAreaItem(index);
					} else if (tid == typeid(Battle)) {
						_summ.insert(index, cast(Battle) area);
						index = _summ.indexOf(cast(Battle) area);
						newBattleItem(index);
					} else {
						assert (tid == typeid(Package));
						_summ.insert(index, cast(Package) area);
						index = _summ.indexOf(cast(Package) area);
						newPackageItem(index);
					}
					callRefArea(area);
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
						index = _summ.indexOf(cast(Area) area);
						newAreaItem(index);
					} else if (tid == typeid(Battle)) {
						area = Battle.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Battle) area);
						index = _summ.indexOf(cast(Battle) area);
						newBattleItem(index);
					} else {
						assert (tid == typeid(Package));
						area = Package.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Package) area);
						index = _summ.indexOf(cast(Package) area);
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
			if (_areas.isFocusControl && e.character == SWT.CR) {
				openArea;
			}
		}
	}
	class ADListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refArea.remove(&refArea);
			_comm.refBattle.remove(&refBattle);
			_comm.refPackage.remove(&refPackage);
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
			itm = new TableItem(_areas, SWT.NONE, index);
		} else {
			itm = new TableItem(_areas, SWT.NONE);
		}
		itm.setImage(0, img);
		itm.setText(ID, to!(string)(a.id));
		itm.setText(NAME, a.name);
		itm.setText(UC, to!(string)(uc));
		itm.setData = a;
	}
	void refData(A)(A a, TableItem itm) {
		itm.setText(ID, to!(string)(a.id));
		itm.setText(NAME, a.name);
		itm.setText(UC, to!(string)(_summ.useCounter.get(A.toID(a.id))));
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

		_comm.refArea.add(&refArea);
		_comm.refBattle.add(&refBattle);
		_comm.refPackage.add(&refPackage);
		_comm.refUseCount.add(&__refreshUseCount);
		_comm.replText.add(&refresh);
		_areas = new Table(parent, SWT.BORDER | SWT.FULL_SELECTION);
		_areas.addDisposeListener(new ADListener);
		_areas.addSelectionListener(new SListener);
		_areas.setHeaderVisible = true;
		auto idCol = new TableColumn(_areas, SWT.NULL);
		idCol.setText = prop.msgs.areaId;
		saveColumnWidth!("prop.var.etc.areaIdColumn")(prop, idCol);
		auto nameCol = new TableColumn(_areas, SWT.NULL);
		nameCol.setText = prop.msgs.areaName;
		saveColumnWidth!("prop.var.etc.areaNameColumn")(prop, nameCol);
		auto countCol = new TableColumn(_areas, SWT.NULL);
		countCol.setText = prop.msgs.areaCount;
		saveColumnWidth!("prop.var.etc.areaCountColumn")(prop, countCol);

		_areasEdit = new TableTextEdit(_areas, 1, &editEnd);

		auto menu = new Menu(parent.getShell, SWT.POP_UP);
		createMenuItem(menu, prop.msgs.menuCEdit, prop.images.menuCEdit, &openArea);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(menu, _prop.msgs.menuSummary, _prop.images.menuSummary, &editSummary);
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(prop, menu, this);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(menu, _prop.msgs.menuReNumbering, _prop.images.menuReNumbering, &reNumbering);
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

	private int toAreaIndex(int index) {
		return (index >= 0 && index < _summ.areas.length) ? index : -1;
	}
	private int toBattleIndex(int index) {
		return (index >= 0 && index < _summ.areas.length + _summ.battles.length)
			? index - _summ.areas.length : -1;
	}
	private int toPackageIndex(int index) {
		return (index >= 0 && index < _summ.areas.length
			+ _summ.battles.length + _summ.packages.length)
			? index - _summ.areas.length - _summ.battles.length : -1;
	}

	void reNumberingAll() {
		reNumberingArea(0, 1);
		reNumberingBattle(0, 1);
		reNumberingPackage(0, 1);
	}
	void reNumBef(A)(A[] arr, int index) {
		for (size_t i = index; i < arr.length; i++) {
			ulong ni = ulong.max - arr.length + i;
			_summ.useCounter.change(A.toID(arr[i].id), A.toID(ni));
			arr[i].id = ni;
		}
	}
	void reNumberingArea(int index, ulong newId) {
		if (index < 0 || _summ.areas.length <= index) return;
		if (newId == 0) return;
		if (index > 0 && _summ.areas[index - 1].id >= newId) return;
		reNumBef(_summ.areas, index);
		for (size_t i = index; i < _summ.areas.length; i++) {
			_summ.useCounter.change(toAreaId(_summ.areas[i].id), toAreaId(newId));
			_summ.areas[i].id = newId;
			newId++;
		}
		refreshIDs;
	}
	void reNumberingBattle(int index, ulong newId) {
		if (index < 0 || _summ.battles.length <= index) return;
		if (newId == 0) return;
		if (index > 0 && _summ.battles[index - 1].id >= newId) return;
		reNumBef(_summ.battles, index);
		for (size_t i = index; i < _summ.battles.length; i++) {
			_summ.useCounter.change(toBattleId(_summ.battles[i].id), toBattleId(newId));
			_summ.battles[i].id = newId;
			newId++;
		}
		refreshIDs;
	}
	void reNumberingPackage(int index, ulong newId) {
		if (index < 0 || _summ.packages.length <= index) return;
		if (newId == 0) return;
		if (index > 0 && _summ.packages[index - 1].id >= newId) return;
		reNumBef(_summ.packages, index);
		for (size_t i = index; i < _summ.packages.length; i++) {
			_summ.useCounter.change(toPackageId(_summ.packages[i].id), toPackageId(newId));
			_summ.packages[i].id = newId;
			newId++;
		}
		refreshIDs;
	}
	void reNumbering() {
		if (!_summ) return;
		int index = _areas.getSelectionIndex;
		if (index < 0) return;
		int ai = toAreaIndex(index);
		if (ai >= 0) {
			auto dlg = new ReNumDialog!(Area)(_prop, _areas.getShell, _summ.areas[ai],
				ai == 0 ? 1 : _summ.areas[ai - 1].id + 1);
			if (dlg.open) {
				reNumberingArea(ai, dlg.newId);
			}
			return;
		}
		int bi = toBattleIndex(index);
		if (bi >= 0) {
			auto dlg = new ReNumDialog!(Battle)(_prop, _areas.getShell, _summ.battles[bi],
				bi == 0 ? 1 : _summ.battles[bi - 1].id + 1);
			if (dlg.open) {
				reNumberingBattle(bi, dlg.newId);
			}
			return;
		}
		int pi = toPackageIndex(index);
		if (pi >= 0) {
			auto dlg = new ReNumDialog!(Package)(_prop, _areas.getShell, _summ.packages[pi],
				pi == 0 ? 1 : _summ.packages[pi - 1].id + 1);
			if (dlg.open) {
				reNumberingPackage(pi, dlg.newId);
			}
			return;
		}
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
		auto bgImages = BgImageS.createBgImages(_comm.skin, _prop.var.etc.bgImagesDefault);
		foreach (b; bgImages) {
			area.append(b);
		}
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
		auto btl = new Battle(_summ.newBattleId, _prop.msgs.battleNew, _comm.skin.defBattle);
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
		void cut(SelectionEvent se) {
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) {
			auto area = getSelectionArea;
			if (area !is null) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(_prop, cb, area.toXML(_summ.id));
			}
		}
		void paste(SelectionEvent se) {
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			auto c = CBtoXML(cb);
			if (c) {
				try {
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
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) {
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


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
import dwt.graphics.Image;
import dwt.dwthelper.utils;
import dwt.events.ShellEvent;
import dwt.events.ShellAdapter;
import dwt.events.KeyEvent;
import dwt.events.KeyAdapter;
import dwt.events.MouseEvent;
import dwt.events.MouseAdapter;
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

import dwtx.jface.viewers.Viewer;
import dwtx.jface.viewers.TableViewer;
import dwtx.jface.viewers.IStructuredContentProvider;
import dwtx.jface.viewers.ITableLabelProvider;
import dwtx.jface.viewers.ILabelProviderListener;
import dwtx.jface.viewers.ICellModifier;
import dwtx.jface.viewers.TextCellEditor;
import dwtx.jface.viewers.CellEditor;
import dwtx.jface.action.Action;
import dwtx.jface.action.IAction;
import dwtx.jface.action.MenuManager;
import dwtx.jface.action.Separator;

public:

/// エリア・バトル・パッケージの一覧を表示する。
class AreaTable : TCPD {
private:
	class AreaTableContentProvider : IStructuredContentProvider {
	public:
		override Object[] getElements(Object inputElement) {
			AbstractArea[] r;
			if (cast(Summary) inputElement) {
				auto summ = cast(Summary) inputElement;
				r ~= summ.areas;
				r ~= summ.battles;
				r ~= summ.packages;
			}
			return r;
		}
		override void inputChanged(Viewer viewer, Object oldInput, Object newInput) {}
		override void dispose() {}
	}

	class AreaTableLabelProvider : ITableLabelProvider {
	public:
		override string getColumnText(Object element, int columnIndex) {
			switch (columnIndex) {
			case 0:
				return to!(string)((cast(AbstractArea) element).id);
			case 1:
				return (cast(AbstractArea) element).name;
			case 2:
				if (cast(Area) element) {
					return to!(string)(_summ.useCounter.area.get(toAreaId((cast(AbstractArea) element).id)));
				} else if (cast(Battle) element) {
					return to!(string)(_summ.useCounter.battle.get(toBattleId((cast(AbstractArea) element).id)));
				} else {
					assert (cast(Package) element);
					return to!(string)(_summ.useCounter.packages.get(toPackageId((cast(AbstractArea) element).id)));
				}
				return "";
			}
		}
		override Image getColumnImage(Object element, int columnIndex) {
			if (columnIndex == 0) {
				if (cast(Area) element) {
					return _prop.images.area;
				} else if (cast(Battle) element) {
					return _prop.images.battle;
				} else {
					assert (cast(Package) element);
					return _prop.images.packages;
				}
			}
			return null;
		}
		override void addListener(ILabelProviderListener listener) {}
		override void removeListener(ILabelProviderListener listener) {}
		override bool isLabelProperty(Object element, string property) {
			return property == "name";
		}
		override void dispose() {}
	}

	void editEnd(TableItem itm, int column, string newText) {
		assert (column == 1);
		if (newText.length > 0) {
			auto area = cast(AbstractArea) itm.getData;
			area.name = newText;
			if (cast(Area) area) {
				_comm.refArea.call(cast(Area) area);
			} else if (cast(Battle) area) {
				_comm.refBattle.call(cast(Battle) area);
			} else {
				assert (cast(Package) area);
				_comm.refPackage.call(cast(Package) area);
			}
			_areasV.update(area, null);
		}
	}

	Commons _comm;
	Props _prop;
	FlagTable _flags;
	Summary _summ;

	Table _areas;
	TableViewer _areasV;
	TableTextEdit _areasEdit;

	AbstractArea getSelectionArea() {
		auto itm = _areas.getSelection;
		if (itm.length > 0) {
			return cast(AbstractArea) itm[0].getData;
		}
		return null;
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
				if (cast(Area) area) {
					_comm.delArea.call(cast(Area) area);
				} else if (cast(Battle) area) {
					_comm.delBattle.call(cast(Battle) area);
				} else {
					assert (cast(Package) area);
					_comm.delPackage.call(cast(Package) area);
				}
				_areasV.refresh;
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
					if (tid == typeid(Area)) {
						_summ.insert(index, cast(Area) area);
					} else if (tid == typeid(Battle)) {
						_summ.insert(index, cast(Battle) area);
					} else {
						assert (tid == typeid(Package));
						_summ.insert(index, cast(Package) area);
					}
					e.detail = DND.DROP_NONE;
					_areasV.refresh;
				} else {
					// 他のリストからのコピー
					index = revId(index);
					AbstractArea area;
					if (tid == typeid(Area)) {
						area = Area.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Area) area);
					} else if (tid == typeid(Battle)) {
						area = Battle.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Battle) area);
					} else {
						assert (tid == typeid(Package));
						area = Package.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Package) area);
					}
					_areasV.refresh;
					e.detail = DND.DROP_NONE;
					_comm.refUseCount.call;
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
public:
	this(Commons comm, Props prop, Composite parent, FlagTable flags) {
		_comm = comm;
		_prop = prop;
		_flags = flags;

		_comm.refUseCount.add(&__refreshUseCount);
		_comm.replText.add(&refresh);
		_areas = new Table(parent, DWT.BORDER | DWT.FULL_SELECTION);
		_areas.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refUseCount.remove(&__refreshUseCount);
				_comm.replText.remove(&refresh);
			}
		});
		_areasV = new TableViewer(_areas);
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

		_areasV.setContentProvider(new AreaTableContentProvider);
		_areasV.setLabelProvider(new AreaTableLabelProvider);

		_areasEdit = new TableTextEdit(_areas, 1, &editEnd);

		auto menu = new Menu(parent.getShell, DWT.POP_UP);
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

	void setFocus() {
		_areas.setFocus;
	}

	Control table() {
		return _areas;
	}

	void refresh() {
		_areasV.refresh;
	}

	void summary(Summary summ) {
		_summ = summ;
		_areasV.setInput(_summ);
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
		_areasV.refresh;
		_areas.setSelection = _summ.areas.length - 1;
		_areas.showSelection;
		_areasEdit.startEdit;
	}

	/// 新規バトルが作成され、名前の入力待ちになる。
	void createBattle() {
		auto btl = new Battle(_summ.newBattleId, _prop.msgs.battleNew, findSkin(_prop, _summ).defBattle);
		_summ.add(btl);
		_areasV.refresh;
		_areas.setSelection = _summ.areas.length + _summ.battles.length - 1;
		_areas.showSelection;
		_areasEdit.startEdit;
	}

	/// 新規パッケージが作成され、名前の入力待ちになる。
	void createPackage() {
		auto pkg = new Package(_summ.newPackageId, _prop.msgs.packageNew);
		pkg.add(new EventTree(_prop.msgs.packageTree));
		_summ.add(pkg);
		_areasV.refresh;
		_areas.setSelection = _summ.areas.length + _summ.battles.length + _summ.packages.length - 1;
		_areas.showSelection;
		_areasEdit.startEdit;
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
						if (sameSummary && !_summ.hasAreaId(oldId)) {
							_summ.useCounter.change(toAreaId(oldId), toAreaId(newId));
						}
					} else if (cast(Package) area) {
						auto newId = _summ.add(cast(Package) area);
						if (sameSummary && !_summ.hasPackageId(oldId)) {
							_summ.useCounter.change(toPackageId(oldId), toPackageId(newId));
						}
					} else {
						assert (cast(Battle) area);
						auto newId = _summ.add(cast(Battle) area);
						if (sameSummary && !_summ.hasBattleId(oldId)) {
							_summ.useCounter.change(toBattleId(oldId), toBattleId(newId));
						}
					}
					_flags.refresh;
					_areasV.refresh;
					_comm.refUseCount.call;
				}
			}
		}
		void del() {
			auto area = getSelectionArea;
			if (area) {
				_summ.remove(area);
				if (cast(Area) area) {
					_comm.delArea.call(cast(Area) area);
				} else if (cast(Battle) area) {
					_comm.delBattle.call(cast(Battle) area);
				} else {
					assert (cast(Package) area);
					_comm.delPackage.call(cast(Package) area);
				}
				_flags.refresh;
				_areasV.refresh;
				_comm.refUseCount.call;
			}
		}
		bool canDoTCPD() {
			return _areas.isFocusControl;
		}
	}
}


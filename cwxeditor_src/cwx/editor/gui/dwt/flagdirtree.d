
module cwx.editor.gui.dwt.flagdirtree;

import cwx.utils;
import cwx.flag;
import cwx.usecounter;
import cwx.path;

import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.flagtable;
import cwx.editor.gui.dwt.xmlbytestransfer;

import dwt.DWT;
import dwt.DWTException;
import dwt.widgets.Shell;
import dwt.widgets.Control;
import dwt.widgets.Display;
import dwt.layout.FillLayout;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.widgets.Composite;
import dwt.widgets.Tree;
import dwt.widgets.TreeItem;
import dwt.custom.TreeEditor;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.widgets.Text;
import dwt.widgets.Label;
import dwt.widgets.Combo;
import dwt.widgets.Table;
import dwt.widgets.Menu;
import dwt.events.SelectionEvent;
import dwt.events.SelectionAdapter;
import dwt.events.FocusEvent;
import dwt.events.FocusListener;
import dwt.events.KeyListener;
import dwt.events.KeyAdapter;
import dwt.events.KeyEvent;
import dwt.events.MouseListener;
import dwt.events.MouseAdapter;
import dwt.events.MouseEvent;
import dwt.events.ModifyListener;
import dwt.events.ModifyEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.dwthelper.utils;
import dwt.dnd.DND;
import dwt.dnd.Transfer;
import dwt.dnd.TransferData;
import dwt.dnd.DragSource;
import dwt.dnd.DragSourceListener;
import dwt.dnd.DragSourceEvent;
import dwt.dnd.ByteArrayTransfer;
import dwt.dnd.DropTargetAdapter;
import dwt.dnd.DropTargetEvent;
import dwt.dnd.DropTarget;
import dwt.dnd.Clipboard;

public class FlagDirTree : TCPD {
private:
	Props prop;
	UseCounter uc;
	Commons _comm;

	Tree dirs;
	FlagTable flags;

	FlagDir root = null;
	TreeEdit edit;

	class DirSelection : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			flags.dir = current;
		}
	}

	class FlagDirDragListener : DragSourceListener {
	private:
		FlagDir moveDir;
	public:
		override void dragStart(DragSourceEvent e) {
			e.doit = current != root && (cast(DragSource) e.getSource).getControl.isFocusControl;
		}
		override void dragSetData(DragSourceEvent e) {
			if (XMLBytesTransfer.getInstance.isSupportedType(e.dataType)) {
				moveDir = current;

				// XML化して転送する。
				e.data = bytesFromXML(getXML(prop.msgs.flagDirRoot, moveDir));
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				moveDir.parent.remove(moveDir);
				refresh;
				_comm.delFlagAndStep.call(moveDir.allFlags, moveDir.allSteps);
			}
		}
	}
	class FlagsDropListener : DropTargetAdapter {
	private:
		void move(DropTargetEvent e) {
			e.detail = (e.item !is null && cast(TreeItem) e.item) ? DND.DROP_MOVE : DND.DROP_NONE;
		}
	public:
		override void dragEnter(DropTargetEvent e){
			move(e);
		}
		override void dragOver(DropTargetEvent e){
			move(e);
		}

		override void drop(DropTargetEvent e){
			if (!isXMLBytes(e.data)) return;
			assert (cast(TreeItem) e.item);
			if (cast(FlagDir) e.item.getData) {
				auto data = bytesToXML(e.data);
				auto dir = cast(FlagDir) e.item.getData;
				string newPath;
				Flag[string] cFlags;
				Step[string] cSteps;
				auto ret = dir.appendFromXML(data, LATEST_VERSION, false, true, cFlags, cSteps, newPath);
				switch (ret) {
				case FlagDir.AppendXmlResult.DIR_SUCCESS:
					e.detail = DND.DROP_MOVE;
					refresh(newPath);
					break;
				case FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS:
					e.detail = DND.DROP_MOVE;
					if (cFlags.length > 0) dir.sortFlags;
					if (cSteps.length > 0) dir.sortSteps;
					flags.refresh;
					break;
				case FlagDir.AppendXmlResult.ON_DIR:
					e.detail = DND.DROP_NONE;
					refresh;
					break;
				case FlagDir.AppendXmlResult.FLAG_STEP_ON_DIR:
					e.detail = DND.DROP_NONE;
					break;
				case FlagDir.AppendXmlResult.FAIL:
					e.detail = DND.DROP_NONE;
					break;
				}
				if (ret == FlagDir.AppendXmlResult.DIR_SUCCESS
						|| ret == FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS) {
					foreach (oldPath; cFlags.keys) {
						uc.change(toFlagId(oldPath), toFlagId(cFlags[oldPath].path));
					}
					foreach (oldPath; cSteps.keys) {
						uc.change(toStepId(oldPath), toStepId(cSteps[oldPath].path));
					}
					_comm.refFlagAndStep.call(cFlags.values, cSteps.values);
				}
			} else {
				e.detail = DND.DROP_NONE;
			}
		}
	}

	void editEnd(TreeItem itm, Control c) {
		auto dir = cast(FlagDir) itm.getData;
		dir.name = (cast(Text) c).getText;
		itm.setText = dir.name;
	}

	Control createEditor(TreeItem itm) {
		return itm.getData != root ? createTextEditor(dirs, itm.getText) : null;
	}

	private void refreshDirs() {
		dirs.setRedraw = false;
		scope (exit) dirs.setRedraw = true;
		auto exAll = expandAll;
		auto sel = current;
		dirs.removeAll;
		if (root) {
			newItem(root, dirs, exAll);
			if (sel) {
				current = sel;
			}
		}
	}
	private FlagDir[] expandAll() {
		FlagDir[] all(TreeItem itm) {
			FlagDir[] r;
			auto dir = cast(FlagDir) itm.getData;
			if (itm.getExpanded) r ~= dir;
			foreach (sub; itm.getItems) {
				r ~= all(sub);
			}
			return r;
		}
		return dirs.getItemCount ? all(dirs.getItem(0)) : cast(FlagDir[]) [];
	}
	private void newItem(T)(FlagDir dir, T parent, FlagDir[] exAll) {
		auto sItm = new TreeItem(parent, DWT.NONE);
		sItm.setImage = prop.images.flagDir;
		static if (is(T : Tree)) {
			sItm.setText = prop.msgs.flagDirRoot;
		} else {
			sItm.setText = dir.name;
		}
		sItm.setData = dir;
		foreach (sub; dir.subDirs) {
			newItem(sub, sItm, exAll);
		}
		if (contains!("a is b")(exAll, dir)) {
			sItm.setExpanded = true;
		}
	}
	private void refreshDirs(FlagDir targ) {
		dirs.setRedraw = false;
		scope (exit) dirs.setRedraw = true;
		auto itm = find(targ);
		if (itm) {
			auto exAll = expandAll;
			auto sel = current;
			itm.removeAll;
			foreach (sub; targ.subDirs) {
				newItem(sub, itm, exAll);
			}
			if (sel) current = sel;
		}
	}
	private TreeItem findImpl(TreeItem parent, FlagDir dir) {
		if (parent.getData is dir) return parent;
		foreach (itm; parent.getItems) {
			auto r = findImpl(itm, dir);
			if (r) return r;
		}
		return null;
	}
	private TreeItem find(FlagDir dir) {
		if (!root) return null;
		return findImpl(dirs.getItem(0), dir);
	}
	private void select(FlagDir dir) {
		auto itm = find(dir);
		if (itm) {
			dirs.select = itm;
		}
	}
public:
	this(Commons comm, Props prop, FlagTable flags) {
		_comm = comm;
		this.prop = prop;
		this.flags = flags;
	}
	private Composite _comp = null;
	Control widget() {return _comp;}

	void refresh() {
		refresh(null);
	}
	void refresh(string selPath) {
		if (!selPath) {
			selPath = current.path;
		}
		refreshDirs;
		select(selPath);
	}

	void select(string path) {
		auto dir = FlagDir.searchPath(root, path);
		if (!dir) {
			current = root;
		} else {
			current = dir;
		}
	}

	/// 使用回数カウンタを設定する。
	/// Params:
	/// uc = 使用回数カウンタ。
	void useCounter(UseCounter uc) {
		this.uc = uc;
	}

	/// コントロールを生成する。
	/// Params:
	/// parent = 親コントロール。
	Control createControl(Composite parent) {
		_comp = new Composite(parent, DWT.NONE);
		_comp.setLayout = new FillLayout;
		dirs = new Tree(_comp, DWT.SINGLE | DWT.BORDER);

		edit = new TreeEdit(dirs, &editEnd, &createEditor);

		dirs.addSelectionListener(new DirSelection);
		auto menu = new Menu(dirs.getShell, DWT.POP_UP);
		appendMenuTCPD(prop, menu, this);
		dirs.setMenu(menu);

		auto ds = new DragSource(dirs, DND.DROP_MOVE);
		ds.setTransfer = [XMLBytesTransfer.getInstance];
		ds.addDragListener(new FlagDirDragListener);
		auto dt = new DropTarget(dirs, DND.DROP_MOVE);
		dt.setTransfer = [XMLBytesTransfer.getInstance];
		dt.addDropListener(new FlagsDropListener);

		_comm.replText.add(&refresh);
		dirs.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.replText.remove(&refresh);
			}
		});
		return _comp;
	}

	/// 新規ディレクトリを生成する。
	/// ディレクトリ名は「新しいフォルダ(Propsで定義)」となり、
	/// すでに同名のディレクトリが存在する場合は"(2)"～をつける。
	void createDir() {
		auto cur = current;
		auto dir = new FlagDir(cur.createNewDirName(prop.msgs.flagDirNew));
		cur.add(dir);
		refreshDirs(cur);
		current = dir;
		edit.startEdit;
	}

	private void current(FlagDir dir) {
		auto itm = find(dir);
		if (itm) {
			dirs.select = itm;
			dirs.showSelection;
			flags.dir = dir;
		}
	}

	private FlagDir current() {
		auto sels = dirs.getSelection;
		if (sels.length) {
			return cast(FlagDir) sels[0].getData;
		}
		return root;
	}

	override {
		void cut(int stateMask) {
			if (!root) return;
			if (current !is root) {
				copy(stateMask);
				del(stateMask);
			}
		}
		void copy(int stateMask) {
			if (!root) return;
			if (dirs.getSelection.length > 0) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(prop, cb, getXML(prop.msgs.flagDirRoot, current));
			}
		}
		void paste(int stateMask) {
			if (!root) return;
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			auto c = CBtoXML(cb);
			if (c) {
				auto cur = current;
				string newPath;
				Flag[string] cFlags;
				Step[string] cSteps;
				switch (cur.appendFromXML(c, LATEST_VERSION, true, true, cFlags, cSteps, newPath)) {
				case FlagDir.AppendXmlResult.DIR_SUCCESS:
					refresh(newPath);
					auto itm = find(current);
					if (itm) treeExpandedAll(itm);
					break;
				case FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS:
					flags.refresh;
					break;
				case FlagDir.AppendXmlResult.FLAG_STEP_ON_DIR:
				case FlagDir.AppendXmlResult.ON_DIR:
					assert (false);
				default:
				}
				_comm.refFlagAndStep.call(cFlags.values, cSteps.values);
			}
		}
		void del(int stateMask) {
			if (!root) return;
			auto cur = current;
			if (cur != root) {
				Flag[] cFlags = cur.allFlags;
				Step[] cSteps = cur.allSteps;
				auto p = cur.parent;
				p.remove(cur);
				current = p;
				refreshDirs(p);
				_comm.delFlagAndStep.call(cFlags, cSteps);
			}
		}
		bool canDoTCPD() {
			return dirs.isFocusControl;
		}
	}

	/// Returns: ルートディレクトリを返す。
	FlagDir rootDir() {
		return root;
	}

	/// ディレクトリツリーを設定する。
	/// Params:
	/// root = ルートディレクトリ。
	void rootDir(FlagDir root) {
		this.root = root;
		refreshDirs;
		current = root;
		treeExpandedAll(dirs);
	}

	private bool openCWXPathImpl(FlagDir dir, string path) {
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "flag": {
			if (index >= dir.flags.length) return false;
			forceFocus(flags.widget);
			current = dir;
			flags.select(dir.flags[index]);
			return true;
		} break;
		case "step": {
			if (index >= dir.steps.length) return false;
			forceFocus(flags.widget);
			current = dir;
			flags.select(dir.steps[index]);
			return true;
		} break;
		case "dir": {
			if (index >= dir.subDirs.length) return false;
			return openCWXPathImpl(dir.subDirs[index], cpbottom(path));
		} break;
		case "": {
			forceFocus(dirs);
			current = dir;
			return true;
		}
		default: break;
		}
		return false;
	}
	bool openCWXPath(string path) {
		return openCWXPathImpl(root, path);
	}
}

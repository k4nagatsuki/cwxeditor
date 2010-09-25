
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

import dwtx.jface.dialogs.Dialog;
import dwtx.jface.dialogs.IDialogConstants;
import dwtx.jface.viewers.Viewer;
import dwtx.jface.viewers.TableViewer;
import dwtx.jface.viewers.TreeViewer;
import dwtx.jface.viewers.ITreeContentProvider;
import dwtx.jface.viewers.IStructuredContentProvider;
import dwtx.jface.viewers.ITableLabelProvider;
import dwtx.jface.viewers.LabelProvider;
import dwtx.jface.viewers.ILabelProviderListener;
import dwtx.jface.viewers.TreeSelection;
import dwtx.jface.viewers.TreePath;
import dwtx.jface.viewers.ICellModifier;
import dwtx.jface.viewers.TextCellEditor;

public class FlagDirTree : TCPD {
private:
	class FlagDirContentProvider : ITreeContentProvider {
	public override:
		Object[] getChildren(Object parentElement) {
			return (cast(FlagDir) parentElement).subDirs;
		}
		Object getParent(Object element) {
			return (cast(FlagDir) element).parent;
		}
		bool hasChildren(Object element) {
			return (cast(FlagDir) element).subDirs.length > 0;
		}
		Object[] getElements(Object inputElement) {
			if (cast(FlagDir) inputElement) {
				return (cast(FlagDir) inputElement).subDirs;
			} else if (root !is null) {
				return [root];
			} else {
				return [];
			}
		}
		void dispose() {}
		void inputChanged(Viewer viewer, Object oldInput, Object newInput) {}
	}
	class FlagDirLabelProvider : LabelProvider {
	public override:
		string getText(Object element) {
			return element == root ? prop.msgs.flagDirRoot : (cast(FlagDir) element).name;
		}
		Image getImage(Object element) {
			return prop.images.flagDir;
		}
		void dispose() {}
	}

	Props prop;
	UseCounter uc;
	Commons _comm;

	Tree dirs;
	TreeViewer dirsV;
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
		(cast(FlagDir) itm.getData).name = (cast(Text) c).getText;
		dirsV.refresh(itm.getData);
	}

	Control createEditor(TreeItem itm) {
		return itm.getData != root ? createTextEditor(dirs, itm.getText) : null;
	}

public:
	this(Commons comm, Props prop, FlagTable flags) {
		_comm = comm;
		this.prop = prop;
		this.flags = flags;
	}
	Control widget() {return dirs;}

	void refresh() {
		refresh(null);
	}

	void refresh(string selPath) {
		dirs.setRedraw = false;
		if (selPath is null) {
			selPath = current.path;
		}
		dirsV.refresh(root);
		select(selPath);
		dirs.setRedraw = true;
	}

	void select(string path) {
		auto dir = FlagDir.searchPath(root, path);
		if (dir is null) {
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
		dirs = new Tree(parent, DWT.SINGLE | DWT.BORDER);
		dirsV = new TreeViewer(dirs);
		dirsV.setContentProvider(new FlagDirContentProvider);
		dirsV.setLabelProvider(new FlagDirLabelProvider);

		edit = new TreeEdit(dirs, &editEnd, &createEditor);

		dirsV.setInput(new Object);

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
		return dirs;
	}

	/// 新規ディレクトリを生成する。
	/// ディレクトリ名は「新しいフォルダ(Propsで定義)」となり、
	/// すでに同名のディレクトリが存在する場合は"(2)"～をつける。
	void createDir() {
		auto cur = current;
		auto dir = new FlagDir(cur.createNewDirName(prop.msgs.flagDirNew));
		cur.add(dir);
		dirsV.refresh(cur);
		current = dir;
		edit.startEdit;
	}

	private void current(FlagDir dir) {
		auto sel = new TreeSelection(new TreePath([dir]));
		dirsV.setSelection(sel);
		flags.dir = dir;
	}

	private FlagDir current() {
		auto s = cast(TreeSelection) dirsV.getSelection;
		if (!s.isEmpty) {
			return cast(FlagDir) s.getPaths[0].getLastSegment;
		}
		return root;
	}

	override {
		void cut() {
			if (!root) return;
			if (current !is root) {
				copy();
				del();
			}
		}
		void copy() {
			if (!root) return;
			if (dirs.getSelection.length > 0) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(prop, cb, getXML(prop.msgs.flagDirRoot, current));
			}
		}
		void paste() {
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
		void del() {
			if (!root) return;
			auto cur = current;
			if (cur != root) {
				Flag[] cFlags = cur.allFlags;
				Step[] cSteps = cur.allSteps;
				auto p = cur.parent;
				p.remove(cur);
				current = p;
				dirsV.refresh(p);
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
		current = root;
		dirsV.refresh;
		dirsV.expandAll;
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

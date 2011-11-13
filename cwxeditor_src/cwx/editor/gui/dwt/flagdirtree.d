
module cwx.editor.gui.dwt.flagdirtree;

import cwx.utils;
import cwx.flag;
import cwx.usecounter;
import cwx.path;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.flagtable;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.custom.TreeEditor;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.FocusListener;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import java.lang.all;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.dnd.TransferData;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceListener;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.ByteArrayTransfer;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.Clipboard;

public class FlagDirTree : TCPD {
private:
	void storeInsert(FlagDir dir, int[] selected, int[] dirIndices, string[] flagName, string[] stepName) {
		_undo ~= new UndoInsertDelete(flags, _comm, dir, selected, dirIndices, flagName, stepName);
	}
	void storeDelete(FlagDir dir, int[] selected, FlagDir[int] ds, Flag[] fs, Step[] ss) {
		_undo ~= new UndoInsertDelete(flags, _comm, dir, selected, ds, fs, ss);
	}
	void storeMove(int[] selected, FlagDir to, int[] dirIndices, string[] flagName, string[] stepName, FlagDir from, FlagDir[int] ds, Flag[] fs, Step[] ss, Flag[string] cFlags, Step[string] cSteps) {
		_undo ~= new UndoMove(flags, _comm, selected, to, dirIndices, flagName, stepName, from, ds, fs, ss, cFlags, cSteps);
	}
	void storeEditDir(FlagDir dir, string oldName) {
		_undo ~= new UndoEditDir(flags, _comm, dir, oldName);
	}

	Props prop;
	UseCounter uc;
	Commons _comm;

	Tree dirs;
	FlagTable flags;

	UndoManager _undo;

	FlagDir root = null;
	TreeEdit edit;

	class DirSelection : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			flags.dir = current;
		}
	}

	FlagDir _moveDir = null;
	class FlagDirDragListener : DragSourceListener {
	public:
		override void dragStart(DragSourceEvent e) {
			e.doit = current != root && (cast(DragSource) e.getSource).getControl.isFocusControl;
		}
		override void dragSetData(DragSourceEvent e) {
			if (XMLBytesTransfer.getInstance.isSupportedType(e.dataType)) {
				_moveDir = current;

				// XML化して転送する。
				e.data = bytesFromXML(getXML(prop.msgs.flagDirRoot, _moveDir));
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				_moveDir.parent.remove(_moveDir);
				refresh;
				_comm.delFlagAndStep.call(_moveDir.allFlags, _moveDir.allSteps);
			}
			_moveDir = null;
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
				string rootId;
				Flag[] fs = flags.dragFlags;
				Step[] ss = flags.dragSteps;
				Flag[string] cFlags;
				Step[string] cSteps;
				int[] tblSels;
				FlagDir moveDirParent = null;
				if (current is dir) {
					tblSels = flags.selected();
				}
				int dirIndex = -1;
				if (_moveDir) {
					moveDirParent = _moveDir.parent;
					dirIndex = moveDirParent.indexOf(_moveDir.name);
				}
				string[] flagName() {
					string[] name;
					foreach (f; cFlags) {
						name ~= f.name;
					}
					return name;
				}
				string[] stepName() {
					string[] name;
					foreach (s; cSteps) {
						name ~= s.name;
					}
					return name;
				}
				auto ret = dir.appendFromXML(data, LATEST_VERSION, false, true, cFlags, cSteps, newPath, rootId);
				bool samePane = dir.root.id == rootId;
				final switch (ret) {
				case FlagDir.AppendXmlResult.DIR_SUCCESS:
					string dirName = FlagDir.basename(newPath);
					if (samePane) {
						e.detail = DND.DROP_MOVE;
						assert (moveDirParent);
						storeMove(tblSels, dir, [dir.indexOf(dirName)], [], [], moveDirParent, [dirIndex:_moveDir], [], [], cFlags, cSteps);
						_comm.delFlagDir.call(this.outer, [_moveDir]);
						_comm.refFlagDir.call(this.outer, [_moveDir]);
					} else {
						e.detail = DND.DROP_COPY;
						storeInsert(dir, tblSels, [dir.indexOf(dirName)], [], []);
						cdebugln(root.findPath(newPath, false).name);
						_comm.refFlagDir.call(this.outer, [root.findPath(newPath, false)]);
					}
					refresh(newPath);
					break;
				case FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS:
					if (samePane) {
						e.detail = DND.DROP_MOVE;
						FlagDir[int] ds;
						storeMove(tblSels, dir, [], flagName, stepName, current, ds, fs, ss, cFlags, cSteps);
					} else {
						e.detail = DND.DROP_COPY;
						storeInsert(dir, tblSels, [], flagName, stepName);
					}
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
				if ((ret == FlagDir.AppendXmlResult.DIR_SUCCESS
						|| ret == FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS)
						&& samePane) {
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
		auto text = (cast(Text) c).getText;
		if (!text) text = "";
		string oldName = dir.name;
		if (oldName == text) return;
		if (dir.rename(text, uc)) {
			storeEditDir(dir, oldName);
			itm.setText = dir.name;
			_comm.refFlagDir.call(this, [dir]);
		}
	}

	Control createEditor(TreeItem itm) {
		return itm.getData != root ? createTextEditor(dirs, itm.getText) : null;
	}

	private void refreshDirs() {
		if (!dirs || dirs.isDisposed) return;
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
	private bool[string] expandAll() {
		bool[string]  r;
		void all(TreeItem itm) {
			auto dir = cast(FlagDir) itm.getData;
			r[dir.path.toLower] = itm.getItemCount == 0 || itm.getExpanded;
			foreach (sub; itm.getItems) {
				all(sub);
			}
		}
		foreach (itm; dirs.getItems) {
			all(itm);
		}
		return r;
	}
	private void newItem(T)(FlagDir dir, T parent, bool[string] exAll) {
		auto sItm = new TreeItem(parent, SWT.NONE);
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
		auto ep = toLower(dir.path) in exAll;
		if (!ep || *ep) {
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
		if (!dirs || dirs.isDisposed) return null;
		return findImpl(dirs.getItem(0), dir);
	}
	private void select(FlagDir dir) {
		auto itm = find(dir);
		if (itm) {
			dirs.select = itm;
		}
	}
	void refreshD(Object sender, FlagDir[] dirs) {
		if (sender is this) return;
		refresh(null);
	}
public:
	this(Commons comm, Props prop, FlagTable flags, UndoManager undo) {
		_undo = undo;
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
		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout = new FillLayout;
		dirs = new Tree(_comp, SWT.SINGLE | SWT.BORDER);

		edit = new TreeEdit(dirs, &editEnd, &createEditor);

		dirs.addSelectionListener(new DirSelection);
		auto menu = new Menu(dirs.getShell, SWT.POP_UP);
		createMenuItem(menu, prop.msgs.menuUndo, prop.images.menuUndo, &this.undo);
		createMenuItem(menu, prop.msgs.menuRedo, prop.images.menuRedo, &this.redo);
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(prop, menu, this, true, true, true, true);
		dirs.setMenu(menu);

		auto ds = new DragSource(dirs, DND.DROP_MOVE);
		ds.setTransfer = [XMLBytesTransfer.getInstance];
		ds.addDragListener(new FlagDirDragListener);
		auto dt = new DropTarget(dirs, DND.DROP_MOVE);
		dt.setTransfer = [XMLBytesTransfer.getInstance];
		dt.addDropListener(new FlagsDropListener);

		_comm.replText.add(&refresh);
		_comm.refSortCondition.add(&refresh);
		_comm.refFlagDir.add(&refreshD);
		_comm.delFlagDir.add(&refreshD);
		dirs.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.replText.remove(&refresh);
				_comm.refSortCondition.remove(&refresh);
				_comm.refFlagDir.remove(&refreshD);
				_comm.delFlagDir.remove(&refreshD);
			}
		});
		return _comp;
	}

	/// 新規ディレクトリを生成する。
	/// ディレクトリ名は「新しいフォルダ(Propsで定義)」となり、
	/// すでに同名のディレクトリが存在する場合は"(2)"～をつける。
	void createDir() {
		auto cur = current;
		if (!cur) return;
		_comm.openCWXPath(cur.cwxPath);
		string name = cur.createNewDirName(prop.msgs.flagDirNew);
		storeInsert(cur, flags.selected, [cast(int) cur.subDirs.length], [], []);
		auto dir = new FlagDir(name);
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
		}
		flags.dir = dir;
	}

	FlagDir current() {
		if (dirs && !dirs.isDisposed) {
			auto sels = dirs.getSelection;
			if (sels.length) {
				return cast(FlagDir) sels[0].getData;
			}
		}
		return root;
	}

	override {
		void cut(SelectionEvent se) {
			if (!root) return;
			if (current !is root) {
				copy(se);
				del(se);
			}
		}
		void copy(SelectionEvent se) {
			if (!root) return;
			if (dirs.getSelection.length > 0) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(prop, cb, getXML(prop.msgs.flagDirRoot, current));
			}
		}
		void paste(SelectionEvent se) {
			if (!root) return;
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			auto c = CBtoXML(cb);
			if (c) {
				try {
					auto cur = current;
					string newPath;
					Flag[string] cFlags;
					Step[string] cSteps;
					auto tblSels = flags.selected;
					switch (cur.appendFromXML(c, LATEST_VERSION, true, true, cFlags, cSteps, newPath)) {
					case FlagDir.AppendXmlResult.DIR_SUCCESS:
						refresh(newPath);
						auto dir = root.findPath(newPath, false);
						storeInsert(dir.parent, tblSels, [dir.parent.indexOf(dir.name)], [], []);
						_comm.refFlagDir.call(this, [dir]);
						auto itm = find(current);
						if (itm) treeExpandedAll(itm);
						break;
					case FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS:
						string[] flagName;
						string[] stepName;
						foreach (f; cFlags) {
							flagName ~= f.name;
						}
						foreach (s; cSteps) {
							stepName ~= s.name;
						}
						storeInsert(cur, tblSels, [], flagName, stepName);
						flags.refresh;
						break;
					case FlagDir.AppendXmlResult.FLAG_STEP_ON_DIR:
					case FlagDir.AppendXmlResult.ON_DIR:
						assert (false);
					default:
					}
					_comm.refFlagAndStep.call(cFlags.values, cSteps.values);
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) {
			if (!root) return;
			auto cur = current;
			if (cur != root) {
				auto tblSels = flags.selected;
				int index = cur.parent.indexOf(cur.name);
				storeDelete(cur.parent, tblSels, [index:cur], [], []);
				Flag[] cFlags = cur.allFlags;
				Step[] cSteps = cur.allSteps;
				auto p = cur.parent;
				p.remove(cur);
				current = p;
				refreshDirs(p);
				_comm.delFlagAndStep.call(cFlags, cSteps);
				_comm.delFlagDir.call([cur]);
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
		if (dirs && !dirs.isDisposed) {
			treeExpandedAll(dirs);
		}
	}

	private bool openCWXPathImpl(FlagDir dir, string path) {
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "flag": {
			if (index >= dir.flags.length) return false;
			_comm.openFlagWin();
			forceFocus(flags.widget);
			current = dir;
			flags.select(dir.flags[index]);
			return true;
		} break;
		case "step": {
			if (index >= dir.steps.length) return false;
			_comm.openFlagWin();
			forceFocus(flags.widget);
			current = dir;
			flags.select(dir.steps[index]);
			return true;
		} break;
		case "dir": {
			if (index >= dir.subDirs.length) return false;
			_comm.openFlagWin();
			return openCWXPathImpl(dir.subDirs[index], cpbottom(path));
		} break;
		case "": {
			_comm.openFlagWin();
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
	void undo() {
		_undo.undo();
	}
	void redo() {
		_undo.redo();
	}
}

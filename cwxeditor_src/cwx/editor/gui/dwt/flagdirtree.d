
module cwx.editor.gui.dwt.flagdirtree;

import cwx.utils;
import cwx.flag;
import cwx.usecounter;
import cwx.path;
import cwx.menu;
import cwx.types;
import cwx.system;
import cwx.card;
import cwx.event;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.flagtable;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;

import std.conv;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

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
	void storeSwap(FlagDir par, int index1, int index2) {
		_undo ~= new UndoSwap(flags, _comm, cast(FlagDir) selectedItem.getData(), par, index1, index2);
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
			flags.setDir(current);
			_comm.refreshToolBar();
		}
	}

	FlagDir _moveDir = null;
	class FlagDirDragListener : DragSourceListener {
	public:
		override void dragStart(DragSourceEvent e) {
			e.doit = current != root && (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e) {
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
				_moveDir = current;

				// XML化して転送する。
				e.data = bytesFromXML(getXML(prop.msgs.flagDirRoot, _moveDir));
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				_moveDir.parent.remove(_moveDir);
				refresh();
				_comm.delFlagAndStep.call(_moveDir.allFlags, _moveDir.allSteps);
				_comm.refreshToolBar();
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
			if (cast(FlagDir) e.item.getData()) {
				auto data = bytesToXML(e.data);
				auto dir = cast(FlagDir) e.item.getData();
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
				@property
				string[] flagName() {
					string[] name;
					foreach (f; cFlags) {
						name ~= f.name;
					}
					return name;
				}
				@property
				string[] stepName() {
					string[] name;
					foreach (s; cSteps) {
						name ~= s.name;
					}
					return name;
				}
				auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
				auto ret = dir.appendFromXML(data, ver, false, true, cFlags, cSteps, newPath, rootId);
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
					if (cFlags.length > 0) dir.sortFlags();
					if (cSteps.length > 0) dir.sortSteps();
					flags.refresh();
					break;
				case FlagDir.AppendXmlResult.ON_DIR:
					e.detail = DND.DROP_NONE;
					refresh();
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
				_comm.refreshToolBar();
			} else {
				e.detail = DND.DROP_NONE;
			}
		}
	}

	void editEnd(TreeItem itm, Control c) {
		auto dir = cast(FlagDir) itm.getData();
		auto text = (cast(Text) c).getText();
		if (!text) text = "";
		string oldName = dir.name;
		if (oldName == text) return;
		if (dir.rename(text, uc)) {
			storeEditDir(dir, oldName);
			itm.setText(dir.name);
			_comm.refFlagDir.call(this, [dir]);
			_comm.refreshToolBar();
		}
	}

	Control createEditor(TreeItem itm) {
		return itm.getData() != root ? createTextEditor(_comm, prop, dirs, itm.getText()) : null;
	}

	private void refreshDirs() {
		if (!dirs || dirs.isDisposed()) return;
		dirs.setRedraw(false);
		scope (exit) dirs.setRedraw(true);
		auto exAll = expandAll();
		auto sel = current;
		dirs.removeAll();
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
			auto dir = cast(FlagDir) itm.getData();
			r[dir.path.toLower()] = itm.getItemCount() == 0 || itm.getExpanded();
			foreach (sub; itm.getItems()) {
				all(sub);
			}
		}
		foreach (itm; dirs.getItems()) {
			all(itm);
		}
		return r;
	}
	private void newItem(T)(FlagDir dir, T parent, bool[string] exAll) {
		auto sItm = new TreeItem(parent, SWT.NONE);
		sItm.setImage(prop.images.flagDir);
		static if (is(T : Tree)) {
			sItm.setText(prop.msgs.flagDirRoot);
		} else {
			sItm.setText(dir.name);
		}
		sItm.setData(dir);
		foreach (sub; dir.subDirs) {
			newItem(sub, sItm, exAll);
		}
		auto ep = toLower(dir.path) in exAll;
		if (!ep || *ep) {
			sItm.setExpanded(true);
		}
	}
	private void refreshDirs(FlagDir targ) {
		dirs.setRedraw(false);
		scope (exit) dirs.setRedraw(true);
		auto itm = find(targ);
		if (itm) {
			auto exAll = expandAll();
			auto sel = current;
			itm.removeAll();
			foreach (sub; targ.subDirs) {
				newItem(sub, itm, exAll);
			}
			if (sel) current = sel;
		}
		_comm.refreshToolBar();
	}
	private TreeItem findImpl(TreeItem parent, FlagDir dir) {
		if (parent.getData() is dir) return parent;
		foreach (itm; parent.getItems()) {
			auto r = findImpl(itm, dir);
			if (r) return r;
		}
		return null;
	}
	private TreeItem find(FlagDir dir) {
		if (!root) return null;
		if (!dirs || dirs.isDisposed()) return null;
		return findImpl(dirs.getItem(0), dir);
	}
	@property
	private void select(FlagDir dir) {
		auto itm = find(dir);
		if (itm) {
			dirs.select(itm);
			_comm.refreshToolBar();
		}
	}
	void refreshD(Object sender, FlagDir[] dirs) {
		if (sender is this) return;
		refresh(null);
	}
	@property
	TreeItem selectedItem() {
		auto sels = dirs.getSelection();
		return sels.length ? sels[0] : null;
	}
public:
	this (Commons comm, Props prop, FlagTable flags, UndoManager undo) {
		_undo = undo;
		_comm = comm;
		this.prop = prop;
		this.flags = flags;
	}
	private Composite _comp = null;
	@property
	Control widget() {return _comp;}

	void refresh() {
		refresh(null);
	}
	void refresh(string selPath) {
		if (!selPath) {
			selPath = current.path;
		}
		refreshDirs();
		select(selPath);
	}

	@property
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
	@property
	void useCounter(UseCounter uc) {
		this.uc = uc;
	}

	/// コントロールを生成する。
	/// Params:
	/// parent = 親コントロール。
	Control createControl(Composite parent) {
		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(new FillLayout);
		dirs = new Tree(_comp, SWT.SINGLE | SWT.BORDER);
		initTree(_comm, dirs, false);

		edit = new TreeEdit(_comm, dirs, &editEnd, &createEditor);

		dirs.addSelectionListener(new DirSelection);
		auto menu = new Menu(dirs.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.Undo, &this.undo, &_undo.canUndo);
		createMenuItem(_comm, menu, MenuID.Redo, &this.redo, &_undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
		new MenuItem(menu, SWT.SEPARATOR);

		void delegate() dlg = null;
		auto evt = createMenuItem(_comm, menu, MenuID.CreateVariableEventTree, dlg, () => current && (current.hasFlag || current.hasStep), SWT.CASCADE);
		auto mEvt = new Menu(parent.getShell(), SWT.DROP_DOWN);
		evt.setMenu(mEvt);
		createMenuItem(_comm, mEvt, MenuID.InitVariablesTree, &copyInitTree, () => current && (current.hasFlag || current.hasStep));
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagTrue, "T", "", false), prop.images.content(CType.SET_FLAG), () => copyFlagTree(true), () => current && current.hasFlag);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagFalse, "F", "", false), prop.images.content(CType.SET_FLAG), () => copyFlagTree(false), () => current && current.hasFlag);
		new MenuItem(mEvt, SWT.SEPARATOR);
		void ssValue(uint i) {
			string mnemonic = i < 10 ? .text(i) : "";
			createMenuItem2(_comm, mEvt, MenuProps.buildMenu(.tryFormat(prop.msgs.setStepValue, .tryFormat(prop.msgs.dlgTxtStep, i)), mnemonic, "", false), prop.images.content(CType.SET_STEP), () => copyStepTree(i), () => current && current.hasStep);
		}
		foreach (i; 0..prop.looks.stepMaxCount) {
			ssValue(i);
		}

		dirs.setMenu(menu);

		auto ds = new DragSource(dirs, DND.DROP_MOVE);
		ds.setTransfer([XMLBytesTransfer.getInstance()]);
		ds.addDragListener(new FlagDirDragListener);
		auto dt = new DropTarget(dirs, DND.DROP_MOVE);
		dt.setTransfer([XMLBytesTransfer.getInstance()]);
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
		_comm.openCWXPath(cur.cwxPath(true), true);
		string name = cur.createNewDirName(prop.msgs.flagDirNew, null);
		storeInsert(cur, flags.selected, [cast(int) cur.subDirs.length], [], []);
		auto dir = new FlagDir(name);
		cur.add(dir);
		refreshDirs(cur);
		current = dir;
		edit.startEdit();
		_comm.refreshToolBar();
	}

	@property
	private void current(FlagDir dir) {
		auto itm = find(dir);
		if (itm) {
			dirs.select(itm);
			dirs.showSelection();
		}
		flags.setDir(dir);
		_comm.refreshToolBar();
	}

	@property
	FlagDir current() {
		if (dirs && !dirs.isDisposed()) {
			auto sels = dirs.getSelection();
			if (sels.length) {
				return cast(FlagDir) sels[0].getData();
			}
		}
		return root;
	}

	private bool canUdImpl(int plus) {
		if (!dirs.isFocusControl()) return false;
		auto sel = selectedItem;
		if (!sel) return false;
		auto dir = cast(FlagDir) sel.getData();
		auto par = dir.parent;
		if (!par) return false;
		int index1 = par.indexOf(dir.name);
		assert (-1 != index1);
		int index2 = index1 + plus;
		if (index2 < 0 || par.subDirs.length <= index2) return false;
		return true;
	}
	private void udImpl(int plus) {
		if (!dirs.isFocusControl()) return;
		auto sel = selectedItem;
		if (!sel) return;
		auto dir = cast(FlagDir) sel.getData();
		auto par = dir.parent;
		if (!par) return;
		int index1 = par.indexOf(dir.name);
		assert (-1 != index1);
		int index2 = index1 + plus;
		if (index2 < 0 || par.subDirs.length <= index2) return;
		storeSwap(par, index1, index2);
		par.swapDir(index1, index2);
		auto parItm = sel.getParentItem();
		assert (parItm);
		auto dir1 = par.subDirs[index1], dir2 = par.subDirs[index2];
		auto itm1 = parItm.getItem(index1), itm2 = parItm.getItem(index2);
		itm1.setData(dir1);
		itm1.setText(dir1.name);
		itm2.setData(dir2);
		itm2.setText(dir2.name);
		refresh(dir2.path);
		_comm.refFlagAndStep.call(dir1.allFlags ~ dir2.allFlags, dir1.allSteps ~ dir2.allSteps);
		_comm.refreshToolBar();
	}
	void up() {
		udImpl(-1);
	}
	void down() {
		udImpl(1);
	}
	@property
	bool canUp() {
		return canUdImpl(-1);
	}
	@property
	bool canDown() {
		return canUdImpl(1);
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
			if (dirs.getSelection().length > 0) {
				XMLtoCB(prop, _comm.clipboard, getXML(prop.msgs.flagDirRoot, current));
				_comm.refreshToolBar();
			}
		}
		void paste(SelectionEvent se) {
			if (!root) return;
			auto c = CBtoXML(_comm.clipboard);
			if (c) {
				try {
					auto cur = current;
					string newPath;
					string rootId;
					Flag[string] cFlags;
					Step[string] cSteps;
					auto tblSels = flags.selected;
					auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
					switch (cur.appendFromXML(c, ver, true, true, cFlags, cSteps, newPath, rootId)) {
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
						flags.refresh();
						break;
					case FlagDir.AppendXmlResult.FLAG_STEP_ON_DIR:
					case FlagDir.AppendXmlResult.ON_DIR:
						assert (false);
					default:
					}
					_comm.refFlagAndStep.call(cFlags.values, cSteps.values);
					_comm.refreshToolBar();
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
				_comm.refreshToolBar();
			}
		}
		void clone(SelectionEvent se) {
			auto sel = dirs.getSelection();
			if (!sel.length) return;
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			auto par = current.parent;
			if (par) {
				current = par;
			}
			paste(se);
		}
		@property
		bool canDoTCPD() {
			return _comm.summary && dirs.isFocusControl();
		}
		@property
		bool canDoT() {
			return dirs.getSelection().length > 0 && current !is root;
		}
		@property
		bool canDoC() {
			return dirs.getSelection().length > 0;
		}
		@property
		bool canDoP() {
			return _comm.summary !is null && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() {
			return canDoT;
		}
		@property
		bool canDoClone() {
			return canDoC;
		}
	}
	void copyFlagTree(bool onOff) {
		if (!current) return;
		auto c = createSetFlagTree(current, onOff);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys)));
		_comm.refreshToolBar();
	}
	void copyStepTree(int value) {
		if (!current) return;
		auto c = createSetStepTree(current, value);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys)));
		_comm.refreshToolBar();
	}
	void copyInitTree() {
		if (!current) return;
		auto c = createInitVariablesTree(current);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys)));
		_comm.refreshToolBar();
	}

	/// Returns: ルートディレクトリを返す。
	@property
	FlagDir rootDir() {
		return root;
	}

	/// ディレクトリツリーを設定する。
	/// Params:
	/// root = ルートディレクトリ。
	@property
	void rootDir(FlagDir root) {
		this.root = root;
		refreshDirs();
		current = root;
		if (dirs && !dirs.isDisposed()) {
			treeExpandedAll(dirs);
		}
		_comm.refreshToolBar();
	}

	private bool openCWXPathImpl(FlagDir dir, string path, bool shellActivate) {
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "flag": {
			if (index >= dir.flags.length) return false;
			_comm.openFlagWin(shellActivate);
			forceFocus(flags.widget, shellActivate);
			current = dir;
			if (cphasattr(path, "opendialog")) {
				flags.edit(dir.flags[index]);
			} else {
				flags.select(dir.flags[index], false);
			}
			_comm.refreshToolBar();
			return true;
		} break;
		case "step": {
			if (index >= dir.steps.length) return false;
			_comm.openFlagWin(shellActivate);
			forceFocus(flags.widget, shellActivate);
			current = dir;
			if (cphasattr(path, "opendialog")) {
				flags.edit(dir.steps[index]);
			} else {
				flags.select(dir.steps[index], false);
			}
			_comm.refreshToolBar();
			return true;
		} break;
		case "dir": {
			if (index >= dir.subDirs.length) return false;
			_comm.openFlagWin(shellActivate);
			return openCWXPathImpl(dir.subDirs[index], cpbottom(path), shellActivate);
		} break;
		case "": {
			_comm.openFlagWin(shellActivate);
			forceFocus(dirs, shellActivate);
			current = dir;
			return true;
		}
		default: break;
		}
		return false;
	}
	bool openCWXPath(string path, bool shellActivate) {
		return openCWXPathImpl(root, path, shellActivate);
	}
	@property
	string[] openedCWXPath() {
		string[] r;
		auto cur = current;
		if (cur) {
			r ~= cur.cwxPath(true);
		}
		return r;
	}
	void undo() {
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() {
		_undo.redo();
		_comm.refreshToolBar();
	}
}

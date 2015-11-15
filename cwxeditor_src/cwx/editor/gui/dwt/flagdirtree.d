
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
	void storeInsert(FlagDir dir, string[] selectedF, string[] selectedS, int[] dirIndices, string[] flagName, string[] stepName) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(flags, _comm, dir, selectedF, selectedS, dirIndices, flagName, stepName);
	}
	void storeDelete(FlagDir dir, string[] selectedF, string[] selectedS, FlagDir[int] ds, cwx.flag.Flag[] fs, Step[] ss) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(flags, _comm, dir, selectedF, selectedS, ds, fs, ss);
	}
	void storeMove(string[] selectedF, string[] selectedS, FlagDir to, int[] dirIndices, string[] flagName, string[] stepName, FlagDir from, FlagDir[int] ds, cwx.flag.Flag[] fs, Step[] ss, cwx.flag.Flag[string] cFlags, Step[string] cSteps) { mixin(S_TRACE);
		_undo ~= new UndoMove(flags, _comm, selectedF, selectedS, to, dirIndices, flagName, stepName, from, ds, fs, ss, cFlags, cSteps);
	}
	void storeEditDir(FlagDir dir, string oldName) { mixin(S_TRACE);
		_undo ~= new UndoEditDir(flags, _comm, dir, oldName);
	}
	void storeSwap(FlagDir par, int index1, int index2) { mixin(S_TRACE);
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
		public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			flags.setDir(current);
			_comm.refreshToolBar();
		}
	}

	FlagDir _moveDir = null;
	class FlagDirDragListener : DragSourceListener {
	public:
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = current != root && (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				_moveDir = current;

				// XML化して転送する。
				e.data = bytesFromXML(getXML(prop.msgs.flagDirRoot, _moveDir));
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
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
		void move(DropTargetEvent e) { mixin(S_TRACE);
			e.detail = (e.item !is null && cast(TreeItem) e.item) ? DND.DROP_MOVE : DND.DROP_NONE;
		}
	public:
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}

		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (!isXMLBytes(e.data)) return;
			assert (cast(TreeItem) e.item);
			if (cast(FlagDir) e.item.getData()) { mixin(S_TRACE);
				auto data = bytesToXML(e.data);
				auto dir = cast(FlagDir) e.item.getData();
				string newPath;
				string rootId;
				cwx.flag.Flag[] fs = flags.dragFlags;
				Step[] ss = flags.dragSteps;
				cwx.flag.Flag[string] cFlags;
				Step[string] cSteps;
				string[] tblSelsF, tblSelsS;
				FlagDir moveDirParent = null;
				if (current is dir) { mixin(S_TRACE);
					tblSelsF = flags.selectionFlagNames();
					tblSelsS = flags.selectionStepNames();
				}
				ptrdiff_t dirIndex = -1;
				if (_moveDir) { mixin(S_TRACE);
					moveDirParent = _moveDir.parent;
					dirIndex = moveDirParent.indexOf(_moveDir.name);
				}
				@property
				string[] flagName() { mixin(S_TRACE);
					string[] name;
					foreach (f; cFlags) { mixin(S_TRACE);
						name ~= f.name;
					}
					return name;
				}
				@property
				string[] stepName() { mixin(S_TRACE);
					string[] name;
					foreach (s; cSteps) { mixin(S_TRACE);
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
					if (samePane) { mixin(S_TRACE);
						e.detail = DND.DROP_MOVE;
						assert (moveDirParent);
						storeMove(tblSelsF, tblSelsS, dir, [cast(int)dir.indexOf(dirName)], [], [], moveDirParent, [cast(int)dirIndex:_moveDir], [], [], cFlags, cSteps);
						_comm.delFlagDir.call(this.outer, [_moveDir]);
						_comm.refFlagDir.call(this.outer, [_moveDir]);
					} else { mixin(S_TRACE);
						e.detail = DND.DROP_COPY;
						storeInsert(dir, tblSelsF, tblSelsS, [cast(int)dir.indexOf(dirName)], [], []);
						_comm.refFlagDir.call(this.outer, [root.findPath(newPath, false)]);
					}
					if (prop.var.etc.sortFlagDirs) dir.sortSubDirs();
					refresh(newPath);
					break;
				case FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS:
					if (samePane) { mixin(S_TRACE);
						e.detail = DND.DROP_MOVE;
						FlagDir[int] ds;
						storeMove(tblSelsF, tblSelsS, dir, [], flagName, stepName, current, ds, fs, ss, cFlags, cSteps);
					} else { mixin(S_TRACE);
						e.detail = DND.DROP_COPY;
						storeInsert(dir, tblSelsF, tblSelsS, [], flagName, stepName);
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
						&& samePane) { mixin(S_TRACE);
					foreach (oldPath; cFlags.keys) { mixin(S_TRACE);
						uc.change(toFlagId(oldPath), toFlagId(cFlags[oldPath].path));
					}
					foreach (oldPath; cSteps.keys) { mixin(S_TRACE);
						uc.change(toStepId(oldPath), toStepId(cSteps[oldPath].path));
					}
					_comm.refFlagAndStep.call(cFlags.values, cSteps.values);
				}
				_comm.refreshToolBar();
			} else { mixin(S_TRACE);
				e.detail = DND.DROP_NONE;
			}
		}
	}

	void editEnd(TreeItem itm, Control c) { mixin(S_TRACE);
		auto dir = cast(FlagDir) itm.getData();
		auto text = (cast(Text) c).getText();
		if (!text) text = "";
		string oldName = dir.name;
		if (oldName == text) return;
		if (dir.rename(text, uc)) { mixin(S_TRACE);
			storeEditDir(dir, oldName);
			_comm.refFlagDir.call(this, [dir]);
			assert (dir.parent !is null);
			if (prop.var.etc.sortFlagDirs) dir.parent.sortSubDirs();
			refresh();
			_comm.refreshToolBar();
		}
	}

	Control createEditor(TreeItem itm) { mixin(S_TRACE);
		return itm.getData() != root ? createTextEditor(_comm, prop, dirs, itm.getText()) : null;
	}

	private void refreshDirs() { mixin(S_TRACE);
		if (!dirs || dirs.isDisposed()) return;
		dirs.setRedraw(false);
		scope (exit) dirs.setRedraw(true);
		auto exAll = expandAll();
		auto sel = current;
		dirs.removeAll();
		if (root) { mixin(S_TRACE);
			newItem(root, dirs, exAll);
			if (sel) { mixin(S_TRACE);
				current = sel;
			}
		}
	}
	private bool[string] expandAll() { mixin(S_TRACE);
		bool[string]  r;
		void all(TreeItem itm) { mixin(S_TRACE);
			auto dir = cast(FlagDir) itm.getData();
			r[dir.path.toLower()] = itm.getItemCount() == 0 || itm.getExpanded();
			foreach (sub; itm.getItems()) { mixin(S_TRACE);
				all(sub);
			}
		}
		foreach (itm; dirs.getItems()) { mixin(S_TRACE);
			all(itm);
		}
		return r;
	}
	private void newItem(T)(FlagDir dir, T parent, bool[string] exAll) { mixin(S_TRACE);
		auto sItm = new TreeItem(parent, SWT.NONE);
		sItm.setImage(prop.images.flagDir);
		static if (is(T : Tree)) {
			sItm.setText(prop.msgs.flagDirRoot);
		} else { mixin(S_TRACE);
			sItm.setText(dir.name);
		}
		sItm.setData(dir);
		foreach (sub; dir.subDirs) { mixin(S_TRACE);
			newItem(sub, sItm, exAll);
		}
		auto ep = toLower(dir.path) in exAll;
		if (!ep || *ep) { mixin(S_TRACE);
			sItm.setExpanded(true);
		}
	}
	private void refreshDirs(FlagDir targ) { mixin(S_TRACE);
		dirs.setRedraw(false);
		scope (exit) dirs.setRedraw(true);
		auto itm = find(targ);
		if (itm) { mixin(S_TRACE);
			auto exAll = expandAll();
			auto sel = current;
			itm.removeAll();
			foreach (sub; targ.subDirs) { mixin(S_TRACE);
				newItem(sub, itm, exAll);
			}
			if (sel) current = sel;
		}
		_comm.refreshToolBar();
	}
	private TreeItem findImpl(TreeItem parent, FlagDir dir) { mixin(S_TRACE);
		if (parent.getData() is dir) return parent;
		foreach (itm; parent.getItems()) { mixin(S_TRACE);
			auto r = findImpl(itm, dir);
			if (r) return r;
		}
		return null;
	}
	private TreeItem find(FlagDir dir) { mixin(S_TRACE);
		if (!root) return null;
		if (!dirs || dirs.isDisposed()) return null;
		return findImpl(dirs.getItem(0), dir);
	}
	@property
	private void select(FlagDir dir) { mixin(S_TRACE);
		auto itm = find(dir);
		if (itm) { mixin(S_TRACE);
			dirs.select(itm);
			_comm.refreshToolBar();
		}
	}
	void refreshD(Object sender, FlagDir[] dirs) { mixin(S_TRACE);
		if (sender is this) return;
		refresh(null);
	}
	@property
	TreeItem selectedItem() { mixin(S_TRACE);
		auto sels = dirs.getSelection();
		return sels.length ? sels[0] : null;
	}
public:
	this (Commons comm, Props prop, FlagTable flags, UndoManager undo) { mixin(S_TRACE);
		_undo = undo;
		_comm = comm;
		this.prop = prop;
		this.flags = flags;
	}
	private Composite _comp = null;
	@property
	Control widget() {return _comp;}

	void refresh() { mixin(S_TRACE);
		refresh(null);
	}
	void refresh(string selPath) { mixin(S_TRACE);
		if (!selPath) { mixin(S_TRACE);
			selPath = current.path;
		}
		refreshDirs();
		select(selPath);
	}

	@property
	void select(string path) { mixin(S_TRACE);
		auto dir = FlagDir.searchPath(root, path);
		if (!dir) { mixin(S_TRACE);
			current = root;
		} else { mixin(S_TRACE);
			current = dir;
		}
	}

	/// 使用回数カウンタを設定する。
	/// Params:
	/// uc = 使用回数カウンタ。
	@property
	void useCounter(UseCounter uc) { mixin(S_TRACE);
		this.uc = uc;
	}

	/// コントロールを生成する。
	/// Params:
	/// parent = 親コントロール。
	Control createControl(Composite parent, void delegate() gotFocus) { mixin(S_TRACE);
		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(new FillLayout);
		dirs = new Tree(_comp, SWT.SINGLE | SWT.BORDER);
		initTree(_comm, dirs, false);
		.listener(dirs, SWT.FocusIn, gotFocus);

		edit = new TreeEdit(_comm, dirs, &editEnd, &createEditor);

		dirs.addSelectionListener(new DirSelection);
		auto menu = new Menu(dirs.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.NewFlagDir, &createDir, () => current !is null);
		new MenuItem(menu, SWT.SEPARATOR);
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
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.REVERSE_FLAG), "R", "", false), prop.images.content(CType.REVERSE_FLAG), &copyFlagReverseTree, () => current && current.hasFlag);
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagTrue, "T", "", false), prop.images.content(CType.SET_FLAG), () => copyFlagTree(true), () => current && current.hasFlag);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagFalse, "F", "", false), prop.images.content(CType.SET_FLAG), () => copyFlagTree(false), () => current && current.hasFlag);
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.SET_STEP_UP), "U", "", false), prop.images.content(CType.SET_STEP_UP), &copyStepUpTree, () => current && current.hasStep);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.SET_STEP_DOWN), "D", "", false), prop.images.content(CType.SET_STEP_DOWN), &copyStepDownTree, () => current && current.hasStep);
		new MenuItem(mEvt, SWT.SEPARATOR);
		void ssValue(uint i) { mixin(S_TRACE);
			string mnemonic = i < 10 ? .text(i) : "";
			createMenuItem2(_comm, mEvt, MenuProps.buildMenu(.tryFormat(prop.msgs.setStepValue, .tryFormat(prop.msgs.dlgTxtStep, i)), mnemonic, "", false), prop.images.content(CType.SET_STEP), () => copyStepTree(i), () => current && current.hasStep);
		}
		foreach (i; 0..prop.looks.stepMaxCount) { mixin(S_TRACE);
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
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
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
	void createDir() { mixin(S_TRACE);
		auto cur = current;
		if (!cur) return;
		_comm.openCWXPath(cur.cwxPath(true), true);
		string name = cur.createNewDirName(prop.msgs.flagDirNew, null);
		storeInsert(cur, flags.selectionFlagNames, flags.selectionStepNames, [cast(int) cur.subDirs.length], [], []);
		auto dir = new FlagDir(name);
		cur.add(dir);
		if (prop.var.etc.sortFlagDirs) cur.sortSubDirs();
		refreshDirs(cur);
		current = dir;
		edit.startEdit();
		_comm.refreshToolBar();
	}

	@property
	private void current(FlagDir dir) { mixin(S_TRACE);
		auto itm = find(dir);
		if (itm) { mixin(S_TRACE);
			dirs.select(itm);
			dirs.showSelection();
		}
		flags.setDir(dir);
		_comm.refreshToolBar();
	}

	@property
	FlagDir current() { mixin(S_TRACE);
		if (dirs && !dirs.isDisposed()) { mixin(S_TRACE);
			auto sels = dirs.getSelection();
			if (sels.length) { mixin(S_TRACE);
				return cast(FlagDir) sels[0].getData();
			}
		}
		return root;
	}

	private bool canUdImpl(int plus) { mixin(S_TRACE);
		if (!dirs.isFocusControl()) return false;
		if (prop.var.etc.sortFlagDirs) return false;
		auto sel = selectedItem;
		if (!sel) return false;
		auto dir = cast(FlagDir) sel.getData();
		auto par = dir.parent;
		if (!par) return false;
		auto index1 = par.indexOf(dir.name);
		assert (-1 != index1);
		auto index2 = index1 + plus;
		if (index2 < 0 || par.subDirs.length <= index2) return false;
		return true;
	}
	private void udImpl(int plus) { mixin(S_TRACE);
		if (!dirs.isFocusControl()) return;
		if (prop.var.etc.sortFlagDirs) return;
		auto sel = selectedItem;
		if (!sel) return;
		auto dir = cast(FlagDir) sel.getData();
		auto par = dir.parent;
		if (!par) return;
		int index1 = cast(int)par.indexOf(dir.name);
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
	void up() { mixin(S_TRACE);
		udImpl(-1);
	}
	void down() { mixin(S_TRACE);
		udImpl(1);
	}
	@property
	bool canUp() { mixin(S_TRACE);
		return canUdImpl(-1);
	}
	@property
	bool canDown() { mixin(S_TRACE);
		return canUdImpl(1);
	}

	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			if (!root) return;
			if (current !is root) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			if (!root) return;
			if (dirs.getSelection().length > 0) { mixin(S_TRACE);
				XMLtoCB(prop, _comm.clipboard, getXML(prop.msgs.flagDirRoot, current));
				_comm.refreshToolBar();
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			if (!root) return;
			auto c = CBtoXML(_comm.clipboard);
			if (c) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto cur = current;
					string newPath;
					string rootId;
					cwx.flag.Flag[string] cFlags;
					Step[string] cSteps;
					auto tblSelsF = flags.selectionFlagNames;
					auto tblSelsS = flags.selectionStepNames;
					auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
					switch (cur.appendFromXML(c, ver, true, true, cFlags, cSteps, newPath, rootId)) {
					case FlagDir.AppendXmlResult.DIR_SUCCESS:
						refresh(newPath);
						auto dir = root.findPath(newPath, false);
						storeInsert(dir.parent, tblSelsF, tblSelsS, [cast(int)dir.parent.indexOf(dir.name)], [], []);
						_comm.refFlagDir.call(this, [dir]);
						if (prop.var.etc.sortFlagDirs) dir.parent.sortSubDirs();
						refresh();
						auto itm = find(current);
						if (itm) treeExpandedAll(itm);
						break;
					case FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS:
						string[] flagName;
						string[] stepName;
						foreach (f; cFlags) { mixin(S_TRACE);
							flagName ~= f.name;
						}
						foreach (s; cSteps) { mixin(S_TRACE);
							stepName ~= s.name;
						}
						storeInsert(cur, tblSelsF, tblSelsS, [], flagName, stepName);
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
					printStackTrace();
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			if (!root) return;
			auto cur = current;
			if (cur != root) { mixin(S_TRACE);
				auto tblSelsF = flags.selectionFlagNames;
				auto tblSelsS = flags.selectionStepNames;
				int index = cast(int)cur.parent.indexOf(cur.name);
				storeDelete(cur.parent, tblSelsF, tblSelsS, [index:cur], [], []);
				cwx.flag.Flag[] cFlags = cur.allFlags;
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
		void clone(SelectionEvent se) { mixin(S_TRACE);
			auto sel = dirs.getSelection();
			if (!sel.length) return;
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			auto par = current.parent;
			if (par) { mixin(S_TRACE);
				current = par;
			}
			paste(se);
		}
		@property
		bool canDoTCPD() { mixin(S_TRACE);
			return _comm.summary !is null;
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			return dirs.getSelection().length > 0 && current !is root;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return dirs.getSelection().length > 0;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return _comm.summary !is null && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return canDoT;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return canDoC;
		}
	}
	void copyFlagTree(bool onOff) { mixin(S_TRACE);
		if (!current) return;
		auto c = createSetFlagTree(current, onOff);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyStepTree(int value) { mixin(S_TRACE);
		if (!current) return;
		auto c = createSetStepTree(current, value);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyInitTree() { mixin(S_TRACE);
		if (!current) return;
		auto c = createInitVariablesTree(current);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyFlagReverseTree() { mixin(S_TRACE);
		if (!current) return;
		auto c = createReverseFlagTree(current);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyStepUpTree() { mixin(S_TRACE);
		if (!current) return;
		auto c = createSetStepUpTree(current);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyStepDownTree() { mixin(S_TRACE);
		if (!current) return;
		auto c = createSetStepDownTree(current);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}

	/// Returns: ルートディレクトリを返す。
	@property
	FlagDir rootDir() { mixin(S_TRACE);
		return root;
	}

	/// ディレクトリツリーを設定する。
	/// Params:
	/// root = ルートディレクトリ。
	@property
	void rootDir(FlagDir root) { mixin(S_TRACE);
		this.root = root;
		refreshDirs();
		current = root;
		if (dirs && !dirs.isDisposed()) { mixin(S_TRACE);
			treeExpandedAll(dirs);
		}
		_comm.refreshToolBar();
	}

	private bool openCWXPathImpl(FlagDir dir, string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "flag": { mixin(S_TRACE);
			if (index >= dir.flags.length) return false;
			_comm.openFlagWin(shellActivate);
			if (!cphasattr(path, "nofocus")) forceFocus(flags.widget, shellActivate);
			current = dir;
			if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
				flags.edit(dir.flags[index]);
			} else { mixin(S_TRACE);
				flags.select(dir.flags[index], false);
			}
			_comm.refreshToolBar();
			return true;
		} break;
		case "step": { mixin(S_TRACE);
			if (index >= dir.steps.length) return false;
			_comm.openFlagWin(shellActivate);
			if (!cphasattr(path, "nofocus")) forceFocus(flags.widget, shellActivate);
			current = dir;
			if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
				flags.edit(dir.steps[index]);
			} else { mixin(S_TRACE);
				flags.select(dir.steps[index], false);
			}
			_comm.refreshToolBar();
			return true;
		} break;
		case "dir": { mixin(S_TRACE);
			if (index >= dir.subDirs.length) return false;
			_comm.openFlagWin(shellActivate);
			return openCWXPathImpl(dir.subDirs[index], cpbottom(path), shellActivate);
		} break;
		case "": { mixin(S_TRACE);
			_comm.openFlagWin(shellActivate);
			forceFocus(dirs, shellActivate);
			current = dir;
			return true;
		}
		default: break;
		}
		return false;
	}
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return openCWXPathImpl(root, path, shellActivate);
	}
	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		auto cur = current;
		if (cur) { mixin(S_TRACE);
			r ~= cur.cwxPath(true);
		}
		return r;
	}
	void undo() { mixin(S_TRACE);
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		_undo.redo();
		_comm.refreshToolBar();
	}
}

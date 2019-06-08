
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
import cwx.structs;
import cwx.warning;

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
	void storeInsert(FlagDir dir, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] selectedV, ptrdiff_t[] dirIndices, ptrdiff_t[] flagIndices, ptrdiff_t[] stepIndices, ptrdiff_t[] variantIndices) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(flags, _comm, uc, dir, selectedF, selectedS, selectedV, dirIndices, flagIndices, stepIndices, variantIndices);
	}
	void storeDelete(FlagDir dir, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] selectedV, FlagDir[ptrdiff_t] ds, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss, cwx.flag.Variant[ptrdiff_t] vs) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(flags, _comm, uc, dir, selectedF, selectedS, selectedV, ds, fs, ss, vs);
	}
	void storeMove(ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] selectedV, FlagDir to, ptrdiff_t[] dirIndices, ptrdiff_t[] flagIndices, ptrdiff_t[] stepIndices, ptrdiff_t[] variantIndices, FlagDir from, FlagDir[ptrdiff_t] ds, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss, cwx.flag.Variant[ptrdiff_t] vs) { mixin(S_TRACE);
		_undo ~= new UndoMove(flags, _comm, uc, selectedF, selectedS, selectedV, to, dirIndices, flagIndices, stepIndices, variantIndices, from, ds, fs, ss, vs);
	}
	void storeEditDir(FlagDir dir, string oldName) { mixin(S_TRACE);
		_undo ~= new UndoEditDir(flags, _comm, uc, dir, oldName);
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
			_moveDir = null;
		}
	}
	void dropMove() { mixin(S_TRACE);
		_moveDir.parent.remove(_moveDir);
		refresh();
		_comm.delFlagAndStep.call(_moveDir.allFlags, _moveDir.allSteps, _moveDir.allVariants);
		_comm.refreshToolBar();
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
			cancelEdit();
			if (cast(FlagDir) e.item.getData()) { mixin(S_TRACE);
				auto data = bytesToXML(e.data);
				auto dir = cast(FlagDir)e.item.getData();
				assert (dir !is null, .text(e.item.getData()));
				string newPath;
				string rootId;
				cwx.flag.Flag[ptrdiff_t] fs = flags.dragFlags;
				Step[ptrdiff_t] ss = flags.dragSteps;
				cwx.flag.Variant[ptrdiff_t] vs = flags.dragVariants;
				cwx.flag.Flag[string] cFlags;
				Step[string] cSteps;
				cwx.flag.Variant[string] cVariants;
				ptrdiff_t[] tblSelsF, tblSelsS, tblSelsV;
				FlagDir moveDirParent = null;
				ptrdiff_t dirIndex = -1;
				if (_moveDir) { mixin(S_TRACE);
					moveDirParent = _moveDir.parent;
					dirIndex = moveDirParent.indexOf(_moveDir);
					if (_moveDir.parent is dir) return;
				}
				if (current is dir) { mixin(S_TRACE);
					tblSelsF = flags.selectionFlagIndices();
					tblSelsS = flags.selectionStepIndices();
					tblSelsV = flags.selectionVariantIndices();
				}

				@property
				ptrdiff_t[] flagIndices() { mixin(S_TRACE);
					ptrdiff_t[] r;
					foreach (f; cFlags) { mixin(S_TRACE);
						r ~= f.parent.indexOf(f);
					}
					return r;
				}
				@property
				ptrdiff_t[] stepIndices() { mixin(S_TRACE);
					ptrdiff_t[] r;
					foreach (s; cSteps) { mixin(S_TRACE);
						r ~= s.parent.indexOf(s);
					}
					return r;
				}
				@property
				ptrdiff_t[] variantIndices() { mixin(S_TRACE);
					ptrdiff_t[] r;
					foreach (v; cVariants) { mixin(S_TRACE);
						r ~= v.parent.indexOf(v);
					}
					return r;
				}
				auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
				auto ret = dir.appendFromXML(data, ver, false, true, false, cFlags, cSteps, cVariants, newPath, rootId);
				bool samePane = dir.root.id == rootId;
				final switch (ret) {
				case FlagDir.AppendXmlResult.DIR_SUCCESS:
					auto newDir = root.findPath(newPath, false);
					if (samePane) { mixin(S_TRACE);
						e.detail = DND.DROP_MOVE;
						assert (moveDirParent);
						dropMove();
						storeMove(tblSelsF, tblSelsS, tblSelsV, dir, [dir.indexOf(newDir)], [], [], [], moveDirParent, [dirIndex:_moveDir], null, null, null);
						_comm.delFlagDir.call(this.outer, [_moveDir]);
						_comm.refFlagDir.call(this.outer, [_moveDir]);
					} else { mixin(S_TRACE);
						e.detail = DND.DROP_COPY;
						storeInsert(dir, tblSelsF, tblSelsS, tblSelsV, [dir.indexOf(newDir)], [], [], []);
						_comm.refFlagDir.call(this.outer, [newDir]);
					}
					refresh(newPath);
					break;
				case FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS:
					if (samePane) { mixin(S_TRACE);
						e.detail = DND.DROP_MOVE;
						storeMove(tblSelsF, tblSelsS, tblSelsV, dir, [], flagIndices, stepIndices, variantIndices, current, null, fs, ss, vs);
					} else { mixin(S_TRACE);
						e.detail = DND.DROP_COPY;
						storeInsert(dir, tblSelsF, tblSelsS, tblSelsV, [], flagIndices, stepIndices, variantIndices);
					}
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
					foreach (oldPath; cFlags.byKey()) { mixin(S_TRACE);
						assert (cFlags[oldPath].parent !is null);
						uc.change(toFlagId(oldPath), toFlagId(cFlags[oldPath].path));
					}
					foreach (oldPath; cSteps.byKey()) { mixin(S_TRACE);
						assert (cSteps[oldPath].parent !is null);
						uc.change(toStepId(oldPath), toStepId(cSteps[oldPath].path));
					}
					foreach (oldPath; cVariants.byKey()) { mixin(S_TRACE);
						assert (cVariants[oldPath].parent !is null);
						uc.change(toVariantId(oldPath), toVariantId(cVariants[oldPath].path));
					}
					_comm.refFlagAndStep.call(cFlags.values, cSteps.values, cVariants.values);
					_comm.refUseCount.call();
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
			auto dir = cast(FlagDir)itm.getData();
			r[dir.path] = itm.getItemCount() == 0 || itm.getExpanded();
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
		.sortedWithName(dir.subDirs, prop.var.etc.logicalSort, (FlagDir sub) { newItem(sub, sItm, exAll); });
		auto ep = dir.path in exAll;
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
			.sortedWithName(targ.subDirs, prop.var.etc.logicalSort, (FlagDir sub) { newItem(sub, itm, exAll); });
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
	Control widget() { return _comp; }

	void refresh() { mixin(S_TRACE);
		refresh(null);
	}
	void refresh(string selPath) { mixin(S_TRACE);
		enterEdit();
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
		.treeWarning(_comm.prop, dirs, (itm) { mixin(S_TRACE);
			auto flagDir = cast(FlagDir)itm.getData();
			if (!flagDir) return new string[0];
			return .warnings(_comm.prop.parent, _comm.skin, _comm.summary, flagDir, _comm.prop.var.etc.targetVersion);
		});

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
		auto evt = createMenuItem(_comm, menu, MenuID.CreateVariableEventTree, dlg, () => current && (current.hasFlag || current.hasStep || current.hasVariant), SWT.CASCADE);
		auto mEvt = new Menu(parent.getShell(), SWT.DROP_DOWN);
		evt.setMenu(mEvt);
		createMenuItem(_comm, mEvt, MenuID.InitVariablesTree, &copyInitTree, () => current && (current.hasFlag || current.hasStep || current.hasVariant));
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.ReverseFlag), "R", "", false), prop.images.content(CType.ReverseFlag), &copyFlagReverseTree, () => current && current.hasFlag);
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagTrue, "T", "", false), prop.images.content(CType.SetFlag), () => copyFlagTree(true), () => current && current.hasFlag);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagFalse, "F", "", false), prop.images.content(CType.SetFlag), () => copyFlagTree(false), () => current && current.hasFlag);
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.SetStepUp), "U", "", false), prop.images.content(CType.SetStepUp), &copyStepUpTree, () => current && current.hasStep);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.SetStepDown), "D", "", false), prop.images.content(CType.SetStepDown), &copyStepDownTree, () => current && current.hasStep);
		new MenuItem(mEvt, SWT.SEPARATOR);
		void ssValue(uint i) { mixin(S_TRACE);
			string mnemonic = i < 10 ? .text(i) : "";
			createMenuItem2(_comm, mEvt, MenuProps.buildMenu(.tryFormat(prop.msgs.setStepValue, .parseDollarParams(prop.var.etc.stepValueName, ['N':.to!string(i)])), mnemonic, "", false), prop.images.content(CType.SetStep), () => copyStepTree(i), () => current && current.hasStep);
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
		enterEdit();
		_comm.openCWXPath(cur.cwxPath(true), true);
		string name = cur.createNewDirName(prop.msgs.flagDirNew, null);
		storeInsert(cur, flags.selectionFlagIndices, flags.selectionStepIndices, flags.selectionVariantIndices, [cast(ptrdiff_t)cur.subDirs.length], [], [], []);
		auto dir = new FlagDir(name);
		cur.add(dir);
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
					assert (cur !is null);
					string newPath;
					string rootId;
					cwx.flag.Flag[string] cFlags;
					Step[string] cSteps;
					cwx.flag.Variant[string] cVariants;
					auto tblSelsF = flags.selectionFlagIndices;
					auto tblSelsS = flags.selectionStepIndices;
					auto tblSelsV = flags.selectionVariantIndices;
					auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
					switch (cur.appendFromXML(c, ver, true, true, false, cFlags, cSteps, cVariants, newPath, rootId)) {
					case FlagDir.AppendXmlResult.DIR_SUCCESS:
						refresh(newPath);
						assert (root !is null);
						auto dir = root.findPath(newPath, false);
						assert (dir !is null);
						storeInsert(dir.parent, tblSelsF, tblSelsS, tblSelsV, [dir.parent.indexOf(dir)], [], [], []);
						_comm.refFlagDir.call(this, [dir]);
						refresh();
						auto itm = find(current);
						if (itm) treeExpandedAll(itm);
						break;
					case FlagDir.AppendXmlResult.FLAG_STEP_SUCCESS:
						ptrdiff_t[] flagIndices;
						ptrdiff_t[] stepIndices;
						ptrdiff_t[] variantIndices;
						foreach (f; cFlags) { mixin(S_TRACE);
							assert (f.parent !is null);
							flagIndices ~= f.parent.indexOf(f);
						}
						foreach (s; cSteps) { mixin(S_TRACE);
							assert (s.parent !is null);
							stepIndices ~= s.parent.indexOf(s);
						}
						foreach (v; cVariants) { mixin(S_TRACE);
							assert (v.parent !is null);
							variantIndices ~= v.parent.indexOf(v);
						}
						storeInsert(cur, tblSelsF, tblSelsS, tblSelsV, [], flagIndices, stepIndices, variantIndices);
						flags.refresh();
						break;
					case FlagDir.AppendXmlResult.FLAG_STEP_ON_DIR:
					case FlagDir.AppendXmlResult.ON_DIR:
						assert (false);
					default:
					}
					_comm.refFlagAndStep.call(cFlags.values, cSteps.values, cVariants.values);
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
				auto tblSelsF = flags.selectionFlagIndices;
				auto tblSelsS = flags.selectionStepIndices;
				auto tblSelsV = flags.selectionVariantIndices;
				auto index = cur.parent.indexOf(cur);
				storeDelete(cur.parent, tblSelsF, tblSelsS, tblSelsV, [index:cur], null, null, null);
				cwx.flag.Flag[] cFlags = cur.allFlags;
				Step[] cSteps = cur.allSteps;
				cwx.flag.Variant[] cVariants = cur.allVariants;
				auto p = cur.parent;
				p.remove(cur);
				current = p;
				refreshDirs(p);
				_comm.delFlagAndStep.call(cFlags, cSteps, cVariants);
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
				flags.select(dir.flags[index], cphasattr(path, "only"));
			}
			_comm.refreshToolBar();
			return true;
		}
		case "step": { mixin(S_TRACE);
			if (index >= dir.steps.length) return false;
			_comm.openFlagWin(shellActivate);
			if (!cphasattr(path, "nofocus")) forceFocus(flags.widget, shellActivate);
			current = dir;
			if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
				flags.edit(dir.steps[index]);
			} else { mixin(S_TRACE);
				flags.select(dir.steps[index], cphasattr(path, "only"));
			}
			_comm.refreshToolBar();
			return true;
		}
		case "variant": { mixin(S_TRACE);
			if (index >= dir.variants.length) return false;
			_comm.openFlagWin(shellActivate);
			if (!cphasattr(path, "nofocus")) forceFocus(flags.widget, shellActivate);
			current = dir;
			if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
				flags.edit(dir.variants[index]);
			} else { mixin(S_TRACE);
				flags.select(dir.variants[index], cphasattr(path, "only"));
			}
			_comm.refreshToolBar();
			return true;
		}
		case "dir": { mixin(S_TRACE);
			if (index >= dir.subDirs.length) return false;
			_comm.openFlagWin(shellActivate);
			return openCWXPathImpl(dir.subDirs[index], cpbottom(path), shellActivate);
		}
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
		cancelEdit();
		if (flags) flags.cancelEdit();
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		cancelEdit();
		if (flags) flags.cancelEdit();
		_undo.redo();
		_comm.refreshToolBar();
	}

	void cancelEdit() { mixin(S_TRACE);
		if (edit) edit.cancel();
	}
	void enterEdit() { mixin(S_TRACE);
		if (edit) edit.enter();
	}
}

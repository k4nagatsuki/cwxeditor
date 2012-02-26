
module cwx.editor.gui.dwt.directorywindow;

import cwx.summary;
import cwx.usecounter;
import cwx.utils;
import cwx.skin;
import cwx.sjis;
import cwx.cab;
import cwx.structs;
import cwx.msgs;
import cwx.menu;

import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.dmenu;

import core.thread;

import std.array;
import std.conv;
import std.datetime;
import std.file;
import std.path;
import std.string;
import std.process;
import std.utf;
debug import std.stdio;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.SashForm;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.dnd.FileTransfer;
import org.eclipse.swt.dnd.TextTransfer;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.program.Program;
import java.lang.all;

version (Windows) {
	import std.c.windows.windows;
	private extern (Windows) {
		const DWORD WAIT_ABANDONED = 0x80;
		const DWORD WAIT_TIMEOUT = 0x102;
		const DWORD WAIT_FAILED = 0xffffffff;
		HANDLE FindFirstChangeNotificationW(LPCWSTR, BOOL, DWORD);
		BOOL FindNextChangeNotification(HANDLE);
		BOOL FindCloseChangeNotification(HANDLE);
	}
} else version (linux) {
	import std.c.linux.linux;
	private extern (C) {
		uintptr_t sleep(uintptr_t);
		intptr_t inotify_init();
		intptr_t inotify_add_watch(intptr_t, char*, uintptr_t);
		const IN_NONBLOCK = 0x4000;
		const IN_MODIFY = 0x0002;
		const IN_ATTRIB = 0x0004;
		const IN_MOVED_FROM = 0x0040;
		const IN_MOVED_TO = 0x0080;
		const IN_CREATE = 0x0100;
		const IN_DELETE = 0x0200;
		const IN_DELETE_SELF = 0x0400;
		struct inotify_event {
			intptr_t wd;
			uintptr_t mask;
			uintptr_t cookie;
			uintptr_t len;
			char* name;
		};
	}
} else {
	import std.c.unix.unix;
}

private struct FC {
	string path;
	SysTime time;
	const
	bool opEquals(ref const(FC) fc) {
		return path == fc.path && time == fc.time;
	}
	const
	int opCmp(ref const(FC) fc) {
		if (time < fc.time) return -1;
		if (time > fc.time) return 1;
		return 0;
	}
	const
	string toString() {
		return time.toISOExtString() ~ "\t" ~ path;
	}
}

class DirectoryWindow : TopLevelPanel, TCPD {
private:
	class FileNameObj {
		private this () {
			this.relPath = toRelPath(this.array);
			this.ext = cwx.utils.getExt(this.basename);
			this.pathId = toPathId(this.relPath);
			this.dir = isDir(this.array) != 0;
			if (this.dir) {
				this.material = false;
			} else {
				auto skin = _comm.skin;
				this.material = skin.isMaterial(this.basename, false);
			}
			this.size = getSize(this.array);
		}
		this (string fullPath) {
			this.array = fullPath;
			this.basename = baseName(this.array);
			this ();
		}
		this (string parent, string basename) {
			this.array = std.path.buildPath(parent, basename);
			this.basename = basename;
			this ();
		}
		string array;
		string basename;
		string relPath;
		string ext;
		PathId pathId;
		bool dir;
		bool material;
		ulong size;
	}
	int comp(string a, string b) {
		if (_prop.var.etc.logicalSort) {
			return fnncmp(a, b);
		} else {
			return fncmp(a, b);
		}
	}

	bool compDirName(string a, string b) {
		return comp(a, b) < 0;
	}
	bool compFullPath(string a, string b) {
		return compFNameS(baseName(a), baseName(b), isDir(a) != 0, isDir(b) != 0);
	}
	bool compFNameS(string a, string b, bool ad, bool bd) {
		if (ad && bd) return comp(a, b) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		return comp(a, b) < 0;
	}
	bool compFName(in FileNameObj a, in FileNameObj b) {
		return compFNameS(a.basename, b.basename, a.dir, b.dir);
	}
	bool revCompFName(in FileNameObj a, in FileNameObj b) {
		auto ad = a.dir;
		auto bd = b.dir;
		if (ad && bd) return comp(a.basename, b.basename) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		return comp(a.basename, b.basename) > 0;
	}
	bool compFExt(in FileNameObj a, in FileNameObj b) {
		auto ad = a.dir;
		auto bd = b.dir;
		if (ad && bd) return comp(a.basename, b.basename) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int r = comp(a.ext, b.ext);
		return r != 0 ? r < 0 : comp(a.basename, b.basename) < 0;
	}
	bool revCompFExt(in FileNameObj a, in FileNameObj b) {
		auto ad = a.dir;
		auto bd = b.dir;
		if (ad && bd) return comp(a.basename, b.basename) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int r = comp(a.ext, b.ext);
		return r != 0 ? r > 0 : comp(a.basename, b.basename) < 0;
	}
	bool compFCount(in FileNameObj a, in FileNameObj b) {
		auto ad = !a.material;
		auto bd = !b.material;
		if (ad && bd) return compFExt(a, b);
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int ac = _summ.useCounter.path.get(a.pathId);
		int bc = _summ.useCounter.path.get(b.pathId);
		int r = ac - bc;
		return r != 0 ? r < 0 : compFName(a, b);
	}
	bool revCompFCount(in FileNameObj a, in FileNameObj b) {
		auto ad = !a.material;
		auto bd = !b.material;
		if (ad && bd) return compFExt(a, b);
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int ac = _summ.useCounter.path.get(a.pathId);
		int bc = _summ.useCounter.path.get(b.pathId);
		int r = ac - bc;
		return r != 0 ? r > 0 : compFName(a, b);
	}
	@property
	FC[] allPaths() {
		FC[] fcs;
		if (_summ) {
			try {
				void list(string path) {
					FC fc;
					fc.path = path;
					if (.isDir(path)) {
						fc.time = SysTime.init;
						fcs ~= fc;
						foreach (c; clistdir(path)) {
							list(std.path.buildPath(path, c));
						}
					} else {
						fc.time = timeLastModified(path);
						fcs ~= fc;
					}
				}
				list(_summ.scenarioPath);
			} catch (Exception e) {
				debugln(e);
			}
		}
		return fcs.sort;
	}
	FC[] _checkPaths;
	void refCheckPaths() {
		if (_summ.useTemp) {
	 		_checkPaths = allPaths;
		}
	}

	bool isDef(string p, bool isDir) {
		return _summ.isSystemFile(p, isDir) || isIgnore(p);
	}

	bool isIgnore(string p) {
		return containsPath(_prop.var.etc.ignorePaths, baseName(p));
	}

	void refreshDirs(string sel) {
		if (!_win || _win.isDisposed()) return;
		try {
			scope (exit) refreshStatusLine();
			if (!_summ) {
				_dirs.removeAll();
				return;
			}
			bool[string] expands;
			void exps(TreeItem itm) {
				if (itm.getExpanded()) {
					expands[(cast(FileNameObj) itm.getData()).array] = true;
				}
				foreach (sub; itm.getItems()) {
					exps(sub);
				}
			}
			foreach (itm; _dirs.getItems()) {
				exps(itm);
			}
			_dirs.setRedraw(false);
			scope (exit) _dirs.setRedraw(true);
			int hs = _dirs.getHorizontalBar().getSelection();
			auto topItm = _dirs.getTopItem();
			string top = null;
			if (topItm) {
				top = (cast(FileNameObj) topItm.getData()).array;
				if (!.exists(top)) top = null;
			}
			TreeItem nTopItm = null;
			_dirs.removeAll();
			if (!addp(_dirs, _summ.scenarioPath, sel ? nabs(sel) : null, top, nTopItm)) {
				_dirs.setSelection(_dirs.getItems()[0]);
			}
			if (nTopItm) _dirs.setTopItem(nTopItm);
			void expst(TreeItem itm) {
				if ((cast(FileNameObj) itm.getData()).array in expands) {
					itm.setExpanded(true);
				}
				foreach (sub; itm.getItems()) {
					expst(sub);
				}
			}
			foreach (itm; _dirs.getItems()) {
				expst(itm);
			}
			_dirs.getHorizontalBar().setSelection(hs);
			_dirs.showSelection();
		} catch (Exception e) {
			debugln(e);
		}
	}
	void refreshFiles(string[] sels) {
		if (!_win || _win.isDisposed()) return;
		try {
			scope (exit) refreshStatusLine();
			if (!_summ) {
				_files.removeAll();
				return;
			}
			_files.setRedraw(false);
			scope (exit) _files.setRedraw(true);
			scope selset = new HashSet!(string);
			if (sels) {
				foreach (path; sels) {
					if (.exists(path)) {
						selset.add(nabs(path));
					}
				}
			}
			auto selDirs = _dirs.getSelection();
			if (selDirs.length > 0) {
				_files.deselectAll();
				_files.removeAll(); // 不要分だけremoveしようとすると Widget is disposed
				auto path = (cast(FileNameObj) selDirs[0].getData()).array;
				FileNameObj[] list;
				foreach (f; clistdir(path)) {
					list ~= new FileNameObj(path, f);
				}
				if (_files.getSortColumn() is _sortName.column) {
					if (_files.getSortDirection() == SWT.UP) {
						list = .sortDlg!(FileNameObj, typeof(&compFName))(list, &compFName);
					} else {
						assert (_files.getSortDirection() == SWT.DOWN);
						list = .sortDlg!(FileNameObj, typeof(&revCompFName))(list, &revCompFName);
					}
				} else if (_files.getSortColumn() is _sortExt.column) {
					if (_files.getSortDirection() == SWT.UP) {
						list = .sortDlg!(FileNameObj, typeof(&compFExt))(list, &compFExt);
					} else {
						assert (_files.getSortDirection() == SWT.DOWN);
						list = .sortDlg!(FileNameObj, typeof(&revCompFExt))(list, &revCompFExt);
					}
				} else {
					assert (_files.getSortColumn() is _sortCount.column);
					if (_files.getSortDirection() == SWT.UP) {
						list = .sortDlg!(FileNameObj, typeof(&compFCount))(list, &compFCount);
					} else {
						assert (_files.getSortDirection() == SWT.DOWN);
						list = .sortDlg!(FileNameObj, typeof(&revCompFCount))(list, &revCompFCount);
					}
				}
				int count = 0;
				int oldC = _files.getItemCount();
				bool sp = cast(bool) cfnmatch(nabs(path), nabs(_summ.scenarioPath));
				Skin skin = _comm.skin;
				foreach (p; list) {
					if (sp) {
						if (isDef(p.array, p.dir)) continue;
					} else {
						if (isIgnore(p.array)) continue;
					}
					TableItem itm;
					if (count < oldC) {
						itm = _files.getItem(count);
					} else {
						itm = new TableItem(_files, SWT.NONE);
					}
					auto img = fimage(skin, p.array, p.dir);
					itm.setImage(0, img);
					if (p.dir) {
						itm.setText(0, p.basename);
						itm.setText(1, "");
						itm.setText(2, "");
					} else if (p.material) {
						itm.setText(0, stripExtension(p.basename));
						itm.setText(1, p.ext);
						itm.setText(2, to!(string)(_summ.useCounter.path.get(p.pathId)));
					} else {
						itm.setText(0, stripExtension(p.basename));
						itm.setText(1, p.ext);
						itm.setText(2, "");
					}
					p.array = nabs(p.array);
					itm.setData(p);
					if (selset.size > 0) {
						if (selset.contains(p.array)) {
							_files.select(count);
						}
					}
					count++;
				}
				if (count > 0 && !sels) {
					_files.setTopIndex(0);
				}
				_files.showSelection();
			} else {
				_files.removeAll();
			}
		} catch (Exception e) {
			debugln(e);
		}
	}
	bool addp(T)(T parItm, string path, string sel, string top, ref TreeItem topItm) {
		auto itm = new TreeItem(parItm, SWT.NONE);
		auto full = nabs(path);
		if (0 == filenameCharCmp('A', 'a') ? _cuts.contains(cwx.utils.toLower(full)) : _cuts.contains(full)) {
			itm.setImage(_sImgFolder);
		} else {
			itm.setImage(_prop.images.folder);
		}
		string abs = nabs(_summ.scenarioPath);
		bool sp = cast(bool) cfnmatch(full, abs);
		if (sp) {
			itm.setText("Scenario");
		} else {
			itm.setText(baseName(path));
		}
		itm.setData(new FileNameObj(full));
		string[] subs;
		foreach (p; clistdir(path)) {
			p = std.path.buildPath(path, p);
			if (isDir(p)) subs ~= p;
		}
		subs = .sortDlg!(string)(subs, &compDirName);
		bool s = false;
		foreach (p; subs) {
			if (sp) {
				if (isDef(p, cast(bool) isDir(p))) continue;
			} else {
				if (isIgnore(p)) continue;
			}
			s |= addp(itm, p, sel, top, topItm);
		}
		if (sel) {
			auto absp = nabs(path);
			if (cfnmatch(sel, absp)) {
				itm.getParent().setSelection(itm);
				s = true;
			}
			if (top && !topItm && cfnmatch(nabs(top), absp)) {
				topItm = itm;
			}
		}
		return s;
	}

	private Display _display = null;

	Image fimage(Image img) {
		if (img is _prop.images.folder || img is _sImgFolder) {
			return _prop.images.folder;
		} else if (img is _prop.images.cards || img is _sImgCards) {
			return _prop.images.cards;
		} else if (img is _prop.images.backs || img is _sImgBacks) {
			return _prop.images.backs;
		} else if (img is _prop.images.bgm || img is _sImgBgm) {
			return _prop.images.bgm;
		} else if (img is _prop.images.se || img is _sImgSe) {
			return _prop.images.se;
		} else if (img is _prop.images.text || img is _sImgText) {
			return _prop.images.text;
		} else if (img is _prop.images.unknown || img is _sImgUnknown) {
			return _prop.images.unknown;
		}
		assert (0);
	}
	Image sfimage(Image img) {
		if (img is _prop.images.folder || img is _sImgFolder) {
			return _sImgFolder;
		} else if (img is _prop.images.cards || img is _sImgCards) {
			return _sImgCards;
		} else if (img is _prop.images.backs || img is _sImgBacks) {
			return _sImgBacks;
		} else if (img is _prop.images.bgm || img is _sImgBgm) {
			return _sImgBgm;
		} else if (img is _prop.images.se || img is _sImgSe) {
			return _sImgSe;
		} else if (img is _prop.images.text || img is _sImgText) {
			return _sImgText;
		} else if (img is _prop.images.unknown || img is _sImgUnknown) {
			return _sImgUnknown;
		}
		assert (0);
	}
	Image fimage(Skin skin, string file) {
		if (skin.isCardImage(file)) {
			return _prop.images.cards;
		} else if (skin.isBgImage(file)) {
			return _prop.images.backs;
		} else if (skin.isBGM(file)) {
			return _prop.images.bgm;
		} else if (skin.isSE(file)) {
			return _prop.images.se;
		} else if (cfnmatch(cwx.utils.getExt(file), "txt")) {
			return _prop.images.text;
		} else {
			return _prop.images.unknown;
		}
	}
	Image fimage(Skin skin, string file, bool dir) {
		if (isCutted(file)) {
			return sfimage(file);
		}
		if (dir) {
			return _prop.images.folder;
		} else {
			return fimage(skin, file);
		}
	}
	Image fimage(string file) {
		if (isCutted(file)) {
			return sfimage(file);
		}
		if (.isDir(file)) {
			return _prop.images.folder;
		} else {
			return fimage(_comm.skin, file);
		}
	}
	Image sfimage(string file) {
		auto skin = _comm.skin;
		if (.isDir(file)) {
			return _sImgFolder;
		} else if (skin.isCardImage(file)) {
			return _sImgCards;
		} else if (skin.isBgImage(file)) {
			return _sImgBacks;
		} else if (skin.isBGM(file)) {
			return _sImgBgm;
		} else if (skin.isSE(file)) {
			return _sImgSe;
		} else if (cfnmatch(cwx.utils.getExt(file), "txt")) {
			return _sImgText;
		} else {
			return _sImgUnknown;
		}
	}
	private bool isCutted(string file) {
		static if (0 == filenameCharCmp('A', 'a')) {
			file = cwx.utils.toLower(file);
			file = file.nabs;
			return _cuts.contains(file);
		} else {
			return _cuts.contains(nabs(file));
		}
	}
	string toRelPath(string file) {
		file = nabs(file);
		auto sc = nabs(_summ.scenarioPath);
		return file.length == sc.length ? "" : file[(sc ~ sep).length .. $];
	}
	class DirsSelection : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshFiles([]);
			_comm.refreshToolBar();
		}
	}
	class FilesSelection : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshStatusLine();
			_comm.refreshToolBar();
		}
	}
	class FileSelect : KeyAdapter, MouseListener {
	private:
		void select() {
			int index = _files.getSelectionIndex();
			if (index >= 0) {
				auto path = (cast(FileNameObj) _files.getItem(index).getData()).array;
				if (.isDir(path)) {
					auto sels = _dirs.getSelection();
					if (!sels.length) return;
					foreach (itm; sels[0].getItems()) {
						if (cfnmatch((cast(FileNameObj) itm.getData()).array, path)) {
							_dirs.setSelection(itm);
							refreshFiles([]);
							return;
						}
					}
					assert (0);
				} else {
					Program.launch(path);
				}
			}
		}
	public override:
		void mouseUp(MouseEvent e) {}
		void mouseDown(MouseEvent e) {}
		void mouseDoubleClick(MouseEvent e) {
			if ((cast(Control) e.widget).isFocusControl() && e.button == 1) {
				select();
			}
		}
		void keyPressed(KeyEvent e) {
			if (e.character == SWT.CR) {
				select();
			}
		}
	}

	class FilesDrag(C) : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e) {
			auto itms
				= (cast(C) (cast(DragSource) e.getSource()).getControl()).getSelection();
			if (itms.length == 0) return;
			string[] data;
			data.length = itms.length;
			foreach (i, itm; itms) {
				data[i] = (cast(FileNameObj) itm.getData()).array;
			}
			e.data = new FileNames(data);
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail != DND.DROP_NONE) {
				auto sels = selFiles;
				auto sdp = selDirPath;
				refreshDirs(sdp);
				refreshFiles(sels);
				_comm.refPaths.call(this.outer, toRelPath(sdp));
				clearCut();
				if (_summ.useTemp) _summ.changed();
			}
		}
	}
	class FilesDrop(C) : DropTargetAdapter {
	override:
		void dragOver(DropTargetEvent e){
			static if (is (C == Table)) {
				e.detail = DND.DROP_MOVE;
			} else static if (is (C == Tree)) {
				e.detail = e.item ? DND.DROP_MOVE : DND.DROP_NONE;
			} else {
				static assert (0);
			}
		}
		void drop(DropTargetEvent e){
			e.detail = DND.DROP_NONE;
			auto files = cast(FileNames) e.data;
			bool fromOut;
			static if (is (C == Table)) {
				auto toparP = e.item ? (cast(FileNameObj) e.item.getData()).array : selDirPath;
			} else static if (is (C == Tree)) {
				auto toparP = (cast(FileNameObj) e.item.getData()).array;
			} else {
				static assert (0);
			}
			if (!toparP) return;
			string topar = .isDir(toparP) ? toparP : dirName(toparP);
			if (__paste(topar, files, true, fromOut)) {
				e.detail = fromOut ? DND.DROP_COPY : DND.DROP_NONE;
				clearCut();
			}
		}
	}
	bool __paste(string targ, FileNames files, bool move, out bool fromOut) {
		if (files && files.array.length > 0) {
			pauseTrace();
			scope (exit) resumeTrace();
			fromOut = false;
			scope pfull = nabs(_summ.scenarioPath);
			bool top = cast(bool) cfnmatch(nabs(targ), pfull);
			try {
				string[] paths;
				string[] exists;
				string[] copys;
				foreach (file; files.array) {
					file = nabs(file);
					if (hasPath(file, targ)) {
						// 自分の上位のディレクトリを持ってこようとした
						continue;
					}
					auto to = std.path.buildPath(targ, baseName(file));
					if (top) {
						if (isDef(to, cast(bool) isDir(file))) continue;
					} else {
						if (isIgnore(to)) continue;
					}
					if (.exists(to)) {
						bool tisdir = cast(bool) isDir(to);
						if (tisdir ==  cast(bool) isDir(file)) {
							auto par = dirName(file);
							if (cfnmatch(par, targ)) {
								if (!move && !(0 == filenameCharCmp('A', 'a')
										? _cuts.contains(cwx.utils.toLower(file)) : _cuts.contains(file))) {
									copys ~= file;
								}
								continue;
							}
							exists ~= file;
						}
					}
					paths ~= file;
				}
				if (paths.length == 0 && copys.length == 0) return false;
				bool over = false;
				if (exists.length > 0) {
					auto dlg = new MessageBox
						(_win.getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
					dlg.setText(_prop.msgs.dlgTitQuestion);
					if (1 == exists.length) {
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropOverWriteFile, exists[0]));
					} else {
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropOverWriteFiles, exists.length));
					}
					int r = dlg.open();
					if (r == SWT.YES) {
						over = true;
					} else if (r == SWT.CANCEL) {
						return false;
					}
				}
				paths = .sortDlg(paths, &compFullPath);
				string dir = null;
				string[] selfs;
				foreach (file; paths) {
					bool fout = !(0 == filenameCharCmp('A', 'a')
						? _cuts.contains(cwx.utils.toLower(file))
						: _cuts.contains(file))
						&& (!move || !hasPath(pfull, file));
					fromOut |= fout;
					void copy(string parent, string from) {
						auto to = std.path.buildPath(parent, baseName(from));
						if (.exists(to) && cast(bool) isDir(to) == cast(bool) isDir(from) && !over) {
							return;
						}
						if (isDir(from)) {
							if (!.exists(to)) std.file.mkdir(to);
							foreach (child; clistdir(from)) {
								copy(to, std.path.buildPath(from, child));
							}
							if (!dir) dir = to;
							if (!fout) {
								delAll(from);
								string p1 = toRelPath(from);
								string p2 = toRelPath(to);
								_comm.refPath.call(p1, p2, true);
							}
						} else {
							if (fout) {
								.copy(from, to);
							} else {
								string p1 = toRelPath(from);
								string p2 = toRelPath(to);
								if (_summ.useCounter.get(toPathId(p1)) > 0) {
									_summ.useCounter.change(toPathId(p1), toPathId(p2), true);
									_summ.changed();
								}
								_comm.refPath.call(p1, p2, false);
								std.file.rename(from, to);
							}
							if (cfnmatch(parent, targ)) selfs ~= to;
						}
					}
					copy(targ, file);
				}
				foreach (file; copys) {
					void renameCopy(string parent, string from) {
						bool isdir = cast(bool) isDir(from);
						string to = std.path.buildPath(parent, baseName(from));
						to = createNewFileName(to, isdir);
						if (isdir) {
							std.file.mkdir(to);
							foreach (child; clistdir(from)) {
								renameCopy(to, std.path.buildPath(from, child));
							}
							if (!dir) dir = to;
						} else {
							std.file.copy(from, to);
						}
					}
					renameCopy(targ, file);
				}
				_comm.refPaths.call(this, toRelPath(selDirPath));
				if (dir) refreshDirs(.exists(targ) ? targ : dir);
				refreshFiles(selfs);
				return true;
			} catch (Exception e) {
				debugln(e);
			}
		}
		return false;
	}
	@property
	string selDirPath() {
		if (_win && !_win.isDisposed()) {
			auto sels = _dirs.getSelection();
			if (sels.length) {
				return (cast(FileNameObj) sels[0].getData()).array;
			}
		}
		return null;
	}
	@property
	string[] selFiles() {
		string[] r;
		if (_win && !_win.isDisposed()) {
			auto sels = _files.getSelection();
			r.length = sels.length;
			foreach (i, itm; sels) {
				r[i] = (cast(FileNameObj) itm.getData()).array;
			}
		}
		return r;
	}

	SBShell _sbshl;
	Composite _win;
	SplitPane _sash;
	Tree _dirs;
	TreeEdit _dirsEdit;
	Table _files;
	TableTextEdit _filesEdit;
	TableSorter!(FileNameObj) _sortName;
	TableSorter!(FileNameObj) _sortExt;
	TableSorter!(FileNameObj) _sortCount;

	HashSet!(string) _cuts;
	Image _sImgFolder, _sImgCards, _sImgBacks, _sImgBgm, _sImgSe, _sImgText, _sImgUnknown;

	Props _prop;
	Summary _summ = null;

	Commons _comm;

	string pathRename(T)(T itm, string newName) {
		clearCut();
		auto path = (cast(FileNameObj) itm.getData()).array;
		string frp = toRelPath(path);
		string frd = nabs(path);
		newName = std.array.replace(newName, sep, "");
		static if (altsep.length) {
			newName = std.array.replace(newName, altsep, "");
		}
		auto to = std.path.buildPath(dirName(path), newName);
		bool isdir = cast(bool) .isDir(path);
		if (!isdir && cwx.utils.getExt(path).length > 0) {
			to = setExtension(to, cwx.utils.getExt(path));
		}
		if (.exists(to) && cast(bool) .isDir(to) == cast(bool) .isDir(path)) return null;
		try {
			std.file.rename(path, to);
		} catch {
			// 不正な名前
			return null;
		}
		string trp = toRelPath(to);
		if (isdir) {
			string tod = nabs(to);
			void pchange(string file) {
				auto oldP = frd ~ nabs(file)[tod.length .. $];
				if (.exists(file) && .isDir(file)) {
					foreach (c; clistdir(file)) {
						pchange(std.path.buildPath(file, c));
					}
				} else {
					string p1 = toRelPath(oldP);
					string p2 = toRelPath(file);
					if (_summ.useCounter.get(toPathId(p1)) > 0) {
						_summ.useCounter.change(toPathId(p1), toPathId(p2));
						_summ.changed();
					}
				}
			}
			foreach (c; clistdir(to)) {
				pchange(std.path.buildPath(to, c));
			}
		} else {
			string p1 = frp;
			string p2 = toRelPath(to);
			if (_summ.useCounter.get(toPathId(p1)) > 0) {
				_summ.useCounter.change(toPathId(p1), toPathId(p2));
				_summ.changed();
			}
			_comm.refPath.call(p1, p2, false);
		}
		itm.setData(new FileNameObj(to));
		static if (is (T == TreeItem)) {
			itm.setText(baseName(stripExtension(to)));
		} else static if (is (T == TableItem)) {
			itm.setText(0, .isDir(to) ? baseName(to) : baseName(stripExtension(to)));
		} else {
			static assert (0);
		}
		_comm.refPath.call(frp, trp, isdir);
		_comm.refUseCount.call();
		return to;
	}
	void dirsEditEnd(TreeItem itm, Control c) {
		string text = (cast(Text) c).getText();
		if (!text) text = "";
		if (text.length == 0) return;
		auto from = (cast(FileNameObj) itm.getData()).array;
		string frd = nabs(from);
		auto to = pathRename(itm, text);
		if (to) {
			string tod = nabs(to);
			void drename(TreeItem itm) {
				itm.setData(new FileNameObj(tod ~ (cast(FileNameObj) itm.getData()).array[frd.length .. $]));
				foreach (c; itm.getItems()) {
					drename(c);
				}
			}
			foreach (cc; itm.getItems()) {
				drename(cc);
			}
			foreach (t; _files.getItems()) {
				t.setData(new FileNameObj(std.path.buildPath(tod, (cast(FileNameObj) t.getData()).basename)));
			}
		}
	}
	Control dirsCreateEditor(TreeItem itm) {
		return itm.getParentItem() ? createTextEditor(_comm, _prop, _dirs, itm.getText()) : null;
	}
	void filesEditEnd(TableItem itm, int column, string newText) {
		if (newText.length == 0) return;
		assert (column == 0);
		if (pathRename(itm, newText)) {
			refreshDirs(selDirPath);
		}
	}
	void __refPaths(Object sender, string parent) {
		if (sender !is this) {
			refreshDirs(selDirPath);
			if (selDirPath && cfnmatch(toRelPath(selDirPath), parent)) {
				refreshFiles(selFiles);
			}
		}
	}

	void __refreshUseCount() {
		foreach (itm; _files.getItems()) {
			try {
				auto file = cast(FileNameObj) itm.getData();
				if (!.exists(file.array) || !file.material) continue;
				auto c = _summ.useCounter.path.get(file.pathId);
				itm.setText(2, to!(string)(c));
			} catch (Exception e) {
				debugln(e);
			}
		}
	}
	void __refreshTitle() {
		_comm.setTitle(_win, title);
	}
	void __refresh() {
		refreshDirs(selDirPath);
		refreshFiles(selFiles);
	}
	void __delPaths(Object sender) {
		if (sender !is this) {
			refreshDirs(selDirPath);
			refreshFiles(selFiles);
		}
	}
	void saveScenario() {
		_comm.save.call(dlgParShl.getShell());
	}
	class Exec {
		private OuterTool _tool;
		private void run() {
			string file = "";
			string[] sf = selFiles;
			foreach (i, f; sf) {
				file ~= `"` ~ f ~ `"`;
				if (i + 1 < sf.length) file ~= " ";
			}
			string sp = _summ ? _summ.scenarioPath : std.file.getcwd();
			auto cwd = std.file.getcwd();
			string wd = OuterTool.parse(_tool.workDir, file, sp);
			if (wd.length > 0) {
				if (!cwx.utils.isabs(wd)) {
					wd = std.path.buildPath(std.path.dirName(_prop.parent.appPath), wd);
				}
			} else {
				wd = dirName(_prop.parent.appPath);
			}
			auto cmd = OuterTool.parse(_tool.command, file, sp);
			if (!exec(cmd, wd)) {
				MessageBox.showWarning
					(.tryFormat(_prop.msgs.errorExec, _tool.name),
					_prop.msgs.dlgTitWarning, _win.getShell());
			}
		}
		this (Menu menu, OuterTool tool) {
			createMenuItem2(_comm, menu, tool.name, null, &run, null);
			_tool = tool;
		}
	}
	void createFilesMenu() {
		if (_files.getMenu()) _files.getMenu().dispose();
		auto menu = new Menu(_win.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.ReplFilePath, &replace, () => _summ !is null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.NewDir, &createDirFiles, () => _summ !is null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CreateArchive, &createArchive, &canCreateArchive);
		new MenuItem(menu, SWT.SEPARATOR);
		foreach (tool; _prop.var.etc.outerTools) {
			new Exec(menu, tool);
		}
		if (_prop.var.etc.outerTools.length > 0) new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(_comm, menu, this, true, true, true, true);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CopyFilePath, &copyFilePath, () => _files.getSelectionIndex() != -1);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.DelNotUsedFile, &deleteUnuse, &canDeleteUnuse);

		_files.setMenu(menu);
	}
	string createDir() {
		auto dir = selDirPath;
		if (!dir) return null;
		string fp;
		createNewName(_prop.msgs.newFolder, (string name) {
			string p = std.path.buildPath(dir, name);
			fp = p;
			if (!.exists(fp)) {
				std.file.mkdir(fp);
				fp = nabs(fp);
				if (_summ.useTemp) _summ.changed();
				return true;
			} else {
				return false;
			}
		}, false);
		return fp;
	}
	void createDirDirs() {
		if (!_win || _win.isDisposed()) {
			_comm.openDirWin(false);
		}
		auto fp = createDir();
		if (!fp) return;
		refreshDirs(fp);
		refreshFiles(null);
		.forceFocus(_dirs, true);
		_dirsEdit.startEdit();
	}
	void createDirFiles() {
		if (!_win || _win.isDisposed()) {
			_comm.openDirWin(false);
		}
		auto fp = createDir();
		if (!fp) return;
		auto files = selFiles ~ fp;
		refreshDirs(selDirPath);
		refreshFiles(files);
		foreach (itm; _files.getItems()) {
			if (cfnmatch((cast(FileNameObj) itm.getData()).array, fp)) {
				.forceFocus(_files, true);
				_filesEdit.startEdit(itm);
				break;
			}
		}
	}
	void __replace(string sel) {
		if (!_summ || !_win || _win.isDisposed()) return;
		_comm.replacePath(sel);
	}
	class SClose : ShellAdapter {
		override void shellClosed(ShellEvent e) {
			(cast(Shell) e.widget).setVisible(false);
			e.doit = false;
			_prop.var.dirWin.visible = false;
			switch (_files.getSortDirection()) {
			case SWT.UP:
				_prop.var.etc.filesSortDirection = SortDir.Up;
				break;
			case SWT.DOWN:
				_prop.var.etc.filesSortDirection = SortDir.Down;
				break;
			default:
				// 必ずソートする
				_prop.var.etc.filesSortDirection = SortDir.Up;
				break;
			}
			if (_files.getSortColumn() is _sortName.column) {
				_prop.var.etc.filesSortColumn = 0;
			} else if (_files.getSortColumn() is _sortExt.column) {
				_prop.var.etc.filesSortColumn = 1;
			} else if (_files.getSortColumn() is _sortCount.column) {
				_prop.var.etc.filesSortColumn = 2;
			} else {
				_prop.var.etc.filesSortColumn = -1;
			}
		}
	}
	class FDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refOuterTools.remove(&createFilesMenu);
		}
	}
	class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refScenarioName.remove(&__refreshTitle);
			_comm.refScenarioPath.remove(&__refreshTitle);
			_comm.refUseCount.remove(&__refreshUseCount);
			_comm.refPaths.remove(&__refPaths);
			_comm.delPaths.remove(&__delPaths);
			_comm.saved.remove(&refCheckPaths);
			_comm.replText.remove(&__refreshTitle);
			_comm.refIgnorePaths.remove(&__refresh);
			_sImgFolder.dispose();
			_sImgCards.dispose();
			_sImgBacks.dispose();
			_sImgBgm.dispose();
			_sImgSe.dispose();
			_sImgText.dispose();
			_sImgUnknown.dispose();
		}
	}
	private SDListener _sdl;
	class SDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_prop.var.etc.directorySashL = _sash.getWeights()[0];
			_prop.var.etc.directorySashR = _sash.getWeights()[1];
			_prop.var.etc.directorySashV = (_sash.getStyle() & SWT.VERTICAL) != 0;
			_win = null;
		}
	}
	private class RefreshThr : Runnable {
		private bool _onRefresh = false;
		override void run() {
			// syncExecを使うとたまに止まるのでここで制御する
			if (_onRefresh) return;
			_onRefresh = true;
			scope (exit) _onRefresh = false;
			if (_stopTrace) return;
			if (_dirsEdit.isEditing() || _filesEdit.isEditing()) return;
			try {
				__refresh();
				_comm.refPaths.call(this.outer, _summ.scenarioPath);
			} catch (Exception e) {
				debugln(e);
			}
		}
	}
	private Runnable _refreshThr;
	private core.thread.Thread _traceThr = null;
	private bool _onTrace = true;
	private bool _stopTrace = false;
	version (Windows) {
		private HANDLE _traceHandle = INVALID_HANDLE_VALUE;
		private void closeTraceHandle() {
			synchronized (_refreshThr) closeTraceHandleImpl();
		}
		private void closeTraceHandleImpl() {
			if (_traceHandle !is INVALID_HANDLE_VALUE) FindCloseChangeNotification(_traceHandle);
			_traceHandle = INVALID_HANDLE_VALUE;
		}
	} else version (linux) {
		private int _traceHandle = -1;
		private void closeTraceHandle() {
			synchronized (_refreshThr) closeTraceHandleImpl;
		}
		private void closeTraceHandleImpl() {
			if (_traceHandle !is -1) close(_traceHandle);
			_traceHandle = -1;
		}
	} else {
		private void closeTraceHandle() {}
	}
	private void trace() {
		try {
			version (Console) {
				debug std.stdio.writeln("Start Trace Thread");
			}
			Summary summ = null;
			void sleep() {
				version (Windows) {
					Sleep(1000); // 1sec
				} else {
					.sleep(1); // 1sec
				}
			}
			@property
			bool canDoChk() {
				return summ && !_display.isDisposed() && _prop.var.etc.traceDirectories && _win;
			}
			version (Windows) {
				bool setup() {
					synchronized (_refreshThr) {
						closeTraceHandleImpl();
						if (summ) {
							DWORD fs = FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME;
							_traceHandle = FindFirstChangeNotificationW(toUTFz!(wchar*)(summ.scenarioPath), TRUE, fs);
							return _traceHandle !is INVALID_HANDLE_VALUE;
						}
						return true;
					}
				}
				scope (exit) {
					synchronized (_refreshThr) {
						if (_traceHandle !is INVALID_HANDLE_VALUE) FindCloseChangeNotification(_traceHandle);
					}
				}
				void next() {
					synchronized (_refreshThr) {
						if (_traceHandle !is INVALID_HANDLE_VALUE) {
							if (!FindNextChangeNotification(_traceHandle)) {
								debugln("FindNextChangeNotification failed: ", GetLastError());
							}
						}
					}
				}
				while (_onTrace && _display && !_display.isDisposed()) {
					try {
						if (_stopTrace) {
							sleep();
							continue;
						}
						if (summ !is _summ) {
							summ = _summ;
							if (!setup()) {
								debugln("FindFirstChangeNotification failed: ", GetLastError());
								continue;
							}
						}
						if (!canDoChk) {
							sleep();
							continue;
						}
						switch (WaitForSingleObject(_traceHandle, 1000)) {
						case WAIT_TIMEOUT: {
							next();
						} break;
						case WAIT_ABANDONED: {
							break;
						}
						case WAIT_OBJECT_0: {
							if (!canDoChk) continue;
							_display.asyncExec(_refreshThr);
							next();
						} break;
						case WAIT_FAILED: {
							debugln("WaitForSingleObject failed: ", GetLastError());
						} break;
						default: break;
						}
					} catch (Exception e) {
						debugln("Trace thread: " ~ e.msg);
						break;
					}
				}
			} else version (linux) {
				bool setup() {
					synchronized (_refreshThr) {
						closeTraceHandleImpl();
						_traceHandle = inotify_init();
						if (_traceHandle is -1) return false;
						void put(string path) {
							foreach (file; clistdir(path)) {
								file = std.path.buildPath(path, file);
								if (isDir(file)) {
									inotify_add_watch(_traceHandle, std.string.toStringz(file),
										IN_MODIFY | IN_ATTRIB | IN_MOVED_FROM | IN_MOVED_TO
										| IN_CREATE | IN_DELETE | IN_DELETE_SELF);
									put(file);
								}
							}
						}
						put(summ.scenarioPath);
						return true;
					}
				}
				scope (exit) {
					synchronized (_refreshThr) {
						if (_traceHandle !is -1) close(_traceHandle);
					}
				}
				while (_onTrace && _display && !_display.isDisposed()) {
					try {
						if (_stopTrace) {
							sleep();
							continue;
						}
						if (summ !is _summ) {
							summ = _summ;
							if (!setup()) {
								debugln("inotify_init() failed");
								continue;
							}
						}
						if (!canDoChk) {
							sleep();
							continue;
						}
						byte[inotify_event.sizeof * 1024] buf;
						int len;
						synchronized (_refreshThr) {
							len = std.c.linux.linux.read(_traceHandle, buf.ptr, buf.sizeof);
						}
						if (-1 == len) break;
						if (0 == len) {
							sleep();
							continue;
						}
						if (!canDoChk) continue;
						_display.asyncExec(_refreshThr);
					} catch (Exception e) {
						debugln("Trace thread: " ~ e.msg);
						break;
					}
				}
			} else {
				d_time[string] dirTimes;
				void setup() {
					d_time[string] times;
					if (summ) {
						void refr(string path) {
							if (summ.isSystemFile(path)
									|| containsPath(_prop.var.etc.ignorePaths, baseName(path))) {
								return;
							}
							times[path] = lastModified(path);
							foreach (sub; clistdir(path)) {
								sub = std.path.buildPath(path, sub);
								if (isDir(sub)) refr(sub);
							}
						}
						refr(nabs(summ.scenarioPath));
					}
					dirTimes = times;
				}
				while (_onTrace && _display && !_display.isDisposed()) {
					try {
						if (_stopTrace) {
							sleep();
							continue;
						}
						if (summ !is _summ) {
							summ = _summ;
							setup();
						}
						sleep();
						if (!canDoChk) continue;
						bool chk(string path) {
							if (summ.isSystemFile(path)
									|| containsPath(_prop.var.etc.ignorePaths, baseName(path))) {
								return false;
							}
							if (dirTimes[path] != lastModified(path)) return true;
							foreach (sub; clistdir(path)) {
								sub = std.path.buildPath(path, sub);
								if (isDir(sub) && chk(sub)) return true;
							}
							return false;
						}
						if (chk(nabs(summ.scenarioPath))) {
							_display.asyncExec(_refreshThr);
							setup;
						}
					} catch (Exception e) {
						debugln("Trace thread: " ~ e.msg);
						break;
					}
				}
			}
			version (Console) {
				debug writeln("Exit Trace Thread");
			}
		} catch (Exception e) {
			debugln(e);
		}
	}
	void refreshStatusLine() {
		if (!_win || _win.isDisposed()) return;
		ulong size;
		foreach (itm; _files.getItems()) {
			auto d = cast(FileNameObj) itm.getData();
			size += d.size;
		}
		string sizeKB = formatNum(size / 1024) ~ " KB";
		int fileCount = _files.getItemCount();
		int selCount = selFiles.length;
		string s;
		if (0 < selCount) {
			s = .tryFormat(_prop.msgs.dirStatusSel, fileCount, sizeKB, selCount);
		} else {
			s = .tryFormat(_prop.msgs.dirStatus, fileCount, sizeKB);
		}
		_comm.setStatusLine(_win, s, _dirs.isFocusControl() || _files.isFocusControl());
	}
	@property
	Shell dlgParShl() {
		if (_win && !_win.isDisposed()) return _win.getShell();
		return _comm.mainWin.shell.getShell();
	}
public:
	this (Commons comm, Props prop, Composite parent) {
		_prop = prop;
		_comm = comm;
		_display = Display.getCurrent();
		if (parent) construct(parent);

		// FXIME: 本当は素材管理ウィンドウ非表示時は止めておきたかったが
		// シナリオ読込み後のスレッドの開始に失敗する事があるので常時起動
		_refreshThr = new RefreshThr;
		_traceThr = new core.thread.Thread(&trace);
		_traceThr.start();
	}
	void reconstruct(Composite parent) {
		if (_win && !_win.isDisposed()) return;
		construct(parent);
		if (_summ) refresh(_summ);
	}
	private void construct(Composite parent) {
		_cuts = new typeof(_cuts);
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		Composite contPane;
		if (parShl) {
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImage(_prop.images.app);
			shell.addShellListener(new SClose);
			_win = shell;
			contPane = _sbshl.contentPane;
		} else {
			_win = new Composite(parent, SWT.NONE);
			contPane = _win;
		}
		_win.setData(new TLPData(this));
		contPane.setLayout(windowGridLayout(1, true));
		_comm.refScenarioName.add(&__refreshTitle);
		_comm.refScenarioPath.add(&__refreshTitle);
		_comm.refUseCount.add(&__refreshUseCount);
		_comm.refPaths.add(&__refPaths);
		_comm.delPaths.add(&__delPaths);
		_comm.saved.add(&refCheckPaths);
		_comm.replText.add(&__refreshTitle);
		_comm.refIgnorePaths.add(&__refresh);
		_sImgFolder = skeletonImage(_prop.images.folder);
		_sImgCards = skeletonImage(_prop.images.cards);
		_sImgBacks = skeletonImage(_prop.images.backs);
		_sImgBgm = skeletonImage(_prop.images.bgm);
		_sImgSe = skeletonImage(_prop.images.se);
		_sImgText = skeletonImage(_prop.images.text);
		_sImgUnknown = skeletonImage(_prop.images.unknown);
		_win.addDisposeListener(new DListener);
		if (shell) {
			auto bar = new Menu(shell, SWT.BAR);

			auto mf = createMenu(_comm, bar, MenuID.File);
			createMenuItem(_comm, mf, MenuID.OpenDir, &openDirectory, &canOpenDirectory);
			new MenuItem(mf, SWT.SEPARATOR);
			createMenuItem(_comm, mf, MenuID.CloseWin, &shell.close, null);

			auto me = createMenu(_comm, bar, MenuID.Edit);
			createMenuItem(_comm, me, MenuID.ReplFilePath, &replace, () => _summ !is null);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.NewDir, &createNewFolder, &canCreateNewFolder);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.CreateArchive, &createArchive, &canCreateArchive);
			new MenuItem(me, SWT.SEPARATOR);
			appendMenuTCPD(_comm, me, this, true, true, true, true);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.DelNotUsedFile, &deleteUnuse, &canDeleteUnuse);

			auto mv = createMenu(_comm, bar, MenuID.View);
			createMenuItem(_comm, mv, MenuID.Refresh, &__refresh, () => _summ !is null);
			new MenuItem(mv, SWT.SEPARATOR);
			createMenuItem(_comm, mv, MenuID.ChangeVH, &changeVHSide, null);

			shell.setMenuBar(bar);
		} else {
			appendMenuTCPD(_comm, this, this, true, true, true, true);
			putMenuAction(MenuID.ReplFilePath, &replace, () => _summ !is null);
			putMenuAction(MenuID.Refresh, &__refresh, () => _summ !is null);
			putMenuAction(MenuID.OpenDir, &openDirectory, &canOpenDirectory);
			putMenuAction(MenuID.NewDir, &createNewFolder, &canCreateNewFolder);
			putMenuAction(MenuID.CreateArchive, &createArchive, &canCreateArchive);
			putMenuAction(MenuID.ChangeVH, &changeVHSide, null);
			putMenuAction(MenuID.DelNotUsedFile, &deleteUnuse, &canDeleteUnuse);
		}
		if (shell) {
			auto bar = new ToolBar(contPane, SWT.FLAT);
			_comm.put(bar);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

			createToolItem(_comm, bar, MenuID.OpenDir, &openDirectory, &canOpenDirectory);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.Refresh, &__refresh, () => _summ !is null);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.ReplFilePath, &replace, () => _summ !is null);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.NewDir, &createNewFolder, &canCreateNewFolder);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.CreateArchive, &createArchive, &canCreateArchive);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.Cut, &cut, &canDoT);
			createToolItem(_comm, bar, MenuID.Copy, &copy, &canDoC);
			createToolItem(_comm, bar, MenuID.Paste, &paste, &canDoP);
			createToolItem(_comm, bar, MenuID.Delete, &del, &canDoD);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.ChangeVH, &changeVHSide, null);
		}
		_sash = new SplitPane(contPane, _prop.var.etc.directorySashV ? SWT.VERTICAL : SWT.HORIZONTAL);
		_sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto dirsComp = new Composite(_sash, SWT.NONE);
		dirsComp.setLayout(new FillLayout);
		_dirs = new Tree(dirsComp, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL);
		initTree(_dirs, false);
		{
			_dirs.addSelectionListener(new DirsSelection);
			_dirsEdit = new TreeEdit(_comm, _dirs, &dirsEditEnd, &dirsCreateEditor);

			auto drop = new DropTarget
				(_dirs, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE);
			drop.setTransfer([FileTransfer.getInstance()]);
			drop.addDropListener(new FilesDrop!(Tree));
			auto drag = new DragSource
				(_dirs, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE);
			drag.setTransfer([FileTransfer.getInstance()]);
			drag.addDragListener(new FilesDrag!(Tree));

			auto menu = new Menu(_win.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.NewDir, &createDirDirs, () => _summ !is null);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.CreateArchive, &createArchive, &canCreateArchive);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, this, true, true, true, true);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.DelNotUsedFile, &deleteUnuse, &canDeleteUnuse);
			_dirs.setMenu(menu);
		}
		auto fComp = new Composite(_sash, SWT.NONE);
		fComp.setLayout(new FillLayout);
		_files = new Table(fComp, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER | SWT.VIRTUAL);
		{
			_files.addSelectionListener(new FilesSelection);
			_files.setHeaderVisible(true);
			auto namec = new TableColumn(_files, SWT.NONE);
			namec.setText(_prop.msgs.fileName);
			saveColumnWidth!("prop.var.etc.fileNameColumn")(_prop, namec);
			auto extc = new TableColumn(_files, SWT.NONE);
			extc.setText(_prop.msgs.fileExt);
			saveColumnWidth!("prop.var.etc.fileExtColumn")(_prop, extc);
			auto cc = new TableColumn(_files, SWT.NONE);
			cc.setText(_prop.msgs.fileCount);
			saveColumnWidth!("prop.var.etc.fileCountColumn")(_prop, cc);
			_filesEdit = new TableTextEdit(_comm, _prop, _files, 0, &filesEditEnd);

			auto fs = new FileSelect;
			_files.addKeyListener(fs);
			_files.addMouseListener(fs);
			auto drop = new DropTarget
				(_files, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE);
			drop.setTransfer([FileTransfer.getInstance()]);
			drop.addDropListener(new FilesDrop!(Table));
			auto drag = new DragSource
				(_files, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE | DND.DROP_LINK);
			drag.setTransfer([FileTransfer.getInstance()]);
			drag.addDragListener(new FilesDrag!(Table));

			_sortName = new TableSorter!(FileNameObj)(namec, &compFName, &revCompFName);
			_sortExt = new TableSorter!(FileNameObj)(extc, &compFExt, &revCompFExt);
			_sortCount = new TableSorter!(FileNameObj)(cc, &compFCount, &revCompFCount);
			TableSorter!(FileNameObj) st;
			switch (_prop.var.etc.filesSortColumn) {
			case 0:
				st = _sortName;
				break;
			case 1:
				st = _sortExt;
				break;
			case 2:
				st = _sortCount;
				break;
			default:
			}
			switch (_prop.var.etc.filesSortDirection) {
			case SortDir.Up:
				st.doSort(SWT.UP);
				break;
			case SortDir.Down:
				st.doSort(SWT.DOWN);
				break;
			default:
				// 必ずソートする
				st.doSort(SWT.UP);
				break;
			}

			_comm.refOuterTools.add(&createFilesMenu);
			_files.addDisposeListener(new FDListener);
			createFilesMenu();
		}
		_sash.setWeights([_prop.var.etc.directorySashL, _prop.var.etc.directorySashR]);
		_sdl = new SDListener;
		_sash.addDisposeListener(_sdl);
		if (shell) {
			shell.setMaximized(_prop.var.dirWin.maximized);
			shell.setMinimized(_prop.var.dirWin.minimized);
			shell.pack();
			scope wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			int width = _prop.var.dirWin.width == SWT.DEFAULT
				? wp.x : _prop.var.dirWin.width;
			int height = _prop.var.dirWin.height == SWT.DEFAULT
				? wp.y : _prop.var.dirWin.height;
			int x = _prop.var.dirWin.x == SWT.DEFAULT
				? shell.getBounds().x : _prop.var.dirWin.x + shell.getParent().getBounds().x;
			int y = _prop.var.dirWin.y == SWT.DEFAULT
				? shell.getBounds().y : _prop.var.dirWin.y + shell.getParent().getBounds().y;
			intoDisplay(x, y, width, height);
			shell.setBounds(x, y, width, height);
			shell.addControlListener(new SCListener);
		}
	}
	private class SCListener : ControlAdapter {
		override void controlMoved(ControlEvent e) {
			saveWin();
		}
		override void controlResized(ControlEvent e) {
			saveWin();
		}
	}
	private void saveWin() {
		auto win = cast(Shell) _win;
		if (win) {
			if (!win.getMaximized() && !win.getMinimized()) {
				_prop.var.dirWin.width = win.getSize().x;
				_prop.var.dirWin.height = win.getSize().y;
				_prop.var.dirWin.x = win.getBounds().x - win.getParent().getBounds().x;
				_prop.var.dirWin.y = win.getBounds().y - win.getParent().getBounds().y;
			}
			_prop.var.dirWin.maximized = win.getMaximized();
			_prop.var.dirWin.minimized = win.getMinimized();
		}
	}
	void removeFiles(in string[] file, bool recycle) {
		pauseTrace();
		scope (exit) resumeTrace();
		version (Windows) {
			wstring targ;
			foreach (i, f; file) {
				targ ~= toUTF16(f);
				targ ~= '\0';
			}
			targ ~= '\0';
			SHFILEOPSTRUCT ope;
			ope.hwnd = cast(HANDLE) shell.handle;
			ope.wFunc = FO_DELETE;
			ope.pFrom = targ.ptr;
			ope.pTo = null;
			ope.fFlags = FOF_MULTIDESTFILES | FOF_NOCONFIRMATION;
			if (recycle) ope.fFlags |= FOF_ALLOWUNDO;
			ope.fAnyOperationsAborted = false;
			ope.hNameMappings = null;
			ope.lpszProgressTitle = null;
			if (0 != SHFileOperationW(&ope)) return;
		} else {
			foreach (f; file) {
				delAll(f);
			}
		}
	}
	bool canDeleteUnuse() {
		return _summ !is null;
	}
	void deleteUnuse(SelectionEvent se) {
		if (!_summ) return;
		auto files = _summ.notUsedFiles(_comm.skin, _prop.var.etc.ignorePaths, _prop.var.etc.logicalSort);
		if (!files.length) return;
		foreach (ref file; files) {
			file = _summ.scenarioPath.buildPath(file);
		}
		bool recycle = (se.stateMask & SWT.SHIFT) == 0;
		auto shl = dlgParShl.getShell();
		auto dlg = new MessageBox(shl, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
		version (Windows) {
			if (recycle) {
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteRecycleUnuse, files.length));
			} else {
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteUnuse, files.length));
			}
		} else {
			dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteUnuse, files.length));
		}
		dlg.setText(_prop.msgs.dlgTitQuestion);
		if (SWT.YES == dlg.open()) {
			removeFiles(files, recycle);
			_comm.refreshToolBar();
		}
	}

	@property
	Composite shell() {return _win;}

	@property
	Image image() {
		return _prop.images.menu(MenuID.FileView);
	}
	@property
	string title() {
		auto shl = cast(Shell) _win;
		if (shl) {
			return .tryFormat(_prop.msgs.dirWindowName, _summ.scenarioName, _summ.scenarioPath);
		}
		return _prop.msgs.dirTabName;
	}
	@property
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	void copyFilePath() {
		if (!_summ) return;
		int sel = _files.getSelectionIndex();
		if (-1 == sel) return;
		auto fno = cast(FileNameObj) _files.getItem(sel).getData();
		_comm.clipboard.setContents([new PathString(encodePath(fno.relPath))],
			[TextTransfer.getInstance()]);
	}
	void replace() {
		if (!_summ) return;
		if (_files.getSelectionIndex() >= 0) {
			__replace((cast(FileNameObj) _files.getItem(_files.getSelectionIndex()).getData()).relPath);
		} else {
			__replace(null);
		}
	}
	private void changeVHSide() {
		_sash.removeDisposeListener(_sdl);
		_sash = .changeVHSide(_sash);
		_sash.addDisposeListener(_sdl);
	}

	void stopTrace() {
		closeTraceHandle();
		_stopTrace = true;
	}
	void resumeTrace() {_stopTrace = false;}
	void pauseTrace() {_stopTrace = true;}

	void refresh(Summary summ) {
		_summ = summ;
		if (_win && !_win.isDisposed()) {
			refreshDirs(std.path.buildPath(_summ.scenarioPath, _comm.skin.materialPath));
			refreshFiles(null);
			auto root = _dirs.getItem(0);
			root.setExpanded(true);
			_dirs.setSelection([root]);
			_dirs.showSelection();
			refCheckPaths();
			__refreshTitle();
			_comm.refreshToolBar();
		}
	}

	@property
	bool isChanged() {
		if (_summ.useTemp) {
			return _summ.isChanged || _checkPaths != allPaths;
		}
		return _summ.isChanged;
	}

	private void clearCut() {
		_cuts.clear();
		void titm(TreeItem itm) {
			if (itm.getImage() is _sImgFolder) {
				itm.setImage(_prop.images.folder);
			}
			foreach (child; itm.getItems()) {
				titm(child);
			}
		}
		foreach (itm; _dirs.getItems()) {
			titm(itm);
		}
		foreach (itm; _files.getItems()) {
			auto img = fimage(itm.getImage());
			if (itm.getImage() !is img) {
				itm.setImage(img);
			}
		}
	}

	@property
	bool canOpenDirectory() {
		return _summ !is null;
	}
	void openDirectory() {
		auto dir = selDirPath;
		if (dir) openFolder(dir);
	}
	@property
	bool canCreateNewFolder() {
		return _summ !is null;
	}
	void createNewFolder() {
		if (!_win || _win.isDisposed()) {
			_comm.openDirWin(false);
		}
		if (_files.isFocusControl()) {
			createDirFiles();
		} else {
			createDirDirs();
		}
	}

	private bool selectImpl(T)(T tree, string path) {
		foreach (itm; tree.getItems()) {
			auto fno = cast(FileNameObj) itm.getData();
			if (cfnmatch(fno.array, path)) {
				_dirs.select(itm);
				refreshFiles(selFiles);
				_comm.refreshToolBar();
				return true;
			}
			if (selectImpl(itm, path)) {
				_comm.refreshToolBar();
				return true;
			}
		}
		return false;
	}
	bool select(string path) {
		try {
			if (.exists(path)) {
				path = nabs(path);
				auto isdir = .isDir(path);
				string dir = isdir ? path : dirName(path);
				bool r = selectImpl(_dirs, dir);
				if (r) {
					_dirs.showSelection();
					if (!isdir) {
						foreach (i, itm; _files.getItems()) {
							auto fno = cast(FileNameObj) itm.getData();
							if (cfnmatch(fno.array, path)) {
								_files.select(i);
								_files.showSelection();
								_comm.refreshToolBar();
								return true;
							}
						}
						return false;
					}
					return true;
				}
			}
		} catch (Exception e) {
			debugln(e);
		}
		return false;
	}

	void quitTrace() {
		if (!_traceThr) return;
		_onTrace = false;
		try {
			_traceThr.join();
		} catch (Throwable e) {
			debugln(e);
		}
	}

	@property
	bool canCreateArchive() {
		return _summ !is null;
	}
	void createArchive() {
		if (!_summ) return;
		auto shl = dlgParShl.getShell();
		if (_comm.isChanged) {
			auto dlg = new MessageBox(shl, SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
			dlg.setText(_prop.msgs.dlgTitQuestion);
			dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgIsSaveBeforeCreateArchive, _summ.scenarioName));
			shl.setMinimized(false);
			switch (dlg.open()) {
			case SWT.YES, SWT.OK:
				saveScenario();
				break;
			case SWT.NO:
				break;
			case SWT.CANCEL:
				return;
			default: assert (0);
			}
		}
		auto dlg = new FileDialog(shl, SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.SAVE);
		int zip, cab, wsn;
		if (canUncab) {
			dlg.setFilterExtensions(["*.zip", "*.cab", "*.wsn"]);
			dlg.setFilterNames([_prop.msgs.filterDescZip, _prop.msgs.filterDescCab, _prop.msgs.filterDescWsn]);
			zip = 0;
			cab = 1;
			wsn = 2;
		} else {
			dlg.setFilterExtensions(["*.zip", "*.wsn"]);
			dlg.setFilterNames([_prop.msgs.filterDescZip, _prop.msgs.filterDescWsn]);
			zip = 0;
			cab = -1;
			wsn = 1;
		}
		dlg.setText(_prop.msgs.dlgTitCreateArchive);
		if (_prop.var.etc.archivePath.length) {
			dlg.setFilterPath(_prop.var.etc.archivePath);
		} else {
			dlg.setFilterPath(getcwd());
		}
		switch (_prop.var.etc.selectedArchiveFilter) {
		case "cab":
			if (!canUncab) {
				goto default;
			}
			dlg.setFilterIndex(cab);
			dlg.setFileName(setExtension(_summ.scenarioName, "cab"));
			break;
		case "wsn":
			dlg.setFilterIndex(wsn);
			dlg.setFileName(setExtension(_summ.scenarioName, "wsn"));
			break;
		default:
			dlg.setFilterIndex(zip);
			dlg.setFileName(setExtension(_summ.scenarioName, "zip"));
			break;
		}
		dlg.setOverwrite(true);
		string fname = dlg.open();
		if (!fname) return;

		try {
			switch (dlg.getFilterIndex()) {
			case cab:
				synchronized (_comm.saveSync) {
					_summ.createCab(fname, _prop.var.etc.ignorePaths);
				}
				_prop.var.etc.selectedArchiveFilter = "cab";
				break;
			case wsn:
				synchronized (_comm.saveSync) {
					_summ.createZip(fname, _prop.var.etc.ignorePaths, false);
				}
				_prop.var.etc.selectedArchiveFilter = "wsn";
				break;
			default:
				synchronized (_comm.saveSync) {
					_summ.createZip(fname, _prop.var.etc.ignorePaths, true);
				}
				_prop.var.etc.selectedArchiveFilter = "zip";
				break;
			}
			_prop.var.etc.archivePath = dlg.getFilterPath();
		} catch (Exception e) {
			debugln(e);
			_comm.setStatusLine(_win, _prop.msgs.failedCreateArchive);
		}
	}

	override void cut(SelectionEvent se) {
		if (!canDoTCPD) return;
		if (_dirs.isFocusControl()) {
			auto sels = _dirs.getSelection();
			if (!sels.length) return;
			if (!sels[0].getParentItem()) return;
		}
		if (__copy()) {
			if (_dirs.isFocusControl()) {
				auto sels = _dirs.getSelection();
				if (!sels.length) return;
				auto dir = selDirPath;
				sels[0].setImage(sfimage(dir));
				static if (0 == filenameCharCmp('A', 'a')) {
					_cuts.add(cwx.utils.toLower(nabs(dir)));
				} else {
					_cuts.add(nabs(dir));
				}
			} else {
				assert (_files.isFocusControl());
				bool isdir = false;
				foreach (itm; _files.getSelection()) {
					auto p = (cast(FileNameObj) itm.getData()).array;
					itm.setImage(sfimage(itm.getImage()));
					static if (0 == filenameCharCmp('A', 'a')) {
						_cuts.add(cwx.utils.toLower(nabs(p)));
					} else {
						_cuts.add(nabs(p));
					}
					if (!isdir && .isDir(p)) isdir = true;
				}
				if (isdir) refreshDirs(selDirPath);
			}
			_comm.refreshToolBar();
		}
	}
	override void copy(SelectionEvent se) {
		if (!canDoTCPD) return;
		__copy();
	}
	private bool __copy() {
		clearCut();
		if (_dirs.isFocusControl()) {
			auto dir = selDirPath;
			if (dir) {
				_comm.clipboard.setContents([new FileNames([nabs(dir)])],
					[FileTransfer.getInstance()]);
				return true;
			}
		} else {
			assert (_files.isFocusControl());
			auto files = selFiles;
			if (files.length > 0) {
				string[] arr;
				arr.length = files.length;
				foreach (i, f; files) {
					arr[i] = nabs(f);
				}
				_comm.clipboard.setContents([new FileNames(arr)],
					[FileTransfer.getInstance()]);
				return true;
			}
		}
		return false;
	}
	override void paste(SelectionEvent se) {
		if (!canDoTCPD) return;
		auto c = _comm.clipboard.getContents(FileTransfer.getInstance());
		if (c && cast(FileNames) c) {
			bool fromOut;
			if (__paste(selDirPath, cast(FileNames) c, false, fromOut)) {
				clearCut();
				if (_summ.useTemp) _summ.changed();
				_comm.refreshToolBar();
			}
		}
	}
	override void del(SelectionEvent se) {
		if (!canDoTCPD) return;
		if (_dirs.isFocusControl()) {
			auto sels = _dirs.getSelection();
			if (!sels.length) return;
			if (!sels[0].getParentItem()) return;
		}
		auto dlg = new MessageBox(_win.getShell(), SWT.ICON_QUESTION | SWT.OK | SWT.CANCEL);
		dlg.setText(_prop.msgs.dlgTitQuestion);
		auto dir = selDirPath;
		auto file = selFiles;
		string[] fileNames;
		fileNames.length = file.length;
		foreach (i, f; file) {
			fileNames[i] = nabs(f);
		}
		bool recycle = (se.stateMask & SWT.SHIFT) == 0;
		if (_dirs.isFocusControl()) {
			if (!dir) return;
			version (Windows) {
				if (recycle) {
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFileRecycle, nabs(dir)));
				} else {
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFile, nabs(dir)));
				}
			} else {
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFile, nabs(dir)));
			}
			if (SWT.OK == dlg.open()) {
				removeFiles([nabs(dir)], recycle);
			} else {
				return;
			}
		} else {
			assert (_files.isFocusControl());
			if (file.length == 0) return;
			version (Windows) {
				if (1 == fileNames.length) {
					if (recycle) {
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFileRecycle, fileNames[0]));
					} else {
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFile, fileNames[0]));
					}
				} else {
					if (recycle) {
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFilesRecycle, fileNames.length));
					} else {
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFiles, fileNames.length));
					}
				}
			} else {
				if (1 == fileNames.length) {
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFile, fileNames[0]));
				} else {
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFiles, fileNames.length));
				}
			}
			if (SWT.OK == dlg.open()) {
				removeFiles(file, recycle);
			} else {
				return;
			}
		}
		refreshDirs(dir);
		refreshFiles(file);
		_comm.delPaths.call(this);
		if (_summ.useTemp) _summ.changed();
		clearCut();
		_comm.refreshToolBar();
	}
	@property
	override bool canDoTCPD() {
		return _dirs.isFocusControl() || _files.isFocusControl();
	}
	@property
	bool canDoT() {
		if (_dirs.isFocusControl()) {
			auto sels = _dirs.getSelection();
			return sels.length > 0 && sels[0].getParentItem();
		} else if (_files.isFocusControl()) {
			return _files.getSelectionIndex() != -1;
		}
		return false;
	}
	@property
	bool canDoC() {
		if (_dirs.isFocusControl()) {
			return _dirs.getSelection().length > 0;
		} else if (_files.isFocusControl()) {
			return _files.getSelectionIndex() != -1;
		}
		return false;
	}
	@property
	bool canDoP() {
		return true;
	}
	@property
	bool canDoD() {
		return canDoT;
	}

	override bool openCWXPath(string path, bool shellActivate) {
		return false;
	}
	@property
	override string[] openedCWXPath() {
		return [];
	}
}

version (Windows) {
	private extern (Windows) {
		alias ushort FILEOP_FLAGS;
		const FOF_MULTIDESTFILES = 0x0001;
		const FOF_NOCONFIRMATION = 0x0010;
		const FOF_ALLOWUNDO = 0x0040;
		INT SHFileOperationW(SHFILEOPSTRUCT*);
		const FO_DELETE = 3;
		struct SHFILEOPSTRUCT {
			HWND  hwnd;
			UINT  wFunc;
			LPCWSTR  pFrom;
			LPCWSTR  pTo;
			FILEOP_FLAGS  fFlags;
			BOOL fAnyOperationsAborted;
			LPVOID  hNameMappings;
			LPCWSTR lpszProgressTitle;
		}
	}
}


module cwx.editor.gui.dwt.directorywindow;

import cwx.summary;
import cwx.usecounter;
import cwx.utils;
import cwx.skin;
import cwx.sjis;
import cwx.cab;
import cwx.structs;
import cwx.types;
import cwx.menu;
import cwx.path;
import cwx.imagesize;
import cwx.jpy;

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
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.images;

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

import org.eclipse.swt.all;

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
	import core.stdc.errno;
	import std.c.linux.linux;
	private extern (C) {
		uintptr_t sleep(uintptr_t);
		intptr_t inotify_init();
		intptr_t inotify_add_watch(intptr_t, in char*, uintptr_t);
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
} else { mixin(S_TRACE);
	import std.c.unix.unix;
}

private struct FC {
	string path;
	SysTime time;
	const
	bool opEquals(ref const(FC) fc) { mixin(S_TRACE);
		return path == fc.path && time == fc.time;
	}
	const
	int opCmp(ref const(FC) fc) { mixin(S_TRACE);
		if (time < fc.time) return -1;
		if (time > fc.time) return 1;
		return 0;
	}
	const
	string toString() { mixin(S_TRACE);
		return path;
	}
}

class DirectoryWindow : TopLevelPanel, SashPanel, TCPD {
private:
	class FileNameObj {
		private this () { mixin(S_TRACE);
			this.relPath = toRelPath(this.array);
			this.ext = .extension(this.basename);
			this.extl = .extension(this.basename).toLower();
			this.pathId = toPathId(this.relPath);
			this.dir = isDir(this.array) != 0;
			if (this.dir) { mixin(S_TRACE);
				this.material = false;
			} else { mixin(S_TRACE);
				auto skin = _comm.skin;
				this.material = skin.isMaterial(this.basename, false);
			}
			this.size = getSize(this.array);
		}
		this (string fullPath) { mixin(S_TRACE);
			this.array = fullPath;
			this.basename = baseName(this.array);
			this ();
		}
		this (string parent, string basename) { mixin(S_TRACE);
			this.array = std.path.buildPath(parent, basename);
			this.basename = basename;
			this ();
		}
		string array;
		string basename;
		string relPath;
		string ext;
		string extl;
		PathId pathId;
		bool dir;
		bool material;
		ulong size;
	}
	int comp(string a, string b) { mixin(S_TRACE);
		if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
			return fnncmp(a, b);
		} else { mixin(S_TRACE);
			return fncmp(a, b);
		}
	}

	bool compDirName(string a, string b) { mixin(S_TRACE);
		return comp(a, b) < 0;
	}
	bool compFullPath(string a, string b) { mixin(S_TRACE);
		return compFNameS(baseName(a), baseName(b), isDir(a) != 0, isDir(b) != 0);
	}
	bool compFNameS(string a, string b, bool ad, bool bd) { mixin(S_TRACE);
		if (ad && bd) return comp(a, b) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		return comp(a, b) < 0;
	}
	bool compFName(in FileNameObj a, in FileNameObj b) { mixin(S_TRACE);
		return compFNameS(a.basename, b.basename, a.dir, b.dir);
	}
	bool revCompFName(in FileNameObj a, in FileNameObj b) { mixin(S_TRACE);
		auto ad = a.dir;
		auto bd = b.dir;
		if (ad && bd) return comp(a.basename, b.basename) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		return comp(a.basename, b.basename) > 0;
	}
	bool compFExt(in FileNameObj a, in FileNameObj b) { mixin(S_TRACE);
		auto ad = a.dir;
		auto bd = b.dir;
		if (ad && bd) return comp(a.basename, b.basename) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int r = comp(a.ext, b.ext);
		return r != 0 ? r < 0 : comp(a.basename, b.basename) < 0;
	}
	bool revCompFExt(in FileNameObj a, in FileNameObj b) { mixin(S_TRACE);
		auto ad = a.dir;
		auto bd = b.dir;
		if (ad && bd) return comp(a.basename, b.basename) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int r = comp(a.ext, b.ext);
		return r != 0 ? r > 0 : comp(a.basename, b.basename) < 0;
	}
	bool compFCount(in FileNameObj a, in FileNameObj b) { mixin(S_TRACE);
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
	bool revCompFCount(in FileNameObj a, in FileNameObj b) { mixin(S_TRACE);
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
	FC[] allPaths() { mixin(S_TRACE);
		FC[] fcs;
		if (_summ) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				void list(string path, string relPath) { mixin(S_TRACE);
					FC fc;
					fc.path = relPath;
					if (.isDir(path)) { mixin(S_TRACE);
						fc.time = SysTime.init;
						fcs ~= fc;
						foreach (c; clistdir(path)) { mixin(S_TRACE);
							list(std.path.buildPath(path, c), relPath.buildPath(c));
						}
					} else { mixin(S_TRACE);
						fc.time = timeLastModified(path);
						fcs ~= fc;
					}
				}
				list(_summ.scenarioPath, "");
			} catch (Exception e) {
				debugln(e);
			}
		}
		return fcs.sort;
	}
	FC[] _checkPaths;
	void refCheckPaths() { mixin(S_TRACE);
		if (_summ.useTemp) { mixin(S_TRACE);
	 		_checkPaths = allPaths;
		}
	}

	bool isDef(string p, bool isDir) { mixin(S_TRACE);
		return _summ.isSystemFile(p, isDir) || isIgnore(p);
	}

	bool isIgnore(string p) { mixin(S_TRACE);
		return containsPath(_prop.var.etc.ignorePaths, baseName(p));
	}

	void refreshDirs(string sel) { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		try { mixin(S_TRACE);
			scope (exit) refreshStatusLine();
			if (!_summ) { mixin(S_TRACE);
				_dirs.removeAll();
				return;
			}
			bool[string] expands;
			void exps(TreeItem itm) { mixin(S_TRACE);
				if (itm.getExpanded()) { mixin(S_TRACE);
					expands[(cast(FileNameObj) itm.getData()).array] = true;
				}
				foreach (sub; itm.getItems()) { mixin(S_TRACE);
					exps(sub);
				}
			}
			foreach (itm; _dirs.getItems()) { mixin(S_TRACE);
				exps(itm);
			}
			_dirs.setRedraw(false);
			scope (exit) _dirs.setRedraw(true);
			int hs = _dirs.getHorizontalBar().getSelection();
			auto topItm = _dirs.getTopItem();
			string top = null;
			if (topItm) { mixin(S_TRACE);
				top = (cast(FileNameObj) topItm.getData()).array;
				if (!.exists(top)) top = null;
			}
			TreeItem nTopItm = null;
			_dirs.removeAll();
			if (!addp(_dirs, _summ.scenarioPath, sel ? nabs(sel) : null, top, nTopItm)) { mixin(S_TRACE);
				_dirs.setSelection(_dirs.getItems()[0]);
			}
			if (nTopItm) _dirs.setTopItem(nTopItm);
			void expst(TreeItem itm) { mixin(S_TRACE);
				if (expands.get((cast(FileNameObj)itm.getData()).array, true)) { mixin(S_TRACE);
					itm.setExpanded(true);
				}
				foreach (sub; itm.getItems()) { mixin(S_TRACE);
					expst(sub);
				}
			}
			foreach (itm; _dirs.getItems()) { mixin(S_TRACE);
				expst(itm);
			}
			_dirs.getHorizontalBar().setSelection(hs);
			_dirs.showSelection();
		} catch (Exception e) {
			debugln(e);
		}
	}
	void refreshFiles(string[] sels) { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		try { mixin(S_TRACE);
			scope (exit) refreshStatusLine();
			if (!_summ) { mixin(S_TRACE);
				_files.removeAll();
				return;
			}
			_files.setRedraw(false);
			scope (exit) _files.setRedraw(true);
			scope selset = new HashSet!(string);
			if (sels) { mixin(S_TRACE);
				foreach (path; sels) { mixin(S_TRACE);
					if (.exists(path)) { mixin(S_TRACE);
						selset.add(nabs(path));
					}
				}
			}
			auto selDirs = _dirs.getSelection();
			if (selDirs.length > 0) { mixin(S_TRACE);
				_files.deselectAll();
				_files.removeAll(); // 不要分だけremoveしようとすると Widget is disposed
				auto path = (cast(FileNameObj) selDirs[0].getData()).array;
				FileNameObj[] list;
				foreach (f; clistdir(path)) { mixin(S_TRACE);
					if (_incSearch.match(f)) { mixin(S_TRACE);
						list ~= new FileNameObj(path, f);
					}
				}
				if (_files.getSortColumn() is _sortName.column) { mixin(S_TRACE);
					if (_files.getSortDirection() == SWT.UP) { mixin(S_TRACE);
						list = .sortDlg!(FileNameObj, typeof(&compFName))(list, &compFName);
					} else { mixin(S_TRACE);
						assert (_files.getSortDirection() == SWT.DOWN);
						list = .sortDlg!(FileNameObj, typeof(&revCompFName))(list, &revCompFName);
					}
				} else if (_files.getSortColumn() is _sortExt.column) { mixin(S_TRACE);
					if (_files.getSortDirection() == SWT.UP) { mixin(S_TRACE);
						list = .sortDlg!(FileNameObj, typeof(&compFExt))(list, &compFExt);
					} else { mixin(S_TRACE);
						assert (_files.getSortDirection() == SWT.DOWN);
						list = .sortDlg!(FileNameObj, typeof(&revCompFExt))(list, &revCompFExt);
					}
				} else { mixin(S_TRACE);
					assert (_files.getSortColumn() is _sortCount.column);
					if (_files.getSortDirection() == SWT.UP) { mixin(S_TRACE);
						list = .sortDlg!(FileNameObj, typeof(&compFCount))(list, &compFCount);
					} else { mixin(S_TRACE);
						assert (_files.getSortDirection() == SWT.DOWN);
						list = .sortDlg!(FileNameObj, typeof(&revCompFCount))(list, &revCompFCount);
					}
				}
				int count = 0;
				int oldC = _files.getItemCount();
				bool sp = cast(bool) cfnmatch(nabs(path), nabs(_summ.scenarioPath));
				Skin skin = _comm.skin;
				foreach (p; list) { mixin(S_TRACE);
					if (sp) { mixin(S_TRACE);
						if (isDef(p.array, p.dir)) continue;
					} else { mixin(S_TRACE);
						if (isIgnore(p.array)) continue;
					}
					TableItem itm;
					if (count < oldC) { mixin(S_TRACE);
						itm = _files.getItem(count);
					} else { mixin(S_TRACE);
						itm = new TableItem(_files, SWT.NONE);
					}
					auto img = fimage(skin, p.array, p.dir);
					itm.setImage(0, img);
					string wrapExt(string ext) { mixin(S_TRACE);
						if (!ext.length) return ext;
						if ('.' == ext[0]) return ext[1 .. $];
						return ext;
					}
					if (p.dir) { mixin(S_TRACE);
						itm.setText(0, p.basename);
						itm.setText(1, "");
						itm.setText(2, "");
					} else if (p.material) { mixin(S_TRACE);
						itm.setText(0, stripExtension(p.basename));
						itm.setText(1, wrapExt(p.ext));
						itm.setText(2, to!(string)(_summ.useCounter.path.get(p.pathId)));
					} else { mixin(S_TRACE);
						itm.setText(0, stripExtension(p.basename));
						itm.setText(1, wrapExt(p.ext));
						itm.setText(2, "");
					}
					p.array = nabs(p.array);
					itm.setData(p);
					if (selset.size > 0) { mixin(S_TRACE);
						if (selset.contains(p.array)) { mixin(S_TRACE);
							_files.select(count);
						}
					}
					count++;
				}
				if (count > 0 && !sels) { mixin(S_TRACE);
					_files.setTopIndex(0);
				}
				_files.showSelection();
			} else { mixin(S_TRACE);
				_files.removeAll();
			}
		} catch (Exception e) {
			debugln(e);
		}
	}
	bool addp(T)(T parItm, string path, string sel, string top, ref TreeItem topItm) { mixin(S_TRACE);
		auto itm = new TreeItem(parItm, SWT.NONE);
		auto full = nabs(path);
		if (0 == filenameCharCmp('A', 'a') ? _cuts.contains(.toLower(full)) : _cuts.contains(full)) { mixin(S_TRACE);
			itm.setImage(_sImgFolder);
		} else { mixin(S_TRACE);
			itm.setImage(_prop.images.folder);
		}
		string abs = nabs(_summ.scenarioPath);
		bool sp = cast(bool) cfnmatch(full, abs);
		if (sp) { mixin(S_TRACE);
			itm.setText("Scenario");
		} else { mixin(S_TRACE);
			itm.setText(baseName(path));
		}
		itm.setData(new FileNameObj(full));
		string[] subs;
		foreach (p; clistdir(path)) { mixin(S_TRACE);
			p = std.path.buildPath(path, p);
			if (isDir(p)) subs ~= p;
		}
		subs = .sortDlg!(string)(subs, &compDirName);
		bool s = false;
		foreach (p; subs) { mixin(S_TRACE);
			if (sp) { mixin(S_TRACE);
				if (isDef(p, cast(bool) isDir(p))) continue;
			} else { mixin(S_TRACE);
				if (isIgnore(p)) continue;
			}
			s |= addp(itm, p, sel, top, topItm);
		}
		if (sel) { mixin(S_TRACE);
			auto absp = nabs(path);
			if (cfnmatch(sel, absp)) { mixin(S_TRACE);
				itm.getParent().setSelection(itm);
				s = true;
			}
			if (top && !topItm && cfnmatch(nabs(top), absp)) { mixin(S_TRACE);
				topItm = itm;
			}
		}
		return s;
	}

	private Display _display = null;

	Image fimage(Image img) { mixin(S_TRACE);
		if (img is _prop.images.folder || img is _sImgFolder) { mixin(S_TRACE);
			return _prop.images.folder;
		} else if (img is _prop.images.cards || img is _sImgCards) { mixin(S_TRACE);
			return _prop.images.cards;
		} else if (img is _prop.images.backs || img is _sImgBacks) { mixin(S_TRACE);
			return _prop.images.backs;
		} else if (img is _prop.images.bgm || img is _sImgBgm) { mixin(S_TRACE);
			return _prop.images.bgm;
		} else if (img is _prop.images.se || img is _sImgSe) { mixin(S_TRACE);
			return _prop.images.se;
		} else if (img is _prop.images.text || img is _sImgText) { mixin(S_TRACE);
			return _prop.images.text;
		} else if (img is _prop.images.unknown || img is _sImgUnknown) { mixin(S_TRACE);
			return _prop.images.unknown;
		}
		assert (0);
	}
	Image sfimage(Image img) { mixin(S_TRACE);
		if (img is _prop.images.folder || img is _sImgFolder) { mixin(S_TRACE);
			return _sImgFolder;
		} else if (img is _prop.images.cards || img is _sImgCards) { mixin(S_TRACE);
			return _sImgCards;
		} else if (img is _prop.images.backs || img is _sImgBacks) { mixin(S_TRACE);
			return _sImgBacks;
		} else if (img is _prop.images.bgm || img is _sImgBgm) { mixin(S_TRACE);
			return _sImgBgm;
		} else if (img is _prop.images.se || img is _sImgSe) { mixin(S_TRACE);
			return _sImgSe;
		} else if (img is _prop.images.text || img is _sImgText) { mixin(S_TRACE);
			return _sImgText;
		} else if (img is _prop.images.unknown || img is _sImgUnknown) { mixin(S_TRACE);
			return _sImgUnknown;
		}
		assert (0);
	}
	Image fimage(Skin skin, string file) { mixin(S_TRACE);
		if (skin.isCardImage(file, false)) { mixin(S_TRACE);
			return _prop.images.cards;
		} else if (skin.isBgImage(file)) { mixin(S_TRACE);
			return _prop.images.backs;
		} else if (skin.isBGM(file) && !.cfnmatch(file.extension(), ".wav")) { mixin(S_TRACE);
			return _prop.images.bgm;
		} else if (skin.isSE(file)) { mixin(S_TRACE);
			return _prop.images.se;
		} else if (cfnmatch(.extension(file), ".txt")) { mixin(S_TRACE);
			return _prop.images.text;
		} else { mixin(S_TRACE);
			return _prop.images.unknown;
		}
	}
	Image fimage(Skin skin, string file, bool dir) { mixin(S_TRACE);
		if (isCutted(file)) { mixin(S_TRACE);
			return sfimage(file);
		}
		if (dir) { mixin(S_TRACE);
			return _prop.images.folder;
		} else { mixin(S_TRACE);
			return fimage(skin, file);
		}
	}
	Image fimage(string file) { mixin(S_TRACE);
		if (isCutted(file)) { mixin(S_TRACE);
			return sfimage(file);
		}
		if (.isDir(file)) { mixin(S_TRACE);
			return _prop.images.folder;
		} else { mixin(S_TRACE);
			return fimage(_comm.skin, file);
		}
	}
	Image sfimage(string file) { mixin(S_TRACE);
		auto skin = _comm.skin;
		if (.isDir(file)) { mixin(S_TRACE);
			return _sImgFolder;
		} else if (skin.isCardImage(file, false)) { mixin(S_TRACE);
			return _sImgCards;
		} else if (skin.isBgImage(file)) { mixin(S_TRACE);
			return _sImgBacks;
		} else if (skin.isBGM(file)) { mixin(S_TRACE);
			return _sImgBgm;
		} else if (skin.isSE(file)) { mixin(S_TRACE);
			return _sImgSe;
		} else if (cfnmatch(.extension(file), ".txt")) { mixin(S_TRACE);
			return _sImgText;
		} else { mixin(S_TRACE);
			return _sImgUnknown;
		}
	}
	private bool isCutted(string file) { mixin(S_TRACE);
		static if (0 == filenameCharCmp('A', 'a')) {
			file = .toLower(file);
			file = file.nabs();
			return _cuts.contains(file);
		} else { mixin(S_TRACE);
			return _cuts.contains(nabs(file));
		}
	}
	string toRelPath(string file) { mixin(S_TRACE);
		file = nabs(file);
		auto sc = nabs(_summ.scenarioPath);
		return file.length == sc.length ? "" : file[(sc ~ dirSeparator).length .. $];
	}
	class DirsSelection : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			refreshFiles([]);
			_comm.refreshToolBar();
		}
	}
	class FilesSelection : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			filesSelected();
		}
	}
	void filesSelected() { mixin(S_TRACE);
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	class FileSelect : KeyAdapter, MouseListener {
	private:
		void select() { mixin(S_TRACE);
			int index = _files.getSelectionIndex();
			if (index >= 0) { mixin(S_TRACE);
				auto path = (cast(FileNameObj) _files.getItem(index).getData()).array;
				if (.isDir(path)) { mixin(S_TRACE);
					auto sels = _dirs.getSelection();
					if (!sels.length) return;
					foreach (itm; sels[0].getItems()) { mixin(S_TRACE);
						if (cfnmatch((cast(FileNameObj) itm.getData()).array, path)) { mixin(S_TRACE);
							_dirs.setSelection(itm);
							refreshFiles([]);
							return;
						}
					}
					assert (0);
				} else { mixin(S_TRACE);
					Program.launch(path);
				}
			}
		}
	public override:
		void mouseUp(MouseEvent e) {}
		void mouseDown(MouseEvent e) {}
		void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if ((cast(Control) e.widget).isFocusControl() && e.button == 1) { mixin(S_TRACE);
				select();
			}
		}
		void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (e.character == SWT.CR) { mixin(S_TRACE);
				select();
			}
		}
	}

	class FilesDrag(C) : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			auto itms
				= (cast(C) (cast(DragSource) e.getSource()).getControl()).getSelection();
			if (itms.length == 0) return;
			string[] data;
			data.length = itms.length;
			foreach (i, itm; itms) { mixin(S_TRACE);
				data[i] = (cast(FileNameObj) itm.getData()).array;
			}
			e.data = new FileNames(data);
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (e.detail != DND.DROP_NONE) { mixin(S_TRACE);
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
		void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			static if (is (C == Table)) {
				e.detail = DND.DROP_MOVE;
			} else static if (is (C == Tree)) {
				e.detail = e.item ? DND.DROP_MOVE : DND.DROP_NONE;
			} else { mixin(S_TRACE);
				static assert (0);
			}
		}
		void drop(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = DND.DROP_NONE;
			auto files = cast(FileNames) e.data;
			bool fromOut;
			static if (is (C == Table)) {
				auto toparP = e.item ? (cast(FileNameObj) e.item.getData()).array : selDirPath;
			} else static if (is (C == Tree)) {
				auto toparP = (cast(FileNameObj) e.item.getData()).array;
			} else { mixin(S_TRACE);
				static assert (0);
			}
			if (!toparP) return;
			string topar = .isDir(toparP) ? toparP : dirName(toparP);
			if (__paste(topar, files, true, fromOut)) { mixin(S_TRACE);
				e.detail = fromOut ? DND.DROP_COPY : DND.DROP_NONE;
				clearCut();
			}
		}
	}
	bool __paste(string targ, FileNames files, bool move, out bool fromOut) { mixin(S_TRACE);
		if (files && files.array.length > 0) { mixin(S_TRACE);
			pauseTrace();
			scope (exit) resumeTrace();
			fromOut = false;
			scope pfull = nabs(_summ.scenarioPath);
			bool top = cast(bool) cfnmatch(nabs(targ), pfull);
			try { mixin(S_TRACE);
				string[] paths;
				string[] exists;
				string[] copys;
				foreach (file; files.array) { mixin(S_TRACE);
					file = nabs(file);
					if (hasPath(file, targ)) { mixin(S_TRACE);
						// 自分の上位のディレクトリを持ってこようとした
						continue;
					}
					auto to = std.path.buildPath(targ, baseName(file));
					if (top) { mixin(S_TRACE);
						if (isDef(to, cast(bool) isDir(file))) continue;
					} else { mixin(S_TRACE);
						if (isIgnore(to)) continue;
					}
					if (.exists(to)) { mixin(S_TRACE);
						bool tisdir = cast(bool) isDir(to);
						if (tisdir ==  cast(bool) isDir(file)) { mixin(S_TRACE);
							auto par = dirName(file);
							if (cfnmatch(par, targ)) { mixin(S_TRACE);
								if (!move && !(0 == filenameCharCmp('A', 'a')
										? _cuts.contains(.toLower(file)) : _cuts.contains(file))) { mixin(S_TRACE);
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
				if (exists.length > 0) { mixin(S_TRACE);
					auto dlg = new MessageBox
						(_win.getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
					dlg.setText(_prop.msgs.dlgTitQuestion);
					if (1 == exists.length) { mixin(S_TRACE);
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropOverWriteFile, exists[0]));
					} else { mixin(S_TRACE);
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropOverWriteFiles, exists.length));
					}
					int r = dlg.open();
					if (r == SWT.YES) { mixin(S_TRACE);
						over = true;
					} else if (r == SWT.CANCEL) { mixin(S_TRACE);
						return false;
					}
				}
				paths = .sortDlg(paths, &compFullPath);
				string dir = null;
				string[] selfs;
				foreach (file; paths) { mixin(S_TRACE);
					bool fout = !(0 == filenameCharCmp('A', 'a')
						? _cuts.contains(.toLower(file))
						: _cuts.contains(file))
						&& (!move || !hasPath(pfull, file));
					fromOut |= fout;
					void copy(string parent, string from) { mixin(S_TRACE);
						auto to = std.path.buildPath(parent, baseName(from));
						if (.exists(to) && cast(bool) isDir(to) == cast(bool) isDir(from) && !over) { mixin(S_TRACE);
							return;
						}
						if (isDir(from)) { mixin(S_TRACE);
							if (!.exists(to)) std.file.mkdir(to);
							foreach (child; clistdir(from)) { mixin(S_TRACE);
								copy(to, std.path.buildPath(from, child));
							}
							if (!dir) dir = to;
							if (!fout) { mixin(S_TRACE);
								delAll(from);
								string p1 = toRelPath(from);
								string p2 = toRelPath(to);
								_comm.refPath.call(p1, p2, true);
							}
						} else { mixin(S_TRACE);
							if (fout) { mixin(S_TRACE);
								.copy(from, to);
							} else { mixin(S_TRACE);
								string p1 = toRelPath(from);
								string p2 = toRelPath(to);
								if (_summ.useCounter.get(toPathId(p1)) > 0) { mixin(S_TRACE);
									_summ.useCounter.change(toPathId(p1), toPathId(p2), true);
									_summ.changed();
								}
								_comm.refPath.call(p1, p2, false);
								std.file.rename(from, to);
								foreach (ref jpy; _jpyData) { mixin(S_TRACE);
									jpy.renameFile(from, to);
								}
							}
						}
						if (cfnmatch(parent, targ)) selfs ~= to;
					}
					copy(targ, file);
				}
				foreach (file; copys) { mixin(S_TRACE);
					void renameCopy(string parent, string from) { mixin(S_TRACE);
						bool isdir = cast(bool) isDir(from);
						string to = std.path.buildPath(parent, baseName(from));
						to = createNewFileName(to, isdir);
						if (isdir) { mixin(S_TRACE);
							std.file.mkdir(to);
							foreach (child; clistdir(from)) { mixin(S_TRACE);
								renameCopy(to, std.path.buildPath(from, child));
							}
							if (!dir) dir = to;
						} else { mixin(S_TRACE);
							std.file.copy(from, to);
						}
						if (cfnmatch(parent, targ)) selfs ~= to;
					}
					renameCopy(targ, file);
				}
				_comm.refPaths.call(this, toRelPath(selDirPath));

				// Jpy1ファイルの内容を更新
				updateJpy1Files();
				updateJpy1List();

				if (dir) { mixin(S_TRACE);
					refreshDirs(.exists(targ) ? targ : dir);
					foreach (itm; _dirs.getSelection()) itm.setExpanded(true);
				}
				refreshFiles(selfs);
				return true;
			} catch (Exception e) {
				debugln(e);
			}
		}
		return false;
	}
	@property
	string selDirPath() { mixin(S_TRACE);
		if (_win && !_win.isDisposed()) { mixin(S_TRACE);
			auto sels = _dirs.getSelection();
			if (sels.length) { mixin(S_TRACE);
				return (cast(FileNameObj) sels[0].getData()).array;
			}
		}
		return null;
	}
	@property
	string[] selFiles() { mixin(S_TRACE);
		string[] r;
		if (_win && !_win.isDisposed()) { mixin(S_TRACE);
			auto sels = _files.getSelection();
			r.length = sels.length;
			foreach (i, itm; sels) { mixin(S_TRACE);
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
	IncSearch _incSearch;

	HashSet!(string) _cuts;
	Image _sImgFolder, _sImgCards, _sImgBacks, _sImgBgm, _sImgSe, _sImgText, _sImgUnknown;

	Props _prop;
	Summary _summ = null;
	Jpy1[] _jpyData;

	Commons _comm;

	Preview _preview;
	FileNameObj _previewO = null;
	PileImage _previewI = null;
	void closePreview() { mixin(S_TRACE);
		if (_previewI) { mixin(S_TRACE);
			_preview.close();
			_previewO = null;
			_previewI.dispose();
		}
	}
	void previewTrigger(int x, int y) { mixin(S_TRACE);
		auto itm = _files.getItem(new Point(x, y));
		if (!itm) { mixin(S_TRACE);
			closePreview();
			return;
		}
		assert (cast(FileNameObj)itm.getData() !is null);
		auto path = cast(FileNameObj)itm.getData();
		if (path is _previewO) { mixin(S_TRACE);
			return;
		}
		closePreview();
		_previewO = path;
		if (path.dir) return;
		if (!path.array.isImageExt()) return;
		auto imgData = previewImage(path.array);
		if (!imgData) return;
		_previewI = new PileImage(imgData, imgData.width, imgData.height);
		_previewI.createImage();

		auto b = itm.getBounds();
		auto p = _files.toDisplay(b.x, b.y + b.height);
		_preview.image(_previewI, p.x, p.y, b.height);
		_preview.show();
	}
	class ClosePreview : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			closePreview();
		}
	}
	class PreviewTrigger : MouseTrackAdapter, MouseMoveListener {
		override void mouseExit(MouseEvent e) { mixin(S_TRACE);
			closePreview();
		}
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			previewTrigger(e.x, e.y);
		}
	}
	ImageData previewImage(string path) { mixin(S_TRACE);
		auto data = loadImage(_prop, _comm.skin, _summ, path, false);
		if (data.width == 1 && data.height == 1 && data.transparentPixel == data.getPixel(0, 0)) { mixin(S_TRACE);
			return null;
		}
		return data;
	}

	string pathRename(T)(T itm, string newName) { mixin(S_TRACE);
		clearCut();
		auto path = (cast(FileNameObj) itm.getData()).array;
		string frp = toRelPath(path);
		string frd = nabs(path);
		newName = std.array.replace(newName, dirSeparator, "");
		static if (altDirSeparator.length) {
			newName = std.array.replace(newName, altDirSeparator, "");
		}
		auto to = std.path.buildPath(dirName(path), newName);
		bool isdir = cast(bool) .isDir(path);
		if (!isdir && .extension(path).length > 0) { mixin(S_TRACE);
			to = to ~ .extension(path);
		}
		if (.exists(to) && cast(bool) .isDir(to) == cast(bool) .isDir(path)) return null;
		try { mixin(S_TRACE);
			std.file.rename(path, to);
			auto p1 = nabs(path);
			auto p2 = nabs(to);
			foreach (ref jpy; _jpyData) { mixin(S_TRACE);
				jpy.renameFile(p1, p2);
			}
		} catch (Exception e) {
			// 不正な名前
			debugln(e);
			return null;
		}
		void updatePaths(string p1, string p2) { mixin(S_TRACE);
			if (_summ.useCounter.get(toPathId(p1)) == 0) return;
			_summ.useCounter.change(toPathId(p1), toPathId(p2));
			_summ.changed();
		}
		string trp = toRelPath(to);
		if (isdir) { mixin(S_TRACE);
			string tod = nabs(to);
			void pchange(string file) { mixin(S_TRACE);
				auto oldP = frd ~ nabs(file)[tod.length .. $];
				if (.exists(file) && .isDir(file)) { mixin(S_TRACE);
					foreach (c; clistdir(file)) { mixin(S_TRACE);
						pchange(std.path.buildPath(file, c));
					}
				} else { mixin(S_TRACE);
					string p1 = toRelPath(oldP);
					string p2 = toRelPath(file);
					updatePaths(p1, p2);
				}
			}
			foreach (c; clistdir(to)) { mixin(S_TRACE);
				pchange(std.path.buildPath(to, c));
			}
		} else { mixin(S_TRACE);
			string p1 = frp;
			string p2 = toRelPath(to);
			updatePaths(p1, p2);
			_comm.refPath.call(p1, p2, false);
		}
		// Jpy1ファイルの内容を更新
		updateJpy1Files();

		itm.setData(new FileNameObj(to));
		static if (is (T == TreeItem)) {
			itm.setText(baseName(stripExtension(to)));
		} else static if (is (T == TableItem)) {
			itm.setText(0, .isDir(to) ? baseName(to) : baseName(stripExtension(to)));
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_comm.refPath.call(frp, trp, isdir);
		_comm.refUseCount.call();
		return to;
	}
	void dirsEditEnd(TreeItem itm, Control c) { mixin(S_TRACE);
		string text = (cast(Text) c).getText();
		if (!text) text = "";
		if (text.length == 0) return;
		auto from = (cast(FileNameObj) itm.getData()).array;
		string frd = nabs(from);
		auto to = pathRename(itm, text);
		if (to) { mixin(S_TRACE);
			string tod = nabs(to);
			void drename(TreeItem itm) { mixin(S_TRACE);
				itm.setData(new FileNameObj(tod ~ (cast(FileNameObj) itm.getData()).array[frd.length .. $]));
				foreach (c; itm.getItems()) { mixin(S_TRACE);
					drename(c);
				}
			}
			foreach (cc; itm.getItems()) { mixin(S_TRACE);
				drename(cc);
			}
			foreach (t; _files.getItems()) { mixin(S_TRACE);
				t.setData(new FileNameObj(std.path.buildPath(tod, (cast(FileNameObj) t.getData()).basename)));
			}
		}
	}
	Control dirsCreateEditor(TreeItem itm) { mixin(S_TRACE);
		return itm.getParentItem() ? createTextEditor(_comm, _prop, _dirs, itm.getText()) : null;
	}
	void filesEditEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		if (newText.length == 0) return;
		assert (column == 0);
		if (pathRename(itm, newText)) { mixin(S_TRACE);
			refreshDirs(selDirPath);
		}
	}
	void __refPaths(Object sender, string parent) { mixin(S_TRACE);
		if (sender !is this) { mixin(S_TRACE);
			refreshDirs(selDirPath);
			if (selDirPath && cfnmatch(toRelPath(selDirPath), parent)) { mixin(S_TRACE);
				refreshFiles(selFiles);
			}
		}
	}

	void __refreshUseCount() { mixin(S_TRACE);
		foreach (itm; _files.getItems()) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				auto file = cast(FileNameObj) itm.getData();
				if (!.exists(file.array) || !file.material) continue;
				auto c = _summ.useCounter.path.get(file.pathId);
				itm.setText(2, to!(string)(c));
			} catch (Exception e) {
				debugln(e);
			}
		}
	}
	void __refreshTitle() { mixin(S_TRACE);
		_comm.setTitle(_win, title);
	}
	void __refresh() { mixin(S_TRACE);
		updateJpy1List();
		refreshDirs(selDirPath);
		refreshFiles(selFiles);
	}
	void updateJpy1List() { mixin(S_TRACE);
		if (!_summ) return;
		foreach (ref jpy; _jpyData) { mixin(S_TRACE);
			jpy.removeUseCounter();
		}
		_jpyData.length = 0;
		auto sPath = _summ.scenarioPath;
		foreach (string file; sPath.dirEntries(SpanMode.depth)) { mixin(S_TRACE);
			if (!cfnmatch(file.extension(), ".jpy1")) continue;
			try { mixin(S_TRACE);
				_jpyData ~= Jpy1.load(_prop.parent, sPath, file);
				_jpyData[$-1].setUseCounter(_summ.useCounter);
			} catch (EffectBoosterError e) {
				debug {
					foreach (err; e.errors) { mixin(S_TRACE);
						debugln(.tryFormat(_prop.msgs.jpyError, err.msg, file, err.line));
					}
				}
			} catch (Exception e) {
				debugln(e);
			}
		}
	}
	void __delPaths(Object sender) { mixin(S_TRACE);
		if (sender !is this) { mixin(S_TRACE);
			refreshDirs(selDirPath);
			refreshFiles(selFiles);
		}
	}
	void saveScenario() { mixin(S_TRACE);
		_comm.save.call(dlgParShl.getShell());
	}
	void incSearch() { mixin(S_TRACE);
		.forceFocus(_files, true);
		_incSearch.startIncSearch();
	}

	void selectAll() { mixin(S_TRACE);
		foreach (i; 0 .. _files.getItemCount()) { mixin(S_TRACE);
			_files.select(i);
		}
		filesSelected();
	}

	void createFilesMenu() { mixin(S_TRACE);
		if (_files.getMenu()) _files.getMenu().dispose();
		auto menu = new Menu(_win.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &incSearch, () => _summ !is null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.NewDir, &createDirFiles, () => _summ !is null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CreateArchive, &createArchive, &canCreateArchive);
		new MenuItem(menu, SWT.SEPARATOR);
		foreach (i, tool; _prop.var.etc.outerTools) { mixin(S_TRACE);
			new Exec(this, menu, tool, i);
		}
		if (_prop.var.etc.outerTools.length > 0) new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, () => _files.getItemCount() && _files.getSelectionCount() != _files.getItemCount());
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.FindID, &replaceID, &canReplaceID);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CopyFilePath, &copyFilePath, () => _files.getSelectionIndex() != -1);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.DelNotUsedFile, &deleteUnuse, &canDeleteUnuse);

		_files.setMenu(menu);
	}
	string createDir() { mixin(S_TRACE);
		auto dir = selDirPath;
		if (!dir) return null;
		string fp;
		createNewName(_prop.msgs.newFolder, (string name) { mixin(S_TRACE);
			string p = std.path.buildPath(dir, name);
			fp = p;
			if (!.exists(fp)) { mixin(S_TRACE);
				std.file.mkdir(fp);
				fp = nabs(fp);
				if (_summ.useTemp) _summ.changed();
				return true;
			} else { mixin(S_TRACE);
				return false;
			}
		}, false);
		return fp;
	}
	void createDirDirs() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) { mixin(S_TRACE);
			_comm.openDirWin(false);
		}
		auto fp = createDir();
		if (!fp) return;
		refreshDirs(fp);
		refreshFiles(null);
		.forceFocus(_dirs, true);
		_dirsEdit.startEdit();
	}
	void createDirFiles() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) { mixin(S_TRACE);
			_comm.openDirWin(false);
		}
		auto fp = createDir();
		if (!fp) return;
		auto files = selFiles ~ fp;
		refreshDirs(selDirPath);
		refreshFiles(files);
		foreach (itm; _files.getItems()) { mixin(S_TRACE);
			if (cfnmatch((cast(FileNameObj) itm.getData()).array, fp)) { mixin(S_TRACE);
				.forceFocus(_files, true);
				_filesEdit.startEdit(itm);
				break;
			}
		}
	}
	void __replace(string sel) { mixin(S_TRACE);
		if (!_summ || !_win || _win.isDisposed()) return;
		_comm.replacePath(sel, true);
	}

	class SClose : ShellAdapter {
		override void shellClosed(ShellEvent e) { mixin(S_TRACE);
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
			if (_files.getSortColumn() is _sortName.column) { mixin(S_TRACE);
				_prop.var.etc.filesSortColumn = 0;
			} else if (_files.getSortColumn() is _sortExt.column) { mixin(S_TRACE);
				_prop.var.etc.filesSortColumn = 1;
			} else if (_files.getSortColumn() is _sortCount.column) { mixin(S_TRACE);
				_prop.var.etc.filesSortColumn = 2;
			} else { mixin(S_TRACE);
				_prop.var.etc.filesSortColumn = -1;
			}
		}
	}
	class FDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			closePreview();
			_preview.dispose();
			_comm.refOuterTools.remove(&createFilesMenu);
		}
	}
	class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
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
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_prop.var.etc.directorySashL = _sash.getWeights()[0];
			_prop.var.etc.directorySashR = _sash.getWeights()[1];
			_prop.var.etc.directorySashV = (_sash.getStyle() & SWT.VERTICAL) != 0;
			_win = null;
		}
	}
	private class RefreshThr : Runnable {
		private bool _onRefresh = false;
		override void run() { mixin(S_TRACE);
			// syncExecを使うとたまに止まるのでここで制御する
			if (_onRefresh) return;
			_onRefresh = true;
			scope (exit) _onRefresh = false;
			if (_stopTrace) return;
			if (_dirsEdit.isEditing() || _filesEdit.isEditing()) return;
			try { mixin(S_TRACE);
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
		private void closeTraceHandle() { mixin(S_TRACE);
			synchronized (_refreshThr) closeTraceHandleImpl();
		}
		private void closeTraceHandleImpl() { mixin(S_TRACE);
			if (_traceHandle !is INVALID_HANDLE_VALUE) FindCloseChangeNotification(_traceHandle);
			_traceHandle = INVALID_HANDLE_VALUE;
		}
	} else version (linux) {
		private int _traceHandle = -1;
		private void closeTraceHandle() { mixin(S_TRACE);
			synchronized (_refreshThr) closeTraceHandleImpl();
		}
		private void closeTraceHandleImpl() { mixin(S_TRACE);
			if (_traceHandle !is -1) close(_traceHandle);
			_traceHandle = -1;
		}
	} else { mixin(S_TRACE);
		private void closeTraceHandle() {}
	}
	private void trace() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Start Trace Thread");
			}
			Summary summ = null;
			void sleep() { mixin(S_TRACE);
				version (Windows) {
					Sleep(1000); // 1sec
				} else { mixin(S_TRACE);
					.sleep(1); // 1sec
				}
			}
			@property
			bool canDoChk() { mixin(S_TRACE);
				return summ && !_display.isDisposed() && _prop.var.etc.traceDirectories && _win;
			}
			version (Windows) {
				bool setup() { mixin(S_TRACE);
					synchronized (_refreshThr) { mixin(S_TRACE);
						closeTraceHandleImpl();
						if (summ) { mixin(S_TRACE);
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
				void next() { mixin(S_TRACE);
					synchronized (_refreshThr) { mixin(S_TRACE);
						if (_traceHandle !is INVALID_HANDLE_VALUE) { mixin(S_TRACE);
							if (!FindNextChangeNotification(_traceHandle)) { mixin(S_TRACE);
								debugln("FindNextChangeNotification failed: ", GetLastError());
							}
						}
					}
				}
				while (_onTrace && _display && !_display.isDisposed()) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						if (_stopTrace) { mixin(S_TRACE);
							sleep();
							continue;
						}
						if (summ !is _summ) { mixin(S_TRACE);
							summ = _summ;
							if (!setup()) { mixin(S_TRACE);
								debugln("FindFirstChangeNotification failed: ", GetLastError());
								continue;
							}
						}
						if (!canDoChk) { mixin(S_TRACE);
							sleep();
							continue;
						}
						switch (WaitForSingleObject(_traceHandle, 1000)) {
						case WAIT_TIMEOUT: { mixin(S_TRACE);
							next();
						} break;
						case WAIT_ABANDONED: { mixin(S_TRACE);
							break;
						}
						case WAIT_OBJECT_0: { mixin(S_TRACE);
							if (!canDoChk) continue;
							_display.asyncExec(_refreshThr);
							next();
						} break;
						case WAIT_FAILED: { mixin(S_TRACE);
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
				bool setup() { mixin(S_TRACE);
					synchronized (_refreshThr) { mixin(S_TRACE);
						closeTraceHandleImpl();
						_traceHandle = inotify_init();
						if (_traceHandle is -1) return false;
						void put(string path) { mixin(S_TRACE);
							foreach (file; clistdir(path)) { mixin(S_TRACE);
								file = std.path.buildPath(path, file);
								if (isDir(file)) { mixin(S_TRACE);
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
				while (_onTrace && _display && !_display.isDisposed()) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						if (_stopTrace) { mixin(S_TRACE);
							sleep();
							continue;
						}
						if (summ !is _summ) { mixin(S_TRACE);
							summ = _summ;
							if (!setup()) { mixin(S_TRACE);
								debugln("inotify_init() failed");
								continue;
							}
						}
						if (!canDoChk) { mixin(S_TRACE);
							sleep();
							continue;
						}
						byte[inotify_event.sizeof * 1024] buf;
						int len;
						synchronized (_refreshThr) { mixin(S_TRACE);
							timeval tout;
							tout.tv_sec = 1;
							tout.tv_usec = 0;
							fd_set fdr;
							FD_ZERO(&fdr);
							FD_SET(_traceHandle, &fdr);
							auto selret = .select(_traceHandle + 1, &fdr, null, null, &tout);
							if (-1 == selret) break;
							if (0 == selret) { mixin(S_TRACE);
								sleep();
								continue;
							}
							if (!FD_ISSET(_traceHandle, &fdr)) { mixin(S_TRACE);
								sleep();
								continue;
							}
							len = std.c.linux.linux.read(_traceHandle, buf.ptr, buf.sizeof);
						}
						if (-1 == len) break;
						if (0 == len) { mixin(S_TRACE);
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
			} else { mixin(S_TRACE);
				d_time[string] dirTimes;
				void setup() { mixin(S_TRACE);
					d_time[string] times;
					if (summ) { mixin(S_TRACE);
						void refr(string path) { mixin(S_TRACE);
							if (summ.isSystemFile(path)
									|| containsPath(_prop.var.etc.ignorePaths, baseName(path))) { mixin(S_TRACE);
								return;
							}
							times[path] = lastModified(path);
							foreach (sub; clistdir(path)) { mixin(S_TRACE);
								sub = std.path.buildPath(path, sub);
								if (isDir(sub)) refr(sub);
							}
						}
						refr(nabs(summ.scenarioPath));
					}
					dirTimes = times;
				}
				while (_onTrace && _display && !_display.isDisposed()) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						if (_stopTrace) { mixin(S_TRACE);
							sleep();
							continue;
						}
						if (summ !is _summ) { mixin(S_TRACE);
							summ = _summ;
							setup();
						}
						sleep();
						if (!canDoChk) continue;
						bool chk(string path) { mixin(S_TRACE);
							if (summ.isSystemFile(path)
									|| containsPath(_prop.var.etc.ignorePaths, baseName(path))) { mixin(S_TRACE);
								return false;
							}
							if (dirTimes[path] != lastModified(path)) return true;
							foreach (sub; clistdir(path)) { mixin(S_TRACE);
								sub = std.path.buildPath(path, sub);
								if (isDir(sub) && chk(sub)) return true;
							}
							return false;
						}
						if (chk(nabs(summ.scenarioPath))) { mixin(S_TRACE);
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
	void refreshStatusLine() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		ulong size;
		foreach (itm; _files.getItems()) { mixin(S_TRACE);
			auto d = cast(FileNameObj) itm.getData();
			size += d.size;
		}
		string sizeKB = formatNum(size / 1024) ~ " KB";
		int fileCount = _files.getItemCount();
		int selCount = selFiles.length;
		string s;
		if (0 < selCount) { mixin(S_TRACE);
			s = .tryFormat(_prop.msgs.dirStatusSel, fileCount, sizeKB, selCount);
		} else { mixin(S_TRACE);
			s = .tryFormat(_prop.msgs.dirStatus, fileCount, sizeKB);
		}
		_comm.setStatusLine(_win, s, _dirs.isFocusControl() || _files.isFocusControl());
	}
	@property
	Shell dlgParShl() { mixin(S_TRACE);
		if (_win && !_win.isDisposed()) return _win.getShell();
		return _comm.mainWin.shell.getShell();
	}
public:
	this (Commons comm, Props prop, Composite parent) { mixin(S_TRACE);
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
	void reconstruct(Composite parent) { mixin(S_TRACE);
		if (_win && !_win.isDisposed()) return;
		construct(parent);
		if (_summ) refresh(_summ);
	}
	private void construct(Composite parent) { mixin(S_TRACE);
		_cuts = new typeof(_cuts);
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		Composite contPane;
		if (parShl) { mixin(S_TRACE);
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImage(_prop.images.app);
			shell.addShellListener(new SClose);
			_win = shell;
			contPane = _sbshl.contentPane;
		} else { mixin(S_TRACE);
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
		if (shell) { mixin(S_TRACE);
			auto bar = new Menu(shell, SWT.BAR);

			auto mf = createMenu(_comm, bar, MenuID.File);
			createMenuItem(_comm, mf, MenuID.OpenDir, &openDirectory, &canOpenDirectory);
			new MenuItem(mf, SWT.SEPARATOR);
			createMenuItem(_comm, mf, MenuID.CloseWin, &shell.close, null);

			auto me = createMenu(_comm, bar, MenuID.Edit);
			createMenuItem(_comm, me, MenuID.FindID, &replaceID, &canReplaceID);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.NewDir, &createNewFolder, &canCreateNewFolder);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.CreateArchive, &createArchive, &canCreateArchive);
			new MenuItem(me, SWT.SEPARATOR);
			appendMenuTCPD(_comm, me, this, true, true, true, true, true);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.DelNotUsedFile, &deleteUnuse, &canDeleteUnuse);

			auto mv = createMenu(_comm, bar, MenuID.View);
			createMenuItem(_comm, mv, MenuID.Refresh, &__refresh, () => _summ !is null);
			new MenuItem(mv, SWT.SEPARATOR);
			createMenuItem(_comm, mv, MenuID.ChangeVH, &changeVHSide, null);

			shell.setMenuBar(bar);
		} else { mixin(S_TRACE);
			appendMenuTCPD(_comm, this, this, true, true, true, true, true);
			putMenuAction(MenuID.Refresh, &__refresh, () => _summ !is null);
			putMenuAction(MenuID.OpenDir, &openDirectory, &canOpenDirectory);
			putMenuAction(MenuID.NewDir, &createNewFolder, &canCreateNewFolder);
			putMenuAction(MenuID.CreateArchive, &createArchive, &canCreateArchive);
			putMenuAction(MenuID.ChangeVH, &changeVHSide, null);
			putMenuAction(MenuID.DelNotUsedFile, &deleteUnuse, &canDeleteUnuse);
			putMenuAction(MenuID.FindID, &replaceID, &canReplaceID);
		}
		if (shell) { mixin(S_TRACE);
			auto bar = new ToolBar(contPane, SWT.FLAT);
			_comm.put(bar);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

			createToolItem(_comm, bar, MenuID.OpenDir, &openDirectory, &canOpenDirectory);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.Refresh, &__refresh, () => _summ !is null);
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
		initTree(_comm, _dirs, false);
		{ mixin(S_TRACE);
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
			appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.DelNotUsedFile, &deleteUnuse, &canDeleteUnuse);
			_dirs.setMenu(menu);
		}
		auto fComp = new Composite(_sash, SWT.NONE);
		fComp.setLayout(new FillLayout);
		_files = new Table(fComp, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER | SWT.VIRTUAL);
		{ mixin(S_TRACE);
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
			auto st = _sortName;
			int sortColumn = _prop.var.etc.filesSortColumn;
			switch (sortColumn) {
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
			int sortDir = _prop.var.etc.filesSortDirection;
			switch (sortDir) {
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

			_preview = new Preview(_prop, _files.getShell());
			auto closePreview = new ClosePreview;
			_files.getVerticalBar().addSelectionListener(closePreview);
			_files.getHorizontalBar().addSelectionListener(closePreview);
			auto prevTrig = new PreviewTrigger;
			_files.addMouseTrackListener(prevTrig);
			_files.addMouseMoveListener(prevTrig);
		}
		_sash.setWeights([_prop.var.etc.directorySashL, _prop.var.etc.directorySashR]);
		_sdl = new SDListener;
		_sash.addDisposeListener(_sdl);
		if (shell) { mixin(S_TRACE);
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
		_incSearch = new IncSearch(_comm, _files);
		_incSearch.modEvent ~= {refreshFiles(null);};
	}
	private class SCListener : ControlAdapter {
		override void controlMoved(ControlEvent e) { mixin(S_TRACE);
			saveWin();
		}
		override void controlResized(ControlEvent e) { mixin(S_TRACE);
			saveWin();
		}
	}
	private void saveWin() { mixin(S_TRACE);
		auto win = cast(Shell) _win;
		if (win) { mixin(S_TRACE);
			if (!win.getMaximized() && !win.getMinimized()) { mixin(S_TRACE);
				_prop.var.dirWin.width = win.getSize().x;
				_prop.var.dirWin.height = win.getSize().y;
				_prop.var.dirWin.x = win.getBounds().x - win.getParent().getBounds().x;
				_prop.var.dirWin.y = win.getBounds().y - win.getParent().getBounds().y;
			}
			_prop.var.dirWin.maximized = win.getMaximized();
			_prop.var.dirWin.minimized = win.getMinimized();
		}
	}
	void removeFiles(in string[] file, bool recycle) { mixin(S_TRACE);
		pauseTrace();
		scope (exit) resumeTrace();
		version (Windows) {
			wstring targ;
			foreach (i, f; file) { mixin(S_TRACE);
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
		} else { mixin(S_TRACE);
			foreach (f; file) { mixin(S_TRACE);
				delAll(f);
			}
		}
	}
	bool canDeleteUnuse() { mixin(S_TRACE);
		return _summ !is null;
	}
	void deleteUnuse(SelectionEvent se) { mixin(S_TRACE);
		if (!_summ) return;
		auto files = _summ.notUsedFiles(_comm.skin, _prop.var.etc.ignorePaths, _prop.var.etc.logicalSort);
		if (!files.length) return;
		foreach (ref file; files) { mixin(S_TRACE);
			file = _summ.scenarioPath.buildPath(file);
		}
		bool recycle = (se.stateMask & SWT.SHIFT) == 0;
		auto shl = dlgParShl.getShell();
		auto dlg = new MessageBox(shl, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
		version (Windows) {
			if (recycle) { mixin(S_TRACE);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteRecycleUnuse, files.length));
			} else { mixin(S_TRACE);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteUnuse, files.length));
			}
		} else { mixin(S_TRACE);
			dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteUnuse, files.length));
		}
		dlg.setText(_prop.msgs.dlgTitQuestion);
		if (SWT.YES == dlg.open()) { mixin(S_TRACE);
			removeFiles(files, recycle);
			_comm.refreshToolBar();
		}
	}

	@property
	override
	Composite shell() {return _win;}

	@property
	override
	Image image() { mixin(S_TRACE);
		return _prop.images.menu(MenuID.FileView);
	}
	@property
	override
	string title() { mixin(S_TRACE);
		auto shl = cast(Shell) _win;
		if (shl) { mixin(S_TRACE);
			return .tryFormat(_prop.msgs.dirWindowName, _summ.scenarioName, _summ.scenarioPath);
		}
		return _prop.msgs.dirTabName;
	}
	@property
	override
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	void copyFilePath() { mixin(S_TRACE);
		if (!_summ) return;
		int sel = _files.getSelectionIndex();
		if (-1 == sel) return;
		auto fno = cast(FileNameObj) _files.getItem(sel).getData();
		_comm.clipboard.setContents([new PathString(encodePath(fno.relPath))],
			[TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	void replace() { mixin(S_TRACE);
		if (!_summ) return;
		if (_files.getSelectionIndex() >= 0) { mixin(S_TRACE);
			__replace((cast(FileNameObj) _files.getItem(_files.getSelectionIndex()).getData()).relPath);
		} else { mixin(S_TRACE);
			__replace(null);
		}
	}

	void replaceID() {
		int index = _files.getSelectionIndex();
		if (index <= -1) return;
		_comm.replacePath((cast(FileNameObj)_files.getItem(index).getData()).relPath, true);
	}
	@property
	bool canReplaceID() {
		int index = _files.getSelectionIndex();
		return 0 <= index;
	}

	private void changeVHSide() { mixin(S_TRACE);
		_sash.removeDisposeListener(_sdl);
		_sash = .changeVHSide(_sash);
		_sash.addDisposeListener(_sdl);
	}

	void stopTrace() { mixin(S_TRACE);
		closeTraceHandle();
		_stopTrace = true;
	}
	void resumeTrace() {_stopTrace = false;}
	void pauseTrace() {_stopTrace = true;}

	void refresh(Summary summ) { mixin(S_TRACE);
		foreach (ref jpy; _jpyData) { mixin(S_TRACE);
			jpy.removeUseCounter();
		}
		_jpyData.length = 0;

		_summ = summ;

		updateJpy1List();
		refCheckPaths();
		if (_win && !_win.isDisposed()) { mixin(S_TRACE);
			refreshDirs(std.path.buildPath(_summ.scenarioPath, _comm.skin.materialPath));
			refreshFiles(null);
			auto root = _dirs.getItem(0);
			root.setExpanded(true);
			if (!_dirs.getSelection().length) { mixin(S_TRACE);
				_dirs.setSelection([root]);
				refreshFiles(null);
			}
			_dirs.showSelection();
			__refreshTitle();
			_comm.refreshToolBar();
		}
	}

	@property
	bool isChanged() { mixin(S_TRACE);
		if (_summ.useTemp) { mixin(S_TRACE);
			return _summ.isChanged || _checkPaths != allPaths;
		}
		return _summ.isChanged;
	}

	private void clearCut() { mixin(S_TRACE);
		_cuts.clear();
		void titm(TreeItem itm) { mixin(S_TRACE);
			if (itm.getImage() is _sImgFolder) { mixin(S_TRACE);
				itm.setImage(_prop.images.folder);
			}
			foreach (child; itm.getItems()) { mixin(S_TRACE);
				titm(child);
			}
		}
		foreach (itm; _dirs.getItems()) { mixin(S_TRACE);
			titm(itm);
		}
		foreach (itm; _files.getItems()) { mixin(S_TRACE);
			auto img = fimage(itm.getImage());
			if (itm.getImage() !is img) { mixin(S_TRACE);
				itm.setImage(img);
			}
		}
	}

	@property
	bool canOpenDirectory() { mixin(S_TRACE);
		return _summ !is null;
	}
	void openDirectory() { mixin(S_TRACE);
		auto dir = selDirPath;
		if (dir) openFolder(dir);
	}
	@property
	bool canCreateNewFolder() { mixin(S_TRACE);
		return _summ !is null;
	}
	void createNewFolder() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) { mixin(S_TRACE);
			_comm.openDirWin(false);
		}
		if (_files.isFocusControl()) { mixin(S_TRACE);
			createDirFiles();
		} else { mixin(S_TRACE);
			createDirDirs();
		}
	}

	private bool selectImpl(T)(T tree, string path) { mixin(S_TRACE);
		foreach (itm; tree.getItems()) { mixin(S_TRACE);
			auto fno = cast(FileNameObj) itm.getData();
			if (cfnmatch(fno.array, path)) { mixin(S_TRACE);
				_dirs.select(itm);
				refreshFiles(selFiles);
				_comm.refreshToolBar();
				return true;
			}
			if (selectImpl(itm, path)) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	bool select(string path) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (!path.isAbsolute()) { mixin(S_TRACE);
				path = _summ.scenarioPath.buildPath(path);
			}
			if (.exists(path)) { mixin(S_TRACE);
				path = nabs(path);
				auto isdir = .isDir(path);
				string dir = isdir ? path : dirName(path);
				bool r = selectImpl(_dirs, dir);
				if (r) { mixin(S_TRACE);
					_dirs.showSelection();
					if (!isdir) { mixin(S_TRACE);
						foreach (i, itm; _files.getItems()) { mixin(S_TRACE);
							auto fno = cast(FileNameObj) itm.getData();
							if (cfnmatch(fno.array, path)) { mixin(S_TRACE);
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

	void quitTrace() { mixin(S_TRACE);
		if (!_traceThr) return;
		_onTrace = false;
		try { mixin(S_TRACE);
			_traceThr.join();
		} catch (Throwable e) {
			debugln(e);
		}
	}

	/// シナリオ内にあるJpy1ファイルの内容の上書きが必要であれば更新する。
	void updateJpy1Files() { mixin(S_TRACE);
		foreach (ref jpy; _jpyData) { mixin(S_TRACE);
			jpy.updateJpy1File(_prop.parent, _prop.var.etc.autoUpdateJpy1File);
		}
	}

	@property
	bool canCreateArchive() { mixin(S_TRACE);
		return _summ !is null;
	}
	void createArchive() { mixin(S_TRACE);
		if (!_summ) return;
		auto shl = dlgParShl.getShell();
		if (_comm.isChanged) { mixin(S_TRACE);
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
		if (canUncab) { mixin(S_TRACE);
			dlg.setFilterExtensions(["*.zip", "*.cab", "*.wsn"]);
			dlg.setFilterNames([_prop.msgs.filterDescZip, _prop.msgs.filterDescCab, _prop.msgs.filterDescWsn]);
			zip = 0;
			cab = 1;
			wsn = 2;
		} else { mixin(S_TRACE);
			dlg.setFilterExtensions(["*.zip", "*.wsn"]);
			dlg.setFilterNames([_prop.msgs.filterDescZip, _prop.msgs.filterDescWsn]);
			zip = 0;
			cab = -1;
			wsn = 1;
		}
		dlg.setText(_prop.msgs.dlgTitCreateArchive);
		if (_prop.var.etc.archivePath.length) { mixin(S_TRACE);
			dlg.setFilterPath(_prop.var.etc.archivePath);
		} else { mixin(S_TRACE);
			dlg.setFilterPath(getcwd());
		}
		string filter = _prop.var.etc.selectedArchiveFilter;
		switch (filter) {
		case ".cab":
			if (!canUncab) { mixin(S_TRACE);
				goto default;
			}
			dlg.setFilterIndex(cab);
			dlg.setFileName(setExtension(_summ.scenarioName, ".cab"));
			break;
		case ".wsn":
			dlg.setFilterIndex(wsn);
			dlg.setFileName(setExtension(_summ.scenarioName, ".wsn"));
			break;
		default:
			dlg.setFilterIndex(zip);
			dlg.setFileName(setExtension(_summ.scenarioName, ".zip"));
			break;
		}
		dlg.setOverwrite(true);
		string fname = dlg.open();
		if (!fname) return;

		try { mixin(S_TRACE);
			switch (dlg.getFilterIndex()) {
			case cab:
				synchronized (_comm.saveSync) { mixin(S_TRACE);
					_summ.createCab(fname, _prop.var.etc.ignorePaths);
				}
				_prop.var.etc.selectedArchiveFilter = ".cab";
				break;
			case wsn:
				synchronized (_comm.saveSync) { mixin(S_TRACE);
					_summ.createZip(fname, _prop.var.etc.ignorePaths, false);
				}
				_prop.var.etc.selectedArchiveFilter = ".wsn";
				break;
			default:
				synchronized (_comm.saveSync) { mixin(S_TRACE);
					_summ.createZip(fname, _prop.var.etc.ignorePaths, true);
				}
				_prop.var.etc.selectedArchiveFilter = ".zip";
				break;
			}
			_prop.var.etc.archivePath = dlg.getFilterPath();
		} catch (Exception e) {
			debugln(e);
			_comm.setStatusLine(_win, _prop.msgs.failedCreateArchive);
		}
	}

	override void cut(SelectionEvent se) { mixin(S_TRACE);
		if (!canDoTCPD) return;
		if (_dirs.isFocusControl()) { mixin(S_TRACE);
			auto sels = _dirs.getSelection();
			if (!sels.length) return;
			if (!sels[0].getParentItem()) return;
		}
		if (__copy()) { mixin(S_TRACE);
			if (_dirs.isFocusControl()) { mixin(S_TRACE);
				auto sels = _dirs.getSelection();
				if (!sels.length) return;
				auto dir = selDirPath;
				sels[0].setImage(sfimage(dir));
				static if (0 == filenameCharCmp('A', 'a')) {
					_cuts.add(.toLower(nabs(dir)));
				} else { mixin(S_TRACE);
					_cuts.add(nabs(dir));
				}
			} else { mixin(S_TRACE);
				assert (_files.isFocusControl());
				bool isdir = false;
				foreach (itm; _files.getSelection()) { mixin(S_TRACE);
					auto p = (cast(FileNameObj) itm.getData()).array;
					itm.setImage(sfimage(itm.getImage()));
					static if (0 == filenameCharCmp('A', 'a')) {
						_cuts.add(.toLower(nabs(p)));
					} else { mixin(S_TRACE);
						_cuts.add(nabs(p));
					}
					if (!isdir && .isDir(p)) isdir = true;
				}
				if (isdir) refreshDirs(selDirPath);
			}
			_comm.refreshToolBar();
		}
	}
	override void copy(SelectionEvent se) { mixin(S_TRACE);
		if (!canDoTCPD) return;
		__copy();
	}
	private string[] copyImpl() { mixin(S_TRACE);
		if (_dirs.isFocusControl()) { mixin(S_TRACE);
			auto dir = selDirPath;
			if (dir) { mixin(S_TRACE);
				return [nabs(dir)];
			}
		} else { mixin(S_TRACE);
			assert (_files.isFocusControl());
			auto files = selFiles;
			if (files.length > 0) { mixin(S_TRACE);
				string[] arr;
				arr.length = files.length;
				foreach (i, f; files) { mixin(S_TRACE);
					arr[i] = nabs(f);
				}
				return arr;
			}
		}
		return [];
	}
	private bool __copy() { mixin(S_TRACE);
		clearCut();
		auto arr = copyImpl();
		if (arr.length) { mixin(S_TRACE);
			_comm.clipboard.setContents([new FileNames(arr)],
				[FileTransfer.getInstance()]);
			_comm.refreshToolBar();
			return true;
		}
		return false;
	}
	override void paste(SelectionEvent se) { mixin(S_TRACE);
		if (!canDoTCPD) return;
		auto c = _comm.clipboard.getContents(FileTransfer.getInstance());
		if (c && cast(FileNames) c) { mixin(S_TRACE);
			pasteImpl((cast(FileNames) c).array);
		}
	}
	private void pasteImpl(string[] array) { mixin(S_TRACE);
		if (!canDoTCPD) return;
		if (!array.length) return;
		bool fromOut;
		if (__paste(selDirPath, new FileNames(array), false, fromOut)) { mixin(S_TRACE);
			clearCut();
			if (_summ.useTemp) _summ.changed();
			.forceFocus(_files, false);
			_comm.refreshToolBar();
		}
	}
	override void del(SelectionEvent se) { mixin(S_TRACE);
		if (!canDoTCPD) return;
		if (_dirs.isFocusControl()) { mixin(S_TRACE);
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
		foreach (i, f; file) { mixin(S_TRACE);
			fileNames[i] = nabs(f);
		}
		bool recycle = (se.stateMask & SWT.SHIFT) == 0;
		if (_dirs.isFocusControl()) { mixin(S_TRACE);
			if (!dir) return;
			version (Windows) {
				if (recycle) { mixin(S_TRACE);
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFileRecycle, nabs(dir)));
				} else { mixin(S_TRACE);
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFile, nabs(dir)));
				}
			} else { mixin(S_TRACE);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFile, nabs(dir)));
			}
			if (SWT.OK == dlg.open()) { mixin(S_TRACE);
				removeFiles([nabs(dir)], recycle);
			} else { mixin(S_TRACE);
				return;
			}
		} else { mixin(S_TRACE);
			assert (_files.isFocusControl());
			if (file.length == 0) return;
			version (Windows) {
				if (1 == fileNames.length) { mixin(S_TRACE);
					if (recycle) { mixin(S_TRACE);
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFileRecycle, fileNames[0]));
					} else { mixin(S_TRACE);
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFile, fileNames[0]));
					}
				} else { mixin(S_TRACE);
					if (recycle) { mixin(S_TRACE);
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFilesRecycle, fileNames.length));
					} else { mixin(S_TRACE);
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFiles, fileNames.length));
					}
				}
			} else { mixin(S_TRACE);
				if (1 == fileNames.length) { mixin(S_TRACE);
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFile, fileNames[0]));
				} else { mixin(S_TRACE);
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDeleteFiles, fileNames.length));
				}
			}
			if (SWT.OK == dlg.open()) { mixin(S_TRACE);
				removeFiles(file, recycle);
			} else { mixin(S_TRACE);
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
	override void clone(SelectionEvent se) { mixin(S_TRACE);
		auto files = copyImpl();
		if (!files.length) return;
		if (_dirs.isFocusControl()) { mixin(S_TRACE);
			auto parItm = _dirs.getSelection()[0].getParentItem();
			if (parItm) { mixin(S_TRACE);
				select((cast(FileNameObj) parItm.getData()).array);
			}
		}
		pasteImpl(files);
	}
	@property
	override bool canDoTCPD() { mixin(S_TRACE);
		return _dirs.isFocusControl() || _files.isFocusControl();
	}
	@property
	bool canDoT() { mixin(S_TRACE);
		if (!_summ) return false;
		if (_dirs.isFocusControl()) { mixin(S_TRACE);
			auto sels = _dirs.getSelection();
			return sels.length > 0 && sels[0].getParentItem();
		} else if (_files.isFocusControl()) { mixin(S_TRACE);
			return _files.getSelectionIndex() != -1;
		}
		return false;
	}
	@property
	bool canDoC() { mixin(S_TRACE);
		if (!_summ) return false;
		if (_dirs.isFocusControl()) { mixin(S_TRACE);
			return _dirs.getSelection().length > 0;
		} else if (_files.isFocusControl()) { mixin(S_TRACE);
			return _files.getSelectionIndex() != -1;
		}
		return false;
	}
	@property
	bool canDoP() { mixin(S_TRACE);
		return _summ !is null && CBisFile(_comm.clipboard);
	}
	@property
	bool canDoD() { mixin(S_TRACE);
		return canDoT;
	}
	@property
	bool canDoClone() { mixin(S_TRACE);
		if (!_summ) return false;
		if (_dirs.isFocusControl()) { mixin(S_TRACE);
			auto sels = _dirs.getSelection();
			return sels.length > 0 && sels[0].getParentItem();
		} else if (_files.isFocusControl()) { mixin(S_TRACE);
			return _files.getSelectionIndex() != -1;
		}
		return false;
	}

	override bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		switch (cate) {
		case "fileview":
			.forceFocus(_files, shellActivate);
			return true;
		default:
			return false;
		}
	}
	@property
	override string[] openedCWXPath() { mixin(S_TRACE);
		return ["fileview"];
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
version (Windows) {
	extern (Windows) {
		void PathRemoveArgsW(LPWSTR);
		void PathUnquoteSpacesW(LPWSTR);
	}
}

class Exec {
	private DirectoryWindow _dirWin;
	private OuterTool _tool;
	private void run() { mixin(S_TRACE);
		string file = "";
		string[] sf = _dirWin.selFiles;
		foreach (i, f; sf) { mixin(S_TRACE);
			file ~= `"` ~ f ~ `"`;
			if (i + 1 < sf.length) file ~= " ";
		}
		string sp = _dirWin._summ ? _dirWin._summ.scenarioPath : std.file.getcwd();
		auto cwd = std.file.getcwd();
		string wd = OuterTool.parse(_tool.workDir, file, sp);
		if (wd.length > 0) { mixin(S_TRACE);
			if (!isAbsolute(wd)) { mixin(S_TRACE);
				wd = std.path.buildPath(std.path.dirName(_dirWin._prop.parent.appPath), wd);
			}
		} else { mixin(S_TRACE);
			wd = dirName(_dirWin._prop.parent.appPath);
		}
		auto cmd = OuterTool.parse(_tool.command, file, sp);
		if (!exec(cmd, wd)) { mixin(S_TRACE);
			MessageBox.showWarning
				(.tryFormat(_dirWin._prop.msgs.errorExec, _tool.name),
				_dirWin._prop.msgs.dlgTitWarning, _dirWin._win.getShell());
		}
	}
	this (DirectoryWindow dirWin, Menu menu, OuterTool tool, int index) { mixin(S_TRACE);
		auto display = menu.getDisplay();
		auto icon = dirWin._prop.images.menu(MenuID.OuterTools);
		string name = MenuProps.buildMenu(tool.name, tool.mnemonic, tool.hotkey, false);
		version (Windows) {
			auto mi = createMenuItem2(dirWin._comm, menu, name, icon, &run, null);

			// loadIcon()は低速のため、メニューを開いた際に呼ぶようにする
			bool rmv = false;
			MenuAdapter mShown;
			mShown = new class MenuAdapter {
				override void menuShown(MenuEvent e) { mixin(S_TRACE);
					auto com = toUTF16(tool.command);
					auto wcom = new wchar[com.length + 1];
					wcom[0 .. com.length] = com[];
					wcom[$ - 1] = '\0';
					PathRemoveArgsW(wcom.ptr);
					PathUnquoteSpacesW(wcom.ptr);
					com = wcom[0 .. std.algorithm.countUntil(wcom, '\0')].idup;
					if (com.length) { mixin(S_TRACE);
						auto thr = new core.thread.Thread({ mixin(S_TRACE);
							auto exeIcon = loadIcon(to!string(com), 16, 16, (void delegate() dlg) { mixin(S_TRACE);
								display.syncExec(new class Runnable {
									void run() { mixin(S_TRACE);
										dlg();
									}
								});
							});
							if (exeIcon) { mixin(S_TRACE);
								display.syncExec(new class Runnable {
									void run() { mixin(S_TRACE);
										if (mi.isDisposed()) return;
										auto img = new Image(mi.getDisplay(), exeIcon);
										listener(mi, SWT.Dispose, { mixin(S_TRACE);
											img.dispose();
										});
										mi.setImage(img);
									}
								});
							}
						});
						thr.start();
					}
					menu.removeMenuListener(mShown);
					rmv = true;
				}
			};
			menu.addMenuListener(mShown);
			mi.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					if (!rmv) menu.removeMenuListener(mShown);
				}
			});
		} else { mixin(S_TRACE);
			createMenuItem2(dirWin._comm, menu, name, icon, &run, null);
		}
		_dirWin = dirWin;
		_tool = tool;
	}
}

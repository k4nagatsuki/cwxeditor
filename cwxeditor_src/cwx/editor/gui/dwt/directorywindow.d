
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
import cwx.msgutils;
import cwx.textholder;
import cwx.warning;

import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.images;

import core.thread;
import core.sync.mutex;

import std.algorithm : countUntil;
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
alias org.eclipse.swt.widgets.MessageBox.MessageBox DWTMessageBox;

import java.lang.all;

version (Windows) {
	import core.sys.windows.windows;
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
	import core.sys.linux.sys.inotify;
	import core.sys.posix.unistd;
	import core.sys.posix.sys.time;
	import core.sys.posix.sys.socket;
	private extern (C) {
		c_uint sleep(c_uint);
		c_int inotify_init();
		c_int inotify_add_watch(int, in char*, c_int);
		const IN_NONBLOCK = 0x4000;
		const IN_MODIFY = 0x0002;
		const IN_ATTRIB = 0x0004;
		const IN_MOVED_FROM = 0x0040;
		const IN_MOVED_TO = 0x0080;
		const IN_CREATE = 0x0100;
		const IN_DELETE = 0x0200;
		const IN_DELETE_SELF = 0x0400;
		struct inotify_event {
			c_int wd;
			c_uint mask;
			c_uint cookie;
			c_uint len;
			char* name;
		};
	}
} else { mixin(S_TRACE);
	import core.sys.unix.unix;
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
		auto c = cmp(path, fc.path);
		if (c != 0) return c;
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
		int ac = _summ.useCounter.path.get(toUCPath(a));
		int bc = _summ.useCounter.path.get(toUCPath(b));
		int r = ac - bc;
		return r != 0 ? r < 0 : compFName(a, b);
	}
	bool revCompFCount(in FileNameObj a, in FileNameObj b) { mixin(S_TRACE);
		auto ad = !a.material;
		auto bd = !b.material;
		if (ad && bd) return compFExt(a, b);
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int ac = _summ.useCounter.path.get(toUCPath(a));
		int bc = _summ.useCounter.path.get(toUCPath(b));
		int r = ac - bc;
		return r != 0 ? r > 0 : compFName(a, b);
	}
	PathId toUCPath(in FileNameObj a) { mixin(S_TRACE);
		PathId aPathId = a.pathId;
		if (_summ && !_summ.legacy && _summ.loadScaledImage) { mixin(S_TRACE);
			if (auto nsp = (cast(string)aPathId).noScaledPath) { mixin(S_TRACE);
				if (nsp.length) aPathId = toPathId(nsp);
			}
		}
		return aPathId;
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
			printStackTrace();
			debugln(e);
		}
	}
	void refreshFiles(string[] sels) { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		try { mixin(S_TRACE);
			scope (exit) refreshStatusLine();
			_hasFile = false;
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
				auto path = (cast(FileNameObj)selDirs[0].getData()).array;
				FileNameObj[] list;
				foreach (f; clistdir(path)) { mixin(S_TRACE);
					if (_summ.isSystemFile(f)) continue;
					_hasFile = true;
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
						itm.setText(2, to!(string)(_summ.useCounter.path.get(toUCPath(p))));
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
			printStackTrace();
			debugln(e);
		}
	}
	void updateIcons() { mixin(S_TRACE);
		auto skin = _comm.skin;
		foreach (itm; _files.getItems()) {
			auto p = cast(FileNameObj)itm.getData();
			assert (p !is null);
			auto img = fimage(skin, p.array, p.dir);
			itm.setImage(0, img);
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
			if (_summ.isSystemFile(p)) continue;
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
		} else if (img is _prop.images.warning || img is _sImgWarning) { mixin(S_TRACE);
			return _prop.images.warning;
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
		} else if (img is _prop.images.warning || img is _sImgWarning) { mixin(S_TRACE);
			return _sImgWarning;
		}
		assert (0);
	}
	Image fimage(Skin skin, string file) { mixin(S_TRACE);
		if (hasWarning(file)) { mixin(S_TRACE);
			return _prop.images.warning;
		} else if (isCard(skin, file)) { mixin(S_TRACE);
			return _prop.images.cards;
		} else if (skin.isBgImage(file)) { mixin(S_TRACE);
			return _prop.images.backs;
		} else if (skin.isBGM(file) && !.cfnmatch(file.extension(), ".wav")) { mixin(S_TRACE);
			return _prop.images.bgm;
		} else if (skin.isSE(file)) { mixin(S_TRACE);
			return _prop.images.se;
		} else { mixin(S_TRACE);
			foreach (txtExt; _prop.var.etc.plainTextFileExtensions) { mixin(S_TRACE);
				auto ext = file.extension();
				if (.cfnmatch(ext, txtExt)) { mixin(S_TRACE);
					return _prop.images.text;
				}
			}
		}
		return _prop.images.unknown;
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
		} else if (hasWarning(file)) { mixin(S_TRACE);
			return _sImgWarning;
		} else if (isCard(skin, file)) { mixin(S_TRACE);
			return _sImgCards;
		} else if (skin.isBgImage(file)) { mixin(S_TRACE);
			return _sImgBacks;
		} else if (skin.isBGM(file)) { mixin(S_TRACE);
			return _sImgBgm;
		} else if (skin.isSE(file)) { mixin(S_TRACE);
			return _sImgSe;
		} else if (cfnmatch(.extension(file), ".txt") || cfnmatch(.extension(file), ".ini") || cfnmatch(.extension(file), ".sli")) { mixin(S_TRACE);
			return _sImgText;
		} else { mixin(S_TRACE);
			return _sImgUnknown;
		}
	}
	private bool isCard(Skin skin, string file) { mixin(S_TRACE);
		if (skin.isCardImage(file, false)) return true;
		if (_summ && _summ.loadScaledImage) { mixin(S_TRACE);
			auto file2 = file.noScaledPath;
			return file2 != "" && skin.isCardImage(file2, false);
		}
		return false;
	}
	private bool hasWarning(string file) { mixin(S_TRACE);
		return .sjisWarnings(_prop.parent, _summ, file, "").length || .fileExtensionWarnings(_prop.parent, file).length;
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
			if (.isEnterKey(e.keyCode)) { mixin(S_TRACE);
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
			if (pasteImpl(topar, files, true, fromOut)) { mixin(S_TRACE);
				e.detail = fromOut ? DND.DROP_COPY : DND.DROP_NONE;
				clearCut();
			}
		}
	}
	bool pasteImpl(string targ, FileNames files, bool move, out bool fromOut) { mixin(S_TRACE);
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
					auto dlg = new DWTMessageBox(_win.getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
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
								updatePaths(p1, p2);
								_comm.refPath.call(p1, p2, false);
								std.file.rename(from, to);
								if (_summ) _summ.renameFile(from, to);
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
				if (_summ) { mixin(S_TRACE);
					_summ.updateJpy1Files(_prop.parent, _prop.var.etc.autoUpdateJpy1File, _comm.sync);
					_summ.updateJpy1List(_prop.parent);
				}

				if (dir) { mixin(S_TRACE);
					refreshDirs(.exists(targ) ? targ : dir);
					foreach (itm; _dirs.getSelection()) itm.setExpanded(true);
				}
				refreshFiles(selfs);
				_comm.sync.sync();
				return true;
			} catch (Exception e) {
				printStackTrace();
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

	Composite _win;
	SplitPane _sash;
	Tree _dirs;
	TreeEdit _dirsEdit;
	Table _files;
	bool _hasFile = false;
	TableTextEdit _filesEdit;
	TableSorter!(FileNameObj) _sortName;
	TableSorter!(FileNameObj) _sortExt;
	TableSorter!(FileNameObj) _sortCount;
	IncSearch _incSearch;
	Control _lastFocus = null;

	HashSet!(string) _cuts;
	Image _sImgFolder, _sImgCards, _sImgBacks, _sImgBgm, _sImgSe, _sImgText, _sImgUnknown, _sImgWarning;

	Props _prop;
	Summary _summ = null;

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
		bool transparent;
		auto imgData = previewImage(path.array, transparent);
		if (!imgData) return;
		_previewI = new PileImage(imgData, NORMAL_SCALE, imgData.getWidth(NORMAL_SCALE), imgData.getHeight(NORMAL_SCALE), false);
		_previewI.transparent = transparent;
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
	ImageDataWithScale previewImage(string path, out bool transparent) { mixin(S_TRACE);
		auto mask = _prop.var.etc.maskCardImagePreview && isCard(_comm.skin, path);
		auto data = .loadImage(_prop, _comm.skin, _summ, path, mask);
		transparent = -1 < data.transparentPixel;
		if (data.width == 1 && data.height == 1 && data.transparentPixel == data.getPixel(0, 0)) { mixin(S_TRACE);
			return null;
		}
		return new ImageDataWithScale(data, NORMAL_SCALE);
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
			if (_summ) _summ.renameFile(p1, p2);
		} catch (Exception e) {
			// 不正な名前
			printStackTrace();
			debugln(e);
			return null;
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
		if (_summ) _summ.updateJpy1Files(_prop.parent, _prop.var.etc.autoUpdateJpy1File, _comm.sync);

		itm.setData(new FileNameObj(to));
		static if (is (T == TreeItem)) {
			itm.setText(baseName(stripExtension(to)));
		} else static if (is (T == TableItem)) {
			itm.setText(0, .isDir(to) ? baseName(to) : baseName(stripExtension(to)));
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_comm.sync.sync();
		_comm.refPath.call(frp, trp, isdir);
		_comm.refUseCount.call();
		return to;
	}
	private void updatePaths(string p1, string p2) { mixin(S_TRACE);
		if (_summ.useCounter.get(toPathId(p1)) == 0) return;
		_summ.useCounter.change(toPathId(p1), toPathId(p2));
		_summ.changed();
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
	void refPaths(Object sender, string parent) { mixin(S_TRACE);
		if (sender !is this) { mixin(S_TRACE);
			refreshDirs(selDirPath);
			if (selDirPath && cfnmatch(toRelPath(selDirPath), parent)) { mixin(S_TRACE);
				refreshFiles(selFiles);
			}
		}
	}

	void refreshUseCount() { mixin(S_TRACE);
		auto update = false;
		foreach (itm; _files.getItems()) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				auto file = cast(FileNameObj) itm.getData();
				if (!.exists(file.array) || !file.material) continue;
				auto c = _summ.useCounter.path.get(toUCPath(file));
				auto s = to!(string)(c);
				if (itm.getText(2) != s) { mixin(S_TRACE);
					itm.setText(2, s);
					update = true;
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
		if (update && _files.getSortColumn() is _sortCount.column) { mixin(S_TRACE);
			auto sortDir = _prop.var.etc.filesSortDirection;
			switch (sortDir) {
			case SortDir.Up:
				_sortCount.doSort(SWT.UP);
				break;
			case SortDir.Down:
				_sortCount.doSort(SWT.DOWN);
				break;
			default:
				_sortCount.doSort(SWT.UP);
				break;
			}
		}
	}
	void refreshTitle() { mixin(S_TRACE);
		_comm.setTitle(_win, title);
	}
	void delPaths(Object sender) { mixin(S_TRACE);
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
		createMenuItem(_comm, menu, MenuID.IncSearch, &incSearch, () => _summ !is null && _hasFile);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.NewDir, &createDirFiles, () => _summ !is null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CreateArchive, &createArchive, &canCreateArchive);
		new MenuItem(menu, SWT.SEPARATOR);
		foreach (i, tool; _prop.var.etc.outerTools) { mixin(S_TRACE);
			new Exec(this, menu, tool, cast(int)i);
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
	void replaceImpl(string sel) { mixin(S_TRACE);
		if (!_summ || !_win || _win.isDisposed()) return;
		_comm.replacePath(sel, true);
	}

	void storeSortParams() { mixin(S_TRACE);
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
	class FDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			closePreview();
			_preview.dispose();
			_comm.refOuterTools.remove(&createFilesMenu);
		}
	}
	class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refScenarioName.remove(&refreshTitle);
			_comm.refScenarioPath.remove(&refreshTitle);
			_comm.refUseCount.remove(&refreshUseCount);
			_comm.refPaths.remove(&refPaths);
			_comm.delPaths.remove(&delPaths);
			_comm.replText.remove(&refreshTitle);
			_comm.refIgnorePaths.remove(&refresh);
			_comm.refImageScale.remove(&updateIcons);
			_sImgFolder.dispose();
			_sImgCards.dispose();
			_sImgBacks.dispose();
			_sImgBgm.dispose();
			_sImgSe.dispose();
			_sImgText.dispose();
			_sImgUnknown.dispose();
			_sImgWarning.dispose();
		}
	}
	private SDListener _sdl;
	class SDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
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
			if (!_summ.scenarioPath.exists()) return;
			if (_summ) { mixin(S_TRACE);
				_summ.checkPathsIsChanged(_prop.var.etc.saveInnerImagePath);
			}
			if (_dirsEdit.isEditing() || _filesEdit.isEditing()) return;
			try { mixin(S_TRACE);
				refresh();
				_comm.refPaths.call(this.outer, _summ.scenarioPath);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	private Runnable _refreshThr = null;
	private Mutex _refreshThrMutex = null;
	private core.thread.Thread _traceThr = null;
	private bool _onTrace = true;
	private bool _stopTrace = false;
	version (Windows) {
		private HANDLE _traceHandle = INVALID_HANDLE_VALUE;
		private void closeTraceHandle() { mixin(S_TRACE);
			_refreshThrMutex.lock();
			scope (exit) _refreshThrMutex.unlock();
			closeTraceHandleImpl();
		}
		private void closeTraceHandleImpl() { mixin(S_TRACE);
			if (_traceHandle !is INVALID_HANDLE_VALUE) FindCloseChangeNotification(_traceHandle);
			_traceHandle = INVALID_HANDLE_VALUE;
		}
	} else version (linux) {
		private int _traceHandle = -1;
		private void closeTraceHandle() { mixin(S_TRACE);
			_refreshThrMutex.lock();
			scope (exit) _refreshThrMutex.unlock();
			closeTraceHandleImpl();
		}
		private void closeTraceHandleImpl() { mixin(S_TRACE);
			if (_traceHandle !is -1) .close(_traceHandle);
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
				string sPath;
				bool setup() { mixin(S_TRACE);
					_refreshThrMutex.lock();
					scope (exit) _refreshThrMutex.unlock();
					closeTraceHandleImpl();
					if (summ) { mixin(S_TRACE);
						DWORD fs = FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME | FILE_NOTIFY_CHANGE_LAST_WRITE;
						_traceHandle = FindFirstChangeNotificationW(toUTFz!(wchar*)(sPath), TRUE, fs);
						return _traceHandle !is INVALID_HANDLE_VALUE;
					}
					return true;
				}
				scope (exit) {
					_refreshThrMutex.lock();
					scope (exit) _refreshThrMutex.unlock();
					if (_traceHandle !is INVALID_HANDLE_VALUE) FindCloseChangeNotification(_traceHandle);
				}
				void next() { mixin(S_TRACE);
					_refreshThrMutex.lock();
					scope (exit) _refreshThrMutex.unlock();
					if (_traceHandle !is INVALID_HANDLE_VALUE) { mixin(S_TRACE);
						if (!FindNextChangeNotification(_traceHandle)) { mixin(S_TRACE);
							debugln("FindNextChangeNotification failed: ", GetLastError());
						}
					}
				}
				while (_onTrace && _display && !_display.isDisposed()) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						if (_stopTrace) { mixin(S_TRACE);
							sleep();
							continue;
						}
						if (summ !is _summ || (summ && summ.scenarioPath != sPath)) { mixin(S_TRACE);
							summ = _summ;
							sPath = summ ? summ.scenarioPath : "";
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
							_comm.sync.sync();
							_display.asyncExec(_refreshThr);
							next();
						} break;
						case WAIT_FAILED: { mixin(S_TRACE);
							debugln("WaitForSingleObject failed: ", GetLastError());
						} break;
						default: break;
						}
					} catch (Exception e) {
						printStackTrace();
						debugln("Trace thread: " ~ e.msg);
						break;
					}
				}
			} else version (linux) {
				bool setup() { mixin(S_TRACE);
					_refreshThrMutex.lock();
					scope (exit) _refreshThrMutex.unlock();
					closeTraceHandleImpl();
					_traceHandle = inotify_init();
					if (_traceHandle is -1) return false;
					void put(string path) { mixin(S_TRACE);
						foreach (file; clistdir(path)) { mixin(S_TRACE);
							if (_summ.isSystemFile(file)
									|| containsPath(_prop.var.etc.ignorePaths, baseName(path))) continue;
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
				scope (exit) {
					_refreshThrMutex.lock();
					scope (exit) _refreshThrMutex.unlock();
					if (_traceHandle !is -1) close(_traceHandle);
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
						ptrdiff_t len;
						{ mixin(S_TRACE);
							_refreshThrMutex.lock();
							scope (exit) _refreshThrMutex.unlock();
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
							len = core.sys.posix.unistd.read(_traceHandle, buf.ptr, buf.sizeof);
						}
						if (-1 == len) break;
						if (0 == len) { mixin(S_TRACE);
							sleep();
							continue;
						}
						if (!canDoChk) continue;
						_display.asyncExec(_refreshThr);
					} catch (Exception e) {
						printStackTrace();
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
						printStackTrace();
						debugln("Trace thread: " ~ e.msg);
						break;
					}
				}
			}
			version (Console) {
				debug writeln("Exit Trace Thread");
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	void refreshStatusLine() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		ulong size;
		foreach (itm; _files.getItems()) { mixin(S_TRACE);
			auto d = cast(FileNameObj)itm.getData();
			assert (d !is null);
			size += d.size;
		}
		string sizeKB = formatNum(size / 1024) ~ " KB";
		auto fileCount = _files.getItemCount();
		auto selCount = selFiles.length;
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
		_refreshThrMutex = new Mutex;
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
		Composite contPane;
		_win = new Composite(parent, SWT.NONE);
		contPane = _win;
		_win.setData(new TLPData(this));
		contPane.setLayout(windowGridLayout(1, true));
		_comm.refScenarioName.add(&refreshTitle);
		_comm.refScenarioPath.add(&refreshTitle);
		_comm.refUseCount.add(&refreshUseCount);
		_comm.refPaths.add(&refPaths);
		_comm.delPaths.add(&delPaths);
		_comm.replText.add(&refreshTitle);
		_comm.refIgnorePaths.add(&refresh);
		_comm.refImageScale.add(&updateIcons);
		_sImgFolder = skeletonImage(_prop.images.folder);
		_sImgCards = skeletonImage(_prop.images.cards);
		_sImgBacks = skeletonImage(_prop.images.backs);
		_sImgBgm = skeletonImage(_prop.images.bgm);
		_sImgSe = skeletonImage(_prop.images.se);
		_sImgText = skeletonImage(_prop.images.text);
		_sImgUnknown = skeletonImage(_prop.images.unknown);
		_sImgWarning = skeletonImage(_prop.images.warning);
		_win.addDisposeListener(new DListener);

		appendMenuTCPD(_comm, this, this, true, true, true, true, true);
		putMenuAction(MenuID.Refresh, &refresh, () => _summ !is null);
		putMenuAction(MenuID.OpenDir, &openDirectory, &canOpenDirectory);
		putMenuAction(MenuID.NewDir, &createNewFolder, &canCreateNewFolder);
		putMenuAction(MenuID.CreateArchive, &createArchive, &canCreateArchive);
		putMenuAction(MenuID.ChangeVH, &changeVHSide, null);
		putMenuAction(MenuID.DelNotUsedFile, &deleteUnuse, &canDeleteUnuse);
		putMenuAction(MenuID.FindID, &replaceID, &canReplaceID);
		putMenuAction(MenuID.CopyFilePath, &copyFilePath, () => _files.getSelectionIndex() != -1);

		auto sashPane = new Composite(contPane, SWT.NONE);
		sashPane.setLayout(zeroGridLayout(1, true));
		sashPane.setLayoutData(new GridData(GridData.FILL_BOTH));
		_sash = new SplitPane(sashPane, _prop.var.etc.directorySashV ? SWT.VERTICAL : SWT.HORIZONTAL);
		_sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto dirsComp = new Composite(_sash, SWT.NONE);
		dirsComp.setLayout(new FillLayout);
		_dirs = new Tree(dirsComp, SWT.SINGLE | SWT.BORDER);
		initTree(_comm, _dirs, false);
		.treeWarning(_prop, _dirs, (itm) { mixin(S_TRACE);
			auto fno = cast(FileNameObj)itm.getData();
			assert (fno !is null);
			return .sjisWarnings(_prop.parent, _summ, fno.basename, _prop.msgs.dirName);
		});
		{ mixin(S_TRACE);
			_dirs.addSelectionListener(new DirsSelection);
			.listener(_dirs, SWT.FocusIn, (e) { _lastFocus = cast(Control)e.widget; });
			_lastFocus = _dirs;
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
		_files = .rangeSelectableTable(fComp, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER);
		{ mixin(S_TRACE);
			_files.addSelectionListener(new FilesSelection);
			.listener(_files, SWT.FocusIn, (e) { _lastFocus = cast(Control)e.widget; });
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
			_sortName.sortedEvent ~= &storeSortParams;
			_sortExt.sortedEvent ~= &storeSortParams;
			_sortCount.sortedEvent ~= &storeSortParams;

			_comm.refOuterTools.add(&createFilesMenu);
			_files.addDisposeListener(new FDListener);
			createFilesMenu();

			_preview = new Preview(_prop, _files);
			auto closePreview = new ClosePreview;
			_files.getVerticalBar().addSelectionListener(closePreview);
			_files.getHorizontalBar().addSelectionListener(closePreview);
			auto prevTrig = new PreviewTrigger;
			_files.addMouseTrackListener(prevTrig);
			_files.addMouseMoveListener(prevTrig);
		}
		.setupWeights(_sash, _prop.var.etc.directorySashL, _prop.var.etc.directorySashR);
		_sdl = new SDListener;
		_sash.addDisposeListener(_sdl);

		_incSearch = new IncSearch(_comm, sashPane, () => _summ && _hasFile);
		_incSearch.modEvent ~= { refreshFiles(null); };
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
			ope.hwnd = cast(HANDLE)shell.handle;
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
		auto dlg = new DWTMessageBox(shl, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
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
		return _prop.msgs.dirTabName;
	}
	@property
	override
	void delegate(string) statusText() {return null;}

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
			replaceImpl((cast(FileNameObj) _files.getItem(_files.getSelectionIndex()).getData()).relPath);
		} else { mixin(S_TRACE);
			replaceImpl(null);
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
		.setupWeights(_sash, _prop.var.etc.directorySashL, _prop.var.etc.directorySashR);
		_sash.addDisposeListener(_sdl);
		_prop.var.etc.directorySashV = (_sash.getStyle() & SWT.VERTICAL) != 0;
	}

	void stopTrace() { mixin(S_TRACE);
		closeTraceHandle();
		_stopTrace = true;
	}
	void resumeTrace() { _stopTrace = false; }
	void pauseTrace() { _stopTrace = true; }

	void refresh() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		if (_summ) _summ.updateJpy1List(_prop.parent);
		refreshDirs(selDirPath);
		refreshFiles(selFiles);
	}
	void refresh(Summary summ) { mixin(S_TRACE);
		_summ = summ;
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
			refreshTitle();
			_comm.refreshToolBar();
		}
	}

	@property
	bool isChanged() { mixin(S_TRACE);
		if (!_summ) return false;
		if (!_summ.scenarioPath.exists()) return false;
		if (!_summ.isChanged) _summ.checkPathsIsChanged(_prop.var.etc.saveInnerImagePath);
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
		if (_lastFocus is _files) { mixin(S_TRACE);
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
	bool select(string path, bool deselectEtc) { mixin(S_TRACE);
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
								if (deselectEtc) _files.deselectAll();
								_files.select(cast(int)i);
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
			printStackTrace();
			debugln(e);
		}
		return false;
	}

	void quitTrace() { mixin(S_TRACE);
		_onTrace = false;
		if (!_traceThr) return;
		try { mixin(S_TRACE);
			_traceThr.join(false);
		} catch (Throwable e) {
			printStackTrace();
			debugln(e);
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
			auto dlg = new DWTMessageBox(shl, SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
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
			if (_summ.legacy) { mixin(S_TRACE);
				dlg.setFilterExtensions(["*.zip", "*.cab"]);
				dlg.setFilterNames([_prop.msgs.filterDescZip, _prop.msgs.filterDescCab]);
				zip = 0;
				cab = 1;
				wsn = -1;
			} else { mixin(S_TRACE);
				dlg.setFilterExtensions(["*.zip", "*.cab", "*.wsn"]);
				dlg.setFilterNames([_prop.msgs.filterDescZip, _prop.msgs.filterDescCab, _prop.msgs.filterDescWsn]);
				zip = 0;
				cab = 1;
				wsn = 2;
			}
		} else { mixin(S_TRACE);
			if (_summ.legacy) { mixin(S_TRACE);
				dlg.setFilterExtensions(["*.zip"]);
				dlg.setFilterNames([_prop.msgs.filterDescZip]);
				zip = 0;
				cab = -1;
				wsn = -1;
			} else { mixin(S_TRACE);
				dlg.setFilterExtensions(["*.zip", "*.wsn"]);
				dlg.setFilterNames([_prop.msgs.filterDescZip, _prop.msgs.filterDescWsn]);
				zip = 0;
				cab = -1;
				wsn = 1;
			}
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
			auto fi = dlg.getFilterIndex();
			if (fi == cab) { mixin(S_TRACE);
				_comm.saveSync.lock();
				scope (exit) _comm.saveSync.unlock();
				_summ.createCab(fname, _prop.var.etc.ignorePaths);
				_prop.var.etc.selectedArchiveFilter = ".cab";
			} else if (fi == wsn) { mixin(S_TRACE);
				_comm.saveSync.lock();
				scope (exit) _comm.saveSync.unlock();
				_summ.createZip(fname, _prop.var.etc.ignorePaths, false, _comm.sync);
				_prop.var.etc.selectedArchiveFilter = ".wsn";
			} else { mixin(S_TRACE);
				_comm.saveSync.lock();
				scope (exit) _comm.saveSync.unlock();
				_summ.createZip(fname, _prop.var.etc.ignorePaths, true, _comm.sync);
				_prop.var.etc.selectedArchiveFilter = ".zip";
			}
			_prop.var.etc.archivePath = dlg.getFilterPath();
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			_comm.setStatusLine(_win, _prop.msgs.failedCreateArchive);
		}
	}

	override void cut(SelectionEvent se) { mixin(S_TRACE);
		if (!canDoTCPD) return;
		if (_lastFocus is _dirs) { mixin(S_TRACE);
			auto sels = _dirs.getSelection();
			if (!sels.length) return;
			if (!sels[0].getParentItem()) return;
		}
		if (copy2()) { mixin(S_TRACE);
			if (_lastFocus is _dirs) { mixin(S_TRACE);
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
				assert (_lastFocus is _files);
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
		copy2();
	}
	private string[] copyImpl() { mixin(S_TRACE);
		if (_lastFocus is _dirs) { mixin(S_TRACE);
			auto dir = selDirPath;
			if (dir) { mixin(S_TRACE);
				return [nabs(dir)];
			}
		} else { mixin(S_TRACE);
			assert (_lastFocus is _files);
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
	private bool copy2() { mixin(S_TRACE);
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
		if (pasteImpl(selDirPath, new FileNames(array), false, fromOut)) { mixin(S_TRACE);
			clearCut();
			if (_summ.useTemp) _summ.changed();
			.forceFocus(_files, false);
			_comm.refreshToolBar();
		}
	}
	override void del(SelectionEvent se) { mixin(S_TRACE);
		if (!canDoTCPD) return;
		if (_lastFocus is _dirs) { mixin(S_TRACE);
			auto sels = _dirs.getSelection();
			if (!sels.length) return;
			if (!sels[0].getParentItem()) return;
		}
		auto dlg = new DWTMessageBox(_win.getShell(), SWT.ICON_QUESTION | SWT.OK | SWT.CANCEL);
		dlg.setText(_prop.msgs.dlgTitQuestion);
		auto dir = selDirPath;
		auto file = selFiles;
		string[] fileNames;
		fileNames.length = file.length;
		foreach (i, f; file) { mixin(S_TRACE);
			fileNames[i] = nabs(f);
		}
		bool recycle = (se.stateMask & SWT.SHIFT) == 0;
		if (_lastFocus is _dirs) { mixin(S_TRACE);
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
			assert (_lastFocus is _files);
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
		if (_lastFocus is _dirs) { mixin(S_TRACE);
			auto parItm = _dirs.getSelection()[0].getParentItem();
			if (parItm) { mixin(S_TRACE);
				select((cast(FileNameObj) parItm.getData()).array, false);
			}
		}
		pasteImpl(files);
	}
	@property
	override bool canDoTCPD() { mixin(S_TRACE);
		return _lastFocus !is null;
	}
	@property
	bool canDoT() { mixin(S_TRACE);
		if (!_summ) return false;
		if (_lastFocus is _dirs) { mixin(S_TRACE);
			auto sels = _dirs.getSelection();
			return sels.length > 0 && sels[0].getParentItem();
		} else if (_lastFocus is _files) { mixin(S_TRACE);
			return _files.getSelectionIndex() != -1;
		}
		return false;
	}
	@property
	bool canDoC() { mixin(S_TRACE);
		if (!_summ) return false;
		if (_lastFocus is _dirs) { mixin(S_TRACE);
			return _dirs.getSelection().length > 0;
		} else if (_lastFocus is _files) { mixin(S_TRACE);
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
		if (_lastFocus is _dirs) { mixin(S_TRACE);
			auto sels = _dirs.getSelection();
			return sels.length > 0 && sels[0].getParentItem();
		} else if (_lastFocus is _files) { mixin(S_TRACE);
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
			DWTMessageBox.showWarning
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
					com = wcom[0 .. .countUntil(wcom, '\0')].idup;
					if (com.length) { mixin(S_TRACE);
						auto w = 16.ppis;
						auto h = 16.ppis;
						auto thr = new core.thread.Thread({ mixin(S_TRACE);
							auto exeIcon = loadIcon(to!string(com), w, h, (void delegate() dlg) { mixin(S_TRACE);
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

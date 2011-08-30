
module cwx.editor.gui.dwt.materialselect;

import cwx.cwl;
import cwx.utils;
import cwx.summary;
import cwx.skin;
import cwx.editor.gui.sound;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;

import std.array;
import std.file;
import std.path;
import std.string;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.TextTransfer;

public:

enum MtType {
	CARD,
	BG_IMG,
	BGM,
	SE
}

class MaterialSelect(MtType Type, D, C) {
	/// パスの変更時に呼び出される。
	void delegate()[] modEvent;
public:
	this(Commons comm, Props prop, Summary summ, void delegate() refresh, string[] defs, int including = -1) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_refresh = refresh;
		_defs = defs;
		_including = including;
	}

	D createDirsCombo(Composite parent) {
		static if (is (D == Combo)) {
			_dirs = new D(parent, SWT.BORDER | SWT.READ_ONLY | SWT.DROP_DOWN);
			_dirs.setVisibleItemCount = 20;
		} else static if (is (D == CCombo)) {
			_dirs = new D(parent, SWT.BORDER | SWT.READ_ONLY);
			_dirs.setVisibleItemCount = 20;
		} else {
			static assert (0);
		}
		_dirs.addSelectionListener(new CSListener);

		_comm.refSkin.add(&refresh);
		_comm.refPaths.add(&__refPaths);
		_comm.refPath.add(&__refPath);
		_comm.delPaths.add(&__delPaths);
		_comm.replPath.add(&__replPath);
		_comm.refIgnorePaths.add(&refresh);
		_dirs.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refSkin.remove(&refresh);
				_comm.refPaths.remove(&__refPaths);
				_comm.refPath.remove(&__refPath);
				_comm.delPaths.remove(&__delPaths);
				_comm.replPath.remove(&__replPath);
				_comm.refIgnorePaths.remove(&refresh);
			}
		});
		return _dirs;
	}
	C createFileList(Composite parent) {
		static if (is (C == Table)) {
			_fileList = new C(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE | SWT.FULL_SELECTION);
			new FullTableColumn(_fileList, SWT.NONE);
		} else static if (is (C == Combo)) {
			_fileList = new C(parent, SWT.BORDER | SWT.READ_ONLY | SWT.DROP_DOWN);
			_fileList.setVisibleItemCount = 20;
		} else static if (is (C == CCombo)) {
			_fileList = new C(parent, SWT.BORDER | SWT.READ_ONLY);
			_fileList.setVisibleItemCount = 20;
		} else {
			static assert (0);
		}
		_fileList.addSelectionListener(new LSListener);
		static if (is (C == Table)) {
			static if (Type == MtType.BGM || Type == MtType.SE) {
				auto play = new Play;
				_fileList.addMouseListener(play);
				_fileList.addKeyListener(play);
				static if (Type == MtType.BGM) {
					_fileList.addDisposeListener(new StopBGM);
				} else static if (Type == MtType.SE) {
					_fileList.addDisposeListener(new StopSE);
				} else static assert (0);
			} else {
				auto open = new OpenMaterial;
				_fileList.addMouseListener(open);
				_fileList.addKeyListener(open);
			}
		}
		auto menu = new Menu(_fileList.getShell, SWT.POP_UP);
		createMenuItem(menu, _prop.msgs.menuOpenFileView, _prop.images.menuOpenFileView, &openFilePath);
		createMenuItem(menu, _prop.msgs.menuCopyFilePath, _prop.images.menuCopyFilePath, &copyFilePath);
		static if (Type == MtType.BGM) {
			new MenuItem(menu, SWT.SEPARATOR);
			_bgmMenu = createMenuItem(menu, _prop.msgs.menuPlayBGM, _prop.images.playBGM, &playBGM);
		} else static if (Type == MtType.SE) {
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(menu, _prop.msgs.menuPlaySound, _prop.images.playSound, &playSE);
			createMenuItem(menu, _prop.msgs.menuStopSound, _prop.images.stopSound, &stopSE);
		}
		_fileList.setMenu = menu;
		new class(_fileList) FileDropTarget {
			this(Control c) {
				super(c);
			}
		protected override:
			bool canDrop() {return _summ !is null;}
			string[] doAll(string[] files) {
				assert (_summ);
				string[] r;
				foreach (f; files) {
					if (isTarg(f) && !hasPath(_summ.scenarioPath, f)) {
						r ~= f;
					}
				}
				if (r.length > 0) {
					auto dlg = new MessageBox(control.getShell, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
					dlg.setMessage = _prop.msgs.dlgMsgDropFiles(r);
					dlg.setText = _prop.msgs.dlgTitDropFiles;
					if (SWT.YES == dlg.open) {
						return r;
					}
				}
				return [];
			}
			bool doFile(string path, int x, int y) {
				assert (_summ);
				copyTo(_summ.scenarioPath, path, _comm.skin.materialPath);
				return true;
			}
			void doExit() {
				assert (_summ);
				refreshPaths(_comm.skin.materialPath);
				_comm.refPaths.call(this.outer, _comm.skin.materialPath);
			}
		};
		return _fileList;
	}
	static if (Type == MtType.BGM) {
		private MenuItem _bgmMenu;
		private ToolItem _bgmTMenu;
		private Button _bgmBtn;
		string _playing;
		void createPlayToolItem(ToolBar bar) {
			_bgmTMenu = createToolItem(bar, _prop.msgs.playBGM, _prop.images.playBGM, &playBGM, SWT.CHECK);
		}
		Button createPlayButton(Composite parent) {
			_bgmBtn = new Button(parent, SWT.TOGGLE);
			_bgmBtn.setLayoutData = new GridData;
			_bgmBtn.setToolTipText = _prop.msgs.playBGM;
			_bgmBtn.setImage = _prop.images.playBGM;
			auto pbgm = new Play;
			_bgmBtn.addSelectionListener(pbgm);
			return _bgmBtn;
		}
		void playBGM() {
			if (!_playing) {
				string p = filePath;
				if (p.length > 0 && !cfnmatch(nabs(p), nabs(_playing))) {
					_playing = p;
					if (_bgmMenu) {
						_bgmMenu.setText = _prop.msgs.menuStopBGM(p);
						_bgmMenu.setImage = _prop.images.stopBGM;
						_bgmMenu.setSelection = true;
					}
					if (_bgmTMenu) {
						_bgmTMenu.setToolTipText = _prop.msgs.stopBGM(p);
						_bgmTMenu.setImage = _prop.images.stopBGM;
						_bgmTMenu.setSelection = true;
					}
					if (_bgmBtn) {
						_bgmBtn.setToolTipText = _prop.msgs.stopBGM(getBaseName(path));
						_bgmBtn.setImage = _prop.images.stopBGM;
						_bgmBtn.setSelection = true;
					}
					playBGMCW(_prop, p, _summ.legacy);
					return;
				}
			}
			if (_bgmMenu) {
				_bgmMenu.setText = _prop.msgs.menuPlayBGM;
				_bgmMenu.setImage = _prop.images.playBGM;
				_bgmMenu.setSelection = false;
			}
			if (_bgmTMenu) {
				_bgmTMenu.setToolTipText = _prop.msgs.playBGM;
				_bgmTMenu.setImage = _prop.images.playBGM;
				_bgmTMenu.setSelection = false;
			}
			if (_bgmBtn) {
				_bgmBtn.setToolTipText = _prop.msgs.playBGM;
				_bgmBtn.setImage = _prop.images.playBGM;
				_bgmBtn.setSelection = false;
			}
			stopBGM();
			_playing = null;
		}
		private class Play : SelectionAdapter, KeyListener, MouseListener {
			override void mouseUp(MouseEvent e) {}
			override void mouseDown(MouseEvent e) {}
			override void mouseDoubleClick(MouseEvent e) {
				if (e.button == 1) {
					playBGM();
				}
			}
			override void keyReleased(KeyEvent e) {}
			override void keyPressed(KeyEvent e) {
				if (e.character == SWT.CR) {
					playBGM();
				}
			}
			override void widgetSelected(SelectionEvent e) {
				playBGM();
			}
		}
	} else static if (Type == MtType.SE) {
		void createPlayToolItem(ToolBar bar) {
			createToolItem(bar, _prop.msgs.playSound, _prop.images.playSound, &playSE, SWT.PUSH);
		}
		Button createPlayButton(Composite parent) {
			auto seBtn = new Button(parent, SWT.PUSH);
			seBtn.setToolTipText = _prop.msgs.playSound;
			seBtn.setImage = _prop.images.playSound;
			auto play = new Play;
			seBtn.addSelectionListener(play);
			return seBtn;
		}
		Button createStopButton(Composite parent) {
			auto stop = new Button(parent, SWT.PUSH);
			stop.setToolTipText = _prop.msgs.stopSound;
			stop.setImage = _prop.images.stopSound;
			auto sse = new StopSE;
			stop.addSelectionListener(sse);
			stop.addDisposeListener(sse);
			return stop;
		}
		void playSE() {
			string p = filePath;
			if (p.length > 0) {
				playSECW(_prop, p, _summ.legacy);
			}
		}
		void stopSE() {
			.stopSE();
		}
		private class Play : SelectionAdapter, KeyListener, MouseListener {
			override void mouseUp(MouseEvent e) {}
			override void mouseDown(MouseEvent e) {}
			override void mouseDoubleClick(MouseEvent e) {
				if (e.button == 1) {
					playSE();
				}
			}
			override void keyReleased(KeyEvent e) {}
			override void keyPressed(KeyEvent e) {
				if (e.character == SWT.CR) {
					playSE();
				}
			}
			override void widgetSelected(SelectionEvent e) {
				playSE();
			}
		}
	}
	Button createRefreshButton(Composite parent, bool text) {
		auto refBtn = new Button(parent, SWT.PUSH);
		refBtn.setImage = _prop.images.menuRefresh;
		if (text) {
			refBtn.setText = _prop.msgs.ttRefreshS;
		} else {
			refBtn.setToolTipText = _prop.msgs.ttRefresh;
		}
		refBtn.addSelectionListener(new RSListener);
		return refBtn;
	}
	Button createDirectoryButton(Composite parent, bool text) {
		auto dirBtn = new Button(parent, SWT.PUSH);
		dirBtn.setLayoutData = new GridData(GridData.FILL_VERTICAL);
		dirBtn.setImage = _prop.images.folder;
		dirBtn.addSelectionListener(new DSListener);
		if (text) {
			dirBtn.setText = _prop.msgs.ttOpenDirectory;
		} else {
			dirBtn.setToolTipText = _prop.msgs.ttOpenDirectory;
		}
		return dirBtn;
	}
	string path() {
		if (_dirs.getSelectionIndex == _including && isBinImg(_oldPath)) {
			return _oldPath;
		}
		return _path;
	}
	string filePath() {
		if (_dirs.getSelectionIndex == _including && isBinImg(_oldPath)) {
			return _oldPath;
		}
		auto p = currentDir;
		if (p && _fileList.getSelectionIndex >= 0) {
			string f = fileText(_fileList.getItem(_fileList.getSelectionIndex));
			if (_dirs.getSelectionIndex == _tbl) {
				return std.path.join(defDir, f);
			} else {
				return std.path.join(std.path.join(_summ ? _summ.scenarioPath : "", p), f);
			}
		}
		return "";
	}
	void path(string path) {
		auto old = _path;
		scope (exit) {
			if (old != _path) {
				foreach (dlg; modEvent) dlg();
			}
		}
		_path = path;
		_oldPath = _path;
		refreshPaths;
	}
	string oldPath() {
		return _oldPath;
	}
	D dirsCombo() {
		return _dirs;
	}
	C fileList() {
		return _fileList;
	}
	void refresh() {
		refreshPaths;
		if (_refresh) _refresh();
	}

	string[] showingNames() {
		static if (is(C : Table)) {
			TableItem[] itms;
			if (_fnone) {
				itms = _fileList.getItems[1 .. $];
			} else {
				itms = _fileList.getItems;
			}
			auto r = new string[itms.length];
			foreach (i, ref s; r) {
				s = itms[i].getText;
			}
			return r;
		} else static if (is(C : Combo) || is(C : CCombo)) {
			if (_fnone) {
				return _fileList.getItems[1 .. $];
			} else {
				return _fileList.getItems;
			}
		}
	}
	string[] showingPaths() {
		string[] r;
		string curr = currentDir;
		string[] paths = showingNames;
		foreach (s; paths) {
			if (curr) {
				r ~= std.path.join(curr, s);
			} else if (s.startsWith("/")) {
				string file;
				s = s["/".length .. $];
				int i = s.lastIndexOf("/");
				if (i != -1) {
					file = s[i + "/".length .. $];
					s = s[0 .. i];
				} else {
					file = s;
					s = "/";
				}
				r ~= std.path.join(s, file);
			} else {
				r ~= s;
			}
		}
		return r;
	}

	void copyFilePath() {
		auto p = path;
		if (!p.length) return;
		auto cb = new Clipboard(Display.getCurrent);
		scope (exit) cb.dispose;
		cb.setContents([new PathString(encodePath(p))],
			[TextTransfer.getInstance]);
	}
private:
	static if (Type == MtType.CARD) {
		string defExt() {return _comm.skin.extImage;}
		string defDir() {return _comm.skin.tableDir;}
		bool isTarg(string p) {return _comm.skin.isCardImage(p);}
		bool hasTarg(string p) {return _comm.skin.hasCardImage(p);}
		string[] targs(string dir, bool re) {return _comm.skin.cards(dir, re);}
		Image image() {return _prop.images.cards;}
	} else static if (Type == MtType.BG_IMG) {
		string defExt() {return _comm.skin.extImage;}
		string defDir() {return _comm.skin.tableDir;}
		bool isTarg(string p) {return _comm.skin.isBgImage(p);}
		bool hasTarg(string p) {return _comm.skin.hasBgImage(p);}
		string[] targs(string dir, bool re) {return _comm.skin.tables(dir, re);}
		Image image() {return _prop.images.backs;}
	} else static if (Type == MtType.BGM) {
		string defExt() {return _comm.skin.extBgm;}
		string defDir() {return _comm.skin.bgmDir;}
		bool isTarg(string p) {return _comm.skin.isBGM(p);}
		bool hasTarg(string p) {return _comm.skin.hasBGM(p);}
		string[] targs(string dir, bool re) {return _comm.skin.musics(dir, re);}
		Image image() {return _prop.images.bgm;}
	} else static if (Type == MtType.SE) {
		string defExt() {return _comm.skin.extSound;}
		string defDir() {return _comm.skin.seDir;}
		bool isTarg(string p) {return _comm.skin.isSE(p);}
		bool hasTarg(string p) {return _comm.skin.hasSE(p);}
		string[] targs(string dir, bool re) {return _comm.skin.sounds(dir, re);}
		Image image() {return _prop.images.se;}
	} else static assert (0);

	class RSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			refreshPaths(null, true);
			if (_refresh) _refresh();
		}
	}
	class DSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			if (_dirs.getSelectionIndex == _tbl) {
				openFolder(defDir);
			} else if (_summ) {
				string cur = currentDir;
				if (cur) {
					openFolder(std.path.join(_summ.scenarioPath, cur));
				} else {
					scope p = std.path.join(_summ.scenarioPath, _comm.skin.materialPath);
					if (exists(p)) {
						openFolder(p);
					} else {
						openFolder(_summ.scenarioPath);
					}
				}
			}
		}
	}
	class CSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			refreshList;
			if (_dirs.getSelectionIndex < _defs.length) {
				_path = "";
				if (_selDir != _dirs.getSelectionIndex) {
					foreach (dlg; modEvent) dlg();
				}
				_selDir = _dirs.getSelectionIndex;
				if (_refresh) _refresh();
			} else {
				static if (is(C : Combo) || is(C : CCombo)) {
					auto old = _path;
					scope (exit) {
						if (old != _path) {
							foreach (dlg; modEvent) dlg();
						}
					}
					string p = currentDir;
					if (!p) return;
					if (0 == _fileList.getItemCount) return;
					_fileList.select = 0;
					_path = std.path.join(p, _fileList.getItem(0));
					if (_refresh) _refresh();
				}
			}
		}
	}
	class LSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			int index = _fileList.getSelectionIndex;
			if (index < 0) return;
			auto old = _path;
			scope (exit) {
				if (old != _path) {
					foreach (dlg; modEvent) dlg();
				}
			}
			if (_allList) {
				string s = fileText(_fileList.getItem(index));
				string file;
				if (s.startsWith("/")) {
					s = s["/".length .. $];
					int i = s.lastIndexOf("/");
					if (i != -1) {
						file = s[i + "/".length .. $];
						s = s[0 .. i];
					} else {
						file = s;
						s = "/";
					}
					_dirs.setText = s;
				} else {
					_dirs.select = _tbl;
					file = s;
				}
				refreshList();
				int selIndex = -1;
				foreach (i, itm; _fileList.getItems) {
					if (cfnmatch(fileText(itm), file)) {
						selIndex = i;
						break;
					}
				}
				_fileList.select = selIndex;
				static if (is (C == Table)) {
					_fileList.showSelection();
				}
				string p = currentDir;
				_path = std.path.join(p, file);
				_selDir = _dirs.getSelectionIndex;
				if (_refresh) _refresh();
			} else {
				string p = currentDir;
				if (!p) {
					static if (is(C : Combo) || is(C : CCombo)) {
						if (index == 0) return;
						_fileList.remove(0);
					}
					_dirs.select = _defs.length;
					p = currentDir;
				}
				if (p) {
					_path = std.path.join(p, fileText(_fileList.getItem(_fileList.getSelectionIndex)));
					_selDir = _dirs.getSelectionIndex;
					if (_refresh) _refresh();
				}
			}
		}
	}
	private class OpenMaterial : MouseAdapter, KeyListener {
		override void mouseDoubleClick(MouseEvent e) {
			if (1 == e.button) {
				openFilePath();
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void keyPressed(KeyEvent e) {
			if (SWT.CR == e.character) openFilePath();
		}
	}
	private void openFilePath() {
		auto dir = _dirs.getSelectionIndex;
		if (dir < _defs.length) return;
		if (dir == _tbl) return;
		auto p = filePath;
		if (p.length) {
			_comm.openFilePath(p);
		}
	}
	private static string fromViewPath(string s) {
		static if (sep != "/" && altsep == "/") {
			return replace(s, "/", sep);
		} else {
			return s;
		}
	}
	private static string toViewPath(string s) {
		static if (sep != "/" && altsep == "/") {
			return replace(replace(s, sep, "/"), altsep, "/");
		} else {
			return s;
		}
	}
	private string currentDir() {
		int sel = _dirs.getSelectionIndex;
		if (sel >= _defs.length) {
			if (sel == _tbl) {
				return "";
			} else {
				return _dirs.getText == "/" ? "" : toViewPath(_dirs.getText);
			}
		}
		return null;
	}
	private string fileText(T)(T itm) {
		static if (is(T : TableItem)) {
			return itm.getText;
		} else static if (is(T : string)) {
			return itm;
		} else static assert (0);
	}
	int indexOf(T)(T list, string path) {
		foreach (i, s; list.getItems) {
			if (cfnmatch(fileText(s), path)) {
				return i;
			}
		}
		return -1;
	}
	int flIndexOf(string path) {
		return indexOf(_fileList, path);
	}
	int dirsIndexOf(string path) {
		return indexOf(_dirs, path);
	}
	void __refreshList(string path, bool forceRefresh) {
		string[] s = targs(path, forceRefresh);
		if (_prop.var.etc.logicalSort) {
			s = sort!(fnncmp)(s);
		} else {
			s = sort!(fncmp)(s);
		}
		__refreshListImpl(s);
		_allList = false;
	}
	void __refreshList(string[] paths, bool forceRefresh) {
		string[] tgs;
		foreach (path; paths) {
			string parent;
			if (cfnmatch(path, defDir)) {
				parent = "";
			} else {
				assert (_summ);
				parent = abs2rel(_summ.scenarioPath, path);
				parent = sep.idup ~ parent;
			}
			string[] s = targs(path, forceRefresh);
			if (_prop.var.etc.logicalSort) {
				s = sort!(fnncmp)(s);
			} else {
				s = sort!(fncmp)(s);
			}
			foreach (ref f; s) {
				f = encodePath(std.path.join(parent, f));
			}
			tgs ~= s;
		}
		__refreshListImpl(tgs);
		_allList = true;
	}
	void __refreshListImpl(string[] tgs) {
		foreach (f; tgs) {
			static if (is(C : Table)) {
				auto itm = new TableItem(_fileList, SWT.NONE);
				itm.setText = f;
				itm.setImage = image;
			} else static if (is(C : Combo) || is(C : CCombo)) {
				_fileList.add(f);
			} else static assert (0);
		}
		string sel = _path.length > 0 ? getBaseName(_path) : "";
		if (sel.length > 0 && _dirs.getSelectionIndex == _selDir) {
			int index = flIndexOf(sel);
			if (index >= 0) {
				_fileList.select = index;
			} else if (_dirs.getSelectionIndex == _tbl) {
				index = flIndexOf(addExt(sel, defExt));
				if (index >= 0) _fileList.select = index;
			}
		}
		static if (is (C == Table)) {
			_fileList.showSelection;
		} else static if (!is (C == Combo) && !is (C == CCombo)) {
			static assert (false);
		}
	}
	string[] allDirs() {
		string[] st;
		foreach (i; _defs.length .. _dirs.getItemCount) {
			string t = _dirs.getItem(i);
			if (i == _tbl) {
				st ~= defDir;
			} else if (t == "/") {
				assert (_summ);
				st ~= nabs(_summ.scenarioPath);
			} else {
				assert (_summ);
				st ~= nabs(std.path.join(_summ.scenarioPath, fromViewPath(t)));
			}
		}
		return st;
	}
	void refreshList(bool forceRefresh = false) {
		_fileList.removeAll;
		_fnone = false;
		if (_dirs.getSelectionIndex < _defs.length) {
			auto dirs = allDirs;
			if (!dirs.length) {
				_fileList.setEnabled = false;
			} else {
				__refreshList(dirs, forceRefresh);
				static if (is(C : Combo) || is(C : CCombo)) {
					_fileList.add(_prop.msgs.fileNone, 0);
					_fileList.select = 0;
					_fnone = true;
				} else {
					_fileList.select = -1;
				}
			}
		} else if (_dirs.getSelectionIndex == _tbl) {
			__refreshList(defDir, forceRefresh);
		} else if (_summ) {
			string st;
			if (_dirs.getText == "/") {
				st = _summ.scenarioPath;
			} else {
				st = std.path.join(_summ.scenarioPath, fromViewPath(_dirs.getText));
			}
			__refreshList(st, forceRefresh);
		}
	}
	void searchTarg(string dir, size_t cut) {
		if (hasTarg(dir)) {
			_dirs.add(dir.length <= cut ? "/" : toViewPath(dir[cut .. $]));
		}
		foreach (f; clistdir(dir)) {
			if (containsPath(_prop.var.etc.ignorePaths, f)) continue;
			f = std.path.join(dir, f);
			if (isdir(f)) {
				searchTarg(f, cut);
			}
		}
	}
	void refreshPaths(string select = null, bool forceRefresh = false) {
		int oldSel = _dirs.getSelectionIndex;
		if (oldSel < 0) oldSel = 0;
		string oldSelS = _dirs.getText;
		_dirs.removeAll;
		foreach (def; _defs) {
			_dirs.add(def);
		}
		auto tbl = defDir;
		_tbl = -1;
		if (hasTarg(tbl)) {
			_tbl = _dirs.getItemCount;
			_dirs.add(_prop.msgs.pathDef);
		}
		size_t cut = 0;
		if (_summ) {
			string st = _summ.scenarioPath;
			cut = st.length;
			static if (altsep.length) {
				if (!endsWith(st, sep) && !endsWith(st, altsep)) cut++;
			} else {
				if (!endsWith(st, sep)) cut++;
			}
			searchTarg(_summ.scenarioPath, cut);
		}
		if (!select) {
			void selectOld() {
				if (oldSel < _defs.length) {
					_dirs.select = oldSel;
				} else {
					int index = dirsIndexOf(oldSelS);
					if (index >= 0) {
						_dirs.select = index;
					} else if (_dirs.getItemCount > 0) {
						_dirs.select = 0;
					}
				}
			}
			bool def;
			if (isBinImg(_path)) {
				_dirs.select = _including;
			} else {
				auto p = _comm.skin.findPathF(_path, defExt, defDir, _summ ? _summ.scenarioPath : "", def);
				if (p.length > 0) {
					if (def) {
						if (_tbl == -1) {
							// ファイルが無い
							selectOld;
						} else {
							_dirs.select = _tbl;
						}
					} else if (_summ) {
						string pt = getDirName(p);
						pt = pt.length <= cut ? sep.idup : pt[cut .. $];
						pt = toViewPath(pt);
						_dirs.select = dirsIndexOf(pt);
					}
				} else {
					selectOld;
				}
			}
		} else {
			select = toViewPath(select);
			_dirs.setText = select;
		}
		_selDir = _dirs.getSelectionIndex;
		refreshList(forceRefresh);
	}

	void __refPaths(Object sender, string parent) {
		if (this !is sender) {
			refreshPaths;
		}
	}
	void __refPath(string o, string n, bool isDir) {
		auto old = _path;
		scope (exit) {
			if (old != _path) {
				foreach (dlg; modEvent) dlg();
			}
		}
		if (isDir) {
			int i = _defs.length;
			if (_tbl >= 0) i++;
			for (; i < _dirs.getItemCount; i++) {
				string name = fromViewPath(_dirs.getItem(i));
				if (startsWith(name, o)) {
					string nName = std.path.join(n, name[o.length .. $]);
					nName = toViewPath(nName);
					_dirs.setItem(i, nName);
					if (i == _dirs.getSelectionIndex) {
						_dirs.setText = nName;
					}
				}
			}
		} else {
			if (o == _path) _path = n;
			int di = _dirs.getSelectionIndex;
			auto op = o;
			if (di >= 0 && cfnmatch(fromViewPath(_dirs.getItems[di]), getDirName(o))) {
				int index = flIndexOf(getBaseName(o));
				if (index >= 0) {
					string nName = getBaseName(n);
					static if (is(C : Table)) {
						_fileList.getItem(index).setText = nName;
					} else static if (is (C : Combo) || is (C : CCombo)) {
						_fileList.setItem(index, nName);
						_fileList.setText = nName;
					} else static assert (0);
				}
			}
		}
	}
	void __delPaths() {
		refreshPaths;
	}
	void __replPath(string from, string to) {
		if (_path == from) {
			refreshPaths;
		}
	}

	Props _prop;
	Commons _comm;
	D _dirs;
	Summary _summ;
	string _path = "";
	string _oldPath = "";
	string[] _defs;
	int _selDir;
	int _including = -1;
	int _tbl = -1;
	bool _fnone = false;
	C _fileList;
	bool _allList = false;
	void delegate() _refresh;
}

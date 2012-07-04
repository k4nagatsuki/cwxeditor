
module cwx.editor.gui.dwt.materialselect;

import cwx.cwl;
import cwx.utils;
import cwx.summary;
import cwx.skin;
import cwx.menu;

import cwx.editor.gui.sound;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;

import std.array;
import std.file;
import std.path;
import std.string;

import org.eclipse.swt.all;

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
	this (Commons comm, Props prop, Summary summ, void delegate() refresh, string[] defs, int including = -1) {
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
			_dirs.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		} else static if (is (D == CCombo)) {
			_dirs = new D(parent, SWT.BORDER | SWT.READ_ONLY);
			_dirs.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!D(_comm, _prop, _dirs, null);
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
		static if (Type == MtType.BGM) {
			stopBGMEvent ~= &stopBGM;
		}
		_dirs.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refSkin.remove(&refresh);
				_comm.refPaths.remove(&__refPaths);
				_comm.refPath.remove(&__refPath);
				_comm.delPaths.remove(&__delPaths);
				_comm.replPath.remove(&__replPath);
				_comm.refIgnorePaths.remove(&refresh);
				static if (Type == MtType.BGM) {
					cwx.utils.remove(stopBGMEvent, &stopBGM);
				}
			}
		});
		auto menu = new Menu(_dirs.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &startIncSearch, null);
		_dirs.setMenu(menu);
		return _dirs;
	}
	static if (Type == MtType.BGM) {
		private void stopBGM() {
			if (_playing) {
				playBGM();
			}
		}
	}
	C createFileList(Composite parent) {
		static if (is (C == Table)) {
			_fileList = new C(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE | SWT.FULL_SELECTION);
			new FullTableColumn(_fileList, SWT.NONE);
		} else static if (is (C == Combo)) {
			_fileList = new C(parent, SWT.BORDER | SWT.READ_ONLY | SWT.DROP_DOWN);
			_fileList.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		} else static if (is (C == CCombo)) {
			_fileList = new C(parent, SWT.BORDER | SWT.READ_ONLY);
			_fileList.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!CCombo(_comm, _prop, _fileList, null);
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
		auto menu = new Menu(_fileList.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &startIncSearch, null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.OpenAtFileView, &openFilePath, () => filePath.length > 0);
		createMenuItem(_comm, menu, MenuID.CopyFilePath, &copyFilePath, () => filePath.length > 0);
		static if (Type == MtType.BGM) {
			new MenuItem(menu, SWT.SEPARATOR);
			_bgmMenu = createMenuItem(_comm, menu, MenuID.PlayBGM, &playBGM, &canPlay);
			auto data = cast(MenuData) _bgmMenu.getData();
			data.format = (string t) {return data.id is MenuID.StopBGM ? .tryFormat(t, _playing) : t;};
		} else static if (Type == MtType.SE) {
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.PlaySE, &playSE, &canPlay);
			createMenuItem(_comm, menu, MenuID.StopSE, &stopSE, null);
		}
		_fileList.setMenu(menu);
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
					auto dlg = new MessageBox(control.getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO);
					if (1 == r.length) {
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropFile, r[0]));
					} else {
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropFiles, r.length));
					}
					dlg.setText(_prop.msgs.dlgTitDropFiles);
					if (SWT.YES == dlg.open()) {
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
		_incSearch = new IncSearch(_comm, _fileList);
		_incSearch.modEvent ~= {
			refreshList();
		};
		return _fileList;
	}
	static if (Type == MtType.BGM || Type == MtType.SE) {
		private Button _bgmBtn;
	}
	static if (Type == MtType.BGM) {
		private MenuItem _bgmMenu;
		private ToolItem _bgmTMenu;
		string _playing = null;
		void createPlayToolItem(ToolBar bar) {
			_bgmTMenu = createToolItem(_comm, bar, MenuID.PlayBGM, &playBGM, &canPlay, SWT.CHECK);
			auto data = cast(MenuData) _bgmTMenu.getData();
			data.format = (string t) {return data.id is MenuID.StopBGM ? .tryFormat(t, _playing) : t;};
		}
		Button createPlayButton(Composite parent) {
			_bgmBtn = new Button(parent, SWT.TOGGLE);
			_bgmBtn.setLayoutData(new GridData);
			_bgmBtn.setToolTipText(_prop.buildTool(MenuID.PlayBGM));
			_bgmBtn.setImage(_prop.images.menu(MenuID.PlayBGM));
			auto pbgm = new Play;
			_bgmBtn.addSelectionListener(pbgm);
			_comm.put(_bgmBtn, &canPlay);
			return _bgmBtn;
		}
		@property
		bool canPlay() {
			return _playing ? true : filePath.length > 0;
		}
		void playBGM() {
			string p = filePath;
			if (p.length > 0 && (!_playing || !cfnmatch(nabs(p), nabs(_playing)))) {
				bool inPlay = playBGMCW(_prop, p, _summ.legacy);
				if (inPlay) {
					_playing = p;
					if (_bgmMenu) {
						_bgmMenu.setText(.tryFormat(_prop.buildMenu(MenuID.StopBGM), p));
						auto d = cast(MenuData) _bgmMenu.getData();
						d.id = MenuID.StopBGM;
						_bgmMenu.setImage(_prop.images.menu(MenuID.StopBGM));
						_bgmMenu.setSelection(true);
					}
					if (_bgmTMenu) {
						_bgmTMenu.setToolTipText(.tryFormat(_prop.buildTool(MenuID.StopBGM), p));
						_bgmTMenu.setImage(_prop.images.menu(MenuID.StopBGM));
						_bgmTMenu.setSelection(true);
					}
					if (_bgmBtn) {
						_bgmBtn.setToolTipText(.tryFormat(_prop.buildTool(MenuID.StopBGM), baseName(path)));
						_bgmBtn.setImage(_prop.images.menu(MenuID.StopBGM));
						_bgmBtn.setSelection(true);
					}
					return;
				}
			}
			if (_bgmMenu) {
				_bgmMenu.setText(_prop.buildMenu(MenuID.PlayBGM));
				auto d = cast(MenuData) _bgmMenu.getData();
				d.id = MenuID.PlayBGM;
				_bgmMenu.setImage(_prop.images.menu(MenuID.PlayBGM));
				_bgmMenu.setSelection(false);
			}
			if (_bgmTMenu) {
				_bgmTMenu.setToolTipText(_prop.buildTool(MenuID.PlayBGM));
				_bgmTMenu.setImage(_prop.images.menu(MenuID.PlayBGM));
				_bgmTMenu.setSelection(false);
			}
			if (_bgmBtn) {
				_bgmBtn.setToolTipText(_prop.buildTool(MenuID.PlayBGM));
				_bgmBtn.setImage(_prop.images.menu(MenuID.PlayBGM));
				_bgmBtn.setSelection(false);
			}
			.stopBGM();
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
			createToolItem(_comm, bar, MenuID.PlaySE, &playSE, &canPlay);
		}
		Button createPlayButton(Composite parent) {
			_bgmBtn = new Button(parent, SWT.PUSH);
			_bgmBtn.setToolTipText(_prop.buildTool(MenuID.PlaySE));
			_bgmBtn.setImage(_prop.images.menu(MenuID.PlaySE));
			auto play = new Play;
			_bgmBtn.addSelectionListener(play);
			_comm.put(_bgmBtn, &canPlay);
			return _bgmBtn;
		}
		Button createStopButton(Composite parent) {
			auto stop = new Button(parent, SWT.PUSH);
			stop.setToolTipText(_prop.buildTool(MenuID.StopSE));
			stop.setImage(_prop.images.menu(MenuID.StopSE));
			auto sse = new StopSE;
			stop.addSelectionListener(sse);
			stop.addDisposeListener(sse);
			return stop;
		}
		@property
		bool canPlay() {
			return filePath.length > 0;
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
		refBtn.setImage(_prop.images.menu(MenuID.Refresh));
		if (text) {
			refBtn.setText(_prop.msgs.refreshS);
		} else {
			refBtn.setToolTipText(_prop.buildTool(MenuID.Refresh));
		}
		refBtn.addSelectionListener(new RSListener);
		return refBtn;
	}
	Button createDirectoryButton(Composite parent, bool text) {
		_dirBtn = new Button(parent, SWT.PUSH);
		_dirBtn.setLayoutData(new GridData(GridData.FILL_VERTICAL));
		_dirBtn.setImage(_prop.images.folder);
		_dirBtn.addSelectionListener(new DSListener);
		if (text) {
			_dirBtn.setText(_prop.buildTool(MenuID.OpenDir));
		} else {
			_dirBtn.setToolTipText(_prop.buildTool(MenuID.OpenDir));
		}
		return _dirBtn;
	}
	@property
	string path() {
		if (_dirs.getSelectionIndex() == _including && isBinImg(_oldPath)) {
			return _oldPath;
		}
		return _path;
	}
	@property
	string filePath() {
		if (!_dirs || _dirs.isDisposed()) return "";
		if (!_fileList || _fileList.isDisposed()) return "";
		if (_dirs.getSelectionIndex() == _including && isBinImg(_oldPath)) {
			return _oldPath;
		}
		auto p = currentDir;
		if (p && _fileList.getSelectionIndex() >= 0) {
			string f = fileText(_fileList.getItem(_fileList.getSelectionIndex()));
			if (_dirs.getSelectionIndex() == _tbl) {
				return std.path.buildPath(defDir, f);
			} else {
				return std.path.buildPath(std.path.buildPath(_summ ? _summ.scenarioPath : "", p), f);
			}
		}
		return "";
	}
	@property
	void path(string path) {
		auto old = _path;
		scope (exit) {
			if (old != _path) {
				foreach (dlg; modEvent) dlg();
			}
		}
		_path = path;
		_oldPath = _path;
		refreshPaths();
	}
	@property
	string oldPath() {
		return _oldPath;
	}
	@property
	D dirsCombo() {
		return _dirs;
	}
	@property
	C fileList() {
		return _fileList;
	}
	void refresh() {
		refreshPaths();
		if (_refresh) _refresh();
	}

	@property
	string[] showingNames() {
		static if (is(C : Table)) {
			TableItem[] itms;
			if (_fnone) {
				itms = _fileList.getItems()[1 .. $];
			} else {
				itms = _fileList.getItems();
			}
			auto r = new string[itms.length];
			foreach (i, ref s; r) {
				s = itms[i].getText();
			}
			return r;
		} else static if (is(C : Combo) || is(C : CCombo)) {
			if (_fnone) {
				return _fileList.getItems()[1 .. $];
			} else {
				return _fileList.getItems();
			}
		}
	}
	@property
	string[] showingPaths() {
		string[] r;
		string curr = currentDir;
		string[] paths = showingNames;
		foreach (s; paths) {
			if (curr) {
				r ~= std.path.buildPath(curr, s);
			} else if (s.startsWith("/")) {
				string file;
				s = s["/".length .. $];
				int i = s.lastIndexOf("/");
				if (i != -1) {
					file = s[i + "/".length .. $];
					s = s[0 .. i];
				} else {
					file = s;
					s = "";
				}
				r ~= std.path.buildPath(s, file);
			} else {
				r ~= s;
			}
		}
		return r;
	}

	void copyFilePath() {
		auto p = path;
		if (!p.length) return;
		_comm.clipboard.setContents([new PathString(encodePath(p))],
			[TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}

	@property
	void selectDir(int sel) {
		_dirs.select(sel);
		refreshList();
		scope (exit) refreshButtons();
		if (sel < _defs.length) {
			_path = "";
			if (_selDir != sel) {
				foreach (dlg; modEvent) dlg();
			}
			_selDir = sel;
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
				if (0 == _fileList.getItemCount()) return;
				_fileList.select(0);
				_path = std.path.buildPath(p, _fileList.getItem(0));
				if (_refresh) _refresh();
			}
			_selDir = sel;
		}
	}

	@property
	IncSearch incSearch() {return _incSearch;}
	void startIncSearch() {
		.forceFocus(_fileList, true);
		_incSearch.startIncSearch();
	}
private:
	static if (Type == MtType.CARD) {
		@property string defExt() {return _comm.skin.extImage;}
		@property string defDir() {return _comm.skin.tableDir;}
		bool isTarg(string p) {return _comm.skin.isCardImage(p);}
		bool hasTarg(string p) {return _comm.skin.hasCardImage(p);}
		string[] targsImpl(string dir, bool re) {return _comm.skin.cards(dir, re);}
		@property Image image() {return _prop.images.cards;}
	} else static if (Type == MtType.BG_IMG) {
		@property string defExt() {return _comm.skin.extImage;}
		@property string defDir() {return _comm.skin.tableDir;}
		bool isTarg(string p) {return _comm.skin.isBgImage(p);}
		bool hasTarg(string p) {return _comm.skin.hasBgImage(p);}
		string[] targsImpl(string dir, bool re) {return _comm.skin.tables(dir, re);}
		@property Image image() {return _prop.images.backs;}
	} else static if (Type == MtType.BGM) {
		@property string defExt() {return _comm.skin.extBgm;}
		@property string defDir() {return _comm.skin.bgmDir;}
		bool isTarg(string p) {return _comm.skin.isBGM(p);}
		bool hasTarg(string p) {return _comm.skin.hasBGM(p);}
		string[] targsImpl(string dir, bool re) {return _comm.skin.musics(dir, re);}
		@property Image image() {return _prop.images.bgm;}
	} else static if (Type == MtType.SE) {
		@property string defExt() {return _comm.skin.extSound;}
		@property string defDir() {return _comm.skin.seDir;}
		bool isTarg(string p) {return _comm.skin.isSE(p);}
		bool hasTarg(string p) {return _comm.skin.hasSE(p);}
		string[] targsImpl(string dir, bool re) {return _comm.skin.sounds(dir, re);}
		@property Image image() {return _prop.images.se;}
	} else static assert (0);

	class RSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			refreshPaths(null, true);
			if (_refresh) _refresh();
		}
	}
	class DSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			if (_dirs.getSelectionIndex() == _tbl) {
				openFolder(defDir);
			} else if (_summ) {
				string cur = currentDir;
				if (cur) {
					openFolder(std.path.buildPath(_summ.scenarioPath, cur));
				} else {
					scope p = std.path.buildPath(_summ.scenarioPath, _comm.skin.materialPath);
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
			selectDir(_dirs.getSelectionIndex());
		}
	}
	class LSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			int index = _fileList.getSelectionIndex();
			if (index < 0) return;
			auto old = _path;
			scope (exit) {
				if (old != _path) {
					foreach (dlg; modEvent) dlg();
				}
				refreshButtons();
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
					_dirs.setText(s);
				} else {
					_dirs.select(_tbl);
					file = s;
				}
				refreshList();
				int selIndex = -1;
				foreach (i, itm; _fileList.getItems()) {
					if (cfnmatch(fileText(itm), file)) {
						selIndex = i;
						break;
					}
				}
				_fileList.select(selIndex);
				static if (is (C == Table)) {
					_fileList.showSelection();
				}
				string p = currentDir;
				_path = std.path.buildPath(p, file);
				_selDir = _dirs.getSelectionIndex();
				if (_refresh) _refresh();
			} else {
				string p = currentDir;
				if (!p) {
					static if (is(C : Combo) || is(C : CCombo)) {
						if (index == 0) return;
						_fileList.remove(0);
					}
					_dirs.select(_defs.length);
					p = currentDir;
				}
				if (p) {
					_path = std.path.buildPath(p, fileText(_fileList.getItem(_fileList.getSelectionIndex())));
					_selDir = _dirs.getSelectionIndex();
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
		auto dir = _dirs.getSelectionIndex();
		if (dir < _defs.length) return;
		if (dir == _tbl) return;
		auto p = filePath;
		if (p.length) {
			_comm.openFilePath(p, false);
		}
	}
	private static string fromViewPath(string s) {
		static if (dirSeparator != "/" && altDirSeparator == "/") {
			return replace(s, "/", dirSeparator);
		} else {
			return s;
		}
	}
	private static string toViewPath(string s) {
		static if (dirSeparator != "/" && altDirSeparator == "/") {
			return replace(replace(s, dirSeparator, "/"), altDirSeparator, "/");
		} else {
			return s;
		}
	}
	@property
	private string currentDir() {
		int sel = _dirs.getSelectionIndex();
		if (sel >= _defs.length) {
			if (sel == _tbl) {
				return "";
			} else {
				return _dirs.getText() == "/" ? "" : toViewPath(_dirs.getText());
			}
		}
		return null;
	}
	private string fileText(T)(T itm) {
		static if (is(T : TableItem)) {
			return itm.getText();
		} else static if (is(T : string)) {
			return itm;
		} else static assert (0);
	}
	int indexOf(T)(T list, string path) {
		foreach (i, s; list.getItems()) {
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
	string[] targs(string path, bool forceRefresh) {
		string[] r;
		foreach (f; targsImpl(path, forceRefresh)) {
			if (_incSearch.match(f.baseName())) {
				r ~= f;
			}
		}
		return r;
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
				parent = dirSeparator.idup ~ parent;
			}
			string[] s = targs(path, forceRefresh);
			if (_prop.var.etc.logicalSort) {
				s = sort!(fnncmp)(s);
			} else {
				s = sort!(fncmp)(s);
			}
			foreach (ref f; s) {
				f = encodePath(std.path.buildPath(parent, f));
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
				itm.setText(f);
				itm.setImage(image);
			} else static if (is(C : Combo) || is(C : CCombo)) {
				_fileList.add(f);
			} else static assert (0);
		}
		string sel = _path.length > 0 ? baseName(_path) : "";
		if (sel.length > 0 && _dirs.getSelectionIndex() == _selDir) {
			int index = flIndexOf(sel);
			if (index >= 0) {
				_fileList.select(index);
			} else if (_dirs.getSelectionIndex() == _tbl) {
				index = flIndexOf(setExtension(sel, defExt));
				if (index >= 0) _fileList.select(index);
			}
		}
		static if (is (C == Table)) {
			_fileList.showSelection();
		} else static if (!is (C == Combo) && !is (C == CCombo)) {
			static assert (false);
		}
	}
	@property
	string[] allDirs() {
		string[] st;
		foreach (i; _defs.length .. _dirs.getItemCount()) {
			string t = _dirs.getItem(i);
			if (i == _tbl) {
				st ~= defDir;
			} else if (t == "/") {
				assert (_summ);
				st ~= nabs(_summ.scenarioPath);
			} else {
				assert (_summ);
				st ~= nabs(std.path.buildPath(_summ.scenarioPath, fromViewPath(t)));
			}
		}
		return st;
	}
	void refreshList(bool forceRefresh = false) {
		_fileList.removeAll();
		_fnone = false;
		if (_dirs.getSelectionIndex() < _defs.length) {
			auto dirs = allDirs;
			if (!dirs.length) {
				_fileList.setEnabled(false);
			} else {
				_fileList.setEnabled(true);
				__refreshList(dirs, forceRefresh);
				static if (is(C : Combo) || is(C : CCombo)) {
					_fileList.add(_prop.msgs.fileNone, 0);
					_fileList.select(0);
					_fnone = true;
				} else {
					_fileList.select(-1);
				}
			}
		} else if (_dirs.getSelectionIndex() == _tbl) {
			__refreshList(defDir, forceRefresh);
		} else if (_summ) {
			string st;
			if (_dirs.getText() == "/") {
				st = _summ.scenarioPath;
			} else {
				st = std.path.buildPath(_summ.scenarioPath, fromViewPath(_dirs.getText()));
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
			f = std.path.buildPath(dir, f);
			if (isDir(f)) {
				searchTarg(f, cut);
			}
		}
	}
	void refreshPaths(string select = null, bool forceRefresh = false) {
		int oldSel = _dirs.getSelectionIndex();
		if (oldSel < 0) oldSel = 0;
		string oldSelS = _dirs.getText();
		_dirs.removeAll();
		foreach (def; _defs) {
			_dirs.add(def);
		}
		auto tbl = defDir;
		_tbl = -1;
		if (hasTarg(tbl)) {
			_tbl = _dirs.getItemCount();
			_dirs.add(_prop.msgs.pathDef);
		}
		size_t cut = 0;
		if (_summ) {
			string st = _summ.scenarioPath;
			cut = st.length;
			static if (altDirSeparator.length) {
				if (!endsWith(st, dirSeparator) && !endsWith(st, altDirSeparator)) cut++;
			} else {
				if (!endsWith(st, dirSeparator)) cut++;
			}
			searchTarg(_summ.scenarioPath, cut);
		}
		if (!select) {
			void selectOld() {
				if (oldSel < _defs.length) {
					_dirs.select(oldSel);
				} else {
					int index = dirsIndexOf(oldSelS);
					if (index >= 0) {
						_dirs.select(index);
					} else if (_dirs.getItemCount() > 0) {
						_dirs.select(0);
					}
				}
			}
			bool def;
			if (isBinImg(_path)) {
				_dirs.select(_including);
			} else {
				auto p = _comm.skin.findPathF(_path, defExt, defDir, _summ ? _summ.scenarioPath : "", def);
				if (p.length > 0) {
					if (def) {
						if (_tbl == -1) {
							// ファイルが無い
							selectOld();
						} else {
							_dirs.select(_tbl);
						}
					} else if (_summ) {
						string pt = dirName(p);
						pt = pt.length <= cut ? dirSeparator.idup : pt[cut .. $];
						pt = toViewPath(pt);
						_dirs.select(dirsIndexOf(pt));
					}
				} else {
					selectOld();
				}
			}
		} else {
			select = toViewPath(select);
			_dirs.setText(select);
		}
		_selDir = _dirs.getSelectionIndex();
		refreshList(forceRefresh);
	}

	void __refPaths(Object sender, string parent) {
		if (this !is sender) {
			refreshPaths();
		}
		if (_refresh) _refresh();
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
			for (; i < _dirs.getItemCount(); i++) {
				string name = fromViewPath(_dirs.getItem(i));
				if (startsWith(name, o)) {
					string nName = std.path.buildPath(n, name[o.length .. $]);
					nName = toViewPath(nName);
					_dirs.setItem(i, nName);
					if (i == _dirs.getSelectionIndex()) {
						_dirs.setText(nName);
					}
				}
			}
		} else {
			if (o == _path) _path = n;
			int di = _dirs.getSelectionIndex();
			auto op = o;
			if (di >= 0 && cfnmatch(fromViewPath(_dirs.getItems()[di]), dirName(o))) {
				int index = flIndexOf(baseName(o));
				if (index >= 0) {
					string nName = baseName(n);
					static if (is(C : Table)) {
						_fileList.getItem(index).setText(nName);
					} else static if (is (C : Combo) || is (C : CCombo)) {
						_fileList.setItem(index, nName);
						_fileList.setText(nName);
					} else static assert (0);
				}
			}
		}
		if (_refresh) _refresh();
	}
	void __delPaths() {
		refreshPaths();
	}
	void __replPath(string from, string to) {
		if (_path == from) {
			refreshPaths();
		}
	}
	void refreshButtons() {
		_comm.refreshToolBar();
	}

	Props _prop;
	Commons _comm;
	D _dirs;
	Summary _summ;
	Button _dirBtn;
	IncSearch _incSearch;
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

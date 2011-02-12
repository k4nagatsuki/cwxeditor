
module cwx.editor.gui.dwt.materialselect;

import cwx.cwl;
import cwx.utils;
import cwx.summary;
import cwx.skin;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;

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
import org.eclipse.swt.widgets.List;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.dnd.DropTargetAdapter;

public:

enum MtType {
	CARD,
	BG_IMG,
	BGM,
	SE
}

class MaterialSelect(MtType Type, D, C) {
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

		_comm.refPaths.add(&__refPaths);
		_comm.refPath.add(&__refPath);
		_comm.delPaths.add(&__delPaths);
		_comm.replPath.add(&__replPath);
		_comm.refIgnorePaths.add(&refresh);
		_dirs.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
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
		static if (is (C == List)) {
			_fileList = new C(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL);
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
					scope (exit) dlg.dispose;
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
			string f = _fileList.getItem(_fileList.getSelectionIndex);
			if (_dirs.getSelectionIndex == _tbl) {
				return std.path.join(defDir, f);
			} else {
				return std.path.join(std.path.join(_summ ? _summ.scenarioPath : "", p), f);
			}
		}
		return "";
	}
	void path(string path) {
		_path = path;
		_oldPath = _path;
		refreshPaths;
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

private:
	static if (Type == MtType.CARD) {
		string defExt() {return _comm.skin.extImage;}
		string defDir() {return _comm.skin.tableDir;}
		bool isTarg(string p) {return _comm.skin.isCardImage(p);}
		bool hasTarg(string p) {return _comm.skin.hasCardImage(p);}
		string[] targs(string dir, bool re) {return _comm.skin.cards(dir, re);}
	} else static if (Type == MtType.BG_IMG) {
		string defExt() {return _comm.skin.extImage;}
		string defDir() {return _comm.skin.tableDir;}
		bool isTarg(string p) {return _comm.skin.isBgImage(p);}
		bool hasTarg(string p) {return _comm.skin.hasBgImage(p);}
		string[] targs(string dir, bool re) {return _comm.skin.tables(dir, re);}
	} else static if (Type == MtType.BGM) {
		string defExt() {return _comm.skin.extBgm;}
		string defDir() {return _comm.skin.bgmDir;}
		bool isTarg(string p) {return _comm.skin.isBGM(p);}
		bool hasTarg(string p) {return _comm.skin.hasBGM(p);}
		string[] targs(string dir, bool re) {return _comm.skin.musics(dir, re);}
	} else static if (Type == MtType.SE) {
		string defExt() {return _comm.skin.extSound;}
		string defDir() {return _comm.skin.seDir;}
		bool isTarg(string p) {return _comm.skin.isSE(p);}
		bool hasTarg(string p) {return _comm.skin.hasSE(p);}
		string[] targs(string dir, bool re) {return _comm.skin.sounds(dir, re);}
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
				_selDir = 0;
				_path = "";
				if (_refresh) _refresh();
			}
		}
	}
	class LSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			int index = _fileList.getSelectionIndex;
			if (index >= 0) {
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
					_path = std.path.join(p, _fileList.getItem(_fileList.getSelectionIndex));
					_selDir = _dirs.getSelectionIndex;
					if (_refresh) _refresh();
				}
			}
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
	int indexOf(T)(T list, string path) {
		foreach (i, s; list.getItems) {
			if (fnmatch(s, path)) {
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
		auto tgs = targs(path, forceRefresh);
		foreach (f; tgs) {
			_fileList.add(f);
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
		static if (is (C == List)) {
			_fileList.showSelection;
		} else static if (!is (C == Combo) && !is (C == CCombo)) {
			static assert (false);
		}
	}
	void refreshList(bool forceRefresh = false) {
		_fileList.removeAll;
		if (_dirs.getSelectionIndex < _defs.length) {
			if (_dirs.getItemCount == _defs.length) {
				_fileList.setEnabled = false;
			} else {
				string st = "";
				if (_tbl > -1) {
					st = defDir;
				} else if (_summ) {
					st = _dirs.getItem(_defs.length);
					if (st == "/") {
						st = _summ.scenarioPath;
					} else {
						st = std.path.join(_summ.scenarioPath, fromViewPath(st));
					}
				}
				if (st.length) {
					__refreshList(st, forceRefresh);
					static if (is(C : Combo) || is(C : CCombo)) {
						_fileList.add(_prop.msgs.fileNone, 0);
						_fileList.select = 0;
					} else {
						_fileList.select = -1;
					}
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
						auto pt = getDirName(p);
						pt = pt.length <= cut ? sep : pt[cut .. $];
						pt = toViewPath(pt);
						_dirs.select = dirsIndexOf(pt);
						assert (_dirs.getSelectionIndex >= 1);
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
			if (di >= 0 && fnmatch(fromViewPath(_dirs.getItems[di]), getDirName(o))) {
				int index = flIndexOf(getBaseName(o));
				if (index >= 0) {
					string nName = getBaseName(n);
					_fileList.setItem(index, nName);
					static if (is (C == Combo) || is (C == CCombo)) {
						_fileList.setText = nName;
					}
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
	C _fileList;
	void delegate() _refresh;
}


module cwx.editor.gui.dwt.directorywindow;

import cwx.summary;
import cwx.usecounter;
import cwx.utils;
import cwx.skin;

import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.splitpane;

import std.date;
import std.file;
import std.path;
import std.string;
import std.process;
import std.thread;

import dwt.DWT;
import dwt.custom.SashForm;
import dwt.widgets.Composite;
import dwt.widgets.Control;
import dwt.widgets.Combo;
import dwt.widgets.Display;
import dwt.widgets.Tree;
alias dwt.widgets.Text.Text WText;
import dwt.widgets.TreeItem;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.widgets.Shell;
import dwt.widgets.MessageBox;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.Label;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.events.ControlAdapter;
import dwt.events.ControlEvent;
import dwt.events.ShellAdapter;
import dwt.events.ShellEvent;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.KeyAdapter;
import dwt.events.KeyEvent;
import dwt.events.MouseListener;
import dwt.events.MouseEvent;
import dwt.graphics.Image;
import dwt.layout.FillLayout;
import dwt.layout.GridData;
import dwt.layout.GridLayout;
import dwt.dnd.DND;
import dwt.dnd.Transfer;
import dwt.dnd.FileTransfer;
import dwt.dnd.DragSource;
import dwt.dnd.DragSourceAdapter;
import dwt.dnd.DragSourceEvent;
import dwt.dnd.DropTarget;
import dwt.dnd.DropTargetAdapter;
import dwt.dnd.DropTargetEvent;
import dwt.dnd.Clipboard;
import dwt.program.Program;
import dwt.dwthelper.utils;

import dwtx.jface.dialogs.IDialogConstants;
import dwtx.jface.dialogs.Dialog;

private struct FC {
	string path;
	d_time time;
	int opEquals(FC fc) {
		return path == fc.path && time == fc.time;
	}
	int opCmp(FC fc) {
		int r = time - fc.time;
		return r == 0 ? std.string.cmp(path, fc.path) : r;
	}
	string toString() {
		return std.date.toUTCString(time) ~ "\t" ~ path;
	}
}

alias ArrayWrapperString FileNameObj;

class DirectoryWindow : TopLevelPanel, TCPD {
private:
	static if (fnmatch("A", "a")) {
		alias icmp comp;
	} else {
		alias cmp comp;
	}
	bool compFNameS(string a, string b) {
		auto ad = isdir(a);
		auto bd = isdir(b);
		if (ad && bd) return comp(getBaseName(a), getBaseName(b)) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		return comp(getBaseName(a), getBaseName(b)) < 0;
	}
	bool compFName(FileNameObj a, FileNameObj b) {
		return compFNameS(a.array, b.array);
	}
	bool revCompFName(FileNameObj a, FileNameObj b) {
		auto ad = isdir(a.array);
		auto bd = isdir(b.array);
		if (ad && bd) return comp(getBaseName(a.array), getBaseName(b.array)) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		return comp(getBaseName(a.array), getBaseName(b.array)) > 0;
	}
	bool compFExt(FileNameObj a, FileNameObj b) {
		auto ad = isdir(a.array);
		auto bd = isdir(b.array);
		if (ad && bd) return comp(getBaseName(a.array), getBaseName(b.array)) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int r = comp(getExt(a.array), getExt(b.array));
		return r != 0 ? r < 0 : comp(getBaseName(a.array), getBaseName(b.array)) < 0;
	}
	bool revCompFExt(FileNameObj a, FileNameObj b) {
		auto ad = isdir(a.array);
		auto bd = isdir(b.array);
		if (ad && bd) return comp(getBaseName(a.array), getBaseName(b.array)) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int r = comp(getExt(a.array), getExt(b.array));
		return r != 0 ? r > 0 : comp(getBaseName(a.array), getBaseName(b.array)) < 0;
	}
	bool compFCount(FileNameObj a, FileNameObj b) {
		auto ad = isdir(a.array);
		auto bd = isdir(b.array);
		if (ad && bd) return comp(getBaseName(a.array), getBaseName(b.array)) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int ac = _summ.useCounter.path.get(toPathId(toRelPath(a.array)));
		int bc = _summ.useCounter.path.get(toPathId(toRelPath(b.array)));
		int r = ac - bc;
		return r != 0 ? r < 0 : compFName(a, b);
	}
	bool revCompFCount(FileNameObj a, FileNameObj b) {
		auto ad = isdir(a.array);
		auto bd = isdir(b.array);
		if (ad && bd) return comp(getBaseName(a.array), getBaseName(b.array)) < 0;
		if (!ad && bd) return false;
		if (ad && !bd) return true;
		int ac = _summ.useCounter.path.get(toPathId(toRelPath(a.array)));
		int bc = _summ.useCounter.path.get(toPathId(toRelPath(b.array)));
		int r = ac - bc;
		return r != 0 ? r > 0 : compFName(a, b);
	}
	FC[] allPaths() {
		FC[] fcs;
		if (_summ) {
			void list(string path) {
				FC fc;
				fc.path = path;
				if (.isdir(path)) {
					fc.time = d_time_nan;
					fcs ~= fc;
					foreach (c; clistdir(path)) {
						list(std.path.join(path, c));
					}
				} else {
					fc.time = lastModified(path);
					fcs ~= fc;
				}
			}
			list(_summ.scenarioPath);
		}
		return fcs.sort;
	}
	FC[] _checkPaths;
	void refCheckPaths() {
 		_checkPaths = allPaths;
	}

	bool isDef(string p, bool isDir) {
		if (_summ.legacy) {
			return std.path.fnmatch(getExt(p), "wid") || std.path.fnmatch(getExt(p), "wsm")
				|| (_summ.useTemp && std.path.fnmatch(getBaseName(p), "cwxeditor.lock"));
		} else {
			string fl = getBaseName(p);
			if (isDir) {
				if (isScenarioSystemDir(fl)) {
					return true;
				}
			} else {
				if (std.path.fnmatch(fl, "Summary.xml") || std.path.fnmatch(fl, "cwxeditor.lock")) {
					return true;
				}
			}
		}
		return false;
	}

	void refreshDirs(string sel) {
		_dirs.setRedraw = false;
		int hs = _dirs.getHorizontalBar.getSelection;
		auto topItm = _dirs.getTopItem;
		string top = null;
		if (topItm) {
			top = (cast(FileNameObj) topItm.getData).array;
			if (!.exists(top)) top = null;
		}
		TreeItem nTopItm = null;
		_dirs.removeAll;
		if (!addp(_dirs, _summ.scenarioPath, sel ? nabs(sel) : null, top, nTopItm)) {
			_dirs.setSelection(_dirs.getItems[0]);
		}
		_dirs.setRedraw = true;
		if (nTopItm) _dirs.setTopItem = nTopItm;
		_dirs.getHorizontalBar.setSelection = hs;
		_dirs.showSelection;
	}
	void refreshFiles(string[] sels) {
		_files.setRedraw = false;
		scope (exit) _files.setRedraw = true;
		scope (exit) fimageThrStart;
		scope selset = new HashSet!(string);
		if (sels) {
			foreach (path; sels) {
				if (.exists(path)) {
					selset.add(nabs(path));
				}
			}
		}
		if (_dirs.getSelection.length > 0) {
			_files.deselectAll;
			auto path = (cast(FileNameObj) _dirs.getSelection[0].getData).array;
			FileNameObj[] list;
			foreach (ref f; clistdir(path)) {
				list ~= new FileNameObj(std.path.join(path, f));
			}
			if (_files.getSortColumn is _sortName.column) {
				if (_files.getSortDirection == DWT.UP) {
					list = .sort(list, &compFName);
				} else {
					assert (_files.getSortDirection == DWT.DOWN);
					list = .sort(list, &revCompFName);
				}
			} else if (_files.getSortColumn is _sortExt.column) {
				if (_files.getSortDirection == DWT.UP) {
					list = .sort(list, &compFExt);
				} else {
					assert (_files.getSortDirection == DWT.DOWN);
					list = .sort(list, &revCompFExt);
				}
			} else {
				assert (_files.getSortColumn is _sortCount.column);
				if (_files.getSortDirection == DWT.UP) {
					list = .sort(list, &compFCount);
				} else {
					assert (_files.getSortDirection == DWT.DOWN);
					list = .sort(list, &revCompFCount);
				}
			}
			int count = 0;
			int oldC = _files.getItemCount;
			bool sp = cast(bool) std.path.fnmatch(nabs(path), nabs(_summ.scenarioPath));
			foreach (i, p; list) {
				if (sp) {
					if (isDef(p.array, cast(bool) .isdir(p.array))) continue;
				}
				TableItem itm;
				if (count < oldC) {
					itm = _files.getItem(count);
				} else {
					itm = new TableItem(_files, DWT.NONE);
				}
				auto img = fimage(p.array);
				itm.setImage(0, img);
				if (.isdir(p.array)) {
					itm.setText(0, getBaseName(p.array));
					itm.setText(1, "");
					itm.setText(2, "");
				} else {
					itm.setText(0, getBaseName(getName(p.array)));
					itm.setText(1, getExt(p.array));
					itm.setText(2, to!(string)
						(_summ.useCounter.path.get(toPathId(toRelPath(p.array)))));
				}
				auto fpath = nabs(p.array);
				itm.setData = new FileNameObj(fpath);
				if (selset.size > 0) {
					if (selset.contains(nabs(p.array))) {
						_files.select = i;
					}
				}
				count++;
			}
			if (count < oldC) _files.remove(count, oldC - 1);
			if (count > 0 && !sels) {
				_files.setTopIndex = 0;
			}
			_files.showSelection;
		} else {
			_files.removeAll;
		}
	}
	bool addp(T)(T parItm, string path, string sel, string top, ref TreeItem topItm) {
		auto itm = new TreeItem(parItm, DWT.NONE);
		auto full = nabs(path);
		if (fnmatch("A", "a") ? _cuts.contains(toLower(full)) : _cuts.contains(full)) {
			itm.setImage = _sImgFolder;
		} else {
			itm.setImage = _prop.images.folder;
		}
		bool sp = cast(bool) std.path.fnmatch(full, nabs(_summ.scenarioPath));
		if (sp) {
			itm.setText = "Scenario";
		} else {
			itm.setText = getBaseName(path);
		}
		itm.setData = new FileNameObj(full);
		string[] subs;
		foreach (p; clistdir(path)) {
			p = std.path.join(path, p);
			if (isdir(p)) subs ~= p;
		}
		subs = .sort(subs, &compFNameS);
		bool s = false;
		foreach (p; subs) {
			if (sp) {
				if (isDef(p, cast(bool) isdir(p))) continue;
			}
			s |= addp(itm, p, sel, top, topItm);
		}
		if (sel) {
			auto absp = nabs(path);
			if (std.path.fnmatch(sel, absp)) {
				itm.getParent.setSelection(itm);
				s = true;
			}
			if (top && !topItm && std.path.fnmatch(nabs(top), absp)) {
				topItm = itm;
			}
		}
		return s;
	}

	// isCardImage()は時間がかかるので別スレッドで実行。
	private Display _display = null;
	private Thread _fimgThr = null;
	private bool _fimgStop = false;
	private string[] _fimgPs;
	private void fimageThrStart() {
		fimageThrStop;
		foreach (itm; _files.getItems) {
			auto img = itm.getImage;
			if (img is _prop.images.backs || img is _sImgBacks) {
				_fimgPs ~= (cast(FileNameObj) itm.getData).array;
			}
		}
		assert (!_fimgThr);
		_display = Display.getCurrent;
		_fimgThr = new Thread(&fimageThr);
		_fimgThr.start;
	}
	private void fimageThrStop() {
		if (_fimgThr) {
			_fimgStop = true;
			_fimgThr.wait;
			_fimgThr = null;
		}
	}
	private class FImgUpdThr : Runnable {
		private string _file;
		this (string file) {_file = file;}
		override void run() {
			try {
				foreach (itm; _files.getItems) {
					if (!itm.isDisposed && fnmatch((cast(FileNameObj) itm.getData).array, _file)) {
						if (isCutted(_file)) {
							itm.setImage(_sImgCards);
						} else {
							itm.setImage(_prop.images.cards);
						}
					}
				}
				_files.redraw;
			} catch {}
		}
	}
	private int fimageThr() {
		try {
			_fimgStop = false;
			auto skin = findSkin(_prop, _summ);
			foreach (file; _fimgPs) {
				if (_fimgStop) break;
				if (skin.isCardImage(file)) {
					_display.asyncExec(new FImgUpdThr(file));
				}
			}
			_fimgPs.length = 0u;
			return 0;
		} catch {
			return -1;
		}
	}
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
		} else if (img is _prop.images.unknown || img is _sImgUnknown) {
			return _prop.images.unknown;
		}
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
		} else if (img is _prop.images.unknown || img is _sImgUnknown) {
			return _sImgUnknown;
		}
	}
	Image fimage(string file) {
		auto skin = findSkin(_prop, _summ);
		if (isCutted(file)) {
			return sfimage(file);
		}
		// isCardImage()は時間がかかるので別スレッドで実行
		if (.isdir(file)) {
			return _prop.images.folder;
		} else if (skin.isBgImage(file)) {
			return _prop.images.backs;
		} else if (skin.isBGM(file)) {
			return _prop.images.bgm;
		} else if (skin.isSE(file)) {
			return _prop.images.se;
		} else {
			return _prop.images.unknown;
		}
	}
	Image sfimage(string file) {
		auto skin = findSkin(_prop, _summ);
		// isCardImage()は時間がかかるので別スレッドで実行
		if (.isdir(file)) {
			return _sImgFolder;
		} else if (skin.isBgImage(file)) {
			return _sImgBacks;
		} else if (skin.isBGM(file)) {
			return _sImgBgm;
		} else if (skin.isSE(file)) {
			return _sImgSe;
		} else {
			return _sImgUnknown;
		}
	}
	private bool isCutted(string file) {
		return fnmatch("A", "a")
			? _cuts.contains(toLower(nabs(file)))
			: _cuts.contains(nabs(file));
	}
	string toRelPath(string file) {
		file = nabs(file);
		auto sc = nabs(_summ.scenarioPath);
		return file.length == sc.length ? "" : file[(sc ~ sep).length .. $];
	}
	class DirsSelection : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshFiles([]);
		}
	}
	class FileSelect : KeyAdapter, MouseListener {
	private:
		void select() {
			int index = _files.getSelectionIndex;
			if (index >= 0) {
				auto path = (cast(FileNameObj) _files.getItem(index).getData).array;
				if (.isdir(path)) {
					foreach (itm; _dirs.getSelection[0].getItems) {
						if (std.path.fnmatch((cast(FileNameObj) itm.getData).array, path)) {
							_dirs.setSelection = itm;
							refreshFiles([]);
							return;
						}
					}
					assert (0);
				}
			}
		}
	public override:
		void mouseUp(MouseEvent e) {}
		void mouseDown(MouseEvent e) {}
		void mouseDoubleClick(MouseEvent e) {
			if ((cast(Control) e.widget).isFocusControl && e.button == 1) {
				select;
			}
		}
		void keyPressed(KeyEvent e) {
			if (e.character == DWT.CR) {
				select;
			}
		}
	}

	class FilesDrag(C) : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource).getControl.isFocusControl;
		}
		override void dragSetData(DragSourceEvent e) {
			auto itms
				= (cast(C) (cast(DragSource) e.getSource).getControl).getSelection;
			if (itms.length == 0) return;
			string[] data;
			data.length = itms.length;
			foreach (i, itm; itms) {
				data[i] = (cast(FileNameObj) itm.getData).array;
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
				clearCut;
				_summ.changed;
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
				auto toparP = e.item ? (cast(FileNameObj) e.item.getData).array : selDirPath;
			} else static if (is (C == Tree)) {
				auto toparP = (cast(FileNameObj) e.item.getData).array;
			} else {
				static assert (0);
			}
			if (!toparP) return;
			string topar = .isdir(toparP) ? toparP : getDirName(toparP);
			if (__paste(topar, files, true, fromOut)) {
				e.detail = fromOut ? DND.DROP_COPY : DND.DROP_NONE;
				clearCut;
			}
		}
	}
	bool __paste(string targ, FileNames files, bool move, out bool fromOut) {
		if (files && files.array.length > 0) {
			fromOut = false;
			scope pfull = nabs(_summ.scenarioPath);
			bool top = cast(bool) std.path.fnmatch(nabs(targ), pfull);
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
					auto to = std.path.join(targ, getBaseName(file));
					if (top) {
						if (isDef(to, cast(bool) isdir(file))) continue;
					}
					if (.exists(to)) {
						bool tisdir = cast(bool) isdir(to);
						if (tisdir ==  cast(bool) isdir(file)) {
							auto par = getDirName(file);
							if (std.path.fnmatch(par, targ)) {
								if (!move && !(fnmatch("A", "a")
										? _cuts.contains(toLower(file)) : _cuts.contains(file))) {
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
						(_win.getShell, DWT.ICON_QUESTION | DWT.YES | DWT.NO | DWT.CANCEL);
					scope (exit) dlg.dispose;
					dlg.setText = _prop.msgs.dlgTitQuestion;
					dlg.setMessage = _prop.msgs.dlgMsgDropOverWriteFiles(exists);
					int r = dlg.open;
					if (r == DWT.YES) {
						over = true;
					} else if (r == DWT.CANCEL) {
						return false;
					}
				}
				paths = .sort(paths, &compFNameS);
				string dir = null;
				string[] selfs;
				foreach (file; paths) {
					bool fout = !(fnmatch("A", "a")
						? _cuts.contains(toLower(file))
						: _cuts.contains(file))
						&& (!move || !hasPath(pfull, file));
					fromOut |= fout;
					void copy(string parent, string from) {
						auto to = std.path.join(parent, getBaseName(from));
						if (.exists(to) && cast(bool) isdir(to) == cast(bool) isdir(from) && !over) {
							return;
						}
						if (isdir(from)) {
							if (!.exists(to)) mkdir(to);
							foreach (child; clistdir(from)) {
								copy(to, std.path.join(from, child));
							}
							if (!dir) dir = to;
							if (!fout) {
								std.file.remove(from);
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
								_summ.useCounter.change(toPathId(p1), toPathId(p2), true);
								_comm.refPath.call(p1, p2, false);
								rename(from, to);
							}
							if (std.path.fnmatch(parent, targ)) selfs ~= to;
						}
					}
					copy(targ, file);
				}
				foreach (file; copys) {
					void renameCopy(string parent, string from) {
						bool isdir = cast(bool) isdir(from);
						string to = std.path.join(parent, getBaseName(from));
						to = createNewFileName(to, isdir);
						if (isdir) {
							mkdir(to);
							foreach (child; clistdir(from)) {
								renameCopy(to, std.path.join(from, child));
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
				_summ.changed;
				return true;
			} catch (Exception e) {
				debugln(e);
			}
		}
		return false;
	}
	string selDirPath() {
		if (_dirs.getSelection.length > 0) {
			return (cast(FileNameObj) _dirs.getSelection[0].getData).array;
		}
		return null;
	}
	string[] selFiles() {
		string[] r;
		auto sels = _files.getSelection;
		r.length = sels.length;
		foreach (i, itm; sels) {
			r[i] = (cast(FileNameObj) itm.getData).array;
		}
		return r;
	}

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
	Image _sImgFolder, _sImgCards, _sImgBacks, _sImgBgm, _sImgSe, _sImgUnknown;

	Props _prop;
	Summary _summ = null;

	Commons _comm;

	string pathRename(T)(T itm, string newName) {
		clearCut;
		auto path = (cast(FileNameObj) itm.getData).array;
		string frp = toRelPath(path);
		string frd = nabs(path);
		newName = std.string.replace(newName, sep, "");
		newName = std.string.replace(newName, altsep, "");
		auto to = std.path.join(getDirName(path), newName);
		bool isdir = cast(bool) .isdir(path);
		if (!isdir && getExt(path).length > 0) {
			to = addExt(to, getExt(path));
		}
		if (.exists(to) && cast(bool) .isdir(to) == cast(bool) .isdir(path)) return null;
		try {
			rename(path, to);
			_summ.changed;
		} catch {
			// 不正な名前
			return null;
		}
		string trp = toRelPath(to);
		if (isdir) {
			string tod = nabs(to);
			void pchange(string file) {
				auto oldP = frd ~ nabs(file)[tod.length .. $];
				if (.isdir(file)) {
					foreach (c; clistdir(file)) {
						pchange(std.path.join(file, c));
					}
				} else {
					string p1 = toRelPath(oldP);
					string p2 = toRelPath(file);
					_summ.useCounter.change(toPathId(p1), toPathId(p2));
				}
			}
			foreach (c; clistdir(path)) {
				pchange(std.path.join(path, c));
			}
		} else {
			string p1 = frp;
			string p2 = toRelPath(to);
			_summ.useCounter.change(toPathId(p1), toPathId(p2));
			_comm.refPath.call(p1, p2, false);
		}
		itm.setData = new FileNameObj(to);
		static if (is (T == TreeItem)) {
			itm.setText = getBaseName(getName(to));
		} else static if (is (T == TableItem)) {
			itm.setText(0, .isdir(to) ? getBaseName(to) : getBaseName(getName(to)));
		} else {
			static assert (0);
		}
		_comm.refPath.call(frp, trp, isdir);
		return to;
	}
	void dirsEditEnd(TreeItem itm, Control c) {
		string text = (cast(WText) c).getText;
		if (text.length == 0) return;
		auto from = (cast(FileNameObj) itm.getData).array;
		string frd = nabs(from);
		auto to = pathRename(itm, text);
		if (to) {
			string tod = nabs(to);
			void drename(TreeItem itm) {
				itm.setData = new FileNameObj(tod ~ (cast(FileNameObj) itm.getData).array[frd.length .. $]);
				foreach (c; itm.getItems) {
					drename(c);
				}
			}
			foreach (cc; itm.getItems) {
				drename(cc);
			}
			foreach (t; _files.getItems) {
				t.setData = new FileNameObj(std.path.join(tod, getBaseName((cast(FileNameObj) t.getData).array)));
			}
		}
	}
	Control dirsCreateEditor(TreeItem itm) {
		return itm.getParentItem ? createTextEditor(_dirs, itm.getText) : null;
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
			if (selDirPath && std.path.fnmatch(toRelPath(selDirPath), parent)) {
				refreshFiles(selFiles);
			}
		}
	}

	void __refreshUseCount() {
		foreach (itm; _files.getItems) {
			auto file = (cast(FileNameObj) itm.getData).array;
			if (isdir(file)) continue;
			auto c = _summ.useCounter.path.get(toPathId(toRelPath(file)));
			itm.setText(2, to!(string)(c));
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
		_comm.save.call(_win.getShell);
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
			string sp = _summ ? _summ.scenarioPath : getcwd;
			auto cwd = getcwd;
			string wd = OuterTool.parse(_tool.workDir, file, sp);
			if (wd.length > 0) {
				if (!std.path.isabs(wd)) {
					wd = std.path.join(std.path.getDirName(_prop.parent.appPath), wd);
				}
			} else {
				wd = getDirName(_prop.parent.appPath);
			}
			auto cmd = OuterTool.parse(_tool.command, file, sp);
			if (!exec(cmd, wd)) {
				MessageBox.showWarning
					(_prop.msgs.errorExec(_tool.name),
					_prop.msgs.dlgTitWarning, _win.getShell);
			}
		}
		this(Menu menu, OuterTool tool) {
			createMenuItem(menu, tool.name, null, &run);
			_tool = tool;
		}
	}
	void createFilesMenu() {
		if (_files.getMenu) _files.getMenu.dispose;
		auto menu = new Menu(_win.getShell, DWT.POP_UP);
		createMenuItem(menu, _prop.msgs.menuReplacePath, _prop.images.menuReplacePath, &replace);
		new MenuItem(menu, DWT.SEPARATOR);
		createMenuItem(menu, _prop.msgs.menuNewFolder, _prop.images.menuNewFolder, &createDirFiles);
		new MenuItem(menu, DWT.SEPARATOR);
		foreach (tool; _prop.var.etc.outerTools) {
			new Exec(menu, tool);
		}
		if (_prop.var.etc.outerTools.length > 0) new MenuItem(menu, DWT.SEPARATOR);
		appendMenuTCPD(_prop, menu, this, true, true, true, true);
		_files.setMenu(menu);
	}
	string createDir() {
		auto dir = selDirPath;
		if (!dir) return null;
		string fp;
		createNewName(_prop.msgs.newFolder, (string name) {
			string p = std.path.join(dir, name);
			fp = p;
			if (!.exists(fp)) {
				mkdir(fp);
				fp = nabs(fp);
				_summ.changed;
				return true;
			} else {
				return false;
			}
		}, false);
		return fp;
	}
	void __createDir() {
		if (_files.isFocusControl) {
			createDirFiles;
		} else {
			createDirDirs;
		}
	}
	void createDirDirs() {
		auto fp = createDir;
		if (!fp) return;
		refreshDirs(fp);
		refreshFiles(null);
		_dirsEdit.startEdit;
	}
	void createDirFiles() {
		auto fp = createDir;
		if (!fp) return;
		auto files = selFiles ~ fp;
		refreshDirs(selDirPath);
		refreshFiles(files);
		foreach (itm; _files.getItems) {
			if (std.path.fnmatch((cast(FileNameObj) itm.getData).array, fp)) {
				_filesEdit.startEdit(itm);
			}
		}
	}
	void replace() {
		if (_files.getSelectionIndex >= 0) {
			__replace(toRelPath((cast(FileNameObj) _files.getItem(_files.getSelectionIndex).getData).array));
		} else {
			__replace(null);
		}
	}
	void __replace(string sel) {
		if (!_summ || !_win || _win.isDisposed) return;
		string[] from;
		foreach (path; _summ.useCounter.path.keys) {
			auto p = cast(string) path;
			if (!path.isBinImg) from ~= p;
		}
		string[] to;
		auto skin = findSkin(_prop, _summ);
		void addTo(string path) {
			FileNameObj[] list;
			foreach (p; clistdir(path)) {
				list ~= new FileNameObj(std.path.join(path, p));
			}
			list = .sort(list, &compFExt);
			foreach (p; list) {
				if (.isdir(p.array)) {
					addTo(p.array);
				} else if (skin.isCardImage(p.array)
						|| skin.isBgImage(p.array)
						|| skin.isBGM(p.array)
						|| skin.isSE(p.array)) {
					to ~= toRelPath(p.array);
				}
			}
		}
		addTo(_summ.scenarioPath);
		foreach (p; skin.tables) {
			to ~= p;
		}
		foreach (p; skin.musics) {
			to ~= p;
		}
		foreach (p; skin.sounds) {
			to ~= p;
		}
		auto dlg = new ReplacePathDialog(_prop, _win.getShell, from, to, sel);
		if (IDialogConstants.OK_ID == dlg.open) {
			_summ.useCounter.change(toPathId(dlg.from), toPathId(dlg.to), true);
			_comm.replPath.call(dlg.from, dlg.to);
			_comm.refUseCount.call;
		}
	}
	class SClose : ShellAdapter {
		override void shellClosed(ShellEvent e) {
			(cast(Shell) e.widget).setVisible = false;
			e.doit = false;
			_prop.var.dirWin.visible = false;
			_prop.var.etc.filesSortDirection = _files.getSortDirection;
			if (_files.getSortColumn is _sortName.column) {
				_prop.var.etc.filesSortColumn = 0;
			} else if (_files.getSortColumn is _sortExt.column) {
				_prop.var.etc.filesSortColumn = 1;
			} else if (_files.getSortColumn is _sortCount.column) {
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
			_sImgFolder.dispose;
			_sImgCards.dispose;
			_sImgBacks.dispose;
			_sImgBgm.dispose;
			_sImgSe.dispose;
			_sImgUnknown.dispose;
		}
	}
	private SDListener _sdl;
	class SDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_prop.var.etc.directorySashL = _sash.getWeights[0];
			_prop.var.etc.directorySashR = _sash.getWeights[1];
			_prop.var.etc.directorySashV = (_sash.getStyle & DWT.VERTICAL) != 0;
		}
	}
public:
	this(Commons comm, Props prop, Composite parent) {
		_prop = prop;
		_comm = comm;
		if (parent) construct(parent);
	}
	void reconstruct(Composite parent) {
		if (_win && !_win.isDisposed) return;
		construct(parent);
		if (_summ) refresh(_summ);
	}
	private void construct(Composite parent) {
		_cuts = new typeof(_cuts);
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		if (parShl) {
			shell = new Shell(parShl, DWT.SHELL_TRIM);
			shell.setImage = _prop.images.app;
			shell.addShellListener(new SClose);
			_win = shell;
		} else {
			_win = new Composite(parent, DWT.NONE);
		}
		_win.setData = new TLPData(this);
		_win.setLayout = windowGridLayout(1, true);
		_comm.refScenarioName.add(&__refreshTitle);
		_comm.refScenarioPath.add(&__refreshTitle);
		_comm.refUseCount.add(&__refreshUseCount);
		_comm.refPaths.add(&__refPaths);
		_comm.delPaths.add(&__delPaths);
		_comm.saved.add(&refCheckPaths);
		_comm.replText.add(&__refreshTitle);
		_sImgFolder = skeletonImage(_prop.images.folder);
		_sImgCards = skeletonImage(_prop.images.cards);
		_sImgBacks = skeletonImage(_prop.images.backs);
		_sImgBgm = skeletonImage(_prop.images.bgm);
		_sImgSe = skeletonImage(_prop.images.se);
		_sImgUnknown = skeletonImage(_prop.images.unknown);
		_win.addDisposeListener(new DListener);
		if (shell) {
			auto bar = new Menu(shell, DWT.BAR);

			auto mf = createMenu(bar, _prop.msgs.menuFile);
			createMenuItem(mf, _prop.msgs.menuOpenDirectory, _prop.images.folder, &openDirectory);
			new MenuItem(mf, DWT.SEPARATOR);
			createMenuItem(mf, _prop.msgs.menuSave, _prop.images.menuSave, &saveScenario);
			new MenuItem(mf, DWT.SEPARATOR);
			createMenuItem(mf, _prop.msgs.menuCloseWin, _prop.images.menuCloseWin, &shell.close);

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			createMenuItem(me, _prop.msgs.menuReplacePath, _prop.images.menuReplacePath, &replace);
			new MenuItem(me, DWT.SEPARATOR);
			createMenuItem(me, _prop.msgs.menuNewFolder, _prop.images.menuNewFolder, &__createDir);
			new MenuItem(me, DWT.SEPARATOR);
			appendMenuTCPD(_prop, me, this, true, true, true, true);

			auto mv = createMenu(bar, _prop.msgs.menuView);
			createMenuItem(mv, _prop.msgs.menuRefresh, _prop.images.menuRefresh, &__refresh);
			new MenuItem(mv, DWT.SEPARATOR);
			createMenuItem(mv, _prop.msgs.menuChangeVH, _prop.images.menuChangeVH, &changeVHSide);

			shell.setMenuBar = bar;
		} else {
			appendMenuTCPD(_prop, this, this, true, true, true, true);
			putMenuAction(_prop.msgs.menuReplacePath, _prop.msgs.ttReplacePath, &replace);
			putMenuAction(_prop.msgs.menuRefresh, _prop.msgs.ttRefresh, &__refresh);
		}
		void setupToolBar(ToolBar bar) {
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

			createToolItem(bar, _prop.msgs.ttOpenDirectory, _prop.images.folder, &openDirectory);
			if (shell) {
				new ToolItem(bar, DWT.SEPARATOR);
				createToolItem(bar, _prop.msgs.ttRefresh, _prop.images.menuRefresh, &__refresh);
				new ToolItem(bar, DWT.SEPARATOR);
				createToolItem(bar, _prop.msgs.ttReplacePath, _prop.images.menuReplacePath, &replace);
			}
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttNewFolder, _prop.images.menuNewFolder, &__createDir);
			if (shell) {
				new ToolItem(bar, DWT.SEPARATOR);
				createToolItem(bar, _prop.msgs.ttCut, _prop.images.menuCut, &cut);
				createToolItem(bar, _prop.msgs.ttCopy, _prop.images.menuCopy, &copy);
				createToolItem(bar, _prop.msgs.ttPaste, _prop.images.menuPaste, &paste);
				createToolItem(bar, _prop.msgs.ttDel, _prop.images.menuDel, &del);
			}
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttChangeVH, _prop.images.menuChangeVH, &changeVHSide);
		}
		if (shell) {
			setupToolBar(new ToolBar(_win, DWT.FLAT));
			_sash = new SplitPane(_win, _prop.var.etc.directorySashV ? DWT.VERTICAL : DWT.HORIZONTAL);
			_sash.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto dirsComp = new Composite(_sash, DWT.NONE);
			dirsComp.setLayout = new FillLayout;
			_dirs = new Tree(dirsComp, DWT.SINGLE | DWT.BORDER | DWT.VIRTUAL);
			_sash.setControl1 = dirsComp;
		} else {
			_sash = new SplitPane(_win, _prop.var.etc.directorySashV ? DWT.VERTICAL : DWT.HORIZONTAL);
			_sash.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto dirsComp = new Composite(_sash, DWT.NONE);
			dirsComp.setLayout = zeroGridLayout(1, true);
			setupToolBar(new ToolBar(dirsComp, DWT.FLAT));
			_dirs = new Tree(dirsComp, DWT.SINGLE | DWT.BORDER | DWT.VIRTUAL);
			_dirs.setLayoutData = new GridData(GridData.FILL_BOTH);
			_sash.setControl1 = dirsComp;
		}
		{
			_dirs.addSelectionListener(new DirsSelection);
			_dirsEdit = new TreeEdit(_dirs, &dirsEditEnd, &dirsCreateEditor);

			auto drop = new DropTarget
				(_dirs, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new FilesDrop!(Tree));
			auto drag = new DragSource
				(_dirs, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE);
			drag.setTransfer([FileTransfer.getInstance]);
			drag.addDragListener(new FilesDrag!(Tree));

			auto menu = new Menu(_win.getShell, DWT.POP_UP);
			createMenuItem(menu, _prop.msgs.menuNewFolder, _prop.images.menuNewFolder, &createDirDirs);
			new MenuItem(menu, DWT.SEPARATOR);
			appendMenuTCPD(_prop, menu, this, true, true, true, true);
			_dirs.setMenu(menu);
		}
		auto fComp = new Composite(_sash, DWT.NONE);
		fComp.setLayout = new FillLayout;
		_files = new Table(fComp, DWT.MULTI | DWT.FULL_SELECTION | DWT.BORDER | DWT.VIRTUAL);
		_sash.setControl2 = fComp;
		{
			_files.setHeaderVisible = true;
			auto namec = new TableColumn(_files, DWT.NONE);
			namec.setText = _prop.msgs.fileName;
			saveColumnWidth!("prop.var.etc.fileNameColumn")(_prop, namec);
			auto extc = new TableColumn(_files, DWT.NONE);
			extc.setText = _prop.msgs.fileExt;
			saveColumnWidth!("prop.var.etc.fileExtColumn")(_prop, extc);
			auto cc = new TableColumn(_files, DWT.NONE);
			cc.setText = _prop.msgs.fileCount;
			saveColumnWidth!("prop.var.etc.fileCountColumn")(_prop, cc);
			_filesEdit = new TableTextEdit(_files, 0, &filesEditEnd);

			auto fs = new FileSelect;
			_files.addKeyListener(fs);
			_files.addMouseListener(fs);
			auto drop = new DropTarget
				(_files, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new FilesDrop!(Table));
			auto drag = new DragSource
				(_files, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE);
			drag.setTransfer([FileTransfer.getInstance]);
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
			st.doSort(_prop.var.etc.filesSortDirection);

			_comm.refOuterTools.add(&createFilesMenu);
			_files.addDisposeListener(new FDListener);
			createFilesMenu;
		}
		_sash.setWeights([_prop.var.etc.directorySashL, _prop.var.etc.directorySashR]);
		_sdl = new SDListener;
		_sash.addDisposeListener(_sdl);
		if (shell) {
			shell.pack;
			scope wp = shell.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			int width = _prop.var.dirWin.width == DWT.DEFAULT
				? wp.x : _prop.var.dirWin.width;
			int height = _prop.var.dirWin.height == DWT.DEFAULT
				? wp.y : _prop.var.dirWin.height;
			int x = _prop.var.dirWin.x == DWT.DEFAULT
				? shell.getBounds.x : _prop.var.dirWin.x + shell.getParent.getBounds.x;
			int y = _prop.var.dirWin.y == DWT.DEFAULT
				? shell.getBounds.y : _prop.var.dirWin.y + shell.getParent.getBounds.y;
			intoDisplay(x, y, width, height);
			shell.setBounds(x, y, width, height);
			shell.setMaximized = _prop.var.dirWin.maximized;
			shell.setMinimized = _prop.var.dirWin.minimized;
			shell.addControlListener(new SCListener);
		}
	}
	private class SCListener : ControlAdapter {
		override void controlMoved(ControlEvent e) {
			saveWin;
		}
		override void controlResized(ControlEvent e) {
			saveWin;
		}
	}
	private void saveWin() {
		auto win = cast(Shell) _win;
		if (win) {
			if (!win.getMaximized && !win.getMinimized) {
				_prop.var.dirWin.width = win.getSize.x;
				_prop.var.dirWin.height = win.getSize.y;
				_prop.var.dirWin.x = win.getBounds.x - win.getParent.getBounds.x;
				_prop.var.dirWin.y = win.getBounds.y - win.getParent.getBounds.y;
			}
			_prop.var.dirWin.maximized = win.getMaximized;
			_prop.var.dirWin.minimized = win.getMinimized;
		}
	}

	Composite shell() {return _win;}

	string title() {
		auto shl = cast(Shell) _win;
		if (shl) {
			return _prop.msgs.dirWindowName(_summ);
		}
		return _prop.msgs.dirTabName(_summ);
	}

	private void changeVHSide() {
		_sash.removeDisposeListener(_sdl);
		_sash = .changeVHSide(_sash);
		_sash.addDisposeListener(_sdl);
	}

	void refresh(Summary summ) {
		_summ = summ;
		if (_win && !_win.isDisposed) {
			refreshDirs(std.path.join(_summ.scenarioPath, findSkin(_prop, summ).materialPath));
			refreshFiles(null);
			refCheckPaths;
			__refreshTitle;
		}
	}

	bool isChanged() {
		return _summ.isChanged || _checkPaths != allPaths;
	}

	private void clearCut() {
		_cuts.clear;
		void titm(TreeItem itm) {
			if (itm.getImage is _sImgFolder) {
				itm.setImage = _prop.images.folder;
			}
			foreach (child; itm.getItems) {
				titm(child);
			}
		}
		foreach (itm; _dirs.getItems) {
			titm(itm);
		}
		foreach (itm; _files.getItems) {
			auto img = fimage(itm.getImage);
			if (itm.getImage !is img) {
				itm.setImage = img;
			}
		}
	}

	void openDirectory() {
		auto dir = selDirPath;
		if (dir) openFolder(dir);
	}

	override void cut() {
		if (!canDoTCPD) return;
		if (_dirs.isFocusControl) {
			if (_dirs.getSelection.length == 0) return;
			if (!_dirs.getSelection[0].getParentItem) return;
		}
		if (__copy) {
			if (_dirs.isFocusControl) {
				auto dir = selDirPath;
				_dirs.getSelection[0].setImage = sfimage(dir);
				static if (fnmatch("A", "a")) {
					_cuts.add(toLower(nabs(dir)));
				} else {
					_cuts.add(nabs(dir));
				}
			} else {
				assert (_files.isFocusControl);
				bool isdir = false;
				foreach (itm; _files.getSelection) {
					auto p = (cast(FileNameObj) itm.getData).array;
					itm.setImage = sfimage(itm.getImage);
					static if (fnmatch("A", "a")) {
						_cuts.add(toLower(nabs(p)));
					} else {
						_cuts.add(nabs(p));
					}
					if (!isdir && .isdir(p)) isdir = true;
				}
				if (isdir) refreshDirs(selDirPath);
			}
		}
	}
	override void copy() {
		if (!canDoTCPD) return;
		__copy;
		fimageThrStart;
	}
	private bool __copy() {
		clearCut;
		if (_dirs.isFocusControl) {
			auto dir = selDirPath;
			if (dir) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				cb.setContents([new FileNames([nabs(dir)])],
					[FileTransfer.getInstance]);
				return true;
			}
		} else {
			assert (_files.isFocusControl);
			auto files = selFiles;
			if (files.length > 0) {
				string[] arr;
				arr.length = files.length;
				foreach (i, f; files) {
					arr[i] = nabs(f);
				}
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				cb.setContents([new FileNames(arr)],
					[FileTransfer.getInstance]);
				return true;
			}
		}
		return false;
	}
	override void paste() {
		if (!canDoTCPD) return;
		auto cb = new Clipboard(Display.getCurrent);
		scope (exit) cb.dispose;
		auto c = cb.getContents(FileTransfer.getInstance);
		if (c && cast(FileNames) c) {
			bool fromOut;
			if (__paste(selDirPath, cast(FileNames) c, false, fromOut)) {
				clearCut;
				_summ.changed;
			}
		}
	}
	override void del() {
		if (!canDoTCPD) return;
		if (_dirs.isFocusControl) {
			if (_dirs.getSelection.length == 0) return;
			if (!_dirs.getSelection[0].getParentItem) return;
		}
		auto dlg = new MessageBox(_win.getShell, DWT.ICON_QUESTION | DWT.OK | DWT.CANCEL);
		scope (exit) dlg.dispose;
		dlg.setText = _prop.msgs.dlgTitQuestion;
		auto dir = selDirPath;
		auto file = selFiles;
		string[] fileNames;
		fileNames.length = file.length;
		foreach (i, f; file) {
			fileNames[i] = nabs(f);
		}
		if (_dirs.isFocusControl) {
			if (!dir) return;
			dlg.setMessage = _prop.msgs.dlgMsgDelete([nabs(dir)]);
			if (DWT.OK == dlg.open) {
				delAll(nabs(dir));
			}
		} else {
			assert (_files.isFocusControl);
			if (file.length == 0) return;
			dlg.setMessage = _prop.msgs.dlgMsgDelete(fileNames);
			if (DWT.OK == dlg.open) {
				foreach (f; file) {
					delAll(f);
				}
			}
		}
		refreshDirs(dir);
		refreshFiles(file);
		_comm.delPaths.call(this);
		_summ.changed;
		clearCut;
	}
	override bool canDoTCPD() {
		return _dirs.isFocusControl || _files.isFocusControl;
	}
}

class ReplacePathDialog : Dialog {
private:
	Props _prop;

	string[] _fromPaths;
	string[] _toPaths;
	string _selPath;
	Combo _base;
	Combo _repl;

	string _baseT, _replT;
public:
	this(Props prop, Shell shell, string[] fromPaths, string[] toPaths, string selPath) {
		super(shell);
		_prop = prop;
		_fromPaths = fromPaths;
		_toPaths = toPaths;
		_selPath = selPath;
	}

	string from() {
		return _baseT;
	}
	string to() {
		return _replT;
	}
protected:
	override void configureShell(Shell shell) {
		super.configureShell(shell);
		shell.setText = _prop.msgs.dlgTitReplacePath;
	}

	override Control createDialogArea(Composite parent) {
		auto area = cast(Composite) super.createDialogArea(parent);
		area.setLayout = new GridLayout(2, false);
		{
			auto l = new Label(area, DWT.NONE);
			l.setText = _prop.msgs.replacePathFrom;
			_base = new Combo(area, DWT.BORDER | DWT.DROP_DOWN);
			foreach (p; _fromPaths) {
				_base.add(p);
			}
			if (_selPath) _base.setText = _selPath;
			_base.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto l = new Label(area, DWT.NONE);
			l.setText = _prop.msgs.replacePathTo;
			_repl = new Combo(area, DWT.BORDER | DWT.DROP_DOWN);
			_repl.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			foreach (p; _toPaths) {
				_repl.add(p);
			}
		}

		return area;
	}

	override void createButtonsForButtonBar(Composite parent) {
		createButton(parent, IDialogConstants.OK_ID, IDialogConstants.OK_LABEL, true);
		createButton(parent, IDialogConstants.CANCEL_ID, IDialogConstants.CANCEL_LABEL, false);
	}

	override void buttonPressed(int buttonId) {
		if (buttonId == IDialogConstants.OK_ID) {
			if (_base.getText.length == 0 || _repl.getText.length == 0) {
				buttonId = IDialogConstants.CANCEL_ID;
			} else {
				try {
					.exists(_repl.getText);
				} catch {
					auto dlg = new MessageBox(_repl.getShell, DWT.ICON_WARNING | DWT.OK);
					scope (exit) dlg.dispose;
					dlg.setText = _prop.msgs.dlgTitWarning;
					dlg.setMessage = _prop.msgs.errorReplacePath;
					dlg.open;
					_repl.setFocus;
					return;
				}
				_baseT = _base.getText;
				_replT = _repl.getText;
			}
		}
		setReturnCode(buttonId);
		close;
		super.buttonPressed(buttonId);
	}
}

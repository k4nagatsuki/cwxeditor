
module cwx.editor.gui.dwt.mainwindow;

import cwx.cwl;
import cwx.area;
import cwx.card;
import cwx.summary;
import cwx.event;
import cwx.flag;
import cwx.utils;
import cwx.archive;
import cwx.usecounter;
import cwx.props;
import cwx.skin;
import cwx.path;
import cwx.graphics;
import cwx.menu;
import cwx.structs;
import cwx.types;
import cwx.cab;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.datawindow;
import cwx.editor.gui.dwt.cardwindow;
import cwx.editor.gui.dwt.directorywindow;
import cwx.editor.gui.dwt.settingsdialog;
import cwx.editor.gui.dwt.replacedialog;
import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.flagspane;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.loader;
import cwx.editor.gui.dwt.dmenu;

import core.memory;
import core.thread;

import std.conv;
import std.file;
import std.path;
import std.zip;
import std.utf;
import std.process;
import std.metastrings;
import std.string;
import std.datetime;
import std.regex;
import std.array;
import std.algorithm;
import std.csv;
import std.functional;
debug import std.stdio;

import org.eclipse.swt.all;

import java.lang.all;

version (Windows) {
	import std.c.windows.windows;
	private extern (Windows) {
		HANDLE CreateNamedPipeW(LPCWSTR, DWORD, DWORD,
			DWORD, DWORD, DWORD, DWORD, LPSECURITY_ATTRIBUTES);
		BOOL ConnectNamedPipe(HANDLE, OVERLAPPED*);
		BOOL DisconnectNamedPipe(HANDLE);
		const PIPE_ACCESS_DUPLEX = 0x3;
		const PIPE_TYPE_BYTE = 0x0;
		const PIPE_READMODE_BYTE = 0x0;
		const PIPE_WAIT = 0x0;
	}
} else {
	import core.stdc.errno;
	version (linux) {
		import std.c.linux.linux;
		import std.c.linux.socket;
		alias std.c.linux.linux.read cread;
		alias std.c.linux.linux.write cwrite;
		alias std.c.linux.socket.bind cbind;
	} else {
		import std.c.unix.unix;
		alias std.c.unix.unix.read cread;
		alias std.c.unix.unix.write cwrite;
		alias std.c.unix.unix.bind cbind;
	}
	import std.c.string;
	extern (C) {
		alias ushort sa_family_t;
		struct sockaddr_un {
			sa_family_t sun_family;
			char[sockaddr.sizeof - sa_family_t.sizeof] sun_path;
		}
	}
}

public:
class MainWindow : TopLevelPanel {
private:
	Display _display = null;
	bool _quit = false;
	Object _saveSync = null;

	SBShell _sbshl = null;
	Shell _win = null;
	DockingFolderCTC _dock = null;

	Props _prop;
	Commons _comm;

	DataWindow _dataWin = null;
	TableWindow _tableWin = null;
	FlagWindow _flagWin = null;
	MainCardWindow _cardWin = null;
	CastCardWindow _castWin = null;
	SkillCardWindow _skillWin = null;
	ItemCardWindow _itemWin = null;
	BeastCardWindow _beastWin = null;
	InfoCardWindow _infoWin = null;
	DirectoryWindow _dirWin = null;

	string _bassDir = "";
	RefreshTitle _refreshTitle;

	Menu _mExecEngine;
	Menu _tmExecEngine;
	ToolItem _tiExecEngine;
	void refreshExecEngine() {
		refreshExecEngineImpl(_mExecEngine, true);
		auto ePath = refreshExecEngineImpl(_tmExecEngine, false);
		version (Windows) {
			// ツールボタンのアイコン
			auto exeIcon = loadIcon(ePath, 16, 16);
			if (exeIcon) {
				auto img = _tiExecEngine.getImage();
				if (_prop.images.menu(MenuID.ExecEngineAuto) !is img) {
					img.dispose();
				}
				auto img2 = new Image(_tiExecEngine.getDisplay(), exeIcon);
				_tiExecEngine.setImage(img2);
			}
		}
		setupMenu(_menu);
		setupMenu(_tool);
	}
	string refreshExecEngineImpl(Menu menu, bool autoSelect) {
		foreach (itm; menu.getItems()) {
			itm.dispose();
		}
		void putIcon(MenuItem mi, string ePath) {
			version (Windows) {
				// loadIcon()は低速のため、メニューを開いた際に呼ぶようにする
				bool rmv = false;
				MenuAdapter mShown;
				mShown = new class MenuAdapter {
					override void menuShown(MenuEvent e) {
						// 実行ファイルのアイコンを取得
						auto thr = new core.thread.Thread({
							auto exeIcon = loadIcon(ePath, 16, 16, (void delegate() dlg) {
								_display.syncExec(new class Runnable {
									void run() {
										dlg();
									}
								});
							});
							if (exeIcon) {
								_display.syncExec(new class Runnable {
									void run() {
										if (mi.isDisposed()) return;
										auto img2 = new Image(mi.getDisplay(), exeIcon);
										listener(mi, SWT.Dispose, {
											img2.dispose();
										});
										mi.setImage(img2);
									}
								});
							}
						});
						menu.removeMenuListener(mShown);
						rmv = true;
						thr.start();
					}
				};
				menu.addMenuListener(mShown);
				mi.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) {
						if (!rmv) menu.removeMenuListener(mShown);
					}
				});
			}
		}
		MenuItem autoMI = null;
		string autoE = nabs(execEnginePath);
		if (autoSelect) {
			autoMI = createMenuItem(_comm, menu, MenuID.ExecEngineAuto, &execEngine, &canExecEngine);
			_menu[MenuID.ExecEngine] = autoMI;
		}
		void putMenu(string path, string ePath, string name, Image img) {
			auto mi = createMenuItem2(_comm, menu, name, img, {
				if (path.length) {
					execEngineP(path);
				}
			}, () => path.length > 0);
			putIcon(mi, ePath);
		}
		if (_prop.var.etc.enginePath.length) {
			if (0 < menu.getItemCount()) {
				new MenuItem(menu, SWT.SEPARATOR);
			}
			auto mi = createMenuItem(_comm, menu, MenuID.ExecEngineMain, {
				if (_prop.enginePath.length) {
					execEngineP(_prop.enginePath);
				}
			}, () => _prop.enginePath.length > 0);
			putIcon(mi, _prop.enginePath);
		}
		if (_prop.var.etc.classicEngines.length) {
			if (0 < menu.getItemCount()) {
				new MenuItem(menu, SWT.SEPARATOR);
			}
			foreach (i, ce; _prop.var.etc.classicEngines) {
				string name = MenuProps.buildMenu(ce.name, ce.mnemonic, ce.hotkey, false);
				auto p = nabs(ce.executePath(_prop.parent.appPath, false)); // 代替実行
				auto e = ce.executePath(_prop.parent.appPath, true); // エンジン本体
				if (autoE.length && cfnmatch(p, autoE)) {
					// 自動実行のアイコンは代替実行ファイルではなくエンジン本体のものとする
					autoE = e;
				}
				putMenu(p, e, name, _prop.images.classicEngine);
			}
		}
		if (autoMI) {
			putIcon(autoMI, autoE);
		}
		return autoE;
	}

	Menu _mOuterTools;
	Menu _tmOuterTools;
	void refreshOuterTools() {
		refreshOuterToolsImpl(_mOuterTools);
		refreshOuterToolsImpl(_tmOuterTools);
		setupMenu(_menu);
		setupMenu(_tool);
	}
	void refreshOuterToolsImpl(Menu menu) {
		foreach (itm; menu.getItems()) {
			itm.dispose();
		}
		foreach (i, tool; _prop.var.etc.outerTools) {
			new Exec(_dirWin, menu, tool, i);
		}
	}

	class RefreshTitle : Runnable {
		void run() {
			if (summary) {
				string path = summary.scenarioPath;
				if (summary.isChanged) {
					_win.setText(.tryFormat(_prop.msgs.mainWindowNameChanged, summary.scenarioName, path));
				} else {
					_win.setText(.tryFormat(_prop.msgs.mainWindowName, summary.scenarioName, path));
				}
			} else {
				_win.setText(_prop.msgs.mainWindowNameEmpty);
			}
		}
	}
	void refreshTitle() {
		_display.syncExec(_refreshTitle);
	}

	private SysTime _lastBackup;
	void backupThr() {
		try {
			version (Console) {
				debug std.stdio.writeln("Start Backup Thread");
			}
			_lastBackup = Clock.currTime();
			while (!_quit) {
				if (_lastBackup + dur!"minutes"(_prop.var.etc.backupInterval) <= Clock.currTime()) {
					createBackup();
					_lastBackup = Clock.currTime();
				}
				core.thread.Thread.sleep(dur!"seconds"(1));
			}
			version (Console) {
				debug writeln("Exit Backup Thread");
			}
		} catch (Throwable e) {
			debugln(e);
		}
	}
	private string _oldMD5 = "";
	void createBackup() {
		try {
			if (_quit) return;
			if (!_prop.var.etc.backupEnabled) return;
			auto summ = summary;
			if (!summ) return;

			if (_prop.var.etc.backupRefAuthor) {
				if (summ.author != _prop.var.etc.defaultAuthor) return;
			}
			if (_prop.var.etc.autoSave && summ.isChanged) {
				// バックアップ前に自動セーブ
				_display.syncExec(new class Runnable {
					override void run() {
						save(_win, true);
					}
				});
			}

			string parent = _prop.backupPath;

			// 既存のバックアップファイルのリスト
			auto reg = .regex("^cwxeditor_backup_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\\[.+\\]\\.zip$"d);
			auto files = clistdir(parent);
			string[] backup;
			foreach (f; files) {
				if (match(to!dstring(f), reg).empty) continue;
				backup ~= f;
			}
			// 日時でソート。実際の更新日時よりファイル名に記述された日付を優先する
			backup = backup.sort;

			auto bc = _prop.var.etc.backupCount;
			void[] data;
			if (0 < bc) {
				string sPath = summ.scenarioPath;
				auto d = Clock.currTime();
				string file = .format("cwxeditor_backup_%04d%02d%02d%02d%02d%02d[%s].zip",
					d.year, d.month, d.day, d.hour, d.minute, d.second, sPath.baseName());
				string zFile = std.path.buildPath(parent, file);
				synchronized (_saveSync) {
					data = summ.createZipData([], true);
				}
				auto md5 = md5Digest(data);
				if ((_oldMD5 != md5) && (!backup.length || data != std.file.read(parent.buildPath(backup[$ - 1])))) {
					// 前回のバックアップと異なっていれば保存
					if (!parent.exists()) mkdirRecurse(parent);
					std.file.write(zFile, data);
					_oldMD5 = md5;
					bc--;
				}
			}

			if (backup.length <= bc) return;

			// 古いバックアップを削除する
			foreach (f; backup[0 .. backup.length - bc]) {
				f = std.path.buildPath(parent, f);
				try {
					std.file.remove(f);
				} catch (Exception e) {
					debugln(e);
				}
			}
		} catch (Exception e) {
			debugln(e);
		}
	}

	void openScenarioNewWin() {
		auto fname = selectScenario(_prop, _win, _prop.msgs.dlgTitOpenScenarioAtNewWin);
		if (!fname) return;
		bool r = exec(_prop.parent.appPath ~ " " ~ fname);
		if (!r) {
			MessageBox.showWarning
				(.tryFormat(_prop.msgs.errorExec, baseName(_prop.parent.appPath)),
				_prop.msgs.dlgTitWarning, _win);
		}
	}
	void createScenarioNewWin() {
		auto dlg = new CreateScenarioDialog(_comm, _prop, _win, false);
		if (!dlg.open()) return;
		bool r;
		if (dlg.legacy) {
			r = exec(_prop.parent.appPath ~ " -createclassic " ~ dlg.name ~ " " ~ dlg.classicDir);
		} else {
			r = exec(_prop.parent.appPath ~ " -create " ~ dlg.name ~ " " ~ dlg.skin);
		}
		if (!r) {
			MessageBox.showWarning
				(.tryFormat(_prop.msgs.errorExec, baseName(_prop.parent.appPath)),
				_prop.msgs.dlgTitWarning, _win);
		}
	}
	void createScenario() {
		if (qSave()) {
			auto dlg = new CreateScenarioDialog(_comm, _prop, _win, true);
			if (!dlg.open()) return;
			Summary summ;
			if (dlg.fromTemplate) {
				summ = dlg.fromTemplate;
			} else if (dlg.legacy) {
				auto dir = dlg.classicDir;
				if (!dir.exists()) mkdirRecurse(dir);
				summ = new Summary(dlg.name, dlg.skin, dir, false, true);
			} else {
				summ = Summary.createScenario(_prop.tempPath, dlg.name, findSkin2(_prop, dlg.skin));
			}
			summ.author = _prop.var.etc.defaultAuthor;
			openScenario(summ);
			statusLine = "";
		}
	}
	class DTListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = DND.DROP_LINK;
		}
		override void drop(DropTargetEvent e) {
			auto arr = cast(FileNames) e.data;
			if (arr && arr.array.length > 0) {
				if (qSave()) {
					openScenario(arr.array[0], &resetOpt);
				}
			}
		}
	}
	@property
	LoadOption loadOption(in Summary old) {
		LoadOption opt;
		opt.cardOnly = false;
		opt.textOnly = false;
		opt.doubleIO = _prop.var.etc.doubleIO;
		opt.expandXMLs = old ? old.expandXMLs : _prop.var.etc.expandXMLs;
		return opt;
	}
	void reload() {
		if (!summary) return;
		auto old = summary;
		if (old.useTemp && !old.zipName.length) {
			MessageBox.showWarning(.tryFormat(_prop.msgs.reloadBeforeSaveError, old.scenarioName),
				_prop.msgs.dlgTitWarning, _win);
			return;
		}
		if (old && qSave(true)) {
			bool expand = old.expandXMLs;
			if (old.legacy) {
				auto wsm = std.path.buildPath(old.scenarioPath, "Summary.wsm");
				if (old.useTemp) {
					try {
						openScenario(old.reloadXMLs(loadOption(old)));
					} catch (Exception e) {
						debugln(e);
						MessageBox.showWarning(.tryFormat(_prop.msgs.reloadError, summary.scenarioPath)
							~ "\n" ~ e.msg,
							_prop.msgs.dlgTitWarning, _win);
					}
				} else {
					if (!.exists(wsm)) wsm = old.scenarioPath;
					loadScenarioFromFile(_prop, loadOption(old), _comm.mainShell, &setStatusLine, old, wsm, &openScenario, &resetOpt);
				}
			} else if (expand) {
				try {
					openScenario(old.reloadXMLs(loadOption(old)));
				} catch (Exception e) {
					debugln(e);
					MessageBox.showWarning(.tryFormat(_prop.msgs.reloadError, summary.scenarioPath)
						~ "\n" ~ e.msg,
						_prop.msgs.dlgTitWarning, _win);
				}
			} else {
				assert (old.zipName.length);
				loadScenarioFromFile(_prop, loadOption(old), _comm.mainShell, &setStatusLine, old, old.zipName, &openScenario, &resetOpt);
			}
		}
	}
	void openScenarioM() {
		if (qSave()) {
			openScenario();
		}
	}
	int cmp(string a, string b) {
		return std.string.cmp(a, b);
	}
	int ncmp(string a, string b) {
		return cwx.utils.ncmp(a, b);
	}
	public Skin findSkinFromHistory(in Summary summ, out OpenHistory hist) {
		hist = findHist(createHistString(summ));
		if (summ.legacy && hist.path.length && (hist.skinName.length || hist.skinEngine.length)) {
			return findSkin(_comm, _prop, summ, hist.skinName, hist.skinEngine);
		}
		return findSkin(_comm, _prop, summ);
	}
	void openScenario(Summary summ) {
		string dStr = .text(__LINE__);
		try {
			assert (summ);
			dStr ~= " - " ~ .text(__LINE__);
			OpenHistory hist;
			auto skin = findSkinFromHistory(summ, hist);
			dStr ~= " - " ~ .text(__LINE__);
			if (summ.legacy && hist.path.length && (hist.skinName.length || hist.skinEngine.length)) {
				summ.type = hist.skinName;
			}
			dStr ~= " - " ~ .text(__LINE__);
			_lastBackup = Clock.currTime();
			dStr ~= " - " ~ .text(__LINE__);
			_dirWin.stopTrace();
			dStr ~= " - " ~ .text(__LINE__);
			scope (exit) _dirWin.resumeTrace();
			dStr ~= " - " ~ .text(__LINE__);
			if (_prop.var.etc.logicalSort) {
				summ.flagDirRoot.sorter = &ncmp;
			} else {
				summ.flagDirRoot.sorter = &cmp;
			}
			dStr ~= " - " ~ .text(__LINE__);
			summ.flagDirRoot.sortFlags(true);
			summ.flagDirRoot.sortSteps(true);
			dStr ~= " - " ~ .text(__LINE__);
			auto old = summary;
			if (old) {
				addHistory();
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (summ.type.length && !hasSkin(_prop, summ.type)
					&& summ.type != _prop.var.etc.defaultSkin) {
				MessageBox.showWarning(.tryFormat(_prop.msgs.useDefaultSkin, summ.type, _prop.var.etc.defaultSkin),
					_prop.msgs.dlgTitWarning, _win);
				summ.type = _prop.var.etc.defaultSkin;
			}
			dStr ~= " - " ~ .text(__LINE__);
			summ.resetChanged();
			dStr ~= " - " ~ .text(__LINE__);
			_comm.skin = skin;
			dStr ~= " - " ~ .text(__LINE__);
			_comm.closeAll();
			dStr ~= " - " ~ .text(__LINE__);
			if (_dataWin) {
				dStr ~= " - " ~ .text(__LINE__);
				_dataWin.load(summ);
			} else {
				dStr ~= " - " ~ .text(__LINE__);
				_tableWin.load(summ);
				dStr ~= " - " ~ .text(__LINE__);
				_flagWin.load(summ);
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (_cardWin) _cardWin.refresh(summ);
			dStr ~= " - " ~ .text(__LINE__);
			if (_castWin) _castWin.refresh(summ);
			dStr ~= " - " ~ .text(__LINE__);
			if (_skillWin) _skillWin.refresh(summ);
			dStr ~= " - " ~ .text(__LINE__);
			if (_itemWin) _itemWin.refresh(summ);
			dStr ~= " - " ~ .text(__LINE__);
			if (_beastWin) _beastWin.refresh(summ);
			dStr ~= " - " ~ .text(__LINE__);
			if (_infoWin) _infoWin.refresh(summ);
			dStr ~= " - " ~ .text(__LINE__);
			_dirWin.refresh(summ);
			dStr ~= " - " ~ .text(__LINE__);
			_comm.refScenario.call(summ);
			dStr ~= " - " ~ .text(__LINE__);
			_comm.refScenarioName.call();
			dStr ~= " - " ~ .text(__LINE__);
			_comm.refScenarioPath.call();
			dStr ~= " - " ~ .text(__LINE__);
			if (!dock) {
				dStr ~= " - " ~ .text(__LINE__);
				if (_prop.var.dataWin.visible) _comm.openDataWin(false);
				dStr ~= " - " ~ .text(__LINE__);
				if (_prop.var.cardWin.visible) _comm.openBindCardWin(false);
				dStr ~= " - " ~ .text(__LINE__);
				if (_prop.var.dirWin.visible) _comm.openDirWin(false);
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);
			setupMenu(_menu);
			dStr ~= " - " ~ .text(__LINE__);
			setupMenu(_tool);
			dStr ~= " - " ~ .text(__LINE__);
			bool opened = false;
			dStr ~= " - " ~ .text(__LINE__);
			string openedS = "";
			dStr ~= " - " ~ .text(__LINE__);
			if (_prop.var.etc.reconstruction && !_opt.noload) {
				dStr ~= " - " ~ .text(__LINE__);
				auto paths = fullHistToCWXPaths(hist.path);
				dStr ~= " - " ~ .text(__LINE__);
				if (paths.length) {
					statusLine = .tryFormat(_prop.msgs.reconstructionStatus, 0, paths.length);
					dStr ~= " - " ~ .text(__LINE__);
					foreach (i, cwxPath; paths) {
						dStr ~= " - " ~ .text(__LINE__);
						dStr ~= " - " ~ cwxPath;
						if (openCWXPath(cwxPath, false)) {
							opened = true;
							openedS = statusLine;
							statusLine = .tryFormat(_prop.msgs.reconstructionStatus, i + 1, paths.length);
						} else {
							statusLine = .tryFormat(_prop.msgs.reconstructionStatus, i + 1, paths.length);
						}
					}
				}
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (_opt.selectfile.length) {
				_comm.openCWXPath("fileview", false);
				_dirWin.select(_opt.selectfile);
			}
			foreach (path; _opt.openPaths) {
				try {
					if (openCWXPath(path, true)) {
						continue;
					}
				} catch (Exception e) {
					debugln(e);
				}
				MessageBox.showWarning(.tryFormat(_prop.msgs.cwxPathOpenError, path), _prop.msgs.dlgTitWarning, _win);
			}
			dStr ~= " - " ~ .text(__LINE__);
			resetOpt();
			dStr ~= " - " ~ .text(__LINE__);
			addHistory();
			dStr ~= " - " ~ .text(__LINE__);
			try {
				if (old && !.cfnmatch(old.scenarioPath.nabs(), summary.scenarioPath.nabs())) {
					synchronized (_saveSync) {
						old.delTemp();
					}
				}
			} catch (Exception e) {
				debugln(e);
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (!opened || !openedS.length) {
				statusLine = .tryFormat(_prop.msgs.loaded, summ.scenarioName);
			} else {
				statusLine = openedS;
			}
			dStr ~= " - " ~ .text(__LINE__);
			auto chgEvtForce = new class Runnable {
				override void run() {
					_comm.changed.call();
				}
			};
			dStr ~= " - " ~ .text(__LINE__);
			auto chgEvt = new class Runnable {
				override void run() {
					refreshTitle();
				}
			};
			dStr ~= " - " ~ .text(__LINE__);
			summ.changedEventForce ~= {
				_display.syncExec(chgEvtForce);
			};
			dStr ~= " - " ~ .text(__LINE__);
			summ.changedEvent ~= {
				_display.syncExec(chgEvt);
			};
			dStr ~= " - " ~ .text(__LINE__);
			refreshTitle();
			dStr ~= " - " ~ .text(__LINE__);
			refreshExecEngine();
			dStr ~= " - " ~ .text(__LINE__);
			core.memory.GC.collect();
			dStr ~= " - " ~ .text(__LINE__);
			_win.redraw();
			dStr ~= " - " ~ .text(__LINE__);
		} catch (Throwable e) {
			fdebugln(dStr);
			fdebugln(e);
			throw e;
		}
	}
	LaunchOption _opt;
	void resetOpt() {
		_opt.openPaths.length = 0u;
		_opt.selectfile = "";
		_opt.noload = false;
	}

	void openScenarioImpl(Summary summ) {
		if (summ) {
			openScenario(summ);
			foreach (path; _opt.openPaths) {
				try {
					if (openCWXPath(path, true)) {
						continue;
					}
				} catch (Exception e) {
					debugln(e);
				}
				MessageBox.showWarning(.tryFormat(_prop.msgs.cwxPathOpenError, path), _prop.msgs.dlgTitWarning, _win);
			}
			_opt.openPaths.length = 0u;
			_comm.refreshToolBar();
		}
	}
	void openScenario() {
		auto old = summary;
		loadScenario(_prop, loadOption(null), _comm.mainShell, &setStatusLine,
			old, _prop.msgs.dlgTitOpenScenario,
			_opt.openPaths, &openScenarioImpl, &resetOpt);
	}
	void openScenario(string fname, void delegate() failure) {
		if (cfnmatch(.extension(fname), ".wsm") && !.exists(fname)) {
			fname = dirName(fname);
		}
		decScenarioPath(fname, _opt.openPaths, _prop.var.etc.clickIsOpenEvent);
		auto old = summary;
		loadScenarioFromFile(_prop, loadOption(null), _comm.mainShell, &setStatusLine,
			old, fname, &openScenarioImpl, failure);
	}
	void playSavedSound() {
		string file = _prop.var.etc.savedSound;
		if (file.length && .exists(file)) {
			playSE(file, SOUND_TYPE_SDL);
		}
	}
	void saveScenario() {
		auto fc = _win.getDisplay().getFocusControl();
		save(fc.getShell());
	}
	void savec(Shell shell) {
		save(shell);
	}
	SaveOption createSaveOpt() {
		SaveOption opt;
		opt.doubleIO = _prop.var.etc.doubleIO;
		opt.saveInnerImagePath = _prop.var.etc.saveInnerImagePath;
		opt.backup = _prop.var.etc.backupBeforeSaveEnabled;
		opt.backupDir = _prop.backupBeforeSavePath.buildPath(_prop.var.etc.backupBeforeSaveDir);
		opt.imageConverter = .toDelegate(&imageToBitmap);
		return opt;
	}
	bool save(Shell shell, bool backupSave = false) {
		if (summary) {
			_dirWin.pauseTrace();
			scope (exit) {
				_dirWin.resumeTrace();
			}
			if (!summary.isSaved) {
				// いまだ保存されていない場合は名前をつけて保存
				if (backupSave) return false;
				return __saveScenarioA(shell);
			} else {
				auto cursors = setWaitCursors(shell);
				scope (exit) {
					resetCursors(cursors);
				}
				try {
					synchronized (_saveSync) {
						summary.saveOverwrite(_prop.parent, _comm.skin, createSaveOpt());
					}
					_comm.saved.call();
					refreshTitle();
					addHistory();
					core.memory.GC.collect();
					playSavedSound();
					return true;
				} catch (SummaryException e) {
					debugln(e);
					MessageBox.showWarning(e.msg, _prop.msgs.dlgTitWarning, shell);
					return false;
				}
			}
		}
		return true;
	}
	void saveScenarioA() {
		__saveScenarioA(_win);
	}
	bool __saveScenarioA(Shell shell) {
		if (summary) {
			static immutable FILTER_WSN = 0;
			static immutable FILTER_XML = 1;
			static immutable FILTER_WSM = 2;
			static immutable FILTER_ZIP = 3;
			static immutable FILTER_CAB = 4;
			string[] filters = ["*.wsn", "Summary.xml", "Summary.wsm", "*.zip"];
			string[] names = [_prop.msgs.filterScenarioSave, _prop.msgs.filterScenarioSaveDir, _prop.msgs.filterScenarioSaveClassic, _prop.msgs.filterScenarioSaveZip];
			if (canUncab) {
				filters ~= "*.cab";
				names ~= _prop.msgs.filterScenarioSaveCab;
			}
			string fname = null;
			int filter = _prop.var.etc.lastSaveFilter;
			if (filter < 0 || filters.length <= filter) {
				filter = 0;
			}
			bool classic;
			string filterPath = scenarioFilterPath(_prop);
			string fileName = toFileName(setExtension(summary.scenarioName, ".wsn"));
			while (true) {
				auto fileDlg = new FileDialog(shell, SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.SAVE);
				fileDlg.setFilterExtensions(filters);
				fileDlg.setFilterNames(names);
				fileDlg.setFilterIndex(filter);
				fileDlg.setText(_prop.msgs.dlgTitSaveScenario);
				fileDlg.setFilterPath(filterPath);
				fileDlg.setFileName(fileName);
				fileDlg.setOverwrite(true);
				fname = fileDlg.open();
				if (!fname) break;
				filterPath = fileDlg.getFilterPath();
				fileName = fileDlg.getFileName();
				filter = fileDlg.getFilterIndex();
				string dir = fname.dirName();
				bool checkDir() {
					if (dir.clistdir().length) {
						auto dlg = new MessageBox(shell, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
						dlg.setMessage(.tryFormat(_prop.msgs.saveToNotEmptyDir, dir));
						dlg.setText(_prop.msgs.dlgTitQuestion);
						if (SWT.YES != dlg.open()) {
							return false;
						}
					}
					return true;
				}
				final switch (filter) {
				case FILTER_WSN:
					classic = false;
					break;
				case FILTER_XML:
					fname = dir.buildPath("Summary.xml");
					if (!checkDir()) continue;
					classic = false;
					break;
				case FILTER_WSM:
					fname = dir.buildPath("Summary.wsm");
					if (!checkDir()) continue;
					classic = true;
					goto case FILTER_ZIP;
				case FILTER_ZIP, FILTER_CAB:
					if (!summary.legacy) {
						auto dlg = new MessageBox(shell, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
						dlg.setMessage(_prop.msgs.warningXToClassic);
						dlg.setText(_prop.msgs.dlgTitQuestion);
						if (SWT.YES != dlg.open()) {
							continue;
						}
					}
					classic = true;
					break;
				}
				break;
			}
			if (fname) {
				auto cursors = setWaitCursors(shell);
				scope (exit) resetCursors(cursors);
				_dirWin.pauseTrace();
				scope (exit) _dirWin.resumeTrace();
				string tempPath = _prop.tempPath;
				bool expandXMLs = _prop.var.etc.expandXMLs;
				Skin defSkin = .findSkin2(_prop, _prop.var.etc.defaultSkin);
				try {
					synchronized (_saveSync) {
						summary.saveWithName(_prop.parent, _comm.skin, createSaveOpt(),
							fname, tempPath, expandXMLs, defSkin, (string msg) {
								MessageBox.showWarning(msg, _prop.msgs.dlgTitWarning, shell);
							}, classic);
					}
					_comm.skin = findSkin(_comm, _prop, summary);
					_comm.saved.call();
					refreshTitle();
					_comm.refScenarioPath.call();
					_comm.refSkin.call();
					_comm.refPaths.call("");
					addHistory();
					_prop.var.etc.lastSaveFilter = filter;
					core.memory.GC.collect();
					playSavedSound();
				} catch (SummaryException e) {
					debugln(e);
					MessageBox.showWarning(e.msg, _prop.msgs.dlgTitWarning, shell);
				}
			}
		}
		return false;
	}
	void execEngineP(string path) {
		if (!exec(path, dirName(nabs(path)))) {
			MessageBox.showWarning(.tryFormat(_prop.msgs.errorExecEngine, .baseName(path)),
				_prop.msgs.dlgTitWarning, _win);
		}
	}
	@property
	bool canExecEngine() {
		string engine = execEnginePath;
		return engine.length > 0;
	}
	void execEngine() {
		string engine = execEnginePath;
		if (engine.length) {
			execEngineP(engine);
		}
	}
	@property
	string execEnginePath() {
		return summary ? _comm.skin.executeEngine : _prop.enginePath;
	}
	private void openDataWindow() {
		if (summary || dock) {
			_prop.var.dataWin.visible = true;
			_comm.openDataWin(true);
		}
	}
	private void openFlagWindow() {
		if (dock) {
			_comm.openFlagWin(true);
		}
	}
	private void openCardWindow() {
		assert (_cardWin);
		if (summary || dock) {
			_prop.var.cardWin.visible = true;
			_comm.openBindCardWin(true);
		}
	}
	private void openDirWindow() {
		if (summary || dock) {
			_prop.var.dirWin.visible = true;
			_comm.openDirWin(true);
		}
	}
	void exitAll() {
		if (qSave()) {
			_win.close();
		}
	}
	private ReplaceDialog _replDlg = null;
	void replaceText() {
		openReplWin();
	}
	void clipboardToXML() {
		auto c = _comm.clipboard.getContents(XMLBytesTransfer.getInstance());
		if (c !is null && isXMLBytes(c)) {
			_comm.clipboard.setContents([new ArrayWrapperString(bytesToXML(c))], [TextTransfer.getInstance()]);
			_comm.refreshToolBar();
		}
	}

	bool qSave(bool reload = false) {
		if (_comm.isChanged) {
			MessageBox dlg;
			if (reload) {
				dlg = new MessageBox(_win, SWT.OK | SWT.CANCEL | SWT.ICON_QUESTION);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgIsSaveBeforeReload, summary.scenarioName));
			} else {
				dlg = new MessageBox(_win, SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgIsSaveBeforeExit, summary.scenarioName));
			}
			dlg.setText(_prop.msgs.dlgTitQuestion);
			_win.setMinimized(false);
			switch (dlg.open()) {
			case SWT.YES, SWT.OK:
				return reload ? true : save(_win);
			case SWT.NO:
				return true;
			case SWT.CANCEL:
				return false;
			default: assert (0);
			}
		}
		return true;
	}

	void revShowMainToolBar(SelectionEvent e) {
		if (!_comm.singleWindowMode(_prop)) return;
		auto item = cast(MenuItem) e.widget;
		_prop.var.etc.showMainToolBar = item.getSelection();
		_comm.refShowToolBar.call();
	}
	void revShowSceneToolBar(SelectionEvent e) {
		if (!_comm.singleWindowMode(_prop)) return;
		auto item = cast(MenuItem) e.widget;
		_prop.var.etc.showSceneToolBar = item.getSelection();
		_comm.refShowToolBar.call();
	}
	void revShowEventToolBar(SelectionEvent e) {
		if (!_comm.singleWindowMode(_prop)) return;
		auto item = cast(MenuItem) e.widget;
		_prop.var.etc.showEventToolBar = item.getSelection();
		_comm.refShowToolBar.call();
	}

	void refShowMainToolBar() {
		if (!_comm.singleWindowMode(_prop)) return;
		if (_win.isVisible()) _win.setRedraw(false);
		scope (exit) {
			if (_win.isVisible()) _win.setRedraw(true);
		}
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		if (!_prop.var.etc.showMainToolBar) {
			gd.heightHint = 0;
		}
		_toolComp.setLayoutData(gd);
		_toolComp.setVisible(_prop.var.etc.showMainToolBar);
		_toolComp.getParent().layout();
	}
	Composite _toolComp;
	private CoolBar _cbar = null;
	class SListener : ShellAdapter {
		override void shellClosed(ShellEvent e) {
			e.doit = qSave();
			if (e.doit) {
				if (summary && !_comm.isChanged) {
					writeDock();
				}
				_comm.closeAll();
			}
		}
	}
	class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_quit = true;
			_prop.var.etc.lastScenario = summary ? createHistString(summary) : "";
			_comm.save.remove(&savec);
			_comm.refScenarioName.remove(&refreshTitle);
			_comm.refScenarioPath.remove(&refreshTitle);
			_comm.refWallpaper.remove(&redrawAll);
			_comm.replText.remove(&refreshTitle);
			_comm.refClassicSkin.remove(&refreshExecEngine);
			_comm.refOuterTools.remove(&refreshOuterTools);
			_comm.refHistories.remove(&createFileMenu);
			_comm.refSkin.remove(&refSkin);
			_comm.refScenario.remove(&refScenario);
			_comm.refSoundType.remove(&refSoundType);
			_comm.refShowToolBar.remove(&refShowMainToolBar);
			auto b = _win.getBounds();
			_prop.var.mainWin.x = b.x;
			_prop.var.mainWin.y = b.y;
			if (dock) {
				_prop.var.mainWin.maximized = _win.getMaximized();
				if (!_prop.var.mainWin.maximized) {
					_prop.var.mainWin.width = b.width;
					_prop.var.mainWin.height = b.height;
				}
			}
			stopSE();
			stopBGM();
			_win.setVisible(false);
			try {
				_comm.refScenario.call(null);
				_comm.closeAll();
				if (summary && summary.useTemp) {
					_dirWin.stopTrace();
					try {
						synchronized (_saveSync) {
							summary.delTemp();
						}
					} catch (Exception e) {
						debugln(e);
					}
				}
			} catch (Throwable e) {
				debugln(e);
				_win.setVisible(true);
			}
		}
	}
	void sendReloadProps() {
		sendToPipe((string recv) {
			if (!recv) {
				return "reload settings";
			}
			return "";
		}, {
			return true;
		});
	}
	void reloadProps() {
		auto oldStgs = OldSettings(_prop);
		scope (exit) {
			oldStgs.raiseEvent(_comm);
		}
		_prop.var.reload();
	}
	private SettingsDialog _stgDlg = null;
	void settings() {
		if (_stgDlg) {
			_stgDlg.active();
		} else {
			_stgDlg = new SettingsDialog(_comm, _prop, _win, _dock, summary, &sendReloadProps);
			_stgDlg.closeEvent ~= {
				_stgDlg = null;
			};
			_stgDlg.open();
		}
	}

	void setHistSkin() {
		string skinName = summary.type;
		string skinEngine = _comm.skin.legacyEngine;
		auto hist = createHistString(summary);
		auto hists = _prop.var.etc.openHistories.dup;
		foreach (i, ref h; hists) {
			if (cfnmatch(fullHistToHist(h.path), hist)) {
				h.skinName = skinName;
				h.skinEngine = skinEngine;
				break;
			}
		}
		_prop.var.etc.openHistories = hists;
	}
	OpenHistory findHist(string hist) {
		if ("" == hist) return OpenHistory("");
		auto hists = _prop.var.etc.openHistories;
		foreach (i, h; hists) {
			if (cfnmatch(fullHistToHist(h.path), hist)) {
				return h;
			}
		}
		return OpenHistory("");
	}
	string findFullHist(string hist) {
		return findHist(hist).path;
	}
	static string createHistString(in Summary summary) {
		if (!summary) return "";
		string hist;
		if (summary.legacy) {
			if (summary.useTemp) {
				hist = summary.zipName;
			} else {
				hist = std.path.buildPath(summary.scenarioPath, "Summary.wsm");
			}
		} else if (summary.useTemp) {
			hist = summary.zipName;
			if (!hist.length) return "";
		} else {
			hist = std.path.buildPath(summary.scenarioPath, "Summary.xml");
		}
		return nabs(hist);
	}
	string createFullHistString() {
		string hist = createHistString(summary);
		if ("" == hist) return "";
		if (_prop.var.etc.reconstruction) {
			hist = "\"" ~ hist ~ "\" " ~ std.string.join(openedCWXPath, CWXPATH_SEP.idup);
		}
		return hist;
	}
	void writeDock() {
		string hist = createHistString(summary);
		if ("" == hist) return;
		auto hists = _prop.var.etc.openHistories.dup;
		foreach (i, h; hists) {
			if (cfnmatch(fullHistToHist(h.path), hist)) {
				if (_prop.var.etc.reconstruction) {
					hists[i].path = createFullHistString();
				} else {
					hists[i].path = hist;
				}
				_prop.var.etc.openHistories = hists;
				break;
			}
		}
	}
	/// `"/foo/bar" /cwx:0/path:0...` -> `/foo/bar`
	static string fullHistToHist(string hist) {
		if (std.string.startsWith(hist, "\"")) {
			int i = std.string.indexOf(hist["\"".length .. $], "\"");
			if (-1 != i) {
				return hist["\"".length .. i + "\"".length];
			}
		}
		return hist;
	} unittest {
		debug mixin(UTPerf);
		assert (fullHistToHist(r"C:\test\test1") == r"C:\test\test1");
		assert (fullHistToHist(`"C:\test\test1" aaa`) == r"C:\test\test1");
	}
	/// `"/foo/bar" /cwx:0/path:0&/cwx:1/path1:0` -> [`/cwx:0/path:0`, `/cwx:1/path:1`]
	static string[] fullHistToCWXPaths(string hist) {
		if (std.string.startsWith(hist, "\"")) {
			int i = std.string.indexOf(hist["\"".length .. $], "\"");
			if (-1 != i) {
				return std.string.split(strip(hist[i + "\"".length + 1 .. $]), CWXPATH_SEP.idup);
			}
		}
		return [];
	} unittest {
		debug mixin(UTPerf);
		assert (fullHistToCWXPaths(r"C:\test\test1") == []);
		assert (fullHistToCWXPaths(`"C:\test\test1" aaa&bbb`) == ["aaa", "bbb"]);
		assert (fullHistToCWXPaths(`"C:\test\test1" &aaa&bbb&&`) == ["", "aaa", "bbb", "", ""]);
	}
	void delHist(string fullHist) {
		auto hists = _prop.var.etc.openHistories.dup;
		string hist = fullHistToHist(fullHist);
		OpenHistory[] hists2;
		foreach (i, h; hists) {
			if (!cfnmatch(fullHistToHist(h.path), hist)) {
				hists2 ~= h;
			}
		}
		_prop.var.etc.openHistories = hists2;
		writeDock();
		_prop.var.save(dock);
		sendReloadProps();
		_comm.refHistories.call();
	}
	void addHistory() {
		auto hist = OpenHistory(createFullHistString());
		if ("" == hist.path) return;
		string p = fullHistToHist(hist.path);
		_prop.var.etc.scenarioPath = summary.useTemp ? dirName(p) : dirName(dirName(p));
		auto hists = _prop.var.etc.openHistories.dup;
		foreach (i, h; hists) {
			if (cfnmatch(fullHistToHist(h.path), p)) {
				// すでに履歴中に存在するため、最新位置に移動
				hist = h;
				_prop.var.etc.openHistories = hists[0 .. i] ~ hists[i + 1 .. $];
				hists = _prop.var.etc.openHistories.dup;
				break;
			}
		}
		_prop.var.etc.openHistories
			= [hist] ~ (hists.length < _prop.var.etc.historyMax ? hists : hists[0 .. $ - 1]);
		_prop.var.etc.lastScenario = p;
		writeDock();
		_prop.var.save(dock);
		sendReloadProps();
		_comm.refHistories.call();
	}
	class Hist {
		private string _hist;
		this(Menu menu, int num, string hist) {
			hist = fullHistToHist(hist);
			string text;
			Image img;
			auto snipLen = _prop.var.etc.historySnipLength;
			if (cfnmatch(baseName(hist), "Summary.xml")) {
				text = cuthist(hist[0u .. $ - "Summary.xml".length - std.path.dirSeparator.length], snipLen);
				img = _prop.images.summaryFile;
			} else if (cfnmatch(.extension(hist), ".wsn")) {
				text = cuthist(hist, snipLen);
				img = _prop.images.scenarioArchive;
			} else if (cfnmatch(baseName(hist), "Summary.wsm")) {
				text = cuthist(hist[0u .. $ - "Summary.wsm".length - std.path.dirSeparator.length], snipLen);
				img = _prop.images.classic;
			} else if (cfnmatch(.extension(hist), ".cab") || cfnmatch(.extension(hist), ".zip")) {
				text = cuthist(hist, snipLen);
				img = _prop.images.scenarioArchive;
			} else {
				text = cuthist(hist, snipLen);
				img = _prop.images.unknown;
			}
			string nstr;
			if (num < 10) {
				nstr = "&" ~ to!(string)(num);
			} else {
				nstr = to!(string)(num);
			}
			createMenuItem2(_comm, menu, nstr ~ " " ~ text, img, &run, null);
			_hist = hist;
		}
		private void run() {
			if (qSave()) {
				openScenario(_hist, {
					delHist();
					resetOpt();
				});
			}
		}
		private void delHist() {
			auto dlg = new MessageBox(_win, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
			string h = _hist;
			string ext = .extension(h);
			if (cfnmatch(ext, ".xml") || cfnmatch(ext, ".wsm") || cfnmatch(ext, ".wid") || cfnmatch(ext, ".wex")) {
				h = dirName(h);
			}
			dlg.setMessage(.tryFormat(_prop.msgs.scenarioNotFound, h));
			dlg.setText(_prop.msgs.dlgTitQuestion);
			if (SWT.YES == dlg.open()) {
				this.outer.delHist(_hist);
			}
		}
		private static string cuthist(string hist, int cut) {
			hist = nabs(hist);
			scope dhist = toUTF32(hist);
			if (dhist.length > cut + "..."d.length) {
				auto drive = driveName(hist);
				int rlen = drive ? toUTF32(drive).length + 1 : 1;
				int flen = toUTF32(baseName(hist)).length + 1;
				int plen = cut - flen;
				if (plen < rlen) plen = rlen;
				return toUTF8(dhist[0 .. plen] ~ "..." ~ dhist[$ - flen .. $]);
			} else {
				return hist;
			}
		} unittest {
			debug mixin(UTPerf);
			version (Windows) {
				string result;
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 30);
				assert (result == r"C:\Documents and Set...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 10);
				assert (result == r"C:\...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 11);
				assert (result == r"C:\...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 12);
				assert (result == r"C:\...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 13);
				assert (result == r"C:\...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 14);
				assert (result == r"C:\D...\test.file", result);
				result = cuthist(r"C:\simple\test.file", 35);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 19);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 18);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 17);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 16);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 15);
				assert (result == r"C:\si...\test.file", result);
				result = cuthist(r"C:\日本語\テスト.file", 12);
				assert (result == r"C:\日本語\テスト.file", result);
				result = cuthist(r"C:\日本語\テスト.file", 11);
				assert (result == r"C:\...\テスト.file", result);
				result = cuthist(r"C:\日本語日本語\テスト.file", 13);
				assert (result == r"C:\日...\テスト.file", result);
			}
		}
	}
	private Menu _menuFile;
	void createFileMenu() {
		foreach (itm; _menuFile.getItems()) {
			itm.dispose();
		}
		mixin (MenuAction!("_menuFile", MenuID.New, SWT.PUSH, "createScenario", "null"));
		mixin (MenuAction!("_menuFile", MenuID.Open, SWT.PUSH, "openScenarioM", "null"));
		mixin (MenuAction!("_menuFile", MenuID.Save, SWT.PUSH, "saveScenario", "() => summary !is null"));
		mixin (MenuAction!("_menuFile", MenuID.SaveAs, SWT.PUSH, "saveScenarioA", "() => summary !is null"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin (MenuAction!("_menuFile", MenuID.NewAtNewWindow, SWT.PUSH, "createScenarioNewWin", "null"));
		mixin (MenuAction!("_menuFile", MenuID.OpenAtNewWindow, SWT.PUSH, "openScenarioNewWin", "null"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin (MenuAction!("_menuFile", MenuID.CreateArchive, SWT.PUSH, "_dirWin.createArchive", "&_dirWin.canCreateArchive"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin (MenuAction!("_menuFile", MenuID.Reload, SWT.PUSH, "reload", "() => summary !is null"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		auto hists = _prop.var.etc.openHistories;
		foreach (i, hist; hists) {
			new Hist(_menuFile, i + 1, hist.path);
		}
		if (hists.length > 0) new MenuItem(_menuFile, SWT.SEPARATOR);
		createMenuItem(_comm, _menuFile, MenuID.Close, &exitAll, null);
		setupMenu(_menu);
	}
	string _pipeName = "";
	class OpenCWXPath : Runnable {
		string path;
		override void run() {
			auto paths = std.string.split(path, CWXPATH_SEP.idup);
			if (!paths.length) paths = [""];
			foreach (p; paths) {
				try {
					openCWXPath(p, true);
				} catch (Throwable e) {
					debugln (e);
				}
			}
		}
	}
	class ReloadSettings : Runnable {
		override void run() {
			try {
				reloadProps();
			} catch (Throwable e) {
				debugln (e);
			}
		}
	}
	class SelectFile : Runnable {
		string path;
		override void run() {
			try {
				_comm.openCWXPath("fileview", false);
				_dirWin.select(path);
			} catch (Throwable e) {
				debugln (e);
			}
		}
	}
	void pipeThr() {
		if (0 >= _prop.var.etc.pipeAppMax) return;
		try {
			version (Console) {
				debug std.stdio.writeln("Start Pipe Thread");
			}
			auto openPath = new OpenCWXPath;
			auto reloadSettings = new ReloadSettings;
			auto selectFile = new SelectFile;
			Summary summ = null;
			string recvSend(in char[] recv, out bool quit) {
				quit = false;
				if (recv == "quit") {
					quit = true;
					return null;
				} else if (recv == "get opened scenario") {
					summ = summary;
					if (!summ) return null;
					string send = "opened scenario ";
					if (summ.useTemp) {
						send ~= summ.zipName;
					} else {
						send ~= summ.scenarioPath;
					}
					return send;
				} else if (std.string.startsWith(recv.idup, "open cwxpath ")) {
					openPath.path = recv["open cwxpath ".length .. $].idup;
					_display.asyncExec(openPath);
					return "opened cwxpath";
				} else if (std.string.startsWith(recv, "select file ")) {
					selectFile.path = recv["select file ".length .. $].idup;
					_display.asyncExec(selectFile);
					return "selected file";
				} else if (recv == "reload settings") {
					_display.asyncExec(reloadSettings);
				}
				return null;
			}
			version (Windows) {
				auto pipe = CreateNamedPipeW(toUTFz!(wchar*)(_pipeName), PIPE_ACCESS_DUPLEX,
					PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
					1, MAX_PATH, MAX_PATH, 1000, null);
				if (pipe == INVALID_HANDLE_VALUE) return;
				scope (exit) CloseHandle(pipe);
				char[MAX_PATH] buf;
				DWORD len;
				bool quit = false;
				while (!quit && ConnectNamedPipe(pipe, null)) {
					scope (exit) DisconnectNamedPipe(pipe);
					while (true) {
						if (!ReadFile(pipe, buf.ptr, buf.length, &len, null)) break;
						auto recv = buf[0 .. len];
						string send = recvSend(recv, quit);
						if (quit) break;
						if (!send) break;
						if (!WriteFile(pipe, send.ptr, send.length, &len, null)) break;
					}
				}
			} else {
				unlink(std.string.toStringz(_pipeName));
				auto pipe = socket(AF_UNIX, SOCK_STREAM, 0);
				if (pipe == -1) return;
				sockaddr_un laddr;
				laddr.sun_family = AF_UNIX;
				scope (exit) {
					close(pipe);
					shutdown(pipe, 2);
					unlink(std.string.toStringz(_pipeName));
				}
				strcpy(laddr.sun_path.ptr, std.string.toStringz(_pipeName));
				if (0 != cbind(pipe, cast(sockaddr*) &laddr, laddr.sun_family.sizeof + strlen(laddr.sun_path.ptr))) return;
				if (0 != listen(pipe, 1)) return;
				char[4096] buf;
				int len;
				typeof(pipe) rsock;
				sockaddr_un raddr;
				socklen_t rsocklen;
				bool quit = false;
				while (!quit && !_quit) {
					timeval tout;
					tout.tv_sec = 1;
					tout.tv_usec = 0;
					fd_set fdr;
					FD_ZERO(&fdr);
					FD_SET(pipe, &fdr);
					auto selret = select(FD_SETSIZE, &fdr, null, null, &tout);
					if (-1 == selret && EINTR == errno) continue;
					if (-1 == selret) break;
					if (0 == selret) continue;
					if (!FD_ISSET(pipe, &fdr)) continue;
					rsock = accept(pipe, cast(sockaddr*) &raddr, &rsocklen);
					if (-1 == rsock) break;
					scope (exit) close(rsock);
					while (true) {
						if (-1 == (len = cread(pipe, buf.ptr, buf.length))) break;
						char[] recv = buf[0 .. len];
						string send = recvSend(recv, quit);
						if (quit) break;
						if (!send) break;
						if (-1 == cwrite(pipe, send.ptr, send.length)) break;
					}
				}
			}
			version (Console) {
				debug writeln("Exit Pipe Thread");
			}
		} catch (Exception e) {
			debugln(e);
		}
	}

	/// このプロセスが待ち受けする際のパイプ名を生成。
	string createPipeName() {
		version (Windows) {
			for (size_t i = 0; i < _prop.var.etc.pipeAppMax; i++) {
				string pipeName = r"\\.\pipe\cwxeditor_" ~ to!(string)(i);
				auto p = CreateFileW(toUTFz!(wchar*)(pipeName),
					GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
				if (p == INVALID_HANDLE_VALUE) {
					return pipeName;
				}
				CloseHandle(p);
			}
		} else {
			for (size_t i = 0; i < _prop.var.etc.pipeAppMax; i++) {
				string pipeName = r"cwxeditor_" ~ to!(string)(i);
				auto p = socket(AF_UNIX, SOCK_STREAM, 0);
				if (-1 == p) continue;
				scope (exit) {
					shutdown(p, 2);
					close(p);
				}
				sockaddr_un raddr;
				raddr.sun_family = AF_INET;
				strcpy(&(raddr.sun_path[1]), pipeName.ptr);
				if (-1 == connect(p, cast(sockaddr*) &raddr, raddr.sizeof)) {
					return pipeName;
				}
			}
		}
		return "";
	}
	/// CWXEditorのプロセスに対してパイプを通じてメッセージを送る。
	void sendToPipe(string delegate(string) sendRecv, bool delegate() next) {
		version (Windows) {
			char[MAX_PATH] buf;
			DWORD len;
			for (size_t i = 0; i < _prop.var.etc.pipeAppMax; i++) {
				if (!next()) break;
				string pipeName = r"\\.\pipe\cwxeditor_" ~ to!(string)(i);
				if (_pipeName == pipeName) continue;
				auto p = CreateFileW(toUTFz!(wchar*)(pipeName),
					GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
				if (p == INVALID_HANDLE_VALUE) {
					continue;
				}
				scope (exit) CloseHandle(p);
				string recv = null;
				while (true) {
					string send = sendRecv(recv);
					if (!send || !send.length) break;
					if (!WriteFile(p, send.ptr, send.length, &len, null)) break;
					if (!ReadFile(p, buf.ptr, buf.length, &len, null)) break;
					recv = buf[0 .. len].idup;
				}
			}
		} else {
			char[4096] buf;
			for (size_t i = 0; i < _prop.var.etc.pipeAppMax; i++) {
				if (!next()) break;
				string pipeName = r"cwxeditor_" ~ to!(string)(i);
				if (_pipeName == pipeName) continue;
				auto p = socket(AF_UNIX, SOCK_STREAM, 0);
				if (-1 == p) continue;
				scope (exit) close(p);
				sockaddr_un raddr;
				raddr.sun_family = AF_INET;
				strcpy(&(raddr.sun_path[1]), pipeName.ptr);
				if (-1 == connect(p, cast(sockaddr*) &raddr, raddr.sizeof)) {
					continue;
				}
				string recv = null;
				while (true) {
					string send = sendRecv(recv);
					if (!send || !send.length) break;
					if (-1 == cwrite(p, send.ptr, send.length)) break;
					int len = cread(p, buf.ptr, buf.length);
					if (-1 == len) break;
					recv = buf[0 .. len].idup;
				}
			}
		}
	}
	void refSkin() {
		refSoundType();
		setHistSkin();
	}
	void refScenario(Summary summ) {
		assert (summ is summary);
		refSoundType();
	}
	/// 音声再生方式を判別し、関係DLLの初期化・解放を行う。
	void refSoundType() {
		// FIXME: BGM再生中にBASSから他形式へ切替えた後、
		//        再生ボタンを連打(停止->再生)すると落ちる事があるため、
		//        ここで停止しておく
		stopBGM();
		stopSE();
		if (!summary) {
			toggleDisposeBass();
			_bassDir = "";
			return;
		}
		int bgmType = _prop.var.etc.soundPlayType;
		int seType = _prop.var.etc.soundEffectPlayType;
		if (SOUND_TYPE_SAME_BGM == seType) seType = bgmType;
		version (Windows) {
			int engineTypeBGM = summary.legacy ? SOUND_TYPE_SDL : SOUND_TYPE_MCI;
			string sfont[] = [];
		} else {
			int engineTypeBGM = SOUND_TYPE_SDL;
		}
		int engineTypeSE = engineTypeBGM;
		if (SOUND_TYPE_AUTO == bgmType || SOUND_TYPE_AUTO == seType) {
			version (Windows) {
				if (summary.legacy) {
					auto settings = _comm.skin.loadEngineSettings();
					switch (.toLower(settings.get("musicapi", settings.get("soundapibgm", "")))) {
					case "winmm":
						engineTypeBGM = SOUND_TYPE_MCI;
						break;
					case "bass":
						engineTypeBGM = SOUND_TYPE_BASS;
						break;
					default:
						break;
					}
					switch (.toLower(settings.get("soundapi", settings.get("soundapise", "")))) {
					case "winmm":
						engineTypeSE = SOUND_TYPE_MCI;
						break;
					case "bass":
						engineTypeSE = SOUND_TYPE_BASS;
						break;
					default:
						break;
					}
					if (SOUND_TYPE_BASS == engineTypeBGM || SOUND_TYPE_BASS == engineTypeSE) {
						try {
							foreach (rec; .csvReader!string(settings.get("soundfont", "").strip())) {
								foreach (s; rec) {
									sfont ~= s;
								}
							}
						} catch (Exception e) {
							debugln(e);
						}
					}
				}
			}
		}
		if (SOUND_TYPE_AUTO == bgmType) bgmType = engineTypeBGM;
		if (SOUND_TYPE_AUTO == seType) seType = engineTypeSE;
		version (Windows) {
			if (SOUND_TYPE_BASS == bgmType || SOUND_TYPE_BASS == seType) {
				string dir = _comm.skin.legacyEngine.nabs().dirName();
				foreach (ref s; sfont) {
					if (!isAbsolute(s)) {
						s = dir.buildPath(s);
					}
				}
				if (_bassDir != dir) {
					if (initBass(dir, sfont)) {
						_bassDir = dir;
					} else {
						if (SOUND_TYPE_BASS == bgmType) bgmType = SOUND_TYPE_MCI;
						if (SOUND_TYPE_BASS == seType) seType = SOUND_TYPE_MCI;
					}
				}
			}
			if (SOUND_TYPE_BASS != bgmType && SOUND_TYPE_BASS != seType) {
				toggleDisposeBass();
				_bassDir = "";
			}
		}
	}
public:
	this (string appPath, cwx.system.System sys, Props prop, LaunchOption opt) {
		string dStr = .text(__LINE__); // 起動ログ
		try {
			_prop = prop;
			_opt = opt;
			dStr ~= " - " ~ .text(__LINE__);
			decScenarioPath(opt.scenario, opt.openPaths, _prop.var.etc.clickIsOpenEvent);
			/// すでにopt.scenarioを開いている
			/// 既存のcwxeditorプロセスがある場合、
			/// そちらを開くようにする。
			string path1 = "";
			dStr ~= " - " ~ .text(__LINE__);
			if (opt.scenario && .exists(opt.scenario)) {
				path1 = nabs(opt.scenario);
				auto ext = .extension(path1);
				if (!.isDir(path1)
						&& (cfnmatch(ext, ".xml") || cfnmatch(ext, ".wsm") || cfnmatch(ext, ".wid") || cfnmatch(ext, ".wex"))) {
					path1 = nabs(dirName(path1));
				}
			}
			bool execute = true;
			dStr ~= " - " ~ .text(__LINE__);
			sendToPipe((string recv) {
				if (!recv) {
					return "get opened scenario";
				} else if (std.string.startsWith(recv, "opened scenario ")) {
					if (cfnmatch(path1, nabs(recv["opened scenario ".length .. $]))) {
						string send = "open cwxpath ";
						foreach (j, s; opt.openPaths) {
							if (j > 0) send ~= CWXPATH_SEP;
							send ~= s;
						}
						path1 = "";
						execute = false;
						return send;
					} else {
						return "";
					}
				} else if (std.string.startsWith(recv, "opened cwxpath")) {
					if (_opt.selectfile.length) {
						string send = "select file " ~ _opt.selectfile;
						execute = false;
						return send;
					} else {
						return "";
					}
				} else {
					return "";
				}
			}, {
				return path1.length > 0;
			});
			dStr ~= " - " ~ .text(__LINE__);
			if (!execute) return;
			_saveSync = new Object;
			dStr ~= " - " ~ .text(__LINE__);
			if (exists(_prop.tempPath)) {
				dStr ~= " - " ~ .text(__LINE__);
				foreach (temp; clistdir(_prop.tempPath)) {
					temp = std.path.buildPath(_prop.tempPath, temp);
					if (exists(temp) && isDir(temp)) {
						auto lock = std.path.buildPath(temp, "cwxeditor.lock");
						if (exists(lock)) {
							try {
								std.file.remove(lock);
								delAll(temp);
							} catch (Exception e) {}
						} else if (fnstartsWith(baseName(temp), "cwxeditor_temp_")) {
							try {
								delAll(temp);
							} catch (Exception e) {}
						}
					}
				}
			}
			_refreshTitle = new RefreshTitle;

			dStr ~= " - " ~ .text(__LINE__);
			_comm = new Commons(_prop);
			_comm.skin = findSkin2(_prop, _prop.var.etc.defaultSkin);
			dStr ~= " - " ~ .text(__LINE__);

			auto d = new Display;
			_display = d;
			d.setAppName(_prop.msgs.application);
			dStr ~= " - " ~ .text(__LINE__);

			string engineDir = "";
			if (_prop.enginePath.length && .exists(_prop.enginePath)) {
				dStr ~= " - " ~ .text(__LINE__);
				engineDir = dirName(nabs(_prop.enginePath));
				auto skinTable = .skinTable(_prop);
				if (!(_prop.var.etc.defaultSkin in skinTable)) {
					MessageBox.showWarning(.tryFormat(_prop.msgs.loadSkinError, _prop.var.etc.defaultSkin),
						_prop.msgs.dlgTitWarning, null);
				}
			}

			if (_prop.var.etc.singleWindow) {
				dStr ~= " - " ~ .text(__LINE__);
				_sbshl = new SBShell(null, SWT.SHELL_TRIM);
			} else {
				dStr ~= " - " ~ .text(__LINE__);
				_sbshl = new SBShell(null, SWT.DIALOG_TRIM | SWT.MIN);
			}
			dStr ~= " - " ~ .text(__LINE__);
			_win = _sbshl.shell();
			_win.setData(new TLPData(this));
			_win.setImage(_prop.images.app);

			dStr ~= " - " ~ .text(__LINE__);
			_comm.save.add(&savec);
			_comm.refScenarioName.add(&refreshTitle);
			_comm.refScenarioPath.add(&refreshTitle);
			_comm.refWallpaper.add(&redrawAll);
			_comm.replText.add(&refreshTitle);
			_comm.refClassicSkin.add(&refreshExecEngine);
			_comm.refOuterTools.add(&refreshOuterTools);
			_comm.refHistories.add(&createFileMenu);
			_comm.refSkin.add(&refSkin);
			_comm.refScenario.add(&refScenario);
			_comm.refSoundType.add(&refSoundType);
			_comm.refShowToolBar.add(&refShowMainToolBar);
			_win.addDisposeListener(new DListener);
			_win.addShellListener(new SListener);
			_comm.refreshWallpaper(_prop);
			dStr ~= " - " ~ .text(__LINE__);
			foreach (f; _prop.looks.fontFiles) {
				d.loadFont(std.path.buildPath(engineDir, f));
			}
			dStr ~= " - " ~ .text(__LINE__);
			_win.setText(_prop.msgs.mainWindowNameEmpty);
			if (_prop.var.etc.singleWindow) {
				_sbshl.contentPane.setLayout(zeroGridLayout(1, true));
			} else {
				_sbshl.contentPane.setLayout(windowGridLayout(1, true));
			}
			dStr ~= " - " ~ .text(__LINE__);
			_toolComp = new Composite(_sbshl.contentPane, SWT.NONE);
			_toolComp.setLayout(new FillLayout);
			if (_prop.var.etc.singleWindow) {
				dStr ~= " - " ~ .text(__LINE__);
				_tableWin = new TableWindow(_comm, _prop, _win, null);
				dStr ~= " - " ~ .text(__LINE__);
				_flagWin = new FlagWindow(_comm, _prop, _win, null);
				dStr ~= " - " ~ .text(__LINE__);
				if (_prop.var.etc.bindCardViews) {
					dStr ~= " - " ~ .text(__LINE__);
					_cardWin = new MainCardWindow(_comm, _prop, null);
				} else {
					dStr ~= " - " ~ .text(__LINE__);
					_castWin = new CastCardWindow(_comm, _prop, null);
					dStr ~= " - " ~ .text(__LINE__);
					_skillWin = new SkillCardWindow(_comm, _prop, null);
					dStr ~= " - " ~ .text(__LINE__);
					_itemWin = new ItemCardWindow(_comm, _prop, null);
					dStr ~= " - " ~ .text(__LINE__);
					_beastWin = new BeastCardWindow(_comm, _prop, null);
					dStr ~= " - " ~ .text(__LINE__);
					_infoWin = new InfoCardWindow(_comm, _prop, null);
				}
				dStr ~= " - " ~ .text(__LINE__);
				dStr ~= " - " ~ .text(__LINE__);
				_dirWin = new DirectoryWindow(_comm, _prop, null);

				dStr ~= " - " ~ .text(__LINE__);
				auto dockComp = new Composite(_sbshl.contentPane, SWT.NONE);
				dockComp.setLayoutData(new GridData(GridData.FILL_BOTH));
				dockComp.setLayout(windowGridLayout(1, true));
				dStr ~= " - " ~ .text(__LINE__);
				_dock = _prop.var.loadDock(dockComp, SWT.NONE, &dockCanVanish, delegate Control(Composite parent, string key) {
					scope (exit) {
						dStr ~= " - " ~ .text(__LINE__);
					}
					switch (key) {
					case "data": {
						dStr ~= " - " ~ .text(__LINE__);
						_tableWin.reconstruct(parent);
						return _tableWin.shell;
					}
					case "flag": {
						dStr ~= " - " ~ .text(__LINE__);
						_flagWin.reconstruct(parent);
						return _flagWin.shell;
					}
					case "card": {
						dStr ~= " - " ~ .text(__LINE__);
						if (_prop.var.etc.bindCardViews) {
							_cardWin.reconstruct(parent);
							return _cardWin.shell;
						}
						return null;
					}
					case "castCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_castWin.reconstruct(parent);
							return _castWin.shell;
						}
						return null;
					}
					case "skillCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_skillWin.reconstruct(parent);
							return _skillWin.shell;
						}
						return null;
					}
					case "itemCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_itemWin.reconstruct(parent);
							return _itemWin.shell;
						}
						return null;
					}
					case "beastCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_beastWin.reconstruct(parent);
							return _beastWin.shell;
						}
						return null;
					}
					case "infoCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_infoWin.reconstruct(parent);
							return _infoWin.shell;
						}
						return null;
					}
					case "file": {
						dStr ~= " - " ~ .text(__LINE__);
						_dirWin.reconstruct(parent);
						return _dirWin.shell;
					}
					default:
						dStr ~= " - " ~ .text(__LINE__);
						debugln("Unknown pane key: " ~ key);
						return null;
					}
				});
				dStr ~= " - " ~ .text(__LINE__);
				bool isSystemPaneName(string key) {
					return std.string.startsWith(key, "data")
						|| std.string.startsWith(key, "side");
				}
				bool isSystemCtrlName(string key) {
					return std.string.startsWith(key, "data")
						|| std.string.startsWith(key, "flag")
						|| std.string.startsWith(key, "card")
						|| std.string.startsWith(key, "castCard")
						|| std.string.startsWith(key, "skillCard")
						|| std.string.startsWith(key, "itemCard")
						|| std.string.startsWith(key, "beastCard")
						|| std.string.startsWith(key, "infoCard")
						|| std.string.startsWith(key, "file");
				}
				void initDock() {
					dStr ~= " - " ~ .text(__LINE__);
					if (!_dock.findPane("work").length) {
						_dock.addPane(_dock.first, Dir.N, 3, 1, "work");
					}
					dStr ~= " - " ~ .text(__LINE__);
					_dock.canMove = &dockCanMove;
					_dock.newPaneName = &dockNewPaneName;
					_dock.canVanish = &dockCanVanish;
					_dock.selectEvent ~= &dockSelect;
					_dock.closeCtrlEvent ~= &dockCloseCtrl;
					_dock.memoryPane = &isSystemPaneName;
					_dock.memoryControl = &isSystemCtrlName;
					_dock.addCreatePaneEvent(&createPaneEvent);
					_dock.area.setLayoutData(new GridData(GridData.FILL_BOTH));
					dStr ~= " - " ~ .text(__LINE__);
					_prop.var.delNodeTemp();
				}
				if (_dock) {
					dStr ~= " - " ~ .text(__LINE__);
					initDock();
					dStr ~= " - " ~ .text(__LINE__);
					dStr ~= " - " ~ .text(__LINE__);
					_dock.tabImage("data", _tableWin.image);
					_dock.tabText("data", _tableWin.title);
					dStr ~= " - " ~ .text(__LINE__);
					dStr ~= " - " ~ .text(__LINE__);
					_dock.tabImage("flag", _flagWin.image);
					_dock.tabText("flag", _flagWin.title);
					dStr ~= " - " ~ .text(__LINE__);
					if (_prop.var.etc.bindCardViews) {
						dStr ~= " - " ~ .text(__LINE__);
						_dock.tabImage("card", _cardWin.image);
						_dock.tabText("card", _cardWin.title);
					} else {
						dStr ~= " - " ~ .text(__LINE__);
						_dock.tabImage("castCard", _castWin.image);
						_dock.tabText("castCard", _castWin.title);
						dStr ~= " - " ~ .text(__LINE__);
						_dock.tabImage("skillCard", _skillWin.image);
						_dock.tabText("skillCard", _skillWin.title);
						dStr ~= " - " ~ .text(__LINE__);
						_dock.tabImage("itemCard", _itemWin.image);
						_dock.tabText("itemCard", _itemWin.title);
						dStr ~= " - " ~ .text(__LINE__);
						_dock.tabImage("beastCard", _beastWin.image);
						_dock.tabText("beastCard", _beastWin.title);
						dStr ~= " - " ~ .text(__LINE__);
						_dock.tabImage("infoCard", _infoWin.image);
						_dock.tabText("infoCard", _infoWin.title);
					}
					dStr ~= " - " ~ .text(__LINE__);
					_dock.tabImage("file", _dirWin.image);
					_dock.tabText("file", _dirWin.title);
					dStr ~= " - " ~ .text(__LINE__);
				} else {
					dStr ~= " - " ~ .text(__LINE__);
					_dock = new DockingFolderCTC(dockComp, SWT.NONE, "work");
					initDock();
					dStr ~= " - " ~ .text(__LINE__);
					auto data = _dock.addPane(_dock.first, Dir.N, 3, 10, "data");
					_tableWin = new TableWindow(_comm, _prop, _win, data);
					_dock.add(_tableWin.shell, _tableWin.title, _tableWin.image, "data", true);
					_flagWin = new FlagWindow(_comm, _prop, _win, data);
					_dock.add(_flagWin.shell, _flagWin.title, _flagWin.image, "flag", false);
					dStr ~= " - " ~ .text(__LINE__);
					if (_prop.var.etc.bindCardViews) {
						_cardWin = new MainCardWindow(_comm, _prop, data);
						_dock.add(_cardWin.shell, _cardWin.title, _cardWin.image, "card", false);
					} else {
						auto card = _dock.addPane(data, Dir.E, 5, 7, "data_2");
						dStr ~= " - " ~ .text(__LINE__);
						_castWin = new CastCardWindow(_comm, _prop, card);
						_dock.add(_castWin.shell, _castWin.title, _castWin.image, "castCard", true);
						_skillWin = new SkillCardWindow(_comm, _prop, card);
						_dock.add(_skillWin.shell, _skillWin.title, _skillWin.image, "skillCard", false);
						_itemWin = new ItemCardWindow(_comm, _prop, card);
						_dock.add(_itemWin.shell, _itemWin.title, _itemWin.image, "itemCard", false);
						_beastWin = new BeastCardWindow(_comm, _prop, card);
						_dock.add(_beastWin.shell, _beastWin.title, _beastWin.image, "beastCard", false);
						_infoWin = new InfoCardWindow(_comm, _prop, card);
						_dock.add(_infoWin.shell, _infoWin.title, _infoWin.image, "infoCard", false);
						dStr ~= " - " ~ .text(__LINE__);
					}
					_dirWin = new DirectoryWindow(_comm, _prop, data);
					_dock.add(_dirWin.shell, _dirWin.title, _dirWin.image, "file", false);
					dStr ~= " - " ~ .text(__LINE__);
				}
			} else {
				_toolComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				dStr ~= " - " ~ .text(__LINE__);
				_dataWin = new DataWindow(_comm, _prop, _win, _win);
				_cardWin = new MainCardWindow(_comm, _prop, _win);
				_dirWin = new DirectoryWindow(_comm, _prop, _win);
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);

			_noSummMenu = new HashSet!(MenuID);
			_noSummMenu.add(MenuID.New);
			_noSummMenu.add(MenuID.Open);
			_noSummMenu.add(MenuID.Close);
			_noSummMenu.add(MenuID.Find);
			_noSummMenu.add(MenuID.ToXMLText);
			if (_prop.var.etc.singleWindow) {
				_noSummMenu.add(MenuID.TableView);
				_noSummMenu.add(MenuID.VarView);
				_noSummMenu.add(MenuID.CardView);
				_noSummMenu.add(MenuID.CastView);
				_noSummMenu.add(MenuID.SkillView);
				_noSummMenu.add(MenuID.ItemView);
				_noSummMenu.add(MenuID.BeastView);
				_noSummMenu.add(MenuID.InfoView);
				_noSummMenu.add(MenuID.FileView);
				_noSummMenu.add(MenuID.ShowMainToolBar);
				_noSummMenu.add(MenuID.ShowSceneToolBar);
				_noSummMenu.add(MenuID.ShowEventToolBar);
			}
			_noSummMenu.add(MenuID.ChangeVH);
			_noSummMenu.add(MenuID.ShowCardProp);
			_noSummMenu.add(MenuID.ShowCardImage);
			_noSummMenu.add(MenuID.ShowCardDetail);
			_noSummMenu.add(MenuID.ExecEngine);
			_noSummMenu.add(MenuID.Settings);
			_noSummMenu.add(MenuID.VersionInfo);

			dStr ~= " - " ~ .text(__LINE__);
			{
				_mainMenu = new HashSet!(MenuID);
				auto bar = new Menu(_win, SWT.BAR);
				dStr ~= " - " ~ .text(__LINE__);

				_menuFile = createMenu(_comm, bar, MenuID.File);
				setupMenuListener(_menuFile);
				dStr ~= " - " ~ .text(__LINE__);
				createFileMenu();
				dStr ~= " - " ~ .text(__LINE__);

				auto me = createMenu(_comm, bar, MenuID.Edit);
				setupMenuListener(me);
				if (_prop.var.etc.singleWindow) {
					mixin (MenuAction!("me", MenuID.OpenDir, SWT.PUSH, "openDirectory", "&canOpenDirectory"));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.Undo));
					mixin (MenuAction!("me", MenuID.Redo));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.Cut));
					mixin (MenuAction!("me", MenuID.Copy));
					mixin (MenuAction!("me", MenuID.Paste));
					mixin (MenuAction!("me", MenuID.Delete));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.Clone));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.SelectAll));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.Comment));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.ToScript));
					mixin (MenuAction!("me", MenuID.ToScriptAll));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.Up));
					mixin (MenuAction!("me", MenuID.Down));
					new MenuItem(me, SWT.SEPARATOR);
				}
				mixin (MenuAction!("me", MenuID.Find, SWT.PUSH, "replaceText", "null"));
				mixin (MenuAction!("me", MenuID.ReNumberingAll, SWT.PUSH, "reNumberingAll", "() => summary !is null"));
				mixin (MenuAction!("me", MenuID.ToXMLText, SWT.PUSH, "clipboardToXML", "() => CBisXMLOnly(_comm.clipboard)"));
				dStr ~= " - " ~ .text(__LINE__);
				if (_prop.var.etc.singleWindow) {
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.NewDir, SWT.PUSH, "_dirWin.createNewFolder", "&_dirWin.canCreateNewFolder"));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.DelNotUsedFile, SWT.PUSH, "_dirWin.deleteUnuse", "&_dirWin.canDeleteUnuse"));
				}

				auto mv = createMenu(_comm, bar, MenuID.View);
				setupMenuListener(mv);
				mixin (MenuAction!("mv", MenuID.TableView, SWT.PUSH, "openDataWindow", "null"));
				if (_prop.var.etc.singleWindow) {
					mixin (MenuAction!("mv", MenuID.VarView, SWT.PUSH, "openFlagWindow", "null"));
				}
				if (!_prop.var.etc.singleWindow || _prop.var.etc.bindCardViews) {
					mixin (MenuAction!("mv", MenuID.CardView, SWT.PUSH, "openCardWindow", "null"));
				} else {
					new MenuItem(mv, SWT.SEPARATOR);
					mixin (MenuAction!("mv", MenuID.CastView, SWT.PUSH, "openCast", "null"));
					mixin (MenuAction!("mv", MenuID.SkillView, SWT.PUSH, "openSkill", "null"));
					mixin (MenuAction!("mv", MenuID.ItemView, SWT.PUSH, "openItem", "null"));
					mixin (MenuAction!("mv", MenuID.BeastView, SWT.PUSH, "openBeast", "null"));
					mixin (MenuAction!("mv", MenuID.InfoView, SWT.PUSH, "openInfo", "null"));
					new MenuItem(mv, SWT.SEPARATOR);
				}
				mixin (MenuAction!("mv", MenuID.FileView, SWT.PUSH, "openDirWindow", "null"));
				if (_prop.var.etc.singleWindow) {
					dStr ~= " - " ~ .text(__LINE__);
					new MenuItem(mv, SWT.SEPARATOR);
					mixin (MenuAction!("mv", MenuID.Refresh, SWT.PUSH, "refreshAll", "() => summary !is null"));
					new MenuItem(mv, SWT.SEPARATOR);
					mixin (MenuAction!("mv", MenuID.ShowMainToolBar, SWT.CHECK, "revShowMainToolBar", "null"));
					auto mtm = _menu[MenuID.ShowMainToolBar];
					mtm.setSelection(_prop.var.etc.showMainToolBar);
					mixin (MenuAction!("mv", MenuID.ShowSceneToolBar, SWT.CHECK, "revShowSceneToolBar", "null"));
					auto stm = _menu[MenuID.ShowSceneToolBar];
					stm.setSelection(_prop.var.etc.showSceneToolBar);
					mixin (MenuAction!("mv", MenuID.ShowEventToolBar, SWT.CHECK, "revShowEventToolBar", "null"));
					auto etm = _menu[MenuID.ShowEventToolBar];
					etm.setSelection(_prop.var.etc.showEventToolBar);
					new MenuItem(mv, SWT.SEPARATOR);
					mixin (MenuAction!("mv", MenuID.ChangeVH));
				}
				dStr ~= " - " ~ .text(__LINE__);

				if (_prop.var.etc.singleWindow) {
					auto ma = createMenu(_comm, bar, MenuID.Table);
					setupMenuListener(ma);
					mixin (MenuAction!("ma", MenuID.EditSummary, SWT.PUSH, "_tableWin.editSummary", "&_tableWin.canEditSummary"));
					new MenuItem(ma, SWT.SEPARATOR);
					if (!_prop.var.etc.bindSceneWithEvent) {
						mixin (MenuAction!("ma", MenuID.EditScene));
						mixin (MenuAction!("ma", MenuID.EditEvent));
						new MenuItem(ma, SWT.SEPARATOR);
					}
					mixin (MenuAction!("ma", MenuID.NewArea, SWT.PUSH, "_tableWin.createArea", "&_tableWin.canCreateArea"));
					mixin (MenuAction!("ma", MenuID.NewBattle, SWT.PUSH, "_tableWin.createBattle", "&_tableWin.canCreateBattle"));
					mixin (MenuAction!("ma", MenuID.NewPackage, SWT.PUSH, "_tableWin.createPackage", "&_tableWin.canCreatePackage"));

					auto mf = createMenu(_comm, bar, MenuID.Variable);
					setupMenuListener(mf);
					mixin (MenuAction!("mf", MenuID.NewFlagDir, SWT.PUSH, "_flagWin.createFlagDir", "&_flagWin.canCreateFlagDir"));
					mixin (MenuAction!("mf", MenuID.NewFlag, SWT.PUSH, "_flagWin.createFlag", "&_flagWin.canCreateFlag"));
					mixin (MenuAction!("mf", MenuID.NewStep, SWT.PUSH, "_flagWin.createStep", "&_flagWin.canCreateStep"));

					auto mc = createMenu(_comm, bar, MenuID.Card);
					setupMenuListener(mc);
					auto g = new RadioGroup!(MenuItem);
					mixin (MenuAction!("mc", MenuID.ShowCardProp, SWT.RADIO, "showCardLife", "null"));
					auto scf = _menu[MenuID.ShowCardProp];
					g.append(scf);
					mixin (MenuAction!("mc", MenuID.ShowCardImage, SWT.RADIO, "showCardList", "null"));
					auto scl = _menu[MenuID.ShowCardImage];
					g.append(scl);
					mixin (MenuAction!("mc", MenuID.ShowCardDetail, SWT.RADIO, "showCardTable", "null"));
					auto sct = _menu[MenuID.ShowCardDetail];
					g.append(sct);
					if (_prop.var.etc.cardLife) {
						scf.setSelection(true);
	 				} else if (_prop.var.etc.cardDetails) {
						sct.setSelection(true);
					} else {
						scl.setSelection(true);
					}
					_menuRG ~= g;
					new MenuItem(mc, SWT.SEPARATOR);
					mixin (MenuAction!("mc", MenuID.NewCast, SWT.PUSH, "newCast", "&canNewCast"));
					mixin (MenuAction!("mc", MenuID.NewSkill, SWT.PUSH, "newSkill", "&canNewSkill"));
					mixin (MenuAction!("mc", MenuID.NewItem, SWT.PUSH, "newItem", "&canNewItem"));
					mixin (MenuAction!("mc", MenuID.NewBeast, SWT.PUSH, "newBeast", "&canNewBeast"));
					mixin (MenuAction!("mc", MenuID.NewInfo, SWT.PUSH, "newInfo", "&canNewInfo"));
					new MenuItem(mc, SWT.SEPARATOR);
					mixin (MenuAction!("mc", MenuID.OpenImportSource, SWT.PUSH, "addScenario", "&canAddScenario"));
				}
				dStr ~= " - " ~ .text(__LINE__);

				auto mt = createMenu(_comm, bar, MenuID.Tool);
				setupMenuListener(mt);
				void delegate(SelectionEvent) dummy = null;
				auto eemi = createMenuItem(_comm, mt, MenuID.ExecEngine, dummy, () => canExecEngine || _prop.var.etc.classicEngines.length, SWT.CASCADE);
				_mExecEngine = new Menu(eemi);
				eemi.setMenu(_mExecEngine);
				new MenuItem(mt, SWT.SEPARATOR);
				auto otmi = createMenuItem(_comm, mt, MenuID.OuterTools, dummy, () => _prop.var.etc.outerTools.length > 0, SWT.CASCADE);
				_mOuterTools = new Menu(otmi);
				otmi.setMenu(_mOuterTools);
				new MenuItem(mt, SWT.SEPARATOR);
				mixin (MenuAction!("mt", MenuID.Settings, SWT.PUSH, "settings", "null"));

				auto mh = createMenu(_comm, bar, MenuID.Help);
				setupMenuListener(mh);
				mixin (MenuAction!("mh", MenuID.VersionInfo, SWT.PUSH, "versionInfo", "null"));

				_win.setMenuBar(bar);
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);

			Menu tmOpenCardWin;
			void createCardWinTI(ToolBar bar) {
				_mainMenu.add(MenuID.CardView);
				auto ti = createDropDownItem(_comm, bar, MenuID.CardView, &openCardWindow, tmOpenCardWin, null);
				_tool[MenuID.CardView] = ti;
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.cwCast, _prop.images.casts, &openCast, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.skill, _prop.images.skill, &openSkill, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.item, _prop.images.item, &openItem, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.beast, _prop.images.beast, &openBeast, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.info, _prop.images.info, &openInfo, null);
			}
			void createExecEngineTI(ToolBar bar) {
				_mainMenu.add(MenuID.ExecEngine);
				_tiExecEngine = createDropDownItem(_comm, bar, MenuID.ExecEngine, &execEngine, _tmExecEngine, () => canExecEngine || _prop.var.etc.classicEngines.length);
				_tool[MenuID.ExecEngine] = _tiExecEngine;
				listener(_tiExecEngine, SWT.Dispose, {
					auto img = _tiExecEngine.getImage();
					if (_prop.images.menu(MenuID.ExecEngineAuto) !is img) {
						img.dispose();
					}
				});
			}
			void createOuterToolsTI(ToolBar bar) {
				_mainMenu.add(MenuID.OuterTools);
				auto ti = createDropDownItem(_comm, bar, MenuID.OuterTools, null, _tmOuterTools, () => _prop.var.etc.outerTools.length > 0);
				_tool[MenuID.OuterTools] = ti;
			}

			if (_prop.var.etc.singleWindow) {
				dStr ~= " - " ~ .text(__LINE__);
				_cbar = createCoolBar!("tools")(_comm, _toolComp, (CoolBar cbar) {
					void createCoolItem(CoolBar cbar, ToolBar tbar) {
						.createCoolItem(cbar, tbar);
						_toolBar ~= tbar;
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.New, SWT.PUSH, "createScenario", "null"));
						mixin (ToolAction!("bar", MenuID.Open, SWT.PUSH, "openScenarioM", "null"));
						mixin (ToolAction!("bar", MenuID.Save, SWT.PUSH, "saveScenario", "() => summary !is null"));
						mixin (ToolAction!("bar", MenuID.SaveAs, SWT.PUSH, "saveScenarioA", "() => summary !is null"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.CreateArchive, SWT.PUSH, "_dirWin.createArchive", "&_dirWin.canCreateArchive"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.Reload, SWT.PUSH, "reload", "() => summary !is null"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Refresh, SWT.PUSH, "refreshAll", "() => summary !is null"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Undo));
						mixin (ToolAction!("bar", MenuID.Redo));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Cut));
						mixin (ToolAction!("bar", MenuID.Copy));
						mixin (ToolAction!("bar", MenuID.Paste));
						mixin (ToolAction!("bar", MenuID.Delete));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.Clone));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Up));
						mixin (ToolAction!("bar", MenuID.Down));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Find, SWT.PUSH, "replaceText", "null"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.ReNumberingAll, SWT.PUSH, "reNumberingAll", "() => summary !is null"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.ToXMLText, SWT.PUSH, "clipboardToXML", "() => CBisXMLOnly(_comm.clipboard)"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.TableView, SWT.PUSH, "openDataWindow", "null"));
						mixin (ToolAction!("bar", MenuID.VarView, SWT.PUSH, "openFlagWindow", "null"));
						if (_prop.var.etc.bindCardViews) {
							createCardWinTI(bar);
						} else {
							new ToolItem(bar, SWT.SEPARATOR);
							mixin (ToolAction!("bar", MenuID.CastView, SWT.PUSH, "openCast", "null"));
							mixin (ToolAction!("bar", MenuID.SkillView, SWT.PUSH, "openSkill", "null"));
							mixin (ToolAction!("bar", MenuID.ItemView, SWT.PUSH, "openItem", "null"));
							mixin (ToolAction!("bar", MenuID.BeastView, SWT.PUSH, "openBeast", "null"));
							mixin (ToolAction!("bar", MenuID.InfoView, SWT.PUSH, "openInfo", "null"));
							new ToolItem(bar, SWT.SEPARATOR);
						}
						mixin (ToolAction!("bar", MenuID.FileView, SWT.PUSH, "openDirWindow", "null"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.ChangeVH));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.EditSummary, SWT.PUSH, "_tableWin.editSummary", "() => summary !is null"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.NewArea, SWT.PUSH, "_tableWin.createArea", "&_tableWin.canCreateArea"));
						mixin (ToolAction!("bar", MenuID.NewBattle, SWT.PUSH, "_tableWin.createBattle", "&_tableWin.canCreateBattle"));
						mixin (ToolAction!("bar", MenuID.NewPackage, SWT.PUSH, "_tableWin.createPackage", "&_tableWin.canCreatePackage"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.NewFlagDir, SWT.PUSH, "_flagWin.createFlagDir", "&_flagWin.canCreateFlagDir"));
						mixin (ToolAction!("bar", MenuID.NewFlag, SWT.PUSH, "_flagWin.createFlag", "&_flagWin.canCreateFlag"));
						mixin (ToolAction!("bar", MenuID.NewStep, SWT.PUSH, "_flagWin.createStep", "&_flagWin.canCreateStep"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						auto g = new RadioGroup!(ToolItem);
						mixin (ToolAction!("bar", MenuID.ShowCardProp, SWT.RADIO, "showCardLife", "null"));
						auto scf = _tool[MenuID.ShowCardProp];
						g.append(scf);
						mixin (ToolAction!("bar", MenuID.ShowCardImage, SWT.RADIO, "showCardList", "null"));
						auto scl = _tool[MenuID.ShowCardImage];
						g.append(scl);
						mixin (ToolAction!("bar", MenuID.ShowCardDetail, SWT.RADIO, "showCardTable", "null"));
						auto sct = _tool[MenuID.ShowCardDetail];
						g.append(sct);
						if (_prop.var.etc.cardLife) {
							scf.setSelection(true);
						} else if (_prop.var.etc.cardDetails) {
							sct.setSelection(true);
						} else {
							scl.setSelection(true);
						}
						_toolRG ~= g;
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.NewCast, SWT.PUSH, "newCast", "&canNewCast"));
						mixin (ToolAction!("bar", MenuID.NewSkill, SWT.PUSH, "newSkill", "&canNewSkill"));
						mixin (ToolAction!("bar", MenuID.NewItem, SWT.PUSH, "newItem", "&canNewItem"));
						mixin (ToolAction!("bar", MenuID.NewBeast, SWT.PUSH, "newBeast", "&canNewBeast"));
						mixin (ToolAction!("bar", MenuID.NewInfo, SWT.PUSH, "newInfo", "&canNewInfo"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.OpenImportSource, SWT.PUSH, "addScenario", "&canAddScenario"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.OpenDir, SWT.PUSH, "openDirectory", "&canOpenDirectory"));
						mixin (ToolAction!("bar", MenuID.NewDir, SWT.PUSH, "_dirWin.createNewFolder", "&_dirWin.canCreateNewFolder"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						createExecEngineTI(bar);
						new ToolItem(bar, SWT.SEPARATOR);
						createOuterToolsTI(bar);
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.Settings, SWT.PUSH, "settings", "null"));
						createCoolItem(cbar, bar);
					}
				});

				auto drop = new DropTarget(_cbar, DND.DROP_DEFAULT | DND.DROP_LINK);
				drop.setTransfer([FileTransfer.getInstance()]);
				drop.addDropListener(new DTListener);

				_comm.baseShell(this, _tableWin, _flagWin, _castWin, _skillWin, _itemWin, _beastWin, _infoWin, _dirWin);
				dStr ~= " - " ~ .text(__LINE__);
			} else {
				dStr ~= " - " ~ .text(__LINE__);
				auto bar = new ToolBar(_toolComp, SWT.FLAT);
				mixin (ToolAction!("bar", MenuID.New, SWT.PUSH, "createScenario", "null"));
				mixin (ToolAction!("bar", MenuID.Open, SWT.PUSH, "openScenarioM", "null"));
				mixin (ToolAction!("bar", MenuID.Save, SWT.PUSH, "saveScenario", "() => summary !is null"));
				mixin (ToolAction!("bar", MenuID.SaveAs, SWT.PUSH, "saveScenarioA", "() => summary !is null"));
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.Find, SWT.PUSH, "replaceText", "null"));
				mixin (ToolAction!("bar", MenuID.ReNumberingAll, SWT.PUSH, "reNumberingAll", "() => summary !is null"));
				mixin (ToolAction!("bar", MenuID.ToXMLText, SWT.PUSH, "clipboardToXML", "() => CBisXMLOnly(_comm.clipboard)"));
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.Reload, SWT.PUSH, "reload", "() => summary !is null"));
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.TableView, SWT.PUSH, "openDataWindow", "() => summary !is null"));
				createCardWinTI(bar);
				mixin (ToolAction!("bar", MenuID.FileView, SWT.PUSH, "openDirWindow", "() => summary !is null"));
				new ToolItem(bar, SWT.SEPARATOR);
				createExecEngineTI(bar);
				new ToolItem(bar, SWT.SEPARATOR);
				createOuterToolsTI(bar);
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.Settings, SWT.PUSH, "settings", "null"));
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.Close, SWT.PUSH, "exitAll", "null"));
				_toolBar ~= bar;

				auto drop = new DropTarget(bar, DND.DROP_DEFAULT | DND.DROP_LINK);
				drop.setTransfer([FileTransfer.getInstance()]);
				drop.addDropListener(new DTListener);

				_comm.baseShell(this, _dataWin, _cardWin, _dirWin);
				setupMenu(_menu);
				setupMenu(_tool);
				dStr ~= " - " ~ .text(__LINE__);
			}
			auto selectFilter = new class Listener {
				override void handleEvent(Event e) {
					if (cast(CTabFolder) e.widget || cast(TabFolder) e.widget) {
						_comm.refreshToolBar();
					}
				}
			};
			auto focusInOut = new class Listener {
				private int[Shell] _imeMode;
				override void handleEvent(Event e) {
					auto control = cast(Control) e.widget;
					if (!control) return;
					auto shl = control.getShell();
					if (e.type is SWT.KeyUp || e.type is SWT.KeyDown) {
						if (cast(Spinner) control || cast(NoIME) control) {
							shl.setImeInputMode(SWT.NONE);
						}
					} else if (e.type is SWT.FocusIn) {
						if (cast(Spinner) control || cast(NoIME) control) {
							if (shl !in _imeMode) {
								.listener(shl, SWT.Dispose, {
									if (shl in _imeMode) {
										_imeMode.remove(shl);
									}
								});
							}
							_imeMode[shl] = shl.getImeInputMode();
							shl.setImeInputMode(SWT.NONE);
						}
						_comm.refreshToolBar();
					} else {
						assert (e.type is SWT.FocusOut);
						if (cast(Spinner) control || cast(NoIME) control) {
							auto p = shl in _imeMode;
							if (p) {
								shl.setImeInputMode(*p);
								_imeMode.remove(shl);
							}
						}
					}
				}
			};
			auto keyDownFilter = new KeyDownFilter;
			auto switchTab = new SwitchTab;
			d.addFilter(SWT.Selection, selectFilter);
			d.addFilter(SWT.FocusIn, focusInOut);
			d.addFilter(SWT.FocusOut, focusInOut);
			d.addFilter(SWT.KeyUp, focusInOut);
			d.addFilter(SWT.KeyDown, focusInOut);
			d.addFilter(SWT.KeyDown, keyDownFilter);
			d.addFilter(SWT.MouseWheel, switchTab);
			d.addFilter(SWT.Traverse, switchTab);
			.listener(_win, SWT.Dispose, {
				d.removeFilter(SWT.Selection, selectFilter);
				d.removeFilter(SWT.FocusIn, focusInOut);
				d.removeFilter(SWT.FocusOut, focusInOut);
				d.removeFilter(SWT.KeyUp, focusInOut);
				d.removeFilter(SWT.KeyDown, focusInOut);
				d.removeFilter(SWT.KeyDown, keyDownFilter);
				d.removeFilter(SWT.MouseWheel, switchTab);
				d.removeFilter(SWT.Traverse, switchTab);
			});
			refreshExecEngine();
			refreshOuterTools();

			dStr ~= " - " ~ .text(__LINE__);
			int tx = _prop.var.mainWin.x == SWT.DEFAULT ? _win.getBounds().x : _prop.var.mainWin.x;
			int ty = _prop.var.mainWin.y == SWT.DEFAULT ? _win.getBounds().y : _prop.var.mainWin.y;
			if (_prop.var.etc.singleWindow) {
				_win.setMaximized(_prop.var.mainWin.maximized);
				intoDisplay(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
				_win.setBounds(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
				_win.layout(true);
			} else {
				_win.pack();
				intoDisplay(tx, ty, _win.getSize().x, _win.getSize().y);
				_win.setBounds(tx, ty, _win.getSize().x, _win.getSize().y);
			}
			dStr ~= " - " ~ .text(__LINE__);
			initSound();
			.bgmVolume = _prop.var.etc.bgmVolume;
			.seVolume = _prop.var.etc.seVolume;
			dStr ~= " - " ~ .text(__LINE__);
			refShowMainToolBar();
			dStr ~= " - " ~ .text(__LINE__);
			if (_dock) {
				if (_dock.pane("data")) {
					dockSelect("data");
				} else if (_dock.pane("card")) {
					dockSelect("card");
				} else if (_dock.pane("flag")) {
					dockSelect("flag");
				} else if (_dock.pane("castCard")) {
					dockSelect("castCard");
				} else if (_dock.pane("skillCard")) {
					dockSelect("skillCard");
				} else if (_dock.pane("itemCard")) {
					dockSelect("itemCard");
				} else if (_dock.pane("beastCard")) {
					dockSelect("beastCard");
				} else if (_dock.pane("infoCard")) {
					dockSelect("infoCard");
				} else if (_dock.pane("file")) {
					dockSelect("file");
				}
				dStr ~= " - " ~ .text(__LINE__);
				setupMenu(_menu);
				setupMenu(_tool);
			}
		} catch (Throwable e) {
			// 起動失敗
			fdebugln(dStr);
			fdebugln(e);
			throw e;
		}
	}
	private class KeyDownFilter : Listener {
		override void handleEvent(Event e) {
			auto text = cast(Text) e.widget;
			if (text && cast(CCombo) text.getParent()) {
				// CComboは本体に加えて内部のTextからもイベントが発生する
				return;
			}
			static const F = [
				SWT.F1, SWT.F2, SWT.F3, SWT.F4, SWT.F5,
				SWT.F6, SWT.F7, SWT.F8, SWT.F9, SWT.F10,
				SWT.F11, SWT.F12, SWT.F13, SWT.F14, SWT.F15,
			];
			e.doit = true;
			auto d = Display.getCurrent();
			auto fc = d.getFocusControl();
			if (!fc) return;
			bool ro = !(fc.getStyle() & SWT.READ_ONLY);
			if (ro && cast(Spinner) fc) {
				return;
			}
			if (ro && (cast(Spinner) fc || cast(Text) fc || cast(Combo) fc || cast(CCombo) fc)) {
				if (!(e.stateMask & SWT.CTRL) && !.contains!("a == b", int, int)(F, e.keyCode)) {
					return;
				}
			}
			if (cast(IgnoreHotkey) fc.getData()) {
				return;
			}
			void raiseEvent(MenuItem menu) {
				if (menu.getStyle() & SWT.CHECK) {
					menu.setSelection(!menu.getSelection());
				}
				if (menu.getStyle() & SWT.RADIO) {
					menu.setSelection(!menu.getSelection());
					if (menu.getSelection()) {
						foreach (etc; menu.getParent().getItems()) {
							if (etc !is menu) {
								menu.setSelection(false);
							}
						}
					}
				}
				scope se = new Event;
				se.type = SWT.Selection;
				se.widget = menu;
				se.time = e.time;
				se.stateMask = e.stateMask;
				se.doit = e.doit;
				menu.notifyListeners(SWT.Selection, se);
				e.doit = false;
			}
			if (fc.getMenu()) {
				auto menu = findMenu(fc.getMenu(), e.keyCode, e.character, e.stateMask);
				if (menu && menu.getEnabled()) {
					raiseEvent(menu);
					return;
				}
			}
			if (!.isDescendant(_win, fc.getShell())) return;
			// フォーカスのあるコントロールのShellのメニューを探し、
			// 該当するメニューが無かった場合は
			// 順に上位のShellを探索する
			auto shl = fc.getShell();
			MenuItem menu = null;
			while (!menu && shl) {
				menu = findMenu(shl, e.keyCode, e.character, e.stateMask);
				if (menu) break;
				if (shl is _win) break;
				int s = shl.getStyle();
				if ((s & SWT.PRIMARY_MODAL) || (s & SWT.APPLICATION_MODAL) || (s & SWT.SYSTEM_MODAL)) {
					break;
				}
				shl = cast(Shell) shl.getParent();
				if (!shl) break;
			}
			if (menu && menu.getEnabled()) {
				raiseEvent(menu);
				return;
			}
		}
	}
	private class SwitchTab : Listener {
		private Control _oldFocus = null;

		private bool switchTab(TabF, Tab)(TabF tabf, Tab tab, Event e) {
			if (!tab || 0 == e.count) return false;
			auto w = cast(Control) e.widget;
			if (!w) return false;
			if (tabf.getItemCount() <= 1) return false;
			if (e.type is SWT.MouseWheel) {
				auto p = w.toDisplay(e.x, e.y);
				auto ca = tabf.getClientArea();
				if (ca.y <= tabf.toControl(p).y) return false;
			}
			int index = tabf.indexOf(tab);
			assert (-1 != index);
			if (e.count < 0) {
				index++;
				if (tabf.getItemCount() <= index) index = 0;
			} else if (0 < e.count) {
				index--;
				if (index < 0) index = tabf.getItemCount() - 1;
			}
			tabf.setSelection(index);

			scope se = new Event;
			se.type = SWT.Selection;
			se.widget = tabf;
			se.time = e.time;
			se.stateMask = e.stateMask;
			se.doit = e.doit;
			tabf.notifyListeners(SWT.Selection, se);
			e.doit = se.doit;
			return true;
		}

		override void handleEvent(Event e) {
			if (!_prop.var.etc.switchTabWheel) return;
			if (e.type != SWT.MouseWheel && e.type != SWT.Traverse) return;
			auto d = Display.getCurrent();
			Control c;
			if (e.type is SWT.MouseWheel) {
				c = d.getCursorControl();
			} else if (e.type is SWT.Traverse) {
				c = d.getFocusControl();
				while (c) {
					if (cast(CTabFolder) c) break;
					c = c.getParent();
				}
			}
			if (!c) return;
			if (!.isDescendant(_win, c.getShell())) return;

			if (e.type is SWT.Traverse && (e.stateMask & SWT.CTRL)) {
				if (e.detail is SWT.TRAVERSE_TAB_NEXT) {
					e.count = -1;
				} else if (e.detail is SWT.TRAVERSE_TAB_PREVIOUS) {
					e.count = 1;
				} else {
					return;
				}
			}

			auto ctabf = cast(CTabFolder) c;
			if (ctabf) {
				if (switchTab(ctabf, ctabf.getSelection(), e)) {
					e.doit = false;
				}
			}
			auto tabf = cast(TabFolder) c;
			if (tabf && 0 < tabf.getSelection().length) {
				if (switchTab(tabf, tabf.getSelection()[0], e)) {
					e.doit = false;
				}
			}
		}
	}

	private void redrawAll() {
		_win.redraw(true);
	}
	private bool canAddScenario() {
		return summary !is null;
	}
	private void addScenario() {
		_comm.addScenario(_prop);
	}
	private template NewCard(string Name) {
		static const NewCard = "auto cw = cast(ICardWindow) _tlp;"
			~ "if (cw && cw.canCreate" ~ Name ~ ") {"
			~ "    cw.create" ~ Name ~ "();"
			~ "} else if (_cardWin) {"
			~ "    _cardWin.create" ~ Name ~ "();"
			~ "} else {"
			~ "    _" ~ .toLower(Name) ~ "Win.create" ~ Name ~ "();"
			~ "}";
	}
	private void openCast() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openCastWin(true);
	}
	private void openSkill() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openSkillWin(true);
	}
	private void openItem() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openItemWin(true);
	}
	private void openBeast() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openBeastWin(true);
	}
	private void openInfo() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openInfoWin(true);
	}
	private void refreshAll(SelectionEvent se) {
		if (!_dock) return;
		foreach (ctrl; _dock.showingControls) {
			auto tlpData = cast(TLPData) ctrl.getData();
			if (!tlpData) continue;
			auto act = tlpData.tlp.menuAction(MenuID.Refresh);
			if (act) act(se);
		}
	}
	private class TabfPaint : PaintListener {
		override void paintControl(PaintEvent e) {
			if (!_comm.wallpaper) return;
			auto tabf = cast(CTabFolder) e.widget;
			if (!tabf || tabf.getItemCount() > 0) return;
			auto rect = tabf.getClientArea();
			if (_prop.var.etc.wallpaperStyle < WallpaperStyle.min || WallpaperStyle.max < _prop.var.etc.wallpaperStyle) {
				_prop.var.etc.wallpaperStyle = WallpaperStyle.Tile;
			}
			auto style = cast(WallpaperStyle) _prop.var.etc.wallpaperStyle;
			drawWallpaper(e.gc, _comm.wallpaper, rect, style);
		}
	}
	private class TabMenu {
		private string _paneKey;
		this (string paneKey) {
			_paneKey = paneKey;
			auto comp = _dock.pane(paneKey);
			comp.addPaintListener(new TabfPaint);
			auto menu = new Menu(comp.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.ClosePane, &close, &canClose);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.ClosePaneExcept, &closeEtc, &canCloseEtc);
			createMenuItem(_comm, menu, MenuID.ClosePaneLeft, &closeLeft, &canCloseLeft);
			createMenuItem(_comm, menu, MenuID.ClosePaneRight, &closeRight, &canCloseRight);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.ClosePaneAll, &closeAll, &canClose);
			_dock.setMenu(paneKey, menu);
		}
		@property
		bool canClose() {
			return _dock.selectedCtrl(_paneKey).length > 0;
		}
		@property
		bool canCloseEtc() {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			return ctrl.length && _dock.hasEtc(ctrl);
		}
		@property
		bool canCloseLeft() {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			return ctrl.length && _dock.hasLeft(ctrl);
		}
		@property
		bool canCloseRight() {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			return ctrl.length && _dock.hasRight(ctrl);
		}
		void close(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.close(ctrl);
		}
		void closeEtc(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeEtc(ctrl);
		}
		void closeLeft(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeLeft(ctrl);
		}
		void closeRight(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeRight(ctrl);
		}
		void closeAll(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeAll(ctrl);
		}
	}
	private void createPaneEvent(string paneKey) {
		new TabMenu(paneKey);
	}
	private bool canOpenDirectory() {return summary !is null;}
	private void openDirectory() {
		if (!summary) return;
		auto dirWin = cast(DirectoryWindow) _tlp;
		if (dirWin) {
			dirWin.openDirectory();
		} else {
			openFolder(summary.scenarioPath);
		}
	}
	private bool isMainCardWin(ICardWindow cw) {
		return cast(MainCardWindow) cw || cast(CastCardWindow) cw || cast(SkillCardWindow) cw || cast(ItemCardWindow) cw || cast(BeastCardWindow) cw || cast(InfoCardWindow) cw;
	}
	private void showCardLife(SelectionEvent se) {
		auto cw = cast(ICardWindow) _tlp;
		if (cw && !isMainCardWin(cw)) {
			menuAction!(MenuID.ShowCardProp)(se);
		} else {
			if (_cardWin) _cardWin.showCardLife();
			if (_castWin) _castWin.showCardLife();
			if (_skillWin) _skillWin.showCardLife();
			if (_itemWin) _itemWin.showCardLife();
			if (_beastWin) _beastWin.showCardLife();
			if (_infoWin) _infoWin.showCardLife();
			menuActionAfter!(MenuID.ShowCardProp)();
		}
	}
	private void showCardList(SelectionEvent se) {
		auto cw = cast(ICardWindow) _tlp;
		if (cw && !isMainCardWin(cw)) {
			menuAction!(MenuID.ShowCardImage)(se);
		} else {
			if (_cardWin) _cardWin.showCardList();
			if (_castWin) _castWin.showCardList();
			if (_skillWin) _skillWin.showCardList();
			if (_itemWin) _itemWin.showCardList();
			if (_beastWin) _beastWin.showCardList();
			if (_infoWin) _infoWin.showCardList();
			menuActionAfter!(MenuID.ShowCardImage)();
		}
	}
	private void showCardTable(SelectionEvent se) {
		auto cw = cast(ICardWindow) _tlp;
		if (cw && !isMainCardWin(cw)) {
			menuAction!(MenuID.ShowCardDetail)(se);
		} else {
			if (_cardWin) _cardWin.showCardTable();
			if (_castWin) _castWin.showCardTable();
			if (_skillWin) _skillWin.showCardTable();
			if (_itemWin) _itemWin.showCardTable();
			if (_beastWin) _beastWin.showCardTable();
			if (_infoWin) _infoWin.showCardTable();
			menuActionAfter!(MenuID.ShowCardDetail)();
		}
	}
	private bool canNewCard() {return summary !is null;}
	private alias canNewCard canNewCast;
	private alias canNewCard canNewSkill;
	private alias canNewCard canNewItem;
	private alias canNewCard canNewInfo;
	private alias canNewCard canNewBeast;
	private void newCast() {mixin (NewCard!("Cast"));}
	private void newSkill() {mixin (NewCard!("Skill"));}
	private void newItem() {mixin (NewCard!("Item"));}
	private void newBeast() {mixin (NewCard!("Beast"));}
	private void newInfo() {mixin (NewCard!("Info"));}
	private void versionInfo() {
		(new VersionDialog(_comm, _prop, _win)).open();
	}

	private HashSet!(MenuID) _noSummMenu;
	private MenuItem[MenuID] _menu;
	private ToolItem[MenuID] _tool;
	private RadioGroup!(MenuItem)[] _menuRG;
	private RadioGroup!(ToolItem)[] _toolRG;
	private HashSet!(MenuID) _mainMenu;
	private ToolBar[] _toolBar;
	private TopLevelPanel _tlp = null;
	private template MenuAction(string M, MenuID Id, int Style = SWT.PUSH, string Act = "", string Can = "null") {
		static if (Act.length) {
			static const MenuAction = "_mainMenu.add(" ~ Id.stringof ~ ");"
				~ "_menu[" ~ Id.stringof ~ "] = createMenuItem(_comm, " ~ M ~ ", " ~ Id.stringof ~ ", &"
				~ Act ~ ", " ~ Can ~ ", " ~ toStringNow!(Style) ~ ");";
		} else {
			static const MenuAction = "_menu[" ~ Id.stringof ~ "] = createMenuItem(_comm, " ~ M ~ ", " ~ Id.stringof ~ ", "
				~ "&menuAction!(" ~ Id.stringof ~ "), " ~ Can ~ ", " ~ toStringNow!(Style) ~ ");";
		}
	}
	private template ToolAction(string T, MenuID Id, int Style = SWT.PUSH, string Act = "", string Can = "null") {
		static if (Act.length) {
			static const ToolAction = "_mainMenu.add(" ~ Id.stringof ~ ");"
				~ "_tool[" ~ Id.stringof ~ "] = createToolItem(_comm, " ~ T ~ ", " ~ Id.stringof ~ ", &"
				~ Act ~ ", " ~ Can ~ ", " ~ toStringNow!(Style) ~ ");";
		} else {
			static const ToolAction = "_tool[" ~ Id.stringof ~ "] = createToolItem(_comm, " ~ T ~ ", " ~ Id.stringof ~ ", "
				~ "&menuAction!(" ~ Id.stringof ~ "), " ~ Can ~ ", " ~ toStringNow!(Style) ~ ");";
		}
	}
	void refreshToolBar(bool delegate()[MenuID] cMenuTbl) {
		foreach (bar; _toolBar) {
			foreach (itm; bar.getItems()) {
				if (itm.getStyle() & SWT.SEPARATOR) continue;
				auto d = cast(MenuData) itm.getData();
				if (!d) continue;
				try {
					auto cMenuE = d.id in cMenuTbl;
					if (cMenuE) {
						itm.setEnabled((*cMenuE)());
					} else if (d.enabled) {
						itm.setEnabled(d.enabled());
					} else if (_tlp) {
						auto enabled = _tlp.menuEnabled(d.id);
						if (enabled) itm.setEnabled(enabled());
					}
				} catch (Throwable e) {
					debugln(.text(d.id));
					debugln(e);
				}
			}
		}
	}
	private class MenuShown : MenuAdapter {
		override void menuShown(MenuEvent e) {
			auto menu = cast(Menu) e.widget;
			foreach (itm; menu.getItems()) {
				if (itm.getStyle() & SWT.SEPARATOR) continue;
				auto d = cast(MenuData) itm.getData();
				assert (d !is null);
				if (d.enabled) continue; // createMenuItem()内の処理に任せる
				auto enabled = _tlp.menuEnabled(d.id);
				if (!enabled) continue;
				itm.setEnabled(enabled());
			}
		}
	}
	private void setupMenuListener(Menu menu) {
		menu.addMenuListener(new MenuShown);
	}
	private void menuActionAfterImpl(MenuID ID, T)(T[MenuID] tools, RadioGroup!(T)[] rg) {
		if (!_tlp) return;
		if (_tlp.menuChecked(ID)) {
			auto p = ID in tools;
			if (p) {
				auto b = *p;
				foreach (g; rg) {
					if (g.contains(b)) {
						foreach (gb; g.set()) {
							gb.setSelection(gb is b);
						}
						return;
					}
				}
				b.setSelection(_tlp.menuChecked(ID)());
			}
		}
	}
	private void menuAction(MenuID ID)(SelectionEvent se) {
		if (!_tlp) return;
		auto act = _tlp.menuAction(ID);
		assert (act, .text(ID) ~ " " ~ .text(_tlp));
		act(se);
		menuActionAfter!(ID)();
	}
	private void menuActionAfter(MenuID ID)() {
		menuActionAfterImpl!(ID)(_menu, _menuRG);
		menuActionAfterImpl!(ID)(_tool, _toolRG);
	}

	private void setupMenu(M)(M[MenuID] menus) {
		foreach (id, itm; menus) {
			if (id is MenuID.ExecEngine) {
				itm.setEnabled(_prop.var.etc.enginePath.length || _prop.var.etc.classicEngines.length);
				continue;
			}
			if (id is MenuID.OuterTools) {
				itm.setEnabled(_prop.var.etc.outerTools.length > 0);
				continue;
			}
			if (_tlp) {
				auto s = itm.getStyle();
				if ((s & SWT.RADIO) || (s & SWT.CHECK)) {
					auto chk = _tlp.menuChecked(id);
					if (chk) itm.setSelection(chk());
				}
			}
			if (!summary && !_noSummMenu.contains(id)) {
				itm.setEnabled(false);
				continue;
			}
			if (_mainMenu.contains(id)) {
				itm.setEnabled(true);
				continue;
			}
			itm.setEnabled(_tlp && _tlp.menuAction(id));
		}
	}
	private void dockSelect(string key) {
		if (!_dock) return;
		if (!_dock.control(key)) return;
		auto tlp = (cast(TLPData) _dock.control(key).getData()).tlp;
		assert (tlp, key);
		_tlp = tlp;
		statusLine = tlp.statusLine;
		setupMenu(_menu);
		setupMenu(_tool);
	}
	private bool dockCanMove(string ctrlKey, string dropPaneKey) {
		if (!dropPaneKey.length) return true;
		bool iswa = std.string.startsWith(dropPaneKey, "work");
		if (std.string.startsWith(ctrlKey, "work")) {
			return iswa;
		} else {
			return !iswa;
		}
	}
	private bool dockCanVanish(DockingFolderCTC dock, string key) {
		if (std.string.startsWith(key, "work")) {
			return dock.findPane("work").length > 1;
		}
		return true;
	}
	private bool dockCanVanish(string key) {
		if (std.string.startsWith(key, "work")) {
			return _dock.findPane("work").length > 1;
		}
		if (_dock.panes.length == 2) {
			statusLine = "";
		}
		return true;
	}
	private bool dockCloseCtrl(string key) {
		statusLine = "";
		return true;
	}
	private string dockNewPaneName(string ctrlKey, string basePane, Dir dir) {
		if (std.string.startsWith(ctrlKey, "work")) {
			return _dock.newPaneKey("work");
		} else if (std.string.startsWith(basePane, "work")) {
			if (dir == Dir.E || dir == Dir.W) {
				return _dock.newPaneKey("side");
			} else if (dir == Dir.N || dir == Dir.S) {
				return _dock.newPaneKey("data");
			}
		}
		return "";
	}
	void setStatusLine(string status) {
		_comm.setStatusLine(_win, status);
	}

	@property
	string title() {return _win.getText();}
	@property
	Image image() {return _win.getImage();}
	@property
	Composite shell() {return _win;}
	@property
	void delegate(string) statusText() {return &_sbshl.statusLine;}
	@property
	DockingFolderCTC dock() {return _dock;}

	@property
	Summary summary() {return _dataWin ? _dataWin.summary : _tableWin.summary;}

	void reNumberingHands(A)(A[] arr) {
		ulong newId = 1;
		foreach (a; arr) {
			if (a.id != newId) {
				a.id = newId;
				static if (is (A : Area)) {
					_comm.refArea.call(a);
				} else static if (is (A : Battle)) {
					_comm.refBattle.call(a);
				} else static if (is (A : Package)) {
					_comm.refPackage.call(a);
				} else static if (is (A : CastCard)) {
					_comm.refCast.call(a);
				} else static if (is (A : SkillCard)) {
					_comm.refSkill.call(a);
				} else static if (is (A : ItemCard)) {
					_comm.refItem.call(a);
				} else static if (is (A : BeastCard)) {
					_comm.refBeast.call(a);
				} else static if (is (A : InfoCard)) {
					_comm.refInfo.call(a);
				}
			}
			newId++;
		}
	}
	void reNumberingAll() {
		if (!summary) return;
		auto dlg = new MessageBox(_win, SWT.ICON_QUESTION | SWT.OK | SWT.CANCEL);
		dlg.setText(_prop.msgs.dlgTitQuestion);
		dlg.setMessage(_prop.msgs.reNumberingAll);
		if (SWT.OK == dlg.open()) {
			if (_dataWin) {
				_dataWin.reNumberingAll();
			} else if (_tableWin) {
				_tableWin.reNumberingAll();
			} else assert (0);
			if (_cardWin) {
				_cardWin.reNumberingAll();
			} else {
				_castWin.reNumberingAll();
				_skillWin.reNumberingAll();
				_itemWin.reNumberingAll();
				_beastWin.reNumberingAll();
				_infoWin.reNumberingAll();
			}
			foreach (c; summary.casts) {
				auto w = _comm.handCardWindowFrom(_prop, summary, c, false, false);
				if (w) {
					w.reNumberingAll();
				} else {
					reNumberingHands(c.skills);
					reNumberingHands(c.items);
					reNumberingHands(c.beasts);
				}
			}
		}
	}

	ReplaceDialog openReplWin() {
		if (!_replDlg || _replDlg.widget.isDisposed()) {
			_replDlg = new ReplaceDialog(_comm, _prop, _win, summary);
			_replDlg.open();
		} else {
			_replDlg.widget.setMinimized(false);
			_replDlg.widget.setActive();
		}
		return _replDlg;
	}

	bool openCWXPath(string path, bool shellActivate) {
		if (!summary) return false;
		if (_win.isVisible()) _win.setRedraw(false);
		scope (exit) {
			if (_win.isVisible()) _win.setRedraw(true);
		}
		bool open() {
			path = .toLower(path);
			if (cpempty(path)) {
				if (cphasattr(path, "opendialog")) {
					if (_dataWin) {
						_dataWin.editSummary();
					} else {
						_tableWin.editSummary();
					}
					return true;
				}
			}
			auto cate = cpcategory(path);
			switch (cate) {
			case "", "area", "battle", "package", "area:id", "battle:id", "package:id", "variable",
					"tableview", "variableview": {
				if (_dataWin) {
					return _dataWin.openCWXPath(path, shellActivate);
				} else if (cate == "variable" || cate == "variableview") {
					return _flagWin.openCWXPath(path, shellActivate);
				} else {
					return _tableWin.openCWXPath(path, shellActivate);
				}
			} case "castcard", "skillcard", "itemcard", "beastcard", "infocard",
					"castcard:id", "skillcard:id", "itemcard:id", "beastcard:id", "infocard:id",
					"castcardview", "skillcardview", "itemcardview", "beastcardview", "infocardview": {
				if (_cardWin) {
					return _cardWin.openCWXPath(path, shellActivate);
				} else {
					assert (_castWin);
					assert (_skillWin);
					assert (_itemWin);
					assert (_beastWin);
					assert (_infoWin);
					switch (cate) {
					case "castcard", "castcard:id", "castcardview":
						return _castWin.openCWXPath(path, shellActivate);
					case "skillcard", "skillcard:id", "skillcardview":
						return _skillWin.openCWXPath(path, shellActivate);
					case "itemcard", "itemcard:id", "itemcardview":
						return _itemWin.openCWXPath(path, shellActivate);
					case "beastcard", "beastcard:id", "beastcardview":
						return _beastWin.openCWXPath(path, shellActivate);
					case "infocard", "infocard:id", "infocardview":
						return _infoWin.openCWXPath(path, shellActivate);
					default:
						return false;
					}
				}
			} case "fileview": {
				if (_dirWin) {
					return _dirWin.openCWXPath(path, shellActivate);
				}
			} default: return false;
			}
		}
		bool r = true;
		string[] paths;
		if (path.length) {
			paths = std.string.split(path, CWXPATH_SEP.idup);
		} else {
			paths = [path];
		}
		foreach (p; paths) {
			if (open()) {
				_win.setMinimized(false);
				if (shellActivate) _win.forceActive();
			} else {
				r = false;
			}
		}
		return r;
	}
	@property
	string[] openedCWXPath() {
		string[] r;
		if (!_dock) return r;
		foreach (paneKey; _dock.paneKeys) {
			foreach (ctrl; _dock.controls(paneKey)) {
				auto tlpData = cast(TLPData) ctrl.getData();
				if (tlpData.tlp is this) continue;
				assert (tlpData);
				r ~= tlpData.tlp.openedCWXPath;
			}
			// ペイン内で選択中のタブを末尾に追加
			string ctrlKey = _dock.selectedCtrl(paneKey);
			if ("" != ctrlKey) {
				auto ctrl = _dock.control(ctrlKey);
				assert (ctrl);
				auto tlpData = cast(TLPData) ctrl.getData();
				assert (tlpData);
				if (tlpData.tlp !is this) {
					r ~= tlpData.tlp.openedCWXPath;
				}
			}
		}
		// 現在フォーカスのあるコントロールを末尾に追加
		auto d = _win.getDisplay();
		auto fc = d.getFocusControl();
		while (fc) {
			auto tlpData = cast(TLPData) fc.getData();
			if (tlpData && tlpData.tlp !is this) {
				r ~= tlpData.tlp.openedCWXPath;
				break;
			}
			fc = fc.getParent();
		}
		return array(uniq(r));
	}

	void doCWX() {
		if (!_win) return;
		string dStr = .text(__LINE__);
		try {
			version (Console) {
				debug std.stdio.writeln("Start Main Thread");
			}
			auto d = _win.getDisplay();
			_win.open();
			dStr ~= " - " ~ .text(__LINE__);
			if (_opt.create) {
				string name = _opt.createName is null ? _prop.msgs.newScenarioName : _opt.createName;
				string skin = _opt.createSkin is null ? _prop.var.etc.defaultSkin : _opt.createSkin;
				auto summ = Summary.createScenario(_prop.tempPath, name, findSkin2(_prop, skin));
				summ.author = _prop.var.etc.defaultAuthor;
				openScenario(summ);
				statusLine = "";
			} else if (_opt.createclassic) {
				string name = _opt.createName is null ? _prop.msgs.newScenarioName : _opt.createName;
				if (_opt.createclassicPath is null || !_opt.createclassicPath.length) {
					_opt.createclassicPath = CreateScenarioDialog.createClassicDir(_prop, _win);
				}
				if (_opt.createclassicPath !is null && _opt.createclassicPath.length) {
					try {
						if (!.exists(_opt.createclassicPath)) {
							mkdirRecurse(_opt.createclassicPath);
						}
						auto summ = new Summary(name, _prop.var.etc.defaultSkin, _opt.createclassicPath, false, true);
						summ.author = _prop.var.etc.defaultAuthor;
						openScenario(summ);
						statusLine = "";
					} catch (Exception e) {
						debugln(e);
					}
				}
			} else if (_opt.scenario) {
				dStr ~= " - " ~ .text(__LINE__);
				openScenario(_opt.scenario, &resetOpt);
			} else if (_prop.var.etc.openLastScenario && _prop.var.etc.lastScenario.length) {
				dStr ~= " - " ~ .text(__LINE__);
				openScenario(_prop.var.etc.lastScenario, &resetOpt);
			}
			dStr ~= " - " ~ .text(__LINE__);

			_pipeName = createPipeName();
			auto pipe = new core.thread.Thread(&pipeThr);
			if (_pipeName.length) {
				pipe.start();
			}
			auto backup = new core.thread.Thread(&backupThr);
			backup.start();
			version (Windows) {
				scope (exit) {
					auto p = CreateFileW(toUTFz!(wchar*)(_pipeName),
						GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
					if (p != INVALID_HANDLE_VALUE) {
						scope (exit) CloseHandle(p);
						string pmsg = "quit";
						DWORD len;
						WriteFile(p, pmsg.ptr, pmsg.length, &len, null);
					}
				}
			} else {
				scope (exit) {
					auto fd = open(std.string.toStringz(_pipeName), O_WRONLY, 0);
					if (fd != -1) {
						scope (exit) close(fd);
						string pmsg = "quit";
						cwrite(fd, pmsg.ptr, pmsg.length);
					}
				}
			}
			dStr ~= " - " ~ .text(__LINE__);
			bool openErrDlg = false;
			version (Console) debug {
				initTimer.stop();
				cwriteln(.format("Starting time: %d msecs", initTimer.peek().msecs));
			}
			while (!_win.isDisposed()) {
				version (nocatch) {
					if (!d.readAndDispatch()) {
						d.sleep();
					}
				} else {
					// なるべくユーザデータを消さないよう、例外が発生しても処理を続行する。
					try {
						if (!d.readAndDispatch()) {
							d.sleep();
						}
					} catch (Throwable e) {
						if (!openErrDlg) {
							// 際限の無い連続発生を抑制
							openErrDlg = true;
							_win.setVisible(true);
							fdebugln(e);
							string s = createDebugln(e);
							auto dlg = new ErrorDialog(_comm, _prop, _win, s);
							dlg.closeEvent ~= {
								openErrDlg = false;
							};
							dlg.open();
						} else {
							core.thread.Thread.sleep(.dur!("msecs")(1));
						}
					}
				}
			}
			// 各要素が絡み合うため、必ずこの順序で各スレッドとリソースを解放する
			_quit = true;
			dStr ~= " - " ~ .text(__LINE__);
			backup.join();
			dStr ~= " - " ~ .text(__LINE__);
			_dirWin.quitTrace();
			dStr ~= " - " ~ .text(__LINE__);
			_comm.dispose();
			dStr ~= " - " ~ .text(__LINE__);
			_prop.images.disposeImages();
			dStr ~= " - " ~ .text(__LINE__);
			d.dispose();
			dStr ~= " - " ~ .text(__LINE__);
			_prop.var.save(dock);
			dStr ~= " - " ~ .text(__LINE__);
			sendReloadProps();
			_prop.var.cleanup();
			version (Console) {
				debug writeln("Exit Main Thread");
			}
		} catch (Throwable e) {
			// 起動・終了失敗
			fdebugln(dStr);
			fdebugln(e);
			throw e;
		}
	}
}

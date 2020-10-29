
module cwx.editor.gui.dwt.mainwindow;

import cwx.archive;
import cwx.area;
import cwx.binary;
import cwx.cab;
import cwx.card;
import cwx.cwl;
import cwx.event;
import cwx.filesync;
import cwx.flag;
import cwx.graphics;
import cwx.menu;
import cwx.path;
import cwx.props;
import cwx.skin;
import cwx.structs;
import cwx.summary;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.win32res;
import cwx.xml;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.cardwindow;
import cwx.editor.gui.dwt.castcarddialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtoolbar;
import cwx.editor.gui.dwt.datawindow;
import cwx.editor.gui.dwt.directorywindow;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.flagspane;
import cwx.editor.gui.dwt.history;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.loader;
import cwx.editor.gui.dwt.namewindow;
import cwx.editor.gui.dwt.partyhistory;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.replacedialog;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.settingsdialog;
import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.xmlbytestransfer;

import core.memory;
import core.sync.mutex;
import core.thread;

import std.algorithm;
import std.array;
import std.conv;
import std.csv;
import std.datetime;
import std.exception;
import std.file;
import std.functional;
import std.path;
import std.process;
import std.range;
import std.regex;
import std.string;
import std.typecons;
import std.utf;
version (Win64) {
	import std.zip;
} else {
	import d2std.zip;
	static import d2std.zlib;
}

debug import std.stdio;

import org.eclipse.swt.all;
alias org.eclipse.swt.widgets.MessageBox.MessageBox DWTMessageBox;

import java.lang.all;

version (Windows) {
	import core.sys.windows.windows;
	private extern (Windows) {
		import core.stdc.wchar_;
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
		import core.sys.posix.fcntl;
		import core.sys.posix.unistd;
		import core.sys.posix.sys.socket;
		import core.sys.posix.sys.time;
		alias core.sys.posix.unistd.read cread;
		alias core.sys.posix.unistd.write cwrite;
		alias core.sys.posix.sys.socket.bind cbind;
	} else { mixin(S_TRACE);
		import core.sys.unix.unix;
		alias core.sys.unix.unix.read cread;
		alias core.sys.unix.unix.write cwrite;
		alias core.sys.unix.unix.bind cbind;
	}
	import core.stdc.string;
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
	Object _displayMutex = null;
	bool _quit = false;
	FileSync _sync = null;
	Mutex _saveSync = null;
	bool _inSaving = false;
	private bool _isChanged = false;

	SBShell _sbshl = null;
	Shell _win = null;
	DockingFolderCTC _dock = null;

	Props _prop;
	Commons _comm;

	TableWindow _tableWin = null;
	FlagWindow _flagWin = null;
	CardWindow _castWin = null;
	CardWindow _skillWin = null;
	CardWindow _itemWin = null;
	CardWindow _beastWin = null;
	CardWindow _infoWin = null;
	DirectoryWindow _dirWin = null;

	CouponWindow _couponWin = null;
	GossipWindow _gossipWin = null;
	CompleteStampWindow _completeStampWin = null;
	KeyCodeWindow _keyCodeWin = null;
	CellNameWindow _cellNameWin = null;
	CardGroupWindow _cardGroupWin = null;

	string _bassDir = "";
	RefreshTitle _refreshTitle;

	Menu _mExecEngine;
	Menu _tmExecEngine;
	ToolItem _tiExecEngine;
	Menu _mExecEngineWithParty;
	Menu _tmExecEngineWithParty;
	ToolItem _tiExecEngineWithParty;
	void refreshExecEngine() { mixin(S_TRACE);
		refreshExecEngineImpl(_mExecEngine, _mExecEngineWithParty, true);
		auto ePath = refreshExecEngineImpl(_tmExecEngine, _tmExecEngineWithParty, false);
		// ツールボタンのアイコン
		Image exeIcon = null;
		if (_tiExecEngine) { mixin(S_TRACE);
			if (!.cfnmatch(ePath.extension(), ".py")) { mixin(S_TRACE);
				version (Windows) {
					auto id = loadIcon(ePath, 16.ppis, 16.ppis);
					if (id) { mixin(S_TRACE);
						exeIcon = new Image(_tiExecEngine.getDisplay(), id);
					}
				}
			}
			if (exeIcon) { mixin(S_TRACE);
				auto img = _tiExecEngine.getImage();
				if (img && _prop.images.menu(MenuID.ExecEngineAuto) !is img) { mixin(S_TRACE);
					img.dispose();
				}
				_tiExecEngine.setImage(exeIcon);
			}
		}
		setupMenu(_menu);
		setupMenu(_tool);
	}

	private string origScenarioPath() { mixin(S_TRACE);
		if (summary.readOnlyPath != "") { mixin(S_TRACE);
			return summary.readOnlyPath;
		} else if (summary.useTemp && summary.origZipName != "") { mixin(S_TRACE);
			return summary.origZipName;
		} else { mixin(S_TRACE);
			return summary.scenarioPath;
		}
	}

	string refreshExecEngineImpl(Menu menu, Menu mWithParty, bool autoSelect) { mixin(S_TRACE);
		if (menu) { mixin(S_TRACE);
			foreach (itm; menu.getItems()) { mixin(S_TRACE);
				itm.dispose();
			}
		}
		if (mWithParty) { mixin(S_TRACE);
			foreach (itm; mWithParty.getItems()) { mixin(S_TRACE);
				itm.dispose();
			}
		}
		MenuItem autoMI = null, autoMI2 = null;
		if (autoSelect) { mixin(S_TRACE);
			if (menu) { mixin(S_TRACE);
				autoMI = createMenuItem(_comm, menu, MenuID.ExecEngineAuto, &execEngine, &canExecEngine);
				_menu[MenuID.ExecEngine] = autoMI;
			}
			if (mWithParty) { mixin(S_TRACE);
				autoMI2 = createMenuItem(_comm, mWithParty, MenuID.ExecEngineWithLastParty, &execEngineWithLastParty, &canExecEngineWithLastParty2);
				_menu[MenuID.ExecEngineWithLastParty] = autoMI2;
				updateExecEngineWithPartyNameMI();
			}
		}

		.createExecEngineMenu(_comm, menu, mWithParty, &canExecEngineWithParty, &origScenarioPath, epKey => true, &execEngineP, &canExecClassic);

		if (mWithParty && (_prop.var.etc.executedPartyBookmarks.length || _prop.var.etc.executedParties.length)) { mixin(S_TRACE);
			auto num = 0;
			void put(ExecutionParty ep) { mixin(S_TRACE);
				string nstr;
				if (num < 10) { mixin(S_TRACE);
					nstr = "&" ~ to!(string)(num);
				} else { mixin(S_TRACE);
					nstr = to!(string)(num);
				}
				auto name = .tryFormat(_prop.msgs.execEngineWithParty, ep.engineName, ep.yadoName, ep.partyName);
				auto img = ep.isClassic ? _prop.images.classicEngine : _prop.images.menu(MenuID.ExecEngineMain);
				auto warn = !existsParty(_comm, ep);
				if (warn) { mixin(S_TRACE);
					img = _prop.images.warning;
				}
				auto mi = createMenuItem2(_comm, mWithParty, nstr ~ " " ~ name, img, { mixin(S_TRACE);
					auto scenario = .tryFormat(`"%s"`, origScenarioPath);
					execEngineP(ep.enginePath, scenario, ep);
				}, () => canExecEngineWithParty && (!ep.isClassic || canExecClassic));
				if (!warn) .putEngineIcon(_comm, mi, null, ep.enginePath, () => !existsParty(_comm, ep));
			}
			if (_prop.var.etc.executedPartyBookmarks.length) { mixin(S_TRACE);
				if (mWithParty.getItemCount()) new MenuItem(mWithParty, SWT.SEPARATOR);
				foreach (ep; _prop.var.etc.executedPartyBookmarks) { mixin(S_TRACE);
					put(ep);
					num++;
				}
			}
			if (_prop.var.etc.executedParties.length) { mixin(S_TRACE);
				if (mWithParty.getItemCount()) new MenuItem(mWithParty, SWT.SEPARATOR);
				foreach (ep; _prop.var.etc.executedParties) { mixin(S_TRACE);
					put(ep);
					num++;
				}
			}
		}

		if (mWithParty && 0 < _prop.var.etc.executedPartiesMax) { mixin(S_TRACE);
			if (mWithParty.getItemCount()) new MenuItem(mWithParty, SWT.SEPARATOR);
			.createMenuItem(_comm, mWithParty, MenuID.EditExecutedPartyHistory, &editExecutedPartyHistory, &canEditExecutedPartyHistory);
		}

		auto autoE = nabs(execEnginePath);
		if (autoMI || autoMI2) { mixin(S_TRACE);
			// 自動実行のアイコンを設定
			// 自動実行するエンジンに代替実行が指定されている場合は
			// エンジン本体のアイコンを使用するために差し替える
			if (autoE != "") { mixin(S_TRACE);
				foreach (i, ce; _prop.var.etc.classicEngines) { mixin(S_TRACE);
					auto p = .nabs(ce.executePath(_prop.parent.appPath, false)); // 代替実行
					auto e = ce.executePath(_prop.parent.appPath, true); // エンジン本体
					if (.cfnmatch(p, autoE)) { mixin(S_TRACE);
						// 代替実行をエンジン本体に差し替え
						autoE = e;
						break;
					}
				}
			}
			.putEngineIcon(_comm, autoMI, autoSelect ? null : autoMI2, autoE);
		}
		return autoE;
	}

	@property
	const
	bool canDelNotExistsParty() { mixin(S_TRACE);
		return 0 < _prop.var.etc.executedParties.length;
	}
	void delNotExistsParty() { mixin(S_TRACE);
		ExecutionParty[] eps;
		foreach (ep; _prop.var.etc.executedParties) { mixin(S_TRACE);
			if (.existsParty(_comm, ep)) eps ~= ep;
		}
		if (_prop.var.etc.executedParties.length == eps.length) return;
		_prop.var.etc.executedParties = eps;

		_comm.refExecutedParties.call();
		_comm.refreshToolBar();
	}
	void refExecutedParties() { mixin(S_TRACE);
		refreshExecEngineImpl(_mExecEngine, _mExecEngineWithParty, true);
		refreshExecEngineImpl(_tmExecEngine, _tmExecEngineWithParty, false);
		updateExecEngineWithPartyName();
		_prop.var.save(dock);
		sendReloadProps();
	}

	void refImportHistory() { mixin(S_TRACE);
		sendReloadPropsAndSave();
	}

	Menu _mOuterTools;
	Menu _tmOuterTools;
	void refreshOuterTools() { mixin(S_TRACE);
		if (_mOuterTools) refreshOuterToolsImpl(_mOuterTools);
		if (_tmOuterTools) refreshOuterToolsImpl(_tmOuterTools);
		setupMenu(_menu);
		setupMenu(_tool);
	}
	void refreshOuterToolsImpl(Menu menu) { mixin(S_TRACE);
		foreach (itm; menu.getItems()) { mixin(S_TRACE);
			itm.dispose();
		}
		foreach (i, tool; _prop.var.etc.outerTools) { mixin(S_TRACE);
			new Exec(_dirWin, menu, tool, cast(int)i);
		}
	}

	class RefreshTitle : Runnable {
		void run() { mixin(S_TRACE);
			if (!_win || _win.isDisposed()) return;
			if (summary) { mixin(S_TRACE);
				string path = origScenarioPath;
				if (summary.isChanged) { mixin(S_TRACE);
					_win.setText(.tryFormat(_prop.msgs.mainWindowNameChanged, summary.scenarioName, path));
					_isChanged = true;
				} else { mixin(S_TRACE);
					_win.setText(.tryFormat(_prop.msgs.mainWindowName, summary.scenarioName, path));
					_isChanged = false;
				}
			} else { mixin(S_TRACE);
				_win.setText(_prop.msgs.mainWindowNameEmpty);
				_isChanged = false;
			}
		}
	}
	void refreshTitle() { mixin(S_TRACE);
		_display.syncExec(_refreshTitle);
	}
	bool _catchedChanging = false;
	uint _changeCount = 0;
	Summary _lastBackupSummary = null;
	void updateChangeCount() { mixin(S_TRACE);
		if (_prop.var.etc.backupIntervalType == BackupType.Edit) { mixin(S_TRACE);
			if (_catchedChanging) return;
			_catchedChanging = true;
			_changeCount++;
		} else {
			_changeCount = 0;
		}
	}

	private MonoTime _lastBackup;
	void backupThr() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Start Backup Thread");
			}
			_lastBackup = MonoTime.currTime();
			_changeCount = 0;
			while (!_quit) { mixin(S_TRACE);
				if (summary) { mixin(S_TRACE);
					if (_lastBackupSummary !is summary) { mixin(S_TRACE);
						_changeCount = 0;
						_lastBackup = MonoTime.currTime();
						_lastBackupSummary = summary;
					}
					void backup() { mixin(S_TRACE);
						version (Console) {
							debug writeln("Start Backup");
						}
						if (createBackup()) { mixin(S_TRACE);
							version (Console) {
								debug writeln("Success Backup");
							}
						} else {
							version (Console) {
								debug writeln("No Write Backup");
							}
						}
						_lastBackup = MonoTime.currTime();
						_changeCount = 0;
					}
					if (_prop.var.etc.backupIntervalType == BackupType.Time) { mixin(S_TRACE);
						if (0 < _prop.var.etc.backupInterval && _lastBackup + .dur!"minutes"(_prop.var.etc.backupInterval) <= MonoTime.currTime()) { mixin(S_TRACE);
							backup();
						}
						_changeCount = 0;
					} else if (_prop.var.etc.backupIntervalType == BackupType.Edit) { mixin(S_TRACE);
						if (0 < _prop.var.etc.backupIntervalEdit && _prop.var.etc.backupIntervalEdit <= _changeCount) { mixin(S_TRACE);
							backup();
						}
						_lastBackup = MonoTime.currTime();
					}
				}
				core.thread.Thread.sleep(dur!"seconds"(1));
			}
			version (Console) {
				debug writeln("Exit Backup Thread");
			}
		} catch (Throwable e) {
			printStackTrace();
			fdebugln(e);
		}
	}
	private string _oldMD5 = "";
	bool createBackup() { mixin(S_TRACE);
		/// dir内の全てのファイルとディレクトリの更新日時のMD5値を得る。
		@property
		static string filesMD5(string dir) { mixin(S_TRACE);
			ByteIO io;
			io.writeL(dir.timeLastModified().stdTime);
			foreach (file; dir.dirEntries(SpanMode.depth)) { mixin(S_TRACE);
				io.writeL(file.timeLastModified.stdTime);
			}
			return md5Digest(io.bytes);
		}
		string dStr = .text(__LINE__);
		try { mixin(S_TRACE);
			if (_quit) return true;
			if (!_prop.var.etc.backupEnabled) return true;
			auto summ = summary;
			if (!summ) return true;

			if (_prop.var.etc.backupRefAuthor) { mixin(S_TRACE);
				if (summ.author != _prop.var.etc.defaultAuthor) return true;
			}
			if (_prop.var.etc.autoSave && summ.isChanged) { mixin(S_TRACE);
				// バックアップ前に自動セーブ
				_display.syncExec(new class Runnable {
					override void run() { mixin(S_TRACE);
						if (!_win || _win.isDisposed()) return;
						save(_win, true);
					}
				});
			}

			string parent = _prop.backupPath;

			// 既存のバックアップファイルのリスト
			auto dReg = .regex("^cwxeditor_backup_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\\[.+\\]$"d);
			auto fReg = .regex("^cwxeditor_backup_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\\[.+\\]\\.(zip|wsn)$"d);
			auto files = clistdir(parent);
			alias Tuple!(string, "name", string, "file", bool, "isDir") Info;
			Info[] backup;
			foreach (name; files) { mixin(S_TRACE);
				auto f = parent.buildPath(name);
				if (f.isFile) { mixin(S_TRACE);
					if (match(to!dstring(name), fReg).empty) continue;
					backup ~= Info(name, f, false);
				} else { mixin(S_TRACE);
					if (match(to!dstring(name), dReg).empty) continue;
					backup ~= Info(name, f, true);
				}
			}
			// 日時でソート。実際の更新日時よりファイル名に記述された日付を優先する
			auto sorter = (Info a, Info b) => .fncmp(a.name, b.name);
			backup = cwx.utils.sort!(sorter)(backup);

			bool ret = false;
			auto mkeddir = false;
			auto bc = _prop.var.etc.backupCount;
			if (0 < bc) { mixin(S_TRACE);
				string sPath = summ.scenarioPath;
				auto d = Clock.currTime();
				string name = .format("cwxeditor_backup_%04d%02d%02d%02d%02d%02d[%s]",
					d.year, d.month, d.day, d.hour, d.minute, d.second, sPath.baseName());
				if (_prop.var.etc.backupArchived) { mixin(S_TRACE);
					if (summ.legacy) { mixin(S_TRACE);
						name ~= ".zip";
					} else { mixin(S_TRACE);
						name ~= ".wsn";
					}
				}
				string writePath = std.path.buildPath(parent, name);

				if (_oldMD5 == "" && backup.length) { mixin(S_TRACE);
					auto before = backup[$ - 1];
					if (before.isDir) { mixin(S_TRACE);
						_oldMD5 = filesMD5(before.file);
					} else { mixin(S_TRACE);
						ubyte* ptr = null;
						auto lastData = readBinaryFrom!ubyte(before.file, ptr);
						scope (exit) freeAll(ptr);
						_oldMD5 = md5Digest(lastData);
						lastData[] = 0;
					}
				}
				if (_prop.var.etc.backupArchived) { mixin(S_TRACE);
					ZipArchive arc;
					ubyte*[] tempData;
					{ mixin(S_TRACE);
						_saveSync.lock();
						scope (exit) _saveSync.unlock();
						mixin(S_TRACE);
						arc = summ.createZipData([], true, name.extension().toLower() == ".wsn", tempData, _sync);
						mixin(S_TRACE);
					}
					scope (exit) {
						destroy(arc);
						freeAll(tempData);
					}
					mixin(S_TRACE);
					auto data = arc.build();
					mixin(S_TRACE);
					auto md5 = md5Digest(data);
					if (_oldMD5 != md5) { mixin(S_TRACE);
						// 前回のバックアップと異なっていれば保存
						if (!parent.exists()) { mixin(S_TRACE);
							mkeddir = true;
							mkdirRecurse(parent);
						}
						std.file.write(writePath, data);
						_oldMD5 = md5;
						bc--;
						ret = true;
					}
				} else { mixin(S_TRACE);
					auto md5 = filesMD5(summ.scenarioPath);
					if (_oldMD5 != md5) { mixin(S_TRACE);
						// 前回のバックアップと異なっていればコピー
						if (!parent.exists()) { mixin(S_TRACE);
							mkeddir = true;
							mkdirRecurse(parent);
						}
						{ mixin(S_TRACE);
							_saveSync.lock();
							scope (exit) _saveSync.unlock();
							copyAll(summ.scenarioPath, writePath);
						}
						_oldMD5 = md5;
						bc--;
						ret = true;
					}
				}
			}

			if (mkeddir) { mixin(S_TRACE);
				_display.syncExec(new class Runnable {
					override void run() { mixin(S_TRACE);
						if (!_win || _win.isDisposed()) return;
						_comm.refreshToolBar();
					}
				});
			}

			if (backup.length <= bc) return ret;

			// 古いバックアップを削除する
			foreach (f; backup[0 .. backup.length - bc]) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					delAll(f.file);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
			return ret;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		} catch (Throwable e) {
			printStackTrace();
			fdebugln(e);
			throw e;
		}
		return true;
	}

	void openScenarioNewWin() { mixin(S_TRACE);
		auto fname = selectScenario(_prop, _win, _prop.msgs.dlgTitOpenScenarioAtNewWin);
		if (!fname) return;
		bool r = exec("\"" ~ _prop.parent.appPath ~ "\" \"" ~ fname ~ "\"");
		if (!r) { mixin(S_TRACE);
			DWTMessageBox.showWarning
				(.tryFormat(_prop.msgs.errorExec, baseName(_prop.parent.appPath)),
				_prop.msgs.dlgTitWarning, _win);
		}
	}
	void createScenarioNewWin() { mixin(S_TRACE);
		auto dlg = new CreateScenarioDialog(_comm, _prop, _win, false);
		if (!dlg.open()) return;
		bool r;
		if (dlg.legacy) { mixin(S_TRACE);
			r = exec("\"" ~ _prop.parent.appPath ~ "\" -createclassic \"" ~ dlg.name ~ "\" \"" ~ dlg.classicDir ~ "\"");
		} else { mixin(S_TRACE);
			r = exec("\"" ~ _prop.parent.appPath ~ "\" -create \"" ~ dlg.name ~ "\" \"" ~ dlg.skinType ~ "\" \"" ~ dlg.skinName ~ "\"");
		}
		if (!r) { mixin(S_TRACE);
			DWTMessageBox.showWarning
				(.tryFormat(_prop.msgs.errorExec, baseName(_prop.parent.appPath)),
				_prop.msgs.dlgTitWarning, _win);
		}
	}
	void createScenario() { mixin(S_TRACE);
		if (qSave(QSaveType.create)) { mixin(S_TRACE);
			auto dlg = new CreateScenarioDialog(_comm, _prop, _win, true);
			if (!dlg.open()) return;
			Summary summ;
			if (dlg.fromTemplate) { mixin(S_TRACE);
				summ = dlg.fromTemplate;
			} else if (dlg.legacy) { mixin(S_TRACE);
				auto dir = dlg.classicDir;
				if (!dir.exists()) mkdirRecurse(dir);
				summ = new Summary(dlg.name, dlg.skinType, dlg.skinName, dir, false, true);
				auto skin = .findSkin(_comm, _prop, summ);
				Summary.createStartArea(summ , _prop.parent, _prop.var.etc.newAreaName != "", _prop.var.etc.newAreaName, _prop.bgImagesDefault(skin.type), null, _prop.enginePath,
					_prop.var.etc.classicEngineRegex, _prop.var.etc.classicDataDirRegex, _prop.var.etc.classicMatchKey,
					_prop.var.etc.classicEngines, _prop.var.etc.defaultSkin);
				{ mixin(S_TRACE);
					_saveSync.lock();
					scope (exit) _saveSync.unlock();
					summ.saveOverwrite(_prop.parent, skin, createSaveOpt(summ.legacy, true), _sync);
				}
			} else { mixin(S_TRACE);
				auto skin = .findSkin2(_prop, dlg.skinType, dlg.skinName);
				summ = Summary.createScenario(_prop.parent, _prop.tempPath, dlg.name,
					skin, _prop.var.etc.newAreaName != "",
					_prop.var.etc.newAreaName, _prop.bgImagesDefault(skin.type), _prop.var.etc.saveSkinName, _sync);
			}
			summ.author = _prop.var.etc.defaultAuthor;
			openScenario(summ, []);
			statusLine = "";
		}
	}
	class DTListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = DND.DROP_LINK;
		}
		override void drop(DropTargetEvent e) { mixin(S_TRACE);
			dropFiles(cast(FileNames)e.data);
		}
	}
	public void dropFiles(FileNames arr) { mixin(S_TRACE);
		if (arr && arr.array.length) { mixin(S_TRACE);
			if (qSave(QSaveType.open)) { mixin(S_TRACE);
				openScenario(arr.array[0], &resetOpt);
			}
		}
	}
	@property
	LoadOption loadOption(in Summary old) { mixin(S_TRACE);
		LoadOption opt;
		opt.cardOnly = false;
		opt.textOnly = false;
		opt.doubleIO = _prop.var.etc.doubleIO;
		opt.expandXMLs = old ? old.expandXMLs : _prop.var.etc.expandXMLs;
		opt.numberStepToVariantThreshold = _prop.var.etc.numberStepToVariantThreshold;
		auto d = _win.getDisplay();
		opt.processFunc = (string sName, string fileName) {
			d.asyncExec(new class Runnable {
				override void run() {
					statusLine = .tryFormat(_prop.msgs.loadingWithFile, sName, fileName);
				}
			});
		};
		return opt;
	}
	void reload() { mixin(S_TRACE);
		if (!summary) return;
		auto old = summary;
		auto readOnly = (old.useTemp && !old.origZipName.length) || old.readOnlyPath != "";
		if (old && qSave(QSaveType.reload)) { mixin(S_TRACE);
			bool expand = old.expandXMLs;
			if (old.legacy || readOnly) { mixin(S_TRACE);
				auto wsm = std.path.buildPath(old.scenarioPath, "Summary.wsm");
				if (!readOnly && old.useTemp) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						string[] errorFiles;
						auto summ = old.reloadXMLs(_prop.parent, loadOption(old), errorFiles);
						openScenario(summ, errorFiles);
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
						DWTMessageBox.showWarning(.tryFormat(_prop.msgs.reloadError, summary.scenarioPath)
							~ "\n" ~ e.msg,
							_prop.msgs.dlgTitWarning, _win);
					}
				} else { mixin(S_TRACE);
					if (!.exists(wsm)) wsm = old.scenarioPath;
					string[] errorFiles;
					if (old.readOnlyPath != "") wsm = old.readOnlyPath;
					loadScenarioFromFile(_prop, loadOption(old), errorFiles, _comm.mainShell, _sync, &setStatusLine, old, wsm, &openScenario, &resetOpt);
				}
			} else if (expand) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					string[] errorFiles;
					_sync.sync();
					openScenario(old.reloadXMLs(_prop.parent, loadOption(old), errorFiles), errorFiles);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
					DWTMessageBox.showWarning(.tryFormat(_prop.msgs.reloadError, summary.scenarioPath)
						~ "\n" ~ e.msg,
						_prop.msgs.dlgTitWarning, _win);
				}
			} else { mixin(S_TRACE);
				auto path = old.origZipName != "" ? old.origZipName : old.readOnlyPath;
				string[] errorFiles;
				loadScenarioFromFile(_prop, loadOption(old), errorFiles, _comm.mainShell, _sync, &setStatusLine, old, path, &openScenario, &resetOpt);
			}
		}
	}
	void openScenarioM() { mixin(S_TRACE);
		if (qSave(QSaveType.open)) { mixin(S_TRACE);
			openScenario();
		}
	}
	int cmp(string a, string b) { mixin(S_TRACE);
		return std.string.cmp(a, b);
	}
	int ncmp(string a, string b) { mixin(S_TRACE);
		return cwx.utils.ncmp(a, b);
	}
	void openScenario(Summary summ, const string[] errorFiles) { mixin(S_TRACE);
		string dStr = .text(__LINE__);
		if (_prop.var.etc.cautionToScenarioLoadErrors && errorFiles.length) { mixin(S_TRACE);
			auto d = new ScenarioErrorFilesDialog(_comm, _win, summ, errorFiles);
			if (!d.open()) return;
		}
		dStr ~= " - " ~ .text(__LINE__);
		try { mixin(S_TRACE);
			assert (summ);
			dStr ~= " - " ~ .text(__LINE__);
			OpenHistory hist;
			auto skin = _comm.findSkinFromHistory(summ, hist);
			dStr ~= " - " ~ .text(__LINE__);
			if (summ.legacy && hist.path.length && (hist.skinType.length || hist.skinEngine.length)) { mixin(S_TRACE);
				summ.type = hist.skinType;
			}
			if (summ.legacy && hist.skinName.length) { mixin(S_TRACE);
				summ.skinName = hist.skinName;
			}
			if (summ.type == "" && !summ.legacy) { mixin(S_TRACE);
				summ.type = _prop.var.etc.defaultSkin;
			}
			if (summ.skinName == "" && !summ.legacy) { mixin(S_TRACE);
				summ.skinName = _prop.var.etc.defaultSkinName;
			}
			dStr ~= " - " ~ .text(__LINE__);
			_lastBackup = MonoTime.currTime();
			dStr ~= " - " ~ .text(__LINE__);
			_dirWin.stopTrace();
			dStr ~= " - " ~ .text(__LINE__);
			scope (exit) _dirWin.resumeTrace();
			dStr ~= " - " ~ .text(__LINE__);
			auto old = summary;
			if (old) { mixin(S_TRACE);
				addHistory();
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (summ.type.length && !hasSkin(_prop, summ.type)
					&& summ.type != _prop.var.etc.defaultSkin) { mixin(S_TRACE);
				DWTMessageBox.showWarning(.tryFormat(_prop.msgs.useDefaultSkin, summ.type, _prop.var.etc.defaultSkin),
					_prop.msgs.dlgTitWarning, _win);
				summ.type = _prop.var.etc.defaultSkin;
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (summ.legacy || summ.toWsnProcessing) { mixin(S_TRACE);
				// BUG: クラシックなシナリオで、アイテムの一枚目に「カード交換」を持っている
				//      キャラクターには本来の「カード交換」が配付されない
				//      CardWirth 1.50
				auto exchangeName = skin.actionCardName(_prop.sys, ActionCardType.Exchange);
				foreach (c; summ.casts) { mixin(S_TRACE);
					auto hasExchange = c && c.items.length && summ.baseCard(c.items[0]).name == exchangeName;
					if (!hasExchange) continue;
					foreach (user; summ.useCounter.values(toCastId(c.id))) { mixin(S_TRACE);
						auto ec = cast(EnemyCard)user.owner;
						if (!ec) continue;
						ec.action(ActionCardType.Exchange, false);
					}
				}
			}
			dStr ~= " - " ~ .text(__LINE__);
			summ.resetChanged();
			dStr ~= " - " ~ .text(__LINE__);
			_comm.skin = skin;
			dStr ~= " - " ~ .text(__LINE__);
			_comm.closeAll();
			dStr ~= " - " ~ .text(__LINE__);
			_tableWin.load(summ);
			dStr ~= " - " ~ .text(__LINE__);
			_flagWin.load(summ);
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
			_couponWin.summary = summ;
			_gossipWin.summary = summ;
			_completeStampWin.summary = summ;
			_keyCodeWin.summary = summ;
			_cellNameWin.summary = summ;
			_cardGroupWin.summary = summ;
			dStr ~= " - " ~ .text(__LINE__);
			_comm.refScenario.call(summ);
			dStr ~= " - " ~ .text(__LINE__);
			_comm.refScenarioName.call();
			dStr ~= " - " ~ .text(__LINE__);
			_comm.refScenarioPath.call();
			dStr ~= " - " ~ .text(__LINE__);
			setupMenu(_menu);
			dStr ~= " - " ~ .text(__LINE__);
			setupMenu(_tool);
			dStr ~= " - " ~ .text(__LINE__);
			bool opened = false;
			dStr ~= " - " ~ .text(__LINE__);
			string openedS = "";
			dStr ~= " - " ~ .text(__LINE__);
			if (_prop.var.etc.reconstruction && !_opt.noload) { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				auto paths = fullHistToCWXPaths(hist.path);
				dStr ~= " - " ~ .text(__LINE__);
				if (paths.length) { mixin(S_TRACE);
					statusLine = .tryFormat(_prop.msgs.reconstructionStatus, 0, paths.length);
					dStr ~= " - " ~ .text(__LINE__);
					foreach (i, cwxPath; paths) { mixin(S_TRACE);
						if (_comm.stopOpen) break;
						dStr ~= " - " ~ .text(__LINE__);
						dStr ~= " - " ~ cwxPath;
						if (openCWXPath(cwxPath, false)) { mixin(S_TRACE);
							opened = true;
							openedS = statusLine;
							statusLine = .tryFormat(_prop.msgs.reconstructionStatus, i + 1, paths.length);
						} else { mixin(S_TRACE);
							statusLine = .tryFormat(_prop.msgs.reconstructionStatus, i + 1, paths.length);
						}
					}
				}
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (_opt.selectfile.length) { mixin(S_TRACE);
				_comm.openCWXPath("fileview", false);
				_dirWin.select(_opt.selectfile, true);
			}
			foreach (path; _opt.openPaths) { mixin(S_TRACE);
				if (_comm.stopOpen) break;
				try { mixin(S_TRACE);
					if (openCWXPath(path, true)) { mixin(S_TRACE);
						continue;
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
				DWTMessageBox.showWarning(.tryFormat(_prop.msgs.cwxPathOpenError, path), _prop.msgs.dlgTitWarning, _win);
			}
			dStr ~= " - " ~ .text(__LINE__);
			resetOpt();
			dStr ~= " - " ~ .text(__LINE__);
			addHistory();
			dStr ~= " - " ~ .text(__LINE__);
			try { mixin(S_TRACE);
				if (old && !.cfnmatch(old.scenarioPath.nabs(), summary.scenarioPath.nabs())) { mixin(S_TRACE);
					_saveSync.lock();
					scope (exit) _saveSync.unlock();
					old.delTemp();
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (!opened || !openedS.length) { mixin(S_TRACE);
				statusLine = .tryFormat(_prop.msgs.loaded, summ.scenarioName);
			} else { mixin(S_TRACE);
				statusLine = openedS;
			}
			dStr ~= " - " ~ .text(__LINE__);
			auto chgEvtForce = new class Runnable {
				override void run() { mixin(S_TRACE);
					if (!_win || _win.isDisposed()) return;
					updateChangeCount();
					_comm.changed.call();
				}
			};
			dStr ~= " - " ~ .text(__LINE__);
			auto chgEvt = new class Runnable {
				override void run() { mixin(S_TRACE);
					if (!_win || _win.isDisposed()) return;
					refreshTitle();
				}
			};
			dStr ~= " - " ~ .text(__LINE__);
			summ.changedEventForce ~= { mixin(S_TRACE);
				_display.syncExec(chgEvtForce);
			};
			dStr ~= " - " ~ .text(__LINE__);
			summ.changedEvent ~= { mixin(S_TRACE);
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
			updateExecEngineWithPartyNameTI();
			_comm.clearExpanded();
			_comm.refreshToolBar();
			dStr ~= " - " ~ .text(__LINE__);
		} catch (Throwable e) {
			printStackTrace();
			fdebugln(dStr);
			fdebugln(e);
			throw e;
		}
	}
	LaunchOption _opt;
	void resetOpt() { mixin(S_TRACE);
		_opt.openPaths.length = 0u;
		_opt.selectfile = "";
		_opt.scenario = "";
		_opt.noload = false;
	}

	void openScenarioImpl(Summary summ, const string[] errorFiles) { mixin(S_TRACE);
		if (summ) { mixin(S_TRACE);
			openScenario(summ, errorFiles);
			foreach (path; _opt.openPaths) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					if (openCWXPath(path, true)) { mixin(S_TRACE);
						continue;
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
				DWTMessageBox.showWarning(.tryFormat(_prop.msgs.cwxPathOpenError, path), _prop.msgs.dlgTitWarning, _win);
			}
			_opt.openPaths.length = 0u;
			_comm.refreshToolBar();
		}
	}
	void openScenario() { mixin(S_TRACE);
		auto old = summary;
		string[] errorFiles;
		loadScenario(_prop, loadOption(null), errorFiles, _comm.mainShell, _sync, &setStatusLine,
			old, _prop.msgs.dlgTitOpenScenario,
			_opt.openPaths, &openScenarioImpl, &resetOpt);
	}
	void openScenario(string fname, void delegate() failure) { mixin(S_TRACE);
		if (cfnmatch(.extension(fname), ".wsm") && !.exists(fname)) { mixin(S_TRACE);
			fname = dirName(fname);
		}
		decScenarioPath(fname, _opt.openPaths, _prop.var.etc.clickIsOpenEvent);
		auto old = summary;
		string[] errorFiles;
		loadScenarioFromFile(_prop, loadOption(null), errorFiles, _comm.mainShell, _sync, &setStatusLine,
			old, fname, &openScenarioImpl, failure);
	}
	void playSavedSound() { mixin(S_TRACE);
		string file = _prop.var.etc.savedSound;
		if (file.length && .exists(file)) { mixin(S_TRACE);
			playSE(file, 0, 1, lastSoundType, true);
		}
	}
	void saveScenario() { mixin(S_TRACE);
		auto fc = _win.getDisplay().getFocusControl();
		save(fc ? fc.getShell() : _win);
	}
	void savec(Shell shell) { mixin(S_TRACE);
		save(shell);
	}
	SaveOption createSaveOpt(bool isClassic, bool initial) { mixin(S_TRACE);
		SaveOption opt;
		opt.doubleIO = _prop.var.etc.doubleIO;
		opt.saveInnerImagePath = _prop.var.etc.saveInnerImagePath;
		opt.logicalSort = _prop.var.etc.logicalSort;
		if (initial) { mixin(S_TRACE);
			opt.saveChangedOnly = false;
		} else { mixin(S_TRACE);
			opt.saveChangedOnly = isClassic ? _prop.var.etc.saveChangedOnly : _prop.var.etc.saveChangedOnlyWsn;
		}
		opt.xmlFileNameIsIDOnly = _prop.var.etc.xmlFileNameIsIDOnly;
		opt.backup = _prop.var.etc.backupBeforeSaveEnabled && !initial;
		opt.backupDir = _prop.backupBeforeSavePath.buildPath(_prop.var.etc.backupBeforeSaveDir);
		if (opt.backup && !initial && !opt.backupDir.exists()) mkdirRecurse(opt.backupDir);
		opt.archiveInNewThread = _prop.var.etc.archiveInNewThread && !initial && summary.useTemp;
		opt.autoUpdateJpy1File = _prop.var.etc.autoUpdateJpy1File;
		opt.saveSkinName = _prop.var.etc.saveSkinName;
		opt.dataVersion = 4;
		opt.replaceClassicResourceExtension = _prop.var.etc.replaceClassicResourceExtension;
		opt.tableExtension = _prop.var.etc.tableExtension;
		opt.midiExtension = _prop.var.etc.midiExtension;
		opt.waveExtension = _prop.var.etc.waveExtension;
		if (opt.archiveInNewThread && !initial) { mixin(S_TRACE);
			opt.savedCallback = { mixin(S_TRACE);
				synchronized (_displayMutex) { mixin(S_TRACE);
					if (_display) { mixin(S_TRACE);
						_display.asyncExec(new class Runnable {
							override void run() { mixin(S_TRACE);
								_inSaving = false;
								if (!_win.isDisposed()) {
									updateExecEngineWithPartyNameTI();
									_comm.refreshToolBar();
								}
							}
						});
					}
				}
			};
		}
		return opt;
	}
	void beforeSave() { mixin(S_TRACE);
		_sync.sync();
		if (_prop.var.etc.applyDialogsBeforeSave) { mixin(S_TRACE);
			foreach (shell; _display.getShells()) { mixin(S_TRACE);
				auto dlg = cast(AbsDialog)shell.getData();
				if (!dlg) continue;
				if (dlg.noScenario) continue;
				if (dlg.noApply) dlg.forceApply();
			}
		}
		if (_prop.var.etc.archiveInNewThread && summary.useTemp) { mixin(S_TRACE);
			_inSaving = true;
			_comm.refreshToolBar();
		}
	}
	bool save(Shell shell, bool backupSave = false) { mixin(S_TRACE);
		if (summary) { mixin(S_TRACE);
			_dirWin.pauseTrace();
			scope (exit) {
				_dirWin.resumeTrace();
			}
			if (!summary.isSaved) { mixin(S_TRACE);
				// いまだ保存されていない場合は名前をつけて保存
				if (backupSave) return false;
				return saveScenarioAImpl(shell);
			} else { mixin(S_TRACE);
				auto cursors = setWaitCursors(shell);
				scope (exit) {
					resetCursors(cursors);
				}
				try { mixin(S_TRACE);
					beforeSave();
					{ mixin(S_TRACE);
						_saveSync.lock();
						scope (exit) _saveSync.unlock();
						summary.saveOverwrite(_prop.parent, _comm.skin, createSaveOpt(summary.legacy, false), _sync);
					}
					_comm.saved.call();
					refreshTitle();
					addHistory();
					core.memory.GC.collect();
					playSavedSound();
					_comm.refreshToolBar();
					return true;
				} catch (SummaryException e) {
					printStackTrace();
					debugln(e);
					DWTMessageBox.showWarning(e.msg, _prop.msgs.dlgTitWarning, shell);
					return false;
				}
			}
		}
		return true;
	}
	void saveScenarioA() { mixin(S_TRACE);
		saveScenarioAImpl(_win);
	}
	bool saveScenarioAImpl(Shell shell) { mixin(S_TRACE);
		if (summary) { mixin(S_TRACE);
			static immutable FILTER_WSN = 0;
			static immutable FILTER_XML = 1;
			static immutable FILTER_WSM = 2;
			static immutable FILTER_ZIP = 3;
			ptrdiff_t filterCab = -1;
			string[] filters = ["*.wsn", "Summary.xml", "Summary.wsm", "*.zip"];
			string[] names = [_prop.msgs.filterScenarioSave, _prop.msgs.filterScenarioSaveDir, _prop.msgs.filterScenarioSaveClassic, _prop.msgs.filterScenarioSaveZip];
			if (canUncab) { mixin(S_TRACE);
				filterCab = filters.length;
				filters ~= "*.cab";
				names ~= _prop.msgs.filterScenarioSaveCab;
			}
			// クラシック(データバージョン=7)のエクスポート
			auto filterClassic7 = filters.length;
			filters ~= "Summary.wsm";
			names ~= _prop.msgs.filterScenarioSaveClassic7;
			auto filterZip7 = filters.length;
			filters ~= "*.zip";
			names ~= _prop.msgs.filterScenarioSaveZip7;
			ptrdiff_t filterCab7 = -1;
			if (canUncab) { mixin(S_TRACE);
				filterCab7 = filters.length;
				filters ~= "*.cab";
				names ~= _prop.msgs.filterScenarioSaveCab7;
			}

			string fname = null;
			int filter = FILTER_WSN;
			if (summary.legacy) { mixin(S_TRACE);
				filter = FILTER_WSM;
			}
			bool classic;
			bool exportSc = false;
			string filterPath = scenarioFilterPath(_prop);
			string fileName;
			if (summary.readOnlyPath != "") { mixin(S_TRACE);
				fileName = setExtension(summary.readOnlyPath.baseName(), filters[filter].extension());
			} else if (summary.origZipName == "") { mixin(S_TRACE);
				fileName = toFileName(setExtension(summary.scenarioName, filters[filter].extension()));
			} else { mixin(S_TRACE);
				fileName = setExtension(summary.origZipName.baseName(), filters[filter].extension());
			}
			if (filters[filter] == "Summary.xml" || filters[filter] == "Summary.wsm") { mixin(S_TRACE);
				fileName = filters[filter];
			}
			while (true) { mixin(S_TRACE);
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
				bool checkDir() { mixin(S_TRACE);
					if (dir.clistdir().length) { mixin(S_TRACE);
						auto dlg = new DWTMessageBox(shell, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
						dlg.setMessage(.tryFormat(_prop.msgs.saveToNotEmptyDir, dir));
						dlg.setText(_prop.msgs.dlgTitQuestion);
						if (SWT.YES != dlg.open()) { mixin(S_TRACE);
							return false;
						}
					}
					return true;
				}
				if (filter == -1) { mixin(S_TRACE);
					break;
				} else if (filter == FILTER_WSN) { mixin(S_TRACE);
					classic = false;
				} else if (filter == FILTER_XML) { mixin(S_TRACE);
					fname = dir.buildPath("Summary.xml");
					if (!checkDir()) continue;
					classic = false;
				} else if (filter == FILTER_WSM || filter == filterClassic7) { mixin(S_TRACE);
					fname = dir.buildPath("Summary.wsm");
					if (!checkDir()) continue;
					classic = true;
				} else if (filter == FILTER_ZIP || filter == filterCab || filter == filterZip7 || filter == filterCab7) { mixin(S_TRACE);
					classic = true;
				} else { mixin(S_TRACE);
					break;
				}
				if (!summary.legacy && classic) { mixin(S_TRACE);
					auto dlg = new DWTMessageBox(shell, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
					dlg.setMessage(_prop.msgs.warningXToClassic);
					dlg.setText(_prop.msgs.dlgTitQuestion);
					if (SWT.YES != dlg.open()) { mixin(S_TRACE);
						continue;
					}
				}
				exportSc = filter == filterClassic7 || filter == filterZip7 || filter == filterCab7;
				break;
			}
			if (fname) { mixin(S_TRACE);
				auto cursors = setWaitCursors(shell);
				scope (exit) resetCursors(cursors);
				_dirWin.pauseTrace();
				scope (exit) _dirWin.resumeTrace();
				string tempPath = _prop.tempPath;
				bool expandXMLs = _prop.var.etc.expandXMLs;
				Skin defSkin = .findSkin2(_prop, _prop.var.etc.defaultSkin, _prop.var.etc.defaultSkinName);
				try { mixin(S_TRACE);
					beforeSave();
					auto oldClassic = summary.legacy;
					auto oldSkin = _comm.skin;
					auto newSkin = findSkin(_comm, _prop, summary, classic, fname, oldSkin.type);
					if (newSkin.isEmpty) newSkin = defSkin;
					if (!exportSc) { mixin(S_TRACE);
						_comm.skin = newSkin;
						_comm.updateSkinMaterialsExtension(summary.useCounter, oldSkin, _comm.skin);
					}
					{ mixin(S_TRACE);
						_saveSync.lock();
						scope (exit) _saveSync.unlock();
						if (exportSc) { mixin(S_TRACE);
							auto opt = createSaveOpt(summary.legacy, false);
							opt.dataVersion = 7;
							summary.exportClassicScenario(_prop.parent, newSkin, opt, fname, tempPath, (string msg) { mixin(S_TRACE);
								DWTMessageBox.showWarning(msg, _prop.msgs.dlgTitWarning, shell);
							}, _sync);
						} else { mixin(S_TRACE);
							summary.saveWithName(_prop.parent, newSkin, createSaveOpt(summary.legacy, false),
								fname, tempPath, expandXMLs, defSkin, (string msg) { mixin(S_TRACE);
									DWTMessageBox.showWarning(msg, _prop.msgs.dlgTitWarning, shell);
								}, classic, _sync);
						}
					}
					_comm.saved.call();
					refreshTitle();
					if (!exportSc) { mixin(S_TRACE);
						_comm.refScenarioPath.call();
						_comm.refSkin.call();
						if (oldClassic != summary.legacy) _comm.refDataVersion.call();
						_comm.refPaths.call("");
						addHistory();
					}
					core.memory.GC.collect();
					playSavedSound();
				} catch (SummaryException e) {
					printStackTrace();
					debugln(e);
					DWTMessageBox.showWarning(e.msg, _prop.msgs.dlgTitWarning, shell);
				}
			}
		}
		return false;
	}
	void updateExecEngineWithPartyName() { mixin(S_TRACE);
		updateExecEngineWithPartyNameTI();
		updateExecEngineWithPartyNameMI();
	}
	void updateExecEngineWithPartyNameMI() { mixin(S_TRACE);
		auto mi = _menu.get(MenuID.ExecEngineWithLastParty, null);
		if (!mi) return;
		if (_prop.var.etc.lastExecutedParty.enginePath == "") { mixin(S_TRACE);
			mi.setText(_prop.var.menu.buildMenu(_prop.parent, MenuID.ExecEngineWithLastParty));
		} else { mixin(S_TRACE);
			auto m = _prop.var.menu.mnemonic(MenuID.ExecEngineWithLastParty);
			auto h = _prop.var.menu.hotkey(MenuID.ExecEngineWithLastParty);
			auto s = execEngineWithLastPartyText;
			mi.setText(MenuProps.buildMenu(s, m, h, false));
		}
	}
	void updateExecEngineWithPartyNameTI() { mixin(S_TRACE);
		if (!_tiExecEngineWithParty) return;
		if (canExecEngineWithLastParty2) { mixin(S_TRACE);
			auto m = _prop.var.menu.mnemonic(MenuID.ExecEngineWithLastParty);
			auto h = _prop.var.menu.hotkey(MenuID.ExecEngineWithLastParty);
			auto s = execEngineWithLastPartyText;
			_tiExecEngineWithParty.setToolTipText(MenuProps.buildTool(s, m, h, false));
		} else { mixin(S_TRACE);
			_tiExecEngineWithParty.setToolTipText(_prop.var.menu.buildTool(_prop.parent, MenuID.ExecEngineWithParty));
		}
	}
	@property
	string execEngineWithLastPartyText() { mixin(S_TRACE);
		assert (_prop.var.etc.lastExecutedParty.enginePath != "");
		auto ep = _prop.var.etc.lastExecutedParty;
		string e = ep.engineName;
		string y = ep.yadoName;
		string p = ep.partyName;
		return .tryFormat(_prop.msgs.execEngineWithLastParty, e, y, p);
	}
	void execEngineP(string path, string scenario = "", ExecutionParty ep = ExecutionParty.init) { mixin(S_TRACE);
		string path2 = path;
		string dir = dirName(nabs(path));
		if (path.extension().toLower() == ".py") { mixin(S_TRACE);
			path2 = .tryFormat(_prop.var.etc.pythonCommand ~ " \"%s\"", path);
		}
		if (scenario != "") { mixin(S_TRACE);
			auto params = [
				"-debug",
				"-yado",
				.tryFormat(`"%s"`, ep.yadoPath),
				"-party",
				.tryFormat(`"%s"`, ep.partyPath),
			];
			path2 ~= .tryFormat(" %s -scenario %s", params.join(" "), scenario);
		}
		_sync.sync();
		if (.exec(path2, dir)) { mixin(S_TRACE);
			if (scenario != "") { mixin(S_TRACE);
				// 履歴を記憶
				_prop.var.etc.lastExecutedParty = ep;

				if (0 < _prop.var.etc.executedPartiesMax) { mixin(S_TRACE);
					auto has = false;
					foreach (i, ep2; _prop.var.etc.executedParties) { mixin(S_TRACE);
						if (ep == ep2) { mixin(S_TRACE);
							// 先頭へ移動
							has = true;
							_prop.var.etc.executedParties = [ep] ~ _prop.var.etc.executedParties[0 .. i] ~ _prop.var.etc.executedParties[i + 1 .. $];
							break;
						}
					}
					if (!has) _prop.var.etc.executedParties = [ep] ~ _prop.var.etc.executedParties;
					_comm.prop.var.etc.executedParties = .removeHistoryNonExisting(_comm, _comm.prop.var.etc.removePartyHistoryNonExistingWithPriority, _comm.prop.var.etc.executedParties, _comm.prop.var.etc.executedPartiesMax);
				} else { mixin(S_TRACE);
					_prop.var.etc.executedParties.length = 0;
				}

				_comm.refExecutedParties.call();
				_comm.refreshToolBar();
			}
		} else {
			DWTMessageBox.showWarning(.tryFormat(_prop.msgs.errorExecEngine, .baseName(path)),
				_prop.msgs.dlgTitWarning, _win);
		}
	}
	@property
	bool canExecEngine() { mixin(S_TRACE);
		string engine = execEnginePath;
		return engine.length > 0;
	}
	@property
	bool canExecEngineWithLastParty() { mixin(S_TRACE);
		if (!canExecEngineWithParty) return false;
		if (_prop.var.etc.lastExecutedParty.enginePath == "") return false;
		auto ep = _prop.var.etc.lastExecutedParty;
		return summary && ep.enginePath != "" && ep.enginePath.exists() && ep.enginePath.isFile();
	}
	@property
	bool canExecEngineWithLastParty2() { mixin(S_TRACE);
		if (!canExecEngineWithLastParty) return false;
		if (_prop.var.etc.lastExecutedParty.enginePath == "") return false;
		auto ep = _prop.var.etc.lastExecutedParty;
		return !ep.isClassic || canExecClassic;
	}
	@property
	bool canExecEngineWithPartyMenu() { mixin(S_TRACE);
		if (canExecEngineWithParty) return true;
		return canExecEngine || _prop.var.etc.classicEngines.length || _prop.var.etc.executedPartyBookmarks.length || _prop.var.etc.executedParties.length;
	}
	@property
	bool canExecEngineWithParty() { mixin(S_TRACE);
		if (!summary || (summary.useTemp && summary.origZipName == "")) return false;
		if (summary.readOnlyPath != "") return false;
		return true;
	}
	void execEngine() { mixin(S_TRACE);
		string engine = execEnginePath;
		if (engine.length) { mixin(S_TRACE);
			execEngineP(engine);
		}
	}
	void execEngineWithLastParty() { mixin(S_TRACE);
		if (!summary) return;
		if (canExecEngineWithLastParty2) { mixin(S_TRACE);
			auto scenario = .tryFormat(`"%s"`, origScenarioPath);
			assert (_prop.var.etc.lastExecutedParty.enginePath != "");
			auto ep = _prop.var.etc.lastExecutedParty;
			execEngineP(ep.enginePath, scenario, ep);
		} else { mixin(S_TRACE);
			showDropDownMenu(_tiExecEngineWithParty, _tmExecEngineWithParty);
		}
	}
	@property
	bool canExecClassic() { mixin(S_TRACE);
		// CardWirth 1.50に -scenario でCAB書庫を渡すのは不可
		if (!summary) return false;
		return summary.legacy && !summary.useTemp;
	}
	@property
	string execEnginePath() { mixin(S_TRACE);
		return summary ? _comm.skin.executeEngine : _prop.enginePath;
	}
	private void openDataWindow() { mixin(S_TRACE);
		_comm.openDataWin(true);
	}
	private void openFlagWindow() { mixin(S_TRACE);
		_comm.openFlagWin(true);
	}
	private void openDirWindow() { mixin(S_TRACE);
		_comm.openDirWin(true);
	}
	private void openCouponWindow() { mixin(S_TRACE);
		_comm.openCouponWin(true);
	}
	private void openGossipWindow() { mixin(S_TRACE);
		_comm.openGossipWin(true);
	}
	private void openCompleteStampWindow() { mixin(S_TRACE);
		_comm.openCompleteStampWin(true);
	}
	private void openKeyCodeWindow() { mixin(S_TRACE);
		_comm.openKeyCodeWin(true);
	}
	private void openCellNameWindow() { mixin(S_TRACE);
		_comm.openCellNameWin(true);
	}
	private void openCardGroupWindow() { mixin(S_TRACE);
		_comm.openCardGroupWin(true);
	}
	void exitAll() { mixin(S_TRACE);
		_win.close();
	}
	private ReplaceDialog _replDlg = null;
	void replaceText() { mixin(S_TRACE);
		openReplWin();
	}
	void clipboardToXML() { mixin(S_TRACE);
		auto c = _comm.clipboard.getContents(XMLBytesTransfer.getInstance());
		if (c !is null && isXMLBytes(c)) { mixin(S_TRACE);
			_comm.clipboard.setContents([new ArrayWrapperString(bytesToXML(c))], [TextTransfer.getInstance()]);
			_comm.refreshToolBar();
		}
	}

	enum QSaveType {
		open,
		create,
		reload,
		close,
	}
	bool qSave(QSaveType type) { mixin(S_TRACE);
		auto noApplyCount = 0;
		foreach (shell; _display.getShells()) { mixin(S_TRACE);
			auto dlg = cast(AbsDialog)shell.getData();
			if (!dlg) continue;
			if (cast(SettingsDialog)dlg && type !is QSaveType.close) continue;
			if (dlg.noApply) { mixin(S_TRACE);
				noApplyCount++;
			}
		}
		if (noApplyCount) { mixin(S_TRACE);
			auto dlg = new DWTMessageBox(_win, SWT.YES | SWT.NO | SWT.ICON_QUESTION);
			dlg.setText(_prop.msgs.dlgTitQuestion);
			if (type is QSaveType.close) { mixin(S_TRACE);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgForceCancelDialogsQuit, noApplyCount));
			} else { mixin(S_TRACE);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgForceCancelDialogs, noApplyCount));
			}
			if (SWT.YES != dlg.open()) { mixin(S_TRACE);
				return false;
			}
		}
		if (_comm.isChanged) { mixin(S_TRACE);
			DWTMessageBox dlg;
			if (type is QSaveType.reload) { mixin(S_TRACE);
				dlg = new DWTMessageBox(_win, SWT.OK | SWT.CANCEL | SWT.ICON_QUESTION);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgIsSaveBeforeReload, summary.scenarioName));
			} else { mixin(S_TRACE);
				dlg = new DWTMessageBox(_win, SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgIsSaveBeforeExit, summary.scenarioName));
			}
			dlg.setText(_prop.msgs.dlgTitQuestion);
			_win.setMinimized(false);
			switch (dlg.open()) {
			case SWT.YES, SWT.OK:
				return (type is QSaveType.reload) ? true : save(_win);
			case SWT.NO:
				return true;
			case SWT.CANCEL:
				return false;
			default: assert (0);
			}
		}
		return true;
	}

	void refShowMainToolBar() { mixin(S_TRACE);
		if (_win.isVisible()) _win.setRedraw(false);
		scope (exit) {
			if (_win.isVisible()) _win.setRedraw(true);
		}
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		if (!_prop.var.etc.showMainToolBar || !_cbar) { mixin(S_TRACE);
			gd.heightHint = 0;
		}
		_toolComp.setLayoutData(gd);
		_toolComp.setVisible(_prop.var.etc.showMainToolBar);
		_toolComp.getParent().layout();
	}
	Composite _toolComp;
	private Composite _cbar = null;
	class SListener : ShellAdapter {
		override void shellClosed(ShellEvent e) { mixin(S_TRACE);
			e.doit = qSave(QSaveType.close);
			if (e.doit) { mixin(S_TRACE);
				if (summary && !_comm.isChanged) { mixin(S_TRACE);
					writeDock();
				}
				_comm.closeAll();
			}
		}
	}
	class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_quit = true;
			version (Console) {
				debug writeln("Start Ending Process");
			}
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
			_comm.refExecutedParties.remove(&refExecutedParties);
			_comm.refImportHistory.remove(&refImportHistory);
			version (Console) {
				debug writeln("Removed Receivers");
			}
			auto b = _win.getBounds();
			_prop.var.mainWin.x = b.x;
			_prop.var.mainWin.y = b.y;
			if (dock) { mixin(S_TRACE);
				_prop.var.mainWin.maximized = _win.getMaximized();
				if (!_prop.var.mainWin.maximized) { mixin(S_TRACE);
					_prop.var.mainWin.width = b.width;
					_prop.var.mainWin.height = b.height;
				}
			}
			version (Console) {
				debug writeln("Saved Window Bounds");
			}
			stopSE();
			stopBGM();
			version (Console) {
				debug writeln("Stopped Sounds");
			}
			_win.setVisible(false);
			try { mixin(S_TRACE);
				_comm.refScenario.call(null);
				_comm.closeAll();
				version (Console) {
					debug writeln("Closed All Windows");
				}
				if (summary && summary.useTemp) { mixin(S_TRACE);
					_dirWin.stopTrace();
					try { mixin(S_TRACE);
						_saveSync.lock();
						scope (exit) _saveSync.unlock();
						summary.delTemp();
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
					}
					version (Console) {
						debug writeln("Deleted Temporary Files");
					}
				}
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
				_win.setVisible(true);
			}
		}
	}
	void sendReloadPropsAndSave() { mixin(S_TRACE);
		_prop.var.save(_dock);
		sendReloadProps();
	}
	void sendReloadProps() { mixin(S_TRACE);
		sendToPipe((string recv) { mixin(S_TRACE);
			if (!recv) { mixin(S_TRACE);
				return "reload settings";
			}
			return "";
		}, { mixin(S_TRACE);
			return true;
		});
	}
	void reloadProps() { mixin(S_TRACE);
		auto oldStgs = OldSettings(_prop);
		scope (exit) {
			oldStgs.raiseEvent(_comm);
		}
		_prop.var.reload();
	}
	private SettingsDialog _stgDlg = null;
	void settings() { mixin(S_TRACE);
		if (_stgDlg) { mixin(S_TRACE);
			_stgDlg.active();
		} else { mixin(S_TRACE);
			_stgDlg = new SettingsDialog(_comm, _prop, _win, _dock, summary, &sendReloadProps);
			_stgDlg.closeEvent ~= { mixin(S_TRACE);
				_stgDlg = null;
			};
			_stgDlg.open();
		}
	}

	@property
	const
	bool canEditScenarioHistory() { return true; }

	private ScenarioHistoryDialog _scHistDlg = null;
	private void editScenarioHistory() { mixin(S_TRACE);
		if (_scHistDlg) { mixin(S_TRACE);
			_scHistDlg.active();
		} else { mixin(S_TRACE);
			_scHistDlg = new ScenarioHistoryDialog(_comm, _win, _prop.msgs.editScenarioHistory, _prop.images.menu(MenuID.EditScenarioHistory), _prop.var.etc.openHistories, _prop.var.etc.scenarioBookmarks);
			_scHistDlg.closeEvent ~= { mixin(S_TRACE);
				_scHistDlg = null;
			};
			_scHistDlg.appliedEvent ~= { mixin(S_TRACE);
				if (_scHistDlg.bookmark != _comm.prop.var.etc.scenarioBookmarks || _scHistDlg.history != _comm.prop.var.etc.openHistories) { mixin(S_TRACE);
					_prop.var.etc.scenarioBookmarks = _scHistDlg.bookmark;
					_prop.var.etc.openHistories = _scHistDlg.history;
					_comm.refHistories.call();
					_prop.var.save(dock);
					sendReloadProps();
				}
			};
			_scHistDlg.open();
		}
	}

	@property
	const
	bool canEditImportHistory() { return true; }

	private ScenarioHistoryDialog _importHistDlg = null;
	private void editImportHistory() { mixin(S_TRACE);
		if (_importHistDlg) { mixin(S_TRACE);
			_importHistDlg.active();
		} else { mixin(S_TRACE);
			_importHistDlg = new ScenarioHistoryDialog(_comm, _win, _prop.msgs.editImportHistory, _prop.images.menu(MenuID.EditImportHistory), _prop.var.etc.importHistory, _prop.var.etc.importBookmarks);
			_importHistDlg.closeEvent ~= { mixin(S_TRACE);
				_importHistDlg = null;
			};
			_importHistDlg.appliedEvent ~= { mixin(S_TRACE);
				if (_importHistDlg.bookmark != _comm.prop.var.etc.importBookmarks || _importHistDlg.history != _comm.prop.var.etc.importHistory) { mixin(S_TRACE);
					_prop.var.etc.importBookmarks = _importHistDlg.bookmark;
					_prop.var.etc.importHistory = _importHistDlg.history;
					_comm.refImportHistory.call();
				}
			};
			_importHistDlg.open();
		}
	}

	@property
	const
	private bool canDelNotExistsScenario() { mixin(S_TRACE);
		return _prop.var.etc.scenarioBookmarks.length ||  _prop.var.etc.openHistories.length || _prop.var.etc.importBookmarks.length ||  _prop.var.etc.importHistory.length;
	}
	private void delNotExistsScenario() { mixin(S_TRACE);
		OpenHistory[] filter(OpenHistory[] arr) { mixin(S_TRACE);
			OpenHistory[] r;
			foreach (m; arr) { mixin(S_TRACE);
				auto f = .fullHistToHist(m.path);
				if (f.exists()) r ~= m;
			}
			return r;
		}
		auto update = false;
		auto bookmarks = filter(_prop.var.etc.scenarioBookmarks);
		auto history = filter(_prop.var.etc.openHistories);
		if (bookmarks.length != _prop.var.etc.scenarioBookmarks.length || history.length != _prop.var.etc.openHistories.length) { mixin(S_TRACE);
			_prop.var.etc.scenarioBookmarks = bookmarks;
			_prop.var.etc.openHistories = history;
			_comm.refHistories.call();
			update = true;
		}
		auto iBookmarks = filter(_prop.var.etc.importBookmarks);
		auto iHistory = filter(_prop.var.etc.importHistory);
		if (iBookmarks.length != _prop.var.etc.importBookmarks.length || iHistory.length != _prop.var.etc.importHistory.length) { mixin(S_TRACE);
			_prop.var.etc.importBookmarks = iBookmarks;
			_prop.var.etc.importHistory = iHistory;
			_comm.refImportHistory.call();
			update = true;
		}
		if (update) { mixin(S_TRACE);
			_prop.var.save(dock);
			sendReloadProps();
			_comm.refreshToolBar();
		}
	}

	@property
	const
	bool canEditExecutedPartyHistory() { return _comm.prop.var.etc.executedPartyBookmarks.length || _comm.prop.var.etc.executedParties.length || _comm.prop.var.etc.classicEngines.length; }

	private ExecutedPartyHistoryDialog _partyHistDlg = null;
	private void editExecutedPartyHistory() { mixin(S_TRACE);
		if (_partyHistDlg) { mixin(S_TRACE);
			_partyHistDlg.active();
		} else { mixin(S_TRACE);
			_partyHistDlg = new ExecutedPartyHistoryDialog(_comm, _win);
			_partyHistDlg.closeEvent ~= { mixin(S_TRACE);
				_partyHistDlg = null;
			};
			_partyHistDlg.open();
		}
	}

	void setHistSkin() { mixin(S_TRACE);
		setHistSkin(_prop.var.etc.scenarioBookmarks.value);
		setHistSkin(_prop.var.etc.openHistories.value);
	}
	void setHistSkin(ref OpenHistory[] history) { mixin(S_TRACE);
		if (!summary) return;
		string skinType = summary.type;
		string skinName = summary.skinName;
		if (summary.type == _comm.skin.type && skinName == "") skinName = _comm.skin.name;
		string skinEngine = _comm.skin.legacyEngine;
		auto hist = createHistString(summary);
		auto hists = history.dup;
		foreach (i, ref h; hists) { mixin(S_TRACE);
			if (cfnmatch(fullHistToHist(h.path), hist)) { mixin(S_TRACE);
				h.skinType = skinType;
				h.skinName = skinName;
				h.skinEngine = skinEngine;
				break;
			}
		}
		history = hists;
	}
	string findFullHist(string hist) { mixin(S_TRACE);
		return .findHistory(_comm, hist).path;
	}
	string createFullHistString() { mixin(S_TRACE);
		string hist = createHistString(summary);
		if ("" == hist) return "";
		if (_prop.var.etc.reconstruction) { mixin(S_TRACE);
			hist = "\"" ~ hist ~ "\" " ~ std.string.join(openedCWXPath, CWXPATH_SEP.idup);
		}
		return hist;
	}
	void writeDock() { mixin(S_TRACE);
		writeDock(_prop.var.etc.scenarioBookmarks.value);
		writeDock(_prop.var.etc.openHistories.value);
	}
	void writeDock(ref OpenHistory[] history) { mixin(S_TRACE);
		string hist = createHistString(summary);
		if ("" == hist) return;
		auto hists = history.dup;
		foreach (i, h; hists) { mixin(S_TRACE);
			if (cfnmatch(fullHistToHist(h.path), hist)) { mixin(S_TRACE);
				if (_prop.var.etc.reconstruction) { mixin(S_TRACE);
					hists[i].path = createFullHistString();
				} else { mixin(S_TRACE);
					hists[i].path = hist;
				}
				history = hists;
				break;
			}
		}
	}
	void delHist(string fullHist) { mixin(S_TRACE);
		delHist(fullHist, _prop.var.etc.scenarioBookmarks);
		delHist(fullHist, _prop.var.etc.openHistories);
	}
	void delHist(string fullHist, ref OpenHistory[] history) { mixin(S_TRACE);
		auto hists = history.dup;
		string hist = fullHistToHist(fullHist);
		OpenHistory[] hists2;
		foreach (i, h; hists) { mixin(S_TRACE);
			if (!cfnmatch(fullHistToHist(h.path), hist)) { mixin(S_TRACE);
				hists2 ~= h;
			}
		}
		if (history.length == hists2.length) return;
		history = hists2;
		_prop.var.save(dock);
		sendReloadProps();
		_comm.refHistories.call();
	}
	void addHistory() { mixin(S_TRACE);
		auto hist = OpenHistory(createFullHistString());
		if ("" == hist.path) return;
		auto p = fullHistToHist(hist.path);
		if (summary.readOnlyPath != "") { mixin(S_TRACE);
			_prop.var.etc.scenarioPath = .nabs(summary.readOnlyPath.dirName());
		} else { mixin(S_TRACE);
			_prop.var.etc.scenarioPath = summary.useTemp ? dirName(p) : dirName(dirName(p));
		}
		.addHistory(_comm, hist, _prop.var.etc.openHistories.value, _prop.var.etc.scenarioBookmarks.value);
		if (summary && !_comm.isChanged) writeDock();
		_prop.var.etc.lastScenario = p;
		_prop.var.save(dock);
		sendReloadProps();
		_comm.refHistories.call();
	}
	class Hist {
		static enum Type {
			Open,
			Import
		}
		private Type _type;
		private string _hist;
		this(Menu menu, Type type, int num, string hist) { mixin(S_TRACE);
			_type = type;
			hist = fullHistToHist(hist);
			string text;
			auto snipLen = _prop.var.etc.historySnipLength;
			auto ext = .extension(hist);
			if (cfnmatch(baseName(hist), "Summary.xml")) { mixin(S_TRACE);
				text = cuthist(hist[0u .. $ - "Summary.xml".length - std.path.dirSeparator.length], snipLen);
			} else if (cfnmatch(ext, ".wsn")) { mixin(S_TRACE);
				text = cuthist(hist, snipLen);
			} else if (cfnmatch(baseName(hist), "Summary.wsm")) { mixin(S_TRACE);
				text = cuthist(hist[0u .. $ - "Summary.wsm".length - std.path.dirSeparator.length], snipLen);
			} else if (cfnmatch(ext, ".cab") || cfnmatch(ext, ".zip") || cfnmatch(ext, ".lzh") || cfnmatch(ext, ".lha")) { mixin(S_TRACE);
				text = cuthist(hist, snipLen);
			} else { mixin(S_TRACE);
				text = cuthist(hist, snipLen);
			}
			auto img = .historyImage(_prop, hist);
			string nstr;
			if (num < 10) { mixin(S_TRACE);
				nstr = "&" ~ to!(string)(num);
			} else { mixin(S_TRACE);
				nstr = to!(string)(num);
			}
			bool canOpen() { return _type is Type.Import ? summary !is null : true; }
			auto mi = createMenuItem2(_comm, menu, nstr ~ " " ~ text, img, &run, &canOpen);
			auto l = new class MenuAdapter {
				override void menuShown(MenuEvent e) { mixin(S_TRACE);
					mi.setImage(.historyImage(_prop, hist));
				}
			};
			menu.addMenuListener(l);
			.listener(mi, SWT.Dispose, { mixin(S_TRACE);
				menu.removeMenuListener(l);
			});
			_hist = hist;
		}
		private void run() { mixin(S_TRACE);
			final switch (_type) {
			case Type.Open:
				if (qSave(QSaveType.open)) { mixin(S_TRACE);
					openScenario(_hist, { mixin(S_TRACE);
						delHist();
						resetOpt();
					});
				}
				break;
			case Type.Import:
				_comm.addScenario(_prop, [_hist], &delHist);
				break;
			}
		}
		private void delHist() { mixin(S_TRACE);
			auto dlg = new DWTMessageBox(_win, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
			string h = _hist;
			string ext = .extension(h);
			if (cfnmatch(ext, ".xml") || cfnmatch(ext, ".wsm") || cfnmatch(ext, ".wid") || cfnmatch(ext, ".wex")) { mixin(S_TRACE);
				h = dirName(h);
			}
			auto isBookmark = false;
			foreach (i, h2; _prop.var.etc.scenarioBookmarks) { mixin(S_TRACE);
				if (.cfnmatch(.fullHistToHist(h2.path), _hist)) { mixin(S_TRACE);
					isBookmark = true;
					break;
				}
			}
			if (isBookmark) { mixin(S_TRACE);
				dlg.setMessage(.tryFormat(_prop.msgs.scenarioNotFoundForBookmark, h));
			} else { mixin(S_TRACE);
				dlg.setMessage(.tryFormat(_prop.msgs.scenarioNotFound, h));
			}
			dlg.setText(_prop.msgs.dlgTitQuestion);
			if (SWT.YES == dlg.open()) { mixin(S_TRACE);
				this.outer.delHist(_hist);
			}
		}
		private static string cuthist(string hist, int cut) { mixin(S_TRACE);
			hist = nabs(hist);
			auto dhist = toUTF32(hist);
			if (dhist.length > cut + "..."d.length) { mixin(S_TRACE);
				auto drive = driveName(hist);
				auto rlen = drive ? toUTF32(drive).length + 1 : 1;
				auto flen = toUTF32(baseName(hist)).length + 1;
				auto plen = flen <= cut ? cut - flen : 0;
				if (plen < rlen) plen = rlen;
				if (dhist.length <= plen + flen + "..."d.length) return hist;
				return toUTF8(dhist[0 .. plen] ~ "..." ~ dhist[$ - flen .. $]);
			} else { mixin(S_TRACE);
				return hist;
			}
		} unittest { mixin(S_TRACE);
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
				result = cuthist(r"C:\日本語_\テスト.file", 13);
				assert (result == r"C:\日本語_\テスト.file", result);
				result = cuthist(r"C:\日本語_\テスト.file", 12);
				assert (result == r"C:\...\テスト.file", result);
				result = cuthist(r"C:\日本語日本語\テスト.file", 13);
				assert (result == r"C:\日...\テスト.file", result);
				result = cuthist(r"C:\simp\test.file", 5);
				assert (result == r"C:\...\test.file", result);
				result = cuthist(r"C:\sim\test.file", 5);
				assert (result == r"C:\sim\test.file", result);
				result = cuthist(r"C:\si\test.file", 5);
				assert (result == r"C:\si\test.file", result);
			}
		}
	}
	private Menu _menuFile;
	bool canSaveOverwrite() { mixin(S_TRACE);
		if (_prop.var.etc.applyDialogsBeforeSave) { mixin(S_TRACE);
			foreach (shell; _display.getShells()) { mixin(S_TRACE);
				auto dlg = cast(AbsDialog)shell.getData();
				if (!dlg) continue;
				if (dlg.noScenario) continue;
				if (dlg.noApply) return true;
			}
		}
		return summary !is null && !_inSaving && (!_prop.var.etc.saveNeedChanged || _isChanged);
	}
	void createFileMenu() { mixin(S_TRACE);
		foreach (itm; _menuFile.getItems()) { mixin(S_TRACE);
			itm.dispose();
		}
		mixin(MenuAction!("_menuFile", MenuID.New, SWT.PUSH, "createScenario", "null"));
		mixin(MenuAction!("_menuFile", MenuID.Open, SWT.PUSH, "openScenarioM", "null"));
		mixin(MenuAction!("_menuFile", MenuID.Save, SWT.PUSH, "saveScenario", "&canSaveOverwrite"));
		mixin(MenuAction!("_menuFile", MenuID.SaveAs, SWT.PUSH, "saveScenarioA", "() => summary !is null && !_inSaving"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin(MenuAction!("_menuFile", MenuID.NewAtNewWindow, SWT.PUSH, "createScenarioNewWin", "null"));
		mixin(MenuAction!("_menuFile", MenuID.OpenAtNewWindow, SWT.PUSH, "openScenarioNewWin", "null"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin(MenuAction!("_menuFile", MenuID.CreateArchive, SWT.PUSH, "_dirWin.createArchive", "&_dirWin.canCreateArchive"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin(MenuAction!("_menuFile", MenuID.Reload, SWT.PUSH, "reload", "() => summary !is null"));
		auto i = 0;
		if (_prop.var.etc.scenarioBookmarks.length) { mixin(S_TRACE);
			new MenuItem(_menuFile, SWT.SEPARATOR);
			foreach (hist; _prop.var.etc.scenarioBookmarks) { mixin(S_TRACE);
				new Hist(_menuFile, Hist.Type.Open, i, hist.path);
				i++;
			}
		}
		if (_prop.var.etc.openHistories.length) {
			new MenuItem(_menuFile, SWT.SEPARATOR);
			foreach (hist; _prop.var.etc.openHistories) { mixin(S_TRACE);
				new Hist(_menuFile, Hist.Type.Open, i, hist.path);
				i++;
			}
		}
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin(MenuAction!("_menuFile", MenuID.EditScenarioHistory, SWT.PUSH, "editScenarioHistory", "&canEditScenarioHistory"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		createMenuItem(_comm, _menuFile, MenuID.Close, &exitAll, null);
		setupMenu(_menu);
	}

	void createImportHistoryMenu(Menu menu, bool withSelectScenario) { mixin(S_TRACE);
		foreach (itm; menu.getItems()) { mixin(S_TRACE);
			itm.dispose();
		}
		if (withSelectScenario) { mixin(S_TRACE);
			.createMenuItem(_comm, menu, MenuID.SelectImportSource, &addScenario, &canAddScenario);
		}
		auto i = 0;
		if (_prop.var.etc.importBookmarks.length) { mixin(S_TRACE);
			if (menu.getItemCount()) new MenuItem(menu, SWT.SEPARATOR);
			foreach (hist; _prop.var.etc.importBookmarks) { mixin(S_TRACE);
				new Hist(menu, Hist.Type.Import, i, hist.path);
				i++;
			}
		}
		if (_prop.var.etc.importHistory.length) {
			if (menu.getItemCount()) new MenuItem(menu, SWT.SEPARATOR);
			foreach (hist; _prop.var.etc.importHistory) { mixin(S_TRACE);
				new Hist(menu, Hist.Type.Import, i, hist.path);
				i++;
			}
		}
		if (menu.getItemCount()) new MenuItem(menu, SWT.SEPARATOR);
		.createMenuItem(_comm, menu, MenuID.EditImportHistory, &editImportHistory, &canEditImportHistory);
	}

	string _pipeName = "";
	class OpenCWXPath : Runnable {
		string path;
		override void run() { mixin(S_TRACE);
			if (!_win || _win.isDisposed()) return;
			auto paths = std.string.split(path, CWXPATH_SEP.idup);
			if (!paths.length) paths = [""];
			foreach (p; paths) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					openCWXPath(p, true);
				} catch (Throwable e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
	}
	class ReloadSettings : Runnable {
		override void run() { mixin(S_TRACE);
			if (!_win || _win.isDisposed()) return;
			try { mixin(S_TRACE);
				reloadProps();
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	class SelectFile : Runnable {
		string path;
		override void run() { mixin(S_TRACE);
			if (!_win || _win.isDisposed()) return;
			if (!summary) return;
			try { mixin(S_TRACE);
				_comm.openCWXPath("fileview", false);
				_dirWin.select(path, true);
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	void pipeThr() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Start Pipe Thread");
			}
			auto openPath = new OpenCWXPath;
			auto reloadSettings = new ReloadSettings;
			auto selectFile = new SelectFile;
			Summary summ = null;
			string recvSend(in char[] recv, out bool quit) { mixin(S_TRACE);
				quit = false;
				if (recv == "quit") { mixin(S_TRACE);
					quit = true;
					return null;
				} else if (recv == "get opened scenario") { mixin(S_TRACE);
					summ = summary;
					if (!summ) return null;
					string send = "opened scenario ";
					send ~= origScenarioPath;
					return send;
				} else if (std.string.startsWith(recv.idup, "open cwxpath ")) { mixin(S_TRACE);
					openPath.path = recv["open cwxpath ".length .. $].idup;
					_display.asyncExec(openPath);
					return "opened cwxpath";
				} else if (std.string.startsWith(recv, "select file ")) { mixin(S_TRACE);
					selectFile.path = recv["select file ".length .. $].idup;
					_display.asyncExec(selectFile);
					return "selected file";
				} else if (recv == "reload settings") { mixin(S_TRACE);
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
				while (!quit && ConnectNamedPipe(pipe, null)) { mixin(S_TRACE);
					scope (exit) DisconnectNamedPipe(pipe);
					while (true) { mixin(S_TRACE);
						if (!ReadFile(pipe, buf.ptr, buf.length, &len, null)) break;
						auto recv = buf[0 .. len];
						string send = recvSend(recv, quit);
						if (quit) break;
						if (!send) break;
						if (!WriteFile(pipe, send.ptr, cast(DWORD)send.length, &len, null)) break;
					}
				}
			} else { mixin(S_TRACE);
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
				if (0 != cbind(pipe, cast(sockaddr*)&laddr, laddr.sizeof)) return;
				if (0 != listen(pipe, 1)) return;
				char[4096] buf;
				ptrdiff_t len;
				typeof(pipe) rsock;
				sockaddr_un raddr;
				socklen_t rsocklen;
				bool quit = false;
				while (!quit && !_quit) { mixin(S_TRACE);
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
					while (true) { mixin(S_TRACE);
						if (-1 == (len = cread(rsock, buf.ptr, buf.length))) break;
						char[] recv = buf[0 .. len];
						string send = recvSend(recv, quit);
						if (quit) break;
						if (!send) break;
						if (-1 == cwrite(rsock, send.ptr, send.length)) break;
					}
				}
			}
			version (Console) {
				debug writeln("Exit Pipe Thread");
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}

	/// このプロセスが待ち受けする際のパイプ名を生成。
	string createPipeName() { mixin(S_TRACE);
		version (Windows) {
			for (size_t i = 0; ; i++) { mixin(S_TRACE);
				string pipeName = r"\\.\pipe\cwxeditor_" ~ to!(string)(i);
				auto p = CreateFileW(toUTFz!(wchar*)(pipeName),
					GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
				if (p == INVALID_HANDLE_VALUE) { mixin(S_TRACE);
					return pipeName;
				}
				CloseHandle(p);
			}
		} else { mixin(S_TRACE);
			for (size_t i = 0; ; i++) { mixin(S_TRACE);
				string pipeName = r"/etc/cwxeditor_pipe_" ~ to!(string)(i);
				auto p = socket(AF_UNIX, SOCK_STREAM, 0);
				if (-1 == p) continue;
				scope (exit) {
					close(p);
				}
				sockaddr_un raddr;
				raddr.sun_family = AF_UNIX;
				strcpy(raddr.sun_path.ptr, pipeName.ptr);
				if (-1 == connect(p, cast(sockaddr*) &raddr, raddr.sizeof)) { mixin(S_TRACE);
					return pipeName;
				}
			}
		}
	}

	Object _sendToPipeMutex;
	bool _sendPipeThrQuit = false;
	Tuple!(string delegate(string), "sendRecv", bool delegate(), "next")[] _sendToPipe;
	/// CWXEditorのプロセスに対してパイプを通じてメッセージを送る。
	void sendToPipe(string delegate(string) sendRecv, bool delegate() next) { mixin(S_TRACE);
		synchronized (_sendToPipeMutex) {
			_sendToPipe ~= typeof(_sendToPipe[0])(sendRecv, next);
		}
	}
	/// ditto
	void sendPipeThr() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Start Sender Pipe Thread");
			}
			while (!_sendPipeThrQuit) { mixin(S_TRACE);
				auto send = false;
				typeof(_sendToPipe[0]) data;
				synchronized (_sendToPipeMutex) {
					if (_sendToPipe.length) { mixin(S_TRACE);
						data = _sendToPipe[0];
						_sendToPipe = _sendToPipe[1 .. $];
						send = true;
					}
				}
				if (send) { mixin(S_TRACE);
					sendToPipeImpl(data.sendRecv, data.next);
				} else { mixin(S_TRACE);
					core.thread.Thread.sleep(.dur!("msecs")(1));
				}
			}
			synchronized (_sendToPipeMutex) {
				foreach (data; _sendToPipe) { mixin(S_TRACE);
					sendToPipeImpl(data.sendRecv, data.next);
				}
			}
			version (Console) {
				debug writeln("Exit Sender Pipe Thread");
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	/// ditto
	void sendToPipeImpl(string delegate(string) sendRecv, bool delegate() next) { mixin(S_TRACE);
		version (Windows) {
			WIN32_FIND_DATA fd;
			char[MAX_PATH] buf;
			DWORD len;
			auto handle = FindFirstFileW(r"\\.\pipe\cwxeditor_*".toUTFz!(wchar*), &fd);
			if (handle == INVALID_HANDLE_VALUE) return;
			scope (exit) FindClose(handle);
			do {
				if (!next()) break;
				auto fname = fd.cFileName[0 .. core.stdc.wchar_.wcslen(fd.cFileName.ptr)].to!string;
				if (!std.string.startsWith(fname, "cwxeditor_")) continue;
				auto pipeName = r"\\.\pipe".buildPath(fname);
				if (_pipeName == pipeName) continue;
				auto p = CreateFileW(toUTFz!(wchar*)(pipeName),
					GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
				if (p == INVALID_HANDLE_VALUE) { mixin(S_TRACE);
					continue;
				}
				scope (exit) CloseHandle(p);
				string recv = null;
				while (true) { mixin(S_TRACE);
					string send = sendRecv(recv);
					if (!send || !send.length) break;
					if (!WriteFile(p, send.ptr, cast(DWORD)send.length, &len, null)) break;
					if (!ReadFile(p, buf.ptr, buf.length, &len, null)) break;
					recv = buf[0 .. len].idup;
				}
			} while (FindNextFileW(handle, &fd));
		} else { mixin(S_TRACE);
			char[4096] buf;
			foreach (entry; .dirEntries("/etc", SpanMode.shallow)) { mixin(S_TRACE);
				if (!entry.baseName.fnstartsWith("cwxeditor_pipe_")) { mixin(S_TRACE);
					continue;
				}
				auto pipeName = entry.name;
				if (!next()) break;
				if (_pipeName == pipeName) continue;
				auto p = socket(AF_UNIX, SOCK_STREAM, 0);
				if (-1 == p) continue;
				scope (exit) close(p);
				sockaddr_un raddr;
				raddr.sun_family = AF_INET;
				strcpy(raddr.sun_path.ptr, pipeName.ptr);
				if (-1 == connect(p, cast(sockaddr*)&raddr, raddr.sizeof)) { mixin(S_TRACE);
					continue;
				}
				string recv = null;
				while (true) { mixin(S_TRACE);
					string send = sendRecv(recv);
					if (!send || !send.length) break;
					if (-1 == cwrite(p, send.ptr, send.length)) break;
					auto len = cread(p, buf.ptr, buf.length);
					if (-1 == len) break;
					recv = buf[0 .. len].idup;
				}
			}
		}
	}
	void refSkin() { mixin(S_TRACE);
		refSoundType();
		setHistSkin();
		if (summary && !summary.legacy) { mixin(S_TRACE);
			// レベル判定式の係数とEP獲得量を種族の値で更新する
			.updateCoefficients(_comm, summary.casts);
		}
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		assert (summ is summary);
		refSoundType();
	}
	/// 音声再生方式を判別し、関係DLLの初期化・解放を行う。
	void refSoundType() { mixin(S_TRACE);
		stopBGM();
		stopSE();
		if (!summary) { mixin(S_TRACE);
			disposeSound();
			_bassDir = "";
			return;
		}
		int bgmType = _prop.var.etc.soundPlayType;
		int seType = _prop.var.etc.soundEffectPlayType;
		if (SOUND_TYPE_SAME_BGM == seType) seType = bgmType;
		version (Windows) {
			int engineTypeBGM = summary.legacy ? SOUND_TYPE_MCI : SOUND_TYPE_SDL;
			SoundFontWithVolume[] sfont = [];
			string sfontDir = "";
		} else { mixin(S_TRACE);
			int engineTypeBGM = SOUND_TYPE_SDL;
		}
		int engineTypeSE = engineTypeBGM;
		if (SOUND_TYPE_AUTO == bgmType || SOUND_TYPE_AUTO == seType) { mixin(S_TRACE);
			version (Windows) {
				if (_comm.skin.legacy) { mixin(S_TRACE);
					sfontDir = _comm.skin.legacyEngine.nabs().dirName();
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
					if (SOUND_TYPE_BASS == engineTypeBGM || SOUND_TYPE_BASS == engineTypeSE) { mixin(S_TRACE);
						try { mixin(S_TRACE);
							foreach (rec; .csvReader!string(settings.get("soundfont", "").strip())) { mixin(S_TRACE);
								foreach (s; rec) { mixin(S_TRACE);
									sfont ~= SoundFontWithVolume(s, 100);
								}
							}
						} catch (Exception e) {
							printStackTrace();
							debugln(e);
						}
					}
  				} else { mixin(S_TRACE);
					sfontDir = _comm.skin.engine.nabs().dirName();
					sfont = _comm.skin.loadSoundFonts(_prop.var.etc.cardWirthPyDefaultSoundFont);
  					if (sfont.length) { mixin(S_TRACE);
						engineTypeBGM = SOUND_TYPE_BASS;
						engineTypeSE = SOUND_TYPE_BASS;
  					}
				}
			}
		}
		if (SOUND_TYPE_AUTO == bgmType) bgmType = engineTypeBGM;
		if (SOUND_TYPE_AUTO == seType) seType = engineTypeSE;
		version (Windows) {
			if (SOUND_TYPE_BASS == bgmType || SOUND_TYPE_BASS == seType) { mixin(S_TRACE);
				foreach (ref s; sfont) { mixin(S_TRACE);
					if (!isAbsolute(s.path)) { mixin(S_TRACE);
						auto s2 = sfontDir.buildPath(s.path);
						if (s2.exists()) { mixin(S_TRACE);
							s.path = s2;
						} else if (_comm.skin.legacy) { mixin(S_TRACE);
							s.path = sfontDir.buildPath("SoundFont").buildPath(s.path);
						}
					}
				}
				version (Win64) {
					sfontDir = sfontDir.buildPath("x64");
					if (!sfontDir.buildPath("bass.dll").exists() && _prop.enginePath.dirName().exists()
							&& _prop.enginePath.dirName().buildPath("x64").exists()) { mixin(S_TRACE);
						sfontDir = _prop.enginePath.dirName().buildPath("x64");
					}
				}
				if (_bassDir != sfontDir) { mixin(S_TRACE);
					if (initBass(sfontDir, sfont)) { mixin(S_TRACE);
						_bassDir = sfontDir;
					} else { mixin(S_TRACE);
						if (SOUND_TYPE_BASS == bgmType) bgmType = SOUND_TYPE_MCI;
						if (SOUND_TYPE_BASS == seType) seType = SOUND_TYPE_MCI;
					}
				}
			}
			if (SOUND_TYPE_BASS != bgmType && SOUND_TYPE_BASS != seType) { mixin(S_TRACE);
				disposeSound();
				_bassDir = "";
			}
		}
		lastSoundType = bgmType;
	}
public:
	this (string appPath, cwx.system.System sys, Display d, Props prop, LaunchOption opt) { mixin(S_TRACE);
		string dStr = .text(__LINE__); // 起動ログ
		try { mixin(S_TRACE);
			dStr ~= " - " ~ .text(__LINE__);
			_prop = prop;
			_opt = opt;
			dStr ~= " - " ~ .text(__LINE__);
			_display = d;
			_displayMutex = new Object;
			dStr ~= " - " ~ .text(__LINE__);
			d.setAppName(_prop.msgs.application);

			dStr ~= " - " ~ .text(__LINE__);
			_sendToPipeMutex = new Object;
			dStr ~= " - " ~ .text(__LINE__);
			decScenarioPath(opt.scenario, opt.openPaths, _prop.var.etc.clickIsOpenEvent);
			/// すでにopt.scenarioを開いている
			/// 既存のcwxeditorプロセスがある場合、
			/// そちらを開くようにする。
			string path1 = "";
			dStr ~= " - " ~ .text(__LINE__);
			if (opt.scenario && .exists(opt.scenario)) { mixin(S_TRACE);
				path1 = nabs(opt.scenario);
				auto ext = .extension(path1);
				if (!.isDir(path1)
						&& (cfnmatch(ext, ".xml") || cfnmatch(ext, ".wsm") || cfnmatch(ext, ".wid") || cfnmatch(ext, ".wex"))) { mixin(S_TRACE);
					path1 = nabs(dirName(path1));
				}
			}
			bool execute = true;
			dStr ~= " - " ~ .text(__LINE__);
			sendToPipeImpl((string recv) { mixin(S_TRACE);
				if (!recv) { mixin(S_TRACE);
					return "get opened scenario";
				} else if (std.string.startsWith(recv, "opened scenario ")) { mixin(S_TRACE);
					if (cfnmatch(path1, nabs(recv["opened scenario ".length .. $]))) { mixin(S_TRACE);
						string send = "open cwxpath ";
						foreach (j, s; opt.openPaths) { mixin(S_TRACE);
							if (j > 0) send ~= CWXPATH_SEP;
							send ~= s;
						}
						path1 = "";
						execute = false;
						return send;
					} else { mixin(S_TRACE);
						return "";
					}
				} else if (std.string.startsWith(recv, "opened cwxpath")) { mixin(S_TRACE);
					if (opt.selectfile.length) { mixin(S_TRACE);
						string send = "select file " ~ opt.selectfile;
						execute = false;
						return send;
					} else { mixin(S_TRACE);
						return "";
					}
				} else { mixin(S_TRACE);
					return "";
				}
			}, { mixin(S_TRACE);
				return path1.length > 0;
			});
			dStr ~= " - " ~ .text(__LINE__);
			if (!execute) return;
			_saveSync = new Mutex;
			dStr ~= " - " ~ .text(__LINE__);
			if (exists(_prop.tempPath)) { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				foreach (temp; clistdir(_prop.tempPath)) { mixin(S_TRACE);
					temp = std.path.buildPath(_prop.tempPath, temp);
					if (exists(temp) && isDir(temp)) { mixin(S_TRACE);
						auto lock = std.path.buildPath(temp, "cwxeditor.lock");
						if (exists(lock)) { mixin(S_TRACE);
							try { mixin(S_TRACE);
								std.file.remove(lock);
								delAll(temp);
							} catch (Exception e) {
								printStackTrace();
								debugln(e);
							}
						}
					}
				}
			}
			_refreshTitle = new RefreshTitle;

			dStr ~= " - " ~ .text(__LINE__);
			_sync = new FileSync;
			_sync.start();
			dStr ~= " - " ~ .text(__LINE__);
			_comm = new Commons(_prop, _sync);
			_comm.saveSync = _saveSync;
			_comm.skin = findSkin2(_prop, _prop.var.etc.defaultSkin, _prop.var.etc.defaultSkinName);
			dStr ~= " - " ~ .text(__LINE__);

			string engineDir = "";
			if (_prop.enginePath.length && .exists(_prop.enginePath)) { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				engineDir = dirName(nabs(_prop.enginePath));
				auto skinTable = .skinTable(_prop);
				bool hasSkin = false;
				foreach (skinFile, skin; skinTable) { mixin(S_TRACE);
					if (_prop.var.etc.defaultSkin == skin.type) { mixin(S_TRACE);
						hasSkin = true;
						break;
					}
				}
				if (!hasSkin) { mixin(S_TRACE);
					DWTMessageBox.showWarning(.tryFormat(_prop.msgs.loadSkinError, _prop.var.etc.defaultSkin),
						_prop.msgs.dlgTitWarning, null);
				}
			}

			dStr ~= " - " ~ .text(__LINE__);
			_sbshl = new SBShell(null, SWT.SHELL_TRIM);
			dStr ~= " - " ~ .text(__LINE__);
			_win = _sbshl.shell();
			_win.setData(new TLPData(this));
			_win.setImages(_prop.images.icon);
			auto drop = new DropTarget(_win, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance()]);
			drop.addDropListener(new DTListener);

			// FIXME: 最大化中に最小化・最小化解除を行うと最大化前の
			//        サイズでのレイアウト処理が発生するのを防ぐ
			.listener(_win, SWT.Resize, (e) { mixin(S_TRACE);
				auto shl = cast(Shell)e.widget;
				if (shl.getMinimized()) { mixin(S_TRACE);
					shl.setLayoutDeferred(true);
				} else if (shl.getLayoutDeferred()) { mixin(S_TRACE);
					shl.setLayoutDeferred(false);
				}
			});

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
			_comm.refExecutedParties.add(&refExecutedParties);
			_comm.refImportHistory.add(&refImportHistory);
			_win.addDisposeListener(new DListener);
			_win.addShellListener(new SListener);
			_comm.refreshWallpaper(_prop);
			dStr ~= " - " ~ .text(__LINE__);
			foreach (f; _prop.looks.fontFiles) { mixin(S_TRACE);
				d.loadFont(std.path.buildPath(engineDir, f));
			}
			dStr ~= " - " ~ .text(__LINE__);
			_win.setText(_prop.msgs.mainWindowNameEmpty);
			_sbshl.contentPane.setLayout(zeroGridLayout(1, true));
			dStr ~= " - " ~ .text(__LINE__);
			_toolComp = new Composite(_sbshl.contentPane, SWT.NONE);
			_toolComp.setLayout(new FillLayout);

			dStr ~= " - " ~ .text(__LINE__);
			_tableWin = new TableWindow(_comm, _prop, _win, null);
			dStr ~= " - " ~ .text(__LINE__);
			_flagWin = new FlagWindow(_comm, _prop, _win, null);
			dStr ~= " - " ~ .text(__LINE__);
			dStr ~= " - " ~ .text(__LINE__);
			_castWin = new CardWindow(_comm, _prop, CardWindowKind.Cast, null);
			dStr ~= " - " ~ .text(__LINE__);
			_skillWin = new CardWindow(_comm, _prop, CardWindowKind.Skill, null);
			dStr ~= " - " ~ .text(__LINE__);
			_itemWin = new CardWindow(_comm, _prop, CardWindowKind.Item, null);
			dStr ~= " - " ~ .text(__LINE__);
			_beastWin = new CardWindow(_comm, _prop, CardWindowKind.Beast, null);
			dStr ~= " - " ~ .text(__LINE__);
			_infoWin = new CardWindow(_comm, _prop, CardWindowKind.Info, null);
			dStr ~= " - " ~ .text(__LINE__);
			_dirWin = new DirectoryWindow(_comm, _prop, null);
			dStr ~= " - " ~ .text(__LINE__);
			_couponWin = new CouponWindow(_comm, _win, null, null, false);
			_gossipWin = new GossipWindow(_comm, _win, null, null, false);
			_completeStampWin = new CompleteStampWindow(_comm, _win, null, null, false);
			_keyCodeWin = new KeyCodeWindow(_comm, _win, null, null, false);
			_cellNameWin = new CellNameWindow(_comm, _win, null, null, false);
			_cardGroupWin = new CardGroupWindow(_comm, _win, null, null, false);

			dStr ~= " - " ~ .text(__LINE__);
			auto dockComp = new Composite(_sbshl.contentPane, SWT.NONE);
			dockComp.setLayoutData(new GridData(GridData.FILL_BOTH));
			dockComp.setLayout(windowGridLayout(1, true));
			dStr ~= " - " ~ .text(__LINE__);
			bool hasCloseButton(string key) { mixin(S_TRACE);
				return _prop.var.etc.showCloseButtonAllTab || std.string.startsWith(key, "work") || std.string.startsWith(key, "side");
			}
			_dock = _prop.var.loadDock(dockComp, SWT.NONE, &hasCloseButton, &dockCanVanish, delegate Control(Composite parent, string key) { mixin(S_TRACE);
				scope (exit) {
					dStr ~= " - " ~ .text(__LINE__);
				}
				switch (key) {
				case "data": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_tableWin.reconstruct(parent);
					return _tableWin.shell;
				}
				case "flag": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_flagWin.reconstruct(parent);
					return _flagWin.shell;
				}
				case "castCard": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_castWin.reconstruct(parent);
					return _castWin.shell;
				}
				case "skillCard": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_skillWin.reconstruct(parent);
					return _skillWin.shell;
				}
				case "itemCard": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_itemWin.reconstruct(parent);
					return _itemWin.shell;
				}
				case "beastCard": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_beastWin.reconstruct(parent);
					return _beastWin.shell;
				}
				case "infoCard": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_infoWin.reconstruct(parent);
					return _infoWin.shell;
				}
				case "file": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_dirWin.reconstruct(parent);
					return _dirWin.shell;
				}
				case "coupon": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_couponWin.reconstruct(parent);
					return _couponWin.shell;
				}
				case "gossip": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_gossipWin.reconstruct(parent);
					return _gossipWin.shell;
				}
				case "completeStamp": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_completeStampWin.reconstruct(parent);
					return _completeStampWin.shell;
				}
				case "keyCode": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_keyCodeWin.reconstruct(parent);
					return _keyCodeWin.shell;
				}
				case "cellName": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_cellNameWin.reconstruct(parent);
					return _cellNameWin.shell;
				}
				case "cardGroup": { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					_cardGroupWin.reconstruct(parent);
					return _cardGroupWin.shell;
				}
				default:
					if (!std.string.startsWith(key, "side")) { mixin(S_TRACE);
						dStr ~= " - " ~ .text(__LINE__);
						debugln("Unknown pane key: " ~ key);
					}
					return null;
				}
			}, &dockFirstResize);
			dStr ~= " - " ~ .text(__LINE__);
			bool isSystemPaneName(string key) { mixin(S_TRACE);
				return std.string.startsWith(key, "data")
					|| std.string.startsWith(key, "side");
			}
			bool isSystemCtrlName(string key) { mixin(S_TRACE);
				if (std.string.startsWith(key, "data")
						|| std.string.startsWith(key, "flag")
						|| std.string.startsWith(key, "card")
						|| std.string.startsWith(key, "castCard")
						|| std.string.startsWith(key, "skillCard")
						|| std.string.startsWith(key, "itemCard")
						|| std.string.startsWith(key, "beastCard")
						|| std.string.startsWith(key, "infoCard")
						|| std.string.startsWith(key, "file")) { mixin(S_TRACE);
					return true;
				}
				if (std.string.startsWith(key, "side")) { mixin(S_TRACE);
					return _dock.findCtrl("side", true).length == 1;
				}
				return false;
			}
			void initDock() { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				if (!_dock.findPane("work", true).length) { mixin(S_TRACE);
					_dock.addPane(_dock.first, Dir.N, 3, 1, "work");
				}
				dStr ~= " - " ~ .text(__LINE__);
				_dock.hasCloseButton = &hasCloseButton;
				_dock.canMove = &dockCanMove;
				_dock.newPaneName = &dockNewPaneName;
				_dock.canVanish = &dockCanVanish;
				_dock.selectEvent ~= &dockSelect;
				_dock.closeCtrlEvent ~= &dockCloseCtrl;
				_dock.movingShellEvent ~= &dockMovingShellEvent;
				_dock.moveShellEvent ~= &dockMoveShellEvent;
				_dock.shellClosedEvent ~= &dockShellClosedEvent;
				_dock.firstResize = &dockFirstResize;
				_dock.memoryPane = &isSystemPaneName;
				_dock.memoryControl = &isSystemCtrlName;
				_dock.closeTabWithMiddleClick = (key) => _prop.var.etc.closeTabWithMiddleClick != false;
				_dock.area.setLayoutData(new GridData(GridData.FILL_BOTH));
				dStr ~= " - " ~ .text(__LINE__);
				_prop.var.delNodeTemp();
			}
			if (_dock) { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				initDock();
				dStr ~= " - " ~ .text(__LINE__);
				_dock.tabImage("data", _tableWin.image);
				_dock.tabText("data", _tableWin.title);
				dStr ~= " - " ~ .text(__LINE__);
				_dock.tabImage("flag", _flagWin.image);
				_dock.tabText("flag", _flagWin.title);
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
				dStr ~= " - " ~ .text(__LINE__);
				_dock.tabImage("file", _dirWin.image);
				_dock.tabText("file", _dirWin.title);
				dStr ~= " - " ~ .text(__LINE__);
				_dock.tabImage("coupon", _couponWin.image);
				_dock.tabText("coupon", _couponWin.title);
				_dock.tabImage("gossip", _gossipWin.image);
				_dock.tabText("gossip", _gossipWin.title);
				_dock.tabImage("completeStamp", _completeStampWin.image);
				_dock.tabText("completeStamp", _completeStampWin.title);
				_dock.tabImage("keyCode", _keyCodeWin.image);
				_dock.tabText("keyCode", _keyCodeWin.title);
				_dock.tabImage("cellName", _cellNameWin.image);
				_dock.tabText("cellName", _cellNameWin.title);
				_dock.tabImage("cardGroup", _cardGroupWin.image);
				_dock.tabText("cardGroup", _cardGroupWin.title);
				dStr ~= " - " ~ .text(__LINE__);
			} else { mixin(S_TRACE);
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
				auto card = _dock.addPane(data, Dir.E, 5, 7, "data_2");
				dStr ~= " - " ~ .text(__LINE__);
				_castWin = new CardWindow(_comm, _prop, CardWindowKind.Cast, card);
				_dock.add(_castWin.shell, _castWin.title, _castWin.image, "castCard", true);
				_skillWin = new CardWindow(_comm, _prop, CardWindowKind.Skill, card);
				_dock.add(_skillWin.shell, _skillWin.title, _skillWin.image, "skillCard", false);
				_itemWin = new CardWindow(_comm, _prop, CardWindowKind.Item, card);
				_dock.add(_itemWin.shell, _itemWin.title, _itemWin.image, "itemCard", false);
				_beastWin = new CardWindow(_comm, _prop, CardWindowKind.Beast, card);
				_dock.add(_beastWin.shell, _beastWin.title, _beastWin.image, "beastCard", false);
				_infoWin = new CardWindow(_comm, _prop, CardWindowKind.Info, card);
				_dock.add(_infoWin.shell, _infoWin.title, _infoWin.image, "infoCard", false);
				dStr ~= " - " ~ .text(__LINE__);
				_dirWin = new DirectoryWindow(_comm, _prop, data);
				_dock.add(_dirWin.shell, _dirWin.title, _dirWin.image, "file", false);
				dStr ~= " - " ~ .text(__LINE__);
				_couponWin = new CouponWindow(_comm, _win, data, null, false);
				_dock.add(_couponWin.shell, _couponWin.title, _couponWin.image, "coupon", false);
				dStr ~= " - " ~ .text(__LINE__);
				_gossipWin = new GossipWindow(_comm, _win, null, null, false);
				_completeStampWin = new CompleteStampWindow(_comm, _win, null, null, false);
				_keyCodeWin = new KeyCodeWindow(_comm, _win, null, null, false);
				_cellNameWin = new CellNameWindow(_comm, _win, null, null, false);
				_cardGroupWin = new CardGroupWindow(_comm, _win, null, null, false);
				dStr ~= " - " ~ .text(__LINE__);
			}
			_dock.addCreatePaneEvent(&createPaneEvent);
			dStr ~= " - " ~ .text(__LINE__);

			_noSummMenu = new HashSet!(MenuID);
			_noSummMenu.add(MenuID.New);
			_noSummMenu.add(MenuID.Open);
			_noSummMenu.add(MenuID.NewAtNewWindow);
			_noSummMenu.add(MenuID.OpenAtNewWindow);
			_noSummMenu.add(MenuID.Close);
			_noSummMenu.add(MenuID.Find);
			_noSummMenu.add(MenuID.ToXMLText);
			_noSummMenu.add(MenuID.TableView);
			_noSummMenu.add(MenuID.VarView);
			_noSummMenu.add(MenuID.CastView);
			_noSummMenu.add(MenuID.SkillView);
			_noSummMenu.add(MenuID.ItemView);
			_noSummMenu.add(MenuID.BeastView);
			_noSummMenu.add(MenuID.InfoView);
			_noSummMenu.add(MenuID.FileView);
			_noSummMenu.add(MenuID.CouponView);
			_noSummMenu.add(MenuID.GossipView);
			_noSummMenu.add(MenuID.CompleteStampView);
			_noSummMenu.add(MenuID.KeyCodeView);
			_noSummMenu.add(MenuID.CellNameView);
			_noSummMenu.add(MenuID.CardGroupView);
			_noSummMenu.add(MenuID.ChangeVH);
			_noSummMenu.add(MenuID.ShowCardProp);
			_noSummMenu.add(MenuID.ShowCardImage);
			_noSummMenu.add(MenuID.ShowCardDetail);
			_noSummMenu.add(MenuID.ExecEngine);
			_noSummMenu.add(MenuID.CustomizeToolBar);
			_noSummMenu.add(MenuID.Settings);
			_noSummMenu.add(MenuID.VersionInfo);

			dStr ~= " - " ~ .text(__LINE__);
			{ mixin(S_TRACE);
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
				mixin(MenuAction!("me", MenuID.Undo));
				mixin(MenuAction!("me", MenuID.Redo));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.Cut));
				mixin(MenuAction!("me", MenuID.Copy));
				mixin(MenuAction!("me", MenuID.Paste));
				mixin(MenuAction!("me", MenuID.Delete));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.Clone));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.SelectAll));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.Comment));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.ToScript));
				mixin(MenuAction!("me", MenuID.ToScriptAll));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.Up));
				mixin(MenuAction!("me", MenuID.Down));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.SelectConnectedResource, SWT.PUSH));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.Find, SWT.PUSH, "replaceText", "null"));
				mixin(MenuAction!("me", MenuID.FindID, SWT.PUSH));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.ReNumberingAll, SWT.PUSH, "reNumberingAll", "() => summary !is null"));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.ToXMLText, SWT.PUSH, "clipboardToXML", "() => CBisXMLOnly(_comm.clipboard)"));
				dStr ~= " - " ~ .text(__LINE__);
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.NewDir, SWT.PUSH, "_dirWin.createNewFolder", "&_dirWin.canCreateNewFolder"));
				new MenuItem(me, SWT.SEPARATOR);
				mixin(MenuAction!("me", MenuID.DelNotUsedFile, SWT.PUSH, "_dirWin.deleteUnuse", "&_dirWin.canDeleteUnuse"));

				auto mv = createMenu(_comm, bar, MenuID.View);
				setupMenuListener(mv);
				mixin(MenuAction!("mv", MenuID.TableView, SWT.PUSH, "openDataWindow", "null"));
				mixin(MenuAction!("mv", MenuID.VarView, SWT.PUSH, "openFlagWindow", "null"));
				new MenuItem(mv, SWT.SEPARATOR);
				mixin(MenuAction!("mv", MenuID.CastView, SWT.PUSH, "openCast", "null"));
				mixin(MenuAction!("mv", MenuID.SkillView, SWT.PUSH, "openSkill", "null"));
				mixin(MenuAction!("mv", MenuID.ItemView, SWT.PUSH, "openItem", "null"));
				mixin(MenuAction!("mv", MenuID.BeastView, SWT.PUSH, "openBeast", "null"));
				mixin(MenuAction!("mv", MenuID.InfoView, SWT.PUSH, "openInfo", "null"));
				new MenuItem(mv, SWT.SEPARATOR);
				mixin(MenuAction!("mv", MenuID.FileView, SWT.PUSH, "openDirWindow", "null"));
				new MenuItem(mv, SWT.SEPARATOR);
				mixin(MenuAction!("mv", MenuID.CouponView, SWT.PUSH, "openCouponWindow", "null"));
				mixin(MenuAction!("mv", MenuID.GossipView, SWT.PUSH, "openGossipWindow", "null"));
				mixin(MenuAction!("mv", MenuID.CompleteStampView, SWT.PUSH, "openCompleteStampWindow", "null"));
				mixin(MenuAction!("mv", MenuID.KeyCodeView, SWT.PUSH, "openKeyCodeWindow", "null"));
				mixin(MenuAction!("mv", MenuID.CellNameView, SWT.PUSH, "openCellNameWindow", "null"));
				mixin(MenuAction!("mv", MenuID.CardGroupView, SWT.PUSH, "openCardGroupWindow", "null"));
				dStr ~= " - " ~ .text(__LINE__);
				new MenuItem(mv, SWT.SEPARATOR);
				mixin(MenuAction!("mv", MenuID.Refresh, SWT.PUSH, "refreshAll", "() => summary !is null"));
				if (!_prop.var.etc.showDuplicateViewInToolBar) { mixin(S_TRACE);
					new MenuItem(mv, SWT.SEPARATOR);
					mixin(MenuAction!("mv", MenuID.EditSceneDup));
					mixin(MenuAction!("mv", MenuID.EditEventDup));
				}
				new MenuItem(mv, SWT.SEPARATOR);
				mixin(MenuAction!("mv", MenuID.ChangeVH));
				dStr ~= " - " ~ .text(__LINE__);

				auto ma = createMenu(_comm, bar, MenuID.Table);
				setupMenuListener(ma);
				mixin(MenuAction!("ma", MenuID.EditSummary, SWT.PUSH, "_tableWin.editSummary", "&_tableWin.canEditSummary"));
				new MenuItem(ma, SWT.SEPARATOR);
				mixin(MenuAction!("ma", MenuID.EditScene));
				mixin(MenuAction!("ma", MenuID.EditEvent));
				new MenuItem(ma, SWT.SEPARATOR);
				mixin(MenuAction!("ma", MenuID.NewAreaDir, SWT.PUSH, "_tableWin.createAreaDir", "&_tableWin.canCreateAreaDir"));
				mixin(MenuAction!("ma", MenuID.NewArea, SWT.PUSH, "_tableWin.createArea", "&_tableWin.canCreateArea"));
				mixin(MenuAction!("ma", MenuID.NewBattle, SWT.PUSH, "_tableWin.createBattle", "&_tableWin.canCreateBattle"));
				mixin(MenuAction!("ma", MenuID.NewPackage, SWT.PUSH, "_tableWin.createPackage", "&_tableWin.canCreatePackage"));

				auto mf = createMenu(_comm, bar, MenuID.Variable);
				setupMenuListener(mf);
				mixin(MenuAction!("mf", MenuID.NewFlagDir, SWT.PUSH, "_flagWin.createFlagDir", "&_flagWin.canCreateFlagDir"));
				mixin(MenuAction!("mf", MenuID.NewFlag, SWT.PUSH, "_flagWin.createFlag", "&_flagWin.canCreateFlag"));
				mixin(MenuAction!("mf", MenuID.NewStep, SWT.PUSH, "_flagWin.createStep", "&_flagWin.canCreateStep"));
				mixin(MenuAction!("mf", MenuID.NewVariant, SWT.PUSH, "_flagWin.createVariant", "&_flagWin.canCreateVariant"));

				auto mc = createMenu(_comm, bar, MenuID.Card);
				setupMenuListener(mc);
				auto g = new RadioGroupAndSet!(MenuItem);
				g.menuIDs.add(MenuID.ShowCardProp);
				g.menuIDs.add(MenuID.ShowCardImage);
				g.menuIDs.add(MenuID.ShowCardDetail);
				mixin(MenuAction!("mc", MenuID.ShowCardProp, SWT.RADIO, "showCardLife", "null"));
				auto scf = _menu[MenuID.ShowCardProp];
				g.append(scf);
				mixin(MenuAction!("mc", MenuID.ShowCardImage, SWT.RADIO, "showCardList", "null"));
				auto scl = _menu[MenuID.ShowCardImage];
				g.append(scl);
				mixin(MenuAction!("mc", MenuID.ShowCardDetail, SWT.RADIO, "showCardTable", "null"));
				auto sct = _menu[MenuID.ShowCardDetail];
				g.append(sct);
				if (_prop.var.etc.cardLife) { mixin(S_TRACE);
					scf.setSelection(true);
 				} else if (_prop.var.etc.cardDetails) { mixin(S_TRACE);
					sct.setSelection(true);
				} else { mixin(S_TRACE);
					scl.setSelection(true);
				}
				_menuRG ~= g;
				new MenuItem(mc, SWT.SEPARATOR);
				mixin(MenuAction!("mc", MenuID.NewCast, SWT.PUSH, "newCast", "&canNewCast"));
				mixin(MenuAction!("mc", MenuID.NewSkill, SWT.PUSH, "newSkill", "&canNewSkill"));
				mixin(MenuAction!("mc", MenuID.NewItem, SWT.PUSH, "newItem", "&canNewItem"));
				mixin(MenuAction!("mc", MenuID.NewBeast, SWT.PUSH, "newBeast", "&canNewBeast"));
				mixin(MenuAction!("mc", MenuID.NewInfo, SWT.PUSH, "newInfo", "&canNewInfo"));
				dStr ~= " - " ~ .text(__LINE__);

				auto mt = createMenu(_comm, bar, MenuID.Tool);
				setupMenuListener(mt);
				void delegate(SelectionEvent) dummy = null;
				auto eemi = createMenuItem(_comm, mt, MenuID.ExecEngine, dummy, () => canExecEngine || _prop.var.etc.classicEngines.length, SWT.CASCADE);
				_menu[MenuID.ExecEngine] = eemi;
				_mExecEngine = new Menu(eemi);
				eemi.setMenu(_mExecEngine);
				auto eewpmi = createMenuItem(_comm, mt, MenuID.ExecEngineWithParty, dummy, &canExecEngineWithPartyMenu, SWT.CASCADE);
				_menu[MenuID.ExecEngineWithParty] = eewpmi;
				_mExecEngineWithParty = new Menu(eewpmi);
				eewpmi.setMenu(_mExecEngineWithParty);
				new MenuItem(mt, SWT.SEPARATOR);
				mixin(MenuAction!("mt", MenuID.OpenDir, SWT.PUSH, "openDirectory", "&canOpenDirectory"));
				new MenuItem(mt, SWT.SEPARATOR);
				auto otmi = createMenuItem(_comm, mt, MenuID.OuterTools, dummy, () => _prop.var.etc.outerTools.length > 0, SWT.CASCADE);
				_mOuterTools = new Menu(otmi);
				otmi.setMenu(_mOuterTools);
				new MenuItem(mt, SWT.SEPARATOR);
				auto impmi = createMenuItem(_comm, mt, MenuID.OpenImportSource, dummy, () => canAddScenario || canEditImportHistory, SWT.CASCADE);
				auto impm = new Menu(impmi);
				impmi.setMenu(impm);
				.listener(impm, SWT.Show, { mixin(S_TRACE);
					createImportHistoryMenu(impm, true);
				});
				new MenuItem(mt, SWT.SEPARATOR);
				mixin(MenuAction!("mt", MenuID.CustomizeToolBar, SWT.PUSH, "customizeToolBar", "null"));
				new MenuItem(mt, SWT.SEPARATOR);
				mixin(MenuAction!("mt", MenuID.OpenBackupDir, SWT.PUSH, "openBackupDirectory", "&canOpenBackupDirectory"));
				new MenuItem(mt, SWT.SEPARATOR);
				mixin(MenuAction!("mt", MenuID.Settings, SWT.PUSH, "settings", "null"));

				auto mh = createMenu(_comm, bar, MenuID.Help);
				setupMenuListener(mh);
				mixin(MenuAction!("mh", MenuID.VersionInfo, SWT.PUSH, "versionInfo", "null"));

				_win.setMenuBar(bar);
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);

			Menu tmOpenCardWin;
			void createCardWinTI(ToolBar bar) { mixin(S_TRACE);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.cwCast, _prop.images.casts, &openCast, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.skill, _prop.images.skill, &openSkill, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.item, _prop.images.item, &openItem, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.beast, _prop.images.beast, &openBeast, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.info, _prop.images.info, &openInfo, null);
			}

			dStr ~= " - " ~ .text(__LINE__);
			createMainToolBar(false);

			_comm.baseShell(this, _tableWin, _flagWin, _castWin, _skillWin, _itemWin, _beastWin, _infoWin, _dirWin,
				_couponWin, _gossipWin, _completeStampWin, _keyCodeWin, _cellNameWin, _cardGroupWin);
			dStr ~= " - " ~ .text(__LINE__);
			auto selectFilter = new class Listener {
				override void handleEvent(Event e) { mixin(S_TRACE);
					if (cast(CTabFolder) e.widget || cast(TabFolder) e.widget) { mixin(S_TRACE);
						_comm.refreshToolBar();
					}
				}
			};
			auto focusInOut = new class Listener {
				private bool _noMode = false;
				override void handleEvent(Event e) { mixin(S_TRACE);
					auto control = cast(Control)e.widget;
					if (!control) return;
					auto shl = control.getShell();
					assert (shl !is null);
					if (e.type is SWT.KeyUp || e.type is SWT.KeyDown) { mixin(S_TRACE);
						if (cast(Spinner)control || cast(NoIME)control || cast(NoIME)control.getData()) { mixin(S_TRACE);
							shl.setImeInputMode(SWT.NONE);
							_noMode = true;
						}
					} else if (e.type is SWT.FocusIn) { mixin(S_TRACE);
						if (cast(Spinner)control || cast(NoIME)control || cast(NoIME)control.getData()) { mixin(S_TRACE);
							shl.setImeInputMode(SWT.NONE);
							_noMode = true;
						} else if (!_noMode) {
							shl.setImeInputMode(_prop.var.etc.imeMode);
						}
						_comm.refreshToolBar();
					} else { mixin(S_TRACE);
						assert (e.type is SWT.FocusOut);
						if (cast(Spinner)control || cast(NoIME)control || cast(NoIME)control.getData()) { mixin(S_TRACE);
							shl.setImeInputMode(_prop.var.etc.imeMode);
							_noMode = false;
						} else if (!_noMode) { mixin(S_TRACE);
							_prop.var.etc.imeMode = shl.getImeInputMode();
							_noMode = false;
						}
					}
				}
			};
			_win.setImeInputMode(_prop.var.etc.imeMode);
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
			.listener(_win, SWT.Dispose, { mixin(S_TRACE);
				d.removeFilter(SWT.Selection, selectFilter);
				d.removeFilter(SWT.FocusIn, focusInOut);
				d.removeFilter(SWT.FocusOut, focusInOut);
				d.removeFilter(SWT.KeyUp, focusInOut);
				d.removeFilter(SWT.KeyDown, focusInOut);
				d.removeFilter(SWT.KeyDown, keyDownFilter);
				d.removeFilter(SWT.MouseWheel, switchTab);
				d.removeFilter(SWT.Traverse, switchTab);
			});

			dStr ~= " - " ~ .text(__LINE__);
			int tx = _prop.var.mainWin.x == SWT.DEFAULT ? _win.getBounds().x : _prop.var.mainWin.x;
			int ty = _prop.var.mainWin.y == SWT.DEFAULT ? _win.getBounds().y : _prop.var.mainWin.y;
			_win.setMaximized(_prop.var.mainWin.maximized);
			intoDisplay(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
			_win.setBounds(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
			_win.layout(true);
			dStr ~= " - " ~ .text(__LINE__);
			.bgmVolume = _prop.var.etc.bgmVolume;
			.seVolume = _prop.var.etc.seVolume;
			dStr ~= " - " ~ .text(__LINE__);
			refShowMainToolBar();
			dStr ~= " - " ~ .text(__LINE__);
			if (_dock) { mixin(S_TRACE);
				if (_dock.pane("data")) { mixin(S_TRACE);
					dockSelect("data");
				} else if (_dock.pane("card")) { mixin(S_TRACE);
					dockSelect("card");
				} else if (_dock.pane("flag")) { mixin(S_TRACE);
					dockSelect("flag");
				} else if (_dock.pane("castCard")) { mixin(S_TRACE);
					dockSelect("castCard");
				} else if (_dock.pane("skillCard")) { mixin(S_TRACE);
					dockSelect("skillCard");
				} else if (_dock.pane("itemCard")) { mixin(S_TRACE);
					dockSelect("itemCard");
				} else if (_dock.pane("beastCard")) { mixin(S_TRACE);
					dockSelect("beastCard");
				} else if (_dock.pane("infoCard")) { mixin(S_TRACE);
					dockSelect("infoCard");
				} else if (_dock.pane("file")) { mixin(S_TRACE);
					dockSelect("file");
				}
				dStr ~= " - " ~ .text(__LINE__);
				setupMenu(_menu);
				setupMenu(_tool);
			}
		} catch (Throwable e) {
			// 起動失敗
			printStackTrace();
			fdebugln(dStr);
			fdebugln(e);
			throw e;
		}
	}
	private void createMainToolBar(bool saveOrder) { mixin(S_TRACE);
		_tmExecEngine = null;
		_tiExecEngine = null;
		_tmExecEngineWithParty = null;
		_tiExecEngineWithParty = null;
		_tmOuterTools = null;
		_tmOpenImportSource = null;

		_toolRG = [];
		_toolBar = [];
		_tool = null;
		if (_cbar) { mixin(S_TRACE);
			auto oldTools = _prop.var.etc.mainToolBar.dup;
			auto oldOrder = _prop.var.etc.toolsOrder.dup;
			_cbar.dispose();
			if (!saveOrder) { mixin(S_TRACE);
				_prop.var.etc.mainToolBar = oldTools;
				_prop.var.etc.toolsOrder = oldOrder;
			}
		}
		void arrangeOrder() { mixin(S_TRACE);
			// メインツールバーの順序をCoolBarのItemOrderに基づいて整理する
			foreach (i; .iota(0, cast(int)_prop.var.etc.mainToolBar.tools.length)) { mixin(S_TRACE);
				if (!.contains(_prop.var.etc.toolsOrder, i)) { mixin(S_TRACE);
					_prop.var.etc.toolsOrder.value ~= i;
				}
			}
			Tool[][] tools;
			foreach (i; _prop.var.etc.toolsOrder) { mixin(S_TRACE);
				if (0 <= i && i < _prop.var.etc.mainToolBar.tools.length) { mixin(S_TRACE);
					tools ~= _prop.var.etc.mainToolBar.tools[i];
				}
			}
			_prop.var.etc.mainToolBar.tools = tools;
			_prop.var.etc.toolsOrder = .iota(0, cast(int)tools.length).array();
		}
		_cbar = createCoolBar!("tools")(_comm, _toolComp, false, (Composite cbar) { mixin(S_TRACE);
			void createCoolItem(Composite comp, ToolBar tbar) { mixin(S_TRACE);
				if (auto cbar = cast(CoolBar)comp) .createCoolItem(cbar, tbar);
				_toolBar ~= tbar;
			}
			auto cardRG = new RadioGroupAndSet!ToolItem;
			cardRG.menuIDs.add(MenuID.ShowCardProp);
			cardRG.menuIDs.add(MenuID.ShowCardImage);
			cardRG.menuIDs.add(MenuID.ShowCardDetail);

			arrangeOrder();
			if (auto bar = cast(CoolBar)cbar) { mixin(S_TRACE);
				.listener(cbar, SWT.Dispose, { mixin(S_TRACE);
					_prop.var.etc.toolsOrder = bar.getItemOrder();
					arrangeOrder();
				});
			}

			foreach (toolbar; _prop.var.etc.mainToolBar.tools) { mixin(S_TRACE);
				auto bar = new ToolBar(cbar, SWT.FLAT);
				foreach (tool; toolbar) { mixin(S_TRACE);
					if (tool.separator) { mixin(S_TRACE);
						new ToolItem(bar, SWT.SEPARATOR);
					} else { mixin(S_TRACE);
						void delegate(SelectionEvent se) actS = null;
						void delegate() act = null;
						bool delegate() can = null;
						int style = SWT.PUSH;

						final switch (tool.menu) {
						case MenuID.New: act = &createScenario; can = null; break;
						case MenuID.Open: act = &openScenarioM; can = null; break;
						case MenuID.Save: act = &saveScenario; can = &canSaveOverwrite; break;
						case MenuID.SaveAs: act = &saveScenarioA; can = () => summary !is null && !_inSaving; break;
						case MenuID.CreateArchive: act = &_dirWin.createArchive; can = &_dirWin.canCreateArchive; break;
						case MenuID.Reload: act = &reload; can = () => _prop.var.etc.scenarioBookmarks.length || _prop.var.etc.openHistories.length; break;
						case MenuID.EditScenarioHistory: act = &editScenarioHistory; can = &canEditScenarioHistory; break;
						case MenuID.EditImportHistory: act = &editImportHistory; can = &canEditImportHistory; break;
						case MenuID.EditExecutedPartyHistory: act = &editExecutedPartyHistory; can = &canEditExecutedPartyHistory; break;
						case MenuID.Refresh: actS = &refreshAll; can = () => summary !is null; break;
						case MenuID.Find: act = &replaceText; can = null; break;
						case MenuID.ReNumberingAll: act = &reNumberingAll; can = () => summary !is null; break;
						case MenuID.ToXMLText: act = &clipboardToXML; can = () => CBisXMLOnly(_comm.clipboard); break;
						case MenuID.TableView: act = &openDataWindow; can = null; break;
						case MenuID.VarView: act = &openFlagWindow; can = null; break;
						case MenuID.CastView: act = &openCast; can = null; break;
						case MenuID.SkillView: act = &openSkill; can = null; break;
						case MenuID.ItemView: act = &openItem; can = null; break;
						case MenuID.BeastView: act = &openBeast; can = null; break;
						case MenuID.InfoView: act = &openInfo; can = null; break;
						case MenuID.FileView: act = &openDirWindow; can = null; break;
						case MenuID.CouponView: act = &openCouponWindow; can = null; break;
						case MenuID.GossipView: act = &openGossipWindow; can = null; break;
						case MenuID.CompleteStampView: act = &openCompleteStampWindow; can = null; break;
						case MenuID.KeyCodeView: act = &openKeyCodeWindow; can = null; break;
						case MenuID.CellNameView: act = &openCellNameWindow; can = null; break;
						case MenuID.CardGroupView: act = &openCardGroupWindow; can = null; break;
						case MenuID.EditSummary: act = &_tableWin.editSummary; can = () => summary !is null; break;
						case MenuID.NewAreaDir: act = &_tableWin.createAreaDir; can = &_tableWin.canCreateAreaDir; break;
						case MenuID.NewArea: act = &_tableWin.createArea; can = &_tableWin.canCreateArea; break;
						case MenuID.NewBattle: act = &_tableWin.createBattle; can = &_tableWin.canCreateBattle; break;
						case MenuID.NewPackage: act = &_tableWin.createPackage; can = &_tableWin.canCreatePackage; break;
						case MenuID.NewFlagDir: act = &_flagWin.createFlagDir; can = &_flagWin.canCreateFlagDir; break;
						case MenuID.NewFlag: act = &_flagWin.createFlag; can = &_flagWin.canCreateFlag; break;
						case MenuID.NewStep: act = &_flagWin.createStep; can = &_flagWin.canCreateStep; break;
						case MenuID.NewVariant: act = &_flagWin.createVariant; can = &_flagWin.canCreateVariant; break;
						case MenuID.ShowCardProp: actS = &showCardLife; can = null; style = SWT.RADIO; break;
						case MenuID.ShowCardImage: actS = &showCardList; can = null; style = SWT.RADIO; break;
						case MenuID.ShowCardDetail: actS = &showCardTable; can = null; style = SWT.RADIO; break;
						case MenuID.NewCast: act = &newCast; can = &canNewCast; break;
						case MenuID.NewSkill: act = &newSkill; can = &canNewSkill; break;
						case MenuID.NewItem: act = &newItem; can = &canNewItem; break;
						case MenuID.NewBeast: act = &newBeast; can = &canNewBeast; break;
						case MenuID.NewInfo: act = &newInfo; can = &canNewInfo; break;
						case MenuID.OpenImportSource: createOpenImportSourceTI(bar); continue;
						case MenuID.SelectImportSource: act = &addScenario; can = &canAddScenario; break;
						case MenuID.OpenDir: act = &openDirectory; can = &canOpenDirectory; break;
						case MenuID.OpenBackupDir: act = &openBackupDirectory; can = &canOpenBackupDirectory; break;
						case MenuID.NewDir: act = &_dirWin.createNewFolder; can = &_dirWin.canCreateNewFolder; break;
						case MenuID.ExecEngine: createExecEngineTI(bar); continue;
						case MenuID.ExecEngineWithParty: createExecEngineWithPartyTI(bar); continue;
						case MenuID.OuterTools: createOuterToolsTI(bar); continue;
						case MenuID.Settings: act = &settings; can = null; break;
						case MenuID.DelNotUsedFile: actS = &_dirWin.deleteUnuse; can = &_dirWin.canDeleteUnuse; break;
						case MenuID.NewAtNewWindow: act = &createScenarioNewWin; can = null; break;
						case MenuID.OpenAtNewWindow: act = &openScenarioNewWin; can = null; break;
						case MenuID.Close: act = &exitAll; can = null; break;
						case MenuID.VersionInfo: act = &versionInfo; can = null; break;
						case MenuID.IncSearch: actS = &doMenu!(MenuID.IncSearch); can = &canDoMenu!(MenuID.IncSearch); break;
						case MenuID.SelectAll: actS = &doMenu!(MenuID.SelectAll); can = &canDoMenu!(MenuID.SelectAll); break;
						case MenuID.DeleteNotExistsHistory: act = &delNotExistsScenario; can = &canDelNotExistsScenario; break;
						case MenuID.DeleteNotExistsParties: act = &delNotExistsParty; can = &canDelNotExistsParty; break;
						case MenuID.CopyAll:
						case MenuID.AddItem:
						case MenuID.DelItem:
						case MenuID.Undo:
						case MenuID.Redo:
						case MenuID.Cut:
						case MenuID.Copy:
						case MenuID.Paste:
						case MenuID.Delete:
						case MenuID.Clone:
						case MenuID.Comment:
						case MenuID.ToScript:
						case MenuID.ToScriptAll:
						case MenuID.Up:
						case MenuID.Down:
						case MenuID.ConvertCouponType:
						case MenuID.ConvertCouponTypeNormal:
						case MenuID.ConvertCouponTypeHide:
						case MenuID.ConvertCouponTypeDur:
						case MenuID.ConvertCouponTypeDurBattle:
						case MenuID.ConvertCouponTypeSystem:
						case MenuID.CopyTypeConvertedCoupon:
						case MenuID.CopyTypeConvertedCouponNormal:
						case MenuID.CopyTypeConvertedCouponHide:
						case MenuID.CopyTypeConvertedCouponDur:
						case MenuID.CopyTypeConvertedCouponDurBattle:
						case MenuID.CopyTypeConvertedCouponSystem:
						case MenuID.AddInitialCoupons:
						case MenuID.ReverseSignOfValues:
						case MenuID.Reverse:
						case MenuID.SelectConnectedResource:
						case MenuID.FindID:
						case MenuID.EditScene:
						case MenuID.EditSceneDup:
						case MenuID.EditEvent:
						case MenuID.EditEventDup:
						case MenuID.EditProp:
						case MenuID.ShowProp:
						case MenuID.Cut1Content:
						case MenuID.Copy1Content:
						case MenuID.Delete1Content:
						case MenuID.PasteInsert:
						case MenuID.SetStartArea:
						case MenuID.CopyVariablePath:
						case MenuID.SwapToParent:
						case MenuID.SwapToChild:
						case MenuID.Import:
						case MenuID.OpenHand:
						case MenuID.AddHand:
						case MenuID.RemoveRef:
						case MenuID.EditEventAtTimeOfUsing:
						case MenuID.Hold:
						case MenuID.CopyFilePath:
						case MenuID.ToScript1Content:
						case MenuID.ChangeVH:
						case MenuID.ReNumbering:
						case MenuID.EventToPackage:
						case MenuID.StartToPackage:
						case MenuID.WrapTree:
							break;
						case MenuID.None:
						case MenuID.File:
						case MenuID.Edit:
						case MenuID.View:
						case MenuID.Tool:
						case MenuID.Table:
						case MenuID.Variable:
						case MenuID.Help:
						case MenuID.Card:
						case MenuID.CardsAndBacks:
						case MenuID.CreateSubWindow:
						case MenuID.LeftPane:
						case MenuID.RightPane:
						case MenuID.ClosePane:
						case MenuID.ClosePaneExcept:
						case MenuID.ClosePaneLeft:
						case MenuID.ClosePaneRight:
						case MenuID.ClosePaneAll:
						case MenuID.CloseWin:
						case MenuID.OpenPlace:
						case MenuID.SaveImage:
						case MenuID.IncludeImage:
						case MenuID.LookImages:
						case MenuID.EditLayers:
						case MenuID.AddLayer:
						case MenuID.RemoveLayer:
						case MenuID.CloseIncSearch:
						case MenuID.CardView:
						case MenuID.ExecEngineAuto:
						case MenuID.ExecEngineMain:
						case MenuID.ExecEngineWithLastParty:
						case MenuID.LockToolBar:
						case MenuID.ResetToolBar:
						case MenuID.CopyAsText:
						case MenuID.OpenAtView:
						case MenuID.CreateContent:
						case MenuID.ConvertContent:
						case MenuID.CGroupTerminal:
						case MenuID.CGroupStandard:
						case MenuID.CGroupData:
						case MenuID.CGroupUtility:
						case MenuID.CGroupBranch:
						case MenuID.CGroupGet:
						case MenuID.CGroupLost:
						case MenuID.CGroupVisual:
						case MenuID.CGroupVariant:
						case MenuID.CreateStepValues:
						case MenuID.PutSPChar:
						case MenuID.PutFlagValue:
						case MenuID.PutStepValue:
						case MenuID.PutVariantValue:
						case MenuID.PutColor:
						case MenuID.PutSkinSPChar:
						case MenuID.PutImageFont:
						case MenuID.CreateVariableEventTree:
						case MenuID.InitVariablesTree:
						case MenuID.OverDialog:
						case MenuID.UnderDialog:
						case MenuID.CreateDialog:
						case MenuID.DeleteDialog:
						case MenuID.CopyToAllDialogs:
						case MenuID.CopyToUpperDialogs:
						case MenuID.CopyToLowerDialogs:
						case MenuID.ShowParty:
						case MenuID.ShowMsg:
						case MenuID.ShowRefCards:
						case MenuID.FixedCards:
						case MenuID.FixedCells:
						case MenuID.FixedBackground:
						case MenuID.ShowGrid:
						case MenuID.ShowEnemyCardProp:
						case MenuID.ShowCard:
						case MenuID.ShowBack:
						case MenuID.NewMenuCard:
						case MenuID.NewEnemyCard:
						case MenuID.NewBack:
						case MenuID.NewTextCell:
						case MenuID.NewColorCell:
						case MenuID.NewPCCell:
						case MenuID.AutoArrange:
						case MenuID.ManualArrange:
						case MenuID.PossibleToRunAway:
						case MenuID.SortWithPosition:
						case MenuID.Mask:
						case MenuID.Escape:
						case MenuID.ChangePos:
						case MenuID.PosTop:
						case MenuID.PosBottom:
						case MenuID.PosLeft:
						case MenuID.PosRight:
						case MenuID.PosEven:
						case MenuID.NearTop:
						case MenuID.NearBottom:
						case MenuID.NearLeft:
						case MenuID.NearRight:
						case MenuID.NearCenterH:
						case MenuID.NearCenterV:
						case MenuID.NearCenter:
						case MenuID.ScaleMin:
						case MenuID.ScaleMiddle:
						case MenuID.ScaleMax:
						case MenuID.ScaleBig:
						case MenuID.ScaleSmall:
						case MenuID.ExpandBack:
						case MenuID.StopBGM:
						case MenuID.PlayBGM:
						case MenuID.NewEvent:
						case MenuID.NewEventWithDialog:
						case MenuID.KeyCodeTiming:
						case MenuID.KeyCodeTimingUse:
						case MenuID.KeyCodeTimingSuccess:
						case MenuID.KeyCodeTimingFailure:
						case MenuID.KeyCodeTimingHasNot:
						case MenuID.CopyTimingConvertedKeyCode:
						case MenuID.CopyTimingConvertedKeyCodeUse:
						case MenuID.CopyTimingConvertedKeyCodeSuccess:
						case MenuID.CopyTimingConvertedKeyCodeFailure:
						case MenuID.CopyTimingConvertedKeyCodeHasNot:
						case MenuID.AddKeyCodesByFeatures:
						case MenuID.KeyCodeCond:
						case MenuID.KeyCodeCondOr:
						case MenuID.KeyCodeCondAnd:
						case MenuID.AddRangeOfRound:
						case MenuID.OpenAtTableView:
						case MenuID.OpenAtVarView:
						case MenuID.OpenAtCardView:
						case MenuID.OpenAtFileView:
						case MenuID.OpenAtEventView:
						case MenuID.PlaySE:
						case MenuID.StopSE:
						case MenuID.PutQuick:
						case MenuID.PutSelect:
						case MenuID.PutContinue:
						case MenuID.EvTemplates:
						case MenuID.EvTemplatesOfScenario:
						case MenuID.EditSelection:
						case MenuID.Expand:
						case MenuID.Collapse:
						case MenuID.SelectCurrentEvent:
						case MenuID.ResetValues:
						case MenuID.ResetValuesAll:
						case MenuID.CustomizeToolBar:
						case MenuID.AddTool:
						case MenuID.AddToolBar:
						case MenuID.AddToolGroup:
						case MenuID.ResetToolBarSettings:
						case MenuID.PutParty:
						case MenuID.SelectIcon:
						case MenuID.SelectPresetIcon:
						case MenuID.DeleteIcon:
							debugln(tool.menu);
							continue;
						}

						if (act) { mixin(S_TRACE);
							_mainMenu.add(tool.menu);
							_tool[tool.menu] = createToolItem(_comm, bar, tool.menu, act, can, style);
						} else if (actS) { mixin(S_TRACE);
							_mainMenu.add(tool.menu);
							_tool[tool.menu] = createToolItem(_comm, bar, tool.menu, actS, can, style);
						} else { mixin(S_TRACE);
							_tool[tool.menu] = createToolItem(_comm, bar, tool.menu, menuActionDlg(tool.menu), can, style);
						}
					}
				}
				createCoolItem(cbar, bar);
			}
			// カードビューの表示方法(ラジオボタン)
			auto scf = _tool.get(MenuID.ShowCardProp, null);
			if (scf) cardRG.append(scf);
			auto scl = _tool.get(MenuID.ShowCardImage, null);
			if (scl) cardRG.append(scl);
			auto sct = _tool.get(MenuID.ShowCardDetail, null);
			if (sct) cardRG.append(sct);
			if (_prop.var.etc.cardLife) { mixin(S_TRACE);
				if (scf) scf.setSelection(true);
			} else if (_prop.var.etc.cardDetails) { mixin(S_TRACE);
				if (sct) sct.setSelection(true);
			} else { mixin(S_TRACE);
				if (scl) scl.setSelection(true);
			}
			if (cardRG.set.size) { mixin(S_TRACE);
				_toolRG ~= cardRG;
			}
		}, (menu) { mixin(S_TRACE);
			createMenuItem(_comm, menu, MenuID.CustomizeToolBar, { mixin(S_TRACE);
				if (auto bar = cast(CoolBar)_cbar) { mixin(S_TRACE);
					_prop.var.etc.toolsOrder = bar.getItemOrder();
				}
				arrangeOrder();
				customizeToolBar();
			}, null);
		});
		if (cast(CoolBar)_cbar ? (cast(CoolBar)_cbar).getItemCount() == 0 : _cbar.getChildren().length == 0) { mixin(S_TRACE);
			_cbar.dispose();
			_cbar = null;
		}
		refShowMainToolBar();

		refreshExecEngine();
		refreshOuterTools();
	}
	private void createExecEngineTI(ToolBar bar) { mixin(S_TRACE);
		_mainMenu.add(MenuID.ExecEngine);
		_tiExecEngine = createDropDownItem(_comm, bar, MenuID.ExecEngine, &execEngine, _tmExecEngine, () => canExecEngine || _prop.var.etc.classicEngines.length);
		_tool[MenuID.ExecEngine] = _tiExecEngine;
		listener(_tiExecEngine, SWT.Dispose, (e) { mixin(S_TRACE);
			auto tiExecEngine = cast(ToolItem)e.widget;
			auto img = tiExecEngine.getImage();
			if (_prop.images.menu(MenuID.ExecEngineAuto) !is img) { mixin(S_TRACE);
				img.dispose();
			}
		});
	}
	private void createExecEngineWithPartyTI(ToolBar bar) { mixin(S_TRACE);
		_mainMenu.add(MenuID.ExecEngineWithParty);
		_tiExecEngineWithParty = createDropDownItem(_comm, bar, MenuID.ExecEngineWithParty, &execEngineWithLastParty, _tmExecEngineWithParty, () => canExecEngineWithLastParty || canExecEngineWithPartyMenu);
		_tool[MenuID.ExecEngineWithParty] = _tiExecEngineWithParty;
		listener(_tiExecEngineWithParty, SWT.Dispose, (e) { mixin(S_TRACE);
			auto tiExecEngineWithParty = cast(ToolItem)e.widget;
			auto img = tiExecEngineWithParty.getImage();
			if (_prop.images.menu(MenuID.ExecEngineWithParty) !is img) { mixin(S_TRACE);
				img.dispose();
			}
		});
		updateExecEngineWithPartyNameTI();
	}
	private void createOuterToolsTI(ToolBar bar) { mixin(S_TRACE);
		_mainMenu.add(MenuID.OuterTools);
		auto ti = createDropDownItem(_comm, bar, MenuID.OuterTools, null, _tmOuterTools, () => _prop.var.etc.outerTools.length > 0);
		_tool[MenuID.OuterTools] = ti;
	}
	private Menu _tmOpenImportSource = null;
	private void createOpenImportSourceTI(ToolBar bar) { mixin(S_TRACE);
		_mainMenu.add(MenuID.OpenImportSource);
		auto ti = .createDropDownItem(_comm, bar, MenuID.OpenImportSource, &addScenario, _tmOpenImportSource, () => canAddScenario || canEditImportHistory, (bool arrow) => arrow || !canAddScenario);
		_tool[MenuID.OpenImportSource] = ti;
		.listener(_tmOpenImportSource, SWT.Show, { mixin(S_TRACE);
			createImportHistoryMenu(_tmOpenImportSource, false);
		});
	}
	ToolBarCustomDialog _customizeToolBarDlg = null;
	private void customizeToolBar() { mixin(S_TRACE);
		if (_customizeToolBarDlg) { mixin(S_TRACE);
			_customizeToolBarDlg.active();
			return;
		}
		auto dlg = new ToolBarCustomDialog(_comm, _win, _prop.var.etc.mainToolBar, _prop.var.etc.mainToolBar.INIT);
		dlg.appliedEvent ~= { mixin(S_TRACE);
			_prop.var.etc.mainToolBar = dlg.tools;
			_prop.var.etc.toolsOrder = .iota(0, cast(int)dlg.tools.tools.length).array();
			updateMainToolBar(false);
			sendReloadPropsAndSave();
		};
		_customizeToolBarDlg = dlg;
		dlg.closeEvent ~= { _customizeToolBarDlg = null; };
		dlg.open();
	}
	public void updateMainToolBar(bool saveOrder = true) { mixin(S_TRACE);
		if (_win.isVisible()) _win.setRedraw(false);
		scope (exit) {
			if (_win.isVisible()) _win.setRedraw(true);
		}
		createMainToolBar(saveOrder);
		refShowMainToolBar();
		_toolComp.layout(true);
		_toolComp.getParent().layout(true);
		_comm.refreshToolBar();
	}
	private void doMenu(MenuID ID)(SelectionEvent e) { mixin(S_TRACE);
		auto menu = getMenu!ID;
		if (!menu) return;
		.doMenu(menu, e);
	}
	@property
	private MenuItem getMenu(MenuID ID)() { mixin(S_TRACE);
		auto fc = _win.getDisplay().getFocusControl();
		if (!fc) return null;
		auto menu = fc.getMenu();
		MenuItem recurse(Menu menu) { mixin(S_TRACE);
			if (!menu) return null;
			foreach (mi; menu.getItems()) { mixin(S_TRACE);
				auto m = cast(MenuData)mi.getData();
				if (m && m.id == ID && (!m.enabled || m.enabled())) { mixin(S_TRACE);
					return mi;
				}
				mi = recurse(mi.getMenu());
				if (mi) return mi;
			}
			return null;
		}
		return recurse(menu);
	}
	@property
	private bool canDoMenu(MenuID ID)() { mixin(S_TRACE);
		return getMenu!ID !is null;
	}
	private class KeyDownFilter : Listener {
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!e.doit) return;
			auto text = cast(Text)e.widget;
			if (text && cast(CCombo)text.getParent()) { mixin(S_TRACE);
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
			if (ro && cast(Spinner)fc) { mixin(S_TRACE);
				return;
			}
			if (ro && (cast(Spinner)fc || cast(Text)fc || cast(StyledText)fc || cast(Combo)fc || cast(CCombo)fc)) { mixin(S_TRACE);
				if (!(e.stateMask & SWT.CTRL) && !.contains!("a == b", int, int)(F, e.keyCode)) { mixin(S_TRACE);
					return;
				}
			}
			if (cast(IgnoreHotkey)fc.getData()) { mixin(S_TRACE);
				return;
			}
			if (fc.getMenu()) { mixin(S_TRACE);
				auto menu = findMenu(fc.getMenu(), e.keyCode, e.character, e.stateMask);
				if (menu && .menuEnabled(menu)) { mixin(S_TRACE);
					raiseEvent(menu, e);
					return;
				}
				if (!menu && (cast(Tree)fc.getParent() || cast(Table)fc.getParent())) { mixin(S_TRACE);
					// ツリー・テーブルアイテムの項目編集中
					menu = findMenu(fc.getParent().getMenu(), e.keyCode, e.character, e.stateMask);
					if (menu && .menuEnabled(menu)) { mixin(S_TRACE);
						raiseEvent(menu, e);
						return;
					}
				}
			}
			if (!.isDescendant(_win, fc.getShell())) return;

			// フォーカスのあるコントロールのShellのメニューを探し、
			// 該当するメニューが無かった場合は
			// 順に上位のShellを探索する
			auto shl = fc.getShell();
			MenuItem menu = null;
			while (!menu && shl) { mixin(S_TRACE);
				menu = findMenu(shl, e.keyCode, e.character, e.stateMask);
				if (menu) break;
				if (shl is _win) break;
				int s = shl.getStyle();
				if ((s & SWT.PRIMARY_MODAL) || (s & SWT.APPLICATION_MODAL) || (s & SWT.SYSTEM_MODAL)) { mixin(S_TRACE);
					break;
				}
				shl = cast(Shell)shl.getParent();
				if (!shl) break;
			}
			if (menu) { mixin(S_TRACE);
				// アプリケーション全体を対象としたメニュー以外は、
				// 現在操作中のウィンドウのみで適用する
				auto data = cast(MenuData)menu.getData();
				if (data && shl !is fc.getShell() && !cast(DockingFolderShell)fc.getShell().getData() && !.isGlobalMenu(data.id)) { mixin(S_TRACE);
					return;
				}
			}
			if (menu && .menuEnabled(menu)) { mixin(S_TRACE);
				raiseEvent(menu, e);
				return;
			}
			auto tlp = getTopLevelPanel(fc);
			if (tlp) { mixin(S_TRACE);
				SelectionEvent selEvent() { mixin(S_TRACE);
					auto se = new SelectionEvent(e);
					se.widget = fc;
					se.time = e.time;
					se.stateMask = e.stateMask;
					se.doit = e.doit;
					return se;
				}
				if (tlp.doMenu(_comm, e.keyCode, e.character, e.stateMask, &selEvent)) return;

				auto key = _dock.keyFromCtrl(tlp.shell);
				auto paneKey = _dock.paneKeyFromCtrlKey(key);
				auto tabMenu = _dock.getMenu(paneKey);
				if (tabMenu) { mixin(S_TRACE);
					menu = findMenu(tabMenu, e.keyCode, e.character, e.stateMask);
					if (menu && .menuEnabled(menu)) { mixin(S_TRACE);
						raiseEvent(menu, e);
						return;
					}
				}
			}
		}
	}
	private void raiseEvent(E)(MenuItem menu, E e) { mixin(S_TRACE);
		_comm.isMenuAccelerating = .convertAccelerator(menu.getText());
		scope (exit) _comm.isMenuAccelerating = 0;
		if (menu.getStyle() & SWT.CHECK) { mixin(S_TRACE);
			menu.setSelection(!menu.getSelection());
		}
		if (menu.getStyle() & SWT.RADIO) { mixin(S_TRACE);
			menu.setSelection(!menu.getSelection());
			if (menu.getSelection()) { mixin(S_TRACE);
				foreach (etc; menu.getParent().getItems()) { mixin(S_TRACE);
					if (etc !is menu) { mixin(S_TRACE);
						menu.setSelection(false);
					}
				}
			}
		}
		auto se = new Event;
		se.type = SWT.Selection;
		se.widget = menu;
		se.time = e.time;
		se.stateMask = e.stateMask;
		se.doit = e.doit;
		menu.notifyListeners(SWT.Selection, se);
		e.doit = false;
	}
	private class SwitchTab : Listener {
		private Control _oldFocus = null;

		private bool switchTab(TabF, Tab)(TabF tabf, Tab tab, Event e) { mixin(S_TRACE);
			if (!tab || 0 == e.count) return false;
			auto w = cast(Control) e.widget;
			if (!w) return false;
			if (tabf.getItemCount() <= 1) return false;
			if (e.type is SWT.MouseWheel) { mixin(S_TRACE);
				auto p = w.toDisplay(e.x, e.y);
				auto ca = tabf.getClientArea();
				if (ca.y <= tabf.toControl(p).y) return false;
			}
			int index = tabf.indexOf(tab);
			assert (-1 != index);
			if (e.count < 0) { mixin(S_TRACE);
				index++;
				if (tabf.getItemCount() <= index) index = 0;
			} else if (0 < e.count) { mixin(S_TRACE);
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
		private void spinUpDown(Event e, Spinner spn) { mixin(S_TRACE);
			if (!e.doit) return;
			int val = spn.getSelection();
			if (e.count < 0) { mixin(S_TRACE);
				val -= spn.getIncrement();
			} else if (0 < e.count) { mixin(S_TRACE);
				val += spn.getIncrement();
			} else { mixin(S_TRACE);
				return;
			}
			spn.setSelection(val);
			if (spn.getSelection() != val) { mixin(S_TRACE);
				auto se = new Event;
				se.type = SWT.Selection;
				se.widget = spn;
				se.time = e.time;
				se.stateMask = e.stateMask;
				se.doit = e.doit;
				spn.notifyListeners(SWT.Selection, se);
				e.doit = se.doit;
			}
		}

		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!_prop.var.etc.switchTabWheel) return;
			if (e.type != SWT.MouseWheel && e.type != SWT.Traverse) return;
			auto d = Display.getCurrent();

			Control c;
			if (e.type is SWT.MouseWheel) { mixin(S_TRACE);
				c = d.getCursorControl();
			} else if (e.type is SWT.Traverse) { mixin(S_TRACE);
				c = d.getFocusControl();
				while (c) { mixin(S_TRACE);
					if (cast(CTabFolder) c) break;
					c = c.getParent();
				}
			}
			if (!c) return;
			if (!.isDescendant(_win, c.getShell())) return;

			if (e.type is SWT.Traverse && (e.stateMask & SWT.CTRL)) { mixin(S_TRACE);
				if (e.detail is SWT.TRAVERSE_TAB_NEXT) { mixin(S_TRACE);
					e.count = -1;
				} else if (e.detail is SWT.TRAVERSE_TAB_PREVIOUS) { mixin(S_TRACE);
					e.count = 1;
				} else { mixin(S_TRACE);
					return;
				}
			}

			auto ctabf = cast(CTabFolder) c;
			if (ctabf) { mixin(S_TRACE);
				if (switchTab(ctabf, ctabf.getSelection(), e)) { mixin(S_TRACE);
					e.doit = false;
				}
			}
			auto tabf = cast(TabFolder) c;
			if (tabf && tabf.getSelection() && 0 < tabf.getSelection().length) { mixin(S_TRACE);
				if (switchTab(tabf, tabf.getSelection()[0], e)) { mixin(S_TRACE);
					e.doit = false;
				}
			}

			if (e.type == SWT.MouseWheel && _prop.var.etc.spinnerUpDownWithWheel) { mixin(S_TRACE);
				auto spn = cast(Spinner)e.widget;
				if (spn) { mixin(S_TRACE);
					spinUpDown(e, spn);
					return;
				}
			}
		}
	}

	private void redrawAll() { mixin(S_TRACE);
		_win.redraw(true);
	}
	private bool canAddScenario() { mixin(S_TRACE);
		return summary !is null;
	}
	private void addScenario() { mixin(S_TRACE);
		_comm.addScenario(_prop);
	}
	private template NewCard(string Name) {
		static const NewCard = "auto cw = cast(CardWindow)_tlp;"
			~ "if (cw && cw.canCreate" ~ Name ~ ") {"
			~ "    cw.create" ~ Name ~ "();"
			~ "} else {"
			~ "    _" ~ .toLower(Name) ~ "Win.create" ~ Name ~ "();"
			~ "}";
	}
	private void openCast() { mixin(S_TRACE);
		_comm.openCastWin(true);
	}
	private void openSkill() { mixin(S_TRACE);
		_comm.openSkillWin(true);
	}
	private void openItem() { mixin(S_TRACE);
		_comm.openItemWin(true);
	}
	private void openBeast() { mixin(S_TRACE);
		_comm.openBeastWin(true);
	}
	private void openInfo() { mixin(S_TRACE);
		_comm.openInfoWin(true);
	}
	private void refreshAll(SelectionEvent se) { mixin(S_TRACE);
		foreach (ctrl; _dock.showingControls) { mixin(S_TRACE);
			auto tlpData = cast(TLPData) ctrl.getData();
			if (!tlpData) continue;
			auto act = tlpData.tlp.menuAction(MenuID.Refresh);
			if (act) act(se);
		}
	}
	private class TabfPaint : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			if (!_comm.wallpaper) return;
			auto tabf = cast(CTabFolder)e.widget;
			if (!tabf || tabf.getItemCount() > 0) return;
			if (!std.string.startsWith(_dock.key(tabf), "work")) return;
			auto rect = tabf.getClientArea();
			if (_prop.var.etc.wallpaperStyle < WallpaperStyle.min || WallpaperStyle.max < _prop.var.etc.wallpaperStyle) { mixin(S_TRACE);
				_prop.var.etc.wallpaperStyle = WallpaperStyle.Tile;
			}
			auto style = cast(WallpaperStyle)_prop.var.etc.wallpaperStyle;
			drawWallpaper(e.gc, _comm.wallpaper, rect, style);
		}
	}
	private class TabMenu {
		private string _paneKey;
		this (string paneKey) { mixin(S_TRACE);
			_paneKey = paneKey;
			auto comp = _dock.pane(paneKey);
			comp.addPaintListener(new TabfPaint);
			auto menu = new Menu(comp.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.CreateSubWindow, &createSubWindow, &canCreateSubWindow);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.LeftPane, &leftTab, &canWalkTab);
			createMenuItem(_comm, menu, MenuID.RightPane, &rightTab, &canWalkTab);
			new MenuItem(menu, SWT.SEPARATOR);
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
		bool canCreateSubWindow() { mixin(S_TRACE);
			return _dock.selectedCtrl(_paneKey).length > 0 && !_dock.isSinglePane(_paneKey);
		}
		@property
		bool canWalkTab() { mixin(S_TRACE);
			return 1 < _dock.controlCount(_paneKey) && 0 < _dock.selectedCtrl(_paneKey).length;
		}
		@property
		bool canClose() { mixin(S_TRACE);
			return _dock.selectedCtrl(_paneKey).length > 0;
		}
		@property
		bool canCloseEtc() { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			return ctrl.length && _dock.hasEtc(ctrl);
		}
		@property
		bool canCloseLeft() { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			return ctrl.length && _dock.hasLeft(ctrl);
		}
		@property
		bool canCloseRight() { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			return ctrl.length && _dock.hasRight(ctrl);
		}
		void createSubWindow(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.createSubWindow(ctrl);
		}
		void leftTab(SelectionEvent se) { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.walkLeft(ctrl);
		}
		void rightTab(SelectionEvent se) { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.walkRight(ctrl);
		}
		void close(SelectionEvent se) { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.close(ctrl);
		}
		void closeEtc(SelectionEvent se) { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeEtc(ctrl);
		}
		void closeLeft(SelectionEvent se) { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeLeft(ctrl);
		}
		void closeRight(SelectionEvent se) { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeRight(ctrl);
		}
		void closeAll(SelectionEvent se) { mixin(S_TRACE);
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeAll(ctrl);
		}
	}
	private void createPaneEvent(Composite parent, string paneKey) { mixin(S_TRACE);
		new TabMenu(paneKey);
	}
	private bool canOpenDirectory() { return summary !is null; }
	private void openDirectory() { mixin(S_TRACE);
		if (!summary) return;
		auto dirWin = cast(DirectoryWindow)_tlp;
		if (dirWin) { mixin(S_TRACE);
			dirWin.openDirectory();
		} else { mixin(S_TRACE);
			openFolder(summary.scenarioPath);
		}
	}
	const
	private bool canOpenBackupDirectory() { mixin(S_TRACE);
		return _prop.backupPath != "" && .exists(_prop.backupPath) && .isDir(_prop.backupPath);
	}
	const
	private void openBackupDirectory() { mixin(S_TRACE);
		if (!canOpenBackupDirectory) return;
		openFolder(_prop.backupPath);
	}
	private bool isMainCardWin(CardWindow cw) { mixin(S_TRACE);
		return cw.kind is CardWindowKind.Cast || cw.kind is CardWindowKind.Skill || cw.kind is CardWindowKind.Item || cw.kind is CardWindowKind.Beast || cw.kind is CardWindowKind.Info;
	}
	private void showCardLife(SelectionEvent se) { mixin(S_TRACE);
		auto cw = cast(CardWindow)_tlp;
		if (cw && !isMainCardWin(cw)) { mixin(S_TRACE);
			menuAction!(MenuID.ShowCardProp)(se);
		} else { mixin(S_TRACE);
			if (_castWin) _castWin.showCardLife();
			if (_skillWin) _skillWin.showCardLife();
			if (_itemWin) _itemWin.showCardLife();
			if (_beastWin) _beastWin.showCardLife();
			if (_infoWin) _infoWin.showCardLife();
			menuActionAfter(MenuID.ShowCardProp);
		}
	}
	private void showCardList(SelectionEvent se) { mixin(S_TRACE);
		auto cw = cast(CardWindow)_tlp;
		if (cw && !isMainCardWin(cw)) { mixin(S_TRACE);
			menuAction!(MenuID.ShowCardImage)(se);
		} else { mixin(S_TRACE);
			if (_castWin) _castWin.showCardList();
			if (_skillWin) _skillWin.showCardList();
			if (_itemWin) _itemWin.showCardList();
			if (_beastWin) _beastWin.showCardList();
			if (_infoWin) _infoWin.showCardList();
			menuActionAfter(MenuID.ShowCardImage);
		}
	}
	private void showCardTable(SelectionEvent se) { mixin(S_TRACE);
		auto cw = cast(CardWindow)_tlp;
		if (cw && !isMainCardWin(cw)) { mixin(S_TRACE);
			menuAction!(MenuID.ShowCardDetail)(se);
		} else { mixin(S_TRACE);
			if (_castWin) _castWin.showCardTable();
			if (_skillWin) _skillWin.showCardTable();
			if (_itemWin) _itemWin.showCardTable();
			if (_beastWin) _beastWin.showCardTable();
			if (_infoWin) _infoWin.showCardTable();
			menuActionAfter(MenuID.ShowCardDetail);
		}
	}
	private bool canNewCard() { return summary !is null; }
	private alias canNewCard canNewCast;
	private alias canNewCard canNewSkill;
	private alias canNewCard canNewItem;
	private alias canNewCard canNewInfo;
	private alias canNewCard canNewBeast;
	private void newCast() { mixin(NewCard!("Cast")); }
	private void newSkill() { mixin(NewCard!("Skill")); }
	private void newItem() { mixin(NewCard!("Item")); }
	private void newBeast() { mixin(NewCard!("Beast")); }
	private void newInfo() { mixin(NewCard!("Info")); }
	private void versionInfo() { mixin(S_TRACE);
		(new VersionDialog(_comm, _prop, _win)).open();
	}

	private HashSet!(MenuID) _noSummMenu;
	private MenuItem[MenuID] _menu;
	private ToolItem[MenuID] _tool;
	private class RadioGroupAndSet(T) {
		RadioGroup!T group = null;
		HashSet!MenuID menuIDs;
		alias group this;
		this () { mixin(S_TRACE);
			group = new RadioGroup!T;
			menuIDs = new HashSet!MenuID;
		}
	}
	private RadioGroupAndSet!MenuItem[] _menuRG;
	private RadioGroupAndSet!ToolItem[] _toolRG;
	private HashSet!(MenuID) _mainMenu;
	private ToolBar[] _toolBar;
	private TopLevelPanel _tlp = null;
	private template MenuAction(string M, MenuID Id, int Style = SWT.PUSH, string Act = "", string Can = "null") {
		static if (Act.length) {
			static const MenuAction = "_mainMenu.add(" ~ Id.stringof ~ ");"
				~ "_menu[" ~ Id.stringof ~ "] = createMenuItem(_comm, " ~ M ~ ", " ~ Id.stringof ~ ", &"
				~ Act ~ ", " ~ Can ~ ", " ~ to!string(Style) ~ ");";
		} else {
			static const MenuAction = "_menu[" ~ Id.stringof ~ "] = createMenuItem(_comm, " ~ M ~ ", " ~ Id.stringof ~ ", "
				~ "&menuAction!(" ~ Id.stringof ~ "), " ~ Can ~ ", " ~ to!string(Style) ~ ");";
		}
	}
	private template ToolAction(string T, MenuID Id, int Style = SWT.PUSH, string Act = "", string Can = "null") {
		static if (Act.length) {
			static const ToolAction = "_mainMenu.add(" ~ Id.stringof ~ ");"
				~ "_tool[" ~ Id.stringof ~ "] = createToolItem(_comm, " ~ T ~ ", " ~ Id.stringof ~ ", &"
				~ Act ~ ", " ~ Can ~ ", " ~ to!string(Style) ~ ");";
		} else {
			static const ToolAction = "_tool[" ~ Id.stringof ~ "] = createToolItem(_comm, " ~ T ~ ", " ~ Id.stringof ~ ", "
				~ "&menuAction!(" ~ Id.stringof ~ "), " ~ Can ~ ", " ~ to!string(Style) ~ ");";
		}
	}
	@property
	ToolBar[] toolBars() { return _toolBar; }
	void refreshToolBar(bool delegate()[MenuID] cMenuTbl) { mixin(S_TRACE);
		foreach (bar; _toolBar) { mixin(S_TRACE);
			foreach (itm; bar.getItems()) { mixin(S_TRACE);
				if (itm.getStyle() & SWT.SEPARATOR) continue;
				auto d = cast(MenuData)itm.getData();
				if (!d) continue;
				try { mixin(S_TRACE);
					auto cMenuE = d.id in cMenuTbl;
					if (cMenuE) { mixin(S_TRACE);
						itm.setEnabled((*cMenuE)());
					} else if (d.enabled) { mixin(S_TRACE);
						itm.setEnabled(d.enabled());
					} else if (_tlp) { mixin(S_TRACE);
						auto enabled = _tlp.menuEnabled(d.id);
						if (enabled) { mixin(S_TRACE);
							itm.setEnabled(enabled());
						} else if (!_mainMenu.contains(d.id)) { mixin(S_TRACE);
							itm.setEnabled(false);
						}
					}
				} catch (Throwable e) {
					printStackTrace();
					debugln(.text(d.id));
					debugln(e);
				}
			}
		}
	}
	private class MenuShown : MenuAdapter {
		override void menuShown(MenuEvent e) { mixin(S_TRACE);
			auto menu = cast(Menu)e.widget;
			foreach (itm; menu.getItems()) { mixin(S_TRACE);
				if (itm.getStyle() & SWT.SEPARATOR) continue;
				auto d = cast(MenuData)itm.getData();
				assert (d !is null);
				if (d.enabled) { mixin(S_TRACE);
					itm.setEnabled(d.enabled());
					continue;
				}
				if (!_tlp) continue;
				auto enabled = _tlp.menuEnabled(d.id);
				if (!enabled) continue;
				itm.setEnabled(enabled());
			}
		}
	}
	private void setupMenuListener(Menu menu) { mixin(S_TRACE);
		menu.addMenuListener(new MenuShown);
	}
	private void menuActionAfterImpl(T)(MenuID id, T[MenuID] tools, RadioGroupAndSet!T[] rg) { mixin(S_TRACE);
		auto p = id in tools;
		foreach (g; rg) { mixin(S_TRACE);
			if (p && g.contains(*p)) { mixin(S_TRACE);
				foreach (gb; g.set) { mixin(S_TRACE);
					gb.setSelection(gb is *p);
				}
			} else if (g.menuIDs.contains(id)) {
				// 選択されたアイテムがメニュー・ツールバー上に存在はしないが
				// 同一ラジオグループの他のアイテムが存在している場合
				foreach (gb; g.set) { mixin(S_TRACE);
					gb.setSelection(false);
				}
			}
		}
		if (p && _tlp && _tlp.menuChecked(id)) { mixin(S_TRACE);
			p.setSelection(_tlp.menuChecked(id)());
		}
	}
	private void menuAction(MenuID ID)(SelectionEvent se) { mixin(S_TRACE);
		menuActionDlg(ID)(se);
	}
	private void delegate(SelectionEvent) menuActionDlg(MenuID id) { mixin(S_TRACE);
		return (SelectionEvent se) { mixin(S_TRACE);
			if (!_tlp) return;
			scope (exit) menuActionAfter(id);
			if (_comm.lastFocusEditor) { mixin(S_TRACE);
				auto menu = _comm.lastFocusEditor.getMenu();
				if (menu) { mixin(S_TRACE);
					foreach (itm; menu.getItems()) { mixin(S_TRACE);
						auto d = cast(MenuData)itm.getData();
						if (d && d.id is id && (!d.enabled || d.enabled())) { mixin(S_TRACE);
							raiseEvent(itm, se);
							_comm.refreshToolBar();
							return;
						}
					}
				}
			}
			auto act = _tlp.menuAction(id);
			assert (act, .text(id) ~ " " ~ .text(_tlp));
			act(se);
		};
	}
	private void menuActionAfter(MenuID id) { mixin(S_TRACE);
		menuActionAfterImpl(id, _menu, _menuRG);
		menuActionAfterImpl(id, _tool, _toolRG);
	}

	private void setupMenu(M)(M[MenuID] menus) { mixin(S_TRACE);
		foreach (id, itm; menus) { mixin(S_TRACE);
			if (id is MenuID.ExecEngine) { mixin(S_TRACE);
				itm.setEnabled(canExecEngine || _prop.var.etc.classicEngines.length);
				continue;
			}
			if (id is MenuID.ExecEngineWithParty) { mixin(S_TRACE);
				itm.setEnabled(canExecEngineWithPartyMenu);
				continue;
			}
			if (id is MenuID.OuterTools) { mixin(S_TRACE);
				itm.setEnabled(_prop.var.etc.outerTools.length > 0);
				continue;
			}
			if (_tlp) { mixin(S_TRACE);
				auto s = itm.getStyle();
				if ((s & SWT.RADIO) || (s & SWT.CHECK)) { mixin(S_TRACE);
					auto chk = _tlp.menuChecked(id);
					if (chk) itm.setSelection(chk());
				}
			}
			if (!summary && !_noSummMenu.contains(id)) { mixin(S_TRACE);
				itm.setEnabled(false);
				continue;
			}
			if (_mainMenu.contains(id)) { mixin(S_TRACE);
				itm.setEnabled(true);
				continue;
			}
			itm.setEnabled(_tlp && _tlp.menuAction(id));
		}
	}
	private void dockSelect(string key) { mixin(S_TRACE);
		if (!_dock.control(key)) return;
		auto tlp = (cast(TLPData)_dock.control(key).getData()).tlp;
		assert (tlp, key);
		_tlp = tlp;
		statusLine = tlp.statusLine;
		setupMenu(_menu);
		setupMenu(_tool);
	}
	private void dockShellClosedEvent() { mixin(S_TRACE);
		auto d = _win.getDisplay();
		auto fc = d.getFocusControl();
		if (!fc) return;
		_tlp = getTopLevelPanel(fc);
		if (!_tlp) return;
		statusLine = _tlp.statusLine;
		setupMenu(_menu);
		setupMenu(_tool);
	}
	private bool dockCanMove(string ctrlKey, string dropPaneKey) { mixin(S_TRACE);
		if (!dropPaneKey.length) return true;
		bool iswa = std.string.startsWith(dropPaneKey, "work");
		if (std.string.startsWith(ctrlKey, "work")) { mixin(S_TRACE);
			return iswa;
		} else { mixin(S_TRACE);
			return !iswa;
		}
	}
	private bool dockCanVanish(DockingFolderCTC dock, string key) { mixin(S_TRACE);
		auto mainWorks = dock.findPane("work", false).length;
		if (_prop.var.etc.canVanishWorkAreaInMainWindow || !mainWorks) { mixin(S_TRACE);
			return !std.string.startsWith(key, "work") || dock.findPane("work", true).length > 1;
		} else { mixin(S_TRACE);
			if (dock.isSubWindowPane(key)) return true;
			return !std.string.startsWith(key, "work") || mainWorks > 1;
		}
	}
	private bool dockCanVanish(string key) { mixin(S_TRACE);
		return dockCanVanish(dock, key);
	}
	private bool dockCloseCtrl(string key) { mixin(S_TRACE);
		_tlp = null;
		setupMenu(_menu);
		setupMenu(_tool);
		statusLine = "";
		return true;
	}
	private void dockMovingShellEvent(string key) { mixin(S_TRACE);
		auto tlpData = cast(TLPData)dock.control(key).getData();
		if (!tlpData) return;
		if (auto ew = cast(EventWindow)tlpData.tlp) { mixin(S_TRACE);
			ew.movingShell();
		}
	}
	private void dockMoveShellEvent(Shell before, string key) { mixin(S_TRACE);
		auto tlpData = cast(TLPData)dock.control(key).getData();
		if (!tlpData) return;
		if (auto ew = cast(EventWindow)tlpData.tlp) { mixin(S_TRACE);
			ew.moveShell();
		}
	}
	private string dockNewPaneName(string ctrlKey, string basePane, Dir dir) { mixin(S_TRACE);
		if (std.string.startsWith(ctrlKey, "work")) { mixin(S_TRACE);
			return _dock.newPaneKey("work");
		} else if (std.string.startsWith(basePane, "work")) { mixin(S_TRACE);
			if (dir == Dir.E || dir == Dir.W) { mixin(S_TRACE);
				return _dock.newPaneKey("side");
			} else if (dir == Dir.N || dir == Dir.S) { mixin(S_TRACE);
				return _dock.newPaneKey("data");
			}
		}
		return "";
	}
	private bool dockFirstResize(string paneKey) { mixin(S_TRACE);
		return std.string.startsWith(paneKey, "work");
	}

	void setStatusLine(string status) { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		_comm.setStatusLine(_win, status);
	}

	@property
	override
	string title() { return _win.getText(); }
	@property
	override
	Image image() { return _win.getImage(); }
	@property
	override
	Composite shell() { return _win; }
	@property
	override
	void delegate(string) statusText() { return &_sbshl.statusLine; }
	@property
	DockingFolderCTC dock() { return _dock; }

	@property
	Summary summary() { return _tableWin.summary; }

	void reNumberingHands(A)(A[] arr) { mixin(S_TRACE);
		ulong newId = 1;
		foreach (a; arr) { mixin(S_TRACE);
			if (a.id != newId) { mixin(S_TRACE);
				a.id = newId;
				static if (is(A : Area)) {
					_comm.refArea.call(a);
				} else static if (is(A : Battle)) {
					_comm.refBattle.call(a);
				} else static if (is(A : Package)) {
					_comm.refPackage.call(a);
				} else static if (is(A : CastCard)) {
					_comm.refCast.call(a);
				} else static if (is(A : SkillCard)) {
					_comm.refSkill.call(a);
				} else static if (is(A : ItemCard)) {
					_comm.refItem.call(a);
				} else static if (is(A : BeastCard)) {
					_comm.refBeast.call(a);
				} else static if (is(A : InfoCard)) {
					_comm.refInfo.call(a);
				}
			}
			newId++;
		}
	}
	void reNumberingAll() { mixin(S_TRACE);
		if (!summary) return;
		auto dlg = new DWTMessageBox(_win, SWT.ICON_QUESTION | SWT.OK | SWT.CANCEL);
		dlg.setText(_prop.msgs.dlgTitQuestion);
		dlg.setMessage(_prop.msgs.reNumberingAll);
		if (SWT.OK == dlg.open()) { mixin(S_TRACE);
			_tableWin.reNumberingAll();
			_castWin.reNumberingAll();
			_skillWin.reNumberingAll();
			_itemWin.reNumberingAll();
			_beastWin.reNumberingAll();
			_infoWin.reNumberingAll();
			foreach (c; summary.casts) { mixin(S_TRACE);
				auto w = _comm.handCardWindowFrom(_prop, summary, c, false, false);
				if (w) { mixin(S_TRACE);
					w.reNumberingAll();
				} else { mixin(S_TRACE);
					reNumberingHands(c.skills);
					reNumberingHands(c.items);
					reNumberingHands(c.beasts);
				}
			}
		}
	}

	ReplaceDialog openReplWin() { mixin(S_TRACE);
		if (!_replDlg || _replDlg.widget.isDisposed()) { mixin(S_TRACE);
			_replDlg = new ReplaceDialog(_comm, _prop, _win, summary, &sendReloadPropsAndSave);
			_replDlg.open();
		} else { mixin(S_TRACE);
			_replDlg.widget.setMinimized(false);
			_replDlg.widget.setActive();
		}
		return _replDlg;
	}

	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		if (!summary) return false;
		if (!_win || _win.isDisposed()) return false;
		if (_win.isVisible()) _win.setRedraw(false);
		scope (exit) {
			if (_win.isVisible()) _win.setRedraw(true);
		}
		if (.cpempty(path)) return true;

		// 参照設定されているカードの場合があるので正規化する
		auto cwxPath = summary.findCWXPath(path);
		if (!cwxPath) { mixin(S_TRACE);
			auto cate = .cpcategory(path);
			auto etc = false;
			if (cate == "area:id" && .cpindex(path) == 0 && summary.areas) { mixin(S_TRACE);
				path = .cpjoin(summary.areas[$ - 1].cwxPath(true), .cpbottom(path));
			} else if (cate == "battle:id" && .cpindex(path) == 0 && summary.battles) { mixin(S_TRACE);
				path = .cpjoin(summary.battles[$ - 1].cwxPath(true), .cpbottom(path));
			} else if (cate == "package:id" && .cpindex(path) == 0 && summary.packages) { mixin(S_TRACE);
				path = .cpjoin(summary.packages[$ - 1].cwxPath(true), .cpbottom(path));
			} else if (cate == "castcard:id" && .cpindex(path) == 0 && summary.casts) { mixin(S_TRACE);
				path = .cpjoin(summary.casts[$ - 1].cwxPath(true), .cpbottom(path));
			} else if (cate == "skillcard:id" && .cpindex(path) == 0 && summary.skills) { mixin(S_TRACE);
				path = .cpjoin(summary.skills[$ - 1].cwxPath(true), .cpbottom(path));
			} else if (cate == "itemcard:id" && .cpindex(path) == 0 && summary.items) { mixin(S_TRACE);
				path = .cpjoin(summary.items[$ - 1].cwxPath(true), .cpbottom(path));
			} else if (cate == "beastcard:id" && .cpindex(path) == 0 && summary.beasts) { mixin(S_TRACE);
				path = .cpjoin(summary.beasts[$ - 1].cwxPath(true), .cpbottom(path));
			} else if (cate == "infocard:id" && .cpindex(path) == 0 && summary.infos) { mixin(S_TRACE);
				path = .cpjoin(summary.infos[$ - 1].cwxPath(true), .cpbottom(path));
			} else { mixin(S_TRACE);
				etc = true;
			}
			if (!etc) { mixin(S_TRACE);
				cwxPath = summary.findCWXPath(path);
				if (!cwxPath) return false;
				auto attrs = cpattr(path);
				path = cwxPath.cwxPath(true);
				foreach (attr; attrs) path = cpaddattr(path, attr);
			}
		}

		bool open() { mixin(S_TRACE);
			path = .toLower(path);
			if (cpempty(path)) { mixin(S_TRACE);
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					_tableWin.editSummary();
					return true;
				}
			}
			auto cate = cpcategory(path);
			switch (cate) {
			case "", "area", "battle", "package", "area:id", "battle:id", "package:id", "variable",
					"tableview", "variableview": { mixin(S_TRACE);
				if (cate == "variable" || cate == "variableview") { mixin(S_TRACE);
					return _flagWin.openCWXPath(path, shellActivate);
				} else { mixin(S_TRACE);
					return _tableWin.openCWXPath(path, shellActivate);
				}
			} case "castcard", "skillcard", "itemcard", "beastcard", "infocard",
					"castcard:id", "skillcard:id", "itemcard:id", "beastcard:id", "infocard:id",
					"castcardview", "skillcardview", "itemcardview", "beastcardview", "infocardview": { mixin(S_TRACE);
				assert (_castWin);
				assert (_skillWin);
				assert (_itemWin);
				assert (_beastWin);
				assert (_infoWin);
				switch (cate) {
				case "castcard", "castcard:id", "castcardview":
					_comm.openCastWin(shellActivate);
					return _castWin.openCWXPath(path, shellActivate);
				case "skillcard", "skillcard:id", "skillcardview":
					_comm.openSkillWin(shellActivate);
					return _skillWin.openCWXPath(path, shellActivate);
				case "itemcard", "itemcard:id", "itemcardview":
					_comm.openItemWin(shellActivate);
					return _itemWin.openCWXPath(path, shellActivate);
				case "beastcard", "beastcard:id", "beastcardview":
					_comm.openBeastWin(shellActivate);
					return _beastWin.openCWXPath(path, shellActivate);
				case "infocard", "infocard:id", "infocardview":
					_comm.openInfoWin(shellActivate);
					return _infoWin.openCWXPath(path, shellActivate);
				default:
					return false;
				}
			} case "fileview": { mixin(S_TRACE);
				if (_dirWin) { mixin(S_TRACE);
					return _dirWin.openCWXPath(path, shellActivate);
				}
				return false;
			} case "couponview": { mixin(S_TRACE);
				if (_couponWin) { mixin(S_TRACE);
					return _couponWin.openCWXPath(path, shellActivate);
				}
				return false;
			} case "gossipview": { mixin(S_TRACE);
				if (_couponWin) { mixin(S_TRACE);
					return _gossipWin.openCWXPath(path, shellActivate);
				}
				return false;
			} case "completestampview": { mixin(S_TRACE);
				if (_completeStampWin) { mixin(S_TRACE);
					return _completeStampWin.openCWXPath(path, shellActivate);
				}
				return false;
			} case "keycodeview": { mixin(S_TRACE);
				if (_keyCodeWin) { mixin(S_TRACE);
					return _keyCodeWin.openCWXPath(path, shellActivate);
				}
				return false;
			} case "cellnameview": { mixin(S_TRACE);
				if (_cellNameWin) { mixin(S_TRACE);
					return _cellNameWin.openCWXPath(path, shellActivate);
				}
				return false;
			} case "cardgroupview": { mixin(S_TRACE);
				if (_cardGroupWin) { mixin(S_TRACE);
					return _cardGroupWin.openCWXPath(path, shellActivate);
				}
				return false;
			} default:
				return false;
			}
		}
		bool r = true;
		string[] paths;
		if (path.length) { mixin(S_TRACE);
			paths = std.string.split(path, CWXPATH_SEP.idup);
		} else { mixin(S_TRACE);
			paths = [path];
		}
		foreach (p; paths) { mixin(S_TRACE);
			if (open()) { mixin(S_TRACE);
				_win.setMinimized(false);
				if (shellActivate) _win.forceActive();
			} else { mixin(S_TRACE);
				r = false;
			}
		}
		return r;
	}
	@property
	override
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		foreach (paneKey; _dock.paneKeys) { mixin(S_TRACE);
			foreach (ctrl; _dock.controls(paneKey)) { mixin(S_TRACE);
				auto tlpData = cast(TLPData) ctrl.getData();
				if (tlpData.tlp is this) continue;
				assert (tlpData);
				foreach (cwxPath; tlpData.tlp.openedCWXPath) {
					r ~= cpaddattr(cwxPath, "nofocus");
				}
			}
			// ペイン内で選択中のタブを末尾に追加
			string ctrlKey = _dock.selectedCtrl(paneKey);
			if ("" != ctrlKey) { mixin(S_TRACE);
				auto ctrl = _dock.control(ctrlKey);
				assert (ctrl);
				auto tlpData = cast(TLPData) ctrl.getData();
				assert (tlpData);
				if (tlpData.tlp !is this) { mixin(S_TRACE);
					r ~= tlpData.tlp.openedCWXPath;
				}
			}
		}
		// 現在フォーカスのあるコントロールを末尾に追加
		auto d = _win.getDisplay();
		auto fc = d.getFocusControl();
		while (fc) { mixin(S_TRACE);
			auto tlpData = cast(TLPData) fc.getData();
			if (tlpData && tlpData.tlp !is this) { mixin(S_TRACE);
				r ~= tlpData.tlp.openedCWXPath;
				break;
			}
			fc = fc.getParent();
		}
		return array(uniq(r));
	}

	void doCWX() { mixin(S_TRACE);
		if (!_win) return;
		string dStr = .text(__LINE__);
		try { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Start Main Thread");
			}
			auto d = _win.getDisplay();
			_win.open();
			dStr ~= " - " ~ .text(__LINE__);
			if (_opt.create) { mixin(S_TRACE);
				auto name = _opt.createName is null ? _prop.var.etc.newScenarioName : _opt.createName;
				auto skinType = _opt.createSkinType is null ? _prop.var.etc.defaultSkin : _opt.createSkinType;
				auto skinName = _opt.createSkinName is null ? _prop.var.etc.defaultSkinName : _opt.createSkinName;
				auto skin = .findSkin2(_prop, skinType, skinName);
				auto summ = Summary.createScenario(_prop.parent, _prop.tempPath, name,
					skin, _prop.var.etc.newAreaName != "",
					_prop.var.etc.newAreaName, _prop.bgImagesDefault(skin.type), _prop.var.etc.saveSkinName, _sync);
				summ.author = _prop.var.etc.defaultAuthor;
				openScenario(summ, []);
				statusLine = "";
			} else if (_opt.createclassic) { mixin(S_TRACE);
				string name = _opt.createName is null ? _prop.var.etc.newScenarioName : _opt.createName;
				if (_opt.createclassicPath is null || !_opt.createclassicPath.length) { mixin(S_TRACE);
					_opt.createclassicPath = CreateScenarioDialog.createClassicDir(_prop, _win);
				}
				if (_opt.createclassicPath !is null && _opt.createclassicPath.length) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						if (!.exists(_opt.createclassicPath)) { mixin(S_TRACE);
							mkdirRecurse(_opt.createclassicPath);
						}
						auto summ = new Summary(name, "", "", _opt.createclassicPath, false, true);
						summ.author = _prop.var.etc.defaultAuthor;
						Summary.createStartArea(summ , _prop.parent, _prop.var.etc.newAreaName != "", _prop.var.etc.newAreaName, _prop.bgImagesDefault(_prop.var.etc.defaultSkin), null, _prop.enginePath,
							_prop.var.etc.classicEngineRegex, _prop.var.etc.classicDataDirRegex, _prop.var.etc.classicMatchKey,
							_prop.var.etc.classicEngines, _prop.var.etc.defaultSkin);
						{ mixin(S_TRACE);
							_saveSync.lock();
							scope (exit) _saveSync.unlock();
							summ.saveOverwrite(_prop.parent, findSkin(_comm, _prop, summ), createSaveOpt(summ.legacy, true), _sync);
						}
						openScenario(summ, []);
						statusLine = "";
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
					}
				}
			} else if (_opt.scenario) { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				openScenario(_opt.scenario, &resetOpt);
			} else if (_prop.var.etc.openLastScenario && _prop.var.etc.lastScenario.length) { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				openScenario(_prop.var.etc.lastScenario, &resetOpt);
			}
			dStr ~= " - " ~ .text(__LINE__);

			_pipeName = createPipeName();
			auto pipe = new core.thread.Thread(&pipeThr);
			if (_pipeName.length) { mixin(S_TRACE);
				pipe.start();
			}
			auto sendPipeThr = new core.thread.Thread(&this.sendPipeThr);
			sendPipeThr.start();
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
						WriteFile(p, pmsg.ptr, cast(DWORD)pmsg.length, &len, null);
					}
				}
			} else { mixin(S_TRACE);
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
				cwriteln(.format("Starting time: %d msecs", initTimer.peek().total!"msecs"));
			}
			version (Windows) {
				size_t minimumHandleCount = 1024;
				auto handleCountLast = MonoTime.currTime();
			}
			while (!_win.isDisposed()) {
				version (nocatch) {
					if (d.readAndDispatch()) {
						_catchedChanging = false;
						version (Windows) {
							_comm.stopOpen = false;
						}
					} else {
						d.sleep();
					}
				} else {
					// なるべくユーザデータを消さないよう、例外が発生しても処理を続行する。
					try {
						if (d.readAndDispatch()) {
							_catchedChanging = false;
							version (Windows) {
								_comm.stopOpen = false;
							}
						} else {
							d.sleep();
						}
					} catch (Throwable e) {
						if (!openErrDlg) {
							// 際限の無い連続発生を抑制
							string s = printStackTrace();
							openErrDlg = true;
							_win.setVisible(true);
							fdebugln(e);
							s ~= "\n--------\n" ~ createDebugln(e);
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
				version (Windows) {
					// DのGCが実行されるまで各種ハンドルが開放されない問題を回避するため、
					// 数秒に一回ハンドル数を取得し、多すぎるようならGCを実行するようにする。
					import core.sys.windows.windows;
					auto handleCountCur = MonoTime.currTime();
					if (handleCountCur < handleCountLast || (handleCountLast + .dur!"seconds"(8)) <= handleCountCur) { mixin(S_TRACE);
						handleCountLast = handleCountCur;
						DWORD hCount;
						if (GetProcessHandleCount(GetCurrentProcess(), &hCount)) { mixin(S_TRACE);
							if (minimumHandleCount < hCount) { mixin(S_TRACE);
								cdebugln("Cleaning handles.");
								core.memory.GC.collect();
								if (GetProcessHandleCount(GetCurrentProcess(), &hCount)) { mixin(S_TRACE);
									if (minimumHandleCount <= hCount) {
										minimumHandleCount = cast(size_t)(hCount * 1.2);
										cdebugln("Updated minimum handle count: %s".format(minimumHandleCount));
									}
								}
							}
							if (0 < _prop.var.etc.warningWindowsHandleCount && _prop.var.etc.liftWarningWindowsHandleCount <= _prop.var.etc.warningWindowsHandleCount) { mixin(S_TRACE);
								if (_prop.var.etc.warningWindowsHandleCount < hCount && !_comm.warningHandleCount) { mixin(S_TRACE);
									_comm.warningHandleCount = true;
								} else if (hCount <= _prop.var.etc.liftWarningWindowsHandleCount && _comm.warningHandleCount) {mixin(S_TRACE);
									_comm.warningHandleCount = false;
								}
							}
						}
					}
				}
			}
			// 各要素が絡み合うため、必ずこの順序で各スレッドとリソースを解放する
			_quit = true;
			dStr ~= " - " ~ .text(__LINE__);
			backup.join(false);
			version (Console) {
				debug writeln("Joined Backup Thread");
			}
			dStr ~= " - " ~ .text(__LINE__);
			_dirWin.quitTrace();
			version (Console) {
				debug writeln("Joined Trace Thread");
			}
			dStr ~= " - " ~ .text(__LINE__);
			_comm.dispose();
			dStr ~= " - " ~ .text(__LINE__);
			_prop.images.disposeImages();
			dStr ~= " - " ~ .text(__LINE__);
			version (Console) {
				debug writeln("Disposed Resources");
			}
			synchronized (_displayMutex) { mixin(S_TRACE);
				_display = null;
				try { mixin(S_TRACE);
					d.dispose();
				} catch (ErrnoException e) {
					// コンソールが無い時にDwtLoggerが標準出力に出力しようとして
					// Bad file descriptorと言われる事がある
					version (Console) {
						printStackTrace();
						debugln(e);
					}
				}
			}
			version (Console) {
				debug writeln("Disposed Display");
			}
			dStr ~= " - " ~ .text(__LINE__);
			_prop.var.save(dock);
			dStr ~= " - " ~ .text(__LINE__);
			_sync.quit();
			dStr ~= " - " ~ .text(__LINE__);
			sendReloadProps();
			dStr ~= " - " ~ .text(__LINE__);
			_sendPipeThrQuit = true;
			sendPipeThr.join(false);
			version (Console) {
				debug writeln("Joined Sender Pipe Thread");
			}
			version (Console) {
				debug writeln("Saved Settings");
			}
			_prop.var.cleanup();
			version (Console) {
				version (Win64) {
					debug writeln("Exit Main Thread");
				} else {
					debug writefln("d2std.zlib.allocCount: %s", d2std.zlib.allocCount);
					debug writeln("Exit Main Thread");
				}
			}
		} catch (Throwable e) {
			// 起動・終了失敗
			printStackTrace();
			fdebugln(dStr);
			fdebugln(e);
			throw e;
		}
	}
}

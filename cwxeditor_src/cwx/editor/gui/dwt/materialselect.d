
module cwx.editor.gui.dwt.materialselect;

import cwx.cwl;
import cwx.utils;
import cwx.summary;
import cwx.skin;
import cwx.menu;
import cwx.types;
import cwx.imagesize;

import cwx.editor.gui.sound;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.timebar;

import core.thread;

import std.array;
import std.file;
import std.path;
import std.string;
import std.conv;
import std.datetime;
import std.exception;

import org.eclipse.swt.all;

import java.lang.all : Runnable;

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
	/// イメージ格納時に呼び出される。
	void delegate(string file)[] includeEvent;
public:
	this (Commons comm, Props prop, Summary summ, bool readOnly, void delegate() refresh, string[] defs, int including = -1, bool canInclude = false, bool isMenuCard = false) { mixin(S_TRACE);
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_comm = comm;
		_prop = prop;
		_summ = summ;
		if (_readOnly) _summSkin = findSkin(_comm, _prop, _summ);
		_refresh = refresh;
		_defs = defs;
		_including = including;
		_canInclude = canInclude;
		_isMenuCard = isMenuCard;
	}
	@property
	const
	bool canInclude() { return _canInclude; }
	@property
	const
	bool isMenuCard() { return _isMenuCard; }

	D createDirsCombo(Composite parent) { mixin(S_TRACE);
		static if (is (D == Combo)) {
			_dirs = new D(parent, SWT.BORDER | SWT.READ_ONLY | SWT.DROP_DOWN);
			_dirs.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		} else static if (is (D == CCombo)) {
			_dirs = new D(parent, SWT.BORDER | SWT.READ_ONLY);
			_dirs.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!D(_comm, _prop, _dirs, null);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_dirs.setEnabled(!_readOnly);
		_dirs.addSelectionListener(new CSListener);

		_comm.refSkin.add(&refresh);
		_comm.refDataVersion.add(&refreshFileListMenu);
		_comm.refPaths.add(&refPaths);
		_comm.refPath.add(&refPath);
		_comm.delPaths.add(&delPaths);
		_comm.replPath.add(&replPath);
		_comm.refIgnorePaths.add(&refresh);
		static if (Type == MtType.BGM) {
			if (!_display) _display = parent.getDisplay();
			stopBGMEvent ~= &stopBGM;
		}
		_dirs.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				_comm.refSkin.remove(&refresh);
				_comm.refDataVersion.remove(&refreshFileListMenu);
				_comm.refPaths.remove(&refPaths);
				_comm.refPath.remove(&refPath);
				_comm.delPaths.remove(&delPaths);
				_comm.replPath.remove(&replPath);
				_comm.refIgnorePaths.remove(&refresh);
				static if (Type == MtType.BGM) {
					cwx.utils.remove(stopBGMEvent, &stopBGM);
				}
			}
		});
		auto menu = new Menu(_dirs.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &startIncSearch, () => !_readOnly);
		_dirs.setMenu(menu);
		return _dirs;
	}
	static if (Type == MtType.BGM) {
		private bool _startPlay = false;
		private void stopBGM() { mixin(S_TRACE);
			if (_startPlay) return;
			_display.asyncExec(new class Runnable {
				override void run() { mixin(S_TRACE);
					if (_playing) { mixin(S_TRACE);
						bgmStopped();
					}
				}
			});
		}
	}
	C createFileList(Composite parent) { mixin(S_TRACE);
		static if (is (C == Table)) {
			_fileList = new C(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE | SWT.FULL_SELECTION | SWT.VIRTUAL);
			new FullTableColumn(_fileList, SWT.NONE);
		} else static if (is (C == Combo)) {
			_fileList = new C(parent, SWT.BORDER | SWT.READ_ONLY | SWT.DROP_DOWN);
			_fileList.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		} else static if (is (C == CCombo)) {
			_fileList = new C(parent, SWT.BORDER | SWT.READ_ONLY);
			_fileList.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!CCombo(_comm, _prop, _fileList, null);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_fileList.setEnabled(!_readOnly);
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
			} else { mixin(S_TRACE);
				auto open = new OpenMaterial;
				_fileList.addMouseListener(open);
				_fileList.addKeyListener(open);
			}
		}
		refreshFileListMenu();
		new class(_fileList) FileDropTarget {
			this(Control c) { mixin(S_TRACE);
				super(c);
			}
		protected override:
			bool canDrop() {return _summ !is null && !_readOnly;}
			string[] doAll(string[] files) { mixin(S_TRACE);
				assert (_summ !is null);
				string[] r;
				foreach (f; files) { mixin(S_TRACE);
					if (isTarg(f) && !hasPath(_summ.scenarioPath, f)) { mixin(S_TRACE);
						r ~= f;
					}
				}
				if (r.length > 0) { mixin(S_TRACE);
					auto dlg = new MessageBox(control.getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO);
					if (1 == r.length) { mixin(S_TRACE);
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropFile, r[0]));
					} else { mixin(S_TRACE);
						dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropFiles, r.length));
					}
					dlg.setText(_prop.msgs.dlgTitDropFiles);
					if (SWT.YES == dlg.open()) { mixin(S_TRACE);
						return r;
					}
				}
				return [];
			}
			bool doFile(string path, int x, int y) { mixin(S_TRACE);
				assert (_summ !is null);
				auto cur = currentDir;
				if (!cur) cur = summSkin.materialPath;
				copyTo(_summ.scenarioPath, path, cur, false);
				return true;
			}
			void doExit() { mixin(S_TRACE);
				assert (_summ !is null);
				auto cur = currentDir;
				if (!cur) cur = summSkin.materialPath;
				refreshPaths(summSkin.materialPath);
				_comm.refPaths.call(this.outer, summSkin.materialPath);
			}
		};
		_incSearch = new IncSearch(_comm, parent);
		_incSearch.modEvent ~= { mixin(S_TRACE);
			refreshList();
		};
		return _fileList;
	}
	private void refreshFileListMenu() { mixin(S_TRACE);
		if (!_fileList) return;
		auto menu = new Menu(_fileList.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &startIncSearch, () => !_readOnly);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.OpenAtFileView, &openFilePath, () => filePath.length > 0 && !_readOnly);
		createMenuItem(_comm, menu, MenuID.CopyFilePath, &copyFilePath, () => filePath.length > 0);
		static if (Type == MtType.CARD) {
			if (!_readOnly && _canInclude && _summ && _summ.legacy) { mixin(S_TRACE);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.IncludeImage, &includeImage, () => filePath.length > 0 && !_readOnly);
			}
		} else static if (Type == MtType.BGM) {
			new MenuItem(menu, SWT.SEPARATOR);
			_bgmMenu = createMenuItem(_comm, menu, MenuID.PlayBGM, () => playBGM(false), &canPlay);
			auto data = cast(MenuData) _bgmMenu.getData();
			data.format = (string t) {return data.id is MenuID.StopBGM ? .tryFormat(t, _playing) : t;};
		} else static if (Type == MtType.SE) {
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.PlaySE, &playSE, &canPlay);
			createMenuItem(_comm, menu, MenuID.StopSE, &stopSE, null);
		}
		_fileList.setMenu(menu);
	}
	static if (Type == MtType.CARD) {
		@property
		void useNoCardSizeImage(bool noCardSize) { mixin(S_TRACE);
			if (_noCardSize == noCardSize) return;
			_noCardSize = noCardSize;
			if (!_noCardSize && !isBinImg(filePath)) { mixin(S_TRACE);
				auto p = summSkin.findImagePath(path, _summ ? _summ.scenarioPath : "");
				if (p.length) { mixin(S_TRACE);
					uint w, h;
					imageSize(p, w, h);
					auto cs = _prop.looks.cardSize;
					if (cs.width != w || cs.height != h) { mixin(S_TRACE);
						path = "";
					}
				}
			}
			refresh();
		}
		@property
		const
		bool useNoCardSizeImage() { mixin(S_TRACE);
			return _noCardSize;
		}
		private void includeImage() { mixin(S_TRACE);
			if (!_canInclude) return;
			string file = filePath;
			if (!file.length) return;
			auto dlg = new MessageBox(_fileList.getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO);
			dlg.setText(_prop.msgs.dlgTitQuestion);
			dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgIncludeImage, this.path));
			if (SWT.YES == dlg.open()) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					if (!file.exists()) return;
					ubyte* ptr = null;
					_binPath = bImgToStr(readBinaryFrom!ubyte(file, ptr));
					scope (exit) freeAll(ptr);
					refreshDefs();
					selectDir(_including);
					foreach (d; includeEvent) { mixin(S_TRACE);
						d(file);
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		@property
		uint pcNumber() { mixin(S_TRACE);
			if (!_isMenuCard || !_summ) return 0;
			auto sel = _dirs.getSelectionIndex();
			if (0 <= _including) { mixin(S_TRACE);
				sel--;
			}
			if (0 < sel && sel <= _prop.var.etc.partyMax) { mixin(S_TRACE);
				return sel;
			}
			return 0;
		}
		@property
		void pcNumber(uint pcNum) { mixin(S_TRACE);
			if (0 == pcNum) return;
			if (!_isMenuCard || !_summ) return;
			uint num = pcNum;
			if (0 <= _including) { mixin(S_TRACE);
				num++;
			}
			_dirs.select(num);
		}
	}
	private void refreshDefs() { mixin(S_TRACE);
		if (!_canInclude) { mixin(S_TRACE);
			refreshPaths();
			return;
		}
		string[] defs = [_prop.msgs.defaultSelection(_prop.msgs.imageNone)];
		int including = _including;
		static if (Type == MtType.CARD) {
			uint pcNum = pcNumber;
		}
		if (isBinImg(_binPath)) { mixin(S_TRACE);
			including = cast(int)defs.length;
			defs ~= _prop.msgs.defaultSelection(_prop.msgs.imageIncluding);
		}
		static if (Type == MtType.CARD) {
			if (_isMenuCard && _summ) { mixin(S_TRACE);
				foreach (num; 0 .. _prop.var.etc.partyMax) { mixin(S_TRACE);
					defs ~= _prop.msgs.defaultSelection(.tryFormat(_prop.msgs.pcNumber, num + 1));
				}
				if (pcNum <= 0 || _prop.var.etc.partyMax < pcNum) { mixin(S_TRACE);
					pcNum = 0;
				}
			} else { mixin(S_TRACE);
				pcNum = 0;
			}
		}
		if (defs != _defs) { mixin(S_TRACE);
			_defs = defs;
			_including = including;
			static if (Type == MtType.CARD) {
				pcNumber = pcNum;
			}
		}
		refreshPaths();
	}
	static if (Type == MtType.BGM || Type == MtType.SE) {
		private Button _bgmBtn = null;

		private Spinner _volume = null;
		private Spinner _loopCount = null;

		@property
		string[] warnings() {
			string[] r;
			if (_volume && _volume.getSelection() != 100 && _summ && !_summ.isTargetVersion("1")) { mixin(S_TRACE);
				r ~= _prop.msgs.warningVolume;
			}
			auto loops = (Type == MtType.BGM) ? 0 : 1;
			if (_loopCount && _loopCount.getSelection() != loops && _summ && !_summ.isTargetVersion("1")) { mixin(S_TRACE);
				r ~= _prop.msgs.warningLoopCount;
			}
			return r;
		}

		Composite createPlayingOptions(Composite parent, bool tableLayout = false) { mixin(S_TRACE);
			auto comp = new Composite(parent, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(2, false));

			void createVolume(Composite parent) { mixin(S_TRACE);
				auto volume = this.volume;
				_volume = new Spinner(parent, SWT.BORDER);
				initSpinner(_volume);
				_volume.setMaximum(100);
				_volume.setMinimum(0);
				_volume.setSelection(volume);
				.listener(_volume, SWT.Selection, { mixin(S_TRACE);
					if (volume != this.volume) { mixin(S_TRACE);
						volume = this.volume;
						if (_refresh) _refresh();
						foreach (dlg; modEvent) dlg();
					}
				});
			}
			void createLoopCount(Composite parent) { mixin(S_TRACE);
				auto loopCount = this.loopCount;
				_loopCount = new Spinner(parent, SWT.BORDER);
				initSpinner(_loopCount);
				_loopCount.setMaximum(_prop.var.etc.loopCountMax);
				_loopCount.setMinimum(0);
				_loopCount.setSelection(loopCount);
				.listener(_loopCount, SWT.Selection, { mixin(S_TRACE);
					if (loopCount != this.loopCount) { mixin(S_TRACE);
						loopCount = this.loopCount;
						if (_refresh) _refresh();
						foreach (dlg; modEvent) dlg();
					}
				});
			}

			if (tableLayout) { mixin(S_TRACE);
				auto grp1 = new Group(comp, SWT.NONE);
				grp1.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp1.setText(_prop.msgs.playingVolume);
				grp1.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
				auto grp1comp = new Composite(grp1, SWT.NONE);
				grp1comp.setLayout(windowGridLayout(2, false));
				createVolume(grp1comp);
				auto l2 = new Label(grp1comp, SWT.NONE);
				l2.setText(_prop.msgs.playingVolumePer);

				auto grp2 = new Group(comp, SWT.NONE);
				grp2.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp2.setText(_prop.msgs.loopCount);
				grp2.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
				auto grp2comp = new Composite(grp2, SWT.NONE);
				grp2comp.setLayout(windowGridLayout(2, false));
				createLoopCount(grp2comp);
				auto l4 = new Label(grp2comp, SWT.NONE);
				l4.setText(_prop.msgs.loopCountHint);
			} else { mixin(S_TRACE);
				auto comp2 = new Composite(comp, SWT.NONE);
				auto wgd1 = windowGridLayout(3, false);
				wgd1.marginWidth = 0;
				wgd1.marginHeight = 0;
				comp2.setLayout(wgd1);
				auto l1 = new Label(comp2, SWT.NONE);
				l1.setText(_prop.msgs.playingVolume ~ ":");
				createVolume(comp2);
				auto l2 = new Label(comp2, SWT.NONE);
				l2.setText(_prop.msgs.playingVolumePer);

				auto comp3 = new Composite(comp, SWT.NONE);
				auto wgd2 = windowGridLayout(3, false);
				wgd2.marginWidth = 0;
				wgd2.marginHeight = 0;
				comp3.setLayout(wgd2);
				auto l3 = new Label(comp3, SWT.NONE);
				l3.setText(_prop.msgs.loopCount ~ ":");
				createLoopCount(comp3);
				auto l4 = new Label(comp3, SWT.NONE);
				l4.setText(_prop.msgs.loopCountHint);
			}
			_comm.refDataVersion.add(&refDataVersion);
			.listener(parent, SWT.Dispose, { mixin(S_TRACE);
				_comm.refDataVersion.remove(&refDataVersion);
			});
			refDataVersion();

			return comp;
		}
		private void refDataVersion() { mixin(S_TRACE);
			_volume.setEnabled(!_summ.legacy);
			_loopCount.setEnabled(!_summ.legacy);
		}
		@property
		int volume() { return _volume ? _volume.getSelection() : 100; }
		@property
		void volume(int volume) { mixin(S_TRACE);
			.enforce(_volume);
			_volume.setSelection(volume);
		}
		@property
		int loopCount() { mixin(S_TRACE);
			static if (Type == MtType.BGM) { mixin(S_TRACE);
				return _loopCount ? _loopCount.getSelection() : 0;
			} else static if (Type == MtType.SE) { mixin(S_TRACE);
				return _loopCount ? _loopCount.getSelection() : 1;
			} else static assert (0);
		}
		@property
		void loopCount(int loopCount) { mixin(S_TRACE);
			.enforce(_loopCount);
			_loopCount.setSelection(loopCount);
		}
	}
	static if (Type == MtType.BGM) {
		private MenuItem _bgmMenu = null;
		private ToolItem _bgmTMenu = null;
		string _playing = null;
		private TimeBar _playBar = null;
		private core.thread.Thread _playThr = null;
		private UpdatePlayBar _updatePlayBar = null;
		private Display _display = null;
		TimeBar createPlayingBar(Composite parent) { mixin(S_TRACE);
			_playBar = new TimeBar(parent, SWT.NONE);
			initPlayBar();
			.listener(_playBar, SWT.Dispose, { mixin(S_TRACE);
				if (_playThr) { mixin(S_TRACE);
					_playing = null;
					_playThr.join();
					_playThr = null;
				}
			});
			_playBar.updateCurrentEvent ~= { mixin(S_TRACE);
				if (!_updatePlayBar) return;
				auto pos = _playBar.current.total!"seconds";
				.bgmPos = pos * 1000;
				_updatePlayBar.putPos(pos);
			};
			return _playBar;
		}
		private void initPlayBar() { mixin(S_TRACE);
			if (!_playBar) return;
			_playBar.current = dur!"msecs"(0);
			_playBar.length = dur!"msecs"(0);
			_playBar.clearWarning();
			_playBar.setEnabled(false);
		}
		void createPlayToolItem(ToolBar bar) { mixin(S_TRACE);
			_bgmTMenu = createToolItem(_comm, bar, MenuID.PlayBGM, () => playBGM(false), &canPlay, SWT.CHECK);
			auto data = cast(MenuData) _bgmTMenu.getData();
			data.format = (string t) {return data.id is MenuID.StopBGM ? .tryFormat(t, _playing) : t;};
		}
		Button createPlayButton(Composite parent) { mixin(S_TRACE);
			_bgmBtn = new Button(parent, SWT.TOGGLE);
			_bgmBtn.setLayoutData(new GridData);
			_bgmBtn.setToolTipText(_prop.msgs.menuText(MenuID.PlayBGM));
			_bgmBtn.setImage(_prop.images.menu(MenuID.PlayBGM));
			auto pbgm = new Play;
			_bgmBtn.addSelectionListener(pbgm);
			_comm.put(_bgmBtn, &canPlay);
			return _bgmBtn;
		}
		@property
		bool canPlay() { mixin(S_TRACE);
			return _playing ? true : filePath.length > 0;
		}
		void playBGM(bool fromEvent) { mixin(S_TRACE);
			string p = filePath;
			if (p.length > 0 && (!_playing || !cfnmatch(nabs(p), nabs(_playing)))) { mixin(S_TRACE);
				_startPlay = true;
				scope (exit) _startPlay = false;
				auto volume = _volume ? _volume.getSelection() : 100;
				auto loopCount = _loopCount ? _loopCount.getSelection() : 0;
				bool inPlay = playBGMCW(_prop, p, volume, loopCount, _comm.skin.legacy);
				if (inPlay) { mixin(S_TRACE);
					_playing = p;
					auto relPath = .encodePath(this.path);
					if (_bgmMenu) { mixin(S_TRACE);
						_bgmMenu.setText(.tryFormat(_prop.buildMenu(MenuID.StopBGM), .baseName(relPath)));
						auto d = cast(MenuData) _bgmMenu.getData();
						d.id = MenuID.StopBGM;
						_bgmMenu.setImage(_prop.images.menu(MenuID.StopBGM));
						_bgmMenu.setSelection(true);
					}
					if (_bgmTMenu) { mixin(S_TRACE);
						_bgmTMenu.setToolTipText(.tryFormat(_prop.msgs.menuText(MenuID.StopBGM), relPath));
						_bgmTMenu.setImage(_prop.images.menu(MenuID.StopBGM));
						_bgmTMenu.setSelection(true);
					}
					if (_bgmBtn) { mixin(S_TRACE);
						_bgmBtn.setToolTipText(.tryFormat(_prop.msgs.menuText(MenuID.StopBGM), relPath));
						_bgmBtn.setImage(_prop.images.menu(MenuID.StopBGM));
						_bgmBtn.setSelection(true);
					}
					if (_playBar) { mixin(S_TRACE);
						if (!_updatePlayBar) { mixin(S_TRACE);
							_updatePlayBar = new UpdatePlayBar;
						}
						if (!_display) { mixin(S_TRACE);
							_display = _playBar.getDisplay();
						}
						_updatePlayBar.len = cast(int)(.bgmLen / 1000.0);
						if (_updatePlayBar.len <= 0) { mixin(S_TRACE);
							_playBar.setWarning(_prop.images.warning, _prop.msgs.canNotGetMusicLength);
						} else { mixin(S_TRACE);
							_playBar.clearWarning();
							_playBar.length = dur!"seconds"(_updatePlayBar.len);
							_playBar.current = dur!"seconds"(cast(int)(.bgmPos / 1000.0));
							_playBar.setEnabled(true);
						}
					}
					_playThr = new core.thread.Thread(&playThr);
					_playThr.start();
					return;
				}
			}
			if (!fromEvent) .stopBGM();
		}
		private void bgmStopped() { mixin(S_TRACE);
			if (!_playing) return;
			if (_bgmMenu) { mixin(S_TRACE);
				_bgmMenu.setText(_prop.buildMenu(MenuID.PlayBGM));
				auto d = cast(MenuData) _bgmMenu.getData();
				d.id = MenuID.PlayBGM;
				_bgmMenu.setImage(_prop.images.menu(MenuID.PlayBGM));
				_bgmMenu.setSelection(false);
			}
			if (_bgmTMenu) { mixin(S_TRACE);
				_bgmTMenu.setToolTipText(_prop.msgs.menuText(MenuID.PlayBGM));
				_bgmTMenu.setImage(_prop.images.menu(MenuID.PlayBGM));
				_bgmTMenu.setSelection(false);
			}
			if (_bgmBtn) { mixin(S_TRACE);
				_bgmBtn.setToolTipText(_prop.msgs.menuText(MenuID.PlayBGM));
				_bgmBtn.setImage(_prop.images.menu(MenuID.PlayBGM));
				_bgmBtn.setSelection(false);
			}
			_playing = null;
			if (_playThr) { mixin(S_TRACE);
				_playThr.join();
				_playThr = null;
			}
			initPlayBar();
		}
		private class Play : SelectionAdapter, KeyListener, MouseListener {
			override void mouseUp(MouseEvent e) {}
			override void mouseDown(MouseEvent e) {}
			override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
				if (e.button == 1) { mixin(S_TRACE);
					playBGM(false);
				}
			}
			override void keyReleased(KeyEvent e) {}
			override void keyPressed(KeyEvent e) { mixin(S_TRACE);
				if (e.character == SWT.CR) { mixin(S_TRACE);
					playBGM(false);
				}
			}
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				playBGM(false);
			}
		}
		private void playThr() { mixin(S_TRACE);
			SysTime last = SysTime.min;
			bool playing = true;
			auto isPlaying = new class Runnable {
				override void run() { mixin(S_TRACE);
					playing = .isBGMPlaying;
				}
			};
			while (_playing && playing) { mixin(S_TRACE);
				_display.asyncExec(isPlaying);
				auto cur = Clock.currTime();
				if (cur < last || (last + dur!"msecs"(100)) <= cur) { mixin(S_TRACE);
					last = cur;
					_display.asyncExec(_updatePlayBar);
				}
				core.thread.Thread.sleep(dur!"msecs"(16));
			}
			stopBGM();
		}
		private class UpdatePlayBar : Runnable {
			int len = 0;
			override void run() { mixin(S_TRACE);
				if (_display.isDisposed()) return;
				auto pos = cast(int)(.bgmPos / 1000.0);
				putPos(pos);
			}
			void putPos(long pos) { mixin(S_TRACE);
				if (_playBar && !_playBar.isDisposed()) { mixin(S_TRACE);
					_playBar.current = dur!"seconds"(pos);
				}
			}
		}
	} else static if (Type == MtType.SE) {
		void createPlayToolItem(ToolBar bar) { mixin(S_TRACE);
			createToolItem(_comm, bar, MenuID.PlaySE, &playSE, &canPlay);
		}
		Button createPlayButton(Composite parent) { mixin(S_TRACE);
			_bgmBtn = new Button(parent, SWT.PUSH);
			_bgmBtn.setToolTipText(_prop.msgs.menuText(MenuID.PlaySE));
			_bgmBtn.setImage(_prop.images.menu(MenuID.PlaySE));
			auto play = new Play;
			_bgmBtn.addSelectionListener(play);
			_comm.put(_bgmBtn, &canPlay);
			return _bgmBtn;
		}
		Button createStopButton(Composite parent) { mixin(S_TRACE);
			auto stop = new Button(parent, SWT.PUSH);
			stop.setToolTipText(_prop.msgs.menuText(MenuID.StopSE));
			stop.setImage(_prop.images.menu(MenuID.StopSE));
			auto sse = new StopSE;
			stop.addSelectionListener(sse);
			stop.addDisposeListener(sse);
			return stop;
		}
		@property
		bool canPlay() { mixin(S_TRACE);
			return filePath.length > 0;
		}
		void playSE() { mixin(S_TRACE);
			string p = filePath;
			if (p.length > 0) { mixin(S_TRACE);
				auto volume = _volume ? _volume.getSelection() : 100;
				auto loopCount = _loopCount ? _loopCount.getSelection() : 1;
				playSECW(_prop, p, volume, loopCount, _comm.skin.legacy);
			}
		}
		void stopSE() { mixin(S_TRACE);
			.stopSE();
		}
		private class Play : SelectionAdapter, KeyListener, MouseListener {
			override void mouseUp(MouseEvent e) {}
			override void mouseDown(MouseEvent e) {}
			override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
				if (e.button == 1) { mixin(S_TRACE);
					playSE();
				}
			}
			override void keyReleased(KeyEvent e) {}
			override void keyPressed(KeyEvent e) { mixin(S_TRACE);
				if (e.character == SWT.CR) { mixin(S_TRACE);
					playSE();
				}
			}
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				playSE();
			}
		}
	}
	Button createRefreshButton(Composite parent, bool text) { mixin(S_TRACE);
		auto refBtn = new Button(parent, SWT.PUSH);
		refBtn.setImage(_prop.images.menu(MenuID.Refresh));
		if (text) { mixin(S_TRACE);
			refBtn.setText(_prop.msgs.refreshS);
		} else { mixin(S_TRACE);
			refBtn.setToolTipText(_prop.msgs.menuText(MenuID.Refresh));
		}
		.listener(refBtn, SWT.Selection, &doRefresh);
		return refBtn;
	}
	Button createDirectoryButton(Composite parent, bool text) { mixin(S_TRACE);
		_dirBtn = new Button(parent, SWT.PUSH);
		_dirBtn.setLayoutData(new GridData(GridData.FILL_VERTICAL));
		_dirBtn.setImage(_prop.images.folder);
		.listener(_dirBtn, SWT.Selection, &doDirectory);
		if (text) { mixin(S_TRACE);
			_dirBtn.setText(_prop.msgs.menuText(MenuID.OpenDir));
		} else { mixin(S_TRACE);
			_dirBtn.setToolTipText(_prop.msgs.menuText(MenuID.OpenDir));
		}
		return _dirBtn;
	}
	ToolItem createRefreshToolItem(ToolBar bar) { mixin(S_TRACE);
		return createToolItem(_comm, bar, MenuID.Refresh, &doRefresh, null);
	}
	ToolItem createDirectoryToolItem(ToolBar bar) { mixin(S_TRACE);
		return createToolItem(_comm, bar, MenuID.OpenDir, &doDirectory, null);
	}
	@property
	string path() { mixin(S_TRACE);
		if (_dirs.getSelectionIndex() == _including && isBinImg(_binPath)) { mixin(S_TRACE);
			return _binPath;
		}
		return _path;
	}
	@property
	string filePath() { mixin(S_TRACE);
		if (!_dirs || _dirs.isDisposed()) return "";
		if (!_fileList || _fileList.isDisposed()) return "";
		if (_dirs.getSelectionIndex() == _including && isBinImg(_binPath)) { mixin(S_TRACE);
			return _binPath;
		}
		auto p = currentDir;
		if (p && _fileList.getSelectionIndex() >= 0) { mixin(S_TRACE);
			string f = fileText(_fileList.getItem(_fileList.getSelectionIndex()));
			if (_dirs.getSelectionIndex() == _tbl) { mixin(S_TRACE);
				return std.path.buildPath(defDir, f);
			} else { mixin(S_TRACE);
				return std.path.buildPath(std.path.buildPath(_summ ? _summ.scenarioPath : "", p), f);
			}
		}
		return "";
	}
	@property
	void path(string path) { mixin(S_TRACE);
		path2(path, true);
	}
	void path2(string path, bool updateBinImg) { mixin(S_TRACE);
		auto old = _path;
		scope (exit) {
			if (old != _path) {
				foreach (dlg; modEvent) dlg();
			}
		}
		_path = path;
		if (updateBinImg) {
			_binPath = isBinImg(path) ? path : "";
		}
		static if (Type is MtType.CARD) {
			if (!useNoCardSizeImage && !_binPath.length) { mixin(S_TRACE);
				auto p = summSkin.findImagePath(_path, _summ ? _summ.scenarioPath : "");
				if (p.length) { mixin(S_TRACE);
					uint w, h;
					imageSize(p, w, h);
					auto cs = _prop.looks.cardSize;
					if (cs.width != w || cs.height != h) { mixin(S_TRACE);
						useNoCardSizeImage = true;
						if (_refresh) _refresh();
					}
				}
			}
		}
		refreshDefs();
	}
	@property
	string binPath() { mixin(S_TRACE);
		return _binPath;
	}
	@property
	D dirsCombo() { mixin(S_TRACE);
		return _dirs;
	}
	@property
	C fileList() { mixin(S_TRACE);
		return _fileList;
	}
	void refresh() { mixin(S_TRACE);
		refreshDefs();
		if (_refresh) _refresh();
	}

	@property
	string[] showingNames() { mixin(S_TRACE);
		static if (is(C : Table)) {
			TableItem[] itms;
			if (_fnone) { mixin(S_TRACE);
				itms = _fileList.getItems()[1 .. $];
			} else { mixin(S_TRACE);
				itms = _fileList.getItems();
			}
			auto r = new string[itms.length];
			foreach (i, ref s; r) { mixin(S_TRACE);
				s = itms[i].getText();
			}
			return r;
		} else static if (is(C : Combo) || is(C : CCombo)) {
			if (_fnone) { mixin(S_TRACE);
				return _fileList.getItems()[1 .. $];
			} else { mixin(S_TRACE);
				return _fileList.getItems();
			}
		}
	}
	@property
	string[] showingPaths() { mixin(S_TRACE);
		string[] r;
		string curr = currentDir;
		string[] paths = showingNames;
		foreach (s; paths) { mixin(S_TRACE);
			if (curr) { mixin(S_TRACE);
				r ~= .encodePath(std.path.buildPath(curr, s));
			} else if (s.startsWith("/")) { mixin(S_TRACE);
				string file;
				s = s["/".length .. $];
				auto i = s.lastIndexOf("/");
				if (i != -1) { mixin(S_TRACE);
					file = s[i + "/".length .. $];
					s = s[0 .. i];
				} else { mixin(S_TRACE);
					file = s;
					s = "";
				}
				r ~= .encodePath(std.path.buildPath(s, file));
			} else { mixin(S_TRACE);
				r ~= s;
			}
		}
		return r;
	}

	void copyFilePath() { mixin(S_TRACE);
		auto p = path;
		if (!p.length) return;
		_comm.clipboard.setContents([new PathString(encodePath(p))],
			[TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}

	@property
	bool selectedDefDir() { mixin(S_TRACE);
		return _selDir == _tbl;
	}

	@property
	void selectDir(int sel) { mixin(S_TRACE);
		_dirs.select(sel);
		refreshList();
		scope (exit) {
			refreshButtons();
			if (_refresh) _refresh();
		}
		if (sel < _defs.length) { mixin(S_TRACE);
			_path = "";
			if (_selDir != sel) { mixin(S_TRACE);
				foreach (dlg; modEvent) dlg();
			}
			_selDir = sel;
		} else { mixin(S_TRACE);
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
			}
			_selDir = sel;
		}
	}

	@property
	IncSearch incSearch() {return _incSearch;}
	void startIncSearch() { mixin(S_TRACE);
		.forceFocus(_fileList, true);
		_incSearch.startIncSearch();
	}

private:
	static if (Type == MtType.CARD) {
		private bool _noCardSize = false;
		@property const(string)[] defExts() {return summSkin.extImage;}
		@property string defDir() {return summSkin.tableDir;}
		bool isTarg(string p) {return summSkin.isCardImage(p, _noCardSize);}
		bool hasTarg(string p) {return summSkin.hasCardImage(p, _noCardSize);}
		string[] targsImpl(string dir, bool re) {return summSkin.cards(dir, _prop.var.etc.logicalSort, re, _noCardSize);}
		@property Image image() {return _prop.images.cards;}
	} else static if (Type == MtType.BG_IMG) {
		@property const(string)[] defExts() {return summSkin.extImage;}
		@property string defDir() {return summSkin.tableDir;}
		bool isTarg(string p) {return summSkin.isBgImage(p);}
		bool hasTarg(string p) {return summSkin.hasBgImage(p);}
		string[] targsImpl(string dir, bool re) {return summSkin.tables(dir, _prop.var.etc.logicalSort, re);}
		@property Image image() {return _prop.images.backs;}
	} else static if (Type == MtType.BGM) {
		@property const(string)[] defExts() {return summSkin.extBgm;}
		@property string defDir() {return summSkin.bgmDir;}
		bool isTarg(string p) {return summSkin.isBGM(p);}
		bool hasTarg(string p) {return summSkin.hasBGM(p);}
		string[] targsImpl(string dir, bool re) {return summSkin.musics(dir, _prop.var.etc.logicalSort, re);}
		@property Image image() {return _prop.images.bgm;}
	} else static if (Type == MtType.SE) {
		@property const(string)[] defExts() {return summSkin.extSound;}
		@property string defDir() {return summSkin.seDir;}
		bool isTarg(string p) {return summSkin.isSE(p);}
		bool hasTarg(string p) {return summSkin.hasSE(p);}
		string[] targsImpl(string dir, bool re) {return summSkin.sounds(dir, _prop.var.etc.logicalSort, re);}
		@property Image image() {return _prop.images.se;}
	} else static assert (0);

	private void doRefresh() { mixin(S_TRACE);
		refreshPaths(null, true);
		if (_refresh) _refresh();
	}
	private void doDirectory() { mixin(S_TRACE);
		if (_dirs.getSelectionIndex() == _tbl) { mixin(S_TRACE);
			openFolder(defDir);
		} else if (_summ) { mixin(S_TRACE);
			string cur = currentDir;
			if (cur) { mixin(S_TRACE);
				openFolder(std.path.buildPath(_summ.scenarioPath, cur));
			} else { mixin(S_TRACE);
				scope p = std.path.buildPath(_summ.scenarioPath, summSkin.materialPath);
				if (exists(p)) { mixin(S_TRACE);
					openFolder(p);
				} else { mixin(S_TRACE);
					openFolder(_summ.scenarioPath);
				}
			}
		}
	}
	class CSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			selectDir(_dirs.getSelectionIndex());
		}
	}
	class LSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			int index = _fileList.getSelectionIndex();
			if (index < 0) return;
			auto old = _path;
			scope (exit) {
				if (old != _path) {
					foreach (dlg; modEvent) dlg();
				}
				refreshButtons();
			}
			if (_allList) { mixin(S_TRACE);
				string s = fileText(_fileList.getItem(index));
				string file;
				if (s.startsWith("/")) { mixin(S_TRACE);
					s = s["/".length .. $];
					auto i = s.lastIndexOf("/");
					if (i != -1) { mixin(S_TRACE);
						file = s[i + "/".length .. $];
						s = s[0 .. i];
					} else { mixin(S_TRACE);
						file = s;
						s = "/";
					}
					_dirs.setText(s);
				} else { mixin(S_TRACE);
					_dirs.select(_tbl);
					file = s;
				}
				refreshList();
				ptrdiff_t selIndex = -1;
				foreach (i, itm; _fileList.getItems()) { mixin(S_TRACE);
					if (cfnmatch(fileText(itm), file)) { mixin(S_TRACE);
						selIndex = i;
						break;
					}
				}
				_fileList.select(cast(int)selIndex);
				static if (is (C == Table)) {
					_fileList.showSelection();
				}
				string p = currentDir;
				_path = std.path.buildPath(p, file);
				_selDir = _dirs.getSelectionIndex();
				if (_refresh) _refresh();
			} else { mixin(S_TRACE);
				string p = currentDir;
				if (!p) { mixin(S_TRACE);
					static if (is(C : Combo) || is(C : CCombo)) {
						if (index == 0) return;
						_fileList.remove(0);
					}
					_dirs.select(cast(int)_defs.length);
					p = currentDir;
				}
				if (p) { mixin(S_TRACE);
					_path = std.path.buildPath(p, fileText(_fileList.getItem(_fileList.getSelectionIndex())));
					_selDir = _dirs.getSelectionIndex();
					if (_refresh) _refresh();
				}
			}
		}
	}
	private class OpenMaterial : MouseAdapter, KeyListener {
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (1 == e.button) { mixin(S_TRACE);
				openFilePath();
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (SWT.CR == e.character) openFilePath();
		}
	}
	private void openFilePath() { mixin(S_TRACE);
		auto dir = _dirs.getSelectionIndex();
		if (dir < _defs.length) return;
		if (dir == _tbl) return;
		auto p = filePath;
		if (p.length) { mixin(S_TRACE);
			_comm.openFilePath(p, false, true);
		}
	}
	private static string fromViewPath(string s) { mixin(S_TRACE);
		static if (dirSeparator != "/" && altDirSeparator == "/") {
			return replace(s, "/", dirSeparator);
		} else { mixin(S_TRACE);
			return s;
		}
	}
	private static string toViewPath(string s) { mixin(S_TRACE);
		static if (dirSeparator != "/" && altDirSeparator == "/") {
			return replace(replace(s, dirSeparator, "/"), altDirSeparator, "/");
		} else { mixin(S_TRACE);
			return s;
		}
	}
	@property
	private string currentDir() { mixin(S_TRACE);
		int sel = _dirs.getSelectionIndex();
		if (sel >= _defs.length) { mixin(S_TRACE);
			if (sel == _tbl) { mixin(S_TRACE);
				return "";
			} else { mixin(S_TRACE);
				return _dirs.getText() == "/" ? "" : toViewPath(_dirs.getText());
			}
		}
		return null;
	}
	private string fileText(T)(T itm) { mixin(S_TRACE);
		static if (is(T : TableItem)) {
			return itm.getText();
		} else static if (is(T : string)) {
			return itm;
		} else static assert (0);
	}
	ptrdiff_t indexOf(T)(T list, string path) { mixin(S_TRACE);
		foreach (i, s; list.getItems()) { mixin(S_TRACE);
			if (cfnmatch(fileText(s), path)) { mixin(S_TRACE);
				return i;
			}
		}
		return -1;
	}
	ptrdiff_t flIndexOf(string path) { mixin(S_TRACE);
		return indexOf(_fileList, path);
	}
	ptrdiff_t dirsIndexOf(string path) { mixin(S_TRACE);
		return indexOf(_dirs, path);
	}
	string[] targs(string path, bool forceRefresh) { mixin(S_TRACE);
		string[] r;
		foreach (f; targsImpl(path, forceRefresh)) { mixin(S_TRACE);
			if (_incSearch.match(f.baseName())) { mixin(S_TRACE);
				r ~= f;
			}
		}
		return r;
	}
	void refreshListImpl(string path, bool forceRefresh) { mixin(S_TRACE);
		refreshListImpl2(targs(path, forceRefresh));
		_allList = false;
	}
	void refreshListImpl(string[] paths, bool forceRefresh) { mixin(S_TRACE);
		string[] tgs;
		foreach (path; paths) { mixin(S_TRACE);
			string parent;
			if (cfnmatch(path, defDir)) { mixin(S_TRACE);
				parent = "";
			} else { mixin(S_TRACE);
				assert (_summ !is null);
				parent = abs2rel(path, _summ.scenarioPath);
				parent = dirSeparator.idup ~ parent;
			}
			string[] s = targs(path, forceRefresh);
			foreach (ref f; s) { mixin(S_TRACE);
				f = encodePath(std.path.buildPath(parent, f));
			}
			tgs ~= s;
		}
		refreshListImpl2(tgs);
		_allList = true;
	}
	void refreshListImpl2(string[] tgs) { mixin(S_TRACE);
		foreach (f; tgs) { mixin(S_TRACE);
			static if (is(C : Table)) {
				auto itm = new TableItem(_fileList, SWT.NONE);
				itm.setText(f);
				itm.setImage(image);
			} else static if (is(C : Combo) || is(C : CCombo)) {
				_fileList.add(f);
			} else static assert (0);
		}
		string sel = _path.length > 0 ? baseName(_path) : "";
		if (sel.length > 0 && _dirs.getSelectionIndex() == _selDir) { mixin(S_TRACE);
			auto index = flIndexOf(sel);
			if (index >= 0) { mixin(S_TRACE);
				_fileList.select(cast(int)index);
			} else if (_dirs.getSelectionIndex() == _tbl) { mixin(S_TRACE);
				foreach (defExt; defExts) { mixin(S_TRACE);
					index = flIndexOf(setExtension(sel, defExt));
					if (0 <= index) { mixin(S_TRACE);
						_fileList.select(cast(int)index);
						break;
					}
				}
			}
		}
		static if (is (C == Table)) {
			_fileList.showSelection();
		} else static if (!is (C == Combo) && !is (C == CCombo)) {
			static assert (false);
		}
	}
	@property
	string[] allDirs() { mixin(S_TRACE);
		string[] st;
		foreach (i; cast(int)_defs.length .. _dirs.getItemCount()) { mixin(S_TRACE);
			string t = _dirs.getItem(i);
			if (i == _tbl) { mixin(S_TRACE);
				st ~= defDir;
			} else if (t == "/") { mixin(S_TRACE);
				assert (_summ !is null);
				st ~= nabs(_summ.scenarioPath);
			} else { mixin(S_TRACE);
				assert (_summ !is null);
				st ~= nabs(std.path.buildPath(_summ.scenarioPath, fromViewPath(t)));
			}
		}
		return st;
	}
	void refreshList(bool forceRefresh = false) { mixin(S_TRACE);
		_fileList.removeAll();
		_fnone = false;
		if (_dirs.getSelectionIndex() < _defs.length) { mixin(S_TRACE);
			auto dirs = allDirs;
			if (!dirs.length) { mixin(S_TRACE);
				_fileList.setEnabled(false);
			} else { mixin(S_TRACE);
				_fileList.setEnabled(!_readOnly);
				refreshListImpl(dirs, forceRefresh);
				static if (is(C : Combo) || is(C : CCombo)) {
					_fileList.add(_prop.msgs.defaultSelection(_prop.msgs.fileNone), 0);
					_fileList.select(0);
					_fnone = true;
				} else { mixin(S_TRACE);
					_fileList.select(-1);
				}
			}
		} else if (_dirs.getSelectionIndex() == _tbl) { mixin(S_TRACE);
			refreshListImpl(defDir, forceRefresh);
		} else if (_summ) { mixin(S_TRACE);
			string st;
			if (_dirs.getText() == "/") { mixin(S_TRACE);
				st = _summ.scenarioPath;
			} else { mixin(S_TRACE);
				st = std.path.buildPath(_summ.scenarioPath, fromViewPath(_dirs.getText()));
			}
			refreshListImpl(st, forceRefresh);
		}
	}
	void searchTarg(string dir, size_t cut) { mixin(S_TRACE);
		if (hasTarg(dir)) { mixin(S_TRACE);
			_dirs.add(dir.length <= cut ? "/" : toViewPath(dir[cut .. $]));
		}
		foreach (f; clistdir(dir)) { mixin(S_TRACE);
			if (containsPath(_prop.var.etc.ignorePaths, f)) continue;
			f = std.path.buildPath(dir, f);
			if (isDir(f)) { mixin(S_TRACE);
				searchTarg(f, cut);
			}
		}
	}
	void refreshPaths(string select = null, bool forceRefresh = false) { mixin(S_TRACE);
		int oldSel = _dirs.getSelectionIndex();
		if (oldSel < 0) oldSel = 0;
		string oldSelS = _dirs.getText();
		_dirs.removeAll();
		foreach (def; _defs) { mixin(S_TRACE);
			_dirs.add(def);
		}
		auto tbl = defDir;
		_tbl = -1;
		if (hasTarg(tbl)) { mixin(S_TRACE);
			_tbl = _dirs.getItemCount();
			_dirs.add(_prop.msgs.defaultSelection(_prop.msgs.pathDef));
		}
		size_t cut = 0;
		if (_summ) { mixin(S_TRACE);
			string st = _summ.scenarioPath;
			cut = st.length;
			static if (altDirSeparator.length) {
				if (!endsWith(st, dirSeparator) && !endsWith(st, altDirSeparator)) cut++;
			} else { mixin(S_TRACE);
				if (!endsWith(st, dirSeparator)) cut++;
			}
			searchTarg(_summ.scenarioPath, cut);
		}
		if (!select) { mixin(S_TRACE);
			void selectOld() { mixin(S_TRACE);
				if (oldSel < _defs.length) { mixin(S_TRACE);
					_dirs.select(oldSel);
				} else { mixin(S_TRACE);
					auto index = dirsIndexOf(oldSelS);
					if (index >= 0) { mixin(S_TRACE);
						_dirs.select(cast(int)index);
					} else if (_dirs.getItemCount() > 0) { mixin(S_TRACE);
						_dirs.select(0);
					}
				}
			}
			bool def;
			if (isBinImg(_path)) { mixin(S_TRACE);
				_dirs.select(_including);
			} else { mixin(S_TRACE);
				auto p = summSkin.findPathF(_path, defExts, defDir, _summ ? _summ.scenarioPath : "", def);
				if (p.length > 0) { mixin(S_TRACE);
					if (def) { mixin(S_TRACE);
						if (_tbl == -1) { mixin(S_TRACE);
							// ファイルが無い
							selectOld();
						} else { mixin(S_TRACE);
							_dirs.select(_tbl);
						}
					} else if (_summ) { mixin(S_TRACE);
						string pt = dirName(p);
						pt = pt.length <= cut ? dirSeparator.idup : pt[cut .. $];
						pt = toViewPath(pt);
						_dirs.select(cast(int)dirsIndexOf(pt));
					}
				} else { mixin(S_TRACE);
					selectOld();
				}
			}
		} else { mixin(S_TRACE);
			select = toViewPath(select);
			_dirs.setText(select);
		}
		_selDir = _dirs.getSelectionIndex();
		refreshList(forceRefresh);
	}

	void refPaths(Object sender, string parent) { mixin(S_TRACE);
		if (this !is sender) { mixin(S_TRACE);
			refreshPaths();
		}
		if (_refresh) _refresh();
	}
	void refPath(string o, string n, bool isDir) { mixin(S_TRACE);
		auto old = _path;
		scope (exit) {
			if (old != _path) {
				foreach (dlg; modEvent) dlg();
			}
		}
		if (isDir) { mixin(S_TRACE);
			int i = cast(int)_defs.length;
			if (_tbl >= 0) i++;
			for (; i < _dirs.getItemCount(); i++) { mixin(S_TRACE);
				string name = fromViewPath(_dirs.getItem(i));
				if (startsWith(name, o)) { mixin(S_TRACE);
					string nName = std.path.buildPath(n, name[o.length .. $]);
					nName = toViewPath(nName);
					_dirs.setItem(i, nName);
					if (i == _dirs.getSelectionIndex()) { mixin(S_TRACE);
						_dirs.setText(nName);
					}
				}
			}
		} else { mixin(S_TRACE);
			if (o == _path) _path = n;
			int di = _dirs.getSelectionIndex();
			auto op = o;
			if (di >= 0 && cfnmatch(fromViewPath(_dirs.getItems()[di]), dirName(o))) { mixin(S_TRACE);
				auto index = flIndexOf(baseName(o));
				if (index >= 0) { mixin(S_TRACE);
					string nName = baseName(n);
					static if (is(C : Table)) {
						_fileList.getItem(cast(int)index).setText(nName);
					} else static if (is (C : Combo) || is (C : CCombo)) {
						_fileList.setItem(cast(int)index, nName);
						_fileList.setText(nName);
					} else static assert (0);
				}
			}
		}
		if (_refresh) _refresh();
	}
	void delPaths() { mixin(S_TRACE);
		refreshPaths();
	}
	void replPath(string from, string to) { mixin(S_TRACE);
		if (_path == from) { mixin(S_TRACE);
			refreshPaths();
		}
	}
	void refreshButtons() { mixin(S_TRACE);
		_comm.refreshToolBar();
	}
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	int _readOnly = 0;
	Props _prop;
	Commons _comm;
	D _dirs;
	Summary _summ;
	Button _dirBtn;
	IncSearch _incSearch;
	string _path = "";
	string _binPath = "";
	string[] _defs;
	int _selDir;
	int _including = -1;
	bool _canInclude = false;
	bool _isMenuCard = false;
	int _tbl = -1;
	bool _fnone = false;
	C _fileList;
	bool _allList = false;
	void delegate() _refresh;
	Skin _summSkin;
}

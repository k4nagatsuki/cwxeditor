
module cwx.editor.gui.dwt.materialselect;

import cwx.cwl;
import cwx.utils;
import cwx.summary;
import cwx.skin;
import cwx.menu;
import cwx.types;
import cwx.imagesize;
import cwx.card;
import cwx.warning;

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
import cwx.editor.gui.dwt.undo;

import core.atomic;
import core.thread;

import std.algorithm : min, any;
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
	void delegate()[] includeEvent;
	/// リスト更新完了時に呼び出される。
	void delegate()[] loadedEvent;

	static if (Type == MtType.CARD) {
		/// defsのindexから値を返す関数。
		CardImage delegate(int index, bool included, string binPath) valueFromDef = null;
		/// 値からdefsのindexを返す関数。
		int delegate(in CardImage imgPath, bool included) valueToDef = null;
		/// カードサイズ以外のイメージを表示するオプションが内部的に切り替えられた時に呼び出される。
		void delegate()[] updateNoCardSize;
	}
	/// 格納リソースを示すdirsのindexを返す。
	int delegate(bool included) indexOfBinPath = null;

	this (Commons comm, Props prop, Summary summ, bool readOnly, void delegate() refresh, string[] delegate(bool included) defs, bool canInclude = false, bool isMenuCard = false,
			UndoManager undo = null, void delegate() store = null) { mixin(S_TRACE);
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_comm = comm;
		_prop = prop;
		_summ = summ;
		if (_readOnly || !_summ || _summ.scenarioPath == "") { mixin(S_TRACE);
			_summSkin = findSkin(_comm, _prop, _summ);
		}
		_refresh = refresh;
		_defs = defs ? defs : included => [];
		_canInclude = canInclude;
		_isMenuCard = isMenuCard;
		static if (Type == MtType.CARD) {
			_paths = [new CardImage("", CardImagePosition.Default)];
			_binPaths = [""];
		}
		_undo = undo;
		_store = store;
	}
	@property
	const
	bool canInclude() { return _canInclude; }
	@property
	const
	bool isMenuCard() { return _isMenuCard; }

	D createDirsCombo(Composite parent) { mixin(S_TRACE);
		static if (is(D == Combo)) {
			_dirs = new D(parent, SWT.BORDER | SWT.READ_ONLY | SWT.DROP_DOWN);
			_dirs.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		} else static if (is(D == CCombo)) {
			_dirs = new D(parent, SWT.BORDER | SWT.READ_ONLY);
			_dirs.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!D(_comm, _prop, _dirs, null);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_dirs.setEnabled(_enabled && !_readOnly);
		_dirs.addSelectionListener(new CSListener);

		_comm.refDataVersion.add(&refreshFileListMenu);
		_comm.refDataVersion.add(&refresh);
		_comm.refTargetVersion.add(&refresh);
		_comm.refIgnorePaths.add(&refresh);
		if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.refSkin.add(&refSkin);
			_comm.refPaths.add(&refPaths);
			_comm.refPath.add(&refPath);
			_comm.delPaths.add(&delPaths);
			_comm.replPath.add(&replPath);
		}
		if (!_display) _display = parent.getDisplay();
		static if (Type == MtType.BGM) {
			stopBGMEvent ~= &stopBGM;
		} else static if (Type == MtType.SE) {
			stopSEEvent ~= &stopSE;
		}
		_dirs.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				_comm.refDataVersion.remove(&refreshFileListMenu);
				_comm.refDataVersion.remove(&refresh);
				_comm.refTargetVersion.remove(&refresh);
				_comm.refIgnorePaths.remove(&refresh);
				if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
					_comm.refSkin.remove(&refSkin);
					_comm.refPaths.remove(&refPaths);
					_comm.refPath.remove(&refPath);
					_comm.delPaths.remove(&delPaths);
					_comm.replPath.remove(&replPath);
				}
				static if (Type == MtType.BGM) {
					cwx.utils.remove(stopBGMEvent, &stopBGM);
					if (_playing != "") .stopBGM();
				} else static if (Type == MtType.SE) {
					cwx.utils.remove(stopSEEvent, &stopSE);
					if (_playing != "") .stopSE();
				}
			}
		});
		auto menu = new Menu(_dirs.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &startIncSearch, &canIncSearch);
		_dirs.setMenu(menu);
		return _dirs;
	}
	static if (Type == MtType.BGM) {
		private bool _startPlay = false;
		private void stopBGM() { mixin(S_TRACE);
			if (_startPlay) return;
			_display.asyncExec(new class Runnable {
				override void run() { mixin(S_TRACE);
					if (_playing != "") { mixin(S_TRACE);
						bgmStopped();
					}
				}
			});
		}

		private bool _canContinue = false;
		/// BGM継続を選択可能か。
		@property
		void canContinue(bool value) { mixin(S_TRACE);
			if (_canContinue == value) return;
			_canContinue = value;
			if (_dirs && _fileList) refreshPaths();
		}
		/// ditto
		@property
		const
		bool canContinue() { mixin(S_TRACE);
			return _canContinue;
		}

		private bool _continueBGM = false;
		@property
		void continueBGM(bool value) { mixin(S_TRACE);
			if (_continueBGM == value) return;
			_continueBGM = value;
			if (_continueBGM) { mixin(S_TRACE);
				path2("", true, true);
				assert (continueIndex != -1);
				selectDir(cast(int)continueIndex);
			} else { mixin(S_TRACE);
				if (path == "") selectDir(0);
			}
		}
		@property
		const
		bool continueBGM() { mixin(S_TRACE);
			return _continueBGM;
		}
	}
	C createFileList(Composite parent) { mixin(S_TRACE);
		static if (is(C == Table)) {
			_fileList = new C(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE | SWT.FULL_SELECTION);
			new FullTableColumn(_fileList, SWT.NONE);
		} else static if (is(C == Combo)) {
			_fileList = new C(parent, SWT.BORDER | SWT.READ_ONLY | SWT.DROP_DOWN);
			_fileList.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		} else static if (is(C == CCombo)) {
			_fileList = new C(parent, SWT.BORDER | SWT.READ_ONLY);
			_fileList.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!CCombo(_comm, _prop, _fileList, null);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		ptrdiff_t skinPos, enginePosFrom, enginePosTo;
		auto dirs = allDirs(skinPos, enginePosFrom, enginePosTo);
		_fileList.setEnabled(_enabled && !_readOnly && _summ);
		_fileList.addSelectionListener(new LSListener);
		static if (is(C == Table)) {
			static if (Type == MtType.BGM || Type == MtType.SE) {
				auto play = new Play;
				_fileList.addMouseListener(play);
				_fileList.addKeyListener(play);
				static if (Type == MtType.BGM) {
					.listener(_fileList, SWT.Dispose, { mixin(S_TRACE);
						if (_playing != "") { mixin(S_TRACE);
							stopBGM();
							_playing = "";
						}
					});
				} else static if (Type == MtType.SE) {
					.listener(_fileList, SWT.Dispose, { mixin(S_TRACE);
						if (_playing != "") { mixin(S_TRACE);
							stopSE();
							_playing = "";
						}
					});
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
			bool canDrop() { return _summ !is null && _summ.scenarioPath != "" && !_readOnly; }
			string[] doAll(string[] files) { mixin(S_TRACE);
				assert (_summ !is null);
				string[] r;
				static if (Type == MtType.CARD) {
					auto showNoCardSize = _noCardSize;
					auto cSize = _prop.looks.cardSize;
					auto skin = summSkin;
				}
				foreach (f; files) { mixin(S_TRACE);
					static if (Type == MtType.CARD) {
						auto isTarg = skin.isCardImage(f, true);
						uint w, h;
						.imageSize(f, w, h);
						showNoCardSize |= (w != cSize.width || h != cSize.height);
					} else {
						auto isTarg = isTarg(f);
					}
					if (isTarg && !hasPath(_summ.scenarioPath, f)) { mixin(S_TRACE);
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
						static if (Type == MtType.CARD) {
							if (showNoCardSize && !_noCardSize) { mixin(S_TRACE);
								_noCardSize = showNoCardSize;
								foreach (d; updateNoCardSize) d();
							}
						}
						return r;
					}
				}
				return [];
			}
			bool doFile(string path, int x, int y) { mixin(S_TRACE);
				assert (_summ !is null);
				auto cur = currentDir;
				if (!cur) cur = summSkin.materialPath;
				.copyTo(_summ.scenarioPath, path, cur, false);
				return true;
			}
			void doExit() { mixin(S_TRACE);
				assert (_summ !is null);
				auto cur = currentDir;
				if (!cur) cur = summSkin.materialPath;
				refreshPaths(cur);
				_comm.refPaths.call(this.outer, cur);
			}
		};
		_incSearch = new IncSearch(_comm, parent, &canIncSearch);
		_incSearch.modEvent ~= { mixin(S_TRACE);
			refreshList();
		};
		return _fileList;
	}
	private void refreshFileListMenu() { mixin(S_TRACE);
		if (!_fileList) return;
		auto menu = new Menu(_fileList.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &startIncSearch, &canIncSearch);
		if (_undo) { mixin(S_TRACE);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
		}
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
			data.format = (string t) { return data.id is MenuID.StopBGM ? .tryFormat(t, _playing) : t; };
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
			if (!_noCardSize && path.length && !isBinImg(filePath)) { mixin(S_TRACE);
				auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
				auto p = summSkin.findImagePath(path, _summ ? _summ.scenarioPath : "", wsnVer);
				if (p.length) { mixin(S_TRACE);
					uint w, h;
					imageSize(p, w, h);
					auto cs = _prop.looks.cardSize;
					if (cs.width != w || cs.height != h) { mixin(S_TRACE);
						path2("", false, false, -1, false);
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
					_binPaths[_imageIndex] = bImgToStr(readBinaryFrom!ubyte(file, ptr));
					scope (exit) freeAll(ptr);
					refreshPaths();
					static if (Type == MtType.CARD) { mixin(S_TRACE);
						selectDir(indexOfBinPath ? indexOfBinPath(true) : 0);
					} else { mixin(S_TRACE);
						selectDir(0);
					}
					foreach (d; includeEvent) d();
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
	} else static if (Type == MtType.BG_IMG) {
		@property
		void excludeCardSizeImage(bool excludeCardSize) { mixin(S_TRACE);
			if (_prop.var.etc.excludeCardSizeImage == excludeCardSize) return;
			_prop.var.etc.excludeCardSizeImage = excludeCardSize;
			if (_prop.var.etc.excludeCardSizeImage && path.length && !isBinImg(filePath)) { mixin(S_TRACE);
				auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
				auto p = summSkin.findImagePath(path, _summ ? _summ.scenarioPath : "", wsnVer);
				if (p.length) { mixin(S_TRACE);
					if (summSkin.isCardImage(p, false)) { mixin(S_TRACE);
						path2("", false, false, -1, false);
					}
				}
			}
			refresh();
		}
		@property
		const
		bool excludeCardSizeImage() { mixin(S_TRACE);
			return _prop.var.etc.excludeCardSizeImage;
		}
	}

	static if (Type == MtType.BGM || Type == MtType.SE) {
		private Button _bgmBtn = null;

		private Spinner _volume = null;
		private Spinner _loopCount = null;
		private Spinner _fadeIn = null;
		private Combo _channel = null;

		@property
		string[] warnings() { mixin(S_TRACE);
			string[] r;
			if (_channel && _channel.getSelectionIndex() != 0 && (path != "" || Type == MtType.BGM) && !_prop.isTargetVersion(_summ, "1")) { mixin(S_TRACE);
				r ~= _prop.msgs.warningChannel;
			}
			if (_fadeIn && _fadeIn.getSelection() != 0 && path != "" && !_prop.isTargetVersion(_summ, "1")) { mixin(S_TRACE);
				r ~= _prop.msgs.warningFadeIn;
			}
			if (_volume && _volume.getSelection() != 100 && path != "" && !_prop.isTargetVersion(_summ, "1")) { mixin(S_TRACE);
				r ~= _prop.msgs.warningVolume;
			}
			auto loops = (Type == MtType.BGM) ? 0 : 1;
			if (_loopCount && _loopCount.getSelection() != loops && path != "" && !_prop.isTargetVersion(_summ, "1")) { mixin(S_TRACE);
				r ~= _prop.msgs.warningLoopCount;
			}
			return r;
		}

		Composite createPlayingOptions(Composite parent, bool selectCh = false, bool tableLayout = false) { mixin(S_TRACE);
			auto comp = new Composite(parent, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(selectCh ? 3 : 2, false));

			void createVolume(Composite parent) { mixin(S_TRACE);
				auto volume = this.volume;
				_volume = new Spinner(parent, SWT.BORDER);
				initSpinner(_volume);
				_volume.setMaximum(100);
				_volume.setMinimum(0);
				_volume.setSelection(volume);
				auto sel = { mixin(S_TRACE);
					refDataVersion();
					if (_processing) return;
					if (volume != this.volume) { mixin(S_TRACE);
						volume = this.volume;
						if (_refresh) _refresh();
						foreach (dlg; modEvent) dlg();
					}
				};
				.listener(_volume, SWT.Modify, sel);
				.listener(_volume, SWT.Selection, sel);
			}
			void createLoopCount(Composite parent) { mixin(S_TRACE);
				auto loopCount = this.loopCount;
				_loopCount = new Spinner(parent, SWT.BORDER);
				initSpinner(_loopCount);
				_loopCount.setMaximum(_prop.var.etc.loopCountMax);
				static if (Type == MtType.BGM) {
					_loopCount.setMinimum(0);
				} else static if (Type == MtType.SE) {
					_loopCount.setMinimum(1);
				} else static assert (0);
				_loopCount.setSelection(loopCount);
				auto sel = { mixin(S_TRACE);
					refDataVersion();
					if (_processing) return;
					if (loopCount != this.loopCount) { mixin(S_TRACE);
						loopCount = this.loopCount;
						if (_refresh) _refresh();
						foreach (dlg; modEvent) dlg();
					}
				};
				.listener(_loopCount, SWT.Modify, sel);
				.listener(_loopCount, SWT.Selection, sel);
			}
			void createCh(Composite parent) { mixin(S_TRACE);
				_channel = new Combo(parent, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				_channel.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_channel.add(_prop.msgs.mainChannel);
				_channel.add(_prop.msgs.subChannel);
				_channel.select(0);
				.listener(_channel, SWT.Selection, { mixin(S_TRACE);
					if (_refresh) _refresh();
					foreach (dlg; modEvent) dlg();
					refDataVersion();
				});
			}

			Composite createComp(string text, int wCount) { mixin(S_TRACE);
				if (tableLayout) {
					auto grp = new Group(comp, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					grp.setText(text);
					grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
					auto comp = new Composite(grp, SWT.NONE);
					comp.setLayout(windowGridLayout(wCount, false));
					return comp;
				} else {
					auto comp = new Composite(comp, SWT.NONE);
					auto wgd = windowGridLayout(wCount + 1, false);
					wgd.marginWidth = 0;
					wgd.marginHeight = 0;
					comp.setLayout(wgd);
					auto l = new Label(comp, SWT.NONE);
					l.setText(text ~ ":");
					return comp;
				}
			}

			if (selectCh) { mixin(S_TRACE);
				auto comp4 = createComp(_prop.msgs.playingChannel, 1);
				createCh(comp4);
			}

			auto comp2 = createComp(_prop.msgs.playingVolume, 2);
			createVolume(comp2);
			auto l2 = new Label(comp2, SWT.NONE);
			l2.setText(_prop.msgs.playingVolumePer);

			auto comp3 = createComp(_prop.msgs.loopCount, Type == MtType.BGM ? 2 : 1);
			static if (Type == MtType.BGM) {
				createLoopCount(comp3);
				auto l4 = new Label(comp3, SWT.NONE);
				l4.setText(_prop.msgs.loopCountHint);
			} else static if (Type == MtType.SE) {
				createLoopCount(comp3);
			} else static assert (0);

			_comm.refDataVersion.add(&refDataVersion);
			.listener(parent, SWT.Dispose, { mixin(S_TRACE);
				_comm.refDataVersion.remove(&refDataVersion);
			});
			refDataVersion();

			return comp;
		}
		Composite createFadeIn(Composite parent) { mixin(S_TRACE);
			auto comp = new Composite(parent, SWT.NONE);
			auto wgd = windowGridLayout(3, false);
			wgd.marginWidth = 0;
			wgd.marginHeight = 0;
			comp.setLayout(wgd);

			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(_prop.msgs.fadeIn ~ ":");

			auto fadeIn = this.fadeIn;
			_fadeIn = new Spinner(comp, SWT.BORDER);
			initSpinner(_fadeIn);
			_fadeIn.setMaximum(_prop.var.etc.fadeInMax);
			_fadeIn.setMinimum(0);
			_fadeIn.setSelection(roundTo!int(fadeIn / 100.0)); // 0.1s -> 1ms
			auto sel = { mixin(S_TRACE);
				refDataVersion();
				if (_processing) return;
				if (fadeIn != this.fadeIn) { mixin(S_TRACE);
					fadeIn = this.fadeIn;
					if (_refresh) _refresh();
					foreach (dlg; modEvent) dlg();
				}
			};
			.listener(_fadeIn, SWT.Modify, sel);
			.listener(_fadeIn, SWT.Selection, sel);

			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(_prop.msgs.fadeInHint);

			return comp;
		}
		private void refDataVersion() { mixin(S_TRACE);
			if (!_summ) return;
			if (_volume) _volume.setEnabled(_enabled && !_readOnly && (!_summ.legacy || _volume.getSelection() != 100) && path != "");
			static immutable loopDef = (Type == MtType.BGM) ? 0 : 1;
			if (_loopCount) _loopCount.setEnabled(_enabled && !_readOnly && (!_summ.legacy || _loopCount.getSelection() != loopDef) && path != "");
			if (_channel) _channel.setEnabled(_enabled && !_readOnly && (!_summ.legacy || _channel.getSelectionIndex() != 0) && (path != "" || Type == MtType.BGM));
			static if (Type == MtType.BGM) {
				auto contVal = continueBGM;
			} else {
				static immutable contVal = false;
			}
			if (_fadeIn) _fadeIn.setEnabled(_enabled && !_readOnly && (!_summ.legacy || _fadeIn.getSelection() != 0) && (path != "" || Type == MtType.BGM) && !contVal);
		}
		@property
		int volume() { return _volume ? _volume.getSelection() : 100; }
		@property
		void volume(int volume) { mixin(S_TRACE);
			.enforce(_volume);
			_processing = true;
			scope (exit) _processing = false;
			_volume.setSelection(volume);
			refDataVersion();
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
			_processing = true;
			scope (exit) _processing = false;
			_loopCount.setSelection(loopCount);
			refDataVersion();
		}
		@property
		int channel() { mixin(S_TRACE);
			return _channel ? _channel.getSelectionIndex() : 0;
		}
		@property
		void channel(int channel) { mixin(S_TRACE);
			.enforce(_channel);
			_channel.select(channel);
			refDataVersion();
		}
		@property
		int fadeIn() { mixin(S_TRACE);
			return _fadeIn ? _fadeIn.getSelection() * 100 : 0; // ms -> 0.1s
		}
		@property
		void fadeIn(int fadeIn) { mixin(S_TRACE);
			.enforce(_fadeIn);
			_processing = true;
			scope (exit) _processing = false;
			_fadeIn.setSelection(roundTo!int(fadeIn / 100.0)); // 0.1s -> ms
			refDataVersion();
		}
	}
	static if (Type == MtType.BGM) {
		private MenuItem _bgmMenu = null;
		private ToolItem _bgmTMenu = null;
		string _playing = "";
		private TimeBar _playBar = null;
		private core.thread.Thread _playThr = null;
		private UpdatePlayBar _updatePlayBar = null;
		TimeBar createPlayingBar(Composite parent) { mixin(S_TRACE);
			_playBar = new TimeBar(parent, SWT.NONE);
			initPlayBar();
			.listener(_playBar, SWT.Dispose, { mixin(S_TRACE);
				if (_playThr) { mixin(S_TRACE);
					_playing = "";
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
			data.format = (string t) { return data.id is MenuID.StopBGM ? .tryFormat(t, _playing) : t; };
			modEvent ~= { mixin(S_TRACE);
				if (_playing == "") return;
				updatePlayButton(isPlayOrStop);
			};
		}
		Button createPlayButton(Composite parent) { mixin(S_TRACE);
			_bgmBtn = new Button(parent, SWT.TOGGLE);
			_bgmBtn.setLayoutData(new GridData);
			_bgmBtn.setToolTipText(_prop.msgs.menuText(MenuID.PlayBGM));
			_bgmBtn.setImage(_prop.images.menu(MenuID.PlayBGM));
			auto pbgm = new Play;
			_bgmBtn.addSelectionListener(pbgm);
			_comm.put(_bgmBtn, () => _enabled && canPlay);
			modEvent ~= { mixin(S_TRACE);
				if (_playing == "") return;
				updatePlayButton(isPlayOrStop);
			};
			return _bgmBtn;
		}
		@property
		bool canPlay() { mixin(S_TRACE);
			return _playing != "" ? true : filePath.length > 0;
		}
		@property
		bool isPlayOrStop() { mixin(S_TRACE);
			string p = filePath;
			return p.length > 0 && (_playing == "" || !cfnmatch(nabs(p), nabs(_playing)));
		}
		void updatePlayButton(bool playOrStop) { mixin(S_TRACE);
			if (playOrStop) { mixin(S_TRACE);
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
			} else { mixin(S_TRACE);
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
			}
		}
		void playBGM(bool fromEvent) { mixin(S_TRACE);
			if (isPlayOrStop) { mixin(S_TRACE);
				_startPlay = true;
				scope (exit) _startPlay = false;
				string p = filePath;
				auto volume = _volume ? _volume.getSelection() : 100;
				auto loopCount = _loopCount ? _loopCount.getSelection() : 0;
				auto fadeIn = this.fadeIn;
				bool inPlay = playBGMCW(_prop, p, fadeIn, volume, loopCount, _comm.skin.legacy);
				if (inPlay) { mixin(S_TRACE);
					_playing = p;
					updatePlayButton(false);
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
			if (_playing == "") return;
			updatePlayButton(true);
			_playing = "";
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
				if (.isEnterKey(e.keyCode)) { mixin(S_TRACE);
					playBGM(false);
				}
			}
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				playBGM(false);
			}
		}
		private void playThr() { mixin(S_TRACE);
			auto last = MonoTime.min;
			bool playing = true;
			auto isPlaying = new class Runnable {
				override void run() { mixin(S_TRACE);
					playing = .isBGMPlaying;
				}
			};
			while (_playing != "" && playing) { mixin(S_TRACE);
				_display.asyncExec(isPlaying);
				auto cur = MonoTime.currTime();
				if (cur < last || (last + .dur!"msecs"(100)) <= cur) { mixin(S_TRACE);
					last = cur;
					_display.asyncExec(_updatePlayBar);
				}
				core.thread.Thread.sleep(.dur!"msecs"(16));
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
		string _playing = "";
		void createPlayToolItem(ToolBar bar) { mixin(S_TRACE);
			createToolItem(_comm, bar, MenuID.PlaySE, &playSE, &canPlay);
		}
		Button createPlayButton(Composite parent) { mixin(S_TRACE);
			_bgmBtn = new Button(parent, SWT.PUSH);
			_bgmBtn.setToolTipText(_prop.msgs.menuText(MenuID.PlaySE));
			_bgmBtn.setImage(_prop.images.menu(MenuID.PlaySE));
			auto play = new Play;
			_bgmBtn.addSelectionListener(play);
			_comm.put(_bgmBtn, () => _enabled && canPlay);
			return _bgmBtn;
		}
		Button createStopButton(Composite parent) { mixin(S_TRACE);
			auto stop = new Button(parent, SWT.PUSH);
			stop.setToolTipText(_prop.msgs.menuText(MenuID.StopSE));
			stop.setImage(_prop.images.menu(MenuID.StopSE));
			.listener(stop, SWT.Selection, &stopSE);
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
				auto fadeIn = this.fadeIn;
				playSECW(_prop, p, fadeIn, volume, loopCount, _comm.skin.legacy);
				_playing = p;
			}
		}
		void stopSE() { mixin(S_TRACE);
			if (_playing != "") { mixin(S_TRACE);
				.stopSE();
				_display.asyncExec(new class Runnable {
					override void run() { mixin(S_TRACE);
						if (_playing != "") { mixin(S_TRACE);
							seStopped();
						}
					}
				});
			}
		}
		void seStopped() { mixin(S_TRACE);
			_playing = "";
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
				if (.isEnterKey(e.keyCode)) { mixin(S_TRACE);
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
		_comm.put(refBtn, () => _enabled && canRefresh);
		return refBtn;
	}
	@property
	bool canRefresh() { return !_loading && _summ && _summ.scenarioPath != ""; }
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
		_comm.put(_dirBtn, () => _enabled && canDirectoryButton);
		return _dirBtn;
	}
	@property
	bool canDirectoryButton() { return !_loading; }
	ToolItem createRefreshToolItem(ToolBar bar) { mixin(S_TRACE);
		return createToolItem(_comm, bar, MenuID.Refresh, &doRefresh, null);
	}
	ToolItem createDirectoryToolItem(ToolBar bar) { mixin(S_TRACE);
		return createToolItem(_comm, bar, MenuID.OpenDir, &doDirectory, null);
	}
	@property
	const
	bool loading() { return _loading; }
	static if (Type == MtType.CARD) {
		@property
		CardImage[] paths() { mixin(S_TRACE);
			return _paths;
		}
		@property
		string path(ptrdiff_t index = -1) { mixin(S_TRACE);
			if (index < 0) index = _imageIndex;
			if (indexOfBinPath && _dirs.getSelectionIndex() == indexOfBinPath(0 < binPath.length) && binPath.length) { mixin(S_TRACE);
				return binPath;
			}
			auto cardPath = _paths[index];
			auto path = cardPath.type == CardImageType.File && cardPath.path.length ? cardPath.path : "";
			return path;
		}
		@property
		void paths(CardImage[] paths) { mixin(S_TRACE);
			setPaths(paths, false);
		}
		void setPaths(CardImage[] paths, bool store) { mixin(S_TRACE);
			paths = paths.length ? paths : [new CardImage("", CardImagePosition.Default)];
			if (paths == _paths && !_firstSet) return;
			if (_firstSet) { mixin(S_TRACE);
				store = false;
				_firstSet = false;
			}

			_dirs.setRedraw(false);
			_fileList.setRedraw(false);
			auto old = _paths;
			scope (exit) {
				if (old != _paths) {
					foreach (dlg; modEvent) dlg();
				}
				refreshButtons();
				_dirs.setRedraw(true);
				_fileList.setRedraw(true);
			}
			if (store && _store) _store();
			_paths = paths;
			_binPaths.length = _paths.length;
			bool include = false;
			foreach (i, path; paths) { mixin(S_TRACE);
				include = path.type == CardImageType.File && isBinImg(path.path);
				_binPaths[i] = include ? path.path : "";
			}
			if (include) { mixin(S_TRACE);
				foreach (dlg; includeEvent) dlg();
			}
			updateUseNoCardSizeImage();
			_imageIndex = .min(_imageIndex, _paths.length - 1);
			refreshPaths();
		}
		@property
		void path(string path) { mixin(S_TRACE);
			path2(path, true, true, -1, true);
		}
		void path2(string path, bool refreshPaths, bool updateBinImg, ptrdiff_t index = -1, bool store = true) { mixin(S_TRACE);
			if (index < 0) index = _imageIndex;
			if (this.path(index) == path) return;
			if (store && _store) _store();
			scope (exit) {
				foreach (dlg; modEvent) dlg();
				refreshButtons();
			}
			refreshPaths |= currentDir == "" && path != "";
			selectPath(path, index, store);
			if (updateBinImg) { mixin(S_TRACE);
				_binPaths[index] = path.isBinImg ? path : "";
				if (_binPaths[index].length) { mixin(S_TRACE);
					foreach (dlg; includeEvent) dlg();
				}
			}
			updateUseNoCardSizeImage();
			this.refreshPaths(null, false, refreshPaths);
		}
		private void selectPath(string path, ptrdiff_t index = -1, bool store = true) { mixin(S_TRACE);
			if (index < 0) index = _imageIndex;
			auto p = new CardImage(path, _paths[index].positionType);
			if (_paths[index] == p) return;
			if (store && _store) _store();
			_paths[index] = p;
		}
		private void updateUseNoCardSizeImage() { mixin(S_TRACE);
			if (useNoCardSizeImage) return;
			// カードサイズ以外の画像が存在する場合は
			// カードサイズ以外選択可にチェックを入れておく
			auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
			foreach (i, path; _paths) { mixin(S_TRACE);
				if (!_binPaths[i].length && path.type == CardImageType.File && path.path != "") { mixin(S_TRACE);
					auto p = summSkin.findImagePath(path.path, _summ ? _summ.scenarioPath : "", wsnVer);
					if (p.length) { mixin(S_TRACE);
						uint w, h;
						imageSize(p, w, h);
						auto cs = _prop.looks.cardSize;
						if (cs.width != w || cs.height != h) { mixin(S_TRACE);
							useNoCardSizeImage = true;
							if (_refresh) { mixin(S_TRACE);
								_dirs.setRedraw(false);
								_fileList.setRedraw(false);
								scope (exit) {
									_dirs.setRedraw(true);
									_fileList.setRedraw(true);
								}
								_refresh();
							}
							break;
						}
					}
				}
			}
		}

		@property
		const
		string binPath() { mixin(S_TRACE);
			return _imageIndex < _binPaths.length ? _binPaths[_imageIndex] : "";
		}

		@property
		const
		int imageIndex() { return _imageIndex; }
		@property
		void imageIndex(int imageIndex) { mixin(S_TRACE);
			_imageIndex = imageIndex;
			refreshPaths();
		}
	} else {
		@property
		string path() { mixin(S_TRACE);
			static if (Type == MtType.BG_IMG) {
				if (indexOfBinPath && _dirs.getSelectionIndex() == indexOfBinPath(0 < binPath.length) && binPath.length) { mixin(S_TRACE);
					return binPath;
				}
			}
			return _path;
		}
		@property
		void path(string path) { mixin(S_TRACE);
			path2(path, true, true);
		}
		void path2(string path, bool refreshPaths, bool updateBinImg, ptrdiff_t index = -1, bool store = true) { mixin(S_TRACE);
			auto old = _path;
			scope (exit) {
				if (old != _path) {
					foreach (dlg; modEvent) dlg();
				}
				refreshButtons();
			}
			refreshPaths |= currentDir == "" && path != "";
			selectPath(path, index, store);
			static if (Type == MtType.BG_IMG) {
				if (updateBinImg) { mixin(S_TRACE);
					_binPaths[_imageIndex] = isBinImg(path) ? path : "";
				}
			}
			static if (Type == MtType.BG_IMG) {
				updateExcludeCardSizeImage();
			}
			this.refreshPaths(null, false, refreshPaths);
			static if (Type == MtType.BGM || Type == MtType.SE) {
				refDataVersion();
			}
		}
		private void selectPath(string path, ptrdiff_t index = -1, bool store = true) { mixin(S_TRACE);
			_path = path;
		}
		@property
		string binPath() { mixin(S_TRACE);
			static if (Type == MtType.BG_IMG) {
				return _binPaths[_imageIndex];
			} else {
				return "";
			}
		}
		static if (Type == MtType.BG_IMG) {
			private void updateExcludeCardSizeImage() { mixin(S_TRACE);
				if (!excludeCardSizeImage) return;
				// カードサイズの画像が選択されている場合は
				// カードサイズを除外のチェックを外しておく
				auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
				if (!_binPaths[_imageIndex].length && path != "") { mixin(S_TRACE);
					auto p = summSkin.findImagePath(path, _summ ? _summ.scenarioPath : "", wsnVer);
					if (p.length) { mixin(S_TRACE);
						if (summSkin.isCardImage(p, false)) { mixin(S_TRACE);
							excludeCardSizeImage = true;
							if (_refresh) { mixin(S_TRACE);
								_dirs.setRedraw(false);
								_fileList.setRedraw(false);
								scope (exit) {
									_dirs.setRedraw(true);
									_fileList.setRedraw(true);
								}
								_refresh();
							}
						}
					}
				}
			}
		}
	}
	@property
	string filePath() { mixin(S_TRACE);
		if (_loading) return "";
		if (!_dirs || _dirs.isDisposed()) return "";
		if (!_fileList || _fileList.isDisposed()) return "";
		static if (Type == MtType.CARD || Type == MtType.BG_IMG) {
			if (indexOfBinPath && _dirs.getSelectionIndex() == indexOfBinPath(0 < binPath.length) && binPath.length) { mixin(S_TRACE);
				return binPath;
			}
		}
		auto p = currentDir;
		if (p && _fileList.getSelectionIndex() >= 0) { mixin(S_TRACE);
			string f = fileText(_fileList.getItem(_fileList.getSelectionIndex()));
			return toFilePath(f);
		}
		return "";
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
		refreshPaths();
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
	private string toFilePath(string f) { mixin(S_TRACE);
		auto p = currentDir;
		if (p) { mixin(S_TRACE);
			if (_dirs.getSelectionIndex() == _tbl) { mixin(S_TRACE);
				foreach (defDir; defDirs) { mixin(S_TRACE);
					auto path = std.path.buildPath(defDir, f);
					if (path.exists()) return path;
				}
			} else if (_dirs.getSelectionIndex() == _tblEngine) { mixin(S_TRACE);
				foreach (dir; engineDefDirs) { mixin(S_TRACE);
					auto path = std.path.buildPath(dir, f);
					if (path.exists()) return path;
				}
			} else { mixin(S_TRACE);
				return std.path.buildPath(std.path.buildPath(_summ ? _summ.scenarioPath : "", p), f);
			}
		} else { mixin(S_TRACE);
			if (f.startsWith("/")) { mixin(S_TRACE);
				f = f["/".length .. $];
				return std.path.buildPath(std.path.buildPath(_summ ? _summ.scenarioPath : "", p), f);
			} else { mixin(S_TRACE);
				foreach (defDir; defDirs) { mixin(S_TRACE);
					auto path = std.path.buildPath(defDir, f);
					if (path.exists()) return path;
				}
			}
		}
		return "";
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
		scope (exit) {
			refreshButtons();
			if (_refresh) _refresh();
		}
		auto defs = getDefs();
		if (sel < defs.length) { mixin(S_TRACE);
			static if (Type == MtType.BGM) {
				_continueBGM = continueIndex == sel;
			}
			static if (Type == MtType.CARD) {
				if (valueFromDef) { mixin(S_TRACE);
					refreshList();
					_paths[_imageIndex] = valueFromDef(sel, 0 < binPath.length, binPath);
				} else { mixin(S_TRACE);
					path2("", true, false, -1, true);
				}
			} else { mixin(S_TRACE);
				path2("", true, false, -1, true);
			}
			if (_selDir != sel) { mixin(S_TRACE);
				foreach (dlg; modEvent) dlg();
			}
		} else { mixin(S_TRACE);
			static if (Type == MtType.BGM) {
				_continueBGM = false;
			}
			refreshList();
			static if (is(C : Combo) || is(C : CCombo)) {
				auto old = this.path;
				scope (exit) {
					if (old != this.path) {
						foreach (dlg; modEvent) dlg();
					}
				}
				string p = currentDir;
				if (!p) return;
				if (0 == _fileList.getItemCount()) return;
				_fileList.select(0);
				path2(std.path.buildPath(p, _fileList.getItem(0)), false, false, -1, true);
			}
		}
		_selDir = sel;
	}

	@property
	IncSearch incSearch() { return _incSearch; }
	void startIncSearch() { mixin(S_TRACE);
		if (!_incSearch.isOpen) .forceFocus(_fileList, true);
		_incSearch.startIncSearch();
	}
	@property
	bool canIncSearch() { mixin(S_TRACE);
		return !_readOnly && !_loading && _canIncSearch;
	}

	static if (Type == MtType.CARD || Type == MtType.BG_IMG) {
		@property
		void loadScaledImage(bool delegate() loadScaledImage) { mixin(S_TRACE);
			_loadScaledImage = loadScaledImage;
		}
	}

	@property
	void enabled(bool enabled) { mixin(S_TRACE);
		_enabled = enabled;

		_dirs.setEnabled(_enabled && !_readOnly && !loading);
		_fileList.setEnabled(_enabled && !_readOnly && !loading && _summ);

		static if (Type == MtType.BGM || Type == MtType.SE) {
			static if (Type == MtType.BGM) {
				auto contVal = continueBGM;
			} else {
				static immutable contVal = false;
			}
			static immutable loopDef = (Type == MtType.BGM) ? 0 : 1;
			if (_volume) _volume.setEnabled(!_readOnly && (!_summ.legacy || _volume.getSelection() != 100) && path != "");
			if (_loopCount) _loopCount.setEnabled(!_readOnly && (!_summ.legacy || _loopCount.getSelection() != loopDef) && path != "");
			if (_channel) _channel.setEnabled(!_readOnly && (!_summ.legacy || _channel.getSelectionIndex() != 0) && (path != "" || Type == MtType.BGM));
			if (_fadeIn) _fadeIn.setEnabled(!_readOnly && (!_summ.legacy || _fadeIn.getSelection() != 0) && (path != "" || Type == MtType.BGM) && !contVal);
		}

		if (!_enabled) { mixin(S_TRACE);
			_incSearch.close();
			static if (Type == MtType.BGM) {
				.stopBGM();
			} else static if (Type == MtType.SE) {
				.stopSE();
			}
		}
	}

	@property
	const
	bool enabled() { return _enabled; }

private:
	static if (Type == MtType.CARD) {
		private bool _noCardSize = false;
		@property const(string)[] defExts() { return summSkin.extImage; }
		@property string[] defDirs() { return summSkin.tableDirs; }
		@property string[] engineDefDirs() { return summSkin.wsnTableDirs(_summ ? _summ.dataVersion : LATEST_VERSION); }
		bool isTarg(string p) { return summSkin.isCardImage(p, _noCardSize); }
		static bool hasTarg(Skin skin, string p, bool forceRefresh, bool noCardSize) { return skin.hasCardImage(p, forceRefresh, noCardSize); }
		bool hasWsnTarg(bool forceRefresh, bool noCardSize) { return summSkin.hasWsnCardImage(_summ ? _summ.dataVersion : LATEST_VERSION, forceRefresh, noCardSize); }
		string[] targsImpl(string dir, bool re) { return summSkin.cards(dir, _prop.var.etc.logicalSort, re, _noCardSize); }
		@property Image image(string file) { return summSkin.isCardImage(file, false) ? _prop.images.cards : _prop.images.backs; }
	} else static if (Type == MtType.BG_IMG) {
		@property const(string)[] defExts() { return summSkin.extImage; }
		@property string[] defDirs() { return summSkin.tableDirs; }
		@property string[] engineDefDirs() { return summSkin.wsnTableDirs(_summ ? _summ.dataVersion : LATEST_VERSION); }
		bool isTarg(string p) { return summSkin.isBgImage(p, excludeCardSizeImage); }
		static bool hasTarg(Skin skin, string p, bool forceRefresh, bool excludeCardSize) { return skin.hasBgImage(p, forceRefresh, excludeCardSize); }
		bool hasWsnTarg(bool forceRefresh, bool excludeCardSize) { return summSkin.hasWsnBgImage(_summ ? _summ.dataVersion : LATEST_VERSION, forceRefresh, excludeCardSize); }
		string[] targsImpl(string dir, bool re) { return summSkin.tables(dir, _prop.var.etc.logicalSort, re, excludeCardSizeImage); }
		@property Image image(string file) { return summSkin.isCardImage(file, false) ? _prop.images.cards : _prop.images.backs; }
	} else static if (Type == MtType.BGM) {
		@property const(string)[] defExts() { return summSkin.extBgm; }
		@property string[] defDirs() { return summSkin.bgmDirs; }
		@property string[] engineDefDirs() { return summSkin.wsnMusicDirs(_summ ? _summ.dataVersion : LATEST_VERSION); }
		bool isTarg(string p) { return summSkin.isBGM(p); }
		static bool hasTarg(Skin skin, string p, bool forceRefresh, bool noCardSize) { return skin.hasBGM(p, forceRefresh); }
		bool hasWsnTarg(bool forceRefresh, bool noCardSize) { return summSkin.hasWsnBGM(_summ ? _summ.dataVersion : LATEST_VERSION, forceRefresh); }
		string[] targsImpl(string dir, bool re) { return summSkin.musics(dir, _prop.var.etc.logicalSort, re); }
		@property Image image() { return _prop.images.bgm; }
	} else static if (Type == MtType.SE) {
		@property const(string)[] defExts() { return summSkin.extSound; }
		@property string[] defDirs() { return summSkin.seDirs; }
		@property string[] engineDefDirs() { return summSkin.wsnSoundDirs(_summ ? _summ.dataVersion : LATEST_VERSION); }
		bool isTarg(string p) { return summSkin.isSE(p); }
		static bool hasTarg(Skin skin, string p, bool forceRefresh, bool noCardSize) { return skin.hasSE(p, forceRefresh); }
		bool hasWsnTarg(bool forceRefresh, bool noCardSize) { return summSkin.hasWsnSE(_summ ? _summ.dataVersion : LATEST_VERSION, forceRefresh); }
		string[] targsImpl(string dir, bool re) { return summSkin.sounds(dir, _prop.var.etc.logicalSort, re); }
		@property Image image() { return _prop.images.se; }
	} else static assert (0);

	private void doRefresh() { mixin(S_TRACE);
		refreshPaths(null, true);
		if (_refresh) _refresh();
	}
	private void doDirectory() { mixin(S_TRACE);
		if (_dirs.getSelectionIndex() == _tbl) { mixin(S_TRACE);
			static if (Type == MtType.CARD) {
				bool noCardSize = _noCardSize;
			} else static if (Type == MtType.BG_IMG) {
				bool noCardSize = _prop.var.etc.excludeCardSizeImage;
			} else {
				bool noCardSize = false;
			}
			auto skin = summSkin;
			foreach (defDir; defDirs) { mixin(S_TRACE);
				if (defDir.exists()) { mixin(S_TRACE);
					if (hasTarg(skin, defDir, false, noCardSize)) { mixin(S_TRACE);
						openFolder(defDir);
						return;
					}
				}
			}
			openFolder(defDirs[0]);
		} else if (_dirs.getSelectionIndex() == _tblEngine) { mixin(S_TRACE);
			auto dir = _prop.enginePath.dirName().buildPath("Data/Materials");
			openFolder(dir);
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
			static if (Type == MtType.BGM) {
				auto index = continueIndex;
				if (index != -1 && !canContinue && index == _dirs.getSelectionIndex()) { mixin(S_TRACE);
					_dirs.select(0);
				}
			}
			selectDir(_dirs.getSelectionIndex());
		}
	}
	class LSListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			selectFile();
		}
	}
	void selectFile() { mixin(S_TRACE);
		int index = _fileList.getSelectionIndex();
		if (index < 0) return;
		if (_fnone && index == 0) return;
		auto old = this.path;
		scope (exit) {
			if (old != this.path) {
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
			} else if (_tblEngineIndex == -1 || index < _tblEngineIndex) { mixin(S_TRACE);
				_dirs.select(_tbl);
				file = s;
			} else {
				_dirs.select(_tblEngine);
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
			static if (is(C == Table)) {
				_fileList.showSelection();
			}
			string p = currentDir;
			path2(std.path.buildPath(p, file), false, false, -1, true);
			_selDir = _dirs.getSelectionIndex();
			if (_refresh) _refresh();
		} else { mixin(S_TRACE);
			string p = currentDir;
			if (!p) { mixin(S_TRACE);
				static if (is(C : Combo) || is(C : CCombo)) {
					if (index == 0) return;
					_fileList.remove(0);
				}
				auto defs = getDefs();
				_dirs.select(cast(int)defs.length);
				p = currentDir;
			}
			if (p) { mixin(S_TRACE);
				selectPath(std.path.buildPath(p, fileText(_fileList.getItem(_fileList.getSelectionIndex()))), -1, true);
				_selDir = _dirs.getSelectionIndex();
				if (_refresh) _refresh();
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
			if (.isEnterKey(e.keyCode)) openFilePath();
		}
	}
	private void openFilePath() { mixin(S_TRACE);
		auto dir = _dirs.getSelectionIndex();
		auto defs = getDefs();
		if (dir < defs.length) return;
		if (dir == _tbl) return;
		if (dir == _tblEngine) return;
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
		auto defs = getDefs();
		if (sel >= defs.length) { mixin(S_TRACE);
			if (sel == _tbl || sel == _tblEngine) { mixin(S_TRACE);
				return "";
			} else { mixin(S_TRACE);
				return _dirs.getText() == "/" ? "" : toViewPath(_dirs.getText());
			}
		}
		return null;
	}
	// FIXME: リリースビルドでこのテンプレートメソッドがリンクエラーになる
	//private string fileText(T)(T itm) { mixin(S_TRACE);
	//	static if (is(T : TableItem)) {
	//		return itm.getText();
	//	} else static if (is(T : string)) {
	//		return itm;
	//	} else static assert (0);
	//}
	private string fileText(TableItem itm) { mixin(S_TRACE);
		return itm.getText();
	}
	private string fileText(string itm) { mixin(S_TRACE);
		return itm;
	}
	// FIXME: リリースビルドでこのテンプレートメソッドがリンクエラーになる
	//ptrdiff_t indexOf(T)(T list, string path) { mixin(S_TRACE);
	//	foreach (i, s; list.getItems()) { mixin(S_TRACE);
	//		if (cfnmatch(fileText(s), path)) { mixin(S_TRACE);
	//			return i;
	//		}
	//	}
	//	return -1;
	//}
	ptrdiff_t indexOf(Combo list, string path) { mixin(S_TRACE);
		foreach (i, s; list.getItems()) { mixin(S_TRACE);
			if (cfnmatch(fileText(s), path)) { mixin(S_TRACE);
				return i;
			}
		}
		return -1;
	}
	ptrdiff_t indexOf(Table list, string path) { mixin(S_TRACE);
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
	string[] targs(string path, bool forceRefresh, bool subThr) { mixin(S_TRACE);
		string[] r;
		auto isTbl = !_summ || _summ.scenarioPath == "" || !path.isSubDirectory(_summ.scenarioPath);
		foreach (f; targsImpl(path, forceRefresh)) { mixin(S_TRACE);
			static if (MtType.CARD == Type || MtType.BG_IMG == Type) {
				if (isTbl || !_summ || _summ.scenarioPath == "" || (!_summ.legacy && _loadScaledImage ? _loadScaledImage() : _summ.loadScaledImage)) { mixin(S_TRACE);
					// スケーリングされたイメージファイルを除外
					if (f.noScaledPath != "") continue;
				}
			}
			_canIncSearch = true;
			if (subThr || _incSearch.match(f.baseName())) { mixin(S_TRACE);
				r ~= f;
			}
		}
		return r;
	}
	void refreshListImpl(string path, bool forceRefresh, bool subThr = false) { mixin(S_TRACE);
		if (!_display) _display = _fileList.getDisplay();
		_tblIndex = -1;
		_tblEngineIndex = -1;
		void find() { mixin(S_TRACE);
			auto tgs = targs(path, forceRefresh, subThr);
			if (subThr) { mixin(S_TRACE);
				_display.asyncExec(new class Runnable {
					override void run() { mixin(S_TRACE);
						if (_fileList.isDisposed()) return;
						refreshListImpl2(tgs);
						_allList = false;
					}
				});
			} else { mixin(S_TRACE);
				refreshListImpl2(tgs);
				_allList = false;
			}
		}
		if (subThr) { mixin(S_TRACE);
			auto thr = new core.thread.Thread(&find);
			thr.start();
		} else { mixin(S_TRACE);
			find();
		}
	}
	void refreshListImpl(string[] paths, bool allList, bool forceRefresh, bool subThr, ptrdiff_t skinPos, ptrdiff_t enginePosFrom, ptrdiff_t enginePosTo) { mixin(S_TRACE);
		if (!_display) _display = _fileList.getDisplay();
		_tblIndex = -1;
		_tblEngineIndex = -1;
		void find() { mixin(S_TRACE);
			string[] def;
			string[] wsn;
			string[] sc;
			foreach (i, path; paths) { mixin(S_TRACE);
				if (i == skinPos) { mixin(S_TRACE);
					_tblIndex = def.length + wsn.length + sc.length;
				}
				if (i == enginePosFrom) { mixin(S_TRACE);
					_tblEngineIndex = def.length + wsn.length + sc.length;
				}
				string parent;
				auto dirIndex = _dirs.getSelectionIndex();
				if (!_summ || _summ.scenarioPath == "" || i == skinPos || (enginePosFrom != -1 && enginePosFrom <= i && i < enginePosTo)) { mixin(S_TRACE);
					parent = "";
				} else { mixin(S_TRACE);
					assert (_summ !is null);
					parent = abs2rel(path, _summ.scenarioPath);
					parent = dirSeparator.idup ~ parent;
				}
				string[] s = targs(path, forceRefresh, subThr);
				foreach (ref f; s) { mixin(S_TRACE);
					f = encodePath(std.path.buildPath(parent, f));
				}
				if (i == skinPos) { mixin(S_TRACE);
					def ~= s;
				} else if (enginePosFrom != -1 && enginePosFrom <= i && i < enginePosTo) { mixin(S_TRACE);
					wsn ~= s;
				} else { mixin(S_TRACE);
					sc ~= s;
				}
			}
			// WSN標準素材は複数のディレクトリに分かれている可能性があるので
			// ここでまとめてソートする
			if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
				wsn = cwx.utils.sort!(fnncmp)(wsn);
			} else { mixin(S_TRACE);
				wsn = cwx.utils.sort!(fncmp)(wsn);
			}
			auto tgs = def ~ wsn ~ sc;
			if (subThr) { mixin(S_TRACE);
				_display.asyncExec(new class Runnable {
					override void run() { mixin(S_TRACE);
						if (_fileList.isDisposed()) return;
						refreshListImpl2(tgs);
						_allList = allList;
					}
				});
			} else { mixin(S_TRACE);
				refreshListImpl2(tgs);
				_allList = allList;
			}
		}
		if (subThr) { mixin(S_TRACE);
			auto thr = new core.thread.Thread(&find);
			thr.start();
		} else { mixin(S_TRACE);
			find();
		}
	}
	void refreshListImpl2(string[] tgs) { mixin(S_TRACE);
		auto skin = summSkin;
		auto legacy = _summ && _summ.legacy;
		foreach (f; tgs) { mixin(S_TRACE);
			static if (is(C : Table)) {
				auto itm = new TableItem(_fileList, SWT.NONE);
				itm.setText(f);
				static if (Type == MtType.CARD || Type == MtType.BG_IMG) {
					auto ws = skin.warningImage(_prop.parent, f, legacy, canInclude && !isMenuCard, _prop.var.etc.targetVersion);
					if (!ws.length) ws = .sjisWarnings(_prop.parent, _summ, f, "");
					if (!ws.length) ws = .fileExtensionWarnings(_prop.parent, toFilePath(f));
					if (ws.length) { mixin(S_TRACE);
						itm.setImage(_prop.images.warning);
					} else { mixin(S_TRACE);
						itm.setImage(image(toFilePath(f)));
					}
				} else { mixin(S_TRACE);
					itm.setImage(image);
				}
			} else static if (is(C : Combo) || is(C : CCombo)) {
				_fileList.add(f);
			} else static assert (0);
		}
		string sel = this.path.length > 0 ? baseName(this.path) : "";
		if (sel.length > 0 && _dirs.getSelectionIndex() == _selDir) { mixin(S_TRACE);
			auto index = flIndexOf(sel);
			if (index >= 0) { mixin(S_TRACE);
				_fileList.select(cast(int)index);
			} else { mixin(S_TRACE);
				foreach (defExt; defExts) { mixin(S_TRACE);
					index = flIndexOf(setExtension(sel, defExt));
					if (0 <= index) { mixin(S_TRACE);
						_fileList.select(cast(int)index);
						break;
					}
				}
			}
		}
		static if (is(C == Table)) {
			_fileList.showSelection();
		} else static if (!is(C == Combo) && !is(C == CCombo)) {
			static assert (false);
		}
		ptrdiff_t skinPos, enginePosFrom, enginePosTo;
		auto dirs = allDirs(skinPos, enginePosFrom, enginePosTo);
		_fileList.setEnabled(_enabled && !_readOnly && _summ);
		_loading = false;
		foreach (dlg; loadedEvent) dlg();
		_comm.refreshToolBar();
	}
	private string[] allDirs(out ptrdiff_t skinPos, out ptrdiff_t enginePosFrom, out ptrdiff_t enginePosTo) { mixin(S_TRACE);
		if (!_dirs) return [];
		string[] st;
		skinPos = -1;
		enginePosFrom = -1;
		enginePosTo = -1;
		auto defs = getDefs();
		foreach (i; cast(int)defs.length .. _dirs.getItemCount()) { mixin(S_TRACE);
			string t = _dirs.getItem(i);
			if (i == _tbl) { mixin(S_TRACE);
				skinPos = st.length;
				st ~= defDirs;
			} else if (i == _tblEngine) { mixin(S_TRACE);
				enginePosFrom = st.length;
				st ~= engineDefDirs;
			} else { mixin(S_TRACE);
				if (enginePosFrom != -1 && enginePosTo == -1) { mixin(S_TRACE);
					enginePosTo = st.length;
				}
				if (t == "/") { mixin(S_TRACE);
					assert (_summ !is null);
					st ~= nabs(_summ.scenarioPath);
				} else { mixin(S_TRACE);
					assert (_summ !is null);
					st ~= nabs(std.path.buildPath(_summ.scenarioPath, fromViewPath(t)));
				}
			}
		}
		if (enginePosFrom != -1 && enginePosTo == -1) { mixin(S_TRACE);
			enginePosTo = st.length;
		}
		return st;
	}
	public void refreshList(bool forceRefresh = false, bool subThr = false) { mixin(S_TRACE);
		_fileList.removeAll();
		_canIncSearch = false;
		_fnone = false;
		auto defs = getDefs();
		if (_dirs.getSelectionIndex() < defs.length) { mixin(S_TRACE);
			ptrdiff_t skinPos, enginePosFrom, enginePosTo;
			auto dirs = allDirs(skinPos, enginePosFrom, enginePosTo);
			_fileList.setEnabled(_enabled && !_readOnly && _summ);
			if (!dirs.length) { mixin(S_TRACE);
				_loading = false;
				foreach (dlg; loadedEvent) dlg();
				_comm.refreshToolBar();
			} else { mixin(S_TRACE);
				refreshListImpl(dirs, true, forceRefresh, subThr, skinPos, enginePosFrom, enginePosTo);
				static if (is(C : Combo) || is(C : CCombo)) {
					_fileList.add(_prop.msgs.defaultSelection(_prop.msgs.fileNone), 0);
					_fileList.select(0);
					_fnone = true;
				} else { mixin(S_TRACE);
					_fileList.select(-1);
				}
			}
		} else if (_dirs.getSelectionIndex() == _tbl) { mixin(S_TRACE);
			auto dirs = defDirs;
			refreshListImpl(dirs, false, forceRefresh, subThr, -1, 0, dirs.length);
		} else if (_dirs.getSelectionIndex() == _tblEngine) { mixin(S_TRACE);
			auto dirs = engineDefDirs;
			refreshListImpl(dirs, false, forceRefresh, subThr, -1, 0, dirs.length);
		} else if (_summ) { mixin(S_TRACE);
			string st;
			if (_dirs.getText() == "/") { mixin(S_TRACE);
				st = _summ.scenarioPath;
			} else { mixin(S_TRACE);
				st = std.path.buildPath(_summ.scenarioPath, fromViewPath(_dirs.getText()));
			}
			refreshListImpl(st, forceRefresh, subThr);
		}
	}
	string[] searchTarg(Skin skin, string dir, bool forceRefresh, size_t cut) { mixin(S_TRACE);
		string[] r = [];
		static if (Type == MtType.CARD) {
			bool noCardSize = _noCardSize;
		} else static if (Type == MtType.BG_IMG) {
			bool noCardSize = _prop.var.etc.excludeCardSizeImage;
		} else {
			bool noCardSize = false;
		}
		if (hasTarg(skin, dir, forceRefresh, noCardSize)) { mixin(S_TRACE);
			r ~= dir.length <= cut ? "/" : toViewPath(dir[cut .. $]);
		}
		if (!dir.exists() || !dir.isDir()) return r;
		foreach (f; dir.dirEntries(SpanMode.shallow)) { mixin(S_TRACE);
			if (containsPath(_prop.var.etc.ignorePaths, f.baseName)) continue;
			if (f.isDir) { mixin(S_TRACE);
				r ~= searchTarg(skin, f, forceRefresh, cut);
			}
		}
		return r;
	}
	void refreshPaths(string select = null, bool forceRefresh = false, bool updateList = true) { mixin(S_TRACE);
		void thr() { mixin(S_TRACE);
			if (_fileList.isDisposed()) return;
			refreshPathsImpl(select, forceRefresh, updateList);
			_scheduleRefreshPaths = false;
		}
		if (updateList) { mixin(S_TRACE);
			if (_scheduleRefreshPaths) return;
			_scheduleRefreshPaths = true;
			.asyncExec(_fileList.getDisplay(), &thr);
		} else { mixin(S_TRACE);
			thr();
		}
	}
	void refreshPathsImpl(string select, bool forceRefresh, bool updateList) { mixin(S_TRACE);
		int oldSel = _dirs.getSelectionIndex();
		if (!updateList && _tbl <= oldSel) { mixin(S_TRACE);
			if (select is null) select = this.path;
			foreach (i, sp; showingPaths) { mixin(S_TRACE);
				if (.cfnmatch(sp, select)) { mixin(S_TRACE);
					_fileList.select(cast(int)i);
					static if (is(C:Table)) {
						_fileList.showSelection();
					}
					return;
				}
			}
		}

		if (oldSel < 0) oldSel = 0;
		auto oldSelS = _dirs.getText();

		_dirs.removeAll();

		string[] items;
		auto defs = getDefs();
		foreach (def; defs) { mixin(S_TRACE);
			items ~= def;
		}
		auto tbl = defDirs;
		_tbl = -1;
		_tblIndex = -1;
		_tblEngine = -1;
		_tblEngineIndex = -1;
		auto skin = summSkin;
		static if (Type == MtType.CARD) {
			bool noCardSize = _noCardSize;
		} else static if (Type == MtType.BG_IMG) {
			bool noCardSize = _prop.var.etc.excludeCardSizeImage;
		} else {
			bool noCardSize = false;
		}
		// BUG: dmd 2.073.0 64bit Releaseビルドでリンクエラーになる
//		if (.any!(tbl => hasTarg(skin, tbl, forceRefresh, noCardSize))(tbl)) { mixin(S_TRACE);
		auto tblHasTarg = false;
		foreach (t; tbl) { mixin(S_TRACE);
			if (hasTarg(skin, t, forceRefresh, noCardSize)) { mixin(S_TRACE);
				tblHasTarg = true;
				break;
			}
		}
		if (tblHasTarg) { mixin(S_TRACE);
			_tbl = cast(int)items.length;
			items ~= _prop.msgs.defaultSelection(_prop.msgs.pathDef);
		}
		if ((!_summ || !_summ.legacy) && hasWsnTarg(forceRefresh, noCardSize)) { mixin(S_TRACE);
			_tblEngine = cast(int)items.length;
			auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
			auto i = .cCountUntil(VERSIONS, wsnVer);
			if (i == -1) i = .cCountUntil(VERSIONS, LATEST_VERSION);
			auto verName = VERSION_NAMES[i];
			items ~= _prop.msgs.defaultSelection(.tryFormat(_prop.msgs.pathWsnBasic, verName));
		}
		ptrdiff_t dirsIndexOf(string path) { mixin(S_TRACE);
			foreach (i, s; items) { mixin(S_TRACE);
				if (cfnmatch(s, path)) { mixin(S_TRACE);
					return i;
				}
			}
			return -1;
		}

		if (!_display) _display = _dirs.getDisplay();
		int dirsIndex = -1;

		auto subThr = !_dirs.isVisible();
		_loading = subThr;
		auto path = this.path;

		void update() { mixin(S_TRACE);
			size_t cut = 0;
			if (_summ) { mixin(S_TRACE);
				string st = _summ.scenarioPath;
				cut = st.length;
				static if (altDirSeparator.length) {
					if (!endsWith(st, dirSeparator) && !endsWith(st, altDirSeparator)) cut++;
				} else { mixin(S_TRACE);
					if (!endsWith(st, dirSeparator)) cut++;
				}
				items ~= searchTarg(skin, _summ.scenarioPath, forceRefresh, cut);
			}
			if (!select) { mixin(S_TRACE);
				void selectOld() { mixin(S_TRACE);
					if (oldSel < defs.length) { mixin(S_TRACE);
						dirsIndex = oldSel;
					} else { mixin(S_TRACE);
						auto index = dirsIndexOf(oldSelS);
						if (index >= 0) { mixin(S_TRACE);
							dirsIndex = cast(int)index;
						} else if (items.length > 0) { mixin(S_TRACE);
							dirsIndex = 0;
						}
					}
					static if (Type == MtType.CARD) {
						auto index = dirsIndex;
						if (index < defs.length) { mixin(S_TRACE);
							if (valueFromDef) { mixin(S_TRACE);
								auto defPath = valueFromDef(index, 0 < binPath.length, binPath);
								if (_paths[_imageIndex] != defPath) { mixin(S_TRACE);
									_paths[_imageIndex] = defPath;
									foreach (dlg; modEvent) dlg();
								}
							}
						}
					}
				}
				int index = -1;
				static if (Type == MtType.CARD) {
					if (valueToDef) { mixin(S_TRACE);
						index = valueToDef(_paths[_imageIndex], 0 < binPath.length);
					}
				} else {
					if (path.isBinImg && indexOfBinPath) { mixin(S_TRACE);
						index = indexOfBinPath(0 < binPath.length);
					}
				}
				if (0 <= index) { mixin(S_TRACE);
					dirsIndex = index;
				} else { mixin(S_TRACE);
					bool isSkinMaterial, isEngineMaterial;
					auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
					auto p = summSkin.findPathF(path, defExts, defDirs, _summ ? _summ.scenarioPath : "", wsnVer,
						engineDefDirs, isSkinMaterial, isEngineMaterial);
					if (p.length > 0) { mixin(S_TRACE);
						if (isSkinMaterial) { mixin(S_TRACE);
							if (_tbl == -1) { mixin(S_TRACE);
								// ファイルが無い
								selectOld();
							} else { mixin(S_TRACE);
								dirsIndex = _tbl;
							}
						} else if (isEngineMaterial) { mixin(S_TRACE);
							if (_tblEngine == -1) { mixin(S_TRACE);
								// ファイルが無い
								selectOld();
							} else { mixin(S_TRACE);
								dirsIndex = _tblEngine;
							}
						} else if (_summ) { mixin(S_TRACE);
							string pt = dirName(p);
							pt = pt.length <= cut ? dirSeparator.idup : pt[cut .. $];
							pt = toViewPath(pt);
							dirsIndex = cast(int)dirsIndexOf(pt);
						}
					} else { mixin(S_TRACE);
						selectOld();
					}
				}
			} else { mixin(S_TRACE);
				select = toViewPath(select);
				dirsIndex = cast(int)dirsIndexOf(select);
			}
			_selDir = dirsIndex;
			if (_selDir == -1 && items.length) { mixin(S_TRACE);
				_selDir = 0;
				dirsIndex = _selDir;
			}

			void updateList() { mixin(S_TRACE);
				setComboItems(_dirs, items);
				_dirs.select(dirsIndex);

				refreshList(forceRefresh, false);
			}
			if (subThr) { mixin(S_TRACE);
				_display.asyncExec(new class Runnable {
					override void run() { mixin(S_TRACE);
						if (_dirs.isDisposed()) return;
						updateList();
						_dirs.setEnabled(_enabled && !_readOnly);
						ptrdiff_t skinPos, enginePosFrom, enginePosTo;
						auto dirs = allDirs(skinPos, enginePosFrom, enginePosTo);
						_fileList.setEnabled(_enabled && !_readOnly && _summ);
					}
				});
			} else { mixin(S_TRACE);
				updateList();
			}
		}
		if (subThr) { mixin(S_TRACE);
			_dirs.setEnabled(false);
			_fileList.setEnabled(false);
			_comm.refreshToolBar();
			auto thr = new core.thread.Thread(&update);
			thr.start();
		} else { mixin(S_TRACE);
			update();
		}
	}

	void refPaths(Object sender, string parent) { mixin(S_TRACE);
		if (this !is sender) { mixin(S_TRACE);
			refreshPaths();
		}
		if (_refresh) _refresh();
	}
	void refPath(string o, string n, bool isDir) { mixin(S_TRACE);
		auto old = this.path;
		static if (Type == MtType.CARD) {
			foreach (i, path; _paths) { mixin(S_TRACE);
				if (i == _imageIndex) continue;
				if (path.type !is CardImageType.File) continue;
				if (o == path.path) _paths[i] = new CardImage(n, path.positionType); // 格納イメージは更新不要
			}
		}
		scope (exit) {
			if (old != this.path) {
				foreach (dlg; modEvent) dlg();
			}
		}
		if (isDir) { mixin(S_TRACE);
			auto defs = getDefs();
			int i = cast(int)defs.length;
			if (_tbl >= 0) i++;
			if (_tblEngine >= 0) i++;
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
			if (o == this.path) path2(n, true, false, -1, false);
			int di = _dirs.getSelectionIndex();
			auto op = o;
			if (di >= 0 && cfnmatch(fromViewPath(_dirs.getItems()[di]), dirName(o))) { mixin(S_TRACE);
				auto index = flIndexOf(baseName(o));
				if (index >= 0) { mixin(S_TRACE);
					string nName = baseName(n);
					static if (is(C : Table)) {
						_fileList.getItem(cast(int)index).setText(nName);
					} else static if (is(C : Combo) || is(C : CCombo)) {
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
		if (this.path == from) { mixin(S_TRACE);
			refreshPaths();
		}
	}
	void refreshButtons() { mixin(S_TRACE);
		_comm.refreshToolBar();
		static if (Type == MtType.BGM || Type == MtType.SE) refDataVersion();
	}
	void updateSkinMaterialsExtension() { mixin(S_TRACE);
		if (!selectedDefDir || path != "") return;
		string update(string path) { mixin(S_TRACE);
			if (path.isBinImg) return path;
			foreach (defDir; defDirs) { mixin(S_TRACE);
				if (std.path.buildPath(defDir, path).exists()) return path;
				foreach (ext; defExts) { mixin(S_TRACE);
					auto path2 = path.setExtension(ext);
					if (std.path.buildPath(defDir, path2).exists()) return path2;
				}
			}
			return path;
		}
		static if (Type == MtType.CARD) {
			foreach (i, path; _paths) {
				if (path.type !is CardImageType.File) continue;
				path2(update(path.path), true, false, i, false);
			}
		} else {
			path2(update(path), true, false, -1, false);
		}
	}
	void refSkin() { mixin(S_TRACE);
		updateSkinMaterialsExtension();
		refresh();
	}
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}
	string[] getDefs() { mixin(S_TRACE);
		auto r = _defs(0 < binPath.length);
		static if (Type == MtType.BGM) {
			if (canContinue || continueBGM) r ~= _prop.msgs.defaultSelection(_prop.msgs.continueBGM);
		}
		return r;
	}
	static if (Type == MtType.BGM) {
		@property
		ptrdiff_t continueIndex() { mixin(S_TRACE);
			return (canContinue || continueBGM) ? _defs(0 < binPath.length).length : -1;
		}
	}

	Display _display = null;
	int _readOnly = 0;
	bool _enabled = true;
	Props _prop;
	Commons _comm;
	D _dirs;
	Summary _summ;
	Button _dirBtn;
	IncSearch _incSearch;
	string[] delegate(bool included) _defs;
	int _selDir;
	bool _canInclude = false;
	bool _isMenuCard = false;
	int _tbl = -1;
	ptrdiff_t _tblIndex = -1;
	int _tblEngine = -1;
	ptrdiff_t _tblEngineIndex = -1;
	bool _fnone = false;
	C _fileList;
	bool _allList = false;
	void delegate() _refresh;
	Skin _summSkin;
	bool _processing = false;
	int _imageIndex = 0;
	bool _loading = false;
	static if (Type == MtType.CARD) {
		CardImage[] _paths = [];
		string[] _binPaths = [];
	} else {
		string _path = "";
		static if (Type == MtType.BG_IMG) {
			string[] _binPaths = [""];
		}
	}
	UndoManager _undo = null;
	void delegate() _store = null;
	bool _firstSet = true;
	bool delegate() _loadScaledImage = null;
	bool _scheduleRefreshPaths = false;
	bool _canIncSearch = false;
}

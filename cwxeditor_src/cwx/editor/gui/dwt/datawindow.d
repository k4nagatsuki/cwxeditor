
module cwx.editor.gui.dwt.datawindow;

import cwx.summary;
import cwx.event;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.skin;
import cwx.path;
import cwx.types;
import cwx.menu;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.areatable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.flagspane;
import cwx.editor.gui.dwt.summarydialog;
import cwx.editor.gui.dwt.dmenu;

import std.file;
import std.path;

import org.eclipse.swt.all;

class AbstractDataWindow(bool UseArea, bool UseFlag) : TopLevelPanel, SashPanel, TCPD {
private:
	Shell _parentShell;
	Commons _comm;
	Composite _win, _contPane;
	static if (UseArea) {
		AreaTable _areas;
	}
	static if (UseFlag) {
		FlagsPane _flags;
	}
	Props _prop;
	static if (UseArea && UseFlag) {
		CTabFolder tabf;
		CTabItem tabA;
		CTabItem tabF;
	}

	Summary _summ = null;

	TCPD _tcpd = null;

	static if (UseArea && UseFlag) {
		void selectedImpl() { mixin(S_TRACE);
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_comm.setStatusLine(tabf, _areas.statusLine);
				_tcpd = _areas;
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_comm.setStatusLine(tabf, _flags.statusLine);
				_tcpd = _flags;
			}
			_comm.refreshToolBar();
		}
		class SListener : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				selectedImpl();
			}
		}
	}
public:
	this (Commons comm, Props prop, Shell parentShell, Composite parent) { mixin(S_TRACE);
		_parentShell = parentShell;
		_prop = prop;
		_comm = comm;
		static if (UseArea) {
			_areas = new AreaTable(_comm, _prop, false, null);
		}
		static if (UseFlag) {
			_flags = new FlagsPane(_comm, _prop);
			_flags.setupTLP(this);
		}
		if (parent) construct(parent);
	}
	void reconstruct(Composite parent) { mixin(S_TRACE);
		if (_win && !_win.isDisposed()) return;
		construct(parent);
		if (_summ) refresh();
	}
	private void construct(Composite parent) { mixin(S_TRACE);
		Composite contPane;
		_win = new Composite(parent, SWT.NONE);
		contPane = _win;
		_contPane = contPane;
		_win.setData(new TLPData(this));
		contPane.setLayout(windowGridLayout(1, true));

		static if (UseArea) {
			_comm.refTableViewStyle.add(&refTableViewStyle);
		}
		_comm.refScenarioName.add(&refreshTitle);
		_comm.refScenarioPath.add(&refreshTitle);
		_comm.replText.add(&refreshTitle);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				static if (UseArea) {
					_comm.refTableViewStyle.remove(&refTableViewStyle);
				}
				_comm.refScenarioName.remove(&refreshTitle);
				_comm.refScenarioPath.remove(&refreshTitle);
				_comm.replText.remove(&refreshTitle);
			}
		});
		{ mixin(S_TRACE);
			static if (UseArea && UseFlag) {
				tabf = new CTabFolder(contPane, SWT.BORDER);
				tabf.setLayoutData(new GridData(GridData.FILL_BOTH));
				tabf.addSelectionListener(new SListener);

				_flags.construct(tabf);
				_areas.construct(tabf, _flags.flags);

				tabA = new CTabItem(tabf, SWT.NONE);
				tabA.setText(_prop.msgs.scenarioView);
				tabA.setControl(_areas.panel);
				tabF = new CTabItem(tabf, SWT.NONE);
				tabF.setText(_prop.msgs.variableView);
				tabF.setControl(_flags.widget);

				_tcpd = _areas;
			} else static if (UseArea) {
				_areas.construct(contPane, null);
				_areas.panel.setLayoutData(new GridData(GridData.FILL_BOTH));
				_tcpd = _areas;
			} else static if (UseFlag) {
				_flags.construct(contPane);
				_flags.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
				_tcpd = _flags;
			} else static assert (0);
		}

		appendMenuTCPD(_comm, this, this, true, true, true, true, true);
		static if (UseArea && UseFlag) {
			putMenuAction(MenuID.EditSummary, &editSummary, &canEditSummary);
		}
		static if (UseArea) {
			putMenuAction(MenuID.EditScene, () => openAreaScene(), &_areas.canOpenAreaScene);
			putMenuAction(MenuID.EditSceneDup, () => openAreaScene(true), &_areas.canOpenAreaScene);
			putMenuAction(MenuID.EditEvent, () => openAreaEvent(), &_areas.canOpenAreaEvent);
			putMenuAction(MenuID.EditEventDup, () => openAreaEvent(true), &_areas.canOpenAreaEvent);
			putMenuAction(MenuID.NewAreaDir, &createAreaDir, &canCreateAreaDir);
			putMenuAction(MenuID.NewArea, &createArea, &canCreateArea);
			putMenuAction(MenuID.NewBattle, &createBattle, &canCreateBattle);
			putMenuAction(MenuID.NewPackage, &createPackage, &canCreatePackage);
			putMenuAction(MenuID.ReNumbering, &_areas.reNumbering, &_areas.canReNumbering);
			putMenuAction(MenuID.SetStartArea, &_areas.setStartArea, &_areas.canSetStartArea);
		}
		static if (UseFlag) {
			putMenuAction(MenuID.NewFlagDir, &createFlagDir, &canCreateFlagDir);
			putMenuAction(MenuID.NewFlag, &createFlag, &canCreateFlag);
			putMenuAction(MenuID.NewStep, &createStep, &canCreateStep);
			putMenuAction(MenuID.EditProp, &_flags.edit, &_flags.canEdit);
		}
		putMenuAction(MenuID.ChangeVH, &changeVHSide, &canChangeVH);
		putMenuAction(MenuID.Undo, &undo, &canUndo);
		putMenuAction(MenuID.Redo, &redo, &canRedo);
		putMenuAction(MenuID.Up, &up, &canUp);
		putMenuAction(MenuID.Down, &down, &canDown);
		putMenuAction(MenuID.FindID, &replaceID, &canReplaceID);

		_comm.refScenarioName.add(&refreshTitle);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				_comm.refScenarioName.remove(&refreshTitle);
			}
		});
	}
	static if (UseArea) {
		@property
		AreaTable areas() { return _areas; }

		void refTableViewStyle() { mixin(S_TRACE);
			static if (UseFlag) {
				tabA.getControl().dispose();
				_areas.construct(tabf, _flags.flags);
				tabA.setControl(_areas.panel);
			} else {
				_areas.panel.dispose();
				_areas.construct(_contPane, null);
				_areas.panel.setLayoutData(new GridData(GridData.FILL_BOTH));
				_contPane.layout();
			}
			if (_summ) _areas.summary = _summ;
		}
	}
	@property
	override
	Composite shell() {return _win;}

	static if (UseArea) {
		@property
		bool canEditSummary() { mixin(S_TRACE);
			return _summ !is null;
		}
		@property
		bool canCreateAreaDir() { mixin(S_TRACE);
			return _summ !is null && _areas.canCreateDir;
		}
		@property
		bool canCreateArea() { mixin(S_TRACE);
			return _summ !is null;
		}
		@property
		alias canCreateArea canCreateBattle;
		@property
		alias canCreateArea canCreatePackage;
		void editSummary() { mixin(S_TRACE);
			if (!_summ) return;
			if (_win && !_win.isDisposed()) { mixin(S_TRACE);
				_areas.editSummary(_win.getShell());
			} else { mixin(S_TRACE);
				_areas.editSummary(_parentShell);
			}
		}

		private void openAreaScene(bool canDuplicate = false) { mixin(S_TRACE);
			_areas.openAreaScene(true, canDuplicate);
		}
		private void openAreaEvent(bool canDuplicate = false) { mixin(S_TRACE);
			_areas.openAreaEvent(true, canDuplicate);
		}

		/// エリアビューを開く。
		void openAreaScene(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
			_areas.openAreaScene(id, shellActivate, canDuplicate);
		}
		/// ditto
		void openAreaEvent(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
			_areas.openAreaEvent(id, shellActivate, canDuplicate);
		}
		/// ditto
		void openBattleScene(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
			_areas.openBattleScene(id, shellActivate, canDuplicate);
		}
		/// ditto
		void openBattleEvent(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
			_areas.openBattleEvent(id, shellActivate, canDuplicate);
		}
		/// ditto
		void openPackage(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
			_areas.openPackage(id, shellActivate, canDuplicate);
		}
		void createAreaDir() { mixin(S_TRACE);
			if (!_summ) return;
			_comm.openDataWin(false);
			_areas.createDir();
		}
		void createArea() { mixin(S_TRACE);
			if (!_summ) return;
			_comm.openDataWin(false);
			.forceFocus(_areas.table, false);
			_areas.createArea();
		}
		void createBattle() { mixin(S_TRACE);
			if (!_summ) return;
			_comm.openDataWin(false);
			.forceFocus(_areas.table, false);
			_areas.createBattle();
		}
		void createPackage() { mixin(S_TRACE);
			createPackage(null);
		}
		ulong createPackage(Content baseStart) { mixin(S_TRACE);
			if (!_summ) return 0;
			_comm.openDataWin(false);
			.forceFocus(_areas.table, false);
			return _areas.createPackage(baseStart);
		}
		void reNumberingAll() { mixin(S_TRACE);
			_areas.reNumberingAll();
		}
	}
	static if (UseFlag) {
		@property
		FlagsPane flags() { return _flags; }

		@property
		bool canCreateFlagDir() { mixin(S_TRACE);
			return _summ !is null;
		}
		@property
		alias canCreateFlagDir canCreateFlag;
		@property
		alias canCreateFlagDir canCreateStep;

		void createFlagDir() { mixin(S_TRACE);
			if (!_summ) return;
			_flags.dirs.createDir();
		}
		void createFlag() { mixin(S_TRACE);
			if (!_summ) return;
			_flags.flags.createFlag();
		}
		void createStep() { mixin(S_TRACE);
			if (!_summ) return;
			_flags.flags.createStep();
		}
	}
	static if (UseArea && UseFlag) {
		void selectData() { mixin(S_TRACE);
			tabf.setSelection(tabA);
			selectedImpl();
		}
		void selectFlags() { mixin(S_TRACE);
			tabf.setSelection(tabF);
			selectedImpl();
		}
		private void changeVHSide() { mixin(S_TRACE);
			if (tabf.getSelection() is tabA) {
				_areas.changeVHSide();
			} else {
				_flags.changeVHSide();
			}
		}
		private bool canChangeVH() { mixin(S_TRACE);
			if (tabf.getSelection() is tabA) {
				return _areas.canChangeVH();
			} else {
				return true;
			}
		}
	} else static if (UseArea) {
		private void changeVHSide() { mixin(S_TRACE);
			_areas.changeVHSide();
		}
		private bool canChangeVH() { mixin(S_TRACE);
			return _areas.canChangeVH();
		}
	} else static if (UseFlag) {
		private void changeVHSide() { mixin(S_TRACE);
			_flags.changeVHSide();
		}
		private bool canChangeVH() { mixin(S_TRACE);
			return true;
		}
	}

	@property
	override
	Image image() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			return _prop.images.menu(MenuID.TableView);
		} else static if (UseArea) {
			return _prop.images.menu(MenuID.TableView);
		} else static if (UseFlag) {
			return _prop.images.menu(MenuID.VarView);
		} else static assert (0);
	}
	@property
	override
	string title() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			return _prop.msgs.dataTabName;
		} else static if (UseArea) {
			return _prop.msgs.areasTabName;
		} else static if (UseFlag) {
			return _prop.msgs.flagTabName;
		} else static assert (0);
	}
	@property
	override
	void delegate(string) statusText() {return null;}

	private void refreshTitle() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		_comm.setTitle(_win, title);
	}
	private void refresh() { mixin(S_TRACE);
		refreshTitle();
		static if (UseArea) {
			_areas.summary = _summ;
			static if (UseFlag) {
				if (_win && !_win.isDisposed()) { mixin(S_TRACE);
					tabf.setSelection(tabA);
					selectedImpl();
				}
			}
		}
		static if (UseFlag) {
			_flags.setFlagDirTree(_summ.flagDirRoot, _summ.useCounter);
		}
	}

	@property
	bool canUp() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canUp();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				return _flags.canUp();
			}
		} else static if (UseArea) {
			return _areas.canUp();
		} else static if (UseFlag) {
			return _flags.canUp();
		} else static assert (0);
	}
	@property
	bool canDown() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canDown();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				return _flags.canDown();
			}
		} else static if (UseArea) {
			return _areas.canDown();
		} else static if (UseFlag) {
			return _flags.canDown();
		} else static assert (0);
	}
	void up() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.up();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_flags.up();
			}
		} else static if (UseArea) {
			_areas.up();
		} else static if (UseFlag) {
			_flags.up();
		} else static assert (0);
	}
	void down() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.down();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_flags.down();
			}
		} else static if (UseArea) {
			_areas.down();
		} else static if (UseFlag) {
			_flags.down();
		} else static assert (0);
	}

	/// 指定されたディレクトリにあるSummary.xmlからシナリオをロードする。
	/// Throws:
	/// SummaryException = ファイルはSummary定義のXML文書ではない。
	/// FileException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	/// FileLoadException = Summary.xml以外での読込例外発生時。
	void load(Summary summ) { mixin(S_TRACE);
		_summ = summ;
		refresh();
	}

	/// Returns: 貼り紙。
	@property
	Summary summary() { mixin(S_TRACE);
		return _summ;
	}
	static if (UseArea) {
		void selectSummary() { mixin(S_TRACE);
			_areas.selectSummary();
		}
	}

	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			assert (_tcpd !is null);
			if (_tcpd.canDoTCPD) { mixin(S_TRACE);
				_tcpd.cut(se);
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			assert (_tcpd !is null);
			if (_tcpd.canDoTCPD) { mixin(S_TRACE);
				_tcpd.copy(se);
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			assert (_tcpd !is null);
			if (_tcpd.canDoTCPD) { mixin(S_TRACE);
				_tcpd.paste(se);
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			assert (_tcpd !is null);
			if (_tcpd.canDoTCPD) { mixin(S_TRACE);
				_tcpd.del(se);
			}
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			assert (_tcpd !is null);
			if (_tcpd.canDoTCPD) { mixin(S_TRACE);
				_tcpd.clone(se);
			}
		}
		bool canDoTCPD() { mixin(S_TRACE);
			assert (_tcpd !is null);
			return .hasFocus(_win);
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			assert (_tcpd !is null);
			return _tcpd.canDoTCPD && _tcpd.canDoT;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			assert (_tcpd !is null);
			return _tcpd.canDoTCPD && _tcpd.canDoC;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			assert (_tcpd !is null);
			return _tcpd.canDoTCPD && _tcpd.canDoP;
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			assert (_tcpd !is null);
			return _tcpd.canDoTCPD && _tcpd.canDoD;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			assert (_tcpd !is null);
			return _tcpd.canDoTCPD && _tcpd.canDoClone;
		}
	}

	private bool openCWXPathAfCommon(A)(A a, ref string path, bool shellActivate) { mixin(S_TRACE);
		path = cpbottom(path);
		if (cpattr(path).contains("shallow") && cpempty(path)) { mixin(S_TRACE);
			if (!cphasattr(path, "nofocus")) .forceFocus(_areas.table, shellActivate);
			_areas.select(a);
			_comm.refreshToolBar();
			return true;
		}
		return false;
	}
	private bool openCWXPathAf(SceneWindow, EventWindow, A)(lazy SceneWindow sw, lazy EventWindow ew, A a, string path, bool shellActivate) { mixin(S_TRACE);
		if (openCWXPathAfCommon(a, path, shellActivate)) { mixin(S_TRACE);
			return true;
		}
		string cate = cpcategory(path);
		bool isScene = cpempty(path)
			|| ((cate == "menucard" || cate == "enemycard") && cpempty(cpbottom(path)))
			|| cate == "background";
		if (isScene && cphasattr(path, "eventview")) { mixin(S_TRACE);
			isScene = false;
		}
		string aPath = a.cwxPath(true);
		if (isScene) { mixin(S_TRACE);
			auto sw2 = _comm.areaWindowFrom(aPath, shellActivate);
			if (sw2) { mixin(S_TRACE);
				return sw2.openCWXPath(path, shellActivate);
			}
			return sw.openCWXPath(path, shellActivate);
		} else { mixin(S_TRACE);
			auto ew2 = _comm.eventWindowFrom(aPath, shellActivate);
			if (ew2) { mixin(S_TRACE);
				return ew2.openCWXPath(path, shellActivate);
			}
			return ew.openCWXPath(path, shellActivate);
		}
	}
	private bool openCWXPathAf(Window, A)(lazy Window w, A a, string path, bool shellActivate) { mixin(S_TRACE);
		if (openCWXPathAfCommon(a, path, shellActivate)) { mixin(S_TRACE);
			return true;
		}
		if (w) { mixin(S_TRACE);
			static if (UseArea && UseFlag) {
				tabf.setSelection(tabA);
				selectedImpl();
				_comm.refreshToolBar();
			}
			return w.openCWXPath(path, shellActivate);
		}
		return false;
	}
	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		if (cpempty(path)) { mixin(S_TRACE);
			static if (UseArea) {
				_comm.selectSummary(shellActivate);
				if (!cphasattr(path, "nofocus")) .forceFocus(_areas.table, shellActivate);
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					editSummary();
				}
			} else { mixin(S_TRACE);
				_comm.openFlagWin(shellActivate);
			}
			return true;
		}
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "area": { mixin(S_TRACE);
			static if (UseArea) {
				if (index >= _summ.areas.length) return false;
				auto a = _summ.areas[index];
				return openCWXPathAf(_comm.openAreaScene(_prop, _summ, a, shellActivate, false),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate, false),
					a, path, shellActivate);
			}
		} break;
		case "area:id": { mixin(S_TRACE);
			static if (UseArea) {
				auto a = _summ.area(index);
				return openCWXPathAf(_comm.openAreaScene(_prop, _summ, a, shellActivate, false),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate, false),
					a, path, shellActivate);
			}
		} break;
		case "battle": { mixin(S_TRACE);
			static if (UseArea) {
				if (index >= _summ.battles.length) return false;
				auto a = _summ.battles[index];
				return openCWXPathAf(_comm.openAreaScene(_prop, _summ, a, shellActivate, false),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate, false),
					a, path, shellActivate);
			}
		} break;
		case "battle:id": { mixin(S_TRACE);
			static if (UseArea) {
				auto a = _summ.battle(index);
				return openCWXPathAf(_comm.openAreaScene(_prop, _summ, a, shellActivate, false),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate, false),
					a, path, shellActivate);
			}
		} break;
		case "package": { mixin(S_TRACE);
			static if (UseArea) {
				if (index >= _summ.packages.length) return false;
				auto a = _summ.packages[index];
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate, false),
					a, path, shellActivate);
			}
		} break;
		case "package:id": { mixin(S_TRACE);
			static if (UseArea) {
				auto a = _summ.cwPackage(index);
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate, false),
					a, path, shellActivate);
			}
		} break;
		case "tableview": { mixin(S_TRACE);
			static if (UseArea) {
				.forceFocus(_areas.table, shellActivate);
				return true;
			}
		} break;
		case "variable": { mixin(S_TRACE);
			static if (UseFlag) {
				return _flags.openCWXPath(cpbottom(path), shellActivate);
			}
		} break;
		case "variableview": { mixin(S_TRACE);
			static if (UseFlag) {
				.forceFocus(_flags.flags.widget, shellActivate);
				return true;
			}
		} break;
		default: break;
		}
		return false;
	}
	@property
	override
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				auto a = _areas.openedCWXPath;
				auto b = _flags.openedCWXPath;
				if (!a.length) r ~= "tableview";
				if (!b.length) r ~= "variableview";
				r ~= a ~ b;
			} else { mixin(S_TRACE);
				auto a = _flags.openedCWXPath;
				auto b = _areas.openedCWXPath;
				if (!a.length) r ~= "variableview";
				if (!b.length) r ~= "tableview";
				r ~= a ~ b;
			}
		} else static if (UseArea) {
			r ~= _areas.openedCWXPath;
			if (!r.length) r ~= "tableview";
		} else static if (UseFlag) {
			r ~= _flags.openedCWXPath;
			if (!r.length) r ~= "variableview";
		} else static assert (0);
		return r;
	}

	@property
	bool canUndo() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canUndo();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				return _flags.canUndo();
			}
		} else static if (UseArea) {
			return _areas.canUndo();
		} else static if (UseFlag) {
			return _flags.canUndo();
		} else static assert (0);
	}
	@property
	bool canRedo() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canRedo();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				return _flags.canRedo();
			}
		} else static if (UseArea) {
			return _areas.canRedo();
		} else static if (UseFlag) {
			return _flags.canRedo();
		} else static assert (0);
	}
	void undo() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.undo();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_flags.undo();
			}
		} else static if (UseArea) {
			_areas.undo();
		} else static if (UseFlag) {
			_flags.undo();
		} else static assert (0);
	}
	void redo() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.redo();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_flags.redo();
			}
		} else static if (UseArea) {
			_areas.redo();
		} else static if (UseFlag) {
			_flags.redo();
		} else static assert (0);
	}
	void replaceID() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.replaceID();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_flags.replaceID();
			}
		} else static if (UseArea) {
			_areas.replaceID();
		} else static if (UseFlag) {
			_flags.replaceID();
		} else static assert (0);
	}
	@property
	bool canReplaceID() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canReplaceID;
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				return _flags.canReplaceID;
			}
		} else static if (UseArea) {
			return _areas.canReplaceID;
		} else static if (UseFlag) {
			return _flags.canReplaceID;
		} else static assert (0);
	}
}

alias AbstractDataWindow!(true, false) TableWindow;
alias AbstractDataWindow!(false, true) FlagWindow;

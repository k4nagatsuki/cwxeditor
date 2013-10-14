
module cwx.editor.gui.dwt.cardwindow;

import cwx.card;
import cwx.summary;
import cwx.utils;
import cwx.usecounter;
import cwx.types;
import cwx.xml;
import cwx.skin;
import cwx.path;
import cwx.motion;
import cwx.menu;
import cwx.types;
import cwx.system;

import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.cardlist;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.castcarddialog;
import cwx.editor.gui.dwt.effectcarddialog;
import cwx.editor.gui.dwt.infocarddialog;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.cardpane;
import cwx.editor.gui.dwt.loader;
import cwx.editor.gui.dwt.dmenu;

import std.algorithm;
import std.array;
import std.utf;
import std.string;
import std.datetime;
import std.typetuple;
import std.path;

import org.eclipse.swt.all;

import java.lang.all;

public:

// TODO エリア類のインポート

interface ICardWindow {
	@property
	bool canCreateCast();
	@property
	bool canCreateSkill();
	@property
	bool canCreateItem();
	@property
	bool canCreateBeast();
	@property
	bool canCreateInfo();
	void createCast();
	void createSkill();
	void createItem();
	void createBeast();
	void createInfo();
}

enum CardWindowKind {
	Main,
	Cast,
	Skill,
	Item,
	Beast,
	Info,
	Hand,
	ImportSource,
	ImportSourceHand,
}

/// カード関係の表示・編集領域。
class CardWindow(CardWindowKind CWKind, PCardOwner, CardOwner, ToCardOwner, Cards ...)
		: TopLevelPanel, TCPD, ICardWindow {
private:
	static const bool EditMode = is (ToCardOwner == void);
	static const bool UseCast = IndexOf!(CastCard, Cards) >= 0;
	static const bool UseSkill = IndexOf!(SkillCard, Cards) >= 0;
	static const bool UseItem = IndexOf!(ItemCard, Cards) >= 0;
	static const bool UseBeast = IndexOf!(BeastCard, Cards) >= 0;
	static const bool UseInfo = IndexOf!(InfoCard, Cards) >= 0;

	template Pane(Card) {
		mixin ("alias " ~ Card.stringof ~ "Pane!(PCardOwner, CardOwner, ToCardOwner) Pane;");
	}

	template CTypes(int Index, Cards ...) {
		static if (is(Cards[0] : CastCard)) {
			static const CAST = Index;
		} else static if (is(Cards[0] : SkillCard)) {
			static const SKILL = Index;
		} else static if (is(Cards[0] : ItemCard)) {
			static const ITEM = Index;
		} else static if (is(Cards[0] : BeastCard)) {
			static const BEAST = Index;
		} else static if (is(Cards[0] : InfoCard)) {
			static const INFO = Index;
		} else static assert (0);
		static if (Cards.length > 1) {
			mixin CTypes!(Index + 1, Cards[1 .. $]);
		}
	}
	mixin CTypes!(0, Cards);
	template PTypes(Cards ...) {
		static if (Cards.length > 1) {
			alias TypeTuple!(Pane!(Cards[0]),
				PTypes!(Cards[1 .. $])) PTypes;
		} else {
			alias TypeTuple!(Pane!(Cards[0])) PTypes;
		}
	}
	PTypes!(Cards) _pane;
	static if (1 < Cards.length) {
		CTabFolder _tabf;
		CTabItem[Cards.length] _tab;
	} else {
		Composite _tabf;
	}

	Props _prop;
	SBShell _sbshl;
	Composite _win;
	Composite _comp;
	PCardOwner _summ;
	CardOwner _owner;
	Commons _comm;

	CViewMode _viewMode = CViewMode.INIT;
	MenuItem _lifeM;
	MenuItem _listM;
	MenuItem _tblM;
	ToolItem _lifeT;
	ToolItem _listT;
	ToolItem _tblT;

	TCPD[] _tcpd;

	static if (!EditMode) {
		ToCardOwner _toc;
	}
	static if (EditMode) {
		void create(int Index)() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				if (_tabf && !_tabf.isDisposed()) { mixin(S_TRACE);
					_tabf.setSelection(_tab[Index]);
				}
			}
			_pane[Index].create();
		}
	}
	static if (EditMode) {
		void open(int Index)(bool shellActivate) { mixin(S_TRACE);
			static if (is(CardOwner : Summary)) {
				static if (1 < Cards.length) {
					_comm.openBindCardWin(shellActivate);
					_tabf.setSelection(_tab[Index]);
				} else { mixin(S_TRACE);
					static if (UseCast && CAST == Index) {
						_comm.openCastWin(shellActivate);
					} else static if(UseSkill && SKILL == Index) { mixin(S_TRACE);
						_comm.openSkillWin(shellActivate);
					} else static if(UseItem && ITEM == Index) { mixin(S_TRACE);
						_comm.openItemWin(shellActivate);
					} else static if(UseBeast && BEAST == Index) { mixin(S_TRACE);
						_comm.openBeastWin(shellActivate);
					} else static if(UseInfo && INFO == Index) { mixin(S_TRACE);
						_comm.openInfoWin(shellActivate);
					} else static assert (0);
				}
			} else { mixin(S_TRACE);
				_tabf.setSelection(_tab[Index]);
			}
		}
	}

	void __refresh() { mixin(S_TRACE);
		foreach (f; _pane) { mixin(S_TRACE);
			f.refresh();
		}
		refreshTitle();
	}
	static if (EditMode && is (CardOwner == Summary)) {
		void addScenario() { mixin(S_TRACE);
			_comm.addScenario(_prop);
		}
		class DropScenario : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
				e.detail = DND.DROP_LINK;
			}
			override void drop(DropTargetEvent e) { mixin(S_TRACE);
				auto arr = cast(FileNames) e.data;
				if (arr && arr.array.length > 0) { mixin(S_TRACE);
					_comm.addScenario(_prop, arr.array);
				}
			}
		}
	}
	@property
	Shell dlgParShl() { mixin(S_TRACE);
		if (_win && !_win.isDisposed()) return _win.getShell();
		return _comm.mainWin.shell.getShell();
	}
	static if (UseCast && !EditMode) {
		void openHand() { mixin(S_TRACE);
			auto sels = _pane[CAST].selectedCards;
			foreach (sel; sels) { mixin(S_TRACE);
				_comm.openAddHands(_prop, _summ, sel, _toc, true);
			}
		}
	}
public:
	static if (EditMode) {
		static if (is (CardOwner == Summary)) {
			this (Commons comm, Props prop, Composite parent) { mixin(S_TRACE);
				_comm = comm;
				_prop = prop;
				if (parent) { mixin(S_TRACE);
					construct(comm, prop, null, parent);
				} else { mixin(S_TRACE);
					initPane!(0)();
				}
			}
			void reconstruct(Composite parent) { mixin(S_TRACE);
				if (_win && !_win.isDisposed()) return;
				construct(_comm, _prop, _summ, parent);
				if (_owner) refresh(_owner);
			}
		} else {
			this(Commons comm, Props prop, PCardOwner summ, Composite parent) { mixin(S_TRACE);
				construct(comm, prop, summ, parent);
			}
		}
		void construct(Commons comm, Props prop, PCardOwner summ, Composite parent) { mixin(S_TRACE);
			_viewMode = CViewMode.INIT;
			construct1(comm, prop, parent);
			static if (is (CardOwner == Summary)) {
				auto shell = cast(Shell) _win;
				if (shell) { mixin(S_TRACE);
					shell.addShellListener(new class ShellAdapter {
						override void shellClosed(ShellEvent e) { mixin(S_TRACE);
							(cast(Shell) e.widget).setVisible(false);
							e.doit = false;
							_prop.var.cardWin.visible = false;
						}
					});
				}
			}
			static if (is (CardOwner == CastCard) && is (PCardOwner == Summary)) {
				_comm.refCast.add(&__refOwner);
				_comm.delCast.add(&__delOwner);
				_win.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
						_comm.refCast.remove(&__refOwner);
						_comm.delCast.remove(&__delOwner);
					}
				});
			}
			construct2();
			_comm.refScenarioName.add(&refreshTitle);
			_comm.refScenarioPath.add(&refreshTitle);
			_win.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					_comm.refScenarioName.remove(&refreshTitle);
					_comm.refScenarioPath.remove(&refreshTitle);
				}
			});
		}
		void initPane(int Index)() { mixin(S_TRACE);
			assert (!_pane[Index]);
			_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, SWT.BORDER);
			static if (Index + 1 < Cards.length) {
				initPane!(Index + 1)();
			}
		}
		void newPane(int Index)() { mixin(S_TRACE);
			if (_pane[Index]) { mixin(S_TRACE);
				_pane[Index].reconstruct(_tabf, SWT.BORDER);
			} else { mixin(S_TRACE);
				_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, SWT.BORDER);
				_pane[Index].construct();
			}
			static if (Index + 1 < Cards.length) {
				newPane!(Index + 1)();
			}
		}
	} else {
		void newPane(int Index)() { mixin(S_TRACE);
			if (_pane[Index]) { mixin(S_TRACE);
				_pane[Index].reconstruct(_tabf, SWT.BORDER);
			} else { mixin(S_TRACE);
				static if (UseCast && Index == CAST) {
					_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, SWT.BORDER, _toc, &openHand);
				} else { mixin(S_TRACE);
					_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, SWT.BORDER, _toc);
				}
				_pane[Index].construct();
			}
			static if (Index + 1 < Cards.length) {
				newPane!(Index + 1)();
			}
		}
		this (Commons comm, Props prop,
				Composite parent, PCardOwner summ, CardOwner owner, ToCardOwner toc) { mixin(S_TRACE);
			_toc = toc;
			construct1(comm, prop, parent);
			static if (is (CardOwner == CastCard)) {
				_comm.closeAdds.add(&__closeAdds);
				_win.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
						_comm.closeAdds.remove(&__closeAdds);
					}
				});
			}
			static if (is (CardOwner == Summary)) {
				_win.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
						_comm.closeAdds.call(_summ);
					}
				});
			}
			_summ = summ;
			construct2();
			__refreshAll(summ, owner);
		}
	}
	private void construct1(Commons comm, Props prop, Composite parent) { mixin(S_TRACE);
		_comm = comm;
		_prop = prop;
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		Composite contPane;
		if (parShl) { mixin(S_TRACE);
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImages(_prop.images.icon);
			_win = shell;
			contPane = _sbshl.contentPane;
		} else { mixin(S_TRACE);
			_win = new Composite(parent, SWT.NONE);
			contPane = _win;
		}
		_win.setData(new TLPData(this));
		contPane.setLayout(new FillLayout);
		_comp = new Composite(contPane, SWT.NONE);
		_comp.setLayout(windowGridLayout(1, true));
		if (shell) { mixin(S_TRACE);
			{ mixin(S_TRACE);
				auto bar = new Menu(shell, SWT.BAR);

				auto mf = createMenu(_comm, bar, MenuID.File);
				createMenuItem(_comm, mf, MenuID.CloseWin, &shell.close, null);

				auto me = createMenu(_comm, bar, MenuID.Edit);
				static if (EditMode) {
					createMenuItem(_comm, me, MenuID.Undo, &undo, &canUndo);
					createMenuItem(_comm, me, MenuID.Redo, &redo, &canRedo);
					new MenuItem(me, SWT.SEPARATOR);
					appendMenuTCPD(_comm, me, this, true, true, true, true, true);
					new MenuItem(me, SWT.SEPARATOR);
					createMenuItem(_comm, me, MenuID.Up, &up, &canUp);
					createMenuItem(_comm, me, MenuID.Down, &down, &canDown);
				} else { mixin(S_TRACE);
					createMenuItem(_comm, me, MenuID.Import, &doImport, &canDoImport);
					new MenuItem(me, SWT.SEPARATOR);
					appendMenuTCPD(_comm, me, this, false, true, false, false, false);
				}

				auto mv = createMenu(_comm, bar, MenuID.View);
				static if (EditMode) {
					createMenuItem(_comm, mv, MenuID.Refresh, &__refresh, () => _summ !is null);
					new MenuItem(mv, SWT.SEPARATOR);
				}
				_lifeM = createMenuItem(_comm, mv, MenuID.ShowCardProp, &showCardLife, null, SWT.RADIO);
				_listM = createMenuItem(_comm, mv, MenuID.ShowCardImage, &showCardList, null, SWT.RADIO);
				_tblM = createMenuItem(_comm, mv, MenuID.ShowCardDetail, &showCardTable, null, SWT.RADIO);

				static if (EditMode) {
					auto mt = createMenu(_comm, bar, MenuID.Card);
					static if (is (CardOwner == Summary)) {
						createMenuItem(_comm, mt, MenuID.OpenImportSource, &addScenario, () => _summ !is null);
						new MenuItem(mt, SWT.SEPARATOR);
					}
					static if (UseCast) createMenuItem(_comm, mt, MenuID.NewCast, &create!(CAST), () => _summ !is null);
					static if (UseSkill) createMenuItem(_comm, mt, MenuID.NewSkill, &create!(SKILL), () => _summ !is null);
					static if (UseItem) createMenuItem(_comm, mt, MenuID.NewItem, &create!(ITEM), () => _summ !is null);
					static if (UseBeast) createMenuItem(_comm, mt, MenuID.NewBeast, &create!(BEAST), () => _summ !is null);
					static if (UseInfo) createMenuItem(_comm, mt, MenuID.NewInfo, &create!(INFO), () => _summ !is null);
				}
				shell.setMenuBar(bar);
			}
			{ mixin(S_TRACE);
				auto bar = new ToolBar(_comp, SWT.FLAT);
				_comm.put(bar);
				static if (EditMode) {
					static if (is (CardOwner == Summary)) {
						createToolItem(_comm, bar, MenuID.OpenImportSource, &addScenario, () => _summ !is null);
						new ToolItem(bar, SWT.SEPARATOR);
					}
				}
				static if (EditMode) {
					createToolItem(_comm, bar, MenuID.Refresh, &__refresh, () => _summ !is null);
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.Up, &up, &canUp);
					createToolItem(_comm, bar, MenuID.Down, &down, &canDown);
					new ToolItem(bar, SWT.SEPARATOR);
					static if (UseCast) createToolItem(_comm, bar, MenuID.NewCast, &create!(CAST), () => _summ !is null);
					static if (UseSkill) createToolItem(_comm, bar, MenuID.NewSkill, &create!(SKILL), () => _summ !is null);
					static if (UseItem) createToolItem(_comm, bar, MenuID.NewItem, &create!(ITEM), () => _summ !is null);
					static if (UseBeast) createToolItem(_comm, bar, MenuID.NewBeast, &create!(BEAST), () => _summ !is null);
					static if (UseInfo) createToolItem(_comm, bar, MenuID.NewInfo, &create!(INFO), () => _summ !is null);
				} else { mixin(S_TRACE);
					createToolItem(_comm, bar, MenuID.Import, &doImport, &canDoImport);
				}
				new ToolItem(bar, SWT.SEPARATOR);
				_lifeT = createToolItem(_comm, bar, MenuID.ShowCardProp, &showCardLife, null, SWT.RADIO);
				_listT = createToolItem(_comm, bar, MenuID.ShowCardImage, &showCardList, null, SWT.RADIO);
				_tblT = createToolItem(_comm, bar, MenuID.ShowCardDetail, &showCardTable, null, SWT.RADIO);
			}
		} else { mixin(S_TRACE);
			static if (EditMode) {
				appendMenuTCPD(_comm, this, this, true, true, true, true, true);
				putMenuAction(MenuID.Refresh, &__refresh, () => _summ !is null);
				static if (is (CardOwner == Summary)) {
					putMenuAction(MenuID.OpenImportSource, &addScenario, () => _summ !is null);
				}
				putMenuAction(MenuID.Undo, &undo, &canUndo);
				putMenuAction(MenuID.Redo, &redo, &canRedo);
				static if (UseCast) {
					putMenuAction(MenuID.NewCast, &create!(CAST), () => _summ !is null);
					putMenuAction(MenuID.OpenHand, &editHand, &canEditHand);
				}
				static if (UseSkill) putMenuAction(MenuID.NewSkill, &create!(SKILL), () => _summ !is null);
				static if (UseItem) putMenuAction(MenuID.NewItem, &create!(ITEM), () => _summ !is null);
				static if (UseBeast) putMenuAction(MenuID.NewBeast, &create!(BEAST), () => _summ !is null);
				static if (UseInfo) putMenuAction(MenuID.NewInfo, &create!(INFO), () => _summ !is null);
				putMenuAction(MenuID.Up, &up, &canUp);
				putMenuAction(MenuID.Down, &down, &canDown);
				putMenuAction(MenuID.FindID, &replaceID, &canReplaceID);
				putMenuAction(MenuID.EditProp, &edit, &canEdit);
				putMenuAction(MenuID.ReNumbering, &reNumbering, &canReNumbering);
				static if (is(CardOwner:CastCard)) {
					putMenuAction(MenuID.RemoveRef, &removeRef, &canRemoveRef);
				}
			} else { mixin(S_TRACE);
				appendMenuTCPD(_comm, this, this, false, true, false, false, false);
				putMenuAction(MenuID.ShowProp, &edit, &canEdit);
				static if (UseCast) {
					putMenuAction(MenuID.OpenHand, &editHand, &canEditHand);
				}
				putMenuAction(MenuID.Import, &doImport, &canDoImport);
			}
			static if (UseSkill || UseItem || UseBeast) {
				putMenuAction(MenuID.EditEventAtTimeOfUsing, &editUseEvent, &canEditUseEvent);
			}
			putMenuChecked(MenuID.ShowCardProp, &showCardLife, &isViewLife, null);
			putMenuChecked(MenuID.ShowCardImage, &showCardList, &isViewList, null);
			putMenuChecked(MenuID.ShowCardDetail, &showCardTable, &isViewTable, null);
		}
		static if (1 < Cards.length) {
			_tabf = new CTabFolder(_comp, SWT.BORDER);
			_tabf.addSelectionListener(new SelChanged);
		} else { mixin(S_TRACE);
			_tabf = new Composite(_comp, SWT.NONE);
			_tabf.setLayout(zeroGridLayout(1, true));
		}
		_tabf.setLayoutData(new GridData(GridData.FILL_BOTH));

		static if (EditMode && is (CardOwner == Summary)) {
			auto drop = new DropTarget(_comp, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance()]);
			drop.addDropListener(new DropScenario);
		}
	}
	static if (1 < Cards.length) {
		private class SelChanged : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				refreshStatusLine();
				_comm.refreshToolBar();
			}
		}
	}
	static if (EditMode) {
		void reNumberingAll() { mixin(S_TRACE);
			foreach (f; _pane) { mixin(S_TRACE);
				f.reNumbering(0, 1);
			}
		}
	}
	void showCardLife() { mixin(S_TRACE);
		if (_viewMode != CViewMode.LIFE) { mixin(S_TRACE);
			_viewMode = CViewMode.LIFE;
			if (_win && !_win.isDisposed()) { mixin(S_TRACE);
				if (_listM) { mixin(S_TRACE);
					_lifeM.setSelection(true);
					_lifeT.setSelection(true);
					_listM.setSelection(false);
					_listT.setSelection(false);
					_tblM.setSelection(false);
					_tblT.setSelection(false);
				}
				foreach (i, f; _pane) { mixin(S_TRACE);
					f.showCardLife();
				}
			}
			static if (EditMode && is (CardOwner == Summary)) {
				_prop.var.etc.cardLife = true;
				_prop.var.etc.cardDetails = false;
			}
			refreshStatusLine();
		}
	}
	void showCardList() { mixin(S_TRACE);
		if (_viewMode != CViewMode.CARD) { mixin(S_TRACE);
			_viewMode = CViewMode.CARD;
			if (_win && !_win.isDisposed()) { mixin(S_TRACE);
				if (_listM) { mixin(S_TRACE);
					_lifeM.setSelection(false);
					_lifeT.setSelection(false);
					_listM.setSelection(true);
					_listT.setSelection(true);
					_tblM.setSelection(false);
					_tblT.setSelection(false);
				}
				foreach (i, f; _pane) { mixin(S_TRACE);
					f.showCardList();
				}
			}
			static if (EditMode && is (CardOwner == Summary)) {
				_prop.var.etc.cardLife = false;
				_prop.var.etc.cardDetails = false;
			}
			refreshStatusLine();
		}
	}
	void showCardTable() { mixin(S_TRACE);
		if (_viewMode != CViewMode.TABLE) { mixin(S_TRACE);
			_viewMode = CViewMode.TABLE;
			if (_win && !_win.isDisposed()) { mixin(S_TRACE);
				if (_listM) { mixin(S_TRACE);
					_lifeM.setSelection(false);
					_lifeT.setSelection(false);
					_listM.setSelection(false);
					_listT.setSelection(false);
					_tblM.setSelection(true);
					_tblT.setSelection(true);
				}
				foreach (i, f; _pane) { mixin(S_TRACE);
					f.showCardTable();
				}
			}
			static if (EditMode && is (CardOwner == Summary)) {
				_prop.var.etc.cardLife = false;
				_prop.var.etc.cardDetails = true;
			}
			refreshStatusLine();
		}
	}

	void setStatusLine(string status) { mixin(S_TRACE);
		auto w = _win;
		if (w.isDisposed()) { mixin(S_TRACE);
			w = null;
		}
		_comm.setStatusLine(w, status);
	}

	static if (EditMode && is(CardOwner : Summary)) {
		CastCardPane!(PCardOwner, CardOwner, ToCardOwner) openCast(bool shellActivate) { mixin(S_TRACE);
			static if (UseCast) {
				open!(CAST)(shellActivate);
				return _pane[CAST];
			} else { mixin(S_TRACE);
				throw new Exception("can not open cast");
			}
		}
		SkillCardPane!(PCardOwner, CardOwner, ToCardOwner) openSkill(bool shellActivate) { mixin(S_TRACE);
			static if (UseSkill) {
				open!(SKILL)(shellActivate);
				return _pane[SKILL];
			} else { mixin(S_TRACE);
				throw new Exception("can not open skill");
			}
		}
		ItemCardPane!(PCardOwner, CardOwner, ToCardOwner) openItem(bool shellActivate) { mixin(S_TRACE);
			static if (UseItem) {
				open!(ITEM)(shellActivate);
				return _pane[ITEM];
			} else { mixin(S_TRACE);
				throw new Exception("can not open item");
			}
		}
		BeastCardPane!(PCardOwner, CardOwner, ToCardOwner) openBeast(bool shellActivate) { mixin(S_TRACE);
			static if (UseBeast) {
				open!(BEAST)(shellActivate);
				return _pane[BEAST];
			} else { mixin(S_TRACE);
				throw new Exception("can not open beast");
			}
		}
		InfoCardPane!(PCardOwner, CardOwner, ToCardOwner) openInfo(bool shellActivate) { mixin(S_TRACE);
			static if (UseInfo) {
				open!(INFO)(shellActivate);
				return _pane[INFO];
			} else { mixin(S_TRACE);
				throw new Exception("can not open info");
			}
		}
		static if (UseCast) {
			@property
			CastCardPane!(PCardOwner, CardOwner, ToCardOwner) paneCast() { mixin(S_TRACE);
				return _pane[CAST];
			}
		}
		static if (UseSkill) {
			@property
			SkillCardPane!(PCardOwner, CardOwner, ToCardOwner) paneSkill() { mixin(S_TRACE);
				return _pane[SKILL];
			}
		}
		static if (UseItem) {
			@property
			ItemCardPane!(PCardOwner, CardOwner, ToCardOwner) paneItem() { mixin(S_TRACE);
				return _pane[ITEM];
			}
		}
		static if (UseBeast) {
			@property
			BeastCardPane!(PCardOwner, CardOwner, ToCardOwner) paneBeast() { mixin(S_TRACE);
				return _pane[BEAST];
			}
		}
		static if (UseInfo) {
			@property
			InfoCardPane!(PCardOwner, CardOwner, ToCardOwner) paneInfo() { mixin(S_TRACE);
				return _pane[INFO];
			}
		}
	}
	void createCast() { mixin(S_TRACE);
		if (!_summ) return;
		static if (EditMode && UseCast) {
			create!(CAST)();
		} else { mixin(S_TRACE);
			throw new Exception("can not create cast");
		}
	}
	void createSkill() { mixin(S_TRACE);
		if (!_summ) return;
		static if (EditMode && UseSkill) {
			create!(SKILL)();
		} else { mixin(S_TRACE);
			throw new Exception("can not create skill");
		}
	}
	void createItem() { mixin(S_TRACE);
		if (!_summ) return;
		static if (EditMode && UseItem) {
			create!(ITEM)();
		} else { mixin(S_TRACE);
			throw new Exception("can not create item");
		}
	}
	void createBeast() { mixin(S_TRACE);
		if (!_summ) return;
		static if (EditMode && UseBeast) {
			create!(BEAST)();
		} else { mixin(S_TRACE);
			throw new Exception("can not create beast");
		}
	}
	void createInfo() { mixin(S_TRACE);
		if (!_summ) return;
		static if (EditMode && UseInfo) {
			create!(INFO)();
		} else { mixin(S_TRACE);
			throw new Exception("can not create info");
		}
	}
	@property
	bool canCreateCast() {return EditMode && UseCast;}
	@property
	bool canCreateSkill() {return EditMode && UseSkill;}
	@property
	bool canCreateItem() {return EditMode && UseItem;}
	@property
	bool canCreateBeast() {return EditMode && UseBeast;}
	@property
	bool canCreateInfo() {return EditMode && UseInfo;}
	@property
	private bool isViewLife() { mixin(S_TRACE);
		return _viewMode == CViewMode.LIFE;
	}
	@property
	private bool isViewList() { mixin(S_TRACE);
		return _viewMode == CViewMode.CARD;
	}
	@property
	private bool isViewTable() { mixin(S_TRACE);
		return _viewMode == CViewMode.TABLE;
	}
	static if (!EditMode || !is(CardOwner : Summary)) {
		private static class ColResize : ControlAdapter {
			bool procRefColWidth = false;
			Commons comm;
			TableColumn[] cols;
			override void controlResized(ControlEvent e) { mixin(S_TRACE);
				if (procRefColWidth) return;
				procRefColWidth = true;
				scope (exit) procRefColWidth = false;
				auto c = cast(TableColumn) e.widget;
				int width = c.getWidth();
				foreach (col; cols) { mixin(S_TRACE);
					if (c !is col) { mixin(S_TRACE);
						col.setWidth(width);
					}
				}
			}
		}
	}
	private void construct2() { mixin(S_TRACE);
		newPane!(0)();
		static if (!EditMode || !is(CardOwner : Summary)) {
			ColResize[CardTableColumn] colR;
			void addTable(TableColumn[CardTableColumn] columns) { mixin(S_TRACE);
				foreach (i, col; columns) { mixin(S_TRACE);
					if (i !in colR) { mixin(S_TRACE);
						colR[i] = new ColResize;
						colR[i].comm = _comm;
					}
					colR[i].cols ~= col;
					col.addControlListener(colR[i]);
				}
			}
		}
		foreach (i, f; _pane) { mixin(S_TRACE);
			static if (1 < Cards.length) {
				_tab[i] = new CTabItem(_tabf, SWT.NONE);
				static if (UseCast) {
					if (i == CAST) { mixin(S_TRACE);
						_tab[i].setText(_prop.msgs.cwCast);
						_tab[i].setImage(_prop.images.casts);
					}
				}
				static if (UseSkill) {
					if (i == SKILL) { mixin(S_TRACE);
						_tab[i].setText(_prop.msgs.skill);
						_tab[i].setImage(_prop.images.skill);
					}
				}
				static if (UseItem) {
					if (i == ITEM) { mixin(S_TRACE);
						_tab[i].setText(_prop.msgs.item);
						_tab[i].setImage(_prop.images.item);
					}
				}
				static if (UseBeast) {
					if (i == BEAST) { mixin(S_TRACE);
						_tab[i].setText(_prop.msgs.beast);
						_tab[i].setImage(_prop.images.beast);
					}
				}
				static if (UseInfo) {
					if (i == INFO) { mixin(S_TRACE);
						_tab[i].setText(_prop.msgs.info);
						_tab[i].setImage(_prop.images.info);
					}
				}
				_tab[i].setControl(_pane[i].pane);
			} else { mixin(S_TRACE);
				_pane[i].pane.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
			_tcpd ~= f;
			static if (!EditMode || !is(CardOwner : Summary)) {
				addTable(f.columns);
			}
		}
		auto shell = cast(Shell) _win;

		static if (1 < Cards.length) {
			_tabf.setSelection(0);
		}
		bool life = _prop.var.etc.cardLife;
		bool detail = _prop.var.etc.cardDetails;
		if (!life && detail) { mixin(S_TRACE);
			showCardTable();
		} else if (life) { mixin(S_TRACE);
			showCardLife();
		} else { mixin(S_TRACE);
			showCardList();
		}
		if (shell) { mixin(S_TRACE);
			scope wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			int width = _prop.var.cardWin.width == SWT.DEFAULT ? wp.x : _prop.var.cardWin.width;
			static if (EditMode && is (CardOwner == Summary)) {
				shell.setMaximized(_prop.var.cardWin.maximized);
				shell.setMinimized(_prop.var.cardWin.minimized);
				int x = _prop.var.cardWin.x == SWT.DEFAULT ? shell.getBounds().x : _prop.var.cardWin.x + shell.getParent().getBounds().x;
				int y = _prop.var.cardWin.y == SWT.DEFAULT ? shell.getBounds().y : _prop.var.cardWin.y + shell.getParent().getBounds().y;
				intoDisplay(x, y, width, _prop.var.cardWin.height);
				shell.setBounds(x, y, width, _prop.var.cardWin.height);
				shell.addControlListener(new SizeL);
			} else { mixin(S_TRACE);
				shell.setSize(width, _prop.var.cardWin.height);
			}
		}
	}
	private class SizeL : ControlAdapter {
		private void saveCardWin() { mixin(S_TRACE);
			auto shell = cast(Shell) _win;
			if (shell) { mixin(S_TRACE);
				if (!shell.getMaximized() && !shell.getMinimized()) { mixin(S_TRACE);
					_prop.var.cardWin.width = shell.getSize().x;
					_prop.var.cardWin.height = shell.getSize().y;
					_prop.var.cardWin.x = shell.getBounds().x - shell.getParent().getBounds().x;
					_prop.var.cardWin.y = shell.getBounds().y - shell.getParent().getBounds().y;
				}
				_prop.var.cardWin.maximized = shell.getMaximized();
				_prop.var.cardWin.minimized = shell.getMinimized();
			}
		}
		override void controlMoved(ControlEvent e) { mixin(S_TRACE);
			saveCardWin();
		}
		override void controlResized(ControlEvent e) { mixin(S_TRACE);
			saveCardWin();
		}
	}
	static if (!EditMode && is(CardOwner == CastCard)) {
		private void __closeAdds(Summary importable) { mixin(S_TRACE);
			if (_summ is importable) { mixin(S_TRACE);
				_comm.close(_win);
			}
		}
	}

	@property
	override
	Composite shell() { mixin(S_TRACE);
		return _win;
	}
	@property
	CardOwner owner() { mixin(S_TRACE);
		return _owner;
	}
	@property
	PCardOwner summary() { mixin(S_TRACE);
		return _summ;
	}
	static if (EditMode && is (CardOwner == CastCard) && is (PCardOwner == Summary)) {
		private void __refOwner(CastCard c) { mixin(S_TRACE);
			if (_owner is c) { mixin(S_TRACE);
				__refresh();
				refreshTitle();
			}
		}
		private void __delOwner(CastCard c) { mixin(S_TRACE);
			if (_owner is c) { mixin(S_TRACE);
				_comm.close(_win);
			}
		}
	}

	@property
	override
	Image image() { mixin(S_TRACE);
		final switch (CWKind) {
		case CardWindowKind.Main: return _prop.images.menu(MenuID.CardView);
		case CardWindowKind.Cast: return _prop.images.menu(MenuID.CastView);
		case CardWindowKind.Skill: return _prop.images.menu(MenuID.SkillView);
		case CardWindowKind.Item: return _prop.images.menu(MenuID.ItemView);
		case CardWindowKind.Beast: return _prop.images.menu(MenuID.BeastView);
		case CardWindowKind.Info: return _prop.images.menu(MenuID.InfoView);
		case CardWindowKind.Hand: return _prop.images.menu(MenuID.OpenHand);
		case CardWindowKind.ImportSource: return _prop.images.menu(MenuID.OpenImportSource);
		case CardWindowKind.ImportSourceHand: return _prop.images.menu(MenuID.OpenImportSource);
		}
	}
	@property
	override
	string title() { mixin(S_TRACE);
		auto shl = cast(Shell) _win;
		if (shl) { mixin(S_TRACE);
			static if (CWKind == CardWindowKind.Main) {
				if (_summ) { mixin(S_TRACE);
					return .tryFormat(_prop.msgs.mainCardWindowName, _summ.scenarioName, _summ.scenarioPath);
				} else { mixin(S_TRACE);
					return _prop.msgs.mainCardWindowNameNoSummary;
				}
			} else static if (CWKind == CardWindowKind.Cast || CWKind == CardWindowKind.Skill || CWKind == CardWindowKind.Item || CWKind == CardWindowKind.Beast || CWKind == CardWindowKind.Info) {
				if (_summ) { mixin(S_TRACE);
					return .tryFormat(_prop.msgs.cardWindowName, .objName!(Cards[0])(_prop), _summ.scenarioName, _summ.scenarioPath);
				} else { mixin(S_TRACE);
					return .tryFormat(_prop.msgs.cardWindowNameNoSummary, .objName!(Cards[0])(_prop));
				}
			} else static if (CWKind == CardWindowKind.Hand) {
				static if (CWKind == CardWindowKind.Hand) {
					return .tryFormat(_prop.msgs.handCardWindowName, owner.id, owner.name);
				} else { mixin(S_TRACE);
					assert (0);
				}
			} else static if (CWKind == CardWindowKind.ImportSource) {
				assert (_summ !is null);
				return .tryFormat(_prop.msgs.importSourceWindowName, _summ.scenarioName, _summ.scenarioPath);
			} else static if (CWKind == CardWindowKind.ImportSourceHand) {
				return .tryFormat(_prop.msgs.handCardWindowName, owner.id, owner.name);
			} else static assert (0);
		}
		static if (CWKind == CardWindowKind.Main) {
			return _prop.msgs.mainCardTabName;
		} else static if (CWKind == CardWindowKind.Cast || CWKind == CardWindowKind.Skill || CWKind == CardWindowKind.Item || CWKind == CardWindowKind.Beast || CWKind == CardWindowKind.Info) {
			return .tryFormat(_prop.msgs.cardTabName, .objName!(Cards[0])(_prop));
		} else static if (CWKind == CardWindowKind.Hand) {
			return .tryFormat(_prop.msgs.handCardTabName, owner.id, owner.name);
		} else static if (CWKind == CardWindowKind.ImportSource) {
			assert (_summ !is null);
			return .tryFormat(_prop.msgs.importSourceTabName, _summ.scenarioName, _summ.scenarioPath);
		} else static if (CWKind == CardWindowKind.ImportSourceHand) {
			return .tryFormat(_prop.msgs.handCardTabName, owner.id, owner.name);
		} else static assert (0);
	}
	@property
	override
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	void refreshTitle() { mixin(S_TRACE);
		if (_win && !_win.isDisposed()) _comm.setTitle(shell, title);
	}

	static if (EditMode) {
		static if (is (PCardOwner == Summary) && is (CardOwner == Summary)) {
			void refresh(Summary summ) { mixin(S_TRACE);
				__refreshAll(summ, summ);
			}
		} else {
			void refresh(PCardOwner summ, CardOwner owner) { mixin(S_TRACE);
				__refreshAll(summ, owner);
			}
		}
	}
	private void __refreshAll(PCardOwner summ, CardOwner owner) { mixin(S_TRACE);
		_owner = owner;
		_summ = summ;
		foreach (f; _pane) { mixin(S_TRACE);
			f.refreshAll(summ, owner);
		}
		if (_win && !_win.isDisposed()) { mixin(S_TRACE);
			refreshTitle();
		}
	}
	private void refreshStatusLine() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		static if (1 < Cards.length) {
			int i = _tabf.getSelectionIndex();
			string s = "";
			static if (UseCast) if (i == CAST) s = _pane[CAST].statusLine;
			static if (UseSkill) if (i == SKILL) s = _pane[SKILL].statusLine;
			static if (UseItem) if (i == ITEM) s = _pane[ITEM].statusLine;
			static if (UseBeast) if (i == BEAST) s = _pane[BEAST].statusLine;
			static if (UseInfo) if (i == INFO) s = _pane[INFO].statusLine;
			_comm.setStatusLine(_tabf, s);
		} else { mixin(S_TRACE);
			_comm.setStatusLine(_comp, _pane[0].statusLine);
		}
	}

	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			static if (EditMode) {
				foreach (c; _tcpd) { mixin(S_TRACE);
					if (c.canDoTCPD) { mixin(S_TRACE);
						c.cut(se);
					}
				}
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) { mixin(S_TRACE);
					c.copy(se);
				}
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			static if (EditMode) {
				foreach (c; _tcpd) { mixin(S_TRACE);
					if (c.canDoTCPD) { mixin(S_TRACE);
						c.paste(se);
					}
				}
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			static if (EditMode) {
				foreach (c; _tcpd) { mixin(S_TRACE);
					if (c.canDoTCPD) { mixin(S_TRACE);
						c.del(se);
					}
				}
			}
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			static if (EditMode) {
				foreach (c; _tcpd) { mixin(S_TRACE);
					if (c.canDoTCPD) { mixin(S_TRACE);
						c.clone(se);
					}
				}
			}
		}
		bool canDoTCPD() { mixin(S_TRACE);
			return EditMode;
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoT;
			}
			return false;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoC;
			}
			return false;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoP;
			}
			return false;
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoD;
			}
			return false;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoClone;
			}
			return false;
		}
	}
	void edit() { mixin(S_TRACE);
		static if (1 < Cards.length) {
			int i = _tabf.getSelectionIndex();
			static if (UseCast) {
				if (i == CAST) _pane[CAST].edit();
			}
			static if (UseSkill) {
				if (i == SKILL) _pane[SKILL].edit();
			}
			static if (UseItem) {
				if (i == ITEM) _pane[ITEM].edit();
			}
			static if (UseBeast) {
				if (i == BEAST) _pane[BEAST].edit();
			}
			static if (UseInfo) {
				if (i == INFO) _pane[INFO].edit();
			}
		} else { mixin(S_TRACE);
			_pane[0].edit();
		}
	}
	@property
	bool canEdit() { mixin(S_TRACE);
		static if (1 < Cards.length) {
			int i = _tabf.getSelectionIndex();
			static if (UseCast) {
				if (i == CAST) return _pane[CAST].canEdit;
			}
			static if (UseSkill) {
				if (i == SKILL) return _pane[SKILL].canEdit;
			}
			static if (UseItem) {
				if (i == ITEM) return _pane[ITEM].canEdit;
			}
			static if (UseBeast) {
				if (i == BEAST) return _pane[BEAST].canEdit;
			}
			static if (UseInfo) {
				if (i == INFO) return _pane[INFO].canEdit;
			}
			return false;
		} else { mixin(S_TRACE);
			return _pane[0].canEdit;
		}
	}
	static if (UseCast) {
		void editHand() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) _pane[CAST].edit();
				}
			} else { mixin(S_TRACE);
				_pane[0].editHand();
			}
		}
		@property
		bool canEditHand() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) return _pane[CAST].canEdit;
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canEdit;
			}
		}
	}
	static if (EditMode) {
		void reNumbering() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) _pane[CAST].reNumbering();
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].reNumbering();
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].reNumbering();
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].reNumbering();
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].reNumbering();
				}
			} else { mixin(S_TRACE);
				_pane[0].reNumbering();
			}
		}
		@property
		bool canReNumbering() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) return _pane[CAST].canReNumbering;
				}
				static if (UseSkill) {
					if (i == SKILL) return _pane[SKILL].canReNumbering;
				}
				static if (UseItem) {
					if (i == ITEM) return _pane[ITEM].canReNumbering;
				}
				static if (UseBeast) {
					if (i == BEAST) return _pane[BEAST].canReNumbering;
				}
				static if (UseInfo) {
					if (i == INFO) return _pane[INFO].canReNumbering;
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canReNumbering;
			}
		}
		bool canUndo() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) return _pane[CAST].canUndo();
				}
				static if (UseSkill) {
					if (i == SKILL) return _pane[SKILL].canUndo();
				}
				static if (UseItem) {
					if (i == ITEM) return _pane[ITEM].canUndo();
				}
				static if (UseBeast) {
					if (i == BEAST) return _pane[BEAST].canUndo();
				}
				static if (UseInfo) {
					if (i == INFO) return _pane[INFO].canUndo();
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canUndo();
			}
		}
		bool canRedo() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) return _pane[CAST].canRedo();
				}
				static if (UseSkill) {
					if (i == SKILL) return _pane[SKILL].canRedo();
				}
				static if (UseItem) {
					if (i == ITEM) return _pane[ITEM].canRedo();
				}
				static if (UseBeast) {
					if (i == BEAST) return _pane[BEAST].canRedo();
				}
				static if (UseInfo) {
					if (i == INFO) return _pane[INFO].canRedo();
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canRedo();
			}
		}
		void undo() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) _pane[CAST].undo();
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].undo();
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].undo();
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].undo();
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].undo();
				}
			} else { mixin(S_TRACE);
				_pane[0].undo();
			}
		}
		void redo() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) _pane[CAST].redo();
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].redo();
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].redo();
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].redo();
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].redo();
				}
			} else { mixin(S_TRACE);
				_pane[0].redo();
			}
		}
		bool canUp() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) return _pane[CAST].canUp();
				}
				static if (UseSkill) {
					if (i == SKILL) return _pane[SKILL].canUp();
				}
				static if (UseItem) {
					if (i == ITEM) return _pane[ITEM].canUp();
				}
				static if (UseBeast) {
					if (i == BEAST) return _pane[BEAST].canUp();
				}
				static if (UseInfo) {
					if (i == INFO) return _pane[INFO].canUp();
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canUp();
			}
		}
		bool canDown() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) return _pane[CAST].canDown();
				}
				static if (UseSkill) {
					if (i == SKILL) return _pane[SKILL].canDown();
				}
				static if (UseItem) {
					if (i == ITEM) return _pane[ITEM].canDown();
				}
				static if (UseBeast) {
					if (i == BEAST) return _pane[BEAST].canDown();
				}
				static if (UseInfo) {
					if (i == INFO) return _pane[INFO].canDown();
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canDown();
			}
		}
		void up() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) _pane[CAST].up();
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].up();
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].up();
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].up();
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].up();
				}
			} else { mixin(S_TRACE);
				_pane[0].up();
			}
		}
		void down() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) _pane[CAST].down();
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].down();
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].down();
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].down();
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].down();
				}
			} else { mixin(S_TRACE);
				_pane[0].down();
			}
		}

		void replaceID() {
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) _pane[CAST].replaceID();
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].replaceID();
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].replaceID();
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].replaceID();
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].replaceID();
				}
			} else { mixin(S_TRACE);
				_pane[0].replaceID();
			}
		}
		@property
		bool canReplaceID() {
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) return _pane[CAST].canReplaceID;
				}
				static if (UseSkill) {
					if (i == SKILL) return _pane[SKILL].canReplaceID;
				}
				static if (UseItem) {
					if (i == ITEM) return _pane[ITEM].canReplaceID;
				}
				static if (UseBeast) {
					if (i == BEAST) return _pane[BEAST].canReplaceID;
				}
				static if (UseInfo) {
					if (i == INFO) return _pane[INFO].canReplaceID;
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canReplaceID;
			}
		}
	} else {
		void doImport() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) _pane[CAST].doImport();
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].doImport();
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].doImport();
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].doImport();
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].doImport();
				}
			} else { mixin(S_TRACE);
				_pane[0].doImport();
			}
		}
		@property
		bool canDoImport() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) return _pane[CAST].canDoImport;
				}
				static if (UseSkill) {
					if (i == SKILL) return _pane[SKILL].canDoImport;
				}
				static if (UseItem) {
					if (i == ITEM) return _pane[ITEM].canDoImport;
				}
				static if (UseBeast) {
					if (i == BEAST) return _pane[BEAST].canDoImport;
				}
				static if (UseInfo) {
					if (i == INFO) return _pane[INFO].canDoImport;
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canDoImport;
			}
		}
	}
	static if (is(CardOwner:CastCard) && EditMode) {
		void removeRef() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) _pane[CAST].removeRef();
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].removeRef();
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].removeRef();
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].removeRef();
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].removeRef();
				}
			} else { mixin(S_TRACE);
				_pane[0].removeRef();
			}
		}
		@property
		bool canRemoveRef() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseCast) {
					if (i == CAST) return _pane[CAST].canRemoveRef;
				}
				static if (UseSkill) {
					if (i == SKILL) return _pane[SKILL].canRemoveRef;
				}
				static if (UseItem) {
					if (i == ITEM) return _pane[ITEM].canRemoveRef;
				}
				static if (UseBeast) {
					if (i == BEAST) return _pane[BEAST].canRemoveRef;
				}
				static if (UseInfo) {
					if (i == INFO) return _pane[INFO].canRemoveRef;
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canRemoveRef;
			}
		}
	}
	static if (UseSkill || UseItem || UseBeast) {
		void editUseEvent() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].editUseEvent();
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].editUseEvent();
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].editUseEvent();
				}
			} else { mixin(S_TRACE);
				_pane[0].editUseEvent();
			}
		}
		@property
		bool canEditUseEvent() { mixin(S_TRACE);
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex();
				static if (UseSkill) {
					if (i == SKILL) return _pane[SKILL].canEdit;
				}
				static if (UseItem) {
					if (i == ITEM) return _pane[ITEM].canEdit;
				}
				static if (UseBeast) {
					if (i == BEAST) return _pane[BEAST].canEdit;
				}
				return false;
			} else { mixin(S_TRACE);
				return _pane[0].canEdit;
			}
		}
	}
	bool isSelected() { mixin(S_TRACE);
		static if (1 < Cards.length) {
			int i = _tabf.getSelectionIndex();
			static if (UseCast) {
				if (i == CAST) return _pane[CAST].isSelected();
			}
			static if (UseSkill) {
				if (i == SKILL) return _pane[SKILL].isSelected();
			}
			static if (UseItem) {
				if (i == ITEM) return _pane[ITEM].isSelected();
			}
			static if (UseBeast) {
				if (i == BEAST) return _pane[BEAST].isSelected();
			}
			static if (UseInfo) {
				if (i == INFO) return _pane[INFO].isSelected();
			}
			return false;
		} else { mixin(S_TRACE);
			return _pane[0].isSelected();
		}
	}

	private bool openCWXPathEff(int C)(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		if (std.string.endsWith(cate, "view")) { mixin(S_TRACE);
			.forceFocus(_pane[C].widget, shellActivate);
			return true;
		}
		auto index = cpindex(path);
		bool isId = std.string.endsWith(cate, ":id") != 0;
		alias typeof(_pane[C].cards()[0]) CType;
		CType card;
		if (isId) { mixin(S_TRACE);
			card = _pane[C].card(index);
			if (!card) return false;
			index = .cCountUntil!("a is b")(_pane[C].cards, card);
		} else { mixin(S_TRACE);
			if (index >= _pane[C].cards.length) return false;
			card = _pane[C].cards[index];
		}
		path = cpbottom(path);
		if (cpempty(path) || (is(CType : MotionOwner) && "motion" == cpcategory(path))) { mixin(S_TRACE);
			if (!cphasattr(path, "nofocus")) .forceFocus(_pane[C].widget, shellActivate);
			_pane[C].select(index);
			_comm.refreshToolBar();
			static if (EditMode) {
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					auto dlg = _pane[C].edit();
					if (!dlg) return false;
					if (!cpempty(path)) { mixin(S_TRACE);
						return dlg.openCWXPath(path, shellActivate);
					}
				}
			}
			return true;
		}
		static if (is(PCardOwner : Summary)) {
			static if (UseCast && C == CAST) {
				cate = cpcategory(path);
				switch (cate) {
				case "skillcard", "itemcard", "beastcard",
						"skillcard:id", "itemcard:id", "beastcard:id",
						"skillcardview", "itemcardview", "beastcardview": { mixin(S_TRACE);
					if (!cphasattr(path, "nofocus")) forceFocus(_pane[C].widget, shellActivate);
					return _comm.openHands(_prop, _summ, card, shellActivate).openCWXPath(path, shellActivate);
				} break;
				default: break;
				}
			} else static if (!UseInfo || C != INFO) {
				if (cpcategory(path) == "event") { mixin(S_TRACE);
					if (!cphasattr(path, "nofocus")) forceFocus(_pane[C].widget, shellActivate);
					return _comm.openUseEvents(_prop, _summ, card, shellActivate).openCWXPath(path, shellActivate);
				}
			}
		}
		return false;
	}
	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		switch (cate) {
		case "castcard", "castcard:id", "castcardview": { mixin(S_TRACE);
			static if (UseCast) {
				return openCWXPathEff!(CAST)(path, shellActivate);
			}
		} break;
		case "skillcard", "skillcard:id", "skillcardview": { mixin(S_TRACE);
			static if (UseSkill) {
				return openCWXPathEff!(SKILL)(path, shellActivate);
			}
		} break;
		case "itemcard", "itemcard:id", "itemcardview": { mixin(S_TRACE);
			static if (UseItem) {
				return openCWXPathEff!(ITEM)(path, shellActivate);
			}
		} break;
		case "beastcard", "beastcard:id", "beastcardview": { mixin(S_TRACE);
			static if (UseBeast) {
				return openCWXPathEff!(BEAST)(path, shellActivate);
			}
		} break;
		case "infocard", "infocard:id", "infocardview": { mixin(S_TRACE);
			static if (UseInfo) {
				return openCWXPathEff!(INFO)(path, shellActivate);
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
		static if (EditMode) {
			static if (1 < Cards.length) {
				string[] last;
				foreach (i, pane; _pane) { mixin(S_TRACE);
					if (_tabf.getSelectionIndex() == i) { mixin(S_TRACE);
						last = pane.openedCWXPath;
					} else { mixin(S_TRACE);
						r ~= pane.openedCWXPath;
					}
				}
				r ~= last;
			} else { mixin(S_TRACE);
				r ~= _pane[0].openedCWXPath;
			}
		}
		return r;
	}
}

alias CardWindow!(CardWindowKind.ImportSourceHand, Summary, CastCard, Summary, SkillCard, ItemCard, BeastCard) AddHandCardWindow;
alias CardWindow!(CardWindowKind.Hand, Summary, CastCard, void, SkillCard, ItemCard, BeastCard) HandCardWindow;
alias CardWindow!(CardWindowKind.Main, Summary, Summary, void, CastCard, SkillCard, ItemCard, BeastCard, InfoCard) MainCardWindow;
alias CardWindow!(CardWindowKind.Cast, Summary, Summary, void, CastCard) CastCardWindow;
alias CardWindow!(CardWindowKind.Skill, Summary, Summary, void, SkillCard) SkillCardWindow;
alias CardWindow!(CardWindowKind.Item, Summary, Summary, void, ItemCard) ItemCardWindow;
alias CardWindow!(CardWindowKind.Beast, Summary, Summary, void, BeastCard) BeastCardWindow;
alias CardWindow!(CardWindowKind.Info, Summary, Summary, void, InfoCard) InfoCardWindow;

private class DelTemp : DisposeListener {
	private Summary _cc;
	this (Summary cc) { mixin(S_TRACE);
		_cc = cc;
	}
	override void widgetDisposed(DisposeEvent dse) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			_cc.delTemp();
		} catch (Exception e) {
			debugln(e);
		}
	}
}
class AddCard {
private:
	alias CardWindow!(CardWindowKind.ImportSource, Summary, Summary, Summary, CastCard, SkillCard, ItemCard, BeastCard, InfoCard) ACW;
	static class AddS {
		Commons comm;
		Props prop;
		Composite parent;
		Summary toc;
		void delegate(Object[]) addScenario;
		this (Commons comm, Props prop,
				Composite parent, Summary toc, void delegate(Object[]) addScenario) { mixin(S_TRACE);
			this.comm = comm;
			this.prop = prop;
			this.parent = parent;
			this.toc = toc;
			this.addScenario = addScenario;
		}
		void addS(Summary[] ccs) { mixin(S_TRACE);
			ACW[] r;
			foreach (i, cc; ccs) { mixin(S_TRACE);
				if (cc) { mixin(S_TRACE);
					auto shl = cast(Shell) parent;
					auto pane = shl && !comm.singleWindowMode(prop) ? parent : comm.sidePane;
					auto acw = new ACW(comm, prop, pane, cc, cc, toc);
					acw.shell.addDisposeListener(new DelTemp(cc));
					r ~= acw;
				}
			}
			addScenario(cast(Object[]) r);
		}
	}
	this() {}
	static Composite pane(Composite parent) { mixin(S_TRACE);
		auto shl = cast(Shell) parent;
		if (shl) { mixin(S_TRACE);
			return topShell(shl);
		} else { mixin(S_TRACE);
			return parent;
		}
	}
	static LoadOption loadOption(in Props prop) { mixin(S_TRACE);
		LoadOption opt;
		opt.cardOnly = true;
		opt.textOnly = false;
		opt.doubleIO = prop.var.etc.doubleIO;
		opt.expandXMLs = false;
		return opt;
	}
public:
	static void openScenario(Commons comm, Props prop, Composite parent, void delegate(string) status,
			Summary summ, Summary toc, void delegate(Object[]) addScenario) { mixin(S_TRACE);
		parent = pane(parent);
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenarios(prop, loadOption(prop), comm.mainShell, status, prop.msgs.dlgTitAddScenario, &addS.addS);
	}
	static void openScenario(Commons comm, Props prop, Composite parent, void delegate(string) status,
			Summary summ, Summary toc, string[] files, void delegate(Object[]) addScenario) { mixin(S_TRACE);
		parent = pane(parent);
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenariosFromFile(prop, loadOption(prop), comm.mainShell, status, files, &addS.addS);
	}
}

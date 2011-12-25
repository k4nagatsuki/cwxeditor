
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

import cwx.editor.gui.dwt.commondialog;
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

import std.algorithm;
import std.array;
import std.utf;
import std.string;
import std.datetime;
import std.typetuple;
import std.path;

import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.custom.StackLayout;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.ByteArrayTransfer;
import org.eclipse.swt.dnd.FileTransfer;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.Clipboard;

import java.lang.all;

public:

interface ICardWindow {
	bool canCreateCast();
	bool canCreateSkill();
	bool canCreateItem();
	bool canCreateBeast();
	bool canCreateInfo();
	void createCast();
	void createSkill();
	void createItem();
	void createBeast();
	void createInfo();
}

class CardWindow(string ShellTitle, string Title, string ShellImage,
		PCardOwner, CardOwner, ToCardOwner, Cards ...)
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
		StackLayout _stackL;
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
		void create(int Index)() {
			static if (1 < Cards.length) {
				if (_tabf && !_tabf.isDisposed) {
					_tabf.setSelection = _tab[Index];
				}
			}
			_pane[Index].create;
		}
	}
	static if (EditMode) {
		void open(int Index)(bool shellActivate) {
			static if (is(CardOwner : Summary)) {
				static if (1 < Cards.length) {
					_comm.openBindCardWin(shellActivate);
					_tabf.setSelection = _tab[Index];
				} else {
					static if (UseCast && CAST == Index) {
						_comm.openCastWin(shellActivate);
					} else static if(UseSkill && SKILL == Index) {
						_comm.openSkillWin(shellActivate);
					} else static if(UseItem && ITEM == Index) {
						_comm.openItemWin(shellActivate);
					} else static if(UseBeast && BEAST == Index) {
						_comm.openBeastWin(shellActivate);
					} else static if(UseInfo && INFO == Index) {
						_comm.openInfoWin(shellActivate);
					} else static assert (0);
				}
			} else {
				_tabf.setSelection = _tab[Index];
			}
		}
	}

	void __refresh() {
		foreach (f; _pane) {
			f.refresh;
		}
		refreshTitle;
	}
	static if (EditMode && is (CardOwner == Summary)) {
		void addScenario() {
			_comm.addScenario(_prop);
		}
		class DropScenario : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_LINK;
			}
			override void drop(DropTargetEvent e) {
				auto arr = cast(FileNames) e.data;
				if (arr && arr.array.length > 0) {
					_comm.addScenario(_prop, arr.array);
				}
			}
		}
	}
	Shell dlgParShl() {
		if (_win && !_win.isDisposed) return _win.getShell;
		return _comm.mainWin.shell.getShell;
	}
	static if (!EditMode) {
		void addCard() {
			static if (1 < Cards.length) {
				foreach (i, f; _pane) {
					if (_tabf.getSelection is _tab[i]) {
						f.addCard();
						return;
					}
				}
			} else {
				_pane[0].addCard();
			}
		}
	}
	static if (UseCast && !EditMode) {
		void openHand() {
			auto sels = _pane[CAST].selectedCards;
			foreach (sel; sels) {
				auto ahcw = _comm.openAddHands(_prop, _summ, sel, _toc, true);
				ahcw.setAddSkill(_pane[SKILL].getAddCard);
				ahcw.setAddItem(_pane[ITEM].getAddCard);
				ahcw.setAddBeast(_pane[BEAST].getAddCard);
			}
		}
	}
public:
	static if (EditMode) {
		static if (is (CardOwner == Summary)) {
			this(Commons comm, Props prop, Composite parent) {
				_comm = comm;
				_prop = prop;
				if (parent) {
					construct(comm, prop, null, parent);
				} else {
					initPane!(0);
				}
			}
			void reconstruct(Composite parent) {
				if (_win && !_win.isDisposed) return;
				construct(_comm, _prop, _summ, parent);
				if (_owner) refresh(_owner);
			}
		} else {
			this(Commons comm, Props prop, PCardOwner summ, Composite parent) {
				construct(comm, prop, summ, parent);
			}
		}
		void construct(Commons comm, Props prop, PCardOwner summ, Composite parent) {
			_viewMode = CViewMode.INIT;
			construct1(comm, prop, parent);
			static if (is (CardOwner == Summary)) {
				auto shell = cast(Shell) _win;
				if (shell) {
					shell.addShellListener(new class ShellAdapter {
						override void shellClosed(ShellEvent e) {
							(cast(Shell) e.widget).setVisible = false;
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
					override void widgetDisposed(DisposeEvent e) {
						_comm.refCast.remove(&__refOwner);
						_comm.delCast.remove(&__delOwner);
					}
				});
			}
			construct2();
			_comm.refScenarioName.add(&refreshTitle);
			_comm.refScenarioPath.add(&refreshTitle);
			_win.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					_comm.refScenarioName.remove(&refreshTitle);
					_comm.refScenarioPath.remove(&refreshTitle);
				}
			});
		}
		void initPane(int Index)() {
			assert (!_pane[Index]);
			_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf);
			static if (Index + 1 < Cards.length) {
				initPane!(Index + 1);
			}
		}
		void newPane(int Index)() {
			if (_pane[Index]) {
				_pane[Index].reconstruct(_tabf);
			} else {
				_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf);
				_pane[Index].construct();
			}
			static if (Index + 1 < Cards.length) {
				newPane!(Index + 1);
			}
		}
	} else {
		void newPane(int Index)() {
			if (_pane[Index]) {
				_pane[Index].reconstruct(_tabf);
			} else {
				static if (UseCast && Index == CAST) {
					_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, _toc, &openHand);
				} else {
					_pane[Index] = new typeof(_pane[Index])(_comm, _prop, _summ, _tabf, _toc);
				}
				_pane[Index].construct();
			}
			static if (Index + 1 < Cards.length) {
				newPane!(Index + 1);
			}
		}
		this(Commons comm, Props prop,
				Composite parent, PCardOwner summ, CardOwner owner, ToCardOwner toc) {
			_toc = toc;
			construct1(comm, prop, parent);
			static if (is (CardOwner == CastCard)) {
				_comm.closeAdds.add(&__closeAdds);
				_win.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) {
						_comm.closeAdds.remove(&__closeAdds);
					}
				});
			}
			static if (is (CardOwner == Importable)) {
				_win.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) {
						_comm.closeAdds.call(_summ);
					}
				});
			}
			_summ = summ;
			construct2();
			__refreshAll(summ, owner);
		}
	}
	private void construct1(Commons comm, Props prop, Composite parent) {
		_comm = comm;
		_prop = prop;
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		Composite contPane;
		if (parShl) {
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImage = prop.images.app;
			_win = shell;
			contPane = _sbshl.contentPane;
		} else {
			_win = new Composite(parent, SWT.NONE);
			contPane = _win;
		}
		_win.setData = new TLPData(this);
		contPane.setLayout = new FillLayout;
		_comp = new Composite(contPane, SWT.NONE);
		_comp.setLayout = windowGridLayout(1, true);
		if (shell) {
			{
				auto bar = new Menu(shell, SWT.BAR);

				auto mf = createMenu(bar, prop.msgs.menuFile);
				createMenuItem(mf, prop.msgs.menuCloseWin, prop.images.menuCloseWin, &shell.close);

				auto me = createMenu(bar, prop.msgs.menuEdit);
				static if (EditMode) {
					createMenuItem(me, prop.msgs.menuUndo, prop.images.menuUndo, &undo);
					createMenuItem(me, prop.msgs.menuRedo, prop.images.menuRedo, &redo);
					new MenuItem(me, SWT.SEPARATOR);
					appendMenuTCPD(prop, me, this, true, true, true, true);
					new MenuItem(me, SWT.SEPARATOR);
					createMenuItem(me, prop.msgs.menuUp, prop.images.menuUp, &up);
					createMenuItem(me, prop.msgs.menuDown, prop.images.menuDown, &down);
				} else {
					createMenuItem(me, prop.msgs.menuAdd, prop.images.menuAdd, &addCard);
					new MenuItem(me, SWT.SEPARATOR);
					appendMenuTCPD(prop, me, this, false, true, false, false);
				}

				auto mv = createMenu(bar, prop.msgs.menuView);
				static if (EditMode) {
					createMenuItem(mv, prop.msgs.menuRefresh, prop.images.menuRefresh, &__refresh);
					new MenuItem(mv, SWT.SEPARATOR);
				}
				_lifeM = createMenuItem(mv, prop.msgs.menuShowCardLife, prop.images.menuShowCardLife, &showCardLife, SWT.RADIO);
				_listM = createMenuItem(mv, prop.msgs.menuShowCardList, prop.images.menuShowCardList, &showCardList, SWT.RADIO);
				_tblM = createMenuItem(mv, prop.msgs.menuShowCardTable, prop.images.menuShowCardTable, &showCardTable, SWT.RADIO);

				static if (EditMode) {
					auto mt = createMenu(bar, prop.msgs.menuNewCards);
					static if (is (CardOwner == Summary)) {
						createMenuItem(mt, prop.msgs.menuAddScenario, prop.images.menuAddScenario, &addScenario);
						new MenuItem(mt, SWT.SEPARATOR);
					}
					static if (UseCast) createMenuItem(mt, prop.msgs.menuNewCast, prop.images.menuNewCast, &create!(CAST));
					static if (UseSkill) createMenuItem(mt, prop.msgs.menuNewSkill, prop.images.menuNewSkill, &create!(SKILL));
					static if (UseItem) createMenuItem(mt, prop.msgs.menuNewItem, prop.images.menuNewItem, &create!(ITEM));
					static if (UseBeast) createMenuItem(mt, prop.msgs.menuNewBeast, prop.images.menuNewBeast, &create!(BEAST));
					static if (UseInfo) createMenuItem(mt, prop.msgs.menuNewInfo, prop.images.menuNewInfo, &create!(INFO));
				}
				shell.setMenuBar = bar;
			}
			{
				auto bar = new ToolBar(_comp, SWT.FLAT);
				static if (EditMode) {
					static if (is (CardOwner == Summary)) {
						createToolItem(bar, prop.msgs.ttAddScenario, prop.images.menuAddScenario, &addScenario);
						new ToolItem(bar, SWT.SEPARATOR);
					}
				}
				static if (EditMode) {
					createToolItem(bar, prop.msgs.ttRefresh, prop.images.menuRefresh, &__refresh);
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(bar, prop.msgs.ttUp, prop.images.menuUp, &up);
					createToolItem(bar, prop.msgs.ttDown, prop.images.menuDown, &down);
					new ToolItem(bar, SWT.SEPARATOR);
					static if (UseCast) createToolItem(bar, prop.msgs.ttNewCast, prop.images.menuNewCast, &create!(CAST));
					static if (UseSkill) createToolItem(bar, prop.msgs.ttNewSkill, prop.images.menuNewSkill, &create!(SKILL));
					static if (UseItem) createToolItem(bar, prop.msgs.ttNewItem, prop.images.menuNewItem, &create!(ITEM));
					static if (UseBeast) createToolItem(bar, prop.msgs.ttNewBeast, prop.images.menuNewBeast, &create!(BEAST));
					static if (UseInfo) createToolItem(bar, prop.msgs.ttNewInfo, prop.images.menuNewInfo, &create!(INFO));
				} else {
					createToolItem(bar, prop.msgs.ttAdd, prop.images.menuAdd, &addCard);
				}
				new ToolItem(bar, SWT.SEPARATOR);
				_lifeT = createToolItem(bar, prop.msgs.ttShowCardLife, prop.images.menuShowCardLife, &showCardLife, SWT.RADIO);
				_listT = createToolItem(bar, prop.msgs.ttShowCardList, prop.images.menuShowCardList, &showCardList, SWT.RADIO);
				_tblT = createToolItem(bar, prop.msgs.ttShowCardTable, prop.images.menuShowCardTable, &showCardTable, SWT.RADIO);
			}
		} else {
			static if (EditMode) {
				appendMenuTCPD(prop, this, this, true, true, true, true);
				putMenuAction(MenuID.Refresh, &__refresh);
				static if (is (CardOwner == Summary)) {
					putMenuAction(MenuID.AddScenario, &addScenario);
				}
				putMenuAction(MenuID.Undo, &undo);
				putMenuAction(MenuID.Redo, &redo);
				static if (UseCast) putMenuAction(MenuID.NewCast, &create!(CAST));
				static if (UseSkill) putMenuAction(MenuID.NewSkill, &create!(SKILL));
				static if (UseItem) putMenuAction(MenuID.NewItem, &create!(ITEM));
				static if (UseBeast) putMenuAction(MenuID.NewBeast, &create!(BEAST));
				static if (UseInfo) putMenuAction(MenuID.NewInfo, &create!(INFO));
				putMenuAction(MenuID.Up, &up);
				putMenuAction(MenuID.Down, &down);
			} else {
				appendMenuTCPD(prop, this, this, false, true, false, false);
			}
			putMenuChecked(MenuID.ShowCardLife, &showCardLife, &isViewLife);
			putMenuChecked(MenuID.ShowCardList, &showCardList, &isViewList);
			putMenuChecked(MenuID.ShowCardTable, &showCardTable, &isViewTable);
		}
		static if (1 < Cards.length) {
			_tabf = new CTabFolder(_comp, SWT.BORDER);
			_tabf.addSelectionListener(new SelChanged);
		} else {
			_tabf = new Composite(_comp, SWT.BORDER);
			_stackL = new StackLayout;
			_tabf.setLayout = _stackL;
		}
		_tabf.setLayoutData = new GridData(GridData.FILL_BOTH);

		static if (EditMode && is (CardOwner == Summary)) {
			auto drop = new DropTarget(_comp, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new DropScenario);
		}
	}
	static if (1 < Cards.length) {
		private class SelChanged : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				refreshStatusLine;
			}
		}
	}
	static if (EditMode) {
		void reNumberingAll() {
			foreach (f; _pane) {
				f.reNumbering(0, 1);
			}
		}
	}
	void showCardLife() {
		if (_viewMode != CViewMode.LIFE) {
			_viewMode = CViewMode.LIFE;
			if (_win && !_win.isDisposed) {
				if (_listM) {
					_lifeM.setSelection = true;
					_lifeT.setSelection = true;
					_listM.setSelection = false;
					_listT.setSelection = false;
					_tblM.setSelection = false;
					_tblT.setSelection = false;
				}
				foreach (i, f; _pane) {
					f.showCardLife;
					static if (1 < Cards.length) {
						_tab[i].setControl = f.widget;
					} else {
						_stackL.topControl = f.widget;
						_tabf.layout();
					}
				}
			}
			static if (is (CardOwner == Summary)) {
				_prop.var.etc.cardLife = true;
				_prop.var.etc.cardDetails = false;
			}
			refreshStatusLine;
		}
	}
	void showCardList() {
		if (_viewMode != CViewMode.CARD) {
			_viewMode = CViewMode.CARD;
			if (_win && !_win.isDisposed) {
				if (_listM) {
					_lifeM.setSelection = false;
					_lifeT.setSelection = false;
					_listM.setSelection = true;
					_listT.setSelection = true;
					_tblM.setSelection = false;
					_tblT.setSelection = false;
				}
				foreach (i, f; _pane) {
					f.showCardList;
					static if (1 < Cards.length) {
						_tab[i].setControl = f.widget;
					} else {
						_stackL.topControl = f.widget;
						_tabf.layout();
					}
				}
			}
			static if (is (CardOwner == Summary)) {
				_prop.var.etc.cardLife = false;
				_prop.var.etc.cardDetails = false;
			}
			refreshStatusLine;
		}
	}
	void showCardTable() {
		if (_viewMode != CViewMode.TABLE) {
			_viewMode = CViewMode.TABLE;
			if (_win && !_win.isDisposed) {
				if (_listM) {
					_lifeM.setSelection = false;
					_lifeT.setSelection = false;
					_listM.setSelection = false;
					_listT.setSelection = false;
					_tblM.setSelection = true;
					_tblT.setSelection = true;
				}
				foreach (i, f; _pane) {
					f.showCardTable;
					static if (1 < Cards.length) {
						_tab[i].setControl = f.widget;
					} else {
						_stackL.topControl = f.widget;
						_tabf.layout();
					}
				}
			}
			static if (is (CardOwner == Summary)) {
				_prop.var.etc.cardLife = false;
				_prop.var.etc.cardDetails = true;
			}
			refreshStatusLine;
		}
	}

	void setStatusLine(string status) {
		auto w = _win;
		if (w.isDisposed) {
			w = null;
		}
		_comm.statusLine(w, status);
	}

	static if (is(CardOwner : Summary)) {
		void openCast(bool shellActivate) {
			static if (UseCast) {
				open!(CAST)(shellActivate);
			} else {
				throw new Exception("can not open cast");
			}
		}
		void openSkill(bool shellActivate) {
			static if (UseSkill) {
				open!(SKILL)(shellActivate);
			} else {
				throw new Exception("can not open skill");
			}
		}
		void openItem(bool shellActivate) {
			static if (UseItem) {
				open!(ITEM)(shellActivate);
			} else {
				throw new Exception("can not open item");
			}
		}
		void openBeast(bool shellActivate) {
			static if (UseBeast) {
				open!(BEAST)(shellActivate);
			} else {
				throw new Exception("can not open beast");
			}
		}
		void openInfo(bool shellActivate) {
			static if (UseInfo) {
				open!(INFO)(shellActivate);
			} else {
				throw new Exception("can not open info");
			}
		}
	}
	void createCast() {
		if (!_summ) return;
		static if (EditMode && UseCast) {
			create!(CAST);
		} else {
			throw new Exception("can not create cast");
		}
	}
	void createSkill() {
		if (!_summ) return;
		static if (EditMode && UseSkill) {
			create!(SKILL);
		} else {
			throw new Exception("can not create skill");
		}
	}
	void createItem() {
		if (!_summ) return;
		static if (EditMode && UseItem) {
			create!(ITEM);
		} else {
			throw new Exception("can not create item");
		}
	}
	void createBeast() {
		if (!_summ) return;
		static if (EditMode && UseBeast) {
			create!(BEAST);
		} else {
			throw new Exception("can not create beast");
		}
	}
	void createInfo() {
		if (!_summ) return;
		static if (EditMode && UseInfo) {
			create!(INFO);
		} else {
			throw new Exception("can not create info");
		}
	}
	bool canCreateCast() {return EditMode && UseCast;}
	bool canCreateSkill() {return EditMode && UseSkill;}
	bool canCreateItem() {return EditMode && UseItem;}
	bool canCreateBeast() {return EditMode && UseBeast;}
	bool canCreateInfo() {return EditMode && UseInfo;}
	private bool isViewLife() {
		return _viewMode == CViewMode.LIFE;
	}
	private bool isViewList() {
		return _viewMode == CViewMode.CARD;
	}
	private bool isViewTable() {
		return _viewMode == CViewMode.TABLE;
	}
	static if (!is(CardOwner : Summary)) {
		private static class ColResize : ControlAdapter {
			bool procRefColWidth = false;
			Commons comm;
			TableColumn[] cols;
			override void controlResized(ControlEvent e) {
				if (procRefColWidth) return;
				procRefColWidth = true;
				scope (exit) procRefColWidth = false;
				auto c = cast(TableColumn) e.widget;
				int width = c.getWidth;
				foreach (col; cols) {
					if (c !is col) {
						col.setWidth = width;
					}
				}
			}
		}
	}
	private void construct2() {
		newPane!(0);
		static if (!is(CardOwner : Summary)) {
			ColResize[] colR;
			colR.length = (is (CardOwner == Summary)) ? 4 : 3;
			foreach (i, c; colR) {
				colR[i] = new ColResize;
				colR[i].comm = _comm;
			}
			void addTable(Table tbl) {
				foreach (i, col; tbl.getColumns) {
					colR[i].cols ~= col;
					col.addControlListener(colR[i]);
				}
			}
		}
		foreach (i, f; _pane) {
			static if (1 < Cards.length) {
				_tab[i] = new CTabItem(_tabf, SWT.NONE);
				static if (UseCast) {
					if (i == CAST) {
						_tab[i].setText = _prop.msgs.casts;
						_tab[i].setImage = _prop.images.casts;
					}
				}
				static if (UseSkill) {
					if (i == SKILL) {
						_tab[i].setText = _prop.msgs.skill;
						_tab[i].setImage = _prop.images.skill;
					}
				}
				static if (UseItem) {
					if (i == ITEM) {
						_tab[i].setText = _prop.msgs.item;
						_tab[i].setImage = _prop.images.item;
					}
				}
				static if (UseBeast) {
					if (i == BEAST) {
						_tab[i].setText = _prop.msgs.beast;
						_tab[i].setImage = _prop.images.beast;
					}
				}
				static if (UseInfo) {
					if (i == INFO) {
						_tab[i].setText = _prop.msgs.info;
						_tab[i].setImage = _prop.images.info;
					}
				}
			}
			_tcpd ~= f;
			static if (!is(CardOwner : Summary)) {
				addTable(f.cardTable);
			}
		}
		auto shell = cast(Shell) _win;

		static if (1 < Cards.length) {
			_tabf.setSelection = 0;
		}
		bool life = _prop.var.etc.cardLife;
		bool detail = _prop.var.etc.cardDetails;
		if (life) {
			showCardLife;
		} else {
			showCardList;
		}
		if (shell) {
			scope wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			int width = _prop.var.cardWin.width == SWT.DEFAULT ? wp.x : _prop.var.cardWin.width;
			static if (is (CardOwner == Summary)) {
				shell.setMaximized = _prop.var.cardWin.maximized;
				shell.setMinimized = _prop.var.cardWin.minimized;
				int x = _prop.var.cardWin.x == SWT.DEFAULT ? shell.getBounds.x : _prop.var.cardWin.x + shell.getParent.getBounds.x;
				int y = _prop.var.cardWin.y == SWT.DEFAULT ? shell.getBounds.y : _prop.var.cardWin.y + shell.getParent.getBounds.y;
				intoDisplay(x, y, width, _prop.var.cardWin.height);
				shell.setBounds(x, y, width, _prop.var.cardWin.height);
				shell.addControlListener(new SizeL);
			} else {
				shell.setSize(width, _prop.var.cardWin.height);
			}
		}
		if (!life && detail) {
			showCardTable;
		}
	}
	private class SizeL : ControlAdapter {
		private void saveCardWin() {
			auto shell = cast(Shell) _win;
			if (shell) {
				if (!shell.getMaximized && !shell.getMinimized) {
					_prop.var.cardWin.width = shell.getSize.x;
					_prop.var.cardWin.height = shell.getSize.y;
					_prop.var.cardWin.x = shell.getBounds.x - shell.getParent.getBounds.x;
					_prop.var.cardWin.y = shell.getBounds.y - shell.getParent.getBounds.y;
				}
				_prop.var.cardWin.maximized = shell.getMaximized;
				_prop.var.cardWin.minimized = shell.getMinimized;
			}
		}
		override void controlMoved(ControlEvent e) {
			saveCardWin;
		}
		override void controlResized(ControlEvent e) {
			saveCardWin;
		}
	}
	static if (!EditMode && is(CardOwner == CastCard)) {
		private void __closeAdds(Importable importable) {
			if (_summ is importable) {
				_comm.close(_win);
			}
		}
	}

	Composite shell() {
		return _win;
	}
	CardOwner owner() {
		return _owner;
	}
	PCardOwner summary() {
		return _summ;
	}
	static if (EditMode && is (CardOwner == CastCard) && is (PCardOwner == Summary)) {
		private void __refOwner(CastCard c) {
			if (_owner is c) {
				__refresh;
				refreshTitle;
			}
		}
		private void __delOwner(CastCard c) {
			if (_owner is c) {
				_comm.close(_win);
			}
		}
	}

	Image image() {
		return mixin ("_prop.images." ~ ShellImage);
	}
	string title() {
		auto shl = cast(Shell) _win;
		if (shl) {
			return mixin ("_prop.msgs." ~ ShellTitle);
		}
		return mixin ("_prop.msgs." ~ Title);
	}
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	void refreshTitle() {
		if (_win && !_win.isDisposed) _comm.setTitle(shell, title);
	}

	static if (EditMode) {
		static if (is (PCardOwner == Summary) && is (CardOwner == Summary)) {
			void refresh(Summary summ) {
				__refreshAll(summ, summ);
			}
		} else {
			void refresh(PCardOwner summ, CardOwner owner) {
				__refreshAll(summ, owner);
			}
		}
	}
	private void __refreshAll(PCardOwner summ, CardOwner owner) {
		_owner = owner;
		_summ = summ;
		foreach (f; _pane) {
			f.refreshAll(summ, owner);
		}
		if (_win && !_win.isDisposed) {
			refreshTitle;
		}
	}
	static if (EditMode) {
		void add(int Index)(ref XNode node, string ver) {
			if (_pane[Index].addFromNode(node, ver)) {
				static if (1 < Cards.length) {
					_tabf.setSelection = _tab[Index];
				}
			}
		}
		static if (UseCast) {
			void addCast(ref XNode node, string ver) {
				_pane[CAST].addFromNode(node, ver);
			}
		}
		static if (UseSkill) {
			void addSkill(ref XNode node, string ver) {
				_pane[SKILL].addFromNode(node, ver);
			}
		}
		static if (UseItem) {
			void addItem(ref XNode node, string ver) {
				_pane[ITEM].addFromNode(node, ver);
			}
		}
		static if (UseBeast) {
			void addBeast(ref XNode node, string ver) {
				_pane[BEAST].addFromNode(node, ver);
			}
		}
		static if (UseInfo) {
			void addInfo(ref XNode node, string ver) {
				_pane[INFO].addFromNode(node, ver);
			}
		}
	} else {
		static if (UseCast) {
			void setAddCast(void delegate(ref XNode node, string) addc) {
				_pane[CAST].setAddCard = addc;
			}
		}
		static if (UseSkill) {
			void setAddSkill(void delegate(ref XNode node, string) addc) {
				_pane[SKILL].setAddCard = addc;
			}
		}
		static if (UseItem) {
			void setAddItem(void delegate(ref XNode node, string) addc) {
				_pane[ITEM].setAddCard = addc;
			}
		}
		static if (UseBeast) {
			void setAddBeast(void delegate(ref XNode node, string) addc) {
				_pane[BEAST].setAddCard = addc;
			}
		}
		static if (UseInfo) {
			void setAddInfo(void delegate(ref XNode node, string) addc) {
				_pane[INFO].setAddCard = addc;
			}
		}
	}
	private void refreshStatusLine() {
		if (!_win || _win.isDisposed) return;
		static if (1 < Cards.length) {
			int i = _tabf.getSelectionIndex;
			string s = "";
			static if (UseCast) if (i == CAST) s = _pane[CAST].statusLine;
			static if (UseSkill) if (i == SKILL) s = _pane[SKILL].statusLine;
			static if (UseItem) if (i == ITEM) s = _pane[ITEM].statusLine;
			static if (UseBeast) if (i == BEAST) s = _pane[BEAST].statusLine;
			static if (UseInfo) if (i == INFO) s = _pane[INFO].statusLine;
			_comm.statusLine(_tabf, s);
		} else {
			_comm.statusLine(_comp, _pane[0].statusLine);
		}
	}

	override {
		void cut(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.cut(se);
					}
				}
			}
		}
		void copy(SelectionEvent se) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.copy(se);
				}
			}
		}
		void paste(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.paste(se);
					}
				}
			}
		}
		void del(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.del(se);
					}
				}
			}
		}
		bool canDoTCPD() {
			return EditMode;
		}
	}
	static if (EditMode) {
		void undo() {
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex;
				static if (UseCast) {
					if (i == CAST) _pane[CAST].undo;
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].undo;
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].undo;
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].undo;
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].undo;
				}
			} else {
				_pane[0].undo;
			}
		}
		void redo() {
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex;
				static if (UseCast) {
					if (i == CAST) _pane[CAST].redo;
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].redo;
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].redo;
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].redo;
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].redo;
				}
			} else {
				_pane[0].redo;
			}
		}
		void up() {
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex;
				static if (UseCast) {
					if (i == CAST) _pane[CAST].up;
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].up;
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].up;
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].up;
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].up;
				}
			} else {
				_pane[0].up;
			}
		}
		void down() {
			static if (1 < Cards.length) {
				int i = _tabf.getSelectionIndex;
				static if (UseCast) {
					if (i == CAST) _pane[CAST].down;
				}
				static if (UseSkill) {
					if (i == SKILL) _pane[SKILL].down;
				}
				static if (UseItem) {
					if (i == ITEM) _pane[ITEM].down;
				}
				static if (UseBeast) {
					if (i == BEAST) _pane[BEAST].down;
				}
				static if (UseInfo) {
					if (i == INFO) _pane[INFO].down;
				}
			} else {
				_pane[0].down;
			}
		}
	}

	private bool openCWXPathEff(int C)(string path, bool shellActivate) {
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool isId = std.string.endsWith(cate, ":id") != 0;
		alias typeof(_pane[C].cards[0]) CType;
		CType card;
		if (isId) {
			card = _pane[C].card(index);
			if (!card) return false;
			index = .cCountUntil!("a is b")(_pane[C].cards, card);
		} else {
			if (index >= _pane[C].cards.length) return false;
			card = _pane[C].cards[index];
		}
		path = cpbottom(path);
		if (cpempty(path) || (is(CType : MotionOwner) && "motion" == cpcategory(path))) {
			.forceFocus(_pane[C].widget, shellActivate);
			_pane[C].select(index);
			static if (EditMode) {
				if (cphasattr(path, "opendialog")) {
					auto dlg = _pane[C].edit();
					if (!cpempty(path)) {
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
						"skillcard:id", "itemcard:id", "beastcard:id": {
					forceFocus(_pane[C].widget, shellActivate);
					return _comm.openHands(_prop, _summ, card, shellActivate).openCWXPath(path, shellActivate);
				} break;
				default: break;
				}
			} else static if (!UseInfo || C != INFO) {
				if (cpcategory(path) == "event") {
					forceFocus(_pane[C].widget, shellActivate);
					return _comm.openUseEvents(_prop, _summ, card, shellActivate).openCWXPath(path, shellActivate);
				}
			}
		}
		return false;
	}
	bool openCWXPath(string path, bool shellActivate) {
		auto cate = cpcategory(path);
		switch (cate) {
		case "castcard", "castcard:id": {
			static if (UseCast) {
				return openCWXPathEff!(CAST)(path, shellActivate);
			}
		} break;
		case "skillcard", "skillcard:id": {
			static if (UseSkill) {
				return openCWXPathEff!(SKILL)(path, shellActivate);
			}
		} break;
		case "itemcard", "itemcard:id": {
			static if (UseItem) {
				return openCWXPathEff!(ITEM)(path, shellActivate);
			}
		} break;
		case "beastcard", "beastcard:id": {
			static if (UseBeast) {
				return openCWXPathEff!(BEAST)(path, shellActivate);
			}
		} break;
		case "infocard", "infocard:id": {
			static if (UseInfo) {
				return openCWXPathEff!(INFO)(path, shellActivate);
			}
		} break;
		default: break;
		}
		return false;
	}
	string[] openedCWXPath() {
		string[] r;
		static if (1 < Cards.length) {
			string[] last;
			foreach (i, pane; _pane) {
				if (_tabf.getSelectionIndex == i) {
					last = pane.openedCWXPath;
				} else {
					r ~= pane.openedCWXPath;
				}
			}
			r ~= last;
		} else {
			r ~= _pane[0].openedCWXPath;
		}
		return r;
	}
}

alias CardWindow!("handCards(owner.id, owner.name)", "handCardsTab(owner.id, owner.name)",
	"menuAddScenario", Importable, CastCard, Summary, SkillCard, ItemCard, BeastCard) AddHandCardWindow;

// FIXME: 以下の二つをaliasにすると前方参照のエラーが発生する
class HandCardWindow : CardWindow!("handCards(owner.id, owner.name)",
		"handCardsTab(owner.id, owner.name)", "menuOpenHand",
		Summary, CastCard, void, SkillCard, ItemCard, BeastCard) {
	this (Commons comm, Props prop, Summary summ, Composite parent) {
		super (comm, prop, summ, parent);
	}
}
class MainCardWindow : CardWindow!("cardWindowName(owner)", "cardTabName(owner)",
		"menuCardWin", Summary, Summary, void, CastCard, SkillCard, ItemCard, BeastCard, InfoCard) {
	this (Commons comm, Props prop, Composite parent) {
		super (comm, prop, parent);
	}
}
alias CardWindow!("castWindowName(owner)", "castTabName(owner)", "menuCastWin", Summary, Summary, void, CastCard) CastCardWindow;
alias CardWindow!("skillWindowName(owner)", "skillTabName(owner)", "menuSkillWin", Summary, Summary, void, SkillCard) SkillCardWindow;
alias CardWindow!("itemWindowName(owner)", "itemTabName(owner)", "menuItemWin", Summary, Summary, void, ItemCard) ItemCardWindow;
alias CardWindow!("beastWindowName(owner)", "beastTabName(owner)", "menuBeastWin", Summary, Summary, void, BeastCard) BeastCardWindow;
alias CardWindow!("infoWindowName(owner)", "infoTabName(owner)", "menuInfoWin", Summary, Summary, void, InfoCard) InfoCardWindow;

private class DelTemp(CC) : DisposeListener {
	private CC _cc;
	this(CC cc) {
		_cc = cc;
	}
	override void widgetDisposed(DisposeEvent dse) {
		try {
			_cc.delTemp;
		} catch (Exception e) {
			debugln(e);
		}
	}
}
private class AddCard {
private:
	alias CardContainer!(true, true, true, true, true) CC;
	alias CardWindow!("addCardWindow(owner.scenarioName, owner.scenarioPath)",
		"addCardTab(owner.scenarioName, owner.scenarioPath)", "menuAddScenario",
		CC, CC, Summary, CastCard, SkillCard, ItemCard, BeastCard, InfoCard) ACW;
	static class AddS {
		Commons comm;
		Props prop;
		Composite parent;
		Summary toc;
		void delegate(Object[]) addScenario;
		this (Commons comm, Props prop,
				Composite parent, Summary toc, void delegate(Object[]) addScenario) {
			this.comm = comm;
			this.prop = prop;
			this.parent = parent;
			this.toc = toc;
			this.addScenario = addScenario;
		}
		void addS(CC[] ccs) {
			ACW[] r;
			foreach (i, cc; ccs) {
				if (cc) {
					auto shl = cast(Shell) parent;
					auto pane = shl && !comm.singleWindowMode(prop) ? parent : comm.sidePane;
					auto acw = new ACW(comm, prop, pane, cc, cc, toc);
					acw.shell.addDisposeListener(new DelTemp!(CC)(cc));
					r ~= acw;
				}
			}
			addScenario(cast(Object[]) r);
		}
	}
	this() {}
	static Composite pane(Composite parent) {
		auto shl = cast(Shell) parent;
		if (shl) {
			return topShell(shl);
		} else {
			return parent;
		}
	}
public:
	static void openScenario(Commons comm, Props prop, Composite parent, void delegate(string) status,
			Summary summ, Summary toc, void delegate(Object[]) addScenario) {
		parent = pane(parent);
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenarios!(CC)(prop, comm.mainShell, status, false, prop.msgs.dlgTitAddScenario, &addS.addS);
	}
	static void openScenario(Commons comm, Props prop, Composite parent, void delegate(string) status,
			Summary summ, Summary toc, string[] files, void delegate(Object[]) addScenario) {
		parent = pane(parent);
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenariosFromFile!(CC)(prop, comm.mainShell, status, false, files, &addS.addS);
	}
}

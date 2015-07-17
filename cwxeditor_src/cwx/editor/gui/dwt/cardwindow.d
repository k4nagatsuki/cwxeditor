
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
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.cardpane;
import cwx.editor.gui.dwt.loader;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.areatable;

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

enum CardWindowKind {
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
class CardWindow : TopLevelPanel, TCPD {
private:
	@property
	const
	bool editMode() { return _toc is null; }
	@property
	const
	bool withArea() { return _kind is CardWindowKind.ImportSource; }
	@property
	const
	bool multiTab() { return _kind is CardWindowKind.ImportSource || _kind is CardWindowKind.Hand || _kind is CardWindowKind.ImportSourceHand; }

	@property
	const
	const(CardType)[] cardTypes() {
		final switch (_kind) {
		case CardWindowKind.Cast:
			return [CardType.Cast];
		case CardWindowKind.Skill:
			return [CardType.Skill];
		case CardWindowKind.Item:
			return [CardType.Item];
		case CardWindowKind.Beast:
			return [CardType.Beast];
		case CardWindowKind.Info:
			return[CardType.Info];
		case CardWindowKind.ImportSource:
			return [CardType.Cast, CardType.Skill, CardType.Item, CardType.Beast, CardType.Info];
		case CardWindowKind.Hand:
			return [CardType.Skill, CardType.Item, CardType.Beast];
		case CardWindowKind.ImportSourceHand:
			return [CardType.Skill, CardType.Item, CardType.Beast];
		}
	}

	CardWindowKind _kind;

	CardPane[] _pane;
	CardPane[CardType] _paneTbl;
	Composite _tabf;
	CTabItem[] _tab;

	AreaTable _areas = null;
	CTabItem _aTab = null;

	Props _prop;
	Composite _win;
	Composite _comp;
	Summary _summ;
	CWXPath _owner;
	OwnerType _ownerType;
	Commons _comm;

	CViewMode _viewMode = CViewMode.INIT;
	MenuItem _lifeM;
	MenuItem _listM;
	MenuItem _tblM;
	ToolItem _lifeT;
	ToolItem _listT;
	ToolItem _tblT;

	Summary _toc = null;

	void refreshM() { mixin(S_TRACE);
		foreach (f; _pane) { mixin(S_TRACE);
			f.refresh();
		}
		refreshTitle();
	}

	void addScenario() { mixin(S_TRACE);
		assert (_ownerType is OwnerType.Summary);
		assert (editMode);
		_comm.addScenario(_prop);
	}
	class DropScenario : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			assert (_ownerType is OwnerType.Summary);
			assert (editMode);
			e.detail = DND.DROP_LINK;
		}
		override void drop(DropTargetEvent e) { mixin(S_TRACE);
			assert (_ownerType is OwnerType.Summary);
			assert (editMode);
			auto arr = cast(FileNames) e.data;
			if (arr && arr.array.length > 0) { mixin(S_TRACE);
				_comm.addScenario(_prop, arr.array);
			}
		}
	}

	@property
	Shell dlgParShl() { mixin(S_TRACE);
		if (_win && !_win.isDisposed()) return _win.getShell();
		return _comm.mainWin.shell.getShell();
	}

	void openHand() { mixin(S_TRACE);
		assert (CardType.Cast in _paneTbl);
		assert (!editMode);
		auto sels = _paneTbl[CardType.Cast].selectedCards;
		foreach (sel; sels) { mixin(S_TRACE);
			_comm.openAddHands(_prop, _summ, cast(CastCard)sel, _toc, true);
		}
	}

public:
	this (Commons comm, Props prop, CardWindowKind kind, Composite parent) { mixin(S_TRACE);
		_comm = comm;
		_prop = prop;
		_kind = kind;
		if (parent) { mixin(S_TRACE);
			construct(comm, prop, null, parent);
		} else { mixin(S_TRACE);
			initPane();
		}
		assert (editMode);
	}
	this (Commons comm, Props prop, CardWindowKind kind, Summary summ, Composite parent) { mixin(S_TRACE);
		_kind = kind;
		construct(comm, prop, summ, parent);
		assert (editMode);
	}
	this (Commons comm, Props prop, CardWindowKind kind, Composite parent, Summary summ, CWXPath owner, Summary toc) { mixin(S_TRACE);
		_kind = kind;
		_toc = toc;
		construct1(comm, prop, parent);
		if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
			_comm.closeAdds.add(&closeAdds);
			_win.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					_comm.closeAdds.remove(&closeAdds);
				}
			});
		}
		if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
			_win.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					_comm.closeAdds.call(_summ);
				}
			});
		}
		_summ = summ;
		construct2();
		assert (!editMode);
		refreshAll(summ, owner);
	}

	void reconstruct(Composite parent) { mixin(S_TRACE);
		assert (editMode);
		if (_win && !_win.isDisposed()) return;
		construct(_comm, _prop, _summ, parent);
		if (_owner) { mixin(S_TRACE);
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
				refresh(cast(Summary)_owner);
			} else if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
				refresh(_summ, cast(CastCard)_owner);
			} else assert (0);
		}
	}

	void construct(Commons comm, Props prop, Summary summ, Composite parent) { mixin(S_TRACE);
		assert (editMode);
		_viewMode = CViewMode.INIT;
		construct1(comm, prop, parent);
		if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
			_comm.refCast.add(&refOwner);
			_comm.delCast.add(&delOwner);
			_win.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					_comm.refCast.remove(&refOwner);
					_comm.delCast.remove(&delOwner);
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
	void initPane() { mixin(S_TRACE);
		assert (editMode);
		if (!_pane.length) { mixin(S_TRACE);
			_pane = new CardPane[cardTypes.length];
			_tab = new CTabItem[cardTypes.length];
		}
		foreach (i, cardType; cardTypes) { mixin(S_TRACE);
			assert (!_pane[i]);
			_pane[i] = new CardPane(_comm, _prop, _summ, _tabf, _ownerType, cardType, SWT.BORDER);
			_paneTbl[cardType] = _pane[i];
		}
	}

	void newPane() { mixin(S_TRACE);
		if (!_pane.length) { mixin(S_TRACE);
			_pane = new CardPane[cardTypes.length];
			_tab = new CTabItem[cardTypes.length];
		}
		foreach (i, cardType; cardTypes) { mixin(S_TRACE);
			if (_pane[i]) { mixin(S_TRACE);
				_pane[i].reconstruct(_tabf, SWT.BORDER);
			} else { mixin(S_TRACE);
				if (editMode) { mixin(S_TRACE);
					_pane[i] = new CardPane(_comm, _prop, _summ, _tabf, _ownerType, cardType, SWT.BORDER);
				} else {
					if (cardType is CardType.Cast) {
						_pane[i] = new CardPane(_comm, _prop, _summ, _tabf, _ownerType, cardType, SWT.BORDER, _toc, &openHand);
					} else { mixin(S_TRACE);
						_pane[i] = new CardPane(_comm, _prop, _summ, _tabf, _ownerType, cardType, SWT.BORDER, _toc);
					}
				}
				_paneTbl[cardType] = _pane[i];
				_pane[i].construct();
			}
		}
	}

	private void construct1(Commons comm, Props prop, Composite parent) { mixin(S_TRACE);
		_comm = comm;
		_prop = prop;
		Composite contPane;
		_win = new Composite(parent, SWT.NONE);
		contPane = _win;
		_win.setData(new TLPData(this));
		contPane.setLayout(new FillLayout);
		_comp = new Composite(contPane, SWT.NONE);
		_comp.setLayout(windowGridLayout(1, true));
		auto useCast = _kind is CardWindowKind.Cast || _kind is CardWindowKind.ImportSource;
		final switch (_kind) {
		case CardWindowKind.Cast:
		case CardWindowKind.Skill:
		case CardWindowKind.Item:
		case CardWindowKind.Beast:
		case CardWindowKind.Info:
		case CardWindowKind.ImportSource:
			_ownerType = OwnerType.Summary;
			break;
		case CardWindowKind.Hand:
		case CardWindowKind.ImportSourceHand:
			_ownerType = OwnerType.Cast;
			break;
		}

		if (withArea) { mixin(S_TRACE);
			putMenuAction(MenuID.EditSummary, () => _areas.editSummary(_areas.panel.getShell()), () => _summ !is null);
			putMenuAction(MenuID.EditScene, () => _areas.openAreaScene(true), () => _areas.canOpenAreaScene);
			putMenuAction(MenuID.EditSceneDup, () => _areas.openAreaScene(true, true), () => _areas.canOpenAreaScene);
			putMenuAction(MenuID.EditEvent, () => _areas.openAreaEvent(true), () => _areas.canOpenAreaEvent);
			putMenuAction(MenuID.EditEventDup, () => _areas.openAreaEvent(true, true), () => _areas.canOpenAreaEvent);
			putMenuAction(MenuID.ChangeVH, () => _areas.changeVHSide(), () => _areas.canChangeVH);
		}
		if (editMode) { mixin(S_TRACE);
			appendMenuTCPD(_comm, this, this, true, true, true, true, true);
			putMenuAction(MenuID.Refresh, &refreshM, () => _summ !is null);
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
				putMenuAction(MenuID.OpenImportSource, &addScenario, () => _summ !is null);
			}
			putMenuAction(MenuID.Undo, &undo, &canUndo);
			putMenuAction(MenuID.Redo, &redo, &canRedo);
			if (useCast) { mixin(S_TRACE);
				putMenuAction(MenuID.NewCast, &createCast, () => _summ !is null);
				putMenuAction(MenuID.OpenHand, &editHand, &canEditHand);
			}
			if (CardType.Skill in _paneTbl) putMenuAction(MenuID.NewSkill, &createSkill, () => _summ !is null);
			if (CardType.Item in _paneTbl) putMenuAction(MenuID.NewItem, &createItem, () => _summ !is null);
			if (CardType.Beast in _paneTbl) putMenuAction(MenuID.NewBeast, &createBeast, () => _summ !is null);
			if (CardType.Info in _paneTbl) putMenuAction(MenuID.NewInfo, &createInfo, () => _summ !is null);
			putMenuAction(MenuID.Up, &up, &canUp);
			putMenuAction(MenuID.Down, &down, &canDown);
			putMenuAction(MenuID.SelectConnectedResource, &selectConnectedResource, &canSelectConnectedResource);
			putMenuAction(MenuID.FindID, &replaceID, &canReplaceID);
			putMenuAction(MenuID.EditProp, &edit, &canEdit);
			putMenuAction(MenuID.ReNumbering, &reNumbering, &canReNumbering);
			if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
				putMenuAction(MenuID.RemoveRef, &removeRef, &canRemoveRef);
			}
		} else { mixin(S_TRACE);
			appendMenuTCPD(_comm, this, this, false, true, false, false, false);
			putMenuAction(MenuID.ShowProp, &edit, &canEdit);
			if (useCast) { mixin(S_TRACE);
				putMenuAction(MenuID.OpenHand, &editHand, &canEditHand);
			}
			putMenuAction(MenuID.Import, &doImport, &canDoImport);
		}
		if (CardType.Skill in _paneTbl || CardType.Item in _paneTbl || CardType.Beast in _paneTbl) {
			putMenuAction(MenuID.EditEventAtTimeOfUsing, () => editUseEvent(false), &canEditUseEvent);
			putMenuAction(MenuID.EditEventDup, () => editUseEvent(true), &canEditUseEvent);
		}
		putMenuChecked(MenuID.ShowCardProp, &showCardLife, &isViewLife, null);
		putMenuChecked(MenuID.ShowCardImage, &showCardList, &isViewList, null);
		putMenuChecked(MenuID.ShowCardDetail, &showCardTable, &isViewTable, null);

		if (multiTab) { mixin(S_TRACE);
			auto tabf = new CTabFolder(_comp, SWT.BORDER);
			tabf.addSelectionListener(new SelChanged);
			_tabf = tabf;
		} else { mixin(S_TRACE);
			_tabf = new Composite(_comp, SWT.NONE);
			_tabf.setLayout(zeroGridLayout(1, true));
		}
		_tabf.setLayoutData(new GridData(GridData.FILL_BOTH));

		if (editMode && _ownerType is OwnerType.Summary) { mixin(S_TRACE);
			auto drop = new DropTarget(_comp, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance()]);
			drop.addDropListener(new DropScenario);
		}
	}

	private class SelChanged : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			refreshStatusLine();
			_comm.refreshToolBar();
		}
	}

	@property
	override
	Control focusControl() {
		return _pane[0].widget;
	}

	void reNumberingAll() { mixin(S_TRACE);
		assert (editMode);
		foreach (f; _pane) { mixin(S_TRACE);
			f.reNumbering(0, 1);
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
			if (editMode && _ownerType is OwnerType.Summary) { mixin(S_TRACE);
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
			if (editMode && _ownerType is OwnerType.Summary) { mixin(S_TRACE);
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
			if (editMode && _ownerType is OwnerType.Summary) { mixin(S_TRACE);
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

	CardPane openPane(CardType cardType, bool shellActivate) { mixin(S_TRACE);
		assert (editMode);
		return open(cardType, shellActivate);
	}

	@property
	CardPane paneCast() { mixin(S_TRACE);
		assert (editMode);
		return _paneTbl[CardType.Cast];
	}
	@property
	CardPane paneSkill() { mixin(S_TRACE);
		assert (editMode);
		return _paneTbl[CardType.Skill];
	}
	@property
	CardPane paneItem() { mixin(S_TRACE);
		assert (editMode);
		return _paneTbl[CardType.Item];
	}
	@property
	CardPane paneBeast() { mixin(S_TRACE);
		assert (editMode);
		return _paneTbl[CardType.Beast];
	}
	@property
	CardPane paneInfo() { mixin(S_TRACE);
		assert (editMode);
		return _paneTbl[CardType.Info];
	}

	void createCast() { mixin(S_TRACE);
		if (!_summ) return;
		create(CardType.Cast);
	}
	void createSkill() { mixin(S_TRACE);
		if (!_summ) return;
		create(CardType.Skill);
	}
	void createItem() { mixin(S_TRACE);
		if (!_summ) return;
		create(CardType.Item);
	}
	void createBeast() { mixin(S_TRACE);
		if (!_summ) return;
		create(CardType.Beast);
	}
	void createInfo() { mixin(S_TRACE);
		if (!_summ) return;
		create(CardType.Info);
	}
	@property
	bool canCreateCast() {return editMode && CardType.Cast in _paneTbl;}
	@property
	bool canCreateSkill() {return editMode && CardType.Skill in _paneTbl;}
	@property
	bool canCreateItem() {return editMode && CardType.Item in _paneTbl;}
	@property
	bool canCreateBeast() {return editMode && CardType.Beast in _paneTbl;}
	@property
	bool canCreateInfo() {return editMode && CardType.Info in _paneTbl;}
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

	private void construct2() { mixin(S_TRACE);
		newPane();
		if (withArea) { mixin(S_TRACE);
			if (!_areas) { mixin(S_TRACE);
				_areas = new AreaTable(_comm, _prop, !editMode, _toc);
			}
			_areas.construct(_tabf, null);
		}

		ColResize[CardTableColumn] colR;
		void addTable(TableColumn[CardTableColumn] columns) { mixin(S_TRACE);
			assert (!editMode || _ownerType !is OwnerType.Summary);
			foreach (i, col; columns) { mixin(S_TRACE);
				if (i !in colR) { mixin(S_TRACE);
					colR[i] = new ColResize;
					colR[i].comm = _comm;
				}
				colR[i].cols ~= col;
				col.addControlListener(colR[i]);
			}
		}

		foreach (i, pane; _pane) { mixin(S_TRACE);
			if (auto tabf = cast(CTabFolder)_tabf) {
				_tab[i] = new CTabItem(tabf, SWT.NONE);
				final switch (pane.cardType) {
				case CardType.Cast:
					_tab[i].setText(_prop.msgs.cwCast);
					_tab[i].setImage(_prop.images.casts);
					break;
				case CardType.Skill:
					_tab[i].setText(_prop.msgs.skill);
					_tab[i].setImage(_prop.images.skill);
					break;
				case CardType.Item:
					_tab[i].setText(_prop.msgs.item);
					_tab[i].setImage(_prop.images.item);
					break;
				case CardType.Beast:
					_tab[i].setText(_prop.msgs.beast);
					_tab[i].setImage(_prop.images.beast);
					break;
				case CardType.Info:
					_tab[i].setText(_prop.msgs.info);
					_tab[i].setImage(_prop.images.info);
					break;
				}
				_tab[i].setControl(pane.pane);
			} else { mixin(S_TRACE);
				_pane[i].pane.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
			if (!editMode || _ownerType !is OwnerType.Summary) { mixin(S_TRACE);
				addTable(pane.columns);
			}
		}

		if (withArea) { mixin(S_TRACE);
			assert (cast(CTabFolder)_tabf !is null);
			_aTab = new CTabItem(cast(CTabFolder)_tabf, SWT.NONE, 0);
			_aTab.setText(_prop.msgs.areasTabName);
			_aTab.setImage(_prop.images.menu(MenuID.TableView));
			_aTab.setControl(_areas.panel);
		}

		if (multiTab) {
			assert (cast(CTabFolder)_tabf !is null);
			(cast(CTabFolder)_tabf).setSelection(0);
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
	}
	private void closeAdds(Summary importable) { mixin(S_TRACE);
		assert (!editMode && _ownerType is OwnerType.Cast);
		if (_summ is importable) { mixin(S_TRACE);
			_comm.close(_win);
		}
	}

	@property
	override
	Composite shell() { mixin(S_TRACE);
		return _win;
	}
	@property
	CWXPath owner() { mixin(S_TRACE);
		return _owner;
	}
	@property
	Summary summary() { mixin(S_TRACE);
		return _summ;
	}
	@property
	const
	CardWindowKind kind() { return _kind; }

	private void refOwner(CastCard c) { mixin(S_TRACE);
		assert (_ownerType is OwnerType.Cast);
		assert (editMode);
		if (_owner is c) { mixin(S_TRACE);
			refreshM();
			refreshTitle();
		}
	}
	private void delOwner(CastCard c) { mixin(S_TRACE);
		assert (_ownerType is OwnerType.Cast);
		assert (editMode);
		if (_owner is c) { mixin(S_TRACE);
			_comm.close(_win);
		}
	}

	@property
	override
	Image image() { mixin(S_TRACE);
		final switch (_kind) {
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
		final switch (_kind) {
		case CardWindowKind.Cast:
			return .tryFormat(_prop.msgs.cardTabName, .objName!CastCard(_prop));
		case CardWindowKind.Skill:
			return .tryFormat(_prop.msgs.cardTabName, .objName!SkillCard(_prop));
		case CardWindowKind.Item:
			return .tryFormat(_prop.msgs.cardTabName, .objName!ItemCard(_prop));
		case CardWindowKind.Beast:
			return .tryFormat(_prop.msgs.cardTabName, .objName!BeastCard(_prop));
		case CardWindowKind.Info:
			return .tryFormat(_prop.msgs.cardTabName, .objName!InfoCard(_prop));
		case CardWindowKind.Hand:
			assert (cast(CastCard)owner !is null);
			return .tryFormat(_prop.msgs.handCardTabName, (cast(CastCard)owner).id, (cast(CastCard)owner).name);
		case CardWindowKind.ImportSource:
			assert (_summ !is null);
			return .tryFormat(_prop.msgs.importSourceTabName, _summ.scenarioName, _summ.scenarioPath);
		case CardWindowKind.ImportSourceHand:
			assert (cast(CastCard)owner !is null);
			return .tryFormat(_prop.msgs.handCardTabName, (cast(CastCard)owner).id, (cast(CastCard)owner).name);
		}
	}
	@property
	override
	void delegate(string) statusText() {return null;}

	void refreshTitle() { mixin(S_TRACE);
		if (_win && !_win.isDisposed()) _comm.setTitle(shell, title);
	}

	void create(CardType cardType) { mixin(S_TRACE);
		assert (editMode);
		if (editMode && cardType in _paneTbl) { mixin(S_TRACE);
			_paneTbl[cardType].create();
		} else { mixin(S_TRACE);
			throw new Exception(.format("can not create: %s", cardType));
		}
	}

	CardPane open(CardType cardType, bool shellActivate) { mixin(S_TRACE);
		assert (editMode);
		if (_ownerType is OwnerType.Summary) {
			return _comm.openCardPane(cardType, shellActivate);
		} else if (auto tabf = cast(CTabFolder)_tabf) { mixin(S_TRACE);
			foreach (i, pane; _pane) { mixin(S_TRACE);
				if (pane.cardType is cardType) { mixin(S_TRACE);
					tabf.setSelection(_tab[i]);
					return pane;
				}
			}
		}
		throw new Exception(.format("can not open: %s", cardType));
	}

	void refresh(Summary summ) { mixin(S_TRACE);
		assert (_ownerType is OwnerType.Summary);
		assert (editMode);
		refreshAll(summ, summ);
	}

	void refresh(Summary summ, CastCard owner) { mixin(S_TRACE);
		assert (_ownerType is OwnerType.Cast);
		assert (editMode);
		refreshAll(summ, owner);
	}

	private void refreshAll(Summary summ, CWXPath owner) { mixin(S_TRACE);
		_owner = owner;
		_summ = summ;
		foreach (f; _pane) { mixin(S_TRACE);
			f.refreshAll(summ, owner);
		}
		if (withArea) { mixin(S_TRACE);
			_areas.summary = summ;
		}
		if (_win && !_win.isDisposed()) { mixin(S_TRACE);
			refreshTitle();
		}
	}
	private void refreshStatusLine() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		if (auto tabf = cast(CTabFolder)_tabf) { mixin(S_TRACE);
			string s = "";
			if (tabf.getSelectionIndex() == areaIndex) { mixin(S_TRACE);
				s = _areas.statusLine;
			} else { mixin(S_TRACE);
				s = _pane[selectionCardIndex].statusLine;
			}
			_comm.setStatusLine(_tabf, s);
		} else { mixin(S_TRACE);
			_comm.setStatusLine(_comp, _pane[0].statusLine);
		}
	}

	@property
	private TCPD tcpd() { mixin(S_TRACE);
		if (auto tabf = cast(CTabFolder)_tabf) { mixin(S_TRACE);
			if (tabf.getSelectionIndex() == areaIndex) return _areas;
			return _pane[selectionCardIndex];
		}
		return _pane[0];
	}
	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				if (tcpd.canDoTCPD) { mixin(S_TRACE);
					tcpd.cut(se);
				}
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			if (tcpd.canDoTCPD) { mixin(S_TRACE);
				tcpd.copy(se);
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				if (tcpd.canDoTCPD) { mixin(S_TRACE);
					tcpd.paste(se);
				}
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				if (tcpd.canDoTCPD) { mixin(S_TRACE);
					tcpd.del(se);
				}
			}
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				if (tcpd.canDoTCPD) { mixin(S_TRACE);
					tcpd.clone(se);
				}
			}
		}
		bool canDoTCPD() { mixin(S_TRACE);
			return editMode;
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoT && editMode;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoC;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoP && editMode;
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoD && editMode;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoClone && editMode;
		}
	}
	private Ret selectPane(Ret, string Method, bool Area = true)() { mixin(S_TRACE);
		static if (is(Ret:void)) {
			static immutable R = "";
		} else {
			static immutable R = "r = ";
			Ret r;
		}
		static if (Area) {
			if (auto tabf = cast(CTabFolder)_tabf) { mixin(S_TRACE);
				if (tabf.getSelectionIndex() == areaIndex) { mixin(S_TRACE);
					mixin(R ~ "_areas." ~ Method ~ "();");
					static if (!is(Ret:void)) {
						return r;
					} else {
						return;
					}
				}
			}
		}
		mixin(R ~ "_pane[selectionCardIndex]." ~ Method ~ "();");
		static if (!is(Ret:void)) {
			return r;
		}
	}
	void edit() { mixin(S_TRACE);
		selectPane!(void, "edit")();
	}
	@property
	bool canEdit() { mixin(S_TRACE);
		return selectPane!(bool, "canEdit")();
	}

	void editHand() { mixin(S_TRACE);
		int i = selectionCardIndex;
		if (0 <= i) _pane[i].editHand();
	}
	@property
	bool canEditHand() { mixin(S_TRACE);
		int i = selectionCardIndex;
		if (0 <= i) return _pane[i].canEdit;
		return false;
	}

	void reNumbering() { mixin(S_TRACE);
		assert (editMode);
		selectPane!(void, "reNumbering")();
	}
	@property
	bool canReNumbering() { mixin(S_TRACE);
		assert (editMode);
		return selectPane!(bool, "canReNumbering")();
	}
	bool canUndo() { mixin(S_TRACE);
		assert (editMode);
		return selectPane!(bool, "canUndo")();
	}
	bool canRedo() { mixin(S_TRACE);
		assert (editMode);
		return selectPane!(bool, "canRedo")();
	}
	void undo() { mixin(S_TRACE);
		assert (editMode);
		selectPane!(void, "undo")();
	}
	void redo() { mixin(S_TRACE);
		assert (editMode);
		selectPane!(void, "redo")();
	}
	bool canUp() { mixin(S_TRACE);
		assert (editMode);
		return selectPane!(bool, "canUp")();
	}
	bool canDown() { mixin(S_TRACE);
		assert (editMode);
		return selectPane!(bool, "canDown")();
	}
	void up() { mixin(S_TRACE);
		assert (editMode);
		selectPane!(void, "up")();
	}
	void down() { mixin(S_TRACE);
		assert (editMode);
		selectPane!(void, "down")();
	}

	void replaceID() {
		assert (editMode);
		selectPane!(void, "replaceID")();
	}
	@property
	bool canReplaceID() {
		assert (editMode);
		return selectPane!(bool, "canReplaceID")();
	}

	void selectConnectedResource() {
		assert (editMode);
		selectPane!(void, "selectConnectedResource", false)();
	}
	@property
	bool canSelectConnectedResource() {
		assert (editMode);
		return selectPane!(bool, "canSelectConnectedResource", false)();
	}

	void doImport() { mixin(S_TRACE);
		assert (!editMode);
		selectPane!(void, "doImport")();
	}
	@property
	bool canDoImport() { mixin(S_TRACE);
		assert (!editMode);
		return selectPane!(bool, "canDoImport")();
	}

	void removeRef() { mixin(S_TRACE);
		assert (_ownerType is OwnerType.Cast);
		assert (editMode);
		selectPane!(void, "removeRef", false)();
	}
	@property
	bool canRemoveRef() { mixin(S_TRACE);
		assert (editMode);
		return selectPane!(bool, "canRemoveRef", false)();
	}

	void editUseEvent(bool canDuplicate = false) { mixin(S_TRACE);
		int i = selectionCardIndex;
		if (0 <= i) { mixin(S_TRACE);
			if (_pane[i].cardType is CardType.Skill || _pane[i].cardType is CardType.Item || _pane[i].cardType is CardType.Beast) { mixin(S_TRACE);
				_pane[i].editUseEvent(canDuplicate);
			}
		}
	}
	@property
	bool canEditUseEvent() { mixin(S_TRACE);
		int i = selectionCardIndex;
		if (0 <= i) { mixin(S_TRACE);
			if (_pane[i].cardType is CardType.Skill || _pane[i].cardType is CardType.Item || _pane[i].cardType is CardType.Beast) { mixin(S_TRACE);
				return _pane[i].canEdit;
			}
		}
		return false;
	}

	bool isSelected() { mixin(S_TRACE);
		return selectPane!(bool, "isSelected")();
	}
	@property
	private int selectionCardIndex() { mixin(S_TRACE);
		if (auto tabf = cast(CTabFolder)_tabf) {
			int i = tabf.getSelectionIndex();
			if (withArea) i--;
			return i;
		} else {
			return 0;
		}
	}

	@property
	private int areaIndex() { return withArea ? 0 : -2; }

	private bool openCWXPathEff(CardType cardType, string path, bool shellActivate) { mixin(S_TRACE);
		if (cardType !in _paneTbl) return false;
		auto cate = cpcategory(path);
		if (std.string.endsWith(cate, "view")) { mixin(S_TRACE);
			.forceFocus(_paneTbl[cardType].widget, shellActivate);
			return true;
		}
		auto index = cpindex(path);
		bool isId = std.string.endsWith(cate, ":id") != 0;
		Card card;
		if (isId) { mixin(S_TRACE);
			card = _paneTbl[cardType].card(index);
			if (!card) return false;
			index = .cCountUntil!("a is b")(_paneTbl[cardType].cards, card);
		} else { mixin(S_TRACE);
			if (index >= _paneTbl[cardType].cards.length) return false;
			card = _paneTbl[cardType].cards[index];
		}
		path = cpbottom(path);
		if (cpempty(path) || ((cardType is CardType.Skill || cardType is CardType.Item || cardType is CardType.Beast) && "motion" == cpcategory(path))) { mixin(S_TRACE);
			if (!cphasattr(path, "nofocus")) .forceFocus(_paneTbl[cardType].widget, shellActivate);
			_paneTbl[cardType].select(cast(int)index);
			_comm.refreshToolBar();
			if (editMode) { mixin(S_TRACE);
				if (cphasattr(path, "opendialog") || !cpempty(path)) { mixin(S_TRACE);
					auto dlg = _paneTbl[cardType].edit();
					if (!dlg) return false;
					if (!cpempty(path)) { mixin(S_TRACE);
						return dlg.openCWXPath(path, shellActivate);
					}
				}
			}
			return true;
		}
		if (cardType is CardType.Cast) {
			cate = cpcategory(path);
			switch (cate) {
			case "skillcard", "itemcard", "beastcard",
					"skillcard:id", "itemcard:id", "beastcard:id",
					"skillcardview", "itemcardview", "beastcardview": { mixin(S_TRACE);
				if (!cphasattr(path, "nofocus")) forceFocus(_paneTbl[cardType].widget, shellActivate);
				return _comm.openHands(_prop, _summ, cast(CastCard)card, shellActivate).openCWXPath(path, shellActivate);
			} break;
			default: break;
			}
		} else if (cardType is CardType.Info) {
			if (cpcategory(path) == "event") { mixin(S_TRACE);
				if (!cphasattr(path, "nofocus")) forceFocus(_pane[cardType].widget, shellActivate);
				assert (cast(EffectCard)card !is null);
				return _comm.openUseEvents(_prop, _summ, cast(EffectCard)card, shellActivate, false).openCWXPath(path, shellActivate);
			}
		}
		return false;
	}
	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		switch (cate) {
		case "castcard", "castcard:id", "castcardview": { mixin(S_TRACE);
			return openCWXPathEff(CardType.Cast, path, shellActivate);
		} break;
		case "skillcard", "skillcard:id", "skillcardview": { mixin(S_TRACE);
			return openCWXPathEff(CardType.Skill, path, shellActivate);
		} break;
		case "itemcard", "itemcard:id", "itemcardview": { mixin(S_TRACE);
			return openCWXPathEff(CardType.Item, path, shellActivate);
		} break;
		case "beastcard", "beastcard:id", "beastcardview": { mixin(S_TRACE);
			return openCWXPathEff(CardType.Beast, path, shellActivate);
		} break;
		case "infocard", "infocard:id", "infocardview": { mixin(S_TRACE);
			return openCWXPathEff(CardType.Info, path, shellActivate);
		} break;
		default: break;
		}
		return false;
	}
	@property
	override
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		if (editMode) { mixin(S_TRACE);
			string[] last;
			foreach (i, pane; _pane) { mixin(S_TRACE);
				if (selectionCardIndex == i) { mixin(S_TRACE);
					last = pane.openedCWXPath;
				} else { mixin(S_TRACE);
					r ~= pane.openedCWXPath;
				}
			}
			r ~= last;
		}
		return r;
	}
}

private class DelTemp : DisposeListener {
	private Summary _cc;
	this (Summary cc) { mixin(S_TRACE);
		_cc = cc;
	}
	override void widgetDisposed(DisposeEvent dse) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			_cc.delTemp();
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
}
class AddCard {
private:
	static class AddS {
		Commons comm;
		Props prop;
		Composite parent;
		Summary toc;
		void delegate(CardWindow[]) addScenario;
		this (Commons comm, Props prop,
				Composite parent, Summary toc, void delegate(CardWindow[]) addScenario) { mixin(S_TRACE);
			this.comm = comm;
			this.prop = prop;
			this.parent = parent;
			this.toc = toc;
			this.addScenario = addScenario;
		}
		void addS(Summary[] ccs) { mixin(S_TRACE);
			CardWindow[] r;
			foreach (i, cc; ccs) { mixin(S_TRACE);
				if (cc) { mixin(S_TRACE);
					auto shl = cast(Shell) parent;
					auto pane = comm.sidePane;
					auto acw = new CardWindow(comm, prop, CardWindowKind.ImportSource, pane, cc, cc, toc);
					acw.shell.addDisposeListener(new DelTemp(cc));
					r ~= acw;
				}
			}
			addScenario(r);
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
		opt.cardOnly = false; // 他のリソースを連鎖的にインポートする可能性がある
		opt.textOnly = false;
		opt.doubleIO = prop.var.etc.doubleIO;
		opt.expandXMLs = false;
		return opt;
	}
public:
	static void openScenario(Commons comm, Props prop, Composite parent, void delegate(string) status,
			Summary summ, Summary toc, void delegate(CardWindow[]) addScenario) { mixin(S_TRACE);
		parent = pane(parent);
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenarios(prop, loadOption(prop), comm.mainShell, status, prop.msgs.dlgTitAddScenario, &addS.addS);
	}
	static void openScenario(Commons comm, Props prop, Composite parent, void delegate(string) status,
			Summary summ, Summary toc, string[] files, void delegate(CardWindow[]) addScenario) { mixin(S_TRACE);
		parent = pane(parent);
		auto addS = new AddS(comm, prop, parent, toc, addScenario);
		loadScenariosFromFile(prop, loadOption(prop), comm.mainShell, status, files, &addS.addS);
	}
}

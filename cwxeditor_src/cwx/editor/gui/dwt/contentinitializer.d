
module cwx.editor.gui.dwt.contentinitializer;

import cwx.area;
import cwx.background;
import cwx.card;
import cwx.event;
import cwx.script;
import cwx.structs;
import cwx.skin;
import cwx.summary;
import cwx.types;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.eventdialog;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.scripterrordialog;
import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.ascii;
import std.exception;
import std.string;
import std.traits;

import org.eclipse.swt.all;

import java.lang.all : ArrayWrapperString;

// TODO: ツールチップでテキスト表示

/// イベントコンテントの初期値を設定する。
class ContentInitialValueEditor : TCPD {
	void delegate()[] modEvent;

	private class CUndo : Undo {
		private Content[] _cs = null;

		this (in Content[] cs) { mixin(S_TRACE);
			foreach (c; cs) _cs ~= c.dup;
		}

		private void impl() { mixin(S_TRACE);
			foreach (i, ref cBase; _cs) { mixin(S_TRACE);
				auto c = cBase;
				auto itm = _list.getItem(_cTypeTable[c.type]);
				cBase = (cast(Content)itm.getData()).dup;
				itm.setData(c);
				auto edited = c != _inits[c.type];
				_edited[c.type] = edited;
				itm.setText(1, edited ? _comm.prop.msgs.editedInitializer : "");
			}
			foreach (modDlg; modEvent) modDlg();
			_comm.refreshToolBar();
			updateToolTip();
		}

		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { }
	}

	private void store(in Content[] c) { _undo ~= new CUndo(c); }

	private Commons _comm;

	private Table _list;
	private int[CType] _cTypeTable;
	private bool[CType] _edited;
	private Content[CType] _inits;
	private BgImageS[] _bgImgs;

	private bool _legacy = false;
	private string _dataVersion = LATEST_VERSION;
	private Summary _summ = null;

	private UndoManager _undo = null;

	private EventDialog[int] _editDlgs;

	this (Commons comm, Composite parent) { mixin(S_TRACE);
		_comm = comm;

		_list = .rangeSelectableTable(parent, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER);
		auto col1 = new TableColumn(_list, SWT.NONE);
		auto col2 = new TableColumn(_list, SWT.NONE);
		foreach (cGrp; EnumMembers!CTypeGroup) { mixin(S_TRACE);
			foreach (cType; CTYPE_GROUP[cGrp]) { mixin(S_TRACE);
				if (!cType.hasDialog(false)) continue;
				_cTypeTable[cType] = _list.getItemCount();
				auto itm = new TableItem(_list, SWT.NONE);
				itm.setText(0, _comm.prop.msgs.contentName(cType));
				itm.setImage(0, _comm.prop.images.content(cType));
				itm.setText(1, _comm.prop.msgs.editedInitializer);
			}
		}
		col1.pack();
		col2.pack();

		auto menu = new Menu(_list.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.EditProp, &editContent, &canEditContent);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, () => _undo.canUndo);
		createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, () => _undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.ResetValues, &resetValues, () => !isInitialValues());
		createMenuItem(comm, menu, MenuID.ResetValuesAll, &resetValuesAll, () => !isInitialValuesAll());
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(_comm, menu, this, false, true, true, false, false);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.SelectAll, () => _list.setSelection(_list.getItems()), () => _list.getItemCount() != _list.getSelectionCount());
		_list.setMenu(menu);

		.listener(_list, SWT.Selection, &_comm.refreshToolBar);
		.listener(_list, SWT.MouseDoubleClick, &editContent);
		.listener(_list, SWT.MouseEnter, &updateToolTipFrom);
		.listener(_list, SWT.MouseMove, &updateToolTipFrom);
		.listener(_list, SWT.KeyDown, (e) { mixin(S_TRACE);
			if (e.character == SWT.CR) { mixin(S_TRACE);
				editContent();
			}
		});
		.listener(_list, SWT.Dispose, { mixin(S_TRACE);
			foreach (dlg; _editDlgs.values) { mixin(S_TRACE);
				dlg.forceCancel();
			}
		});
	}

	Control widget() { return _list; }

	@property
	void bgImagesDefault(BgImageS[] bgImgs) { _bgImgs = bgImgs; }

	private void updateToolTipFrom(Event e) { mixin(S_TRACE);
		updateToolTipImpl(_list.getItem(new Point(e.x, e.y)));
	}
	private void updateToolTip() { mixin(S_TRACE);
		auto itm = _list.getItem(_list.toControl(_list.getDisplay().getCursorLocation()));
		updateToolTipImpl(itm);
	}
	private void updateToolTipImpl(TableItem itm) { mixin(S_TRACE);
		auto toolTip = "";
		if (itm) { mixin(S_TRACE);
			auto c = cast(Content)itm.getData();
			toolTip = .contentText(_comm, c, _summ);
		}
		if (toolTip != _list.getToolTipText()) { mixin(S_TRACE);
			_list.setToolTipText(toolTip);
		}
	}

	void setInitializer(Content[CType] initializer, bool legacy, string dataVersion, UndoManager undo) { mixin(S_TRACE);
		_undo = undo;
		_legacy = legacy;
		_dataVersion = dataVersion;
		auto skin = findSkin(_comm, _comm.prop, null);
		_edited = null;
		_inits = null;
		_summ = new Summary("", _comm.prop.var.etc.defaultSkin, _comm.prop.var.etc.defaultSkinName, "", false, _legacy);
		_summ.dataVersion = _dataVersion;
		foreach (cGrp; EnumMembers!CTypeGroup) { mixin(S_TRACE);
			foreach (cType; CTYPE_GROUP[cGrp]) { mixin(S_TRACE);
				if (!cType.hasDialog(false)) continue;
				auto itm = _list.getItem(_cTypeTable[cType]);
				auto init = initial(skin, cType);

				auto p = cType in initializer;
				if (p && *p != init) { mixin(S_TRACE);
					itm.setData(*p);
					itm.setText(1, _comm.prop.msgs.editedInitializer);
					_edited[cType] = true;
				} else { mixin(S_TRACE);
					itm.setData(init.dup);
					itm.setText(1, "");
					_edited[cType] = false;
				}
				_inits[cType] = init;
			}
		}
		foreach (dlg; _editDlgs.values) { mixin(S_TRACE);
			dlg.forceCancel();
		}
		_list.deselectAll();
		_comm.refreshToolBar();
		updateToolTip();
	}
	Content[CType] getInitializer() { mixin(S_TRACE);
		Content[CType] r;
		foreach (cType, edited; _edited) { mixin(S_TRACE);
			if (!edited) continue;
			auto i = _cTypeTable[cType];
			auto itm = _list.getItem(i);
			auto c = cast(Content)itm.getData();
			assert (c !is null);
			assert (c.type is cType);

			r[cType] = c.dup;
		}
		return r;
	}

	private Content initial(in Skin skin, CType cType) { mixin(S_TRACE);
		return .initial(_comm, skin, _legacy, _dataVersion, _bgImgs, new Content(cType, ""));
	}

	void editContent() { mixin(S_TRACE);
		if (!canEditContent) return;
		foreach (sel; _list.getSelection()) { mixin(S_TRACE);
			auto c = cast(Content)sel.getData();
			auto cc = c.dup;
			assert (c !is null);
			auto i = _cTypeTable[c.type];

			auto p = i in _editDlgs;
			if (p) { mixin(S_TRACE);
				p.active();
				return;
			}

			auto dlg = .createEventDialog(_comm, _summ, _list.getShell(), c, null, false);
			dlg.appliedEvent ~= { mixin(S_TRACE);
				if (c == cc) return;
				store([cc]);
				cc = c.dup;
				auto edited = c != _inits[c.type];
				_edited[c.type] = edited;
				sel.setText(1, edited ? _comm.prop.msgs.editedInitializer : "");
				foreach (modDlg; modEvent) modDlg();
				_comm.refreshToolBar();
				updateToolTip();
			};
			_editDlgs[i] = dlg;
			dlg.closeEvent ~= { mixin(S_TRACE);
				_editDlgs.remove(i);
			};
			dlg.open();
		}
	}
	@property
	bool canEditContent() { mixin(S_TRACE);
		return _list.getSelectionIndex() != -1;
	}

	void resetValues() { mixin(S_TRACE);
		if (isInitialValues()) return;
		resetValuesImpl(_list.getSelection());
	}
	void resetValuesAll() { mixin(S_TRACE);
		if (isInitialValuesAll()) return;
		resetValuesImpl(_list.getItems());
	}
	private void resetValuesImpl(TableItem[] items) { mixin(S_TRACE);
		Content[] cs;
		foreach (sel; items) { mixin(S_TRACE);
			cs ~= cast(Content)sel.getData();
		}
		store(cs);
		foreach (sel; items) { mixin(S_TRACE);
			auto c = cast(Content)sel.getData();
			sel.setData(_inits[c.type].dup);
			_edited[c.type] = false;
			sel.setText(1, "");
		}
		foreach (modDlg; modEvent) modDlg();
		_comm.refreshToolBar();
		updateToolTip();
	}

	bool isInitialValues() { mixin(S_TRACE);
		return isInitialValuesImpl(_list.getSelection());
	}
	bool isInitialValuesAll() { mixin(S_TRACE);
		return isInitialValuesImpl(_list.getItems());
	}
	private bool isInitialValuesImpl(TableItem[] items) { mixin(S_TRACE);
		foreach (sel; items) { mixin(S_TRACE);
			auto c = cast(Content)sel.getData();
			if (c != _inits[c.type]) return false;
		}
		return true;
	}

	override
	void cut(SelectionEvent se) { }
	override
	void copy(SelectionEvent se) { mixin(S_TRACE);
		auto sels = _list.getSelection();
		if (!sels.length) return;
		auto e = XNode.create("ContentInitializer");
		foreach (itm; sels) { mixin(S_TRACE);
			auto c = cast(Content)itm.getData();
			c.toNode(e, null);
		}
		XMLtoCB(_comm.prop, _comm.clipboard, e.text);
		_comm.refreshToolBar();
	}

	override
	void paste(SelectionEvent se) { mixin(S_TRACE);
		Content[] cs;

		auto xml = CBtoXML(_comm.clipboard);
		if (xml) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				if (node.name == "ContentInitializer") { mixin(S_TRACE);
					node.onTag[null] = (ref XNode node) {
						cs ~= Content.createFromNode(node, null);
					};
					node.parse();
				}
			} catch (Exception e) { mixin (S_TRACE);
				printStackTrace();
				debugln(e);
			}
		}

		Content[] stored;
		foreach (c; cs) { mixin(S_TRACE);
			auto i = _cTypeTable[c.type];
			auto cc = cast(Content)_list.getItem(i).getData();
			if (c == cc) continue;
			stored ~= cc;
		}

		if (stored.length) store(stored);

		_list.deselectAll();
		foreach (c; cs) { mixin(S_TRACE);
			auto i = _cTypeTable[c.type];
			auto itm = _list.getItem(i);
			auto cc = itm.getData();
			if (c != cc) { mixin(S_TRACE);
				auto edited = c != _inits[c.type];
				_edited[c.type] = edited;
				itm.setText(1, edited ? _comm.prop.msgs.editedInitializer : "");
				itm.setData(c);
			}
			_list.select(i);
		}
		if (stored.length) { mixin(S_TRACE);
			foreach (modDlg; modEvent) modDlg();
			_comm.refreshToolBar();
			updateToolTip();
		}
	}
	override
	void del(SelectionEvent se) { }
	override
	void clone(SelectionEvent se) { }
	@property
	override
	bool canDoTCPD() { return true; }
	@property
	override
	bool canDoT() { return false; }
	@property
	override
	bool canDoC() { return _list.getSelectionIndex() != -1; }
	@property
	override
	bool canDoP() { return CBisXML(_comm.clipboard); }
	@property
	override
	bool canDoClone() { return false; }
	@property
	override
	bool canDoD() { return false; }
}

@property
bool hasDialog(CType type, bool existsSummary = true) { mixin(S_TRACE);
	switch (type) {
	case CType.START:
	case CType.END_BAD_END:
	case CType.EFFECT_BREAK:
	case CType.ELAPSE_TIME:
	case CType.BRANCH_AREA:
	case CType.BRANCH_BATTLE:
	case CType.BRANCH_IS_BATTLE:
	case CType.SHOW_PARTY:
	case CType.HIDE_PARTY:
	case CType.BRANCH_MULTI_RANDOM:
		return false;
	case CType.START_BATTLE:
	case CType.LINK_START:
	case CType.CALL_START:
	case CType.LINK_PACKAGE:
	case CType.CALL_PACKAGE:
	case CType.BRANCH_FLAG:
	case CType.SET_FLAG:
	case CType.REVERSE_FLAG:
	case CType.BRANCH_MULTI_STEP:
	case CType.BRANCH_STEP:
	case CType.SET_STEP:
	case CType.SET_STEP_UP:
	case CType.SET_STEP_DOWN:
	case CType.SUBSTITUTE_STEP:
	case CType.SUBSTITUTE_FLAG:
	case CType.BRANCH_STEP_CMP:
	case CType.BRANCH_FLAG_CMP:
	case CType.CHECK_FLAG:
	case CType.BRANCH_CAST:
	case CType.BRANCH_INFO:
	case CType.GET_INFO:
	case CType.LOSE_CAST:
	case CType.LOSE_INFO:
		return existsSummary;
	default:
		return true;
	}
}

EventDialog createEventDialog(Commons comm, Summary summ, Shell parentShell, Content evt, Content parent, bool create) { mixin(S_TRACE);
	EventDialog dlg;
	switch (evt.type) {
	case CType.START_BATTLE: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.START_BATTLE, Battle, "summary.battles")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.END: { mixin(S_TRACE);
		dlg = new ClearEventDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.CHANGE_AREA: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.CHANGE_AREA, Area, "summary.areas")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.CHANGE_BG_IMAGE: { mixin(S_TRACE);
		if (create) { mixin(S_TRACE);
			evt.backs = createBgImages(findSkin(comm, comm.prop, summ), comm.prop.var.etc.bgImagesDefault);
		}
		dlg = new BgImagesDialog(comm, comm.prop, parentShell, summ, parent, evt, null, CType.CHANGE_BG_IMAGE);
		break;
	} case CType.EFFECT: { mixin(S_TRACE);
		dlg = new EffectDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LINK_START: { mixin(S_TRACE);
		dlg = new StartSelectDialog!(CType.LINK_START)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LINK_PACKAGE: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.LINK_PACKAGE, Package, "summary.packages")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.TALK_MESSAGE: { mixin(S_TRACE);
		dlg = new MessageDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.TALK_DIALOG: { mixin(S_TRACE);
		dlg = new SpeakDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.PLAY_BGM: { mixin(S_TRACE);
		dlg = new BgmDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.PLAY_SOUND: { mixin(S_TRACE);
		dlg = new SeDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.WAIT: { mixin(S_TRACE);
		dlg = new WaitEventDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.CALL_START: { mixin(S_TRACE);
		dlg = new StartSelectDialog!(CType.CALL_START)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.CALL_PACKAGE: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.CALL_PACKAGE, Package, "summary.packages")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_FLAG: { mixin(S_TRACE);
		dlg = new BrFlagDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BRANCH_MULTI_STEP: { mixin(S_TRACE);
		dlg = new BrStepNDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BRANCH_STEP: { mixin(S_TRACE);
		dlg = new BrStepULDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BRANCH_SELECT: { mixin(S_TRACE);
		dlg = new BrMemberDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_ABILITY: { mixin(S_TRACE);
		dlg = new BrPowerDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_RANDOM: { mixin(S_TRACE);
		dlg = new BrRandomEventDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_LEVEL: { mixin(S_TRACE);
		dlg = new BrLevelDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_STATUS: { mixin(S_TRACE);
		dlg = new BrStateDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_PARTY_NUMBER: { mixin(S_TRACE);
		dlg = new BrNumEventDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_CAST: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.BRANCH_CAST, CastCard, "summary.casts")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_ITEM: { mixin(S_TRACE);
		dlg = new BrItemDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_SKILL: { mixin(S_TRACE);
		dlg = new BrSkillDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_INFO: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.BRANCH_INFO, InfoCard, "summary.infos")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_BEAST: { mixin(S_TRACE);
		dlg = new BrBeastDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_MONEY: { mixin(S_TRACE);
		dlg = new MoneyEventDialog!(CType.BRANCH_MONEY)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_COUPON: { mixin(S_TRACE);
		dlg = new BranchCouponDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_COMPLETE_STAMP: { mixin(S_TRACE);
		dlg = new EndEventDialog!(CType.BRANCH_COMPLETE_STAMP)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_GOSSIP: { mixin(S_TRACE);
		dlg = new GossipEventDialog!(CType.BRANCH_GOSSIP)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.SET_FLAG: { mixin(S_TRACE);
		dlg = new FlagSetDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.SET_STEP: { mixin(S_TRACE);
		dlg = new StepSetDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.SET_STEP_UP: { mixin(S_TRACE);
		dlg = new StepPlusDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.SET_STEP_DOWN: { mixin(S_TRACE);
		dlg = new StepMinusDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.REVERSE_FLAG: { mixin(S_TRACE);
		dlg = new FlagRDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.CHECK_FLAG: { mixin(S_TRACE);
		dlg = new FlagJudgeDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.GET_CAST: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.GET_CAST, CastCard, "summary.casts")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GET_ITEM: { mixin(S_TRACE);
		dlg = new GetItemDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GET_SKILL: { mixin(S_TRACE);
		dlg = new GetSkillDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GET_INFO: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.GET_INFO, InfoCard, "summary.infos")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GET_BEAST: { mixin(S_TRACE);
		dlg = new GetBeastDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GET_MONEY: { mixin(S_TRACE);
		dlg = new MoneyEventDialog!(CType.GET_MONEY)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GET_COUPON: { mixin(S_TRACE);
		dlg = new GetCouponDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GET_COMPLETE_STAMP: { mixin(S_TRACE);
		dlg = new EndEventDialog!(CType.GET_COMPLETE_STAMP)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GET_GOSSIP: { mixin(S_TRACE);
		dlg = new GossipEventDialog!(CType.GET_GOSSIP)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LOSE_CAST: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.LOSE_CAST, CastCard, "summary.casts")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LOSE_ITEM: { mixin(S_TRACE);
		dlg = new LostItemDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LOSE_SKILL: { mixin(S_TRACE);
		dlg = new LostSkillDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LOSE_INFO: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.LOSE_INFO, InfoCard, "summary.infos")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LOSE_BEAST: { mixin(S_TRACE);
		dlg = new LostBeastDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LOSE_MONEY: { mixin(S_TRACE);
		dlg = new MoneyEventDialog!(CType.LOSE_MONEY)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LOSE_COUPON: { mixin(S_TRACE);
		dlg = new LoseCouponDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LOSE_COMPLETE_STAMP: { mixin(S_TRACE);
		dlg = new EndEventDialog!(CType.LOSE_COMPLETE_STAMP)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LOSE_GOSSIP: { mixin(S_TRACE);
		dlg = new GossipEventDialog!(CType.LOSE_GOSSIP)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.REDISPLAY: { mixin(S_TRACE);
		dlg = new RefreshDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.SUBSTITUTE_STEP: { mixin(S_TRACE);
		dlg = new SubstituteStepDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.SUBSTITUTE_FLAG: { mixin(S_TRACE);
		dlg = new SubstituteFlagDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BRANCH_STEP_CMP: { mixin(S_TRACE);
		dlg = new BrStepCmpDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BRANCH_FLAG_CMP: { mixin(S_TRACE);
		dlg = new BrFlagCmpDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BRANCH_RANDOM_SELECT: { mixin(S_TRACE);
		dlg = new BrRandomSelectDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_KEY_CODE: { mixin(S_TRACE);
		dlg = new BrKeyCodeDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.CHECK_STEP: { mixin(S_TRACE);
		dlg = new CheckStepDialog(comm, comm.prop, parentShell, summ, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BRANCH_ROUND: { mixin(S_TRACE);
		dlg = new BranchRoundDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.MOVE_BG_IMAGE: { mixin(S_TRACE);
		dlg = new MoveBgImageDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.REPLACE_BG_IMAGE: { mixin(S_TRACE);
		dlg = new BgImagesDialog(comm, comm.prop, parentShell, summ, parent, evt, null, CType.REPLACE_BG_IMAGE);
		break;
	} case CType.LOSE_BG_IMAGE: { mixin(S_TRACE);
		dlg = new LoseBgImageDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BRANCH_MULTI_COUPON: { mixin(S_TRACE);
		dlg = new BranchMultiCouponDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} default: assert (0);
	}
	return dlg;
}

Content initial(in Commons comm, in Skin skin, bool legacy, string dataVersion, in BgImageS[] bgImagesDefault, Content c) { mixin(S_TRACE);
	if (c.type is CType.CHANGE_BG_IMAGE) { mixin(S_TRACE);
		c.backs = createBgImages(skin, bgImagesDefault);
	} else if (c.type is CType.TALK_DIALOG) { mixin(S_TRACE);
		c.dialogs = [new SDialog];
		if (comm.prop.parent.isTargetVersion(legacy, dataVersion, "2")) c.boundaryCheck = true;
	} else if (c.type is CType.BRANCH_SKILL || c.type is CType.BRANCH_ITEM || c.type is CType.BRANCH_BEAST) { mixin(S_TRACE);
		c.range = Range.FIELD;
	} else if (c.type is CType.LOSE_SKILL || c.type is CType.LOSE_ITEM || c.type is CType.LOSE_BEAST) { mixin(S_TRACE);
		c.range = Range.FIELD;
	} else if (c.type is CType.TALK_MESSAGE) { mixin(S_TRACE);
		if (comm.prop.parent.isTargetVersion(legacy, dataVersion, "2")) c.boundaryCheck = true;
	} else if (c.type is CType.BRANCH_KEY_CODE) { mixin(S_TRACE);
		if (legacy) { mixin(S_TRACE);
			c.targetIsSkill = true;
			c.targetIsItem = true;
			c.targetIsBeast = true;
			c.targetIsHand = true;
		}
	}
	return c;
}

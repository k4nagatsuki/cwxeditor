
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
import cwx.usecounter;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.eventdialog;
import cwx.editor.gui.dwt.exprutils;
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

import java.lang.all : ArrayWrapperString, Runnable;

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

	private EventDialog[CType] _editDlgs;

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
			if (.isEnterKey(e.keyCode)) { mixin(S_TRACE);
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
	void bgImagesDefault(BgImageS[] bgImgs) { mixin(S_TRACE);
		_bgImgs = bgImgs;
		auto p = CType.ChangeBgImage in _inits;
		if (p) { mixin(S_TRACE);
			auto itm = _list.getItem(_cTypeTable[CType.ChangeBgImage]);
			auto c = cast(Content)itm.getData();

			auto skin = findSkin(_comm, _comm.prop, _summ);
			auto init = initial(skin, c.type);
			_inits[CType.ChangeBgImage] = init;
			if (!_edited.get(c.type, false)) { mixin(S_TRACE);
				store([c]);
				c = init.dup;
				itm.setData(c);
			}

			auto edited = (c != init);
			itm.setText(1, edited ? _comm.prop.msgs.editedInitializer : "");
			_edited[c.type] = edited;

			updateToolTip();
		}
	}

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
			// BUG: そのままツールチップを設定すると異常に反応が遅れる現象が頻発する
			_list.getDisplay().asyncExec(new class Runnable {
				override void run() { mixin(S_TRACE);
					if (_list.isDisposed()) return;
					_list.setToolTipText(toolTip);
				}
			});
		}
	}

	void setInitializer(Content[CType] initializer, bool legacy, string dataVersion, UndoManager undo) { mixin(S_TRACE);
		_undo = undo;
		_legacy = legacy;
		_dataVersion = dataVersion;
		_summ = new Summary("", _comm.prop.var.etc.defaultSkin, _comm.prop.var.etc.defaultSkinName, "", false, _legacy);
		_summ.dataVersion = _dataVersion;
		auto skin = findSkin(_comm, _comm.prop, _summ);
		_edited = null;
		_inits = null;
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
			editContentImpl(sel);
		}
	}
	private void editContentImpl(TableItem sel) {
		auto c = cast(Content)sel.getData();
		auto cc = c.dup;
		assert (c !is null);
		auto i = _cTypeTable[c.type];

		auto p = c.type in _editDlgs;
		if (p) { mixin(S_TRACE);
			p.active();
			return;
		}

		auto dlg = .createEventDialog(_comm, _summ, _summ ? _summ.useCounter : null, _list.getShell(), c, null, false);
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
		_editDlgs[c.type] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(c.type);
		};
		dlg.open();
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
		auto e = XNode.create("Contents");
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
				if (node.name == "Contents") { mixin(S_TRACE);
					node.onTag[null] = (ref XNode node) {
						cs ~= Content.createFromNode(node, null);
					};
					node.parse();
				} else { mixin(S_TRACE);
					auto c = Content.createFromNode(node, null, false);
					if (c) cs ~= c;
				}
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
			}
		} else if (auto scriptObj = cast(ArrayWrapperString)_comm.clipboard.getContents(TextTransfer.getInstance())) { mixin(S_TRACE);
			auto script = scriptObj.array.idup;
			auto base = script;
			CompileOption opt;
			try { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto compiler = new CWXScript(_comm.prop.parent, _summ);
					auto vars = compiler.eatEmptyVars(script, opt);
					if (vars.length) { mixin(S_TRACE);
						auto dlg = new ScriptVarSetDialog(_comm, _summ, _summ.useCounter, _list.getShell(), vars, script, base, opt);
						dlg.appliedEvent ~= { mixin(S_TRACE);
							cs ~= dlg.contents;
						};
						dlg.open();
					} else { mixin(S_TRACE);
						cs ~= cwx.script.compile(_comm.prop.parent, _summ, script, opt);
					}
				} catch (CWXScriptException e) {
					throw e;
				} catch (Throwable e) {
					printStackTrace();
					debugln(e);
					throw new CWXScriptException(__FILE__, __LINE__, "", [CWXSError(_comm.prop.msgs.scriptErrorSystem, 0, 0, __FILE__, __LINE__)], false);
				}
			} catch (CWXScriptException e) {
				auto dlg = new ScriptErrorDialog(_comm, _comm.prop, _list, e, base, opt);
				dlg.open();
			}
		}

		Content[] stored;
		foreach (c; cs) { mixin(S_TRACE);
			if (c.type !in _cTypeTable) continue;
			auto i = _cTypeTable[c.type];
			auto cc = cast(Content)_list.getItem(i).getData();
			if (c == cc) continue;
			stored ~= cc;
		}

		if (stored.length) store(stored);

		_list.deselectAll();
		foreach (c; cs) { mixin(S_TRACE);
			if (c.type !in _cTypeTable) continue;
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
	bool canDoP() { return CBisXML(_comm.clipboard) || CBisText(_comm.clipboard); }
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
	case CType.Start:
	case CType.EndBadEnd:
	case CType.ElapseTime:
	case CType.BranchArea:
	case CType.BranchBattle:
	case CType.BranchIsBattle:
	case CType.BranchMultiRandom:
		return false;
	case CType.StartBattle:
	case CType.LinkStart:
	case CType.CallStart:
	case CType.LinkPackage:
	case CType.CallPackage:
	case CType.BranchFlag:
	case CType.SetFlag:
	case CType.ReverseFlag:
	case CType.BranchMultiStep:
	case CType.BranchStep:
	case CType.SetStep:
	case CType.SetStepUp:
	case CType.SetStepDown:
	case CType.SubstituteStep:
	case CType.SubstituteFlag:
	case CType.BranchStepCmp:
	case CType.BranchFlagCmp:
	case CType.CheckFlag:
	case CType.BranchCast:
	case CType.BranchInfo:
	case CType.GetInfo:
	case CType.LoseCast:
	case CType.LoseInfo:
		return existsSummary;
	default:
		return true;
	}
}

EventDialog createEventDialog(Commons comm, Summary summ, UseCounter uc, Shell parentShell, Content evt, Content parent, bool create) { mixin(S_TRACE);
	EventDialog dlg;
	switch (evt.type) {
	case CType.StartBattle: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.StartBattle, Battle, "summary.battles")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.End: { mixin(S_TRACE);
		dlg = new ClearEventDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.ChangeArea: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.ChangeArea, Area, "summary.areas")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.ChangeBgImage: { mixin(S_TRACE);
		dlg = new BgImagesDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, null, CType.ChangeBgImage);
		break;
	} case CType.Effect: { mixin(S_TRACE);
		dlg = new EffectDialog(comm, comm.prop, parentShell, summ, parent, uc, parent, evt);
		break;
	} case CType.EffectBreak: { mixin(S_TRACE);
		dlg = new EffectBreakDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LinkStart: { mixin(S_TRACE);
		dlg = new StartSelectDialog!(CType.LinkStart)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LinkPackage: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.LinkPackage, Package, "summary.packages")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.TalkMessage: { mixin(S_TRACE);
		dlg = new MessageDialog(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.TalkDialog: { mixin(S_TRACE);
		dlg = new SpeakDialog(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.PlayBgm: { mixin(S_TRACE);
		dlg = new BgmDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.PlaySound: { mixin(S_TRACE);
		dlg = new SeDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.Wait: { mixin(S_TRACE);
		dlg = new WaitEventDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.CallStart: { mixin(S_TRACE);
		dlg = new StartSelectDialog!(CType.CallStart)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.CallPackage: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.CallPackage, Package, "summary.packages")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchFlag: { mixin(S_TRACE);
		dlg = new BrFlagDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BranchMultiStep: { mixin(S_TRACE);
		dlg = new BrStepNDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BranchStep: { mixin(S_TRACE);
		dlg = new BrStepULDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BranchSelect: { mixin(S_TRACE);
		dlg = new BrMemberDialog(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.BranchAbility: { mixin(S_TRACE);
		dlg = new BrPowerDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchRandom: { mixin(S_TRACE);
		dlg = new BrRandomEventDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchLevel: { mixin(S_TRACE);
		dlg = new BrLevelDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchStatus: { mixin(S_TRACE);
		dlg = new BrStateDialog(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.BranchPartyNumber: { mixin(S_TRACE);
		dlg = new BrNumEventDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchCast: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.BranchCast, CastCard, "summary.casts")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchItem: { mixin(S_TRACE);
		dlg = new BrItemDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchSkill: { mixin(S_TRACE);
		dlg = new BrSkillDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchInfo: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.BranchInfo, InfoCard, "summary.infos")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchBeast: { mixin(S_TRACE);
		dlg = new BrBeastDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchMoney: { mixin(S_TRACE);
		dlg = new MoneyEventDialog!(CType.BranchMoney)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchCoupon: { mixin(S_TRACE);
		dlg = new BranchCouponDialog(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.BranchCompleteStamp: { mixin(S_TRACE);
		dlg = new EndEventDialog!(CType.BranchCompleteStamp)(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.BranchGossip: { mixin(S_TRACE);
		dlg = new GossipEventDialog!(CType.BranchGossip)(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.SetFlag: { mixin(S_TRACE);
		dlg = new FlagSetDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.SetStep: { mixin(S_TRACE);
		dlg = new StepSetDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.SetStepUp: { mixin(S_TRACE);
		dlg = new StepPlusDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.SetStepDown: { mixin(S_TRACE);
		dlg = new StepMinusDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.ReverseFlag: { mixin(S_TRACE);
		dlg = new FlagRDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.CheckFlag: { mixin(S_TRACE);
		dlg = new FlagJudgeDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.GetCast: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.GetCast, CastCard, "summary.casts")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GetItem: { mixin(S_TRACE);
		dlg = new GetItemDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GetSkill: { mixin(S_TRACE);
		dlg = new GetSkillDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GetInfo: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.GetInfo, InfoCard, "summary.infos")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GetBeast: { mixin(S_TRACE);
		dlg = new GetBeastDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GetMoney: { mixin(S_TRACE);
		dlg = new MoneyEventDialog!(CType.GetMoney)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.GetCoupon: { mixin(S_TRACE);
		dlg = new GetCouponDialog(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.GetCompleteStamp: { mixin(S_TRACE);
		dlg = new EndEventDialog!(CType.GetCompleteStamp)(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.GetGossip: { mixin(S_TRACE);
		dlg = new GossipEventDialog!(CType.GetGossip)(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.LoseCast: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.LoseCast, CastCard, "summary.casts")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LoseItem: { mixin(S_TRACE);
		dlg = new LostItemDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LoseSkill: { mixin(S_TRACE);
		dlg = new LostSkillDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LoseInfo: { mixin(S_TRACE);
		dlg = new AreaSelectDialog!(CType.LoseInfo, InfoCard, "summary.infos")
			(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LoseBeast: { mixin(S_TRACE);
		dlg = new LostBeastDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LoseMoney: { mixin(S_TRACE);
		dlg = new MoneyEventDialog!(CType.LoseMoney)(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.LoseCoupon: { mixin(S_TRACE);
		dlg = new LoseCouponDialog(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.LoseCompleteStamp: { mixin(S_TRACE);
		dlg = new EndEventDialog!(CType.LoseCompleteStamp)(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.LoseGossip: { mixin(S_TRACE);
		dlg = new GossipEventDialog!(CType.LoseGossip)(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.ShowParty: { mixin(S_TRACE);
		dlg = new ShowHidePartyDialog(evt.type, comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.HideParty: { mixin(S_TRACE);
		dlg = new ShowHidePartyDialog(evt.type, comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.Redisplay: { mixin(S_TRACE);
		dlg = new RefreshDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.SubstituteStep: { mixin(S_TRACE);
		dlg = new SubstituteStepDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.SubstituteFlag: { mixin(S_TRACE);
		dlg = new SubstituteFlagDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BranchStepCmp: { mixin(S_TRACE);
		dlg = new BrStepCmpDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BranchFlagCmp: { mixin(S_TRACE);
		dlg = new BrFlagCmpDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BranchRandomSelect: { mixin(S_TRACE);
		dlg = new BrRandomSelectDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchKeyCode: { mixin(S_TRACE);
		dlg = new BrKeyCodeDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.CheckStep: { mixin(S_TRACE);
		dlg = new CheckStepDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, summ ? summ.flagDirRoot : null);
		break;
	} case CType.BranchRound: { mixin(S_TRACE);
		dlg = new BranchRoundDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.MoveBgImage: { mixin(S_TRACE);
		dlg = new MoveBgImageDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.ReplaceBgImage: { mixin(S_TRACE);
		dlg = new BgImagesDialog(comm, comm.prop, parentShell, summ, uc, parent, evt, null, CType.ReplaceBgImage);
		break;
	} case CType.LoseBgImage: { mixin(S_TRACE);
		dlg = new LoseBgImageDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchMultiCoupon: { mixin(S_TRACE);
		dlg = new BranchMultiCouponDialog(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.MoveCard: { mixin(S_TRACE);
		dlg = new MoveCardDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.ChangeEnvironment: { mixin(S_TRACE);
		dlg = new ChangeEnvironmentDialog(comm, comm.prop, parentShell, summ, parent, evt);
		break;
	} case CType.BranchVariant: { mixin(S_TRACE);
		dlg = new ExpressionEventDialog(comm, comm.prop, parentShell, summ, uc, parent, CType.BranchVariant, evt);
		break;
	} case CType.SetVariant: { mixin(S_TRACE);
		dlg = new SetVariantDialog(comm, comm.prop, parentShell, summ, uc, parent, evt);
		break;
	} case CType.CheckVariant: { mixin(S_TRACE);
		dlg = new ExpressionEventDialog(comm, comm.prop, parentShell, summ, uc, parent, CType.CheckVariant, evt);
		break;
	} default: assert (0);
	}
	return dlg;
}

Content initial(in Commons comm, in Skin skin, bool legacy, string dataVersion, in BgImageS[] bgImagesDefault, Content c) { mixin(S_TRACE);
	if (c.type is CType.ChangeBgImage) { mixin(S_TRACE);
		c.backs = createBgImages(skin, bgImagesDefault);
	} else if (c.type is CType.TalkDialog) { mixin(S_TRACE);
		c.dialogs = [new SDialog];
		if (comm.prop.parent.isTargetVersion(legacy, dataVersion, "2")) c.boundaryCheck = true;
	} else if (c.type is CType.BranchSkill || c.type is CType.BranchItem || c.type is CType.BranchBeast) { mixin(S_TRACE);
		c.range = Range.Field;
	} else if (c.type is CType.LoseSkill || c.type is CType.LoseItem || c.type is CType.LoseBeast) { mixin(S_TRACE);
		c.range = Range.Field;
	} else if (c.type is CType.TalkMessage) { mixin(S_TRACE);
		if (comm.prop.parent.isTargetVersion(legacy, dataVersion, "2")) c.boundaryCheck = true;
	} else if (c.type is CType.BranchKeyCode) { mixin(S_TRACE);
		if (legacy) { mixin(S_TRACE);
			c.targetIsSkill = true;
			c.targetIsItem = true;
			c.targetIsBeast = true;
			c.targetIsHand = true;
		}
	}
	return c;
}


module cwx.editor.gui.dwt.etcsettings;

import cwx.utils;
import cwx.settings;
import cwx.structs;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;

import org.eclipse.swt.all;

import java.lang.all;

/// 設定ダイアログ内の詳細欄。On/Offできる設定を分類して並べる。
class EtcSettings : Composite {
	void delegate()[] modEvent;

	private void delegate()[] _apply;

	private ScrolledComposite _sc;
	private bool _scResizing = false;

	private Button boolSetting(Composite parent, ref Prop!(bool, false) pVal, string text) { mixin(S_TRACE);
		return boolSetting!bool(parent, pVal, text, value => value, value => value);
	}
	private Button boolSetting(T)(Composite parent, ref Prop!(T, false) pVal, string text, bool function(T) toBool, T function(bool) fromBool) { mixin(S_TRACE);
		auto check = new Button(parent, SWT.CHECK);
		check.setText(text);
		check.setSelection(toBool(pVal));
		.listener(check, SWT.Selection, { mixin(S_TRACE);
			foreach (mod; modEvent) mod();
		});
		// FIXME: _sc.setShowFocusedControl()を使うとExpandItemの
		//        拡大と縮小でスクロール位置に問題が出る
		.listener(check, SWT.FocusIn, { mixin(S_TRACE);
			if (_scResizing) return;
			_sc.showControl(check);
		});

		auto set = &pVal.opAssign;
		_apply ~= { mixin(S_TRACE);
			set(fromBool(check.getSelection()));
		};
		return check;
	}

	this (Commons comm, Composite parent, int style) { mixin(S_TRACE);
		super (parent, style);
		setLayout(new FillLayout);

		auto prop = comm.prop;

		_sc = new ScrolledComposite(this, SWT.V_SCROLL | SWT.BORDER);
		_sc.setExpandHorizontal(true);
		_sc.setExpandVertical(true);
		// FIXME: ExpandItemの拡大と縮小でスクロール位置に問題が出る
		//_sc.setShowFocusedControl(true);

		auto expandBar = new ExpandBar(_sc, SWT.NONE);
		.listener(expandBar, SWT.MouseDown, { mixin(S_TRACE);
			expandBar.setFocus();
		});
		_sc.setContent(expandBar);
		auto runScSize = new class Runnable {
			override void run() { mixin(S_TRACE);
				auto size = expandBar.computeSize(SWT.DEFAULT, SWT.DEFAULT);
				_sc.setMinSize(size.x, size.y);
				_scResizing = false;
			}
		};
		void scSize() { mixin(S_TRACE);
			_scResizing = true;
			getDisplay().asyncExec(runScSize);
		}
		.listener(_sc, SWT.Resize, { mixin(S_TRACE);
			auto size = _sc.getSize();
			_sc.getVerticalBar().setPageIncrement(size.y / 2);
		});
		.listener(expandBar, SWT.Expand, &scSize);
		.listener(expandBar, SWT.Collapse, &scSize);

		Composite createComp(string text) { mixin(S_TRACE);
			auto itm = new ExpandItem(expandBar, SWT.NONE);
			itm.setText(text);
			auto comp = new Composite(expandBar, SWT.NONE);
			comp.setLayout(new GridLayout(1, true));
			itm.setControl(comp);
			itm.setExpanded(true);
			.listener(comp, SWT.MouseDown, { mixin(S_TRACE);
				expandBar.setFocus();
			});
			return comp;
		}

		auto comp = createComp(prop.msgs.etcSettingsCommon);
		if (!comm.singleWindowMode(prop)) { mixin(S_TRACE);
			boolSetting(comp, prop.var.etc.singleWindow, prop.msgs.singleWindow);
		}
		boolSetting(comp, prop.var.etc.showImagePreview, prop.msgs.showImagePreview);
		boolSetting(comp, prop.var.etc.switchTabWheel, prop.msgs.switchTabWheel);
		boolSetting(comp, prop.var.etc.closeTabWithMiddleClick, prop.msgs.closeTabWithMiddleClick);
		boolSetting(comp, prop.var.etc.openTabAtRightOfCurrentTab, prop.msgs.openTabAtRightOfCurrentTab);
		boolSetting(comp, prop.var.etc.comboListVisible, prop.msgs.comboListVisible);
		boolSetting!int(comp, prop.var.etc.editTriggerType, prop.msgs.editTriggerTypeIsQuick, (int value) { mixin(S_TRACE);
			return value is EditTrigger.Quick;
		}, (bool value) { mixin(S_TRACE);
			return cast(int)(value ? EditTrigger.Quick : EditTrigger.Slow);
		});
		boolSetting(comp, prop.var.etc.xmlCopy, prop.msgs.xmlCopy);
		boolSetting(comp, prop.var.etc.logicalSort, prop.msgs.logicalSort);
		boolSetting(comp, prop.var.etc.canVanishWorkAreaInMainWindow, prop.msgs.canVanishWorkAreaInMainWindow);

		comp = createComp(prop.msgs.etcSettingsLoad);
		boolSetting(comp, prop.var.etc.saveNeedChanged, prop.msgs.saveNeedChanged);
		boolSetting(comp, prop.var.etc.applyDialogsBeforeSave, prop.msgs.applyDialogsBeforeSave);
		boolSetting(comp, prop.var.etc.doubleIO, prop.msgs.doubleIO);
		boolSetting(comp, prop.var.etc.archiveInNewThread, prop.msgs.archiveInNewThread);
		boolSetting(comp, prop.var.etc.saveChangedOnly, prop.msgs.saveChangedOnly);
		boolSetting(comp, prop.var.etc.expandXMLs, prop.msgs.expandXMLs);
		boolSetting(comp, prop.var.etc.saveInnerImagePath, prop.msgs.saveInnerImagePath);
		boolSetting(comp, prop.var.etc.addNewClassicEngine, prop.msgs.addNewClassicEngine);
		boolSetting(comp, prop.var.etc.openLastScenario, prop.msgs.openLastScenario);
		boolSetting(comp, prop.var.etc.reconstruction, prop.msgs.reconstruction);

		comp = createComp(prop.msgs.etcSettingsFile);
		boolSetting(comp, prop.var.etc.traceDirectories, prop.msgs.traceDirectories);
		boolSetting(comp, prop.var.etc.autoUpdateJpy1File, prop.msgs.autoUpdateJpy1File);

		comp = createComp(prop.msgs.etcSettingsFind);
		boolSetting(comp, prop.var.etc.cautionBeforeReplace, prop.msgs.cautionBeforeReplace);

		comp = createComp(prop.msgs.etcSettingsTable);
		boolSetting(comp, prop.var.etc.showAreaDirTree, prop.msgs.showAreaDirTree);
		boolSetting(comp, prop.var.etc.showSummaryInAreaTable, prop.msgs.showSummaryInAreaTable);
		boolSetting(comp, prop.var.etc.clickIsOpenEvent, prop.msgs.clickIsOpenEvent);

		comp = createComp(prop.msgs.etcSettingsScene);
		boolSetting(comp, prop.var.etc.smoothingCard, prop.msgs.smoothingCard);
		boolSetting(comp, prop.var.etc.ignoreBackgroundInRange, prop.msgs.ignoreBackgroundInRange);
		boolSetting(comp, prop.var.etc.copyDesc, prop.msgs.copyDesc);

		comp = createComp(prop.msgs.etcSettingsEvent);
		auto contentsFloat = boolSetting(comp, prop.var.etc.contentsFloat, prop.msgs.contentsFloat);
		auto contentsAutoHide = boolSetting(comp, prop.var.etc.contentsAutoHide, prop.msgs.contentsAutoHide);
		.listener(contentsFloat, SWT.Selection, { mixin(S_TRACE);
			if (contentsFloat.getSelection()) { mixin(S_TRACE);
				contentsAutoHide.setSelection(false);
			}
		});
		.listener(contentsAutoHide, SWT.Selection, { mixin(S_TRACE);
			if (contentsAutoHide.getSelection()) { mixin(S_TRACE);
				contentsFloat.setSelection(false);
			}
		});
		boolSetting(comp, prop.var.etc.straightEventTreeView, prop.msgs.straightEventTreeView);
		boolSetting(comp, prop.var.etc.gentleAngleEventTree, prop.msgs.gentleAngleEventTree);
		boolSetting(comp, prop.var.etc.forceIndentBranchContent, prop.msgs.forceIndentBranchContent);
		boolSetting(comp, prop.var.etc.showTerminalMark, prop.msgs.showTerminalMark);
		boolSetting(comp, prop.var.etc.classicStyleTree, prop.msgs.classicStyleTree);
		boolSetting(comp, prop.var.etc.clickIconIsStartEdit, prop.msgs.clickIconIsStartEdit);
		boolSetting(comp, prop.var.etc.adjustContentName, prop.msgs.adjustContentName);
		boolSetting(comp, prop.var.etc.showVariableValuesInEventText, prop.msgs.showVariableValuesInEventText);
		boolSetting(comp, prop.var.etc.refCardsAtEditBgImage, prop.msgs.refCardsAtEditBgImage);
		boolSetting(comp, prop.var.etc.floatMessagePreview, prop.msgs.floatMessagePreview);
		boolSetting(comp, prop.var.etc.selectVariableWithTree, prop.msgs.selectVariableWithTree);
		boolSetting(comp, prop.var.etc.useNamesAfterStandard, prop.msgs.useNamesAfterStandard);

		comp = createComp(prop.msgs.etcSettingsCard);
		boolSetting(comp, prop.var.etc.showEventTreeMark, prop.msgs.showEventTreeMark);
		boolSetting(comp, prop.var.etc.ignoreEmptyStart, prop.msgs.ignoreEmptyStart);
		boolSetting(comp, prop.var.etc.showCardListHeader, prop.msgs.showCardListHeader);
		boolSetting(comp, prop.var.etc.showCardListTitle, prop.msgs.showCardListTitle);
		boolSetting(comp, prop.var.etc.showSkillCardLevel, prop.msgs.showSkillCardLevel);
		boolSetting(comp, prop.var.etc.showSpNature, prop.msgs.showSpNature);
		boolSetting(comp, prop.var.etc.radarStyleParams, prop.msgs.radarStyleParams);
		boolSetting(comp, prop.var.etc.linkCard, prop.msgs.linkCard);

		foreach (itm; expandBar.getItems()) { mixin(S_TRACE);
			auto ctrl = itm.getControl();
			itm.setHeight(ctrl.computeSize(SWT.DEFAULT, SWT.DEFAULT).y);
		}

		auto gd = new GridLayout(1, true);
		_sc.getVerticalBar().setIncrement(contentsFloat.computeSize(SWT.DEFAULT, SWT.DEFAULT).y + gd.verticalSpacing);
		scSize();
	}

	void apply() { mixin(S_TRACE);
		foreach (apply; _apply) { mixin(S_TRACE);
			apply();
		}
	}
}

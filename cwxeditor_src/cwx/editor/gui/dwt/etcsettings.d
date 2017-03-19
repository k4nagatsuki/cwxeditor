
module cwx.editor.gui.dwt.etcsettings;

import cwx.utils;
import cwx.settings;
import cwx.structs;
import cwx.types;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;

import org.eclipse.swt.all;

import java.lang.all;

/// 設定ダイアログ内の詳細欄。On/Offできる設定を分類して並べる。
class EtcSettings : Composite {
	void delegate()[] modEvent;

	private ExpandBar _expandBar;

	private IncSearch _incSearch = null;
	private void incSearch() { mixin(S_TRACE);
		auto fc = getDisplay().getFocusControl();
		if (!fc || !isDescendant(this, fc)) { mixin(S_TRACE);
			.forceFocus(this, true);
		}
		_incSearch.startIncSearch();
	}

	private void delegate()[] _apply;

	private ScrolledComposite _sc;

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

		_expandBar = new ExpandBar(_sc, SWT.NONE);
		.listener(_expandBar, SWT.MouseDown, { mixin(S_TRACE);
			// FIXME: スクロールバーが一番上にある時に限り
			//        フォーカスが得られないのでここで設定
			if (_sc.getVerticalBar().getSelection() == 0) { mixin(S_TRACE);
				_expandBar.setFocus();
			}
		});
		_sc.setContent(_expandBar);
		.listener(_sc, SWT.Resize, { mixin(S_TRACE);
			auto size = _sc.getSize();
			_sc.getVerticalBar().setPageIncrement(size.y / 2);
		});
		.listener(_expandBar, SWT.Expand, &scSize);
		.listener(_expandBar, SWT.Collapse, &scSize);

		Composite createComp(string text) { mixin(S_TRACE);
			auto itm = new ExpandItem(_expandBar, SWT.NONE);
			itm.setText(text);
			auto comp = new Composite(_expandBar, SWT.NONE);
			auto fl = new FormLayout;
			fl.marginLeft = 5.ppis;
			fl.marginRight = 5.ppis;
			fl.marginBottom = 5.ppis;
			comp.setLayout(fl);
			itm.setControl(comp);
			itm.setExpanded(true);
			.listener(comp, SWT.MouseDown, { mixin(S_TRACE);
				_expandBar.setFocus();
			});
			return comp;
		}

		auto comp = createComp(prop.msgs.etcSettingsCommon);
		boolSetting(comp, prop.var.etc.showImagePreview, prop.msgs.showImagePreview);
		boolSetting(comp, prop.var.etc.maskCardImagePreview, prop.msgs.maskCardImagePreview);
		boolSetting(comp, prop.var.etc.switchTabWheel, prop.msgs.switchTabWheel);
		boolSetting(comp, prop.var.etc.closeTabWithMiddleClick, prop.msgs.closeTabWithMiddleClick);
		boolSetting(comp, prop.var.etc.openTabAtRightOfCurrentTab, prop.msgs.openTabAtRightOfCurrentTab);
		boolSetting(comp, prop.var.etc.showCloseButtonAllTab, prop.msgs.showCloseButtonAllTab);
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
		boolSetting(comp, prop.var.etc.xmlFileNameIsIDOnly, prop.msgs.xmlFileNameIsIDOnly);
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
		boolSetting(comp, prop.var.etc.startIncrementalSearchWhenKeyDown, prop.msgs.startIncrementalSearchWhenKeyDown);

		comp = createComp(prop.msgs.etcSettingsTable);
		boolSetting(comp, prop.var.etc.showAreaDirTree, prop.msgs.showAreaDirTree);
		boolSetting(comp, prop.var.etc.showSummaryInAreaTable, prop.msgs.showSummaryInAreaTable);
		boolSetting(comp, prop.var.etc.clickIsOpenEvent, prop.msgs.clickIsOpenEvent);

		comp = createComp(prop.msgs.etcSettingsScene);
		boolSetting(comp, prop.var.etc.smoothingCard, prop.msgs.smoothingCard);
		boolSetting(comp, prop.var.etc.ignoreBackgroundInRange, prop.msgs.ignoreBackgroundInRange);
		boolSetting(comp, prop.var.etc.copyDesc, prop.msgs.copyDesc);

		comp = createComp(prop.msgs.etcSettingsEvent);
		boolSetting(comp, prop.var.etc.showContentsGroupName, prop.msgs.showContentsGroupName);
		boolSetting(comp, prop.var.etc.showEventContentDescription, prop.msgs.showEventContentDescription);
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
		boolSetting(comp, prop.var.etc.forceIndentBranchContent, prop.msgs.forceIndentBranchContent);
		boolSetting(comp, prop.var.etc.showTerminalMark, prop.msgs.showTerminalMark);
		boolSetting(comp, prop.var.etc.classicStyleTree, prop.msgs.classicStyleTree);
		boolSetting(comp, prop.var.etc.clickIconIsStartEdit, prop.msgs.clickIconIsStartEdit);
		boolSetting(comp, prop.var.etc.adjustContentName, prop.msgs.adjustContentName);
		boolSetting(comp, prop.var.etc.showVariableValuesInEventText, prop.msgs.showVariableValuesInEventText);
		boolSetting(comp, prop.var.etc.editSelectionWithCombo, prop.msgs.editSelectionWithCombo);
		boolSetting(comp, prop.var.etc.refCardsAtEditBgImage, prop.msgs.refCardsAtEditBgImage);
		boolSetting(comp, prop.var.etc.floatMessagePreview, prop.msgs.floatMessagePreview);
		boolSetting(comp, prop.var.etc.selectVariableWithTree, prop.msgs.selectVariableWithTree);
		boolSetting(comp, prop.var.etc.useNamesAfterStandard, prop.msgs.useNamesAfterStandard);
		boolSetting(comp, prop.var.etc.expandChooserItems, prop.msgs.expandChooserItems);

		comp = createComp(prop.msgs.etcSettingsCard);
		boolSetting(comp, prop.var.etc.showEventTreeMark, prop.msgs.showEventTreeMark);
		boolSetting(comp, prop.var.etc.ignoreEmptyStart, prop.msgs.ignoreEmptyStart);
		boolSetting(comp, prop.var.etc.showCardListHeader, prop.msgs.showCardListHeader);
		boolSetting(comp, prop.var.etc.showCardListTitle, prop.msgs.showCardListTitle);
		boolSetting(comp, prop.var.etc.showSkillCardLevel, prop.msgs.showSkillCardLevel);
		boolSetting(comp, prop.var.etc.showSpNature, prop.msgs.showSpNature);
		boolSetting(comp, prop.var.etc.showMotionDescription, prop.msgs.showMotionDescription);
		boolSetting(comp, prop.var.etc.radarStyleParams, prop.msgs.radarStyleParams);
		boolSetting(comp, prop.var.etc.linkCard, prop.msgs.linkCard);

		_incSearch = new IncSearch(comm, this);
		_incSearch.modEvent ~= &showCheckBoxes;
		auto menu = new Menu(getShell(), SWT.POP_UP);
		createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, null);
		void recurse(Control ctrl) { mixin(S_TRACE);
			ctrl.setMenu(menu);
			if (auto comp = cast(Composite)ctrl) { mixin(S_TRACE);
				foreach (child; comp.getChildren()) recurse(child);
			}
		}
		recurse(this);

		showCheckBoxes();

		auto gd = normalGridLayout(1, true);
		_sc.getVerticalBar().setIncrement(contentsFloat.computeSize(SWT.DEFAULT, SWT.DEFAULT).y + gd.verticalSpacing);
		scSize();
	}

	private void showCheckBoxes() { mixin(S_TRACE);
		foreach (itm; _expandBar.getItems()) { mixin(S_TRACE);
			auto comp = cast(Composite)itm.getControl();
			assert (comp !is null);
			Control[] children;
			foreach (child; comp.getChildren()) { mixin(S_TRACE);
				auto check = cast(Button)child;
				assert (check !is null);
				if (_incSearch.match(check.getText())) { mixin(S_TRACE);
					child.setVisible(true);
					children ~= child;
				} else { mixin(S_TRACE);
					child.setVisible(false);
					auto fd = new FormData;
					fd.top = new FormAttachment(0, 0.ppis);
					fd.width = 0;
					fd.height = 0;
					child.setLayoutData(fd);
				}
			}
			foreach (i, check; children) { mixin(S_TRACE);
				auto fd = new FormData;
				if (0 < i) { mixin(S_TRACE);
					fd.top = new FormAttachment(children[i - 1], 5.ppis);
				} else {
					fd.top = new FormAttachment(0, 5.ppis);
				}
				check.setLayoutData(fd);
			}
			itm.setHeight(comp.computeSize(SWT.DEFAULT, SWT.DEFAULT).y);
		}
		scSize();
	}
	private void scSize() { mixin(S_TRACE);
		auto runScSize = new class Runnable {
			override void run() { mixin(S_TRACE);
				if (_expandBar.isDisposed()) return;
				auto size = _expandBar.computeSize(SWT.DEFAULT, SWT.DEFAULT);
				_sc.setMinSize(size.x, size.y);
			}
		};
		getDisplay().asyncExec(runScSize);
	}

	void apply() { mixin(S_TRACE);
		foreach (apply; _apply) { mixin(S_TRACE);
			apply();
		}
	}
}

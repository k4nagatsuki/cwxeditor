
module cwx.editor.gui.dwt.exprutils;

import cwx.card;
import cwx.event;
import cwx.expression;
import cwx.flag;
import cwx.menu;
import cwx.msgutils;
import cwx.path;
import cwx.summary;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.warning;

import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.eventdialog;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

static import core.thread;

import std.algorithm : each, map, max;
import std.array;
import std.conv;
import std.datetime;
import std.range;
import std.string;
import std.traits;
import std.typecons;

import org.eclipse.swt.all;

import java.lang.all;

/// コモン分岐・判定イベントの設定を行うダイアログ(Wsn.4)。
class ExpressionEventDialog : EventDialog {
private:
	ExpressionEditor _expr;
	UseCounter _uc;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!prop.isTargetVersion(summ, "4")) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(type), "4");
		}
		auto val = _expr.returnValue;
		if (val.valid && val.type !is VariantType.Boolean) { mixin(S_TRACE);
			final switch (val.type) {
			case VariantType.Number:
				ws ~= .tryFormat(prop.msgs.warningExpressionNeedBooleanReturnType, prop.msgs.numberValue, prop.msgs.contentName(type));
				break;
			case VariantType.String:
				ws ~= .tryFormat(prop.msgs.warningExpressionNeedBooleanReturnType, prop.msgs.stringValue, prop.msgs.contentName(type));
				break;
			case VariantType.Boolean:
				assert (0);
			}
		}
		ws ~= _expr.warnings;
		warning = ws;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, CType cType, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, cType, parent, evt, true, prop.var.expressionDlg, true);
		_uc = uc;
	}

	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = .cpcategory(path);
		if (cate == "") return true;
		if (cate == "expr") { mixin(S_TRACE);
			_expr.editor.setFocus();
			return true;
		}
		return false;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(comm.prop.msgs.expression);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			cl.fillVertical = true;
			grp.setLayout(cl);

			_expr = new ExpressionEditor(comm, summ, _uc, grp, SWT.NONE);
			mod(_expr);
			_expr.modEvent ~= &refreshWarning;
			_expr.modReturnValueEvent ~= &refreshWarning;
		}

		ignoreMod = true;
		scope (exit) .asyncExec(getShell().getDisplay(), { ignoreMod = false; });
		if (evt) { mixin(S_TRACE);
			_expr.expression = evt.expression;
		} else { mixin(S_TRACE);
			_expr.expression = "";
		}

		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!evt) evt = new Content(type, "");
		evt.expression = _expr.expression;
		comm.refCoupons.call();
		comm.refGossips.call();
		return true;
	}
}

/// コモン設定イベントの設定を行うダイアログ(Wsn.4)。
class SetVariantDialog : EventDialog {
private:
	ExpressionEditor _expr;
	UseCounter _uc;

	Button[VariableType] _varTypes;
	Composite _varComp;
	FlagChooser!(cwx.flag.Flag, false) _flag = null;
	string _selFlag = "";
	FlagChooser!(Step, false) _step = null;
	string _selStep = "";
	FlagChooser!(cwx.flag.Variant, false) _variant = null;
	string _selVariant = "";

	void refFlagsAndSteps(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		if (summ && !summ.flagDirRoot.hasFlag && !summ.flagDirRoot.hasStep && !summ.flagDirRoot.hasVariant) { mixin(S_TRACE);
			forceCancel();
		} else { mixin(S_TRACE);
			updateEnabled();
		}
	}

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!prop.isTargetVersion(summ, "4")) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.SetVariant), "4");
		}
		ws ~= _expr.warnings;
		if (_flag) { mixin(S_TRACE);
			auto val = _expr.returnValue;
			if (val.valid && val.type !is VariantType.Boolean) { mixin(S_TRACE);
				final switch (val.type) {
				case VariantType.Number:
					ws ~= .tryFormat(prop.msgs.warningExpressionToFlag, prop.msgs.numberValue);
					break;
				case VariantType.String:
					ws ~= .tryFormat(prop.msgs.warningExpressionToFlag, prop.msgs.stringValue);
					break;
				case VariantType.Boolean:
					assert (0);
				}
			}
		} else if (_step) { mixin(S_TRACE);
			auto val = _expr.returnValue;
			if (val.valid && val.type !is VariantType.Number) { mixin(S_TRACE);
				final switch (val.type) {
				case VariantType.Number:
					assert (0);
				case VariantType.String:
					ws ~= .tryFormat(prop.msgs.warningExpressionToStep, prop.msgs.stringValue);
					break;
				case VariantType.Boolean:
					ws ~= .tryFormat(prop.msgs.warningExpressionToStep, prop.msgs.booleanValue);
					break;
				}
			}
		}
		warning = ws;
	}

	private void updateEnabled() { mixin(S_TRACE);
		auto noSelect = false;
		foreach (varType, b; _varTypes) { mixin(S_TRACE);
			final switch (varType) {
			case VariableType.Flag:
				b.setEnabled(summ && summ.flagDirRoot.hasFlag);
				break;
			case VariableType.Step:
				b.setEnabled(summ && summ.flagDirRoot.hasStep);
				break;
			case VariableType.Variant:
				b.setEnabled(summ && summ.flagDirRoot.hasVariant);
				break;
			}
			if (!b.getEnabled() && b.getSelection()) { mixin(S_TRACE);
				b.setSelection(false);
				noSelect = true;
			}
		}
		if (noSelect) { mixin(S_TRACE);
			if (summ && summ.flagDirRoot.hasVariant) { mixin(S_TRACE);
				_varTypes[VariableType.Variant].setSelection(true);
			} else if (summ && summ.flagDirRoot.hasStep) { mixin(S_TRACE);
				_varTypes[VariableType.Step].setSelection(true);
			} else if (summ && summ.flagDirRoot.hasFlag) { mixin(S_TRACE);
				_varTypes[VariableType.Flag].setSelection(true);
			} else { mixin(S_TRACE);
				_varTypes[VariableType.Variant].setSelection(true);
			}
		}
		selectedVariableType();
	}

	void selectedVariableType() { mixin(S_TRACE);
		_varComp.setRedraw(false);
		scope (exit) _varComp.setRedraw(true);
		auto varType = .getRadioValue(_varTypes);
		if (_flag && varType is VariableType.Flag) return;
		if (_step && varType is VariableType.Step) return;
		if (_variant && varType is VariableType.Variant) return;
		if (_flag) { mixin(S_TRACE);
			_selFlag = _flag.selected;
			_flag.dispose();
			_flag = null;
		} else if (_step) { mixin(S_TRACE);
			_selStep = _step.selected;
			_step.dispose();
			_step = null;
		} else if (_variant) { mixin(S_TRACE);
			_selVariant = _variant.selected;
			_variant.dispose();
			_variant = null;
		}
		assert (!_flag && !_step && !_variant);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.horizontalSpan = 3;
		final switch (varType) {
		case VariableType.Flag:
			_flag = new FlagChooser!(cwx.flag.Flag, false)(comm, summ, _uc, _varComp);
			_flag.setLayoutData(gd);
			mod(_flag);
			_flag.selected = _selFlag;
			break;
		case VariableType.Step:
			_step = new FlagChooser!(Step, false)(comm, summ, _uc, _varComp);
			_step.setLayoutData(gd);
			mod(_step);
			_step.selected = _selStep;
			break;
		case VariableType.Variant:
			_variant = new FlagChooser!(cwx.flag.Variant, false)(comm, summ, _uc, _varComp);
			_variant.setLayoutData(gd);
			mod(_variant);
			_variant.selected = _selVariant;
			break;
		}
		_varComp.layout();
		refreshWarning();
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.SetVariant, parent, evt, true, prop.var.expressionWithTargetDlg, true);
		_uc = uc;
	}

	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = .cpcategory(path);
		if (cate == "") return true;
		if (cate == "expr") { mixin(S_TRACE);
			_expr.editor.setFocus();
			return true;
		}
		return false;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));
		auto sash = new SplitPane(area, SWT.VERTICAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto grpT = new Group(sash, SWT.NONE);
		grpT.setText(comm.prop.msgs.expression);
		{ mixin(S_TRACE);
			auto gl = normalGridLayout(1, true);
			grpT.setLayout(gl);

			_expr = new ExpressionEditor(comm, summ, _uc, grpT, SWT.NONE);
			mod(_expr);
			_expr.modEvent ~= &refreshWarning;
			_expr.modReturnValueEvent ~= &refreshWarning;
			_expr.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		auto grpB = new Group(sash, SWT.NONE);
		_varComp = grpB;
		grpB.setText(comm.prop.msgs.expressionTarget);
		grpB.setLayout(normalGridLayout(3, false));
		foreach (varType; [VariableType.Variant, VariableType.Step, VariableType.Flag]) { mixin(S_TRACE);
			auto b = new Button(grpB, SWT.RADIO);
			mod(b);
			b.setText(comm.prop.msgs.variableTypeName(varType));
			_varTypes[varType] = b;
			.listener(b, SWT.Selection, &selectedVariableType);
		}

		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refFlagAndStep.add(&refFlagsAndSteps);
			comm.delFlagAndStep.add(&refFlagsAndSteps);
			.listener(area, SWT.Dispose, { mixin(S_TRACE);
				comm.refFlagAndStep.remove(&refFlagsAndSteps);
				comm.delFlagAndStep.remove(&refFlagsAndSteps);
			});
		}

		ignoreMod = true;
		scope (exit) .asyncExec(getShell().getDisplay(), { ignoreMod = false; });
		if (evt) { mixin(S_TRACE);
			_expr.expression = evt.expression;
			if (evt.flag != "") { mixin(S_TRACE);
				_varTypes[VariableType.Flag].setSelection(true);
				selectedVariableType();
				_flag.selected = evt.flag;
			} else if (evt.step != "") { mixin(S_TRACE);
				_varTypes[VariableType.Step].setSelection(true);
				selectedVariableType();
				_step.selected = evt.step;
			} else { mixin(S_TRACE);
				_varTypes[VariableType.Variant].setSelection(true);
				selectedVariableType();
				_variant.selected = evt.variant;
			}
		} else { mixin(S_TRACE);
			_expr.expression = "";
			_varTypes[VariableType.Variant].setSelection(true);
			selectedVariableType();
			_variant.selected = "";
		}

		refDataVersion();

		if (comm.prop.var.etc.expressionAndTargetSashT == -1) { mixin(S_TRACE);
			comm.prop.var.etc.expressionAndTargetSashT = grpT.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
		}
		if (comm.prop.var.etc.expressionAndTargetSashB == -1) { mixin(S_TRACE);
			comm.prop.var.etc.expressionAndTargetSashB = grpB.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
		}
		.setupWeights(sash, comm.prop.var.etc.expressionAndTargetSashT, comm.prop.var.etc.expressionAndTargetSashB);
	}

	override bool apply() { mixin(S_TRACE);
		if (!evt) evt = new Content(CType.SetVariant, "");
		evt.expression = _expr.expression;
		if (_flag) { mixin(S_TRACE);
			evt.flag = _flag.selected;
			evt.step = "";
			evt.variant = "";
		} else if (_step) { mixin(S_TRACE);
			evt.step = _step.selected;
			evt.flag = "";
			evt.variant = "";
		} else if (_variant) { mixin(S_TRACE);
			evt.variant = _variant.selected;
			evt.flag = "";
			evt.step = "";
		} else assert (0);
		comm.refCoupons.call();
		comm.refGossips.call();
		return true;
	}
}

/// 式を編集するウィジェット。
class ExpressionEditor : Composite {
	void delegate()[] modEvent;
	void delegate()[] modReturnValueEvent;

	// レスポンスが悪くなるのを避けるため、最後の入力から一定時間経過後に文法チェックを行う
	private MonoTime _lastModified = MonoTime.init;
	private Display _display;
	private bool _quit = false;
	private void checkThread() { mixin(S_TRACE);
		auto check = new class Runnable {
			override void run() { mixin(S_TRACE);
				if (isDisposed()) return;
				checkExpression(true);
			}
		};
		while (!_quit) { mixin(S_TRACE);
			if (_lastModified != MonoTime.init && _lastModified + .dur!"msecs"(_comm.prop.var.etc.expressionCheckingDelay) <= MonoTime.currTime()) { mixin(S_TRACE);
				_display.asyncExec(check);
			}
			core.thread.Thread.sleep(dur!"msecs"(1));
		}
	}

	private void modified() { mixin(S_TRACE);
		_lastModified = MonoTime.currTime();
		modEvent.each!(func => func())();
	}
	private string _raisedExpr = "";
	private void checkExpression(bool raiseModEvent) { mixin(S_TRACE);
		_lastModified = MonoTime.init;
		if (_raisedExpr == _expr.getText()) return;
		checkExpressionImpl(raiseModEvent);
	}
	private void checkExpressionImpl(bool raiseModEvent) { mixin(S_TRACE);
		auto oldWS = _ws;
		_ws = [];
		_raisedExpr = _expr.getText();
		auto text = .wrapReturnCode(_expr.getText());
		auto expr = new Expression;
		expr.text = text;
		string[char] names;
		VarValue[string] flags, steps, variants, sysSteps;
		auto err = expr.getExpressionErrors(_comm.prop.parent, VariableInfo(_comm.prop.parent, _summ, _uc, _comm.prop.var.etc.targetVersion, names, flags, steps, variants, sysSteps));
		_ws ~= .exprErrorToWarnings(_comm.prop.parent, text, err);

		bool[string] wFlags;
		bool[string] wSteps;
		bool[string] wVariants;
		bool[string] wFonts;
		bool[char] wColors;
		_ws ~= .textWarnings(_comm.prop.parent, _comm.skin, _summ, _uc, _comm.prop.var.etc.targetVersion, text, expr.flagsInText, expr.stepsInText, expr.variantsInText, [], [], wFlags, wSteps, wVariants, wFonts, wColors).all;

		auto valid = _returnValue.valid;
		auto type = _returnValue.type;
		_returnValue = expr.returnValue(_comm.prop.parent);
		if (raiseModEvent && oldWS != _ws) { mixin(S_TRACE);
			modEvent.each!(func => func())();
		}
		if (raiseModEvent && (_returnValue.valid !is valid || _returnValue.type !is type)) { mixin(S_TRACE);
			modReturnValueEvent.each!(func => func())();
		}
	}
	private void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		checkExpressionImpl(true);
	}

	private Commons _comm;
	private Summary _summ;
	private UseCounter _uc;

	private Text _expr;
	private VariantVal _returnValue = VariantVal(false);
	private string[] _ws;

	private FunctionCallEditor _funcEdit = null;
	private Button _func;
	private Menu _flagMenu;
	private Menu _stepMenu;
	private Menu _variantMenu;

	this (Commons comm, Summary summ, UseCounter uc, Composite parent, int style) { mixin(S_TRACE);
		super (parent, style);
		_comm = comm;
		_summ = summ;
		_uc = uc;

		auto gd = zeroMarginGridLayout(1, true);
		setLayout(gd);

		_expr = new Text(this, SWT.MULTI | SWT.BORDER | SWT.V_SCROLL);
		.createTextMenu!Text(_comm, _comm.prop, _expr, null);
		.listener(_expr, SWT.Modify, &modified);
		_expr.setTabs(_comm.prop.var.etc.tabs);
		auto font = _expr.getFont();
		auto fSize = font ? cast(uint)font.getFontData()[0].height : 0;
		_expr.setFont(new Font(getDisplay(), dwtData(_comm.prop.adjustFont(_comm.prop.looks.textDlgFont(fSize)))));
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_expr.getFont().dispose();
		});
		auto gc = new GC(_expr);
		scope (exit) gc.dispose();
		auto exprGD = new GridData(GridData.FILL_BOTH);
		exprGD.heightHint = gc.getFontMetrics().getHeight() * 4;
		_expr.setLayoutData(exprGD);

		auto varComp = new Composite(this, SWT.NONE);
		varComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		varComp.setLayout(zeroMarginGridLayout(3, false));

		_flagMenu = new Menu(getShell(), SWT.NONE);
		_stepMenu = new Menu(getShell(), SWT.NONE);
		_variantMenu = new Menu(getShell(), SWT.NONE);

		auto funcDefs = .functionDefinitions(_comm.prop.parent);
		auto var = .createFlagStepBar(varComp, null, _comm, _comm.prop, _summ, _uc, null, false, (comp, combo, varType) { mixin(S_TRACE);
			auto b = new Button(comp, SWT.TOGGLE);
			immutable(FuncDef)[] funcs;
			Menu menu = null;
			void insertFunc(ref size_t i, immutable(FuncDef) funcDef) { mixin(S_TRACE);
				funcs ~= funcDef;
				auto s = .tryFormat(_comm.prop.msgs.functionNameWithDescription, funcDef.name, funcDef.shortDesc);
				s = MenuProps.buildMenu(i.text ~ " " ~ s, i.text, "", false);
				.createMenuItem2(_comm, menu, s, _comm.prop.images.functions, { showFuncWin(funcDef.name, [.tuple(ArgType.String, combo.getText())]); }, null);
				i++;
			}
			void insertPath(bool refs) { mixin(S_TRACE);
				auto path = combo.getText();
				path = path.replace("\"", "\"\"");
				_expr.insert((refs ? "@\"" : "\"") ~ path ~ "\"");
			}

			final switch (varType) {
			case VariableType.Flag:
				b.setToolTipText(_comm.prop.msgs.insertFlagIntoExpression);
				b.setImage(_comm.prop.images.flag);
				menu = _flagMenu;

				auto s = MenuProps.buildMenu(_comm.prop.msgs.insertFlagPath, "F", "", false);
				.createMenuItem2(_comm, _flagMenu, s, _comm.prop.images.flag, { insertPath(false); }, () => combo.getText() != "");
				new MenuItem(_flagMenu, SWT.SEPARATOR);

				size_t i = 0;
				foreach (funcDef; funcDefs) { mixin(S_TRACE);
					switch (funcDef.name) {
					case "FLAGVALUE":
					case "FLAGTEXT":
						insertFunc(i, funcDef);
						break;
					default:
						break;
					}
				}
				break;
			case VariableType.Step:
				b.setToolTipText(_comm.prop.msgs.insertStepIntoExpression);
				b.setImage(_comm.prop.images.step);
				menu = _stepMenu;

				auto s = MenuProps.buildMenu(_comm.prop.msgs.insertStepPath, "S", "", false);
				.createMenuItem2(_comm, _stepMenu, s, _comm.prop.images.step, { insertPath(false); }, () => combo.getText() != "");
				new MenuItem(_stepMenu, SWT.SEPARATOR);

				size_t i = 0;
				foreach (funcDef; funcDefs) {
					switch (funcDef.name) {
					case "STEPVALUE":
					case "STEPTEXT":
					case "STEPMAX":
						insertFunc(i, funcDef);
						break;
					default:
						break;
					}
				}
				break;
			case VariableType.Variant:
				b.setToolTipText(_comm.prop.msgs.insertVariantIntoExpression);
				b.setImage(_comm.prop.images.variant);
				menu = _variantMenu;

				auto s = MenuProps.buildMenu(_comm.prop.msgs.insertVariantPath, "S", "", false);
				.createMenuItem2(_comm, _variantMenu, s, _comm.prop.images.variant, { insertPath(false); }, () => combo.getText() != "");
				auto r = MenuProps.buildMenu(_comm.prop.msgs.insertVariantReference, "R", "", false);
				.createMenuItem2(_comm, _variantMenu, r, _comm.prop.images.variantRef, { insertPath(true); }, () => combo.getText() != "");
				new MenuItem(_variantMenu, SWT.SEPARATOR);

				size_t i = 0;
				foreach (funcDef; funcDefs) {
					switch (funcDef.name) {
					case "VAR":
						insertFunc(i, funcDef);
						break;
					default:
						break;
					}
				}
				break;
			}
			.listener(b, SWT.Selection, { mixin(S_TRACE);
				if (b.getSelection()) { mixin(S_TRACE);
					auto pt = b.toDisplay(new Point(0, 0));
					pt.y += b.getSize().y;
					menu.setLocation(pt);
					menu.setVisible(true);
				} else { mixin(S_TRACE);
					menu.setVisible(false);
				}
			});
			.listener(menu, SWT.Show, { mixin(S_TRACE);
				b.setSelection(true);
			});
			.listener(menu, SWT.Hide, { mixin(S_TRACE);
				b.setSelection(false);
			});
			return b;
		});
		var.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto sep = new Label(varComp, SWT.SEPARATOR | SWT.VERTICAL);
		auto sepGD = new GridData(GridData.FILL_VERTICAL);
		sepGD.heightHint = 0.ppis;
		sep.setLayoutData(sepGD);

		_func = new Button(varComp, SWT.TOGGLE);
		_func.setImage(_comm.prop.images.functions);
		_func.setText(_comm.prop.msgs.insertFunctionIntoExpression);
		_func.setLayoutData(new GridData(GridData.FILL_VERTICAL));
		.listener(_func, SWT.Selection, { showFuncWin(true); });

		auto hComp = new Composite(this, SWT.NONE);
		hComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		hComp.setLayout(zeroMarginGridLayout(2, false));

		auto op = new Label(hComp, SWT.NONE);
		op.setText(_comm.prop.msgs.operators);
		op.setLayoutData(new GridData(GridData.VERTICAL_ALIGN_BEGINNING));

		auto eHint = new Text(hComp, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.READ_ONLY);
		.createTextMenu!Text(_comm, _comm.prop, eHint, null);
		eHint.setText(_comm.prop.msgs.operatorList);
		eHint.setFont(_expr.getFont());
		eHint.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		setTabList([_expr, varComp]);

		_display = getDisplay();
		auto checkThr = new core.thread.Thread(&checkThread);
		checkThr.start();

		_comm.refFlagAndStep.add(&refFlagAndStep);
		_comm.delFlagAndStep.add(&refFlagAndStep);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_quit = true;
			checkThr.join();

			_comm.refFlagAndStep.remove(&refFlagAndStep);
			_comm.delFlagAndStep.remove(&refFlagAndStep);
		});
	}

	private void showFuncWin(string name, in Tuple!(ArgType, string)[] args) { mixin(S_TRACE);
		_func.setSelection(true);
		showFuncWin(false);
		_funcEdit.selectFunction(name, args);
		_funcEdit.shell.open();
		_funcEdit.focusToArgs();
	}
	private void showFuncWin(bool open) { mixin(S_TRACE);
		if (_func.getSelection()) { mixin(S_TRACE);
			if (_funcEdit) { mixin(S_TRACE);
				_funcEdit.shell.setActive();
				return;
			}
			_funcEdit = new FunctionCallEditor(_comm, _summ, _uc, _func, &_expr.insert);
			.listener(_funcEdit.shell, SWT.Dispose, { mixin(S_TRACE);
				_func.setSelection(false);
				_funcEdit = null;
			});
			if (open) _funcEdit.shell.open();
		} else { mixin(S_TRACE);
			if (_funcEdit) { mixin(S_TRACE);
				_funcEdit.shell.dispose();
				_funcEdit = null;
			}
		}
	}

	@property
	Text editor() { return _expr; }

	@property
	string expression() { return .wrapReturnCode(_expr.getText()); }
	@property
	void expression(string expr) { mixin(S_TRACE);
		_expr.setText(expr);
		checkExpression(true);
	}

	@property
	VariantVal returnValue() { return _returnValue; }

	string[] warnings() { return _ws; }
}

/// 関数入力支援ウィジェット。
private class FunctionCallEditor {
	private class ArgsUndo : Undo {
		private int _selected;
		private ArgType[] _selectedArgType;
		private string[] _values;
		this () { mixin(S_TRACE);
			store();
		}
		private void store() { mixin(S_TRACE);
			_selected = _args.getSelectionIndex();
			_selectedArgType = this.outer._selectedArgType.dup;
			_values = .iota(0, _args.getItemCount()).map!(i => _args.getItem(i).getText(2)).array();
		}
		private void impl() { mixin(S_TRACE);
			_typeEdit.cancel();
			_valueEdit.cancel();
			auto selected = _selected;
			auto _selectedArgType = _selectedArgType.dup;
			auto values = _values.dup;
			store();
			this.outer._selectedArgType = _selectedArgType;
			_args.setItemCount(cast(int)_selectedArgType.length);
			foreach (i; 0 .. _args.getItemCount()) { mixin(S_TRACE);
				auto itm = _args.getItem(i);
				if (i < _argDefs.length - 1 || !_argDefs[$ - 1].varArg) { mixin(S_TRACE);
					itm.setText(0, _argDefs[i].name);
				} else { mixin(S_TRACE);
					itm.setText(0, .tryFormat(_argDefs[$ - 1].name, (i - _argDefs.length) + 2));
				}
				itm.setText(1, argTypeName(_selectedArgType[i]));
				itm.setText(2, values[i]);
			}
			_args.select(selected);
			_args.showSelection();
		}
		override
		void undo() { impl(); }
		override
		void redo() { impl(); }
		override
		void dispose() { mixin(S_TRACE);
			// 処理無し
		}
	}
	private void store() {
		_undo ~= new ArgsUndo;
	}
	private void refUndoMax() { mixin(S_TRACE);
		_undo.max = _comm.prop.var.etc.undoMaxEtc;
	}

	private Commons _comm;
	private const(Summary) _summ;
	private const(UseCounter) _uc;

	private Shell _shell;
	private Combo _category;
	private FunctionCategory[] _categories;
	private Combo _func;

	private Text _decl;
	private Text _desc;
	private Text _example;

	private Table _args;

	private TableComboEdit!Combo _typeEdit;
	private TableTCEdit _valueEdit;

	private immutable(FuncDef[]) _allFuncDefs;
	private immutable(FuncDef)[] _funcDefs;
	private IncSearch _incSearch;
	private string _selectedFuncName = "";
	private UndoManager _undo;

	private immutable(ArgDef)[] _argDefs = [];
	private ArgType[][] _argTypes = [];
	private ArgType[] _selectedArgType = [];

	this (Commons comm, in Summary summ, in UseCounter uc, Control parent, void delegate(string) insert) { mixin(S_TRACE);
		_comm = comm;
		_summ = summ;
		_uc = uc;
		_allFuncDefs = .functionDefinitions(_comm.prop.parent);

		auto parShl = parent.getShell();

		_shell = new Shell(parShl, SWT.TITLE | SWT.RESIZE | SWT.CLOSE | SWT.TOOL);
		_shell.setText(_comm.prop.msgs.insertFunctionIntoExpression);
		_shell.setSize(_comm.prop.var.etc.functionCallEditorWidth, _comm.prop.var.etc.functionCallEditorHeight);
		void saveWin() { mixin(S_TRACE);
			auto size = _shell.getSize();
			_comm.prop.var.etc.functionCallEditorWidth = size.x;
			_comm.prop.var.etc.functionCallEditorHeight = size.y;
		}
		.listener(_shell, SWT.Move, &saveWin);
		.listener(_shell, SWT.Resize, &saveWin);

		auto cloc = parent.toDisplay(new Point(0, 0));
		cloc.y += parent.getSize().y;
		auto p = _shell.getSize();
		intoDisplay(cloc.x, cloc.y, p.x, p.y);
		_shell.setBounds(cloc.x, cloc.y, p.x, p.y);

		auto sgl = normalGridLayout(1, true);
		sgl.marginWidth = 0;
		_shell.setLayout(sgl);

		auto sash = new SplitPane(_shell, SWT.VERTICAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto top = new Composite(sash, SWT.NONE);
		top.setLayout(zeroMarginGridLayout(1, true));
		auto bottom = new Composite(sash, SWT.NONE);
		bottom.setLayout(zeroMarginGridLayout(1, true));
		{ mixin(S_TRACE);
			auto comp = new Composite(top, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			auto gd = normalGridLayout(2, false);
			gd.marginHeight = 0.ppis;
			comp.setLayout(gd);

			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(_comm.prop.msgs.functionCategory);
			_category = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			_category.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
			_category.add(_comm.prop.msgs.allFunctions);
			foreach (category; EnumMembers!FunctionCategory) { mixin(S_TRACE);
				_category.add(_comm.prop.msgs.functionCategoryName(category));
				_categories ~= category;
			}
			_category.select(0);
			.listener(_category, SWT.Selection, &categorySelected);

			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(_comm.prop.msgs.selectFunction);
			_func = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			_func.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
			.listener(_func, SWT.Selection, &functionSelected);

			_incSearch = new IncSearch(_comm, _func, () => true);
			_incSearch.modEvent ~= &updateFunctions;

			auto menu = new Menu(_func.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
				_typeEdit.enter();
				_valueEdit.enter();
				.forceFocus(_func, true);
				_incSearch.startIncSearch();
			}, () => true);
			_func.setMenu(menu);
		}
		(new Label(top, SWT.SEPARATOR | SWT.HORIZONTAL)).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{ mixin(S_TRACE);
			auto comp = new Composite(top, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto gd = normalGridLayout(2, false);
			gd.marginHeight = 0.ppis;
			comp.setLayout(gd);

			auto declL = new Label(comp, SWT.NONE);
			declL.setText(_comm.prop.msgs.functionDeclaration);
			_decl = new Text(comp, SWT.BORDER | SWT.READ_ONLY);
			createTextMenu!Text(_comm, _comm.prop, _decl, null);
			auto baseFont = _decl.getFont();
			auto fSize = baseFont ? cast(uint)baseFont.getFontData()[0].height : 0;
			auto font = new Font(_shell.getDisplay(), .dwtData(_comm.prop.adjustFont(_comm.prop.looks.textDlgFont(fSize))));
			.listener(comp, SWT.Dispose, { font.dispose(); });
			_decl.setFont(font);
			auto gc = new GC(_decl);
			scope (exit) gc.dispose();
			auto lineH = gc.getFontMetrics().getHeight();
			auto declGD = new GridData(GridData.FILL_HORIZONTAL);
			declGD.heightHint = _decl.computeSize(SWT.DEFAULT, lineH).y;
			_decl.setLayoutData(declGD);

			auto descL = new Label(comp, SWT.NONE);
			descL.setText(_comm.prop.msgs.functionDescription);
			_desc = new Text(comp, SWT.BORDER | SWT.READ_ONLY | SWT.WRAP | SWT.V_SCROLL);
			createTextMenu!Text(_comm, _comm.prop, _desc, null);
			auto descGD = new GridData(GridData.FILL_BOTH);
			descGD.heightHint = _desc.computeSize(SWT.DEFAULT, lineH * 4).y;
			_desc.setLayoutData(descGD);

			auto exampleL = new Label(comp, SWT.NONE);
			exampleL.setText(_comm.prop.msgs.functionExample);
			_example = new Text(comp, SWT.BORDER | SWT.READ_ONLY);
			createTextMenu!Text(_comm, _comm.prop, _example, null);
			_example.setFont(font);
			auto exampleGD = new GridData(GridData.FILL_HORIZONTAL);
			exampleGD.heightHint = _example.computeSize(SWT.DEFAULT, lineH).y;
			_example.setLayoutData(exampleGD);
		}
		{ mixin(S_TRACE);
			auto comp = new Composite(bottom, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto gd = normalGridLayout(1, true);
			gd.marginHeight = 0;
			comp.setLayout(gd);

			_args = .rangeSelectableTable(comp, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER);
			_args.setLayoutData(new GridData(GridData.FILL_BOTH));
			_args.setHeaderVisible(true);

			auto prop = _comm.prop;
			auto argName = new TableColumn(_args, SWT.NONE);
			argName.setText(_comm.prop.msgs.functionArgumentName);
			.saveColumnWidth!("prop.var.etc.functionArgumentNameColumn")(_comm.prop, argName);
			auto argType = new TableColumn(_args, SWT.NONE);
			argType.setText(_comm.prop.msgs.functionArgumentType);
			.saveColumnWidth!("prop.var.etc.functionArgumentTypeColumn")(_comm.prop, argType);
			auto argValue = new TableColumn(_args, SWT.NONE);
			argValue.setText(_comm.prop.msgs.functionArgumentValue);
			.saveColumnWidth!("prop.var.etc.functionArgumentValueColumn")(_comm.prop, argValue);

			_typeEdit = new TableComboEdit!Combo(_comm, _comm.prop, _args, 1, &createTypeEditor, &typeEditEnd, null);
			_typeEdit.quickStart = EditStartType.SingleClick;
			_valueEdit = new TableTCEdit(_comm, _args, 2, &createValueEditor, &valueEditEnd, null);
			_valueEdit.quickStart = EditStartType.SingleClick;
			_valueEdit.exitEvent ~= &valueEditExit;

			_undo = new UndoManager(_comm.prop.var.etc.undoMaxEtc);
			_comm.refUndoMax.add(&refUndoMax);
			.listener(_args, SWT.Dispose, { mixin(S_TRACE);
				_comm.refUndoMax.remove(&refUndoMax);
			});

			auto menu = new Menu(_args.getShell(), SWT.POP_UP);
			createMenuItem(comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
			createMenuItem(comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
			_args.setMenu(menu);
		}
		(new Label(bottom, SWT.SEPARATOR | SWT.HORIZONTAL)).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{ mixin(S_TRACE);
			auto comp = new Composite(bottom, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			auto gl = normalGridLayout(1, true);
			gl.marginHeight = 0.ppis;
			comp.setLayout(gl);

			auto insertFunc = new Button(comp, SWT.PUSH);
			insertFunc.setText(_comm.prop.msgs.insertFunctionIntoExpressionButton);
			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			gd.widthHint = .max(insertFunc.computeSize(SWT.DEFAULT, SWT.DEFAULT).x, _comm.prop.var.etc.buttonWidth);
			insertFunc.setLayoutData(gd);
			.listener(insertFunc, SWT.Selection, { mixin(S_TRACE);
				_typeEdit.enter();
				_valueEdit.enter();
				string[] args;
				foreach (i, argType; _selectedArgType) { mixin(S_TRACE);
					auto t = _args.getItem(cast(int)i).getText(2);
					final switch (argType) {
					case ArgType.Number:
					case ArgType.Boolean:
						args ~= t;
						break;
					case ArgType.String:
					case ArgType.Flag:
					case ArgType.Step:
					case ArgType.Variant:
						args ~= "\"" ~ t.replace("\"", "\"\"") ~ "\"";
						break;
					case ArgType.VariantRef:
						args ~= "@\"" ~ t.replace("\"", "\"\"") ~ "\"";
						break;
					case ArgType.NoArgument:
						break;
					case ArgType.Any:
					case ArgType.NumberOrString:
						assert (0);
					}
				}
				insert("%s(%s)".format(_selectedFuncName, args.join(", ")));
			});
			_comm.put(insertFunc, () => _selectedFuncName != "");
		}
		.setupWeights(sash, comm.prop.var.etc.expressionFunctionAndArgsSashT, comm.prop.var.etc.expressionFunctionAndArgsSashB);

		updateFunctions();
	}

	private void categorySelected() { mixin(S_TRACE);
		updateFunctions();
	}
	private void functionSelected() { mixin(S_TRACE);
		auto funcDef = _funcDefs[_func.getSelectionIndex()];
		if (_selectedFuncName == funcDef.name) return;
		_typeEdit.cancel();
		_valueEdit.cancel();
		_args.removeAll();
		if (_func.getSelectionIndex() == -1) { mixin(S_TRACE);
			_decl.setText("");
			_desc.setText("");
			_example.setText("");
			_args.setEnabled(false);
			_comm.refreshToolBar();
			return;
		}
		string[] args;
		_argDefs = [];
		_argTypes = [];
		_selectedArgType = [];
		foreach (i, arg; funcDef.args) { mixin(S_TRACE);
			ArgType[] argTypes;
			final switch (arg.type) {
			case ArgType.Number:
				argTypes = [ArgType.Number, ArgType.VariantRef];
				break;
			case ArgType.String:
				argTypes = [ArgType.String, ArgType.VariantRef];
				break;
			case ArgType.Flag:
				argTypes = [ArgType.Flag, ArgType.VariantRef];
				break;
			case ArgType.Step:
				argTypes = [ArgType.Step, ArgType.VariantRef];
				break;
			case ArgType.Variant:
				argTypes = [ArgType.Variant, ArgType.VariantRef];
				break;
			case ArgType.Boolean:
				argTypes = [ArgType.Boolean, ArgType.VariantRef];
				break;
			case ArgType.Any:
				argTypes = [ArgType.String, ArgType.Number, ArgType.Boolean, ArgType.VariantRef];
				break;
			case ArgType.NumberOrString:
				argTypes = [ArgType.String, ArgType.Number, ArgType.VariantRef];
				break;
			case ArgType.VariantRef:
			case ArgType.NoArgument:
				assert (0);
			}
			if (arg.optional) argTypes = ArgType.NoArgument ~ argTypes;
			auto itm = new TableItem(_args, SWT.NONE);
			string s = arg.varArg ? .tryFormat(arg.name, 1) : arg.name;
			itm.setText(0, s);
			itm.setText(1, argTypeName(argTypes[0]));
			if (!arg.optional) itm.setText(2, arg.initValue);
			_argDefs ~= arg;
			_argTypes ~= argTypes;
			_selectedArgType ~= argTypes[0];
			if (arg.varArg) { mixin(S_TRACE);
				auto itm2 = new TableItem(_args, SWT.NONE);
				itm2.setText(0, .tryFormat(arg.name, 2));
				itm2.setText(1, _comm.prop.msgs.noArgument);
				_selectedArgType ~= ArgType.NoArgument;
			}

			if (0 < i) s = ", " ~ s;
			if (arg.varArg) { mixin(S_TRACE);
				s ~= " ...";
			}
			if (arg.optional) { mixin(S_TRACE);
				s = "[" ~ s ~ "]";
			}
			args ~= s;
		}
		auto decl = "%s(%s)".format(funcDef.name, args.join(""));
		_decl.setText(.tryFormat(_comm.prop.msgs.functionAs, decl, argTypeName(funcDef.returnType)));
		_desc.setText(funcDef.desc);
		_example.setText(funcDef.example);
		_args.setEnabled(0 < funcDef.args.length);

		_selectedFuncName = funcDef.name;
		_undo.reset();
		_comm.refreshToolBar();
	}
	private string argTypeName(ArgType argType) { mixin(S_TRACE);
		final switch (argType) {
		case ArgType.Number:
			return _comm.prop.msgs.argNumber;
		case ArgType.String:
			return _comm.prop.msgs.argString;
		case ArgType.Flag:
			return _comm.prop.msgs.argFlag;
		case ArgType.Step:
			return _comm.prop.msgs.argStep;
		case ArgType.Variant:
			return _comm.prop.msgs.argVariant;
		case ArgType.Boolean:
			return _comm.prop.msgs.argBoolean;
		case ArgType.NumberOrString:
			assert (0);
		case ArgType.Any:
			return _comm.prop.msgs.argAny;
		case ArgType.VariantRef:
			return _comm.prop.msgs.variantReference;
		case ArgType.NoArgument:
			return _comm.prop.msgs.noArgument;
		}
	}

	private void updateFunctions() { mixin(S_TRACE);
		_func.removeAll();
		_funcDefs = [];
		auto i = 0;
		auto all = _category.getSelectionIndex() <= 0;
		auto category = all ? FunctionCategory.init : _categories[_category.getSelectionIndex() - 1];
		foreach (funcDef; _allFuncDefs) { mixin(S_TRACE);
			if (!_incSearch.match(funcDef.name)) continue;
			if (!all && !funcDef.category.contains(category)) continue;
			_func.add(.tryFormat(_comm.prop.msgs.functionNameWithDescription, funcDef.name, funcDef.shortDesc));
			_funcDefs ~= funcDef;
			if (funcDef.name == _selectedFuncName) { mixin(S_TRACE);
				_func.select(cast(int)i);
			}
			i++;
		}
		if (_func.getSelectionIndex() == -1 && _func.getItemCount() != 0) { mixin(S_TRACE);
			_func.select(0);
			functionSelected();
		}
	}

	private ArgType[] argTypes(size_t index) { mixin(S_TRACE);
		return index < _argTypes.length ? _argTypes[index] : (ArgType.NoArgument ~ _argTypes[$ - 1]);
	}
	private void createTypeEditor(TableItem itm, int column, out string[] strs, out string str, out bool canIncSearch) { mixin(S_TRACE);
		canIncSearch = false;
		str = itm.getText(1);
		foreach (argType; argTypes(_args.indexOf(itm))) { mixin(S_TRACE);
			strs ~= argTypeName(argType);
		}
	}
	private void typeEditEnd(TableItem selItm, int column, Combo combo) { mixin(S_TRACE);
		auto i = _args.indexOf(selItm);
		typeEditEndImpl(i, combo.getSelectionIndex(), false);
	}
	private void typeEditEndImpl(int i, int typeIndex, bool force) { mixin(S_TRACE);
		auto selItm = _args.getItem(i);
		auto old = _selectedArgType[i];
		auto argType = argTypes(i)[typeIndex];
		if (!force && old == argType) return;
		store();
		_selectedArgType[i] = argType;
		selItm.setText(1, argTypeName(argType));
		auto varArg = _argDefs.length <= i && _argDefs[$ - 1].varArg;
		if (argType == ArgType.NoArgument) { mixin(S_TRACE);
			if (varArg && 0 < i && i + 1 < _args.getItemCount()) { mixin(S_TRACE);
				_args.remove(i);
				_selectedArgType = _selectedArgType[0 .. i] ~ _selectedArgType[i + 1 .. $];
				foreach (j; i .. _args.getItemCount()) { mixin(S_TRACE);
					_args.getItem(j).setText(0, .tryFormat(_argDefs[$ - 1].name, (j - _argDefs.length) + 2));
				}
			} else { mixin(S_TRACE);
				selItm.setText(2, "");
			}
		} else { mixin(S_TRACE);
			if (varArg && old == ArgType.NoArgument) { mixin(S_TRACE);
				auto itm = new TableItem(_args, SWT.NONE);
				itm.setText(0, .tryFormat(_argDefs[$ - 1].name, (i - _argDefs.length) + 3));
				itm.setText(1, argTypeName(ArgType.NoArgument));
				_selectedArgType ~= ArgType.NoArgument;
			}

			if (!validArg(argType, selItm.getText())) { mixin(S_TRACE);
				selItm.setText(2, _argDefs[$ - 1].initValue);
			}
		}
	}
	private bool validArg(ArgType argType, string text) { mixin(S_TRACE);
		if (argType == ArgType.Number) { mixin(S_TRACE);
			try {
				.to!double(text);
			} catch (ConvException e) {
				return false;
			}
		} else if (argType == ArgType.Boolean) { mixin(S_TRACE);
			return text == "TRUE" || text == "FALSE";
		}
		return true;
	}
	private int _selectType = -1;
	private TableItem _editingValue = null;
	private Control createValueEditor(TableItem itm, int editC) { mixin(S_TRACE);
		_selectType = -1;
		_editingValue = null;
		auto i =_args.indexOf(itm);
		auto argType = _selectedArgType[i];
		auto val = itm.getText(2);
		if (_selectedArgType[i] is ArgType.NoArgument) { mixin(S_TRACE);
			foreach (j, argType2; argTypes(i)) { mixin(S_TRACE);
				if (ArgType.NoArgument !is argType2) { mixin(S_TRACE);
					_selectType = cast(int)j;
					_editingValue = itm;
					argType = argType2;
					itm.setText(1, argTypeName(argType));
					val = _argDefs[$ - 1].initValue;
					break;
				}
			}
		}
		Control createIDEditor(F)() { mixin(S_TRACE);
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				return .createVariableCombo!(Combo, F)(_comm, _summ, _uc, _args, null, val);
			} else { mixin(S_TRACE);
				return .createTextEditor(_comm, _comm.prop, _args, val);
			}
		}
		final switch (argType) {
		case ArgType.Number:
			auto t = .createNumberEditor(_comm, _args, SWT.BORDER, null);
			t.setText(val);
			return t;
		case ArgType.String:
			return .createTextEditor(_comm, _comm.prop, _args, val);
		case ArgType.Flag:
			return createIDEditor!(cwx.flag.Flag)();
		case ArgType.Step:
			return createIDEditor!(Step)();
		case ArgType.Variant:
			return createIDEditor!(cwx.flag.Variant)();
		case ArgType.Boolean:
			auto v = VariantVal(VariantType.Boolean);
			v.boolVal = true;
			auto trueVal = .variantValueToText(v);
			v.boolVal = false;
			auto falseVal = .variantValueToText(v);
			return .createComboEditor!Combo(_comm, _comm.prop, _args, [trueVal, falseVal], val);
		case ArgType.VariantRef:
			return createIDEditor!(cwx.flag.Variant)();
		case ArgType.NumberOrString:
		case ArgType.Any:
		case ArgType.NoArgument:
			assert (0);
		}
	}
	private void valueEditEnd(TableItem selItm, int column, Control ctrl) { mixin(S_TRACE);
		string text;
		if (auto t = cast(Text)ctrl) {
			text = t.getText();
		} else if (auto t = cast(Combo)ctrl) { mixin(S_TRACE); mixin(S_TRACE);
			text = t.getText();
		} else assert (0);
		if (selItm.getText(2) == text && _selectType == -1) { mixin(S_TRACE);
			_selectType = -1;
			_editingValue = null;
			return;
		}
		auto i =_args.indexOf(selItm);
		if (_selectedArgType[i] == ArgType.Number) { mixin(S_TRACE);
			try {
				.to!double(text);
			} catch (ConvException e) {
				return;
			}
		}
		if (_selectType == -1) { mixin(S_TRACE);
			store();
		} else { mixin(S_TRACE);
			typeEditEndImpl(i, _selectType, true);
			_selectType = -1;
			_editingValue = null;
		}
		selItm.setText(2, text);
	}
	private void valueEditExit(bool cancel) { mixin(S_TRACE);
		if (cancel && _selectType != -1 && _editingValue) { mixin(S_TRACE);
			_editingValue.setText(1, argTypeName(ArgType.NoArgument));
			_editingValue.setText(2, "");
		}
		_selectType = -1;
		_editingValue = null;
	}

	void selectFunction(string name, in Tuple!(ArgType, string)[] args) { mixin(S_TRACE);
		_typeEdit.cancel();
		_valueEdit.cancel();
		_incSearch.close();
		void putArgs() { mixin(S_TRACE);
			foreach (j, arg; args) { mixin(S_TRACE);
				auto itm = _args.getItem(cast(int)j);
				itm.setText(1, argTypeName(arg[0]));
				itm.setText(2, arg[1]);
			}
		}
		if (_selectedFuncName == name) { mixin(S_TRACE);
			store();
			putArgs();
			return;
		}
		foreach (i, funcDef; _funcDefs) { mixin(S_TRACE);
			if (funcDef.name == name) { mixin(S_TRACE);
				_func.select(cast(int)i);
				functionSelected();
				putArgs();
				return;
			}
		}
		foreach (i, funcDef; _allFuncDefs) { mixin(S_TRACE);
			if (funcDef.name == name) { mixin(S_TRACE);
				_category.select(cast(int)_categories.cCountUntil(funcDef.category[0]) + 1);
				updateFunctions();
				selectFunction(name, args);
				return;
			}
		}
	}

	void focusToArgs() { _args.setFocus(); }

	Shell shell() { return _shell; }
}

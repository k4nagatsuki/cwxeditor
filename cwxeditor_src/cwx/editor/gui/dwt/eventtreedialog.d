
module cwx.editor.gui.dwt.eventtreedialog;

import cwx.area;
import cwx.event;
import cwx.perf;
import cwx.structs;
import cwx.summary;
import cwx.types;
import cwx.utils;
import cwx.warning;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.keycodeview;
import cwx.editor.gui.dwt.roundview;

import std.algorithm : map;
import std.array;
import std.traits;

import org.eclipse.swt.all;

import java.lang.all;

public:

/// イベントツリーの情報を編集するダイアログ。
class EventTreeDialog : AbsDialog {
	private immutable MATCHING_TYPE = [MatchingType.Or, MatchingType.And];

	private int _readOnly = SWT.NONE;

	private Commons _comm = null;
	private Summary _summ = null;
	private EventTreeOwner _eto = null;
	private EventTree _et = null;

	private Text _name = null;
	private Combo _keyCodeMatchingType = null;

	private Button _enter = null;
	private Button _lose = null;
	private Button _escape = null;
	private Button _everyRound = null;
	private Button _round0 = null;
	private KeyCodeView _keyCodes = null;
	private RoundView _rounds = null;

	private void refreshWarning() { mixin(S_TRACE);
		string[] ws;

		ws ~= .sjisWarnings(_comm.prop.parent, _summ, _name.getText(), _comm.prop.msgs.eventName);

		if (!_comm.prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
			if (_everyRound && _everyRound.getSelection()) ws ~= _comm.prop.msgs.warningEveryRound;
			if (_round0 && _round0.getSelection()) ws ~= _comm.prop.msgs.warningRound0;
		}

		if (_keyCodes) ws ~= _keyCodes.warnings;
		if (_keyCodeMatchingType && keyCodeMatchingType is MatchingType.And && !_comm.prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
			ws ~= _comm.prop.msgs.warningKeyCodeMatchingTypeAnd;
		}

		if (_rounds) ws ~= _rounds.warnings;

		warning = ws;
	}

	private bool _setAutoName = true;
	private void setAutoName() { mixin(S_TRACE);
		if (ignoreMod) return;
		if (!_setAutoName) return;
		if (_name.getText() != "") { mixin(S_TRACE);
			_setAutoName = false;
			return;
		}
		auto treeName = "";
		if (_enter && _enter.getSelection()) { mixin(S_TRACE);
			if (cast(MenuCard)_eto) { mixin(S_TRACE);
				treeName = _comm.prop.msgs.selectTree;
			} else if (cast(EnemyCard)_eto) { mixin(S_TRACE);
				treeName = _comm.prop.msgs.deadTree;
			} else if (cast(Area)_eto) { mixin(S_TRACE);
				treeName = _comm.prop.msgs.enterTree;
			} else if (cast(Battle)_eto) { mixin(S_TRACE);
				treeName = _comm.prop.msgs.victoryTree;
			} else if (cast(PlayerCardEvents)_eto) { mixin(S_TRACE);
				treeName = _comm.prop.msgs.deadTree;
			} else assert (0);
		} else if (_lose && _lose.getSelection()) { mixin(S_TRACE);
			treeName = _comm.prop.msgs.loseTree;
		} else if (_escape && _escape.getSelection()) { mixin(S_TRACE);
			treeName = _comm.prop.msgs.escapeTree;
		} else if (_everyRound && _everyRound.getSelection()) { mixin(S_TRACE);
			treeName = _comm.prop.msgs.everyRoundTree;
		} else if (_round0 && _round0.getSelection()) { mixin(S_TRACE);
			treeName = _comm.prop.msgs.round0Tree;
		} else if (_keyCodes && !_keyCodes.isNewItemEditing && _keyCodes.keyCodes.length) { mixin(S_TRACE);
			treeName = .tryFormat(_comm.prop.msgs.keyCodeTree, _keyCodes.keyCodes[0]);
		} else if (_rounds && !_rounds.isNewItemEditing && _rounds.rounds.length) { mixin(S_TRACE);
			treeName = .tryFormat(_comm.prop.msgs.roundTree, _rounds.rounds[0]);
		}
		if (treeName == "") return;
		_setAutoName = false;
		_name.setText(treeName);
	}

	this (Commons comm, Shell parent, Summary summ, EventTreeOwner eto, EventTree et, bool create, bool readOnly)
		in (eto !is null)
		in (et !is null)
	{ mixin(S_TRACE);
		auto title = create ? comm.prop.msgs.dlgTitNewEvent : .tryFormat(comm.prop.msgs.dlgTitEventTree, et.name);
		auto dSize = eto.canHasFireRound ? cast(DSize)comm.prop.var.eventIgnitionsWithRoundsDlg : comm.prop.var.eventIgnitionsDlg;
		super (comm.prop, parent, false, title, comm.prop.images.eventTree, true, dSize, true, true);
		enterClose = false;
		if (!create) _setAutoName = false;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_comm = comm;
		_summ = summ;
		_eto = eto;
		_et = et;
	}

	@property
	inout
	inout(EventTreeOwner) eventTreeOwner() { return _eto; }

	@property
	inout
	inout(EventTree) eventTree() { return _et; }

	override void setup(Composite area) { mixin(S_TRACE);
		auto sys = _eto.canHasFireEnter || _eto.canHasFireLose || _eto.canHasFireEscape || _eto.canHasFireEveryRound || _eto.canHasFireRound0;
		auto kc = _eto.canHasFireKeyCode;
		auto round = _eto.canHasFireRound;
		auto col = 0;
		if (sys) col++;
		if (kc) col++;
		if (round) col++;
		area.setLayout(normalGridLayout(col, false));

		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_comm.prop.msgs.eventName);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = col;
			grp.setLayoutData(gd);
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			grp.setLayout(cl);
			_name = new Text(grp, SWT.BORDER);
			mod(_name);
			.listener(_name, SWT.Modify, &setAutoName);
			.listener(_name, SWT.Modify, &refreshWarning);
		}

		if (sys) { mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_comm.prop.msgs.eventTreeKindSystem);
			grp.setLayoutData(new GridData(GridData.VERTICAL_ALIGN_BEGINNING));
			grp.setLayout(normalGridLayout(1, true));

			Button createCheck(string name, bool warn = false) { mixin(S_TRACE);
				auto check = new Button(grp, SWT.CHECK);
				mod(check);
				check.setText(name);
				auto gd = new GridData;
				gd.grabExcessVerticalSpace = true;
				check.setLayoutData(gd);
				if (warn) .listener(check, SWT.Selection, &refreshWarning);
				.listener(check, SWT.Selection, &setAutoName);
				return check;
			}
			if (_eto.canHasFireEnter) { mixin(S_TRACE);
				if (cast(Area)_eto) { mixin(S_TRACE);
					_enter = createCheck(_comm.prop.msgs.enterTree);
				} else if (cast(Battle)_eto) { mixin(S_TRACE);
					_enter = createCheck(_comm.prop.msgs.victoryTree);
				} else if (cast(MenuCard)_eto) { mixin(S_TRACE);
					_enter = createCheck(_comm.prop.msgs.selectTree);
				} else if (cast(EnemyCard)_eto) { mixin(S_TRACE);
					_enter = createCheck(_comm.prop.msgs.deadTree);
				} else if (cast(PlayerCardEvents)_eto) { mixin(S_TRACE);
					_enter = createCheck(_comm.prop.msgs.deadTree);
				} else assert (0);
			}
			if (_eto.canHasFireLose) _lose = createCheck(_comm.prop.msgs.loseTree);
			if (_eto.canHasFireEscape) _escape = createCheck(_comm.prop.msgs.escapeTree);
			if (_eto.canHasFireEveryRound) _everyRound = createCheck(_comm.prop.msgs.everyRoundTree, true);
			if (_eto.canHasFireRound0) _round0 = createCheck(_comm.prop.msgs.round0Tree, true);
		}

		if (_eto.canHasFireKeyCode) { mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_comm.prop.msgs.eventTreeKindKeyCode);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(normalGridLayout(1, true));

			auto withKeyCodeIgnitionType = cast(EnemyCard)_eto || cast(PlayerCardEvents)_eto;
			_keyCodes = new KeyCodeView(_comm, _summ, grp, _readOnly, false, withKeyCodeIgnitionType, &catchMod);
			mod(_keyCodes);
			_keyCodes.setLayoutData(new GridData(GridData.FILL_BOTH));
			_keyCodes.modEvent ~= &setAutoName;
			_keyCodes.modEvent ~= &refreshWarning;

			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			comp.setLayout(zeroMarginGridLayout(2, false));

			auto l = new Label(comp, SWT.NONE);
			l.setText(_comm.prop.msgs.matchingType);

			_keyCodeMatchingType = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_keyCodeMatchingType);
			_keyCodeMatchingType.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
			foreach (type; MATCHING_TYPE) { mixin(S_TRACE);
				_keyCodeMatchingType.add(_comm.prop.msgs.matchingTypeName(type));
			}
			.listener(_keyCodeMatchingType, SWT.Selection, &refreshWarning);
		}

		if (_eto.canHasFireRound) { mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_comm.prop.msgs.eventTreeKindRound);
			grp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			cl.fillVertical = true;
			grp.setLayout(cl);

			_rounds = new RoundView(_comm, grp, _readOnly, &catchMod);
			mod(_rounds);
			_rounds.modEvent ~= &setAutoName;
		}

		_comm.refDataVersion.add(&refreshWarning);
		_comm.refTargetVersion.add(&refreshWarning);
		.listener(area, SWT.Dispose, { mixin(S_TRACE);
			_comm.refDataVersion.remove(&refreshWarning);
			_comm.refTargetVersion.remove(&refreshWarning);
		});

		ignoreMod = true;
		scope (exit) ignoreMod = false;

		assert (_et !is null);
		if (_enter) _enter.setSelection(_et.fireEnter);
		if (_lose) _lose.setSelection(_et.fireLose);
		if (_escape) _escape.setSelection(_et.fireEscape);
		if (_everyRound) _everyRound.setSelection(_et.fireEveryRound);
		if (_round0) _round0.setSelection(_et.fireRound0);
		if (_keyCodes) _keyCodes.keyCodes = .map!(keyCode => _comm.prop.sys.convFireKeyCode(keyCode))(_et.keyCodes).array();
		if (_keyCodeMatchingType) { mixin(S_TRACE);
			_keyCodeMatchingType.select(cast(int).cCountUntil(MATCHING_TYPE, _et.keyCodeMatchingType));
		}
		if (_rounds) _rounds.rounds = _et.rounds;
		_name.setText(_et.name);

		refreshWarning();
	}

	@property
	private MatchingType keyCodeMatchingType() { return MATCHING_TYPE[_keyCodeMatchingType.getSelectionIndex()]; }

	override bool apply() { mixin(S_TRACE);
		assert (_et !is null);
		_et.name = _name.getText();
		if (_enter) _et.enter = _enter.getSelection();
		if (_lose) _et.lose = _lose.getSelection();
		if (_escape) _et.escape = _escape.getSelection();
		if (_everyRound) _et.everyRound = _everyRound.getSelection();
		if (_round0) _et.round0 = _round0.getSelection();
		if (_keyCodes) _et.keyCodes = .map!(keyCode => _comm.prop.sys.toFKeyCode(keyCode))(_keyCodes.keyCodes).array();
		if (_keyCodeMatchingType) { mixin(S_TRACE);
			_et.keyCodeMatchingType = keyCodeMatchingType;
		}
		if (_rounds) _et.rounds = _rounds.rounds;

		getShell().setText(.tryFormat(_comm.prop.msgs.dlgTitEventTree, _et.name));
		return true;
	}
}

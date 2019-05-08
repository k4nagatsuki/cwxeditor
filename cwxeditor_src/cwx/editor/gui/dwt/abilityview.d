
module cwx.editor.gui.dwt.abilityview;

import cwx.perf;
import cwx.types;

import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;

import std.range;

import org.eclipse.swt.all;

class AbilityView : Composite {
	void delegate()[] modEvent;

	private Button[Physical] _phy;
	private Button[Mental] _mtl;

	private bool _enabled = true;
	private int _readOnly;

	this (Commons comm, Composite parent, int readOnly) {
		super (parent, SWT.NONE);
		_readOnly = readOnly;

		setLayout(zeroMarginGridLayout(2, false));

		{ mixin(S_TRACE);
			auto grp = new Group(this, SWT.NONE);
			grp.setText(comm.prop.msgs.aptPhysical);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout(cl);
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayout(normalGridLayout(1, true));
			foreach (phy; [Physical.Dex, Physical.Agl, Physical.Int,
					Physical.Str, Physical.Vit, Physical.Min]) { mixin(S_TRACE);
				auto radio = new Button(comp2, SWT.RADIO);
				radio.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				radio.setText(comm.prop.msgs.physicalName(phy));
				radio.setEnabled(!readOnly);
				_phy[phy] = radio;
				.listener(radio, SWT.Selection, { mixin(S_TRACE);
					foreach (dlg; modEvent) dlg();
				});
			}
		}
		{ mixin(S_TRACE);
			auto grp = new Group(this, SWT.NONE);
			grp.setText(comm.prop.msgs.aptMental);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout(cl);
			auto comp2 = new Composite(grp, SWT.NONE);
			auto gl = normalGridLayout(2, true);
			gl.horizontalSpacing = comm.prop.var.etc.radioGroupSeparatorWidth;
			comp2.setLayout(gl);
			static const Ms = [Mental.Aggressive, Mental.Unaggressive,
				Mental.Cheerful, Mental.Uncheerful,
				Mental.Brave, Mental.Unbrave, Mental.Cautious, Mental.Uncautious,
				Mental.Trickish, Mental.Untrickish];
			foreach (i, m; Ms) { mixin(S_TRACE);
				auto radio = new Button(comp2, SWT.RADIO);
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				radio.setText(comm.prop.msgs.mentalName(m));
				radio.setEnabled(!readOnly);
				_mtl[m] = radio;
				.listener(radio, SWT.Selection, { mixin(S_TRACE);
					foreach (dlg; modEvent) dlg();
				});
			}
		}

		physical = Physical.Dex;
		mental = Mental.Aggressive;
	}

	@property
	Physical physical() { mixin(S_TRACE);
		Physical r;
		putRadioValue!(Physical)(_phy, (v) { r = v; });
		return r;
	}
	@property
	void physical(Physical v) { mixin(S_TRACE);
		foreach (p, b; _phy) { mixin(S_TRACE);
			b.setSelection(p is v);
		}
	}

	@property
	Mental mental() { mixin(S_TRACE);
		Mental r;
		putRadioValue!(Mental)(_mtl, (v) { r = v; });
		return r;
	}
	@property
	void mental(Mental v) { mixin(S_TRACE);
		foreach (m, b; _mtl) { mixin(S_TRACE);
			b.setSelection(m is v);
		}
	}

	@property
	const
	bool enabled() { return _enabled; }
	@property
	void enabled(bool v) { mixin(S_TRACE);
		_enabled = v;
		foreach (radio; .chain(_phy.byValue(), _mtl.byValue())) { mixin(S_TRACE);
			radio.setEnabled(!_readOnly && v);
		}
	}
}

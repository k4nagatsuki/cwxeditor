
module cwx.editor.gui.dwt.scales;

import cwx.utils;

import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.dutils;

import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

class Scales : Composite {
	/// 値の変更時に呼び出される。
	void delegate()[] modEvent;

	private bool _readOnly;

	private Spinner[] _spns;
	private Scale[] _scales;
	private Canvas _hints;
	private int[] _borderlines;

	this (Composite parent, int style) {
		super (parent, style);
		_readOnly = (style & SWT.READ_ONLY) != 0;
		setLayout(zeroMarginGridLayout(3, false));
	}

	/// パラメータを指定して初期化を行う。
	/// 値の段階はstep_cで、最小値はminで設定する。
	void setScales(uint step_c, in string[] names, int page, int min = 0) {
		auto scStyle = _readOnly ? SWT.READ_ONLY : SWT.NONE;
		auto spStyle = _readOnly ? SWT.BORDER|SWT.READ_ONLY : SWT.BORDER;
		foreach (i; 0..names.length) {
			auto label = new Label(this, SWT.NONE);
			label.setText(names[i]);

			auto scaleComp = new Composite(this, SWT.NONE);
			scaleComp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			scaleComp.setLayout(cl);
			auto scale = new Scale(scaleComp, scStyle);
			_scales ~= scale;
			scale.setMinimum(0);
			scale.setMaximum(step_c - 1);
			scale.setPageIncrement(page);

			auto spn = new Spinner(this, spStyle);
			_spns ~= spn;
			spn.setMinimum(min);
			spn.setMaximum(step_c - 1 + min);

			auto sel = new Selection(scale, spn);
			scale.addSelectionListener(sel);
			spn.addSelectionListener(sel);
		}
		auto dummy = new Composite(this, SWT.NONE);
		auto dgd = new GridData;
		dgd.widthHint = 0;
		dgd.heightHint = 0;
		dummy.setLayoutData(dgd);
		_hints = new Canvas(this, SWT.DOUBLE_BUFFERED);
		_hints.setBackgroundMode(SWT.INHERIT_DEFAULT);
		auto hgd = new GridData(GridData.FILL_HORIZONTAL);
		auto gc = new GC(_hints);
		scope (exit) gc.dispose();
		hgd.heightHint = gc.getFontMetrics().getHeight();
		_hints.setLayoutData(hgd);
		_hints.addPaintListener(new PaintHints);
	}
	private class Selection : SelectionAdapter {
		private Scale _scale;
		private Spinner _spn;
		this (Scale scale, Spinner spn) {
			_scale = scale;
			_spn = spn;
		}
		override void widgetSelected(SelectionEvent e) {
			if (_scale is e.widget) {
				_spn.setSelection(_scale.getSelection() + _spn.getMinimum());
			} else {
				assert (_spn is e.widget);
				_scale.setSelection(_spn.getSelection() - _spn.getMinimum());
			}
			foreach (dlg; modEvent) dlg();
		}
	}
	private class PaintHints : PaintListener {
		override void paintControl(PaintEvent e) {
			auto ca = _hints.getClientArea();
			version (Windows) {
				import org.eclipse.swt.internal.win32.OS;
				import org.eclipse.swt.internal.win32.WINTYPES;
				RECT rect;
				OS.SendMessage(_scales[0].handle, TBM_GETCHANNELRECT, 0, &rect);
				int left = rect.left;
				OS.SendMessage(_scales[0].handle, TBM_GETTHUMBRECT, 0, &rect);
				left += (rect.right - rect.left) / 2;
			} else {
				int left = 15;
			}
			int w = ca.width - left * 2;

			int minVal = _spns[0].getMinimum();
			int maxVal = _spns[0].getMaximum();
			auto minStr = .text(minVal);
			auto maxStr = .text(maxVal);
			e.gc.drawText(minStr, left - e.gc.textExtent(minStr).x / 2, 0);
			e.gc.drawText(maxStr, ca.width - left - e.gc.textExtent(maxStr).x / 2, 0);

			int range = maxVal - minVal;
			foreach (b; borderlines) {
				auto bb = b - minVal;
				auto s = .text(b);
				auto x = cast(int)(w * (cast(real)bb / range)) + left - e.gc.textExtent(s).x / 2;
				e.gc.drawText(s, x, 0);
			}
		}
	}

	/// 値を設定する。
	void setValue(int index, int value) {
		int minVal = _spns[index].getMinimum();
		_spns[index].setSelection(value);
		_scales[index].setSelection(value - minVal);
	}
	/// 全ての値を設定する。
	void setValues(in int[] value) {
		foreach (i, v; value) {
			setValue(i, v);
		}
	}
	/// 値を返す。
	int getValue(int index) {
		return _spns[index].getSelection();
	}
	/// 全ての値を返す。
	int[] getValues() {
		int[] r;
		foreach (i, s; _spns) {
			r ~= s.getSelection();
		}
		return r;
	}

	/// 強調表示する値。
	@property
	void borderlines(in int[] lines) {
		_borderlines = lines.dup;
		_hints.redraw();
	}
	/// ditto
	@property
	const
	int[] borderlines() {
		return _borderlines.dup;
	}
}

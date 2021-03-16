
module cwx.editor.gui.dwt.radarspinner;

import cwx.utils;

import cwx.editor.gui.dwt.dutils : ppis, normalGridLayout;

import std.algorithm;
import std.conv;
import std.math;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Display;

import org.eclipse.swt.all;

import java.lang.all;

public:

class RadarSpinner : Composite {
	/// 値の変更時に呼び出される。
	void delegate()[] modEvent;

	/// トグルのスタイル。
	static enum Toggle {
		SQUARE, /// 四画。
		OVAL, /// 円。
		OBLIQUE_SQUARE, /// 斜めの四画。
		CROSS, /// 十字。
		NOTHING, /// 無し。
	}

	private void delegate(int, int)[] _modHandler;

	private Point[][] _tgls;
	private Rectangle[] _ovals;
	private int[][] _polys;
	private Composite[] _comps;
	private Point _maxSize;
	private Label[] _lbls;
	private Control[] _spns;
	private string[] _names;
	private uint _step_c;
	private size_t _param_c;
	private int _min;
	private ptrdiff_t _onDrag = -1;
	private int _ovalStep = 1;
	private static immutable int TOGGLE_SIZE = 5;
	private static immutable int TOGGLE_CATCH_SIZE = 11;
	private static immutable int MARGIN = 10;
	private int _antialias = SWT.DEFAULT;
	private bool _side = true;
	private bool _oval = false;
	private int[] _borderlines;
	private int _ovalW = SWT.DEFAULT, _ovalH = SWT.DEFAULT;
	private Color _ovalBack;
	private Color _ovalFore;
	private bool _readOnly;
	private Toggle _tstyle = Toggle.OBLIQUE_SQUARE;
	private int _alpha = 0x9F;

	private bool _mod = false;
	private Listener _mod_redraw;

	/// Params:
	/// parent = 親コンポーネント。
	/// style = スタイル。指定可能なスタイルはSWT.BORDER、DWT.READ_ONLY。
	this(Composite parent, int style) { mixin(S_TRACE);
		super(parent, style | SWT.DOUBLE_BUFFERED);
		setBackgroundMode(SWT.INHERIT_DEFAULT);
		_ovalFore = Display.getCurrent().getSystemColor(SWT.COLOR_LIST_FOREGROUND);
		_ovalBack = Display.getCurrent().getSystemColor(SWT.COLOR_LIST_BACKGROUND);
		_readOnly = (style & SWT.READ_ONLY) != 0;
		if (!_readOnly) { mixin(S_TRACE);
			_mod_redraw = new class Listener {
				override void handleEvent(Event e) { mixin(S_TRACE);
					foreach (dlg; modEvent) dlg();
					redraw();
				}
			};
			addListener(SWT.MouseMove, new class Listener {
				override void handleEvent(Event e) { mixin(S_TRACE);
					if (_onDrag >= 0) { mixin(S_TRACE);
						int x = e.x;
						int y = e.y;
						ptrdiff_t i = _onDrag;
						int sel = getValue(i) - _min;
						size_t minIdx = 0;
						double minDist = double.max;
						foreach (j, tgl; _tgls[i]) { mixin(S_TRACE);
							double dist = abs(tgl.x - x) + abs(tgl.y - y);
							if (dist <= minDist) { mixin(S_TRACE);
								minDist = dist;
								minIdx = j;
							}
						}
						setValue(i, cast(int)minIdx + _min);
						foreach (dlg; modEvent) dlg();
						redraw();
					} else { mixin(S_TRACE);
						checkCursor(e.x, e.y);
					}
				}
			});
			addListener(SWT.MouseUp, new class Listener {
				override void handleEvent(Event e) { mixin(S_TRACE);
					if (e.button == 1) { mixin(S_TRACE);
						_onDrag = -1;
						checkCursor(e.x, e.y);
					}
				}
			});
			addListener(SWT.MouseDown, new class Listener {
				override void handleEvent(Event e) { mixin(S_TRACE);
					if (e.button == 1) { mixin(S_TRACE);
						_onDrag = cursorFromPos(e.x, e.y);
						if (_onDrag >= 0) { mixin(S_TRACE);
							(cast(Spinner)_spns[_onDrag]).setFocus();
						}
					}
				}
			});
		}
		addListener(SWT.Resize, new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				_mod = true;
				resizeImpl();
			}
		});
		addListener(SWT.Paint, new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				resizeImpl();
				scope size = getClientArea();
				if (size.width == 0 || size.height == 0) return;
				auto gc = e.gc;
				gc.setAntialias(_antialias);
				if (_step_c > 0) { mixin(S_TRACE);
					for (uint i = 0; i < _step_c; i += _ovalStep) { mixin(S_TRACE);
						if (i == 0) { mixin(S_TRACE);
							gc.setLineWidth(2);
							gc.setForeground(e.gc.getForeground());
							gc.setBackground(_ovalBack);
							if (_oval) { mixin(S_TRACE);
								auto oval = _ovals[i];
								gc.fillOval(oval.x, oval.y, oval.width, oval.height);
								gc.drawOval(oval.x, oval.y, oval.width, oval.height);
							} else { mixin(S_TRACE);
								gc.fillPolygon(_polys[i]);
								gc.drawPolygon(_polys[i]);
							}
							gc.setForeground(_ovalFore);
							gc.setLineWidth(1);
							gc.setLineStyle(SWT.LINE_DASH);
						} else if (!isBorderline(_step_c + _min - 1 - i)) { mixin(S_TRACE);
							if (_oval) { mixin(S_TRACE);
								auto oval = _ovals[i];
								gc.drawOval(oval.x, oval.y, oval.width, oval.height);
							} else { mixin(S_TRACE);
								gc.drawPolygon(_polys[i]);
							}
						}
					}
					if ((_step_c - 1) % _ovalStep != 0) { mixin(S_TRACE);
						if (!isBorderline(0)) { mixin(S_TRACE);
							if (_oval) { mixin(S_TRACE);
								auto oval = _ovals[$ - 1];
								gc.drawOval(oval.x, oval.y, oval.width, oval.height);
							} else { mixin(S_TRACE);
								gc.drawPolygon(_polys[$ - 1]);
							}
						}
					}
					gc.setLineStyle(SWT.LINE_SOLID);
					foreach (line; _borderlines) { mixin(S_TRACE);
						if (_oval) { mixin(S_TRACE);
							auto oval = _ovals[$ + _min - 1 - line];
							gc.drawOval(oval.x, oval.y, oval.width, oval.height);
						} else { mixin(S_TRACE);
							gc.drawPolygon(_polys[$ + _min - 1 - line]);
						}
					}
					gc.setLineStyle(SWT.LINE_DASH);
					foreach (i, tgls; _tgls) { mixin(S_TRACE);
						gc.drawLine(tgls[0].x, tgls[0].y, tgls[$ - 1].x, tgls[$ - 1].y);
					}
				} else { mixin(S_TRACE);
					gc.setLineWidth(1);
				}
				if (_step_c > 0) { mixin(S_TRACE);
					gc.setLineStyle(SWT.LINE_SOLID);
					scope int[] poly;
					poly.length = _spns.length * 2;
					foreach (i, spn; _spns) { mixin(S_TRACE);
						auto tgl = _tgls[i][getValue(i) - _min];
						poly[i * 2] = tgl.x;
						poly[i * 2 + 1] = tgl.y;
					}
					if (_alpha > 0) { mixin(S_TRACE);
						gc.setAlpha(_alpha);
						gc.fillPolygon(poly);
						gc.setAlpha(0xFF);
					}
					gc.drawPolygon(poly);
					if (!_readOnly) { mixin(S_TRACE);
						// indexが小さい方を前に出すため、逆順に描画する。
						foreach_reverse (i, spn; _spns) { mixin(S_TRACE);
							auto tgl = _tgls[i][getValue(i) - _min];
							final switch (_tstyle) {
							case Toggle.SQUARE:
								int x = tgl.x - TOGGLE_SIZE.ppis / 2;
								int y = tgl.y - TOGGLE_SIZE.ppis / 2;
								gc.fillRectangle(x, y, TOGGLE_SIZE.ppis, TOGGLE_SIZE.ppis);
								gc.drawRectangle(x, y, TOGGLE_SIZE.ppis, TOGGLE_SIZE.ppis);
								break;
							case Toggle.OVAL:
								int x = tgl.x - TOGGLE_SIZE.ppis / 2;
								int y = tgl.y - TOGGLE_SIZE.ppis / 2;
								gc.fillOval(x, y, TOGGLE_SIZE.ppis, TOGGLE_SIZE.ppis);
								gc.drawOval(x, y, TOGGLE_SIZE.ppis, TOGGLE_SIZE.ppis);
								break;
							case Toggle.OBLIQUE_SQUARE:
								int pL = tgl.x - TOGGLE_SIZE.ppis / 2 - 1;
								int pT = tgl.y - TOGGLE_SIZE.ppis / 2 - 1;
								int pR = tgl.x + TOGGLE_SIZE.ppis / 2 + 1;
								int pB = tgl.y + TOGGLE_SIZE.ppis / 2 + 1;
								gc.fillPolygon([pL, tgl.y, tgl.x, pT, pR, tgl.y, tgl.x, pB]);
								gc.drawPolygon([pL, tgl.y, tgl.x, pT, pR, tgl.y, tgl.x, pB]);
								break;
							case Toggle.CROSS:
								int pL = tgl.x - TOGGLE_SIZE.ppis / 2 - 2;
								int pT = tgl.y - TOGGLE_SIZE.ppis / 2 - 2;
								int pR = tgl.x + TOGGLE_SIZE.ppis / 2 + 2;
								int pB = tgl.y + TOGGLE_SIZE.ppis / 2 + 2;
								int[] cpoly = [
									pL, tgl.y - 1,
									tgl.x - 1, tgl.y - 1,
									tgl.x - 1, pT,
									tgl.x + 1, pT,
									tgl.x + 1, tgl.y - 1,
									pR, tgl.y - 1,
									pR, tgl.y + 1,
									tgl.x + 1, tgl.y + 1,
									tgl.x + 1, pB,
									tgl.x - 1, pB,
									tgl.x - 1, tgl.y + 1,
									pL, tgl.y + 1,
								];
								gc.fillPolygon(cpoly);
								gc.drawPolygon(cpoly);
								break;
							case Toggle.NOTHING:
								break;
							}
						}
					}
				}
			}
		});
	}
	private class SpnListener : Listener {
		private int _index;
		this(int index) { _index = index; }
		override void handleEvent(Event e) { mixin(S_TRACE);
			foreach (h; _modHandler) { mixin(S_TRACE);
				h(_index, (cast(Spinner)e.widget).getSelection());
			}
		}
	}
	/*
	Params:
	step_c = パラメータのポイント数。
	names = 各パラメータの名称。
	min = パラメータの最低値。例えばstep_c = 11でmin = -5の場合、値の範囲は-5～+5となる。
	      指定しなかった場合は0。
	*/
	void setRadar(uint step_c, string[] names, int min = 0) { mixin(S_TRACE);
		foreach (comp; _comps) { mixin(S_TRACE);
			comp.dispose();
		}
		_borderlines.length = 0;
		_names = names;
		_step_c = step_c;
		_param_c = names.length;
		_min = min;

		_spns.length = _param_c;
		_comps.length = _param_c;
		_lbls.length = _param_c;
		foreach (i, ref comp; _comps) { mixin(S_TRACE);
			comp = new Composite(this, SWT.NONE);
			comp.setCapture(false);
			auto gl = normalGridLayout(1, true);
			gl.marginWidth = 0;
			gl.marginHeight = 0;
			gl.verticalSpacing = 2.ppis;
			comp.setLayout(gl);
			auto lbl = new Label(comp, SWT.CENTER | SWT.EMBEDDED);
			lbl.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			lbl.setText(names[i]);
			lbl.setForeground(getForeground());
			lbl.setFont(getFont());
			lbl.setCapture(false);
			Control spn;
			if (_readOnly) { mixin(S_TRACE);
				auto sspn = new Label(comp, SWT.BORDER | SWT.CENTER | SWT.EMBEDDED);
				sspn.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				sspn.setData(new Integer(min));
				spn = sspn;
			} else { mixin(S_TRACE);
				auto sspn = new Spinner(comp, SWT.BORDER);
				sspn.addListener(SWT.Modify, _mod_redraw);
				sspn.setMinimum(min);
				sspn.setMaximum(step_c - 1 + min);
				sspn.setSelection(min);
				sspn.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_CENTER));
				sspn.addListener(SWT.Selection, new SpnListener(cast(int)i));
				spn = sspn;
			}
			_lbls[i] = lbl;
			_spns[i] = spn;
		}
		calcMaxSize();

		_tgls.length = _param_c;
		foreach (ref ts; _tgls) { mixin(S_TRACE);
			ts.length = step_c;
			foreach (ref t; ts) { mixin(S_TRACE);
				t = new Point(0, 0);
			}
		}
		// _ovalsと_polysの初期化のために一旦反転する
		_oval = !_oval;
		oval = !_oval;

		_mod = true;
		resizeImpl();
	}
	private bool checkCursor(int x, int y) { mixin(S_TRACE);
		assert (!_readOnly);
		foreach (i, tgls; _tgls) { mixin(S_TRACE);
			auto tgl = tgls[getValue(i) - _min];
			int tx = tgl.x - TOGGLE_CATCH_SIZE.ppis / 2;
			int ty = tgl.y - TOGGLE_CATCH_SIZE.ppis / 2;
			scope rect = new Rectangle(tx, ty, TOGGLE_CATCH_SIZE.ppis, TOGGLE_CATCH_SIZE.ppis);
			if (rect.contains(x, y)) { mixin(S_TRACE);
				setCursor(Display.getCurrent().getSystemCursor(SWT.CURSOR_CROSS));
				return true;
			}
		}
		setCursor(null);
		return false;
	}
	/// カーソルの位置にあるトグルを取得。被る場合はより近い方を優先する。
	private ptrdiff_t cursorFromPos(int x, int y) { mixin(S_TRACE);
		assert (!_readOnly);
		int minDist = int.max;
		ptrdiff_t index = -1;
		foreach (i, tgls; _tgls) { mixin(S_TRACE);
			auto tgl = tgls[getValue(i) - _min];
			int tx = tgl.x - TOGGLE_CATCH_SIZE.ppis / 2;
			int ty = tgl.y - TOGGLE_CATCH_SIZE.ppis / 2;
			scope rect = new Rectangle(tx, ty, TOGGLE_CATCH_SIZE.ppis, TOGGLE_CATCH_SIZE.ppis);
			if (rect.contains(x, y)) { mixin(S_TRACE);
				int dist = abs(tgl.x - x) + abs(tgl.y - y);
				if (dist < minDist) { mixin(S_TRACE);
					minDist = dist;
					index = i;
				}
			}
		}
		return index;
	}
	private static uint figure(int n, int minusMarkLen = 1, int h = 10) { mixin(S_TRACE);
		if (n == 0) return 1;
		int n_ = abs(n);
		int r = 0;
		int t = 1;
		while (n_ >= t) { mixin(S_TRACE);
			t *= h;
			r++;
		}
		if (n < 0) r += minusMarkLen;
		return r;
	} unittest { mixin(S_TRACE);
		debug mixin(UTPerf);
		assert (figure(100, 1, 10) == 3);
		assert (figure(99, 1, 10) == 2);
		assert (figure(123, 1, 10) == 3);
		assert (figure(0x0f, 1, 16) == 1);
		assert (figure(-123, 1, 10) == 4);
		assert (figure(-5555, 2, 10) == 6);
	}
	private void calcMaxSize() { mixin(S_TRACE);
		_maxSize = new Point(0, 0);
		int max = _step_c - 1 + _min;
		bool ml = figure(_min) > figure(max);
		int v = ml ? _min : max;
		foreach (i, comp; _comps) { mixin(S_TRACE);
			int old;
			if (_readOnly) { mixin(S_TRACE);
				old = (cast(Integer)_spns[i].getData()).intValue();
				auto sspn = cast(Label)_spns[i];
				sspn.setText(to!(string)(v));
			} else { mixin(S_TRACE);
				auto sspn = (cast(Spinner)_spns[i]);
				old = sspn.getMaximum();
				if (v < 0) { mixin(S_TRACE);
					// Spinner#computeSize()で'-'を無視してくれるので
					sspn.setMaximum(abs(v) * 10);
				} else { mixin(S_TRACE);
					sspn.setMaximum(abs(v));
				}
			}
			scope s = comp.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			if (_readOnly) { mixin(S_TRACE);
				(cast(Label)_spns[i]).setText(to!(string)(old));
			} else { mixin(S_TRACE);
				(cast(Spinner)_spns[i]).setMaximum(old);
			}
			if (s.x > _maxSize.x) _maxSize.x = s.x;
			if (s.y > _maxSize.y) _maxSize.y = s.y;
		}
	}
	private static immutable MAX_GAP = 1.5;
	private static immutable MAX_GAP_3H = 0.8;
	private void resizeImpl() { mixin(S_TRACE);
		if (!_mod) return;
		_mod = false;
		scope client = getClientArea();
		double tgs_d = TOGGLE_SIZE.ppis / 2.0;

		if (SWT.DEFAULT == _ovalW && SWT.DEFAULT == _ovalH && 3 == _param_c && !_oval) { mixin(S_TRACE);
			// 3点の場合は最初に頂点の位置を固定する
			double x1, y1, x2, y2, x3, y3;
			int w = client.width;
			int h = client.height;

			// 縦横比を適正にする
			if (h * MAX_GAP < w) { mixin(S_TRACE);
				w = cast(int)(h * MAX_GAP);
			}
			if (w * MAX_GAP_3H < h) { mixin(S_TRACE);
				h = cast(int)(w * MAX_GAP_3H);
			}
			int xs = (client.width - w) / 2;
			int ys = (client.height - h) / 2;

			if (_side) { mixin(S_TRACE);
				x1 = _maxSize.x / 2.0;
				y1 = _maxSize.y / 2.0;
				x2 = w - (_maxSize.x / 2.0);
				y2 = _maxSize.y / 2.0;
				x3 = w / 2.0;
				y3 = h - (_maxSize.y / 2.0);
			} else { mixin(S_TRACE);
				x1 = _maxSize.x / 2.0;
				y1 = h - (_maxSize.y / 2.0);
				x2 = w - (_maxSize.x / 2.0);
				y2 = h - (_maxSize.y / 2.0);
				x3 = w / 2.0;
				y3 = _maxSize.y / 2.0;
			}
			double x1sq = x1 * x1;
			double y1sq = y1 * y1;
			double x2sq = x2 * x2;
			double y2sq = y2 * y2;
			double x3sq = x3 * x3;
			double y3sq = y3 * y3;

			double cx = (x1 + x2 + x3) / 3.0;
			double cy = (y1 + y2 + y3) / 3.0;
			double r1 = atan2(y1 - cy, x1 - cx);
			double r2 = atan2(y2 - cy, x2 - cx);
			double r3 = atan2(y3 - cy, x3 - cx);

			// LabelとSpinnerの位置。
			_comps[0].setBounds(xs + cast(int)(x1 - _maxSize.x / 2), ys + cast(int)(y1 - _maxSize.y / 2), _maxSize.x, _maxSize.y);
			_comps[1].setBounds(xs + cast(int)(x2 - _maxSize.x / 2), ys + cast(int)(y2 - _maxSize.y / 2), _maxSize.x, _maxSize.y);
			_comps[2].setBounds(xs + cast(int)(x3 - _maxSize.x / 2), ys + cast(int)(y3 - _maxSize.y / 2), _maxSize.x, _maxSize.y);

			double dis = TOGGLE_SIZE.ppis + MARGIN.ppis + ((_maxSize.x + _maxSize.y) / 2) / 2;
			x1 -= dis * cos(r1);
			y1 -= dis * sin(r1);
			x2 -= dis * cos(r2);
			y2 -= dis * sin(r2);
			x3 -= dis * cos(r3);
			y3 -= dis * sin(r3);
			double x1d = (cx - x1) / _step_c;
			double y1d = (cy - y1) / _step_c;
			double x2d = (cx - x2) / _step_c;
			double y2d = (cy - y2) / _step_c;
			double x3d = (cx - x3) / _step_c;
			double y3d = (cy - y3) / _step_c;

			// レーダーの各座標位置
			foreach (s; 0 .. _step_c) { mixin(S_TRACE);
				int x1i = cast(int)(x1 + x1d * s);
				int y1i = cast(int)(y1 + y1d * s);
				int x2i = cast(int)(x2 + x2d * s);
				int y2i = cast(int)(y2 + y2d * s);
				int x3i = cast(int)(x3 + x3d * s);
				int y3i = cast(int)(y3 + y3d * s);
				_polys[s][0 * 2] = xs + x1i;
				_polys[s][0 * 2 + 1] = ys + y1i;
				_polys[s][1 * 2] = xs + x2i;
				_polys[s][1 * 2 + 1] = ys + y2i;
				_polys[s][2 * 2] = xs + x3i;
				_polys[s][2 * 2 + 1] = ys + y3i;
				foreach (i; 0 .. _param_c) { mixin(S_TRACE);
					auto t = _tgls[i][$ - 1 - s];
					t.x = _polys[s][i * 2];
					t.y = _polys[s][i * 2 + 1];
				}
			}
			redraw();
			return;
		}
		int ovalW = _ovalW;
		int ovalH = _ovalH;
		if (SWT.DEFAULT == _ovalW || SWT.DEFAULT == _ovalH) { mixin(S_TRACE);
			double ovalWr = double.max;
			double ovalHr = double.max;
			double cw = client.width;
			double ch = client.height;
			double bw = _maxSize.x;
			double bh = _maxSize.y;
			double disW = TOGGLE_SIZE.ppis + MARGIN.ppis + _maxSize.x / 2;
			double disH = TOGGLE_SIZE.ppis + MARGIN.ppis + _maxSize.y / 2;
			foreach (i; 0 .. _param_c) { mixin(S_TRACE);
				// 角度(°)
				int r = cast(int)(((PI * 2.0 * nPos(i) / _param_c)) * 180 / PI); // rad -> °
				r += 360;
				r %= 360;
				double cosR = .cos(r * PI / 180);
				double sinR = r == 180 ? 0.0 : .sin(r * PI / 180);
				double disBaseX, disBaseY;
				if (r < 90) { mixin(S_TRACE);
					disBaseX = +(cw - bw);
					disBaseY = +(ch - bh);
				} else if (r < 180) { mixin(S_TRACE);
					disBaseX = -(cw - bw);
					disBaseY = +(ch - bh);
				} else if (r < 270) { mixin(S_TRACE);
					disBaseX = -(cw - bw);
					disBaseY = -(ch - bh);
				} else if (r < 360) { mixin(S_TRACE);
					disBaseX = +(cw - bw);
					disBaseY = -(ch - bh);
				} else assert (0);
				// 第一象限の場合
				// 0(左端) = (ovalW + disW) * cos(r) + (cw / 2) + (bw / 2)
				// 0(上端) = (ovalH + disH) * sin(r) + (ch / 2) + (bh / 2)
				if (!cosR.isClose(0.0)) ovalWr = .min(ovalWr, disBaseX / (cosR * 2) - disW);
				if (!sinR.isClose(0.0)) ovalHr = .min(ovalHr, disBaseY / (sinR * 2) - disH);
			}
			if (SWT.DEFAULT == _ovalW) ovalW = .max(0, cast(int)(ovalWr * 2));
			if (SWT.DEFAULT == _ovalH) ovalH = .max(0, cast(int)(ovalHr * 2));
		}
		if (SWT.DEFAULT == _ovalW && SWT.DEFAULT == _ovalH) { mixin(S_TRACE);
			// 縦横比を1:1.5以内にする
			if (.min(ovalW, ovalH) * MAX_GAP < .max(ovalW, ovalH)) { mixin(S_TRACE);
				if (ovalW < ovalH) { mixin(S_TRACE);
					ovalH = cast(int)(ovalW * MAX_GAP);
				} else { mixin(S_TRACE);
					ovalW = cast(int)(ovalH * MAX_GAP);
				}
			}
		}

		scope size = new Point
			(ovalW + TOGGLE_SIZE.ppis + MARGIN.ppis * 2 + _maxSize.x * 2,
			ovalH + TOGGLE_SIZE.ppis + MARGIN.ppis * 2 + _maxSize.y * 2);
		scope bs = computeBounds(size.x, size.y);
		double posX = (client.width - bs.width) / 2.0 - bs.x;
		double posY = (client.height - bs.height) / 2.0 - bs.y;

		auto sp = _maxSize;

		// レーダー線と値の位置。
		int oval_base_x = size.x - TOGGLE_SIZE.ppis - MARGIN.ppis * 2 - sp.x * 2;
		int oval_base_y = size.y - TOGGLE_SIZE.ppis - MARGIN.ppis * 2 - sp.y * 2;
		double oval_x = oval_base_x;
		double oval_y = oval_base_y;
		double oval_d_x = oval_x / _step_c;
		double oval_d_y = oval_y / _step_c;
		double x = tgs_d + MARGIN.ppis + sp.x + posX;
		double y = tgs_d + MARGIN.ppis + sp.y + posY;
		for (int s = 0; s < _step_c; s++) { mixin(S_TRACE);
			if (_oval) { mixin(S_TRACE);
				_ovals[s].x = cast(int)x;
				_ovals[s].y = cast(int)y;
				_ovals[s].width = cast(int)oval_x + 1;
				_ovals[s].height = cast(int)oval_y + 1;
			}
			double rw = oval_x / 2.0;
			double rh = oval_y / 2.0;
			for (int i = 0; i < _param_c; i++) { mixin(S_TRACE);
				double n = nPos(i);
				double px = x + rw + rw * cos(PI * 2.0 * n / _param_c);
				double py = y + rh + rh * sin(PI * 2.0 * n / _param_c);
				auto t = _tgls[i][$ - 1 - s];
				t.x = cast(int)px;
				t.y = cast(int)py;
				if (!_oval) { mixin(S_TRACE);
					_polys[s][i * 2] = t.x;
					_polys[s][i * 2 + 1] = t.y;
				}
			}
			if (s + 1 < _step_c) { mixin(S_TRACE);
				oval_x -= oval_d_x;
				oval_y -= oval_d_y;
				x = sp.x + MARGIN.ppis + tgs_d + (oval_base_x - oval_x) / 2.0 + posX;
				y = sp.y + MARGIN.ppis + tgs_d + (oval_base_y - oval_y) / 2.0 + posY;
			}
		}
		// LabelとSpinnerの位置。
		x = sp.x / 2.0 + posX;
		y = sp.y / 2.0 + posY;
		oval_x = size.x - sp.x;
		oval_y = size.y - sp.y;
		for (int i = 0; i < _param_c; i++) { mixin(S_TRACE);
			double n = nPos(i);
			double rw = oval_x / 2.0;
			double rh = oval_y / 2.0;
			double px = x + rw + rw * cos(PI * 2.0 * n / _param_c);
			double py = y + rh + rh * sin(PI * 2.0 * n / _param_c);
			_comps[i].setBounds
				(cast(int)rndtol(px - sp.x / 2), cast(int)rndtol(py - sp.y / 2), sp.x, sp.y);
		}
		redraw();
	}
	/// 値を設定する。
	/// Params:
	/// index = 設定箇所。
	/// value = 値。
	void setValue(size_t index, int value) { mixin(S_TRACE);
		if (_readOnly) { mixin(S_TRACE);
			(cast(Label)_spns[index]).setText(to!(string)(value));
			_spns[index].setData(new Integer(value));
		} else { mixin(S_TRACE);
			(cast(Spinner)_spns[index]).setSelection(value);
		}
		redraw();
	}
	/// 全ての値を設定する。
	/// Params:
	/// values = 値群。
	void setValues(int[] value) { mixin(S_TRACE);
		foreach (i, spn; _spns) { mixin(S_TRACE);
			if (_readOnly) { mixin(S_TRACE);
				(cast(Label)spn).setText(to!(string)(value[i]));
				spn.setData(new Integer(value[i]));
			} else { mixin(S_TRACE);
				(cast(Spinner)spn).setSelection(value[i]);
			}
		}
		redraw();
	}
	/// 値を返す。
	/// Params:
	/// index = 取得箇所。
	/// Returns: 値。
	int getValue(size_t index) { mixin(S_TRACE);
		if (_readOnly) { mixin(S_TRACE);
			return (cast(Integer)_spns[index].getData()).intValue();
		} else { mixin(S_TRACE);
			return (cast(Spinner)_spns[index]).getSelection();
		}
	}
	/// 全ての値を返す。
	/// Returns: 全ての値。
	int[] getValues() { mixin(S_TRACE);
		int[] vals;
		vals.length = _spns.length;
		foreach (i, ref v; vals) { mixin(S_TRACE);
			v = getValue(i);
		}
		return vals;
	}
	/// 全てのパラメータ名。
	@property
	string[] names() { mixin(S_TRACE);
		return _names;
	}
	/// パラメータ数。
	@property
	size_t paramCount() { mixin(S_TRACE);
		return _param_c;
	}
	/// 値の範囲。
	@property
	int step() { mixin(S_TRACE);
		return _step_c;
	}
	/// 値の最小値。
	@property
	int minimum() { mixin(S_TRACE);
		return _min;
	}
	/// レーダー線を何ポイントおきに表示するかを設定する。
	/// 初期値は1。
	/// Params:
	/// step = ポイント数。
	@property
	void lineStep(uint step) { mixin(S_TRACE);
		_ovalStep = step;
		redraw();
	}
	/// ポイント数。
	@property
	uint lineStep() { mixin(S_TRACE);
		return _ovalStep;
	}
	/// 描画時のアンチエイリアス設定。
	/// 初期値はSWT.DEFAULT。
	/// Params:
	/// antialias = SWT.ONまたはSWT.OFFまたはSWT.DEFAULT。
	@property
	void antialias(int antialias) { mixin(S_TRACE);
		_antialias = antialias;
		redraw();
	}
	/// アンチエイリアス設定。DWT.ONまたはSWT.OFFまたはSWT.DEFAULT。
	@property
	int antialias() { mixin(S_TRACE);
		return _antialias;
	}
	/// 各パラメータの配置モード。
	/// trueなら最初のパラメータが上辺の中央に寄る。falseなら左上の角に寄る。
	/// いずれも時計回りに配置される。
	/// 初期値はtrue。
	/// Params:
	/// sideMode = 配置モード。
	@property
	void sideMode(bool sideMode) { mixin(S_TRACE);
		if (_side != sideMode) { mixin(S_TRACE);
			_side = sideMode;
			_mod = true;
			resizeImpl();
		}
	}
	/// 配置モード。
	@property
	bool sideMode() { mixin(S_TRACE);
		return _side;
	}
	/// レーダーの表示形式を設定する。
	/// Params:
	/// oval = trueなら円、falseなら多角形。
	@property
	void oval(bool oval) { mixin(S_TRACE);
		if (_oval != oval) { mixin(S_TRACE);
			_oval = oval;
			if (oval) { mixin(S_TRACE);
				_ovals.length = _step_c;
				_polys.length = 0;
				foreach (ref o; _ovals) { mixin(S_TRACE);
					o = new Rectangle(0, 0, 0, 0);
				}
			} else { mixin(S_TRACE);
				_ovals.length = 0;
				_polys.length = _step_c;
				foreach (ref p; _polys) { mixin(S_TRACE);
					p.length = _param_c * 2;
				}
			}
			_mod = true;
			resizeImpl();
		}
	}
	/// 表示形式。
	@property
	bool oval() { mixin(S_TRACE);
		return _oval;
	}
	private bool isBorderline(int value) { mixin(S_TRACE);
		foreach (line; _borderlines) { mixin(S_TRACE);
			if (line == value) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	/// 強調表示する値を設定する。
	/// Params:
	/// lines = 強調表示する値の配列。
	@property
	void borderlines(int[] lines) { mixin(S_TRACE);
		_borderlines = lines;
		redraw();
	}
	/// 強調表示する値の配列。
	@property
	int[] borderlines() { mixin(S_TRACE);
		return _borderlines;
	}
	/// 値を変更するトグルのスタイル。
	/// 初期値はOBLIQUE_SQUARE。
	/// Params:
	/// style = スタイル。
	@property
	void toggleStyle(Toggle style) { mixin(S_TRACE);
		_tstyle = style;
		redraw();
	}
	/// スタイル。
	@property
	Toggle toggleStyle() { mixin(S_TRACE);
		return _tstyle;
	}
	private double nPos(size_t i) { mixin(S_TRACE);
		double r;
		if (_side) { mixin(S_TRACE);
			r = i - _param_c / 4.0 - 0.5;
		} else { mixin(S_TRACE);
			r = i - _param_c / 4.0;
		}
		return r;
	}
	private Rectangle computeBounds(int width, int height) { mixin(S_TRACE);
		int minL = int.max;
		int minT = int.max;
		int maxR = int.min;
		int maxB = int.min;
		auto sp = _maxSize;
		double x = sp.x / 2.0;
		double y = sp.y / 2.0;
		double oval_x = width - sp.x;
		double oval_y = height - sp.y;
		for (int i = 0; i < _param_c; i++) { mixin(S_TRACE);
			double n = nPos(i);
			double rw = oval_x / 2.0;
			double rh = oval_y / 2.0;
			double px = x + rw + rw * cos(PI * 2.0 * n / _param_c);
			double py = y + rh + rh * sin(PI * 2.0 * n / _param_c);
			int cl = cast(int)px - sp.x / 2;
			int ct = cast(int)py - sp.y / 2;
			int cr = cl + sp.x;
			int cb = ct + sp.y;
			if (cl < minL) minL = cl;
			if (ct < minT) minT = ct;
			if (cr > maxR) maxR = cr;
			if (cb > maxB) maxB = cb;
		}
		int cx, cy, cwidth, cheight;
		if (_oval) { mixin(S_TRACE);
			// 5 = (外周円の幅 = 2) * 2 + 1
			int oval_w = width - TOGGLE_SIZE.ppis - MARGIN.ppis * 2 - sp.x * 2 + 5;
			if (minL == 0) { mixin(S_TRACE);
				oval_w += MARGIN.ppis + sp.x;
			} else if (maxR == width) { mixin(S_TRACE);
				oval_w += MARGIN.ppis + sp.x;
				if (maxR - minL < oval_w) minL += maxR - minL - oval_w;
			} else { mixin(S_TRACE);
				if (maxR - minL < oval_w) minL = MARGIN.ppis + sp.x;
			}
			int oval_h = height - TOGGLE_SIZE.ppis - MARGIN.ppis * 2 - sp.y * 2 + 5;
			if (minT == 0) { mixin(S_TRACE);
				oval_h += MARGIN.ppis + sp.y;
			} else if (maxB == height) { mixin(S_TRACE);
				oval_h += MARGIN.ppis + sp.y;
				if (maxB - minT < oval_h) minT += maxB - minT - oval_h;
			} else { mixin(S_TRACE);
				if (maxB - minT < oval_h) minT = MARGIN.ppis + sp.y;
			}
			cwidth = maxR - minL > oval_w ? maxR - minL : oval_w;
			cheight = maxB - minT > oval_h ? maxB - minT : oval_h;
		} else { mixin(S_TRACE);
			cwidth = maxR - minL;
			cheight = maxB - minT;
		}
		cx = minL;
		cy = minT;
		cx -= getBorderWidth();
		cy -= getBorderWidth();
		cwidth += getBorderWidth() * 2;
		cheight += getBorderWidth() * 2;
		return new Rectangle(cx, cy, cwidth, cheight);
	}
	/// 円のサイズを設定する。
	/// 初期値はポイント数 * 10。
	/// Params:
	/// width = 円の幅。
	/// height = 円の高さ。
	void setRadarSize(int width, int height) { mixin(S_TRACE);
		if (_ovalW != width || _ovalH != height) { mixin(S_TRACE);
			_ovalW = width;
			_ovalH = height;
			_mod = true;
			resizeImpl();
		}
	}
	/// 円のサイズ。
	Point getRadarSize() { mixin(S_TRACE);
		return new Point(_ovalW, _ovalH);
	}
	/// 円の描画色を設定する。
	/// Params:
	/// fore = 前景色。初期値はSWT.COLOR_LIST_FOREGROUND。
	/// back = 背景色。初期値はSWT.COLOR_LIST_BACKGROUND。
	void setRadarColor(Color fore, Color back) { mixin(S_TRACE);
		_ovalFore = fore;
		_ovalBack = back;
		redraw();
	}
	/// 円の前景色。
	@property
	Color radarForeground() { mixin(S_TRACE);
		return _ovalFore;
	}
	/// 円の背景色。
	@property
	Color radarBackground() { mixin(S_TRACE);
		return _ovalBack;
	}
	/// 各点を結ぶ領域の不透明度(0x00～0xFF)を設定する。
	/// 初期値は0x9F。
	/// Params:
	/// alpha = アルファ値。
	@property
	void alpha(int alpha) { mixin(S_TRACE);
		_alpha = alpha;
		redraw();
	}
	/// アルファ値。
	@property
	int alpha() { mixin(S_TRACE);
		return _alpha;
	}
	void addModifyHandler(void delegate(int index, int value) handler) { mixin(S_TRACE);
		_modHandler ~= handler;
	}
	override {
		Point computeSize(int wHint, int hHint) { mixin(S_TRACE);
			return computeSize(wHint, hHint, false);
		}
		Point computeSize(int wHint, int hHint, bool changed) { mixin(S_TRACE);
			int x, y;
			if (wHint != SWT.DEFAULT && hHint != SWT.DEFAULT) { mixin(S_TRACE);
				return new Point(wHint, hHint);
			} else if (wHint == SWT.DEFAULT && hHint != SWT.DEFAULT) { mixin(S_TRACE);
				return new Point(hHint, hHint);
			} else if (wHint != SWT.DEFAULT && hHint == SWT.DEFAULT) { mixin(S_TRACE);
				return new Point(wHint, wHint);
			} else { mixin(S_TRACE);
				assert (wHint == SWT.DEFAULT && hHint == SWT.DEFAULT);
				if (_names.length == 0) { mixin(S_TRACE);
					int w = _ovalW != SWT.DEFAULT ? _ovalW : 0;
					int h = _ovalH != SWT.DEFAULT ? _ovalH : 0;
					return new Point(w, h);
				}
				int w = _ovalW + TOGGLE_SIZE.ppis + MARGIN.ppis * 2 + _maxSize.x * 2;
				int h = _ovalH + TOGGLE_SIZE.ppis + MARGIN.ppis * 2 + _maxSize.y * 2;
				scope b = computeBounds(w, h);
				return new Point(b.width, b.height);
			}
		}
		void setFont(Font font) { mixin(S_TRACE);
			if (getFont() != font) { mixin(S_TRACE);
				super.setFont(font);
				foreach (lbl; _lbls) { mixin(S_TRACE);
					lbl.setFont(font);
				}
				calcMaxSize();
				_mod = true;
				resizeImpl();
			}
		}
		void setForeground(Color color) { mixin(S_TRACE);
			super.setForeground(color);
			foreach (lbl; _lbls) { mixin(S_TRACE);
				lbl.setForeground(color);
			}
		}
	}
}

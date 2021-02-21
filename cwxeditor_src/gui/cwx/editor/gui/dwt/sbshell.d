
module cwx.editor.gui.dwt.sbshell;

import cwx.perf;
import cwx.sjis;

import org.eclipse.swt.all;

import std.string;

version (Windows) {
	import std.stdio;
	import std.utf;
	import std.windows.charset;

	import org.eclipse.swt.internal.win32.OS;
	import org.eclipse.swt.internal.win32.WINTYPES;
	extern (Windows) {
		HWND CreateStatusWindowW(LONG, LPCWSTR, HWND, UINT);
	}
} else {
	import cwx.editor.gui.dwt.dutils : normalGridLayout;
}

/// ステータスバーつきのShell。
class SBShell {
	private Shell _shl;
	private Composite _contentPane;
	this (Shell parent, int style) { mixin(S_TRACE);
		_shl = new Shell(parent, style);
		scope (failure) _shl.dispose();
		initStatusBar();
	}
	@property
	Shell shell() { return _shl; }
	@property
	Composite contentPane() { return _contentPane; }

	version (Windows) {
		private HWND _hsbar = INVALID_HANDLE_VALUE;
		private void initStatusBar() { mixin(S_TRACE);
			OS.InitCommonControls();
			_hsbar = CreateStatusWindowW
				(OS.WS_CHILD | OS.WS_VISIBLE | CCS_BOTTOM | SBARS_SIZEGRIP,
				toUTFz!(wchar*)(""), cast(HANDLE) _shl.handle, 1);
			if (_hsbar == INVALID_HANDLE_VALUE) { mixin(S_TRACE);
				throw new Exception("CreateStatusWindowW()");
			}
			_shl.addDisposeListener(new DL);
			_shl.addControlListener(new CL);

			RECT rect;
			OS.GetWindowRect(_hsbar, &rect);
			_shl.setLayout(new FormLayout);
			_contentPane = new Composite(_shl, SWT.NONE);
			auto fd = new FormData;
			fd.top = new FormAttachment(0, 0);
			fd.right = new FormAttachment(100, 0);
			fd.bottom = new FormAttachment(100, rect.top - rect.bottom);
			fd.left = new FormAttachment(0, 0);
			_contentPane.setLayoutData(fd);
		}
		private class DL : DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				if (_hsbar == INVALID_HANDLE_VALUE) return;
				OS.CloseHandle(_hsbar);
			}
		}
		private class CL : ControlAdapter {
			override void controlResized(ControlEvent e) { mixin(S_TRACE);
				if (_hsbar == INVALID_HANDLE_VALUE) return;
				if (_shl.getMinimized()) return;
				auto p = _shl.getSize();
				auto s = (p.y << 16) | p.x;
				if (_shl.getMaximized()) { mixin(S_TRACE);
					OS.SendMessageW(_hsbar, OS.WM_SIZE, OS.SIZE_MAXIMIZED, s);
				} else { mixin(S_TRACE);
					OS.SendMessageW(_hsbar, OS.WM_SIZE, OS.SIZE_RESTORED, s);
				}
			}
		}
		@property
		void statusLine(string text) { mixin(S_TRACE);
			if (_hsbar == INVALID_HANDLE_VALUE) return;
			OS.SendMessageW(_hsbar, SB_SETTEXTW, 0, cast(.LPARAM).toUTFz!(wchar*)(text));
		}
	} else {
		private Label _sbar;
		private void initStatusBar() { mixin(S_TRACE);
			auto gl = normalGridLayout(1, true);
			gl.marginWidth = 0;
			gl.marginHeight = 0;
			gl.verticalSpacing = 0;
			gl.horizontalSpacing = 0;
			_shl.setLayout(gl);
			_contentPane = new Composite(_shl, SWT.NONE);
			_contentPane.setLayoutData(new GridData(GridData.FILL_BOTH));
			_sbar = new Label(_shl, SWT.NONE);
			_sbar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		@property
		void statusLine(string text) { mixin(S_TRACE);
			_sbar.setText(std.string.replace(text, "&", "&&"));
		}
	}
}

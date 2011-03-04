
module cwx.editor.gui.dwt.sbshell;

import cwx.sjis;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;

version (Windows) {
	import std.stdio;
	import std.string;
	import std.utf;
	import std.windows.charset;

	import org.eclipse.swt.widgets.Display;
	import org.eclipse.swt.layout.FormLayout;
	import org.eclipse.swt.layout.FormData;
	import org.eclipse.swt.layout.FormAttachment;
	import org.eclipse.swt.graphics.Rectangle;
	import org.eclipse.swt.events.ControlEvent;
	import org.eclipse.swt.events.ControlAdapter;
	import org.eclipse.swt.events.DisposeEvent;
	import org.eclipse.swt.events.DisposeListener;
	import org.eclipse.swt.internal.win32.OS;
	import org.eclipse.swt.internal.win32.WINTYPES;
	extern (Windows) {
		HWND CreateStatusWindowW(LONG, LPCWSTR, HWND, UINT);
	}
} else {
	import org.eclipse.swt.widgets.Label;
	import org.eclipse.swt.layout.GridLayout;
	import org.eclipse.swt.layout.GridData;
}

/// ステータスバーつきのShell。
class SBShell {
	private Shell _shl;
	private Composite _contentPane;
	this (Shell parent, int style) {
		_shl = new Shell(parent, style);
		scope (failure) _shl.dispose;
		initStatusBar;
	}
	Shell shell() {return _shl;}
	Composite contentPane() {return _contentPane;}

	version (Windows) {
		private HWND _hsbar = INVALID_HANDLE_VALUE;
		private void initStatusBar() {
			OS.InitCommonControls;
			_hsbar = CreateStatusWindowW
				(OS.WS_CHILD | OS.WS_VISIBLE | CCS_BOTTOM | SBARS_SIZEGRIP,
				toUTF16z(""), cast(HANDLE) _shl.handle, 1);
			if (_hsbar == INVALID_HANDLE_VALUE) {
				throw new Exception("CreateStatusWindowW()");
			}
			_shl.addDisposeListener(new DL);
			_shl.addControlListener(new CL);

			RECT rect;
			OS.GetWindowRect(_hsbar, &rect);
			_shl.setLayout = new FormLayout;
			_contentPane = new Composite(_shl, SWT.NONE);
			auto fd = new FormData;
			fd.top = new FormAttachment(0, 0);
			fd.right = new FormAttachment(100, 0);
			fd.bottom = new FormAttachment(100, rect.top - rect.bottom);
			fd.left = new FormAttachment(0, 0);
			_contentPane.setLayoutData = fd;
		}
		private class DL : DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				if (_hsbar == INVALID_HANDLE_VALUE) return;
				OS.CloseHandle(_hsbar);
			}
		}
		private class CL : ControlAdapter {
			override void controlResized(ControlEvent e) {
				if (_hsbar == INVALID_HANDLE_VALUE) return;
				if (_shl.getMinimized) return;
				auto p = _shl.getSize;
				auto s = (p.y << 16) | p.x;
				if (_shl.getMaximized) {
					OS.SendMessage(_hsbar, OS.WM_SIZE, OS.SIZE_MAXIMIZED, s);
				} else {
					OS.SendMessage(_hsbar, OS.WM_SIZE, OS.SIZE_RESTORED, s);
				}
			}
		}
		void statusLine(string text) {
			if (_hsbar == INVALID_HANDLE_VALUE) return;
			OS.SendMessage(_hsbar, SB_SETTEXT, 0, tosjismz(text));
		}
	} else {
		private Label _sbar;
		private void initStatusBar() {
			auto gl = new GridLayout(1, true);
			gl.marginWidth = 0;
			gl.marginHeight = 0;
			gl.verticalSpacing = 0;
			gl.horizontalSpacing = 0;
			_shl.setLayout = gl;
			_contentPane = new Composite(_shl, SWT.NONE);
			_contentPane.setLayoutData = new GridData(GridData.FILL_BOTH);
			_sbar = new Label(_shl, SWT.NONE);
			_sbar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		void statusLine(string text) {
			_sbar.setText = std.string.replace(text, "&", "&&");
		}
	}
}

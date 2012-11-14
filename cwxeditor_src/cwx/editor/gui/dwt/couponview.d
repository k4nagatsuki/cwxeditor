
module cwx.editor.gui.dwt.couponview;

import cwx.utils;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.jpyimage;
import cwx.editor.gui.dwt.dmenu;

import std.algorithm;
import std.conv;
import std.math;
import std.path;
import std.file;
import std.traits;
import std.datetime;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

/// 得点付きクーポンのリスト。
class CouponView : Composite {
	private ToolBar _tools;
	private Table _list;

	this () {
	}
}

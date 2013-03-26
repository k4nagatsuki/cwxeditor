
module cwx.textholder;

import cwx.msgutils;
import cwx.path;
import cwx.usecounter;

/// メッセージやダイアログが持つテキスト。
class TextHolder : SimpleTextHolder, IPathUser, ChgPathCallback {
private:
	PathUser[] _fontusers;
public:
	/// コンストラクタ。
	this () {}
	/// コピーコンストラクタ。
	this (in TextHolder base) {
		this.text = base.text;
	}
	alias SimpleTextHolder.text text;
	@property
	override
	void text(string text) {
		if (_text != text) {
			string[] flags;
			string[] steps;
			string[] fonts;
			textUseItems(text, flags, steps, fonts);
			removeTextUseCounter();
			_fontusers = [];
			foreach (f; fonts) {
				auto u = new PathUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.path = f;
				_fontusers ~= u;
			}
			_flagusers = [];
			foreach (f; flags) {
				auto u = new FlagUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.flag = f;
				_flagusers ~= u;
			}
			_stepusers = [];
			foreach (s; steps) {
				auto u = new StepUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.step = s;
				_stepusers ~= u;
			}
			_text = text;
		}
	}

	// テキスト内で使用されているfont_X.png等のパス。
	@property
	const
	string[] fontsInText() {
		string[] r;
		foreach (u; _fontusers) {
			r ~= u.path;
		}
		return r;
	}

	/// 使用回数カウンタを設定する。
	@property
	override
	void setUseCounter(UseCounter uc) {
		foreach (u; _fontusers) {
			u.setUseCounter(uc);
		}
		super.setUseCounter(uc);
	}
	private void removeTextUseCounter() {
		if (_uc) {
			foreach (u; _fontusers) {
				u.removeUseCounter();
			}
		}
		super.removeTextUseCounter();
	}
	alias SimpleTextHolder.change change;
	void change(PathId id) {
		foreach (u; _fontusers) {
			u.change(id);
		}
	}
	/// テキスト内のfont_X.bmp・フラグ・ステップを置換する。
	void change(size_t index, PathId id) {
		_fontusers[index].change(id);
	}
	alias SimpleTextHolder.changeCallback changeCallback;
	override void changeCallback(PathId oldVal, PathId newVal) {
		_text = replTextUseFont(_text, cast(string) oldVal, cast(string) newVal);
	}
}

/// メッセージテキストの保持者。
interface ITextHolder : ISimpleTextHolder {
	/// テキスト内で使用されているfont_X.pngのパス。
	@property
	const string[] fontsInText();
	/// テキスト内のfont_X.bmpを置換する。
	void changeInText(size_t index, PathId id);
	alias ISimpleTextHolder.changeInText changeInText;
}

/// ファイル以外の特殊文字に対応したテキスト。
class SimpleTextHolder : CWXPath, IFlagUser, IStepUser, ChgFlagCallback, ChgStepCallback {
private:
	string _text;
	FlagUser[] _flagusers;
	StepUser[] _stepusers;
	UseCounter _uc;
public:
	/// コンストラクタ。
	this () {}
	/// コピーコンストラクタ。
	this (in SimpleTextHolder base) {
		this.text = base.text;
	}
	/// テキスト。
	@property
	const
	string text() {
		return _text;
	}
	/// ditto
	@property
	void text(string text) {
		if (_text != text) {
			string[] flags;
			string[] steps;
			string[] fonts;
			textUseItems(text, flags, steps, fonts);
			removeTextUseCounter();
			_flagusers = [];
			foreach (f; flags) {
				auto u = new FlagUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.flag = f;
				_flagusers ~= u;
			}
			_stepusers = [];
			foreach (s; steps) {
				auto u = new StepUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.step = s;
				_stepusers ~= u;
			}
			_text = text;
		}
	}

	// テキスト内で使用されているフラグのパス。
	@property
	const
	string[] flagsInText() {
		string[] r;
		foreach (u; _flagusers) {
			r ~= u.flag;
		}
		return r;
	}
	// テキスト内で使用されているステップのパス。
	@property
	const
	string[] stepsInText() {
		string[] r;
		foreach (u; _stepusers) {
			r ~= u.step;
		}
		return r;
	}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを設定する。
	@property
	void setUseCounter(UseCounter uc) {
		foreach (u; _flagusers) {
			u.setUseCounter(uc);
		}
		foreach (u; _stepusers) {
			u.setUseCounter(uc);
		}
		_uc = uc;
	}
	private void removeTextUseCounter() {
		if (_uc) {
			foreach (u; _flagusers) {
				u.removeUseCounter();
			}
			foreach (u; _stepusers) {
				u.removeUseCounter();
			}
		}
	}
	/// 使用回数カウンタを除去。
	void removeUseCounter() {
		removeTextUseCounter();
		_uc = null;
	}
	void change(FlagId id) {
		foreach (u; _flagusers) {
			u.change(id);
		}
	}
	void change(StepId id) {
		foreach (u; _stepusers) {
			u.change(id);
		}
	}
	/// ditto
	void change(size_t index, FlagId id) {
		_flagusers[index].change(id);
	}
	/// ditto
	void change(size_t index, StepId id) {
		_stepusers[index].change(id);
	}
	override void changeCallback(FlagId oldVal, FlagId newVal) {
		_text = replTextUseFlag(_text, cast(string) oldVal, cast(string) newVal);
	}
	override void changeCallback(StepId oldVal, StepId newVal) {
		_text = replTextUseStep(_text, cast(string) oldVal, cast(string) newVal);
	}
	/// このSimpleTextHolderの所持者。
	@property
	CWXPath owner() {return _owner;}
	private CWXPath _owner = null;
	@property
	package void owner(CWXPath owner) {_owner = owner;}
	@property
	string cwxPath(bool id) {
		if (_owner) {
			return cpjoin(_owner, "text", id);
		}
		return "";
	}
	CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		return null;
	}
	@property
	CWXPath[] cwxChilds() {return [];}
	@property
	CWXPath cwxParent() {return _owner;}
}

/// 一部特殊文字対応テキストの保持者。
interface ISimpleTextHolder {
	/// テキスト。
	@property
	const string text();
	/// ditto
	@property
	void text(string);
	/// テキスト内で使用されているフラグ・ステップのパス。
	@property
	const string[] flagsInText();
	/// ditto
	@property
	const string[] stepsInText();
	/// テキスト内のフラグ・ステップを置換する。
	void changeInText(size_t index, FlagId id);
	/// ditto
	void changeInText(size_t index, StepId id);
}

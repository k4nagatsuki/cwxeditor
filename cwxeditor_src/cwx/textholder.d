
module cwx.textholder;

import cwx.utils;
import cwx.msgutils;
import cwx.path;
import cwx.usecounter;

/// メッセージやダイアログが持つテキスト。
class TextHolder : SimpleTextHolder, ITextHolder, IPathUser, ChgPathCallback {
private:
	PathUser[] _fontusers;
	char[] _colors;
public:
	/// コンストラクタ。
	this () {}
	/// コピーコンストラクタ。
	this (in TextHolder base) { mixin(S_TRACE);
		this.text = base.text;
	}
	alias SimpleTextHolder.text text;
	@property
	override
	void text(string text) { mixin(S_TRACE);
		if (_text != text) { mixin(S_TRACE);
			string[] flags;
			string[] steps;
			string[] fonts;
			textUseItems(text, flags, steps, fonts, _colors);
			removeTextUseCounter();
			_fontusers = [];
			foreach (f; fonts) { mixin(S_TRACE);
				auto u = new PathUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.path = f;
				_fontusers ~= u;
			}
			_flagusers = [];
			foreach (f; flags) { mixin(S_TRACE);
				auto u = new FlagUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.flag = f;
				_flagusers ~= u;
			}
			_stepusers = [];
			foreach (s; steps) { mixin(S_TRACE);
				auto u = new StepUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.step = s;
				_stepusers ~= u;
			}
			_text = text;
		}
	}

	/// テキスト内で使用されているfont_X.png等のパス。
	@property
	const
	override
	string[] fontsInText() { mixin(S_TRACE);
		string[] r;
		foreach (u; _fontusers) { mixin(S_TRACE);
			r ~= u.path;
		}
		return r;
	}

	@property
	const
	override
	char[] namesInText() { mixin(S_TRACE);
		return .namesInText(text, true);
	}

	/// テキスト内で使用されている色。
	@property
	const
	const(char)[] colorsInText() { mixin(S_TRACE);
		return _colors;
	}

	/// 使用回数カウンタを設定する。
	@property
	override
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (u; _fontusers) { mixin(S_TRACE);
			u.setUseCounter(uc);
		}
		super.setUseCounter(uc);
	}
	override
	protected void removeTextUseCounter() { mixin(S_TRACE);
		if (_uc) { mixin(S_TRACE);
			foreach (u; _fontusers) { mixin(S_TRACE);
				u.removeUseCounter();
			}
		}
		super.removeTextUseCounter();
	}
	alias SimpleTextHolder.change change;
	bool change(PathId id) { mixin(S_TRACE);
		if (!(cast(string)id).isSPFontFile) return false;
		foreach (u; _fontusers) { mixin(S_TRACE);
			u.change(id);
		}
		return true;
	}
	alias SimpleTextHolder.changeInText changeInText;
	/// テキスト内のfont_X.bmp・フラグ・ステップを置換する。
	override
	void changeInText(size_t index, PathId id) { mixin(S_TRACE);
		_fontusers[index].change(id);
	}
	alias SimpleTextHolder.changeCallback changeCallback;
	override bool changeCallback(PathId oldVal, PathId newVal) { mixin(S_TRACE);
		if (!(cast(string)newVal).isSPFontFile) return false;
		_text = replTextUseFont(_text, cast(string)oldVal, cast(string)newVal);
		return true;
	}
}

/// メッセージテキストの保持者。
interface ITextHolder : ISimpleTextHolder {
	/// テキスト内で使用されているfont_X.pngのパス。
	@property
	const string[] fontsInText();
	/// テキスト内のfont_X.bmpを置換する。
	void changeInText(size_t index, PathId id);
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
	this (in SimpleTextHolder base) { mixin(S_TRACE);
		this.text = base.text;
	}
	/// テキスト。
	@property
	const
	string text() { mixin(S_TRACE);
		return _text;
	}
	/// ditto
	@property
	void text(string text) { mixin(S_TRACE);
		if (_text != text) { mixin(S_TRACE);
			string[] flags;
			string[] steps;
			string[] fonts;
			char[] colors;
			textUseItems(text, flags, steps, fonts, colors);
			removeTextUseCounter();
			_flagusers = [];
			foreach (f; flags) { mixin(S_TRACE);
				auto u = new FlagUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.flag = f;
				_flagusers ~= u;
			}
			_stepusers = [];
			foreach (s; steps) { mixin(S_TRACE);
				auto u = new StepUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.step = s;
				_stepusers ~= u;
			}
			_text = text;
		}
	}

	/// テキスト内で使用されているフラグのパス。
	@property
	const
	string[] flagsInText() { mixin(S_TRACE);
		string[] r;
		foreach (u; _flagusers) { mixin(S_TRACE);
			r ~= u.flag;
		}
		return r;
	}

	/// テキスト内で使用されているステップのパス。
	@property
	const
	string[] stepsInText() { mixin(S_TRACE);
		string[] r;
		foreach (u; _stepusers) { mixin(S_TRACE);
			r ~= u.step;
		}
		return r;
	}

	/// テキスト内で使用されている選択メンバ名などの特殊文字。
	@property
	const
	char[] namesInText() { mixin(S_TRACE);
		return .namesInText(text, false);
	}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを設定する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (u; _flagusers) { mixin(S_TRACE);
			u.setUseCounter(uc);
		}
		foreach (u; _stepusers) { mixin(S_TRACE);
			u.setUseCounter(uc);
		}
		_uc = uc;
	}
	protected void removeTextUseCounter() { mixin(S_TRACE);
		if (_uc) { mixin(S_TRACE);
			foreach (u; _flagusers) { mixin(S_TRACE);
				u.removeUseCounter();
			}
			foreach (u; _stepusers) { mixin(S_TRACE);
				u.removeUseCounter();
			}
		}
	}
	/// 使用回数カウンタを除去。
	void removeUseCounter() { mixin(S_TRACE);
		removeTextUseCounter();
		_uc = null;
	}
	bool change(FlagId id) { mixin(S_TRACE);
		foreach (u; _flagusers) { mixin(S_TRACE);
			u.change(id);
		}
		return true;
	}
	bool change(StepId id) { mixin(S_TRACE);
		foreach (u; _stepusers) { mixin(S_TRACE);
			u.change(id);
		}
		return true;
	}
	/// ditto
	void changeInText(size_t index, FlagId id) { mixin(S_TRACE);
		_flagusers[index].change(id);
	}
	/// ditto
	void changeInText(size_t index, StepId id) { mixin(S_TRACE);
		_stepusers[index].change(id);
	}
	override bool changeCallback(FlagId oldVal, FlagId newVal) { mixin(S_TRACE);
		_text = replTextUseFlag(_text, cast(string)oldVal, cast(string)newVal);
		return true;
	}
	override bool changeCallback(StepId oldVal, StepId newVal) { mixin(S_TRACE);
		_text = replTextUseStep(_text, cast(string)oldVal, cast(string)newVal);
		return true;
	}

	protected override void changed() { }

	/// このSimpleTextHolderの所持者。
	@property
	CWXPath owner() {return _owner;}
	private CWXPath _owner = null;
	@property
	package void owner(CWXPath owner) {_owner = owner;}
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			return cpjoin(_owner, "text", id);
		}
		return "";
	}
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() {return [];}
	@property
	CWXPath cwxParent() {return _owner;}
}

/// 一部特殊文字対応テキストの保持者。
interface ISimpleTextHolder : IFlagUser, IStepUser {
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

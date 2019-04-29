
module cwx.textholder;

import cwx.utils;
import cwx.msgutils;
import cwx.path;
import cwx.usecounter;

/// メッセージやダイアログが持つテキスト。
class TextHolder : SimpleTextHolder, ITextHolder, ChgPathCallback {
private:
	PathUser[] _fontusers;
	char[] _colors;
public:
	/// コンストラクタ。
	this (CWXPath owner, string cwxPathCategory = "text") { mixin(S_TRACE);
		super (owner, cwxPathCategory);
	}
	alias SimpleTextHolder.text text;
	@property
	override
	void text(string text) { mixin(S_TRACE);
		if (_text != text) { mixin(S_TRACE);
			string[] flags;
			string[] steps;
			string[] variants;
			string[] fonts;
			textUseItems(text, flags, steps, variants, fonts, _colors);
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
			_variantusers = [];
			foreach (s; variants) { mixin(S_TRACE);
				auto u = new VariantUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.variant = s;
				_variantusers ~= u;
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
		if (_changed) _changed();
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
class SimpleTextHolder : CWXPath, ISimpleTextHolder, ChgFlagCallback, ChgStepCallback, ChgVariantCallback {
private:
	string _text;
	FlagUser[] _flagusers;
	StepUser[] _stepusers;
	VariantUser[] _variantusers;
	UseCounter _uc;
	string _cwxPathCategory;
	void delegate() _changed;
public:
	/// コンストラクタ。
	this (CWXPath owner, string cwxPathCategory = "text") { mixin(S_TRACE);
		this.owner = owner;
		_cwxPathCategory = cwxPathCategory;
	}

	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		_changed = change;
	}

	@property
	const
	override
	string text() { mixin(S_TRACE);
		return _text;
	}
	@property
	override
	void text(string text) { mixin(S_TRACE);
		if (_text != text) { mixin(S_TRACE);
			string[] flags;
			string[] steps;
			string[] variants;
			string[] fonts;
			char[] colors;
			textUseItems(text, flags, steps, variants, fonts, colors);
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
			_variantusers = [];
			foreach (s; variants) { mixin(S_TRACE);
				auto u = new VariantUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.variant = s;
				_variantusers ~= u;
			}
			_text = text;
		}
	}

	@property
	const
	override
	string[] flagsInText() { mixin(S_TRACE);
		string[] r;
		foreach (u; _flagusers) { mixin(S_TRACE);
			r ~= u.flag;
		}
		return r;
	}
	@property
	const
	override
	string[] stepsInText() { mixin(S_TRACE);
		string[] r;
		foreach (u; _stepusers) { mixin(S_TRACE);
			r ~= u.step;
		}
		return r;
	}
	@property
	const
	override
	string[] variantsInText() { mixin(S_TRACE);
		string[] r;
		foreach (u; _variantusers) { mixin(S_TRACE);
			r ~= u.variant;
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
	inout
	inout(UseCounter) useCounter() { return _uc; }
	/// 使用回数カウンタを設定する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (u; _flagusers) { mixin(S_TRACE);
			u.setUseCounter(uc);
		}
		foreach (u; _stepusers) { mixin(S_TRACE);
			u.setUseCounter(uc);
		}
		foreach (u; _variantusers) { mixin(S_TRACE);
			u.setUseCounter(uc);
		}
		_uc = uc;
	}
	/// 状態変数ユーザの使用回数カウンタを除去する。
	protected void removeTextUseCounter() { mixin(S_TRACE);
		if (_uc) { mixin(S_TRACE);
			foreach (u; _flagusers) { mixin(S_TRACE);
				u.removeUseCounter();
			}
			foreach (u; _stepusers) { mixin(S_TRACE);
				u.removeUseCounter();
			}
			foreach (u; _variantusers) { mixin(S_TRACE);
				u.removeUseCounter();
			}
		}
	}
	/// 使用回数カウンタを除去。
	void removeUseCounter() { mixin(S_TRACE);
		removeTextUseCounter();
		_uc = null;
	}
	/// 個別に状態変数パスを変更する。
	void changeInText(size_t index, FlagId id) { mixin(S_TRACE);
		_flagusers[index].change(id);
	}
	/// ditto
	void changeInText(size_t index, StepId id) { mixin(S_TRACE);
		_stepusers[index].change(id);
	}
	/// ditto
	void changeInText(size_t index, VariantId id) { mixin(S_TRACE);
		_variantusers[index].change(id);
	}
	override bool changeCallback(FlagId oldVal, FlagId newVal) { mixin(S_TRACE);
		_text = replTextUseFlag(_text, cast(string)oldVal, cast(string)newVal);
		if (_changed) _changed();
		return true;
	}
	override bool changeCallback(StepId oldVal, StepId newVal) { mixin(S_TRACE);
		_text = replTextUseStep(_text, cast(string)oldVal, cast(string)newVal);
		if (_changed) _changed();
		return true;
	}
	override bool changeCallback(VariantId oldVal, VariantId newVal) { mixin(S_TRACE);
		_text = replTextUseVariant(_text, cast(string)oldVal, cast(string)newVal);
		if (_changed) _changed();
		return true;
	}

	override void changed() { }

	/// このSimpleTextHolderの所持者。
	@property
	CWXPath owner() { return _owner; }
	private CWXPath _owner = null;
	@property
	package void owner(CWXPath owner) { _owner = owner; }
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			return cpjoin(_owner, _cwxPathCategory, id);
		}
		return "";
	}
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() { return []; }
	@property
	CWXPath cwxParent() { return _owner; }
}

/// 一部特殊文字対応テキストの保持者。
interface ISimpleTextHolder {
	/// テキスト。
	@property
	const string text();
	/// ditto
	@property
	void text(string);
	/// テキスト内で使用されている状態変数のパス。
	@property
	const string[] flagsInText();
	/// ditto
	@property
	const string[] stepsInText();
	/// ditto
	@property
	const string[] variantsInText();
	/// テキスト内の状態変数パスを置換する。
	void changeInText(size_t index, FlagId id);
	/// ditto
	void changeInText(size_t index, StepId id);
	/// ditto
	void changeInText(size_t index, VariantId id);
}

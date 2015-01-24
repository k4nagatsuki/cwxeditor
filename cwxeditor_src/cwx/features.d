
module cwx.features;

import cwx.perf;
import cwx.types;

import std.typecons : Proxy;

/// クーポンのタイプ
enum CouponType {
	Normal, /// 通常。
	Hide, /// 隠蔽クーポン。
	System, /// システムクーポン。
	Dur, /// 次元クーポン。
	DurBattle, /// 戦闘中限定時限クーポン。
}

/// 性別。
alias Typedef2!(size_t, 0, "Sex") Sex;

/// 年代。
alias Typedef2!(size_t, 0, "Period") Period;

/// 素質。
alias Typedef2!(size_t, 0, "Nature") Nature;

/// 特徴。
alias Typedef2!(size_t, 0, "Makings") Makings;

/// Typedef!intでは連想配列のキーにできないので代替。
struct Typedef2(T, T init = T.init, string cookie = null) {
	T value;
	alias value this;

	nothrow
	@safe
	this (T value) {
		this.value = value;
	}

	mixin Proxy!value;

	const
	nothrow
	@safe
	hash_t toHash() {
		return value;
	}
}

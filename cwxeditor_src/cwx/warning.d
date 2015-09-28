
module cwx.warning;

import cwx.utils;
import cwx.msgutils;
import cwx.path;
import cwx.props;
import cwx.summary;
import cwx.flag;
import cwx.card;
import cwx.area;
import cwx.event;
import cwx.skin;
import cwx.background;
import cwx.types;
import cwx.features;
import cwx.imagesize;
import cwx.motion;
import cwx.sjis;

import std.path;
import std.typecons : Tuple;

/// pathの内容を調査し、警告すべき点があればメッセージ群を返す。
string[] warnings(in CProps prop, in Skin skin, in Summary summ, in CWXPath path, string targVer) { mixin(S_TRACE);
	auto wsnVer = summ ? summ.dataVersion : LATEST_VERSION;
	auto sPath = summ ? summ.scenarioPath : "";
	auto froot = summ ? summ.flagDirRoot : null;
	string[] r;

	auto psumm = cast(Summary) path;
	if (psumm) { mixin(S_TRACE);
		if (psumm.imagePath != "" && !isBinImg(psumm.imagePath) && !skin.findPath(psumm.imagePath, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(psumm.imagePath));
		}
		if (psumm.levelMin > psumm.levelMax) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorReversalLevel;
		}
		if (!psumm.area(psumm.startArea)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorStartAreaNotFound;
		}
		if (psumm.imagePath != "") { mixin(S_TRACE);
			r ~= skin.warningImage(prop, psumm.imagePath, psumm.legacy, true, targVer);
		}
	}
	auto flagDir = cast(FlagDir) path;
	if (flagDir) { mixin(S_TRACE);
		if (flagDir.parent is froot && prop.sys.isSystemVar(flagDir.name)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemVariable, flagDir.name);
		}
	}
	auto flag = cast(Flag) path;
	if (flag) { mixin(S_TRACE);
		if (flag.parent is froot && prop.sys.isSystemVar(flag.name)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemVariable, flag.name);
		}
	}
	auto step = cast(Step) path;
	if (step) { mixin(S_TRACE);
		if (step.parent is froot && prop.sys.isSystemVar(step.name)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemVariable, step.name);
		}
	}
	auto eventTree = cast(EventTree) path;
	if (eventTree) { mixin(S_TRACE);
		if (eventTree.keyCodes.length && prop.sys.convFireKeyCode(eventTree.keyCodes[0]) == "MatchingType=All") { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorKeyCodeMatchingAll;
		}
		if (eventTree.fireEveryRound && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningEveryRound;
		}
		if (eventTree.fireRound0 && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningRound0;
		}
	}
	auto casts = cast(CastCard) path;
	if (casts) { mixin(S_TRACE);
		foreach (c; casts.skills) { mixin(S_TRACE);
			if (0 != c.linkId && !(summ && summ.skill(c.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdSkillNotFound, c.linkId);
			}
		}
		foreach (c; casts.items) { mixin(S_TRACE);
			if (0 != c.linkId && !(summ && summ.item(c.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdItemNotFound, c.linkId);
			}
		}
		foreach (c; casts.beasts) { mixin(S_TRACE);
			if (0 != c.linkId && !(summ && summ.beast(c.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdBeastNotFound, c.linkId);
			}
		}
	}
	auto card = cast(Card) path;
	if (card) { mixin(S_TRACE);
		if (card.path != "" && !isBinImg(card.path) && !skin.findPath(card.path, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(card.path));
		}
		if (card.path != "") { mixin(S_TRACE);
			r ~= skin.warningImage(prop, card.path, summ ? summ.legacy : false, true, targVer);
		}
	}
	void putMotions(in Motion[] motions) { mixin(S_TRACE);
		foreach (m; motions) { mixin(S_TRACE);
			if (m.type is MType.CANCEL_ACTION && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningUnknownMotion, prop.msgs.motionName(m.type), "1.50");
			}
			if (m.type == MType.SUMMON_BEAST && !m.beast) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoBeast;
			}
			if (m.type == MType.SUMMON_BEAST && m.beast && 0 != m.beast.linkId && !(summ && summ.beast(m.beast.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdBeastNotFound, m.beast.linkId);
			}
		}
	}
	auto effCard = cast(EffectCard) path;
	if (effCard) { mixin(S_TRACE);
		putMotions(effCard.motions);
		if (effCard.soundPath1 != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, effCard.soundPath1, summ ? summ.legacy : false, targVer);
		}
		if (effCard.soundPath2 != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, effCard.soundPath2, summ ? summ.legacy : false, targVer);
		}
	}
	auto spChars = skin.spChars;
	auto checkTextRes(in string[] flags, in string[] steps, in string[] fonts, in char[] colors,
			ref bool[string] wFlags, ref bool[string] wSteps, ref bool[string] wFonts, ref bool[char] wColors) { mixin(S_TRACE);
		return .textWarnings(prop, skin, summ, targVer, flags, steps, fonts, colors, wFlags, wSteps, wFonts, wColors);
	}
	string[] checkTextRes2(in string[] flags, in string[] steps, in string[] fonts, in char[] colors) { mixin(S_TRACE);
		bool[string] wFlags;
		bool[string] wSteps;
		bool[string] wFonts;
		bool[char] wColors;
		return checkTextRes(flags, steps, fonts, colors, wFlags, wSteps, wFonts, wColors).all;
	}
	auto bi = cast(BgImage) path;
	if (bi) { mixin(S_TRACE);
		if (bi.flag != "" && !(froot && froot.findFlag(bi.flag))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, bi.flag);
		}
		if (bi.foreground) {
			if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageForeground;
			}
		}
		if (bi.cellName != "") {
			if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageCellName;
			}
		}
	}
	auto ic = cast(ImageCell) path;
	if (ic) { mixin(S_TRACE);
		if (!ic.path.length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoImage;
		}
		if (isBinImg(ic.path)) { mixin(S_TRACE);
			if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageIncluded;
			}
		} else if (ic.path.length && !skin.findPath(ic.path, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(ic.path));
		}
		if (ic.path != "") { mixin(S_TRACE);
			r ~= skin.warningImage(prop, ic.path, summ ? summ.legacy : false, true, targVer);
		}
	}
	auto tc = cast(TextCell) path;
	if (tc) { mixin(S_TRACE);
		r ~= checkTextRes2(tc.flagsInText, tc.stepsInText, [], []);
		if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningTextCell;
		}
	}
	auto cc = cast(ColorCell) path;
	if (cc) { mixin(S_TRACE);
		if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningColorCell;
		}
	}
	auto pc = cast(PCCell) path;
	if (pc) { mixin(S_TRACE);
		if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningPCCell;
		}
	}
	auto btl = cast(Battle) path;
	if (btl) { mixin(S_TRACE);
		if (btl.music != "") { mixin(S_TRACE);
			r ~= skin.warningBGM(prop, btl.music, summ ? summ.legacy : false, targVer);
		}
	}
	auto mc = cast(MenuCard) path;
	if (mc) { mixin(S_TRACE);
		if (mc.path != "" && !isBinImg(mc.path) && !skin.findPath(mc.path, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(mc.path));
		}
		if (mc.path != "") {
			if (isBinImg(mc.path)) { mixin(S_TRACE);
				auto bin =  cast(ubyte[])strToBImg(mc.path);
				auto type = imageType(bin);
				if (type != "") {
					auto img = "image".setExtension(type);
					r ~= skin.warningImage(prop, img, summ ? summ.legacy : false, true, targVer);
				}
			} else {
				r ~= skin.warningImage(prop, mc.path, summ ? summ.legacy : false, false, targVer);
			}
		}
		if (mc.flag != "" && !(froot && froot.findFlag(mc.flag))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, mc.flag);
		}
		if (0 != mc.pcNumber && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningPCNumberClassic;
		}
	}
	auto ec = cast(EnemyCard) path;
	if (ec) { mixin(S_TRACE);
		if (ec.id == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoCast;
		}
		if (ec.id != 0 && !(summ && summ.cwCast(ec.id))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorCastNotFound, ec.id);
		}
		if (ec.flag != "" && !(froot && froot.findFlag(ec.flag))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, ec.flag);
		}
	}
	auto c = cast(Content) path;
	if (c) { mixin(S_TRACE);
		if ((summ ? summ.legacy : false) && c.type == CType.WAIT && !c.next.length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorIgnoreWait;
		}
		if (c.detail.owner && c.detail.nextType != CNextType.TEXT) { mixin(S_TRACE);
			auto set = new HashSet!(string);
			foreach (cld; c.next) { mixin(S_TRACE);
				if (cld.name == "") continue;
				if (set.contains(cld.name)) { mixin(S_TRACE);
					r ~= prop.msgs.searchErrorDupNextContent;
					break;
				}
				set.add(cld.name);
			}
		}
		if (c.type == CType.TALK_DIALOG) { mixin(S_TRACE);
			if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				if (Talker.VALUED is c.talkerNC) { mixin(S_TRACE);
					r ~= prop.msgs.warningValuedTalker;
				}
			}
			if (c.dialogs.length) { mixin(S_TRACE);
				bool[string] wFlags;
				bool[string] wSteps;
				bool[string] wFonts;
				bool[char] wColors;
				foreach (i, dlg; c.dialogs) { mixin(S_TRACE);
					r ~= checkTextRes(dlg.flagsInText, dlg.stepsInText, dlg.fontsInText, dlg.colorsInText,
						wFlags, wSteps, wFonts, wColors).noDup;
					if (i + 1 < c.dialogs.length && !dlg.rCoupons.length) { mixin(S_TRACE);
						// 最後以外にクーポンが設定されていない場合
						r ~= prop.msgs.searchErrorNoRCouponsDialog;
					}
				}
			}
		}
		r ~= checkTextRes2(c.flagsInText, c.stepsInText, c.fontsInText, c.colorsInText);
		bool hasStart() { mixin(S_TRACE);
			foreach (s; c.tree.starts) { mixin(S_TRACE);
				if (s.name == c.start) return true;
			}
			return false;
		}
		if (c.flag != "" && !(froot && froot.findFlag(c.flag))) { mixin(S_TRACE);
			// 代入コンテントではランダム値有効
			if (!c.type == CType.SUBSTITUTE_FLAG || prop.sys.randomValue != c.flag) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, c.flag);
			}
		}
		if (c.step != "" && !(froot && froot.findStep(c.step))) { mixin(S_TRACE);
			// 代入コンテントではランダム値有効
			if (!c.type == CType.SUBSTITUTE_STEP || prop.sys.randomValue != c.step) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorStepNotFound, c.step);
			}
		}
		if (c.type == CType.TALK_MESSAGE && c.talkerC == Talker.IMAGE
				&& c.cardPath != "" && !skin.findPath(c.cardPath, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(c.cardPath));
		}
		if (c.bgmPath != "" && !skin.findPath(c.bgmPath, skin.extBgm, skin.bgmDir, sPath).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorBGMNotFound, .encodePath(c.bgmPath));
		}
		if (c.soundPath != "" && !skin.findPath(c.soundPath, skin.extSound, skin.seDir, sPath).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSENotFound, .encodePath(c.soundPath));
		}
		if (c.area != 0 && !(summ && summ.area(c.area))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorAreaNotFound, c.area);
		}
		if (c.battle != 0 && !(summ && summ.battle(c.battle))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorBattleNotFound, c.battle);
		}
		if (c.packages != 0 && !(summ && summ.cwPackage(c.packages))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorPackageNotFound, c.packages);
		}
		if (c.casts != 0 && !(summ && summ.cwCast(c.casts))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorCastNotFound, c.casts);
		}
		if (c.item != 0 && !(summ && summ.item(c.item))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorItemNotFound, c.item);
		}
		if (c.skill != 0 && !(summ && summ.skill(c.skill))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSkillNotFound, c.skill);
		}
		if (c.beast != 0 && !(summ && summ.beast(c.beast))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorBeastNotFound, c.beast);
		}
		if (c.info != 0 && !(summ && summ.info(c.info))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorInfoNotFound, c.info);
		}
		if (c.start != "" && !hasStart()) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorStartNotFound, c.start);
		}
		putMotions(c.motions);
		if (c.flag2 != "" && !(froot && froot.findFlag(c.flag2))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, c.flag2);
		}
		if (c.step2 != "" && !(froot && froot.findStep(c.step2))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorStepNotFound, c.step2);
		}
		if (c.flag != "" && c.flag == c.flag2) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSourceIsTarget;
		}
		if (c.step != "" && c.step == c.step2) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSourceIsTarget;
		}
		if ((c.type is CType.GET_COUPON || c.type is CType.LOSE_COUPON) && prop.sys.isCouponType(c.coupon, CouponType.System)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemCoupon, c.coupon);
		}
		if (c.levelMin > c.levelMax) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorReversalLevel;
		}
		if (c.type is CType.BRANCH_ROUND) { mixin(S_TRACE);
			CWXPath cwxPath = c;
			while (cwxPath) { mixin(S_TRACE);
				if (cast(Area) cwxPath) { mixin(S_TRACE);
					r ~= prop.msgs.searchErrorBranchRoundInArea;
					break;
				}
				cwxPath = cwxPath.cwxParent();
			}
		}
		if (c.cardPath != "") { mixin(S_TRACE);
			r ~= skin.warningImage(prop, c.cardPath, summ ? summ.legacy : false, false, targVer);
		}
		if (c.bgmPath != "") { mixin(S_TRACE);
			r ~= skin.warningBGM(prop, c.bgmPath, summ ? summ.legacy : false, targVer);
		}
		if (c.soundPath != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, c.soundPath, summ ? summ.legacy : false, targVer);
		}
		uint maxNextLen(in Content c) {
			if (c.type is CType.TALK_MESSAGE) { mixin(S_TRACE);
				return c.text == "" ? prop.looks.selectionBarMax : prop.looks.selectionBarMaxWithMessage;
			} else if (c.type is CType.TALK_DIALOG) { mixin(S_TRACE);
				foreach (dlg; c.dialogs) { mixin(S_TRACE);
					if (dlg.text != "") return prop.looks.selectionBarMaxWithMessage;
				}
				return prop.looks.selectionBarMax;
			}
			return uint.max;
		}
		if (c.detail.nextType is CNextType.TEXT && maxNextLen(c) < c.next.length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningSelectionBarIsMany, c.next.length, maxNextLen(c));
		}

		if (c.talkerC is Talker.VALUED && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningValuedTalker;
		}
		if (c.status !is Status.NONE) { mixin(S_TRACE);
			if (Status.SILENCE <= c.status && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchStatusMental, prop.msgs.statusName(c.status), "1.50");
			} else if (Status.CONFUSE <= c.status && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchStatusMental, prop.msgs.statusName(c.status), "1.30");
			}
		}
		if (c.range == Range.FIELD && c.detail.use(CArg.COUPON) && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningBranchCouponAtField;
		}
		if (c.type is CType.CHECK_STEP && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.CHECK_STEP), "1.50");
		}
		if (c.type is CType.SUBSTITUTE_STEP && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.SUBSTITUTE_STEP), "1.30");
		}
		if (c.type is CType.SUBSTITUTE_FLAG && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.SUBSTITUTE_FLAG), "1.30");
		}
		if (c.type is CType.BRANCH_STEP_CMP && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_STEP_CMP), "1.30");
		}
		if (c.type is CType.BRANCH_FLAG_CMP && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_FLAG_CMP), "1.30");
		}
		if (c.type is CType.BRANCH_RANDOM_SELECT && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_RANDOM_SELECT), "1.30");
		}
		if (c.type is CType.BRANCH_KEY_CODE && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_KEY_CODE), "1.50");
		}
		if (c.type is CType.BRANCH_ROUND && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_ROUND), "1.50");
		}
	}
	return r;
}

/// 台詞・メッセージ内で使用されているデータに対する警告を返す。
/// 警告が行われたデータは引数の連想配列に格納される。
Tuple!(string[], "all", string[], "noDup") textWarnings(in CProps prop, in Skin skin, in Summary summ, string targVer,
		in string[] flags, in string[] steps, in string[] fonts, in char[] colors,
		ref bool[string] wFlags, ref bool[string] wSteps, ref bool[string] wFonts, ref bool[char] wColors) { mixin(S_TRACE);
	string[] all = [];
	string[] noDup = [];

	auto sPath = summ.scenarioPath;
	auto spChars = skin.spChars;
	auto froot = summ.flagDirRoot;

	foreach (font; fonts) { mixin(S_TRACE);
		dchar c = decodeFontPath(font);
		if (c in spChars) continue;
		bool put = false;
		if (summ.legacy && !.isSJIS1ByteChar(c)) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorSPFontIsNotSJIS1ByteChar, .tryFormat("#%s", c));
			all ~= msg;
			if (!wFonts.get(font, false)) { mixin(S_TRACE);
				noDup ~= msg;
				put = true;
			}
		}
		if (!skin.findPath(font, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorSPFontNotFound, .tryFormat("#%s", c));
			all ~= msg;
			if (!wFonts.get(font, false)) { mixin(S_TRACE);
				noDup ~= msg;
				put = true;
			}
		}
		if (put) wFonts[font] = true;
	}
	foreach (flag; flags) { mixin(S_TRACE);
		if (!(froot && froot.findFlag(flag))) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorFlagNotFound, flag);
			all ~= msg;
			if (!wFlags.get(flag, false)) { mixin(S_TRACE);
				noDup ~= msg;
				wFlags[flag] = true;
			}
		}
	}
	foreach (step; steps) { mixin(S_TRACE);
		if (!(froot && froot.findStep(step))) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorStepNotFound, step);
			all ~= msg;
			if (!wSteps.get(step, false)) { mixin(S_TRACE);
				noDup ~= msg;
				wSteps[step] = true;
			}
		}
	}
	if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
		foreach (color; colors) { mixin(S_TRACE);
			switch (std.ascii.toUpper(color)) {
			case 'O', 'P', 'L', 'D':
				auto w = .tryFormat(prop.msgs.warningTextColor, "&" ~ color, "1.50");
				all ~= w;
				if (!wColors.get(color, false)) { mixin(S_TRACE);
					noDup ~= w;
					wColors[color] = true;
				}
				break;
			default:
				break;
			}
		}
	}
	return typeof(return)(all, noDup);
}

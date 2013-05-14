
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

/// pathの内容を調査し、警告すべき点があればメッセージ群を返す。
string[] warnings(in CProps prop, in Skin skin, in Summary summ, in CWXPath path) {
	if (!summ) return [];
	auto sPath = summ.scenarioPath;
	auto froot = summ.flagDirRoot;
	string[] r;

	auto psumm = cast(Summary) path;
	if (psumm) {
		if (psumm.imagePath != "" && !isBinImg(psumm.imagePath) && !skin.findPath(psumm.imagePath, skin.extImage, skin.tableDir, sPath).length) {
			r ~= prop.msgs.searchErrorImageNotFound;
		}
		if (psumm.levelMin > psumm.levelMax) {
			r ~= prop.msgs.searchErrorReversalLevel;
		}
		if (!psumm.area(psumm.startArea)) {
			r ~= prop.msgs.searchErrorStartAreaNotFound;
		}
	}
	auto flagDir = cast(FlagDir) path;
	if (flagDir) {
		if (flagDir.parent is froot && prop.sys.isSystemVar(flagDir.name)) {
			r ~= prop.msgs.searchErrorSystemName;
		}
	}
	auto flag = cast(Flag) path;
	if (flag) {
		if (flag.parent is froot && prop.sys.isSystemVar(flag.name)) {
			r ~= prop.msgs.searchErrorSystemName;
		}
	}
	auto step = cast(Step) path;
	if (step) {
		if (step.parent is froot && prop.sys.isSystemVar(step.name)) {
			r ~= prop.msgs.searchErrorSystemName;
		}
	}
	auto eventTree = cast(EventTree) path;
	if (eventTree) {
		if (eventTree.keyCodes.length && prop.sys.convFireKeyCode(eventTree.keyCodes[0]) == "MatchingType=All") {
			r ~= prop.msgs.searchErrorKeyCodeMatchingAll;
		}
	}
	auto casts = cast(CastCard) path;
	if (casts) {
		bool err = false;
		foreach (c; casts.skills) {
			if (err) break;
			if (0 != c.linkId && !summ.skill(c.linkId)) {
				r ~= prop.msgs.searchErrorLinkIdNotFound;
				err = true;
			}
		}
		foreach (c; casts.items) {
			if (err) break;
			if (0 != c.linkId && !summ.item(c.linkId)) {
				r ~= prop.msgs.searchErrorLinkIdNotFound;
				err = true;
			}
		}
		foreach (c; casts.beasts) {
			if (err) break;
			if (0 != c.linkId && !summ.beast(c.linkId)) {
				r ~= prop.msgs.searchErrorLinkIdNotFound;
				err = true;
			}
		}
	}
	auto card = cast(Card) path;
	if (card) {
		if (card.path != "" && !isBinImg(card.path) && !skin.findPath(card.path, skin.extImage, skin.tableDir, sPath).length) {
			r ~= prop.msgs.searchErrorImageNotFound;
		}
	}
	auto spChars = skin.spChars;
	string checkTextRes(string[] fonts, string[] flags, string[] steps) {
		foreach (font; fonts) {
			dchar c = decodeFontPath(font);
			if (c in spChars) continue;
			if (!skin.findPath(font, skin.extImage, skin.tableDir, sPath).length) {
				return prop.msgs.searchErrorSPFontNotFound;
			}
		}
		foreach (flag; flags) {
			if (!froot.findFlag(flag)) {
				return prop.msgs.searchErrorFlagNotFound;
			}
		}
		foreach (step; steps) {
			if (!froot.findStep(step)) {
				return prop.msgs.searchErrorStepNotFound;
			}
		}
		return null;
	}
	auto bi = cast(BgImage) path;
	if (bi) {
		if (bi.flag != "" && !froot.findFlag(bi.flag)) {
			r ~= prop.msgs.searchErrorFlagNotFound;
		}
	}
	auto ic = cast(ImageCell) path;
	if (ic) {
		if (!ic.path.length) {
			r ~= prop.msgs.searchErrorNoImage;
		}
		if (ic.path.length && !skin.findPath(ic.path, skin.extImage, skin.tableDir, sPath).length) {
			r ~= prop.msgs.searchErrorImageNotFound;
		}
	}
	auto tc = cast(TextCell) path;
	if (tc) {
		string err = checkTextRes([], tc.flagsInText, tc.stepsInText);
		if (err) {
			r ~= err;
		}
	}
	auto mc = cast(MenuCard) path;
	if (mc) {
		if (mc.path != "" && !isBinImg(mc.path) && !skin.findPath(mc.path, skin.extImage, skin.tableDir, sPath).length) {
			r ~= prop.msgs.searchErrorImageNotFound;
		}
		if (mc.flag != "" && !froot.findFlag(mc.flag)) {
			r ~= prop.msgs.searchErrorFlagNotFound;
		}
		if (0 != mc.pcNumber && !summ.legacy) {
			r ~= prop.msgs.searchErrorPCNumber;
		}
	}
	auto ec = cast(EnemyCard) path;
	if (ec) {
		if (ec.id == 0) {
			r ~= prop.msgs.searchErrorNoCast;
		}
		if (ec.id != 0 && !summ.cwCast(ec.id)) {
			r ~= prop.msgs.searchErrorCastNotFound;
		}
		if (ec.flag != "" && !froot.findFlag(ec.flag)) {
			r ~= prop.msgs.searchErrorFlagNotFound;
		}
	}
	auto c = cast(Content) path;
	if (c) {
		if (summ.legacy && c.type == CType.WAIT && !c.next.length) {
			r ~= prop.msgs.searchErrorIgnoreWait;
		}
		if (c.detail.owner && c.detail.nextType != CNextType.TEXT) {
			auto set = new HashSet!(string);
			foreach (cld; c.next) {
				if (cld.name == "") continue;
				if (set.contains(cld.name)) {
					r ~= prop.msgs.searchErrorDupNextContent;
					break;
				}
				set.add(cld.name);
			}
		}
		if (c.type == CType.TALK_DIALOG) {
			if (c.dialogs.length) {
				foreach (i, dlg; c.dialogs) {
					if (i + 1 < c.dialogs.length && !dlg.rCoupons.length) {
						// 最後以外にクーポンが設定されていない場合
						r ~= prop.msgs.searchErrorNoRCouponsDialog;
						break;
					}
					string err = checkTextRes(dlg.fontsInText, dlg.flagsInText, dlg.stepsInText);
					if (err) {
						r ~= err;
						break;
					}
				}
			}
		}
		string textErr = checkTextRes(c.fontsInText, c.flagsInText, c.stepsInText);
		if (textErr) {
			r ~= textErr;
		}
		bool hasStart() {
			foreach (s; c.tree.starts) {
				if (s.name == c.start) return true;
			}
			return false;
		}
		if (c.flag != "" && !froot.findFlag(c.flag)) {
			r ~= prop.msgs.searchErrorFlagNotFound;
		}
		if (c.step != "" && !froot.findStep(c.step)) {
			r ~= prop.msgs.searchErrorStepNotFound;
		}
		if (c.type == CType.TALK_MESSAGE && c.talkerC == Talker.IMAGE
				&& c.cardPath != "" && !skin.findPath(c.cardPath, skin.extImage, skin.tableDir, sPath).length) {
			r ~= prop.msgs.searchErrorImageNotFound;
		}
		if (c.bgmPath != "" && !skin.findPath(c.bgmPath, skin.extBgm, skin.bgmDir, sPath).length) {
			r ~= prop.msgs.searchErrorBGMNotFound;
		}
		if (c.soundPath != "" && !skin.findPath(c.soundPath, skin.extSound, skin.seDir, sPath).length) {
			r ~= prop.msgs.searchErrorSENotFound;
		}
		if (c.area != 0 && !summ.area(c.area)) {
			r ~= prop.msgs.searchErrorAreaNotFound;
		}
		if (c.battle != 0 && !summ.battle(c.battle)) {
			r ~= prop.msgs.searchErrorBattleNotFound;
		}
		if (c.packages != 0 && !summ.cwPackage(c.packages)) {
			r ~= prop.msgs.searchErrorPackageNotFound;
		}
		if (c.casts != 0 && !summ.cwCast(c.casts)) {
			r ~= prop.msgs.searchErrorCastNotFound;
		}
		if (c.item != 0 && !summ.item(c.item)) {
			r ~= prop.msgs.searchErrorItemNotFound;
		}
		if (c.skill != 0 && !summ.skill(c.skill)) {
			r ~= prop.msgs.searchErrorSkillNotFound;
		}
		if (c.beast != 0 && !summ.beast(c.beast)) {
			r ~= prop.msgs.searchErrorBeastNotFound;
		}
		if (c.info != 0 && !summ.info(c.info)) {
			r ~= prop.msgs.searchErrorInfoNotFound;
		}
		if (c.start != "" && !hasStart()) {
			r ~= prop.msgs.searchErrorStartNotFound;
		}
		foreach (m; c.motions) {
			if (m.type == MType.SUMMON_BEAST && !m.beast) {
				r ~= prop.msgs.searchErrorNoBeast;
				break;
			}
			if (m.type == MType.SUMMON_BEAST && m.beast && 0 != m.beast.linkId && !summ.beast(m.beast.linkId)) {
				r ~= prop.msgs.searchErrorLinkIdNotFound;
				break;
			}
		}
		if (c.flag2 != "" && !froot.findFlag(c.flag2)) {
			r ~= prop.msgs.searchErrorFlagNotFound;
		}
		if (c.step2 != "" && !froot.findStep(c.step2)) {
			r ~= prop.msgs.searchErrorStepNotFound;
		}
		if (c.flag != "" && c.flag == c.flag2) {
			r ~= prop.msgs.searchErrorSouceIsTarget;
		}
		if (c.step != "" && c.step == c.step2) {
			r ~= prop.msgs.searchErrorSouceIsTarget;
		}
		if ((c.type is CType.GET_COUPON || c.type is CType.LOSE_COUPON) && prop.sys.isCouponType(c.coupon, CouponType.System)) {
			r ~= prop.msgs.searchErrorSystemName;
		}
		if (c.levelMin > c.levelMax) {
			r ~= prop.msgs.searchErrorReversalLevel;
		}
		if (c.type is CType.BRANCH_ROUND) {
			CWXPath cwxPath = c;
			while (cwxPath) {
				if (cast(Area) cwxPath) {
					r ~= prop.msgs.searchErrorBranchRoundInArea;
					break;
				}
				cwxPath = cwxPath.cwxParent();
			}
		}
	}
	return r;
}

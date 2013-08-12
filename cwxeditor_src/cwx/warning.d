
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
string[] warnings(in CProps prop, in Skin skin, in Summary summ, in CWXPath path, string targVer) { mixin(S_TRACE);
	if (!summ) return [];
	auto sPath = summ.scenarioPath;
	auto froot = summ.flagDirRoot;
	string[] r;

	auto psumm = cast(Summary) path;
	if (psumm) { mixin(S_TRACE);
		if (psumm.imagePath != "" && !isBinImg(psumm.imagePath) && !skin.findPath(psumm.imagePath, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorImageNotFound;
		}
		if (psumm.levelMin > psumm.levelMax) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorReversalLevel;
		}
		if (!psumm.area(psumm.startArea)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorStartAreaNotFound;
		}
		if (psumm.imagePath != "") { mixin(S_TRACE);
			r ~= skin.warningImage(prop, psumm.imagePath, summ.legacy, targVer);
		}
	}
	auto flagDir = cast(FlagDir) path;
	if (flagDir) { mixin(S_TRACE);
		if (flagDir.parent is froot && prop.sys.isSystemVar(flagDir.name)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSystemName;
		}
	}
	auto flag = cast(Flag) path;
	if (flag) { mixin(S_TRACE);
		if (flag.parent is froot && prop.sys.isSystemVar(flag.name)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSystemName;
		}
	}
	auto step = cast(Step) path;
	if (step) { mixin(S_TRACE);
		if (step.parent is froot && prop.sys.isSystemVar(step.name)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSystemName;
		}
	}
	auto eventTree = cast(EventTree) path;
	if (eventTree) { mixin(S_TRACE);
		if (eventTree.keyCodes.length && prop.sys.convFireKeyCode(eventTree.keyCodes[0]) == "MatchingType=All") { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorKeyCodeMatchingAll;
		}
	}
	auto casts = cast(CastCard) path;
	if (casts) { mixin(S_TRACE);
		bool err = false;
		foreach (c; casts.skills) { mixin(S_TRACE);
			if (err) break;
			if (0 != c.linkId && !summ.skill(c.linkId)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorLinkIdNotFound;
				err = true;
			}
		}
		foreach (c; casts.items) { mixin(S_TRACE);
			if (err) break;
			if (0 != c.linkId && !summ.item(c.linkId)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorLinkIdNotFound;
				err = true;
			}
		}
		foreach (c; casts.beasts) { mixin(S_TRACE);
			if (err) break;
			if (0 != c.linkId && !summ.beast(c.linkId)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorLinkIdNotFound;
				err = true;
			}
		}
	}
	auto card = cast(Card) path;
	if (card) { mixin(S_TRACE);
		if (card.path != "" && !isBinImg(card.path) && !skin.findPath(card.path, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorImageNotFound;
		}
		if (card.path != "") { mixin(S_TRACE);
			r ~= skin.warningImage(prop, card.path, summ.legacy, targVer);
		}
	}
	auto effCard = cast(EffectCard) path;
	if (effCard) { mixin(S_TRACE);
		if (effCard.soundPath1 != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, effCard.soundPath1, summ.legacy, targVer);
		}
		if (effCard.soundPath2 != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, effCard.soundPath2, summ.legacy, targVer);
		}
	}
	auto spChars = skin.spChars;
	string checkTextRes(string[] fonts, string[] flags, string[] steps) { mixin(S_TRACE);
		foreach (font; fonts) { mixin(S_TRACE);
			dchar c = decodeFontPath(font);
			if (c in spChars) continue;
			if (!skin.findPath(font, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
				return prop.msgs.searchErrorSPFontNotFound;
			}
		}
		foreach (flag; flags) { mixin(S_TRACE);
			if (!froot.findFlag(flag)) { mixin(S_TRACE);
				return prop.msgs.searchErrorFlagNotFound;
			}
		}
		foreach (step; steps) { mixin(S_TRACE);
			if (!froot.findStep(step)) { mixin(S_TRACE);
				return prop.msgs.searchErrorStepNotFound;
			}
		}
		return null;
	}
	auto bi = cast(BgImage) path;
	if (bi) { mixin(S_TRACE);
		if (bi.flag != "" && !froot.findFlag(bi.flag)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorFlagNotFound;
		}
	}
	auto ic = cast(ImageCell) path;
	if (ic) { mixin(S_TRACE);
		if (!ic.path.length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoImage;
		}
		if (ic.path.length && !skin.findPath(ic.path, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorImageNotFound;
		}
		if (ic.path != "") { mixin(S_TRACE);
			r ~= skin.warningImage(prop, ic.path, summ.legacy, targVer);
		}
	}
	auto tc = cast(TextCell) path;
	if (tc) { mixin(S_TRACE);
		string err = checkTextRes([], tc.flagsInText, tc.stepsInText);
		if (err) { mixin(S_TRACE);
			r ~= err;
		}
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
	auto btl = cast(Battle) path;
	if (btl) { mixin(S_TRACE);
		if (btl.music != "") { mixin(S_TRACE);
			r ~= skin.warningBGM(prop, btl.music, summ.legacy, targVer);
		}
	}
	auto mc = cast(MenuCard) path;
	if (mc) { mixin(S_TRACE);
		if (mc.path != "" && !isBinImg(mc.path) && !skin.findPath(mc.path, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorImageNotFound;
		}
		if (mc.flag != "" && !froot.findFlag(mc.flag)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorFlagNotFound;
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
		if (ec.id != 0 && !summ.cwCast(ec.id)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorCastNotFound;
		}
		if (ec.flag != "" && !froot.findFlag(ec.flag)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorFlagNotFound;
		}
	}
	auto c = cast(Content) path;
	if (c) { mixin(S_TRACE);
		if (summ.legacy && c.type == CType.WAIT && !c.next.length) { mixin(S_TRACE);
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
			if (c.dialogs.length) { mixin(S_TRACE);
				foreach (i, dlg; c.dialogs) { mixin(S_TRACE);
					if (i + 1 < c.dialogs.length && !dlg.rCoupons.length) { mixin(S_TRACE);
						// 最後以外にクーポンが設定されていない場合
						r ~= prop.msgs.searchErrorNoRCouponsDialog;
						break;
					}
					string err = checkTextRes(dlg.fontsInText, dlg.flagsInText, dlg.stepsInText);
					if (err) { mixin(S_TRACE);
						r ~= err;
						break;
					}
				}
			}
		}
		string textErr = checkTextRes(c.fontsInText, c.flagsInText, c.stepsInText);
		if (textErr) { mixin(S_TRACE);
			r ~= textErr;
		}
		bool hasStart() { mixin(S_TRACE);
			foreach (s; c.tree.starts) { mixin(S_TRACE);
				if (s.name == c.start) return true;
			}
			return false;
		}
		if (c.flag != "" && !froot.findFlag(c.flag)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorFlagNotFound;
		}
		if (c.step != "" && !froot.findStep(c.step)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorStepNotFound;
		}
		if (c.type == CType.TALK_MESSAGE && c.talkerC == Talker.IMAGE
				&& c.cardPath != "" && !skin.findPath(c.cardPath, skin.extImage, skin.tableDir, sPath).length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorImageNotFound;
		}
		if (c.bgmPath != "" && !skin.findPath(c.bgmPath, skin.extBgm, skin.bgmDir, sPath).length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorBGMNotFound;
		}
		if (c.soundPath != "" && !skin.findPath(c.soundPath, skin.extSound, skin.seDir, sPath).length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSENotFound;
		}
		if (c.area != 0 && !summ.area(c.area)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorAreaNotFound;
		}
		if (c.battle != 0 && !summ.battle(c.battle)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorBattleNotFound;
		}
		if (c.packages != 0 && !summ.cwPackage(c.packages)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorPackageNotFound;
		}
		if (c.casts != 0 && !summ.cwCast(c.casts)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorCastNotFound;
		}
		if (c.item != 0 && !summ.item(c.item)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorItemNotFound;
		}
		if (c.skill != 0 && !summ.skill(c.skill)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSkillNotFound;
		}
		if (c.beast != 0 && !summ.beast(c.beast)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorBeastNotFound;
		}
		if (c.info != 0 && !summ.info(c.info)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorInfoNotFound;
		}
		if (c.start != "" && !hasStart()) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorStartNotFound;
		}
		foreach (m; c.motions) { mixin(S_TRACE);
			if (m.type == MType.SUMMON_BEAST && !m.beast) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoBeast;
				break;
			}
			if (m.type == MType.SUMMON_BEAST && m.beast && 0 != m.beast.linkId && !summ.beast(m.beast.linkId)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorLinkIdNotFound;
				break;
			}
		}
		if (c.flag2 != "" && !froot.findFlag(c.flag2)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorFlagNotFound;
		}
		if (c.step2 != "" && !froot.findStep(c.step2)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorStepNotFound;
		}
		if (c.flag != "" && c.flag == c.flag2) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSouceIsTarget;
		}
		if (c.step != "" && c.step == c.step2) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSouceIsTarget;
		}
		if ((c.type is CType.GET_COUPON || c.type is CType.LOSE_COUPON) && prop.sys.isCouponType(c.coupon, CouponType.System)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSystemName;
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
			r ~= skin.warningImage(prop, c.cardPath, summ.legacy, targVer);
		}
		if (c.bgmPath != "") { mixin(S_TRACE);
			r ~= skin.warningBGM(prop, c.bgmPath, summ.legacy, targVer);
		}
		if (c.soundPath != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, c.soundPath, summ.legacy, targVer);
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

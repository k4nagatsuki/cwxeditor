SRC = cwxeditor.d \
	cwx\utils.d \
	cwx\sjis.d \
	cwx\system.d \
	cwx\card.d \
	cwx\coupon.d \
	cwx\xml.d \
	cwx\event.d \
	cwx\types.d \
	cwx\motion.d \
	cwx\usecounter.d \
	cwx\flag.d \
	cwx\path.d \
	cwx\background.d \
	cwx\props.d \
	cwx\features.d \
	cwx\area.d \
	cwx\summary.d \
	cwx\cwl.d \
	cwx\binary.d \
	cwx\archive.d \
	cwx\skin.d \
	cwx\race.d \
	cwx\imagesize.d \
	cwx\cab.d \
	cwx\structs.d \
	cwx\graphics.d \
	cwx\jpy.d \
	cwx\script.d \
	cwx\msgs.d \
	cwx\versioninfo.d \
	cwx\msgutils.d \
	cwx\settings.d \
	cwx\menu.d \
	cwx\variables.d \
	cwx\editor\gui\sound.d \
	cwx\editor\gui\dwt\sbshell.d \
	cwx\editor\gui\dwt\mainwindow.d \
	cwx\editor\gui\dwt\images.d \
	cwx\editor\gui\dwt\dutils.d \
	cwx\editor\gui\dwt\dprops.d \
	cwx\editor\gui\dwt\properties.d \
	cwx\editor\gui\dwt\absdialog.d \
	cwx\editor\gui\dwt\dockingfolder.d \
	cwx\editor\gui\dwt\splitpane.d \
	cwx\editor\gui\dwt\centerlayout.d \
	cwx\editor\gui\dwt\dskin.d \
	cwx\editor\gui\dwt\commons.d \
	cwx\editor\gui\dwt\areaview.d \
	cwx\editor\gui\dwt\spcarddialog.d \
	cwx\editor\gui\dwt\materialselect.d \
	cwx\editor\gui\dwt\imageselect.d \
	cwx\editor\gui\dwt\customtext.d \
	cwx\editor\gui\dwt\customtable.d \
	cwx\editor\gui\dwt\bgimagedialog.d \
	cwx\editor\gui\dwt\xmlbytestransfer.d \
	cwx\editor\gui\dwt\undo.d \
	cwx\editor\gui\dwt\jpyimage.d \
	cwx\editor\gui\dwt\areawindow.d \
	cwx\editor\gui\dwt\eventview.d \
	cwx\editor\gui\dwt\message.d \
	cwx\editor\gui\dwt\eventtreeview.d \
	cwx\editor\gui\dwt\eventdialog.d \
	cwx\editor\gui\dwt\motionview.d \
	cwx\editor\gui\dwt\effectcarddialog.d \
	cwx\editor\gui\dwt\radarspinner.d \
	cwx\editor\gui\dwt\cardwindow.d \
	cwx\editor\gui\dwt\commondialog.d \
	cwx\editor\gui\dwt\cardlist.d \
	cwx\editor\gui\dwt\eventwindow.d \
	cwx\editor\gui\dwt\castcarddialog.d \
	cwx\editor\gui\dwt\infocarddialog.d \
	cwx\editor\gui\dwt\directorywindow.d \
	cwx\editor\gui\dwt\datawindow.d \
	cwx\editor\gui\dwt\areatable.d \
	cwx\editor\gui\dwt\flagtable.d \
	cwx\editor\gui\dwt\summarydialog.d \
	cwx\editor\gui\dwt\flagspane.d \
	cwx\editor\gui\dwt\flagdirtree.d \
	cwx\editor\gui\dwt\settingsdialog.d \
	cwx\editor\gui\dwt\replacedialog.d \
	cwx\editor\gui\dwt\scripterrordialog.d \
	cwx\editor\gui\dwt\textdialog.d \
	cwx\editor\gui\dwt\imagelistwindow.d \
	cwx\editor\gui\dwt\smalldialogs.d \
	cwx\editor\gui\dwt\image.d \
	cwx\editor\gui\dwt\cardpane.d \
	cwx\editor\gui\dwt\loader.d \
	cwx\editor\gui\dwt\areaviewutils.d \
	cwx\editor\gui\dwt\messageutils.d \
	cwx\editor\gui\dwt\dmenu.d \

OBJ = objs\cwxeditor.obj \
	objs\cwx\utils.obj \
	objs\cwx\sjis.obj \
	objs\cwx\system.obj \
	objs\cwx\card.obj \
	objs\cwx\coupon.obj \
	objs\cwx\xml.obj \
	objs\cwx\event.obj \
	objs\cwx\types.obj \
	objs\cwx\motion.obj \
	objs\cwx\usecounter.obj \
	objs\cwx\flag.obj \
	objs\cwx\path.obj \
	objs\cwx\background.obj \
	objs\cwx\props.obj \
	objs\cwx\features.obj \
	objs\cwx\area.obj \
	objs\cwx\summary.obj \
	objs\cwx\cwl.obj \
	objs\cwx\binary.obj \
	objs\cwx\archive.obj \
	objs\cwx\skin.obj \
	objs\cwx\race.obj \
	objs\cwx\imagesize.obj \
	objs\cwx\cab.obj \
	objs\cwx\structs.obj \
	objs\cwx\graphics.obj \
	objs\cwx\jpy.obj \
	objs\cwx\script.obj \
	objs\cwx\msgs.obj \
	objs\cwx\versioninfo.obj \
	objs\cwx\msgutils.obj \
	objs\cwx\settings.obj \
	objs\cwx\menu.obj \
	objs\cwx\variables.obj \
	objs\cwx\editor\gui\sound.obj \
	objs\cwx\editor\gui\dwt\sbshell.obj \
	objs\cwx\editor\gui\dwt\mainwindow.obj \
	objs\cwx\editor\gui\dwt\images.obj \
	objs\cwx\editor\gui\dwt\dutils.obj \
	objs\cwx\editor\gui\dwt\dprops.obj \
	objs\cwx\editor\gui\dwt\properties.obj \
	objs\cwx\editor\gui\dwt\absdialog.obj \
	objs\cwx\editor\gui\dwt\dockingfolder.obj \
	objs\cwx\editor\gui\dwt\splitpane.obj \
	objs\cwx\editor\gui\dwt\centerlayout.obj \
	objs\cwx\editor\gui\dwt\dskin.obj \
	objs\cwx\editor\gui\dwt\commons.obj \
	objs\cwx\editor\gui\dwt\areaview.obj \
	objs\cwx\editor\gui\dwt\spcarddialog.obj \
	objs\cwx\editor\gui\dwt\materialselect.obj \
	objs\cwx\editor\gui\dwt\imageselect.obj \
	objs\cwx\editor\gui\dwt\customtext.obj \
	objs\cwx\editor\gui\dwt\customtable.obj \
	objs\cwx\editor\gui\dwt\bgimagedialog.obj \
	objs\cwx\editor\gui\dwt\xmlbytestransfer.obj \
	objs\cwx\editor\gui\dwt\undo.obj \
	objs\cwx\editor\gui\dwt\jpyimage.obj \
	objs\cwx\editor\gui\dwt\areawindow.obj \
	objs\cwx\editor\gui\dwt\eventview.obj \
	objs\cwx\editor\gui\dwt\message.obj \
	objs\cwx\editor\gui\dwt\eventtreeview.obj \
	objs\cwx\editor\gui\dwt\eventdialog.obj \
	objs\cwx\editor\gui\dwt\motionview.obj \
	objs\cwx\editor\gui\dwt\effectcarddialog.obj \
	objs\cwx\editor\gui\dwt\radarspinner.obj \
	objs\cwx\editor\gui\dwt\cardwindow.obj \
	objs\cwx\editor\gui\dwt\commondialog.obj \
	objs\cwx\editor\gui\dwt\cardlist.obj \
	objs\cwx\editor\gui\dwt\eventwindow.obj \
	objs\cwx\editor\gui\dwt\castcarddialog.obj \
	objs\cwx\editor\gui\dwt\infocarddialog.obj \
	objs\cwx\editor\gui\dwt\directorywindow.obj \
	objs\cwx\editor\gui\dwt\datawindow.obj \
	objs\cwx\editor\gui\dwt\areatable.obj \
	objs\cwx\editor\gui\dwt\flagtable.obj \
	objs\cwx\editor\gui\dwt\summarydialog.obj \
	objs\cwx\editor\gui\dwt\flagspane.obj \
	objs\cwx\editor\gui\dwt\flagdirtree.obj \
	objs\cwx\editor\gui\dwt\settingsdialog.obj \
	objs\cwx\editor\gui\dwt\replacedialog.obj \
	objs\cwx\editor\gui\dwt\scripterrordialog.obj \
	objs\cwx\editor\gui\dwt\textdialog.obj \
	objs\cwx\editor\gui\dwt\imagelistwindow.obj \
	objs\cwx\editor\gui\dwt\smalldialogs.obj \
	objs\cwx\editor\gui\dwt\image.obj \
	objs\cwx\editor\gui\dwt\cardpane.obj \
	objs\cwx\editor\gui\dwt\loader.obj \
	objs\cwx\editor\gui\dwt\areaviewutils.obj \
	objs\cwx\editor\gui\dwt\messageutils.obj \
	objs\cwx\editor\gui\dwt\dmenu.obj \
	objs\xml.obj \

DMD = dmd
RCC = rcc
APP = cwxeditor
RM = del
RMDIR = rmdir /S /Q
RC = $(APP).rc
OUT = $(APP).exe
RES = $(APP).res
MAP = $(APP).map

LIB = /rc:cwxeditor \
	/NOM \
	+advapi32.lib \
	+comctl32.lib \
	+comdlg32.lib \
	+gdi32.lib \
	+kernel32.lib \
	+shell32.lib \
	+ole32.lib \
	+oleaut32.lib \
	+olepro32.lib \
	+oleacc.lib \
	+user32.lib \
	+usp10.lib \
	+msimg32.lib \
	+opengl32.lib \
	+shlwapi.lib \
	+dwt-base.lib \
	+org.eclipse.swt.win32.win32.x86.lib \

FLAGS = -J. -Jresource -op -c -property

$(OUT) : $(SRC) $(RES)
	$(DMD) $(FLAGS) $(SRC) -g -gs -debug -unittest -version="Console" -odobjs
	$(DMD) -c -O -inline -release d2std\xml.d -odobjs
	$(DMD) $(OBJ) -L"$(LIB)" -g -gs -debug -of"$(OUT)" -L/exet:nt/su:console:4.0

debug_windows : $(SRC) $(RES)
	$(DMD) $(FLAGS) $(SRC) -g -gs -debug -unittest -odobjs
	$(DMD) -c -O -inline -release d2std\xml.d -odobjs
	$(DMD) $(OBJ) -L"$(LIB)" -g -gs -of"$(OUT)" -L/exet:nt/su:windows:4.0

release : $(SRC) $(RES)
	$(DMD) $(FLAGS) $(SRC) -release -odobjs
	$(DMD) -c -O -inline -release d2std\xml.d -odobjs
	$(DMD) $(OBJ) -L"$(LIB)" -of"$(OUT)" -L/exet:nt/su:windows:4.0 -O

linktest : $(OBJ)
	$(DMD) $(OBJ) -L"$(LIB)" -g -gs -debug -of"$(OUT)" -L/exet:nt/su:console:4.0
	$(DMD) $(OBJ) -L"$(LIB)" -g -gs -of"$(OUT)" -L/exet:nt/su:windows:4.0

$(RES) : $(RC)
	rcc $(RC)

clean :
	$(RM) $(OUT) $(MAP) $(RES)
	$(RMDIR) objs

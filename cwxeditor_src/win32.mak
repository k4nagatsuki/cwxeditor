SRC = cwxeditor.d \
	cwx\utils.d \
	cwx\sjis.d \
	cwx\system.d \
	cwx\card.d \
	cwx\coupon.d \
	cwx\xml.d \
	d2std\xml.d \
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
	cwx\editor\gui\sound.d \
	cwx\editor\gui\dwt\sbshell.d \
	cwx\editor\gui\dwt\mainwindow.d \
	cwx\editor\gui\dwt\images.d \
	cwx\editor\gui\dwt\utils.d \
	cwx\editor\gui\dwt\props.d \
	cwx\editor\gui\dwt\properties.d \
	cwx\editor\gui\dwt\absdialog.d \
	cwx\editor\gui\dwt\dockingfolder.d \
	cwx\editor\gui\dwt\splitpane.d \
	cwx\editor\gui\dwt\centerlayout.d \
	cwx\editor\gui\dwt\skin.d \
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

OBJ = cwxeditor.obj \
	cwx\utils.obj \
	cwx\sjis.obj \
	cwx\system.obj \
	cwx\card.obj \
	cwx\coupon.obj \
	cwx\xml.obj \
	d2std\xml.obj \
	cwx\event.obj \
	cwx\types.obj \
	cwx\motion.obj \
	cwx\usecounter.obj \
	cwx\flag.obj \
	cwx\path.obj \
	cwx\background.obj \
	cwx\props.obj \
	cwx\features.obj \
	cwx\area.obj \
	cwx\summary.obj \
	cwx\cwl.obj \
	cwx\binary.obj \
	cwx\archive.obj \
	cwx\skin.obj \
	cwx\race.obj \
	cwx\imagesize.obj \
	cwx\cab.obj \
	cwx\structs.obj \
	cwx\graphics.obj \
	cwx\jpy.obj \
	cwx\editor\gui\sound.obj \
	cwx\editor\gui\dwt\sbshell.obj \
	cwx\editor\gui\dwt\mainwindow.obj \
	cwx\editor\gui\dwt\images.obj \
	cwx\editor\gui\dwt\utils.obj \
	cwx\editor\gui\dwt\props.obj \
	cwx\editor\gui\dwt\properties.obj \
	cwx\editor\gui\dwt\absdialog.obj \
	cwx\editor\gui\dwt\dockingfolder.obj \
	cwx\editor\gui\dwt\splitpane.obj \
	cwx\editor\gui\dwt\centerlayout.obj \
	cwx\editor\gui\dwt\skin.obj \
	cwx\editor\gui\dwt\commons.obj \
	cwx\editor\gui\dwt\areaview.obj \
	cwx\editor\gui\dwt\spcarddialog.obj \
	cwx\editor\gui\dwt\materialselect.obj \
	cwx\editor\gui\dwt\imageselect.obj \
	cwx\editor\gui\dwt\customtext.obj \
	cwx\editor\gui\dwt\customtable.obj \
	cwx\editor\gui\dwt\bgimagedialog.obj \
	cwx\editor\gui\dwt\xmlbytestransfer.obj \
	cwx\editor\gui\dwt\undo.obj \
	cwx\editor\gui\dwt\jpyimage.obj \
	cwx\editor\gui\dwt\areawindow.obj \
	cwx\editor\gui\dwt\eventview.obj \
	cwx\editor\gui\dwt\message.obj \
	cwx\editor\gui\dwt\eventtreeview.obj \
	cwx\editor\gui\dwt\eventdialog.obj \
	cwx\editor\gui\dwt\motionview.obj \
	cwx\editor\gui\dwt\effectcarddialog.obj \
	cwx\editor\gui\dwt\radarspinner.obj \
	cwx\editor\gui\dwt\cardwindow.obj \
	cwx\editor\gui\dwt\commondialog.obj \
	cwx\editor\gui\dwt\cardlist.obj \
	cwx\editor\gui\dwt\eventwindow.obj \
	cwx\editor\gui\dwt\castcarddialog.obj \
	cwx\editor\gui\dwt\infocarddialog.obj \
	cwx\editor\gui\dwt\directorywindow.obj \
	cwx\editor\gui\dwt\datawindow.obj \
	cwx\editor\gui\dwt\areatable.obj \
	cwx\editor\gui\dwt\flagtable.obj \
	cwx\editor\gui\dwt\summarydialog.obj \
	cwx\editor\gui\dwt\flagspane.obj \
	cwx\editor\gui\dwt\flagdirtree.obj \
	cwx\editor\gui\dwt\settingsdialog.obj \
	cwx\editor\gui\dwt\replacedialog.obj \

DMD = dmd
RCC = rcc
APP = cwxeditor
RM = del
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
	+zlib.lib \
	+dwt-base.lib \
	+org.eclipse.swt.win32.win32.x86.lib \
	+tangobos.lib \

FLAGS = -J. -Jresource -op -c

$(OUT) : $(SRC) $(RES)
	$(DMD) $(FLAGS) $** -g -debug -unittest
	$(DMD) $(OBJ) -L"$(LIB)" -of"$(OUT)" -L/exet:nt/su:console:4.0

release : $(SRC) $(RES)
	$(DMD) $(FLAGS) $** -release -O
	$(DMD) $(OBJ) -L"$(LIB)" -of"$(OUT)" -L/exet:nt/su:windows:4.0 -O

$(RES) : $(RC)
	rcc $(RC)

clean :
	$(RM) $(OUT) $(MAP) $(OBJ) $(RES)

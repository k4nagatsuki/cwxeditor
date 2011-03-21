SRC = cwxeditor.d \
	cwx/utils.d \
	cwx/sjis.d \
	cwx/system.d \
	cwx/card.d \
	cwx/coupon.d \
	cwx/xml.d \
	d2std/xml.d \
	cwx/event.d \
	cwx/types.d \
	cwx/motion.d \
	cwx/usecounter.d \
	cwx/flag.d \
	cwx/path.d \
	cwx/background.d \
	cwx/props.d \
	cwx/features.d \
	cwx/area.d \
	cwx/summary.d \
	cwx/cwl.d \
	cwx/binary.d \
	cwx/archive.d \
	cwx/skin.d \
	cwx/race.d \
	cwx/imagesize.d \
	cwx/cab.d \
	cwx/structs.d \
	cwx/graphics.d \
	cwx/jpy.d \
	cwx/script.d \
	cwx/editor/gui/sound.d \
	cwx/editor/gui/dwt/sbshell.d \
	cwx/editor/gui/dwt/mainwindow.d \
	cwx/editor/gui/dwt/images.d \
	cwx/editor/gui/dwt/utils.d \
	cwx/editor/gui/dwt/props.d \
	cwx/editor/gui/dwt/properties.d \
	cwx/editor/gui/dwt/absdialog.d \
	cwx/editor/gui/dwt/dockingfolder.d \
	cwx/editor/gui/dwt/splitpane.d \
	cwx/editor/gui/dwt/centerlayout.d \
	cwx/editor/gui/dwt/skin.d \
	cwx/editor/gui/dwt/commons.d \
	cwx/editor/gui/dwt/areaview.d \
	cwx/editor/gui/dwt/spcarddialog.d \
	cwx/editor/gui/dwt/materialselect.d \
	cwx/editor/gui/dwt/imageselect.d \
	cwx/editor/gui/dwt/customtext.d \
	cwx/editor/gui/dwt/customtable.d \
	cwx/editor/gui/dwt/bgimagedialog.d \
	cwx/editor/gui/dwt/xmlbytestransfer.d \
	cwx/editor/gui/dwt/undo.d \
	cwx/editor/gui/dwt/jpyimage.d \
	cwx/editor/gui/dwt/areawindow.d \
	cwx/editor/gui/dwt/eventview.d \
	cwx/editor/gui/dwt/message.d \
	cwx/editor/gui/dwt/eventtreeview.d \
	cwx/editor/gui/dwt/eventdialog.d \
	cwx/editor/gui/dwt/motionview.d \
	cwx/editor/gui/dwt/effectcarddialog.d \
	cwx/editor/gui/dwt/radarspinner.d \
	cwx/editor/gui/dwt/cardwindow.d \
	cwx/editor/gui/dwt/commondialog.d \
	cwx/editor/gui/dwt/cardlist.d \
	cwx/editor/gui/dwt/eventwindow.d \
	cwx/editor/gui/dwt/castcarddialog.d \
	cwx/editor/gui/dwt/infocarddialog.d \
	cwx/editor/gui/dwt/directorywindow.d \
	cwx/editor/gui/dwt/datawindow.d \
	cwx/editor/gui/dwt/areatable.d \
	cwx/editor/gui/dwt/flagtable.d \
	cwx/editor/gui/dwt/summarydialog.d \
	cwx/editor/gui/dwt/flagspane.d \
	cwx/editor/gui/dwt/flagdirtree.d \
	cwx/editor/gui/dwt/settingsdialog.d \
	cwx/editor/gui/dwt/replacedialog.d \
	cwx/editor/gui/dwt/scripterrordialog.d \

OBJ = $(SRC:%.d=%.o)
DMD = dmd
RM = rm
OUT = cwxeditor

LIB = org.eclipse.swt.gtk.linux.x86.a \
	dwt-base.a \
	-L-ltangobos \
	-L-lgnomeui-2 \
	-L-lcairo \
	-L-lglib-2.0 \
	-L-ldl \
	-L-lgmodule-2.0 \
	-L-lgobject-2.0 \
	-L-lpango-1.0 \
	-L-lXfixes \
	-L-lX11 \
	-L-lXdamage \
	-L-lXcomposite \
	-L-lXcursor \
	-L-lXrandr \
	-L-lXi \
	-L-lXinerama \
	-L-lXrender \
	-L-lXext \
	-L-lXtst \
	-L-lfontconfig \
	-L-lpangocairo-1.0 \
	-L-lgthread-2.0 \
	-L-lgdk_pixbuf-2.0 \
	-L-latk-1.0 \
	-L-lgdk-x11-2.0 \
	-L-lgtk-x11-2.0 \

FLAGS = -J. -Jresource -op -c

$(OUT) : $(SRC)
	$(DMD) $(FLAGS) $(SRC) -g -debug -unittest
	$(DMD) $(OBJ) $(LIB) -of"$(OUT)"

release : $(SRC)
	$(DMD) $(FLAGS) $(SRC) -release -O
	$(DMD) $(OBJ) $(LIB) -of"$(OUT)"

clean :
	$(RM) $(OUT) $(OBJ)


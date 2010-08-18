rcc cwxeditor.rc
rem bud cwxeditor.d -L"/rc:cwxeditor" -J./ -Jresource -release -O -gui -full -clean %1 %2 %3 %4 %5 %6 %7 %8 %9
rem -gui‚ð‚Â‚¯‚é‚ÆClipboard#dispose‚ÅŽ€‚Ê‚½‚ß”ð‚¯‚é
bud cwxeditor.d -L"/rc:cwxeditor" -J./ -Jresource -release -O -L/exet:nt/su:windows:4.0 -full -clean %1 %2 %3 %4 %5 %6 %7 %8 %9

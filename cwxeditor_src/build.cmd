rcc cwxeditor.rc
rem bud cwxeditor.d -L"/rc:cwxeditor" -J./ -Jresource -version=nocatch -g -debug -unittest -clean -full -L"/su:console:5" %1 %2 %3 %4 %5 %6 %7 %8 %9
bud cwxeditor.d -L"/rc:cwxeditor" -J./ -Jresource -debug -unittest -clean -full -L"/su:console:5" %1 %2 %3 %4 %5 %6 %7 %8 %9

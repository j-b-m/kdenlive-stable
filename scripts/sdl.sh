#!/bin/bash
set -e
set -x
cd /app/src/
wget https://www.libsdl.org/release/SDL-1.2.15.tar.gz
tar -xf SDL-1.2.15.tar.gz
cd SDL-1.2.15
# patch SDL
	cat > sdl_fix.patch << EOF
diff -r f7fd5c3951b9 -r 91ad7b43317a configure.in
--- a/configure.in	Wed Apr 17 00:56:53 2013 -0700
+++ b/configure.in	Sun Jun 02 20:48:53 2013 +0600
@@ -1169,6 +1169,17 @@
             if test x$definitely_enable_video_x11_xrandr = xyes; then
                 AC_DEFINE(SDL_VIDEO_DRIVER_X11_XRANDR)
             fi
+            AC_MSG_CHECKING(for const parameter to _XData32)
+            have_const_param_xdata32=no
+            AC_TRY_COMPILE([
+              #include <X11/Xlibint.h>
+              extern int _XData32(Display *dpy,register _Xconst long *data,unsigned len);
+            ],[
+            ],[
+            have_const_param_xdata32=yes
+            AC_DEFINE(SDL_VIDEO_DRIVER_X11_CONST_PARAM_XDATA32)
+            ])
+            AC_MSG_RESULT($have_const_param_xdata32)
         fi
     fi
 }
diff -r f7fd5c3951b9 -r 91ad7b43317a include/SDL_config.h.in
--- a/include/SDL_config.h.in	Wed Apr 17 00:56:53 2013 -0700
+++ b/include/SDL_config.h.in	Sun Jun 02 20:48:53 2013 +0600
@@ -283,6 +283,7 @@
 #undef SDL_VIDEO_DRIVER_WINDIB
 #undef SDL_VIDEO_DRIVER_WSCONS
 #undef SDL_VIDEO_DRIVER_X11
+#undef SDL_VIDEO_DRIVER_X11_CONST_PARAM_XDATA32
 #undef SDL_VIDEO_DRIVER_X11_DGAMOUSE
 #undef SDL_VIDEO_DRIVER_X11_DYNAMIC
 #undef SDL_VIDEO_DRIVER_X11_DYNAMIC_XEXT
diff -r f7fd5c3951b9 -r 91ad7b43317a src/video/x11/SDL_x11sym.h
--- a/src/video/x11/SDL_x11sym.h	Wed Apr 17 00:56:53 2013 -0800
+++ b/src/video/x11/SDL_x11sym.h	Sun Jun 02 20:48:53 2013 +0100
@@ -165,7 +165,7 @@
  */
 #ifdef LONG64
 SDL_X11_MODULE(IO_32BIT)
-SDL_X11_SYM(int,_XData32,(Display *dpy,register long *data,unsigned len),(dpy,data,len),return)
+SDL_X11_SYM(int,_XData32,(Display *dpy,register _Xconst long *data,unsigned len),(dpy,data,len),return)
 SDL_X11_SYM(void,_XRead32,(Display *dpy,register long *data,long len),(dpy,data,len),)
 #endif

EOF
	cat sdl_fix.patch |patch -p1
	cd ..

cd SDL-1.2.15
if ./configure --prefix=/opt/usr; then

make
make install

else
	error_exit "$LINENO: An error has occurred.. Aborting."
fi

function error_exit
{
	echo "$1" 1>&2
	exit 1
}

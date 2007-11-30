require "mkmf"
require "rbconfig"

$INCFLAGS += " -I/usr/include/libgnomeprint-2.2 -I/usr/include/libart-2.0 -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include -I/usr/include/libxml2 -I/usr/include/pango-1.0 -I/usr/include/libgnomeprintui-2.2 -I/usr/include/libgnomecanvas-2.0 -I/usr/include/freetype2 -I/usr/include/gail-1.0 -I/usr/include/gtk-2.0 -I/usr/include/atk-1.0 -I/usr/lib/gtk-2.0/include -I/usr/include/cairo -I/usr/include/libpng12 "
$LIBS += " -lgnomeprintui-2-2 -lgnomeprint-2-2 -lz -lgnomecanvas-2 -lxml2 -lart_lgpl_2 -lgtk-x11-2.0 -lgdk-x11-2.0 -lgdk_pixbuf-2.0 -lm -lpangocairo-1.0 -lfontconfig -lXext -lXrender -lXinerama -lXi -lXrandr -lXcursor -lXcomposite -lXdamage -lpango-1.0 -lcairo -lX11 -lXfixes -latk-1.0 -lgobject-2.0 -lgmodule-2.0 -ldl -lglib-2.0 "

create_makefile("keybinder")


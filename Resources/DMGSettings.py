# dmgbuild settings — invoked from build.sh.
#
# build.sh passes the moving parts via -D flags:
#   -D app_path=<absolute path to the signed .app>
#   -D bg_image=<absolute path to background PNG, or empty string>
#
# Everything else (window size, chrome visibility, icon positions, view
# mode) lives here so the layout is reproducible without driving Finder
# via AppleScript. dmgbuild writes the .DS_Store directly using the
# ds_store library — no Finder, no automation permission prompts, no
# sync timing races.

import os.path

_app = defines['app_path']
_bg = defines.get('bg_image', '')

# ----- image format -----------------------------------------------------
# UDZO = compressed read-only, the standard distribution format.
format = 'UDZO'
filesystem = 'HFS+'
size = None  # auto-size to contents

# ----- contents ---------------------------------------------------------
files = [_app]
symlinks = {'Applications': '/Applications'}

# ----- window -----------------------------------------------------------
# (x, y) top-left, (w, h) size. 540x380 is a comfortable size for the
# classic two-icon "drag to Applications" layout.
window_rect = ((200, 120), (540, 380))
default_view = 'icon-view'

# Hide every bit of Finder chrome — clean install window, just the
# icons + (optional) background.
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 0

# ----- icon view --------------------------------------------------------
icon_size = 128
text_size = 13
arrange_by = None  # don't snap to grid — honour explicit positions below

# Place the app on the left, /Applications symlink on the right. If you
# add a background image with arrows, it should align to roughly these
# coordinates (icon centres at y=190, x=140 and x=400 respectively).
_app_basename = os.path.basename(_app)
icon_locations = {
    _app_basename: (140, 190),
    'Applications': (400, 190),
}

# ----- background (optional) -------------------------------------------
# If a background PNG path was passed in, wire it up. Drop a file at
# Resources/DMGBackground.png to enable. dmgbuild auto-detects @2x HiDPI
# variants if you ship them as <name>@2x.png alongside.
if _bg:
    background = _bg

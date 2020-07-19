/* See LICENSE file for copyright and license details. */

/* Modifer keys */
#define KEY_BRIGHT_UP     0x1008ff02
#define KEY_BRIGHT_DOWN   0x1008ff03
#define KEY_VOL_UP        0x1008ff13
#define KEY_VOL_DOWN      0x1008ff11
#define KEY_VOL_MUTE      0x1008ff12
#define KEY_MIC_MUTE      0x1008ffb2
#define KEY_PRINTSCRN     0xff61
#define BCKLGHT_DIFF	  "5"
#define VOLUP_DIFF        "5%+"
#define VOLDOWN_DIFF      "5%-"

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int snap      = 10;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const double defaultopacity  = 1.0;
static const char *fonts[]          = { "Ubuntu Mono:size=10" };
static const char dmenufont[]       = "Ubuntu Mono:size=10";

static const char col_base00[]      = "#1d1f21"; /* darkest-grey */
static const char col_base08[]      = "#f92672"; /* vibrant pink */
static const char col_base0B[]      = "#a6e22e"; /* vibrant lime green */
static const char col_base0A[]      = "#f4bf75"; /* beige-orange */
static const char col_base0D[]      = "#66d9ef"; /* light-blue */
static const char col_base0E[]      = "#ae81ff"; /* vibrant light-purple */
static const char col_base0C[]      = "#a1efe4"; /* light-aqua */
static const char col_base05[]      = "#f8f8f2"; /* white (ish) */
static const char col_base03[]      = "#75715e"; /* grey */
static const char col_base09[]      = "#fd971f"; /* orange */
static const char col_base01[]      = "#383830"; /* dark-grey */
static const char col_base02[]      = "#49483e"; /* darker-grey */
static const char col_base04[]      = "#a59f85"; /* light-grey-green */
static const char col_base06[]      = "#f5f4f1"; /* white (ish) */
static const char col_base0F[]      = "#cc6633"; /* white (ish) */
static const char col_base07[]      = "#f9f8f5"; /* white (ish) */
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_base0D, col_base00, col_base0D },
	[SchemeSel]  = { col_base08, col_base00, col_base0D },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
    /* xprop(1):
     *  WM_CLASS(STRING) = instance, class
     *  WM_NAME(STRING) = title
     */
    /* class      instance    title       tags mask     isfloating   monitor */
    { "Gimp",     NULL,       NULL,       0,            1,           -1 },
};


/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_base00, "-nf", col_base0D, "-sb", col_base00, "-sf", col_base0D, NULL };
static const char *termcmd[]  = { "alacritty", NULL };

static const char *brightness_up[]  =   { "xbacklight", "-inc", BCKLGHT_DIFF };
static const char *brightness_down[]  = { "xbacklight", "-dec", BCKLGHT_DIFF };
static const char *volume_up[] = { "amixer", "sset", "Master", VOLUP_DIFF, NULL };
static const char *volume_down[] = { "amixer", "sset", "Master", VOLDOWN_DIFF, NULL };
static const char *volume_mute[] = { "amixer", "sset", "Master", "1+", "toggle", NULL };
static const char *mic_mute[] = { "amixer", "-D", "pulse", "sset", "Capture", "1+", "toggle", NULL };
static const char *screenshot[] = { "scrot", "screenshot_%y%m%d_%H%M.png", NULL };
static const char *screenshot_focused[] = { "scrot", "--focused", "screenshot_%y%m%d_%H%M.png", NULL };

static Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_p,      spawn,          {.v = dmenucmd } },
	{ MODKEY|ShiftMask,             XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
    { 0,                            KEY_BRIGHT_UP,             spawn,       {.v = brightness_up } },
    { 0,                            KEY_BRIGHT_DOWN,           spawn,       {.v = brightness_down } },
    { 0,                            KEY_VOL_UP,                spawn,       {.v = volume_up } },
    { 0,                            KEY_VOL_DOWN,              spawn,       {.v = volume_down} },
    { 0,                            KEY_VOL_MUTE,              spawn,       {.v = volume_mute} },
    { 0,                            KEY_MIC_MUTE,              spawn,       {.v = mic_mute} },
    { 0,                            KEY_PRINTSCRN,             spawn,       {.v = screenshot} },
    { ShiftMask,                    KEY_PRINTSCRN,             spawn,       {.v = screenshot_focused} },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

Maximize script & Rio patch
===========================

The rio(4) manual is phrased in a way to imply that the `wctl` `move` command can take `-maxx` and `-maxy` options, but unfortunately the implementation disagrees. If the implementation matched the docs, aligning windows to the right or bottom edge of the screen would be very simple, so let's take a look at what needs to be fixed. References to code won't use line numbers as Plan 9 is potentially a moving target in the case of the 9front fork.

The area we're interested in is located in `wctl.c`.

Fig 1.
```
int
wctlcmd(Window *w, Rectangle r, int cmd, char *err)
{
	Image *i;

	switch(cmd){
	case Move:
		r = Rect(r.min.x, r.min.y, r.min.x+Dx(w->screenr), r.min.y+Dy(w->screenr));
		r = rectonscreen(r);
		/* fall through */
	case Resize:
```

The `r` argument to the function is initialized to the rectangle for the window, and each of `-minx`, `-miny`, `-maxx` and `-maxy` will overwrite its corresponding value in `r`. So the behavior of the move command in Fig 1 is to throw out the max `x` and `y` values and replace them with the minimum values added to the width or height (Dx, Dy) of the window, hence keeping the window the same dimensions. The last thing the `Move` case does is call `rectonscreen` which moves the rectangle so that all parts of it are on screen if any of it isn't.

You might notice that the `Move` case doesn't actually make any changes other than modifying `r`, which is because it falls through to the next case, `Resize`, which then resizes the window according to the modified `r`.


The changes
-----------

The function arguments for `wctlcmd` don't contain any information about what specific flags were used in the command, so we have to either change `wctlcmd` to include this information for just this one case, or we infer the command options by comparing the new `Rectangle`, `r` and the dimensions of the `Window` `w`. I chose the latter, to avoid changing too much of the structure of the program.

Fig 2.
```
int
wctlcmd(Window *w, Rectangle r, int cmd, char *err)
{
	Image *i;
	Rectangle rd;

	switch(cmd){
	case Move:
		if(r.min.x != w->screenr.min.x) rd.min.x = 1; else rd.min.x = 0;
		if(r.max.x != w->screenr.max.x) rd.max.x = 1; else rd.max.x = 0;
		if(r.min.y != w->screenr.min.y) rd.min.y = 1; else rd.min.y = 0;
		if(r.max.y != w->screenr.max.y) rd.max.y = 1; else rd.max.y = 0;

		if(rd.min.x && rd.max.x || rd.min.y && rd.max.y) {
			strcpy(err, "max and min are mutually exclusive");
			return -1;
		}

		if(rd.min.x)							// Did the minimum x change?
			r.max.x = r.min.x+Dx(w->screenr);	// set max x to the min plus width
		else
			r.min.x = r.max.x-Dx(w->screenr);	// set min x to the max minus width

		if(rd.min.y)							// Did the minimum y change?
			r.max.y = r.min.y+Dy(w->screenr);	// set max y to the min plus width
		else
			r.min.y = r.max.y-Dy(w->screenr);	// set min y to the max minus width

		r = rectonscreen(r);
		/* fall through */
	case Resize:
```

My solution is a little clunkier than I'd like, but it works well enough and it's clear exactly what it does. It will mis-handle a move outside rio's bounds, potentially succeeding incorrectly, or mis-reporting the error `max and min are mutually exclusive`, but the solution would be more work than it's worth. First order of business is the new variable, `rd` of type `Rectangle`. Despite its type, `rd` does not represent a rectangle to be drawn, it represents whether the corresponding values of `r` and `w->screenr` differ. A check is performed to make sure the `min` and `max` values of the same axis haven't both changed, if they have, it returns an error to the calling function.

Then, it's just a matter of deciding which value to throw away and which to keep, much like in the original code, but this time, it can throw away either the `min` or `max`.


What this affords us
--------------------

I noticed this bug when I was making a script to maximize windows and it didn't behave correctly, so fixing this allows my script to work.

The script's name is simply `max` on my system. `max`, as seen in Fig 6, will maximize and move the window to the limits defined by the variable `rmargin`, which is expected to be defined prior to the execution of `max`. An example definition is as shown in Fig 4. This definition leaves a 161-pixel gap at the left, and a 1-pixel gap at the bottom and right side of the screen. So I have a stats(8), clock date(1), and winwatch(1) windows setup by riostart in the left margin, and that never changes. The 1-pixel margin around the bottom and right of the screen is for right-clicking to access the rio menu, which is sometimes handy.

In addition to `rmargin`, there's `sriomargin` which is for use if a sub-rio is spawned. For normal rio, the values should be as depicted in Fig 5.

Running `max` with no arguments will make the window as large as it can be while maintaining the margins. The flags `-l`, `-r`, `-u`, and `-d` bump the window up next to the leftmost, rightmost, uppermost, and lowermost limits, respectively. The `-v` and `-h` flags maximize the window vertically and horizontally, respectively. Running `max` with no arguments is the same as running `max -vh`.

The script itself is mostly self-explanatory. The section that contains the most magic is the definition of the `scr` variable, which invokes dd(1) on either `/dev/screen` if we're not running in a sub-rio, or `/mnt/orio/window` if we are. The fields of `/dev/screen` on my system are shown in Fig 3. It is imperative that we read only once and only the first 60 bytes, as we're reading the header of a larger image(6) file. It seems rio will only return the first 60 bytes even if your buffer is larger on the first read, but we only ask for 60 just to be safe. As such, cat(1), which reads indefinitely, is out of the question for this application.

We set the `ifs` to a single space to separate out the fields produced by dd(1). The fields we're interested in are fields 2-5, which, as described in draw(3), are `r.min.x, r.min.y, r.max.x, and r.max.y`. So we subtract our `maxx` and `maxy` margins from the values we got from `/dev/draw/new` to get the maximum limits. We do this by composing commands for bc(1) with echo and piping to `bc` and assigning the output to the variables `maxx` and `maxy` as rc(1) doesn't have builtin math facilities.

The reason we have a special case for sub-rios is because otherwise we would have no idea what size the rio we're running in is, and we would be passing errant values to rio. Both `/mnt/orio` and `sriomargin` come from the script I use for creating sub-rios conveniently, shown in Fig 7, so `/mnt/orio`, if it exists, will always be the parent rio, not the rio we're currently operating in.

Fig 3.
```
   x8r8g8b8           0           0        1600         900 
```

Fig 4.
```
rmargin=(161 0 1 1)
```

Fig 5.
```
sriomargin=(0 0 8 8)
```

Fig 6.
```
#!/bin/rc

rfork e

nl='
'
h=0
v=0
our=()
oum=()

argv0=$0

if(~ $#rmargin 0)
	rmargin=(0 0 0 0)
if(~ $#sriomargin 0)
	sriomargin=(0 0 0 0)

if(test -r /mnt/orio/window)
	ressrc='/mnt/orio/window'
if not
	ressrc='/dev/screen'
ifs=' ' scr=`{dd -if $ressrc -bs 60 -count 1 -quiet 1}
if(test $#scr -lt 5){
	echo 'failed to read resolution'
	exit 1
}
res=($scr(2) $scr(3) $scr(4) $scr(5))
minx=$rmargin(1)
miny=$rmargin(2)
# maxx = scr.max.x - scr.min.x - rmarg - rsriomarg
# maxy = scr.max.y - scr.min.y - bmarg - bsriomarg
maxx=`{echo $res(3) - $res(1) - $rmargin(3) - $sriomargin(3) | bc | tr -d $nl}
maxy=`{echo $res(4) - $res(2) - $rmargin(4) - $sriomargin(4) | bc | tr -d $nl}

nopts=$#*
flagfmt='h,v,l,r,t,b'
args=''
if(! ifs=() eval `{aux/getflags $*}){
	aux/usage
	exit usage
}

if(~ $nopts 0)
	our = `{echo $our -r $minx $miny $maxx $maxy}
if not {
	if(~ $#flagh 1)
		our = `{echo $our -minx $minx -maxx $maxx}
	if(~ $#flagv 1)
		our = `{echo $our -miny $miny -maxy $maxy}
	if(~ $#flagl 1)
		oum = `{echo $oum -minx $minx}
	if(~ $#flagr 1)
		oum = `{echo $oum -maxx $maxx}
	if(~ $#flagt 1)
		oum = `{echo $oum -miny $miny}
	if(~ $#flagb 1)
		oum = `{echo $oum -maxy $maxy}
}

if(! ~ $our '')
	echo resize $"our >>/dev/wctl
if(! ~ $oum '')
	echo move $"oum >>/dev/wctl
```

Fig 7.
```
#!/bin/rc

max

rfork e
bind /mnt/wsys /mnt/orio
rmargin=(20 0 0 0)
sriomargin=(0 0 8 8)
rio
```
include <math.h>
include <gset.h>
include <gim.h>
include "lris.h"
include "futil.h"

define	KEYSFILE	"ucsclris$lib/keys/simulator.key"

define		MASK_X0	107.95		# X-Center of mask (mm)
define		MASK_Y0	167.8  		# Y-Center of mask (mm)
define		XSENSE	+1.0		# X sense of mask coord system
define		YSENSE	-1.0		# Y sense of mask coord system

define		PA_INCR	1.		# PA Increment (deg) for p/n commands
define		TR_INCR	1.		# Translational Incr. (") for hjkl
define		SZ_INLN	132		# Maximum length of input line
define		SLITLEN 8.		# Slit length (") in disp. diagram
define		PRIMRY	1		# Primary object flag
define		SECDRY	2		# Secondary object flag
define		ALIGN	3		# Secondary object flag
define		SZ_ID	9		# Length of input ID field (char)

# Mode dependent:
define		MDEF_WD	480.		# Mask Default field width (arcsec)
define		LDEF_WD	250.		# Longslit Default field width (arcsec)
define		MDEF_XM	1.		# Mask Default x-magn factor
define		LDEF_XM	4.		# Longslit Default x-magn factor

# Mask specific:
#define		BAR_LOW	161.3		# Lower Bar Y (mm)
#define		BAR_UPP	169.4		# Upper Bar Y (mm)
define		BAR_LOW	164.6		# Lower Bar Y (mm)
define		BAR_UPP	171.0		# Upper Bar Y (mm)
define		MIR_X0	46.3		# Mirror offset along Bar X (mm)
define		MIR_Y0	-21.0		# Mirror (#2) offset from Bar Y (mm)
define		MIR_XSZ	22.9		# Mirror size in X (mm)
define		MIR_YSZ	22.9		# Mirror size in Y (mm)

# Longslit specific:
define		SLIT_Y1	80		# Lower Y-limit to slit (mm)
define		SLIT_Y2	240		# Upper Y-limit to slit (mm)

define		NLIMITS	34		# number of limit parameters following
define		CX1	$1[1]		# CCD Lower X-limit (" rel. center)
define		CY1	$1[2]		# CCD Lower Y-limit (" rel. center)
define		CX2	$1[3]		# CCD Upper X-limit (" rel. center)
define		CY2	$1[4]		# CCD Upper Y-limit (" rel. center)
define		MX1	$1[5]		# Mask Lower X-limit (" rel. center)
define		MY1	$1[6]		# Mask Lower Y-limit (" rel. center)
define		MX2	$1[7]		# Mask Upper X-limit (" rel. center)
define		MY2	$1[8]		# Mask Upper Y-limit (" rel. center)
define		BY1	$1[9]		# Bar Lower Y (" rel. center)
define		BY2	$1[10]		# Bar Upper Y (" rel. center)
define		GX1	$1[11]		# Guider Lower X-limit (" rel. center)
define		GY1	$1[12]		# Guider Lower Y-limit (" rel. center)
define		GX2	$1[13]		# Guider Upper X-limit (" rel. center)
define		GY2	$1[14]		# Guider Upper Y-limit (" rel. center)
define		X1	$1[15]		# Eff. Lower X-limit (" rel. center)
define		Y1	$1[16]		# Eff. Lower Y-limit (" rel. center)
define		X2	$1[17]		# Eff. Upper X-limit (" rel. center)
define		Y2	$1[18]		# Eff. Upper Y-limit (" rel. center)
define		DISP1	$1[19]		# Starting dispersion (")
define		DISP2	$1[20]		# Ending dispersion (")
define		PA1	$1[21]		# Starting Disp. PA (deg)
define		PA2	$1[22]		# Ending Disp. PA (deg)
define		ELEV_1	$1[23]		# Starting Dewar Elevation (deg)
define		ELEV_2	$1[24]		# Ending Dewar Elevation (deg)
define		SLITWID	$1[25]		# Width of slit (")
define		MINSLIT	$1[26]		# Slit length in plot (")
define		ERR_LOW	$1[27]		# If non-zero, service tower conflict
define		ERR_LN2	$1[28]		# If non-zero, LN2 spillage
define		PL_XMAG	$1[29]		# Xmag in plot (default 1)
define		PL_FWID	$1[30]		# Field width (")
define		MIR_X1	$1[31]		# Mirror Lower X-limit (" rel. center)
define		MIR_X2	$1[32]		# Mirror Upper X-limit (" rel. center)
define		MIR_Y1	$1[33]		# Mirror Lower Y-limit (" rel. center)
define		MIR_Y2	$1[34]		# Mirror Upper Y-limit (" rel. center)

# T_SIMULATOR: LRIS simulator; formerly...
#    T_MSSELECT: Multi-slit select; formerly ...
#    T_AUTOSLUT: Because it panders to AUTOSLIT (and it's user friendly, too)
#
# Note on Coord system:
# The x axis is parallel to the slit-mask-punch x-axis (ie neg fp-coord system)
# The y-axis is anti-parallel to the slit-punch y-axis (ie pos fp-coord system)
# This produces an image as seen on the CCD
# All coords relevant to the mask (mask, bar, pickoff mirrors) are given in
# slit-punch coords (mm).
# All displayed coords are in arc-sec, with a Mercator-style dec value
# (normalized to the central dec value).

procedure t_simulator()

# Updates
# -- New format (slit top/bottom)
# -- CENTER line in input
# -- Alignment/Guide star select

# These all need to be incorporated:
# -- Spectral range			# (done) get accurate CCD pos.
# -- Bar				# Done
# -- Checks on PA (for LN2 spillage)	# Done
# -- Check on dispersion angle		# Done
# -- Check on tower exclusion		# Done
# -- Punch machine x-limit		# done
# -- Guide star possibilities		# (done) get box location

# Current approximations:
# -- edges are straight (ie won't work at pole)
# -- All coord. epochs are current

# Needs to have the following options:
# -- Change field center		# Y
# -- Change PA				# Y
# -- Add/delete objects			# (Y)
# -- provide info on particular objects # (Y)
# -- set size of viewing region		# Y

bool	long_slit_mode
char	objfile[SZ_FNAME]			# ID, prior, mag, RA, Dec
char	other[SZ_FNAME]				# ID, prior, mag, RA, Dec
char	output[SZ_FNAME]			# Output file name
char	remain[SZ_FNAME]			# Output list of remaining obj.
double	dra0, ddec0				# Coords. of field center
double	equinox					# Equinox of Coords
real	limit[NLIMITS]
pointer	fda, fdb, fdc, fdd

char	tchar
double	dra, ddec
double	cosd, cosd0
char	id[SZ_ID]
int	priority
real	magn, center
int	i
int	npt, ndx
real	x1, x2, y1, y2
real	wave1, wave2, disp, woff
real	ha1, ha2
real	dec, lat, pa, atmdisp, slit, z1, z2, az1, az2
real	xoff, yoff, theta
pointer	bufx, bufy, bufxt, bufyt, buff, bufin, bufp
real	slitbot, slittop
pointer	bufpa, bufs1, bufs2		# PA, slit_below, slit_above

real	chk_elev()

bool	clgetb(), strne(), streq()
double	clgetd()
real	clgetr()
int	fscan(), nscan()
pointer	open()

begin
	call clgstr ("objfile", objfile, SZ_FNAME)
	call clgstr ("other_obj", other, SZ_FNAME)
	call clgstr ("output", output, SZ_FNAME)
	call clgstr ("remain", remain, SZ_FNAME)
	ha1 = clgetr ("ha")
	ha2 = clgetr ("exposure") + ha1			# Ending HA
	slit = clgetr ("slit")
	wave1 = clgetr ("blue")
	wave2 = clgetr ("red")
	disp = clgetr ("dispersion")
	long_slit_mode = clgetb ("long_slit_mode")

	if (!long_slit_mode) {
		x1 = clgetr ("x1")
		x2 = clgetr ("x2")
		y1 = clgetr ("y1")
		y2 = clgetr ("y2")
		woff = 0.5 * abs (wave2-wave1) / disp
	} else {
		woff = 0.
	}

# Open the primary file; check for CENTER specifications
        fda = open (objfile, READ_ONLY, TEXT_FILE)
	while (fscan(fda) != EOF) {
		call gargwrd (tchar, 1)
		if (tchar == '#' || nscan() == 0) {
			next
		}
		call reset_scan()

		call gargwrd (id, SZ_ID)
		if (streq (id, "CENTER")) {
#	if present, get info
			call gargi (priority)
			call gargd (equinox)
			call gargd (dra0)
			call gargd (ddec0)
			call gargr (theta)
			if (nscan() < 6 || theta == INDEF)
				theta = 0.
			if (nscan() >= 5) {
			    call printf ("Field Center, Eqx. from Input File\n")
			    break
			} else {
			    call eprintf ("Incorrect CENTER specification\n")
			}
		}
#	otherwise get from parameters (forced)
		dra0 = clgetd ("ra0")
		ddec0 = clgetd ("dec0")
		equinox = clgetd ("equinox")
		theta = clgetr ("PA")
		break
	}
	call seek (fda, BOF)

# Set the limits (mostly from definitions above), in image coord space
# CCD:
	CX1(limit) = (1 - CCD_X0 + woff) * ASECPPX
	CX2(limit) = (CCD_NX - CCD_X0 - woff) * ASECPPX
	CY1(limit) = (1 - CCD_Y0) * ASECPPX 
	CY2(limit) = (CCD_NY - CCD_Y0) * ASECPPX 
# Guider:
	GX1(limit) = (GUID_X1 - MASK_X0) * ASECPMM
	GX2(limit) = (GUID_X2 - MASK_X0) * ASECPMM
	GY1(limit) = (GUID_Y1 - MASK_Y0) * ASECPMM 
	GY2(limit) = (GUID_Y2 - MASK_Y0) * ASECPMM 

	if (long_slit_mode) {
# Longslit (treat as mask):
		MX1(limit) = -0.5 * slit
		MX2(limit) =  0.5 * slit
		if (YSENSE > 0.) {
			MY1(limit) = (SLIT_Y1 - MASK_Y0) * ASECPMM 
			MY2(limit) = (SLIT_Y2 - MASK_Y0) * ASECPMM 
		} else {
			MY2(limit) = -(SLIT_Y1 - MASK_Y0) * ASECPMM 
			MY1(limit) = -(SLIT_Y2 - MASK_Y0) * ASECPMM 
		}
# Bar and pick-off mirror (not there!)
		BY1(limit) =  GY1 (limit)
		BY2(limit) =  GY1 (limit)
		MIR_X1(limit) = GX1 (limit)
		MIR_X2(limit) = GX1 (limit)
		MIR_Y1(limit) = GY1 (limit)
		MIR_Y2(limit) = GY1 (limit)
	} else {
# Slit mask:
		if (XSENSE > 0.) {
			MX1(limit) = (x1 - MASK_X0) * ASECPMM
			MX2(limit) = (x2 - MASK_X0) * ASECPMM
		} else {
			MX2(limit) = -(x1 - MASK_X0) * ASECPMM
			MX1(limit) = -(x2 - MASK_X0) * ASECPMM
		}
		if (YSENSE > 0.) {
			MY1(limit) = (y1 - MASK_Y0) * ASECPMM 
			MY2(limit) = (y2 - MASK_Y0) * ASECPMM 
			BY1(limit) = (BAR_LOW - MASK_Y0) * ASECPMM 
			BY2(limit) = (BAR_UPP - MASK_Y0) * ASECPMM 
		} else {
			MY2(limit) = -(y1 - MASK_Y0) * ASECPMM 
			MY1(limit) = -(y2 - MASK_Y0) * ASECPMM 
			BY2(limit) = -(BAR_LOW - MASK_Y0) * ASECPMM 
			BY1(limit) = -(BAR_UPP - MASK_Y0) * ASECPMM 
		}
# Slit-viewing Pickoff mirror location:
		center = XSENSE * MIR_X0
		MIR_X1(limit) = (center - 0.5*MIR_XSZ) * ASECPMM
		MIR_X2(limit) = MIR_X1(limit) + MIR_XSZ * ASECPMM
		center = (BY1(limit) + BY2(limit)) * 0.5 + MIR_Y0
		MIR_Y1(limit) = (center - 0.5*MIR_YSZ) * ASECPMM
		MIR_Y2(limit) = MIR_Y1(limit) + MIR_YSZ * ASECPMM
	}

# Effective slit limits:
	X1(limit) = max (CX1(limit), MX1(limit))
	Y1(limit) = max (CY1(limit), MY1(limit))
	X2(limit) = min (CX2(limit), MX2(limit))
	Y2(limit) = min (CY2(limit), MY2(limit))

# Dispersion info:
	dec = real (ddec0)
	lat = OBS_LAT
	call atm_geom (ha1, dec, wave1, wave2, lat, z1, az1, pa, atmdisp)
	PA1(limit) = pa
	DISP1(limit) = atmdisp
	call atm_geom (ha2, dec, wave1, wave2, lat, z2, az2, pa, atmdisp)
	PA2(limit) = pa
	DISP2(limit) = atmdisp
	if (dec > lat) {
	    if (az1 > 180.)
		az1 = az1 - 360.
	    if (az2 > 180.)
		az2 = az2 - 360.
	} else {
	    if (az1 < 0.) 
		az1 = az1 + 360.
	    if (az2 < 0.) 
		az2 = az2 + 360.
	}
	SLITWID(limit) = slit

# Check limits:
	ERR_LOW(limit) = chk_elev (az1, z1, az2, z2)
	ERR_LN2(limit) = 0.
	if (ERR_LOW(limit) != 0.)
		call printf ("Potential Service Tower/Shutter conflict!\n")

# Initial plot limits:
	if (long_slit_mode) {
		PL_FWID(limit) = LDEF_WD
		PL_XMAG(limit) = LDEF_XM
	} else {
		PL_FWID(limit) = MDEF_WD
		PL_XMAG(limit) = MDEF_XM
	}
	MINSLIT(limit) = clgetr ("min_slit")

# Count the primary list (already open) and the secondary list if present
	npt = 0
	while (fscan(fda) != EOF)
		npt = npt + 1
	call seek (fda, BOF)

	if (strne (other, "")) {
        	fdb = open (other, READ_ONLY, TEXT_FILE)
		while (fscan(fdb) != EOF)
			npt = npt + 1
		call seek (fdb, BOF)
	}

# Allocate memory
	call malloc (bufx, npt, TY_REAL)
	call malloc (bufy, npt, TY_REAL)
	call malloc (bufxt, npt, TY_REAL)
	call malloc (bufyt, npt, TY_REAL)
	call malloc (bufp, npt, TY_INT)			# priority
	call malloc (bufpa, npt, TY_REAL)		# PA
	call malloc (bufs1, npt, TY_REAL)		# slit len below
	call malloc (bufs2, npt, TY_REAL)		# slit len above
	call malloc (buff, npt, TY_INT)			# flag
	call malloc (bufin, npt*SZ_INLN, TY_CHAR)
	call amovkc (EOS, Memc[bufin], npt*SZ_INLN)

# Get the primary list (avoid center if present)
	ndx = 0
	cosd0 = cos (DEGTORAD (ddec0))
	while (fscan(fda) != EOF) {
		call gargwrd (tchar, 1)
		if (tchar == '#' || nscan() == 0) {
			next
		}
		call reset_scan()
		call gargwrd (id, SZ_ID)
		if (ndx == 0 && streq (id, "CENTER"))
			next
		call gargi (priority)
		call gargr (magn)
		call gargd (dra)
		call gargd (ddec)

		if (nscan() < 5) {
		    call eprintf ("Poorly-formatted data line %d -- skipped\n")
			call pargi (ndx+1)
		    next
		}
		cosd = cos (DEGTORAD (ddec))
		Memr[bufx+ndx] = (ddec - ddec0) * 3600. * cosd0 / cosd
		Memr[bufy+ndx] = (dra - dra0) * 15. * 3600. * cosd
		Memi[bufp+ndx] = priority

		call gargr (pa)
		call gargr (slitbot)
		call gargr (slittop)

		if (nscan() < 6) {
			pa = INDEF
		}
		if (nscan() < 7 || slitbot <= 0. || slitbot == INDEF)
			slitbot = MINSLIT(limit) * 0.5
		if (nscan() < 8 || slittop <= 0. || slittop == INDEF)
			slittop = MINSLIT(limit) * 0.5
		Memr[bufpa+ndx] = pa
		Memr[bufs1+ndx] = slitbot
		Memr[bufs2+ndx] = slittop
		
		call reset_scan()
		call gargstr (Memc[bufin+ndx*SZ_INLN], SZ_INLN)
		if (priority >= 0)
			Memi[buff+ndx] = -1 * PRIMRY
		else
			Memi[buff+ndx] = -1 * ALIGN
		ndx = ndx + 1
	}
	call close (fda)

# Get the secondary list:
	if (strne (other, "")) {
	    while (fscan(fdb) != EOF) {
		call gargwrd (tchar, 1)
		if (tchar == '#' || nscan() == 0) {
			next
		}
		call reset_scan()
		call gargwrd (id, SZ_ID)
		call gargi (priority)
		call gargr (magn)
		call gargd (dra)
		call gargd (ddec)

		if (nscan() < 5) {
		    call eprintf ("Poorly-formatted data line %d -- skipped\n")
			call pargi (ndx+1)
		    next
		}
		cosd = cos (DEGTORAD (ddec))
		Memr[bufx+ndx] = (ddec - ddec0) * 3600. * cosd0 / cosd
		Memr[bufy+ndx] = (dra - dra0) * 15. * 3600. * cosd
		Memi[bufp+ndx] = priority

		call gargr (pa)
		call gargr (slitbot)
		call gargr (slittop)

		if (nscan() < 6) {
			pa = INDEF
		}
		if (nscan() < 7 || slitbot <= 0. || slitbot == INDEF)
			slitbot = MINSLIT(limit) * 0.5
		if (nscan() < 8 || slittop <= 0. || slittop == INDEF)
			slittop = MINSLIT(limit) * 0.5
		Memr[bufpa+ndx] = pa
		Memr[bufs1+ndx] = slitbot
		Memr[bufs2+ndx] = slittop
		
		call reset_scan()
		call gargstr (Memc[bufin+ndx*SZ_INLN], SZ_INLN)
		if (priority >= 0)
			Memi[buff+ndx] = -1 * SECDRY
		else
			Memi[buff+ndx] = -1 * ALIGN
		ndx = ndx + 1
	    }
	    call close (fdb)
	}

	npt = ndx

# Open the output file
	if (strne (output, ""))
        	fdc = open (output, NEW_FILE, TEXT_FILE)
	if (strne (remain, ""))
        	fdd = open (remain, NEW_FILE, TEXT_FILE)

	call focpl_graph (Memr[bufx], Memr[bufy], Memr[bufxt], Memr[bufyt],
		Memr[bufpa], Memr[bufs1], Memr[bufs2], Memi[bufp], Memi[buff],
		npt, limit, dec, ha1, ha2, theta, xoff, yoff, bufin)

	ddec = ddec0 + xoff/3600.
	cosd = cos (DEGTORAD (ddec))
	dra = dra0 + yoff/3600./15. / cosd

	call printf ("\n\nField center: %11.1h %11.0h,  PA: %5.1f\n\n")
		call pargd (dra)
		call pargd (ddec)
		call pargr (theta)
	call printf ("Geometry: z1 = %4.1f (az%4.0f), z2 = %4.1f (az%4.0f)\n")
		call pargr (z1)
		call pargr (az1)
		call pargr (z2)
		call pargr (az2)
	call printf ("Dispersion: %5.2f'' @%6.1f deg --%5.2f'' @%6.1f deg\n\n")
		call pargr (DISP1(limit))
		call pargr (PA1(limit))
		call pargr (DISP2(limit))
		call pargr (PA2(limit))
	call printf ("Dewar elevation: %5.1f (start)  %5.1f (end)\n")
		call pargr (ELEV_1(limit))
		call pargr (ELEV_2(limit))

	if (ERR_LOW(limit) == 1.)
		call printf ("PROBLEM: Service Tower Conflict\n")
	if (ERR_LOW(limit) == 2.)
		call printf ("PROBLEM: Occulted by Shutter\n")
	if (ERR_LN2(limit) != 0.)
		call printf ("PROBLEM: PA May Cause LN2 Spillage\n")

# If output file specified, copy same info.
	if (strne (output, "")) {
	    call fprintf (fdc,
		"#\n#\n# Field center: %11.1h %11.0h,  PA: %7.3f\n#\n")
		call pargd (dra)
		call pargd (ddec)
		call pargr (theta)
	    call fprintf (fdc,
		"# Geometry: z1 = %4.1f (az%4.0f), z2 = %4.1f (az%4.0f)\n")
		call pargr (z1)
		call pargr (az1)
		call pargr (z2)
		call pargr (az2)
	    call fprintf (fdc,
		"# Dispersion: %5.2f'' @%6.1f deg --%5.2f'' @%6.1f deg\n#\n")
		call pargr (DISP1(limit))
		call pargr (mod (PA1(limit), 180.))
		call pargr (DISP2(limit))
		call pargr (mod (PA2(limit), 180.))
	    call fprintf (fdc,
			"# Dewar elevation: %5.1f (start)  %5.1f (end)\n")
		call pargr (ELEV_1(limit))
		call pargr (ELEV_2(limit))

	    if (ERR_LOW(limit) == 1.)
		call fprintf (fdc, "# PROBLEM: Service Tower Conflict\n")
	    if (ERR_LOW(limit) == 2.)
		call fprintf (fdc, "# PROBLEM: Occulted by Shutter\n")
	    if (ERR_LN2(limit) != 0.)
		call fprintf (fdc, "# PROBLEM: PA May Cause LN2 Spillage\n")
	}
	
# Output list to file or STDOUT:
	if (strne (output, "")) {
	    call fprintf (fdc, "\nCENTER   9999 %7.2f %11.2h %11.1h %5.1f\n")
		call pargd (equinox)
		call pargd (dra)
		call pargd (ddec)
		call pargr (theta)
	    do i = 0, npt-1 {
		if (Memi[buff+i] > 0) {
		    call fprintf (fdc, "%s\n")
			call pargstr (Memc[bufin+i*SZ_INLN])
		}
	    }
	    call close (fdc)
	} else {
	    call printf ("\nCENTER   9999 %7.2f %11.2h %11.1h %5.1f\n")
		call pargd (equinox)
		call pargd (dra)
		call pargd (ddec)
		call pargr (theta)
	    do i = 0, npt-1 {
		if (Memi[buff+i] > 0) {
		    call printf ("%s\n")
			call pargstr (Memc[bufin+i*SZ_INLN])
		}
	    }
	}

# If remainder file specified, write out unused objects
	if (strne (remain, "")) {
	    do i = 0, npt-1 {
		if (Memi[buff+i] < 0) {
		    call fprintf (fdd, "%s\n")
			call pargstr (Memc[bufin+i*SZ_INLN])
		}
	    }
	    call close (fdd)
	}

	call mfree (bufin, TY_CHAR)
	call mfree (bufp, TY_INT)
	call mfree (buff, TY_INT)
	call mfree (bufs2, TY_REAL)
	call mfree (bufs1, TY_REAL)
	call mfree (bufpa, TY_REAL)
	call mfree (bufyt, TY_REAL)
	call mfree (bufxt, TY_REAL)
	call mfree (bufy, TY_REAL)
	call mfree (bufx, TY_REAL)
end

procedure	focpl_graph (x, y, xt, yt, pa, sl1, sl2, pri, flag, npt, limit,
					dec, ha1, ha2, theta, xoff, yoff, bufin)

real	x[npt], y[npt]			# Relative coords.
int	pri[npt]			# Selection priorities
real	xt[npt], yt[npt]		# Relative coords.
real	pa[npt]				# PA of object
real	sl1[npt], sl2[npt]		# Slit length below, above objects
int	flag[npt]			# Codes for objects
int	npt				# Number of objects
real	limit[NLIMITS]			# limit parameter list
real	dec, ha1, ha2			# dec (deg), start and end HA (hr)
real	theta				# PA of mask
real	xoff, yoff			# relative offsets (arcsec) (returned)
pointer	bufin				# POINTER to information string

char	id[SZ_ID]		 	# ID string
int	i
real	sinp, cosp
real	anginc, xyinc, speed
int	nslit, psum
real	stats[NFITPAR]			# structure for fitting
pointer	bufw				# weights for fitting

char	command[32]			# not sure if 32 is good
int	wcs, key
real	wx, wy
pointer	gp

real	dewar_elev(), vsum1()
pointer	gopen()
int	clgcur(), get_nearest()
real	clgetr()

begin
# Initialize plot
	xoff = 0.
	yoff = 0.

	speed = 10.
	anginc = PA_INCR * speed
	xyinc = TR_INCR * speed

# Work out dewar elevation
	ELEV_1(limit) = dewar_elev (ha1, dec, theta+90., OBS_LAT, CAM_ANG)
	ELEV_2(limit) = dewar_elev (ha2, dec, theta+90., OBS_LAT, CAM_ANG)
	ERR_LN2(limit) = 0.
	if (ELEV_1(limit) < 0. || ELEV_2(limit) < 0.)
		ERR_LN2(limit) = 1.

# Open the graphics stream
	gp = gopen ("stdgraph", NEW_FILE, STDGRAPH)

# Transform the coords
	cosp = cos (DEGTORAD (90.-theta))
	sinp = sin (DEGTORAD (90.-theta))
	do i = 1, npt {
		xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
		yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
	}
	
# Plot the data
	call focpl_layout (gp, xt, yt, pa, sl1, sl2, flag, npt, limit, theta)

	while ( clgcur("coord", wx, wy, wcs, key, command, 32) != EOF ) {

	    if (key == 'q') {
		break
	    }

	    switch (key) {			# NB note TWO switch cases!

		case 'c':
			xoff = xoff + wx * cosp + wy * sinp
			yoff = yoff - wx * sinp + wy * cosp
			do i = 1, npt {
				xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
				yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
			}
			
		case 'h':
			xoff = xoff + (xyinc) * cosp + (0.) * sinp
			yoff = yoff - (xyinc) * sinp + (0.) * cosp
			do i = 1, npt {
				xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
				yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
			}
			
		case 'j':
			xoff = xoff + (0.) * cosp + (xyinc) * sinp
			yoff = yoff - (0.) * sinp + (xyinc) * cosp
			do i = 1, npt {
				xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
				yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
			}
			
		case 'k':
			xoff = xoff + (0.) * cosp + (-xyinc) * sinp
			yoff = yoff - (0.) * sinp + (-xyinc) * cosp
			do i = 1, npt {
				xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
				yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
			}
			
		case 'l':
			xoff = xoff + (-xyinc) * cosp + (0.) * sinp
			yoff = yoff - (-xyinc) * sinp + (0.) * cosp
			do i = 1, npt {
				xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
				yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
			}
			
		case 'a':
			theta = clgetr ("PA")
			cosp = cos (DEGTORAD (90.-theta))
			sinp = sin (DEGTORAD (90.-theta))
			do i = 1, npt {
				xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
				yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
			}
			ELEV_1(limit) = dewar_elev (ha1, dec, theta+90.,
							OBS_LAT, CAM_ANG)
			ELEV_2(limit) = dewar_elev (ha2, dec, theta+90.,
							OBS_LAT, CAM_ANG)
			ERR_LN2(limit) = 0.
			if (ELEV_1(limit) < 0. || ELEV_2(limit) < 0.)
				ERR_LN2(limit) = 1.

			
		case 'p':
			theta = theta + anginc
			cosp = cos (DEGTORAD (90.-theta))
			sinp = sin (DEGTORAD (90.-theta))
			do i = 1, npt {
				xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
				yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
			}
			ELEV_1(limit) = dewar_elev (ha1, dec, theta+90.,
							OBS_LAT, CAM_ANG)
			ELEV_2(limit) = dewar_elev (ha2, dec, theta+90.,
							OBS_LAT, CAM_ANG)
			ERR_LN2(limit) = 0.
			if (ELEV_1(limit) < 0. || ELEV_2(limit) < 0.)
				ERR_LN2(limit) = 1.

		case 'n':
			theta = theta - anginc
			cosp = cos (DEGTORAD (90.-theta))
			sinp = sin (DEGTORAD (90.-theta))
			do i = 1, npt {
				xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
				yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
			}
			ELEV_1(limit) = dewar_elev (ha1, dec, theta+90.,
							OBS_LAT, CAM_ANG)
			ELEV_2(limit) = dewar_elev (ha2, dec, theta+90.,
							OBS_LAT, CAM_ANG)
			ERR_LN2(limit) = 0.
			if (ELEV_1(limit) < 0. || ELEV_2(limit) < 0.)
				ERR_LN2(limit) = 1.

		case 'f':
# Fit all good points; here set weights and check for 2 or more points
			call calloc (bufw, npt, TY_REAL)
			do i = 1, npt {
				if (flag[i] > 0)
					Memr[bufw+i-1] = 1.
			}
			if (vsum1 (Memr[bufw], npt) < 2.) {
				call eprintf ("Select more points\g\n")
				next
			}
# Work out as increments, to preserve the approx. PA and centering;
# note the inverted coord system, ie, the reversal of xt, yt 
			call get_0lsqf1 (yt, xt, Memr[bufw], npt, stats)
			call mfree (bufw, TY_REAL)

			xoff = xoff + YINCPT(stats) * cosp
			yoff = yoff - YINCPT(stats) * sinp
			theta = theta - RADTODEG (atan (SLOPE(stats)))
			cosp = cos (DEGTORAD (90.-theta))
			sinp = sin (DEGTORAD (90.-theta))
			do i = 1, npt {
				xt[i] = (x[i]-xoff) * cosp - (y[i]-yoff) * sinp
				yt[i] = (x[i]-xoff) * sinp + (y[i]-yoff) * cosp
			}
			ELEV_1(limit) = dewar_elev (ha1, dec, theta+90.,
							OBS_LAT, CAM_ANG)
			ELEV_2(limit) = dewar_elev (ha2, dec, theta+90.,
							OBS_LAT, CAM_ANG)
			ERR_LN2(limit) = 0.
			if (ELEV_1(limit) < 0. || ELEV_2(limit) < 0.)
				ERR_LN2(limit) = 1.

		case 'g':
			do i = 1, npt {
			    if (xt[i] < X1(limit) || xt[i] > X2(limit) ||
				yt[i] < Y1(limit) || yt[i] > Y2(limit)) {
				next
			    }
			    if (abs (flag[i]) == PRIMRY || abs (flag[i]) == ALIGN)
				flag[i] = abs (flag[i])
			}

		case 'i':
			do i = 1, npt
				flag[i] = -abs (flag[i])

		case 't':
			i = get_nearest (gp, xt, yt, npt, wx, wy, wcs)
			flag[i] = -flag[i]
#			call gmark (gp, xt[i], yt[i], GM_CIRCLE, 3.0, 3.0)
			call gmark (gp, xt[i], yt[i], GM_CIRCLE, -2.*sl1[i], -2.*sl2[i])

		case 'w':
			PL_FWID(limit) = clgetr ("width")
	    }

	    switch (key) {

		case 'r','c','h','j','k','l','a','p','n','f','g','i','w':
			call focpl_layout (gp, xt, yt, pa, sl1, sl2, flag, npt, limit, theta)

		case 's':
			do i = 1, npt
				flag[i] = -abs (flag[i])
			call selector (xt, yt, pri, flag, npt, limit,
								MINSLIT(limit))
			nslit = 0
			psum = 0.
			do i = 1, npt {
				if (flag[i] > 0) {
					nslit = nslit + 1
					psum = psum + pri[i]
				}
			}
			call focpl_layout (gp, xt, yt, pa, sl1, sl2, flag, npt, limit, theta)
			call eprintf ("Nslit = %d;  Summed priority = %d")
			call pargi (nslit)
			call pargi (psum)

		case '.':
			speed = speed / 10.
			if (speed < 0.1)
				speed = 10.
			anginc = PA_INCR * speed
			xyinc = TR_INCR * speed

		case 'x':
			do i = 1, npt {
			   call amovkc (" ", id, SZ_ID+1)
			   call strcpy (Memc[bufin+(i-1)*SZ_INLN], id[2], SZ_ID)
			   call gtext (gp, xt[i], yt[i], id, "h=l;v=c;q=h;s=0.55")
			}

		case ' ':
			i = get_nearest (gp, xt, yt, npt, wx, wy, wcs)
			call eprintf ("%s")			# TMP!!
			    call pargstr (Memc[bufin+(i-1)*SZ_INLN], SZ_INLN)

		case '?':
		    call gpagefile (gp, KEYSFILE, "simulator cursor commands")

		case 'I':
			call fatal (0, "INTERRUPT")
	    }
	}

	call gclose (gp)
end

procedure	focpl_layout (gp, xt, yt, pa, sl1, sl2, flag, npt, limit, theta)

pointer	gp				# graphics description
real	xt[npt], yt[npt]		# Coords.
real	pa[npt]				# PA of object
real	sl1[npt], sl2[npt]		# Slit length below, above objects
int	flag[npt]			# Codes for objects
int	npt				# Number of objects
real	limit[NLIMITS]			# limit parameter list
real	theta				# PA

char	title[SZ_LINE]
int	i
real	x1, x2, y1, y2, x0, y0, padisp, dmag
real	x, y
real	cosp, sinp
real	gx1, gx2, gy1, gy2
real	hbox				# box half-width (arcsec)

real	delt
real	aspect
real	ggetr()

begin
	theta = mod (theta+360., 360.)
	if (theta > 180.)
		theta = theta - 360.

	hbox = PL_FWID(limit) / 2.

	gx1 = -hbox / PL_XMAG(limit)
	gx2 =  hbox / PL_XMAG(limit)
	gy1 = -hbox
	gy2 =  hbox

	call gclear (gp)
	
# get the aspect ratio for the device, so that squares are square.
	aspect = ggetr (gp, "ar")

	call gsview (gp, (0.5-0.49*aspect), (0.5+0.49*aspect), 0.01, 0.99)
#	call gsview (gp, 0.01, 0.99, 0.01, 0.99)
	call gswind (gp, gx1, gx2, gy1, gy2)

#	call glabax (gp, title, "", "")

	if (X1(limit) < X2(limit)) {
		call gseti (gp, G_PLTYPE, GL_SOLID)
		call gseti (gp, G_PLCOLOR, YELLOW)
	} else {
		call gseti (gp, G_PLTYPE, GL_DOTTED)
		call gseti (gp, G_PLCOLOR, RED)
	}

	call gamove (gp, X1(limit), Y1(limit))
	call gadraw (gp, X1(limit), Y2(limit))
	call gadraw (gp, X2(limit), Y2(limit))
	call gadraw (gp, X2(limit), Y1(limit))
	call gadraw (gp, X1(limit), Y1(limit))

	call gseti (gp, G_PLCOLOR, YELLOW)
	call gseti (gp, G_PLTYPE, GL_DOTTED)
# CCD limits not currently shown
#	call gamove (gp, CX1(limit), CY1(limit))
#	call gadraw (gp, CX1(limit), CY2(limit))
#	call gadraw (gp, CX2(limit), CY2(limit))
#	call gadraw (gp, CX2(limit), CY1(limit))
#	call gadraw (gp, CX1(limit), CY1(limit))

	call gamove (gp, MX1(limit), MY1(limit))
	call gadraw (gp, MX1(limit), MY2(limit))
	call gadraw (gp, MX2(limit), MY2(limit))
	call gadraw (gp, MX2(limit), MY1(limit))
	call gadraw (gp, MX1(limit), MY1(limit))

	call gamove (gp, MX1(limit), BY1(limit))
	call gadraw (gp, MX2(limit), BY1(limit))
	call gamove (gp, MX1(limit), BY2(limit))
	call gadraw (gp, MX2(limit), BY2(limit))

	call gamove (gp, MIR_X1(limit), MIR_Y1(limit))
	call gadraw (gp, MIR_X1(limit), MIR_Y2(limit))
	call gadraw (gp, MIR_X2(limit), MIR_Y2(limit))
	call gadraw (gp, MIR_X2(limit), MIR_Y1(limit))
	call gadraw (gp, MIR_X1(limit), MIR_Y1(limit))

	call gamove (gp, GX1(limit), GY1(limit))
	call gadraw (gp, GX1(limit), GY2(limit))
	call gadraw (gp, GX2(limit), GY2(limit))
	call gadraw (gp, GX2(limit), GY1(limit))
	call gadraw (gp, GX1(limit), GY1(limit))
	call gseti (gp, G_PLTYPE, GL_SOLID)
	
# Mark the field center:
	call gmark (gp, 0., 0., GM_CIRCLE, 2., 2.)
	call gmark (gp, 0., 0., GM_CROSS, 1.4, 1.4)

	do i = 1, npt {
		if (pa[i] == INDEF) {
			x1 = 0.
			x2 = 0.
			y1 = sl1[i]
			y2 = sl2[i]
		} else {
			delt = -(pa[i] - theta)
			x1 = sl1[i] * sin (DEGTORAD(delt))
			x2 = sl2[i] * sin (DEGTORAD(delt))
			y1 = sl1[i] * cos (DEGTORAD(delt))
			y2 = sl2[i] * cos (DEGTORAD(delt))
		}
			
		if (flag[i] > 0) {
		    call gseti (gp, G_PLCOLOR, WHITE)
		    call gamove (gp, MX1(limit)-8.-0.005*xt[i], yt[i]-sl1[i])
		    call gadraw (gp, MX1(limit)-8.-0.005*xt[i], yt[i]+sl2[i])
		    if (flag[i] == PRIMRY) {
			call gmark (gp, xt[i], yt[i], GM_BOX, 1., 1.)
		    } else {
			call gmark (gp, xt[i], yt[i], GM_DIAMOND, 1.,1.)
		    }
		} else {
		    if (abs (flag[i]) == PRIMRY) {
			call gseti (gp, G_PLCOLOR, CYAN)
			call gmark (gp, xt[i], yt[i], GM_HLINE, 1., 1.)
		    } else if (abs (flag[i]) == SECDRY) {
			call gseti (gp, G_PLCOLOR, GREEN)
		    } else if (abs (flag[i]) == ALIGN) {
			call gseti (gp, G_PLCOLOR, MAGENTA)
		    }
		}
		call gamove (gp, xt[i]-x1, yt[i]-y1)
		call gadraw (gp, xt[i]+x2, yt[i]+y2)
	}

	call gseti (gp, G_PLCOLOR, 1)

# Set up transformation:
	cosp = cos (DEGTORAD (90.-theta)) 
	sinp = sin (DEGTORAD (90.-theta))

# Draw the compass rose:
	x0 = 0.82*gx2
	y0 = 0.74*hbox
	call gamove (gp, x0, y0)
	x =  0.05*hbox * cosp / PL_XMAG(limit)
	y =  0.05*hbox * sinp
	call grdraw (gp, x, y)
	call gtext (gp, x0+1.4*x, y0+1.4*y, "N", "h=c;v=c;q=h;s=0.7")
	call gamove (gp, x0, y0)
	x = -0.05*hbox * sinp / PL_XMAG(limit)
	y =  0.05*hbox * cosp
	call grdraw (gp, x, y)

# Draw the dispersion info
	call gseti (gp, G_PLCOLOR, RED)
	x0 = 0.82 * gx2
	y0 = -0.4 * hbox
	dmag = 0.1 * hbox
	x = SLITWID(limit) * dmag / PL_XMAG(limit)
	y = SLITLEN * dmag
	call gamove (gp, x0-x/2., y0-y/2.)
	call grdraw (gp, x, 0.)
	call grdraw (gp, 0., y)
	call grdraw (gp, -x, 0.)
	call grdraw (gp, 0., -y)
	padisp = DEGTORAD (90. - theta + PA1(limit))
	x = DISP1(limit) * dmag * cos (padisp) / PL_XMAG(limit)
	y = DISP1(limit) * dmag * sin (padisp)
	call gamove (gp, x0-x/2., y0-y/2.)
	call grdraw (gp, x, y)
	padisp = DEGTORAD (90. - theta + PA2(limit))
	x = DISP2(limit) * dmag * cos (padisp) / PL_XMAG(limit)
	y = DISP2(limit) * dmag * sin (padisp)
	call gamove (gp, x0-x/2., y0-y/2.)
	call grdraw (gp, x, y)

# PA, warnings messages:
	call gseti (gp, G_PLCOLOR, 1)		# default foreground
	x0 = 0.82 * gx2
	y0 = 0.5 * hbox
	call sprintf (title, SZ_LINE, "PA = %-6.1f")
		call pargr (theta)
	call gtext (gp, x0, y0, title, "h=c;v=c;q=n;s=1")

	if ((ERR_LOW(limit)+ERR_LN2(limit)) != 0.) {
		y0 = 0.25 * hbox
		x = 0.12 * hbox / PL_XMAG(limit)
		y = 0.08 * hbox
		call gamove (gp, x0-x, y0-y)
		call gadraw (gp, x0-x, y0+y)
		call gadraw (gp, x0+x, y0+y)
		call gadraw (gp, x0+x, y0-y)
		call gadraw (gp, x0-x, y0-y)
		call sprintf (title, SZ_LINE, " WARNING:")
		call gtext (gp, x0, y0, title, "h=c;v=b;q=n;s=1")
		call sprintf (title, SZ_LINE, "")
		if (ERR_LN2(limit) > 0.)
			call strcat (" LN2", title, SZ_LINE)
		if (ERR_LOW(limit) > 0.)
			call strcat (" ELEV", title, SZ_LINE)
		call gtext (gp, x0, y0, title, "h=c;v=t;q=n;s=1")
	}

	call gflush (gp)
	call gseti (gp, G_PLCOLOR, 1)		# default foreground
end

#
# SELECTOR: Does an auto selection of slits
# Should include an option for weighting to keep things toward the center.
# Note that y's sent to sel_rank are relative to starting y

procedure	selector (xt, yt, pri, flag, npt, limit, minsep)

real	xt[npt], yt[npt]		# Coords. (" rel. to center)
int	pri[npt]			# priority level
int	flag[npt]			# Codes for objects
int	npt				# Number of objects
real	limit[NLIMITS]			# limit parameter list
real	minsep				# minimum separation (arcsec)

int	i, ndx
int	nselect				# Number of selected slits
real	yrange
real	x, y
pointer	bufn, bufy, bufp, bufsel

begin
	call malloc (bufn, npt, TY_INT)
	call malloc (bufy, npt, TY_REAL)
	call malloc (bufp, npt, TY_INT)
	call malloc (bufsel, npt, TY_INT)

# Find the pool of good objects above the bar...
	ndx = 0
	do i = 1, npt {
		if (abs (flag[i]) == PRIMRY) {
			x = xt[i]
			y = yt[i]
			if (x < X1(limit) || x > X2(limit) ||
					y < BY2(limit) || y > Y2(limit)) {
				next
			}
# Note that priority can be modified here (& below) based on centerline distance
			Memi[bufn+ndx] = i
			Memr[bufy+ndx] = y - BY2(limit)
			Memi[bufp+ndx] = pri[i]
			ndx = ndx + 1
		}
	}
	yrange = Y2(limit) - BY2(limit)

#...select the upper mask slits
	if (ndx > 0) {
		call sel_rank (Memr[bufy], Memi[bufp], Memi[bufn], Memi[bufsel],
						ndx, yrange, minsep, nselect)
		do i = 0, nselect-1 {
			flag[Memi[bufsel+i]] = abs (flag[Memi[bufsel+i]])
		}
	}

#...Now do the same for the lower mask
	ndx = 0
	do i = 1, npt {
		if (abs (flag[i]) == PRIMRY) {
			x = xt[i]
			y = yt[i]
			if (x < X1(limit) || x > X2(limit) ||
					y < Y1(limit) || y > BY1(limit)) {
				next
			}
# Note that priority can be modified here (& above) based on centerline distance
			Memi[bufn+ndx] = i
			Memr[bufy+ndx] = BY1(limit) - y		# Note y-sense
			Memi[bufp+ndx] = pri[i]
			ndx = ndx + 1
		}
	}
	yrange = BY1(limit) - Y1(limit)

	if (ndx > 0) {
		call sel_rank (Memr[bufy], Memi[bufp], Memi[bufn], Memi[bufsel],
						ndx, yrange, minsep, nselect)
		do i = 0, nselect-1 {
			flag[Memi[bufsel+i]] = abs (flag[Memi[bufsel+i]])
		}
	}

	call mfree (bufsel, TY_INT)
	call mfree (bufp, TY_INT)
	call mfree (bufy, TY_REAL)
	call mfree (bufn, TY_INT)
		
end

#
# SEL_RANK: Select slits with priority ranking.
# The scheme is to find the next possible slit, and then to look up to one
# min-slit width away for higher-priority objects. The higher priorities are
# down-weighted depending on their distance.
#

procedure	sel_rank (y, pri, index, sel, npt, yrange, minsep, nslit)

real	y[npt]				# Y (rel. to search start)
int	pri[npt]			# Priority
int	index[npt]			# Index of objects
int	sel[npt]			# selected objects
int	npt				# Number of objects
real	yrange				# yrange from ymin to edge
real	minsep				# minimum separation (arcsec)
int	nslit				# Number of selected slits

int	i, j
int	ihold, phold
real	yhold

int	isel 
real	ynext, ylook, ystop, ylast
real	prisel, prinorm

begin

# Sort the list in y (low-to-high)

	do i = 1, npt-1 {
	    do j = 1, npt-i {
		if (y[j] > y[j+1]) {
			yhold = y[j+1]
			y[j+1] = y[j]
			y[j] = yhold
			ihold = index[j+1]
			index[j+1] = index[j]
			index[j] = ihold
			phold = pri[j+1]
			pri[j+1] = pri[j]
			pri[j] = phold
		}
	    }
	}

# Start at half a slit length; stop inside half slit length
	ystop = min (y[npt], yrange-0.5*minsep)
	ynext = 0.5*minsep
	ylast = 0.
	nslit = 0
	isel = 0

# Loop through to end
	for (i = isel + 1; i <= npt; i = i + 1) {
		if (y[i] < ynext)
			next
		isel = i
		prisel = pri[isel] / (y[isel] - ylast)
# Now look for higher priority to win out
		ylook = min (y[isel]+minsep, ystop)
		if (isel < npt) {
			do j = isel+1, npt {
				if (y[j] >= ylook)
					break
				prinorm = pri[j] / (y[j] - ylast)
				if (prinorm > prisel) {
					isel = j
					prisel = prinorm
				}
			}
		}

		nslit = nslit + 1
		sel[nslit] = index[isel]
		ylast = y[isel]
		ynext = ylast + minsep
		i = isel			# Reset search start point
	}
end

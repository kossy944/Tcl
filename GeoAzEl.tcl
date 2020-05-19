# Geostationary Satellite Az, El & Pol look-angle calculator.
# Calculates from internal parameters OR user input data
#
# March 2004 Chris von Koss
#

# sat long, add new satellites here.
array set satlong {\
Optus_B1 160 \
Optus_B3 152 \
Optus_A3 164 \
Optus_C1 156 \
Apstar_2R 76.5 \
Apstar_5 138.0 \
Pas_10 68.5 \
Pas_8 169.00 \
Pas_4 72 \
Pas_2 169 \
Thaicom_3 78.5 \
GE-1A(AAP-1) 108.2 \
Leasat_L5 156 \
IOR_64 64.15 \
IOR_62 62.0 \
OTHER 100.0 \
}

# site {lat long} lat & long as a list, add new earth stations here.
array set stationlatlong {\
Lockridge {-31.880138 115.941163} \
Belrose {-33.719000 151.211000} \
Adelaide {-34.864000 138.571000} \
Darwin {-12.478000 130.939000} \
Canberra {-35.213000 149.143000} \
Hobart {-42.881000 147.303000} \
Brisbane {-27.556000 153.130000} \
OTHER {30 115} \
}

# get list of earth stations from array
set stationlist [array name stationlatlong]
#foreach {site latlong} [array get stationlatlong] {
#	lappend stationlist $site
#}

# get list of satellites from array
set satlist [array names satlong]
#foreach {sat long} [array get satlong] {
#	lappend satlist $sat
#}

# gui construction
wm title . "GeoSat Az El calc"
wm resizable . 0 0

spinbox .sat -values $satlist -font {-size 12} -wrap 1 -state readonly \
-textvariable sat \
-command { set satellitelong $satlong($sat) }
label .lsat -text "SATELLITE"
set sat OTHER

spinbox .station -values $stationlist -font {-size 12} -wrap 1 -state readonly \
-textvariable station \
-command {set statlong [lindex $stationlatlong($station) 1]; set statlat [lindex $stationlatlong($station) 0]; setlatref}
label .lstation -text "EARTH STATION"
set station OTHER

entry .satlong -font {-size 12} -width 10 -validate key \
-vcmd {expr {[string is double %P] && [string length %P]<7}} \
-textvariable satellitelong
bind .satlong <Return> { calculate }
label .lsatlong -text "LONG (E)"

entry .stationlong -font {-size 12} -width 10 -validate key \
-vcmd {expr {[string is double %P] && [string length %P]<11}} \
-textvariable statlong
bind .stationlong <Return> { calculate }
label .lstationlong -text "LONG (E)"

entry .stationlat -font {-size 12} -width 10 -validate key \
-vcmd {expr {[string is double %P] && [string length %P]<11}} \
-textvariable statlat
bind .stationlat <Return> { calculate }

frame .rbl
label .rbl.lstationlat -text "LAT"
pack .rbl.lstationlat -side left -padx 1 -anchor w -fill x
foreach a {N S} {
	radiobutton .rbl.b$a -text "$a" -variable latref -relief flat -value $a
	pack .rbl.b$a -side left -padx 1 -anchor w -fill x
}
# bind radio buttons to station latitude value
bind .rbl.bN <ButtonRelease-1> { set statlat [expr abs($statlat)] }
bind .rbl.bS <ButtonRelease-1> { set statlat [expr -1*abs($statlat)] }

button .calc -text CALC -command calculate

# About
button .ab -text About -command about

text .op1 -height 10 -width 45 -font {-size 12} -borderwidth 2 -background lightgrey

grid .lsat .lsatlong -padx 5 -sticky w
grid .sat .satlong .calc -sticky w
grid .lstation .lstationlong .rbl -padx 5 -sticky w
grid .station .stationlong .stationlat -padx 5
grid .op1 -columnspan 3
grid configure .sat .satlong .station .stationlong .stationlat -padx 5
grid configure .op1 -pady 5 -padx 5
grid configure .calc -padx 5 -sticky e
grid configure .ab -padx 5 -pady 5 -sticky w

# do stuff
proc calculate {} {
	global sat satellitelong station statlat statlong
	# Geosynchronous radius
	set grad 42164.5
	# Earth radius
	set erad 6378.144
	# other constants
	set pi 3.1415926535897931
	set d2r [expr $pi/180]
	set r2d [expr 180/$pi]
	set diff [expr $statlong-$satellitelong]
	# clear output
	.op1 delete 1.0 {end - 1 chars}
	# Confirm input parameters to user
	.op1 insert end "Satellite:\t$sat\n\t$satellitelong [format %c 176]E\n\Station:\t$station\n\t\LAT: $statlat\tLONG: $statlong\n\n"
	# calculate results
	set pol [expr atan(sin($diff*$pi/180)/tan($statlat*$d2r))*$r2d]
	set range [expr sqrt(pow($grad,2)+pow($erad,2)-2*$grad*$erad*cos($diff*$d2r)*cos($statlat*$d2r))]
	set el [expr asin(($grad*cos($diff*$d2r)*cos($statlat*$d2r)-$erad)/$range)*$r2d]
	set az [expr atan(tan($diff*$d2r)/sin($statlat*$d2r))*$r2d]
	# check and or adjust results
	if {$az<0} {set az [expr $az+360]}
	if {$pol<0} {set pchk "ccw to sat"} else {set pchk "cw to sat"}
	if {$el<1} {set elchk "Elevation too low!"} else {set elchk "ok"}
	if {$statlat<0} {set azchk "cw from North"} else {set azchk "cw from South"}
	# display results
	.op1 insert end "\
	Az:   \t[format "%3.1f%c" $az 176]  $azchk\n\
	El:   \t[format "%3.1f%c" $el 176]  $elchk\n\
	Pol:  \t[format "%3.1f%c" $pol 176] $pchk\n\
	Range:\t[format "%6.1f" $range] km\n"
}

# set station lat ref radio buttons
proc setlatref {} {
	global statlat latref
	if {$statlat<0} {set latref S}
	if {$statlat>0} {set latref N}
}

# Info
proc about {} {
	if {[catch {toplevel .about}]} return
	message .about.text -aspect 1000 -justify left -text "\
Simple Azimuth & Elevation calculator \n\
for geostationary satellites.\n\n\
Select your Location and Satellite, \n\
Then click the CALC button. OR...\n\
Enter your details in entry boxes and\n\
click CALC.\n\n\
CvK March 2004\n"
wm title .about "Geo AZ EL calc info."
button .about.ok -text OK -command {destroy .about}
pack .about.text
pack .about.ok -side bottom
focus .about
}

# initalise entry wigets
set satellitelong $satlong($sat)
set statlong [lindex $stationlatlong($station) 1]
set statlat [lindex $stationlatlong($station) 0]
setlatref

#!/usr/bin/python

# plot points for icing roc
# for a pair of mean max model product, they should be listed
# at (1,2) or (3,4) or (5,6) ... position in a data consequence,
# then they have the same color, one line solid, the other dashed.

import sys
import matplotlib.pyplot as plt
from matplotlib import rcParams

rcParams['xtick.direction'] = 'out'
rcParams['ytick.direction'] = 'out'
rcParams['xtick.labelsize'] = 17
rcParams['ytick.labelsize'] = 17
rcParams['legend.fontsize'] = 17


colors = ["blue","red", "DarkGreen","Fuchsia", "aqua"]

usage = "python vsdbroc.py datafile variable region obsv"
if len(sys.argv) != 5:
    print usage
    quit()

fig = plt.figure(figsize=(8, 8), dpi=100)

filename=sys.argv[1]
variable=sys.argv[2]
region=sys.argv[3]
obsv=sys.argv[4]
curvename="roc"

idxdate=filename.rfind("_")+1
daterange=filename[idxdate:idxdate+8] + " - " + filename[idxdate+8:idxdate+16]

with open(filename) as f:

  while True:

    info = f.readline()
    if not info:
      quit()
    a, fhour, b, preslevl, c, nproducts = info.split()

    imagefile=curvename+"_f"+fhour+"_"+variable+"_P"+preslevl+"_"+region+".png"

#==================================================
#   html header and table headers
#==================================================
    htmlfile=curvename+"_f"+fhour+"_"+variable+"_P"+preslevl+"_"+region+".html"
    fw=open(htmlfile,'w')
    fw.truncate()
    fw.write('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">')
    fw.write('<html>')
    fw.write('<head>')
    fw.write('  <link href="/gmb/icao/roctab.css" rel="stylesheet">')
    fw.write('</head>')
    fw.write('<body>')
    fw.write('<div align="center" style="font-size:2.0em;margin-bottom: 10px;">('+daterange+')</div>')
    fw.write('<div align="center" style="font-size:1.3em">Contingency Tables for ')
    if region.find("G45NHM") > -1:
      fw.write('       Northern Hemisphere')
    elif region.find("G45TRP") > -1:
      fw.write('       Tropics')
    elif region.find("G45SHM") > -1:
      fw.write('       Southern Hemisphere')
    elif region.find("G45AR2") > -1:
      fw.write('       North Atlantic - Area 2')
    elif region.find("G45ASIA") > -1:
      fw.write('       Asia')
    elif region.find("G45NPCF") > -1:
      fw.write('       North Pacific')
    elif region.find("G45AUNZ") > -1:
      fw.write('       Australia/NZ')
    elif region.find("G45NAMR") > -1:
      fw.write('       North America')
    elif region.find("G45") > -1:
      fw.write('       Global')
    else:
      fw.write('       United States CONUS')
    fw.write('</div><p>')
    fw.write('<table id="contingencyTable">')
    fw.write('  <thead>')
    fw.write('    <tr>')
    fw.write('      <th class="contingencyCol0">Threshold</th>')
    fw.write('      <th class="contingencyCol1">Hits</th>')
    fw.write('      <th class="contingencyCol2">False Alarms</th>')
    fw.write('      <th class="contingencyCol3">Miss</th>')
    fw.write('      <th class="contingencyCol4">Correct Rejection</th>')
    fw.write('      <th class="contingencyCol5">Hit Rate</th>')
    fw.write('      <th class="contingencyCol6">False Alarm Rate</th>')
    fw.write('      <th class="contingencyCol6">Bias</th>')
    fw.write('    </tr>')
    fw.write('  </thead>')
    fw.write('  <tbody>')
#==================================================
#==================================================

    fig.clf()
    ax=fig.add_axes([0.1, 0.1, 0.8, 0.8])
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')
    ax.set_xlabel('False Alarm Rate', size=20)
    ax.xaxis.set_label_coords(0.5, -0.075)
    ax.set_ylabel('Hit Rate', size=20)
    ax.text(0.0,1.025, "ICING ROC against "+obsv.upper(), size=20)
    title= "on "+preslevl+"mb, fcst hour="+fhour 
    ax.text(1.0,1.025, title, style='italic',horizontalalignment='right',size=17)

    print fhour, preslevl, nproducts

    i = -1

    nproducts=int(nproducts)
    for j in range(0, nproducts):
      info = f.readline()
      product, npoints = info.split()

#==================================================
#     html product line
#==================================================
      fw.write('    <tr>')
      fw.write('      <th colspan="7" align="left" class="contingencyCol6">'+product+'</th>')
      fw.write('    </tr>')
#==================================================
#==================================================


      x = [];
      y = [];

      # draw the diagonal line
      x.append(0)
      y.append(0)
      x.append(1)
      y.append(1)
      ax.plot(x, y, linewidth=0.8,  color='black')
      del x[:]
      del y[:]

      npoints=int(npoints)
      x.append(1)
      y.append(1)
      for k in range(0, npoints):
        info = f.readline()
        thrd, aa, bb, cc, dd, hit, falm, bias = info.split()
        x.append(falm)
        y.append(hit)

#==================================================
#       html values at each threshold
#==================================================
        fw.write('    <tr>')
        fw.write('      <td class="contingencyCol0">'+thrd+'</td>')
        fw.write('      <td class="contingencyCol1">'+aa  +'</td>')
        fw.write('      <td class="contingencyCol2">'+bb  +'</td>')
        fw.write('      <td class="contingencyCol3">'+cc  +'</td>')
        fw.write('      <td class="contingencyCol4">'+dd  +'</td>')
        fw.write('      <td class="contingencyCol5">'+hit +'</td>')
        fw.write('      <td class="contingencyCol6">'+falm+'</td>')
        fw.write('      <td class="contingencyCol6">'+bias+'</td>')
        fw.write('    </tr>')
#==================================================
#==================================================
      x.append(0)
      y.append(0)


      # preparing individual or pair of products
      imean = product.find("mean")
      imax  = product.find("max")
      igfip = product.find("usfip")
      if igfip >= 0:
        product = "gfip"
      if imean > 0:
        prd = product[:imean]
      elif imax > 0:
        prd = product[:imax]
      else:
        prd = product
      if i < 0:
        i = 0
        prd0 = prd
      elif prd != prd0:
        i = i + 1
        prd0 = prd

      if imean > 0:
        ax.plot(x, y, marker="s", markersize=3.8, linewidth=1.5, label=product, color=colors[i])
      elif imax > 0:
        ax.plot(x, y, marker="^", markersize=5.5, markerfacecolor='None',markeredgecolor=colors[i],linewidth=1.5, label=product, color=colors[i],linestyle="dashed")
      else:
        ax.plot(x, y, marker="s", markersize=3.8, linewidth=1.5, label=product, color=colors[i])

      del x[:]
      del y[:]

    ax.legend(loc=4); # 1 upper right corner; 2 upper left corner; 3 bottom left corner; 4 bottom right corner


    #configure  X axes
    ax.set_xlim(0.05,0.95)
    ax.set_xticks([0,.1,.2,.3,.4,.5,.6,.7,.8,.9,1])
    #configure  y axes
    ax.set_ylim(0.05,0.95)
    ax.set_yticks([0,.1,.2,.3,.4,.5,.6,.7,.8,.9,1])

    #plt.show()
    print "save plot to file:", imagefile
    plt.savefig(imagefile, format='png')

#==================================================
#   html close tags
#==================================================
    fw.write('  </tbody>')
    fw.write('</table>')
    fw.write('</body>')
    fw.write('</html>')
#==================================================
#==================================================


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
rcParams['xtick.labelsize'] = 9
rcParams['ytick.labelsize'] = 9
rcParams['legend.fontsize'] = 9


colors = ["blue","red", "DarkGreen","Fuchsia", "aqua"]

usage = "python vsdbbias.py datafile variable region obsv"
if len(sys.argv) != 5:
    print usage
    quit()

fig = plt.figure(figsize=(8, 8), dpi=100)

filename=sys.argv[1]
variable=sys.argv[2]
region=sys.argv[3]
obsv=sys.argv[4]
curvename="bias"

idxdate=filename.rfind("_")+1
daterange=filename[idxdate:idxdate+8] + "-" + filename[idxdate+8:idxdate+16]

with open(filename) as f:

  while True:

    info = f.readline()
    if not info:
      quit()
    a, fhour, b, preslevl, c, nproducts = info.split()

    imagefile=curvename+"_f"+fhour+"_"+variable+"_P"+preslevl+"_"+region+".png"

    fig.clf()
    ax=fig.add_axes([0.1, 0.1, 0.8, 0.8])
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')
    ax.set_xlabel('Forecast Threshold', size=12)
    ax.set_ylabel('BIAS (forecast/observation)', size=12)
    ax.text(0.01,1.055, "ICING ROC against "+obsv.upper()+", "+daterange, va='top',size=15,transform = ax.transAxes)
    title= "on "+preslevl+"mb, fcst hour="+fhour 
    ax.text(0.99,1.025, title, style='italic',horizontalalignment='right', va='top',size=10,transform = ax.transAxes)

    print fhour, preslevl, nproducts

    i = -1

    nproducts=int(nproducts)
    for j in range(0, nproducts):
      info = f.readline()
      product, npoints = info.split()

      x = [];
      y = [];

      # draw the perfect score line
      x.append(0.1)
      y.append(1)
      x.append(0.9)
      y.append(1)
      ax.plot(x, y, linewidth=0.25,  color='black')
      del x[:]
      del y[:]

      npoints=int(npoints)
      for k in range(0, npoints):
        info = f.readline()
        thrd, aa, bb, cc, dd, hit, falm, bias = info.split()
        x.append(thrd)
        y.append(bias)


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
        ax.plot(x, y, marker="s", markersize=3.8, linewidth=1, label=product, color=colors[i])
      elif imax > 0:
        ax.plot(x, y, marker="^", markersize=5.5, markerfacecolor='None',markeredgecolor=colors[i],linewidth=1, label=product, color=colors[i],linestyle="dashed")
      else:
        ax.plot(x, y, marker="s", markersize=3.8, linewidth=1, label=product, color=colors[i])

      del x[:]
      del y[:]

    ax.legend(loc=1); # 1 upper right corner; 2 upper left corner; 3 bottom left corner; 4 bottom right corner


    #configure  X axes
    ax.set_xlim(0.1,0.9)
    ax.set_xticks([.1,.2,.3,.4,.5,.6,.7,.8,.9])
    #configure  y axes
#    ax.set_ylim(0.05,0.95)
#    ax.set_yticks([0,.1,.2,.3,.4,.5,.6,.7,.8,.9,1])

    #plt.show()
    print "save plot to file:", imagefile
    plt.savefig(imagefile, format='png')


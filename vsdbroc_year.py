#!/usr/bin/python

# plot points for icing roc

#===================================================
#=======sample data=========
#===================================================
#fhour: 24  pressure:   700  nmodels:   2
# max2019                        9
#  0.10     74006    593646       140    482141  0.9981  0.5518        9.00
#  0.20     73960    543728       186    532059  0.9975  0.5054        8.33
#  0.30     73624    494403       522    581384  0.9930  0.4596        7.66
#  0.40     73357    466754       789    609033  0.9894  0.4339        7.28
#  0.50     73278    444329       868    631458  0.9883  0.4130        6.98
#  0.60     73120    409558      1026    666229  0.9862  0.3807        6.51
#  0.70     72787    363995      1359    711792  0.9817  0.3384        5.89
#  0.80     71229    283302      2917    792485  0.9607  0.2633        4.78
#  0.90     58708    164020     15438    911767  0.7918  0.1525        3.00
# max2020                        9
#  0.10     68870    679264       151    537697  0.9978  0.5582       10.84
#  0.20     68834    623090       187    593871  0.9973  0.5120       10.02
#  0.30     68512    567054       509    649907  0.9926  0.4660        9.21
#  0.40     68261    533342       760    683619  0.9890  0.4383        8.72
#  0.50     68173    505806       848    711155  0.9877  0.4156        8.32
#  0.60     68016    465078      1005    751883  0.9854  0.3822        7.72
#  0.70     67682    412708      1339    804253  0.9806  0.3391        6.96
#  0.80     65317    308677      3704    908284  0.9463  0.2536        5.42
#  0.90     54985    179396     14036   1037565  0.7966  0.1474        3.40


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
    print (usage)
    quit()

fig = plt.figure(figsize=(8, 8), dpi=100)

filename=sys.argv[1]
variable=sys.argv[2]
region=sys.argv[3]
obsv=sys.argv[4]
curvename="roc"

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
    ax.set_xlabel('False Alarm Rate', size=20)
    ax.xaxis.set_label_coords(0.5, -0.075)
    ax.set_ylabel('Hit Rate', size=20)
    ax.text(0.0,1.04, "ICING ROC against "+obsv.upper(), size=20)
    title= "on "+preslevl+"mb, fcst hour="+fhour 
    ax.text(1.0,1.015, title, style='italic',horizontalalignment='right',size=17)

    print (fhour, preslevl, nproducts)

    i = -1

    nproducts=int(nproducts)
    for j in range(0, nproducts):
      info = f.readline()
      product, npoints = info.split()

      print (j, product, npoints)

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
        x.append(float(falm))
        y.append(float(hit))

      x.append(0)
      y.append(0)

      # preparing individual or pair of products
      iyear1 = product.find("2019")
      iyear2 = product.find("2020")
      print(iyear1, iyear2, product)
      if iyear1 >= 0:
          prd = product
          print(iyear1, product, prd)
      if iyear2 >= 0:
          prd = product
          print(iyear2, product, prd)
      if i < 0:
        i = 0
        prd0 = prd
      elif prd != prd0:
        i = i + 1
        prd0 = prd
      print(prd0, prd, i)

      if iyear1 >= 0:
        ax.plot(x, y, marker="s", markersize=3.8, linewidth=1.5, label=product, color=colors[i])
      elif iyear2 >= 0:
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
    print ("save plot to file:", imagefile)
    plt.savefig(imagefile, format='png')

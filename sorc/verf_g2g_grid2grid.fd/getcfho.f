c        real fcst, obsv, threshold
c        character *10 symbol
c        character*1 updown
c        real F, O, H
c        symbol = 'FHO>'
c        fcst = 2.20
c        obsv = 1.01
c        threshold = 1.5
c        updown='+'
c        F = getTND_FO(fcst,updown, threshold, symbol) 
c        O = getTND_FO(obsv,updown, threshold, symbol) 
c        H = getTND_Hit(fcst, obsv, updown, threshold, symbol)
c        write(*,*) fcst, obsv,  symbol,threshold, updown
c        write(*,*) "FHO=",F,O,H
c        stop
c        end 

c
c   This function is to get F(fcst <  or = or > threshold) and 
c   O (obsv < or = or > threshold) values for FHO vsdb record
c   Author: Binbin Zhou
c           Mar, 2005
c   Modified: 03/2015 Y Mao: for icing ROC

        subroutine getcfho(x, y, thr1, thr2, symbol, h, f)
        real, intent(in) :: x, y, thr1, thr2
        character(len=10), intent(in) :: symbol
        real, intent(out) :: h, f

        h = 0.
        f = 0.

        if (index(trim(symbol),'>') > 0) then

           if (x > thr1 .and. x <= thr2) then
              if(y > thr1 .and. y <= thr2) then
                 h = 1
              else
                 f = 1
              endif
           endif

        elseif (index(trim(symbol),'<') > 0) then

           if (x <= thr1 .and. x > thr2) then
              if(y <= thr1 .and. y > thr2) then
                 h = 1
              else
                 f = 1
              endif
           endif

        endif

        return
        end

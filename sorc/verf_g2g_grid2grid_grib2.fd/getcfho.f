c        real fcst, obsv, threshold
c        character *10 symbol
c        character*1 updown
c        real F, O, H
c        symbol = 'CFHO>  (5:5)'
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

        subroutine getcfho(x, xthr, y, ythr, symbol, f, h, o)
        real, intent(in) :: x, y, xthr, ythr
        character(len=1), intent(in) :: symbol
        real, intent(out) :: f, h, o

        o = 0.
        f = 0.
        h = 0.

        if (index(trim(symbol),'>') > 0) then
         if(x >= xthr) then        ! yes event
            o = 1.
            if(y >= ythr) h = 1
         elseif(y >= ythr) then    ! no event
            f = 1
         endif
        elseif (index(trim(symbol),'<') > 0) then
         if(x <= xthr) then	   ! yes event
            o = 1.
            if(y <= ythr) h = 1
         elseif(y <= ythr) then    ! no event
            f = 1
         endif
        endif

        return
        end

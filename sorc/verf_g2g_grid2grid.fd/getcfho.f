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

        subroutine getcfho(x, y, xthr, ythr1, ythr2, symbol, h, f)
        real, intent(in) :: x, y, xthr, ythr1, ythr2
        character(len=10), intent(in) :: symbol
        real, intent(out) :: h, f

        h = 0.
        f = 0.


        if (index(trim(symbol),'>') > 0) then
           if(y <= ythr1 .or. y > ythr2) return

           if(x >= xthr) then	! yes event
              h = 1
           else			! no event
              f = 1
           endif
        elseif (index(trim(symbol),'<') > 0) then
           if(y >= ythr1 .or. y < ythr2) return

           if(x <= xthr) then	! yes event
              h = 1
           else			! no event
              f = 1
           endif
        endif

        return
        end

c     input h f are n dimension, to be converted to a, b
c     output valid at n-1 dimension
      subroutine getROC(n, h, f, c, d)
      integer, intent(in) :: n
      real*8, intent(inout) :: h(n), f(n), c(n), d(n)

      real :: a(n-1), b(n-1)
      integer :: i, j

      do i = 1, n - 1
         a(i) = 0.
         b(i) = 0.
         c(i) = 0.
         d(i) = 0.
      enddo

      do i = 1, n - 1
         do j = i+1, n
            a(i) = a(i) + h(j)
            b(i) = b(i) + f(j)
         enddo
         do j = 1, i
            c(i) = c(i) + h(j)
            d(i) = d(i) + f(j)
         enddo
      enddo

      do i = 1, n - 1
         h(i) = a(i)
         f(i) = b(i)
      enddo

      return
      end

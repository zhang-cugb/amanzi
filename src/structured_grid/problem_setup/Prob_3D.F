#undef  BL_LANG_CC
#ifndef BL_LANG_FORT
#define BL_LANG_FORT
#endif

#include "REAL.H"
#include "CONSTANTS.H"
#include "BC_TYPES.H"
#include "BC_TYPES_PM.H"
#include "PROB_AMR_F.H"
#include "PROB_PM_F.H"
#include "ArrayLim.H"

#define SDIM 3

c ::: -----------------------------------------------------------
c ::: This routine is called at problem initialization time
c ::: and when restarting from a checkpoint file.
c ::: The purpose is (1) to specify the initial time value
c ::: (not all problems start at time=0.0) and (2) to read
c ::: problem specific data from a namelist or other input
c ::: files and possibly store them or derived information
c ::: in FORTRAN common blocks for later use.
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: init      => TRUE if called at start of problem run
c :::              FALSE if called from restart
c ::: name      => name of "probin" file
c ::: namlen    => length of name
c ::: strttime <=  start problem with this time variable 
c ::: 
c ::: -----------------------------------------------------------
      subroutine FORT_PROBINIT (init,name,namlen,problo,probhi)

      implicit none

      integer init,namlen
      integer name(namlen)
      integer untin, i
      REAL_T  problo(SDIM), probhi(SDIM)
      end


c ::: -----------------------------------------------------------
c ::: This routine will tag high error cells based on the 
c ::: value provided
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: tag      <=  integer tag array
c ::: DIMS(tag) => index extent of tag array
c ::: set       => integer value to tag cell for refinement
c ::: clear     => integer value to untag cell
c ::: adv       => scalar array
c ::: DIMS(adv) => index extent of scalar array
c ::: lo,hi     => index extent of grid
c ::: nvar      => number of components in rho array (should be 1)
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of tag array
c ::: problo    => phys loc of lower left corner of prob domain
c ::: time      => problem evolution time
c ::: value     => threshold value
c ::: min_time  => minimum time to apply this condition
c ::: max_time  => minimum time to apply this condition
c ::: max_level => maximum level to be generated by this condition
c ::: -----------------------------------------------------------
      subroutine FORT_VALGTERROR (tag,DIMS(tag),set,clear,
     &                            adv,DIMS(adv),mask,DIMS(mask),
     &                            lo,hi,nvar,
     &                            domlo,domhi,dx,xlo,
     &			          problo,time,level,value)

      implicit none

#include "probdata.H"
      
      integer   DIMDEC(tag)
      integer   DIMDEC(adv)
      integer   DIMDEC(mask)
      integer   nvar, set, clear, level
      integer   domlo(SDIM), domhi(SDIM)
      integer   lo(SDIM), hi(SDIM)
      integer   tag(DIMV(tag))
      REAL_T    dx(SDIM), xlo(SDIM), problo(SDIM), time
      REAL_T    adv(DIMV(adv),1)
      REAL_T    mask(DIMV(mask))
      REAL_T    value

      integer   i, j, k

      do i = lo(1), hi(1)
         do j = lo(2), hi(2)
            do k = lo(3), hi(3)
               tag(i,j,k) = merge(set,tag(i,j,k), mask(i,j,k).eq.1 .and. adv(i,j,k,1).gt.value)
            end do
         end do
      end do

      end

c ::: -----------------------------------------------------------
c ::: This routine will tag high error cells based on the 
c ::: value provided
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: tag      <=  integer tag array
c ::: DIMS(tag) => index extent of tag array
c ::: set       => integer value to tag cell for refinement
c ::: clear     => integer value to untag cell
c ::: adv       => scalar array
c ::: DIMS(adv) => index extent of scalar array
c ::: lo,hi     => index extent of grid
c ::: nvar      => number of components in rho array (should be 1)
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of tag array
c ::: problo    => phys loc of lower left corner of prob domain
c ::: time      => problem evolution time
c ::: value     => threshold value
c ::: min_time  => minimum time to apply this condition
c ::: max_time  => minimum time to apply this condition
c ::: max_level => maximum level to be generated by this condition
c ::: -----------------------------------------------------------
      subroutine FORT_VALLTERROR (tag,DIMS(tag),set,clear,
     &                            adv,DIMS(adv),mask,DIMS(mask),
     &                            lo,hi,nvar,
     &                            domlo,domhi,dx,xlo,
     &			          problo,time,level,value)

      implicit none

#include "probdata.H"
      
      integer   DIMDEC(tag)
      integer   DIMDEC(adv)
      integer   DIMDEC(mask)
      integer   nvar, set, clear, level
      integer   domlo(SDIM), domhi(SDIM)
      integer   lo(SDIM), hi(SDIM)
      integer   tag(DIMV(tag))
      REAL_T    dx(SDIM), xlo(SDIM), problo(SDIM), time
      REAL_T    adv(DIMV(adv),1)
      REAL_T    mask(DIMV(mask))
      REAL_T    value

      integer   i, j, k

      do i = lo(1), hi(1)
         do j = lo(2), hi(2)
            do k = lo(3), hi(3)
               tag(i,j,k) = merge(set,tag(i,j,k), mask(i,j,k).eq.1 .and. adv(i,j,k,1).lt.value)
            end do
         end do
      end do

      end

c ::: -----------------------------------------------------------
c ::: This routine will tag high error cells based on the 
c ::: value provided
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: tag      <=  integer tag array
c ::: DIMS(tag) => index extent of tag array
c ::: set       => integer value to tag cell for refinement
c ::: clear     => integer value to untag cell
c ::: adv       => scalar array
c ::: DIMS(adv) => index extent of scalar array
c ::: lo,hi     => index extent of grid
c ::: nvar      => number of components in rho array (should be 1)
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of tag array
c ::: problo    => phys loc of lower left corner of prob domain
c ::: time      => problem evolution time
c ::: value     => threshold value
c ::: min_time  => minimum time to apply this condition
c ::: max_time  => minimum time to apply this condition
c ::: max_level => maximum level to be generated by this condition
c ::: -----------------------------------------------------------
      subroutine FORT_DIFFGTERROR (tag,DIMS(tag),set,clear,
     &                             adv,DIMS(adv),mask,DIMS(mask),
     &                             lo,hi,nvar,
     &                             domlo,domhi,dx,xlo,
     &			           problo,time,level,value)

      implicit none

#include "probdata.H"
      
      integer   DIMDEC(tag)
      integer   DIMDEC(adv)
      integer   DIMDEC(mask)
      integer   nvar, set, clear, level
      integer   domlo(SDIM), domhi(SDIM)
      integer   lo(SDIM), hi(SDIM)
      integer   tag(DIMV(tag))
      REAL_T    dx(SDIM), xlo(SDIM), problo(SDIM), time
      REAL_T    adv(DIMV(adv),1)
      REAL_T    mask(DIMV(mask))
      REAL_T    value
      REAL_T    ax, ay, az
      REAL_T    axp, axm, ayp, aym, azp, azm, aerr

      integer   i, j, k

      if (ARG_L1(mask).gt.lo(1)-1
     &     .or.  ARG_H1(mask).lt.hi(1)+1
     &     .or.  ARG_L2(mask).gt.lo(2)-1
     &     .or.  ARG_H2(mask).lt.hi(2)+1
     &     .or.  ARG_L3(mask).gt.lo(3)-1
     &     .or.  ARG_H3(mask).lt.hi(3)+1 ) then
         print *,'bad mask bounds',lo,hi,DIMS(mask)
         print *,DIMS(mask)
         print *,DIMS(adv)
         call abort()
      endif

      do i = lo(1), hi(1)
         do j = lo(2), hi(2)
            do k = lo(3), hi(3)
               if (mask(i,j,k).eq.1) then

                  if (mask(i+1,j,k).eq.1) then
                     axp = ABS(adv(i+1,j,k,1) - adv(i,j,k,1))
                  else
                     axp = 0.d0
                  endif
                  if (mask(i-1,j,k).eq.1) then
                     axm = ABS(adv(i-1,j,k,1) - adv(i,j,k,1))
                  else
                     axm = 0.d0
                  endif
                  if (mask(i,j+1,k).eq.1) then
                     ayp = ABS(adv(i,j+1,k,1) - adv(i,j,k,1))
                  else
                     ayp = 0.d0
                  endif
                  if (mask(i,j-1,k).eq.1) then
                     aym = ABS(adv(i,j-1,k,1) - adv(i,j,k,1))
                  else
                     aym = 0.d0
                  endif
                  if (mask(i,j,k+1).eq.1) then
                     azp = ABS(adv(i,j,k+1,1) - adv(i,j,k,1))
                  else
                     azp = 0.d0
                  endif
                  if (mask(i,j,k-1).eq.1) then
                     azm = ABS(adv(i,j,k-1,1) - adv(i,j,k,1))
                  else
                     azm = 0.d0
                  endif

                  aerr = MAX(axp,MAX(axm,MAX(ayp,MAX(aym,MAX(azp,azm)))))

                  if (aerr.gt.value) then
                     tag(i,j,k) = set
                  endif
               endif
            end do
         end do
      end do
      
      end

c ::: -----------------------------------------------------------
c ::: This routine is called during a filpatch operation when
c ::: the patch to be filled falls outside the interior
c ::: of the problem domain.  You are requested to supply the
c ::: data outside the problem interior in such a way that the
c ::: data is consistant with the types of the boundary conditions
c ::: you specified in the C++ code.  
c ::: E
c ::: NOTE:  you can assume all interior cells have been filled
c :::        with valid data and that all non-interior cells have
c ::         have been filled with a large real number.
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: rho      <=  density array
c ::: DIMS(rho) => index extent of rho array
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of rho array
c ::: time      => problem evolution time
c ::: bc	=> array of boundary flags bc(BL_SPACEDIM,lo:hi)
c ::: -----------------------------------------------------------

      subroutine FORT_ONE_N_FILL (rho,DIMS(rho),domlo,domhi,dx,xlo,time,bc)

#include "probdata.H"

      integer    DIMDEC(rho)
      integer    domlo(SDIM), domhi(SDIM)
      REAL_T     dx(SDIM), xlo(SDIM), time
      REAL_T     rho(DIMV(rho))
      integer    bc(SDIM,2)

      call filcc(rho(ARG_L1(rho),ARG_L2(rho),ARG_L3(rho)),
     &            DIMS(rho),domlo,domhi,dx,xlo,bc)   
  
      end

c ::: -----------------------------------------------------------
c ::: This routine is called during a filpatch operation when
c ::: the patch to be filled falls outside the interior
c ::: of the problem domain.  You are requested to supply the
c ::: data outside the problem interior in such a way that the
c ::: data is consistant with the types of the boundary conditions
c ::: you specified in the C++ code.  
c ::: E
c ::: NOTE:  you can assume all interior cells have been filled
c :::        with valid data and that all non-interior cells have
c ::         have been filled with a large real number.
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: rho      <=  density array
c ::: DIMS(rho) => index extent of rho array
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of rho array
c ::: time      => problem evolution time
c ::: bc	=> array of boundary flags bc(BL_SPACEDIM,lo:hi)
c ::: -----------------------------------------------------------

      subroutine FORT_ALL_N_FILL (rho,DIMS(rho),domlo,domhi,dx,xlo,time,bc)

      implicit none

#include "probdata.H"

      integer  DIMDEC(rho)
      integer  domlo(SDIM), domhi(SDIM)
      integer  bc(SDIM,2)
      REAL_T   dx(SDIM), xlo(SDIM), time
      REAL_T   rho(DIMV(rho),ncomps)

      integer  i,j,n
      integer  bctmp(SDIM,2)

      !
      ! I'll call filcc() with a slightly different bc.
      ! filcc() doesn't know about SEEPAGE.
      !
      do j=1,2
         do i=1,SDIM
            bctmp(i,j) = bc(i,j)
            if (bc(i,j) .eq. SEEPAGE .or. 
     &           bc(i,j) .eq. REFLECT_ODD) then
               bctmp(i,j) = FOEXTRAP
            end if
         end do
      end do
      

      do n = 1,ncomps
        call filcc(rho(ARG_L1(rho),ARG_L2(rho),ARG_L3(rho),n),
     &             DIMS(rho),domlo,domhi,dx,xlo,bctmp)
      end do

      end

c ::: -----------------------------------------------------------
c ::: This routine is called during a filpatch operation of Tracers 
c ::: when the patch to be filled falls outside the interior
c ::: of the problem domain.  You are requested to supply the
c ::: data outside the problem interior in such a way that the
c ::: data is consistant with the types of the boundary conditions
c ::: you specified in the C++ code.  
c ::: 
c ::: NOTE:  you can assume all interior cells have been filled
c :::        with valid data and that all non-interior cells have
c ::         have been filled with a large real number.
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: rho      <=  density array
c ::: DIMS(rho) => index extent of rho array
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of rho array
c ::: time      => problem evolution time
c ::: bc	=> array of boundary flags bc(BL_SPACEDIM,lo:hi)
c ::: -----------------------------------------------------------

      subroutine FORT_ALL_T_FILL (rho,DIMS(rho),domlo,domhi,dx,xlo,time,bc)

#include "probdata.H"

      integer  DIMDEC(rho)
      integer  domlo(SDIM), domhi(SDIM)
      integer  bc(SDIM,2)
      REAL_T   dx(SDIM), xlo(SDIM), time
      REAL_T   rho(DIMV(rho),ntracers)
      
      integer  i,j,n
      integer  bctmp(SDIM,2)

      !
      ! I'll call filcc() with a slightly different bc.
      ! filcc() doesn't know about SEEPAGE.
      !
      do j=1,2
         do i=1,SDIM
            bctmp(i,j) = bc(i,j)
            if (bc(i,j) .eq. SEEPAGE) bctmp(i,j) = FOEXTRAP
         end do
      end do
      
      do n = 1,ntracers
        call filcc(rho(ARG_L1(rho),ARG_L2(rho),ARG_L3(rho),n),
     &             DIMS(rho),domlo,domhi,dx,xlo,bctmp)
      end do

      end

c ::: -----------------------------------------------------------
c ::: This routine is called during a filpatch operation of Auxilliary 
c ::: when the patch to be filled falls outside the interior
c ::: of the problem domain.  You are requested to supply the
c ::: data outside the problem interior in such a way that the
c ::: data is consistant with the types of the boundary conditions
c ::: you specified in the C++ code.  
c ::: 
c ::: NOTE:  you can assume all interior cells have been filled
c :::        with valid data and that all non-interior cells have
c ::         have been filled with a large real number.
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: rho      <=  density array
c ::: DIMS(rho) => index extent of rho array
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of rho array
c ::: time      => problem evolution time
c ::: bc	=> array of boundary flags bc(BL_SPACEDIM,lo:hi)
c ::: -----------------------------------------------------------

      subroutine FORT_ONE_A_FILL (rho,DIMS(rho),domlo,domhi,dx,xlo,time,bc)

      integer  DIMDEC(rho)
      integer  domlo(SDIM), domhi(SDIM)
      integer  bc(SDIM,2)
      REAL_T   dx(SDIM), xlo(SDIM), time
      REAL_T   rho(DIMV(rho))
      
      integer  i,j
      integer  bctmp(SDIM,2)

      do j=1,2
         do i=1,SDIM
            bctmp(i,j) = FOEXTRAP
         end do
      end do

      call filcc(rho,DIMS(rho),domlo,domhi,dx,xlo,bctmp)

     
      end

c ::: -----------------------------------------------------------
c ::: This routine is called during a filpatch operation of Auxilliary 
c ::: when the patch to be filled falls outside the interior
c ::: of the problem domain.  You are requested to supply the
c ::: data outside the problem interior in such a way that the
c ::: data is consistant with the types of the boundary conditions
c ::: you specified in the C++ code.  
c ::: 
c ::: NOTE:  you can assume all interior cells have been filled
c :::        with valid data and that all non-interior cells have
c ::         have been filled with a large real number.
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: rho      <=  density array
c ::: DIMS(rho) => index extent of rho array
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of rho array
c ::: time      => problem evolution time
c ::: bc	=> array of boundary flags bc(BL_SPACEDIM,lo:hi)
c ::: -----------------------------------------------------------

      subroutine FORT_ALL_A_FILL (rho,DIMS(rho),domlo,domhi,dx,xlo,time,bc)

#include "probdata.H"

      integer  DIMDEC(rho)
      integer  domlo(SDIM), domhi(SDIM)
      integer  bc(SDIM,2)
      REAL_T   dx(SDIM), xlo(SDIM), time
      REAL_T   rho(DIMV(rho),naux)
      
      integer  i,j,n
      integer  bctmp(SDIM,2)

      do j=1,2
         do i=1,SDIM
            bctmp(i,j) = FOEXTRAP
         end do
      end do
      do n = 1,naux 
        call filcc(rho(ARG_L1(rho),ARG_L2(rho),ARG_L3(rho),n),
     &             DIMS(rho),domlo,domhi,dx,xlo,bctmp)
      end do

      end

      subroutine FORT_XVELFILL (vel,DIMS(vel),domlo,domhi,dx,
     &                          xlo,time,bc )

      integer    DIMDEC(vel)
      integer    domlo(SDIM), domhi(SDIM)
      REAL_T     dx(SDIM), xlo(SDIM), time
      REAL_T     vel(DIMV(vel))
      integer    bc(SDIM,2)

      integer    i, j

#include "probdata.H"

      call filcc(vel,DIMS(vel),domlo,domhi,dx,xlo,bc)
      end

      subroutine FORT_YVELFILL (vel,DIMS(vel),domlo,domhi,dx,
     &                          xlo,time,bc )

      integer    DIMDEC(vel)
      integer    domlo(SDIM), domhi(SDIM)
      REAL_T     dx(SDIM), xlo(SDIM), time
      REAL_T     vel(DIMV(vel))
      integer    bc(SDIM,2)

      integer    i, j

#include "probdata.H"

      call filcc(vel,DIMS(vel),domlo,domhi,dx,xlo,bc)
      end

      subroutine FORT_ZVELFILL (vel,DIMS(vel),domlo,domhi,dx,
     &                          xlo,time,bc )

      integer    DIMDEC(vel)
      integer    domlo(SDIM), domhi(SDIM)
      REAL_T     dx(SDIM), xlo(SDIM), time
      REAL_T     vel(DIMV(vel))
      integer    bc(SDIM,2)

      integer    i, j

#include "probdata.H"

      call filcc(vel,DIMS(vel),domlo,domhi,dx,xlo,bc)
      end

c ::: -----------------------------------------------------------
c ::: This routine is called during a filpatch operation when
c ::: the patch to be filled falls outside the interior
c ::: of the problem domain.  You are requested to supply the
c ::: data outside the problem interior in such a way that the
c ::: data is consistant with the types of the boundary conditions
c ::: you specified in the C++ code.  
c ::: 
c ::: NOTE:  you can assume all interior cells have been filled
c :::        with valid data and that all non-interior cells have
c ::         have been filled with a large real number.
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: adv      <=  advected quantity array
c ::: DIMS(adv) => index extent of adv array
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of adv array
c ::: time      => problem evolution time
c ::: bc	=> array of boundary flags bc(BL_SPACEDIM,lo:hi)
c ::: -----------------------------------------------------------

      subroutine FORT_ADVFILL (adv,DIMS(adv),domlo,domhi,dx,xlo,time,bc)

      integer    DIMDEC(adv)
      integer    domlo(SDIM), domhi(SDIM)
      REAL_T     dx(SDIM), xlo(SDIM), time
      REAL_T     adv(DIMV(adv))
      integer    bc(SDIM,2)

      integer    i, j

#include "probdata.H"

      call filcc(adv,DIMS(adv),domlo,domhi,dx,xlo,bc)
      end

c ::: -----------------------------------------------------------
c ::: This routine is called during a filpatch operation when
c ::: the patch to be filled falls outside the interior
c ::: of the problem domain.  You are requested to supply the
c ::: data outside the problem interior in such a way that the
c ::: data is consistant with the types of the boundary conditions
c ::: you specified in the C++ code.
c :::
c ::: NOTE:  you can assume all interior cells have been filled
c :::        with valid data and that all non-interior cells have
c ::         have been filled with a large real number.
c :::
c ::: INPUTS/OUTPUTS:
c :::
c ::: temperature <=  temperature array
c ::: DIMS(temp)   => index extent of adv array
c ::: domlo,hi     => index extent of problem domain
c ::: dx           => cell spacing
c ::: xlo          => physical location of lower left hand
c :::                 corner of temperature array
c ::: time         => problem evolution time
c ::: bc           => array of boundary flags bc(BL_SPACEDIM,lo:hi)
c ::: -----------------------------------------------------------

      subroutine FORT_ENTHFILL (enthalpy,DIMS(temp),domlo,domhi,dx,
     &                          xlo,time,bc )

      integer    DIMDEC(temp)
      integer    domlo(SDIM), domhi(SDIM)
      REAL_T     dx(SDIM), xlo(SDIM), time
      REAL_T     enthalpy(DIMV(temp))
      integer    bc(SDIM,2)

      integer    i, j

#include "probdata.H"

      call filcc(enthalpy,DIMS(temp),domlo,domhi,dx,xlo,bc)
      end

c ::: -----------------------------------------------------------
c ::: This routine is called during a filpatch operation when
c ::: the patch to be filled falls outside the interior
c ::: of the problem domain.  You are requested to supply the
c ::: data outside the problem interior in such a way that the
c ::: data is consistant with the types of the boundary conditions
c ::: you specified in the C++ code.  
c ::: 
c ::: NOTE:  you can assume all interior cells have been filled
c :::        with valid data.
c ::: 
c ::: INPUTS/OUTPUTS:
c ::: 
c ::: p        <=  pressure array
c ::: DIMS(p)   => index extent of p array
c ::: domlo,hi  => index extent of problem domain
c ::: dx        => cell spacing
c ::: xlo       => physical location of lower left hand
c :::	           corner of rho array
c ::: time      => problem evolution time
c ::: bc	=> array of boundary flags bc(BL_SPACEDIM,lo:hi) 
c ::: -----------------------------------------------------------

      subroutine FORT_PRESFILL (p,DIMS(p),domlo,domhi,dx,xlo,time,bc)

      integer    DIMDEC(p)
      integer    domlo(SDIM), domhi(SDIM)
      REAL_T     dx(SDIM), xlo(SDIM), time
      REAL_T     p(DIMV(p))
      integer    bc(SDIM,2)

      integer    i, j

      call filcc(p,DIMS(p),domlo,domhi,dx,xlo,bc)
      end


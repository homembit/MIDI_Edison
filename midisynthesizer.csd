;
; Author: Victor Lazzarini
; Originally published at http://csound.1045644.n5.nabble.com/csound-on-the-Intel-Galileo-td5737023.html
;
<CsoundSynthesizer>

<CsOptions>

-odac:hw:0 -b256 -B1024 -Ma -+rtaudio=alsa -+rtmidi=alsa

</CsOptions>

<CsInstruments>

sr=44100

ksmps=64

nchnls = 2

0dbfs=1



ginstrs = 3

ichn = 1

lp1: massign   ichn, 0

loop_le   ichn, 1, 16, lp1

pgmassign 0, 0



gipg ftgen 1001,0,16,7,0,16,0

gic2 ftgen 1002,0,16,7,127,16,127

gic3 ftgen 1003,0,16,7,64,16,64

gimod ftgen 1004,0,16,7,0,16,0

gibend ftgen 1005,0,16,7,1,16,1



instr 1

kinsto init 0

nxt:

  kst, kch, kd1, kd2 midiin

  if (kst != 0) then

    kch = kch - 1

    if (kst == 144 && kd2 != 0) then ; note on

        kpg table kch, gipg

        kpg = kpg%3 

        kpg += 100

        printk2 kpg

        kac active 102

         if(kpg == 102) then

        /* 102 is mono, the others are poly

           instrument identifier is instr.[chn][note] */

           kinst = kpg + kd1/100000 + kch/100

          if(kac > 0 && kinsto != 0) then

           event "i", -kinsto, 0, 1 

          endif  

           event "i", kinst, 0, -1, kd1, kd2, kch

           kinsto = kinst

          ;endif

         else

           kinst = kpg + kd1/100000 + kch/100  

           event "i", kinst, 0, -1, kd1, kd2, kch

         endif 

    elseif (kst == 128 || (kst == 144 && kd2 == 0)) then ; note off

        kpg table kch, gipg

        kpg = kpg%3 

        kpg += 100

        kinst = kpg +  kd1/100000 + kch/100

        event "i", -kinst, 0, 1 

        kinsto = (kinst == kinsto) ? 0 : kinsto

    elseif (kst == 192) then /* program change msgs */

       kpg = kd1

       tablew  kpg, kch, gipg

       printf "CHANNEL %d PGM %d\n",kd1,kch+1,kpg%ginstrs

    elseif (kst == 176 && kd1 == 1) then /* mod msgs    */

       tablew kd2, kch, gimod

    elseif (kst == 176 && kd1 == 2) then /* ctl2 msgs */

       printk2 kd2

       tablew kd2, kch, gic2

    elseif (kst == 176 && kd1 == 3) then /* ctl3 msgs    */

       tablew kd2, kch, gic3

    elseif (kst == 224) then

       kd2 = kd2/64

       kbnd = 2^(2*(kd2-1)/12)

       tablew kbnd, kch, gibend

    endif

       kgoto nxt

  endif



endin



garev1 init 0

garev2 init 0



instr 100

iatt table p6, gic2

idec table p6, gic3

knx  = p6

kmod table knx, gimod

printk2 kmod

kmod = 0.002+0.006*kmod/128



knx = p6

kbnd table knx, gibend

kcps = cpsmidinn(p4)*kbnd

iamp = 0.2*p5/128



a1 vco2  iamp, kcps*(1.00+kmod)

a2 vco2  iamp, kcps*(1.00+kmod*2)

a3 vco2  iamp, kcps

a4 vco2  iamp, kcps*(1.00-kmod*2)

a5 vco2  iamp, kcps*(1.00-kmod)

iatt /= 128

idec /= 128

idec += 0.01

a6 linenr a1+a2+a3+a4+a5, iatt+0.001,idec,idec/10



kosc oscili 0.5, 0.5, 1

a7, a8 pan2 a6, 0.5+kosc

   outs a7, a8

 

garev2 = a7*0.5 + garev2

garev1 = a8*0.5 + garev1   

   

endin



gifn	ftgen	10000,0, 257, 9, .5,1,270,1.5,.33,90,2.5,.2,270,3.5,.143,90,4.5,.111,270



instr 101

knx = p6

iatt table p6, gic2

idec table p6, gic3

icps = cpsmidinn(p4)

kbnd table knx, gibend

kcps = icps*kbnd

iamp = p5/128

kmod table knx, gimod

kmod = kmod/128





a1 pluck 1, kcps, icps/1.123,0,1



iatt /= 128

idec /= 128

idec += 0.01

a1 linenr a1, iatt+0.001,idec,idec/10

a6 distort a1, kmod, gifn

a6 balance a6,a1



kosc oscili 0.5, 0.5, 1

a7, a8 pan2 a6, 0.5+kosc

   outs a7, a8

   

garev2 = a7*0.5 + garev2

garev1 = a8*0.5 + garev1



endin



opcode ModFM,a,aakkkki



acos,aph,kamp,kfo,kfc,kbw,itab xin



itm = 14

icor = 4.*exp(-1)



ktrig changed kbw

if ktrig == 1 then

 k2 = exp(-kfo/(.29*kbw*icor)) 

 kg2 = 2*sqrt(k2)/(1.-k2)

 kndx = kg2*kg2/2.

endif



kf = kfc/kfo

kfin = int(kf)

ka = kf  - kfin

aexp table kndx*(1-acos)/itm,3,1



ioff = 0.25

acos1 tablei aph*kfin, itab, 1, ioff, 1

acos2 tablei aph*(kfin+1), itab, 1, ioff, 1

asig = (ka*acos2 + (1-ka)*acos1)*aexp



    xout asig*kamp



endop



instr 102

knx = p6

kbnd table knx, gibend

kfun1 =  cpsmidinn(p4)*kbnd

iamp  =  (p5/128)*0.3

imod table p6, gimod

kmod table knx, gimod

kndx port kmod/128,0.1,imod/128



kform1   tablei kndx, 101, 1, 0, 1                  ; 5 formant regions

kform2   tablei kndx, 102, 1, 0, 1  

kform3   tablei kndx, 103, 1, 0, 1  

kform4   tablei kndx, 104, 1, 0, 1  



; formant amplitudes

kaf2     tablei kndx, 112, 1, 0, 1                    

kaf3      tablei kndx, 113, 1, 0, 1  

kaf4      tablei kndx, 114, 1, 0, 1  

kaf5      tablei kndx, 115, 1, 0, 1  



kscal   = 1/(1+ampdb(kaf3)+ampdb(kaf2)+ampdb(kaf4)+ampdb(kaf5)) ; scale output



kbw1    tablei kndx, 121, 1, 0, 1  

kbw2    tablei kndx, 122, 1, 0, 1  

kbw3    tablei kndx, 123, 1, 0, 1  

kbw4    tablei kndx, 124, 1, 0, 1  

kbw5    tablei kndx, 125, 1, 0, 1  



kvib     =   .9*log(kfun1)       ; vibrato intensity



kvib    =  kvib*0.5



      ;jitter & vibr 

kj     randi  kvib, 15

kv     linen  1, 1, p3,1

iph    rnd31  1, 0

kv     oscili  kvib*kv, 3.8+kv, 1, iph



      ;fundamental + jitter + vibr



kfun   =   (kfun1+kj+kv)

iadj = 1.5

iadj2 = 2



aph   phasor kfun

acos tablei aph, 1, 1, 0.25, 1



if kform1 <= kfun then

kform1 = kfun

endif



a1 ModFM acos,aph,1,kfun,kform1,kbw1,1

a2 ModFM acos,aph,ampdb(kaf2),kfun,kform2,kbw2*iadj,1

a3 ModFM acos,aph,ampdb(kaf3),kfun,kform3,kbw3*iadj2,1

;a4 ModFM acos,aph,ampdb(kaf4),kfun,kform4,kbw4*iadj2,1

;a5 ModFM acos,aph,ampdb(kaf5),kfun,4950,kbw5*iadj2,1



asuml   =     (a3+a2+a1)*kscal*iamp             ; mix all formant regions



iatt table p6, gic2

idec table p6, gic3

iatt /= 128

idec /= 128

idec = 0.01

aenv  linenr asuml, iatt+0.001,idec,idec/10

asuml dcblock  aenv

garev1 = asuml*0.5 + garev1

garev2 = asuml*0.5 + garev2

      outs   asuml,asuml



endin





instr 200



arev1,arev2 freeverb garev1, garev2, 0.7, 0.7

     outs arev1,arev2



garev2  = 0

garev1 = 0

endin



</CsInstruments>

<CsScore>

f1 0 16384 10 1

f3 0 131072 "exp" 0 -14 1

 

f101 0 4 -2  800 325 350 450    

f102 0 4 -2  1150 700 2000 800  

f103 0 4 -2  2900 2700 2800 2830 

f104 0 4 -2  3900 3800 3600 3800 



f112 0 4 -2  -6  -16 -20 -11 

f113 0 4 -2  -32 -35 -15 -22 

f114 0 4 -2  -20 -40 -40 -22 

f115 0 4 -2  -50 -60 -56 -50 



f121 0 4 -2  80 50 60 70 

f122 0 4 -2  90 60 90 80 

f123 0 4 -2  120 170 100 100 

f124 0 4 -2  130 180 150 130 

f125 0 4 -2  140 200 200 135 

i1 0 36000

i200 0 36000

</CsScore>

</CsoundSynthesizer>

<bsbPanel>

 <label>Widgets</label>

 <objectName/>

 <x>100</x>

 <y>100</y>

 <width>320</width>

 <height>240</height>

 <visible>true</visible>

 <uuid/>

 <bgcolor mode="nobackground">

  <r>255</r>

  <g>255</g>

  <b>255</b>

 </bgcolor>

</bsbPanel>

<bsbPresets>

</bsbPresets>


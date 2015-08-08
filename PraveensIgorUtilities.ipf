#pragma rtGlobals=1		// Use modern global access method.
#include <Waves Average>
//#include <XY Pair To Waveform>
#Include <Remove Points>
#Include <Power Spectral Density>
//#Include <GaussianFilter>
// test test test
// LastUpdated : 08/16/2008

// ANY CHANGES MADE TO THIS FILE SHOULD BE ENTERED (EXPLAINED) HERE. THIS WAY FOR ANY ANALYZED DATA ONE CAN EASILY
// CHECKED IF ANY OF THE USED FUNCTIONS HAS BEEN ALTERED AND IF PART OR WHOLE OF THAT DATA NEEDS TO BE ANALYSED.
// ANALYSIS CAN ALSO CHANGE IF FUNCTION REMAINS THE SAME BUT PARAMETER VALUES ARE DIFFERENT. THE SURESHOT WAY OF 
// CHECKING THAT IS TO ACTUALLY LOOK AT THE PARAMETER VALUES USED AND MAKE SURE THEY ARE WHAT THEY SHOULD BE. IN
// GENERAL IF ANALYSIS IS REDONE JUST BEFORE FINAptLIZING IT, IT SHOULD TAKE CARE OF BOTH CHANGES IN FUNCTIONS AND
//PARAMETER VALUES

//1.  Coded pt_CalRsRinCmVmIClampVarPar1() which is a wrapper for pt_CalRsRinCmVmIClamp. As in current clamp Rs measurement  is difficult
//(initial transient is small for the seal test current), i am using the current injected for evoking spikes to measure the transient. This wrapper automatically
// changes the current injection values and wavenames before calling pt_CalRsRinCmVmIClamp. Also Renames RsV that is generated to RsVXXXpA
// where XXX is current injection value. pt_AverageVals can then be used to get RsV values during the recordings. 08_18_2008

//2. // inverted the definition of adaptation ratio in pt_CalISIAdaptRatio(). 
// Old 		ARTmp[0]	= 	EndAvgISI/ StartAvgISI
//  New		ARTmp[0]	= 	StartAvgISI / EndAvgISI
//seems that inverse ratio is more commonly used. 08_23_2008

//3 In  pt_RsRinCmVmIclamp2 if weird value of TempRs then it should not be used in further calculations (like RIn). 
// Therefore set =Nan.   Earlier weird value of tempRs was getting  used in further calculations		11_02_2008. 
// SAME NEEDS TO BE DONE FOR pt_RsRinCmVmIclamp2, pt_RsRinCmVmVclamp2 IN THIS FILE AND OTHER FROZEN VERSIONS OF THIS FILE

//4 In pt_SpikeReAnal small bug for extracting ExtractParW corresponding to 0th index value of NSpikesInTrainW. 
//for 0th point there is no point before // (found while analyzing spontaneous activity data which were the 1st 10 waves) 11_17_2008 praveen.

//5. In pt_CurveFit() set the default values of output fit parameters to NaN.  11_19_2008

//6 in case where the calculated result is displayed on top of raw data, the following logic was being used.
//DoWindow WInName
//	If (V_Flag)
//		DoWindow /F WInName
//		Sleep 00:00:01
//		DoWindow /K WInName
//	EndIf
//	DoWindow /c WInName
// now append new raw and calculated data. problem is that this way the current data and current results are not displayed properly. what happens
// is that during sleep the data and results from last calculation are displayed. instead comment out the sleep in earlier window and put a sleep /T 30 
// after new graphs are attached. see example in pt_BinXYWave() 

//7 modified pt_AverageVals() so that the parameter wave can be chosen from current data folder before looking in root:FuncParWaves 12/19/2008

//8 In pt_CalBLAvg if no points to average (start or end point =Nan), do not create any wave. 12/19/2008

// In pt_SpikeAnal, added ISIMidAbsX (ISI mid-point) and ISVY (Interspike voltage calculated at ISIMid point) 03/14/2009

// In pt_LoadWFrmFldrs added the option to load a specific wave rather than all waves (eg. AnalParW[0] = Cell_00*_0016) 03/25/2009

// Modified pt_BinXYWave() to exclude Nans and Infs when checking if all points got binned once and only once 05/16/2009

// modified pt_OperateOn2Waves() to operate on multiple waves matching the DataWaveMatchStr and also instead of choosing bigger 
// of the dimension of pair of waves to be acted on choose smaller dimension 	06/09/2009



// After a change is made in an analysis procedure how to make sure that new analysis is used in all subsequent analysis?
// any new analysis will obviously use new analysis 'cos there is only one copy of PraveensIgorUtilities. 
// ways to identify if newer analysis was used
// 1. check LAST UPDATED date of analysis
// 2. change basename of output waves. this way just by looking at output wave one can know. no need to check in history file for date
// one exception is when new analysis means new parameters not new procedure. then old parameters might still get used for some 
// analysis 'cos parameters are not unique. one way is for procedure to issue alert messages about changes in parameters. boolean
// variable for alert messages can be included in parameter wave which should be set to false only when user is sure all alerts are
// taken care of. 
// for older analysis a prudent approach is to redo all analysis just before finalizing it. that way all latest changes are included.

// LastUpdated : 07/24/2007

// Bugs List 
// [1.]  In pt_AnalWInFldrs2, pt_CalRsRinCmVmVClamp and pt_CalRsRinCmVmIClamp were changing DataWaveMatchStr in the par wave from
// root:FuncParWave while loading waves in RawData: folder. The functions themselves were using local copies of par waves. The par wave
// DataWaveMatchStr in FuncParWavesExtra (from which local copies for data folder were made) is Cell_00* so all the waves in data folder matching
// Cell_00* will be analyzed (which implies all waves corresponding to that cell as only waves corresponding to that cell was loaded by 
// pt_AnalWInFldrs2). To check, use pt_EditWFrmFldrs with DataWaveMatchStr = pt_CalRsRinCmVmVClamp and pt_CalRsRinCmVmIClamp and 
// make sure that the first par is Cell_00*. 07/24/2007.

// [2.] Just as in [1.] pt_AnalWInFldrs2 was using par wave from root:FuncParWave for pt_CalPeak. So correct waves were being loaded in 
// RawData: folder. but pt_CalPeak was not programmed before to use local copy of par waves but was using copy from root:FuncParWaves. In this
// case as pt_AnalWInFldrs2 was modifying DataWaveMatchStr in par wave from root:FuncParWaves, correct DataWaveMatchStr was being used in
// pt_CalPeak. Now changed to using local copy of par wave both in pt_AnalWInFldrs2 and pt_CalPeak. 07/24/2007

// [3.] pt_AverageWaves doesnot check the x-scaling of points. assumes they are same. added 
//  pt_ChkXScaling to check all waves have same offset and scaling, else abort. 11_20_2007. should 
// check earlier usages of pt_AverageWaves and make sure that the waves had same scaling






// Functions Catalog: what different funcs do?

// pt_AnalyzeWavesInFolders, pt_AnalWInFldrs2 applies different functions to data that is loaded from disk (temporarily) or from data present in Igor Folders.
// pt_SpikeAnal finds spikes in waves matching a string. 
// pt_ConctWFrmFldrs concatenates waves matching a string (can be used for scanning the data as a whole to see if some parts need to be removed)
// "****Use pt_XYToWave2 to convert XY waves to waveforms****"
// pt_AverageWaveXY averages XY data waves. different pnts in the average wave correspond to average of pnts that fall in different bins.
// pt_DuplicateWFrmFldrs duplicates waves from different folders in a destination folder.
// pt_DisplayWFrmFldrs displays waves from a folder.
// pt_AppendWFrmFldrs appends waves that match a string to a destination wave, which can then be averaged.
//

// Path for this file: D:\users\taneja\CommonFiles


// Igor Waves: Waves in igor are ALWAYS global. therefore u need to create a reference to access a wave in a function (like for any global variable).
// Reference is like a pointer. it can change the value of the thing it points to, but its local and is automatically killed when the function ends. 
// Functions Make and Duplicate automatically create pointers to the new waves having the same name as waves. Exception to this is when 
// $(StringExpression) is used. If new waves are created inside a function, then they shud be killed by KillWaves if u don't want them to exist 
// when the function finishes. 


// Abt Included files. The included files are in WaveMetrics Procedures folder, which is where the compiler searches for them when u use <> brackets.
// WavesAverage has a useful procedure for averaging waves. RemovePoints has RemoveNans func that need to be used before using StatTTest.

// calculation of RsRinCm in V-clamp

// 3 ways to calculate 

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// simplest way
Function pt_RsRinCmVclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod,Rs,Rin,Cm)
variable tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod,&Rs,&Rin,&Cm
wave w
variable i,WorkVar1,WorkVar2,tStart,tEnd, amp,tau,y1,SumRs,SumRin,SumCm,TempRs,TempRin,TempCm,TempNumRs,TempNumRin,TempNumCm
variable tBaselineStart, tBaselineEnd, tSteadyStateStart, tSteadyStateEnd
	
	i=0; WorkVar1=0; WorkVar2=0; tStart=0; tEnd=0; amp=0; tau=0; y1=0; SumRs=0; SumRin=0; SumCm=0; Rs=0; Rin=0; Cm=0
	TempRs=0; TempRin=0; TempCm=0; TempNumRs=0; TempNumRin=0; TempNumCm=0;tBaselineStart=0;tBaselineEnd=0;tSteadyStateStart=0;tSteadyStateEnd=0
		
	duplicate /o w,w1
	Rs=Nan; Rin=Nan; Cm=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN
	if (SealTestAmp_V<0)
		w1 *= -1
	endif
//	tBaselineStart		 =	 tBaselineStart0
//	tBaselineEnd		=	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd		 =	tSteadyStateEnd0
	
	For  (i=0;i<NumRepeat;i+=1)

//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
//	Print tBaselineEnd
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline I_m before sealtest [A]

//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

//	tStart=tBaselineEnd+0.001											//finally this values should be input by user thru the interface.
	tStart=tBaselineEnd+dimdelta(w1,0)
	tEnd=tStart+0.001

	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> I_m at peak value of sealtest [A]

	//edit w1
	pt_expfit(w1,WorkVar2,tStart,tEnd,amp,tau)
	y1=WorkVar2+amp*exp(-tBaselineEnd/tau)
	
	TempRs =abs(SealTestAmp_V)/(y1-WorkVar1)
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Endif
	
	TempRin =(abs(SealTestAmp_V)/(WorkVar2-WorkVar1))-TempRs
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
	TempCm =tau/(TempRs*TempRin/(TempRs+TempRin))
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1000e-12) 	    // weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
//	Print TempRs,TempRin,TempCm	
	EndFor
	
	Rs=SumRs/TempNumRs
	Rin=SumRin/TempNumRin
	Cm=SumCm/TempNumCm
	KillWaves w1
return 1
end

// calculation of RsRinCm in I-clamp		(good for I-Clamp)
Function pt_RsRinCmIclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod,Rs,Rin,Cm)
variable tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod,&Rs,&Rin,&Cm
wave w
variable i, WorkVar1,WorkVar2,tStart,tEnd,amp,tau,y1,negativeWorkVar2,SumRs,SumRin,SumCm,TempRs,TempRin,TempCm,TempNumRs,TempNumRin,TempNumCm				
variable tBaselineStart, tBaselineEnd, tSteadyStateStart, tSteadyStateEnd

	i=0; WorkVar1=0; WorkVar2=0; tStart=0; tEnd=0; amp=0; tau=0; y1=0; SumRs=0; SumRin=0; SumCm=0; Rs=0; Rin=0; Cm=0
	TempRs=0; TempRin=0; TempCm=0; TempNumRs=0; TempNumRin=0; TempNumCm=0;tBaselineStart=0;tBaselineEnd=0;tSteadyStateStart=0;tSteadyStateEnd=0
//	tBaselineStart		 =	tBaselineStart0
//	tBaselineEnd			 =	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd		 =	tSteadyStateEnd0
	
	duplicate /o w,w1
	
	if (SealTestAmp_I<0)
		w1 *= -1
	endif
	
	For  (i=0;i<NumRepeat;i+=1)	
//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline V_m before sealtest [V]

//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

	tStart=tBaselineEnd+0.0001												//finally this values should be input by user thru the interface.
	tEnd=tStart+0.005
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> V_m at peak value of sealtest [V]
	
	duplicate /o w1, negativeW1
	negativeW1=-w1
	negativeWorkVar2=-WorkVar2
	pt_expfit(negativeW1,negativeWorkVar2,tStart,tEnd,amp,tau)
	y1=WorkVar2-amp*exp(-tBaselineEnd/tau)
	
	TempRs=(y1-WorkVar1)/(abs(SealTestAmp_I)*1e-9)
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Endif
	
	TempRin=((WorkVar2-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
	TempCm=tau/TempRin
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1000e-12) 	    // weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
	EndFor
	
	Rs=SumRs/TempNumRs
	Rin=SumRin/TempNumRin
	Cm=SumCm/TempNumCm
	KillWaves w1, negativeW1
	
return 1
end

// calculation of RsRinCm in I-clamp		(good for I-Clamp)
// Modified from RsRinCmIclamp with following changes.
// 1. the steady state of exponential is not necessarily same as steady state at end of seal test (eg. some voltage and time dependent conductance (eg. Ih) 
//	can change during later part of the seal test). so calculate the steady state of exponential early on (WorkVar3). so use WorkVar3 instead of WorkVar2 
//	for fitting of exponential and calculation of Rs, Cm.
// 2. even for current clamp the time-constant Tau is given by Req*Cm (where Req=Rs*Rin/(Rs+Rin)), just like in V-clamp. However, for good current
//	clamp Rs >> Rin. eventhough, we usually have Rs << Rin, the amp. somehow? realizes the Rs>>Rin so that Tau=Rin*Cm. 
// 3. also output Vm, as we are calculating it anyway.
// 4. also changed the tBaselineEnd0 to 0.0499 s instead of 0.05 s. earlier it was off by 0.1 ms which was causing a small error. correspondingly, 
//	exponential fit starts later. 
// 5. to distinguish the new analysis, the output waves are RsV, RinV, CmV, VmV, TauV instead of RsW, RinW, CmW, VmW, TauV.
Function pt_RsRinCmVmIclamp1(w,tBaselineStart0, tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, tExpFitStart0, tExpFitEnd0, Rs,Rin,Cm, Vm, Tau)
variable tBaselineStart0,tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, tExpFitStart0, tExpFitEnd0, &Rs,&Rin,&Cm, &Vm, &Tau
wave w
variable i, WorkVar1,WorkVar2,amp,t0,y1, WorkVar3,	negativeWorkVar3,SumRs,SumRin,SumCm, SumVm, SumTau, TempRs,TempRin,TempCm, TempVm, TempTau, TempNumRs, TempNumRin,TempNumCm, TempNumVm, TempNumTau			
variable tBaselineStart, tBaselineEnd, tSealTestStart,tSteadyStateStart, tSteadyStateEnd, tExpSteadyStateStart, tExpSteadyStateEnd, tExpFitStart, tExpFitEnd

	i=0; 
	WorkVar1=0; WorkVar2=0; WorkVar3=0; 
	amp=0; t0=0; y1=0; 
	SumRs=0; SumRin=0; SumCm=0; SumVm=0; SumTau=0
	Rs=0; Rin=0; Cm=0; Vm=0; Tau=0
	TempRs=0; TempRin=0; TempCm=0; TempVm=0; TempTau=0
	TempNumRs=0; TempNumRin=0; TempNumCm=0; TempNumVm=0; TempNumTau=0
	tBaselineStart=0;tBaselineEnd=0;
	tSealTestStart=0
	tSteadyStateStart=0;tSteadyStateEnd=0
	tExpSteadyStateStart=0; tExpSteadyStateEnd=0
	tExpFitStart=0; tExpFitEnd=0
//	tBaselineStart		 =	tBaselineStart0
//	tBaselineEnd			 =	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd		 =	tSteadyStateEnd0
	
	duplicate /o w,w1
	Rs=Nan; Rin=Nan; Cm=Nan; Vm=Nan; Tau=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN

	if (SealTestAmp_I<0)
		w1 *= -1
	endif
	
	For  (i=0;i<NumRepeat;i+=1)	
//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline V_m before sealtest [V]
	
	
	tSealTestStart = tSealTestStart0 + i*RepeatPeriod
//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

//	tStart=tBaselineEnd+0.0001	
	tExpFitStart	=tExpFitStart0	+ i*RepeatPeriod								//finally this values should be input by user thru the interface.
	tExpFitEnd	=tExpFitEnd0	+ i*RepeatPeriod
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> V_m at peak value of sealtest [V]
	
	tExpSteadyStateStart	=	tExpSteadyStateStart0	+	i*RepeatPeriod
	tExpSteadyStateEnd  =	tExpSteadyStateEnd0		+	i*RepeatPeriod
	WorkVar3			=	mean(w1,tExpSteadyStateStart,tExpSteadyStateEnd)	
	
// 	Equation to fit V(t)=V(Inf)+(V(0)-V(Inf))*exp(-t/(Req*C))			
// 	V(t) = voltage across Rs + Rin (or Cm) 
//	Tau=Req*C where Req=Rs*Rin/(Rs+Rin). under good current clamp effectively Rs>> Rin. so that Req=Rin.  	
	duplicate /o w1, negativeW1
	negativeW1=-w1
	negativeWorkVar3=-WorkVar3
	pt_expfit(negativeW1,negativeWorkVar3, tExpFitStart, tExpFitEnd, amp, t0)
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen	
	
	
//	y1=WorkVar3-amp*exp(-tBaselineEnd/t0)
	y1=WorkVar3-amp*exp(-tSealTestStart/t0)
	
	
	
	TempRs=(y1-WorkVar1)/(abs(SealTestAmp_I)*1e-9)
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Endif
	
	TempRin=((WorkVar2-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
//	TempCm =t0/(TempRs*TempRin/(TempRs+TempRin))							In general
//	TempCm=t0/TempRin														// under good I clamp the circuit behaves " as if " Rs>>Rin
	TempCm=t0/ ( ((WorkVar3-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs )	// under good I clamp the circuit behaves " as if " Rs>>Rin
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1500e-12) 	   			// weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
	TempVm = SealTestAmp_I<0  ? -WorkVar1 : WorkVar1
	If (numtype(TempVm)==0 && TempVm>-200e-3 && TempVm<+200e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumVm+=TempVm
	TempNumVm+=1
	Endif
	
	TempTau = t0
	If (numtype(TempTau)==0 && TempTau>0 && TempTau<100e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumTau+=TempTau
	TempNumTau+=1
	EndIf
	
	EndFor
	
	Rs		=	SumRs	/	TempNumRs
	Rin		=	SumRin	/	TempNumRin
	Cm		=	SumCm	/	TempNumCm
	Vm		=	SumVm	/	TempNumVm
	Tau		=	SumTau	/	TempNumTau
	KillWaves w1, negativeW1
	
return 1
end


Function pt_RsRinCmVmIclamp2(w,tBaselineStart0, tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpFitStart0, tExpFitEnd0, SmoothFactor, transientWin, Rs,Rin,Cm, Vm, Tau)


// The third derivative was overestimating the Rs transient. The seal test response in current clamp shows a fast decrease (or increase if the stim is depolarizing)
// followed by a slower change. This shows as a large decrease in slope (negative valued) followed by an increase (which is still negative) leading to a minimum 
//(or maximum) in slope which can be  easily measured. Two things to be careful about
// 1. Can't smooth the raw data because that smooths the transition between fast change and slow change and makes it more difficult to detect.
// 2. In calculating the slope, the default is /meth = 0 (central difference). This and meth = 1 (forward difference) causes slope to rise before the raw trace 
// begins to change. Meth =2 (backward differences) seems to be more aligned to raw data and peak in slope corresponds to the end of fast transient.
// using transientWin	= 5e-4
// Above changes made on 12/21/13. Previos code commented as //$*^//



//t0			= W_FitCoeff[3] // Corrected on 06/15/11. Since the wave only has two points  W_FitCoeff[3] = W_FitCoeff[2] so it wasn't causing any error
//  t0			= W_FitCoeff[2]
// finding the small sharp transient voltage (which when divided by current gives Rs)by fittig the exponential is tricky because the exponential fit
// can be affected by activity. hence switching instead to using the third derivative going to zero (as 1st derivative has the point of inflexion).  09/10/2010
//  if weird value then it should not be used in further calculations (like RIn). 
// Therefore set =Nan.   Earlier weird value of tempRs was getting  used in further calculations		11_02_2008. 
// calculation of RsRinCm in I-clamp		(good for I-Clamp)
// changes in pt_RsRinCmVmIclamp1 to get pt_RsRinCmVmIclamp2
//  incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. 
//one advantage is that it can also fit the steady state value. plus it will make the seal test stand alone program. 05/20/2008. 


//     changes in RsRinCmIclamp to get pt_RsRinCmVmIclamp1
// 1. the steady state of exponential is not necessarily same as steady state at end of seal test (eg. some voltage and time dependent conductance (eg. Ih) 
//	can change during later part of the seal test). so calculate the steady state of exponential early on (WorkVar3). so use WorkVar3 instead of WorkVar2 
//	for fitting of exponential and calculation of Rs, Cm.
// 2. even for current clamp the time-constant Tau is given by Req*Cm (where Req=Rs*Rin/(Rs+Rin)), just like in V-clamp. However, for good current
//	clamp Rs >> Rin. eventhough, we usually have Rs << Rin, the amp. somehow? realizes the Rs>>Rin so that Tau=Rin*Cm. 
// 3. also output Vm, as we are calculating it anyway.
// 4. also changed the tBaselineEnd0 to 0.0499 s instead of 0.05 s. earlier it was off by 0.1 ms which was causing a small error. correspondingly, 
//	exponential fit starts later. 
// 5. to distinguish the new analysis, the output waves are RsV, RinV, CmV, VmV, TauV instead of RsW, RinW, CmW, VmW, TauV.

variable tBaselineStart0,tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpFitStart0, tExpFitEnd0,  SmoothFactor, transientWin, &Rs,&Rin,&Cm, &Vm, &Tau
wave w
// removed variable amp as it was not getting used anyway 06/15/11
//variable i, WorkVar1,WorkVar2,amp,t0,y1, WorkVar3,	negativeWorkVar3,SumRs,SumRin,SumCm, SumVm, SumTau, TempRs,TempRin,TempCm, TempVm, TempTau, TempNumRs, TempNumRin,TempNumCm, TempNumVm, TempNumTau
variable i, WorkVar1,WorkVar2,t0,y1, WorkVar3,	negativeWorkVar3,SumRs,SumRin,SumCm, SumVm, SumTau, TempRs,TempRin,TempCm, TempVm, TempTau, TempNumRs, TempNumRin,TempNumCm, TempNumVm, TempNumTau			
variable tBaselineStart, tBaselineEnd, tSealTestStart,tSteadyStateStart, tSteadyStateEnd, tExpFitStart, tExpFitEnd, DisplayResults
SVAR CurrentRsRinCmVmWName=CurrentRsRinCmVmWName
Variable transientX1, transientY1

	i=0; 
	WorkVar1=0; WorkVar2=0; WorkVar3=0; 
//	amp=0; t0=0; y1=0; 	06/15/11
	t0=0; y1=0; 
	SumRs=0; SumRin=0; SumCm=0; SumVm=0; SumTau=0
	Rs=0; Rin=0; Cm=0; Vm=0; Tau=0
	TempRs=0; TempRin=0; TempCm=0; TempVm=0; TempTau=0
	TempNumRs=0; TempNumRin=0; TempNumCm=0; TempNumVm=0; TempNumTau=0
	tBaselineStart=0;tBaselineEnd=0;
	tSealTestStart=0
	tSteadyStateStart=0;tSteadyStateEnd=0
//	tExpSteadyStateStart=0; tExpSteadyStateEnd=0
	tExpFitStart=0; tExpFitEnd=0

	
	duplicate /o w,w1
	Rs=Nan; Rin=Nan; Cm=Nan; Vm=Nan; Tau=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN

//	if (SealTestAmp_I<0)		05_20_2008
//		w1 *= -1
//	endif
	
	For  (i=0;i<NumRepeat;i+=1)	


	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline V_m before sealtest [V]
	
	
	tSealTestStart = tSealTestStart0 + i*RepeatPeriod

	
	tExpFitStart	=tExpFitStart0	+ i*RepeatPeriod								//finally this values should be input by user thru the interface.
	tExpFitEnd	=tExpFitEnd0	+ i*RepeatPeriod
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> V_m at peak value of sealtest [V]
	
//	tExpSteadyStateStart	=	tExpSteadyStateStart0	+	i*RepeatPeriod			05_20_2008
//	tExpSteadyStateEnd  =	tExpSteadyStateEnd0		+	i*RepeatPeriod
//	WorkVar3			=	mean(w1,tExpSteadyStateStart,tExpSteadyStateEnd)	
	
// 	Equation to fit V(t)=V(Inf)+(V(0)-V(Inf))*exp(-t/(Req*C))			
// 	V(t) = voltage across Rs + Rin (or Cm) 
//	Tau=Req*C where Req=Rs*Rin/(Rs+Rin). under good current clamp effectively Rs>> Rin. so that Req=Rin.  	
//	duplicate /o w1, negativeW1													05_20_2008
//	negativeW1=-w1
//	negativeWorkVar3=-WorkVar3
//	pt_expfit(negativeW1,negativeWorkVar3, tExpFitStart, tExpFitEnd, amp, t0) 05_20_2008

Make /D/O/N=3 W_FitCoeff = Nan
Duplicate /O  w1, fit_w1
fit_w1= Nan

CurveFit /NTHR=0/TBOX=0/Q exp_XOffset,  kwCWave=W_FitCoeff, w1 (tExpFitStart, tExpFitEnd) /D = fit_w1


WorkVar3	= W_FitCoeff[0]
//amp 		= W_FitCoeff[1]
//t0			= W_FitCoeff[3]		06/15/11
t0			= W_FitCoeff[2]

If (		(NumType(W_FitCoeff[0])!=0) || (NumType(W_FitCoeff[1])!=0) || (NumType(W_FitCoeff[2])!=0)		)
	Print "																			"
//	Print "Fitting error: y0, A, Tau =", WorkVar3, amp,t0, "in", CurrentRsRinCmVmWName		06/15/11
	Print "Fitting error: y0, Tau =", WorkVar3,t0, "in", CurrentRsRinCmVmWName
EndIf

// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen	
	
	
//	y1=WorkVar3-amp*exp(-tBaselineEnd/t0)
//	y1=WorkVar3-amp*exp(-tSealTestStart/t0) 05_20_2008
	
//	y1=WorkVar3+amp*exp(-(tSealTestStart- tExpFitStart)/t0)		09/10/2010

// Replacing third derivative with minimum in 1st derivative. See comments at begining of function . Old code commented as  //$*^//	12/21/13

 //$*^//	Duplicate /O w1, w1_Smooth3Diff
 //$*^//	Smooth SmoothFactor, w1_Smooth3Diff// binomial smoothing applied SmoothFactor number of times
 //$*^//		Differentiate w1_Smooth3Diff			// 1st  Der
 //$*^//		Differentiate w1_Smooth3Diff			// 2nd Der
 //$*^//		Differentiate w1_Smooth3Diff			// 3rd Der
 
 	Duplicate /O w1, w1_Diff
	Differentiate /meth =2 w1_Diff			// 1st  Der. BACKWARD DIFFERENCES
	
	Wavestats /Q/r=(tSealTestStart, tSealTestStart+transientWin) w1_Diff	
	If (SealTestAmp_I<0)
		transientY1 = V_Min
		transientX1 = V_MinLoc
		transientY1= w1[X2Pnt(w1_Diff, transientX1)]
	 //$*^//FindLevel /R=(tSealTestStart0,)/Q/Edge = 2  w1_Smooth3Diff, 0
	Else
		transientY1 = V_Max
		transientX1 = V_MaxLoc
		transientY1= w1[X2Pnt(w1_Diff, transientX1)]
	 //$*^//FindLevel /R=(tSealTestStart0,)/Q/Edge = 1  w1_Smooth3Diff, 0
	EndIf
	
 //$*^//	If (V_Flag ==0)	// level found

 //$*^//		y1= w1[X2Pnt(w1_Smooth3Diff, V_LevelX)]
//		Print y1	
 //$*^//	Else
 //$*^//		y1 = NaN
 //$*^//	EndIf
	
DisplayResults=1
If (DisplayResults)

DoWindow pt_RsRinCmVmIclamp2Display
	If (V_Flag)
//		DoWindow /F pt_RsRinCmVmIclamp2Display
//		Sleep 00:00:01
		DoWindow /K pt_RsRinCmVmIclamp2Display
	EndIf
	Display
	DoWindow /c pt_RsRinCmVmIclamp2Display
	
		AppendToGraph /W=pt_RsRinCmVmIclamp2Display w1, fit_w1
		SetAxis Bottom tBaselineStart, tSteadyStateEnd0
		SetAxis /A=2 Left 
		SetDrawEnv textxjust= 2,textyjust= 2, fsize=08;DelayUpdate
		DrawText 1,0,CurrentRsRinCmVmWName
		ModifyGraph rgb(fit_w1)=(0,0,0)
		ModifyGraph lsize(fit_w1)=2
//		Cursor A w1 0.5*(tBaselineStart+tBaselineEnd), WorkVar1
//		Cursor A w1 WorkVar2, WorkVar1
//		Make /O/N=1 RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmExpPkW
//		Make /O/N=1 RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmExpPkWX

		Make /O/N=1 RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmRsPkW
		Make /O/N=1 RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmRsPkWX
		RsRinCmVmBLWX		= 0.5*(tBaselineStart+tBaselineEnd)
		RsRinCmVmBLW		= WorkVar1
		
		RsRinCmVmSSWX		= 0.5*(tSteadyStateStart+tSteadyStateEnd)
		RsRinCmVmSSW		= WorkVar2
		
//		RsRinCmVmExpPkWX	= tSealTestStart
		RsRinCmVmRsPkWX		=  transientX1//$*^//V_LevelX
		RsRinCmVmRsPkW		= transientY1
		
		AppendToGraph /W=pt_RsRinCmVmIclamp2Display RsRinCmVmBLW		vs RsRinCmVmBLWX
		ModifyGraph mode(RsRinCmVmBLW)=3
		ModifyGraph marker(RsRinCmVmBLW)=19
		ModifyGraph rgb(RsRinCmVmBLW)=(0,15872,65280)
		
		AppendToGraph /W=pt_RsRinCmVmIclamp2Display RsRinCmVmSSW		vs RsRinCmVmSSWX
		ModifyGraph mode(RsRinCmVmSSW)=3
		ModifyGraph marker(RsRinCmVmSSW	)=16
		ModifyGraph rgb(RsRinCmVmSSW)=(0,15872,65280)
		
		AppendToGraph /W=pt_RsRinCmVmIclamp2Display RsRinCmVmRsPkW	vs RsRinCmVmRsPkWX
		ModifyGraph mode(RsRinCmVmRsPkW)=3
		ModifyGraph marker(RsRinCmVmRsPkW)=17
		ModifyGraph rgb(RsRinCmVmRsPkW)=(0,15872,65280)
		
		Legend/C/N=text0/J/F=0/A=RC "\\Z08\\s(RsRinCmVmBLW) BaseLineW\r\\s(RsRinCmVmSSW) SteadyState\r\\s(RsRinCmVmRsPkW) RsTransient"
		
		DoUpdate /W = pt_RsRinCmVmIclamp2Display	
		Sleep /T 5
		
//DoWindow pt_RsRinCmVmIclamp2Display				05_20_2008
//	If (V_Flag)
//		DoWindow /F pt_RsRinCmVmIclamp2Display
//		Sleep 00:00:02
//		DoWindow /K pt_RsRinCmVmIclamp2Display
//	EndIf
DoWindow pt_RsRinCmVmIclamp2Display		// kill the last display window 11_11/13
If (V_Flag)
//	DoWindow /K pt_RsRinCmVmIclamp2Display
EndIf

EndIf	
	
	
//	TempRs=(y1-WorkVar1)/(abs(SealTestAmp_I)*1e-9)   					05_20_2008
	TempRs=(transientY1-WorkVar1)/(     (SealTestAmp_I))	
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Else															
//  if weird value then it should not be used in further calculations (like RIn). 
// Therefore set =Nan.   Earlier weird value of tempRs was getting  used in further calculations		11_02_2008. 
	TempRs = Nan																			
	Endif
	
//	TempRin=((WorkVar2-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs  //05_20_2008
	TempRin=((WorkVar2-WorkVar1)/(     (SealTestAmp_I)))-TempRs
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
//	TempCm =t0/(TempRs*TempRin/(TempRs+TempRin))							In general
//	TempCm=t0/TempRin														// under good I clamp the circuit behaves " as if " Rs>>Rin
//	TempCm=t0/ ( ((WorkVar3-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs )  //05_20_2008	// under good I clamp the circuit behaves " as if " Rs>>Rin
	TempCm=t0/ ( ((WorkVar3-WorkVar1)/(     (SealTestAmp_I)))-TempRs ) 
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1500e-12) 	   			// weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
//	TempVm = SealTestAmp_I<0  ? -WorkVar1 : WorkVar1			//05_20_2008
	TempVm = WorkVar1
	If (numtype(TempVm)==0 && TempVm>-200e-3 && TempVm<+200e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumVm+=TempVm
	TempNumVm+=1
	Endif
	
	TempTau = t0
	If (numtype(TempTau)==0 && TempTau>0 && TempTau<100e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumTau+=TempTau
	TempNumTau+=1
	EndIf
	
	EndFor
	
	Rs		=	SumRs	/	TempNumRs
	Rin		=	SumRin	/	TempNumRin
	Cm		=	SumCm	/	TempNumCm
	Vm		=	SumVm	/	TempNumVm
	Tau		=	SumTau	/	TempNumTau
//	Print Rs, Rin, Cm, Vm, Tau
	KillWaves /Z w1, fit_w1, w1_Smooth3Diff				//, negativeW1				05_20_2008
	KillWaves/Z RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmRsPkW, RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmRsPkWX
		
return 1
end





// modified from: RsRinCmIclamp
// Modifications
//** earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of seal test. but still kept using tBaselineEnd0 to 
//extrapolate the exp. to get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran  
// Feb.28th 2008 Praveen
// ** the steady state of exponential is not necessarily same as steady state at end of seal test (eg. some voltage and time dependent conductance (eg. Ih) 
//	can change during later part of the seal test). so calculate the steady state of exponential early on (WorkVar3). so use WorkVar3 instead of WorkVar2 
//	for fitting of exponential and calculation of Rs, Cm.
//** Often in V-clamp seal test two exponential decays can be seen. the first fast decay is charge on pipette capacitance leaking thru the resistors, the second slower 
//decay is due to cell capacitance charge leaking. the 2nd exponential decay should be used for calculation of cell membrane capacitance.
//** also output Vm, as we are calculating it anyway.
//** also changed the tBaselineEnd0 to 0.0499 s instead of 0.05 s. earlier it was off by 0.1 ms which was causing a small error. correspondingly, 
//	exponential fit starts later. 
//** to distinguish the new analysis, the output waves are RsV, RinV, CmV, VmV, TauV instead of RsW, RinW, CmW, VmW, TauV.


Function pt_RsRinCmVmVclamp1(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp1SteadyStateStart0, tExp1SteadyStateEnd0, tExp1FitStart0, tExp1FitEnd0, tExp2SteadyStateStart0, tExp2SteadyStateEnd0, tExp2FitStart0, tExp2FitEnd0, Rs,Rin,Cm, Im, Tau)
variable tBaselineStart0,tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp1SteadyStateStart0, tExp1SteadyStateEnd0, tExp1FitStart0, tExp1FitEnd0, tExp2SteadyStateStart0, tExp2SteadyStateEnd0, tExp2FitStart0, tExp2FitEnd0, &Rs,&Rin,&Cm, &Im, &Tau
wave w
variable i, WorkVar1,WorkVar2,amp,t0,y1, WorkVar3,	negativeWorkVar3,SumRs,SumRin,SumCm, SumIm, SumTau, TempRs,TempRin, TempRin1, TempCm, TempIm, TempTau, TempNumRs, TempNumRin, TempNumCm, TempNumIm, TempNumTau			
variable tBaselineStart, tBaselineEnd, tSealTestStart, tSteadyStateStart, tSteadyStateEnd, tExp1SteadyStateStart, tExp1SteadyStateEnd, tExp1FitStart, tExp1FitEnd,  tExp2SteadyStateStart, tExp2SteadyStateEnd, tExp2FitStart, tExp2FitEnd

	i=0; 
	WorkVar1=0; WorkVar2=0; WorkVar3=0; 
	amp=0; t0=0; y1=0; 
	SumRs=0; SumRin=0; SumCm=0; SumIm=0; SumTau=0
	Rs=0; Rin=0; Cm=0; Im=0; Tau=0
	TempRs=0; TempRin=0; TempRin1=0; TempCm=0; TempIm=0; TempTau=0
	TempNumRs=0; TempNumRin=0; TempNumCm=0; TempNumIm=0; TempNumTau=0
	tBaselineStart=0;tBaselineEnd=0;
	tSealTestStart=0
	tSteadyStateStart=0;tSteadyStateEnd=0
	tExp1SteadyStateStart=0; tExp1SteadyStateEnd=0
	tExp1FitStart=0; tExp1FitEnd=0
	tExp2SteadyStateStart=0; tExp2SteadyStateEnd=0
	tExp2FitStart=0; tExp2FitEnd=0
//	tBaselineStart		 =	tBaselineStart0
//	tBaselineEnd			 =	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd		 =	tSteadyStateEnd0
	
	duplicate /o w,w1
	Rs=Nan; Rin=Nan; Cm=Nan; Im=Nan; Tau=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN

	if (SealTestAmp_V<0)
		w1 *= -1
	endif
	
	For  (i=0;i<NumRepeat;i+=1)	
//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline V_m before sealtest [V]

	tSealTestStart = tSealTestStart0 + i*RepeatPeriod
//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

//	tStart=tBaselineEnd+0.0001	
	tExp1FitStart	=tExp1FitStart0	+ i*RepeatPeriod								//finally this values should be input by user thru the interface.
	tExp1FitEnd	=tExp1FitEnd0	+ i*RepeatPeriod
	
	tExp2FitStart	=tExp2FitStart0	+ i*RepeatPeriod								//finally this values should be input by user thru the interface.
	tExp2FitEnd	=tExp2FitEnd0	+ i*RepeatPeriod
	
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> V_m at peak value of sealtest [V]
	
	tExp1SteadyStateStart	=	tExp1SteadyStateStart0		+	i*RepeatPeriod
	tExp1SteadyStateEnd  	=	tExp1SteadyStateEnd0		+	i*RepeatPeriod
	WorkVar3			=	mean(w1,tExp1SteadyStateStart,tExp1SteadyStateEnd)	
	
// 	Equation to fit I(t)=I(Inf)+(I(0)-I(Inf))*exp(-t/(Req*C))			
// 	I(t) = current through Rs or Rin+Cm parallel compbination
//	Tau=Req*C where Req=Rs*Rin/(Rs+Rin). under good V clamp effectively Rs<< Rin. so that Req=Rs.  	
//	duplicate /o w1, negativeW1
//	negativeW1=-w1
//	negativeWorkVar3=-WorkVar3
	pt_expfit(w1,WorkVar3, tExp1FitStart, tExp1FitEnd, amp, t0)
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
	
//	y1=WorkVar3+amp*exp(-tBaselineEnd/t0)
	y1=WorkVar3+amp*exp(-tSealTestStart/t0)

	
//	TempRs=(y1-WorkVar1)/(abs(SealTestAmp_I)*1e-9)
	TempRs =abs(SealTestAmp_V)/(y1-WorkVar1)
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Endif
	
//	TempRin=((WorkVar2-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs
	TempRin =(abs(SealTestAmp_V)/(WorkVar2-WorkVar1))-TempRs
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
//	TempCm =t0/(TempRs*TempRin/(TempRs+TempRin))							
//	TempCm=t0/TempRin	
//	pt_expfit(w1,WorkVar2, tExpFitStart+0.0001, tExpFitEnd+0.001, amp, t0)					
	WorkVar3			=	mean(w1,tExp2SteadyStateStart,tExp2SteadyStateEnd)
	pt_expfit(w1,WorkVar3, tExp2FitStart, tExp2FitEnd, amp, t0)
	TempRIn1=(abs(SealTestAmp_V)/(WorkVar3-WorkVar1))-TempRs
	TempCm=t0/(TempRs*TempRin1/(TempRs+TempRin1))							
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1500e-12) 	   			// weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
	TempIm = SealTestAmp_V<0  ? -WorkVar1 : WorkVar1
	If (numtype(TempIm)==0 && TempIm>-200e-3 && TempIm<+200e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumIm+=TempIm
	TempNumIm+=1
	Endif
	
	TempTau = t0
	If (numtype(TempTau)==0 && TempTau>0 && TempTau<100e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumTau+=TempTau
	TempNumTau+=1
	EndIf
	
	EndFor
	
	Rs		=	SumRs	/	TempNumRs
	Rin		=	SumRin	/	TempNumRin
	Cm		=	SumCm	/	TempNumCm
	Im		=	SumIm	/	TempNumIm
	Tau		=	SumTau	/	TempNumTau
	KillWaves w1								
	
return 1
end

//------------------------------------------------
Function pt_RsRinCmVmVclamp3(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSteadyStateStart0, tSteadyStateEnd0, SealTestAmp_V, NumRepeat,RepeatPeriod, tExp1FitStart0, tExp1FitEnd0, Rs,Rin,Cm, Im, Tau)
// modified from: pt_RsRinCmVmVclamp2 (04/18_12)

// modified Q1 = Area(w2, tSealTestStart+wDel, tExp1FitEnd0 ) to Q1 = Area(w2, tSealTestStart+wDel, tSteadyStateStart) 10/25/13
// and also modified baseline and steady state start and end values in parameters as follows
// tBaselineStart0	tBaselineEnd0	0..005, 0.045 to 0.025, 0.045
//	tSteadyStateStart, tSteadyStateEnd0	0.45, 0.495 to 0.07, 0.09 //10/25/13
// implementing the method used in pclamp analysis (see pclamp manual). Can be done at the beginning and at the end of the test and average values can be used. For now it's just the 1st transient
// 1st find the charge accumulated on the membrane capacitor during seal test. Between the beginning of the seal test and before the steady state is reached the current changes from
// being totally capacitative to totally resistive. We need to find the part of the current that flows through the capacitor to calculate Q=C*V. Which means we need to subtract from the total area under 
// the transient, the area under the current that flows through the resistor (this is estimated as follows)
// Charge under (I_Tot-I_SS) (SS= steady state) from beginning to steady state + Tau*(I_SS-I_BL) where BL = Baseline.
// Once the charge and Tau are known (latter by fitting exponential), From Q=CVm (where Vm = Voltage across membrane), we have
// Q=C*VStim*(RIn/(Rs+RIn)) [1]
// Also, Tau = C*(RsRIn/(Rs+RIn)) [2]
// Substituting C from [1] in [2]
// Tau = Q*Rs/VStim [3]
// From (3) Rs=Tau*VStim/Q [4]
// RIn = RTot-Rs= VStim/(I_SS-I_BL) - Rs [5]
// Cm= can be calculated from [2] above.








// Comments from Older version
// removed amp variable all together as it wasn't getting used 06/15/11
//t0			= W_FitCoeff[3] // Corrected on 04/19/11. Since the wave only has two points  W_FitCoeff[3] = W_FitCoeff[2] so it wasn't causing any error
//  t0			= W_FitCoeff[2]
// curvefitting exponential is difficult for the falling phase of series-resistance transient as it's very fast and only has 2-3 points before
// it gives rise to slower decay due to membrane RIn and Cm. So just for the amplitude of series resistance transient i am switching to
// finding minimum or maximum using wavestats. //07/14/2008

// changes in pt_RsRinCmVmVclamp1 to get pt_RsRinCmVmVclamp2
//  incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. 
//one advantage is that it can also fit the steady state value. plus it will make the seal test stand alone program. 07/14/2008 (already did for I clamp on 05/20/2008)


// Modifications
//** earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of seal test. but still kept using tBaselineEnd0 to 
//extrapolate the exp. to get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran  
// Feb.28th 2008 Praveen
// ** the steady state of exponential is not necessarily same as steady state at end of seal test (eg. some voltage and time dependent conductance (eg. Ih) 
//	can change during later part of the seal test). so calculate the steady state of exponential early on (WorkVar3). so use WorkVar3 instead of i_SS 
//	for fitting of exponential and calculation of Rs, Cm.
//** Often in V-clamp seal test two exponential decays can be seen. the first fast decay is charge on pipette capacitance leaking thru the resistors, the second slower 
//decay is due to cell capacitance charge leaking. the 2nd exponential decay should be used for calculation of cell membrane capacitance.
//** also output Vm, as we are calculating it anyway.
//** also changed the tBaselineEnd0 to 0.0499 s instead of 0.05 s. earlier it was off by 0.1 ms which was causing a small error. correspondingly, 
//	exponential fit starts later. 
//** to distinguish the new analysis, the output waves are RsV, RinV, CmV, VmV, TauV instead of RsW, RinW, CmW, VmW, TauV.


variable tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp1FitStart0, tExp1FitEnd0, &Rs,&Rin,&Cm, &Im, &Tau
wave w

variable i, i_BL,i_SS,amp,t0,y1, WorkVar3,	 WorkVar4, negativeWorkVar3,SumRs,SumRin,SumCm, SumIm, SumTau, TempRs,TempRin, TempRin1, TempCm, TempIm, TempTau, TempNumRs, TempNumRin, TempNumCm, TempNumIm, TempNumTau			
variable tBaselineStart, tBaselineEnd, tSealTestStart, tSteadyStateStart, tSteadyStateEnd, tExp1FitStart, tExp1FitEnd, DisplayResults, wDel, Q1, Q2, Q_Tot
SVAR CurrentRsRinCmImWName=CurrentRsRinCmImWName

	i=0; 
	i_BL=0; i_SS=0; WorkVar3=0; 
//	amp=0; t0=0; y1=0;
	t0=0; y1=0;  
	SumRs=0; SumRin=0; SumCm=0; SumIm=0; SumTau=0
	Rs=0; Rin=0; Cm=0; Im=0; Tau=0
	TempRs=0; TempRin=0; TempRin1=0; TempCm=0; TempIm=0; TempTau=0
	TempNumRs=0; TempNumRin=0; TempNumCm=0; TempNumIm=0; TempNumTau=0
	tBaselineStart=0;tBaselineEnd=0;
	tSealTestStart=0
	tSteadyStateStart=0;tSteadyStateEnd=0
	tExp1FitStart=0; tExp1FitEnd=0


	
	duplicate /o w,w1
	wDel=DimDelta(w,0)
	Rs=Nan; Rin=Nan; Cm=Nan; Im=Nan; Tau=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN

//	if (SealTestAmp_V<0)
//		w1 *= -1
//	endif
	
	For  (i=0;i<NumRepeat;i+=1)	
//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	i_BL = mean(w1,tBaselineStart,tBaselineEnd)									// i_BL --> Baseline current before sealtest [V]

	tSealTestStart = tSealTestStart0 + i*RepeatPeriod
//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

//	tStart=tBaselineEnd+0.0001	
	tExp1FitStart	=tExp1FitStart0	+ i*RepeatPeriod								
	tExp1FitEnd	=tExp1FitEnd0	+ i*RepeatPeriod
	
//	tExp2FitStart	=tExp2FitStart0	+ i*RepeatPeriod								
//	tExp2FitEnd	=tExp2FitEnd0	+ i*RepeatPeriod
	
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	i_SS = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// i_SS --> Steady state current towards the end of sealtest [V]
	
//	tExp1SteadyStateStart	=	tExp1SteadyStateStart0		+	i*RepeatPeriod
//	tExp1SteadyStateEnd  	=	tExp1SteadyStateEnd0		+	i*RepeatPeriod
//	WorkVar3			=	mean(w1,tExp1SteadyStateStart,tExp1SteadyStateEnd)	
	
// Fit exponential to transient to calculate t0 (=tau)
Make /D/O/N=3 W_FitCoeff = Nan
Duplicate /O  w1, fit1_w1
fit1_w1= Nan

CurveFit /NTHR=0/TBOX=0/Q exp_XOffset,  kwCWave=W_FitCoeff, w1 (tExp1FitStart, tExp1FitEnd) /D = fit1_w1


//WorkVar4	= W_FitCoeff[0]
//amp 		= W_FitCoeff[1]
//t0			= W_FitCoeff[3] // Corrected on 04/19/11
t0			= W_FitCoeff[2]



If (		(NumType(W_FitCoeff[0])!=0) || (NumType(W_FitCoeff[1])!=0) || (NumType(W_FitCoeff[2])!=0)		)
	Print "																			"
//	Print "Fitting error: y0, A, Tau =", WorkVar4, amp,t0, "in", CurrentRsRinCmImWName
	Print "Fitting error: y0, Tau =", WorkVar4, t0, "in", CurrentRsRinCmImWName
EndIf

Duplicate /O w1,w2
w2 = w1[p]-i_SS

//Q1 = Area(w2, tSealTestStart+wDel, tExp1FitEnd0 )	//charge due to (total current - steady state current)
Q1 = Area(w2, tSealTestStart+wDel, tSteadyStateStart) //changed 10/25/13
Q2 = (i_SS-i_BL)*t0									//When this correction is added to Q1 we get charge due to capacitative current.  
Q_Tot=Q1+Q2


	
//	TempRs=(y1-i_BL)/(abs(SealTestAmp_I)*1e-9)			
//	TempRs = (SealTestAmp_V)/(y1-i_BL)					//07/14/2008
	TempRs = t0*SealTestAmp_V/Q_Tot
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Else															
//  if weird value then it should not be used in further calculations (like RIn). 
// Therefore set =Nan.   Earlier weird value of tempRs was getting  used in further calculations		09_16_2010.  (same as in I clamp)
	TempRs = Nan			
	Endif
	
//	TempRin=((i_SS-i_BL)/(abs(SealTestAmp_I)*1e-9))-TempRs
//	TempRin =(abs(SealTestAmp_V)/(i_SS-i_BL))-TempRs
	TempRin =((SealTestAmp_V)/(i_SS-i_BL))-TempRs			//07/14/2008
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
			
	
//	TempRIn1=(abs(SealTestAmp_V)/(WorkVar3-i_BL))-TempRs
//	TempRIn1=((SealTestAmp_V)/(WorkVar4-i_BL))-TempRs
	TempCm=t0/(TempRs*TempRin/(TempRs+TempRin))							
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1500e-12) 	   			// weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
//	TempIm = SealTestAmp_V<0  ? -i_BL : i_BL
	TempIm = i_BL
	If (numtype(TempIm)==0 && TempIm>-200e-3 && TempIm<+200e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumIm+=TempIm
	TempNumIm+=1
	Endif
	
	TempTau = t0
	If (numtype(TempTau)==0 && TempTau>0 && TempTau<100e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumTau+=TempTau
	TempNumTau+=1
	EndIf

DisplayResults=1
If (DisplayResults)
Display
DoWindow pt_RsRinCmVmVclamp2Display
	If (V_Flag)
		DoWindow /F pt_RsRinCmVmVclamp2Display
//		Sleep 00:00:01
		DoWindow /K pt_RsRinCmVmVclamp2Display
	EndIf
DoWindow /c pt_RsRinCmVmVclamp2Display
	
//		AppendToGraph /W=pt_RsRinCmVmVclamp2Display w1, fit_w1, fit2_w1
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display w1,  fit1_w1
		SetAxis Bottom tBaselineStart, tSteadyStateEnd
		SetAxis /A=2 Left 
		SetDrawEnv textxjust= 2,textyjust= 2, fsize=08;DelayUpdate
		DrawText 1,0,CurrentRsRinCmImWName
		ModifyGraph rgb(fit1_w1)=(0,0,0)
		ModifyGraph lsize(fit1_w1)=2
//		Cursor A w1 0.5*(tBaselineStart+tBaselineEnd), i_BL
//		Cursor A w1 i_SS, i_BL
		Make /O/N=1 RsRinCmVmBLW, RsRinCmVmSSW//, RsRinCmVmExpPkW
		Make /O/N=1 RsRinCmVmBLWX, RsRinCmVmSSWX//, RsRinCmVmExpPkWX
		RsRinCmVmBLWX		= 0.5*(tBaselineStart+tBaselineEnd)
		RsRinCmVmBLW		= i_BL
		
		RsRinCmVmSSWX		= 0.5*(tSteadyStateStart+tSteadyStateEnd)
		RsRinCmVmSSW		= i_SS
		
//		RsRinCmVmExpPkWX	= (SealTestAmp_V > 0) ? V_MaxLoc : V_MinLoc
//		RsRinCmVmExpPkW		= y1
		
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display RsRinCmVmBLW		vs RsRinCmVmBLWX
		ModifyGraph mode(RsRinCmVmBLW)=3
		ModifyGraph marker(RsRinCmVmBLW)=19
		ModifyGraph rgb(RsRinCmVmBLW)=(0,15872,65280)
		
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display RsRinCmVmSSW		vs RsRinCmVmSSWX
		ModifyGraph mode(RsRinCmVmSSW)=3
		ModifyGraph marker(RsRinCmVmSSW	)=16
		ModifyGraph rgb(RsRinCmVmSSW)=(0,15872,65280)
		
//		AppendToGraph /W=pt_RsRinCmVmVclamp2Display RsRinCmVmExpPkW	vs RsRinCmVmExpPkWX
//		ModifyGraph mode(RsRinCmVmExpPkW)=3
//		ModifyGraph marker(RsRinCmVmExpPkW)=17
//		ModifyGraph rgb(RsRinCmVmExpPkW)=(0,15872,65280)
		
		Legend/C/N=text0/J/F=0/A=RC "\\Z08\\s(RsRinCmVmBLW) BaseLineW\r\\s(RsRinCmVmSSW) SteadyState"//\r\\s(RsRinCmVmExpPkW) RsTransient"
		DoUpdate
		Sleep /T 2
		
//DoWindow pt_RsRinCmVmVclamp2Display				05_20_2008
//	If (V_Flag)
//		DoWindow /F pt_RsRinCmVmVclamp2Display
//		Sleep 00:00:02
//		DoWindow /K pt_RsRinCmVmVclamp2Display
//	EndIf

EndIf


	
	EndFor
	
	Rs		=	SumRs	/	TempNumRs
	Rin		=	SumRin	/	TempNumRin
	Cm		=	SumCm	/	TempNumCm
	Im		=	SumIm	/	TempNumIm
	Tau		=	SumTau	/	TempNumTau
	KillWaves /z w1, fit1_w1							
	KillWaves /z RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmExpPkW
	KillWaves /z RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmExpPkWX
	
return 1
end // pt_RsRinCmVmVclamp3
//------------------------------------------------

Function pt_RsRinCmVmVclamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSealTestPeakWinDel, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp2FitStart0, tExp2FitEnd0, Rs,Rin,Cm, Im, Tau)
// superseeded by pt_RsRinCmVmVclamp3 (04_18_12)

// modified from: RsRinCmIclamp
// removed amp variable all together as it wasn't getting used 06/15/11
//t0			= W_FitCoeff[3] // Corrected on 04/19/11. Since the wave only has two points  W_FitCoeff[3] = W_FitCoeff[2] so it wasn't causing any error
//  t0			= W_FitCoeff[2]
// curvefitting exponential is difficult for the falling phase of series-resistance transient as it's very fast and only has 2-3 points before
// it gives rise to slower decay due to membrane RIn and Cm. So just for the amplitude of series resistance transient i am switching to
// finding minimum or maximum using wavestats. //07/14/2008

// changes in pt_RsRinCmVmVclamp1 to get pt_RsRinCmVmVclamp2
//  incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. 
//one advantage is that it can also fit the steady state value. plus it will make the seal test stand alone program. 07/14/2008 (already did for I clamp on 05/20/2008)


// Modifications
//** earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of seal test. but still kept using tBaselineEnd0 to 
//extrapolate the exp. to get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran  
// Feb.28th 2008 Praveen
// ** the steady state of exponential is not necessarily same as steady state at end of seal test (eg. some voltage and time dependent conductance (eg. Ih) 
//	can change during later part of the seal test). so calculate the steady state of exponential early on (WorkVar3). so use WorkVar3 instead of WorkVar2 
//	for fitting of exponential and calculation of Rs, Cm.
//** Often in V-clamp seal test two exponential decays can be seen. the first fast decay is charge on pipette capacitance leaking thru the resistors, the second slower 
//decay is due to cell capacitance charge leaking. the 2nd exponential decay should be used for calculation of cell membrane capacitance.
//** also output Vm, as we are calculating it anyway.
//** also changed the tBaselineEnd0 to 0.0499 s instead of 0.05 s. earlier it was off by 0.1 ms which was causing a small error. correspondingly, 
//	exponential fit starts later. 
//** to distinguish the new analysis, the output waves are RsV, RinV, CmV, VmV, TauV instead of RsW, RinW, CmW, VmW, TauV.


variable tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSealTestPeakWinDel, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp2FitStart0, tExp2FitEnd0, &Rs,&Rin,&Cm, &Im, &Tau
wave w
// removed amp variable all together as it wasn't getting used 06/15/11
//variable i, WorkVar1,WorkVar2,t0,y1, WorkVar3,	 WorkVar4, negativeWorkVar3,SumRs,SumRin,SumCm, SumIm, SumTau, TempRs,TempRin, TempRin1, TempCm, TempIm, TempTau, TempNumRs, TempNumRin, TempNumCm, TempNumIm, TempNumTau
variable i, WorkVar1,WorkVar2,amp,t0,y1, WorkVar3,	 WorkVar4, negativeWorkVar3,SumRs,SumRin,SumCm, SumIm, SumTau, TempRs,TempRin, TempRin1, TempCm, TempIm, TempTau, TempNumRs, TempNumRin, TempNumCm, TempNumIm, TempNumTau			
variable tBaselineStart, tBaselineEnd, tSealTestStart, tSteadyStateStart, tSteadyStateEnd, tExp2FitStart, tExp2FitEnd, DisplayResults
SVAR CurrentRsRinCmImWName=CurrentRsRinCmImWName

	i=0; 
	WorkVar1=0; WorkVar2=0; WorkVar3=0; 
//	amp=0; t0=0; y1=0;
	t0=0; y1=0;  
	SumRs=0; SumRin=0; SumCm=0; SumIm=0; SumTau=0
	Rs=0; Rin=0; Cm=0; Im=0; Tau=0
	TempRs=0; TempRin=0; TempRin1=0; TempCm=0; TempIm=0; TempTau=0
	TempNumRs=0; TempNumRin=0; TempNumCm=0; TempNumIm=0; TempNumTau=0
	tBaselineStart=0;tBaselineEnd=0;
	tSealTestStart=0
	tSteadyStateStart=0;tSteadyStateEnd=0
//	tExp1SteadyStateStart=0; tExp1SteadyStateEnd=0
//	tExp1FitStart=0; tExp1FitEnd=0
//	tExp2SteadyStateStart=0; tExp2SteadyStateEnd=0
	tExp2FitStart=0; tExp2FitEnd=0
//	tBaselineStart		 =	tBaselineStart0
//	tBaselineEnd			 =	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd		 =	tSteadyStateEnd0
	
	duplicate /o w,w1
	Rs=Nan; Rin=Nan; Cm=Nan; Im=Nan; Tau=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN

//	if (SealTestAmp_V<0)
//		w1 *= -1
//	endif
	
	For  (i=0;i<NumRepeat;i+=1)	
//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline V_m before sealtest [V]

	tSealTestStart = tSealTestStart0 + i*RepeatPeriod
//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

//	tStart=tBaselineEnd+0.0001	
//	tExp1FitStart	=tExp1FitStart0	+ i*RepeatPeriod								//finally this values should be input by user thru the interface.
//	tExp1FitEnd	=tExp1FitEnd0	+ i*RepeatPeriod
	
	tExp2FitStart	=tExp2FitStart0	+ i*RepeatPeriod								//finally this values should be input by user thru the interface.
	tExp2FitEnd	=tExp2FitEnd0	+ i*RepeatPeriod
	
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> V_m at peak value of sealtest [V]
	
//	tExp1SteadyStateStart	=	tExp1SteadyStateStart0		+	i*RepeatPeriod
//	tExp1SteadyStateEnd  	=	tExp1SteadyStateEnd0		+	i*RepeatPeriod
//	WorkVar3			=	mean(w1,tExp1SteadyStateStart,tExp1SteadyStateEnd)	
	
// 	Equation to fit I(t)=I(Inf)+(I(0)-I(Inf))*exp(-t/(Req*C))			
// 	I(t) = current through Rs or Rin+Cm parallel compbination
//	Tau=Req*C where Req=Rs*Rin/(Rs+Rin). under good V clamp effectively Rs<< Rin. so that Req=Rs.  	
//	duplicate /o w1, negativeW1
//	negativeW1=-w1
//	negativeWorkVar3=-WorkVar3
//	pt_expfit(w1,WorkVar3, tExp1FitStart, tExp1FitEnd, amp, t0)

// curvefitting exponential is difficult for the falling phase of series-resistance transient as it's very fast and only has 2-3 points before
// it gives rise to slower decay due to membrane RIn and Cm. So just for the amplitude of series resistance transient i am switching to
// finding minimum or maximum using wavestats. //07/14/2008

Wavestats /Q/R=(tSealTestStart, (tSealTestStart+tSealTestPeakWinDel)) w1


//Make /D/O/N=3 W_FitCoeff = Nan
//Duplicate /O  w1, fit_w1
//fit_w1= Nan

//CurveFit /NTHR=0/TBOX=0/Q exp_XOffset,  kwCWave=W_FitCoeff, w1 (tExp1FitStart, tExp1FitEnd) /D = fit_w1

//WorkVar3	= W_FitCoeff[0]
//amp 		= W_FitCoeff[1]
//t0			= W_FitCoeff[3]

//If (		(NumType(W_FitCoeff[0])!=0) || (NumType(W_FitCoeff[1])!=0) || (NumType(W_FitCoeff[2])!=0)		)
//	Print "																			"
//	Print "Fitting error: y0, A, Tau =", WorkVar3, amp,t0, "in", CurrentRsRinCmImWName
//EndIf

// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
	
//	y1=WorkVar3+amp*exp(-tBaselineEnd/t0)
//	y1=WorkVar3+amp*exp(-tSealTestStart/t0)
//	y1=WorkVar3+amp*exp(-(tSealTestStart- tExp1FitStart)/t0)		//07/14/2008
	y1 = (SealTestAmp_V > 0) ? V_Max : V_Min
	
//	TempRs=(y1-WorkVar1)/(abs(SealTestAmp_I)*1e-9)			
	TempRs = (SealTestAmp_V)/(y1-WorkVar1)					//07/14/2008
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Else															
//  if weird value then it should not be used in further calculations (like RIn). 
// Therefore set =Nan.   Earlier weird value of tempRs was getting  used in further calculations		09_16_2010.  (same as in I clamp)
	TempRs = Nan			
	Endif
	
//	TempRin=((WorkVar2-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs
//	TempRin =(abs(SealTestAmp_V)/(WorkVar2-WorkVar1))-TempRs
	TempRin =((SealTestAmp_V)/(WorkVar2-WorkVar1))-TempRs			//07/14/2008
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
//	TempCm =t0/(TempRs*TempRin/(TempRs+TempRin))							
//	TempCm=t0/TempRin	
//	pt_expfit(w1,WorkVar2, tExpFitStart+0.0001, tExpFitEnd+0.001, amp, t0)					
//	WorkVar3			=	mean(w1,tExp2SteadyStateStart,tExp2SteadyStateEnd)
//	pt_expfit(w1,WorkVar3, tExp2FitStart, tExp2FitEnd, amp, t0)

Make /D/O/N=3 W_FitCoeff = Nan
Duplicate /O  w1, fit2_w1
fit2_w1= Nan

CurveFit /NTHR=0/TBOX=0/Q exp_XOffset,  kwCWave=W_FitCoeff, w1 (tExp2FitStart, tExp2FitEnd) /D = fit2_w1


WorkVar4	= W_FitCoeff[0]
//amp 		= W_FitCoeff[1]
//t0			= W_FitCoeff[3] // Corrected on 04/19/11
t0			= W_FitCoeff[2]

If (		(NumType(W_FitCoeff[0])!=0) || (NumType(W_FitCoeff[1])!=0) || (NumType(W_FitCoeff[2])!=0)		)
	Print "																			"
//	Print "Fitting error: y0, A, Tau =", WorkVar4, amp,t0, "in", CurrentRsRinCmImWName
	Print "Fitting error: y0, Tau =", WorkVar4, t0, "in", CurrentRsRinCmImWName
EndIf
			
	
//	TempRIn1=(abs(SealTestAmp_V)/(WorkVar3-WorkVar1))-TempRs
	TempRIn1=((SealTestAmp_V)/(WorkVar4-WorkVar1))-TempRs
	TempCm=t0/(TempRs*TempRin1/(TempRs+TempRin1))							
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1500e-12) 	   			// weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
//	TempIm = SealTestAmp_V<0  ? -WorkVar1 : WorkVar1
	TempIm = WorkVar1
	If (numtype(TempIm)==0 && TempIm>-200e-3 && TempIm<+200e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumIm+=TempIm
	TempNumIm+=1
	Endif
	
	TempTau = t0
	If (numtype(TempTau)==0 && TempTau>0 && TempTau<100e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumTau+=TempTau
	TempNumTau+=1
	EndIf

DisplayResults=1
If (DisplayResults)
Display
DoWindow pt_RsRinCmVmVclamp2Display
	If (V_Flag)
		DoWindow /F pt_RsRinCmVmVclamp2Display
//		Sleep 00:00:01
		DoWindow /K pt_RsRinCmVmVclamp2Display
	EndIf
DoWindow /c pt_RsRinCmVmVclamp2Display
	
//		AppendToGraph /W=pt_RsRinCmVmVclamp2Display w1, fit_w1, fit2_w1
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display w1,  fit2_w1
		SetAxis Bottom tBaselineStart, tSteadyStateEnd
		SetAxis /A=2 Left 
		SetDrawEnv textxjust= 2,textyjust= 2, fsize=08;DelayUpdate
		DrawText 1,0,CurrentRsRinCmImWName
		ModifyGraph rgb(fit2_w1)=(0,0,0)
		ModifyGraph lsize(fit2_w1)=2
//		Cursor A w1 0.5*(tBaselineStart+tBaselineEnd), WorkVar1
//		Cursor A w1 WorkVar2, WorkVar1
		Make /O/N=1 RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmExpPkW
		Make /O/N=1 RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmExpPkWX
		RsRinCmVmBLWX		= 0.5*(tBaselineStart+tBaselineEnd)
		RsRinCmVmBLW		= WorkVar1
		
		RsRinCmVmSSWX		= 0.5*(tSteadyStateStart+tSteadyStateEnd)
		RsRinCmVmSSW		= WorkVar2
		
		RsRinCmVmExpPkWX	= (SealTestAmp_V > 0) ? V_MaxLoc : V_MinLoc
		RsRinCmVmExpPkW		= y1
		
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display RsRinCmVmBLW		vs RsRinCmVmBLWX
		ModifyGraph mode(RsRinCmVmBLW)=3
		ModifyGraph marker(RsRinCmVmBLW)=19
		ModifyGraph rgb(RsRinCmVmBLW)=(0,15872,65280)
		
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display RsRinCmVmSSW		vs RsRinCmVmSSWX
		ModifyGraph mode(RsRinCmVmSSW)=3
		ModifyGraph marker(RsRinCmVmSSW	)=16
		ModifyGraph rgb(RsRinCmVmSSW)=(0,15872,65280)
		
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display RsRinCmVmExpPkW	vs RsRinCmVmExpPkWX
		ModifyGraph mode(RsRinCmVmExpPkW)=3
		ModifyGraph marker(RsRinCmVmExpPkW)=17
		ModifyGraph rgb(RsRinCmVmExpPkW)=(0,15872,65280)
		
		Legend/C/N=text0/J/F=0/A=RC "\\Z08\\s(RsRinCmVmBLW) BaseLineW\r\\s(RsRinCmVmSSW) SteadyState\r\\s(RsRinCmVmExpPkW) RsTransient"
		DoUpdate
		Sleep /T 30
		
//DoWindow pt_RsRinCmVmVclamp2Display				05_20_2008
//	If (V_Flag)
//		DoWindow /F pt_RsRinCmVmVclamp2Display
//		Sleep 00:00:02
//		DoWindow /K pt_RsRinCmVmVclamp2Display
//	EndIf

EndIf


	
	EndFor
	
	Rs		=	SumRs	/	TempNumRs
	Rin		=	SumRin	/	TempNumRin
	Cm		=	SumCm	/	TempNumCm
	Im		=	SumIm	/	TempNumIm
	Tau		=	SumTau	/	TempNumTau
	KillWaves /z w1, fit2_w1							
	KillWaves /z RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmExpPkW
	KillWaves /z RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmExpPkWX
	
return 1
end








//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// pseudo-multi seal tests. take average over small baselines and average the averages. helps reduce noise for v-clamp when current is in denominator (R=V/I)
// RepeatPeriod = RT_SealTestWidth
Function pt_RsRinCmVclamp1(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0, tSealTestStarts0, SealTestAmp_V,NumRepeat,RepeatPeriod,Rs,Rin,Cm)
variable tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0, tSealTestStarts0, SealTestAmp_V,NumRepeat,RepeatPeriod,&Rs,&Rin,&Cm
wave w
variable i,WorkVar1,WorkVar2,tStart,tEnd, amp,tau,y1,SumRs,SumRin,SumCm,TempRs,TempRin,TempCm,TempNumRs,TempNumRin,TempNumCm
variable tBaselineStart, tBaselineEnd, tSteadyStateStart, tSteadyStateEnd
	
	i=0; WorkVar1=0; WorkVar2=0; tStart=0; tEnd=0; amp=0; tau=0; y1=0; SumRs=0; SumRin=0; SumCm=0; Rs=0; Rin=0; Cm=0
	TempRs=0; TempRin=0; TempCm=0; TempNumRs=0; TempNumRin=0; TempNumCm=0;tBaselineStart=0;tBaselineEnd=0;tSteadyStateStart=0;tSteadyStateEnd=0
		
	duplicate /o w,w1
	Rs=Nan; Rin=Nan; Cm=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN
	if (SealTestAmp_V<0)
		w1 *= -1
	endif
//	tBaselineStart		 =	 tBaselineStart0
//	tBaselineEnd			 =	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd		 =	tSteadyStateEnd0
	
	For  (i=0;i<NumRepeat;i+=1)

//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
//	Print tBaselineEnd
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline I_m before sealtest [A]

//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

//	tStart=tBaselineEnd+0.001											//finally this values should be input by user thru the interface.
	tStart=tSealTestStarts0+dimdelta(w1,0)
	tEnd=tStart+0.001

	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> I_m at peak value of sealtest [A]
//	print "****",tBaselineStart, tBaselineEnd, tSteadyStateStart, tSteadyStateEnd, tStart, tEnd
	//edit w1
	pt_expfit(w1,WorkVar2,tStart,tEnd,amp,tau)
	y1=WorkVar2+amp*exp(-tSealTestStarts0/tau)
	
	TempRs =abs(SealTestAmp_V)/(y1-WorkVar1)
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Endif
	
	TempRin =(abs(SealTestAmp_V)/(WorkVar2-WorkVar1))-TempRs
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
	TempCm =tau/(TempRs*TempRin/(TempRs+TempRin))
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1000e-12) 	    // weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
//	Print TempRs,TempRin,TempCm	
	EndFor
	
	Rs=SumRs/TempNumRs
	Rin=SumRin/TempNumRin
	Cm=SumCm/TempNumCm
	KillWaves w1
return 1
end

// calculation of RsRinCm in I-clamp		(Not-good for I-clamp as voltage takes a long time to reach steady state, so only the end of seal test can be used)
// RepeatPeriod = RT_SealTestWidth
Function pt_RsRinCmIclamp1(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0, tSealTestStarts0, SealTestAmp_I,NumRepeat,RepeatPeriod,Rs,Rin,Cm)
variable tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0, tSealTestStarts0, SealTestAmp_I,NumRepeat,RepeatPeriod,&Rs,&Rin,&Cm
wave w
variable i, WorkVar1,WorkVar2,tStart,tEnd,amp,tau,y1,negativeWorkVar2,SumRs,SumRin,SumCm,TempRs,TempRin,TempCm,TempNumRs,TempNumRin,TempNumCm				
variable tBaselineStart, tBaselineEnd, tSteadyStateStart, tSteadyStateEnd

	i=0; WorkVar1=0; WorkVar2=0; tStart=0; tEnd=0; amp=0; tau=0; y1=0; SumRs=0; SumRin=0; SumCm=0; Rs=0; Rin=0; Cm=0
	TempRs=0; TempRin=0; TempCm=0; TempNumRs=0; TempNumRin=0; TempNumCm=0;tBaselineStart=0;tBaselineEnd=0;tSteadyStateStart=0;tSteadyStateEnd=0
//	tBaselineStart		 =	tBaselineStart0
//	tBaselineEnd			 =	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd		 =	tSteadyStateEnd0
	
	duplicate /o w,w1
	
	if (SealTestAmp_I<0)
		w1 *= -1
	endif
	
	For  (i=0;i<NumRepeat;i+=1)	
//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline V_m before sealtest [V]

//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

	tStart=tSealTestStarts0+0.0001												//finally this values should be input by user thru the interface.
	tEnd=tStart+0.005
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> V_m at peak value of sealtest [V]
//	print "****",tBaselineStart, tBaselineEnd, tSteadyStateStart, tSteadyStateEnd, tStart, tEnd
	duplicate /o w1, negativeW1
	negativeW1=-w1
	negativeWorkVar2=-WorkVar2
	pt_expfit(negativeW1,negativeWorkVar2,tStart,tEnd,amp,tau)
	y1=WorkVar2-amp*exp(-tSealTestStarts0/tau)
	
	TempRs=(y1-WorkVar1)/(abs(SealTestAmp_I)*1e-9)
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Endif
	
	TempRin=((WorkVar2-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
	TempCm=tau/TempRin
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1000e-12) 	    // weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
	EndFor
	
	Rs=SumRs/TempNumRs
	Rin=SumRin/TempNumRin
	Cm=SumCm/TempNumCm
	KillWaves w1
return 1
end

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Take "long" baseline after seal test. as its long therefore can smooth and average.

Function pt_RsRinCmVclamp2(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0, tSealTestStarts0, SealTestAmp_V, NoisePolarity, NumRepeat,RepeatPeriod,Rs,Rin,Cm)
variable tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0, tSealTestStarts0, SealTestAmp_V, NoisePolarity, NumRepeat,RepeatPeriod,&Rs,&Rin,&Cm
wave w
variable i,WorkVar1,WorkVar2,tStart,tEnd, amp,tau,y1,SumRs,SumRin,SumCm,TempRs,TempRin,TempCm,TempNumRs,TempNumRin,TempNumCm
variable tBaselineStart, tBaselineEnd, tSteadyStateStart, tSteadyStateEnd, tSealTestStarts, WorkVar1Alt, WorkVar2Alt, NoisePolarity1
	
	i=0; WorkVar1=0; WorkVar2=0; tStart=0; tEnd=0; amp=0; tau=0; y1=0; SumRs=0; SumRin=0; SumCm=0; Rs=0; Rin=0; Cm=0
	TempRs=0; TempRin=0; TempCm=0; TempNumRs=0; TempNumRin=0; TempNumCm=0;tBaselineStart=0;tBaselineEnd=0
	tSteadyStateStart=0;tSteadyStateEnd=0; tSealTestStarts=0	
	duplicate /o w, w1
	NoisePolarity1 = NoisePolarity
	Rs=Nan; Rin=Nan; Cm=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN
	if (SealTestAmp_V<0)
		w1 *= -1
		NoisePolarity1 *= -1
	endif
//	tBaselineStart		 =	 tBaselineStart0
//	tBaselineEnd			 =	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd 		=	tSteadyStateEnd0
//	tSealTestStarts		=	tSealTestStarts0
	For  (i=0;i<NumRepeat;i+=1)

//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
//	Print tBaselineEnd
	pt_MeasureBaseLine("w1", tBaselineStart, tBaselineEnd, 750, WorkVar1, NoisePolarity1, WorkVar1Alt)
//	WorkVar1=  WorkVar1Alt
//	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline I_m before sealtest [A]

//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

//	tStart=tBaselineEnd+0.001											//finally this values should be input by user thru the interface.
	tSealTestStarts = tSealTestStarts0 + i*RepeatPeriod
	tStart=tSealTestStarts+dimdelta(w1,0)
	tEnd=tStart+0.001

	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	pt_MeasureBaseLine("w1", tSteadyStateStart, tSteadyStateEnd, 750,WorkVar2, NoisePolarity1, WorkVar2Alt)
//	WorkVar2=WorkVar2Alt
//	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> I_m at peak value of sealtest [A]

	//edit w1
	pt_expfit(w1,WorkVar2,tStart,tEnd,amp,tau)
	y1=WorkVar2+amp*exp(-tSealTestStarts/tau)
	
	TempRs =abs(SealTestAmp_V)/(y1-WorkVar1)
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Endif
	
	TempRin =(abs(SealTestAmp_V)/(WorkVar2-WorkVar1))-TempRs
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
	TempCm =tau/(TempRs*TempRin/(TempRs+TempRin))
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1000e-12) 	    // weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
//	Print TempRs,TempRin,TempCm	
	EndFor
	
	Rs=SumRs/TempNumRs
	Rin=SumRin/TempNumRin
	Cm=SumCm/TempNumCm
	KillWaves w1
return 1
end

// calculation of RsRinCm in I-clamp		(Not-good for I-clamp as voltage takes a long time to reach steady state, so only the end of seal test can be used)
Function pt_RsRinCmIclamp2(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0 ,tSealTestStarts0, SealTestAmp_I,NumRepeat,RepeatPeriod,Rs,Rin,Cm)
variable tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0, tSealTestStarts0, SealTestAmp_I,NumRepeat,RepeatPeriod,&Rs,&Rin,&Cm
wave w
variable i, WorkVar1,WorkVar2,tStart,tEnd,amp,tau,y1,negativeWorkVar2,SumRs,SumRin,SumCm,TempRs,TempRin,TempCm,TempNumRs,TempNumRin,TempNumCm				
variable tBaselineStart, tBaselineEnd, tSteadyStateStart, tSteadyStateEnd,  tSealTestStarts

	i=0; WorkVar1=0; WorkVar2=0; tStart=0; tEnd=0; amp=0; tau=0; y1=0; SumRs=0; SumRin=0; SumCm=0; Rs=0; Rin=0; Cm=0
	TempRs=0; TempRin=0; TempCm=0; TempNumRs=0; TempNumRin=0; TempNumCm=0;tBaselineStart=0;tBaselineEnd=0
	tSteadyStateStart=0;tSteadyStateEnd=0; tSealTestStarts=0
//	tBaselineStart		 =	tBaselineStart0
//	tBaselineEnd			 =	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd		 =	tSteadyStateEnd0
//	tSealTestStarts		 = 	tSealTestStarts0
	
	duplicate /o w,w1
	
	if (SealTestAmp_I<0)
		w1 *= -1
	endif
	
	For  (i=0;i<NumRepeat;i+=1)	
//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline V_m before sealtest [V]

//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000
	tSealTestStarts = tSealTestStarts0 + i*RepeatPeriod
	tStart=tSealTestStarts+0.0001												//finally this values should be input by user thru the interface.
	tEnd=tStart+0.005
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> V_m at peak value of sealtest [V]
	
	duplicate /o w1, negativeW1
	negativeW1=-w1
	negativeWorkVar2=-WorkVar2
	pt_expfit(negativeW1,negativeWorkVar2,tStart,tEnd,amp,tau)
	y1=WorkVar2-amp*exp(-tSealTestStarts/tau)
	
	TempRs=(y1-WorkVar1)/(abs(SealTestAmp_I)*1e-9)
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Endif
	
	TempRin=((WorkVar2-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
	TempCm=tau/TempRin
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1000e-12) 	    // weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
	EndFor
	
	Rs=SumRs/TempNumRs
	Rin=SumRin/TempNumRin
	Cm=SumCm/TempNumCm
	KillWaves w1
return 1
end

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function pt_expfit(w,steadyY,startX,finishX,amp,tau)
Wave w
Variable steadyY,startX,finishX,&amp,&tau
Variable intercept,slope
// eqn to fit is y(t)=steadyY+amp*exp(-t/tau)
// ln(y(t)-steadyY)=ln(amp)-t/tau
Duplicate /o w,lny
lny=ln(w-steadyY)
pt_linearfit(lny,startX,finishX,slope,intercept)
amp=exp(intercept)
tau=(-1/slope)
killwaves /z lny
end

Function pt_linearfit(w,startX,finishX,slope,intercept)
wave w
Variable startX,finishX,&slope,&intercept
// fit straight line w(x)=intercept+slope*x in the range startX to finishX
variable startPoint,finishPoint, i, meanX,meanY, MeanXY, MeanX2
startPoint=x2pnt(w,startX)
finishPoint=x2pnt(w,finishX)
make /d/o/n=(1+finishPoint-startPoint) xx,yy,x2,xy
xx=pnt2x(w,startPoint)+p*deltax(w)
yy=w[startPoint+p]
	For (i=startPoint; i<=finishPoint; i+=1)	// if Nan in y value, assign Nan to x value also. else mean of X is incorrect. (praveen taneja 08/18/2004)
		If (NumType(yy[i])!=0)
			xx[i]=Nan
		EndIf
	EndFor	
//display xx, yy
//meanX=mean(xx,-inf,inf)	
//meanY=mean(yy,-inf,inf)	// replacing with wavestats, as "mean" gives NaN, if any pt. is NaN.
WaveStats /q xx
meanX= V_Avg
WaveStats /q yy
meanY= V_Avg
// slope = [mean(xy)-mean(x).mean(y)]/[mean(x**2)-(mean(x))**2]
//          = mean((x-mean(x))*y)/mean((x-mean(x))*x)
//intercept=mean(y)-slope*mean(x)
x2=(xx-meanX)*xx
xy=(xx-meanX)*yy
//slope = mean(xy,-inf,inf)/mean(x2,-inf,inf)  // replacing with wavestats, as "mean" gives NaN, if any pt. is NaN.
WaveStats /q xy
MeanXY = V_Avg
WaveStats /q x2
MeanX2 = V_Avg
slope = MeanXY/MeanX2 //mean(xy,-inf,inf)/mean(x2,-inf,inf)
intercept=meanY-slope*meanX
killwaves /z xx,yy,x2,xy
end

// function to add the number of selected minis in a wave (12/11/2002)
// the function now adds the total number of waves (before adding number of minis in each) and reports bad 
// values. (02/14/03)
//function add_selected(WaveInterval)	renamed as pt_AddSelected
function pt_AddSelected(WaveInterval)
Variable WaveInterval
variable i,ilast,j,total,totalwaveno
wave numberVW,selectionVW
totalwaveno=num_waves(numberVW)
make /o/n=(totalwaveno) num_mini  
ilast=0
	for (j=0;j<totalwaveno;j+=1)
		if (numtype(numberVW[ilast])!=0)
		print "Error: Nan on line",ilast,"!!!!. Replace by num. of lines in this wave (usually by 1, if its a bad wave with no minis)" 
		return -1	//// usually a bad wave (saturated or very noisy)
		endif
		total=0
			for (i=ilast;(i-ilast)<numberVW[ilast];i+=1)
				total=total+selectionVW[i]
			endfor
		ilast=i
		num_mini[j]=total
	endfor
// converting to frequency
	num_mini=num_mini/WaveInterval
	appendtotable num_mini
//	print "Done...Total no of waves =",totalwaveno
	print "Done...Total no of waves =",j
return 1
end
function num_waves(numberVW)
wave numberVW
wavestats /Q numberVW
return V_npnts
end

Function pt_ConvertImToVm(ImWavName, RinWavName, VCom, AutoZero, VIni)
// Convert holding current to membrane voltage
// Example Usage: pt_ConvertImToVm("Cell_001308_Vm", "Cell_001308_Seal", -0.09, 1, -65.7e-3)
String ImWavName, RinWavName
Variable VCom, AutoZero, VIni
Duplicate /o $ImWavName, $(ImWavName+"Cal")
Wave w = $(ImWavName+"Cal")
Wave w1 = $RinWavName
If (AutoZero)
	w = VCom - w*w1	 - (VCom- VIni)	// Vm = VCommand - IHold*Rin
else
	w = VCom - w*w1
EndIf	
Return 1 
End


function pt_GenTimeCourse()

// This is always the latest version
// if DataWaveName = SelectionVW then instead of average give total which is equal to number of events in wave. divide by time to get frequency 11_12_2008
// Modifying to the new coding style of variables being global

// Modific of pt_AddSelected. pt_AddSelected used to add the selected events (added zero if not selected) and divide by time interval to get frequency
// pt_GenTimeCourse does the same for any wave (eg. RsVW), can accept pts based on boolean "Only Selected". eg. if in a wave it finds 20 events out of which 
// only 10 are selected then it calculates average value only from those 10 events. The func can be used in place of  pt_AddSelected also.

String LastUpdatedMM_DD_YYYY="11_18_2007"
String DataWaveName
Variable OnlySelected
variable i,ilast,j,TotalYVal,TotalNum,totalwaveno

Print "*********************************************************"
Print "pt_GenTimeCourse last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_GenTimeCourse"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_GenTimeCourse"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_GenTimeCourse!!!"
EndIf

DataWaveName			=	AnalParW[0]
OnlySelected			=	Str2Num(AnalParW[1])


PrintAnalPar("pt_GenTimeCourse")


Wave numberVW, SelectionVW
Wave DataWaveNamePtr = $(DataWaveName)
totalwaveno=num_waves(numberVW)
make /o/n=(totalwaveno)   $(DataWaveName + "_TmCrs")
Wave DestWaveNamePtr = $(DataWaveName + "_TmCrs")
ilast=0
	for (j=0;j<totalwaveno;j+=1)
		if (numtype(numberVW[ilast])!=0)
		print "Error: Nan on line",ilast,"!!!!. Replace by num. of lines in this wave (usually by 1, if its a bad wave with no minis)" 
		return -1	//// usually a bad wave (saturated or very noisy)
		endif
		TotalYVal=0
		TotalNum = 0
			for (i=ilast;(i-ilast)<numberVW[ilast];i+=1)
				If (NumType(DataWaveNamePtr[i])==0) 
					If (OnlySelected)
						if (SelectionVW[i]==1) 
							totalYVal=totalYVal+DataWaveNamePtr[i]
							TotalNum = TotalNum + 1
						Endif
					else
						totalYVal=totalYVal+DataWaveNamePtr[i]
						TotalNum = TotalNum + 1
					Endif	
				EndIf								
			endfor
		ilast=i
		DestWaveNamePtr[j]=totalYVal/TotalNum	
		If (StringMatch(DataWaveName, "SelectionVW"))				// this is total number of events per wave.
																// divide by time period to get frequnecy  praveen 11_12_2008
		DestWaveNamePtr[j]=totalYVal
		EndIf
	endfor
//	appendtotable DestWaveNamePtr
//	print "Done...Total no of waves =",totalwaveno
	print "Done...Total no of waves =",j
return 1
end

Function pt_DiceIntoIndWaves()
// pt_GenTimeCourse calculates the average value of the parameter like decaytime, peak amplitude for individual waves. For
// Cummulative histogram generation individual points are needed. This program will dice the concatenated parameter wave
// into individual waves, and then the baseline or drug waves from all cells can be combined to form baseline/ drug parameter 
// values. 
// partly based on pt_GenTimeCourse

String LastUpdatedMM_DD_YYYY="02_18_2010"
String DataWaveName, OutWBaseName
Variable OnlySelected
variable ilast,j,totalwaveno

Print "*********************************************************"
Print "pt_pt_DiceIntoIndWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"
Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_DiceIntoIndWaves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_DiceIntoIndWaves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_DiceIntoIndWaves!!!"
EndIf

DataWaveName			=	AnalParW[0]
OnlySelected			=	Str2Num(AnalParW[1])
OutWBaseName			= 	AnalParW[2]

PrintAnalPar("pt_DiceIntoIndWaves")

Wave numberVW, SelectionVW

Wave DataWaveNamePtr = $(DataWaveName)
If (OnlySelected)
	Duplicate /O DataWaveNamePtr, $(DataWaveName+"Slct1")
	pt_FilterWave("SelectionVW", 1, 1,DataWaveName+"Slct1", DataWaveName+"Slct1", Nan)
	Wave DataWaveNamePtr = $(DataWaveName+"Slct1")		
Endif


totalwaveno=num_waves(numberVW)
ilast=0
	for (j=0;j<totalwaveno;j+=1)
		if (numtype(numberVW[ilast])!=0)
		print "Error: Nan on line",ilast,"!!!!. Replace by num. of lines in this wave (usually by 1, if its a bad wave with no minis)" 
		return -1	//// usually a bad wave (saturated or very noisy)
		endif
//		Print ilast, numberVW[ilast]
		 // j+1 so that wave names start from 1
		Duplicate /O/R=[ilast, (ilast+numberVW[ilast]-1)] DataWaveNamePtr, $(OutWBaseName + pt_PadZeros2IntNum(j+1, 3))
		ilast+=numberVW[ilast]
	endfor
//	appendtotable DestWaveNamePtr
//	print "Done...Total no of waves =",totalwaveno
	print "Done...Total no of waves =",j
return 1
KillWaves $(DataWaveName+"Slct1")

End

Function pt_ConcatEpochWaves()
// pt_DiceIntoIndWaves() dices the concatenated wave into individual waves for parameters like decay time, peak amp,
// etc. pt_ConcatEpochWaves concatenates waves from an epoch into a single wave. Eg. if baseline is from 1, 12 waves
// then pt_ConcatEpochWaves will concatenate 1, 12 waves into a BL Wave. It does allow for an initial offset (cos many times)
// the baseline starts after a few trial waves. pt_ConcatEpochWaves() will use information from pt_MiniEpochParW (also used by
// pt_AllignWaves) to get the offset info.
String WPathWName
Variable PntNum, X0
String DataWaveMatchStr, OutWName 
Variable StartWaveNum, EndWaveNum
String WList, WNameStr
Variable N, i

String LastUpdatedMM_DD_YYYY="02_19_2010"


Print "*********************************************************"
Print "pt_ConcatEpochWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AllignWaves", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_AllignWaves", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_AllignWaves!!!"
EndIf


WPathWName = AnalParW[0]
PntNum		   = Str2Num(AnalParW[1])

// allign all waves so that Start pnt has x value =0.
X0 = pt_GetOnePnt(WPathWName, PntNum)
							
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConcatEpochWaves", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_ConcatEpochWaves", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_AllignWaves!!!"
EndIf

DataWaveMatchStr 	= AnalParW[0]
StartWaveNum 		= Str2Num(AnalParW[1])
EndWaveNum		= Str2Num(AnalParW[2])
OutWName 			= AnalParW[3]

PrintAnalPar("pt_ConcatEpochWaves")

// example: take baseline from 1, 12 waves (total 12 waves). But 1st baseline wave is the 5th recorded wave
// as waves 1 to 4 were waiting for stability, etc. So we should take waves from 5, 16. 

StartWaveNum 	+=X0-1
EndWaveNum 	+=X0-1
N = EndWaveNum - StartWaveNum +1

Make /O/N=0 $(OutWName)
Wave w = $(OutWName)

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
For (i=StartWaveNum; i<(StartWaveNum+N); i+=1)
	WNameStr=StringFromList(i-1, WList, ";") // i-1 because wavelist index starts from 0. 
	Wave w1=$WNameStr
	Concatenate /NP {w1}, w
EndFor
Print "Concatenated", N, "waves from", StartWaveNum, "to", EndWaveNum, "Last Wave=", WNameStr
End


function pt_SortMinisByWaves()

// This is always the latest version
// modified from pt_GenTimeCourse(). Uses the MiniWaves extracted using pt_ExtractMiniWAll() and sort them to minis in different waves

String LastUpdatedMM_DD_YYYY="01_09_2009"
String MiniWaveBaseNameStr
Variable OnlySelected
variable i,ilast,j,TotalYVal,TotalNum,totalwaveno

Print "*********************************************************"
Print "pt_SortMinisByWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_SortMinisByWaves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_SortMinisByWaves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_SortMinisByWaves!!!"
EndIf

MiniWaveBaseNameStr	=	AnalParW[0]
OnlySelected			=	Str2Num(AnalParW[1])


PrintAnalPar("pt_SortMinisByWaves")


Wave numberVW, SelectionVW
totalwaveno=num_waves(numberVW)

ilast=0
	for (j=0;j<totalwaveno;j+=1)
		if (numtype(numberVW[ilast])!=0)
		print "Error: Nan on line",ilast,"!!!!. Replace by num. of lines in this wave (usually by 1, if its a bad wave with no minis)" 
		return -1	//// usually a bad wave (saturated or very noisy)
		EndIf
		TotalNum = 0
			for (i=ilast;(i-ilast)<numberVW[ilast];i+=1)
//				If (NumType(DataWaveNamePtr[i])==0) 
					If (OnlySelected)
						if (SelectionVW[i]==1) 
//							Duplicate /O $(MiniWaveBaseNameStr+Num2Str(i)), $(MiniWaveBaseNameStr+"W"+Num2Str(j)+"_"+Num2Str(i))
							Duplicate /O $(MiniWaveBaseNameStr+pt_PadZeros2IntNum(i, 5)), $(MiniWaveBaseNameStr+"W"+pt_PadZeros2IntNum(j, 3)+"_"+pt_PadZeros2IntNum(i, 4))
							TotalNum = TotalNum + 1
						Endif
					else
//							Duplicate /O $(MiniWaveBaseNameStr+Num2Str(i)), $(MiniWaveBaseNameStr+"W"+Num2Str(j)+"_"+Num2Str(i))
							Duplicate /O $(MiniWaveBaseNameStr+pt_PadZeros2IntNum(i, 5)), $(MiniWaveBaseNameStr+"W"+pt_PadZeros2IntNum(j, 3)+"_"+pt_PadZeros2IntNum(i, 4))

							TotalNum = TotalNum + 1
					Endif	
//				EndIf								
			endfor
		ilast=i
		Print "Found", TotalNum, "waves in wave", j
	endfor
//	appendtotable DestWaveNamePtr
//	print "Done...Total no of waves =",totalwaveno
	print "Done...Total no of waves =",j
return 1
end





Function pt_GenCutOffIndex(WavName, CntrlEndVal, PntsPerBin, CutoffPercent, AbsLowerCutOff, AbsUpperCutOff, SmoothFactor, TimesSD)
// the inequality sign will change if things are multiplied by -1 on both sides.
String WavName
Variable  CntrlEndVal, PntsPerBin, CutoffPercent, AbsLowerCutOff, AbsUpperCutOff, SmoothFactor, TimesSD

String OldDataWaveMatchStr, OldSmoothFactor, OldTimesSD
Variable N, i, UpperCutOff,  LowerCutOff, Num, Num1

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_RemoveOutLiers1!!!"
EndIf


OldDataWaveMatchStr	=	AnalParW[0]
OldSmoothFactor 		=	AnalParW[1]
OldTimesSD				=	AnalParW[2]

AnalParW[0]				= 	WavName
AnalParW[1]				= 	Num2Str(SmoothFactor)
AnalParW[2]				= 	Num2Str(TimesSD)


Duplicate /o $WavName, $(WavName+"_MW")

//Num = NumPnts($WavName)
//Make /O/N=(Num) $WavName+"_MW"
Wave w = $(WavName+"_MW")

// pt_RemoveOutLiers(WavName, TimesSD)		// pt_RemoveOutLiers uses V_Avg to decide outlier. This can cause pts. to be removed if value varies a lot from avg.
print "---------------------------------------------------------------------------------------------"
DoAlert 0, "not tested after modifying the call to modified pt_RemoveOutLiers1. Check before using. modified on 02_13_2009"
pt_RemoveOutLiers1()	// pt_RemoveOutLiers1 uses smoothed curve to find outliers. thus it uses instantaneous smooth value
														// rather than global average value like pt_RemoveOutLiers
pt_CoarseBin(WavName+"_NoOL", PntsPerBin)
Wave w1 = $(WavName + "_NoOL_CBY")

//WaveStats /Q/R=[0, CntrlEndPt] w1	 // had it wrong. on coarse binning, the dimensionality changes. (praveen taneja)
WaveStats /Q/R=(0, CntrlEndVal) w1
If (V_Avg>0)
	UpperCutOff = V_Avg*(1+ 0.01*CutoffPercent)
	LowerCutOff = V_Avg*(1-  0.01*CutoffPercent)
Else
	UpperCutOff = V_Avg*(1-  0.01*CutoffPercent)
	LowerCutOff = V_Avg*(1+ 0.01*CutoffPercent)
EndIf
Printf "CntrlAvg = %+5.2e\t  UpperCutOff = %+5.2e\t  LowerCutOff = %+5.2e\t AbsUpperCutOff = %+5.2e\t  AbsLowerCutOff = %+5.2e \r"V_Avg, UpperCutOff, LowerCutOff, AbsUpperCutOff, AbsLowerCutOff
Num1=NumPnts(w1)

	For (i=0; i<Num1 ; i+=1)
		If (w1[i] > LowerCutOff && w1[i] < UpperCutOff && w1[i] > AbsLowerCutOff && w1[i] < AbsUpperCutOff)
			w[PntsPerBin*i,PntsPerBin*(i+1)-1]=1 
		Else	
			w[PntsPerBin*i,PntsPerBin*(i+1)-1]=Nan
			Print "Wave", WavName, "pts.", PntsPerBin*i, "to", PntsPerBin*(i+1)-1, "are out of bounds..."
		EndIf	 
	EndFor	
KillWaves /Z  w1, $(WavName + "_NoOL"), $(WavName + "_NoOL_CBX")
AnalParW[0]				= 	OldDataWaveMatchStr
AnalParW[1]				= 	OldSmoothFactor
AnalParW[2]				= 	OldTimesSD
Return 1
End

Function pt_GenMaskWave(WavListString, CntrlEndVal, CutOffPercentListString, AbsCutOffListString, PntsPerBin, SmoothFactor, TimesSD)
// Example Usage: 
// pt_GenMaskWave("PreRSeriesWave;PostRSeriesWave;Cell_001326_Seal;Cell_001325_Seal;Cell_001326_Vm;Cell_001325_VmCal",44,"30;30;30;30;20;20","5e6;40e6;5e6;40e6; 50e6;1500e6; 50e6;1500e6; -90e-3; -55e-3; -90e-3; -55e-3",5,5,2)

String WavListString, CutOffPercentListString, AbsCutOffListString
Variable CntrlEndVal, PntsPerBin, SmoothFactor, TimesSD
String WavNameStr
Variable Num,  i, CutOffPercent, AbsLowerCutOff, AbsUpperCutOff

Num = ItemsInList(WavListString, ";")
WavNameStr = StringFromList(0, WavListString, ";")
Duplicate /o $WavNameStr, NetMaskWave

NetMaskWave = 1

	For (i=0; i<Num; i+=1)
		WavNameStr = StringFromList(i, WavListString, ";")
		CutOffPercent = Str2Num( StringFromList(i, CutOffPercentListString, ";") )
		AbsLowerCutOff = Str2Num( StringFromList(2*i, AbsCutOffListString, ";") )
		AbsUpperCutOff = Str2Num( StringFromList((2*i)+1, AbsCutOffListString, ";") )
		pt_GenCutOffIndex(WavNameStr, CntrlEndVal, PntsPerBin, CutoffPercent, AbsLowerCutOff, AbsUpperCutOff, SmoothFactor, TimesSD)
		Wave w = $(WavNameStr+"_MW")
		NetMaskWave*=w
		KillWaves /Z w
	EndFor	

//	WaveStats /Q/R=[0,Num] CutOffsWave
//	MaskWave[0,V_Min] = 1
Return 1
End

Function pt_MultiplyWaves(InputWavName, WavToMultiplyName,OutPutWavName)
// pt_MultiplyWaves("Cell_001325_EPSP_0001", "NetMaskWave", "Cell1326To1325Epsc1")
String InputWavName, WavToMultiplyName,OutPutWavName
Duplicate /o $InputWavName, $OutPutWavName
Wave w	= $OutPutWavName
Wave w1= $WavToMultiplyName
	If (NumPnts(w) != NumPnts(w1))
		Print "Input Wave & Multiplication wave have diff. dimensions! Not Multiplying..." 
	else
		w *= w1
	EndIf
End


Function pt_RemoveOutLiers(WavNameStr, TimesSD) // pt_RemoveOutLiers uses V_Avg to decide outlier. This can cause pts. to be removed if value varies a lot from avg
// extreme outliers bias the average. shud use "mode" instead? also the inequality sign will change if things are multiplied by -1 on both sides.
String WavNameStr
Variable 	TimesSD
String OutliersStr
Variable i
Wave w = $WavNameStr
WaveStats /q w
Duplicate /o w, $(WavNameStr+"_NoOL")
Wave w1=$(WavNameStr+"_NoOL")
For (i=0;i<NumPnts(w1); i+=1)
	If (w1[i]<V_avg-TimesSD*V_Sdev || w1[i]>V_avg+TimesSD*V_Sdev)
		w1[i]=Nan
//		Print "Removed Outlier pt.", i, "from wave", WavNameStr+"_NoOL"
	EndIf
EndFor	
End

Function pt_RemoveOutLiers2()
// Renamed pt_RemoveOutLiers1 as pt_RemoveOutLiers2 and re-wrote a cleaner version of  pt_RemoveOutLiers1 11/11/13

// modified to optionally use  (median instead of mean) and (inter-quartile range instead of StandardDeviation)

//********************************************************************************************************************************************
// Outlier Criterion (*******************from the following 1.5 seems like a good factor for outliers because the included range = 4*IQ which includes most of the data***************************** )
//********************************************************************************************************************************************
//Source -  http://www.itl.nist.gov/div898/handbook/prc/section1/prc16.htm
//Box plots with fences
//A box plot is constructed by drawing a box between the upper and lower quartiles with a solid line drawn across the box to locate the median. The following quantities (called fences) are needed for identifying extreme values in the tails of the distribution:
//	1.	lower inner fence: Q1 - 1.5*IQ		(Q1 is lower quartile, Q2 is upper quartile, IQ = Q2-Q1 = interquartile range)
//	2.	upper inner fence: Q2 + 1.5*IQ
//	3.	lower outer fence: Q1 - 3*IQ
//	4.	upper outer fence: Q2 + 3*IQ
//Outlier detection criteria
//A point beyond an inner fence on either side is considered a mild outlier. A point beyond an outer fence is considered an extreme outlier.




// modified to use SubFldr 12/28/2010. ALSO SKIP BINOMIAL SMOOTHING IF WAVE HAS NANS (USING SMOOTHFACTOR =-1)
// modifying to the new coding format of passing parameters through waves. 
// extreme outliers bias the average. shud use "mode" instead? also the inequality sign will change if things are multiplied by -1 on both sides.
// pt_RemoveOutLiers1 uses smoothed curve to find outliers. thus it uses instantaneous smooth value
// rather than global average value like pt_RemoveOutLiers
String DataWaveMatchStr, SubFldr	
Variable 	SmoothFactor, TimesSD, UseMedian

String OutliersStr="", wavlist, WavNameStr
Variable j,i, NumWaves, NPnts
String LastUpdatedMM_DD_YYYY="11_11_2013"

Print "*********************************************************"
Print "pt_RemoveOutLiers1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_RemoveOutLiers1ParW and/or pt_RemoveOutLiers1ParNamesW!!!"
EndIf

DataWaveMatchStr	=	AnalParW[0]
SmoothFactor 		=	Str2Num(AnalParW[1])	// Binomial smoothing (Doesnot tetect or ignore Nans. Undefined results. Use -1 to skip smoothing)
TimesSD			=	Str2Num(AnalParW[2])
SubFldr				= 	AnalParW[3]
UseMedian			=	Str2Num(AnalParW[4])

PrintAnalPar("pt_RemoveOutLiers1")

//wavlist = wavelist(DataWaveMatchStr,";","")
WavList	= pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
NumWaves 	= ItemsInList(WavList,";")

If (SmoothFactor ==-1)			// Skip Smoothing
Print "Smoothing = None"
Print "Removing points that deviate TimesSD from Average"
Else
Print "Smoothing = Binomial" 
Print "Removing points that deviate TimesSD from Smoothed Data"
EndIf

Print "Removing Outliers from waves, N=", NumWaves, WavList

For (j=0; j<NumWaves; j+=1)
WavNameStr= StringFromList (j,wavlist,";")
if (strlen(WavNameStr)== 0)
  			Print "While finding average of waves could not find wave #", i
  			DoAlert 0, "While finding average of waves could not find wave #"+ WavNameStr//"Exiting without finishing!!"	11/11/13
 			break
endif 
//wave w = $WavNameStr
Wave w = $(GetDataFolder(1)+SubFldr+WavNameStr)
NPnts=NumPnts(w)
Duplicate /o w, $(GetDataFolder(1)+SubFldr+WavNameStr+"_NoOL")//, $(GetDataFolder(1)+SubFldr+"SmoothWave")
Wave w1=$(GetDataFolder(1)+SubFldr+WavNameStr+"_NoOL")
//Wave SmoothWave = $(GetDataFolder(1)+SubFldr+"SmoothWave")
If (NPnts>0)

If (SmoothFactor ==-1)

If (UseMedian)
//Duplicate /O w, wNoNaN
StatsQuantiles w
Print "Using TimesSD*InterQuantileRange from Lower and Upper Quartile to find OutLiers"
Print "Median =",V_Median,"LowerThresh =", V_Q25-TimesSD*V_IQR,"UpperThresh =", V_Q75+TimesSD*V_IQR
Else
WaveStats /q w
Print "Using TimesSD*StandardDev from Mean to find OutLiers"
Print "Median =",V_Avg,"LowerThresh =", V_Avg-TimesSD*V_Sdev,"UpperThresh =", V_Avg+TimesSD*V_Sdev
EndIf

Else
Duplicate /o w, $(GetDataFolder(1)+SubFldr+"SmoothWave")
Wave SmoothWave = $(GetDataFolder(1)+SubFldr+"SmoothWave")
Print "Using TimesSD*StandardDev from Smoothed Data to find OutLiers"
Smooth SmoothFactor, SmoothWave
EndIf


For (i=0;i<NPnts; i+=1)
	If (SmoothFactor ==-1)	// No Smoothing. Use deviations from V_Avg

	Switch (UseMedian)
	
	Case 0 :
	
	If (w1[i]<V_Avg-TimesSD*V_Sdev || w1[i]>V_Avg+TimesSD*V_Sdev)
		w1[i]=Nan
		OutliersStr += Num2Str(i) +"; "
	EndIf
	
	Break
	
	Case 1:
	
	If (w1[i] < V_Q25-TimesSD*V_IQR || w1[i] > V_Q75+TimesSD*V_IQR)
		w1[i]=Nan
		OutliersStr += Num2Str(i) +"; "
	EndIf
	Break
	
	EndSwitch
	Else
	If (w1[i]<SmoothWave[i]-TimesSD*V_Sdev || w1[i]>SmoothWave[i]+TimesSD*V_Sdev)
		w1[i]=Nan
		OutliersStr += Num2Str(i) +"; "
	EndIf	
	
	EndIf
EndFor	
	If (strlen(OutliersStr)!=0)
		Print "Removed from wave", WavNameStr, "outlier points", OutLiersStr
	EndIf
OutLiersStr = ""		
KillWaves /z SmoothWave
Else
	Print "Empty Wave", WavNameStr
EndIf
EndFor
End

//$$$$$
Function pt_RemoveOutLiers1()
// Renamed pt_RemoveOutLiers1 as pt_RemoveOutLiers2 and re-wrote a cleaner version of  pt_RemoveOutLiers1 11/11/13
// also accounted for the fact that for statsquantile NPnts should be >=3
// removing smoothing option. the calling function can smooth the data beforehand 11/11/13
// As TimesSD*SDev and TimesSD*V_IQR are always positive LowerThresh is always smaller than middle value (avg or median) and
// upper thresh is always higher than middle value. Thus even if w[i] is negative, the following inequality for outliers holds. 

//w1[i]< LowerThresh || w1[i]> UpperThresh

// modified to optionally use  (median instead of mean) and (inter-quartile range instead of StandardDeviation)

//********************************************************************************************************************************************
// Outlier Criterion (*******************from the following 1.5 seems like a good factor for outliers because the included range = 4*IQ which includes most of the data***************************** )
//********************************************************************************************************************************************
//Source -  http://www.itl.nist.gov/div898/handbook/prc/section1/prc16.htm
//Box plots with fences
//A box plot is constructed by drawing a box between the upper and lower quartiles with a solid line drawn across the box to locate the median. The following quantities (called fences) are needed for identifying extreme values in the tails of the distribution:
//	1.	lower inner fence: Q1 - 1.5*IQ		(Q1 is lower quartile, Q2 is upper quartile, IQ = Q2-Q1 = interquartile range)
//	2.	upper inner fence: Q2 + 1.5*IQ
//	3.	lower outer fence: Q1 - 3*IQ
//	4.	upper outer fence: Q2 + 3*IQ
//Outlier detection criteria
//A point beyond an inner fence on either side is considered a mild outlier. A point beyond an outer fence is considered an extreme outlier.




// modified to use SubFldr 12/28/2010. ALSO SKIP BINOMIAL SMOOTHING IF WAVE HAS NANS (USING SMOOTHFACTOR =-1)
// modifying to the new coding format of passing parameters through waves. 
// extreme outliers bias the average. shud use "mode" instead? also the inequality sign will change if things are multiplied by -1 on both sides.
// pt_RemoveOutLiers1 uses smoothed curve to find outliers. thus it uses instantaneous smooth value
// rather than global average value like pt_RemoveOutLiers
String DataWaveMatchStr, SubFldr	
Variable SmoothFactor, TimesSD, UseMedian

String OutliersStr="", wavlist, WavNameStr
Variable j,i, NumWaves, NPnts, LowerThresh, UpperThresh
String LastUpdatedMM_DD_YYYY="11_11_2013"

Print "*********************************************************"
Print "pt_RemoveOutLiers1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_RemoveOutLiers1ParW and/or pt_RemoveOutLiers1ParNamesW!!!"
EndIf

DataWaveMatchStr	=	AnalParW[0]
SmoothFactor 		=	Str2Num(AnalParW[1])	// Binomial smoothing (Doesnot tetect or ignore Nans. Undefined results. Use -1 to skip smoothing)
TimesSD			=	Str2Num(AnalParW[2])
SubFldr				= 	AnalParW[3]
UseMedian			=	Str2Num(AnalParW[4])

PrintAnalPar("pt_RemoveOutLiers1")

//wavlist = wavelist(DataWaveMatchStr,";","")
WavList	= pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
NumWaves 	= ItemsInList(WavList,";")

Print "Removing Outliers from waves, N=", NumWaves, WavList

For (j=0; j<NumWaves; j+=1)
	WavNameStr= StringFromList (j,wavlist,";")
	if (strlen(WavNameStr)== 0)
  		Print "While finding average of waves could not find wave #", i
  		DoAlert 0, "While finding average of waves could not find wave #"+ WavNameStr//"Exiting without finishing!!"	11/11/13
 		break
	endif 
	//wave w = $WavNameStr
	Wave w = $(GetDataFolder(1)+SubFldr+WavNameStr)
	NPnts=NumPnts(w)
	Duplicate /o w, $(GetDataFolder(1)+SubFldr+WavNameStr+"_NoOL")//, $(GetDataFolder(1)+SubFldr+"SmoothWave")
	Wave w1=$(GetDataFolder(1)+SubFldr+WavNameStr+"_NoOL")

	If (NPnts>0)

		If (UseMedian)
			//Duplicate /O w, wNoNaN
			If (NPnts >= 3)
				StatsQuantiles /q w
				Print "Using TimesSD*InterQuantileRange from Lower and Upper Quartile to find OutLiers"
				LowerThresh = V_Q25-TimesSD*V_IQR
				UpperThresh = V_Q75+TimesSD*V_IQR
				Print "Median =",V_Median,"LowerThresh =", LowerThresh,"UpperThresh =", UpperThresh
			Else 
				Print "Warning - Less than 3 points - can't find outliers in ", WavNameStr
				LowerThresh = -inf
				UpperThresh = +inf
			EndIf	
		Else
			WaveStats /q w
			Print "Using TimesSD*StandardDev from Mean to find OutLiers"
			LowerThresh = V_Avg-TimesSD*V_Sdev
			UpperThresh = V_Avg+TimesSD*V_Sdev
			Print "Mean =",V_Avg,"LowerThresh =", LowerThresh,"UpperThresh =", UpperThresh
		EndIf


		For (i=0;i<NPnts; i+=1)
			If (w1[i]< LowerThresh || w1[i]> UpperThresh)
				w1[i]=Nan
				//OutliersStr += Num2Str(i) +"; "
				OutliersStr += Num2Str(i) +"; "
			EndIf
		EndFor
	
	//If (strlen(OutliersStr)!=0)
	Print "Removed from wave:", WavNameStr, "index numbers:", OutLiersStr
	//EndIf
	OutLiersStr = ""		
	//KillWaves /z SmoothWave
	Else
		Print "Empty Wave", WavNameStr
	EndIf
EndFor
End
//$$$$$



Function pt_FilterWave(DataValWName, FilterOutLessThanVal, FilterOutGreaterThanVal, ToBeFilteredWName, DestWName, ReplaceFalseWith)
//Example:  pt_FilterWave("BLCntrlEmgRmsAmpFullW", -inf, 0.0255,"BLCntrlMeanPsdDeltaFullW", "BLCntrlMeanPsdDeltaLowEmgW", Nan)
//pt_FilterWave("BLCntrlEmgRmsAmpFullW", -inf, 0.0255,"BLCntrlMeanPsdThetaFullW", "BLCntrlMeanPsdThetaLowEmgW", Nan)
//pt_FilterWave("BLCntrlSleepScoreW", 0.5, +inf,"BLCntrlMeanPsdDeltaFullW", "BLCntrlDeltaSleepFullW", Nan)
//pt_FilterWave("BLExptSleepScoreW", 0.5, +inf,"BLExptMeanPsdDeltaFullW", "BLExptDeltaSleepFullW", Nan)

String DataValWName, ToBeFilteredWName, DestWName
Variable FilterOutLessThanVal, FilterOutGreaterThanVal, ReplaceFalseWith
Variable i, Num
If (!StringMatch(ToBeFilteredWName, DestWName))
Duplicate /O  $ToBeFilteredWName ,$DestWName
Wave w1 = $DestWName
Else
Wave w1 = $ToBeFilteredWName
EndIf

Wave w = $DataValWName
//Wave w1 = $DestWName
Num = NumPnts(w)

For (i=0; i<Num; i+=1)
//	Print w[i]
	If ( (w[i]<FilterOutLessThanVal) || (w[i]>FilterOutGreaterThanVal) )		// logic expression here
		w1[i]=ReplaceFalseWith
	EndIf
EndFor

End


Function pt_FilterWave1()
// based on pt_Filterwave but works with pt_AnalWInFldrs2 and written with more recent conventions
String DataWaveMatchStr, SubFldr, ReplaceKeptWith
Variable LowerCutOff, HigherCutOff, ReplaceFilteredWith

String WList, WNameStr
Variable i, NumWaves, KeepOrigVal, ReplaceKeptWithVal

String LastUpdatedMM_DD_YYYY="09_22_20011"

Print "*********************************************************"
Print "pt_FilterWave1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_FilterWave1", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_FilterWave1", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_FilterWave1ParW and/or pt_FilterWave1ParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
SubFldr					=	AnalParW[1]
LowerCutOff 			=	Str2Num(AnalParW[2])
HigherCutOff 			=	Str2Num(AnalParW[3])
ReplaceKeptWith 		=	AnalParW[4]			// blank means keep orig val
ReplaceFilteredWith 	=	Str2Num(AnalParW[5])

PrintAnalPar("pt_FilterWave1")

If (StringMatch(ReplaceKeptWith, ""))
KeepOrigVal = 1
Else
KeepOrigVal = 0
ReplaceKeptWithVal = Str2Num(ReplaceKeptWith)
EndIf

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
Numwaves=ItemsInList(WList, ";")

Print "Filtering Waves, N =", Numwaves, WList

For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	Duplicate /O $(GetDataFolder(1)+SubFldr+WNameStr), $(GetDataFolder(1)+SubFldr+"F_"+WNameStr)
	Wave w=$(GetDataFolder(1)+SubFldr+"F_"+WNameStr)
	If (KeepOrigVal)
	w = (w[p]>LowerCutOff && w[p]<HigherCutOff) ? w[p] : ReplaceFilteredWith
	Else
	w = (w[p]>LowerCutOff && w[p]<HigherCutOff) ? ReplaceKeptWithVal : ReplaceFilteredWith
	EndIf
EndFor 

Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+"F_sIPSCNSumW")
Wave F_SumW = $(GetDataFolder(1)+SubFldr+"F_sIPSCNSumW")

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";") 
	Wave w=$(GetDataFolder(1)+SubFldr+"F_"+WNameStr)
	If (NumPnts(w) >0)
	WaveStats /Q w		// instead of Sum(w) so that Nan's Infs can be excluded
	F_SumW[i]= V_Avg*V_NPnts
	Else
	F_SumW[i]= 0
	EndIf
EndFor 

End

Function pt_FilterBadPoints()
// Replace points for which Data is smaller than error with "ReplaceWith"
String DataWaveMatchStr, ErrorWaveMatchStr
Variable ReplaceWith, TimesError 
String DataWaveList, ErrorWaveList, DataWaveNameStr, ErrorWaveNameStr
Variable NumWaves, j

String LastUpdatedMM_DD_YYYY="05_25_2009"

Print "*********************************************************"
Print "pt_FilterBadPoints last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_FilterBadPoints", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_FilterBadPoints", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_FilterBadPointsParW and/or pt_FilterBadPointsParNamesW!!!"
EndIf

DataWaveMatchStr	=	AnalParW[0]
ErrorWaveMatchStr 	=	AnalParW[1]
TimesError			=	Str2Num(AnalParW[2])
ReplaceWith			=	Str2Num(AnalParW[3])


PrintAnalPar("pt_FilterBadPoints")

DataWaveList = wavelist(DataWaveMatchStr,";","")
ErrorWaveList = wavelist(ErrorWaveMatchStr,";","")

If (NumPnts(DataWaveList)!=NumPnts(ErrorWaveList))
Abort "UNEQUAL NUMBER OF DATA AND ERROR WAVES. ABORTING..."
Else
NumWaves = ItemsInList(DataWaveList)
EndIf

For (j=0; j<NumWaves; j+=1)
DataWaveNameStr= StringFromList (j,DataWaveList,";")
ErrorWaveNameStr= StringFromList (j,ErrorWaveList,";")

Duplicate /O $DataWaveNameStr, $(DataWaveNameStr+"Flt")
Wave DataW = $(DataWaveNameStr+"Flt")
Wave ErrorW = $(ErrorWaveNameStr)

If (NumPnts(DataW) != NumPnts(ErrorW))
	Print "UNEQUAL NUMBER OF POINTS IN", DataWaveNameStr, "and",  ErrorWaveNameStr, "NO WAVE GENERATED"
Else
	DataW = (Abs(DataW)>TimesError*Abs(ErrorW)) ? DataW : ReplaceWith
	Print "Filtered", DataWaveNameStr,",", ErrorWaveNameStr
EndIf
EndFor

End

Function pt_ReplaceWithNan(WavName, StartPt, EndPt)
String WavName
Variable	StartPt, EndPt
Variable i
Wave w = $WavName
w[StartPt,EndPt] = Nan
Print "Replaced pts. from", StartPt, "to", EndPt, "in wave", WavName, "with NaNs"
Return 1
End

Function pt_TestBaseLineStability(BaseLineStartVal, BaseLineEndVal, PntsPerBin)
// basically, need to check if the values are constant or changing. so smooth and fit a straight line and see if slope is close to zero.
// normalize, coarsebin, fit straightline.
// Example Usage: pt_TestBaseLineStability(0,44,5)
Variable BaseLineStartVal, BaseLineEndVal, PntsPerBin
Variable wavindex, slope, intercept
String WavList, WavStr

wavlist = wavelist("*",";","WIN:")
print "Testing BaseLine stability for waves...",wavlist, "from pt.", BaseLineStartVal, "to", BaseLineEndVal

pt_Normalize(BaseLineStartVal, BaseLineEndVal, "",1)

wavindex=0

do 
 	wavstr= StringFromList (wavindex,wavlist,";")
 	if (strlen(wavstr)== 0)
 	break
 	endif
 	WavStr=WavStr+"_Norm"
 	wave w = $wavStr
	pt_CoarseBin(WavStr, PntsPerBin)
	Wave w = $(WavStr+"_CBY")
	
	pt_linearfit(w,BaseLineStartVal, BaseLineEndVal,slope,intercept)
//	PrintF "Wave  %s  Slope = %+2.4f   PercentChange %+3.2f\r", WavStr, Slope, 100*Slope*(BaseLineEndVal-BaseLineStartVal+1)	// range is sum of intervals. shud be no +1. 
	PrintF "Wave  %s  Slope = %+2.4f   PercentChange %+3.2f\r", WavStr, Slope, 100*Slope*(BaseLineEndVal-BaseLineStartVal)
//	Print "Wave", WavStr, "Slope=", Slope, "%Change=", 100*Slope*(BaseLineEnd-BaseLineStart+1)
	wavindex+=1
	KillWaves /z w, $WavStr, $(WavStr+"_CBX")
While (1)
Return 1
End

Function display_data()
Display num_mini
Display RsVW
Display RinVW
Display CmVW
ModifyGraph /W=graph0 minor=1;DelayUpdate
Label /W=graph0 left "mini freq (Htz)";DelayUpdate
Label /W=graph0 bottom "time (in units of 40 secs)";DelayUpdate
ModifyGraph /W=graph1 minor=1;DelayUpdate
Label /W=graph1 left "Rs (Mohm)";DelayUpdate
Label /W=graph1 bottom "time (in units of 40 secs)";DelayUpdate
ModifyGraph /W=graph2 minor=1;DelayUpdate
Label /W=graph2 left "Rin (Mohm)";DelayUpdate
Label /W=graph2 bottom "time (in units of 40 secs)";DelayUpdate
ModifyGraph /W=graph3 minor=1;DelayUpdate
Label /W=graph3 left "Cm (pF)";DelayUpdate
Label /W=graph3 bottom "time (in units of 40 secs)"
NewLayout 
AppendLayoutObject  graph graph0
ModifyLayout /I left(graph0) =1.03, top(graph0) =2.4, width(graph0)=3.21,height(graph0)=3.73
AppendLayoutObject  graph graph1;DelayUpdate
ModifyLayout /I left(graph1) =4.26, top(graph1) =2.4, width(graph1)=3.21,height(graph1)=3.73
AppendLayoutObject  graph graph2;DelayUpdate
ModifyLayout /I left(graph2) =1.03, top(graph2) =6.28, width(graph2)=3.21,height(graph2)=3.73
AppendLayoutObject  graph graph3;DelayUpdate
ModifyLayout /I  left(graph3) =4.26, top(graph3) =6.28, width(graph3)=3.21,height(graph3)=3.73
SetDrawEnv fsize= 20
DrawText 95,105,"cellname"
SetDrawEnv fsize= 20
DrawText 400,105,"Date"
SetDrawEnv fsize= 20
DrawText 95,135,"Vm(start)="
SetDrawEnv fsize= 20
DrawText 250,135,"Vm(end)="
SetDrawEnv fsize= 20
DrawText 95,165,"other info="
return 1
end

Function display_data1()
Display num_mini
Display RsVW
Display RinVW
Display  CmVW
ModifyGraph /W=graph0 minor=1;DelayUpdate
Label /W=graph0 left "mini freq (Htz)";DelayUpdate
SetAxis /W=graph0 left 0,10
Label /W=graph0 bottom "time (in units of 40 secs)";DelayUpdate
ModifyGraph /W=graph1 minor=1;DelayUpdate
SetAxis /W=graph1 left 0,40
Label /W=graph1 left "Rs (Mohm)";DelayUpdate
Label /W=graph1 bottom "time (in units of 40 secs)";DelayUpdate
ModifyGraph /W=graph2 minor=1;DelayUpdate
SetAxis /W=graph2 left 0,500
Label /W=graph2 left "Rin (Mohm)";DelayUpdate
Label /W=graph2 bottom "time (in units of 40 secs)";DelayUpdate
ModifyGraph /W=graph3 minor=1;DelayUpdate
SetAxis /W=graph3 left 0,300
Label /W=graph3 left "Cm (pF)";DelayUpdate
Label /W=graph3 bottom "time (in units of 40 secs)"
NewLayout
AppendLayoutObject  graph graph0
ModifyLayout /I left(graph0) =1.03, top(graph0) =2.4, width(graph0)=3.21,height(graph0)=3.73
AppendLayoutObject  graph graph1;DelayUpdate
ModifyLayout /I left(graph1) =4.26, top(graph1) =2.4, width(graph1)=3.21,height(graph1)=3.73
AppendLayoutObject  graph graph2;DelayUpdate
ModifyLayout /I left(graph2) =1.03, top(graph2) =6.28, width(graph2)=3.21,height(graph2)=3.73
AppendLayoutObject  graph graph3;DelayUpdate
ModifyLayout /I  left(graph3) =4.26, top(graph3) =6.28, width(graph3)=3.21,height(graph3)=3.73
SetDrawEnv fsize= 20
DrawText 95,105,"cellname"
SetDrawEnv fsize= 20
DrawText 400,105,"Date"
SetDrawEnv fsize= 20
DrawText 95,135,"Vm(start)="
SetDrawEnv fsize= 20
DrawText 250,135,"Vm(end)="
SetDrawEnv fsize= 20
DrawText 95,165,"other info="
return 1
end




//given a wave new, this function average 2 bins at a time
//the resultant wave is <waveStr>_new
//the result will have n/2 points
//if you pass in a wave with odd n, there will be problems
Function cFirstFunction(waveStr)
String waveStr

Wave/D wavePtr = $waveStr
Make/O/D/N=(numpnts($waveStr)/2) $(waveStr+"_new")
Wave/D dstPtr = $(waveStr+"_new")

Variable  numItems = numpnts(dstPtr)
Variable srcIdx = 0
Variable dstIdx = 0
do
	dstPtr[dstIdx] = (wavePtr[srcIdx] + wavePtr[srcIdx+1]) / 2
	
	dstIdx += 1
	srcIdx += 2
while ( dstIdx < (numItems))

End  //function


Function pt_AnalyzeFolders(FoldersPathListString, DestAnalFolderString, NumMiniDo, ImVmDo, RsRinCmDelPntsDo, DisplayDataMiniDo)
String FoldersPathListString, DestAnalFolderString
Variable NumMiniDo, ImVmDo, RsRinCmDelPntsDo, DisplayDataMiniDo
String FolderName, CurrentDataFolder, CurrentDataFolderAbs, DuplicateAs
Variable i, NumFolders

NumFolders=ItemsInList(FoldersPathListString)
CurrentDataFolder = GetDataFolder(1)

	For (i=0;i<NumFolders; i+=1)
		FolderName=StringFromList(i, FoldersPathListString, ";")
		SetdataFolder FolderName
		CurrentDataFolderAbs = GetDataFolder(0)

		If (NumMiniDo)
			pt_AddSelected(10)
			DuplicateAs = DestAnalFolderString + ":"+ CurrentDataFolderAbs+"NumMini"
			Duplicate /O Num_Mini, $(DuplicateAs)
			Print "Analyzed folder:", GetDataFolder(1),"for NumMini & copied the Num_Mini wave to folder", FolderName
		EndIf
		
		If (ImVmDo)
//			pt_ImVm("Cell_000654_","AcqNeg90","D:users:taneja:data:ptCell654",0,0.025,15,95,3)
		EndIf
		
		If (RsRinCmDelPntsDo)
			pt_DeleteNansInBegin("RsVW;RinVW;CmVW")		
		EndIf
		
		If (DisplayDataMiniDo)
			pt_DisplayDataMini(CurrentDataFolderAbs)	
			PrintLayOut CurrentDataFolderAbs
		EndIf
		
	EndFor	

SetDataFolder CurrentDataFolder	
Return 1
End

Function pt_DeleteNansInBegin(WaveListString)
String WaveListString
Variable i, j, NumWaves, FirstInstance, FirstNormalNumber, WaveDim
String WaveNameString
NumWaves = ItemsInList(WaveListString) 

	For (i=0; i < NumWaves; i+=1)
		FirstInstance = 0
		j = 0 
		WaveNameString = StringFromList(i, WaveListString, ";")
		Wave w = $(WaveNameString)
			WaveDim = NumPnts(w)
			For (j=0;j < WaveDim; j+=1)
				
				If (NumType(w[j])==0 && FirstInstance==0)
					FirstNormalNumber = j
					FirstInstance = 1
				EndIf
					
			EndFor
			DeletePoints 0,FirstNormalNumber, w
	EndFor
End


function pt_averagewave()
variable wavindex
string wavlist,wavstr
wavlist = wavelist("*",";","WIN:")
print "averaging waves...",wavlist
wavstr= StringFromList (0,wavlist,";")
wave w = $wavStr 
duplicate /O w,avgwave
avgwave=0
wavindex=0
	do 
 		wavstr= StringFromList (wavindex,wavlist,";")
 		if (strlen(wavstr)== 0)
 		break
 		endif
 		wave w = $wavStr 
 		avgwave=avgwave+w
 		wavindex=wavindex+1
       while (1)
avgwave=avgwave/(wavindex)
appendtotable avgwave
// AppendToGraph /C=(0,0,0) avgwave
//ModifyGraph lsize(avgwave)=2
end 	

function pt_BarGraph(cntrlstartVal,cntrlendVal,drugstartVal,drugendVal,washstartVal,washendVal, WavName)
String WavName
variable cntrlstartVal,cntrlendVal,drugstartVal,drugendVal,washstartVal,washendVal
String WindowName

Wave w = $WavName
make /N=3/O  $(WavName+"_BG")
make /N=3/O  $(WavName+"_BGStdErr")
make /N=3/O/T  $(WavName+"_BGXAxis")

Wave	w1=$(WavName+"_BG")
Wave	w2=$(WavName+"_BGStdErr")
Wave /T w3=$(WavName+"_BGXAxis")
//wavestats /Q /R=[cntrlstart,cntrlend] avgwav	
wavestats /Q /R=(cntrlstartVal,cntrlendVal) w
w1[0]= V_avg
w2[0]=V_sdev/sqrt(V_npnts)
w3[0]="Control"
//wavestats /Q /R=[drugstart,drugend] avgwav
wavestats /Q /R=(drugstartVal,drugendVal) w
w1[1]= V_avg
w2[1]=V_sdev/sqrt(V_npnts)
w3[1]="APV"
//wavestats /Q /R=[washstart,washend] avgwav
wavestats /Q /R=(washstartVal,washendVal) w
w1[2]= V_avg
w2[2]=V_sdev/sqrt(V_npnts)
w3[2]="Wash"
// display  BarGraphWave vs BarGraphWave_xaxis as "histogramgraph"
WindowName = WavName+"BG"
display w1 vs w3
DoWindow /c $WindowName
ModifyGraph /w=$WindowName fSize(left)=18;DelayUpdate
ModifyGraph  hbFill=0,rgb=(0,0,0)
ErrorBars  /w=$WindowName w1 Y, Wave=(w2,w2)
ModifyGraph /w=$WindowName lsize=2
ModifyGraph /w=$WindowName fSize=18
end

// normalize function takes all the waves from the top window and normalizes each of them
// such that the average value of the wave between "startx-value" and  "endx-value" is equal to
// "normalize value".
function pt_normalize(startXVal,endXVal, OutWaveBaseName, normalizevalue)
// This is always the latest version

// If using wavstr as OutWaveBaseName, then don not attach wavindex num. 05/14/2007
String OutWaveBaseName
variable startXVal,endXVal,normalizevalue
variable wavindex
string wavlist,wavstr
String LastUpdatedMM_DD_YYYY="05/14/2007"

Print "*********************************************************"
Print "pt_normalize last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

wavlist = wavelist("*",";","WIN:")
print "normalizing waves...",wavlist
wavindex=0
do 
 	wavstr= StringFromList (wavindex,wavlist,";")
 	if (strlen(wavstr)== 0)
 	break
 	endif
 	wave w = $wavStr 
//	duplicate /O w,$(wavstr+"_norm")
//	wave w_norm = $(wavstr+"_norm")
	If (Strlen(OutWaveBaseName)==0)				// modified 03/22/2007
//	OutWaveBaseName=wavStr
	duplicate /O w,$(wavStr+"_N")			// modified 05/14/2007
	wave w_norm = $(wavStr+"_N")
	Else
	duplicate /O w,$(OutWaveBaseName+Num2Str(wavindex)+"_N")			// modified 03/22/2007
	wave w_norm = $(OutWaveBaseName+Num2Str(wavindex)+"_N")
	EndIf
// note: for waves with xscaling different from the point scaling, "wavestats" function shud be
// carefully. the range specified with round brackets is the range of x-value (scaled) while 
// the range specified with square brackets is the range of the point (ie. index) value. 
wavestats /Q /R=(startXVal,endXVal) w
w_norm=w*(normalizevalue/V_avg)
//appendtotable w_norm
//AppendToGraph w_norm
//RemoveFromGraph $wavstr
wavindex=wavindex+1
while (1)
end

function pt_normalize1(WavList, startXVal,endXVal,OutWaveBaseName, normalizevalue)
String WavList, OutWaveBaseName
variable startXVal,endXVal,normalizevalue
variable wavindex
string wavstr

//wavlist = wavelist("*",";","WIN:")
print "normalizing waves...",wavlist
wavindex=0
do 
 	wavstr= StringFromList (wavindex,wavlist,";")
 	if (strlen(wavstr)== 0)
 	break
 	endif
 	wave w = $wavStr 
//	duplicate /O w,$(wavstr+"_norm")
//	wave w_norm = $(wavstr+"_norm")
	If (Strlen(OutWaveBaseName)==0)					// modified 03/22/2007
		OutWaveBaseName=wavStr
	EndIf
	duplicate /O w,$(OutWaveBaseName+Num2Str(wavindex)+"_N")			// modified 03/22/2007
	wave w_norm = $(OutWaveBaseName+Num2Str(wavindex)+"_N")
// note: for waves with xscaling different from the point scaling, "wavestats" function shud be
// carefully. the range specified with round brackets is the range of x-value (scaled) while 
// the range specified with square brackets is the range of the point (ie. index) value. 
wavestats /Q /R=(startXVal,endXVal) w
w_norm=w*(normalizevalue/V_avg)
//appendtotable w_norm
//AppendToGraph w_norm
//RemoveFromGraph $wavstr
wavindex=wavindex+1
while (1)
end

//	pt_normalize2peakval finds the peak (max or min) between "startx-value" and  "endx-value" and multiplies the wave so that the peak val = NormalizePeakValue
function pt_normalize2peakval(StartXVal, EndXVal, OutWaveBaseName, PeakIsAMax, NormalizePeakValue)
String OutWaveBaseName
variable StartXVal, EndXVal, PeakIsAMax, NormalizePeakValue
variable wavindex
string wavlist,wavstr

wavlist = wavelist("*",";","WIN:")
print "scaling following waves so that their peaks are equal to normalize value...",wavlist
wavindex=0
do 
 	wavstr= StringFromList (wavindex,wavlist,";")
 	if (strlen(wavstr)== 0)
 	break
 	endif
 	wave w = $wavStr 
// 	duplicate /O w,$(wavstr+"norm")
//	wave w_norm = $(wavstr+"norm")
	
	If (Strlen(OutWaveBaseName)==0)						// modified 03/22/2007
		OutWaveBaseName=wavStr
	EndIf
	duplicate /O w,$(OutWaveBaseName+Num2Str(wavindex)+"_N2P")			// modified 03/22/2007
	wave w_norm = $(OutWaveBaseName+Num2Str(wavindex)+"_N2P")
	
	
// note: for waves with xscaling different from the point scaling, "wavestats" function shud be
// carefully. the range specified with round brackets is the range of x-value (scaled) while 
// the range specified with square brackets is the range of the point (ie. index) value. 
wavestats /Q  /R=(StartXVal, EndXVal) w
If (PeakIsAMax==1)
	w_norm=w*(NormalizePeakValue/V_max)
Else
	w_norm=w*(NormalizePeakValue/V_min)
EndIf	
//appendtotable w_norm
//AppendToGraph w_norm
//RemoveFromGraph $wavstr
wavindex=wavindex+1
while (1)
end


// baselineshift function takes all the waves from the top window and shifts their baselines
// such that the average value of the wave between "startx-value" and  "endx-value" is equal to "baseline value".
function pt_BaseLineShift(startXVal,endXVal,OutWaveBaseName, BaseLineValue)
String OutWaveBaseName
variable startXVal,endXVal,BaseLineValue
variable wavindex
string wavlist,wavstr

wavlist = wavelist("*",";","WIN:")
print "BaseLine Shifting waves...",wavlist
wavindex=0
do 
 	wavstr= StringFromList (wavindex,wavlist,";")
 	if (strlen(wavstr)== 0)
 	break
 	endif
 	wave w = $wavStr 
//	duplicate /O w,$(wavstr+"_BSShift")
//	wave w_BSShift = $(wavstr+"_BSShift")
	If (Strlen(OutWaveBaseName)==0)						// modified 03/22/2007
		OutWaveBaseName=wavStr
	EndIf
	duplicate /O w,$(OutWaveBaseName+Num2Str(wavindex)+"_BS")			// modified 03/22/2007
	wave w_BSShift = $(OutWaveBaseName+Num2Str(wavindex)+"_BS")
// note: for waves with xscaling different from the point scaling, "wavestats" function shud be
// carefully. the range specified with round brackets is the range of x-value (scaled) while 
// the range specified with square brackets is the range of the point (ie. index) value. 
wavestats /Q /R=(startXVal,endXVal) w
w_BSShift=w+(BaseLineValue-V_avg)
// appendtotable w_norm
AppendToGraph w_BSShift
RemoveFromGraph $wavstr
wavindex=wavindex+1
while (1)
end

function pt_randomselect(num)
variable num
variable i,wavindex
string wavlist,wavstr
wavlist = wavelist("*",";","WIN:")
print "randomly choosing",num,"pts from each of the following waves",wavlist
wavindex=0
	do 
 		wavstr= StringFromList (wavindex,wavlist,";")
 		if (strlen(wavstr)== 0)
 		break
 		endif
 		wave w = $wavStr 
		make /O/n=(num) $(wavstr+"_rnd")
		wave w_rnd = $(wavstr+"_rnd")
		util_randomselectA(w,w_rnd,num)
	//	AppendToGraph w_rnd
	//	RemoveFromGraph $wavstr
		wavindex=wavindex+1
	while (1)
end
// ******************
Function pt_RndSlctPntsFromW()
// modern version of util_randomSelectA(w,tgt, num) 11/05/11
Wave /T ParNamesW	=	$pt_GetParWave("pt_RndSlctPntsFromW", "ParNamesW")
Wave /T ParW			=	$pt_GetParWave("pt_RndSlctPntsFromW", "ParW")

String DataWaveMatchStr,  SubFldr
Variable NumPnts2Slct, NumPntsSlctd

String	WList, WNameStr
Variable NumWaves, i, Nw 

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_RndSlctPntsFromWParW and/or pt_RndSlctPntsFromWParNamesW!!!"
EndIf

DataWaveMatchStr	=		ParW[0]
NumPnts2Slct		= 		Str2Num(ParW[1])
SubFldr				= 		ParW[2]


PrintAnalPar("pt_RndSlctPntsFromW")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
NumWaves=	ItemsInList(WList,";")
print "Randomly selecting points from wave N=",NumWaves, WList

//Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+BaseNameString+"Avg")
//Wave w1= $(GetDataFolder(1)+SubFldr+BaseNameString+"Avg")


For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList,";")
	Wave w=$(GetDataFolder(1)+SubFldr+WNameStr)
	Nw = NumPnts(w)
	If (NumPnts2Slct <= Nw)
	NumPntsSlctd = NumPnts2Slct
	Else
	NumPntsSlctd = Nw
	Print "************************************"
	Print "Num of points in wave", WNameStr,"=", Nw,"is less than", NumPnts2Slct,". Pnts selected =", Nw
	Print "************************************"
	EndIf
	Make /O/N=(NumPntsSlctd) $(GetDataFolder(1)+SubFldr+"Rnd_"+WNameStr)
	Make /O/N=(Nw) $(GetDataFolder(1)+SubFldr+WNameStr+"_TmpW"), $(GetDataFolder(1)+SubFldr+WNameStr+"_Tmpi")
	Wave WRnd= $(GetDataFolder(1)+SubFldr+"Rnd_"+WNameStr)
	Wave TmpW= $(GetDataFolder(1)+SubFldr+WNameStr+"_TmpW")
	Wave Tmpi= $(GetDataFolder(1)+SubFldr+WNameStr+"_Tmpi")
	WRnd = Nan; TmpW= Nan; Tmpi = Nan
	TmpW= enoise(1)
	Tmpi = p
	Sort TmpW, Tmpi
	WRnd = w[Tmpi[p]]
	KillWaves /Z TmpW, Tmpi
EndFor	
	
End
// ******************


// ******************
Function pt_RndSlctWFromW()
// modified from pt_RndSlctPntsFromW() 04/22/12

// Instead of selecting pnts randomly from a wave select a subset of weves from all the matching waves

// modern version of util_randomSelectA(w,tgt, num) 11/05/11
Wave /T ParNamesW	=	$pt_GetParWave("pt_RndSlctWFromW", "ParNamesW")
Wave /T ParW			=	$pt_GetParWave("pt_RndSlctWFromW", "ParW")

String DataWaveMatchStr,  SubFldr
Variable NumW2Slct, NumWSlctd//, RenameW

String	WList, WNameStr
Variable NumWaves, i, Nw 

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_RndSlctWFromWParW and/or pt_RndSlctWFromWParNamesW!!!"
EndIf

DataWaveMatchStr	=		ParW[0]
NumW2Slct			= 		Str2Num(ParW[1])
SubFldr				= 		ParW[2]
//RenameW			=		Str2Num(ParW[3])	// to save space


PrintAnalPar("pt_RndSlctWFromW")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
NumWaves=	ItemsInList(WList,";")

print "Randomly selecting waves from all wave N=",NumWaves

If (NumW2Slct <= NumWaves)
	NumWSlctd = NumW2Slct
	Else
	NumWSlctd = NumWaves
	Print "************************************"
	Print "Num of all waves =", NumWaves,"is less than", NumW2Slct,". Pnts selected =", NumWSlctd
	Print "************************************"
EndIf

Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+"TmpW"), $(GetDataFolder(1)+SubFldr+"Tmpi")
Wave TmpW= $(GetDataFolder(1)+SubFldr+"TmpW")
Wave Tmpi= $(GetDataFolder(1)+SubFldr+"Tmpi")
TmpW= Nan; Tmpi = Nan
	TmpW= enoise(1)
	Tmpi = p
	Sort TmpW, Tmpi
//	WRnd = w[Tmpi[p]]
//	KillWaves /Z TmpW, Tmpi


//Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+BaseNameString+"Avg")
//Wave w1= $(GetDataFolder(1)+SubFldr+BaseNameString+"Avg")


For (i=0; i<NumWSlctd; i+=1)
	WNameStr=StringFromList(Tmpi[i], WList,";")
	
	Wave w=$(GetDataFolder(1)+SubFldr+WNameStr)
//	If (RenameW)
//	Else
//	EndIf
	Duplicate /O w, $(GetDataFolder(1)+SubFldr+"Rnd_"+WNameStr)
EndFor	
KillWaves /Z TmpW, Tmpi
End
// ******************

function util_randomSelectA(w,tgt, num)
	wave w,tgt
	variable num
	make /o/n=(numpnts(w)) tmpw, tmpi
	tmpw = enoise(1)		// random
	tmpi = p				// wave = p assignment assigns the successive elements, the successive index no. (see manual)
//	print tmpi[0],tmpi[1],tmpi[2],tmpi[3],tmpi[4]
	sort tmpw, tmpi     // sorts the indexes in tmpi ascending order according to the value in tmpw
//	print tmpw[0],tmpw[1],tmpw[2],tmpw[3],tmpw[4]
//	print tmpi[0],tmpi[1],tmpi[2],tmpi[3],tmpi[4]
	redimension /n=(num) tgt
	tgt = w[tmpi[p]]     // destwav=srcwav[p] (p in igor waves is the index no) successive values of srcwav to successive values of destwav
//	print tgt[0],tgt[1],tgt[2]
//	appendtotable tmpw, tmpi
	Killwaves tmpi, tmpw
end

//return randomly selected indexes of w in tgt
function util_randomSelectB(w,tgt, num)
	wave w,tgt
	variable num
	make /o/n=(numpnts(w)) tmpw, tmpi
	tmpw = enoise(1)		// random
	tmpi = p				// index
	sort tmpw, tmpi
	
	redimension /n=(num) tgt
	//tgt = w[tmpi[p]]
	tgt = tmpi[p]
	killwaves /z tmpw, tmpi
end

// this procedure selects those values of peakampVW for which selectionVW=1 and makes 3 waves named
// peakampcontrol, peakampdrug, peakampwash. the number of waves of each is passed to subroutine in 
// the arguement.																praveen 04/13/03
function pt_sortselected(numcontrol,numdrug,numwash)
variable numcontrol,numdrug,numwash
variable i,ilast,j,k,totalwaveno,dimpeakampVW,changecondition,kcontrol,kdrug
wave numberVW,selectionVW,peakampVW
totalwaveno=num_waves1(numberVW)
dimpeakampVW=num_waves1(peakampVW)
make /o/n=(dimpeakampVW) peakampcontrol,peakampdrug,peakampwash 
ilast=0
k=0
changecondition=0
	for (j=0;j<totalwaveno;j+=1)
		if (numtype(numberVW[ilast])!=0)
		print "Error: Not a normal number on line",ilast,"!!!!. please check."
		return -1
		endif
			for (i=ilast;(i-ilast)<numberVW[ilast];i+=1)
				if (selectionvw[i]==1)
					if (j<=(numcontrol-1))
					peakampcontrol[k]=peakampvw[i]
					k=k+1
					endif
					if (j>(numcontrol-1) && j<=(numcontrol+numdrug-1))
					if (changecondition==0)
					kcontrol=k
					changecondition=1
					endif
					peakampdrug[k]=peakampvw[i]
					k=k+1
					endif
					if (j>(numcontrol+numdrug-1))
					if (changecondition==1)
					kdrug=k
					changecondition=0
					endif
					peakampwash[k]=peakampvw[i]
					k=k+1
					endif
				endif
			endfor
		ilast=i
	endfor
//	appendtotable peakampcontrol,peakampdrug,peakampwash
	deletepoints kcontrol,(dimpeakampvw-kcontrol), peakampcontrol
	deletepoints kdrug,(dimpeakampvw-kdrug), peakampdrug
	deletepoints 0,kcontrol, peakampdrug
	deletepoints k,(dimpeakampvw-k),peakampwash
	deletepoints 0,kdrug, peakampwash
	print "total number of waves =", totalwaveno
	print "number of control, drug, wash waves=",  numcontrol,numdrug,numwash
	print "done..."
return 1
end

function pt_sortselectedminirise(controlendindex,drugendindex,washendindex)
variable controlendindex,drugendindex,washendindex
variable i,ilast,j,k,totalwaveno,dimriseVW,changecondition,kcontrol,kdrug
wave numberVW,selectionVW,riseVW
totalwaveno=num_waves3(numberVW)
dimriseVW=num_waves3(riseVW)
make /o/n=(dimriseVW) risecontrol,risedrug,risewash 
   
ilast=0
k=0
changecondition=0
	for (j=0;j<totalwaveno;j+=1)
		if (numtype(numberVW[ilast])!=0)
		print "Error: Not a normal number on line",ilast,"!!!!. please check."
		return -1
		endif
			for (i=ilast;(i-ilast)<numberVW[ilast];i+=1)
				if (selectionvw[i]==1)
					if (j<=controlendindex)
					risecontrol[k]=risevw[i]
					k=k+1
					endif
					if (j>controlendindex && j<=drugendindex)
					if (changecondition==0)
					kcontrol=k
					changecondition=1
					endif
					risedrug[k]=risevw[i]
					k=k+1
					endif
					if (j>drugendindex)
					if (changecondition==1)
					kdrug=k
					changecondition=0
					endif
					risewash[k]=risevw[i]
					k=k+1
					endif
				endif
			endfor
		ilast=i
	endfor
// converting to frequency
//	appendtotable risecontrol,risedrug,risewash
	deletepoints kcontrol,(dimrisevw-(kcontrol)), risecontrol
	deletepoints 0,kcontrol, risedrug
	deletepoints (kdrug-kcontrol),(dimrisevw-(kdrug)), risedrug
	deletepoints 0,kdrug, risewash
	deletepoints  (k-kdrug),(dimrisevw-(k)),risewash
	print "Done...Total no of waves =",totalwaveno
return 1
end
function num_waves3(numberVW)
wave numberVW
wavestats /Q numberVW
return V_npnts
end

function pt_sortselectedminidecay(controlendindex,drugendindex,washendindex)
variable controlendindex,drugendindex,washendindex
variable i,ilast,j,k,totalwaveno,dimdecayVW,changecondition,kcontrol,kdrug
wave numberVW,selectionVW,decayVW
totalwaveno=num_waves2(numberVW)
dimdecayVW=num_waves2(decayVW)
make /o/n=(dimdecayVW) decaycontrol,decaydrug,decaywash 
   
ilast=0
k=0
changecondition=0
	for (j=0;j<totalwaveno;j+=1)
		if (numtype(numberVW[ilast])!=0)
		print "Error: Not a normal number on line",ilast,"!!!!. please check."
		return -1
		endif
			for (i=ilast;(i-ilast)<numberVW[ilast];i+=1)
				if (selectionvw[i]==1)
					if (j<=controlendindex)
					decaycontrol[k]=decayvw[i]
					k=k+1
					endif
					if (j>controlendindex && j<=drugendindex)
					if (changecondition==0)
					kcontrol=k
					changecondition=1
					endif
					decaydrug[k]=decayvw[i]
					k=k+1
					endif
					if (j>drugendindex)
					if (changecondition==1)
					kdrug=k
					changecondition=0
					endif
					decaywash[k]=decayvw[i]
					k=k+1
					endif
				endif
			endfor
		ilast=i
	endfor
// converting to frequency
//	appendtotable decaycontrol,decaydrug,decaywash
	deletepoints kcontrol,(dimdecayvw-(kcontrol)), decaycontrol
	deletepoints 0,kcontrol, decaydrug
	deletepoints (kdrug-kcontrol),(dimdecayvw-(kdrug)), decaydrug
	deletepoints 0,kdrug, decaywash
	deletepoints  (k-kdrug),(dimdecayvw-(k)),decaywash
	print "Done...Total no of waves =",totalwaveno
return 1
end
function num_waves2(numberVW)
wave numberVW
wavestats /Q numberVW
return V_npnts
end


function pt_ExtractSelected()

// This is always the latest version

String InWaveBaseName, OutWaveBaseName, RangeW	
variable NumControlStart,NumControlEnd,NumDrugStart,NumDrugEnd,NumWashStart,NumWashEnd

variable i,ilast,j,k,totalwaveno,dimTgtVW,changecondition,kcontrol,kdrug
// renamed to pt_ExtractSelected() as it's more appropriate and made parameters global. also automated so that it can run 
// thru multiple folders. 10th Oct. 2007
// using it after a long time and slightly modifying it. (praveen.) 9th Oct. 2007 
// added InWaveBaseName so that it can be used for any wave.


//function pt_SortSelected1(NumControlStart,NumControlEnd,NumDrugStart,NumDrugEnd,NumWashStart,NumWashEnd)
//variable NumControlStart,NumControlEnd,NumDrugStart,NumDrugEnd,NumWashStart,NumWashEnd
// pt_SortSelected1("Decay",5,16,35,46, 53, 64)		(wave nums start from 1; corrected inside the prog. to start from 0)


// modified pt_SortSelected so that data can be selected starting from any wave and ending at any wave in control, drug, wash 02/19/2004 (praveen taneja)
// Example: pt_SortSelected1(1,2,4,6,7,8)

String LastUpdatedMM_DD_YYYY="10_10_2007"

Print "*********************************************************"
Print "pt_ExtractSelected last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_ExtractSelected"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_ExtractSelected"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_ExtractSelected!!!"
EndIf

PrintAnalPar("pt_ExtractSelected")

InWaveBaseName 	= AnalParW[0]
OutWaveBaseName	= AnalParW[1]
RangeW				= AnalParW[2]


Wave /T AnalParNamesW		=	$pt_GetParWave(RangeW, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(RangeW, "ParW")


NumControlStart	=	Str2Num(AnalParW[0])
NumControlEnd	=	Str2Num(AnalParW[1])
NumDrugStart	=	Str2Num(AnalParW[2])
NumDrugEnd		=	Str2Num(AnalParW[3])
NumWashStart	=	Str2Num(AnalParW[4])
NumWashEnd	=	Str2Num(AnalParW[5])


wave numberVW,selectionVW//,peakampVW
Wave TgtVW = $(InWaveBaseName + "VW")

totalwaveno=num_waves1(numberVW)
dimTgtVW=num_waves1(TgtVW)

make /o/n=(dimTgtVW) $(OutWaveBaseName+"Control"),$(OutWaveBaseName+"Drug"),$(OutWaveBaseName+"Wash") 

Wave TgtControl 	= $(OutWaveBaseName+"Control")
Wave TgtDrug 	= $(OutWaveBaseName+"Drug")
Wave TgtWash 	= $(OutWaveBaseName+"Wash")

ilast=0
k=0
changecondition=0

NumControlStart	-=1		// actual waves start from 0, not 1
NumControlEnd	-=1		
NumDrugStart	-=1
NumDrugEnd		-=1
NumWashStart	-=1
NumWashEnd	-=1




	for (j=0;j<totalwaveno;j+=1)
		if (numtype(numberVW[ilast])!=0)
		print "Error: Not a normal number on line",ilast,"!!!!. please check."
		KillWaves TgtControl, TgtDrug, TgtWash
		Edit numberVW,selectionVW, Tgtvw
		return -1
		endif
			for (i=ilast;(i-ilast)<numberVW[ilast];i+=1)
				if (selectionvw[i]==1)
					if ( (j>=NumControlStart) && (j<=NumControlEnd ) )
					Tgtcontrol[k]=Tgtvw[i]
					k=k+1
					endif
					if (  (j>=NumDrugStart) && (j<=NumDrugEnd)  )
					if (changecondition==0)
					kcontrol=k
					changecondition=1
					endif
					Tgtdrug[k]=Tgtvw[i]
					k=k+1
					endif
					if (  (j>=NumWashStart) && (j<=NumWashEnd)  )
					if (changecondition==1)
					kdrug=k
					changecondition=0
					endif
					Tgtwash[k]=Tgtvw[i]
					k=k+1
					endif
				endif
			endfor
		ilast=i
	endfor

//	appendtotable peakampcontrol,peakampdrug,peakampwash
//	edit	numberVW, selectionVW
//	appendtotable Tgtcontrol,Tgtdrug,Tgtwash
	deletepoints kcontrol,(dimTgtvw-kcontrol), Tgtcontrol
	deletepoints kdrug,(dimTgtvw-kdrug), Tgtdrug
	deletepoints 0,kcontrol, Tgtdrug
	deletepoints k,(dimTgtvw-k),Tgtwash
	deletepoints 0,kdrug, Tgtwash
	Printf "\r"
	print "total number of waves =", totalwaveno, "in folder", GetDataFolder(0)
	print "number of control, drug, wash waves=",  NumControlEnd-NumControlStart+1,NumDrugEnd-NumDrugStart+1,NumWashEnd-NumWashStart+1
//	print "done..."

return 1
end

Function pt_SplitEpochs()
// This function will generate par waves for pt_RepeatNums from pt_MiniEpoch (that has start and end pnt of diff. epochs)
// first generate pt_RepeatNumsBL, pt_RepeatNumsDrug, pt_RepeatNumsWash with correct PntsPerRep, NumReps
// then get correct start pnt from pt_MiniEpoch wave

// This is always the latest version

String OrigWName, OrigWStartPnt, OutWBaseName, OutWSuffix

String LastUpdatedMM_DD_YYYY="11_13_2007"
Print "*********************************************************"
Print "pt_SplitEpochs last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SplitEpochs", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_SplitEpochs", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_SplitEpochs!!!"
EndIf

PrintAnalPar("pt_SplitEpochs")

OrigWName			= AnalParW[0]
OrigWStartPnt		= AnalParW[1]
OutWBaseName		= AnalParW[2]
OutWSuffix			= AnalParW[3]

Wave  /T w = $(AnalParW[0])

Wave /T ParW 		= $(OutWBaseName+ OutWSuffix)

ParW[1] = w[Str2Num(OrigWStartPnt)]

Print "StartPnt", ParW[1]

End




Function pt_SplitWEpochs()

// based on pt_AllignWaves and pt_SplitEpochs

// pt_AllignWaves worked on extracted parameters like amplitude, decay time etc. 
// pt_SplitWEpochs() will categorize mini waves into different epochs. For parameter waves the algorithm
// was to use the startpnt of BL and set x-scale so that 0th point was the start point using pt_AllignWaves. 
// that way all cells will start at 0 BL value. Then choose epochs for BLStart, BLEnd, DrugStart, DrugEnd etc. 
// and average parameters in these epochs to get average BL, Drug values
// Following similar approach, we'll use the start point of BL and call that wave as BL 0 Wave. Then use epoch parameters
// BLStart, BLEnd etc, to find average mini during BL, Drug, Wash. 

// This is always the latest version


// Acquired	wave# 1, 2, 3, 4, 5
// Mini Wave# 0, 1, 2, 3, 4
// pt_MiniEpoch refers to acquired waves starting at 1
//  So to allign Mini Wave# subtract 1
// EpochWName refer to waves with 1st BL point =0 

// Example BL waves acuisition starts at 3 (so leave 1st 2 waves)
// Averaging starts from 5 to 16 (counting from 0). so leave 5 waves from BL start
// In all leave 1st 7 waves. therefore start from 7th wave (counting from 0)

String DataWaveMatchStr, ScanformatStr, EpochPrefix, AllignWName, EpochWName
Variable PntNum, EpochStartPntNum, EpochEndPntNum

String WList, WNameStr, NumStr
Variable AllignWNum, StartWNum, EndWNum, N, i, X0

String LastUpdatedMM_DD_YYYY="01_19_2009"

Print "*********************************************************"
Print "pt_SplitWEpochs last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SplitWEpochs", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_SplitWEpochs", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_SplitWEpochs!!!"
EndIf

PrintAnalPar("pt_SplitWEpochs")

DataWaveMatchStr	= AnalParW[0]
ScanformatStr		= AnalParW[1]

AllignWName		= AnalParW[2]
PntNum		   		= Str2Num(AnalParW[3])

AllignWNum			= (pt_GetOnePnt(AllignWName, PntNum) -1)	// PntNum starts from 1; AllignWNum from 0

EpochWName		= AnalParW[4]
EpochStartPntNum	= Str2Num(AnalParW[5])
EpochEndPntNum	= Str2Num(AnalParW[6])
EpochPrefix			= AnalParW[7]

Wave /T AnalParNamesW		=	$pt_GetParWave(EpochWName, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(EpochWName, "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave EpochWName!!!"
EndIf


StartWNum	= pt_GetOnePnt(EpochWName+"ParW", EpochStartPntNum)
EndWNum	= pt_GetOnePnt(EpochWName+"ParW", EpochEndPntNum)

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
N= ItemsInList(WList, ";")

Make /O/N=0  SelectedWaves
Make /O/N=1  SelectedWavesTmp = Nan

For (i=0; i<N; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$WNameStr
		SScanf WNameStr, ScanformatStr, NumStr
		X0 = Str2Num(NumStr)
		X0 -=AllignWNum
		If ( (X0 >=StartWNum) && (X0 <=EndWNum) )
			Duplicate /O w, $(EpochPrefix+WNameStr)
			If (NumPNts(SelectedWaves) ==0)
			SelectedWavesTmp[0] = X0+AllignWNum
			Concatenate /NP {SelectedWavesTmp},  SelectedWaves
			ElseIf (SelectedWavesTmp[0] != (X0+AllignWNum) )
			SelectedWavesTmp[0] = X0+AllignWNum
			Concatenate /NP {SelectedWavesTmp},  SelectedWaves
			EndIf
		EndIf
EndFor

Print "Selected Waves", SelectedWaves

End

function num_waves1(numberVW)
wave numberVW
wavestats /Q numberVW
return V_npnts
end

Function pt_NthPntWave()

// This is always the latest version.

// modified for SubDataFldr (04/21/12)

// modified to specify WList in parameter wave. This will cause a NAN value for non-existing waves. could be useful in the following instance:
// say you generated SpikeThreshold waves as function of spike number for different current injections. for lower current injections no spikes
// were there and no wave was created. now if we want to extract threshold of 1st spike at different current injections for different cells the spike
// threshold vs current wave will correspond to different currents. however, if for currents that didn't generate a any spike a NAN is assigned, then
// value at same index will correspond to same current for all cells 06_14_2008

String LastUpdatedMM_DD_YYYY="04_21_12"

Print "*********************************************************"
Print "pt_NthPntWave last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

String DataWaveMatchStr, DestWName, WList, SubDataFldr
Variable PntNum

String	WNameStr
Variable	Numwaves, i


Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_NthPntWave"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_NthPntWave"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_NthPntWave!!!"
EndIf

PrintAnalPar("pt_NthPntWave")

DataWaveMatchStr		=	AnalParW[0]
PntNum					=	Str2Num(AnalParW[1])
DestWName				=	AnalParW[2]
WList					= 	AnalParW[3]	//modified to specify WList in parameter wave. This will cause a NAN value for non-existing waves. 
SubDataFldr			=	AnalParW[4]

If (StringMatch(WList, "") )	//modified to specify WList in parameter wave.
WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+ SubDataFldr)
EndIf
Numwaves=ItemsInList(WList, ";")

Print "Nth pnt. from waves, N =", Numwaves, WList

Make /O/N=(Numwaves) $(GetDataFolder(1)+ SubDataFldr+DestWName)
Wave w1 = $(GetDataFolder(1)+ SubDataFldr+DestWName)
w1 = Nan

For (i=0; i<Numwaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	If ( 	WaveExists($(GetDataFolder(1)+ SubDataFldr+WNameStr) )	)
	Wave w=$(GetDataFolder(1)+ SubDataFldr+WNameStr)
	If (NumPnts(w)>=(PntNum+1))
	w1[i]=w[PntNum]
	EndIf
	Else
	w1[i]=Nan			//modified to specify WList in parameter wave.
	EndIf
	
EndFor


End

Function pt_NthPntWaveVarPar1()
// function to run pt_NthPntWave with some parameters varied
String OldDataWaveMatchStr, OldPntNum, OldDestWName

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_NthPntWave"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_NthPntWave"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_NthPntWave!!!"
EndIf

OldDataWaveMatchStr		=	AnalParW[0]
OldPntNum					=	AnalParW[1]
OldDestWName				=	AnalParW[2]
//WList						= 	AnalParW[3]	//modified to specify WList in parameter wave. This will cause a NAN value for non-existing waves. 

AnalParW[0] = "CofCell_00*_0012"
AnalParW[1] = "0"
AnalParW[2] = "NullF_I300pA27HzBL0ExpY0Avg"
pt_NthPntWave()

AnalParW[0] = "CofCell_00*_0012"
AnalParW[1] = "1"
AnalParW[2] = "NullF_I300pA27HzBL0ExpAAvg"
pt_NthPntWave()

AnalParW[0] = "CofCell_00*_0012"
AnalParW[1] = "2"
AnalParW[2] = "NullF_I300pA27HzBL0ExpDAvg"
pt_NthPntWave()


AnalParW[0] = "SigCell_00*_0012"
AnalParW[1] = "0"
AnalParW[2] = "NullF_I300pA27HzBL0ExpY0SD"
pt_NthPntWave()

AnalParW[0] = "SigCell_00*_0012"
AnalParW[1] = "1"
AnalParW[2] = "NullF_I300pA27HzBL0ExpASD"
pt_NthPntWave()

AnalParW[0] = "SigCell_00*_0012"
AnalParW[1] = "2"
AnalParW[2] = "NullF_I300pA27HzBL0ExpDSD"
pt_NthPntWave()




AnalParW[0] = "CofCell_00*_0022"
AnalParW[1] = "0"
AnalParW[2] = "NullF_I300pA27HzBL1ExpY0Avg"
pt_NthPntWave()

AnalParW[0] = "CofCell_00*_0022"
AnalParW[1] = "1"
AnalParW[2] = "NullF_I300pA27HzBL1ExpAAvg"
pt_NthPntWave()

AnalParW[0] = "CofCell_00*_0022"
AnalParW[1] = "2"
AnalParW[2] = "NullF_I300pA27HzBL1ExpDAvg"
pt_NthPntWave()


AnalParW[0] = "SigCell_00*_0022"
AnalParW[1] = "0"
AnalParW[2] = "NullF_I300pA27HzBL1ExpY0SD"
pt_NthPntWave()

AnalParW[0] = "SigCell_00*_0022"
AnalParW[1] = "1"
AnalParW[2] = "NullF_I300pA27HzBL1ExpASD"
pt_NthPntWave()

AnalParW[0] = "SigCell_00*_0022"
AnalParW[1] = "2"
AnalParW[2] = "NullF_I300pA27HzBL1ExpDSD"
pt_NthPntWave()



AnalParW[0]	= OldDataWaveMatchStr
AnalParW[1] = OldPntNum
AnalParW[2] = OldDestWName
End


Function pt_TransposeWavelist(DataWaveMatchStr, OutWaveBaseName, WaveStartNum)
// This is always the latest version.

// brushed up the code. 03_22_2007
// instead of the 1st wave it now uses the longest wave to decide how many waves to make. so the waves can have unequal lengths. 03_22_2007
// also shorter waves will have NANs inserted in the transpose. Else Igor returns last wave value if you read past the wave length. 03_22_2007

// example: pt_TransposeWavelist("Cell_00*FIPeakRelY510pA_Avg","FIPeakRelY",0)
//Older example: pt_TransposeWavelist("Cell_000420_EPSP_AnalXWave",13)


string DataWaveMatchStr, OutWaveBaseName
Variable WaveStartNum

string WaveListString,Wavstr
Variable i,j,NumWaves,WaveDim, LongestWIndex
String LastUpdatedMM_DD_YYYY="03_22_2007"

Print "*********************************************************"
Print "pt_TransposeWavelist last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

	WaveListString=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
//	WaveListString = wavelist(CellBaseName+"*",";","")
	NumWaves=ItemsInList(WaveListString)
//	wavstr= StringFromList (0,WaveListString,";")	
//	Wave w = $Wavstr
//	WaveDim=Numpnts(w)	// figure out dimension of waves (all waves have the same dimension though some values can be Nan)
	pt_MaxWDim(WaveListString, WaveDim, LongestWIndex)
							// if not all waves have the same dimension find the maximum dimension by going thru the list of waves first (praveen taneja)
	Print "Num of waves = ",NumWaves
	Print "Num of transposed waves = ",WaveDim
	
	For (i=0;i<WaveDim;i+=1)
	
		Make /O/N=(NumWaves) $(OutWaveBaseName+num2istr(i+WaveStartNum)+"_T")
		Wave w1=$(OutWaveBaseName+num2istr(i+WaveStartNum)+"_T") 
		
//		For (j=0;j<=NumWaves;j+=1)
		For (j=0;j<NumWaves;j+=1)
		
			wavstr= StringFromList (j,WaveListString,";")
  			if (strlen(wavstr)== 0)
  			Print "While finding transpose could not find wave #", j
  			DoAlert 0, "Exiting without finishing!!"
 			break
 			endif
 			wave w = $wavStr
			
			w1[j] = ( i >(NumPnts(w)-1)   ) ? NAN : w[i]
		endfor
		
	endfor			
	
return 1
End

Function pt_LoadWaves(CellBaseName,WavesFolder, FolderToLoadIn, WaveStartNum,WaveEndNum, CheckPreExistence, NDig)
// Usage Eg. pt_LoadWaves("Cell_000856_","D:users:taneja:data1:PresynapticNmda:NmdaEvoked:04_20_2004 Folder","root:Cell_000857ToCell_000856" , 6,10)
String 	CellBasename,WavesFolder, FolderToLoadIn
Variable WaveStartNum, WaveEndNum, CheckPreExistence, NDig
Variable i
String OldDataFolder, wName, FileName
OldDataFolder = GetDataFolder(1)
SetDataFolder FolderToLoadIn+":"
	For (i=WaveStartNum;i<=WaveEndNum;i=i+1)
//		FileName=WavesFolder+":"+CellBaseName+num2digstrCopy(NDig,i)
		wName= CellBaseName+num2digstrCopy(NDig,i)
		if (waveexists($wName)*CheckPreExistence==0)
			FileName=WavesFolder+":"+CellBaseName+num2digstrCopy(NDig,i)
			LoadWave /W/A FileName
		endif
	EndFor		
SetDataFolder $OldDataFolder	
End 

Function pt_LoadData1(MatchStr, HDFolderPath, IgorFolderPath)	// see pt_LoadDataRecursive for recursive loading of data
String MatchStr, HDFolderPath, IgorFolderPath
// To load waves having a "StringExpression" from a folder on disk. Load all files in a TempLoadData Folder and then select from there.
// Example Usage: pt_LoadData("*EPSP*", "D:users:taneja:data1:PresynapticNmda:NmdaEvoked:07_19_2004 Folder:Cell1326To1325Anal08_11_2004 Folder",  "root:EPSP")
String OldDf, ListStr, WaveStr
Variable i, NumWaves

OldDf = GetDataFolder(1)
NewDataFolder /O  $(IgorFolderPath)		// No : at end)
NewDataFolder /O/S  $(IgorFolderPath+"Temp")
LoadData /Q/O/D/L=1 HDFolderPath
ListStr= WaveList(MatchStr, ";", "")
NumWaves = ItemsinList(ListStr)

	For (i=0; i< NumWaves; i+=1)
		WaveStr = StringFromList(i, ListStr, ";")
		Duplicate /o $WaveStr, $(IgorFolderPath + ":" +WaveStr)
	EndFor
	KillDataFolder $(IgorFolderPath+"Temp")
Return 1	
End

Function pt_LoadData(MatchStr, HDFolderPath, IgorFolderPath)	// see pt_LoadDataRecursive for recursive loading of data

// This is always the latest version

// Previous version was pt_LoadData1 where all files were loaded first and then only matching files were kept. with "IndexedFile" you can get
// names all files in a folder and then load only the ones needed.  6th August, 2007

String MatchStr, HDFolderPath, IgorFolderPath
// To load waves having a "StringExpression" from a folder on disk. Load all files in a TempLoadData Folder and then select from there.
// Example Usage: pt_LoadData("*EPSP*", "D:users:taneja:data1:PresynapticNmda:NmdaEvoked:07_19_2004 Folder:Cell1326To1325Anal08_11_2004 Folder",  "root:EPSP")
String OldDf, ListStr, WaveStr, AllListStr
Variable i, NumWaves
String LastUpdatedMM_DD_YYYY="08/06/2007"

Print "*********************************************************"
Print "pt_LoadData last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

OldDf = GetDataFolder(1)
NewDataFolder /O/S  $(IgorFolderPath)		// No : at end)

NewPath /O/Q/C SymblkHDFolderPath, HDFolderPath
AllListStr= IndexedFile(SymblkHDFolderPath, -1, ".ibw")
ListStr = ListMatch(AllListStr, MatchStr)
NumWaves = ItemsinList(ListStr)

	For (i=0; i< NumWaves; i+=1)
		WaveStr = StringFromList(i, ListStr, ";")
		LoadWave /O/Q/P=SymblkHDFolderPath WaveStr
	EndFor
Print "Pt_LoadData: Loaded waves, N= ", NumWaves	
SetDataFolder OldDf	
KillPath SymblkHDFolderPath
Return 1	
End

Function pt_LoadData2(MatchStr, HDFolderPath, IgorFolderPath)	// see pt_LoadDataRecursive for recursive loading of data

// Modified from pt_LoadData(MatchStr, HDFolderPath, IgorFolderPath) 08/25/12. To allow for the common part of the HDFolderPath to be supplied (also modified pt_LoadDataRecursive as  pt_LoadDataRecursive2)
//specified separately. That way just by changing the common part the folder can be specifed on different computers.
// Eg. Right now HDFolderPath=Macintosh HD:Users:taneja:OldMastishk:j:users:JUsersTaneja:rutlin:RorBetaGFP:mIPSC:07_14_12 Folder
// We can change this to HDFolderPath= 07_14_12 Folder and a 
// HDFolderParentDir=Macintosh HD:Users:taneja:OldMastishk:j:users:JUsersTaneja:rutlin:RorBetaGFP:mIPSC:
// Then total path = HDFolderParentDir+HDFolderPath

// Previous version was pt_LoadData1 where all files were loaded first and then only matching files were kept. with "IndexedFile" you can get
// names all files in a folder and then load only the ones needed.  6th August, 2007

String MatchStr, HDFolderPath, IgorFolderPath
// To load waves having a "StringExpression" from a folder on disk. Load all files in a TempLoadData Folder and then select from there.
// Example Usage: pt_LoadData("*EPSP*", "D:users:taneja:data1:PresynapticNmda:NmdaEvoked:07_19_2004 Folder:Cell1326To1325Anal08_11_2004 Folder",  "root:EPSP")
String OldDf, ListStr, WaveStr, AllListStr, FullHDFolderPath
Variable i, NumWaves
String LastUpdatedMM_DD_YYYY="08/25/2012"
SVAR ParentHDDataFolder=$"root:ParentHDDataFolder"

Print "*********************************************************"
Print "pt_LoadData2 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

OldDf = GetDataFolder(1)
NewDataFolder /O/S  $(IgorFolderPath)		// No : at end)

FullHDFolderPath=ParentHDDataFolder+HDFolderPath
NewPath /O/Q/C SymblkHDFolderPath, FullHDFolderPath
AllListStr= IndexedFile(SymblkHDFolderPath, -1, ".ibw")
ListStr = ListMatch(AllListStr, MatchStr)
NumWaves = ItemsinList(ListStr)

	For (i=0; i< NumWaves; i+=1)
		WaveStr = StringFromList(i, ListStr, ";")
		LoadWave /O/Q/P=SymblkHDFolderPath WaveStr
	EndFor
Print "Pt_LoadData2: Loaded waves, N= ", NumWaves, "from", ParentHDDataFolder+HDFolderPath	
SetDataFolder OldDf	
KillPath SymblkHDFolderPath
Return 1	
End

Function pt_LoadDataNthWave()	// see pt_LoadDataRecursive for recursive loading of data
// The older version is saved as pt_LoadDataNthWave1() 06/13/11
// From Praveens Igor Utilities. Modified to allow NDel = "" implying load all waves
String MatchStr, MatchExtn, HDFolderPath, IgorFolderPath
Variable DataIsImage, N0,NDel, NTot	// N0 = First Wave, NDel = Difference between Wave numbers

// Adapted from pt_LoadData
// This is always the latest version

// added the option so that only every nth wave starting from N0 Waves is loaded. Useful, when the waves are big (like EEG or Video) and we don't want to 
// load all the waves

// Previous version was pt_LoadData1 where all files were loaded first and then only matching files were kept. with "IndexedFile" you can get
// names all files in a folder and then load only the ones needed.  6th August, 2007

// To load waves having a "StringExpression" from a folder on disk. Load all files in a TempLoadData Folder and then select from there.
// Example Usage: pt_LoadData("*EPSP*", "D:users:taneja:data1:PresynapticNmda:NmdaEvoked:07_19_2004 Folder:Cell1326To1325Anal08_11_2004 Folder",  "root:EPSP")
String OldDf, ListStr, WaveStr, AllListStr
Variable i, NumWaves
String LastUpdatedMM_DD_YYYY="03/28/2011"

Print "*********************************************************"
Print "pt_LoadDataNthWave last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW	=	$pt_GetParWave("pt_LoadDataNthWave", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_LoadDataNthWave", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_LoadDataNthWave!!!"
EndIf

PrintAnalPar("pt_LoadDataNthWave")

MatchStr			= AnalParW[0]
MatchExtn			= AnalParW[1]
DataIsImage			= Str2Num(AnalParW[2])
HDFolderPath		= AnalParW[3]
IgorFolderPath		= AnalParW[4]
N0					= Str2Num(AnalParW[5])	// To start with first wave, N0=0
//If (!StringMatch(AnalParW[4], ""))
NDel				= Str2Num(AnalParW[6])
//EndIf
If (!StringMatch(AnalParW[7], ""))
NTot				= Str2Num(AnalParW[7])
EndIf


OldDf = GetDataFolder(1)
NewDataFolder /O/S  $(IgorFolderPath)		// No : at end)

NewPath /O/Q/C SymblkHDFolderPath, HDFolderPath
AllListStr= IndexedFile(SymblkHDFolderPath, -1, MatchExtn)
ListStr = ListMatch(AllListStr, MatchStr)
NumWaves = ItemsinList(ListStr)

//	For (i=0; i< NumWaves; i+=1)
//		WaveStr = StringFromList(i, ListStr, ";")
//		LoadWave /O/Q/P=SymblkHDFolderPath WaveStr
//	EndFor
//If (!StringMatch(AnalParW[4], ""))
NumWaves=  floor((NumWaves-N0)/NDel)
//EndIf
If (!StringMatch(AnalParW[7], ""))
NumWaves = (NumWaves> NTot) ? NTot : NumWaves
EndIf

For (i=0; i< NumWaves; i+=1)
	WaveStr = StringFromList(i*NDel+N0, ListStr, ";")
	If (DataIsImage)
	ImageLoad /O/Q/P=SymblkHDFolderPath WaveStr
	Else
	LoadWave /O/Q/P=SymblkHDFolderPath WaveStr
	EndIf	
EndFor

Print "Pt_LoadData: Loaded waves, N= ", NumWaves	
SetDataFolder OldDf	
KillPath /Z SymblkHDFolderPath
Return 1	
End

Function pt_LoadDataNthWave1()	// see pt_LoadDataRecursive for recursive loading of data
// The newer version is saved as pt_LoadDataNthWave() 06/13/11
String MatchStr, HDFolderPath, IgorFolderPath
Variable N0,NDel	// N0 = First Wave, NDel = Difference between Wave numbers

// Adapted from pt_LoadData
// This is always the latest version

// added the option so that only every nth wave starting from N0 Waves is loaded. Useful, when the waves are big (like EEG or Video) and we don't want to 
// load all the waves

// Previous version was pt_LoadData1 where all files were loaded first and then only matching files were kept. with "IndexedFile" you can get
// names all files in a folder and then load only the ones needed.  6th August, 2007

// To load waves having a "StringExpression" from a folder on disk. Load all files in a TempLoadData Folder and then select from there.
// Example Usage: pt_LoadData("*EPSP*", "D:users:taneja:data1:PresynapticNmda:NmdaEvoked:07_19_2004 Folder:Cell1326To1325Anal08_11_2004 Folder",  "root:EPSP")
String OldDf, ListStr, WaveStr, AllListStr
Variable i, NumWaves
String LastUpdatedMM_DD_YYYY="03/28/2011"

Print "*********************************************************"
Print "pt_LoadDataNthWave last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW	=	$pt_GetParWave("pt_LoadDataNthWave", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_LoadDataNthWave", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_LoadDataNthWave!!!"
EndIf

PrintAnalPar("pt_LoadDataNthWave")

MatchStr			= AnalParW[0]
HDFolderPath		= AnalParW[1]
IgorFolderPath		= AnalParW[2]
N0					= Str2Num(AnalParW[3])
NDel				= Str2Num(AnalParW[4])

OldDf = GetDataFolder(1)
NewDataFolder /O/S  $(IgorFolderPath)		// No : at end)

NewPath /O/Q/C SymblkHDFolderPath, HDFolderPath
AllListStr= IndexedFile(SymblkHDFolderPath, -1, ".ibw")
ListStr = ListMatch(AllListStr, MatchStr)
NumWaves = ItemsinList(ListStr)

//	For (i=0; i< NumWaves; i+=1)
//		WaveStr = StringFromList(i, ListStr, ";")
//		LoadWave /O/Q/P=SymblkHDFolderPath WaveStr
//	EndFor
NumWaves=  1+floor((NumWaves-N0)/NDel)

	For (i=0; i< NumWaves; i+=1)
		WaveStr = StringFromList(i*NDel+N0, ListStr, ";")
		LoadWave /O/Q/P=SymblkHDFolderPath WaveStr
	EndFor

Print "Pt_LoadData: Loaded waves, N= ", NumWaves	
SetDataFolder OldDf	
KillPath /Z SymblkHDFolderPath
Return 1	
End


Function pt_LoadDataRecursive(MatchStr, HDFolderPath, IgorFolderPath)	// same as above except recursive loading
String MatchStr, HDFolderPath, IgorFolderPath
// To load waves having a "StringExpression" from a folder on disk. Load all files in a TempLoadData Folder and then select from there.
// Example Usage: pt_LoadData("*EPSP*", "D:users:taneja:data1:PresynapticNmda:NmdaEvoked:07_19_2004 Folder:Cell1326To1325Anal08_11_2004 Folder",  "root:EPSP")
String OldDf, ListStr, WaveStr
Variable i, NumWaves

OldDf = GetDataFolder(1)
NewDataFolder /O  $(IgorFolderPath)		// No : at end)
NewDataFolder /O/S  $(IgorFolderPath+"Temp")
LoadData /Q/O/D/L=1/R HDFolderPath
ListStr= WaveList(MatchStr, ";", "")
NumWaves = ItemsinList(ListStr)

	For (i=0; i< NumWaves; i+=1)
		WaveStr = StringFromList(i, ListStr, ";")
		Duplicate /o $WaveStr, $(IgorFolderPath + ":" +WaveStr)
	EndFor
	KillDataFolder $(IgorFolderPath+"Temp")
Return 1	
End







Function pt_LoadDataRecursive2(MatchStr, HDFolderPath, IgorFolderPath)	// same as above except recursive loading
String MatchStr, HDFolderPath, IgorFolderPath
// modified from pt_LoadDataRecursive 08/25/12 (also modified pt_LoadData as pt_LoadData2)
// To allow for the common part of the HDFolderPath to be supplied
//specified separately. That way just by changing the common part the folder can be specifed on different computers.
// Eg. Right now HDFolderPath=Macintosh HD:Users:taneja:OldMastishk:j:users:JUsersTaneja:rutlin:RorBetaGFP:mIPSC:07_14_12 Folder
// We can change this to HDFolderPath= 07_14_12 Folder and a 
// HDFolderParentDir=Macintosh HD:Users:taneja:OldMastishk:j:users:JUsersTaneja:rutlin:RorBetaGFP:mIPSC:
// Then total path = HDFolderParentDir+HDFolderPath

// To load waves having a "StringExpression" from a folder on disk. Load all files in a TempLoadData Folder and then select from there.
// Example Usage: pt_LoadData("*EPSP*", "D:users:taneja:data1:PresynapticNmda:NmdaEvoked:07_19_2004 Folder:Cell1326To1325Anal08_11_2004 Folder",  "root:EPSP")
String OldDf, ListStr, WaveStr, FullHDFolderPath
SVAR ParentHDDataFolder=$"root:ParentHDDataFolder"
Variable i, NumWaves

OldDf = GetDataFolder(1)
NewDataFolder /O  $(IgorFolderPath)		// No : at end)
NewDataFolder /O/S  $(IgorFolderPath+"Temp")
FullHDFolderPath=ParentHDDataFolder+HDFolderPath
LoadData /Q/O/D/L=1/R FullHDFolderPath
ListStr= WaveList(MatchStr, ";", "")
NumWaves = ItemsinList(ListStr)

	For (i=0; i< NumWaves; i+=1)
		WaveStr = StringFromList(i, ListStr, ";")
		Duplicate /o $WaveStr, $(IgorFolderPath + ":" +WaveStr)
	EndFor
	KillDataFolder $(IgorFolderPath+"Temp")
Return 1	
End




Function /s pt_SortWavesInFolder(MatchStr, IgorFolderPath)
// ExampleUsage: pt_SortWavesInFolder("CntrlEegW*", "root:LoadedData")
String MatchStr, IgorFolderPath
String OldDf, WaveListStr
OldDf=GetDataFolder(-1)
SetDataFolder $IgorFolderPath
WaveListStr=WaveList(MatchStr, ";", "")
WaveListStr=SortList(WaveListStr, ";", 16)
SetDataFolder OldDf
Return WaveListStr
End

Function pt_ConcatenateWaves(WaveListStr, DestWaveName, IgorFolderPath)
// ExampleUsage: pt_ConcatenateWaves(pt_SortWavesInFolder("CntrlEegW*", "root:LoadedData"), "CntrlEegW", "root:LoadedData")
String WaveListStr, DestWaveName, IgorFolderPath
String OldDf
Variable i
OldDf=GetDataFolder(-1)
SetDataFolder $IgorFolderPath
//For (i=0; i <ItemsInList(WaveListStr); i+=1)
	Concatenate /NP WaveListStr,  $DestWaveName
//EndFor
SetDataFolder OldDf
End




Function pt_DisplayAnalyzed(CellBaseName,WavesFolder, FolderToLoadIn, WaveStartNum,WaveEndNum, NDig)
//example: pt_DisplayAnalyzed("Cell_000856_","D:users:taneja:data1:PresynapticNmda:NmdaEvoked:04_20_2004 Folder","root:Cell_000857ToCell_000856",6,125, 4)

//	Jesper's analysis calculates 1st epsp for all waves and then 2nd epsp for all waves. so if u want to plot all epsp's for a given wave u have to 
// 	use the transpose function above to form waves that will have all epsp's for a given wave in one wave. still need to do some clearing up of the
// 	code. 01/14/2004 (praveen taneja)
String CellBasename,WavesFolder, FolderToLoadIn
Variable  WaveStartNum, WaveEndNum, NDig
Variable i
String WindowName,CellName,CellNameAnalX,CellNameAnalY, OldDataFolder

//For (i=EpspStartNum;i<=EpspEndNum;i=i+1)
//	CellName=CellBaseName+num2digstr(NDig,WaveNum)
//	Wave w=$(CellName)
//	WindowName=CellBaseName+"Anal"+num2digstr(NDig,WaveNum)
//	DoWindow $WindowName
//	Display  w
//	CellNameAnalX=CellBaseName+"EPSP_AnalXWave"+num2digstr(NDig,i+1)+"_T"
//	CellNameAnalY=CellBaseName+"EPSP_AnalYWave"+num2digstr(NDig,i+1)+"_T"	
//	Wave w1=$(CellNameAnalX)
//	Wave w2=$(CellNameAnalY)
//	DoWindow $WindowName
//	AppendtoGraph /C=(0,0,0) w2 vs w1 
//	ModifyGraph mode($CellNameAnalY)=3,rgb($CellNameAnalY)=(0,0,0)
//EndFor
OldDataFolder = GetDataFolder(1)
SetDataFolder FolderToLoadIn	
	
	pt_LoadWaves(CellBaseName,WavesFolder,FolderToLoadIn,WaveStartNum,WaveEndNum, 1,NDig)	// don't load if wave already exists
	
	For (i=WaveStartNum;i<=WaveEndNum;i=i+1)
		CellName=CellBaseName+num2digstrCopy(NDig,i)
		Wave w=$(CellName)
		WindowName=CellBaseName+"Anal"+num2digstrCopy(NDig,i)
		DoWindow $WindowName
		Display  w
	
		CellNameAnalX=CellBaseName+"Epsp_AnalXWave"+num2istr(i)+"_T"
		CellNameAnalY=CellBaseName+"Epsp_AnalYWave"+num2istr(i)+"_T"	
		Wave w1=$(CellNameAnalX)
		Wave w2=$(CellNameAnalY)
		DoWindow $WindowName
		AppendtoGraph /C=(0,0,0) w2 vs w1
		ModifyGraph mode($CellNameAnalY)=3,rgb($CellNameAnalY)=(0,0,0)
	EndFor
SetDataFolder OldDataFolder	
return 1
end

// Function to calculate CV Analysis parameters. For subtraction of background variance, we have calculated the variance before epsp's for each wave and then
// calculated the mean of these variances (cos variances add!). This average background variance is subtracted from variance of EPSP's. Has to be checked for
// some test cases still to see if its working properly 02/02/2004 (praveen taneja)

Function pt_CVAnalysis(DataWaveNameStr, BGndWaveNameStr,BeforeStartVal,BeforeEndVal,AfterStartVal,AfterEndVal,r,m)
String DataWaveNameStr, BGndWaveNameStr
 
Variable BeforeStartVal,BeforeEndVal,AfterStartVal,AfterEndVal,&r,&m
Variable BeforeBGndVarianceAve, AfterBGndVarianceAve, DataMeanBefore, DataVarianceBefore,DataMeanAfter, DataVarianceAfter,CVBefore,CVAfter

Wave w = $(BGndWaveNameStr)

BeforeBGndVarianceAve=mean(w,BeforeStartVal, BeforeEndVal)
AfterBGndVarianceAve  =mean(w,AfterStartVal, AfterEndVal )
// print pnt2x(w,BeforeStartNum), pnt2x(w,BeforeEndNum),pnt2x(w,AfterStartNum), pnt2x(w,AfterEndNum)

Wave w = $(DataWaveNameStr)

WaveStats /Q/R=(BeforeStartVal,BeforeEndVal) w
DataMeanBefore=V_avg
DataVarianceBefore=V_Sdev^2

WaveStats /Q/R=(AfterStartVal,AfterEndVal) w
DataMeanAfter=V_avg
DataVarianceAfter=V_Sdev^2

DataVarianceBefore -= BeforeBGndVarianceAve
DataVarianceAfter  -= AfterBGndVarianceAve

CVBefore = (DataVarianceBefore^0.5)/DataMeanBefore
CVAfter	  = (DataVarianceAfter^0.5)/DataMeanAfter

r = CVBefore^2/CVAfter^2
m = DataMeanAfter/DataMeanBefore

End

Function pt_PrintCVAnalysis(DataWaveNameStr, BGndWaveNameStr,BeforeStartVal,BeforeEndVal,AfterStartVal,AfterEndVal)

// Example Use: pt_PrintCVAnalysis("Cell_000441_EPSP_0001", "Cell_000441_bNoise",6,20,36,45)

String DataWaveNameStr, BGndWaveNameStr
Variable BeforeStartVal,BeforeEndVal,AfterStartVal,AfterEndVal
Variable r, m

pt_CVAnalysis(DataWaveNameStr, BGndWaveNameStr,BeforeStartVal,BeforeEndVal,AfterStartVal,AfterEndVal,r,m) 

print "r,m = ",r,m

End

Function pt_CoarseBin(WaveNameStr,PntsPerBin)

// This function Coarse Bins the wave (output wave has extension _CBY); ie. it will take replace every n=PntsPerBin with 
//  their average. it can take care of Nan's and also the pnts in the wave need not be exactly divisible by PntsPerBin. 01/262004 (Praveen Taneja)

// It also provides the x-dimension of new wave in 2 of the following waves

// 1.) using setscale, but this implies waveform data for final wave. if number of pnts in data wave is not divisible by PntsPerBin, 
// it places the last point where it shud have been on the X-axis

// 2.) Also calculates a  separate X-Wave (extension _CBX) which has the correct value for the last X value (needed when number of 
// pnts in data wave is not divisible by PntsPerBin)   01/31/04 (praveen taneja)

// Example: pt_CoarseBin("Cell_000403_EPSP_0001",2)
//		   : pt_CoarseBin("TimeAxisWave",2)

String WaveNameStr
variable PntsPerBin
variable SrcIndex, DestIndex, LastSrcIndex,LastXWaveVal,TotalXWave,TotalYWave,TempNumX,TempNumY,NumpntsDestWave,NumPntsSrcWave
variable DestWaveDimOffset,DestWaveDimDelta,DeltaSrcWave,OffsetSrcWave

Wave SrcWave= $(WaveNameStr) 
NumPntsSrcWave=Numpnts(SrcWave)

if (mod(NumPntsSrcWave,PntsPerBin)==0)
NumpntsDestWave=(NumPntsSrcWave/PntsPerBin)
else
NumpntsDestWave=(Ceil(NumPntsSrcWave/PntsPerBin)) 
Endif

Make /O/N=(NumpntsDestWave) $(WaveNameStr+"_CBY")
Wave DestYWave=$(WaveNameStr+"_CBY")

Make /O/N=(NumpntsDestWave) $(WaveNameStr+"_CBX")
Wave DestXWave=$(WaveNameStr+"_CBX")

DeltaSrcWave=DimDelta(SrcWave,0)
OffsetSrcWave=DimOffset(SrcWave,0)

LastSrcIndex=0
LastXWaveVal=0


For (DestIndex=0;DestIndex<=(NumpntsDestWave-1); DestIndex += 1)
	
	TotalXWave=0
	TotalYWave=0
	TempNumX=0
	TempNumY=0
	
	For (SrcIndex=(LastSrcIndex); (SrcIndex<=(LastSrcIndex+PntsPerBin-1)&&SrcIndex<=(NumpntsSrcWave-1)); SrcIndex+=1)
		
		if (numtype(SrcWave[SrcIndex])==0)
		totalYWave=totalYWave+SrcWave[SrcIndex]
		TempNumY=TempNumY+1
		Endif
		
		TotalXWave=TotalXWave+ (OffsetSrcWave+DeltaSrcWave*SrcIndex)
		TempNumX=TempNumX+1
		LastXWaveVal=(OffsetSrcWave+DeltaSrcWave*SrcIndex)
		
	Endfor
	
	DestXWave[DestIndex]=TotalXWave/TempNumX
	DestYWave[DestIndex]=TotalYWave/TempNumY	
	LastSrcIndex=SrcIndex
	
EndFor

DestWaveDimOffset=DimOffset(SrcWave,0)+( ( (PntsPerBin-1) * DimDelta(SrcWave,0) )/2 )
DestWaveDimDelta=DimDelta(SrcWave,0)*PntsPerBin
SetScale /p x,DestWaveDimOffset,DestWaveDimDelta,DestYWave

Return 1
End

Function pt_ConvertBlockDataToWave(OutPutWaveName, StartWaveNum, EndWaveNum, PntsPerBin)
// This function takes data from many waves and makes a single wave w such that w[i=0 To PntsPerBin-1] = w1[0 To PntsPerBin-1], 
// w[i=PntsPerBin To 2*PntsPerBin-1] = w2[0 To PntsPerBin], and so on...This wave can then be further processed for statistics, etc. 
// Now this function can be used to select data from StartWaveNum to EndWaveNum
//  Usage: Eg. pt_ConvertBlockDataToWave("ControlExtendedWave",0,44,5)
String OutPutWaveName
Variable PntsPerBin, StartWaveNum, EndWaveNum

Variable NumWaves, NumPntsSrcWave, NumpntsDestWave, RemainingPntsNum=0, NumPntsW1, j, i
String 	wavlist, WaveNameStr
wavlist = wavelist("*",";","WIN:")
print "Converting",wavlist, "to a single wave"
NumWaves = ItemsInList(WavList)

WaveNameStr= StringFromList (0,wavlist,";") // first wave in list 
wave w = $WaveNameStr
//NumPntsSrcWave = NumPnts(w)
NumPntsSrcWave = EndWaveNum-StartWaveNum+1

if (mod(NumPntsSrcWave,PntsPerBin)==0) // figure dimensionality of final wave
NumpntsDestWave=(NumPntsSrcWave/PntsPerBin)
else
NumpntsDestWave=ceil(NumPntsSrcWave/PntsPerBin)
RemainingPntsNum= NumPntsSrcWave-PntsPerBin*Floor(NumPntsSrcWave/PntsPerBin)
Endif

NumPntsW1= NumPntsSrcWave*NumWaves
Make /O/N=(NumPntsW1) $OutPutWaveName
Wave w1=$OutPutWaveName

For (j=0; j< NumpntsDestWave; j+=1)
	For (i=0; i< NumWaves; i+=1)
		WaveNameStr= StringFromList (i,wavlist,";")
//		if (strlen(WaveNameStr)== 0)
//			break
//		endif
 		if (strlen(WaveNameStr)== 0)
  			Print "While finding converting blockdata to wave could not find wave #", i
  			DoAlert 0, "Exiting without finishing!!"
 			break
 			endif
 		wave w = $WaveNameStr
// 		Convert the block data into a column data. 		
//		w1[j*PntsPerBin*NumWaves+PntsPerBin*i,j*PntsPerBin*NumWaves+PntsPerBin*(i+1)-1]=w[p-PntsPerBin*i-j*PntsPerBin*(NumWaves-1)] Simplified expression below
//		w1[PntsPerBin*(NumWaves*j+i), PntsPerBin*(NumWaves*j+i+1)-1 ] = w[p - PntsPerBin*(i+j*(NumWaves-1)) ]
		
		If (  ((NumpntsDestWave-j-1)==0) && (RemainingPntsNum!=0)  )
			w1[PntsPerBin*(NumWaves*j)+RemainingPntsNum*i, PntsPerBin*(NumWaves*j)+RemainingPntsNum*(i+1)-1] = w[StartWaveNum+ p - PntsPerBin*(j*(NumWaves-1))-RemainingPntsNum*(i) ]
		Else
			w1[PntsPerBin*(NumWaves*j+i), PntsPerBin*(NumWaves*j+i+1)-1 ] = w[StartWaveNum+ p - PntsPerBin*(i+j*(NumWaves-1)) ]
		EndIf
	EndFor
EndFor
End


Function pt_CoarseBin1(WaveNameStr, OutPutWaveName, PntsPerBin)
// This function coarse bins the wave $DataWaveName
// Usage: Eg. pt_CoarseBin1("w1", "w1", 20)
String WaveNameStr, OutPutWaveName
Variable PntsPerBin

Variable NumPntsSrcWave, NumpntsDestWave, DeltaSrcWave, OffsetSrcWave, DestWaveDimOffset, DestWaveDimDelta, i

Wave w= $(WaveNameStr) 
NumPntsSrcWave=Numpnts(w)

if (mod(NumPntsSrcWave,PntsPerBin)==0)
NumpntsDestWave=(NumPntsSrcWave/PntsPerBin)
else
NumpntsDestWave=(Ceil(NumPntsSrcWave/PntsPerBin)) 
Endif

Make /O/N=(NumpntsDestWave) $(OutPutWaveName+"Avg"), $(OutPutWaveName+"StdDev"), $(OutPutWaveName+"Num"), $(OutPutWaveName+"StdErr")
Wave w2= $(OutPutWaveName+"Avg")
Wave w3= $(OutPutWaveName+"StdDev")
Wave w4= $(OutPutWaveName+"Num")
Wave w5= $(OutPutWaveName+"StdErr")

DeltaSrcWave=DimDelta(w,0)
OffsetSrcWave=DimOffset(w,0)
DestWaveDimOffset=DimOffset(w,0)+( ( (PntsPerBin-1) * DimDelta(w,0) )/2 )		// To set the correct scaling for final wave.
DestWaveDimDelta=DimDelta(w,0)*PntsPerBin

For (i=0; i<NumpntsDestWave; i+=1)
	WaveStats /Q/R=[PntsPerBin*i, PntsPerBin*(i+1)-1] w
	w2[i]= V_Avg
	w3[i]= V_SDev
	w4[i]= V_NPnts
	w5[i]= V_SDev/(sqrt(V_Npnts))
EndFor

SetScale /p x,DestWaveDimOffset,DestWaveDimDelta, w2,w3,w4,w5

End

Function pt_AverageWaveXY()
// to take X-Y waves and average them
String XDataWaveMatchStr, YDataWaveMatchStr, BaseNameString, DataFldrStr
Variable XStartVal, XEndVal, XBinWidth, XEpsilonVal, InterpolNPnts	 

String 	XWList, YWList, XWaveStr, YWaveStr , OldDF
Variable NumWaves, i, j, k, p1, p2, x1,x2, NumpntsDestW

Wave /T ParNamesW	=$("root:FuncParWaves:pt_AverageWaveXY"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_AverageWaveXY"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AverageWaveXYParW and/or pt_AverageWaveXYParNamesW!!!"
EndIf

XDataWaveMatchStr			=		ParW[0]
YDataWaveMatchStr			=		ParW[1]
XStartVal					=Str2Num(ParW[2])
XEndVal						=Str2Num(ParW[3])
XBinWidth					=Str2Num(ParW[4])
XEpsilonVal					=Str2Num(ParW[5])
InterpolNPnts				=Str2Num(ParW[6])
DataFldrStr					=		ParW[7]
BaseNameString				=		ParW[8]

x1=XStartVal
OldDF=GetDataFolder(-1)
SetDataFolder $DataFldrStr
XWList=pt_SortWavesInFolder(XDataWaveMatchStr, GetDataFolder(-1))
YWList=pt_SortWavesInFolder(YDataWaveMatchStr, GetDataFolder(-1))
 If (ItemsInList(XWList,";")!=ItemsInList(YWList,";"))
 	Abort "X and Y Waves diff in num"
 Else
 	NumWaves=	ItemsInList(XWList,";")
EndIf

NumpntsDestW=ceil((XEndVal-XStartVal)/XBinWidth)

Make /O/N=(NumpntsDestW) $(BaseNameString+"Avg"), $(BaseNameString+"StdDev"), $(BaseNameString+"Num"), $(BaseNameString+"StdErr")
Wave w2= $(BaseNameString+"Avg")
Wave w3= $(BaseNameString+"StdDev")
Wave w4= $(BaseNameString+"Num")
Wave w5= $(BaseNameString+"StdErr")


For (j=0; j<NumpntsDestW; j+=1)
	For (i=0; i<NumWaves; i+=1)
		XWaveStr=StringFromList(i, XWList,";")
		YWaveStr=StringFromList(i,YWList,";")
		Wave Xwave=$XWaveStr
		Wave Ywave=$YWaveStr
		If (j==0)
			Print "Averaging Waves...", XWaveStr, YWaveStr
		EndIf	
		Sort XWave, XWave,YWave
		p1=BinarySearch(XWave, x1) 
				
		do				// since binary search gives "highest" p such that w[p], w[p+1] bracket the value.  
		If (p1>0 && Xwave[p1]==XWave[p1-1])
			p1-=1
		Else
			Break
		EndIf	
		while (1)
		
		If (p1==-1)
			Print x1,"lies left of wave", XWaveStr
		ElseIf (p1==-2)	
			Print x1,"lies right of wave", XWaveStr
		EndIf
		
		p2=BinarySearch(XWave, x1+XBinWidth)
		
		If (p2==-1)
			Print x1,"lies left of wave", XWaveStr
		ElseIf (p2==-2)	
			Print x1,"lies right of wave", XWaveStr
		EndIf

		If	((p1>=0) && (p2>=0))
				p1 = (p1!=p2) ? p1+1 : p1	// range !=0 : range=0 
				Make /O/N=(InterpolNPnts) wInterPolated
				For (k=0;k<InterpolNPnts; k+=1)
				
					If (mod(InterpolNPnts,2)==0 && -(trunc(InterpolNPnts/2)-k)>=0)		
						wInterPolated[k]=	interp((x1+0.5*XBinWidth-(trunc(InterpolNPnts/2)-(k+1))*XEpsilonVal), XWave, YWave)	// for InterpolNPnts=even, skip the value at center
						Print x1+0.5*XBinWidth-(trunc(InterpolNPnts/2)-(k+1))*XEpsilonVal, wInterPolated[k]
					Else
						wInterPolated[k]=	interp((x1+0.5*XBinWidth-(trunc(InterpolNPnts/2)-k)*XEpsilonVal), XWave, YWave)
						Print x1+0.5*XBinWidth-(trunc(InterpolNPnts/2)-k)*XEpsilonVal, wInterPolated[k]
					EndIf				

				EndFor
				Concatenate /NP {wInterPolated}, w1
				KillWaves wInterPolated
//				Duplicate /O /R=[p1+1,p2] YWave, w
//				Concatenate /NP {w}, w1
//				KillWaves w
		EndIf		
	EndFor
//	edit w1
	If (NumPnts(w1)!=0)
		WaveStats /q w1
		w2[j]= V_Avg
		w3[j]= V_SDev
		w4[j]= V_NPnts
		w5[j]= V_SDev/(sqrt(V_Npnts))
	Else
		w2[j]= Nan
		w3[j]= Nan
		w4[j]= Nan
		w5[j]= Nan
	EndIf
	x1=x1+XBinWidth
	KillWaves w1
EndFor
setscale /P x XStartVal+.5*XBinWidth,  XBinWidth, w2,w3,w4,w5
SetDataFolder OldDF

End

Function pt_AverageWaveXY1()
// to take X-Y waves and average them
String XDataWaveMatchStr, YDataWaveMatchStr, BaseNameString, DataFldrStr
Variable XStartVal, XEndVal, XBinWidth, XEpsilonVal, InterpolNPnts	 

String 	XWList, YWList, XWaveStr, YWaveStr , OldDF
Variable NumWaves, i, j, k, p1, p2, x1,x2, NumpntsDestW

Wave /T ParNamesW	=$("root:FuncParWaves:pt_AverageWaveXY"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_AverageWaveXY"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AverageWaveXYParW and/or pt_AverageWaveXYParNamesW!!!"
EndIf

XDataWaveMatchStr			=		ParW[0]
YDataWaveMatchStr			=		ParW[1]
XStartVal					=Str2Num(ParW[2])
XEndVal						=Str2Num(ParW[3])
XBinWidth					=Str2Num(ParW[4])
XEpsilonVal					=Str2Num(ParW[5])
InterpolNPnts				=Str2Num(ParW[6])
DataFldrStr					=		ParW[7]
BaseNameString				=		ParW[8]

x1=XStartVal
OldDF=GetDataFolder(-1)
SetDataFolder $DataFldrStr
XWList=pt_SortWavesInFolder(XDataWaveMatchStr, GetDataFolder(-1))
YWList=pt_SortWavesInFolder(YDataWaveMatchStr, GetDataFolder(-1))
 If (ItemsInList(XWList,";")!=ItemsInList(YWList,";"))
 	Abort "X and Y Waves diff in num"
 Else
 	NumWaves=	ItemsInList(XWList,";")
EndIf

NumpntsDestW=ceil((XEndVal-XStartVal)/XBinWidth)

Make /O/N=(NumpntsDestW) $(BaseNameString+"Avg"), $(BaseNameString+"StdDev"), $(BaseNameString+"Num"), $(BaseNameString+"StdErr")
Wave w2= $(BaseNameString+"Avg")
Wave w3= $(BaseNameString+"StdDev")
Wave w4= $(BaseNameString+"Num")
Wave w5= $(BaseNameString+"StdErr")


For (j=0; j<NumpntsDestW; j+=1)
	For (i=0; i<NumWaves; i+=1)
		XWaveStr=StringFromList(i, XWList,";")
		YWaveStr=StringFromList(i,YWList,";")
		Wave Xwave=$XWaveStr
		Wave Ywave=$YWaveStr
		If (j==0)
			Print "Averaging Waves...", XWaveStr, YWaveStr
		EndIf	
		Sort XWave, XWave,YWave
//		p1=BinarySearch(XWave, x1) 
				
//		p1 = (p1==-1)? 0 : ( (p1==-2)? NumPnts(Xwave)-1 : p1)		
//		If (p1==-1)
//			p1=0
//		ElseIf (p1==-2)	
//			p1=NumPnts(Xwave)-1
//		EndIf
		
//		do				// since binary search gives "highest" p such that w[p], w[p+1] bracket the value.  
//			If (p1>0 && Xwave[p1]==XWave[p1-1])
//				p1-=1
//			Else
//				Break
//			EndIf	
//		while (1)
		
		
//		p2=BinarySearch(XWave, x1+XBinWidth)
		
//		p2 = (p2==-1)? 0 : ( (p2==-2)? NumPnts(Xwave)-1 : p2)
//		If (p2==-1)
//			p2=0
//		ElseIf (p2==-2)	
//			p2=NumPnts(Xwave)-1
//		EndIf

//		If	((p1>=0) && (p2>=0))
//				p1 = (p1!=p2) ? p1+1 : p1	// range !=0 : range=0 
				Make /O/N=(InterpolNPnts) wInterPolated
				For (k=0;k<InterpolNPnts; k+=1)
				
					If (mod(InterpolNPnts,2)==0 && -(trunc(InterpolNPnts/2)-k)>=0)		
						wInterPolated[k]=	interp((x1+0.5*XBinWidth-(trunc(InterpolNPnts/2)-(k+1))*XEpsilonVal), XWave, YWave)	// for InterpolNPnts=even, skip the value at center
						Print x1+0.5*XBinWidth-(trunc(InterpolNPnts/2)-(k+1))*XEpsilonVal, wInterPolated[k]
					Else
						wInterPolated[k]=	interp((x1+0.5*XBinWidth-(trunc(InterpolNPnts/2)-k)*XEpsilonVal), XWave, YWave)
						Print x1+0.5*XBinWidth-(trunc(InterpolNPnts/2)-k)*XEpsilonVal, wInterPolated[k]
					EndIf				

				EndFor
				Concatenate /NP {wInterPolated}, w1
				KillWaves wInterPolated
//				Duplicate /O /R=[p1+1,p2] YWave, w
//				Concatenate /NP {w}, w1
//				KillWaves w
//		EndIf		
	EndFor
//	edit w1
	If (NumPnts(w1)!=0)
		WaveStats /q w1
		w2[j]= V_Avg
		w3[j]= V_SDev
		w4[j]= V_NPnts
		w5[j]= V_SDev/(sqrt(V_Npnts))
	Else
		w2[j]= Nan
		w3[j]= Nan
		w4[j]= Nan
		w5[j]= Nan
	EndIf
	x1=x1+XBinWidth
	KillWaves w1
EndFor
setscale /P x XStartVal+.5*XBinWidth,  XBinWidth, w2,w3,w4,w5
SetDataFolder OldDF

End

Function pt_AverageWaveXY2()
// to take X-Y waves and average them
String XDataWaveMatchStr, YDataWaveMatchStr, BaseNameString, DataFldrStr
Variable XStartVal, XEndVal, XBinWidth, XEpsilonVal, InterpolNPnts, x1Num, x1AvgNum	 

String 	XWList, YWList, XWaveStr, YWaveStr , OldDF
Variable NumWaves, i, j, k, m, p1, p2,  x1, NumpntsDestW

Wave /T ParNamesW	=$("root:FuncParWaves:pt_AverageWaveXY2"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_AverageWaveXY2"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AverageWaveXY2ParW and/or pt_AverageWaveXY2ParNamesW!!!"
EndIf

XDataWaveMatchStr			=		ParW[0]
YDataWaveMatchStr			=		ParW[1]
//XStartVal					=Str2Num(ParW[2])
//XEndVal					=Str2Num(ParW[3])
//XBinWidth					=Str2Num(ParW[4])
XEpsilonVal					=Str2Num(ParW[2])
//InterpolNPnts				=Str2Num(ParW[6])
//DataFldrStr					=		ParW[3]
BaseNameString				=		ParW[3]

//x1=XStartVal
//OldDF=GetDataFolder(-1)
//SetDataFolder $DataFldrStr
XWList=pt_SortWavesInFolder(XDataWaveMatchStr, GetDataFolder(-1))
YWList=pt_SortWavesInFolder(YDataWaveMatchStr, GetDataFolder(-1))
 If (ItemsInList(XWList,";")!=ItemsInList(YWList,";"))
 	Abort "X and Y Waves diff in num"
 Else
 	NumWaves=	ItemsInList(XWList,";")
EndIf

For (i=0; i<NumWaves; i+=1)
	XWaveStr=StringFromList(i, XWList,";")
	Wave Xwave=$XWaveStr
	Concatenate /NP {XWave}, XWaveFull
EndFor

Sort XWaveFull, XWaveFull

WaveStats /Q XWaveFull
XStartVal=V_min
XEndVal=V_Max
	
//NumpntsDestW=ceil((XEndVal-XStartVal)/XBinWidth)

Make /O/N=0 $(BaseNameString+"Avg"), $(BaseNameString+"StdDev"), $(BaseNameString+"Num"), $(BaseNameString+"StdErr"), $(BaseNameString+"XWave")
Wave y2= $(BaseNameString+"Avg")
Wave y3= $(BaseNameString+"StdDev")
Wave y4= $(BaseNameString+"Num")
Wave y5= $(BaseNameString+"StdErr")
Wave y6= $(BaseNameString+"XWave")

Make /o/N=1 TmpW

x1=XStartVal
Do
	If (x1> XEndVal)
		Break
	EndIf
	// find avg num of times x1 is present in the waves
	Make /O/N=0 x1NumW
	Make /O/N=1 x1NumTmpW
	
	For (i=0; i<NumWaves; i+=1)
		XWaveStr=StringFromList(i, XWList,";")
		Wave Xwave=$XWaveStr
		x1Num=0
		For (j=0; j<NumPnts(Xwave) ; j+=1)
			x1Num= (XWave[j]==x1)? x1Num+1 : x1Num	
		EndFor
		If (x1Num>=1)
			x1NumTmpW[0]=x1Num
			Concatenate /NP {x1NumTmpW}, x1NumW
		EndIf	
	EndFor
	WaveStats /Q x1NumW
	x1AvgNum=round(V_avg)	
	
	For (i=0; i<NumWaves; i+=1)
		XWaveStr=StringFromList(i, XWList,";")
		YWaveStr=StringFromList(i,YWList,";")
		Duplicate /O $XWaveStr, $(XWaveStr+"S")
		Wave Xwave=$(XWaveStr+"S")
		Duplicate /O $YWaveStr, $(YWaveStr+"S")
		Wave Ywave=$(YWaveStr+"S")
//		If (j==0)
//			Print "Averaging Waves...", XWaveStr, YWaveStr
//		EndIf	
		Sort XWave, XWave,YWave
		p1=BinarySearch(XWave, x1) 
		If (p1>=0)
			do				// since binary search gives "highest" p such that w[p], w[p+1] bracket the value.  
				If (p1>0 && Xwave[p1]==XWave[p1-1])
					p1-=1
				Else
					Break
				EndIf	
			while (1)
		
			Make /O/N=(x1AvgNum) yW
			k=0
			Do 
				If (k<x1AvgNum && p1>=0 && XWave(p1)==x1)
					yW[k]=YWave[p1]
					k+=1
					p1+=1
				Else
					Break
				EndIf	
			While (1)
			InterpolNPnts= x1AvgNum-k
			If (InterPolNPnts>0)
			Make /O/N=(InterpolNPnts) XInterpW, YInterpW
					For (j=0; j<InterpolNPnts; j+=1)
						If (mod(InterpolNPnts,2)==0 && -(trunc(InterpolNPnts/2)-j)>=0)	
							XInterpW[j]=	x1-(trunc(InterpolNPnts/2)-(j+1))*XEpsilonVal
//							Print x1-(trunc(InterpolNPnts/2)-(j+1))*XEpsilonVal
						Else
							XInterpW[j]= x1-(trunc(InterpolNPnts/2)-j)*XEpsilonVal
//							Print x1-(trunc(InterpolNPnts/2)-j)*XEpsilonVal
						EndIf	
					EndFor	
//					yW[k]=	interp((x1-(trunc(InterpolNPnts/2)-(j+1))*XEpsilonVal), XWave, YWave)	// for InterpolNPnts=even, skip the value at center
//					Print x1-(trunc(InterpolNPnts/2)-(j+1))*XEpsilonVal, yW[k]
				

//					yW[k]=	interp((x1-(trunc(InterpolNPnts/2)-j)*XEpsilonVal), XWave, YWave)
//					Print x1-(trunc(InterpolNPnts/2)-j)*XEpsilonVal, yW[k]	
		
			Interpolate2/T=1/I=3/Y=YInterpW/X=XInterpW XWave, YWave
			Print "******************"
			Print "Interpolated pnts:",XWaveStr, YWaveStr
			For (m=0; m<NumPnts(XInterpW); m+=1)
				Print XInterpW[m], YInterpW[m]
			EndFor	
			yW[k, x1AvgNum-1]=YInterpW[p-k]
			KillWaves XInterpW, YInterpW
			EndIf	
			Concatenate /NP {yW}, y1
		EndIf
		KillWaves yW, XWave,YWave	
	EndFor
		If (NumPnts(y1)!=0)
			WaveStats /q y1
			TmpW=V_Avg				 ; Concatenate /NP {TmpW}, y2
			TmpW=V_SDev				 ; Concatenate /NP {TmpW}, y3
			TmpW=V_NPnts				 ; Concatenate /NP {TmpW}, y4
			TmpW=V_SDev/(sqrt(V_Npnts)) ; Concatenate /NP {TmpW}, y5
		Else
			TmpW=Nan				; Concatenate /NP {TmpW}, y2
			TmpW=Nan				; Concatenate /NP {TmpW}, y3
			TmpW=Nan				; Concatenate /NP {TmpW}, y4
			TmpW=Nan				; Concatenate /NP {TmpW}, y5
		EndIf
		TmpW[0]=x1
		Concatenate /NP {TmpW}, y6
		m=0
		Do 
			If (XWaveFull[m]>x1)
				x1=XWaveFull[m]
				Break
			EndIf
			m+=1
			If (m>=NumPnts(XWaveFull) )
				x1= XEndVal+1
				Break
			EndIf	
		While (1)
	KillWaves y1
While (1)

KillWaves XWaveFull, x1NumW, x1NumTmpW, TmpW
//SetDataFolder OldDF

End

Function pt_NormIByC()
String DataWaveMatchStr, IWName, CWName, SuffixStr

String WList, WNameStr		
Variable Numwaves, i
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_NormIByC", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_NormIByC", "ParW")

DataWaveMatchStr			=	(AnalParW[0])
IWName						=	(AnalParW[1])
CWName					=	(AnalParW[2])
SuffixStr						=	(AnalParW[3])

PrintAnalPar("pt_NormIByC")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")

Wave iw	 = $IWName
Wave cw = $CWName 


If (NumWaves==NumPnts(cw))
	For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	sscanf WNameStr, "%11s", WNameStr
	Duplicate /O iw $(WNameStr + SuffixStr)
	Wave w = $(WNameStr + SuffixStr)
	w /= cw[i]
	EndFor
Else
	Abort "capacitance wave has diff. num. of pnts than num of data waves found"
EndIf

End


// This is older version! Latest version is always pt_AverageWaves
Function pt_AverageWaves1(DataWaveMatchStr, BaseNameString, PntsPerBin, ExcludeWNamesWStr)
// This function averages waves taken from the top window. To calculate the final  average waves (and the like) it  takes "PntsPerBin" number of pnts
//from each wave for each pnt. Also dimensionality of final wave = dimensionality of longest wave.

Variable PntsPerBin
String DataWaveMatchStr, BaseNameString, ExcludeWNamesWStr

Variable NumPntsSrcWave, NumpntsDestWave, i, j, NumWaves, NumPntsW1, DeltaSrcWave, OffsetSrcWave, DestWaveDimOffset, DestWaveDimDelta
String wavlist, WaveNameStr

If (StrLen(DataWaveMatchStr)==0)
wavlist = wavelist("*",";","WIN:")
Else
wavlist = wavelist(DataWaveMatchStr,";","")
EndIf
wavlist = pt_ExcludeFromWList(ExcludeWNamesWStr, wavlist)

print "Averaging waves...N=",ItemsInList(wavlist, ";"), wavlist
NumWaves = ItemsInList(WavList)

NumPntsSrcWave=0

For (i=0; i<NumWaves; i+=1)
WaveNameStr= StringFromList (i,wavlist,";") 
wave w = $WaveNameStr
NumPntsSrcWave = (NumPntsSrcWave<NumPnts(w)) ?  NumPnts(w) : NumPntsSrcWave
EndFor



DeltaSrcWave=DimDelta(w,0)
OffsetSrcWave=DimOffset(w,0)
DestWaveDimOffset=DimOffset(w,0)+( ( (PntsPerBin-1) * DimDelta(w,0) )/2 )		// To set the correct scaling for final wave.
DestWaveDimDelta=DimDelta(w,0)*PntsPerBin

if (mod(NumPntsSrcWave,PntsPerBin)==0) // figure dimensionality of final wave
NumpntsDestWave=(NumPntsSrcWave/PntsPerBin)
else
NumpntsDestWave=(Ceil(NumPntsSrcWave/PntsPerBin)) 
Endif

NumPntsW1= NumPntsSrcWave*NumWaves
Make /O/N=(NumPntsW1) w1
//Make /O/N=(NumpntsDestWave) $(BaseNameString+"Avg"), $(BaseNameString+"StdDev"), $(BaseNameString+"Num"), $(BaseNameString+"StdErr")
Make /O/N=(NumpntsDestWave) $(BaseNameString+"Avg"), $(BaseNameString+"SD"), $(BaseNameString+"Num"), $(BaseNameString+"SE")
Wave w2= $(BaseNameString+"Avg")
//Wave w3= $(BaseNameString+"StdDev")
Wave w3= $(BaseNameString+"SD")
Wave w4= $(BaseNameString+"Num")
//Wave w5= $(BaseNameString+"StdErr")
Wave w5= $(BaseNameString+"SE")

For (j=0; j< NumpntsDestWave; j+=1)
	For (i=0; i< NumWaves; i+=1)
		WaveNameStr= StringFromList (i,wavlist,";")
//		if (strlen(WaveNameStr)== 0)
 //			break
 //		endif
 		if (strlen(WaveNameStr)== 0)
  			Print "While finding average of waves could not find wave #", i
  			DoAlert 0, "Exiting without finishing!!"
 			break
 		endif
 		
 		
 		
 		wave w = $WaveNameStr
// 		Convert the block data into a column data. 		
//		w1[j*PntsPerBin*NumWaves+PntsPerBin*i,j*PntsPerBin*NumWaves+PntsPerBin*(i+1)-1]=w[p-PntsPerBin*i-j*PntsPerBin*(NumWaves-1)] Simplified expression below

//		w1[PntsPerBin*(NumWaves*j+i), PntsPerBin*(NumWaves*j+i+1)-1 ] = w[p - PntsPerBin*(i+j*(NumWaves-1)) ]
// if the index is bigger than dimension of wave then weird things can happen. check and set it to NAN.   Praveen 03/01/2007
		w1[PntsPerBin*(NumWaves*j+i), PntsPerBin*(NumWaves*j+i+1)-1 ] = (p - PntsPerBin*(i+j*(NumWaves-1)))>(NumPnts(w)-1) ? Nan : w[p - PntsPerBin*(i+j*(NumWaves-1)) ]
	EndFor
EndFor
For (i=0; i<NumpntsDestWave; i+=1)
	WaveStats /Q/R=[NumWaves*PntsPerBin*i, NumWaves*PntsPerBin*(i+1)-1] w1
	w2[i]= V_Avg
	w3[i]= V_SDev
	w4[i]= V_NPnts
	w5[i]= V_SDev/(sqrt(V_Npnts))
EndFor
SetScale /p x,DestWaveDimOffset,DestWaveDimDelta, w2,w3,w4,w5
KillWaves /z w1
End

Function pt_AverageWavesEasy() 
// This is always the latest version. 
// added capability to look for waves in subfolder. 10/10/13

// instead of appending "_Avg", just append "Avg" 30th Sept. 2007

// so far i was generating temporary wave with PntsPerBin*NumWaves for each point of the destination wave and averaging that. a much more simpler and 
// faster wave is first average all waves 1 pnt at a time and then coarse bin it because,
//	

// renamed version last modified on 03_22_2007 to pt_AverageWaves2() on 23rd, Sept. 2007.

// separated the finding of largest dimension as a separate function pt_MaxWDim  03_22_2007
// also added an DoAlert if we got an empty string 03_22_2007
// adding underscore to distinguish output of this version (modified 03_01_2007) from earlier version. Earlier version had problem if any wave was
// shorter than the longest wave. 
// pt_AverageWFrmFldrs was unnecessary. merged functionality with pt_AverageWaves (modified 03_02_2007)
// This function averages waves taken from the top window or matching a string. To calculate the final  average waves it  takes "PntsPerBin" 
// number of pnts from each wave for each pnt. Also dimensionality and scaling of final wave is set by longest wave

Variable DisplayAvg
String DataWaveMatchStr, DataFldrStr, BaseNameStr, ExcludeWNamesWStr

Variable NumPntsSrcWave, i, j, NumWaves, NumPntsW1, DeltaSrcWave, OffsetSrcWave, DestWaveDimOffset 
Variable DestWaveDimDelta, LongestWIndex, NPnts
String wavlist, WaveNameStr, OldDF
String LastUpdatedMM_DD_YYYY="09_30_2007"

Print "*********************************************************"
Print "pt_AverageWavesEasy last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_AverageWavesEasy"+"ParNamesW")

Wave /T AnalParW		=	$("root:FuncParWaves:pt_AverageWavesEasy"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AverageWavesEasyParW and/or pt_AverageWavesEasyParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
BaseNameStr			=	AnalParW[2]
//PntsPerBin				=	Str2Num(AnalParW[3])
ExcludeWNamesWStr	=	AnalParW[3]
DisplayAvg				=	Str2Num(AnalParW[4])

PrintAnalPar("pt_AverageWavesEasy")

OldDF = GetDataFolder(1)
SetDataFolder GetDataFolder(1)+DataFldrStr

If (StrLen(DataWaveMatchStr)==0)
wavlist = wavelist("*",";","WIN:")
Else
wavlist = wavelist(DataWaveMatchStr,";","")
EndIf
wavlist = pt_ExcludeFromWList(ExcludeWNamesWStr, wavlist)



NumWaves = ItemsInList(WavList,";")
If (!NumWaves>0)
Print "NumWaves <=0. No Waves to average!!"
Return -1
EndIf
print "Averaging waves...N=", NumWaves, wavlist

// Check all waves have same num of points and no NAN's
WaveNameStr= StringFromList (0,wavlist,";")
wave w = $WaveNameStr
NPnts= NumPnts(w)

// Check all waves have same num of points and no NAN's
For (i=0; i<NumWaves; i+=1)
	WaveNameStr= StringFromList (i,wavlist,";")
	
	 	if (strlen(WaveNameStr)== 0)
  			Print "While finding average of waves could not find wave #", i
  			DoAlert 0, "Exiting without finishing!!"
 			break
 		endif
	
	wave w = $WaveNameStr
	If (NumPnts(w) != NPnts)
		Print "NumPoints", WaveNameStr, "not equal to", NPnts
		DoAlert 0, "Use pt_AverageWaves instead!!"
 		Abort
	EndIf
	For (j=0; j<NPnts; j+=1)
		If (NumType(w(j)) != 0)
		Print "NumType",  WaveNameStr,"(",j,")  a normal-number'"
		DoAlert 0, "Waves contains a non-normal number. Use pt_AverageWaves instead!!"
 		Abort
	EndIf
	EndFor	
EndFor


Make /O/N=(NPnts) $(BaseNameStr+"Avg")
Wave w2= $(BaseNameStr+"Avg")
WaveNameStr= StringFromList (0,wavlist,";")
wave w = $WaveNameStr
SetScale /p x,DimOffset(w,0),DimDelta(w,0), w2
w2 = 0


	
For (i=0; i< NumWaves; i+=1)
	
		WaveNameStr= StringFromList (i,wavlist,";") 		
 		wave w = $WaveNameStr
		w2 +=w
EndFor

w2 /=NumWaves

If (DisplayAvg)
	Display
	DoWindow pt_AverageWavesEasyDisplay
	If (V_Flag)
		DoWindow /F pt_AverageWavesEasyDisplay
//		Sleep 00:00:02
		DoWindow /K pt_AverageWavesEasyDisplay
	EndIf
	DoWindow /C pt_AverageWavesEasyDisplay
	For (i=0; i< NumWaves; i+=1)
	
		WaveNameStr= StringFromList (i,wavlist,";")
//		if (strlen(WaveNameStr)== 0)
 //			break
 //		endif
 	 if (strlen(WaveNameStr)== 0)
  			Print "While finding average of waves could not find wave #", i
  			DoAlert 0, "Exiting without finishing!!"
 			break
 	endif	
 		
 	wave w = $WaveNameStr
 	AppendToGraph /W=pt_AverageWavesEasyDisplay w
 	ModifyGraph /W=pt_AverageWavesEasyDisplay mode=4
 	EndFor
 	AppendToGraph /W=pt_AverageWavesEasyDisplay w2
 	ModifyGraph rgb($(BaseNameStr+"Avg"))=(0,0,0)
	ModifyGraph /W=pt_AverageWavesEasyDisplay mode=4
	ModifyGraph /W=pt_AverageWavesEasyDisplay marker($(BaseNameStr+"Avg"))=41
	DoUpdate
	Sleep /T 30
EndIf
SetDataFolder OldDf
End


Function pt_AverageWaves() 
// This is always the latest version. 
// DataFldrStr was not actually being used. Allowed set that the data folder is temporariliy set to DataFldrstr and restored at the end

// abort if the waves do not have same x-scaling (offset, delta) as the calculation assumes that 11_20_2007
// separated the finding of largest dimension as a separate function pt_MaxWDim  03_22_2007
// also added an DoAlert if we got an empty string 03_22_2007
// adding underscore to distinguish output of this version (modified 03_01_2007) from earlier version. Earlier version had problem if any wave was
// shorter than the longest wave. 
// pt_AverageWFrmFldrs was unnecessary. merged functionality with pt_AverageWaves (modified 03_02_2007)
// This function averages waves taken from the top window or matching a string. To calculate the final  average waves it  takes "PntsPerBin" 
// number of pnts from each wave for each pnt. Also dimensionality and scaling of final wave is set by longest wave

Variable PntsPerBin, DisplayAvg
String DataWaveMatchStr, DataFldrStr, BaseNameStr, ExcludeWNamesWStr

Variable NumPntsSrcWave, NumpntsDestWave, i, j, NumWaves, NumPntsW1, DeltaSrcWave, OffsetSrcWave, DestWaveDimOffset 
Variable DestWaveDimDelta, LongestWIndex, SameScaling
String wavlist, WaveNameStr, OldDF
String LastUpdatedMM_DD_YYYY="11_20_2007"

Print "*********************************************************"
Print "pt_AverageWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_AverageWaves"+"ParNamesW")

Wave /T AnalParW		=	$("root:FuncParWaves:pt_AverageWaves"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AverageWavesParW and/or pt_AverageWavesParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
BaseNameStr			=	AnalParW[2]
PntsPerBin				=	Str2Num(AnalParW[3])
ExcludeWNamesWStr	=	AnalParW[4]
DisplayAvg				=	Str2Num(AnalParW[5])

PrintAnalPar("pt_AverageWaves")

OldDF = GetDataFolder(1)
SetDataFolder GetDataFolder(1)+DataFldrStr


If (StrLen(DataWaveMatchStr)==0)
wavlist = wavelist("*",";","WIN:")
Else
wavlist = wavelist(DataWaveMatchStr,";","")
EndIf
wavlist = pt_ExcludeFromWList(ExcludeWNamesWStr, wavlist)

NumWaves = ItemsInList(WavList,";")
If (!NumWaves>0)
Print "NumWaves <=0. No Waves to average!!"
Return -1
EndIf
print "Averaging waves...N=", NumWaves, wavlist



pt_MaxWDim(WavList, NumPntsSrcWave, LongestWIndex)	// wrote the max dimension as a separate function

SameScaling =0
pt_ChkXScaling(WavList, SameScaling)  // this averaging assumes x-scaling (offset, delta) is same for all waves 11_20_2007

If (!SameScaling)
	Abort "Waves do not have same scaling"
EndIf

//For (i=0; i<NumWaves; i+=1)				
// different waves can have different dimensions. find the maximum dimension.
										
//WaveNameStr= StringFromList (i,wavlist,";") 
//wave w = $WaveNameStr

//If (NumPntsSrcWave<NumPnts(w))
//	NumPntsSrcWave =NumPnts(w)
//	LongestWIndex=i	
//EndIf
//NumPntsSrcWave = (NumPntsSrcWave<NumPnts(w)) ?  NumPnts(w) : NumPntsSrcWave
//EndFor

// Calculate scaling (index value to x value) of final wave. Assuming all waves have same scaling and offset.
// We are taking PntsPerBin pnts at one time from each wave and averaging to get a point of final wave.


WaveNameStr= StringFromList (LongestWIndex,wavlist,";") 	// use longest wave to calculate scaling of final wave. 
wave w = $WaveNameStr

//DeltaSrcWave=DimDelta(w,0)				
//OffsetSrcWave=DimOffset(w,0)
// X value of first point of final wave will be equal to x value of first point of any wave + mean x value of PntsPerBin points. 
DestWaveDimOffset=DimOffset(w,0)+( ( (PntsPerBin-1) * DimDelta(w,0) )/2 )		
DestWaveDimDelta=DimDelta(w,0)*PntsPerBin

if (mod(NumPntsSrcWave,PntsPerBin)==0) // figure dimensionality of final wave
NumpntsDestWave=(NumPntsSrcWave/PntsPerBin)
else
NumpntsDestWave=(Ceil(NumPntsSrcWave/PntsPerBin)) 
Endif

//Make /O/N=(NumpntsDestWave) $(BaseNameString+"Avg"), $(BaseNameString+"SD"), $(BaseNameString+"Num"), $(BaseNameString+"SE")rs

Make /O/N=(NumpntsDestWave) $(BaseNameStr+"_Avg"), $(BaseNameStr+"_SD"), $(BaseNameStr+"_Num"), $(BaseNameStr+"_SE")

Wave w2= $(BaseNameStr+"_Avg")

Wave w3= $(BaseNameStr+"_SD")

Wave w4= $(BaseNameStr+"_Num")

Wave w5= $(BaseNameStr+"_SE")

For (j=0; j< NumpntsDestWave; j+=1)

	Make /O/N=0 w1
	Make /O/N=(PntsPerBin) w1Tmp
	
	For (i=0; i< NumWaves; i+=1)
	
		WaveNameStr= StringFromList (i,wavlist,";")
//		if (strlen(WaveNameStr)== 0)
//			break
//		endif
 		if (strlen(WaveNameStr)== 0)
  			Print "While finding average of waves could not find wave #", i
  			DoAlert 0, "Exiting without finishing!!"
 			break
 		endif
 		
 		wave w = $WaveNameStr

		w1Tmp[0,PntsPerBin-1]= (   (p+j*PntsPerBin) >  (NumPnts(w)-1)   ) ? Nan : w[p+j*PntsPerBin]
		Concatenate /NP {w1Tmp}, w1

	EndFor

		WaveStats /Q w1
		w2[j]= V_Avg
		w3[j]= V_SDev
		w4[j]= V_NPnts
		w5[j]= V_SDev/(sqrt(V_Npnts))
		KillWaves /Z w1, w1Tmp

EndFor

SetScale /p x,DestWaveDimOffset,DestWaveDimDelta, w2,w3,w4,w5
KillWaves /z w1
If (DisplayAvg)
	DoWindow pt_AverageWavesDisplay
	If (V_Flag)
		DoWindow /K pt_AverageWavesDisplay
	EndIf
	Display
	DoWindow /C pt_AverageWavesDisplay
	For (i=0; i< NumWaves; i+=1)
	
		WaveNameStr= StringFromList (i,wavlist,";")
//		if (strlen(WaveNameStr)== 0)
 //			break
 //		endif
 	 if (strlen(WaveNameStr)== 0)
  			Print "While finding average of waves could not find wave #", i
  			DoAlert 0, "Exiting without finishing!!"
 			break
 	endif	
 		
 	wave w = $WaveNameStr
 	AppendToGraph /W=pt_AverageWavesDisplay w
 	ModifyGraph /W=pt_AverageWavesDisplay mode=4
 	EndFor
 	AppendToGraph /W=pt_AverageWavesDisplay w2
 	ModifyGraph rgb($(BaseNameStr+"_Avg"))=(0,0,0)
	ModifyGraph /W=pt_AverageWavesDisplay mode=4
	ModifyGraph /W=pt_AverageWavesDisplay marker($(BaseNameStr+"_Avg"))=41
	DoUpdate /W = pt_AverageWavesDisplay	
	//Sleep 00:00:02
	Sleep /T 30
EndIf
DoWindow pt_AverageWavesDisplay		// kill the last display window 11_11/13
If (V_Flag)
	DoWindow /K pt_AverageWavesDisplay
EndIf
	


SetDataFolder OldDF
End

//***

//***

Function pt_AverageWavesVarPar1()
// wrapper for pt_AverageWaves. will run pt_AverageWaves with some parameters varied
String DataWaveMatchStrOld, BaseNameStrOld, DataWaveMatchStrList, BaseNameStrList
Variable NDataWaveMatchStrList, NBaseNameStrList, i
String LastUpdatedMM_DD_YYYY="08_05_2008"
Print "*********************************************************"
Print "pt_AverageWavesVarPar1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_AverageWaves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_AverageWaves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_AverageWavesParW and/or pt_AverageWavesParNamesW!!!"
EndIf


DataWaveMatchStrOld		=	AnalParW[0]	// count from zero
BaseNameStrOld				=	AnalParW[2]

//DataWaveMatchStrList   = "F_ISpkT000pA*ISI;F_ISpkT030pA*ISI;F_ISpkT060pA*ISI;"
//DataWaveMatchStrList += "F_ISpkT090pA*ISI;F_ISpkT120pA*ISI;F_ISpkT150pA*ISI;"
//DataWaveMatchStrList += "F_ISpkT180pA*ISI;F_ISpkT210pA*ISI;F_ISpkT240pA*ISI;"
//DataWaveMatchStrList += "F_ISpkT270pA*ISI;F_ISpkT300pA*ISI;F_ISpkT330pA*ISI;"
//DataWaveMatchStrList += "F_ISpkT360pA*ISI;F_ISpkT390pA*ISI;F_ISpkT420pA*ISI;"
//DataWaveMatchStrList += "F_ISpkT450pA*ISI;F_ISpkT480pA*ISI;F_ISpkT510pA*ISI;"
//DataWaveMatchStrList += "F_ISpkT540pA*ISI;F_ISpkT570pA*ISI;"



//BaseNameStrList  = "F_I000pAISI;F_I030pAISI;F_I060pAISI;"
//BaseNameStrList+= "F_I090pAISI;F_I120pAISI;F_I150pAISI;"
//BaseNameStrList+= "F_I180pAISI;F_I210pAISI;F_I240pAISI;"
//BaseNameStrList+= "F_I270pAISI;F_I300pAISI;F_I330pAISI;"
//BaseNameStrList+= "F_I360pAISI;F_I390pAISI;F_I420pAISI;"
//BaseNameStrList+= "F_I450pAISI;F_I480pAISI;F_I510pAISI;"
//BaseNameStrList+= "F_I540pAISI;F_I570pAISI;"

//DataWaveMatchStrList   = "F_IEOPAHPBL000pA*;F_IEOPAHPBL030pA*;F_IEOPAHPBL060pA*;"
//DataWaveMatchStrList += "F_IEOPAHPBL090pA*;F_IEOPAHPBL120pA*;F_IEOPAHPBL150pA*;"
//DataWaveMatchStrList += "F_IEOPAHPBL180pA*;F_IEOPAHPBL210pA*;F_IEOPAHPBL240pA*;"
//DataWaveMatchStrList += "F_IEOPAHPBL270pA*;F_IEOPAHPBL300pA*;F_IEOPAHPBL330pA*;"
//DataWaveMatchStrList += "F_IEOPAHPBL360pA*;F_IEOPAHPBL390pA*;F_IEOPAHPBL420pA*;"
//DataWaveMatchStrList += "F_IEOPAHPBL450pA*;F_IEOPAHPBL480pA*;F_IEOPAHPBL510pA*;"
//DataWaveMatchStrList += "F_IEOPAHPBL540pA*;F_IEOPAHPBL570pA*;"



//BaseNameStrList  = "F_I000pAEOPAHPBL;F_I030pAEOPAHPBL;F_I060pAEOPAHPBL;"
//BaseNameStrList+= "F_I090pAEOPAHPBL;F_I120pAEOPAHPBL;F_I150pAEOPAHPBL;"
//BaseNameStrList+= "F_I180pAEOPAHPBL;F_I210pAEOPAHPBL;F_I240pAEOPAHPBL;"
//BaseNameStrList+= "F_I270pAEOPAHPBL;F_I300pAEOPAHPBL;F_I330pAEOPAHPBL;"
//BaseNameStrList+= "F_I360pAEOPAHPBL;F_I390pAEOPAHPBL;F_I420pAEOPAHPBL;"
//BaseNameStrList+= "F_I450pAEOPAHPBL;F_I480pAEOPAHPBL;F_I510pAEOPAHPBL;"
//BaseNameStrList+= "F_I540pAEOPAHPBL;F_I570pAEOPAHPBL;"

DataWaveMatchStrList   = "F_IEOPAHPDrug000pA*;F_IEOPAHPDrug060pA*;"
DataWaveMatchStrList += "F_IEOPAHPDrug120pA*;"
DataWaveMatchStrList += "F_IEOPAHPDrug180pA*;F_IEOPAHPDrug240pA*;"
DataWaveMatchStrList += "F_IEOPAHPDrug300pA*;"
DataWaveMatchStrList += "F_IEOPAHPDrug360pA*;F_IEOPAHPDrug420pA*;"
DataWaveMatchStrList += "F_IEOPAHPDrug480pA*;"
DataWaveMatchStrList += "F_IEOPAHPDrug540pA*;"



BaseNameStrList  = "F_I000pAEOPAHPDrug;F_I060pAEOPAHPDrug;"
BaseNameStrList+= "F_I120pAEOPAHPDrug;"
BaseNameStrList+= "F_I180pAEOPAHPDrug;F_I240pAEOPAHPDrug;"
BaseNameStrList+= "F_I300pAEOPAHPDrug;"
BaseNameStrList+= "F_I360pAEOPAHPDrug;F_I420pAEOPAHPDrug;"
BaseNameStrList+= "F_I480pAEOPAHPDrug;"
BaseNameStrList+= "F_I540pAEOPAHPDrug;"

//DataWaveMatchStrList   = "F_IInstFrqA000pA*_NoOL;F_IInstFrqA030pA*_NoOL;F_IInstFrqA060pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqA090pA*_NoOL;F_IInstFrqA120pA*_NoOL;F_IInstFrqA150pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqA180pA*_NoOL;F_IInstFrqA210pA*_NoOL;F_IInstFrqA240pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqA270pA*_NoOL;F_IInstFrqA300pA*_NoOL;F_IInstFrqA330pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqA360pA*_NoOL;F_IInstFrqA390pA*_NoOL;F_IInstFrqA420pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqA450pA*_NoOL;F_IInstFrqA480pA*_NoOL;F_IInstFrqA510pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqA540pA*_NoOL;F_IInstFrqA570pA*_NoOL;"

//DataWaveMatchStrList   = "F_IInstFrqISI000pA*_NoOL;F_IInstFrqISI025pA*_NoOL;F_IInstFrqISI050pA*_NoOL;F_IInstFrqISI075pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI100pA*_NoOL;F_IInstFrqISI125pA*_NoOL;F_IInstFrqISI150pA*_NoOL;F_IInstFrqISI175pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI200pA*_NoOL;F_IInstFrqISI225pA*_NoOL;F_IInstFrqISI250pA*_NoOL;F_IInstFrqISI275pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI300pA*_NoOL;F_IInstFrqISI325pA*_NoOL;F_IInstFrqISI350pA*_NoOL;F_IInstFrqISI375pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI400pA*_NoOL;F_IInstFrqISI425pA*_NoOL;F_IInstFrqISI450pA*_NoOL;F_IInstFrqISI475pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI500pA*_NoOL;F_IInstFrqISI525pA*_NoOL;F_IInstFrqISI550pA*_NoOL;F_IInstFrqISI575pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI600pA*_NoOL;F_IInstFrqISI625pA*_NoOL;F_IInstFrqISI650pA*_NoOL;F_IInstFrqISI675pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI700pA*_NoOL;F_IInstFrqISI725pA*_NoOL;F_IInstFrqISI750pA*_NoOL;F_IInstFrqISI775pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI800pA*_NoOL;F_IInstFrqISI825pA*_NoOL;F_IInstFrqISI850pA*_NoOL;F_IInstFrqISI875pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI900pA*_NoOL;F_IInstFrqISI925pA*_NoOL;F_IInstFrqISI950pA*_NoOL;F_IInstFrqISI975pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqISI1000pA*_NoOL;F_IInstFrqISI1025pA*_NoOL;F_IInstFrqISI1050pA*_NoOL;F_IInstFrqISI1075pA*_NoOL;"

//BaseNameStrList  =		"F_I000pAInstFrqISI_NoOL;F_I025pAInstFrqISI_NoOL;F_I050pAInstFrqISI_NoOL;F_I075pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I100pAInstFrqISI_NoOL;F_I125pAInstFrqISI_NoOL;F_I150pAInstFrqISI_NoOL;F_I175pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I200pAInstFrqISI_NoOL;F_I225pAInstFrqISI_NoOL;F_I250pAInstFrqISI_NoOL;F_I275pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I300pAInstFrqISI_NoOL;F_I325pAInstFrqISI_NoOL;F_I350pAInstFrqISI_NoOL;F_I375pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I400pAInstFrqISI_NoOL;F_I425pAInstFrqISI_NoOL;F_I450pAInstFrqISI_NoOL;F_I475pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I500pAInstFrqISI_NoOL;F_I525pAInstFrqISI_NoOL;F_I550pAInstFrqISI_NoOL;F_I575pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I600pAInstFrqISI_NoOL;F_I625pAInstFrqISI_NoOL;F_I650pAInstFrqISI_NoOL;F_I675pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I700pAInstFrqISI_NoOL;F_I725pAInstFrqISI_NoOL;F_I750pAInstFrqISI_NoOL;F_I775pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I800pAInstFrqISI_NoOL;F_I825pAInstFrqISI_NoOL;F_I850pAInstFrqISI_NoOL;F_I875pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I900pAInstFrqISI_NoOL;F_I925pAInstFrqISI_NoOL;F_I950pAInstFrqISI_NoOL;F_I975pAInstFrqISI_NoOL;"
//BaseNameStrList+=		"F_I1000pAInstFrqISI_NoOL;F_I1025pAInstFrqISI_NoOL;F_I1050pAInstFrqISI_NoOL;F_I1075pAInstFrqISI_NoOL;"

//BaseNameStrList  = "F_I000pAInstFrqA_NoOL;F_I030pAInstFrqA_NoOL;F_I060pAInstFrqA_NoOL;"
//BaseNameStrList+= "F_I090pAInstFrqA_NoOL;F_I120pAInstFrqA_NoOL;F_I150pAInstFrqA_NoOL;"
//BaseNameStrList+= "F_I180pAInstFrqA_NoOL;F_I210pAInstFrqA_NoOL;F_I240pAInstFrqA_NoOL;"
//BaseNameStrList+= "F_I270pAInstFrqA_NoOL;F_I300pAInstFrqA_NoOL;F_I330pAInstFrqA_NoOL;"
//BaseNameStrList+= "F_I360pAInstFrqA_NoOL;F_I390pAInstFrqA_NoOL;F_I420pAInstFrqA_NoOL;"
//BaseNameStrList+= "F_I450pAInstFrqA_NoOL;F_I480pAInstFrqA_NoOL;F_I510pAInstFrqA_NoOL;"
//BaseNameStrList+= "F_I540pAInstFrqA_NoOL;F_I570pAInstFrqA_NoOL;"

//DataWaveMatchStrList   = "F_IInstFrqB600pA*_NoOL;F_IInstFrqB630pA*_NoOL;F_IInstFrqB660pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqB690pA*_NoOL;F_IInstFrqB720pA*_NoOL;F_IInstFrqB750pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqB780pA*_NoOL;F_IInstFrqB810pA*_NoOL;F_IInstFrqB840pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqB870pA*_NoOL;F_IInstFrqB900pA*_NoOL;F_IInstFrqB930pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqB960pA*_NoOL;F_IInstFrqB990pA*_NoOL;F_IInstFrqB1020pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqB1050pA*_NoOL;F_IInstFrqB1080pA*_NoOL;F_IInstFrqB1110pA*_NoOL;"
//DataWaveMatchStrList += "F_IInstFrqB1140pA*_NoOL;F_IInstFrqB1170pA*_NoOL;"



//BaseNameStrList  = "F_I600pAInstFrqB_NoOL;F_I630pAInstFrqB_NoOL;F_I660pAInstFrqB_NoOL;"
//BaseNameStrList+= "F_I690pAInstFrqB_NoOL;F_I720pAInstFrqB_NoOL;F_I750pAInstFrqB_NoOL;"
//BaseNameStrList+= "F_I780pAInstFrqB_NoOL;F_I810pAInstFrqB_NoOL;F_I840pAInstFrqB_NoOL;"
//BaseNameStrList+= "F_I870pAInstFrqB_NoOL;F_I900pAInstFrqB_NoOL;F_I930pAInstFrqB_NoOL;"
//BaseNameStrList+= "F_I960pAInstFrqB_NoOL;F_I990pAInstFrqB_NoOL;F_I1020pAInstFrqB_NoOL;"
//BaseNameStrList+= "F_I1050pAInstFrqB_NoOL;F_I1080pAInstFrqB_NoOL;F_I1110pAInstFrqB_NoOL;"
//BaseNameStrList+= "F_I1140pAInstFrqB_NoOL;F_I1170pAInstFrqB_NoOL;"

NDataWaveMatchStrList = ItemsInList(DataWaveMatchStrList, ";")
NBaseNameStrList = ItemsInList(BaseNameStrList, ";")

If (NDataWaveMatchStrList != NBaseNameStrList)
Abort "Unequal number of items in list of varied parameters"
EndIf

For (i=0; i<NDataWaveMatchStrList; i+=1)
AnalParW[0] = StringFromList(i,DataWaveMatchStrList, ";")
AnalParW[2] = StringFromList(i,BaseNameStrList, ";")
pt_AnalWInFldrs2("pt_AverageWaves")
EndFor

AnalParW[0] = DataWaveMatchStrOld
AnalParW[2] = BaseNameStrOld

End





Function pt_MaxWDim(WavList, MaxDim, LongestWIndex)
Variable &MaxDim, &LongestWIndex
String WavList

String WaveNameStr
Variable i, NumWaves

MaxDim=0
LongestWIndex=0

NumWaves = ItemsInList(WavList,";")

For (i=0; i<NumWaves; i+=1)				
// different waves can have different dimensions. find the maximum dimension.
										
WaveNameStr= StringFromList (i,wavlist,";") 
wave w = $WaveNameStr

If (MaxDim<NumPnts(w))
	MaxDim =NumPnts(w)
	LongestWIndex=i	
EndIf
//NumPntsSrcWave = (NumPntsSrcWave<NumPnts(w)) ?  NumPnts(w) : NumPntsSrcWave
EndFor
Return MaxDim
End


Function pt_ChkXScaling(WavList, SameScaling)
Variable &SameScaling
String WavList

String WaveNameStr
Variable i, NumWaves, X0, X0a, X1, X1a

NumWaves = ItemsInList(WavList,";")


WaveNameStr= StringFromList (0,wavlist,";")
wave w = $WaveNameStr
X0= DimOffset(w,0)
X1= DimDelta(w,0)

SameScaling = 1

For (i=1; i<NumWaves; i+=1)				
										
WaveNameStr= StringFromList (i,wavlist,";")
wave w = $WaveNameStr

X0a= DimOffset(w,0)
X1a= DimDelta(w,0)

If (	(X0a !=X0)	||   (X1a !=X1)   )

SameScaling = 0

Print "Wave", WaveNameStr, "has Offset, Delta =", X0a, X1a, "not equal to", X0, X1
Break
EndIf

EndFor

End


Function pt_BurstAnal()
// pt_SpikeAnal can be used to find subthreshold epsp bursts also. Need to smooth the trace first and then essentially find peak higher than an 
// absolute threshold and a relative threshold. This function is a wrapper for pt_SpikeAnal
//Variable NTimesSmooth
String WNameStr, WList, DataWaveMatchStr, DataFldrStr, BaseNameStr
String FreqCutOff, CutOffAmp, LowPassTrue
String StartX, EndX, SpikeAmpAbsThresh, SpikeAmpRelativeThresh, SpikePolarity, BoxSmoothingPnts, RefractoryPeriod
String SpikeThreshWin, SpikeThreshDerivLevel, BLPreDelT, Frac, EOPAHPDelT, PrePlsBLDelT, AlertMessages, SpikeThreshDblDeriv, ISVDelT
Variable x0, dx, x1, x2, SpikeThreshStartX, SpikeThreshEndX, BLStartX, BLEndX, SpikeAmpRelative, SpikeThreshCrossX
Variable i, Numwaves,FIData
String LastUpdatedMM_DD_YYYY="10_01_2010"
String KWDataWaveMatchStr, KWExcludeWList, KWSubFldr

Print "*********************************************************"
Print "pt_BurstAnal last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"
DoAlert 0, "pt_SpikeAnal used in this function uses crossing of SpikeThreshDerivLevel by 1st derivativel always"

Wave /T pt_BurstAnalParW=	$pt_GetParWave("pt_BurstAnal", "ParW")	// wasn't checking locally first. modified 08/21/2007
																		//	First check locally, then in FuncParWaves
PrintAnalPar("pt_BurstAnal")

Wave /T pt_GaussianFilterDataParW			=	$pt_GetParWave("pt_GaussianFilterData", "ParW")

DataWaveMatchStr 		= pt_GaussianFilterDataParW[0]
DataFldrStr				= pt_GaussianFilterDataParW[1]
FreqCutOff				= pt_GaussianFilterDataParW[2]
CutOffAmp				= pt_GaussianFilterDataParW[3]
LowPassTrue			= pt_GaussianFilterDataParW[4]
//DisplayResults		= pt_GaussianFilterDataParW[5]



pt_GaussianFilterDataParW[0] 	=	pt_BurstAnalParW[0]
pt_GaussianFilterDataParW[1]  =	pt_BurstAnalParW[1]
pt_GaussianFilterDataParW[2]  =	pt_BurstAnalParW[8]
pt_GaussianFilterDataParW[3]  =	pt_BurstAnalParW[9]
pt_GaussianFilterDataParW[4]  =	pt_BurstAnalParW[10]

pt_GaussianFilterData()

pt_GaussianFilterDataParW[0] 	=	DataWaveMatchStr
pt_GaussianFilterDataParW[1]  =	DataFldrStr
pt_GaussianFilterDataParW[2]  =	FreqCutOff
pt_GaussianFilterDataParW[3]  =	CutOffAmp
pt_GaussianFilterDataParW[4]  =	LowPassTrue


Wave /T pt_SpikeAnalParW			=	$pt_GetParWave("pt_SpikeAnal", "ParW")	// wasn't checking locally first. modified 08/21/2007
																		//	First check locally, then in FuncParWaves
//PrintAnalPar("pt_SpikeAnal")

DataWaveMatchStr		=	pt_SpikeAnalParW[0]
DataFldrStr				=	pt_SpikeAnalParW[1]
//StartX					=	pt_SpikeAnalParW[2]
//EndX					=	pt_SpikeAnalParW[3]
SpikeAmpAbsThresh		=	pt_SpikeAnalParW[4]
SpikeAmpRelativeThresh	=	pt_SpikeAnalParW[5]
//SpikePolarity				=	pt_SpikeAnalParW[6]
//BoxSmoothingPnts		=	pt_SpikeAnalParW[7]
RefractoryPeriod			=	pt_SpikeAnalParW[8]
SpikeThreshWin			=	pt_SpikeAnalParW[9]
//SpikeThreshDerivLevel		= 	pt_SpikeAnalParW[10]
//BLPreDelT				=	pt_SpikeAnalParW[11]
//If ( StrLen(pt_SpikeAnalParW[12])*StrLen(pt_SpikeAnalParW[13])!=0)
//	Wave /T FIWNamesW		=	$(GetDataFolder(-1)+DataFldrStr+":"+pt_SpikeAnalParW[12])		// removed ":" 04/23/2007
//	Wave /T FIWNamesW		=	$(GetDataFolder(-1)+DataFldrStr+pt_SpikeAnalParW[12])
//	Wave     FICurrWave		=	$(GetDataFolder(-1)+DataFldrStr+":"+pt_SpikeAnalParW[13])		// removed ":" 04/23/2007
//	Wave     FICurrWave		=	$(GetDataFolder(-1)+DataFldrStr+pt_SpikeAnalParW[13])	
//	FIData=1
//Else
//	FIData=0
//EndIf


BaseNameStr			=	pt_SpikeAnalParW[14]
//Frac					=	pt_SpikeAnalParW[15]
//EOPAHPDelT			=	pt_SpikeAnalParW[16]	// EndOfPulseAHPDelT
//PrePlsBLDelT			= 	pt_SpikeAnalParW[17]
//AlertMessages			=	pt_SpikeAnalParW[18]
SpikeThreshDblDeriv	=	pt_SpikeAnalParW[19]		// use double derivative to detect spike threshold instead of threshold crossing
														// of 1st derivative
//ISVDelT					= 	pt_SpikeAnalParW[20]




// Values to analyze bursts
//NTimesSmooth	= Str2Num(pt_BurstAnalParW[0])
//pt_SpikeAnalParW[0] 	= pt_BurstAnalParW[0]			//DataWaveMatchStr
pt_SpikeAnalParW[0] 	= "*_F"							//DataWaveMatchStr
pt_SpikeAnalParW[1]	= ""								//DataFldrStr
pt_SpikeAnalParW[4] 	= pt_BurstAnalParW[2]			//SpikeAmpAbsThresh
pt_SpikeAnalParW[5] 	= pt_BurstAnalParW[3]			//SpikeAmpRelativeThresh
pt_SpikeAnalParW[8] 	= pt_BurstAnalParW[4]			//RefractoryPeriod
pt_SpikeAnalParW[9] 	= pt_BurstAnalParW[5]			//SpikeThreshWin
pt_SpikeAnalParW[14] = pt_BurstAnalParW[6]			//BaseNameStr
pt_SpikeAnalParW[19] = pt_BurstAnalParW[7]			//SpikeThreshDblDeriv

//WList=pt_SortWavesInFolder(BurstAnalParW[0], GetDataFolder(-1)+DataFldrStr)
//Numwaves=ItemsInList(WList, ";")

//For (i=0;i<NumWaves;i+=1)
//	WNameStr=StringFromList(i, WList,";")
//	Wave w=$(GetDataFolder(-1)+DataFldrStr+WNameStr)
//	Smooth NTimesSmooth, w
//	pt_GaussianFilterData()
//EndFor


//pt_GaussianFilterData()
//Print "Gaussian filtered waves=", NumWaves
//Print "Now calling pt_SpikeAnal"

pt_SpikeAnal()

// Restore old values

pt_SpikeAnalParW[0] 	= DataWaveMatchStr
pt_SpikeAnalParW[1]	= DataFldrStr
pt_SpikeAnalParW[4] 	= SpikeAmpAbsThresh
pt_SpikeAnalParW[5] 	= SpikeAmpRelativeThresh
pt_SpikeAnalParW[8] 	= RefractoryPeriod
pt_SpikeAnalParW[9] 	= SpikeThreshWin
pt_SpikeAnalParW[14] 	= BaseNameStr
pt_SpikeAnalParW[19] 	= SpikeThreshDblDeriv

Wave /T pt_KillWFrmFldrsParW			=	$pt_GetParWave("pt_KillWFrmFldrs", "ParW")

KWDataWaveMatchStr = pt_KillWFrmFldrsParW[0]
KWExcludeWList         =  pt_KillWFrmFldrsParW[1]
KWSubFldr                  =  pt_KillWFrmFldrsParW[2]

pt_KillWFrmFldrsParW[0] = "*_F"
pt_KillWFrmFldrsParW[1] = ""
pt_KillWFrmFldrsParW[2] = ""

pt_KillWFrmFldrs()

pt_KillWFrmFldrsParW[0] = KWDataWaveMatchStr
pt_KillWFrmFldrsParW[1] = KWExcludeWList
pt_KillWFrmFldrsParW[2] = KWSubFldr

End


Function pt_BurstProb()
// Also see pt_BurstAnal() using pt_SpikeAnal()
String DataWaveMatchStr, DataFldrStr, OutWNameString
String 	 OldDF, WList, WNameStr
Variable MaxISIVal, NumWaves, N, i, j, BurstISINum, ISINum

Wave /T AnalParNamesW	=$("root:FuncParWaves:pt_BurstProb"+"ParNamesW")
Wave /T AnalParW		=$("root:FuncParWaves:pt_BurstProb"+"ParW")

If (WaveExists(AnalParNamesW)&&WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_BurstProbParW and/or pt_BurstProbParNamesW!!!"
EndIf

PrintAnalPar("pt_BurstProb")

DataWaveMatchStr	=		AnalParW[0]
OutWNameString	=		AnalParW[1]
MaxISIVal			= 		Str2Num(AnalParW[2])

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
NumWaves=	ItemsInList(WList,";")

Make /O/N=1	 		$(OutWNameString)
Wave BurstProbW	=	$(OutWNameString)

BurstISINum	=	0
ISINum		=	0

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList,";")
	Wave w=$WNameStr
	N=NumPnts(w)
	For (j=0; j<N; j+=1)
		If (w[j]<MaxISIVal)
			BurstISINum	+=	1
		EndIf
		ISINum +=1
	EndFor
EndFor
BurstProbW[0]=BurstISINum/ISINum

End


Function pt_AverageVals()
// modified to use subfolder in CurrentDataFolder 12_28_2010 
// Also if any wave has 0 points, then the Avg, SD, Num, SE = Nan. 	12_28_2010
// modified pt_AverageVals() so that the parameter wave can be chosen from current data folder before looking in root:FuncParWaves 12/19/2008
// Structure of pt_CalSlope() based on pt_AverageVals()
// This function is pretty similar to pt_CalBLAvg()
String DataWaveMatchStr, DataFldrStr, BaseNameString, SubFldr
Variable XStartVal, XEndVal

String 	 OldDF, WList, WNameStr
Variable NumWaves, i

// modified pt_AverageVals() so that the parameter wave can be chosen from current data folder before looking in root:FuncParWaves 12/19/2008

//Wave /T ParNamesW	=$("root:FuncParWaves:pt_AverageVals"+"ParNamesW")
//Wave /T ParW		=$("root:FuncParWaves:pt_AverageVals"+"ParW")

Wave /T ParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T ParW			=	$pt_GetParWave("pt_AverageVals", "ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AverageValsParW and/or pt_AverageValsParNamesW!!!"
EndIf

DataWaveMatchStr	=		ParW[0]
XStartVal			=Str2Num(ParW[1])
XEndVal				=Str2Num(ParW[2]) 
//DataFldrStr			=		ParW[3]		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
BaseNameString		=		ParW[3]
SubFldr				=		ParW[4]

PrintAnalPar("pt_AverageVals")

//OldDF=GetDataFolder(-1)		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
//SetDataFolder $DataFldrStr		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
NumWaves=	ItemsInList(WList,";")
print "Average Vals of waves...N=",NumWaves, WList

Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+BaseNameString+"Avg")
Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+BaseNameString+"SD")
Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+BaseNameString+"Num")
Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+BaseNameString+"SE")

Wave w1= $(GetDataFolder(1)+SubFldr+BaseNameString+"Avg")
Wave w2= $(GetDataFolder(1)+SubFldr+BaseNameString+"SD")
Wave w3= $(GetDataFolder(1)+SubFldr+BaseNameString+"Num")
Wave w4= $(GetDataFolder(1)+SubFldr+BaseNameString+"SE")

w1 = Nan
w2 = Nan
w3 = Nan
w4 = Nan

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList,";")
	Wave w=$(GetDataFolder(1)+SubFldr+WNameStr)
	XStartVal= (XStartVal<0)?	-inf : XStartVal
	XEndVal=   (XEndVal<0)?  inf : XEndVal
	If (NumPnts(w)>0)			//	12/28/2010
	WaveStats /Q /R=(XStartVal, XEndVal) w
	w1[i]=V_Avg
	w2[i]=V_SDev
	w3[i]=V_NPnts
	w4[i]=V_SDev/(sqrt(V_Npnts))
	EndIf
EndFor
//SetDataFolder OldDF	data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
End

//$$$$$$$$$$
Function pt_CalArea()
// based on pt_AverageVals()
// modified to use subfolder in CurrentDataFolder 12_28_2010 
// Also if any wave has 0 points, then the Avg, SD, Num, SE = Nan. 	12_28_2010
// modified pt_AverageVals() so that the parameter wave can be chosen from current data folder before looking in root:FuncParWaves 12/19/2008
// Structure of pt_CalSlope() based on pt_AverageVals()
// This function is pretty similar to pt_CalBLAvg()
String DataWaveMatchStr, DataFldrStr, BaseNameString, SubFldr
Variable XStartVal, XEndVal

String 	 OldDF, WList, WNameStr
String LastUpdatedMM_DD_YYYY="07_05_2013"

Variable NumWaves, i

// modified pt_AverageVals() so that the parameter wave can be chosen from current data folder before looking in root:FuncParWaves 12/19/2008

//Wave /T ParNamesW	=$("root:FuncParWaves:pt_CalArea"+"ParNamesW")
//Wave /T ParW		=$("root:FuncParWaves:pt_CalArea"+"ParW")

Wave /T ParNamesW		=	$pt_GetParWave("pt_CalArea", "ParNamesW")
Wave /T ParW			=	$pt_GetParWave("pt_CalArea", "ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_CalAreaParW and/or pt_CalAreaParNamesW!!!"
EndIf

Print "*********************************************************"
Print "pt_InsertPoints last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

DataWaveMatchStr	=		ParW[0]
XStartVal			=Str2Num(ParW[1])
XEndVal				=Str2Num(ParW[2]) 
//DataFldrStr			=		ParW[3]		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
BaseNameString		=		ParW[3]
SubFldr				=		ParW[4]

PrintAnalPar("pt_CalArea")

//OldDF=GetDataFolder(-1)		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
//SetDataFolder $DataFldrStr		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
NumWaves=	ItemsInList(WList,";")
print "Calculating area for waves...N=",NumWaves, WList

Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+BaseNameString+"Area")
Wave w1= $(GetDataFolder(1)+SubFldr+BaseNameString+"Area")


w1 = Nan

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList,";")
	Wave w=$(GetDataFolder(1)+SubFldr+WNameStr)
	XStartVal= (XStartVal<0)?	-inf : XStartVal
	XEndVal=   (XEndVal<0)?  inf : XEndVal
	If (NumPnts(w)>0)			//	12/28/2010
	WaveStats /Q /R=(XStartVal, XEndVal) w
	w1[i]=Area(w, XStartVal, XEndVal)
	EndIf
EndFor
//SetDataFolder OldDF	data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
End
//$$$$$$$$$$


Function pt_AverageValsVarPar1()
// wrapper to run pt_AverageVals with different parameters

String OldDataWaveMatchStr, OldBaseNameString, OldDataFolder, OldSubFldr

Wave /T ParNamesW	=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T ParW			=	$pt_GetParWave("pt_AverageVals", "ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AverageValsParW and/or pt_AverageValsParNamesW!!!"
EndIf

OldDataWaveMatchStr	=		ParW[0]
//XStartVal			=Str2Num(ParW[1])
//XEndVal				=Str2Num(ParW[2]) 
//DataFldrStr			=		ParW[3]		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
OldBaseNameString		=		ParW[3]
OldSubFldr				=		ParW[4]

OldDataFolder = GetDataFolder(1)

ParW[4] = ""

SetDataFolder root:Anal:mIPSC:Joint:ACSFIpsiContra
Print "Current Data Folder =", GetDataFolder(1)
ParW[0]	= "Cell_*RsVAvg"
ParW[3]		= "ACSFIpsiContraRsV"
pt_AverageVals()
ParW[0]	= "Cell_*RInVAvg"
ParW[3]		= "ACSFIpsiContraRInV"
pt_AverageVals()
ParW[0]	= "Cell_*CmVAvg"
ParW[3]		= "ACSFIpsiContraCmV"
pt_AverageVals()
ParW[0]	= "Cell_*mIPSCPkAmpRelW"
ParW[3]		= "ACSFIpsiContraRelPkAmp"
pt_AverageVals()
ParW[0]	= "Cell_*mIPSCInstFrq"
ParW[3]		= "ACSFIpsiContraPkInstFrq"
pt_AverageVals()
ParW[0]	= "Cell_*mIPSCTauD"
ParW[3]		= "ACSFIpsiContraTauD"
pt_AverageVals()

//SetDataFolder root:Anal:mIPSC:Joint:ACSFIpsi
//Print "Current Data Folder =", GetDataFolder(1)
//ParW[0]	= "Cell_*RsVAvg"
//ParW[3]		= "ACSFIpsiRsV"
//pt_AverageVals()
//ParW[0]	= "Cell_*RInVAvg"
//ParW[3]		= "ACSFIpsiRInV"
//pt_AverageVals()
//ParW[0]	= "Cell_*CmVAvg"
//ParW[3]		= "ACSFIpsiCmV"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCPkAmpRelW"
//ParW[3]		= "ACSFIpsiRelPkAmp"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCInstFrq"
//ParW[3]		= "ACSFIpsiPkInstFrq"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCTauD"
//ParW[3]		= "ACSFIpsiTauD"
//pt_AverageVals()

SetDataFolder root:Anal:mIPSC:Joint:TTXIpsiContra
Print "Current Data Folder =", GetDataFolder(1)
ParW[0]	= "Cell_*RsVAvg"
ParW[3]		= "TTXIpsiContraRsV"
pt_AverageVals()
ParW[0]	= "Cell_*RInVAvg"
ParW[3]		= "TTXIpsiContraRInV"
pt_AverageVals()
ParW[0]	= "Cell_*CmVAvg"
ParW[3]		= "TTXIpsiContraCmV"
pt_AverageVals()
ParW[0]	= "Cell_*mIPSCPkAmpRelW"
ParW[3]		= "TTXIpsiContraRelPkAmp"
pt_AverageVals()
ParW[0]	= "Cell_*mIPSCInstFrq"
ParW[3]		= "TTXIpsiContraPkInstFrq"
pt_AverageVals()
ParW[0]	= "Cell_*mIPSCTauD"
ParW[3]		= "TTXIpsiContraTauD"
pt_AverageVals()

//SetDataFolder root:Anal:mIPSC:Joint:TTXIpsi
//Print "Current Data Folder =", GetDataFolder(1)
//ParW[0]	= "Cell_*RsVAvg"
//ParW[3]		= "TTXIpsiRsV"
//pt_AverageVals()
//ParW[0]	= "Cell_*RInVAvg"
//ParW[3]		= "TTXIpsiRInV"
//pt_AverageVals()
//ParW[0]	= "Cell_*CmVAvg"
//ParW[3]		= "TTXIpsiCmV"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCPkAmpRelW"
//ParW[3]		= "TTXIpsiRelPkAmp"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCInstFrq"
//ParW[3]		= "TTXIpsiPkInstFrq"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCTauD"
//ParW[3]		= "TTXIpsiTauD"
//pt_AverageVals()

//SetDataFolder root:Anal:mIPSC:P24:Het
//Print "Current Data Folder =", GetDataFolder(1)
//ParW[0]	= "Cell_*RsVAvg"
//ParW[3]		= "P24HetRsV"
//pt_AverageVals()
//ParW[0]	= "Cell_*RInVAvg"
//ParW[3]		= "P24HetRInV"
//pt_AverageVals()
//ParW[0]	= "Cell_*CmVAvg"
//ParW[3]		= "P24HetCmV"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCFreqPksW"
//ParW[3]		= "P24HetAvgFrq"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCPkAmpRelW"
//ParW[3]		= "P24HetPkAmp"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCTauDAvg"
//ParW[3]		= "TTXIpsiTauD"
//pt_AverageVals()

//SetDataFolder root:Anal:mIPSC:P24:KO
//Print "Current Data Folder =", GetDataFolder(1)
//ParW[0]	= "Cell_*RsVAvg"
//ParW[3]		= "P24KORsV"
//pt_AverageVals()
//ParW[0]	= "Cell_*RInVAvg"
//ParW[3]		= "P24KORInV"
//pt_AverageVals()
//ParW[0]	= "Cell_*CmVAvg"
//ParW[3]		= "P24KOCmV"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCFreqPksW"
//ParW[3]		= "P24KOAvgFrq"
//pt_AverageVals()
//ParW[0]	= "Cell_*mIPSCPkAmpRelW"
//ParW[3]		= "P24KOPkAmp"
//pt_AverageVals()

ParW[0]		= OldDataWaveMatchStr
ParW[3]		= OldBaseNameString
ParW[4]		= OldSubFldr
SetDataFolder OldDataFolder

End

Function pt_WaveStatsVarPar1()
// Aim is to calculate wavestats (mostly to get Avg and SE) for some 1d waves in different folders and 
// store the Avg and SE in a specified folder (like stats folder)
// Last Updated 01/12/12

String DestFolder = "root:Anal:mIPSC:Joint:StatsCombined"	// Modify if needed
String ParName = "PkInstFrq"		// Modify if needed
Variable NDataWaves,i
String, WStr, DataWaveNameList

Make /O/N=0 $DestFolder+":"+ParName+"Avg"
Make /O/N=1 $DestFolder+":"+ParName+"AvgTmp"
Make /O/N=0 $DestFolder+":"+ParName+"SE"
Make /O/N=1 $DestFolder+":"+ParName+"SETmp"

Wave wAvg		= $DestFolder+":"+ParName+"Avg"
Wave wAvgTmp	= $DestFolder+":"+ParName+"AvgTmp"

Wave wSE		= $DestFolder+":"+ParName+"SE"
Wave wSETmp	= $DestFolder+":"+ParName+"SETmp"

WAvgTmp = Nan
WSETmp=Nan

DataWaveNameList = ""
//DataWaveNameList +="root:Anal:FI:Day1FS:Day1FSRInAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:FI:Day2FS:Day2FSRInAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:FI:Day3FS:Day3FSRInAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:FI:Day4FS:Day4FSRInAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:FI:Day5FS:Day5FSRInAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:FI:Day6FS:Day6FSRInAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:FI:Day7FS:Day7FSRInAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:FI:Day8FS:Day8FSRInAvg;"// Modify if needed

//DataWaveNameList +="root:Anal:SpontSpk:Day1FS:Day1FSSpontSpkFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontSpk:Day2FS:Day2FSSpontSpkFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontSpk:Day3FS:Day3FSSpontSpkFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontSpk:Day4FS:Day4FSSpontSpkFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontSpk:Day5FS:Day5FSSpontSpkFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontSpk:Day6FS:Day6FSSpontSpkFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontSpk:Day7FS:Day7FSSpontSpkFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontSpk:Day8FS:Day8FSSpontSpkFrqAvg;"// Modify if needed

//DataWaveNameList +="root:Anal:SpontBurst:Day1FS:Day1FSSpontBurstFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontBurst:Day2FS:Day2FSSpontBurstFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontBurst:Day3FS:Day3FSSpontBurstFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontBurst:Day4FS:Day4FSSpontBurstFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontBurst:Day5FS:Day5FSSpontBurstFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontBurst:Day6FS:Day6FSSpontBurstFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontBurst:Day7FS:Day7FSSpontBurstFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:SpontBurst:Day8FS:Day8FSSpontBurstFrqAvg;"// Modify if needed

DataWaveNameList +="root:Anal:mIPSC:Joint:ACSFIpsiContra:ACSFIpsiContraPkInstFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:mIPSC:Joint:ACSFIpsi:ACSFIpsiPkInstFrqAvg;"// Modify if needed
DataWaveNameList +="root:Anal:mIPSC:Joint:TTXIpsiContra:TTXIpsiContraPkInstFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:mIPSC:Joint:TTXIpsi:TTXIpsiPkInstFrqAvg;"// Modify if needed

//DataWaveNameList +="root:Anal:mIPSC:P14:Het:P14HetAvgFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:mIPSC:P14:KO:P14KOAvgFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:mIPSC:P24:Het:P24HetAvgFrqAvg;"// Modify if needed
//DataWaveNameList +="root:Anal:mIPSC:P24:KO:P24KOAvgFrqAvg;"// Modify if needed

NDataWaves = ItemsInList(DataWaveNameList)

Print "DestFolder, ParName", DestFolder, ParName
Print "NumWaves =", NDataWaves, DataWaveNameList

For (i=0; i<NDataWaves; i+=1)
WStr= StringFromList(i, DataWaveNameList, ";")
If (WaveExists($WStr))
Print "                          "
Print WStr
WaveStats $WStr
wAvgTmp[0]=V_Avg
wSETmp[0] =V_SEM
Else
Print "                          "
Print "Wave doesn't exist!"
EndIf
Concatenate /NP {wAvgTmp}, wAvg
Concatenate /NP {wSETmp}, wSE
wAvgTmp[0]=Nan
wSETmp[0] =Nan
EndFor
KillWaves /Z WAvgTmp, WSETmp

End


Function pt_CalSlope()
// Structure of pt_CalSlope() based on pt_AverageVals()		

String DataWaveMatchStr, DataFldrStr, BaseNameString
Variable StartPnt, EndPnt, DelX

String 	 OldDF, WList, WNameStr
Variable NumWaves, i

Wave /T ParNamesW	=$("root:FuncParWaves:pt_CalSlope"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_CalSlope"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_CalSlopeParW and/or pt_CalSlopeParNamesW!!!"
EndIf

DataWaveMatchStr	=		ParW[0]
StartPnt				=Str2Num(ParW[1])
EndPnt				=Str2Num(ParW[2])
DelX				=Str2Num(ParW[3])
//DataFldrStr			=		ParW[3]		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
BaseNameString		=		ParW[4]

PrintAnalPar("pt_CalSlope")
//OldDF=GetDataFolder(-1)		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
//SetDataFolder $DataFldrStr		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
NumWaves=	ItemsInList(WList,";")
print "Calculating slopes of waves...N=",NumWaves, WList

Make /O/N=(NumWaves) $(BaseNameString+"Slp")
Wave w1= $(BaseNameString+"Slp")

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList,";")
	Wave w=$WNameStr
	w1[i]= ( w[EndPnt]-w[StartPnt] )/(DelX)
EndFor
//SetDataFolder OldDF	data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
End

//Function pt_CalStatPearsonTest()		// StatsLinearCorrelationTest replaces StatPearsonTest in Igor 6

//String Wave1WName, Wave2WName, OutWBaseName

//Wave /T ParNamesW	=$("root:FuncParWaves:pt_CalStatPearsonTest"+"ParNamesW")
//Wave /T ParW		=$("root:FuncParWaves:pt_CalStatPearsonTest"+"ParW")

//If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
//	Abort	"Cudn't find the parameter waves  pt_CalStatPearsonTestParW and/or pt_CalStatPearsonTestParNamesW!!!"
//EndIf

//Wave1WName	=		ParW[0]
//Wave2WName	=		ParW[1]
//OutWBaseName	=		ParW[2]

//PrintAnalPar("pt_CalStatPearsonTest")

//Wave w1 = $(Wave1WName)
//Wave w2 = $(Wave2WName)

//print "Calculating StatPearson correlation for waves...",Wave1WName, Wave2WName

//Make /O/N=(3) $(OutWBaseName+"Corr")
//Wave w3= $(OutWBaseName+"Corr")

//Print StatPearsonTest(w1, w2, w3)

//End


Function pt_StatsLnrC()

// This is always the latest version.


String LastUpdatedMM_DD_YYYY="08_02_2007"

Print "*********************************************************"
Print "pt_StatsLnrC last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


String Wave1WName, Wave2WName, OutWBaseName

Wave /T ParNamesW	=$("root:FuncParWaves:pt_StatsLnrC"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_StatsLnrC"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_StatsLnrCParW and/or pt_StatsLnrCParNamesW!!!"
EndIf

Wave1WName	=		ParW[0]
Wave2WName	=		ParW[1]
OutWBaseName	=		ParW[2]

PrintAnalPar("pt_StatsLnrC")

Wave w1 = $(Wave1WName)
Wave w2 = $(Wave2WName)

print "Calculating Linear correlation coeff. for waves...",Wave1WName, Wave2WName

//Make /O/N=(3) $(OutWBaseName+"LnrC")
//Wave w3= $(OutWBaseName+"LnrC")

StatsLinearCorrelationTest w1, w2
Duplicate /O W_StatsLinearCorrelationTest $(OutWBaseName+"LnrC")
Wave WStatsLnrC, W_StatsLinearCorrelationTest

Print WStatsLnrC

Killwaves W_StatsLinearCorrelationTest

End





Function pt_DisplayDataEvoked(PreCellNumString,PostCellNumString, PairName, ExptDateStr)
// Example: pt_DisplayDataEvoked("Cell_001310","Cell_001308", "Cell1310To1308", "05/24/2004")
String PreCellNumString,PostCellNumString, PairName, ExptDateStr
String tileCommand="Tile /A=(4,0)/O=1 EpspGraph,VmGraph, RseriesGraph, RInputGraph", AnalDateString
Wave RInputPreWave=$(PreCellNumString+"_Seal")
Wave RInputPostWave=$(PostCellNumString+"_Seal")
Wave VmPreWave=$(PreCellNumString+"_Vm")
Wave VmPostWaveCal=$(PostCellNumString+"_VmCal")
Wave VmPostWave=$(PostCellNumString+"_Vm")
//Wave Epsp1Wave=$(PostCellNumString+"_Epsp_0001")
//Wave Epsp2Wave=$(PostCellNumString+"_Epsp_0002")
Wave Epsp1Wave=$(PairName+"Epsc1")
Wave Epsp2Wave=$(PairName+"Epsc2")
Duplicate /o Epsp2Wave, $(PairName+"PPR2By1")
Wave PPRWave=$(PairName+"PPR2By1")
//PPRWave /= Epsp1Wave
PPRWave = 1-(Epsp2Wave/Epsp1Wave)

Display PreRSeriesWave, PostRseriesWave vs TimeAxisWave
DoWindow /C RseriesGraph
Display RInputPreWave,RinputPostWave vs TimeAxisWave
DoWindow /C RInputGraph
Display Epsp1Wave, Epsp2Wave vs TimeAxisWave
DoWindow /C EpspGraph
AppendToGraph /R PPRWave vs TimeAxisWave
Display VmPreWave, VmPostWaveCal vs TimeAxisWave
DoWindow /C VmGraph
AppendToGraph /R VmPostWave vs TimeAxisWave

ModifyGraph /W=RseriesGraph lstyle(PreRSeriesWave)=0,RGB(PreRSeriesWave)=(0,0,0);DelayUpdate
ModifyGraph /W=RseriesGraph lstyle(PostRSeriesWave)=3,RGB(PostRSeriesWave)=(0,0,0);DelayUpdate
Label  /W=RseriesGraph left "Rs (MOhms)";DelayUpdate
Label  /W=RseriesGraph bottom "Time (mins)";DelayUpdate
Legend  /W=RseriesGraph /F=0/C/N=Legend1/A=LB
SetAxis /W=RseriesGraph left 0,50e6

ModifyGraph /W=RInputGraph lstyle($(PreCellNumString+"_Seal"))=0,RGB($(PreCellNumString+"_Seal"))=(0,0,0);DelayUpdate
ModifyGraph /W=RInputGraph lstyle($(PostCellNumString+"_Seal"))=3,RGB($(PostCellNumString+"_Seal"))=(0,0,0);DelayUpdate
Label  /W=RInputGraph left "Rin (MOhms)";DelayUpdate
Label  /W=RInputGraph bottom "Time (mins)";DelayUpdate
Legend  /W=RInputGraph /F=0/C/N=Legend1/A=LB
SetAxis /W=RInputGraph left 0,500e6

ModifyGraph /W=VmGraph lstyle($(PreCellNumString+"_Vm"))=0, RGB($(PreCellNumString+"_Vm"))=(0,0,0);DelayUpdate
ModifyGraph /W=VmGraph lstyle($(PostCellNumString+"_VmCal"))=2, RGB($(PostCellNumString+"_VmCal"))=(0,0,0);DelayUpdate
ModifyGraph /W=VmGraph lstyle($(PostCellNumString+"_Vm"))=3,RGB($(PostCellNumString+"_Vm"))=(0,0,0);DelayUpdate
Label  /W=VmGraph left "Vm (V)";DelayUpdate
Label  /W=VmGraph right "Im (A)";DelayUpdate
Label  /W=VmGraph bottom "Time (mins)";DelayUpdate
Legend  /W=VmGraph /F=0/C/N=Legend1/A=LB
//SetAxis /W=VmGraph left -100e-3,-50e-3



ModifyGraph /W=EpspGraph lstyle($(PairName+"Epsc1"))=0, RGB($(PairName+"Epsc1"))=(0,0,0);DelayUpdate
ModifyGraph /W=EpspGraph lstyle($(PairName+"Epsc2"))=3, RGB($(PairName+"Epsc2"))=(0,0,0);DelayUpdate
ModifyGraph /W=EpspGraph lstyle($(PairName+"PPR2By1"))=6    , RGB($(PairName+"PPR2By1"))=(0,0,0);DelayUpdate
Label  /W=EpspGraph left "Epsp or Epsc (V or A)";DelayUpdate
Label  /W=EpspGraph Right "PPR2By1";DelayUpdate
SetAxis /W=EpspGraph Right 0,2
Label  /W=EpspGraph bottom "Time (mins)";DelayUpdate
Legend  /W=EpspGraph /F=0/C/N=Legend1/A=RB
//SetAxis /W=EpspGraph left 0,3e-3


NewLayout 
DoWindow /C Layout0

AppendLayoutObject /W=Layout0 Graph EpspGraph
AppendLayoutObject /W=Layout0 Graph RseriesGraph
AppendLayoutObject /W=Layout0 Graph RInputGraph
AppendLayoutObject /W=Layout0 Graph VmGraph

Execute /Q tileCommand

SetDrawEnv fsize= 10
DrawText /W=Layout0 175,90,"Pre"
SetDrawEnv fsize= 10
DrawText /W=Layout0 195,90,PreCellNumString

SetDrawEnv fsize= 10
DrawText /W=Layout0 175,100,"Post"
SetDrawEnv fsize= 10
DrawText /W=Layout0 195,100,PostCellNumString

SetDrawEnv fsize= 10
DrawText 265,90,"Exp. Date= " + ExptDateStr
AnalDateString = Date()
SetDrawEnv fsize= 10
DrawText 265,100, "Anal. Date= " + AnalDateString

//SetDrawEnv fsize= 20
//DrawText 95,135,"Vm(start)="
//SetDrawEnv fsize= 20
//DrawText 250,135,"Vm(end)="
SetDrawEnv fsize= 10
DrawText 400,90,"other info="
return 1
end

Function pt_DisplayDataMini(CellName)
String CellName
String tileCommand="Tile /A=(4,0)/O=1 Num_MiniGraph,RsGraph, RInGraph, CmGraph, ImVmAvgGraph"
// Example: pt_DisplayDataMini("ptCell654")

Display num_mini
DoWindow /C Num_MiniGraph
Display RsVW
DoWindow /C RsGraph
Display RInVW
DoWindow /C RInGraph
Display CmVW
DoWindow /C CmGraph
Display ImVmAvg
DoWindow /C ImVmAvgGraph

ModifyGraph /W=Num_MiniGraph lstyle(num_mini)=0,RGB(num_mini)=(0,0,0);DelayUpdate
Label  /W=Num_MiniGraph left "MiniFreq (Htz)";DelayUpdate
Label  /W=Num_MiniGraph bottom "Time (Units of 40 Secs)";DelayUpdate
Legend  /W=Num_MiniGraph /F=0/C/N=Legend1/A=LB
//SetAxis /W=Num_MiniGraph left 10e6,40e6

ModifyGraph /W=RsGraph lstyle(RsVW)=0,RGB(RsVW)=(0,0,0);DelayUpdate
Label  /W=RsGraph left "Rs (MOhms)";DelayUpdate
Label  /W=RsGraph bottom "Time (Units of 40 Secs)";DelayUpdate
Legend  /W=RsGraph /F=0/C/N=Legend1/A=LB
//SetAxis /W=RseriesGraph left 10e6,40e6

ModifyGraph /W=RInGraph lstyle(RInVW)=0,RGB(RInVW)=(0,0,0);DelayUpdate
Label  /W=RInGraph left "Rin (MOhms)";DelayUpdate
Label  /W=RInGraph bottom "Time (Units of 40 Secs)";DelayUpdate
Legend  /W=RInGraph /F=0/C/N=Legend1/A=LB
//SetAxis /W=RInGraph left 10e6,40e6

ModifyGraph /W=CmGraph lstyle(CmVW)=0,RGB(CmVW)=(0,0,0);DelayUpdate
Label  /W=CmGraph left "Cm (MOhms)";DelayUpdate
Label  /W=CmGraph bottom "Time (Units of 40 Secs)";DelayUpdate
Legend  /W=CmGraph /F=0/C/N=Legend1/A=LB
//SetAxis /W=CmGraph left 10e6,40e6

ModifyGraph /W=ImVmAvgGraph lstyle(ImVmAvg)=0,RGB(ImVmAvg)=(0,0,0);DelayUpdate
Label  /W=ImVmAvgGraph left "ImVmAvg (pA)";DelayUpdate
Label  /W=ImVmAvgGraph bottom "Time (Units of 40 Secs)";DelayUpdate
Legend  /W=ImVmAvgGraph /F=0/C/N=Legend1/A=LB
//SetAxis /W=ImVmAvgGraph left 10e6,40e6


NewLayout 
DoWindow /C $(CellName)

AppendLayoutObject /W=$(CellName) Graph Num_MiniGraph
AppendLayoutObject /W=$(CellName) Graph RsGraph
AppendLayoutObject /W=$(CellName) Graph RinGraph
AppendLayoutObject /W=$(CellName) Graph CmGraph
AppendLayoutObject /W=$(CellName) Graph ImVmAvgGraph
Execute /Q "Tile"

SetDrawEnv fsize= 15
DrawText 95,600,"Date"
SetDrawEnv fsize= 15
DrawText 95,620, "CellName"
SetDrawEnv fsize= 15
DrawText 185,620, CellName
SetDrawEnv fsize= 15
DrawText 95,640,"Vm(start)"
SetDrawEnv fsize= 15
DrawText 95,660,"Vm(end)"
SetDrawEnv fsize= 15
DrawText 95,680,"other info"

PrintLayOut $(CellName)

DoWindow /K Num_MiniGraph
DoWindow /K RsGraph
DoWindow /K RInGraph
DoWindow /K CmGraph
DoWindow /K ImVmAvgGraph
DoWindow /K $(CellName)
return 1
end

Function pt_LayOutsFrmFldrs()
String	WListStr
String WNameStr, FldrNameStr, LayoutWinName, WindowName, TextStr, WListTmp, WListFull
Variable i, NumWaves, PrintAndKill, NumWavesTmp, j

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_LayOutsFrmFldrs"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_LayOutsFrmFldrs"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_LayOutsFrmFldrs!!!"
EndIf
FldrNameStr = GetDataFolder(0)
LayoutWinName =	FldrNameStr + "TmpLayout"

PrintAnalPar("pt_LayOutsFrmFldrs")

WListStr					=	AnalParW[0]
PrintAndKill				=	Str2Num(AnalParW[1])

WListTmp = ""
WListFull = ""
NumWaves=ItemsInList(WListStr)

// Incorporating WildCards in StringList

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringfromList(i,WListStr, ";")
	If (StrSearch(WNameStr, "*", 0) != -1)
		WListTmp=pt_SortWavesInFolder(WNameStr, GetDataFolder(-1))
		WListFull	=	AddListItem(WListTmp, WListFull, ";", inf)	
	Else
		WListFull = AddListItem(WNameStr, WListFull, ";", inf)	
	EndIf
EndFor	

WListStr		=	WListFull
NumWaves=ItemsInList(WListStr)
Print "Creating layout for waves, N =", NumWaves, WListStr


NewLayout 
DoWindow /C $(LayoutWinName)

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringfromList(i,WListStr, ";")
	If (Strlen(WNameStr)!=0 && WaveExists($WNameStr))
		Wave w= $WNameStr
		Display w
		WindowName = LayoutWinName+"Graph"+Num2Str(i)
		DoWindow /C $WindowName
		Legend/C/N=text0/J/F=0/H={0,0,0} "\\Z06\\s("+WNameStr+") "+WNameStr
		ModifyGraph /W=$WindowName rgb=(0,0,0)
		ModifyGraph /W=$WindowName mode=4		//08/20/2008
		AppendLayoutObject /W=$(LayoutWinName) Graph $WindowName
//	Execute /Q tileCommand 
		Execute "Tile"
	EndIf
EndFor	

TextStr="AnalDate = "+Date()
SetDrawEnv /W=$(LayoutWinName) fsize= 13
DrawText /W=$(LayoutWinName) 350,650, TextStr
SetDrawEnv /W=$(LayoutWinName) fsize= 13
DrawText /W=$(LayoutWinName) 350,670, FldrNameStr

If (PrintAndKill)
	PrintLayOut $(LayoutWinName) 
	For (i=0; i<NumWaves; i+=1)
		WindowName = LayoutWinName+"Graph"+Num2Str(i)
		DoWindow $WindowName
		If (V_flag)
			DoWindow /K $WindowName
		EndIf	
	EndFor
	KillWindow $LayoutWinName
EndIf
End


Function pt_ChangeAquisMode(Device, Port, Line, LineDirection, LineState)

// Usage Example: pt_ChangeMode(1,0,0,1,1)
//				  pt_ChangeMode(1,0,0,1,0)

// This Function changes the mode (Line State = high for VClamp & Low for I clamp) of the Multiclamp 700 A
//  The Ext. box (next to V mode, I mode) in Multi Clamp Software should be checked. 
// 01/01/04 (praveen taneja)

Variable device,Port, Line, LineDirection, LineState

//fNIDAQ_DIG_Line_Config( Device, Port, Line, LineDirection)
//fNIDAQ_DIG_Out_Line( Device, Port, Line, LineState)

End

Function pt_RenameWaves()

// This is always the latest version
// modified pt_RenameWaves() so that only waves that have the old string are renamed (not all the wavenames that are tested)
// correspondingly the print message are the waves whose names contained the OldStr	22nd Dec. 2008

String DataWaveMatchStr, OldStr, NewStr

String  WList, WNameStr, WNameStrNew, RenamedWList

Variable Numwaves, i 

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_RenameWaves"+"ParNamesW")

Wave /T AnalParW		=	$("root:FuncParWaves:pt_RenameWaves"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_RenameWaves and/or pt_RenameWavesParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
OldStr					=	AnalParW[1]
NewStr					=	AnalParW[2]


PrintAnalPar("pt_RenameWaves")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")
RenamedWList =""

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$WNameStr
// modified pt_RenameWaves() so that only waves that have the old string are renamed (not all the wavenames that are tested)
// correspondingly the print message are the waves whose names contained the OldStr	22nd Dec. 2008	
	WNameStrNew=ReplaceString(OldStr, WNameStr, NewStr)
	If (StringMatch(WNameStrNew, WNameStr)==0)
		Rename w, $WNameStrNew
		RenamedWList +=WNameStr+";"
	EndIf
EndFor
Print "Renamed N=",ItemsInList(RenamedWList),"waves",RenamedWList
End

Function pt_RepTxtInW()

// This is always the latest version.
// modified from pt_RenameWaves() so that instead of changing names of waves, text inside each wave can be renamed/replaced


String DataWaveMatchStr, OldStr, NewStr

String  WList, WNameStr, WNameStrNew, RenamedWList, NewStr0

Variable Numwaves, i, NPnts, j ,NumReplaced 

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_RepTxtInW"+"ParNamesW")

Wave /T AnalParW		=	$("root:FuncParWaves:pt_RepTxtInW"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves pt_RepTxtInW and/or pt_RepTxtInWParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
OldStr					=	AnalParW[1]
NewStr					=	AnalParW[2]


PrintAnalPar("pt_RepTxtInW")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")
RenamedWList =""

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave /T w=$WNameStr
	NPnts = NumPnts(w)
	NumReplaced = 0
	For (j = 0; j < NPnts; j += 1)
		NewStr0 = ReplaceString(OldStr, w[ j ], NewStr)
		If (!StringMatch(NewStr0, w[ j ]))
			NumReplaced += 1
			w[ j ] = NewStr0
		EndIf
	EndFor
	Print "Replaced", OldStr, "with", NewStr, "in", NumReplaced, "instances", "in", WNameStr
EndFor
End



Function pt_RenameWaves1(BaseName, WaveSuffixString, OrigWavesFolder, NewWavesFolder, MultiplyBy, YUnitsString, WaveStartNum, WaveEndNum)
// Example Usage: pt_RenameWaves("Cell_000654_","ToNeg90;RsRinCm;AcqNeg90;ToNeg70","D:users:taneja:data:Temp","D:users:taneja:data:ptCell654",1e12,pA, 1,203)
String BaseName, WaveSuffixString, OrigWavesFolder, NewWavesFolder,YUnitsString
Variable MultiplyBy,WaveStartNum,WaveEndNum
String  OldWaveName, NewWaveName,WavStr, SaveNewWaveAs
Variable i, NumSuffixes, SuffixNum,Ndig=4


NewDataFolder /O/S root:TempRenameWavesFolder
NumSuffixes = ItemsInList(WaveSuffixString)

	For (i=WaveStartNum;i<=WaveEndNum;i+=1)
//		OldWaveName =BaseName+num2istr(i)
		OldWaveName =BaseName+num2digstrCopy(NDig,i)
		SuffixNum = Mod((i-WaveStartNum),NumSuffixes)

//		If (SuffixNum==0)
//		SuffixNum=NumSuffixes
//		Endif
 		
 		WavStr=StringFromList(SuffixNum,WaveSuffixString,";")
		NewWaveName=OldWaveName +"_"+WavStr
		Wave NewWaveNamePtr = $(NewWaveName)
		LoadData /Q/O/D/J=OldWaveName/L=1 OrigWavesFolder
		Duplicate /O $(OldWavename), $(NewWaveName)
		Wave NewWaveNamePtr = $(NewWaveName)
		NewWaveNamePtr *=MultiplyBy
		SetScale d,0,0,YUnitsString,NewWaveNamePtr			
		SaveNewWaveAs=NewWavesFolder + ":"+NewWaveName+".bwav"
		Save /O $(NewWaveName) as SaveNewWaveAs
		KillWaves /A/Z
	EndFor
	Print "Multiplied y-axis values by ",MultiplyBy, "and changed the unit to ",YUnitsString
	
Return 1
End

Function pt_DisplayDataStacked(HDFolderName, SearchStringName, X1,X2,Y1,Y2, XShift,YShift)
// Example Usage: pt_DisplayDataStacked("D:users:taneja:data1:PresynapticNmda:NmdaEvoked:04_20_2004 Folder","Cell_000856_*",2.4,2.6,-100e-12,50e-12,.002,30e-12)
String HDFolderName, SearchStringName
Variable X1,X2,Y1,Y2, XShift,YShift
String OldDataFolder, ListString, WaveStr, ShiftedWaveName, HDFolderNameString
Variable	i, j, NumWaves, XOffset, XDelta, YOffset, YDelta

	OldDataFolder = GetDataFolder(1)
	NewDataFolder /O/S TempDisplayStackedFolder
	LoadData /Q/O/D/L=1 HDFolderName
	ListString= WaveList(SearchStringName, ";", "")
	NumWaves = ItemsinList(ListString)
			j=0
			For (i=0; i< NumWaves; i+=1)
				WaveStr = StringFromList(i, ListString, ";")
				Wave Wav = $(WaveStr)
//				ShiftedWaveName = WaveStr + "_Shft"
//				Duplicate 
//				Wave WavShifted=$(ShiftedWaveName)
				Duplicate /O Wav, $( WaveStr + "_S")
				Wave WavShifted = $( WaveStr + "_S")
				If (j==0)
					Display WavShifted
//					HDFolderNameString = $(HDFolderName)
					DoWindow /C HDFolderName
					SetAxis /W=HDFolderName Bottom X1, (X2 + NumWaves*XShift)
					SetAxis /W=HDFolderName Left Y1, (Y2 + NumWaves*YShift)
//					SetAxis /W=HDFolderName Bottom X1, X2
//					SetAxis /W=HDFolderName Left Y1, Y2
					j+=1
				Else
					WavShifted += j*YShift
					XOffset 	= 	DimOffset(WavShifted,0)
//					YOffset 	= 	DimOffset(WavShifted,1)
					XDelta   	=  	DimDelta(WavShifted,0)
//					YDelta   =  	DimDelta(WavShifted,1)
					XOffset += j*XShift
//					YOffset += j*YShift
					SetScale /P x, XOffset, XDelta, WavShifted
//					SetScale /P y, YOffset, YDelta, WavShifted
					AppendToGraph /W=HDFolderName WavShifted
					j+=1
				EndIf
				
			EndFor
	SetDataFolder  OldDataFolder		
Return 1
End

// This function loads waves from "WavesFolder" and calculates average value over time (TEnd-TStart) in secs. In between 2 waves that it selects it skips SkipNumWaves.
Function pt_ImVm(CellName, BaseSuffixName, WavesFolder, TStartVal, TEndVal, WaveStartNum, WaveEndNum,SkipNumWaves)
// Example Usage: pt_ImVm("Cell_000654_","AcqNeg90","D:users:taneja:data:ptCell654",0,0.025,15,95,3)
String CellName, BaseSuffixName, WavesFolder 
Variable TStartVal, TEndVal, WaveStartNum,WaveEndNum,SkipNumWaves
String  DataWaveName, BaseCellname
Variable i,j,Ndig=4,NumWaves,T1,T2, CellNum

NewDataFolder /O/S root:TempImVmWavesFolder
NumWaves= ((WaveEndNum-WaveStartNum)/(SkipNumWaves+1) ) +1
Make /O/N=(NumWaves) ImVm
j=0
T1=TStartVal
T2=TEndVal

	For (i=WaveStartNum;i<=WaveEndNum;i+=(SkipNumWaves+1))
		sscanf CellName, "ptCell%d", CellNum
//		Currently the cell num has 6 digits. If that changes then the number in next line shud change...
		BaseCellname = "Cell_"+ num2digstrCopy(6,CellNum) + "_"
		DataWaveName =BaseCellName+num2digstrCopy(NDig,i) + "_"+BaseSuffixName
		LoadData /Q/O/D/J=DataWaveName/L=1 WavesFolder
//		TStart = X2pnt($(DataWaveName),T1)
//		TEnd  = X2pnt($(DataWaveName),T2)
//		Wavestats /Q/R=[TStart, TEnd] $(DataWaveName)
		Wavestats /Q/R=(TStartVal, TEndVal) $(DataWaveName)
		ImVm[j]= V_avg
		j +=1
		KillWaves /Z $(DataWaveName)
	EndFor
	Duplicate /O ImVm,  $("root:"+CellName+":ImVm")
	KillWaves ImVm
	Print "Averaged", j, "waves..."
Return 1
End

Function /S num2digstrCopy(digits,num)
	variable digits, num
	
//
//	This function returns a string representing a number padded with zeros, so that the number of character
//	= digits. If num occupies more digits than requested, the excess low digits of the number are truncated. 
// 	e.g. calling num2digstr (3,1234) returns "123", while  calling num2digstr (6,1234) returns "001234"
//
	String outstr, zerostr="000000000000", numstr = num2istr(num)
	variable i=1
	
	if (strlen(numstr) <= digits) 
		outstr = zerostr[0,digits-1]		
		outstr[digits-strlen(numstr),digits-1] = numstr
	else
		outstr = numstr[0,digits-1]
	endif
	
	return outstr
End

Function pt_AlignEvokedResponses(TBaselineAvgDur, TBaseLineEndVal, TSearchStartVal, TSearchDur, Threshold, SmoothBoxWidth, PercentRiseTimeToAlign)
// Given a trace, and a window in which to look for evoked response, this function xshifts the trace so that the rising edge of the response lies at x = 0.
// Example Usage: pt_AlignEvokedResponses(0.01, 0.7995, 0.7995, 0.006, -5e-12, 7, 50)
Variable TBaselineAvgDur, TBaseLineEndVal, TSearchStartVal, TSearchDur, Threshold, SmoothBoxWidth, PercentRiseTimeToAlign
String 	wavlist, wavstr
Variable BaseAvg, ResponseThreshold, PeakVal, PeakLoc, Offset, Delta, YValueToAlignAt, XValueToAlignAt, i, NumWaves

wavlist = wavelist("*",";","WIN:")
print "Aligning waves...",wavlist
NumWaves= ItemsInList(wavlist, ";")
i=0
For (i=0;i<NumWaves;i+=1)
 	wavstr= StringFromList (i,wavlist,";")
// 	if (strlen(wavstr)== 0)
// 	break
// 	endif
 	if (strlen(wavstr)== 0)
  			Print "While aligning evoked responses could not find wave #", i
  			DoAlert 0, "Exiting without finishing!!"
 			break
 	endif
 	
 	wave w = $wavStr 
	Duplicate /o w,$(wavstr + "_EA") 	// EA = Evoked (response) Aligned
	wave w1 = $(wavstr + "_EA")
	Offset = DimOffset(w1,0)
	Delta = DimDelta(w1,0)
	BaseAvg=mean(w1, TBaseLineEndVal - TBaselineAvgDur, TBaseLineEndVal)
	ResponseThreshold = BaseAvg + Threshold

	If (Threshold >= 0)
		findpeak /B=(SmoothBoxWidth) /M=(ResponseThreshold) /Q /R=( TSearchStartVal, TSearchStartVal +TSearchDur) w1
		if (V_Flag)
			print "WARNING!!! Maximum was not found in the wave!","t1=",TSearchStartVal,"t2=",TSearchStartVal +TSearchDur,"EpspThresholdAbsolute=",ResponseThreshold,"Wave=",wavstr
		endif
	else
		findpeak /B=(SmoothBoxWidth) /M=(ResponseThreshold) /N /Q /R=( TSearchStartVal, TSearchStartVal +TSearchDur) w1
		if (V_Flag)
			print "WARNING!!! Minimum was not found in the wave!","t1=",TSearchStartVal,"t2=",TSearchStartVal +TSearchDur,"EpspThresholdAbsolute=",ResponseThreshold,"Wave=",wavstr
			endif
	EndIf
	If (!V_Flag)
		PeakVal= V_PeakVal
		PeakLoc= V_PeakLoc
		YValueToAlignAt = BaseAvg + 0.01*PercentRiseTimeToAlign*(PeakVal - BaseAvg)
		FindLevel /Q/R=(TSearchStartVal, PeakLoc) w1, YValueToAlignAt
		XValueToAlignAt = V_LevelX
//		Offset -= XValueToAlignAt
//		SetScale /p x, Offset, Delta, w1
		DeletePoints 0,x2Pnt(w1,XvalueToAlignAt-TBaselineAvgDur), w1
		AppendToGraph w1
	EndIf
	RemoveFromGraph $wavstr
EndFor
//Display w1
End 

// function that kills all graphs (KillWindow is there only in Igor5)
Function pt_KillGraphs()
String Str
Str=WinName(0,1)
Do
KillWindow $Str
Str=WinName(0,1)
While (StrLen(Str)!=0)
End

// function that kills all graphs (KillWindow is there only in Igor5)
Function pt_KillWindows(WindowType)
Variable WindowType
// More general form of pt_KillGraphs() 12/18/10
// 1:		Graphs
// 2:		Tables
// 4:		Layouts
// 16:		Notebooks
// 64:		Panels
// 128:		Procedure windows
// 4096:	XOP target windows (e.g., surface plots)

String Str
Str=WinName(0,WindowType)
Do
KillWindow $Str
Str=WinName(0,WindowType)
While (StrLen(Str)!=0)
End

Function pt_FindResponseAmplitude(WavName, tStartVal, tEndVal, SmoothFactor, EpspIsAMax, PeakVal, PeakPos)
String WavName
Variable tStartVal, tEndVal, SmoothFactor, EpspIsAMax, &PeakVal, &PeakPos
Duplicate /o $WavName, wSmooth
Smooth  SmoothFactor, wSmooth	
wavestats /q/r=(tStartVal,tEndVal) wSmooth
if (EpspIsAMax)
	PeakPos=V_MaxLoc
	wavestats /q/r=(V_MaxLoc-2*DimDelta($WavName,0), V_MaxLoc+2*DimDelta($WavName,0))  $WavName
	Peakval = V_Avg
Else
	PeakPos=V_MinLoc	
	wavestats /q/r=(V_MinLoc-2*DimDelta($WavName,0), V_MinLoc+2*DimDelta($WavName,0))  $WavName
	Peakval = V_Avg
EndIf
Killwaves /z wSmooth	
End

Function pt_MeasureBaseLine(WavName, StartXVal, EndXVal, SmoothFactor, BaseLineAvg, NoisePolarity, BaseLineMaxMin)
String WavName
Variable StartXVal, EndXVal, SmoothFactor, NoisePolarity, &BaseLineAvg,  &BaseLineMaxMin
Duplicate /o $WavName, w
Smooth SmoothFactor, w
StartXVal += SmoothFactor*DimDelta(w,0)
EndXVal   -=  SmoothFactor*DimDelta(w,0)
//Print StartX, EndX
WaveStats /q/R=(StartXVal, EndXVal) w
BaseLineAvg = V_avg
If (NoisePolarity==1)
	 BaseLineMaxMin = V_Min
Else
	If (NoisePolarity==-1)
		 BaseLineMaxMin = V_Max
	Else
		Print "Warning! Noise Polarity in baseline measurement shud be +1 or -1."	
	EndIf	 
Endif 
KillWaves /z w
Return 1
End
Function pt_GenerateDataWave(WaveNamStr, StartXVal, EndXVal, DeltaXVal, FuncStr)
// pt_GenerateDataWave("w1",0,7.32,.01,"sin(x)")
String WaveNamStr, FuncStr
Variable StartXVal, EndXVal, DeltaXVal
String AssignVals
Variable Num

Num = abs((EndXVal-StartXVal)/DeltaXVal)
Make /O/N=(Num) $WaveNamStr
Wave w = $WaveNamStr
SetScale /p x,StartXVal, DeltaXVal, w
AssignVals=WaveNamStr+"="+FuncStr 
Execute AssignVals
Return 1
End

Function pt_FindSpike(WavName, StartXVal, EndXVal, InflectionWindowWidth, CurvaturePeakAmpThr, SpikeThr, SpikeWasNotFound, PeakPos, PeakAmp)
// find if between the starting point and peak pos. 
String WavName
Variable StartXVal, EndXVal, InflectionWindowWidth, CurvaturePeakAmpThr, SpikeThr, &SpikeWasNotFound, &PeakPos, &PeakAmp
Variable t1,t2, TempPeakPos, TempPeakVal 
t1= StartXVal; t2= EndXVal

Duplicate /o $(WavName), wTemp
Smooth (0.0005/DimDelta(wTemp,0)), wTemp 

WaveStats /q/r=(t1, t2) wTemp // find global peak pos.
If (V_Max < SpikeThr)
	Print "Warning! Presynaptic spike max < SpikeThr."
	Print  "Wave=", WavName, "t1=", StartXVal, "t2=", EndXVal, "SpikeMax=", V_Max, "SpikeThr=",SpikeThr
//	Display $(WavName)
	SpikeWasNotFound =1; PeakPos= Nan; PeakAmp= Nan
	KillWaves /z wTemp
	Return -1
Else
	TempPeakPos = V_MaxLoc
	TempPeakVal = V_Max
	pt_CalculateCurvature("wTemp")
	FindPeak /M = (CurvaturePeakAmpThr) /Q /R=(V_MaxLoc- InflectionWindowWidth, V_MaxLoc) $("wTemp_Curvature")
	If  (!V_Flag==0)
		Print "Warning! Didn't find peak indicating active presynaptic response in the curvature wave!"
		Print  "Orig. Wave=", WavName, "t1=", V_MaxLoc- InflectionWindowWidth, "t2=", V_MaxLoc, "Threshold=", CurvaturePeakAmpThr
//		Display $(WavName)
		KillWaves /z wTemp, $("wTemp_Curvature")
		Return -1
	else
		PeakPos= TempPeakPos
		PeakAmp= TempPeakVal
		SpikeWasNotFound = 0	
	EndIf
EndIf
KillWaves /z wTemp, $("wTemp_Curvature")
Return 1
End

Function pt_CalculateCurvature(WavName)	// shud somehow be made dimensionless!
String WavName
Duplicate /o $WavName, $(WavName+"_DIF"), $(WavName+"_DIF_DIF"), $(WavName+"_Curvature")
Differentiate $(WavName)/D=$(WavName+"_DIF")
Differentiate $(WavName+"_DIF")/D=$(WavName+"_DIF_DIF")

Wave w1=$(WavName+"_DIF")
Wave w2=$(WavName+"_DIF_DIF")
Wave w3=$(WavName+"_Curvature")

w3 = w2/(1+w1^2)^1.5
killWaves /z w1, w2
End

Function Test()
Variable SpikeWasNotFound, PeakPos, PeakAmp
pt_FindSpike("w2", 2.0666, 2.0726, .003, 2, 0, SpikeWasNotFound, PeakPos, PeakAmp)
Print SpikeWasNotFound, PeakPos, PeakAmp
End

Function pt_LoadCells1(TitleForSelection, BaseLineStart, BaseLineEnd, PntsPerBin, MinBaseLineStabilityPercent, NStim, NDig)
// To load data from different pairs, and average them.
// Read list of pairs ; make data folders for each pair ; load data ; multiply by netmask wave ; find 
// baseline stability; normalize; average; plot BarGraphs.
String TitleForSelection
Variable BaseLineStart, BaseLineEnd, PntsPerBin, MinBaseLineStabilityPercent, NStim, NDig
String Pair, PostCell, Path, wName, OldDf, NewDf, DfName
Variable i, j, StartRowNum, EndRowNum, StartWaveNum, EndWaveNum

Wave /T wPair= PairName
Wave /T wPostCell= PostCellName
Wave /T wPath= DiskDataFolderName
Wave 	wStartNum= StartNum
Wave 	wEndNum= EndNum
Wave	BS= BaseLineStability
//wavlist = wavelist("*",";","WIN:")
//print "Aligning waves...",wavlist
GetSelection  Table, pt_CDB, 1
StartRowNum = V_StartRow; EndRowNum = V_EndRow 

	For (i=StartRowNum; i==EndRowNum; i+=1)
 		Pair				=	wPair[i]
 		PostCell			=	wPostCell[i]
 		Path			=	wPath[i]
 		StartWaveNum	= 	wStartNum[i]
 		EndWaveNum	=	wEndNum[i]
 		if ( strlen(Pair)==0 || StrLen(PostCell)==0 || StrLen(Path) ==0 || NumType(StartWaveNum)!=0  || NumType(EndWaveNum)!=0) //|| !(NumType(StartWaveNum)) || !(NumType(EndWaveNum))
 			Print "Missing entry in row=", i
 			break
 		endif
 		wName= PostCell+"EPSP_"
 		DfName= "root:"+Pair
 		OldDf=GetDataFolder(1)
 		NewDataFolder /O/S $DfName	// NewDataFolder doesn't accept ":" at end. while SetDataFolder and GetDataFolder do. so with SetDataFolder if the name is 
 									// not obtained by GetDataFolder, then u need to add a ":" at the end.
  		pt_LoadWaves(wName, Path, DfName, StartWaveNum,EndWaveNum, 0, NDig)  // load fresh copy; don't CheckPreExistence
  		
  		For (j=1; j==NStim; j+=1)
  			wName= wName+num2digstrCopy(NDig, j)
  			Duplicate /o $wName, $("root:"+Pair+":"+"EPSP_"+num2digstrCopy(NDig,j))
  		EndFor	
  		
  	EndFor
  	SetDataFolder $OldDf
End

Function pt_LoadCells(TableName, MatchStr, wSuffix)
// Eg. pt_LoadCells("pt_Cdb", "*Epsp_0001", "Epsc1")
String TableName, MatchStr, wSuffix
String OldDf, IgorFolderPath, ListStr, WaveStr
Variable StartRowNum,  EndRowNum, i, NumWaves, j
 
Wave /T HdFolderPath	= DiskDataFolderName
Wave /T Pair				= PairName

OldDf=GetDataFolder(1)

GetSelection  Table, $TableName, 1
StartRowNum = V_StartRow; EndRowNum = V_EndRow
	
	For (i=StartRowNum; i<=EndRowNum; i+=1)
 		IgorFolderPath= "root:"+ Pair[i]
 		Print "Loading pair", Pair[i], "..."
 		pt_LoadData(MatchStr, HDFolderPath[i], IgorFolderPath)
 		SetDataFolder $IgorFolderPath
 		ListStr= WaveList(MatchStr, ";", "")
		NumWaves = ItemsinList(ListStr)
		For (j=0; j< NumWaves; j+=1)
			WaveStr = StringFromList(j, ListStr, ";")
//			Duplicate /o $WaveStr, $("root:"+Pair[i]+wSuffix)
			Duplicate /o $WaveStr, $("root:"+ WaveStr)
			Print "Loading wave", WaveStr, "..."
		EndFor
 	EndFor	
 	SetDataFolder $OldDf	
End

Function pt_SaveCdb(TableName, CdbPath)
String TableName, CdbPath
String WaveListStr, WinNameStr
	WinNameStr = "Win:"+TableName
	WaveListStr=WaveList("*", ";", WinNameStr)
	Print "Saving waves", WaveListStr, "in folder", CdbPath
	NewPath /C/O/Q EvokedAnalysis, CdbPath
	Save /O/b /P=EvokedAnalysis WaveListStr
End

Function pt_GenHdFolderPath(TableName)
//pt_GenHdFolderPath("pt_CDB")
String TableName
Variable StartRowNum,  EndRowNum, i

Wave /T Pair					= PairName
Wave /T HdParentFolderPath	= DiskParentDataFolderName
Wave /T ExptDate			= ExptDate
Wave /T AnalDate			= AnalDate
Wave /T HdFolderPath		= DiskDataFolderName



GetSelection  Table, $TableName, 1
StartRowNum = V_StartRow; EndRowNum = V_EndRow

	For (i=StartRowNum; i<=EndRowNum; i+=1)
		HdFolderPath[i]= HdParentFolderPath[i]+ExptDate[i]+" Folder:" +Pair[i]+"Anal"+AnalDate[i]+" Folder:"
	EndFor
End

Function pt_CalculateStatistic(TableName)
// a general purpose function to call a function with some parameters;
String TableName
Variable StartRowNum,  EndRowNum, i
End


Function pt_AnalyzeEvokedData(PreCellNum, PostCellNum, AutoZero, VmIni, NumDigit, ExptDateStr)
// pt_AnalyzeEvokedData(1069, 1072, 1, -70.3e-3, 6, "05/28/2004")
String ExptDateStr
Variable PreCellNum, PostCellNum, AutoZero, VmIni, NumDigit
String PreCellVmWaveName, PostCellVmWaveName, PostCellVmCalWaveName, PreCellRinWaveName, PostCellRinWaveName, InputWavesStringList, InputEpspWaveName, OutputEpspWaveName
String PreCellName, PostCellName, PairName

PreCellVmWaveName= "Cell_"+ num2digstrCopy(NumDigit, PreCellNum)+"_Vm"
PostCellVmWaveName= "Cell_"+ num2digstrCopy(NumDigit, PostCellNum)+"_Vm"
PostCellVmCalWaveName= "Cell_"+ num2digstrCopy(NumDigit, PostCellNum)+"_VmCal"
PreCellRinWaveName= "Cell_"+ num2digstrCopy(NumDigit, PreCellNum)+"_Seal"
PostCellRinWaveName= "Cell_"+ num2digstrCopy(NumDigit, PostCellNum)+"_Seal"

pt_ConvertImToVm(PostCellVmWaveName, PostCellRinWaveName, -0.09, AutoZero, VmIni)
display $PostCellVmCalWaveName

InputWavesStringList= "PreRSeriesWave;PostRSeriesWave;"+PreCellRinWaveName+";"+PostCellRinWaveName+";"+PreCellVmWaveName+";"+PostCellVmCalWaveName
pt_GenMaskWave(InputWavesStringList,44,"30;30;30;30;20;20","5e6;40e6; 5e6;40e6; 50e6;1500e6; 50e6;1500e6; -90e-3; -55e-3; -90e-3; -55e-3",5,5,2)

InputEpspWaveName="Cell_"+ num2digstrCopy(NumDigit, PostCellNum)+ "_Epsp_0001"
OutputEpspWaveName="Cell"+num2str(PreCellNum)+"To"+num2str(PostCellNum)+"Epsc1"
pt_MultiplyWaves(InputEpspWaveName, "NetMaskWave", OutputEpspWaveName)

InputEpspWaveName="Cell_"+ num2digstrCopy(NumDigit, PostCellNum)+ "_Epsp_0002"
OutputEpspWaveName="Cell"+num2str(PreCellNum)+"To"+num2str(PostCellNum)+"Epsc2"
pt_MultiplyWaves(InputEpspWaveName, "NetMaskWave", OutputEpspWaveName)
PreCellName="Cell_"+num2digstrCopy(NumDigit, PreCellNum)
PostCellName="Cell_"+num2digstrCopy(NumDigit, PostCellNum)
PairName="Cell"+num2str(PreCellNum)+"To"+num2str(PostCellNum)
pt_DisplayDataEvoked(PreCellName,PostCellName, PairName, ExptDateStr)

// Convert voltage to current for PostSynapticCell, GenerateMaskWave, multiply epsp with netmaskwave, & display evoked data.
// pt_ConvertImToVm("Cell_001059_Vm", "Cell_001059_Seal", -0.09, 0, -65.9e-3)
//pt_GenMaskWave("PreRSeriesWave;Cell_001060_Seal;Cell_001059_Seal;Cell_001060_Vm;Cell_001059_VmCal",44,"30;30;30;20;20","5e6;50e6; 50e6;1500e6; 50e6;1500e6; -100e-3; -50e-3; -100e-3; -50e-3",5,5,2)
//pt_MultiplyWaves("Cell_001059_EPSP_0001", "NetMaskWave", "Cell1060To1059Epsc1")
//pt_MultiplyWaves("Cell_001059_EPSP_0002", "NetMaskWave", "Cell1060To1059Epsc2")
//pt_DisplayDataEvoked("Cell_001060","Cell_001059", "Cell1060To1059")
End

Function pt_ReturnSigmoidVal(XVal, Base, XHalf, Rate)
Variable XVal, Base, XHalf, Rate
Variable SigmoidVal
SigmoidVal=Base+1/(1+exp( (XHalf-XVal)/Rate ))
Return SigmoidVal
End

Function pt_LinearMinMaxNormalize(YOld, YOldMin, YNewMax, YNewMin, YOldMax)
Variable YOld, YOldMin, YNewMax, YNewMin, YOldMax
Variable YNew
YNew=(YOld-YOldMin)*(YNewMax-YNewMin)/(YOldMax-YOldMin)+YNewMin
Return YNew
End

Function /s pt_SaveDataToDisk(DFName, EncFName, DiskDFName)
String DFName, DiskDFName, EncFName
String OldDf, IgorPathName
OldDf = GetDataFolder(1)
SetDataFolder DFName
NewPath /Q/C/M="Enter folder to save data in" /O SaveDF, DiskDFName
//Print V_Flag
If (V_Flag==0)
	Print "Saving data to disk..."
	SaveData /D=1/O/R/P=SaveDF /T=$EncFName
Else
	Print "Problem"
EndIf
//KillPath SaveDF
SetDataFolder OldDf
Return S_Path
End

Function pt_ConcatenateAndOrSave(WListStr, IterNum, AppendIterNum, TempSaveFolder,SaveDataFolder)
String WListStr, TempSaveFolder, SaveDataFolder
Variable IterNum, AppendIterNum
NVAR SaveDataToHD=root:EegGlobalVars:SaveDataToHD
String OldDF, wName, wName1
Variable i, NumWaves


NumWaves=ItemsInList(WListStr)
For (i=0; i<NumWaves;i+=1)
	wName=StringFromList(i, WListStr, ";")
	Wave w=$wName
	Concatenate /NP {$wName}, $(TempSaveFolder+":"+wName)
//	If ((Mod(IterNum,N)==0) || (IterNum==TotIter) || (EndOfExpt==1) ) // save every N'th iter OR last iter OR 
	If (SaveDataToHD==1)
		NewPath /Q/C/O SaveDF, SaveDataFolder				   // EndOfExpt=1 (say cos user aborted expt.)
		OldDF=GetDataFolder(-1)
		SetDataFolder $TempSaveFolder
		If (AppendIterNum==1)
			Rename $wName $(wName+"N"+Num2Str( IterNum) )
			Save /O/B/P=SaveDF wName+"N"+Num2Str( IterNum) // as wName+"N"+Num2Str( IterNum) +".ibw"
			KillWaves $(wName+"N"+Num2Str( IterNum) )
		Else
//			Rename $wName $(wName+"N"+Num2Str( IterNum) )
			Save /O/B/P=SaveDF wName // as wName+"N"+Num2Str( IterNum) +".ibw"
			KillWaves $(wName)
		EndIf	
		SetDataFolder $OldDF
		KillPath SaveDF
	EndIf
EndFor
SaveDataToHD=0
Return 1
End

Function pt_RemoveNansAndInfs(Wname)
String Wname
Variable N, i, NumNans=0
Duplicate /o $WName, $(WName+"_NoNan")
N=NumPnts($WName)
	Wave w= $WName
	Wave w1= $(WName+"_NoNan")
	For (i=0; i<N; i+=1)
		If (NumType(w[i])!=0)
			DeletePoints i-NumNans,1,w1
			NumNans+=1
		EndIf
	EndFor
Print "Removed", NumNans,"Nans & Infs from", WName, "..."
End

Function pt_AddNaNs(wName, Suffix, StartPnt, EndPnt, LeaveEveryXthPnt)
String wName, Suffix
Variable StartPnt, EndPnt, LeaveEveryXthPnt

Variable N, i

Duplicate /O $wName, $(wName +Suffix)
Wave w=$(wName +Suffix)
N = Numpnts(w)

For (i=StartPnt; i<=EndPnt; i+=1)
		If (Mod(i+1, LeaveEveryXthPnt)!=0)
			w[i] = NaN
		EndIf
EndFor
End


Function pt_InsertPoints()

// InsertPoints in a wave and initialize the values. Same as redimension. 

String DataWaveMatchStr, InsrtNewStr, InsrtPosStr
Variable StartIndx, NPnts,  InitialVal, ReplaceExisting

String  WList, WNameStr, NewWStr
Variable NumWaves, i, EndIndx

String LastUpdatedMM_DD_YYYY="03_15_2009"

Wave /T ParNamesW		=	$pt_GetParWave("pt_InsertPoints", "ParNamesW")
Wave /T ParW			=	$pt_GetParWave("pt_InsertPoints", "ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_InsertPointsParW and/or pt_InsertPointsParNamesW!!!"
EndIf

Print "*********************************************************"
Print "pt_InsertPoints last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

DataWaveMatchStr	=		ParW[0]
StartIndx			=		Str2Num(ParW[1])
NPnts				=		Str2Num(ParW[2]) 
InitialVal				=		Str2Num(ParW[3])
InsrtNewStr			= 		ParW[4]
InsrtPosStr			= 		ParW[5]
ReplaceExisting		= 		Str2Num(ParW[6])

PrintAnalPar("pt_InsertPoints")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")

Print "Analyzing Waves N=",  Numwaves, WList

DoAlert 0,"Used NPnts = 30-NumPnts(w) and StartIndx = NumPnts(w) in pt_InsertPoints() temporarily"
//DoAlert 0,"Used NPnts = 20-NumPnts(w) in pt_InsertPoints() temporarily"

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$WNameStr
	Print "Used NPnts = 30-NumPnts(w) and StartIndx = NumPnts(w) in pt_InsertPoints() temporarily"
	NPnts = 30-NumPnts(w)
	StartIndx = NumPnts(w)
//	NPnts = 20-NumPnts(w)
//	StartIndx = NumPnts(w)
	NewWStr  = pt_CalNewNameStr(WNameStr, InsrtNewStr, InsrtPosStr, ReplaceExisting)
	If (StringMatch(WNameStr, NewWStr)==1)
		If (NPnts >0)
		InsertPoints StartIndx, NPnts, w
		EndIndx= StartIndx+NPnts-1
		w[StartIndx, EndIndx] = InitialVal
		EndIf
	Else
		If (NPnts >0)
		Duplicate /O w, $NewWStr
		Wave NewW=$NewWStr
		InsertPoints StartIndx, NPnts, NewW
		EndIndx= StartIndx+NPnts-1
		NewW[StartIndx, EndIndx] = InitialVal
		EndIf
	EndIf
EndFor
Print "										"
Print "Processed number of waves =", i	
End

Function pt_InsertPointsVarPar1()

// wrapper for pt_InsertPoints. will run pt_InsertPoints with some parameters varied
Variable Npnts
String LastUpdatedMM_DD_YYYY="03_15_2009"
Print "*********************************************************"
Print "pt_InsertPointsVarPar1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_InsertPoints"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_InsertPoints"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_InsertPointsParW and/or pt_InsertPointsParNamesW!!!"
EndIf


Duplicate /T/O AnalParW, AnalParWOld
If (WaveExists(F_IISVAvg))
Wave w=F_IISVAvg
Npnts = 20-NumPnts(w)
AnalParW[2] = Num2Str(NPnts)
pt_AnalWInFldrs2("pt_InsertPoints")

Duplicate /T/O AnalParWOld, AnalParW
KillWaves AnalParWOld
EndIf
End



Function pt_WriteReport(NoteBookName)
String NoteBookName
NewNoteBook /N=NoteBookWin as NoteBookName
NoteBook NoteBookWin text="TrialText"
End

Function pt_SleepIgorTill(AbsTime)
String AbsTime
String Str
Print "Igor Sleeping till", AbsTime,"Press command-period (Macintosh ) or Ctrl+Break (Windows ) to wake up Igor"
//Sleep /A/Q/W $AbsTime
End

Function pt_InvertWave(WName, NewWName)
String WName, NewWname
Variable N
If (StringMatch(WName, NewWName)==1|| WaveExists($NewWName)==1)
	DoAlert 1, "NewName same as original wave or preexists!! Overwrite=Yes; Abort=No"
	If (V_Flag!=1) //don't overwrite
		Abort "Aborting..."
	Else
		Duplicate  $WName, $WName+"_TempW"
		If (WaveType($WName)==0)		// text wave
			Wave /T Tw=$WName
			Wave /T Tw1=$WName+"_TempW"
			N=NumPnts(Tw)
			Tw1[0,N-1]=Tw[N-1-p]
			Duplicate /O Tw1,$NewWName
			KillWaves Tw1
		Else
			Wave w=$WName
			Wave w1=$WName+"_TempW"
			N=NumPnts(w)
			w1[0,N-1]=w[N-1-p]
			Duplicate /O w1,$NewWName
			KillWaves w1
		EndIf
		
	EndIf
Else
	Duplicate  $WName, $NewWName
	If (WaveType($WName)==0)		// text wave
		Wave /T Tw=$WName
		Wave /T Tw1=$WName+"_TempW"
		N=NumPnts(Tw)
		Tw1[0,N-1]=Tw[N-1-p]	
	Else
		Wave w=$WName
		Wave w1=$WName+"_TempW"
		N=NumPnts(w)
		w1[0,N-1]=w[N-1-p]	
	EndIf
		
EndIf
End

Function pt_ExtractWave(WName, SuffixStr, StartPnt, EndPnt)
String WName, SuffixStr
Variable StartPnt, EndPnt

Wave w = $WName

Make /O/N=(EndPnt-StartPnt+1) $(WName+SuffixStr)
Duplicate /O/R=[StartPnt, EndPnt] w $(WName+SuffixStr)

End

// many expts are like this. there are repetitions in each epoch. and then there are many epochs (like BaseLine, Drug, Wash). This function takes a wave
//in which some parameter has been calculated (like avg in a certain window) for each wave, averages the repetitions, and makes waves for different
// epochs.

Function pt_MakeEpochs()

String	WNameStr, BaseNameStr
Variable	PntsPerRep, BaseStartPnt, NumBaseReps, DrugStartPnt, NumDrugReps, WashStartPnt, NumWashReps
Variable i

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_MakeEpochs"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_MakeEpochs"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_MakeEpochsParW!!!"
EndIf

PrintAnalPar("pt_MakeEpochs")

WNameStr				=	AnalParW[0]
BaseNameStr			=	AnalParW[1]
PntsPerRep				=	Str2Num(AnalParW[2])
BaseStartPnt			=	Str2Num(AnalParW[3])
NumBaseReps			=	Str2Num(AnalParW[4])
DrugStartPnt				=	Str2Num(AnalParW[5])
NumDrugReps			=	Str2Num(AnalParW[6])
WashStartPnt			=	Str2Num(AnalParW[7])
NumWashReps			=	Str2Num(AnalParW[8])

Wave w	=	$WNameStr

If (NumBaseReps > 0)
	Make /O/N	=	(PntsPerRep)	$(BaseNameStr+"_Base")
	Wave w1	=	$(BaseNameStr+"_Base")
	Make /O/N=(NumBaseReps) wTemp
	
	For (i=0; i<PntsPerRep; i+=1)
	
		wTemp[]=w[BaseStartPnt+i+PntsPerRep*p]
		WaveStats /Q wTemp
		w1[i] = V_Avg
	
	EndFor
EndIf	

If (NumDrugReps > 0)
	Make /O/N	=	(PntsPerRep)	$(BaseNameStr+"_Drug")
	Wave w2	=	$(BaseNameStr+"_Drug")
	Make /O/N=(NumDrugReps) wTemp

	For (i=0; i<PntsPerRep; i+=1)
	
		wTemp[]=w[DrugStartPnt+i+PntsPerRep*p]
		WaveStats /Q wTemp
		w2[i] = V_Avg
	
	EndFor
EndIf

If (NumWashReps > 0)
	Make /O/N	=	(PntsPerRep)	$(BaseNameStr+"_Wash")
	Wave w3	=	$(BaseNameStr+"_Wash")
	Make /O/N=(NumWashReps) wTemp

	For (i=0; i<PntsPerRep; i+=1)
	
		wTemp[]=w[WashStartPnt+i+PntsPerRep*p]
		WaveStats /Q wTemp
		w3[i] = V_Avg
	
	EndFor
EndIf

KillWaves WTemp

End

// many expts are like this. there are repetitions in each epoch. and then there are many epochs (like BaseLine, Drug, Wash). This function takes a wave
//in which some parameter has been calculated (like avg in a certain window) for each wave, averages the repetitions, and makes waves for different
// epochs.

Function pt_AvgRepeatNums()	// former name pt_MakeEpochs

// This is always the latest version\.
//*** Averaging is a little counter-intutive. Each point in point per repeat is averaged across num repeats***/

// modifying so that Numpnts, SD, and SE are also calculated 11/14/2007
// corrected checking StartPntsW[p1]==Nan to NumType(StartPntsW[p1])!=0
// Added displaying of repeats and average									04_04_2007
// modified so that the second repeat need not be contiguous. eg. first rep can start at 11 and with NReps=2, second rep. can
// start at 51 or 71 instead of 31.  (03_26_2007)

String	WNameStr, OutNameStr, RangeW
Variable	PntsPerRep, StartPnt, NumReps
Variable i, p1,Offset
String LastUpdatedMM_DD_YYYY="11_14_2007"

Print "*********************************************************"
Print "pt_AvgRepeatNums last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_AvgRepeatNums"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_AvgRepeatNums"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_AvgRepeatNums!!!"
EndIf

WNameStr				=	AnalParW[0]
OutNameStr				=	AnalParW[1]
RangeW					=	AnalParW[2]

RangeW = GetDataFolder(0) + RangeW	//01/25/14

PrintAnalPar("pt_AvgRepeatNums")

//Wave /T AnalParNamesW		=	$pt_GetParWave(RangeW, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(RangeW, "ParW")

PntsPerRep			=	Str2Num(AnalParW[0])
StartPnt				=	Str2Num(AnalParW[1])	// Start Pnt of first repeat. Count starts at 1
NumReps				=	Str2Num(AnalParW[2])

Make /O/N=(NumReps) StartPntsW
StartPntsW[0] = StartPnt

// following for non-contiguous repeats which can be appended to the par wave
For (i=1;i<(NumReps);i+=1)
	StartPntsW[i] = (  (i+2) > (NumPnts(AnalParW)-1)  ) ? NAN : Str2Num(AnalParW[i+2])
EndFor

//PrintAnalPar(RangeW)

Wave w	=	$WNameStr

Print "Calculating AvgRepeatNums for", WNameStr

If (PntsPerRep*NumReps!=0)

//	Make /O/N	=	(PntsPerRep)	$OutNameStr
//	Wave w1	=	$OutNameStr

	Make /O/N	=	(PntsPerRep)	$(OutNameStr+"Avg"), $(OutNameStr+"Num"), $(OutNameStr+"SD"), $(OutNameStr+"SE")
	Wave w1	=	$(OutNameStr+"Avg")
	Wave w2	=	$(OutNameStr+"Num")
	Wave w3	=	$(OutNameStr+"SD")
	Wave w4	=	$(OutNameStr+"SE")
	
	w1=Nan
	w2=Nan
	w3=Nan
	w4=Nan
	
	Make /O/N=(NumReps) wTemp
	
	For (i=0; i<PntsPerRep; i+=1)
	//	wTemp[]=w[StartPnt+i+PntsPerRep*p]
	//	wTemp[]=w[StartPnt-1+i+PntsPerRep*p]	// this assigns the last value of the right hand wave 
											// doesn't have the point being evaluated. 

		For (p1=0; p1<NumReps; p1+=1)
//			If (StartPntsW[p1]==NAN)
			If (NumType(StartPntsW[p1])!=0)
				Offset = PntsPerRep*p1
			Else
				Offset = StartPntsW[p1] - StartPntsW[0]
			EndIf
//			If ((NumPnts(w)-1)<(StartPnt-1+i+PntsPerRep*p1))
//				wTemp[p1]=Nan
//			Else	
//				wTemp[p1]=w[StartPnt-1+i+PntsPerRep*p1]
//			EndIf
			If (i==0)	
				Print "Repeat number",p1,"\t StartPnt", StartPnt+Offset	
			EndIf
			If ((NumPnts(w)-1)<(StartPnt-1+i+Offset))
				wTemp[p1]=Nan
			Else	
				wTemp[p1]=w[StartPnt-1+i+Offset]
			EndIf
		EndFor	
		
		WaveStats  /Q wTemp																						
		w1[i] = V_Avg
		w2[i] = V_NPnts
		w3[i] = V_SDev
		w4[i] = V_SDev/Sqrt(V_Npnts)
			
	EndFor
	KillWaves WTemp
Else
	Print "Attention! Either PntsPerRep OR NumReps =0!!! No Wave Generated"	
EndIf
If (PntsPerRep*NumReps!=0)
Display
	DoWindow pt_AvgRepeatNumsDisplay
	If (V_Flag)
		DoWindow /F pt_AvgRepeatNumsDisplay
		Sleep 00:00:02
		DoWindow /K pt_AvgRepeatNumsDisplay
	EndIf
	DoWindow /C pt_AvgRepeatNumsDisplay
	For (p1=0; p1< NumReps; p1+=1)
	If (NumType(StartPntsW[p1])!=0)
		Offset = PntsPerRep*p1
	Else
		Offset = StartPntsW[p1] - StartPntsW[0]
	EndIf
	Duplicate /O/R=[StartPnt-1+Offset, StartPnt-1+Offset +PntsPerRep-1] w, $("AvgRepeatNums"+Num2Str(p1))
	SetScale /P x,0,1, $("AvgRepeatNums"+Num2Str(p1))
 	AppendToGraph /W=pt_AvgRepeatNumsDisplay $("AvgRepeatNums"+Num2Str(p1))
 	ModifyGraph /W=pt_AvgRepeatNumsDisplay mode=4
 	EndFor
 	AppendToGraph /W=pt_AvgRepeatNumsDisplay w1
 	ErrorBars /W=pt_AvgRepeatNumsDisplay $(OutNameStr+"Avg") Y,wave=($(OutNameStr+"SE"),$(OutNameStr+"SE"))	// also plot SE
 	ModifyGraph rgb($OutNameStr+"Avg")=(0,0,0)
	ModifyGraph /W=pt_AvgRepeatNumsDisplay mode=4
	ModifyGraph /W=pt_AvgRepeatNumsDisplay marker($OutNameStr+"Avg")=41
	DoUpdate
	DoWindow pt_AvgRepeatNumsDisplay
	If (V_Flag)
		DoWindow /F pt_AvgRepeatNumsDisplay
		Sleep 00:00:02
		DoWindow /K pt_AvgRepeatNumsDisplay
	EndIf
	For (p1=0; p1< NumReps; p1+=1)
		KillWaves $("AvgRepeatNums"+Num2Str(p1))
	EndFor
EndIf	
End

// many expts are like this. there are repetitions in each epoch. and then there are many epochs (like BaseLine, Drug, Wash). This function takes a wave
//in which some parameter has been calculated (like avg in a certain window) for each wave, averages the repetitions, and makes waves for different
// epochs.

Function pt_AvgRepeatNums1()	// former name pt_MakeEpochs

String	WNameStr, OutNameStr
Variable	PntsPerRep, StartPnt, NumReps
Variable i, p1

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_AvgRepeatNums"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_AvgRepeatNums"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_AvgRepeatNums!!!"
EndIf

PrintAnalPar("pt_AvgRepeatNums")

WNameStr				=	AnalParW[0]
OutNameStr				=	AnalParW[1]

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RepeatNumsBL", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_RepeatNumsBL", "ParW")

PntsPerRep				=	Str2Num(AnalParW[0])
StartPnt					=	Str2Num(AnalParW[1])
NumReps				=	Str2Num(AnalParW[2])

PrintAnalPar("pt_RepeatNumsBL")

Wave w	=	$WNameStr

Print "Calculating AvgRepeatNums for", WNameStr

If (PntsPerRep*NumReps!=0)

	Make /O/N	=	(PntsPerRep)	$OutNameStr
	Wave w1	=	$OutNameStr
	Make /O/N=(NumReps) wTemp
	
	For (i=0; i<PntsPerRep; i+=1)
	//	wTemp[]=w[StartPnt+i+PntsPerRep*p]
	//	wTemp[]=w[StartPnt-1+i+PntsPerRep*p]	// this assigns the last value of the right hand wave 
											// doesn't have the point being evaluated. 

		For (p1=0; p1<NumReps; p1+=1)
			If ((NumPnts(w)-1)<(StartPnt-1+i+PntsPerRep*p1))
				wTemp[p1]=Nan
			Else	
				wTemp[p1]=w[StartPnt-1+i+PntsPerRep*p1]
			EndIf
		EndFor	
	
		WaveStats /Q wTemp																						
		w1[i] = V_Avg		
	
	EndFor


	KillWaves WTemp
Else
	Print "Attention! Either PntsPerRep OR NumReps =0!!! No Wave Generated"
	
EndIf
End



// many expts are like this. there are repetitions in each epoch. and then there are many epochs (like BaseLine, Drug, Wash). This function takes a wave
//in which some parameter has been calculated (like avg in a certain window) for each wave, averages the repetitions, and makes waves for different
// epochs.

Function pt_AvgRepeatWaves()

// This is always the latest version

// added capability for non-contiguous repeats like for pt_AvgRepeatNums	1st Aug , 2007
// SUPERCEDES pt_AvgRepeatWaves2()	1st Aug , 2007
// add print for what waves are selected. 1st Aug , 2007
// as whole wave list is printed, added "from"  07/25/2007
// modified so that the results are displayed. 05_20_2007
// also the repeats can be separately specified for each folder now. 05_20_2007
// maybe add capability for non-contiguous repeats like for pt_AvgRepeatNums

String	DataWaveMatchStr, DataFldrStr, OutBaseNameStr, OutNameStr, RangeW
Variable DisplayXStart, DisplayXEnd, DisplayYStart, DisplayYEnd

Variable	WavesPerRep, StartWaveNum, NumReps
String 	WList, WNameStr
Variable i,j, Numwaves,p1, Offset

String LastUpdatedMM_DD_YYYY="11_14_13"

Print "*********************************************************"
Print "pt_AvgRepeatWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_AvgRepeatWaves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_AvgRepeatWaves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_AvgRepeatWaves!!!"
EndIf

PrintAnalPar("pt_AvgRepeatWaves")

DataWaveMatchStr				=	AnalParW[0]
DataFldrStr						=	AnalParW[1]
OutBaseNameStr				=	AnalParW[2]	
RangeW							=	AnalParW[3]	
DisplayXStart					=	Str2Num(AnalParW[4])
DisplayXEnd					=	Str2Num(AnalParW[5])
DisplayYStart					=	Str2Num(AnalParW[6])
DisplayYEnd					=	Str2Num(AnalParW[7])


RangeW = GetDataFolder(0) + RangeW //04/10/14

//Wave /T AnalParNamesW		=	$pt_GetParWave(RangeW, "ParNamesW")	// no need to look for par names wave  //04/10/14
Wave /T AnalParW				=	$pt_GetParWave(RangeW, "ParW")

WavesPerRep					=	Str2Num(AnalParW[0])
StartWaveNum					=	Str2Num(AnalParW[1])	// FirstWave starts from 1
NumReps						=	Str2Num(AnalParW[2])


Make /O/N=(NumReps) StartPntsW
StartPntsW[0] = StartWaveNum

For (i=1;i<(NumReps);i+=1)
	StartPntsW[i] = (  (i+2) > (NumPnts(AnalParW)-1)  ) ? NAN : Str2Num(AnalParW[i+2])
EndFor



PrintAnalPar(RangeW)


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")
If (NumWaves<WavesPerRep*NumReps)
	Abort "NumWaves less than WavesPerRep*NumReps"
EndIf



//Print "Averaging repeats in waves",WList

If (WavesPerRep*NumReps!=0)
Display
DoWindow pt_AvgRepeatWavesDisplay
	If (V_Flag)
		DoWindow /F pt_AvgRepeatWavesDisplay
		Sleep 00:00:02
		DoWindow /K pt_AvgRepeatWavesDisplay
	EndIf
DoWindow /c pt_AvgRepeatWavesDisplay
	
For (i=0; i<WavesPerRep; i+=1)
//		Duplicate /O	$(StringFromList(StartWaveNum-1+i, WList, ";")), $(OutBaseNameStr +"_"+Num2Str(i))
		WNameStr=StringFromList(StartWaveNum-1+i, WList, ";")
		Duplicate /O	$(GetDataFolder(-1)+DataFldrStr+WNameStr), $(OutBaseNameStr +"_"+Num2Str(i))
		Wave w = $(OutBaseNameStr +"_"+Num2Str(i))
		w=0
		For (j=0; j<NumReps;j+=1)
		
			If (NumType(StartPntsW[j])!=0)
				Offset = WavesPerRep*j
			Else
				Offset = StartPntsW[j] - StartPntsW[0]
			EndIf
			
			WNameStr=StringFromList(StartWaveNum-1+i+Offset, WList, ";")
			Wave w1=$(GetDataFolder(-1)+DataFldrStr+WNameStr)
			w+=w1
			AppendToGraph /W=pt_AvgRepeatWavesDisplay $(GetDataFolder(-1)+DataFldrStr+WNameStr)
			Print "Repeat wave", WNameStr	// 1st Aug , 2007
			Print ""
		EndFor	
		w /=NumReps
		AppendToGraph /W=pt_AvgRepeatWavesDisplay $(OutBaseNameStr +"_"+Num2Str(i))
		SetAxis Bottom DisplayXStart, DisplayXEnd
		SetAxis Left DisplayYStart, DisplayYEnd
		ModifyGraph rgb($(OutBaseNameStr +"_"+Num2Str(i)))=(0,0,0)
		DoUpdate
EndFor	
Else
	Print "Attention! Either WavesPerRep OR NumReps = 0!!! No Wave generated"
EndIf
// Print "Averaging repeat waves, N =", i*j, WList	
Print "Averaging repeat waves, N =", i*j, "from", WList	// as whole wave list is printed, added "from"  07/25/2007
DoWindow pt_AvgRepeatWavesDisplay
	If (V_Flag)
		DoWindow /F pt_AvgRepeatWavesDisplay
		Sleep 00:00:02
		DoWindow /K pt_AvgRepeatWavesDisplay
	EndIf

End





// many expts are like this. there are repetitions in each epoch. and then there are many epochs (like BaseLine, Drug, Wash). This function takes a wave
//in which some parameter has been calculated (like avg in a certain window) for each wave, averages the repetitions, and makes waves for different
// epochs.

Function pt_AvgRepeatWaves1()

String	DataWaveMatchStr, DataFldrStr, OutBaseNameStr, OutNameStr

Variable	WavesPerRep, StartWaveNum, NumReps
String 	WList, WNameStr
Variable i,j, Numwaves

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_AvgRepeatWaves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_AvgRepeatWaves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_AvgRepeatWaves!!!"
EndIf

PrintAnalPar("pt_AvgRepeatWaves")

DataWaveMatchStr				=	AnalParW[0]
DataFldrStr						=	AnalParW[1]
OutBaseNameStr					=	AnalParW[2]	
WavesPerRep					=	Str2Num(AnalParW[3])
StartWaveNum					=	Str2Num(AnalParW[4])	// FirstWave starts from 1
NumReps						=	Str2Num(AnalParW[5])


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")
If (NumWaves<WavesPerRep*NumReps)
	Abort "NumWaves less than WavesPerRep*NumReps"
EndIf

Print "Averaging repeat waves, N =", ItemsInList(WList, ";"), WList




//Print "Averaging repeats in waves",WList


For (i=0; i<WavesPerRep; i+=1)
//		Duplicate /O	$(StringFromList(StartWaveNum-1+i, WList, ";")), $(OutBaseNameStr +"_"+Num2Str(i))
		WNameStr=StringFromList(StartWaveNum-1+i, WList, ";")
		Duplicate /O	$(GetDataFolder(-1)+DataFldrStr+WNameStr), $(OutBaseNameStr +"_"+Num2Str(i))
		Wave w = $(OutBaseNameStr +"_"+Num2Str(i))
		w=0
		For (j=0; j<NumReps;j+=1)
			WNameStr=StringFromList(StartWaveNum-1+i+WavesPerRep*j, WList, ";")
			Wave w1=$(GetDataFolder(-1)+DataFldrStr+WNameStr)
			w+=w1
		EndFor	
		w /=NumReps
EndFor	


End

Function pt_AvgRepeatWaves2()

// This WAS the latest version	1st Aug , 2007
// add print for what waves are selected. 1st Aug , 2007
// as whole wave list is printed, added "from"  07/25/2007
// modified so that the results are displayed. 05_20_2007
// also the repeats can be separately specified for each folder now. 05_20_2007
// maybe add capability for non-contiguous repeats like for pt_AvgRepeatNums

String	DataWaveMatchStr, DataFldrStr, OutBaseNameStr, OutNameStr, RangeW
Variable DisplayXStart, DisplayXEnd, DisplayYStart, DisplayYEnd

Variable	WavesPerRep, StartWaveNum, NumReps
String 	WList, WNameStr
Variable i,j, Numwaves,p1

String LastUpdatedMM_DD_YYYY="08_01_2007"

Print "*********************************************************"
Print "pt_AvgRepeatWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_AvgRepeatWaves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_AvgRepeatWaves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_AvgRepeatWaves!!!"
EndIf

PrintAnalPar("pt_AvgRepeatWaves")

DataWaveMatchStr				=	AnalParW[0]
DataFldrStr						=	AnalParW[1]
OutBaseNameStr					=	AnalParW[2]	
RangeW							=	AnalParW[3]	
DisplayXStart					=	Str2Num(AnalParW[4])
DisplayXEnd						=	Str2Num(AnalParW[5])
DisplayYStart					=	Str2Num(AnalParW[6])
DisplayYEnd						=	Str2Num(AnalParW[7])


Wave /T AnalParNamesW		=	$pt_GetParWave(RangeW, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(RangeW, "ParW")

WavesPerRep					=	Str2Num(AnalParW[0])
StartWaveNum					=	Str2Num(AnalParW[1])	// FirstWave starts from 1
NumReps						=	Str2Num(AnalParW[2])


PrintAnalPar(RangeW)


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")
If (NumWaves<WavesPerRep*NumReps)
	Abort "NumWaves less than WavesPerRep*NumReps"
EndIf



//Print "Averaging repeats in waves",WList

If (WavesPerRep*NumReps!=0)
Display
DoWindow pt_AvgRepeatWavesDisplay
	If (V_Flag)
		DoWindow /F pt_AvgRepeatWavesDisplay
		Sleep 00:00:02
		DoWindow /K pt_AvgRepeatWavesDisplay
	EndIf
DoWindow /c pt_AvgRepeatWavesDisplay
	
For (i=0; i<WavesPerRep; i+=1)
//		Duplicate /O	$(StringFromList(StartWaveNum-1+i, WList, ";")), $(OutBaseNameStr +"_"+Num2Str(i))
		WNameStr=StringFromList(StartWaveNum-1+i, WList, ";")
		Duplicate /O	$(GetDataFolder(-1)+DataFldrStr+WNameStr), $(OutBaseNameStr +"_"+Num2Str(i))
		Wave w = $(OutBaseNameStr +"_"+Num2Str(i))
		w=0
		For (j=0; j<NumReps;j+=1)
			WNameStr=StringFromList(StartWaveNum-1+i+WavesPerRep*j, WList, ";")
			Wave w1=$(GetDataFolder(-1)+DataFldrStr+WNameStr)
			w+=w1
			AppendToGraph /W=pt_AvgRepeatWavesDisplay $(GetDataFolder(-1)+DataFldrStr+WNameStr)
			Print "Repeat wave", WNameStr	// 1st Aug , 2007
			Print ""
		EndFor	
		w /=NumReps
		AppendToGraph /W=pt_AvgRepeatWavesDisplay $(OutBaseNameStr +"_"+Num2Str(i))
		SetAxis Bottom DisplayXStart, DisplayXEnd
		SetAxis Left DisplayYStart, DisplayYEnd
		ModifyGraph rgb($(OutBaseNameStr +"_"+Num2Str(i)))=(0,0,0)
		DoUpdate
EndFor	
Else
	Print "Attention! Either WavesPerRep OR NumReps = 0!!! No Wave generated"
EndIf
// Print "Averaging repeat waves, N =", i*j, WList	
Print "Averaging repeat waves, N =", i*j, "from", WList	// as whole wave list is printed, added "from"  07/25/2007
DoWindow pt_AvgRepeatWavesDisplay
	If (V_Flag)
		DoWindow /F pt_AvgRepeatWavesDisplay
		Sleep 00:00:02
		DoWindow /K pt_AvgRepeatWavesDisplay
	EndIf

End




Function pt_DiffPrePostWaves()

// This is always the latest function

// WavesPerRep not being used. commenting it out 11_21_2007

String LastUpdatedMM_DD_YYYY="11_21_2007"

Print "*********************************************************"
Print "pt_DiffPrePostWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


String	PreWaveMatchStr, PostWaveMatchStr, OutBaseNameStr, OutNameStr

//Variable	WavesPerRep
String 	PreWList, PostWList, WNameStr
Variable i, PreNumwaves, PostNumwaves

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_DiffPrePostWaves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_DiffPrePostWaves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_DiffPrePostWaves!!!"
EndIf

PrintAnalPar("pt_DiffPrePostWaves")

PreWaveMatchStr				=	AnalParW[0]
PostWaveMatchStr				=	AnalParW[1]
OutBaseNameStr					=	AnalParW[2]	
//WavesPerRep					=	Str2Num(AnalParW[3])



PreWList=pt_SortWavesInFolder(PreWaveMatchStr, GetDataFolder(-1))
PreNumwaves=ItemsInList(PreWList, ";")
PostWList=pt_SortWavesInFolder(PostWaveMatchStr, GetDataFolder(-1))
PostNumwaves=ItemsInList(PostWList, ";")

Print "Calculating difference between waves, NPre =", PreNumwaves, PreWList, "NPost=", PostNumwaves, PostWList


//Print "Averaging repeats in waves",WList

If (PreNumwaves==PostNumwaves)
	For (i=0; i<PreNumwaves; i+=1)
			Print "Pre=", StringFromList(i, PreWList, ";"), "Post=", StringFromList(i, PostWList, ";")
			Duplicate /O	$(StringFromList(i, PreWList, ";")), $(OutBaseNameStr +"_"+Num2Str(i))
			Wave w = $(OutBaseNameStr +"_"+Num2Str(i))
			WNameStr=StringFromList(i, PostWList, ";")
			Wave w1 = $WNameStr
			w -=w1
	EndFor	
Else
	Print "Num Pre waves Not equal to Num Post Waves"
EndIf

End

Function pt_OperateOn2Waves()
// modified to operate on multiple waves matching the DataWaveMatchStr and
// also instead of choosing bigger of the dimension of pair of waves to be acted on choose smaller dimension 	06/09/2009
String Wave1MatchStr, Wave2MatchStr, OutBaseNameStr, OperationString
String W1List, W2List, w1str, w2str, OutWNameStr
Variable Num, Numwaves1, Numwaves2, i

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_OperateOn2Waves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_OperateOn2Waves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_OperateOn2Waves!!!"
EndIf

PrintAnalPar("pt_OperateOn2Waves")


Wave1MatchStr					=	AnalParW[0]
Wave2MatchStr					=	AnalParW[1]
OutBaseNameStr					=	AnalParW[2]	
OperationString					=	AnalParW[3]


W1List=pt_SortWavesInFolder(Wave1MatchStr, GetDataFolder(-1))
Numwaves1=ItemsInList(W1List, ";")
W2List=pt_SortWavesInFolder(Wave2MatchStr, GetDataFolder(-1))
Numwaves2=ItemsInList(W2List, ";")



If (Numwaves1 == Numwaves2)  // modified 03_23_2007

For (i=0; i<NumWaves1; i+=1)
w1str=StringFromList(i, W1List, ";")
w2str=StringFromList(i, W2List, ";")

Wave w1	=	$w1str
Wave w2	=	$w2str

If (Numpnts(w2) != Numpnts(w1))
	Print "Warning! Unequal number of points in waves", w1str, w2str
EndIf

Num = (Numpnts(w2) >= NumPnts(w1)) ? Numpnts(w1) : Numpnts(w2)    // choose smaller dimension
OutWNameStr=OutBaseNameStr + "_"+Num2Str(i)
Make /O/N=(Num) $(OutWNameStr)
Wave w	=	$(OutWNameStr)
w = Nan
	StrSwitch(OperationString)

		Case "Add":
			w=w1+w2
			Print  OutWNameStr, "=", w1str, "+", w2str
		Break
		Case "Subtract":
			w=w1-w2
			Print OutWNameStr, "=", w1str, "-", w2str
		Break
		Case "Multiply":
			w=w1*w2
			Print OutWNameStr, "=", w1str, "*", w2str
		Break
		Case "Divide":
			w=w1/w2
			Print  OutWNameStr, "=", w1str, "/", w2str
		Break
		Case "PercentDel":
			w=100*((w1/w2)-1)
			Print  OutWNameStr, "=", "100*((",w1str, "/", w2str,") -1)"
		Break
		Default:
			Print "Error: OperationString should be one of 'Add'; ''Subtract'; 'Multiply'; 'Divide' "
	EndSwitch
EndFor
Print "                                                               "
Print "Number of waves operated on",i		
Else
	Print "Unequal number of waves Waves1 and Waves2. No Operation performed..."
EndIf		

End


Function pt_PeakAnal()


// This is always the latest version. (Based on pt_Spike Anal)

//If (DecayTWTemp < DecayTThresh); PkSelected  =0	// remove events for which decay is reached too fast 10/30/13
// changed returning to baseline from 5% to 20% baseline (PostBLLevel = PreBLYWTemp[0] + 0.2*abs(PreBLYWTemp[0])	// 20% of baseline 10/29/13. )
// also changed TtoBLThresh to 2 ms. 10/29/13
// Added the option to also use specified peak threshold, when using noise related thresholds to weed out very small peaks. 10/28/13
// In noise relative threshold the peak will be selected it is > noise relative thresh and also PkAmpRelThreshOrig, 10/28/13
// The box filter gives a shifted trace and also it is difficult to quantify what frequencies are being filtered out. 10/17/13
 // Switched from using box smoothing, to using FIR (finite impulse response) filter. (IIR filter gives a shifted trace). 10/17/13
 // STILL TO DO. CORRECT OTHER PARS LIKE BASEINE Y VALUE SO THAT THEY ARE CALCULATED FROM RAW WAVE NOT BACKGROUND
 // SUBTRACTED WAVE. 
// switched from smoothing being used only for peak detection in derivative, to all calculations. 10/17/13
// modified so that the saved absolute Y values, are calculated from raw data and not from baseline subtracted data 10/17/13
// added option to subtract baseline using SubtractBL 10/16/13
// re-introducing the option of using absolute anplitude and derivative thesholds rather than only noise relative
// thresholds. The parameter is 'UseNoiseRelThresh' 10/7/13
// add the trace name in comment string. That way analysis and trace can be linked more
// accurately (in case some waves are excluded in analysis) 09/24/13
// added DoNotCropPeaks to save memory. 07/14/13
// added NumType(BLNoiseWTemp) !=0 to warn about waves where some data is missing(bad acquisition) 07/14/13
//	DrawText 0.8,0.4,WNAmeStr // print at multiple locations so that the name is not hidden by trace 07/14/13


// Allow the baseline to reach within 95% of pre-event baseline 07/07/13
// // changed Numiters from 2 to 4 on 7/7/13
// Allow ExcludeWNamesWStr to be empty ie. No ExcludeW is specified10/30/12 
// coded rise time calculation 09/04/12
// Use the following to see what is saved after 1st Iter
		//If (Iter==1)
			//Abort "Aborting"	// to see what data is saved after 1st Iter; Only things stored are PkAmpThreshW, DerivAbsThreshW. All the subfolders and waves in cell folder are empty
		//EndIf
// ToDo:
//1. if not using noise related thresholds then no need to do multiple iterations (NumIters=1)
// 2. Allow for baseline return to be only a fraction of original baseline level (like 95%). DONE
// 3. Allow Numiter to be determined by no further change in amplitude and derivative noise. 07/07/13
// Modified to allow specification of thresholds as multiples of standard dev. of raw data (PkAmpThreshTimesSD) and derivative of smooth data (DerivAbsThreshTimesSD) 07/24/12
// also allow a separate BLAvgWin that can be set to be longer than PkAvgWin (used to be AvgWin)//07/24/12
// Previous analysis was not getting killed because of an extra colon in
// If (DataFolderExists(BaseNameStr+"PeakAbsXF:")). Removed colon in all instances  02/21/12

// Logic 
// 1. Low pass filter the data
// 2. Take derivative.
// 3. If zeroth iteration ,use the whole trace for estimating noise. On subsequent iterations, use
// the trace from which some events above current noise threshold have been removed,
// to calculate a better estimate of noise. 
// 4. The events have sharp rise which gives a peak in the derivative. Find peaks in derivative 
// above the noise related threshold for derivative. 
// 5. Find peak in original data by finding zero crossing after peak in the derivative. A better
// estimate of peak position in original data is obtained by looking for max. or min. (depending 
// on polarity) in the original data in the window that starts at peak in derivative and ends at 
// zero crossing in derivative.
// 6. Find peak value by averaging over a small window around the peak.
// 7. Find baseline before and after the peak. 
// 8. If peak returns to baseline before a minimum time, reject the peak. Useful for rejecting
// sharp, short lasting noise. 
// 9. Accept peak if it is above amplitude threshold defined by noise. 
// 10. Find rise time. 
// 11. Decay time is found by finding where the peak returns to exp(-1) of the peak value. 
// 12. Clip the peak from next iteration to get a better estimate of noise. 
// 13. Display results. 
// 14. Find non-overlapping peaks (peaks that are separated by a minimum time). 
// 15. Crop non-overlapping peaks.
// 16. Find decay times corresponding to non-overlapping peaks.
 
String DataWaveMatchStr, DataFldrStr, BaseNameStr, PkAmpThreshTimesSD, DerivThreshTimesSD
Variable StartX, EndX, BoxSmoothingPnts, PkPolarity, TtoBLThresh, RefractoryPeriod, OverlapPksDelT, CropPreMaxSlpDelT, CropPostMaxSlpDelT, tExpFitStart, tExpFitEnd	
Variable DerivAbsThresh, PkAvgWin, AlertMessages, DisplayResults, BLAvgWin, DoNotCropPeaks	, NumIters=4 // changed Numiters from 2 to 4 on 7/7/13
Variable UseNoiseRelThresh, SubtractBL, PassBandEndFreq, RejectBandStartFreq, DecayTThresh


String WList, WNameStr, TraceNameStr1,TraceNameStr2
String LastUpdatedMM_DD_YYYY="07_24_2012"
Variable NumWaves, i, XOffset, XDelta, x1,x2, j, NumNoOLPks, PkSelected=0, k, NDups=0, Oldx1, OldPkXWTemp, Iter, PostBLLevel, PkAmpRelThreshOrig
Variable UsePkAmpNoiseThresh=0, UseDerivNoiseThresh=0, PkAmpThreshTimesSDVal, DerivThreshTimesSDVal, PkAmpRelThresh, BLNoiseWarnThresh

/////String ExpDataWaveMatchStr, ExpDataFldrStr, ExpIgorFitFuncName, ExpXDataWaveMatchStr, ExpStartXVal, ExpEndXVal, ExpDisplayFit			// Pars for pt_CurveFit
					
String NthPntDataWaveMatchStr, NthPntPntNum, NthPntDestWName, NthPntWList, NthPntSubDataFldr, ExcludeWNamesWStr	// Pars for pt_NthPntWave
Variable PkRiseLev1Y, PkRiseLev2Y, PkRiseLev1X, PkRiseLev2X, RiseTPercent // 0.1=10-90% rise time, 0.1=20-80% rise time
Variable PkDecayLev1Y


Print "*********************************************************"
Print "pt_PeakAnal last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"



//Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_SynRespAnal"+"ParNamesW")
//Wave /T AnalParW			=	$("root:FuncParWaves:pt_SynRespAnal"+"ParW")
//If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
//	Abort	"Cudn't find the parameter wave pt_SynRespAnalParW!!!"
//EndIf


Wave /T AnalParW			=	$pt_GetParWave("pt_PeakAnal", "ParW")	// wasn't checking locally first. modified 08/21/2007
																				//	First check locally, then in FuncParWaves
																				
																	
																		
PrintAnalPar("pt_PeakAnal")


DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]

StartX					=	Str2Num(AnalParW[2])
EndX					=	Str2Num(AnalParW[3]) 
PkPolarity				=	Str2Num(AnalParW[4])
PkAvgWin				=	Str2Num(AnalParW[5])
PkAmpRelThresh		=	Str2Num(AnalParW[6])

PkAmpRelThreshOrig	=	PkAmpRelThresh

TtoBLThresh			=	Str2Num(AnalParW[7])
RefractoryPeriod		=	Str2Num(AnalParW[8])
OverlapPksDelT			=    Str2Num(AnalParW[9])
CropPreMaxSlpDelT		=    Str2Num(AnalParW[10])
CropPostMaxSlpDelT	=    Str2Num(AnalParW[11])

tExpFitStart			=    Str2Num(AnalParW[12])
tExpFitEnd				=    Str2Num(AnalParW[13])

BoxSmoothingPnts		= 	Str2Num(AnalParW[14]) 
DerivAbsThresh			= 	Str2Num(AnalParW[15])



BaseNameStr			=	AnalParW[16]
AlertMessages			=	Str2Num(AnalParW[17])
DisplayResults			=	Str2Num(AnalParW[18])
If (AlertMessages)    // incorporated alert message for SpikeThreshWin increase 05_03_2008
	DoAlert 1, "Recent changes:"
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf
PkAmpThreshTimesSD 	= 	AnalParW[19]	//07/24/12
DerivThreshTimesSD   	= 	AnalParW[20]	//07/24/12
BLAvgWin			     	=	Str2Num(AnalParW[21])	//07/24/12
ExcludeWNamesWStr   	=	AnalParW[22]
If (!StringMatch(ExcludeWNamesWStr,""))	//10/30/12 
	ExcludeWNamesWStr 	= GetDataFolder(0)+ExcludeWNamesWStr
EndIf
BLNoiseWarnThresh	=    Str2Num(AnalParW[23])
RiseTPercent			= Str2Num(AnalParW[24])
DoNotCropPeaks			= Str2Num(AnalParW[25])
UseNoiseRelThresh		= Str2Num(AnalParW[26])
SubtractBL				= Str2Num(AnalParW[27])
PassBandEndFreq		= Str2Num(AnalParW[28])		// low pass FIR filter
RejectBandStartFreq	= Str2Num(AnalParW[29])
DecayTThresh			= Str2Num(AnalParW[30])



If (UseNoiseRelThresh == 1)

//If (StringMatch(PkAmpThreshTimesSD,"")==0)
	//UsePkAmpNoiseThresh=1
	PkAmpThreshTimesSDVal= Str2Num(AnalParW[19])
//EndIf

//If (StringMatch(DerivThreshTimesSD,"")==0)
	//UseDerivNoiseThresh=1
	DerivThreshTimesSDVal= Str2Num(AnalParW[20])
//EndIf
EndIf

If (UseNoiseRelThresh == 0)
	NumIters = 1
EndIf
Print "***************************"
Print "NumIters = ", NumIters
Print "***************************"

// using 5 slashes (/////) to comment out the old statements for exp fitting 10/30/12
/////Wave /T ExpAnalParW	=$pt_GetParWave("pt_CurveFitEdit", "ParW")		// for fitting exponential decay to non-overlapping minins

/////ExpDataWaveMatchStr		=	ExpAnalParW[0]
/////ExpDataFldrStr				=	ExpAnalParW[1]
//ExpIgorFitFuncName		=	ExpAnalParW[2]
/////ExpStartXVal				=	ExpAnalParW[2]
/////ExpEndXVal					=	ExpAnalParW[3]
/////ExpDisplayFit				=	ExpAnalParW[4]
/////ExpXDataWaveMatchStr		=	ExpAnalParW[5]

//ExpAnalParW[0]			= 	// specified later in the prog
/////ExpAnalParW[1]			=	BaseNameStr+"CropPksF:"
//ExpAnalParW[2]			=	"exp_XOffset"
/////ExpAnalParW[2]			=	AnalParW[12]	//tExpFitStart
/////ExpAnalParW[3]			=	AnalParW[13]	//tExpFitEnd
/////ExpAnalParW[4]			=	"0"//AnalParW[18]	//DisplayResults
/////ExpAnalParW[5]			=	""


/////Wave /T NthPntAnalParW	=$pt_GetParWave("pt_NthPntWave", "ParW")		// for extracting TauD from the coeff waves.


/////NthPntDataWaveMatchStr	=	NthPntAnalParW[0]
/////NthPntPntNum				=	NthPntAnalParW[1]
/////NthPntDestWName			=	NthPntAnalParW[2]
/////NthPntWList				= 	NthPntAnalParW[3]	//modified to specify WList in parameter wave. This will cause a NAN value for non-existing waves. 
/////NthPntSubDataFldr			=	NthPntAnalParW[4]

//NthPntAnalParW[0]		= 	// specified later in the prog
/////NthPntAnalParW[1]		=	"2"
//NthPntAnalParW[2]		=	// specified later in the prog
/////NthPntAnalParW[3]		=	""
/////NthPntAnalParW[4]		=	BaseNameStr+"CropPksF:"


Make 	/O/N=0			$(BaseNameStr+"NumPksW")
Make 	/O/N=0			$(BaseNameStr+"FreqPksW")
Make 	/O/N=0			$(BaseNameStr+"PkXW")
Make 	/O/N=0			$(BaseNameStr+"PkYW")
Make 	/O/N=0			$(BaseNameStr+"PreBLXW")
Make 	/O/N=0			$(BaseNameStr+"PreBLYW")
Make 	/O/N=0			$(BaseNameStr+"PostBLXW")
Make 	/O/N=0			$(BaseNameStr+"PostBLYW")
Make 	/O/N=0			$(BaseNameStr+"PkAmpRelW")
Make 	/O/N=0			$(BaseNameStr+"MaxRiseXW")
Make 	/O/N=0			$(BaseNameStr+"PkAmpThreshW")
Make 	/O/N=0			$(BaseNameStr+"DerivAbsThreshW")
Make 	/O/N=0			$(BaseNameStr+"BLNoiseW")
Make 	/O/N=0			$(BaseNameStr+"BLSmthDiffNoiseW")
Make 	/O/N=0/T		$(BaseNameStr+"NoisyBLW")
Make 	/O/N=0			$(BaseNameStr+"RiseTW")
Make 	/O/N=0			$(BaseNameStr+"DecayTW")


Wave NumPksW					= $(BaseNameStr+"NumPksW")
Wave FreqPksW 				= $(BaseNameStr+"FreqPksW")
Wave  PkXW					= $(BaseNameStr+"PkXW")
Wave  PkYW					= $(BaseNameStr+"PkYW")
Wave  PreBLXW					= $(BaseNameStr+"PreBLXW")
Wave  PreBLYW					= $(BaseNameStr+"PreBLYW")
Wave  PostBLXW				= $(BaseNameStr+"PostBLXW")
Wave  PostBLYW				= $(BaseNameStr+"PostBLYW")
Wave  PkAmpRelW				= $(BaseNameStr+"PkAmpRelW")
Wave  MaxRiseXW				= $(BaseNameStr+"MaxRiseXW")
Wave  PkAmpThreshW			= $(BaseNameStr+"PkAmpThreshW")
Wave  DerivAbsThreshW		= $(BaseNameStr+"DerivAbsThreshW")
Wave  BLNoiseW				= $(BaseNameStr+"BLNoiseW")
Wave  BLSmthDiffNoiseW		= $(BaseNameStr+"BLSmthDiffNoiseW")
Wave  /T NoisyBLW				= $(BaseNameStr+"NoisyBLW")
Wave  RiseTW					= $(BaseNameStr+"RiseTW")
Wave  DecayTW					= $(BaseNameStr+"DecayTW")



Make 	/O/N=1		$(BaseNameStr+"NumPksWTemp")
Make 	/O/N=1		$(BaseNameStr+"FreqPksWTemp")
Make 	/O/N=1		$(BaseNameStr+"PkXWTemp")
Make 	/O/N=1		$(BaseNameStr+"PkYWTemp")
Make 	/O/N=1		$(BaseNameStr+"PkYNoBWTemp")
Make 	/O/N=1		$(BaseNameStr+"PreBLXWTemp")
Make 	/O/N=1		$(BaseNameStr+"PreBLYWTemp")
Make 	/O/N=1		$(BaseNameStr+"PostBLXWTemp")
Make 	/O/N=1		$(BaseNameStr+"PostBLYWTemp")
Make 	/O/N=1		$(BaseNameStr+"PkAmpRelWTemp")
Make 	/O/N=1		$(BaseNameStr+"MaxRiseXWTemp")

Make 	/O/N=1		$(BaseNameStr+"MaxRiseYWTemp")
Make 	/O/N=1		$(BaseNameStr+"TauDWTemp")

Make 	/O/N=1		$(BaseNameStr+"PkAmpThreshWTemp")
Make 	/O/N=1		$(BaseNameStr+"DerivAbsThreshWTemp")
Make 	/O/N=1		$(BaseNameStr+"BLNoiseWTemp")
Make 	/O/N=1		$(BaseNameStr+"BLSmthDiffNoiseWTemp")
Make 	/O/N=1/T	$(BaseNameStr+"NoisyBLWTemp")
Make 	/O/N=1		$(BaseNameStr+"RiseTWTemp")
Make 	/O/N=1		$(BaseNameStr+"DecayTWTemp")


Wave NumPksWTemp 			= $(BaseNameStr+"NumPksWTemp")
Wave FreqPksWTemp			= $(BaseNameStr+"FreqPksWTemp")
Wave  PkXWTemp				= $(BaseNameStr+"PkXWTemp")
Wave  PkYWTemp				= $(BaseNameStr+"PkYWTemp")
Wave  PkYNoBWTemp			= $(BaseNameStr+"PkYNoBWTemp")
Wave  PreBLXWTemp			= $(BaseNameStr+"PreBLXWTemp")
Wave  PreBLYWTemp			= $(BaseNameStr+"PreBLYWTemp")
Wave  PostBLXWTemp			= $(BaseNameStr+"PostBLXWTemp")
Wave  PostBLYWTemp			= $(BaseNameStr+"PostBLYWTemp")
Wave  PkAmpRelWTemp			= $(BaseNameStr+"PkAmpRelWTemp")
Wave  MaxRiseXWTemp			= $(BaseNameStr+"MaxRiseXWTemp")

Wave  MaxRiseYWTemp			= $(BaseNameStr+"MaxRiseYWTemp")
Wave  TauDWTemp				= $(BaseNameStr+"TauDWTemp")

Wave  PkAmpThreshWTemp		= $(BaseNameStr+"PkAmpThreshWTemp")
Wave  DerivAbsThreshWTemp	= $(BaseNameStr+"DerivAbsThreshWTemp")
Wave  BLNoiseWTemp			= $(BaseNameStr+"BLNoiseWTemp")
Wave  BLSmthDiffNoiseWTemp	= $(BaseNameStr+"BLSmthDiffNoiseWTemp")
Wave  /T NoisyBLWTemp		= $(BaseNameStr+"NoisyBLWTemp")
Wave  RiseTWTemp			= $(BaseNameStr+"RiseTWTemp")
Wave  DecayTWTemp			= $(BaseNameStr+"DecayTWTemp")



WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
If (!StringMatch(ExcludeWNamesWStr,""))	//10/30/12 
	Wlist = pt_ExcludeFromWList(ExcludeWNamesWStr, Wlist)		// added 08_30_12
EndIf


Numwaves=ItemsInList(WList, ";")

If (NumWaves>0)
	// Kill previous analysis so that the results don't get mixed in


	Print "Deleting previous analysis..."

	DoWindow pt_PeakAnalDisplay
	If (V_Flag)
		DoWindow /F pt_PeakAnalDisplay
	//		Sleep 00:00:01
		DoWindow /K pt_PeakAnalDisplay
	EndIf
	
	Wave /T KWAnalParW			=	$pt_GetParWave("pt_KillWFrmFldrs", "ParW")	// wasn't checking locally first. modified 08/21/2007

	String OldDataWaveMatchStr			=		KWAnalParW[0]
	String OldSubFldr						= 		KWAnalParW[2]

	KWAnalParW[0] = BaseNameStr+"*"

	//1
	If (DataFolderExists(BaseNameStr+"PkXF"))
		KWAnalParW[2] = BaseNameStr+"PkXF:"
		pt_KillWFrmFldrs()
	EndIf

	//2
	If (DataFolderExists(BaseNameStr+"PkYF"))
		KWAnalParW[2] = BaseNameStr+"PkYF:"
		pt_KillWFrmFldrs()
	EndIf

	//3
	If (DataFolderExists(BaseNameStr+"PreBLXF"))
		KWAnalParW[2] = BaseNameStr+"PreBLXF:"
		pt_KillWFrmFldrs()
	EndIf

	//4
	If (DataFolderExists(BaseNameStr+"PreBLYF"))
		KWAnalParW[2] = BaseNameStr+"PreBLYF:"
		pt_KillWFrmFldrs()
	EndIf

	//5
	If (DataFolderExists(BaseNameStr+"PostBLXF"))
		KWAnalParW[2] = BaseNameStr+"PostBLXF:"
		pt_KillWFrmFldrs()
	EndIf

	//6
	If (DataFolderExists(BaseNameStr+"PostBLYF"))
		KWAnalParW[2] = BaseNameStr+"PostBLYF:"
		pt_KillWFrmFldrs()
	EndIf

	//7
	If (DataFolderExists(BaseNameStr+"PkAmpRelF"))
		KWAnalParW[2] = BaseNameStr+"PkAmpRelF:"
		pt_KillWFrmFldrs()
	EndIf

	//8
	If (DataFolderExists(BaseNameStr+"NoOLPksF"))
		KWAnalParW[2] = BaseNameStr+"NoOLPksF:"
		pt_KillWFrmFldrs()
	EndIf

	//9
	If (DataFolderExists(BaseNameStr+"MaxRiseXF"))
		KWAnalParW[2] = BaseNameStr+"MaxRiseXF:"
		pt_KillWFrmFldrs()
	EndIf

	//10
	If (DataFolderExists(BaseNameStr+"CropPksF"))
		KWAnalParW[2] = BaseNameStr+"CropPksF:"
		pt_KillWFrmFldrs()
	EndIf

	//11
	If (DataFolderExists(BaseNameStr+"TauDF"))	
		KWAnalParW[2] = BaseNameStr+"TauDF:"
		pt_KillWFrmFldrs()
	EndIf

	//12
	If (DataFolderExists(BaseNameStr+"RejPkXF"))
		KWAnalParW[2] = BaseNameStr+"RejPkXF:"
		pt_KillWFrmFldrs()
	EndIf

	//13
	If (DataFolderExists(BaseNameStr+"RejPkYF"))
		KWAnalParW[2] = BaseNameStr+"RejPkYF:"
		pt_KillWFrmFldrs()
	EndIf
	
	//14
	If (DataFolderExists(BaseNameStr+"RiseTF"))	
		KWAnalParW[2] = BaseNameStr+"RiseTF:"
		pt_KillWFrmFldrs()
	EndIf
	
	//15
	If (DataFolderExists(BaseNameStr+"DecayTF"))	
		KWAnalParW[2] = BaseNameStr+"DecayTF:"
		pt_KillWFrmFldrs()
	EndIf


	KWAnalParW[0] = OldDataWaveMatchStr
	KWAnalParW[2] = OldSubFldr

EndIf

Print "Analyzing spikes for waves, N =", ItemsInList(WList, ";"), WList

For (i=0; i<NumWaves; i+=1)	// Start: iterate through NumWaves
	WNameStr=StringFromList(i, WList, ";")
	For (Iter=0;Iter<NumIters;Iter+=1)	// Start: iterate through NumIters (ie. find minis, get baseline without minis, recalculate noise, repeat)
		Print "***************************"
		Print "Iteration # =",Iter//+1 7/7/13
		//If (Iter==1)
			//Abort "Aborting"	// to see what data is saved after 1st Iter; Only things stored are PkAmpThreshW, DerivAbsThreshW. All the subfolders and waves in cell folder are empty
		//EndIf
		//
		Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), wRaw, WRawB //  WRawB is with background subtracted
		
		
		//Smooth /B BoxSmoothingPnts, $"wSmth"
		If (SubtractBL ==1)
			Wave /T AnalParNamesW	=	$pt_GetParWave("pt_RemoveBLPoly", "ParNamesW")		// check in local folder first 07/23/2007
			Wave /T AnalParW			=	$pt_GetParWave("pt_RemoveBLPoly", "ParW")
			SaveNRestore("pt_RemoveBLPoly", 1)
			AnalParW[0]	=		"wRaw"					//DataWaveMatchStr
			AnalParW[1]	=		""						//DataFldrStr
			AnalParW[2]	=		""						//SubFldr
			AnalParW[3]	=		"3"						//NPoly
			AnalParW[4]	=		Num2Str(StartX)		//StartX
			AnalParW[5]	=		Num2Str(EndX)		//EndX
			pt_RemoveBLPoly()
			Print "Subtracted baseline for", WNameStr
			SaveNRestore("pt_RemoveBLPoly", 2)
		EndIf
		XOffset = DimOffset(wRaw,0)
		XDelta = DimDelta(wRaw,0)
		
		Duplicate /O wRaw, $"wSmth"
		Make/O/D/N=0 coefs
		FilterFIR/DIM=0/LO={XDelta*PassBandEndFreq, XDelta*RejectBandStartFreq,101}/COEF coefs, $"wSmth"// filtered
		KillWaves /z coefs
		
		Duplicate /O wRawB, $"wSmthB" // with background subtracted
		Make/O/D/N=0 coefs
		FilterFIR/DIM=0/LO={XDelta*PassBandEndFreq, XDelta*RejectBandStartFreq,101}/COEF coefs, $"wSmthB"// filtered
		KillWaves /z coefs
		
		//Smooth /B BoxSmoothingPnts, $"wSmthB"
		Duplicate /O $"wSmthB", wSmthBDiff
		Differentiate wSmthBDiff
		Duplicate /O wSmthBDiff, wSmthBDiffSmth
		//Smooth /B BoxSmoothingPnts, wSmthBDiffSmth
		Make/O/D/N=0 coefs
		FilterFIR/DIM=0/LO={XDelta*PassBandEndFreq, XDelta*RejectBandStartFreq,101}/COEF coefs, $"wSmthBDiffSmth"// filtered
		KillWaves /z coefs

		NumPksWTemp[0]=0; x1=StartX; x2=EndX;
	
		//If (UsePkAmpNoiseThresh)
			If (Iter==0)
				Wavestats/Q /R=(x1,x2) wSmthB//wRawB
				//Duplicate /O wRawB, $(GetDataFolder(-1)+DataFldrStr+"wNextIter")
				Duplicate /O wSmthB, $(GetDataFolder(-1)+DataFldrStr+"wNextIter")
				Wave wNextIter = $(GetDataFolder(-1)+DataFldrStr+"wNextIter")
			Else
				Wavestats/Q /R=(x1,x2) wNextIter
				
			EndIf
			BLNoiseWTemp[0]=V_SDev
			If (UseNoiseRelThresh == 1)
				PkAmpThreshWTemp[0]= PkAmpThreshTimesSDVal*V_SDev
				// called relative threshold because the relative peak height is compared against it
				PkAmpRelThresh = (PkPolarity==1) ? PkAmpThreshWTemp[0] : -1*PkAmpThreshWTemp[0]
				Print "Using noise related and absolute threshold for amplitude", PkAmpRelThresh, PkAmpRelThreshOrig  
			Else
				Print "Using absolute threshold and absolute for amplitude", PkAmpRelThresh, PkAmpRelThreshOrig  
			EndIf
			If (Iter==(NumIters-1))	// final iteration
				Concatenate /NP {BLNoiseWTemp}, BLNoiseW
				Concatenate /NP {PkAmpThreshWTemp}, PkAmpThreshW
				// added NumType(BLNoiseWTemp) !=0 to warn about waves where some data is missing(bad acquisition) 07/14/13 
				If ((BLNoiseWTemp[0]>BLNoiseWarnThresh) || (NumType(BLNoiseWTemp) !=0 ))
					NoisyBLWTemp[0]=WNameStr
					Print "Warning - High baseline noise", BLNoiseWTemp[0], "for", WNameStr,"!!!!"
					Concatenate /T/NP {NoisyBLWTemp}, NoisyBLW
					
				EndIf
			EndIf
			//Print "Using noise related threshold for amplitude", PkAmpRelThresh
		//EndIf
	
		//If (UseDerivNoiseThresh)
			If (Iter==0)
				Wavestats/Q /R=(x1,x2) wSmthBDiffSmth//wRaw
				Duplicate /O wSmthBDiffSmth, $(GetDataFolder(-1)+DataFldrStr+"wSmthBDiffSmthNextIter")
				Wave wSmthBDiffSmthNextIter = $(GetDataFolder(-1)+DataFldrStr+"wSmthBDiffSmthNextIter")
			Else
				Wavestats/Q /R=(x1,x2) wSmthBDiffSmthNextIter//wRaw
			EndIf
			BLSmthDiffNoiseWTemp[0]=V_SDev
			If (UseNoiseRelThresh == 1)
			DerivAbsThreshWTemp[0]= DerivThreshTimesSDVal*V_SDev
			// called absolute threshold because the absolute peak y-value is compared against it in FindPeak
			DerivAbsThresh = (PkPolarity==1) ? DerivAbsThreshWTemp[0] : -1*DerivAbsThreshWTemp[0] 
				Print "Using noise related threshold for Deriv", DerivAbsThresh
			Else
				Print "Using absolute threshold for Deriv", DerivAbsThresh
			EndIf
			
			If (Iter==(NumIters-1))	// final iteration
				Concatenate /NP {BLSmthDiffNoiseWTemp}, BLSmthDiffNoiseW
				Concatenate /NP {DerivAbsThreshWTemp}, DerivAbsThreshW
			EndIf
			
		//EndIf


		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PkXF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PkXF:"+BaseNameStr+"PkXW"+Num2Str(i))
		Wave PkXWi = $(GetDataFolder(1)+BaseNameStr+"PkXF:"+BaseNameStr+"PkXW"+Num2Str(i))
		Note /k PkXWi "TraceName:"+WNameStr


		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PkYF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PkYF:"+BaseNameStr+"PkYW"+Num2Str(i))
		Wave PkYWi = $(GetDataFolder(1)+BaseNameStr+"PkYF:"+BaseNameStr+"PkYW"+Num2Str(i))
		Note /k PkYWi "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PreBLXF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PreBLXF:"+BaseNameStr+"PreBLXW"+Num2Str(i))
		Wave PreBLXWi = $(GetDataFolder(1)+BaseNameStr+"PreBLXF:"+BaseNameStr+"PreBLXW"+Num2Str(i))
		Note /k PreBLXWi "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PreBLYF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PreBLYF:"+BaseNameStr+"PreBLYW"+Num2Str(i))
		Wave PreBLYWi = $(GetDataFolder(1)+BaseNameStr+"PreBLYF:"+BaseNameStr+"PreBLYW"+Num2Str(i))
		Note /k PreBLYWi "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PostBLXF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PostBLXF:"+BaseNameStr+"PostBLXW"+Num2Str(i))
		Wave PostBLXWi = $(GetDataFolder(1)+BaseNameStr+"PostBLXF:"+BaseNameStr+"PostBLXW"+Num2Str(i))
		Note /k PostBLXWi "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PostBLYF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PostBLYF:"+BaseNameStr+"PostBLYW"+Num2Str(i))
		Wave PostBLYWi = $(GetDataFolder(1)+BaseNameStr+"PostBLYF:"+BaseNameStr+"PostBLYW"+Num2Str(i))
		Note /k PostBLYWi  "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PkAmpRelF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PkAmpRelF:"+BaseNameStr+"PkAmpRelW"+Num2Str(i))
		Wave PkAmpRelWi = $(GetDataFolder(1)+BaseNameStr+"PkAmpRelF:"+BaseNameStr+"PkAmpRelW"+Num2Str(i))
		Note /k PkAmpRelWi "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"MaxRiseXF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"MaxRiseXF:"+BaseNameStr+"MaxRiseXW"+Num2Str(i))
		Wave MaxRiseXWi = $(GetDataFolder(1)+BaseNameStr+"MaxRiseXF:"+BaseNameStr+"MaxRiseXW"+Num2Str(i))
		Note /k MaxRiseXWi "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"NoOLPksF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"NoOLPksF:"+BaseNameStr+"NoOLPksW"+Num2Str(i))
		Wave NoOLPksWi = $(GetDataFolder(1)+BaseNameStr+"NoOLPksF:"+BaseNameStr+"NoOLPksW"+Num2Str(i))
		Note /k NoOLPksWi "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"CropPksF")

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"TauDF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"TauDF:"+BaseNameStr+"TauDW"+Num2Str(i))
		Wave TauDWi = $(GetDataFolder(1)+BaseNameStr+"TauDF:"+BaseNameStr+"TauDW"+Num2Str(i))
		Note /k TauDWi  "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"RejPkXF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"RejPkXF:"+BaseNameStr+"RejPkXW"+Num2Str(i))
		Wave RejPkXWi = $(GetDataFolder(1)+BaseNameStr+"RejPkXF:"+BaseNameStr+"RejPkXW"+Num2Str(i))
		Note /k RejPkXWi "TraceName:"+WNameStr

		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"RejPkYF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"RejPkYF:"+BaseNameStr+"RejPkYW"+Num2Str(i))
		Wave RejPkYWi = $(GetDataFolder(1)+BaseNameStr+"RejPkYF:"+BaseNameStr+"RejPkYW"+Num2Str(i))
		Note /k RejPkYWi "TraceName:"+WNameStr
		
		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"RiseTF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"RiseTF:"+BaseNameStr+"RiseTW"+Num2Str(i))
		Wave RiseTWi = $(GetDataFolder(1)+BaseNameStr+"RiseTF:"+BaseNameStr+"RiseTW"+Num2Str(i))
		Note /k RiseTWi "TraceName:"+WNameStr
		
		NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"DecayTF")
		Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"DecayTF:"+BaseNameStr+"DecayTW"+Num2Str(i))
		Wave DecayTWi = $(GetDataFolder(1)+BaseNameStr+"DecayTF:"+BaseNameStr+"DecayTW"+Num2Str(i))
		Note /k DecayTWi "TraceName:"+WNameStr
		
		Make /O/N=1 $(GetDataFolder(1)+BaseNameStr+"DecayTF:"+BaseNameStr+"DecayTW"+Num2Str(i))+"Temp"
		Wave NoOLTauDWiTemp=$(GetDataFolder(1)+BaseNameStr+"DecayTF:"+BaseNameStr+"DecayTW"+Num2Str(i))+"Temp"
		Note /k NoOLTauDWiTemp "TraceName:"+WNameStr



		Print " "
	

		Do
			If (x1>=x2)								// end of pulse reached;
				//Print x1,">=",x2
				//NumPksTemp[0]=NumPks
			
				FreqPksWTemp[0] = NumPksWTemp[0]/abs(EndX-StartX)
				If (Iter==(NumIters-1))
					Concatenate /NP {NumPksWTemp}, NumPksW
					Concatenate /NP {FreqPksWTemp}, FreqPksW
				EndIf
				Print "Number of peaks =",NumPksWTemp[0]
				Break	// finish analyzing this pulse
			EndIf
			Oldx1=x1
			OldPkXWTemp = PkXWTemp[0]	
			If (PkPolarity==1) // It's a maxima
				FindPeak 	/M=(DerivAbsThresh) /Q/R=(x1,x2) wSmthBDiffSmth		// find peak in the derivative of smoothed wave
			Else
				FindPeak 	/N/M=(DerivAbsThresh) /Q/R=(x1,x2) wSmthBDiffSmth	// find peak in the derivative of smoothed wave
			EndIf	
			If (V_Flag==0)	// Peak found in derivative
				PkSelected =0
				MaxRiseXWTemp[0] = V_PeakLoc
				MaxRiseYWTemp[0]=  V_PeakVal
				Findlevel /R=(MaxRiseXWTemp[0],EndX)  /Q wSmthBDiffSmth, 0 // zero crossing AFTER the peak in derivative corresponds to the peak in the original data
				If (V_Flag==0)	// level was found
					// Actually, because we are taking the derivative of smoothed data the zero crossing always occurs slightly later than the maxima/minima. Using wavestats to find the true maxima/minima			
					Wavestats /Q/R=(MaxRiseXWTemp[0], V_LevelX) wSmthB//wRawB
					If (PkPolarity==1) // It's a maxima
						PkXWTemp[0] = V_MaxLoc
					Else
						PkXWTemp[0] = V_MinLoc
					EndIf	// It's a maxima
				
				
					x1=V_LevelX+RefractoryPeriod
				
					If (abs(PkXWTemp[0] - OldPkXWTemp )< 1e-5)		// Warn for Duplicate peaks 
						NDups+=1
						Print  "Old X1, OldPkX, X1, PkX, Total # of duplicates",Oldx1, OldPkXWTemp, x1, PkXWTemp[0], NDups
					EndIf
				
					//				PkXWTemp[0] = V_LevelX
					PkYWTemp[0] = mean(wSmthB, PkXWTemp[0] - 0.5*PkAvgWin,  PkXWTemp[0] + 0.5*PkAvgWin)
					PkYNoBWTemp[0] = mean(wSmth, PkXWTemp[0] - 0.5*PkAvgWin,  PkXWTemp[0] + 0.5*PkAvgWin)	// PkY on the raw data (ie No BL correction)
					Findlevel /R=(MaxRiseXWTemp[0], StartX) /Q wSmthBDiffSmth, 0 // zero crossing BEFORE the peak in derivative corresponds to the PreBL in the original data
					If (V_Flag==0)	// level was found
						PreBLXWTemp[0] = V_LevelX - 0.5*BLAvgWin
						PreBLYWTemp[0] = mean(wSmthB, PreBLXWTemp[0] - 0.5*BLAvgWin,  PreBLXWTemp[0] + 0.5*BLAvgWin)
						PkAmpRelWTemp[0] = PkYWTemp[0]-PreBLYWTemp[0]
						//				Print "PreBLYWTemp[0],PkAmpRelThresh, PostBLLevel=",PreBLYWTemp[0],PkAmpRelThresh, PostBLLevel
						//PostBLLevel=PreBLYWTemp[0]//+PkAmpRelThresh
						//Baseline =  10 pA. PkPolarity = 1=> PostBLLevel = 11pA
						//Baseline =  10 pA. PkPolarity = -1=> PostBLLevel = 9pA
						//Baseline =  -10 pA. PkPolarity = 1=> PostBLLevel = -9pA
						//Baseline =  -10 pA. PkPolarity = -1=> PostBLLevel = -11pA
						// Tested to work under both polarities of baseline and peak polarity - 07/07/13. 
						If (PkPolarity==1) // It's a maxima
							//PostBLLevel = PreBLYWTemp[0] + 0.05*abs(PreBLYWTemp[0])	// 5% of baseline 07/07/13. 
							    PostBLLevel = PreBLYWTemp[0] + 0.2*abs(PreBLYWTemp[0])	// 20% of baseline 10/29/13. 
							//Print "PkPolarity, PreBL val., PostBLVal. ", PkPolarity, PreBLYWTemp[0], PostBLLevel 
						Else
							//PostBLLevel = PreBLYWTemp[0] - 0.05*abs(PreBLYWTemp[0])	// 5% of baseline  //07/07/13
							    PostBLLevel = PreBLYWTemp[0] - 0.2*abs(PreBLYWTemp[0])	// 20% of baseline 10/29/13. 
							//Print "PkPolarity, PreBL val., PostBLVal. ", PkPolarity, PreBLYWTemp[0], PostBLLevel
						EndIf // It's a maxima
						
						Findlevel /R=(PkXWTemp[0], EndX) /Q $"wSmthB", PostBLLevel//PreBLYWTemp[0] // crossing of PreBL level in the smoothed data after the peak gives PostBL
						If (V_Flag==0)	// level was found
							PostBLXWTemp[0] = V_LevelX// + 0.5*BLAvgWin
							PostBLYWTemp[0] = mean(wSmthB, PostBLXWTemp[0] - 0.5*BLAvgWin,  PostBLXWTemp[0] + 0.5*BLAvgWin)
				
							If ( (PostBLXWTemp[0] - PkXWTemp[0]) > TtoBLThresh)	// Peak didn't end too early
				
								If (PkPolarity==1) // It's a maxima
									PkSelected = ( PkAmpRelWTemp[0] > PkAmpRelThresh  && PkAmpRelWTemp[0] > PkAmpRelThreshOrig) ? 1 : 0 // 10/28/13
								Else
									PkSelected = (PkAmpRelWTemp[0] < PkAmpRelThresh && PkAmpRelWTemp[0] < PkAmpRelThreshOrig) ? 1 : 0  // 10/28/13
								EndIf // It's a maxima
								
								// calculate rise time - start
								PkRiseLev1Y=PkAmpRelWTemp[0]*(RiseTPercent)+PreBLYWTemp[0]
								PkRiseLev2Y=PkAmpRelWTemp[0]*(1-RiseTPercent)+PreBLYWTemp[0]
										
								Findlevel /R=(PreBLXWTemp[0] , PkXWTemp[0]) /Q wSmthB, PkRiseLev1Y
								If (V_Flag==0)
									PkRiseLev1X=V_LevelX
								Else
									//Print "PkAmpRelWTemp[0],,PreBLYWTemp[0], PkRiseLev1Y, PreBLXWTemp[0] , PkXWTemp[0]), PkRiseLev1X"
									//Print PkAmpRelWTemp[0],PreBLYWTemp[0], PkRiseLev1Y, PreBLXWTemp[0] , PkXWTemp[0], PkRiseLev1X
									PkRiseLev1X=Nan
								EndIf
								
								//Print "PkAmpRelWTemp[0],,PreBLYWTemp[0], PkRiseLev1Y, PreBLXWTemp[0] , PkXWTemp[0]), PkRiseLev1X"
								//Print PkAmpRelWTemp[0],PreBLYWTemp[0], PkRiseLev1Y, PreBLXWTemp[0] , PkXWTemp[0], PkRiseLev1X
										
								Findlevel /R=(PreBLXWTemp[0] , PkXWTemp[0]) /Q wSmthB, PkRiseLev2Y
								If (V_Flag==0)
									PkRiseLev2X=V_LevelX
								Else
									
									//Print "PkAmpRelWTemp[0],,PreBLYWTemp[0], PkRiseLev2Y, PreBLXWTemp[0] , PkXWTemp[0]), PkRiseLev2X"
									//Print PkAmpRelWTemp[0],PreBLYWTemp[0], PkRiseLev2Y, PreBLXWTemp[0] , PkXWTemp[0], PkRiseLev2X
									PkRiseLev2X=Nan
								EndIf
								
								
								
								//Print "PkAmpRelWTemp[0],,PreBLYWTemp[0], PkRiseLev2Y, PreBLXWTemp[0] , PkXWTemp[0]), PkRiseLev2X"
								//Print PkAmpRelWTemp[0],PreBLYWTemp[0], PkRiseLev2Y, PreBLXWTemp[0] , PkXWTemp[0], PkRiseLev2X
										
								RiseTWTemp[0]=PkRiseLev2X-PkRiseLev1X

								//Print "RiseTWTemp[0]",RiseTWTemp[0]
								// calculate rise time - end
								
								// calculate decay time. 
								PkDecayLev1Y= PkAmpRelWTemp[0]*(exp(-1))+PreBLYWTemp[0] // time to decay to exp(-1) of peak value
								//Print "PkAmpRelWTemp[0],PreBLYWTemp[0],PkDecayLev1Y ",PkAmpRelWTemp[0],PreBLYWTemp[0],PkDecayLev1Y 
								Findlevel /R=(PkXWTemp[0], PostBLXWTemp[0]) /Q $"wSmthB" , PkDecayLev1Y//$"wSmth" (less noisy with wRaw)
								If (V_Flag==0)
									DecayTWTemp=V_LevelX-PkXWTemp[0]
									If (DecayTWTemp < DecayTThresh)	// remove events for which decay is reached too fast 10/30/13
										PkSelected  =0
										DecayTWTemp=Nan
									EndIf
								Else
									DecayTWTemp=Nan
								EndIf
								
								If (PkSelected) // Pk is selected
									NumPksWTemp[0] 	+=1
									If (Iter==(NumIters-1))
										Concatenate /NP {PkXWTemp}, PkXW
										Concatenate /NP {PkYNoBWTemp}, PkYW
										Concatenate /NP {PreBLXWTemp}, PreBLXW
										Concatenate /NP {PreBLYWTemp}, PreBLYW
										Concatenate /NP {PostBLXWTemp}, PostBLXW
										Concatenate /NP {PostBLYWTemp}, PostBLYW

										Concatenate /NP {PkAmpRelWTemp}, PkAmpRelW
										Concatenate /NP {MaxRiseXWTemp}, MaxRiseXW
										
				
										Concatenate /NP {PkXWTemp}, PkXWi
										Concatenate /NP {PkYNoBWTemp}, PkYWi
										Concatenate /NP {PreBLXWTemp}, PreBLXWi
										Concatenate /NP {PreBLYWTemp}, PreBLYWi
										Concatenate /NP {PostBLXWTemp}, PostBLXWi
										Concatenate /NP {PostBLYWTemp}, PostBLYWi
										Concatenate /NP {PkAmpRelWTemp}, PkAmpRelWi
										Concatenate /NP {MaxRiseXWTemp}, MaxRiseXWi
								
										Concatenate /NP {RiseTWTemp},RiseTW
										Concatenate /NP {RiseTWTemp},RiseTWi
										Concatenate /NP {DecayTWTemp},DecayTW
										Concatenate /NP {DecayTWTemp},DecayTWi
										
									EndIf
									If (Iter<(NumIters-1))		// don't do on final iteration so that we can see the baseline used for final iteration
										wNextIter[x2pnt(wSmthB, PreBLXWTemp[0]),x2pnt(wSmthB, PostBLXWTemp[0])] = Nan
										wSmthBDiffSmthNextIter[x2pnt(wSmthB, PreBLXWTemp[0]),x2pnt(wSmthB, PostBLXWTemp[0])] = Nan
									EndIf
								Else
									If (Iter==(NumIters-1))
										Concatenate /NP {PkXWTemp}, RejPkXWi
										Concatenate /NP {PkYNoBWTemp}, RejPkYWi
									EndIf
								EndIf	// Pk is selected
				
							Else 	// Peak ended too early
								//Print "Time to BL =", PostBLXWTemp[0]- PkXWTemp[0],"is less than TtoBLThreh",TtoBLThresh
							EndIf	// End: Peak didn't end too early
				
						Else
						EndIf	// Level crossing to find PostBL
				
					Else
					EndIf	// If (V_Flag==0)	// Level crossing to find PreBL
				
				Else // zero crossing AFTER the peak in derivative not found
					x1=MaxRiseXWTemp[0]+RefractoryPeriod
				EndIf	// End: zero crossing AFTER the peak in derivative
			Else	//No more peak found in derivative
				FreqPksWTemp[0] = NumPksWTemp[0]/abs(EndX-StartX)
				If (Iter==(NumIters-1))
					Concatenate /NP {NumPksWTemp}, NumPksW
					Concatenate /NP {FreqPksWTemp}, FreqPksW
				EndIf
					Print "Number of peaks =",NumPksWTemp[0]
				Break 
			EndIf	//If (V_Flag==0)	// Peak found in derivative
		While (1)
	EndFor	//End iterate through NumIters (ie. find minis, get baseline without minis, recalculate noise, repeat)

	If (DisplayResults)
		DoWindow pt_PeakAnalDisplay
		If (V_Flag)
			DoWindow /F pt_PeakAnalDisplay
			//		Sleep 00:00:01
			DoWindow /K pt_PeakAnalDisplay
		EndIf
		Display /W = (0,0,1400,400)
		DoWindow /c pt_PeakAnalDisplay
	
		//	ModifyGraph /W= pt_PeakAnalDisplay width=1400,height=400
		AppendToGraph /W= pt_PeakAnalDisplay wRaw
		SetAxis Bottom StartX,EndX
		SetAxis /A=2 Left
		ModifyGraph rgb(wRaw)=(65535,0,0)
		
		AppendToGraph /W= pt_PeakAnalDisplay wSmth
		ModifyGraph rgb(wSmth)=(0,0,0)
		
		//AppendToGraph  /W= pt_PeakAnalDisplay wNextIter
		//ModifyGraph rgb(wNextIter)=(0,0,0)
	
			//AppendToGraph /W= pt_PeakAnalDisplay /R wSmthDiffSmth
			//TraceNameStr = BaseNameStr+"PkY"
			//ModifyGraph rgb(wSmthDiffSmth)=(52428,52428,52428)
		
		AppendToGraph PkYWi vs PkXWi
		//TraceNameStr = GetDataFolder(1)+BaseNameStr+"PkYF:"+BaseNameStr+"PkYW"+Num2Str(i)
		TraceNameStr1 = BaseNameStr+"PkYW"+Num2Str(i)
		//Print TraceNameStr1
		ModifyGraph mode($TraceNameStr1)=3
		ModifyGraph marker($TraceNameStr1)=19
		ModifyGraph msize($TraceNameStr1)=4
		ModifyGraph rgb($TraceNameStr1)=(26205,52428,1)
		
	
		AppendToGraph RejPkYWi vs RejPkXWi
		//	TraceNameStr = GetDataFolder(1)+BaseNameStr+"PkYF:"+BaseNameStr+"PkYW"+Num2Str(i)
		TraceNameStr2 = BaseNameStr+"RejPkYW"+Num2Str(i)
		//	Print TraceNameStr2
		ModifyGraph mode($TraceNameStr2)=3
		ModifyGraph marker($TraceNameStr2)=19
		ModifyGraph msize($TraceNameStr2)=4
		ModifyGraph rgb($TraceNameStr2)=(1,16019,65535)
	
		//AppendToGraph PreBLYWi vs PreBLXWi
		//TraceNameStr = GetDataFolder(1)+BaseNameStr+"PreBLYF:"+BaseNameStr+"PreBLYW"+Num2Str(i)
		//TraceNameStr = BaseNameStr+"PreBLYW"+Num2Str(i)
		//ModifyGraph mode($TraceNameStr)=3
		//ModifyGraph marker($TraceNameStr)=19
		//ModifyGraph msize($TraceNameStr)=4
		//ModifyGraph rgb($TraceNameStr)=(3,52428,1)
	
		
	
		//AppendToGraph PostBLYWi vs PostBLXWi
		//	TraceNameStr = GetDataFolder(1)+BaseNameStr+"PostBLYF:"+BaseNameStr+"PostBLYW"+Num2Str(i)
		//TraceNameStr = BaseNameStr+"PostBLYW"+Num2Str(i)
		//ModifyGraph mode($TraceNameStr)=3
		//ModifyGraph marker($TraceNameStr)=19
		//ModifyGraph msize($TraceNameStr)=4
		//ModifyGraph rgb($TraceNameStr)=(65535,0,0)
		
		//Legend/C/N=text0/J/F=0/A=RB "\\s(wRaw) Data\r\\s(wNextIter) Baseline\r\\s("+TraceNameStr1+") Selected\r\\s("+TraceNameStr2+") Rejected"
		Legend/C/N=text0/J/F=0/A=RB "\\s(wRaw) Data\r\\s("+TraceNameStr1+") Selected\r\\s("+TraceNameStr2+") Rejected"

		SetDrawEnv fsize= 12;DelayUpdate
		DrawText 0.8,0.4,WNAmeStr // print at multiple locations so that the name is not hidden by trace 07/14/13
		DrawText 0.8,0.55,WNAmeStr
		DrawText 0.8,0.7,WNAmeStr
		DrawText 0.8,0.6,"Num Selected ="+Num2Str(NumPksWTemp[0])
		DrawText 0.8,0.65,"BL Noise ="+Num2Str(BLNoiseWTemp[0])
		
		
		
		DoUpdate
//		Sleep /T 90
		pt_PutTopGraphInNotebook()

	EndIf //End:(DisplayResults)
	
		
	pt_DetectNoOLPks(GetDataFolder(1)+BaseNameStr+"PkXF:"+BaseNameStr+"PkXW"+Num2Str(i), OverlapPksDelT)
	Duplicate /O $GetDataFolder(1)+BaseNameStr+"PkXF:"+BaseNameStr+"PkXW"+Num2Str(i)+"NoOLPks", NoOLPksWi
	KillWaves /Z $GetDataFolder(1)+BaseNameStr+"PkXF:"+BaseNameStr+"PkXW"+Num2Str(i)+"NoOLPks"
	
	Make /O/N=0 $GetDataFolder(1)+BaseNameStr+"DecayTF:"+BaseNameStr+"NoOLDecayTW"+Num2Str(i)//+"NoOLPks"
	Wave NoOLTauDWi=$GetDataFolder(1)+BaseNameStr+"DecayTF:"+BaseNameStr+"NoOLDecayTW"+Num2Str(i)//+"NoOLPks"
	Note /k NoOLTauDWi "TraceName:"+WNameStr
	//	NumNoOLPks = Sum(NoOLPksWi)
	k=0
	For (j=0; j<NumPksWTemp[0]; j+=1) // Start Iterate through NumPks to crop non overlapping peaks
		If 	(NoOLPksWi[j] ==1)
			If (DoNotCropPeaks != 1) // added DoNotCropPeaks to save memory. 07/14/13
				Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"CropPksF:"+BaseNameStr+"CropPksW"+Num2Str(i)+"_"+Num2Str(k))
				Wave CropPksWi_k = $(GetDataFolder(1)+BaseNameStr+"CropPksF:"+BaseNameStr+"CropPksW"+Num2Str(i)+"_"+Num2Str(k))
				Note /k CropPksWi_k "TraceName:"+WNameStr
				//	Print MaxRiseXWi[j], MaxRiseXWi[j]-CropPreMaxSlpDelT, MaxRiseXWi[j]+CropPostMaxSlpDelT
				Duplicate /O /R=(MaxRiseXWi[j]-CropPreMaxSlpDelT, MaxRiseXWi	[j]+CropPostMaxSlpDelT) wRawB, CropPksWi_k  // align at max rise.
				SetScale /P x,0,XDelta, CropPksWi_k
				CropPksWi_k -= PreBLYWi[j]
			EndIf
			NoOLTauDWiTemp[0]=DecayTWi[j]
			Concatenate /NP {NoOLTauDWiTemp}, NoOLTauDWi//[k]=DecayTWi[j]
			k+=1
		EndIf
	EndFor // End Iterate through NumPks to crop non overlapping peaks
	
	// pt_CurveFitEdit() gives wrong values (very high, like in seconds) when the trace isn't very exponential. Switching to finding the point where the trace reaches exp(-1) of peak value
	// using 5 slashes (/////) to comment out the old statements 09/05/12
	
	// CurveFit Start
	/////ExpAnalParW[0]= BaseNameStr+"CropPksW"+Num2Str(i)+"_*"
	/////pt_CurveFitEdit()
	//Extract Tau from coeff waves
	/////NthPntAnalParW[0] = "Cof"+BaseNameStr+"CropPksW"	+Num2Str(i)+"_*"
	/////NthPntAnalParW[2] = "TauD"+BaseNameStr					+Num2Str(i)
	/////pt_NthPntWave()
	
	

	//End Extract Tau from coeff waves
	//
	// Fit exponential to decay to caculate TauD
	//	Make /D/O/N=3 $(GetDataFolder(1)+BaseNameStr+"TauDF:"+BaseNameStr+"TauDW"+Num2Str(i)+"_"+Num2Str(k))      W_FitCoeff = Nan
	////	Make /D/O/N=3 $(GetDataFolder(1)+BaseNameStr+"TauDF:"+"W_FitCoeff")
	////	Wave W_FitCoeff = $(GetDataFolder(1)+BaseNameStr+"TauDF:"+"W_FitCoeff")
	////	W_FitCoeff = Nan
	////	Duplicate /O  CropPksWi_k, $(GetDataFolder(1)+BaseNameStr+"TauDF:"+"fit_w")
	////	Wave fit_w=$(GetDataFolder(1)+BaseNameStr+"TauDF:"+"fit_w")
	////	fit_w= Nan

	////	CurveFit /NTHR=0/TBOX=0/Q exp_XOffset,  kwCWave=W_FitCoeff, CropPksWi_k (tExpFitStart, tExpFitEnd) /D = fit_w


	////	TauDWTemp[0]			= W_FitCoeff[2]
	////	Concatenate /NP {TauDWTemp}, TauDWi


	////	If (		(NumType(W_FitCoeff[0])!=0) || (NumType(W_FitCoeff[1])!=0) || (NumType(W_FitCoeff[2])!=0)		)
	////	Print "																			"
	////	Print "Exponential decay fitting error in wave",Num2Str(i), " in CropPksW", Num2Str(k)
	////	EndIf
	// CurveFit End

	
	
	//kill Coffecient and sigma waves generated by pt_CurveFitEdit

	/////Wave /T KWAnalParW			=	$pt_GetParWave("pt_KillWFrmFldrs", "ParW")	// wasn't checking locally first. modified 08/21/2007

	/////OldDataWaveMatchStr			=		KWAnalParW[0]
	/////OldSubFldr						= 		KWAnalParW[2]

	/////If (DataFolderExists(BaseNameStr+"CropPksF"))
		/////KWAnalParW[2] = BaseNameStr+"CropPksF:"
		/////KWAnalParW[0] = "Cof"+BaseNameStr+"CropPksW"+"*"
		/////pt_KillWFrmFldrs()
		/////KWAnalParW[0] = "Sig"+BaseNameStr+"CropPksW"+"*"
		/////pt_KillWFrmFldrs()
		/////KWAnalParW[0] = "fit_"+BaseNameStr+"CropPksW"+"*"
		/////pt_KillWFrmFldrs()
	/////EndIf

	/////KWAnalParW[0] = OldDataWaveMatchStr
	/////KWAnalParW[2] = OldSubFldr
// using 5 slashes (/////) to comment out the old statements for exp fit 10/30/12
/////	ExpAnalParW[0]			=	ExpDataWaveMatchStr
/////	ExpAnalParW[1]			=	ExpDataFldrStr
	//ExpAnalParW[2]			=	ExpIgorFitFuncName
/////	ExpAnalParW[2]			=	ExpStartXVal
/////	ExpAnalParW[3]			=	ExpEndXVal	
/////	ExpAnalParW[4]			=	ExpDisplayFit
/////	ExpAnalParW[5]			=	ExpXDataWaveMatchStr

	// Restore pt_NthPntWave par values

	/////NthPntAnalParW[0]	=	NthPntDataWaveMatchStr
	/////NthPntAnalParW[1]	=	NthPntPntNum
	/////NthPntAnalParW[2]	=	NthPntDestWName	
	/////NthPntAnalParW[3]	= 	NthPntWList//modified to specify WList in parameter wave. This will cause a NAN value for non-existing waves. 
	/////NthPntAnalParW[4]	=	NthPntSubDataFldr

	
	KillWaves /Z wRaw, wRawB, wSmthB, wSmthBDiff, wSmthBDiffSmth
EndFor	//End iterate through NumWaves
KillWaves /Z NumPksWTemp, FreqPksWTemp, PkXWTemp, PkYWTemp, PkYNoBWTemp, PreBLXWTemp, PreBLYWTemp, PostBLXWTemp, PostBLYWTemp, PkAmpRelWTemp
KillWaves /Z wRaw, wRawB, wSmthB, wSmthBDiff, wSmthBDiffSmth, mIPSCTauDWTemp, PkAmpThreshWTemp, DerivAbsThreshWTemp, NoisyBLWTemp, BLSmthDiffNoiseWTemp, MaxRiseXWTemp, MaxRiseYWTemp
KillWaves /Z RiseTWTemp, DecayTWTemp, NoOLTauDWiTemp
End

Function pt_DetectNoOLPks(PkXWName,  OverlapPksDelT)
// Function to mark peaks as non-overlapping if they are separated from the neighbors by > OverlapPksDelT	

String PkXWName
Variable OverlapPksdelT

Variable i, N

Wave w = $PkXWName
N = NumPnts(w)
Make /O/N=(N) $PkXWName+"NoOLPks"
Wave w1 = $PkXWName+"NoOLPks"
w1 = Nan


For (i=0; i<(N-1); i+=1)
If  (  (w[i+1]-w[i]) <  OverlapPksdelT)
w1[i] = 0
//If (   (i+1) < N ) 
w1[i+1] =0
i+=1
//EndIf
Else
w1[i] =1	// Non-overlapping
EndIf

w1[N-1] = (w1[N-1]==0) ? 0 : 1 // if last peak is not overlapping set it to be non-overlapping

EndFor
Print " "
Print "Found non-overlapping peaks N =", Sum(w1)

End

Function pt_SpikeAnal()
// This is always the latest version.

// switched back to single derivative - while triple derivative was more accurate, the spikes at end of spike trains are slow and
// don't always have a distinct peak in triple derivative. 12/22/14
// having a separate thresh window for 0th peak (Spike0ThreshWin) otherwise the program was detecting the response to
// stim start. 12/22/14
// specifying an absolute threshold such as 10V/s works well except again for slower spikes it gets the threshold too close to the
// action potential peak. 12/22/14
// Having the threshold as a fraction of max slope gets more accurate values for faster and slower spikes (Rony A and Charles MG J Neurosci 1999). 12/22/14
// also  searching for threshold in the forward direction gets the proper threshold. Searching backwards from peak was getting 
// wrong threshold when the AP had a non-monotonic increase in slope (sort of like a double peak merged together). Saw this
// in MSNs in nucleus accumbens in Li Gan' data. 12/22/14


// made changes on 11/18/14.
// using triple derivative. Searrching in forward direction. if peak in triple derivative is not detected, use voltage threshold of previous spike
// as threshold.


//Switching to backward differences which seems to give slope closer to expected x-value. 08/06/14
//Differentiate Diffw	  // 1st
//Differentiate Diff3w	 // 1st
//Differentiate Diff3w 	// 2nd
//Differentiate Diff3w 	// 3rd

//Differentiate/METH=2 Diffw// 1st
//Differentiate/METH=2 Diff3w // 1st
//Differentiate/METH=2 Diff3w // 2nd
//Differentiate/METH=2 Diff3w // 3rd

// start searching for spike thresh from peak towards threshold IN THE DIFF WAVE 08/04/14
// This way we will first cross the threshold rather than get a value from previous peak. 
// seems like if we are reversing the direction of searching, then Edge =1 gives crossing while y-values are decreasing
// and Edge = 2 while y values are increasing. Also, note that we are searching for crossing in the diff wave.
// therefore using Edge = 1 with reversed direction of searching. 

// Earlier I had changed SpikeThreshWin from 4e-3 to 2e-3. But with 4 ms, sometimes for the 1st spike, instead of the spike threshold, the
// increase in slope at start of stim gets detected. Since it doesn't happen for subsequent spikes, reducing the SpikeThreshWin to 3ms might correct
// that problem.  01/10/14


// Tried to modify from using peak in SpikeThreshDblDeriv to peak in SpikeThreshTripleDeriv based on (Henze DA and Buzsaki G, Neuroscience, 2001)
// but that was detecting wrong peak sometimes (essentially detecting the spike peak rather than threshold)
// Using crossing of SpikeThreshDerivLevel by 1st derivativel always. 
// Above changes on 12/24/13

// IMPORTANT: READ THE FLOW OF TEH PROGRAM IN THE COMMENTS BELOW TO UNDERSTAND HOW IT WORKS
// Store the absolute peak values per wave in a separate folder to display in pt_Analysis 10/12/13
// Previous analysis was not getting killed because of an extra colon in
// If (DataFolderExists(BaseNameStr+"PeakAbsXF:")). Removed colon in all instances  02/21/12
// made cropping events optional as cropped events occupy lots of space. 02/21/12

// Modified such that per spike parameters are stored for each data wave in a separate wave along with one long concatenated wave  12/25/2010
// Added FIWSpikeFreq which has the spike frequency averaged from StartX to EndX.
// NB. FIWNUMSPIKES IS THE NUM. OF SPIKES IN THE WAVE AND NOT SPIKE FREQUENCY 12/12/2007

// added ISIMidAbsX (ISI mid-point) and ISVY (Interspike voltage calculated at ISIMid point) 03/14/2009
// changing value of BoxSmoothingPnts from 1 to 5 (= box size for sliding average. for smooth operation by itself this corresponds to num & /B=b 
// is number of iterations of smoothing). with BoxSmoothingPnts=1 FindPeak finds spurious peaks. also found box smoothing with num=5
// gave derivatives that followed original derivatives more closely than derivatives of binomially (num =1) smoothened curve. anyways
// findpeak by itself only has sliding average option. included change in alert messages. default BaseNameStr changed from FI to F_I to distinguish cells 
// analysed with old and new parameter	 05/06/5008
// incorporated alert message for SpikeThreshWin increase 05_03_2008
// changing the value of paramerter SpikeThreshWin from 2e-3 (2ms) to 4e-3 (4ms). i noticed that with 2 ms for some spikes 
// SpikeThreshStartX was not past the threshold crossing, so next threshold crossing near peak was getting detected 
//(voltage slope increases and then decreases between threshold and peak) which falsely made the peak very small. 
//default BaseNameStr changed from FI to F_I to distinguish cells analysed with old and new parameter. 05_02_2008. 

// modified so that the parwave is searched locally first and then in FuncParWaves.
// // removed hard coded ":" after DataFldrStr. now if DataFldrStr = "" then the waves in current fldr will be analyzed. 04/23/2007
// EOPAHP was using BL at the end of wave. the voltage might not reach steady state by end of wave. changed to PrePlsBLY (pre pulse BL)
// PrePlsBLY is also being stored separately now, to be able to verify the values later. 
//also changed the averaging window to PrePlsBLDelT from BLPreDelT (spike BL) 03_28_2007

// This function finds spikes in a trace, based on absolute height, relative height, & spike threshold based on slope threshold.
// example: pt_FindSpikes("Cell_001517_0016", 0.5, 20, -30e-3, 30e-3, 1, 5, 1e-3, 2e-3, 10, .5e-3)
// for minimas will need to change sign of SpikeThreshDerivLevel, SpikeAmpAbsThresh, SpikePolarity, 

// flow of the program

// Basically, no more peaks are found under 2 conditons
// a. the new search start location becomes greater than end location	
// b. FindPeak doesn't find any more peak between current search location and the end of stim

// The program does the same following set of operations when either of the above 2 exits happen
// a. Update NumSpikes and spike Freq
// b. If NSpikes > 0,  Append NaN to AHP waves, and ISIMidX, and ISIVY. For EOPAHP and PreBlsBL If NSpikes > 0, update value else append NAN's


// More detailed flow -
// 1. Make Waves for different parameters and also temp waves (because the concatenate operation appends one wave to the other)
// 2. Make data folders for holding the non-concatenated analysis waves for parameters that are one-per-spike (eg. peak height, AHP, etc.)
// 3. Start Do loop and if the start point for next window is beyond the end point of depolarization. (means no more spikes in this wave)
//		a. Update NumSpikes and spike Freq
//		b. If NSpikes > 0, 
//				append NaN to AHP waves, and ISIMidX, and ISIVY
//				append EOPAHP and PreBlsBL else append NAN's	(EOPAHP and PreBlsBL are only appended when there are no more spikes in the waves and also if NSpikes<=0 then EOPAHP and PrePlsBL are NAN's)
//    Break while loop
//	EndIF (of start point for next window is beyond the end point of depolarization)
//	4. If SpikePolarity >0
//		a. FindPeak (above Abs. Thresh). If Peak Found, Find Spike Thresh. Find Baseline. Check 	spike height > Rel. Spk. Thresh.
//		b. If the spike qualifies criteria 	
//		c.  If NSpikes > 0, Update AHP, ISIMidX, and ISIVY else append NaN to AHP. EndIf	
//		(AHP, ISIMidX, and ISVY are calculated after the next peak is found and that is why when no more peaks are found NAN is appended to them)

//		d.  Update, Width, TimeTo Half height, SpikeBL, Peak pars, Spike Thresh and Add 1 to NSpikes		
//       If no more spikes in waves (ie. Find Peak, didn't find any more peaks), Update NumSpikes and spike Freq
//		e. If NSpikes > 0,  
//			append NaN to AHP waves, and ISIMidX, and ISIVY
//			append EOPAHP and PreBlsBL else append NAN's
// 		Do the above  If SpikePolarity !=1 (NOT USED AND NOT UPTODATE!!!)
		

String WNameStr, WList, DataWaveMatchStr, DataFldrStr, BaseNameStr
Variable StartX, EndX, SpikeAmpAbsThresh, SpikeAmpRelativeThresh, SpikePolarity, BoxSmoothingPnts, RefractoryPeriod
Variable SpikeThreshWin, SpikeThreshDerivLevel, BLPreDelT, Frac, EOPAHPDelT, PrePlsBLDelT, AlertMessages, SpikeThreshTripleDeriv, ISVDelT, CropEvents, Spike0ThreshWin //**$$//SpikeTh3DerivPerCuttOff
Variable x0, dx, x1, x2, SpikeThreshStartX, SpikeThreshEndX, BLStartX, BLEndX, SpikeAmpRelative, SpikeThreshCrossX
Variable i, Numwaves, NSpikesInWave, PlusAreaVar, MinusAreaVar,j, FIData, LambdaW, SpikeThreshCrossAbsPntX, SpkMaxDvDtAbsX, CropPreMaxSlpDelT, CropPostMaxSlpDelT,k	

String LastUpdatedMM_DD_YYYY="01_03_2011"

Variable BaseNameLen = 0, mNumWaves, TempMaxSlope, PeakLocX, PeakLocXLast, PeakLocY, SpikeThresh3DerivLevel, SpikeThreshCrossXLast
Variable Diff3w_median, Diff3w_iqr , SpikeThreshMaxFrac
String mDestFolderName, mOrigDf, mWList, mWNameStr, mDestWName


Print "*********************************************************"
Print "pt_SpikeAnal last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


//Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_SpikeAnal"+"ParNamesW")
//Wave /T AnalParW			=	$("root:FuncParWaves:pt_SpikeAnal"+"ParW")
//If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
//	Abort	"Cudn't find the parameter wave pt_SpikeAnalParW!!!"
//EndIf


Wave /T AnalParW			=	$pt_GetParWave("pt_SpikeAnal", "ParW")	// wasn't checking locally first. modified 08/21/2007
																		//	First check locally, then in FuncParWaves
																		



PrintAnalPar("pt_SpikeAnal")

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
StartX					=	Str2Num(AnalParW[2]); 
EndX					=	Str2Num(AnalParW[3]); 
SpikeAmpAbsThresh		=	Str2Num(AnalParW[4])
SpikeAmpRelativeThresh	=	Str2Num(AnalParW[5])
SpikePolarity				=	Str2Num(AnalParW[6])
BoxSmoothingPnts		=	Str2Num(AnalParW[7])
RefractoryPeriod			=	Str2Num(AnalParW[8])
SpikeThreshWin			=	Str2Num(AnalParW[9])
SpikeThreshDerivLevel		= 	Str2Num(AnalParW[10])
BLPreDelT				=	Str2Num(AnalParW[11])
If ( StrLen(AnalParW[12])*StrLen(AnalParW[13])!=0)
//	Wave /T FIWNamesW		=	$(GetDataFolder(-1)+DataFldrStr+":"+AnalParW[12])		// removed ":" 04/23/2007
	Wave /T FIWNamesW		=	$(GetDataFolder(-1)+DataFldrStr+AnalParW[12])
//	Wave     FICurrWave		=	$(GetDataFolder(-1)+DataFldrStr+":"+AnalParW[13])		// removed ":" 04/23/2007
	Wave     FICurrWave		=	$(GetDataFolder(-1)+DataFldrStr+AnalParW[13])	
	FIData=1
Else
	FIData=0
EndIf
BaseNameStr			=	AnalParW[14]
BaseNameLen = Strlen(BaseNameStr)
Frac					=	Str2Num(AnalParW[15])
EOPAHPDelT			=	Str2Num(AnalParW[16])		// EndOfPulseAHPDelT
PrePlsBLDelT			= 	Str2Num(AnalParW[17])
AlertMessages			=	Str2Num(AnalParW[18])
// use triple derivative to detect spike threshold instead of threshold crossing of 1st derivative. Even though triple derivative is more accurate if the rise is slow,
// the peak doesn't show clearly. For now, using 1st derivative threhold.
SpikeThreshTripleDeriv		=	Str2Num(AnalParW[19])		
ISVDelT					= 	Str2Num(AnalParW[20])

If (StringMatch(AnalParW[21],"") || StringMatch(AnalParW[22],""))		//02/21/12
CropEvents 				=0
Else
CropEvents 				=1
CropPreMaxSlpDelT		=    Str2Num(AnalParW[21])
CropPostMaxSlpDelT	=    Str2Num(AnalParW[22])
EndIf
//**$$//SpikeTh3DerivPerCuttOff = Str2Num(AnalParW[23]) // 0.05 means cut-off value of triple derivative such that 95% values are below 
Spike0ThreshWin = Str2Num(AnalParW[23]) // look for thresh crossing in this window for the 1st spike.
SpikeThreshMaxFrac = Str2Num(AnalParW[24])
//AlertMessages = 1
//If (AlertMessages)    // incorporated alert message for SpikeThreshWin increase 05_03_2008
//	DoAlert 1, "Recent changes: Using SpikeThreshTripleDeriv. CONTINUE?"
//	If (V_Flag==2)
//		Abort "Aborting..."
//	EndIf
//EndIf

Make 	/O/N=0		$(BaseNameStr+"PrePlsBLX")
Make 	/O/N=0		$(BaseNameStr+"PrePlsBLAbsX")
Make 	/O/N=0		$(BaseNameStr+"PrePlsBLY")
Make 	/O/N=0		$(BaseNameStr+"SpkBLAvgX")
Make 	/O/N=0		$(BaseNameStr+"SpkBLAvgAbsX")
Make 	/O/N=0		$(BaseNameStr+"SpkBLAvgY")
Make 	/O/N=0		$(BaseNameStr+"PeakX")
Make 	/O/N=0		$(BaseNameStr+"PeakAbsX")
Make 	/O/N=0		$(BaseNameStr+"PeakAbsY")
Make 	/O/N=0		$(BaseNameStr+"PeakRelY")
Make 	/O/N=0		$(BaseNameStr+"SpikeThreshX")
Make 	/O/N=0		$(BaseNameStr+"SpikeThreshAbsX")
Make 	/O/N=0		$(BaseNameStr+"SpikeThreshY")
Make 	/O/N=0		$(BaseNameStr+"LFracPX")
Make 	/O/N=0		$(BaseNameStr+"LFracPAbsX")
Make 	/O/N=0		$(BaseNameStr+"RFracPX")
Make 	/O/N=0		$(BaseNameStr+"RFracPAbsX")
Make 	/O/N=0		$(BaseNameStr+"FracPAbsY")
Make 	/O/N=0		$(BaseNameStr+"TToFracPeakY")
Make 	/O/N=0		$(BaseNameStr+"FWFracM")
Make 	/O/N=0		$(BaseNameStr+"AHPX")
Make 	/O/N=0		$(BaseNameStr+"AHPAbsX")
Make 	/O/N=0		$(BaseNameStr+"AHPY")
Make 	/O/N=0		$(BaseNameStr+"AHPAbsY")

Make 	/O/N=0		$(BaseNameStr+"ISIMidAbsX")
Make 	/O/N=0		$(BaseNameStr+"ISIMidX")
Make 	/O/N=0		$(BaseNameStr+"ISVY")

Make 	/O/N=0		$(BaseNameStr+"EOPAHPAbsX")
Make 	/O/N=0		$(BaseNameStr+"EOPAHPX")
Make 	/O/N=0		$(BaseNameStr+"EOPAHPAbsY")
Make 	/O/N=0		$(BaseNameStr+"EOPAHPY")
Make 	/O/N=0		$(BaseNameStr+"WNumSpikes")
Make 	/O/N=0		$(BaseNameStr+"WSpikeFreq")
Make	/O/N=0		$(BaseNameStr+"FICurrW")
Make 	/T/O/N=0	$(BaseNameStr+"WName") 

Make	/O/N=0		$(BaseNameStr+"SpkMaxDvDtY")
Make	/O/N=0		$(BaseNameStr+"SpkMaxDvDtX")
Make	/O/N=0		$(BaseNameStr+"SpkMaxDvDtAbsPnt")
							
						

Make 	/O/N=1		$(BaseNameStr+"PrePlsBLXTemp")
Make 	/O/N=1		$(BaseNameStr+"PrePlsBLAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"PrePlsBLYTemp")
Make 	/O/N=1		$(BaseNameStr+"SpkBLAvgXTemp")
Make 	/O/N=1		$(BaseNameStr+"SpkBLAvgAbsXTemp")
Make	/O/N=1		$(BaseNameStr+"SpkBLAvgYTemp")
Make	/O/N=1		$(BaseNameStr+"PeakXTemp")
Make	/O/N=1		$(BaseNameStr+"PeakAbsXTemp")
Make	/O/N=1		$(BaseNameStr+"PeakAbsYTemp")
Make	/O/N=1		$(BaseNameStr+"PeakRelYTemp")
Make	/O/N=1		$(BaseNameStr+"SpikeThreshXTemp")
Make	/O/N=1		$(BaseNameStr+"SpikeThreshAbsXTemp")
Make	/O/N=1		$(BaseNameStr+"SpikeThreshYTemp")
Make 	/O/N=1		$(BaseNameStr+"LFracPXTemp")
Make 	/O/N=1		$(BaseNameStr+"LFracPAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"RFracPXTemp")
Make 	/O/N=1		$(BaseNameStr+"RFracPAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"FracPAbsYTemp")
Make 	/O/N=1		$(BaseNameStr+"TToFracPeakYTemp")
Make 	/O/N=1		$(BaseNameStr+"FWFracMTemp")
Make 	/O/N=1		$(BaseNameStr+"AHPXTemp")
Make 	/O/N=1		$(BaseNameStr+"AHPAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"AHPYTemp")
Make 	/O/N=1		$(BaseNameStr+"AHPAbsYTemp")

Make 	/O/N=1		$(BaseNameStr+"ISIMidAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"ISIMidXTemp")
Make 	/O/N=1		$(BaseNameStr+"ISVYTemp")

Make 	/O/N=1		$(BaseNameStr+"EOPAHPAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"EOPAHPXTemp")
Make 	/O/N=1		$(BaseNameStr+"EOPAHPAbsYTemp")
Make 	/O/N=1		$(BaseNameStr+"EOPAHPYTemp")
Make	/O/N=1		$(BaseNameStr+"WNumSpikesTemp")
Make	/O/N=1		$(BaseNameStr+"FICurrWTemp")
Make	/T/O/N=1	$(BaseNameStr+"WNameTemp")

Make	/O/N=1		$(BaseNameStr+"SpkMaxDvDtYTemp")
Make	/O/N=1		$(BaseNameStr+"SpkMaxDvDtXTemp")
Make	/O/N=1		$(BaseNameStr+"SpkMaxDvDtAbsPntTemp")



Wave		PrePlsBLX				=		$(BaseNameStr+"PrePlsBLX")
Wave		PrePlsBLAbsX			=		$(BaseNameStr+"PrePlsBLAbsX")
Wave		PrePlsBLY				=		$(BaseNameStr+"PrePlsBLY")
Wave		SpkBLAvgX				=		$(BaseNameStr+"SpkBLAvgX")
Wave		SpkBLAvgAbsX			=		$(BaseNameStr+"SpkBLAvgAbsX")
Wave		SpkBLAvgY				=		$(BaseNameStr+"SpkBLAvgY")
Wave		PeakX					=		$(BaseNameStr+"PeakX")
Wave 		PeakAbsX				=		$(BaseNameStr+"PeakAbsX")
Wave 		PeakAbsY				=		$(BaseNameStr+"PeakAbsY")
Wave 		PeakRelY				=		$(BaseNameStr+"PeakRelY")
Wave 		SpikeThreshX			=		$(BaseNameStr+"SpikeThreshX")
Wave 		SpikeThreshAbsX			=		$(BaseNameStr+"SpikeThreshAbsX")
Wave 		SpikeThreshY			=		$(BaseNameStr+"SpikeThreshY")
Wave 		LFracPX					=		$(BaseNameStr+"LFracPX")
Wave 		LFracPAbsX				=		$(BaseNameStr+"LFracPAbsX")
Wave 		RFracPX					=		$(BaseNameStr+"RFracPX")
Wave 		RFracPAbsX				=		$(BaseNameStr+"RFracPAbsX")
Wave 		FracPAbsY				=		$(BaseNameStr+"FracPAbsY")
Wave 		TToFracPeakY			=		$(BaseNameStr+"TToFracPeakY")
Wave 		FWFracM				=		$(BaseNameStr+"FWFracM")
Wave 		AHPX					=		$(BaseNameStr+"AHPX")
Wave 		AHPAbsX				=		$(BaseNameStr+"AHPAbsX")
Wave 		AHPY					=		$(BaseNameStr+"AHPY")
Wave 		AHPAbsY				=		$(BaseNameStr+"AHPAbsY")

Wave 		ISIMidAbsX				=		$(BaseNameStr+"ISIMidAbsX")
Wave 		ISIMidX					=		$(BaseNameStr+"ISIMidX")
Wave 		ISVY					=		$(BaseNameStr+"ISVY")

Wave		EOPAHPAbsX			=		$(BaseNameStr+"EOPAHPAbsX")
Wave		EOPAHPX				=		$(BaseNameStr+"EOPAHPX")
Wave		EOPAHPAbsY			=		$(BaseNameStr+"EOPAHPAbsY")
Wave		EOPAHPY				=		$(BaseNameStr+"EOPAHPY")
Wave 		WNumSpikes			=		$(BaseNameStr+"WNumSpikes")
Wave 		WSpikeFreq				=		$(BaseNameStr+"WSpikeFreq")
Wave		FICurrW				=		$(BaseNameStr+"FICurrW")
Wave	/T	WName					=		$(BaseNameStr+"WName") 

Wave 		SpkMaxDvDtY			= 		$(BaseNameStr+"SpkMaxDvDtY")
Wave 		SpkMaxDvDtX			= 		$(BaseNameStr+"SpkMaxDvDtX")
Wave 		SpkMaxDvDtAbsPnt		= 		$(BaseNameStr+"SpkMaxDvDtAbsPnt")


Wave		PrePlsBLXTemp			=		$(BaseNameStr+"PrePlsBLXTemp")
Wave		PrePlsBLAbsXTemp		=		$(BaseNameStr+"PrePlsBLAbsXTemp")
Wave		PrePlsBLYTemp			=		$(BaseNameStr+"PrePlsBLYTemp")
Wave		SpkBLAvgXTemp			=		$(BaseNameStr+"SpkBLAvgXTemp")
Wave		SpkBLAvgAbsXTemp		=		$(BaseNameStr+"SpkBLAvgAbsXTemp")
Wave		SpkBLAvgYTemp			=		$(BaseNameStr+"SpkBLAvgYTemp")
Wave		PeakXTemp				=		$(BaseNameStr+"PeakXTemp")
Wave		PeakAbsXTemp			=		$(BaseNameStr+"PeakAbsXTemp")
Wave		PeakAbsYTemp			=		$(BaseNameStr+"PeakAbsYTemp")
Wave		PeakRelYTemp			=		$(BaseNameStr+"PeakRelYTemp")
Wave		SpikeThreshXTemp		=		$(BaseNameStr+"SpikeThreshXTemp")
Wave		SpikeThreshAbsXTemp	=		$(BaseNameStr+"SpikeThreshAbsXTemp")
Wave		SpikeThreshYTemp		=		$(BaseNameStr+"SpikeThreshYTemp")
Wave		LFracPXTemp			=		$(BaseNameStr+"LFracPXTemp")
Wave 		LFracPAbsXTemp		=		$(BaseNameStr+"LFracPAbsXTemp")
Wave 		RFracPXTemp			=		$(BaseNameStr+"RFracPXTemp")
Wave 		RFracPAbsXTemp		=		$(BaseNameStr+"RFracPAbsXTemp")
Wave 		FracPAbsYTemp			=		$(BaseNameStr+"FracPAbsYTemp")
Wave 		TToFracPeakYTemp		=		$(BaseNameStr+"TToFracPeakYTemp")
Wave 		FWFracMTemp			=		$(BaseNameStr+"FWFracMTemp")
Wave 		AHPXTemp				=		$(BaseNameStr+"AHPXTemp")
Wave 		AHPAbsXTemp			=		$(BaseNameStr+"AHPAbsXTemp")
Wave 		AHPYTemp				=		$(BaseNameStr+"AHPYTemp")
Wave 		AHPAbsYTemp			=		$(BaseNameStr+"AHPAbsYTemp")

Wave 		ISIMidAbsXTemp			=		$(BaseNameStr+"ISIMidAbsXTemp")
Wave 		ISIMidXTemp				=		$(BaseNameStr+"ISIMidXTemp")
Wave 		ISVYTemp				=		$(BaseNameStr+"ISVYTemp")

Wave		EOPAHPAbsXTemp		=		$(BaseNameStr+"EOPAHPAbsXTemp")
Wave		EOPAHPXTemp			=		$(BaseNameStr+"EOPAHPXTemp")
Wave		EOPAHPAbsYTemp		=		$(BaseNameStr+"EOPAHPAbsYTemp")
Wave		EOPAHPYTemp			=		$(BaseNameStr+"EOPAHPYTemp")
Wave		WNumSpikesTemp		=		$(BaseNameStr+"WNumSpikesTemp")
Wave		FICurrWTemp			=		$(BaseNameStr+"FICurrWTemp")
Wave	/T	WNameTemp			=		$(BaseNameStr+"WNameTemp")

Wave 		SpkMaxDvDtYTemp		= 		$(BaseNameStr+"SpkMaxDvDtYTemp")
Wave 		SpkMaxDvDtXTemp		= 		$(BaseNameStr+"SpkMaxDvDtXTemp")
Wave 		SpkMaxDvDtAbsPntTemp= 		$(BaseNameStr+"SpkMaxDvDtAbsPntTemp")




WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

If (NumWaves>0)
// Kill previous analysis so that the results don't get mixed in


Print "Deleting previous analysis..."

Wave /T KWAnalParW			=	$pt_GetParWave("pt_KillWFrmFldrs", "ParW")	// wasn't checking locally first. modified 08/21/2007

String OldDataWaveMatchStr			=		KWAnalParW[0]
String OldSubFldr						= 		KWAnalParW[2]

KWAnalParW[0] = BaseNameStr+"*"

//1
If (DataFolderExists(BaseNameStr+"PeakAbsXF"))
KWAnalParW[2] = BaseNameStr+"PeakAbsXF:"
pt_KillWFrmFldrs()
EndIf

//1a 
If (DataFolderExists(BaseNameStr+"PeakAbsYF"))
KWAnalParW[2] = BaseNameStr+"PeakAbsYF:"
pt_KillWFrmFldrs()
EndIf

//2
If (DataFolderExists(BaseNameStr+"FWFracMF"))
KWAnalParW[2] = BaseNameStr+"FWFracMF:"
pt_KillWFrmFldrs()
EndIf

//3
If (DataFolderExists(BaseNameStr+"AHPYF"))
KWAnalParW[2] = BaseNameStr+"AHPYF:"
pt_KillWFrmFldrs()
EndIf

//4
If (DataFolderExists(BaseNameStr+"AHPAbsYF"))
KWAnalParW[2] = BaseNameStr+"AHPYF:"
pt_KillWFrmFldrs()
EndIf

//5
If (DataFolderExists(BaseNameStr+"AHPAbsXF"))
KWAnalParW[2] = BaseNameStr+"AHPYF:"
pt_KillWFrmFldrs()
EndIf

//6
If (DataFolderExists(BaseNameStr+"ISVYF"))
KWAnalParW[2] = BaseNameStr+"ISVYF:"
pt_KillWFrmFldrs()
EndIf

//7
If (DataFolderExists(BaseNameStr+"PeakRelYF"))
KWAnalParW[2] = BaseNameStr+"PeakRelYF:"
pt_KillWFrmFldrs()
EndIf

//8
If (DataFolderExists(BaseNameStr+"SpikeThreshYF"))
KWAnalParW[2] = BaseNameStr+"SpikeThreshYF:"
pt_KillWFrmFldrs()
EndIf

//9
If (DataFolderExists(BaseNameStr+"SpkBLAvgYF"))
KWAnalParW[2] = BaseNameStr+"SpkBLAvgYF:"
pt_KillWFrmFldrs()
EndIf

//10
If (DataFolderExists(BaseNameStr+"TToFracPeakYF"))
KWAnalParW[2] = BaseNameStr+"TToFracPeakYF:"
pt_KillWFrmFldrs()
EndIf

//11
If (DataFolderExists(BaseNameStr+"SpkMaxDvDtYF"))
KWAnalParW[2] = BaseNameStr+"SpkMaxDvDtYF:"
pt_KillWFrmFldrs()
EndIf

//12
If (DataFolderExists(BaseNameStr+"CropPksF"))
KWAnalParW[2] = BaseNameStr+"CropPksF:"
pt_KillWFrmFldrs()
EndIf

//13
If (DataFolderExists(BaseNameStr+"SpkMaxDvDtXF"))
KWAnalParW[2] = BaseNameStr+"SpkMaxDvDtXF:"
pt_KillWFrmFldrs()
EndIf

//14
If (DataFolderExists(BaseNameStr+"IFrqF"))
KWAnalParW[2] = BaseNameStr+"IFrqF:"
pt_KillWFrmFldrs()
EndIf

//15
If (DataFolderExists(BaseNameStr+"ISIF"))
KWAnalParW[2] = BaseNameStr+"ISIF:"
pt_KillWFrmFldrs()
EndIf

//16
If (DataFolderExists(BaseNameStr+"SpikeThreshXF"))
KWAnalParW[2] = BaseNameStr+"SpikeThreshXF:"
pt_KillWFrmFldrs()
EndIf

//17
If (DataFolderExists(BaseNameStr+"EOPAHPAbsXF"))
KWAnalParW[2] = BaseNameStr+"EOPAHPAbsXF:"
pt_KillWFrmFldrs()
EndIf

//18
If (DataFolderExists(BaseNameStr+"EOPAHPAbsYF"))
KWAnalParW[2] = BaseNameStr+"EOPAHPAbsYF:"
pt_KillWFrmFldrs()
EndIf

//19
If (DataFolderExists(BaseNameStr+"LFracPAbsXF"))
KWAnalParW[2] = BaseNameStr+"LFracPAbsXF:"
pt_KillWFrmFldrs()
EndIf

//20
If (DataFolderExists(BaseNameStr+"RFracPAbsXF"))
KWAnalParW[2] = BaseNameStr+"RFracPAbsXF:"
pt_KillWFrmFldrs()
EndIf

//21
If (DataFolderExists(BaseNameStr+"FracPAbsYF"))
KWAnalParW[2] = BaseNameStr+"FracPAbsYF:"
pt_KillWFrmFldrs()
EndIf

EndIf

Print "Analyzing spikes for waves, N =", ItemsInList(WList, ";"), WList

//Print "TEMPOARILY REDIFINING SPIKE WIDTH TO WHERE THE VOLTAGE CROSSES THE SPIKE THRESHOLD"

//If (SpikeThreshTripleDeriv)
	//Triple derivative detects wrong peak some times. 
//	DoAlert 0, "Using crossing of SpikeThreshDerivLevel by 1st derivative"
//EndIf


For (i=0; i<NumWaves; i+=1)
	
	WNameStr=StringFromList(i, WList, ";")
	WNameTemp[0]=WNameStr
	If (FIData)
		For (j=0; j<NumPnts(FIWNamesW); j+=1)
			If (StringMatch(FIWNamesW[j],WNameStr))
//				Print j, WNameStr, FICurrWave[j]
				FICurrWTemp[0]=FICurrWave[j]
				Concatenate /NP 	   {FICurrWTemp}, FICurrW
				break
				print "Couldn't find", WNameStr, "in",AnalParW[11]
			EndIf
		EndFor
	EndIf
	Concatenate /T/NP {WNameTemp}, WName
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), w		// removed ":" 04/23/2007
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), w
//	display w
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), Diffw	// removed ":" 04/23/2007
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), Diffw, Diff3w
	//Smooth 1, Diffw
	Differentiate Diffw	  // 1st
	Differentiate Diff3w // 1st
	Differentiate Diff3w // 2nd
	Differentiate Diff3w // 3rd
	
	//Switching to backward differences which give seems to give slope closer to expected x-value

	//Differentiate/METH=2 Diffw	  // 1st
	//Differentiate/METH=2 Diff3w // 1st
	//Differentiate/METH=2 Diff3w // 2nd
	//Differentiate/METH=2 Diff3w // 3rd
	x0=DimOffset(w,0); dx=DimDelta(w,0)
//	LambdaW=x0+(NumPnts(w)-1)*dx
	LambdaW=x0+(NumPnts(w))*dx
	NSpikesInWave=0; x1=StartX; x2=EndX;
	//$//Duplicate /O Diff3w, Diff3w_Smth
	//$//Smooth /B 5, Diff3w_Smth // not used in next step at present 11/14/14
	//$//Duplicate /O /R=(x1, x2) Diff3w_Smth, $"Diff3w_Smth_clipped"
	//SpikeThresh3DerivLevel = pt_CalHistThresh("Diff3w_Smth_clipped", SpikeTh3DerivPerCuttOff, SpikePolarity) // 0.05 means cut-off value of triple derivative such that 95% values are below 
	//$//SpikeThresh3DerivLevel = pt_CalPercentile("Diff3w_Smth_clipped", SpikeTh3DerivPerCuttOff) // 0.95 means cut-off value of triple derivative such that 95% values are below 

	//$//Print "Cut-off for triple derivative =", SpikeThresh3DerivLevel, WNameStr
	//$//KillWaves /Z $"Diff3w_Smth_clipped"
//   Also store per spike parameters for each data wave in a separate wave along with one long concatenated wave

//Print GetDataFolder(1)
NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PeakAbsXF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PeakAbsXF:"+BaseNameStr+"PeakAbsXW"+Num2Str(i))
Wave PeakAbsXWi = $(GetDataFolder(1)+BaseNameStr+"PeakAbsXF:"+BaseNameStr+"PeakAbsXW"+Num2Str(i))
Note /k PeakAbsXWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PeakAbsYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PeakAbsYF:"+BaseNameStr+"PeakAbsYW"+Num2Str(i))
Wave PeakAbsYWi = $(GetDataFolder(1)+BaseNameStr+"PeakAbsYF:"+BaseNameStr+"PeakAbsYW"+Num2Str(i))
Note /k PeakAbsYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"FWFracMF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"FWFracMF:"+BaseNameStr+"FWFracMW"+Num2Str(i))
Wave FWFracMWi = $(GetDataFolder(1)+BaseNameStr+"FWFracMF:"+BaseNameStr+"FWFracMW"+Num2Str(i))
Note /k FWFracMWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"AHPYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"AHPYF:"+BaseNameStr+"AHPYW"+Num2Str(i))
Wave AHPYWi = $(GetDataFolder(1)+BaseNameStr+"AHPYF:"+BaseNameStr+"AHPYW"+Num2Str(i))
Note /k AHPYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"AHPAbsYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"AHPAbsYF:"+BaseNameStr+"AHPAbsYW"+Num2Str(i))
Wave AHPAbsYWi = $(GetDataFolder(1)+BaseNameStr+"AHPAbsYF:"+BaseNameStr+"AHPAbsYW"+Num2Str(i))
Note /k AHPAbsYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"AHPAbsXF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"AHPAbsXF:"+BaseNameStr+"AHPAbsXW"+Num2Str(i))
Wave AHPAbsXWi = $(GetDataFolder(1)+BaseNameStr+"AHPAbsXF:"+BaseNameStr+"AHPAbsXW"+Num2Str(i))
Note /k AHPAbsXWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"EOPAHPAbsYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"EOPAHPAbsYF:"+BaseNameStr+"EOPAHPAbsYW"+Num2Str(i))
Wave EOPAHPAbsYWi = $(GetDataFolder(1)+BaseNameStr+"EOPAHPAbsYF:"+BaseNameStr+"EOPAHPAbsYW"+Num2Str(i))
Note /k EOPAHPAbsYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"EOPAHPAbsXF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"EOPAHPAbsXF:"+BaseNameStr+"EOPAHPAbsXW"+Num2Str(i))
Wave EOPAHPAbsXWi = $(GetDataFolder(1)+BaseNameStr+"EOPAHPAbsXF:"+BaseNameStr+"EOPAHPAbsXW"+Num2Str(i))
Note /k EOPAHPAbsXWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"LFracPAbsXF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"LFracPAbsXF:"+BaseNameStr+"LFracPAbsXW"+Num2Str(i))
Wave LFracPAbsXWi = $(GetDataFolder(1)+BaseNameStr+"LFracPAbsXF:"+BaseNameStr+"LFracPAbsXW"+Num2Str(i))
Note /k LFracPAbsXWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"RFracPAbsXF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"RFracPAbsXF:"+BaseNameStr+"RFracPAbsXW"+Num2Str(i))
Wave RFracPAbsXWi = $(GetDataFolder(1)+BaseNameStr+"RFracPAbsXF:"+BaseNameStr+"RFracPAbsXW"+Num2Str(i))
Note /k RFracPAbsXWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"FracPAbsYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"FracPAbsYF:"+BaseNameStr+"FracPAbsYW"+Num2Str(i))
Wave FracPAbsYWi = $(GetDataFolder(1)+BaseNameStr+"FracPAbsYF:"+BaseNameStr+"FracPAbsYW"+Num2Str(i))
Note /k FracPAbsYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"ISVYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"ISVYF:"+BaseNameStr+"ISVYW"+Num2Str(i))
Wave ISVYWi = $(GetDataFolder(1)+BaseNameStr+"ISVYF:"+BaseNameStr+"ISVYW"+Num2Str(i))
Note /k ISVYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"PeakRelYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"PeakRelYF:"+BaseNameStr+"PeakRelYW"+Num2Str(i))
Wave PeakRelYWi = $(GetDataFolder(1)+BaseNameStr+"PeakRelYF:"+BaseNameStr+"PeakRelYW"+Num2Str(i))
Note /k PeakRelYWi  "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"SpikeThreshYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"SpikeThreshYF:"+BaseNameStr+"SpikeThreshYW"+Num2Str(i))
Wave SpikeThreshYWi = $(GetDataFolder(1)+BaseNameStr+"SpikeThreshYF:"+BaseNameStr+"SpikeThreshYW"+Num2Str(i))
Note /k SpikeThreshYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"SpikeThreshXF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"SpikeThreshXF:"+BaseNameStr+"SpikeThreshXW"+Num2Str(i))
Wave SpikeThreshXWi = $(GetDataFolder(1)+BaseNameStr+"SpikeThreshXF:"+BaseNameStr+"SpikeThreshXW"+Num2Str(i))
Note /k SpikeThreshXWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"SpkBLAvgYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"SpkBLAvgYF:"+BaseNameStr+"SpkBLAvgYW"+Num2Str(i))
Wave SpkBLAvgYWi = $(GetDataFolder(1)+BaseNameStr+"SpkBLAvgYF:"+BaseNameStr+"SpkBLAvgYW"+Num2Str(i))
Note /k SpkBLAvgYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"TToFracPeakYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"TToFracPeakYF:"+BaseNameStr+"TToFracPeakYW"+Num2Str(i))
Wave TToFracPeakYWi = $(GetDataFolder(1)+BaseNameStr+"TToFracPeakYF:"+BaseNameStr+"TToFracPeakYW"+Num2Str(i))
Note /k TToFracPeakYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"SpkMaxDvDtYF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"SpkMaxDvDtYF:"+BaseNameStr+"SpkMaxDvDtYW"+Num2Str(i))
Wave SpkMaxDvDtYWi = $(GetDataFolder(1)+BaseNameStr+"SpkMaxDvDtYF:"+BaseNameStr+"SpkMaxDvDtYW"+Num2Str(i))
Note /k SpkMaxDvDtYWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"CropPksF")

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"SpkMaxDvDtXF")
Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"SpkMaxDvDtXF:"+BaseNameStr+"SpkMaxDvDtXW"+Num2Str(i))
Wave SpkMaxDvDtXWi = $(GetDataFolder(1)+BaseNameStr+"SpkMaxDvDtXF:"+BaseNameStr+"SpkMaxDvDtXW"+Num2Str(i))
Note /k SpkMaxDvDtXWi "TraceName:"+WNameStr

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"SpkMaxDvDtXF")

NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"IFrqF")
NewDataFolder /O $(GetDataFolder(1)+BaseNameStr+"ISIF")

j=0			//	index fos spike num
PeakLocXLast = NaN  
	Do
	If (x1>=x2)								// end of pulse reached; now calculate EOPAHP and PrePlsBLY
//			Print x1,">=",x2
			WNumSpikesTemp[0]=NSpikesInWave
			Concatenate /NP {WNumSpikesTemp}, WNumSpikes
			Duplicate /O WNumSpikes, WSpikeFreq
			WSpikeFreq /= abs(EndX-StartX) 
				If (NSpikesInWave>0)
					AHPAbsXTemp		= NaN
					AHPXTemp			= NaN
					AHPAbsYTemp		= NaN
					AHPYTemp			= NaN
					Concatenate /NP	{AHPAbsXTemp},			AHPAbsX; Concatenate /NP	{AHPAbsXTemp},			AHPAbsXWi
					Concatenate /NP	{AHPXTemp},			AHPX
					Concatenate /NP	{AHPAbsYTemp},			AHPAbsY;	 Concatenate /NP	{AHPAbsYTemp},			AHPAbsYWi
					Concatenate /NP	{AHPYTemp},			AHPY; Concatenate /NP	{AHPYTemp}, AHPYWi	
					
					ISIMidAbsXTemp			= Nan
					ISIMidXTemp				= Nan
					ISVYTemp				= Nan
					Concatenate /NP {ISIMidAbsXTemp}, 	ISIMidAbsX
					Concatenate /NP {ISIMidXTemp}, 		ISIMidX
					Concatenate /NP {ISVYTemp}, 			ISVY; Concatenate /NP {ISVYTemp}, 			ISVYWi
					
				EndIf
				EOPAHPAbsXTemp			=	NaN
				EOPAHPXTemp				=	NaN
				EOPAHPAbsYTemp			=	NaN
				EOPAHPYTemp				=	NaN
							
				PrePlsBLAbsXTemp			=	NaN
				PrePlsBLXTemp				=	NaN
				PrePlsBLYTemp				=	NaN	

				
				If (NSpikesInWave>0)
					WaveStats /Q/R=(StartX-PrePlsBLDelT, StartX) w 
					PrePlsBLAbsXTemp	= StartX-0.5*PrePlsBLDelT
					PrePlsBLXTemp		= PrePlsBLAbsXTemp + i*LambdaW
					PrePlsBLYTemp		= V_Avg
					WaveStats /Q/R=(EndX, EndX+EOPAHPDelT) w
					EOPAHPAbsXTemp			=	V_MinLoc
					EOPAHPXTemp				=	EOPAHPAbsXTemp+ i*LambdaW
					EOPAHPAbsYTemp			=	V_Min
// for EOPAHP the steady state voltage may not be reached by end of wave. should be taken from before the pulse. 03/28/2007
//					EOPAHPYTemp	=	EOPAHPAbsYTemp-Mean(w, LambdaW-BLPreDelT, LambdaW)		
					EOPAHPYTemp	=	EOPAHPAbsYTemp - PrePlsBLYTemp
				EndIf	
				Concatenate /NP	{EOPAHPAbsXTemp},			EOPAHPAbsX; Concatenate /NP	{EOPAHPAbsXTemp}, EOPAHPAbsXWi
				Concatenate /NP	{EOPAHPXTemp},			EOPAHPX
				Concatenate /NP	{EOPAHPAbsYTemp},		EOPAHPAbsY; Concatenate /NP	{EOPAHPAbsYTemp}, EOPAHPAbsYWi
				Concatenate /NP	{EOPAHPYTemp},			EOPAHPY
				
				Concatenate /NP	{PrePlsBLAbsXTemp},			PrePlsBLAbsX
				Concatenate /NP	{PrePlsBLXTemp},			PrePlsBLX
				Concatenate /NP	{PrePlsBLYTemp},			PrePlsBLY
			Break	// finish analyzing this pulse
		EndIf
		If (SpikePolarity==1)
			FindPeak 		/B=(BoxSmoothingPnts) /M=(SpikeAmpAbsThresh) /Q/R=(x1,x2) w
			If (V_Flag==0)
				//y1=mean(V_PeakLoc-BLPreT-BLPreDelT,V_PeakLoc-BLPreT)
				PeakLocX=x0+dx*x2pnt(w,V_PeakLoc)	// convert from pt. to x
				x1=PeakLocX+RefractoryPeriod
				PeakLocY = V_PeakVal
				SpikeThreshEndX=PeakLocX
				SpikeThreshStartX=SpikeThreshEndX-SpikeThreshWin
				
				// Spike thresh = voltage at which the slope 1st exceeds a fraction of max slope (Rony A and Charles MG J Neurosci 1999) 11/10/14
				//Wavestats /Q/R=(SpikeThreshStartX, SpikeThreshEndX) Diffw
				//TempMaxSlope = V_Max
				
				// narrow the search window by limiting SpikeThreshEndX to minimum in triple derivative (11/16/14)
				//**$$//Wavestats /Q/R=(SpikeThreshStartX, SpikeThreshEndX)  Diff3w
				//**$$//SpikeThreshEndX = V_MinLoc
				
				SpikeThreshCrossX = Nan
				//If (SpikeThreshTripleDeriv)
				//Triple derivative detects wrong peak some times. 
				//	DoAlert 0, "Using crossing of SpikeThreshDerivLevel by 1st derivative"
				//EndIf
				//$$//If (SpikeThreshTripleDeriv)
						//$$//	Wavestats /Q/R=(SpikeThreshStartX, SpikeThreshEndX) Diff3w
						//$$//	SpikeThreshCrossX=V_MaxLoc
				//$$//Else
				
				// start searching for spike thresh from peak towards threshold IN THE DIFF WAVE 08/04/14
				// This way we will first cross the threshold rather than get a value from previous peak. 
				// seems like if we are reversing the direction of searching, then Edge =1 gives crossing while y-values are decreasing
				// and Edge = 2 while y values are increasing. Also, note that we are searching for crossing in the diff wave.
				// therefore using Edge = 1 with reversed direction of searching. 
				//FindLevel /Edge =2 /Q/R=(SpikeThreshStartX, SpikeThreshEndX)  Diffw, SpikeThreshDerivLevel
				
				

				// switching back to forward searching 11/10/14
				//FindLevel /Edge =1 /Q/R=(SpikeThreshEndX, SpikeThreshStartX)  Diffw, TempMaxSlope*0.033
				// define SpikeThreshStartX = min between current peak and prev peak
				
				// set appropriate SpikeThreshStartX depending on 1st spike or not
				If (NumType(PeakLocXLast) != 0) // 1st spike, PeakLocXLast = NaN. Use if 1st threshold detection for 1st spike needs special treatment 11/15/14
					SpikeThreshStartX=SpikeThreshEndX-Spike0ThreshWin
					//print "1st spike: SpikeThreshStartX, peak pos. for WName", SpikeThreshStartX, PeakLocX
					PeakLocXLast = 0
				Else
					Wavestats /Q/R=(PeakLocXLast, PeakLocX) w
				 	// If the previous spike occured after SpikeThreshStartX, replace with min loc between spikes
					If (SpikeThreshStartX < V_MinLoc)
						SpikeThreshStartX = V_MinLoc
					EndIf
				//print "SpikeThreshStartX for WName, PeakLocX", SpikeThreshStartX, PeakLocX//, "TempMaxSlope*0.033", TempMaxSlope*0.01//33
				EndIf
				
				// Spike thresh = voltage at which the slope 1st exceeds a fraction of max slope (Rony A and Charles MG J Neurosci 1999) 11/10/14
				Wavestats /Q/R=(SpikeThreshStartX, SpikeThreshEndX) Diffw
				TempMaxSlope = V_Max
				
				SpikeThreshEndX = V_MaxLoc // narrow down the window for spike thresh search
				
				//FindLevel /Edge =1 /Q/R=(SpikeThreshStartX, SpikeThreshEndX)  Diffw, TempMaxSlope*0.02//, SpikeThreshDerivLevel
				
				//Wave Diff3wSmth = $"Diff3w_Smth"
				
				//$//Duplicate /O Diff3w, Diff3w_Smth
				//$//Smooth /B 5, Diff3w_Smth // not used in next step at present 11/14/14
				//**$$//Duplicate /O /R=(SpikeThreshStartX, SpikeThreshEndX) Diff3w, $"Diff3w_clipped"
				//SpikeThresh3DerivLevel = pt_CalHistThresh("Diff3w_Smth_clipped", SpikeTh3DerivPerCuttOff, SpikePolarity) // 0.05 means cut-off value of triple derivative such that 95% values are below 
				//**$$//SpikeThresh3DerivLevel = pt_CalPercentile("Diff3w_clipped", SpikeTh3DerivPerCuttOff) // 0.95 means cut-off value of triple derivative such that 95% values are below 
				//SpikeThresh3DerivLevel = pt_CalPercentile("Diff3w_clipped", SpikeTh3DerivPerCuttOff) // 0.95 means cut-off value of triple derivative such that 95% values are below 

				//Print "Cut-off for triple derivative =", SpikeThresh3DerivLevel, WNameStr
				//$//WaveStats /Q $"Diff3w_clipped"
				//**$$//StatsQuantiles /Q/Z $"Diff3w_clipped"
				//**$$//Diff3w_median = V_Median
 				//**$$//Diff3w_iqr = V_IQR
				//**$$//KillWaves /Z $"Diff3w_clipped"

				//**$$//FindPeak /M = (SpikeThresh3DerivLevel) /Q/R=(SpikeThreshStartX, SpikeThreshEndX)  Diff3w//_Smth//"//TempMaxSlope*0.02//, SpikeThreshDerivLevel 
				//print "SpikeThresh3DerivLevel , Diff3w_median+ 2.0*V_IQR", SpikeThresh3DerivLevel , Diff3w_median+ 1.0*V_IQR, WNameStr,  "Peak loc =", PeakLocX
				//**$$//If  ( (V_Flag==0) && (SpikeThresh3DerivLevel > (Diff3w_median+ 1.0*V_IQR) ) ) // peak found and SpikeThresh3DerivLevel was above noise level
				//**$$//	SpikeThreshCrossX=V_PeakLoc//V_LevelX
					//SpikeThreshCrossXLast = SpikeThreshCrossX
				//**$$//Else // if can't find spike using triple derivative (if the rise is too smooth). Use Thresh for 1st derivative for previous spike
					
				//**$$//	SpikeThreshDerivLevel = Diffw[x2pnt(w, SpikeThreshCrossXLast)]
					//print "No peak in triple derivative. ", WNameStr,"Using  Thresh for 1st derivative for previous spike", SpikeThreshDerivLevel,  "Peak loc =", PeakLocX//10% of max slope as voltage threshold = ", TempMaxSlope
					FindLevel /Edge =1 /Q/R=(SpikeThreshStartX, SpikeThreshEndX)  Diffw, TempMaxSlope*SpikeThreshMaxFrac//SpikeThreshDerivLevel////,SpikeThreshDerivLevel
					SpikeThreshCrossX=V_LevelX
				//**$$//EndIf
				//$$//EndIf
				If (NumType(SpikeThreshCrossX)!=0)			//(V_Flag!=0)
//					Print "Cudn't find spike amp. thresh for spike at", V_PeakLoc,"in wave", WNameStr
				Else 
					SpikeThreshCrossAbsPntX	=	x2pnt(w,SpikeThreshCrossX)		// store for use with SpkMaxDvDtAbsPnt
//					SpikeThreshCrossX=x0+dx*x2pnt(w,SpikeThreshCrossX)
					SpikeThreshCrossX=x0+dx*SpikeThreshCrossAbsPntX
					BLStartX=SpikeThreshCrossX-BLPreDelT
					BLEndX=SpikeThreshCrossX
					SpkBLAvgYTemp		=	mean( w, BLStartX, BLEndX)
					SpkBLAvgAbsXTemp	= 	0.5*(BLStartX + BLEndX)
					SpkBLAvgXTemp		=	SpkBLAvgAbsXTemp + i*LambdaW
					SpikeAmpRelative=PeakLocY-SpkBLAvgYTemp
//					print mean( w, BLStartX, BLEndX)
					If (SpikeAmpRelative >=SpikeAmpRelativeThresh)
						//Print "Is a spike"
						PeakAbsXTemp	=	PeakLocX; PeakAbsYTemp=PeakLocY; PeakRelYTemp=SpikeAmpRelative
						PeakLocXLast = PeakLocX //11/10/14
						SpikeThreshCrossXLast = SpikeThreshCrossX  //11/10/14
						PeakXTemp		=	PeakAbsXTemp+ i*LambdaW
						
						SpikeThreshAbsXTemp	=	SpikeThreshCrossX; SpikeThreshYTemp=w[x2pnt(w,SpikeThreshCrossX)]
						SpikeThreshXTemp		=	SpikeThreshAbsXTemp+i*LambdaW
						
// LFracPX = x value at which the trace crosses the Frac of  max on left side			
						FracPAbsYTemp	=	SpkBLAvgYTemp+Frac*SpikeAmpRelative	
						FindLevel /Q/R=(PeakAbsXTemp, -inf)  w, 	FracPAbsYTemp	// Frac will usually be 0.5//SpikeThreshAbsXTemp
//						FindLevel /Q/R=(PeakAbsXTemp, -inf)  w, 	SpikeThreshYTemp // temporarily redefining spike width to where the voltage crosses the spike threshold						
						If (V_Flag!=0)
							Print "No left crossing at", frac,"times of peak in wave", WNameStr, "at", PeakAbsXTemp,"between", PeakAbsXTemp, SpikeThreshAbsXTemp
							LFracPAbsXTemp	= 	NaN
							LFracPXTemp		= 	NaN
							TToFracPeakYTemp	=  	NaN
						Else	
							LFracPAbsXTemp	= 	V_LevelX
							LFracPXTemp		= 	LFracPAbsXTemp+ i*LambdaW
							TToFracPeakYTemp	=  	LFracPAbsXTemp-SpikeThreshAbsXTemp
						EndIf	
							
						
// RFracPX = x value at which the trace crosses the Frac of  max on Right side			
			
							FindLevel /Q/R=(PeakAbsXTemp, +inf)  w, FracPAbsYTemp//2*PeakAbsXTemp-SpikeThreshAbsXTemp
//							FindLevel /Q/R=(PeakAbsXTemp, +inf)  w, SpikeThreshYTemp // temporarily redefining spike width to where the voltage crosses the spike threshold							
						If (V_Flag!=0)
							Print "No right crossing at", frac,"times of peak in wave", WNameStr, "at", PeakAbsXTemp, "between",PeakAbsXTemp, 2*PeakAbsXTemp-SpikeThreshAbsXTemp
							RFracPAbsXTemp	= 	NaN
							RFracPXTemp		=  	NaN
							FWFracMTemp		= 	NaN
						Else
							RFracPAbsXTemp	= 	V_LevelX
							RFracPXTemp		=  	RFracPAbsXTemp+ i*LambdaW
							FWFracMTemp		= 	RFracPAbsXTemp - LFracPAbsXTemp								
						EndIf
						
						Wavestats /Q /R=(SpikeThreshAbsXTemp, PeakAbsXTemp)	Diffw
						SpkMaxDvDtYTemp			= V_Max
						
						SpkMaxDvDtAbsX			= V_MaxLoc
						SpkMaxDvDtXTemp			= SpkMaxDvDtAbsX + i*LambdaW
						
						SpkMaxDvDtAbsPntTemp	= x2Pnt(Diffw, SpkMaxDvDtAbsX)-SpikeThreshCrossAbsPntX			// Pnt value of Max with Thresh counted as point zero
						
						
//						WaveStats /Q/R=(PeakAbsXTemp, PeakAbsXTemp+AHPDelT) w
						If (NSpikesInWave>0)
//							If (NSpikesInWave==1)
//								DeletePoints Numpnts(AHPAbsX)-1,1,AHPAbsX, AHPX, AHPAbsY, AHPY
//							EndIf
							WaveStats /Q/R=(PeakAbsX[Numpnts(PeakAbsX)-1], PeakAbsXTemp) w
							AHPAbsXTemp		= V_MinLoc
							AHPXTemp			= AHPAbsXTemp + i*LambdaW
							AHPAbsYTemp		= V_Min
							AHPYTemp			= AHPAbsYTemp-SpkBLAvgY[Numpnts(SpkBLAvgY)-1]
							Concatenate /NP	{AHPAbsXTemp},			AHPAbsX; Concatenate /NP	{AHPAbsXTemp},			AHPAbsXWi
							Concatenate /NP	{AHPXTemp},			AHPX
							Concatenate /NP	{AHPAbsYTemp},			AHPAbsY; Concatenate /NP	{AHPAbsYTemp},			AHPAbsYWi
							Concatenate /NP	{AHPYTemp},			AHPY; Concatenate /NP	{AHPYTemp},			AHPYWi
							
							ISIMidAbsXTemp	= 	0.5*(PeakAbsX[Numpnts(PeakAbsX)-1]+ PeakAbsXTemp)
							WaveStats /Q/R	=	(ISIMidAbsXTemp-ISVDelT, ISIMidAbsXTemp+ISVDelT) w
							ISIMidXTemp	 	= 	ISIMidAbsXTemp + i*LambdaW
							ISVYTemp 		= 	V_Avg
							Concatenate /NP {ISIMidAbsXTemp}, 	ISIMidAbsX
							Concatenate /NP {ISIMidXTemp}, 		ISIMidX
							Concatenate /NP {ISVYTemp}, 			ISVY; Concatenate /NP {ISVYTemp}, 			ISVYWi
							
//							If (NumPnts(SpikeThreshY)!=NumPnts(AHPY))	
//								Print "********",SpikeThreshY(NumPnts(SpikeThreshY)-1), AHPY(NumPnts(AHPY)-1),"********"
//							EndIf	
						Else
//							AHPAbsXTemp		= NaN
//							AHPXTemp			= NaN
//							AHPAbsYTemp		= NaN
//							AHPYTemp			= NaN
//							Concatenate /NP	{AHPAbsXTemp},			AHPAbsX
//							Concatenate /NP	{AHPXTemp},			AHPX
//							Concatenate /NP	{AHPAbsYTemp},			AHPAbsY
//							Concatenate /NP	{AHPYTemp},			AHPY	
						EndIf
						Concatenate /NP	{TToFracPeakYTemp},	TToFracPeakY; Concatenate /NP	{TToFracPeakYTemp},	TToFracPeakYWi
						Concatenate /NP	{LFracPAbsXTemp},		LFracPAbsX; Concatenate /NP	{LFracPAbsXTemp},		LFracPAbsXWi
						Concatenate /NP	{LFracPXTemp},		LFracPX
						Concatenate /NP	{RFracPAbsXTemp},		RFracPAbsX; Concatenate /NP	{RFracPAbsXTemp},		RFracPAbsXWi
						Concatenate /NP	{RFracPXTemp},		RFracPX
						Concatenate /NP	{FracPAbsYTemp},		FracPAbsY; Concatenate /NP	{FracPAbsYTemp},		FracPAbsYWi
						Concatenate /NP	{FWFracMTemp},		FWFracM; Concatenate /NP	{FWFracMTemp}, FWFracMWi

						

				
						Concatenate /NP {SpkBLAvgYTemp}, 		SpkBLAvgY; Concatenate /NP {SpkBLAvgYTemp}, SpkBLAvgYWi
						Concatenate /NP {SpkBLAvgXTemp}, 		SpkBLAvgX
						Concatenate /NP {SpkBLAvgAbsXTemp}, 	SpkBLAvgAbsX		
						Concatenate /NP {PeakXTemp}, 			PeakX
						Concatenate /NP {PeakAbsXTemp}, 		PeakAbsX; Concatenate /NP {PeakAbsXTemp}, PeakAbsXWi
						Concatenate /NP {PeakAbsYTemp}, 		PeakAbsY; Concatenate /NP {PeakAbsYTemp}, PeakAbsYWi
						Concatenate /NP {PeakRelYTemp}, 		PeakRelY; Concatenate /NP {PeakRelYTemp}, PeakRelYWi
						Concatenate /NP	{SpikeThreshXTemp}, 		SpikeThreshX
						Concatenate /NP	{SpikeThreshAbsXTemp}, 	SpikeThreshAbsX; Concatenate /NP	{SpikeThreshAbsXTemp}, SpikeThreshXWi
						Concatenate /NP	{SpikeThreshYTemp}, 		SpikeThreshY; Concatenate /NP	{SpikeThreshYTemp}, SpikeThreshYWi
						
						// Maximum rate of change of voltage between Spk Threshold and Peak (indicative of Sodium Channel denstyKole et al. Nature neuroscience (2008) vol. 11 (2) pp. 178-86)
						Concatenate /NP	{SpkMaxDvDtAbsPntTemp}, 	SpkMaxDvDtAbsPnt//; Concatenate /NP	{SpkMaxDvDtAbsPntTemp}, 	SpkMaxDvDtAbsPntWi		// Pnt value of Max with Thresh counted as point zero
						Concatenate /NP	{SpkMaxDvDtXTemp}, 		SpkMaxDvDtX
						Concatenate /NP	{SpkMaxDvDtYTemp}, 		SpkMaxDvDtY; Concatenate /NP	{SpkMaxDvDtYTemp}, 		SpkMaxDvDtYWi
						
						
						
//						For (j=0; j<WNumSpikesTemp[0]; j+=1)
						If (CropEvents)
						Wave CropPksWj = $(GetDataFolder(1)+BaseNameStr+"CropPksF:"+BaseNameStr+"CropPksW"+Num2Str(i)+"_"+Num2Str(j))
						If (!WaveExists(CropPksWj))
						Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"CropPksF:"+BaseNameStr+"CropPksW"+Num2Str(i)+"_"+Num2Str(j))
						Wave CropPksWj = $(GetDataFolder(1)+BaseNameStr+"CropPksF:"+BaseNameStr+"CropPksW"+Num2Str(i)+"_"+Num2Str(j))
						Note /k CropPksWj "TraceName:"+WNameStr
						EndIf
						Duplicate /O /R=(SpkMaxDvDtAbsX-CropPreMaxSlpDelT, SpkMaxDvDtAbsX+CropPostMaxSlpDelT) w, CropPksWj  // align at max rise.
						SetScale /P x,0,dx, CropPksWj
						CropPksWj -= SpkBLAvgYTemp
						EndIf
						j+=1
//						EndFor
	
						
						NSpikesInWave +=1
					Else
//						Print "Peak at x=", V_PeakLoc,"relative amp.=", SpikeAmpRelative, "< SpikeAmpRelativeThresh=",SpikeAmpRelativeThresh ," in wave", WNameStr	
					EndIf
				EndIf	
			Else 				// no more peaks found in the pulse; now calculate EOPAHP and PrePlsBLY
				WNumSpikesTemp[0]=NSpikesInWave
				Concatenate /NP {WNumSpikesTemp}, WNumSpikes
				Duplicate /O WNumSpikes, WSpikeFreq
				WSpikeFreq /= abs(EndX-StartX) 
				If (NSpikesInWave>0)
					AHPAbsXTemp		= NaN
					AHPXTemp			= NaN
					AHPAbsYTemp		= NaN
					AHPYTemp			= NaN
					Concatenate /NP	{AHPAbsXTemp},			AHPAbsX; Concatenate /NP	{AHPAbsXTemp},			AHPAbsXWi
					Concatenate /NP	{AHPXTemp},			AHPX
					Concatenate /NP	{AHPAbsYTemp},			AHPAbsY; Concatenate /NP	{AHPAbsYTemp},			AHPAbsYWi
					Concatenate /NP	{AHPYTemp},			AHPY; Concatenate /NP	{AHPYTemp},			AHPYWi
					
					ISIMidAbsXTemp			= Nan
					ISIMidXTemp				= Nan
					ISVYTemp				= Nan
					Concatenate /NP {ISIMidAbsXTemp}, 	ISIMidAbsX
					Concatenate /NP {ISIMidXTemp}, 		ISIMidX
					Concatenate /NP {ISVYTemp}, 			ISVY; Concatenate /NP {ISVYTemp}, 			ISVYWi
					
						
				EndIf
				
				EOPAHPAbsXTemp			=	NaN
				EOPAHPXTemp				=	NaN
				EOPAHPAbsYTemp			=	NaN
				EOPAHPYTemp				=	NaN
				
				PrePlsBLAbsXTemp			=	NaN
				PrePlsBLXTemp				=	NaN
				PrePlsBLYTemp				=	NaN	
				
				If (NSpikesInWave>0)
					WaveStats /Q/R=(StartX-PrePlsBLDelT, StartX) w 
					PrePlsBLAbsXTemp	= StartX-0.5*PrePlsBLDelT
					PrePlsBLXTemp		= PrePlsBLAbsXTemp + i*LambdaW
					PrePlsBLYTemp		= V_Avg
					WaveStats /Q/R=(EndX, EndX+EOPAHPDelT) w
					EOPAHPAbsXTemp			=	V_MinLoc
					EOPAHPXTemp				=	EOPAHPAbsXTemp+ i*LambdaW
					EOPAHPAbsYTemp			=	V_Min
// for EOPAHP the steady state voltage may not be reached by end of wave. should be taken from before the pulse. 03/28/2007
//					EOPAHPYTemp	=	EOPAHPAbsYTemp-Mean(w, LambdaW-BLPreDelT, LambdaW)		
					EOPAHPYTemp	=	EOPAHPAbsYTemp - PrePlsBLYTemp
				EndIf	
					Concatenate /NP	{EOPAHPAbsXTemp},			EOPAHPAbsX; Concatenate /NP	{EOPAHPAbsXTemp},			EOPAHPAbsXWi
					Concatenate /NP	{EOPAHPXTemp},			EOPAHPX
					Concatenate /NP	{EOPAHPAbsYTemp},		EOPAHPAbsY; Concatenate /NP	{EOPAHPAbsYTemp},		EOPAHPAbsYWi
					Concatenate /NP	{EOPAHPYTemp},			EOPAHPY
					
					Concatenate /NP	{PrePlsBLAbsXTemp},			PrePlsBLAbsX
					Concatenate /NP	{PrePlsBLXTemp},			PrePlsBLX
					Concatenate /NP	{PrePlsBLYTemp},			PrePlsBLY
				Break	 
			EndIf
		Else
			FindPeak 	/N	/B=(BoxSmoothingPnts) /M=(SpikeAmpAbsThresh) /Q/R=(x1,x2) w
			If (V_Flag==0)
				//y1=mean(V_PeakLoc-BLPreT-BLPreDelT,V_PeakLoc-BLPreT)
				x1=V_PeakLoc+RefractoryPeriod
				SpikeThreshStartX=V_PeakLoc-SpikeThreshWin
				SpikeThreshEndX=V_PeakLoc
				
				FindLevel /Q/R=(SpikeThreshStartX, SpikeThreshEndX) Diffw, SpikeThreshDerivLevel

				If (V_Flag!=0)
					Print "Cudn't find spike amp. thresh for spike at", V_PeakLoc,"in wave", WNameStr
				Else 	
					BLStartX=V_LevelX-BLPreDelT
					BLEndX=V_LevelX
					SpikeAmpRelative=V_PeakVal-mean( w, BLStartX, BLEndX)
//					print mean( w, BLStartX, BLEndX)
					If (SpikeAmpRelative <=SpikeAmpRelativeThresh)
						PeakAbsXTemp	=	V_PeakLoc; PeakAbsYTemp=V_PeakVal; PeakRelYTemp=SpikeAmpRelative
						PeakXTemp		=	PeakAbsXTemp+ i*LambdaW
						SpikeThreshAbsXTemp	=	V_LevelX; SpikeThreshYTemp=w[x2pnt(w,V_LevelX)]
						SpikeThreshXTemp		=	SpikeThreshAbsXTemp+i*LambdaW
						Concatenate /NP {PeakXTemp}, PeakX
						Concatenate /NP {PeakAbsXTemp}, PeakAbsX; Concatenate /NP {PeakAbsXTemp}, PeakAbsXWi
						Concatenate /NP {PeakAbsYTemp}, PeakAbsY; Concatenate /NP {PeakAbsYTemp}, PeakAbsYWi
						Concatenate /NP {PeakRelYTemp}, PeakRelY
						Concatenate /NP	{SpikeThreshXTemp}, SpikeThreshX
						Concatenate /NP	{SpikeThreshAbsXTemp}, SpikeThreshAbsX
						Concatenate /NP	{SpikeThreshYTemp}, SpikeThreshY
						NSpikesInWave +=1
					Else
//						Print "Peak at x=", V_PeakLoc,"relative amp.=", SpikeAmpRelative, "> SpikeAmpRelativeThresh=",SpikeAmpRelativeThresh ," in wave", WNameStr	
					EndIf
				EndIf	
			Else 
				WNumSpikesTemp[0]=NSpikesInWave
				Concatenate /NP {WNumSpikesTemp}, WNumSpikes
				Duplicate /O WNumSpikes, WSpikeFreq
				WSpikeFreq /= abs(EndX-StartX) 
				Break	 
			EndIf
		EndIf	
	While(1)




//	For (j=0; j<WNumSpikesTemp[0]; j+=1)
//	Make /O/N=0 $(GetDataFolder(1)+BaseNameStr+"CropPksF:"+BaseNameStr+"CropPksW"+Num2Str(i)+"_"+Num2Str(j))
//	Wave CropPksWj = $(GetDataFolder(1)+BaseNameStr+"CropPksF:"+BaseNameStr+"CropPksW"+Num2Str(i)+"_"+Num2Str(j))
////	Print MaxRiseXWi[j], MaxRiseXWi[j]-CropPreMaxSlpDelT, MaxRiseXWi[j]+CropPostMaxSlpDelT
//	Duplicate /O /R=(SpkMaxDvDtXWi[j]-CropPreMaxSlpDelT, SpkMaxDvDtXWi[j]+CropPostMaxSlpDelT) w, CropPksW  // align at max rise.
//	SetScale /P x,0,dx, CropPksW
//	CropPksW -= mean( w, BLStartX, BLEndX)
//	EndFor
	
					
EndFor

// Also generate ISI and Inst. Freq waves
//******************
// Inst. Freq

If  (NumWaves > 0)
Wave /T T2ISIAnalParNamesW		=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParNamesW")		
Wave /T T2ISIAnalParW				=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParW")

Duplicate /O/T T2ISIAnalParW, T2ISIAnalParWOrig

T2ISIAnalParW[0]	=	BaseNameStr+"PeakAbsXW*" // DataWaveMatchStr
T2ISIAnalParW[1]	=	""					//DataWaveNotMatchStr
//AnalParW[2]	=	"InstFrq"			//InsrtNewStr
T2ISIAnalParW[2]	=	"IFrq"			//InsrtNewStr
T2ISIAnalParW[3]	=	Num2Str(BaseNameLen)//"-1"					//  InsrtPosStr
T2ISIAnalParW[4]	=	"0"					//ReplaceExisting 
T2ISIAnalParW[5]	=	BaseNameStr+"PeakAbsXF:"	//SubFldr
T2ISIAnalParW[6]	=	"1"						// Invert
pt_ConvertTSpikeToISI()

// ISI
T2ISIAnalParW[2]	=	"ISI"			//InsrtNewStr
T2ISIAnalParW[3]	=	Num2Str(BaseNameLen)//"-1"					//  InsrtPosStr
T2ISIAnalParW[4]	=	"0"					//ReplaceExisting 
T2ISIAnalParW[5]	=	BaseNameStr+"PeakAbsXF:"	//SubFldr
T2ISIAnalParW[6]	=	"0"						// Invert
pt_ConvertTSpikeToISI()

Duplicate /O/T T2ISIAnalParWOrig, T2ISIAnalParW
Killwaves /Z T2ISIAnalParWOrig



//******************
// move waves to folders
//******************
// Inst. Freq
//mOrigDf = GetDataFolder(1)


mDestFolderName = GetDataFolder(1)+BaseNameStr+"IFrqF"
NewDataFolder /O $mDestFolderName

mWList=pt_SortWavesInFolder(BaseNameStr+"IFrq"+"PeakAbsXW*", GetDataFolder(1)+BaseNameStr+"PeakAbsXF:")
mNumwaves=ItemsInList(mWList, ";")

//NewDataFolder /O $"root:"+BaseNameStr+"PeakAbsXF:"
For (i=0; i<mNumWaves; i+=1) 
		mWNameStr=StringFromList(i, mWList, ";") 
		Wave w=$GetDataFolder(1)+BaseNameStr+"PeakAbsXF:"+mWNameStr
		mDestWName = replaceString("PeakAbsX",  mWNameStr, "")
		Duplicate /O w,$(mDestFolderName+":"+mDestWName)
		KillWaves /Z w
EndFor 

//******************
// ISI
//mOrigDf = GetDataFolder(1)


mDestFolderName = GetDataFolder(1)+BaseNameStr+"ISIF"
NewDataFolder /O $mDestFolderName

mWList=pt_SortWavesInFolder(BaseNameStr+"ISI"+"PeakAbsXW*", GetDataFolder(1)+BaseNameStr+"PeakAbsXF:")
mNumwaves=ItemsInList(mWList, ";")

//NewDataFolder /O $"root:"+BaseNameStr+"PeakAbsXF:"
//TestTest
For (i=0; i<mNumWaves; i+=1) 
		mWNameStr=StringFromList(i, mWList, ";") 
		Wave w=$GetDataFolder(1)+BaseNameStr+"PeakAbsXF:"+mWNameStr
		mDestWName = replaceString("PeakAbsX",  mWNameStr, "")
		Duplicate /O w,$(mDestFolderName+":"+mDestWName)
		KillWaves /Z w
EndFor

EndIf

//SetDataFolder $mOrigDf

//******************
		
Killwaves /Z PeakXTemp, PeakAbsXTemp, PeakAbsYTemp, PeakRelYTemp, SpikeThreshXTemp, SpikeThreshAbsXTemp, SpikeThreshYTemp, w, DiffW, Diff3W, Diff3w_Smth, WNumSpikesTemp, WNameTemp, FICurrWTemp
KillWaves /Z LFracPXTemp, LFracPAbsXTemp, RFracPXTemp, RFracPAbsXTemp, FracPAbsYTemp, TToFracPeakYTemp, FWFracMTemp, AHPAbsXTemp, AHPXTemp, AHPAbsYTemp, AHPYTemp					
KillWaves /Z EOPAHPAbsXTemp, EOPAHPXTemp, EOPAHPAbsYTemp, EOPAHPYTemp, SpkBLAvgYTemp, SpkBLAvgXTemp, SpkBLAvgAbsXTemp
KillWaves /Z PrePlsBLAbsXTemp, PrePlsBLXTemp, PrePlsBLYTemp
KillWaves /Z ISIMidAbsXTemp, ISIMidXTemp, ISVYTemp
KillWaves /Z FISpkMaxDvDtAbsPntTemp, FISpkMaxDvDtYTemp, FISpkMaxDvDtXTemp


End

Function pt_SpikeAnalAuto()
// To automate steps for pt_SpikeAnal
// Typically following steps are done manually
// 1. pt_AnalWInFldrs2("pt_SpikeAnal")
// 2. pt_AnalWInFldrs2("pt_ExtractFromWaveNote")
// 3. Enter pt_RepsInfo for each cell
// 4. pt_AnalWInFldrs2("pt_Ext ractRepsNSrt")
// 5. pt_AnalWInFldrs2("pt_AverageWaves")
// 6. pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")
// 7. pt_MoveWaves()
// 8. pt_DisplayWFrmFldrs()
// 9. pt_AverageWaves()	
End

Function pt_SpikeAnalDisplay()

// XYParList for pt_SpikeAnal
// FIPeakAbsY;FIFracPAbsY;FIFracPAbsY;FISpikeThreshY;FISpkBLAvgY;FIAHPAbsY;FIPrePlsBLY;FIEOPAHPAbsY;FIISVY -----XParList 
// FIPeakX;FILFracPX;FIRFracPX;FISpikeThreshX;FISpkBLAvgX;FIAHPX;FIPrePlsBLX;FIEOPAHPX;FIISIMidX -----YParList 

// XYParList for pt_CalPeak
// 	VhBLY;VhPeakAbsY;VhSSAbsY		X-ParList
// 	VhBLX;VhPeakX;VhSSX 				Y-ParList

// FSpontPeakAbsY;FSpontFracPAbsY;FSpontFracPAbsY;FSpontSpikeThreshY;FSpontSpkBLAvgY;FSpontAHPAbsY;FSpontPrePlsBLY;FSpontEOPAHPAbsY;FSpontISVY -----XParList 
// FSpontPeakX;FSpontLFracPX;FSpontRFracPX;FSpontSpikeThreshX;FSpontSpkBLAvgX;FSpontAHPX;FSpontPrePlsBLX;FSpontEOPAHPX;FSpontISIMidX -----YParList 

// Append to top-graph the concatenated Spike Anal results. The top-graph is expected
// to display concatenated data waves.
String YWNameList, XWNameList

Variable N, i
String YWaveStr, XWaveStr, TraceNameStr, LastUpdatedMM_DD_YYYY="01_26_2009"

Print "*********************************************************"
Print "pt_SpikeAnalDisplay last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW	=	$pt_GetParWave("pt_SpikeAnalDisplay","ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_SpikeAnalDisplay","ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_SpikeAnalDisplay!!!"
EndIf

PrintAnalPar("pt_SpikeAnalDisplay")

YWNameList 	= AnalParW[0]
XWNameList	= AnalParW[1]

If (ItemsInList(YWNameList) !=ItemsInList(XWNameList) )
	Abort "Unequal number of X and Y waves"
Else
	N= ItemsInList(YWNameList)
EndIf

For (i=0; i<N; i+=1)
	YWaveStr = StringFromList(i, YWNameList, ";")
	XWaveStr = StringFromList(i, XWNameList, ";")
	Wave YWave=$(YWaveStr)
	Wave XWave=$(XWaveStr)
	AppendToGraph YWave vs XWave
	TraceNameStr = YWaveStr
	ModifyGraph mode($TraceNameStr)=3
	ModifyGraph marker($TraceNameStr)=i
	ModifyGraph rgb($TraceNameStr)=(0,0,0)
EndFor
End

Function pt_CalBinSpkW()
// To find correlation (of activity for example) between 2 waves (eg two or more cells recorded together), we can use correlate 
// which gives an output wave that calculates correlation as one wave is slid past another. Rather than correlating raw voltage 
// waves we may be more interested in just correlating spikes. For that reason we can make waves which are zero everywhere
// when there is no spike and 1 when there is spike. This function will do that.

// Logic - 
//1. We could use pt_Reps info to limit the number of waves that are created
String LastUpdatedMM_DD_YYYY
Print "*********************************************************"
Print "pt_CalBinSpkWAnalDisplay last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalBinSpkWAnalDisplay","ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_CalBinSpkWAnalDisplay","ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_CalBinSpkWAnalDisplay!!!"
EndIf

PrintAnalPar("pt_CalBinSpkWAnalDisplay")

//BaseName 	= AnalParW[0]
//NPnts		= AnalParW[1]
//XOffset
//XDelta
//SpkTW
//SubFldr
//RangeW
//RangeWPrefixStr

End


Function pt_BurstAnalDisplay()

// Append to top-graph the concatenated Burst Anal results. The top-graph is expected
// to display concatenated data waves.
String YWNameList, XWNameList

Variable N, i
String YWaveStr, XWaveStr, TraceNameStr, LastUpdatedMM_DD_YYYY="01_26_2009"

Print "*********************************************************"
Print "pt_BurstAnalDisplay last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW		=	$pt_GetParWave("pt_BurstAnalDisplay","ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_BurstAnalDisplay","ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_BurstAnalDisplay!!!"
EndIf

PrintAnalPar("pt_BurstAnalDisplay")

YWNameList 	= AnalParW[0]
XWNameList	= AnalParW[1]

If (ItemsInList(YWNameList) !=ItemsInList(XWNameList) )
	Abort "Unequal number of X and Y waves"
Else
	N= ItemsInList(YWNameList)
EndIf

For (i=0; i<N; i+=1)
	YWaveStr = StringFromList(i, YWNameList, ";")
	XWaveStr = StringFromList(i, XWNameList, ";")
	Wave YWave=$(YWaveStr)
	Wave XWave=$(XWaveStr)
	AppendToGraph YWave vs XWave
	TraceNameStr = YWaveStr
	ModifyGraph mode($TraceNameStr)=3
	ModifyGraph marker($TraceNameStr)=i
	ModifyGraph rgb($TraceNameStr)=(0,0,0)
EndFor
End



Function pt_SpikeNthAnal()

String NSpikesInTrainW, ParW
Variable SpikeNum, Num, SumSpikes, i 



// find parameters for nth spike in a current injection

Wave /T AnalParW=$("root:FuncParWaves:pt_SpikeNthAnal"+"ParW")
If (WaveExists(AnalParW)==0)
	Abort	"Cudn't find the parameter wave pt_SpikeNthAnalParW!!!"
EndIf

PrintAnalPar("pt_SpikeNthAnal")

NSpikesInTrainW		=	AnalParW[0]
ParW				=	AnalParW[1]
SpikeNum			=	Str2Num(AnalParW[2])	// count from zero


Wave w		=	$NSpikesInTrainW
Num 		=	NumPnts(w)
Make /O/N	=	(Num) $(ParW+Num2Str(SpikeNum)+"Spk")


Wave w1	=	$ParW
Wave w2	=	$(ParW+Num2Str(SpikeNum)+"Spk")			


SumSpikes	= 0
w2			= Nan
For (i=0; i<Num; i+=1)

	Do
		If (w[i]==0)
			i+=1
			If (i>=Num)
				Break	// Break only if W[i] ==0 and no more points in w 
			EndIf
		Else
			Break		// Break only if W[i] !=0
		EndIf	
	While (1)
	
	If (i>=Num)
		Break
	EndIf
	w2[i]	=	w1[SpikeNum + SumSpikes]
	SumSpikes += w[i]


EndFor

End


Function pt_SpikeReAnal()
// This is always the latest version
// small bug for extracting ExtractParW corresponding to 0th index value of NSpikesInTrainW. // for 0th point there is no point before 
// (found while analyzing spontaneous activity data which were the 1st 10 waves) 11_17_2008 praveen.

// aim to pull out data from the data generated by pt_SpikeAnal which concatenates all the analyzed data. 
//to pull out the required data we need to find out which waves we want and for those waves pull out the pars that we want. 
 
String	NSpikesinTrainWName,BaseStr, SuffixStr, RangeW	
Variable TestVal, TestValDelta, N, i=0, j=0,s, e, PulsePar, x1,x2 
Variable PntsPerRep, StartPnt, NumReps


// find parameters for nth spike in a current injection

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_SpikeReAnal"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_SpikeReAnal"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_SpikeReAnalParW and/or pt_SpikeReAnalParNamesW!!!"
EndIf


PrintAnalPar("pt_SpikeReAnal")

Wave NSpikesInTrainW		=	$(AnalParW[0]); NSpikesinTrainWName=AnalParW[0]
Wave ExtractParW			=	$(AnalParW[1])
TestVal						=	Str2Num(AnalParW[2])	// count from zero
TestValDelta					=	Str2Num(AnalParW[3])
Wave TestW					=    $(AnalParW[4])
BaseStr						=	 AnalParW[5]
SuffixStr						=	 AnalParW[6]
PulsePar					= 	Str2Num(AnalParW[7])
RangeW						=	 AnalParW[8]	

Wave /T AnalParNamesW		=	$pt_GetParWave(RangeW, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(RangeW, "ParW")

PntsPerRep				=	Str2Num(AnalParW[0])
StartPnt					=	Str2Num(AnalParW[1])
NumReps				=	Str2Num(AnalParW[2])

PrintAnalPar(RangeW)


If (PntsPerRep*NumReps!=0)

N	=	NumPnts(TestW)
Make /O/N=0 IndexW
Make /O/N=1 IndexWTemp


For (j=0; j<NumReps; j+=1)
i=0
Do
	If (i>=N)
		Break
	EndIf

 	If (Abs(TestW[i]-TestVal)<=TestValDelta)			
 		IndexWTemp[0]=i+(StartPnt-1)+j*PntsPerRep
 		Concatenate /NP {IndexWTemp}, IndexW
 	EndIf
	i+=1
While (1)
EndFor


N 	=	NumPnts(IndexW)
Print "Num selected waves=", N, "Index Nums =",IndexW

//Duplicate /O NSpikesInTrainW, NSpikesInTrainWTmp
//DeletePoints 0,NSpikesInTrainWOffSet,NSpikesInTrainWTmp


For (i=0; i<N; i+=1)
	If (!PulsePar)			// Spike-dep parameter	(eg AHP, Spike-thresh, etc.)
	
//	x1=pnt2x(NSpikesInTrainWTmp,0)
//	x2=pnt2x(NSpikesInTrainWTmp,(IndexW[i]-1))
//	s	=	Sum(NSpikesInTrainWTmp, x1,x2)	
//	
//	x1=pnt2x(NSpikesInTrainWTmp,0)
//	x2=pnt2x(NSpikesInTrainWTmp, IndexW[i])
//	e	=	Sum(NSpikesInTrainWTmp, x1,x2) -1	
	
	x1=pnt2x(NSpikesInTrainW,0)
	x2=pnt2x(NSpikesInTrainW,(IndexW[i]-1))
	s	=	Sum(NSpikesInTrainW, x1,x2)	
	If (IndexW[i]==0)								// for 0th point there is no point before (found while analyzing spontaneous activity data
												// which were the 1st 10 waves) 11_17_2008 praveen.
		x2	=pnt2x(NSpikesInTrainW,(IndexW[i]))
		s  	=0
	EndIf
	
	
	x1=pnt2x(NSpikesInTrainW,0)
	x2=pnt2x(NSpikesInTrainW, IndexW[i])
	e	=	Sum(NSpikesInTrainW, x1,x2) -1	
	
	
	
//	If (s!=e)
	If (e-s>=0)
		Duplicate /O /R=(s,e) ExtractParW, $(BaseStr+SuffixStr+Num2Str(i))
		SetScale /P x,0,1,$(BaseStr+SuffixStr+Num2Str(i))
		Print "Num spikes in wave", NSpikesinTrainWName, "[", IndexW[i],"]=", NSpikesInTrainW[IndexW[i]]
	Else
		Print "NO SPIKES IN WAVE!!", NSpikesinTrainWName, "[", IndexW[i],"]=", NSpikesInTrainW[IndexW[i]]
	EndIf	
	
	Else				// Pulse-dep parameter	(eg. EndOfPulse AHP)
		Duplicate /O /R=(IndexW[i], IndexW[i]) ExtractParW, $(BaseStr+SuffixStr+Num2Str(i))
		SetScale /P x,0,1,$(BaseStr+SuffixStr+Num2Str(i))
	EndIf
	
//	pt_AverageWaves(BaseNameString, PntsPerBin, ExcludeWNamesWStr)
	
EndFor

Killwaves IndexWTemp, IndexW//, NSpikesInTrainW

Else
	Print "Attention! Either PntsPerRep OR NumReps =0!!! No Wave Generated"
EndIf

End

Function pt_SpikeReAnalVarPar1()
// wrapper for pt_SpikeReAnal. will run pt_SpikeReAnal with some parameters varied
String TestValStrOld, SuffixStrOld, TestValList, SuffixStrList
Variable NTestValList, NSuffixStrList, i
String LastUpdatedMM_DD_YYYY="08_05_2008"
Print "*********************************************************"
Print "pt_SpikeReAnalVarPar1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_SpikeReAnal"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_SpikeReAnal"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_SpikeReAnalParW and/or pt_SpikeReAnalParNamesW!!!"
EndIf


TestValStrOld					=	AnalParW[2]	// count from zero
SuffixStrOld						=	AnalParW[6]

//TestValList   = "0.00;0.03;0.06;"
//TestValList += "0.09;0.12;0.15;"
//TestValList += "0.18;0.21;0.24;"
//TestValList += "0.27;0.30;0.33;"
//TestValList += "0.36;0.39;0.42;"
//TestValList += "0.45;0.48;0.51;"
//TestValList += "0.54;0.57;"



//SuffixStrList	= "000pA;030pA;060pA;"
//SuffixStrList+= "090pA;120pA;150pA;"
//SuffixStrList+= "180pA;210pA;240pA;"
//SuffixStrList+= "270pA;300pA;330pA;"
//SuffixStrList+= "360pA;390pA;420pA;"
//SuffixStrList+= "450pA;480pA;510pA;"
//SuffixStrList+= "540pA;570pA"

TestValList   = "0.00;0.06;"
TestValList += "0.12;"
TestValList += "0.18;0.24;"
TestValList += "0.30;"
TestValList += "0.36;0.42;"
TestValList += "0.48;"
TestValList += "0.54;"

//TestValList   =	"0.000;0.025;0.050;0.075;"
//TestValList +=	"0.100;0.125;0.150;0.175;"
//TestValList +=	"0.200;0.225;0.250;0.275;"
//TestValList +=	"0.300;0.325;0.350;0.375;"
//TestValList +=	"0.400;0.425;0.450;0.475;"
//TestValList +=	"0.500;0.525;0.550;0.575;"
//TestValList +=	"0.600;0.625;0.650;0.675;"
//TestValList +=	"0.700;0.725;0.750;0.775;"
//TestValList +=	"0.800;0.825;0.850;0.875;"
//TestValList +=	"0.900;0.925;0.950;0.975;"
//TestValList +=	"1.000;1.025;1.050;1.075;"

//SuffixStrList	=	"000pA;025pA;050pA;075pA;" 
//SuffixStrList+=	"100pA;125pA;150pA;175pA;"
//SuffixStrList+=	"200pA;225pA;250pA;275pA;"
//SuffixStrList+=	"300pA;325pA;350pA;375pA;"
//SuffixStrList+=	"400pA;425pA;450pA;475pA;"
//SuffixStrList+=	"500pA;525pA;550pA;575pA;"
//SuffixStrList+=	"600pA;625pA;650pA;675pA;"
//SuffixStrList+=	"700pA;725pA;750pA;775pA;"
//SuffixStrList+=	"800pA;825pA;850pA;875pA;"
//SuffixStrList+=	"900pA;925pA;950pA;975pA;"
//SuffixStrList+=	"1000pA;1025pA;1050pA;1075pA;"




SuffixStrList	= "000pA;060pA;"
SuffixStrList+= "120pA;"
SuffixStrList+= "180pA;240pA;"
SuffixStrList+= "300pA;"
SuffixStrList+= "360pA;420pA;"
SuffixStrList+= "480pA;"
SuffixStrList+= "540pA;"



//TestValList   = "0.60;0.63;0.66;"
//TestValList += "0.69;0.72;0.75;"
//TestValList += "0.78;0.81;0.84;"
//TestValList += "0.87;0.90;0.93;"
//TestValList += "0.96;0.99;1.02;"
//TestValList += "1.05;1.08;1.11;"
//TestValList += "1.14;1.17;"



//SuffixStrList	= "600pA;630pA;660pA;"
//SuffixStrList+= "690pA;720pA;750pA;"
//SuffixStrList+= "780pA;810pA;840pA;"
//SuffixStrList+= "870pA;900pA;930pA;"
//SuffixStrList+= "960pA;990pA;1020pA;"
//SuffixStrList+= "1050pA;1080pA;1110pA;"
//SuffixStrList+= "1140pA;1170pA"

NTestValList = ItemsInList(TestValList, ";")
NSuffixStrList = ItemsInList(TestValList, ";")

If (NTestValList != NSuffixStrList)
Abort "Unequal number of items in list of varied parameters"
EndIf

For (i=0; i<NTestValList; i+=1)
AnalParW[2] = StringFromList(i,TestValList, ";")
AnalParW[6] = StringFromList(i,SuffixStrList, ";")
pt_AnalWInFldrs2("pt_SpikeReAnal")
EndFor

AnalParW[2] = TestValStrOld
AnalParW[6] = SuffixStrOld

End

Function pt_ConvertTSpikeToISI()

// modified to use subfolder in CurrentDataFolder 12_27_2010 to use after pt_ExtractWRepsNSrt.
// Also make new wave only if (NumPnts(w)>1) 12_27_2010. Also, add invert option to convert to frequency.
// REMEMBER AVERAGING ISI AND INVERTING IS NOT THE SAME AS INVERTING AND AVERAGING. 12/28/2010

// modified to use pt_CalNewNameStr 03/06/2009
// updated with features from pt_ConvertTSpikeToMidT that allow you to add a 
// string in middle of WaveNameStr and also prints wavenames to be converted 02_12_2009
// not really updated, just incorporated LastUpdatedMM_DD_YYYY 11_09_2008
// after excluding the waves that shudn't be included

String DataWaveMatchStr, DataWaveNotMatchStr, InsrtNewStr, InsrtPosStr, SubFldr
Variable ReplaceExisting,  Invert
String NewWStr, WStr, WAllList, WList, SScanfFrmtStr, StrStrt, StrEnd
String LastUpdatedMM_DD_YYYY="12_28_2010"
Variable N, i, NPnts 

Print "*********************************************************"
Print "pt_ConvertTSpikeToISI() last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParW=$("root:FuncParWaves:pt_ConvertTSpikeToISI"+"ParW")
If (WaveExists(AnalParW)==0)
	Abort	"Cudn't find the parameter wave pt_ConvertTSpikeToISIParW!!!"
EndIf

PrintAnalPar("pt_ConvertTSpikeToISI")

DataWaveMatchStr				=		AnalParW[0]
DataWaveNotMatchStr			=		AnalParW[1]
//SuffixStr						=		AnalParW[2]	
InsrtNewStr						=		AnalParW[2]
InsrtPosStr						=		AnalParW[3]	// -1 =prefix, 0=suffix, 1=after 1st char, etc...
ReplaceExisting					= 		Str2Num(AnalParW[4])
SubFldr							= 		AnalParW[5]
Invert							=		Str2Num(AnalParW[6])

WAllList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
N=	ItemsInList(WAllList,";")
WList=""
For (i=0;i<N;i+=1)
	WStr=StringFromList(i, WAllList,";")
	If  (StringMatch(WStr, DataWaveNotMatchStr)==0)
		WList += WStr+";" 
	EndIf
EndFor

N=	ItemsInList(WList,";")
Print "Converting SpikeT to MidT for waves N=",N,WList



For (i=0; i<N; i+=1)
	WStr=StringFromList(i, WList,";")
//	If (StringMatch(WStr, DataWaveNotMatchStr)==0)
		Wave w=$(GetDataFolder(1)+SubFldr+WStr)
//		StrSwitch (InsrtPosStr)
//		Case "-1":	//prefix
//			NewWStr = InsrtNewStr+WStr
//			Break
//		Case "0":	//suffix
//			NewWStr = WStr+InsrtNewStr
//			Break	
//		default:
//			SScanfFrmtStr = "%"+InsrtPosStr+"s%s"
//			Sscanf WStr, SScanfFrmtStr, StrStrt, StrEnd
//			NewWStr = StrStrt+InsrtNewStr+StrEnd
//			Break
//		EndSwitch
		NewWStr  = pt_CalNewNameStr(WStr, InsrtNewStr, InsrtPosStr, ReplaceExisting)
//		Print 	GetDataFolder(1)+SubFldr+NewWStr
		NPnts = NumPnts(w)
		If (NumPnts(w)>1)
		Make /O/N=(NumPnts(w)-1) $(GetDataFolder(1)+SubFldr+NewWStr)
		Wave w1=$(GetDataFolder(1)+SubFldr+NewWStr)
		w1 = (Invert) ? 1/(w[p+1]-w[p]) : (w[p+1]-w[p])
		Else	// assign instantaneous frequency = Nan. That way we will have the full instantaneous frequnecy vs I curve
		Make /O/N=1 $(GetDataFolder(1)+SubFldr+NewWStr)
		Wave w1=$(GetDataFolder(1)+SubFldr+NewWStr)
		w1=Nan
		EndIf
//	EndIf
EndFor	
End

Function pt_ConvertTSpikeToISIVarPar1()

// wrapper for pt_ConvertTSpikeToISI. will run pt_ConvertTSpikeToISI with some parameters varied
String DataWaveMatchStrOld, DataWaveMatchStrList
Variable NDataWaveMatchStrList, i
String LastUpdatedMM_DD_YYYY="08_05_2008"
Print "*********************************************************"
Print "pt_ConvertTSpikeToISIVarPar1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_ConvertTSpikeToISI"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_ConvertTSpikeToISI"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_ConvertTSpikeToISIParW and/or pt_ConvertTSpikeToISIParNamesW!!!"
EndIf


DataWaveMatchStrOld		=	AnalParW[0]	// count from zero


//DataWaveMatchStrList   = "F_ISpkT000pA*;F_ISpkT030pA*;F_ISpkT060pA*;"
//DataWaveMatchStrList += "F_ISpkT090pA*;F_ISpkT120pA*;F_ISpkT150pA*;"
//DataWaveMatchStrList += "F_ISpkT180pA*;F_ISpkT210pA*;F_ISpkT240pA*;"
//DataWaveMatchStrList += "F_ISpkT270pA*;F_ISpkT300pA*;F_ISpkT330pA*;"
//DataWaveMatchStrList += "F_ISpkT360pA*;F_ISpkT390pA*;F_ISpkT420pA*;"
//DataWaveMatchStrList += "F_ISpkT450pA*;F_ISpkT480pA*;F_ISpkT510pA*;"
//DataWaveMatchStrList += "F_ISpkT540pA*;F_ISpkT570pA*;"

//DataWaveMatchStrList   = "F_ISpkTA000pA*;F_ISpkTA030pA*;F_ISpkTA060pA*;"
//DataWaveMatchStrList += "F_ISpkTA090pA*;F_ISpkTA120pA*;F_ISpkTA150pA*;"
//DataWaveMatchStrList += "F_ISpkTA180pA*;F_ISpkTA210pA*;F_ISpkTA240pA*;"
//DataWaveMatchStrList += "F_ISpkTA270pA*;F_ISpkTA300pA*;F_ISpkTA330pA*;"
//DataWaveMatchStrList += "F_ISpkTA360pA*;F_ISpkTA390pA*;F_ISpkTA420pA*;"
//DataWaveMatchStrList += "F_ISpkTA450pA*;F_ISpkTA480pA*;F_ISpkTA510pA*;"
//DataWaveMatchStrList += "F_ISpkTA540pA*;F_ISpkTA570pA*;"

//DataWaveMatchStrList   = "F_ISpkTB600pA*;F_ISpkTB630pA*;F_ISpkTB660pA*;"
//DataWaveMatchStrList += "F_ISpkTB690pA*;F_ISpkTB720pA*;F_ISpkTB750pA*;"
//DataWaveMatchStrList += "F_ISpkTB780pA*;F_ISpkTB810pA*;F_ISpkTB840pA*;"
//DataWaveMatchStrList += "F_ISpkTB870pA*;F_ISpkTB900pA*;F_ISpkTB930pA*;"
//DataWaveMatchStrList += "F_ISpkTB960pA*;F_ISpkTB990pA*;F_ISpkTB1020pA*;"
//DataWaveMatchStrList += "F_ISpkTB1050pA*;F_ISpkTB1080pA*;F_ISpkTB1110pA*;"
//DataWaveMatchStrList += "F_ISpkTB1140pA*;F_ISpkTB1170pA*;"

DataWaveMatchStrList   = "F_ISpkT000pA*;F_ISpkT025pA*;F_ISpkT050pA*;F_ISpkT075pA*;"
DataWaveMatchStrList +=	"F_ISpkT100pA*;F_ISpkT125pA*;F_ISpkT150pA*;F_ISpkT175pA*;"
DataWaveMatchStrList +=	"F_ISpkT200pA*;F_ISpkT225pA*;F_ISpkT250pA*;F_ISpkT275pA*;"
DataWaveMatchStrList +=	"F_ISpkT300pA*;F_ISpkT325pA*;F_ISpkT350pA*;F_ISpkT375pA*;"
DataWaveMatchStrList +=	"F_ISpkT400pA*;F_ISpkT425pA*;F_ISpkT450pA*;F_ISpkT475pA*;"
DataWaveMatchStrList +=	"F_ISpkT500pA*;F_ISpkT525pA*;F_ISpkT550pA*;F_ISpkT575pA*;"
DataWaveMatchStrList +=	"F_ISpkT600pA*;F_ISpkT625pA*;F_ISpkT650pA*;F_ISpkT675pA*;"
DataWaveMatchStrList +=	"F_ISpkT700pA*;F_ISpkT725pA*;F_ISpkT750pA*;F_ISpkT775pA*;"
DataWaveMatchStrList +=	"F_ISpkT800pA*;F_ISpkT825pA*;F_ISpkT850pA*;F_ISpkT875pA*;"
DataWaveMatchStrList +=	"F_ISpkT900pA*;F_ISpkT925pA*;F_ISpkT950pA*;F_ISpkT975pA*;"
DataWaveMatchStrList +=	"F_ISpkT1000pA*;F_ISpkT1025pA*;F_ISpkT1050pA*;F_ISpkT1075pA*;"



NDataWaveMatchStrList = ItemsInList(DataWaveMatchStrList, ";")


For (i=0; i<NDataWaveMatchStrList; i+=1)
AnalParW[0] = StringFromList(i,DataWaveMatchStrList, ";")
pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
EndFor

AnalParW[0] = DataWaveMatchStrOld

End

Function pt_ConvNansToZeros()
// can be used to replace Nan's in waves with zeros (for example after calculating instantaneous frequencies) before averaging

String DataWaveMatchStr

String wavlist, WNameStr
Variable NumWaves, i, N, j

String LastUpdatedMM_DD_YYYY="11_07_2009"
Print "*********************************************************"
Print "pt_ConvNansToZeros last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConvNansToZeros", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_ConvNansToZeros", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_ConvNansToZerosParW and/or pt_ConvNansToZerosParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]

PrintAnalPar("pt_ConvNansToZeros")

wavlist = wavelist(DataWaveMatchStr,";","")
NumWaves = ItemsInList(WavList,";")

If (!NumWaves>0)
Print "NumWaves <=0. No Waves to operate on!!"
Return -1
EndIf
print "Converting Nan's to zero's for waves...N=", NumWaves, wavlist

For (i=0; i< NumWaves; i+=1)
WNameStr= StringFromList(i,wavlist,";")
Wave w = $WNameStr
N = NumPnts(w)
For (j=0; j<N; j+=1)
If (NumType(w[j]) == 2)
w[j]=0
EndIf
EndFor
EndFor
End

Function pt_UnaryOpOnWaves()

String DataWaveMatchStr, UnaryOpStr, InsrtNewStr, InsrtPosStr
Variable ReplaceExisting
String wavlist, WaveNameStr, NewWaveNameStr
Variable NumWaves,i 

String LastUpdatedMM_DD_YYYY="02_12_2009"
Print "*********************************************************"
Print "pt_UnaryOpOnWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_UnaryOpOnWaves", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_UnaryOpOnWaves", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_UnaryOpOnWavesParW and/or pt_UnaryOpOnWavesParNamesW!!!"
EndIf

//example
//DataWaveMatchStr	F_ISpkTISIA210pA1
//UnaryOpStr			Inverse
//InsrtNewStr			Frq
//InsrtPosStr			10
//ReplaceExisting		0


DataWaveMatchStr		=	AnalParW[0]
UnaryOpStr				= 	AnalParW[1]
InsrtNewStr				=	AnalParW[2]
InsrtPosStr				=	AnalParW[3]	// -1 =prefix, 0=suffix, 1=after 1st char, etc..
ReplaceExisting			=    Str2Num(AnalParW[4])


PrintAnalPar("pt_UnaryOpOnWaves")

wavlist = wavelist(DataWaveMatchStr,";","")

NumWaves = ItemsInList(WavList,";")
If (!NumWaves>0)
Print "NumWaves <=0. No Waves to operate on!!"
Return -1
EndIf
print "Operating on waves...N=", NumWaves, wavlist

For (i=0; i< NumWaves; i+=1)
	
		WaveNameStr= StringFromList (i,wavlist,";")
		if (strlen(WaveNameStr)== 0)
			break
		endif
		NewWaveNameStr  = pt_CalNewNameStr(WaveNameStr, InsrtNewStr, InsrtPosStr, ReplaceExisting)
		If (!StringMatch(NewWaveNameStr, WaveNameStr))
		Duplicate /O $WaveNameStr, $NewWaveNameStr
		Wave w=$NewWaveNameStr
		Else
		Wave w=$WaveNameStr
		EndIf
		
		StrSwitch (UnaryOpStr)
		Case "Inverse":
			w=1/w
			Break
		Case "Square":
			w=w*w
			Break	
		default:
			Print UnaryOpStr+"undefined. define in pt_UnaryOpOnWaves first"
			Break
		EndSwitch
		
EndFor

End

Function pt_ScalarOpOnWaves()

// based on pt_UnaryOpOnWaves()

String DataWaveMatchStr, ScalarOpStr, InsrtNewStr, InsrtPosStr
Variable ReplaceExisting, ScalarVal
String wavlist, WaveNameStr, NewWaveNameStr
Variable NumWaves,i 

String LastUpdatedMM_DD_YYYY="03_05_2009"
Print "*********************************************************"
Print "pt_ScalarOpOnWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ScalarOpOnWaves", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_ScalarOpOnWaves", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_ScalarOpOnWavesParW and/or pt_ScalarOpOnWavesParNamesW!!!"
EndIf

//example
//DataWaveMatchStr	F_ISpkTISIA210pA1
//ScalarOpStr			Inverse
//InsrtNewStr			Frq
//InsrtPosStr			10
//ReplaceExisting		0


DataWaveMatchStr		=	AnalParW[0]
ScalarOpStr				= 	AnalParW[1]
ScalarVal				=	Str2Num(AnalParW[2])
InsrtNewStr				=	AnalParW[3]
InsrtPosStr				=	AnalParW[4]	// -1 =prefix, 0=suffix, 1=after 1st char, etc..
ReplaceExisting			=    Str2Num(AnalParW[5])


PrintAnalPar("pt_ScalarOpOnWaves")

wavlist = wavelist(DataWaveMatchStr,";","")

NumWaves = ItemsInList(WavList,";")
If (!NumWaves>0)
Print "NumWaves <=0. No Waves to operate on!!"
Return -1
EndIf
print "Operating on waves...N=", NumWaves, wavlist

For (i=0; i< NumWaves; i+=1)
	
		WaveNameStr= StringFromList (i,wavlist,";")
		if (strlen(WaveNameStr)== 0)
			break
		endif
		NewWaveNameStr  = pt_CalNewNameStr(WaveNameStr, InsrtNewStr, InsrtPosStr, ReplaceExisting)
		If (!StringMatch(NewWaveNameStr, WaveNameStr))
		Duplicate /O $WaveNameStr, $NewWaveNameStr
		Wave w=$NewWaveNameStr
		Else
		Wave w=$WaveNameStr
		EndIf
		
		StrSwitch (ScalarOpStr)
		
		Case "Add":
			w	+=ScalarVal
			Break
		
		Case "Subtract":
			w	-=ScalarVal
		Break
		
		Case "Multiply":
			w	*=ScalarVal
		Break
		
		Case "Divide":
			w	/=ScalarVal
		Break		
		
		default:
			Print ScalarOpStr+"undefined. define in pt_ScalarOpOnWaves first"
			Break
		EndSwitch
		
EndFor

End



Function pt_ConvertTSpikeToMidT()

// modified to use subfolder in CurrentDataFolder 03_16_13
// modified from pt_ConvertTSpikeToISI()
// calculate average time point for 2 successive spikes (eg. to plot ISI as a function of time we wud need such a wave)

String DataWaveMatchStr, DataWaveNotMatchStr, InsrtNewStr, WAllList, WList, WStr
Variable ReplaceExisting
String LastUpdatedMM_DD_YYYY="11_09_2008", StrStrt,StrEnd, NewWStr, SScanfFrmtStr,InsrtPosStr, SubFldr
Variable N, i, NPnts 

Print "*********************************************************"
Print "pt_ConvertTSpikeToMidT last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParW=$("root:FuncParWaves:pt_ConvertTSpikeToMidT"+"ParW")
If (WaveExists(AnalParW)==0)
	Abort	"Cudn't find the parameter wave pt_ConvertTSpikeToMidTParW!!!"
EndIf

PrintAnalPar("pt_ConvertTSpikeToMidT")

DataWaveMatchStr				=		AnalParW[0]
DataWaveNotMatchStr			=		AnalParW[1]
InsrtNewStr					=		AnalParW[2]
InsrtPosStr						=		AnalParW[3]	// -1 =prefix, 0=suffix, 1=after 1st char, etc...
ReplaceExisting					= 		Str2Num(AnalParW[4])
SubFldr							= 		AnalParW[5]

//DoAlert 0, "You may want to use pt_ConvertTSpikeToISI which finds ISI or InstFreq and corresponding time points"

WAllList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
N=	ItemsInList(WAllList,";")
WList=""
For (i=0;i<N;i+=1)
	WStr=StringFromList(i, WAllList,";")
	If  (StringMatch(WStr, DataWaveNotMatchStr)==0)
		WList += WStr+";" 
	EndIf
EndFor

N=	ItemsInList(WList,";")
Print "Converting SpikeT to MidT for waves N=",N,WList


For (i=0; i<N; i+=1)
	WStr=StringFromList(i, WList,";")
//	If (StringMatch(WStr, DataWaveNotMatchStr)==0)
		Wave w=$(GetDataFolder(1)+SubFldr+WStr)
//		StrSwitch (InsrtPosStr)
//		Case "-1":	//prefix
//			NewWStr = InsrtNewStr+WStr
//			Break
//		Case "0":	//suffix
//			NewWStr = WStr+InsrtNewStr
//			Break	
//		default:
//			SScanfFrmtStr = "%"+InsrtPosStr+"s%s"
//			Sscanf WStr, SScanfFrmtStr, StrStrt, StrEnd
//			NewWStr = StrStrt+InsrtNewStr+StrEnd
//			Break
//		EndSwitch
		NewWStr  = pt_CalNewNameStr(WStr, InsrtNewStr, InsrtPosStr, ReplaceExisting)
		NPnts = NumPnts(w)
		If (NumPnts(w)>1)
			Make /O/N=(NumPnts(w)-1) $(GetDataFolder(1)+SubFldr+NewWStr)
			Wave w1=$(GetDataFolder(1)+SubFldr+NewWStr)
			w1=0.5*(w[p+1]+w[p])
		Else
			Make /O/N=1 $(GetDataFolder(1)+SubFldr+NewWStr)
			Wave w1=$(GetDataFolder(1)+SubFldr+NewWStr)
			w1=Nan		
		//Make /O/N=(NumPnts(w)-1) $(NewWStr)
		//Wave w1=$(NewWStr)
//		w1=w[p+1]-w[p]	
			
		EndIf
//	EndIf
EndFor	
End

Function	/S pt_CalNewNameStr(OrigNameStr, InsrtNewStr, InsrtPosStr, ReplaceExisting)
String OrigNameStr, InsrtNewStr, InsrtPosStr	// -1 =prefix, 0=suffix, 1=after 1st char, etc...
Variable ReplaceExisting

String NewWStr, SScanfFrmtStr, StrStrt, StrReplc, StrEnd, LenNewStr

StrSwitch (InsrtPosStr)
		Case "-1":	//prefix
			NewWStr = InsrtNewStr+OrigNameStr
			Break
		Case "0":	//suffix
			NewWStr = OrigNameStr+InsrtNewStr
			Break	
		default:
			// OrigNameStr = "ABCDEF"; InsrtNewStr = "GH"; InsrtPosStr = "2"; 
			If (ReplaceExisting)
				LenNewStr=Num2Str(StrLen(InsrtNewStr))
				SScanfFrmtStr = "%"+InsrtPosStr+"s%"+LenNewStr+"s%s"
				Sscanf OrigNameStr, SScanfFrmtStr, StrStrt, StrReplc, StrEnd
				NewWStr = StrStrt+InsrtNewStr+StrEnd	
			Else
				SScanfFrmtStr = "%"+InsrtPosStr+"s%s"
				Sscanf OrigNameStr, SScanfFrmtStr, StrStrt, StrEnd
				NewWStr = StrStrt+InsrtNewStr+StrEnd		
			EndIf
			Break
EndSwitch
Return NewWStr

End


Function pt_ConvertTSpikeToMidTVarPar1()

// wrapper for pt_ConvertTSpikeToMidT. will run pt_ConvertTSpikeToMidT with some parameters varied
// based on pt_ConvertTSpikeToISIVarPar1()

String DataWaveMatchStrOld, DataWaveMatchStrList
Variable NDataWaveMatchStrList, i
String LastUpdatedMM_DD_YYYY="11_09_2008"
Print "*********************************************************"
Print "pt_ConvertTSpikeToMidTVarPar1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_ConvertTSpikeToMidT"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_ConvertTSpikeToMidT"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_ConvertTSpikeToMidTParW and/or pt_ConvertTSpikeToMidTParNamesW!!!"
EndIf


DataWaveMatchStrOld		=	AnalParW[0]	// count from zero


DataWaveMatchStrList   = "F_ISpkT000pA*;F_ISpkT030pA*;F_ISpkT060pA*;"
DataWaveMatchStrList += "F_ISpkT090pA*;F_ISpkT120pA*;F_ISpkT150pA*;"
DataWaveMatchStrList += "F_ISpkT180pA*;F_ISpkT210pA*;F_ISpkT240pA*;"
DataWaveMatchStrList += "F_ISpkT270pA*;F_ISpkT300pA*;F_ISpkT330pA*;"
DataWaveMatchStrList += "F_ISpkT360pA*;F_ISpkT390pA*;F_ISpkT420pA*;"
DataWaveMatchStrList += "F_ISpkT450pA*;F_ISpkT480pA*;F_ISpkT510pA*;"
DataWaveMatchStrList += "F_ISpkT540pA*;F_ISpkT570pA*;"

NDataWaveMatchStrList = ItemsInList(DataWaveMatchStrList, ";")


For (i=0; i<NDataWaveMatchStrList; i+=1)
AnalParW[0] = StringFromList(i,DataWaveMatchStrList, ";")
pt_AnalWInFldrs2("pt_ConvertTSpikeToMidT")
EndFor

AnalParW[0] = DataWaveMatchStrOld

End


Function pt_KillWFrmFldrs()
// modified to include subfolder 12/28/2010. Also instead of specifying 1 ExcludeWName per row, specifiy the list in AnalParW[1]
String DataWaveMatchStr, WList, WList1, WStr, ExcludeWList, SubFldr	
Variable N, i, j//, NumExcludeW 

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_KillWFrmFldrs"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_KillWFrmFldrs"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_KillWFrmFldrsParW and/or pt_KillWFrmFldrsParNamesW!!!"
EndIf

PrintAnalPar("pt_KillWFrmFldrs")


DataWaveMatchStr			=		AnalParW[0]
//NumExcludeW	= NumPnts(AnalParW) -1
ExcludeWList				=		AnalParW[1]
SubFldr						= 		AnalParW[2]

WList1=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)

//ExcludeWList=""

//For (j=0; j<NumExcludeW; j+=1)
//	ExcludeWList=ExcludeWList+pt_SortWavesInFolder(AnalParW[j+1], GetDataFolder(1)+SubFldr)
//EndFor

WList = RemoveFromList(ExcludeWList, WList1, ";")

N=	ItemsInList(WList,";")

For (i=0; i<N; i+=1)
	WStr=StringFromList(i, WList,";")
	KillWaves $(GetDataFolder(1)+SubFldr+WStr)
EndFor	
Print "Killed waves, N =", i, WList
End

Function pt_KillFldrsFrmFldrs()
// modified from KillWFrmFldrs 09/02/12
// modified to include subfolder 12/28/2010. Also instead of specifying 1 ExcludeWName per row, specifiy the list in AnalParW[1]
String DataFldrMatchStr, FldrList, FldrList1, FldrStr, SubFldr, OldDF, AllDirStr, ListFldrsKilled=""
Variable N, i, j//, NumExcludeW 

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_KillFldrsFrmFldrs"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_KillFldrsFrmFldrs"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_KillFldrsFrmFldrsParW and/or pt_KillFldrsFrmFldrsParNamesW!!!"
EndIf
DoAlert 0, "May need to run multiple times to kill all folders"
PrintAnalPar("pt_KillFldrsFrmFldrs")


DataFldrMatchStr			=		AnalParW[0]
SubFldr						= 		AnalParW[1]

OldDF=GetDataFolder(1)
SetDataFolder $GetDataFolder(1)+SubFldr
DFREF saveDFR = GetDataFolderDFR()		// change to subfolder as GetDataFolderDFR works only for current folder
SetDataFolder OldDF

N=	CountObjectsDFR(saveDFR , 4)

For (i=0; i<N; i+=1)
	FldrStr=GetIndexedObjNameDFR(saveDFR, 4,i)//StringFromList(i, FldrList,";")
	If (StringMatch(FldrStr, DataFldrMatchStr))
		KillDataFolder /Z $FldrStr
		ListFldrsKilled+=FldrStr+";"
	EndIf
EndFor	

Print "Killed Fldrs, N =", i, ListFldrsKilled
End


Function pt_AnalyzeWavesInFolders(AnalFunc)
// aim: to carry out same analysis in waves (acquired traces) in different folders (like different cells)
String AnalFunc

String OldDF, CurrFldrName, TableName
Variable  iStartRow

OldDF=GetDataFolder(-1)
SetDataFolder root:
//Wave /T FolderNamesW=$(StringByKey("Wave", TableInfo("",0), ":") )

Print "Starting Analysis", AnalFunc, "at", Time(), Date()

TableName=StringByKey("TableName",TableInfo("",-2), ":")
GetSelection Table, $TableName, 1
Wave /T FolderNamesW=$(StringByKey("Wave", TableInfo("",V_StartCol), ":") )
iStartRow=V_StartRow
Do 
	If (iStartRow>V_EndRow)
		Break
	EndIf	
	Print "Analyzing folder...", FolderNamesW[iStartRow]
	CurrFldrName=FolderNamesW[iStartRow]
	SetDataFolder $CurrFldrName
	Execute AnalFunc
//	Concatenate /NP {WNumSpikes}, root:DeprWNumSpikes
//	Concatenate /NP {PlusArea}, root:DeprPlusArea
//	Concatenate /NP {MinusArea}, root:DeprMinusArea
	Print "****************************************************************************************"
	SetDataFolder root:
	iStartRow+=1
While (1)
SetDataFolder OldDF
Print "Analysis", AnalFunc, "over!"
End


Menu "EditFuncPars"

"pt_AllignWaves" , pt_EditFuncPars("pt_AllignWaves")
"pt_AnalWInFldrs2" , pt_EditFuncPars("pt_AnalWInFldrs2")
"pt_AppendWFrmFldrs", pt_EditFuncPars("pt_AppendWFrmFldrs")
"pt_AppendWToGraph", pt_EditFuncPars("pt_AppendWToGraph")
"pt_AppendWFrmFldrs1", pt_EditFuncPars("pt_AppendWFrmFldrs1")
"pt_CalArea", pt_EditFuncPars("pt_CalArea")
Submenu "Average"
"pt_AverageWaves",pt_EditFuncPars("pt_AverageWaves")
"Use pt_AverageWavesVarPar1 to run pt_AverageWaves with some parameters varied"
"pt_AverageWavesEasy",pt_EditFuncPars("pt_AverageWavesEasy")
"****Use pt_XYToWave2 to convert XY waves to waveforms****"
"pt_XYToWave2",pt_EditFuncPars("pt_XYToWave2")
//"pt_AverageWaveXY",pt_EditFuncPars("pt_AverageWaveXY")
//"pt_AverageWaveXY2",pt_EditFuncPars("pt_AverageWaveXY2")
"pt_AverageVals",pt_EditFuncPars("pt_AverageVals")
"pt_AvgRepeatNums",pt_EditFuncPars("pt_AvgRepeatNums")
"pt_AvgRepeatWaves",pt_EditFuncPars("pt_AvgRepeatWaves")
End
"pt_BinXYWave", pt_EditFuncPars("pt_BinXYWave")
"pt_BurstProb", pt_EditFuncPars("pt_BurstProb")
"pt_CalBLAvg",pt_EditFuncPars("pt_CalBLAvg")
"pt_CalAvgAtXWVals",pt_EditFuncPars("pt_CalAvgAtXWVals")
"pt_CalHistTCrs" , pt_EditFuncPars("pt_CalHistTCrs")
"pt_CalLeakCurr" , pt_EditFuncPars("pt_CalLeakCurr")
"pt_CalPeak",pt_EditFuncPars("pt_CalPeak")
"pt_CalTonicCurr",pt_EditFuncPars("pt_CalTonicCurr")

Submenu "SealTest"
"pt_CalRsRinCmVmIClamp", pt_EditFuncPars("pt_CalRsRinCmVmIClamp")
"pt_CalRsRinCmVmVClamp", pt_EditFuncPars("pt_CalRsRinCmVmVClamp")
End
"pt_CalSlope",pt_EditFuncPars("pt_CalSlope")
"pt_CompareWFrmFldrs", pt_EditFuncPars("pt_CompareWFrmFldrs")
Submenu "Concatenate waves"
"pt_ConctnWFrmFldrs", pt_EditFuncPars("pt_ConctnWFrmFldrs")
"pt_ConctnWFrmFldrs1", pt_EditFuncPars("pt_ConctnWFrmFldrs1")
End
Submenu "FileConverters"
	"pt_ConvertTextToBinary", pt_EditFuncPars("pt_ConvertTextToBinary")
End
"pt_CurveFit",pt_EditFuncPars("pt_CurveFit")
"pt_CurveFitEdit",pt_EditFuncPars("pt_CurveFitEdit")
"pt_DiffPrePostWaves",pt_EditFuncPars("pt_DiffPrePostWaves")
"pt_DisplayWFrmFldrs", pt_EditFuncPars("pt_DisplayWFrmFldrs")
"pt_DuplicateWRnd", pt_EditFuncPars("pt_DuplicateWRnd")
End

Menu "EditFuncPars More..."
Submenu "Edit Waves"
"pt_EditWFrmFldrs", pt_EditFuncPars("pt_EditWFrmFldrs")
"pt_EditWAuto", pt_EditFuncPars("pt_EditWAuto")
End


"pt_ElectroPhysWaveGen", pt_EditFuncPars("pt_ElectroPhysWaveGen")
"pt_ExportWavesAsText", pt_EditFuncPars("pt_ExportWavesAsText")
"pt_ExtractSelected", pt_EditFuncPars("pt_ExtractSelected")
SubMenu "Extract And Sort"
"pt_ExtractFromWaveNote", 	pt_EditFuncPars("pt_ExtractFromWaveNote")
"pt_ExtractRepsNSrt", 			pt_EditFuncPars("pt_ExtractRepsNSrt")
"pt_ExtractWRepsNSrt", 		pt_EditFuncPars("pt_ExtractWRepsNSrt")
"pt_ExtractWRepsNSrt", 		pt_EditFuncPars("pt_ExtractWRepsNSrt")
"pt_NthPntExtract", 			pt_EditFuncPars("pt_NthPntExtract")
End

"pt_ExpFitW", pt_EditFuncPars("pt_ExpFitW")


SubMenu "SpikeAnalysis"
"pt_LevelCross", pt_EditFuncPars("pt_LevelCross")
"pt_CalFISlope", pt_EditFuncPars("pt_CalFISlope")
"pt_FIAnalysis", pt_EditFuncPars("pt_FIAnalysis")
"pt_PostProcessFI", pt_EditFuncPars("pt_PostProcessFI")
"***use for normalzing current waves to capacitance***"
"pt_NormWsToW", pt_EditFuncPars("pt_NormWsToW")
"***use for normalzing current waves to capacitance***"
"pt_CalIntWidth", pt_EditFuncPars("pt_CalIntWidth")
"pt_SpikeAnal", pt_EditFuncPars("pt_SpikeAnal")
"pt_SpikeAnalDisplay", pt_EditFuncPars("pt_SpikeAnalDisplay")
"pt_BurstAnalDisplay", pt_EditFuncPars("pt_BurstAnalDisplay")
"pt_SpikeNthAnal",pt_EditFuncPars("pt_SpikeNthAnal")
"pt_SpikeReAnal", pt_EditFuncPars("pt_SpikeReAnal")
"pt_SortW",pt_EditFuncPars("pt_SortW")
"Use pt_SpikeReAnalVarPar1 to run pt_SpikeReAnal with some parameters varied"
"pt_ConvertTSpikeToISI", pt_EditFuncPars("pt_ConvertTSpikeToISI")
"pt_ConvNansToZeros", pt_EditFuncPars("pt_ConvNansToZeros")
"Use pt_ConvertTSpikeToISIVarPar1 to run  with some parameters varied"
"pt_ConvertTSpikeToMidT", pt_EditFuncPars("pt_ConvertTSpikeToMidT")
"Use pt_ConvertTSpikeToMidTVarPar1 to run with some parameters varied"
"pt_CalISIAdaptRatio" , pt_EditFuncPars("pt_CalISIAdaptRatio")
"pt_CalISIAdaptTau" , pt_EditFuncPars("pt_CalISIAdaptTau")
"pt_CalEOPAHPTau" , pt_EditFuncPars("pt_CalEOPAHPTau")
"Use pt_CurveFitAdaptRatio to fit exponential to XY Wave"
"generated from pt_CalISIAdaptRatio"
"pt_BurstAnal",pt_EditFuncPars("pt_BurstAnal")
End

Submenu "MoveData"
"pt_DuplicateWFrmFldrs", pt_EditFuncPars("pt_DuplicateWFrmFldrs")
"pt_DuplicateWToFldrs", pt_EditFuncPars("pt_DuplicateWToFldrs")
"pt_LoadWFrmFldrs", pt_EditFuncPars("pt_LoadWFrmFldrs")
"pt_LoadDataNthWave", pt_EditFuncPars("pt_LoadDataNthWave")
"pt_MoveWaves",pt_EditFuncPars("pt_MoveWaves")
"pt_MoveWavesMany",pt_EditFuncPars("pt_MoveWavesMany")
" use  pt_SaveWFrmFldrs to save individual waves as IgorBinary or convert to DelimitedText"
"pt_SaveWFrmFldrs", pt_EditFuncPars("pt_SaveWFrmFldrs")
"pt_SaveWSubset", pt_EditFuncPars("pt_SaveWSubset")
"pt_SaveWsAsText", pt_EditFuncPars("pt_SaveWsAsText")
"pt_SaveTableAsText", pt_EditFuncPars("pt_SaveTableAsText")

End

Submenu "pclamp analysis"
	"pt_Abf2Igor", pt_EditFuncPars("pt_Abf2Igor")
End

Submenu "WaveFilters"
"pt_FilterBadPoints", pt_EditFuncPars("pt_FilterBadPoints")
"pt_RemoveOutLiers1", pt_EditFuncPars("pt_RemoveOutLiers1")
"pt_ConvNansToZeros", pt_EditFuncPars("pt_ConvNansToZeros")
"Use pt_FilterWave to filter out values < and > specified cutoffs"
"pt_NanIndices", pt_EditFuncPars("pt_NanIndices")
End
"pt_GaussianFilterData",pt_EditFuncPars("pt_GaussianFilterData")
"pt_InsertPoints",pt_EditFuncPars("pt_InsertPoints")
"pt_NormIByC", pt_EditFuncPars("pt_NormIByC")
"Use pt_KillAllGraphWin(N) to kill graphs from N1 to N2"
"pt_KillWFrmFldrs", pt_EditFuncPars("pt_KillWFrmFldrs")
"pt_KillFldrsFrmFldrs", pt_EditFuncPars("pt_KillFldrsFrmFldrs")
"pt_LayOutsFrmFldrs", pt_EditFuncPars("pt_LayOutsFrmFldrs")

Submenu "Stats"
"Run func pt_StatPower() for instructions to calculate statistical power"
"pt_MakeAnova2Waves",pt_EditFuncPars("pt_MakeAnova2Waves")
"pt_MakeNAnovaRW",pt_EditFuncPars("pt_MakeNAnovaRW")
"pt_StatsLnrC",pt_EditFuncPars("pt_StatsLnrC")
"pt_StatsTTest",pt_EditFuncPars("pt_StatsTTest")
"pt_StatsAnova1",pt_EditFuncPars("pt_StatsAnova1")
End

"pt_MakeEpochs",pt_EditFuncPars("pt_MakeEpochs")
SubMenu "MiniAnalysis"
Submenu "Ken's"
"pt_ExtractMiniWAll",pt_EditFuncPars("pt_ExtractMiniWAll")
"pt_GenTimeCourse",pt_EditFuncPars("pt_GenTimeCourse")
"pt_SortMinisByWaves",pt_EditFuncPars("pt_SortMinisByWaves")
"pt_SplitWEpochs", pt_EditFuncPars("pt_SplitWEpochs")
 "pt_DiceIntoIndWaves", pt_EditFuncPars("pt_DiceIntoIndWaves")
 "pt_ConcatEpochWaves", pt_EditFuncPars("pt_ConcatEpochWaves")
"pt_WKenMiniAnal", pt_EditFuncPars("pt_WKenMiniAnal")
"Use  pt_WKenMiniAnal to prepare waves for Ken's mini analysis"
"Use  pt_ExtractMiniWAll to extract all mini's from concatenated miniwave generated by Ken's program"
End
Submenu "Praveen's"
"pt_RemoveBLPoly",pt_EditFuncPars("pt_RemoveBLPoly")
"pt_MiniAnalysis", pt_EditFuncPars("pt_MiniAnalysis")
//"***For pt_PeakAnal set the edit the fit function in pt_CurveFitEdit first***"
"pt_PeakAnal",pt_EditFuncPars("pt_PeakAnal")
//"***For pt_PeakAnal set the edit the fit function in pt_CurveFitEdit first***"
"pt_CurveFitEdit",pt_EditFuncPars("pt_CurveFitEdit")
"pt_NthPntWave",pt_EditFuncPars("pt_NthPntWave")
"pt_RemoveOutLiers1", pt_EditFuncPars("pt_RemoveOutLiers1")
"pt_ConctnWFrmFldrs1", pt_EditFuncPars("pt_ConctnWFrmFldrs1")
"pt_RndSlctPntsFromW",pt_EditFuncPars("pt_RndSlctPntsFromW")
"pt_RndSlctWFromW",pt_EditFuncPars("pt_RndSlctWFromW")
End

End

"pt_NthPntWave",pt_EditFuncPars("pt_NthPntWave")
"Use pt_NthPntWaveVarPar1 to run pt_NthPntWave with some parameters varied"
"pt_OperateOn2Waves",pt_EditFuncPars("pt_OperateOn2Waves")
help={"Add, Subtract, Multiply, Divide, PercentChange"}
"pt_PsdCal",pt_EditFuncPars("pt_PsdCal")
//"***For pt_PeakAnal set the edit the fit function in pt_CurveFitEdit first***"
"pt_PeakAnal",pt_EditFuncPars("pt_PeakAnal")
//"***For pt_PeakAnal set the edit the fit function in pt_CurveFitEdit first***"
"pt_RndSlctPntsFromW",pt_EditFuncPars("pt_RndSlctPntsFromW")
"pt_RndSlctWFromW",pt_EditFuncPars("pt_RndSlctWFromW")
Submenu "Rename"
"pt_RenameWaves", pt_EditFuncPars("pt_RenameWaves")
"pt_RepTxtInW", pt_EditFuncPars("pt_RepTxtInW")
"pt_RenameUnique", pt_EditFuncPars("pt_RenameUnique")
End

"pt_RepeatNumsBL", pt_EditFuncPars("pt_RepeatNumsBL")
"pt_SetXScale",pt_EditFuncPars("pt_SetXScale")
"pt_SortW",pt_EditFuncPars("pt_SortW")

Submenu "Paired Rec. Analysis"
"pt_CalSynResp", pt_EditFuncPars("pt_CalSynResp")
End



"pt_SplitEpochs", pt_EditFuncPars("pt_SplitEpochs")
"pt_UpdateCellInfo", pt_EditFuncPars("pt_UpdateCellInfo")
"pt_UserCommands",pt_EditFuncPars("pt_UserCommands")
SubMenu "Wave Operations"
"pt_UnaryOpOnWaves",pt_EditFuncPars("pt_UnaryOpOnWaves")
"pt_ScalarOpOnWaves",pt_EditFuncPars("pt_ScalarOpOnWaves")
"pt_StatsOnWaves",pt_EditFuncPars("pt_StatsOnWaves")
"pt_WavestatsParAsW",pt_EditFuncPars("pt_WavestatsParAsW")

End
"pt_PlotXYZcolor",pt_EditFuncPars("pt_PlotXYZcolor")	
End


Menu "RunFunctionOnFldrs"

"pt_AllignWaves",pt_AnalWInFldrs2("pt_AllignWaves")
"pt_CalArea",pt_AnalWInFldrs2("pt_CalArea")

Submenu "Average"
"pt_AverageVals",pt_AnalWInFldrs2("pt_AverageVals")
"pt_AverageWaves",pt_AnalWInFldrs2("pt_AverageWaves")	
"pt_AverageWavesEasy",pt_AnalWInFldrs2("pt_AverageWavesEasy")	
"pt_AvgRepeatNums",pt_AnalWInFldrs2("pt_AvgRepeatNums")	
"pt_AvgRepeatWaves",pt_AnalWInFldrs2("pt_AvgRepeatWaves")	
"pt_CalBLAvg",pt_AnalWInFldrs2("pt_CalBLAvg")	
"pt_CalAvgAtXWVals",pt_AnalWInFldrs2("pt_CalAvgAtXWVals")
End
"pt_BinXYWave",pt_AnalWInFldrs2("pt_BinXYWave")	
"pt_CalLeakCurr",pt_AnalWInFldrs2("pt_CalLeakCurr")	
"pt_CalPeak",pt_AnalWInFldrs2("pt_CalPeak")
"pt_CalTonicCurr",pt_AnalWInFldrs2("pt_CalTonicCurr")
	
Submenu "SealTest"
"pt_CalRsRinCmVmIClamp", pt_AnalWInFldrs2("pt_CalRsRinCmVmIClamp")	
"pt_CalRsRinCmVmVClamp", pt_AnalWInFldrs2("pt_CalRsRinCmVmVClamp")
End
"pt_CalSlope",pt_AnalWInFldrs2("pt_CalSlope")
"pt_CompareWFrmFldrs", pt_AnalWInFldrs2("pt_CompareWFrmFldrs")
Submenu "Concatenate waves"	
"pt_ConctnWFrmFldrs", pt_AnalWInFldrs2("pt_ConctnWFrmFldrs")
"Use pt_ConctnWFrmFldrs1 to concatenate "	
"pt_ConctnWFrmFldrs1", pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
End	
"pt_DiffPrePostWaves",pt_AnalWInFldrs2("pt_DiffPrePostWaves")	
"pt_DisplayWFrmFldrs",pt_AnalWInFldrs2("pt_DisplayWFrmFldrs")

SubMenu "Edit Waves"
"pt_EditWFrmFldrs",pt_AnalWInFldrs2("pt_EditWFrmFldrs")
"pt_EditWAuto",pt_AnalWInFldrs2("pt_EditWAuto")

End

//"pt_ExportWavesAsText",pt_AnalWInFldrs2("pt_ExportWavesAsText")
"pt_ExtractSelected",pt_AnalWInFldrs2("pt_ExtractSelected")
SubMenu "Extract And Sort"
"pt_ExtractFromWaveNote",pt_AnalWInFldrs2("pt_ExtractFromWaveNote")
"pt_ExtractRepsNSrt",pt_AnalWInFldrs2("pt_ExtractRepsNSrt")
"pt_ExtractWRepsNSrt",pt_AnalWInFldrs2("pt_ExtractWRepsNSrt")
"pt_NthPntExtract",pt_AnalWInFldrs2("pt_NthPntExtract")
End

"pt_InsertPoints",pt_AnalWInFldrs2("pt_InsertPoints")
"Use pt_KillAllGraphWin(N) to kill graphs from N1 to N2"
"pt_KillWFrmFldrs",pt_AnalWInFldrs2("pt_KillWFrmFldrs")	
"pt_KillFldrsFrmFldrs",pt_AnalWInFldrs2("pt_KillFldrsFrmFldrs")
"pt_LayOutsFrmFldrs",pt_AnalWInFldrs2("pt_LayOutsFrmFldrs")	

SubMenu "MiniAnalysis"
Submenu "Ken's"
"pt_DoMiniAnal",pt_AnalWInFldrs2("pt_DoMiniAnal")
"pt_GenTimeCourse",pt_AnalWInFldrs2("pt_GenTimeCourse")
"pt_ExtractMiniWAll",pt_AnalWInFldrs2("pt_ExtractMiniWAll")
"pt_SortMinisByWaves",pt_AnalWInFldrs2("pt_SortMinisByWaves")
"pt_SplitWEpochs",pt_AnalWInFldrs2("pt_SplitWEpochs")
"pt_DiceIntoIndWaves", pt_AnalWInFldrs2("pt_DiceIntoIndWaves")
"pt_ConcatEpochWaves", pt_AnalWInFldrs2("pt_ConcatEpochWaves")
"Use  pt_WKenMiniAnal to prepare waves for Ken's mini analysis"
"Use  pt_ExtractMiniWAll to extract all mini's from concatenated miniwave generated by Ken's program"
End
Submenu "Praveen's"
"pt_RemoveBLPoly",pt_AnalWInFldrs2("pt_RemoveBLPoly")
//"***For pt_PeakAnal set the edit the fit function in pt_CurveFitEdit first***"
"pt_PeakAnal",pt_AnalWInFldrs2("pt_PeakAnal")
//"***For pt_PeakAnal set the edit the fit function in pt_CurveFitEdit first***"
//"***pt_CurveFitEdit called by pt_PeakAnal***"//,pt_AnalWInFldrs2("pt_CurveFitEdit")
//"***pt_NthPntWave called by pt_PeakAnal***"//,pt_AnalWInFldrs2("pt_NthPntWave")
"pt_RemoveOutLiers1", pt_AnalWInFldrs2("pt_RemoveOutLiers1")
"pt_ConctnWFrmFldrs1", pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
"pt_RndSlctPntsFromW",pt_AnalWInFldrs2("pt_RndSlctPntsFromW")
"pt_RndSlctWFromW",pt_AnalWInFldrs2("pt_RndSlctWFromW")
End
End

Submenu "MoveData"
"pt_DuplicateWFrmFldrs",pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")	
"pt_DuplicateWToFldrs",pt_AnalWInFldrs2("pt_DuplicateWToFldrs")
"pt_LoadWFrmFldrs",pt_AnalWInFldrs2("pt_LoadWFrmFldrs")
"pt_LoadDataNthWave",pt_AnalWInFldrs2("pt_LoadDataNthWave")
"pt_SaveWFrmFldrs", pt_AnalWInFldrs2("pt_SaveWFrmFldrs")
"pt_SaveWSubset", pt_AnalWInFldrs2("pt_SaveWSubset")
"pt_SaveWsAsText", pt_AnalWInFldrs2("pt_SaveWsAsText")	
"pt_SaveTableAsText", pt_AnalWInFldrs2("pt_SaveTableAsText")	
End

"pt_NthPntWave", pt_AnalWInFldrs2("pt_NthPntWave")	
"pt_OperateOn2Waves",pt_AnalWInFldrs2("pt_OperateOn2Waves")
help={"Add, Subtract, Multiply, Divide, PercentChange"}

Submenu "Rename"
"pt_RenameWaves", pt_AnalWInFldrs2("pt_RenameWaves")
"pt_RepTxtInW", pt_AnalWInFldrs2("pt_RepTxtInW")
"**to rename cells uniquely**"
"pt_RenameUnique", pt_RenameUnique()
End


//"***For pt_PeakAnal set the edit the fit function in pt_CurveFitEdit first***"
"pt_PeakAnal", pt_AnalWInFldrs2("pt_PeakAnal")
//"***For pt_PeakAnal set the edit the fit function in pt_CurveFitEdit first***"
"pt_PsdCal", pt_AnalWInFldrs2("pt_PsdCal")
"pt_RndSlctPntsFromW", pt_AnalWInFldrs2("pt_RndSlctPntsFromW")
"pt_RndSlctWFromW", pt_AnalWInFldrs2("pt_RndSlctWFromW")
"pt_RemoveOutLiers1", pt_AnalWInFldrs2("pt_RemoveOutLiers1")
"pt_SetXScale", pt_AnalWInFldrs2("pt_SetXScale")

	
SubMenu "Spike Analysis"

	"pt_LevelCross", pt_AnalWInFldrs2("pt_LevelCross")
	"pt_CalFISlope", pt_AnalWInFldrs2("pt_CalFISlope")
	"pt_CalIntWidth", pt_AnalWInFldrs2("pt_CalIntWidth")
	"pt_BurstAnal", pt_AnalWInFldrs2("pt_BurstAnal")
	"pt_CalISIAdaptRatio", pt_AnalWInFldrs2("pt_CalISIAdaptRatio")
	"pt_CalISIAdaptTau", pt_AnalWInFldrs2("pt_CalISIAdaptTau")
	"pt_CalEOPAHPTau", pt_AnalWInFldrs2("pt_CalEOPAHPTau")
	"pt_ConvertTSpikeToISI", pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
	"pt_ConvertTSpikeToMidT", pt_AnalWInFldrs2("pt_ConvertTSpikeToMidT")
	"pt_SpikeAnal", pt_AnalWInFldrs2("pt_SpikeAnal")	
	"pt_SpikeAnalDisplay", pt_AnalWInFldrs2("pt_SpikeAnalDisplay")
	"pt_BurstAnalDisplay", pt_AnalWInFldrs2("pt_BurstAnalDisplay")
	"pt_SpikeNthAnal", pt_AnalWInFldrs2("pt_SpikeNthAnal")
	"pt_SpikeReAnal", pt_AnalWInFldrs2("pt_SpikeReAnal")	
//	"pt_SpikeReAnalVarPar1", pt_AnalWInFldrs2("pt_SpikeReAnalVarPar1") 
//      pt_SpikeReAnalVarPar1 calls pt_AnalWInFldrs2("pt_SpikeReAnal"); so no need for it to be called using pt_AnalWInFldrs2
End

Submenu "Paired Rec. Analysis"
"pt_CalSynResp", pt_AnalWInFldrs2("pt_CalSynResp")
End

"pt_SplitEpochs", pt_AnalWInFldrs2("pt_SplitEpochs")
SubMenu "WaveFilters"
"pt_FilterWave1", pt_AnalWInFldrs2("pt_FilterWave1")
"pt_RemoveOutLiers1", pt_AnalWInFldrs2("pt_RemoveOutLiers1")
"pt_NanIndices", pt_AnalWInFldrs2("pt_NanIndices")

End 
"pt_UpdateCellInfo",pt_AnalWInFldrs2("pt_UpdateCellInfo")	
"pt_UserCommands",pt_AnalWInFldrs2("pt_UserCommands")	
"pt_UnaryOpOnWaves",pt_AnalWInFldrs2("pt_UnaryOpOnWaves")
"pt_ScalarOpOnWaves",pt_AnalWInFldrs2("pt_ScalarOpOnWaves")	
End

Menu "RunFunc"
//"pt_MiniAnalysis",pt_MiniAnalysis()
//"pt_FIAnalysis",pt_FIAnalysis()
"pt_Analysis", pt_Analysis()
"pt_ExportWavesAsText", pt_ExportWavesAsText()
"**to rename cells uniquely**"
"pt_RenameUnique", pt_RenameUnique()
End

Menu "AnalysisInfo"
"pt_AnalysisStartDateNTime",pt_AnalysisStartDateNTime()
"pt_AnalysisStopDateNTime",pt_AnalysisStopDateNTime()
End

Function pt_EnterDataNSaveFolders()
String /G ParentDataFolder
String Pdf
Prompt Pdf, "Enter parent data folder"
DoPrompt "Parent Data Folder", Pdf
ParentDataFolder=Pdf
End

Function pt_UpdateCellInfo()
Variable CellNameIndex

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_UpdateCellInfo"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_UpdateCellInfo"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_UpdateCellInfoParW and/or pt_UpdateCellInfoParNamesW!!!"
EndIf

PrintAnalPar("pt_UpdateCellInfo")

CellNameIndex	=	Str2Num(AnalParW[0])

Wave /T CellInfo		=	root:CellInfo
Wave /T CellName	=	root:CellName

If (CellNameIndex>NumPnts(CellInfo))
	Abort "Num of Pnts in CellInfo wave is less than the index of cell whose info is to be updated! Maybe add pnts to CellInfo wave"
EndIf

If (WaveExists(InfoCell))
	Wave /T InfoCell = InfoCell
	CellInfo[CellNameIndex] = InfoCell 
Else
	Print "InfoCell Wave doesn't exist!"
EndIf	
End



Function pt_AnalWInFldrs2(AnalFunc)

//	This is always the latest version

// In pt_LoadWFrmFldrs added the option to load a specific wave rather than all waves (eg. AnalParW[0] = Cell_00*_0016) 03/25/2009
// incorporated pt_NthPntWave 08/14/2008 	WRONG DATE
// If DataFldrStr empty, don't change DataWaveMatchStr and don't load data.
// useful when analysing a specific wave number from each cell. 05/27/2008

// data folders created if not existing (praveen 04/29/2008)
// incorporated pt_RenameWaves 08/26/2008
// incorprated creation of RawData folder and loading of waves in Case:pt_ConctnWFrmFldrs. used to be there earlier, but was missing now. 12/12/2007.

// in pt_SpikeAnal and pt_CalRsRinCmVmIClamp changed the loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 08/21/2007
// in pt_CalRsRinCmVmVClamp and pt_CalRsRinCmVmIClamp changed the loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 07/23/2007
// in Pt_CalPeak changed the loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 07/23/2007
// has to be done for other functions     07/23/2007


// aim: to carry out same analysis in waves (acquired traces) in different folders (like different cells)
String AnalFunc
SVAR ParentDataFolder=root:ParentDataFolder
String OldDF, OldDF1, OldDataWaveMatchStr, CurrFldrName, TableName, DataWaveMatchStr, WList, WNameStr, OldCellNameIndexStr, OldHDFolderPath, OldIgorFolderPath
Variable  LoadDataRecursive, iStartRow, RawDataFolderExists=0, Numwaves, i, j
Variable DataWaveMatchStrChngd=0

String LastUpdatedMM_DD_YYYY=" 07/06/2008"

Print "*********************************************************"
Print "pt_AnalWInFldrs2 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParW=$("root:FuncParWaves:pt_AnalWInFldrs2"+"ParW")
If (WaveExists(AnalParW)==0)
	Abort	"Cudn't find the parameter wave pt_AnalWInFldrs2ParW!!!"
EndIf

//If (StringMatch(AnalFunc,"pt_PeakAnal"))
//	DoAlert 1,"Have you edited the function pt_CurveFitEdit manually to set the fit function for mini's."
//	If (V_Flag==2)
//		Abort "Aborting..."
//	EndIf
//EndIf

LoadDataRecursive		=		Str2Num(AnalParW[0])

PrintAnalPar("pt_AnalWInFldrs2")

OldDF=GetDataFolder(-1)
SetDataFolder root:
Print "Starting Analysis", AnalFunc, "at", Time(), Date()

//Wave /T FolderNamesW=$(StringByKey("Wave", TableInfo("",0), ":") )
//Wave /T HDDataFldrPathW=$(StringByKey("Wave", TableInfo("",1), ":") )
Wave /T HDDataFldrPathW=root:HDDataFldrPathW

TableName=StringByKey("TableName",TableInfo("",-2), ":")
GetSelection Table, $TableName, 1
Wave /T FolderNamesW=$(StringByKey("Wave", TableInfo("",V_StartCol), ":") )
iStartRow=V_StartRow


Do 
	If (iStartRow>V_EndRow)
		Break
	EndIf	
	Print "Analyzing folder...", ParentDataFolder+":"+FolderNamesW[iStartRow]
	CurrFldrName=ParentDataFolder+":"+FolderNamesW[iStartRow]
//	SetDataFolder $CurrFldrName
	If (	DataFolderExists(CurrFldrName)		)	// data folders created if not existing (praveen 04/29/2008)
	SetDataFolder $CurrFldrName
	Else
		NewDataFolder /s $CurrFldrName
		Print "Created Data Folder", CurrFldrName
	EndIf
			
	StrSwitch(AnalFunc)
		Case "pt_PeakAnal":
		// Load Data
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 08/21/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	
			
			
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
//				pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData") // modified on 08/25/12
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
//				pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData") // modified on 08/25/12
			EndIf
		Break
		
		Case "pt_FilterWave1":
		Break
		Case "pt_RemoveOutLiers1":
		Break
		Case "pt_EditWAuto":
		Break	
		Case "pt_SpikeAnal":
			// Load Data
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 08/21/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	
			
			
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				//pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				//pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
			
			If ( StrLen(AnalParW[12])*StrLen(AnalParW[13])!=0)
				OldDF1=GetDataFolder(-1)
				SetDataFolder CurrFldrName+":RawData"
				print HDDataFldrPathW[iStartRow]+":FIWNamesWave.txt"
				LoadWave /A/J/B="C=1, F=-2, N=FIWNamesW;" HDDataFldrPathW[iStartRow]+":FIWNamesWave.txt"
				LoadWave /A/J/B="C=1, F=0, T=4, N=FICurrWave;" HDDataFldrPathW[iStartRow]+":FICurrWave.txt"
				SetDataFolder OldDF1
			EndIf	
//			Edit FIWNamesW, FICurrWave
				
			Break
			
		Case  "pt_CalSynResp":
// Load Data
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 08/21/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	
			
			
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
			
		Break	
			
		Case "pt_BurstAnal":
			// Load Data
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 08/21/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	
			
			
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
//				pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
//				pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
			
//			If ( StrLen(AnalParW[12])*StrLen(AnalParW[13])!=0)
//			OldDF1=GetDataFolder(-1)
//				SetDataFolder CurrFldrName+":RawData"
//				print HDDataFldrPathW[iStartRow]+":FIWNamesWave.txt"
//				LoadWave /A/J/B="C=1, F=-2, N=FIWNamesW;" HDDataFldrPathW[iStartRow]+":FIWNamesWave.txt"
//				LoadWave /A/J/B="C=1, F=0, T=4, N=FICurrWave;" HDDataFldrPathW[iStartRow]+":FICurrWave.txt"
//				SetDataFolder OldDF1
//			EndIf	
//			Edit FIWNamesW, FICurrWave
				
			Break
			
		Case "pt_ExtractFromWaveNote":
			// Load Data
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 08/21/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	
			
			
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				//pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				//pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
				
			Break
			
		///////***
		
		Case "pt_SaveWSubset":
			// Load Data
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 08/21/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	
			
			
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				//pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				//pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
				
			Break
		///////***
		
		Case "pt_ExtractRepsNSrt":
			Break
//		Case "pt_ExportWavesAsText":
//			Break
		Case "pt_PsdCal":
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 07/24/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	

//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf

			If (StrLen(AnalParW[1]) != 0)		// If DataFldrStr empty, don't change DataWaveMatchStr and don't load data.
											// useful when analysing a specific wave number from each cell. 05/27/2008

			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			DataWaveMatchStrChngd =1
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				//pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				//pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
			EndIf
			Break				
		Case "pt_ExtractWRepsNSrt":
			Break
		Case "pt_NthPntExtract":
			Break	
		Case "pt_SpikeReAnal":			
			Break
		Case "pt_SpikeAnalDisplay":			
			Break
		Case "pt_BurstAnalDisplay":			
			Break			
		Case "pt_ConvertTSpikeToISI":			
			Break		
		Case "pt_ConvertTSpikeToMidT":			
			Break
		Case "pt_SpikeNthAnal":			
			Break	
		Case "pt_SplitEpochs":	
			Break	
		Case "pt_SplitWEpochs":	
			Break
		Case "pt_AverageVals":			
			Break
		Case "pt_CalArea":
			Break
		Case "pt_GenTimeCourse":
			Break
		Case "pt_InsertPoints":
			Break
		Case "pt_SortMinisByWaves":
			Break	
		Case "pt_DoMiniAnal":
			Break		
		Case "pt_ExtractMiniWAll":
			Break
		Case "pt_CalSlope":			
			Break	
		Case "pt_CompareWFrmFldrs":			
			Break	
		Case "pt_CalISIAdaptRatio	":			
			Break
		Case "pt_CalISIAdaptTau":			
			Break
		Case "pt_CalEOPAHPTau":			
			Break			
		Case "pt_NthPntWave	":	
			Break
		Case "pt_BinXYWave":	
			Break
		Case "pt_RemoveOutLiers1":	
			Break
		Case "pt_DiceIntoIndWaves":	
			Break
		Case "pt_ConcatEpochWaves":	
			Break
		Case "pt_CalIntWidth":	
			Break
		Case "pt_ConctnWFrmFldrs1":
		Break				
		Case "pt_ConctnWFrmFldrs":
		
			
			// Load Data								// somehow creation of rawdata folder and loading of waves. used to be there in earlier version
													// incorporated that. 12/12/2007
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 08/21/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	
			
			
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				//pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				//pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
		
		
			Break
		Case "pt_CalTonicCurr":
		Break		
		Case "pt_CalTonicCurr1": // delete 05/06/2014
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
		Break
		Case "pt_RndSlctPntsFromW":
			Break
		Case "pt_RndSlctWFromW":
			Break	
		Case "pt_RenameWaves":
			Break
		Case "pt_RepTxtInW":
			Break
		Case "pt_SetXScale":
			Break
		Case "pt_CalLeakCurr":
			Break	
		Case "pt_AllignWaves":
			Break
		Case "pt_SaveWFrmFldrs":
			Break	
		Case "pt_SaveWsAsText":
			//NewDataFolder /O $CurrFldrName+":RawData"
			//RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 07/24/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	

//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf

			If (StrLen(AnalParW[1]) != 0)		// If DataFldrStr empty, don't change DataWaveMatchStr and don't load data.
											// useful when analysing a specific wave number from each cell. 05/27/2008

			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			DataWaveMatchStrChngd =1
			EndIf
			Break
		Case "pt_SaveTableAsText":
			//NewDataFolder /O $CurrFldrName+":RawData"
			//RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 07/24/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	

//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf

			If (StrLen(AnalParW[1]) != 0)		// If DataFldrStr empty, don't change DataWaveMatchStr and don't load data.
											// useful when analysing a specific wave number from each cell. 05/27/2008

			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			DataWaveMatchStrChngd =1
			EndIf
			Break
		Case "pt_LoadWFrmFldrs":
			// Load Data
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			// In pt_LoadWFrmFldrs added the option to load a specific wave rather than all waves (eg. AnalParW[0] = Cell_00*_0016*) 03/25/2009
			If (Str2Num(AnalParW[2])==1)		
			AnalParW[0]=GetDataFolder(0)+"*"
			EndIf
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
//				pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData") //08_30_12
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
//				pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	//08_30_12
			EndIf
			Break
			
		Case "pt_LoadDataNthWave":
			// Load Data
			//NewDataFolder /O $CurrFldrName+":RawData"
			//RawDataFolderExists=1
			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
			Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr	=AnalParW[0]
			OldHDFolderPath		=AnalParW[3]
			OldIgorFolderPath		=AnalParW[4]
			// In pt_LoadWFrmFldrs added the option to load a specific wave rather than all waves (eg. AnalParW[0] = Cell_00*_0016*) 03/25/2009
			//If (Str2Num(AnalParW[2])==1)		
			AnalParW[0]=GetDataFolder(0)+"*"
			AnalParW[3]=HDDataFldrPathW[iStartRow]
			AnalParW[4]=CurrFldrName
			
			//EndIf
			//DataWaveMatchStr  = AnalParW[0]
			//DataWaveMatchStr  =GetDataFolder(0)+"*"
			//If (LoadDataRecursive)
			//	Print "Loading Data RECURSIVELY from HD"
			//	pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			//Else
			//	Print "Loading Data NON-RECURSIVELY from HD"
			//	pt_LoadDataNthWave()
			//EndIf
			Break	
		
		
		Case "pt_CalRsRinCmVmIClamp":	
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 07/24/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	

//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf

			If (StrLen(AnalParW[1]) != 0)		// If DataFldrStr empty, don't change DataWaveMatchStr and don't load data.
											// useful when analysing a specific wave number from each cell. 05/27/2008

			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			DataWaveMatchStrChngd =1
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				//pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				//pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
			EndIf
			Break
		Case "pt_CalRsRinCmVmVClamp":	
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1


			// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
			// seen inside the function. 			 07/24/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")	
			
						
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
//				pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
//				pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf
			Break	
		Case "pt_CalBLAvg":
			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			If (StringMatch(AnalParW[1], "RawData:"))
				NewDataFolder /O $CurrFldrName+":RawData"
				RawDataFolderExists=1
				OldDataWaveMatchStr=AnalParW[0]
				AnalParW[0]=GetDataFolder(0)+"*"
				DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			EndIf

			EndIf	
			Break
		Case "pt_CalAvgAtXWVals":
			Break	
		Case "pt_AvgRepeatNums":
//			NewDataFolder /O $CurrFldrName+":RawData"
//			RawDataFolderExists=1
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
//			If (!WaveExists(AnalParW))
//				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
//			EndIf
//			OldDataWaveMatchStr=AnalParW[0]
//			AnalParW[0]=GetDataFolder(0)+"*"
//			DataWaveMatchStr  = AnalParW[0]
//			pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	
			Break	
		Case "pt_UserCommands":
			Break	
		Case "pt_AvgRepeatWaves":
			NewDataFolder /O $CurrFldrName+":RawData"
			RawDataFolderExists=1
			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldDataWaveMatchStr=AnalParW[0]
			AnalParW[0]=GetDataFolder(0)+"*"
			DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				//pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData") // 03/27/13
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				//pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	//03/27/13
			EndIf
			Break
		Case "pt_DiffPrePostWaves":	
//			NewDataFolder /O $CurrFldrName+":RawData"
//			RawDataFolderExists=1
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
//			If (!WaveExists(AnalParW))
//				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
//			EndIf
//			OldDataWaveMatchStr=AnalParW[0]
//			AnalParW[0]=GetDataFolder(0)+"*"
//			DataWaveMatchStr  = AnalParW[0]
//			pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	
			Break	
			Case "pt_OperateOn2Waves":	
//			NewDataFolder /O $CurrFldrName+":RawData"
//			RawDataFolderExists=1
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
//			If (!WaveExists(AnalParW))
//				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
//			EndIf
//			OldDataWaveMatchStr=AnalParW[0]
//			AnalParW[0]=GetDataFolder(0)+"*"
//			DataWaveMatchStr  = AnalParW[0]
//			pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	
			Break
			Case "pt_UnaryOpOnWaves":
			Break
			Case "pt_ScalarOpOnWaves":
			Break
			Case "pt_DuplicateWFrmFldrs":	
//			NewDataFolder /O $CurrFldrName+":RawData"
//			RawDataFolderExists=1
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
//			If (!WaveExists(AnalParW))
//				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
//			EndIf
//			OldDataWaveMatchStr=AnalParW[0]
//			AnalParW[0]=GetDataFolder(0)+"*"
//			DataWaveMatchStr  = AnalParW[0]
//			pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	
			Break	
			
			Case  "pt_ExtractSelected":
			Break
			
			Case "pt_DuplicateWToFldrs":	
//			NewDataFolder /O $CurrFldrName+":RawData"
//			RawDataFolderExists=1
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
//			If (!WaveExists(AnalParW))
//				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
//			EndIf
//			OldDataWaveMatchStr=AnalParW[0]
//			AnalParW[0]=GetDataFolder(0)+"*"
//			DataWaveMatchStr  = AnalParW[0]
//			pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	
			Break	
			
			
			Case "pt_DisplayWFrmFldrs":	
//			NewDataFolder /O $CurrFldrName+":RawData"
//			RawDataFolderExists=1
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
//			If (!WaveExists(AnalParW))
//				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
//			EndIf
//			OldDataWaveMatchStr=AnalParW[0]
//			AnalParW[0]=GetDataFolder(0)+"*"
//			DataWaveMatchStr  = AnalParW[0]
//			pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	
			Break
			
			Case "pt_EditWFrmFldrs":
			Break 
			Case "pt_AverageWaves":
			Break
			Case "pt_LevelCross":
			Break
			Case "pt_CalFISlope":
			Break
			Case "pt_AverageWavesEasy":
			Break 
			
			Case "pt_LayOutsFrmFldrs":	
//			NewDataFolder /O $CurrFldrName+":RawData"
//			RawDataFolderExists=1
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
//			If (!WaveExists(AnalParW))
//				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
//			EndIf
//			OldDataWaveMatchStr=AnalParW[0]
//			AnalParW[0]=GetDataFolder(0)+"*"
//			DataWaveMatchStr  = AnalParW[0]
//			pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	
			Break	
			
			Case "pt_KillWFrmFldrs":	
//			NewDataFolder /O $CurrFldrName+":RawData"
//			RawDataFolderExists=1
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
//			If (!WaveExists(AnalParW))
//				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
//			EndIf
//			OldDataWaveMatchStr=AnalParW[0]
//			AnalParW[0]=GetDataFolder(0)+"*"
//			DataWaveMatchStr  = AnalParW[0]
//			pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	
			Break
			
			Case "pt_KillFldrsFrmFldrs":	
//			NewDataFolder /O $CurrFldrName+":RawData"
//			RawDataFolderExists=1
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
//			If (!WaveExists(AnalParW))
//				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
//			EndIf
//			OldDataWaveMatchStr=AnalParW[0]
//			AnalParW[0]=GetDataFolder(0)+"*"
//			DataWaveMatchStr  = AnalParW[0]
//			pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")	
			Break		
			
			Case "pt_UpdateCellInfo":
			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			OldCellNameIndexStr=AnalParW[0]
			AnalParW[0]=Num2Str(iStartRow)
			Break
			
		Case "pt_CalPeak": 
// If DataFldrStr empty, don't change DataWaveMatchStr and don't load data.
// useful when analysing a specific wave number from each cell. 	03/27/13	
			//NewDataFolder /O $CurrFldrName+":RawData"
			//RawDataFolderExists=1

// loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function. 			 07/23/2007
			
			Wave /T AnalParW=$pt_GetParWave(AnalFunc, "ParW")		
//			Wave /T AnalParW=$("root:FuncParWaves:"+AnalFunc+"ParW")
			If (!WaveExists(AnalParW))
				Abort  "Cudn't find the parameter wave" +AnalFunc+"ParW!!!"
			EndIf
			If (StringMatch(AnalParW[1], "RawData:"))
				NewDataFolder /O $CurrFldrName+":RawData"
				RawDataFolderExists=1
				OldDataWaveMatchStr=AnalParW[0]
				AnalParW[0]=GetDataFolder(0)+"*"
				DataWaveMatchStr  = AnalParW[0]
			If (LoadDataRecursive)
				Print "Loading Data RECURSIVELY from HD"
				//pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadDataRecursive2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData") //03/27/13
			Else
				Print "Loading Data NON-RECURSIVELY from HD"
				//pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
				pt_LoadData2(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData") //03/27/13
			EndIf

			EndIf	
			
			
			//OldDataWaveMatchStr=AnalParW[0]
			//AnalParW[0]=GetDataFolder(0)+"*"
			//DataWaveMatchStr  = AnalParW[0]
			//If (LoadDataRecursive)
			//	Print "Loading Data RECURSIVELY from HD"
			//	pt_LoadDataRecursive(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			//Else
			//	Print "Loading Data NON-RECURSIVELY from HD"
			//	pt_LoadData(DataWaveMatchStr, HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
			//EndIf
//			OldDF1=GetDataFolder(-1)
//			SetDataFolder CurrFldrName+":RawData"
	
//			If ( StrLen(AnalParW[12])*StrLen(AnalParW[13])!=0)		// praveen 07/18/2007
//				print HDDataFldrPathW[iStartRow]+":FIWNamesWave.txt"
//				LoadWave /A/J/B="C=1, F=-2, N=FIWNamesW;" HDDataFldrPathW[iStartRow]+":FIWNamesWave.txt"
//				LoadWave /A/J/B="C=1, F=0, T=4, N=FICurrWave;" HDDataFldrPathW[iStartRow]+":FICurrWave.txt"
//			EndIf
//			Edit FIWNamesW, FICurrWave
//			SetDataFolder OldDF1
//			If ( StrLen(AnalParW[12])*StrLen(AnalParW[13])!=0)		// FIData=1
//				Wave /T FIWNamesW		=	$(GetDataFolder(-1)+"RawData:"+AnalParW[12])
//				Wave     FICurrWave		=	$(GetDataFolder(-1)+"RawData:"+AnalParW[13])
				// pre-select waves
//				WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+"RawData")
//				Numwaves=ItemsInList(WList, ";")
			
//				For (i=0; i<NumWaves; i+=1)
//				WNameStr=StringFromList(i, WList, ";")
				
//					For (j=0; j<NumPnts(FIWNamesW); j+=1)
//						If (StringMatch(FIWNamesW[j],WNameStr))
//							If (FICurrWave[j] >0)
//								KillWaves $(GetDataFolder(-1)+"RawData:"+WNameStr)
//								break
//							Else
//								break	
//							EndIf
//							
//						EndIf	
//					EndFor
					
//					If (j==NumPnts(FIWNamesW))
//						print "Couldn't find", WNameStr, "in",AnalParW[11]
//					EndIf
//				EndFor	
//			EndIf
			Break
		Default:
		
	EndSwitch	
	Execute AnalFunc+"()"		
	StrSwitch(AnalFunc)
		Case "pt_PeakAnal":
			AnalParW[0]=OldDataWaveMatchStr
			Break
		Case "pt_SpikeAnal":
			AnalParW[0]=OldDataWaveMatchStr
			Break
		Case "pt_CalSynResp":
			AnalParW[0]=OldDataWaveMatchStr
		Break	
			
		Case "pt_BurstAnal":
			AnalParW[0]=OldDataWaveMatchStr
			Break		
		Case "pt_CalRsRinCmVmIClamp":
			If (DataWaveMatchStrChngd)
				AnalParW[0]=OldDataWaveMatchStr
			EndIf
			Break
		Case "pt_CalRsRinCmVmIClamp":
			If (DataWaveMatchStrChngd)
				AnalParW[0]=OldDataWaveMatchStr
			EndIf
			Break	
		Case "pt_UpdateCellInfo":
			AnalParW[0]=OldCellNameIndexStr
			Break
		Case "pt_CalPeak":
			//AnalParW[0]=OldDataWaveMatchStr	
			If (RawDataFolderExists)	// 03/27/13
				AnalParW[0]=OldDataWaveMatchStr	
				KillDataFolder CurrFldrName+":RawData"
				RawDataFolderExists=0
			EndIf	
			Break
		Case "pt_CalBLAvg":
			If (RawDataFolderExists)	
				AnalParW[0]=OldDataWaveMatchStr	
				KillDataFolder CurrFldrName+":RawData"
				RawDataFolderExists=0
			EndIf	
			Break
		Case "pt_ConctnWFrmFldrs":
			AnalParW[0]=OldDataWaveMatchStr	
			Break	
		//Case "pt_LoadWFrmFldrs":
		//	AnalParW[0]=OldDataWaveMatchStr		
		//	Break
		Case "pt_LoadDataNthWave":
			AnalParW[0]=OldDataWaveMatchStr		
			AnalParW[3] = OldHDFolderPath
			AnalParW[4] = OldIgorFolderPath
		Break	
//		Case "pt_AvgRepeatWaves":
//			AnalParW[0]=OldDataWaveMatchStr		
			Break		
		Default:
	EndSwitch	
//	Concatenate /NP {WNumSpikes}, root:DeprWNumSpikes
//	Concatenate /NP {PlusArea}, root:DeprPlusArea
//	Concatenate /NP {MinusArea}, root:DeprMinusArea
	Print "****************************************************************************************"
	SetDataFolder root:
	If (RawDataFolderExists)
		KillDataFolder CurrFldrName+":RawData"
	EndIf
	iStartRow+=1
While (1)
SetDataFolder OldDF
Print "Analysis", AnalFunc, "over!"
End


Function pt_EditFuncPars(FuncName)
String FuncName
String TableName=FuncName+"_Edit"

DoWindow /F $TableName
If	(!V_Flag)
	Edit /K=1/N=$TableName
EndIf
If (WaveExists($("root:FuncParWaves:"+FuncName+"ParNamesW")) && WaveExists($("root:FuncParWaves:"+FuncName+"ParW")))
	AppendToTable  $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
	//Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
Else 
	Make /T/N=0 $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
	AppendToTable  $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
//	Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
EndIf

End

Function pt_EditWList(WList)
String WList
String WStr
Variable i, N

String TableName="pt_EditWaves"

DoWindow /K $TableName
//If	(!V_Flag)
Edit /K=1/N=$TableName
//EndIf
N = ItemsInList(WList, ";")
For (i = 0; i < N; i+=1)
WStr = StringFromList(i, WList, ";")
//Wave w = $WStr
If (WaveExists($WStr))
	AppendToTable  $WStr
	//Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
Else 
	//DoAlert 0, "Wave"+ WStr+ "does not exist."
	// Might as well make waves if they don't exist. 07/29/14
	Make /T/N=0 $WStr
	AppendToTable  $WStr
EndIf
EndFor
End


Function pt_SubThreshArea(WName, StartX, EndX, BLGaussFilterFreqCutOff, BLGaussFilterAmpCutOff, PlusArea, MinusArea)
String WName
Variable StartX, EndX, BLGaussFilterFreqCutOff, BLGaussFilterAmpCutOff, &PlusArea, &MinusArea
//Variable AreaVal

Duplicate /O $WName, w
Duplicate /O $WName, w_BG

//pt_GaussianFilterData(w_BG,BLGaussFilterFreqCutOff, BLGaussFilterAmpCutOff)
pt_GaussianFilterData()
w -=w_BG	// subtract BackGround

Duplicate /O w, wPlus
Duplicate /O w, wMinus

wPlus=wPlus*(wPlus>0)	// set -ive vals = 0
wMinus=wMinus*(wMinus<0)	// set +ive vals = 0
//display wPlus,wMinus
PlusArea=Area(wPlus, StartX, EndX)
MinusArea=Area(wMinus, StartX, EndX)

KillWaves w, w_BG, wPlus, wMinus 

End


Function pt_GaussianFilterData()	// taken from Wavemetrics Procedure GaussianFilter & slightly modified
	
// This is always the latest version.
// Combining LowPass And HighPass options in same function 27th Sept. 2007
// CutOffAmp = value of gaussian function at cutoff freq. a value of 0.5 means that at cut off freq. the different freq coeff. will
// get attenuated by 50%?? to visulalise:
// use gnuplot to plot y(x)=exp(-x**2/(sigma(f0,a0))**2) with sigma(f0,a0) = f0/sqrt(-log(a0))
// plot [-100:100] y(x), a0=.1,f0=10

String DataWaveMatchStr, DataFldrStr
Variable FreqCutOff, CutOffAmp, LowPassTrue, DisplayResults

String WList, LastUpdatedMM_DD_YYYY="09_27_2007", WNameStr
Variable i,npnts, NumWaves

Print "*********************************************************"
Print "pt_GaussianFilterData last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParW=$pt_GetParWave("pt_GaussianFilterData", "ParW")		

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
FreqCutOff				=	Str2Num(AnalParW[2])
CutOffAmp				=	Str2Num(AnalParW[3])
LowPassTrue			=	Str2Num(AnalParW[4])	//1= lowpass; 0= highpass
DisplayResults			=	Str2Num(AnalParW[5])

PrintAnalPar("pt_GaussianFilterData")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

If (LowPassTrue)
Print "Gaussian low-pass filtering waves, N =", Numwaves, WList
Else
Print "Gaussian high-pass filtering waves, N =", Numwaves, WList
EndIf

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave wOrig = $(GetDataFolder(-1)+DataFldrStr+WNameStr)
	Duplicate /O wOrig, $(WNameStr+"_F")
	Wave w = $(WNameStr+"_F")
	npnts= numpnts(w)
	Redimension/N=(npnts*2) w	// eliminate end-effects
	FFT w
	WAVE/C cfiltered= w
	pt_ApplyGaussFilterRespCmplx(cfiltered,FreqCutOff,CutOffAmp, LowPassTrue)
	IFFT cfiltered
	Redimension/N=(npnts) w
	If (DisplayResults)
	Display
	DoWindow pt_GaussianFilterDataDisplay
	If (V_Flag)
		DoWindow /F pt_GaussianFilterDataDisplay
		Sleep /T 30
		DoWindow /K pt_GaussianFilterDataDisplay
	EndIf
	DoWindow /C pt_GaussianFilterDataDisplay
	AppendToGraph /W=pt_GaussianFilterDataDisplay wOrig, w
	ModifyGraph /W=pt_GaussianFilterDataDisplay rgb($(WNameStr+"_F"))=(0,15872,65280)
EndIf	
	
EndFor

End

Function pt_ApplyGaussFilterResp(w,fCutoff,cutoffAmplitude)
	Wave w
	Variable fCutoff
	Variable cutoffAmplitude // use 0.5 for half-voltage, 1/(sqrt(2)) for half-power
	
	Variable gaussWidth= fCutoff/sqrt(-ln(cutoffAmplitude))
	
	w*= exp(-(x*x/(gaussWidth*gaussWidth)))
End

Function pt_ApplyGaussFilterRespCmplx(w,fCutoff,cutoffAmplitude, LowPass)
	Wave/C w
	Variable fCutoff, LowPass
	Variable cutoffAmplitude // use 0.5 for half-voltage, 1/(sqrt(2)) for half-power
	
	Variable gaussWidth= fCutoff/sqrt(-ln(cutoffAmplitude))
	If (LowPass)
	w *=  cmplx(exp(-(x*x/(gaussWidth*gaussWidth))),0)
	Else
	w *= (1- cmplx(exp(-(x*x/(gaussWidth*gaussWidth))),0))
	EndIf
End

Function pt_PsdCal()
// logic: The wave may need to be smoothed / filtered beforehand
// allow for chosing time range smaller than wavelength
// allow for choosing different window functions
// 
String DataWaveMatchStr, DataFldrStr, PntsPerSegment, OverlapPnts, WindowKind, SubFldr
Variable StartX, EndX, RemoveDC
//Variable FreqCutOff, CutOffAmp, LowPassTrue, DisplayResults

String WList, LastUpdatedMM_DD_YYYY="03_04_2011", WNameStr, DspExecStr
String DspExecStrFull, NewDataFldrStr, SubFldrNoColon
Variable i, NumWaves, ColonPos

Print "*********************************************************"
Print "pt_PsdCal last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParW=$pt_GetParWave("pt_PsdCal", "ParW")		

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
StartX					=	Str2Num(AnalParW[2])
EndX					=	Str2Num(AnalParW[3])
RemoveDC				= 	Str2Num(AnalParW[4])
PntsPerSegment			=	AnalParW[5]
OverlapPnts				=	AnalParW[6]
WindowKind				= 	AnalParW[7]
SubFldr					= 	AnalParW[8]

PrintAnalPar("pt_PsdCal")

If (StringMatch(SubFldr,  "")!=1)
SubFldrNoColon = SubFldr
ColonPos= StrSearch(SubFldrNoColon, ":", inf, 1)	// Search backwards. 
//SubFldrNoColon = ReplaceString(":", SubFldrNoColon, "")
SubFldrNoColon = SubFldrNoColon[0,ColonPos-1]	// Remove last ":"
NewDataFolder /O $(GetDataFolder(1)+SubFldrNoColon)
EndIf

//StartX=   (StartX<0)?	-inf : StartX
//EndX =   (EndX <0)?    inf :  EndX

If (NumType(StartX)==0 && NumType(EndX)==0)
DspExecStr = "DSPPeriodogram /R=("	+Num2Str(StartX)+	","	+Num2Str(EndX)+	")"
Else
DspExecStr = "DSPPeriodogram"
EndIf

//If (StringMatch(StartX,"")!=0 && StringMatch(EndX,"")!=0)
//DspExecStr +=" /R=("		+StartX+		","	+EndX+		")"		// Use Range
//EndIf

If (RemoveDC)					// Remove DC
DspExecStr +=" /NoDC=1"
EndIf

If ((StringMatch(PntsPerSegment,"")!=1) &&StringMatch(OverlapPnts,"")!=1)
DspExecStr +=" /SegN={"	+PntsPerSegment+	","	+OverlapPnts+	"}"
EndIf

//Abort
WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")
Print "Calculating psd for waves, N=", NumWaves
For (i=0;i<NumWaves; i+=1)
WNameStr=StringFromList(i, WList, ";")
Wave w = $GetDataFolder(1)+DataFldrStr+WNameStr
DspExecStrFull = DspExecStr+" "+GetDataFolder(1)+DataFldrStr+WNameStr
//Print DspExecStrFull
Execute DspExecStrFull

Duplicate /O W_Periodogram, $(GetDataFolder(1)+SubFldr+"DSP_"+WNameStr)
EndFor
End

Function pt_PsdBandMeanCal()

//Variable /G MinDeltaFreqInHz=1.5	
//Variable /G MaxDeltaFreqInHz=6
//Variable /G MinThetaFreqInHz=6
//Variable /G MaxThetaFreqInHz=10
//Variable /G MinAlphaFreqInHz=10
//Variable /G MaxAlphaFreqInHz=15
//Variable /G MinBetaFreqInHz=15
//Variable /G MaxBetaFreqInHz=30
//Variable /G MinGammaFreqInHz=30
//Variable /G MaxGammaFreqInHz=50

//From Wikipedia
//Delta < 4Hz
// Theta 4 to < 8Hz
// Alpha 8 to 13 Hz
// Beta >13 to 30 Hz
// Gamma 20- 100+ Hz (Somatosensory cortex)
// Mu 8-13 Hz (Sensorimotor cortex)


End

Function pt_CalSubThreshArea()

String DataWaveMatchStr, WList, WNameStr
Variable StartX, EndX, BLGaussFilterFreqCutOff, BLGaussFilterAmpCutOff, PlusAreaVar, MinusAreaVar, Numwaves, i 

Wave /T SubThreshAreaParW=$("root:FuncParWaves:pt_CalSubThreshArea"+"ParW")
If (WaveExists(SubThreshAreaParW)==0)
	Abort	"Cudn't find the parameter wave pt_CalSubThreshAreaParW!!!"
EndIf

DataWaveMatchStr		=	SubThreshAreaParW[0]
StartX					=	Str2Num(SubThreshAreaParW[1]); 
EndX					=	Str2Num(SubThreshAreaParW[2]); 
BLGaussFilterFreqCutOff	=	Str2Num(SubThreshAreaParW[3])
BLGaussFilterAmpCutOff	=	Str2Num(SubThreshAreaParW[4])

Make /O/N=0  PlusArea, MinusArea
Make /O/N=1  PlusAreaTemp, MinusAreaTemp

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave WNumSpikes=WNumSpikes
	If (WNumSpikes[i]==0)
		pt_SubThreshArea(WNameStr, StartX, EndX, BLGaussFilterFreqCutOff, BLGaussFilterAmpCutOff, PlusAreaVar, MinusAreaVar)
	Else
		PlusAreaVar=Nan; 	MinusAreaVar=Nan
	EndIf
	PlusAreaTemp=PlusAreaVar;	MinusAreaTemp=MinusAreaVar
	Concatenate /NP {PlusAreaTemp}, PlusArea; Concatenate /NP {MinusAreaTemp}, MinusArea;
EndFor
KillWaves PlusAreaTemp, 	MinusAreaTemp
End


Function pt_CalIntWidth()
// Function to calculate integral width of waves. 
// Defn- Area/ Height. 
String DataWaveMatchStr, BaseNameStr
Variable BaseLineYVal
String WList, WNameStr
Variable NumWaves, i
String LastUpdatedMM_DD_YYYY="11_27_2011"

Print "*********************************************************"
Print "pt_CalIntWidth last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"
Wave /T AnalParW=$pt_GetParWave("pt_CalIntWidth", "ParW")
If (WaveExists(AnalParW)==0)
	Abort	"Cudn't find the parameter wave pt_CalIntWidthParW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
BaseLineYVal			=	Str2Num(AnalParW[1])
BaseNameStr			=	AnalParW[2]

PrintAnalPar("pt_CalIntWidth")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")


If (NumWaves>0)
Print "Analyzing waves N=", NumWaves, WList
Make /O/N=(NumWaves) $(BaseNameStr+"IW")
Wave IntWid = $(BaseNameStr+"IW")
IntWid  = Nan

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w = $WNameStr
	Wavestats /Q w
	IntWid[i] = Area(w)/(V_Max-BaseLineYVal)
EndFor	
Else
Print "No waves found to analyze!"
EndIf
End

Function pt_CalRsRinCmVmIClamp()

// The third derivative was overestimating the Rs transient. The seal test response in current clamp shows a fast decrease (or increase if the stim is depolarizing)
// followed by a slower change. This shows as a large decrease in slope (negative valued) followed by an increase (which is still negative) leading to a minimum 
//(or maximum) in slope which can be  easily measured. Two things to be careful about
// 1. Can't smooth the raw data because that smooths the transition between fast change and slow change and makes it more difficult to detect.
// 2. In calculating the slope, the default is /meth = 0 (central difference). This and meth = 1 (forward difference) causes slope to rise before the raw trace 
// begins to change. Meth =2 (backward differences) seems to be more aligned to raw data and peak in slope corresponds to the end of fast transient.
// using transientWin	= 5e-4
// Above changes made on 12/21/13. Previos code commented as //$*^//


// finding the small sharp transient voltage (which when divided by current gives Rs)by fittig the exponential is tricky because the exponential fit
// can be affected by activity. hence switching instead to using the third derivative going to zero (as 1st derivative has point of inflexion).  09/10/2010

// incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. one advantage is that it can also
// fit the steady state value. 05/20/2008

 // incorporated alert message for baseline window, and tExpSteadyState changes 05_13_2008
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
// pt_GetParWave  will find local or global version of par wave  07/24/2007
// corrected print message  07/23/2007
// removed ":" after DataFldrStr 04/23/2009
String DataWaveMatchStr, DataFldrStr, WList, WNameStr
Variable Numwaves, i 
Variable tBaselineStart0,tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I, NumRepeat,RepeatPeriod, SmoothFactor, transientWin, Rs, Rin, Cm, Vm, Tau, tExpFitStart0, tExpFitEnd0	
String LastUpdatedMM_DD_YYYY="02_28_2008"
Variable AlertMessages
String /G CurrentRsRinCmVmWName // 05/22/2008

Print "*********************************************************"
//Print "pt_SpikeAnal last updated on", LastUpdatedMM_DD_YYYY
Print "pt_CalRsRinCmVmIClamp last updated on", LastUpdatedMM_DD_YYYY					// corrected print message  07/23/2007
Print "*********************************************************"


Wave /T AnalParW=$pt_GetParWave("pt_CalRsRinCmVmIClamp", "ParW")			// pt_GetParWave  will find local or global version of par wave  07/24/2007


//If ( WaveExists($"pt_CalRsRinCmVmIClamp"+"ParNamesW") && WaveExists($("pt_CalRsRinCmVmIClamp"+"ParW") ) )

//Wave /T AnalParNamesW	=	$"pt_CalRsRinCmVmIClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"pt_CalRsRinCmVmIClamp"+"ParW"
//Print "***Found pt_CalRsRinCmVmIClampParW in", GetDataFolder(-1), "***"

//ElseIf ( WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParNamesW") && WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParW") )

//Wave /T AnalParNamesW	=	$"root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParW"

//Else

//	Abort	"Cudn't find the parameter waves  pt_CalRsRinCmVmIClampParW and/or pt_CalRsRinCmVmIClampParNamesW!!!"

//EndIf


DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
tBaselineStart0			=Str2Num(AnalParW[2])
tBaselineEnd0			=Str2Num(AnalParW[3])
tSteadyStateStart0		=Str2Num(AnalParW[4])
tSteadyStateEnd0		=Str2Num(AnalParW[5])
SealTestAmp_I			=Str2Num(AnalParW[6])
NumRepeat				=Str2Num(AnalParW[7])
RepeatPeriod			=Str2Num(AnalParW[8])
//tExpSteadyStateStart0	=Str2Num(AnalParW[9])
//tExpSteadyStateEnd0		=Str2Num(AnalParW[10])
tExpFitStart0				=Str2Num(AnalParW[9])
tExpFitEnd0				=Str2Num(AnalParW[10])

// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
														
tSealTestStart0			=Str2Num(AnalParW[11])		
AlertMessages			= Str2Num(AnalParW[12])
SmoothFactor			= Str2Num(AnalParW[13])		// needed before differentiation 09/10/2010
transientWin				= Str2Num(AnalParW[14])		// 12/21/13


PrintAnalPar("pt_CalRsRinCmVmIClamp")
//Print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
//Print "Calculating Rs+Rin instead of the more accurate Rin!!!"
//Print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

//AlertMessages =1 
If (AlertMessages)    // incorporated alert message for baseline window, and tExpSteadyState changes 05_13_2008
//	DoAlert 1, "Recent changes: baseline window shifted; tExpSteadyState changed CONTINUE?"
	DoAlert 1, "Recent changes: Newly defined window for transient. Have you adjusted the value, CONTINUE?"
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf

Make /O/N=0  RsV, RinV, CmV, VmV, TauV
Make /O/N=1  RsVTemp, RinVTemp, CmVTemp, VmVTemp, TauVTemp

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

Print "Calculating RsRinCmVm in I-clamp for waves, N =", ItemsInList(WList, ";"), WList

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	CurrentRsRinCmVmWName = WNameStr			// 05/22/2008
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), w			// removed ":" after DataFldrStr 04/23/2009
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), w
//	If (V_ClampTrue)
//		pt_RsRinCmVclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, Rs,Rin,Cm)
//		pt_RsRinCmVmIclamp1(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, tExpFitStart0, tExpFitEnd0, Rs,Rin,Cm, Vm, Tau)  

//	Else
//		pt_RsRinCmIclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, Rs,Rin,Cm)	
		pt_RsRinCmVmIclamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpFitStart0, tExpFitEnd0, SmoothFactor, transientWin, Rs,Rin,Cm, Vm, Tau)  

//	EndIf
	
	RsVTemp=Rs; RinVTemp=Rin; CmVTemp=Cm; VmVTemp=Vm; TauVTemp=Tau
	Concatenate /NP {RsVTemp}, 	RsV
	Concatenate /NP {RinVTemp},	RinV
	Concatenate /NP {CmVTemp}, 	CmV
	Concatenate /NP {VmVTemp}, 	VmV
	Concatenate /NP {TauVTemp}, TauV
EndFor

KillWaves RsVTemp, RinVTemp, CmVTemp, VmVTemp, TauVTemp, w

End

Function pt_CalRsRinCmVmIClampVarPar1()
// wrapper for pt_CalRsRinCmVmIClamp. will run pt_CalRsRinCmVmIClamp with some parameters varied
String DataWaveMatchStrOld, SealTestAmp_IOld, NewStrOld, DataWaveMatchStrList, SealTestAmp_IList, NewStrList
Variable NDataWaveMatchStrList, NSealTestAmp_IList, NNewStrList, i
String LastUpdatedMM_DD_YYYY="08_18_2008"
Print "*********************************************************"
Print "pt_CalRsRinCmVmIClampVarPar1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_CalRsRinCmVmIClampParW and/or pt_CalRsRinCmVmIClampParNamesW!!!"
EndIf

Wave /T AnalParNamesW1	=	$("root:FuncParWaves:pt_RenameWaves"+"ParNamesW")
Wave /T AnalParW1			=	$("root:FuncParWaves:pt_RenameWaves"+"ParW")
If (WaveExists(AnalParW1)*WaveExists(AnalParNamesW1) ==0 )
	Abort	"Cudn't find the parameter wave pt_RenameWavesParW and/or pt_RenameWavesParNamesW!!!"
EndIf



DataWaveMatchStrOld		=	AnalParW[0]	// count from zero
SealTestAmp_IOld			=	AnalParW[6]

NewStrOld					=    AnalParW1[2]

//DataWaveMatchStrList   = "Cell_00*_0031;Cell_00*_0032;Cell_00*_0033;Cell_00*_0034;"
//DataWaveMatchStrList += "Cell_00*_0035;Cell_00*_0036;Cell_00*_0037;Cell_00*_0038;"
//DataWaveMatchStrList += "Cell_00*_0039;Cell_00*_0040;Cell_00*_0041;Cell_00*_0042;"
//DataWaveMatchStrList += "Cell_00*_0043;Cell_00*_0044;Cell_00*_0045;Cell_00*_0046;"
//DataWaveMatchStrList += "Cell_00*_0047;Cell_00*_0048;Cell_00*_0049;Cell_00*_0050;"

//DataWaveMatchStrList += "Cell_00*_0051;Cell_00*_0052;Cell_00*_0053;Cell_00*_0054;"
//DataWaveMatchStrList += "Cell_00*_0055;Cell_00*_0056;Cell_00*_0057;Cell_00*_0058;"
//DataWaveMatchStrList += "Cell_00*_0059;Cell_00*_0060;Cell_00*_0061;Cell_00*_0062;"
//DataWaveMatchStrList += "Cell_00*_0063;Cell_00*_0064;Cell_00*_0065;Cell_00*_0066;"
//DataWaveMatchStrList += "Cell_00*_0067;Cell_00*_0068;Cell_00*_0069;Cell_00*_0070;"

//DataWaveMatchStrList   = "Cell_00*_0011;Cell_00*_0012;Cell_00*_0013;Cell_00*_0014;"
//DataWaveMatchStrList += "Cell_00*_0015;Cell_00*_0016;Cell_00*_0017;Cell_00*_0018;"
//DataWaveMatchStrList += "Cell_00*_0019;Cell_00*_0020;Cell_00*_0021;Cell_00*_0022;"
//DataWaveMatchStrList += "Cell_00*_0023;Cell_00*_0024;Cell_00*_0025;Cell_00*_0026;"
//DataWaveMatchStrList += "Cell_00*_0027;Cell_00*_0028;Cell_00*_0030;"

//DataWaveMatchStrList += "Cell_00*_0031;Cell_00*_0032;Cell_00*_0033;Cell_00*_0034;"
//DataWaveMatchStrList += "Cell_00*_0035;Cell_00*_0036;Cell_00*_0037;Cell_00*_0038;"
//DataWaveMatchStrList += "Cell_00*_0039;Cell_00*_0040;Cell_00*_0041;Cell_00*_0042;"
//DataWaveMatchStrList += "Cell_00*_0043;Cell_00*_0044;Cell_00*_0045;Cell_00*_0046;"
//DataWaveMatchStrList += "Cell_00*_0047;Cell_00*_0048;Cell_00*_0050;"

DataWaveMatchStrList   = "Cell_00*_0006;Cell_00*_0007;Cell_00*_0008;Cell_00*_0009;Cell_00*_0010;"
DataWaveMatchStrList += "Cell_00*_0011;Cell_00*_0012;Cell_00*_0013;Cell_00*_0014;Cell_00*_0015;"
DataWaveMatchStrList += "Cell_00*_0016;Cell_00*_0017;Cell_00*_0018;Cell_00*_0019;Cell_00*_0020;"
DataWaveMatchStrList += "Cell_00*_0021;Cell_00*_0022;Cell_00*_0023;Cell_00*_0024;Cell_00*_0025;"


DataWaveMatchStrList += "Cell_00*_0026;Cell_00*_0027;Cell_00*_0028;Cell_00*_0029;Cell_00*_0030;"
DataWaveMatchStrList += "Cell_00*_0031;Cell_00*_0032;Cell_00*_0033;Cell_00*_0034;Cell_00*_0035;"
DataWaveMatchStrList += "Cell_00*_0036;Cell_00*_0037;Cell_00*_0038;Cell_00*_0039;Cell_00*_0040;"
DataWaveMatchStrList += "Cell_00*_0041;Cell_00*_0042;Cell_00*_0043;Cell_00*_0044;Cell_00*_0045;"

SealTestAmp_IList  =	"0.12;0.36;0.00;0.18;0.06;"
SealTestAmp_IList+=	"0.48;0.30;0.54;0.42;0.24;"
SealTestAmp_IList+=	"0.12;0.36;0.00;0.18;0.06;"
SealTestAmp_IList+=	"0.48;0.30;0.54;0.42;0.24;"

SealTestAmp_IList+=	"0.12;0.36;0.00;0.18;0.06;"
SealTestAmp_IList+=	"0.48;0.30;0.54;0.42;0.24;"
SealTestAmp_IList+=	"0.12;0.36;0.00;0.18;0.06;"
SealTestAmp_IList+=	"0.48;0.30;0.54;0.42;0.24;"

NewStrList   = "RsV120pABL;RsV360pABL;RsV000pABL;RsV180pABL;RsV060pABL;"
NewStrList += "RsV480pABL;RsV300pABL;RsV540pABL;RsV420pABL;RsV240pABL;"
NewStrList += "RsV120pABL_1;RsV360pABL_1;RsV000pABL_1;RsV180pABL_1;RsV060pABL_1;"
NewStrList += "RsV480pABL_1;RsV300pABL_1;RsV540pABL_1;RsV420pABL_1;RsV240pABL_1;"

NewStrList += "RsV120pADrug;RsV360pADrug;RsV000pADrug;RsV180pADrug;RsV060pADrug;"
NewStrList += "RsV480pADrug;RsV300pADrug;RsV540pADrug;RsV420pADrug;RsV240pADrug;"
NewStrList += "RsV120pADrug_1;RsV360pADrug_1;RsV000pADrug_1;RsV180pADrug_1;RsV060pADrug_1;"
NewStrList += "RsV480pADrug_1;RsV300pADrug_1;RsV540pADrug_1;RsV420pADrug_1;RsV240pADrug_1;"

//SealTestAmp_IList  =	"0.06;0.48;0.57;0.00;"
//SealTestAmp_IList+=	"0.24;0.15;0.18;0.36;"
//SealTestAmp_IList+= 	"0.39;0.12;0.33;0.51;"
//SealTestAmp_IList+= 	"0.03;0.09;0.54;0.45;"
//SealTestAmp_IList+= 	"0.42;0.21;0.27;0.30;"

//SealTestAmp_IList+=	"0.06;0.48;0.57;0.00;"
//SealTestAmp_IList+=	"0.24;0.15;0.18;0.36;"
//SealTestAmp_IList+= 	"0.39;0.12;0.33;0.51;"
//SealTestAmp_IList+= 	"0.03;0.09;0.54;0.45;"
//SealTestAmp_IList+= 	"0.42;0.21;0.27;0.30;"

//SealTestAmp_IList  =	"0.42;0.06;0.36;0.18;"
//SealTestAmp_IList+=	"0.33;0.39;0.54;0.57;"
//SealTestAmp_IList+= 	"0.21;0.15;0.24;0.12;"
//SealTestAmp_IList+= 	"0.09;0.48;0.03;0.27;"
//SealTestAmp_IList+= 	"0.30;0.45;0.51;"

//SealTestAmp_IList+=	"0.42;0.06;0.36;0.18;"
//SealTestAmp_IList+=	"0.33;0.39;0.54;0.57;"
//SealTestAmp_IList+= 	"0.21;0.15;0.24;0.12;"
//SealTestAmp_IList+= 	"0.09;0.48;0.03;0.27;"
//SealTestAmp_IList+= 	"0.30;0.45;0.51;"

//SealTestAmp_IList  =	"0.54;0.18;0.48;0.24;"
//SealTestAmp_IList+=	"0.06;0.30;0.15;0.39;"
//SealTestAmp_IList+= 	"0.12;0.21;0.36;0.33;"
//SealTestAmp_IList+= 	"0.27;0.45;0.42;0.09;"
//SealTestAmp_IList+= 	"0.03;0.57;0.51;"

//SealTestAmp_IList+=	"0.54;0.18;0.48;0.24;"
//SealTestAmp_IList+=	"0.06;0.30;0.15;0.39;"
//SealTestAmp_IList+= 	"0.12;0.21;0.36;0.33;"
//SealTestAmp_IList+= 	"0.27;0.45;0.42;0.09;"
//SealTestAmp_IList+= 	"0.03;0.57;0.51;"

//NewStrList   = "RsV060pA;RsV480pA;RsV570pA;RsV000pA;"
//NewStrList += "RsV240pA;RsV150pA;RsV180pA;RsV360pA;"
//NewStrList += "RsV390pA;RsV120pA;RsV330pA;RsV510pA;"
//NewStrList += "RsV030pA;RsV090pA;RsV540pA;RsV450pA;"
//NewStrList += "RsV420pA;RsV210pA;RsV270pA;RsV300pA;"

//NewStrList += "RsV060pA_1;RsV480pA_1;RsV570pA_1;RsV000pA_1;"
//NewStrList += "RsV240pA_1;RsV150pA_1;RsV180pA_1;RsV360pA_1;"
//NewStrList += "RsV390pA_1;RsV120pA_1;RsV330pA_1;RsV510pA_1;"
//NewStrList += "RsV030pA_1;RsV090pA_1;RsV540pA_1;RsV450pA_1;"
//NewStrList += "RsV420pA_1;RsV210pA_1;RsV270pA_1;RsV300pA_1;"


//NewStrList   = "RsV420pA;RsV060pA;RsV360pA;RsV180pA;"
//NewStrList += "RsV330pA;RsV390pA;RsV540pA;RsV570pA;"
//NewStrList += "RsV210pA;RsV150pA;RsV240pA;RsV120pA;"
//NewStrList += "RsV090pA;RsV480pA;RsV030pA;RsV270pA;"
//NewStrList += "RsV300pA;RsV450pA;RsV510pA;"

//NewStrList += "RsV420pA_1;RsV060pA_1;RsV360pA_1;RsV180pA_1;"
//NewStrList += "RsV330pA_1;RsV390pA_1;RsV540pA_1;RsV570pA_1;"
//NewStrList += "RsV210pA_1;RsV150pA_1;RsV240pA_1;RsV120pA_1;"
//NewStrList += "RsV090pA_1;RsV480pA_1;RsV030pA_1;RsV270pA_1;"
//NewStrList += "RsV300pA_1;RsV450pA_1;RsV510pA_1;"

//NewStrList   = "RsV540pA;RsV180pA;RsV480pA;RsV240pA;"
//NewStrList += "RsV060pA;RsV300pA;RsV150pA;RsV390pA;"
//NewStrList += "RsV120pA;RsV210pA;RsV360pA;RsV330pA;"
//NewStrList += "RsV270pA;RsV450pA;RsV420pA;RsV090pA;"
//NewStrList += "RsV030pA;RsV570pA;RsV510pA;"

//NewStrList += "RsV540pA_1;RsV180pA_1;RsV480pA_1;RsV240pA_1;"
//NewStrList += "RsV060pA_1;RsV300pA_1;RsV150pA_1;RsV390pA_1;"
//NewStrList += "RsV120pA_1;RsV210pA_1;RsV360pA_1;RsV330pA_1;"
//NewStrList += "RsV270pA_1;RsV450pA_1;RsV420pA_1;RsV090pA_1;"
//NewStrList += "RsV030pA_1;RsV570pA_1;RsV510pA_1;"


NDataWaveMatchStrList = ItemsInList(DataWaveMatchStrList, ";")
NSealTestAmp_IList = ItemsInList(SealTestAmp_IList, ";")
NNewStrList = ItemsInList(NewStrList, ";")

If ( (NDataWaveMatchStrList != NSealTestAmp_IList) || (NDataWaveMatchStrList != NNewStrList)  )
Abort "Unequal number of items in list of varied parameters"
EndIf

For (i=0; i<NDataWaveMatchStrList; i+=1)
AnalParW[0] = StringFromList(i,DataWaveMatchStrList, ";")
AnalParW[6] = StringFromList(i,SealTestAmp_IList, ";")
pt_AnalWInFldrs2("pt_CalRsRinCmVmIClamp")

AnalParW1[2] = StringFromList(i, NewStrList, ";")
pt_AnalWInFldrs2("pt_RenameWaves")

EndFor

AnalParW[0] = DataWaveMatchStrOld
AnalParW[6] = SealTestAmp_IOld
AnalParW1[2] = NewStrOld

End

//-------------
Function pt_CalRsRinCmVmVClamp()
// allowed ExcludeWNamesWStr to be empty, that is excludeW need not be specified 10/30/12
// Switched to using pt_RsRinCmVmVclamp3 in this function (implements pclamp seal test analysis) (04/18_12)

// curvefitting exponential is difficult for the falling phase of series-resistance transient as it's very fast and only has 2-3 points before
// it gives rise to slower decay due to membrane RIn and Cm. So just for the amplitude of series resistance transient i am switching to
// finding minimum or maximum using wavestats. //07/14/2008

// incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. one advantage is that it can also
// fit the steady state value. 07/14/2008  (already changed for current clamp on 05/20/2008)
 // incorporated alert message for baseline window, and tExpSteadyState changes 07_14_2008 (already changed for current clamp on 05/13/2008)
 
 
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
// pt_GetParWave  will find local or global version of par wave  07/24/2007
// corrected print message 							 07/23/2007
// praveen: corrected i-clamp to v-clamp in print message 06/13/2007
// removed ":" after DataFldrStr 04/23/2009
String DataWaveMatchStr, DataFldrStr, WList, WNameStr
Variable Numwaves, i 
Variable tBaselineStart0,tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V, NumRepeat,RepeatPeriod, Rs, Rin, Cm, Im, Tau
//Variable tExp1SteadyStateStart0, tExp1SteadyStateEnd0, tExp1FitStart0, tExp1FitEnd0, tExp2SteadyStateStart0, tExp2SteadyStateEnd0, tExp2FitStart0, tExp2FitEnd0		
Variable tSealTestPeakWinDel, tExp1FitStart0, tExp1FitEnd0		
String LastUpdatedMM_DD_YYYY="04_18_2012", ExcludeWNamesWStr
Variable AlertMessages
String /G CurrentRsRinCmImWName // 07/14/2008


Print "*********************************************************"
// Print "pt_SpikeAnal last updated on", LastUpdatedMM_DD_YYYY
Print "CalRsRinCmVmVClamp last updated on", LastUpdatedMM_DD_YYYY	// corrected print message  07/23/2007
Print "*********************************************************"

Wave /T AnalParW=$pt_GetParWave("pt_CalRsRinCmVmVClamp", "ParW")			// pt_GetParWave  will find local or global version of par wave  07/24/2007

//If ( WaveExists($"pt_CalRsRinCmVmVClamp"+"ParNamesW") && WaveExists($("pt_CalRsRinCmVmVClamp"+"ParW") ) )

//Wave /T AnalParNamesW	=	$"pt_CalRsRinCmVmVClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"pt_CalRsRinCmVmVClamp"+"ParW"
//Print "***Found pt_CalRsRinCmVmVClampParW in", GetDataFolder(-1), "***"

//ElseIf ( WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParNamesW") && WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParW") )

//Wave /T AnalParNamesW	=	$"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParW"

//Else

//	Abort	"Cudn't find the parameter waves  pt_CalRsRinCmVmVClampParW and/or pt_CalRsRinCmVmVClampParNamesW!!!"

//EndIf


DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
tBaselineStart0			=Str2Num(AnalParW[2])
tBaselineEnd0			=Str2Num(AnalParW[3])
tSteadyStateStart0		=Str2Num(AnalParW[4])
tSteadyStateEnd0		=Str2Num(AnalParW[5])
SealTestAmp_V			=Str2Num(AnalParW[6])
//SealTestAmp_I			=Str2Num(AnalParW[6])
NumRepeat				=Str2Num(AnalParW[7])
RepeatPeriod			=Str2Num(AnalParW[8])
//V_ClampTrue			=Str2Num(AnalParW[10])
//tExp1SteadyStateStart0		=Str2Num(AnalParW[9])
//tExp1SteadyStateEnd0		=Str2Num(AnalParW[10])
//tExp1FitStart0				=Str2Num(AnalParW[9])
//tExp1FitEnd0				=Str2Num(AnalParW[10])
//tExp2SteadyStateStart0		=Str2Num(AnalParW[13])
//tExp2SteadyStateEnd0		=Str2Num(AnalParW[14])
//tSealTestPeakWinDel			= Str2Num(AnalParW[9])
tExp1FitStart0				=Str2Num(AnalParW[9])
tExp1FitEnd0				=Str2Num(AnalParW[10])
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
														
tSealTestStart0				=Str2Num(AnalParW[11])	
AlertMessages			= Str2Num(AnalParW[12])	
ExcludeWNamesWStr	= AnalParW[13]
If (!StringMatch(ExcludeWNamesWStr,""))	//10/30/12 
	ExcludeWNamesWStr = GetDataFolder(0)+ExcludeWNamesWStr
EndIf

														
PrintAnalPar("pt_CalRsRinCmVmVClamp")

If (AlertMessages)    // incorporated alert message for baseline window, and tExpSteadyState changes 07_14_2008
//	DoAlert 1, "Recent changes: baseline window shifted; tExpSteadyState changed CONTINUE?"
	DoAlert 1, "Recent changes: new vals for baseline and steadystate locations, CONTINUE?"
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf

//DoAlert 1, "Recent changes: new vals for baseline and steadystate locations, CONTINUE?"
//If (V_Flag==2)
//		Abort "Aborting..."
//EndIf

Make /O/N=0  RsV, RinV, CmV, ImV, TauV
Make /O/N=1  RsVTemp, RinVTemp, CmVTemp, ImVTemp, TauVTemp

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
If (!StringMatch(ExcludeWNamesWStr,""))	//10/30/12 
	Wlist = pt_ExcludeFromWList(ExcludeWNamesWStr, Wlist)		// added 08_30_12
EndIf



Numwaves=ItemsInList(WList, ";")

//Print "Calculating RsRinCmVm in I-clamp for waves, N =", ItemsInList(WList, ";"), WList		praveen: corrected i-clamp to v-clamp in print message 06/13/2007
Print "Calculating RsRinCmVm in V-clamp for waves, N =", ItemsInList(WList, ";"), WList


For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	CurrentRsRinCmImWName = WNameStr			// 07/14/2008
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), w				// removed ":" after DataFldrStr 04/23/2009
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), w
//	If (V_ClampTrue)
//		pt_RsRinCmVclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, Rs,Rin,Cm)
//		pt_RsRinCmVmVclamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp1SteadyStateStart0, tExp1SteadyStateEnd0, tExp1FitStart0, tExp1FitEnd0, tExp2SteadyStateStart0, tExp2SteadyStateEnd0, tExp2FitStart0, tExp2FitEnd0, Rs,Rin,Cm, Im, Tau)  
//		pt_RsRinCmVmVclamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0,  tSealTestPeakWinDel, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp2FitStart0, tExp2FitEnd0, Rs,Rin,Cm, Im, Tau) 
		pt_RsRinCmVmVclamp3(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSteadyStateStart0, tSteadyStateEnd0, SealTestAmp_V, NumRepeat,RepeatPeriod, tExp1FitStart0, tExp1FitEnd0, Rs,Rin,Cm, Im, Tau) 
//	Else
//		pt_RsRinCmIclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, Rs,Rin,Cm)	
//		pt_RsRinCmVmIclamp1(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, tExpFitStart0, tExpFitEnd0, Rs,Rin,Cm, Vm, Tau)  

//	EndIf
	
	RsVTemp=Rs; RinVTemp=Rin; CmVTemp=Cm; ImVTemp=Im; TauVTemp=Tau
	Concatenate /NP {RsVTemp}, 	RsV
	Concatenate /NP {RinVTemp},	RinV
	Concatenate /NP {CmVTemp}, 	CmV
	Concatenate /NP {ImVTemp}, 	ImV
	Concatenate /NP {TauVTemp}, TauV
EndFor

KillWaves RsVTemp, RinVTemp, CmVTemp, ImVTemp, TauVTemp, w

End //pt_CalRsRinCmVmVClamp()
//-------------

Function pt_CalRsRinCmVmVClamp1()
// superseeded by pt_CalRsRinCmVmVClamp() (04_18_12)


// curvefitting exponential is difficult for the falling phase of series-resistance transient as it's very fast and only has 2-3 points before
// it gives rise to slower decay due to membrane RIn and Cm. So just for the amplitude of series resistance transient i am switching to
// finding minimum or maximum using wavestats. //07/14/2008

// incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. one advantage is that it can also
// fit the steady state value. 07/14/2008  (already changed for current clamp on 05/20/2008)
 // incorporated alert message for baseline window, and tExpSteadyState changes 07_14_2008 (already changed for current clamp on 05/13/2008)
 
 
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
// pt_GetParWave  will find local or global version of par wave  07/24/2007
// corrected print message 							 07/23/2007
// praveen: corrected i-clamp to v-clamp in print message 06/13/2007
// removed ":" after DataFldrStr 04/23/2009
String DataWaveMatchStr, DataFldrStr, WList, WNameStr
Variable Numwaves, i 
Variable tBaselineStart0,tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V, NumRepeat,RepeatPeriod, Rs, Rin, Cm, Im, Tau
//Variable tExp1SteadyStateStart0, tExp1SteadyStateEnd0, tExp1FitStart0, tExp1FitEnd0, tExp2SteadyStateStart0, tExp2SteadyStateEnd0, tExp2FitStart0, tExp2FitEnd0		
Variable tSealTestPeakWinDel, tExp2FitStart0, tExp2FitEnd0		
String LastUpdatedMM_DD_YYYY="07_14_2008"
Variable AlertMessages
String /G CurrentRsRinCmImWName // 07/14/2008


Print "*********************************************************"
// Print "pt_SpikeAnal last updated on", LastUpdatedMM_DD_YYYY
Print "CalRsRinCmVmVClamp last updated on", LastUpdatedMM_DD_YYYY	// corrected print message  07/23/2007
Print "*********************************************************"

Wave /T AnalParW=$pt_GetParWave("pt_CalRsRinCmVmVClamp", "ParW")			// pt_GetParWave  will find local or global version of par wave  07/24/2007

//If ( WaveExists($"pt_CalRsRinCmVmVClamp"+"ParNamesW") && WaveExists($("pt_CalRsRinCmVmVClamp"+"ParW") ) )

//Wave /T AnalParNamesW	=	$"pt_CalRsRinCmVmVClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"pt_CalRsRinCmVmVClamp"+"ParW"
//Print "***Found pt_CalRsRinCmVmVClampParW in", GetDataFolder(-1), "***"

//ElseIf ( WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParNamesW") && WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParW") )

//Wave /T AnalParNamesW	=	$"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParW"

//Else

//	Abort	"Cudn't find the parameter waves  pt_CalRsRinCmVmVClampParW and/or pt_CalRsRinCmVmVClampParNamesW!!!"

//EndIf


DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
tBaselineStart0			=Str2Num(AnalParW[2])
tBaselineEnd0			=Str2Num(AnalParW[3])
tSteadyStateStart0		=Str2Num(AnalParW[4])
tSteadyStateEnd0		=Str2Num(AnalParW[5])
SealTestAmp_V			=Str2Num(AnalParW[6])
//SealTestAmp_I			=Str2Num(AnalParW[6])
NumRepeat				=Str2Num(AnalParW[7])
RepeatPeriod			=Str2Num(AnalParW[8])
//V_ClampTrue			=Str2Num(AnalParW[10])
//tExp1SteadyStateStart0		=Str2Num(AnalParW[9])
//tExp1SteadyStateEnd0		=Str2Num(AnalParW[10])
//tExp1FitStart0				=Str2Num(AnalParW[9])
//tExp1FitEnd0				=Str2Num(AnalParW[10])
//tExp2SteadyStateStart0		=Str2Num(AnalParW[13])
//tExp2SteadyStateEnd0		=Str2Num(AnalParW[14])
tSealTestPeakWinDel			= Str2Num(AnalParW[9])
tExp2FitStart0				=Str2Num(AnalParW[10])
tExp2FitEnd0				=Str2Num(AnalParW[11])
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
														
tSealTestStart0				=Str2Num(AnalParW[12])	
AlertMessages			= Str2Num(AnalParW[13])	
														
PrintAnalPar("pt_CalRsRinCmVmVClamp")

If (AlertMessages)    // incorporated alert message for baseline window, and tExpSteadyState changes 07_14_2008
//	DoAlert 1, "Recent changes: baseline window shifted; tExpSteadyState changed CONTINUE?"
	DoAlert 1, "Recent changes: wavestats for Rs transient, using curvefit, baseline window shifted, CONTINUE?"
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf


Make /O/N=0  RsV, RinV, CmV, ImV, TauV
Make /O/N=1  RsVTemp, RinVTemp, CmVTemp, ImVTemp, TauVTemp

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

//Print "Calculating RsRinCmVm in I-clamp for waves, N =", ItemsInList(WList, ";"), WList		praveen: corrected i-clamp to v-clamp in print message 06/13/2007
Print "Calculating RsRinCmVm in V-clamp for waves, N =", ItemsInList(WList, ";"), WList


For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	CurrentRsRinCmImWName = WNameStr			// 07/14/2008
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), w				// removed ":" after DataFldrStr 04/23/2009
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), w
//	If (V_ClampTrue)
//		pt_RsRinCmVclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, Rs,Rin,Cm)
//		pt_RsRinCmVmVclamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp1SteadyStateStart0, tExp1SteadyStateEnd0, tExp1FitStart0, tExp1FitEnd0, tExp2SteadyStateStart0, tExp2SteadyStateEnd0, tExp2FitStart0, tExp2FitEnd0, Rs,Rin,Cm, Im, Tau)  
		pt_RsRinCmVmVclamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0,  tSealTestPeakWinDel, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp2FitStart0, tExp2FitEnd0, Rs,Rin,Cm, Im, Tau)  
//	Else
//		pt_RsRinCmIclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, Rs,Rin,Cm)	
//		pt_RsRinCmVmIclamp1(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, tExpFitStart0, tExpFitEnd0, Rs,Rin,Cm, Vm, Tau)  

//	EndIf
	
	RsVTemp=Rs; RinVTemp=Rin; CmVTemp=Cm; ImVTemp=Im; TauVTemp=Tau
	Concatenate /NP {RsVTemp}, 	RsV
	Concatenate /NP {RinVTemp},	RinV
	Concatenate /NP {CmVTemp}, 	CmV
	Concatenate /NP {ImVTemp}, 	ImV
	Concatenate /NP {TauVTemp}, TauV
EndFor

KillWaves RsVTemp, RinVTemp, CmVTemp, ImVTemp, TauVTemp, w

End






Function pt_CalBLAvg()
// In pt_CalBLAvg if no points to average (start or end point =Nan), do not create any wave. 12/19/2008
// This function is pretty similar to pt_AverageVals() and pt_CalAvgAtXWVals()
// can be used for avg Vm or Im

String DataWaveMatchStr, DataFldrStr, RangeW, BaseNameStr, WList, WNameStr

Variable Numwaves, i 

Variable tBaselineStart0, tBaselineEnd0

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_CalBLAvg"+"ParNamesW")

Wave /T AnalParW		=	$("root:FuncParWaves:pt_CalBLAvg"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_CalBLAvgParW and/or pt_CalBLAvgParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
//tBaselineStart0			=Str2Num(AnalParW[2])
//tBaselineEnd0			=Str2Num(AnalParW[3])
RangeW					=	AnalParW[2]
//BaseNameStr			=	AnalParW[4]
BaseNameStr			=	AnalParW[3]

//Print "Analysis parameters"
//Print "****************************************************************************************"
//i=0
//Do
//	If (i>=NumPnts(AnalParW))
//		Break
//	Else
//	 	Print AnalParNamesW[i], "=", AnalParW[i]
//	 EndIf	
//	 i+=1
//While (1)
//Print "****************************************************************************************"
PrintAnalPar("pt_CalBLAvg")

Wave /T AnalParNamesW		=	$pt_GetParWave(RangeW, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(RangeW, "ParW")

tBaselineStart0					=	Str2Num(AnalParW[0])
tBaselineEnd0					=	Str2Num(AnalParW[1])

PrintAnalPar(RangeW)

// In pt_CalBLAvg if no points to average (start or end point =Nan), do not create any wave.

If (NumType(tBaselineStart0)!=2 && NumType(tBaselineStart0)!=2)		


Make /O/N=0		$BaseNameStr+"Avg"
Wave BLW		=	$BaseNameStr+"Avg"
Make /O/N=1		$BaseNameStr+"TmpAvg"
Wave BLWTmp	=	$BaseNameStr+"TmpAvg"


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

Print "Calculating BL average for waves, N =", ItemsInList(WList, ";"), WList

For (i=0; i<NumWaves; i+=1)
	
	WNameStr=StringFromList(i, WList, ";")
	
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), w
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), w
	Wavestats /Q /R=(tBaselineStart0, tBaselineEnd0) w
	BLWTmp=V_Avg
	Concatenate /NP {BLWTmp}, BLW

EndFor

KillWaves BLWTmp, w
Else
	// In pt_CalBLAvg if no points to average (start or end point =Nan), do not create any wave.
	Print "No points to average. No wave created!!"
EndIf
End


Function pt_CalAvgAtXWVals()
// adapted from pt_CalBLAvg. pt_CalBLAvg calculates average between start and end values provided by
//RangeW. This function will  average at given x-values (actually x-values -Del to X-values +Del)

String DataWaveMatchStr, XWName, BaseNameString, InsrtNewStr, InsrtPosStr
Variable DelX, ReplaceExisting

String WList, WyStr, NewWNameStr
Variable NumWaves, NumXPnts, i, XStart, XEnd, WyStartX, WyEndX

String LastUpdatedMM_DD_YYYY="02_24_2009"

Print "*********************************************************"
Print "pt_CalAvgAtXWVals last updated on", LastUpdatedMM_DD_YYYY	// corrected print message  07/23/2007
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalAvgAtXWVals", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_CalAvgAtXWVals", "ParW")

If (WaveExists(AnalParNamesW)&&WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_CalAvgAtXWValsParW and/or pt_CalAvgAtXWValsParNamesW!!!"
EndIf

DataWaveMatchStr	=		AnalParW[0]
XWName			=		AnalParW[1]
DelX				=		Str2Num(AnalParW[2]) 
//DataFldrStr			=		AnalParW[3]		data folder will be set by pt_AnalWInFldrs2, so that multiple folders can be analyzed
InsrtNewStr			=		AnalParW[3]
InsrtPosStr			=		AnalParW[4]
ReplaceExisting		=		Str2Num(AnalParW[5])

PrintAnalPar("pt_CalAvgAtXWVals")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")

Wave Wx = $XWName
NumXPnts= NumPnts(Wx)

If (NumXPnts == NumWaves)
Print "Calculating average for waves, N =", NumXPnts, WList
			For (i=0; i<NumXPnts; i+=1)
			WyStr=StringFromList(i, WList, ";")
			Wave Wy=$WyStr
			
			XStart	= Wx[i]	-	DelX
			XEnd	= Wx[i]	+	DelX
			
			WyStartX = DimOffset(Wy,0)
			WyEndX =  WyStartX+(NumPnts(Wy)-1)*DimDelta(Wy,0)
			
			XStart = (XStart<=WyStartX) ? WyStartX : XStart
			XEnd = 	(XEnd>=WyEndX) ? WyEndX : XEnd
			
//			Print "XStart, XEnd", XStart, XEnd
			If (	(NumType(XStart)==0) && (NumType(XEnd)==0)	)
			WaveStats /Q/R=(XStart, XEnd)	Wy
			NewWNameStr = pt_CalNewNameStr(WyStr, InsrtNewStr, InsrtPosStr, ReplaceExisting)
			
			Make /O/N=1 $(NewWNameStr+"Avg")
			Wave WNewAvg	= $(NewWNameStr+"Avg")
			WNewAvg[0] = V_Avg
			
			Make /O/N=1 $(NewWNameStr+"SD")
			Wave WNewSD	= $(NewWNameStr+"SD")
			WNewSD[0] = V_SDev
			
			Make /O/N=1 $(NewWNameStr+"Num")
			Wave WNewNum	= $(NewWNameStr+"Num")
			WNewNum[0] = V_NPnts
			
			Make /O/N=1 $(NewWNameStr+"SE")
			Wave WNewSE	= $(NewWNameStr+"SE")
			WNewSE[0] = V_SDev/(sqrt(V_Npnts))
			
			Else
			
				NewWNameStr = pt_CalNewNameStr(WyStr, InsrtNewStr, InsrtPosStr, ReplaceExisting)
				
				Make /O/N=1 $(NewWNameStr+"Avg")
				Wave WNewAvg	= $(NewWNameStr+"Avg")
				WNewAvg[0] = Nan
				
				Make /O/N=1 $(NewWNameStr+"SD")
				Wave WNewSD	= $(NewWNameStr+"SD")
				WNewSD[0] = Nan
				
				Make /O/N=1 $(NewWNameStr+"Num")
				Wave WNewNum	= $(NewWNameStr+"Num")
				WNewNum[0] = Nan
				
				Make /O/N=1 $(NewWNameStr+"SE")
				Wave WNewSE	= $(NewWNameStr+"SE")
				WNewSE[0] = Nan
			EndIf

			EndFor		
Else
Print "Unequal number of points in YWaveList", WList, "and XWave", XWName
EndIf

End


Function pt_AverageWFrmFldrs()

String DataWaveMatchStr, DataFldrStr, BaseNameStr, WList, WNameStr, ExcludeWNamesWStr//, DataWaveMatchStrOld, XWaveMatchStrOld

Variable Numwaves, i, PntsPerBin, DisplayAvg//, WindowNameIsFldrNameOld  


Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_AverageWFrmFldrs"+"ParNamesW")

Wave /T AnalParW		=	$("root:FuncParWaves:pt_AverageWFrmFldrs"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AverageWFrmFldrsParW and/or pt_AverageWFrmFldrsParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
BaseNameStr			=	AnalParW[2]
PntsPerBin				=	Str2Num(AnalParW[3])
ExcludeWNamesWStr	=	AnalParW[4]
DisplayAvg				=	Str2Num(AnalParW[5])

PrintAnalPar("pt_AverageWFrmFldrs")

//Wave /T AnalParNamesW		=$("root:FuncParWaves:pt_DisplayWFrmFldrs"+"ParNamesW")
//Wave /T AnalParW			=$("root:FuncParWaves:pt_DisplayWFrmFldrs"+"ParW")

//If (WaveExists(AnalParNamesW)&&WaveExists(ANalParW) == 0)
//	Abort	"Cudn't find the parameter waves pt_DisplayWFrmFldrsParW and/or pt_DisplayWFrmFldrsParNamesW!!!"
//EndIf

//DestFolderName		=ParW[0]
//DataWaveMatchStrOld		=AnalParW[0]
//WindowNameIsFldrNameOld	=Str2Num(AnalParW[1])
//XWaveMatchStrOld			=AnalParW[2]
//DestWNameStr			=ParW[2]

//AnalParW[0]		=	DataWaveMatchStr
//AnalParW[1]		=	Num2Str(1)	
//AnalParW[2]		=	""

//pt_DisplayWFrmFldrs()
//DoWindow 

//AnalParW[0]		=	DataWaveMatchStrOld
//AnalParW[1]		=	Num2Str(WindowNameIsFldrNameOld)
//AnalParW[2]		=	XWaveMatchStrOld

pt_AverageWaves()


End












Function pt_UserCommands()
String CommandStr

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_UserCommands"+"ParNamesW")
Wave /T AnalParW		=	$("root:FuncParWaves:pt_UserCommands"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_UserCommandsParW and/or pt_UserCommandsParNamesW!!!"
EndIf

CommandStr				=	AnalParW[0]
PrintAnalPar("pt_UserCommands")

Execute CommandStr	

End




Function pt_AppendWFrmFldrs()
String WList, WNameStr, OrigWNameStr, DestWNameStr
Variable Numwaves, i 

Wave /T OrigWNames		=$("root:FuncParWaves:pt_AppendWFrmFldrs"+"ParNamesW")
Wave /T DestWNames	=$("root:FuncParWaves:pt_AppendWFrmFldrs"+"ParW")

If (WaveExists(OrigWNames)&&WaveExists(DestWNames) == 0)
	Abort	"Cudn't find the parameter waves  pt_AppendWFrmFldrsParW and/or pt_AppendWFrmFldrsParNamesW!!!"
EndIf

Numwaves=NumPnts(OrigWNames)

For (i=0; i<NumWaves; i+=1) 
	OrigWNameStr=OrigWNames[i]
	DestWNameStr=DestWNames[i]
	Wave wOrig=$OrigWNameStr
	Concatenate /NP {wOrig}, $DestWNameStr
EndFor
//KillWaves wOrig
End

Function pt_AppendWFrmFldrs1()
String DataWaveMatchStr, DataFldrStr, DestWNameStr

String OldDF, WList, WNameStr
Variable Numwaves, i 

Wave /T ParNamesW	=$("root:FuncParWaves:pt_AppendWFrmFldrs1"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_AppendWFrmFldrs1"+"ParW")

If (WaveExists(ParNamesW	)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AppendWFrmFldrs1ParW and/or pt_AppendWFrmFldrs1ParNamesW!!!"
EndIf

DataWaveMatchStr			= 		ParW[0]
DataFldrStr					=		ParW[1]
DestWNameStr				=		ParW[2]

OldDF=GetDataFolder(-1)
SetDataFolder $DataFldrStr

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))

NumWaves=	ItemsInList(WList,";")

Make /O/N=0 $(DestWNameStr)

For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList,";")
	Wave w=$WNameStr
	Concatenate /NP {w}, $(DestWNameStr)
EndFor
SetDataFolder OldDF
//KillWaves wOrig
End

Function pt_ConctnWFrmFldrs()

// This is always the latest version

// Modified to concatenate a subrange
// ":" should be included in DataFldrStr itself. eg. RawData: 12/12/2007

String WList, DataWaveMatchStr, DataFldrStr, DestWNameStr, OldDF
Variable StartX, EndX
String WNameStr
Variable Numwaves, i 

Wave /T ParNamesW	=$("root:FuncParWaves:pt_ConctnWFrmFldrs"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_ConctnWFrmFldrs"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_ConctnWFrmFldrsParW and/or pt_ConctnWFrmFldrsParNamesW!!!"
EndIf

DataWaveMatchStr	=ParW[0]
DataFldrStr			=ParW[1]
//DestWNameStr	  	=GetDataFolder(0) //=ParW[2]
DestWNameStr	  	=ParW[2]	// 05/06/2014
StartX				=Str2Num(ParW[3])			// 05/06/2014
EndX				=Str2Num(ParW[4])				// 05/06/2014



If (NumPnts(ParW) != 5)
	DoAlert 0, "pt_ConctnWFrmFldrs takes 5 parameters as of May 6th, 2014. Please correct. Aborting!"
EndIf

If (StringMatch(DestWNameStr, ""))
	DestWNameStr = GetDataFolder(0)
EndIf

If (StartX == -1)
	StartX = -inf
EndIf

If (EndX == -1)
	EndX = inf
EndIf


PrintAnalPar("pt_ConctnWFrmFldrs")

OldDF=GetDataFolder(-1)
SetDataFolder $(OldDF+DataFldrStr)
WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Print "Concatenating waves, N =", ItemsInList(WList, ";"), WList

// Duplicate sub-range	// 05/06/2014
Numwaves = ItemsInList(WList, ";")
For (i =0; i< Numwaves; i+=1)
	WNameStr = StringFromList(i, WList, ";")
	Duplicate /O /R=(StartX, EndX) $WNameStr, $WNameStr+"Cn" // because we can't overwrite self
	KillWaves /Z  $WNameStr
	Duplicate /O $WNameStr+"Cn", $WNameStr
	KillWaves /Z  $WNameStr+"Cn"
EndFor

Concatenate /NP WList, $(GetDataFolder(1)+DestWNameStr)
SetDataFolder OldDF
//Wave w = $(GetDataFolder(-1)+DataFldrStr+":"+DestWNameStr)
Wave w = $(GetDataFolder(1)+DataFldrStr+DestWNameStr)  // ":" should be included in DataFldrStr itself. eg. RawData:
SetScale /P x,0,DimDelta(w, 0), w
If (!StringMatch(DataFldrStr,""))	// 05/03/11
Duplicate /O w, $(GetDataFolder(1)+DestWNameStr)
EndIf
End

Function pt_ConctnWFrmFldrs1()

// This is always the latest version

// modified from pt_ConctnWFrmFldrs(). When run over several cells, only the data folder is set but
// DataWaveMatchStr, DataFldrStr remains unchanged. Useful to concatenate waves other than Cell_00*

// ":" should be included in DataFldrStr itself. eg. RawData: 12/12/2007

String WList, DataWaveMatchStr, DataFldrStr, DestWNameStr, OldDF
Variable Numwaves, i 

Wave /T ParNamesW	=$("root:FuncParWaves:pt_ConctnWFrmFldrs1"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_ConctnWFrmFldrs1"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_ConctnWFrmFldrs1ParW and/or pt_ConctnWFrmFldrs1ParNamesW!!!"
EndIf

DataWaveMatchStr	=ParW[0]
DataFldrStr			=ParW[1]
DestWNameStr		=ParW[2]

PrintAnalPar("pt_ConctnWFrmFldrs1")

//DestWNameStr	  	=GetDataFolder(0) //=ParW[2]
OldDF=GetDataFolder(1)
SetDataFolder $(OldDF+DataFldrStr)
Make /O/N=0 $DestWNameStr

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1))
Print "Concatenating waves, N =", ItemsInList(WList, ";"), WList

Concatenate /NP WList, $(GetDataFolder(1)+DestWNameStr)
SetDataFolder OldDF
//Wave w = $(GetDataFolder(-1)+DataFldrStr+":"+DestWNameStr)
//Wave w = $(GetDataFolder(1)+DataFldrStr+DestWNameStr)  // ":" should be included in DataFldrStr itself. eg. RawData:
//If (!StringMatch(DataFldrStr,""))	// 05/03/11
//Duplicate /O w, $(GetDataFolder(1)+DestWNameStr)
//EndIf
End


// This function is used in conjunction with pt_LoadData() which loads the waves in RawData folder, and then 
// pt_LoadWFrmFldrs() is called

Function pt_LoadWFrmFldrs()
// This function is used in conjunction with pt_LoadData() which loads the waves in RawData folder, and then 
// pt_LoadWFrmFldrs() is called. at some point i want to replace this completely with pt_LoadData() March10th 2008
String WList, DataWaveMatchStr, DataFldrStr, DestWNameStr, OldDF, WNameStr
Variable AllWaves, Numwaves, i 

Wave /T ParNamesW	=$("root:FuncParWaves:pt_LoadWFrmFldrs"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_LoadWFrmFldrs"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_LoadWFrmFldrsParW and/or pt_LoadWFrmFldrsParNamesW!!!"
EndIf

DataWaveMatchStr	=ParW[0]
DataFldrStr			=ParW[1]
AllWaves			=Str2Num(ParW[2])

PrintAnalPar("pt_LoadWFrmFldrs")

DestWNameStr	  	=GetDataFolder(0) //=ParW[2]
OldDF=GetDataFolder(-1)
SetDataFolder $(OldDF+DataFldrStr)
WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Print "Loading waves, N =", ItemsInList(WList, ";"), WList

SetDataFolder OldDF
Numwaves=ItemsInList(WList)
For (i=0; i<Numwaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
//	Wave w = $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr)	01_10_11
	Wave w = $(GetDataFolder(-1)+DataFldrStr+WNameStr)
	Duplicate /O w, $(GetDataFolder(-1)+WNameStr)
EndFor
SetDataFolder OldDF
End

Function pt_SaveWFrmFldrs()
// use to save individual waves as IgorBinary or convert to DelimitedText

String  DataWaveMatchStr, HDDataFldrPathW, SaveAsType
String WList, WNameStr, SaveNewWaveAs
Variable Numwaves, i 

Wave /T ParNamesW	=$("root:FuncParWaves:pt_SaveWFrmFldrs"+"ParNamesW")
Wave /T ParW		=$("root:FuncParWaves:pt_SaveWFrmFldrs"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_SaveWFrmFldrsParW and/or pt_SaveWFrmFldrsParNamesW!!!"
EndIf

DataWaveMatchStr			=ParW[0]
HDDataFldrPathW			=ParW[1]
SaveAsType					=ParW[2]	// IgorBinary, DelimitedText 09/19/14

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))

Numwaves=ItemsInList(WList)

For (i=0; i<Numwaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w = $(WNameStr)
	StrSwitch(SaveAsType)	
	
		Case "IgorBinary":
			SaveNewWaveAs=HDDataFldrPathW + ":" + WNameStr+".ibw"
			Save /O w as SaveNewWaveAs
		Break
		
		Case "DelimitedText":
			SaveNewWaveAs=HDDataFldrPathW + ":" + WNameStr+".txt"
			Save /O/J w as SaveNewWaveAs
		Break
		
		Default:
			Abort "Wrong SaveAsType or not yet implemented. No wave saved!"
	EndSwitch

EndFor
Print "Saved N=",i, "waves to folder", HDDataFldrPathW
Print WList
End


Function pt_DisplayWFrmFldrs()
String DataWaveMatchStr, XWaveMatchStr
Variable WindowNameIsFldrName
String WList, WListX, WNameStr, WNameStrX, TraceNameStr
Variable XWavePresent, Numwaves, NumwavesX, i

Wave /T ParNamesW		=$("root:FuncParWaves:pt_DisplayWFrmFldrs"+"ParNamesW")
Wave /T ParW			=$("root:FuncParWaves:pt_DisplayWFrmFldrs"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves pt_DisplayWFrmFldrsParW and/or pt_DisplayWFrmFldrsParNamesW!!!"
EndIf

//DestFolderName		=ParW[0]
DataWaveMatchStr		=ParW[0]
WindowNameIsFldrName	=Str2Num(ParW[1])
XWaveMatchStr			=ParW[2]
//DestWNameStr			=ParW[2]

If (Strlen(XWaveMatchStr)!=0)
	XWavePresent=1
EndIf


PrintAnalPar("pt_DisplayWFrmFldrs")

//NewDataFolder /O $(DestFolderName)
//SuffixStr= GetDataFolder(0)

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")

If (XWavePresent)
	WListX=pt_SortWavesInFolder(XWaveMatchStr, GetDataFolder(-1))
	NumwavesX=ItemsInList(WList, ";")
EndIf	

If (!XWavePresent)

Print "Displaying waves, N =", Numwaves, WList

For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$WNameStr
//	DestWNameStr=DestFolderName+":"+SuffixStr+WNameStr //DestWNames[i+1]
	If (i==0)
		Display $WNameStr 				//$DestWNameStr
//		Print WNameStr
		If (WindowNameIsFldrName)
			DoWindow /C/F $GetDataFolder(0)	//(SuffixStr+DestWNames[i+1])
			TraceNameStr=WNameStr 
			SetAxis		 /W=$GetDataFolder(0)	/A left //0,.1
			Legend		 /W=$GetDataFolder(0) 	/A=RT/C/N=Text0/F=0
			ModifyGraph	 /W=$GetDataFolder(0)	rgb($TraceNameStr)=(65280,43520,0)	
		EndIf	
	Else
		If (WindowNameIsFldrName)
			AppendToGraph /W=$GetDataFolder(0) $WNameStr
//			Print WNameStr
			TraceNameStr=WNameStr 
			SetAxis		 /W=$GetDataFolder(0)	/A left //0,.1
			Legend		 /W=$GetDataFolder(0) 	/A=RT/C/N=Text0/F=0
			ModifyGraph	 /W=$GetDataFolder(0)	rgb($TraceNameStr)=(65280,43520,0)
		Else
			AppendToGraph $WNameStr	
//			Print WNameStr
		EndIf	
	EndIf
EndFor
Else
	If (NumwavesX==Numwaves)
		Print "Displaying waves, N =", Numwaves
	For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	WNameStrX=StringFromList(i, WListX, ";")
	Wave w=$WNameStr
	Wave wX=$WNameStrX
//	DestWNameStr=DestFolderName+":"+SuffixStr+WNameStr //DestWNames[i+1]
	If (i==0)
		Display $WNameStr 	vs 	wX		//$DestWNameStr
		Print WNameStr, WNameStrX
		If (WindowNameIsFldrName)
			DoWindow /C/F $GetDataFolder(0)	//(SuffixStr+DestWNames[i+1])
			TraceNameStr=WNameStr 
			SetAxis		 /W=$GetDataFolder(0)	/A left //0,.1
			Legend		 /W=$GetDataFolder(0) 	/A=RT/C/N=Text0/F=0
			ModifyGraph	 /W=$GetDataFolder(0)	rgb($TraceNameStr)=(65280,43520,0)	
		EndIf	
	Else
		If (WindowNameIsFldrName)
			AppendToGraph /W=$GetDataFolder(0) $WNameStr vs wX
			Print WNameStr, WNameStrX
			TraceNameStr=WNameStr 
			SetAxis		 /W=$GetDataFolder(0)	/A left //0,.1
			Legend		 /W=$GetDataFolder(0) 	/A=RT/C/N=Text0/F=0
			ModifyGraph	 /W=$GetDataFolder(0)	rgb($TraceNameStr)=(65280,43520,0)
		Else
			AppendToGraph $WNameStr vs wX	
			Print WNameStr, WNameStrX
		EndIf	
	EndIf
	EndFor
	Else
	Abort "Num of X waves different than Y Waves"	
	EndIF
EndIF

//KillWaves wOrig
End

Function pt_DisplayWavesVarPar1()

Display /k=1
AppendToGraph /C=(65535,43690,0) root:Anal:mIPSC:Joint:ACSFContra:ACSFContraRsVAvg
AppendToGraph /C=(65535,0,0) root:Anal:mIPSC:Joint:ACSFIpsi:ACSFIpsiRsVAvg
AppendToGraph /C=(16385,49025,65535) root:Anal:mIPSC:Joint:TTXContra:TTXContraRsVAvg
AppendToGraph /C=(1,16019,65535) root:Anal:mIPSC:Joint:TTXIpsi:TTXIpsiRsVAvg
Legend/C/N=text0/F=0/A=RT

Display /k=1
AppendToGraph /C=(65535,43690,0) root:Anal:mIPSC:Joint:ACSFContra:ACSFContraRInVAvg
AppendToGraph /C=(65535,0,0) root:Anal:mIPSC:Joint:ACSFIpsi:ACSFIpsiRInVAvg
AppendToGraph /C=(16385,49025,65535) root:Anal:mIPSC:Joint:TTXContra:TTXContraRInVAvg
AppendToGraph /C=(1,16019,65535) root:Anal:mIPSC:Joint:TTXIpsi:TTXIpsiRInVAvg
Legend/C/N=text0/F=0/A=RT

Display /k=1
AppendToGraph /C=(65535,43690,0) root:Anal:mIPSC:Joint:ACSFContra:ACSFContraCmVAvg
AppendToGraph /C=(65535,0,0) root:Anal:mIPSC:Joint:ACSFIpsi:ACSFIpsiCmVAvg
AppendToGraph /C=(16385,49025,65535) root:Anal:mIPSC:Joint:TTXContra:TTXContraCmVAvg
AppendToGraph /C=(1,16019,65535) root:Anal:mIPSC:Joint:TTXIpsi:TTXIpsiCmVAvg
Legend/C/N=text0/F=0/A=RT

Display /k=1
AppendToGraph /C=(65535,43690,0) root:Anal:mIPSC:Joint:ACSFContra:ACSFContraRelPkAmpAvg
AppendToGraph /C=(65535,0,0) root:Anal:mIPSC:Joint:ACSFIpsi:ACSFIpsiRelPkAmpAvg
AppendToGraph /C=(16385,49025,65535) root:Anal:mIPSC:Joint:TTXContra:TTXContraRelPkAmpAvg
AppendToGraph /C=(1,16019,65535) root:Anal:mIPSC:Joint:TTXIpsi:TTXIpsiRelPkAmpAvg
Legend/C/N=text0/F=0/A=RT

Display /k=1
AppendToGraph /C=(65535,43690,0) root:Anal:mIPSC:Joint:ACSFContra:ACSFContraPkInstFrqAvg
AppendToGraph /C=(65535,0,0) root:Anal:mIPSC:Joint:ACSFIpsi:ACSFIpsiPkInstFrqAvg
AppendToGraph /C=(16385,49025,65535) root:Anal:mIPSC:Joint:TTXContra:TTXContraPkInstFrqAvg
AppendToGraph /C=(1,16019,65535) root:Anal:mIPSC:Joint:TTXIpsi:TTXIpsiPkInstFrqAvg
Legend/C/N=text0/F=0/A=RT

Display /k=1
AppendToGraph /C=(65535,43690,0) root:Anal:mIPSC:Joint:ACSFContra:ACSFContraTauDAvg
AppendToGraph /C=(65535,0,0) root:Anal:mIPSC:Joint:ACSFIpsi:ACSFIpsiTauDAvg
AppendToGraph /C=(16385,49025,65535) root:Anal:mIPSC:Joint:TTXContra:TTXContraTauDAvg
AppendToGraph /C=(1,16019,65535) root:Anal:mIPSC:Joint:TTXIpsi:TTXIpsiTauDAvg
Legend/C/N=text0/F=0/A=RT


//Display /k=1
//AppendToGraph /C=(65535,43690,0) root:Anal:SpontSpk:HetFs:HetFsSpontSpkFrqAvg
//AppendToGraph /C=(65535,0,0) root:Anal:SpontSpk:HetPyram:HetPyramSpontSpkFrqAvg
//AppendToGraph /C=(16385,49025,65535) root:Anal:SpontSpk:KOFs:KOFsSpontSpkFrqAvg
//AppendToGraph /C=(1,16019,65535) root:Anal:SpontSpk:KOPyram:KOPyramSpontSpkFrqAvg
//Legend/C/N=text0/F=0/A=RT

//Display /k=1
//AppendToGraph /C=(65535,43690,0) root:Anal:mIPSC:P14:Het:P14HetCmVAvg
//AppendToGraph /C=(65535,0,0) root:Anal:mIPSC:P14:KO:P14KOCmVAvg
//AppendToGraph /C=(16385,49025,65535) root:Anal:mIPSC:P24:Het:P24HetCmVAvg
//AppendToGraph /C=(1,16019,65535) root:Anal:mIPSC:P24:KO:P24KOCmVAvg
//Legend/C/N=text0/F=0/A=RT

End

Function pt_AppendWToGraph()

//added color option // 11/18/13
// Adapted from pt_DisplayWFrmFldrs 	30th sept. 2007

String DataWaveMatchStr, GraphWinName, XWaveMatchStr, RGBList
Variable NWaves	
String WList, WListX, WNameStr, TraceNameStr, WNameStrX
Variable XWavePresent, Numwaves, NumwavesX, i, pt_Red=0, pt_Green=0, pt_Blue=0

Wave /T ParNamesW		=$("root:FuncParWaves:pt_AppendWToGraph"+"ParNamesW")
Wave /T ParW			=$("root:FuncParWaves:pt_AppendWToGraph"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves pt_AppendWToGraphParW and/or pt_AppendWToGraphParNamesW!!!"
EndIf

DataWaveMatchStr		=ParW[0]
GraphWinName			=ParW[1]	
NWaves					=Str2Num(ParW[2])	// Append 1st N waves; -1 for all waves
XWaveMatchStr			=ParW[3]
RGBList					=ParW[4]		// 11/18/13

if (!StringMatch(RGBList, ""))
	pt_Red 	= Str2Num(StringFromList(0, RGBList, ";"))
	pt_Green = Str2Num(StringFromList(1, RGBList, ";"))
	pt_Blue 	= Str2Num(StringFromList(2, RGBList, ";"))
EndIF

If (Strlen(XWaveMatchStr)!=0)
	XWavePresent=1
EndIf

PrintAnalPar("pt_AppendWToGraph")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")
NumWaves = (NWaves == -1) ? NumWaves : NWaves

If (XWavePresent)
	WListX=pt_SortWavesInFolder(XWaveMatchStr, GetDataFolder(-1))
	NumwavesX=ItemsInList(WList, ";")
	NumWavesX = (NWaves == -1) ? NumWavesX : NWaves
EndIf	

If (!XWavePresent)

Print "Appending waves, N =", Numwaves, WList
DoWindow $GraphWinName
If (V_Flag)
		DoWindow /F $GraphWinName
Else
		Display
		DoWindow /C/F $GraphWinName		
EndIf

For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$WNameStr
			AppendToGraph /W=$GraphWinName $WNameStr
//			Print WNameStr
			TraceNameStr=WNameStr 
			SetAxis		 /W=$GraphWinName	/A left //0,.1
			Legend		 /W=$GraphWinName 	/A=RT/C/N=Text0/F=0
			ModifyGraph	 /W=$GraphWinName	rgb($TraceNameStr)=(pt_Red, pt_Green, pt_Blue)
EndFor
Else
	If (NumwavesX==Numwaves)
		Print "Appending waves, N =", Numwaves
	DoWindow  $GraphWinName
	If (V_Flag)
		DoWindow /F $GraphWinName
	Else
		Display
		DoWindow /C/F $GraphWinName	
	EndIf
	For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	WNameStrX=StringFromList(i, WListX, ";")
	Wave w=$WNameStr
	Wave wX=$WNameStrX
			AppendToGraph /W=$GraphWinName $WNameStr vs wX
			Print WNameStr, WNameStrX
			TraceNameStr=WNameStr 
			SetAxis		 /W=$GraphWinName	/A left //0,.1
			Legend		 /W=$GraphWinName 	/A=RT/C/N=Text0/F=0
			ModifyGraph	 /W=$GraphWinName	rgb($TraceNameStr)=(pt_Red, pt_Green, pt_Blue)
	EndFor	
	Else	
		Abort "Num of X waves different than Y Waves"	
	EndIF
EndIf	
End


Function pt_EditWFrmFldrs()
// 
// TO LOAD PRE-EXISTING WAVES WITH DATA FOLDER PREFIX SET MATCHSTR TO *MATCHSTR //10/07/13 
// Modified to add prefix, so that it is not added by default. 09/25/13
// Modifying so that the waves are created if no matching waves 08_30_12
// Modifying so that instead of separate tables from each cell, the matched waves are attached to the same table. This will prevent creating a lot of tables.  12/09/2010
// Adapted from pt_DisplayWFrmFldrs. maybe the two can be recombined. 


String DataWaveMatchStr, XWaveMatchStr
Variable WindowNameIsFldrName
String WList, WListX, WNameStr, WNameStrX, TraceNameStr, LastUpdatedMM_DD_YYYY="12_09_2010", ColTitle, Prefix
Variable XWavePresent, Numwaves, NumwavesX, i, CreateIfMissing, IsTextWave, SetColTitle=0

Wave /T ParNamesW		=$("root:FuncParWaves:pt_EditWFrmFldrs"+"ParNamesW")
Wave /T ParW			=$("root:FuncParWaves:pt_EditWFrmFldrs"+"ParW")

Print "*********************************************************"
Print "pt_EditWFrmFldrs last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves pt_EditWFrmFldrsParW and/or pt_EditWFrmFldrsParNamesW!!!"
EndIf

//DestFolderName		=ParW[0]
DataWaveMatchStr		=ParW[0]
WindowNameIsFldrName	=Str2Num(ParW[1])	// THIS OPTION IS NO LONGER USED. ALL WAVES ARE ATTACHED TO THE SAME TABLE.  12/09/2010
XWaveMatchStr			=ParW[2]
IsTextWave				=Str2Num(ParW[3]) 
CreateIfMissing			=Str2Num(ParW[4])
// if making waves with same names and using Perfix = "", set ColTitle = "DataFldrName"	
ColTitle				=ParW[5]
// to make or edit waves with same names across folders, Prefix = ""
// to make or edit waves with DataFldrName as prefix, Prefix = "DataFldrName"
// if Prefix = "XYZ", all waves will be created or edited with XYZ as prefix
Prefix				= ParW[6]		

//If (StringMatch(ColTitle,"")!=1)
//	SetColTitle =1
	If (StringMatch(ColTitle,"DataFldrName")==1)
		ColTitle=GetDataFolder(0)
		SetColTitle =1
	EndIf
//EndIf

If (StringMatch(Prefix, "DataFldrName"))
	Prefix = GetDataFolder(0)
EndIf

//DestWNameStr			=ParW[2]

If (Strlen(XWaveMatchStr)!=0)
	XWavePresent=1
EndIf


PrintAnalPar("pt_EditWFrmFldrs")

//NewDataFolder /O $(DestFolderName)
//SuffixStr= GetDataFolder(0)

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")
If (NumWaves==0)
	If (IsTextWave==0)
		//Make/O/N=0 $GetDataFolder(0)+DataWaveMatchStr
		Make/O/N=0 $Prefix+DataWaveMatchStr
	Else
		//Make/O/N=0/T $GetDataFolder(0)+DataWaveMatchStr	
		Make/O/N=0/T $Prefix+DataWaveMatchStr	
	EndIf	
	WList=pt_SortWavesInFolder(Prefix + DataWaveMatchStr, GetDataFolder(-1))
	Numwaves=ItemsInList(WList, ";")
EndIf

If (XWavePresent)
	WListX=pt_SortWavesInFolder(XWaveMatchStr, GetDataFolder(-1))
	NumwavesX=ItemsInList(WList, ";")
EndIf	


DoWindow pt_EditWFrmFldrsTable
If (V_FLag)
DoWIndow /F pt_EditWFrmFldrsTable
Else
Edit /K=1
DoWIndow /C pt_EditWFrmFldrsTable
EndIf

If (!XWavePresent)

Print "Editing waves, N =", Numwaves, WList

For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	If (IsTextWave==0)
		Wave w=$WNameStr
		AppendToTable /W= pt_EditWFrmFldrsTable w
		If (SetColTitle)
			ModifyTable /W= pt_EditWFrmFldrsTable title($WNameStr)=ColTitle
		EndIf	
	Else
		Wave /T wT=$WNameStr
		AppendToTable /W= pt_EditWFrmFldrsTable wT
		If (SetColTitle)
			ModifyTable /W= pt_EditWFrmFldrsTable title($WNameStr)=ColTitle
		EndIf	
	EndIf	
	
//	If (i==0)
//		Edit $WNameStr 				//$DestWNameStr
//		If (WindowNameIsFldrName)
//			DoWindow /C/F $GetDataFolder(0)	//(SuffixStr+DestWNames[i+1])
//		EndIf	
//	Else
//		If (WindowNameIsFldrName)
//			AppendToTable /W=$GetDataFolder(0) $WNameStr
//		Else
//			AppendToTable $WNameStr	
//		EndIf	
//	EndIf
EndFor
Else
	If (NumwavesX==Numwaves)
		Print "Editing waves, N =", Numwaves
	For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	WNameStrX=StringFromList(i, WListX, ";")
	Wave w=$WNameStr
	Wave wX=$WNameStrX
	AppendToTable /W=pt_EditWFrmFldrsTable wX, $WNameStr
	If (SetColTitle)
			ModifyTable /W= pt_EditWFrmFldrsTable title($WNameStr)=ColTitle
		EndIf	
//	If (i==0)
//		Edit wX, $WNameStr		//$DestWNameStr
//		Print WNameStr, WNameStrX
//		If (WindowNameIsFldrName)
//			DoWindow /C/F $GetDataFolder(0)	//(SuffixStr+DestWNames[i+1])
//		EndIf	
//	Else
//		If (WindowNameIsFldrName)
//			AppendToTable /W=$GetDataFolder(0) wX, $WNameStr
	//		Print WNameStr, WNameStrX
//		Else
//			AppendToTable wX, $WNameStr
//			Print WNameStr, WNameStrX
//		EndIf	
//	EndIf
	EndFor
	Else
	Abort "Num of X waves different than Y Waves"	
	EndIF
EndIF

//KillWaves wOrig
End

Function pt_EditWAuto()
//  Idea is to automatically edit parameter waves in a data folders based on certain conditions
//eg. the value of parameters can depend on whether the cell is control or expt. 
String DataWaveMatchStr, SubFldr
Variable PntNum

SVAR /Z LCategory = Category
If (!SVAR_Exists(LCategory))
Print "Warning  - Category variable doesn't exist. No Wave edited "
Return -1
Else
Print GetDataFolder(0), LCategory
EndIf

String WList, WNameStr
Variable i, NumWaves
String LastUpdatedMM_DD_YYYY="09_23_2011"



Print "*********************************************************"
Print "pt_EditWAuto last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


//Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_SynRespAnal"+"ParNamesW")
//Wave /T AnalParW			=	$("root:FuncParWaves:pt_SynRespAnal"+"ParW")
//If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
//	Abort	"Cudn't find the parameter wave pt_SynRespAnalParW!!!"
//EndIf


Wave /T AnalParNamesW	=	$pt_GetParWave("pt_EditWAuto", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_EditWAuto", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_EditWAutoParW and/or pt_EditWAutoParNamesW!!!"
EndIf

																		
DataWaveMatchStr		=	AnalParW[0]
SubFldr					= 	AnalParW[1]
PntNum					= 	Str2Num(AnalParW[2])


PrintAnalPar("pt_EditWAuto")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
Numwaves=ItemsInList(WList, ";")

Print "Editing Waves, N =", Numwaves, WList

For (i=0; i<NumWaves; i+=1) 
WNameStr=StringFromList(i, WList, ";")
Wave /T  w=$(GetDataFolder(1)+SubFldr+WNameStr)
// Define condtitions and change value

StrSwitch (LCategory)
	
	Case "SalIpsi":
//	w[PntNum] = "-4.4e-11"
	w[PntNum] = "1.8e-11"
	Break
	
	Case "SalContra":
//	w[PntNum] = "+inf"
	w[PntNum] = ""
	Break
	
	Case "TTXIpsi":
//	w[PntNum] = "-4.4e-11"
	w[PntNum] = "1.8e-11"
	Break
	
	Case "TTXContra":
//	w[PntNum] = "-4.4e-11"
	w[PntNum] = "1.8e-11"
	Break
	
	
EndSwitch

EndFor


End


Function pt_CompareWFrmFldrs()
// Adapted from pt_DisplayWFrmFldrs

String DataWaveMatchStr
Variable WindowNameIsFldrName
String WList, WNameStr, W1NameStr, LastUpdatedMM_DD_YYYY="04_04_2007"
Variable NumWaves, N,N1, i, j, WavesAreDiff=0

Wave /T ParNamesW		=$("root:FuncParWaves:pt_CompareWFrmFldrs"+"ParNamesW")
Wave /T ParW			=$("root:FuncParWaves:pt_CompareWFrmFldrs"+"ParW")

Print "*********************************************************"
Print "pt_CompareWFrmFldrs last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves pt_CompareWFrmFldrsParW and/or pt_CompareWFrmFldrsParNamesW!!!"
EndIf

//DestFolderName		=ParW[0]
DataWaveMatchStr		=ParW[0]
WindowNameIsFldrName	=Str2Num(ParW[1])


PrintAnalPar("pt_CompareWFrmFldrs")


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")

Print "Comparing waves, N =", Numwaves, WList

WNameStr=StringFromList(0, WList, ";")

If (StrLen(WNameStr)!=0)
	Wave w=$WNameStr
	N=NumPnts(w)
Else
	Print "No matching waves found"
	Return 1
EndIf

For (i=1; i<NumWaves; i+=1) 

	W1NameStr=StringFromList(i, WList, ";")
	Wave w1=$W1NameStr
	N1=NumPnts(w1)
	
	If (N==N1)
		For (j=0; j<N; j+=1)
			If (  NumType(w[j])*NumType(w1[j]) ==0  )
			If (w[j] != w1[j])
				Print "Waves are different", WNameStr, W1NameStr, "Pnt. #", j
				WavesAreDiff=1
				Break
			EndIf
			EndIf
		EndFor
	Else
		Print "Waves have different num. of pnts.", WNameStr, W1NameStr, "NumPnts.",N, N1
		WavesAreDiff=1
	EndIf
	If (!WavesAreDiff)
		Print "Waves are same"
	EndIf	
EndFor

End



Function pt_DuplicateWFrmFldrs()

// This is always the latest version
// modified to use subfolder 08/28/2010
// Implemented duplication within a range using XStartVal, XEndVal
String WList, WNameStr, OrigWNameStr, DestFolderName, DataWaveMatchStr, PrefixStr, SuffixStr, SubFldr//, DestWNameStr
Variable XStartVal, XEndVal
String TraceNameStr, DestWNameStr, OldPrefixStr="", LastUpdatedMM_DD_YYYY = "08_28_2010"
Variable Numwaves, i, PrefixStrChanged=0

Wave /T AnalParNamesW		=$("root:FuncParWaves:pt_DuplicateWFrmFldrs"+"ParNamesW")
Wave /T AnalParW			=$("root:FuncParWaves:pt_DuplicateWFrmFldrs"+"ParW")

//Print "*********************************************************"
//Print "pt_EditWFrmFldrs last updated on", LastUpdatedMM_DD_YYYY
//Print "*********************************************************"

Print "*********************************************************"
Print "pt_DuplicateWFrmFldrs last updated on", LastUpdatedMM_DD_YYYY	// wrong print message 09/29/2008
Print "*********************************************************"

If (WaveExists(AnalParNamesW)&&WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves pt_DuplicateWFrmFldrsParW and/or pt_DuplicateWFrmFldrsParNamesW!!!"
EndIf

DestFolderName			=AnalParW[0]
DataWaveMatchStr		=AnalParW[1]
PrefixStr				=AnalParW[2]
SuffixStr				=AnalParW[3]
XStartVal				=Str2Num(AnalParW[4])
XEndVal					=Str2Num(AnalParW[5])
SubFldr					= AnalParW[6]
//DestWNameStr			=ParW[2]


PrintAnalPar("pt_DuplicateWFrmFldrs")

NewDataFolder /O $(DestFolderName)
If (StringMatch(PrefixStr, "DataFldrName"))
	OldPrefixStr=PrefixStr
	PrefixStr= GetDataFolder(0)
	PrefixStrChanged=1
EndIf

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
Numwaves=ItemsInList(WList, ";")

Print "Duplicating waves, N =", Numwaves, WList

XStartVal= (XStartVal<0)?	-inf : XStartVal	// Implemented duplication within a range using XStartVal, XEndVal
XEndVal=   (XEndVal<0)?  inf : XEndVal

For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$(GetDataFolder(1)+SubFldr+WNameStr)
	DestWNameStr=DestFolderName+":"+PrefixStr+WNameStr+SuffixStr //DestWNames[i+1]
	Duplicate /O/R=(XStartVal, XEndVal) w, $DestWNameStr
//	Duplicate /O/R=(0,99) w, $DestWNameStr	
EndFor 
If (PrefixStrChanged==1)
	PrefixStr=OldPrefixStr
	OldPrefixStr=""
EndIf
//KillWaves wOrig
End

Function pt_DuplicateWRnd()
String WList, WNameStr, OrigWNameStr, DestFolderName, DataWaveMatchStr, PrefixStr, SuffixStr//, DestWNameStr
Variable NumRnd
String TraceNameStr, DestWNameStr, OldPrefixStr=""
Variable Numwaves, i, PrefixStrChanged=0

Wave /T AnalParNamesW		=$("root:FuncParWaves:pt_DuplicateWRnd"+"ParNamesW")
Wave /T AnalParW			=$("root:FuncParWaves:pt_DuplicateWRnd"+"ParW")

If (WaveExists(AnalParNamesW)&&WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves pt_DuplicateWRndParW and/or pt_DuplicateWRndParNamesW!!!"
EndIf

DestFolderName			=AnalParW[0]
DataWaveMatchStr		=AnalParW[1]
PrefixStr					=AnalParW[2]
SuffixStr					=AnalParW[3]
NumRnd					=Str2Num(AnalParW[4])	
//DestWNameStr			=ParW[2]


PrintAnalPar("pt_DuplicateWRnd")

NewDataFolder /O $(DestFolderName)
If (StringMatch(PrefixStr, "DataFldrName"))
	OldPrefixStr=PrefixStr
	PrefixStr= GetDataFolder(0)
	PrefixStrChanged=1
EndIf

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")

Print "RANDOMLY Duplicating", NumRnd, "waves, out of N =", Numwaves, WList
Make /O/N=(Numwaves) RndIndexW
RndIndexW = p
edit RndIndexW
DoWindow /C RndIndexWWin
pt_randomselect(NumRnd)
DoWindow /K RndIndexWWin
Wave RndIndexW_Rnd=RndIndexW_Rnd
RndIndexW=RndIndexW_Rnd
KillWaves RndIndexW_Rnd

For (i=0; i<NumRnd; i+=1) 
	WNameStr=StringFromList(RndIndexW[i], WList, ";")
	Wave w=$WNameStr
	DestWNameStr=DestFolderName+":"+PrefixStr+WNameStr+SuffixStr //DestWNames[i+1]
	Duplicate /O w, $DestWNameStr
EndFor 
If (PrefixStrChanged==1)
	PrefixStr=OldPrefixStr
	OldPrefixStr=""
EndIf
//KillWaves wOrig
KillWaves RndIndexW
End




Function pt_DuplicateWToFldrs()
String WList, WNameStr, OrigWNameStr, SourceFolderName, DataWaveMatchStr, PrefixStr, SuffixStr//, DestWNameStr
String TraceNameStr, DestWNameStr, OldPrefixStr=""
Variable Numwaves, i, PrefixStrChanged=0

Wave /T AnalParNamesW		=$("root:FuncParWaves:pt_DuplicateWToFldrs"+"ParNamesW")
Wave /T AnalParW			=$("root:FuncParWaves:pt_DuplicateWToFldrs"+"ParW")

If (WaveExists(AnalParNamesW)&&WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves pt_DuplicateWToFldrsParW and/or pt_DuplicateWToFldrsParNamesW!!!"
EndIf

SourceFolderName			=AnalParW[0]
DataWaveMatchStr			=AnalParW[1]
PrefixStr						=AnalParW[2]
SuffixStr						=AnalParW[3]
//DestWNameStr				=ParW[2]


PrintAnalPar("pt_DuplicateWToFldrs")

//If (StringMatch(PrefixStr, "DataFldrName"))
//	OldPrefixStr=PrefixStr
//	PrefixStr= SourceFolderName
//	PrefixStrChanged=1
//EndIf

If (StringMatch(PrefixStr, "DataFldrName"))
	OldPrefixStr=PrefixStr
	PrefixStr= GetDataFolder(0)
	PrefixStrChanged=1
EndIf


WList=pt_SortWavesInFolder(DataWaveMatchStr, SourceFolderName)
Numwaves=ItemsInList(WList, ";")

Print "Duplicating waves, N =", Numwaves, WList


For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$SourceFolderName+":"+WNameStr
	DestWNameStr=GetDataFolder(-1)+PrefixStr+WNameStr+SuffixStr //DestWNames[i+1]
	If (WaveExists($DestWNameStr))
		DoAlert 1, "Wave already exists!! Overwrite=Yes; Don't overwrite=No"
		If (V_flag==1)
			Duplicate /O w, $DestWNameStr
		Else
			Print "Wave not overwritten"
		EndIf
	Else
		Duplicate w, $DestWNameStr
	EndIf	
EndFor 
//If (PrefixStrChanged==1)
//	PrefixStr=OldPrefixStr
//	OldPrefixStr=""
//EndIf

If (PrefixStrChanged==1)
	PrefixStr=OldPrefixStr
	OldPrefixStr=""
EndIf
//KillWaves wOrig
End




Function pt_SortW()
String DataWaveMatchStr, SortKeyWName, SuffixStr //, DestWNameStr
String DestWNameStr, WList, WNameStr
Variable Numwaves, i

Wave /T ParNamesW		=$("root:FuncParWaves:pt_SortW"+"ParNamesW")
Wave /T ParW	=$("root:FuncParWaves:pt_SortW"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves pt_SortWParW and/or pt_SortWParNamesW!!!"
EndIf

DataWaveMatchStr		=ParW[0]
SortKeyWName			=ParW[1]
SuffixStr					=ParW[2]

PrintAnalPar("pt_SortW")


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")

Print "Sorting waves, N =", Numwaves, WList


Wave SortKeyW=$SortKeyWName

For (i=0; i<NumWaves; i+=1) 

	WNameStr=StringFromList(i, WList, ";")
	Wave w=$WNameStr
//	DestWNameStr=WNameStr+"_"+SuffixStr //DestWNames[i+1]
	DestWNameStr=WNameStr+SuffixStr //DestWNames[i+1]
	If (!StringMatch(DestWNameStr, WNameStr))
		Duplicate /O w, $DestWNameStr
	EndIf	
	If (Strlen(SortKeyWName)==0)
		Sort $DestWNameStr, $DestWNameStr
	Else
		Sort SortKeyW, $DestWNameStr
	EndIf	
	Display $DestWNameStr
EndFor 
//KillWaves wOrig
End



Function pt_CalHistTCrs()
String DataWaveMatchStr, WList, WNameStr, DestBaseNameStr
Variable Numwaves, i, j 
Variable StartX, DelX, StartBin, BinWidth, NumBins, NHist, x1,x2

Wave /T HistTCrsParW			=$("root:FuncParWaves:pt_CalHistTCrs"+"ParW")

If (WaveExists(HistTCrsParW) == 0)
	Abort	"Cudn't find the parameter waves pt_CalHistTCrsParW !!!"
EndIf

DataWaveMatchStr		=		   HistTCrsParW[0]
DestBaseNameStr		=		   HistTCrsParW[1]
StartX					=Str2Num(HistTCrsParW[2])
DelX					=Str2Num(HistTCrsParW[3])
BinWidth				=Str2Num(HistTCrsParW[4])	
NumBins				=Str2Num(HistTCrsParW[5])	


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Numwaves=ItemsInList(WList, ";")
For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$WNameStr
	NHist=Round(NumPnts(w)/DelX)
	x1=StartX; x2=x1+DelX-1
	For (j=0; j<NHist; j+=1)
		Make /O/D/N=(NumBins) $(DestBaseNameStr+Num2Str(x1)+"_"+Num2Str(x2)+"_Hist")
		Wave w1=$(DestBaseNameStr+Num2Str(x1)+"_"+Num2Str(x2)+"_Hist")
		Histogram /R=(x1, x2) /B={StartX, BinWidth, NumBins} w, w1
		x1+=DelX; x2=x1+DelX-1
	EndFor	
EndFor
End

Function pt_TextFrmNotebook(NB, FormatStr, StrW)
// pt_TextFrmNotebook("NoteBook0"," Initializing Board  %s ", "TxtStore")

// NB 	= NoteBookName
// StrW 	= Name of text wave to store strings
String NB, FormatStr, StrW
String ScanStr, Str
Variable p=0

Make /T/O/N=0 $StrW
Make /T/O/N=1 $(StrW+"_Tmp")

Wave  /T WTxt		=$StrW
Wave /T WTxtTmp	=$(StrW+"_Tmp")
Do
	Notebook $NB, Selection={(p,0), (p,0)}
	If (V_Flag)
		break
	EndIf
	Notebook $NB selection={startOfParagraph, endOfChars}
	GetSelection notebook, $NB, 2		// Get the selected text
	ScanStr = S_Selection
	If (strlen(ScanStr) > 0)
		SScanf	ScanStr, FormatStr, Str
		If	(strlen(Str) > 0)
			WTxtTmp[0]=Str
			Concatenate /NP/T {WTxtTmp}, WTxt
		EndIf
	EndIf
	p+=1
While (1)
Print "Found", NumPnts(WTxt), "matches for", FormatStr, " in", NB
KillWaves WTxtTmp
End

Function pt_CalPeak()
// modified to have polarity = 0. Polarity is determined by average during the PeakWin compared to baseline Useful when the peak can be max or min. 03/27/13
// Eg. synaptic response vs voltage
// For displaying analyzed pars use pt_SpikeAnalDisplay
// 	VhBLY;VhPeakAbsY;VhSSAbsY		X-ParList
// 	VhBLX;VhPeakX;VhSSX 				Y-ParList

// This is always the latest version
// modified - removed identification of data as FI 12/22/11
// inserted the smoothing option. default option is binomial smoothing. 9th sept. 2007
// look for par waves in local folder first 	07/23/2007
//// in pt_AnalWInFldrs2("pt_CalPeak") changed the loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function.	 07/23/2007
// also check if ParNamesW is present		07/23/2007
//PrintAnalPar("pt_CalPeak")    07/18/2007
// in pt_AnalWInFldrs2("pt_CalPeak") applied If ( StrLen(AnalParW[11])*StrLen(AnalParW[12])!=0)
// before loading FIWNamesW, etc. 07/18/2007
// also killing WNameTemp at the end    07/18/2007
//	removed ":". should be included with data fldr		06/13/2007


String WNameStr, WList, DataWaveMatchStr, DataFldrStr, BaseNameStr

Variable PeakWinStart, PeakWinEnd, AvgWin, BLStart, BLEnd, SteadyStateStart, SteadyStateEnd, PeakPolarity, SmoothPnts//, DisplayAnal//, FIData


Variable i, Numwaves, j, X0, dx, LambdaW, BLVal, PeakPolarityOrig

String LastUpdatedMM_DD_YYYY=" 09/27/2007"

Print "*********************************************************"
Print "pt_CalPeak last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalPeak", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW				=	$pt_GetParWave("pt_CalPeak", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_CalPeakParW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
BaseNameStr			=	AnalParW[2]
BLStart			 		= 	Str2Num(AnalParW[3]);
BLEnd					=	Str2Num(AnalParW[4]); 
PeakWinStart			=	Str2Num(AnalParW[5]);
PeakWinEnd			=	Str2Num(AnalParW[6]);
AvgWin					=	Str2Num(AnalParW[7]);
SteadyStateStart		= 	Str2Num(AnalParW[8]);
SteadyStateEnd			=	Str2Num(AnalParW[9]); 
PeakPolarity			=	Str2Num(AnalParW[10]);
SmoothPnts				= 	Str2Num(AnalParW[11]);
//DisplayAnal				= 	Str2Num(AnalParW[12])		

//If (		NumPnts(AnalParW) >=14 && NumPnts(AnalParNamesW) >=14		)// 04/26/2010; before refereing a wave index, always check the wavelength. 
//If ( StrLen(AnalParW[12])*StrLen(AnalParW[13])!=0)
//print StrLen(AnalParW[12]), StrLen(AnalParW[13])
//	Wave /T FIWNamesW		=	$(GetDataFolder(-1)+DataFldrStr+":"+AnalParW[12])	//	removed ":". should be included with data fldr		06/13/2007
//	Wave     FICurrWave		=	$(GetDataFolder(-1)+DataFldrStr+":"+AnalParW[13])	//	removed ":". should be included with data fldr		06/13/2007
//	Wave /T FIWNamesW		=	$(GetDataFolder(-1)+DataFldrStr+AnalParW[12])		
//	Wave     FICurrWave		=	$(GetDataFolder(-1)+DataFldrStr+AnalParW[13])
//	FIData=1
//Else
//	FIData=0
//EndIf
//EndIf

PrintAnalPar("pt_CalPeak")	// 07/18/2007

//***************
Make /O/N=0 	$(BaseNameStr+"BLX")
Make /O/N=0 	$(BaseNameStr+"BLY")

Make /O/N=0 	$(BaseNameStr+"PeakX")
Make /O/N=0 	$(BaseNameStr+"PeakAbsY")
Make /O/N=0 	$(BaseNameStr+"PeakRelY")

Make /O/N=0 	$(BaseNameStr+"SSX")
Make /O/N=0 	$(BaseNameStr+"SSAbsY")	// SteadyState Y (absolute)
Make /O/N=0 	$(BaseNameStr+"SSRelY")	// SteadyState Y (relative)
	
Make /O/N=0 	$(BaseNameStr+"PeakRelSSY")		// peak measured from steady state
//***************

Make /O/N=1 	$(BaseNameStr+"BLXTemp")
Make /O/N=1 	$(BaseNameStr+"BLYTemp")

Make /O/N=1 	$(BaseNameStr+"PeakXTemp")
Make /O/N=1 	$(BaseNameStr+"PeakAbsYTemp")
Make /O/N=1 	$(BaseNameStr+"PeakRelYTemp")

Make /O/N=1 	$(BaseNameStr+"SSXTemp")
Make /O/N=1 	$(BaseNameStr+"SSAbsYTemp")	// SteadyState Y (absolute)
Make /O/N=1 	$(BaseNameStr+"SSRelYTemp")	// SteadyState Y (relative)
	
Make /O/N=1 	$(BaseNameStr+"PeakRelSSYTemp")		// peak measured from steady state

//***************

Wave wBLX			=	$(BaseNameStr+"BLX")
Wave wBLY			=	$(BaseNameStr+"BLY")

Wave wPeakX		=	$(BaseNameStr+"PeakX")
Wave wPeakAbsY	=	$(BaseNameStr+"PeakAbsY")
Wave wPeakRelY	=	$(BaseNameStr+"PeakRelY")

Wave wSSX			=	$(BaseNameStr+"SSX")
Wave wSSAbsY		=	$(BaseNameStr+"SSAbsY")
Wave wSSRelY		=	$(BaseNameStr+"SSRelY")

Wave wPeakRelSSY	=	$(BaseNameStr+"PeakRelSSY")

//***************

Wave wBLXTemp			=	$(BaseNameStr+"BLXTemp")
Wave wBLYTemp			=	$(BaseNameStr+"BLYTemp")

Wave wPeakXTemp			=	$(BaseNameStr+"PeakXTemp")
Wave wPeakAbsYTemp		=	$(BaseNameStr+"PeakAbsYTemp")
Wave wPeakRelYTemp		=	$(BaseNameStr+"PeakRelYTemp")

Wave wSSXTemp			=	$(BaseNameStr+"SSXTemp")
Wave wSSAbsYTemp			=	$(BaseNameStr+"SSAbsYTemp")
Wave wSSRelYTemp			=	$(BaseNameStr+"SSRelYTemp")

Wave wPeakRelSSYTemp	=	$(BaseNameStr+"PeakRelSSYTemp")
//***************


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

Print "Calculating peak for waves, N =", Numwaves, WList

//If (DisplayAnal ==1)
//Display
//DoWindow pt_CalPeakDisplay
//	If (V_Flag)
//		DoWindow /F pt_CalPeakDisplay
//		Sleep 00:00:02
//		DoWindow /K pt_CalPeakDisplay
//	EndIf
//DoWindow /c pt_CalPeakDisplay
//EndIf


For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
//	WNameTemp[0]=WNameStr
//	If (FIData)
//		For (j=0; j<NumPnts(FIWNamesW); j+=1)
//			If (StringMatch(FIWNamesW[j],WNameStr))
//				Print j, WNameStr, FICurrWave[j]
//				wParTemp[0]=FICurrWave[j]
//				Concatenate /NP 	   {wParTemp}, wPar
//				break
//				print "Couldn't find", WNameStr, "in",AnalParW[11]
//			EndIf
//		EndFor
//	EndIf
//	Concatenate /T/NP {WNameTemp}, WName
//	Wave w= $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr)
	Wave w= $(GetDataFolder(1)+DataFldrStr+WNameStr)
	x0=DimOffset(w,0); dx=DimDelta(w,0)
	LambdaW=x0+(NumPnts(w))*dx
//	display w
	
	Wavestats /Q /R=(BLStart, BLEnd) w
	wBLXTemp[0]=BLStart+0.5*(BLEnd-BLStart)
	wBLXTemp[0]+=i*LambdaW
	wBLYTemp[0]=V_Avg
	
	
	Duplicate /O w, w_sm							// inserted the smoothing option. default option is binomial smoothing. 9th sept. 2007
	Smooth SmoothPnts, w_sm
	Wavestats /Q /R=(PeakWinStart, PeakWinEnd) w_sm
	KillWaves w_sm
//Polarity is determined by average during the PeakWin compared to baseline Useful when the peak can be max or min. 03/27/13	
	PeakPolarityOrig = PeakPolarity	// 01/24/14
	If (PeakPolarity ==0) // polarity deter
		//PeakPolarityOrig = PeakPolarity	// 01/24/14
		PeakPolarity = (V_Avg >= wBLYTemp[0]) ? 1 : -1
		Print "Avg during peak window =", V_Avg, "BL =", wBLYTemp[0], "Peak polarity =", PeakPolarity
	EndIf
		
	wPeakXTemp[0]	= (PeakPolarity==1) ? V_MaxLoc : V_MinLoc
	wPeakXTemp[0]	+=i*LambdaW
	wPeakAbsYTemp[0] = (PeakPolarity==1) ? mean(w, V_MaxLoc-0.5*AvgWin, V_MaxLoc+0.5*AvgWin) : mean(w, V_MinLoc-0.5*AvgWin, V_MinLoc+0.5*AvgWin)
	
	wPeakRelYTemp[0]	= wPeakAbsYTemp[0] - wBLYTemp[0]

	Wavestats /Q /R=(SteadyStateStart, SteadyStateEnd) w
	
	wSSXTemp[0] 		=	SteadyStateStart +0.5*(SteadyStateEnd- SteadyStateStart)
	wSSXTemp[0]	    +=i*LambdaW
	wSSAbsYTemp[0]	=	V_Avg	
	wSSRelYTemp[0]	=	wSSAbsYTemp[0] - wBLYTemp[0]
		
	wPeakRelSSYTemp[0] = wPeakAbsYTemp[0] - wSSAbsYTemp[0]
	
	Concatenate /NP {wBLXTemp}		, wBLX
	Concatenate /NP {wBLYTemp}		, wBLY
	
	Concatenate /NP {wPeakXTemp}		, wPeakX
	Concatenate /NP {wPeakAbsYTemp}	, wPeakAbsY
	Concatenate /NP {wPeakRelYTemp}	, wPeakRelY

	Concatenate /NP {wSSXTemp}		, wSSX
	Concatenate /NP {wSSAbsYTemp}	, wSSAbsY
	Concatenate /NP {wSSRelYTemp}	, wSSRelY
	
	Concatenate /NP {wPeakRelSSYTemp}, wPeakRelSSY
	
	//AppendToGraph /W=pt_CalPeakDisplay w
	//AppendToGraph /W=pt_CalPeakDisplay wBLYTemp vs wBLXTemp
	//String TraceNameStr
	//TraceNameStr = "wBLYTemp"
	//ModifyGraph mode($TraceNameStr)=3
	//ModifyGraph marker($TraceNameStr)=1
	//ModifyGraph rgb($TraceNameStr)=(0,0,0)
	//AppendToGraph /W=pt_CalPeakDisplay wPeakAbsYTemp vs wPeakXTemp
	//ModifyGraph mode($TraceNameStr)=3
	//ModifyGraph marker($TraceNameStr)=i
	//ModifyGraph rgb($TraceNameStr)=(0,0,0)
	//DoUpdate
	
	//DoWindow pt_CalPeakDisplay
	//If (V_Flag)
	//DoWindow /F pt_CalPeakDisplay
	//Sleep 00:00:02
	//DoWindow /K pt_CalPeakDisplay
	//EndIf
		
	PeakPolarity = PeakPolarityOrig
		
EndFor

	
Killwaves /Z wBLXTemp, wBLYTemp, wPeakXTemp , wPeakAbsYTemp, wPeakRelYTemp, wSSXTemp, wSSAbsYTemp, wSSRelYTemp, wPeakRelSSYTemp//, wParTemp, WNameTemp	 // 07/18/2007
End


Function pt_CalSynResp()
// Based on pt_CalPeak()

// This is always the latest version
// RelPkY was being calculated wrong. corrected 11/01/12



String WNameStr, WList, DataWaveMatchStr, DataFldrStr, BaseNameStr, PkWinStart0List

Variable PkWinStart0, PkWinDel, BLDel, AvgWin, ThreshVal, SmthPnts, PkPolr, NStepsPerStim, StepsPerStimDelT, NStims


Variable i, Numwaves, j, X0,PkWinStart, k

String LastUpdatedMM_DD_YYYY=" 11/01/2012"

Print "*********************************************************"
Print "pt_CalSynResp last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_CalSynResp", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW			=	$pt_GetParWave("pt_CalSynResp", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_CalSynRespParW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
BaseNameStr			=	AnalParW[2]
PkWinStart0List			=	AnalParW[3]
PkWinDel				=	Str2Num(AnalParW[4]);
BLDel			 		= 	Str2Num(AnalParW[5]);
AvgWin					= 	Str2Num(AnalParW[6]);
ThreshVal				= 	Str2Num(AnalParW[7]);
NStepsPerStim			= 	Str2Num(AnalParW[8]);
StepsPerStimDelT		= 	Str2Num(AnalParW[9]);
SmthPnts				= 	Str2Num(AnalParW[10]);
PkPolr					=	Str2Num(AnalParW[11]);



PrintAnalPar("pt_CalSynResp")	// 07/18/2007

Print "Analyzing folder", Getdatafolder(1)

NStims = ItemsInList(PkWinStart0List, ";")
Make /O/N=(NStims), $(BaseNameStr+"PkWinStart0W")
Wave PkWinStart0W=$(BaseNameStr+"PkWinStart0W")
PkWinStart0W = Str2Num(StringFromList(p,PkWinStart0List, ";")	)

For (k=0;k<NStims; k+=1)		// Stim #

Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+"BLX")
Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+"BLY")
Wave BLX		= $(BaseNameStr+Num2Str(k)+"_"+"BLX")
Wave BLY		= $(BaseNameStr+Num2Str(k)+"_"+"BLY")

EndFor

Make /O/N=1 	$(BaseNameStr+"BLXTemp")
Make /O/N=1 	$(BaseNameStr+"BLYTemp")
Wave BLXTemp	= $(BaseNameStr+"BLXTemp")
Wave BLYTemp	= $(BaseNameStr+"BLYTemp")

For (k=0;k<NStims; k+=1)		// Stim #
For (j=0;j<NStepsPerStim; j+=1)	// Step # (Multiple steps in a stim)

Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"PkX")
Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"AbsPkY")
Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"RelPkY")
Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"Boln")		

EndFor
EndFor

Make /O/N=1 		$(BaseNameStr+"PkXTemp")
Make /O/N=1 		$(BaseNameStr+"AbsPkYTemp")
Make /O/N=1 		$(BaseNameStr+"RelPkYTemp")
Make /O/N=1 		$(BaseNameStr+"BolnTemp")		
Wave PkXTemp		= $(BaseNameStr+"PkXTemp")
Wave AbsPkYTemp	= $(BaseNameStr+"AbsPkYTemp")
Wave RelPkYTemp	= $(BaseNameStr+"RelPkYTemp")
Wave BolnTemp		= $(BaseNameStr+"BolnTemp")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

Print "Calculating synaptic response for waves, N =", Numwaves, WList


For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")


	Wave w= $(GetDataFolder(1)+DataFldrStr+WNameStr)
//	x0=DimOffset(w,0); dx=DimDelta(w,0)
//	LambdaW=x0+(NumPnts(w))*dx
//	display w
	For (k=0;k<NStims; k+=1)		// Stim #
	PkWinStart0 = PkWinStart0W[k]
	Wavestats /Q /R=(PkWinStart0-BLDel, PkWinStart0) w	// BL before 1st response
	BLYTemp[0]=V_Avg
	BLXTemp[0]=PkWinStart0-0.5*BLDel
	
	Duplicate /O w, w_sm							// inserted the smoothing option. default option is binomial smoothing. 9th sept. 2007
	Smooth SmthPnts, w_sm
	
	For (j=0;j<NStepsPerStim; j+=1)
	PkWinStart = PkWinStart0+j*StepsPerStimDelT
	
	Wavestats /Q /R=(PkWinStart, PkWinStart+PkWinDel) w_sm
	PkXTemp[0]	= (PkPolr==1) ? V_MaxLoc : V_MinLoc
//	wXTemp[0]	+=i*LambdaW
	
	If (PkPolr==1)
	WaveStats /Q/R=(V_MaxLoc-0.5*AvgWin, V_MaxLoc+0.5*AvgWin) w
	Else
	WaveStats /Q/R=(V_MinLoc-0.5*AvgWin, V_MinLoc+0.5*AvgWin) w
	EndIf

	AbsPkYTemp[0] = V_Avg
	RelPkYTemp[0]	= AbsPkYTemp[0]- BLYTemp[0]//BLXTemp[0] 11/01/12
	
	BolnTemp = (abs(RelPkYTemp[0]) >= abs(ThreshVal) ) ? 1 : 0
	
	Wave PkX		= $(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"PkX")
	Wave AbsPkY	= $(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"AbsPkY")
	Wave RelPkY	= $(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"RelPkY")
	Wave Boln		= $(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"Boln")
	
	Concatenate /NP {BLXTemp}			, BLX
	Concatenate /NP {BLYTemp}			, BLY
	Concatenate /NP {PkXTemp}			, PkX
	Concatenate /NP {AbsPkYTemp}		, AbsPkY
	Concatenate /NP {RelPkYTemp}		, RelPkY
	Concatenate /NP {BolnTemp}			, Boln
	
	EndFor
	EndFor
	KillWaves /Z w_sm
		
EndFor		
Killwaves /Z BLXTemp, BLYTemp, PkXTemp, AbsPkYTemp, RelPkYTemp, BolnTemp,PkWinStart0W// 07/18/2007
End

Function pt_DisplayFIData()
Display	$GetDataFolder(0)
AppendToGraph FIPeakAbsY		vs 	FIPeakX
AppendToGraph FISpkBLAvgY		vs 	FISpkBLAvgX
AppendToGraph FISpikeThreshY	vs 	FISpikeThreshX
AppendToGraph FIFracPAbsY		vs 	FILFracPX
AppendToGraph FIFracPAbsY		vs	 FIRFracPX
AppendToGraph FIAHPAbsY		vs 	FIAHPX
AppendToGraph FIEOPAHPAbsY 	vs 	FIEOPAHPX
ModifyGraph mode(FIPeakAbsY)=3,mode(FISpkBLAvgY)=3,mode(FISpikeThreshY)=3
ModifyGraph mode(FIFracPAbsY)=3,mode(FIFracPAbsY#1)=3,mode(FIAHPAbsY)=3
ModifyGraph mode(FIEOPAHPAbsY)=3
ModifyGraph rgb(FIPeakAbsY)=(0,15872,65280),rgb(FISpkBLAvgY)=(0,15872,65280);DelayUpdate
ModifyGraph rgb(FISpikeThreshY)=(0,15872,65280),rgb(FIFracPAbsY)=(0,15872,65280);DelayUpdate
ModifyGraph rgb(FIFracPAbsY#1)=(0,15872,65280),rgb(FIAHPAbsY)=(0,15872,65280);DelayUpdate
ModifyGraph rgb(FIEOPAHPAbsY)=(0,15872,65280)
setaxis bottom 0.8, 2
End

Function /S pt_GetParWave(AnalFunc, ParDescripStr)	// ParDescripStr=ParNamesW OR ParW
String AnalFunc, ParDescripStr

If ( WaveExists($AnalFunc+ParDescripStr) )
	Print "***Found", AnalFunc+ParDescripStr, GetDataFolder(-1), "***"
	Return GetDataFolder(-1) +AnalFunc + ParDescripStr

ElseIf ( WaveExists($"root:FuncParWaves:"+AnalFunc+ParDescripStr) )
	
	Return "root:FuncParWaves:"+AnalFunc+ParDescripStr

Else

	Abort	"Cudn't find the parameter waves"+  AnalFunc+ ParDescripStr

EndIf

End




Function PrintAnalPar(AnalFunc)
String AnalFunc
Variable i

Print "Analysis parameters"
Print "****************************************************************************************"
Wave /T AnalParW			=  		$pt_GetParWave(AnalFunc, "ParW")
If (WaveExists($AnalFunc+"ParNamesW") || WaveExists($"root:FuncParWaves:"+AnalFunc+"ParNamesW")) // ok if names wave doesn't exist 04/10/14
	Wave /T AnalParNamesW		=		$pt_GetParWave(AnalFunc, "ParNamesW")
EndIf

//Print "Analysis parameters"
//Print "****************************************************************************************"
i=0
Do
	If (i>=NumPnts(AnalParW))
		Break
	Else
		If (WaveExists($AnalFunc+"ParNamesW") || WaveExists($"root:FuncParWaves:"+AnalFunc+"ParNamesW"))  // ok if names wave doesn't exist 04/10/14
	 		Print AnalParNamesW[i], "=", AnalParW[i]
	 	Else
	 		Print "Analsyis pars", i , AnalParW[i]
	 	EndIf
	 EndIf	
	 i+=1
While (1)
Print "****************************************************************************************"
End

Function/S pt_ExcludeFromWList(ExcludeWNamesWStr, WList)
String ExcludeWNamesWStr, WList
String NewWList, ExcludeWList, WStr
Variable Overwrite, N, i 
NewWList=WList
If (!StringMatch(ExcludeWNamesWStr, "") && WaveExists($ExcludeWNamesWStr))
	Wave /T w=$ExcludeWNamesWStr
	N=NumPnts(w)
	ExcludeWList=""
	For (i=0; i<N; i+=1)
		WStr=w[i]
		ExcludeWList     +=ListMatch(NewWList, WStr, ";")
		NewWList		=ListMatch(NewWList, "!"+WStr, ";")
	EndFor
	Print "**Excluded Waves:** N=",ItemsInList(ExcludeWList, ";"), ExcludeWList
Else
	Print "ExcludeWNamesWStr or the Exclude wave is empty. No waves Excluded"
EndIf	
Return NewWList
End


Function pt_MoveWaves()
// modified to accept cell names without asterisk 10/15/13
String	DataWaveMatchStrsW, DataWaveMatchStr, DestFolderName

String	WList, WNameStr
Variable	Numwaves, i, j, NumDataWaveMatchStrs


Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_MoveWaves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_MoveWaves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_MoveWaves!!!"
EndIf

PrintAnalPar("pt_MoveWaves")

DataWaveMatchStrsW	=	AnalParW[0]
DestFolderName			=	AnalParW[1]
DestFolderName			+= ":"

Wave /T wNames = $DataWaveMatchStrsW

NumDataWaveMatchStrs=NumPnts(wNames)

	For (j=0; j<NumDataWaveMatchStrs; j+=1)
		DataWaveMatchStr	=	wNames[j]

		WList=pt_SortWavesInFolder(DataWaveMatchStr+"*", GetDataFolder(-1))
		Numwaves=ItemsInList(WList, ";")

		Print "Moving waves, N =", Numwaves, WList

	For (i=0; i<NumWaves; i+=1) 
		WNameStr=StringFromList(i, WList, ";") 
		Wave w=$WNameStr
		MoveWave w, $DestFolderName
	EndFor 
	
	EndFor

End

Function pt_MoveWavesMany()
// To specify multiple waves and destination folders
// modified to accept cell names without asterisk 10/15/13
String	ListDataWaveMatchStrsW, ListDestFolderName
Variable Overwrite

String		WList, WNameStr,DataWaveMatchStr, DestFolderName
Variable	NListItems, Numwaves, i, j,k, NumDataWaveMatchStrs


Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_MoveWavesMany!!!"
EndIf

PrintAnalPar("pt_MoveWavesMany")

ListDataWaveMatchStrsW	=	AnalParW[0]	// semicolon seperated list of multiple waves
ListDestFolderName			=	AnalParW[1]	// semicolon seperated list of multiple folders
//DestFolderName			+= ":"
Overwrite					=	Str2Num(AnalParW[2])	// if yes, then duplicate /O will be used.

If (ItemsInList(ListDataWaveMatchStrsW,";")!=ItemsInList(ListDestFolderName, ";"))
Abort "In pt_MoveWavesManyMany the numbers of items in ListDataWaveMatchStrsW and ListDestFolderName are not equal! "
Else
NListItems= ItemsInList(ListDataWaveMatchStrsW,";")
EndIf

For (k=0; k<NListItems; k+=1)
	Wave /T wNames = $StringFromList(k,ListDataWaveMatchStrsW, ";")
	DestFolderName   = StringFromList(k,ListDestFolderName, ";")+":"
	NumDataWaveMatchStrs=NumPnts(wNames)

	For (j=0; j<NumDataWaveMatchStrs; j+=1)
		DataWaveMatchStr	=	wNames[j]
		
		//WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
		WList=pt_SortWavesInFolder(DataWaveMatchStr+"*", GetDataFolder(-1))
		Numwaves=ItemsInList(WList, ";")

		Print "Moving waves, N =", Numwaves, WList

	For (i=0; i<NumWaves; i+=1) 
		WNameStr=StringFromList(i, WList, ";") 
		Wave w=$WNameStr
		If (!Overwrite)
		MoveWave w, $DestFolderName
		Else
		Duplicate /O w,$(DestFolderName+WNameStr)
		KillWaves /Z w
		EndIf
	EndFor 
	
	EndFor
EndFor


End

Function pt_MoveWavesVarPar1()
// Wrapper for pt_MoveWaves	
String OldDataWaveMatchStrsW, OldDestFolderName

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MoveWaves"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_MoveWaves"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_MoveWaves!!!"
EndIf

OldDataWaveMatchStrsW	=	AnalParW[0]
OldDestFolderName			=	AnalParW[1]

AnalParW[0] = "root:Anal:mIPSC:Joint:ACSFIpsiContra:ACSFIpsiContraCellName"
AnalParW[1] = "root:Anal:mIPSC:Joint:ACSFIpsiContra"
pt_MoveWaves()

//AnalParW[0] = "root:Anal:mIpsc:Joint:ACSFIpsi:ACSFIpsiCellName"
//AnalParW[1] = "root:Anal:mIpsc:Joint:ACSFIpsi"
//pt_MoveWaves()

AnalParW[0] = "root:Anal:mIPSC:Joint:TTXIpsiContra:TTXIpsiContraCellName"
AnalParW[1] = "root:Anal:mIPSC:Joint:TTXIpsiContra"
pt_MoveWaves()

//AnalParW[0] = "root:Anal:mIpsc:Joint:TTXIpsi:TTXIpsiCellName"
//AnalParW[1] = "root:Anal:mIpsc:Joint:TTXIpsi"
//pt_MoveWaves()

//AnalParW[0] = "root:Anal:SpontBurst:HetFs:HetFsCellName"
//AnalParW[1] = "root:Anal:SpontBurst:HetFs"
//pt_MoveWaves()

//AnalParW[0] = "root:Anal:SpontBurst:HetPyram:HetPyramCellName"
//AnalParW[1] = "root:Anal:SpontBurst:HetPyram"
//pt_MoveWaves()

//AnalParW[0] = "root:Anal:SpontBurst:KOFs:KOFsCellName"
//AnalParW[1] = "root:Anal:SpontBurst:KOFs"
//pt_MoveWaves()

//AnalParW[0] = "root:Anal:SpontBurst:KOPyram:KOPyramCellName"
//AnalParW[1] = "root:Anal:SpontBurst:KOPyram"
//pt_MoveWaves()

//AnalParW[0] = "root:Anal:mIPSC:P14:Het:P14HetCellName"
//AnalParW[1] = "root:Anal:mIPSC:P14:Het"
//pt_MoveWaves()

//AnalParW[0] = "root:Anal:mIPSC:P14:KO:P14KOCellName"
//AnalParW[1] = "root:Anal:mIPSC:P14:KO"
//pt_MoveWaves()

//AnalParW[0] = "root:Anal:mIPSC:p24:Het:p24HetCellName"
//AnalParW[1] = "root:Anal:mIPSC:p24:Het"
//pt_MoveWaves()

//AnalParW[0] = "root:Anal:mIPSC:p24:KO:p24KOCellName"
//AnalParW[1] = "root:Anal:mIPSC:p24:KO"
//pt_MoveWaves()

AnalParW[0]	= OldDataWaveMatchStrsW
AnalParW[1] = OldDestFolderName
End

// function to subtract leak-current from base and drug IV curves
Function pt_Tmp()
Variable IVSlope, IVIntercept
Duplicate /O BaseSSAvg BaseILeak; Duplicate /O Drug1SSAvg Drug1ILeak; 
Make /O/N=1 BaseSSLeakGin; 
pt_LinearFit(BaseSSAvg,4,6,IVSlope, IVIntercept)
Print IVSlope, IVIntercept
//BaseSSLeakGin[0]=(BaseILeak[4]-BaseILeak[5])/(10e-3) 
BaseSSLeakGin[0]=-IVSlope*1e2
Make /O/N=1 Drug1SSLeakGin; 
pt_LinearFit(Drug1SSAvg,4,6,IVSlope, IVIntercept)
Print IVSlope, IVIntercept
//Drug1SSLeakGin[0]=(Drug1ILeak[4]-Drug1ILeak[5])/(10e-3)  
Drug1SSLeakGin[0]=-IVSlope*1e2
Wave BaseSSAvg=BaseSSAvg
BaseILeak = BaseSSAvg[6]+BaseSSLeakGin[0]*10e-3*(6-p) 
Wave Drug1SSAvg=Drug1SSAvg
Drug1ILeak = Drug1SSAvg[6]+Drug1SSLeakGin[0]*10e-3*(6-p) 
Display Drug1SSAvg,BaseSSAvg,BaseILeak,Drug1ILeak
ModifyGraph rgb(Drug1SSAvg)=(0,15872,65280),rgb(Drug1ILeak)=(0,15872,65280)
Duplicate /O BaseSSAvg BaseSSAvgNL; Duplicate /O Drug1SSAvg Drug1SSAvgNL;  
BaseSSAvgNL -=BaseILeak; Drug1SSAvgNL -=Drug1ILeak  
Duplicate /O BaseSSAvgNL, Im1SSAvgNL; Im1SSAvgNL-=Drug1SSAvgNL;  
Display Im1SSAvgNL
End

// a function to scale waves (praveen)
Function pt_ScaleWaves1(MatchStrW, MultiplicFactor)
//Example: pt_ScaleWaves("Cell_002138_*", 1e12)
String MatchStrW
Variable MultiplicFactor
String WList, WNameStr
Variable i, N
WList=wavelist(MatchStrW,";","")
N=ItemsInList(wList,";")
For (i=0; i<N; i+=1)
	WNameStr=StringFromList(i, Wlist, ";")
	wave w=$WNameStr
	w=w*MultiplicFactor
EndFor
Print "Multiplied N=",N,"waves with",MultiplicFactor
End


Function pt_CurveFitOutData()

// append the fit values to a wave

Make /O/N=0 InterceptTmp, SlopeTmp

pt_CurveFit()



End

// fit a curve.
Function pt_CurveFit()

// !!!!!!!!CAUTION: THE EXECUTE FUNCTION DOES NOT SET THE V_FITERROR ON ERROR!!!!!!!. EVEN IF THE FIT FAILS THE COEFFS AND SIG VALS ARE ACCEPTED IN THIS FUNC



// DataFldrStr was not being used. fixed that. Some functions using pt_CurveFir may be broken (04_20_12)
// not yet modified for XWavePresent

// modified the fitting to Y waves. mainly made the fit wave name based on the data wave so that it's not overwritten	11/23/2008
// set initial fitW =Nan in XY wave fitting 11/23/2008
// modifying to curvefit XY waves: forks in the begining to previous Y wave fitting or newer XY wave fitting 11/21/2008
// This is always the latest version
// default fit parameters =Nan 11/19/2008
// modified to output the W_Coef , W_Sigma  10/20//2008


String DataWaveMatchStr, DataFldrStr, IgorFitFuncName, XDataWaveMatchStr
Variable StartXVal, EndXVal, DisplayFit 

String WList, XWList, CurveFitStr, WNameStr, XWNameStr, x1S,x2S, TraceNameStr
Variable N,i,x1,x2, XWavePresent

Variable V_FitOptions =4 // suppresses progree window of curve fit
Variable V_FitError =0    // Prevents abort on error. Error in fitting sets bit 0 and some error also set higher bits. 
// Execute /z prevents errors from execute. 

String LastUpdatedMM_DD_YYYY="10_20_2008"

Print "*********************************************************"
Print "pt_CurveFit last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParW=$pt_GetParWave("pt_CurveFit", "ParW")

PrintAnalPar("pt_CurveFit")

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
IgorFitFuncName		=	AnalParW[2]
StartXVal				=Str2Num(AnalParW[3])
EndXVal					=Str2Num(AnalParW[4])
DisplayFit				=Str2Num(AnalParW[5])
XDataWaveMatchStr		=	AnalParW[6]

If (StringMatch(XDataWaveMatchStr, ""))
	XWavePresent =0
Else
	XWavePresent = 1
EndIf

//DoAlert 0, "Temporarily holding y0=-60e-3 for exp. fit"
//Variable /G K0=-60e-3


If (XWavePresent ==0)

//WList	=wavelist(DataWaveMatchStr,";","")
WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+DataFldrStr)	//(04_20_12)
N		=ItemsInList(wList,";")

For (i=0; i<N; i+=1)
	WNameStr=StringFromList(i, Wlist, ";")
	wave w=$(GetDataFolder(1)+DataFldrStr+WNameStr)	//(04_20_12)
	x1=X2Pnt(w,StartXVal)
	x2=X2Pnt(w,EndXVal)
//	x1S=Num2Str(x1)
//	x2S=Num2Str(x2)
	Print "CurveFit range, x=", StartXVal, "to", EndXVal
	Duplicate /O/R=[x1,x2] w, $(GetDataFolder(1)+DataFldrStr+"w_FtRng")
	Wave w_FtRng= $(GetDataFolder(1)+DataFldrStr+"w_FtRng")
	
If (DisplayFit	)
	Display
	DoWindow pt_CurveFitDisplay
	If (V_Flag)
		DoWindow /F pt_CurveFitDisplay
//		Sleep 00:00:02
		DoWindow /K pt_CurveFitDisplay
	EndIf
	DoWindow /C pt_CurveFitDisplay
	AppendToGraph /W=pt_CurveFitDisplay w
	TraceNameStr=WNameStr
	ModifyGraph /W=pt_CurveFitDisplay rgb($TraceNameStr)=(65280,0,0)
	AppendToGraph /W=pt_CurveFitDisplay w_FtRng
	TraceNameStr="w_FtRng"
	ModifyGraph /W=pt_CurveFitDisplay rgb($TraceNameStr)=(0,0,0)
	DoUpdate
//	Sleep /T 120
EndIf	
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ DataWaveMatchStr +"["+X1S+","+X2S+"] /D "
	Duplicate /O w_FtRng, $(GetDataFolder(1)+DataFldrStr+"fit_"+WNameStr)
	Wave FitW=$(GetDataFolder(1)+DataFldrStr+"fit_"+WNameStr)
	FitW=Nan
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ WNameStr +" "+"["+X1S+","+X2S+"]  "+" "+"/D=fit_"+WNameStr

//	Print "###################################"
//	Print "Temporarily holding y0=-60e-3 for exp. fit"
//	Print "###################################"
	CurveFitStr = "CurveFit/Q/NTHR=0/TBOX=0/W=2"+" "+ IgorFitFuncName+ " "+ GetDataFolder(1)+DataFldrStr+"w_FtRng" +" "+"/D="+GetDataFolder(1)+DataFldrStr+"fit_"+WNameStr
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0/H=\"100\""+" "+ IgorFitFuncName+ " "+ "w_FtRng" +" "+"/D=fit_"+WNameStr
	Print CurveFitStr
	Execute  CurveFitStr
	Wave CoefW= W_Coef 
	Wave SigW = W_Sigma
	Make /O /N=(NumPnts(CoefW)) $(GetDataFolder(1)+DataFldrStr+"Cof"+WNameStr), $(GetDataFolder(1)+DataFldrStr+"Sig"+WNameStr)  
	Wave w1 = $(GetDataFolder(1)+DataFldrStr+"Cof"+WNameStr)      // modified to output the W_Coef , W_Sigma  10/20//2008
	Wave w2 = $(GetDataFolder(1)+DataFldrStr+"Sig"+WNameStr)
	w1 = Nan; w2 =Nan	// default fit parameters =Nan 11/19/2008
	If (V_FitError!=0)
	V_FitError=0
	Print "Fitting error in", WNameStr,". Coeff and Sigma set = NAN"
	Else
	w1= CoefW
	w2= SigW
	EndIf
	If (DisplayFit	)
	AppendToGraph FitW
	ModifyGraph /W=pt_CurveFitDisplay lsize=2
	TraceNameStr="fit_"+WNameStr
	ModifyGraph /W=pt_CurveFitDisplay rgb($TraceNameStr)=(0,43520,65280)
	DoUpdate
	Sleep /T 60
	EndIf 
EndFor
//If (DisplayFit	)
//	AppendToGraph FitW
//	ModifyGraph /W=pt_CurveFitDisplay lsize=2
//	TraceNameStr="fit_"+WNameStr
//	ModifyGraph /W=pt_CurveFitDisplay rgb($TraceNameStr)=(0,43520,65280)
//	DoUpdate
//	Sleep /T 120
//EndIf
	KillWaves /z w_FtRng
Else	// XWavePresent

WList	=wavelist(DataWaveMatchStr,";","")
N		=ItemsInList(wList,";")

XWList	=wavelist(XDataWaveMatchStr,";","")

// check number of X and Y waves is same

If (N!=ItemsInList(XWList,";"))
	Abort "Unequal number of XY waves in pt_CurveFit"
EndIf

For (i=0; i<N; i+=1)
	WNameStr	=StringFromList(i, Wlist, ";")
	XWNameStr	=StringFromList(i, XWlist, ";")
	wave w=$WNameStr
	wave wX=$XWNameStr
	Duplicate /O w, $("w_Srt")
	Duplicate /O wX, $("wX_Srt")
	Wave w_Srt=w_Srt
	Wave wX_Srt=wX_Srt
	Sort wX_Srt, wX_Srt, w_Srt 			
	If (NumPnts(w_Srt )==NumPnts(wX_Srt))
	SetScale /P x,0,1,wX_Srt					
// for fitting to a sub-range, the y-data and x-data shud have equal number of points. therefore we need to duplicate a subrange of y and x wave. duplicate
//range for a wave applies to it's x-scaling or x-index pnts. we want to duplicate subrange of x, y waves based on y-values. so we need to know where
// the y values cross the start and end point. 
				
	Findlevel /Q/P wX_Srt,StartXVal		// bug in igor?? if /Q is not present V_FLag is not set =1 on "level not found"
	
	If (V_flag==1)
		x1=0				
	Else
		x1= Round(V_LevelX)	
	EndIf
	Findlevel /Q/P wX_Srt,EndXVal
	
	If (V_flag==1)
		x2=NumPnts(wX_Srt)-1	
	Else
		x2=Round(V_LevelX)
	EndIf
	
	Print "CurveFit range, x=", wX_Srt(x1), "to", wX_Srt(x2)
	Duplicate /O/R=[x1,x2] w_Srt, w_SrtFtRng
	Duplicate /O/R=[x1,x2] wX_Srt, wX_SrtFtRng
//	x2=X2Pnt(wX,EndXVal)
//	x1S=Num2Str(x1)		
//	x2S=Num2Str(x2)
If (DisplayFit	)
	Display
	DoWindow pt_CurveFitDisplay
	If (V_Flag)
		DoWindow /F pt_CurveFitDisplay
//		Sleep 00:00:02
		DoWindow /K pt_CurveFitDisplay
	EndIf
	DoWindow /C pt_CurveFitDisplay
	AppendToGraph /W=pt_CurveFitDisplay w vs wX
	TraceNameStr=WNameStr
	ModifyGraph /W=pt_CurveFitDisplay rgb($TraceNameStr)=(65280,0,0)
	AppendToGraph /W=pt_CurveFitDisplay w_SrtFtRng vs wX_SrtFtRng
	TraceNameStr="w_SrtFtRng"
	ModifyGraph /W=pt_CurveFitDisplay rgb($TraceNameStr)=(0,0,0)
	DoUpdate
//	Sleep /T 120
EndIf	
// CurveFit/L=221 /X=1/NTHR=0/TBOX=0 exp_XOffset  Wy /X=Wx /D
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ DataWaveMatchStr +"["+X1S+","+X2S+"] /D "
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ "w_SrtFtRng" +" "+"/X="+"wX_SrtFtRng"+" "+"["+X1S+","+X2S+"] /D "
	Duplicate /O w_SrtFtRng, $("fit_"+WNameStr)
	Wave FitW=$("fit_"+WNameStr)
	FitW=Nan					// 11/23/2008
	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ "w_SrtFtRng" +" "+"/X="+"wX_SrtFtRng"+" "+ "/D=fit_"+WNameStr
	Print CurveFitStr
	Execute CurveFitStr
	Wave CoefW= W_Coef 
	Wave SigW = W_Sigma
	Make /O /N=(NumPnts(CoefW)) $("Cof"+WNameStr), $("Sig"+WNameStr)  
	Wave w1 = $("Cof"+WNameStr)      // mdified to output the W_Coef , W_Sigma  10/20//2008
	Wave w2 = $("Sig"+WNameStr)
	w1=Nan; w2=Nan
	w1= CoefW
	w2= SigW
	If (DisplayFit	)
	AppendToGraph FitW vs wX_SrtFtRng
	ModifyGraph /W=pt_CurveFitDisplay lsize=2
	TraceNameStr="fit_"+WNameStr
	ModifyGraph /W=pt_CurveFitDisplay rgb($TraceNameStr)=(0,43520,65280)
	DoUpdate
	Sleep /T 15
	EndIf
	Else
		Print "Number of Pnts in X and Y Wave not equal", WNameStr, "vs", XWNameStr
	EndIf
EndFor
//If (DisplayFit	)
//	AppendToGraph FitW vs wX_SrtFtRng
//	ModifyGraph /W=pt_CurveFitDisplay lsize=2
//	TraceNameStr="fit_"+WNameStr
//	ModifyGraph /W=pt_CurveFitDisplay rgb($TraceNameStr)=(0,43520,65280)
//	DoUpdate
//	Sleep /T 60
//EndIf
EndIf
KillWaves /Z w_Srt, wX_Srt, w_SrtFtRng, wX_SrtFtRng
End		
//********

// fit a curve.
Function pt_CurveFitEdit()
// IMPORTANT - The constant x0 (where the exp has max value is set by Curvefit to start point of data. This affects the estimation of amplitude but not 
// decay time or baseline value - tested this with generating trace with known parameters and noise and fitting it in different data ranges.) 04/10/14.
//ïMake /O/N=10000 raw
//ïSetscale /p x,0,1e-4, raw
//raw = 100+50*exp(-(x-0.1)/50e-3) + 10*gnoise(1)

// modified from pt_curvefit() because THE EXECUTE FUNCTION DOES NOT SET THE V_FITERROR ON ERROR!!!!!!!. EVEN IF THE FIT FAILS THE COEFFS AND SIG VALS ARE ACCEPTED IN THIS FUNC.
// FOR NOW YOU NEED TO EDIT THE PROCEDURE FILE TO EDIT THE FUNCTION YOU WANT TO FIT 04/21/12

// DataFldrStr was not being used. fixed that. Some functions using pt_CurveFir may be broken (04_20_12)
// not yet modified for XWavePresent

// modified the fitting to Y waves. mainly made the fit wave name based on the data wave so that it's not overwritten	11/23/2008
// set initial fitW =Nan in XY wave fitting 11/23/2008
// modifying to curvefit XY waves: forks in the begining to previous Y wave fitting or newer XY wave fitting 11/21/2008
// This is always the latest version
// default fit parameters =Nan 11/19/2008
// modified to output the W_Coef , W_Sigma  10/20//2008


String DataWaveMatchStr, DataFldrStr, IgorFitFuncName, XDataWaveMatchStr
Variable StartXVal, EndXVal, DisplayFit 

String WList, XWList, CurveFitStr, WNameStr, XWNameStr, x1S,x2S, TraceNameStr
Variable N,i,x1,x2, XWavePresent

Variable V_FitOptions =4 // suppresses progree window of curve fit
Variable V_FitError =0    // Prevents abort on error. Error in fitting sets bit 0 and some error also set higher bits. 
// Execute /z prevents errors from execute. 

String LastUpdatedMM_DD_YYYY="04_21_2012"


Print "*********************************************************"
Print "pt_CurveFitEdit last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

//DoAlert 1, "You need to edit the fit function you want to fit in the procedure file. Also pt_CurveFitEdit is not yet debugged for x-wave present case. Continue?"
//If (V_Flag!=1)
//Abort
//EndIf

Wave /T AnalParW=$pt_GetParWave("pt_CurveFitEdit", "ParW")

PrintAnalPar("pt_CurveFitEdit")

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
////IgorFitFuncName		=	AnalParW[2]
StartXVal				=Str2Num(AnalParW[2])
EndXVal					=Str2Num(AnalParW[3])
DisplayFit				=Str2Num(AnalParW[4])
XDataWaveMatchStr		=	AnalParW[5]

If (StringMatch(XDataWaveMatchStr, ""))
	XWavePresent =0
Else
	XWavePresent = 1
EndIf

//DoAlert 0, "Temporarily holding y0=-60e-3 for exp. fit"
//Variable /G K0=-60e-3


If (XWavePresent ==0)

//WList	=wavelist(DataWaveMatchStr,";","")
WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+DataFldrStr)	//(04_20_12)
N		=ItemsInList(wList,";")

For (i=0; i<N; i+=1)
	WNameStr=StringFromList(i, Wlist, ";")
	wave w=$(GetDataFolder(1)+DataFldrStr+WNameStr)	//(04_20_12)
	x1=X2Pnt(w,StartXVal)
	x2=X2Pnt(w,EndXVal)
//	x1S=Num2Str(x1)
//	x2S=Num2Str(x2)
////	Print "CurveFit range, x=", StartXVal, "to", EndXVal
	Duplicate /O/R=[x1,x2] w, $(GetDataFolder(1)+DataFldrStr+"w_FtRng")
	Wave w_FtRng= $(GetDataFolder(1)+DataFldrStr+"w_FtRng")
	
If (DisplayFit	)
	Display
	DoWindow pt_CurveFitEditDisplay
	If (V_Flag)
		DoWindow /F pt_CurveFitEditDisplay
//		Sleep 00:00:02
		DoWindow /K pt_CurveFitEditDisplay
	EndIf
	DoWindow /C pt_CurveFitEditDisplay
	AppendToGraph /W=pt_CurveFitEditDisplay w
	TraceNameStr=WNameStr
	ModifyGraph /W=pt_CurveFitEditDisplay rgb($TraceNameStr)=(65280,0,0)
	AppendToGraph /W=pt_CurveFitEditDisplay w_FtRng
	TraceNameStr="w_FtRng"
	ModifyGraph /W=pt_CurveFitEditDisplay rgb($TraceNameStr)=(0,0,0)
	DoUpdate
//	Sleep /T 120
EndIf	
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ DataWaveMatchStr +"["+X1S+","+X2S+"] /D "
	Duplicate /O w_FtRng, $(GetDataFolder(1)+DataFldrStr+"fit_"+WNameStr)
	Wave FitW=$(GetDataFolder(1)+DataFldrStr+"fit_"+WNameStr)
	FitW=Nan
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ WNameStr +" "+"["+X1S+","+X2S+"]  "+" "+"/D=fit_"+WNameStr

//	Print "###################################"
//	Print "Temporarily holding y0=-60e-3 for exp. fit"
//	Print "###################################"
////	CurveFitStr = "CurveFit/Q/NTHR=0/TBOX=0/W=2"+" "+ IgorFitFuncName+ " "+ GetDataFolder(1)+DataFldrStr+"w_FtRng" +" "+"/D="+GetDataFolder(1)+DataFldrStr+"fit_"+WNameStr
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0/H=\"100\""+" "+ IgorFitFuncName+ " "+ "w_FtRng" +" "+"/D=fit_"+WNameStr
////	Print CurveFitStr
////	Execute  CurveFitStr
	
// edit func in line below to fit a diff func	
//	CurveFit /NTHR=0/TBOX=0/W=2 exp_xOffset w_FtRng /D=FitW
	CurveFit/Q/NTHR=0/TBOX=0/W=2 line w_FtRng /D=FitW
	Wave CoefW= W_Coef 
	Wave SigW = W_Sigma
	Make /O /N=(NumPnts(CoefW)) $(GetDataFolder(1)+DataFldrStr+"Cof"+WNameStr), $(GetDataFolder(1)+DataFldrStr+"Sig"+WNameStr)  
	Wave w1 = $(GetDataFolder(1)+DataFldrStr+"Cof"+WNameStr)      // modified to output the W_Coef , W_Sigma  10/20//2008
	Wave w2 = $(GetDataFolder(1)+DataFldrStr+"Sig"+WNameStr)
	w1 = Nan; w2 =Nan	// default fit parameters =Nan 11/19/2008
	If (V_FitError!=0)
	V_FitError=0
	Print "Fitting error in", WNameStr,". Coeff and Sigma set = NAN"
	Else
	w1= CoefW
	w2= SigW
	EndIf
	If (DisplayFit	)
	AppendToGraph FitW
	ModifyGraph /W=pt_CurveFitEditDisplay lsize=2
	TraceNameStr="fit_"+WNameStr
	ModifyGraph /W=pt_CurveFitEditDisplay rgb($TraceNameStr)=(0,43520,65280)
	DoUpdate
	Sleep /T 60
	EndIf
EndFor
//If (DisplayFit	)
//	AppendToGraph FitW
//	ModifyGraph /W=pt_CurveFitEditDisplay lsize=2
//	TraceNameStr="fit_"+WNameStr
//	ModifyGraph /W=pt_CurveFitEditDisplay rgb($TraceNameStr)=(0,43520,65280)
//	DoUpdate
//	Sleep /T 120
//EndIf
	KillWaves /z w_FtRng
Else	// XWavePresent

WList	=wavelist(DataWaveMatchStr,";","")
N		=ItemsInList(wList,";")

XWList	=wavelist(XDataWaveMatchStr,";","")

// check number of X and Y waves is same

If (N!=ItemsInList(XWList,";"))
	Abort "Unequal number of XY waves in pt_CurveFitEdit"
EndIf

For (i=0; i<N; i+=1)
	WNameStr	=StringFromList(i, Wlist, ";")
	XWNameStr	=StringFromList(i, XWlist, ";")
	wave w=$WNameStr
	wave wX=$XWNameStr
	Duplicate /O w, $("w_Srt")
	Duplicate /O wX, $("wX_Srt")
	Wave w_Srt=w_Srt
	Wave wX_Srt=wX_Srt
	Sort wX_Srt, wX_Srt, w_Srt 			
	If (NumPnts(w_Srt )==NumPnts(wX_Srt))
	SetScale /P x,0,1,wX_Srt					
// for fitting to a sub-range, the y-data and x-data shud have equal number of points. therefore we need to duplicate a subrange of y and x wave. duplicate
//range for a wave applies to it's x-scaling or x-index pnts. we want to duplicate subrange of x, y waves based on y-values. so we need to know where
// the y values cross the start and end point. 
				
	Findlevel /Q/P wX_Srt,StartXVal		// bug in igor?? if /Q is not present V_FLag is not set =1 on "level not found"
	
	If (V_flag==1)
		x1=0				
	Else
		x1= Round(V_LevelX)	
	EndIf
	Findlevel /Q/P wX_Srt,EndXVal
	
	If (V_flag==1)
		x2=NumPnts(wX_Srt)-1	
	Else
		x2=Round(V_LevelX)
	EndIf
	
	Print "CurveFit range, x=", wX_Srt(x1), "to", wX_Srt(x2)
	Duplicate /O/R=[x1,x2] w_Srt, w_SrtFtRng
	Duplicate /O/R=[x1,x2] wX_Srt, wX_SrtFtRng
//	x2=X2Pnt(wX,EndXVal)
//	x1S=Num2Str(x1)		
//	x2S=Num2Str(x2)
If (DisplayFit	)
	Display
	DoWindow pt_CurveFitEditDisplay
	If (V_Flag)
		DoWindow /F pt_CurveFitEditDisplay
//		Sleep 00:00:02
		DoWindow /K pt_CurveFitEditDisplay
	EndIf
	DoWindow /C pt_CurveFitEditDisplay
	AppendToGraph /W=pt_CurveFitEditDisplay w vs wX
	TraceNameStr=WNameStr
	ModifyGraph /W=pt_CurveFitEditDisplay rgb($TraceNameStr)=(65280,0,0)
	AppendToGraph /W=pt_CurveFitEditDisplay w_SrtFtRng vs wX_SrtFtRng
	TraceNameStr="w_SrtFtRng"
	ModifyGraph /W=pt_CurveFitEditDisplay rgb($TraceNameStr)=(0,0,0)
	DoUpdate
//	Sleep /T 120
EndIf	
// CurveFit/L=221 /X=1/NTHR=0/TBOX=0 exp_XOffset  Wy /X=Wx /D
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ DataWaveMatchStr +"["+X1S+","+X2S+"] /D "
//	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ "w_SrtFtRng" +" "+"/X="+"wX_SrtFtRng"+" "+"["+X1S+","+X2S+"] /D "
	Duplicate /O w_SrtFtRng, $("fit_"+WNameStr)
	Wave FitW=$("fit_"+WNameStr)
	FitW=Nan					// 11/23/2008
	CurveFitStr = "CurveFit/NTHR=0/TBOX=0"+" "+ IgorFitFuncName+ " "+ "w_SrtFtRng" +" "+"/X="+"wX_SrtFtRng"+" "+ "/D=fit_"+WNameStr
	Print CurveFitStr
	Execute CurveFitStr
	Wave CoefW= W_Coef 
	Wave SigW = W_Sigma
	Make /O /N=(NumPnts(CoefW)) $("Cof"+WNameStr), $("Sig"+WNameStr)  
	Wave w1 = $("Cof"+WNameStr)      // mdified to output the W_Coef , W_Sigma  10/20//2008
	Wave w2 = $("Sig"+WNameStr)
	w1=Nan; w2=Nan
	w1= CoefW
	w2= SigW
	If (DisplayFit	)
	AppendToGraph FitW vs wX_SrtFtRng
	ModifyGraph /W=pt_CurveFitEditDisplay lsize=2
	TraceNameStr="fit_"+WNameStr
	ModifyGraph /W=pt_CurveFitEditDisplay rgb($TraceNameStr)=(0,43520,65280)
	DoUpdate
	Sleep /T 15
	EndIf
	Else
		Print "Number of Pnts in X and Y Wave not equal", WNameStr, "vs", XWNameStr
	EndIf
EndFor
//If (DisplayFit	)
//	AppendToGraph FitW vs wX_SrtFtRng
//	ModifyGraph /W=pt_CurveFitEditDisplay lsize=2
//	TraceNameStr="fit_"+WNameStr
//	ModifyGraph /W=pt_CurveFitEditDisplay rgb($TraceNameStr)=(0,43520,65280)
//	DoUpdate
//	Sleep /T 60
//EndIf
EndIf
KillWaves /Z w_Srt, wX_Srt, w_SrtFtRng, wX_SrtFtRng
End 
//**************


Function pt_ExpFitW()

String DataWaveMatchStr, DataFldrStr, OutputWBaseName
Variable StartXVal, EndXVal, StartSteadyStateX, EndSteadyStateX	, Polarity, DisplayFit

String WList, CurveFitStr, WNameStr
Variable N,i, amp, tau, ySS

String LastUpdatedMM_DD_YYYY="10_01_2007"

Print "*********************************************************"
Print "pt_ExpFitW last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParW=$pt_GetParWave("pt_ExpFitW", "ParW")

PrintAnalPar("pt_ExpFitW")

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
StartXVal				=	Str2Num(AnalParW[2])
EndXVal					=	Str2Num(AnalParW[3])
StartSteadyStateX		=	Str2Num(AnalParW[4])
EndSteadyStateX			=	Str2Num(AnalParW[5])
Polarity					= 	Str2Num(AnalParW[6])
OutputWBaseName		=	AnalParW[7]
DisplayFit				=	Str2Num(AnalParW[8])

WList	=wavelist(DataWaveMatchStr,";","")
N		=ItemsInList(wList,";")
Make /O/N=0 $(OutputWBaseName+"Amp"), 		$(OutputWBaseName+"Tau")
Make /O/N=1 $(OutputWBaseName+"TmpAmp"), 	$(OutputWBaseName+"TmpTau")

Wave wAmp		= $(OutputWBaseName+"Amp")
Wave wTau		= $(OutputWBaseName+"Tau")
Wave wTmpAmp	= $(OutputWBaseName+"TmpAmp")
Wave wTmpTau	= $(OutputWBaseName+"TmpTau")

For (i=0; i<N; i+=1)
	WNameStr=StringFromList(i, Wlist, ";")
	wave w1=$WNameStr
	Duplicate /O w1,w
	If (Polarity == -1)
		w *= -1
	EndIf
	
	WaveStats /Q /R=(StartSteadyStateX, EndSteadyStateX) w
	ySS = V_Avg
	
	pt_expfit(w, ySS, StartXVal, EndXVal, amp, tau)
	
	Duplicate /O /R=(StartXVal, EndXVal) w1, $("Ft"+WNameStr)
	Wave FitW = $("Ft"+WNameStr)
	FitW = Nan
	If (Polarity == -1)
		amp *= -1
		ySS *= -1
	EndIf
	wTmpAmp = amp
	wTmpTau   = tau
	Concatenate /NP {wTmpAmp} ,		wAmp
	Concatenate /NP {wTmpTau} , 		wTau
//	Print amp, tau
	FitW = ySS + amp*exp(-x/tau)
	
	
If (DisplayFit	)
	Display
	DoWindow pt_ExpFitWDisplay
	If (V_Flag)
		DoWindow /F pt_ExpFitWDisplay
		Sleep 00:00:02
		DoWindow /K pt_ExpFitWDisplay
	EndIf
	DoWindow /C pt_ExpFitWDisplay
	AppendToGraph /W=pt_ExpFitWDisplay w1, FitW
	ModifyGraph /W=pt_ExpFitWDisplay rgb($("Ft"+WNameStr))=(0,0,0)
	ModifyGraph /W=pt_ExpFitWDisplay lsize=2
Else
	KillWaves /z $("Ft"+WNameStr)	
EndIf	
	KillWaves /z w
EndFor
KillWaves /z wTmpAmp, wTmpTau
End


Function pt_AnalyzeMinis(CellNameW, FitStartDelFrmPk)

// Last updated 1st Oct. 2007

// Analyze mini  peak amps, peak pos, decay tau's

Wave /T CellNameW
Variable FitStartDelFrmPk

String CellNameStr, DataWaveMatchStr, OutWaveBaseName, MiniNamesList, MiniNameStr, OldDataWaveMatchStr, OldBaseNameStr, OldOutWaveBaseName
String OldStartXValStr	
Variable N, i, NumMinis, j, OldStartXVal

N = NumPnts(CellNameW)

For (i=0; i<N; i+=1)
	CellNameStr = CellNameW[i]
	DataWaveMatchStr 	= CellNameStr +"_*"
	OutWaveBaseName 	= CellNameStr
	
	Make /O/N=0 $(CellNameStr+"PkYRel"), $(CellNameStr+"PkX")
	Wave wPkY = $(CellNameStr+"PkYRel")
	Wave wPkX = $(CellNameStr+"PkX")
	
	Make /O/N=0 $(CellNameStr+"Tau")
	Wave WTau = $(CellNameStr+"Tau")
	
	MiniNamesList	=wavelist(DataWaveMatchStr,";","")
	NumMinis		=ItemsInList(MiniNamesList,";")
	
	For (j=0; j<NumMinis; j+=1)
		MiniNameStr		=	StringFromList(j, MiniNamesList, ";")
		
		Wave /T AnalParW	=	$pt_GetParWave("pt_CalPeak", "ParW")
		OldDataWaveMatchStr	=	AnalParW[0]
		OldBaseNameStr			=	AnalParW[2]	
		AnalParW[0]				=	MiniNameStr	
		AnalParW[2]				= 	"MiniPeak"
	
		pt_CalPeak()
		
		AnalParW[0] = OldDataWaveMatchStr
		AnalParW[2]	= OldBaseNameStr
		
		
		Wave wPkYTmp 	= $("MiniPeak"	+"RelY")
		Wave wPkXTmp  =  $("MiniPeak"	+"X")
		
		Concatenate /NP {wPkYTmp}, wPkY
		Concatenate /NP {wPkXTmp}, wPkX
		
		Wave /T AnalParW	=	$pt_GetParWave("pt_ExpFitW", "ParW")
	
		OldDataWaveMatchStr	=	AnalParW[0]	
		OldStartXValStr			=	AnalParW[2]
		OldOutWaveBaseName	= 	AnalParW[7]	
	
		AnalParW[0]			=	MiniNameStr
		AnalParW[2]			=	Num2Str(WPkX[j] + FitStartDelFrmPk)
		AnalParW[7]			=	"MiniPeak"	
	
		pt_ExpFitW()
		
		AnalParW[0] = OldDataWaveMatchStr
		AnalParW[2]	= OldStartXValStr
		AnalParW[7]	= OldOutWaveBaseName
		
		Wave wTauTmp 	= $("MiniPeak" +"Tau")
		Concatenate /NP {wTauTmp}, WTau
			
	EndFor
	
EndFor	

End

Function pt_CalCummHist(WHistNameStr)
String WHistNameStr
Variable N, i

Wave wHist = $WHistNameStr

N	= NumPnts(wHist)

Make /O/N=(N) $WHistNameStr+"In"
Wave wHistIn = $WHistNameStr+"In"
wHistIn[0] = wHist[0]

For (i=1; i<N; i+=1)
	wHistIn[i] = wHistIn[i-1]+wHist[i]
EndFor
WHistIn /=WHistIn[N-1]

SetScale /P x, DimOffSet(wHist,0), DimDelta(wHist,0), wHistIn
	
End

Function pt_CalNormHist(WHistNameStr)
// normalize histogram so that sum of Y values =1
String WHistNameStr
Variable SumY

Wave wHist = $WHistNameStr
Wavestats /Q wHist
SumY= V_Sum
Duplicate /O wHist, $WHistNameStr+"N"
Wave wHistN = $WHistNameStr+"N"
wHistN	= wHist/SumY
	
End


Function pt_WKenMiniAnal()

// This is always the latest version

// "Use  pt_WKenMiniAnal to prepare waves for Ken's mini analysis"

// ALSO CHECK OUT pt_ExtractMiniWAll(), A FUNCTION TO EXTRACT MINIS FROM CONCATENATED WAVES

// the first wave was getting loaded and processed twice in case of FilterWave = 1. cos then AnalParW and AnalParNamesW referred to 
//pt_GaussianFilterData. which is ok if all the parameters from original AnalParW had been copied to local variables. however, in this function
// we are checking whether AnalParW[6], AnalParW[7] are empty or not. they no longer remain empty for pt_GaussianFilterData
// (in igor datapnts past end of wave get value of last pnt). therefore on 1st run, AnalParW[6], AnalParW[7] are empty and _0001 wave is chosen
// on 2nd pass, the pars were not empty and i=1 and therefore _0001 wave was again chosen. on all subsequent passes they were not empty.
// still even when the bug was there, 1st wave is loaded fresh twice so no error is really introduced. also the last wave will be 2nd last when the 
// bug was present. but in the gaba mini analysis for zolpidem in LC the cells 2643 to 2658 had the last few waves collected for reversal pot. 
// and were anyway not included in wash epoch.
// changed AnalParW to AnalParW1 for pt_GaussianFilterData. 3rd Dec. 2007

// modified so that WaveStartNum & WaveEndNum need not be given. 9th Oct. 2007
// modified from older version of  pt_RenameWaves that used to add suffix, change extenstion, and scale.
// Example Usage: pt_RenameWaves("Cell_000654_","ToNeg90;RsRinCm;AcqNeg90;ToNeg70","D:users:taneja:data:Temp","D:users:taneja:data:ptCell654",1e12,pA, 1,203)
String BaseNameStr, WaveSuffixString, OrigWavesFolder, NewWavesFolder, YUnitsString
Variable MultiplyBy, WaveStartNum, WaveEndNum, FilterData

String  OldWaveName, NewWaveName,WavStr, SaveNewWaveAs, LastUpdatedMM_DD_YYYY="12_03_2007", AllListStr, ListStr
String  OldDataWaveMatchStr
Variable i, NumSuffixes, SuffixNum,Ndig=4, NumWaves

Print "*********************************************************"
Print "pt_WKenMiniAnal last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParW=$pt_GetParWave("pt_WKenMiniAnal", "ParW")

PrintAnalPar("pt_WKenMiniAnal")

BaseNameStr			=	AnalParW[0]
WaveSuffixString			=	AnalParW[1]
OrigWavesFolder			=	AnalParW[2]
NewWavesFolder			=	AnalParW[3]
MultiplyBy				=	Str2Num(AnalParW[4])
YUnitsString				=	AnalParW[5]

WaveStartNum 	= StringMatch(AnalParW[6], "") ? Nan : Str2Num(AnalParW[6])		// if empty use 1st found	9th Oct. 2007
WaveEndNum	= StringMatch(AnalParW[7], "") ? Nan : Str2Num(AnalParW[7])		// if empty use  last found

FilterData				=    Str2Num(AnalParW[8])	// 1= yes ; 0 = No


If (	(NumType(WaveStartNum)!=0) || (NumType(WaveEndNum)!=0)	)

	NewPath SymblkHDFolderPath, OrigWavesFolder
	AllListStr= IndexedFile(SymblkHDFolderPath, -1, ".ibw")
	KillPath /Z SymblkHDFolderPath
	ListStr = ListMatch(AllListStr, BaseNameStr+"*", ";")
	NumWaves = ItemsinList(ListStr, ";")
	
	WaveStartNum 	= 	0
	WaveEndNum	= 	NumWaves-1

EndIf


NewDataFolder /O/S root:TempRenameWavesFolder
NumSuffixes = ItemsInList(WaveSuffixString)

	For (i=WaveStartNum;i<=WaveEndNum;i+=1)
//		OldWaveName =BaseName+num2istr(i)
		If (	(StringMatch(AnalParW[6],"") || StringMatch(AnalParW[7],"")) ==1	)
			OldWaveName = StringfromList(i, ListStr, ";")
			OldWaveName = ReplaceString(".ibw", OldWaveName, "")
		Else
			OldWaveName =BaseNameStr+num2digstrCopy(NDig,i)
		EndIf
		
		SuffixNum = Mod((i-WaveStartNum),NumSuffixes)

//		If (SuffixNum==0)
//		SuffixNum=NumSuffixes
//		Endif
 		
 		WavStr=StringFromList(SuffixNum,WaveSuffixString,";")
//		NewWaveName=OldWaveName +"_"+WavStr
		NewWaveName=OldWaveName +WavStr	// include "_" in suffix str itself so that if no suffix is there then nothing gets added. praveen (10_04_2007)
		LoadData /Q/O/D/J=OldWaveName /L=1 OrigWavesFolder
//		Wave NewWaveNamePtr = $(NewWaveName)
		If (StringMatch(WavStr, "") !=1)
			Duplicate /O $(OldWavename), $(NewWaveName)
		EndIf
		Wave NewWaveNamePtr = $(NewWaveName)
		NewWaveNamePtr *=MultiplyBy
		SetScale d,0,0,YUnitsString,NewWaveNamePtr	
		If (FilterData)
//			Wave /T AnalParNamesW	=	$pt_GetParWave("pt_GaussianFilterData", "ParNamesW")
//			Wave /T AnalParW			=	$pt_GetParWave("pt_GaussianFilterData", "ParW")
			Wave /T AnalParNamesW1	=	$pt_GetParWave("pt_GaussianFilterData", "ParNamesW")
			Wave /T AnalParW1			=	$pt_GetParWave("pt_GaussianFilterData", "ParW")
			OldDataWaveMatchStr		=	AnalParW1[0]
			AnalParW1[0]				=	NewWaveName
			pt_GaussianFilterData()
			AnalParW1[0]				=	OldDataWaveMatchStr
			Duplicate /O $(NewWaveName+"_F"), NewWaveNamePtr
		EndIf
			
//		SetScale /p x, DimOffset($(OldWavename),0), DImDelta($(OldWavename),0),YUnitsString,NewWaveNamePtr	
		SaveNewWaveAs=NewWavesFolder + ":"+NewWaveName+".bwav"
		Save /O $(NewWaveName) as SaveNewWaveAs
		KillWaves /A/Z
	EndFor
	If (	(StringMatch(AnalParW[6],"") || StringMatch(AnalParW[7],"")) ==1	)
		Print "Multiplied y-axis values by ",MultiplyBy, "and changed the unit to ",YUnitsString, "for waves, N=", i
	Else
		Print "Multiplied y-axis values by ",MultiplyBy, "and changed the unit to ",YUnitsString, "for waves, N=", i-1
	EndIf
	
Return 1
End


Function pt_ExtractMiniWAll()

// To extract ALL mini waves out of concatenated mini waves saved by ken's program
//Example Usage: pt_ExtractMiniWAll("miniWaves", 350, "Mini_")

// this function essentially taken out from ken's functions (function DecayNoise_afterFolder()). 
// variable names are kept similar
String ConcatMiniWName, OutBaseName
Variable IndvidMiniLenInPnts //in points

String LastUpdatedMM_DD_YYYY= "01_20_2009"

Print "*********************************************************"
Print "pt_ExtractMiniWAll last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParW=$pt_GetParWave("pt_ExtractMiniWAll", "ParW")

PrintAnalPar("pt_ExtractMiniWAll")

ConcatMiniWName		=	AnalParW[0]
IndvidMiniLenInPnts		=	Str2Num(AnalParW[1])
OutBaseName			=	AnalParW[2]


Wave miniWaves = $ConcatMiniWName

Variable c

Variable numMini = floor(numpnts(miniWaves)/IndvidMiniLenInPnts)

for(c=0;c<numMini;c+=1)
		Make /O/N=(IndvidMiniLenInPnts)	$(OutBaseName+pt_PadZeros2IntNum(c, 5))
		Wave wMini =	$(OutBaseName+pt_PadZeros2IntNum(c, 5))
		CopyScales /p miniWaves, wMini
		wMini = miniWaves[IndvidMiniLenInPnts*c+p]
endfor

End


Function pt_AnalysisStartDateNTime()

Print "=============================="
Print "Starting Analysis at", time(), "on", Date()
Print "=============================="

End

Function pt_AnalysisStopDateNTime()

Print "=============================="
Print "Stopping Analysis at", time(), "on", Date()
Print "=============================="

End

Function pt_SetXScale()

String LastUpdatedMM_DD_YYYY="11_19_2007"
Print "*********************************************************"
Print "pt_SetXScale last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Variable x0, xDel, N, i, ChngeOrigW
String WNameStr, OutWBaseName, OutWSuffix, wavlist, wStr

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SetXScale", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_SetXScale", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_SetXScale!!!"
EndIf

PrintAnalPar("pt_SetXScale")

WNameStr			= AnalParW[0]
OutWSuffix			= AnalParW[1]

x0					= Str2Num(AnalParW[2])
xDel				= Str2Num(AnalParW[3])

If (StrLen(WNameStr)==0)
wavlist = wavelist("*",";","WIN:")
Else
wavlist = wavelist(WNameStr,";","")
EndIf

ChngeOrigW =0
If (StringMatch(OutWSuffix, ""))
	ChngeOrigW	= 1	
EndIf

N=ItemsInList(wavlist, ";")

Print "Changing X-scaling for waves for N=",N,wavlist

For (i=0; i<N; i+=1)
	wStr= StringFromList(i,wavlist,";")
	If (ChngeOrigW)
		Setscale /P x, x0, xDel, $wStr
	Else
		Duplicate /O $wStr, $(wStr+OutWSuffix)
		Setscale /P x, x0, xDel, $(wStr+OutWSuffix)
	EndIf
EndFor


End

Function pt_GetOnePnt(WPathWName, PntNum)
String WPathWName
Variable PntNum
If (WaveType($WPathWName) ==0 )	// text wave
Wave /T wT = $WPathWName
Return Str2Num(wT[PntNum])
Else
Wave w = $WPathWName
Return w[PntNum]
EndIf	
End

Function pt_AllignWaves()

String LastUpdatedMM_DD_YYYY="11_19_2007"
String WPathWName, x0Old
Variable PntNum, x0New

Print "*********************************************************"
Print "pt_AllignWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AllignWaves", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_AllignWaves", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_AllignWaves!!!"
EndIf

PrintAnalPar("pt_AllignWaves")

WPathWName = AnalParW[0]
PntNum		   = Str2Num(AnalParW[1])


Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SetXScale", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_SetXScale", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_SetXScale!!!"
EndIf

//PrintAnalPar("pt_SetXScale")

x0Old = AnalParW[2]

// allign all waves so that Start pnt has x value =0.
x0New = -1*(pt_GetOnePnt(WPathWName, PntNum) -1) 
							
AnalParW[2] = Num2Str(x0New)

pt_SetXScale()

AnalParW[2] = x0Old

End

// StatsTTest
Function pt_StatsTTest()

// different autoset bins 10/31/2008

String WName1, WName2, LastUpdatedMM_DD_YYYY = "10_31_2008"
Variable ShowHistograms, EqualVariance, Paired, Tails, Mean1Greater, m, t

Print "*********************************************************"
Print "pt_StatsTTest last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_StatsTTest", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_StatsTTest", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_StatsTTest!!!"
EndIf



WName1 			= AnalParW[0]
WName2 			= AnalParW[1]
ShowHistograms		= Str2Num(AnalParW[2])
EqualVariance		= Str2Num(AnalParW[3])
Paired				= Str2Num(AnalParW[4])
Tails				= Str2Num(AnalParW[5])
If (Tails !=2)
	If (	StrLen(AnalParW[6]) !=0)
	Mean1Greater		= Str2Num(AnalParW[6])
	Else
	Abort "1-tailed t-test: Is Mean1Greater true?"
	EndIf
EndIf

PrintAnalPar("pt_StatsTTest")

Wave w1 = $WName1
Wave w2 = $WName2

If (ShowHistograms)
	DoWindow /F HistogramsForTTest
	If	(!V_Flag)
		Display 
		DoWindow /C HistogramsForTTest
	Else
		DoWindow /K HistogramsForTTest		
		Display 
		DoWindow /C HistogramsForTTest
	EndIf
	If (Paired)
		Duplicate /O w1, wDiff
		wDiff -= w2
//		Make/N=5/O wDiff_Hist
//		Histogram/B=1 wDiff, wDiff_Hist		// different autoset bins
		Make/N=0/O wDiff_Hist
		Histogram/B=3 wDiff, wDiff_Hist
		AppendToGraph wDiff_Hist
	Else
//	Make/N=5/O w1_Hist						// different autoset bins
//	Histogram/B=1 w1, w1_Hist
	Make/N=0/O w1_Hist
	Histogram/B=3 w1, w1_Hist
	AppendToGraph w1_Hist
//	Make/N=5/O w2_Hist						// different autoset bins
//	Histogram/B=1 w2, w2_Hist
	Make/N=0/O w2_Hist
	Histogram/B=3 w2, w2_Hist
	AppendToGraph w2_Hist
	ModifyGraph rgb(w1_Hist)=(65280,0,0)
//	AppendToGraph w2
	ModifyGraph rgb(w2_Hist)=(0,15872,65280)
	Legend/C/N=text0/F=0
	EndIf
EndIf

m =0
m = (EqualVariance == 0) ? 0 : 2

t = 4

If (	Tails !=2		)
	t = (Mean1Greater == 1) ? 1 : 2
EndIf	

Print "EqualVariance, Paired, Tails (1: Mean1Greater, 2: Mean2Greater, 4: 2-tailed)", EqualVariance, Paired, t

If (Paired)
	If (	NumPnts(w1) == NumPnts(w2)	)
		StatsTTest /T=0/CI/DFM=(m)/Pair/Tail=(t) w1, w2
	Else
		Abort "In paired t-test waves should have equal num. of pnts."
	EndIf
Else
	StatsTTest /T=0/CI/DFM=(m)/Tail=(t) w1, w2
EndIf

End

//******
// StatsAnova1
Function pt_StatsAnova1()
// WListStr doesn't work properly. Specify waves separated by commas after StatsAnova1Test
// for posthoc test use StatsTukeyTest


// Based on pt_StatsTTest()

String WListStr, LastUpdatedMM_DD_YYYY = "07_29_12"

Print "*********************************************************"
Print "pt_StatsAnova1last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_StatsTTest", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_StatsTTest", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_StatsTTest!!!"
EndIf

WListStr 			= AnalParW[0]

PrintAnalPar("pt_StatsAnova1")

StatsANOVA1Test /WSTR=WListStr

End
//******




Function pt_CalLeakCurr()
// This is always the latest version

String DataWaveMatchStr, OutNameBaseStr, OutNameSuffixStr	
Variable FitStartX	, FitEndX, N, i

String LastUpdatedMM_DD_YYYY = "04_06_2008", WList, WaveStr
Variable Slp, Intcpt, DisplayLeak

Print "*********************************************************"
Print "pt_CalLeakCurr last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalLeakCurr", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_CalLeakCurr", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_CalLeakCurr!!!"
EndIf

DataWaveMatchStr 	=	AnalParW[0]
FitStartX				=	Str2Num(AnalParW[1])
FitEndX				=	Str2Num(AnalParW[2])
OutNameBaseStr		=	AnalParW[3]
OutNameSuffixStr	=    AnalParW[4]
DisplayLeak			=	Str2Num(AnalParW[5])

PrintAnalPar("pt_CalLeakCurr")

WList	=wavelist(DataWaveMatchStr,";","")
N		=ItemsInList(wList,";")

For (i=0; i<N; i+=1)
	WaveStr = StringFromList(i, WList, ";")
	Duplicate /O $WaveStr, w_tmp
	Duplicate /O w_tmp, $(OutNameBaseStr + OutNameSuffixStr)
	Wave w1_tmp = $(OutNameBaseStr + OutNameSuffixStr)
	w1_tmp = Nan
	pt_LinearFit(w_tmp, FitStartX, FitEndX, 	Slp, Intcpt)
	Print Slp, Intcpt
	w1_tmp = Slp*p + Intcpt
	
	
	If (DisplayLeak)
	Display
	DoWindow pt_LeakCurrDisplay
	If (V_Flag)
		DoWindow /F pt_LeakCurrDisplay
		Sleep 00:00:02
		DoWindow /K pt_LeakCurrDisplay
	EndIf
	DoWindow /C pt_LeakCurrDisplay
	AppendToGraph /W=pt_LeakCurrDisplay w_tmp, w1_tmp
	ModifyGraph /W=pt_LeakCurrDisplay rgb($(OutNameBaseStr + OutNameSuffixStr))=(0,0,0)
//	ModifyGraph /W=pt_LeakCurrDisplay lsize=2
	Else
	KillWaves /z w_tmp
	EndIf	
			
EndFor

End

Function pt_CalISIAdaptRatio()

// add NaNs, when AdaptR is not defined, to keep length of all waves same. Easier for averaging		11/17/13
// added subfldr option - 11/15/13
// inverted the definition of adaptation ratio in pt_CalISIAdaptRatio(). 
// Old 		ARTmp[0]	= 	EndAvgISI/ StartAvgISI
//  New		ARTmp[0]	= 	StartAvgISI / EndAvgISI	
//seems that inverse ratio is more commonly used. 08_23_2008

// algo: 

// for each wave calculate average of 'm1' start ISI starting at 's1' 
// for each wave calculate average of 'm2' end ISI starting at 's2' 
// calculate ratio EndAvgISI/ StartAvgISI. value greater than one means adapting
// also make a wave with StartAvgISI to plot AdaptationRatio vs StartAvgISI

String DataWaveMatchStr, OutNameBaseStr, OutNameSuffixStr, SubFldr
Variable StartISINum, StartISINumAvgWin, EndISINum, EndISINumAvgWin
String LastUpdatedMM_DD_YYYY = "08_23_2008", WList, WaveStr
Variable N, i, wN, s1, e1, s2, e2, StartAvgISI, EndAvgISI

Print "*********************************************************"
Print "pt_CalISIAdaptRatio last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalISIAdaptRatio", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_CalISIAdaptRatio", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_CalISIAdaptRatio!!!"
EndIf

DataWaveMatchStr 	=	AnalParW[0]

//**** ISI count starts from zero. So StartISINum=1 is actually 2nd ISI. 
//StartISINumAvgWin	= 1 implies only 1 point. EndISINumAvgWin=1 implies only 1 point***
// with above values we are defining adaptation ratio as 2nd ISI/ Last ISI


StartISINum			=	Str2Num(AnalParW[1])
StartISINumAvgWin	=	Str2Num(AnalParW[2])
//EndISINum			=	Str2Num(AnalParW[3])
EndISINumAvgWin	=	Str2Num(AnalParW[3])

OutNameBaseStr		=	AnalParW[4]
OutNameSuffixStr	= 	AnalParW[5]
SubFldr				=	AnalParW[6]		// added subfldr option - 11/15/13

PrintAnalPar("pt_CalISIAdaptRatio")

// find all waves that match DataWaveMatchStr
WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
N		=ItemsInList(wList,";")

Make /O/N=1 $GetDataFolder(1)+SubFldr+"ARTmp"		// AR = AdaptationRatio
Wave ARTmp = $GetDataFolder(1)+SubFldr+"ARTmp"

Make /O/N=1  $GetDataFolder(1)+SubFldr+"ARTmpX"
Wave ARTmpX = $GetDataFolder(1)+SubFldr+"ARTmpX"

Make /O/N=0 $(GetDataFolder(1)+SubFldr+OutNameBaseStr + OutNameSuffixStr)	
Wave AR = $(GetDataFolder(1)+SubFldr+OutNameBaseStr + OutNameSuffixStr)

Make /O/N=0 $(GetDataFolder(1)+SubFldr+OutNameBaseStr + OutNameSuffixStr+ "X")
Wave ARX = $(GetDataFolder(1)+SubFldr+OutNameBaseStr + OutNameSuffixStr	+ "X")

ARTmp		= Nan
ARTmpX 	= Nan

AR			= Nan
ARX			= Nan

For (i=0; i<N; i+=1)
	WaveStr = StringFromList(i, WList, ";")
	Wave w = $GetDataFolder(1)+SubFldr+WaveStr
	wN = NumPnts(w) 
	// If wave has sufficient number of ISI's
	If (wN >= (StartISINum+ StartISINumAvgWin + EndISINumAvgWin) )
	
		s1 = StartISINum
		e1 = StartISINum+StartISINumAvgWin-1
		
		e2 = wN-1
		s2 = e2 - (EndISINumAvgWin-1)
		
		If (	(e1 >=s1) && (e2 >=s2)	)
		
		Print  WaveStr, "ISIStart", s1, "to",e1, "ISIEnd", s2, "to", e2
		
		Wavestats /Q /R=[s1, e1] w 
		StartAvgISI = V_Avg

		Wavestats /Q /R=[s2, e2] w 
		EndAvgISI = V_Avg

//		Print StartAvgISI, EndAvgISI
//		ARTmp[0]	= 	EndAvgISI/ StartAvgISI
		ARTmp[0]	= 	StartAvgISI / EndAvgISI	// seems that inverse ratio is more commonly used. 08_23_2008
		ARTmpX[0]	= 	StartAvgISI
		
		Concatenate /NP {ARTmp}, AR
		Concatenate /NP {ARTmpX}, ARX		
		Else		// add NaNs, when AdaptR is not defined, to keep length of all waves same. Easier for averaging	11/17/13
			ARTmp[0]	= 	NaN	// seems that inverse ratio is more commonly used. 08_23_2008
			ARTmpX[0]	= 	NaN
		
			Concatenate /NP {ARTmp}, AR
			Concatenate /NP {ARTmpX}, ARX	
		EndIf		
	Else		// add NaNs, when AdaptR is not defined, to keep length of all waves same. Easier for averaging		11/17/13
		ARTmp[0]	= 	NaN	// seems that inverse ratio is more commonly used. 08_23_2008
		ARTmpX[0]	= 	NaN
		
		Concatenate /NP {ARTmp}, AR
		Concatenate /NP {ARTmpX}, ARX	
	EndIf
	
EndFor	

KillWaves /Z ARTmp, ARTmpX

End


Function pt_CalISIAdaptTau()

// calculate ISI using pt_ConvertTSpikeToISI() or pt_ConvertTSpikeToISIVarPar1(). 
// calculate SpkT Avg using pt_ConvertTSpikeToMidT or pt_ConvertTSpikeToMidTVarPar1  (NumPnts in SpkT is 1 less than num pnts
// ISI. while AvgSpkT has same numpnts as ISI wave)

//now, use pt_CurveFit to fit whatever function (usually single or double exponentials to ISI vs AvgSPkT). get the fit parameters out
// and name them with current injection suffix. then make a wave from them. thus for each FI curve you will get a fit parameter wave
// as function of current injection. average across cells to get fit parameter as function of current injection for a category
// (like WT and mutant)



String ISIDataWaveMatchStr, SpkTDataWaveMatchStr

String OldDataWaveMatchStr, OldStartXVal, OldEndXVal, OldXDataWaveMatchStr

String ISIWList, SpkTWList, wYStr, wXStr
Variable N, i
Variable MinLocIndx

String LastUpdatedMM_DD_YYYY = "08_23_2008"

Print "*********************************************************"
Print "pt_CalISIAdaptTau last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalISIAdaptTau", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_CalISIAdaptTau", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_CalISIAdaptTau!!!"
EndIf

ISIDataWaveMatchStr 	=	AnalParW[0]
SpkTDataWaveMatchStr 	=	AnalParW[1]


PrintAnalPar("pt_CalISIAdaptTau")

Wave /T AnalParW=$pt_GetParWave("pt_CurveFit", "ParW")

OldDataWaveMatchStr		=	AnalParW[0]
OldStartXVal					=	AnalParW[3]
OldEndXVal					=	AnalParW[4]
OldXDataWaveMatchStr		=	AnalParW[6]




ISIWList		=wavelist(ISIDataWaveMatchStr,";","")
SpkTWList	=wavelist(SPkTDataWaveMatchStr,";","")

// check that the number of items in ISIWList	 is same as in SPkTWList

If (ItemsInList(ISIWList)!=ItemsInList(SpkTWList))
Abort "Unequal number of ISI and SpkTMid waves"
Else
N		=ItemsInList(ISIWList	,";")
EndIf

For (i=0; i<N;i+=1)
wYStr = StringFromList(i,ISIWList,";")
wXStr = StringFromList(i,SpkTWList,";")
Wave wY = $wYStr
Wave wX  = $wXStr
AnalParW[0] = wYStr
AnalParW[6] = wXStr
Duplicate /O wY, $("wY_Srt")
Duplicate /O wX, $("wX_Srt")
Wave wY_Srt, wY_Srt
Wave wX_Srt, wX_Srt
Sort wX_Srt, wX_Srt, wY_Srt
SetScale /P x,0,1, wY_Srt	

// pt_CurveFit takes XVals not XIndexVals

// start at minimum location
//wavestats /q wY_Srt
//MinLocIndx=V_MinLoc

//AnalParW[3] = Num2Str(wX_Srt(MinLocIndx))		
//AnalParW[4] = Num2Str(wX_Srt(NumPnts(wY_Srt)))		

// start at fixed index value
AnalParW[3] = Num2Str(wX_Srt(1))			// 1st point = 2nd ISI
AnalParW[4] = Num2Str(wX_Srt(NumPnts(wY_Srt)-1))	

KillWaves wY_Srt, wX_Srt
pt_Curvefit()

AnalParW[0]=OldDataWaveMatchStr
AnalParW[6]=OldXDataWaveMatchStr
AnalParW[3]=OldStartXVal
AnalParW[4]=OldEndXVal

EndFor 



End

Function pt_CalEOPAHPTau()


//based on pt_CalISIAdaptTau. any modifications here should probably also be made to pt_CalISIAdaptTau

// only difference is this will fit just a y wave not xy wave

String DataWaveMatchStr

String OldDataWaveMatchStr, OldStartXVal, OldEndXVal

String WList, wYStr
Variable N, i
Variable MinLocIndx

String LastUpdatedMM_DD_YYYY = "08_23_2008"

Print "*********************************************************"
Print "pt_CalEOPAHPTau last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalEOPAHPTau", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_CalEOPAHPTau", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_CalEOPAHPTau!!!"
EndIf

DataWaveMatchStr 	=	AnalParW[0]



PrintAnalPar("pt_CalEOPAHPTau")

Wave /T AnalParW=$pt_GetParWave("pt_CurveFit", "ParW")

OldDataWaveMatchStr		=	AnalParW[0]
OldStartXVal					=	AnalParW[3]
OldEndXVal					=	AnalParW[4]

WList		=wavelist(DataWaveMatchStr,";","")

N			=ItemsInList(WList	,";")

For (i=0; i<N;i+=1)
wYStr = StringFromList(i,WList,";")
Wave wY = $wYStr
AnalParW[0] = wYStr

// pt_CurveFit takes XVals not XIndexVals

// start at minimum location
Duplicate /O wY, Sm_wY
Smooth /B 51, Sm_wY
wavestats /q Sm_wY
MinLocIndx=V_MinLoc+0.1
KillWaves /Z Sm_wY
Print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
Print "Fitting from Wave min+100ms to 2.8s. Boxcar smoothing (for finding minimum)=51"
Print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
AnalParW[3] = Num2Str(MinLocIndx)		
//AnalParW[4] = Num2Str(DimOffSet(wY,0)+DimDelta(wY,0)*(NumPnts(wY)-1)    )		

// start at fixed index value
//AnalParW[3] = Num2Str(wX_Srt(1))			
//AnalParW[4] = Num2Str(wX_Srt(NumPnts(wY_Srt)-1))	

pt_Curvefit()

AnalParW[0]=OldDataWaveMatchStr
AnalParW[3]=OldStartXVal
AnalParW[4]=OldEndXVal

EndFor 

End





Function pt_CurveFitAdaptRatio()
// function to fit exponential to XY waves generated from pt_CalISIAdaptRatio()
String WStr
Variable N, i
String LastUpdatedMM_DD_YYYY = "08_23_2008"
Wave /T CellNameW = root:Anal:FI:WTFemale:WTFemaleCellName

Print "*********************************************************"
Print "pt_CurveFitAdaptRatio last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

N= NumPnts(CellNameW)

For (i=0; i<N; i+=1)
WStr = CellNameW(i)
WStr =ReplaceString("*", WStr, "F_IISIAdptR")
Wave Wy = $WStr
Wave Wx = $(WStr+"X")
Display
DoWindow pt_CurveFitAdaptRatioDisplay
If (V_Flag)
	DoWindow /F pt_CurveFitAdaptRatioDisplay
	Sleep 00:00:02
	DoWindow /K pt_CurveFitAdaptRatioDisplay
EndIf
DoWindow /C pt_CurveFitAdaptRatioDisplay
AppendToGraph /W=pt_CurveFitAdaptRatioDisplay Wy vs Wx
SetAxis /W=pt_CurveFitAdaptRatioDisplay bottom 0.001,0.221
CurveFit/L=221 /X=1/NTHR=0/TBOX=0 exp_XOffset  Wy /X=Wx /D
EndFor
End


Function pt_FuncFitAdaptRatio()
// function to fit Inverse exponential decay to XY waves generated from pt_CalISIAdaptRatio(). since i inverted the defininition of 
// adaptation ratio
String WStr
Variable N, i
String LastUpdatedMM_DD_YYYY = "08_23_2008"
Wave /T CellNameW = root:Anal:FI:Mecp2NullTHP:Mecp2NullTHPCellName
Print "*********************************************************"
Print "pt_FuncFitAdaptRatio last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

N= NumPnts(CellNameW)

For (i=0; i<N; i+=1)
WStr = CellNameW(i)
WStr =ReplaceString("*", WStr, "F_IISIAdptR")
Wave Wy = $WStr
Wave Wx = $(WStr+"X")
Display
DoWindow pt_CurveFitAdaptRatioDisplay
If (V_Flag)
	DoWindow /F pt_CurveFitAdaptRatioDisplay
	Sleep 00:00:02
	DoWindow /K pt_CurveFitAdaptRatioDisplay
EndIf
DoWindow /C pt_CurveFitAdaptRatioDisplay
AppendToGraph /W=pt_CurveFitAdaptRatioDisplay Wy vs Wx
SetAxis /W=pt_CurveFitAdaptRatioDisplay bottom 0.01,0.221
//CurveFit/L=221 /X=1/NTHR=0/TBOX=0 exp_XOffset  Wy /X=Wx /D
Make /O/D/N=4 FitCoeffW

FitCoeffW[0]	= 1	// initial guesses were generated by first starting with some guesses, generating fits, averaging,
				// and then fitting the average. the guesses are values close to fit coeffs for average
FitCoeffW[1]	= 1.5	// held constant	
FitCoeffW[2]	= 0.003	
FitCoeffW[3]	= 0.04

Print "FitCoeffW ( Starting guesses) = {1,1.5,0.003, 0.04}"
Print "InvExp_XOffset(x) = 1/(y0+A*Exp(-(x-x0)/Tau) )"

FuncFit/L=212/X=1/H="0010"/NTHR=0/TBOX=0 pt_InvExp_XOffset FitCoeffW  Wy /X=Wx /D 
EndFor
End


Function pt_InvExp_XOffset(w, x) : FitFunc
Wave w
Variable x
String LastUpdatedMM_DD_YYYY = "08_23_2008"
//Print "*********************************************************"
//Print "pt_InvExp_XOffset last updated on", LastUpdatedMM_DD_YYYY
//Print "*********************************************************"

Variable y0 	=	w[0]
Variable A  	=	w[1]
Variable x0 	=	w[2]
Variable Tau	=	w[3]

Return 1/(y0+A*Exp(-(x-x0)/Tau) )
End


Function pt_PlotXYZcolor()
// x, y are spatial coordinates. z is some measure at different spatial positions. say size of neuron. igor
// plots a matrix of data n*m (n-rows and m-columns). the value is the intensity of the pixel (which is
// rectangular). now, our x,y,z values may not cover the entire matrix. what we need is to scale the x-y
// values of matrix. initialize it with all values zero. and then assign z to x,y values to the matrix

String XDataWMatchStr, YDataWMatchStr, ZDataWMatchStr, XYWNameStr
Variable Rn, Cn, OddNumPixelSize

String LastUpdatedMM_DD_YYYY= "06_22_2008"
Variable i, N, xWRnd0, yWRnd0, xWRnd, yWRnd, r, j, k


Print "*********************************************************"
Print "pt_PlotXYZcolor last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"



Wave /T AnalParNamesW		=	$pt_GetParWave("pt_PlotXYZcolor", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_PlotXYZcolor", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_PlotXYZcolor!!!"
EndIf

XDataWMatchStr 	=	AnalParW[0]
YDataWMatchStr 	=	AnalParW[1]
ZDataWMatchStr 	=	AnalParW[2]
Rn					=	Str2Num(AnalParW[3])	// num of rows
Cn					=	Str2Num(AnalParW[4])	// num of columns
OddNumPixelSize	=	Str2Num(AnalParW[5])
XYWNameStr		= 	AnalParW[6]

PrintAnalPar("pt_PlotXYZcolor")

Wave xW=$(XDataWMatchStr )
Wave yW=$(YDataWMatchStr )
Wave zW=$(ZDataWMatchStr )

Make /O/N=(Rn,Cn) $(XYWNameStr)=Nan
Wave XYW = $(XYWNameStr)


// check xW, yW have same number of pnts
N =NumPnts(xW)

//Wave zW=zW


For (i=0; i<N;i+=1)
	xWRnd0=Round(xW[i])
	yWRnd0=Round(yW[i])
	
	For (j=0 ; j<OddNumPixelSize ; j+=1)
		xWRnd =xWRnd0 - ( (OddNumPixelSize-1)/2)  +j
	For(k=0; k<OddNumPixelSize; k+=1)
		yWRnd =yWRnd0 - ( (OddNumPixelSize-1)/2)  +k
		XYW[xWRnd][yWRnd] = zW(i)
	EndFor
	EndFor
			
EndFor

End


Function pt_SelectRndMrkrs1(NRnd)		

// Aim: randomly choose N markers

Variable NRnd	//NRnd = Number of random points to select

Variable NSliceNum, i, N0, num

Wave x1	=	XLoc
Wave y1	=	YLoc
Wave z0	=	SliceNumAll
Wave z1	=	SliceNum

NSliceNum = NumPnts(z1)

i=0
N0=0

Do		// count number of non-repeated markers
If (z0(i) >1)
	Break
EndIf
	i	+=	1
	N0 	+=	1	
While(1)

// check if Pnts in SliceNum = number of markers AND
// check if N Random markers is less than equal to total number of markers

If (	(NSliceNum == N0)	&& (NRnd <= N0) )

	Make  /O/N=(NRnd) xLoc_Rnd, yLoc_Rnd, SliceNum_Rnd

	Make /O/N=(N0) tmp1, tmp2
	tmp1=enoise(1)
	tmp2= p
		
	Sort tmp1, tmp2
	
//	Redimension /N=(NRnd)  xLoc_Rnd, yLoc_Rnd, SliceNum_Rnd
	
	xLoc_Rnd		= x1(tmp2[p])
	yLoc_Rnd		= y1(tmp2[p])
	SliceNum_Rnd	= z1(tmp2[p])
	KillWaves/Z tmp1, tmp2
Else
	Print "Num of slices not equal to number of markers OR N random markers greater than total markers!"
	DoAlert 0, "No waves modified!"
EndIf

End


Function pt_NormWsToW()
// normalize a set of waves by values in a specified wave. Eg. normalize currents values to capacitance value for each cell. 
// duplicate current waves to analysis folder
String DataWaveMatchStr, NormWMatchStr, DataFldrStr, OutBaseStr
String LastUpdatedMM_DD_YYYY="10_19_2012"
String OldDF, WList, WStr
Variable i, NumWaves

Print "*********************************************************"
Print "pt_NormWsToW last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_NormWsToW"+"ParNamesW")
Wave /T AnalParW		=	$("root:FuncParWaves:pt_NormWsToW"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_NormWsToWParW and/or pt_NormWsToWParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
NormWMatchStr		=	AnalParW[1]
DataFldrStr				=	AnalParW[2]
OutBaseStr			=	AnalParW[3]

PrintAnalPar("pt_NormWsToW")

OldDF = GetDataFolder(1)
SetDataFolder GetDataFolder(1)+DataFldrStr

WList	=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
Wave NormByW = $NormWMatchStr
If (ItemsInList(WList,";")!=NumPnts(NormByW))
 	Print "Number of waves not equal to number of norm values"
 	Return (-1)
 Else
 	NumWaves=	ItemsInList(WList,";")
EndIf

If (NumWaves<=0)
Print "NumWaves <=0. No Waves to normalize!!"
Return -1
EndIf

print "Normalizing waves...N=", NumWaves, WList

For (i=0; i<NumWaves; i+=1)
WStr= StringFromList (i,WList,";")
Duplicate /O $WStr, $OutBaseStr+Num2Str(i)
Wave w = $OutBaseStr+Num2Str(i)
w /=NormByW[i]
EndFor

SetDataFolder OldDF
End


Function pt_BinXYWave() 
// This is always the latest version. 
// Modified pt_BinXYWave() to exclude Nans and Infs when checking if all points got binned once and only once 05/16/2009

// sometimes X-Y waves have different x-values for different waves. in order to average, the y-values need to be calculated at same x-values.
// one way to do that is to bin them into equally spaced bins. this function does that. if instead of XY waves, Y waves are there with different
//x-scaling, pt_BinXYWave can still be used cos the x-scaling can be used to generate x-waves first.


Variable BinStartXVal, BinWidthX, NBins, DisplayAvg
String YDataWaveMatchStr, XDataWaveMatchStr, DataFldrStr, SuffixStr

Variable NumWaves, i, NPnts, j, k, klast, NPntsBinned, NumNansInfs,EqualPoints
String XWList, YWList, YWaveNameStr, XWaveNameStr
String LastUpdatedMM_DD_YYYY="10_06_2008"

Print "*********************************************************"
Print "pt_BinXYWave last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_BinXYWave"+"ParNamesW")

Wave /T AnalParW		=	$("root:FuncParWaves:pt_BinXYWave"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_BinXYWaveParW and/or pt_BinXYWaveParNamesW!!!"
EndIf

YDataWaveMatchStr		=	AnalParW[0]
XDataWaveMatchStr		=	AnalParW[1]
DataFldrStr				=	AnalParW[2]
SuffixStr					=	AnalParW[3]
BinStartXVal				=	Str2Num(AnalParW[4])
BinWidthX				=	Str2Num(AnalParW[5])
NBins					=	Str2Num(AnalParW[6])
DisplayAvg				=	Str2Num(AnalParW[7])

PrintAnalPar("pt_BinXYWave")


XWList	=pt_SortWavesInFolder(XDataWaveMatchStr, GetDataFolder(-1))
YWList	=pt_SortWavesInFolder(YDataWaveMatchStr, GetDataFolder(-1))
If (ItemsInList(XWList,";")!=ItemsInList(YWList,";"))
 	Print "X and Y Waves diff in num"
 	Return (-1)
 Else
 	NumWaves=	ItemsInList(YWList,";")
EndIf

If (NumWaves<=0)
Print "NumWaves <=0. No Waves to average!!"
Return -1
EndIf

print "Binning waves...N=", NumWaves, YWList

For (i=0; i<NumWaves; i+=1)
YWaveNameStr= StringFromList (i,YWList,";")
wave wY1 = $YWaveNameStr
XWaveNameStr= StringFromList (i,XWList,";")
wave wX1 = $XWaveNameStr
EqualPoints =1
If ( NumPnts(wY1) != NumPnts(wX1)  )
Print "   "
Print "X, Y waves have different num of pnts:",  YWaveNameStr, ",",XWaveNameStr, ".WAVE NOT BINNED!!"
//Return (-1)	// instead of aborting the program can still bin the rest of the waves.
EqualPoints =0 
Else
NPnts=NumPnts(wY1)
EndIf

If (EqualPoints)

Duplicate /O wY1, wY2

Duplicate /O wX1, wX2

Sort wX2, wX2, wY2

Make /O/N=(NBins) $(YWaveNameStr+"Avg"+SuffixStr), $(YWaveNameStr+"SE"+SuffixStr)  //, $(XWaveNameStr+SuffixStr)
Wave wY3Avg=$(YWaveNameStr+"Avg"+SuffixStr)
Wave wY3SE=$(YWaveNameStr+"SE"+SuffixStr)
wY3Avg=Nan
wY3SE=Nan
SetScale /p x, (BinStartXVal+0.5*BinWidthX),BinWidthX, wY3Avg
SetScale /p x, (BinStartXVal+0.5*BinWidthX),BinWidthX, wY3SE
//Wave wX3=$(XWaveNameStr+SuffixStr)
//wX3=BinStartXVal+BinWidthX*(p+0.5)
Make /O/N=1 TempWY0
//klast =0
NPntsBinned =0
For (j=0;j<NBins;j+=1)
Make /O/N=0 TempWY
	For (k=0;k<NPnts;k+=1)
		If ( (wX2[k] >=(BinStartXVal + BinWidthX*j)  ) && (wX2[k] < (BinStartXVal + BinWidthX*(j+1)))	)
		TempWY0	=wY2[k]
		Concatenate /NP {TempWY0}, TempWY
//		klast=k
		EndIf
	EndFor
	If (NumPnts(TempWY) !=0)
	Wavestats /q TempWY
	wY3Avg[j]=V_Avg			
	wY3SE[j]=V_SDev/Sqrt(V_NPnts)	
	NPntsBinned += V_NPnts+V_numNaNs+V_numINFs
	EndIf	
EndFor
Wavestats /q wX2
// Modified pt_BinXYWave() to exclude Nans and Infs when checking if all points got binned once and only once 05/16/2009
NumNansInfs=V_numNans+V_numInfs
//Print NPntsBinned, NPnts, NumNansInfs
If (NPntsBinned > (NPnts-NumNansInfs))
Print "                                                                                  "
Print "Some pnts got binned more than once??", YWaveNameStr, XWaveNameStr
ElseIf (NPntsBinned < (NPnts-NumNansInfs))
Print "                                                                                  "
Print "Some pnts did not get binned??", YWaveNameStr, XWaveNameStr
EndIf

If (DisplayAvg)
	Display
	DoWindow pt_BinXYWaveDisplay
	If (V_Flag)
		DoWindow /F pt_BinXYWaveDisplay
//		Sleep 00:00:02
		DoWindow /K pt_BinXYWaveDisplay
	EndIf
	DoWindow /C pt_BinXYWaveDisplay
 	AppendToGraph /W=pt_BinXYWaveDisplay wY2 vs wX2
 	ModifyGraph /W=pt_BinXYWaveDisplay mode=4
 	AppendToGraph /W=pt_BinXYWaveDisplay wY3Avg
 	ModifyGraph rgb($(YWaveNameStr+"Avg"+SuffixStr))=(0,0,0)
 	ModifyGraph lsize($(YWaveNameStr+"Avg"+SuffixStr))=2
 	ErrorBars $(YWaveNameStr+"Avg"+SuffixStr) Y,wave=($(YWaveNameStr+"SE"+SuffixStr),$(YWaveNameStr+"SE"+SuffixStr))
 	ModifyGraph /W=pt_BinXYWaveDisplay mode=4
	ModifyGraph /W=pt_BinXYWaveDisplay marker($(YWaveNameStr+"Avg"+SuffixStr))=41
	DoUpdate
	Sleep /T 30
//	DoWindow pt_BinXYWaveDisplay
//	If (V_Flag)
//		DoWindow /F pt_BinXYWaveDisplay
//		Sleep 00:00:02
//		DoWindow /K pt_BinXYWaveDisplay
//	EndIf
EndIf

EndIf
EndFor
KillWaves /z wX2, wY2, TempWY0, TempWY
End


Function pt_MakeAnova2Waves()
//StatsANOVA2Test performs 2 way anova on a 3-d source wave. The columns are the levels of factor A,
//Rows are the levels of factor B and the layers are the replicates. Typically we have data in the form of 
//1D waves in which the rows are levels of one of the factors (like current or SpikeNum) and the columns
// are there for the levels of other factor (such as WT and Null). Within WT (or Null) different columns are
// replicates. This function will make a 3-D wave. Inputs are essentially to which dimension the matching 
// columns should be added.

// Example parameter wave											   
//DataWaveMatchStr	Cell_00*FC_I300pAFWHM_Avg
//ColumnNum	1
//NumRows	20
//OutNameStr	Anova2FC_IWT450Null300FWHM


String DataWaveMatchStr, OutNameStr
Variable ColumnNum, NumRows

String WList, WNameStr
Variable PreExistingWave, NumLayers, i , NumLayers0

String LastUpdatedMM_DD_YYYY="04_11_2009"

Print "*********************************************************"
Print "pt_MakeAnova2Waves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MakeAnova2Waves"+"ParNamesW")

Wave /T AnalParW		=	$("root:FuncParWaves:pt_MakeAnova2Waves"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_MakeAnova2WavesParW and/or pt_MakeAnova2WavesParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
ColumnNum				=	Str2Num(AnalParW[1])  // Levels of one of the two factors. 
												   // Levels of other factor are rows
NumRows				= 	Str2Num(AnalParW[2])										   
OutNameStr				= 	AnalParW[3]

PrintAnalPar("pt_MakeAnova2Waves")

WList	=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1))
NumLayers=ItemsInList(WList, ";")

PreExistingWave=0

If (WaveExists($OutNameStr))
PreExistingWave=1
Wave wOut= $OutNameStr
NumLayers0=DimSize(wOut, 2)
If (NumLayers0 <NumLayers)
	Redimension /N= (-1,-1, (NumLayers)) wOut
	wOut[][][NumLayers0, (NumLayers-1)]=Nan
EndIf
EndIf

// Assume all waves have same number of rows
//WNameStr=StringFromList (0,WList,";")
//NumRows=NumPnts($WNameStr)

If (!PreExistingWave)
Make /O/N=(NumRows, 2, NumLayers) $OutNameStr		// Assume 2-way anova
Wave wOut= $OutNameStr
wOut=Nan
EndIf

For (i=0; i<NumLayers; i+=1)
	WNameStr=StringFromList (i,WList,";")
	Wave w = $WNameStr
	wOut[][ColumnNum][i] = w[p]
EndFor
 
End

//****
Function pt_MakeNAnovaRW()

//READ FOLLOWING INSTRUCTIONS TO SAVE TIME
// START
// Load data table and labels table as text. Before importing labels table, add cell names column 
// to it, so that each entry in the exported data also has the cell-name field. Might need to rename
//  the Factors column (1st column in labels table) as something different. Eg. 'Factors' so that it
// isn't the same as any of the values in first column.

// To load data in Igor save them as excel first (instead of csv) and import in igor as excel file. Import in a new data folder to avoid
// conflicts.
// Choose 'Treat all columns as text option' and 'Make table' option. //
// Uncheck option 'Truncate blanks at end of table' while importing excel file to avoid getting waves of unequal length (with NA values at end)
//Rename tables as something simpler (eg. VThresh_0SpkTable, FI_ScalarParsTransposeTable)
// Edit parameters using pt_EditFuncPars("pt_MakeNAnovaRW").  pt_MakeNAnovaRW() to run.
// In order to add currents (instead of manually), generate in python as t = np.array(range(START,END+STEP,STEP)*NumCells)
// x = pd.TimeSeries(t)
// x.to_csv("/Users/taneja/Dropbox/Currents.csv")
// finally save as 'Save table copy' as csv file
//END


////Make waves for N way anova in in R.

// modified to read the data table as text. That way if missing values are specified as NA, they will
// be copied as such 04/02/2014. 
// modified from pt_MakeNAnovaRW1() so that multiple columns can be appended. 

//****
// How to use Anova in R
//dat = read.table("/Users/taneja/Work/rutlin/L4mEPSCsRoRB/FreqPks.txt", header=TRUE)
// par(mfrow = c(1,2))
// plot(FreqPksW ~ Genotyp+Age, data=dat)
//results = aov(FreqPksW ~ Genotyp + Age + Genotyp*Age, data = dat)
//summary(results)
// TukeyHSD(results, "Genotyp")
//x = x(0.409113, 0.0213438, 0.66545, 0.103195)
//p.adjust(x, method = "holm")
//****

// two tables are expected. 1st is the data table, where each column is a replicate. 2nd is the labels table in which 1st column is the names
//of the factors (eg. genotype, age, gender). remaining columns (1 per replicate) is levels for factors. 

//Input
// table 1
// Cell1 	Cell2	Cell3
//	1		0		3
//	4		2		5

//table2			
//age			24			30		24
//gender		m			f		m
//genotype	wt			wt		ko

//Output
//age		gender		genotype
//1			24			m				wt
//4			24			m				wt
//0			30			f				wt
//2			30			f				wt
//3			24			m				ko
//5			24			m				ko

//Analysis steps

//1. Use pt_EditFuncPars("pt_MakeNAnovaRW") to edit parameters
//2. pt_MakeNAnovaRW() to run the program

//Important -

//1. Text in numeric data are converted to missing data. No need to remove it beforehand. NO LONGER TRUE. DATA TABLE IS ALSO LOADED
//AS TEXT
//2. In the labels table, don't use spaces or brackets. Use underscores or CamelCase to separate words.

//Export:
//1. Save table copy as space-delimited text.

String OutDataName, DataTableName, LabelsTableName, DataWList, LabelsWList
Variable DataWListN, LabelsWListN
Variable i, j, k, NFactors, NPntsDataW, CurrNPntsFactorW

String LastUpdatedMM_DD_YYYY="01_28_2014"

Print "*********************************************************"
Print "pt_MakeNAnovaRW last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

DoAlert 1, "Make sure the columns are in the same order as the info in labels table. Continue?"
If (V_Flag ==2)
	Abort "Aborting..."
EndIf

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MakeNAnovaRW"+"ParNamesW")
Wave /T AnalParW		=	$("root:FuncParWaves:pt_MakeNAnovaRW"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_MakeNAnovaRWParW and/or pt_MakeNAnovaRWParNamesW!!!"
EndIf

DataTableName		= AnalParW[0]  // eg. InstFreq
LabelsTableName	= AnalParW[1] // eg. FI_ScalarParsTransposeTable
OutDataName	= 	AnalParW[2] // eg. InstFreq_long


PrintAnalPar("pt_MakeNAnovaRW")

DataWList= WaveList("*", ";", "WIn:"+DataTableName)		// list of names of data columns
LabelsWList= WaveList("*", ";", "WIn:"+LabelsTableName)	// list of names of labels columns

DataWListN = ItemsInList(DataWList, ";")
LabelsWListN = ItemsInList(LabelsWList, ";")
		
// LabelsTableName should have 1st column as names of labels, followed by columns corresponding
// to data columns. So LabelsWListN = 1+DataWListN


If (1+ DataWListN != LabelsWListN)
	Abort "Number of columns in labels table should be 1 more than in data column table"
EndIf

Wave /T AllFactorsW = $StringFromList(0, LabelsWList, ";")	// 1st labels column has names of all factors
NFactors = NumPnts(AllFactorsW)   

//Make /O/N=0 $OutDataName		// make an empty output wave. don't want to append to a pre-existing wave.
//Wave OutDataw = $OutDataName	// output data wave

Make /O/N=0/T $OutDataName		// make an empty output wave. don't want to append to a pre-existing wave.
Wave /T OutDataw = $OutDataName	// output data wave

// for each data column, append data to concatenated data column and also append labels for all factors. 

	For (j = 0; j < NFactors; j +=1)	// for each factor
		//If (WaveExists($AllFactorsW[ j ]) )
		Make /O/N=0/T $AllFactorsW[ j ]	// make an empty factor output wave. don't want to append to a pre-existing wave.
		Wave /T FactorW = $AllFactorsW[ j ]
		
		For (k =0; k<DataWListN; k +=1)		// for each data column
			//Wave wData = $StringFromList(k, DataWList, ";")
			Wave /T wData = $StringFromList(k, DataWList, ";") //04/02/2014
			NPntsDataW = NumPnts(wData)
			CurrNPntsFactorW = NumPnts(FactorW)
			Redimension /N=(CurrNPntsFactorW + NPntsDataW) FactorW
			Wave /T LabelsW = $StringFromList(k + 1, LabelsWList, ";")	// label corresponding to the current data wave
			FactorW[CurrNPntsFactorW, CurrNPntsFactorW + NPntsDataW - 1] = LabelsW[j]	// append label NPntsDataW times.
			Print "Appended label =",  LabelsW[j],  NPntsDataW, "times."
		EndFor
	Endfor
	Print " "
	For (k =0; k<DataWListN; k +=1)
		//Wave wData = $StringFromList(k, DataWList, ";")	
		Wave /T wData = $StringFromList(k, DataWList, ";") //04/02/2014
		//Concatenate /NP {wData}, OutDataw	// concatenate data wave
		Concatenate /T/NP {wData}, OutDataw	// concatenate data wave //04/02/2014
		Print "Appended data points =", NumPnts(wData)
	EndFor

	Edit OutDataw
	For (j = 0; j < NFactors; j +=1)
		AppendtoTable $AllFactorsW[ j ]
	EndFor
	
End
//****

//****
Function pt_MakeNAnovaRW1()
// modified so that multiple columns can be appended. From named table 1 get names of all data columns. 
// from named table 2 get all the labels.
//Make waves for N way anova in in R. 
//****
// How to use Anova in R
//dat = read.table("/Users/taneja/Work/rutlin/L4mEPSCsRoRB/FreqPks.txt", header=TRUE)
// par(mfrow = c(1,2))
// plot(FreqPksW ~ Genotyp+Age, data=dat)
//results = aov(FreqPksW ~ Genotyp + Age + Genotyp*Age, data = dat)
//summary(results)
// TukeyHSD(results, "Genotyp")
//x = x(0.409113, 0.0213438, 0.66545, 0.103195)
//p.adjust(x, method = "holm")
//****
// Given N factors with different levels (eg. GT = WT, KO; Age = p5, p7, p9), and one dependent variable (eg. Freq)
// make text waves for factors specifying levels and a numerical wave for dependent variable.
// eg. GT		Age		Freq
//	    HET		p5		0.3
//	    HET		p5		0.4
//	    KO		p5		0.5
// 	    KO		p5		0.4
//	    HET		p7		0.3
//	    HET		p7		0.4
//	    KO		p7		0.5
// 	    KO		p7		0.4

// How? Assuming the initial data is in the form p5Het, P5KO, P7Het, PKO, we can concatenate the frequency wave and label can be same for all 
// values.


String DataNamewPath, OutDataNamewPath, LabelsList, DestWList
String wStr, wLabelVal
Variable i, NLabels, NPnts, NPntswLabel

String LastUpdatedMM_DD_YYYY="10_31_2013"

Print "*********************************************************"
Print "pt_MakeNAnovaRW last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MakeNAnovaRW"+"ParNamesW")
Wave /T AnalParW		=	$("root:FuncParWaves:pt_MakeNAnovaRW"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_MakeNAnovaRWParW and/or pt_MakeNAnovaRWParNamesW!!!"
EndIf

DataNamewPath		=	AnalParW[0]
OutDataNamewPath	= 	AnalParW[1]	// this may have to be without path. Check in pt_MakeNAnovaRW above!!!!!!
LabelsList			=	AnalParW[2]
DestWList			=	AnalParW[3]

PrintAnalPar("pt_MakeNAnovaRW")

If (ItemsInList(LabelsList) != ItemsInList(DestWList))
	Abort "Number of labels is not equal to number of waves"
EndIf

NLabels = ItemsInList(LabelsList)

Wave wData = $DataNamewPath		// input data wave
NPnts = NumPnts(wData)

If (!WaveExists($OutDataNamewPath))
	Make /O/N=0 $OutDataNamewPath
EndIf
Wave OutDataw = $OutDataNamewPath	// output data wave


For (i =0; i < NLabels; i+=1)	// for each wave in DestWList, set label
	wStr = StringFromList(i, DestWList, ";")
	If (!WaveExists($wStr))
		Make /O/N=0/T $wStr
	EndIf
	Wave /T wLabel = $wStr
	NPntswLabel = NumPnts(wLabel)
	Redimension /N=(NPntswLabel + NPnts) wLabel
	wLabelVal = StringFromList(i, LabelsList, ";")
	wLabel[NPntswLabel,  NPntswLabel+ NPnts -1] =  wLabelVal
EndFor

Concatenate /NP {wData}, OutDataw
Print "Appended points =", NPnts

End
//****


Function pt_CalAnova(WaveListStr)
String WaveListStr

String WNameStr
Variable NStr, NWaves, i
NStr=ItemsInList(WaveListStr) 
NWaves = 0
For (i=0; i<NStr; i+=1)
WNameStr= StringFromList (i,WaveListStr,";")
If (StringMatch(WNameStr,"")!=1)
Wave w =$WNameStr
Duplicate /O w, $("w_"+Num2Str(i))
NWaves +=1
EndIf
EndFor


Wave w
Variable N, XMeanSqr, XSqrMean, SS
// aim: to understand anova calculations
// SS = sum of squared deviations 	= Sum( (Xi-XMean)^2) 
//								= Sum(Xi^2 + XMean^2-2*Xi*XMean) 
//								= Sum(Xi^2) + Sum(XMean^2) -2*XMean*Sum(Xi) 
//								= Sum(Xi^2) + N*XMean^2 -2*XMean*N*XMean
//								= N*Mean(Xi^2) - N*XMean^2
//								= N*(Mean(Xi^2) - XMean^2)
//given a set of numbers calculate it's SS	
//One-way anova with m levels							
Duplicate /O w,wSqr
wSqr = w^2
Wavestats /q w
XMeanSqr = (V_Avg)^2
Wavestats /q wSqr
XSqrMean = (V_Avg)
SS = V_NPnts*(XSqrMean - XMeanSqr)
Print "SS=",SS
KillWaves wSqr
End

Function /S pt_PadZeros2IntNum(Num, LenStr)
// convert a positive integer to a string Prefixed with zeros
// converted from Num2Str to Num2iStr	10/16/13
// Allowed for LenStr =0 to return original num 10/16/13
Variable Num, LenStr

String ZerosStr= ""
Variable i, NumZeros=LenStr

If (LenStr == 0)	//10/16/13
	Return Num2iStr(Num)
EndIf

For (i=0; i<LenStr; i+=1)
	If (Num<10^(i+1))
			NumZeros = LenStr-(i+1) 
			Break
	EndIf
EndFor

If (NumZeros==LenStr)
	Print "Error in pt_PadZeros2IntNum: Number > ZeroPaddedStrLength"
	Return ""
EndIf

For (i=0; i< NumZeros; i+=1)
	ZerosStr += "0"
EndFor

Return  ZerosStr+Num2iStr(Num)

End

Function pt_DoMiniAnal()

String OldEpochWName, OldEpochPrefix

String LastUpdatedMM_DD_YYYY="01_21_2009"

Print "*********************************************************"
Print "pt_DoMiniAnal last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

pt_AnalWInFldrs2("pt_ExtractMiniWAll")
pt_AnalWInFldrs2("pt_SortMinisByWaves")


Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SplitWEpochs", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_SplitWEpochs", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_SplitWEpochs!!!"
EndIf


If (WaveExists($AnalParW[2]))

OldEpochWName		=	AnalParW[4]
OldEpochPrefix			= 	AnalParW[7]

AnalParW[4]				=    "BLRange"
If (WaveExists($(AnalParW[4]+"ParW")) )
AnalParW[7]				=	"BL"
pt_AnalWInFldrs2("pt_SplitWEpochs")
Else
	Print AnalParW[4]+"ParW" + "doesn't exist"
EndIf

AnalParW[4]				=    "DrugRange"
If (WaveExists($(AnalParW[4]+"ParW")) )
AnalParW[7]				=	"Drug"
pt_AnalWInFldrs2("pt_SplitWEpochs")
Else
	Print AnalParW[4]+"ParW" + "doesn't exist"
EndIf

AnalParW[4]				=    "WashRange"
If (WaveExists($(AnalParW[4]+"ParW")) )
AnalParW[7]				=	"Wash"
pt_AnalWInFldrs2("pt_SplitWEpochs")
Else
	Print AnalParW[4]+"ParW" + "doesn't exist"
EndIf

AnalParW[4]				=   OldEpochWName
AnalParW[7]				=   OldEpochPrefix

EndIf

pt_AnalWInFldrs2("pt_KillWFrmFldrs")

End


Function pt_GenVarPar()
// For any function F whose parameters are passed as a wave W, pt_GenVarPar() allows F to be run after varying different parameters
// Execution
// access the parameter wave W for F. 
String FuncNameStr
Variable NumPar, i

String WList, DataWaveMatchStr
Variable N
String LastUpdatedMM_DD_YYYY="02_20_2009"

Print "*********************************************************"
Print "pt_GenVarPar last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_GenVarPar", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_GenVarPar", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_GenVarPar!!!"
EndIf

FuncNameStr	= AnalParW[0]

PrintAnalPar("pt_GenVarPar")


Wave /T AnalParNamesW		=	$pt_GetParWave(FuncNameStr, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(FuncNameStr, "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave,"+ FuncNameStr+"!!!"
EndIf

NumPar=NumPnts(AnalParW)
Duplicate /T/O AnalParW, OldAnalParW
Wave /T OldAnalParW = OldAnalParW

	StrSwitch(FuncNameStr)

		Case "pt_SpikeAnal":
//			vary parameters here
		Break
		Case "pt_CalBLAvg":
		Break
		Default:
			Print "Function name doesn't match functions specified in pt_GenVarPar()"
	EndSwitch	

pt_AnalWInFldrs2(FuncNameStr)

End

Function pt_ErrProp_PrcntDel(a,aDel, b, bDel, StdDevTrue)
Variable a,aDel, b, bDel, StdDevTrue
Variable PerDel, PerDelErr
// Given a+/-aDel, b+/-bDel, calculate error in percentage change z=((a-b)/b)*100
// z=f(x,y), then dz=pdx(f)*xDel + pdy(f)*yDel, where pdx, pdy are partial derivatives
// wrt x,y
// zDel=(-a/b^2)*bDel + aDel/b  This is correct. checked again on 05/11/11
PerDel = 100*(   (a/b)-1  )
// Error if aDel, bDel are absolute errors
//PerDelErr = 100*(   ((a*bDel)/b^2) + (aDel/b)   )

		
// Error if aDel, bDel are standard deviations (ie. sqrt(variance)    )
// PerDelErr= 100*(Sqrt(  ((a*bDel)/b^2)^2 			+	(aDel/b)^2		        ))	

If (StdDevTrue)
PerDelErr	 = 100*(Sqrt(  ((a*bDel)/b^2)^2 			+	(aDel/b)^2		        ))
Print "Percent change =", PerDel, "+/-", PerDelErr
Else
PerDelErr = 100*(   ((a*bDel)/b^2) 					+ (aDel/b)   				)
Print "Percent change =", PerDel, "+/-", PerDelErr
EndIf

End

Function pt_TextToBinary()

String DataWaveMatchStr, HDFolderPath
String LastUpdatedMM_DD_YYYY="07/08/2009"

String  AllListStr, ListStr, SymblkHDFolderPath, WaveStr, SaveNewWaveAs
Variable NumWaves, i

Print "*********************************************************"
Print "pt_TextToBinary last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_TextToBinary", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_TextToBinary", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_TextToBinaryParNamesW or pt_TextToBinaryParW!!!"
EndIf

DataWaveMatchStr	=AnalParW[0]
HDFolderPath		=AnalParW[1]

PrintAnalPar("pt_TextToBinary")

NewPath /O/Q/C SymblkHDFolderPath, HDFolderPath
AllListStr= IndexedFile(SymblkHDFolderPath, -1, ".txt")
ListStr = ListMatch(AllListStr, DataWaveMatchStr)
NumWaves = ItemsinList(ListStr)

For (i=0; i< NumWaves; i+=1)
	WaveStr = StringFromList(i, ListStr, ";")
	LoadWave /O/Q/A=TextToBinary/G/P=SymblkHDFolderPath WaveStr
	WaveStr=ReplaceString(".txt", WaveStr, "")
//	Rename TextToBinary0, $WaveStr
	Duplicate /O TextToBinary0, $WaveStr
	Save /C/O/P=SymblkHDFolderPath $WaveStr as (WaveStr+".ibw")
	KillWaves  TextToBinary0, $WaveStr
EndFor

Print "pt_TextToBinary: Converted waves, N= ", i	
KillPath SymblkHDFolderPath

End

Function pt_ElectroPhysWaveGen()
// To generate one wave typically for electrophysiology use

String OutWNameStr, StartEndValsList
Variable DCValue, YGain, XOffset, XDelta, XLength, NSegments, StartX1Val, StartY1Val, EndX1Val, EndY1Val, DisplayOutW	

Variable NVals, NPnts, i, x1, x2, y1, y2, m
String LastUpdatedMM_DD_YYYY="07/24/2009"

Print "*********************************************************"
Print "pt_ElectroPhysWaveGen last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ElectroPhysWaveGen", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_ElectroPhysWaveGen", "ParW")

OutWNameStr	= AnalParW[0]
DCValue		   	= Str2Num(AnalParW[1])
YGain			= Str2Num(AnalParW[2])
XOffset			= Str2Num(AnalParW[3])
XDelta			= Str2Num(AnalParW[4])
XLength			= Str2Num(AnalParW[5])
DisplayOutW		= Str2Num(AnalParW[6])
NSegments		= Str2Num(AnalParW[7])
StartEndValsList = AnalParW[8] 			// StartX1Val; StartY1Val; EndX1Val; EndY1Val

NVals = ItemsInList(StartEndValsList, ";")

// check that 
If (4*NSegments != NVals)
	Abort "N values in StartEndValsList should be equal to 4*NSegments (x1,y1,x2,y2)"	
Else
NPnts=round(XLength/XDelta)
Make /O/N=(NPnts) $(OutWNameStr)
Wave w = $(OutWNameStr)
w = 0
w = w+DCValue
SetScale /P X, XOffset, XDelta, w
If (DisplayOutW)
	Display w
EndIf
For (i=0; i<(NVals-1); i+=4)
	x1=Str2Num(StringFromList(i,StartEndValsList,";"))
	y1=Str2Num(StringFromList(i+1,StartEndValsList,";"))
	x2=Str2Num(StringFromList(i+2,StartEndValsList,";"))
	y2=Str2Num(StringFromList(i+3,StartEndValsList,";"))
	
	If (y1==y2) // DC Step
		w[x2pnt(w, x1), x2pnt(w, x2)]=y1
	Else	   // Ramp
		m= (y2-y1)/(x2-x1)
		w[x2pnt(w, x1), x2pnt(w, x2)]=m*(pnt2x(w, p)-x1)+y1
	EndIf
	
EndFor
w*=YGain
EndIf
End

Function pt_KillAllGraphWin(N1,N2)
Variable N1,N2
//"Use pt_KillAllGraphWin(N) to kill graphs from N1 to N2" Last Updated 11/12/2010
String KillWinName
Variable i
For (i=N1;i<=N2;i+=1)
KillWinName = "Graph"+Num2Str(i)
DoWindow $KillWinName
If (V_Flag)
	DoWindow /K $KillWinName
	Print "Killed window", KillWinName
EndIf
EndFor
End


Function pt_ExtractFromWaveNote()

// This is always the latest version
// Basic structure based on pt_CalPeak

String DataWaveMatchStr, DataFldrStr, KeyStrName, ParIsStr, OutWNameStr
String WList, WNameStr, WNoteStr
Variable NumWaves, i



String LastUpdatedMM_DD_YYYY=" 06/13/11"

Print "*********************************************************"
Print "pt_ExtractFromWaveNote last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractFromWaveNote", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractFromWaveNote", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_ExtractFromWaveNoteParW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
KeyStrName			=	AnalParW[2]
ParIsStr				= 	AnalParW[3]
OutWNameStr			=	AnalParW[4]

PrintAnalPar("pt_ExtractFromWaveNote")	// 07/18/2007

If (!Str2Num(ParIsStr))
Make /O/N=0 	$(OutWNameStr)	
Make /O/N=1 	$(OutWNameStr+"Temp")
Wave OutW			=	$(OutWNameStr)	
Wave OutWTemp			=	$(OutWNameStr+"Temp")
Else
Make /O/N=0/T 			$(OutWNameStr)	
Make /O/N=1/T 			$(OutWNameStr+"Temp")
Wave /T 	OutTextW		=	$(OutWNameStr)	
Wave /T 	OutTextWTemp	=	$(OutWNameStr+"Temp")
EndIf

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

Print "Extracting parameter from waves, N =", Numwaves, WList

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	WNoteStr = Note($(GetDataFolder(1)+DataFldrStr+WNameStr))
	If (!Str2Num(ParIsStr))
//	OutWTemp[0] = Str2Num(StringByKey("Stim Amp.",WNoteStr))	corrected 06/13/11
	OutWTemp[0] = Str2Num(StringByKey(KeyStrName,WNoteStr))
	Concatenate /NP {OutWTemp}, OutW
	Else
//	OutTextWTemp[0] = StringByKey("Stim Amp.",WNoteStr)	corrected 06/13/11
	OutTextWTemp[0] = StringByKey(KeyStrName,WNoteStr)		
	Concatenate /T/NP {OutTextWTemp}, OutTextW
	EndIf
EndFor	 	
Killwaves	/Z OutWTemp, OutTextWTemp
End

Function pt_SaveWSubset()
// PLEASE EDIT CRITERIA TO SELECT FILES TO SAVE MANUALLY IN THE PROCEDURE

// This is always the latest version
// Basic structure based on pt_SaveWSubset. Save a subset of waves satisfying a certain criteria of the extracted paramerter
// to disk. Eg. we recorded waves every 50pA but we want to analyze only every 100 pA then following would work

//If (mod(OutWTemp,100e-12) ==0)
//	Save /O $(GetDataFolder(1)+DataFldrStr+WNameStr) as "H:Core Labs:Electrophysiology:PraveenT:MuckeLab:Dravet:FI_L5A_Pyramidal:SubSetFI:" + WNameStr+".ibw"/
//EndIf

String DataWaveMatchStr, DataFldrStr, KeyStrName, ParIsStr, OutWNameStr, HDSaveFldrPathW
String WList, WNameStr, WNoteStr
Variable NumWaves, i, TotSaved

DoAlert 0, "Have you manually edited the saving criteria in pt_SaveWSubset() function?"
Print "Criterion = Save If (mod(OutWTemp[0]*1e10,1) <0.1)	"

String LastUpdatedMM_DD_YYYY=" 06/13/11"

Print "*********************************************************"
Print "pt_SaveWSubset last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SaveWSubset", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW			=	$pt_GetParWave("pt_SaveWSubset", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_SaveWSubsetParW!!!"
EndIf

DataWaveMatchStr	=	AnalParW[0]
DataFldrStr			=	AnalParW[1]
KeyStrName			=	AnalParW[2]
ParIsStr				= 	AnalParW[3]
OutWNameStr		=	AnalParW[4]
HDSaveFldrPathW	= 	AnalParW[5]

PrintAnalPar("pt_SaveWSubset")	// 07/18/2007


If (!Str2Num(ParIsStr))
Make /O/N=0 	$(OutWNameStr)	
Make /O/N=1 	$(OutWNameStr+"Temp")
Wave OutW			=	$(OutWNameStr)	
Wave OutWTemp			=	$(OutWNameStr+"Temp")
Else
Make /O/N=0/T 			$(OutWNameStr)	
Make /O/N=1/T 			$(OutWNameStr+"Temp")
Wave /T 	OutTextW		=	$(OutWNameStr)	
Wave /T 	OutTextWTemp	=	$(OutWNameStr+"Temp")
EndIf

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

Print "Extracting parameter from waves and saving waves, N =", Numwaves, WList


TotSaved = 0
For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	WNoteStr = Note($(GetDataFolder(1)+DataFldrStr+WNameStr))
	If (!Str2Num(ParIsStr))
//	OutWTemp[0] = Str2Num(StringByKey("Stim Amp.",WNoteStr))	corrected 06/13/11
	OutWTemp[0] = Str2Num(StringByKey(KeyStrName,WNoteStr))
	Concatenate /NP {OutWTemp}, OutW
	//*****
	//mod doesn't always work properly for fractions
	//print mod(6E-10, 1e-10) = 1e-10

	//convert to integers first
	//print round(mod(6E-10*1e11, 10)) = 0
	//******

	If (mod(Round(OutWTemp[0]*1e11),10) <1)		
		Print "Saved", OutWTemp[0]
		Save /O $(GetDataFolder(1)+DataFldrStr+WNameStr) as HDSaveFldrPathW + WNameStr+".ibw"
		TotSaved +=1
	Else
		Print "NotSaved", OutWTemp[0]//, Round(OutWTemp[0]*1e11), mod(Round(OutWTemp[0]*1e11),10)
	EndIf
	Else
//	OutTextWTemp[0] = StringByKey("Stim Amp.",WNoteStr)	corrected 06/13/11
	OutTextWTemp[0] = StringByKey(KeyStrName,WNoteStr)		
	Concatenate /T/NP {OutTextWTemp}, OutTextW
	EndIf
EndFor
Print "Total waves saved =", TotSaved	 	
Killwaves	/Z OutWTemp, OutTextWTemp
End

Function pt_RandomiseTreatments(NumExptUnits, NumTreatments)
Variable NumExptUnits, NumTreatments
// UNFINISHED

// Given Total number of Experimental Units and Number of Treatments, this program assigns the experimental units to treatments in a random manner
// such that there are roughly equal number or units per treatment

Variable UnitsPerTreatment = floor(NumExptUnits/ NumTreatments)
Variable ReminderUnits	= mod(NumExptUnits, NumTreatments)
Variable i


For (i=0; i<NumTreatments; i+=1)
	Make /O/N=(UnitsPerTreatment)  $("Treatment_"+(Num2Str(i)   ))
	Wave Treatment = $("Treatment_"+(Num2Str(i)   ))
EndFor

End

Function pt_ExtractRepsNSrt()
// Allowing for sorted key wave and par wave to have a user defined outname (in case used with different repeats, etc.)
// This function can be used to separate repeats and sort the values. 
// Eg. if you have 2 repeats of FI curves acquired with randomized currents, then this function can be used
// to generate two FI repeats with values sorted based on the currents.

// inputs - wave to be sorted, sort value wave, Start value, PntsPerRep, NumReps.  

String SortKeyWName, SortParWName, RangeW, RangeWPrefixStr, SortKeyOutWName, SortParOutWName
Variable PntsPerRep, StartPnt, NumReps

Variable i, SortKeyStartVal, SortKeyDelVal,j

String LastUpdatedMM_DD_YYYY=" 01/01/2012", DoAlertStr

Print "*********************************************************"
Print "pt_ExtractRepsNSrt last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractRepsNSrt", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractRepsNSrt", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_ExtractRepsNSrt!!!"
EndIf

//DataWaveMatchStr		=	AnalParW[0]
//DataFldrStr				=	AnalParW[1]
SortKeyWName			= 	AnalParW[0]
SortParWName			= 	AnalParW[1]
RangeW					=	AnalParW[2]
RangeWPrefixStr		=	AnalParW[3]
SortKeyOutWName		= 	AnalParW[4]
SortParOutWName		= 	AnalParW[5]

If (StringMatch(RangeWPrefixStr, "DataFldrName"))
	RangeW	= GetDataFolder(0)+RangeW
Else
	RangeW	= RangeWPrefixStr+RangeW
EndIf


PrintAnalPar("pt_ExtractRepsNSrt")

Wave /T AnalParNamesW	=	$pt_GetParWave(RangeW, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(RangeW, "ParW")

PntsPerRep				=	Str2Num(AnalParW[0])
StartPnt				=	Str2Num(AnalParW[1])	// Start Pnt of first repeat counting from 1.
NumReps				=	Str2Num(AnalParW[2])
SortKeyStartVal			= 	Str2Num(AnalParW[3])
SortKeyDelVal			= 	Str2Num(AnalParW[4])

If (StartPnt==0)
//	Abort "StartPnt should be >0"
	Print "******StartPnt should be >0!!. Nothing analyzed****** "
	Return 1
EndIf

PrintAnalPar(RangeW)

Wave SortKeyW		= $(SortKeyWName)
Wave SortParW 	= $(SortParWName)

If (StringMatch(SortKeyOutWName,""))
SortKeyOutWName = SortKeyWName
EndIf

If (StringMatch(SortParOutWName,""))
SortParOutWName = SortParWName
EndIf

If (PntsPerRep*NumReps!=0)
For (i=0;i<(NumReps);i+=1)
	Print "Duplicating and sorting points from (counting from zero)", StartPnt-1+i*PntsPerRep,"to", StartPnt-1+(i+1)*PntsPerRep-1
	Duplicate /O /R=(StartPnt-1+i*PntsPerRep, StartPnt-1+(i+1)*PntsPerRep-1) SortKeyW, 	$(SortKeyOutWName+Num2Str(i)+"Srt"	)
	Duplicate /O /R=(StartPnt-1+i*PntsPerRep, StartPnt-1+(i+1)*PntsPerRep-1) SortParW, 	$(SortParOutWName+Num2Str(i)+"Srt"	)
	Sort $(SortKeyOutWName+Num2Str(i)+"Srt"	), $(SortKeyOutWName+Num2Str(i)+"Srt"	), 	$(SortParOutWName+Num2Str(i)+"Srt"	)
	Wave XWave = $(SortKeyOutWName+Num2Str(i)+"Srt"	)
	Wave SortParWSrti=$(SortParOutWName+Num2Str(i)+"Srt"	)
//	XOffSet	= XWave[0]
//	XDelta   = XWave[1]-XWave[0]
	Print "****************"
	Print "XOffset =", SortKeyStartVal
	Print "XDelta  =", SortKeyDelVal
	Print "****************"
	SetScale /P 	x, 0, 1, XWave		// set the x-scaling for x-wave 11_12_13
	SetScale /P 	x, SortKeyStartVal, SortKeyDelVal, SortParWSrti	
// If KeyVals are random and if whole sequence is not scanned, some KeyVals will be missing.
//	NMissingKeyVals =0
	For (j=0; j<PntsPerRep;j+=1)
		If (	(XWave[j]-(SortKeyStartVal+j*SortKeyDelVal)	) > 0.5*SortKeyDelVal)
			InsertPoints j,1, XWave, SortParWSrti
			XWave[j]			= Nan
			SortParWSrti[j]	= Nan
			DoAlertStr			= "Missing value "+Num2Str(SortKeyStartVal+j*SortKeyDelVal)+" in "+ SortKeyWName+Num2Str(i)+"Srt"
			//DoAlert 0, DoAlertStr	
			Print DoAlertStr
//			NMissingKeyVals	+=1
		EndIf
	EndFor	
//	DeletePoints PntsPerRep, NumPnts(), XWave, SortParWSrti
EndFor

Else 
Print "Attention! Either PntsPerRep OR NumReps =0!!! No Wave Generated"	
EndIf
End

//&&&&&&&&&&&&&&&&&&&&&&&&&
Function pt_ExtractWRepsNSrt()

// This is always the latest version.

// Sort was giving problem (in compatible wavelengths) as WNameWavej had more traces than SortKeyWSrtj 
// when some traces were missing from a repeat. Fixed that 12/28/14
// also generate waves averaged over repeats. 11/14/13
//In this newer version if some values are missing, empty waves are generated instead of completely skipping the cell. 01/11/12
// Modified, such that Instead of doing one SortParWName we can have a list of parameters that can be extracted and sorted 01_01_2011
// Based on pt_ExtractRepsNSrt() except that pt_ExtractWRepsNSrt() extracts and sorts waves instead of Scalars.

// This function can be used to separate repeats and sort Waves. 
// Eg. if you have 2 repeats of FI curves acquired with randomized currents, and using pt_SpikeAnal you have SpikeWidths (a vector for a single current injection)
// and many of these vectors corresponding to different current injections.  pt_ExtractWRepsNSrt() will generate new waves whose wavenames will reflect the current
// injection values and also an index corresponsing to the repeat.

// inputs - wave to be sorted, sort value wave, Start value, PntsPerRep, NumReps.  
// logic
// We have 44 waves. each wave has some spike parameter like spike times. We also have the current wave with 44 currents.
// Also we know that 1st FI curve starts at 3rd wave, has 21 points, and 2nd Fi curve starts follows the end of 1st FI curve.
// We need to pick out from the 42 waves 2 sets of 21 waves and these 2 pairs of 21 waves need to be duplicated so that each has
// the current value in the name and the repeat number in the name. That way we can average the repates for a given current and
// look at the spike times for any current.
// We first take the current wave and generate 2 current waves that start at 3rd point and carry the 2 current sequences.
// We make a list of the names of the 44 waves, convert the list to a text wave, and separate that into 2 text waves carrying the names
// of the waves in the sequence they were acquired. 
// now we generate 2 text waves that are sorted based on the corresponding current wave. Then we take the sorted text wave and duplicate that
// wave with proper current and repeat number. 
//NB we need to separete into 2 waves before sorting else sorting will not be able to distininguish 1st repeat from 2nd

String SortKeyWName, SortParWList, SubFldrList, RangeW, RangeWPrefixStr
Variable PntsPerRep, StartPnt, NumReps, SortKeyStartVal, SortKeyDelVal

Variable i, j, NPnts, PntsPerRep1, NSortParWList, NSubFldrList,k//, Numwaves//, XOffset, XDelta
Variable NWList //12/28/14

String LastUpdatedMM_DD_YYYY=" 01/01/2011", WList, WListAll, NewWName, DoAlertStr, SortParWName, SubFldr

Print "*********************************************************"
Print "pt_ExtractWRepsNSrt last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_ExtractWRepsNSrt!!!"
EndIf

//DataWaveMatchStr		=	AnalParW[0]
//DataFldrStr				=	AnalParW[1]
SortKeyWName			= 	AnalParW[0]
//SortParWName		= 	AnalParW[1]
SortParWList			= 	AnalParW[1]		// more than 1 pars can be analyzed. It's a list
SubFldrList				= 	AnalParW[2]		// more than 1 pars can be analyzed. It's a list
RangeW					=	AnalParW[3]
RangeWPrefixStr		=	AnalParW[4]

If (StringMatch(RangeWPrefixStr, "DataFldrName"))
	RangeW	= GetDataFolder(0)+RangeW
Else
	RangeW	= RangeWPrefixStr+RangeW
EndIf


PrintAnalPar("pt_ExtractWRepsNSrt")

Wave /T AnalParNamesW	=	$pt_GetParWave(RangeW, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(RangeW, "ParW")

PntsPerRep				=	Str2Num(AnalParW[0])
StartPnt				=	Str2Num(AnalParW[1])	// Start Pnt of first repeat counting from 1.
NumReps				=	Str2Num(AnalParW[2])
SortKeyStartVal			= 	Str2Num(AnalParW[3])
SortKeyDelVal			= 	Str2Num(AnalParW[4])

If (StartPnt==0)				// StartPnt counts from 1 and not 0.
//	DoAlert 1, "StartPnt should not be =0!!. Assume StartPnt =1 and continue?"
//	If (V_Flag )
//		StartPnt=1
//	Else
	Print "******StartPnt should be >0!!. Nothing analyzed****** "
	Return 1
//	Abort
EndIf

NSortParWList	= ItemsInList(SortParWList)
NSubFldrList	= ItemsInList(SubFldrList)


If (		NSortParWList != NSubFldrList		)
DoAlertStr = "Items in SortParWList = "+Num2Str(NSortParWList)+" is not equal to Items in SubFldrList "+Num2Str(NSubFldrList)+ ". Aborting!"
DoAlert 0, DoAlertStr
Abort
Else
Print "Analyzing ParW, N= ", NSortParWList
EndIf


PrintAnalPar(RangeW)

Wave SortKeyW	= $(SortKeyWName)
//Wave SortParW 	= $(SortParWName)

NPnts = NumReps*PntsPerRep

If (NPnts!=0)

For (k=0; k<NSortParWList; k+=1)	// j = index for repeats, i = index for pnts within a repeat, k = index for number of parameters
SortParWName	= StringFromList(k,SortParWList,";")
SubFldr 		= StringFromList(k,SubFldrList,";")
Print "********************************************"
Print "Analyzing ParW =", SortParWName, "in SubFolder =", SubFldr
Print "********************************************"

// Generating RepeatNum text waves that will carry the names of the waves in the sequence they were acquired.
WListAll=pt_SortWavesInFolder(SortParWName+"*", GetDataFolder(1)+SubFldr)	// j = index for repeats, i = index for pnts within a repeat, k = index for number of parameters
Print "Total # of waves =", ItemsInList(WListAll)
print WListAll
Print "										"

For (j=0;j<NumReps; j+=1)
	WList=""
	For (i=0;i<PntsPerRep; i+=1)
	If  (  (i+StartPnt-1+j*PntsPerRep) > (ItemsInList(WListAll) -1)  )
	DoAlertStr = "In repeat "+Num2Str(j+1)+" number of waves starting from StartPnt "+Num2Str(StartPnt)+" is less than "+Num2Str(PntsPerRep)//+" . Skipping this cell!"
//	DoAlert 0, DoAlertStr
	Print DoAlertStr
//	Return 0
	//$//EndIf 12/28/14. 
	Else
	WList += StringFromList(i+StartPnt-1+j*PntsPerRep,WListAll, ";")+";"
	EndIf
//	For (i=StartPnt-1;i<(StartPnt-1+NPnts);i+=1)
//	WList = StringFromList(i,WListAll, ";")                                                                                                                                 
	EndFor
Print "# of waves repeat in repeat",j,"=", ItemsInList(WList)
//Print "# of waves repeat in repeat",j+1,"=", ItemsInList(WList)	// 01/11/12
Print WList
Print "	 "
	NWList = ItemsInList(WList)	// 12/28/14					"	
	//For (i=0;i<PntsPerRep; i+=1)
	For (i=0;i<NWList; i+=1)
	//Make /T/O/N=(PntsPerRep) $(GetDataFolder(1)+SubFldr+"WNameWave"+Num2Str( j ))
	Make /T/O/N=(NWList) $(GetDataFolder(1)+SubFldr+"WNameWave"+Num2Str( j ))
	Wave /T WNameWavej = 	$(GetDataFolder(1)+SubFldr+"WNameWave"+Num2Str( j ))
	
	WNameWavej[i] =  StringFromList(i, WList, ";")	
	
	EndFor
	
EndFor

// Generating RepeatNum SortKeyWaves that will carry the values in the sequence they were acquired.
For (j=0;j<NumReps; j+=1)
Duplicate /O /R=(StartPnt-1+j*PntsPerRep, StartPnt-1+(j+1)*PntsPerRep-1) SortKeyW, $(GetDataFolder(1)+SubFldr+"SortKeyWSrt"+Num2Str( j ))	
EndFor

//Make /T/O/N=(NPnts) WNameWave	// Text wave with  entries as names of all the waves StartPnt-1+i*PntsPerRep, StartPnt-1+(i+1)*PntsPerRep-1
//For (i=0;i<(NPnts);i+=1)
//	WNameWave[i] =  StringFromList(i, WList, ";")
//EndFor

// Now sort the WNameWaves based on the SortKeyWSrt waves
For (j=0;j<NumReps; j+=1)
Wave 		SortKeyWSrtj 	= $(GetDataFolder(1)+SubFldr+"SortKeyWSrt"+Num2Str( j ))	
Wave /T 	WNameWavej 	= $(GetDataFolder(1)+SubFldr+"WNameWave"+Num2Str( j ))
Sort SortKeyWSrtj , SortKeyWSrtj,  WNameWavej	// SortKeyWSrt = sorted SortKeyW
EndFor


// Now duplicate the waves with wavenames from sorted text waves and name them with proper current and repeat index.
For (j=0;j<(NumReps);j+=1)
//	Print "Duplicating and sorting waves from (counting from zero)", StartPnt-1+i*PntsPerRep,"to", StartPnt-1+(i+1)*PntsPerRep-1
	Wave 		SortKeyWSrtj 	= $(GetDataFolder(1)+SubFldr+"SortKeyWSrt"+Num2Str( j ))	
	Wave /T 	WNameWavej 	= $(GetDataFolder(1)+SubFldr+"WNameWave"+Num2Str( j ))
	PntsPerRep1 = PntsPerRep
	For (i=0; i<PntsPerRep1; i+=1)
// Not using current value in name of wave because then the sorted wavenames is not in same sequence as SortKeyWSrt !!	12/28/2010
//	NewWName = "S"+SortParWName+pt_ConvertNumStr2NameStr(Num2Str(SortKeyWSrtj[ i ]))+"_"+Num2Str( j )
	NewWName = "S"+SortParWName+Num2Str(i )+"_"+Num2Str( j )	
//	Print "SortKeyW =",SortKeyWSrtj[ i ], "for", WNameWavej[i],". Duplicated to", NewWName 
//	Print GetDataFolder(-1)+SubFldr+WNameWavej[i], GetDataFolder(-1)+SubFldr+NewWName
	If (	(SortKeyWSrtj[ i ] - (SortKeyStartVal+i*SortKeyDelVal)	) > 0.5*SortKeyDelVal)	// missing point
	InsertPoints i,1, SortKeyWSrtj, WNameWavej
	SortKeyWSrtj[i] = Nan
	WNameWavej[i] = ""
	Make /O/N=0 $(GetDataFolder(1)+SubFldr+NewWName )
	DoAlertStr = "Missing value "+Num2Str(SortKeyStartVal+i*SortKeyDelVal)+" in "+ SortKeyWName+Num2Str(j)+"Srt"
	//DoAlert 0, DoAlertStr	
	Print DoAlertStr
	//PntsPerRep1 +=1  //12/28/14
	Else
//	Duplicate /O $(GetDataFolder(1)+SubFldr+WNameWavej[i]), $(GetDataFolder(1)+SubFldr+NewWName )
	Duplicate /O $(GetDataFolder(1)+SubFldr+WNameWavej[i]), $(GetDataFolder(1)+SubFldr+NewWName )
	EndIf
	If (k==0) // Print only for 1st Par
	Print "SortKeyW =",SortKeyWSrtj[ i ], "for", WNameWavej[i],". Duplicated to", NewWName
	EndIf
	EndFor
	Print "											"
	KillWaves /Z WNameWavej
EndFor
//***11/14/13
// also generate waves averaged over repeats. eg. if 16 points and 3 repeats each, generate 16 waves where each wave is average of 3 repeats. 
// How? we can use pt_AverageWaves and call it 16 times.
//pt_AnalWInFldrs2("pt_AverageWaves")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")

//SaveNRestore("pt_AverageWaves", 1) // Can't use as the calling function in pt_FIAnalysis is also using save and restore 11/14/13

Duplicate /T/O AnalParW, AnalParWOrig	

AnalParW[1]	=	SubFldr	//DataFldrStr
AnalParW[3]	=	"1"			//PntsPerBin
AnalParW[4]	=	""			//ExcludeWNamesWStr
AnalParW[5]	=	"0"			//DisplayAvg

For (i=0;i<PntsPerRep; i+=1)
	AnalParW[0]	=	"S"+SortParWName+Num2Str(i )+"_*"	//DataWaveMatchStr
	AnalParW[2]	=	"A"+SortParWName+Num2Str(i )						//BaseNameStr
	pt_AverageWaves()
EndFor

Duplicate /T/O AnalParWOrig, AnalParW
KillWaves AnalParWOrig

//***11/14/13

EndFor	//index k; SortParWList
Else 
Print "Attention! Either PntsPerRep OR NumReps =0!!! No Wave Generated"	
EndIf

End
//&&&&&&&&&&&&&&&&&&&&&&&&&
Function pt_ExtractWRepsNSrt1()

// This is older version. In newer version if some values are missing, empty waves are generated instead of completely skipping the cell. 01/11/12

// Modified, such that Instead of doing one SortParWName we can have a list of parameters that can be extracted and sorted 01_01_2011
// Based on pt_ExtractRepsNSrt() except that pt_ExtractWRepsNSrt() extracts and sorts waves instead of Scalars.

// This function can be used to separate repeats and sort Waves. 
// Eg. if you have 2 repeats of FI curves acquired with randomized currents, and using pt_SpikeAnal you have SpikeWidths (a vector for a single current injection)
// and many of these vectors corresponding to different current injections.  pt_ExtractWRepsNSrt() will generate new waves whose wavenames will reflect the current
// injection values and also an index corresponsing to the repeat.

// inputs - wave to be sorted, sort value wave, Start value, PntsPerRep, NumReps.  
// logic
// We have 44 waves. each wave has some spike parameter like spike times. We also have the current wave with 44 currents.
// Also we know that 1st FI curve starts at 3rd wave, has 21 points, and 2nd Fi curve starts follows the end of 1st FI curve.
// We need to pick out from the 43 waves 2 sets of 21 waves and these 2 pairs of 21 waves need to be duplicated so that each has
// the current value in the name and the repeat number in the name. That way we can average the repates for a given current and
// look at the spike times for any current.
// We first take the current wave and generate 2 current waves that start at 3rd point and carry the 2 current sequences.
// We make a list of the names of the 44 waves, convert the list to a text wave, and separate that into 2 text waves carrying the names
// of the waves in the sequence they were acquired. 
// now we generate 2 text waves that are sorted based on the corresponding current wave. Then we take the sorted text wave and duplicate that
// wave with proper current and repeat number. 
//NB we need to separete into 2 waves before sorting else sorting will not be able to distininguish 1st repeat from 2nd

String SortKeyWName, SortParWList, SubFldrList, RangeW, RangeWPrefixStr
Variable PntsPerRep, StartPnt, NumReps, SortKeyStartVal, SortKeyDelVal

Variable i, j, NPnts, PntsPerRep1, NSortParWList, NSubFldrList,k//, Numwaves//, XOffset, XDelta

String LastUpdatedMM_DD_YYYY=" 01/01/2011", WList, WListAll, NewWName, DoAlertStr, SortParWName, SubFldr

Print "*********************************************************"
Print "pt_ExtractWRepsNSrt last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_ExtractWRepsNSrt!!!"
EndIf

//DataWaveMatchStr		=	AnalParW[0]
//DataFldrStr				=	AnalParW[1]
SortKeyWName			= 	AnalParW[0]
//SortParWName			= 	AnalParW[1]
SortParWList			= 	AnalParW[1]
SubFldrList				= 	AnalParW[2]
RangeW					=	AnalParW[3]
RangeWPrefixStr		=	AnalParW[4]

If (StringMatch(RangeWPrefixStr, "DataFldrName"))
	RangeW	= GetDataFolder(0)+RangeW
Else
	RangeW	= RangeWPrefixStr+RangeW
EndIf


PrintAnalPar("pt_ExtractWRepsNSrt")

Wave /T AnalParNamesW	=	$pt_GetParWave(RangeW, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(RangeW, "ParW")

PntsPerRep				=	Str2Num(AnalParW[0])
StartPnt				=	Str2Num(AnalParW[1])	// Start Pnt of first repeat counting from 1.
NumReps				=	Str2Num(AnalParW[2])
SortKeyStartVal			= 	Str2Num(AnalParW[3])
SortKeyDelVal			= 	Str2Num(AnalParW[4])

If (StartPnt==0)				// StartPnt counts from 1 and not 0.
//	DoAlert 1, "StartPnt should not be =0!!. Assume StartPnt =1 and continue?"
//	If (V_Flag )
//		StartPnt=1
//	Else
	Print "******StartPnt should be >0!!. Nothing analyzed****** "
	Return 1
//	Abort
EndIf

NSortParWList	= ItemsInList(SortParWList)
NSubFldrList	= ItemsInList(SubFldrList)


If (		NSortParWList != NSubFldrList		)
DoAlertStr = "Items in SortParWList = "+Num2Str(NSortParWList)+" is not equal to Items in SubFldrList "+Num2Str(NSubFldrList)+ ". Aborting!"
DoAlert 0, DoAlertStr
Abort
Else
Print "Analyzing ParW, N= ", NSortParWList
EndIf


PrintAnalPar(RangeW)

Wave SortKeyW	= $(SortKeyWName)
//Wave SortParW 	= $(SortParWName)

NPnts = NumReps*PntsPerRep

If (NPnts!=0)

For (k=0; k<NSortParWList; k+=1)	// j = index for repeats, i = index for pnts within a repeat, k = index for number of parameters
SortParWName	= StringFromList(k,SortParWList,";")
SubFldr 		= StringFromList(k,SubFldrList,";")
Print "********************************************"
Print "Analyzing ParW =", SortParWName, "in SubFolder =", SubFldr
Print "********************************************"

// Generating RepeatNum text waves that will carry the names of the waves in the sequence they were acquired.
WListAll=pt_SortWavesInFolder(SortParWName+"*", GetDataFolder(1)+SubFldr)	// j = index for repeats, i = index for pnts within a repeat, k = index for number of parameters
Print "Total # of waves =", ItemsInList(WListAll)
Print "										"

For (j=0;j<NumReps; j+=1)
	WList=""
	For (i=0;i<PntsPerRep; i+=1)
	If  (  (i+StartPnt-1+j*PntsPerRep) > (ItemsInList(WListAll) -1)  )
	DoAlertStr = "In repeat "+Num2Str(j+1)+" number of waves starting from StartPnt "+Num2Str(StartPnt)+" is less than "+Num2Str(PntsPerRep)+" . Skipping this cell!"
	DoAlert 0, DoAlertStr
	Return 0
	EndIf
	WList += StringFromList(i+StartPnt-1+j*PntsPerRep,WListAll, ";")+";"
//	For (i=StartPnt-1;i<(StartPnt-1+NPnts);i+=1)
//	WList = StringFromList(i,WListAll, ";")                                                                                                                                 
	EndFor
Print "# of waves repeat in repeat",j,"=", ItemsInList(WList)
Print "										"	
	For (i=0;i<PntsPerRep; i+=1)
	Make /T/O/N=(PntsPerRep) $(GetDataFolder(1)+SubFldr+"WNameWave"+Num2Str( j ))
	Wave /T WNameWavej = 	$(GetDataFolder(1)+SubFldr+"WNameWave"+Num2Str( j ))
	WNameWavej[i] =  StringFromList(i, WList, ";")
	EndFor
	
EndFor

// Generating RepeatNum SortKeyWaves that will carry the values in the sequence they were acquired.
For (j=0;j<NumReps; j+=1)
Duplicate /O /R=(StartPnt-1+j*PntsPerRep, StartPnt-1+(j+1)*PntsPerRep-1) SortKeyW, $(GetDataFolder(1)+SubFldr+"SortKeyWSrt"+Num2Str( j ))	
EndFor

//Make /T/O/N=(NPnts) WNameWave	// Text wave with  entries as names of all the waves StartPnt-1+i*PntsPerRep, StartPnt-1+(i+1)*PntsPerRep-1
//For (i=0;i<(NPnts);i+=1)
//	WNameWave[i] =  StringFromList(i, WList, ";")
//EndFor

// Now sort the WNameWaves based on the SortKeyWSrt waves
For (j=0;j<NumReps; j+=1)
Wave 		SortKeyWSrtj 	= $(GetDataFolder(1)+SubFldr+"SortKeyWSrt"+Num2Str( j ))	
Wave /T 	WNameWavej 	= $(GetDataFolder(1)+SubFldr+"WNameWave"+Num2Str( j ))
Sort SortKeyWSrtj , SortKeyWSrtj,  WNameWavej	// SortKeyWSrt = sorted SortKeyW
EndFor

// Now duplicate the waves with wavenames from sorted text waves and name them with proper current and repeat index.
For (j=0;j<(NumReps);j+=1)
//	Print "Duplicating and sorting waves from (counting from zero)", StartPnt-1+i*PntsPerRep,"to", StartPnt-1+(i+1)*PntsPerRep-1
	Wave 		SortKeyWSrtj 	= $(GetDataFolder(1)+SubFldr+"SortKeyWSrt"+Num2Str( j ))	
	Wave /T 	WNameWavej 	= $(GetDataFolder(1)+SubFldr+"WNameWave"+Num2Str( j ))
	PntsPerRep1 = PntsPerRep
	For (i=0; i<PntsPerRep1; i+=1)
// Not using current value in name of wave because then the sorted wavenames is not in same sequence as SortKeyWSrt !!	12/28/2010
//	NewWName = "S"+SortParWName+pt_ConvertNumStr2NameStr(Num2Str(SortKeyWSrtj[ i ]))+"_"+Num2Str( j )
	NewWName = "S"+SortParWName+Num2Str(i )+"_"+Num2Str( j )	
//	Print "SortKeyW =",SortKeyWSrtj[ i ], "for", WNameWavej[i],". Duplicated to", NewWName 
//	Print GetDataFolder(-1)+SubFldr+WNameWavej[i], GetDataFolder(-1)+SubFldr+NewWName
	If (	(SortKeyWSrtj[ i ] - (SortKeyStartVal+i*SortKeyDelVal)	) > 0.5*SortKeyDelVal)	// missing point
	InsertPoints i,1, SortKeyWSrtj, WNameWavej
	SortKeyWSrtj[i] = Nan
	WNameWavej[i] = ""
	Make /O/N=0 $(GetDataFolder(1)+SubFldr+NewWName )
	DoAlertStr = "Missing value "+Num2Str(SortKeyStartVal+i*SortKeyDelVal)+" in "+ SortKeyWName+Num2Str(j)+"Srt"
	DoAlert 0, DoAlertStr	
	Print DoAlertStr
	PntsPerRep1 +=1
	Else
//	Duplicate /O $(GetDataFolder(1)+SubFldr+WNameWavej[i]), $(GetDataFolder(1)+SubFldr+NewWName )
	Duplicate /O $(GetDataFolder(1)+SubFldr+WNameWavej[i]), $(GetDataFolder(1)+SubFldr+NewWName )
	EndIf
	If (k==0) // Print only for 1st Par
	Print "SortKeyW =",SortKeyWSrtj[ i ], "for", WNameWavej[i],". Duplicated to", NewWName
	EndIf
	EndFor
	Print "											"
	KillWaves /Z WNameWavej
EndFor

EndFor	//index k; SortParWList
Else 
Print "Attention! Either PntsPerRep OR NumReps =0!!! No Wave Generated"	
EndIf

End

Function pt_NthPntExtract()
// Extract parameter for Nth Spike from extracted Waves
String DataWaveMatchStr, SubFldr, OutWName
Variable PntVal

String LastUpdatedMM_DD_YYYY=" 01/05/2011", WList, WNameStr
Variable NumWaves, i

Print "*********************************************************"
Print "pt_NthPntExtract last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_NthPntExtract", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_NthPntExtract", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)		
	Abort	"Cudn't find the parameter wave pt_NthPntExtract!!!"
EndIf

DataWaveMatchStr   = AnalParW[0]
PntVal				= Str2Num(AnalParW[1])
SubFldr				= AnalParW[2]
OutWName			= AnalParW[3]

PrintAnalPar("pt_NthPntExtract")


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
Numwaves=ItemsInList(WList, ";")

Print "Extracting pnt # ",PntVal, "from waves, N =", Numwaves, WList

Make /O/N=(NumWaves) $(GetDataFolder(1)+SubFldr+OutWName)
Wave OutW = $(GetDataFolder(1)+SubFldr+OutWName)
OutW = NaN

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w = $(GetDataFolder(1)+SubFldr+WNameStr)
	If (NumPnts(w)-1 >= PntVal)
	OutW[i] = w[PntVal]
	EndIf	
EndFor


End

Function /S pt_ConvertNumStr2NameStr(NumStr)
// Function to convert a number string (eg. "2.5e-11") to a string that can be used as wavename (eg. 2F5EN11)
String NumStr
NumStr= ReplaceString("-", NumStr,"N")		// Replace "-" with "N"
NumStr= ReplaceString("+", NumStr,"P")		// Replace "+" with "P"
NumStr= ReplaceString(".", NumStr,"D")		// Replace "." with "D"
//Print NumStr
Return NumStr
End

Function pt_BinDataW(WName, BinMinVal, BinWidth, NumBins)
String WName
Variable BinMinVal, BinWidth, NumBins

Variable NPnts, i, j, BinNum
Wave w = $WName
Duplicate /O w, $(WName+"Bin")
Wave w1 = $(WName+"Bin")
NPnts = NumPnts(w)
For (i=0; i<NPnts; i+=1)
BinNum = floor(   (w[i]-BinMinVal)/BinWidth)
If (BinNum>(NumBins-1))
DoAlert 0,"Couldn’t bin the value ="+ Num2Str(w[i])+"in wave "+ WName
Else
w1[i] = BinMinVal+(BinNum+0.5)*BinWidth
EndIf
//	For (j=0; j<NumBins; j+=1)
//		If (  (w[i]>=(BinMinVal+j*BinWidth) )&& (w[i]<(BinMinVal+(j+1)*BinWidth))   )
//			Print i, w[i], BinMinVal+j*BinWidth, BinMinVal+(j+1)*BinWidth
//			w1[i]=BinMinVal+(j+0.5)*BinWidth
//			Break
//		EndIf
//			DoAlert 0,"Couldn’t bin the value ="+ Num2Str(w[i])+"in wave "+ WName
//	EndFor
EndFor
End

Function pt_ScalarFuncCalc()
// Use this to calculate trivial functions
//=========
// V=pi*d*d*h/4
Variable V=(1e-6)*1e-3	// 1 L = 1e-3 cubic meter
Variable d=0.023*25.4*1e-3
Print "h=", 4*V/(pi*d*d)
//=========
End

Function pt_ExcitInhibBal()
// Use this to calculate trivial vector functions
//=========
// MembV(t)=Exct(t)+Inhib(t)
Variable i,j, Num=10000,NumThCross//, Delta=1e-4
Variable RMP=-65, Threshold = -50
Variable NRep=100
Variable ExctAmp =1.5, InhibAmp=1.5

Make /O/N=(Num) MembV, Exct, Inhib
//Setscale /P x,0,Delta, MembV, Exct, Inhib




Make /O/N=(NRep) NormThCrossW=Nan

For (j=0;j<NRep;j+=1)
NumThCross=0
Exct = ExctAmp*abs(gnoise(5))
Inhib = InhibAmp*-1*abs(gnoise(5))
Make /N=100/O $"Exct_Hist"+Num2Str(ExctAmp), $"Inhib_Hist"+Num2Str(InhibAmp)
Histogram/B=1 Exct,$"Exct_Hist"+Num2Str(ExctAmp)
Histogram/B=1 Inhib, $"Inhib_Hist"+Num2Str(InhibAmp)
//DoWindow HistDisplay
//If (V_Flag==0)
//Display 
//Dowindow /C HistDisplay
//AppendToGraph $"Exct_Hist"+Num2Str(ExctAmp), $"Exct_Hist"+Num2Str(ExctAmp)
//EndIf
MembV = RMP+Exct[p]+Inhib[p]

For (i=0;i<Num; i+=1)
If (MembV[i] > Threshold)
NumThCross +=1
EndIf
EndFor

NormThCrossW[j]= NumThCross/Num
EndFor
WaveStats /q NormThCrossW
Print "=========="
Print "Exct. Amp., Inhib. Amp.=", ExctAmp,",", InhibAmp
Print "V_Avg, V_SDev=", V_Avg,V_SDev
Print "=========="
//=========
End

Function pt_PSDNormalize(RawPSDWName)
String RawPSDWName
Variable NRows, NCols, i

Wave RawPSDW = $RawPSDWName
NRows =DimSize(RawPSDW, 0)
NCols   =DimSize(RawPSDW, 1)

Print "NRows, NCols =", NRows, NCols
Duplicate /O RawPSDW, $(RawPSDWName+"_N")
Wave NormPSDW= $(RawPSDWName+"_N")

Make /O/N=(NCols) TmpColW 
Wave TmpW = TmpColW

For (i=0;i<NRows;i+=1)
TmpColW = RawPSDW[i][p]
//Wavestats TmpW
//Print Sum(TmpColW)
NormPSDW[i][] /=Sum(TmpColW)
Print i
EndFor
KillWaves /Z TmpColW
End

Function pt_CalCostain(W1NameStr, W2NameStr)
String W1NameStr, W2NameStr
// given two columns of data with: 1= Stained; 0= Non-stained; -1 = Not Sure. Calculate waves with neurons that are -/-; -/+; +/-; +/+
// and the percent of neurons in each category
// algorithm - exclude neurons if even one stain is not clear.
// keywords (to help searching): immuno, stain, label, colabel, co-label, costain, co-stain  
Variable N1, N2,i, NValidTot
Wave w1 = $W1NameStr
Wave w2 = $W2NameStr

N1 = NumPnts(w1)
N2 = NumPnts(w2)

If (N1==N2)
Else
Abort "Number of points in 2 waves must be equal"
EndIf

Make /N=(N1)/O Marker1Marker2_00, Marker1Marker2_01, Marker1Marker2_10, Marker1Marker2_11 
Wave Marker1Marker2_00 = Marker1Marker2_00
Wave Marker1Marker2_01 = Marker1Marker2_01
Wave Marker1Marker2_10 = Marker1Marker2_10
Wave Marker1Marker2_11 = Marker1Marker2_11

Marker1Marker2_00 = Nan
Marker1Marker2_01 = Nan
Marker1Marker2_10 = Nan
Marker1Marker2_11 = Nan

NValidTot =0

For (i=0; i<N1; i+=1)

If (w1[i]==0 && w2[i]==0)
Marker1Marker2_00[i] = 1
NValidTot +=1
EndIf

If (w1[i]==0 && w2[i]==1)
Marker1Marker2_01[i] = 1
NValidTot +=1
EndIf

If (w1[i]==1 && w2[i]==0)
Marker1Marker2_10[i] = 1
NValidTot +=1
EndIf

If (w1[i]==1 && w2[i]==1)
Marker1Marker2_11[i] = 1
NValidTot +=1
EndIf

EndFor
Print "*****************************************"
WaveStats /Q Marker1Marker2_00
Print "Percent Marker1Marker2_00=",V_Sum*100/NValidTot

WaveStats /Q Marker1Marker2_01
Print "Percent Marker1Marker2_01=",V_Sum*100/NValidTot

WaveStats /Q Marker1Marker2_10
Print "Percent Marker1Marker2_10=",V_Sum*100/NValidTot

WaveStats /Q Marker1Marker2_11
Print "Percent Marker1Marker2_11=",V_Sum*100/NValidTot

Print "Num points ignored=", NValidTot-N1
Print "*****************************************"

End

Function DuplicGraphSize(SrcGrphName, TrgGrphName, FontSize)
// Example usage: DuplicGraphSize("Graph4", "Graph0", 16)

// Function that gets the size of source graph and applies it to target target. 
// That way we don't have to manually make the sizes equal.
// *******************************
// size of outer window = graph size + margins
// *******************************
String SrcGrphName, TrgGrphName
Variable FontSize
//Prompt SrcGrphName, "Source graph name"
//Prompt TrgGrphName, "Target graph name"
//Prompt FontSize, "Font Size"
//DoPrompt "Enter source and target graph names",SrcGrphName, TrgGrphName, FontSize

ModifyGraph /W=$SrcGrphName margin(left)=72
ModifyGraph /W=$SrcGrphName margin(right)=36
ModifyGraph /W=$SrcGrphName margin(top)=18
ModifyGraph /W=$SrcGrphName margin(bottom)=54

ModifyGraph /W=$SrcGrphName fsize=FontSize

//ModifyGraph /W=$SrcGrphName width=0
//ModifyGraph /W=$SrcGrphName Height=0

GetWindow $SrcGrphName wsize	// get size

Print "Width=",V_Right-V_Left, "Height=",V_Bottom-V_Top

ModifyGraph /W=$TrgGrphName margin(left)=72
ModifyGraph /W=$TrgGrphName margin(right)=36
ModifyGraph /W=$TrgGrphName margin(top)=18
ModifyGraph /W=$TrgGrphName margin(bottom)=54
ModifyGraph /W=$TrgGrphName fsize=FontSize
//ModifyGraph /W=$TrgGrphName width=0
//ModifyGraph /W=$TrgGrphName Height=0

ModifyGraph /W=$TrgGrphName width = V_Right-V_Left-108, height=V_Bottom-V_Top-72	// set size

//Print V_Right-V_Left, V_Bottom-V_Top
// ModifyGraph ModifyGraph /W=$TrgGrphName width=0, height=0
//ModifyGraph /W=$TrgGrphName fsize=FontSize
End

Function pt_MakeStringSeqW(WName, StrBaseName, StartNum, DelNum, PadNum)
// modified from straight assignment (which required waves to have required number of points) to concatenation
// To create a text wave with a sequence of string basename + numbers eg. w[0]=Cell_0001,w[1]=Cell_0002, and so on.
// Eg. usage: pt_MakeStringSeqW("CellName", "Cell_",1,200,4)
String WName, StrBaseName
Variable StartNum, DelNum, PadNum
Variable i
If (WaveExists($WName) == 0)
	Make /O/N=0/T $WName
EndIf

Wave /T w= $WName
Make /O/N=1/T TmpStringSeqW

For (i=0; i<DelNum; i+=1)
//w[i] = StrBaseName+pt_PadZeros2IntNum(StartNum+i, PadNum)
TmpStringSeqW[0]= StrBaseName+pt_PadZeros2IntNum(StartNum+i, PadNum)
Concatenate /T/NP {TmpStringSeqW},w
EndFor
KillWaves /Z TmpStringSeqW

End


Function pt_LevelCross()

// This is always the latest version. Can be used to find current threshold of an FI curve. 
// added option to apply interpolation correction. If w[i]=0 and w[i+1]>0 then the best estimate for transition is at (i+0.5)

String LastUpdatedMM_DD_YYYY="05_08_2012"

Print "*********************************************************"
Print "pt_LevelCross last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

String DataWaveMatchStr, DestWName, LevelValStr
Variable LevelEdge, InterpCorr	

String	WList, WNameStr, SubFldr
Variable	Numwaves, i, LevelVal, NPnts, j
Variable NonZeroVal= NaN, SkipW=0

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_LevelCross", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_LevelCross", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_LevelCross!!!"
EndIf

PrintAnalPar("pt_LevelCross")

DataWaveMatchStr		=	AnalParW[0]
LevelValStr				=	"FirstNonZeroVal"
LevelEdge				=	Str2Num(AnalParW[2]) //e=1: crossing where y vals are increasing, e=2 : y vals are decreasing, e=0 : either
DestWName				=	AnalParW[3]
SubFldr					= 	AnalParW[4]
InterpCorr				= 	Str2Num(AnalParW[5])	// 12/06/12




WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
Numwaves=ItemsInList(WList, ";")

Print "Level crossing from waves, N =", Numwaves, WList

Make /O/N=(Numwaves) $DestWName
Wave w1 = $(GetDataFolder(1)+SubFldr+DestWName)
w1 = Nan

For (i=0; i<Numwaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$(GetDataFolder(1)+SubFldr+WNameStr)

Strswitch (LevelValStr)
	Case "FirstNonZeroVal":
	NPnts=NumPnts(w)
	
	j=0; SkipW=0; LevelVal=Nan
	Do
		If (j<NPnts)
		
		If (w[j]!=0)
		LevelVal = w[j]
		Break
		EndIf
		Else
		Print "Warning: All values in wave", WNameStr, "are =0 or the wave has 0 number of points"
		SkipW=1
		Break
		EndIf
		
		j+=1
	While (1)
	
	Break	// Case "FirstNonZeroVal":
	Default:
//	LevelVal = Str2Num(LevelValStr)
//	Print "For wave=",WNameStr,"LevelVal=",LevelVal
EndSwitch

If (!SkipW)
	Findlevel /Q/edge=(LevelEdge) w, LevelVal
	If (V_flag==0)
		w1[i] = V_LevelX
		If (InterpCorr)
			w1[i] = V_LevelX-(DimDelta(w, 0))*0.5	// 12/06/12
		EndIf
	Else
		Print "Warning: Level crossing not found for",WNameStr
	EndIf
EndIf
	
EndFor


End

//******
Function pt_StatsOnWaves()

// based on pt_UnaryOpOnWaves()

String DataWaveMatchStr, SubFldr, OutWaveNameStr, StatsStr

String wavlist, WaveNameStr
Variable NumWaves,i 

String LastUpdatedMM_DD_YYYY="08_22_2012"
Print "*********************************************************"
Print "pt_StatsOnWaves last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_StatsOnWaves", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_StatsOnWaves", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_ScalarOpOnWavesParW and/or pt_ScalarOpOnWavesParNamesW!!!"
EndIf


DataWaveMatchStr		=	AnalParW[0]
SubFldr					=	AnalParW[1]
OutWaveNameStr		=	AnalParW[2]
StatsStr				=	AnalParW[3]

PrintAnalPar("pt_StatsOnWaves")


WavList	= pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)

NumWaves = ItemsInList(WavList,";")
If (!NumWaves>0)
	Print "NumWaves <=0. No Waves to operate on!!"
	Return -1
EndIf
print "Stats on waves...N=", NumWaves, wavlist

Make /O/N=(NumWaves) $GetDataFolder(1)+SubFldr+OutWaveNameStr
Wave OutW=$GetDataFolder(1)+SubFldr+OutWaveNameStr

For (i=0; i< NumWaves; i+=1)
	
	WaveNameStr= StringFromList (i,wavlist,";")
	
	If (strlen(WaveNameStr)== 0)
		break
	endif
	
	Wave w = $GetDataFolder(1)+SubFldr+WaveNameStr
		
	StrSwitch (StatsStr)
		
		Case "NPnts":
			OutW[i]=NumPnts(w)
			Break		
		
		default:
			Print StatsStr+"undefined. define in pt_StatsOnWaves first"
			Break
	EndSwitch
		
EndFor

End
//******
Function SaveNRestore(FuncName, SaveEq1RestoreEq2)
// optional to find *ParNamesW //05/06/2014
// Function to save orig pars and restore them later
String FuncName
Variable SaveEq1RestoreEq2

//Wave /T AnalParNamesW		=	$pt_GetParWave(FuncName, "ParNamesW")
If (WaveExists($FuncName+"ParNamesW") || WaveExists($"root:FuncParWaves:"+FuncName+"ParNamesW")) // ok if names wave doesn't exist 04/10/14
	Wave /T AnalParNamesW		=		$pt_GetParWave(FuncName, "ParNamesW")
EndIf	
Wave /T AnalParW				=	$pt_GetParWave(FuncName, "ParW")

If  (SaveEq1RestoreEq2 ==1)
If (WaveExists($FuncName+"ParNamesW") || WaveExists($"root:FuncParWaves:"+FuncName+"ParNamesW")) // ok if names wave doesn't exist 04/10/14
	Duplicate /O AnalParNamesW, 	$("root:FuncParWaves:"+"SaveNRestore"+"ParNamesW")
EndIf
Duplicate /O AnalParW,			$("root:FuncParWaves:"+"SaveNRestore"+"ParW")
//KillWaves /Z AnalParNamesW, AnalParW
ElseIf  (SaveEq1RestoreEq2 ==2)

Wave /T w2= $("root:FuncParWaves:"	+"SaveNRestore"+"ParW")
If (WaveExists($FuncName+"ParNamesW") || WaveExists($"root:FuncParWaves:"+FuncName+"ParNamesW")) // ok if names wave doesn't exist 04/10/14
	Wave /T w1= $("root:FuncParWaves:"	+"SaveNRestore"+"ParNamesW")
	Duplicate /O/T w1, AnalParNamesW
EndIf
Duplicate /O/T w2, AnalParW
KillWaves /Z w1,w2
Else
DoAlert 1,"SaveNRestore 2nd parameter has to be =1 (save) or =2(restore). Nothing saved or restored!"
EndIf

End

//$$$$$$

Function pt_MiniAnalysis()
// This is a function to carry out the full mini-analysis including averaging, etc. Earlier many of these steps were being carried out manually
// changed ISI bin width to 10ms. 10/30/13
////pt_AnalWInFldrs2("pt_AverageWavesEasy"). Switched to pt_AverageWaves 10/20/13
// option for specifying CellNamePrefix rather than the previously hard-coded Cell_* 10/15/13 
// average and histograms of rise times were missing. Added those 10/9/13
// Switched from instantaneous frequency to ISIs for histograms and from instantaneous frequency to average frequency for bar plots. 07/14/13 (suggested by Sacha)
// remove decay time outliers 07/15/13
// ToDo:
// 1. When selecting the minimum number of events randomly from each cell, allow for selecting more than minimum number of events if the 
// minimum number is much less than what other cells have.
// eg. if cells have 20, 100, 150, 80, then instead of selecting 20 events from each cell, select 80 from each cell and all 20 from 1st cell. 
String CellNamePrefix
String OldDf, ConditionFldrList, AnalFldr="root:ConditionAnal",ParListStr,HistParListStr
Variable NCond, i, PkPolarity, HistBinStart, HistBinWidth, HistNumBins,NParListItem,j,NHistParListItem,k, NumWaves
String ParList="RsV;RInV;CmV;PkAmpRelW;FreqPksW;DecayT;RiseT;BLNoiseW;BLSmthDiffNoiseW", DisplayWinName, TraceNameStr1, TraceNameStr2
String HistParList="PkAmp;ISI;TauD;RiseT", WList, WStr, WList1, WStr1
//String /G root:ExcludeWList
//String ExcludeWList=$"root:ExcludeWList"
NParListItem=ItemsInList(ParList)
NHistParListItem=ItemsInList(HistParList)

String LastUpdatedMM_DD_YYYY="10_15_2013"
Print "*********************************************************"
Print "pt_MiniAnalysis last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_MiniAnalysis", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_MiniAnalysis", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_MiniAnalysisParW and/or pt_MiniAnalysisParNamesW!!!"
EndIf

CellNamePrefix		=	AnalParW[0]

PrintAnalPar("pt_MiniAnalysis")

DoAlert 1, "Recent changes in seal test analysis: new vals for baseline and steadystate locations, CONTINUE?"
If (V_Flag==2)
		Abort "Aborting..."
EndIf


DoAlert 1,"Press 'Yes', if parameters for pt_MiniAnalysis(), pt_PeakAnal(), pt_CalRsRinCmVmVClamp(), pt_MoveWavesMany have been adjusted and the folders for pt_MoveWavesMany exist. "
If (V_Flag==2)
	Abort "Aborting...."
EndIf
NewDataFolder /O $AnalFldr

//******************
// pt_AnalWInFldrs2("pt_PeakAnal")
String BaseNameStr
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_PeakAnal", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_PeakAnal", "ParW")
BaseNameStr = AnalParW[16]
Print "BaseNameStr=",BaseNameStr
pt_AnalWInFldrs2("pt_PeakAnal")
//******************
//pt_AnalWInFldrs2("pt_CalRsRinCmVmVClamp")
 pt_AnalWInFldrs2("pt_CalRsRinCmVmVClamp")
 //******************
//pt_AnalWInFldrs2("pt_AverageVals")
//Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")		
//Wave /T AnalParW				=	$pt_GetParWave("pt_AverageVals", "ParW")
//SaveNRestore("pt_AverageVals", 1) 
//AnalParW[0]	=	"RsV"	//DataWaveMatchStr
//AnalParW[1]	=	"-1"				//XStartVal
//AnalParW[2]	=	"-1"				//XEndVal
//AnalParW[3]	=	"RsV"	//BaseNameString
//AnalParW[4]	=	""					//SubFldr
//pt_AnalWInFldrs2("pt_AverageVals")
//AnalParW[0]	=	"RInV"	//DataWaveMatchStr
//AnalParW[3]	=	"RInV"	//BaseNameString
//pt_AnalWInFldrs2("pt_AverageVals")
//AnalParW[0]	=	"CmV"	//DataWaveMatchStr
//AnalParW[3]	=	"CmV"	//BaseNameString
//pt_AnalWInFldrs2("pt_AverageVals")
//SaveNRestore("pt_AverageVals", 2)
//******************
//pt_AnalWInFldrs2("pt_RemoveOutLiers1")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")		// remove decay time outliers 07/15/13
Wave /T AnalParW				=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")
SaveNRestore("pt_RemoveOutLiers1", 1)
AnalParW[0]	=	BaseNameStr+"NoOLDecayTW*" // DataWaveMatchStr
AnalParW[1]	=	"-1"					//SmoothFactor
AnalParW[2]	=	"1.5"					//TimesSD
AnalParW[3]	=	BaseNameStr+"DecayTF:"//SubFldr
AnalParW[4]	=	"1"						//UseMedian
pt_AnalWInFldrs2("pt_RemoveOutLiers1")
SaveNRestore("pt_RemoveOutLiers1", 2)
//******************
//******************
//pt_AnalWInFldrs2("pt_RemoveOutLiers1")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")		// remove decay time outliers 07/15/13
Wave /T AnalParW				=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")
SaveNRestore("pt_RemoveOutLiers1", 1)
AnalParW[0]	=	BaseNameStr+"RiseTW*" // DataWaveMatchStr
AnalParW[1]	=	"-1"					//SmoothFactor
AnalParW[2]	=	"1.5"					//TimesSD
AnalParW[3]	=	BaseNameStr+"RiseTF:"//SubFldr
AnalParW[4]	=	"1"						//UseMedian
pt_AnalWInFldrs2("pt_RemoveOutLiers1")
SaveNRestore("pt_RemoveOutLiers1", 2)
//******************

//pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
//TempRemove Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConctnWFrmFldrs1", "ParNamesW")		
//TempRemove Wave /T AnalParW				=	$pt_GetParWave("pt_ConctnWFrmFldrs1", "ParW")
//TempRemove SaveNRestore("pt_ConctnWFrmFldrs1", 1) 
//TempRemove AnalParW[0]	=	"TauD"+BaseNameStr+"*_NoOL" // DataWaveMatchStr
//TempRemove AnalParW[1]	=	BaseNameStr+"CropPksF:"	//DataFldr
//TempRemove AnalParW[2]	=	BaseNameStr+"TauD"	//DestWNameStr
//TempRemove pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
//TempRemove SaveNRestore("pt_ConctnWFrmFldrs1", 2) 
//******************
//pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParW")
SaveNRestore("pt_ConvertTSpikeToISI", 1) 
AnalParW[0]	=	BaseNameStr+"PkXW*" // DataWaveMatchStr
AnalParW[1]	=	""					//DataWaveNotMatchStr
AnalParW[2]	=	"_ISI"			//InsrtNewStr
AnalParW[3]	=	"0"					//  InsrtPosStr
AnalParW[4]	=	"1"					//ReplaceExisting 
AnalParW[5]	=	BaseNameStr+"PkXF:"	//SubFldr
AnalParW[6]	=	"0"						// Invert. Switched to 0 as Sacha suggested to plot ISI instead of frequnecies for histograms.  07/14/13
pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
SaveNRestore("pt_ConvertTSpikeToISI", 2)
//******************
//pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConctnWFrmFldrs1", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_ConctnWFrmFldrs1", "ParW")
SaveNRestore("pt_ConctnWFrmFldrs1", 1) 
AnalParW[0]	=	BaseNameStr+"PkXW*_ISI" // DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"PkXF:"			//DataFldr
AnalParW[2]	=	BaseNameStr+"ISI"			//DestWNameStr
pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")

AnalParW[0]	=	BaseNameStr+"NoOLDecayTW*_NoOL*" // DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"DecayTF:"			//DataFldr
AnalParW[2]	=	BaseNameStr+"DecayT"			//DestWNameStr
pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")

AnalParW[0]	=	BaseNameStr+"RiseTW*_NoOL*" // DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"RiseTF:"			//DataFldr
AnalParW[2]	=	BaseNameStr+"RiseT"			//DestWNameStr
pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")


SaveNRestore("pt_ConctnWFrmFldrs1", 2) 
//******************

//pt_AnalWInFldrs2("pt_AverageWavesEasy"). Switched to pt_AverageWaves 10/20/13
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")
SaveNRestore("pt_AverageWaves", 1) 
AnalParW[0]	=	BaseNameStr+"CropPksW*" // DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"CropPksF:"	//DataFldrStr
AnalParW[2] 	=	BaseNameStr + "CropPk"	//BaseNameStr
AnalParW[3]	=	"1"							//PntsPerBin
AnalParW[4]	=	""							//ExcludeWNamesWStr
AnalParW[5]	=	"1"							//DisplayAvg

pt_AnalWInFldrs2("pt_AverageWaves")

SaveNRestore("pt_AverageWaves", 2) 
//******************
//******************

//pt_AnalWInFldrs2("pt_UserCommands")
//Wave /T AnalParNamesW		=	$pt_GetParWave("pt_UserCommands", "ParNamesW")
//Wave /T AnalParW				=	$pt_GetParWave("pt_UserCommands", "ParW")
//SaveNRestore("pt_UserCommands", 1) 
//AnalParW[0]	=	"Make /O/N=0"+ GetDataFolder(1) + BaseNameStr+"CropPksF:NoOLCropArea"; 
//AnalParW[0]	+=   "Wave wCropArea =" GetDataFolder(1) + BaseNameStr+"CropPksF:NoOLCropArea"; // CommandStr
//AnalParW[0] 	+=   wCropArea[0] = area(BaseNameStr + "CropPk")
//pt_AnalWInFldrs2("pt_UserCommands")
//root:Data:sEPSC:Cell_0003:sEPSCCropPksF:sEPSCCropPkAvg
//SaveNRestore("pt_UserCommands", 2) 
//******************

//pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParW")

AnalParW[0]	=	AnalFldr	//DestFolderName
AnalParW[2]	=	"DataFldrName"				//PrefixStr
AnalParW[3]	=	""							//SuffixStr
AnalParW[4]	=	"-1"						//XStartVal
AnalParW[5]	=	"-1"						//XEndVal

SaveNRestore("pt_DuplicateWFrmFldrs", 1)

AnalParW[1]	=	BaseNameStr+"FreqPksW"		//DataWaveMatchStr
AnalParW[6]	=	""		//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")
 

AnalParW[1]	=	BaseNameStr+"ISI"		//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"PkXF:"		//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"CropPk_Avg"		//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"CropPksF:"		//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"PkAmpRelW"		//DataWaveMatchStr
AnalParW[6]	=	""									//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"DecayT"		//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"DecayTF:"	//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"RiseT"		//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"RiseTF:"	//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	"RsV"		//DataWaveMatchStr
AnalParW[6]	=	""			//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	"RInV"		//DataWaveMatchStr
AnalParW[6]	=	""			//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	"CmV"		//DataWaveMatchStr
AnalParW[6]	=	""			//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"BLNoiseW"		//DataWaveMatchStr
AnalParW[6]	=	""			//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"BLSmthDiffNoiseW"		//DataWaveMatchStr
AnalParW[6]	=	""			//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

SaveNRestore("pt_DuplicateWFrmFldrs", 2) 
//******************

OldDf = GetDataFolder(1)
SetDataFolder AnalFldr

SaveNRestore("pt_MoveWavesMany", 1) 
Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParW")
AnalParW[2]="1"//Overwrite
ConditionFldrList=AnalParW[1]		//ListDestFolderName
NCond=ItemsInList(ConditionFldrList,";")
pt_MoveWavesMany()
SaveNRestore("pt_MoveWavesMany", 2)
SetDataFolder OldDf
//**

OldDf = GetDataFolder(1)
For (i=0;i<NCond;i+=1)
SetDataFolder StringFromList(i, ConditionFldrList, ";")
//pt_AnalWInFldrs2("pt_AverageWaves")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")
SaveNRestore("pt_AverageWaves", 1) 
AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"CropPk_Avg" // DataWaveMatchStr
AnalParW[1]	=	""										//DataFldrStr
AnalParW[2] 	=	GetDataFolder(0) + "CropPk"	//BaseNameStr
AnalParW[3]	=	"1"							//PntsPerBin
AnalParW[4]	=	""								//ExcludeWNamesWStr
AnalParW[5]	=	"1"								//DisplayAvg
pt_AverageWaves()
SaveNRestore("pt_AverageWaves", 2) 
//Also calculate the average area & charge per sec as area*freq
WList=pt_SortWavesInFolder(CellNamePrefix+"*"+BaseNameStr+"CropPk_Avg", GetDataFolder(0))
WList1=pt_SortWavesInFolder(CellNamePrefix+"*"+BaseNameStr+"FreqPksW", GetDataFolder(0))

Numwaves=ItemsInList(WList, ";")
Make /O/N=(NumWaves) $(GetDataFolder(0)+"NoOLArea")
Wave wNoOLArea = $(GetDataFolder(0)+"NoOLArea")

Make /O/N=(NumWaves) $(GetDataFolder(0)+"ChargePerS")
Wave ChargePerS = $(GetDataFolder(0)+"ChargePerS")
For (j = 0; j<NumWaves; j+=1)
	
	WStr = StringFromList(j, WList, ";")
	Wave NoOLAreaTmp = $WStr
	wNoOLArea[j] = Area(NoOLAreaTmp)
	
	WStr1 = StringFromList(j, WList1, ";")
	Wave FreqPksW = $WStr1
	ChargePerS[j] = wNoOLArea[j]*FreqPksW[j]
EndFor

EndFor
SetDataFolder OldDf
//**

//******************
//pt_AnalWInFldrs2("pt_AppendWToGraph")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AppendWToGraph", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AppendWToGraph", "ParW")
SaveNRestore("pt_AppendWToGraph", 1)



DisplayWinName="AvgEvent"
DoWindow $DisplayWinName
If (V_Flag)
	DoWindow /F $DisplayWinName
Else
	Display
	DoWindow /C $DisplayWinName
EndIf

//AnalParW[0]="Cell_*"+BaseNameStr+"FreqPksW"
AnalParW[1]=DisplayWinName
AnalParW[2]="-1"
AnalParW[3]=""

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AnalParW[0]=GetDataFolder(0) + "CropPk_Avg"
	pt_AppendWToGraph()
	//ModifyGraph /W=$DisplayWinName
EndFor		
SaveNRestore("pt_AppendWToGraph", 2)
//******************
 
//ConditionFldrList=AnalParW[1]		//ListDestFolderName
//NCond=ItemsInList(ConditionFldrList,";")
OldDf = GetDataFolder(1)

//******************
//pt_AnalWInFldrs2("pt_AverageVals")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageVals", "ParW")
SaveNRestore("pt_AverageVals", 1)

AnalParW[1]	=	"-1"				//XStartVal
AnalParW[2]	=	"-1"				//XEndVal
AnalParW[4]	=	""					//SubFldr

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	For(j=0;j<NParListItem;j+=1)
		ParListStr=StringFromList(j, ParList, ";")
 
		AnalParW[0]	=	CellNamePrefix+"*"+ParListStr			//DataWaveMatchStr
		AnalParW[3]	=	GetDataFolder(0)+ParListStr	//BaseNameString
		pt_AverageVals()

//AnalParW[0]	=	"Cell_*RInV"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"RInV"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*CmV"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"CmV"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*"+BaseNameStr+"InstFrq"		//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"InstFrq"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*"+BaseNameStr+"PkAmpRelW"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"PkAmp"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*"+BaseNameStr+"TauD"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"TauD"	//BaseNameString
//pt_AverageVals()
	EndFor
EndFor
SaveNRestore("pt_AverageVals", 2)

//******************

For (i=0;i<NCond;i+=1)
SetDataFolder StringFromList(i, ConditionFldrList, ";")
	For(j=0;j<NParListItem;j+=1)
		ParListStr=StringFromList(j, ParList, ";")
		
		DisplayWinName=ParListStr+"Display"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		EndIf
		AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+ParListStr+"Avg"
		Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
	EndFor
	
EndFor	

//******************
//pt_AnalWInFldrs2("pt_AppendWToGraph")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AppendWToGraph", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AppendWToGraph", "ParW")
SaveNRestore("pt_AppendWToGraph", 1)



DisplayWinName="AvgFrq_TimeCourse_Display"
DoWindow $DisplayWinName
If (V_Flag)
	DoWindow /F $DisplayWinName
Else
	Display
	DoWindow /C $DisplayWinName
EndIf

AnalParW[0]=CellNamePrefix+"*"+BaseNameStr+"FreqPksW"
AnalParW[1]=DisplayWinName
AnalParW[2]="-1"
AnalParW[3]=""

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	pt_AppendWToGraph()
EndFor		
SaveNRestore("pt_AppendWToGraph", 2)


// Calculate averages and SEM

NewDataFolder /O $(AnalFldr+":Stats")

If (!WaveExists($(AnalFldr+":Stats:ConditionW")))
	Make /O/N=(NCond)/T $(AnalFldr+":Stats:ConditionW")
	Wave /T ConditionW=$(AnalFldr+":Stats:ConditionW")
Else
	Wave /T ConditionW=$(AnalFldr+":Stats:ConditionW")
EndIf

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	ConditionW[i]=GetDataFolder(0)
EndFor


	
For(j=0;j<NParListItem;j+=1)
	ParListStr=StringFromList(j, ParList, ";")
	If (!WaveExists($(AnalFldr+":Stats:"+ParListStr+"Avg")))
		Make /O/N=(NCond) $(AnalFldr+":Stats:"+ParListStr+"Avg")
		Wave wAvg=$(AnalFldr+":Stats:"+ParListStr+"Avg")
	Else
		Wave wAvg=$(AnalFldr+":Stats:"+ParListStr+"Avg")
	EndIf
	If (!WaveExists($(AnalFldr+":Stats:"+ParListStr+"SE")))
		Make /O/N=(NCond) $(AnalFldr+":Stats:"+ParListStr+"SE")
		Wave wSE=$(AnalFldr+":Stats:"+ParListStr+"SE")
	Else
		Wave wSE=$(AnalFldr+":Stats:"+ParListStr+"SE")
	EndIf
		
	For (i=0;i<NCond;i+=1)
		SetDataFolder StringFromList(i, ConditionFldrList, ";")
		Print GetDataFolder(1), ParListStr
		Wavestats $GetDataFolder(0)+ParListStr+"Avg"
		wAvg[i]=V_Avg
		wSE[i]=V_Sem
	EndFor
EndFor

// Draw category plots
//SetDataFolder $(AnalFldr+":Stats")
For(j=0;j<NParListItem;j+=1)
	ParListStr=StringFromList(j, ParList, ";")
	Display $(AnalFldr+":Stats:"+ParListStr+"Avg") vs $(AnalFldr+":Stats:ConditionW")
	DoWindow /C $ParListStr
	TraceNameStr1=ParListStr+"Avg"	// tracename is just the name of the wave without the entire path
	TraceNameStr2=AnalFldr+":Stats:"+ParListStr+"SE"
	ErrorBars /W=$ParListStr $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
	Legend/C/N=text0/F=0/A=RT	
EndFor


//******************
// Draw histograms from randomly selected pnts. To do this we need to select equal number of points from all cells. 
//Therefore we need to know minimum number of events that is common to all cells. However, if the next higher number of events is substantially higher then maybe we can use all events
// from cell with minimum number of events.
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_StatsOnWaves", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_StatsOnWaves", "ParW")
SaveNRestore("pt_StatsOnWaves", 1)
AnalParW[1]	=	""		//SubFldr
AnalParW[3]	=	"NPnts"	

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
//	For (k=0;k<NHistParListItem;k+=1)
//	HistParListStr=StringFromList(j, HistParList, ";")
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"PkAmpRelW"		//DataWaveMatchStr
	AnalParW[2]	=	GetDataFolder(0)+"PkAmpNPnts"			//OutWaveNameStr
	pt_StatsOnWaves()
	
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"ISI"		//DataWaveMatchStr
	AnalParW[2]	=	GetDataFolder(0)+"ISINPnts"			//OutWaveNameStr
	pt_StatsOnWaves()
	
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"DecayT"		//DataWaveMatchStr
	AnalParW[2]	=	GetDataFolder(0)+"DecayTNPnts"			//OutWaveNameStr
	pt_StatsOnWaves()
	
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"RiseT"		//DataWaveMatchStr
	AnalParW[2]	=	GetDataFolder(0)+"RiseTNPnts"			//OutWaveNameStr
	pt_StatsOnWaves()
	
EndFor										// StatsStr
SaveNRestore("pt_StatsOnWaves", 2)


Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RndSlctPntsFromW", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_RndSlctPntsFromW", "ParW")
SaveNRestore("pt_RndSlctPntsFromW", 1)





AnalParW[2]	=	""		//SubFldr

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
	
	Duplicate /O $(GetDataFolder(0)+"PkAmpNPnts"), $(GetDataFolder(0)+"PkAmpNPntsSrt")
	Wave NpntsTmpwSrt=$(GetDataFolder(0)+"PkAmpNPntsSrt")
	Sort NpntsTmpwSrt, NpntsTmpwSrt
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"PkAmpRelW"		//DataWaveMatchStr
	AnalParW[1]	=	Num2Str(NpntsTmpwSrt[0])							//NumPnts2Slct
	pt_RndSlctPntsFromW()
	
	Duplicate /O $(GetDataFolder(0)+"ISINPnts"), $(GetDataFolder(0)+"ISINPntsSrt")
	Wave NpntsTmpwSrt=$(GetDataFolder(0)+"ISINPntsSrt")
	Sort NpntsTmpwSrt, NpntsTmpwSrt
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"ISI"		//DataWaveMatchStr
	AnalParW[1]	=	Num2Str(NpntsTmpwSrt[0])							//NumPnts2Slct
	pt_RndSlctPntsFromW()
	
	Duplicate /O $(GetDataFolder(0)+"DecayTNPnts"), $(GetDataFolder(0)+"DecayTNPntsSrt")
	Wave NpntsTmpwSrt=$(GetDataFolder(0)+"DecayTNPntsSrt")
	Sort NpntsTmpwSrt, NpntsTmpwSrt
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"DecayT"		//DataWaveMatchStr
	AnalParW[1]	=	Num2Str(NpntsTmpwSrt[0])							//NumPnts2Slct
	pt_RndSlctPntsFromW()
	
	Duplicate /O $(GetDataFolder(0)+"RiseTNPnts"), $(GetDataFolder(0)+"RiseTNPntsSrt")
	Wave NpntsTmpwSrt=$(GetDataFolder(0)+"RiseTNPntsSrt")
	Sort NpntsTmpwSrt, NpntsTmpwSrt
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"RiseT"		//DataWaveMatchStr
	AnalParW[1]	=	Num2Str(NpntsTmpwSrt[0])							//NumPnts2Slct
	pt_RndSlctPntsFromW()
	
EndFor
SaveNRestore("pt_RndSlctPntsFromW", 2)


//******************
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConctnWFrmFldrs", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_ConctnWFrmFldrs", "ParW")
SaveNRestore("pt_ConctnWFrmFldrs", 1)



AnalParW[2]	=	""		//DataFldrStr

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
	AnalParW[0]	=	"Rnd_"+CellNamePrefix+"*"+BaseNameStr+"PkAmpRelW"		//DataWaveMatchStr
	pt_ConctnWFrmFldrs()
	Rename $GetDataFolder(0), $GetDataFolder(0)+"PkAmpAll"	// check if this name is already used
	
	AnalParW[0]	=	"Rnd_"+CellNamePrefix+"*"+BaseNameStr+"ISI"		//DataWaveMatchStr
	pt_ConctnWFrmFldrs()
	Rename $GetDataFolder(0), $GetDataFolder(0)+"ISIAll"	// check if this name is already used
	
	AnalParW[0]	=	"Rnd_"+CellNamePrefix+"*"+BaseNameStr+"DecayT"		//DataWaveMatchStr
	pt_ConctnWFrmFldrs()
	Rename $GetDataFolder(0), $GetDataFolder(0)+"DecayTAll"	// check if this name is already used
	
	AnalParW[0]	=	"Rnd_"+CellNamePrefix+"*"+BaseNameStr+"RiseT"		//DataWaveMatchStr
	pt_ConctnWFrmFldrs()
	Rename $GetDataFolder(0), $GetDataFolder(0)+"RiseTAll"	// check if this name is already used
	
EndFor	
//******************
SaveNRestore("pt_ConctnWFrmFldrs", 2)


//******************
//StatsQuantiles /Q $GetDataFolder(0)+BaseNameStr+"PkAmpRelW"

//Print "Using TimesSD*InterQuantileRange from Lower and Upper Quartile to find OutLiers"
//Print "Median =",V_Median,"LowerThresh =", V_Q25-TimesSD*V_IQR,"UpperThresh =", V_Q75+TimesSD*V_IQR

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_PeakAnal", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_PeakAnal", "ParW")

PkPolarity = Str2Num(AnalParW[4])



For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
	HistBinStart = 0
	HistBinWidth = (PkPolarity==1) ? 1e-12:-1e-12	// if the amplitude is in A
	//HistBinWidth = (PkPolarity==1) ? 1:-1	// if the amplitude is in pA
	HistNumBins = 150
	Print "HistBinStart,HistBinWidth,HistNumBins=",HistBinStart,HistBinWidth,HistNumBins
	Make/N=150/O $GetDataFolder(0)+"PkAmpAll_Hist";DelayUpdate
	Histogram/B={(HistBinStart),(HistBinWidth),(HistNumBins)} $GetDataFolder(0)+"PkAmpAll",$GetDataFolder(0)+"PkAmpAll_Hist"
	pt_CalNormHist(GetDataFolder(0)+"PkAmpAll_Hist") // 09/27/13
	pt_CalCummHist(GetDataFolder(0)+"PkAmpAll_Hist")
	
	HistBinStart = 0
	HistBinWidth = 0.01//0.4   different bins for ISI -  07/15/13
	HistNumBins = 1000//150   different bins for ISI -  07/15/13
	Print "HistBinStart,HistBinWidth,HistNumBins=",HistBinStart,HistBinWidth,HistNumBins
	Make/N=150/O $GetDataFolder(0)+"ISIAll_Hist";DelayUpdate
	Histogram/B={(HistBinStart),(HistBinWidth),(HistNumBins)} $GetDataFolder(0)+"ISIAll",$GetDataFolder(0)+"ISIAll_Hist"
	pt_CalNormHist(GetDataFolder(0)+"ISIAll_Hist") // 09/27/13
	pt_CalCummHist(GetDataFolder(0)+"ISIAll_Hist")
	
	HistBinStart = 0
	HistBinWidth = 0.00020
	HistNumBins = 60
	Print "HistBinStart,HistBinWidth,HistNumBins=",HistBinStart,HistBinWidth,HistNumBins
	Make/N=60/O $GetDataFolder(0)+"DecayTAll_Hist";DelayUpdate
	Histogram/B={(HistBinStart),(HistBinWidth),(HistNumBins)} $GetDataFolder(0)+"DecayTAll",$GetDataFolder(0)+"DecayTAll_Hist"
	pt_CalNormHist(GetDataFolder(0)+"DecayTAll_Hist") // 09/27/13
	pt_CalCummHist(GetDataFolder(0)+"DecayTAll_Hist")
	
	HistBinStart = 0
	HistBinWidth = 0.0001
	HistNumBins = 40
	Print "HistBinStart,HistBinWidth,HistNumBins=",HistBinStart,HistBinWidth,HistNumBins
	Make/N=40/O $GetDataFolder(0)+"RiseTAll_Hist";DelayUpdate
	Histogram/B={(HistBinStart),(HistBinWidth),(HistNumBins)} $GetDataFolder(0)+"RiseTAll",$GetDataFolder(0)+"RiseTAll_Hist"
	pt_CalNormHist(GetDataFolder(0)+"RiseTAll_Hist") // 09/27/13
	pt_CalCummHist(GetDataFolder(0)+"RiseTAll_Hist")
	
	
EndFor
//Display Normailzed histograms
DoWindow PkAmpNHistDisplay
If (V_Flag)
	DoWindow /F PkAmpNHistDisplay
Else
	Display
	DoWindow /C PkAmpNHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AppendToGraph /W=PkAmpNHistDisplay $GetDataFolder(0)+"PkAmpAll_HistN"
EndFor
Legend /W=PkAmpNHistDisplay /C/N=text0/F=0	

DoWindow ISINHistDisplay
If (V_Flag)
	DoWindow /F ISINHistDisplay
Else
	Display
	DoWindow /C ISINHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AppendToGraph /W=ISINHistDisplay $GetDataFolder(0)+"ISIAll_HistN"
EndFor
Legend /W=ISINHistDisplay /C/N=text0/F=0

DoWindow DecayTNHistDisplay
If (V_Flag)
	DoWindow /F DecayTNHistDisplay
Else
	Display
	DoWindow /C DecayTNHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AppendToGraph /W=DecayTNHistDisplay $GetDataFolder(0)+"DecayTAll_HistN"
EndFor
Legend /W=DecayTNHistDisplay /C/N=text0/F=0

DoWindow RiseTNHistDisplay
If (V_Flag)
	DoWindow /F RiseTNHistDisplay
Else
	Display
	DoWindow /C RiseTNHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AppendToGraph /W=RiseTNHistDisplay $GetDataFolder(0)+"RiseTAll_HistN"
EndFor
Legend /W=RiseTNHistDisplay /C/N=text0/F=0			


//Display Cummulative histograms
DoWindow PkAmpCummHistDisplay
If (V_Flag)
	DoWindow /F PkAmpCummHistDisplay
Else
	Display
	DoWindow /C PkAmpCummHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AppendToGraph /W=PkAmpCummHistDisplay $GetDataFolder(0)+"PkAmpAll_HistIn"
EndFor
Legend /W=PkAmpCummHistDisplay /C/N=text0/F=0	

DoWindow ISICummHistDisplay
If (V_Flag)
	DoWindow /F ISICummHistDisplay
Else
	Display
	DoWindow /C ISICummHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AppendToGraph /W=ISICummHistDisplay $GetDataFolder(0)+"ISIAll_HistIn"
EndFor
Legend /W=ISICummHistDisplay /C/N=text0/F=0

DoWindow DecayTCummHistDisplay
If (V_Flag)
	DoWindow /F DecayTCummHistDisplay
Else
	Display
	DoWindow /C DecayTCummHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AppendToGraph /W=DecayTCummHistDisplay $GetDataFolder(0)+"DecayTAll_HistIn"
EndFor
Legend /W=DecayTCummHistDisplay /C/N=text0/F=0


DoWindow RiseTCummHistDisplay
If (V_Flag)
	DoWindow /F RiseTCummHistDisplay
Else
	Display
	DoWindow /C RiseTCummHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AppendToGraph /W=RiseTCummHistDisplay $GetDataFolder(0)+"RiseTAll_HistIn"
EndFor
Legend /W=RiseTCummHistDisplay /C/N=text0/F=0			

//******************

//******************
//******************
//******************
//******************
//******************
//******************
//******************
//******************
//******************
//
//
//
//
//
//
//
End

//	PutTopGraphInNotebook()
//	Inserts a picture of the top graph in the notebook. If there is a selection in the notebook,
//	it overwrites the selection.
//$$$$$$


Function pt_MiniAnalyzeCells(ctrlName) : ButtonControl
String ctrlName


// Based on pt_MiniAnalysis
// Modified from pt_MiniAnalysis to separate analyzing all cells and pooling data 1/14/14

// changed ISI bin width to 10ms. 10/30/13
////pt_AnalWInFldrs2("pt_AverageWavesEasy"). Switched to pt_AverageWaves 10/20/13
// option for specifying CellNamePrefix rather than the previously hard-coded Cell_* 10/15/13 
// average and histograms of rise times were missing. Added those 10/9/13
// Switched from instantaneous frequency to ISIs for histograms and from instantaneous frequency to average frequency for bar plots. 07/14/13 (suggested by Sacha)
// remove decay time outliers 07/15/13
// ToDo:
// 1. When selecting the minimum number of events randomly from each cell, allow for selecting more than minimum number of events if the 
// minimum number is much less than what other cells have.
// eg. if cells have 20, 100, 150, 80, then instead of selecting 20 events from each cell, select 80 from each cell and all 20 from 1st cell. 
//String CellNamePrefix
String OldDf, ConditionFldrList, AnalFldr="root:ConditionAnal",ParListStr,HistParListStr
Variable NCond, i, PkPolarity, HistBinStart, HistBinWidth, HistNumBins,NParListItem,j,NHistParListItem,k, NumWaves
String ParList="PkAmpRelW;FreqPksW;DecayTW;RiseTW;"
//String HistParList="PkAmp;ISI;TauD;RiseT", WList, WStr, WList1, WStr1
String SealTestParList = "RsV;RInV;CmV;"
//String /G root:ExcludeWList
//String ExcludeWList=$"root:ExcludeWList"
NParListItem=ItemsInList(ParList)

//NHistParListItem=ItemsInList(HistParList)

Print "Starting mini Analysis at", time(), "on", date()

String LastUpdatedMM_DD_YYYY="10_15_2013"
Print "*********************************************************"
Print "pt_MiniAnalysis last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

//Wave /T AnalParNamesW	=	$pt_GetParWave("pt_MiniAnalysis", "ParNamesW")
//Wave /T AnalParW			=	$pt_GetParWave("pt_MiniAnalysis", "ParW")

//If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
//	Abort	"Cudn't find the parameter waves  pt_MiniAnalysisParW and/or pt_MiniAnalysisParNamesW!!!"
//EndIf

SVAR CellNamePrefix = root:AnalysisViewer:CellNamePrefix
NVAR DoSealTestAnal =  root:AnalysisViewer:DoSealTestAnal

Print "CellNamePrefix", CellNamePrefix
Print "DoSealTestAnal", DoSealTestAnal

//PrintAnalPar("pt_MiniAnalysis")

DoAlert 1, "Recent changes in seal test analysis: new vals for baseline and steadystate locations, CONTINUE?"
If (V_Flag==2)
		Abort "Aborting..."
EndIf


//DoAlert 1,"Press 'Yes', if parameters for pt_MiniAnalysis(), pt_PeakAnal(), pt_CalRsRinCmVmVClamp(), pt_MoveWavesMany have been adjusted and the folders for pt_MoveWavesMany exist. "
//If (V_Flag==2)
//	Abort "Aborting...."
//EndIf
NewDataFolder /O $AnalFldr

//******************
// pt_AnalWInFldrs2("pt_PeakAnal")
String BaseNameStr
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_PeakAnal", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_PeakAnal", "ParW")
BaseNameStr = AnalParW[16]
Print "BaseNameStr=",BaseNameStr
pt_AnalWInFldrs2("pt_PeakAnal")
//******************
//pt_AnalWInFldrs2("pt_CalRsRinCmVmVClamp")
if (DoSealTestAnal)
	//ParList = "RsV;RInV;CmV;"+ParList
	//NParListItem=ItemsInList(ParList)
	pt_AnalWInFldrs2("pt_CalRsRinCmVmVClamp")
endif
 //******************
//pt_AnalWInFldrs2("pt_AverageVals")
//Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")		
//Wave /T AnalParW				=	$pt_GetParWave("pt_AverageVals", "ParW")
//SaveNRestore("pt_AverageVals", 1) 
//AnalParW[0]	=	"RsV"	//DataWaveMatchStr
//AnalParW[1]	=	"-1"				//XStartVal
//AnalParW[2]	=	"-1"				//XEndVal
//AnalParW[3]	=	"RsV"	//BaseNameString
//AnalParW[4]	=	""					//SubFldr
//pt_AnalWInFldrs2("pt_AverageVals")
//AnalParW[0]	=	"RInV"	//DataWaveMatchStr
//AnalParW[3]	=	"RInV"	//BaseNameString
//pt_AnalWInFldrs2("pt_AverageVals")
//AnalParW[0]	=	"CmV"	//DataWaveMatchStr
//AnalParW[3]	=	"CmV"	//BaseNameString
//pt_AnalWInFldrs2("pt_AverageVals")
//SaveNRestore("pt_AverageVals", 2)
//******************
//pt_AnalWInFldrs2("pt_RemoveOutLiers1")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")		// remove decay time outliers 07/15/13
Wave /T AnalParW				=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")
SaveNRestore("pt_RemoveOutLiers1", 1)
AnalParW[0]	=	BaseNameStr+"NoOLDecayTW*" // DataWaveMatchStr
AnalParW[1]	=	"-1"					//SmoothFactor
AnalParW[2]	=	"1.5"					//TimesSD
AnalParW[3]	=	BaseNameStr+"DecayTF:"//SubFldr
AnalParW[4]	=	"1"						//UseMedian
pt_AnalWInFldrs2("pt_RemoveOutLiers1")
SaveNRestore("pt_RemoveOutLiers1", 2)
//******************
//******************
//pt_AnalWInFldrs2("pt_RemoveOutLiers1")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")		// remove rise time outliers 07/15/13
Wave /T AnalParW				=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")
SaveNRestore("pt_RemoveOutLiers1", 1)
AnalParW[0]	=	BaseNameStr+"RiseTW*" // DataWaveMatchStr
AnalParW[1]	=	"-1"					//SmoothFactor
AnalParW[2]	=	"1.5"					//TimesSD
AnalParW[3]	=	BaseNameStr+"RiseTF:"//SubFldr
AnalParW[4]	=	"1"						//UseMedian
pt_AnalWInFldrs2("pt_RemoveOutLiers1")
SaveNRestore("pt_RemoveOutLiers1", 2)
//******************

//pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
//TempRemove Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConctnWFrmFldrs1", "ParNamesW")		
//TempRemove Wave /T AnalParW				=	$pt_GetParWave("pt_ConctnWFrmFldrs1", "ParW")
//TempRemove SaveNRestore("pt_ConctnWFrmFldrs1", 1) 
//TempRemove AnalParW[0]	=	"TauD"+BaseNameStr+"*_NoOL" // DataWaveMatchStr
//TempRemove AnalParW[1]	=	BaseNameStr+"CropPksF:"	//DataFldr
//TempRemove AnalParW[2]	=	BaseNameStr+"TauD"	//DestWNameStr
//TempRemove pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
//TempRemove SaveNRestore("pt_ConctnWFrmFldrs1", 2) 
//******************
//pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParW")
SaveNRestore("pt_ConvertTSpikeToISI", 1) 
AnalParW[0]	=	BaseNameStr+"PkXW*" // DataWaveMatchStr
AnalParW[1]	=	""					//DataWaveNotMatchStr
AnalParW[2]	=	"_ISI"			//InsrtNewStr
AnalParW[3]	=	"0"					//  InsrtPosStr
AnalParW[4]	=	"1"					//ReplaceExisting 
AnalParW[5]	=	BaseNameStr+"PkXF:"	//SubFldr
AnalParW[6]	=	"0"						// Invert. Switched to 0 as Sacha suggested to plot ISI instead of frequnecies for histograms.  07/14/13
pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
SaveNRestore("pt_ConvertTSpikeToISI", 2)
//******************
//pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConctnWFrmFldrs1", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_ConctnWFrmFldrs1", "ParW")
SaveNRestore("pt_ConctnWFrmFldrs1", 1) 
AnalParW[0]	=	BaseNameStr+"PkXW*_ISI" // DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"PkXF:"			//DataFldr
AnalParW[2]	=	BaseNameStr+"ISI"			//DestWNameStr
pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
// using avg. freq. and not inst. freq.
//Duplicate /O $(BaseNameStr+"PkXF:"+ BaseNameStr+"ISI"), $(BaseNameStr+"ISI")

AnalParW[0]	=	BaseNameStr+"NoOLDecayTW*_NoOL*" // DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"DecayTF:"			//DataFldr
AnalParW[2]	=	BaseNameStr+"DecayT"			//DestWNameStr
pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
//Duplicate /O $(BaseNameStr+"DecayTF:"+ BaseNameStr+"DecayT"), $(BaseNameStr+"DecayT")

AnalParW[0]	=	BaseNameStr+"RiseTW*_NoOL*" // DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"RiseTF:"			//DataFldr
AnalParW[2]	=	BaseNameStr+"RiseT"			//DestWNameStr
pt_AnalWInFldrs2("pt_ConctnWFrmFldrs1")
//Duplicate /O $(BaseNameStr+"RiseTF:"+BaseNameStr+"RiseT"), $(BaseNameStr+"RiseT")


SaveNRestore("pt_ConctnWFrmFldrs1", 2) 
//******************
//Duplicate to  individual cell folders
Wave /T DuplAnalParNamesW		=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParNamesW")		
Wave /T DuplAnalParW				=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParW")
Duplicate /O/T DuplAnalParW, DuplAnalParWOrig

AnalParW[0] =  ""//DestFolderName
AnalParW[2] = ""//PrefixStr	
AnalParW[3] = ""//SuffixStr	
AnalParW[4] = "-1"//XStartVal
AnalParW[5] = "-1"//XEndVal

AnalParW[1] =	BaseNameStr+"DecayT"//DataWaveMatchStr		
AnalParW[6] =	BaseNameStr+"DecayTF:"//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1] =	BaseNameStr+"RiseT"//DataWaveMatchStr		
AnalParW[6] =	BaseNameStr+"RiseTF:"//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

Duplicate /O/T DuplAnalParWOrig, DuplAnalParW
KillWaves /Z  DuplAnalParWOrig

//******************

//pt_AnalWInFldrs2("pt_AverageWavesEasy"). Switched to pt_AverageWaves 10/20/13
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")
SaveNRestore("pt_AverageWaves", 1) 
AnalParW[0]	=	BaseNameStr+"CropPksW*" // DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"CropPksF:"	//DataFldrStr
AnalParW[2] 	=	BaseNameStr + "CropPk"	//BaseNameStr
AnalParW[3]	=	"1"							//PntsPerBin
AnalParW[4]	=	""							//ExcludeWNamesWStr
AnalParW[5]	=	"1"							//DisplayAvg

pt_AnalWInFldrs2("pt_AverageWaves")

SaveNRestore("pt_AverageWaves", 2) 
//******************
//******************

//pt_AnalWInFldrs2("pt_UserCommands")
//Wave /T AnalParNamesW		=	$pt_GetParWave("pt_UserCommands", "ParNamesW")
//Wave /T AnalParW				=	$pt_GetParWave("pt_UserCommands", "ParW")
//SaveNRestore("pt_UserCommands", 1) 
//AnalParW[0]	=	"Make /O/N=0"+ GetDataFolder(1) + BaseNameStr+"CropPksF:NoOLCropArea"; 
//AnalParW[0]	+=   "Wave wCropArea =" GetDataFolder(1) + BaseNameStr+"CropPksF:NoOLCropArea"; // CommandStr
//AnalParW[0] 	+=   wCropArea[0] = area(BaseNameStr + "CropPk")
//pt_AnalWInFldrs2("pt_UserCommands")
//root:Data:sEPSC:Cell_0003:sEPSCCropPksF:sEPSCCropPkAvg
//SaveNRestore("pt_UserCommands", 2) 
//******************

// moved from pooling to analysis so that we can use the averaged values for exporting analysis 09/16/14
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_AverageVals", "ParW")
Duplicate /O/T AnalParW, AvgValsAnalParW_Old

AnalParW[1]	=	"-1"				//XStartVal
AnalParW[2]	=	"-1"				//XEndVal
AnalParW[4]	=	""					//SubFldr

For(j=0;j<NParListItem;j+=1)
	ParListStr=StringFromList(j, ParList, ";")
	AnalParW[0]	=	BaseNameStr+ParListStr		//DataWaveMatchStr
	AnalParW[3]	=	ParListStr						//BaseNameString
	pt_AnalWInFldrs2("pt_AverageVals")
EndFor		

//pt_AnalWInFldrs2("pt_CalRsRinCmVmVClamp")
If (DoSealTestAnal)
	NParListItem=ItemsInList(SealTestParList)
	For(j=0;j<NParListItem;j+=1)
		ParListStr=StringFromList(j, SealTestParList, ";")
		AnalParW[0]	=	ParListStr		//DataWaveMatchStr
		AnalParW[3]	=	ParListStr		//BaseNameString
		pt_AnalWInFldrs2("pt_AverageVals")
	EndFor	
Endif
Duplicate /O/T AvgValsAnalParW_Old, AnalParW
KillWaves /Z AvgValsAnalParW_Old

End

Function pt_PoolNAvgMiniData(ctrlName) : ButtonControl
// Modified from pt_MiniAnalysis to separate analyzing all cells and pooling data 11/07/13
String ctrlName

String OldDf, ConditionFldrList, AnalFldr="root:ConditionAnal",ParListStr,HistParListStr
Variable NCond, i, PkPolarity, HistBinStart, HistBinWidth, HistNumBins,NParListItem,j,NHistParListItem,k, NumWaves//, NSealTestParListItem
//String SealTestParList = "RsV;RInV;CmV;", SealTestParListStr
String ParList="PkAmpRelW;FreqPksW;DecayT;RiseT;BLNoiseW;BLSmthDiffNoiseW", DisplayWinName, TraceNameStr1, TraceNameStr2
String HistParList="PkAmp;ISI;TauD;RiseT", WList, WStr, WList1, WStr1, tileCommand = ""
Variable pt_red, pt_Green, pt_blue, col_id

//String /G root:ExcludeWList
//String ExcludeWList=$"root:ExcludeWList"
NParListItem=ItemsInList(ParList)
//NSealTestParListItem=ItemsInList(SealTestParList)
NHistParListItem=ItemsInList(HistParList)


Print "Starting Mini data pooling at", time(), "on", date()

String LastUpdatedMM_DD_YYYY="01_14_2014"
Print "*********************************************************"
Print "pt_PoolNAvgMiniData last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

SVAR CellNamePrefix = root:AnalysisViewer:CellNamePrefix
NVAR DoSealTestAnal =  root:AnalysisViewer:DoSealTestAnal

If (DoSealTestAnal)
	ParList = "RsV;RInV;CmV;"+ParList
	NParListItem=ItemsInList(ParList)
EndIf

// color
Wave /T ColorLevelNamesW 	=	root:AnalysisViewer:ColorLevelNamesW
Wave ColorLevel_RedVal 		=	root:AnalysisViewer:ColorLevel_RedVal
Wave ColorLevel_BlueVal 		=	root:AnalysisViewer:ColorLevel_BlueVal
Wave ColorLevel_GreenVal 	= 	root:AnalysisViewer:ColorLevel_GreenVal
//

Print "CellNamePrefix", CellNamePrefix
Print "DoSealTestAnal", DoSealTestAnal

NewDataFolder /O $AnalFldr

String BaseNameStr
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_PeakAnal", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_PeakAnal", "ParW")
BaseNameStr = AnalParW[16]
Print "BaseNameStr=",BaseNameStr

//pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParW")

AnalParW[0]	=	AnalFldr	//DestFolderName
AnalParW[2]	=	"DataFldrName"				//PrefixStr
AnalParW[3]	=	""							//SuffixStr
AnalParW[4]	=	"-1"						//XStartVal
AnalParW[5]	=	"-1"						//XEndVal

SaveNRestore("pt_DuplicateWFrmFldrs", 1)

AnalParW[1]	=	BaseNameStr+"FreqPksW"		//DataWaveMatchStr
AnalParW[6]	=	""		//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"ISI"		//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"PkXF:"		//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"CropPk_Avg"		//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"CropPksF:"		//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"PkAmpRelW"		//DataWaveMatchStr
AnalParW[6]	=	""									//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"DecayT"		//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"DecayTF:"	//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"RiseT"		//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"RiseTF:"	//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

If (DoSealTestAnal ==1)
	AnalParW[1]	=	"RsV"		//DataWaveMatchStr
	AnalParW[6]	=	""			//SubFldr
	pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

	AnalParW[1]	=	"RInV"		//DataWaveMatchStr
	AnalParW[6]	=	""			//SubFldr
	pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

	AnalParW[1]	=	"CmV"		//DataWaveMatchStr
	AnalParW[6]	=	""			//SubFldr
	pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")
EndIF

AnalParW[1]	=	BaseNameStr+"BLNoiseW"		//DataWaveMatchStr
AnalParW[6]	=	""			//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"BLSmthDiffNoiseW"		//DataWaveMatchStr
AnalParW[6]	=	""			//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

SaveNRestore("pt_DuplicateWFrmFldrs", 2) 
//******************

OldDf = GetDataFolder(1)
SetDataFolder AnalFldr

SaveNRestore("pt_MoveWavesMany", 1) 
Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParW")
AnalParW[2]="1"//Overwrite
pt_MoveWavesMany()
SaveNRestore("pt_MoveWavesMany", 2)
SetDataFolder OldDf
//**

ConditionFldrList=AnalParW[1]		//ListDestFolderName
NCond=ItemsInList(ConditionFldrList,";")
OldDf = GetDataFolder(1)

For (i=0;i<NCond;i+=1)
SetDataFolder StringFromList(i, ConditionFldrList, ";")
//pt_AnalWInFldrs2("pt_AverageWaves")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")
SaveNRestore("pt_AverageWaves", 1) 
AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"CropPk_Avg" // DataWaveMatchStr
AnalParW[1]	=	""										//DataFldrStr
AnalParW[2] 	=	GetDataFolder(0) + "CropPk"	//BaseNameStr
AnalParW[3]	=	"1"							//PntsPerBin
AnalParW[4]	=	""								//ExcludeWNamesWStr
AnalParW[5]	=	"1"								//DisplayAvg
pt_AverageWaves()
SaveNRestore("pt_AverageWaves", 2) 
//Also calculate the average area & charge per sec as area*freq
WList=pt_SortWavesInFolder(CellNamePrefix+"*"+BaseNameStr+"CropPk_Avg", GetDataFolder(1))
WList1=pt_SortWavesInFolder(CellNamePrefix+"*"+BaseNameStr+"FreqPksW", GetDataFolder(1))

Numwaves=ItemsInList(WList, ";")
Make /O/N=(NumWaves) $(GetDataFolder(0)+"NoOLArea")
Wave wNoOLArea = $(GetDataFolder(0)+"NoOLArea")

Make /O/N=(NumWaves) $(GetDataFolder(0)+"ChargePerS")
Wave ChargePerS = $(GetDataFolder(0)+"ChargePerS")
For (j = 0; j<NumWaves; j+=1)
	
	WStr = StringFromList(j, WList, ";")
	Wave NoOLAreaTmp = $WStr
	wNoOLArea[j] = Area(NoOLAreaTmp)
	
	WStr1 = StringFromList(j, WList1, ";")
	Wave FreqPksW = $WStr1
	ChargePerS[j] = wNoOLArea[j]*FreqPksW[j]
EndFor

EndFor
SetDataFolder OldDf
//**

//******************
//pt_AnalWInFldrs2("pt_AppendWToGraph")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AppendWToGraph", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AppendWToGraph", "ParW")
SaveNRestore("pt_AppendWToGraph", 1)

DisplayWinName="AvgEvent"
DoWindow $DisplayWinName
If (V_Flag)
	DoWindow /F $DisplayWinName
Else
	Display
	DoWindow /C $DisplayWinName
EndIf

//AnalParW[0]="Cell_*"+BaseNameStr+"FreqPksW"
AnalParW[1]=DisplayWinName
AnalParW[2]="-1"
AnalParW[3]=""

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	AnalParW[0]=GetDataFolder(0) + "CropPk_Avg"
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
		If (col_id == -1)
			col_id = 0
		EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]			
	AnalParW[4]=Num2Str(pt_Red)+";"+Num2Str(pt_Green)+";"+Num2Str(pt_Blue)+";"
		
	pt_AppendWToGraph()
	//ModifyGraph /W=$DisplayWinName
EndFor		
SaveNRestore("pt_AppendWToGraph", 2)
//******************
 
//ConditionFldrList=AnalParW[1]		//ListDestFolderName
//NCond=ItemsInList(ConditionFldrList,";")
OldDf = GetDataFolder(1)

//******************
//pt_AnalWInFldrs2("pt_AverageVals")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageVals", "ParW")
SaveNRestore("pt_AverageVals", 1)

AnalParW[1]	=	"-1"				//XStartVal
AnalParW[2]	=	"-1"				//XEndVal
AnalParW[4]	=	""					//SubFldr

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	For(j=0;j<NParListItem;j+=1)
		ParListStr=StringFromList(j, ParList, ";")
 
		AnalParW[0]	=	CellNamePrefix+"*"+ParListStr			//DataWaveMatchStr
		AnalParW[3]	=	GetDataFolder(0)+ParListStr	//BaseNameString
		pt_AverageVals()
	EndFor		
EndFor
SaveNRestore("pt_AverageVals", 2)

//******************

For (i=0;i<NCond;i+=1)
SetDataFolder StringFromList(i, ConditionFldrList, ";")
col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
If (col_id == -1)
	col_id = 0
EndIf
pt_Red 		= ColorLevel_RedVal[col_id]
pt_Green 	= ColorLevel_GreenVal[col_id]
pt_Blue 		= ColorLevel_BlueVal[col_id]

	For(j=0;j<NParListItem;j+=1)
		ParListStr=StringFromList(j, ParList, ";")
		
		DisplayWinName=ParListStr+"Display"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		EndIf
		AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+ParListStr+"Avg"
		Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
		ModifyGraph 	/W=$DisplayWinName rgb($GetDataFolder(0)+ParListStr+"Avg")=(pt_Red, pt_Green, pt_Blue)
	EndFor
	
EndFor	

//******************
//pt_AnalWInFldrs2("pt_AppendWToGraph")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AppendWToGraph", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AppendWToGraph", "ParW")
SaveNRestore("pt_AppendWToGraph", 1)



DisplayWinName="AvgFrq_TimeCourse_Display"
DoWindow $DisplayWinName
If (V_Flag)
	DoWindow /F $DisplayWinName
Else
	Display
	DoWindow /C $DisplayWinName
EndIf

AnalParW[0]=CellNamePrefix+"*"+BaseNameStr+"FreqPksW"
AnalParW[1]=DisplayWinName
AnalParW[2]="-1"
AnalParW[3]=""

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
	If (col_id == -1)
		col_id = 0
	EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]			
	AnalParW[4]=Num2Str(pt_Red)+";"+Num2Str(pt_Green)+";"+Num2Str(pt_Blue)+";"
	pt_AppendWToGraph()
EndFor		
SaveNRestore("pt_AppendWToGraph", 2)


// Calculate averages and SEM

NewDataFolder /O $(AnalFldr+":Stats")

If (!WaveExists($(AnalFldr+":Stats:ConditionW")))
	Make /O/N=(NCond)/T $(AnalFldr+":Stats:ConditionW")
	Wave /T ConditionW=$(AnalFldr+":Stats:ConditionW")
Else
	Wave /T ConditionW=$(AnalFldr+":Stats:ConditionW")
EndIf

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	ConditionW[i]=GetDataFolder(0)
EndFor


	
For(j=0;j<NParListItem;j+=1)
	ParListStr=StringFromList(j, ParList, ";")
	If (!WaveExists($(AnalFldr+":Stats:"+ParListStr+"Avg")))
		Make /O/N=(NCond) $(AnalFldr+":Stats:"+ParListStr+"Avg")
		Wave wAvg=$(AnalFldr+":Stats:"+ParListStr+"Avg")
	Else
		Wave wAvg=$(AnalFldr+":Stats:"+ParListStr+"Avg")
	EndIf
	If (!WaveExists($(AnalFldr+":Stats:"+ParListStr+"SE")))
		Make /O/N=(NCond) $(AnalFldr+":Stats:"+ParListStr+"SE")
		Wave wSE=$(AnalFldr+":Stats:"+ParListStr+"SE")
	Else
		Wave wSE=$(AnalFldr+":Stats:"+ParListStr+"SE")
	EndIf
		
	For (i=0;i<NCond;i+=1)
		SetDataFolder StringFromList(i, ConditionFldrList, ";")
		Print GetDataFolder(1), ParListStr
		Wavestats $GetDataFolder(0)+ParListStr+"Avg"
		wAvg[i]=V_Avg
		wSE[i]=V_Sem
	EndFor
	
EndFor

// Draw category plots
//SetDataFolder $(AnalFldr+":Stats")
For(j=0;j<NParListItem;j+=1)
	ParListStr=StringFromList(j, ParList, ";")
	Display $(AnalFldr+":Stats:"+ParListStr+"Avg") vs $(AnalFldr+":Stats:ConditionW")
	DoWindow /C $ParListStr
	TraceNameStr1=ParListStr+"Avg"	// tracename is just the name of the wave without the entire path
	TraceNameStr2=AnalFldr+":Stats:"+ParListStr+"SE"
	ErrorBars /W=$ParListStr $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
	Legend/C/N=text0/F=0/A=RT	
EndFor


//******************
// Draw histograms from randomly selected pnts. To do this we need to select equal number of points from all cells. 
//Therefore we need to know minimum number of events that is common to all cells. However, if the next higher number of events is substantially higher then maybe we can use all events
// from cell with minimum number of events.
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_StatsOnWaves", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_StatsOnWaves", "ParW")
SaveNRestore("pt_StatsOnWaves", 1)
AnalParW[1]	=	""		//SubFldr
AnalParW[3]	=	"NPnts"	

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
//	For (k=0;k<NHistParListItem;k+=1)
//	HistParListStr=StringFromList(j, HistParList, ";")
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"PkAmpRelW"		//DataWaveMatchStr
	AnalParW[2]	=	GetDataFolder(0)+"PkAmpNPnts"			//OutWaveNameStr
	pt_StatsOnWaves()
	
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"ISI"		//DataWaveMatchStr
	AnalParW[2]	=	GetDataFolder(0)+"ISINPnts"			//OutWaveNameStr
	pt_StatsOnWaves()
	
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"DecayT"		//DataWaveMatchStr
	AnalParW[2]	=	GetDataFolder(0)+"DecayTNPnts"			//OutWaveNameStr
	pt_StatsOnWaves()
	
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"RiseT"		//DataWaveMatchStr
	AnalParW[2]	=	GetDataFolder(0)+"RiseTNPnts"			//OutWaveNameStr
	pt_StatsOnWaves()
	
EndFor										// StatsStr
SaveNRestore("pt_StatsOnWaves", 2)


Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RndSlctPntsFromW", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_RndSlctPntsFromW", "ParW")
SaveNRestore("pt_RndSlctPntsFromW", 1)





AnalParW[2]	=	""		//SubFldr

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
	
	Duplicate /O $(GetDataFolder(0)+"PkAmpNPnts"), $(GetDataFolder(0)+"PkAmpNPntsSrt")
	Wave NpntsTmpwSrt=$(GetDataFolder(0)+"PkAmpNPntsSrt")
	Sort NpntsTmpwSrt, NpntsTmpwSrt
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"PkAmpRelW"		//DataWaveMatchStr
	AnalParW[1]	=	Num2Str(NpntsTmpwSrt[0])							//NumPnts2Slct
	pt_RndSlctPntsFromW()
	
	Duplicate /O $(GetDataFolder(0)+"ISINPnts"), $(GetDataFolder(0)+"ISINPntsSrt")
	Wave NpntsTmpwSrt=$(GetDataFolder(0)+"ISINPntsSrt")
	Sort NpntsTmpwSrt, NpntsTmpwSrt
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"ISI"		//DataWaveMatchStr
	AnalParW[1]	=	Num2Str(NpntsTmpwSrt[0])							//NumPnts2Slct
	pt_RndSlctPntsFromW()
	
	Duplicate /O $(GetDataFolder(0)+"DecayTNPnts"), $(GetDataFolder(0)+"DecayTNPntsSrt")
	Wave NpntsTmpwSrt=$(GetDataFolder(0)+"DecayTNPntsSrt")
	Sort NpntsTmpwSrt, NpntsTmpwSrt
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"DecayT"		//DataWaveMatchStr
	AnalParW[1]	=	Num2Str(NpntsTmpwSrt[0])							//NumPnts2Slct
	pt_RndSlctPntsFromW()
	
	Duplicate /O $(GetDataFolder(0)+"RiseTNPnts"), $(GetDataFolder(0)+"RiseTNPntsSrt")
	Wave NpntsTmpwSrt=$(GetDataFolder(0)+"RiseTNPntsSrt")
	Sort NpntsTmpwSrt, NpntsTmpwSrt
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"RiseT"		//DataWaveMatchStr
	AnalParW[1]	=	Num2Str(NpntsTmpwSrt[0])							//NumPnts2Slct
	pt_RndSlctPntsFromW()
	
EndFor
SaveNRestore("pt_RndSlctPntsFromW", 2)


//******************
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConctnWFrmFldrs", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_ConctnWFrmFldrs", "ParW")
SaveNRestore("pt_ConctnWFrmFldrs", 1)



AnalParW[1]	=	""		//DataFldrStr
AnalParW[2]	= 	""		//DestWNameStr
AnalParW[3]	=	"-1"		// StartX 
AnalParW[4]	=	"-1"		// EndX

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
	AnalParW[0]	=	"Rnd_"+CellNamePrefix+"*"+BaseNameStr+"PkAmpRelW"		//DataWaveMatchStr
	pt_ConctnWFrmFldrs()
	Rename $GetDataFolder(0), $GetDataFolder(0)+"PkAmpAll"	// check if this name is already used
	
	AnalParW[0]	=	"Rnd_"+CellNamePrefix+"*"+BaseNameStr+"ISI"		//DataWaveMatchStr
	pt_ConctnWFrmFldrs()
	Rename $GetDataFolder(0), $GetDataFolder(0)+"ISIAll"	// check if this name is already used
	
	AnalParW[0]	=	"Rnd_"+CellNamePrefix+"*"+BaseNameStr+"DecayT"		//DataWaveMatchStr
	pt_ConctnWFrmFldrs()
	Rename $GetDataFolder(0), $GetDataFolder(0)+"DecayTAll"	// check if this name is already used
	
	AnalParW[0]	=	"Rnd_"+CellNamePrefix+"*"+BaseNameStr+"RiseT"		//DataWaveMatchStr
	pt_ConctnWFrmFldrs()
	Rename $GetDataFolder(0), $GetDataFolder(0)+"RiseTAll"	// check if this name is already used
	
EndFor	
//******************
SaveNRestore("pt_ConctnWFrmFldrs", 2)


//******************
//StatsQuantiles /Q $GetDataFolder(0)+BaseNameStr+"PkAmpRelW"

//Print "Using TimesSD*InterQuantileRange from Lower and Upper Quartile to find OutLiers"
//Print "Median =",V_Median,"LowerThresh =", V_Q25-TimesSD*V_IQR,"UpperThresh =", V_Q75+TimesSD*V_IQR

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_PeakAnal", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_PeakAnal", "ParW")

PkPolarity = Str2Num(AnalParW[4])



For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
	HistBinStart = 0
	HistBinWidth = (PkPolarity==1) ? 1e-12:-1e-12	// if the amplitude is in A
	//HistBinWidth = (PkPolarity==1) ? 1:-1	// if the amplitude is in pA
	HistNumBins = 150
	Print "HistBinStart,HistBinWidth,HistNumBins=",HistBinStart,HistBinWidth,HistNumBins
	Make/N=150/O $GetDataFolder(0)+"PkAmpAll_Hist";DelayUpdate
	Histogram/B={(HistBinStart),(HistBinWidth),(HistNumBins)} $GetDataFolder(0)+"PkAmpAll",$GetDataFolder(0)+"PkAmpAll_Hist"
	pt_CalNormHist(GetDataFolder(0)+"PkAmpAll_Hist") // 09/27/13
	pt_CalCummHist(GetDataFolder(0)+"PkAmpAll_Hist")
	
	HistBinStart = 0
	HistBinWidth = 0.01//0.4   different bins for ISI -  07/15/13
	HistNumBins = 1000//150   different bins for ISI -  07/15/13
	Print "HistBinStart,HistBinWidth,HistNumBins=",HistBinStart,HistBinWidth,HistNumBins
	Make/N=150/O $GetDataFolder(0)+"ISIAll_Hist";DelayUpdate
	Histogram/B={(HistBinStart),(HistBinWidth),(HistNumBins)} $GetDataFolder(0)+"ISIAll",$GetDataFolder(0)+"ISIAll_Hist"
	pt_CalNormHist(GetDataFolder(0)+"ISIAll_Hist") // 09/27/13
	pt_CalCummHist(GetDataFolder(0)+"ISIAll_Hist")
	
	HistBinStart = 0
	HistBinWidth = 0.00020
	HistNumBins = 60
	Print "HistBinStart,HistBinWidth,HistNumBins=",HistBinStart,HistBinWidth,HistNumBins
	Make/N=60/O $GetDataFolder(0)+"DecayTAll_Hist";DelayUpdate
	Histogram/B={(HistBinStart),(HistBinWidth),(HistNumBins)} $GetDataFolder(0)+"DecayTAll",$GetDataFolder(0)+"DecayTAll_Hist"
	pt_CalNormHist(GetDataFolder(0)+"DecayTAll_Hist") // 09/27/13
	pt_CalCummHist(GetDataFolder(0)+"DecayTAll_Hist")
	
	HistBinStart = 0
	HistBinWidth = 0.0001
	HistNumBins = 40
	Print "HistBinStart,HistBinWidth,HistNumBins=",HistBinStart,HistBinWidth,HistNumBins
	Make/N=40/O $GetDataFolder(0)+"RiseTAll_Hist";DelayUpdate
	Histogram/B={(HistBinStart),(HistBinWidth),(HistNumBins)} $GetDataFolder(0)+"RiseTAll",$GetDataFolder(0)+"RiseTAll_Hist"
	pt_CalNormHist(GetDataFolder(0)+"RiseTAll_Hist") // 09/27/13
	pt_CalCummHist(GetDataFolder(0)+"RiseTAll_Hist")
	
	
EndFor
//Display Normailzed histograms
DoWindow PkAmpNHistDisplay
If (V_Flag)
	DoWindow /F PkAmpNHistDisplay
Else
	Display
	DoWindow /C PkAmpNHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
	If (col_id == -1)
		col_id = 0
	EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]
	AppendToGraph /W=PkAmpNHistDisplay $GetDataFolder(0)+"PkAmpAll_HistN"
	ModifyGraph 	/W=PkAmpNHistDisplay rgb($GetDataFolder(0)+"PkAmpAll_HistN")=(pt_Red, pt_Green, pt_Blue)
EndFor
Legend /W=PkAmpNHistDisplay /C/N=text0/F=0	

DoWindow ISINHistDisplay
If (V_Flag)
	DoWindow /F ISINHistDisplay
Else
	Display
	DoWindow /C ISINHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
	If (col_id == -1)
		col_id = 0
	EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]
	AppendToGraph /W=ISINHistDisplay $GetDataFolder(0)+"ISIAll_HistN"
	ModifyGraph 	/W=ISINHistDisplay rgb($GetDataFolder(0)+"ISIAll_HistN")=(pt_Red, pt_Green, pt_Blue)
EndFor
Legend /W=ISINHistDisplay /C/N=text0/F=0

DoWindow DecayTNHistDisplay
If (V_Flag)
	DoWindow /F DecayTNHistDisplay
Else
	Display
	DoWindow /C DecayTNHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
	If (col_id == -1)
		col_id = 0
	EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]
	AppendToGraph /W=DecayTNHistDisplay $GetDataFolder(0)+"DecayTAll_HistN"
	ModifyGraph 	/W=DecayTNHistDisplay rgb($GetDataFolder(0)+"DecayTAll_HistN")=(pt_Red, pt_Green, pt_Blue)
EndFor
Legend /W=DecayTNHistDisplay /C/N=text0/F=0

DoWindow RiseTNHistDisplay
If (V_Flag)
	DoWindow /F RiseTNHistDisplay
Else
	Display
	DoWindow /C RiseTNHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
	If (col_id == -1)
		col_id = 0
	EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]
	AppendToGraph /W=RiseTNHistDisplay $GetDataFolder(0)+"RiseTAll_HistN"
	ModifyGraph 	/W=RiseTNHistDisplay rgb($GetDataFolder(0)+"RiseTAll_HistN")=(pt_Red, pt_Green, pt_Blue)
EndFor
Legend /W=RiseTNHistDisplay /C/N=text0/F=0			


//Display Cummulative histograms
DoWindow PkAmpCummHistDisplay
If (V_Flag)
	DoWindow /F PkAmpCummHistDisplay
Else
	Display
	DoWindow /C PkAmpCummHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
	If (col_id == -1)
		col_id = 0
	EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]
	AppendToGraph /W=PkAmpCummHistDisplay $GetDataFolder(0)+"PkAmpAll_HistIn"
	ModifyGraph 	/W=PkAmpCummHistDisplay rgb($GetDataFolder(0)+"PkAmpAll_HistIn")=(pt_Red, pt_Green, pt_Blue)
EndFor
Legend /W=PkAmpCummHistDisplay /C/N=text0/F=0	

DoWindow ISICummHistDisplay
If (V_Flag)
	DoWindow /F ISICummHistDisplay
Else
	Display
	DoWindow /C ISICummHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
	If (col_id == -1)
		col_id = 0
	EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]
	AppendToGraph /W=ISICummHistDisplay $GetDataFolder(0)+"ISIAll_HistIn"
	ModifyGraph 	/W=ISICummHistDisplay rgb($GetDataFolder(0)+"ISIAll_HistIn")=(pt_Red, pt_Green, pt_Blue)
EndFor
Legend /W=ISICummHistDisplay /C/N=text0/F=0

DoWindow DecayTCummHistDisplay
If (V_Flag)
	DoWindow /F DecayTCummHistDisplay
Else
	Display
	DoWindow /C DecayTCummHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
	If (col_id == -1)
		col_id = 0
	EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]
	AppendToGraph /W=DecayTCummHistDisplay $GetDataFolder(0)+"DecayTAll_HistIn"
	ModifyGraph 	/W=DecayTCummHistDisplay rgb($GetDataFolder(0)+"DecayTAll_HistIn")=(pt_Red, pt_Green, pt_Blue)
EndFor
Legend /W=DecayTCummHistDisplay /C/N=text0/F=0


DoWindow RiseTCummHistDisplay
If (V_Flag)
	DoWindow /F RiseTCummHistDisplay
Else
	Display
	DoWindow /C RiseTCummHistDisplay
EndIf
For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
	If (col_id == -1)
		col_id = 0
	EndIf
	pt_Red 		= ColorLevel_RedVal[col_id]
	pt_Green 	= ColorLevel_GreenVal[col_id]
	pt_Blue 		= ColorLevel_BlueVal[col_id]
	AppendToGraph /W=RiseTCummHistDisplay $GetDataFolder(0)+"RiseTAll_HistIn"
	ModifyGraph 	/W=RiseTCummHistDisplay rgb($GetDataFolder(0)+"RiseTAll_HistIn")=(pt_Red, pt_Green, pt_Blue)
EndFor
Legend /W=RiseTCummHistDisplay /C/N=text0/F=0			

//******************
Execute tileCommand
End




//	PutTopGraphInNotebook()
//	Inserts a picture of the top graph in the notebook. If there is a selection in the notebook,
//	it overwrites the selection.
Function pt_PutTopGraphInNotebook()

// copied from  Igor Pro Folder:Examples:Feature Demos:Web Page Demo.pxp 08/30/12
	String topGraphName
	topGraphName = WinName(0, 1)
	if (strlen(topGraphName) == 0)
		DoAlert 0, "There are no graphs to put in the notebook."
		return -1
	endif
	
	String nb = "DataAnalysisNotebook"
	DoWindow $nb
	if (V_flag == 0)							// Does the notebook already exist?
		NewNotebook/F=1/N=$nb as "Data Analysis Notebook"
		Notebook $nb, showRuler=0				// Hide the ruler.
	endif
	
	// Insert identification of the Igor user. This is so that WaveMetrics can tell who is using this HTML and upload features.
//	SVAR IgorUserInfo=root:Packages:WebPageInfo:gIgorUserInfo		// Info entered into the setup dialog.
//	Notebook $nb, text= IgorUserInfo + "\r\r"
	
	// Insert some explanatory text.
//	Notebook $nb, text="z = exp(-((x-0)/.75)^2) * exp(-((y-0)/.75)^2)\r\r"
	
	// Insert the graph.
	Variable mode = -5							// PNG (This determine the format of graphics in the notebook, not in the HTML file. See help for SaveNotebook.)
	Variable flags = 1							// Color
	Notebook $nb, picture={$topGraphName, mode, flags}
End

Function pt_CreateOrEdit()
// Function to create (if  not existing) and edit ExcludeWNames. Inspired from pt_EditFuncPars()
String TableName = "ExcludeW_Edit"
DoWindow /F $TableName
If	(!V_Flag)
	Edit /K=1/N=$TableName
EndIf
If (WaveExists($"ExcludeW"))
	AppendToTable $"ExcludeW"
Else 
	Make /T/N=0 $"ExcludeW"
	AppendToTable $"ExcludeW"
EndIf

End


//------------pt_FIAnalysis Start
Function pt_FIAnalysis()
// Based on pt_MiniAnalysis
// This is a function to carry out the full FI-analysis including averaging, etc. Earlier many of these steps were being carried out manually
String CellNamePrefix
Variable DoSealTestAnal
String OldDf, ConditionFldrList, AnalFldr="root:ConditionAnal",ParStr
Variable NCond, i, PkPolarity, HistBinStart, HistBinWidth, HistNumBins,NSealTestParList,j,k,NSpkAnalScalarParList
String DisplayWinName, TraceNameStr1, TraceNameStr2
String SealTestParList="RsV;RInV;CmV;"
String SpkAnalScalarParList="WSpikeFreq;EOPAHPY"
//String /G root:ExcludeWList
//String ExcludeWList=$"root:ExcludeWList"
NSealTestParList=ItemsInList(SealTestParList)
NSpkAnalScalarParList=ItemsInList(SpkAnalScalarParList)


String LastUpdatedMM_DD_YYYY="10_15_2013"
Print "*********************************************************"
Print "pt_FIAnalysis last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_FIAnalysis", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_FIAnalysis", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_FIAnalysisParW and/or pt_FIAnalysisParNamesW!!!"
EndIf

CellNamePrefix		=	AnalParW[0]
DoSealTestAnal		= 	Str2Num(AnalParW[1])

PrintAnalPar("pt_FIAnalysis")


DoAlert 1,"Press 'Yes', if Cell_*RepsInfo waves waves have been created and edited for each cell" 
If (V_Flag==2)
	Abort "Aborting...."
EndIf

DoAlert 1,"Press 'Yes', if parameters for pt_SpikeAnal(), pt_CalRsRinCmVmVClamp(), pt_MoveWavesMany have been adjusted and the folders for pt_MoveWavesMany exist. "
If (V_Flag==2)
	Abort "Aborting...."
EndIf
NewDataFolder /O $AnalFldr

//******************
// pt_AnalWInFldrs2("pt_SpikeAnal")
String BaseNameStr
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SpikeAnal", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_SpikeAnal", "ParW")
BaseNameStr = AnalParW[14]
Print "BaseNameStr=",BaseNameStr
pt_AnalWInFldrs2("pt_SpikeAnal")
//******************
//pt_AnalWInFldrs2("pt_CalRsRinCmVmIClamp")
If (DoSealTestAnal)
	 pt_AnalWInFldrs2("pt_CalRsRinCmVmIClamp")
 EndIf
 //******************
//pt_AnalWInFldrs2("pt_ExtractFromWaveNote")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractFromWaveNote", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractFromWaveNote", "ParW")
SaveNRestore("pt_ExtractFromWaveNote", 1)
AnalParW[0]	=	CellNamePrefix+"*"				//DataWaveMatchStr
AnalParW[1]	=	"RawData:"				//DataFldrStr	
AnalParW[2]	=	"Stim Amp."	//KeyStrName
AnalParW[3]	=	"0"				//ParIsStr
AnalParW[4]	=	"CurrW"		//OutWNameStr
pt_AnalWInFldrs2("pt_ExtractFromWaveNote")
SaveNRestore("pt_ExtractFromWaveNote", 2)

//******************
//pt_AnalWInFldrs2("pt_ExtractRepsNSrt")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractRepsNSrt", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractRepsNSrt", "ParW")

SaveNRestore("pt_ExtractRepsNSrt", 1)
AnalParW[0]	=	"CurrW"		//SortKeyWName
AnalParW[2]	=	"pt_RepsInfo"			//RangeW	
AnalParW[3]	=	"DataFldrName"				//RangeWPrefixStr
AnalParW[4]	=	""		//SortKeyOutWName
AnalParW[5]	=	""		//SortParOutWName

If (DoSealTestAnal ==1)
For(j=0;j<NSealTestParList;j+=1)
	ParStr=StringFromList(j, SealTestParList, ";")
	AnalParW[1]	=	ParStr			//SortParWName
	pt_AnalWInFldrs2("pt_ExtractRepsNSrt")
EndFor
EndIf

For(j=0;j<NSpkAnalScalarParList;j+=1)
	ParStr=StringFromList(j, SpkAnalScalarParList, ";")
	AnalParW[1]	=	BaseNameStr+ParStr			//SortParWName
	pt_AnalWInFldrs2("pt_ExtractRepsNSrt")
EndFor


//AnalParW[1]	=	BaseNameStr+"WSpikeFreq"				//SortParWName
//pt_AnalWInFldrs2("pt_ExtractRepsNSrt")

//AnalParW[1]	=	BaseNameStr+"EOPAHPY"				//SortParWName
//pt_AnalWInFldrs2("pt_ExtractRepsNSrt")
	
SaveNRestore("pt_ExtractRepsNSrt", 2)

//******************
//pt_AnalWInFldrs2("pt_ExtractWRepsNSrt")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParW")

SaveNRestore("pt_ExtractWRepsNSrt", 1)
AnalParW[0]	=	"CurrW"		//SortKeyWName
AnalParW[3]	=	"pt_RepsInfo"			//RangeW	
AnalParW[4]	=	"DataFldrName"				//RangeWPrefixStr

AnalParW[1]	=	BaseNameStr+"FWFracMW"			//SortParWList
AnalParW[2]	=	BaseNameStr+"FWFracMF:"	//SubFldrList
pt_AnalWInFldrs2("pt_ExtractWRepsNSrt")

AnalParW[1]	=	BaseNameStr+"PeakAbsXW"			//SortParWList
AnalParW[2]	=	BaseNameStr+"PeakAbsXF:"	//SubFldrList
pt_AnalWInFldrs2("pt_ExtractWRepsNSrt")

SaveNRestore("pt_ExtractWRepsNSrt", 2)
//******************
//pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParW")
SaveNRestore("pt_ConvertTSpikeToISI", 1) 
AnalParW[0]	=	"S"+BaseNameStr+"PeakAbsXW*" // DataWaveMatchStr
AnalParW[1]	=	""					//DataWaveNotMatchStr
AnalParW[2]	=	"_InstFrq"			//InsrtNewStr
AnalParW[3]	=	"3"					//  InsrtPosStr
AnalParW[4]	=	"1"					//ReplaceExisting 
AnalParW[5]	=	BaseNameStr+"PeakAbsXF:"	//SubFldr
AnalParW[6]	=	"1"						// Invert
pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
SaveNRestore("pt_ConvertTSpikeToISI", 2)

//******************
//pt_AnalWInFldrs2("pt_RemoveOutLiers1")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")
SaveNRestore("pt_RemoveOutLiers1", 1) 
AnalParW[0]	=	"S"+BaseNameStr+"_InstFrqW*" // DataWaveMatchStr
AnalParW[1]	=	"-1"					//SmoothFactor
AnalParW[2]	=	"3"					//TimesSD
AnalParW[3]	=	BaseNameStr+"PeakAbsXF:"	//SubFldr
AnalParW[4]	=	"1"						//UseMedian
pt_AnalWInFldrs2("pt_RemoveOutLiers1")
SaveNRestore("pt_RemoveOutLiers1", 2)

//******************
//pt_AnalWInFldrs2("pt_AverageVals")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageVals", "ParW")
SaveNRestore("pt_AverageVals", 1)

AnalParW[1]	=	"-1"				//XStartVal
AnalParW[2]	=	"-1"				//XEndVal
AnalParW[4]	=	BaseNameStr+"PeakAbsXF:"					//SubFldr

AnalParW[0]	=	 "S"+BaseNameStr+"_InstFrqW*_0_NoOL"			//DataWaveMatchStr
AnalParW[3]	=	BaseNameStr+"_InstFrq_0"							//BaseNameString
pt_AnalWInFldrs2("pt_AverageVals")

AnalParW[0]	=	 "S"+BaseNameStr+"_InstFrqW*_1_NoOL"			//DataWaveMatchStr
AnalParW[3]	=	BaseNameStr+"_InstFrq_1"							//BaseNameString
pt_AnalWInFldrs2("pt_AverageVals")


AnalParW[4]	=	BaseNameStr+"FWFracMF:"				//SubFldr

AnalParW[0]	=	 "S"+BaseNameStr+"FWFracMW*_0"			//DataWaveMatchStr
AnalParW[3]	=	BaseNameStr+"_SpkFWHM_0"			//BaseNameString
pt_AnalWInFldrs2("pt_AverageVals")

AnalParW[0]	=	 "S"+BaseNameStr+"FWFracMW*_1"			//DataWaveMatchStr
AnalParW[3]	=	 BaseNameStr+"_SpkFWHM_1"			//BaseNameString
pt_AnalWInFldrs2("pt_AverageVals")


SaveNRestore("pt_AverageVals", 2)
//******************
//pt_AnalWInFldrs2("pt_AverageWaves")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")

SaveNRestore("pt_AverageWaves", 1)

AnalParW[1]	=	""	//DataFldrStr
AnalParW[3]	=	"1"//PntsPerBin
AnalParW[4]	=	""//ExcludeWNamesWStr
AnalParW[5]	=	"1"//DisplayAvg

If (DoSealTestAnal ==1)
For(j=0;j<NSealTestParList;j+=1)
	ParStr=StringFromList(j, SealTestParList, ";")
	AnalParW[0]	=	ParStr+"*Srt"			//DataWaveMatchStr
	AnalParW[2]	=	ParStr					//BaseNameStr
	pt_AnalWInFldrs2("pt_AverageWaves")
EndFor
EndIf

For(j=0;j<NSpkAnalScalarParList;j+=1)
	ParStr=StringFromList(j, SpkAnalScalarParList, ";")
	AnalParW[0]	=	BaseNameStr+ParStr+"*Srt"			//DataWaveMatchStr
	AnalParW[2]	=	BaseNameStr+ParStr					//BaseNameStr
	pt_AnalWInFldrs2("pt_AverageWaves")
EndFor

//For(j=0;j<NSpkAnalParListItem;j+=1)
//	SpkAnalParListStr=StringFromList(j, SpkAnalParList, ";")
//	AnalParW[0]	=	BaseNameStr+"WSpikeFreq"+"*Srt"			//DataWaveMatchStr
//	AnalParW[2]	=	BaseNameStr+"SpkAvgFrq"						//BaseNameStr
//	pt_AnalWInFldrs2("pt_AverageWaves")
	
//	AnalParW[0]	=	BaseNameStr+"EOPAHPY"+"*Srt"			//DataWaveMatchStr
//	AnalParW[2]	=	BaseNameStr+"EopAhpY"						//BaseNameStr
//	pt_AnalWInFldrs2("pt_AverageWaves")
//EndFor

AnalParW[0]	=	BaseNameStr+"_InstFrq_*Avg"				//DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"PeakAbsXF:"		//DataFldrStr
AnalParW[2]	=	BaseNameStr+"InstFrq"			//BaseNameStr
pt_AnalWInFldrs2("pt_AverageWaves")

AnalParW[0]	=	BaseNameStr+"_SpkFWHM_*Avg"				//DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"FWFracMF:"		//DataFldrStr
AnalParW[2]	=	BaseNameStr+"SpkFWHM"			//BaseNameStr
pt_AnalWInFldrs2("pt_AverageWaves")

SaveNRestore("pt_AverageWaves", 2)

//******************
//pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParW")

AnalParW[0]	=	AnalFldr	//DestFolderName
AnalParW[2]	=	"DataFldrName"				//PrefixStr
AnalParW[3]	=	""							//SuffixStr
AnalParW[4]	=	"-1"						//XStartVal
AnalParW[5]	=	"-1"						//XEndVal
AnalParW[6]	=	""		//SubFldr

SaveNRestore("pt_DuplicateWFrmFldrs", 1)

AnalParW[1]	=	"*_Avg"		//DataWaveMatchStr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"InstFrq_Avg"			//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"PeakAbsXF:"				//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"SpkFWHM_Avg"				//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"FWFracMF:"				//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

SaveNRestore("pt_DuplicateWFrmFldrs", 2) 

//******************

OldDf = GetDataFolder(1)
SetDataFolder AnalFldr

SaveNRestore("pt_MoveWavesMany", 1) 
Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParW")
AnalParW[2]="1"//Overwrite
pt_MoveWavesMany()
SaveNRestore("pt_MoveWavesMany", 2)
SetDataFolder OldDf
 
ConditionFldrList=AnalParW[1]		//ListDestFolderName
NCond=ItemsInList(ConditionFldrList,";")
OldDf = GetDataFolder(1)

//******************
If (DoSealTestAnal ==1)
//pt_AnalWInFldrs2("pt_AverageVals")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageVals", "ParW")
SaveNRestore("pt_AverageVals", 1)

AnalParW[1]	=	"-1"				//XStartVal
AnalParW[2]	=	"-1"				//XEndVal
AnalParW[4]	=	""					//SubFldr

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	For(j=0;j<NSealTestParList;j+=1)
		ParStr=StringFromList(j, SealTestParList, ";")
 
		AnalParW[0]	=	CellNamePrefix+"*"+ParStr+"_Avg"//DataWaveMatchStr
		AnalParW[3]	=	GetDataFolder(0)+ParStr	//BaseNameString
		pt_AverageVals()

//AnalParW[0]	=	"Cell_*RInV"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"RInV"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*CmV"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"CmV"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*"+BaseNameStr+"InstFrq"		//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"InstFrq"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*"+BaseNameStr+"PkAmpRelW"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"PkAmp"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*"+BaseNameStr+"TauD"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"TauD"	//BaseNameString
//pt_AverageVals()
	EndFor
EndFor
SaveNRestore("pt_AverageVals", 2)
EndIf

//******************
//display
If (DoSealTestAnal ==1)
For (i=0;i<NCond;i+=1)
SetDataFolder StringFromList(i, ConditionFldrList, ";")
	For(j=0;j<NSealTestParList;j+=1)
		ParStr=StringFromList(j, SealTestParList, ";")
		
		DisplayWinName=ParStr+"Display"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		EndIf
		AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+ParStr+"Avg"
		Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
	EndFor
	
EndFor
EndIf

//******************
//pt_AnalWInFldrs2("pt_AppendWToGraph")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AppendWToGraph", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AppendWToGraph", "ParW")
SaveNRestore("pt_AppendWToGraph", 1)


For(j=0;j<NSpkAnalScalarParList;j+=1)
	ParStr=StringFromList(j, SpkAnalScalarParList, ";")
	DisplayWinName=ParStr+"_Display"
	DoWindow $DisplayWinName
	If (V_Flag)
		DoWindow /F $DisplayWinName
	Else
		Display
		DoWindow /C $DisplayWinName
	EndIf
	
	AnalParW[0]=CellNamePrefix+"*"+BaseNameStr+ParStr+"_Avg"
	AnalParW[1]=DisplayWinName
	AnalParW[2]="-1"
	AnalParW[3]=""
	
	For (i=0;i<NCond;i+=1)
		SetDataFolder StringFromList(i, ConditionFldrList, ";")
		pt_AppendWToGraph()
	EndFor		
	SaveNRestore("pt_AppendWToGraph", 2)

EndFor


// Calculate averages and SEM

NewDataFolder /O $(AnalFldr+":Stats")

If (!WaveExists($(AnalFldr+":Stats:ConditionW")))
	Make /O/N=(NCond)/T $(AnalFldr+":Stats:ConditionW")
	Wave /T ConditionW=$(AnalFldr+":Stats:ConditionW")
Else
	Wave /T ConditionW=$(AnalFldr+":Stats:ConditionW")
EndIf

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	ConditionW[i]=GetDataFolder(0)
EndFor


If (DoSealTestAnal ==1)	
For(j=0;j<NSealTestParList;j+=1)
	ParStr=StringFromList(j, SealTestParList, ";")
	If (!WaveExists($(AnalFldr+":Stats:"+ParStr+"Avg")))
		Make /O/N=(NCond) $(AnalFldr+":Stats:"+ParStr+"Avg")
		Wave wAvg=$(AnalFldr+":Stats:"+ParStr+"Avg")
	Else
		Wave wAvg=$(AnalFldr+":Stats:"+ParStr+"Avg")
	EndIf
	
	If (!WaveExists($(AnalFldr+":Stats:"+ParStr+"SE")))
		Make /O/N=(NCond) $(AnalFldr+":Stats:"+ParStr+"SE")
		Wave wSE=$(AnalFldr+":Stats:"+ParStr+"SE")
	Else
		Wave wSE=$(AnalFldr+":Stats:"+ParStr+"SE")
	EndIf
		
	For (i=0;i<NCond;i+=1)
		SetDataFolder StringFromList(i, ConditionFldrList, ";")
		Print GetDataFolder(1)
		Wavestats $GetDataFolder(0)+ParStr+"Avg"
		wAvg[i]=V_Avg
		wSE[i]=V_Sem
	EndFor
EndFor
EndIf

// Draw category plots
//SetDataFolder $(AnalFldr+":Stats")
If (DoSealTestAnal ==1)
For(j=0;j<NSealTestParList;j+=1)
	ParStr=StringFromList(j, SealTestParList, ";")
	Display $(AnalFldr+":Stats:"+ParStr+"Avg") vs $(AnalFldr+":Stats:ConditionW")
	DoWindow /C $ParStr
	TraceNameStr1=ParStr+"Avg"	// tracename is just the name of the wave without the entire path
	TraceNameStr2=AnalFldr+":Stats:"+ParStr+"SE"
	ErrorBars /W=$ParStr $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
	Legend/C/N=text0/F=0/A=RT
//	SetAxis /W=$ParStr Left 0,inf	
EndFor
EndIf


//*****************
//pt_AnalWInFldrs2("pt_AverageWaves")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")

SaveNRestore("pt_AverageWaves", 1)

AnalParW[1]	=	""	//DataFldrStr
AnalParW[3]	=	"1"//PntsPerBin
AnalParW[4]	=	""//ExcludeWNamesWStr
AnalParW[5]	=	"1"//DisplayAvg

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
	For(j=0;j<NSpkAnalScalarParList;j+=1)
		ParStr=StringFromList(j, SpkAnalScalarParList, ";")
		AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+ParStr+"_Avg"//DataWaveMatchStr
		AnalParW[2]	=	 GetDataFolder(0)+ParStr			//BaseNameStr
		pt_AverageWaves()
	EndFor
	
	
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"InstFrq_Avg"//DataWaveMatchStr
	AnalParW[2]	=	 GetDataFolder(0)+"InstFrq"				//BaseNameStr
	pt_AverageWaves()
	
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"SpkFWHM_Avg"//DataWaveMatchStr
	AnalParW[2]	=	 GetDataFolder(0)+"SpkFWHM"				//BaseNameStr
	pt_AverageWaves()
	
EndFor

SaveNRestore("pt_AverageWaves", 2)
//*****************
//display
For (i=0;i<NCond;i+=1)
SetDataFolder StringFromList(i, ConditionFldrList, ";")

	For(j=0;j<NSpkAnalScalarParList;j+=1)
		ParStr=StringFromList(j, SpkAnalScalarParList, ";")
		DisplayWinName="Condition_"+ParStr+"_Display"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		Endif
		TraceNameStr1=GetDataFolder(0)+ParStr+"_Avg"	// tracename is just the name of the wave without the entire path
		TraceNameStr2=GetDataFolder(0)+ParStr	+"_SE"
		AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+ParStr+"_Avg"
		ErrorBars /W=$DisplayWinName $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
		Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
	EndFor	
	
		DisplayWinName="Condition_InstFrq_Display"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		Endif
	TraceNameStr1=GetDataFolder(0)+"InstFrq"	+"_Avg"	// tracename is just the name of the wave without the entire path
	TraceNameStr2=GetDataFolder(0)+"InstFrq"	+"_SE"
	AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+"InstFrq"+"_Avg"
	ErrorBars /W=$DisplayWinName $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
	Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
	
	
		DisplayWinName="Condition_SpkFWHM_Display"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		Endif
	TraceNameStr1=GetDataFolder(0)+"SpkFWHM"	+"_Avg"	// tracename is just the name of the wave without the entire path
	TraceNameStr2=GetDataFolder(0)+"SpkFWHM"	+"_SE"
	AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+"SpkFWHM"+"_Avg"
	ErrorBars /W=$DisplayWinName $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
	Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
	
	
EndFor
	
	
	
//*****************

End

//------------pt_FIAnalysis End

Function pt_HideAxis()
ModifyGraph nticks=0,noLabel=2,axThick=0
End

Function pt_UnHideAxis()
ModifyGraph axThick=1, nTicks = 5, noLabel=0// nticks=0,noLabel=2,axThick=0
End

Function pt_ExportWavesAsText()
String DataWaveMatchStr, HDFldrName, SaveFileName, StartWaveNum, NumWaves, SubFldr

SVAR ParentDataFolder = root:ParentDataFolder


String WavListAll, WList, WaveNameStr, FullName, OrigParentDataFolder, TmpFolderName
Variable i 

TmpFolderName = "root:TmpFolder"
OrigParentDataFolder = ParentDataFolder
ParentDataFolder = TmpFolderName		// so as not to mix waves with those in ParentDataFolder
NewDataFolder /O root:TmpFolder

String LastUpdatedMM_DD_YYYY="01_09_2013"
Print "*********************************************************"
Print "pt_ExportWavesAsText last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_ExportWavesAsText", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_ExportWavesAsText", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_ScalarOpOnWavesParW and/or pt_ScalarOpOnWavesParNamesW!!!"
EndIf


DataWaveMatchStr		=	AnalParW[0]
HDFldrName			= 	AnalParW[1]
SaveFileName			=	AnalParW[2]
StartWaveNum			=	AnalParW[3]	// count starts at zero
NumWaves				= 	AnalParW[4]
SubFldr					= 	AnalParW[5]

DoAlert 0, "Check prog works fine with DataFldr and SubFldr change in pt_SaveWsAsText 03_15_13. Maybe use pt_SaveTableAsText"

PrintAnalPar("pt_ExportWavesAsText")

// load waves
Wave /T AnalParNamesW	=	$pt_GetParWave("pt_LoadWFrmFldrs", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_LoadWFrmFldrs", "ParW")
SaveNRestore("pt_LoadWFrmFldrs", 1)
AnalParW[1]	=	"RawData:"
AnalParW[2]	=	"1"
pt_AnalWInFldrs2("pt_LoadWFrmFldrs")
//pt_LoadWFrmFldrs()
SaveNRestore("pt_LoadWFrmFldrs", 2)

// save as text
Wave /T AnalParNamesW	=	$pt_GetParWave("pt_SaveWsAsText", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_SaveWsAsText", "ParW")
SaveNRestore("pt_SaveWsAsText", 1)
AnalParW[2] = HDFldrName
AnalParW[3] = SaveFileName
AnalParW[4] = StartWaveNum	// count starts at zero
AnalParW[5] = NumWaves
AnalParW[6] = SubFldr
pt_AnalWInFldrs2("pt_SaveWsAsText")
//pt_SaveWsAsText()
SaveNRestore("pt_SaveWsAsText", 2)


// kill waves
Killdatafolder $TmpFolderName
//Wave /T AnalParNamesW	=	$pt_GetParWave("pt_KillWFrmFldrs", "ParNamesW")
//Wave /T AnalParW			=	$pt_GetParWave("pt_KillWFrmFldrs", "ParW")
//SaveNRestore("pt_KillWFrmFldrs", 1)
//AnalParW[0] = 	GetDataFolder(0)+"*"
//AnalParW[1] = ""	//ExcludeWList	
//AnalParW[2] = ""	//SubFldr
//pt_AnalWInFldrs2("pt_KillWFrmFldrs")
//pt_KillWFrmFldrs()
//SaveNRestore("pt_KillWFrmFldrs", 2)
//KillDataFolder /Z GetDataFolder(0)

//OrigParentDataFolder = ParentDataFolder
ParentDataFolder = OrigParentDataFolder
End

Function pt_SaveWsAsText()
// added DataFldrStr parameter, so that pt_AnalWInFldrs2 does not automatically change DataWaveMatchStr 03_16_13
// corrected for insufficient waves 03_16_13
String DataWaveMatchStr, DataFldrStr,HDFldrName, SaveFileName, SubFldr
Variable StartWaveNum, NumWaves

String WavListAll, WList, WaveNameStr, FullName, OrigParentDataFolder, OldDf, DfName, AlertMessage
Variable i, NumItems 

Wave /T AnalParNamesW	=$("root:FuncParWaves:pt_SaveWsAsText"+"ParNamesW")
Wave /T AnalParW		=$("root:FuncParWaves:pt_SaveWsAsText"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_pt_SaveWsAsTextParW and/or pt_pt_SaveWsAsTextParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				= 	AnalParW[1]
HDFldrName			= 	AnalParW[2]
SaveFileName			=	AnalParW[3]
StartWaveNum			=	Str2Num(AnalParW[4])	// count starts at zero
NumWaves				= 	Str2Num(AnalParW[5])
SubFldr					= 	AnalParW[6]	// 03_15_13

PrintAnalPar("pt_SaveWsAsText")

DfName = GetDataFolder(0)
OldDf = GetDataFolder(1)
SetDataFolder $( GetDataFolder(1)+SubFldr)
print "Current Data Folder", GetDataFolder(0)

WavListAll	= pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1))
NumItems = ItemsInList(WavListAll, ";")
If (NumItems < (StartWaveNum+ NumWaves))
	AlertMessage = "Warning!!! Num of waves is = "+ Num2Str(NumItems)+ ". Not enough waves!"//, " less than "+ Num2Str(StartWaveNum+ NumWaves)
	Print AlertMessage
	DoAlert 0, AlertMessage
EndIf
WList = ""
If (NumItems >=  (StartWaveNum+ NumWaves))
	For (i =StartWaveNum; i < (StartWaveNum+ NumWaves); i+=1)
		WList += StringFromList(i, WavListAll, ";")+";"
	EndFor
Else
	For (i =StartWaveNum; i < (NumItems); i+=1)
		WList += StringFromList(i, WavListAll, ";")+";"
	EndFor
EndIf	
//If (ItemsInList(WList, ";") < NumWaves)
//	Abort "Aborting...Number of binary waves is less than" + Num2Str(NumWaves)
//EndIf
If (StringMatch(SaveFileName, ""))
	SaveFileName = DfName//GetDataFolder(0)
EndIf
FullName = HDFldrName + SaveFileName
Save /J/O/B/W  WList as FullName

Print "Saved N=",NumItems, "waves as", FullName
SetDataFolder OldDf
End

//*******
Function pt_SaveTableAsText()
// adapted from pt_SaveWsAsText. pt_SaveWsAsText saves as a delimited file but doesn't write in a proper format when the columns are 
// of unequal length or have missing values. pt_SaveTableAsText() creates a table of waves first and then exports as csv 03_17_13
// added DataFldrStr parameter, so that pt_AnalWInFldrs2 does not automatically change DataWaveMatchStr 03_16_13
// corrected for insufficient waves 03_16_13
String DataWaveMatchStr, DataFldrStr,HDFldrName, SaveFileName, SubFldr
Variable StartWaveNum, NumWaves

String WavListAll, WList, WaveNameStr, FullName, OrigParentDataFolder, OldDf, DfName, AlertMessage
Variable i, NumItems 

Wave /T AnalParNamesW	=$("root:FuncParWaves:pt_SaveTableAsText"+"ParNamesW")
Wave /T AnalParW		=$("root:FuncParWaves:pt_SaveTableAsText"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_pt_SaveTableAsTextParW and/or pt_pt_SaveTableAsTextParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				= 	AnalParW[1]
HDFldrName			= 	AnalParW[2]
SaveFileName			=	AnalParW[3]
StartWaveNum			=	Str2Num(AnalParW[4])	// count starts at zero
NumWaves				= 	Str2Num(AnalParW[5])
SubFldr					= 	AnalParW[6]	// 03_15_13

PrintAnalPar("pt_SaveTableAsText")

DfName = GetDataFolder(0)
OldDf = GetDataFolder(1)
SetDataFolder $( GetDataFolder(1)+SubFldr)
print "Current Data Folder", GetDataFolder(0)

WavListAll	= pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1))
NumItems = ItemsInList(WavListAll, ";")
If (NumItems < (StartWaveNum+ NumWaves))
	AlertMessage = "Warning!!! Num of waves is = "+ Num2Str(NumItems)+ ". Not enough waves!"//, " less than "+ Num2Str(StartWaveNum+ NumWaves)
	Print AlertMessage
	DoAlert 0, AlertMessage
EndIf
WList = ""
If (NumItems >=  (StartWaveNum+ NumWaves))
	For (i =StartWaveNum; i < (StartWaveNum+ NumWaves); i+=1)
		WList += StringFromList(i, WavListAll, ";")+";"
	EndFor
Else
	For (i =StartWaveNum; i < (NumItems); i+=1)
		WList += StringFromList(i, WavListAll, ";")+";"
	EndFor
EndIf	
//If (ItemsInList(WList, ";") < NumWaves)
//	Abort "Aborting...Number of binary waves is less than" + Num2Str(NumWaves)
//EndIf
If (StringMatch(SaveFileName, ""))
	SaveFileName = DfName//GetDataFolder(0)
EndIf

DoWindow pt_SaveTableAsText_Edit
If (V_Flag)
	DoWindow /K pt_SaveTableAsText_Edit
EndIf
Edit
DoWindow /C pt_SaveTableAsText_Edit
NumItems = ItemsInList(WList, ";")
For (i=0;i< NumItems; i+=1)
	Wave w = $StringFromList(i, WList, ";")
	AppendToTable /W = pt_SaveTableAsText_Edit w
EndFor
DoUpdate /W = pt_SaveTableAsText_Edit
FullName = HDFldrName + SaveFileName
SaveTableCopy /O/T = 2/W = pt_SaveTableAsText_Edit as FullName

Print "Saved N=",NumItems, "waves as", FullName
SetDataFolder OldDf
End
//*******

// statistical analysis:
// top levels are the factors eg. genotype (control, mutant), age(young, old)
// lower level are the replicates. 
// we want to write a function that will
// 1. Create the folders for factors and subfolders for levels
// 2. duplicate the right replicates to the right levels
// 3. all the info about factors, levels, and replicates will be stored in a top level folder.


Function pt_ApplyFuncMulti()

// Framework to apply a function multiple times on a trace.
// Example. Seal test is defined for 1 time per trace (or N times but the values are averaged). But suppose you want to follow time course of passive properties during a long trace.
// Basically, change some parameters and apply func repeatedly

String DataWaveMatchStr, DataFldrStr,HDFldrName, FuncName, SubFldr
Variable NReps, DelTReps

String WavListAll, WList, WaveNameStr, FullName, OrigParentDataFolder, OldDf, DfName, AlertMessage
Variable i, NumItems 

Wave /T AnalParNamesW	=$("root:FuncParWaves:pt_ApplyFuncMulti"+"ParNamesW")
Wave /T AnalParW		=$("root:FuncParWaves:pt_ApplyFuncMulti"+"ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_ApplyFuncMultiParW and/or pt_ApplyFuncMultiParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				= 	AnalParW[1]
FuncName 				= 	AnalParW[2]
NReps					= 	Str2Num(AnalParW[3])
DelTReps					= 	Str2Num(AnalParW[4])
SubFldr					= 	AnalParW[5]

PrintAnalPar("pt_ApplyFuncMulti")
End

Function pt_CalRsRinCmVmVClampVarPar1()
// wrapper for pt_CalRsRinCmVmVClamp. will run pt_CalRsRinCmVmVClamp with some parameters varied
// Modified from pt_CalRsRinCmVmIClampVarPar1()

String DataWaveMatchStr, DataFldrStr, tBaselineStart0, tBaselineEnd0, tSteadyStateStart0, tSteadyStateEnd0, SealTestAmp_V, tSealTestStart0
Variable NumReps, DelTRep
String DataWaveMatchStr_N, DataFldrStr_N
Variable tBaselineStart0_N, tBaselineEnd0_N, tSteadyStateStart0_N, tSteadyStateEnd0_N, SealTestAmp_V_N, tSealTestStart0_N
Variable tBaselineStart_N, tBaselineEnd_N, tSteadyStateStart_N, tSteadyStateEnd_N, tSealTestStart_N
Variable i

String LastUpdatedMM_DD_YYYY="08_18_2008"
Print "*********************************************************"
Print "pt_CalRsRinCmVmVClampVarPar1 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParW")
If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_CalRsRinCmVmVClampParW and/or pt_CalRsRinCmVmVClampParNamesW!!!"
EndIf

// ######
// Change these values
NumReps = 96
DelTRep = 5.0 // seconds
// New values have '_N' suffix
DataWaveMatchStr_N = "Cell_0117_0002"
DataFldrStr_N = ""
tBaselineStart0_N = 0.950
tBaselineEnd0_N = 0.995
tSteadyStateStart0_N = 1.330
tSteadyStateEnd0_N = 1.370
SealTestAmp_V_N = -2e-3
tSealTestStart0_N = 1.0


Make /O/N=0 RsW_All, RInW_All, ImW_All
//######

// save old values
DataWaveMatchStr 	= 	AnalParW[0]
DataFldrStr 		= 	AnalParW[1]
tBaselineStart0		=	AnalParW[2]
tBaselineEnd0		=	AnalParW[3]
tSteadyStateStart0	= 	AnalParW[4]
tSteadyStateEnd0	= 	AnalParW[5]
SealTestAmp_V		= 	AnalParW[6]
tSealTestStart0		= 	AnalParW[11]


// Seal test time course. To follow passive properties over a long trace.

For (i = 0; i < NumReps; i+=1)
	tBaselineStart_N 		= tBaselineStart0_N 	+ i*DelTRep
	tBaselineEnd_N 			= tBaselineEnd0_N 		+ i*DelTRep
	tSteadyStateStart_N 	= tSteadyStateStart0_N 	+ i*DelTRep
	tSteadyStateEnd_N 		= tSteadyStateEnd0_N 	+ i*DelTRep
	SealTestAmp_V_N 		= SealTestAmp_V_N
	tSealTestStart_N 		= tSealTestStart0_N 	+ i*DelTRep
	
	AnalParW[0]	= DataWaveMatchStr_N 
	AnalParW[1]	= DataFldrStr_N
	AnalParW[2]	= Num2Str(tBaselineStart_N)
	AnalParW[3]	= Num2Str(tBaselineEnd_N)
	AnalParW[4]	= Num2Str(tSteadyStateStart_N)
	AnalParW[5]	= Num2Str(tSteadyStateEnd_N)
	AnalParW[6]	= Num2Str(SealTestAmp_V_N)
	AnalParW[11]	= Num2Str(tSealTestStart_N)

	//Wave Rs = $"RsV"
	//Wave RIn = $"RInV"
	//Wave Im = $"ImV"

	pt_CalRsRinCmVmVClamp()
	Concatenate /NP {RsV}, RsW_All
	Concatenate /NP {RInV}, RInW_All
	Concatenate /NP {ImV}, ImW_All
	Setscale /P x, tSealTestStart0_N, DelTRep, RsW_All, RInW_All, ImW_All
EndFor

// Restore
AnalParW[2]	= 	DataWaveMatchStr
AnalParW[3]	= 	DataFldrStr
AnalParW[2]	= 	tBaselineStart0
AnalParW[3]	= 	tBaselineEnd0
AnalParW[4]	= 	tSteadyStateStart0
AnalParW[5]	= 	tSteadyStateEnd0
AnalParW[6]	= 	SealTestAmp_V
AnalParW[11]	= 	tSealTestStart0

End

Function pt_SealTestTimeCrs()

// modified from pt_CalPeak. Calculate time course of seal test paramaters in a long trace with multiple seal test. 


Variable NumReps, DelTRep, SealTestAmp_V
String LastUpdatedMM_DD_YYYY=" 06/13/2013"
String DataWaveMatchStr, DataFldrStr, BaseNameStr, PeakWinStart, PeakWinEnd, AvgWin, BLStart, BLEnd, SteadyStateStart, SteadyStateEnd, PeakPolarity, SmoothPnts

String DataWaveMatchStr_N, DataFldrStr_N, BaseNameStr_N
Variable PeakWinStart_N, PeakWinEnd_N, BLStart_N, BLEnd_N, SteadyStateStart_N, SteadyStateEnd_N, AvgWin_N, PeakPolarity_N, SmoothPnts_N


Variable PeakWinStart0_N, PeakWinEnd0_N, BLStart0_N, BLEnd0_N, SteadyStateStart0_N, SteadyStateEnd0_N
Variable i

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalPeak", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW				=	$pt_GetParWave("pt_CalPeak", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_CalPeakParW!!!"
EndIf


Print "*********************************************************"
Print "pt_SealTestTimeCrs last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

// ######
// Change these values
NumReps = 96
DelTRep = 5.0 // seconds
SealTestAmp_V = -2e-3

SetDataFolder root:Data:Cell_0125

DataWaveMatchStr_N		=	"Cell_0125_0001"
DataFldrStr_N				=	""
BaseNameStr_N				=	"Cell_0125_0001"
BLStart0_N		 			= 	0.950
BLEnd0_N					=	0.995
PeakWinStart0_N			=	1.0
PeakWinEnd0_N			=	1.1
AvgWin_N					=	1e-3
SteadyStateStart0_N		= 	1.330
SteadyStateEnd0_N			=	1.370
PeakPolarity_N				=	-1
SmoothPnts_N				= 	1

// ######

// save old values
DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
BaseNameStr			=	AnalParW[2]
BLStart			 		= 	AnalParW[3]
BLEnd					=	AnalParW[4] 
PeakWinStart			=	AnalParW[5]
PeakWinEnd			=	AnalParW[6]
AvgWin					=	AnalParW[7]
SteadyStateStart		= 	AnalParW[8]
SteadyStateEnd			=	AnalParW[9] 
PeakPolarity			=	AnalParW[10]
SmoothPnts				= 	AnalParW[11]


// Seal test time course. To follow passive properties over a long trace.

For (i = 0; i < NumReps; i+=1)

	BLStart_N 					= BLStart0_N 			+ i*DelTRep
	BLEnd_N 					= BLEnd0_N 			+ i*DelTRep
	
	PeakWinStart_N 			= PeakWinStart0_N 	+ i*DelTRep
	PeakWinEnd_N 				= PeakWinEnd0_N 		+ i*DelTRep
	
	SteadyStateStart_N 			= SteadyStateStart0_N 	+ i*DelTRep
	SteadyStateEnd_N 			= SteadyStateEnd0_N 	+ i*DelTRep
	
	
	AnalParW[0]	= DataWaveMatchStr_N 
	AnalParW[1]	= DataFldrStr_N
	AnalParW[2]	= BaseNameStr_N	
	AnalParW[3]	= Num2Str(BLStart_N)
	AnalParW[4]	= Num2Str(BLEnd_N) 
	AnalParW[5]	= Num2Str(PeakWinStart_N)
	AnalParW[6]	= Num2Str(PeakWinEnd_N)
	AnalParW[7]	= Num2Str(AvgWin_N)
	AnalParW[8]	= Num2Str(SteadyStateStart_N)
	AnalParW[9]	= Num2Str(SteadyStateEnd_N)
	AnalParW[10]	= Num2Str(PeakPolarity_N)
	AnalParW[11]	= Num2Str(SmoothPnts_N)


	pt_CalPeak()
	Wave wBLY			=	$(BaseNameStr_N+"BLY")
	Wave wSSRelY		=	$(BaseNameStr_N+"SSRelY")
	Duplicate /O wSSRelY, wRIn
	wRIn = SealTestAmp_V/wSSRelY[p]
	
	Concatenate /NP {wBLY}, $(BaseNameStr_N+"ImW")
	Concatenate /NP {wRIn}, $(BaseNameStr_N+"RInW")	
	
EndFor
Setscale /P x, BLEnd0_N, DelTRep, $(BaseNameStr_N+"ImW"), $(BaseNameStr_N+"RInW")

// Restore

	AnalParW[0]	= DataWaveMatchStr
	AnalParW[1]	= DataFldrStr
	AnalParW[2]	= BaseNameStr
	AnalParW[3]	= BLStart
	AnalParW[4]	= BLEnd
	AnalParW[5]	= PeakWinStart
	AnalParW[6]	= PeakWinEnd
	AnalParW[7]	= AvgWin
	AnalParW[8]	= SteadyStateStart
	AnalParW[9]	= SteadyStateEnd
	AnalParW[10]	= PeakPolarity
	AnalParW[11]	= SmoothPnts

End

Function pt_RenameUnique()
// Most of my analysis requires that cells that need to be pooled for analysis have unique names. 
// But many users start with cell_0001 for each new day of experiment. 
// This function will convert cells to unique names. 
// logic. 
// load cells from individual dates. 
// rename cells. Store the unique cell ID.
// Save cells to a folder.
// kill loaded data.

String NewStrBaseName, NewStartNum, PadNum, SaveHDDataFldrPathW
String TableName, CurrFldrName, LastUpdatedMM_DD_YYYY = "07_11_13", OldDF, FolderToKill
Variable iStartRow, i, StartNum, pn
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RenameUnique", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW				=	$pt_GetParWave("pt_RenameUnique", "ParW")

SVAR ParentDataFolder=root:ParentDataFolder

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
//	Abort	"Cudn't find the parameter wave pt_RenameUniqueParW!!!"
EndIf


Print "*********************************************************"
Print "pt_RenameUnique last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

NewStrBaseName = AnalParW[0]
NewStartNum = AnalParW[1]
PadNum = AnalParW[2]
SaveHDDataFldrPathW = AnalParW[3]

//DataWaveMatchStr		=	AnalParW[0]
//DataFldrStr				= 	AnalParW[1]
//HDFldrName			= 	AnalParW[2]
//SaveFileName			=	AnalParW[3]
//StartWaveNum			=	Str2Num(AnalParW[4])	// count starts at zero
//NumWaves				= 	Str2Num(AnalParW[5])
//SubFldr					= 	AnalParW[6]	// 03_15_13

//PrintAnalPar("pt_RenameUnique")

//DfName = GetDataFolder(0)
//OldDf = GetDataFolder(1)
//SetDataFolder $( GetDataFolder(1)+SubFldr)
print "Current Data Folder", GetDataFolder(0)

//WavListAll	= pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1))
//NumItems = ItemsInList(WavListAll, ";")




// Adapted from pt_AnalWInFldrs2
Wave /T HDDataFldrPathW=root:HDDataFldrPathW
TableName=StringByKey("TableName",TableInfo("",-2), ":")
GetSelection Table, $TableName, 1
Wave /T FolderNamesW=$(StringByKey("Wave", TableInfo("",V_StartCol), ":") )
iStartRow=V_StartRow

i = 0
StartNum = Str2Num(NewStartNum)
pn = Str2Num(PadNum)
Do 
	If (iStartRow>V_EndRow)
		Break
	EndIf	
	Print "Renaming folder...", ParentDataFolder+":"+FolderNamesW[iStartRow]
	CurrFldrName=ParentDataFolder+":"+FolderNamesW[iStartRow]
	OldDF = GetDataFolder(1)
	If (	DataFolderExists(CurrFldrName)		)	// data folders created if not existing (praveen 04/29/2008)
	SetDataFolder $CurrFldrName
	Else
		NewDataFolder /s $CurrFldrName
		Print "Created Data Folder", CurrFldrName
	EndIf
//	SetDataFolder $CurrFldrName
	 
	 
//	SetDataFolder $CurrFldrName
	FolderToKill = CurrFldrName
	//########
	// uncommented parameter setting for pt_LoadWFrmFldrs() 09/19/14
	Wave /T LoadWAnalParNamesW	=	$pt_GetParWave("pt_LoadWFrmFldrs", "ParNamesW")		// check in local folder first 07/23/2007
	Wave /T LoadWAnalParW			=	$pt_GetParWave("pt_LoadWFrmFldrs", "ParW")
	Duplicate /O/T LoadWAnalParW, LoadWAnalParWOrig
	LoadWAnalParW[0]	=		GetDataFolder(0)+"*"	//DataWaveMatchStr
	LoadWAnalParW[1]	=		"RawData:"	//DataFldrStr
	LoadWAnalParW[2]	=		"1" 		//AllWaves
	pt_LoadData2(GetDataFolder(0)+"*", HDDataFldrPathW[iStartRow], CurrFldrName+":RawData")
	pt_LoadWFrmFldrs()
	Duplicate /O/T LoadWAnalParWOrig, LoadWAnalParW
	KillWaves /Z LoadWAnalParWOrig
	//########
	Wave /T AnalParNamesW	=	$pt_GetParWave("pt_RenameWaves", "ParNamesW")		// check in local folder first 07/23/2007
	Wave /T AnalParW			=	$pt_GetParWave("pt_RenameWaves", "ParW")
	SaveNRestore("pt_RenameWaves", 1)
	AnalParW[0]	=	"Cell_*"				//DataWaveMatchStr
	AnalParW[1]	=	GetDataFolder(0)		//OldStr
	AnalParW[2]	=	"Cell_"	+pt_PadZeros2IntNum(StartNum+i, pn) //NewStr
	pt_RenameWaves()
	SaveNRestore("pt_RenameWaves", 2)
	//########
	Wave /T AnalParNamesW	=	$pt_GetParWave("pt_SaveWFrmFldrs", "ParNamesW")		// check in local folder first 07/23/2007
	Wave /T AnalParW			=	$pt_GetParWave("pt_SaveWFrmFldrs", "ParW")
	SaveNRestore("pt_SaveWFrmFldrs", 1)
	AnalParW[0]	=		"Cell_*"			//DataWaveMatchStr
	AnalParW[1]	=		SaveHDDataFldrPathW	//HDDataFldrPathW
	AnalParW[2]	=		"IgorBinary"	//HDDataFldrPathW
	pt_SaveWFrmFldrs()
	SaveNRestore("pt_SaveWFrmFldrs", 2)
	//########
	i = i +1
	iStartRow+=1
	SetDataFolder OldDF
	FolderToKill = CurrFldrName
	KillDataFolder /Z FolderToKill
While (1)

//########
//Wave /T AnalParNamesW	=	$pt_GetParWave("pt_SaveWFrmFldrs", "ParNamesW")		// check in local folder first 07/23/2007
//Wave /T AnalParW			=	$pt_GetParWave("pt_SaveWFrmFldrs", "ParW")
//SaveNRestore("pt_SaveWFrmFldrs", 1)
//AnalParW[0]	=		"Cell_*"			//DataWaveMatchStr
//AnalParW[1]	=		SaveHDDataFldrPathW	//HDDataFldrPathW
//pt_AnalWInFldrs2("pt_SaveWFrmFldrs")
//SaveNRestore("pt_SaveWFrmFldrs", 2)
//########

End

Function pt_Analysis() :Panel
// We have pt_SpikeAnalDisplay to display analysis for concatenated traces. It will be good to be able to display analysis for a specified
//trace. eg. for spike analysis or peak analysis (mini analysis).
// modified to allow for arbitrary CellNamePrefix and no CellNum, IterNum padding
// aim - given the type of analysis to display (spike anal or mini anal) and the cell number & trace number, display the analysis.
// The program can prompt the user for type of analysis to display, this way we can just one program which can display multiple
// analyses. If it can display analysis for all traces one by one, that will be good like a panel that can have a graph and a trace number
// and an analysis type drop down menu.
NewDataFolder /O root:AnalysisViewer
NewDataFolder /O root:Data
NewDataFolder /O root:ConditionAnal

String /G root:ParentDataFolder = "root:Data"

SVAR /Z pHD = root:ParentHDDataFolder
If (!SVAR_Exists(pHD))
	String /G root:ParentHDDataFolder
EndIf

SVAR /Z cNP = root:AnalysisViewer:CellNamePrefix
If (!SVAR_Exists(cNP))
	String /G root:AnalysisViewer:CellNamePrefix
EndIf

//String /G root:ParentHDDataFolder = "Macintosh HD:Users:taneja:Work:Analysis:"
//String /G root:AnalysisViewer:CellNamePrefix = "Cell_"//"Cell_"	// 10/16/13.
Variable /G root:AnalysisViewer:DoSealTestAnal
Variable /G root:AnalysisViewer:VectorParNSpks = 4

// FI Pars
//Variable /G root:AnalysisViewer:N_FIAnova = 1
String /G root:AnalysisViewer:List_Anova = ""
//SVAR List_Anova = root:AnalysisViewer:List_Anova
// PSC Pars
// Display Pars
Variable /G root:AnalysisViewer:CellNum
Variable /G root:AnalysisViewer:IterNum
String /G root:AnalysisViewer:BaseNameStr
Variable /G root:AnalysisViewer:AppendGraph
Variable /G root:AnalysisViewer:CellNumPad	 = 4	// 10/16/13. to allow for no padding.
Variable /G root:AnalysisViewer:IterNumPad	 = 4	// 10/16/13. to allow for no padding.
//Variable /G root:AnalysisViewer:ShowFiltered = 1
//Variable /G root:AnalysisViewer:BoxSmoothingPnts = 201
Variable /G root:AnalysisViewer:PassBandEndFreq = 500
Variable /G root:AnalysisViewer:RejectBandStartFreq = 800

Variable /G root:AnalysisViewer:ActiveAnalysisTabNum
String /G root:AnalysisViewer:PanelName
////String /G root:AnalysisViewer:GraphName

SVAR PanelName = root:AnalysisViewer:PanelName
////SVAR GraphName = root:AnalysisViewer:GraphName
//NVAR XMin = root:AnalysisViewer:XMin
//NVAR YMin = root:AnalysisViewer:YMin
//NVAR XMax = root:AnalysisViewer:XMax
//NVAR YMax = root:AnalysisViewer:YMax
Variable txloc = 5, tyloc = 90


PanelName = "pt_AnalysisWin"
////GraphName = "pt_DisplayWin"

PauseUpdate; Silent 1		// building window...
DoWindow $PanelName
If (V_Flag==1)
	DoWindow /F $PanelName
Else
NewPanel /W=(900,95,1160,555)
DoWindow /C $PanelName
SetDrawLayer UserBack

//SetVariable setvar0,pos={619,9},size={130,15},fSize = 12
//SetVariable setvar0, limits={0,inf,1}, value= root:AnalysisViewer:CellNum, proc = pt_DisplayAnalysis
//SetVariable setvar1,pos={619,29},size={130,15},fSize = 12
//SetVariable setvar1, limits={0,inf,1}, value= root:AnalysisViewer:IterNum, proc = pt_DisplayAnalysis
//PopupMenu popup0,pos={619,59},size={80,20}, fSize = 12, title = "Analysis"
//PopupMenu popup0,mode=1,popvalue="None",value= #"\"None;MiniAnal;SpikeAnal\""
//SetVariable setvar2,pos={590,89},size={150,15},fSize = 12
//SetVariable setvar2, value= root:AnalysisViewer:BaseNameStr//, proc = pt_DisplayAnalysis1


//Button button0,pos={619,129},size={89,21},title="Display"//, proc = pt_DisplayAnalysis
//Display/W=(5,5,700,500)///HOST=$PanelName
//DoWindow /C $GraphName
//RenameWindow #,$GraphName
//SetActiveSubwindow #
EndIf


SetVariable setvar4,pos={txloc,tyloc-85},size={215,20},fSize = 12, title = "Parent HD folder"
SetVariable setvar4, limits={0,inf,1}, value= root:ParentHDDataFolder//, proc = pt_DisplayAnalysis
SetVariable setvar3,pos={txloc,tyloc-60},size={170,20},fSize = 12, title = "Cell name prefix"
SetVariable setvar3, limits={0,inf,1}, value= root:AnalysisViewer:CellNamePrefix//, proc = pt_DisplayAnalysis
CheckBox check0,pos={txloc,tyloc-30},size={100,20},fSize = 12, title = "Seal test"
CheckBox check0, limits={0,inf,1}, variable = root:AnalysisViewer:DoSealTestAnal, value =0//, proc = pt_DisplayAnalysis


// add tabs to panel

TabControl AnalPanel,pos={txloc,tyloc},size={245,495},tabLabel(0)="FI",value= 0		// FI Analysis
 txloc +=5
 tyloc +=30
SetVariable setvar5,pos={txloc+8,tyloc},size={160,30},fSize = 12, title = "Anova factors"
SetVariable setvar5, limits={0,inf,1}, value= root:AnalysisViewer:List_Anova, proc = pt_MakeAnovaInWaves
PopupMenu popup1,pos={txloc,tyloc+30},size={80,20}, fSize = 12, title = "Edit parameters"
PopupMenu popup1,mode=1,popvalue="None", value= #"\"None;Cell database;Stim. info - all cells;Stim. info - per cell;Spike analysis;Seal test;FI thresh and slope;Save analysis pars;Save analysis vector pars\"", proc = pt_CallEditWList
Button button0,pos={txloc+95,tyloc+60},size={90,20},fSize = 12, title = "Analyze cells"
Button button0, limits={0,inf,1}, proc = pt_FIAnalyzeCells
PopupMenu popup3,pos={txloc+7,tyloc+90},size={100,20}, fSize = 12, title = "Choose Factor"
PopupMenu popup3,mode=1,popvalue="None",value= pt_ReturnAnovaFactorList(), proc = pt_MakeCellNameWaves
Button button1,pos={txloc+93,tyloc+120},size={90,20},fSize = 12, title = "Pool & Avg."
Button button1, limits={0,inf,1}, proc = pt_PoolNAvgFIData
PopupMenu popupZoomWin,pos={txloc+7,tyloc+150},size={100,20}, fSize = 12, title = "Zoom window"
PopupMenu popupZoomWin,mode=1,popvalue="None",value= pt_ReturnFIDisplayList(), proc = pt_ZoomWin
PopupMenu popupEditData,pos={txloc+7,tyloc+180},size={100,20}, fSize = 12, title = "Edit data"
PopupMenu popupEditData,mode=1,popvalue="None",value= pt_ReturnFIDisplayList(), proc = pt_ZoomWin		// also use to edit data
PopupMenu popup6,pos={txloc+7,tyloc+210},size={100,20}, fSize = 12, title = "Close all"
PopupMenu popup6,mode=1,popvalue="None",value= "Graphs;Tables", proc = pt_CallKillWindows
Button buttonExportAnalysis,pos={txloc+7,tyloc+240},size={160,20},fSize = 12, title = "Export Analysis one current"
Button buttonExportAnalysis, limits={0,inf,1}, proc = pt_SaveFIAnal
Button buttonExportAnalysisVect,pos={txloc+7,tyloc+270},size={160,20},fSize = 12, title = "Export Analysis all currents"
Button buttonExportAnalysisVect, limits={0,inf,1}, proc = pt_SaveFIVectAnal

//Button button1,pos={txloc,tyloc+90},size={90,20},fSize = 12, title = "Choose factor"
//Button button1, limits={0,inf,1}, proc = pt_FactorToPool

//Button button0,pos={700,40},size={50,20},title="First"
//CheckBox check0,pos={52,105},size={102,15},title="Check first",value= 0
TabControl AnalPanel,proc=TabControlProc,tabLabel(1)="PSC"						// post synaptic current analysis
 //txloc +=5
 //tyloc +=30
SetVariable setvar6,pos={txloc+8,tyloc},size={160,30},fSize = 12, title = "Anova factors"
SetVariable setvar6, limits={0,inf,1}, value= root:AnalysisViewer:List_Anova, proc = pt_MakeAnovaInWaves
PopupMenu popup2,pos={txloc,tyloc+30},size={80,20}, fSize = 12, title = "Edit parameters"
PopupMenu popup2,mode=1,popvalue="None", value= #"\"None;Cell database;Peak analysis;Seal test\"", proc = pt_CallEditWList
Button button2,pos={txloc+95,tyloc+60},size={90,20},fSize = 12, title = "Analyze cells"
Button button2, limits={0,inf,1}, proc = pt_MiniAnalyzeCells
PopupMenu popup4,pos={txloc+7,tyloc+90},size={100,20}, fsize = 12, title = "Choose Factor"
PopupMenu popup4,mode=1,popvalue="None",value= pt_ReturnAnovaFactorList(), proc = pt_MakeCellNameWaves
Button button3,pos={txloc+93,tyloc+120},size={90,20},fSize = 12, title = "Pool & Avg."
Button button3, limits={0,inf,1}, proc = pt_PoolNAvgMiniData
PopupMenu popupPSCZoomWin,pos={txloc+7,tyloc+150},size={100,20}, fSize = 12, title = "Zoom window"
PopupMenu popupPSCZoomWin,mode=1,popvalue="None",value= pt_ReturnPSCDisplayList(), proc = pt_PSCZoomWin
PopupMenu popupPSCEditData,pos={txloc+7,tyloc+180},size={100,20}, fSize = 12, title = "Edit data"
PopupMenu popupPSCEditData,mode=1,popvalue="None",value= pt_ReturnPSCDisplayList(), proc = pt_PSCZoomWin		// also use to edit data
PopupMenu popup5,pos={txloc+7,tyloc+210},size={100,20}, fSize = 12, title = "Close all"
PopupMenu popup5,mode=1,popvalue="None",value= "Graphs;Tables", proc = pt_CallKillWindows
Button buttonExportAnalysisPSC,pos={txloc+7,tyloc+240},size={120,20},fSize = 12, title = "Export Analysis"
Button buttonExportAnalysisPSC, limits={0,inf,1}, proc = pt_ExportAnalysisPSC

//PopupMenu popup2,pos={txloc,tyloc},size={80,20}, fSize = 12, title = "Edit parameters"
//PopupMenu popup2,mode=1,popvalue="None",value= #"\"None;Cell database;PSC analysis;Seal test\"", proc = pt_CallEditWList
//Button button1,pos={700, 40},size={50,20},title="Second"
//CheckBox check1,pos={60,105},size={114,15},title="Check second",value= 0
TabControl AnalPanel,proc=TabControlProc,tabLabel(2)="Display"					// display
CheckBox check1,pos={txloc,tyloc},size={100,20},fSize = 12, title = "Append graph"
CheckBox check1, limits={0,inf,1}, variable = root:AnalysisViewer:AppendGraph, value =0//, proc = pt_DisplayAnalysis
SetVariable setvar0,pos={txloc,tyloc+30},size={130,15},fSize = 12
SetVariable setvar0, limits={0,inf,1}, value= root:AnalysisViewer:CellNum//, proc = pt_DisplayAnalysis
SetVariable setvar1,pos={txloc,tyloc+60},size={130,15},fSize = 12
SetVariable setvar1, limits={0,inf,1}, value= root:AnalysisViewer:IterNum, proc = pt_DisplayAnalysis
PopupMenu popup0,pos={txloc,tyloc+90},size={80,20}, fSize = 12, title = "Analysis"
PopupMenu popup0,mode=1,popvalue="None",value= #"\"None;MiniAnal;SpikeAnal\""
SetVariable setvar2,pos={txloc,tyloc+120},size={150,15},fSize = 12
SetVariable setvar2, value= root:AnalysisViewer:BaseNameStr//, proc = pt_DisplayAnalysis1

PopupMenu popup7,pos={txloc,tyloc+180},size={100,20}, fSize = 12, title = "Choose Current"
PopupMenu popup7,mode=1,popvalue="None",value= pt_ReturnListOfCurrents(), proc = pt_SetIterNum

PopupMenu popup8,pos={txloc,tyloc+150},size={100,20}, fSize = 12, title = "Choose parameter"
PopupMenu popup8,mode=1,popvalue="None",value= pt_ReturnFIAnalParsList()


TabControlProc("AnalPanel",0) // to initialize the tab to tab0


////DoWindow $GraphName
////If (V_Flag==1)
////	DoWindow /F $GraphName
////Else
////	Display /W=(5,5,700,500)
////	DoWindow /C $GraphName
////EndIf

End

Function pt_SetIterNum(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum	// which item is currently selected (1-based)
String popStr		// contents of current popup item as string

NVAR IterNum = root:AnalysisViewer:IterNum

IterNum = popNum

//ControlInfo /W = $PanelName popup7
pt_DisplayAnalysis("CurrentValue",0,"","")

End

Function pt_MakeCellNameWaves(ctrlName,popNum,popStr) : PopupMenuControl
	// corrected mistake (in two places) leading to only last factor being parsed and factors being incompletely parsed //04/01/14
	// also parse levels of other factors in List_Anova 03/17/14
	// make cellname waves & folders, and set pars for pt_MoveWavesMany  movewaves
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	//SVAR LevelsColorList = root:AnalysisViewer:LevelsColorList	// to color traces belonging to different color. 
	
	SVAR List_Anova = root:AnalysisViewer:List_Anova
	String FactorLevels, LevelName, ShortList_Anova="", theAnovaFactor
	Variable NumLevels, i, NumReplicates, j, NumAnovaFactors, k
	
	NumAnovaFactors = ItemsInList(List_Anova, ";")
	

	
	
	Make /O/N=0/T root:AnalysisViewer:ColorLevelNamesW
	Make /O/N=0 	root:AnalysisViewer:ColorLevel_RedVal
	Make /O/N=0 	root:AnalysisViewer:ColorLevel_BlueVal
	Make /O/N=0 	root:AnalysisViewer:ColorLevel_GreenVal

	//String /G root:AnalysisViewer:LevelsColorList = ""	// to color traces belonging to different color. 

	Wave /T ColorLevelNamesW 	=	root:AnalysisViewer:ColorLevelNamesW
	Wave ColorLevel_RedVal 		=	root:AnalysisViewer:ColorLevel_RedVal
	Wave ColorLevel_BlueVal 		=	root:AnalysisViewer:ColorLevel_BlueVal
	Wave ColorLevel_GreenVal 	= 	root:AnalysisViewer:ColorLevel_GreenVal
	
	Make /N=1/T/O LevelNameTmp
	Make /N=1/O ColorTmp
	
	Wave /T CellName = $"root:CellName"
	Make /O/N=1/T CellNameTemp
	
	For (k=0; k<NumAnovaFactors; k+=1)
		theAnovaFactor = StringFromList(k, List_Anova, ";")
		If (WaveExists($"root:AnalysisViewer:"+theAnovaFactor))
			If (NumPnts($"root:AnalysisViewer:"+theAnovaFactor) == NumPnts(CellName) )
				//ShortList_Anova = theAnovaFactor+";"
				ShortList_Anova += theAnovaFactor+";" //04/01/14
			Else
				Print "Warning! Wave has different number of points than CellName wave","root:AnalysisViewer:" +theAnovaFactor
				Print "Not parsed in different levels of ", popStr
			EndIf
		Else
			Print "Wave doesn't exist","root:AnalysisViewer:" +theAnovaFactor	
		EndIf
	EndFor
	Make /O/N=1/T LevelAnovaFactorWTemp
	
	NumAnovaFactors = ItemsInList(ShortList_Anova, ";")
	
	NewDataFolder /O $"root:ConditionAnal:"+popStr
	
	Wave /T wFactor = $"root:AnalysisViewer:"+popStr
	NumReplicates = NumPnts(wFactor)
	FactorLevels = pt_DistinctTextVals("root:AnalysisViewer:"+popStr)
	NumLevels = ItemsInList(FactorLevels, ";")
	
	//Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParNamesW")
	Wave /T AnalParW			=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParW")
	AnalParW[0]=""
	AnalParW[1]=""
	AnalParW[2]="1"//Overwrite
	
	For (i = 0; i < NumLevels; i = i + 1)
		LevelName = StringFromList(i, FactorLevels, ";")
		NewDataFolder /O $"root:ConditionAnal:"+popStr+":"+LevelName
		Make /O/N=0/T $"root:ConditionAnal:"+popStr+":"+LevelName+":"+LevelName+"CellNames"
		Wave /T CellNamesW = $"root:ConditionAnal:"+popStr+":"+LevelName+":"+LevelName+"CellNames"
		
		AnalParW[0] += "root:ConditionAnal:"+popStr+":"+LevelName+":"+LevelName+"CellNames"+";"
		AnalParW[1] += "root:ConditionAnal:"+popStr+":"+LevelName+";"
	
		For (j = 0; j < NumReplicates; j = j + 1)
			If (StringMatch(wFactor[j], LevelName) )
				CellNameTemp[0] = CellName[j]
				Concatenate /T/NP {CellNameTemp}, CellNamesW
			EndIf
		EndFor
		
		// for each level of anova factor by which we are pooling, parse the other anova factor levels
		For (j = 0; j < NumReplicates; j = j + 1)	
			If (StringMatch(wFactor[j], LevelName) )
				For (k=0; k<NumAnovaFactors; k+=1)
					theAnovaFactor = StringFromList(k, ShortList_Anova, ";")	// anova wave to be parsed
					Wave /T theAnovaFactorW = $"root:AnalysisViewer:"+theAnovaFactor
					If (!WaveExists($"root:ConditionAnal:"+popStr+":"+LevelName+":"+LevelName+theAnovaFactor))
						// new anova waves to be created for each level for each factor.
						Make /O/N=0/T $"root:ConditionAnal:"+popStr+":"+LevelName+":"+LevelName+theAnovaFactor
						//Wave /T LevelAnovaFactorW = $"root:ConditionAnal:"+popStr+":"+LevelName+":"+LevelName+theAnovaFactor //04/01/14
					EndIf
					 Wave /T LevelAnovaFactorW = $"root:ConditionAnal:"+popStr+":"+LevelName+":"+LevelName+theAnovaFactor //04/01/14
					 LevelAnovaFactorWTemp[0] =  theAnovaFactorW[j]
					 Concatenate /NP/T {LevelAnovaFactorWTemp}, LevelAnovaFactorW
				EndFor
			EndIf
		EndFor
		
		
		
		
		Sort CellNamesW, CellNamesW
		
		LevelNameTmp = LevelName
		DoAlert 0, "Choose color for "+LevelName
		ChooseColor

		ColorTmp[0] = V_Red
		Concatenate /NP {ColorTmp},  ColorLevel_RedVal
		 
		ColorTmp[0] = V_Green
		Concatenate /NP {ColorTmp},  ColorLevel_GreenVal
		
		ColorTmp[0] = V_Blue
		Concatenate /NP {ColorTmp},  ColorLevel_BlueVal
		
		Concatenate /NP/T {LevelNameTmp}, ColorLevelNamesW 
		  
	EndFor
	
	For (i = 0; i < NumLevels; i = i + 1)
		If (i ==0)
			Print "Following colors were chosen."
			Print " "
		EndIf
		
		Print ColorLevelNamesW[i], ColorLevel_RedVal[i], ColorLevel_GreenVal[i], ColorLevel_BlueVal[i]
	EndFor
	
	KillWaves /Z  CellNameTemp, ColorTmp, LevelNameTmp, LevelAnovaFactorWTemp
End

Function /s pt_DistinctTextVals(wName)
String wName
String WList = ""
Variable i, N
Wave /T w = $WName
N = NumPnts(w)
For (i = 0; i < N; i = i +1)
	If (FindListItem(w[i], WList, ";" ) == -1 && StringMatch(w[i] ,"")  == 0 )
		WList += w[i] + ";"
	EndIf
EndFor
WList = SortList(WList, ";")
Return WList
End

Function pt_MakeAnovaInWaves(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	
	SVAR List_Anova = root:AnalysisViewer:List_Anova
	//String LList_Anova = "", WStr		// local list as DoPrompt doesn't work for global list
	String WStr
	Variable i, N
	//If (varNum >0)
	//Prompt LList_Anova , "Enter list"
	//DoPrompt "Enter anova factor names (eg. GT;Age;Gender;)", LList_Anova
	//List_Anova = LList_Anova
	//N = ItemsInList(LList_Anova)
	N = ItemsInList(List_Anova)
	For (i = 0; i<N; i+=1)
	//WStr = StringFromList(i, LList_Anova, ";")
	WStr = StringFromList(i, List_Anova, ";")
	If (!WaveExists($"root:AnalysisViewer:"+WStr))
		Make /O/T/N=0 $"root:AnalysisViewer:"+WStr
	EndIf
	EndFor
	
End

Function TabControlProc(name,tab)
	String name
	Variable tab
	
NVAR ActiveAnalysisTabNum = root:AnalysisViewer:ActiveAnalysisTabNum
	
	ActiveAnalysisTabNum = tab
	Print "ActiveAnalysisTabNum =", ActiveAnalysisTabNum

	// tab0
	SetVariable setvar5,disable= (tab!=0)// && tab!=1)
	PopupMenu popup1,disable= (tab!=0)// && tab!=1)
	Button button0,disable= (tab!=0)// && tab!=1)
	PopupMenu popup3,disable= (tab!=0)// && tab!=1)
	Button button1,disable= (tab!=0)// && tab!=1)
	PopupMenu popupZoomWin,disable= (tab!=0)// && tab!=1)
	PopupMenu popupEditData,disable= (tab!=0)// && tab!=1)
	PopupMenu popup6,disable= (tab!=0)// && tab!=1)
	Button buttonExportAnalysis, disable= (tab!=0)
	Button buttonExportAnalysisVect, disable= (tab!=0)
	
	//tab1
	SetVariable setvar6, disable= (tab!=1)
	PopupMenu popup2, disable= (tab!=1)
	Button button2, disable= (tab!=1)
	PopupMenu popup4, disable= (tab!=1)
	Button button3, disable= (tab!=1)
	PopupMenu popupPSCZoomWin, disable= (tab!=1)
	PopupMenu popupPSCEditData, disable= (tab!=1)
	PopupMenu popup5, disable= (tab!=1)
	Button buttonExportAnalysisPSC, disable= (tab!=1)
	
	//tab2
	SetVariable setvar0,disable= (tab!=2)
	SetVariable setvar1,disable= (tab!=2)
	PopupMenu popup0,disable= (tab!=2)
	SetVariable setvar2,disable= (tab!=2)
	PopupMenu popup7,disable= (tab!=2)
	PopupMenu popup8,disable= (tab!=2)
	CheckBox check1, disable= (tab!=2)
		
End

Function /s pt_ReturnAnovaFactorList()
SVAR List_Anova = root:AnalysisViewer:List_Anova
Return List_Anova
End


Function /s pt_ReturnFIDisplayList()
NVAR VectorParNSpks = root:AnalysisViewer:VectorParNSpks
Variable k 
String List_FIDisplay = "None;"
List_FIDisplay += "FI;"
List_FIDisplay += "FI_All;"
List_FIDisplay += "FI_NormC;"
List_FIDisplay += "FI_NormC_All;"
List_FIDisplay += "FI_Inst;"
List_FIDisplay += "FI_Inst_All;"
List_FIDisplay += "Spk_train_AHP;"
List_FIDisplay += "Spk_train_AHP_All;"
List_FIDisplay += "Initial_Inst_Freq;"
For (k =0; k < VectorParNSpks; k +=1)
	List_FIDisplay += "Initial_Inst_Freq_AllSpk" +Num2Str(k) + ";"
EndFor
List_FIDisplay += "Ahp;"
For (k =0; k < VectorParNSpks; k +=1)
	List_FIDisplay += "Ahp_AllSpk" +Num2Str(k) + ";"
EndFor
List_FIDisplay += "Peak_Amp;"
For (k =0; k < VectorParNSpks; k +=1)
	List_FIDisplay += "Peak_Amp_AllSpk" +Num2Str(k) + ";"
EndFor
List_FIDisplay += "Adaptation_ratio;"
List_FIDisplay += "Fwhm;"
For (k =0; k < VectorParNSpks; k +=1)
	List_FIDisplay += "Fwhm_AllSpk" +Num2Str(k) + ";"
EndFor
List_FIDisplay += "VThresh;"
For (k =0; k < VectorParNSpks; k +=1)
	List_FIDisplay += "VThresh_AllSpk" +Num2Str(k) + ";"
EndFor
List_FIDisplay += "MaxDvDt;"
For (k =0; k < VectorParNSpks; k +=1)
	List_FIDisplay += "MaxDvDt_AllSpk" +Num2Str(k) + ";"
EndFor
List_FIDisplay += "T2FracPeak;"
For (k =0; k < VectorParNSpks; k +=1)
	List_FIDisplay += "T2FracPeak_AllSpk" +Num2Str(k) + ";"
EndFor
List_FIDisplay += "Inter_stim_interval;"		// to be fixed
For (k =0; k < VectorParNSpks; k +=1)
	List_FIDisplay += "Inter_stim_interval_AllSpk" +Num2Str(k) + ";"
EndFor
List_FIDisplay += "Rs;"
List_FIDisplay += "RIn;"
List_FIDisplay += "Cm;"
List_FIDisplay += "Rs_All;"
List_FIDisplay += "RIn_All;"
List_FIDisplay += "Cm_All;"

//List_FIDisplay += " ;"

Return List_FIDisplay
End

Function /s pt_ReturnPSCDisplayList()
String List_FIDisplay = "None;"
List_FIDisplay += "Freq_Avg;"
List_FIDisplay += "Freq_Avg_All;"
List_FIDisplay += "PeakAmp_Avg;"
List_FIDisplay += "PeakAmp_Avg_All;"
List_FIDisplay += "DecayTau_Avg;"
List_FIDisplay += "DecayTau_Avg_All;"
List_FIDisplay += "RiseTau_Avg;"
List_FIDisplay += "RiseTau_Avg_All;"
//List_FIDisplay += "Rs_Avg;"
//List_FIDisplay += "RIn_Avg;"
//List_FIDisplay += "Cm_Avg;"
//List_FIDisplay += "Rs_All;"
//List_FIDisplay += "RIn_All;"
//List_FIDisplay += "Cm_All;"

//List_FIDisplay += " ;"

Return List_FIDisplay
End

//....
Function /s pt_ReturnFIAnalParsList()
String List_FIDisplay = "None;"
List_FIDisplay += "Spk_train_AHP;"
List_FIDisplay += "Ahp;"
List_FIDisplay += "Peak Amp;"
List_FIDisplay += "Fwhm;"
List_FIDisplay += "VThresh;"
//List_FIDisplay += "MaxDvDt;"
//List_FIDisplay += "T2FracPeak;"
//List_FIDisplay += " ;"

Return List_FIDisplay
End
//....

Function /S pt_ReturnListOfCurrents()

NVAR CellNum = root:AnalysisViewer:CellNum
//NVAR IterNum = root:AnalysisViewer:IterNum
NVAR CellNumPad = root:AnalysisViewer:CellNumPad
//NVAR IterNumPad = root:AnalysisViewer:IterNumPad
//NVAR BoxSmoothingPnts = root:AnalysisViewer:BoxSmoothingPnts
//NVAR PassBandEndFreq = root:AnalysisViewer:PassBandEndFreq
//NVAR RejectBandStartFreq = root:AnalysisViewer:RejectBandStartFreq

SVAR ParentDataFolder=$"root:ParentDataFolder"
SVAR CellNamePrefix = root:AnalysisViewer:CellNamePrefix
SVAR BaseNameStr = root:AnalysisViewer:BaseNameStr

String CellNameStr, CurrFldrName, CurrList = ""
Variable i, N

CellNameStr = CellNamePrefix+pt_PadZeros2IntNum(CellNum, CellNumPad)
CurrFldrName = ParentDataFolder+":"+CellNamePrefix+pt_PadZeros2IntNum(CellNum, CellNumPad)

If (!WaveExists($CurrFldrName+":"+"CurrW"))
	DoAlert 0, "Extracted current values not found. Have you analyzed the data first?"
	Return "" 
EndIf	

Wave CurrW = $CurrFldrName+":"+"CurrW"
N = NumPnts(CurrW)

For (i = 0; i <N; i +=1)
	CurrList += Num2Str(CurrW[i])+";"
EndFor
// a function that returns the a list of all currents injected in a cell. 
Return CurrList
// a function that returns the tracename when the current is speciied
End

Function pt_CallKillWindows(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum	// which item is currently selected (1-based)
String popStr		// contents of current popup item as string

StrSwitch (popStr)
	Case "Graphs":
		pt_KillWindows(1)
		Break
		
	Case "Tables":
		pt_KillWindows(2)
		Break
EndSwitch

End

//Function pt_DisplayAnalysis(ButtonVarName)//: ButtonControl
//String ButtonVarName
Function pt_DisplayAnalysis(ctrlName,varNum,varStr,varName) : SetVariableControl
String ctrlName
Variable varNum	// value of variable as number
String varStr		// value of variable as string
String varName	// name of variable
// does the actual displaying for pt_Analysis()

SVAR PanelName = root:AnalysisViewer:PanelName



// load data and display. 
SVAR ParentDataFolder=$"root:ParentDataFolder"
SVAR ParentHDDataFolder = $"root:ParentHDDataFolder"

NVAR AppendGraph = root:AnalysisViewer:AppendGraph
//SVAR ParentHDDataFolder=$"root:ParentHDDataFolder"
NVAR CellNum = root:AnalysisViewer:CellNum
NVAR IterNum = root:AnalysisViewer:IterNum
NVAR CellNumPad = root:AnalysisViewer:CellNumPad
NVAR IterNumPad = root:AnalysisViewer:IterNumPad
//NVAR BoxSmoothingPnts = root:AnalysisViewer:BoxSmoothingPnts
NVAR PassBandEndFreq = root:AnalysisViewer:PassBandEndFreq
NVAR RejectBandStartFreq = root:AnalysisViewer:RejectBandStartFreq

SVAR CellNamePrefix = root:AnalysisViewer:CellNamePrefix
SVAR BaseNameStr = root:AnalysisViewer:BaseNameStr

String GraphName = ""
Variable DisplayRawDataFolderExists = 0, DataNotFound = 0, xmin, xmax, ymin, ymax, ExistingAxis = 0
Variable i, N, xDelta
String FullHDFolderPath, CurrFldrName, DataWaveMatchStr, OldDf, DataWaveMatchStrNoExt, ListofAxes
String HDFolderPath, TracesOnGraph, PathStr1, PathStr2, PathStr3, TraceNameStr, yWName, xWName, xWName1
String DisplayFIAnalPar

If (AppendGraph)
	GraphName = WinName(0, 1) // name of top window
Else
	 Display /k = 1 // kill without dialog 11/11/14
	 GraphName = WinName(0, 1)
EndIf

//Remove existing traces 
TracesOnGraph = TraceNameList(GraphName,";",1)
N = ItemsInList(TracesOnGraph)
if (N>0) // get axis range

//GetAxis /W = $PanelName#$GraphName bottom
GetAxis /W = $GraphName bottom //#$GraphName
If (V_Flag ==0)
	xmin = V_Min
	xmax = V_Max
	ExistingAxis = 1 
EndIf

//GetAxis /W = $PanelName #$GraphName left
GetAxis /W = $GraphName left
If (V_Flag ==0)
	ymin = V_Min
	ymax = V_Max 
	ExistingAxis = 1
EndIf

EndIf

////For (i = 0; i < N; i+=1)
////RemoveFromGraph /W = $GraphName $StringFromList(i, TracesOnGraph, ";")
////EndFor

Wave /T HDDataFldrPathW = $"root:HDDataFldrPathW"
String CellNameStr = CellNamePrefix+pt_PadZeros2IntNum(CellNum, CellNumPad)

// find cell name in the text wave and find the corresponding HD folder.
i = pt_TextWSearch("root:CellName", CellNameStr)
If (i >=0)
	HDFolderPath = HDDataFldrPathW[i]
	Print "Found HDFolderPath  for ", CellNameStr, "=",  ParentHDDataFolder+HDFolderPath 
Else
	Abort  "Couldn't find " + CellNameStr+ "in root:CellName to find HD folder"
EndIf

// Load data in DisplayRawData subfolder 
CurrFldrName = ParentDataFolder+":"+CellNamePrefix+pt_PadZeros2IntNum(CellNum, CellNumPad) //
DataWaveMatchStr = CellNamePrefix+pt_PadZeros2IntNum(CellNum, CellNumPad) +"_"+pt_PadZeros2IntNum(IterNum, IterNumPad)+".ibw"
OldDf = GetDataFolder(1)
SetDataFolder ParentDataFolder
If (	DataFolderExists(CurrFldrName)		)	// data folders created if not existing (praveen 04/29/2008)
	SetDataFolder $CurrFldrName
Else
	NewDataFolder /s $CurrFldrName
	Print "Created Data Folder", CurrFldrName
EndIf
	
NewDataFolder /O DisplayRawData
DisplayRawDataFolderExists=1

//Print DataWaveMatchStr, HDFolderPath, CurrFldrName+":DisplayRawData"
pt_LoadData2(DataWaveMatchStr, HDFolderPath, CurrFldrName+":DisplayRawData")

// Display raw data
DataWaveMatchStrNoExt = CellNamePrefix+pt_PadZeros2IntNum(CellNum, CellNumPad) +"_"+pt_PadZeros2IntNum(IterNum, IterNumPad)
If (waveexists($(CurrFldrName+":DisplayRawData:"+ DataWaveMatchStrNoExt)) == 0)
	Print "Warning! Wave not found", CurrFldrName+":DisplayRawData:"+ DataWaveMatchStrNoExt
	Return 0
EndIf

Duplicate /O $(CurrFldrName+":DisplayRawData:"+ DataWaveMatchStrNoExt), $("root:AnalysisViewer:"+ DataWaveMatchStrNoExt)//$("root:AnalysisViewer:wRaw")
Wave wRaw = $("root:AnalysisViewer:"+ DataWaveMatchStrNoExt)

AppendToGraph /W = $GraphName wRaw
//Smooth /B BoxSmoothingPnts, wSm

If (ExistingAxis ==1)
SetAxis /W = $GraphName bottom, xmin, xmax
SetAxis /W = $GraphName left, ymin, ymax
Else //autoscale
SetAxis /W = $GraphName /A bottom
SetAxis /W = $GraphName /A left
EndIf

ControlInfo /W = $PanelName popup8
DisplayFIAnalPar = S_Value

// Display analysis if needed
ControlInfo /W = $PanelName popup0
//Print "S_Value", S_Value

StrSwitch(S_Value)

	Case "MiniAnal":
		// filtered trace
		Duplicate /O wRaw, $("root:AnalysisViewer:wSm")
		Wave wSm = $("root:AnalysisViewer:wSm")
		XDelta = DimDelta(wRaw, 0)
		
		Make/O/D/N=0 coefs
		FilterFIR/DIM=0/LO={XDelta*PassBandEndFreq, XDelta*RejectBandStartFreq,101}/COEF coefs, wSm// filtered
		KillWaves /z coefs
		
		AppendToGraph /W = $GraphName wSm
		//ModifyGraph /W = $PanelName #$GraphName rgb(wSm)=(0,0,0)
		ModifyGraph /W = $GraphName rgb(wSm)=(0,0,0)
	
		// peaks 
		// for greater accuracy find analysis wave by checking raw data wave name in wavenote in analysis wave
		yWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"PkYF",  BaseNameStr+"PkYW*", "TraceName", DataWaveMatchStrNoExt, 1)
		xWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"PkXF",  BaseNameStr+"PkXW*", "TraceName", DataWaveMatchStrNoExt, 1)
		print "yWName, xWName", yWName, xWName
		If (!StringMatch(yWName, "") && !StringMatch(xWName, ""))
			PathStr1 = CurrFldrName + ":"+BaseNameStr+"PkYF:"+yWName
			PathStr2 =  CurrFldrName + ":"+BaseNameStr+"PkXF:"+xWName
			AppendToGraph /W = $GraphName $(PathStr1) vs $(PathStr2)
			TraceNameStr = yWName
			Print TraceNameStr
			ModifyGraph /W = $GraphName mode($TraceNameStr)=3
			ModifyGraph /W = $GraphName marker($TraceNameStr)=19
			ModifyGraph /W = $GraphName msize($TraceNameStr)=3
			ModifyGraph /W = $GraphName rgb($TraceNameStr)=(26205,52428,1)
		Else
			DoAlert 0, "Analysis not found for "+ DataWaveMatchStrNoExt
		EndIf
		Break
		
		
		
	Case "SpikeAnal":
		// peaks 
		// for greater accuracy find analysis wave by checking raw data wave name in wavenote in analysis wave
		StrSwitch(DisplayFIAnalPar)
			
			Case "Ahp":
				yWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"AHPAbsYF",  BaseNameStr+"AHPAbsYW*", "TraceName", DataWaveMatchStrNoExt, 1)
				xWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"AHPAbsXF",  BaseNameStr+"AHPAbsXW*", "TraceName", DataWaveMatchStrNoExt, 1)
				print "yWName, xWName", yWName, xWName
				PathStr1 = CurrFldrName + ":"+BaseNameStr+"AHPAbsYF:"+yWName
				PathStr2 =  CurrFldrName + ":"+BaseNameStr+"AHPAbsXF:"+xWName
			Break
			
			Case "Spk_train_AHP":
				yWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"EOPAHPAbsYF",  BaseNameStr+"EOPAHPAbsYW*", "TraceName", DataWaveMatchStrNoExt, 1)
				xWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"EOPAHPAbsXF",  BaseNameStr+"EOPAHPAbsXW*", "TraceName", DataWaveMatchStrNoExt, 1)
				print "yWName, xWName", yWName, xWName
				PathStr1 = CurrFldrName + ":"+BaseNameStr+"EOPAHPAbsYF:"+yWName
				PathStr2 =  CurrFldrName + ":"+BaseNameStr+"EOPAHPAbsXF:"+xWName
			Break
			
			Case "Peak Amp":
				yWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"PeakAbsYF",  BaseNameStr+"PeakAbsYW*", "TraceName", DataWaveMatchStrNoExt, 1)
				xWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"PeakAbsXF",  BaseNameStr+"PeakAbsXW*", "TraceName", DataWaveMatchStrNoExt, 1)
				print "yWName, xWName", yWName, xWName
				PathStr1 = CurrFldrName + ":"+BaseNameStr+"PeakAbsYF:"+yWName
				PathStr2 =  CurrFldrName + ":"+BaseNameStr+"PeakAbsXF:"+xWName
			Break
			
			Case "Fwhm":
				yWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"FracPAbsYF",  BaseNameStr+"FracPAbsYW*", "TraceName", DataWaveMatchStrNoExt, 1)
				xWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"LFracPAbsXF",  BaseNameStr+"LFracPAbsXW*", "TraceName", DataWaveMatchStrNoExt, 1)
				xWName1 = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"RFracPAbsXF",  BaseNameStr+"RFracPAbsXW*", "TraceName", DataWaveMatchStrNoExt, 1)
				print "yWName, xWName, xWName1 ", yWName, xWName, xWName1
				PathStr1 = CurrFldrName + ":"+BaseNameStr+"FracPAbsYF:"+yWName
				PathStr2 =  CurrFldrName + ":"+BaseNameStr+"LFracPAbsXF:"+xWName
				PathStr3 =  CurrFldrName + ":"+BaseNameStr+"RFracPAbsXF:"+xWName1
			Break
			
			Case "VThresh":
				yWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"SpikeThreshYF",  BaseNameStr+"SpikeThreshYW*", "TraceName", DataWaveMatchStrNoExt, 1)
				xWName = pt_FindWWithNoteStr(CurrFldrName + ":"+BaseNameStr+"SpikeThreshXF",  BaseNameStr+"SpikeThreshXW*", "TraceName", DataWaveMatchStrNoExt, 1)
				print "yWName, xWName", yWName, xWName
				PathStr1 = CurrFldrName + ":"+BaseNameStr+"SpikeThreshYF:"+yWName
				PathStr2 =  CurrFldrName + ":"+BaseNameStr+"SpikeThreshXF:"+xWName
			Break
			
			Case "MaxDvDt":
			Break
			
			Case "T2FracPeak":
			Break
			
		EndSwitch
		
		
		If (!StringMatch(yWName, "") && !StringMatch(xWName, ""))
			AppendToGraph /W = $GraphName $(PathStr1) vs $(PathStr2)
			TraceNameStr = yWName
			Print TraceNameStr
			ModifyGraph /W = $GraphName mode($TraceNameStr)=3
			ModifyGraph /W = $GraphName marker($TraceNameStr)=19
			ModifyGraph /W = $GraphName msize($TraceNameStr)=3
			ModifyGraph /W = $GraphName rgb($TraceNameStr)=(26205,52428,1)
			If (StringMatch(DisplayFIAnalPar, "Fwhm"))
				AppendToGraph /W = $GraphName $(PathStr1) vs $(PathStr3)
				TraceNameStr = yWName+"#1"
				Print TraceNameStr
				ModifyGraph /W = $GraphName mode($TraceNameStr)=3
				ModifyGraph /W = $GraphName marker($TraceNameStr)=19
				ModifyGraph /W = $GraphName msize($TraceNameStr)=3
				ModifyGraph /W = $GraphName rgb($TraceNameStr)=(26205,52428,1)
			EndIf
		Else
			DoAlert 0, "Analysis not found for "+ DataWaveMatchStrNoExt
		EndIf
		Break

	Default:

EndSwitch

If (DisplayRawDataFolderExists ==1)
	KillDataFolder /Z $CurrFldrName+":DisplayRawData:"
EndIf


End

Function pt_CallEditWList(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	
	SVAR List_Anova = root:AnalysisViewer:List_Anova
	NVAR ActiveAnalysisTabNum = root:AnalysisViewer:ActiveAnalysisTabNum
	String WList = "", WStr, WStr1
	Variable i, N
	
	StrSwitch(popStr)
		
		Case "Cell database":
		If (!WaveExists($"root:CellName"))
			Make /O/N=0/T $"root:CellName"
		EndIf
		If (!WaveExists($"root:HDDataFldrPathW"))
			Make /O/N=0/T $"root:HDDataFldrPathW"
		EndIf
		WList +="root:CellName;"
		WList +="root:HDDataFldrPathW;"
		N = ItemsInList(List_Anova, ";")
		For (i = 0; i< N; i += 1)
			WStr = StringFromList(i, List_Anova, ";")
			WList +="root:AnalysisViewer:"+WStr+";"
		EndFor
		If (!WaveExists($"root:CommentsW"))
			Make /O/N=0/T $"root:CommentsW"
		EndIf
		WList +="root:CommentsW;"
		//WList +=""
		pt_EditWList(WList)
		Break
		
		Case "Seal test":
		If (ActiveAnalysisTabNum == 0)	// FI
			WList +="root:FuncParWaves:pt_CalRsRinCmVmIClampParNamesW;"
			WList +="root:FuncParWaves:pt_CalRsRinCmVmIClampParW;"
		ElseIf (ActiveAnalysisTabNum == 1)	// PSC
			WList +="root:FuncParWaves:pt_CalRsRinCmVmVClampParNamesW;"
			WList +="root:FuncParWaves:pt_CalRsRinCmVmVClampParW;"
		EndIf
		//WList +=""
		pt_EditWList(WList)
		Break
		
		Case "Spike analysis":
		WList +="root:FuncParWaves:pt_SpikeAnalParNamesW;"
		WList +="root:FuncParWaves:pt_SpikeAnalParW;"
		//WList +=""
		pt_EditWList(WList)
		Break
		
		Case "Peak analysis":
		WList +="root:FuncParWaves:pt_PeakAnalParNamesW;"
		WList +="root:FuncParWaves:pt_PeakAnalParW;"
		//WList +=""
		pt_EditWList(WList)
		Break
		
		Case "Stim. info - all cells":
		WList += "root:FuncParWaves:pt_RepsInfoParNamesW;"
		WList += "root:FuncParWaves:pt_RepsInfoParW;"
		//WList +=""
		pt_EditWList(WList)
		Break
		
		Case "Stim. info - per cell":
		// if local pt_RepsInfo doesn't exist, duplicate from root:FuncParWaves
		Wave /T CellName = $"root:CellName"
		SVAR ParentDataFolder = root:ParentDataFolder
		N = NumPnts(CellName)
		For (i =0; i< N; i+=1)
			If (!DataFolderExists(ParentDataFolder+":"+CellName[i]))
				NewDataFolder $(ParentDataFolder+":"+CellName[i])
			EndIf
			WStr = ParentDataFolder+":"+CellName[i]+":"+CellName[i]+"pt_RepsInfoParNamesW"
			WStr1 = ParentDataFolder+":"+CellName[i]+":"+CellName[i]+"pt_RepsInfoParW"
			If (!WaveExists($WStr))
				Duplicate /O $"root:funcParWaves:pt_RepsInfoParNamesW", $WStr
				Duplicate /O $"root:funcParWaves:pt_RepsInfoParW", $WStr1
				
			EndIf
			WList += WStr+";"+WStr1+";"
		EndFor
		//WList +=""
		pt_EditWList(WList)
		Break
		Case "FI thresh and slope":
			WList += "root:FuncParWaves:pt_CalFISlopeParNamesW;"
			WList += "root:FuncParWaves:pt_CalFISlopeParW;"
			//WList +=""
			pt_EditWList(WList)
		Break
		
		Case "Save analysis pars":
			WList += "root:FuncParWaves:pt_SaveFIAnalParNamesW;"
			WList += "root:FuncParWaves:pt_SaveFIAnalParW;"
			WList += "root:FuncParWaves:pt_SaveFIAnalOutNamesW;"
			pt_EditWList(WList)
		Break
		
		Case "Save analysis vector pars":
			WList += "root:FuncParWaves:pt_SaveFIVectAnalParNamesW;"
			WList += "root:FuncParWaves:pt_SaveFIVectAnalParW;"
			pt_EditWList(WList)
		Break
		
		Default:
	EndSwitch
//None;Cell database;Seal test
End


Function pt_MakeOrEditRepeatInfoW()
// make panel with reps info. Make button and edit button
End

Function pt_TextWSearch(WName, SearchStr)
// search a text wave for a searchStr and return the index of 1st occurance. 09/20/13
String WName, SearchStr
Variable i, N
Wave /T wT = $WNAme 
N = NumPnts(wT)
For (i = 0; i<N; i+=1)
	If (StringMatch(wT[i], SearchStr))
		Return i
	EndIf
EndFor
Return -1
End

End

Function /S pt_FindWWithNoteStr(FldrPath, WMatchStr, KeyWrd, NoteVal, IsString)
String FldrPath, WMatchStr, KeyWrd, NoteVal
Variable  IsString
// find which trace from traces in a given folder has a certain value for a specified keyword in wavenote.
// eg. there are 10 traces in a folder. Check wavenotes from all traces that match a MatchString and find
// which trace has a certain value for a keyword.
String OldDf, WList, FullNoteStr, NoteStr, WNameStr
Variable Numwaves, i

OldDf = GetDataFolder(1)
SetDataFolder $FldrPath

WList	= pt_SortWavesInFolder(WMatchStr, GetDataFolder(1))
Numwaves=ItemsInList(WList, ";")

Print "Finding matching wave from, N =", Numwaves, WList

For (i=0; i<Numwaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$(GetDataFolder(1)+WNameStr)
	FullNoteStr = Note(w)
	NoteStr = StringByKey(KeyWrd,FullNoteStr)
	If (IsString ==1)
		If (StringMatch(NoteStr, NoteVal))
			Return WNameStr
		EndIf
	Else
		If (    (Str2Num(NoteStr) - Str2Num(NoteVal) ) < 1e-5)
			Return WNameStr
		EndIf
	EndIf
EndFor
SetDataFolder $OldDf
Print "Warning!!! No matching wave found in ", FldrPath, "with", KeyWrd, "=", NoteVal
Return ""
End

Function pt_TestAccuracy(wTrueName, wName, err, FalsePos)
String wTrueName, wName
Variable err, FalsePos
// This is always the latest version. 
// given two vectors calculate false positive and false negative rate (assuming 1st vector as the true data). Can be used to see the accuracy of
// pt_MiniAnalysis for example
// for each point in w2, check if there is a point in w1 within an error value. If yes, count as true, if no count as false, positive. 
// for each point in w1, check if there is a point in w2 within an error value. If yes, count as true, if no count as false, negative.
// False positive.
// Example usage pt_TestAccuracy("root:Data:sEPSC:Cell_0002:ManPkXCell_0002_0009", "root:Data:sEPSC:Cell_0002:sEPSCPkXF:sEPSCPkXW4", 5e-3, 1)
//

Variable N, val, i, NTrue, NFalse
String LastUpdatedMM_DD_YYYY = "10/9/13"

Print "*********************************************************"
Print "pt_TestAccuracy last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

If (FalsePos ==1)
	Wave wTrue = $(wTrueName)	
	Wave w = $(wName)
Else
	Wave wTrue = $(wName)	// switch waves
	Wave w = $(wTrueName)
EndIf
//Sort wTrue, wTrue
//Sort w, w

N = NumPnts(w)
NTrue = 0
NFalse = 0

For (i = 0; i<N; i  += 1)
  	//val = w[i]
  	//low = val - err
  	//high = val + err
  	FindValue /T = (err) /V = (w[i]) wTrue
  	If (V_value == -1)
		NFalse = NFalse + 1
		Print "Value not found (index, value)", i, w[i]  		
  	Else
  		NTrue = NTrue + 1
  		Print "Value found (index, value)", i, w[i], "at (index, value)", V_Value, wTrue[V_Value]  
  	EndIf
EndFor
Print "Num True, Num False", NTrue, NFalse

If (FalsePos ==1)
	Print "False positive rate = ", 100*(NFalse/(NFalse+NTrue))
Else
	Print "False negative rate = ", 100*(NFalse/(NFalse+NTrue))
EndIf	 
End

Function pt_FracNoOL(BaseNameStr)
String BaseNameStr
// temporary script to calculate fraction of events that are non-overlapping
String WList, WList1
Variable i, Num
WList=pt_SortWavesInFolder("Cell_*"+BaseNameStr+"DecayT", GetDataFolder(1)) // only non overlapping events
WList1=pt_SortWavesInFolder("Cell_*"+BaseNameStr+"RiseT", GetDataFolder(1)) // all events included
Num = ItemsInList(WList)
Make /O/N=(Num) $(GetDataFolder(0) + "FracNonOL")
Wave FracNonOL = $(GetDataFolder(0) + "FracNonOL")
For (i = 0; i<Num ; i +=1)
Wave wNoOLTmp = $StringFromList(i, WList, ";")
Wave wOLTmp = $StringFromList(i, WList1, ";")
Print NumPnts(wNoOLTmp),NumPnts(wOLTmp)
FracNonOL[i] = NumPnts(wNoOLTmp)/NumPnts(wOLTmp)
Print FracNonOL[i] 
EndFor
End



Function pt_RemoveBLPoly()
// remove baseline by fitting a polynomial of specified degree
String DataWaveMatchStr, DataFldrStr, SubFldr
Variable NPoly, StartX, EndX

String WList, WNameStr, LastUpdatedMM_DD_YYYY="01_09_2013"
Variable NumWaves, i
Print "*********************************************************"
Print "pt_RemoveBLPoly last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_RemoveBLPoly", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_RemoveBLPoly", "ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_RemoveBLPolyParW and/or pt_RemoveBLPolyParNamesW!!!"
EndIf


DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				= 	AnalParW[1]
SubFldr					= 	AnalParW[2]
NPoly					= 	Str2Num(AnalParW[3])
StartX					= 	Str2Num(AnalParW[4])
EndX					=	Str2Num(AnalParW[5])

PrintAnalPar("pt_RemoveBLPoly")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
NumWaves=	ItemsInList(WList,";")
print "Subtracting baseline from waves...N=",NumWaves, WList

For (i=0; i<NumWaves; i+=1) 
	WNameStr=StringFromList(i, WList, ";")
	Wave w = $WNameStr
	Duplicate /O/R=(StartX, EndX) w, $(WNameStr+"B"), $("Fit_"+WNameStr)
	Wave w1 = $(WNameStr+"B")
	CurveFit /NTHR=0/TBOX=0/Q poly NPoly,  w1 (StartX, EndX) /D=$("Fit_"+WNameStr)
	Wave Fit_w1 = $("Fit_"+WNameStr)
	w1 -= Fit_w1
	KillWaves /Z Fit_w1
EndFor	

End

// statistical power calculation
Function pt_StatPower()

Print "Given 3 of the following pars, 4th can be calculated: Effect size, power, significance level, sample size"
Print "Use pwr function in R to calculate above pars"
Print "Install 'pwr' package using package installer in RStudio. Use require(pwr) to load package "
Print "Use pwr.anova.test(k =, f = ,  sig.level =, power =)"
Print "Use formula for f given under the subheading anova at http://www.statmethods.net/stats/power.html"

End

Function pt_FIAnalyzeCells(ctrlName) : ButtonControl
String ctrlName
// Based on pt_MiniAnalysis
// Modified from pt_FIAnalysis to separate analyzing all cells and pooling data 11/07/13


//String CellNamePrefix
//Variable DoSealTestAnal
String OldDf, ConditionFldrList, AnalFldr="root:ConditionAnal",ParStr
Variable NCond, i, PkPolarity, HistBinStart, HistBinWidth, HistNumBins,NSealTestParList,j,k,NSpkAnalScalarParList, NSpkAnalVectorParList
String DisplayWinName, TraceNameStr1, TraceNameStr2
String SealTestParList="RsV;RInV;CmV;"
String SpkAnalScalarParList="WSpikeFreq;EOPAHPY"
String SpkAnalVectorParList="AHPY;PeakRelY;FWFracM;PeakAbsX;SpikeThreshY;SpkMaxDvDtY;TToFracPeakY;IFrq;ISI"		// parameters that are function of spike number and current
// for vector pars, the pars will be extracted for 1st, 2nd, 3rd spike separately. VectorParNSpks specifies number of spikes to analyze.
//Variable VectorParNSpks = 3
//String /G root:ExcludeWList
//String ExcludeWList=$"root:ExcludeWList"
NSealTestParList=ItemsInList(SealTestParList)
NSpkAnalScalarParList=ItemsInList(SpkAnalScalarParList)
NSpkAnalVectorParList=ItemsInList(SpkAnalVectorParList)

Print "Starting FI Analysis at", time(), "on", date()

String LastUpdatedMM_DD_YYYY="11_11_2013"
Print "*********************************************************"
Print "pt_FIAnalyzeCells last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

//Wave /T AnalParNamesW	=	$pt_GetParWave("pt_FIAnalysis", "ParNamesW")
//Wave /T AnalParW			=	$pt_GetParWave("pt_FIAnalysis", "ParW")

//If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
//	Abort	"Cudn't find the parameter waves  pt_FIAnalysisParW and/or pt_FIAnalysisParNamesW!!!"
//EndIf

SVAR CellNamePrefix = root:AnalysisViewer:CellNamePrefix
NVAR DoSealTestAnal =  root:AnalysisViewer:DoSealTestAnal

Print "CellNamePrefix", CellNamePrefix
Print "DoSealTestAnal", DoSealTestAnal

//CellNamePrefix		=	AnalParW[0]
//DoSealTestAnal		= 	Str2Num(AnalParW[1])

//PrintAnalPar("pt_FIAnalysis")


//DoAlert 1,"Press 'Yes', if Cell_*RepsInfo waves waves have been created and edited for each cell" 
//If (V_Flag==2)
//	Abort "Aborting...."
//EndIf

//DoAlert 1,"Press 'Yes', if parameters for pt_SpikeAnal(), pt_CalRsRinCmVmVClamp(), pt_MoveWavesMany have been adjusted and the folders for pt_MoveWavesMany exist. "
//If (V_Flag==2)
//	Abort "Aborting...."
//EndIf
NewDataFolder /O $AnalFldr

//******************
// pt_AnalWInFldrs2("pt_SpikeAnal")
String BaseNameStr
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SpikeAnal", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_SpikeAnal", "ParW")
BaseNameStr = AnalParW[14]
Print "BaseNameStr=",BaseNameStr
pt_AnalWInFldrs2("pt_SpikeAnal")
//******************
//pt_AnalWInFldrs2("pt_CalRsRinCmVmIClamp")
If (DoSealTestAnal)
	 pt_AnalWInFldrs2("pt_CalRsRinCmVmIClamp")
 EndIf
 //******************
//pt_AnalWInFldrs2("pt_ExtractFromWaveNote")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractFromWaveNote", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractFromWaveNote", "ParW")
SaveNRestore("pt_ExtractFromWaveNote", 1)
AnalParW[0]	=	CellNamePrefix+"*"				//DataWaveMatchStr
AnalParW[1]	=	"RawData:"				//DataFldrStr	
AnalParW[2]	=	"Stim Amp."	//KeyStrName
AnalParW[3]	=	"0"				//ParIsStr
AnalParW[4]	=	"CurrW"		//OutWNameStr
pt_AnalWInFldrs2("pt_ExtractFromWaveNote")
SaveNRestore("pt_ExtractFromWaveNote", 2)

//******************
//pt_AnalWInFldrs2("pt_ExtractRepsNSrt")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractRepsNSrt", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractRepsNSrt", "ParW")

SaveNRestore("pt_ExtractRepsNSrt", 1)
AnalParW[0]	=	"CurrW"		//SortKeyWName
AnalParW[2]	=	"pt_RepsInfo"			//RangeW	
AnalParW[3]	=	"DataFldrName"				//RangeWPrefixStr
AnalParW[4]	=	""		//SortKeyOutWName
AnalParW[5]	=	""		//SortParOutWName

If (DoSealTestAnal ==1)
For(j=0;j<NSealTestParList;j+=1)
	ParStr=StringFromList(j, SealTestParList, ";")
	AnalParW[1]	=	ParStr			//SortParWName
	pt_AnalWInFldrs2("pt_ExtractRepsNSrt")
EndFor
EndIf

For(j=0;j<NSpkAnalScalarParList;j+=1)
	ParStr=StringFromList(j, SpkAnalScalarParList, ";")
	AnalParW[1]	=	BaseNameStr+ParStr			//SortParWName
	pt_AnalWInFldrs2("pt_ExtractRepsNSrt")
EndFor

//AnalParW[1]	=	BaseNameStr+"WSpikeFreq"				//SortParWName
//pt_AnalWInFldrs2("pt_ExtractRepsNSrt")

//AnalParW[1]	=	BaseNameStr+"EOPAHPY"				//SortParWName
//pt_AnalWInFldrs2("pt_ExtractRepsNSrt")
	
SaveNRestore("pt_ExtractRepsNSrt", 2)

//******************
//pt_AnalWInFldrs2("pt_ExtractWRepsNSrt")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParW")

SaveNRestore("pt_ExtractWRepsNSrt", 1)
AnalParW[0]	=	"CurrW"		//SortKeyWName
AnalParW[3]	=	"pt_RepsInfo"			//RangeW	
AnalParW[4]	=	"DataFldrName"			//RangeWPrefixStr

//SpkAnalVectorParList,VectorParNSpks
For(j=0;j<NSpkAnalVectorParList;j+=1)
	ParStr=StringFromList(j, SpkAnalVectorParList, ";")
	AnalParW[1]	=	BaseNameStr+ParStr+"W"			//SortParWList
	AnalParW[2]	=	BaseNameStr+ParStr+"F:"			//SubFldrList
	pt_AnalWInFldrs2("pt_ExtractWRepsNSrt")
EndFor
SaveNRestore("pt_ExtractWRepsNSrt", 2)
//******************
//*//pt_AnalWInFldrs2("pt_ExtractWRepsNSrt")
//*Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParNamesW")
//*Wave /T AnalParW				=	$pt_GetParWave("pt_ExtractWRepsNSrt", "ParW")

//*SaveNRestore("pt_ExtractWRepsNSrt", 1)
//*AnalParW[0]	=	"CurrW"		//SortKeyWName
//*AnalParW[3]	=	"pt_RepsInfo"			//RangeW	
//*AnalParW[4]	=	"DataFldrName"				//RangeWPrefixStr

//*AnalParW[1]	=	BaseNameStr+"FWFracMW"			//SortParWList
//*AnalParW[2]	=	BaseNameStr+"FWFracMF:"	//SubFldrList
//*pt_AnalWInFldrs2("pt_ExtractWRepsNSrt")

//*AnalParW[1]	=	BaseNameStr+"PeakAbsXW"			//SortParWList
//*AnalParW[2]	=	BaseNameStr+"PeakAbsXF:"	//SubFldrList
//*pt_AnalWInFldrs2("pt_ExtractWRepsNSrt")

//*SaveNRestore("pt_ExtractWRepsNSrt", 2)


Wave /T AnalParNamesW		=	$pt_GetParWave("pt_PostProcessFI", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW				=	$pt_GetParWave("pt_PostProcessFI", "ParW")

Duplicate /O/T AnalParW, pt_PostProcessFIAnalParWOrig

AnalParW[0]	=		""//DataWaveMatchStr
AnalParW[1]	=		""//DataFldrStr
AnalParW[2]	=		"pt_RepsInfo"//RangeW
AnalParW[3]	=		"DataFldrName"//RangeWPrefixStr

pt_AnalWInFldrs2("pt_PostProcessFI")//()

Duplicate /O/T pt_PostProcessFIAnalParWOrig, AnalParW
Killwaves /Z pt_PostProcessFIAnalParWOrig

//*AnalParW[4]	=	BaseNameStr+"FWFracMF:"				//SubFldr

//*AnalParW[0]	=	 "S"+BaseNameStr+"FWFracMW*_0"			//DataWaveMatchStr
//*AnalParW[3]	=	BaseNameStr+"_SpkFWHM_0"			//BaseNameString
//*pt_AnalWInFldrs2("pt_AverageVals")

//*AnalParW[0]	=	 "S"+BaseNameStr+"FWFracMW*_1"			//DataWaveMatchStr
//*AnalParW[3]	=	 BaseNameStr+"_SpkFWHM_1"			//BaseNameString
//*pt_AnalWInFldrs2("pt_AverageVals")


//SaveNRestore("pt_AverageVals", 2)
//******************
//pt_AnalWInFldrs2("pt_AverageWaves")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")

SaveNRestore("pt_AverageWaves", 1)

AnalParW[1]	=	""	//DataFldrStr
AnalParW[3]	=	"1"//PntsPerBin
AnalParW[4]	=	""//ExcludeWNamesWStr
AnalParW[5]	=	"1"//DisplayAvg

If (DoSealTestAnal ==1)
For(j=0;j<NSealTestParList;j+=1)
	ParStr=StringFromList(j, SealTestParList, ";")
	AnalParW[0]	=	ParStr+"*Srt"			//DataWaveMatchStr
	AnalParW[2]	=	ParStr					//BaseNameStr
	pt_AnalWInFldrs2("pt_AverageWaves")
EndFor
//--
//******************
// Moved from pt_PoolNAvgFIData

//pt_AnalWInFldrs2("pt_AverageVals")
Wave /T AvgValsAnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T AvgValsAnalParW				=	$pt_GetParWave("pt_AverageVals", "ParW")
Duplicate /T/O AvgValsAnalParW, AvgValsAnalParWOrig

AvgValsAnalParW[1]	=	"-1"				//XStartVal
AvgValsAnalParW[2]	=	"-1"				//XEndVal
AvgValsAnalParW[4]	=	""					//SubFldr

For(j=0;j<NSealTestParList;j+=1)
	ParStr=StringFromList(j, SealTestParList, ";")
	AvgValsAnalParW[0]	=	ParStr+"_Avg"//DataWaveMatchStr
	AvgValsAnalParW[3]	=	ReplaceString("V", ParStr, "")	//BaseNameString. Renaming to Rs, RIn, Cm
	pt_AnalWInFldrs2("pt_AverageVals")
EndFor
Duplicate /T/O AvgValsAnalParWOrig, AvgValsAnalParW
KillWaves /Z AvgValsAnalParWOrig
//==

EndIf

For(j=0;j<NSpkAnalScalarParList;j+=1)
	ParStr=StringFromList(j, SpkAnalScalarParList, ";")
	AnalParW[0]	=	BaseNameStr+ParStr+"*Srt"			//DataWaveMatchStr
	AnalParW[2]	=	BaseNameStr+ParStr					//BaseNameStr
	pt_AnalWInFldrs2("pt_AverageWaves")
EndFor

// also average the sorted current waves
AnalParW[0]	=	"CurrW"+"*Srt"			//DataWaveMatchStr
AnalParW[2]	=	"CurrW"					//BaseNameStr
pt_AnalWInFldrs2("pt_AverageWaves")

//For(j=0;j<NSpkAnalParListItem;j+=1)
//	SpkAnalParListStr=StringFromList(j, SpkAnalParList, ";")
//	AnalParW[0]	=	BaseNameStr+"WSpikeFreq"+"*Srt"			//DataWaveMatchStr
//	AnalParW[2]	=	BaseNameStr+"SpkAvgFrq"						//BaseNameStr
//	pt_AnalWInFldrs2("pt_AverageWaves")
	
//	AnalParW[0]	=	BaseNameStr+"EOPAHPY"+"*Srt"			//DataWaveMatchStr
//	AnalParW[2]	=	BaseNameStr+"EopAhpY"						//BaseNameStr
//	pt_AnalWInFldrs2("pt_AverageWaves")
//EndFor

//AnalParW[0]	=	BaseNameStr+"AdaptR"+"_*"			//DataWaveMatchStr
//AnalParW[1]	=	BaseNameStr+"PeakAbsXF:"		//DataFldrStr
//AnalParW[2]	=	BaseNameStr+"AdaptR"			//BaseNameStr
//pt_AnalWInFldrs2("pt_AverageWaves")




//*AnalParW[0]	=	BaseNameStr+"_SpkFWHM_*Avg"				//DataWaveMatchStr
//*AnalParW[1]	=	BaseNameStr+"FWFracMF:"		//DataFldrStr
//*AnalParW[2]	=	BaseNameStr+"SpkFWHM"			//BaseNameStr
//*pt_AnalWInFldrs2("pt_AverageWaves")

SaveNRestore("pt_AverageWaves", 2)
//
// Also calculate the current threshold and slope of FI curve.
Wave /T AnalParNamesW	=	$pt_GetParWave("pt_CalFISlope", "ParNamesW")		
Wave /T AnalParW			=	$pt_GetParWave("pt_CalFISlope", "ParW")

SaveNRestore("pt_CalFISlope", 1)

AnalParW[0] = BaseNameStr+"WSpikeFreq_Avg"	 //DataWaveMatchStr
AnalParW[1] = ""//SubFldr	
//AnalParW[2] = //CurrRangeAboveThresh Set by user in the pt_Analysis GUI
AnalParW[3] = "1"//InterpCorr
AnalParW[4] = "FI_"//OutWBaseName
pt_AnalWInFldrs2("pt_CalFISlope")
SaveNRestore("pt_CalFISlope", 2)
End

Function pt_FactorToPool(ctrlName) : ButtonControl
String ctrlName
String quote = "\""

SVAR List_Anova = root:AnalysisViewer:List_Anova
String LList_Anova = List_Anova
LList_Anova = quote + LList_Anova + quote
String PanelName = "Choose_factor"
PauseUpdate; Silent 1		// building window...
DoWindow $PanelName
If (V_Flag==1)
	DoWindow /F $PanelName
Else
NewPanel /K=1/W=(10,10,200,100)
DoWindow /C $PanelName
SetDrawLayer UserBack
EndIf

PopupMenu popup0,pos={10,10},size={80,20}, fSize = 12, title = "Anova factor"
PopupMenu popup0,mode=1,popvalue="None",value= #LList_Anova//, proc = pt_CallEditWList

Button button1,pos={30,40},size={120,30},fSize = 12, title = "Analyze"
Button button1, limits={0,inf,1}, proc = pt_PoolFIData

End

Function pt_PoolNAvgFIData(ctrlName) : ButtonControl
// Modified from pt_FIAnalysis to separate analyzing all cells and pooling data 11/07/13
String ctrlName

SVAR PanelName = root:AnalysisViewer:PanelName
//SVAR GraphName = root:AnalysisViewer:GraphName
NVAR VectorParNSpks = root:AnalysisViewer:VectorParNSpks

String OldDf, ConditionFldrList, AnalFldr="root:ConditionAnal",ParStr
Variable NCond, i, PkPolarity, HistBinStart, HistBinWidth, HistNumBins,NSealTestParList,j,k,NSpkAnalScalarParList
String DisplayWinName, TraceNameStr1, TraceNameStr2
String SealTestParList="RsV;RInV;CmV;"
String SpkAnalScalarParList="WSpikeFreq;EOPAHPY;AvgIFrq;AdaptR;"
String SpkAnalVectorParList="AHPY;PeakRelY;FWFracM;SpikeThreshY;SpkMaxDvDtY;TToFracPeakY;IFrq;ISI"
Variable NSpkAnalVectorParList = ItemsInList(SpkAnalVectorParList, ";")
String tileCommand = "", WList1, WList2, WStr1, WStr2
Variable N1, N2, pt_red, pt_Green, pt_blue, col_id
//String /G root:ExcludeWList
//String ExcludeWList=$"root:ExcludeWList"
NSealTestParList=ItemsInList(SealTestParList)
NSpkAnalScalarParList=ItemsInList(SpkAnalScalarParList)

Print "Starting FI data pooling at", time(), "on", date()

String LastUpdatedMM_DD_YYYY="11_11_2013"
Print "*********************************************************"
Print "pt_PoolNAvgFIData last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

SVAR CellNamePrefix = root:AnalysisViewer:CellNamePrefix
NVAR DoSealTestAnal =  root:AnalysisViewer:DoSealTestAnal


// color
Wave /T ColorLevelNamesW 	=	root:AnalysisViewer:ColorLevelNamesW
Wave ColorLevel_RedVal 		=	root:AnalysisViewer:ColorLevel_RedVal
Wave ColorLevel_BlueVal 		=	root:AnalysisViewer:ColorLevel_BlueVal
Wave ColorLevel_GreenVal 	= 	root:AnalysisViewer:ColorLevel_GreenVal
//

Print "CellNamePrefix", CellNamePrefix
Print "DoSealTestAnal", DoSealTestAnal

NewDataFolder /O $AnalFldr

//******************
// pt_AnalWInFldrs2("pt_SpikeAnal")
String BaseNameStr
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SpikeAnal", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_SpikeAnal", "ParW")
BaseNameStr = AnalParW[14]
Print "BaseNameStr=",BaseNameStr


//******************
//pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_DuplicateWFrmFldrs", "ParW")

AnalParW[0]	=	AnalFldr	//DestFolderName
AnalParW[2]	=	"DataFldrName"				//PrefixStr
AnalParW[3]	=	""							//SuffixStr
AnalParW[4]	=	"-1"						//XStartVal
AnalParW[5]	=	"-1"						//XEndVal
AnalParW[6]	=	""		//SubFldr

SaveNRestore("pt_DuplicateWFrmFldrs", 1)

AnalParW[1]	=	"*_Avg"		//DataWaveMatchStr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

AnalParW[1]	=	BaseNameStr+"AdaptR_Avg"			//DataWaveMatchStr
//AnalParW[6]	=	BaseNameStr+"PeakAbsXF:"				//SubFldr
AnalParW[6]	=	BaseNameStr+"ISIF:"				//SubFldr

pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")


AnalParW[1]	=	BaseNameStr+"AvgIFrq_Avg"			//DataWaveMatchStr
AnalParW[6]	=	BaseNameStr+"IFrqF:"				//SubFldr
pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

//*AnalParW[1]	=	BaseNameStr+"SpkFWHM_Avg"				//DataWaveMatchStr
//*AnalParW[6]	=	BaseNameStr+"FWFracMF:"				//SubFldr
//*pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")

For (i = 0; i < NSpkAnalVectorParList; i +=1)
	ParStr=StringFromList(i, SpkAnalVectorParList, ";")
	AnalParW[1]	=	"Spk"+"*"+BaseNameStr+ParStr+"W"	//DataWaveMatchStr
	AnalParW[6]	=	BaseNameStr+ParStr+"F:"				//SubFldr
	pt_AnalWInFldrs2("pt_DuplicateWFrmFldrs")
EndFor

SaveNRestore("pt_DuplicateWFrmFldrs", 2) 

//******************

OldDf = GetDataFolder(1)
SetDataFolder AnalFldr

SaveNRestore("pt_MoveWavesMany", 1) 
Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_MoveWavesMany"+"ParW")
AnalParW[2]="1"//Overwrite
pt_MoveWavesMany()
SaveNRestore("pt_MoveWavesMany", 2)
SetDataFolder OldDf
 
ConditionFldrList=AnalParW[1]		//ListDestFolderName
NCond=ItemsInList(ConditionFldrList,";")
OldDf = GetDataFolder(1)

//******************
If (DoSealTestAnal ==1)
//pt_AnalWInFldrs2("pt_AverageVals")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageVals", "ParW")
SaveNRestore("pt_AverageVals", 1)

AnalParW[1]	=	"-1"				//XStartVal
AnalParW[2]	=	"-1"				//XEndVal
AnalParW[4]	=	""					//SubFldr

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	For(j=0;j<NSealTestParList;j+=1)
		ParStr=StringFromList(j, SealTestParList, ";")
 
		AnalParW[0]	=	CellNamePrefix+"*"+ParStr+"_Avg"//DataWaveMatchStr
		AnalParW[3]	=	GetDataFolder(0)+ParStr	//BaseNameString
		pt_AverageVals()

//AnalParW[0]	=	"Cell_*RInV"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"RInV"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*CmV"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"CmV"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*"+BaseNameStr+"InstFrq"		//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"InstFrq"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*"+BaseNameStr+"PkAmpRelW"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"PkAmp"	//BaseNameString
//pt_AverageVals()

//AnalParW[0]	=	"Cell_*"+BaseNameStr+"TauD"	//DataWaveMatchStr
//AnalParW[3]	=	GetDataFolder(0)+"TauD"	//BaseNameString
//pt_AverageVals()
	EndFor
EndFor
SaveNRestore("pt_AverageVals", 2)
EndIf

//******************
//display
If (DoSealTestAnal ==1)
For (i=0;i<NCond;i+=1)

SetDataFolder StringFromList(i, ConditionFldrList, ";")
col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
If (col_id == -1)
	col_id = 0
EndIf
pt_Red 		= ColorLevel_RedVal[col_id]
pt_Green 	= ColorLevel_GreenVal[col_id]
pt_Blue 		= ColorLevel_BlueVal[col_id]

	For(j=0;j<NSealTestParList;j+=1)
		ParStr=StringFromList(j, SealTestParList, ";")
		DisplayWinName=ParStr+"_All"
		DoWindow $DisplayWinName//PanelName+"#"+GraphName+"#"+ParStr+"_All"
		If (V_Flag)
			DoWindow /F $DisplayWinName//PanelName+"#"+GraphName+"#"+ParStr+"_All"
		Else
			//Display /Host=$DisplayWinNamePanelName#$GraphName
			//RenameWindow #,$(ParStr+"_All")
			Display
			DoWindow /C $DisplayWinName
		EndIf
		//AppendToGraph /W=$PanelName#$GraphName#$(ParStr+"_All") $GetDataFolder(0)+ParStr+"Avg"
		//Legend 			/W=$PanelName#$GraphName#$(ParStr+"_All") /C/N=text0/F=0/A=RT
		//ModifyGraph 	/W=$PanelName#$GraphName#$(ParStr+"_All")  fSize=14, mode = 4, marker = 19
		AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+ParStr+"Avg"
		Legend 			/W=$DisplayWinName /C/N=text0/F=0/A=RT
		ModifyGraph 	/W=$DisplayWinName  fSize=14, mode = 4, marker = 19
		ModifyGraph 	/W=$DisplayWinName rgb($GetDataFolder(0)+ParStr+"Avg")=(pt_Red, pt_Green, pt_Blue)
	EndFor
	
EndFor
EndIf


//******************
//pt_AnalWInFldrs2("pt_AppendWToGraph")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AppendWToGraph", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AppendWToGraph", "ParW")
SaveNRestore("pt_AppendWToGraph", 1)


For(j=0;j<NSpkAnalScalarParList;j+=1)
	ParStr=StringFromList(j, SpkAnalScalarParList, ";")
	DisplayWinName=ParStr+"_All"
	DoWindow $DisplayWinName
	If (V_Flag)
		DoWindow /F $DisplayWinName
	Else
		Display
		DoWindow /C $DisplayWinName
	EndIf
	
	AnalParW[0]=CellNamePrefix+"*"+BaseNameStr+ParStr+"_Avg"
	AnalParW[1]=DisplayWinName
	AnalParW[2]="-1"
	AnalParW[3]=""
	
	For (i=0;i<NCond;i+=1)
		SetDataFolder StringFromList(i, ConditionFldrList, ";")
		col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
		If (col_id == -1)
			col_id = 0
		EndIf
		pt_Red 		= ColorLevel_RedVal[col_id]
		pt_Green 	= ColorLevel_GreenVal[col_id]
		pt_Blue 		= ColorLevel_BlueVal[col_id]			
		AnalParW[4]=Num2Str(pt_Red)+";"+Num2Str(pt_Green)+";"+Num2Str(pt_Blue)+";"
		pt_AppendWToGraph()
	EndFor
	ModifyGraph /W=$DisplayWinName  fSize=14, mode = 4, marker = 19		
EndFor
SaveNRestore("pt_AppendWToGraph", 2)

//$$$$$
//******************Temporary generation of InstFrq_All graph. Later can be done using a list with similar graph 11/17/13/
//pt_AnalWInFldrs2("pt_AppendWToGraph")
//$$$###//Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AppendWToGraph", "ParNamesW")
//$$$###//Wave /T AnalParW			=	$pt_GetParWave("pt_AppendWToGraph", "ParW")
//$$$###//SaveNRestore("pt_AppendWToGraph", 1)


//*For(j=0;j<NSpkAnalScalarParList;j+=1)
//*	ParStr=StringFromList(j, SpkAnalScalarParList, ";")
	//ParStr = "InstFrq"
//$$$###//	ParStr = "AvgIFrq"
	
//$$$###//	DisplayWinName=ParStr+"_All"
//$$$###//	DoWindow $DisplayWinName
//$$$###//	If (V_Flag)
//$$$###//		DoWindow /F $DisplayWinName
//$$$###//	Else
//$$$###//		Display
//$$$###//		DoWindow /C $DisplayWinName
//$$$###//	EndIf
	
//$$$###//	AnalParW[0]=CellNamePrefix+"*"+BaseNameStr+ParStr+"_Avg"
//$$$###//	AnalParW[1]=DisplayWinName
//$$$###//	AnalParW[2]="-1"
//$$$###//	AnalParW[3]=""
	
//$$$###//	For (i=0;i<NCond;i+=1)
//$$$###//		SetDataFolder StringFromList(i, ConditionFldrList, ";")
//$$$###//		col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
//$$$###//		If (col_id == -1)
//$$$###//			col_id = 0
//$$$###//		EndIf
//$$$###//		pt_Red 		= ColorLevel_RedVal[col_id]
//$$$###//		pt_Green 	= ColorLevel_GreenVal[col_id]
//$$$###//		pt_Blue 		= ColorLevel_BlueVal[col_id]
//$$$###//		AnalParW[4]=Num2Str(pt_Red)+";"+Num2Str(pt_Green)+";"+Num2Str(pt_Blue)+";"
//$$$###//		pt_AppendWToGraph()
//$$$###//	EndFor
//$$$###//	ModifyGraph /W=$DisplayWinName  fSize=14, mode = 4, marker = 19		
//EndFor
//$$$###//SaveNRestore("pt_AppendWToGraph", 2)
//$$$$$




// Calculate averages and SEM

NewDataFolder /O $(AnalFldr+":Stats")

If (!WaveExists($(AnalFldr+":Stats:ConditionW")))
	Make /O/N=(NCond)/T $(AnalFldr+":Stats:ConditionW")
	Wave /T ConditionW=$(AnalFldr+":Stats:ConditionW")
Else
	Wave /T ConditionW=$(AnalFldr+":Stats:ConditionW")
EndIf

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	ConditionW[i]=GetDataFolder(0)
EndFor


If (DoSealTestAnal ==1)	
For(j=0;j<NSealTestParList;j+=1)
	ParStr=StringFromList(j, SealTestParList, ";")
	If (!WaveExists($(AnalFldr+":Stats:"+ParStr+"Avg")))
		Make /O/N=(NCond) $(AnalFldr+":Stats:"+ParStr+"Avg")
		Wave wAvg=$(AnalFldr+":Stats:"+ParStr+"Avg")
	Else
		Wave wAvg=$(AnalFldr+":Stats:"+ParStr+"Avg")
	EndIf
	
	If (!WaveExists($(AnalFldr+":Stats:"+ParStr+"SE")))
		Make /O/N=(NCond) $(AnalFldr+":Stats:"+ParStr+"SE")
		Wave wSE=$(AnalFldr+":Stats:"+ParStr+"SE")
	Else
		Wave wSE=$(AnalFldr+":Stats:"+ParStr+"SE")
	EndIf
		
	For (i=0;i<NCond;i+=1)
		SetDataFolder StringFromList(i, ConditionFldrList, ";")
		Print GetDataFolder(1)
		Wavestats $GetDataFolder(0)+ParStr+"Avg"
		wAvg[i]=V_Avg
		wSE[i]=V_Sem
	EndFor
EndFor
EndIf

// Draw category plots
//SetDataFolder $(AnalFldr+":Stats")
If (DoSealTestAnal ==1)
For(j=0;j<NSealTestParList;j+=1)
	ParStr=StringFromList(j, SealTestParList, ";")
	Display $(AnalFldr+":Stats:"+ParStr+"Avg") vs $(AnalFldr+":Stats:ConditionW")
	DisplayWinName=ParStr+"_Avg"
	DoWindow /C $DisplayWinName
	TraceNameStr1=ParStr+"Avg"	// tracename is just the name of the wave without the entire path
	TraceNameStr2=AnalFldr+":Stats:"+ParStr+"SE"
	ErrorBars /W=$DisplayWinName $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
	Legend/C/N=text0/F=0/A=RT
	ModifyGraph /W=$DisplayWinName fSize=14//, mode = 4, marker = 19
//	SetAxis /W=$ParStr Left 0,inf	
EndFor
EndIf


//*****************
//pt_AnalWInFldrs2("pt_AverageWaves")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")

SaveNRestore("pt_AverageWaves", 1)

AnalParW[1]	=	""	//DataFldrStr
AnalParW[3]	=	"1"//PntsPerBin
AnalParW[4]	=	""//ExcludeWNamesWStr
AnalParW[5]	=	"1"//DisplayAvg

For (i=0;i<NCond;i+=1)
	SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
	For(j=0;j<NSpkAnalScalarParList;j+=1)
		ParStr=StringFromList(j, SpkAnalScalarParList, ";")
		AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+ParStr+"_Avg"//DataWaveMatchStr
		AnalParW[2]	=	 GetDataFolder(0)+ParStr			//BaseNameStr
		pt_AverageWaves()
	EndFor
	
	
	For (j = 0; j < NSpkAnalVectorParList; j +=1)
		ParStr=StringFromList(j, SpkAnalVectorParList, ";")
		For (k =0; k < VectorParNSpks; k +=1)
			AnalParW[0]	=	CellNamePrefix+"*"+"Spk"+Num2Str(k)+BaseNameStr+ParStr+"W"	//DataWaveMatchStr
			AnalParW[2]	=	GetDataFolder(0)+"Spk"+Num2Str(k)+ParStr				//BaseNameStr
		pt_AverageWaves()
		EndFor
	EndFor
	
	//$$$###//AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"AvgIFrq_Avg"//DataWaveMatchStr
	//$$$###//AnalParW[2]	=	 GetDataFolder(0)+"AvgInstFrq"		//BaseNameStr
	//$$$###//pt_AverageWaves()
	
	
	//$$$###//AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"AdaptR_Avg"//DataWaveMatchStr
	//$$$###//AnalParW[2]	=	 GetDataFolder(0)+"AdaptR"				//BaseNameStr
	//$$$###//pt_AverageWaves()
	
	//*AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"SpkFWHM_Avg"//DataWaveMatchStr
	//*AnalParW[2]	=	 GetDataFolder(0)+"SpkFWHM"				//BaseNameStr
	//*pt_AverageWaves()

EndFor

SaveNRestore("pt_AverageWaves", 2)
//*****************
If (DoSealTestAnal ==1)		// plot freq as func of current density
	For (i=0;i<NCond;i+=1)
		SetDataFolder StringFromList(i, ConditionFldrList, ";")
	
		WList1= pt_SortWavesInFolder(CellNamePrefix+"*"+"CurrW_Avg", GetDataFolder(-1))
		//WList2 =pt_SortWavesInFolder(CellNamePrefix+"*"+"CmV_Avg", GetDataFolder(-1))
		Wave CmAvg = $(GetDataFolder(0) + "CmVAvg")
		N1 = ItemsInList(WList1, ";"); 	N2 = NumPnts(CmAvg)//N2 = ItemsInList(WList2, ";")
		If (N1 == N2)
			For (j =0; j<N1; j+=1)
				WStr1 = StringFromList(j, WList1, ";")
				//WStr2 = StringFromList(j, WList2, ";")
				Duplicate /O $WStr1, $WStr1+"NCm" // currents normalized to Cm
				Wave NCmW =  $WStr1+"NCm" 
				//Wave CmW =  $WStr2
				NCmW /= CmAvg[j]
			EndFor
			// convert normalized XY data to waveform data
			Wave /T AnalParNamesW		=	$pt_GetParWave("pt_XYToWave2", "ParNamesW")		
			Wave /T AnalParW				=	$pt_GetParWave("pt_XYToWave2", "ParW")
			SaveNRestore("pt_XYToWave2", 1)
			AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"WSpikeFreq_Avg"	//YWaveMatchStr
			AnalParW[1]	=	CellNamePrefix+"*"+"CurrW_AvgNCm"				//XWaveMatchStr
 			AnalParW[2]	=	""														//SubFldr
			AnalParW[3]	=	""
  			AnalParW[4]	= 	""														//OutStartX
  			AnalParW[5]	= 	""														//OutEndX  =  
  			AnalParW[6]	= 	"1"														//DisplayInterp
			pt_XYToWave2()
			SaveNRestore("pt_XYToWave2", 2)
		EndIf
	Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")		
	Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")
	SaveNRestore("pt_AverageWaves", 1)
	AnalParW[1]	=	""	//DataFldrStr
	AnalParW[3]	=	"1"//PntsPerBin
	AnalParW[4]	=	""//ExcludeWNamesWStr
	AnalParW[5]	=	"1"//DisplayAvg
	
	AnalParW[0]	=	CellNamePrefix+"*"+BaseNameStr+"WSpikeFreq_Avg"+"_ip"	
	AnalParW[2]	=	 GetDataFolder(0)+"WSpikeFreqNCm"				//BaseNameStr
	pt_AverageWaves()
	SaveNRestore("pt_AverageWaves", 2)
	EndFor

EndIf

//*****************
//display
For (i=0;i<NCond;i+=1)
SetDataFolder StringFromList(i, ConditionFldrList, ";")
col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
If (col_id == -1)
	col_id = 0
EndIf
pt_Red 		= ColorLevel_RedVal[col_id]
pt_Green 	= ColorLevel_GreenVal[col_id]
pt_Blue 		= ColorLevel_BlueVal[col_id]

	For(j=0;j<NSpkAnalScalarParList;j+=1)
		ParStr=StringFromList(j, SpkAnalScalarParList, ";")
		DisplayWinName= ParStr+"_Avg"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		Endif
		TraceNameStr1=GetDataFolder(0)+ParStr+"_Avg"	// tracename is just the name of the wave without the entire path
		TraceNameStr2=GetDataFolder(0)+ParStr	+"_SE"
		AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+ParStr+"_Avg"
		ErrorBars /W=$DisplayWinName $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
		Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
		ModifyGraph /W=$DisplayWinName fSize=14, mode = 4, marker = 19
		ModifyGraph 	/W=$DisplayWinName rgb($GetDataFolder(0)+ParStr+"_Avg")=(pt_Red, pt_Green, pt_Blue)
		
	EndFor

	
		//$$$###//DisplayWinName="InstFrq_Avg"
		//$$$###//DoWindow $DisplayWinName
		//$$$###//If (V_Flag)
		//$$$###//	DoWindow /F $DisplayWinName
		//$$$###//Else
		//$$$###//	Display
		//$$$###//	DoWindow /C $DisplayWinName
		//$$$###//Endif
	//$$$###//TraceNameStr1=GetDataFolder(0)+"AvgInstFrq"	+"_Avg"	// tracename is just the name of the wave without the entire path
	//$$$###//TraceNameStr2=GetDataFolder(0)+"AvgInstFrq"	+"_SE"
	//$$$###//AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+"AvgInstFrq"+"_Avg"
	//$$$###//ErrorBars /W=$DisplayWinName $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
	//$$$###//Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
	//$$$###//ModifyGraph /W=$DisplayWinName fSize=14, mode = 4, marker = 19
	//$$$###//ModifyGraph 	/W=$DisplayWinName rgb($GetDataFolder(0)+"InstFrq"+"_Avg")=(pt_Red, pt_Green, pt_Blue)
	
	//----
	If (DoSealTestAnal ==1)		// plot freq as func of current density
	DisplayWinName="WSpikeFreqNCm_Avg"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		Endif
	TraceNameStr1=GetDataFolder(0)+"WSpikeFreqNCm"	+"_Avg"	// tracename is just the name of the wave without the entire path
	TraceNameStr2=GetDataFolder(0)+"WSpikeFreqNCm"	+"_SE"
	AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+"WSpikeFreqNCm"+"_Avg"
	ErrorBars /W=$DisplayWinName $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
	Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
	ModifyGraph /W=$DisplayWinName fSize=14, mode = 4, marker = 19
	ModifyGraph 	/W=$DisplayWinName rgb($GetDataFolder(0)+"WSpikeFreqNCm"+"_Avg")=(pt_Red, pt_Green, pt_Blue)
	EndIf
	//----
	//Also display raw traces for "WSpikeFreqNCm_Avg"
	If (DoSealTestAnal ==1)		// plot freq as func of current density
		DisplayWinName="WSpikeFreqNCm_All"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		Endif
		Wave /T AnalParNamesW					=	$pt_GetParWave("pt_AppendWToGraph", "ParNamesW")
		Wave /T AppendToGraphAnalParW			=	$pt_GetParWave("pt_AppendWToGraph", "ParW")
		Duplicate /T/O AppendToGraphAnalParW, AppendToGraphAnalParWOrig
		 AppendToGraphAnalParW[0]=CellNamePrefix+"*"+BaseNameStr+"WSpikeFreq_Avg"+"_ip" //DataWaveMatchStr
		 AppendToGraphAnalParW[1]=DisplayWinName //GraphWinName
		 AppendToGraphAnalParW[2]="-1" // Append 1st N waves; -1 for all waves
		 AppendToGraphAnalParW[3]=""	//XWaveMatchStr	
			
		//For (i=0;i<NCond;i+=1)
			SetDataFolder StringFromList(i, ConditionFldrList, ";")
			col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
			If (col_id == -1)
				col_id = 0
			EndIf
			pt_Red 		= ColorLevel_RedVal[col_id]
			pt_Green 	= ColorLevel_GreenVal[col_id]
			pt_Blue 	= ColorLevel_BlueVal[col_id]
			 AppendToGraphAnalParW[4]=Num2Str(pt_Red)+";"+Num2Str(pt_Green)+";"+Num2Str(pt_Blue)+"; "//RGBList	
			pt_AppendWToGraph()
		//EndFor
		Duplicate /T/O AppendToGraphAnalParWOrig, AppendToGraphAnalParW
	EndIf
	//----
	
	
	//$$$###//DisplayWinName="AdaptR_Avg"
	//$$$###//DoWindow $DisplayWinName
	//$$$###//If (V_Flag)
	//$$$###//	DoWindow /F $DisplayWinName
	//$$$###//Else
	//$$$###//	Display
	//$$$###//	DoWindow /C $DisplayWinName
	//$$$###//Endif
	//$$$###//TraceNameStr1=GetDataFolder(0)+"AdaptR"	+"_Avg"	// tracename is just the name of the wave without the entire path
	//$$$###//TraceNameStr2=GetDataFolder(0)+"AdaptR"	+"_SE"
	//$$$###//AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+"AdaptR"+"_Avg"
	//$$$###//ErrorBars /W=$DisplayWinName $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
	//$$$###//Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
	//$$$###//ModifyGraph /W=$DisplayWinName fSize=14, mode = 4, marker = 19
	//$$$###//ModifyGraph 	/W=$DisplayWinName rgb($GetDataFolder(0)+"AdaptR"+"_Avg")=(pt_Red, pt_Green, pt_Blue)
	// display average data for vector pars
	For(j = 0; j < NSpkAnalVectorParList; j += 1)
		ParStr=StringFromList(j, SpkAnalVectorParList, ";")
		DisplayWinName= ParStr+"_Avg"
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		Endif
		For (k =0; k < VectorParNSpks; k +=1)
			TraceNameStr1=GetDataFolder(0)+"Spk"+Num2Str(k)+ParStr+"_Avg"	// tracename is just the name of the wave without the entire path
			TraceNameStr2=GetDataFolder(0)+"Spk"+Num2Str(k)+ParStr+"_SE"
			AppendToGraph /W=$DisplayWinName $GetDataFolder(0)+"Spk"+Num2Str(k)+ParStr+"_Avg"
			ErrorBars /W=$DisplayWinName $TraceNameStr1 Y,wave=($TraceNameStr2,$TraceNameStr2)
			Legend /W=$DisplayWinName /C/N=text0/F=0/A=RT
			ModifyGraph /W=$DisplayWinName fSize=14, mode = 4, marker = 19
			ModifyGraph 	/W=$DisplayWinName rgb($GetDataFolder(0)+"Spk"+Num2Str(k)+ParStr+"_Avg")=(pt_Red, pt_Green, pt_Blue)
		EndFor
	EndFor
	
EndFor

// // display all data for vector pars

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AppendWToGraph", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_AppendWToGraph", "ParW")
SaveNRestore("pt_AppendWToGraph", 1)

For(j = 0; j < NSpkAnalVectorParList; j += 1)
	For (k =0; k < VectorParNSpks; k +=1)
		ParStr=StringFromList(j, SpkAnalVectorParList, ";")
		DisplayWinName= ParStr+"_AllSpk"+Num2Str(k)
		DoWindow $DisplayWinName
		If (V_Flag)
			DoWindow /F $DisplayWinName
		Else
			Display
			DoWindow /C $DisplayWinName
		Endif
		AnalParW[0]=CellNamePrefix+"*Spk"+Num2Str(k)+BaseNameStr+ParStr+"W"
		AnalParW[1]=DisplayWinName
		AnalParW[2]="-1"
		AnalParW[3]=""
			
		For (i=0;i<NCond;i+=1)
			SetDataFolder StringFromList(i, ConditionFldrList, ";")
			col_id = pt_TextWSearch("root:AnalysisViewer:ColorLevelNamesW", GetDataFolder(0))
			If (col_id == -1)
				col_id = 0
			EndIf
			pt_Red 		= ColorLevel_RedVal[col_id]
			pt_Green 	= ColorLevel_GreenVal[col_id]
			pt_Blue 		= ColorLevel_BlueVal[col_id]
			AnalParW[4]=Num2Str(pt_Red)+";"+Num2Str(pt_Green)+";"+Num2Str(pt_Blue)+";"
			pt_AppendWToGraph()
		EndFor
	EndFor
EndFor
SaveNRestore("pt_AppendWToGraph", 2)

tileCommand= "TileWindows /O=1 /C"

Execute tileCommand
	
	
	
//*****************
End

Function pt_ZoomWin(ctrlName,popNum,popStr) : PopupMenuControl
	// make cellname waves & folders, and set pars for pt_MoveWavesMany  movewaves
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	
NVAR VectorParNSpks = root:AnalysisViewer:VectorParNSpks	
String tileCommand= "TileWindows /O=1 /C", AllWinsList, WinNameStr, Str
Variable N_AllWinsList, i, k

If (StringMatch(CtrlName, "PopupZoomWin"))		// Tile windows if zooming.
	AllWinsList = WinList("*_Display",";", "")
	N_AllWinsList = ItemsInList(AllWinsList, ";")
	For (i=0; i< N_AllWinsList; i+=1)
		WinNameStr = StringFromList(i, AllWinsList, ";")
		ModifyGraph /w = $WinNameStr width=0,height=0
	EndFor	
	Execute tileCommand
	//Return 0
EndIf
	WinNameStr = "None"
	StrSwitch (popStr)
		
		Case "FI":
			WinNameStr = "WSpikeFreq_Avg"
		Break
		
		Case "FI_All":
			WinNameStr = "WSpikeFreq_All"
		Break
		
		Case "FI_NormC":
			WinNameStr = "WSpikeFreqNCm_Avg"
		Break
		
		Case "FI_NormC_All":
			WinNameStr = "WSpikeFreqNCm_All"
		Break
		
		Case "FI_Inst":
			WinNameStr = "AvgIFrq_Avg"
		Break
		
		Case "FI_Inst_All":
			WinNameStr = "AvgIFrq_All"
		Break
		
		Case "Spk_train_AHP":
			WinNameStr = "EOPAHPY_Avg"
		Break
		
		Case "Spk_train_AHP_All":
			WinNameStr = "EOPAHPY_All"
		Break
		
		Case "Initial_Inst_Freq":
			WinNameStr = "IFrq_Avg"
		Break
		
		Case "Inter_stim_interval":
			WinNameStr = "ISI_Avg"
		Break
		
		Case "Ahp":
			WinNameStr = "AHPY_Avg"
		Break
		
		Case "Peak_Amp":
			WinNameStr = "PeakRelY_Avg"
		Break
		
		Case "Adaptation_ratio":
			WinNameStr = "AdaptR_Avg"
		Break
		
		Case "Fwhm":
			WinNameStr = "FWFracM_Avg"
		Break
		
		Case "VThresh":
			WinNameStr = "SpikeThreshY_Avg"
		Break
		
		Case "MaxDvDt":
			WinNameStr = "SpkMaxDvDtY_Avg"
		Break
		
		Case "T2FracPeak":
			WinNameStr = "TToFracPeakY_Avg"
		Break
		
		Case "Rs":
			WinNameStr = "RsV_Avg"
		Break
		
		Case "RIn":
			WinNameStr = "RInV_Avg"
		Break
		
		Case "Cm":
			WinNameStr = "CmV_Avg"
		Break
		
		Case "Rs_All":
			WinNameStr = "RsV_All"
		Break
		
		Case "RIn_All":
			WinNameStr = "RInV_All"
		Break
		
		Case "Cm_All":
			WinNameStr = "CmV_All"
		Break
		
		Default:
			WinNameStr = "None"	
	EndSwitch


	For (k =0; k < VectorParNSpks; k +=1)
		
		
		If (StringMatch(popStr, "Ahp_AllSpk" + Num2Str(k)))
			WinNameStr = "AHPY_AllSpk" + Num2Str(k)
			Break
		EndIf
		
		If (StringMatch(popStr, "Peak_Amp_AllSpk" + Num2Str(k)))
			WinNameStr = "PeakRelY_AllSpk" + Num2Str(k)
			Break
		EndIf
		
		If (StringMatch(popStr, "Fwhm_AllSpk" + Num2Str(k)))
			WinNameStr = "FWFracM_AllSpk" + Num2Str(k)
			Break
		EndIf
		
		If (StringMatch(popStr, "VThresh_AllSpk" + Num2Str(k)))
			WinNameStr = "SpikeThreshY_AllSpk" + Num2Str(k)
			Break
		EndIf
		
		If (StringMatch(popStr, "MaxDvDt_AllSpk" + Num2Str(k)))
			WinNameStr = "SpkMaxDvDtY_AllSpk" + Num2Str(k)
			Break
		EndIf
		
		If (StringMatch(popStr, "T2FracPeak_AllSpk" + Num2Str(k)))
			WinNameStr = "TToFracPeakY_AllSpk" + Num2Str(k)
			Break
		EndIf
		
		If (StringMatch(popStr, "Initial_Inst_Freq_AllSpk" + Num2Str(k)))
			WinNameStr = "IFrq_AllSpk" + Num2Str(k)
			Break
		EndIf
		
		If (StringMatch(popStr, "Inter_stim_interval_AllSpk" + Num2Str(k)))
			WinNameStr = "ISI_AllSpk" + Num2Str(k)
			Break
		EndIf

	EndFor	




If (!StringMatch(WinNameStr, "None"))

	StrSwitch (ctrlName)
		
		Case "PopupZoomWin":
			DoWindow $WinNameStr
			If (V_Flag)
				DoWindow /F $WinNameStr
				//ModifyGraph /w = $popStr width=640,height=400
				MoveWindow /w = $WinNameStr 0, 0, 640, 400
			EndIf
			Break
		
		Case "PopupEditData":
			pt_EditGraphWaves(WinNameStr)
			Break
		
		Default:
	
	EndSwitch
	
EndIf
End

Function pt_SaveFIAnal(ctrlName) : ButtonControl
String ctrlName
// aim - to export analysis for further processing through other software.
// copy the data from root:Data:Cell* folders to "root:ExportAnalysis:.
// logic- for all cell names in the database, find folder in root:Data and add values of specified waves to the ExportAnalysis.
// How do we deal with parameters which are many values for one cell (eg. FI curves) or may even have 2 independent pars
// eg. spike-width as function of current and freq. Depends on how we plan to analyze these subsequently. For now we 
// will convert them to a single value per cell. Eg. FI curve can be repesented by slope, threshold, saturation value.
// spikewidth etc - will be measured for 1st few spikes (spike0, spike1, etc.) and for spike width belonging to a given 
// spike as function of current can be represented by threshold, slope, etc.

//	Partly inspired from pt_AnalWInFldrs2

/////String AnalFunc
SVAR ParentDataFolder=root:ParentDataFolder
SVAR List_Anova = root:AnalysisViewer:List_Anova
String ParName, OutWName, WStr, WNameWPath, BaseNameStr
//ParListStr += "RsAvg;RInAvg;CmAvg;FIPeakAbsXF;FI_CurrTh;FI_Slope;FIFreq500pA;FIFreq1000pA;FIPeakRelYF:Spk1PkAmp500pA;FIPeakRelYF:Spk1PkAmp1000pA"//FIAdaptR700pA;"	// partial path

// No user input needed for following so not included in ExportAnalysisFIPars
String ScalarParList = "RsAvg;RInAvg;CmAvg;FI_CurrTh;FI_Slope;FI_CurrAtMaxFreq;FI_MaxFreq;" 
// "RsVAvg;RInVAvg;CmVAvg;FI_CurrTh; FI_CurrSlope"

Variable NumCells, NumPars, i, j, NumAnovaFactors, PntNum, ParFound
String OldDF, CurrFldrName, WName

String LastUpdatedMM_DD_YYYY=" 07/29/2014"

Print "*********************************************************"
Print "pt_SaveFIAnal last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


//****

// the par name wave will have the name of the pars and the par value will have the point number to be extracted.  OutParNames will be the name of exported wave.
// example - for spike freq we want to extract spike freq at 500 pA. then the point number will be 5 (with current start val = 0 and step value = 100 pA). And the output
// name could be SpkFreq500pA.

Wave /T ParNamesW		=$pt_GetParWave("pt_SaveFIAnal", "ParNamesW")
Wave /T ParW			=$pt_GetParWave("pt_SaveFIAnal", "ParW")
Wave /T OutNamesW	=$pt_GetParWave("pt_SaveFIAnal", "OutNamesW")

If (WaveExists(ParNamesW)&&WaveExists(ParW)&&WaveExists(OutNamesW) == 0)
	Abort	"Cudn't find the parameter waves pt_SaveFIAnalParW and/or pt_SaveFIAnalParNamesW and/or pt_SaveFIAnalOutNamesW!!!"
EndIf

Wave /T NthPParNamesW	=	$pt_GetParWave("pt_NthPntWave","ParNamesW")
Wave /T NthPParW		=	$pt_GetParWave("pt_NthPntWave","ParW")


SaveNRestore("pt_NthPntWave", 1)
NthPParW[3]	=	""//WList

NumPars = NumPnts(ParW)
//ParList = ""
//OutParNameList = ""

OldDF=GetDataFolder(1)
SetDataFolder root:
Make /O/N=1 WTmp

DoWindow pt_EditAllAnalPars
If (V_Flag)
	DoWindow /K pt_EditAllAnalPars
EndIf
Edit 
DoWindow /C pt_EditAllAnalPars

Wave /T CellName = root:CellName
Wave /T HDDataFldrPathW = root:HDDataFldrPathW

// append cellname wave and path
AppendToTable /W = pt_EditAllAnalPars CellName, HDDataFldrPathW
NumCells = NumPnts(CellName)

// data folder to save all appended waves
If (!DataFolderExists("root:ExportAnalysis"))
	NewDataFolder root:ExportAnalysis
EndIf

// append all anova waves
NumAnovaFactors = ItemsInList(List_Anova, ";")
For (i = 0; i< NumAnovaFactors; i += 1)
	WStr = StringFromList(i, List_Anova, ";")
	If (WaveExists($"root:AnalysisViewer:"+WStr))
		AppendToTable /W =  pt_EditAllAnalPars $"root:AnalysisViewer:"+WStr
	Else 
		DoAlert 0, "Wave"+ WStr+ "does not exist."	
	EndIf
EndFor

Wave /T FIAnalParNamesW	=	$pt_GetParWave("pt_SpikeAnal", "ParNamesW")		
Wave /T FIAnalParW			=	$pt_GetParWave("pt_SpikeAnal", "ParW")
BaseNameStr = FIAnalParW[14]
Print "BaseNameStr=",BaseNameStr



For (j = 0; j < NumPars; j +=1)

	ParName = ParNamesW[j]
	PntNum = Str2Num(ParW[j])
	OutWName= OutNamesW[j]
	
	If (StringMatch(OutWName, BaseNameStr+"*") ==1)
		Abort "Can't start the OutName with BaseNameStr = " + BaseNameStr
	EndIf

	ParFound = 0
	StrSwitch (ParName)
	
		Case "AvgFreq":
			ParFound = 1
			
			
			NthPParW[0]	= 	BaseNameStr+"WSpikeFreq_Avg"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName	//DestWName
			NthPParW[4]	=	""			//SubFldrList
			
			WNameWPath = OutWName
					
		Break

		Case "InstFreq":
			ParFound = 1
			
			
			NthPParW[0]	= 	BaseNameStr+"AvgIFrq_Avg"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName	//DestWName
			NthPParW[4]	=	BaseNameStr+"IFrqF:"			//SubFldrList
			
			WNameWPath = BaseNameStr+"IFrqF:"+OutWName
					
		Break
		
		Case "Spk_train_AHP":
			ParFound = 1
			
			
			NthPParW[0]	= 	BaseNameStr+"EOPAHPY_Avg"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName	//DestWName
			NthPParW[4]	=	""			//SubFldrList
			
			WNameWPath = ""+OutWName
					
		Break
		
		Case "Adaptation_ratio":
			ParFound = 1
			
			NthPParW[0]	= 	BaseNameStr+"AdaptR_avg"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	 BaseNameStr+"ISIF:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"ISIF:"+OutWName
					
		Break
		
		//Initial_Inst_Freq_Spk
		Case "Initial_Inst_Freq_Spk0":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk0"+BaseNameStr+"IFrq"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"IFrq"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"IFrq"+"F:"+OutWName
					
		Break
		
		Case "Initial_Inst_Freq_Spk1":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk1"+BaseNameStr+"IFrq"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"IFrq"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"IFrq"+"F:"+OutWName
					
		Break
		
		Case "Initial_Inst_Freq_Spk2":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk2"+BaseNameStr+"IFrq"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"IFrq"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"IFrq"+"F:"+OutWName
					
		Break
		
		Case "Initial_Inst_Freq_Spk3":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk3"+BaseNameStr+"IFrq"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"IFrq"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"IFrq"+"F:"+OutWName
					
		Break
		
		//Ahp_Spk
		Case "Ahp_Spk0":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk0"+BaseNameStr+"AHPY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"AHPY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"AHPY"+"F:"+OutWName
					
		Break
		
		Case "Ahp_Spk1":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk1"+BaseNameStr+"AHPY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"AHPY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"AHPY"+"F:"+OutWName
					
		Break
		
		Case "Ahp_Spk2":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk2"+BaseNameStr+"AHPY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"AHPY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"AHPY"+"F:"+OutWName
					
		Break
		
		Case "Ahp_Spk3":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk3"+BaseNameStr+"AHPY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"AHPY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"AHPY"+"F:"+OutWName
					
		Break
		
		//PeakAmp_Spk
		Case "PeakAmp_Spk0":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk0"+BaseNameStr+"PeakRelY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"PeakRelY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"PeakRelY"+"F:"+OutWName
					
		Break
		
		Case "PeakAmp_Spk1":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk1"+BaseNameStr+"PeakRelY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"PeakRelY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"PeakRelY"+"F:"+OutWName
					
		Break
		
		Case "PeakAmp_Spk2":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk2"+BaseNameStr+"PeakRelY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"PeakRelY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"PeakRelY"+"F:"+OutWName
					
		Break
		
		Case "PeakAmp_Spk3":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk3"+BaseNameStr+"PeakRelY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"PeakRelY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"PeakRelY"+"F:"+OutWName
					
		Break
		
		//Fwhm_Spk
		Case "Fwhm_Spk0":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk0"+BaseNameStr+"FWFracM"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"FWFracM"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"FWFracM"+"F:"+OutWName
					
		Break
		
		Case "Fwhm_Spk1":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk1"+BaseNameStr+"FWFracM"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"FWFracM"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"FWFracM"+"F:"+OutWName
					
		Break
		
		Case "Fwhm_Spk2":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk2"+BaseNameStr+"FWFracM"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"FWFracM"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"FWFracM"+"F:"+OutWName
					
		Break
		
		Case "Fwhm_Spk3":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk3"+BaseNameStr+"FWFracM"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"FWFracM"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"FWFracM"+"F:"+OutWName
					
		Break
		
		//VThresh_Spk
		Case "VThresh_Spk0":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk0"+BaseNameStr+"SpikeThreshY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"SpikeThreshY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"SpikeThreshY"+"F:"+OutWName
					
		Break
		
		Case "VThresh_Spk1":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk1"+BaseNameStr+"SpikeThreshY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"SpikeThreshY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"SpikeThreshY"+"F:"+OutWName
					
		Break
	
		Case "VThresh_Spk2":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk2"+BaseNameStr+"SpikeThreshY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"SpikeThreshY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"SpikeThreshY"+"F:"+OutWName
					
		Break
		
		Case "VThresh_Spk3":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk3"+BaseNameStr+"SpikeThreshY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"SpikeThreshY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"SpikeThreshY"+"F:"+OutWName
					
		Break
		
		//MaxDvDt_Spk
		Case "MaxDvDt_Spk0":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk0"+BaseNameStr+"SpkMaxDvDtY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"SpkMaxDvDtY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"SpkMaxDvDtY"+"F:"+OutWName
					
		Break
		
		Case "MaxDvDt_Spk1":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk1"+BaseNameStr+"SpkMaxDvDtY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"SpkMaxDvDtY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"SpkMaxDvDtY"+"F:"+OutWName
					
		Break
		
		Case "MaxDvDt_Spk2":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk2"+BaseNameStr+"SpkMaxDvDtY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"SpkMaxDvDtY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"SpkMaxDvDtY"+"F:"+OutWName
					
		Break
		
		Case "MaxDvDt_Spk3":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk3"+BaseNameStr+"SpkMaxDvDtY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"SpkMaxDvDtY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"SpkMaxDvDtY"+"F:"+OutWName
					
		Break
		
		//T2FracPeak_Spk
		Case "T2FracPeak_Spk0":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk0"+BaseNameStr+"TToFracPeakY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"TToFracPeakY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"TToFracPeakY"+"F:"+OutWName
					
		Break
		
		Case "T2FracPeak_Spk1":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk1"+BaseNameStr+"TToFracPeakY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"TToFracPeakY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"TToFracPeakY"+"F:"+OutWName
					
		Break
		
		Case "T2FracPeak_Spk2":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk2"+BaseNameStr+"TToFracPeakY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"TToFracPeakY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"TToFracPeakY"+"F:"+OutWName
					
		Break
		
		Case "T2FracPeak_Spk3":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk3"+BaseNameStr+"TToFracPeakY"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"TToFracPeakY"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"TToFracPeakY"+"F:"+OutWName
					
		Break
		
		//"ISI_Spk"
		Case "ISI_Spk0":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk0"+BaseNameStr+"ISI"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"ISI"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"ISI"+"F:"+OutWName
					
		Break
		
		Case "ISI_Spk1":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk1"+BaseNameStr+"ISI"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"ISI"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"ISI"+"F:"+OutWName
					
		Break
		
		Case "ISI_Spk2":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk2"+BaseNameStr+"ISI"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"ISI"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"ISI"+"F:"+OutWName
					
		Break
		
		Case "ISI_Spk3":
			ParFound = 1
			
			
			NthPParW[0]	= 	"Spk3"+BaseNameStr+"ISI"+"W"	//DataWaveMatchStr
			NthPParW[1]	=	Num2Str(PntNum)				//PntNum
			NthPParW[2]	=	OutWName						//DestWName
			NthPParW[4]	=	BaseNameStr+"ISI"+"F:"		//SubFldrList
			
			WNameWPath = BaseNameStr+"ISI"+"F:"+OutWName
					
		Break
		

		Default:
			ParFound = 0
	EndSwitch
	
	//If (!WaveExists( $("root:ExportAnalysis:"+StringFromList(j, ParListStr, ";") ) ) )
	//WName = ParseFilePath(0, StringFromList(j, ParListStr, ";"), ":", 1, 0)
	If (ParFound == 1)
	Make /O/N=(NumCells) $("root:ExportAnalysis:"+ OutWName) // last part of partial path
	Wave w = $("root:ExportAnalysis:"+ OutWName)
	w = NaN
	Print "Analyzing paramter", ParName//StringFromList(j, ParListStr, ";")
	//EndIf
	For (i = 0; i<NumCells; i+=1)
		CurrFldrName=ParentDataFolder+":"+CellName[i]
		If (!DataFolderExists(CurrFldrName))	// data folders created if not existing (praveen 04/29/2008)
			NewDataFolder /s $CurrFldrName
			Print "Created Data Folder", CurrFldrName
		EndIf
		SetDataFolder $CurrFldrName
		pt_NthPntWave()
		
		//If (!WaveExists($(CurrFldrName + ":"+StringFromList(j, ParListStr, ";") ) ) )

		If (!WaveExists($(CurrFldrName + ":"+ WNameWPath ) ) )
			//WTmp = NaN
			w[i] = NaN
		Else
			Wave w1 = $(CurrFldrName + ":"+ WNameWPath ) 
			//WTmp = w1[0]
			w[i] = w1[0]
		EndIf
		
		//Concatenate /NP {wTmp}, w
	EndFor
	AppendToTable /W = pt_EditAllAnalPars w
	EndIf // ParFound
EndFor
SaveNRestore("pt_NthPntWave", 2)

// Also append scalar pars (only one value per FI curve) 
// ScalarParList = "RsVAvg;RInVAvg;CmVAvg;FI_CurrTh;FI_CurrSlope;" + BaseNameStr+"AdaptR;"

NumPars = ItemsInList(ScalarParList)

For (j = 0; j < NumPars; j +=1)
	//If (!WaveExists( $("root:ExportAnalysis:"+StringFromList(j, ScalarParList, ";") ) ) )
	WName = ParseFilePath(0, StringFromList(j, ScalarParList, ";"), ":", 1, 0)
	Make /O/N=(NumCells) $("root:ExportAnalysis:"+ WName) // last part of partial path
	Wave w = $("root:ExportAnalysis:"+ WName)
	w = NaN
	Print "Analyzing paramter", StringFromList(j, ScalarParList, ";")
	//EndIf
	For (i = 0; i<NumCells; i+=1)
		CurrFldrName=ParentDataFolder+":"+CellName[i]
		If (!DataFolderExists(CurrFldrName))	// data folders created if not existing (praveen 04/29/2008)
			NewDataFolder /s $CurrFldrName
			Print "Created Data Folder", CurrFldrName
		EndIf
		If (!WaveExists($(CurrFldrName + ":"+StringFromList(j, ScalarParList, ";") ) ) )
			//WTmp = NaN
			w[i] = NaN
		Else
			Wave w1 = $(CurrFldrName + ":"+StringFromList(j, ScalarParList, ";") )
			//WTmp = w1[0]
			w[i] = w1[0]
		EndIf
		//Concatenate /NP {wTmp}, w
	EndFor
	AppendToTable /W = pt_EditAllAnalPars w
EndFor
		
SetDataFolder OldDF
/////Print "Analysis", AnalFunc, "over!"
End

Function pt_SaveFIVectAnal(ctrlName) : ButtonControl
String ctrlName

// modified to export min-max range (approx linear part of FI curve).
// modified from pt_SaveFIAnal(ctrlName) and pt_ExportAnalysisPSC()
// pt_SaveFIAnal exports scalar data for a given current. pt_SaveFIVectAnal will export data as a function of current 


// comments from pt_SaveFIAnal(ctrlName)
// aim - to export analysis for further processing through other software.
// copy the data from root:Data:Cell* folders to "root:ExportAnalysis:.
// logic- for all cell names in the database, find folder in root:Data and add values of specified waves to the ExportAnalysis.
// How do we deal with parameters which are many values for one cell (eg. FI curves) or may even have 2 independent pars
// eg. spike-width as function of current and freq. Depends on how we plan to analyze these subsequently. For now we 
// will convert them to a single value per cell. Eg. FI curve can be repesented by slope, threshold, saturation value.
// spikewidth etc - will be measured for 1st few spikes (spike0, spike1, etc.) and for spike width belonging to a given 
// spike as function of current can be represented by threshold, slope, etc.

//	Partly inspired from pt_AnalWInFldrs2

/////String AnalFunc
SVAR ParentDataFolder=root:ParentDataFolder
SVAR ParentHDDataFolder=root:ParentHDDataFolder

SVAR List_Anova = root:AnalysisViewer:List_Anova
String ParName, OutWName, WStr, WNameWPath, BaseNameStr
//ParListStr += "RsAvg;RInAvg;CmAvg;FIPeakAbsXF;FI_CurrTh;FI_Slope;FIFreq500pA;FIFreq1000pA;FIPeakRelYF:Spk1PkAmp500pA;FIPeakRelYF:Spk1PkAmp1000pA"//FIAdaptR700pA;"	// partial path


//String ScalarParList = "RsAvg;RInAvg;CmAvg;FI_CurrTh;FI_Slope;"
//String ScalarParList = "RsAvg;RInAvg;CmAvg;" 
Variable RangeMinMax
Variable ParWMinMax_NPnts
String VectParList = ""
String VectOutParNames = ""

Variable NumCells, NumPars, i, j, NumAnovaFactors, PntNum, ParFound, StartX, EndX
Variable StartPnt, EndPnt, CurrwOffset, CurrwDelta
String OldDF, CurrFldrName, WName
String LastUpdatedMM_DD_YYYY=" 10/09/2014"

 
// "RsVAvg;RInVAvg;CmVAvg;FI_CurrTh; FI_CurrSlope"

Print "*********************************************************"
Print "pt_SaveFIVectAnal last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"
//****

Wave /T SaveAnalParNamesW	=$pt_GetParWave("pt_SaveFIVectAnal", "ParNamesW")
Wave /T SaveAnalParW			=$pt_GetParWave("pt_SaveFIVectAnal", "ParW")

If (WaveExists(SaveAnalParW)&&WaveExists(SaveAnalParNamesW) == 0)
	Abort	"Cudn't find the parameter waves pt_SaveFIVectAnalParW and/or pt_SaveFIVectAnalParNamesW!!"
EndIf

RangeMinMax = Str2Num(SaveAnalParW[0])	// export range between min and max value of FI frequency (to get linear portion of curve)  //12/19/14
//ParList = ""
//OutParNameList = ""

OldDF=GetDataFolder(1)
SetDataFolder root:

DoWindow pt_EditAllAnalPars
If (V_Flag)
	DoWindow /K pt_EditAllAnalPars
EndIf
Edit 
DoWindow /C pt_EditAllAnalPars

Wave /T CellName = root:CellName
Wave /T HDDataFldrPathW = root:HDDataFldrPathW

// append cellname wave and path
AppendToTable /W = pt_EditAllAnalPars CellName, HDDataFldrPathW
NumCells = NumPnts(CellName)

// data folder to save all appended waves
If (!DataFolderExists("root:ExportVectAnal"))
	NewDataFolder root:ExportVectAnal
EndIf

// append all anova waves
NumAnovaFactors = ItemsInList(List_Anova, ";")
For (i = 0; i< NumAnovaFactors; i += 1)
	WStr = StringFromList(i, List_Anova, ";")
	If (WaveExists($"root:AnalysisViewer:"+WStr))
		AppendToTable /W =  pt_EditAllAnalPars $"root:AnalysisViewer:"+WStr
	Else 
		DoAlert 0, "Wave"+ WStr+ "does not exist."	
	EndIf
EndFor

SaveTableCopy /O/T = 2 /W = pt_EditAllAnalPars as ParentHDDataFolder + "FI_ScalarPars.csv"
KillWindow pt_EditAllAnalPars

Wave /T FIAnalParNamesW	=	$pt_GetParWave("pt_SpikeAnal", "ParNamesW")		
Wave /T FIAnalParW			=	$pt_GetParWave("pt_SpikeAnal", "ParW")
BaseNameStr = FIAnalParW[14]
Print "BaseNameStr=",BaseNameStr

VectParList += "RsV_Avg;"
VectOutParNames += "RsAvg;"

VectParList += "RInV_Avg;"
VectOutParNames += "RInAvg;"

VectParList += "CmV_Avg;"
VectOutParNames += "CmAvg;"

VectParList += BaseNameStr+"WSpikeFreq_Avg;"
VectOutParNames += "AvgFreq;"

VectParList += BaseNameStr+"IFrqF:" + BaseNameStr+"AvgIFrq_Avg;"
VectOutParNames += "InstFreq;"

VectParList += BaseNameStr+"EOPAHPY_Avg;"
VectOutParNames += "SpkTrainAhp;"

VectParList += BaseNameStr+"ISIF:" + BaseNameStr+"AdaptR_avg;"
VectOutParNames += "AdaptR;"

VectParList += BaseNameStr+"IFrqF:" + "Spk0"+BaseNameStr+"IFrqW;"
VectOutParNames += "InstFreq_0Spk;"

VectParList += BaseNameStr+"IFrqF:" + "Spk1"+BaseNameStr+"IFrqW;"
VectOutParNames += "InstFreq_1Spk;"

VectParList += BaseNameStr+"IFrqF:" + "Spk2"+BaseNameStr+"IFrqW;"
VectOutParNames += "InstFreq_2Spk;"

VectParList += BaseNameStr+"IFrqF:" + "Spk3"+BaseNameStr+"IFrqW;"
VectOutParNames += "InstFreq_3Spk;"

VectParList += BaseNameStr+"AHPYF:" + "Spk0"+BaseNameStr+"AHPYW;"
VectOutParNames += "Ahp_0Spk;"

VectParList += BaseNameStr+"AHPYF:" + "Spk1"+BaseNameStr+"AHPYW;"
VectOutParNames += "Ahp_1Spk;"

VectParList += BaseNameStr+"AHPYF:" + "Spk2"+BaseNameStr+"AHPYW;"
VectOutParNames += "Ahp_2Spk;"

VectParList += BaseNameStr+"AHPYF:" + "Spk3"+BaseNameStr+"AHPYW;"
VectOutParNames += "Ahp_3Spk;"

VectParList += BaseNameStr+"PeakRelYF:" + "Spk0"+BaseNameStr+"PeakRelYW;"
VectOutParNames += "PeakAmp_0Spk;"

VectParList += BaseNameStr+"PeakRelYF:" + "Spk1"+BaseNameStr+"PeakRelYW;"
VectOutParNames += "PeakAmp_1Spk;"

VectParList += BaseNameStr+"PeakRelYF:" + "Spk2"+BaseNameStr+"PeakRelYW;"
VectOutParNames += "PeakAmp_2Spk;"

VectParList += BaseNameStr+"PeakRelYF:" + "Spk3"+BaseNameStr+"PeakRelYW;"
VectOutParNames += "PeakAmp_3Spk;"

VectParList += BaseNameStr+"FWFracMF:" + "Spk0"+BaseNameStr+"FWFracMW;"
VectOutParNames += "Fwhm_0Spk;"

VectParList += BaseNameStr+"FWFracMF:" + "Spk1"+BaseNameStr+"FWFracMW;"
VectOutParNames += "Fwhm_1Spk;"

VectParList += BaseNameStr+"FWFracMF:" + "Spk2"+BaseNameStr+"FWFracMW;"
VectOutParNames += "Fwhm_2Spk;"

VectParList += BaseNameStr+"FWFracMF:" + "Spk3"+BaseNameStr+"FWFracMW;"
VectOutParNames += "Fwhm_3Spk;"

VectParList += BaseNameStr+"SpikeThreshYF:" + "Spk0"+BaseNameStr+"SpikeThreshYW;"
VectOutParNames += "VThresh_0Spk;"

VectParList += BaseNameStr+"SpikeThreshYF:" + "Spk1"+BaseNameStr+"SpikeThreshYW;"
VectOutParNames += "VThresh_1Spk;"

VectParList += BaseNameStr+"SpikeThreshYF:" + "Spk2"+BaseNameStr+"SpikeThreshYW;"
VectOutParNames += "VThresh_2Spk;"

VectParList += BaseNameStr+"SpikeThreshYF:" + "Spk3"+BaseNameStr+"SpikeThreshYW;"
VectOutParNames += "VThresh_3Spk;"

VectParList += BaseNameStr+"SpkMaxDvDtYF:" + "Spk0"+BaseNameStr+"SpkMaxDvDtYW;"
VectOutParNames += "MaxDvDt_0Spk;"

VectParList += BaseNameStr+"SpkMaxDvDtYF:" + "Spk1"+BaseNameStr+"SpkMaxDvDtYW;"
VectOutParNames += "MaxDvDt_1Spk;"

VectParList += BaseNameStr+"SpkMaxDvDtYF:" + "Spk2"+BaseNameStr+"SpkMaxDvDtYW;"
VectOutParNames += "MaxDvDt_2Spk;"

VectParList += BaseNameStr+"SpkMaxDvDtYF:" + "Spk3"+BaseNameStr+"SpkMaxDvDtYW;"
VectOutParNames += "MaxDvDt_3Spk;"

NumPars = ItemsInList(VectParList, ";")

StartX = -inf
EndX = + inf

For (j = 0; j < NumPars; j +=1)

	ParName = StringFromList(j, VectParList, ";")
	OutWName = StringFromList(j, VectOutParNames, ";")
	Edit
	DoWindow /C $(OutWName + "_ExportFI")

	Print "Exporting paramter", ParName, "to", ParentHDDataFolder//StringFromList(j, ParListStr, ";")

	For (i = 0; i<NumCells; i+=1)
		CurrFldrName=ParentDataFolder+":"+CellName[i]
		//If (!DataFolderExists(CurrFldrName))	// data folders created if not existing (praveen 04/29/2008)
		//	NewDataFolder /s $CurrFldrName
		//	Print "Created Data Folder", CurrFldrName
		//EndIf
		//SetDataFolder $CurrFldrName
		If (WaveExists($(CurrFldrName + ":" + ParName)))
			//print CurrFldrName + ":" + ParName, "root:ExportVectAnal:" + CellName[i] + OutWName
			//WName = ParseFilePath(0, ParName, ":", 1, 0)
			
			If (RangeMinMax == 1)	//12/19/14
				Wave FICurrTh = $(CurrFldrName + ":" + "FI_CurrTh")
				Wave FI_CurrAtMaxFreq = $(CurrFldrName + ":" + "FI_CurrAtMaxFreq")
				StartX = FICurrTh[0]
				EndX = FI_CurrAtMaxFreq[0]
				// convert to point value
				Wave Currw = $(CurrFldrName + ":" + "CurrW_Avg")
				
				CurrwOffset = Currw[0]
				CurrwDelta = Currw[1] - Currw[0] 
				StartPnt = Ceil((StartX - CurrwOffset)/CurrwDelta) // this was calculated as 0.5*(Curr at zero freq + Curr at non-zero freq) 
				EndPnt = Round((EndX - CurrwOffset)/CurrwDelta) // 
				
//				Findlevel /P/Q Currw, StartX
	//			If (V_Flag ==0)
	//				StartPnt = V_LevelX//Ceil(x2pnt(Currw, StartX))
	//			EndPnt = Ceil(x2pnt(Currw, EndX))
				//print Currw  
				If (j == NumPars -1) // print only first time for a cell. For last parameter so it is easily seen,
					print CellName[i]
					print "FICurrTh, Start index = ", StartX, StartPnt
					print "FI_CurrAtMaxFreq, End index", EndX, EndPnt
				EndIf
			EndIf
			Duplicate /O $(CurrFldrName + ":" + ParName), $("root:ExportVectAnal:" + CellName[i] + OutWName) //12/19/14
			Wave ParWMinMax = $("root:ExportVectAnal:" + CellName[i] + OutWName)
			// Set values outside RangeMinMax = Nan
			If (RangeMinMax == 1)	//12/19/14
				ParWMinMax_NPnts = NumPnts(ParWMinMax)
				If ((StartPnt -1) >= 0) // else 1st point is still set = NaN
					ParWMinMax[ , StartPnt - 1] = Nan
				EndIf
				If ((EndPnt + 1) < (ParWMinMax_NPnts)) // else last point is still set = NaN
					ParWMinMax[EndPnt + 1, ] = Nan
				EndIf
				//AppendToTable /W = $(OutWName + "_ExportFI")  $("root:ExportVectAnal:" + CellName[i] + OutWName) 01/16/15
			EndIf
			AppendToTable /W = $(OutWName + "_ExportFI")  $("root:ExportVectAnal:" + CellName[i] + OutWName)
		Else
			Print "Warning! Wave doesn't exist" + CurrFldrName + ":" + ParName
		EndIf
	EndFor
	SaveTableCopy /O/T = 2/W = $(OutWName + "_ExportFI") as ParentHDDataFolder+OutWName + ".csv"
	KillWindow $(OutWName + "_ExportFI")
	//KillWaves $("root:ExportVectAnal:" + GetDataFolder(0) + ParName)
EndFor
KillDataFolder root:ExportVectAnal
SetDataFolder OldDF
/////Print "Analysis", AnalFunc, "over!"
End


////+++++//////
Function pt_ExportAnalysisPSC(ctrlName) : ButtonControl
String ctrlName

// inspired from  pt_SaveFIAnal
// aim - to export analysis for further processing through other software.
// copy the data from root:Data:Cell* folders to "root:ExportAnalysis:.
// logic- for all cell names in the database, find folder in root:Data and add values of specified waves to the ExportAnalysis.

//	Partly inspired from pt_AnalWInFldrs2

/////String AnalFunc
SVAR ParentDataFolder=root:ParentDataFolder
SVAR List_Anova = root:AnalysisViewer:List_Anova
String ParName, OutWName, WStr, WNameWPath, BaseNameStr
//ParListStr += "RsAvg;RInAvg;CmAvg;FIPeakAbsXF;FI_CurrTh;FI_Slope;FIFreq500pA;FIFreq1000pA;FIPeakRelYF:Spk1PkAmp500pA;FIPeakRelYF:Spk1PkAmp1000pA"//FIAdaptR700pA;"	// partial path

// No user input needed for following so not included in ExportAnalysisFIPars
String ScalarParList="PkAmpRelWAvg;FreqPksWAvg;DecayTWAvg;RiseTWAvg;RsVAvg;RInVAvg;CmVAvg;"
String ScalarOutParNames="PeakAmp;PeakFreq;DecayTau;RiseT;Rs;RIn;Cm"
// "RsVAvg;RInVAvg;CmVAvg;FI_CurrTh; FI_CurrSlope"

Variable NumCells, NumPars, i, j, NumAnovaFactors//, PntNum, ParFound
String OldDF, CurrFldrName, WName

String LastUpdatedMM_DD_YYYY=" 09/17/2014"

Print "*********************************************************"
Print "pt_ExportAnalysisPSC last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"
//****

OldDF=GetDataFolder(1)
SetDataFolder root:
Make /O/N=1 WTmp

DoWindow pt_EditAllAnalPars
If (V_Flag)
	DoWindow /K pt_EditAllAnalPars
EndIf
Edit 
DoWindow /C pt_EditAllAnalPars

Wave /T CellName = root:CellName

// append cellname wave and path
AppendToTable /W = pt_EditAllAnalPars CellName, HDDataFldrPathW
NumCells = NumPnts(CellName)

// data folder to save all appended waves
If (!DataFolderExists("root:ExportAnalysis"))
	NewDataFolder root:ExportAnalysis
EndIf

// append all anova waves
NumAnovaFactors = ItemsInList(List_Anova, ";")
For (i = 0; i< NumAnovaFactors; i += 1)
	WStr = StringFromList(i, List_Anova, ";")
	If (WaveExists($"root:AnalysisViewer:"+WStr))
		AppendToTable /W =  pt_EditAllAnalPars $"root:AnalysisViewer:"+WStr
	Else 
		DoAlert 0, "Wave"+ WStr+ "does not exist."	
	EndIf
EndFor

Wave /T PeakAnalParNamesW		=	$pt_GetParWave("pt_PeakAnal", "ParNamesW")		
Wave /T PeakAnalParW			=	$pt_GetParWave("pt_PeakAnal", "ParW")
BaseNameStr = PeakAnalParW[16]
Print "BaseNameStr=",BaseNameStr


// Also append scalar pars (only one value per FI curve) 
// ScalarParList = "RsVAvg;RInVAvg;CmVAvg;FI_CurrTh;FI_CurrSlope;" + BaseNameStr+"AdaptR;"
NumPars = ItemsInList(ScalarParList)

For (j = 0; j < NumPars; j +=1)
	//If (!WaveExists( $("root:ExportAnalysis:"+StringFromList(j, ScalarParList, ";") ) ) )
	//WName = ParseFilePath(0, StringFromList(j, ScalarParList, ";"), ":", 1, 0)
	WName = StringFromList(j, ScalarOutParNames, ";")
	Make /O/N=(NumCells) $("root:ExportAnalysis:"+ WName) // last part of partial path
	Wave w = $("root:ExportAnalysis:"+ WName)
	w = NaN
	Print "Analyzing paramter", StringFromList(j, ScalarParList, ";")
	//EndIf
	For (i = 0; i<NumCells; i+=1)
		CurrFldrName=ParentDataFolder+":"+CellName[i]
		If (!DataFolderExists(CurrFldrName))	// data folders created if not existing (praveen 04/29/2008)
			NewDataFolder /s $CurrFldrName
			Print "Created Data Folder", CurrFldrName
		EndIf
		If (!WaveExists($(CurrFldrName + ":"+StringFromList(j, ScalarParList, ";") ) ) )
			//WTmp = NaN
			w[i] = NaN
		Else
			Wave w1 = $(CurrFldrName + ":"+StringFromList(j, ScalarParList, ";") )
			//WTmp = w1[0]
			w[i] = w1[0]
		EndIf
		//Concatenate /NP {wTmp}, w
	EndFor
	AppendToTable /W = pt_EditAllAnalPars w
EndFor

KillWaves /Z WTmp		
SetDataFolder OldDF
/////Print "Analysis", AnalFunc, "over!"
End
////+++++//////

Function pt_PSCZoomWin(ctrlName,popNum,popStr) : PopupMenuControl
	// based on pt_PSCZoomWin
	// make cellname waves & folders, and set pars for pt_MoveWavesMany  movewaves
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	
	
String tileCommand= "TileWindows /O=1 /C", AllWinsList, WinNameStr
Variable N_AllWinsList, i

If (StringMatch(CtrlName, "PopupPSCZoomWin"))		// Tile windows if zooming.
	AllWinsList = WinList("*_Display",";", "")
	N_AllWinsList = ItemsInList(AllWinsList, ";")
	For (i=0; i< N_AllWinsList; i+=1)
		WinNameStr = StringFromList(i, AllWinsList, ";")
		ModifyGraph /w = $WinNameStr width=0,height=0
	EndFor	
	Execute tileCommand
	//Return 0
EndIf
	StrSwitch (popStr)
		
		Case "Freq_Avg":
			WinNameStr = "FreqPksW"
		Break
		
		Case "Freq_Avg_All":
			WinNameStr = "FreqPksWDisplay"
		Break
		
		Case "PeakAmp_Avg":
			WinNameStr = "PkAmpRelW"
		Break
		
		Case "PeakAmp_Avg_All":
			WinNameStr = "PkAmpRelWDisplay"
		Break
		
		Case "DecayTau_Avg":
			WinNameStr = "DecayT"
		Break
		
		Case "DecayTau_Avg_All":
			WinNameStr = "DecayTDisplay"
		Break
		
		Case "RiseTau_Avg":
			WinNameStr = "RiseT"
		Break
		
		Case "RiseTau_Avg_All":
			WinNameStr = "RiseTDisplay"
		Break
		
		Default:
			WinNameStr = "None"	
	EndSwitch

If (!StringMatch(WinNameStr, "None"))

	StrSwitch (ctrlName)
		
		Case "PopupPSCZoomWin":
			DoWindow $WinNameStr
			If (V_Flag)
				DoWindow /F $WinNameStr
				//ModifyGraph /w = $popStr width=640,height=400
				MoveWindow /w = $WinNameStr 0, 0, 640, 400
			EndIf
			Break
		
		Case "PopupPSCEditData":
			pt_EditGraphWaves(WinNameStr)
			Break
		
		Default:
	
	EndSwitch
	
EndIf
End

Function pt_EditGraphWaves(GraphWinName)
// given a graph window edit all waves in a table
String GraphWinName

String WStr, TraceNames, TraceNameStr
Variable i, N

DoWindow pt_GraphDataEdit
If (V_Flag)
	DoWindow /k pt_GraphDataEdit
EndIf
Edit /k=1
DoWindow /C/F pt_GraphDataEdit

TraceNames = TraceNameList(GraphWinName,";",1)
N = ItemsInList(TraceNames, ";")
For (i=0; i<N; i+=1)
	TraceNameStr = StringFromList(i, TraceNames, ";")
	Wave WRef = TraceNameToWaveRef(GraphWinName, TraceNameStr)
	AppendToTable /W=pt_GraphDataEdit WRef
EndFor
End

Function pt_XYToWave2()

// Igor's Interpolate2 sorts the X,Y data before interpolating. If the original data has x values that 
// are not monotonically increasing, the auto-sorting by interpolate2 maps the x-y values to smaller
// x-values which doesn't faithfully represent the curve.
// example 
// x, y = [(0,0), (1,1), (2,1), (1.5,2), (1.7,0)] gets sorted as
// x, y = [(0,0), (1,1), (1.5,2), (1.7,0), (2,1)] but that's different than the original curve
// even if interpolate2 didn't sort the data, averaging such data will be a problem, because we will end
// up with non-unique y values for same x-values. 
// for now we will exclude x-y pairs when x value is lower than the last x-value.

// this function will generate waveform waves from XY waves. 
// based on igor supplied XYToWave2 (use #include <XY Pair to Waveform Panel> to load procedure)
//interp does linear interpolation on pre-sorted data. interpolate2 does cubic spline, and smoothed spline. no need to presort.

// Important -  We want all interpolated waves to have same start-x value and scaling so that they can be averaged.
// but all data points outside the range for a given x-wave will be set = NaN so that they don't contribute to average.

String YWaveMatchStr, XWaveMatchStr, SubFldr
Variable OutStartX, OutEndX, OutNumPnts, DisplayInterp
String YWList, XWList, wXStr, wYStr
Variable Ny, Nx, i, OutDelX, OutStartX0, OutEndX0, j, sort_order

String LastUpdatedMM_DD_YYYY="11_13_2013"

Print "*********************************************************"
Print "pt_XYToWave2 last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

	
Wave /T ParNamesW	=$pt_GetParWave("pt_XYToWave2", "ParNamesW")
Wave /T ParW			=$pt_GetParWave("pt_XYToWave2", "ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves pt_XYToWave2ParW and/or pt_XYToWave2ParNamesW!!!"
EndIf

YWaveMatchStr		=ParW[0]
XWaveMatchStr		=ParW[1]
SubFldr				=ParW[2]
OutNumPnts		= Str2Num(ParW[3])
OutStartX			= Str2Num(ParW[4])
OutEndX				= Str2Num(ParW[5])
DisplayInterp		= Str2Num(ParW[6])

PrintAnalPar("pt_XYToWave2")
//DoAlert 0, "FYI: Interpolation is set to linear and not cubic spline. Also, the function now removes pairs of xy vals for non-monotinc x vals"

YWList	=	pt_SortWavesInFolder(YWaveMatchStr, GetDataFolder(1)+SubFldr)
XWList	=	pt_SortWavesInFolder(XWaveMatchStr, GetDataFolder(1)+SubFldr)

Ny=ItemsInList(YWList, ";"); Nx=ItemsInList(XWList, ";")

If (Ny != Nx)
	Abort "Number of Y waves is not equal to number of x waves (N_X, NY = )" + Num2Str(Nx) +","+ Num2Str(Ny)
Else
	Print "Found number of XY waves =", Nx
EndIf
// find range (min, max) of all x - values
Make /O/N=0 XWaveFull
Make /O/N=(Nx) PntsPerWave			// to calculate average number of points (better would have been mode) the waves have
PntsPerWave = NaN
For (i=0; i<Nx; i+=1)
	wXStr=StringFromList(i, XWList,";")
	//Print GetDataFolder(1)+SubFldr+wXStr
	Wave Xwave=$GetDataFolder(1)+SubFldr+wXStr
	Concatenate /NP {XWave}, XWaveFull
	PntsPerWave[i] = NumPnts(XWave)
EndFor

Sort XWaveFull, XWaveFull



//If (NumType(OutStartX)*NumType(OutEndX) !=0*NumType(OutNumPnts) !=0)
If ( (NumType(OutStartX) || NumType(OutEndX) || NumType(OutNumPnts))  !=0) //08/26/14
WaveStats /Q XWaveFull
OutStartX			= V_Min
OutEndX				= V_Max
wavestats /Q PntsPerWave
OutNumPnts = Round(V_Max)
KillWaves /Z PntsPerWave
EndIf
// Get DelX which will be same for all waves
OutDelX = (OutEndX - OutStartX)/(OutNumPnts-1)
sort_order =  (OutDelX > 0) ? 1 : -1
Print "OutStartX, OutEndX, OutDelX, OutNumPnts=", OutStartX, OutEndX, OutDelX, OutNumPnts

For (i=0; i<Nx; i+=1)
	wXStr = StringFromList(i, XWList, ";")
	wYStr = StringFromList(i, YWList, ";")
	
	// We want all interpolated waves to have same start-x value and scaling so that they can be averaged.
	// but all data points outside the range for a given x-wave will be set = NaN so that they don't contribute to average.
	//OutNumPnts 		= 1+( (OutEndX - OutStartX)/OutDelX)
	Make /O/N=(OutNumPnts) $GetDataFolder(1)+SubFldr+wYStr+"_ip"
	SetScale /P x, OutStartX, OutDelX, $GetDataFolder(1)+SubFldr+wYStr+"_ip"
	Print "X, Y Wavenames : ", wXStr, wYStr
	pt_FilterNonMonotonicXVals(wXStr, wYStr, SubFldr, sort_order)
	Wave w_mX = $GetDataFolder(1)+SubFldr+wXStr+"mX"
	Interpolate2/T=1/E=2/I=3/Y=$(GetDataFolder(1)+SubFldr+wYStr+"_ip") $GetDataFolder(1)+SubFldr+wXStr+"mX", $GetDataFolder(1)+SubFldr+wYStr+"mY"
	wave wInterp = $(GetDataFolder(1)+SubFldr+wYStr+"_ip")
	// set all points outside orig. data = NaN
	Wavestats /Q $GetDataFolder(1)+SubFldr+wXStr+"mX"
	OutStartX0			= V_Min
	OutEndX0			= V_Max
	
	// Also exclude x-values above and below which the values of y wave were not a regular number.
	Wave /T NanIndicesParW	= $pt_GetParWave("pt_NanIndices", "ParW")
	Duplicate /O/T NanIndicesParW, NanIndicesParW_orig
	NanIndicesParW[0] = wYStr+"mY"//DataWaveMatchStr
	NanIndicesParW[1] = SubFldr//SubFldr
	pt_NanIndices()
	Duplicate /O/T NanIndicesParW_orig, NanIndicesParW
	KillWaves /Z NanIndicesParW_orig
	Wave w_ni =  $GetDataFolder(1)+SubFldr+wYStr+"mY_ni"
	If (OutStartX0 <  w_mX[w_ni[0]] )
		OutStartX0 = w_mX[w_ni[0]]
	EndIf
	If (OutEndX0 > w_mX[w_ni[NumPnts(w_ni) - 1]] )
		OutEndX0 = w_mX[w_ni[NumPnts(w_ni) - 1]]
	EndIf
	KillWaves /Z w_ni
	Print "OutStartX0, OutEndX0 =", OutStartX0, OutEndX0
	For (j=0; j<NumPnts(wInterp); j+=1)
		If ( (OutStartX + j*OutDelX) < OutStartX0 || (OutStartX + j*OutDelX) > OutEndX0)
			wInterp[j] = NaN
		EndIf
	EndFor
	wInterp = (x <  OutStartX0 || x > OutEndX0) ? NaN : winterp(x)
	If (DisplayInterp)
		DoWindow pt_InterPDisplay
		If (V_Flag)
		DoWindow /K pt_InterPDisplay
		EndIf
		Display
		DoWindow /C pt_InterPDisplay
		AppendToGraph /w=pt_InterPDisplay $GetDataFolder(1)+SubFldr+wYStr+"mY" vs $GetDataFolder(1)+SubFldr+wXStr+"mX"
		AppendToGraph /w=pt_InterPDisplay $(GetDataFolder(1)+SubFldr+wYStr+"_ip")
		ModifyGraph /w=pt_InterPDisplay rgb($(wYStr+"_ip"))=(0,0,0)
		ModifyGraph /W=pt_InterPDisplay mode=4
		ModifyGraph /W=pt_InterPDisplay  marker($(wYStr+"_ip"))=41
		DoUpdate /W = pt_InterPDisplay 
		Sleep /T 10
		DoWindow /K pt_InterPDisplay 
	EndIf
	KillWaves /Z $GetDataFolder(1)+SubFldr+wYStr+"mY", $GetDataFolder(1)+SubFldr+wXStr+"mX"
EndFor
KillWaves /Z XWaveFull, PntsPerWave		
End

Function pt_NanIndices()
	// return indexes for which $WNameStr == NaN
	
String DataWaveMatchStr, SubFldr
String WList, WStr
Variable N, NPnts, i


String LastUpdatedMM_DD_YYYY="07_21_2015"

Print "*********************************************************"
Print "pt_NanIndices last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

	
Wave /T ParNamesW	=$pt_GetParWave("pt_NanIndices", "ParNamesW")
Wave /T ParW			=$pt_GetParWave("pt_NanIndices", "ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves pt_NanIndicesParW and/or pt_NanIndicesParNamesW!!!"
EndIf

DataWaveMatchStr	=ParW[0]
SubFldr				=ParW[1]

PrintAnalPar("pt_NanIndices")

WList	=	pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
N = ItemsInList(WList, ";")

Print "Current folder name", GetDataFolder(1)
Print "Calculating NaN indices for waves, N=", N, WList

For (i=0; i<N; i+=1)
	WStr = StringFromList(i, WList, ";")
	Wave w = $GetDataFolder(1)+SubFldr+WStr
	
	Make /O/N=0 $GetDataFolder(1)+SubFldr+WStr+"_ni" // nan indices
	Wave w_ni = $GetDataFolder(1)+SubFldr+WStr+"_ni"
	
	Make /O/N=1 $GetDataFolder(1)+SubFldr+WStr+"_ni0" // nan indices
	Wave w_ni0 = $GetDataFolder(1)+SubFldr+WStr+"_ni0"
	
	NPnts = NumPnts(w)
	For (i=0; i<NPnts; i+=1)
		//print i, w[i]
		If (NumType(w[i]) == 0 )
			//print 'NaN', i
			w_ni0[0] = i
			Concatenate /NP {w_ni0}, w_ni
		EndIf
	EndFor
	Killwaves /Z  w_ni0
EndFor
End

Function pt_FilterNonMonotonicXVals(wXStr, wYStr, SubFldr, sort_order)
String wXStr, wYStr, SubFldr
Variable sort_order

Variable NPnts, i_ok, i
// if ith value in x-wave is smaller that (i-1)th value, remove the x-y pair. 
Wave wX = $GetDataFolder(1)+SubFldr+wXStr
Wave wY = $GetDataFolder(1)+SubFldr+wYStr

// make with one point so that the 1st point from original waves can be included before checking for monotonicity
Make /O/N=1 $GetDataFolder(1)+SubFldr+wXStr+"mX"	// mX = monotonicX1
Make /O/N=1 $GetDataFolder(1)+SubFldr+wYStr+"mY"

Make /O/N=1  $GetDataFolder(1)+SubFldr+wXStr+"mXTmp"
Make /O/N=1  $GetDataFolder(1)+SubFldr+wYStr+"mYTmp"

Wave wXmX = $GetDataFolder(1)+SubFldr+wXStr+"mX"
Wave wYmY = $GetDataFolder(1)+SubFldr+wYStr+"mY"

Wave wXmXTmp = $GetDataFolder(1)+SubFldr+wXStr+"mXTmp"
Wave wYmYTmp = $GetDataFolder(1)+SubFldr+wYStr+"mYTmp"

wXmX[0] = wX[0]
wYmY[0] = wY[0]

NPnts = NumPnts(wX)
i_ok = 0

For (i = 0; i < NPnts; i+=1)
	Switch (sort_order) 
	
		Case 1:	// ascending order
		If (wX[i+1] > wX[i_ok])
			wXmXTmp[0] = wX[i+1]
			wYmYTmp[0] = wY[i+1]
			Concatenate /NP {wXmXTmp}, wXmX
			Concatenate /NP {wYmYTmp}, wYmY
			i_ok = i + 1
		EndIf
		Break
		
		Case -1:	// descending order
		If (wX[i+1] < wX[i_ok])
			wXmXTmp[0] = wX[i+1]
			wYmYTmp[0] = wY[i+1]
			Concatenate /NP {wXmXTmp}, wXmX
			Concatenate /NP {wYmYTmp}, wYmY
			i_ok = i + 1
		EndIf
		Break
		EndSwitch
EndFor

KillWaves /Z wXmXTmp, wYmYTmp
End

Function pt_WavestatsParAsW()
String DataWaveMatchStr, SubFldr, OutWName//, ParName
Variable M_WaveStatsNum
String WList, WStr
Variable i, N

String LastUpdatedMM_DD_YYYY="11_13_2013"

Print "*********************************************************"
Print "pt_WavestatsParAsW last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

// this function will generate waveform waves from XY waves. 
// based on igor supplied XYToWave2 (use #include <XY Pair to Waveform Panel> to load procedure)
//interp does linear interpolation on pre-sorted data. interpolate2 does cubic spline, and smoothed spline. no need to presort.

// Important -  We want all interpolated waves to have same start-x value and scaling so that they can be averaged.
// but all data points outside the range for a given x-wave will be set = NaN so that they don't contribute to average.
	
Wave /T ParNamesW	=$pt_GetParWave("pt_WavestatsParAsW", "ParNamesW")
Wave /T ParW			=$pt_GetParWave("pt_WavestatsParAsW", "ParW")

If (WaveExists(ParNamesW)&&WaveExists(ParW) == 0)
	Abort	"Cudn't find the parameter waves pt_WavestatsParAsWParW and/or pt_WavestatsParAsWParNamesW!!!"
EndIf

DataWaveMatchStr		=	ParW[0]
SubFldr					=	ParW[1]
//ParName 				=	ParW[2]
M_WaveStatsNum		= 	Str2Num(ParW[2])
OutWName				=	ParW[3]

PrintAnalPar("pt_WavestatsParAsW")

WList	=	pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
N = ItemsInList(WList, ";")

Print "Current folder name", GetDataFolder(1)
Print "Calculating wavestats par on waves, N=", N, WList


Make /O/N=(N) $GetDataFolder(1)+SubFldr+OutWName
Wave wOut = $GetDataFolder(1)+SubFldr+OutWName
wOut = NaN
For (i=0; i<N; i+=1)
	WStr = StringFromList(i, WList, ";")
	Wavestats /W/Q $WStr
	Wave StatsWave  = M_WaveStats
	wOut[i] = StatsWave[M_WaveStatsNum]
EndFor
// given a set of waves, calculate the specified par in a wave and return as a wave
End



Function pt_RepCallFunc(FuncName)
String FuncName
// wrapper for calling a function multiple times based on repeat info wave. 
// logic. In a given folder read the reps info wave. Call the function 'FuncName' multiple times with some parameters varied.
End



//&&&&&&&&&&&&&&&&&&&&&&&&&
Function pt_PostProcessFI()

// This is always the latest version.

// based on pt_ExtractWRepsNSrt(). Generate following waves. Given a vector (different points correspond to different spike #); different vectors 
// correspond to different iterations in one repeat and there are several repeats. pt_ExtractWRepsNSrt already generates 
// AHPY;ISV;FWFracM;ISI, Adapt ratio; avg inst. freq., spike hieght;Spike voltage thresh; Spk max slope; spike time to frac peak"

// categories - for some data we want to generate the parameter like spike hieght for1st n spikes as a function of current and then average repeats
// for some data we want to average for all spikes and 
NVAR VectorParNSpks = root:AnalysisViewer:VectorParNSpks
NVAR DoSealTestAnal =  root:AnalysisViewer:DoSealTestAnal
String DataWaveMatchStr, DataFldrStr, RangeW, RangeWPrefixStr
String SealTestParList="Rs;RIn;Cm;"
Variable PntsPerRep, StartPnt, NumReps, StartXVal, DeltaXValue, NSealTestParList 

NSealTestParList=ItemsInList(SealTestParList)

Variable i, j, k, NPnts//, VectorParNSpks = 4
String BaseNameStr, ParStr

//vector parameters: average repeats first. 
String SpkAnalVectorParList="AHPY;PeakRelY;FWFracM;SpikeThreshY;SpkMaxDvDtY;TToFracPeakY;IFrq;ISI" //PeakAbsX
Variable NSpkAnalVectorParList = ItemsInList(SpkAnalVectorParList, ";")


String LastUpdatedMM_DD_YYYY=" 11/16/2013", WList, SubFldr

Print "*********************************************************"
Print "pt_PostProcessFI last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_PostProcessFI", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW			=	$pt_GetParWave("pt_PostProcessFI", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_PostProcessFI!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
RangeW					=	AnalParW[2]
RangeWPrefixStr		=	AnalParW[3]

If (StringMatch(RangeWPrefixStr, "DataFldrName"))
	RangeW	= GetDataFolder(0)+RangeW
Else
	RangeW	= RangeWPrefixStr+RangeW
EndIf

PrintAnalPar("pt_PostProcessFI")

Wave /T AnalParNamesW	=	$pt_GetParWave(RangeW, "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave(RangeW, "ParW")

PntsPerRep		=	Str2Num(AnalParW[0])
StartPnt		=	Str2Num(AnalParW[1])	// Start Pnt of first repeat counting from 1.
NumReps		=	Str2Num(AnalParW[2])
StartXVal		= 	Str2Num(AnalParW[3])
DeltaXValue		= 	Str2Num(AnalParW[4])

Print "Analyzing folder", GetDataFolder(1)
Print "PntsPerRep, StartPnt, NumReps, StartXVal, DeltaXValue", PntsPerRep, StartPnt, NumReps, StartXVal, DeltaXValue

If (StartPnt==0)				// StartPnt counts from 1 and not 0.
//	DoAlert 1, "StartPnt should not be =0!!. Assume StartPnt =1 and continue?"
//	If (V_Flag )
//		StartPnt=1
//	Else
	Print "******StartPnt should be >0!!. Nothing analyzed****** "
	Return 1
//	Abort
EndIf

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_SpikeAnal", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_SpikeAnal", "ParW")
BaseNameStr = AnalParW[14]
Print "BaseNameStr=",BaseNameStr

NPnts = NumReps*PntsPerRep

If (NPnts!=0)

//--------------- for the vectors that have been averaged over repeats by pt_ExtractWRepsNSrt, generate waves with for
// 1st spike, 2ns spike, etc. 
//pt_NthPntWave
Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_NthPntWave"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_NthPntWave"+"ParW")

SaveNRestore("pt_NthPntWave", 1)

AnalParW[3]	=	""//WList
For(j=0;j<NSpkAnalVectorParList;j+=1)
	AnalParW[4]	=	""//SubDataFldr
	For (k=0; k<VectorParNSpks; k+=1)
		ParStr=StringFromList(j, SpkAnalVectorParList, ";")
		AnalParW[0]	= 	"A"+BaseNameStr+ParStr+"W*_Avg"	//DataWaveMatchStr
		AnalParW[1]	=	Num2Str(k)								//PntNum
		AnalParW[2]	=	"Spk"+Num2Str(k)+BaseNameStr+ParStr+"W"	//DestWName	
		AnalParW[4]	=	BaseNameStr+ParStr+"F:"			//SubFldrList
		pt_NthPntWave()
	EndFor
EndFor
SaveNRestore("pt_NthPntWave", 2)

// calculate vectors for instantaneous frequency. (DO NOT USE SPIKE TIMES AVERAGED OVER REPEATS. FIRST
// CALCULATE INST. FREQ. OR ISI AND THEN AVERAGE OVER REPEATS)
// convert spike times to Inst Freq.

//BETTER NOT TO GENERATE NEW NAME BY INSERTION AT SOME POSITION COS THEN IT DEPENDS ON BASE NAME STR
//pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
//$$//Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParNamesW")		
//$$//Wave /T AnalParW				=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParW")
//$$//SaveNRestore("pt_ConvertTSpikeToISI", 1) 
//$$//AnalParW[0]	=	"S"+BaseNameStr+"PeakAbsXW*" // DataWaveMatchStr
//$$//AnalParW[1]	=	""					//DataWaveNotMatchStr
//AnalParW[2]	=	"InstFrq"			//InsrtNewStr
//$$//AnalParW[2]	=	"IFrq"			//InsrtNewStr
//$$//AnalParW[3]	=	"-1"					//  InsrtPosStr
//$$//AnalParW[4]	=	"0"					//ReplaceExisting 
//$$//AnalParW[5]	=	BaseNameStr+"PeakAbsXF:"	//SubFldr
//$$//AnalParW[6]	=	"1"						// Invert
//$$//pt_ConvertTSpikeToISI()
//$$//SaveNRestore("pt_ConvertTSpikeToISI", 2)


// Since we are going to calculate average of all inst. freq., we should remove outliers. 
//******************
//pt_AnalWInFldrs2("pt_RemoveOutLiers1")
//$$//Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")		
//$$//Wave /T AnalParW			=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")
//$$//SaveNRestore("pt_RemoveOutLiers1", 1)
//$$//AnalParW[0]	=	"IFrq" +"S"+BaseNameStr+"PeakAbsXW*" // DataWaveMatchStr
//$$//AnalParW[1]	=	"-1"					//SmoothFactor
//$$//AnalParW[2]	=	"3"					//TimesSD
//$$//AnalParW[3]	=	BaseNameStr+"PeakAbsXF:"	//SubFldr
//$$//AnalParW[4]	=	"1"						//UseMedian
//$$//pt_RemoveOutLiers1()
//$$//SaveNRestore("pt_RemoveOutLiers1", 2)

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_RemoveOutLiers1", "ParNamesW")		
Wave /T AnalParW			=	$pt_GetParWave("pt_RemoveOutLiers1", "ParW")
SaveNRestore("pt_RemoveOutLiers1", 1)
AnalParW[0]	=	"S"+BaseNameStr+"IFrqW*" // DataWaveMatchStr
AnalParW[1]	=	"-1"					//SmoothFactor
AnalParW[2]	=	"3"					//TimesSD
AnalParW[3]	=	BaseNameStr+"IFrqF:"	//SubFldr
AnalParW[4]	=	"1"						//UseMedian
pt_RemoveOutLiers1()
SaveNRestore("pt_RemoveOutLiers1", 2)

//****************** average over all inst. freq.
//pt_AnalWInFldrs2("pt_AverageVals")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageVals", "ParNamesW")
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageVals", "ParW")
SaveNRestore("pt_AverageVals", 1)

AnalParW[1]	=	"-1"				//XStartVal
AnalParW[2]	=	"-1"				//XEndVal
AnalParW[4]	=	BaseNameStr+"IFrqF:"			//SubFldr

For (i = 0; i <NumReps; i += 1)

	AnalParW[0]	=	 "S"+BaseNameStr+"IFrqW*_"+Num2Str(i)+"_NoOL"			//DataWaveMatchStr
	//AnalParW[3]	=	BaseNameStr+"_InstFrq_"+Num2Str(i)							//BaseNameString
	// Remove hyphen to distinguish from averaged wave in the next step
	AnalParW[3]	=	BaseNameStr+"_AvgIFrq"+Num2Str(i)
	pt_AverageVals()

EndFor
SaveNRestore("pt_AverageVals", 2)

// average waves
//pt_AnalWInFldrs2("pt_AverageWaves")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")

SaveNRestore("pt_AverageWaves", 1)

AnalParW[1]	=	""	//DataFldrStr
AnalParW[3]	=	"1"//PntsPerBin
AnalParW[4]	=	""//ExcludeWNamesWStr
//AnalParW[5]	=	"1"//DisplayAvg


AnalParW[0]	=	BaseNameStr+"_AvgIFrq*Avg"				//DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"IFrqF:"		//DataFldrStr
AnalParW[2]	=	BaseNameStr+"AvgIFrq"			//BaseNameStr
AnalParW[5]	=	"0"//DisplayAvg
pt_AverageWaves()
SaveNRestore("pt_AverageWaves", 2)

//---------------Avg. Inst Freq End	

//---------------Also calculate instantaneous freq for number of spikes = VectorParNSpks (in addition to the averaged inst. freq. above)

//--------------- for the vectors that have been averaged over repeats by pt_ExtractWRepsNSrt, generate waves with for

//


// 1st spike, 2ns spike, etc. 
//pt_NthPntWave
Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_NthPntWave"+"ParNamesW")
Wave /T AnalParW			=	$("root:FuncParWaves:pt_NthPntWave"+"ParW")

SaveNRestore("pt_NthPntWave", 1)

AnalParW[3]	=	""//WList

//For(j=0;j<NSpkAnalVectorParList;j+=1)
	AnalParW[4]	=	""//SubDataFldr
	For (k=0; k<VectorParNSpks; k+=1)
		//ParStr=StringFromList(j, SpkAnalVectorParList, ";")
		AnalParW[0]	= 	BaseNameStr+"AvgIFrq_Avg"	//DataWaveMatchStr
		AnalParW[1]	=	Num2Str(k)								//PntNum
		AnalParW[2]	=	"Spk"+Num2Str(k)+BaseNameStr+"AvgIFrqW"	//DestWName	
		AnalParW[4]	=	BaseNameStr+"IFrqF:"			//SubFldrList
		pt_NthPntWave()
	EndFor
//EndFor

SaveNRestore("pt_NthPntWave", 2)

//---------------


//---------------Adaptation ratio Start
// convert spike times to ISI.

//pt_AnalWInFldrs2("pt_ConvertTSpikeToISI")
//$$//Wave /T AnalParNamesW		=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParNamesW")		
//$$//Wave /T AnalParW				=	$pt_GetParWave("pt_ConvertTSpikeToISI", "ParW")
//$$//SaveNRestore("pt_ConvertTSpikeToISI", 1) 
//$$//AnalParW[0]	=	"S"+BaseNameStr+"PeakAbsXW*" // DataWaveMatchStr
//$$//AnalParW[1]	=	""					//DataWaveNotMatchStr
//$$//AnalParW[2]	=	"ISI"			//InsrtNewStr
//$$//AnalParW[3]	=	"-1"					//  InsrtPosStr
//$$//AnalParW[4]	=	"0"					//ReplaceExisting 
//$$//AnalParW[5]	=	BaseNameStr+"PeakAbsXF:"	//SubFldr
//$$//AnalParW[6]	=	"0"						// Invert
//$$//pt_ConvertTSpikeToISI()
//$$//SaveNRestore("pt_ConvertTSpikeToISI", 2)


Wave /T AnalParNamesW	=	$pt_GetParWave("pt_CalISIAdaptRatio", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_CalISIAdaptRatio", "ParW")

Duplicate /O/T AnalParW, AnalParWOrig

//**** ISI count starts from zero. So StartISINum=1 is actually 2nd ISI. 
//StartISINumAvgWin	= 1 implies only 1 point. EndISINumAvgWin=1 implies only 1 point***
// with above values we are defining adaptation ratio as 2nd ISI/ Last ISI

//DoAlert 0, "Warning: AdaptR temporarily set to 3rd ISI/LastISI !!!"

//AnalParW[1]	=	"1"//StartISINum

AnalParW[1]		=	"1"//StartISINum
AnalParW[2] 	=	"1"//StartISINumAvgWin	
AnalParW[3] 	=	"1"//EndISINumAvgWin
AnalParW[5]	=	""//OutNameSuffixStr
AnalParW[6]	=	BaseNameStr+"ISIF:"	//SubFldr


For (i = 0; i <NumReps; i += 1)
	AnalParW[0]	=	"S"+BaseNameStr+"ISIW*_"+Num2Str(i)	//DataWaveMatchStr
	//AnalParW[4]	=	BaseNameStr+"AdaptR"+"_"+Num2Str(i)//OutNameBaseStr
	// following out name to 1) exclude _avg wave and 2) Adapt*X wave (which is also generated) in averaging in the next step
	AnalParW[4]	=	BaseNameStr+"Adapt"+Num2Str(i)+"R"//OutNameBaseStr
	pt_CalISIAdaptRatio()
EndFor
Duplicate /O/T AnalParWOrig, AnalParW
KillWaves /z AnalParWOrig



// average waves
//pt_AnalWInFldrs2("pt_AverageWaves")
Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AverageWaves", "ParNamesW")		
Wave /T AnalParW				=	$pt_GetParWave("pt_AverageWaves", "ParW")

SaveNRestore("pt_AverageWaves", 1)

AnalParW[1]	=	""	//DataFldrStr
AnalParW[3]	=	"1"//PntsPerBin
AnalParW[4]	=	""//ExcludeWNamesWStr
//AnalParW[5]	=	"1"//DisplayAvg


AnalParW[0]	=	BaseNameStr+"Adapt*R"				//DataWaveMatchStr
AnalParW[1]	=	BaseNameStr+"ISIF:"		//DataFldrStr
AnalParW[2]	=	BaseNameStr+"AdaptR"			//BaseNameStr
AnalParW[5]	=	"0"//DisplayAvg
pt_AverageWaves()
SaveNRestore("pt_AverageWaves", 2)

//---------------Adaptation ratio End



//******************


Else 
Print "Attention! Either PntsPerRep OR NumReps =0!!! No Wave Generated"	
EndIf

End
//&&&&&&&&&&&&&&&&&&&&&&&&&

Function pt_PlotCursorDiff(GraphName)
String GraphName
// A quick script to plot response amplitude so that we can check when the
// response is stable.
// logic - Make a new graph.
// Append to graph the difference between cursor B - cursor A from
// a specified graph. The function needs to run after every data aquisition iteration
Variable y2, y1
DoWindow pt_PlotCursorDiff_Display // if window is closed, assume new trace
If (V_Flag ==0)
	Make /O/N=0 CursorDiffW
	Display 
	DoWindow /C pt_PlotCursorDiff_Display
	AppendToGraph /W = pt_PlotCursorDiff_Display CursorDiffW
	ModifyGraph /W = pt_PlotCursorDiff_Display mode=4,marker=19
EndIf
Make /O/N=1 CursorDiffWTemp
y1 = vcsr(A, GraphName)
y2 = vcsr(B, GraphName)
CursorDiffWTemp[0] = y2 - y1
Concatenate /NP {CursorDiffWTemp}, CursorDiffW
End

Function pt_RepTabEntries(TableName, OrigStr, NewStr)
String TableName, OrigStr, NewStr
String FullPath = ""
Variable i, j, NPnts
// function to replace missing values with a string in the top table.

i = 0
Do
	Wave /Z w = WaveRefIndexed(TableName, i , 3)
	If (!WaveExists(w) )
		Break
	EndIf
	FullPath = GetWavesDataFolder(w, 2)
	Wave /T w1 = $FullPath
	NPnts = NumPnts(w1)
	Print "Wave names and num pnts =", FullPath, NPnts
	For (j =0; j < NPnts; j +=1)
		If (StringMatch(w1[j], OrigStr))
			w1[j] = NewStr
		EndIf
	EndFor
	
	i +=1
While (1)

End

Function pt_CalTonicCurr()
// Reference Glykys et al The Journal of Physiology 582, no. Pt 3 (August 1, 2007)
//Aim: to quantify tonic current.
// Steps in paper
// 1. Concatenate all waves 
// 2. Remove seal tests
// 3. All points histogram for 10K points (Sampling 10kHz; LowPass 3kHz)
// 4. Smooth using SavitzkyñGolay. Find Peak
// 5. Fit Gaussian to part of histogram that excludes synaptic events (ie > 1 to 3pA) to the largest value
// 6. Mean of fitted Gaussian = mean of holding current
// 7. Repeat for all traces.
// 8. If basline means are sloping, detrend using a linear fit.
// 9. Tonic current = Difference between baseline current with and without Bicuculline.

String DataWaveMatchStr, DataFldrStr, OutWName
Variable StartTime, DelTime, EndTime, SmoothFactor, DisplayHist	//, EventsPolarity
Variable DeltaT, NAvgPnts, i, t1, t2 //HistMinX, HistMaxX, MeanStartX, MeanEndX
Variable MinVal, NumBins = 10000, BinWidth = 0.25e-12
String  LastUpdatedMM_DD_YYYY = "05/06/2014", CnctnWName

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalTonicCurr", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW			=	$pt_GetParWave("pt_CalTonicCurr", "ParW")


If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
//	Abort	"Cudn't find the parameter wave pt_CalTonicCurrParW!!!"
EndIf


Print "*********************************************************"
Print "pt_CalTonicCurr last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
StartTime				= 	Str2Num(AnalParW[2])
DelTime					= 	Str2Num(AnalParW[3])
EndTime					= 	Str2Num(AnalParW[4])
//EventsPolarity			= 	Str2Num(AnalParW[5])
SmoothFactor			= 	Str2Num(AnalParW[5])
OutWName 				= 	AnalParW[6]
DisplayHist				= 	Str2Num(AnalParW[7])


Wave /T ConctnParW		=$pt_GetParWave("pt_ConctnWFrmFldrs", "ParW")

If (WaveExists(ConctnParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_ConctnWFrmFldrsParW!!!"
EndIf

SaveNRestore("pt_ConctnWFrmFldrs", 1)
ConctnParW[0]		= DataWaveMatchStr
ConctnParW[1]		= DataFldrStr
ConctnParW[2]		= ""
ConctnParW[3]		= Num2Str(StartTime)		//StartX
ConctnParW[4]		= Num2Str(EndTime)		//EndX

pt_AnalWInFldrs2("pt_ConctnWFrmFldrs")

SaveNRestore("pt_ConctnWFrmFldrs", 2)
CnctnWName = GetDataFolder(0)
Wave CnctnW = $CnctnWName


DeltaT 		= DimDelta(CnctnW, 0)
//SetScale /P x, 0, DeltaT, CnctnW		// The offset after concatenation is set to StartTime
NAvgPnts 	= Trunc((NumPnts(CnctnW)*DeltaT )/DelTime)
//Print NumPnts(CnctnW)
Print "Num averages points =", NAvgPnts

Make /O/N=(NAvgPnts) $OutWName
Wave OutW = $OutWName

For (i = 0; i<NAvgPnts; i+=1)
	t1 = i*StartTime
	t2 = i*StartTime+DelTime
	Duplicate /O /R = (t1, t2) CnctnW, $"CnctnW"+Num2Str(i)
	Wavestats /Q $"CnctnW"+Num2Str(i)
	MinVal = V_Min
	Make/N=(NumBins)/O $"CnctnW"+Num2Str(i)+"_Hist";DelayUpdate
	Histogram/B={MinVal, BinWidth, NumBins} /C $"CnctnW"+Num2Str(i),$"CnctnW"+Num2Str(i)+"_Hist"
	//HistMinX 	= DimOffSet(CnctnWTmp_Hist, 0)
	//HistMaxX 	= HistMinX + 99*DimDelta(CnctnWTmp_Hist, 0)
	Duplicate/O $"CnctnW"+Num2Str(i)+"_Hist",$"CnctnW"+Num2Str(i)+"_Hist_smth";DelayUpdate
	Smooth/S=2 SmoothFactor, $"CnctnW"+Num2Str(i)+"_Hist_smth"
	Wavestats /Q $"CnctnW"+Num2Str(i)+"_Hist_smth"
	/////If (EventsPolarity == 1)
	/////	MeanStartX = HistMinX
	/////	MeanEndX = V_MaxLoc + 3e-12
	/////Else
	/////	MeanStartX = V_MaxLoc - 3e-12
	/////	MeanEndX = HistMaxX
	/////EndIf
	//CurveFit /NTHR=0 gauss  Cell_0024_Hist_smth[pcsr(B),pcsr(A)] /D 
	/////WaveStats /Q/R= (MeanStartX, MeanEndX) CnctnWTmp_Hist_smth
	OutW[i] = V_MaxLoc
	Make /O/N=1 $"HistPkLoc"+Num2Str(i), $"HistPkVal"+Num2Str(i)
	Wave HistPkLoc = $"HistPkLoc"+Num2Str(i)
	Wave HistPkVal = $"HistPkVal"+Num2Str(i)
	HistPkLoc = V_MaxLoc
	HistPkVal = V_Max
	//FitStartX = V_MaxLoc
	If (DisplayHist)
	DoWindow $"pt_CalTonicCurrDisplay" 
	If (V_Flag)
//		DoWindow /F pt_RsRinCmVmIclamp2Display
//		Sleep 00:00:01
		DoWindow /K $"pt_CalTonicCurrDisplay" 
	EndIf
	Display 
	DoWindow /C $"pt_CalTonicCurrDisplay" 
	AppendToGraph /W = $"pt_CalTonicCurrDisplay"  $"CnctnW"+Num2Str(i)+"_Hist",$"CnctnW"+Num2Str(i)+"_Hist_smth"
	ModifyGraph  rgb($"CnctnW"+Num2Str(i)+"_Hist_smth")=(0,0,0)
	AppendToGraph /W = $"pt_CalTonicCurrDisplay"  HistPkVal vs HistPkLoc
	ModifyGraph  /W = $"pt_CalTonicCurrDisplay" mode($"HistPkVal"+Num2Str(i))=3,marker($"HistPkVal"+Num2Str(i))=19
	ModifyGraph /W = $"pt_CalTonicCurrDisplay" rgb($"HistPkVal"+Num2Str(i)) = (0,15872,65280)
	Legend /W=$"pt_CalTonicCurrDisplay"  /C/N=text0/F=0
	DoUpdate /W = $"pt_CalTonicCurrDisplay"
	Sleep /T 30
	EndIf
	DoWindow $"pt_CalTonicCurrDisplay" 
	If (V_Flag)
//		DoWindow /F pt_RsRinCmVmIclamp2Display
//		Sleep 00:00:01
		DoWindow /K $"pt_CalTonicCurrDisplay" 
	EndIf
	KillWaves /Z $"CnctnW"+Num2Str(i)+"_Hist",$"CnctnW"+Num2Str(i)+"_Hist_smth"
	KillWaves /Z $"HistPkLoc"+Num2Str(i), $"HistPkVal"+Num2Str(i)
	KillWaves /Z $"CnctnW"+Num2Str(i)
EndFor
SetScale /P x, 0.5*Deltime, Deltime, OutW

DoWindow $"pt_CalTonicCurrDisplay" 
If (V_Flag)
//		DoWindow /F pt_RsRinCmVmIclamp2Display
//		Sleep 00:00:01
		DoWindow /K $"pt_CalTonicCurrDisplay" 
EndIf
Display 
DoWindow /C $"pt_CalTonicCurrDisplay" 
AppendToGraph  /W = $"pt_CalTonicCurrDisplay"  CnctnW, OutW
ModifyGraph  /W = $"pt_CalTonicCurrDisplay"  rgb($OutWName)=(0,0,0)
ModifyGraph  /W = $"pt_CalTonicCurrDisplay"  mode($OutWName)=3,marker($OutWName)=19
KillWaves /Z CnctnWTmp, CnctnWTmp_Hist, pt_CalTonicCurr_HistPkLoc, pt_CalTonicCurr_HistPkVal
	
End

Function /S pt_ReturnObjList(FolderPath, MatchStr, ObjType)
String FolderPath, MatchStr
Variable ObjType
String OldDf, ObjStr, ListObjs = ""
Variable i, N
// Return list of folders that match MatchStr
//1:	Waves.
//2:	Numeric variables.
//3:	String variables.
//4:	Data folders.

OldDf = GetDataFolder(1)
SetDataFolder $FolderPath
DFREF saveDFR = GetDataFolderDFR()	
N = CountObjectsDFR(saveDFR , ObjType)
For (i = 0; i<N;i+=1)
	ObjStr=GetIndexedObjNameDFR(saveDFR, ObjType,i)
	If (StringMatch(ObjStr, MatchStr))
		ListObjs+=ObjStr+";"
	EndIf
EndFor
Return ListObjs
End

Function pt_CalFISlope()

// added CurrFitTh - current threshold from linear fit = -c/m, where c = y intercept and m is slope 06/11/15
//=======06_02_15=======//
//fit_start = w_ITh0// -DimDelta(w, 0)   // start fit from first non-zero value.
//=======06_02_15=======//
//=======05_30_15=======//
// modified to use curve_fit which can fit waves with NaNs (eg. in instantaneous  freq).
// also allowed for max range by setting CurrRangeAboveThresh = "" or "inf" for max range.
// still keeping intercept as manually calculated and not fitted intercept as sometimes fit is not accurate 
// and also the fitted intercept will under estimate the current thresh.
// if the fit fails, V_FitError is set = 1, in which case slope = NaN. Note V_FitError variable needs to be manually created.
// If fit_start + CurrRangeAboveThresh > x_max; set CurrRangeAboveThresh = x_max - fit_start
// also show fit (code from pt_CurveFitEdit())
//=======05_30_15=======//

// also calculate max freq and current at which freq is max. 10/29/14
// calculate current threshold and slope of FI curves. Partly based on pt_LevelCross
// current thresh - 1st non zero-spike


String DataWaveMatchStr, SubFldr, OutWBaseName
Variable CurrRangeAboveThresh, InterpCorr, DisplayFit	

String	WList, WNameStr, TraceNameStr
Variable	Numwaves, i, LevelVal, NPnts, j
Variable SkipW=0, slope, intercept
Variable x_max, fit_start, w_ITh0
Variable V_FitError =0, CurrRangeAboveThresh0 
String  LastUpdatedMM_DD_YYYY = "07/18/2014"

Wave /T AnalParNamesW	=	$pt_GetParWave("pt_CalFISlope", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW			=	$pt_GetParWave("pt_CalFISlope", "ParW")


If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
//	Abort	"Cudn't find the parameter wave pt_CalFISlopeParW!!!"
EndIf


Print "*********************************************************"
Print "pt_CalFISlope last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


DataWaveMatchStr		=	AnalParW[0]
SubFldr					=	AnalParW[1]
CurrRangeAboveThresh	= 	Str2Num(AnalParW[2])   // set = "" or "inf" for max range. 05_30_15
InterpCorr				= 	Str2Num(AnalParW[3])
OutWBaseName			= 	AnalParW[4]
DisplayFit				= 	Str2Num(AnalParW[5])

PrintAnalPar("pt_CalFISlope")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+SubFldr)
Numwaves=ItemsInList(WList, ";")

Print "Finding FI slope, current thresh., max. freq., and max. freq. current for, N =", Numwaves, WList

Make /O/N=(Numwaves) $(GetDataFolder(1)+SubFldr+OutWBaseName+"CurrTh"),  $(GetDataFolder(1)+SubFldr+OutWBaseName+"Slope")


Wave w_ITh = $(GetDataFolder(1)+SubFldr+OutWBaseName+"CurrTh")
Wave w_Slp = $(GetDataFolder(1)+SubFldr+OutWBaseName+"Slope")
w_ITh = Nan
w_Slp = Nan

//added CurrFitTh - current threshold from linear fit = -c/m, where c = y intercept and m is slope 06/11/15
Make /O/N=(Numwaves) $(GetDataFolder(1)+SubFldr+OutWBaseName+"CurrFitTh")
Wave w_IFitTh = $(GetDataFolder(1)+SubFldr+OutWBaseName+"CurrFitTh")
w_IFitTh = NaN

Make /O/N=(Numwaves) $(GetDataFolder(1)+SubFldr+OutWBaseName+"MaxFreq"), $(GetDataFolder(1)+SubFldr+OutWBaseName+"CurrAtMaxFreq")
Wave w_MaxFreq = $(GetDataFolder(1)+SubFldr+OutWBaseName+"MaxFreq")
Wave w_CurrAtMaxFreq = $(GetDataFolder(1)+SubFldr+OutWBaseName+"CurrAtMaxFreq")
w_MaxFreq = Nan
w_CurrAtMaxFreq = Nan

CurrRangeAboveThresh0 = CurrRangeAboveThresh

For (i=0; i<Numwaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	Wave w=$(GetDataFolder(1)+SubFldr+WNameStr)
	CurrRangeAboveThresh = CurrRangeAboveThresh0
	NPnts=NumPnts(w)
	j=0; SkipW=0; LevelVal=Nan
	Do
		If (j<NPnts) // not yet reached last point in the wave
			//If (w[j]!=0)
			If (NumType(w[j]) == 0 && w[j]!=0) // NumType(w[j]) == 0 so that we can ignore NaNs
				LevelVal = w[j]
				// calculate x value for crossing right here rather than later using Findlevel 05_30_15
				w_ITh[i] = DimOffset(w, 0) + j*DimDelta(w, 0)
				w_ITh0 = w_ITh[i] 
				If (InterpCorr)
					w_ITh[i] = w_ITh[i] -(DimDelta(w, 0))*0.5	// 12/06/12
				EndIf 
				Break
			EndIf
		Else
			Print "Warning: All values in wave", WNameStr, "are =0 or the wave has 0 number of points. Skipping wave"
			SkipW=1
			//w_ITh0 = NaN
			Break
		EndIf
		j+=1
	While (1)

//If (!SkipW)  05_30_15
//	print 'LevelVal', LevelVal
//	Findlevel /Q/edge=1 w, LevelVal
//	If (V_flag==0)
		//w_ITh0rig  =  V_LevelX
//		w_ITh[i] = V_LevelX
//		If (InterpCorr)
//			w_ITh[i] = V_LevelX-(DimDelta(w, 0))*0.5	// 12/06/12
//		EndIf
//	Else
//		Print "Warning: Level crossing not found for",WNameStr
		//w_ITh0rig = NaN
//		w_ITh[i] = NaN
//	EndIf
//EndIf

If (!SkipW)
fit_start = w_ITh0// -DimDelta(w, 0)   // start fit from first non-zero value.
// if nothing was specified in CurrRangeAboveThresh, then Str2Num(CurrRangeAboveThresh) = NaN. Set = max range.

x_max = DimOffset(w, 0) + (NumPnts(w) -1)*DimDelta(w, 0)

If (NumType(CurrRangeAboveThresh0) !=0)
	CurrRangeAboveThresh = x_max - fit_start
EndIf

If (   (fit_start + CurrRangeAboveThresh0) > x_max)
	CurrRangeAboveThresh = x_max - fit_start
EndIf

print "Curr. thresh =", w_ITh[i],". Fitting slope in range", fit_start  ,fit_start + CurrRangeAboveThresh, "in", WNameStr

Duplicate /O/R=(fit_start  ,fit_start + CurrRangeAboveThresh) w, $(GetDataFolder(1)+SubFldr+"w_FtRng")
Wave w_FtRng= $(GetDataFolder(1)+SubFldr+"w_FtRng")

Duplicate /O w_FtRng, $(GetDataFolder(1)+SubFldr+"fit_"+WNameStr)
Wave FitW=$(GetDataFolder(1)+SubFldr+"fit_"+WNameStr)
FitW=Nan
	
//pt_linearfit(w,w_ITh[i] ,w_ITh[i] + CurrRangeAboveThresh,slope,intercept)
CurveFit/Q/NTHR=0/TBOX=0/W=2 line w_FtRng /D=FitW
Wave CoefW= W_Coef 
If (V_FitError!=0)
	print V_FitError
	V_FitError=0
	Print "Fitting error in", WNameStr,". Coeff and Sigma set = NAN"
	Else
	w_Slp[i] = CoefW[1]
	w_IFitTh[i] = -CoefW[0]/CoefW[1] // y = mx + c => at y = 0, x = -c/m
EndIf



If (DisplayFit)
	Display
	DoWindow pt_CalFISlopeDisplay
	If (V_Flag)
		DoWindow /F pt_CalFISlopeDisplay
//		Sleep 00:00:02
		DoWindow /K pt_CalFISlopeDisplay
	EndIf
	DoWindow /C pt_CalFISlopeDisplay
	AppendToGraph /W=pt_CalFISlopeDisplay w
	TraceNameStr=WNameStr
	ModifyGraph /W=pt_CalFISlopeDisplay rgb($TraceNameStr)=(65280,0,0)
	AppendToGraph /W=pt_CalFISlopeDisplay w_FtRng
	TraceNameStr="w_FtRng"
	ModifyGraph /W=pt_CalFISlopeDisplay rgb($TraceNameStr)=(0,0,0)
	DoUpdate
//	Sleep /T 120

	AppendToGraph FitW
	ModifyGraph /W=pt_CalFISlopeDisplay lsize=2
	TraceNameStr="fit_"+WNameStr
	ModifyGraph /W=pt_CalFISlopeDisplay rgb($TraceNameStr)=(0,43520,65280)
	DoUpdate
	Sleep /T 30
EndIf

DoWindow pt_CalFISlopeDisplay		// kill the last display window 11_11/13
If (V_Flag)
	DoWindow /K pt_CalFISlopeDisplay
EndIf

Wavestats /Q w
w_MaxFreq[i] = V_max
w_CurrAtMaxFreq[i] = V_maxloc
EndIf

Killwaves /z w_FtRng, FitW
EndFor

End


Function pt_CalHistThresh(wName, k, peak_polarity)
// given a trace with some peaks, calculate the histogram and find the value such that p% of values are above or below that value
String wName
Variable k, peak_polarity
Variable BinWidth, BinStart, NBins

Wave w = $wName
Wavestats /Q w
BinWidth=3.49*V_SDev*V_NPnts^(-1/3)  // D. Scott method
Print BinWidth
BinStart = V_Min
NBins = ceil((V_Max - V_Min) / BinWidth)
Print BinStart, BinWidth, NBins
Make/N=(NBins)/O $wName+"_Hist"
Wave wHist = $wName+"_Hist"
Histogram/CUM/P/B={BinStart, BinWidth, NBins} w, wHist

If (peak_polarity == 1)
	FindLevel /Q wHist, k
Else
	FindLevel /Q wHist, k
EndIf
Return V_LevelX
KillWaves /Z wHist
End


Function pt_CalPercentile(wName, k)//, peak_polarity)
// given a trace with some peaks, calculate the histogram and find the value such that p% of values are above or below that value
String wName
Variable k//, peak_polarity
Variable id

Wave w = $wName
Duplicate /O $wName, $wName+"_SP"
Wave wSrtPer = $wName+"_SP"
Sort wSrtPer, wSrtPer
Wavestats /Q wSrtPer
id = round(k*V_NPnts)
Return wSrtPer[id]
KillWaves /Z wSrtPer
End


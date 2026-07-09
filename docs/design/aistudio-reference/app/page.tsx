'use client';

import * as React from 'react';
import { useState } from 'react';
import { motion } from 'motion/react';
import { ChevronDown, ShieldAlert, HeartPulse, CheckCircle2, ClipboardList, ShieldCheck, Sparkles, HelpCircle } from 'lucide-react';

export default function HomePage() {
  const [isHeroToggleActive, setIsHeroToggleActive] = useState(true);
  const [isSliderActive, setIsSliderActive] = useState(false);
  const [isYellowCircleActive, setIsYellowCircleActive] = useState(true);
  const [openFaqIndex, setOpenFaqIndex] = useState<number | null>(null);

  const scrollToSection = (id: string) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  const faqData = [
    {
      q: "How does RxMind protect my healthcare privacy?",
      a: "RxMind uses an entirely offline-first, on-device architecture. Your prescriptions, symptoms, and vitals are processed and stored strictly in your phone's secure local sandbox. We have zero central servers, meaning your medical data never leaves your device."
    },
    {
      q: "Can I import my hospital discharge instructions?",
      a: "Yes! RxMind allows you to easily photograph or paste your medical discharge papers. Our on-device local engine parses the instructions into simplified, actionable schedules and friendly step-by-step checklists."
    },
    {
      q: "Does it work without an internet connection?",
      a: "Absolutely. RxMind is designed to function fully offline. All recovery plans, medication alerts, and wellness logging features operate seamlessly even during travel or in areas with poor cellular coverage."
    },
    {
      q: "Is RxMind a replacement for professional medical advice?",
      a: "No. RxMind is a recovery assistant designed to help you organize, track, and complete your prescribed post-discharge care plan. Always consult your physician or care team for any clinical decisions."
    }
  ];

  return (
    <div className="min-h-screen bg-white text-[#111827] font-sans selection:bg-indigo-100 overflow-x-hidden">
      
      {/* NAVBAR */}
      <nav className="flex items-center justify-between px-6 md:px-12 py-6 max-w-7xl mx-auto z-50 relative">
        <div className="flex items-center gap-2">
          <div className="text-[#3B82F6] cursor-pointer" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
              <path d="M21 11.5C21 16.1944 16.9706 20 12 20C10.7424 20 9.5441 19.7618 8.44857 19.3323C8.10659 19.198 7.72895 19.2319 7.4116 19.4267L4.54226 21.1873C3.76639 21.6635 2.80216 21.011 2.94639 20.109L3.38575 17.3626C3.4542 16.9348 3.32831 16.5021 3.05374 16.1706C1.7825 14.6366 1 13.149 1 11.5C1 6.80558 5.02944 3 10 3C14.9706 3 19 6.80558 19 11.5Z" />
            </svg>
          </div>
          <span 
            className="font-extrabold text-2xl tracking-tight text-[#111827] cursor-pointer" 
            onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
          >
            rxmind
          </span>
          <div className="w-px h-6 bg-slate-200 mx-4 hidden md:block" />
        </div>

        <div className="hidden md:flex items-center gap-8 text-sm font-semibold text-slate-700">
          <button 
            onClick={() => scrollToSection('features')} 
            className="hover:text-slate-900 transition-colors cursor-pointer bg-transparent border-none p-0 text-slate-600 font-semibold"
          >
            Features
          </button>
          <button 
            onClick={() => scrollToSection('how-it-works')} 
            className="hover:text-slate-900 transition-colors cursor-pointer bg-transparent border-none p-0 text-slate-600 font-semibold"
          >
            How It Works
          </button>
          <button 
            onClick={() => scrollToSection('privacy')} 
            className="hover:text-slate-900 transition-colors cursor-pointer bg-transparent border-none p-0 text-slate-600 font-semibold"
          >
            Privacy First
          </button>
          <button 
            onClick={() => scrollToSection('faq')} 
            className="hover:text-slate-900 transition-colors cursor-pointer bg-transparent border-none p-0 text-slate-600 font-semibold"
          >
            FAQ
          </button>
        </div>

        <div className="flex items-center gap-4 text-sm font-semibold">
          <button 
            onClick={() => scrollToSection('cta')} 
            className="text-slate-700 hover:text-slate-900 hidden sm:block cursor-pointer bg-transparent border-none"
          >
            Login
          </button>
          <button 
            onClick={() => scrollToSection('cta')} 
            className="border border-slate-200 text-slate-800 px-5 py-2 rounded-full hover:bg-slate-50 transition-colors cursor-pointer"
          >
            Get Started
          </button>
        </div>
      </nav>

      {/* HERO SECTION */}
      <section className="relative pt-12 pb-24 md:pt-16 md:pb-32 px-4 flex flex-col items-center justify-center max-w-5xl mx-auto">
      
        {/* Floating background graphics (Kept extremely clean and far out) */}
        <div className="absolute inset-0 pointer-events-none z-0 overflow-visible hidden md:block">
          <motion.div animate={{ y: [0, -10, 0] }} transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }} className="absolute left-[5%] top-[40%] w-8 h-8 opacity-40">
            <svg viewBox="0 0 24 24" fill="none" className="text-[#10B981] drop-shadow-sm">
               <path d="M12 4V20M4 12H20" stroke="currentColor" strokeWidth="6" strokeLinecap="round" />
            </svg>
          </motion.div>
          
          <motion.div animate={{ y: [0, 8, 0], rotate: [0, 5, 0] }} transition={{ duration: 5, repeat: Infinity, ease: "easeInOut", delay: 1 }} className="absolute right-[5%] top-[45%] w-8 h-8 opacity-40">
            <div className="w-8 h-8 bg-[#FBBF24] rounded-full flex items-center justify-center rotate-45 shadow-sm">
               <div className="w-3 h-1 bg-amber-600/30 rounded-full" />
               <div className="w-3 h-1 bg-amber-600/30 rounded-full ml-1" />
            </div>
          </motion.div>
        </div>

        {/* Hero Interactive Text Group */}
        <div className="relative z-10 flex flex-col items-center gap-6 md:gap-8 w-full select-none tracking-tight">
          
          {/* Row 1 */}
          <div className="flex flex-wrap justify-center items-center gap-4 md:gap-6 text-6xl md:text-8xl lg:text-[110px] font-extrabold leading-none">
            <span className="text-slate-900">master</span>
            
            {/* Green Arrow Circle */}
            <motion.div 
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="w-16 h-16 md:w-24 md:h-24 lg:w-28 lg:h-28 rounded-full bg-[#10B981] flex items-center justify-center text-slate-900 cursor-pointer shadow-lg shadow-emerald-500/20"
            >
              <svg width="40%" height="40%" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M5 12h14M12 5l7 7-7 7" />
              </svg>
            </motion.div>

            {/* Gradient Toggle */}
            <div 
              onClick={() => setIsHeroToggleActive(!isHeroToggleActive)}
              className="relative flex items-center shrink-0 cursor-pointer"
            >
              <div className="w-32 h-16 md:w-48 md:h-24 lg:w-56 lg:h-28 rounded-full bg-gradient-to-r from-[#3B82F6] via-[#A855F7] to-[#F43F5E] p-1 md:p-2 transition-all duration-500 shadow-xl shadow-purple-500/10">
                <motion.div 
                  animate={{ x: isHeroToggleActive ? '100%' : '0%' }}
                  style={{ x: isHeroToggleActive ? 'calc(100% - 3.5rem)' : '0px' }}
                  className="w-14 h-14 md:w-20 md:h-20 lg:w-24 lg:h-24 rounded-full bg-white/95 backdrop-blur-sm shadow-[0_8px_16px_rgba(0,0,0,0.1)] flex items-center justify-center relative border border-white/50"
                  transition={{ type: "spring", stiffness: 300, damping: 25 }}
                >
                  <div className="w-8 h-8 md:w-12 md:h-12 rounded-full border-[1.5px] border-slate-200 flex items-center justify-center">
                    <div className="w-1.5 h-1.5 md:w-2.5 md:h-2.5 rounded-full bg-[#3B82F6]" />
                  </div>
                </motion.div>
              </div>
            </div>
          </div>

          {/* Row 2 */}
          <div className="flex flex-wrap justify-center items-center gap-4 md:gap-6 text-6xl md:text-8xl lg:text-[110px] font-extrabold leading-none -mt-2 z-20">
            
            {/* Yellow Circle + Slider */}
            <div className="relative flex items-center shrink-0 h-16 md:h-24 lg:h-28 w-40 md:w-56 lg:w-64">
              <div 
                onClick={() => setIsYellowCircleActive(!isYellowCircleActive)}
                className="absolute left-0 w-16 h-16 md:w-24 md:h-24 lg:w-28 lg:h-28 rounded-full bg-[#FBBF24] flex items-center justify-center cursor-pointer shadow-lg shadow-amber-500/20 z-10"
              >
                <div className="w-3 h-3 md:w-4 md:h-4 rounded-full bg-[#3B82F6] shadow-sm" />
              </div>
              
              <div 
                onClick={() => setIsSliderActive(!isSliderActive)}
                className="absolute left-10 md:left-14 lg:left-16 w-32 md:w-48 lg:w-56 h-12 md:h-16 lg:h-20 bg-white/80 backdrop-blur-md rounded-full shadow-[0_8px_16px_rgba(0,0,0,0.06)] border border-slate-100 flex items-center px-4 md:px-6 cursor-pointer"
              >
                <div className="w-full h-1 bg-slate-900 rounded-full relative">
                  <motion.div 
                    animate={{ x: isSliderActive ? '100%' : '0%' }}
                    style={{ left: isSliderActive ? 'calc(100% - 1rem)' : '0%' }}
                    className="absolute top-1/2 -translate-y-1/2 -ml-2 w-5 h-5 md:w-6 md:h-6 rounded-full bg-[#10B981]"
                    transition={{ type: "spring", stiffness: 300, damping: 25 }}
                  />
                </div>
              </div>
            </div>

            <span className="text-slate-900 ml-4">your</span>

            {/* Icon Pill */}
            <motion.div 
              whileHover={{ y: -5 }}
              className="w-32 h-16 md:w-48 md:h-24 lg:w-56 lg:h-28 bg-white/80 backdrop-blur-md rounded-full shadow-[0_12px_24px_rgba(0,0,0,0.08)] border border-slate-100 flex items-center justify-center gap-2 md:gap-4 px-4 z-20 shrink-0"
            >
              <span className="text-2xl md:text-4xl">💊</span>
              <span className="text-3xl md:text-5xl drop-shadow-md relative">
                ❤️
                <span className="text-xs md:text-sm absolute bottom-0 right-0">🩺</span>
              </span>
            </motion.div>

          </div>

          {/* Row 3 */}
          <div className="flex flex-wrap justify-center items-center gap-4 md:gap-6 text-6xl md:text-8xl lg:text-[110px] font-extrabold leading-none -mt-2 z-30">
            
            {/* Overlapping Circles + Pill */}
            <div className="relative flex items-center justify-center w-32 h-16 md:w-48 md:h-24 lg:w-56 lg:h-28 shrink-0">
              {/* Blurred background circles */}
              <div className="absolute w-16 h-16 md:w-24 md:h-24 lg:w-28 lg:h-28 rounded-full bg-gradient-to-tr from-rose-400 to-purple-500 left-0 md:left-4 shadow-sm opacity-90" />
              <div className="absolute w-16 h-16 md:w-24 md:h-24 lg:w-28 lg:h-28 rounded-full bg-gradient-to-tr from-blue-400 to-cyan-300 right-0 md:right-4 shadow-sm opacity-90" />
              
              {/* Pill foreground containing the classic medical serpent staff */}
              <motion.div 
                whileHover={{ scale: 1.05 }}
                className="w-28 h-10 md:w-40 md:h-12 lg:w-48 lg:h-14 bg-white/95 backdrop-blur-xl rounded-full shadow-[0_8px_16px_rgba(0,0,0,0.1)] border border-white flex items-center justify-center gap-1.5 md:gap-2 relative z-10 cursor-pointer"
              >
                {/* Classic medical serpent staff (Rod of Asclepius) SVG */}
                <svg className="w-4 h-4 md:w-5 md:h-5 text-indigo-600 shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <line x1="12" y1="3" x2="12" y2="21" />
                  <path d="M12 18.5c-3-1-4-3-4-4.5s2-2.5 4-4 4-2.5 4-4-2-2.5-4-3.5" />
                  <circle cx="12" cy="2.5" r="1.2" fill="currentColor" />
                </svg>
                <span className="text-[10px] md:text-sm lg:text-base font-bold text-slate-800 tracking-tight">plan details</span>
              </motion.div>
            </div>

            <span className="text-slate-900">recovery</span>
            
            {/* Heartbeat end SVG */}
            <div className="hidden lg:block ml-2 w-12 lg:w-16">
               <svg viewBox="0 0 50 20" fill="none" stroke="#111827" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round">
                 <path d="M0 10h10l5-8 10 16 5-8h20" />
               </svg>
            </div>
          </div>
        </div>

        {/* Dashed Connecting Lines (Absolute behind everything) */}
        <div className="absolute inset-0 pointer-events-none z-0 hidden lg:block overflow-visible mt-24 max-w-5xl mx-auto">
          <svg className="w-full h-[600px] absolute inset-0" viewBox="0 0 1000 600" fill="none" style={{ overflow: 'visible' }}>
             {/* Yellow to Right Dotted Curve */}
             <path 
               d="M 280 320 Q 280 430 400 420" 
               stroke="#111827" 
               strokeWidth="3.5" 
               strokeDasharray="8,8"
               strokeLinecap="round"
             />
             <polygon points="400,420 390,412 390,428" fill="#3B82F6" />

             {/* Top Right Toggle to Heart Pill Curve */}
             <path 
               d="M 680 180 Q 780 180 750 280" 
               stroke="#111827" 
               strokeWidth="3.5" 
               strokeDasharray="8,8"
               strokeLinecap="round"
             />
             <polygon points="750,280 740,270 760,270" fill="#3B82F6" />
          </svg>
        </div>

        {/* Subtitle & CTAs container - Floating elements placed carefully relative to the box layout to never block text */}
        <div className="relative w-full max-w-4xl mx-auto px-6 mt-20 md:mt-28 z-10">
          
          {/* Tastefully placed floating icons at far left/right boundaries of the layout */}
          <div className="absolute -left-2 xl:-left-12 top-0 w-10 h-10 hidden md:flex items-center justify-center select-none pointer-events-none">
            <svg viewBox="0 0 24 24" fill="currentColor" className="text-[#10B981] w-8 h-8 drop-shadow-sm rotate-12 opacity-80">
              <path d="M19 10h-5V5a2 2 0 0 0-4 0v5H5a2 2 0 0 0 0 4h5v5a2 2 0 0 0 4 0v-5h5a2 2 0 0 0 0-4z" />
            </svg>
          </div>

          <div className="absolute -right-2 xl:-right-12 top-4 text-3xl hidden md:block select-none pointer-events-none -rotate-12 opacity-90 drop-shadow-sm">
            🩹
          </div>

          <div className="absolute left-8 xl:left-0 -bottom-4 w-6 h-6 hidden md:block select-none pointer-events-none">
            <svg viewBox="0 0 24 24" fill="currentColor" className="text-[#3B82F6] opacity-80 w-6 h-6">
              <path d="M12 0L14.6 9.4L24 12L14.6 14.6L12 24L9.4 14.6L0 12L9.4 9.4L12 0Z" />
            </svg>
          </div>

          <div className="absolute right-8 xl:right-0 -bottom-6 w-6 h-6 hidden md:block select-none pointer-events-none">
            <svg viewBox="0 0 24 24" fill="currentColor" className="text-[#93C5FD] opacity-80 w-6 h-6">
              <path d="M12 0L14.6 9.4L24 12L14.6 14.6L12 24L9.4 14.6L0 12L9.4 9.4L12 0Z" />
            </svg>
          </div>

          {/* Actual Subtitle & CTA Buttons (No text blocking, proper margins) */}
          <div className="text-center flex flex-col items-center">
            <p className="text-lg md:text-xl text-slate-600 font-medium leading-relaxed mb-10 px-4 max-w-3xl">
              RxMind simplifies your post-hospital recovery, empowering you with private, on-device recovery plans, smart medication schedules, and supportive progress tracking. 🫶🏼
            </p>
            <div className="flex flex-col sm:flex-row items-center gap-4 z-20">
              <button 
                onClick={() => scrollToSection('cta')}
                className="bg-[#1E1E24] text-white px-8 py-4 rounded-full font-bold text-sm md:text-base hover:bg-black transition-all shadow-lg hover:shadow-xl cursor-pointer"
              >
                Try RxMind for free
              </button>
              <button 
                onClick={() => scrollToSection('how-it-works')}
                className="text-slate-800 font-bold text-sm underline underline-offset-4 hover:text-black transition-colors cursor-pointer bg-transparent border-none py-2 px-4"
              >
                See how it works
              </button>
            </div>
          </div>
        </div>

        {/* Clinical Partners / Logos */}
        <div className="mt-24 md:mt-28 flex flex-col items-center gap-6 w-full px-4">
           <span className="text-xs font-semibold text-slate-400 uppercase tracking-widest">Designed for modern medical standards</span>
           <div className="flex flex-wrap justify-center items-center gap-8 md:gap-16 opacity-30 grayscale max-w-4xl">
              <span className="text-xl md:text-2xl font-bold font-sans tracking-tight">Mayo Clinic</span>
              <span className="text-xl md:text-2xl font-bold uppercase font-sans tracking-wide">Stanford Medicine</span>
              <span className="text-xl md:text-2xl font-bold font-sans flex items-center gap-1.5">
                <div className="w-5 h-5 rounded-full bg-current" /> Johns Hopkins
              </span>
              <span className="text-xl md:text-2xl font-bold lowercase font-sans">Cleveland Clinic</span>
              <span className="text-xl md:text-2xl font-bold font-sans">Cedars-Sinai</span>
           </div>
        </div>

      </section>

      {/* FEATURES SECTION */}
      <section id="features" className="py-24 md:py-32 bg-slate-50 px-4 relative overflow-hidden">
        <div className="max-w-5xl mx-auto text-center">
           <span className="bg-indigo-100 text-indigo-700 font-bold px-4 py-1.5 rounded-full text-xs uppercase tracking-wider mb-6 inline-block">Smarter Home Recovery</span>
           <h2 className="text-4xl md:text-5xl font-extrabold text-slate-900 tracking-tight mb-16 max-w-2xl mx-auto leading-tight">
             Your recovery schedule, fully automated.
           </h2>

           <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-left">
              <motion.div whileHover={{ y: -5 }} className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-100/80 flex flex-col items-start min-h-[300px] justify-between">
                 <div className="w-12 h-12 bg-pink-100 text-pink-600 rounded-full flex items-center justify-center mb-6 shrink-0">
                   <HeartPulse className="w-6 h-6" />
                 </div>
                 <div>
                   <h3 className="text-xl font-bold text-slate-900 mb-3">Smart Prescription Dosing</h3>
                   <p className="text-slate-600 font-medium leading-relaxed text-sm md:text-base">
                     Never miss a vital dose. RxMind orchestrates complex medical regimens with beautifully timed notifications that integrate into your daily life.
                   </p>
                 </div>
              </motion.div>

              <motion.div whileHover={{ y: -5 }} className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-100/80 flex flex-col items-start relative overflow-hidden min-h-[300px] justify-between">
                 <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-50 rounded-full blur-2xl -mr-10 -mt-10 pointer-events-none" />
                 <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mb-6 relative z-10 shrink-0">
                   <CheckCircle2 className="w-6 h-6" />
                 </div>
                 <div className="relative z-10">
                   <h3 className="text-xl font-bold text-slate-900 mb-3">Symptom & Vital Logs</h3>
                   <p className="text-slate-600 font-medium leading-relaxed text-sm md:text-base">
                     Log pain levels, temperature, and recovery vitals with friendly, organic interfaces that make wellness tracking feel refreshing.
                   </p>
                 </div>
              </motion.div>

              <motion.div whileHover={{ y: -5 }} className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-100/80 flex flex-col items-start min-h-[300px] justify-between">
                 <div className="w-12 h-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mb-6 shrink-0">
                   <ClipboardList className="w-6 h-6" />
                 </div>
                 <div>
                   <h3 className="text-xl font-bold text-slate-900 mb-3">Clear Care Regimens</h3>
                   <p className="text-slate-600 font-medium leading-relaxed text-sm md:text-base">
                     Ditch the complex medical jargon. Access structured checklists translated directly from your doctor&apos;s discharge instructions.
                   </p>
                 </div>
              </motion.div>
           </div>
        </div>
      </section>

      {/* HOW IT WORKS / INTERACTIVE SHOWCASE */}
      <section id="how-it-works" className="py-24 md:py-32 px-4 bg-white">
        <div className="max-w-5xl mx-auto flex flex-col md:flex-row items-center gap-16">
          <div className="flex-1 space-y-6">
            <span className="bg-orange-100 text-orange-800 font-bold px-4 py-1.5 rounded-full text-xs uppercase tracking-wider inline-block">Recovery Companion</span>
            <h2 className="text-4xl md:text-5xl font-extrabold text-slate-900 tracking-tight leading-tight">
              Healing doesn&apos;t have to feel like a checklist chore.
            </h2>
            <p className="text-lg text-slate-600 font-medium leading-relaxed">
              We replaced rigid clinical sheets and complex hospital instructions with supportive, interactive tools that celebrate your path to full health. Track daily recovery milestones in a delightful visual dashboard.
            </p>
            <div className="pt-4">
               <button 
                 onClick={() => scrollToSection('cta')}
                 className="bg-slate-900 text-white px-7 py-3 rounded-full font-bold hover:bg-slate-800 transition-colors cursor-pointer"
               >
                 Explore Live App Preview
               </button>
            </div>
          </div>
          
          <div className="flex-1 w-full relative h-[420px]">
             {/* Bubbly decorative layout simulating a mock RxMind companion app interface */}
             <div className="absolute inset-0 bg-gradient-to-tr from-indigo-50 via-blue-50 to-emerald-50 rounded-[3rem] p-8 overflow-hidden shadow-inner flex flex-col justify-center">
               
               <motion.div 
                 animate={{ y: [0, -10, 0] }} 
                 transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }} 
                 className="bg-white/90 backdrop-blur-sm p-5 rounded-[2rem] shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white w-5/6 mb-6 ml-4"
               >
                 <div className="flex items-center gap-3.5 mb-3">
                   <div className="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center text-lg">🏃‍♀️</div>
                   <div>
                     <div className="h-2.5 w-24 bg-slate-200 rounded-full mb-1.5" />
                     <div className="h-2 w-32 bg-slate-100 rounded-full" />
                   </div>
                   <span className="ml-auto text-xs font-bold text-slate-400">9:30 AM</span>
                 </div>
                 <div className="h-2 w-full bg-slate-100 rounded-full overflow-hidden mt-4">
                    <div className="h-full bg-emerald-400 w-3/4 rounded-full" />
                 </div>
                 <div className="flex justify-between items-center mt-3 text-xs font-semibold text-slate-500">
                   <span>Post-Op Stretch</span>
                   <span className="text-emerald-600">75% Completed</span>
                 </div>
               </motion.div>

               <motion.div 
                 animate={{ y: [0, 10, 0] }} 
                 transition={{ duration: 5, repeat: Infinity, ease: "easeInOut", delay: 1 }} 
                 className="bg-white/90 backdrop-blur-sm p-5 rounded-[2rem] shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white w-5/6 float-right mr-4 ml-auto relative"
               >
                 <div className="absolute -top-3 -right-3 w-8 h-8 bg-indigo-500 text-white rounded-full flex items-center justify-center text-xs font-bold shadow-md">
                   +1
                 </div>
                 <div className="flex items-center gap-3.5">
                   <div className="w-10 h-10 rounded-full bg-pink-100 flex items-center justify-center text-lg">💊</div>
                   <div className="flex-1">
                     <div className="h-2.5 w-16 bg-slate-200 rounded-full mb-1.5" />
                     <div className="h-2 w-28 bg-slate-100 rounded-full" />
                   </div>
                   <span className="text-xs font-bold text-pink-600 bg-pink-50 px-2 py-0.5 rounded-full">Next dose</span>
                 </div>
               </motion.div>
             </div>
          </div>
        </div>
      </section>

      {/* PRIVACY FIRST / ON-DEVICE ENGINE */}
      <section id="privacy" className="py-24 md:py-32 px-4 bg-gradient-to-b from-white to-slate-50 relative overflow-hidden">
        <div className="max-w-5xl mx-auto flex flex-col md:flex-row-reverse items-center gap-16">
          <div className="flex-1 space-y-6">
            <span className="bg-emerald-100 text-emerald-800 font-bold px-4 py-1.5 rounded-full text-xs uppercase tracking-wider inline-block">100% On-Device Privacy</span>
            <h2 className="text-4xl md:text-5xl font-extrabold text-slate-900 tracking-tight leading-tight">
              Your health data. Protected locally.
            </h2>
            <p className="text-lg text-slate-600 font-medium leading-relaxed">
              Unlike cloud-hosted solutions that transmit sensitive medication schedules, RxMind processes and stores everything directly on your physical mobile device. No central databases, no tracking, and no medical leaks.
            </p>
            <div className="flex flex-wrap gap-4 pt-2">
              <div className="flex items-center gap-2 bg-white px-4 py-2.5 rounded-full border border-slate-200 shadow-sm text-sm font-semibold text-slate-800">
                <ShieldCheck className="w-4 h-4 text-emerald-500" /> Fully Local Engine
              </div>
              <div className="flex items-center gap-2 bg-white px-4 py-2.5 rounded-full border border-slate-200 shadow-sm text-sm font-semibold text-slate-800">
                <Sparkles className="w-4 h-4 text-emerald-500" /> Secure Device Storage
              </div>
            </div>
          </div>
          
          <div className="flex-1 w-full relative">
             <div className="bg-slate-900 text-slate-100 rounded-[3rem] p-8 md:p-10 shadow-2xl relative overflow-hidden min-h-[380px] flex flex-col justify-between">
                <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none" />
                <div className="flex justify-between items-start relative z-10">
                   <div className="bg-slate-800 p-3 rounded-2xl border border-slate-700">
                     <svg className="w-6 h-6 text-indigo-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                       <path strokeLinecap="round" strokeLinejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                     </svg>
                   </div>
                   <span className="text-xs font-mono text-emerald-400 bg-emerald-400/10 px-3 py-1 rounded-full border border-emerald-500/20">Secure Local Sandbox</span>
                </div>

                <div className="space-y-4 relative z-10 my-8">
                   <div className="text-2xl font-bold tracking-tight">RxMind Sandbox Active</div>
                   <p className="text-sm text-slate-400 leading-relaxed">
                     Our custom medical engine compiles care plans straight inside your browser or mobile device, shielding personal history from third-party lookup APIs.
                   </p>
                </div>

                <div className="flex items-center gap-3 bg-slate-800/50 border border-slate-700/50 p-4 rounded-2xl relative z-10">
                   <div className="w-3 h-3 rounded-full bg-emerald-500 animate-pulse" />
                   <div className="text-xs font-mono text-slate-300">Local database encrypted with AES-256</div>
                </div>
             </div>
          </div>
        </div>
      </section>

      {/* FAQ SECTION */}
      <section id="faq" className="py-24 md:py-32 bg-white px-4">
        <div className="max-w-3xl mx-auto">
          <div className="text-center mb-16">
            <span className="bg-slate-100 text-slate-700 font-bold px-4 py-1.5 rounded-full text-xs uppercase tracking-wider mb-4 inline-block">Frequently Asked Questions</span>
            <h2 className="text-4xl font-extrabold text-slate-900 tracking-tight">Got Questions? We&apos;ve got answers.</h2>
          </div>

          <div className="space-y-4">
            {faqData.map((faq, idx) => {
              const isOpen = openFaqIndex === idx;
              return (
                <div 
                  key={idx} 
                  className="bg-slate-50 border border-slate-100/80 rounded-[2rem] overflow-hidden transition-all duration-300"
                >
                  <button
                    onClick={() => setOpenFaqIndex(isOpen ? null : idx)}
                    className="w-full text-left px-8 py-6 font-bold text-slate-900 flex justify-between items-center gap-4 hover:bg-slate-100/50 transition-colors cursor-pointer"
                  >
                    <span className="text-base md:text-lg flex items-center gap-3">
                      <HelpCircle className="w-5 h-5 text-indigo-500 shrink-0" />
                      {faq.q}
                    </span>
                    <span className={`transform transition-transform duration-300 text-slate-400 shrink-0 ${isOpen ? 'rotate-180' : ''}`}>
                      <ChevronDown className="w-5 h-5" />
                    </span>
                  </button>

                  <div 
                    className={`transition-all duration-300 ease-in-out overflow-hidden ${
                      isOpen ? 'max-h-60 opacity-100 border-t border-slate-200/40' : 'max-h-0 opacity-0'
                    }`}
                  >
                    <div className="px-8 py-6 text-slate-600 font-medium leading-relaxed text-sm md:text-base">
                      {faq.a}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* CALL TO ACTION SECTION */}
      <section id="cta" className="py-24 md:py-32 px-4 bg-slate-50 text-center relative overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-indigo-100/40 rounded-full blur-3xl pointer-events-none" />
        
        <div className="max-w-2xl mx-auto relative z-10 space-y-8">
           <span className="bg-indigo-100 text-indigo-800 font-bold px-4 py-1.5 rounded-full text-xs uppercase tracking-wider inline-block">Join RxMind today</span>
           <h2 className="text-4xl md:text-5xl font-extrabold text-slate-900 tracking-tight leading-tight">
             Take control of your healing process.
           </h2>
           <p className="text-lg text-slate-600 font-medium leading-relaxed">
             Join thousands of patients who master their recovery timeline privately, with 100% on-device local companion toolsets. No sign-ups required to try.
           </p>

           <div className="flex flex-col sm:flex-row justify-center items-center gap-4 pt-4">
              <input 
                type="email" 
                placeholder="Enter your email to receive app link" 
                className="px-6 py-4 rounded-full border border-slate-200 bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 w-full sm:w-80 text-sm md:text-base font-medium"
              />
              <button className="bg-slate-900 text-white px-8 py-4 rounded-full font-bold text-sm md:text-base hover:bg-black transition-all shadow-md hover:shadow-lg w-full sm:w-auto cursor-pointer">
                Get Early Access
              </button>
           </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="bg-white border-t border-slate-100 py-12 px-6">
        <div className="max-w-5xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6 text-sm text-slate-500 font-medium">
          <div className="flex items-center gap-2">
            <div className="text-[#3B82F6]">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path d="M21 11.5C21 16.1944 16.9706 20 12 20C10.7424 20 9.5441 19.7618 8.44857 19.3323C8.10659 19.198 7.72895 19.2319 7.4116 19.4267L4.54226 21.1873C3.76639 21.6635 2.80216 21.011 2.94639 20.109L3.38575 17.3626C3.4542 16.9348 3.32831 16.5021 3.05374 16.1706C1.7825 14.6366 1 13.149 1 11.5C1 6.80558 5.02944 3 10 3C14.9706 3 19 6.80558 19 11.5Z" />
              </svg>
            </div>
            <span className="font-extrabold text-lg text-slate-800 tracking-tight">rxmind</span>
          </div>

          <div className="flex flex-wrap justify-center gap-6 text-slate-400">
            <button onClick={() => scrollToSection('features')} className="hover:text-slate-600 transition-colors cursor-pointer bg-transparent border-none">Features</button>
            <button onClick={() => scrollToSection('how-it-works')} className="hover:text-slate-600 transition-colors cursor-pointer bg-transparent border-none">How It Works</button>
            <button onClick={() => scrollToSection('privacy')} className="hover:text-slate-600 transition-colors cursor-pointer bg-transparent border-none">Privacy Policy</button>
            <button onClick={() => scrollToSection('faq')} className="hover:text-slate-600 transition-colors cursor-pointer bg-transparent border-none">FAQ</button>
          </div>

          <div>
             <span>&copy; 2026 RxMind Inc. All rights reserved.</span>
          </div>
        </div>
      </footer>
    </div>
  );
}

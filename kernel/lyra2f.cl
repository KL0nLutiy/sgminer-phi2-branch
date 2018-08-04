// lyra2 kernel.
// Author: CryptoGraphics ( CrGraphics@protonmail.com )
// Author: fancyIX 2018

#define rotr64(x, n) ((n) < 32 ? (amd_bitalign((uint)((x) >> 32), (uint)(x), (uint)(n)) | ((ulong)amd_bitalign((uint)(x), (uint)((x) >> 32), (uint)(n)) << 32)) : (amd_bitalign((uint)(x), (uint)((x) >> 32), (uint)(n) - 32) | ((ulong)amd_bitalign((uint)((x) >> 32), (uint)(x), (uint)(n) - 32) << 32)))

#define Gfunc(a,b,c,d) \
{ \
    a += b;  \
    d ^= a; \
    ttr = rotr64(d, 32); \
    d = ttr; \
 \
    c += d;  \
    b ^= c; \
    ttr = rotr64(b, 24); \
    b = ttr; \
 \
    a += b;  \
    d ^= a; \
    ttr = rotr64(d, 16); \
    d = ttr; \
 \
    c += d; \
    b ^= c; \
    ttr = rotr64(b, 63); \
    b = ttr; \
}

#define roundLyra(state) \
{ \
     Gfunc(state[0].x, state[2].x, state[4].x, state[6].x); \
     Gfunc(state[0].y, state[2].y, state[4].y, state[6].y); \
     Gfunc(state[1].x, state[3].x, state[5].x, state[7].x); \
     Gfunc(state[1].y, state[3].y, state[5].y, state[7].y); \
 \
     Gfunc(state[0].x, state[2].y, state[5].x, state[7].y); \
     Gfunc(state[0].y, state[3].x, state[5].y, state[6].x); \
     Gfunc(state[1].x, state[3].y, state[4].x, state[6].y); \
     Gfunc(state[1].y, state[2].x, state[4].y, state[7].x); \
}

#define roundLyra_sm(state) \
{ \
    Gfunc(state[0], state[1], state[2], state[3]); \
    smState[lIdx].s0 = state[1]; \
    smState[lIdx].s1 = state[2]; \
    smState[lIdx].s2 = state[3]; \
    barrier(CLK_LOCAL_MEM_FENCE); \
    state[1] = smState[gr4 + ((lIdx+1) & 3)].s0; \
    state[2] = smState[gr4 + ((lIdx+2) & 3)].s1; \
    state[3] = smState[gr4 + ((lIdx+3) & 3)].s2; \
 \
    Gfunc(state[0], state[1], state[2], state[3]); \
 \
    smState[lIdx].s0 = state[1]; \
    smState[lIdx].s1 = state[2]; \
    smState[lIdx].s2 = state[3]; \
    barrier(CLK_LOCAL_MEM_FENCE); \
    state[1] = smState[gr4 + ((lIdx+3) & 3)].s0; \
    state[2] = smState[gr4 + ((lIdx+2) & 3)].s1; \
    state[3] = smState[gr4 + ((lIdx+1) & 3)].s2; \
}

#define loop3p1_iteration(st00,st01,st02, lm20,lm21,lm22) \
{ \
    t0 = state0[st00]; \
    c0 = state1[st00] + t0; \
    state[0] ^= c0; \
\
    t0 = state0[st01]; \
    c0 = state1[st01] + t0; \
    state[1] ^= c0; \
\
    t0 = state0[st02]; \
    c0 = state1[st02] + t0; \
    state[2] ^= c0; \
\
    roundLyra_sm(state); \
\
    state2[0] = state1[st00]; \
    state2[1] = state1[st01]; \
    state2[2] = state1[st02]; \
 \
    state2[0] ^= state[0]; \
    state2[1] ^= state[1]; \
    state2[2] ^= state[2]; \
 \
    lMatrix[lm20] = state2[0]; \
    lMatrix[lm21] = state2[1]; \
    lMatrix[lm22] = state2[2]; \
 \
    smState[lIdx].s0 = state[0]; \
    smState[lIdx].s1 = state[1]; \
    smState[lIdx].s2 = state[2]; \
    ulong Data0 = smState[gr4 + ((lIdx-1) & 3)].s0; \
    ulong Data1 = smState[gr4 + ((lIdx-1) & 3)].s1; \
    ulong Data2 = smState[gr4 + ((lIdx-1) & 3)].s2; \
    if((lIdx&3) == 0) \
    { \
        state0[st01] ^= Data0; \
        state0[st02] ^= Data1; \
        state0[st00] ^= Data2; \
    } \
    else \
    { \
        state0[st00] ^= Data0; \
        state0[st01] ^= Data1; \
        state0[st02] ^= Data2; \
    } \
 \
    lMatrix[st00] = state0[st00]; \
    lMatrix[st01] = state0[st01]; \
    lMatrix[st02] = state0[st02]; \
 \
    state0[st00] = state2[0]; \
    state0[st01] = state2[1]; \
    state0[st02] = state2[2]; \
}

#define loop3p2_iteration(st00,st01,st02, st10,st11,st12, lm30,lm31,lm32, lm10,lm11,lm12) \
{ \
    t0 = state1[st00]; \
    c0 = state0[st10] + t0; \
    state[0] ^= c0; \
 \
    t0 = state1[st01]; \
    c0 = state0[st11] + t0; \
    state[1] ^= c0; \
 \
    t0 = state1[st02]; \
    c0 = state0[st12] + t0; \
    state[2] ^= c0; \
\
    roundLyra_sm(state); \
 \
    state0[st10] ^= state[0]; \
    state0[st11] ^= state[1]; \
    state0[st12] ^= state[2]; \
 \
    lMatrix[lm30] = state0[st10]; \
    lMatrix[lm31] = state0[st11]; \
    lMatrix[lm32] = state0[st12]; \
 \
    smState[lIdx].s0 = state[0]; \
    smState[lIdx].s1 = state[1]; \
    smState[lIdx].s2 = state[2]; \
    ulong Data0 = smState[gr4 + ((lIdx-1) & 3)].s0; \
    ulong Data1 = smState[gr4 + ((lIdx-1) & 3)].s1; \
    ulong Data2 = smState[gr4 + ((lIdx-1) & 3)].s2; \
    if((lIdx&3) == 0) \
    { \
        state1[st01] ^= Data0; \
        state1[st02] ^= Data1; \
        state1[st00] ^= Data2; \
    } \
    else \
    { \
        state1[st00] ^= Data0; \
        state1[st01] ^= Data1; \
        state1[st02] ^= Data2; \
    } \
 \
    lMatrix[lm10] = state1[st00]; \
    lMatrix[lm11] = state1[st01]; \
    lMatrix[lm12] = state1[st02]; \
}


#define wanderIteration_orig(prv00,prv01,prv02, rng00,rng01,rng02, rng10,rng11,rng12, rng20,rng21,rng22, rng30,rng31,rng32, rou00,rou01,rou02) \
{ \
    a_state1_0 = lMatrix[prv00]; \
    a_state1_1 = lMatrix[prv01]; \
    a_state1_2 = lMatrix[prv02]; \
 \
    b0 = (rowa < 4)? lMatrix[rng00]: lMatrix[rng20]; \
    b1 = (rowa < 4)? lMatrix[rng10]: lMatrix[rng30]; \
    a_state2_0 = ((rowa & 0x1U) < 1)? b0: b1; \
 \
 \
    b0 = (rowa < 4)? lMatrix[rng01]: lMatrix[rng21]; \
    b1 = (rowa < 4)? lMatrix[rng11]: lMatrix[rng31]; \
    a_state2_1 = ((rowa & 0x1U) < 1)? b0: b1; \
 \
 \
    b0 = (rowa < 4)? lMatrix[rng02]: lMatrix[rng22]; \
    b1 = (rowa < 4)? lMatrix[rng12]: lMatrix[rng32]; \
    a_state2_2 = ((rowa & 0x1U) < 1)? b0: b1; \
 \
    t0 = a_state1_0; \
    c0 = a_state2_0 + t0; \
    state[0] ^= c0; \
 \
    t0 = a_state1_1; \
    c0 = a_state2_1 + t0; \
    state[1] ^= c0; \
 \
    t0 = a_state1_2; \
    c0 = a_state2_2 + t0; \
    state[2] ^= c0; \
 \
    roundLyra_sm(state); \
 \
    smState[lIdx].s0 = state[0]; \
    smState[lIdx].s1 = state[1]; \
    smState[lIdx].s2 = state[2]; \
 \
    a_state1_0 = smState[gr4 + ((lIdx-1) & 3)].s0; \
    a_state1_1 = smState[gr4 + ((lIdx-1) & 3)].s1; \
    a_state1_2 = smState[gr4 + ((lIdx-1) & 3)].s2; \
    if((lIdx&3) == 0) \
    { \
        a_state2_1 ^= a_state1_0; \
        a_state2_2 ^= a_state1_1; \
        a_state2_0 ^= a_state1_2; \
    } \
    else \
    { \
        a_state2_0 ^= a_state1_0; \
        a_state2_1 ^= a_state1_1; \
        a_state2_2 ^= a_state1_2; \
    } \
 \
    if(rowa == 0) \
    { \
        lMatrix[rng00] = a_state2_0; \
        lMatrix[rng01] = a_state2_1; \
        lMatrix[rng02] = a_state2_2; \
    } \
    if(rowa == 1) \
    { \
        lMatrix[rng10] = a_state2_0; \
        lMatrix[rng11] = a_state2_1; \
        lMatrix[rng12] = a_state2_2; \
    } \
    if(rowa == 2) \
    { \
        lMatrix[rng20] = a_state2_0; \
        lMatrix[rng21] = a_state2_1; \
        lMatrix[rng22] = a_state2_2; \
    } \
    if(rowa == 3) \
    { \
        lMatrix[rng30] = a_state2_0; \
        lMatrix[rng31] = a_state2_1; \
        lMatrix[rng32] = a_state2_2; \
    } \
 \
    lMatrix[rou00] ^= state[0]; \
    lMatrix[rou01] ^= state[1]; \
    lMatrix[rou02] ^= state[2]; \
}

/*
#define wanderIteration(prv00,prv01,prv02, rng00,rng01,rng02, rng10,rng11,rng12, rng20,rng21,rng22, rng30,rng31,rng32, rng40,rng41,rng42, rng50,rng51,rng52, rng60,rng61,rng62, rng70,rng71,rng72, rou00,rou01,rou02) \
{ \
    a_state1_0 = state0[prv00 % 24]; \
    a_state1_1 = state0[prv01 % 24]; \
    a_state1_2 = state0[prv02 % 24]; \
 \
    if (rowa == 0) { \
        a_state2_0 = lMatrix[rng00]; \
    } else if (rowa == 1) { \
        a_state2_0 = lMatrix[rng10]; \
    } else if (rowa == 2) { \
        a_state2_0 = lMatrix[rng20]; \
    } else if (rowa == 3) { \
        a_state2_0 = lMatrix[rng30]; \
    } else if (rowa == 4) { \
        a_state2_0 = lMatrix[rng40]; \
    } else if (rowa == 5) { \
        a_state2_0 = lMatrix[rng50]; \
    } else if (rowa == 6) { \
        a_state2_0 = lMatrix[rng60]; \
    } else if (rowa == 7) { \
        a_state2_0 = lMatrix[rng70]; \
    } \
 \
    if (rowa == 0) { \
        a_state2_1 = lMatrix[rng01]; \
    } else if (rowa == 1) { \
        a_state2_1 = lMatrix[rng11]; \
    } else if (rowa == 2) { \
        a_state2_1 = lMatrix[rng21]; \
    } else if (rowa == 3) { \
        a_state2_1 = lMatrix[rng31]; \
    } else if (rowa == 4) { \
        a_state2_1 = lMatrix[rng41]; \
    } else if (rowa == 5) { \
        a_state2_1 = lMatrix[rng51]; \
    } else if (rowa == 6) { \
        a_state2_1 = lMatrix[rng61]; \
    } else if (rowa == 7) { \
        a_state2_1 = lMatrix[rng71]; \
    } \
\
    if (rowa == 0) { \
        a_state2_2 = lMatrix[rng02]; \
    } else if (rowa == 1) { \
        a_state2_2 = lMatrix[rng12]; \
    } else if (rowa == 2) { \
        a_state2_2 = lMatrix[rng22]; \
    } else if (rowa == 3) { \
        a_state2_2 = lMatrix[rng32]; \
    } else if (rowa == 4) { \
        a_state2_2 = lMatrix[rng42]; \
    } else if (rowa == 5) { \
        a_state2_2 = lMatrix[rng52]; \
    } else if (rowa == 6) { \
        a_state2_2 = lMatrix[rng62]; \
    } else if (rowa == 7) { \
        a_state2_2 = lMatrix[rng72]; \
    } \
\
    t0 = a_state1_0; \
    c0 = a_state2_0 + t0; \
    state[0] ^= c0; \
\
    t0 = a_state1_1; \
    c0 = a_state2_1 + t0; \
    state[1] ^= c0; \
 \
    t0 = a_state1_2; \
    c0 = a_state2_2 + t0; \
    state[2] ^= c0; \
 \
    roundLyra_sm(state); \
    smState[lIdx].s0 = state[0]; \
    smState[lIdx].s1 = state[1]; \
    smState[lIdx].s2 = state[2]; \
    barrier(CLK_LOCAL_MEM_FENCE); \
    a_state1_0 = smState[gr4 + ((lIdx-1) & 3)].s0; \
    a_state1_1 = smState[gr4 + ((lIdx-1) & 3)].s1; \
    a_state1_2 = smState[gr4 + ((lIdx-1) & 3)].s2; \
 \
    if(rowa == 0) \
    { \
        lMatrix[rng00] = a_state2_0; \
        lMatrix[rng01] = a_state2_1; \
        lMatrix[rng02] = a_state2_2; \
        lMatrix[rng00] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng01] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng02]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 1) \
    { \
        lMatrix[rng10] = a_state2_0; \
        lMatrix[rng11] = a_state2_1; \
        lMatrix[rng12] = a_state2_2; \
        lMatrix[rng10] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng11] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng12]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 2) \
    { \
        lMatrix[rng20] = a_state2_0; \
        lMatrix[rng21] = a_state2_1; \
        lMatrix[rng22] = a_state2_2; \
        lMatrix[rng20] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng21] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng22]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 3) \
    { \
        lMatrix[rng30] = a_state2_0; \
        lMatrix[rng31] = a_state2_1; \
        lMatrix[rng32] = a_state2_2; \
        lMatrix[rng30] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng31] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng32]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 4) \
    { \
        lMatrix[rng40] = a_state2_0; \
        lMatrix[rng41] = a_state2_1; \
        lMatrix[rng42] = a_state2_2; \
        lMatrix[rng40] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng41] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng42]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 5) \
    { \
        lMatrix[rng50] = a_state2_0; \
        lMatrix[rng51] = a_state2_1; \
        lMatrix[rng52] = a_state2_2; \
        lMatrix[rng50] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng51] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng52]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 6) \
    { \
        lMatrix[rng60] = a_state2_0; \
        lMatrix[rng61] = a_state2_1; \
        lMatrix[rng62] = a_state2_2; \
        lMatrix[rng60] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng61] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng62]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 7) \
    { \
        lMatrix[rng70] = a_state2_0; \
        lMatrix[rng71] = a_state2_1; \
        lMatrix[rng72] = a_state2_2; \
        lMatrix[rng70] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng71] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng72]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
 \
    state0[rou00 % 24] = lMatrix[rou00]; \
    state0[rou01 % 24] = lMatrix[rou01]; \
    state0[rou02 % 24] = lMatrix[rou02]; \
    state0[rou00 % 24] ^= state[0]; \
    state0[rou01 % 24] ^= state[1]; \
    state0[rou02 % 24] ^= state[2]; \
    lMatrix[rou00] = state0[rou00 % 24]; \
    lMatrix[rou01] = state0[rou01 % 24]; \
    lMatrix[rou02] = state0[rou02 % 24]; \
}

#define wanderIterationP2(rin00,rin01,rin02, rng00,rng01,rng02, rng10,rng11,rng12, rng20,rng21,rng22, rng30,rng31,rng32, rng40,rng41,rng42, rng50,rng51,rng52, rng60,rng61,rng62, rng70,rng71,rng72) \
{ \
    t0 = lMatrix[rin00]; \
    if (rowa == 0) { \
        c0 = lMatrix[rng00]; \
    } else if (rowa == 1) { \
        c0 = lMatrix[rng10]; \
    } else if (rowa == 2) { \
        c0 = lMatrix[rng20]; \
    } else if (rowa == 3) { \
        c0 = lMatrix[rng30]; \
    } else if (rowa == 4) { \
        c0 = lMatrix[rng40]; \
    } else if (rowa == 5) { \
        c0 = lMatrix[rng50]; \
    } else if (rowa == 6) { \
        c0 = lMatrix[rng60]; \
    } else if (rowa == 7) { \
        c0 = lMatrix[rng70]; \
    } \
    t0+=c0; \
    state[0] ^= t0; \
 \
    t0 = lMatrix[rin01]; \
    if (rowa == 0) { \
        c0 = lMatrix[rng01]; \
    } else if (rowa == 1) { \
        c0 = lMatrix[rng11]; \
    } else if (rowa == 2) { \
        c0 = lMatrix[rng21]; \
    } else if (rowa == 3) { \
        c0 = lMatrix[rng31]; \
    } else if (rowa == 4) { \
        c0 = lMatrix[rng41]; \
    } else if (rowa == 5) { \
        c0 = lMatrix[rng51]; \
    } else if (rowa == 6) { \
        c0 = lMatrix[rng61]; \
    } else if (rowa == 7) { \
        c0 = lMatrix[rng71]; \
    } \
    t0+=c0; \
    state[1] ^= t0; \
 \
    t0 = lMatrix[rin02]; \
    if (rowa == 0) { \
        c0 = lMatrix[rng02]; \
    } else if (rowa == 1) { \
        c0 = lMatrix[rng12]; \
    } else if (rowa == 2) { \
        c0 = lMatrix[rng22]; \
    } else if (rowa == 3) { \
        c0 = lMatrix[rng32]; \
    } else if (rowa == 4) { \
        c0 = lMatrix[rng42]; \
    } else if (rowa == 5) { \
        c0 = lMatrix[rng52]; \
    } else if (rowa == 6) { \
        c0 = lMatrix[rng62]; \
    } else if (rowa == 7) { \
        c0 = lMatrix[rng72]; \
    } \
    t0+=c0; \
    state[2] ^= t0; \
 \
    roundLyra_sm(state); \
}
*/



#define wanderIteration(prv00,prv01,prv02, rng00,rng01,rng02, rng10,rng11,rng12, rng20,rng21,rng22, rng30,rng31,rng32, rng40,rng41,rng42, rng50,rng51,rng52, rng60,rng61,rng62, rng70,rng71,rng72, rou00,rou01,rou02) \
{ \
    a_state1_0 = lMatrix[prv00]; \
    a_state1_1 = lMatrix[prv01]; \
    a_state1_2 = lMatrix[prv02]; \
 \
    b0 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng00]: lMatrix[rng20]) : ((rowa < 6) ? lMatrix[rng40]: lMatrix[rng60]); \
    b1 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng10]: lMatrix[rng30]) : ((rowa < 6) ? lMatrix[rng50]: lMatrix[rng70]); \
    a_state2_0 = ((rowa & 0x1U) < 1)? b0: b1; \
 \
    b0 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng01]: lMatrix[rng21]) : ((rowa < 6) ? lMatrix[rng41]: lMatrix[rng61]); \
    b1 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng11]: lMatrix[rng31]) : ((rowa < 6) ? lMatrix[rng51]: lMatrix[rng71]); \
    a_state2_1 = ((rowa & 0x1U) < 1)? b0: b1; \
\
    b0 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng02]: lMatrix[rng22]) : ((rowa < 6) ? lMatrix[rng42]: lMatrix[rng62]); \
    b1 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng12]: lMatrix[rng32]) : ((rowa < 6) ? lMatrix[rng52]: lMatrix[rng72]); \
    a_state2_2 = ((rowa & 0x1U) < 1)? b0: b1; \
\
    t0 = a_state1_0; \
    c0 = a_state2_0 + t0; \
    state[0] ^= c0; \
\
    t0 = a_state1_1; \
    c0 = a_state2_1 + t0; \
    state[1] ^= c0; \
 \
    t0 = a_state1_2; \
    c0 = a_state2_2 + t0; \
    state[2] ^= c0; \
 \
    roundLyra_sm(state); \
    smState[lIdx].s0 = state[0]; \
    smState[lIdx].s1 = state[1]; \
    smState[lIdx].s2 = state[2]; \
    barrier(CLK_LOCAL_MEM_FENCE); \
    a_state1_0 = smState[gr4 + ((lIdx-1) & 3)].s0; \
    a_state1_1 = smState[gr4 + ((lIdx-1) & 3)].s1; \
    a_state1_2 = smState[gr4 + ((lIdx-1) & 3)].s2; \
 \
    if(rowa == 0) \
    { \
        lMatrix[rng00] = a_state2_0; \
        lMatrix[rng01] = a_state2_1; \
        lMatrix[rng02] = a_state2_2; \
        lMatrix[rng00] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng01] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng02]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 1) \
    { \
        lMatrix[rng10] = a_state2_0; \
        lMatrix[rng11] = a_state2_1; \
        lMatrix[rng12] = a_state2_2; \
        lMatrix[rng10] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng11] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng12]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 2) \
    { \
        lMatrix[rng20] = a_state2_0; \
        lMatrix[rng21] = a_state2_1; \
        lMatrix[rng22] = a_state2_2; \
        lMatrix[rng20] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng21] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng22]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 3) \
    { \
        lMatrix[rng30] = a_state2_0; \
        lMatrix[rng31] = a_state2_1; \
        lMatrix[rng32] = a_state2_2; \
        lMatrix[rng30] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng31] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng32]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 4) \
    { \
        lMatrix[rng40] = a_state2_0; \
        lMatrix[rng41] = a_state2_1; \
        lMatrix[rng42] = a_state2_2; \
        lMatrix[rng40] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng41] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng42]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 5) \
    { \
        lMatrix[rng50] = a_state2_0; \
        lMatrix[rng51] = a_state2_1; \
        lMatrix[rng52] = a_state2_2; \
        lMatrix[rng50] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng51] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng52]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 6) \
    { \
        lMatrix[rng60] = a_state2_0; \
        lMatrix[rng61] = a_state2_1; \
        lMatrix[rng62] = a_state2_2; \
        lMatrix[rng60] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng61] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng62]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
    if(rowa == 7) \
    { \
        lMatrix[rng70] = a_state2_0; \
        lMatrix[rng71] = a_state2_1; \
        lMatrix[rng72] = a_state2_2; \
        lMatrix[rng70] ^=((lIdx&3) == 0)?a_state1_2:a_state1_0; \
        lMatrix[rng71] ^=((lIdx&3) == 0)?a_state1_0:a_state1_1; \
        lMatrix[rng72]^=((lIdx&3) == 0)?a_state1_1:a_state1_2; \
    } \
 \
    lMatrix[rou00] ^= state[0]; \
    lMatrix[rou01] ^= state[1]; \
    lMatrix[rou02] ^= state[2]; \
}

#define wanderIterationP2(rin00,rin01,rin02, rng00,rng01,rng02, rng10,rng11,rng12, rng20,rng21,rng22, rng30,rng31,rng32, rng40,rng41,rng42, rng50,rng51,rng52, rng60,rng61,rng62, rng70,rng71,rng72) \
{ \
    t0 = lMatrix[rin00]; \
    b0 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng00]: lMatrix[rng20]) : ((rowa < 6) ? lMatrix[rng40]: lMatrix[rng60]); \
    b1 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng10]: lMatrix[rng30]) : ((rowa < 6) ? lMatrix[rng50]: lMatrix[rng70]); \
    c0 = ((rowa & 0x1U) < 1)? b0: b1; \
    t0+=c0; \
    state[0] ^= t0; \
 \
    t0 = lMatrix[rin01]; \
    b0 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng01]: lMatrix[rng21]) : ((rowa < 6) ? lMatrix[rng41]: lMatrix[rng61]); \
    b1 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng11]: lMatrix[rng31]) : ((rowa < 6) ? lMatrix[rng51]: lMatrix[rng71]); \
    c0 = ((rowa & 0x1U) < 1)? b0: b1; \
    t0+=c0; \
    state[1] ^= t0; \
 \
    t0 = lMatrix[rin02]; \
    b0 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng02]: lMatrix[rng22]) : ((rowa < 6) ? lMatrix[rng42]: lMatrix[rng62]); \
    b1 = (rowa < 4)? ((rowa < 2) ? lMatrix[rng12]: lMatrix[rng32]) : ((rowa < 6) ? lMatrix[rng52]: lMatrix[rng72]); \
    c0 = ((rowa & 0x1U) < 1)? b0: b1; \
    t0+=c0; \
    state[2] ^= t0; \
 \
    roundLyra_sm(state); \
}





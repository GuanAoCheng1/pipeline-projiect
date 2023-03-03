function f!(F, A)
    # T = [ 333; 331]
    k = 0#方程和节点数混淆
    T0=278.15#土壤温度
    dt = 10#s
    dx = 10000#m总长50，节点数
    γ11 = dt / dx
    D = 1.112#外径
    Ke=0.017#粗糙度mm
    λ=1/(-2*log10(Ke/(3.7*D*1000)))^2
    CRXS = 1.15#传热
    d = 0.998
    bc = π * d^2 / 4#管道截面积
#------------------------------------------------总连续性方程（2个管段）（2个方程）--------------------------------
    for j in 1:2:2#m是单位面积上的质量流量，密度单位为kg/m^3
        k = k + 1
        F[k] = A[j, 4] + A[j+1, 4] - md[j] - md[j+1] + γ11 * (M[j+1] - M[j] + A[j+1, 3] - A[j, 3]) / bc
    end
#-------------------------------------------------动量方程（2个管段）压力单位是Pa（2个方程）--------------------------------
    for j in 1:2:2#
        k = k + 1
        F[k] = (A[j, 3] + A[j+1, 3] - M[j+1] - M[j]) / bc + γ11 * ((A[j+1, 3] / bc)^2 / A[j+1, 4] + A[j+1, 1] * 10^6 - (A[j, 3] / bc)^2 / A[j, 4] -
                A[j, 1] * 10^6 + (M[j+1] / bc)^2 / md[j+1] + P[j+1] * 10^6 - (M[j] / bc)^2 / md[j] - P[j] * 10^6) +
               dt * λ / 4 / d * ((A[j+1, 3] / bc)^2 / A[j+1, 4] + (A[j, 3] / bc)^2 /
                A[j, 4] + (M[j+1] / bc)^2 / md[j+1] + (M[j] / bc)^2 / md[j])
        #+dt*g*ds/dx*(A[j+1,4]+A[j,4]+md[j+1,t_s]+md[j,t_s])#高程不用考虑ds     
    end
#------------------------------------------------能量方程（2个管段）（2个方程）(T0为土壤温度)----------------------------------
    for j in 1:2:2
        k = k + 1
        F[k] = A[j, 5] * A[j, 4] - A[j, 1] * 10^6 + (A[j, 3] / bc)^2 / 2 / A[j, 4] - h[j] * md[j] + P[j] * 10^6 - (M[j] / bc)^2 / 2 / md[j] + A[j+1, 5] * A[j+1, 4] -
               A[j+1, 1] * 10^6 + (A[j+1, 3] / bc)^2 / 2 / A[j+1, 4] - h[j+1] * md[j+1] + P[j+1] * 10^6 - M[j+1]^2 / 2 / md[j+1] + γ11 * (A[j+1, 5] * (A[j+1, 3] / bc) +
               (A[j+1, 3] / bc)^3 / 2 / (A[j+1, 4])^2 - A[j, 4] * (A[j, 3] / bc) - (A[j, 3] / bc)^3 / 2 / A[j, 4]^2 + h[j+1] * (M[j+1] / bc) + (M[j+1] / bc)^3 / 2 / md[j+1]^2 -
                h[j] * (M[j] / bc) - (M[j] / bc)^3 / 2 / md[j]^2) +
               2 * CRXS * dt / D * (A[j+1, 2] + A[j, 2] + T[j] + T[j+1] - 4 * T0) #+ g * dt * ds / 2 / dx * (A[j+1, 3] + A[j, 3] + M[j] + M[j+1])
    end
#----------------------------------------------状态方程（采用bwrs方程来计算）-一些参数 ---------------------------------------
    A1=[0.443690 1.284380 0.356306 0.544979 0.528629 0.484011 0.0705233 0.5040870 0.0307452 0.0732828 0.0064500]
    B=[0.115449 -0.920731 1.70871 -0.270896 0.349261 0.754130 -0.044448 1.32245 0.179433 0.463492 -0.022143]
    w=[0.0 0.013 0.101 0.1018 0.15 0.157 0.183 0.197 0.226 0.252 0.302 0.353 0.412 0.475 0.54 0.6 0.035 0.21 1.105 ]#偏心因子
    row=[15.579 10.05 8.0653 6.7566 5.5248 4.9994 3.8012 3.9213 3.2469 3.2149 2.7167 2.3467 2.0568 1.8421 1.6611 1.5154 11.099 10.638 10.526 ]#临界密度
    T=[32.98 190.69 283.05 305.38 365.04 369.89 408.13 425.18 460.37 469.49 507.28 540.28 568.58 594.57 617.54 639.99 126.15 304.09 373.39 ]#临界温度
    μ=[2.01588 16.042 28.05 30.068 42.08 44.094 58.12 58.12 72.146 72.0146 86.172 100.198 114.224 178.25 142.276 156.3 28.016 44.01 34.076 ]#各组分相对分子质量
    H_A = [28.672 135.84210 0 379.2766 0  385.4736 377.0006 382.4968 393.1319 403.4701 309.809 312.0396 303.7124 294.7414 275.4521 0 -2.17251 11.11374 -1.43705 ]
    H_B = [13.39616 2.39359  0  1.10899 0   0.72265  0.19545  0.4127  -0.1319  -0.0117  0.95923  0.7545  0.72467  0.7078  0.85137  0 1.06849  0.47911  0.99887  ]
    H_C1 = [29.60131 -22.18007 0  -1.88512 0   7.08716  25.23143  20.28601  35.41155  33.16498  -6.14724  2.61728  3.67845  4.38048  -2.063041  0   -1.34096  7.62195  -1.84315  ]
    H_C = [i*10^-4 for i in H_C1]
    H_D1 = [-39.80745 57.4022  0 39.6558  0  29.23895  1.95651  7.02953  -13.33225  -11.7051  61.42103  43.66359  41.42833  39.69342  55.21815  0  2.15569  -3.59392  5.57088  ]
    H_D = [i*10^-7 for i in H_D1]
    H_E1 = [266.1667 -372.79 0  -314.0209 0   -261.5071  -77.26149  -102.5871  25.14633  19.96476  -616.0952  -448.4511  -424.0198  -404.3158  -563.1732  0  -7.86319  8.47438  -31.77336  ]
    H_E = [i*10^-11 for i in H_E1]
    H_F1 = [-60.99862 85.49685  0  80.08189  0  70.00448  23.86087  28.83394  -1.29589  -0.86652  208.6819  148.421  137.3406  128.7595  188.8545  0 0.69851  -0.57752  6.36644  ]
    H_F = [i*10^-14 for i in H_F1]
    K=[0 0 0.01 0.01 0.021 0.023 0.0275 0.031 0.036 0.041 0.05 0.06 0.07 0.081 0.092 0.101 0.025 0.05 0.05;
       0 0 0 0 0.003 0.0031 0.004 0.0045 0.005 0.006 0.007 0.0085 0.01 0.012 0.013 0.015 0.07 0.048 0.045;#对齐
       0 0 0 0 0.003 0.0031 0.004 0.0045 0.005 0.006 0.007 0.0085 0.01 0.012 0.013 0.015 0.07 0.048 0.045;
       0 0 0 0 0 0 0.003 0.0035 0.004 0.0045 0.005 0.0065 0.008 0.01 0.011 0.013 0.1 0.045 0.04;
       0 0 0 0 0 0 0.003 0.0035 0.004 0.0045 0.005 0.0065 0.008 0.01 0.011 0.013 0.1 0.045 0.04;
       0 0 0 0 0 0 0 0 0.008 0.001 0.0015 0.0018 0.002 0.0025 0.003 0.003 0.11 0.05 0.036;
       0 0 0 0 0 0 0 0 0.008 0.001 0.0015 0.0018 0.002 0.0025 0.003 0.003 0.12 0.05 0.034;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.134 0.05 0.028;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.148 0.05 0.02;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.172 0.05 0;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.2 0.05 0;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.228 0.05 0;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.264 0.05 0;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.204 0.05 0;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.322 0.05 0;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.035;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;]
#-----------------------------------状态方程求解------------------------------------------------------------------------
    for j in 1:2
        k=k+1
        zf=[A[j,6] A[j,7]  0  A[j,8]  0  A[j,9]  0  0  0  0  0  0  0  0  0  0  A[j,10]  A[j,11]  0  ]
        B0=Array{Float64}(undef,1,length(zf))
        A0=Array{Float64}(undef,1,length(zf))
        c=Array{Float64}(undef,1,length(zf))
        C0=Array{Float64}(undef,1,length(zf))
        D0=Array{Float64}(undef,1,length(zf))
        E0=Array{Float64}(undef,1,length(zf))
        a=Array{Float64}(undef,1,length(zf))
        b=Array{Float64}(undef,1,length(zf))
        d=Array{Float64}(undef,1,length(zf))
        α=Array{Float64}(undef,1,length(zf))
        γ=Array{Float64}(undef,1,length(zf))
        R=8.3143#j/kg/k
    #----------------------------------------求单一物质公式--------------------------------------------
    for i in 1:length(zf)
        B0[i]=(A1[1]+B[1]*w[i])/row[i]
        A0[i]=(A1[2]+B[2]*w[i])*R*T[i]/row[i]
        C0[i]=(A1[3]+B[3]*w[i])*R*(T[i])^3/row[i]
        D0[i]=(A1[9]+B[9]*w[i])*R*(T[i])^4/row[i]
        γ[i]=(A1[4]+B[4]*w[i])/(row[i])^2
        b[i]=(A1[5]+B[5]*w[i])/(row[i])^2
        a[i]=(A1[6]+B[6]*w[i])*R*(T[i])/(row[i])^2
        c[i]=(A1[8]+B[8]*w[i])*R*(T[i])^3/(row[i])^2
        d[i]=(A1[10]+B[10]*w[i])*R*(T[i])^2/(row[i])^2
        α[i]=(A1[7]+B[7]*w[i])/(row[i])^3
        E0[i]=(A1[11]+B[11]*w[i]*exp(-3.8*w[i]))*R*(T[i]^5)/row[i]
    end
    #-------------------------------------------混合物的相关参数------------------------------------
    A0H=0
    B0H=0#变量位置
    C0H=0
    D0H=0
    E0H=0
    ah1=0
    bh1=0
    ch1=0
    dh1=0
    αh1=0
    γh1=0
    ah=0
    bh=0
    ch=0
    dh=0
    αh=0
    γh=0
    μ0=0
    for i in 1:length(zf)
        μ0+=zf[i]*μ[i]
    end
    for i in 1:length(zf)#对齐（快捷键）
        for m in 1:length(zf)
            A0H+=zf[i]*zf[m]*((A0[i])^(0.5))*((A0[m])^(0.5))*(1-K[i,m])#xy
            C0H=zf[i]*zf[m]*((C0[i])^(0.5))*((C0[m])^(0.5))*(1-K[i,m])^3+C0H
            D0H=zf[i]*zf[m]*((D0[i])^(0.5))*((D0[m])^(0.5))*(1-K[i,m])^4+D0H
            E0H=zf[i]*zf[m]*((E0[i])^(0.5))*((E0[m])^(0.5))*(1-K[i,m])^5+E0H
        end
    end
    for i in 1:length(zf)
        ah1+=zf[i]*a[i]^(1/3)
        bh1=(zf[i]*(b[i])^(1/3)+bh1)
        ch1=(zf[i]*(c[i])^(1/3)+ch1)
        dh1=(zf[i]*(d[i])^(1/3)+dh1)
        γh1=(zf[i]*(γ[i])^(1/2)+γh1)
        αh1=(zf[i]*(α[i])^(1/3)+αh1)
        B0H=zf[i]*B0[i]+B0H
    end
    ah=ah1^3
    bh=bh1^3
    ch=ch1^3
    dh=dh1^3
    αh=αh1^3
    γh=γh1^2
    F[k]=(A[j,4]/μ0*R*A[j,2]+(B0H*R*A[j,2]-A0H-C0H/A[j,2]^2+D0H/A[j,2]^3-E0H/A[j,2]^4)*(A[j,4]/μ0)^2)+(bh*R*A[j,2]-
        ah-dh/A[j,2])*(A[j,4]/μ0)^3+αh*(ah+dh/A[j,2])*(A[j,4]/μ0)^6+ch*(A[j,4]/μ0)^3/A[j,2]^2*(1+γh*(A[j,4]/μ0)^2)*
        exp(-γh*(A[j,4]/μ0)^2)-A[j,1]*1000
    end
#--------------------------------------晗的求解（bwrs方程求解）---------------------------------
    for j in 1:2
        k=k+1
        zf=[A[j,6] A[j,7]  0  A[j,8]  0  A[j,9]  0  0  0  0  0  0  0  0  0  0  A[j,10]  A[j,11]  0  ]
        HA=0
        HB=0
        HC=0
        HD=0
        HE=0
        HF=0
        μ0=0
    for i in 1:length(zf)
        μ0+=zf[i]*μ[i]
    end
    for i in 1:length(zf)#（设置变量）
        HA = (zf[i]*μ[i]*H_A[i])/μ0+HA
        HB = (zf[i]*μ[i]*H_B[i])/μ0+HB
        HC = (zf[i]*μ[i]*H_C[i])/μ0+HC
        HD = (zf[i]*μ[i]*H_D[i])/μ0+HD
        HE = (zf[i]*μ[i]*H_E[i])/μ0+HE
        HF = (zf[i]*μ[i]*H_F[i])/μ0+HF
    end
        B0=Array{Float64}(undef,1,length(zf))
        A0=Array{Float64}(undef,1,length(zf))
        c=Array{Float64}(undef,1,length(zf))
        C0=Array{Float64}(undef,1,length(zf))
        D0=Array{Float64}(undef,1,length(zf))
        E0=Array{Float64}(undef,1,length(zf))
        a=Array{Float64}(undef,1,length(zf))
        b=Array{Float64}(undef,1,length(zf))
        d=Array{Float64}(undef,1,length(zf))
        α=Array{Float64}(undef,1,length(zf))
        γ=Array{Float64}(undef,1,length(zf))
        R=8.3143#j/kg/k
    #----------------------------------------求单一物质公式--------------------------------------------
    for i in 1:length(zf)
        B0[i]=(A1[1]+B[1]*w[i])/row[i]
        A0[i]=(A1[2]+B[2]*w[i])*R*T[i]/row[i]
        C0[i]=(A1[3]+B[3]*w[i])*R*(T[i])^3/row[i]
        D0[i]=(A1[9]+B[9]*w[i])*R*(T[i])^4/row[i]
        γ[i]=(A1[4]+B[4]*w[i])/(row[i])^2
        b[i]=(A1[5]+B[5]*w[i])/(row[i])^2
        a[i]=(A1[6]+B[6]*w[i])*R*(T[i])/(row[i])^2
        c[i]=(A1[8]+B[8]*w[i])*R*(T[i])^3/(row[i])^2
        d[i]=(A1[10]+B[10]*w[i])*R*(T[i])^2/(row[i])^2
        α[i]=(A1[7]+B[7]*w[i])/(row[i])^3
        E0[i]=(A1[11]+B[11]*w[i]*exp(-3.8*w[i]))*R*(T[i]^5)/row[i]
    end
    #-------------------------------------------混合物的相关参数------------------------------------
    A0H=0
    B0H=0#变量位置
    C0H=0
    D0H=0
    E0H=0
    ah1=0
    bh1=0
    ch1=0
    dh1=0
    αh1=0
    γh1=0
    ah=0
    bh=0
    ch=0
    dh=0
    αh=0
    γh=0
    μ0=0
    for i in 1:length(zf)
        μ0+=zf[i]*μ[i]
    end
    for i in 1:length(zf)#对齐（快捷键）
        for m in 1:length(zf)
            A0H+=zf[i]*zf[m]*((A0[i])^(0.5))*((A0[m])^(0.5))*(1-K[i,m])#xy
            C0H=zf[i]*zf[m]*((C0[i])^(0.5))*((C0[m])^(0.5))*(1-K[i,m])^3+C0H
            D0H=zf[i]*zf[m]*((D0[i])^(0.5))*((D0[m])^(0.5))*(1-K[i,m])^4+D0H
            E0H=zf[i]*zf[m]*((E0[i])^(0.5))*((E0[m])^(0.5))*(1-K[i,m])^5+E0H
        end
    end
    for i in 1:length(zf)
        ah1+=zf[i]*a[i]^(1/3)
        bh1=(zf[i]*(b[i])^(1/3)+bh1)
        ch1=(zf[i]*(c[i])^(1/3)+ch1)
        dh1=(zf[i]*(d[i])^(1/3)+dh1)
        γh1=(zf[i]*(γ[i])^(1/2)+γh1)
        αh1=(zf[i]*(α[i])^(1/3)+αh1)
        B0H=zf[i]*B0[i]+B0H
    end
    ah=ah1^3
    bh=bh1^3
    ch=ch1^3
    dh=dh1^3
    αh=αh1^3
    γh=γh1^2
    H_0 = HA + HB * A[j,2] + HC * A[j,2]^2 + HD * A[j,2]^3 + HE * A[j,2]^4 + HF * A[j,2]^5
    F[k]=1000/(μ0)*(H_0*μ0+(B0H*R*A[j,2]-2*A0H-4*C0H/A[j,2]^2+5*D0H/A[j,2]^3-6*E0H/A[j,2]^4)*A[j,4]/μ0+
        0.5*(2*bh*R*A[j,2]-3*ah-4*dh/A[j,2])*(A[j,4]/μ0)^2+0.2*αh*(6*ah+7*dh/A[j,2])*(A[j,4]/μ0)^5+ch/(γh*A[j,2]^2)*
        (3-(3+(γh*(A[j,4]/μ0)^2)/2-γh^2*(A[j,4]/μ0)^4)*exp(-γh*(A[j,4]/μ0)^2)))-A[j,5]
    end
#--------------------------------------------------浓度扩散方程（1个管段）6个组分以及关于混合物密度向纯物质密度转换（6个方程）----

    for j in 1:1#氢气（相对分子质量是在改变的）c1代表氢气的初始时刻在各节点的摩尔分数（）
        k = k + 1
        μ0 = A[j, 6] * μ[1] + A[j, 7] * μ[2] + A[j, 8] * μ[4] + A[j, 9] * μ[6] + A[j, 10] * μ[17] + A[j, 11] * μ[18]
#        μ1=A[j+1,6].........
        F[k] = A[j, 6] * A[j, 4] * μ[1] / μ0 + A[j+1, 6] * A[j+1, 4] * μ[1] / μ0 - md[j] * c1[j] * μ[1] / μ0 - md[j+1] * c1[j+1] * μ[1] / μ0 +
               γ11 * (M[j+1] / bc * c1[j+1] * μ[1] / μ0 - M[j] / bc * c1[j] * μ[1] / μ0 + A[j+1, 3] / bc * A[j+1, 6] * μ[1] / μ0 - A[j, 3] / bc * A[j, 6] * μ[1] / μ0)
    end
    for j in 1:2:2#甲烷，c2代表甲烷的初始时刻在各节点的摩尔分数
        k = k + 1
        μ0 = A[j, 6] * μ[1] + A[j, 7] * μ[2] + A[j, 8] * μ[4] + A[j, 9] * μ[6] + A[j, 10] * μ[17] + A[j, 11]* μ[18]
        F[k] = A[j, 7] * A[j, 4] * μ[2] / μ0 + A[j+1, 7] * A[j+1, 4] * μ[2] / μ0 - md[j] * c2[j] * μ[2] / μ0 - md[j+1] * c2[j+1] * μ[2] / μ0 +
               γ11 * (M[j+1] * c2[j+1] * μ[2] / μ0 - M[j] * c2[j] * μ[2] / μ0 +
                    A[j+1, 3] * A[j+1, 7] * μ[2] / μ0 - A[j, 3] * A[j, 7] * μ[2] / μ0) / bc
    end
    for j in 1:2:2#乙烷，c3代表乙烷的初始时刻在各节点的摩尔分数
        k = k + 1
        μ0 = A[j, 6] * μ[1] + A[j, 7] * μ[2] + A[j, 8] * μ[4] + A[j, 9] * μ[6] + A[j, 10] * μ[17] + A[j, 11]* μ[18]
        F[k] = (A[j, 8] * A[j, 4] + A[j+1, 8] * A[j+1, 4] - md[j] * c3[j] - md[j+1] * c3[j+1]) * μ[4] / μ0 +
               γ11 * (M[j+1] * c3[j+1,] * μ[3] / μ0 - M[j] * c3[j] * μ[3] / μ0 +
                    A[j+1, 3] * A[j+1, 8] * μ[3] / μ0 - A[j, 3] * A[j, 8] * μ[3] / μ0) / bc
    end
    for j in 1:2:2#丙烷，c4代表丙烷的初始时刻在各节点的摩尔分数
        k = k + 1
        μ0 = A[j, 6] * μ[1] + A[j, 7] * μ[2] + A[j, 8] * μ[4] + A[j, 9] * μ[6] + A[j, 10] * μ[17] + A[j, 11]* μ[18]
        F[k] = (A[j, 9] * A[j, 4] + A[j+1, 9] * A[j+1, 4] - md[j] * c4[j] - md[j+1] * c4[j+1]) * μ[6] / μ0 +
               γ11 * (M[j+1] * c4[j+1] * μ[4] / μ0 - M[j] * c4[j] * μ[4] / μ0 +
                    A[j+1, 3] * A[j+1, 9] * μ[4] / μ0 - A[j, 3] * A[j, 9] * μ[4] / μ0) / bc
    end
    for j in 1:2:2#氮气，c5代表氮气的初始时刻在各节点的摩尔分数
        k = k + 1
        μ0 = A[j, 6] * μ[1] + A[j, 7] * μ[2] + A[j, 8] * μ[4] + A[j, 9] * μ[6] + A[j, 10] * μ[17] + A[j, 11]* μ[18]
        F[k] = (A[j, 10] * A[j, 4] + A[j+1, 10] * A[j+1, 4] - md[j] * c5[j] - md[j+1] * c5[j+1]) * μ[17] / μ0 +
               γ11 * (M[j+1] * c5[j+1] * μ[5] / μ0 - M[j] * c5[j] * μ[5] / μ0 +
                    A[j+1, 3] * A[j+1, 10] * μ[5] / μ0 - A[j, 3] * A[j, 10] * μ[5] / μ0) / bc
    end
    for j in 1:2:2#二氧化碳，c6代表二氧化碳的初始时刻在各节点的摩尔分数
        k = k + 1
        μ0 = A[j, 6] * μ[1] + A[j, 7] * μ[2] + A[j, 8] * μ[4] + A[j, 9] * μ[6] + A[j, 10] * μ[17] + A[j, 11]* μ[18]
        F[k] = (A[j, 11] * A[j, 4] + A[j+1, 11] * A[j+1, 4] - md[j] * c6[j] - md[j+1] * c6[j+1]) * μ[18] / μ0 +
               γ11 * (M[j+1] * c6[j+1] * μ[6] / μ0 - M[j] * c6[j] * μ[6] / μ0 + A[j+1, 3] *
               A[j+1, 11] * μ[6] / μ0 - A[j, 3] * A[j, 11] * μ[6] / μ0) / bc
    end
    #时间步长
    #----------------------------------------对k_t和k_v用expr3和expr5表示--------------------------------------
    #----------------------------------------------------边界条件（11个）--------------------------------------------------
    F[14] = A[2, 3] - 520#分输点的质量流量随时间变化（末端流量）
    F[15] = A[1, 7] - 0.917#甲烷浓度（摩尔分数）的变化(自己假设)
    F[16] = A[1, 8] - 0.05#乙烷浓度的变化
    F[17] = A[1, 9] - 0.007#丙烷浓度的变化
    F[18] = A[1, 6] - 0.033#氢气浓度的变化
    F[19] = A[1, 10] - 0.003#氮气浓度的变化
    F[20] = A[1, 11] - 0.001#二氧化碳浓度的变化（变化在氢气和甲烷上）
    F[21] = A[1, 1] - 9.7#气源压力随时间变化
    F[22] = A[1, 2] - 330#气源温度随时间变化
#println(A)
end

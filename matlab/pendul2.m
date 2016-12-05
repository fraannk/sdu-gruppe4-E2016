format compact
clear
close all


S = 0                           % Theta pos for ligev�gt
g = 9.82;                       % tyngde acc.
l = 0.1;                        % l�ngde af pendul

f_gen = 44E4                    % switch frekvens for sensor system
w_gen = 2*pi*f_gen

pendul_num = [1];
pendul_den = [l 0 -g]
pendul = tf(pendul_num, pendul_den)

filter_tau_per_volt = 0.3491
filter_gain = 3.5 * filter_tau_per_volt
filter_tau = 1E-3
filter_num = [filter_gain]
filter_den = [filter_tau 1]
filter = tf(filter_num, filter_den)

summa = 20

L_motor = 51E-3
R_motor = 2
motor_tau = L_motor/R_motor
motor_num = [1]
motor_den = [motor_tau 1]
motor = tf(motor_num, motor_den)

bil_tau = 1E-4
bil_num = [1]
bil_den = [bil_tau 1]
bil = tf(bil_num, bil_den)
bil = 1

Hopenloop = motor * bil * pendul * filter * summa

[Gm, Pm, Wgm, Wpm] = margin(Hopenloop)

% PID regulator beregninger 
% �nsket fasemargin Phi_m
Phi_m_deg = 60
Phi_m = (2*pi*Phi_m_deg)/360

Pboost = Phi_m_deg-Pm
Kc = 1/Gm
Kboost = tan((0.25*pi) + ((Pboost*pi)/(4*180)))
Wz = Wpm/Kboost
Wp = Kboost*Wpm

s = tf('s');
PID_regulator = (Kc/s)*((1+s/Wz)^2/(1+s/Wp)^2)

% PD regulator beregninger
% �nsket fasemargin Phi_m
% Reg. bog side 278

alfa = (1-sin(Phi_m))/(1+sin(Phi_m))
%alfa=0.01
Am = 20*log(1/sqrt(alfa))
Wm = 27.9% afl�st, hvor A = -Am
Tau_d = 1/(Wm*sqrt(alfa))

%alfa = 0.1
%Tau_d = 20
%Wm = 1/(sqrt(alfa)*Tau_d) 
%Am = 1

% side 349
R2 = 1E3
syms R1
R1 = double(solve(alfa==R2/(R1+R2),R1))
syms R3
R3 = double(solve(Am == R3/(R1+R2),R3))
syms C1
C1 = double(solve(alfa*Tau_d == (R1*R2*C1)/(R1+R2),C1))


PD_regulator = Am*((Tau_d*s+1)/(alfa*Tau_d*s+1))

%regulator = PID_regulator
regulator = PD_regulator

[Gc_num, Gc_den] = tfdata(regulator)
regulator_num = Gc_num{1,1}
regulator_den = Gc_den{1,1}

Hforward = regulator * motor * bil * pendul
Hfeedback = filter * summa
Hclosedloop = feedback(Hforward, Hfeedback)



   

fig1 = figure(1)
margin(regulator)
hold on
margin(Hopenloop)
hold on
margin(Hopenloop*regulator)
grid
legend('Reg','OL','OL+Reg')

fig2 = figure(2)
step(Hclosedloop)





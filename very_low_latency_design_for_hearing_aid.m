clear all; close all; clc
% oversampled DFT filter bank

% first scale down the design by 16 times to find the best initial guess
fb = FilterBankStruct( );
fb.T = 256/16;
fb.B = 48/16;  % 1 ms hop size
Lh = 480/16; % I increase filter length until over shooting arises; another way to suppress over shooting is to set lambda > 0
Lg = 480/16;
fb.tau0 = 3*48/16 - 1; % 3 ms latency
fb.symmetry = [-1;0;0];
fb.w_cut = pi/fb.B/2; % narrower mainlobe than default designs as the over sampling ratio is too high
eta = 1e4;
lambda = 0.0;

best_cost = inf;
best_fb = fb;
for num_trial = 1 : 100
    fb.h = rand(Lh,1); fb.g = rand(Lg,1);
    [fb, cost, recon_err, iter] = FilterBankDesign(fb, eta, lambda, 100);
    fprintf('Trial: %g; cost: %g; reconstruction error: %g; iterations %g\n', num_trial, cost, recon_err, iter)
    if cost < best_cost
        best_cost = cost;
        best_fb = fb;
    end
end

% then back to the original design
fb = FilterBankStruct( );
fb.T = 256;
fb.B = 48;  % 1 ms hop size
Lh = 480; % I increase filter length until over shooting arises; another way to suppress over shooting is to set lambda > 0
Lg = 480;
fb.tau0 = 3*48 - 1; % 3 ms latency
fb.symmetry = [-1;0;0];
fb.w_cut = pi/fb.B/2; % narrower mainlobe than default designs as the over sampling ratio is too high
fb.h = kron(best_fb.h, ones(16, 1));
fb.g = kron(best_fb.g, ones(16, 1));
eta = 1e4;
lambda = 0.0;

[fb, cost, recon_err, iter] = FilterBankDesign(fb, eta, lambda, 1000);
fprintf('Refinement. Cost: %g; reconstruction error: %g; iterations %g\n', cost, recon_err, iter)

figure;
subplot(2,1,1)
plot(fb.h, 'b-');
hold on; plot(fb.g, 'k-')
legend('Analysis filter', 'Synthesis filter')
xlabel('Time')
ylabel('Impulse response')
subplot(2,1,2)
fft_size = 32768;
H = 20*log10(abs(fft(fb.h, fft_size)));
plot(pi*[0:fft_size/2-1]/(fft_size/2-1), H(1:end/2), 'b-')
G = 20*log10(abs(fft(fb.g, fft_size)));
hold on; plot(pi*[0:fft_size/2-1]/(fft_size/2-1), G(1:end/2), 'k-')
xlabel('\omega')
ylabel('Magnitude in dB')

save very_low_latency_design_for_hearing_aid fb

figure
[H, F] = freqz(conv(fb.h, fb.g), 1, 32768, 48000);
H = H/max(abs(H));
plot(F, 20*log10(abs(H)))
xlim([0, 500])
xlabel('Hz')
ylabel('Analysis-synthesis magnitude in dB')
title('3 ms latency design for hearing aid')
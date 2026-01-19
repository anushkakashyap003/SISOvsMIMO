clc;
clear;
close all;

%% ---------------- Parameters ----------------
SNR_dB = 0:2:30;
SNR = 10.^(SNR_dB/10);

Nt = [1 2 4];      % Number of transmit antennas
Nr = [1 2 4];      % Number of receive antennas
numRealizations = 1000;

Capacity = zeros(length(Nt), length(SNR));

%% ---------------- Capacity Calculation ----------------
for ant = 1:length(Nt)
    for snrIdx = 1:length(SNR)
        capSum = 0;
        for iter = 1:numRealizations
            H = (randn(Nr(ant),Nt(ant)) + ...
                 1j*randn(Nr(ant),Nt(ant))) / sqrt(2);

            capSum = capSum + ...
                log2(det( eye(Nr(ant)) + ...
                (SNR(snrIdx)/Nt(ant))*(H*H') ));
        end
        Capacity(ant,snrIdx) = real(capSum/numRealizations);
    end
end

%% ---------------- Plot Capacity ----------------
figure;
plot(SNR_dB, Capacity(1,:), 'o-', 'LineWidth',2); hold on;
plot(SNR_dB, Capacity(2,:), 's-', 'LineWidth',2);
plot(SNR_dB, Capacity(3,:), 'd-', 'LineWidth',2);
grid on;
xlabel('SNR (dB)');
ylabel('Capacity (bits/s/Hz)');
title('Capacity Comparison: SISO vs MIMO');
legend('SISO (1×1)','MIMO (2×2)','MIMO (4×4)');

clc;
clear;
close all;

%% ---------------- Parameters ----------------
M = 4;                  % QPSK
k = log2(M);
numBits = 1e5;
SNR_dB = 0:2:30;

BER_SISO = zeros(length(SNR_dB),1);
BER_MIMO = zeros(length(SNR_dB),1);

%% ---------------- Simulation Loop ----------------
for snrIdx = 1:length(SNR_dB)

    %% ----------- Transmitter -----------
    txBits = randi([0 1], numBits, 1);
    txSym = qammod(txBits, M, 'InputType','bit', ...
                   'UnitAveragePower', true);

    %% ----------- SISO Channel -----------
    h = (randn + 1j*randn)/sqrt(2);
    rxSISO = h*txSym;
    rxSISO = awgn(rxSISO, SNR_dB(snrIdx),'measured');
    rxSISO = rxSISO / h;

    rxBits_SISO = qamdemod(rxSISO, M, ...
        'OutputType','bit','UnitAveragePower',true);

    BER_SISO(snrIdx) = biterr(txBits, rxBits_SISO)/numBits;

    %% ----------- 2×2 MIMO Channel -----------
    txSymMIMO = reshape(txSym, 2, []);
    H = (randn(2,2) + 1j*randn(2,2))/sqrt(2);

    rxMIMO = H * txSymMIMO;
    rxMIMO = awgn(rxMIMO, SNR_dB(snrIdx),'measured');

    % Zero-Forcing Equalization
    rxMIMO = pinv(H) * rxMIMO;
    rxMIMO = rxMIMO(:);

    rxBits_MIMO = qamdemod(rxMIMO, M, ...
        'OutputType','bit','UnitAveragePower',true);

    BER_MIMO(snrIdx) = biterr(txBits, rxBits_MIMO)/numBits;
end

%% ---------------- Plot BER ----------------
figure;
semilogy(SNR_dB, BER_SISO, 'o-', 'LineWidth',2); hold on;
semilogy(SNR_dB, BER_MIMO, 's-', 'LineWidth',2);
grid on;
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('BER Performance: SISO vs 2×2 MIMO');
legend('SISO','2×2 MIMO');

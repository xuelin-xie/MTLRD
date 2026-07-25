clc; clear;
addpath(genpath(pwd));

% KSC   512*614*176
% load KSC
% O_Img = KSC(1:256,1:256, 3:176);

% WDC
load Ori_WDC
O_Img = Img;

%% Comparison Methods
%   1. WLRTR,           2020  Tcybs
%   2. SDeCNN,          2020  TGRS
%   3. NGmeet,          2022  TPAMI
%   4. FastHyMix,       2023  TNNLS
%   5. TPTV,            2023  TGRS
%   6. CTVSPCP,         2024  SIAM
%   7. FBGND,           2024  TCI
%   8. FallHyDe         2024  TGRS
%   9. Ours (MTLRD)

Comparison_Nosiy          = 1;
Comparison_WLRTR          = 0;
Comparison_SDeCNN         = 0;
Comparison_NGmeet         = 0;
Comparison_FastHyMix      = 0;
Comparison_TPTV           = 0;
Comparison_CTVSPCP        = 0;
Comparison_FBGND          = 0;
Comparison_FallHyDe       = 0;
Comparison_MTLRD          = 1;
i=0;

setdemorandstream(pi);  % Setting the random seed
[M, N, bands] = size(O_Img);
% Convert to a value between 0 and 1
O_Img_normalized = zeros(M, N, bands);
for b = 1:bands
    min_val = min(min(O_Img(:,:,b)));  % Minimum value of the current band
    max_val = max(max(O_Img(:,:,b)));  % Maximum value of the current band
    O_Img_normalized(:,:,b) = (O_Img(:,:,b) - min_val) / (max_val - min_val);
end
O_Img = O_Img_normalized;


%% Noise selection
Nosiy_cases = 1;

if Nosiy_cases==1
    % Case1.  Gaussian noise  0.2
    Nosiy_case='Case 1 --> Gaussian noise 0.2';
    nSig = 0.2;  % Noise level
    N_Img_Gaussian = O_Img + nSig * randn(size(O_Img));
    N_Img = N_Img_Gaussian;
elseif Nosiy_cases==2
    % Case 2. Gaussian 0.2 + Salt_pepper noise 0.1
    Nosiy_case='Case 2 --> Gaussian 0.2 + Salt_pepper noise 0.1';
    nSig = 0.2;
    N_Img_Gaussian = O_Img + nSig * randn(size(O_Img));  % add Gaussian noise
    salt_pepper_ratio = 0.1;  % Impulse noise ratio (between 0 and 1)
    N_Img_Salt_pepper = N_Img_Gaussian;
    num_salt = round(salt_pepper_ratio * M * N * bands / 2);
    salt_idx = randperm(M * N * bands, num_salt);
    pepper_idx = randperm(M * N * bands, num_salt);
    N_Img_Salt_pepper(salt_idx) = 1;
    N_Img_Salt_pepper(pepper_idx) = 0;
    N_Img = N_Img_Salt_pepper;
elseif Nosiy_cases==3
    % Case 3. Gaussian 0.15 + Deadline 0.1
    Nosiy_case='Case3 --> Gaussian 0.15 + Deadline 0.1';
    nSig = 0.15;
    N_Img_Gaussian = O_Img + nSig * randn(size(O_Img));
    N_Img_Deadline = N_Img_Gaussian;
    stripeRatio = 0.1;  % Stripe ratio
    numStripes = round(N * stripeRatio);  % Number of stripes
    for b = 1:bands
        stripeColumns = randperm(N, numStripes);
        for c = stripeColumns
            N_Img_Deadline(:, c, b) = 0;
        end
    end
    N_Img =N_Img_Deadline;
elseif Nosiy_cases==4
    % Case 4. Gaussian 0.15 + Impulse [20%, 0.35] + Stripe [20%, 0.35]
    Nosiy_case = 'Case 4 --> Gaussian 0.20 + Impulse [20%, 0.35] + Stripe [20%, 0.35]';
    nSig = 0.15;
    impulse_ratio = 0.2;
    pollution_strength = 0.35;
    stripe_ratio = 0.2;
    stripe_strength = 0.35;
    N_Img = O_Img + nSig * randn(size(O_Img));
    num_impulse = round(impulse_ratio * M * N * bands);
    impulse_idx = randperm(M * N * bands, num_impulse);
    perturbation = pollution_strength * (2 * rand(size(impulse_idx)) - 1);
    N_Img(impulse_idx) = O_Img(impulse_idx) + perturbation;
    num_stripe_columns = round(stripe_ratio * N);
    stripe_cols = randperm(N, num_stripe_columns);
    for b = 1:bands
        for col = stripe_cols
            stripe_value = stripe_strength * (2 * rand() - 1);
            N_Img(:, col, b) = N_Img(:, col, b) + stripe_value;
        end
    end
elseif Nosiy_cases==5
    % Case 5. Mix 3: Gaussian 0.2 + Impulse noise [20%, 0.5] + Deadline noise [20%, 0.5]
    Nosiy_case = 'Case 5 --> Gaussian 0.25 + Impulse [20%, 0.5] + Stripe [20%, 0.5]';
    nSig = 0.25;
    impulse_ratio = 0.2;
    pollution_strength = 0.5;
    stripe_ratio = 0.2;
    stripe_strength = 0.5;
    N_Img = O_Img + nSig * randn(size(O_Img));
    num_impulse = round(impulse_ratio * M * N * bands);
    impulse_idx = randperm(M * N * bands, num_impulse);
    perturbation = pollution_strength * (2 * rand(size(impulse_idx)) - 1);
    N_Img(impulse_idx) = O_Img(impulse_idx) + perturbation;
    num_stripe_columns = round(stripe_ratio * N);
    stripe_cols = randperm(N, num_stripe_columns);
    for b = 1:bands
        for col = stripe_cols
            stripe_value = stripe_strength * (2 * rand() - 1);
            N_Img(:, col, b) = N_Img(:, col, b) + stripe_value;
        end
    end
end


%% Noisy
if Comparison_Nosiy == 1
    i=i+1;
    Time(i) = 0;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, N_Img*255);
    disp(['Method Name: None', ', Time = None', ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'Noisy';
end

%% WLRTR, 2020 Tcybs
if Comparison_WLRTR == 1
    i=i+1;
    nSigmma = nSig*255;
    Par   = ParSet(nSigmma);
    tic
    WLRTR_Img = LRTR_DeNoising(N_Img, O_Img, Par);
    Time(i) = toc;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, WLRTR_Img*255);
    disp(['Method Name: WLRTR', ', Time = ' num2str(Time(i)), ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'WLRTR';
end

%% SDeCNN 2020 TGRS
if Comparison_SDeCNN == 1
    i=i+1;
    % run vl_setupnn
    % load model
    global sigmas;
    sigmas = 100/255;          % Case1: 50/255, Case 2-5: 100/255
    load(fullfile('BestModel','best_model'));
    net.layers = net.layers(1:end-1);
    net = vl_simplenn_tidy(net);
    nch = 25;
    K = nch-1;
    nz= bands + K;
    tic
    output_img = zeros(2*ceil(M/2),2*ceil(N/2),bands);
    data = zeros(M,N,nz);
    order_init = (K/2+1):-1:2;
    order_final = (bands-1):-1:(bands-K/2);
    data(:,:,1:K/2) = N_Img(:,:,order_init);
    data(:,:,(K/2 + 1):(end-K/2)) = N_Img;
    data(:,:,(end-K/2+1):end) = N_Img(:,:,order_final);
    inputs = data;
    if mod(M,2)==1
        inputs = cat(1,inputs, inputs(end,:,:)) ;
    end
    if mod(N,2)==1
        inputs = cat(2,inputs, inputs(:,end,:)) ;
    end
    for z = 1 : bands
        Input_img = inputs(:,:,z:z+K);
        % perform denoising
        %         res    = vl_simplenn(net,Input_img,[],[],'conserveMemory',true,'mode','test');
        res    = vl_net_concise(net, Input_img);    % concise version of vl_simplenn for testing (faster)
        output = res(end).x;
        output_img(:,:,z) = output;
    end
    if mod(M,2)==1
        output_img = output_img(1:end-1,:,:);
        inputs  = inputs(1:end-1,:,:);
    end
    if mod(N,2)==1
        output_img = output_img(:,1:end-1,:);
        inputs  = inputs(:,1:end-1,:);
    end
    SDeCNN_Img = output_img;
    Time(i) = toc;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, SDeCNN_Img*255);
    disp(['Method Name: SDeCNN', ', Time = ' num2str(Time(i)), ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'SDeCNN';
end

%% NGmeet, 2022 TPAMI
if Comparison_NGmeet == 1
    i=i+1;
    noiselevel = nSig*ones(1,80);
    ParNG = ParSetH(255*mean(noiselevel),bands);
    tic
    NGmeet_Img = NGmeet_DeNoising(255*N_Img, ParNG)/255;
    Time(i) = toc;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, NGmeet_Img*255);
    disp(['Method Name: NGmeet', ', Time = ' num2str(Time(i)), ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'NGmeet';
end

%% FastHyMix, 2023 TNNLS
if Comparison_FastHyMix == 1
    i=i+1;
    tic
    k_subspace = 3;        
    [FastHyMix_Img, ~, ~] = FastHyMix(N_Img, k_subspace);
    Time(i) = toc;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, FastHyMix_Img*255);
    disp(['Method Name: FastHyMix', ', Time = ' num2str(Time(i)), ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'FastHyMix';
end

%% TPTV, 2023 TGRS
if Comparison_TPTV == 1
    i=i+1;
    param.Rank = [7,7,5];
    param.initial_rank = 2;
    param.maxIter = 50;
    param.lambda  = 4e-3*sqrt(M*N);             
    tic
    [output_image,U_x,V_x,E] = WETV(N_Img, O_Img, param);
    TPTV_Img = reshape(output_image, M, N, bands);
    Time(i) = toc;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, TPTV_Img*255);
    disp(['Method Name: TPTV', ', Time = ' num2str(Time(i)), ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'TPTV';
end

%% CTVSPCP, 2024 SIAM
if Comparison_CTVSPCP == 1
    i=i+1;
    tic
    CTVSPCP_Img =ctv_alm_spcp(N_Img,mean(nSig));
    Time(i) = toc;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, CTVSPCP_Img*255);
    disp(['Method Name: CTV_SPCP', ', Time = ' num2str(Time(i)), ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'CTVSPCP';
end

%% FBGND, 2024 TCI  % Matconvet need   % KSC case 5, max_iter 20, opts.lambda3 = 10 .
if Comparison_FBGND == 1
    %     run vl_setupnn
    addpath(genpath(cd));
    i=i+1;
    G_level=0.1;
    opts=[];
    opts.lambda3=50;
    opts.level=G_level;
    opts.lambda4=1;
    opts.gamma=1.2*[1,1,1,1,1,1];
    opts.beta=[0.1,0.1,1e-3,0.4,0.1,0.02];
    opts.rank=[round(min(N,bands)*0.05),round(min(M,bands)*0.05),round(min(M,N)*0.7)];
    opts.Xtrue=O_Img;
    opts.Llevel=2.8;
    opts.Nlevel=2;
    opts.speedup=1;
    tic;
    [FBGND_Img,~,~,Out]=FBGND(N_Img,opts);
    Time(i) = toc;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, FBGND_Img*255);
    disp(['Method Name: FBGND', ', Time = ' num2str(Time(i)), ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'FBGND';
end

%% FallHyDe, 2024 TGRS
if Comparison_FallHyDe == 1
    i=i+1;
    parameter = [1 3];  
    tic
    FallHyDe_Img = FallHyDe(N_Img, parameter(1, 1), parameter(1, 2));
    Time(i) = toc;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, FallHyDe_Img*255);
    disp(['Method Name: FallHyDe', ', Time = ' num2str(Time(i)), ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'FallHyDe';
end

%% MTLRD
if Comparison_MTLRD == 1
    i=i+1;
    % ~~ HySime Esitimate Spectral_dim ~~
    % Y = reshape(N_Img, M*N, bands)';
    % Spectral_dim = estimate_rank_HySime(Y);
    % Parameter setting
    Spectral_dim  = 5;     % Better in [3, 10]    %  KSC Case 1-3: 5 Case3: 3 Case4: 2, Case5: 1  WDC: Case 1-2: 5  Case3: 4 Case 4-5: 3
    lambda        = 100;   % Better in [1, 100]
    if Nosiy_cases == 1
        beta = 0;
    else
        beta = 0.1;        % Better in [0.01, 1]      %  WDC Case 1: 0  Case 2-4: 0.1   Case 5: 0.01
    end
    energy_thres  = 0.95;  % (0,1]      Case 1: 0.95
    tic
    MTLRD_Img = MTLRD_denoising(N_Img, Spectral_dim, lambda, beta, energy_thres);
    Time(i) = toc;
    [PSNR(i), SSIM(i), FSIM(i), ERGAS(i), SAM(i)] = MSIQA(O_Img*255, MTLRD_Img*255);
    disp(['Method Name: MTLRD', ', Time = ' num2str(Time(i)), ', MPSNR = ' num2str(PSNR(i),'%5.2f')  ...
        ', MSSIM = ' num2str(SSIM(i),'%5.4f'), ', The case of noise is: ' num2str(Nosiy_case)]);
    Methods{i} = 'MTLRD';
end

%% Show the results
Indexes = [PSNR; SSIM; FSIM; ERGAS; SAM; Time];
results = array2table(Indexes, ...
    'VariableNames', Methods', ...
    'RowNames', {'PSNR', 'SSIM', 'FSIM', 'ERGAS', 'SAM', 'Time'});
results.Properties.DimensionNames = {'Indexes', 'Methods'};
disp(results);


# MTLRD
Source code for “Multi-Level Tensor Low-Rank Decomposition for Hyperspectral Image Denoising”

⚠️ <span style="color: blue;">**The code will be fully uploaded upon formal acceptance.**</span>

# Introduction
Hyperspectral images (HSIs) exhibit strong low-rank structures due to high spectral correlations. Existing non-local low-rank denoising methods effectively exploit global spectral low-rankness and non-local self-similarity. However, within this paradigm, the spatial low-rank structure of the spectrally reduced image has not been explicitly explored.

**We propose MTLRD**, which for the first time systematically uncovers and exploits the multi-level spatial low-rank structures in non-local HSI denoising, including the previously overlooked spatial low-rankness of the spectrally reduced image. The proposed model corresponds to the following optimization problem:
![image](https://github.com/xuelin-xie/MTLRD/blob/main/images/MTLRD_model.png)

# Contents
These are the function files for the MTLRD model, all involved code is compressed in the 'MTLRD_main.zip' file. The framework of this work is:
![image](https://github.com/xuelin-xie/MTLRD/blob/main/images/MTLRD_framework.png)

# Key Findings
## 🔑 Key Finding 1: Multi-Level Spatial Low-Rankness in Non-Local Denoising
![image](https://github.com/xuelin-xie/MTLRD/blob/main/images/Multi-level_low-rank.png)

## 🔑 Key Finding 2: SST t-SVD with Energy-Based Truncation
To exploit these multi-level spatial low-rank structures while preserving spectral fidelity, we propose **Spatial Slice Truncated t-SVD (SST t-SVD)**.
![image](https://github.com/xuelin-xie/MTLRD/blob/main/images/SST_t-SVD.png)

- Operates directly on spatial slices in the original domain — no unfolding
- Preserves full spectral information while compressing spatial redundancy
- Enables **adaptive per-band rank selection** via energy threshold:
![image](https://github.com/xuelin-xie/MTLRD/blob/main/images/energy_truncated.png)

## 🔑 Key Finding 3: Key Finding 3: Joint Optimization Across All Levels
Prior methods apply low-rank constraints to non-local groups independently, without coupling them with the reduced image. MTLRD jointly optimizes all levels through a BCU-ADMM framework.

# Advantages
1) High precision;
2) Relatively insensitive to parameters;
3) Adaptive rank selection via energy threshold.

# Limitations
1) Computational cost is moderate (~30 seconds on KSC/WDC);
2) Performance depends on proper selection of regularization parameters.

# How to Cite
If you find this code or our work helpful, we would really appreciate a citation to our paper. Thank you!

Paper citation:
Xuelin Xie, Xiliang Lu, Zhengshan Wang, and Long Chen. Multi-Level Tensor Low-Rank Decomposition for Hyperspectral Image Denoising. In preparation.

# Contact
The MTLRD model for MATLAB is supported by Supercomputing Center of Wuhan University. If you have any questions, please feel free to contact us: xl.xie@whu.edu.cn (Xuelin Xie).


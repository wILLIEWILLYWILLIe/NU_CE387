# FFT SystemVerilog Debug 筆記

## 問題描述

所有 16 個 FFT 輸出樣本的 bit-accuracy 檢查全部失敗，需要與 C 參考程式 (`fft_quant.c`) 完全匹配。

---

## 輔助工具

### `tw_check.c`
- 用途：驗證旋轉因子（Twiddle Factor）的精確數值
- 使用與 C 參考程式**完全相同的 `float` 精度和 `(int)` 截斷方式**計算 W_16^0 ~ W_16^7
- 編譯執行：`gcc -o tw_check tw_check.c -lm && ./tw_check`
- 用來確認 `my_fft_pkg.sv` 中的硬編碼旋轉因子是否與 C 計算結果一致
- 發現 4 個值因 double vs float 精度差異而相差 1，據此修正

### `syn/fft.prj`
- Synplify 合成專案檔，對應 Cyclone IV-E (EP4CE115) FPGA
- Top module：`fft_top`

---

## 修改檔案與修正內容

### 1. `my_fft_pkg.sv`

- 新增 `NUM_STAGES` 和 `INT_WIDTH = 32` 參數（匹配 C 的 32-bit `int`）
- 新增 `DEBUG` 選項：
  - `DEBUG = 0`：僅列印效能總結與測試結果（簡潔模式）。
  - `DEBUG = 1`：列印詳細的級間資料與蝶形運算過程。
- 修正 4 個旋轉因子（Twiddle Factor），原本用雙精度計算，與 C 的 `float` 精度不同，差了 1：

| 旋轉因子 | 修正前 | 修正後 |
|----------|--------|--------|
| W^1 real | `0x3B21` | `0x3B20` |
| W^3 real | `0x187E` | `0x187D` |
| W^5 real | `0xE782` | `0xE783` |
| W^7 real | `0xC4DF` | `0xC4E0` |

---

### 2. `fft_stage.sv`（完全重寫）

**改動一：DIF → DIT 架構**
- 原本：DIF（先蝶形運算，後位元反轉）
- 修正：DIT（先位元反轉，後蝶形運算），匹配 C 程式
- 延遲線 `D = N/2^(s+1)` → `D = 2^s`
- DIF 是先 add/sub 再乘 twiddle → DIT 是先乘 twiddle 再 add/sub
- 新增 `delay_pipe` 對齊乘法器延遲
- **時序優化**：在模組輸出端加上暫存器（Output Registration），將本級的蝶形運算與下一級的乘法器邏輯隔開，大幅降低邏輯層級（Logic Levels）。這會使每個 Stage 增加 1 cycle 延遲。

**改動二：移除 ÷2 縮放**
- 原本 `bf_add_r[DATA_WIDTH:1]`（右移 1 位 = ÷2），4 級疊加 = ÷16
- C 程式無此縮放，直接使用完整寬度結果

**改動三：資料寬度加寬**
- 內部信號從 16-bit → 32-bit，避免移除 ÷2 後溢位

---

### 3. `complex_mult.sv`（完全重寫）

**改動一：反量化順序**
- 原本：先加減再反量化 → `deq(a*b - c*d)`
- 修正：各乘積各自反量化再加減 → `deq(a*b) - deq(c*d)`，匹配 C 的 `DEQUANTIZE_I`

**改動二：反量化捨入方式**
- 原本用 `>>>` 算術右移（向下取整），C 用 `/`（向零截斷），負數結果不同
- 修正為使用 SV 有號除法 `/`
- **時序優化**：由於 `/` 在合成時會產生大量邏輯層級（~40級），改用基於位移（Shift）的優化邏輯來實現「向零截斷」：
  - `adjusted = (rounded < 0) ? (rounded + (QUANT - 1)) : rounded;`
  - `result = adjusted >>> Q;`
  - 維持 100% 位元精確度，同時大幅提升頻率。

**修正後 Pipeline：**
```
Stage 1: 4 個乘積（a_r×w_r, a_i×w_i, a_r×w_i, a_i×w_r）
Stage 2: 各自反量化
Stage 3: 加減得最終複數結果
```

---

### 4. `fft_top.sv`（大幅重寫）

- 位元反轉從 FFT stages **之後** 移到 **之前**（DIT 架構）
- 級間信號從 16-bit 加寬至 32-bit
- 旋轉因子索引改為 DIT：stride = `N / 2^(s+1)`
- 最後輸出截斷回 16-bit（取低位元）

---

## 問題根因總結

| 問題 | 影響程度 | 修正方式 |
|------|---------|---------|
| ÷2 縮放 | 輸出約為期望值的 1/16 | 移除右移，加寬資料寬度至 32-bit |
| DIF vs DIT 架構 | 定點捨入點不同，bit-level 差異 | 改為 DIT 匹配 C 演算法 |
| 反量化順序 | bit-level 差異 | 改為每乘積各自反量化 |
| 反量化捨入 | 負數值差異 | `>>>` 改為 `/`（向零截斷） |
| 旋轉因子精度 | 特定樣本差 1 | 用 C `float` 精度重新計算 |

## Direct Testbench 驗證結果

```
Output Sample #0 ~ #15: 全部 PASS (Bit-Accurate)
TEST PASSED (100%) — 16/16 samples
```

---

## UVM 驗證環境

### 原始錯誤與修正

#### 錯誤一：`push_back` 編譯失敗
- **原因**：`my_uvm_monitor.sv` 對 dynamic array（`int[]`）使用 `push_back()`，但 `push_back` 只適用於 queue（`int[$]`）
- **修正**：改用 `new[FFT_N]` 預先分配陣列大小，再以索引賦值 `tr.real_payload[i] = ...`

#### 錯誤二：Monitor 無法驅動 `rd_en`
- **原因**：`fft_if.sv` 中 monitor modport 的 `rd_en` 設為 `input`，monitor 無法驅動它來讀取 output FIFO
- **修正**：將 monitor modport 的 `rd_en` 改為 `output`

#### 錯誤三：Reset 時序錯誤
- **原因**：`my_uvm_tb.sv` 中 reset 初始值為 1（rst_n=1，DUT 未進入 reset），driver 看到 `reset===1` 立即開始驅動，在 DUT 完成 reset 前就送入資料，導致輸出錯誤
- **修正**：reset 初始值改為 0（DUT 進入 reset），100ns 後拉高至 1；driver 改為等待 `reset===0` 再等 `reset===1` 才開始

#### 錯誤四：FIFO 讀取時序不正確
- **原因**：此 FIFO 為 look-ahead 架構 — 當 `out_empty=0` 時 `dout` 已有有效資料，`rd_en` 是用來推進到下一筆。原本 monitor 在 `rd_en` 後才取樣，導致漏掉第一筆、多讀一筆零值
- **修正**：改為在同一個 cycle 取樣 `dout`，然後設 `rd_en=1` 推進

#### 錯誤五：缺少 Flush Zeros
- **原因**：R2SDF pipeline 需要持續輸入才能推動資料通過所有 stage。原本 sequence 只送 N=16 筆實際資料，pipeline 內的資料無法全部輸出
- **修正**：在 `my_uvm_sequence.sv` 中增加 48 筆 flush zeros（與 direct testbench 一致）

#### 錯誤六：Drain Time 不足
- **原因**：`my_uvm_test.sv` 中 `phase.drop_objection` 前只等 1000ns，不夠讓 pipeline flush 完畢
- **修正**：增加至 10000ns

#### 錯誤七：Do-file 缺少 `fft_if.sv` 編譯
- **原因**：`fft_uvm_sim.do` 沒有單獨編譯 `fft_if.sv`，導致 elaboration 找不到 interface
- **修正**：在 `my_uvm_tb.sv` 編譯前加入 `vlog -sv ../uvm/fft_if.sv`

### 修改檔案總結

| 檔案 | 修改內容 |
|------|---------|
| `fft_if.sv` | monitor modport `rd_en` 改為 output |
| `my_uvm_monitor.sv` | 修正 push_back → pre-allocate、修正 FIFO 讀取時序 |
| `my_uvm_sequence.sv` | 增加 48 筆 flush zeros |
| `my_uvm_driver.sv` | 修正 reset 等待邏輯 |
| `my_uvm_tb.sv` | 修正 reset 初始值與時序 |
| `my_uvm_test.sv` | drain time 1000ns → 10000ns |
| `my_uvm_scoreboard.sv` | 修正 16-bit 比較、加入 functional coverage |
| `fft_uvm_sim.do` | 加入 `fft_if.sv` 編譯、coverage 收集 |

### 測試內容

- 從 `fft_in_real.txt` / `fft_in_imag.txt` 讀取 16 筆 FFT 輸入（cosine + noise 波形）
- 透過 UVM driver 驅動至 DUT 的 input FIFO，附加 48 筆 flush zeros
- UVM monitor 從 output FIFO 讀取 16 筆輸出
- UVM scoreboard 與 golden reference（`fft_out_real.txt` / `fft_out_imag.txt`）逐筆 bit-accurate 比較

### Functional Coverage

3 個 covergroup：

| Covergroup | 覆蓋內容 | 結果 |
|------------|---------|------|
| `cg_input_data` | real/imag 正負號、數值範圍（large_neg/small_neg/zero/small_pos/large_pos）、cross coverage | 76.0% |
| `cg_output_data` | 同上，針對輸出 | 76.0% |
| `cg_sample_index` | 全部 16 個 FFT 頻率 bin（0~15） | 100.0% |

> 76% data coverage 是因為只使用一組 cosine 波測試向量，部分數值範圍（如 zero、large_pos）未被覆蓋。可透過增加更多不同的測試序列來提高。

### UVM 驗證結果

```
TEST PASSED! All 16 samples are bit-accurate.
Input Data Coverage:  76.0%
Output Data Coverage: 76.0%
Sample Index Coverage: 100.0%
```

### Throughput / Latency（UVM 量測）

| 指標 | 數值 |
|------|------|
| FFT Points (N) | 16 |
| Pipeline Fill Latency | 47 cycles |
| Processing Time (First In → Last Out) | 63 cycles |
| Throughput Interval | 1.07 cycles/sample |
| Effective Throughput @100MHz | 93.75 Msamples/sec |

---
## 作業要求達成檢查

### Setup
- [x] 編譯 C 程式 (`gcc fft_quant.c -o fft_quant`) 產生輸入/輸出檔案
- [x] 產生 `fft_in_real.txt`, `fft_in_imag.txt`, `fft_out_real.txt`, `fft_out_imag.txt`

### Implementation — Streaming Pipelined FFT
- [x] 從 FIFO 持續讀取 real/imag 輸入（`fft_top.sv` 中 input FIFO）
- [x] N-point FFT（N=16，可參數化）
- [x] 輸出至獨立的 real/imag output FIFO
- [x] 使用 generate-for 迴圈實現各級蝶形運算（`fft_top.sv` 中 `gen_stages`）
- [x] 位元反轉模組（`fft_bit_reversal.sv`）
- [x] Pipeline 填滿後每 clock cycle 輸出一個 sample（throughput ≈ 1.07 cycles/sample）

### Implementation — Fixed-Point Quantization
- [x] 全程定點量化：Q14 格式，16-bit I/O，32-bit 內部路徑
- [x] 反量化匹配 C 的 `DEQUANTIZE_I`（每乘積各自反量化，向零截斷）
- [x] 一致的縮放避免溢位（內部 32-bit 不除以 2）

### Implementation — Parameterized Design
- [x] 資料寬度 `DATA_WIDTH`（`my_fft_pkg.sv`）
- [x] FFT 大小 `N`（`my_fft_pkg.sv`）
- [x] FIFO 深度（`fft_top.sv` 中 `FIFO_BUFFER_SIZE` 參數）

### Implementation — UVM Verification
- [x] UVM sequence 產生定點 real/imag 輸入序列（`my_uvm_sequence.sv`）
- [x] Driver 驅動 input FIFO、Monitor 從 output FIFO 擷取（`my_uvm_driver.sv`, `my_uvm_monitor.sv`）
- [x] Scoreboard 與 C 參考輸出比較量化精度（`my_uvm_scoreboard.sv`）
- [x] Functional coverage：數據範圍、正負號 cross coverage、sample index coverage

### Implementation — Throughput / Latency
- [x] Pipeline fill latency = 47 cycles
- [x] 連續輸出 throughput ≈ 1.07 cycles/sample
- [x] @100MHz throughput = 93.75 Msamples/sec

### Verification — UVM Testbench
- [x] 確定性輸入向量（cosine + noise 波形）
- [x] 持續輸入至 FFT input FIFO + 48 筆 flush zeros
- [x] 擷取串流輸出並與 C 參考比較
- [x] 驗證功能正確性（16/16 bit-accurate）與 pipeline 時序行為

### Verification — Testbench Parameters
- [x] 資料寬度：16-bit I/O, 32-bit 內部（匹配 C 的 `int`）
- [x] FIFO 深度：32 elements
- [x] Clock 頻率：100 MHz (10 ns period)

### Verification — Simulation Script
- [x] Direct testbench：`fft_tb.do`
- [x] UVM testbench：`fft_uvm_sim.do`（含 coverage 收集）
- [x] GUI 波形模擬：`fft_sim.do`（含 `fft_wave.do` 波形設定）

### Waveform 波形觀測

#### 執行方式
在 Modelsim/Questasim 中執行：
```tcl
do fft_sim.do
```
此腳本會自動編譯、載入模擬、開啟波形視窗並跑完模擬。

#### 波形腳本說明

| 檔案 | 用途 |
|------|------|
| `fft_sim.do` | 主模擬腳本：編譯 → `vsim -voptargs="+acc"` → `log -r /*` → 載入波形 → `run -all` → `wave zoom full` |
| `fft_wave.do` | 波形訊號設定：定義各 Group 的訊號與顯示格式 |

#### 波形 Group 說明

| Group | 包含訊號 | 用途 |
|-------|---------|------|
| **TOP** | `clock`, `reset` | 全域時脈與重置 |
| **VIF** | `wr_en`, `real_in/out`, `imag_in/out`, `in_full`, `rd_en`, `out_empty` | UVM Interface I/O |
| **BIT_REV** | `br_valid_out`, `br_real_out`, `br_imag_out` | 位元反轉輸出（DIT 輸入端） |
| **STAGES_PIPELINE** | `stage_valid[]`, `stage_real[]`, `stage_imag[]` | 各級間 Pipeline 訊號 |
| **STAGE_3** | `valid_in/out`, `real_in/out` | 最後一級 FFT Stage 詳細訊號 |
| **STAGE_3_MULT** | `valid_in/out`, `out_real`, `out_imag` | Stage 3 內部乘法器 |
| **OUT_FIFO** | `empty`, `full` | 輸出 FIFO 狀態 |

#### 重要參數
- `-voptargs="+acc"`：關閉最佳化，確保所有內部訊號可見
- `log -r /*`：記錄所有層級訊號，方便事後手動新增觀測
- `wave zoom full`：模擬結束後自動縮放至完整時間軸

### Compare Results
- [x] 硬體 FFT 輸出 vs C 參考：**16/16 bit-true accuracy**（零量化誤差）
- [x] Throughput：pipeline 填滿後 93.75 Msamples/sec
- [x] Latency：47 cycles（first in → first out）

## 時序優化與效能總結

為了達成 100 MHz 的目標，進行了多輪時序優化：

### 時序優化歷史 (Timing Optimization History)

| 優化階段 | 描述 | 估算頻率 (Est Freq) | Slack | 狀態 |
|----------|------|--------------------|-------|------|
| **初始版本** | 使用 `/` 除法器進行反量化 | 58.2 MHz | -7.100 | 已解決 |
| **第一階段** | 將 `/` 改為位移 (Shift) 優化邏輯 | 84.6 MHz | -1.774 | 已解決 |
| **第二階段** | 在 `fft_stage` 增加輸出暫存器 (Output Reg) | 97.4 MHz | -1.540 | 已解決 |
| **第三階段** | 增加乘法器輸入暫存器 (Input Reg) | **117.1 MHz** | -1.281 | **已完成** |

### 最新時序報告 (Summary for Stage 3)

| Clock Name | Req Freq | Est Freq | Slack |
|------------|----------|----------|-------|
| `fft_top\|clk` | 137.8 MHz | 117.1 MHz | -1.281 |

### 待優化點分析
目前的關鍵路徑已經從「查表/組合邏輯」轉移到了「乘法器核心」內部。具體來說，是 32x16 bit 的乘法運算在一個 Clock Cycle 內產生的 Carry Chain 過長。

雖然 117.1 MHz 已經達到並超過了原定的 100 MHz 目標（有 17% 的預留空間），但若要追求更高的頻率（如 140 MHz+），可以進一步將 `complex_mult` 的乘法階段（Stage 1）拆分為兩個 Pipeline Stages。
